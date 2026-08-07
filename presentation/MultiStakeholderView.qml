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
    readonly property var selectedMissionData: selectedMission >= 0 && selectedMission < viewModel.missions.length ? viewModel.missions[selectedMission] : null

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
        Accessible.name: text
        Accessible.role: Accessible.Button
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
            Layout.preferredHeight: 82
            color: "#091412"
            border.color: root.line
            radius: 4

            ColumnLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 10
                anchors.topMargin: 7
                anchors.bottomMargin: 7
                spacing: 5

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    Column {
                        Layout.fillWidth: true
                        spacing: 1
                        Text { text: "MULTI-STAKEHOLDER ENVIRONMENT"; color: root.textMain; font.family: "Consolas"; font.pixelSize: 13; font.bold: true }
                        Text { text: "SHARED OPERATIONAL STATE / DELHI UAM SANDBOX"; visible: root.width >= 1180; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 9 }
                    }
                    Rectangle { width: 7; height: 7; radius: 4; color: root.viewModel.mqttConnected ? root.green : root.amber }
                    Column {
                        Layout.preferredWidth: root.width >= 950 ? 158 : 128
                        Text { text: root.viewModel.transportMode; color: root.viewModel.mqttConnected ? root.green : root.amber; font.family: "Consolas"; font.pixelSize: 10; font.bold: true }
                        Text { text: root.viewModel.transportStatusText; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 7; elide: Text.ElideRight; width: parent.width }
                    }
                    Text { text: root.viewModel.simulationTime + " IST"; color: root.textMain; font.family: "Consolas"; font.pixelSize: 17; font.bold: true }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        Layout.fillWidth: true
                        text: root.viewModel.mqttConnected ? "REMOTE EVENTS ONLY / LOCAL STATE LOCKED" : (root.viewModel.running ? "AUTO ADVANCE / 1 SIM MIN PER SECOND" : "PAUSED / MANUAL STEP READY")
                        color: root.viewModel.mqttConnected ? root.cyan : root.textMuted
                        font.family: "Consolas"
                        font.pixelSize: 8
                    }
                    ActionButton { Layout.preferredWidth: 76; text: root.viewModel.running ? "PAUSE" : "RESUME"; accent: root.amber; enabled: root.viewModel.localControlsEnabled; onClicked: root.viewModel.toggleRunning() }
                    ActionButton { Layout.preferredWidth: 76; text: "STEP +1"; enabled: root.viewModel.manualStepEnabled; onClicked: root.viewModel.advanceSimulation() }
                    ActionButton { Layout.preferredWidth: 68; text: "RESET"; accent: root.red; enabled: root.viewModel.localControlsEnabled; onClicked: root.viewModel.resetSimulation() }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 30
            visible: root.viewModel.actionMessage.length > 0
            color: root.viewModel.actionSeverity === "warning" ? "#2b2015" : "#10261f"
            border.color: root.viewModel.actionSeverity === "warning" ? root.amber : root.green
            radius: 3
            Text {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                text: root.viewModel.actionMessage
                color: root.viewModel.actionSeverity === "warning" ? root.amber : root.green
                font.family: "Consolas"
                font.pixelSize: 9
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }
        }

        TabBar {
            id: stakeholderTabs
            Layout.fillWidth: true
            currentIndex: root.stakeholderIndex
            onCurrentIndexChanged: root.stakeholderIndex = currentIndex

            Repeater {
                model: root.viewModel.stakeholderTabs
                TabButton {
                    required property string modelData
                    width: stakeholderTabs.width / 4
                    text: modelData
                    font.family: "Consolas"
                    font.pixelSize: 11
                    font.bold: checked
                    Accessible.name: modelData
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
                            model: root.viewModel.routeOptions
                            font.pixelSize: 10
                            enabled: root.viewModel.localControlsEnabled && root.viewModel.missions.length > 0
                            palette.button: root.raised
                            palette.buttonText: root.textMain
                            palette.base: root.raised
                            palette.text: root.textMain
                            palette.highlight: "#17352d"
                            palette.highlightedText: root.green
                        }
                        ComboBox {
                            id: profileSelector
                            Layout.preferredWidth: 110
                            implicitHeight: 30
                            model: root.viewModel.missionProfiles
                            font.pixelSize: 10
                            enabled: root.viewModel.localControlsEnabled && root.viewModel.missions.length > 0
                            palette.button: root.raised
                            palette.buttonText: root.textMain
                            palette.base: root.raised
                            palette.text: root.textMain
                            palette.highlight: "#17352d"
                            palette.highlightedText: root.green
                        }
                        ActionButton { text: "PLAN ROUTE"; enabled: root.viewModel.localControlsEnabled && root.viewModel.missions.length > 0; onClicked: root.viewModel.planMission(root.selectedMission, routeSelector.currentText, profileSelector.currentText) }
                    }
                    ListView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 3
                        clip: true
                        model: root.viewModel.missions
                        Text { anchors.centerIn: parent; visible: parent.count === 0; text: "NO MISSIONS AVAILABLE"; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 10 }
                        delegate: Rectangle {
                            required property int index
                            required property var modelData
                            width: ListView.view.width
                            height: 64
                            radius: 3
                            color: index === root.selectedMission ? "#17352d" : root.raised
                            border.color: modelData.severity === "warning" ? root.amber : (index === root.selectedMission ? root.green : root.line)
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
                                    Text { text: modelData.profile + "  /  " + modelData.status; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 10 }
                                }
                                Metric { Layout.preferredWidth: 70; label: "HEALTH"; value: modelData.health + "%" }
                            }
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        ActionButton { text: "BOOK PROFILE"; enabled: root.viewModel.localControlsEnabled && root.selectedMissionData !== null && root.selectedMissionData.canBook; onClicked: root.viewModel.bookMission(root.selectedMission) }
                        ActionButton { text: "DELAY +5 MIN"; enabled: root.viewModel.localControlsEnabled && root.selectedMissionData !== null; accent: root.amber; onClicked: root.viewModel.delayMission(root.selectedMission) }
                        Item { Layout.fillWidth: true }
                        Text { text: root.viewModel.workflowNotes.booking; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 8 }
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
                        Text { anchors.centerIn: parent; visible: parent.count === 0; text: "NO VERTIPORTS AVAILABLE"; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 10 }
                        delegate: Rectangle {
                            required property int index
                            required property var modelData
                            width: ListView.view.width
                            height: 72
                            radius: 3
                            color: index === root.selectedVertiport ? "#142c31" : root.raised
                            border.color: modelData.severity === "warning" ? root.amber : (index === root.selectedVertiport ? root.cyan : root.line)
                            MouseArea { anchors.fill: parent; onClicked: root.selectedVertiport = index }
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 16
                                Column {
                                    Layout.fillWidth: true
                                    Text { text: modelData.name; color: root.textMain; font.family: "Consolas"; font.pixelSize: 13; font.bold: true }
                                    Text { text: modelData.status; color: modelData.severity === "warning" ? root.amber : root.textMuted; font.family: "Consolas"; font.pixelSize: 10 }
                                }
                                Metric { label: "GATES"; value: modelData.freeGates + "/" + modelData.gates }
                                Metric { label: "CHARGERS"; value: modelData.freeChargers + "/" + modelData.chargers }
                                Metric { label: "PAX QUEUE"; value: modelData.queue.toString() }
                                Metric { label: modelData.chargingMinutes > 0 ? "CHARGE" : "TURN"; value: (modelData.chargingMinutes > 0 ? modelData.chargingMinutes : modelData.turnaround) + "m" }
                            }
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        ActionButton { text: "ASSIGN GATE"; enabled: root.viewModel.localControlsEnabled && root.viewModel.vertiports.length > 0; onClicked: root.viewModel.assignGate(root.selectedVertiport) }
                        ActionButton { text: "START CHARGING"; enabled: root.viewModel.localControlsEnabled && root.viewModel.vertiports.length > 0; accent: root.cyan; onClicked: root.viewModel.startCharging(root.selectedVertiport) }
                        Item { Layout.fillWidth: true }
                        Text { text: root.viewModel.workflowNotes.vertiport; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 8 }
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
                        Text { anchors.centerIn: parent; visible: parent.count === 0; text: "NO SLOT REQUESTS"; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 10 }
                        delegate: Rectangle {
                            required property int index
                            required property var modelData
                            width: ListView.view.width
                            height: 72
                            radius: 3
                            color: index === root.selectedSlot ? "#17352d" : root.raised
                            border.color: modelData.severity === "warning" ? root.amber : (index === root.selectedSlot ? root.green : root.line)
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
                                Text { text: modelData.status; color: modelData.severity === "warning" ? root.amber : root.green; font.family: "Consolas"; font.pixelSize: 9; font.bold: true }
                            }
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        ActionButton { text: "GRANT SLOT"; enabled: root.viewModel.localControlsEnabled && root.viewModel.slotRequests.length > 0; onClicked: root.viewModel.decideSlot(root.selectedSlot, true) }
                        ActionButton { text: "DENY SLOT"; enabled: root.viewModel.localControlsEnabled && root.viewModel.slotRequests.length > 0; accent: root.red; onClicked: root.viewModel.decideSlot(root.selectedSlot, false) }
                        Item { Layout.fillWidth: true }
                        Text { text: root.viewModel.workflowNotes.slot; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 8 }
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
                        Text { anchors.centerIn: parent; visible: parent.count === 0; text: "NO COMPLIANCE ZONES"; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 10 }
                        delegate: Rectangle {
                            required property int index
                            required property var modelData
                            width: ListView.view.width
                            height: 72
                            radius: 3
                            color: index === root.selectedZone ? "#2d2817" : root.raised
                            border.color: modelData.severity === "warning" ? root.amber : (index === root.selectedZone ? root.cyan : root.line)
                            MouseArea { anchors.fill: parent; onClicked: root.selectedZone = index }
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 14
                                Column {
                                    Layout.fillWidth: true
                                    Text { text: modelData.name; color: root.textMain; font.family: "Consolas"; font.pixelSize: 13; font.bold: true }
                                    Text { text: modelData.track + "  /  " + modelData.status; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 10 }
                                }
                                Metric { label: "OVERFLIGHTS"; value: modelData.current + "/" + modelData.cap }
                                Metric { label: "NOISE"; value: modelData.noise + " dBA" }
                                Rectangle { width: 7; height: 7; radius: 4; color: modelData.enforced ? root.green : root.textMuted }
                            }
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        ActionButton { text: "ENFORCE BOUNDARY"; enabled: root.viewModel.localControlsEnabled && root.viewModel.complianceZones.length > 0; accent: root.amber; onClicked: root.viewModel.setBoundaryEnforcement(root.selectedZone, true) }
                        ActionButton { text: "MONITOR ONLY"; enabled: root.viewModel.localControlsEnabled && root.viewModel.complianceZones.length > 0; accent: root.cyan; onClicked: root.viewModel.setBoundaryEnforcement(root.selectedZone, false) }
                        Item { Layout.fillWidth: true }
                        Text { text: root.viewModel.workflowNotes.compliance; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 8 }
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
                    Text { anchors.centerIn: parent; visible: parent.count === 0; text: "NO EVENTS RECEIVED"; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 9 }
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

    Connections {
        target: root.viewModel
        function onMissionsChanged() { root.selectedMission = Math.max(0, Math.min(root.selectedMission, root.viewModel.missions.length - 1)) }
        function onVertiportsChanged() { root.selectedVertiport = Math.max(0, Math.min(root.selectedVertiport, root.viewModel.vertiports.length - 1)) }
        function onSlotRequestsChanged() { root.selectedSlot = Math.max(0, Math.min(root.selectedSlot, root.viewModel.slotRequests.length - 1)) }
        function onComplianceZonesChanged() { root.selectedZone = Math.max(0, Math.min(root.selectedZone, root.viewModel.complianceZones.length - 1)) }
    }

    Shortcut { sequence: "Space"; enabled: root.visible && root.viewModel.localControlsEnabled; onActivated: root.viewModel.toggleRunning() }
    Shortcut { sequence: "Right"; enabled: root.visible && root.viewModel.manualStepEnabled; onActivated: root.viewModel.advanceSimulation() }
    Shortcut { sequence: "Ctrl+R"; enabled: root.visible && root.viewModel.localControlsEnabled; onActivated: root.viewModel.resetSimulation() }
    Shortcut { sequence: "Ctrl+1"; enabled: root.visible; onActivated: root.stakeholderIndex = 0 }
    Shortcut { sequence: "Ctrl+2"; enabled: root.visible; onActivated: root.stakeholderIndex = 1 }
    Shortcut { sequence: "Ctrl+3"; enabled: root.visible; onActivated: root.stakeholderIndex = 2 }
    Shortcut { sequence: "Ctrl+4"; enabled: root.visible; onActivated: root.stakeholderIndex = 3 }
}