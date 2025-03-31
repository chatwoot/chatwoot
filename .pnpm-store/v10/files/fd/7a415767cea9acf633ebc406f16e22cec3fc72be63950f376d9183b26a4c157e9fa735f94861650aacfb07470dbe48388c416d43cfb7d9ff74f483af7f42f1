/**
 * @file segment-loader.js
 */
import Playlist from './playlist';
import videojs from 'video.js';
import Config from './config';
import window from 'global/window';
import { initSegmentId, segmentKeyId } from './bin-utils';
import { mediaSegmentRequest, REQUEST_ERRORS } from './media-segment-request';
import segmentTransmuxer from './segment-transmuxer';
import { TIME_FUDGE_FACTOR, timeUntilRebuffer as timeUntilRebuffer_ } from './ranges';
import { minRebufferMaxBandwidthSelector } from './playlist-selectors';
import logger from './util/logger';
import { concatSegments } from './util/segment';
import {
  createCaptionsTrackIfNotExists,
  createMetadataTrackIfNotExists,
  addMetadata,
  addCaptionData,
  removeCuesFromTrack
} from './util/text-tracks';
import { gopsSafeToAlignWith, removeGopBuffer, updateGopBuffer } from './util/gops';
import shallowEqual from './util/shallow-equal.js';
import { QUOTA_EXCEEDED_ERR } from './error-codes';
import {timeRangesToArray, lastBufferedEnd, timeAheadOf} from './ranges.js';
import {getKnownPartCount} from './playlist.js';

/**
 * The segment loader has no recourse except to fetch a segment in the
 * current playlist and use the internal timestamps in that segment to
 * generate a syncPoint. This function returns a good candidate index
 * for that process.
 *
 * @param {Array} segments - the segments array from a playlist.
 * @return {number} An index of a segment from the playlist to load
 */
export const getSyncSegmentCandidate = function(currentTimeline, segments, targetTime) {
  segments = segments || [];
  const timelineSegments = [];
  let time = 0;

  for (let i = 0; i < segments.length; i++) {
    const segment = segments[i];

    if (currentTimeline === segment.timeline) {
      timelineSegments.push(i);
      time += segment.duration;

      if (time > targetTime) {
        return i;
      }
    }
  }

  if (timelineSegments.length === 0) {
    return 0;
  }

  // default to the last timeline segment
  return timelineSegments[timelineSegments.length - 1];
};

// In the event of a quota exceeded error, keep at least one second of back buffer. This
// number was arbitrarily chosen and may be updated in the future, but seemed reasonable
// as a start to prevent any potential issues with removing content too close to the
// playhead.
const MIN_BACK_BUFFER = 1;

// in ms
const CHECK_BUFFER_DELAY = 500;
const finite = (num) => typeof num === 'number' && isFinite(num);
// With most content hovering around 30fps, if a segment has a duration less than a half
// frame at 30fps or one frame at 60fps, the bandwidth and throughput calculations will
// not accurately reflect the rest of the content.
const MIN_SEGMENT_DURATION_TO_SAVE_STATS = 1 / 60;

export const illegalMediaSwitch = (loaderType, startingMedia, trackInfo) => {
  // Although these checks should most likely cover non 'main' types, for now it narrows
  // the scope of our checks.
  if (loaderType !== 'main' || !startingMedia || !trackInfo) {
    return null;
  }

  if (!trackInfo.hasAudio && !trackInfo.hasVideo) {
    return 'Neither audio nor video found in segment.';
  }

  if (startingMedia.hasVideo && !trackInfo.hasVideo) {
    return 'Only audio found in segment when we expected video.' +
      ' We can\'t switch to audio only from a stream that had video.' +
      ' To get rid of this message, please add codec information to the manifest.';
  }

  if (!startingMedia.hasVideo && trackInfo.hasVideo) {
    return 'Video found in segment when we expected only audio.' +
      ' We can\'t switch to a stream with video from an audio only stream.' +
      ' To get rid of this message, please add codec information to the manifest.';
  }

  return null;
};

/**
 * Calculates a time value that is safe to remove from the back buffer without interrupting
 * playback.
 *
 * @param {TimeRange} seekable
 *        The current seekable range
 * @param {number} currentTime
 *        The current time of the player
 * @param {number} targetDuration
 *        The target duration of the current playlist
 * @return {number}
 *         Time that is safe to remove from the back buffer without interrupting playback
 */
export const safeBackBufferTrimTime = (seekable, currentTime, targetDuration) => {
  // 30 seconds before the playhead provides a safe default for trimming.
  //
  // Choosing a reasonable default is particularly important for high bitrate content and
  // VOD videos/live streams with large windows, as the buffer may end up overfilled and
  // throw an APPEND_BUFFER_ERR.
  let trimTime = currentTime - Config.BACK_BUFFER_LENGTH;

  if (seekable.length) {
    // Some live playlists may have a shorter window of content than the full allowed back
    // buffer. For these playlists, don't save content that's no longer within the window.
    trimTime = Math.max(trimTime, seekable.start(0));
  }

  // Don't remove within target duration of the current time to avoid the possibility of
  // removing the GOP currently being played, as removing it can cause playback stalls.
  const maxTrimTime = currentTime - targetDuration;

  return Math.min(maxTrimTime, trimTime);
};

export const segmentInfoString = (segmentInfo) => {
  const {
    startOfSegment,
    duration,
    segment,
    part,
    playlist: {
      mediaSequence: seq,
      id,
      segments = []
    },
    mediaIndex: index,
    partIndex,
    timeline
  } = segmentInfo;

  const segmentLen = segments.length - 1;
  let selection = 'mediaIndex/partIndex increment';

  if (segmentInfo.getMediaInfoForTime) {
    selection = `getMediaInfoForTime (${segmentInfo.getMediaInfoForTime})`;
  } else if (segmentInfo.isSyncRequest) {
    selection = 'getSyncSegmentCandidate (isSyncRequest)';
  }

  if (segmentInfo.independent) {
    selection += ` with independent ${segmentInfo.independent}`;
  }

  const hasPartIndex = typeof partIndex === 'number';
  const name = segmentInfo.segment.uri ? 'segment' : 'pre-segment';
  const zeroBasedPartCount = hasPartIndex ? getKnownPartCount({preloadSegment: segment}) - 1 : 0;

  return `${name} [${seq + index}/${seq + segmentLen}]` +
    (hasPartIndex ? ` part [${partIndex}/${zeroBasedPartCount}]` : '') +
    ` segment start/end [${segment.start} => ${segment.end}]` +
    (hasPartIndex ? ` part start/end [${part.start} => ${part.end}]` : '') +
    ` startOfSegment [${startOfSegment}]` +
    ` duration [${duration}]` +
    ` timeline [${timeline}]` +
    ` selected by [${selection}]` +
    ` playlist [${id}]`;
};

const timingInfoPropertyForMedia = (mediaType) => `${mediaType}TimingInfo`;

/**
 * Returns the timestamp offset to use for the segment.
 *
 * @param {number} segmentTimeline
 *        The timeline of the segment
 * @param {number} currentTimeline
 *        The timeline currently being followed by the loader
 * @param {number} startOfSegment
 *        The estimated segment start
 * @param {TimeRange[]} buffered
 *        The loader's buffer
 * @param {boolean} overrideCheck
 *        If true, no checks are made to see if the timestamp offset value should be set,
 *        but sets it directly to a value.
 *
 * @return {number|null}
 *         Either a number representing a new timestamp offset, or null if the segment is
 *         part of the same timeline
 */
export const timestampOffsetForSegment = ({
  segmentTimeline,
  currentTimeline,
  startOfSegment,
  buffered,
  overrideCheck
}) => {
  // Check to see if we are crossing a discontinuity to see if we need to set the
  // timestamp offset on the transmuxer and source buffer.
  //
  // Previously, we changed the timestampOffset if the start of this segment was less than
  // the currently set timestampOffset, but this isn't desirable as it can produce bad
  // behavior, especially around long running live streams.
  if (!overrideCheck && segmentTimeline === currentTimeline) {
    return null;
  }

  // When changing renditions, it's possible to request a segment on an older timeline. For
  // instance, given two renditions with the following:
  //
  // #EXTINF:10
  // segment1
  // #EXT-X-DISCONTINUITY
  // #EXTINF:10
  // segment2
  // #EXTINF:10
  // segment3
  //
  // And the current player state:
  //
  // current time: 8
  // buffer: 0 => 20
  //
  // The next segment on the current rendition would be segment3, filling the buffer from
  // 20s onwards. However, if a rendition switch happens after segment2 was requested,
  // then the next segment to be requested will be segment1 from the new rendition in
  // order to fill time 8 and onwards. Using the buffered end would result in repeated
  // content (since it would position segment1 of the new rendition starting at 20s). This
  // case can be identified when the new segment's timeline is a prior value. Instead of
  // using the buffered end, the startOfSegment can be used, which, hopefully, will be
  // more accurate to the actual start time of the segment.
  if (segmentTimeline < currentTimeline) {
    return startOfSegment;
  }

  // segmentInfo.startOfSegment used to be used as the timestamp offset, however, that
  // value uses the end of the last segment if it is available. While this value
  // should often be correct, it's better to rely on the buffered end, as the new
  // content post discontinuity should line up with the buffered end as if it were
  // time 0 for the new content.
  return buffered.length ? buffered.end(buffered.length - 1) : startOfSegment;
};

/**
 * Returns whether or not the loader should wait for a timeline change from the timeline
 * change controller before processing the segment.
 *
 * Primary timing in VHS goes by video. This is different from most media players, as
 * audio is more often used as the primary timing source. For the foreseeable future, VHS
 * will continue to use video as the primary timing source, due to the current logic and
 * expectations built around it.

 * Since the timing follows video, in order to maintain sync, the video loader is
 * responsible for setting both audio and video source buffer timestamp offsets.
 *
 * Setting different values for audio and video source buffers could lead to
 * desyncing. The following examples demonstrate some of the situations where this
 * distinction is important. Note that all of these cases involve demuxed content. When
 * content is muxed, the audio and video are packaged together, therefore syncing
 * separate media playlists is not an issue.
 *
 * CASE 1: Audio prepares to load a new timeline before video:
 *
 * Timeline:       0                 1
 * Audio Segments: 0 1 2 3 4 5 DISCO 6 7 8 9
 * Audio Loader:                     ^
 * Video Segments: 0 1 2 3 4 5 DISCO 6 7 8 9
 * Video Loader              ^
 *
 * In the above example, the audio loader is preparing to load the 6th segment, the first
 * after a discontinuity, while the video loader is still loading the 5th segment, before
 * the discontinuity.
 *
 * If the audio loader goes ahead and loads and appends the 6th segment before the video
 * loader crosses the discontinuity, then when appended, the 6th audio segment will use
 * the timestamp offset from timeline 0. This will likely lead to desyncing. In addition,
 * the audio loader must provide the audioAppendStart value to trim the content in the
 * transmuxer, and that value relies on the audio timestamp offset. Since the audio
 * timestamp offset is set by the video (main) loader, the audio loader shouldn't load the
 * segment until that value is provided.
 *
 * CASE 2: Video prepares to load a new timeline before audio:
 *
 * Timeline:       0                 1
 * Audio Segments: 0 1 2 3 4 5 DISCO 6 7 8 9
 * Audio Loader:             ^
 * Video Segments: 0 1 2 3 4 5 DISCO 6 7 8 9
 * Video Loader                      ^
 *
 * In the above example, the video loader is preparing to load the 6th segment, the first
 * after a discontinuity, while the audio loader is still loading the 5th segment, before
 * the discontinuity.
 *
 * If the video loader goes ahead and loads and appends the 6th segment, then once the
 * segment is loaded and processed, both the video and audio timestamp offsets will be
 * set, since video is used as the primary timing source. This is to ensure content lines
 * up appropriately, as any modifications to the video timing are reflected by audio when
 * the video loader sets the audio and video timestamp offsets to the same value. However,
 * setting the timestamp offset for audio before audio has had a chance to change
 * timelines will likely lead to desyncing, as the audio loader will append segment 5 with
 * a timestamp intended to apply to segments from timeline 1 rather than timeline 0.
 *
 * CASE 3: When seeking, audio prepares to load a new timeline before video
 *
 * Timeline:       0                 1
 * Audio Segments: 0 1 2 3 4 5 DISCO 6 7 8 9
 * Audio Loader:           ^
 * Video Segments: 0 1 2 3 4 5 DISCO 6 7 8 9
 * Video Loader            ^
 *
 * In the above example, both audio and video loaders are loading segments from timeline
 * 0, but imagine that the seek originated from timeline 1.
 *
 * When seeking to a new timeline, the timestamp offset will be set based on the expected
 * segment start of the loaded video segment. In order to maintain sync, the audio loader
 * must wait for the video loader to load its segment and update both the audio and video
 * timestamp offsets before it may load and append its own segment. This is the case
 * whether the seek results in a mismatched segment request (e.g., the audio loader
 * chooses to load segment 3 and the video loader chooses to load segment 4) or the
 * loaders choose to load the same segment index from each playlist, as the segments may
 * not be aligned perfectly, even for matching segment indexes.
 *
 * @param {Object} timelinechangeController
 * @param {number} currentTimeline
 *        The timeline currently being followed by the loader
 * @param {number} segmentTimeline
 *        The timeline of the segment being loaded
 * @param {('main'|'audio')} loaderType
 *        The loader type
 * @param {boolean} audioDisabled
 *        Whether the audio is disabled for the loader. This should only be true when the
 *        loader may have muxed audio in its segment, but should not append it, e.g., for
 *        the main loader when an alternate audio playlist is active.
 *
 * @return {boolean}
 *         Whether the loader should wait for a timeline change from the timeline change
 *         controller before processing the segment
 */
