/**
 * @file source-updater.js
 */
import videojs from 'video.js';
import logger from './util/logger';
import noop from './util/noop';
import { bufferIntersection } from './ranges.js';
import {getMimeForCodec} from '@videojs/vhs-utils/es/codecs.js';
import window from 'global/window';
import toTitleCase from './util/to-title-case.js';
import { QUOTA_EXCEEDED_ERR } from './error-codes';

const bufferTypes = [
  'video',
  'audio'
];

const updating = (type, sourceUpdater) => {
  const sourceBuffer = sourceUpdater[`${type}Buffer`];

  return (sourceBuffer && sourceBuffer.updating) || sourceUpdater.queuePending[type];
};

const nextQueueIndexOfType = (type, queue) => {
  for (let i = 0; i < queue.length; i++) {
    const queueEntry = queue[i];

    if (queueEntry.type === 'mediaSource') {
      // If the next entry is a media source entry (uses multiple source buffers), block
      // processing to allow it to go through first.
      return null;
    }

    if (queueEntry.type === type) {
      return i;
    }
  }

  return null;
};

const shiftQueue = (type, sourceUpdater) => {
  if (sourceUpdater.queue.length === 0) {
    return;
  }

  let queueIndex = 0;
  let queueEntry = sourceUpdater.queue[queueIndex];

  if (queueEntry.type === 'mediaSource') {
    if (!sourceUpdater.updating() && sourceUpdater.mediaSource.readyState !== 'closed') {
      sourceUpdater.queue.shift();
      queueEntry.action(sourceUpdater);

      if (queueEntry.doneFn) {
        queueEntry.doneFn();
      }

      // Only specific source buffer actions must wait for async updateend events. Media
      // Source actions process synchronously. Therefore, both audio and video source
      // buffers are now clear to process the next queue entries.
      shiftQueue('audio', sourceUpdater);
      shiftQueue('video', sourceUpdater);
    }

    // Media Source actions require both source buffers, so if the media source action
    // couldn't process yet (because one or both source buffers are busy), block other
    // queue actions until both are available and the media source action can process.
    return;
  }

  if (type === 'mediaSource') {
    // If the queue was shifted by a media source action (this happens when pushing a
    // media source action onto the queue), then it wasn't from an updateend event from an
    // audio or video source buffer, so there's no change from previous state, and no
    // processing should be done.
    return;
  }

  // Media source queue entries don't need to consider whether the source updater is
  // started (i.e., source buffers are created) as they don't need the source buffers, but
  // source buffer queue entries do.
  if (
    !sourceUpdater.ready() ||
    sourceUpdater.mediaSource.readyState === 'closed' ||
    updating(type, sourceUpdater)
  ) {
    return;
  }

  if (queueEntry.type !== type) {
    queueIndex = nextQueueIndexOfType(type, sourceUpdater.queue);

    if (queueIndex === null) {
      // Either there's no queue entry that uses this source buffer type in the queue, or
      // there's a media source queue entry before the next entry of this type, in which
      // case wait for that action to process first.
      return;
    }

    queueEntry = sourceUpdater.queue[queueIndex];
  }

  sourceUpdater.queue.splice(queueIndex, 1);
  // Keep a record that this source buffer type is in use.
  //
  // The queue pending operation must be set before the action is performed in the event
  // that the action results in a synchronous event that is acted upon. For instance, if
  // an exception is thrown that can be handled, it's possible that new actions will be
  // appended to an empty queue and immediately executed, but would not have the correct
  // pending information if this property was set after the action was performed.
  sourceUpdater.queuePending[type] = queueEntry;
  queueEntry.action(type, sourceUpdater);

  if (!queueEntry.doneFn) {
    // synchronous operation, process next entry
    sourceUpdater.queuePending[type] = null;
    shiftQueue(type, sourceUpdater);
    return;
  }
};

const cleanupBuffer = (type, sourceUpdater) => {
  const buffer = sourceUpdater[`${type}Buffer`];
  const titleType = toTitleCase(type);

  if (!buffer) {
    return;
  }

  buffer.removeEventListener('updateend', sourceUpdater[`on${titleType}UpdateEnd_`]);
  buffer.removeEventListener('error', sourceUpdater[`on${titleType}Error_`]);

  sourceUpdater.codecs[type] = null;
  sourceUpdater[`${type}Buffer`] = null;
};

const inSourceBuffers = (mediaSource, sourceBuffer) => mediaSource && sourceBuffer &&
  Array.prototype.indexOf.call(mediaSource.sourceBuffers, sourceBuffer) !== -1;

