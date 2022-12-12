/**
 * @file playback-watcher.js
 *
 * Playback starts, and now my watch begins. It shall not end until my death. I shall
 * take no wait, hold no uncleared timeouts, father no bad seeks. I shall wear no crowns
 * and win no glory. I shall live and die at my post. I am the corrector of the underflow.
 * I am the watcher of gaps. I am the shield that guards the realms of seekable. I pledge
 * my life and honor to the Playback Watch, for this Player and all the Players to come.
 */

import window from 'global/window';
import * as Ranges from './ranges';
import logger from './util/logger';

// Set of events that reset the playback-watcher time check logic and clear the timeout
const timerCancelEvents = [
  'seeking',
  'seeked',
  'pause',
  'playing',
  'error'
];

/**
 * @class PlaybackWatcher
 */
export default class PlaybackWatcher {
  /**
   * Represents an PlaybackWatcher object.
   *
   * @class
   * @param {Object} options an object that includes the tech and settings
   */
  constructor(options) {
    this.masterPlaylistController_ = options.masterPlaylistController;
    this.tech_ = options.tech;
    this.seekable = options.seekable;
    this.allowSeeksWithinUnsafeLiveWindow = options.allowSeeksWithinUnsafeLiveWindow;
    this.liveRangeSafeTimeDelta = options.liveRangeSafeTimeDelta;
    this.media = options.media;

    this.consecutiveUpdates = 0;
    this.lastRecordedTime = null;
    this.timer_ = null;
    this.checkCurrentTimeTimeout_ = null;
    this.logger_ = logger('PlaybackWatcher');

    this.logger_('initialize');

    const playHandler = () => this.monitorCurrentTime_();
    const canPlayHandler = () => this.monitorCurrentTime_();
    const waitingHandler = () => this.techWaiting_();
    const cancelTimerHandler = () => this.cancelTimer_();

    const mpc = this.masterPlaylistController_;

    const loaderTypes = ['main', 'subtitle', 'audio'];
    const loaderChecks = {};

    loaderTypes.forEach((type) => {
      loaderChecks[type] = {
        reset: () => this.resetSegmentDownloads_(type),
        updateend: () => this.checkSegmentDownloads_(type)
      };

      mpc[`${type}SegmentLoader_`].on('appendsdone', loaderChecks[type].updateend);
      // If a rendition switch happens during a playback stall where the buffer
      // isn't changing we want to reset. We cannot assume that the new rendition
      // will also be stalled, until after new appends.
      mpc[`${type}SegmentLoader_`].on('playlistupdate', loaderChecks[type].reset);
      // Playback stalls should not be detected right after seeking.
      // This prevents one segment playlists (single vtt or single segment content)
      // from being detected as stalling. As the buffer will not change in those cases, since
      // the buffer is the entire video duration.
      this.tech_.on(['seeked', 'seeking'], loaderChecks[type].reset);
    });

    /**
     * We check if a seek was into a gap through the following steps:
     * 1. We get a seeking event and we do not get a seeked event. This means that
     *    a seek was attempted but not completed.
     * 2. We run `fixesBadSeeks_` on segment loader appends. This means that we already
     *    removed everything from our buffer and appended a segment, and should be ready
     *    to check for gaps.
     */
    const setSeekingHandlers = (fn) => {
      ['main', 'audio'].forEach((type) => {
        mpc[`${type}SegmentLoader_`][fn]('appended', this.seekingAppendCheck_);
      });
    };

    this.seekingAppendCheck_ = () => {
      if (this.fixesBadSeeks_()) {
        this.consecutiveUpdates = 0;
        this.lastRecordedTime = this.tech_.currentTime();
        setSeekingHandlers('off');
      }
    };

    this.clearSeekingAppendCheck_ = () => setSeekingHandlers('off');

    this.watchForBadSeeking_ = () => {
      this.clearSeekingAppendCheck_();
      setSeekingHandlers('on');
    };

    this.tech_.on('seeked', this.clearSeekingAppendCheck_);
    this.tech_.on('seeking', this.watchForBadSeeking_);

    this.tech_.on('waiting', waitingHandler);
    this.tech_.on(timerCancelEvents, cancelTimerHandler);
    this.tech_.on('canplay', canPlayHandler);

    /*
      An edge case exists that results in gaps not being skipped when they exist at the beginning of a stream. This case
      is surfaced in one of two ways:

      1)  The `waiting` event is fired before the player has buffered content, making it impossible
          to find or skip the gap. The `waiting` event is followed by a `play` event. On first play
          we can check if playback is stalled due to a gap, and skip the gap if necessary.
      2)  A source with a gap at the beginning of the stream is loaded programatically while the player
          is in a playing state. To catch this case, it's important that our one-time play listener is setup
          even if the player is in a playing state
    */
    this.tech_.one('play', playHandler);

    // Define the dispose function to clean up our events
    this.dispose = () => {
      this.clearSeekingAppendCheck_();
      this.logger_('dispose');
      this.tech_.off('waiting', waitingHandler);
      this.tech_.off(timerCancelEvents, cancelTimerHandler);
      this.tech_.off('canplay', canPlayHandler);
      this.tech_.off('play', playHandler);
      this.tech_.off('seeking', this.watchForBadSeeking_);
      this.tech_.off('seeked', this.clearSeekingAppendCheck_);

      loaderTypes.forEach((type) => {
        mpc[`${type}SegmentLoader_`].off('appendsdone', loaderChecks[type].updateend);
        mpc[`${type}SegmentLoader_`].off('playlistupdate', loaderChecks[type].reset);
        this.tech_.off(['seeked', 'seeking'], loaderChecks[type].reset);
      });
      if (this.checkCurrentTimeTimeout_) {
        window.clearTimeout(this.checkCurrentTimeTimeout_);
      }
      this.cancelTimer_();
    };
  }