export const shouldWaitForTimelineChange = ({
  timelineChangeController,
  currentTimeline,
  segmentTimeline,
  loaderType,
  audioDisabled
}) => {
  if (currentTimeline === segmentTimeline) {
    return false;
  }

  if (loaderType === 'audio') {
    const lastMainTimelineChange = timelineChangeController.lastTimelineChange({
      type: 'main'
    });

    // Audio loader should wait if:
    //
    // * main hasn't had a timeline change yet (thus has not loaded its first segment)
    // * main hasn't yet changed to the timeline audio is looking to load
    return !lastMainTimelineChange || lastMainTimelineChange.to !== segmentTimeline;
  }

  // The main loader only needs to wait for timeline changes if there's demuxed audio.
  // Otherwise, there's nothing to wait for, since audio would be muxed into the main
  // loader's segments (or the content is audio/video only and handled by the main
  // loader).
  if (loaderType === 'main' && audioDisabled) {
    const pendingAudioTimelineChange = timelineChangeController.pendingTimelineChange({
      type: 'audio'
    });

    // Main loader should wait for the audio loader if audio is not pending a timeline
    // change to the current timeline.
    //
    // Since the main loader is responsible for setting the timestamp offset for both
    // audio and video, the main loader must wait for audio to be about to change to its
    // timeline before setting the offset, otherwise, if audio is behind in loading,
    // segments from the previous timeline would be adjusted by the new timestamp offset.
    //
    // This requirement means that video will not cross a timeline until the audio is
    // about to cross to it, so that way audio and video will always cross the timeline
    // together.
    //
    // In addition to normal timeline changes, these rules also apply to the start of a
    // stream (going from a non-existent timeline, -1, to timeline 0). It's important
    // that these rules apply to the first timeline change because if they did not, it's
    // possible that the main loader will cross two timelines before the audio loader has
    // crossed one. Logic may be implemented to handle the startup as a special case, but
    // it's easier to simply treat all timeline changes the same.
    if (pendingAudioTimelineChange && pendingAudioTimelineChange.to === segmentTimeline) {
      return false;
    }

    return true;
  }

  return false;
};

export const mediaDuration = (timingInfos) => {
  let maxDuration = 0;

  ['video', 'audio'].forEach(function(type) {
    const typeTimingInfo = timingInfos[`${type}TimingInfo`];

    if (!typeTimingInfo) {
      return;
    }
    const {start, end} = typeTimingInfo;
    let duration;

    if (typeof start === 'bigint' || typeof end === 'bigint') {
      duration = window.BigInt(end) - window.BigInt(start);
    } else if (typeof start === 'number' && typeof end === 'number') {
      duration = end - start;
    }

    if (typeof duration !== 'undefined' && duration > maxDuration) {
      maxDuration = duration;
    }
  });

  // convert back to a number if it is lower than MAX_SAFE_INTEGER
  // as we only need BigInt when we are above that.
  if (typeof maxDuration === 'bigint' && maxDuration < Number.MAX_SAFE_INTEGER) {
    maxDuration = Number(maxDuration);
  }

  return maxDuration;
};

export const segmentTooLong = ({ segmentDuration, maxDuration }) => {
  // 0 duration segments are most likely due to metadata only segments or a lack of
  // information.
  if (!segmentDuration) {
    return false;
  }

  // For HLS:
  //
  // https://tools.ietf.org/html/draft-pantos-http-live-streaming-23#section-4.3.3.1
  // The EXTINF duration of each Media Segment in the Playlist
  // file, when rounded to the nearest integer, MUST be less than or equal
  // to the target duration; longer segments can trigger playback stalls
  // or other errors.
  //
  // For DASH, the mpd-parser uses the largest reported segment duration as the target
  // duration. Although that reported duration is occasionally approximate (i.e., not
  // exact), a strict check may report that a segment is too long more often in DASH.
  return Math.round(segmentDuration) > maxDuration + TIME_FUDGE_FACTOR;
};

export const getTroublesomeSegmentDurationMessage = (segmentInfo, sourceType) => {
  // Right now we aren't following DASH's timing model exactly, so only perform
  // this check for HLS content.
  if (sourceType !== 'hls') {
    return null;
  }

  const segmentDuration = mediaDuration({
    audioTimingInfo: segmentInfo.audioTimingInfo,
    videoTimingInfo: segmentInfo.videoTimingInfo
  });

  // Don't report if we lack information.
  //
  // If the segment has a duration of 0 it is either a lack of information or a
  // metadata only segment and shouldn't be reported here.
  if (!segmentDuration) {
    return null;
  }

  const targetDuration = segmentInfo.playlist.targetDuration;

  const isSegmentWayTooLong = segmentTooLong({
    segmentDuration,
    maxDuration: targetDuration * 2
  });
  const isSegmentSlightlyTooLong = segmentTooLong({
    segmentDuration,
    maxDuration: targetDuration
  });

  const segmentTooLongMessage = `Segment with index ${segmentInfo.mediaIndex} ` +
    `from playlist ${segmentInfo.playlist.id} ` +
    `has a duration of ${segmentDuration} ` +
    `when the reported duration is ${segmentInfo.duration} ` +
    `and the target duration is ${targetDuration}. ` +
    'For HLS content, a duration in excess of the target duration may result in ' +
    'playback issues. See the HLS specification section on EXT-X-TARGETDURATION for ' +
    'more details: ' +
    'https://tools.ietf.org/html/draft-pantos-http-live-streaming-23#section-4.3.3.1';

  if (isSegmentWayTooLong || isSegmentSlightlyTooLong) {
    return {
      severity: isSegmentWayTooLong ? 'warn' : 'info',
      message: segmentTooLongMessage
    };
  }

  return null;
};

/**
 * An object that manages segment loading and appending.
 *
 * @class SegmentLoader
 * @param {Object} options required and optional options
 * @extends videojs.EventTarget
 */
export default class SegmentLoader extends videojs.EventTarget {
  constructor(settings, options = {}) {
    super();
    // check pre-conditions
    if (!settings) {
      throw new TypeError('Initialization settings are required');
    }
    if (typeof settings.currentTime !== 'function') {
      throw new TypeError('No currentTime getter specified');
    }
    if (!settings.mediaSource) {
      throw new TypeError('No MediaSource specified');
    }
    // public properties
    this.bandwidth = settings.bandwidth;
    this.throughput = {rate: 0, count: 0};
    this.roundTrip = NaN;
    this.resetStats_();
    this.mediaIndex = null;
    this.partIndex = null;

    // private settings
    this.hasPlayed_ = settings.hasPlayed;
    this.currentTime_ = settings.currentTime;
    this.seekable_ = settings.seekable;
    this.seeking_ = settings.seeking;
    this.duration_ = settings.duration;
    this.mediaSource_ = settings.mediaSource;
    this.vhs_ = settings.vhs;
    this.loaderType_ = settings.loaderType;
    this.currentMediaInfo_ = void 0;
    this.startingMediaInfo_ = void 0;
    this.segmentMetadataTrack_ = settings.segmentMetadataTrack;
    this.goalBufferLength_ = settings.goalBufferLength;
    this.sourceType_ = settings.sourceType;
    this.sourceUpdater_ = settings.sourceUpdater;
    this.inbandTextTracks_ = settings.inbandTextTracks;
    this.state_ = 'INIT';
    this.timelineChangeController_ = settings.timelineChangeController;
    this.shouldSaveSegmentTimingInfo_ = true;
    this.parse708captions_ = settings.parse708captions;
    this.captionServices_ = settings.captionServices;
    this.experimentalExactManifestTimings = settings.experimentalExactManifestTimings;

    // private instance variables
    this.checkBufferTimeout_ = null;
    this.error_ = void 0;
    this.currentTimeline_ = -1;
    this.pendingSegment_ = null;
    this.xhrOptions_ = null;
    this.pendingSegments_ = [];
    this.audioDisabled_ = false;
    this.isPendingTimestampOffset_ = false;
    // TODO possibly move gopBuffer and timeMapping info to a separate controller
    this.gopBuffer_ = [];
    this.timeMapping_ = 0;
    this.safeAppend_ = videojs.browser.IE_VERSION >= 11;
    this.appendInitSegment_ = {
      audio: true,
      video: true
    };
    this.playlistOfLastInitSegment_ = {
      audio: null,
      video: null
    };
    this.callQueue_ = [];
    // If the segment loader prepares to load a segment, but does not have enough
    // information yet to start the loading process (e.g., if the audio loader wants to
    // load a segment from the next timeline but the main loader hasn't yet crossed that
    // timeline), then the load call will be added to the queue until it is ready to be
    // processed.
    this.loadQueue_ = [];
    this.metadataQueue_ = {
      id3: [],
      caption: []
    };
    this.waitingOnRemove_ = false;
    this.quotaExceededErrorRetryTimeout_ = null;

    // Fragmented mp4 playback
    this.activeInitSegmentId_ = null;
    this.initSegments_ = {};

    // HLSe playback
    this.cacheEncryptionKeys_ = settings.cacheEncryptionKeys;
    this.keyCache_ = {};

    this.decrypter_ = settings.decrypter;

    // Manages the tracking and generation of sync-points, mappings
    // between a time in the display time and a segment index within
    // a playlist
    this.syncController_ = settings.syncController;
    this.syncPoint_ = {
      segmentIndex: 0,
      time: 0
    };

    this.transmuxer_ = this.createTransmuxer_();
    this.triggerSyncInfoUpdate_ = () => this.trigger('syncinfoupdate');
    this.syncController_.on('syncinfoupdate', this.triggerSyncInfoUpdate_);

    this.mediaSource_.addEventListener('sourceopen', () => {
      if (!this.isEndOfStream_()) {
        this.ended_ = false;
      }
    });

    // ...for determining the fetch location
    this.fetchAtBuffer_ = false;

    this.logger_ = logger(`SegmentLoader[${this.loaderType_}]`);

    Object.defineProperty(this, 'state', {
      get() {
        return this.state_;
      },
      set(newState) {
        if (newState !== this.state_) {
          this.logger_(`${this.state_} -> ${newState}`);
          this.state_ = newState;
          this.trigger('statechange');
        }
      }
    });

    this.sourceUpdater_.on('ready', () => {
      if (this.hasEnoughInfoToAppend_()) {
        this.processCallQueue_();
      }
    });

    // Only the main loader needs to listen for pending timeline changes, as the main
    // loader should wait for audio to be ready to change its timeline so that both main
    // and audio timelines change together. For more details, see the
    // shouldWaitForTimelineChange function.
    if (this.loaderType_ === 'main') {
      this.timelineChangeController_.on('pendingtimelinechange', () => {
        if (this.hasEnoughInfoToAppend_()) {
          this.processCallQueue_();
        }
      });
    }
    // The main loader only listens on pending timeline changes, but the audio loader,
    // since its loads follow main, needs to listen on timeline changes. For more details,
    // see the shouldWaitForTimelineChange function.
    if (this.loaderType_ === 'audio') {
      this.timelineChangeController_.on('timelinechange', () => {
        if (this.hasEnoughInfoToLoad_()) {
          this.processLoadQueue_();
        }
        if (this.hasEnoughInfoToAppend_()) {
          this.processCallQueue_();
        }
      });
    }
  }

  createTransmuxer_() {
    return segmentTransmuxer.createTransmuxer({
      remux: false,
      alignGopsAtEnd: this.safeAppend_,
      keepOriginalTimestamps: true,
      parse708captions: this.parse708captions_,
      captionServices: this.captionServices_
    });
  }

  /**
   * reset all of our media stats
   *
   * @private
   */
  resetStats_() {
    this.mediaBytesTransferred = 0;
    this.mediaRequests = 0;
    this.mediaRequestsAborted = 0;
    this.mediaRequestsTimedout = 0;
    this.mediaRequestsErrored = 0;
    this.mediaTransferDuration = 0;
    this.mediaSecondsLoaded = 0;
    this.mediaAppends = 0;
  }

  /**
   * dispose of the SegmentLoader and reset to the default state
   */
  dispose() {
    this.trigger('dispose');
    this.state = 'DISPOSED';
    this.pause();
    this.abort_();
    if (this.transmuxer_) {
      this.transmuxer_.terminate();
    }
    this.resetStats_();

    if (this.checkBufferTimeout_) {
      window.clearTimeout(this.checkBufferTimeout_);
    }

    if (this.syncController_ && this.triggerSyncInfoUpdate_) {
      this.syncController_.off('syncinfoupdate', this.triggerSyncInfoUpdate_);
    }

    this.off();
  }

  setAudio(enable) {
    this.audioDisabled_ = !enable;
    if (enable) {
      this.appendInitSegment_.audio = true;
    } else {
      // remove current track audio if it gets disabled
      this.sourceUpdater_.removeAudio(0, this.duration_());
    }
  }

  /**
   * abort anything that is currently doing on with the SegmentLoader
   * and reset to a default state
   */
  abort() {
    if (this.state !== 'WAITING') {
      if (this.pendingSegment_) {
        this.pendingSegment_ = null;
      }
      return;
    }

    this.abort_();

    // We aborted the requests we were waiting on, so reset the loader's state to READY
    // since we are no longer "waiting" on any requests. XHR callback is not always run
    // when the request is aborted. This will prevent the loader from being stuck in the
    // WAITING state indefinitely.
    this.state = 'READY';

    // don't wait for buffer check timeouts to begin fetching the
    // next segment
    if (!this.paused()) {
      this.monitorBuffer_();
    }
  }

