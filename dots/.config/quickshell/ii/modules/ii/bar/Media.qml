pragma ComponentBehavior: Bound
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.services
import qs.modules.common.models
import qs
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

Item {
    id: root
    property bool vertical: false
    property bool borderless: Config.options.bar.borderless
    property bool isMaterial: Config.options.bar.cornerStyle === 3
    readonly property MprisPlayer activePlayer: MprisController.activePlayer
    readonly property string cleanedTitle: StringUtils.cleanMusicTitle(activePlayer?.trackTitle) || Translation.tr("No media")

    // DockMedia-like properties
    property var    artUrl:      activePlayer?.trackArtUrl ?? ""
    property string trackTitle:  activePlayer?.trackTitle  ?? ""
    property string trackArtist: activePlayer?.trackArtist ?? ""
    property bool   isPlaying:   activePlayer?.isPlaying   ?? false
    property bool   hasTrack:    trackTitle.length > 0

    readonly property bool artDownloaded: mediaArtSource.ready
    property color artDominantColor: root.displayedArtFilePath !== ""
        ? ColorUtils.mix(
            colorQuantizer?.colors[0] ?? Appearance.colors.colPrimary,
            Appearance.colors.colPrimaryContainer,
            0.8
        )
        : Appearance.colors.colPrimaryContainer

    property QtObject blendedColors: AdaptedMaterialScheme {
        color: root.artDominantColor
    }

    readonly property string displayedArtFilePath: mediaArtSource.source

    ColorQuantizer {
        id: colorQuantizer
        source: root.displayedArtFilePath
        depth: 0
        rescaleSize: 1
    }

    MediaArtSource {
        id: mediaArtSource
        artUrl: root.artUrl
    }

    Layout.fillHeight: true
    implicitWidth:  vertical ? Appearance.sizes.verticalBarWidth : (isMaterial ? materialRow.implicitWidth : Math.min(rowLayout.implicitWidth + 8, 280))
    implicitHeight: vertical ? (isMaterial ? 26 : mediaCircProg.implicitHeight + 6) : Appearance.sizes.barHeight

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.MiddleButton | Qt.BackButton | Qt.ForwardButton | Qt.RightButton | Qt.LeftButton
        hoverEnabled: !Config.options.bar.tooltips.clickToShow
        onPressed: (event) => {
            if (event.button === Qt.MiddleButton)      activePlayer.togglePlaying()
            else if (event.button === Qt.BackButton)   activePlayer.previous()
            else if (event.button === Qt.ForwardButton || event.button === Qt.RightButton) activePlayer.next()
            else if (event.button === Qt.LeftButton)   GlobalStates.mediaControlsOpen = !GlobalStates.mediaControlsOpen
        }
    }

    // Vertical default
    Loader {
        id: mediaCircProg
        active: root.vertical && !root.isMaterial
        visible: active
        anchors.centerIn: parent
        sourceComponent: ClippedFilledCircularProgress {
            implicitSize: 20
            lineWidth: 2
            value: MprisController.displayPosition(root.activePlayer) / Math.max(root.activePlayer?.length ?? 0, 1)
            colPrimary: root.blendedColors.colOnSecondaryContainer
            enableAnimation: false
            Item {
                anchors.centerIn: parent
                width: 20
                height: 20
                MaterialSymbol {
                    anchors.centerIn: parent
                    fill: 1
                    text: root.activePlayer?.isPlaying ? "pause" : "music_note"
                    iconSize: Appearance.font.pixelSize.normal
                    color: root.blendedColors.colOnSecondaryContainer
                }
            }
        }
    }

    // Vertical Material
    Rectangle {
        visible: root.vertical && root.isMaterial
        anchors.centerIn: parent
        color: root.blendedColors.colSecondaryContainer
        radius: Appearance.rounding.full
        implicitWidth: 32
        implicitHeight: 32

        MaterialSymbol {
            anchors.centerIn: parent
            fill: 1
            text: root.activePlayer?.isPlaying ? "pause" : "music_note"
            iconSize: Appearance.font.pixelSize.normal
            color: root.blendedColors.colOnSecondaryContainer
        }
    }

    // Horizontal default
    Loader {
        id: rowLayout
        active: !root.vertical && !root.isMaterial
        visible: active
        anchors.fill: parent
        sourceComponent: RowLayout {
            spacing: 4
            ClippedFilledCircularProgress {
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: 3
                implicitSize: 20
                lineWidth: 2
                value: MprisController.displayPosition(root.activePlayer) / Math.max(root.activePlayer?.length ?? 0, 1)
                colPrimary: root.blendedColors.colOnSecondaryContainer
                enableAnimation: false
                Item {
                    anchors.centerIn: parent
                    width: 20
                    height: 20
                    MaterialSymbol {
                        anchors.centerIn: parent
                        fill: 1
                        text: root.activePlayer?.isPlaying ? "pause" : "music_note"
                        iconSize: Appearance.font.pixelSize.normal
                        color: root.blendedColors.colOnSecondaryContainer
                    }
                }
            }
            StyledText {
                visible: Config.options.bar.verbose
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true
                Layout.rightMargin: 0
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                color: root.blendedColors.colOnLayer1
                text: `${root.cleanedTitle}${root.activePlayer?.trackArtist ? ' • ' + root.activePlayer.trackArtist : ''}`
            }
        }
    }

    // Horizontal Material
    Loader {
        id: materialRow
        active: !root.vertical && root.isMaterial
        visible: active
        anchors.centerIn: parent
        sourceComponent: Rectangle {
            id: card
            color: root.blendedColors.colSecondaryContainer
            radius: Appearance.rounding.full
            implicitHeight: 30
            implicitWidth: innerRow.implicitWidth + 8

            RowLayout {
                id: innerRow
                anchors.centerIn: parent
                spacing: 6

                // Art
                Rectangle {
                    id: artRect
                    implicitWidth: 26
                    implicitHeight: 26
                    radius: Appearance.rounding.sm
                    color: root.blendedColors.colSecondaryContainer
                    Layout.alignment: Qt.AlignVCenter

                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: artRect.width
                            height: artRect.height
                            radius: artRect.radius
                        }
                    }

                    StyledImage {
                        anchors.fill: parent
                        source: root.displayedArtFilePath
                        fillMode: Image.PreserveAspectCrop
                        cache: false
                        antialiasing: true
                        sourceSize.width: artRect.width
                        sourceSize.height: artRect.height
                        visible: root.displayedArtFilePath !== ""
                    }

                    MaterialSymbol {
                        anchors.centerIn: parent
                        fill: 1
                        text: "music_note"
                        iconSize: Appearance.font.pixelSize.normal
                        color: root.blendedColors.colOnSecondaryContainer
                        visible: root.displayedArtFilePath === ""
                    }
                }

                // Title + Artist
                ColumnLayout {
                    spacing: -4
                    Layout.alignment: Qt.AlignVCenter
                    Layout.topMargin: 2

                    StyledText {
                        id: artistText
                        text: root.trackArtist
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: root.blendedColors.colOnSecondaryContainer
                        elide: Text.ElideRight
                        Layout.maximumWidth: 120
                        Behavior on text {
                            SequentialAnimation {
                                NumberAnimation { target: artistText; property: "x"; to: -artistText.width; duration: 150; easing.type: Easing.InQuad }
                                PropertyAction { target: artistText; property: "text" }
                                NumberAnimation { target: artistText; property: "x"; from: artistText.width; to: 0; duration: 150; easing.type: Easing.OutQuad }
                            }
                        }
                    }
                    StyledText {
                        id: titleText
                        Layout.topMargin: !root.activePlayer ? -13 : 0
                        text: StringUtils.cleanMusicTitle(root.trackTitle) || Translation.tr("No media")
                        font.pixelSize: Appearance.font.pixelSize.smallie
                        color: root.blendedColors.colOnSecondaryContainer
                        elide: Text.ElideRight
                        opacity: 0.7
                        Layout.maximumWidth: 120
                        Behavior on text {
                            SequentialAnimation {
                                NumberAnimation { target: titleText; property: "x"; to: -artistText.width; duration: 150; easing.type: Easing.InQuad }
                                PropertyAction { target: titleText; property: "text" }
                                NumberAnimation { target: titleText; property: "x"; from: artistText.width; to: 0; duration: 150; easing.type: Easing.OutQuad }
                            }
                        }
                    }
                }

                // Play/Pause
                RippleButton {
                    implicitWidth: 40
                    implicitHeight: 23
                    buttonRadius: root.isPlaying ? Appearance.rounding.md : Appearance.rounding.full
                    colBackground: root.isPlaying ? root.blendedColors.colPrimary : ColorUtils.transparentize(root.blendedColors.colLayer0, 0.8)
                    colBackgroundHover: root.isPlaying ? root.blendedColors.colPrimaryHover : root.blendedColors.colSecondaryContainerHover
                    colRipple: root.isPlaying ? root.blendedColors.colPrimaryActive : root.blendedColors.colSecondaryContainerActive
                    downAction: () => root.activePlayer?.togglePlaying()
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                        text: root.isPlaying ? "pause" : "play_arrow"
                        iconSize: Appearance.font.pixelSize.large
                        fill: 1
                        color: root.isPlaying ? root.blendedColors.colOnPrimary : root.blendedColors.colOnSecondaryContainer
                    }
                }

                // Next
                RippleButton {
                    implicitWidth: 26
                    implicitHeight: 26
                    Layout.leftMargin: -4
                    buttonRadius: Appearance.rounding.full
                    colBackground: "transparent"
                    colBackgroundHover: root.blendedColors.colSecondaryContainerHover
                    colRipple: root.blendedColors.colSecondaryContainerActive
                    downAction: () => root.activePlayer?.next()
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                        text: "skip_next"
                        iconSize: Appearance.font.pixelSize.large
                        fill: 1
                        color: root.blendedColors.colOnSecondaryContainer
                    }
                }
            }
        }
    }
}
