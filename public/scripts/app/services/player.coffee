angular.module('ponyfm').factory('player', [
	'$rootScope'
	($rootScope) ->
		readyDef = new $.Deferred()

		play = (track) ->
			self.currentTrack = track
			$rootScope.$broadcast 'player-starting-track', track
			self.currentSound = soundManager.createSound
				url: track.streams.mp3,
				volume: self.volume

				whileloading: () -> $rootScope.safeApply ->
					track.loadingProgress = (self.currentSound.bytesLoaded / self.currentSound.bytesTotal) * 100

				whileplaying: () -> $rootScope.safeApply ->
					track.progressSeconds = self.currentSound.position / 1000
					track.progress = (self.currentSound.position / (track.duration * 1000)) * 100

				onfinish: () -> $rootScope.safeApply ->
					track.isPlaying = false
					self.playNext()

				onstop: () -> $rootScope.safeApply ->
					track.isPlaying = false
					self.isPlaying = false

				onplay: () -> $rootScope.safeApply ->
					track.isPlaying = true

				onresume: () -> $rootScope.safeApply ->
					track.isPlaying = true

				onpause: () -> $rootScope.safeApply ->
					track.isPlaying = false

			track.isPlaying = true
			self.isPlaying = true
			self.currentSound.play()

		self =
			ready: false
			isPlaying: false
			currentTrack: null
			currentSound: null
			playlist: []
			playlistIndex: 0
			volume: 0
			readyDef: readyDef.promise()

			playPause: () ->
				return if !self.ready
				return if !self.isPlaying

				if self.currentSound.paused
					self.currentSound.play()
				else
					self.currentSound.pause()

			playNext: () ->
				self.currentSound.stop() if self.currentSound != null
				self.playlistIndex++
				if self.playlistIndex >= self.playlist.length
					self.playlist.length = 0
					self.currentTrack = null
					self.currentSong = null
					self.isPlaying = false
					return

				play self.playlist[self.playlistIndex]

			playPrev: () ->
				self.currentSound.stop() if self.currentSound != null
				self.playlistIndex--
				if self.playlistIndex <= 0
					self.playlist.length = 0
					self.currentTrack = null
					self.currentSong = null
					self.isPlaying = false
					return

				play self.playlist[self.playlistIndex]

			seek: (progress) ->
				return if !self.currentSound
				self.currentSound.setPosition(progress)

			setVolume: (theVolume) ->
				theVolume = 100 if theVolume > 100
				self.currentSound.setVolume(theVolume) if self.currentSound
				$.cookie('pfm-volume', theVolume)
				self.volume = theVolume

			playTracks: (tracks, index) ->
				return if !self.ready
				return if tracks.length == 0

				if tracks[index].isPlaying
					self.playPause()
					return

				self.currentSound.stop() if self.currentSound != null

				$rootScope.$broadcast 'player-stopping-playlist'
				self.playlist.length = 0
				self.playlist.push track for track in tracks
				self.playlistIndex = index

				$rootScope.$broadcast 'player-starting-playlist', tracks
				play tracks[index]

		pfm.soundManager.done () ->
			self.ready = true
			self.setVolume($.cookie('pfm-volume') || 100)
			readyDef.resolve()

		self
])