  /**
   * abort all pending xhr requests and null any pending segements
   *
   * @private
   */
  abort_() {
    if (this.pendingSegment_ && this.pendingSegment_.abortRequests) {
      this.pendingSegment_.abortRequests();
    }

    // clear out the segment being processed
    this.pendingSegment_ = null;
    this.callQueue_ = [];
    this.loadQueue_ = [];
    this.metadataQueue_.id3 = [];
    this.metadataQueue_.caption = [];
    this.timelineChangeController_.clearPendingTimelineChange(this.loaderType_);
    this.waitingOnRemove_ = false;
    window.clearTimeout(this.quotaExceededErrorRetryTimeout_);
    this.quotaExceededErrorRetryTimeout_ = null;
  }

  checkForAbort_(requestId) {
    // If the state is APPENDING, then aborts will not modify the state, meaning the first
    // callback that happens should reset the state to READY so that loading can continue.
    if (this.state === 'APPENDING' && !this.pendingSegment_) {
      this.state = 'READY';
      return true;
    }

    if (!this.pendingSegment_ || this.pendingSegment_.requestId !== requestId) {
      return true;
    }

    return false;
  }

  /**
   * set an error on the segment loader and null out any pending segements
   *
   * @param {Error} error the error to set on the SegmentLoader
   * @return {Error} the error that was set or that is currently set
   */
  error(error) {
    if (typeof error !== 'undefined') {
      this.logger_('error occurred:', error);
      this.error_ = error;
    }

    this.pendingSegment_ = null;
    return this.error_;
  }

  endOfStream() {
    this.ended_ = true;
    if (this.transmuxer_) {
      // need to clear out any cached data to prepare for the new segment
      segmentTransmuxer.reset(this.transmuxer_);
    }
    this.gopBuffer_.length = 0;
    this.pause();
    this.trigger('ended');
  }

  /**
   * Indicates which time ranges are buffered
   *
   * @return {TimeRange}
   *         TimeRange object representing the current buffered ranges
   */
  buffered_() {
    const trackInfo = this.getMediaInfo_();

    if (!this.sourceUpdater_ || !trackInfo) {
      return videojs.createTimeRanges();
    }

    if (this.loaderType_ === 'main') {
      const { hasAudio, hasVideo, isMuxed } = trackInfo;

      if (hasVideo && hasAudio && !this.audioDisabled_ && !isMuxed) {
        return this.sourceUpdater_.buffered();
      }

      if (hasVideo) {
        return this.sourceUpdater_.videoBuffered();
      }
    }

    // One case that can be ignored for now is audio only with alt audio,
    // as we don't yet have proper support for that.
    return this.sourceUpdater_.audioBuffered();
  }

  /**
   * Gets and sets init segment for the provided map
   *
   * @param {Object} map
   *        The map object representing the init segment to get or set
   * @param {boolean=} set
   *        If true, the init segment for the provided map should be saved
   * @return {Object}
   *         map object for desired init segment
   */
  initSegmentForMap(map, set = false) {
    if (!map) {
      return null;
    }

    const id = initSegmentId(map);
    let storedMap = this.initSegments_[id];

    if (set && !storedMap && map.bytes) {
      this.initSegments_[id] = storedMap = {
        resolvedUri: map.resolvedUri,
        byterange: map.byterange,
        bytes: map.bytes,
        tracks: map.tracks,
        timescales: map.timescales
      };
    }

    return storedMap || map;
  }

  /**
   * Gets and sets key for the provided key
   *
   * @param {Object} key
   *        The key object representing the key to get or set
   * @param {boolean=} set
   *        If true, the key for the provided key should be saved
   * @return {Object}
   *         Key object for desired key
   */
  segmentKey(key, set = false) {
    if (!key) {
      return null;
    }

    const id = segmentKeyId(key);
    let storedKey = this.keyCache_[id];

    // TODO: We should use the HTTP Expires header to invalidate our cache per
    // https://tools.ietf.org/html/draft-pantos-http-live-streaming-23#section-6.2.3
    if (this.cacheEncryptionKeys_ && set && !storedKey && key.bytes) {
      this.keyCache_[id] = storedKey = {
        resolvedUri: key.resolvedUri,
        bytes: key.bytes
      };
    }

    const result = {
      resolvedUri: (storedKey || key).resolvedUri
    };

    if (storedKey) {
      result.bytes = storedKey.bytes;
    }

    return result;
  }

  /**
   * Returns true if all configuration required for loading is present, otherwise false.
   *
   * @return {boolean} True if the all configuration is ready for loading
   * @private
   */
  couldBeginLoading_() {
    return this.playlist_ && !this.paused();
  }

  /**
   * load a playlist and start to fill the buffer
   */
  load() {
    // un-pause
    this.monitorBuffer_();

    // if we don't have a playlist yet, keep waiting for one to be
    // specified
    if (!this.playlist_) {
      return;
    }

    // if all the configuration is ready, initialize and begin loading
    if (this.state === 'INIT' && this.couldBeginLoading_()) {
      return this.init_();
    }

    // if we're in the middle of processing a segment already, don't
    // kick off an additional segment request
    if (!this.couldBeginLoading_() ||
        (this.state !== 'READY' &&
        this.state !== 'INIT')) {
      return;
    }

    this.state = 'READY';
  }

  /**
   * Once all the starting parameters have been specified, begin
   * operation. This method should only be invoked from the INIT
   * state.
   *
   * @private
   */
  init_() {
    this.state = 'READY';
    // if this is the audio segment loader, and it hasn't been inited before, then any old
    // audio data from the muxed content should be removed
    this.resetEverything();
    return this.monitorBuffer_();
  }

  /**
   * set a playlist on the segment loader
   *
   * @param {PlaylistLoader} media the playlist to set on the segment loader
   */
  playlist(newPlaylist, options = {}) {
    if (!newPlaylist) {
      return;
    }
    const oldPlaylist = this.playlist_;
    const segmentInfo = this.pendingSegment_;

    this.playlist_ = newPlaylist;
    this.xhrOptions_ = options;

    // when we haven't started playing yet, the start of a live playlist
    // is always our zero-time so force a sync update each time the playlist
    // is refreshed from the server
    //
    // Use the INIT state to determine if playback has started, as the playlist sync info
    // should be fixed once requests begin (as sync points are generated based on sync
    // info), but not before then.
    if (this.state === 'INIT') {
      newPlaylist.syncInfo = {
        mediaSequence: newPlaylist.mediaSequence,
        time: 0
      };
      // Setting the date time mapping means mapping the program date time (if available)
      // to time 0 on the player's timeline. The playlist's syncInfo serves a similar
      // purpose, mapping the initial mediaSequence to time zero. Since the syncInfo can
      // be updated as the playlist is refreshed before the loader starts loading, the
      // program date time mapping needs to be updated as well.
      //
      // This mapping is only done for the main loader because a program date time should
      // map equivalently between playlists.
      if (this.loaderType_ === 'main') {
        this.syncController_.setDateTimeMappingForStart(newPlaylist);
      }
    }

    let oldId = null;

    if (oldPlaylist) {
      if (oldPlaylist.id) {
        oldId = oldPlaylist.id;
      } else if (oldPlaylist.uri) {
        oldId = oldPlaylist.uri;
      }
    }

    this.logger_(`playlist update [${oldId} => ${newPlaylist.id || newPlaylist.uri}]`);

    // in VOD, this is always a rendition switch (or we updated our syncInfo above)
    // in LIVE, we always want to update with new playlists (including refreshes)
    this.trigger('syncinfoupdate');

    // if we were unpaused but waiting for a playlist, start
    // buffering now
    if (this.state === 'INIT' && this.couldBeginLoading_()) {
      return this.init_();
    }

    if (!oldPlaylist || oldPlaylist.uri !== newPlaylist.uri) {
      if (this.mediaIndex !== null) {
        // we must reset/resync the segment loader when we switch renditions and
        // the segment loader is already synced to the previous rendition

        // on playlist changes we want it to be possible to fetch
        // at the buffer for vod but not for live. So we use resetLoader
        // for live and resyncLoader for vod. We want this because
        // if a playlist uses independent and non-independent segments/parts the
        // buffer may not accurately reflect the next segment that we should try
        // downloading.
        if (!newPlaylist.endList) {
          this.resetLoader();
        } else {
          this.resyncLoader();
        }
      }
      this.currentMediaInfo_ = void 0;
      this.trigger('playlistupdate');

      // the rest of this function depends on `oldPlaylist` being defined
      return;
    }

    // we reloaded the same playlist so we are in a live scenario
    // and we will likely need to adjust the mediaIndex
    const mediaSequenceDiff = newPlaylist.mediaSequence - oldPlaylist.mediaSequence;

    this.logger_(`live window shift [${mediaSequenceDiff}]`);

    // update the mediaIndex on the SegmentLoader
    // this is important because we can abort a request and this value must be
    // equal to the last appended mediaIndex
    if (this.mediaIndex !== null) {
      this.mediaIndex -= mediaSequenceDiff;

      // this can happen if we are going to load the first segment, but get a playlist
      // update during that. mediaIndex would go from 0 to -1 if mediaSequence in the
      // new playlist was incremented by 1.
      if (this.mediaIndex < 0) {
        this.mediaIndex = null;
        this.partIndex = null;
      } else {
        const segment = this.playlist_.segments[this.mediaIndex];

        // partIndex should remain the same for the same segment
        // unless parts fell off of the playlist for this segment.
        // In that case we need to reset partIndex and resync
        if (this.partIndex && (!segment.parts || !segment.parts.length || !segment.parts[this.partIndex])) {
          const mediaIndex = this.mediaIndex;

          this.logger_(`currently processing part (index ${this.partIndex}) no longer exists.`);
          this.resetLoader();

          // We want to throw away the partIndex and the data associated with it,
          // as the part was dropped from our current playlists segment.
          // The mediaIndex will still be valid so keep that around.
          this.mediaIndex = mediaIndex;
        }
      }
    }

    // update the mediaIndex on the SegmentInfo object
    // this is important because we will update this.mediaIndex with this value
    // in `handleAppendsDone_` after the segment has been successfully appended
    if (segmentInfo) {
      segmentInfo.mediaIndex -= mediaSequenceDiff;

      if (segmentInfo.mediaIndex < 0) {
        segmentInfo.mediaIndex = null;
        segmentInfo.partIndex = null;
      } else {
        // we need to update the referenced segment so that timing information is
        // saved for the new playlist's segment, however, if the segment fell off the
        // playlist, we can leave the old reference and just lose the timing info
        if (segmentInfo.mediaIndex >= 0) {
          segmentInfo.segment = newPlaylist.segments[segmentInfo.mediaIndex];
        }

        if (segmentInfo.partIndex >= 0 && segmentInfo.segment.parts) {
          segmentInfo.part = segmentInfo.segment.parts[segmentInfo.partIndex];
        }
      }
    }

    this.syncController_.saveExpiredSegmentInfo(oldPlaylist, newPlaylist);
  }

  /**
   * Prevent the loader from fetching additional segments. If there
   * is a segment request outstanding, it will finish processing
   * before the loader halts. A segment loader can be unpaused by
   * calling load().
   */
  pause() {
    if (this.checkBufferTimeout_) {
      window.clearTimeout(this.checkBufferTimeout_);

      this.checkBufferTimeout_ = null;
    }
  }

  /**
   * Returns whether the segment loader is fetching additional
   * segments when given the opportunity. This property can be
   * modified through calls to pause() and load().
   */
  paused() {
    return this.checkBufferTimeout_ === null;
  }

  /**
   * Delete all the buffered data and reset the SegmentLoader
   *
   * @param {Function} [done] an optional callback to be executed when the remove
   * operation is complete
   */
  resetEverything(done) {
    this.ended_ = false;
    this.appendInitSegment_ = {
      audio: true,
      video: true
    };
    this.resetLoader();

    // remove from 0, the earliest point, to Infinity, to signify removal of everything.
    // VTT Segment Loader doesn't need to do anything but in the regular SegmentLoader,
    // we then clamp the value to duration if necessary.
    this.remove(0, Infinity, done);

    // clears fmp4 captions
    if (this.transmuxer_) {
      this.transmuxer_.postMessage({
        action: 'clearAllMp4Captions'
      });

      // reset the cache in the transmuxer
      this.transmuxer_.postMessage({
        action: 'reset'
      });
    }
  }

  /**
   * Force the SegmentLoader to resync and start loading around the currentTime instead
   * of starting at the end of the buffer
   *
   * Useful for fast quality changes
   */
  resetLoader() {
    this.fetchAtBuffer_ = false;
    this.resyncLoader();
  }

  /**
   * Force the SegmentLoader to restart synchronization and make a conservative guess
   * before returning to the simple walk-forward method
   */
  resyncLoader() {
    if (this.transmuxer_) {
      // need to clear out any cached data to prepare for the new segment
      segmentTransmuxer.reset(this.transmuxer_);
    }
    this.mediaIndex = null;
    this.partIndex = null;
    this.syncPoint_ = null;
    this.isPendingTimestampOffset_ = false;
    this.callQueue_ = [];
    this.loadQueue_ = [];
    this.metadataQueue_.id3 = [];
    this.metadataQueue_.caption = [];
    this.abort();

    if (this.transmuxer_) {
      this.transmuxer_.postMessage({
        action: 'clearParsedMp4Captions'
      });
    }
  }