  /**
   * Periodically check current time to see if playback stopped
   *
   * @private
   */
  monitorCurrentTime_() {
    this.checkCurrentTime_();

    if (this.checkCurrentTimeTimeout_) {
      window.clearTimeout(this.checkCurrentTimeTimeout_);
    }

    // 42 = 24 fps // 250 is what Webkit uses // FF uses 15
    this.checkCurrentTimeTimeout_ =
      window.setTimeout(this.monitorCurrentTime_.bind(this), 250);
  }

  /**
   * Reset stalled download stats for a specific type of loader
   *
   * @param {string} type
   *        The segment loader type to check.
   *
   * @listens SegmentLoader#playlistupdate
   * @listens Tech#seeking
   * @listens Tech#seeked
   */
  resetSegmentDownloads_(type) {
    const loader = this.masterPlaylistController_[`${type}SegmentLoader_`];

    if (this[`${type}StalledDownloads_`] > 0) {
      this.logger_(`resetting possible stalled download count for ${type} loader`);
    }
    this[`${type}StalledDownloads_`] = 0;
    this[`${type}Buffered_`] = loader.buffered_();
  }

  /**
   * Checks on every segment `appendsdone` to see
   * if segment appends are making progress. If they are not
   * and we are still downloading bytes. We blacklist the playlist.
   *
   * @param {string} type
   *        The segment loader type to check.
   *
   * @listens SegmentLoader#appendsdone
   */
  checkSegmentDownloads_(type) {
    const mpc = this.masterPlaylistController_;
    const loader = mpc[`${type}SegmentLoader_`];
    const buffered = loader.buffered_();
    const isBufferedDifferent = Ranges.isRangeDifferent(this[`${type}Buffered_`], buffered);

    this[`${type}Buffered_`] = buffered;

    // if another watcher is going to fix the issue or
    // the buffered value for this loader changed
    // appends are working
    if (isBufferedDifferent) {
      this.resetSegmentDownloads_(type);
      return;
    }

    this[`${type}StalledDownloads_`]++;

    this.logger_(`found #${this[`${type}StalledDownloads_`]} ${type} appends that did not increase buffer (possible stalled download)`, {
      playlistId: loader.playlist_ && loader.playlist_.id,
      buffered: Ranges.timeRangesToArray(buffered)

    });

    // after 10 possibly stalled appends with no reset, exclude
    if (this[`${type}StalledDownloads_`] < 10) {
      return;
    }

    this.logger_(`${type} loader stalled download exclusion`);
    this.resetSegmentDownloads_(type);
    this.tech_.trigger({type: 'usage', name: `vhs-${type}-download-exclusion`});

    if (type === 'subtitle') {
      return;
    }

    // TODO: should we exclude audio tracks rather than main tracks
    // when type is audio?
    mpc.blacklistCurrentPlaylist({
      message: `Excessive ${type} segment downloading detected.`
    }, Infinity);
  }