const actions = {
  appendBuffer: (bytes, segmentInfo, onError) => (type, sourceUpdater) => {
    const sourceBuffer = sourceUpdater[`${type}Buffer`];

    // can't do anything if the media source / source buffer is null
    // or the media source does not contain this source buffer.
    if (!inSourceBuffers(sourceUpdater.mediaSource, sourceBuffer)) {
      return;
    }

    sourceUpdater.logger_(`Appending segment ${segmentInfo.mediaIndex}'s ${bytes.length} bytes to ${type}Buffer`);

    try {
      sourceBuffer.appendBuffer(bytes);
    } catch (e) {
      sourceUpdater.logger_(`Error with code ${e.code} ` +
        (e.code === QUOTA_EXCEEDED_ERR ? '(QUOTA_EXCEEDED_ERR) ' : '') +
        `when appending segment ${segmentInfo.mediaIndex} to ${type}Buffer`);
      sourceUpdater.queuePending[type] = null;
      onError(e);
    }
  },
  remove: (start, end) => (type, sourceUpdater) => {
    const sourceBuffer = sourceUpdater[`${type}Buffer`];

    // can't do anything if the media source / source buffer is null
    // or the media source does not contain this source buffer.
    if (!inSourceBuffers(sourceUpdater.mediaSource, sourceBuffer)) {
      return;
    }

    sourceUpdater.logger_(`Removing ${start} to ${end} from ${type}Buffer`);
    try {
      sourceBuffer.remove(start, end);
    } catch (e) {
      sourceUpdater.logger_(`Remove ${start} to ${end} from ${type}Buffer failed`);
    }
  },
  timestampOffset: (offset) => (type, sourceUpdater) => {
    const sourceBuffer = sourceUpdater[`${type}Buffer`];

    // can't do anything if the media source / source buffer is null
    // or the media source does not contain this source buffer.
    if (!inSourceBuffers(sourceUpdater.mediaSource, sourceBuffer)) {
      return;
    }

    sourceUpdater.logger_(`Setting ${type}timestampOffset to ${offset}`);

    sourceBuffer.timestampOffset = offset;
  },
  callback: (callback) => (type, sourceUpdater) => {
    callback();
  },
  endOfStream: (error) => (sourceUpdater) => {
    if (sourceUpdater.mediaSource.readyState !== 'open') {
      return;
    }
    sourceUpdater.logger_(`Calling mediaSource endOfStream(${error || ''})`);

    try {
      sourceUpdater.mediaSource.endOfStream(error);
    } catch (e) {
      videojs.log.warn('Failed to call media source endOfStream', e);
    }
  },
  duration: (duration) => (sourceUpdater) => {
    sourceUpdater.logger_(`Setting mediaSource duration to ${duration}`);
    try {
      sourceUpdater.mediaSource.duration = duration;
    } catch (e) {
      videojs.log.warn('Failed to set media source duration', e);
    }
  },
  abort: () => (type, sourceUpdater) => {
    if (sourceUpdater.mediaSource.readyState !== 'open') {
      return;
    }
    const sourceBuffer = sourceUpdater[`${type}Buffer`];

    // can't do anything if the media source / source buffer is null
    // or the media source does not contain this source buffer.
    if (!inSourceBuffers(sourceUpdater.mediaSource, sourceBuffer)) {
      return;
    }

    sourceUpdater.logger_(`calling abort on ${type}Buffer`);
    try {
      sourceBuffer.abort();
    } catch (e) {
      videojs.log.warn(`Failed to abort on ${type}Buffer`, e);
    }
  },
  addSourceBuffer: (type, codec) => (sourceUpdater) => {
    const titleType = toTitleCase(type);
    const mime = getMimeForCodec(codec);

    sourceUpdater.logger_(`Adding ${type}Buffer with codec ${codec} to mediaSource`);

    const sourceBuffer = sourceUpdater.mediaSource.addSourceBuffer(mime);

    sourceBuffer.addEventListener('updateend', sourceUpdater[`on${titleType}UpdateEnd_`]);
    sourceBuffer.addEventListener('error', sourceUpdater[`on${titleType}Error_`]);
    sourceUpdater.codecs[type] = codec;
    sourceUpdater[`${type}Buffer`] = sourceBuffer;
  },
  removeSourceBuffer: (type) => (sourceUpdater) => {
    const sourceBuffer = sourceUpdater[`${type}Buffer`];

    cleanupBuffer(type, sourceUpdater);

    // can't do anything if the media source / source buffer is null
    // or the media source does not contain this source buffer.
    if (!inSourceBuffers(sourceUpdater.mediaSource, sourceBuffer)) {
      return;
    }

    sourceUpdater.logger_(`Removing ${type}Buffer with codec ${sourceUpdater.codecs[type]} from mediaSource`);

    try {
      sourceUpdater.mediaSource.removeSourceBuffer(sourceBuffer);
    } catch (e) {
      videojs.log.warn(`Failed to removeSourceBuffer ${type}Buffer`, e);
    }
  },
  changeType: (codec) => (type, sourceUpdater) => {
    const sourceBuffer = sourceUpdater[`${type}Buffer`];
    const mime = getMimeForCodec(codec);

    // can't do anything if the media source / source buffer is null
    // or the media source does not contain this source buffer.
    if (!inSourceBuffers(sourceUpdater.mediaSource, sourceBuffer)) {
      return;
    }

    // do not update codec if we don't need to.
    if (sourceUpdater.codecs[type] === codec) {
      return;
    }

    sourceUpdater.logger_(`changing ${type}Buffer codec from ${sourceUpdater.codecs[type]} to ${codec}`);

    sourceBuffer.changeType(mime);
    sourceUpdater.codecs[type] = codec;
  }
};

