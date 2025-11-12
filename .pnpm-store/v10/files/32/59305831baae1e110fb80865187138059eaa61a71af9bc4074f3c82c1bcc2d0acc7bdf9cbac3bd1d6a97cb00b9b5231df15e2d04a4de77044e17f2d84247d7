/**
 * @file vtt-segment-loader.js
 */
import SegmentLoader from './segment-loader';
import videojs from 'video.js';
import window from 'global/window';
import { removeCuesFromTrack, removeDuplicateCuesFromTrack } from './util/text-tracks';
import { initSegmentId } from './bin-utils';
import { uint8ToUtf8 } from './util/string';
import { REQUEST_ERRORS } from './media-segment-request';
import { ONE_SECOND_IN_TS } from 'mux.js/lib/utils/clock';

const VTT_LINE_TERMINATORS =
  new Uint8Array('\n\n'.split('').map(char => char.charCodeAt(0)));

/**
 * An object that manages segment loading and appending.
 *
 * @class VTTSegmentLoader
 * @param {Object} options required and optional options
 * @extends videojs.EventTarget
 */
export default class VTTSegmentLoader extends SegmentLoader {
  constructor(settings, options = {}) {
    super(settings, options);

    // SegmentLoader requires a MediaSource be specified or it will throw an error;
    // however, VTTSegmentLoader has no need of a media source, so delete the reference
    this.mediaSource_ = null;

    this.subtitlesTrack_ = null;

    this.loaderType_ = 'subtitle';

    this.featuresNativeTextTracks_ = settings.featuresNativeTextTracks;

    // The VTT segment will have its own time mappings. Saving VTT segment timing info in
    // the sync controller leads to improper behavior.
    this.shouldSaveSegmentTimingInfo_ = false;
  }

  createTransmuxer_() {
    // don't need to transmux any subtitles
    return null;
  }

  /**
   * Indicates which time ranges are buffered
   *
   * @return {TimeRange}
   *         TimeRange object representing the current buffered ranges
   */
  buffered_() {
    if (!this.subtitlesTrack_ || !this.subtitlesTrack_.cues || !this.subtitlesTrack_.cues.length) {
      return videojs.createTimeRanges();
    }

    const cues = this.subtitlesTrack_.cues;
    const start = cues[0].startTime;
    const end = cues[cues.length - 1].startTime;

    return videojs.createTimeRanges([[start, end]]);
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
      // append WebVTT line terminators to the media initialization segment if it exists
      // to follow the WebVTT spec (https://w3c.github.io/webvtt/#file-structure) that
      // requires two or more WebVTT line terminators between the WebVTT header and the
      // rest of the file
      const combinedByteLength = VTT_LINE_TERMINATORS.byteLength + map.bytes.byteLength;
      const combinedSegment = new Uint8Array(combinedByteLength);

      combinedSegment.set(map.bytes);
      combinedSegment.set(VTT_LINE_TERMINATORS, map.bytes.byteLength);

      this.initSegments_[id] = storedMap = {
        resolvedUri: map.resolvedUri,
        byterange: map.byterange,
        bytes: combinedSegment
      };
    }

