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
    property bool loading: false
    property int version: 0

    signal dataLoaded()

    function transformSearch(search: string): string {
        const prefix = GlobalConfig.launcher.emojiPrefix;
        return search.startsWith(prefix) ? search.slice(prefix.length) : search;
    }

    function ensureLoaded(): void {
        if (!loaded && !loading) {
            loading = true;
            getEmojis.running = true;
        }
    }

    function pasteEmoji(glyph: string): void {
        if (!glyph)
            return;

        const luaArg = Hypr.usingLua ? "1" : "0";
        Quickshell.execDetached(["sh", "-c", `
            # Set emoji to clipboard with --sensitive so cliphist completely ignores it
            wl-copy --sensitive --type text/plain -- '${glyph}'

            # Check if active window is a terminal
            win_info=$(hyprctl activewindow -j 2>/dev/null)
            is_term=0
            if echo "$win_info" | grep -qiE '"class":\\s*"(foot|kitty|alacritty|wezterm|xterm|ghostty|konsole|termite|urxvt|st|gnome-terminal)"' || echo "$win_info" | grep -qi '"terminal'; then
                is_term=1
            fi

            # Dispatch paste shortcut
            if [ "$is_term" = "1" ]; then
                if [ "${luaArg}" = "1" ]; then
                    hyprctl dispatch 'hl.dsp.send_shortcut({ mods = "CTRL SHIFT", key = "V", window = "activewindow" })'
                else
                    hyprctl dispatch sendshortcut "CTRL SHIFT,V,activewindow"
                fi
            else
                if [ "${luaArg}" = "1" ]; then
                    hyprctl dispatch 'hl.dsp.send_shortcut({ mods = "CTRL", key = "V", window = "activewindow" })'
                else
                    hyprctl dispatch sendshortcut "CTRL,V,activewindow"
                fi
            fi

            # Wait for active window to finish reading clipboard
            sleep 0.1

            # Restore previous clipboard directly from cliphist using --sensitive
            # so cliphist does not record a duplicate entry
            last_item=$(cliphist list 2>/dev/null | head -n 1)
            if [ -n "$last_item" ]; then
                printf "%s\\n" "$last_item" | cliphist decode | wl-copy --sensitive
            else
                wl-copy --clear 2>/dev/null || true
            fi
        `]);
    }

    function query(search: string): var {
        ensureLoaded();

        const _v = version;
        search = transformSearch(search.trim().replace(/\s+/g, " "));

        if (!loaded)
            return [];

        if (!search)
            return allItems.slice(0, 36);

        if (GlobalConfig.launcher.useFuzzy.emoji) {
            const fuzzyResults = Fuzzy.go(search, allItems, {
                keys: ["name", "tags"],
                scoreFn: r => 0.7 * (r[0]?.score ?? 0) + 0.3 * (r[1]?.score ?? 0),
                limit: 36
            });
            return fuzzyResults.map(r => r.obj);
        }

        const searchLower = search.toLowerCase();
        const terms = searchLower.split(" ").filter(t => t.length > 0);
        if (terms.length === 0)
            return allItems.slice(0, 36);

        const exactEmoticon = [];
        const exactName = [];
        const nameStartsWith = [];
        const nameWordStartsWith = [];
        const tagsWordStartsWith = [];
        const substring = [];

        const emoticonCandidates = [searchLower, `:${searchLower}`, `>${searchLower}`];

        const items = allItems;
        const len = items.length;
        const firstTerm = terms[0];
        const rootWord = firstTerm.endsWith("e") ? firstTerm.slice(0, -1) : firstTerm;

        for (let i = 0; i < len; i++) {
            const item = items[i];
            const allText = item.searchKeyLower;
            let matched = true;

            // Check emoticon match (e.g. :> for 😊)
            const emots = item.emoticons || [];
            let isEmoticonMatch = false;
            for (let e = 0; e < emots.length; e++) {
                if (emoticonCandidates.indexOf(emots[e]) !== -1) {
                    isEmoticonMatch = true;
                    break;
                }
            }

            if (isEmoticonMatch) {
                exactEmoticon.push(item);
                continue;
            }

            for (let t = 0; t < terms.length; t++) {
                if (allText.indexOf(terms[t]) === -1) {
                    matched = false;
                    break;
                }
            }

            if (!matched)
                continue;

            const nameLower = item.nameLower;
            const labelLower = item.labelLower;

            if (nameLower === searchLower || labelLower === searchLower) {
                exactName.push(item);
            } else if (nameLower.startsWith(firstTerm) || (rootWord.length >= 3 && nameLower.startsWith(rootWord))) {
                nameStartsWith.push(item);
            } else if (nameLower.indexOf(` ${firstTerm}`) !== -1 || (rootWord.length >= 3 && nameLower.indexOf(` ${rootWord}`) !== -1)) {
                nameWordStartsWith.push(item);
            } else if (item.tagsLower.startsWith(firstTerm) || item.tagsLower.indexOf(` ${firstTerm}`) !== -1 || (rootWord.length >= 3 && item.tagsLower.indexOf(` ${rootWord}`) !== -1)) {
                tagsWordStartsWith.push(item);
            } else {
                substring.push(item);
            }

            if (exactEmoticon.length + exactName.length + nameStartsWith.length + nameWordStartsWith.length + tagsWordStartsWith.length + substring.length >= 36)
                break;
        }

        const results = exactEmoticon.concat(exactName, nameStartsWith, nameWordStartsWith, tagsWordStartsWith, substring);
        return results.slice(0, 36);
    }

    Process {
        id: getEmojis

        running: false
        command: ["caelestia", "emoji"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.loading = false;
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
                    if (!line)
                        continue;
                    const spaceIdx = line.indexOf(" ");
                    let glyph = line;
                    let rest = "";
                    if (spaceIdx !== -1) {
                        glyph = line.slice(0, spaceIdx);
                        rest = line.slice(spaceIdx + 1).trim();
                    }
                    const tokens = rest.split(/\s+/);
                    const emoticons = [];
                    const labelWords = [];

                    for (let j = 0; j < tokens.length; j++) {
                        const t = tokens[j];
                        if (/^[:;><=()\/|xX8oO\-]/.test(t) && t.length <= 5 && !/^[a-zA-Z]{2,}$/.test(t))
                            emoticons.push(t.toLowerCase());
                        else
                            labelWords.push(t);
                    }

                    const name = labelWords.slice(0, Math.min(labelWords.length, 5)).join(" ") || rest;
                    const label = labelWords.join(" ");

                    items.push({
                        glyph: glyph,
                        name: name,
                        tags: rest,
                        emoticons: emoticons,
                        searchKey: `${glyph} ${rest}`,
                        nameLower: name.toLowerCase(),
                        labelLower: label.toLowerCase(),
                        tagsLower: rest.toLowerCase(),
                        searchKeyLower: `${glyph} ${rest}`.toLowerCase()
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
