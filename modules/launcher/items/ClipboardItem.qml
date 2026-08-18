import QtQuick
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.launcher.services

Item {
    id: root

    required property var modelData
    required property var list

    implicitHeight: Tokens.sizes.launcher.itemHeight

    anchors.left: parent?.left
    anchors.right: parent?.right

    StateLayer {
        radius: Tokens.rounding.large
        onClicked: {
            root.list.screenState.launcher = false;
            Clipboard.selectItem(root.modelData);
        }
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: Tokens.padding.medium
        anchors.rightMargin: Tokens.padding.medium
        anchors.margins: Tokens.padding.small

        MaterialIcon {
            id: icon

            anchors.verticalCenter: parent.verticalCenter
            text: root.modelData?.isBinary ? "image" : "content_paste"
            color: Colours.palette.m3onSurfaceVariant
            fontStyle: Tokens.font.icon.builders.large.scale(1.1).build()
        }

        Item {
            anchors.left: icon.right
            anchors.leftMargin: Tokens.spacing.medium
            anchors.right: deleteBtn.left
            anchors.rightMargin: Tokens.spacing.small
            anchors.verticalCenter: icon.verticalCenter

            implicitHeight: name.implicitHeight + desc.implicitHeight

            StyledText {
                id: name

                text: root.modelData?.preview ?? ""
                font: Tokens.font.body.medium
                elide: Text.ElideRight
                width: parent.width
            }

            StyledText {
                id: desc

                text: root.modelData?.isBinary ? qsTr("Image / Binary data") : qsTr("Item #%1 • %2 chars").arg(root.modelData?.id ?? "").arg((root.modelData?.preview ?? "").length)
                font: Tokens.font.body.small
                color: Colours.palette.m3outline

                elide: Text.ElideRight
                width: parent.width

                anchors.top: name.bottom
            }
        }

        IconButton {
            id: deleteBtn

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter

            icon: "delete_outline"
            type: IconButton.Text
            radius: Tokens.rounding.full
            radiusMorph: false
            stateLayer.hoverEnabled: true
            onClicked: Clipboard.deleteItem(root.modelData)
        }
    }
}
