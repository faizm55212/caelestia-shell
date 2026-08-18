pragma Singleton

import QtQuick
import Quickshell
import Caelestia
import Caelestia.Config

Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string pictures: Quickshell.env("XDG_PICTURES_DIR") || `${home}/Pictures`
    readonly property string videos: Quickshell.env("XDG_VIDEOS_DIR") || `${home}/Videos`

    readonly property string data: `${Quickshell.env("XDG_DATA_HOME") || `${home}/.local/share`}/caelestia`
    readonly property string state: `${Quickshell.env("XDG_STATE_HOME") || `${home}/.local/state`}/caelestia`
    readonly property string cache: `${Quickshell.env("XDG_CACHE_HOME") || `${home}/.cache`}/caelestia`
    readonly property string config: `${Quickshell.env("XDG_CONFIG_HOME") || `${home}/.config`}/caelestia`

    readonly property string imagecache: `${cache}/imagecache`
    readonly property string notifimagecache: `${imagecache}/notifs`
    readonly property string wallsdir: Quickshell.env("CAELESTIA_WALLPAPERS_DIR") || absolutePath(GlobalConfig.paths.wallpaperDir)
    readonly property string recsdir: Quickshell.env("CAELESTIA_RECORDINGS_DIR") || `${videos}/Recordings`
    readonly property string libdir: Quickshell.env("CAELESTIA_LIB_DIR") || "/usr/lib/caelestia"

    readonly property string weWorkshopDir: {
        const configured = GlobalConfig.background?.wallpaperEngine?.workshop;
        if (configured)
            return absolutePath(configured);

        const xdgData = Quickshell.env("XDG_DATA_HOME");
        const candidates = [
            ...(xdgData ? [`${xdgData}/Steam/steamapps/workshop/content/431960`] : []),
            `${home}/.steam/steam/steamapps/workshop/content/431960`,
            `${home}/.local/share/Steam/steamapps/workshop/content/431960`,
            `${home}/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/workshop/content/431960`,
        ];
        for (const c of candidates) {
            if (CUtils.dirExists(c))
                return c;
        }
        return `${home}/.local/share/Steam/steamapps/workshop/content/431960`;
    }

    readonly property string weAssetsDir: {
        const configured = GlobalConfig.background?.wallpaperEngine?.assets;
        if (configured)
            return absolutePath(configured);

        const xdgData = Quickshell.env("XDG_DATA_HOME");
        const candidates = [
            ...(xdgData ? [`${xdgData}/Steam/steamapps/common/wallpaper_engine/assets`] : []),
            `${home}/.steam/steam/steamapps/common/wallpaper_engine/assets`,
            `${home}/.local/share/Steam/steamapps/common/wallpaper_engine/assets`,
            `${home}/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/common/wallpaper_engine/assets`,
        ];
        for (const c of candidates) {
            if (CUtils.dirExists(c))
                return c;
        }
        return `${home}/.local/share/Steam/steamapps/common/wallpaper_engine/assets`;
    }

    function toLocalFile(path: url): string {
        path = Qt.resolvedUrl(path);
        return path.toString() ? CUtils.toLocalFile(path) : "";
    }

    function absolutePath(path: string): string {
        if (!path)
            return "";
        let expanded = path.replace(/~|(\$({?)HOME(}?))+/, home);
        if (expanded.startsWith("/"))
            return expanded;
        return toLocalFile(expanded);
    }

    function shortenHome(path: string): string {
        return path.replace(home, "~");
    }
}
