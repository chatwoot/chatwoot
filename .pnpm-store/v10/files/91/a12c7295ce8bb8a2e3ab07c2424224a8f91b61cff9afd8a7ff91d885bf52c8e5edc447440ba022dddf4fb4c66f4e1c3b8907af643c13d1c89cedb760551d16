import YouTubeAnalytics from ".";
import assert from "assert";
import fetchMock from "fetch-mock";
const SEEK_THRESHOLD = 2000;

const sampleSingleVideoApiOutput = {
  body: {
    items: [
      {
        kind: "youtube#video",
        etag: '"XI7nbFXulYBIpL0ayR_gDh3eu1k/l8T3Ps_vgKQV_OC2bHkLGQ44KAk"',
        id: "M7lc1UVf-VE",
        snippet: {
          publishedAt: "2013-04-10T17:25:04.000Z",
          channelId: "UC_x5XG1OV2P6uZZ5FSM9Ttw",
          title: "YouTube Developers Live: Embedded Web Player Customization",
          description:
            "On this week's show, Jeff Posnick covers everything you need to know about using player parameters to customize the YouTube iframe-embedded player.",
          channelTitle: "Google Developers",
          tags: [
            "youtubedataapi",
            "youtube",
            "youtubeplayerapi",
            "youtubeapi",
            "video",
            "Mountain View",
            "gdl"
          ],
          categoryId: "28",
          liveBroadcastContent: "none",
          localized: {
            title: "YouTube Developers Live: Embedded Web Player Customization",
            description:
              "On this week's show, Jeff Posnick covers everything you need to know about using player parameters to customize the YouTube iframe-embedded player."
          },
          defaultAudioLanguage: "en"
        },
        contentDetails: {
          duration: "PT22M24S",
          dimension: "2d",
          definition: "hd",
          caption: "true",
          licensedContent: false,
          projection: "rectangular"
        }
      }
    ]
  }
};

const samplePlaylistApiOutput = {
  body: {
    items: [
      {
        kind: "youtube#video",
        etag: '"XI7nbFXulYBIpL0ayR_gDh3eu1k/l8T3Ps_vgKQV_OC2bHkLGQ44KAk"',
        id: "M7lc1UVf-VE",
        snippet: {
          publishedAt: "2013-04-10T17:25:04.000Z",
          channelId: "UC_x5XG1OV2P6uZZ5FSM9Ttw",
          title: "YouTube Developers Live: Embedded Web Player Customization",
          description:
            "On this week's show, Jeff Posnick covers everything you need to know about using player parameters to customize the YouTube iframe-embedded player.",
          channelTitle: "Google Developers",
          tags: [
            "youtubedataapi",
            "youtube",
            "youtubeplayerapi",
            "youtubeapi",
            "video",
            "Mountain View",
            "gdl"
          ],
          categoryId: "28",
          liveBroadcastContent: "none",
          localized: {
            title: "YouTube Developers Live: Embedded Web Player Customization",
            description:
              "On this week's show, Jeff Posnick covers everything you need to know about using player parameters to customize the YouTube iframe-embedded player."
          },
          defaultAudioLanguage: "en"
        },
        contentDetails: {
          duration: "PT22M24S",
          dimension: "2d",
          definition: "hd",
          caption: "true",
          licensedContent: false,
          projection: "rectangular"
        }
      },
      {
        kind: "youtube#video",
        etag: '"XI7nbFXulYBIpL0ayR_gDh3eu1k/WRztWOH0sUonKk2lGPf4GfmmTjk"',
        id: "izoct69J4v8",
        snippet: {
          publishedAt: "2017-10-26T21:49:55.000Z",
          channelId: "UCTJmlYi-adThOQaXuuNYsgQ",
          title: "Introducing Personas, by Segment",
          description:
            "Derrick thinks Kicks Central controls the weather. Turns out, its just the corporate office using Personas by Segment to send the right offers to the right people, at exactly the right time. Learn more at segment.com/personas.",
          channelTitle: "Segment",
          tags: [
            "segment",
            "personas",
            "identity resolution",
            "audience building",
            "custom segments",
            "marketing automation",
            "api"
          ],
          categoryId: "27",
          liveBroadcastContent: "none",
          localized: {
            title: "Introducing Personas, by Segment",
            description:
              "Derrick thinks Kicks Central controls the weather. Turns out, its just the corporate office using Personas by Segment to send the right offers to the right people, at exactly the right time. Learn more at segment.com/personas."
          }
        },
        contentDetails: {
          duration: "PT1M30S",
          dimension: "2d",
          definition: "hd",
          caption: "false",
          licensedContent: false,
          projection: "rectangular"
        }
      }
    ]
  }
};

