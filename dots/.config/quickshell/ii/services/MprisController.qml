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
	property string preferredPlayerId: Config.options.media.preferredPlayer ?? "";
	property MprisPlayer preferredPlayer: preferredPlayerId.length > 0 ? players.find(player => playerId(player) === preferredPlayerId) ?? null : null;
	property MprisPlayer activePlayer: preferredPlayer ?? trackedPlayer ?? players[0] ?? null;
	signal trackChanged(reverse: bool);

	property bool __reverse: false;

	property var activeTrack;

	readonly property bool hasActivePlasmaIntegration: Mpris.players.values.some(
		p => p.dbusName?.startsWith('org.mpris.MediaPlayer2.plasma-browser-integration')
	)
	function isRealPlayer(player) {
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

	function playerId(player) {
		return player?.desktopEntry || player?.identity || player?.dbusName || String(player?.uniqueId ?? "");
	}

	function playerName(player) {
		return player?.identity || player?.desktopEntry || player?.dbusName || Translation.tr("Unknown Player");
	}

	function selectPreferredPlayer(player) {
		Config.options.media.preferredPlayer = player ? playerId(player) : "";
		setActivePlayer(player);
	}

	function isPreferredPlayer(player) {
		return preferredPlayerId.length > 0 && playerId(player) === preferredPlayerId;
	}

	function popupPlayerIds() {
		return Config.options.media.popupPlayers ?? [];
	}

	function playerShownInPopup(player) {
		if (isPreferredPlayer(player)) {
			return true;
		}
		if (Config.options.media.popupAllPlayers) {
			return true;
		}
		return Array.from(popupPlayerIds()).includes(playerId(player));
	}

	function pinPreferredPlayer(players) {
		if (!preferredPlayer) {
			return players;
		}

		const preferredId = playerId(preferredPlayer);
		const rest = players.filter(player => playerId(player) !== preferredId);
		return [preferredPlayer, ...rest];
	}

	function selectedPopupPlayers() {
		const ids = Array.from(popupPlayerIds());
		return pinPreferredPlayer(players.filter(player => isPreferredPlayer(player) || ids.includes(playerId(player))));
	}

	function availablePopupPlayers() {
		const ids = Array.from(popupPlayerIds());
		return players.filter(player => !isPreferredPlayer(player) && !ids.includes(playerId(player)));
	}

	function setPlayerShownInPopup(player, shown) {
		const id = playerId(player);
		if (!id) {
			return;
		}

		let ids = Array.from(popupPlayerIds());
		const index = ids.indexOf(id);
		if (shown && index < 0) {
			ids.push(id);
		} else if (!shown && index >= 0) {
			ids.splice(index, 1);
		}
		Config.options.media.popupPlayers = ids;
	}

	function selectAllPopupPlayers() {
		Config.options.media.popupPlayers = players.map(player => playerId(player));
	}

	function fallbackPlayer() {
		return players.find(player => player.playbackState.isPlaying) ?? players[0] ?? null;
	}

	onPreferredPlayerIdChanged: {
		if (preferredPlayerId.length === 0 && (!trackedPlayer || players.indexOf(trackedPlayer) < 0)) {
			trackedPlayer = fallbackPlayer();
		}
	}

	// Original stuff from fox below
	Instantiator {
		model: Mpris.players;

		Connections {
			required property MprisPlayer modelData;
			target: modelData;

			Component.onCompleted: {
				if (root.preferredPlayerId.length === 0 && root.isRealPlayer(modelData) && (root.trackedPlayer == null || modelData.isPlaying)) {
					root.trackedPlayer = modelData;
				}
			}

			Component.onDestruction: {
				if (root.preferredPlayerId.length === 0 && (root.trackedPlayer == null || !root.trackedPlayer.isPlaying)) {
					root.trackedPlayer = root.fallbackPlayer();
				}
			}

			function onPlaybackStateChanged() {
				if (root.preferredPlayerId.length === 0 && root.isRealPlayer(modelData) && root.trackedPlayer !== modelData) root.trackedPlayer = modelData;
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
		const targetPlayer = player ?? players[0];
		console.log(`[Mpris] Active player ${targetPlayer} << ${activePlayer}`)

		if (targetPlayer && this.activePlayer) {
			this.__reverse = players.indexOf(targetPlayer) < players.indexOf(this.activePlayer);
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
