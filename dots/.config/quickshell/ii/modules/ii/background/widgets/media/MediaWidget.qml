import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import qs
import qs.services
import Qt5Compat.GraphicalEffects
import qs.modules.common
import qs.modules.common.models
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.common.widgets.widgetCanvas
import qs.modules.ii.background.widgets

AbstractBackgroundWidget {
    id: root

    signal requestReset()

    configEntryName: "media"

    readonly property var playerList: MprisController.players
    property MprisPlayer currentPlayer: MprisController.activePlayer
    property var artUrl: currentPlayer?.trackArtUrl
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

    property real widgetSize: 200
    property real controlsSize: 55
    property real buttonIconSize: 30

    readonly property bool downloaded: mediaArtSource.ready
    readonly property string displayedArtFilePath: mediaArtSource.source

    implicitHeight: contentItem.implicitHeight
    implicitWidth: contentItem.implicitWidth

    property bool hovering: false
    hoverEnabled: true
    onEntered: { hovering = true }
    onExited:  { hovering = false }

    MediaArtSource {
        id: mediaArtSource
        artUrl: root.artUrl ?? ""
    }

    ColorQuantizer {
        id: colorQuantizer
        source: root.displayedArtFilePath
        depth: 0
        rescaleSize: 1
    }

    function getShape(name) {
        switch (name) {
            case "Circle":        return MaterialShape.Shape.Circle
            case "Square":        return MaterialShape.Shape.Square
            case "Slanted":       return MaterialShape.Shape.Slanted
            case "Arch":          return MaterialShape.Shape.Arch
            case "Fan":           return MaterialShape.Shape.Fan
            case "Arrow":         return MaterialShape.Shape.Arrow
            case "SemiCircle":    return MaterialShape.Shape.SemiCircle
            case "Oval":          return MaterialShape.Shape.Oval
            case "Pill":          return MaterialShape.Shape.Pill
            case "Triangle":      return MaterialShape.Shape.Triangle
            case "Diamond":       return MaterialShape.Shape.Diamond
            case "ClamShell":     return MaterialShape.Shape.ClamShell
            case "Pentagon":      return MaterialShape.Shape.Pentagon
            case "Gem":           return MaterialShape.Shape.Gem
            case "Sunny":         return MaterialShape.Shape.Sunny
            case "VerySunny":     return MaterialShape.Shape.VerySunny
            case "Cookie4Sided":  return MaterialShape.Shape.Cookie4Sided
            case "Cookie6Sided":  return MaterialShape.Shape.Cookie6Sided
            case "Cookie7Sided":  return MaterialShape.Shape.Cookie7Sided
            case "Cookie9Sided":  return MaterialShape.Shape.Cookie9Sided
            case "Cookie12Sided": return MaterialShape.Shape.Cookie12Sided
            case "Ghostish":      return MaterialShape.Shape.Ghostish
            case "Clover4Leaf":   return MaterialShape.Shape.Clover4Leaf
            case "Clover8Leaf":   return MaterialShape.Shape.Clover8Leaf
            case "Burst":         return MaterialShape.Shape.Burst
            case "SoftBurst":     return MaterialShape.Shape.SoftBurst
            case "Boom":          return MaterialShape.Shape.Boom
            case "SoftBoom":      return MaterialShape.Shape.SoftBoom
            case "Flower":        return MaterialShape.Shape.Flower
            case "Puffy":         return MaterialShape.Shape.Puffy
            case "PuffyDiamond":  return MaterialShape.Shape.PuffyDiamond
            case "PixelCircle":   return MaterialShape.Shape.PixelCircle
            case "PixelTriangle": return MaterialShape.Shape.PixelTriangle
            case "Bun":           return MaterialShape.Shape.Bun
            case "Heart":         return MaterialShape.Shape.Heart
            default:              return MaterialShape.Shape.Cookie4Sided
        }
    }

    Item {
        id: contentItem

        implicitWidth: root.widgetSize
        implicitHeight: root.widgetSize

        MaterialShape {
            id: shadowShape
            anchors.fill: parent
            color: blendedColors.colPrimaryContainer
            shape: getShape(Config.options.background.widgets.media.backgroundShape)
            visible: false
        }

        StyledDropShadow {
            target: shadowShape
            z: -1
        }

        MaterialShape {
            id: artBackground
            anchors.fill: parent
            z: 0
            color: blendedColors.colPrimaryContainer
            shape: getShape(Config.options.background.widgets.media.backgroundShape)

            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: MaterialShape {
                    width: artBackground.width
                    height: artBackground.height
                    shape: getShape(Config.options.background.widgets.media.backgroundShape)
                }
            }

            StyledImage {
                id: mediaArt
                property int size: parent.height
                anchors.fill: parent
                source: root.displayedArtFilePath
                fillMode: Image.PreserveAspectCrop
                cache: false
                antialiasing: true
                width: size
                height: size
                sourceSize.width: size
                sourceSize.height: size
            }
        }

        Loader {
            z: 1
            active: Config.options.background.widgets.media.showTitles
            anchors {
                left: parent.left
                bottom: parent.bottom
            }
            sourceComponent: Column {
                spacing: 0

                Rectangle {
                    implicitWidth: controlsSize * 2
                    implicitHeight: controlsSize - 10
                    radius: Appearance.rounding.full
                    color: blendedColors.colSecondaryContainer

                    Column {
                        anchors.centerIn: parent
                        spacing: 2

                        Text {
                            width: controlsSize * 2 - 12
                            text: root.currentPlayer?.trackArtist ?? ""
                            color: blendedColors.colOnSecondaryContainer
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignHCenter
                        }

                        Text {
                            width: controlsSize * 2 - 12
                            text: root.currentPlayer?.trackTitle ?? ""
                            color: blendedColors.colOnSecondaryContainer
                            font.pixelSize: 9
                            opacity: 0.6
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }

                Item {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 8 + cornerRadius * 2
                    height: Config.options.background.widgets.media.showLyrics ? 16 : 0

                    property int cornerRadius: 4

                    Rectangle {
                        id: theRect
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        width: 0
                        height: Config.options.background.widgets.media.showLyrics ? 16 : 0
                        color: blendedColors.colSecondaryContainer
                        radius: Appearance.rounding.none
                    }

                    RoundCorner {
                        visible: Config.options.background.widgets.media.showLyrics
                        anchors.right: theRect.left
                        anchors.top: theRect.top
                        implicitSize: cornerRadius
                        color: blendedColors.colSecondaryContainer
                        corner: RoundCorner.CornerEnum.TopRight
                    }

                    RoundCorner {
                        visible: Config.options.background.widgets.media.showLyrics
                        anchors.left: theRect.right
                        anchors.top: theRect.top
                        implicitSize: cornerRadius
                        color: blendedColors.colSecondaryContainer
                        corner: RoundCorner.CornerEnum.TopLeft
                    }

                    Item {
                        width: 320
                        height: Config.options.background.widgets.media.showLyrics ? 250 + 16 : 0
                        anchors.horizontalCenter: parent.horizontalCenter

                        Rectangle {
                            id: lyricsBox
                            visible: Config.options.background.widgets.media.showLyrics
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            width: 320
                            height: 250
                            radius: Appearance.rounding.lg
                            color: blendedColors.colSecondaryContainer

                            Lyrics {
                                id: lyricsComp
                                anchors.fill: parent
                                anchors.margins: 16
                                textAlignment: Text.AlignHCenter
                                player: root.currentPlayer
                                textColor: blendedColors.colOnLayer0
                                activeColor: blendedColors.colPrimary
                                dimColor: blendedColors.colSubtext
                                indicatorColor: blendedColors.colPrimary
                                indicatorShapeColor: blendedColors.colOnPrimary
                            }
                        }
                    }
                }
            }
        }

        FadeLoader {
            z: 2
            active: Config.options.background.widgets.media.showControls
            anchors {
                top: parent.top
                right: parent.right
            }
            sourceComponent: ControlButton {
                buttonRadius: root.currentPlayer?.isPlaying ? Appearance.rounding.md : Appearance.rounding.full
                colBackground: root.currentPlayer?.isPlaying ? blendedColors.colPrimary : blendedColors.colSecondaryContainer
                colBackgroundHover: root.currentPlayer?.isPlaying ? blendedColors.colPrimaryHover : blendedColors.colSecondaryContainerHover
                colRipple: root.currentPlayer?.isPlaying ? blendedColors.colPrimaryActive : blendedColors.colSecondaryContainerActive
                symbolText: root.currentPlayer?.isPlaying ? "pause" : "play_arrow"
                symbolColor: root.currentPlayer?.isPlaying ? blendedColors.colOnPrimary : blendedColors.colOnSecondaryContainer
                onClicked: {
                    root.currentPlayer.togglePlaying()
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton | Qt.MiddleButton | Qt.BackButton | Qt.ForwardButton
                    onPressed: (event) => {
                        if (event.button === Qt.MiddleButton || event.button === Qt.BackButton) {
                            root.currentPlayer.previous()
                        } else if (event.button === Qt.RightButton || event.button === Qt.ForwardButton) {
                            root.currentPlayer.next()
                        }
                    }
                }
            }
        }

        FadeLoader {
            z: 3
            anchors.centerIn: parent
            shown: root.currentPlayer == null
            sourceComponent: MaterialShapeWrappedMaterialSymbol {
                padding: 20
                text: root.currentPlayer == null ? "music_off" : !root.downloaded ? "hourglass_bottom" : ""
                anchors.centerIn: parent
                iconSize: root.widgetSize / 4
                shape: MaterialShape.Shape.Cookie12Sided
                color: blendedColors.colOnSecondaryContainer
                colSymbol: blendedColors.colPrimaryContainer
            }
        }
    }

    component ControlButton: RippleButton {
        id: button
        property string symbolText
        property color symbolColor

        z: 2
        implicitWidth: controlsSize
        implicitHeight: implicitWidth
        buttonRadius: Appearance.rounding.full

        MaterialSymbol {
            anchors.centerIn: parent
            iconSize: root.buttonIconSize
            text: button.symbolText
            fill: 1
            color: button.symbolColor
        }
    }
}
