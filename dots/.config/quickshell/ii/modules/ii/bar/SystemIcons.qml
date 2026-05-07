import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root
    property bool vertical: Config.options.bar.vertical

    implicitWidth: vertical ? Appearance.sizes.verticalBarWidth : flow.implicitWidth + 10
    implicitHeight: vertical ? flow.implicitHeight + 6 : Appearance.sizes.barHeight

    MouseArea {
        anchors.fill: parent
        onPressed: {
            GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen;
        }
    }

    Flow {
        id: flow
        anchors.centerIn: parent
        flow: root.vertical ? Flow.TopToBottom : Flow.LeftToRight
        spacing: root.vertical ? 6 : 10

        MaterialSymbol {
            text: Audio.sink?.audio?.muted ? "volume_off" : "volume_up"
            iconSize: Appearance.font.pixelSize.larger
            color: Appearance.colors.colOnLayer1
        }

        Revealer {
            reveal: Audio.source?.audio?.muted ?? false
            vertical: root.vertical
            MaterialSymbol {
                text: "mic_off"
                iconSize: Appearance.font.pixelSize.larger
                color: Appearance.colors.colOnLayer1
            }
        }

        HyprlandXkbIndicator {
            color: Appearance.colors.colOnLayer1
        }

        MaterialSymbol {
            text: Network.materialSymbol
            iconSize: Appearance.font.pixelSize.larger
            color: Appearance.colors.colOnLayer1
        }

        MaterialSymbol {
            visible: BluetoothStatus.available
            text: BluetoothStatus.connected ? "bluetooth_connected" : BluetoothStatus.enabled ? "bluetooth" : "bluetooth_disabled"
            iconSize: Appearance.font.pixelSize.larger
            color: Appearance.colors.colOnLayer1
        }

        NotificationUnreadCount {
            visible: Notifications.silent || Notifications.unread > 0
        }
    }
}