  /**
   * The purpose of this function is to emulate the "waiting" event on
   * browsers that do not emit it when they are waiting for more
   * data to continue playback
   *
   * @private
   */
  checkCurrentTime_() {
    if (this.tech_.paused() || this.tech_.seeking()) {
      return;
    }

    const currentTime = this.tech_.currentTime();
    const buffered = this.tech_.buffered();

    if (this.lastRecordedTime === currentTime &&
        (!buffered.length ||
         currentTime + Ranges.SAFE_TIME_DELTA >= buffered.end(buffered.length - 1))) {
      // If current time is at the end of the final buffered region, then any playback
      // stall is most likely caused by buffering in a low bandwidth environment. The tech
      // should fire a `waiting` event in this scenario, but due to browser and tech
      // inconsistencies. Calling `techWaiting_` here allows us to simulate
      // responding to a native `waiting` event when the tech fails to emit one.
      return this.techWaiting_();
    }

    if (this.consecutiveUpdates >= 5 &&
        currentTime === this.lastRecordedTime) {
      this.consecutiveUpdates++;
      this.waiting_();
    } else if (currentTime === this.lastRecordedTime) {
      this.consecutiveUpdates++;
    } else {
      this.consecutiveUpdates = 0;
      this.lastRecordedTime = currentTime;
    }
  }

  /**
   * Cancels any pending timers and resets the 'timeupdate' mechanism
   * designed to detect that we are stalled
   *
   * @private
   */
  cancelTimer_() {
    this.consecutiveUpdates = 0;

    if (this.timer_) {
      this.logger_('cancelTimer_');
      clearTimeout(this.timer_);
    }

    this.timer_ = null;
  }

  /**
   * Fixes situations where there's a bad seek
   *
   * @return {boolean} whether an action was taken to fix the seek
   * @private
   */
  fixesBadSeeks_() {
    const seeking = this.tech_.seeking();

    if (!seeking) {
      return false;
    }

    // TODO: It's possible that these seekable checks should be moved out of this function
    // and into a function that runs on seekablechange. It's also possible that we only need
    // afterSeekableWindow as the buffered check at the bottom is good enough to handle before
    // seekable range.
    const seekable = this.seekable();
    const currentTime = this.tech_.currentTime();
    const isAfterSeekableRange = this.afterSeekableWindow_(
      seekable,
      currentTime,
      this.media(),
      this.allowSeeksWithinUnsafeLiveWindow
    );
    let seekTo;

    if (isAfterSeekableRange) {
      const seekableEnd = seekable.end(seekable.length - 1);

      // sync to live point (if VOD, our seekable was updated and we're simply adjusting)
      seekTo = seekableEnd;
    }

    if (this.beforeSeekableWindow_(seekable, currentTime)) {
      const seekableStart = seekable.start(0);

      // sync to the beginning of the live window
      // provide a buffer of .1 seconds to handle rounding/imprecise numbers
      seekTo = seekableStart +
        // if the playlist is too short and the seekable range is an exact time (can
        // happen in live with a 3 segment playlist), then don't use a time delta
        (seekableStart === seekable.end(0) ? 0 : Ranges.SAFE_TIME_DELTA);
    }

    if (typeof seekTo !== 'undefined') {
      this.logger_(`Trying to seek outside of seekable at time ${currentTime} with ` +
                  `seekable range ${Ranges.printableRange(seekable)}. Seeking to ` +
                  `${seekTo}.`);

      this.tech_.setCurrentTime(seekTo);
      return true;
    }

    const sourceUpdater = this.masterPlaylistController_.sourceUpdater_;
    const buffered = this.tech_.buffered();
    const audioBuffered = sourceUpdater.audioBuffer ? sourceUpdater.audioBuffered() : null;
    const videoBuffered = sourceUpdater.videoBuffer ? sourceUpdater.videoBuffered() : null;
    const media = this.media();

    // verify that at least two segment durations or one part duration have been
    // appended before checking for a gap.
    const minAppendedDuration = media.partTargetDuration ? media.partTargetDuration :
      (media.targetDuration - Ranges.TIME_FUDGE_FACTOR) * 2;

    // verify that at least two segment durations have been
    // appended before checking for a gap.
    const bufferedToCheck = [audioBuffered, videoBuffered];

    for (let i = 0; i < bufferedToCheck.length; i++) {
      // skip null buffered
      if (!bufferedToCheck[i]) {
        continue;
      }

      const timeAhead = Ranges.timeAheadOf(bufferedToCheck[i], currentTime);

      // if we are less than two video/audio segment durations or one part
      // duration behind we haven't appended enough to call this a bad seek.
      if (timeAhead < minAppendedDuration) {
        return false;
      }
    }

    const nextRange = Ranges.findNextRange(buffered, currentTime);

    // we have appended enough content, but we don't have anything buffered
    // to seek over the gap
    if (nextRange.length === 0) {
      return false;
    }

    seekTo = nextRange.start(0) + Ranges.SAFE_TIME_DELTA;

    this.logger_(`Buffered region starts (${nextRange.start(0)}) ` +
      ` just beyond seek point (${currentTime}). Seeking to ${seekTo}.`);

    this.tech_.setCurrentTime(seekTo);

    return true;
  }

