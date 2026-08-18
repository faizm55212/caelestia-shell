pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.utils

Item {
    id: root

    required property var content
    required property ScreenState screenState
    required property var panels
    required property real maxHeight
    required property SearchBar search
    required property int padding
    required property int rounding

    readonly property bool showWallpapers: search.text.startsWith(`${GlobalConfig.launcher.actionPrefix}wallpaper `)
    readonly property bool showEmojis: search.text.startsWith(GlobalConfig.launcher.emojiPrefix)
    readonly property var currentList: showWallpapers ? wallpaperList.item : (showEmojis ? emojiList.item : appList.item) // Can be either ListView, GridView or PathView, so can't type properly
    property string animState: showWallpapers ? "wallpapers" : (showEmojis ? "emojis" : "apps")

    function moveUp(): void {
        if (showEmojis && currentList?.moveUp)
            currentList.moveUp();
        else
            currentList?.decrementCurrentIndex();
    }

    function moveDown(): void {
        if (showEmojis && currentList?.moveDown)
            currentList.moveDown();
        else
            currentList?.incrementCurrentIndex();
    }

    function moveLeft(): void {
        if (showEmojis && currentList?.moveLeft)
            currentList.moveLeft();
        else
            currentList?.decrementCurrentIndex();
    }

    function moveRight(): void {
        if (showEmojis && currentList?.moveRight)
            currentList.moveRight();
        else
            currentList?.incrementCurrentIndex();
    }

    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom

    clip: true
    state: animState

    states: [
        State {
            name: "apps"

            PropertyChanges {
                root.implicitWidth: root.Tokens.sizes.launcher.itemWidth
                root.implicitHeight: Math.min(root.maxHeight, appList.implicitHeight > 0 ? appList.implicitHeight : empty.implicitHeight)
                appList.active: true
            }

            AnchorChanges {
                anchors.left: root.parent.left
                anchors.right: root.parent.right
            }
        },
        State {
            name: "wallpapers"

            PropertyChanges {
                root.implicitWidth: Math.max(root.Tokens.sizes.launcher.itemWidth * 1.2, wallpaperList.implicitWidth)
                root.implicitHeight: root.Tokens.sizes.launcher.wallpaperHeight
                wallpaperList.active: true
            }
        },
        State {
            name: "emojis"

            PropertyChanges {
                root.implicitWidth: root.Tokens.sizes.launcher.itemWidth
                root.implicitHeight: Math.min(root.maxHeight, emojiList.implicitHeight > 0 ? emojiList.implicitHeight : empty.implicitHeight)
                emojiList.active: true
            }

            AnchorChanges {
                anchors.left: root.parent.left
                anchors.right: root.parent.right
            }
        }
    ]

    Behavior on animState {
        SequentialAnimation {
            Anim {
                target: root
                property: "opacity"
                from: 1
                to: 0
                type: Anim.DefaultEffects
            }
            PropertyAction {}
            Anim {
                target: root
                property: "opacity"
                from: 0
                to: 1
                type: Anim.DefaultEffects
            }
        }
    }

    Loader {
        id: appList

        active: false

        anchors.fill: parent

        sourceComponent: AppList {
            objectName: "launcherAppList"

            search: root.search
            screenState: root.screenState
        }
    }

    Loader {
        id: wallpaperList

        asynchronous: true
        active: false

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter

        sourceComponent: WallpaperList {
            objectName: "launcherWallpaperList"

            search: root.search
            screenState: root.screenState
            panels: root.panels
            content: root.content
        }
    }

    Loader {
        id: emojiList

        active: false

        anchors.fill: parent

        sourceComponent: EmojiList {
            objectName: "launcherEmojiList"

            search: root.search
            screenState: root.screenState
            maxHeight: root.maxHeight
        }
    }

    Row {
        id: empty

        opacity: root.currentList?.count === 0 ? 1 : 0
        scale: root.currentList?.count === 0 ? 1 : 0.5

        spacing: Tokens.spacing.medium
        padding: Tokens.padding.large

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter

        MaterialIcon {
            text: root.state === "wallpapers" ? "wallpaper_slideshow" : (root.state === "emojis" ? "sentiment_satisfied" : (root.search.text.startsWith(GlobalConfig.launcher.clipboardPrefix) ? "content_paste_off" : "manage_search"))
            color: Colours.palette.m3onSurfaceVariant
            fontStyle: Tokens.font.icon.extraLarge

            anchors.verticalCenter: parent.verticalCenter
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter

            StyledText {
                text: {
                    if (root.state === "wallpapers")
                        return qsTr("No wallpapers found");
                    if (root.state === "emojis")
                        return qsTr("No emojis found");
                    if (root.search.text.startsWith(GlobalConfig.launcher.clipboardPrefix))
                        return qsTr("Clipboard history is empty");
                    return qsTr("No results");
                }
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.builders.large.weight(Font.Medium).build()
            }

            StyledText {
                text: {
                    if (root.state === "wallpapers" && Wallpapers.list.length === 0)
                        return qsTr("Try putting some wallpapers in %1").arg(Paths.shortenHome(Paths.wallsdir));
                    return qsTr("Try searching for something else");
                }
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.medium
            }
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        Behavior on scale {
            Anim {}
        }
    }

    Behavior on implicitWidth {
        enabled: root.screenState.launcher

        Anim {}
    }

    Behavior on implicitHeight {
        enabled: root.screenState.launcher

        Anim {}
    }
}
