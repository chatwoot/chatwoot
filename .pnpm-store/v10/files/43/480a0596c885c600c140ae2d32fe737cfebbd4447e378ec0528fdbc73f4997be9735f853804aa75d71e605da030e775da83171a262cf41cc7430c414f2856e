/* global self */
/**
 * @file transmuxer-worker.js
 */

/**
 * videojs-contrib-media-sources
 *
 * Copyright (c) 2015 Brightcove
 * All rights reserved.
 *
 * Handles communication between the browser-world and the mux.js
 * transmuxer running inside of a WebWorker by exposing a simple
 * message-based interface to a Transmuxer object.
 */

import {Transmuxer} from 'mux.js/lib/mp4/transmuxer';
import CaptionParser from 'mux.js/lib/mp4/caption-parser';
import mp4probe from 'mux.js/lib/mp4/probe';
import tsInspector from 'mux.js/lib/tools/ts-inspector.js';
import {
  ONE_SECOND_IN_TS,
  secondsToVideoTs,
  videoTsToSeconds
} from 'mux.js/lib/utils/clock';

/**
 * Re-emits transmuxer events by converting them into messages to the
 * world outside the worker.
 *
 * @param {Object} transmuxer the transmuxer to wire events on
 * @private
 */
const wireTransmuxerEvents = function(self, transmuxer) {
  transmuxer.on('data', function(segment) {
    // transfer ownership of the underlying ArrayBuffer
    // instead of doing a copy to save memory
    // ArrayBuffers are transferable but generic TypedArrays are not
    // @link https://developer.mozilla.org/en-US/docs/Web/API/Web_Workers_API/Using_web_workers#Passing_data_by_transferring_ownership_(transferable_objects)
    const initArray = segment.initSegment;

    segment.initSegment = {
      data: initArray.buffer,
      byteOffset: initArray.byteOffset,
      byteLength: initArray.byteLength
    };

    const typedArray = segment.data;

    segment.data = typedArray.buffer;
    self.postMessage({
      action: 'data',
      segment,
      byteOffset: typedArray.byteOffset,
      byteLength: typedArray.byteLength
    }, [segment.data]);
  });

  transmuxer.on('done', function(data) {
    self.postMessage({ action: 'done' });
  });

  transmuxer.on('gopInfo', function(gopInfo) {
    self.postMessage({
      action: 'gopInfo',
      gopInfo
    });
  });

  transmuxer.on('videoSegmentTimingInfo', function(timingInfo) {
    const videoSegmentTimingInfo = {
      start: {
        decode: videoTsToSeconds(timingInfo.start.dts),
        presentation: videoTsToSeconds(timingInfo.start.pts)
      },
      end: {
        decode: videoTsToSeconds(timingInfo.end.dts),
        presentation: videoTsToSeconds(timingInfo.end.pts)
      },
      baseMediaDecodeTime: videoTsToSeconds(timingInfo.baseMediaDecodeTime)
    };

    if (timingInfo.prependedContentDuration) {
      videoSegmentTimingInfo.prependedContentDuration = videoTsToSeconds(timingInfo.prependedContentDuration);
    }
    self.postMessage({
      action: 'videoSegmentTimingInfo',
      videoSegmentTimingInfo
    });
  });

  transmuxer.on('audioSegmentTimingInfo', function(timingInfo) {
    // Note that all times for [audio/video]SegmentTimingInfo events are in video clock
    const audioSegmentTimingInfo = {
      start: {
        decode: videoTsToSeconds(timingInfo.start.dts),
        presentation: videoTsToSeconds(timingInfo.start.pts)
      },
      end: {
        decode: videoTsToSeconds(timingInfo.end.dts),
        presentation: videoTsToSeconds(timingInfo.end.pts)
      },
      baseMediaDecodeTime: videoTsToSeconds(timingInfo.baseMediaDecodeTime)
    };

    if (timingInfo.prependedContentDuration) {
      audioSegmentTimingInfo.prependedContentDuration =
        videoTsToSeconds(timingInfo.prependedContentDuration);
    }
    self.postMessage({
      action: 'audioSegmentTimingInfo',
      audioSegmentTimingInfo
    });
  });

  transmuxer.on('id3Frame', function(id3Frame) {
    self.postMessage({
      action: 'id3Frame',
      id3Frame
    });
  });

  transmuxer.on('caption', function(caption) {
    self.postMessage({
      action: 'caption',
      caption
    });
  });

  transmuxer.on('trackinfo', function(trackInfo) {
    self.postMessage({
      action: 'trackinfo',
      trackInfo
    });
  });

  transmuxer.on('audioTimingInfo', function(audioTimingInfo) {
    // convert to video TS since we prioritize video time over audio
    self.postMessage({
      action: 'audioTimingInfo',
      audioTimingInfo: {
        start: videoTsToSeconds(audioTimingInfo.start),
        end: videoTsToSeconds(audioTimingInfo.end)
      }
    });
  });

  transmuxer.on('videoTimingInfo', function(videoTimingInfo) {
    self.postMessage({
      action: 'videoTimingInfo',
      videoTimingInfo: {
        start: videoTsToSeconds(videoTimingInfo.start),
        end: videoTsToSeconds(videoTimingInfo.end)
      }
    });
  });

  transmuxer.on('log', function(log) {
    self.postMessage({action: 'log', log});
  });

};

/**
 * All incoming messages route through this hash. If no function exists
 * to handle an incoming message, then we ignore the message.
 *
 * @class MessageHandlers
 * @param {Object} options the options to initialize with
 */
class MessageHandlers {
  constructor(self, options) {
    this.options = options || {};
    this.self = self;
    this.init();
  }