  /**
   * Remove any data in the source buffer between start and end times
   *
   * @param {number} start - the start time of the region to remove from the buffer
   * @param {number} end - the end time of the region to remove from the buffer
   * @param {Function} [done] - an optional callback to be executed when the remove
   * @param {boolean} force - force all remove operations to happen
   * operation is complete
   */
  remove(start, end, done = () => {}, force = false) {
    // clamp end to duration if we need to remove everything.
    // This is due to a browser bug that causes issues if we remove to Infinity.
    // videojs/videojs-contrib-hls#1225
    if (end === Infinity) {
      end = this.duration_();
    }

    // skip removes that would throw an error
    // commonly happens during a rendition switch at the start of a video
    // from start 0 to end 0
    if (end <= start) {
      this.logger_('skipping remove because end ${end} is <= start ${start}');
      return;
    }

    if (!this.sourceUpdater_ || !this.getMediaInfo_()) {
      this.logger_('skipping remove because no source updater or starting media info');
      // nothing to remove if we haven't processed any media
      return;
    }

    // set it to one to complete this function's removes
    let removesRemaining = 1;
    const removeFinished = () => {
      removesRemaining--;
      if (removesRemaining === 0) {
        done();
      }
    };

    if (force || !this.audioDisabled_) {
      removesRemaining++;
      this.sourceUpdater_.removeAudio(start, end, removeFinished);
    }

    // While it would be better to only remove video if the main loader has video, this
    // should be safe with audio only as removeVideo will call back even if there's no
    // video buffer.
    //
    // In theory we can check to see if there's video before calling the remove, but in
    // the event that we're switching between renditions and from video to audio only
    // (when we add support for that), we may need to clear the video contents despite
    // what the new media will contain.
    if (force || this.loaderType_ === 'main') {
      this.gopBuffer_ = removeGopBuffer(this.gopBuffer_, start, end, this.timeMapping_);
      removesRemaining++;
      this.sourceUpdater_.removeVideo(start, end, removeFinished);
    }

    // remove any captions and ID3 tags
    for (const track in this.inbandTextTracks_) {
      removeCuesFromTrack(start, end, this.inbandTextTracks_[track]);
    }

    removeCuesFromTrack(start, end, this.segmentMetadataTrack_);

    // finished this function's removes
    removeFinished();
  }

  /**
   * (re-)schedule monitorBufferTick_ to run as soon as possible
   *
   * @private
   */
  monitorBuffer_() {
    if (this.checkBufferTimeout_) {
      window.clearTimeout(this.checkBufferTimeout_);
    }

    this.checkBufferTimeout_ = window.setTimeout(this.monitorBufferTick_.bind(this), 1);
  }

  /**
   * As long as the SegmentLoader is in the READY state, periodically
   * invoke fillBuffer_().
   *
   * @private
   */
  monitorBufferTick_() {
    if (this.state === 'READY') {
      this.fillBuffer_();
    }

    if (this.checkBufferTimeout_) {
      window.clearTimeout(this.checkBufferTimeout_);
    }

    this.checkBufferTimeout_ = window.setTimeout(
      this.monitorBufferTick_.bind(this),
      CHECK_BUFFER_DELAY
    );
  }

  /**
   * fill the buffer with segements unless the sourceBuffers are
   * currently updating
   *
   * Note: this function should only ever be called by monitorBuffer_
   * and never directly
   *
   * @private
   */
  fillBuffer_() {
    // TODO since the source buffer maintains a queue, and we shouldn't call this function
    // except when we're ready for the next segment, this check can most likely be removed
    if (this.sourceUpdater_.updating()) {
      return;
    }

    // see if we need to begin loading immediately
    const segmentInfo = this.chooseNextRequest_();

    if (!segmentInfo) {
      return;
    }

    if (typeof segmentInfo.timestampOffset === 'number') {
      this.isPendingTimestampOffset_ = false;
      this.timelineChangeController_.pendingTimelineChange({
        type: this.loaderType_,
        from: this.currentTimeline_,
        to: segmentInfo.timeline
      });
    }

    this.loadSegment_(segmentInfo);
  }

  /**
   * Determines if we should call endOfStream on the media source based
   * on the state of the buffer or if appened segment was the final
   * segment in the playlist.
   *
   * @param {number} [mediaIndex] the media index of segment we last appended
   * @param {Object} [playlist] a media playlist object
   * @return {boolean} do we need to call endOfStream on the MediaSource
   */
  isEndOfStream_(mediaIndex = this.mediaIndex, playlist = this.playlist_, partIndex = this.partIndex) {
    if (!playlist || !this.mediaSource_) {
      return false;
    }

    const segment = typeof mediaIndex === 'number' && playlist.segments[mediaIndex];

    // mediaIndex is zero based but length is 1 based
    const appendedLastSegment = (mediaIndex + 1) === playlist.segments.length;
    // true if there are no parts, or this is the last part.
    const appendedLastPart = !segment || !segment.parts || (partIndex + 1) === segment.parts.length;

    // if we've buffered to the end of the video, we need to call endOfStream
    // so that MediaSources can trigger the `ended` event when it runs out of
    // buffered data instead of waiting for me
    return playlist.endList &&
      this.mediaSource_.readyState === 'open' &&
      appendedLastSegment &&
      appendedLastPart;
  }

  /**
   * Determines what request should be made given current segment loader state.
   *
   * @return {Object} a request object that describes the segment/part to load
   */
  chooseNextRequest_() {
    const buffered = this.buffered_();
    const bufferedEnd = lastBufferedEnd(buffered) || 0;
    const bufferedTime = timeAheadOf(buffered, this.currentTime_());
    const preloaded = !this.hasPlayed_() && bufferedTime >= 1;
    const haveEnoughBuffer = bufferedTime >= this.goalBufferLength_();
    const segments = this.playlist_.segments;

    // return no segment if:
    // 1. we don't have segments
    // 2. The video has not yet played and we already downloaded a segment
    // 3. we already have enough buffered time
    if (!segments.length || preloaded || haveEnoughBuffer) {
      return null;
    }

    this.syncPoint_ = this.syncPoint_ || this.syncController_.getSyncPoint(
      this.playlist_,
      this.duration_(),
      this.currentTimeline_,
      this.currentTime_()
    );

    const next = {
      partIndex: null,
      mediaIndex: null,
      startOfSegment: null,
      playlist: this.playlist_,
      isSyncRequest: Boolean(!this.syncPoint_)
    };

    if (next.isSyncRequest) {
      next.mediaIndex = getSyncSegmentCandidate(this.currentTimeline_, segments, bufferedEnd);
    } else if (this.mediaIndex !== null) {
      const segment = segments[this.mediaIndex];
      const partIndex = typeof this.partIndex === 'number' ? this.partIndex : -1;

      next.startOfSegment = segment.end ? segment.end : bufferedEnd;

      if (segment.parts && segment.parts[partIndex + 1]) {
        next.mediaIndex = this.mediaIndex;
        next.partIndex = partIndex + 1;
      } else {
        next.mediaIndex = this.mediaIndex + 1;
      }
    } else {
      // Find the segment containing the end of the buffer or current time.
      const {segmentIndex, startTime, partIndex} = Playlist.getMediaInfoForTime({
        experimentalExactManifestTimings: this.experimentalExactManifestTimings,
        playlist: this.playlist_,
        currentTime: this.fetchAtBuffer_ ? bufferedEnd : this.currentTime_(),
        startingPartIndex: this.syncPoint_.partIndex,
        startingSegmentIndex: this.syncPoint_.segmentIndex,
        startTime: this.syncPoint_.time
      });

      next.getMediaInfoForTime = this.fetchAtBuffer_ ?
        `bufferedEnd ${bufferedEnd}` : `currentTime ${this.currentTime_()}`;
      next.mediaIndex = segmentIndex;
      next.startOfSegment = startTime;
      next.partIndex = partIndex;
    }

    const nextSegment = segments[next.mediaIndex];
    let nextPart = nextSegment &&
      typeof next.partIndex === 'number' &&
      nextSegment.parts &&
      nextSegment.parts[next.partIndex];

    // if the next segment index is invalid or
    // the next partIndex is invalid do not choose a next segment.
    if (!nextSegment || (typeof next.partIndex === 'number' && !nextPart)) {
      return null;
    }

    // if the next segment has parts, and we don't have a partIndex.
    // Set partIndex to 0
    if (typeof next.partIndex !== 'number' && nextSegment.parts) {
      next.partIndex = 0;
      nextPart = nextSegment.parts[0];
    }

    // if we have no buffered data then we need to make sure
    // that the next part we append is "independent" if possible.
    // So we check if the previous part is independent, and request
    // it if it is.
    if (!bufferedTime && nextPart && !nextPart.independent) {

      if (next.partIndex === 0) {
        const lastSegment = segments[next.mediaIndex - 1];
        const lastSegmentLastPart = lastSegment.parts && lastSegment.parts.length && lastSegment.parts[lastSegment.parts.length - 1];

        if (lastSegmentLastPart && lastSegmentLastPart.independent) {
          next.mediaIndex -= 1;
          next.partIndex = lastSegment.parts.length - 1;
          next.independent = 'previous segment';
        }
      } else if (nextSegment.parts[next.partIndex - 1].independent) {
        next.partIndex -= 1;
        next.independent = 'previous part';
      }
    }

    const ended = this.mediaSource_ && this.mediaSource_.readyState === 'ended';

    // do not choose a next segment if all of the following:
    // 1. this is the last segment in the playlist
    // 2. end of stream has been called on the media source already
    // 3. the player is not seeking
    if (next.mediaIndex >= (segments.length - 1) && ended && !this.seeking_()) {
      return null;
    }

    return this.generateSegmentInfo_(next);
  }

  generateSegmentInfo_(options) {
    const {
      independent,
      playlist,
      mediaIndex,
      startOfSegment,
      isSyncRequest,
      partIndex,
      forceTimestampOffset,
      getMediaInfoForTime
    } = options;
    const segment = playlist.segments[mediaIndex];
    const part = typeof partIndex === 'number' && segment.parts[partIndex];
    const segmentInfo = {
      requestId: 'segment-loader-' + Math.random(),
      // resolve the segment URL relative to the playlist
      uri: part && part.resolvedUri || segment.resolvedUri,
      // the segment's mediaIndex at the time it was requested
      mediaIndex,
      partIndex: part ? partIndex : null,
      // whether or not to update the SegmentLoader's state with this
      // segment's mediaIndex
      isSyncRequest,
      startOfSegment,
      // the segment's playlist
      playlist,
      // unencrypted bytes of the segment
      bytes: null,
      // when a key is defined for this segment, the encrypted bytes
      encryptedBytes: null,
      // The target timestampOffset for this segment when we append it
      // to the source buffer
      timestampOffset: null,
      // The timeline that the segment is in
      timeline: segment.timeline,
      // The expected duration of the segment in seconds
      duration: part && part.duration || segment.duration,
      // retain the segment in case the playlist updates while doing an async process
      segment,
      part,
      byteLength: 0,
      transmuxer: this.transmuxer_,
      // type of getMediaInfoForTime that was used to get this segment
      getMediaInfoForTime,
      independent
    };

    const overrideCheck =
      typeof forceTimestampOffset !== 'undefined' ? forceTimestampOffset : this.isPendingTimestampOffset_;

    segmentInfo.timestampOffset = this.timestampOffsetForSegment_({
      segmentTimeline: segment.timeline,
      currentTimeline: this.currentTimeline_,
      startOfSegment,
      buffered: this.buffered_(),
      overrideCheck
    });

    const audioBufferedEnd = lastBufferedEnd(this.sourceUpdater_.audioBuffered());

    if (typeof audioBufferedEnd === 'number') {
      // since the transmuxer is using the actual timing values, but the buffer is
      // adjusted by the timestamp offset, we must adjust the value here
      segmentInfo.audioAppendStart = audioBufferedEnd - this.sourceUpdater_.audioTimestampOffset();
    }

    if (this.sourceUpdater_.videoBuffered().length) {
      segmentInfo.gopsToAlignWith = gopsSafeToAlignWith(
        this.gopBuffer_,
        // since the transmuxer is using the actual timing values, but the time is
        // adjusted by the timestmap offset, we must adjust the value here
        this.currentTime_() - this.sourceUpdater_.videoTimestampOffset(),
        this.timeMapping_
      );
    }

    return segmentInfo;
  }

