import VimeoAnalytics from ".";
import assert from "assert";
const sandbox = sinon.createSandbox();

describe("VimeoAnalytics", () => {
  let player;
  let vimeoAnalytics;

  beforeEach(() => {
    window.analytics = {
      track: sandbox.spy()
    };

    const html =
      '<iframe id="video-player" src="https://player.vimeo.com/video/76979871" width="640" height="360" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe>';
    document.body.insertAdjacentHTML("afterbegin", html);
    const iframe = document.querySelector("iframe");
    player = new Vimeo.Player(iframe, { autoplay: true, muted: true });
    vimeoAnalytics = new VimeoAnalytics(
      player,
      "b203643ead884f6b47b193c88f328c4a"
    );
    vimeoAnalytics.track = sandbox.spy();
    vimeoAnalytics.initialize();
  });

  afterEach(() => {
    player.unload().then(() => {
      clearEnv("video-player");
      sandbox.reset();
    });
  });

  describe("registerHandler", () => {
    it("should call player.on for any event with the given handler", () => {
      sandbox.spy(player, "on");
      vimeoAnalytics.registerHandler("play", () => {});
      player.on.should.have.been.calledOnce;
      player.on.should.have.been.calledWithMatch(
        sinon.match("play"),
        sinon.match.func
      );
    });
  });

  describe("initialize()", () => {
    it("should initiate all supported event handlers", () => {
      sandbox.spy(vimeoAnalytics, "registerHandler");

      const events = {
        loaded: vimeoAnalytics.retrieveMetadata,
        play: vimeoAnalytics.trackPlay,
        pause: vimeoAnalytics.trackPause,
        ended: vimeoAnalytics.trackEnded,
        timeupdate: vimeoAnalytics.trackHeartbeat
      };

      vimeoAnalytics.initialize();

      for (let event in events) {
        vimeoAnalytics.registerHandler.should.have.been.calledWith(
          event,
          events[event]
        );
      }
    });
  });

  describe("Event Handlers", () => {
    describe("retrieveMetadata()", () => {
      it("should successfully retrieve metadata for a given video", () => {
        vimeoAnalytics.retrieveMetadata({ id: 76979871 }).then(() => {
          assert.equal(
            vimeoAnalytics.metadata.content.title,
            "The New Vimeo Player (You Know, For Videos)"
          );
          assert(
            typeof vimeoAnalytics.metadata.content.description === "string"
          );
          assert.equal(
            vimeoAnalytics.metadata.content.publisher,
            "Vimeo Staff"
          );
          assert.equal(vimeoAnalytics.metadata.playback.videoPlayer, "Vimeo");
          assert.equal(vimeoAnalytics.metadata.playback.position, 0);
          assert.equal(vimeoAnalytics.metadata.playback.totalLength, 62);
        });
      });
    });

    describe("trackPlay()", () => {
      it("should track play events as Video Playback Started events", () => {
        vimeoAnalytics.trackPlay();
        vimeoAnalytics.track.firstCall.should.have.been.calledWith(
          "Video Playback Started",
          vimeoAnalytics.metadata.playback
        );
      });

      it("should not track Video Playback Started events if playback is paused", () => {
        vimeoAnalytics.isPaused = true;
        vimeoAnalytics.trackPlay();
        vimeoAnalytics.track.should.not.have.been.calledWith(
          "Video Playback Started"
        );
      });

      it("should track play events as Video Playback Resumed events if the video was previously paused", () => {
        vimeoAnalytics.isPaused = true;
        vimeoAnalytics.trackPlay();
        vimeoAnalytics.track.should.have.been.calledWith(
          "Video Playback Resumed",
          vimeoAnalytics.metadata.playback
        );
      });

      it("should track play events as Video Content Started events", () => {
        vimeoAnalytics.trackPlay();
        vimeoAnalytics.track.should.have.been.calledWith(
          "Video Content Started",
          vimeoAnalytics.metadata.content
        );
      });
    });

    describe("trackPause()", () => {
      const pauseData = {
        duration: 61.857,
        percent: 0.049,
        seconds: 3.034
      };

      it("should set isPaused to true", () => {
        vimeoAnalytics.updateMetadata(pauseData).then(() => {
          vimeoAnalytics.trackPause();
          assert(vimeoAnalytics.isPaused === true);
        });
      });

      it("should track pause events as Video Playback Paused events", () => {
        vimeoAnalytics.updateMetadata(pauseData).then(() => {
          vimeoAnalytics.trackPause();
          vimeoAnalytics.track.should.have.been.calledOnce;
          vimeoAnalytics.track.should.have.been.calledWith(
            "Video Playback Paused",
            vimeoAnalytics.metadata.playback
          );
        });
      });
    });

    describe("trackHeartbeat()", () => {
      const getData = seconds => {
        seconds = seconds || 0;
        const duration = 61.857;
        return {
          percent: seconds / duration,
          duration,
          seconds
        };
      };

      it("should not track a heartbeat event if it has not been 10 seconds since the last heartbeat", () => {
        vimeoAnalytics.mostRecentHeartbeat = 10;
        vimeoAnalytics.trackHeartbeat(getData(15.02));
        analytics.track.should.not.have.been.called;
      });

      it("should track a single heartbeat event at 10 second intervals", () => {
        vimeoAnalytics.mostRecentHeartbeat = 10;
        vimeoAnalytics
          .updateMetadata(getData(20.03))
          .then(() => {
            vimeoAnalytics.trackHeartbeat();
            return vimeoAnalytics.updateMetadata(getData(22.07));
          })
          .then(() => {
            vimeoAnalytics.trackHeartbeat();
            vimeoAnalytics.track.should.have.been.calledOnce;
            vimeoAnalytics.track.should.have.been.calledWith(
              "Video Content Playing",
              vimeoAnalytics.metadata.content
            );
          });
      });

      it("should update the mostRecentHeartbeat flag when a new heartbeat is triggered", () => {
        vimeoAnalytics.mostRecentHeartbeat = 20;
        vimeoAnalytics.updateMetadata(getData(30)).then(() => {
          vimeoAnalytics.trackHeartbeat();
          assert.equal(vimeoAnalytics.mostRecentHeartbeat, 30);
        });
      });
    });

    describe("trackEnded()", () => {
      it("should track end events as Video Playback Completed events", () => {
        vimeoAnalytics.trackEnded();
        vimeoAnalytics.track.should.have.been.calledWith(
          "Video Playback Completed",
          vimeoAnalytics.metadata.playback
        );
      });

      it("should track end events as Video Content Completed events", () => {
        vimeoAnalytics.trackEnded();
        const contentCompletedSpy = vimeoAnalytics.track.withArgs(
          "Video Content Completed",
          vimeoAnalytics.metadata.content
        );
        contentCompletedSpy.should.have.been.calledOnce;
      });
    });
  });
});

function clearEnv(id) {
  document.getElementById(id).remove();
}
