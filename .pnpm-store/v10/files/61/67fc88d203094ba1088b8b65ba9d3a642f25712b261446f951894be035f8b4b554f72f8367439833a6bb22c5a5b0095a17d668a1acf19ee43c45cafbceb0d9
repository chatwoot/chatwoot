import fetch from "unfetch";
import Plugin from "../../lib/plugin";

export default class VimeoAnalytics extends Plugin {
  constructor(player, authToken) {
    super("VimeoAnalytics");
    this.authToken = authToken;
    this.player = player;
    this.metadata = {
      content: {},
      playback: { videoPlayer: "Vimeo" }
    };
    this.mostRecentHeartbeat = 0;
    this.isPaused = false;
  }

  initialize() {
    const events = {
      loaded: this.retrieveMetadata,
      play: this.trackPlay,
      pause: this.trackPause,
      ended: this.trackEnded,
      timeupdate: this.trackHeartbeat
    };

    for (let event in events) {
      this.registerHandler(event, events[event]);
    }

    this.player
      .getVideoId()
      .then(id => {
        this.retrieveMetadata({ id });
      })
      .catch(console.error);
  }

  // This is a helper function used to facilitate easier testing.
  registerHandler(event, handler) {
    this.player.on(event, data => {
      this.updateMetadata(data);
      handler.call(this, data);
    });
  }

  trackPlay() {
    if (this.isPaused) {
      this.track("Video Playback Resumed", this.metadata.playback);
      this.isPaused = false;
    } else {
      this.track("Video Playback Started", this.metadata.playback);
      this.track("Video Content Started", this.metadata.content);
    }
  }

  trackEnded() {
    this.track("Video Playback Completed", this.metadata.playback);
    this.track("Video Content Completed", this.metadata.content);
  }

  // Vimeo provides time updates every 250ms while Segment documents sending heartbeats every 10s.
  // Therefore, we need to do some math to ensure we are not sending 4 heartbeat events when we reach
  // 10 second intervals.
  trackHeartbeat() {
    const mostRecentHeartbeat = this.mostRecentHeartbeat;
    const currentPosition = this.metadata.playback.position;
    if (
      currentPosition !== mostRecentHeartbeat &&
      currentPosition - mostRecentHeartbeat >= 10
    ) {
      this.track("Video Content Playing", this.metadata.content);
      this.mostRecentHeartbeat = Math.floor(currentPosition);
    }
  }

  trackPause() {
    this.isPaused = true;
    this.track("Video Playback Paused", this.metadata.playback);
  }

  // retrieve static video metadata from vimeo API
  retrieveMetadata(data) {
    return new Promise((resolve, reject) => {
      const videoId = data.id;
      fetch(`https://api.vimeo.com/videos/${videoId}`, {
        headers: {
          Authorization: `Bearer ${this.authToken}`
        }
      })
        .then(res => {
          if (res.ok) {
            return res.json();
          }
          return reject(res);
        })
        .then(json => {
          this.metadata.content.title = json.name;
          this.metadata.content.description = json.description;
          this.metadata.content.publisher = json.user.name;

          this.metadata.playback.position = 0;
          this.metadata.playback.totalLength = json.duration;
        })
        .catch(err => {
          console.error("Request to Vimeo API Failed with: ", err);
          return reject(err);
        });
    });
  }

  // update dynamic video information
  updateMetadata(data) {
    return new Promise((resolve, reject) => {
      this.player
        .getVolume()
        .then(volume => {
          if (volume) this.metadata.playback.sound = volume * 100;
          this.metadata.playback.position = data.seconds;
          resolve();
        })
        .catch(reject);
    });
  }
}
