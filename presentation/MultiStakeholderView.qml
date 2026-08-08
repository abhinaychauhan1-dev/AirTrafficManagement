pragma ComponentBehavior: Bound

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
    property int selectedRisk: 0
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

    component StatusPill: Rectangle {
        required property string label
        property color accent: root.green
        implicitWidth: pillContent.implicitWidth + 20
        implicitHeight: 28
        radius: 3
        color: Qt.rgba(accent.r, accent.g, accent.b, 0.1)
        border.color: Qt.rgba(accent.r, accent.g, accent.b, 0.6)

        Row {
            id: pillContent
            anchors.centerIn: parent
            spacing: 7
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 6
                height: 6
                radius: 3
                color: accent
            }
            Text {
                text: label
                color: accent
                font.family: "Consolas"
                font.pixelSize: 11
                font.bold: true
            }
        }
    }

    component KpiCard: Rectangle {
        required property string label
        required property string value
        property string detail: ""
        property color accent: root.cyan
        implicitHeight: 64
        color: "#0a1513"
        border.color: root.line
        radius: 3

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 3
            color: accent
        }
        Column {
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            Text { width: parent.width; text: label; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 10; font.bold: true }
            Text { width: parent.width; text: value; color: accent; font.family: "Consolas"; font.pixelSize: 16; font.bold: true; elide: Text.ElideRight }
            Text { width: parent.width; text: detail; visible: detail.length > 0; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 10; elide: Text.ElideRight }
        }
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
            Layout.preferredHeight: 108
            color: "#091412"
            border.color: root.line
            radius: 4

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 4
                color: root.green
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.leftMargin: 18
                anchors.rightMargin: 12
                anchors.topMargin: 10
                anchors.bottomMargin: 9
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    Column {
                        Layout.fillWidth: true
                        spacing: 2
                        Text { text: "ACTIVE TAXI MISSIONS"; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 11; font.bold: true }
                        Text { text: root.selectedMissionData.callSign || "NO ACTIVE MISSION"; color: root.textMain; font.family: "Consolas"; font.pixelSize: 22; font.bold: true }
                    }
                    StatusPill {
                        label: String(root.selectedMissionData.status || "UNASSIGNED").toUpperCase()
                        accent: root.selectedMissionData.severity === "warning" ? root.amber : root.green
                    }
                    StatusPill {
                        label: root.viewModel.transportMode
                        accent: root.viewModel.mqttConnected ? root.cyan : root.amber
                    }
                    Column {
                        Layout.preferredWidth: 112
                        Text { width: parent.width; text: root.viewModel.simulationTime; color: root.textMain; font.family: "Consolas"; font.pixelSize: 20; font.bold: true; horizontalAlignment: Text.AlignRight }
                        Text { width: parent.width; text: "INDIA STANDARD TIME"; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 9; horizontalAlignment: Text.AlignRight }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        Layout.fillWidth: true
                        text: (root.selectedMissionData.route || "ROUTE NOT ASSIGNED") + "  |  "
                              + (root.viewModel.mqttConnected ? "REMOTE EVENTS / LOCAL STATE LOCKED" : (root.viewModel.running ? "LIVE SIMULATION" : "SIMULATION PAUSED"))
                        color: root.viewModel.mqttConnected ? root.cyan : root.textMain
                        font.family: "Consolas"
                        font.pixelSize: 12
                        elide: Text.ElideRight
                    }
                    ActionButton { Layout.preferredWidth: 88; text: root.viewModel.running ? "PAUSE" : "RESUME"; accent: root.amber; enabled: root.viewModel.localControlsEnabled; onClicked: root.viewModel.toggleRunning() }
                    ActionButton { Layout.preferredWidth: 88; text: "STEP +1"; enabled: root.viewModel.manualStepEnabled; onClicked: root.viewModel.advanceSimulation() }
                    ActionButton { Layout.preferredWidth: 76; text: "RESET"; accent: root.red; enabled: root.viewModel.localControlsEnabled; onClicked: root.viewModel.resetSimulation() }
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
                        spacing: 7
                        KpiCard {
                            Layout.fillWidth: true
                            label: "DEPARTURE WINDOW"
                            value: root.selectedMissionData.departure || "--:--"
                            detail: "IST / ACTIVE SCHEDULE"
                            accent: root.cyan
                        }
                        KpiCard {
                            Layout.fillWidth: true
                            label: "MISSION PROFILE"
                            value: root.selectedMissionData.profile || "UNASSIGNED"
                            detail: root.selectedMissionData.status || "NO STATUS"
                            accent: root.green
                        }
                        KpiCard {
                            Layout.fillWidth: true
                            label: "VEHICLE HEALTH"
                            value: Number(root.selectedMissionData.health || 0) + "%"
                            detail: Number(root.selectedMissionData.health || 0) >= 60 ? "DISPATCH READY" : "INSPECTION REQUIRED"
                            accent: Number(root.selectedMissionData.health || 0) >= 60 ? root.green : root.amber
                        }
                        KpiCard {
                            Layout.fillWidth: true
                            label: "UTM CLEARANCE"
                            value: root.viewModel.activeMissionSlots.length > 0 ? root.viewModel.activeMissionSlots[0].status : "PENDING"
                            detail: root.viewModel.activeMissionSlots.length > 0 ? root.viewModel.activeMissionSlots[0].corridor : "NO CORRIDOR"
                            accent: value === "GRANTED" ? root.green : root.amber
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 166
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
                            Layout.preferredWidth: Math.min(330, root.width * 0.29)
                            Layout.fillHeight: true
                            color: "#091412"
                            border.color: root.line
                            radius: 3
                            clip: true

                            readonly property var endpoints: String(root.selectedMissionData.route || "-- - --").split(" - ")
                            readonly property var currentSlot: root.viewModel.activeMissionSlots.length > 0
                                                               ? root.viewModel.activeMissionSlots[0] : ({})
                            readonly property string lifecycle: String(currentSlot.lifecycle || "UNASSIGNED")
                            readonly property bool movementAuthorized: lifecycle === "ACTIVATED" || lifecycle === "CLOSED"
                            readonly property real routeProgress: calculateProgress()
                            readonly property color stateColor: lifecycle === "ACTIVATED" ? root.green
                                                               : (lifecycle === "CLOSED" ? root.cyan
                                                               : (currentSlot.severity === "warning" ? root.amber : root.textMuted))

                            function minuteOfDay(time) {
                                const parts = String(time).split(":")
                                return parts.length === 2 ? Number(parts[0]) * 60 + Number(parts[1]) : -1
                            }

                            function calculateProgress() {
                                if (lifecycle === "CLOSED")
                                    return 1
                                if (lifecycle !== "ACTIVATED")
                                    return 0
                                const bounds = String(currentSlot.window || "").split("-")
                                const start = bounds.length === 2 ? minuteOfDay(bounds[0]) : -1
                                const end = bounds.length === 2 ? minuteOfDay(bounds[1]) : -1
                                const current = minuteOfDay(root.viewModel.simulationTime)
                                if (start < 0 || end <= start || current < 0)
                                    return 0
                                return Math.max(0, Math.min(1, (current - start) / (end - start)))
                            }

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 6

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "LIVE ROUTE FLOW"; color: root.textMain; font.family: "Consolas"; font.pixelSize: 12; font.bold: true }
                                    Item { Layout.fillWidth: true }
                                    Text { text: routeFlow.lifecycle; color: routeFlow.stateColor; font.family: "Consolas"; font.pixelSize: 9; font.bold: true }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { Layout.fillWidth: true; text: routeFlow.currentSlot.corridor || "NO CORRIDOR"; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 9; elide: Text.ElideRight }
                                    Text { text: routeFlow.currentSlot.window || "--:-- - --:--"; color: root.cyan; font.family: "Consolas"; font.pixelSize: 9 }
                                }

                                Item {
                                    id: routeTrack
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    Layout.minimumHeight: 46

                                    Rectangle {
                                        id: routeBaseline
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 8
                                        height: 4
                                        radius: 2
                                        color: root.line
                                        Rectangle {
                                            width: parent.width * routeFlow.routeProgress
                                            height: parent.height
                                            radius: 2
                                            color: routeFlow.stateColor
                                            Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
                                        }
                                    }

                                    Repeater {
                                        model: 5
                                        Text {
                                            required property int index
                                            x: routeBaseline.x + routeBaseline.width * (index + 0.5) / 5 - width / 2
                                            anchors.verticalCenter: routeBaseline.verticalCenter
                                            text: ">"
                                            color: routeFlow.routeProgress >= (index + 0.5) / 5 ? routeFlow.stateColor : root.textMuted
                                            font.family: "Consolas"
                                            font.pixelSize: 11
                                            font.bold: true
                                        }
                                    }

                                    Rectangle {
                                        anchors.left: routeBaseline.left
                                        anchors.verticalCenter: routeBaseline.verticalCenter
                                        width: 12; height: 12; radius: 6
                                        color: root.cyan
                                        border.color: root.textMain
                                    }
                                    Rectangle {
                                        anchors.right: routeBaseline.right
                                        anchors.verticalCenter: routeBaseline.verticalCenter
                                        width: 12; height: 12; radius: 6
                                        color: root.green
                                        border.color: root.textMain
                                    }
                                    Rectangle {
                                        x: routeBaseline.x + (routeBaseline.width - width) * routeFlow.routeProgress
                                        anchors.verticalCenter: routeBaseline.verticalCenter
                                        visible: routeFlow.movementAuthorized
                                        width: 24
                                        height: 20
                                        radius: 3
                                        color: routeFlow.stateColor
                                        border.color: root.textMain
                                        Text { anchors.centerIn: parent; text: ">"; color: root.deep; font.family: "Consolas"; font.pixelSize: 13; font.bold: true }
                                        Behavior on x { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
                                    }
                                    Rectangle {
                                        anchors.left: routeBaseline.left
                                        anchors.leftMargin: -6
                                        anchors.verticalCenter: routeBaseline.verticalCenter
                                        visible: !routeFlow.movementAuthorized
                                        width: 24
                                        height: 20
                                        radius: 3
                                        color: routeFlow.stateColor
                                        border.color: root.textMain
                                        Text { anchors.centerIn: parent; text: "!"; color: root.deep; font.family: "Consolas"; font.pixelSize: 13; font.bold: true }
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Column {
                                        Layout.fillWidth: true
                                        Layout.minimumWidth: 92
                                        Text { text: "ORIGIN"; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 8 }
                                        Text { width: parent.width; text: routeFlow.endpoints[0] || "--"; color: root.cyan; font.family: "Consolas"; font.pixelSize: 10; font.bold: true; elide: Text.ElideRight }
                                    }
                                    Text {
                                        Layout.preferredWidth: 54
                                        text: routeFlow.movementAuthorized ? Math.round(routeFlow.routeProgress * 100) + "%" : "HOLD"
                                        color: routeFlow.stateColor
                                        font.family: "Consolas"
                                        font.pixelSize: 12
                                        font.bold: true
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                    Column {
                                        Layout.fillWidth: true
                                        Layout.minimumWidth: 92
                                        Text { width: parent.width; text: "DESTINATION"; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 8; horizontalAlignment: Text.AlignRight }
                                        Text { width: parent.width; text: routeFlow.endpoints[1] || "--"; color: root.green; font.family: "Consolas"; font.pixelSize: 10; font.bold: true; horizontalAlignment: Text.AlignRight; elide: Text.ElideRight }
                                    }
                                }
                            }
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3
                            Text { text: "ROUTE ASSIGNMENT"; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 10; font.bold: true }
                            InteractiveComboBox {
                                id: routeSelector
                                Layout.fillWidth: true
                                implicitHeight: 38
                                model: root.viewModel.routeOptions
                                font.pixelSize: 12
                                enabled: root.viewModel.localControlsEnabled && root.viewModel.missions.length > 0
                            }
                        }
                        ColumnLayout {
                            Layout.preferredWidth: 150
                            spacing: 3
                            Text { text: "FLIGHT PROFILE"; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 10; font.bold: true }
                            InteractiveComboBox {
                                id: profileSelector
                                Layout.fillWidth: true
                                implicitHeight: 38
                                model: root.viewModel.missionProfiles
                                font.pixelSize: 12
                                enabled: root.viewModel.localControlsEnabled && root.viewModel.missions.length > 0
                            }
                        }
                        ActionButton { Layout.alignment: Qt.AlignBottom; Layout.preferredWidth: 122; implicitHeight: 38; text: "PLAN ROUTE"; enabled: root.viewModel.localControlsEnabled && root.viewModel.missions.length > 0; onClicked: root.viewModel.planMission(root.selectedMission, routeSelector.currentText, profileSelector.currentText) }
                    }
                    ListView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 5
                        clip: true
                        model: root.viewModel.missions
                        boundsBehavior: Flickable.StopAtBounds
                        ScrollIndicator.vertical: ScrollIndicator { }
                        Text { anchors.centerIn: parent; visible: parent.count === 0; text: "NO MISSIONS AVAILABLE"; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 12 }
                        delegate: Rectangle {
                            required property int index
                            required property var modelData
                            width: ListView.view.width
                            height: 82
                            radius: 3
                            color: index === root.selectedMission ? "#17352d" : (missionMouse.containsMouse ? "#132522" : root.raised)
                            border.color: modelData.severity === "warning" ? root.amber : (index === root.selectedMission ? root.green : root.line)
                            Behavior on color { ColorAnimation { duration: 180 } }
                            MouseArea { id: missionMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.viewModel.setActiveMissionIndex(index) }
                            Rectangle {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: index === root.selectedMission ? 4 : 2
                                color: modelData.severity === "warning" ? root.amber : (index === root.selectedMission ? root.green : root.line)
                                Behavior on width { NumberAnimation { duration: 140 } }
                            }
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 14
                                anchors.rightMargin: 12
                                spacing: 14
                                Column {
                                    Layout.preferredWidth: 110
                                    spacing: 3
                                    Text { text: modelData.callSign; color: index === root.selectedMission ? root.green : root.textMain; font.family: "Consolas"; font.pixelSize: 17; font.bold: true }
                                    Text { text: "DEPART  " + modelData.departure; color: root.cyan; font.family: "Consolas"; font.pixelSize: 11; font.bold: true }
                                }
                                Column {
                                    Layout.fillWidth: true
                                    spacing: 4
                                    Text { text: modelData.route; color: root.textMain; font.family: "Consolas"; font.pixelSize: 14; font.bold: true; elide: Text.ElideRight; width: parent.width }
                                    Text { text: modelData.profile; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 11 }
                                }
                                Rectangle {
                                    Layout.preferredWidth: statusText.implicitWidth + 16
                                    Layout.preferredHeight: 26
                                    radius: 3
                                    color: modelData.severity === "warning" ? "#2b2015" : "#10261f"
                                    border.color: modelData.severity === "warning" ? root.amber : root.green
                                    Text {
                                        id: statusText
                                        anchors.centerIn: parent
                                        text: modelData.status
                                        color: modelData.severity === "warning" ? root.amber : root.green
                                        font.family: "Consolas"
                                        font.pixelSize: 10
                                        font.bold: true
                                    }
                                }
                                ColumnLayout {
                                    Layout.preferredWidth: 104
                                    spacing: 4
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { text: "HEALTH"; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 10 }
                                        Item { Layout.fillWidth: true }
                                        Text { text: modelData.health + "%"; color: modelData.health < 60 ? root.amber : root.green; font.family: "Consolas"; font.pixelSize: 12; font.bold: true }
                                    }
                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 5
                                        radius: 2
                                        color: "#1c2c29"
                                        Rectangle {
                                            width: parent.width * Math.max(0, Math.min(100, Number(modelData.health))) / 100
                                            height: parent.height
                                            radius: 2
                                            color: modelData.health < 60 ? root.amber : root.green
                                            Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                                        }
                                    }
                                }
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
                            height: 92
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
                        ActionButton { text: "ASSIGN GATE"; enabled: root.viewModel.localControlsEnabled && root.selectedVertiport >= 0 && root.selectedVertiport < root.viewModel.activeMissionVertiports.length; onClicked: root.viewModel.assignGate(root.viewModel.activeMissionVertiports[root.selectedVertiport].sourceIndex) }
                        ActionButton { text: "START CHARGING"; enabled: root.viewModel.localControlsEnabled && root.selectedVertiport >= 0 && root.selectedVertiport < root.viewModel.activeMissionVertiports.length; accent: root.cyan; onClicked: root.viewModel.startCharging(root.viewModel.activeMissionVertiports[root.selectedVertiport].sourceIndex) }
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
                                    Layout.preferredWidth: 150
                                    Text { text: modelData.intentId + "  r" + modelData.revision; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 10 }
                                    Text { text: modelData.callSign; color: root.textMain; font.family: "Consolas"; font.pixelSize: 16; font.bold: true }
                                    Text { text: modelData.lifecycle; color: modelData.severity === "warning" ? root.amber : root.cyan; font.family: "Consolas"; font.pixelSize: 10; font.bold: true }
                                }
                                Metric { label: "CORRIDOR"; value: modelData.corridor }
                                Metric { label: "4D WINDOW"; value: modelData.window }
                                Metric { label: "ALTITUDE"; value: modelData.altitudeBand }
                                Item { Layout.fillWidth: true }
                                Column {
                                    Layout.preferredWidth: 180
                                    Text { width: parent.width; text: modelData.status; color: modelData.severity === "warning" ? root.amber : root.green; font.family: "Consolas"; font.pixelSize: 11; font.bold: true; horizontalAlignment: Text.AlignRight; elide: Text.ElideRight }
                                    Text { width: parent.width; visible: modelData.conflictReason.length > 0; text: modelData.conflictReason; color: root.amber; font.family: "Consolas"; font.pixelSize: 9; horizontalAlignment: Text.AlignRight; elide: Text.ElideRight }
                                }
                            }
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        ActionButton { text: "GRANT SLOT"; enabled: root.viewModel.localControlsEnabled && root.selectedSlot >= 0 && root.selectedSlot < root.viewModel.activeMissionSlots.length && root.viewModel.activeMissionSlots[root.selectedSlot].canDecide; onClicked: root.viewModel.decideSlot(root.viewModel.activeMissionSlots[root.selectedSlot].sourceIndex, true) }
                        ActionButton { text: "DENY SLOT"; enabled: root.viewModel.localControlsEnabled && root.selectedSlot >= 0 && root.selectedSlot < root.viewModel.activeMissionSlots.length && root.viewModel.activeMissionSlots[root.selectedSlot].canDecide; accent: root.red; onClicked: root.viewModel.decideSlot(root.viewModel.activeMissionSlots[root.selectedSlot].sourceIndex, false) }
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
                    PanelTitle { title: "MISSION SAFETY AND COMPLIANCE"; role: "SMS RISK CONTROL / CORRIDOR BOUNDARY" }
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 7
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
                                        Text { text: modelData.name; color: root.textMain; font.family: "Consolas"; font.pixelSize: 14; font.bold: true }
                                        Text { text: modelData.track + " / " + modelData.status; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 10 }
                                    }
                                    Metric { label: "OVERFLIGHTS"; value: modelData.current + "/" + modelData.cap }
                                    Metric { label: "NOISE"; value: modelData.noise + " dBA" }
                                }
                            }
                        }
                        ListView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: 4
                            clip: true
                            model: root.viewModel.activeMissionSafetyRisks
                            Text { anchors.centerIn: parent; visible: parent.count === 0; text: "NO RECORDED SAFETY RISKS"; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 12 }
                            delegate: Rectangle {
                                required property int index
                                required property var modelData
                                width: ListView.view.width
                                height: 96
                                radius: 3
                                color: index === root.selectedRisk ? "#2d2817" : root.raised
                                border.color: modelData.severity === "warning" ? root.amber : root.line
                                MouseArea { anchors.fill: parent; onClicked: root.selectedRisk = index }
                                Column {
                                    Layout.fillWidth: true
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 2
                                    Text { width: parent.width; text: modelData.riskId + " r" + modelData.revision + " / " + modelData.status; color: modelData.severity === "warning" ? root.amber : root.green; font.family: "Consolas"; font.pixelSize: 10; font.bold: true; elide: Text.ElideRight }
                                    Text { width: parent.width; text: modelData.hazard; color: root.textMain; font.family: "Consolas"; font.pixelSize: 12; font.bold: true; elide: Text.ElideRight }
                                    Text { width: parent.width; text: "INITIAL " + modelData.initialRisk + "  /  RESIDUAL " + modelData.residualRisk; color: root.cyan; font.family: "Consolas"; font.pixelSize: 10; elide: Text.ElideRight }
                                    Text { width: parent.width; text: modelData.owner + " / " + modelData.mitigation; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 9; elide: Text.ElideRight }
                                }
                            }
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        ActionButton { text: "ENFORCE BOUNDARY"; enabled: root.viewModel.localControlsEnabled && root.selectedZone >= 0 && root.selectedZone < root.viewModel.activeMissionComplianceZones.length; accent: root.amber; onClicked: root.viewModel.setBoundaryEnforcement(root.viewModel.activeMissionComplianceZones[root.selectedZone].sourceIndex, true) }
                        ActionButton { text: "MONITOR ONLY"; enabled: root.viewModel.localControlsEnabled && root.selectedZone >= 0 && root.selectedZone < root.viewModel.activeMissionComplianceZones.length; accent: root.cyan; onClicked: root.viewModel.setBoundaryEnforcement(root.viewModel.activeMissionComplianceZones[root.selectedZone].sourceIndex, false) }
                        ActionButton { text: "APPLY MITIGATION"; enabled: root.viewModel.localControlsEnabled && root.selectedRisk >= 0 && root.selectedRisk < root.viewModel.activeMissionSafetyRisks.length && root.viewModel.activeMissionSafetyRisks[root.selectedRisk].canMitigate; accent: root.green; onClicked: root.viewModel.applySafetyMitigation(root.viewModel.activeMissionSafetyRisks[root.selectedRisk].sourceIndex) }
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
                    Text { text: root.selectedMissionData.callSign + "  /  " + root.viewModel.activeMissionActivity.length + " EVENTS"; color: root.textMuted; font.family: "Consolas"; font.pixelSize: 11 }
                    Item { Layout.fillHeight: true }
                }
                Rectangle { width: 1; Layout.fillHeight: true; color: root.line }
                ListView {
                    id: missionActivityList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 2
                    model: root.viewModel.activeMissionActivity
                    onCountChanged: positionViewAtEnd()
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
            root.selectedRisk = 0
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