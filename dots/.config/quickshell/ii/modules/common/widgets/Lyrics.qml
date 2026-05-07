pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.utils
import qs.services
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

Item {
    id: root

    property var player: null
    property color textColor: "white"
    property color activeColor: "white"
    property color dimColor: Qt.rgba(1, 1, 1, 0.35)

    property color indicatorColor: Appearance.colors.colPrimaryContainer
    property color indicatorShapeColor: Appearance.colors.colOnPrimaryContainer

    readonly property var lyricsLines: lyricsBackend.lines
    property int activeIndex: -1
    property int textAlignment: Text.AlignLeft
    readonly property bool serviceEnabled: Config.options.lyricsService.enable && Config.options.lyricsService.enableLrclib
    readonly property string style: Config.options.lyricsService.style === "static" ? "static" : "scroller"
    readonly property bool useGradientMask: Config.options.lyricsService.useGradientMask
    readonly property int lyricFontSize: Config.options.lyricsService.fontSize
    readonly property string status: {
        if (!root.serviceEnabled) return "disabled"
        if (lyricsBackend.loading) return "loading"
        if (lyricsBackend.error === "No track info") return "no_info"
        if (lyricsBackend.error === "Instrumental") return "instrumental"
        if (lyricsBackend.error) return "not_found"
        if (root.lyricsLines.length > 0) return "ok"
        return "loading"
    }
    readonly property string statusText: {
        if (root.status === "disabled") return Translation.tr("Lyrics disabled")
        if (root.status === "loading") return Translation.tr("Fetching lyrics...")
        if (root.status === "not_found") return Translation.tr("No synced lyrics")
        if (root.status === "no_info") return Translation.tr("No track info")
        if (root.status === "instrumental") return Translation.tr("Instrumental")
        return ""
    }

    readonly property int before: 3
    readonly property int after:  3
    readonly property int total:  7
    readonly property int halfVisibleLines: 2
    readonly property int visibleLineCount: halfVisibleLines * 2 + 1
    readonly property int rowHeight: Math.round(Math.max(46, lyricFontSize * 2.8))
    readonly property real animProgress: rowHeight > 0 ? Math.min(1, Math.abs(scrollOffset) / rowHeight) : 0
    readonly property string currentLineText: activeIndex >= 0 ? (lyricsLines[activeIndex]?.text ?? "") : ""

    property int lastIndex: -1
    property bool isMovingForward: true
    property real scrollOffset: 0

    function buildSlots(idx) {
        let result = []
        for (let i = 0; i < root.total; i++) {
            let lineIdx = idx - root.before + i
            if (lineIdx >= 0 && lineIdx < root.lyricsLines.length) {
                result.push(root.lyricsLines[lineIdx].text || "♪")
            } else {
                result.push("")
            }
        }
        return result
    }

    property var slots: ["", "", "", "", "", "", ""]

    function opacityForOffset(offset) {
        const dist = Math.abs(offset)
        if (dist === 0) return 1.0
        if (dist === 1) return 0.48
        if (dist === 2) return 0.16
        return 0.0
    }

    function updateActiveIndex(idx) {
        if (idx === root.activeIndex) {
            return
        }
        root.isMovingForward = idx > root.lastIndex
        root.lastIndex = idx
        root.activeIndex = idx
        root.slots = root.buildSlots(idx)
        scrollAnimation.stop()
        root.scrollOffset = root.isMovingForward ? -root.rowHeight : root.rowHeight
        scrollAnimation.start()
    }

    function activeIndexForPosition(positionSeconds) {
        if (!root.lyricsLines || root.lyricsLines.length === 0) {
            return -1
        }

        const position = isNaN(positionSeconds) || positionSeconds < 0 ? 0 : positionSeconds
        let lo = 0
        let hi = root.lyricsLines.length - 1
        let idx = -1

        while (lo <= hi) {
            const mid = (lo + hi) >> 1
            if (root.lyricsLines[mid].time <= position) {
                idx = mid
                lo = mid + 1
            } else {
                hi = mid - 1
            }
        }

        return idx
    }

    NumberAnimation {
        id: scrollAnimation
        target: root
        property: "scrollOffset"
        to: 0
        duration: 400
        easing.type: Easing.OutQuart
    }

    Timer {
        id: syncTimer
        interval: 300
        repeat: true
        running: root.status === "ok" && root.lyricsLines.length > 0
        onTriggered: {
            root.updateActiveIndex(root.activeIndexForPosition(root.player?.position ?? 0))
        }
    }

    function resetLyricsView() {
        root.activeIndex = -1
        root.lastIndex = -1
        root.scrollOffset = 0
        root.slots = ["", "", "", "", "", "", ""]
    }

    function restartLyrics() {
        root.resetLyricsView()
        if (root.status === "ok") {
            Qt.callLater(() => root.updateActiveIndex(root.activeIndexForPosition(root.player?.position ?? 0)))
        }
    }

    LrclibLyrics {
        id: lyricsBackend
        active: root.serviceEnabled
        title: root.player?.trackTitle ?? ""
        artist: root.player?.trackArtist ?? ""
        duration: root.player?.length ?? 0
    }

    onLyricsLinesChanged: {
        root.resetLyricsView()
        if (root.status === "ok") {
            Qt.callLater(() => root.updateActiveIndex(-1))
        }
    }

    onStatusChanged: {
        if (root.status !== "ok") {
            root.resetLyricsView()
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 4

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.status !== "ok"

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 12

                MaterialLoadingIndicator {
                    Layout.alignment: Qt.AlignHCenter
                    visible: root.status === "loading"
                    loading: root.status === "loading"
                    colBg: root.indicatorColor
                    colShape: root.indicatorShapeColor
                    implicitSize: 48
                }

                StyledText {
                    visible: root.status !== "loading"
                    Layout.alignment: Qt.AlignHCenter
                    horizontalAlignment: Text.AlignHCenter
                    color: root.dimColor
                    text: root.statusText
                    font.pixelSize: Appearance.font.pixelSize.small
                }
            }
        }

        StyledText {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.status === "ok" && root.style === "static"
            horizontalAlignment: root.textAlignment
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            text: root.currentLineText || "♪"
            color: root.activeColor
            font.pixelSize: root.lyricFontSize
            font.weight: Font.DemiBold
            animateChange: true
            animationDistanceX: 0
            animationDistanceY: 8
        }

        Item {
            id: scrollerView
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.status === "ok" && root.style === "scroller"
            clip: true
            layer.enabled: root.useGradientMask
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: scrollerView.width
                    height: scrollerView.height
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 0.18; color: "black" }
                        GradientStop { position: 0.88; color: "black" }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                }
            }

            Column {
                width: parent.width
                spacing: 0
                y: Math.round((parent.height - root.rowHeight) / 2 - (root.halfVisibleLines * root.rowHeight) - root.scrollOffset)

                Repeater {
                    model: root.visibleLineCount
                    delegate: StyledText {
                        required property int index
                        readonly property int lineOffset: index - root.halfVisibleLines
                        readonly property int actualIndex: root.activeIndex + lineOffset
                        readonly property int oldLineOffset: root.isMovingForward ? lineOffset + 1 : lineOffset - 1
                        readonly property real targetHighlight: Math.abs(lineOffset) === 0 ? 1.0 : 0.0
                        readonly property real startHighlight: Math.abs(oldLineOffset) === 0 ? 1.0 : 0.0
                        readonly property real highlightFactor: startHighlight + (targetHighlight - startHighlight) * (1.0 - root.animProgress)
                        readonly property real targetOpacity: root.opacityForOffset(lineOffset)
                        readonly property real startOpacity: root.opacityForOffset(oldLineOffset)

                        width: parent.width
                        height: root.rowHeight
                        horizontalAlignment: root.textAlignment
                        verticalAlignment: Text.AlignVCenter
                        wrapMode: Text.WordWrap
                        maximumLineCount: Math.abs(lineOffset) === 0 ? 2 : 1
                        elide: Math.abs(lineOffset) === 0 ? Text.ElideNone : Text.ElideRight
                        text: {
                            if (actualIndex >= 0 && actualIndex < root.lyricsLines.length) {
                                return root.lyricsLines[actualIndex].text || (lineOffset === 0 ? "♪" : "");
                            }
                            return lineOffset === 0 ? "♪" : "";
                        }
                        color: highlightFactor > 0.5 ? root.activeColor : root.dimColor
                        font.pixelSize: Math.round(root.lyricFontSize * (highlightFactor > 0.5 ? 1.12 : 0.92))
                        font.weight: highlightFactor > 0.5 ? Font.Bold : Font.Medium
                        opacity: startOpacity + (targetOpacity - startOpacity) * (1.0 - root.animProgress)
                    }
                }
            }
        }

    }
}