  // get the timestampoffset for a segment,
  // added so that vtt segment loader can override and prevent
  // adding timestamp offsets.
  timestampOffsetForSegment_(options) {
    return timestampOffsetForSegment(options);
  }
  /**
   * Determines if the network has enough bandwidth to complete the current segment
   * request in a timely manner. If not, the request will be aborted early and bandwidth
   * updated to trigger a playlist switch.
   *
   * @param {Object} stats
   *        Object containing stats about the request timing and size
   * @private
   */
  earlyAbortWhenNeeded_(stats) {
    if (this.vhs_.tech_.paused() ||
        // Don't abort if the current playlist is on the lowestEnabledRendition
        // TODO: Replace using timeout with a boolean indicating whether this playlist is
        //       the lowestEnabledRendition.
        !this.xhrOptions_.timeout ||
        // Don't abort if we have no bandwidth information to estimate segment sizes
        !(this.playlist_.attributes.BANDWIDTH)) {
      return;
    }

    // Wait at least 1 second since the first byte of data has been received before
    // using the calculated bandwidth from the progress event to allow the bitrate
    // to stabilize
    if (Date.now() - (stats.firstBytesReceivedAt || Date.now()) < 1000) {
      return;
    }

    const currentTime = this.currentTime_();
    const measuredBandwidth = stats.bandwidth;
    const segmentDuration = this.pendingSegment_.duration;

    const requestTimeRemaining =
      Playlist.estimateSegmentRequestTime(
        segmentDuration,
        measuredBandwidth,
        this.playlist_,
        stats.bytesReceived
      );

    // Subtract 1 from the timeUntilRebuffer so we still consider an early abort
    // if we are only left with less than 1 second when the request completes.
    // A negative timeUntilRebuffering indicates we are already rebuffering
    const timeUntilRebuffer = timeUntilRebuffer_(
      this.buffered_(),
      currentTime,
      this.vhs_.tech_.playbackRate()
    ) - 1;

    // Only consider aborting early if the estimated time to finish the download
    // is larger than the estimated time until the player runs out of forward buffer
    if (requestTimeRemaining <= timeUntilRebuffer) {
      return;
    }

    const switchCandidate = minRebufferMaxBandwidthSelector({
      master: this.vhs_.playlists.master,
      currentTime,
      bandwidth: measuredBandwidth,
      duration: this.duration_(),
      segmentDuration,
      timeUntilRebuffer,
      currentTimeline: this.currentTimeline_,
      syncController: this.syncController_
    });

    if (!switchCandidate) {
      return;
    }

    const rebufferingImpact = requestTimeRemaining - timeUntilRebuffer;

    const timeSavedBySwitching = rebufferingImpact - switchCandidate.rebufferingImpact;

    let minimumTimeSaving = 0.5;

    // If we are already rebuffering, increase the amount of variance we add to the
    // potential round trip time of the new request so that we are not too aggressive
    // with switching to a playlist that might save us a fraction of a second.
    if (timeUntilRebuffer <= TIME_FUDGE_FACTOR) {
      minimumTimeSaving = 1;
    }

    if (!switchCandidate.playlist ||
        switchCandidate.playlist.uri === this.playlist_.uri ||
        timeSavedBySwitching < minimumTimeSaving) {
      return;
    }

    // set the bandwidth to that of the desired playlist being sure to scale by
    // BANDWIDTH_VARIANCE and add one so the playlist selector does not exclude it
    // don't trigger a bandwidthupdate as the bandwidth is artifial
    this.bandwidth =
      switchCandidate.playlist.attributes.BANDWIDTH * Config.BANDWIDTH_VARIANCE + 1;
    this.trigger('earlyabort');
  }

  handleAbort_(segmentInfo) {
    this.logger_(`Aborting ${segmentInfoString(segmentInfo)}`);
    this.mediaRequestsAborted += 1;
  }

  /**
   * XHR `progress` event handler
   *
   * @param {Event}
   *        The XHR `progress` event
   * @param {Object} simpleSegment
   *        A simplified segment object copy
   * @private
   */
  handleProgress_(event, simpleSegment) {
    this.earlyAbortWhenNeeded_(simpleSegment.stats);

    if (this.checkForAbort_(simpleSegment.requestId)) {
      return;
    }

    this.trigger('progress');
  }

  handleTrackInfo_(simpleSegment, trackInfo) {
    this.earlyAbortWhenNeeded_(simpleSegment.stats);

    if (this.checkForAbort_(simpleSegment.requestId)) {
      return;
    }

    if (this.checkForIllegalMediaSwitch(trackInfo)) {
      return;
    }

    trackInfo = trackInfo || {};

    // When we have track info, determine what media types this loader is dealing with.
    // Guard against cases where we're not getting track info at all until we are
    // certain that all streams will provide it.
    if (!shallowEqual(this.currentMediaInfo_, trackInfo)) {
      this.appendInitSegment_ = {
        audio: true,
        video: true
      };

      this.startingMediaInfo_ = trackInfo;
      this.currentMediaInfo_ = trackInfo;
      this.logger_('trackinfo update', trackInfo);
      this.trigger('trackinfo');
    }

    // trackinfo may cause an abort if the trackinfo
    // causes a codec change to an unsupported codec.
    if (this.checkForAbort_(simpleSegment.requestId)) {
      return;
    }

    // set trackinfo on the pending segment so that
    // it can append.
    this.pendingSegment_.trackInfo = trackInfo;

    // check if any calls were waiting on the track info
    if (this.hasEnoughInfoToAppend_()) {
      this.processCallQueue_();
    }
  }

  handleTimingInfo_(simpleSegment, mediaType, timeType, time) {
    this.earlyAbortWhenNeeded_(simpleSegment.stats);
    if (this.checkForAbort_(simpleSegment.requestId)) {
      return;
    }

    const segmentInfo = this.pendingSegment_;
    const timingInfoProperty = timingInfoPropertyForMedia(mediaType);

    segmentInfo[timingInfoProperty] = segmentInfo[timingInfoProperty] || {};
    segmentInfo[timingInfoProperty][timeType] = time;

    this.logger_(`timinginfo: ${mediaType} - ${timeType} - ${time}`);

    // check if any calls were waiting on the timing info
    if (this.hasEnoughInfoToAppend_()) {
      this.processCallQueue_();
    }
  }

  handleCaptions_(simpleSegment, captionData) {
    this.earlyAbortWhenNeeded_(simpleSegment.stats);

    if (this.checkForAbort_(simpleSegment.requestId)) {
      return;
    }

    // This could only happen with fmp4 segments, but
    // should still not happen in general
    if (captionData.length === 0) {
      this.logger_('SegmentLoader received no captions from a caption event');
      return;
    }

    const segmentInfo = this.pendingSegment_;

    // Wait until we have some video data so that caption timing
    // can be adjusted by the timestamp offset
    if (!segmentInfo.hasAppendedData_) {
      this.metadataQueue_.caption.push(this.handleCaptions_.bind(this, simpleSegment, captionData));
      return;
    }

    const timestampOffset = this.sourceUpdater_.videoTimestampOffset() === null ?
      this.sourceUpdater_.audioTimestampOffset() :
      this.sourceUpdater_.videoTimestampOffset();

    const captionTracks = {};

    // get total start/end and captions for each track/stream
    captionData.forEach((caption) => {
      // caption.stream is actually a track name...
      // set to the existing values in tracks or default values
      captionTracks[caption.stream] = captionTracks[caption.stream] || {
        // Infinity, as any other value will be less than this
        startTime: Infinity,
        captions: [],
        // 0 as an other value will be more than this
        endTime: 0
      };

      const captionTrack = captionTracks[caption.stream];

      captionTrack.startTime = Math.min(captionTrack.startTime, (caption.startTime + timestampOffset));
      captionTrack.endTime = Math.max(captionTrack.endTime, (caption.endTime + timestampOffset));
      captionTrack.captions.push(caption);
    });

    Object.keys(captionTracks).forEach((trackName) => {
      const {startTime, endTime, captions} = captionTracks[trackName];
      const inbandTextTracks = this.inbandTextTracks_;

      this.logger_(`adding cues from ${startTime} -> ${endTime} for ${trackName}`);

      createCaptionsTrackIfNotExists(inbandTextTracks, this.vhs_.tech_, trackName);
      // clear out any cues that start and end at the same time period for the same track.
      // We do this because a rendition change that also changes the timescale for captions
      // will result in captions being re-parsed for certain segments. If we add them again
      // without clearing we will have two of the same captions visible.
      removeCuesFromTrack(startTime, endTime, inbandTextTracks[trackName]);

      addCaptionData({captionArray: captions, inbandTextTracks, timestampOffset});
    });

    // Reset stored captions since we added parsed
    // captions to a text track at this point

    if (this.transmuxer_) {
      this.transmuxer_.postMessage({
        action: 'clearParsedMp4Captions'
      });
    }
  }

  handleId3_(simpleSegment, id3Frames, dispatchType) {
    this.earlyAbortWhenNeeded_(simpleSegment.stats);

    if (this.checkForAbort_(simpleSegment.requestId)) {
      return;
    }

    const segmentInfo = this.pendingSegment_;

    // we need to have appended data in order for the timestamp offset to be set
    if (!segmentInfo.hasAppendedData_) {
      this.metadataQueue_.id3.push(this.handleId3_.bind(this, simpleSegment, id3Frames, dispatchType));
      return;
    }

    const timestampOffset = this.sourceUpdater_.videoTimestampOffset() === null ?
      this.sourceUpdater_.audioTimestampOffset() :
      this.sourceUpdater_.videoTimestampOffset();

    // There's potentially an issue where we could double add metadata if there's a muxed
    // audio/video source with a metadata track, and an alt audio with a metadata track.
    // However, this probably won't happen, and if it does it can be handled then.
    createMetadataTrackIfNotExists(this.inbandTextTracks_, dispatchType, this.vhs_.tech_);
    addMetadata({
      inbandTextTracks: this.inbandTextTracks_,
      metadataArray: id3Frames,
      timestampOffset,
      videoDuration: this.duration_()
    });
  }

  processMetadataQueue_() {
    this.metadataQueue_.id3.forEach((fn) => fn());
    this.metadataQueue_.caption.forEach((fn) => fn());

    this.metadataQueue_.id3 = [];
    this.metadataQueue_.caption = [];
  }

  processCallQueue_() {
    const callQueue = this.callQueue_;

    // Clear out the queue before the queued functions are run, since some of the
    // functions may check the length of the load queue and default to pushing themselves
    // back onto the queue.
    this.callQueue_ = [];
    callQueue.forEach((fun) => fun());
  }

  processLoadQueue_() {
    const loadQueue = this.loadQueue_;

    // Clear out the queue before the queued functions are run, since some of the
    // functions may check the length of the load queue and default to pushing themselves
    // back onto the queue.
    this.loadQueue_ = [];
    loadQueue.forEach((fun) => fun());
  }

  /**
   * Determines whether the loader has enough info to load the next segment.
   *
   * @return {boolean}
   *         Whether or not the loader has enough info to load the next segment
   */
  hasEnoughInfoToLoad_() {
    // Since primary timing goes by video, only the audio loader potentially needs to wait
    // to load.
    if (this.loaderType_ !== 'audio') {
      return true;
    }

    const segmentInfo = this.pendingSegment_;

    // A fill buffer must have already run to establish a pending segment before there's
    // enough info to load.
    if (!segmentInfo) {
      return false;
    }

    // The first segment can and should be loaded immediately so that source buffers are
    // created together (before appending). Source buffer creation uses the presence of
    // audio and video data to determine whether to create audio/video source buffers, and
    // uses processed (transmuxed or parsed) media to determine the types required.
    if (!this.getCurrentMediaInfo_()) {
      return true;
    }

    if (
      // Technically, instead of waiting to load a segment on timeline changes, a segment
      // can be requested and downloaded and only wait before it is transmuxed or parsed.
      // But in practice, there are a few reasons why it is better to wait until a loader
      // is ready to append that segment before requesting and downloading:
      //
      // 1. Because audio and main loaders cross discontinuities together, if this loader
      //    is waiting for the other to catch up, then instead of requesting another
      //    segment and using up more bandwidth, by not yet loading, more bandwidth is
      //    allotted to the loader currently behind.
      // 2. media-segment-request doesn't have to have logic to consider whether a segment
      // is ready to be processed or not, isolating the queueing behavior to the loader.
      // 3. The audio loader bases some of its segment properties on timing information
      //    provided by the main loader, meaning that, if the logic for waiting on
      //    processing was in media-segment-request, then it would also need to know how
      //    to re-generate the segment information after the main loader caught up.
      shouldWaitForTimelineChange({
        timelineChangeController: this.timelineChangeController_,
        currentTimeline: this.currentTimeline_,
        segmentTimeline: segmentInfo.timeline,
        loaderType: this.loaderType_,
        audioDisabled: this.audioDisabled_
      })
    ) {
      return false;
    }

    return true;
  }

  getCurrentMediaInfo_(segmentInfo = this.pendingSegment_) {
    return segmentInfo && segmentInfo.trackInfo || this.currentMediaInfo_;
  }

  getMediaInfo_(segmentInfo = this.pendingSegment_) {
    return this.getCurrentMediaInfo_(segmentInfo) || this.startingMediaInfo_;
  }

  hasEnoughInfoToAppend_() {
    if (!this.sourceUpdater_.ready()) {
      return false;
    }

    // If content needs to be removed or the loader is waiting on an append reattempt,
    // then no additional content should be appended until the prior append is resolved.
    if (this.waitingOnRemove_ || this.quotaExceededErrorRetryTimeout_) {
      return false;
    }

    const segmentInfo = this.pendingSegment_;
    const trackInfo = this.getCurrentMediaInfo_();

    // no segment to append any data for or
    // we do not have information on this specific
    // segment yet
    if (!segmentInfo || !trackInfo) {
      return false;
    }

    const {hasAudio, hasVideo, isMuxed} = trackInfo;

    if (hasVideo && !segmentInfo.videoTimingInfo) {
      return false;
    }

    // muxed content only relies on video timing information for now.
    if (hasAudio && !this.audioDisabled_ && !isMuxed && !segmentInfo.audioTimingInfo) {
      return false;
    }

    if (
      shouldWaitForTimelineChange({
        timelineChangeController: this.timelineChangeController_,
        currentTimeline: this.currentTimeline_,
        segmentTimeline: segmentInfo.timeline,
        loaderType: this.loaderType_,
        audioDisabled: this.audioDisabled_
      })
    ) {
      return false;
    }

    return true;
  }

