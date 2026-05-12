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
                tooltip: Translation.tr("Choose which active MPRIS player feeds media widgets.")

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
                        const index = model.findIndex(item => {
                            if (item.value === "") {
                                return preferred === "";
                            }

                            const player = MprisController.players.find(candidate => MprisController.playerMatchesId(candidate, item.value));
                            return MprisController.playerMatchesId(player, preferred);
                        });
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

            ConfigSwitch {
                buttonIcon: "filter_list"
                text: Translation.tr("Filter duplicate players")
                checked: Config.options.media.filterDuplicatePlayers
                onCheckedChanged: {
                    Config.options.media.filterDuplicatePlayers = checked;
                }
            }
        }

        ContentSection {
            icon: "lyrics"
            shape: MaterialShape.Shape.Cookie6Sided
            title: Translation.tr("Lyrics")

            ConfigSwitch {
                buttonIcon: "lyrics"
                text: Translation.tr("Enable lyrics")
                checked: Config.options.lyricsService.enable
                onCheckedChanged: {
                    Config.options.lyricsService.enable = checked;
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
                enabled: Config.options.lyricsService.enable
                icon: "format_size"
                text: Translation.tr("Font size")
                value: Config.options.lyricsService.fontSize
                from: 12
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
                ConfigRow {
                    uniform: true
                    MaterialTextArea {
                        Layout.fillWidth: true
                        placeholderText: Translation.tr("Apps")
                        text: Config.options.search.prefix.app
                        wrapMode: TextEdit.Wrap
                        onTextChanged: {
                            Config.options.search.prefix.app = text;
                        }
                    }
                    MaterialTextArea {
                        Layout.fillWidth: true
                        placeholderText: Translation.tr("Keybinds")
                        text: Config.options.search.prefix.keybinds
                        wrapMode: TextEdit.Wrap
                        onTextChanged: {
                            Config.options.search.prefix.keybinds = text;
                        }
                    }
                    MaterialTextArea {
                        Layout.fillWidth: true
                        placeholderText: Translation.tr("Math")
                        text: Config.options.search.prefix.math
                        wrapMode: TextEdit.Wrap
                        onTextChanged: {
                            Config.options.search.prefix.math = text;
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
