import fetch from "unfetch";
import VideoPlugin from "../../lib/plugin";
const SEEK_THRESHOLD = 2000;

export default class YouTubeAnalytics extends VideoPlugin {
  /**
   * Creates a YouTube video plugin to track events directly from the player.
   *
   * @param {YT.Player} player YouTube IFrame Player (docs: https://developers.google.com/youtube/iframe_api_reference#Loading_a_Video_Player).
   * @param {String} apiKey Youtube Data API key (docs: https://developers.google.com/youtube/registering_an_application).
   */
  constructor(player, apiKey) {
    super("YoutubeAnalytics");
    this.player = player;
    this.apiKey = apiKey;
    this.playerLoaded = false;
    this.playbackStarted = false;
    this.contentStarted = false;
    this.isPaused = false;
    this.isBuffering = false;
    this.isSeeking = false;
    this.lastRecordedTime = {
      // updated every event
      timeReported: Date.now(),
      timeElapsed: 0.0
    };
    this.metadata = [{ playback: { video_player: "youtube" }, content: {} }];
    this.playlistIndex = 0;
  }

  initialize() {
    // Youtube API requires listeners to exist as top-level props on window object
    window.segmentYoutubeOnStateChange = this.onPlayerStateChange.bind(this);
    window.segmentYoutubeOnReady = this.onPlayerReady.bind(this);

    this.player.addEventListener("onReady", "segmentYoutubeOnReady");
    this.player.addEventListener(
      "onStateChange",
      "segmentYoutubeOnStateChange"
    );
  }

  onPlayerReady(event) {
    // this fires when the player html element loads
    this.retrieveMetadata();
  }

  // yt reports events via state changes in the player rather than explicitly EVENTS like 'play', 'pause', etc
  onPlayerStateChange(event) {
    const currentTime = this.player.getCurrentTime();
    if (this.metadata[this.playlistIndex]) {
      this.metadata[this.playlistIndex].playback.position = this.metadata[
        this.playlistIndex
      ].content.position = currentTime;
      this.metadata[
        this.playlistIndex
      ].playback.quality = this.player.getPlaybackQuality();
      this.metadata[this.playlistIndex].playback.sound = this.player.isMuted()
        ? 0
        : this.player.getVolume();
    }

    switch (event.data) {
      case -1: // this fires when a video or playlist has loaded
        if (this.playerLoaded) break;
        this.retrieveMetadata();
        this.playerLoaded = true;
        break;

      case YT.PlayerState.BUFFERING:
        this.handleBuffer();
        break;

      case YT.PlayerState.PLAYING:
        this.handlePlay();
        break;

      case YT.PlayerState.PAUSED:
        this.handlePause();
        break;

      case YT.PlayerState.ENDED:
        this.handleEnd();
        break;
    }

    this.lastRecordedTime = {
      timeReported: Date.now(),
      timeElapsed: this.player.getCurrentTime() * 1000.0
    };
  }

  /**
   * Retrieves the video metadata from Youtube Data API using user's API Key
   * docs: https://developers.google.com/youtube/v3/docs/videos/list
   *
   * @returns {Promise} A promise that resolves in a metadata object from the video
   * contained in the player.
   */
  retrieveMetadata() {
    return new Promise((resolve, reject) => {
      let videoData = this.player.getVideoData();
      let playlist = this.player.getPlaylist() || [videoData.video_id];

      const videoIds = playlist.join();

      fetch(
        `https://www.googleapis.com/youtube/v3/videos?id=${videoIds}&part=snippet,contentDetails&key=${this.apiKey}`
      )
        .then(res => {
          if (!res.ok) {
            const err = new Error(
              "Segment request to Youtube API failed (likely due to a bad API Key. Events will still be sent but will not contain video metadata)"
            );
            err.response = res;
            throw err;
          }
          return res.json();
        })
        .then(json => {
          this.metadata = [];
          let total_length = 0;
          for (var i = 0; i < playlist.length; i++) {
            const videoInfo = json.items[i];
            this.metadata.push({
              content: {
                title: videoInfo.snippet.title,
                description: videoInfo.snippet.description,
                keywords: videoInfo.snippet.tags,
                channel: videoInfo.snippet.channelTitle,
                airdate: videoInfo.snippet.publishedAt
              }
            });
            total_length += YTDurationToSeconds(
              videoInfo.contentDetails.duration
            );
          }

          for (var i = 0; i < playlist.length; i++) {
            this.metadata[i].playback = {
              total_length,
              video_player: "youtube"
            };
          }
          resolve();
        })
        .catch(err => {
          this.metadata = playlist.map(item => {
            return { playback: { video_player: "youtube" }, content: {} };
          });
          reject(err);
        });
    });
  }