window.YT = {
  PlayerState: {
    ENDED: 0,
    PLAYING: 1,
    PAUSED: 2,
    BUFFERING: 3
  }
};

describe("YoutubeAnalytics", () => {
  let youTubeAnalytics;
  let playerTime;
  let playbackQuality;
  let volume;
  let playlistIndex;
  let player;
  let playlistId;
  let videoId = "M7lc1UVf";
  let playlist;
  let muted;

  beforeEach(() => {
    playerTime = 0;
    playlistId = null;
    volume = 47;
    muted = false;
    playbackQuality = 0;

    // stub out player methods
    player = {
      addEventListener: function() {},
      getVideoData: function() {
        return { video_id: videoId };
      },
      getPlaylist: function() {
        return playlist;
      },
      getCurrentTime: function() {
        return playerTime;
      },
      getPlaybackQuality: function() {
        return playbackQuality;
      },
      getVolume: function() {
        return volume;
      },
      isMuted: function() {
        return muted;
      },
      getPlaylistIndex: function() {
        return isNaN(playlistIndex) ? -1 : playlistIndex;
      },
      getPlaylistId: function() {
        return playlistId;
      },
      cuePlaylist: function() {},
      cueVideoById: function() {}
    };

    window.analytics = {
      track: sinon.spy()
    };
    youTubeAnalytics = new YouTubeAnalytics(
      player,
      "AIzaSyDxtBpYa_IAWudnLW0P79sBF-cIzBUOUpQ"
    );
  });

  describe("initialize()", () => {
    it("should put listeners on the window and add the listeners to the player object", () => {
      const stub = sinon.stub(player, "addEventListener");

      youTubeAnalytics.initialize();

      assert(global.segmentYoutubeOnStateChange);
      assert(global.segmentYoutubeOnReady);
      sinon.assert.calledWith(
        stub,
        "onStateChange",
        "segmentYoutubeOnStateChange"
      );
      sinon.assert.calledWith(stub, "onReady", "segmentYoutubeOnReady");
    });
  });

  describe("onPlayerReady", () => {
    it("should call retrieveMetdata", () => {
      const stub = sinon.stub(youTubeAnalytics, "retrieveMetadata");
      youTubeAnalytics.onPlayerReady();

      sinon.assert.called(stub);
    });
  });

  describe("Metadata Retrieval", () => {
    afterEach(() => {
      fetchMock.restore();
    });
    it("should successfully retrieve metadata for a given video", () => {
      fetchMock.mock(
        "begin:https://www.googleapis.com",
        sampleSingleVideoApiOutput
      );
      youTubeAnalytics.retrieveMetadata().then(() => {
        assert.deepEqual(youTubeAnalytics.metadata, [
          {
            content: {
              title:
                "YouTube Developers Live: Embedded Web Player Customization",
              description:
                "On this week's show, Jeff Posnick covers everything you need to know about using player parameters to customize the YouTube iframe-embedded player.",
              keywords: [
                "youtubedataapi",
                "youtube",
                "youtubeplayerapi",
                "youtubeapi",
                "video",
                "Mountain View",
                "gdl"
              ],
              channel: "Google Developers",
              airdate: "2013-04-10T17:25:04.000Z"
            },
            playback: { total_length: 1344, video_player: "youtube" }
          }
        ]);
      });
    });

    it("should successfully retrieve metadata for a playlist of multiple videos", () => {
      fetchMock.mock(
        "begin:https://www.googleapis.com",
        samplePlaylistApiOutput
      );
      youTubeAnalytics.player.getPlaylist = function() {
        return ["M7lc1UVf-VE", "izoct69J4v8"];
      };
      youTubeAnalytics.retrieveMetadata().then(() => {
        assert.deepEqual(youTubeAnalytics.metadata, [
          {
            content: {
              title:
                "YouTube Developers Live: Embedded Web Player Customization",
              description:
                "On this week's show, Jeff Posnick covers everything you need to know about using player parameters to customize the YouTube iframe-embedded player.",
              keywords: [
                "youtubedataapi",
                "youtube",
                "youtubeplayerapi",
                "youtubeapi",
                "video",
                "Mountain View",
                "gdl"
              ],
              channel: "Google Developers",
              airdate: "2013-04-10T17:25:04.000Z"
            },
            playback: { total_length: 1434, video_player: "youtube" }
          },
          {
            content: {
              title: "Introducing Personas, by Segment",
              description:
                "Derrick thinks Kicks Central controls the weather. Turns out, its just the corporate office using Personas by Segment to send the right offers to the right people, at exactly the right time. Learn more at segment.com/personas.",
              keywords: [
                "segment",
                "personas",
                "identity resolution",
                "audience building",
                "custom segments",
                "marketing automation",
                "api"
              ],
              channel: "Segment",
              airdate: "2017-10-26T21:49:55.000Z"
            },
            playback: { total_length: 1434, video_player: "youtube" }
          }
        ]);
      });
    });

    it("should not fail on API request failure", () => {
      fetchMock.mock("begin:https://www.googleapis.com", 400);
      youTubeAnalytics.retrieveMetadata().then(() => {
        assert.deepEqual(youTubeAnalytics.metadata, [
          { playback: { video_player: "youtube" }, content: {} }
        ]);
      });
    });
  });

  describe("onPlayerStateChange", () => {
    beforeEach(() => {
      youTubeAnalytics.initialize();
      youTubeAnalytics.metadata = [{ playback: {}, content: {} }];
    });
    it("should update playback metadata", () => {
      playerTime = 4;
      playbackQuality = 3;
      volume = 2;
      window.segmentYoutubeOnStateChange({});

      assert.deepEqual(youTubeAnalytics.metadata[0].playback, {
        position: playerTime,
        quality: playbackQuality,
        sound: volume
      });
    });

    it("should check for muted videos", () => {
      playerTime = 4;
      playbackQuality = 3;
      volume = 100;
      muted = true;
      window.segmentYoutubeOnStateChange({});

      assert.deepEqual(youTubeAnalytics.metadata[0].playback, {
        position: playerTime,
        quality: playbackQuality,
        sound: 0
      });
    });

    it('should update "last recorded time"', () => {
      playerTime = 4;

      const timeBeforeFunctionRun = Date.now();

      window.segmentYoutubeOnStateChange({});

      // impossible to know what Date.now was at the time the var was set so settle for checking that the updated value
      // is for a later date than Date.now before the function was run
      assert(
        youTubeAnalytics.lastRecordedTime.timeReported >= timeBeforeFunctionRun
      );
      assert.equal(
        youTubeAnalytics.lastRecordedTime.timeElapsed,
        playerTime * 1000.0
      );
    });
  });

  describe("Video Events", () => {
    let stub;
    let playback;
    let content;
    beforeEach(() => {
      youTubeAnalytics.initialize();
      youTubeAnalytics.metadata = [{ playback: {}, content: {} }];
      stub = sinon.stub(youTubeAnalytics, "track");
      playback = {
        position: playerTime,
        quality: playbackQuality,
        sound: volume
      };
      content = {
        title: "YouTube Developers Live: Embedded Web Player Customization",
        description:
          "On this week's show, Jeff Posnick covers everything you need to know about using player parameters to customize the YouTube iframe-embedded player.",
        keywords: [
          "youtubedataapi",
          "youtube",
          "youtubeplayerapi",
          "youtubeapi",
          "video",
          "Mountain View",
          "gdl"
        ],
        channel: "Google Developers",
        airdate: "2013-04-10T17:25:04.000Z"
      };
      youTubeAnalytics.metadata = [{ playback, content }];
    });
    describe("Singular Video Playback", () => {
      describe("YT buffering events", () => {
        it('should trigger "Playback Started","Playback Buffer Started" if video buffering for the first time', () => {
          window.segmentYoutubeOnStateChange({
            data: YT.PlayerState.BUFFERING
          });

          assert(youTubeAnalytics.isBuffering);
          assert(youTubeAnalytics.playbackStarted);
          sinon.assert.calledWith(stub, "Video Playback Started", playback);
          sinon.assert.calledWith(
            stub,
            "Video Playback Buffer Started",
            playback
          );
        });

        it('should trigger "Playback Seek Started","Playback Seek Completed",Playback Buffer Started" if a user seeks with keyboard or seeks while video is paused', () => {
          youTubeAnalytics.playbackStarted = true;
          // simulate a keyboard seek
          youTubeAnalytics.lastRecordedTime.timeElapsed = 0;
          youTubeAnalytics.lastRecordedTime.timeReported = Date.now();
          playerTime = SEEK_THRESHOLD / 1000 + 10;
          window.segmentYoutubeOnStateChange({
            data: YT.PlayerState.BUFFERING
          });

          assert(youTubeAnalytics.isBuffering);
          assert(!youTubeAnalytics.isSeeking);
          sinon.assert.calledWith(
            stub,
            "Video Playback Seek Started",
            playback
          );
          sinon.assert.calledWith(
            stub,
            "Video Playback Seek Completed",
            playback
          );
          sinon.assert.calledWith(
            stub,
            "Video Playback Buffer Started",
            playback
          );
        });

        it('should trigger "Playback Seek Completed","Playback Buffer Started" if a seek is in progress', () => {
          youTubeAnalytics.isSeeking = true;
          youTubeAnalytics.playbackStarted = true;
          window.segmentYoutubeOnStateChange({
            data: YT.PlayerState.BUFFERING
          });

          assert(youTubeAnalytics.isBuffering);
          assert(!youTubeAnalytics.isSeeking);
          sinon.assert.calledWith(
            stub,
            "Video Playback Seek Completed",
            playback
          );
          sinon.assert.calledWith(
            stub,
            "Video Playback Buffer Started",
            playback
          );
        });
      });

      describe("YT play events", () => {
        it('should trigger "Content Started" if the content hadnt started yet', () => {
          window.segmentYoutubeOnStateChange({ data: YT.PlayerState.PLAYING });

          assert(youTubeAnalytics.contentStarted);
          sinon.assert.calledWith(stub, "Video Content Started", content);
        });

        it('should trigger "Playback Buffer Completed" if a buffer is in progress', () => {
          youTubeAnalytics.contentStarted = true;
          youTubeAnalytics.isBuffering = true;

          window.segmentYoutubeOnStateChange({ data: YT.PlayerState.PLAYING });

          assert(!youTubeAnalytics.isBuffering);
          sinon.assert.calledWith(
            stub,
            "Video Playback Buffer Completed",
            playback
          );
        });

        it('should trigger "Playback Resumed" if the video is paused', () => {
          youTubeAnalytics.contentStarted = true;
          youTubeAnalytics.isPaused = true;

          window.segmentYoutubeOnStateChange({ data: YT.PlayerState.PLAYING });
          assert(!youTubeAnalytics.isPaused);
          sinon.assert.calledWith(stub, "Video Playback Resumed", playback);
        });
      });

      describe("YT pause events", () => {
        it('should trigger "Playback Buffer" if the video was buffering', () => {
          youTubeAnalytics.isBuffering = true;
          window.segmentYoutubeOnStateChange({ data: YT.PlayerState.PAUSED });

          assert(!youTubeAnalytics.isBuffering);
          sinon.assert.calledWith(
            stub,
            "Video Playback Buffer Completed",
            playback
          );
        });

        it('should trigger "Playback Seek Started" if a seek is detected', () => {
          youTubeAnalytics.lastRecordedTime.timeElapsed = 0;
          youTubeAnalytics.lastRecordedTime.timeReported = Date.now();
          playerTime = playback.position = SEEK_THRESHOLD / 1000 + 10;

          window.segmentYoutubeOnStateChange({ data: YT.PlayerState.PAUSED });

          assert(youTubeAnalytics.isSeeking);
          sinon.assert.calledWith(
            stub,
            "Video Playback Seek Started",
            playback
          );
        });

        it('should trigger "Playback Paused" if the video wasnt paused and a seek wasnt detected', () => {
          window.segmentYoutubeOnStateChange({ data: YT.PlayerState.PAUSED });

          assert(youTubeAnalytics.isPaused);
          sinon.assert.calledWith(stub, "Video Playback Paused", playback);
        });
      });

      describe("YT ended events", () => {
        it('should trigger "Video Content Completed" and "Video Playback Completed" as its the only video in the playlist', () => {
          window.segmentYoutubeOnStateChange({ data: YT.PlayerState.ENDED });

          assert(!youTubeAnalytics.contentStarted);
          sinon.assert.calledWith(stub, "Video Content Completed", content);
          sinon.assert.calledWith(stub, "Video Playback Completed", playback);
        });
      });
    });

    describe("Video Playlist Playback", () => {
      beforeEach(() => {
        youTubeAnalytics.metadata = [
          { playback, content },
          { playback, content }
        ];
        playlist = ["", ""];
      });
      it("should set contentStarted to false if user clicks next video", () => {
        playerTime = 0;
        playlistIndex = 1;
        youTubeAnalytics.playlistIndex = 0;

        window.segmentYoutubeOnStateChange({ data: YT.PlayerState.BUFFERING });

        assert(!youTubeAnalytics.contentStarted);
      });

      it('should trigger "Playback Completed" and then "Playback Started" when user clicks next video on the last video of playlist', () => {
        playerTime = 0;
        playlistIndex = 0;
        youTubeAnalytics.playlistIndex = 1;
        youTubeAnalytics.playbackStarted = true;

        window.segmentYoutubeOnStateChange({ data: YT.PlayerState.BUFFERING });

        assert(!youTubeAnalytics.contentStarted);
        assert(youTubeAnalytics.isBuffering);
        sinon.assert.calledWith(stub, "Video Playback Completed", playback);
        sinon.assert.calledWith(stub, "Video Playback Started", playback);
        sinon.assert.calledWith(
          stub,
          "Video Playback Buffer Started",
          playback
        );
      });

      it('should trigger "Content Completed" but not "Playback Completed" when a video in the middle of the playlist ends', () => {
        playlistIndex = 0;

        window.segmentYoutubeOnStateChange({ data: YT.PlayerState.ENDED });

        assert(!youTubeAnalytics.contentStarted);
        sinon.assert.calledWith(stub, "Video Content Completed", content);
        sinon.assert.neverCalledWith(stub, "Video Playback Completed");
      });

      it('should trigger "Content Completed" and "Playback Completed" when the final video ends', () => {
        playlistIndex = 1;

        window.segmentYoutubeOnStateChange({ data: YT.PlayerState.ENDED });

        assert(!youTubeAnalytics.contentStarted);
        sinon.assert.calledWith(stub, "Video Content Completed", content);
        sinon.assert.calledWith(stub, "Video Playback Completed", playback);
      });
    });
  });
});

function clearEnv(id) {
  document.getElementById(id).remove();
}
