pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io
import qs.modules.common
import qs.modules.common.functions

Item {
    id: root
    visible: false

    property bool active: false
    property string title: ""
    property string artist: ""
    property real duration: 0

    readonly property string queryTitle: normalizeTitle(root.title)
    readonly property string queryArtist: normalizeArtist(root.artist)
    readonly property int queryDuration: Math.round(root.duration ?? 0)
    readonly property string queryKey: `${root.queryTitle}||${root.queryArtist}||${root.queryDuration}`

    property bool loading: false
    property string error: ""
    property bool instrumental: false
    property var lines: []

    property var cache: ({})
    property string loadedKey: ""
    property string requestKey: ""
    property int requestId: 0
    property int attempt: 0
    property bool startPending: false

    function normalizeTitle(rawTitle) {
        if (!rawTitle) return "";

        let cleaned = StringUtils.cleanMusicTitle(rawTitle);
        const parts = cleaned.split(" - ");
        const main = parts[0].trim();
        const suffix = parts.slice(1).join(" - ").trim();

        if (suffix && /\b(remix|version|edit|mix|rework)\b/i.test(suffix)) {
            cleaned = `${main} ${suffix}`;
        } else {
            cleaned = main;
        }

        cleaned = cleaned.replace(/\s*[\(\[\{]([^\)\]\}]*)[\)\]\}]\s*/g, function(_, inner) {
            if (/(?:feat\.?|ft\.?|featuring)/i.test(inner)) {
                const featured = inner.replace(/^(?:feat\.?|ft\.?|featuring)\s*/i, "").trim();
                return featured ? ` feat. ${featured} ` : " ";
            }
            return " ";
        }).replace(/\s+/g, " ").trim();

        return cleaned;
    }

    function normalizeArtist(rawArtist) {
        if (!rawArtist) return "";

        let cleaned = String(rawArtist).trim();
        cleaned = cleaned.split(",")[0];
        cleaned = cleaned.split(/ feat\.? /i)[0];
        cleaned = cleaned.split(/ ft\.? /i)[0];
        cleaned = cleaned.split(/ featuring /i)[0];
        cleaned = cleaned.split(/ & /)[0];
        cleaned = cleaned.split(/ x /i)[0];
        return cleaned.trim();
    }

    function parseSyncedLyrics(lrcText) {
        if (!lrcText) return [];

        const parsed = [];
        const rawLines = lrcText.split(/\r?\n/);
        const timeTag = /\[(\d{1,2}):(\d{2})(?:\.(\d{1,3}))?\]/g;

        for (const rawLine of rawLines) {
            if (!rawLine) continue;

            timeTag.lastIndex = 0;
            const times = [];
            let match;
            while ((match = timeTag.exec(rawLine)) !== null) {
                const minutes = parseInt(match[1], 10);
                const seconds = parseInt(match[2], 10);
                const fraction = match[3];
                let millis = 0;

                if (fraction !== undefined) {
                    if (fraction.length === 1) {
                        millis = parseInt(fraction, 10) * 100;
                    } else if (fraction.length === 2) {
                        millis = parseInt(fraction, 10) * 10;
                    } else {
                        millis = parseInt(fraction.padEnd(3, "0"), 10);
                    }
                }

                times.push(minutes * 60 + seconds + millis / 1000);
            }

            if (times.length === 0) continue;

            const text = rawLine.replace(timeTag, "").trim();
            for (const time of times) {
                parsed.push({ time: time, text: text });
            }
        }

        parsed.sort((a, b) => a.time - b.time);
        return parsed;
    }

    function cacheEntry(key) {
        return root.cache[key] || null;
    }

    function writeCache(key, data) {
        root.cache[key] = data;
        lyricsCacheFile.setText(JSON.stringify(root.cache, null, 2));
    }

    function buildLyricsSearchUrl(attempt) {
        const baseSearch = "https://lrclib.net/api/search";
        const baseGet = "https://lrclib.net/api/get";
        const title = root.queryTitle;
        const artist = root.queryArtist;
        const duration = root.queryDuration;

        if (!title || !artist) return "";

        if (attempt === 0) {
            let url = `${baseGet}?track_name=${encodeURIComponent(title)}&artist_name=${encodeURIComponent(artist)}`;
            if (duration > 0) url += `&duration=${duration}`;
            return url;
        }

        if (attempt === 1) {
            let url = `${baseSearch}?track_name=${encodeURIComponent(title)}&artist_name=${encodeURIComponent(artist)}`;
            if (duration > 0) url += `&duration=${duration}`;
            return url;
        }

        if (attempt === 2) {
            return `${baseSearch}?q=${encodeURIComponent(`${title} ${artist}`)}`;
        }

        if (attempt === 3) {
            return `${baseSearch}?q=${encodeURIComponent(title)}`;
        }

        return "";
    }

    function pickBestLyricsResult(results) {
        if (!Array.isArray(results) || results.length === 0) return null;

        const titleLower = root.queryTitle.toLowerCase();
        const artistLower = root.queryArtist.toLowerCase();
        const duration = root.queryDuration;
        let best = null;
        let bestScore = -Infinity;

        for (const item of results) {
            const syncedLyrics = item?.syncedLyrics ?? "";
            if (!syncedLyrics || syncedLyrics.length === 0) continue;

            let score = 0;
            const itemTitle = (item?.trackName ?? item?.name ?? "").toLowerCase();
            const itemArtist = (item?.artistName ?? "").toLowerCase();

            if (itemArtist && itemArtist === artistLower) score += 100;
            if (itemTitle && itemTitle === titleLower) score += 50;

            if (duration > 0 && typeof item?.duration === "number") {
                const diff = Math.abs(item.duration - duration);
                if (diff <= 2) {
                    score += 25;
                } else if (diff <= 5) {
                    score += 10;
                } else {
                    score -= Math.min(diff, 30);
                }
            }

            if (item?.instrumental) score -= 1000;
            if (syncedLyrics.length < 32) score -= 60;
            score += Math.min(syncedLyrics.length, 4000) / 20;

            if (score > bestScore) {
                bestScore = score;
                best = item;
            }
        }

        return best;
    }

    function resetState() {
        root.loading = false;
        root.error = "";
        root.instrumental = false;
        root.lines = [];
        root.loadedKey = "";
        root.requestKey = "";
        root.attempt = 0;
        root.startPending = false;
        fetchTimeout.stop();
    }

    function finishNoLyrics() {
        fetchTimeout.stop();
        root.loading = false;
        root.error = "No synced lyrics";
        root.requestKey = "";
        root.startPending = false;
    }

    function tryNextAttempt(requestId) {
        if (requestId !== root.requestId || root.requestKey !== root.queryKey) return;

        root.attempt += 1;
        root.fetchAttempt(requestId);
    }

    function ensureFetched() {
        if (!root.active) {
            root.resetState();
            return;
        }

        if (!root.queryTitle || !root.queryArtist) {
            root.resetState();
            root.error = "No track info";
            return;
        }

        if (root.loadedKey === root.queryKey) return;
        if (root.loading && root.requestKey === root.queryKey) return;
        if (fetcher.running && fetcher.requestKey === root.queryKey) return;

        const cached = root.cacheEntry(root.queryKey);
        if (cached) {
            root.loading = false;
            root.error = cached.error || "";
            root.instrumental = cached.instrumental || false;
            root.lines = cached.lines || [];
            root.loadedKey = root.queryKey;
            return;
        }

        root.requestId += 1;
        root.attempt = 0;
        root.requestKey = root.queryKey;
        root.loading = true;
        root.error = "";
        root.instrumental = false;
        root.lines = [];
        fetchTimeout.restart();

        if (fetcher.running) {
            root.startPending = true;
            return;
        }

        root.fetchAttempt(root.requestId);
    }

    function fetchAttempt(requestId) {
        if (requestId !== root.requestId || root.requestKey !== root.queryKey) return;

        const url = root.buildLyricsSearchUrl(root.attempt);
        if (!url) {
            root.finishNoLyrics();
            return;
        }

        fetcher.requestId = requestId;
        fetcher.requestKey = root.requestKey;
        fetcher.attempt = root.attempt;
        fetcher.command = ["curl", "-sL", "--max-time", "8", url];
        fetcher.running = true;
    }

    Timer {
        id: fetchDebounce
        interval: 250
        repeat: false
        onTriggered: root.ensureFetched()
    }

    Timer {
        id: fetchTimeout
        interval: 30000
        repeat: false
        onTriggered: {
            if (root.loading) {
                fetcher.running = false;
                root.finishNoLyrics();
            }
        }
    }

    FileView {
        id: lyricsCacheFile
        path: Directories.lyricsPath
        property bool loadedOnce: false

        onLoaded: {
            try {
                root.cache = JSON.parse(lyricsCacheFile.text() || "{}");
            } catch (e) {
                root.cache = {};
            }

            loadedOnce = true;
            fetchDebounce.restart();
        }

        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                lyricsCacheFile.setText("{}");
                root.cache = {};
            }

            loadedOnce = true;
            fetchDebounce.restart();
        }
    }

    Process {
        id: fetcher
        property int requestId: 0
        property string requestKey: ""
        property int attempt: 0
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const requestId = fetcher.requestId;
                const requestKey = fetcher.requestKey;

                if (requestId !== root.requestId || requestKey !== root.requestKey) {
                    if (root.startPending) {
                        root.startPending = false;
                        root.fetchAttempt(root.requestId);
                    }
                    return;
                }

                if (text.length === 0) {
                    root.tryNextAttempt(requestId);
                    return;
                }

                try {
                    const parsed = JSON.parse(text);
                    let results = [];

                    if (Array.isArray(parsed)) {
                        results = parsed;
                    } else if (parsed && typeof parsed === "object" && !parsed.code && !parsed.error) {
                        results = [parsed];
                    }

                    let filtered = results;
                    if (fetcher.attempt === 3 && root.queryArtist) {
                        const artistLower = root.queryArtist.toLowerCase();
                        filtered = results.filter(item => (item?.artistName ?? "").toLowerCase() === artistLower);
                    }

                    const best = root.pickBestLyricsResult(filtered);
                    if (!best) {
                        root.tryNextAttempt(requestId);
                        return;
                    }

                    const lines = root.parseSyncedLyrics(best.syncedLyrics ?? "");
                    if (lines.length === 0) {
                        root.tryNextAttempt(requestId);
                        return;
                    }

                    root.lines = lines;
                    root.loading = false;
                    root.error = "";
                    root.instrumental = best.instrumental ?? false;
                    root.loadedKey = requestKey;
                    root.requestKey = "";
                    root.startPending = false;
                    fetchTimeout.stop();
                    root.writeCache(root.queryKey, {
                        error: "",
                        instrumental: root.instrumental,
                        lines: lines
                    });
                } catch (e) {
                    root.tryNextAttempt(requestId);
                }
            }
        }
    }

    onActiveChanged: fetchDebounce.restart()
    onQueryKeyChanged: {
        root.resetState();
        fetchDebounce.restart();
    }

    Component.onCompleted: fetchDebounce.restart()
}
