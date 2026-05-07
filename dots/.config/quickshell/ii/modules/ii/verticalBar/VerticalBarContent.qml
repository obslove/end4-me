import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Services.UPower
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.ii.bar as Bar

Item {
    id: root
    implicitWidth: Appearance.sizes.verticalBarWidth
    height: parent.height

    readonly property real barPadding: 0
    property var screen: root.QsWindow.window?.screen

    function getWidgetUrl(name) {
        switch (name) {
        case "resources": return Qt.resolvedUrl("./Resources.qml");
        case "media": return Qt.resolvedUrl("./VerticalMedia.qml");
        case "clockWidget": return Qt.resolvedUrl("./VerticalClockWidget.qml");
        case "batteryIndicator": return Qt.resolvedUrl("./BatteryIndicator.qml");
        case "workspaces": return Qt.resolvedUrl("../bar/Workspaces.qml");
        case "leftSidebarButton": return Qt.resolvedUrl("../bar/LeftSidebarButton.qml");
        case "sysTray": return Qt.resolvedUrl("../bar/SysTray.qml");
        case "utilButtons": return Qt.resolvedUrl("../bar/UtilButtons.qml");
        case "systemIcons": return Qt.resolvedUrl("../bar/SystemIcons.qml");
        case "activeWindow": return Qt.resolvedUrl("../bar/ActiveWindow.qml");
        case "weatherBar": return Qt.resolvedUrl("../bar/WeatherBar.qml");
        case "powerButton": return Qt.resolvedUrl("../bar/PowerButton.qml");
        case "updatesCount": return Qt.resolvedUrl("../bar/UpdatesCount.qml");
        default:
            if (!name)
                return "";
            const formattedName = name.charAt(0).toUpperCase() + name.slice(1);
            return Qt.resolvedUrl(`../bar/${formattedName}.qml`);
        }
    }

    Rectangle {
        id: barBackground
        anchors {
            fill: parent
            margins: Config.options.bar.cornerStyle === 1 ? Appearance.sizes.hyprlandGapsOut : 0
        }
        color: Config.options.bar.showBackground && Config.options.bar.cornerStyle !== 2 ? Appearance.colors.colLayer0 : "transparent"
        radius: Config.options.bar.cornerStyle === 1 ? Appearance.rounding.windowRounding : 0
        border.width: Config.options.bar.cornerStyle === 1 ? 1 : 0
        border.color: Appearance.colors.colLayer0Border
    }

    Item {
        id: contentContainer
        anchors.fill: barBackground
        anchors.margins: root.barPadding

        Item {
            id: absoluteCenter
            anchors.centerIn: parent
            height: middleCol.implicitHeight
            width: parent.width

            ColumnLayout {
                id: middleCol
                anchors.fill: parent
                spacing: 2

                Repeater {
                    model: Config.options.bar.layouts.middleLayout
                    delegate: Bar.BarGroup {
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        vertical: true
                        currentIndex: index
                        totalCount: Config.options.bar.layouts.middleLayout.length

                        Loader {
                            Layout.fillWidth: true
                            source: root.getWidgetUrl(modelData)
                            onLoaded: {
                                if (item && "vertical" in item)
                                    item.vertical = true;
                            }
                        }
                    }
                }
            }
        }

        Item {
            anchors {
                top: parent.top
                topMargin: Config.options.bar.cornerStyle === 1 ? 4 : 10
                left: parent.left
                right: parent.right
            }
            height: topCol.implicitHeight

            ColumnLayout {
                id: topCol
                anchors.fill: parent
                spacing: 2

                Repeater {
                    model: Config.options.bar.layouts.leftLayout
                    delegate: Bar.BarGroup {
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        vertical: true
                        currentIndex: index
                        totalCount: Config.options.bar.layouts.leftLayout.length

                        Loader {
                            Layout.fillWidth: true
                            source: root.getWidgetUrl(modelData)
                            onLoaded: {
                                if (item && "vertical" in item)
                                    item.vertical = true;
                            }
                        }
                    }
                }
            }
        }

        Item {
            anchors {
                bottom: parent.bottom
                bottomMargin: Config.options.bar.cornerStyle === 1 ? 4 : 10
                left: parent.left
                right: parent.right
            }
            height: bottomCol.implicitHeight

            ColumnLayout {
                id: bottomCol
                anchors.fill: parent
                spacing: 2

                Repeater {
                    model: Config.options.bar.layouts.rightLayout
                    delegate: Bar.BarGroup {
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        vertical: true
                        currentIndex: index
                        totalCount: Config.options.bar.layouts.rightLayout.length

                        Loader {
                            Layout.fillWidth: true
                            source: root.getWidgetUrl(modelData)
                            onLoaded: {
                                if (item && "vertical" in item)
                                    item.vertical = true;
                            }
                        }
                    }
                }
            }
        }
    }
}