const pushQueue = ({type, sourceUpdater, action, doneFn, name}) => {
  sourceUpdater.queue.push({
    type,
    action,
    doneFn,
    name
  });
  shiftQueue(type, sourceUpdater);
};

const onUpdateend = (type, sourceUpdater) => (e) => {
  // Although there should, in theory, be a pending action for any updateend receieved,
  // there are some actions that may trigger updateend events without set definitions in
  // the w3c spec. For instance, setting the duration on the media source may trigger
  // updateend events on source buffers. This does not appear to be in the spec. As such,
  // if we encounter an updateend without a corresponding pending action from our queue
  // for that source buffer type, process the next action.
  if (sourceUpdater.queuePending[type]) {
    const doneFn = sourceUpdater.queuePending[type].doneFn;

    sourceUpdater.queuePending[type] = null;

    if (doneFn) {
      // if there's an error, report it
      doneFn(sourceUpdater[`${type}Error_`]);
    }
  }

  shiftQueue(type, sourceUpdater);
};

/**
 * A queue of callbacks to be serialized and applied when a
 * MediaSource and its associated SourceBuffers are not in the
 * updating state. It is used by the segment loader to update the
 * underlying SourceBuffers when new data is loaded, for instance.
 *
 * @class SourceUpdater
 * @param {MediaSource} mediaSource the MediaSource to create the SourceBuffer from
 * @param {string} mimeType the desired MIME type of the underlying SourceBuffer
 */
export default class SourceUpdater extends videojs.EventTarget {
  constructor(mediaSource) {
    super();
    this.mediaSource = mediaSource;
    this.sourceopenListener_ = () => shiftQueue('mediaSource', this);
    this.mediaSource.addEventListener('sourceopen', this.sourceopenListener_);
    this.logger_ = logger('SourceUpdater');
    // initial timestamp offset is 0
    this.audioTimestampOffset_ = 0;
    this.videoTimestampOffset_ = 0;
    this.queue = [];
    this.queuePending = {
      audio: null,
      video: null
    };
    this.delayedAudioAppendQueue_ = [];
    this.videoAppendQueued_ = false;
    this.codecs = {};
    this.onVideoUpdateEnd_ = onUpdateend('video', this);
    this.onAudioUpdateEnd_ = onUpdateend('audio', this);
    this.onVideoError_ = (e) => {
      // used for debugging
      this.videoError_ = e;
    };
    this.onAudioError_ = (e) => {
      // used for debugging
      this.audioError_ = e;
    };
    this.createdSourceBuffers_ = false;
    this.initializedEme_ = false;
    this.triggeredReady_ = false;
  }

  initializedEme() {
    this.initializedEme_ = true;
    this.triggerReady();
  }

  hasCreatedSourceBuffers() {
    // if false, likely waiting on one of the segment loaders to get enough data to create
    // source buffers
    return this.createdSourceBuffers_;
  }

  hasInitializedAnyEme() {
    return this.initializedEme_;
  }

  ready() {
    return this.hasCreatedSourceBuffers() && this.hasInitializedAnyEme();
  }

