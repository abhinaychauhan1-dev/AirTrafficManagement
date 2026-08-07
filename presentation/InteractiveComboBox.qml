import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ComboBox {
    id: control

    property color accentColor: "#6fffc1"
    property color panelColor: "#12201e"
    property color popupColor: "#091412"
    property color lineColor: "#293a37"
    property color textColor: "#d9e5e1"
    property color mutedTextColor: "#7f9690"

    implicitHeight: 38
    leftPadding: 12
    rightPadding: 40
    hoverEnabled: true
    font.family: "Consolas"
    font.pixelSize: 12
    font.bold: activeFocus || popup.visible

    contentItem: Text {
        text: control.displayText
        color: control.enabled ? control.textColor : "#53635f"
        font: control.font
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    indicator: Item {
        x: control.width - width - 7
        y: (control.height - height) / 2
        width: 28
        height: 26

        Rectangle {
            anchors.fill: parent
            radius: 3
            color: control.popup.visible ? control.accentColor : (control.hovered ? "#1b302b" : "#172522")
            border.color: control.popup.visible ? control.accentColor : control.lineColor
            Behavior on color { ColorAnimation { duration: 140 } }
            Behavior on border.color { ColorAnimation { duration: 140 } }
        }
        Text {
            anchors.centerIn: parent
            text: "▼"
            color: control.popup.visible ? "#07100f" : control.mutedTextColor
            font.family: "Consolas"
            font.pixelSize: 11
            rotation: control.popup.visible ? 180 : 0
            Behavior on rotation { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 140 } }
        }
    }

    background: Rectangle {
        radius: 4
        color: control.down ? "#1d342f" : (control.hovered || control.activeFocus ? "#172a26" : control.panelColor)
        border.width: control.activeFocus || control.popup.visible ? 2 : 1
        border.color: control.activeFocus || control.popup.visible
                      ? control.accentColor
                      : (control.hovered ? "#416158" : control.lineColor)
        Behavior on color { ColorAnimation { duration: 140 } }
        Behavior on border.color { ColorAnimation { duration: 140 } }
    }

    delegate: ItemDelegate {
        id: option
        required property int index

        width: control.popup.width - control.popup.leftPadding - control.popup.rightPadding
        height: 40
        highlighted: control.highlightedIndex === index
        hoverEnabled: true

        contentItem: RowLayout {
            spacing: 9
            Rectangle {
                Layout.preferredWidth: 3
                Layout.preferredHeight: 20
                radius: 1
                color: option.index === control.currentIndex || option.highlighted
                       ? control.accentColor : "transparent"
            }
            Text {
                Layout.fillWidth: true
                text: control.textAt(option.index)
                color: option.index === control.currentIndex
                       ? control.accentColor
                       : (option.highlighted ? control.textColor : control.mutedTextColor)
                font.family: control.font.family
                font.pixelSize: control.font.pixelSize
                font.bold: option.index === control.currentIndex
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }
            Text {
                text: "✓"
                visible: option.index === control.currentIndex
                color: control.accentColor
                font.pixelSize: 13
                font.bold: true
            }
        }

        background: Rectangle {
            radius: 3
            color: option.highlighted ? "#17352d" : (option.hovered ? "#132522" : "transparent")
            Behavior on color { ColorAnimation { duration: 100 } }
        }
    }

    popup: Popup {
        y: control.height + 5
        width: control.width
        implicitHeight: Math.min(contentItem.implicitHeight + topPadding + bottomPadding, 260)
        padding: 6
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: control.popup.visible ? control.delegateModel : null
            currentIndex: control.highlightedIndex
            boundsBehavior: Flickable.StopAtBounds
            ScrollIndicator.vertical: ScrollIndicator { }
        }

        background: Rectangle {
            color: control.popupColor
            border.color: control.accentColor
            radius: 4
        }

        enter: Transition {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 140 }
        }
        exit: Transition {
            NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 100 }
        }
    }
}