  /**
   * Handler for situations when we determine the player is waiting.
   *
   * @private
   */
  waiting_() {
    if (this.techWaiting_()) {
      return;
    }

    // All tech waiting checks failed. Use last resort correction
    const currentTime = this.tech_.currentTime();
    const buffered = this.tech_.buffered();
    const currentRange = Ranges.findRange(buffered, currentTime);

    // Sometimes the player can stall for unknown reasons within a contiguous buffered
    // region with no indication that anything is amiss (seen in Firefox). Seeking to
    // currentTime is usually enough to kickstart the player. This checks that the player
    // is currently within a buffered region before attempting a corrective seek.
    // Chrome does not appear to continue `timeupdate` events after a `waiting` event
    // until there is ~ 3 seconds of forward buffer available. PlaybackWatcher should also
    // make sure there is ~3 seconds of forward buffer before taking any corrective action
    // to avoid triggering an `unknownwaiting` event when the network is slow.
    if (currentRange.length && currentTime + 3 <= currentRange.end(0)) {
      this.cancelTimer_();
      this.tech_.setCurrentTime(currentTime);

      this.logger_(`Stopped at ${currentTime} while inside a buffered region ` +
        `[${currentRange.start(0)} -> ${currentRange.end(0)}]. Attempting to resume ` +
        'playback by seeking to the current time.');

      // unknown waiting corrections may be useful for monitoring QoS
      this.tech_.trigger({type: 'usage', name: 'vhs-unknown-waiting'});
      this.tech_.trigger({type: 'usage', name: 'hls-unknown-waiting'});
      return;
    }
  }

  /**
   * Handler for situations when the tech fires a `waiting` event
   *
   * @return {boolean}
   *         True if an action (or none) was needed to correct the waiting. False if no
   *         checks passed
   * @private
   */
  techWaiting_() {
    const seekable = this.seekable();
    const currentTime = this.tech_.currentTime();

    if (this.tech_.seeking() || this.timer_ !== null) {
      // Tech is seeking or already waiting on another action, no action needed
      return true;
    }

    if (this.beforeSeekableWindow_(seekable, currentTime)) {
      const livePoint = seekable.end(seekable.length - 1);

      this.logger_(`Fell out of live window at time ${currentTime}. Seeking to ` +
                   `live point (seekable end) ${livePoint}`);
      this.cancelTimer_();
      this.tech_.setCurrentTime(livePoint);

      // live window resyncs may be useful for monitoring QoS
      this.tech_.trigger({type: 'usage', name: 'vhs-live-resync'});
      this.tech_.trigger({type: 'usage', name: 'hls-live-resync'});
      return true;
    }

    const sourceUpdater = this.tech_.vhs.masterPlaylistController_.sourceUpdater_;
    const buffered = this.tech_.buffered();
    const videoUnderflow = this.videoUnderflow_({
      audioBuffered: sourceUpdater.audioBuffered(),
      videoBuffered: sourceUpdater.videoBuffered(),
      currentTime
    });

    if (videoUnderflow) {
      // Even though the video underflowed and was stuck in a gap, the audio overplayed
      // the gap, leading currentTime into a buffered range. Seeking to currentTime
      // allows the video to catch up to the audio position without losing any audio
      // (only suffering ~3 seconds of frozen video and a pause in audio playback).
      this.cancelTimer_();
      this.tech_.setCurrentTime(currentTime);

      // video underflow may be useful for monitoring QoS
      this.tech_.trigger({type: 'usage', name: 'vhs-video-underflow'});
      this.tech_.trigger({type: 'usage', name: 'hls-video-underflow'});
      return true;
    }
    const nextRange = Ranges.findNextRange(buffered, currentTime);

    // check for gap
    if (nextRange.length > 0) {
      const difference = nextRange.start(0) - currentTime;

      this.logger_(`Stopped at ${currentTime}, setting timer for ${difference}, seeking ` +
        `to ${nextRange.start(0)}`);

      this.cancelTimer_();

      this.timer_ = setTimeout(
        this.skipTheGap_.bind(this),
        difference * 1000,
        currentTime
      );
      return true;
    }

    // All checks failed. Returning false to indicate failure to correct waiting
    return false;
  }

