pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root

    property bool sectorBoundariesEnabled: true
    property bool approachCorridorsEnabled: true
    property bool geofencesEnabled: true

    signal sectorBoundariesToggled()
    signal approachCorridorsToggled()
    signal geofencesToggled()

    implicitWidth: 240
    implicitHeight: 148
    color: "#e60a1513"
    border.color: "#416158"
    radius: 4

    component LayerToggle: CheckBox {
        id: control
        required property color layerColor
        implicitHeight: 32
        font.family: "Consolas"
        font.pixelSize: 12
        spacing: 8
        indicator: Rectangle {
            implicitWidth: 28
            implicitHeight: 14
            y: (control.height - height) / 2
            radius: 7
            color: control.checked ? control.layerColor : "#17231f"
            border.color: control.checked ? control.layerColor : "#465650"
            Rectangle {
                x: control.checked ? parent.width - width - 2 : 2
                anchors.verticalCenter: parent.verticalCenter
                width: 10
                height: 10
                radius: 5
                color: control.checked ? "#07100f" : "#82918d"
                Behavior on x { NumberAnimation { duration: 100 } }
            }
        }
        contentItem: Text {
            leftPadding: control.indicator.width + control.spacing
            text: control.text
            color: control.checked ? "#d9e5e1" : "#7f9690"
            font: control.font
            verticalAlignment: Text.AlignVCenter
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 2

        RowLayout {
            Layout.fillWidth: true
            Text { text: "AIRSPACE MANAGER"; color: "#d9e5e1"; font.family: "Consolas"; font.pixelSize: 13; font.bold: true }
            Item { Layout.fillWidth: true }
            Text { text: "LAYERS"; color: "#7f9690"; font.family: "Consolas"; font.pixelSize: 11 }
        }
        Rectangle { Layout.fillWidth: true; height: 1; color: "#293a37" }
        LayerToggle {
            Layout.fillWidth: true
            text: "SECTOR BOUNDARIES"
            layerColor: "#6fffc1"
            checked: root.sectorBoundariesEnabled
            onToggled: root.sectorBoundariesToggled()
        }
        LayerToggle {
            Layout.fillWidth: true
            text: "VERTIPORT CORRIDORS"
            layerColor: "#73d9ff"
            checked: root.approachCorridorsEnabled
            onToggled: root.approachCorridorsToggled()
        }
        LayerToggle {
            Layout.fillWidth: true
            text: "GEOFENCES"
            layerColor: "#ff746c"
            checked: root.geofencesEnabled
            onToggled: root.geofencesToggled()
        }
    }
}