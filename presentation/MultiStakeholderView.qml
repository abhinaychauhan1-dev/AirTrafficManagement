import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    required property var viewModel
    property int selectedMission: 0
    property int selectedVertiport: 0
    property int selectedSlot: 0
    property int selectedZone: 0
    property int stakeholderIndex: 0

    readonly property color panel: "#0c1716"
    readonly property color raised: "#12201e"
    readonly property color line: "#293a37"
    readonly property color textMain: "#d9e5e1"
    readonly property color textMuted: "#7f9690"
    readonly property color green: "#6fffc1"
    readonly property color amber: "#ffb443"
    readonly property color cyan: "#73d9ff"
    readonly property color red: "#ff746c"

    component PanelTitle: RowLayout {
        required property string title
        required property string role
        Layout.fillWidth: true
        spacing: 8
        Rectangle { width: 3; height: 20; color: root.cyan }
        Text { text: title; color: root.textMain; font.family: "Consolas"; font.pixelSize: 12; font.bold: true }
        Item { Layout.fillWidth: true }
        Text { text: role; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 9 }
    }

    component ActionButton: Button {
        id: action
        property color accent: root.green
        implicitHeight: 30
        font.family: "Consolas"
        font.pixelSize: 9
        font.bold: true
        contentItem: Text {
            text: action.text
            color: action.enabled ? action.accent : "#53635f"
            font: action.font
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        background: Rectangle {
            color: action.down ? "#203831" : (action.hovered ? "#182c28" : root.raised)
            border.color: action.enabled ? action.accent : root.line
            radius: 3
        }
    }

    component Metric: Column {
        required property string label
        required property string value
        spacing: 1
        Text { text: label; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 8 }
        Text { text: value; color: root.textMain; font.family: "Consolas"; font.pixelSize: 11; font.bold: true }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 52
            color: "#091412"
            border.color: root.line
            radius: 4

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 10
                spacing: 12
                Column {
                    Layout.preferredWidth: root.width >= 1180 ? 330 : 285
                    spacing: 1
                    Text { text: "MULTI-STAKEHOLDER ENVIRONMENT"; color: root.textMain; font.family: "Consolas"; font.pixelSize: 13; font.bold: true }
                    Text { text: "SHARED OPERATIONAL STATE / DELHI UAM SANDBOX"; visible: root.width >= 1180; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 9 }
                }
                Item { Layout.fillWidth: true }
                Rectangle { width: 7; height: 7; radius: 4; color: root.viewModel.mqttConnected ? root.green : root.amber }
                Column {
                    Layout.preferredWidth: 142
                    Text { text: root.viewModel.transportMode; color: root.viewModel.mqttConnected ? root.green : root.amber; font.family: "Consolas"; font.pixelSize: 10; font.bold: true }
                    Text { text: root.viewModel.mqttConnected ? root.viewModel.brokerDescription : "MQTT OFFLINE"; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 7 }
                }
                Rectangle { width: 1; Layout.fillHeight: true; Layout.topMargin: 12; Layout.bottomMargin: 12; color: root.line }
                Text { text: root.viewModel.simulationTime + " IST"; color: root.textMain; font.family: "Consolas"; font.pixelSize: 17; font.bold: true }
                ActionButton { Layout.preferredWidth: 68; text: root.viewModel.running ? "PAUSE" : "RESUME"; accent: root.amber; onClicked: root.viewModel.running = !root.viewModel.running }
                ActionButton { Layout.preferredWidth: 68; visible: root.width >= 1180; text: "STEP +1"; enabled: !root.viewModel.running; onClicked: root.viewModel.advanceSimulation() }
                ActionButton { Layout.preferredWidth: 62; visible: root.width >= 1180; text: "RESET"; accent: root.red; onClicked: root.viewModel.resetSimulation() }
            }
        }

        TabBar {
            id: stakeholderTabs
            Layout.fillWidth: true
            currentIndex: root.stakeholderIndex
            onCurrentIndexChanged: root.stakeholderIndex = currentIndex

            Repeater {
                model: ["FLEET OPERATIONS", "VERTIPORT", "ANSP / PSU", "URBAN AUTHORITY"]
                TabButton {
                    required property string modelData
                    width: stakeholderTabs.width / 4
                    text: modelData
                    font.family: "Consolas"
                    font.pixelSize: 11
                    font.bold: checked
                    contentItem: Text {
                        text: parent.text
                        color: parent.checked ? root.green : root.textMuted
                        font: parent.font
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: parent.checked ? "#17352d" : root.panel
                        border.color: parent.checked ? root.green : root.line
                        radius: 3
                    }
                }
            }
        }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: root.stakeholderIndex

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
                    PanelTitle { title: "FLEET OPERATOR WORKSTATION"; role: "DISPATCH / MISSION CONTROL" }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        ComboBox {
                            id: routeSelector
                            Layout.fillWidth: true
                            implicitHeight: 30
                            model: ["Dilli Haat - IGI", "Noida - Connaught Place", "Gurugram - IGI", "Rohini - Aerocity"]
                            font.pixelSize: 10
                        }
                        ComboBox {
                            id: profileSelector
                            Layout.preferredWidth: 110
                            implicitHeight: 30
                            model: ["COMMUTER", "AIRPORT", "CARGO", "MEDEVAC"]
                            font.pixelSize: 10
                        }
                        ActionButton { text: "PLAN ROUTE"; onClicked: root.viewModel.planMission(root.selectedMission, routeSelector.currentText, profileSelector.currentText) }
                    }
                    ListView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 3
                        clip: true
                        model: root.viewModel.missions
                        delegate: Rectangle {
                            required property int index
                            required property var modelData
                            width: ListView.view.width
                            height: 64
                            radius: 3
                            color: index === root.selectedMission ? "#17352d" : root.raised
                            border.color: modelData.health < 60 ? root.amber : (index === root.selectedMission ? root.green : root.line)
                            MouseArea { anchors.fill: parent; onClicked: root.selectedMission = index }
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 10
                                Column {
                                    Layout.preferredWidth: 72
                                    Text { text: modelData.callSign; color: root.textMain; font.family: "Consolas"; font.pixelSize: 13; font.bold: true }
                                    Text { text: "DEPART " + modelData.departure; color: root.cyan; font.family: "Consolas"; font.pixelSize: 10 }
                                }
                                Column {
                                    Layout.fillWidth: true
                                    Text { text: modelData.route; color: root.textMain; font.pixelSize: 12; elide: Text.ElideRight; width: parent.width }
                                    Text { text: modelData.profile + "  •  " + modelData.status; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 10 }
                                }
                                Metric { Layout.preferredWidth: 70; label: "HEALTH"; value: modelData.health + "%" }
                            }
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        ActionButton { text: "BOOK PROFILE"; onClicked: root.viewModel.bookMission(root.selectedMission) }
                        ActionButton { text: "DELAY +5 MIN"; accent: root.amber; onClicked: root.viewModel.delayMission(root.selectedMission) }
                        Item { Layout.fillWidth: true }
                        Text { text: "Health <60% blocks booking"; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 8 }
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
                    PanelTitle { title: "VERTIPORT OPERATOR DASHBOARD"; role: "GATES / CHARGING / PAX" }
                    ListView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 4
                        clip: true
                        model: root.viewModel.vertiports
                        delegate: Rectangle {
                            required property int index
                            required property var modelData
                            width: ListView.view.width
                            height: 72
                            radius: 3
                            color: index === root.selectedVertiport ? "#142c31" : root.raised
                            border.color: modelData.freeGates === 0 ? root.amber : (index === root.selectedVertiport ? root.cyan : root.line)
                            MouseArea { anchors.fill: parent; onClicked: root.selectedVertiport = index }
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 16
                                Column {
                                    Layout.fillWidth: true
                                    Text { text: modelData.name; color: root.textMain; font.family: "Consolas"; font.pixelSize: 13; font.bold: true }
                                    Text { text: modelData.status; color: modelData.status === "SATURATED" ? root.amber : root.textMuted; font.family: "Consolas"; font.pixelSize: 10 }
                                }
                                Metric { label: "GATES"; value: modelData.freeGates + "/" + modelData.gates }
                                Metric { label: "CHARGERS"; value: modelData.freeChargers + "/" + modelData.chargers }
                                Metric { label: "PAX QUEUE"; value: modelData.queue.toString() }
                                Metric { label: "TURN"; value: modelData.turnaround + "m" }
                            }
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        ActionButton { text: "ASSIGN GATE"; onClicked: root.viewModel.assignGate(root.selectedVertiport) }
                        ActionButton { text: "START CHARGING"; accent: root.cyan; onClicked: root.viewModel.startCharging(root.selectedVertiport) }
                        Item { Layout.fillWidth: true }
                        Text { text: "Resources update in shared time"; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 8 }
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
                    PanelTitle { title: "ANSP / PSU FLOW INTERFACE"; role: "CORRIDORS / SLOT ALLOCATION" }
                    ListView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 4
                        clip: true
                        model: root.viewModel.slotRequests
                        delegate: Rectangle {
                            required property int index
                            required property var modelData
                            width: ListView.view.width
                            height: 72
                            radius: 3
                            color: index === root.selectedSlot ? "#17352d" : root.raised
                            border.color: modelData.status === "HELD - NOISE" ? root.amber : (index === root.selectedSlot ? root.green : root.line)
                            MouseArea { anchors.fill: parent; onClicked: root.selectedSlot = index }
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 14
                                Column {
                                    Layout.preferredWidth: 78
                                    Text { text: modelData.requestId; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 10 }
                                    Text { text: modelData.callSign; color: root.textMain; font.family: "Consolas"; font.pixelSize: 13; font.bold: true }
                                }
                                Metric { label: "CORRIDOR"; value: modelData.corridor }
                                Metric { label: "REQUEST"; value: modelData.desired }
                                Item { Layout.fillWidth: true }
                                Text { text: modelData.status; color: modelData.status === "DENIED" || modelData.status === "HELD - NOISE" ? root.amber : root.green; font.family: "Consolas"; font.pixelSize: 9; font.bold: true }
                            }
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        ActionButton { text: "GRANT SLOT"; onClicked: root.viewModel.decideSlot(root.selectedSlot, true) }
                        ActionButton { text: "DENY SLOT"; accent: root.red; onClicked: root.viewModel.decideSlot(root.selectedSlot, false) }
                        Item { Layout.fillWidth: true }
                        Text { text: "Decisions propagate to fleet status"; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 8 }
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
                    PanelTitle { title: "URBAN AUTHORITY DASHBOARD"; role: "NOISE / CAPS / BOUNDARIES" }
                    ListView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 4
                        clip: true
                        model: root.viewModel.complianceZones
                        delegate: Rectangle {
                            required property int index
                            required property var modelData
                            width: ListView.view.width
                            height: 72
                            radius: 3
                            color: index === root.selectedZone ? "#2d2817" : root.raised
                            border.color: modelData.current >= modelData.cap ? root.amber : (index === root.selectedZone ? root.cyan : root.line)
                            MouseArea { anchors.fill: parent; onClicked: root.selectedZone = index }
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 14
                                Column {
                                    Layout.fillWidth: true
                                    Text { text: modelData.name; color: root.textMain; font.family: "Consolas"; font.pixelSize: 13; font.bold: true }
                                    Text { text: modelData.track + "  •  " + modelData.status; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 10 }
                                }
                                Metric { label: "OVERFLIGHTS"; value: modelData.current + "/" + modelData.cap }
                                Metric { label: "NOISE"; value: modelData.noise + " dBA" }
                                Rectangle { width: 7; height: 7; radius: 4; color: modelData.enforced ? root.green : root.textMuted }
                            }
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        ActionButton { text: "ENFORCE BOUNDARY"; accent: root.amber; onClicked: root.viewModel.setBoundaryEnforcement(root.selectedZone, true) }
                        ActionButton { text: "MONITOR ONLY"; accent: root.cyan; onClicked: root.viewModel.setBoundaryEnforcement(root.selectedZone, false) }
                        Item { Layout.fillWidth: true }
                        Text { text: "Cap enforcement holds pending slots"; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 8 }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 104
            color: "#091412"
            border.color: root.line
            radius: 4
            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 12
                ColumnLayout {
                    Layout.preferredWidth: 178
                    Text { text: "SHARED ACTIVITY"; color: root.textMain; font.family: "Consolas"; font.pixelSize: 11; font.bold: true }
                    Text { text: "Cross-stakeholder event bus"; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 8 }
                    Item { Layout.fillHeight: true }
                }
                Rectangle { width: 1; Layout.fillHeight: true; color: root.line }
                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 2
                    model: root.viewModel.activityLog
                    delegate: Text {
                        required property string modelData
                        width: ListView.view.width
                        text: modelData
                        color: root.textMuted
                        font.family: "Consolas"
                        font.pixelSize: 9
                    }
                }
            }
        }
    }
}