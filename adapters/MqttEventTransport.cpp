#include "MqttEventTransport.h"

#include <QAbstractSocket>
#include <QCoreApplication>
#include <QHostInfo>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSslSocket>
#include <QTcpSocket>
#include <QUuid>

#include <algorithm>
#include <cmath>
#include <cstddef> // For std::size_t
#include <cstdint> // For std::uint16_t, std::uint64_t
#include <limits>
#include <utility>

namespace {

bool environmentFlag(const char *name)
{
    const QByteArray value = qgetenv(name).trimmed().toLower();
    return value == "1" || value == "true" || value == "yes";
}

quint16 environmentPort(bool tls)
{
    bool valid = false;
    const uint port = qEnvironmentVariableIntValue("ATTM_MQTT_PORT", &valid);
    return valid && port > 0 && port <= 65535 ? static_cast<quint16>(port)
                                               : static_cast<quint16>(tls ? 8883 : 1883);
}

} // namespace

MqttEventTransport::MqttEventTransport(QObject *parent, std::size_t capacity)
    : QObject(parent)
    , m_host(qEnvironmentVariable("ATTM_MQTT_HOST", QStringLiteral("localhost")))
    , m_topic(qEnvironmentVariable("ATTM_MQTT_TOPIC", QStringLiteral("attm/events")))
    , m_username(qEnvironmentVariable("ATTM_MQTT_USERNAME"))
    , m_password(qEnvironmentVariable("ATTM_MQTT_PASSWORD"))
    , m_clientId(QStringLiteral("attm-%1-%2")
                     .arg(QHostInfo::localHostName().left(20),
                          QUuid::createUuid().toString(QUuid::Id128).left(12)))
    , m_capacity(capacity)
    , m_useTls(environmentFlag("ATTM_MQTT_TLS"))
{
    m_port = environmentPort(m_useTls);
    m_socket = m_useTls ? static_cast<QAbstractSocket *>(new QSslSocket(this))
                        : static_cast<QAbstractSocket *>(new QTcpSocket(this));

    m_reconnectTimer.setSingleShot(true);
    m_reconnectTimer.setInterval(3000);
    m_keepAliveTimer.setInterval(15000);
    m_connectTimer.setSingleShot(true);
    m_connectTimer.setInterval(5000);

    connect(&m_reconnectTimer, &QTimer::timeout, this, &MqttEventTransport::connectToBroker);
    connect(&m_keepAliveTimer, &QTimer::timeout, this, [this] { sendPacket(0xC0, {}); });
    connect(&m_connectTimer, &QTimer::timeout, this, [this] {
        m_socket->abort();
        scheduleReconnect();
    });
    connect(m_socket, &QAbstractSocket::connected, this, &MqttEventTransport::sendConnect);
    connect(m_socket, &QAbstractSocket::disconnected, this, [this] {
        setConnected(false);
        scheduleReconnect();
    });
    connect(m_socket, &QIODevice::readyRead, this, [this] {
        m_receiveBuffer += m_socket->readAll();
        processIncoming();
    });
    connect(m_socket, &QAbstractSocket::errorOccurred, this, [this](QAbstractSocket::SocketError) {
        if (m_socket->state() == QAbstractSocket::UnconnectedState)
            scheduleReconnect();
    });

    QTimer::singleShot(0, this, &MqttEventTransport::connectToBroker);
}

void MqttEventTransport::publish(atm::face::v1::SimulationEvent event)
{
    if (m_nextSequence == std::numeric_limits<std::uint64_t>::max())
        return;
    event.sequence = m_nextSequence++;
    store(event);
    if (m_connected)
        sendPublish(event);
}

const std::vector<atm::face::v1::SimulationEvent> &MqttEventTransport::events() const
{
    return m_events;
}

void MqttEventTransport::clear()
{
    m_events.clear();
    m_latestEntityVersions.clear();
    emit eventsChanged();
}

void MqttEventTransport::connectToBroker()
{
    if (m_socket->state() != QAbstractSocket::UnconnectedState)
        return;

    m_receiveBuffer.clear();
    m_connectTimer.start();
    if (m_useTls)
        static_cast<QSslSocket *>(m_socket)->connectToHostEncrypted(m_host, m_port);
    else
        m_socket->connectToHost(m_host, m_port);
}

