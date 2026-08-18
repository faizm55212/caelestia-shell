pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.launcher.services

Item {
    id: root

    required property SearchBar search
    required property ScreenState screenState
    required property real maxHeight

    readonly property string queryText: search.text
    property var currentEmoji: null

    readonly property int targetColumns: 9
    readonly property int gridPadding: Tokens.padding.small
    readonly property int columns: Math.max(1, Math.min(targetColumns, Math.floor((width - gridPadding * 2) / (Tokens.sizes.launcher.emojiCellSize || 62))))
    readonly property real cellWidth: Math.floor((width - gridPadding * 2) / columns)
    readonly property real cellHeight: cellWidth
    readonly property int maxVisibleRows: 3

    function moveLeft(): void {
        if (gridView.currentIndex > 0)
            gridView.currentIndex--;
    }

    function moveRight(): void {
        if (gridView.currentIndex < gridView.count - 1)
            gridView.currentIndex++;
    }

    function moveUp(): void {
        if (gridView.currentIndex >= columns)
            gridView.currentIndex -= columns;
    }

    function moveDown(): void {
        if (gridView.currentIndex + columns < gridView.count)
            gridView.currentIndex += columns;
    }

    function decrementCurrentIndex(): void {
        moveUp();
    }

    function incrementCurrentIndex(): void {
        moveDown();
    }

    function acceptCurrent(): void {
        if (currentEmoji?.glyph) {
            Emoji.pasteEmoji(currentEmoji.glyph);
            screenState.launcher = false;
        }
    }

    readonly property int count: scriptModel.values.length
    readonly property alias currentItem: gridView.currentItem

    implicitWidth: Tokens.sizes.launcher.itemWidth
    implicitHeight: Math.min(root.maxHeight, gridViewWrapper.implicitHeight + previewBar.implicitHeight + Tokens.spacing.small)

    Item {
        id: gridViewWrapper

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: previewBar.top
        anchors.bottomMargin: Tokens.spacing.small

        implicitHeight: Math.min(root.maxHeight - previewBar.implicitHeight - Tokens.spacing.small, Math.max(1, Math.ceil(Math.min(scriptModel.values.length, root.columns * root.maxVisibleRows) / root.columns)) * root.cellHeight + root.gridPadding * 2)

        GridView {
            id: gridView

            anchors.fill: parent
            anchors.margins: root.gridPadding

            clip: true
            cellWidth: root.cellWidth
            cellHeight: root.cellHeight

            focus: false
            interactive: true

            model: ScriptModel {
                id: scriptModel

                values: Emoji.query(root.queryText)
                onValuesChanged: {
                    gridView.currentIndex = 0;
                    if (values.length > 0)
                        root.currentEmoji = values[0];
                    else
                        root.currentEmoji = null;
                }
            }

            onCurrentIndexChanged: {
                if (currentIndex >= 0 && currentIndex < scriptModel.values.length) {
                    root.currentEmoji = scriptModel.values[currentIndex];
                    positionViewAtIndex(currentIndex, GridView.Contain);
                }
            }

            delegate: Item {
                id: delegateRoot

                required property var modelData
                required property int index

                width: gridView.cellWidth
                height: gridView.cellHeight

                readonly property bool isCurrent: gridView.currentIndex === index

                StyledRect {
                    anchors.fill: parent
                    anchors.margins: 2
                    radius: Tokens.rounding.medium
                    color: delegateRoot.isCurrent ? Colours.palette.m3onSurface : Colours.palette.m3surfaceContainerHigh
                    opacity: delegateRoot.isCurrent ? 0.14 : (stateLayer.containsMouse ? 0.08 : 0)

                    Behavior on opacity {
                        Anim {
                            duration: Tokens.anim.durations.small
                        }
                    }
                }

                StyledText {
                    anchors.centerIn: parent
                    text: delegateRoot.modelData?.glyph ?? ""
                    font.pixelSize: Math.round(delegateRoot.height * 0.56)
                    font.family: "Noto Color Emoji, Apple Color Emoji, Segoe UI Emoji, sans-serif"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                StateLayer {
                    id: stateLayer

                    radius: Tokens.rounding.medium
                    onClicked: {
                        gridView.currentIndex = delegateRoot.index;
                        root.currentEmoji = delegateRoot.modelData;
                        Emoji.pasteEmoji(delegateRoot.modelData.glyph);
                        root.screenState.launcher = false;
                    }
                    onHoveredChanged: {
                        if (containsMouse) {
                            gridView.currentIndex = delegateRoot.index;
                            root.currentEmoji = delegateRoot.modelData;
                        }
                    }
                }
            }

            StyledScrollBar.vertical: StyledScrollBar {
                flickable: gridView
            }
        }
    }

    // Bottom Preview Bar
    StyledRect {
        id: previewBar

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        implicitHeight: Tokens.sizes.launcher.itemHeight * 0.8
        radius: Tokens.rounding.large
        color: Colours.palette.m3surfaceContainer
        opacity: root.currentEmoji ? 1 : 0

        Behavior on opacity {
            Anim {
                duration: Tokens.anim.durations.small
            }
        }

        Row {
            anchors.fill: parent
            anchors.margins: Tokens.padding.small
            anchors.leftMargin: Tokens.padding.medium
            anchors.rightMargin: Tokens.padding.medium
            spacing: Tokens.spacing.medium

            StyledText {
                text: root.currentEmoji?.glyph ?? ""
                font.pixelSize: Math.round(parent.height * 0.6)
                anchors.verticalCenter: parent.verticalCenter
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 150
                spacing: 0

                StyledText {
                    text: root.currentEmoji?.name ?? ""
                    font: Tokens.font.body.medium
                    elide: Text.ElideRight
                    width: parent.width
                }

                StyledText {
                    text: root.currentEmoji?.tags ?? ""
                    font: Tokens.font.body.small
                    color: Colours.palette.m3outline
                    elide: Text.ElideRight
                    width: parent.width
                }
            }
        }

        StyledText {
            anchors.right: parent.right
            anchors.rightMargin: Tokens.padding.medium
            anchors.verticalCenter: parent.verticalCenter
            text: qsTr("↵ to paste")
            font: Tokens.font.label.small
            color: Colours.palette.m3outline
        }
    }
}
