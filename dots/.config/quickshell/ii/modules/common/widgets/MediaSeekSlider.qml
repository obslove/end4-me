pragma ComponentBehavior: Bound
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.services
import Quickshell.Services.Mpris

StyledSlider {
    id: root

    property MprisPlayer player
    property bool wasPlayingBeforeSeek: false
    property bool seekActive: false
    property real seekValue: normalizedPosition()
    signal seekCommitted()

    function normalizedPosition() {
        const length = root.player?.length ?? 0
        if (length <= 0) return 0
        return Math.max(0, Math.min(1, MprisController.displayPosition(root.player) / length))
    }

    function targetPosition() {
        return Math.max(0, Math.min(1, root.value)) * (root.player?.length ?? 0)
    }

    value: root.pressed ? root.seekValue : root.normalizedPosition()
    usePercentTooltip: false
    tooltipContent: StringUtils.friendlyTimeForSeconds(root.targetPosition())

    function beginInteractiveSeek() {
        if (root.seekActive || !root.player) {
            return
        }

        root.seekActive = true
        root.seekValue = root.normalizedPosition()
        root.wasPlayingBeforeSeek = root.player?.isPlaying ?? false
        MprisController.beginSeek(root.player, root.seekValue * (root.player?.length ?? 0))
        if (root.wasPlayingBeforeSeek && root.player?.canPause) {
            root.player.pause()
        } else if (root.wasPlayingBeforeSeek && root.player?.canTogglePlaying) {
            root.player.togglePlaying()
        }
    }

    onPointerPressed: root.beginInteractiveSeek()

    onPressedChanged: {
        if (root.pressed) {
            root.beginInteractiveSeek()
            return
        }

        if (!root.seekActive) {
            return
        }

        root.seekActive = false
        MprisController.finishSeek(root.player, root.seekValue * (root.player?.length ?? 0), root.wasPlayingBeforeSeek)
        root.seekCommitted()
    }

    onMoved: {
        root.seekValue = Math.max(0, Math.min(1, root.value))
        MprisController.updateSeek(root.player, root.seekValue * (root.player?.length ?? 0))
    }
}
