import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    required property string featureNumber
    required property string title
    required property string summary
    required property var capabilities

    Rectangle {
        anchors.fill: parent
        color: "#0c1716"
        border.color: "#293a37"
        radius: 4

        ColumnLayout {
            width: Math.min(parent.width - 48, 720)
            anchors.centerIn: parent
            spacing: 18

            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                Rectangle {
                    width: 42; height: 42; radius: 4; color: "#172724"; border.color: "#49645e"
                    Text { anchors.centerIn: parent; text: root.featureNumber; color: "#73d9ff"; font.family: "Consolas"; font.pixelSize: 16; font.bold: true }
                }
                Column {
                    Layout.fillWidth: true
                    Text { text: root.title; color: "#d9e5e1"; font.family: "Consolas"; font.pixelSize: 18; font.bold: true }
                    Text { text: "PLANNED MODULE / INTERFACE PLACEHOLDER"; color: "#ffb443"; font.family: "Consolas"; font.pixelSize: 9 }
                }
            }
            Text { Layout.fillWidth: true; text: root.summary; color: "#8ea19c"; font.pixelSize: 12; wrapMode: Text.WordWrap; lineHeight: 1.35 }
            Rectangle { Layout.fillWidth: true; height: 1; color: "#293a37" }
            Repeater {
                model: root.capabilities
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    Rectangle { width: 7; height: 7; radius: 4; color: "#49645e" }
                    Text { Layout.fillWidth: true; text: modelData; color: "#d9e5e1"; font.family: "Consolas"; font.pixelSize: 11 }
                    Text { text: "NOT IMPLEMENTED"; color: "#687b76"; font.family: "Consolas"; font.pixelSize: 8 }
                }
            }
        }
    }
}