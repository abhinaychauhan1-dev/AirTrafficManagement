pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

ApplicationWindow {
    id: window
    minimumWidth: 1024
    minimumHeight: 680
    width: {
        var availableWidth = (window.screen && window.screen.availableGeometry)
            ? window.screen.availableGeometry.width
            : Screen.desktopAvailableWidth
        return Math.max(1024, Math.round(availableWidth * 0.9))
    }
    height: {
        var availableHeight = (window.screen && window.screen.availableGeometry)
            ? window.screen.availableGeometry.height
            : Screen.desktopAvailableHeight
        return Math.max(680, Math.round(availableHeight * 0.87))
    }
    visible: true
    title: "Air Taxi Traffic Management | Delhi ACC"
    color: "#07100f"

    readonly property color panel: "#0c1716"
    readonly property color panelRaised: "#12201e"
    readonly property color line: "#293a37"
    readonly property color textMain: "#d9e5e1"
    readonly property color textMuted: "#7f9690"
    readonly property color green: "#6fffc1"
    readonly property color amber: "#ffb443"
    readonly property color cyan: "#73d9ff"
    readonly property color red: "#ff746c"

    font.family: "Segoe UI"

    component SectionTitle: Text {
        color: window.textMuted
        font.family: "Consolas"
        font.pixelSize: 13
        font.bold: true
        font.letterSpacing: 1.2
    }

    component StatusDot: Rectangle {
        property color statusColor: window.green
        width: 8
        height: 8
        radius: 4
        color: statusColor
        border.color: Qt.lighter(statusColor, 1.35)
    }

    component ToolButton: Button {
        id: control
        implicitWidth: 40
        implicitHeight: 34
        font.family: "Consolas"
        font.pixelSize: 14
        contentItem: Text {
            text: control.text
            color: !control.enabled ? "#53635f" : (control.checked ? "#07100f" : window.textMain)
            font: control.font
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        background: Rectangle {
            color: control.checked ? window.green : (control.down ? "#244039" : (control.hovered ? "#1c302c" : window.panelRaised))
            border.color: control.enabled && control.checked ? window.green : window.line
            radius: 3
        }
    }

    header: Rectangle {
        height: 64
        color: "#091412"
        border.color: window.line

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            spacing: 16

            Rectangle {
                width: 34
                height: 34
                radius: 3
                color: window.green
                Text { anchors.centerIn: parent; text: "AT"; color: "#07100f"; font.bold: true; font.pixelSize: 15 }
            }
            Column {
                Layout.preferredWidth: 228
                spacing: 1
                Text { text: "DELHI UAM CORRIDOR"; color: window.textMain; font.bold: true; font.pixelSize: 17; font.letterSpacing: 0.8 }
                Text { text: "AIR TAXI TRAFFIC MANAGEMENT"; color: window.textMuted; font.family: "Consolas"; font.pixelSize: 12; font.letterSpacing: 1.3 }
            }
            Rectangle { width: 1; Layout.fillHeight: true; Layout.topMargin: 15; Layout.bottomMargin: 15; color: window.line }
            Row {
                visible: window.width >= 1360
                spacing: 20
                Repeater {
                    model: airTrafficViewModel.operationalFacts
                    Column {
                        id: operationalFact
                        required property var modelData
                        spacing: 2
                        Text { text: operationalFact.modelData.label; color: window.textMuted; font.family: "Consolas"; font.pixelSize: 11 }
                        Text { text: operationalFact.modelData.value; color: window.textMain; font.family: "Consolas"; font.pixelSize: 15; font.bold: true }
                    }
                }
            }
            Button {
                id: moduleSelector
                readonly property var selectedModule: appShellViewModel.modules[appShellViewModel.selectedModuleIndex]
                function togglePopup() {
                    modulePopup.opened ? modulePopup.close() : modulePopup.open()
                }
                Layout.preferredWidth: window.width >= 1360 ? 260 : 224
                implicitHeight: 42
                activeFocusOnTab: true
                flat: true
                font.family: "Consolas"
                Accessible.name: "Feature selector: " + selectedModule.label
                Accessible.description: selectedModule.description
                palette.button: "#12201e"
                palette.highlight: "#13211f"
                palette.midlight: "#13211f"
                palette.window: "#12201e"
                ToolTip.text: selectedModule.description
                ToolTip.visible: hovered && !modulePopup.opened
                onClicked: togglePopup()
                Keys.onDownPressed: modulePopup.open()

                contentItem: RowLayout {
                    spacing: 9
                    Rectangle {
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                        radius: 3
                        color: modulePopup.opened ? window.green : "#17352d"
                        Text {
                            anchors.centerIn: parent
                            text: String(appShellViewModel.selectedModuleIndex + 1).padStart(2, "0")
                            color: modulePopup.opened ? "#07100f" : window.green
                            font.family: "Consolas"
                            font.pixelSize: 12
                            font.bold: true
                        }
                    }
                    Column {
                        Layout.fillWidth: true
                        spacing: 1
                        Text {
                            width: parent.width
                            text: moduleSelector.selectedModule.label
                            color: window.textMain
                            font.family: "Consolas"
                            font.pixelSize: 12
                            font.bold: true
                            elide: Text.ElideRight
                        }
                        Text {
                            text: moduleSelector.selectedModule.availability
                            color: moduleSelector.selectedModule.availability === "PLANNED" ? window.textMuted : window.green
                            font.family: "Consolas"
                            font.pixelSize: 11
                            font.bold: true
                        }
                    }
                    Text {
                        text: modulePopup.opened ? "▲" : "▼"
                        color: modulePopup.opened ? window.green : window.textMuted
                        font.pixelSize: 11
                    }
                }
                background: Rectangle {
                    color: modulePopup.opened ? "#142622" : (moduleSelector.hovered ? "#13211f" : window.panelRaised)
                    border.color: modulePopup.opened ? window.green : (moduleSelector.activeFocus ? window.cyan : (moduleSelector.hovered ? "#334943" : window.line))
                    radius: 3
                }

                Popup {
                    id: modulePopup
                    x: Math.min(0, window.width
                                - moduleSelector.mapToItem(window.contentItem, 0, 0).x
                                - width - 16)
                    y: moduleSelector.height + 7
                    width: Math.min(430, window.width - 32)
                    height: featureList.implicitHeight + topPadding + bottomPadding
                    padding: 8
                    focus: true
                    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

                    background: Rectangle {
                        color: "#0a1513"
                        border.color: "#416158"
                        radius: 4
                    }

                    contentItem: Column {
                        id: featureList
                        spacing: 4

                        RowLayout {
                            width: parent.width
                            height: 30
                            Text {
                                text: "SELECT OPERATIONAL FEATURE"
                                color: window.textMuted
                                font.family: "Consolas"
                                font.pixelSize: 11
                                font.bold: true
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: appShellViewModel.modules.length + " MODULES"
                                color: window.textMuted
                                font.family: "Consolas"
                                font.pixelSize: 11
                            }
                        }

                        Repeater {
                            model: appShellViewModel.modules
                            Button {
                                id: featureOption
                                required property int index
                                required property var modelData
                                readonly property bool selected: index === appShellViewModel.selectedModuleIndex
                                width: featureList.width
                                height: 76
                                flat: true
                                hoverEnabled: true
                                palette.button: "#0e1b19"
                                palette.highlight: "#101f1c"
                                palette.midlight: "#101f1c"
                                palette.window: "#0e1b19"
                                Accessible.name: modelData.label
                                Accessible.description: modelData.description + " " + modelData.availability
                                onClicked: {
                                    appShellViewModel.selectModule(index)
                                    modulePopup.close()
                                }

                                contentItem: RowLayout {
                                    spacing: 11
                                    Rectangle {
                                        Layout.preferredWidth: 34
                                        Layout.preferredHeight: 34
                                        radius: 3
                                        color: featureOption.selected ? window.green : "#172824"
                                        border.color: featureOption.selected ? window.green : window.line
                                        Text {
                                            anchors.centerIn: parent
                                            text: String(featureOption.index + 1).padStart(2, "0")
                                            color: featureOption.selected ? "#07100f" : window.textMuted
                                            font.family: "Consolas"
                                            font.pixelSize: 12
                                            font.bold: true
                                        }
                                    }
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 3
                                        Text {
                                            Layout.fillWidth: true
                                            text: featureOption.modelData.label
                                            color: featureOption.selected ? window.green : window.textMain
                                            font.family: "Consolas"
                                            font.pixelSize: 13
                                            font.bold: true
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            Layout.fillWidth: true
                                            text: featureOption.modelData.description
                                            color: window.textMuted
                                            font.pixelSize: 11
                                            elide: Text.ElideRight
                                        }
                                    }
                                    Rectangle {
                                        Layout.preferredWidth: featureOption.modelData.availability === "SIMULATION" ? 72 : 54
                                        Layout.preferredHeight: 22
                                        radius: 3
                                        color: featureOption.modelData.availability === "PLANNED" ? "#18211f" : "#143328"
                                        border.color: featureOption.modelData.availability === "PLANNED" ? window.line : "#32735b"
                                        Text {
                                            anchors.centerIn: parent
                                            text: featureOption.modelData.availability
                                            color: featureOption.modelData.availability === "PLANNED" ? window.textMuted : window.green
                                            font.family: "Consolas"
                                            font.pixelSize: 11
                                            font.bold: true
                                        }
                                    }
                                }
                                background: Rectangle {
                                    color: featureOption.selected ? "#102a22" : (featureOption.hovered || featureOption.activeFocus ? "#101f1c" : "#0e1b19")
                                    border.color: featureOption.selected ? "#3f9878" : (featureOption.activeFocus ? window.cyan : window.line)
                                    radius: 3
                                }
                            }
                        }
                    }
                }
            }
            Item { Layout.fillWidth: true }
            Row {
                visible: window.width >= 1180
                spacing: 8
                anchors.verticalCenter: parent.verticalCenter
                StatusDot { anchors.verticalCenter: parent.verticalCenter; statusColor: airTrafficViewModel.operational ? window.green : window.amber }
                Text { text: airTrafficViewModel.operational ? "ALL SYSTEMS NOMINAL" : "DEGRADED MODE"; color: airTrafficViewModel.operational ? window.green : window.amber; font.family: "Consolas"; font.pixelSize: 13; font.bold: true }
            }
            Rectangle { width: 1; Layout.fillHeight: true; Layout.topMargin: 15; Layout.bottomMargin: 15; color: window.line }
            Column {
                Layout.preferredWidth: 92
                Text { text: airTrafficViewModel.istTime; color: window.textMain; font.family: "Consolas"; font.pixelSize: 20; font.bold: true }
                Text { text: airTrafficViewModel.istDate; color: window.textMuted; font.family: "Consolas"; font.pixelSize: 11 }
            }
        }
    }

    footer: Rectangle {
        height: 36
        color: "#091412"
        border.color: window.line
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 18
            Text { text: airTrafficViewModel.radarId; color: window.green; font.family: "Consolas"; font.pixelSize: 12; font.bold: true }
            Text { text: "UPDATE  " + airTrafficViewModel.updateRate; color: window.textMuted; font.family: "Consolas"; font.pixelSize: 12 }
            Text { text: "UTM COVERAGE  " + airTrafficViewModel.adsbCoverage; color: window.textMuted; font.family: "Consolas"; font.pixelSize: 12 }
            Text { text: "AIR TAXIS  " + airTrafficViewModel.airTaxiCount; color: window.textMuted; font.family: "Consolas"; font.pixelSize: 12 }
            Text { text: "ALERTS  " + airTrafficViewModel.alertCount; color: airTrafficViewModel.alertCount > 0 ? window.amber : window.textMuted; font.family: "Consolas"; font.pixelSize: 12; font.bold: airTrafficViewModel.alertCount > 0 }
            Item { Layout.fillWidth: true }
            Text { text: airTrafficViewModel.controllerPosition; color: window.textMuted; font.family: "Consolas"; font.pixelSize: 12 }
        }
    }

    Item {
        anchors.fill: parent
        anchors.margins: 8
        visible: appShellViewModel.selectedModuleIndex === 0

        Rectangle {
            id: trafficPanel
            width: window.width >= 1400 ? 330 : 300
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            color: window.panel
            border.color: window.line
            radius: 4

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    SectionTitle { text: "ACTIVE AIR TAXIS" }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        width: 34; height: 20; radius: 2; color: "#17332b"
                        Text { anchors.centerIn: parent; text: airTrafficViewModel.airTaxiCount; color: window.green; font.family: "Consolas"; font.pixelSize: 12; font.bold: true }
                    }
                }
                TextField {
                    id: trackSearch
                    Layout.fillWidth: true
                    implicitHeight: 34
                    placeholderText: "Filter vehicle or vertiport"
                    color: window.textMain
                    placeholderTextColor: "#5c716b"
                    font.pixelSize: 13
                    leftPadding: 10
                    rightPadding: 28
                    background: Rectangle { color: "#08110f"; border.color: window.line; radius: 3 }
                    onTextChanged: airTrafficViewModel.setAirTaxiFilter(text)
                    Keys.onEscapePressed: clear()
                    ToolButton {
                        anchors.right: parent.right
                        anchors.rightMargin: 2
                        anchors.verticalCenter: parent.verticalCenter
                        visible: trackSearch.text.length > 0
                        text: "×"
                        ToolTip.text: "Clear search"
                        ToolTip.visible: hovered
                        onClicked: trackSearch.clear()
                    }
                }
                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: 6
                    rowSpacing: 6

                    InteractiveComboBox {
                        id: altitudeQuickFilter
                        Layout.fillWidth: true
                        implicitHeight: 34
                        model: ["ALL ALT", "LOW < 1000 FT", "MID 1000-2000", "HIGH > 2000 FT"]
                        font.family: "Consolas"
                        font.pixelSize: 11
                        onActivated: airTrafficViewModel.setAltitudeFilter(index === 0 ? "" : ["LOW", "MID", "HIGH"][index - 1])
                        ToolTip.text: "Filter targets by altitude band"
                        ToolTip.visible: hovered
                    }
                    InteractiveComboBox {
                        id: phaseQuickFilter
                        Layout.fillWidth: true
                        implicitHeight: 34
                        model: ["ALL PHASES", "DEPARTURE", "EN ROUTE", "APPROACH", "PRIORITY", "CONFLICT"]
                        font.family: "Consolas"
                        font.pixelSize: 11
                        onActivated: airTrafficViewModel.setPhaseFilter(index === 0 ? "" : currentText)
                        ToolTip.text: "Filter air taxis by mission phase"
                        ToolTip.visible: hovered
                    }
                    TextField {
                        id: squawkQuickFilter
                        Layout.fillWidth: true
                        implicitHeight: 34
                        placeholderText: "SQUAWK"
                        maximumLength: 4
                        inputMethodHints: Qt.ImhDigitsOnly
                        color: window.textMain
                        placeholderTextColor: window.textMuted
                        font.family: "Consolas"
                        font.pixelSize: 11
                        background: Rectangle { color: "#08110f"; border.color: window.line; radius: 3 }
                        onTextEdited: airTrafficViewModel.setSquawkFilter(text)
                    }
                    Button {
                        Layout.fillWidth: true
                        implicitHeight: 34
                        text: "CLEAR FILTERS"
                        font.family: "Consolas"
                        font.pixelSize: 11
                        onClicked: {
                            trackSearch.clear()
                            altitudeQuickFilter.currentIndex = 0
                            phaseQuickFilter.currentIndex = 0
                            squawkQuickFilter.clear()
                            airTrafficViewModel.clearQuickFilters()
                        }
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Text { text: "VEHICLE"; color: window.textMuted; font.family: "Consolas"; font.pixelSize: 11; Layout.preferredWidth: 76 }
                    Text { text: "CORRIDOR / ALT"; color: window.textMuted; font.family: "Consolas"; font.pixelSize: 11; Layout.fillWidth: true }
                    Text { text: "PHASE"; color: window.textMuted; font.family: "Consolas"; font.pixelSize: 11; Layout.preferredWidth: 48; horizontalAlignment: Text.AlignRight }
                }
                ListView {
                    id: airTaxiList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 3
                    clip: true
                    model: airTrafficViewModel.filteredAirTaxis
                    currentIndex: airTrafficViewModel.selectedFilteredTrack
                    boundsBehavior: Flickable.StopAtBounds

                    Text {
                        anchors.centerIn: parent
                        visible: airTrafficViewModel.filteredAirTaxiCount === 0
                        text: "NO AIR TAXIS MATCH\nCURRENT FILTERS"
                        color: window.textMuted
                        font.family: "Consolas"
                        font.pixelSize: 12
                        horizontalAlignment: Text.AlignHCenter
                        lineHeight: 1.4
                    }

                    delegate: Rectangle {
                        required property int index
                        required property string callSign
                        required property string route
                        required property string level
                        required property string trend
                        required property string state
                        required property string statusLabel
                        required property string severity
                        width: ListView.view.width
                        height: 70
                        radius: 3
                        color: index === airTrafficViewModel.selectedFilteredTrack ? "#17352d" : (mouse.containsMouse ? "#132522" : "#0f1c1a")
                        border.color: severity === "warning" ? window.amber : (index === airTrafficViewModel.selectedFilteredTrack ? "#3f9878" : "#1f302d")
                        Rectangle { width: 3; height: parent.height; color: severity === "warning" ? window.amber : (index === airTrafficViewModel.selectedFilteredTrack ? window.green : "transparent") }
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 18
                            spacing: 8
                            Text { text: callSign; color: severity === "warning" ? "#ffd087" : window.textMain; font.family: "Consolas"; font.pixelSize: 14; font.bold: true; Layout.preferredWidth: 72 }
                            Column {
                                Layout.fillWidth: true
                                Text { text: route; color: window.textMuted; font.family: "Consolas"; font.pixelSize: 11 }
                                Text { text: level + "  " + trend; color: window.green; font.family: "Consolas"; font.pixelSize: 13 }
                            }
                            Text { text: statusLabel; color: severity === "warning" ? window.amber : window.textMuted; font.family: "Consolas"; font.pixelSize: 11; font.bold: true; Layout.preferredWidth: 48; horizontalAlignment: Text.AlignRight }
                        }
                        MouseArea { id: mouse; anchors.fill: parent; hoverEnabled: true; onClicked: airTrafficViewModel.selectFilteredTrack(index) }
                    }
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                }
            }
        }

        Rectangle {
            anchors.left: trafficPanel.right
            anchors.leftMargin: 8
            anchors.right: inspectorPanel.left
            anchors.rightMargin: 8
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            color: "#07110f"
            border.color: window.line
            radius: 4
            clip: true

            RadarScope {
                id: radar
                anchors.fill: parent
                anchors.topMargin: 42
                airTaxis: airTrafficViewModel.filteredAirTaxis
                rangeNm: airTrafficViewModel.rangeNm
                sweepEnabled: airTrafficViewModel.sweepEnabled
                weatherEnabled: airTrafficViewModel.weatherEnabled
                routesEnabled: airTrafficViewModel.routesEnabled
                selectedTrack: airTrafficViewModel.selectedFilteredTrack
                sectorBoundariesEnabled: airspaceManager.sectorBoundariesEnabled
                approachCorridorsEnabled: airspaceManager.approachCorridorsEnabled
                geofencesEnabled: airspaceManager.geofencesEnabled
                atMinimumRange: airTrafficViewModel.atMinimumRange
                atMaximumRange: airTrafficViewModel.atMaximumRange
                boundaryPolyline: airTrafficViewModel.boundaryPolyline
                routeOverlays: airTrafficViewModel.routeOverlays
                weatherCells: airTrafficViewModel.weatherCells
                viewCenterX: airTrafficViewModel.viewCenterX
                viewCenterY: airTrafficViewModel.viewCenterY
                onTrackSelected: index => airTrafficViewModel.selectFilteredTrack(index)
                onRangeStepRequested: steps => airTrafficViewModel.changeRangeBySteps(steps)
                onTrackFocusRequested: index => airTrafficViewModel.focusFilteredTrack(index)
            }
            Rectangle {
                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                height: 42; color: "#0b1715"; border.color: window.line
                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10; spacing: 6
                    ToolButton { text: "-"; enabled: !airTrafficViewModel.atMaximumRange; Accessible.name: "Zoom out"; ToolTip.text: "Zoom out / increase radar range"; ToolTip.visible: hovered; onClicked: airTrafficViewModel.increaseRange() }
                    Rectangle {
                        width: 64; height: 32; color: window.panelRaised; border.color: window.line; radius: 3
                        Text { anchors.centerIn: parent; text: airTrafficViewModel.rangeNm + " NM"; color: window.textMain; font.family: "Consolas"; font.pixelSize: 13 }
                    }
                    ToolButton { text: "+"; enabled: !airTrafficViewModel.atMinimumRange; Accessible.name: "Zoom in"; ToolTip.text: "Zoom in / decrease radar range"; ToolTip.visible: hovered; onClicked: airTrafficViewModel.decreaseRange() }
                    ToolButton { text: "CTR"; implicitWidth: 42; Accessible.name: "Reset radar view"; ToolTip.text: "Reset radar center and range"; ToolTip.visible: hovered; onClicked: airTrafficViewModel.resetRadarView() }
                    Rectangle { width: 1; height: 24; color: window.line }
                    ToolButton { text: "WX"; checkable: true; checked: airTrafficViewModel.weatherEnabled; ToolTip.text: "Weather overlay"; ToolTip.visible: hovered; onClicked: airTrafficViewModel.toggleWeather(); implicitWidth: 44 }
                    ToolButton { text: "COR"; checkable: true; checked: airTrafficViewModel.routesEnabled; ToolTip.text: "UAM corridors"; ToolTip.visible: hovered; onClicked: airTrafficViewModel.toggleRoutes(); implicitWidth: 44 }
                    ToolButton { text: airTrafficViewModel.sweepEnabled ? "II" : ">"; ToolTip.text: airTrafficViewModel.sweepEnabled ? "Pause sweep" : "Resume sweep"; ToolTip.visible: hovered; onClicked: airTrafficViewModel.toggleSweep() }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: airTrafficViewModel.selectedAirTaxi.callSign
                              ? airTrafficViewModel.selectedAirTaxi.callSign + "  " + airTrafficViewModel.selectedAirTaxi.level
                              : "NO TRACK SELECTED"
                        color: window.textMain
                        font.family: "Consolas"
                        font.pixelSize: 12
                        font.bold: true
                    }
                    Rectangle { width: 1; height: 24; color: window.line }
                    Row {
                        spacing: 7
                        StatusDot { anchors.verticalCenter: parent.verticalCenter; statusColor: airTrafficViewModel.operational ? window.green : window.amber }
                        Text { text: airTrafficViewModel.dataStatusText; color: airTrafficViewModel.operational ? window.green : window.amber; font.family: "Consolas"; font.pixelSize: 12; font.bold: true }
                    }
                }
            }
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.topMargin: 52
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                height: 54
                visible: airTrafficViewModel.separationAlertActive
                color: "#e61f1a0f"
                border.color: window.amber
                radius: 3
                z: 4
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 8
                    spacing: 12
                    Rectangle {
                        color: window.amber
                        radius: 2
                        width: textItem.implicitWidth + 10
                        height: textItem.implicitHeight + 10

                        Text {
                            id: textItem
                            anchors.centerIn: parent
                            text: airTrafficViewModel.separationAlert.code
                            color: "#07100f"
                            font.family: "Consolas"
                            font.pixelSize: 12
                            font.bold: true
                        }
                    }
                    Column {
                        Text { text: airTrafficViewModel.separationAlert.title; color: "#ffe0a8"; font.family: "Consolas"; font.pixelSize: 13; font.bold: true }
                        Text { text: airTrafficViewModel.separationAlert.instruction; color: "#bda77f"; font.family: "Consolas"; font.pixelSize: 11 }
                    }
                    Item { Layout.fillWidth: true }
                    Button {
                        text: "ACKNOWLEDGE"
                        implicitWidth: 92
                        font.family: "Consolas"
                        font.pixelSize: 11
                        font.bold: true
                        onClicked: airTrafficViewModel.acknowledgeSeparationAlert()
                        background: Rectangle { color: parent.hovered ? "#6c4a1c" : "#3c2d18"; border.color: window.amber; radius: 3 }
                        contentItem: Text { text: parent.text; color: window.amber; font: parent.font; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    }
                }
            }
            Rectangle {
                anchors.left: parent.left; anchors.bottom: parent.bottom; anchors.margins: 14
                width: 194; height: 54; color: "#ca101817"; border.color: window.line; radius: 3
                Column {
                    anchors.centerIn: parent; spacing: 3
                    Text { text: airTrafficViewModel.activeVertiport.name + "  PAD " + airTrafficViewModel.activeVertiport.pad + " ACTIVE"; color: window.textMain; font.family: "Consolas"; font.pixelSize: 12; font.bold: true }
                    Row {
                        spacing: 12
                        Text { text: "APCH " + airTrafficViewModel.activeVertiport.heading + "°"; color: window.textMuted; font.family: "Consolas"; font.pixelSize: 11 }
                        Text { text: airTrafficViewModel.activeVertiport.status; color: window.green; font.family: "Consolas"; font.pixelSize: 11 }
                    }
                }
            }
        }

        Rectangle {
            id: inspectorPanel
            width: window.width >= 1500 ? 340 : 310
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            color: window.panel
            border.color: window.line
            radius: 4

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8
                TabBar {
                    id: surveillanceInspectorTabs
                    Layout.fillWidth: true
                    TabButton { width: surveillanceInspectorTabs.width / 3; text: "AIR TAXI" }
                    TabButton { width: surveillanceInspectorTabs.width / 3; text: "UAM WEATHER" }
                    TabButton { width: surveillanceInspectorTabs.width / 3; text: "CORRIDORS" }
                }
                StackLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    currentIndex: surveillanceInspectorTabs.currentIndex
                    ColumnLayout {
                        spacing: 12
                        RowLayout {
                            Layout.fillWidth: true
                            SectionTitle { text: "SELECTED AIR TAXI" }
                            Item { Layout.fillWidth: true }
                            StatusDot { statusColor: airTrafficViewModel.selectedAirTaxi.alert ? window.amber : window.green }
                        }
                        Text { text: airTrafficViewModel.selectedAirTaxi.callSign || "---"; color: window.textMain; font.family: "Consolas"; font.pixelSize: 28; font.bold: true }
                        Text { text: airTrafficViewModel.selectedAirTaxi.route || "NO SURVEILLANCE TRACK SELECTED"; color: window.cyan; font.family: "Consolas"; font.pixelSize: 13 }
                        Rectangle { Layout.fillWidth: true; height: 1; color: window.line }
                        GridLayout {
                            Layout.fillWidth: true; columns: 2; columnSpacing: 22; rowSpacing: 14
                            Repeater {
                                model: airTrafficViewModel.selectedAirTaxiMetrics
                                Column {
                                    id: selectedMetric
                                    required property var modelData
                                    Text { text: selectedMetric.modelData.label; color: window.textMuted; font.family: "Consolas"; font.pixelSize: 11 }
                                    Text { text: selectedMetric.modelData.value; color: window.textMain; font.family: "Consolas"; font.pixelSize: 14; font.bold: true }
                                }
                            }
                        }
                        Rectangle { Layout.fillWidth: true; height: 42; color: airTrafficViewModel.selectedAirTaxi.alert ? "#2b2113" : "#10251f"; border.color: airTrafficViewModel.selectedAirTaxi.alert ? window.amber : "#285747"; radius: 3; Text { anchors.centerIn: parent; text: airTrafficViewModel.selectedAirTaxi.state; color: airTrafficViewModel.selectedAirTaxi.alert ? window.amber : window.green; font.family: "Consolas"; font.pixelSize: 13; font.bold: true } }
                        Item { Layout.fillHeight: true }
                    }
                    ColumnLayout {
                        spacing: 12
                        SectionTitle { text: "LOCAL CONDITIONS  •  " + airTrafficViewModel.weatherSummary.station }
                    RowLayout {
                        Layout.fillWidth: true
                        Column {
                            Text { text: airTrafficViewModel.weatherSummary.temperature + "°C"; color: window.textMain; font.family: "Consolas"; font.pixelSize: 24; font.bold: true }
                            Text { text: airTrafficViewModel.weatherSummary.cloud; color: window.textMuted; font.family: "Consolas"; font.pixelSize: 11 }
                        }
                        Item { Layout.fillWidth: true }
                        Column {
                            Text { text: airTrafficViewModel.weatherSummary.windDirection + "°"; color: window.cyan; font.family: "Consolas"; font.pixelSize: 17; font.bold: true }
                            Text { text: airTrafficViewModel.weatherSummary.wind; color: window.textMuted; font.family: "Consolas"; font.pixelSize: 11 }
                        }
                    }
                        Rectangle { Layout.fillWidth: true; height: 1; color: window.line }
                        GridLayout {
                            Layout.fillWidth: true; columns: 3
                            Repeater {
                                model: airTrafficViewModel.weatherMetrics
                                Column {
                                    id: weatherMetric
                                    required property var modelData
                                    Text { text: weatherMetric.modelData.label; color: window.textMuted; font.family: "Consolas"; font.pixelSize: 11 }
                                    Text { text: weatherMetric.modelData.value; color: window.textMain; font.family: "Consolas"; font.pixelSize: 13; font.bold: true }
                                }
                            }
                        }
                        Text { Layout.fillWidth: true; text: airTrafficViewModel.weatherSummary.advisory; color: window.amber; font.family: "Consolas"; font.pixelSize: 11; font.bold: true; elide: Text.ElideRight }
                        Item { Layout.fillHeight: true }
                    }
                    ColumnLayout {
                        spacing: 14
                        SectionTitle { text: "CORRIDOR LOAD" }
                        Repeater {
                            model: airTrafficViewModel.sectorLoads
                            ColumnLayout {
                                id: sectorLoad
                                required property var modelData
                                Layout.fillWidth: true; spacing: 5
                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: sectorLoad.modelData.name; color: window.textMain; font.family: "Consolas"; font.pixelSize: 13; font.bold: true }
                                    Item { Layout.fillWidth: true }
                                    Text { text: sectorLoad.modelData.trackCount + " AIR TAXIS"; color: window.textMuted; font.family: "Consolas"; font.pixelSize: 11 }
                                }
                                Rectangle { Layout.fillWidth: true; height: 6; color: "#1a2926"; Rectangle { width: parent.width * sectorLoad.modelData.load; height: parent.height; color: sectorLoad.modelData.category === "primary" ? window.green : window.cyan } }
                            }
                        }
                        Item { Layout.fillHeight: true }
                        RowLayout {
                            Layout.fillWidth: true
                            StatusDot {}
                            Text { text: airTrafficViewModel.datalinkStatus.label; color: window.textMuted; font.family: "Consolas"; font.pixelSize: 11 }
                            Item { Layout.fillWidth: true }
                            Text { text: airTrafficViewModel.datalinkStatus.messageCount + " MSG"; color: window.green; font.family: "Consolas"; font.pixelSize: 11 }
                        }
                    }
                }
                AirspaceManager {
                    id: airspaceManager
                    Layout.fillWidth: true
                    Layout.preferredHeight: 148
                    onSectorBoundariesToggled: sectorBoundariesEnabled = !sectorBoundariesEnabled
                    onApproachCorridorsToggled: approachCorridorsEnabled = !approachCorridorsEnabled
                    onGeofencesToggled: geofencesEnabled = !geofencesEnabled
                }
            }
        }
    }

    MultiStakeholderView {
        anchors.fill: parent
        anchors.margins: 8
        visible: appShellViewModel.selectedModuleIndex === 3
        viewModel: stakeholderSimulationViewModel
    }

    HubGroundOperationsView {
        anchors.fill: parent
        anchors.margins: 8
        visible: appShellViewModel.selectedModuleIndex === 2
        viewModel: stakeholderSimulationViewModel
    }

    VehicleTelemetryView {
        anchors.fill: parent
        anchors.margins: 8
        visible: appShellViewModel.selectedModuleIndex === 1
    }

    Shortcut {
        sequence: "Ctrl+F"
        enabled: appShellViewModel.selectedModuleIndex === 0
        onActivated: trackSearch.forceActiveFocus()
    }
    Shortcut {
        sequence: "Ctrl+-"
        enabled: appShellViewModel.selectedModuleIndex === 0 && !airTrafficViewModel.atMaximumRange
        onActivated: airTrafficViewModel.increaseRange()
    }
    Shortcut {
        sequence: "Ctrl+="
        enabled: appShellViewModel.selectedModuleIndex === 0 && !airTrafficViewModel.atMinimumRange
        onActivated: airTrafficViewModel.decreaseRange()
    }
    Shortcut {
        sequence: "Ctrl+0"
        enabled: appShellViewModel.selectedModuleIndex === 0
        onActivated: airTrafficViewModel.resetRadarView()
    }
}