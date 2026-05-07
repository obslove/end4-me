import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import Quickshell.Hyprland
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Item {
    id: root
    implicitHeight: Appearance.sizes.barHeight
    width: parent.width

    readonly property real barPadding: 0
    property var screen: root.QsWindow.window?.screen

    function getWidgetUrl(name) {
        if (!name)
            return "";
        const formattedName = name.charAt(0).toUpperCase() + name.slice(1);
        return Qt.resolvedUrl(`./${formattedName}.qml`);
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
            width: middleRow.implicitWidth
            height: parent.height

            RowLayout {
                id: middleRow
                anchors.fill: parent
                spacing: 2

                Repeater {
                    model: Config.options.bar.layouts.middleLayout
                    delegate: BarGroup {
                        required property var modelData
                        required property int index
                        Layout.fillHeight: true
                        currentIndex: index
                        totalCount: Config.options.bar.layouts.middleLayout.length

                        Loader {
                            Layout.fillHeight: true
                            source: root.getWidgetUrl(modelData)
                        }
                    }
                }
            }
        }

        Item {
            anchors {
                left: parent.left
                leftMargin: Config.options.bar.cornerStyle === 1 ? 4 : 10
                top: parent.top
                bottom: parent.bottom
            }
            width: leftRow.implicitWidth

            RowLayout {
                id: leftRow
                anchors.fill: parent
                spacing: 2

                Repeater {
                    model: Config.options.bar.layouts.leftLayout
                    delegate: BarGroup {
                        required property var modelData
                        required property int index
                        Layout.fillHeight: true
                        currentIndex: index
                        totalCount: Config.options.bar.layouts.leftLayout.length

                        Loader {
                            Layout.fillHeight: true
                            source: root.getWidgetUrl(modelData)
                        }
                    }
                }
            }
        }

        Item {
            anchors {
                right: parent.right
                rightMargin: Config.options.bar.cornerStyle === 1 ? 4 : 10
                top: parent.top
                bottom: parent.bottom
            }
            width: rightRow.implicitWidth

            RowLayout {
                id: rightRow
                anchors.fill: parent
                spacing: 2

                Repeater {
                    model: Config.options.bar.layouts.rightLayout
                    delegate: BarGroup {
                        required property var modelData
                        required property int index
                        Layout.fillHeight: true
                        currentIndex: index
                        totalCount: Config.options.bar.layouts.rightLayout.length

                        Loader {
                            Layout.fillHeight: true
                            source: root.getWidgetUrl(modelData)
                        }
                    }
                }
            }
        }
    }
}
