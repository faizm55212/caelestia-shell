pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import qs.services
import qs.utils
import "../../../utils/scripts/fuzzysort.js" as Fuzzy

Singleton {
    id: root

    property var allItems: []
    property bool loaded: false
    property int version: 0

    signal dataLoaded()

    function transformSearch(search: string): string {
        const prefix = GlobalConfig.launcher.clipboardPrefix;
        return search.startsWith(prefix) ? search.slice(prefix.length) : search;
    }

    function reload(): void {
        if (getCliphist.running)
            return;
        getCliphist.running = true;
    }

    function selectItem(item: var): void {
        if (!item?.id)
            return;
        Quickshell.execDetached(["sh", "-c", `printf "%s\t\n" "${item.id}" | cliphist decode | wl-copy`]);
    }

    function deleteItem(item: var): void {
        if (!item?.id)
            return;
        Quickshell.execDetached(["sh", "-c", `printf "%s\t\n" "${item.id}" | cliphist delete`]);
        allItems = allItems.filter(e => e.id !== item.id);
        version++;
        dataLoaded();
    }

    function wipeAll(): void {
        Quickshell.execDetached(["cliphist", "wipe"]);
        allItems = [];
        version++;
        dataLoaded();
    }

    function query(search: string): var {
        if (!loaded && !getCliphist.running)
            reload();

        const _v = version;
        search = transformSearch(search.trim());
        if (!search)
            return allItems.slice(0, 20);

        if (GlobalConfig.launcher.useFuzzy.clipboard) {
            const fuzzyResults = Fuzzy.go(search, allItems, { key: "preview", limit: 20 });
            return fuzzyResults.map(r => r.obj);
        }

        const s = search.toLowerCase();
        return allItems.filter(item => item.preview && item.preview.toLowerCase().includes(s)).slice(0, 20);
    }

    Process {
        id: getCliphist

        running: false
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text) {
                    root.allItems = [];
                    root.loaded = true;
                    root.version++;
                    root.dataLoaded();
                    return;
                }
                const lines = text.trim().split("\n");
                const items = [];
                for (let i = 0; i < lines.length; i++) {
                    const line = lines[i];
                    const tabIdx = line.indexOf("\t");
                    if (tabIdx === -1)
                        continue;
                    const id = line.slice(0, tabIdx);
                    const preview = line.slice(tabIdx + 1);
                    items.push({
                        id: id,
                        preview: preview,
                        isBinary: preview.startsWith("[[ binary data")
                    });
                }
                root.allItems = items;
                root.loaded = true;
                root.version++;
                root.dataLoaded();
            }
        }
    }
}