  /**
   * initialize our web worker and wire all the events.
   */
  init() {
    if (this.transmuxer) {
      this.transmuxer.dispose();
    }
    this.transmuxer = new Transmuxer(this.options);

    wireTransmuxerEvents(this.self, this.transmuxer);
  }

  pushMp4Captions(data) {
    if (!this.captionParser) {
      this.captionParser = new CaptionParser();
      this.captionParser.init();
    }
    const segment = new Uint8Array(data.data, data.byteOffset, data.byteLength);
    const parsed = this.captionParser.parse(
      segment,
      data.trackIds,
      data.timescales
    );

    this.self.postMessage({
      action: 'mp4Captions',
      captions: parsed && parsed.captions || [],
      logs: parsed && parsed.logs || [],
      data: segment.buffer
    }, [segment.buffer]);
  }

  probeMp4StartTime({timescales, data}) {
    const startTime = mp4probe.startTime(timescales, data);

    this.self.postMessage({
      action: 'probeMp4StartTime',
      startTime,
      data
    }, [data.buffer]);
  }

  probeMp4Tracks({data}) {
    const tracks = mp4probe.tracks(data);

    this.self.postMessage({
      action: 'probeMp4Tracks',
      tracks,
      data
    }, [data.buffer]);
  }

  /**
   * Probe an mpeg2-ts segment to determine the start time of the segment in it's
   * internal "media time," as well as whether it contains video and/or audio.
   *
   * @private
   * @param {Uint8Array} bytes - segment bytes
   * @param {number} baseStartTime
   *        Relative reference timestamp used when adjusting frame timestamps for rollover.
   *        This value should be in seconds, as it's converted to a 90khz clock within the
   *        function body.
   * @return {Object} The start time of the current segment in "media time" as well as
   *                  whether it contains video and/or audio
   */
  probeTs({data, baseStartTime}) {
    const tsStartTime = (typeof baseStartTime === 'number' && !isNaN(baseStartTime)) ?
      (baseStartTime * ONE_SECOND_IN_TS) :
      void 0;
    const timeInfo = tsInspector.inspect(data, tsStartTime);
    let result = null;

    if (timeInfo) {
      result = {
        // each type's time info comes back as an array of 2 times, start and end
        hasVideo: timeInfo.video && timeInfo.video.length === 2 || false,
        hasAudio: timeInfo.audio && timeInfo.audio.length === 2 || false
      };

      if (result.hasVideo) {
        result.videoStart = timeInfo.video[0].ptsTime;
      }
      if (result.hasAudio) {
        result.audioStart = timeInfo.audio[0].ptsTime;
      }
    }

    this.self.postMessage({
      action: 'probeTs',
      result,
      data
    }, [data.buffer]);
  }

  clearAllMp4Captions() {
    if (this.captionParser) {
      this.captionParser.clearAllCaptions();
    }
  }

  clearParsedMp4Captions() {
    if (this.captionParser) {
      this.captionParser.clearParsedCaptions();
    }
  }

  /**
   * Adds data (a ts segment) to the start of the transmuxer pipeline for
   * processing.
   *
   * @param {ArrayBuffer} data data to push into the muxer
   */
  push(data) {
    // Cast array buffer to correct type for transmuxer
    const segment = new Uint8Array(data.data, data.byteOffset, data.byteLength);

    this.transmuxer.push(segment);
  }

  /**
   * Recreate the transmuxer so that the next segment added via `push`
   * start with a fresh transmuxer.
   */
  reset() {
    this.transmuxer.reset();
  }

  /**
   * Set the value that will be used as the `baseMediaDecodeTime` time for the
   * next segment pushed in. Subsequent segments will have their `baseMediaDecodeTime`
   * set relative to the first based on the PTS values.
   *
   * @param {Object} data used to set the timestamp offset in the muxer
   */
  setTimestampOffset(data) {
    const timestampOffset = data.timestampOffset || 0;

    this.transmuxer.setBaseMediaDecodeTime(Math.round(secondsToVideoTs(timestampOffset)));
  }

  setAudioAppendStart(data) {
    this.transmuxer.setAudioAppendStart(Math.ceil(secondsToVideoTs(data.appendStart)));
  }

  setRemux(data) {
    this.transmuxer.setRemux(data.remux);
  }

  /**
   * Forces the pipeline to finish processing the last segment and emit it's
   * results.
   *
   * @param {Object} data event data, not really used
   */
  flush(data) {
    this.transmuxer.flush();
    // transmuxed done action is fired after both audio/video pipelines are flushed
    self.postMessage({
      action: 'done',
      type: 'transmuxed'
    });
  }

  endTimeline() {
    this.transmuxer.endTimeline();
    // transmuxed endedtimeline action is fired after both audio/video pipelines end their
    // timelines
    self.postMessage({
      action: 'endedtimeline',
      type: 'transmuxed'
    });
  }

  alignGopsWith(data) {
    this.transmuxer.alignGopsWith(data.gopsToAlignWith.slice());
  }
}

/**
 * Our web worker interface so that things can talk to mux.js
 * that will be running in a web worker. the scope is passed to this by
 * webworkify.
 *
 * @param {Object} self the scope for the web worker
 */
self.onmessage = function(event) {
  if (event.data.action === 'init' && event.data.options) {
    this.messageHandlers = new MessageHandlers(self, event.data.options);
    return;
  }

  if (!this.messageHandlers) {
    this.messageHandlers = new MessageHandlers(self);
  }

  if (event.data && event.data.action && event.data.action !== 'init') {
    if (this.messageHandlers[event.data.action]) {
      this.messageHandlers[event.data.action](event.data);
    }
  }
};
