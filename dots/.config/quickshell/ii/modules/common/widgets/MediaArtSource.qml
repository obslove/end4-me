pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.functions

Item {
    id: root

    property string artUrl: ""
    property string cacheDir: Directories.coverArt
    readonly property string source: root.currentSource
    property string currentSource: ""
    property bool ready: false

    function shellQuote(value) {
        return `'${StringUtils.shellSingleQuoteEscape(value)}'`
    }

    function refresh() {
        const url = root.artUrl ?? ""
        root.ready = false
        root.currentSource = ""

        if (url.length === 0) {
            return
        }

        if (url.startsWith("file://")) {
            root.currentSource = url
            root.ready = true
            return
        }

        downloader.targetUrl = url
        downloader.targetPath = `${root.cacheDir}/${Qt.md5(url)}.jpg`
        downloader.running = false
        downloader.running = true
    }

    onArtUrlChanged: root.refresh()
    Component.onCompleted: root.refresh()

    Process {
        id: downloader
        property string targetUrl: ""
        property string targetPath: ""
        command: ["bash", "-c", `
            set -e
            out=${root.shellQuote(targetPath)}
            url=${root.shellQuote(targetUrl)}
            mkdir -p "$(dirname "$out")"
            lock="$out.lock"
            (
                flock 9
                if [ -s "$out" ] && { magick identify -quiet "$out" >/dev/null 2>&1 || file --mime-type "$out" | grep -q ': image/'; }; then
                    exit 0
                fi
                rm -f "$out"
                tmp="$(mktemp "$out.XXXXXX")"
                if curl -fL --retry 2 --connect-timeout 8 --max-time 30 -sS "$url" -o "$tmp" \
                    && [ -s "$tmp" ] \
                    && { magick identify -quiet "$tmp" >/dev/null 2>&1 || file --mime-type "$tmp" | grep -q ': image/'; }; then
                    chmod 0644 "$tmp"
                    mv -f "$tmp" "$out"
                else
                    rm -f "$tmp" "$out"
                    exit 1
                fi
            ) 9>"$lock"
        `]
        onExited: (exitCode, exitStatus) => {
            const valid = exitCode === 0 && downloader.targetUrl === root.artUrl
            root.ready = valid
            root.currentSource = valid ? `file://${downloader.targetPath}` : ""
        }
    }
}