  handleBuffer() {
    var seekDetected = this.determineSeek();

    if (!this.playbackStarted) {
      this.playbackStarted = true;
      this.track(
        "Video Playback Started",
        this.metadata[this.playlistIndex].playback
      );
    }

    // user used keyboard to seek or seeked while video was paused
    if (seekDetected && !this.isSeeking) {
      this.isSeeking = true;
      this.track(
        "Video Playback Seek Started",
        this.metadata[this.playlistIndex].playback
      );
    }

    // state changing to BUFFERING denotes seeking has completed
    if (this.isSeeking) {
      this.track(
        "Video Playback Seek Completed",
        this.metadata[this.playlistIndex].playback
      );
      this.isSeeking = false;
    }

    // user clicked next video button (not possible in single video playback)
    const playlist = this.player.getPlaylist();
    if (
      playlist &&
      this.player.getCurrentTime() === 0 &&
      this.player.getPlaylistIndex() !== this.playlistIndex
    ) {
      this.contentStarted = false;
      if (
        this.playlistIndex === playlist.length - 1 &&
        this.player.getPlaylistIndex() === 0
      ) {
        // user skipped to end of last video in playlist
        this.track(
          "Video Playback Completed",
          this.metadata[this.player.getPlaylistIndex()].playback
        );
        this.track(
          "Video Playback Started",
          this.metadata[this.player.getPlaylistIndex()].playback
        ); // playlist automatically starts from beginning
      }
    }

    this.track(
      "Video Playback Buffer Started",
      this.metadata[this.playlistIndex].playback
    );
    this.isBuffering = true;
  }

  handlePlay() {
    if (!this.contentStarted) {
      this.playlistIndex = this.player.getPlaylistIndex(); // will return -1 if the player has a singular video instead of a playlist
      if (this.playlistIndex === -1) this.playlistIndex = 0;
      this.track(
        "Video Content Started",
        this.metadata[this.playlistIndex].content
      );
      this.contentStarted = true;
    }

    if (this.isBuffering) {
      this.track(
        "Video Playback Buffer Completed",
        this.metadata[this.playlistIndex].playback
      );
      this.isBuffering = false;
    }

    if (this.isPaused) {
      this.track(
        "Video Playback Resumed",
        this.metadata[this.playlistIndex].playback
      );
      this.isPaused = false;
    }
  }

  handlePause() {
    const seekDetected = this.determineSeek();
    // user seeked while video was paused, it buffered, and then finished buffering
    if (this.isBuffering) {
      this.track(
        "Video Playback Buffer Completed",
        this.metadata[this.playlistIndex].playback
      );
      this.isBuffering = false;
    }

    if (!this.isPaused) {
      // user seeked while video was playing
      if (seekDetected) {
        this.track(
          "Video Playback Seek Started",
          this.metadata[this.playlistIndex].playback
        );
        this.isSeeking = true;
      }
      // user clicked pause while video was playing
      else {
        this.track(
          "Video Playback Paused",
          this.metadata[this.playlistIndex].playback
        );
        this.isPaused = true;
      }
    }
  }

  handleEnd() {
    this.track(
      "Video Content Completed",
      this.metadata[this.playlistIndex].content
    );
    this.contentStarted = false;

    const playlistIndex = this.player.getPlaylistIndex();
    const playlist = this.player.getPlaylist();

    if (
      (playlist && playlistIndex === playlist.length - 1) ||
      playlistIndex === -1
    ) {
      this.track(
        "Video Playback Completed",
        this.metadata[this.playlistIndex].playback
      );
      this.playbackStarted = false;
    }
  }

  // yt doesn't natively track seeking so we have to manually calculate whether a seek has occurred based on expected vs actual event timestamps
  determineSeek() {
    const expectedTimeElapsed =
      this.isPaused || this.isBuffering
        ? 0
        : Date.now() - this.lastRecordedTime.timeReported;
    const actualTimeElapsed =
      this.player.getCurrentTime() * 1000.0 - this.lastRecordedTime.timeElapsed;

    return Math.abs(expectedTimeElapsed - actualTimeElapsed) > SEEK_THRESHOLD; // if the diff btwn the 2 is > the threshold we can reasonably assume a seek has occurred
  }
}

// convert from ISO 8601 to seconds
function YTDurationToSeconds(duration) {
  var match = duration.match(/PT(\d+H)?(\d+M)?(\d+S)?/);

  match = match.slice(1).map(function(x) {
    if (x != null) {
      return x.replace(/\D/, "");
    }
  });

  var hours = parseInt(match[0]) || 0;
  var minutes = parseInt(match[1]) || 0;
  var seconds = parseInt(match[2]) || 0;

  return hours * 3600 + minutes * 60 + seconds;
}
