import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland

LazyLoader {
    id: root
    property Item hoverTarget
    default property Item contentItem
    property real popupBackgroundMargin: 0
    active: hoverTarget && hoverTarget.containsMouse

    component: PanelWindow {
        id: popupWindow

        // Bring contentItem reference into this scope
        property Item innerContent: root.contentItem
        readonly property real shadowMargin: Appearance.sizes.elevationMargin

        color: "transparent"
        anchors.left: !Config.options.bar.vertical || (Config.options.bar.vertical && !Config.options.bar.bottom)
        anchors.right: Config.options.bar.vertical && Config.options.bar.bottom
        anchors.top: Config.options.bar.vertical || (!Config.options.bar.vertical && !Config.options.bar.bottom)
        anchors.bottom: !Config.options.bar.vertical && Config.options.bar.bottom

        implicitWidth: popupBackground.implicitWidth + Appearance.sizes.elevationMargin * 2 + root.popupBackgroundMargin
        implicitHeight: popupBackground.implicitHeight + Appearance.sizes.elevationMargin * 2 + root.popupBackgroundMargin

        mask: Region {
            item: popupBackground
        }
        exclusionMode: ExclusionMode.Ignore
        exclusiveZone: 0

        function clamp(value, lower, upper) {
            return Math.max(lower, Math.min(value, upper))
        }

        function targetPoint(x, y) {
            return root.QsWindow?.mapFromItem(root.hoverTarget, x, y) ?? Qt.point(0, 0)
        }

        margins {
            left: {
                if (!Config.options.bar.vertical) {
                    const desiredBackgroundLeft = popupWindow.targetPoint((root.hoverTarget.width - popupBackground.implicitWidth) / 2, 0).x
                    const maxLeft = popupWindow.screen.width - popupWindow.implicitWidth
                    return popupWindow.clamp(desiredBackgroundLeft - popupWindow.shadowMargin, 0, maxLeft)
                }
                if (!Config.options.bar.bottom) {
                    const desiredBackgroundLeft = popupWindow.targetPoint(root.hoverTarget.width, 0).x
                    const maxLeft = popupWindow.screen.width - popupWindow.implicitWidth
                    return popupWindow.clamp(desiredBackgroundLeft - popupWindow.shadowMargin, 0, maxLeft)
                }
                return 0
            }
            top: {
                if (!Config.options.bar.vertical && !Config.options.bar.bottom) {
                    const desiredBackgroundTop = popupWindow.targetPoint(0, root.hoverTarget.height).y
                    const maxTop = popupWindow.screen.height - popupWindow.implicitHeight
                    return popupWindow.clamp(desiredBackgroundTop - popupWindow.shadowMargin, 0, maxTop)
                }
                if (Config.options.bar.vertical) {
                    const desiredBackgroundTop = popupWindow.targetPoint(0, (root.hoverTarget.height - popupBackground.implicitHeight) / 2).y
                    const maxTop = popupWindow.screen.height - popupWindow.implicitHeight
                    return popupWindow.clamp(desiredBackgroundTop - popupWindow.shadowMargin, 0, maxTop)
                }
                return 0
            }
            right: {
                if (Config.options.bar.vertical && Config.options.bar.bottom) {
                    const desiredBackgroundRight = popupWindow.screen.width - popupWindow.targetPoint(0, 0).x
                    const maxRight = popupWindow.screen.width - popupWindow.implicitWidth
                    return popupWindow.clamp(desiredBackgroundRight - popupWindow.shadowMargin, 0, maxRight)
                }
                return 0
            }
            bottom: {
                if (!Config.options.bar.vertical && Config.options.bar.bottom) {
                    const desiredBackgroundBottom = popupWindow.screen.height - popupWindow.targetPoint(0, 0).y
                    const maxBottom = popupWindow.screen.height - popupWindow.implicitHeight
                    return popupWindow.clamp(desiredBackgroundBottom - popupWindow.shadowMargin, 0, maxBottom)
                }
                return 0
            }
        }
        WlrLayershell.namespace: "quickshell:popup"
        WlrLayershell.layer: WlrLayer.Overlay

        StyledRectangularShadow {
            target: popupBackground
        }

        Rectangle {
            id: popupBackground
            readonly property real margin: 8

            anchors {
                fill: parent
                leftMargin: Appearance.sizes.elevationMargin + root.popupBackgroundMargin * (!popupWindow.anchors.left)
                rightMargin: Appearance.sizes.elevationMargin + root.popupBackgroundMargin * (!popupWindow.anchors.right)
                topMargin: Appearance.sizes.elevationMargin + root.popupBackgroundMargin * (!popupWindow.anchors.top)
                bottomMargin: Appearance.sizes.elevationMargin + root.popupBackgroundMargin * (!popupWindow.anchors.bottom)
            }

            // Use local reference instead of crossing LazyLoader scope boundary
            implicitWidth: (popupWindow.innerContent?.implicitWidth ?? 0) + margin * 2
            implicitHeight: (popupWindow.innerContent?.implicitHeight ?? 0) + margin * 2

            color: Appearance.colors.colLayer1Base
            radius: Appearance.rounding.normal
            border.width: 1
            border.color: Appearance.colors.colLayer0Border

            // Reparent content here once the window is ready
            Component.onCompleted: {
                if (popupWindow.innerContent) {
                    popupWindow.innerContent.parent = popupBackground
                    popupWindow.innerContent.anchors.centerIn = popupBackground
                }
            }
        }
    }
}
