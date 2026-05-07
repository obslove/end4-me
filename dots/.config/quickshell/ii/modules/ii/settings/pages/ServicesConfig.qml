import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    id: page
    forceWidth: true

    //This was intended to go into the results more deeply but in the end I didn't like it but I left it just in case lol
    function goTo(term) {
        const t = term.toLowerCase().trim()

        function findTarget(rootItem) {
            for (let i = 0; i < rootItem.children.length; i++) {
                let child = rootItem.children[i]
                if (child.title && child.title.toLowerCase().includes(t)) {
                    return child
                }
            }

            for (let i = 0; i < rootItem.children.length; i++) {
                let found = findTarget(rootItem.children[i])
                if (found) return found
            }
            return null
        }

        let target = findTarget(mainLayout)
        if (target) {
            let pos = target.mapToItem(mainLayout, 0, 0)
            page.contentY = Math.max(0, pos.y - 0)
        }
    }

    ColumnLayout {
        id: mainLayout 
        Layout.fillWidth: true   
        Layout.fillHeight: true
        spacing: 20

        ContentSection {
            icon: "neurology"
            shape: MaterialShape.Shape.Ghostish
            title: Translation.tr("AI")

            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("System prompt")
                text: Config.options.ai.systemPrompt
                wrapMode: TextEdit.Wrap
                onTextChanged: {
                    Qt.callLater(() => {
                        Config.options.ai.systemPrompt = text;
                    });
                }
            }
        }

        ContentSection {
            icon: "album"
            shape: MaterialShape.Shape.Puffy
            title: Translation.tr("Media")

            ContentSubsection {
                title: Translation.tr("Primary player")
                tooltip: Translation.tr("Choose which active MPRIS player feeds the bar, dock, background, lock screen and media controls.")

                StyledComboBox {
                    id: primaryPlayerSelector
                    buttonIcon: "music_note"
                    textRole: "displayName"
                    enabled: MprisController.players.length > 0
                    model: [
                        {
                            displayName: Translation.tr("Automatic"),
                            value: "",
                            icon: "auto_awesome"
                        },
                        ...MprisController.players.map(player => {
                            return {
                                displayName: MprisController.playerName(player),
                                value: MprisController.playerId(player),
                                icon: player.isPlaying ? "pause_circle" : "music_note"
                            };
                        })
                    ]
                    currentIndex: {
                        const preferred = Config.options.media.preferredPlayer ?? "";
                        const index = model.findIndex(item => item.value === preferred);
                        return index >= 0 ? index : 0;
                    }
                    onActivated: index => {
                        Config.options.media.preferredPlayer = model[index]?.value ?? "";
                    }
                }

                NoticeBox {
                    visible: MprisController.players.length === 0
                    Layout.fillWidth: true
                    materialIcon: "music_off"
                    text: Translation.tr("No active player")
                }
            }

            ContentSubsection {
                title: Translation.tr("Popup players")
                tooltip: Translation.tr("Choose which active MPRIS players are shown in the media popup.")

                StyledComboBox {
                    id: popupPlayerModeSelector
                    buttonIcon: "queue_music"
                    textRole: "displayName"
                    model: [
                        {
                            displayName: Translation.tr("All active players"),
                            value: true,
                            icon: "select_all"
                        },
                        {
                            displayName: Translation.tr("Custom selection"),
                            value: false,
                            icon: "playlist_add_check"
                        }
                    ]
                    currentIndex: Config.options.media.popupAllPlayers ? 0 : 1
                    onActivated: index => {
                        Config.options.media.popupAllPlayers = model[index]?.value ?? true;
                        if (!Config.options.media.popupAllPlayers && Config.options.media.popupPlayers.length === 0) {
                            MprisController.selectAllPopupPlayers();
                        }
                    }
                }

                ColumnLayout {
                    visible: !Config.options.media.popupAllPlayers
                    Layout.fillWidth: true
                    Layout.preferredHeight: visible ? implicitHeight : 0
                    spacing: 8

                    StyledComboBox {
                        id: popupPlayerAddSelector
                        buttonIcon: "playlist_add"
                        textRole: "displayName"
                        enabled: MprisController.availablePopupPlayers().length > 0
                        model: [
                            {
                                displayName: MprisController.availablePopupPlayers().length > 0
                                    ? Translation.tr("Add player to popup")
                                    : Translation.tr("All players selected"),
                                value: "",
                                icon: MprisController.availablePopupPlayers().length > 0 ? "playlist_add" : "check"
                            },
                            ...MprisController.availablePopupPlayers().map(player => {
                                return {
                                    displayName: MprisController.playerName(player),
                                    value: MprisController.playerId(player),
                                    icon: player.isPlaying ? "pause_circle" : "music_note"
                                };
                            })
                        ]
                        currentIndex: 0
                        onActivated: index => {
                            if (index <= 0) {
                                return;
                            }
                            const player = MprisController.availablePopupPlayers()[index - 1];
                            MprisController.setPlayerShownInPopup(player, true);
                            Qt.callLater(() => popupPlayerAddSelector.currentIndex = 0);
                        }
                    }

                    Flow {
                        Layout.fillWidth: true
                        spacing: 6

                        Repeater {
                            model: MprisController.selectedPopupPlayers().length

                            RippleButton {
                                required property int index
                                readonly property var player: MprisController.selectedPopupPlayers()[index]
                                readonly property bool fixedPlayer: MprisController.isPreferredPlayer(player)

                                buttonRadius: height / 2
                                colBackground: Appearance.colors.colSecondaryContainer
                                colBackgroundHover: Appearance.colors.colSecondaryContainerHover
                                colRipple: Appearance.colors.colSecondaryContainerActive
                                implicitHeight: 36
                                implicitWidth: chipLayout.implicitWidth + 24
                                onClicked: {
                                    if (!fixedPlayer) {
                                        MprisController.setPlayerShownInPopup(player, false);
                                    }
                                }

                                contentItem: RowLayout {
                                    id: chipLayout
                                    spacing: 8

                                    MaterialSymbol {
                                        text: player?.isPlaying ? "pause_circle" : "music_note"
                                        iconSize: Appearance.font.pixelSize.larger
                                        color: Appearance.colors.colOnSecondaryContainer
                                    }

                                    StyledText {
                                        text: MprisController.playerName(player)
                                        color: Appearance.colors.colOnSecondaryContainer
                                        font.pixelSize: Appearance.font.pixelSize.small
                                    }

                                    MaterialSymbol {
                                        text: fixedPlayer ? "push_pin" : "close"
                                        iconSize: Appearance.font.pixelSize.large
                                        color: Appearance.colors.colOnSecondaryContainer
                                    }
                                }
                            }
                        }
                    }

                    NoticeBox {
                        visible: MprisController.selectedPopupPlayers().length === 0 && MprisController.players.length > 0
                        Layout.fillWidth: true
                        materialIcon: "playlist_remove"
                        text: Translation.tr("No player selected for the popup")
                    }
                }

                NoticeBox {
                    visible: MprisController.players.length === 0
                    Layout.fillWidth: true
                    materialIcon: "music_off"
                    text: Translation.tr("No active player")
                }
            }

            ConfigSwitch {
                buttonIcon: "filter_list"
                text: Translation.tr("Filter duplicate players")
                checked: Config.options.media.filterDuplicatePlayers
                onCheckedChanged: {
                    Config.options.media.filterDuplicatePlayers = checked;
                }
                StyledToolTip {
                    text: Translation.tr("Attempt to remove dupes (the aggregator playerctl one and browsers' native ones when there's plasma browser integration)")
                }
            }
        }

        ContentSection {
            icon: "lyrics"
            shape: MaterialShape.Shape.Cookie6Sided
            title: Translation.tr("Lyrics")

            ConfigSwitch {
                buttonIcon: "lyrics"
                text: Translation.tr("Enable lyrics service")
                checked: Config.options.lyricsService.enable
                onCheckedChanged: {
                    Config.options.lyricsService.enable = checked;
                }
                StyledToolTip {
                    text: Translation.tr("Disabling this prevents lyrics widgets from calling external lyrics APIs.")
                }
            }

            ConfigSwitch {
                enabled: Config.options.lyricsService.enable
                buttonIcon: "library_books"
                text: Translation.tr("Use LRCLIB synced lyrics")
                checked: Config.options.lyricsService.enableLrclib
                onCheckedChanged: {
                    Config.options.lyricsService.enableLrclib = checked;
                }
            }

            ContentSubsection {
                title: Translation.tr("Style")

                ConfigSelectionArray {
                    currentValue: Config.options.lyricsService.style
                    onSelected: newValue => {
                        Config.options.lyricsService.style = newValue;
                    }
                    options: [
                        {
                            displayName: Translation.tr("Scroller"),
                            icon: "keyboard_double_arrow_up",
                            value: "scroller"
                        },
                        {
                            displayName: Translation.tr("Static"),
                            icon: "format_size",
                            value: "static"
                        }
                    ]
                }
            }

            ConfigSwitch {
                enabled: Config.options.lyricsService.enable && Config.options.lyricsService.style !== "static"
                buttonIcon: "gradient"
                text: Translation.tr("Use scroller mask")
                checked: Config.options.lyricsService.useGradientMask
                onCheckedChanged: {
                    Config.options.lyricsService.useGradientMask = checked;
                }
            }

            ConfigSpinBox {
                icon: "format_size"
                text: Translation.tr("Lyrics font size (px)")
                value: Config.options.lyricsService.fontSize
                from: 10
                to: 32
                stepSize: 1
                onValueChanged: {
                    Config.options.lyricsService.fontSize = value;
                }
            }
        }

        ContentSection {
            icon: "music_cast"
            shape: MaterialShape.Shape.Oval
            title: Translation.tr("Music Recognition")

            ConfigSpinBox {
                icon: "timer_off"
                text: Translation.tr("Total duration timeout (s)")
                value: Config.options.musicRecognition.timeout
                from: 10
                to: 100
                stepSize: 2
                onValueChanged: {
                    Config.options.musicRecognition.timeout = value;
                }
            }
            ConfigSpinBox {
                icon: "av_timer"
                text: Translation.tr("Polling interval (s)")
                value: Config.options.musicRecognition.interval
                from: 2
                to: 10
                stepSize: 1
                onValueChanged: {
                    Config.options.musicRecognition.interval = value;
                }
            }
        }

        ContentSection {
            icon: "cell_tower"
            shape: MaterialShape.Shape.PixelCircle
            title: Translation.tr("Networking")

            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("User agent (for services that require it)")
                text: Config.options.networking.userAgent
                wrapMode: TextEdit.Wrap
                onTextChanged: {
                    Config.options.networking.userAgent = text;
                }
            }
        }

        ContentSection {
            icon: "file_open"
            shape: MaterialShape.Shape.Slanted
            title: Translation.tr("Save paths")

            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("Video Recording Path")
                text: Config.options.screenRecord.savePath
                wrapMode: TextEdit.Wrap
                onTextChanged: {
                    Config.options.screenRecord.savePath = text;
                }
            }
            
            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("Screenshot Path (leave empty to just copy)")
                text: Config.options.screenSnip.savePath
                wrapMode: TextEdit.Wrap
                onTextChanged: {
                    Config.options.screenSnip.savePath = text;
                }
            }
        }

        ContentSection {
            icon: "search"
            shape: MaterialShape.Shape.Cookie6Sided
            title: Translation.tr("Search")

            ConfigSwitch {
                text: Translation.tr("Use Levenshtein distance-based algorithm instead of fuzzy")
                checked: Config.options.search.sloppy
                onCheckedChanged: {
                    Config.options.search.sloppy = checked;
                }
            }

            ContentSubsection {
                title: Translation.tr("Prefixes")
                ConfigRow {
                    uniform: true
                    MaterialTextArea {
                        Layout.fillWidth: true
                        placeholderText: Translation.tr("Action")
                        text: Config.options.search.prefix.action
                        wrapMode: TextEdit.Wrap
                        onTextChanged: {
                            Config.options.search.prefix.action = text;
                        }
                    }
                    MaterialTextArea {
                        Layout.fillWidth: true
                        placeholderText: Translation.tr("Clipboard")
                        text: Config.options.search.prefix.clipboard
                        wrapMode: TextEdit.Wrap
                        onTextChanged: {
                            Config.options.search.prefix.clipboard = text;
                        }
                    }
                    MaterialTextArea {
                        Layout.fillWidth: true
                        placeholderText: Translation.tr("Emojis")
                        text: Config.options.search.prefix.emojis
                        wrapMode: TextEdit.Wrap
                        onTextChanged: {
                            Config.options.search.prefix.emojis = text;
                        }
                    }
                }

                ConfigRow {
                    uniform: true
                    MaterialTextArea {
                        Layout.fillWidth: true
                        placeholderText: Translation.tr("Icons")
                        text: Config.options.search.prefix.symbols
                        wrapMode: TextEdit.Wrap
                        onTextChanged: {
                            Config.options.search.prefix.symbols = text;
                        }
                    }
                    MaterialTextArea {
                        Layout.fillWidth: true
                        placeholderText: Translation.tr("Shell command")
                        text: Config.options.search.prefix.shellCommand
                        wrapMode: TextEdit.Wrap
                        onTextChanged: {
                            Config.options.search.prefix.shellCommand = text;
                        }
                    }
                    MaterialTextArea {
                        Layout.fillWidth: true
                        placeholderText: Translation.tr("Web search")
                        text: Config.options.search.prefix.webSearch
                        wrapMode: TextEdit.Wrap
                        onTextChanged: {
                            Config.options.search.prefix.webSearch = text;
                        }
                    }
                }
            }
            ContentSubsection {
                title: Translation.tr("Web search")
                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Base URL")
                    text: Config.options.search.engineBaseUrl
                    wrapMode: TextEdit.Wrap
                    onTextChanged: {
                        Config.options.search.engineBaseUrl = text;
                    }
                }
            }
        }

        ContentSection {
             icon: "deployed_code_update"
             title: Translation.tr("System updates (Arch only)")

             ConfigSwitch {
                 text: Translation.tr("Enable update checks")
                 checked: Config.options.updates.enableCheck
                 onCheckedChanged: {
                     Config.options.updates.enableCheck = checked;
                 }
             }

             ConfigSpinBox {
                 icon: "av_timer"
                 text: Translation.tr("Check interval (mins)")
                 value: Config.options.updates.checkInterval
                 from: 60
                 to: 1440
                 stepSize: 60
                 onValueChanged: {
                     Config.options.updates.checkInterval = value;
                 }
             }
        }

        ContentSection {
            icon: "weather_mix"
            shape: MaterialShape.Shape.Pill
            title: Translation.tr("Weather")
            ConfigRow {
                ConfigSwitch {
                    buttonIcon: "assistant_navigation"
                    text: Translation.tr("Enable GPS based location")
                    checked: Config.options.bar.weather.enableGPS
                    onCheckedChanged: {
                        Config.options.bar.weather.enableGPS = checked;
                    }
                }
                ConfigSwitch {
                    buttonIcon: "thermometer"
                    text: Translation.tr("Fahrenheit unit")
                    checked: Config.options.bar.weather.useUSCS
                    onCheckedChanged: {
                        Config.options.bar.weather.useUSCS = checked;
                    }
                }
            }
            
            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("City name")
                text: Config.options.bar.weather.city
                wrapMode: TextEdit.Wrap
                onTextChanged: {
                    Config.options.bar.weather.city = text;
                }
            }
            ConfigSpinBox {
                icon: "av_timer"
                text: Translation.tr("Polling interval (m)")
                value: Config.options.bar.weather.fetchInterval
                from: 5
                to: 50
                stepSize: 5
                onValueChanged: {
                    Config.options.bar.weather.fetchInterval = value;
                }
            }
        }
    }
}
