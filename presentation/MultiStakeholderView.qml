import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    required property var viewModel
    readonly property int selectedMission: viewModel.activeMissionIndex
    property int selectedVertiport: 0
    property int selectedSlot: 0
    property int selectedZone: 0
    property int stakeholderIndex: 0
    readonly property var selectedMissionData: viewModel.activeMission

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
        Text { text: title; color: root.textMain; font.family: "Consolas"; font.pixelSize: 15; font.bold: true }
        Item { Layout.fillWidth: true }
        Text { text: role; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 11 }
    }

    component ActionButton: Button {
        id: action
        property color accent: root.green
        implicitHeight: 34
        font.family: "Consolas"
        font.pixelSize: 11
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
        Text { text: label; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 11 }
        Text { text: value; color: root.textMain; font.family: "Consolas"; font.pixelSize: 14; font.bold: true }
    }

    component TelemetryProgress: ColumnLayout {
        required property string label
        required property real value
        property color accent: root.green
        spacing: 3

        RowLayout {
            Layout.fillWidth: true
            Text { text: label; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 11 }
            Item { Layout.fillWidth: true }
            Text { text: Math.round(value) + "%"; color: accent; font.family: "Consolas"; font.pixelSize: 12; font.bold: true }
        }
        ProgressBar {
            id: telemetryBar
            Layout.fillWidth: true
            implicitHeight: 7
            from: 0
            to: 100
            value: parent.value
            background: Rectangle { color: "#1c2c29"; radius: 2 }
            contentItem: Item {
                implicitHeight: 7
                Rectangle {
                    width: telemetryBar.visualPosition * parent.width
                    height: parent.height
                    radius: 2
                    color: telemetryBar.parent.accent
                    Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
                }
            }
        }
    }

    component MissionHealthGraph: Canvas {
        id: healthGraph
        required property var missionModel
        required property int activeIndex
        signal missionSelected(int index)

        renderTarget: Canvas.FramebufferObject
        antialiasing: true
        onMissionModelChanged: requestPaint()
        onActiveIndexChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            const context = getContext("2d")
            context.reset()
            const count = missionModel ? missionModel.length : 0
            if (count === 0)
                return

            const chartTop = 12
            const chartBottom = height - 24
            const chartHeight = chartBottom - chartTop
            const columnWidth = width / count
            context.strokeStyle = root.line
            context.lineWidth = 1
            for (let level = 0; level <= 4; ++level) {
                const gridY = chartTop + chartHeight * level / 4
                context.beginPath()
                context.moveTo(0, gridY)
                context.lineTo(width, gridY)
                context.stroke()
            }

            for (let index = 0; index < count; ++index) {
                const mission = missionModel[index]
                const health = Math.max(0, Math.min(100, Number(mission.health)))
                const barWidth = Math.min(42, columnWidth * 0.52)
                const barHeight = chartHeight * health / 100
                const barX = columnWidth * index + (columnWidth - barWidth) / 2
                const barY = chartBottom - barHeight
                context.fillStyle = index === activeIndex ? root.green : (health < 60 ? root.amber : root.cyan)
                context.globalAlpha = index === activeIndex ? 1 : 0.62
                context.fillRect(barX, barY, barWidth, barHeight)
                context.globalAlpha = 1
                context.fillStyle = index === activeIndex ? root.textMain : root.textMuted
                context.font = (index === activeIndex ? "bold " : "") + "11px Consolas"
                context.textAlign = "center"
                context.fillText(mission.callSign, columnWidth * (index + 0.5), height - 7)
                context.fillText(Math.round(health) + "%", columnWidth * (index + 0.5), Math.max(9, barY - 4))
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                const count = healthGraph.missionModel ? healthGraph.missionModel.length : 0
                if (count > 0)
                    healthGraph.missionSelected(Math.min(count - 1, Math.floor(mouse.x / (width / count))))
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 90
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
                        Text { text: "ACTIVE TAXI MISSIONS"; color: root.textMain; font.family: "Consolas"; font.pixelSize: 16; font.bold: true }
                        Text { text: root.selectedMissionData.callSign + "  /  " + root.selectedMissionData.route + "  /  " + root.selectedMissionData.status; visible: root.width >= 1180; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 11 }
                    }
                    Rectangle {
                        width: 7
                        height: 7
                        radius: 4
                        color: root.viewModel.mqttConnected ? root.green : root.amber
                        SequentialAnimation on opacity {
                            running: root.viewModel.running || root.viewModel.mqttConnected
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.25; duration: 650 }
                            NumberAnimation { to: 1; duration: 650 }
                        }
                    }
                    Column {
                        Layout.preferredWidth: root.width >= 950 ? 158 : 128
                        Text { text: root.viewModel.transportMode; color: root.viewModel.mqttConnected ? root.green : root.amber; font.family: "Consolas"; font.pixelSize: 12; font.bold: true }
                        Text { text: root.viewModel.transportStatusText; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 11; elide: Text.ElideRight; width: parent.width }
                    }
                    Text { text: root.viewModel.simulationTime + " IST"; color: root.textMain; font.family: "Consolas"; font.pixelSize: 20; font.bold: true }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        Layout.fillWidth: true
                        text: root.viewModel.mqttConnected ? "REMOTE EVENTS ONLY / LOCAL STATE LOCKED" : (root.viewModel.running ? "AUTO ADVANCE / 1 SIM MIN PER SECOND" : "PAUSED / MANUAL STEP READY")
                        color: root.viewModel.mqttConnected ? root.cyan : root.textMuted
                        font.family: "Consolas"
                        font.pixelSize: 11
                    }
                    ActionButton { Layout.preferredWidth: 76; text: root.viewModel.running ? "PAUSE" : "RESUME"; accent: root.amber; enabled: root.viewModel.localControlsEnabled; onClicked: root.viewModel.toggleRunning() }
                    ActionButton { Layout.preferredWidth: 76; text: "STEP +1"; enabled: root.viewModel.manualStepEnabled; onClicked: root.viewModel.advanceSimulation() }
                    ActionButton { Layout.preferredWidth: 68; text: "RESET"; accent: root.red; enabled: root.viewModel.localControlsEnabled; onClicked: root.viewModel.resetSimulation() }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 36
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
                font.pixelSize: 11
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
                    font.pixelSize: 13
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
                    PanelTitle { title: "ACTIVE TAXI MISSION"; role: "CURRENT MISSION / DISPATCH" }
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 154
                        spacing: 8

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: "#091412"
                            border.color: root.line
                            radius: 3

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 9
                                spacing: 5
                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "FLEET HEALTH"; color: root.textMain; font.family: "Consolas"; font.pixelSize: 12; font.bold: true }
                                    Item { Layout.fillWidth: true }
                                    Text { text: "SELECT A BAR"; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 11 }
                                }
                                MissionHealthGraph {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    missionModel: root.viewModel.missions
                                    activeIndex: root.selectedMission
                                    onMissionSelected: index => root.viewModel.setActiveMissionIndex(index)
                                }
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: Math.min(320, root.width * 0.3)
                            Layout.fillHeight: true
                            color: "#091412"
                            border.color: root.line
                            radius: 3

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 7
                                Text { text: "MISSION READINESS"; color: root.textMain; font.family: "Consolas"; font.pixelSize: 12; font.bold: true }
                                TelemetryProgress {
                                    Layout.fillWidth: true
                                    label: "VEHICLE HEALTH"
                                    value: Number(root.selectedMissionData.health || 0)
                                    accent: value < 60 ? root.amber : root.green
                                }
                                TelemetryProgress {
                                    Layout.fillWidth: true
                                    label: "SLOT CLEARANCE"
                                    value: root.viewModel.activeMissionSlots.length > 0 && root.viewModel.activeMissionSlots[0].status === "GRANTED" ? 100 : 35
                                    accent: value === 100 ? root.green : root.amber
                                }
                                TelemetryProgress {
                                    Layout.fillWidth: true
                                    label: "CORRIDOR CAPACITY"
                                    value: root.viewModel.activeMissionComplianceZones.length > 0
                                           ? Math.max(0, 100 - (100 * Number(root.viewModel.activeMissionComplianceZones[0].current) / Math.max(1, Number(root.viewModel.activeMissionComplianceZones[0].cap))))
                                           : 0
                                    accent: value < 30 ? root.red : root.cyan
                                }
                            }
                        }

                        Rectangle {
                            id: routeFlow
                            Layout.preferredWidth: Math.min(280, root.width * 0.27)
                            Layout.fillHeight: true
                            color: "#091412"
                            border.color: root.line
                            radius: 3
                            clip: true

                            readonly property var endpoints: String(root.selectedMissionData.route || "-- - --").split(" - ")
                            property real flowProgress: 0

                            Text { anchors.top: parent.top; anchors.left: parent.left; anchors.margins: 10; text: "LIVE ROUTE FLOW"; color: root.textMain; font.family: "Consolas"; font.pixelSize: 12; font.bold: true }
                            Rectangle { x: 25; y: parent.height * 0.57; width: parent.width - 50; height: 2; color: root.line }
                            Rectangle { x: 20; y: parent.height * 0.57 - 4; width: 10; height: 10; radius: 5; color: root.cyan }
                            Rectangle { x: parent.width - 30; y: parent.height * 0.57 - 4; width: 10; height: 10; radius: 5; color: root.green }
                            Rectangle {
                                x: 25 + (routeFlow.width - 56) * routeFlow.flowProgress
                                y: routeFlow.height * 0.57 - 5
                                width: 12
                                height: 12
                                radius: 6
                                color: root.green
                                border.color: root.textMain
                                SequentialAnimation on scale {
                                    running: root.viewModel.running
                                    loops: Animation.Infinite
                                    NumberAnimation { to: 1.35; duration: 450 }
                                    NumberAnimation { to: 1; duration: 450 }
                                }
                            }
                            Text { x: 10; y: parent.height * 0.7; width: parent.width * 0.45; text: routeFlow.endpoints[0] || "--"; color: root.cyan; font.family: "Consolas"; font.pixelSize: 11; elide: Text.ElideRight }
                            Text { x: parent.width * 0.52; y: parent.height * 0.7; width: parent.width * 0.44 - 10; text: routeFlow.endpoints[1] || "--"; color: root.green; font.family: "Consolas"; font.pixelSize: 11; horizontalAlignment: Text.AlignRight; elide: Text.ElideRight }

                            SequentialAnimation on flowProgress {
                                running: root.viewModel.running
                                loops: Animation.Infinite
                                NumberAnimation { from: 0; to: 1; duration: 2800; easing.type: Easing.InOutSine }
                                PauseAnimation { duration: 200 }
                            }
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        InteractiveComboBox {
                            id: routeSelector
                            Layout.fillWidth: true
                            implicitHeight: 34
                            model: root.viewModel.routeOptions
                            font.pixelSize: 12
                            enabled: root.viewModel.localControlsEnabled && root.viewModel.missions.length > 0
                            palette.button: root.raised
                            palette.buttonText: root.textMain
                            palette.base: root.raised
                            palette.text: root.textMain
                            palette.highlight: "#17352d"
                            palette.highlightedText: root.green
                        }
                        InteractiveComboBox {
                            id: profileSelector
                            Layout.preferredWidth: 110
                            implicitHeight: 34
                            model: root.viewModel.missionProfiles
                            font.pixelSize: 12
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
                        Text { anchors.centerIn: parent; visible: parent.count === 0; text: "NO MISSIONS AVAILABLE"; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 12 }
                        delegate: Rectangle {
                            required property int index
                            required property var modelData
                            width: ListView.view.width
                            height: 72
                            radius: 3
                            color: index === root.selectedMission ? "#17352d" : root.raised
                            border.color: modelData.severity === "warning" ? root.amber : (index === root.selectedMission ? root.green : root.line)
                            scale: missionMouse.containsMouse ? 0.995 : 1
                            Behavior on scale { NumberAnimation { duration: 120 } }
                            Behavior on color { ColorAnimation { duration: 180 } }
                            MouseArea { id: missionMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.viewModel.setActiveMissionIndex(index) }
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 10
                                Column {
                                    Layout.preferredWidth: 92
                                    Text { text: modelData.callSign; color: root.textMain; font.family: "Consolas"; font.pixelSize: 16; font.bold: true }
                                    Text { text: "DEPART " + modelData.departure; color: root.cyan; font.family: "Consolas"; font.pixelSize: 12 }
                                }
                                Column {
                                    Layout.fillWidth: true
                                    Text { text: modelData.route; color: root.textMain; font.pixelSize: 14; elide: Text.ElideRight; width: parent.width }
                                    Text { text: modelData.profile + "  /  " + modelData.status; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 12 }
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
                        Text { text: root.viewModel.workflowNotes.booking; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 11 }
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
                    PanelTitle { title: "MISSION VERTIPORTS"; role: "ORIGIN / DESTINATION RESOURCES" }
                    ListView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 4
                        clip: true
                        model: root.viewModel.activeMissionVertiports
                        Text { anchors.centerIn: parent; visible: parent.count === 0; text: "NO VERTIPORTS AVAILABLE"; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 12 }
                        delegate: Rectangle {
                            required property int index
                            required property var modelData
                            width: ListView.view.width
                            height: 78
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
                                    Text { text: modelData.name; color: root.textMain; font.family: "Consolas"; font.pixelSize: 16; font.bold: true }
                                    Text { text: modelData.status; color: modelData.severity === "warning" ? root.amber : root.textMuted; font.family: "Consolas"; font.pixelSize: 12 }
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
                        ActionButton { text: "ASSIGN GATE"; enabled: root.viewModel.localControlsEnabled && root.viewModel.activeMissionVertiports.length > 0; onClicked: root.viewModel.assignGate(root.viewModel.activeMissionVertiports[root.selectedVertiport].sourceIndex) }
                        ActionButton { text: "START CHARGING"; enabled: root.viewModel.localControlsEnabled && root.viewModel.activeMissionVertiports.length > 0; accent: root.cyan; onClicked: root.viewModel.startCharging(root.viewModel.activeMissionVertiports[root.selectedVertiport].sourceIndex) }
                        Item { Layout.fillWidth: true }
                        Text { text: root.viewModel.workflowNotes.vertiport; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 11 }
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
                    PanelTitle { title: "MISSION UTM SLOT"; role: "ASSIGNED CORRIDOR / DEPARTURE" }
                    ListView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 4
                        clip: true
                        model: root.viewModel.activeMissionSlots
                        Text { anchors.centerIn: parent; visible: parent.count === 0; text: "NO SLOT REQUESTS"; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 12 }
                        delegate: Rectangle {
                            required property int index
                            required property var modelData
                            width: ListView.view.width
                            height: 78
                            radius: 3
                            color: index === root.selectedSlot ? "#17352d" : root.raised
                            border.color: modelData.severity === "warning" ? root.amber : (index === root.selectedSlot ? root.green : root.line)
                            MouseArea { anchors.fill: parent; onClicked: root.selectedSlot = index }
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 14
                                Column {
                                    Layout.preferredWidth: 96
                                    Text { text: modelData.requestId; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 12 }
                                    Text { text: modelData.callSign; color: root.textMain; font.family: "Consolas"; font.pixelSize: 16; font.bold: true }
                                }
                                Metric { label: "CORRIDOR"; value: modelData.corridor }
                                Metric { label: "REQUEST"; value: modelData.desired }
                                Item { Layout.fillWidth: true }
                                Text { text: modelData.status; color: modelData.severity === "warning" ? root.amber : root.green; font.family: "Consolas"; font.pixelSize: 11; font.bold: true }
                            }
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        ActionButton { text: "GRANT SLOT"; enabled: root.viewModel.localControlsEnabled && root.viewModel.activeMissionSlots.length > 0; onClicked: root.viewModel.decideSlot(root.viewModel.activeMissionSlots[root.selectedSlot].sourceIndex, true) }
                        ActionButton { text: "DENY SLOT"; enabled: root.viewModel.localControlsEnabled && root.viewModel.activeMissionSlots.length > 0; accent: root.red; onClicked: root.viewModel.decideSlot(root.viewModel.activeMissionSlots[root.selectedSlot].sourceIndex, false) }
                        Item { Layout.fillWidth: true }
                        Text { text: root.viewModel.workflowNotes.slot; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 11 }
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
                    PanelTitle { title: "MISSION COMPLIANCE"; role: "CORRIDOR NOISE / BOUNDARY" }
                    ListView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 4
                        clip: true
                        model: root.viewModel.activeMissionComplianceZones
                        Text { anchors.centerIn: parent; visible: parent.count === 0; text: "NO COMPLIANCE ZONES"; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 12 }
                        delegate: Rectangle {
                            required property int index
                            required property var modelData
                            width: ListView.view.width
                            height: 78
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
                                    Text { text: modelData.name; color: root.textMain; font.family: "Consolas"; font.pixelSize: 16; font.bold: true }
                                    Text { text: modelData.track + "  /  " + modelData.status; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 12 }
                                }
                                Metric { label: "OVERFLIGHTS"; value: modelData.current + "/" + modelData.cap }
                                Metric { label: "NOISE"; value: modelData.noise + " dBA" }
                                Rectangle { width: 7; height: 7; radius: 4; color: modelData.enforced ? root.green : root.textMuted }
                            }
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        ActionButton { text: "ENFORCE BOUNDARY"; enabled: root.viewModel.localControlsEnabled && root.viewModel.activeMissionComplianceZones.length > 0; accent: root.amber; onClicked: root.viewModel.setBoundaryEnforcement(root.viewModel.activeMissionComplianceZones[root.selectedZone].sourceIndex, true) }
                        ActionButton { text: "MONITOR ONLY"; enabled: root.viewModel.localControlsEnabled && root.viewModel.activeMissionComplianceZones.length > 0; accent: root.cyan; onClicked: root.viewModel.setBoundaryEnforcement(root.viewModel.activeMissionComplianceZones[root.selectedZone].sourceIndex, false) }
                        Item { Layout.fillWidth: true }
                        Text { text: root.viewModel.workflowNotes.compliance; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 11 }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 112
            color: "#091412"
            border.color: root.line
            radius: 4
            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 12
                ColumnLayout {
                    Layout.preferredWidth: 220
                    Text { text: "CURRENT MISSION ACTIVITY"; color: root.textMain; font.family: "Consolas"; font.pixelSize: 13; font.bold: true }
                    Text { text: root.selectedMissionData.callSign; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 11 }
                    Item { Layout.fillHeight: true }
                }
                Rectangle { width: 1; Layout.fillHeight: true; color: root.line }
                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 2
                    model: root.viewModel.activeMissionActivity
                    Text { anchors.centerIn: parent; visible: parent.count === 0; text: "NO EVENTS RECEIVED"; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 11 }
                    delegate: Text {
                        required property string modelData
                        width: ListView.view.width
                        text: modelData
                        color: root.textMuted
                        font.family: "Consolas"
                        font.pixelSize: 11
                    }
                }
            }
        }
    }

    Connections {
        target: root.viewModel
        function onActiveMissionChanged() {
            root.selectedVertiport = 0
            root.selectedSlot = 0
            root.selectedZone = 0
        }
    }

    Shortcut { sequence: "Space"; enabled: root.visible && root.viewModel.localControlsEnabled; onActivated: root.viewModel.toggleRunning() }
    Shortcut { sequence: "Right"; enabled: root.visible && root.viewModel.manualStepEnabled; onActivated: root.viewModel.advanceSimulation() }
    Shortcut { sequence: "Ctrl+R"; enabled: root.visible && root.viewModel.localControlsEnabled; onActivated: root.viewModel.resetSimulation() }
    Shortcut { sequence: "Ctrl+1"; enabled: root.visible; onActivated: root.stakeholderIndex = 0 }
    Shortcut { sequence: "Ctrl+2"; enabled: root.visible; onActivated: root.stakeholderIndex = 1 }
    Shortcut { sequence: "Ctrl+3"; enabled: root.visible; onActivated: root.stakeholderIndex = 2 }
    Shortcut { sequence: "Ctrl+4"; enabled: root.visible; onActivated: root.stakeholderIndex = 3 }
}