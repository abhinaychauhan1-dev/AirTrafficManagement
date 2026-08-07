import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    required property var viewModel
    property int selectedPad: 0
    property int queueMode: 0
    property real windSpeed: 7.8
    property real windGust: 12.4
    property int windDirection: 238
    property real temperature: 29.6
    property int visibilityKm: 9
    property real pressure: 1007.8
    property int telemetryTick: 0

    readonly property color panel: "#0c1716"
    readonly property color raised: "#12201e"
    readonly property color deep: "#091412"
    readonly property color line: "#293a37"
    readonly property color textMain: "#d9e5e1"
    readonly property color textMuted: "#7f9690"
    readonly property color green: "#6fffc1"
    readonly property color cyan: "#73d9ff"
    readonly property color amber: "#ffb443"
    readonly property color red: "#ff746c"

    function padColor(status) {
        if (status === "AVAILABLE") return green
        if (status === "OCCUPIED") return cyan
        if (status === "RESERVED") return amber
        return red
    }

    function setSelectedPadStatus(status) {
        if (selectedPad < 0 || selectedPad >= padModel.count)
            return
        padModel.setProperty(selectedPad, "status", status)
        if (status === "AVAILABLE") {
            padModel.setProperty(selectedPad, "airTaxi", "--")
            padModel.setProperty(selectedPad, "detail", "READY FOR ASSIGNMENT")
        } else if (status === "RESERVED") {
            padModel.setProperty(selectedPad, "airTaxi", "NEXT")
            padModel.setProperty(selectedPad, "detail", "ARRIVAL WINDOW +04 MIN")
        } else if (status === "MAINTENANCE") {
            padModel.setProperty(selectedPad, "airTaxi", "LOCKED")
            padModel.setProperty(selectedPad, "detail", "GROUND CREW INSPECTION")
        }
    }

    component PanelTitle: RowLayout {
        required property string title
        property string meta: "LIVE"
        Layout.fillWidth: true
        spacing: 8
        Rectangle { width: 3; height: 20; color: root.cyan }
        Text { text: title; color: root.textMain; font.family: "Consolas"; font.pixelSize: 14; font.bold: true }
        Item { Layout.fillWidth: true }
        Text { text: meta; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 10; font.bold: true }
    }

    component OpsButton: Button {
        id: control
        property color accent: root.green
        implicitHeight: 34
        hoverEnabled: true
        font.family: "Consolas"
        font.pixelSize: 10
        font.bold: true
        contentItem: Text {
            text: control.text
            color: control.enabled ? control.accent : "#53635f"
            font: control.font
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        background: Rectangle {
            radius: 3
            color: control.down ? "#203831" : (control.hovered ? "#182c28" : root.raised)
            border.color: control.enabled ? control.accent : root.line
            Behavior on color { ColorAnimation { duration: 120 } }
        }
    }

    component StatusBadge: Rectangle {
        required property string status
        property color accent: root.padColor(status)
        implicitWidth: badgeText.implicitWidth + 16
        implicitHeight: 24
        radius: 3
        color: Qt.rgba(accent.r, accent.g, accent.b, 0.1)
        border.color: Qt.rgba(accent.r, accent.g, accent.b, 0.65)
        Text {
            id: badgeText
            anchors.centerIn: parent
            text: status
            color: accent
            font.family: "Consolas"
            font.pixelSize: 9
            font.bold: true
        }
    }

    component WeatherMetric: Rectangle {
        required property string label
        required property string value
        property string unit: ""
        property color accent: root.textMain
        implicitHeight: 58
        color: root.deep
        border.color: root.line
        radius: 3
        Column {
            anchors.centerIn: parent
            spacing: 2
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: label; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 9; font.bold: true }
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: value + (unit.length ? " " + unit : ""); color: accent; font.family: "Consolas"; font.pixelSize: 15; font.bold: true }
        }
    }

    ListModel {
        id: padModel
        ListElement { pad: "A1"; status: "OCCUPIED"; airTaxi: "ATX201"; detail: "CHARGING / 06 MIN" }
        ListElement { pad: "A2"; status: "RESERVED"; airTaxi: "URB308"; detail: "ARRIVAL WINDOW +03 MIN" }
        ListElement { pad: "A3"; status: "AVAILABLE"; airTaxi: "--"; detail: "READY FOR ASSIGNMENT" }
        ListElement { pad: "A4"; status: "MAINTENANCE"; airTaxi: "LOCKED"; detail: "FOD INSPECTION / 12 MIN" }
        ListElement { pad: "B1"; status: "AVAILABLE"; airTaxi: "--"; detail: "READY FOR ASSIGNMENT" }
        ListElement { pad: "B2"; status: "OCCUPIED"; airTaxi: "SKY114"; detail: "BATTERY SWAP / 04 MIN" }
        ListElement { pad: "B3"; status: "RESERVED"; airTaxi: "MED805"; detail: "DEPARTURE WINDOW +07 MIN" }
        ListElement { pad: "B4"; status: "AVAILABLE"; airTaxi: "--"; detail: "READY FOR ASSIGNMENT" }
    }

    ListModel {
        id: turnaroundModel
        ListElement { callSign: "ATX201"; pad: "A1"; task: "RAPID CHARGE"; progress: 68; battery: 76; elapsed: 11; target: 17; accent: "green" }
        ListElement { callSign: "SKY114"; pad: "B2"; task: "BATTERY SWAP"; progress: 42; battery: 54; elapsed: 7; target: 14; accent: "cyan" }
        ListElement { callSign: "URB308"; pad: "A2"; task: "GROUND CHECK"; progress: 84; battery: 73; elapsed: 13; target: 16; accent: "amber" }
    }

    ListModel {
        id: arrivalModel
        ListElement { order: "01"; callSign: "URB308"; route: "VPT-DILLI"; time: "08:32"; state: "FINAL"; priority: "NORMAL" }
        ListElement { order: "02"; callSign: "MED805"; route: "AIIMS-V8"; time: "08:36"; state: "HOLD 2 MIN"; priority: "MEDICAL" }
        ListElement { order: "03"; callSign: "ECO518"; route: "VPT-CP"; time: "08:41"; state: "INBOUND"; priority: "NORMAL" }
    }

    ListModel {
        id: departureModel
        ListElement { order: "01"; callSign: "ATX201"; route: "VPT-IGI"; time: "08:35"; state: "PAD READY"; priority: "NORMAL" }
        ListElement { order: "02"; callSign: "SKY114"; route: "VPT-CP"; time: "08:39"; state: "CHARGING"; priority: "NORMAL" }
        ListElement { order: "03"; callSign: "UAM412"; route: "VPT-NOIDA"; time: "08:44"; state: "SLOT HELD"; priority: "NORMAL" }
    }

    Timer {
        interval: 1500
        running: root.visible
        repeat: true
        onTriggered: {
            root.telemetryTick++
            root.windSpeed = 7.8 + Math.sin(root.telemetryTick * 0.42) * 1.4
            root.windGust = root.windSpeed + 3.8 + Math.sin(root.telemetryTick * 0.21) * 0.8
            root.windDirection = (238 + root.telemetryTick * 2) % 360
            root.temperature = 29.6 + Math.sin(root.telemetryTick * 0.12) * 0.5
            root.pressure = 1007.8 + Math.sin(root.telemetryTick * 0.16) * 0.7
            for (let index = 0; index < turnaroundModel.count; ++index) {
                const current = turnaroundModel.get(index)
                if (current.progress < 100) {
                    turnaroundModel.setProperty(index, "progress", Math.min(100, current.progress + 1))
                    turnaroundModel.setProperty(index, "battery", Math.min(100, current.battery + (index === 0 ? 1 : 0)))
                    if (root.telemetryTick % 4 === 0)
                        turnaroundModel.setProperty(index, "elapsed", current.elapsed + 1)
                }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 92
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
                    spacing: 3
                    Text { text: "HUB & GROUND OPERATIONS"; color: root.textMain; font.family: "Consolas"; font.pixelSize: 21; font.bold: true }
                    Text { text: "VPT-IGI / DELHI PRIMARY HUB  |  PAD, ENERGY, FLOW AND WEATHER CONTROL"; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 11 }
                }
                StatusBadge { status: root.windGust < 18 ? "VTOL CONDITIONS NORMAL" : "WIND CAUTION"; accent: root.windGust < 18 ? root.green : root.amber }
                Column {
                    Layout.preferredWidth: 112
                    Text { width: parent.width; text: root.viewModel.simulationTime; color: root.textMain; font.family: "Consolas"; font.pixelSize: 20; font.bold: true; horizontalAlignment: Text.AlignRight }
                    Text { width: parent.width; text: "LIVE OPERATIONS / IST"; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 9; horizontalAlignment: Text.AlignRight }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 720
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 330
                    color: root.panel
                    border.color: root.line
                    radius: 4
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8
                        PanelTitle { title: "LANDING PAD STATUS BOARD"; meta: "8 PADS / SELECT TO MANAGE" }
                        GridView {
                            id: padGrid
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            model: padModel
                            cellWidth: width / 4
                            cellHeight: height / 2
                            delegate: Item {
                                required property int index
                                required property string pad
                                required property string status
                                required property string airTaxi
                                required property string detail
                                width: padGrid.cellWidth
                                height: padGrid.cellHeight
                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: 4
                                    radius: 3
                                    color: index === root.selectedPad ? "#17352d" : root.deep
                                    border.width: index === root.selectedPad ? 2 : 1
                                    border.color: index === root.selectedPad ? root.padColor(status) : root.line
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                    MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.selectedPad = index }
                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 10
                                        spacing: 4
                                        RowLayout {
                                            Layout.fillWidth: true
                                            Text { text: pad; color: root.textMain; font.family: "Consolas"; font.pixelSize: 18; font.bold: true }
                                            Item { Layout.fillWidth: true }
                                            Rectangle { width: 9; height: 9; radius: 5; color: root.padColor(status) }
                                        }
                                        Text { text: airTaxi; color: root.padColor(status); font.family: "Consolas"; font.pixelSize: 14; font.bold: true }
                                        Text { Layout.fillWidth: true; text: detail; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 9; elide: Text.ElideRight }
                                        Item { Layout.fillHeight: true }
                                        Text { text: status; color: root.padColor(status); font.family: "Consolas"; font.pixelSize: 10; font.bold: true }
                                    }
                                }
                            }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6
                            Text { text: "PAD " + padModel.get(root.selectedPad).pad; color: root.textMain; font.family: "Consolas"; font.pixelSize: 11; font.bold: true }
                            Item { Layout.fillWidth: true }
                            OpsButton { text: "RESERVE"; accent: root.amber; onClicked: root.setSelectedPadStatus("RESERVED") }
                            OpsButton { text: "MARK AVAILABLE"; onClicked: root.setSelectedPadStatus("AVAILABLE") }
                            OpsButton { text: "MAINTENANCE"; accent: root.red; onClicked: root.setSelectedPadStatus("MAINTENANCE") }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: root.panel
                    border.color: root.line
                    radius: 4
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 7
                        PanelTitle { title: "TURNAROUND & CHARGING TRACKER"; meta: "LIVE GROUND SERVICE" }
                        ListView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            spacing: 5
                            model: turnaroundModel
                            delegate: Rectangle {
                                required property string callSign
                                required property string pad
                                required property string task
                                required property int progress
                                required property int battery
                                required property int elapsed
                                required property int target
                                required property string accent
                                width: ListView.view.width
                                height: 68
                                color: root.deep
                                border.color: root.line
                                radius: 3
                                readonly property color rowAccent: accent === "cyan" ? root.cyan : (accent === "amber" ? root.amber : root.green)
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 9
                                    spacing: 12
                                    Column { Layout.preferredWidth: 92; Text { text: callSign; color: root.textMain; font.family: "Consolas"; font.pixelSize: 14; font.bold: true } Text { text: "PAD " + pad; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 10 } }
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 5
                                        RowLayout { Layout.fillWidth: true; Text { text: task; color: rowAccent; font.family: "Consolas"; font.pixelSize: 10; font.bold: true } Item { Layout.fillWidth: true } Text { text: progress + "%"; color: rowAccent; font.family: "Consolas"; font.pixelSize: 11; font.bold: true } }
                                        Rectangle { Layout.fillWidth: true; height: 7; radius: 3; color: "#1c2c29"; Rectangle { width: parent.width * progress / 100; height: parent.height; radius: 3; color: rowAccent; Behavior on width { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } } } }
                                    }
                                    Column { Layout.preferredWidth: 72; Text { text: "BATTERY"; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 9 } Text { text: battery + "%"; color: battery < 60 ? root.amber : root.green; font.family: "Consolas"; font.pixelSize: 13; font.bold: true } }
                                    Column { Layout.preferredWidth: 88; Text { text: "TURNAROUND"; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 9 } Text { text: elapsed + " / " + target + " MIN"; color: elapsed > target ? root.red : root.textMain; font.family: "Consolas"; font.pixelSize: 12; font.bold: true } }
                                }
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.preferredWidth: Math.max(390, root.width * 0.34)
                Layout.fillHeight: true
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: root.panel
                    border.color: root.line
                    radius: 4
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 7
                        PanelTitle { title: "ARRIVAL & DEPARTURE QUEUE"; meta: "FLOW SEQUENCING" }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 5
                            OpsButton { Layout.fillWidth: true; text: "ARRIVALS  " + arrivalModel.count; accent: root.queueMode === 0 ? root.cyan : root.textMuted; onClicked: root.queueMode = 0 }
                            OpsButton { Layout.fillWidth: true; text: "DEPARTURES  " + departureModel.count; accent: root.queueMode === 1 ? root.green : root.textMuted; onClicked: root.queueMode = 1 }
                        }
                        ListView {
                            id: queueList
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            spacing: 5
                            model: root.queueMode === 0 ? arrivalModel : departureModel
                            delegate: Rectangle {
                                required property string order
                                required property string callSign
                                required property string route
                                required property string time
                                required property string state
                                required property string priority
                                width: ListView.view.width
                                height: 66
                                radius: 3
                                color: root.deep
                                border.color: priority === "MEDICAL" ? root.red : root.line
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 10
                                    Text { text: order; color: root.queueMode === 0 ? root.cyan : root.green; font.family: "Consolas"; font.pixelSize: 18; font.bold: true }
                                    Column { Layout.fillWidth: true; Text { text: callSign + "  /  " + route; width: parent.width; color: root.textMain; font.family: "Consolas"; font.pixelSize: 12; font.bold: true; elide: Text.ElideRight } Text { text: state; color: priority === "MEDICAL" ? root.red : root.textMuted; font.family: "Consolas"; font.pixelSize: 10 } }
                                    Text { text: time; color: root.textMain; font.family: "Consolas"; font.pixelSize: 13; font.bold: true }
                                }
                            }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            Text { Layout.fillWidth: true; text: root.queueMode === 0 ? "NEXT PAD: A2 / SEPARATION 90 SEC" : "NEXT RELEASE: C-DELTA"; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 9 }
                            OpsButton {
                                text: "ADVANCE QUEUE"
                                accent: root.queueMode === 0 ? root.cyan : root.green
                                onClicked: {
                                    const model = root.queueMode === 0 ? arrivalModel : departureModel
                                    if (model.count > 1) {
                                        const first = model.get(0)
                                        model.remove(0)
                                        model.append(first)
                                        for (let index = 0; index < model.count; ++index)
                                            model.setProperty(index, "order", String(index + 1).padStart(2, "0"))
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 254
                    color: root.panel
                    border.color: root.windGust < 18 ? root.line : root.amber
                    radius: 4
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 7
                        PanelTitle { title: "LOCAL WEATHER & WIND"; meta: "ANEMOMETER WX-IGI-04" }
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Rectangle {
                                Layout.preferredWidth: 138
                                Layout.fillHeight: true
                                color: root.deep
                                border.color: root.line
                                radius: 3
                                Item {
                                    anchors.centerIn: parent
                                    width: Math.min(parent.width, parent.height) - 28
                                    height: width
                                    Rectangle { anchors.fill: parent; radius: width / 2; color: "transparent"; border.color: root.line }
                                    Repeater {
                                        model: 8
                                        Text {
                                            required property int index
                                            anchors.centerIn: parent
                                            text: index % 2 === 0 ? ["N", "E", "S", "W"][index / 2] : "•"
                                            color: index % 2 === 0 ? root.textMuted : root.line
                                            font.family: "Consolas"
                                            font.pixelSize: index % 2 === 0 ? 10 : 8
                                            transform: Translate { x: Math.sin(index * Math.PI / 4) * 43; y: -Math.cos(index * Math.PI / 4) * 43 }
                                        }
                                    }
                                    Rectangle {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        anchors.bottom: parent.verticalCenter
                                        width: 3
                                        height: parent.height * 0.36
                                        radius: 2
                                        color: root.cyan
                                        transformOrigin: Item.Bottom
                                        rotation: root.windDirection
                                        Behavior on rotation { NumberAnimation { duration: 700; easing.type: Easing.InOutCubic } }
                                    }
                                    Rectangle { anchors.centerIn: parent; width: 10; height: 10; radius: 5; color: root.cyan }
                                    Text { anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: 8; text: root.windDirection + "°"; color: root.textMain; font.family: "Consolas"; font.pixelSize: 12; font.bold: true }
                                }
                            }
                            GridLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                columns: 2
                                rowSpacing: 6
                                columnSpacing: 6
                                WeatherMetric { Layout.fillWidth: true; label: "WIND"; value: root.windSpeed.toFixed(1); unit: "KT"; accent: root.cyan }
                                WeatherMetric { Layout.fillWidth: true; label: "GUST"; value: root.windGust.toFixed(1); unit: "KT"; accent: root.windGust < 18 ? root.green : root.amber }
                                WeatherMetric { Layout.fillWidth: true; label: "TEMP"; value: root.temperature.toFixed(1); unit: "°C" }
                                WeatherMetric { Layout.fillWidth: true; label: "VISIBILITY"; value: root.visibilityKm; unit: "KM" }
                                WeatherMetric { Layout.fillWidth: true; label: "QNH"; value: root.pressure.toFixed(0); unit: "HPA" }
                                WeatherMetric { Layout.fillWidth: true; label: "GUST LIMIT"; value: "18"; unit: "KT"; accent: root.amber }
                            }
                        }
                    }
                }
            }
        }
    }
}