  createSourceBuffers(codecs) {
    if (this.hasCreatedSourceBuffers()) {
      // already created them before
      return;
    }

    // the intial addOrChangeSourceBuffers will always be
    // two add buffers.
    this.addOrChangeSourceBuffers(codecs);
    this.createdSourceBuffers_ = true;
    this.trigger('createdsourcebuffers');
    this.triggerReady();
  }

  triggerReady() {
    // only allow ready to be triggered once, this prevents the case
    // where:
    // 1. we trigger createdsourcebuffers
    // 2. ie 11 synchronously initializates eme
    // 3. the synchronous initialization causes us to trigger ready
    // 4. We go back to the ready check in createSourceBuffers and ready is triggered again.
    if (this.ready() && !this.triggeredReady_) {
      this.triggeredReady_ = true;
      this.trigger('ready');
    }
  }

  /**
   * Add a type of source buffer to the media source.
   *
   * @param {string} type
   *        The type of source buffer to add.
   *
   * @param {string} codec
   *        The codec to add the source buffer with.
   */
  addSourceBuffer(type, codec) {
    pushQueue({
      type: 'mediaSource',
      sourceUpdater: this,
      action: actions.addSourceBuffer(type, codec),
      name: 'addSourceBuffer'
    });
  }

  /**
   * call abort on a source buffer.
   *
   * @param {string} type
   *        The type of source buffer to call abort on.
   */
  abort(type) {
    pushQueue({
      type,
      sourceUpdater: this,
      action: actions.abort(type),
      name: 'abort'
    });
  }

  /**
   * Call removeSourceBuffer and remove a specific type
   * of source buffer on the mediaSource.
   *
   * @param {string} type
   *        The type of source buffer to remove.
   */
  removeSourceBuffer(type) {
    if (!this.canRemoveSourceBuffer()) {
      videojs.log.error('removeSourceBuffer is not supported!');
      return;
    }

    pushQueue({
      type: 'mediaSource',
      sourceUpdater: this,
      action: actions.removeSourceBuffer(type),
      name: 'removeSourceBuffer'
    });
  }

  /**
   * Whether or not the removeSourceBuffer function is supported
   * on the mediaSource.
   *
   * @return {boolean}
   *          if removeSourceBuffer can be called.
   */
  canRemoveSourceBuffer() {
    // IE reports that it supports removeSourceBuffer, but often throws
    // errors when attempting to use the function. So we report that it
    // does not support removeSourceBuffer. As of Firefox 83 removeSourceBuffer
    // throws errors, so we report that it does not support this as well.
    return !videojs.browser.IE_VERSION && !videojs.browser.IS_FIREFOX && window.MediaSource &&
      window.MediaSource.prototype &&
      typeof window.MediaSource.prototype.removeSourceBuffer === 'function';
  }

  /**
   * Whether or not the changeType function is supported
   * on our SourceBuffers.
   *
   * @return {boolean}
   *         if changeType can be called.
   */
  static canChangeType() {
    return window.SourceBuffer &&
        window.SourceBuffer.prototype &&
        typeof window.SourceBuffer.prototype.changeType === 'function';
  }

  /**
   * Whether or not the changeType function is supported
   * on our SourceBuffers.
   *
   * @return {boolean}
   *         if changeType can be called.
   */
  canChangeType() {
    return this.constructor.canChangeType();
  }

  /**
   * Call the changeType function on a source buffer, given the code and type.
   *
   * @param {string} type
   *        The type of source buffer to call changeType on.
   *
   * @param {string} codec
   *        The codec string to change type with on the source buffer.
   */
  changeType(type, codec) {
    if (!this.canChangeType()) {
      videojs.log.error('changeType is not supported!');
      return;
    }

    pushQueue({
      type,
      sourceUpdater: this,
      action: actions.changeType(codec),
      name: 'changeType'
    });
  }

  /**
   * Add source buffers with a codec or, if they are already created,
   * call changeType on source buffers using changeType.
   *
   * @param {Object} codecs
   *        Codecs to switch to
   */
  addOrChangeSourceBuffers(codecs) {
    if (!codecs || typeof codecs !== 'object' || Object.keys(codecs).length === 0) {
      throw new Error('Cannot addOrChangeSourceBuffers to undefined codecs');
    }

    Object.keys(codecs).forEach((type) => {
      const codec = codecs[type];

      if (!this.hasCreatedSourceBuffers()) {
        return this.addSourceBuffer(type, codec);
      }

      if (this.canChangeType()) {
        this.changeType(type, codec);
      }
    });
  }

