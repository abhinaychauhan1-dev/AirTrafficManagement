#pragma once

#include "face/interfaces/IEventTransport.h"

#include <QByteArray>
#include <QObject>
#include <QTimer>

#include <cstddef>
#include <cstdint>
#include <vector>

class QAbstractSocket;

class MqttEventTransport final : public QObject, public atm::face::interfaces::IEventTransport
{
    Q_OBJECT

public:
    explicit MqttEventTransport(QObject *parent = nullptr, std::size_t capacity = 8);

    void publish(atm::face::v1::SimulationEvent event) override;
    const std::vector<atm::face::v1::SimulationEvent> &events() const override;
    void clear() override;

    bool isConnected() const;
    QString brokerDescription() const;

signals:
    void connectedChanged(bool connected);
    void eventsChanged();

private:
    void connectToBroker();
    void scheduleReconnect();
    void sendConnect();
    void subscribe();
    void sendPublish(const atm::face::v1::SimulationEvent &event);
    void sendPacket(quint8 header, const QByteArray &body);
    void processIncoming();
    void processPacket(quint8 header, const QByteArray &body);
    void setConnected(bool connected);
    void store(atm::face::v1::SimulationEvent event);

    static QByteArray encodeString(const QByteArray &value);
    static QByteArray encodeRemainingLength(qsizetype length);

    QAbstractSocket *m_socket = nullptr;
    QTimer m_reconnectTimer;
    QTimer m_keepAliveTimer;
    QTimer m_connectTimer;
    QByteArray m_receiveBuffer;
    QString m_host;
    QString m_topic;
    QString m_username;
    QString m_password;
    QString m_clientId;
    quint16 m_port = 1883;
    quint16 m_packetId = 1;
    std::size_t m_capacity;
    std::uint64_t m_nextSequence = 1;
    std::vector<atm::face::v1::SimulationEvent> m_events;
    bool m_useTls = false;
    bool m_connected = false;
};
