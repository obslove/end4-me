import qs.modules.common
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property bool vertical: false
    property real padding: 5
    property int currentIndex: 0
    property int totalCount: 0
    readonly property bool backgroundEnabled: Config.options?.bar.showBackground ?? true
    readonly property real fullRadius: Math.min(width, height) / 2
    readonly property real midRadius: Config.options.bar.cornerStyle === 2 ? Appearance.rounding.unsharpenmore + 2 : Appearance.rounding.unsharpenmore
    readonly property real startRadius: {
        if (totalCount <= 1 || currentIndex === 0) return fullRadius;
        return midRadius;
    }
    readonly property real endRadius: {
        if (totalCount <= 1 || currentIndex === totalCount - 1) return fullRadius;
        return midRadius;
    }
    implicitWidth: vertical ? Appearance.sizes.baseVerticalBarWidth : (gridLayout.implicitWidth + padding * 2)
    implicitHeight: vertical ? (gridLayout.implicitHeight + padding * 2) : Appearance.sizes.baseBarHeight
    default property alias items: gridLayout.children

    Rectangle {
        id: background
        anchors {
            fill: parent
            topMargin: root.vertical ? 0 : 4
            bottomMargin: root.vertical ? 0 : 4
            leftMargin: root.vertical ? 4 : 0
            rightMargin: root.vertical ? 4 : 0
        }
        color: (!root.backgroundEnabled || Config.options?.bar.borderless) ? "transparent" : Config.options.bar.cornerStyle === 2 ? Appearance.colors.colLayer0 : Appearance.colors.colLayer1
        topLeftRadius: root.startRadius
        bottomLeftRadius: root.vertical ? root.endRadius : root.startRadius
        topRightRadius: root.vertical ? root.startRadius : root.endRadius
        bottomRightRadius: root.endRadius

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }
    }

    GridLayout {
        id: gridLayout
        columns: root.vertical ? 1 : -1
        anchors {
            verticalCenter: root.vertical ? undefined : parent.verticalCenter
            horizontalCenter: root.vertical ? parent.horizontalCenter : undefined
            left: root.vertical ? undefined : parent.left
            right: root.vertical ? undefined : parent.right
            top: root.vertical ? parent.top : undefined
            bottom: root.vertical ? parent.bottom : undefined
            margins: root.padding
        }
        columnSpacing: 0
        rowSpacing: 0
    }
}