  handleData_(simpleSegment, result) {
    this.earlyAbortWhenNeeded_(simpleSegment.stats);

    if (this.checkForAbort_(simpleSegment.requestId)) {
      return;
    }

    // If there's anything in the call queue, then this data came later and should be
    // executed after the calls currently queued.
    if (this.callQueue_.length || !this.hasEnoughInfoToAppend_()) {
      this.callQueue_.push(this.handleData_.bind(this, simpleSegment, result));
      return;
    }

    const segmentInfo = this.pendingSegment_;

    // update the time mapping so we can translate from display time to media time
    this.setTimeMapping_(segmentInfo.timeline);

    // for tracking overall stats
    this.updateMediaSecondsLoaded_(segmentInfo.part || segmentInfo.segment);

    // Note that the state isn't changed from loading to appending. This is because abort
    // logic may change behavior depending on the state, and changing state too early may
    // inflate our estimates of bandwidth. In the future this should be re-examined to
    // note more granular states.

    // don't process and append data if the mediaSource is closed
    if (this.mediaSource_.readyState === 'closed') {
      return;
    }

    // if this request included an initialization segment, save that data
    // to the initSegment cache
    if (simpleSegment.map) {
      simpleSegment.map = this.initSegmentForMap(simpleSegment.map, true);
      // move over init segment properties to media request
      segmentInfo.segment.map = simpleSegment.map;
    }

    // if this request included a segment key, save that data in the cache
    if (simpleSegment.key) {
      this.segmentKey(simpleSegment.key, true);
    }

    segmentInfo.isFmp4 = simpleSegment.isFmp4;
    segmentInfo.timingInfo = segmentInfo.timingInfo || {};

    if (segmentInfo.isFmp4) {
      this.trigger('fmp4');

      segmentInfo.timingInfo.start =
        segmentInfo[timingInfoPropertyForMedia(result.type)].start;
    } else {
      const trackInfo = this.getCurrentMediaInfo_();
      const useVideoTimingInfo =
        this.loaderType_ === 'main' && trackInfo && trackInfo.hasVideo;
      let firstVideoFrameTimeForData;

      if (useVideoTimingInfo) {
        firstVideoFrameTimeForData = segmentInfo.videoTimingInfo.start;
      }

      // Segment loader knows more about segment timing than the transmuxer (in certain
      // aspects), so make any changes required for a more accurate start time.
      // Don't set the end time yet, as the segment may not be finished processing.
      segmentInfo.timingInfo.start = this.trueSegmentStart_({
        currentStart: segmentInfo.timingInfo.start,
        playlist: segmentInfo.playlist,
        mediaIndex: segmentInfo.mediaIndex,
        currentVideoTimestampOffset: this.sourceUpdater_.videoTimestampOffset(),
        useVideoTimingInfo,
        firstVideoFrameTimeForData,
        videoTimingInfo: segmentInfo.videoTimingInfo,
        audioTimingInfo: segmentInfo.audioTimingInfo
      });
    }

    // Init segments for audio and video only need to be appended in certain cases. Now
    // that data is about to be appended, we can check the final cases to determine
    // whether we should append an init segment.
    this.updateAppendInitSegmentStatus(segmentInfo, result.type);
    // Timestamp offset should be updated once we get new data and have its timing info,
    // as we use the start of the segment to offset the best guess (playlist provided)
    // timestamp offset.
    this.updateSourceBufferTimestampOffset_(segmentInfo);

    // if this is a sync request we need to determine whether it should
    // be appended or not.
    if (segmentInfo.isSyncRequest) {
      // first save/update our timing info for this segment.
      // this is what allows us to choose an accurate segment
      // and the main reason we make a sync request.
      this.updateTimingInfoEnd_(segmentInfo);
      this.syncController_.saveSegmentTimingInfo({
        segmentInfo,
        shouldSaveTimelineMapping: this.loaderType_ === 'main'
      });

      const next = this.chooseNextRequest_();

      // If the sync request isn't the segment that would be requested next
      // after taking into account its timing info, do not append it.
      if (next.mediaIndex !== segmentInfo.mediaIndex || next.partIndex !== segmentInfo.partIndex) {
        this.logger_('sync segment was incorrect, not appending');
        return;
      }
      // otherwise append it like any other segment as our guess was correct.
      this.logger_('sync segment was correct, appending');
    }

    // Save some state so that in the future anything waiting on first append (and/or
    // timestamp offset(s)) can process immediately. While the extra state isn't optimal,
    // we need some notion of whether the timestamp offset or other relevant information
    // has had a chance to be set.
    segmentInfo.hasAppendedData_ = true;
    // Now that the timestamp offset should be set, we can append any waiting ID3 tags.
    this.processMetadataQueue_();

    this.appendData_(segmentInfo, result);
  }

  updateAppendInitSegmentStatus(segmentInfo, type) {
    // alt audio doesn't manage timestamp offset
    if (this.loaderType_ === 'main' &&
        typeof segmentInfo.timestampOffset === 'number' &&
        // in the case that we're handling partial data, we don't want to append an init
        // segment for each chunk
        !segmentInfo.changedTimestampOffset) {
      // if the timestamp offset changed, the timeline may have changed, so we have to re-
      // append init segments
      this.appendInitSegment_ = {
        audio: true,
        video: true
      };
    }

    if (this.playlistOfLastInitSegment_[type] !== segmentInfo.playlist) {
      // make sure we append init segment on playlist changes, in case the media config
      // changed
      this.appendInitSegment_[type] = true;
    }
  }

  getInitSegmentAndUpdateState_({ type, initSegment, map, playlist }) {
    // "The EXT-X-MAP tag specifies how to obtain the Media Initialization Section
    // (Section 3) required to parse the applicable Media Segments.  It applies to every
    // Media Segment that appears after it in the Playlist until the next EXT-X-MAP tag
    // or until the end of the playlist."
    // https://tools.ietf.org/html/draft-pantos-http-live-streaming-23#section-4.3.2.5
    if (map) {
      const id = initSegmentId(map);

      if (this.activeInitSegmentId_ === id) {
        // don't need to re-append the init segment if the ID matches
        return null;
      }

      // a map-specified init segment takes priority over any transmuxed (or otherwise
      // obtained) init segment
      //
      // this also caches the init segment for later use
      initSegment = this.initSegmentForMap(map, true).bytes;
      this.activeInitSegmentId_ = id;
    }

    // We used to always prepend init segments for video, however, that shouldn't be
    // necessary. Instead, we should only append on changes, similar to what we've always
    // done for audio. This is more important (though may not be that important) for
    // frame-by-frame appending for LHLS, simply because of the increased quantity of
    // appends.
    if (initSegment && this.appendInitSegment_[type]) {
      // Make sure we track the playlist that we last used for the init segment, so that
      // we can re-append the init segment in the event that we get data from a new
      // playlist. Discontinuities and track changes are handled in other sections.
      this.playlistOfLastInitSegment_[type] = playlist;
      // Disable future init segment appends for this type. Until a change is necessary.
      this.appendInitSegment_[type] = false;

      // we need to clear out the fmp4 active init segment id, since
      // we are appending the muxer init segment
      this.activeInitSegmentId_ = null;

      return initSegment;
    }

    return null;
  }

  handleQuotaExceededError_({segmentInfo, type, bytes}, error) {
    const audioBuffered = this.sourceUpdater_.audioBuffered();
    const videoBuffered = this.sourceUpdater_.videoBuffered();

    // For now we're ignoring any notion of gaps in the buffer, but they, in theory,
    // should be cleared out during the buffer removals. However, log in case it helps
    // debug.
    if (audioBuffered.length > 1) {
      this.logger_('On QUOTA_EXCEEDED_ERR, found gaps in the audio buffer: ' +
        timeRangesToArray(audioBuffered).join(', '));
    }
    if (videoBuffered.length > 1) {
      this.logger_('On QUOTA_EXCEEDED_ERR, found gaps in the video buffer: ' +
        timeRangesToArray(videoBuffered).join(', '));
    }

    const audioBufferStart = audioBuffered.length ? audioBuffered.start(0) : 0;
    const audioBufferEnd = audioBuffered.length ?
      audioBuffered.end(audioBuffered.length - 1) : 0;
    const videoBufferStart = videoBuffered.length ? videoBuffered.start(0) : 0;
    const videoBufferEnd = videoBuffered.length ?
      videoBuffered.end(videoBuffered.length - 1) : 0;

    if (
      (audioBufferEnd - audioBufferStart) <= MIN_BACK_BUFFER &&
      (videoBufferEnd - videoBufferStart) <= MIN_BACK_BUFFER
    ) {
      // Can't remove enough buffer to make room for new segment (or the browser doesn't
      // allow for appends of segments this size). In the future, it may be possible to
      // split up the segment and append in pieces, but for now, error out this playlist
      // in an attempt to switch to a more manageable rendition.
      this.logger_('On QUOTA_EXCEEDED_ERR, single segment too large to append to ' +
        'buffer, triggering an error. ' +
        `Appended byte length: ${bytes.byteLength}, ` +
        `audio buffer: ${timeRangesToArray(audioBuffered).join(', ')}, ` +
        `video buffer: ${timeRangesToArray(videoBuffered).join(', ')}, `);
      this.error({
        message: 'Quota exceeded error with append of a single segment of content',
        excludeUntil: Infinity
      });
      this.trigger('error');
      return;
    }

    // To try to resolve the quota exceeded error, clear back buffer and retry. This means
    // that the segment-loader should block on future events until this one is handled, so
    // that it doesn't keep moving onto further segments. Adding the call to the call
    // queue will prevent further appends until waitingOnRemove_ and
    // quotaExceededErrorRetryTimeout_ are cleared.
    //
    // Note that this will only block the current loader. In the case of demuxed content,
    // the other load may keep filling as fast as possible. In practice, this should be
    // OK, as it is a rare case when either audio has a high enough bitrate to fill up a
    // source buffer, or video fills without enough room for audio to append (and without
    // the availability of clearing out seconds of back buffer to make room for audio).
    // But it might still be good to handle this case in the future as a TODO.
    this.waitingOnRemove_ = true;
    this.callQueue_.push(this.appendToSourceBuffer_.bind(this, {segmentInfo, type, bytes}));

    const currentTime = this.currentTime_();
    // Try to remove as much audio and video as possible to make room for new content
    // before retrying.
    const timeToRemoveUntil = currentTime - MIN_BACK_BUFFER;

    this.logger_(`On QUOTA_EXCEEDED_ERR, removing audio/video from 0 to ${timeToRemoveUntil}`);
    this.remove(0, timeToRemoveUntil, () => {

      this.logger_(`On QUOTA_EXCEEDED_ERR, retrying append in ${MIN_BACK_BUFFER}s`);
      this.waitingOnRemove_ = false;
      // wait the length of time alotted in the back buffer to prevent wasted
      // attempts (since we can't clear less than the minimum)
      this.quotaExceededErrorRetryTimeout_ = window.setTimeout(() => {
        this.logger_('On QUOTA_EXCEEDED_ERR, re-processing call queue');
        this.quotaExceededErrorRetryTimeout_ = null;
        this.processCallQueue_();
      }, MIN_BACK_BUFFER * 1000);
    }, true);
  }

  handleAppendError_({segmentInfo, type, bytes}, error) {
    // if there's no error, nothing to do
    if (!error) {
      return;
    }

    if (error.code === QUOTA_EXCEEDED_ERR) {
      this.handleQuotaExceededError_({segmentInfo, type, bytes});
      // A quota exceeded error should be recoverable with a future re-append, so no need
      // to trigger an append error.
      return;
    }

    this.logger_('Received non QUOTA_EXCEEDED_ERR on append', error);
    this.error(`${type} append of ${bytes.length}b failed for segment ` +
      `#${segmentInfo.mediaIndex} in playlist ${segmentInfo.playlist.id}`);

    // If an append errors, we often can't recover.
    // (see https://w3c.github.io/media-source/#sourcebuffer-append-error).
    //
    // Trigger a special error so that it can be handled separately from normal,
    // recoverable errors.
    this.trigger('appenderror');
  }

  appendToSourceBuffer_({ segmentInfo, type, initSegment, data, bytes }) {
    // If this is a re-append, bytes were already created and don't need to be recreated
    if (!bytes) {
      const segments = [data];
      let byteLength = data.byteLength;

      if (initSegment) {
        // if the media initialization segment is changing, append it before the content
        // segment
        segments.unshift(initSegment);
        byteLength += initSegment.byteLength;
      }

      // Technically we should be OK appending the init segment separately, however, we
      // haven't yet tested that, and prepending is how we have always done things.
      bytes = concatSegments({
        bytes: byteLength,
        segments
      });
    }

    this.sourceUpdater_.appendBuffer(
      {segmentInfo, type, bytes},
      this.handleAppendError_.bind(this, {segmentInfo, type, bytes})
    );
  }

  handleSegmentTimingInfo_(type, requestId, segmentTimingInfo) {
    if (!this.pendingSegment_ || requestId !== this.pendingSegment_.requestId) {
      return;
    }

    const segment = this.pendingSegment_.segment;
    const timingInfoProperty = `${type}TimingInfo`;

    if (!segment[timingInfoProperty]) {
      segment[timingInfoProperty] = {};
    }

    segment[timingInfoProperty].transmuxerPrependedSeconds =
      segmentTimingInfo.prependedContentDuration || 0;
    segment[timingInfoProperty].transmuxedPresentationStart =
      segmentTimingInfo.start.presentation;
    segment[timingInfoProperty].transmuxedDecodeStart =
      segmentTimingInfo.start.decode;
    segment[timingInfoProperty].transmuxedPresentationEnd =
      segmentTimingInfo.end.presentation;
    segment[timingInfoProperty].transmuxedDecodeEnd =
      segmentTimingInfo.end.decode;
    // mainly used as a reference for debugging
    segment[timingInfoProperty].baseMediaDecodeTime =
      segmentTimingInfo.baseMediaDecodeTime;
  }

  appendData_(segmentInfo, result) {
    const {
      type,
      data
    } = result;

    if (!data || !data.byteLength) {
      return;
    }

    if (type === 'audio' && this.audioDisabled_) {
      return;
    }

    const initSegment = this.getInitSegmentAndUpdateState_({
      type,
      initSegment: result.initSegment,
      playlist: segmentInfo.playlist,
      map: segmentInfo.isFmp4 ? segmentInfo.segment.map : null
    });

    this.appendToSourceBuffer_({ segmentInfo, type, initSegment, data });
  }