void MqttEventTransport::scheduleReconnect()
{
    m_connectTimer.stop();
    m_keepAliveTimer.stop();
    if (!m_reconnectTimer.isActive())
        m_reconnectTimer.start();
}

void MqttEventTransport::sendConnect()
{
    quint8 flags = 0x02; // Clean session.
    if (!m_username.isEmpty())
        flags |= 0x80;
    if (!m_password.isEmpty())
        flags |= 0x40;

    QByteArray body = encodeString("MQTT");
    body.append(char(0x04)); // MQTT 3.1.1.
    body.append(char(flags));
    body.append(char(0x00));
    body.append(char(30)); // Keep alive, seconds.
    body += encodeString(m_clientId.toUtf8());
    if (!m_username.isEmpty())
        body += encodeString(m_username.toUtf8());
    if (!m_password.isEmpty())
        body += encodeString(m_password.toUtf8());
    sendPacket(0x10, body);
}

void MqttEventTransport::subscribe()
{
    QByteArray body;
    const quint16 packetId = m_packetId++;
    body.append(char(packetId >> 8));
    body.append(char(packetId & 0xff));
    body += encodeString(m_topic.toUtf8());
    body.append(char(0x00)); // QoS 0 subscription.
    sendPacket(0x82, body);
}

void MqttEventTransport::sendPublish(const atm::face::v1::SimulationEvent &event)
{
    QJsonObject payload{
        {QStringLiteral("schemaVersion"), event.schemaVersion},
        {QStringLiteral("sequence"), QString::number(event.sequence)},
        {QStringLiteral("simulationMinutes"), event.simulationMinutes},
        {QStringLiteral("source"), static_cast<int>(event.source)},
        {QStringLiteral("message"), QString::fromStdString(event.message)},
        {QStringLiteral("correlationId"), QString::fromStdString(event.correlationId)},
        {QStringLiteral("entityVersion"), static_cast<qint64>(event.entityVersion)},
        {QStringLiteral("origin"), m_clientId}
    };
    QByteArray body = encodeString(m_topic.toUtf8());
    body += QJsonDocument(payload).toJson(QJsonDocument::Compact);
    sendPacket(0x30, body);
}

void MqttEventTransport::sendPacket(quint8 header, const QByteArray &body)
{
    if (m_socket->state() != QAbstractSocket::ConnectedState)
        return;
    QByteArray packet(1, char(header));
    packet += encodeRemainingLength(body.size());
    packet += body;
    m_socket->write(packet);
}

void MqttEventTransport::processIncoming()
{
    while (m_receiveBuffer.size() >= 2) {
        int multiplier = 1;
        int remaining = 0;
        int index = 1;
        int encodedBytes = 0;
        quint8 encoded = 0;
        do {
            if (index >= m_receiveBuffer.size())
                return;
            if (++encodedBytes > 4) {
                m_receiveBuffer.clear();
                m_socket->disconnectFromHost();
                return;
            }
            encoded = static_cast<quint8>(m_receiveBuffer.at(index++));
            remaining += (encoded & 0x7f) * multiplier;
            multiplier *= 128;
        } while (encoded & 0x80);

        if (m_receiveBuffer.size() < index + remaining)
            return;
        const quint8 header = static_cast<quint8>(m_receiveBuffer.at(0));
        const QByteArray body = m_receiveBuffer.mid(index, remaining);
        m_receiveBuffer.remove(0, index + remaining);
        processPacket(header, body);
    }
}

