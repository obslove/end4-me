import qs
import qs.services
import qs.modules.common
import qs.modules.common.models
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import Qt5Compat.GraphicalEffects

Item {
    id: root
    property bool vertical: Config.options.bar.vertical
    property bool borderless: Config.options.bar.borderless
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.QsWindow.window?.screen)
    readonly property Toplevel activeWindow: ToplevelManager.activeToplevel
    readonly property int effectiveActiveWorkspaceId: monitor?.activeWorkspace?.id ?? 1
    
    readonly property int workspacesShown: Config.options.bar.workspaces.shown
    readonly property int workspaceGroup: Math.floor((effectiveActiveWorkspaceId - 1) / root.workspacesShown)
    readonly property bool dynamicWorkspaces: Config.options.bar.workspaces.dynamicWorkspaces
    property list<bool> workspaceOccupied: []
    property int widgetPadding: 4
    property int workspaceButtonWidth: Config.options.bar.cornerStyle === 3 ? 30 : 26
    property real activeWorkspaceMargin: Config.options.bar.cornerStyle === 3 ? 3 : 2
    property real workspaceIconSize: workspaceButtonWidth * 0.69
    property real workspaceIconSizeShrinked: workspaceButtonWidth * 0.55
    property real workspaceIconOpacityShrinked: 1
    property real workspaceIconMarginShrinked: -4
    property int workspaceIndexInGroup: (effectiveActiveWorkspaceId - 1) % root.workspacesShown
    readonly property var visibleWorkspaceIndexes: computeVisibleWorkspaceIndexes()
    readonly property int visibleWorkspaceCount: Math.max(1, visibleWorkspaceIndexes.length)
    readonly property int visibleActiveIndex: Math.max(0, visibleWorkspaceIndexes.indexOf(workspaceIndexInGroup))
    readonly property real targetWorkspaceSpan: root.workspaceButtonWidth * root.visibleWorkspaceCount
    property real workspaceSpan: targetWorkspaceSpan
    property bool workspaceLayoutTransitioning: false
    clip: true

    onTargetWorkspaceSpanChanged: {
        workspaceSpan = targetWorkspaceSpan
    }

    onDynamicWorkspacesChanged: {
        workspaceLayoutTransitioning = true
        workspaceLayoutTransitionTimer.restart()
    }

    Timer {
        id: workspaceLayoutTransitionTimer
        interval: Appearance.animation.elementResize.duration + 50
        repeat: false
        onTriggered: root.workspaceLayoutTransitioning = false
    }

    function isWorkspaceVisible(index) {
        if (!root.dynamicWorkspaces) return true
        return index === root.workspaceIndexInGroup || root.workspaceOccupied[index]
    }

    function computeVisibleWorkspaceIndexes() {
        let indexes = []
        for (let i = 0; i < root.workspacesShown; i++) {
            if (root.isWorkspaceVisible(i))
                indexes.push(i)
        }
        return indexes.length > 0 ? indexes : [root.workspaceIndexInGroup]
    }

    property bool showNumbers: false
    Timer {
        id: showNumbersTimer
        interval: (Config?.options.bar.workspaces.showNumberDelay ?? 100)
        repeat: false
        onTriggered: {
            root.showNumbers = true
        }
    }
    Connections {
        target: GlobalStates
        function onSuperDownChanged() {
            if (!Config?.options.bar.autoHide.showWhenPressingSuper.enable) return;
            if (GlobalStates.superDown) showNumbersTimer.restart();
            else {
                showNumbersTimer.stop();
                root.showNumbers = false;
            }
        }
        function onSuperReleaseMightTriggerChanged() { 
            showNumbersTimer.stop()
        }
    }

    // Function to update workspaceOccupied
    function updateWorkspaceOccupied() {
        workspaceOccupied = Array.from({ length: root.workspacesShown }, (_, i) => {
            return Hyprland.workspaces.values.some(ws => ws.id === workspaceGroup * root.workspacesShown + i + 1);
        })
    }

    // Occupied workspace updates
    Component.onCompleted: updateWorkspaceOccupied()
    Connections {
        target: Hyprland.workspaces
        function onValuesChanged() {
            updateWorkspaceOccupied();
        }
    }
    Connections {
        target: Hyprland
        function onFocusedWorkspaceChanged() {
            updateWorkspaceOccupied();
        }
    }
    onWorkspaceGroupChanged: {
        updateWorkspaceOccupied();
    }

    implicitWidth: root.vertical ? Appearance.sizes.verticalBarWidth : root.workspaceSpan
    implicitHeight: root.vertical ? root.workspaceSpan : Appearance.sizes.barHeight

    Behavior on workspaceSpan {
        animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
    }

    // Scroll to switch workspaces
    WheelHandler {
        onWheel: (event) => {
            if (event.angleDelta.y < 0)
                Hyprland.dispatch(`hl.dsp.focus({workspace = "r+1"})`);
            else if (event.angleDelta.y > 0)
                Hyprland.dispatch(`hl.dsp.focus({workspace = "r-1"})`);
        }
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.BackButton
        onPressed: (event) => {
            if (event.button === Qt.BackButton) {
                Hyprland.dispatch(`hl.dsp.workspace.toggle_special("special")`);
            } 
        }
    }

    // Workspaces - background
    Grid {
        z: 1
        width: implicitWidth
        height: implicitHeight
        x: root.vertical ? Math.round((parent.width - width) / 2) : 0
        y: root.vertical ? 0 : Math.round((parent.height - height) / 2)

        rowSpacing: 0
        columnSpacing: 0
        columns: root.vertical ? 1 : root.workspacesShown
        rows: root.vertical ? root.workspacesShown : 1

        Repeater {
            model: root.workspacesShown

            Rectangle {
                z: 1
                property int workspaceIndex: index
                property int workspaceValue: root.workspaceGroup * root.workspacesShown + workspaceIndex + 1
                property bool workspaceVisible: root.isWorkspaceVisible(workspaceIndex)
                implicitWidth: root.vertical ? workspaceButtonWidth : (workspaceVisible ? workspaceButtonWidth : 0)
                implicitHeight: root.vertical ? (workspaceVisible ? workspaceButtonWidth : 0) : workspaceButtonWidth
                radius: Appearance.rounding.full
                property var previousOccupied: (workspaceOccupied[workspaceIndex - 1] && !(!activeWindow?.activated && root.effectiveActiveWorkspaceId === workspaceValue - 1))
                property var rightOccupied: (workspaceOccupied[workspaceIndex + 1] && !(!activeWindow?.activated && root.effectiveActiveWorkspaceId === workspaceValue + 1))
                property var radiusPrev: previousOccupied ? Appearance.rounding.none : Appearance.rounding.full
                property var radiusNext: rightOccupied ? Appearance.rounding.none : Appearance.rounding.full

                topLeftRadius: radiusPrev
                bottomLeftRadius: root.vertical ? radiusNext : radiusPrev
                topRightRadius: root.vertical ? radiusPrev : radiusNext
                bottomRightRadius: radiusNext
                
                color: Config.options.bar.cornerStyle === 3 ? Appearance.colors.colPrimaryContainer : ColorUtils.transparentize(Appearance.m3colors.m3secondaryContainer, 0.4)
                opacity: (workspaceOccupied[workspaceIndex] && !(!activeWindow?.activated && root.effectiveActiveWorkspaceId === workspaceValue)) ? 1 : 0

                Behavior on opacity {
                    animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
                }
                Behavior on radiusPrev {
                    animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
                }

                Behavior on radiusNext {
                    animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
                }

            }

        }

    }

    // Active workspace
    Rectangle {
        z: 2
        // Make active ws indicator, which has a brighter color, smaller to look like it is of the same size as ws occupied highlight
        radius: Appearance.rounding.full
        color: Appearance.colors.colPrimary

        anchors {
            verticalCenter: vertical ? undefined : parent.verticalCenter
            horizontalCenter: vertical ? parent.horizontalCenter : undefined
        }

        AnimatedTabIndexPair {
            id: idxPair
            index: root.visibleActiveIndex
            idx1Duration: root.workspaceLayoutTransitioning ? 0 : 100
            idx2Duration: root.workspaceLayoutTransitioning ? 0 : 300
        }
        property real indicatorPosition: Math.min(idxPair.idx1, idxPair.idx2) * workspaceButtonWidth + root.activeWorkspaceMargin
        property real indicatorLength: Math.abs(idxPair.idx1 - idxPair.idx2) * workspaceButtonWidth + workspaceButtonWidth - root.activeWorkspaceMargin * 2
        property real indicatorThickness: workspaceButtonWidth - root.activeWorkspaceMargin * 2

        x: root.vertical ? null : indicatorPosition
        implicitWidth: root.vertical ? indicatorThickness : indicatorLength
        y: root.vertical ? indicatorPosition : null
        implicitHeight: root.vertical ? indicatorLength : indicatorThickness

    }

    // Workspaces - numbers
    Grid {
        z: 3

        columns: root.vertical ? 1 : root.workspacesShown
        rows: root.vertical ? root.workspacesShown : 1
        columnSpacing: 0
        rowSpacing: 0

        anchors.fill: parent

        Repeater {
            model: root.workspacesShown

            Button {
                id: button
                property int workspaceIndex: index
                property int workspaceValue: workspaceGroup * root.workspacesShown + workspaceIndex + 1
                property bool workspaceVisible: root.isWorkspaceVisible(workspaceIndex)
                implicitHeight: vertical ? (workspaceVisible ? workspaceButtonWidth : 0) : Appearance.sizes.barHeight
                implicitWidth: vertical ? Appearance.sizes.verticalBarWidth : (workspaceVisible ? workspaceButtonWidth : 0)
                onPressed: Hyprland.dispatch(`hl.dsp.focus({ workspace = ${workspaceValue} })`)
                width: vertical ? undefined : implicitWidth
                height: vertical ? implicitHeight : undefined
                enabled: workspaceVisible
                clip: true

                background: Item {
                    id: workspaceButtonBackground
                    implicitWidth: button.workspaceVisible ? workspaceButtonWidth : 0
                    implicitHeight: button.workspaceVisible ? workspaceButtonWidth : 0
                    property var biggestWindow: HyprlandData.biggestWindowForWorkspace(button.workspaceValue)
                    property var mainAppIconSource: Quickshell.iconPath(AppSearch.guessIcon(biggestWindow?.class), "image-missing")

                    StyledText { // Workspace number text
                        opacity: root.showNumbers
                            || ((Config.options?.bar.workspaces.alwaysShowNumbers && (!Config.options?.bar.workspaces.showAppIcons || !workspaceButtonBackground.biggestWindow || root.showNumbers))
                            || (root.showNumbers && !Config.options?.bar.workspaces.showAppIcons)
                            )  ? 1 : 0
                        z: 3

                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font {
                            pixelSize: Appearance.font.pixelSize.small - ((text.length - 1) * (text !== "10") * 2)
                            family: Config.options?.bar.workspaces.useNerdFont ? Appearance.font.family.iconNerd : defaultFont
                        }
                        text: Config.options?.bar.workspaces.numberMap[button.workspaceValue - 1] || button.workspaceValue
                        elide: Text.ElideRight
                        color: (root.effectiveActiveWorkspaceId == button.workspaceValue) ? 
                            Appearance.m3colors.m3onPrimary : 
                            (workspaceOccupied[button.workspaceIndex] ? Appearance.m3colors.m3onSecondaryContainer :
                                Appearance.colors.colOnLayer1Inactive)

                        Behavior on opacity {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }
                    }
                    MaterialSymbol {
                        id: wsDot
                        opacity: (Config.options?.bar.workspaces.alwaysShowNumbers
                            || root.showNumbers
                            || (Config.options?.bar.workspaces.showAppIcons && workspaceButtonBackground.biggestWindow)
                        ) ? 0 : 1
                        visible: opacity > 0
                        anchors.centerIn: parent
                        iconSize: workspaceButtonWidth * 0.55
                        color: (root.effectiveActiveWorkspaceId == button.workspaceValue) ?
                            Appearance.m3colors.m3onPrimary :
                            (workspaceOccupied[button.workspaceIndex] ? Appearance.m3colors.m3onSecondaryContainer :
                                Appearance.colors.colOnLayer1Inactive)
                        text: {
                            switch (button.workspaceValue) {
                                case 1:  return "code"
                                case 2:  return "public"
                                case 3:  return "music_note"
                                case 4:  return "edit_square"
                                case 5:  return "image"
                                case 6:  return "forum"
                                case 7:  return "browser_updated"
                                case 8:  return "finance_mode"
                                case 9:  return "monitor"
                                case 10: return "analytics"
                                default: return "circle"
                            }
                        }
                        Behavior on opacity {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }
                    }
                    Item { // Main app icon
                        anchors.centerIn: parent
                        width: workspaceButtonWidth
                        height: workspaceButtonWidth
                        opacity: !Config.options?.bar.workspaces.showAppIcons ? 0 :
                            (workspaceButtonBackground.biggestWindow && !root.showNumbers && Config.options?.bar.workspaces.showAppIcons) ? 
                            1 : workspaceButtonBackground.biggestWindow ? workspaceIconOpacityShrinked : 0
                            visible: opacity > 0
                        IconImage {
                            id: mainAppIcon
                            anchors.bottom: parent.bottom
                            anchors.right: parent.right
                            anchors.bottomMargin: (!root.showNumbers && Config.options?.bar.workspaces.showAppIcons) ? 
                                (workspaceButtonWidth - workspaceIconSize) / 2 : workspaceIconMarginShrinked
                            anchors.rightMargin: (!root.showNumbers && Config.options?.bar.workspaces.showAppIcons) ? 
                                (workspaceButtonWidth - workspaceIconSize) / 2 : workspaceIconMarginShrinked

                            source: workspaceButtonBackground.mainAppIconSource
                            implicitSize: (!root.showNumbers && Config.options?.bar.workspaces.showAppIcons) ? workspaceIconSize : workspaceIconSizeShrinked

                            Behavior on opacity {
                                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                            }
                            Behavior on anchors.bottomMargin {
                                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                            }
                            Behavior on anchors.rightMargin {
                                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                            }
                            Behavior on implicitSize {
                                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                            }
                        }

                        Loader {
                            active: Config.options.bar.workspaces.monochromeIcons
                            anchors.fill: mainAppIcon
                            sourceComponent: Item {
                                Desaturate {
                                    id: desaturatedIcon
                                    visible: false // There's already color overlay
                                    anchors.fill: parent
                                    source: mainAppIcon
                                    desaturation: 0.8
                                }
                                ColorOverlay {
                                    anchors.fill: desaturatedIcon
                                    source: desaturatedIcon
                                    color: ColorUtils.transparentize(wsDot.color, 0.9)
                                }
                            }
                        }
                    }
                }
                

            }

        }

    }

}