  /**
   * load a specific segment from a request into the buffer
   *
   * @private
   */
  loadSegment_(segmentInfo) {
    this.state = 'WAITING';
    this.pendingSegment_ = segmentInfo;
    this.trimBackBuffer_(segmentInfo);

    if (typeof segmentInfo.timestampOffset === 'number') {
      if (this.transmuxer_) {
        this.transmuxer_.postMessage({
          action: 'clearAllMp4Captions'
        });
      }
    }

    if (!this.hasEnoughInfoToLoad_()) {
      this.loadQueue_.push(() => {
        // regenerate the audioAppendStart, timestampOffset, etc as they
        // may have changed since this function was added to the queue.
        const options = Object.assign(
          {},
          segmentInfo,
          {forceTimestampOffset: true}
        );

        Object.assign(segmentInfo, this.generateSegmentInfo_(options));
        this.isPendingTimestampOffset_ = false;
        this.updateTransmuxerAndRequestSegment_(segmentInfo);
      });
      return;
    }

    this.updateTransmuxerAndRequestSegment_(segmentInfo);
  }

  updateTransmuxerAndRequestSegment_(segmentInfo) {
    // We'll update the source buffer's timestamp offset once we have transmuxed data, but
    // the transmuxer still needs to be updated before then.
    //
    // Even though keepOriginalTimestamps is set to true for the transmuxer, timestamp
    // offset must be passed to the transmuxer for stream correcting adjustments.
    if (this.shouldUpdateTransmuxerTimestampOffset_(segmentInfo.timestampOffset)) {
      this.gopBuffer_.length = 0;
      // gopsToAlignWith was set before the GOP buffer was cleared
      segmentInfo.gopsToAlignWith = [];
      this.timeMapping_ = 0;
      // reset values in the transmuxer since a discontinuity should start fresh
      this.transmuxer_.postMessage({
        action: 'reset'
      });
      this.transmuxer_.postMessage({
        action: 'setTimestampOffset',
        timestampOffset: segmentInfo.timestampOffset
      });
    }

    const simpleSegment = this.createSimplifiedSegmentObj_(segmentInfo);
    const isEndOfStream = this.isEndOfStream_(
      segmentInfo.mediaIndex,
      segmentInfo.playlist,
      segmentInfo.partIndex
    );
    const isWalkingForward = this.mediaIndex !== null;
    const isDiscontinuity = segmentInfo.timeline !== this.currentTimeline_ &&
      // currentTimeline starts at -1, so we shouldn't end the timeline switching to 0,
      // the first timeline
      segmentInfo.timeline > 0;
    const isEndOfTimeline = isEndOfStream || (isWalkingForward && isDiscontinuity);

    this.logger_(`Requesting ${segmentInfoString(segmentInfo)}`);

    // If there's an init segment associated with this segment, but it is not cached (identified by a lack of bytes),
    // then this init segment has never been seen before and should be appended.
    //
    // At this point the content type (audio/video or both) is not yet known, but it should be safe to set
    // both to true and leave the decision of whether to append the init segment to append time.
    if (simpleSegment.map && !simpleSegment.map.bytes) {
      this.logger_('going to request init segment.');
      this.appendInitSegment_ = {
        video: true,
        audio: true
      };
    }

    segmentInfo.abortRequests = mediaSegmentRequest({
      xhr: this.vhs_.xhr,
      xhrOptions: this.xhrOptions_,
      decryptionWorker: this.decrypter_,
      segment: simpleSegment,
      abortFn: this.handleAbort_.bind(this, segmentInfo),
      progressFn: this.handleProgress_.bind(this),
      trackInfoFn: this.handleTrackInfo_.bind(this),
      timingInfoFn: this.handleTimingInfo_.bind(this),
      videoSegmentTimingInfoFn: this.handleSegmentTimingInfo_.bind(this, 'video', segmentInfo.requestId),
      audioSegmentTimingInfoFn: this.handleSegmentTimingInfo_.bind(this, 'audio', segmentInfo.requestId),
      captionsFn: this.handleCaptions_.bind(this),
      isEndOfTimeline,
      endedTimelineFn: () => {
        this.logger_('received endedtimeline callback');
      },
      id3Fn: this.handleId3_.bind(this),

      dataFn: this.handleData_.bind(this),
      doneFn: this.segmentRequestFinished_.bind(this),
      onTransmuxerLog: ({message, level, stream}) => {
        this.logger_(`${segmentInfoString(segmentInfo)} logged from transmuxer stream ${stream} as a ${level}: ${message}`);
      }
    });
  }

  /**
   * trim the back buffer so that we don't have too much data
   * in the source buffer
   *
   * @private
   *
   * @param {Object} segmentInfo - the current segment
   */
  trimBackBuffer_(segmentInfo) {
    const removeToTime = safeBackBufferTrimTime(
      this.seekable_(),
      this.currentTime_(),
      this.playlist_.targetDuration || 10
    );

    // Chrome has a hard limit of 150MB of
    // buffer and a very conservative "garbage collector"
    // We manually clear out the old buffer to ensure
    // we don't trigger the QuotaExceeded error
    // on the source buffer during subsequent appends

    if (removeToTime > 0) {
      this.remove(0, removeToTime);
    }
  }

  /**
   * created a simplified copy of the segment object with just the
   * information necessary to perform the XHR and decryption
   *
   * @private
   *
   * @param {Object} segmentInfo - the current segment
   * @return {Object} a simplified segment object copy
   */
  createSimplifiedSegmentObj_(segmentInfo) {
    const segment = segmentInfo.segment;
    const part = segmentInfo.part;

    const simpleSegment = {
      resolvedUri: part ? part.resolvedUri : segment.resolvedUri,
      byterange: part ? part.byterange : segment.byterange,
      requestId: segmentInfo.requestId,
      transmuxer: segmentInfo.transmuxer,
      audioAppendStart: segmentInfo.audioAppendStart,
      gopsToAlignWith: segmentInfo.gopsToAlignWith,
      part: segmentInfo.part
    };

    const previousSegment = segmentInfo.playlist.segments[segmentInfo.mediaIndex - 1];

    if (previousSegment && previousSegment.timeline === segment.timeline) {
      // The baseStartTime of a segment is used to handle rollover when probing the TS
      // segment to retrieve timing information. Since the probe only looks at the media's
      // times (e.g., PTS and DTS values of the segment), and doesn't consider the
      // player's time (e.g., player.currentTime()), baseStartTime should reflect the
      // media time as well. transmuxedDecodeEnd represents the end time of a segment, in
      // seconds of media time, so should be used here. The previous segment is used since
      // the end of the previous segment should represent the beginning of the current
      // segment, so long as they are on the same timeline.
      if (previousSegment.videoTimingInfo) {
        simpleSegment.baseStartTime =
          previousSegment.videoTimingInfo.transmuxedDecodeEnd;
      } else if (previousSegment.audioTimingInfo) {
        simpleSegment.baseStartTime =
          previousSegment.audioTimingInfo.transmuxedDecodeEnd;
      }
    }

    if (segment.key) {
      // if the media sequence is greater than 2^32, the IV will be incorrect
      // assuming 10s segments, that would be about 1300 years
      const iv = segment.key.iv || new Uint32Array([
        0, 0, 0, segmentInfo.mediaIndex + segmentInfo.playlist.mediaSequence
      ]);

      simpleSegment.key = this.segmentKey(segment.key);
      simpleSegment.key.iv = iv;
    }

    if (segment.map) {
      simpleSegment.map = this.initSegmentForMap(segment.map);
    }

    return simpleSegment;
  }

  saveTransferStats_(stats) {
    // every request counts as a media request even if it has been aborted
    // or canceled due to a timeout
    this.mediaRequests += 1;

    if (stats) {
      this.mediaBytesTransferred += stats.bytesReceived;
      this.mediaTransferDuration += stats.roundTripTime;
    }
  }

  saveBandwidthRelatedStats_(duration, stats) {
    // byteLength will be used for throughput, and should be based on bytes receieved,
    // which we only know at the end of the request and should reflect total bytes
    // downloaded rather than just bytes processed from components of the segment
    this.pendingSegment_.byteLength = stats.bytesReceived;

    if (duration < MIN_SEGMENT_DURATION_TO_SAVE_STATS) {
      this.logger_(`Ignoring segment's bandwidth because its duration of ${duration}` +
        ` is less than the min to record ${MIN_SEGMENT_DURATION_TO_SAVE_STATS}`);
      return;
    }

    this.bandwidth = stats.bandwidth;
    this.roundTrip = stats.roundTripTime;
  }

  handleTimeout_() {
    // although the VTT segment loader bandwidth isn't really used, it's good to
    // maintain functinality between segment loaders
    this.mediaRequestsTimedout += 1;
    this.bandwidth = 1;
    this.roundTrip = NaN;
    this.trigger('bandwidthupdate');
  }

  /**
   * Handle the callback from the segmentRequest function and set the
   * associated SegmentLoader state and errors if necessary
   *
   * @private
   */
  segmentRequestFinished_(error, simpleSegment, result) {
    // TODO handle special cases, e.g., muxed audio/video but only audio in the segment

    // check the call queue directly since this function doesn't need to deal with any
    // data, and can continue even if the source buffers are not set up and we didn't get
    // any data from the segment
    if (this.callQueue_.length) {
      this.callQueue_.push(this.segmentRequestFinished_.bind(this, error, simpleSegment, result));
      return;
    }

    this.saveTransferStats_(simpleSegment.stats);

    // The request was aborted and the SegmentLoader has already been reset
    if (!this.pendingSegment_) {
      return;
    }

    // the request was aborted and the SegmentLoader has already started
    // another request. this can happen when the timeout for an aborted
    // request triggers due to a limitation in the XHR library
    // do not count this as any sort of request or we risk double-counting
    if (simpleSegment.requestId !== this.pendingSegment_.requestId) {
      return;
    }

    // an error occurred from the active pendingSegment_ so reset everything
    if (error) {
      this.pendingSegment_ = null;
      this.state = 'READY';

      // aborts are not a true error condition and nothing corrective needs to be done
      if (error.code === REQUEST_ERRORS.ABORTED) {
        return;
      }

      this.pause();

      // the error is really just that at least one of the requests timed-out
      // set the bandwidth to a very low value and trigger an ABR switch to
      // take emergency action
      if (error.code === REQUEST_ERRORS.TIMEOUT) {
        this.handleTimeout_();
        return;
      }

      // if control-flow has arrived here, then the error is real
      // emit an error event to blacklist the current playlist
      this.mediaRequestsErrored += 1;
      this.error(error);
      this.trigger('error');
      return;
    }

    const segmentInfo = this.pendingSegment_;

    // the response was a success so set any bandwidth stats the request
    // generated for ABR purposes
    this.saveBandwidthRelatedStats_(segmentInfo.duration, simpleSegment.stats);

    segmentInfo.endOfAllRequests = simpleSegment.endOfAllRequests;

    if (result.gopInfo) {
      this.gopBuffer_ = updateGopBuffer(this.gopBuffer_, result.gopInfo, this.safeAppend_);
    }

    // Although we may have already started appending on progress, we shouldn't switch the
    // state away from loading until we are officially done loading the segment data.
    this.state = 'APPENDING';

    // used for testing
    this.trigger('appending');

    this.waitForAppendsToComplete_(segmentInfo);
  }

  setTimeMapping_(timeline) {
    const timelineMapping = this.syncController_.mappingForTimeline(timeline);

    if (timelineMapping !== null) {
      this.timeMapping_ = timelineMapping;
    }
  }

  updateMediaSecondsLoaded_(segment) {
    if (typeof segment.start === 'number' && typeof segment.end === 'number') {
      this.mediaSecondsLoaded += segment.end - segment.start;
    } else {
      this.mediaSecondsLoaded += segment.duration;
    }
  }

  shouldUpdateTransmuxerTimestampOffset_(timestampOffset) {
    if (timestampOffset === null) {
      return false;
    }

    // note that we're potentially using the same timestamp offset for both video and
    // audio

    if (this.loaderType_ === 'main' &&
        timestampOffset !== this.sourceUpdater_.videoTimestampOffset()) {
      return true;
    }

    if (!this.audioDisabled_ &&
        timestampOffset !== this.sourceUpdater_.audioTimestampOffset()) {
      return true;
    }

    return false;
  }

  trueSegmentStart_({
    currentStart,
    playlist,
    mediaIndex,
    firstVideoFrameTimeForData,
    currentVideoTimestampOffset,
    useVideoTimingInfo,
    videoTimingInfo,
    audioTimingInfo
  }) {
    if (typeof currentStart !== 'undefined') {
      // if start was set once, keep using it
      return currentStart;
    }

    if (!useVideoTimingInfo) {
      return audioTimingInfo.start;
    }

    const previousSegment = playlist.segments[mediaIndex - 1];

    // The start of a segment should be the start of the first full frame contained
    // within that segment. Since the transmuxer maintains a cache of incomplete data
    // from and/or the last frame seen, the start time may reflect a frame that starts
    // in the previous segment. Check for that case and ensure the start time is
    // accurate for the segment.
    if (mediaIndex === 0 ||
        !previousSegment ||
        typeof previousSegment.start === 'undefined' ||
        previousSegment.end !==
          (firstVideoFrameTimeForData + currentVideoTimestampOffset)) {
      return firstVideoFrameTimeForData;
    }

    return videoTimingInfo.start;
  }

