pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config
import Caelestia.Models
import qs.services
import qs.utils

Searcher {
    id: root

    readonly property string currentNamePath: `${Paths.state}/wallpaper/path.txt`
    readonly property list<string> smartArg: GlobalConfig.services.smartScheme ? [] : ["--no-smart"]
    readonly property string fallback: Quickshell.shellPath("assets/wallpaper.webp")

    property bool showPreview: false
    readonly property string current: showPreview ? previewPath : actualCurrent
    readonly property string currentPreview: {
        if (showPreview)
            return previewPath;
        if (isWallpaperEngine) {
            const match = liveWallpapers.find(w => w.path === actualCurrent);
            if (match && match.preview)
                return match.preview;
            return `${Paths.state}/wallpaper/current`;
        }
        return actualCurrent;
    }
    property string previewPath
    property string actualCurrent
    property bool previewColourLock
    property bool pendingPreviewClear

    readonly property bool isWallpaperEngine: GlobalConfig.background?.wallpaperEngine?.enabled ?? false
    property list<QtObject> liveWallpapers: []

    function reloadLiveWallpapers(): void {
        liveWallpapers = CUtils.getWorkshopWallpapers(Paths.weWorkshopDir);
    }

    function initWallpaperEngine(): void {
        if (isWallpaperEngine) {
            reloadLiveWallpapers();
            Quickshell.execDetached(["caelestia", "wallpaper", "-R", ...smartArg]);
        }
    }

    onIsWallpaperEngineChanged: initWallpaperEngine()
    Component.onCompleted: initWallpaperEngine()

    Connections {
        target: Paths
        function onWeWorkshopDirChanged() {
            if (root.isWallpaperEngine)
                root.reloadLiveWallpapers();
        }
    }

    Connections {
        target: SessionManager
        function onResumed() {
            root.initWallpaperEngine();
        }
    }

    function previewFor(w: var): string {
        return w?.preview ?? w?.path ?? "";
    }

    function titleFor(w: var): string {
        return w?.title ?? w?.name ?? "";
    }
    function getCategoryFor(w: var): string {
        if (!w)
            return "";
        if (isWallpaperEngine)
            return "Live";
        let category = (w.parentDir ?? "").slice(Paths.wallsdir.length + 1);
        if (category.includes("/"))
            category = category.slice(0, category.indexOf("/"));
        return category;
    }

    function setRandom(): void {
        Quickshell.execDetached(["caelestia", "wallpaper", "-r", ...smartArg]);
    }

    function setWallpaper(path: string): void {
        actualCurrent = path;
        Quickshell.execDetached(["caelestia", "wallpaper", "-f", path, ...smartArg]);
    }

    function preview(path: string): void {
        previewPath = path;
        showPreview = true;

        if (Colours.scheme === "dynamic")
            getPreviewColoursProc.running = true;
    }

    function stopPreview(): void {
        showPreview = false;
        if (previewColourLock)
            pendingPreviewClear = true;
        else
            Colours.showPreview = false;
    }

    onPreviewColourLockChanged: {
        if (!previewColourLock && pendingPreviewClear)
            Colours.showPreview = false;
    }

    list: isWallpaperEngine ? liveWallpapers : wallpapers.entries
    key: "relativePath"
    useFuzzy: GlobalConfig.launcher.useFuzzy.wallpapers
    extraOpts: useFuzzy ? ({}) : ({
            forward: false
        })

    IpcHandler {
        function get(): string {
            return root.actualCurrent;
        }

        function set(path: string): void {
            root.setWallpaper(path);
        }

        function list(): string {
            return root.list.map(w => w.path).join("\n");
        }

        target: "wallpaper"
    }

    FileView {
        path: root.currentNamePath
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            let wall = text().trim();
            if (!wall) {
                wall = root.fallback;
                Quickshell.execDetached(["caelestia", "wallpaper", "-f", root.fallback, ...root.smartArg]);
            }
            root.actualCurrent = wall;
            root.previewColourLock = false;
        }
        onLoadFailed: {
            root.actualCurrent = root.fallback;
            root.previewColourLock = false;
            Quickshell.execDetached(["caelestia", "wallpaper", "-f", root.fallback, ...root.smartArg]);
        }
    }

    FileSystemModel {
        id: wallpapers

        recursive: true
        path: Paths.wallsdir
        filter: FileSystemModel.Images
    }

    FileSystemModel {
        id: workshopWatcher

        path: Paths.weWorkshopDir
        filter: FileSystemModel.Dirs
        onEntriesChanged: {
            if (root.isWallpaperEngine)
                root.reloadLiveWallpapers();
        }
    }

    Process {
        id: getPreviewColoursProc

        command: ["caelestia", "wallpaper", "-p", root.previewPath, ...root.smartArg]
        stdout: StdioCollector {
            onStreamFinished: {
                Colours.load(text, true);
                Colours.showPreview = true;
            }
        }
    }
}