  afterSeekableWindow_(seekable, currentTime, playlist, allowSeeksWithinUnsafeLiveWindow = false) {
    if (!seekable.length) {
      // we can't make a solid case if there's no seekable, default to false
      return false;
    }

    let allowedEnd = seekable.end(seekable.length - 1) + Ranges.SAFE_TIME_DELTA;
    const isLive = !playlist.endList;

    if (isLive && allowSeeksWithinUnsafeLiveWindow) {
      allowedEnd = seekable.end(seekable.length - 1) + (playlist.targetDuration * 3);
    }

    if (currentTime > allowedEnd) {
      return true;
    }

    return false;
  }

  beforeSeekableWindow_(seekable, currentTime) {
    if (seekable.length &&
        // can't fall before 0 and 0 seekable start identifies VOD stream
        seekable.start(0) > 0 &&
        currentTime < seekable.start(0) - this.liveRangeSafeTimeDelta) {
      return true;
    }

    return false;
  }

  videoUnderflow_({videoBuffered, audioBuffered, currentTime}) {
    // audio only content will not have video underflow :)
    if (!videoBuffered) {
      return;
    }
    let gap;

    // find a gap in demuxed content.
    if (videoBuffered.length && audioBuffered.length) {
      // in Chrome audio will continue to play for ~3s when we run out of video
      // so we have to check that the video buffer did have some buffer in the
      // past.
      const lastVideoRange = Ranges.findRange(videoBuffered, currentTime - 3);
      const videoRange = Ranges.findRange(videoBuffered, currentTime);
      const audioRange = Ranges.findRange(audioBuffered, currentTime);

      if (audioRange.length && !videoRange.length && lastVideoRange.length) {
        gap = {start: lastVideoRange.end(0), end: audioRange.end(0)};
      }

    // find a gap in muxed content.
    } else {
      const nextRange = Ranges.findNextRange(videoBuffered, currentTime);

      // Even if there is no available next range, there is still a possibility we are
      // stuck in a gap due to video underflow.
      if (!nextRange.length) {
        gap = this.gapFromVideoUnderflow_(videoBuffered, currentTime);
      }
    }

    if (gap) {
      this.logger_(`Encountered a gap in video from ${gap.start} to ${gap.end}. ` +
        `Seeking to current time ${currentTime}`);

      return true;
    }

    return false;
  }

  /**
   * Timer callback. If playback still has not proceeded, then we seek
   * to the start of the next buffered region.
   *
   * @private
   */
  skipTheGap_(scheduledCurrentTime) {
    const buffered = this.tech_.buffered();
    const currentTime = this.tech_.currentTime();
    const nextRange = Ranges.findNextRange(buffered, currentTime);

    this.cancelTimer_();

    if (nextRange.length === 0 ||
        currentTime !== scheduledCurrentTime) {
      return;
    }

    this.logger_(
      'skipTheGap_:',
      'currentTime:', currentTime,
      'scheduled currentTime:', scheduledCurrentTime,
      'nextRange start:', nextRange.start(0)
    );

    // only seek if we still have not played
    this.tech_.setCurrentTime(nextRange.start(0) + Ranges.TIME_FUDGE_FACTOR);

    this.tech_.trigger({type: 'usage', name: 'vhs-gap-skip'});
    this.tech_.trigger({type: 'usage', name: 'hls-gap-skip'});
  }

  gapFromVideoUnderflow_(buffered, currentTime) {
    // At least in Chrome, if there is a gap in the video buffer, the audio will continue
    // playing for ~3 seconds after the video gap starts. This is done to account for
    // video buffer underflow/underrun (note that this is not done when there is audio
    // buffer underflow/underrun -- in that case the video will stop as soon as it
    // encounters the gap, as audio stalls are more noticeable/jarring to a user than
    // video stalls). The player's time will reflect the playthrough of audio, so the
    // time will appear as if we are in a buffered region, even if we are stuck in a
    // "gap."
    //
    // Example:
    // video buffer:   0 => 10.1, 10.2 => 20
    // audio buffer:   0 => 20
    // overall buffer: 0 => 10.1, 10.2 => 20
    // current time: 13
    //
    // Chrome's video froze at 10 seconds, where the video buffer encountered the gap,
    // however, the audio continued playing until it reached ~3 seconds past the gap
    // (13 seconds), at which point it stops as well. Since current time is past the
    // gap, findNextRange will return no ranges.
    //
    // To check for this issue, we see if there is a gap that starts somewhere within
    // a 3 second range (3 seconds +/- 1 second) back from our current time.
    const gaps = Ranges.findGaps(buffered);

    for (let i = 0; i < gaps.length; i++) {
      const start = gaps.start(i);
      const end = gaps.end(i);

      // gap is starts no more than 4 seconds back
      if (currentTime - start < 4 && currentTime - start > 2) {
        return {
          start,
          end
        };
      }
    }

    return null;
  }
}