  waitForAppendsToComplete_(segmentInfo) {
    const trackInfo = this.getCurrentMediaInfo_(segmentInfo);

    if (!trackInfo) {
      this.error({
        message: 'No starting media returned, likely due to an unsupported media format.',
        blacklistDuration: Infinity
      });
      this.trigger('error');
      return;
    }
    // Although transmuxing is done, appends may not yet be finished. Throw a marker
    // on each queue this loader is responsible for to ensure that the appends are
    // complete.
    const {hasAudio, hasVideo, isMuxed} = trackInfo;
    const waitForVideo = this.loaderType_ === 'main' && hasVideo;
    const waitForAudio = !this.audioDisabled_ && hasAudio && !isMuxed;

    segmentInfo.waitingOnAppends = 0;

    // segments with no data
    if (!segmentInfo.hasAppendedData_) {
      if (!segmentInfo.timingInfo && typeof segmentInfo.timestampOffset === 'number') {
        // When there's no audio or video data in the segment, there's no audio or video
        // timing information.
        //
        // If there's no audio or video timing information, then the timestamp offset
        // can't be adjusted to the appropriate value for the transmuxer and source
        // buffers.
        //
        // Therefore, the next segment should be used to set the timestamp offset.
        this.isPendingTimestampOffset_ = true;
      }

      // override settings for metadata only segments
      segmentInfo.timingInfo = {start: 0};
      segmentInfo.waitingOnAppends++;

      if (!this.isPendingTimestampOffset_) {
        // update the timestampoffset
        this.updateSourceBufferTimestampOffset_(segmentInfo);

        // make sure the metadata queue is processed even though we have
        // no video/audio data.
        this.processMetadataQueue_();
      }

      // append is "done" instantly with no data.
      this.checkAppendsDone_(segmentInfo);
      return;
    }

    // Since source updater could call back synchronously, do the increments first.
    if (waitForVideo) {
      segmentInfo.waitingOnAppends++;
    }
    if (waitForAudio) {
      segmentInfo.waitingOnAppends++;
    }

    if (waitForVideo) {
      this.sourceUpdater_.videoQueueCallback(this.checkAppendsDone_.bind(this, segmentInfo));
    }
    if (waitForAudio) {
      this.sourceUpdater_.audioQueueCallback(this.checkAppendsDone_.bind(this, segmentInfo));
    }
  }

  checkAppendsDone_(segmentInfo) {
    if (this.checkForAbort_(segmentInfo.requestId)) {
      return;
    }

    segmentInfo.waitingOnAppends--;

    if (segmentInfo.waitingOnAppends === 0) {
      this.handleAppendsDone_();
    }
  }

  checkForIllegalMediaSwitch(trackInfo) {
    const illegalMediaSwitchError =
      illegalMediaSwitch(this.loaderType_, this.getCurrentMediaInfo_(), trackInfo);

    if (illegalMediaSwitchError) {
      this.error({
        message: illegalMediaSwitchError,
        blacklistDuration: Infinity
      });
      this.trigger('error');
      return true;
    }

    return false;
  }

  updateSourceBufferTimestampOffset_(segmentInfo) {
    if (segmentInfo.timestampOffset === null ||
        // we don't yet have the start for whatever media type (video or audio) has
        // priority, timing-wise, so we must wait
        typeof segmentInfo.timingInfo.start !== 'number' ||
        // already updated the timestamp offset for this segment
        segmentInfo.changedTimestampOffset ||
        // the alt audio loader should not be responsible for setting the timestamp offset
        this.loaderType_ !== 'main') {
      return;
    }

    let didChange = false;

    // Primary timing goes by video, and audio is trimmed in the transmuxer, meaning that
    // the timing info here comes from video. In the event that the audio is longer than
    // the video, this will trim the start of the audio.
    // This also trims any offset from 0 at the beginning of the media
    segmentInfo.timestampOffset -= segmentInfo.timingInfo.start;
    // In the event that there are part segment downloads, each will try to update the
    // timestamp offset. Retaining this bit of state prevents us from updating in the
    // future (within the same segment), however, there may be a better way to handle it.
    segmentInfo.changedTimestampOffset = true;

    if (segmentInfo.timestampOffset !== this.sourceUpdater_.videoTimestampOffset()) {
      this.sourceUpdater_.videoTimestampOffset(segmentInfo.timestampOffset);
      didChange = true;
    }

    if (segmentInfo.timestampOffset !== this.sourceUpdater_.audioTimestampOffset()) {
      this.sourceUpdater_.audioTimestampOffset(segmentInfo.timestampOffset);
      didChange = true;
    }

    if (didChange) {
      this.trigger('timestampoffset');
    }
  }

  updateTimingInfoEnd_(segmentInfo) {
    segmentInfo.timingInfo = segmentInfo.timingInfo || {};
    const trackInfo = this.getMediaInfo_();
    const useVideoTimingInfo =
      this.loaderType_ === 'main' && trackInfo && trackInfo.hasVideo;
    const prioritizedTimingInfo = useVideoTimingInfo && segmentInfo.videoTimingInfo ?
      segmentInfo.videoTimingInfo : segmentInfo.audioTimingInfo;

    if (!prioritizedTimingInfo) {
      return;
    }
    segmentInfo.timingInfo.end = typeof prioritizedTimingInfo.end === 'number' ?
      // End time may not exist in a case where we aren't parsing the full segment (one
      // current example is the case of fmp4), so use the rough duration to calculate an
      // end time.
      prioritizedTimingInfo.end : prioritizedTimingInfo.start + segmentInfo.duration;
  }

  /**
   * callback to run when appendBuffer is finished. detects if we are
   * in a good state to do things with the data we got, or if we need
   * to wait for more
   *
   * @private
   */
  handleAppendsDone_() {
    // appendsdone can cause an abort
    if (this.pendingSegment_) {
      this.trigger('appendsdone');
    }

    if (!this.pendingSegment_) {
      this.state = 'READY';
      // TODO should this move into this.checkForAbort to speed up requests post abort in
      // all appending cases?
      if (!this.paused()) {
        this.monitorBuffer_();
      }
      return;
    }

    const segmentInfo = this.pendingSegment_;

    // Now that the end of the segment has been reached, we can set the end time. It's
    // best to wait until all appends are done so we're sure that the primary media is
    // finished (and we have its end time).
    this.updateTimingInfoEnd_(segmentInfo);
    if (this.shouldSaveSegmentTimingInfo_) {
      // Timeline mappings should only be saved for the main loader. This is for multiple
      // reasons:
      //
      // 1) Only one mapping is saved per timeline, meaning that if both the audio loader
      //    and the main loader try to save the timeline mapping, whichever comes later
      //    will overwrite the first. In theory this is OK, as the mappings should be the
      //    same, however, it breaks for (2)
      // 2) In the event of a live stream, the initial live point will make for a somewhat
      //    arbitrary mapping. If audio and video streams are not perfectly in-sync, then
      //    the mapping will be off for one of the streams, dependent on which one was
      //    first saved (see (1)).
      // 3) Primary timing goes by video in VHS, so the mapping should be video.
      //
      // Since the audio loader will wait for the main loader to load the first segment,
      // the main loader will save the first timeline mapping, and ensure that there won't
      // be a case where audio loads two segments without saving a mapping (thus leading
      // to missing segment timing info).
      this.syncController_.saveSegmentTimingInfo({
        segmentInfo,
        shouldSaveTimelineMapping: this.loaderType_ === 'main'
      });
    }

    const segmentDurationMessage =
      getTroublesomeSegmentDurationMessage(segmentInfo, this.sourceType_);

    if (segmentDurationMessage) {
      if (segmentDurationMessage.severity === 'warn') {
        videojs.log.warn(segmentDurationMessage.message);
      } else {
        this.logger_(segmentDurationMessage.message);
      }
    }

    this.recordThroughput_(segmentInfo);
    this.pendingSegment_ = null;
    this.state = 'READY';

    if (segmentInfo.isSyncRequest) {
      this.trigger('syncinfoupdate');
      // if the sync request was not appended
      // then it was not the correct segment.
      // throw it away and use the data it gave us
      // to get the correct one.
      if (!segmentInfo.hasAppendedData_) {
        this.logger_(`Throwing away un-appended sync request ${segmentInfoString(segmentInfo)}`);
        return;
      }
    }

    this.logger_(`Appended ${segmentInfoString(segmentInfo)}`);

    this.addSegmentMetadataCue_(segmentInfo);
    this.fetchAtBuffer_ = true;
    if (this.currentTimeline_ !== segmentInfo.timeline) {
      this.timelineChangeController_.lastTimelineChange({
        type: this.loaderType_,
        from: this.currentTimeline_,
        to: segmentInfo.timeline
      });
      // If audio is not disabled, the main segment loader is responsible for updating
      // the audio timeline as well. If the content is video only, this won't have any
      // impact.
      if (this.loaderType_ === 'main' && !this.audioDisabled_) {
        this.timelineChangeController_.lastTimelineChange({
          type: 'audio',
          from: this.currentTimeline_,
          to: segmentInfo.timeline
        });
      }
    }
    this.currentTimeline_ = segmentInfo.timeline;

    // We must update the syncinfo to recalculate the seekable range before
    // the following conditional otherwise it may consider this a bad "guess"
    // and attempt to resync when the post-update seekable window and live
    // point would mean that this was the perfect segment to fetch
    this.trigger('syncinfoupdate');
    const segment = segmentInfo.segment;
    const part = segmentInfo.part;
    const badSegmentGuess = segment.end &&
      this.currentTime_() - segment.end > segmentInfo.playlist.targetDuration * 3;
    const badPartGuess = part &&
      part.end && this.currentTime_() - part.end > segmentInfo.playlist.partTargetDuration * 3;

    // If we previously appended a segment/part that ends more than 3 part/targetDurations before
    // the currentTime_ that means that our conservative guess was too conservative.
    // In that case, reset the loader state so that we try to use any information gained
    // from the previous request to create a new, more accurate, sync-point.
    if (badSegmentGuess || badPartGuess) {
      this.logger_(`bad ${badSegmentGuess ? 'segment' : 'part'} ${segmentInfoString(segmentInfo)}`);
      this.resetEverything();
      return;
    }

    const isWalkingForward = this.mediaIndex !== null;

    // Don't do a rendition switch unless we have enough time to get a sync segment
    // and conservatively guess
    if (isWalkingForward) {
      this.trigger('bandwidthupdate');
    }
    this.trigger('progress');

    this.mediaIndex = segmentInfo.mediaIndex;
    this.partIndex = segmentInfo.partIndex;

    // any time an update finishes and the last segment is in the
    // buffer, end the stream. this ensures the "ended" event will
    // fire if playback reaches that point.
    if (this.isEndOfStream_(segmentInfo.mediaIndex, segmentInfo.playlist, segmentInfo.partIndex)) {
      this.endOfStream();
    }

    // used for testing
    this.trigger('appended');

    if (segmentInfo.hasAppendedData_) {
      this.mediaAppends++;
    }

    if (!this.paused()) {
      this.monitorBuffer_();
    }
  }

  /**
   * Records the current throughput of the decrypt, transmux, and append
   * portion of the semgment pipeline. `throughput.rate` is a the cumulative
   * moving average of the throughput. `throughput.count` is the number of
   * data points in the average.
   *
   * @private
   * @param {Object} segmentInfo the object returned by loadSegment
   */
  recordThroughput_(segmentInfo) {
    if (segmentInfo.duration < MIN_SEGMENT_DURATION_TO_SAVE_STATS) {
      this.logger_(`Ignoring segment's throughput because its duration of ${segmentInfo.duration}` +
        ` is less than the min to record ${MIN_SEGMENT_DURATION_TO_SAVE_STATS}`);
      return;
    }

    const rate = this.throughput.rate;
    // Add one to the time to ensure that we don't accidentally attempt to divide
    // by zero in the case where the throughput is ridiculously high
    const segmentProcessingTime =
      Date.now() - segmentInfo.endOfAllRequests + 1;
    // Multiply by 8000 to convert from bytes/millisecond to bits/second
    const segmentProcessingThroughput =
      Math.floor((segmentInfo.byteLength / segmentProcessingTime) * 8 * 1000);

    // This is just a cumulative moving average calculation:
    //   newAvg = oldAvg + (sample - oldAvg) / (sampleCount + 1)
    this.throughput.rate +=
      (segmentProcessingThroughput - rate) / (++this.throughput.count);
  }

  /**
   * Adds a cue to the segment-metadata track with some metadata information about the
   * segment
   *
   * @private
   * @param {Object} segmentInfo
   *        the object returned by loadSegment
   * @method addSegmentMetadataCue_
   */
  addSegmentMetadataCue_(segmentInfo) {
    if (!this.segmentMetadataTrack_) {
      return;
    }

    const segment = segmentInfo.segment;
    const start = segment.start;
    const end = segment.end;

    // Do not try adding the cue if the start and end times are invalid.
    if (!finite(start) || !finite(end)) {
      return;
    }

    removeCuesFromTrack(start, end, this.segmentMetadataTrack_);

    const Cue = window.WebKitDataCue || window.VTTCue;
    const value = {
      custom: segment.custom,
      dateTimeObject: segment.dateTimeObject,
      dateTimeString: segment.dateTimeString,
      bandwidth: segmentInfo.playlist.attributes.BANDWIDTH,
      resolution: segmentInfo.playlist.attributes.RESOLUTION,
      codecs: segmentInfo.playlist.attributes.CODECS,
      byteLength: segmentInfo.byteLength,
      uri: segmentInfo.uri,
      timeline: segmentInfo.timeline,
      playlist: segmentInfo.playlist.id,
      start,
      end
    };
    const data = JSON.stringify(value);
    const cue = new Cue(start, end, data);

    // Attach the metadata to the value property of the cue to keep consistency between
    // the differences of WebKitDataCue in safari and VTTCue in other browsers
    cue.value = value;

    this.segmentMetadataTrack_.addCue(cue);
  }
}