  /**
   * Queue an update to append an ArrayBuffer.
   *
   * @param {MediaObject} object containing audioBytes and/or videoBytes
   * @param {Function} done the function to call when done
   * @see http://www.w3.org/TR/media-source/#widl-SourceBuffer-appendBuffer-void-ArrayBuffer-data
   */
  appendBuffer(options, doneFn) {
    const {segmentInfo, type, bytes} = options;

    this.processedAppend_ = true;
    if (type === 'audio' && this.videoBuffer && !this.videoAppendQueued_) {
      this.delayedAudioAppendQueue_.push([options, doneFn]);
      this.logger_(`delayed audio append of ${bytes.length} until video append`);
      return;
    }

    // In the case of certain errors, for instance, QUOTA_EXCEEDED_ERR, updateend will
    // not be fired. This means that the queue will be blocked until the next action
    // taken by the segment-loader. Provide a mechanism for segment-loader to handle
    // these errors by calling the doneFn with the specific error.
    const onError = doneFn;

    pushQueue({
      type,
      sourceUpdater: this,
      action: actions.appendBuffer(bytes, segmentInfo || {mediaIndex: -1}, onError),
      doneFn,
      name: 'appendBuffer'
    });

    if (type === 'video') {
      this.videoAppendQueued_ = true;
      if (!this.delayedAudioAppendQueue_.length) {
        return;
      }
      const queue = this.delayedAudioAppendQueue_.slice();

      this.logger_(`queuing delayed audio ${queue.length} appendBuffers`);

      this.delayedAudioAppendQueue_.length = 0;
      queue.forEach((que) => {
        this.appendBuffer.apply(this, que);
      });
    }
  }

  /**
   * Get the audio buffer's buffered timerange.
   *
   * @return {TimeRange}
   *         The audio buffer's buffered time range
   */
  audioBuffered() {
    // no media source/source buffer or it isn't in the media sources
    // source buffer list
    if (!inSourceBuffers(this.mediaSource, this.audioBuffer)) {
      return videojs.createTimeRange();
    }

    return this.audioBuffer.buffered ? this.audioBuffer.buffered :
      videojs.createTimeRange();
  }

  /**
   * Get the video buffer's buffered timerange.
   *
   * @return {TimeRange}
   *         The video buffer's buffered time range
   */
  videoBuffered() {
    // no media source/source buffer or it isn't in the media sources
    // source buffer list
    if (!inSourceBuffers(this.mediaSource, this.videoBuffer)) {
      return videojs.createTimeRange();
    }
    return this.videoBuffer.buffered ? this.videoBuffer.buffered :
      videojs.createTimeRange();
  }

  /**
   * Get a combined video/audio buffer's buffered timerange.
   *
   * @return {TimeRange}
   *         the combined time range
   */
  buffered() {
    const video = inSourceBuffers(this.mediaSource, this.videoBuffer) ? this.videoBuffer : null;
    const audio = inSourceBuffers(this.mediaSource, this.audioBuffer) ? this.audioBuffer : null;

    if (audio && !video) {
      return this.audioBuffered();
    }

    if (video && !audio) {
      return this.videoBuffered();
    }

    return bufferIntersection(this.audioBuffered(), this.videoBuffered());
  }

  /**
   * Add a callback to the queue that will set duration on the mediaSource.
   *
   * @param {number} duration
   *        The duration to set
   *
   * @param {Function} [doneFn]
   *        function to run after duration has been set.
   */
  setDuration(duration, doneFn = noop) {
    // In order to set the duration on the media source, it's necessary to wait for all
    // source buffers to no longer be updating. "If the updating attribute equals true on
    // any SourceBuffer in sourceBuffers, then throw an InvalidStateError exception and
    // abort these steps." (source: https://www.w3.org/TR/media-source/#attributes).
    pushQueue({
      type: 'mediaSource',
      sourceUpdater: this,
      action: actions.duration(duration),
      name: 'duration',
      doneFn
    });
  }

  /**
   * Add a mediaSource endOfStream call to the queue
   *
   * @param {Error} [error]
   *        Call endOfStream with an error
   *
   * @param {Function} [doneFn]
   *        A function that should be called when the
   *        endOfStream call has finished.
   */
  endOfStream(error = null, doneFn = noop) {
    if (typeof error !== 'string') {
      error = undefined;
    }
    // In order to set the duration on the media source, it's necessary to wait for all
    // source buffers to no longer be updating. "If the updating attribute equals true on
    // any SourceBuffer in sourceBuffers, then throw an InvalidStateError exception and
    // abort these steps." (source: https://www.w3.org/TR/media-source/#attributes).
    pushQueue({
      type: 'mediaSource',
      sourceUpdater: this,
      action: actions.endOfStream(error),
      name: 'endOfStream',
      doneFn
    });
  }

