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
    title: "Air Traffic Management | Delhi ACC"
    color: "#07100f"

    readonly property color panel: "#0c1716"
    readonly property color panelRaised: "#12201e"
    readonly property color line: "#293a37"
    readonly property color textMain: "#d9e5e1"
    readonly property color textMuted: "#7f9690"
    readonly property color green: "#6fffc1"
    readonly property color amber: "#ffb443"
    readonly property color cyan: "#73d9ff"
    property int moduleIndex: 0

    font.family: "Segoe UI"

    component SectionTitle: Text {
        color: window.textMuted
        font.family: "Consolas"
        font.pixelSize: 11
        font.bold: true
        font.letterSpacing: 1.2
    }

    component StatusDot: Rectangle {
        property color statusColor: window.green
        width: 7
        height: 7
        radius: 4
        color: statusColor
    }

    component ToolButton: Button {
        id: control
        implicitWidth: 36
        implicitHeight: 32
        font.family: "Consolas"
        font.pixelSize: 12
        contentItem: Text {
            text: control.text
            color: control.checked ? "#07100f" : window.textMain
            font: control.font
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        background: Rectangle {
            color: control.checked ? window.green : (control.hovered ? "#1c302c" : window.panelRaised)
            border.color: control.checked ? window.green : window.line
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
                Text { anchors.centerIn: parent; text: "AT"; color: "#07100f"; font.bold: true; font.pixelSize: 13 }
            }
            Column {
                Layout.preferredWidth: 228
                spacing: 1
                Text { text: "DELHI AREA CONTROL"; color: window.textMain; font.bold: true; font.pixelSize: 15; font.letterSpacing: 0.8 }
                Text { text: "AIR TRAFFIC MANAGEMENT"; color: window.textMuted; font.family: "Consolas"; font.pixelSize: 10; font.letterSpacing: 1.3 }
            }
            Rectangle { width: 1; Layout.fillHeight: true; Layout.topMargin: 15; Layout.bottomMargin: 15; color: window.line }
            Row {
                visible: window.width >= 1360
                spacing: 20
                Repeater {
                    model: [{label:"SECTOR", value:"DLC-W"}, {label:"FREQUENCY", value:"128.35"}, {label:"QNH", value:"1008 hPa"}]
                    Column {
                        spacing: 2
                        Text { text: modelData.label; color: window.textMuted; font.family: "Consolas"; font.pixelSize: 9 }
                        Text { text: modelData.value; color: window.textMain; font.family: "Consolas"; font.pixelSize: 13; font.bold: true }
                    }
                }
            }
            ComboBox {
                id: moduleSelector
                Layout.preferredWidth: window.width >= 1360 ? 220 : 185
                implicitHeight: 32
                currentIndex: window.moduleIndex
                model: [
                    "SURVEILLANCE",
                    "STAKEHOLDER SIM",
                    "BATTERY / ALL - PLANNED",
                    "STRESS TEST - PLANNED",
                    "CONFORMANCE - PLANNED"
                ]
                font.family: "Consolas"
                font.pixelSize: 10
                onActivated: index => window.moduleIndex = index
            }
            Item { Layout.fillWidth: true }
            Row {
                visible: window.width >= 1180
                spacing: 8
                anchors.verticalCenter: parent.verticalCenter
                StatusDot { anchors.verticalCenter: parent.verticalCenter; statusColor: airTrafficViewModel.operational ? window.green : window.amber }
                Text { text: airTrafficViewModel.operational ? "ALL SYSTEMS NOMINAL" : "DEGRADED MODE"; color: airTrafficViewModel.operational ? window.green : window.amber; font.family: "Consolas"; font.pixelSize: 11; font.bold: true }
            }
            Rectangle { width: 1; Layout.fillHeight: true; Layout.topMargin: 15; Layout.bottomMargin: 15; color: window.line }
            Column {
                Layout.preferredWidth: 92
                Text { id: utcClock; color: window.textMain; font.family: "Consolas"; font.pixelSize: 18; font.bold: true }
                Text { text: "04 AUG 2026 UTC"; color: window.textMuted; font.family: "Consolas"; font.pixelSize: 9 }
            }
            Timer {
                interval: 1000; running: true; repeat: true; triggeredOnStart: true
                onTriggered: utcClock.text = new Date().toLocaleTimeString(Qt.locale("en_GB"), "HH:mm:ss")
            }
        }
    }

    footer: Rectangle {
        height: 32
        color: "#091412"
        border.color: window.line
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 18
            Text { text: "RADAR 01"; color: window.green; font.family: "Consolas"; font.pixelSize: 10; font.bold: true }
            Text { text: "UPDATE 1.0s"; color: window.textMuted; font.family: "Consolas"; font.pixelSize: 10 }
            Text { text: "ADS-B  99.8%"; color: window.textMuted; font.family: "Consolas"; font.pixelSize: 10 }
            Text { text: "TRACKS  " + airTrafficViewModel.flightCount; color: window.textMuted; font.family: "Consolas"; font.pixelSize: 10 }
            Text { text: "ALERTS  " + airTrafficViewModel.alertCount; color: airTrafficViewModel.alertCount > 0 ? window.amber : window.textMuted; font.family: "Consolas"; font.pixelSize: 10; font.bold: airTrafficViewModel.alertCount > 0 }
            Item { Layout.fillWidth: true }
            Text { text: "CTRL: PRIYA S.  -  POSITION: DWC-04"; color: window.textMuted; font.family: "Consolas"; font.pixelSize: 10 }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 8
        visible: window.moduleIndex === 0

        Rectangle {
            Layout.preferredWidth: window.width >= 1400 ? 290 : 260
            Layout.fillHeight: true
            color: window.panel
            border.color: window.line
            radius: 4

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    SectionTitle { text: "ACTIVE TRAFFIC" }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        width: 34; height: 20; radius: 2; color: "#17332b"
                        Text { anchors.centerIn: parent; text: airTrafficViewModel.flightCount; color: window.green; font.family: "Consolas"; font.pixelSize: 10; font.bold: true }
                    }
                }
                TextField {
                    id: trackSearch
                    Layout.fillWidth: true
                    implicitHeight: 34
                    placeholderText: "Search callsign or route"
                    color: window.textMain
                    placeholderTextColor: "#5c716b"
                    font.pixelSize: 11
                    leftPadding: 10
                    rightPadding: 28
                    background: Rectangle { color: "#08110f"; border.color: window.line; radius: 3 }
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
                RowLayout {
                    Layout.fillWidth: true
                    Text { text: "CALLSIGN"; color: window.textMuted; font.family: "Consolas"; font.pixelSize: 9; Layout.preferredWidth: 65 }
                    Text { text: "ROUTE / LEVEL"; color: window.textMuted; font.family: "Consolas"; font.pixelSize: 9; Layout.fillWidth: true }
                    Text { text: "STATE"; color: window.textMuted; font.family: "Consolas"; font.pixelSize: 9 }
                }
                ListView {
                    id: flightList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 3
                    clip: true
                    model: airTrafficViewModel.flights
                    currentIndex: airTrafficViewModel.selectedTrack

                    delegate: Rectangle {
                        required property int index
                        required property string callSign
                        required property string route
                        required property string level
                        required property string trend
                        required property string state
                        readonly property bool matchesFilter: trackSearch.text.trim().length === 0
                            || callSign.toLowerCase().includes(trackSearch.text.trim().toLowerCase())
                            || route.toLowerCase().includes(trackSearch.text.trim().toLowerCase())
                        width: ListView.view.width
                        height: matchesFilter ? 62 : 0
                        visible: matchesFilter
                        radius: 3
                        color: index === airTrafficViewModel.selectedTrack ? "#17352d" : (mouse.containsMouse ? "#132522" : "#0f1c1a")
                        border.color: state === "CONFLICT" ? window.amber : (index === airTrafficViewModel.selectedTrack ? "#3f9878" : "#1f302d")
                        Rectangle { width: 3; height: parent.height; color: state === "CONFLICT" ? window.amber : (index === airTrafficViewModel.selectedTrack ? window.green : "transparent") }
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 7
                            spacing: 8
                            Text { text: callSign; color: state === "CONFLICT" ? "#ffd087" : window.textMain; font.family: "Consolas"; font.pixelSize: 12; font.bold: true; Layout.preferredWidth: 62 }
                            Column {
                                Layout.fillWidth: true
                                Text { text: route; color: window.textMuted; font.family: "Consolas"; font.pixelSize: 9 }
                                Text { text: level + "  " + trend; color: window.green; font.family: "Consolas"; font.pixelSize: 11 }
                            }
                            Text { text: state === "CONFLICT" ? "STCA" : state.substring(0, 3); color: state === "CONFLICT" ? window.amber : window.textMuted; font.family: "Consolas"; font.pixelSize: 9; font.bold: true }
                        }
                        MouseArea { id: mouse; anchors.fill: parent; hoverEnabled: true; onClicked: airTrafficViewModel.selectedTrack = index }
                    }
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#07110f"
            border.color: window.line
            radius: 4
            clip: true

            RadarScope {
                id: radar
                anchors.fill: parent
                anchors.topMargin: 42
                flights: airTrafficViewModel.flights
                rangeNm: airTrafficViewModel.rangeNm
                sweepEnabled: airTrafficViewModel.sweepEnabled
                weatherEnabled: airTrafficViewModel.weatherEnabled
                routesEnabled: airTrafficViewModel.routesEnabled
                selectedTrack: airTrafficViewModel.selectedTrack
                onTrackSelected: index => airTrafficViewModel.selectedTrack = index
                onRangeChangeRequested: delta => airTrafficViewModel.rangeNm += delta
            }
            Rectangle {
                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                height: 42; color: "#0b1715"; border.color: window.line
                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10; spacing: 6
                    ToolButton { text: "-"; ToolTip.text: "Decrease radar range"; ToolTip.visible: hovered; onClicked: airTrafficViewModel.decreaseRange() }
                    Rectangle {
                        width: 64; height: 32; color: window.panelRaised; border.color: window.line; radius: 3
                        Text { anchors.centerIn: parent; text: airTrafficViewModel.rangeNm + " NM"; color: window.textMain; font.family: "Consolas"; font.pixelSize: 11 }
                    }
                    ToolButton { text: "+"; ToolTip.text: "Increase radar range"; ToolTip.visible: hovered; onClicked: airTrafficViewModel.increaseRange() }
                    Rectangle { width: 1; height: 24; color: window.line }
                    ToolButton { text: "WX"; checkable: true; checked: airTrafficViewModel.weatherEnabled; ToolTip.text: "Weather overlay"; ToolTip.visible: hovered; onToggled: airTrafficViewModel.weatherEnabled = checked; implicitWidth: 44 }
                    ToolButton { text: "RTE"; checkable: true; checked: airTrafficViewModel.routesEnabled; ToolTip.text: "Airway routes"; ToolTip.visible: hovered; onToggled: airTrafficViewModel.routesEnabled = checked; implicitWidth: 44 }
                    ToolButton { text: airTrafficViewModel.sweepEnabled ? "II" : ">"; ToolTip.text: airTrafficViewModel.sweepEnabled ? "Pause sweep" : "Resume sweep"; ToolTip.visible: hovered; onClicked: airTrafficViewModel.sweepEnabled = !airTrafficViewModel.sweepEnabled }
                    Item { Layout.fillWidth: true }
                    Text { text: airTrafficViewModel.selectedFlight.callSign + "  " + airTrafficViewModel.selectedFlight.level; color: window.textMain; font.family: "Consolas"; font.pixelSize: 10; font.bold: true }
                    Rectangle { width: 1; height: 24; color: window.line }
                    Row {
                        spacing: 7
                        StatusDot { anchors.verticalCenter: parent.verticalCenter }
                        Text { text: "LIVE SURVEILLANCE"; color: window.green; font.family: "Consolas"; font.pixelSize: 10; font.bold: true }
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
                        // Optional: let the rectangle size itself to fit the text + padding
                        width: textItem.implicitWidth + 10 // 5 padding on left + 5 on right
                        height: textItem.implicitHeight + 10 // 5 top + 5 bottom

                        Text {
                            id: textItem
                            anchors.centerIn: parent
                            text: "STCA"
                            color: "#07100f"
                            font.family: "Consolas"
                            font.pixelSize: 10
                            font.bold: true
                        }
                    }
                    //Text { text: "STCA"; color: "#07100f"; font.family: "Consolas"; font.pixelSize: 10; font.bold: true; padding: 5; background: Rectangle { color: window.amber; radius: 2 } }
                    Column {
                        Text { text: "IGO613 / VTI829  •  PREDICTED LOSS OF SEPARATION"; color: "#ffe0a8"; font.family: "Consolas"; font.pixelSize: 11; font.bold: true }
                        Text { text: "CPA 3.1 NM / 700 FT  •  EST 14:38Z"; color: "#bda77f"; font.family: "Consolas"; font.pixelSize: 9 }
                    }
                    Item { Layout.fillWidth: true }
                    Button {
                        text: "ACK"
                        font.family: "Consolas"
                        font.pixelSize: 9
                        font.bold: true
                        onClicked: airTrafficViewModel.acknowledgeSeparationAlert()
                        background: Rectangle { color: parent.hovered ? "#6c4a1c" : "#3c2d18"; border.color: window.amber; radius: 3 }
                        contentItem: Text { text: parent.text; color: window.amber; font: parent.font; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    }
                }
            }
            Rectangle {
                anchors.left: parent.left; anchors.bottom: parent.bottom; anchors.margins: 14
                width: 160; height: 48; color: "#ca101817"; border.color: window.line; radius: 3
                Column {
                    anchors.centerIn: parent; spacing: 3
                    Text { text: "VIDP  RWY 28 ACTIVE"; color: window.textMain; font.family: "Consolas"; font.pixelSize: 10; font.bold: true }
                    Row {
                        spacing: 12
                        Text { text: "HDG 281°"; color: window.textMuted; font.family: "Consolas"; font.pixelSize: 9 }
                        Text { text: "ILS 110.3"; color: window.green; font.family: "Consolas"; font.pixelSize: 9 }
                    }
                }
            }
        }

        Rectangle {
            Layout.preferredWidth: window.width >= 1500 ? 300 : 272
            Layout.fillHeight: true
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
                    TabButton { width: surveillanceInspectorTabs.width / 3; text: "TRACK" }
                    TabButton { width: surveillanceInspectorTabs.width / 3; text: "WEATHER" }
                    TabButton { width: surveillanceInspectorTabs.width / 3; text: "SECTORS" }
                }
                StackLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    currentIndex: surveillanceInspectorTabs.currentIndex
                    ColumnLayout {
                        spacing: 12
                        RowLayout {
                            Layout.fillWidth: true
                            SectionTitle { text: "SELECTED TRACK" }
                            Item { Layout.fillWidth: true }
                            StatusDot { statusColor: airTrafficViewModel.selectedFlight.alert ? window.amber : window.green }
                        }
                        Text { text: airTrafficViewModel.selectedFlight.callSign; color: window.textMain; font.family: "Consolas"; font.pixelSize: 25; font.bold: true }
                        Text { text: airTrafficViewModel.selectedFlight.route; color: window.cyan; font.family: "Consolas"; font.pixelSize: 11 }
                        Rectangle { Layout.fillWidth: true; height: 1; color: window.line }
                        GridLayout {
                            Layout.fillWidth: true; columns: 2; columnSpacing: 22; rowSpacing: 14
                            Repeater {
                                model: [
                                    {key:"SQUAWK", value:airTrafficViewModel.selectedFlight.squawk},
                                    {key:"CLEARED", value:airTrafficViewModel.selectedFlight.level},
                                    {key:"GROUND SPEED", value:airTrafficViewModel.selectedFlight.speed + " KT"},
                                    {key:"TREND", value:airTrafficViewModel.selectedFlight.trend},
                                    {key:"HEADING", value:airTrafficViewModel.selectedFlight.heading + "°"},
                                    {key:"AIRCRAFT", value:airTrafficViewModel.selectedFlight.aircraftType}
                                ]
                                Column {
                                    Text { text: modelData.key; color: window.textMuted; font.family: "Consolas"; font.pixelSize: 8 }
                                    Text { text: modelData.value; color: window.textMain; font.family: "Consolas"; font.pixelSize: 12; font.bold: true }
                                }
                            }
                        }
                        Rectangle { Layout.fillWidth: true; height: 38; color: airTrafficViewModel.selectedFlight.alert ? "#2b2113" : "#10251f"; border.color: airTrafficViewModel.selectedFlight.alert ? window.amber : "#285747"; radius: 3; Text { anchors.centerIn: parent; text: airTrafficViewModel.selectedFlight.state; color: airTrafficViewModel.selectedFlight.alert ? window.amber : window.green; font.family: "Consolas"; font.pixelSize: 11; font.bold: true } }
                        Item { Layout.fillHeight: true }
                    }
                    ColumnLayout {
                        spacing: 12
                        SectionTitle { text: "METAR  •  VIDP" }
                    RowLayout {
                        Layout.fillWidth: true
                        Column {
                            Text { text: "31°C"; color: window.textMain; font.family: "Consolas"; font.pixelSize: 24; font.bold: true }
                            Text { text: "FEW 3,000 FT"; color: window.textMuted; font.family: "Consolas"; font.pixelSize: 9 }
                        }
                        Item { Layout.fillWidth: true }
                        Column {
                            Text { text: "280°"; color: window.cyan; font.family: "Consolas"; font.pixelSize: 17; font.bold: true }
                            Text { text: "12 KT  G18"; color: window.textMuted; font.family: "Consolas"; font.pixelSize: 9 }
                        }
                    }
                        Rectangle { Layout.fillWidth: true; height: 1; color: window.line }
                        GridLayout {
                            Layout.fillWidth: true; columns: 3
                            Repeater {
                                model: [{k:"VIS",v:"6 KM"},{k:"QNH",v:"1008"},{k:"DEW",v:"24°C"}]
                                Column {
                                    Text { text: modelData.k; color: window.textMuted; font.family: "Consolas"; font.pixelSize: 8 }
                                    Text { text: modelData.v; color: window.textMain; font.family: "Consolas"; font.pixelSize: 11; font.bold: true }
                                }
                            }
                        }
                        Text { text: "TEMPO TSRA  •  CB NW OF FIELD"; color: window.amber; font.family: "Consolas"; font.pixelSize: 9; font.bold: true }
                        Item { Layout.fillHeight: true }
                    }
                    ColumnLayout {
                        spacing: 14
                        SectionTitle { text: "SECTOR LOAD" }
                        Repeater {
                            model: [{n:"DLC-W", count:2, load:.25, c:window.green},{n:"DLC-E",count:3,load:.38,c:window.green},{n:"TMA-N",count:1,load:.13,c:window.cyan},{n:"TMA-S",count:2,load:.25,c:window.cyan}]
                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 5
                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: modelData.n; color: window.textMain; font.family: "Consolas"; font.pixelSize: 11; font.bold: true }
                                    Item { Layout.fillWidth: true }
                                    Text { text: modelData.count + " TRACKS"; color: window.textMuted; font.family: "Consolas"; font.pixelSize: 9 }
                                }
                                Rectangle { Layout.fillWidth: true; height: 6; color: "#1a2926"; Rectangle { width: parent.width * modelData.load; height: parent.height; color: modelData.c } }
                            }
                        }
                        Item { Layout.fillHeight: true }
                        RowLayout {
                            Layout.fillWidth: true
                            StatusDot {}
                            Text { text: "CPDLC ONLINE"; color: window.textMuted; font.family: "Consolas"; font.pixelSize: 9 }
                            Item { Layout.fillWidth: true }
                            Text { text: "12 MSG"; color: window.green; font.family: "Consolas"; font.pixelSize: 9 }
                        }
                    }
                }
            }
        }
    }

    MultiStakeholderView {
        anchors.fill: parent
        anchors.margins: 8
        visible: window.moduleIndex === 1
        viewModel: stakeholderSimulationViewModel
    }

    FeaturePlaceholder {
        anchors.fill: parent
        anchors.margins: 8
        visible: window.moduleIndex === 2
        featureNumber: "02"
        title: "BATTERY ENDURANCE & ALTERNATIVE LANDING LOCATION ENGINE"
        summary: "Will calculate mission energy reserves continuously and rank reachable alternative landing locations under operational constraints."
        capabilities: ["Energy reserve and degradation model", "Reachable ALL ranking", "Diversion recommendation workflow"]
    }

    FeaturePlaceholder {
        anchors.fill: parent
        anchors.margins: 8
        visible: window.moduleIndex === 3
        featureNumber: "03"
        title: "DISRUPTION AND STRESS-TESTING SCENARIOS"
        summary: "Will inject deterministic and stochastic disruptions to measure network resilience and operator response quality."
        capabilities: ["Weather and infrastructure failures", "Demand surge scenarios", "Recovery KPI comparison"]
    }

    FeaturePlaceholder {
        anchors.fill: parent
        anchors.margins: 8
        visible: window.moduleIndex === 4
        featureNumber: "04"
        title: "CONFORMANCE AND TRAJECTORY TRACKING MODULE"
        summary: "Will compare live tracks with cleared four-dimensional trajectories and issue escalating conformance alerts."
        capabilities: ["4D trajectory correlation", "Lateral and vertical deviation alerts", "Controller resolution workflow"]
    }
}