    return storedMap || map;
  }

  /**
   * Returns true if all configuration required for loading is present, otherwise false.
   *
   * @return {boolean} True if the all configuration is ready for loading
   * @private
   */
  couldBeginLoading_() {
    return this.playlist_ &&
           this.subtitlesTrack_ &&
           !this.paused();
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
    this.resetEverything();
    return this.monitorBuffer_();
  }

  /**
   * Set a subtitle track on the segment loader to add subtitles to
   *
   * @param {TextTrack=} track
   *        The text track to add loaded subtitles to
   * @return {TextTrack}
   *        Returns the subtitles track
   */
  track(track) {
    if (typeof track === 'undefined') {
      return this.subtitlesTrack_;
    }

    this.subtitlesTrack_ = track;

    // if we were unpaused but waiting for a sourceUpdater, start
    // buffering now
    if (this.state === 'INIT' && this.couldBeginLoading_()) {
      this.init_();
    }

    return this.subtitlesTrack_;
  }

  /**
   * Remove any data in the source buffer between start and end times
   *
   * @param {number} start - the start time of the region to remove from the buffer
   * @param {number} end - the end time of the region to remove from the buffer
   */
  remove(start, end) {
    removeCuesFromTrack(start, end, this.subtitlesTrack_);
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
    // see if we need to begin loading immediately
    const segmentInfo = this.chooseNextRequest_();

    if (!segmentInfo) {
      return;
    }

    if (this.syncController_.timestampOffsetForTimeline(segmentInfo.timeline) === null) {
      // We don't have the timestamp offset that we need to sync subtitles.
      // Rerun on a timestamp offset or user interaction.
      const checkTimestampOffset = () => {
        this.state = 'READY';
        if (!this.paused()) {
          // if not paused, queue a buffer check as soon as possible
          this.monitorBuffer_();
        }
      };

      this.syncController_.one('timestampoffset', checkTimestampOffset);
      this.state = 'WAITING_ON_TIMELINE';
      return;
    }

    this.loadSegment_(segmentInfo);
  }

  // never set a timestamp offset for vtt segments.
  timestampOffsetForSegment_() {
    return null;
  }

  chooseNextRequest_() {
    return this.skipEmptySegments_(super.chooseNextRequest_());
  }

  /**
   * Prevents the segment loader from requesting segments we know contain no subtitles
   * by walking forward until we find the next segment that we don't know whether it is
   * empty or not.
   *
   * @param {Object} segmentInfo
   *        a segment info object that describes the current segment
   * @return {Object}
   *         a segment info object that describes the current segment
   */
  skipEmptySegments_(segmentInfo) {
    while (segmentInfo && segmentInfo.segment.empty) {
      // stop at the last possible segmentInfo
      if (segmentInfo.mediaIndex + 1 >= segmentInfo.playlist.segments.length) {
        segmentInfo = null;
        break;
      }
      segmentInfo = this.generateSegmentInfo_({
        playlist: segmentInfo.playlist,
        mediaIndex: segmentInfo.mediaIndex + 1,
        startOfSegment: segmentInfo.startOfSegment + segmentInfo.duration,
        isSyncRequest: segmentInfo.isSyncRequest
      });
    }
    return segmentInfo;
  }

  stopForError(error) {
    this.error(error);
    this.state = 'READY';
    this.pause();
    this.trigger('error');
  }

  /**
   * append a decrypted segement to the SourceBuffer through a SourceUpdater
   *
   * @private
   */
  segmentRequestFinished_(error, simpleSegment, result) {
    if (!this.subtitlesTrack_) {
      this.state = 'READY';
      return;
    }

    this.saveTransferStats_(simpleSegment.stats);

    // the request was aborted
    if (!this.pendingSegment_) {
      this.state = 'READY';
      this.mediaRequestsAborted += 1;
      return;
    }

    if (error) {
      if (error.code === REQUEST_ERRORS.TIMEOUT) {
        this.handleTimeout_();
      }

      if (error.code === REQUEST_ERRORS.ABORTED) {
        this.mediaRequestsAborted += 1;
      } else {
        this.mediaRequestsErrored += 1;
      }

      this.stopForError(error);
      return;
    }

    const segmentInfo = this.pendingSegment_;

    // although the VTT segment loader bandwidth isn't really used, it's good to
    // maintain functionality between segment loaders
    this.saveBandwidthRelatedStats_(segmentInfo.duration, simpleSegment.stats);

    this.state = 'APPENDING';

    // used for tests
    this.trigger('appending');

    const segment = segmentInfo.segment;

    if (segment.map) {
      segment.map.bytes = simpleSegment.map.bytes;
    }
    segmentInfo.bytes = simpleSegment.bytes;

    // Make sure that vttjs has loaded, otherwise, wait till it finished loading
    if (typeof window.WebVTT !== 'function' &&
        this.subtitlesTrack_ &&
        this.subtitlesTrack_.tech_) {

      let loadHandler;
      const errorHandler = () => {
        this.subtitlesTrack_.tech_.off('vttjsloaded', loadHandler);
        this.stopForError({
          message: 'Error loading vtt.js'
        });
        return;
      };

      loadHandler = () => {
        this.subtitlesTrack_.tech_.off('vttjserror', errorHandler);
        this.segmentRequestFinished_(error, simpleSegment, result);
      };

      this.state = 'WAITING_ON_VTTJS';
      this.subtitlesTrack_.tech_.one('vttjsloaded', loadHandler);
      this.subtitlesTrack_.tech_.one('vttjserror', errorHandler);

      return;
    }

    segment.requested = true;

    try {
      this.parseVTTCues_(segmentInfo);
    } catch (e) {
      this.stopForError({
        message: e.message
      });
      return;
    }

    this.updateTimeMapping_(
      segmentInfo,
      this.syncController_.timelines[segmentInfo.timeline],
      this.playlist_
    );

    if (segmentInfo.cues.length) {
      segmentInfo.timingInfo = {
        start: segmentInfo.cues[0].startTime,
        end: segmentInfo.cues[segmentInfo.cues.length - 1].endTime
      };
    } else {
      segmentInfo.timingInfo = {
        start: segmentInfo.startOfSegment,
        end: segmentInfo.startOfSegment + segmentInfo.duration
      };
    }

    if (segmentInfo.isSyncRequest) {
      this.trigger('syncinfoupdate');
      this.pendingSegment_ = null;
      this.state = 'READY';
      return;
    }

    segmentInfo.byteLength = segmentInfo.bytes.byteLength;

    this.mediaSecondsLoaded += segment.duration;

    // Create VTTCue instances for each cue in the new segment and add them to
    // the subtitle track
    segmentInfo.cues.forEach((cue) => {
      this.subtitlesTrack_.addCue(this.featuresNativeTextTracks_ ?
        new window.VTTCue(cue.startTime, cue.endTime, cue.text) :
        cue);
    });

    // Remove any duplicate cues from the subtitle track. The WebVTT spec allows
    // cues to have identical time-intervals, but if the text is also identical
    // we can safely assume it is a duplicate that can be removed (ex. when a cue
    // "overlaps" VTT segments)
    removeDuplicateCuesFromTrack(this.subtitlesTrack_);

    this.handleAppendsDone_();
  }

  handleData_() {
    // noop as we shouldn't be getting video/audio data captions
    // that we do not support here.
  }
  updateTimingInfoEnd_() {
    // noop
  }

  /**
   * Uses the WebVTT parser to parse the segment response
   *
   * @param {Object} segmentInfo
   *        a segment info object that describes the current segment
   * @private
   */
  parseVTTCues_(segmentInfo) {
    let decoder;
    let decodeBytesToString = false;

    if (typeof window.TextDecoder === 'function') {
      decoder = new window.TextDecoder('utf8');
    } else {
      decoder = window.WebVTT.StringDecoder();
      decodeBytesToString = true;
    }

    const parser = new window.WebVTT.Parser(
      window,
      window.vttjs,
      decoder
    );

    segmentInfo.cues = [];
    segmentInfo.timestampmap = { MPEGTS: 0, LOCAL: 0 };

    parser.oncue = segmentInfo.cues.push.bind(segmentInfo.cues);
    parser.ontimestampmap = (map) => {
      segmentInfo.timestampmap = map;
    };
    parser.onparsingerror = (error) => {
      videojs.log.warn('Error encountered when parsing cues: ' + error.message);
    };

    if (segmentInfo.segment.map) {
      let mapData = segmentInfo.segment.map.bytes;

      if (decodeBytesToString) {
        mapData = uint8ToUtf8(mapData);
      }

      parser.parse(mapData);
    }

    let segmentData = segmentInfo.bytes;

    if (decodeBytesToString) {
      segmentData = uint8ToUtf8(segmentData);
    }

    parser.parse(segmentData);
    parser.flush();
  }

  /**
   * Updates the start and end times of any cues parsed by the WebVTT parser using
   * the information parsed from the X-TIMESTAMP-MAP header and a TS to media time mapping
   * from the SyncController
   *
   * @param {Object} segmentInfo
   *        a segment info object that describes the current segment
   * @param {Object} mappingObj
   *        object containing a mapping from TS to media time
   * @param {Object} playlist
   *        the playlist object containing the segment
   * @private
   */
  updateTimeMapping_(segmentInfo, mappingObj, playlist) {
    const segment = segmentInfo.segment;

    if (!mappingObj) {
      // If the sync controller does not have a mapping of TS to Media Time for the
      // timeline, then we don't have enough information to update the cue
      // start/end times
      return;
    }

    if (!segmentInfo.cues.length) {
      // If there are no cues, we also do not have enough information to figure out
      // segment timing. Mark that the segment contains no cues so we don't re-request
      // an empty segment.
      segment.empty = true;
      return;
    }

    const timestampmap = segmentInfo.timestampmap;
    const diff = (timestampmap.MPEGTS / ONE_SECOND_IN_TS) - timestampmap.LOCAL + mappingObj.mapping;

    segmentInfo.cues.forEach((cue) => {
      // First convert cue time to TS time using the timestamp-map provided within the vtt
      cue.startTime += diff;
      cue.endTime += diff;
    });

    if (!playlist.syncInfo) {
      const firstStart = segmentInfo.cues[0].startTime;
      const lastStart = segmentInfo.cues[segmentInfo.cues.length - 1].startTime;

      playlist.syncInfo = {
        mediaSequence: playlist.mediaSequence + segmentInfo.mediaIndex,
        time: Math.min(firstStart, lastStart - segment.duration)
      };
    }
  }
}