  /**
   * Queue an update to remove a time range from the buffer.
   *
   * @param {number} start where to start the removal
   * @param {number} end where to end the removal
   * @param {Function} [done=noop] optional callback to be executed when the remove
   * operation is complete
   * @see http://www.w3.org/TR/media-source/#widl-SourceBuffer-remove-void-double-start-unrestricted-double-end
   */
  removeAudio(start, end, done = noop) {
    if (!this.audioBuffered().length || this.audioBuffered().end(0) === 0) {
      done();
      return;
    }

    pushQueue({
      type: 'audio',
      sourceUpdater: this,
      action: actions.remove(start, end),
      doneFn: done,
      name: 'remove'
    });
  }

  /**
   * Queue an update to remove a time range from the buffer.
   *
   * @param {number} start where to start the removal
   * @param {number} end where to end the removal
   * @param {Function} [done=noop] optional callback to be executed when the remove
   * operation is complete
   * @see http://www.w3.org/TR/media-source/#widl-SourceBuffer-remove-void-double-start-unrestricted-double-end
   */
  removeVideo(start, end, done = noop) {
    if (!this.videoBuffered().length || this.videoBuffered().end(0) === 0) {
      done();
      return;
    }

    pushQueue({
      type: 'video',
      sourceUpdater: this,
      action: actions.remove(start, end),
      doneFn: done,
      name: 'remove'
    });
  }

  /**
   * Whether the underlying sourceBuffer is updating or not
   *
   * @return {boolean} the updating status of the SourceBuffer
   */
  updating() {
    // the audio/video source buffer is updating
    if (updating('audio', this) || updating('video', this)) {
      return true;
    }

    return false;
  }

  /**
   * Set/get the timestampoffset on the audio SourceBuffer
   *
   * @return {number} the timestamp offset
   */
  audioTimestampOffset(offset) {
    if (typeof offset !== 'undefined' &&
        this.audioBuffer &&
        // no point in updating if it's the same
        this.audioTimestampOffset_ !== offset) {
      pushQueue({
        type: 'audio',
        sourceUpdater: this,
        action: actions.timestampOffset(offset),
        name: 'timestampOffset'
      });
      this.audioTimestampOffset_ = offset;
    }
    return this.audioTimestampOffset_;
  }

  /**
   * Set/get the timestampoffset on the video SourceBuffer
   *
   * @return {number} the timestamp offset
   */
  videoTimestampOffset(offset) {
    if (typeof offset !== 'undefined' &&
        this.videoBuffer &&
        // no point in updating if it's the same
        this.videoTimestampOffset !== offset) {
      pushQueue({
        type: 'video',
        sourceUpdater: this,
        action: actions.timestampOffset(offset),
        name: 'timestampOffset'
      });
      this.videoTimestampOffset_ = offset;
    }
    return this.videoTimestampOffset_;
  }

  /**
   * Add a function to the queue that will be called
   * when it is its turn to run in the audio queue.
   *
   * @param {Function} callback
   *        The callback to queue.
   */
  audioQueueCallback(callback) {
    if (!this.audioBuffer) {
      return;
    }
    pushQueue({
      type: 'audio',
      sourceUpdater: this,
      action: actions.callback(callback),
      name: 'callback'
    });
  }

  /**
   * Add a function to the queue that will be called
   * when it is its turn to run in the video queue.
   *
   * @param {Function} callback
   *        The callback to queue.
   */
  videoQueueCallback(callback) {
    if (!this.videoBuffer) {
      return;
    }
    pushQueue({
      type: 'video',
      sourceUpdater: this,
      action: actions.callback(callback),
      name: 'callback'
    });
  }

  /**
   * dispose of the source updater and the underlying sourceBuffer
   */
  dispose() {
    this.trigger('dispose');
    bufferTypes.forEach((type) => {
      this.abort(type);
      if (this.canRemoveSourceBuffer()) {
        this.removeSourceBuffer(type);
      } else {
        this[`${type}QueueCallback`](() => cleanupBuffer(type, this));
      }
    });

    this.videoAppendQueued_ = false;
    this.delayedAudioAppendQueue_.length = 0;

    if (this.sourceopenListener_) {
      this.mediaSource.removeEventListener('sourceopen', this.sourceopenListener_);
    }

    this.off();
  }
}
