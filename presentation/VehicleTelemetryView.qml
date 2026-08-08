import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    property int tick: 0
    property real pitch: 2.4
    property real roll: -4.0
    property real airspeed: 118
    property real altitude: 1860
    property real verticalSpeed: 320
    property real heading: 274
    property real stateOfCharge: 78.4
    property real packVoltage: 742
    property real packCurrent: 186
    property real packTemperature: 38.6
    property bool automationEngaged: true
    property int logFilter: 0
    property var socHistory: [82.5, 82.2, 81.9, 81.6, 81.3, 81.0, 80.7, 80.4, 80.1, 79.8, 79.5, 79.2, 78.9, 78.7, 78.4]
    property var voltageHistory: [755, 752, 750, 748, 751, 747, 745, 744, 746, 743, 741, 744, 742, 740, 742]
    property var temperatureHistory: [34.2, 34.6, 34.9, 35.4, 35.7, 36.0, 36.4, 36.8, 37.1, 37.5, 37.9, 38.1, 38.4, 38.5, 38.6]

    readonly property color panel: "#0c1716"
    readonly property color raised: "#12201e"
    readonly property color deep: "#07110f"
    readonly property color line: "#293a37"
    readonly property color textMain: "#d9e5e1"
    readonly property color textMuted: "#7f9690"
    readonly property color green: "#6fffc1"
    readonly property color cyan: "#73d9ff"
    readonly property color amber: "#ffb443"
    readonly property color red: "#ff746c"

    function appendHistory(source, value) {
        const next = source.slice(1)
        next.push(value)
        return next
    }

    function motorColor(status) {
        return status === "NOMINAL" ? green : (status === "WATCH" ? amber : red)
    }

    function toggleAutomation() {
        automationEngaged = !automationEngaged
        const seconds = 20 + tick % 40
        diagnosticLog.insert(0, {
            "time": "14:32:" + String(seconds).padStart(2, "0"),
            "severity": automationEngaged ? "PASS" : "WATCH",
            "subsystem": "FCC",
            "message": automationEngaged
                       ? "Autopilot NAV / ALT HOLD engaged by operator"
                       : "Autopilot disengaged; manual flight control active"
        })
        if (diagnosticLog.count > 8)
            diagnosticLog.remove(diagnosticLog.count - 1)
    }

    component PanelTitle: RowLayout {
        required property string title
        property string meta: "LIVE"
        property color accent: root.cyan
        Layout.fillWidth: true
        spacing: 8
        Rectangle { Layout.preferredWidth: 3; Layout.preferredHeight: 19; color: accent }
        Text { text: title; color: root.textMain; font.family: "Consolas"; font.pixelSize: 13; font.bold: true }
        Item { Layout.fillWidth: true }
        Text { text: meta; color: accent; font.family: "Consolas"; font.pixelSize: 9; font.bold: true }
    }

    component StatusTag: Rectangle {
        required property string label
        property color accent: root.green
        implicitWidth: tagContent.implicitWidth + 18
        implicitHeight: 24
        radius: 3
        color: Qt.rgba(accent.r, accent.g, accent.b, 0.09)
        border.color: Qt.rgba(accent.r, accent.g, accent.b, 0.62)
        Row {
            id: tagContent
            anchors.centerIn: parent
            spacing: 6
            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 6; height: 6; radius: 3; color: accent }
            Text { text: label; color: accent; font.family: "Consolas"; font.pixelSize: 9; font.bold: true }
        }
    }

    component DataCell: Column {
        required property string label
        required property string value
        property color accent: root.textMain
        spacing: 1
        Text { text: label; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 9; font.bold: true }
        Text { text: value; color: accent; font.family: "Consolas"; font.pixelSize: 14; font.bold: true }
    }

    component DiagnosticBar: ColumnLayout {
        required property string label
        required property real value
        property string valueText: Math.round(value) + "%"
        property color accent: root.green
        spacing: 3
        RowLayout {
            Layout.fillWidth: true
            Text { text: label; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 9; font.bold: true }
            Item { Layout.fillWidth: true }
            Text { text: valueText; color: accent; font.family: "Consolas"; font.pixelSize: 10; font.bold: true }
        }
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 6
            radius: 2
            color: "#1b2b28"
            Rectangle {
                width: parent.width * Math.max(0, Math.min(100, value)) / 100
                height: parent.height
                radius: 2
                color: accent
                Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
            }
        }
    }

    ListModel {
        id: motorModel
        ListElement { motor: "M1"; position: "FRONT L"; rpm: 2410; torque: 86; thrust: 118; status: "NOMINAL" }
        ListElement { motor: "M2"; position: "FRONT R"; rpm: 2436; torque: 87; thrust: 120; status: "NOMINAL" }
        ListElement { motor: "M3"; position: "MID L"; rpm: 2388; torque: 84; thrust: 116; status: "NOMINAL" }
        ListElement { motor: "M4"; position: "MID R"; rpm: 2442; torque: 88; thrust: 121; status: "NOMINAL" }
        ListElement { motor: "M5"; position: "AFT L"; rpm: 2364; torque: 82; thrust: 114; status: "NOMINAL" }
        ListElement { motor: "M6"; position: "AFT R"; rpm: 2401; torque: 85; thrust: 117; status: "NOMINAL" }
        ListElement { motor: "M7"; position: "LIFT L"; rpm: 2298; torque: 79; thrust: 109; status: "WATCH" }
        ListElement { motor: "M8"; position: "LIFT R"; rpm: 2324; torque: 80; thrust: 111; status: "NOMINAL" }
    }

    ListModel {
        id: diagnosticLog
        ListElement { time: "14:32:18"; severity: "INFO"; subsystem: "FCC"; message: "Autopilot mode NAV / ALT HOLD engaged" }
        ListElement { time: "14:32:16"; severity: "PASS"; subsystem: "SENSORS"; message: "Triple IMU voting agreement within 0.08 deg" }
        ListElement { time: "14:32:11"; severity: "WATCH"; subsystem: "DEP-7"; message: "Bearing vibration trend above advisory baseline" }
        ListElement { time: "14:32:07"; severity: "PASS"; subsystem: "BMS"; message: "Cell delta 14 mV / isolation resistance nominal" }
        ListElement { time: "14:31:58"; severity: "INFO"; subsystem: "DATALINK"; message: "Primary and secondary command links synchronized" }
    }

    Timer {
        interval: 900
        running: root.visible
        repeat: true
        onTriggered: {
            root.tick++
            root.pitch = 2.4 + Math.sin(root.tick * 0.31) * 2.1
            root.roll = -4.0 + Math.sin(root.tick * 0.22) * 5.5
            root.airspeed = 118 + Math.sin(root.tick * 0.28) * 4.2
            root.altitude = 1860 + Math.sin(root.tick * 0.17) * 34
            root.verticalSpeed = 260 + Math.sin(root.tick * 0.38) * 210
            root.heading = (274 + root.tick * 0.35) % 360
            root.stateOfCharge = Math.max(20, root.stateOfCharge - 0.06)
            root.packVoltage = 742 + Math.sin(root.tick * 0.37) * 5.5
            root.packCurrent = 186 + Math.sin(root.tick * 0.42) * 18
            root.packTemperature = 38.6 + Math.sin(root.tick * 0.16) * 1.1
            root.socHistory = root.appendHistory(root.socHistory, root.stateOfCharge)
            root.voltageHistory = root.appendHistory(root.voltageHistory, root.packVoltage)
            root.temperatureHistory = root.appendHistory(root.temperatureHistory, root.packTemperature)
            for (let index = 0; index < motorModel.count; ++index) {
                const phase = root.tick * 0.32 + index * 0.8
                motorModel.setProperty(index, "rpm", Math.round(2390 + Math.sin(phase) * 62 - (index === 6 ? 74 : 0)))
                motorModel.setProperty(index, "torque", Math.round(84 + Math.sin(phase * 0.8) * 5))
                motorModel.setProperty(index, "thrust", Math.round(116 + Math.sin(phase * 0.7) * 7))
            }
            pfdCanvas.requestPaint()
            energyChart.requestPaint()
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 68
            color: root.deep
            border.color: root.line
            radius: 4
            Rectangle { anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom; width: 4; color: root.cyan }
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 18
                anchors.rightMargin: 14
                spacing: 18
                Column {
                    Layout.fillWidth: true
                    spacing: 2
                    Text { text: "VEHICLE TELEMETRY (DIAGNOSTICS)"; color: root.textMain; font.family: "Consolas"; font.pixelSize: 19; font.bold: true }
                    Text { text: "ATX-201  /  VTOL-07  /  FLIGHT, PROPULSION, ENERGY AND SAFETY BUS"; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 10 }
                }
                StatusTag { label: "AIRBORNE"; accent: root.cyan }
                StatusTag { label: "DATA VALID" }
                Column {
                    Layout.preferredWidth: 92
                    Text { width: parent.width; text: "14:32:" + String(20 + root.tick % 40).padStart(2, "0"); color: root.textMain; font.family: "Consolas"; font.pixelSize: 17; font.bold: true; horizontalAlignment: Text.AlignRight }
                    Text { width: parent.width; text: "UTC / 20 HZ BUS"; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 8; horizontalAlignment: Text.AlignRight }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 0
            spacing: 8

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 0
                Layout.preferredWidth: root.width * 0.55
                Layout.minimumWidth: 0
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: 0
                    Layout.preferredHeight: 250
                    Layout.minimumWidth: 0
                    color: root.panel
                    border.color: root.line
                    radius: 4
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 9
                        spacing: 6
                        PanelTitle { title: "PRIMARY FLIGHT DISPLAY"; meta: "ADC / AHRS VALID"; accent: root.green }
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.minimumWidth: 0
                            Layout.minimumHeight: 0
                            spacing: 8
                            Rectangle {
                                Layout.preferredWidth: 78
                                Layout.fillHeight: true
                                color: root.deep
                                border.color: root.line
                                radius: 3
                                Column {
                                    anchors.centerIn: parent
                                    spacing: 2
                                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: "IAS"; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 9; font.bold: true }
                                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: Math.round(root.airspeed); color: root.cyan; font.family: "Consolas"; font.pixelSize: 25; font.bold: true }
                                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: "KT"; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 9 }
                                    Rectangle { width: 50; height: 5; radius: 2; color: "#1b2b28"; Rectangle { width: parent.width * root.airspeed / 180; height: parent.height; radius: 2; color: root.cyan } }
                                }
                            }
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: "#081312"
                                border.color: root.line
                                radius: 3
                                clip: true
                                Canvas {
                                    id: pfdCanvas
                                    anchors.fill: parent
                                    antialiasing: true
                                    onWidthChanged: requestPaint()
                                    onHeightChanged: requestPaint()
                                    onPaint: {
                                        const context = getContext("2d")
                                        context.reset()
                                        const centerX = width / 2
                                        const centerY = height / 2
                                        context.save()
                                        context.translate(centerX, centerY)
                                        context.rotate(-root.roll * Math.PI / 180)
                                        const horizonY = root.pitch * 3.2
                                        context.fillStyle = "#16394a"
                                        context.fillRect(-width, -height * 1.5 + horizonY, width * 2, height * 1.5)
                                        context.fillStyle = "#493a24"
                                        context.fillRect(-width, horizonY, width * 2, height * 1.5)
                                        context.strokeStyle = "#d9e5e1"
                                        context.lineWidth = 2
                                        context.beginPath()
                                        context.moveTo(-width, horizonY)
                                        context.lineTo(width, horizonY)
                                        context.stroke()
                                        context.font = "10px Consolas"
                                        context.textAlign = "center"
                                        for (let mark = -20; mark <= 20; mark += 5) {
                                            if (mark === 0) continue
                                            const markY = horizonY + mark * 3.2
                                            const half = mark % 10 === 0 ? 28 : 17
                                            context.lineWidth = 1
                                            context.beginPath()
                                            context.moveTo(-half, markY)
                                            context.lineTo(half, markY)
                                            context.stroke()
                                            if (mark % 10 === 0) {
                                                context.fillStyle = "#d9e5e1"
                                                context.fillText(Math.abs(mark), -half - 12, markY + 3)
                                                context.fillText(Math.abs(mark), half + 12, markY + 3)
                                            }
                                        }
                                        context.restore()
                                        context.strokeStyle = "#ffb443"
                                        context.lineWidth = 3
                                        context.beginPath()
                                        context.moveTo(centerX - 46, centerY)
                                        context.lineTo(centerX - 12, centerY)
                                        context.lineTo(centerX, centerY + 8)
                                        context.lineTo(centerX + 12, centerY)
                                        context.lineTo(centerX + 46, centerY)
                                        context.stroke()
                                        context.fillStyle = "#d9e5e1"
                                        context.font = "bold 11px Consolas"
                                        context.textAlign = "center"
                                        context.fillText("HDG " + String(Math.round(root.heading)).padStart(3, "0") + "°", centerX, 15)
                                        context.fillText("P " + root.pitch.toFixed(1) + "°   R " + root.roll.toFixed(1) + "°", centerX, height - 8)
                                    }
                                }
                            }
                            Rectangle {
                                Layout.preferredWidth: 104
                                Layout.fillHeight: true
                                color: root.deep
                                border.color: root.line
                                radius: 3
                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 7
                                    DataCell { label: "BARO ALT"; value: Math.round(root.altitude) + " FT"; accent: root.green }
                                    Rectangle { Layout.fillWidth: true; height: 1; color: root.line }
                                    DataCell { label: "VERT SPEED"; value: (root.verticalSpeed >= 0 ? "+" : "") + Math.round(root.verticalSpeed); accent: Math.abs(root.verticalSpeed) > 450 ? root.amber : root.cyan }
                                    Item { Layout.fillHeight: true }
                                    Text { text: "FT / MIN"; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 8 }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumWidth: 0
                    Layout.minimumHeight: 0
                    Layout.preferredHeight: 250
                    color: root.panel
                    border.color: root.line
                    radius: 4
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 9
                        spacing: 6
                        PanelTitle { title: "DISTRIBUTED ELECTRIC PROPULSION"; meta: "8 / 8 ONLINE"; accent: root.cyan }
                        GridView {
                            id: motorGrid
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.minimumHeight: 0
                            clip: true
                            model: motorModel
                            cellWidth: width / 4
                            cellHeight: height / 2
                            delegate: Item {
                                required property string motor
                                required property string position
                                required property int rpm
                                required property int torque
                                required property int thrust
                                required property string status
                                width: motorGrid.cellWidth
                                height: motorGrid.cellHeight
                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: 3
                                    color: root.deep
                                    border.color: root.motorColor(status)
                                    radius: 3
                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 7
                                        spacing: 7
                                        Rectangle {
                                            Layout.preferredWidth: 34
                                            Layout.preferredHeight: 34
                                            radius: 17
                                            color: "transparent"
                                            border.color: root.motorColor(status)
                                            border.width: 2
                                            Text { anchors.centerIn: parent; text: motor; color: root.motorColor(status); font.family: "Consolas"; font.pixelSize: 11; font.bold: true }
                                            RotationAnimation on rotation { from: 0; to: 360; duration: Math.max(420, 150000 / rpm); loops: Animation.Infinite; running: root.visible }
                                        }
                                        Column {
                                            Layout.fillWidth: true
                                            spacing: 1
                                            Text { text: position + "  " + status; color: root.motorColor(status); font.family: "Consolas"; font.pixelSize: 8; font.bold: true }
                                            Text { text: rpm + " RPM"; color: root.textMain; font.family: "Consolas"; font.pixelSize: 11; font.bold: true }
                                            Text { text: torque + " Nm  /  " + thrust + " kgf"; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 8 }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumWidth: 0
                Layout.minimumHeight: 0
                Layout.preferredWidth: root.width * 0.45
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: 0
                    Layout.preferredHeight: 250
                    color: root.panel
                    border.color: root.packTemperature > 44 ? root.amber : root.line
                    radius: 4
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 9
                        spacing: 6
                        PanelTitle { title: "ENERGY & POWER MANAGEMENT"; meta: "PACK A+B / BALANCED"; accent: root.green }
                        RowLayout {
                            Layout.fillWidth: true
                            DataCell { Layout.fillWidth: true; label: "STATE OF CHARGE"; value: root.stateOfCharge.toFixed(1) + "%"; accent: root.green }
                            DataCell { Layout.fillWidth: true; label: "PACK VOLTAGE"; value: Math.round(root.packVoltage) + " V"; accent: root.cyan }
                            DataCell { Layout.fillWidth: true; label: "DISCHARGE"; value: Math.round(root.packCurrent) + " A"; accent: root.textMain }
                            DataCell { Layout.fillWidth: true; label: "PACK MAX"; value: root.packTemperature.toFixed(1) + " °C"; accent: root.packTemperature > 44 ? root.amber : root.green }
                        }
                        Canvas {
                            id: energyChart
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.minimumHeight: 0
                            antialiasing: true
                            onWidthChanged: requestPaint()
                            onHeightChanged: requestPaint()
                            onPaint: {
                                const context = getContext("2d")
                                context.reset()
                                const left = 32
                                const right = width - 8
                                const top = 8
                                const bottom = height - 19
                                context.strokeStyle = root.line
                                context.lineWidth = 1
                                for (let row = 0; row <= 4; ++row) {
                                    const y = top + (bottom - top) * row / 4
                                    context.beginPath()
                                    context.moveTo(left, y)
                                    context.lineTo(right, y)
                                    context.stroke()
                                }
                                function drawSeries(values, minimum, maximum, color) {
                                    context.strokeStyle = color
                                    context.lineWidth = 2
                                    context.beginPath()
                                    for (let index = 0; index < values.length; ++index) {
                                        const x = left + (right - left) * index / Math.max(1, values.length - 1)
                                        const y = bottom - (bottom - top) * (values[index] - minimum) / (maximum - minimum)
                                        if (index === 0) context.moveTo(x, y)
                                        else context.lineTo(x, y)
                                    }
                                    context.stroke()
                                }
                                drawSeries(root.socHistory, 65, 90, root.green)
                                drawSeries(root.voltageHistory, 700, 780, root.cyan)
                                drawSeries(root.temperatureHistory, 25, 55, root.amber)
                                context.fillStyle = root.textMuted
                                context.font = "8px Consolas"
                                context.textAlign = "left"
                                context.fillText("-14 MIN", left, height - 5)
                                context.textAlign = "right"
                                context.fillText("NOW", right, height - 5)
                            }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 14
                            Text { text: "━ SOC"; color: root.green; font.family: "Consolas"; font.pixelSize: 9; font.bold: true }
                            Text { text: "━ VOLTAGE"; color: root.cyan; font.family: "Consolas"; font.pixelSize: 9; font.bold: true }
                            Text { text: "━ TEMPERATURE"; color: root.amber; font.family: "Consolas"; font.pixelSize: 9; font.bold: true }
                            Item { Layout.fillWidth: true }
                            Text { text: "THERMAL LIMIT 50 °C"; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 8 }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: 0
                    Layout.preferredHeight: 250
                    color: root.panel
                    border.color: root.line
                    radius: 4
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 9
                        spacing: 6
                        PanelTitle { title: "HEALTH & SAFETY DIAGNOSTICS"; meta: root.automationEngaged ? "1 ADVISORY / 0 FAULTS" : "MANUAL CONTROL / 0 FAULTS"; accent: root.automationEngaged ? root.amber : root.cyan }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6
                            StatusTag { label: "FCC NOMINAL" }
                            StatusTag { label: "3x IMU VALID"; accent: root.cyan }
                            StatusTag { label: root.automationEngaged ? "AP NAV / ALT" : "AP DISENGAGED"; accent: root.automationEngaged ? root.green : root.amber }
                            Item { Layout.fillWidth: true }
                            Button {
                                id: automationButton
                                implicitWidth: 88
                                implicitHeight: 25
                                text: root.automationEngaged ? "DISENGAGE AP" : "ENGAGE AP"
                                font.family: "Consolas"
                                font.pixelSize: 8
                                font.bold: true
                                onClicked: root.toggleAutomation()
                                contentItem: Text { text: automationButton.text; color: root.automationEngaged ? root.amber : root.green; font: automationButton.font; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                background: Rectangle { color: automationButton.hovered ? "#182c28" : root.raised; border.color: root.automationEngaged ? root.amber : root.green; radius: 3 }
                            }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.minimumHeight: 0
                            spacing: 10
                            ColumnLayout {
                                Layout.preferredWidth: 170
                                Layout.minimumWidth: 150
                                Layout.maximumWidth: 190
                                spacing: 6
                                DiagnosticBar { Layout.fillWidth: true; label: "SYSTEM INTEGRITY"; value: 98; accent: root.green }
                                DiagnosticBar { Layout.fillWidth: true; label: "SENSOR CONSENSUS"; value: 96; accent: root.cyan }
                                DiagnosticBar { Layout.fillWidth: true; label: "FAULT TOLERANCE"; value: 88; accent: root.amber }
                            }
                            Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; color: root.line }
                            ListView {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Layout.minimumWidth: 0
                                Layout.minimumHeight: 0
                                clip: true
                                spacing: 3
                                model: diagnosticLog
                                delegate: Rectangle {
                                    required property string time
                                    required property string severity
                                    required property string subsystem
                                    required property string message
                                    width: ListView.view.width
                                    height: 34
                                    color: severity === "WATCH" ? "#211c12" : root.deep
                                    border.color: severity === "WATCH" ? root.amber : root.line
                                    radius: 2
                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 7
                                        anchors.rightMargin: 7
                                        spacing: 7
                                        Text { text: time; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 8 }
                                        Text { text: severity; color: severity === "WATCH" ? root.amber : (severity === "PASS" ? root.green : root.cyan); font.family: "Consolas"; font.pixelSize: 8; font.bold: true; Layout.preferredWidth: 34 }
                                        Text { text: subsystem; color: root.textMain; font.family: "Consolas"; font.pixelSize: 8; font.bold: true; Layout.preferredWidth: 48 }
                                        Text { Layout.fillWidth: true; text: message; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 8; elide: Text.ElideRight }
                                    }
                                }
                                ScrollIndicator.vertical: ScrollIndicator { }
                            }
                        }
                    }
                }
            }
        }
    }
}