void MqttEventTransport::processPacket(quint8 header, const QByteArray &body)
{
    const quint8 type = header >> 4;
    if (type == 2) { // CONNACK
        m_connectTimer.stop();
        if (body.size() == 2 && body.at(1) == 0) {
            setConnected(true);
            m_keepAliveTimer.start();
            subscribe();
        } else {
            m_socket->disconnectFromHost();
        }
        return;
    }
    if (type == 13) // PINGRESP
        return;
    if (type != 3 || body.size() < 2) // PUBLISH
        return;

    const int topicLength = (static_cast<quint8>(body.at(0)) << 8)
                          | static_cast<quint8>(body.at(1));
    const int qos = (header >> 1) & 0x03;
    if (qos == 3 || topicLength == 0 || topicLength > body.size() - 2)
        return;
    int payloadOffset = 2 + topicLength;

    quint16 packetId = 0;
    if (qos > 0) {
        if (payloadOffset + 2 > body.size())
            return;
        packetId = (static_cast<quint8>(body.at(payloadOffset)) << 8)
                 | static_cast<quint8>(body.at(payloadOffset + 1));
        payloadOffset += 2;
    }
    if (qos == 1) {
        QByteArray acknowledgement;
        acknowledgement.append(char(packetId >> 8));
        acknowledgement.append(char(packetId & 0xff));
        sendPacket(0x40, acknowledgement);
    }

    QJsonParseError error;
    const QJsonDocument document = QJsonDocument::fromJson(body.mid(payloadOffset), &error);
    if (error.error != QJsonParseError::NoError || !document.isObject())
        return;
    const QJsonObject payload = document.object();
    if (payload.value(QStringLiteral("origin")).toString() == m_clientId)
        return;

    atm::face::v1::SimulationEvent event;
    event.schemaVersion = static_cast<std::uint16_t>(payload.value(QStringLiteral("schemaVersion")).toInt());
    const QJsonValue sequence = payload.value(QStringLiteral("sequence"));
    bool sequenceValid = false;
    if (sequence.isString()) {
        event.sequence = sequence.toString().toULongLong(&sequenceValid);
    } else if (sequence.isDouble()) {
        const double numericSequence = sequence.toDouble();
        sequenceValid = std::isfinite(numericSequence) && numericSequence >= 1.0
            && numericSequence <= 9007199254740991.0 && std::floor(numericSequence) == numericSequence;
        if (sequenceValid)
            event.sequence = static_cast<std::uint64_t>(numericSequence);
    }
    event.simulationMinutes = payload.value(QStringLiteral("simulationMinutes")).toInt();
    event.source = static_cast<atm::face::v1::Stakeholder>(payload.value(QStringLiteral("source")).toInt());
    event.message = payload.value(QStringLiteral("message")).toString().toStdString();
    event.correlationId = payload.value(QStringLiteral("correlationId")).toString().toStdString();
    event.entityVersion = static_cast<std::uint32_t>(payload.value(QStringLiteral("entityVersion")).toInteger());
    const int sourceValue = static_cast<int>(event.source);
    if (event.schemaVersion != atm::face::v1::kSchemaVersion || !sequenceValid
        || event.sequence == 0 || event.sequence == std::numeric_limits<std::uint64_t>::max()
        || event.simulationMinutes < 0 || event.simulationMinutes >= 24 * 60
        || sourceValue < static_cast<int>(atm::face::v1::Stakeholder::System)
        || sourceValue > static_cast<int>(atm::face::v1::Stakeholder::UrbanAuthority)
        || event.message.empty() || event.message.size() > 256
        || event.correlationId.size() > 64)
        return;
    m_nextSequence = std::max(m_nextSequence, event.sequence + 1);
    store(std::move(event));
}

void MqttEventTransport::setConnected(bool connected)
{
    if (m_connected == connected)
        return;
    m_connected = connected;
    emit connectedChanged(connected);
}

void MqttEventTransport::store(atm::face::v1::SimulationEvent event)
{
    if (!event.correlationId.empty()) {
        const QString correlationId = QString::fromStdString(event.correlationId);
        const auto latestVersion = m_latestEntityVersions.constFind(correlationId);
        if (event.entityVersion == 0
            || (latestVersion != m_latestEntityVersions.cend() && event.entityVersion <= latestVersion.value()))
            return;
        m_latestEntityVersions.insert(correlationId, event.entityVersion);
    }
    m_events.insert(m_events.begin(), std::move(event));
    if (m_events.size() > m_capacity)
        m_events.resize(m_capacity);
    emit eventsChanged();
}

QByteArray MqttEventTransport::encodeString(const QByteArray &value)
{
    QByteArray result;
    const qsizetype length = std::min<qsizetype>(value.size(), 65535);
    result.append(char((length >> 8) & 0xff));
    result.append(char(length & 0xff));
    result.append(value.constData(), length);
    return result;
}

QByteArray MqttEventTransport::encodeRemainingLength(qsizetype length)
{
    QByteArray result;
    do {
        quint8 encoded = static_cast<quint8>(length % 128);
        length /= 128;
        if (length > 0)
            encoded |= 0x80;
        result.append(char(encoded));
    } while (length > 0);
    return result;
}
