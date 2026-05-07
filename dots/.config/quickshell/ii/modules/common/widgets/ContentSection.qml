import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

ColumnLayout {
    id: root
    property var shape: null
    property var shapePool: [
        MaterialShape.Shape.Circle,
        MaterialShape.Shape.Square,
        MaterialShape.Shape.Slanted,
        MaterialShape.Shape.Arch,
        MaterialShape.Shape.Fan,
        MaterialShape.Shape.Arrow,
        MaterialShape.Shape.SemiCircle,
        MaterialShape.Shape.Oval,
        MaterialShape.Shape.Pill,
        MaterialShape.Shape.Triangle,
        MaterialShape.Shape.Diamond,
        MaterialShape.Shape.ClamShell,
        MaterialShape.Shape.Pentagon,
        MaterialShape.Shape.Gem,
        MaterialShape.Shape.Sunny,
        MaterialShape.Shape.VerySunny,
        MaterialShape.Shape.Cookie4Sided,
        MaterialShape.Shape.Cookie6Sided,
        MaterialShape.Shape.Cookie7Sided,
        MaterialShape.Shape.Cookie9Sided,
        MaterialShape.Shape.Cookie12Sided,
        MaterialShape.Shape.Ghostish,
        MaterialShape.Shape.Clover4Leaf,
        MaterialShape.Shape.Clover8Leaf,
        MaterialShape.Shape.Burst,
        MaterialShape.Shape.SoftBurst,
        MaterialShape.Shape.Boom,
        MaterialShape.Shape.SoftBoom,
        MaterialShape.Shape.Flower,
        MaterialShape.Shape.Puffy,
        MaterialShape.Shape.PuffyDiamond,
        MaterialShape.Shape.PixelCircle,
        MaterialShape.Shape.PixelTriangle,
        MaterialShape.Shape.Bun,
        MaterialShape.Shape.Heart
    ]
    property var randomShape: shapePool[Math.floor(Math.random() * shapePool.length)]
    readonly property var effectiveShape: shape ?? randomShape
    property string title
    property string icon: ""
    property color bgColor: Appearance.colors.colSecondaryContainer
    property real iconSize: Appearance.font.pixelSize.larger
    property real shapePadding: 6
    default property alias contentData: sectionContent.data

    Layout.fillWidth: true
    spacing: 6

    RowLayout {
        spacing: 6
        MaterialShapeWrappedMaterialSymbol {
            visible: root.icon.length > 0
            text: root.icon
            iconSize: root.iconSize
            padding: root.shapePadding
            wrappedShape: root.effectiveShape
            color: root.bgColor
        }
        StyledText {
            text: root.title
            font.pixelSize: Appearance.font.pixelSize.larger
            font.weight: Font.Medium
            color: Appearance.colors.colOnSecondaryContainer
        }
    }

    ColumnLayout {
        id: sectionContent
        Layout.fillWidth: true
        spacing: 4

    }
}
