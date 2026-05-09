pragma Singleton
pragma ComponentBehavior: Bound

// From https://git.outfoxxed.me/outfoxxed/nixnew
// It does not have a license, but the author is okay with redistribution.

import QtQml.Models
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.modules.common

/**
 * A service that provides easy access to the active Mpris player.
 */
Singleton {
	id: root;
	property list<MprisPlayer> players: Mpris.players.values.filter(player => isRealPlayer(player));
	property MprisPlayer trackedPlayer: null;
	readonly property MprisPlayer preferredPlayer: findPreferredPlayer();
	property MprisPlayer activePlayer: preferredPlayer ?? (isSelectablePlayer(trackedPlayer) ? trackedPlayer : null) ?? players[0] ?? null;
	signal trackChanged(reverse: bool);

	property bool __reverse: false;

	property var activeTrack;
	property int positionTick: 0;
	property string seekingPlayerId: "";
	property real seekingPosition: 0;

	readonly property bool hasActivePlasmaIntegration: Mpris.players.values.some(
		p => p.dbusName?.startsWith('org.mpris.MediaPlayer2.plasma-browser-integration')
	)
	function isRealPlayer(player) {
        if (!player) {
            return false;
        }
        if (!Config.options.media.filterDuplicatePlayers) {
            return true;
        }
        return (
            // Remove native browser buses only if plasma-browser-integration is actually active on D-Bus
            !(hasActivePlasmaIntegration && player.dbusName.startsWith('org.mpris.MediaPlayer2.firefox')) && !(hasActivePlasmaIntegration && player.dbusName.startsWith('org.mpris.MediaPlayer2.chromium')) &&
            // playerctld just copies other buses and we don't need duplicates
            !player.dbusName?.startsWith('org.mpris.MediaPlayer2.playerctld') &&
            // Non-instance mpd bus
            !(player.dbusName?.endsWith('.mpd') && !player.dbusName.endsWith('MediaPlayer2.mpd')));
    }

	function normalizePlayerId(id) {
		return String(id ?? "")
			.trim()
			.toLowerCase()
			.replace(/^org\.mpris\.mediaplayer2\./, "")
			.replace(/\.instance\d+$/, "");
	}

	function playerId(player) {
		if (!player) {
			return "";
		}

		return player.dbusName || player.desktopEntry || player.identity || "";
	}

	function playerName(player) {
		if (!player) {
			return Translation.tr("Unknown player");
		}

		return player.identity || player.desktopEntry || normalizePlayerId(player.dbusName) || Translation.tr("Unknown player");
	}

	function playerAliases(player) {
		if (!player) {
			return [];
		}

		const aliases = [];
		const add = value => {
			const normalized = normalizePlayerId(value);
			if (normalized.length > 0 && !aliases.includes(normalized)) {
				aliases.push(normalized);
			}
		};

		add(player.dbusName);
		add(player.desktopEntry);
		add(player.identity);
		add(player.uniqueId);
		add(playerId(player));

		return aliases;
	}

	function playerMatchesId(player, id) {
		const normalized = normalizePlayerId(id);
		return normalized.length > 0 && playerAliases(player).includes(normalized);
	}

	function isSeekingPlayer(player) {
		return seekingPlayerId.length > 0 && playerMatchesId(player, seekingPlayerId);
	}

	function displayPosition(player) {
		if (positionTick < 0) {
			return 0;
		}
		if (!player) {
			return 0;
		}
		if (isSeekingPlayer(player)) {
			return seekingPosition;
		}
		return Math.max(0, player.position ?? 0);
	}

	function beginSeek(player, position) {
		if (!player) {
			return;
		}
		seekingPlayerId = playerId(player);
		seekingPosition = Math.max(0, position ?? 0);
		positionTick++;
	}

	function updateSeek(player, position) {
		if (!player || !isSeekingPlayer(player)) {
			return;
		}
		seekingPosition = Math.max(0, position ?? 0);
		positionTick++;
	}

	function finishSeek(player, position, resumePlayback) {
		if (!player) {
			return;
		}

		const targetPosition = Math.max(0, position ?? 0);
		player.position = targetPosition;
		player.positionChanged();
		seekingPlayerId = "";
		seekingPosition = 0;
		positionTick++;

		if (resumePlayback) {
			Qt.callLater(() => {
				if (player.canPlay) {
					player.play();
				} else if (player.canTogglePlaying && !player.isPlaying) {
					player.togglePlaying();
				}
			});
		}
	}

	function isSelectablePlayer(player) {
		return player && players.some(candidate => playerMatchesId(candidate, playerId(player)));
	}

	function findPreferredPlayer() {
		const preferred = Config.options.media.preferredPlayer ?? "";
		if (preferred.length === 0) {
			return null;
		}

		return players.find(player => playerMatchesId(player, preferred)) ?? null;
	}

	// Original stuff from fox below
	Timer {
		interval: 250
		repeat: true
		running: root.players.length > 0 || root.seekingPlayerId.length > 0
		onTriggered: {
			for (const player of root.players) {
				if (player.playbackState == MprisPlaybackState.Playing) {
					player.positionChanged();
				}
			}
			root.positionTick++;
		}
	}

	Instantiator {
		model: Mpris.players;

		Connections {
			required property MprisPlayer modelData;
			target: modelData;

			Component.onCompleted: {
				if (root.isRealPlayer(modelData) && (root.trackedPlayer == null || modelData.isPlaying)) {
					root.trackedPlayer = modelData;
				}
			}

			Component.onDestruction: {
				if (root.trackedPlayer == null || !root.trackedPlayer.isPlaying) {
					for (const player of root.players) {
						if (player.playbackState.isPlaying) {
							root.trackedPlayer = player;
							break;
						}
					}

					if (trackedPlayer == null && Mpris.players.values.length != 0) {
						trackedPlayer = root.players[0] ?? null;
					}
				}
			}

			function onPlaybackStateChanged() {
				if (root.isRealPlayer(modelData) && root.trackedPlayer !== modelData) root.trackedPlayer = modelData;
			}
		}
	}

	Connections {
		target: activePlayer

		function onPostTrackChanged() {
			root.updateTrack();
		}

		function onTrackArtUrlChanged() {
			// console.log("arturl:", activePlayer.trackArtUrl)
			// root.updateTrack();
			if (root.activePlayer.uniqueId == root.activeTrack.uniqueId && root.activePlayer.trackArtUrl != root.activeTrack.artUrl) {
				// cantata likes to send cover updates *BEFORE* updating the track info.
				// as such, art url changes shouldn't be able to break the reverse animation
				const r = root.__reverse;
				root.updateTrack();
				root.__reverse = r;

			}
		}
	}

	onActivePlayerChanged: this.updateTrack();

	function updateTrack() {
		//console.log(`update: ${this.activePlayer?.trackTitle ?? ""} : ${this.activePlayer?.trackArtists}`)
		this.activeTrack = {
			uniqueId: this.activePlayer?.uniqueId ?? 0,
			artUrl: this.activePlayer?.trackArtUrl ?? "",
			title: this.activePlayer?.trackTitle || Translation.tr("Unknown Title"),
			artist: this.activePlayer?.trackArtist || Translation.tr("Unknown Artist"),
			album: this.activePlayer?.trackAlbum || Translation.tr("Unknown Album"),
		};

		this.trackChanged(__reverse);
		this.__reverse = false;
	}

	property bool isPlaying: this.activePlayer && this.activePlayer.isPlaying;
	property bool canTogglePlaying: this.activePlayer?.canTogglePlaying ?? false;
	function togglePlaying() {
		if (this.canTogglePlaying) this.activePlayer.togglePlaying();
	}

	property bool canGoPrevious: this.activePlayer?.canGoPrevious ?? false;
	function previous() {
		if (this.canGoPrevious) {
			this.__reverse = true;
			this.activePlayer.previous();
		}
	}

	property bool canGoNext: this.activePlayer?.canGoNext ?? false;
	function next() {
		if (this.canGoNext) {
			this.__reverse = false;
			this.activePlayer.next();
		}
	}

	property bool canChangeVolume: this.activePlayer && this.activePlayer.volumeSupported && this.activePlayer.canControl;

	property bool loopSupported: this.activePlayer && this.activePlayer.loopSupported && this.activePlayer.canControl;
	property var loopState: this.activePlayer?.loopState ?? MprisLoopState.None;
	function setLoopState(loopState: var) {
		if (this.loopSupported) {
			this.activePlayer.loopState = loopState;
		}
	}

	property bool shuffleSupported: this.activePlayer && this.activePlayer.shuffleSupported && this.activePlayer.canControl;
	property bool hasShuffle: this.activePlayer?.shuffle ?? false;
	function setShuffle(shuffle: bool) {
		if (this.shuffleSupported) {
			this.activePlayer.shuffle = shuffle;
		}
	}

	function setActivePlayer(player: MprisPlayer) {
		const targetPlayer = player ?? root.players[0];
		console.log(`[Mpris] Active player ${targetPlayer} << ${activePlayer}`)

		if (targetPlayer && this.activePlayer) {
			this.__reverse = root.players.indexOf(targetPlayer) < root.players.indexOf(this.activePlayer);
		} else {
			// always animate forward if going to null
			this.__reverse = false;
		}

		this.trackedPlayer = targetPlayer;
	}

	IpcHandler {
		target: "mpris"

		function pauseAll(): void {
			for (const player of Mpris.players.values) {
				if (player.canPause) player.pause();
			}
		}

		function playPause(): void { root.togglePlaying(); }
		function previous(): void { root.previous(); }
		function next(): void { root.next(); }
	}
}
