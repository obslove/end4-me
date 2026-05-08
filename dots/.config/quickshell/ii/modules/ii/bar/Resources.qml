import qs.services
import qs.modules.common
import QtQuick
import QtQuick.Layouts

MouseArea {
    id: root
    property bool vertical: false
    property bool alwaysShowAllResources: false
    property bool isMaterial: Config.options.bar.cornerStyle === 3
    property real contentWidth: vertical ? (colLoader.item?.implicitWidth ?? 0) : (rowLoader.item?.implicitWidth ?? 0)
    property real contentHeight: vertical ? (colLoader.item?.implicitHeight ?? 0) : (rowLoader.item?.implicitHeight ?? 0)

    implicitWidth: vertical
        ? Math.max(0, contentWidth + (isMaterial ? 0 : 4))
        : Math.max(0, contentWidth + (isMaterial ? 10 : 4))
    implicitHeight: vertical
        ? Math.max(0, contentHeight + (isMaterial ? 15 : 20))
        : (isMaterial ? Appearance.sizes.barHeight - 10 : Appearance.sizes.barHeight)
    hoverEnabled: !Config.options.bar.tooltips.clickToShow

    Rectangle {
        anchors.fill: parent
        color: root.isMaterial ? Appearance.colors.colTertiaryContainer : "transparent"
        radius: Appearance.rounding.full

        Loader {
            id: rowLoader
            active: !root.vertical
            visible: active
            anchors.centerIn: parent
            sourceComponent: RowLayout {
                spacing: 0
                Resource {
                    iconName: "memory"
                    shown: Config.options.bar.resources.alwaysShowRam
                    percentage: ResourceUsage.memoryUsedPercentage
                    warningThreshold: Config.options.bar.resources.memoryWarningThreshold
                }
                Resource {
                    iconName: "planner_review"
                    shown: Config.options.bar.resources.alwaysShowCpu
                    percentage: ResourceUsage.cpuUsage
                    Layout.leftMargin: shown ? 6 : 0
                    warningThreshold: Config.options.bar.resources.cpuWarningThreshold
                }
                Resource {
                    iconName: "thermostat"
                    shown: Config.options.bar.resources.alwaysShowCpuTemp
                    percentage: ResourceUsage.cpuTemp / 100
                    Layout.leftMargin: shown ? 6 : 0
                }
                Resource {
                    iconName: "hard_drive"
                    shown: Config.options.bar.resources.alwaysShowDisk
                    percentage: ResourceUsage.diskUsedPercentage
                    Layout.leftMargin: shown ? 6 : 0
                }
                Resource {
                    iconName: "swap_horiz"
                    shown: Config.options.bar.resources.alwaysShowSwap
                    percentage: ResourceUsage.swapUsedPercentage
                    Layout.leftMargin: shown ? 6 : 0
                    warningThreshold: Config.options.bar.resources.swapWarningThreshold
                }
            }
        }

        Loader {
            id: colLoader
            active: root.vertical
            visible: active
            anchors.centerIn: parent
            sourceComponent: ColumnLayout {
                spacing: root.isMaterial ? 7 : 5
                Resource {
                    Layout.alignment: Qt.AlignHCenter
                    iconName: "memory"
                    vertical: true
                    visible: Config.options.bar.resources.alwaysShowRam
                    percentage: ResourceUsage.memoryUsedPercentage
                    warningThreshold: Config.options.bar.resources.memoryWarningThreshold
                }
                Resource {
                    Layout.alignment: Qt.AlignHCenter
                    iconName: "planner_review"
                    vertical: true
                    visible: Config.options.bar.resources.alwaysShowCpu
                    percentage: ResourceUsage.cpuUsage
                    warningThreshold: Config.options.bar.resources.cpuWarningThreshold
                }
                Resource {
                    Layout.alignment: Qt.AlignHCenter
                    iconName: "thermostat"
                    vertical: true
                    visible: Config.options.bar.resources.alwaysShowCpuTemp
                    percentage: ResourceUsage.cpuTemp / 100
                }
                Resource {
                    Layout.alignment: Qt.AlignHCenter
                    iconName: "hard_drive"
                    vertical: true
                    visible: Config.options.bar.resources.alwaysShowDisk
                    percentage: ResourceUsage.diskUsedPercentage
                }
                Resource {
                    Layout.alignment: Qt.AlignHCenter
                    iconName: "swap_horiz"
                    vertical: true
                    visible: Config.options.bar.resources.alwaysShowSwap
                    percentage: ResourceUsage.swapUsedPercentage
                    warningThreshold: Config.options.bar.resources.swapWarningThreshold
                }
            }
        }

        ResourcesPopup {
            hoverTarget: root
        }
    }
}
