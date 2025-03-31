"use strict";

var Stream = require('../utils/stream.js');

var m2ts = require('../m2ts/m2ts.js');

var codecs = require('../codecs/index.js');

var AudioSegmentStream = require('./audio-segment-stream.js');

var VideoSegmentStream = require('./video-segment-stream.js');

var trackInfo = require('../mp4/track-decode-info.js');

var isLikelyAacData = require('../aac/utils').isLikelyAacData;

var AdtsStream = require('../codecs/adts');

var AacStream = require('../aac/index');

var clock = require('../utils/clock');

var createPipeline = function createPipeline(object) {
  object.prototype = new Stream();
  object.prototype.init.call(object);
  return object;
};

var tsPipeline = function tsPipeline(options) {
  var pipeline = {
    type: 'ts',
    tracks: {
      audio: null,
      video: null
    },
    packet: new m2ts.TransportPacketStream(),
    parse: new m2ts.TransportParseStream(),
    elementary: new m2ts.ElementaryStream(),
    timestampRollover: new m2ts.TimestampRolloverStream(),
    adts: new codecs.Adts(),
    h264: new codecs.h264.H264Stream(),
    captionStream: new m2ts.CaptionStream(options),
    metadataStream: new m2ts.MetadataStream()
  };
  pipeline.headOfPipeline = pipeline.packet; // Transport Stream

  pipeline.packet.pipe(pipeline.parse).pipe(pipeline.elementary).pipe(pipeline.timestampRollover); // H264

  pipeline.timestampRollover.pipe(pipeline.h264); // Hook up CEA-608/708 caption stream

  pipeline.h264.pipe(pipeline.captionStream);
  pipeline.timestampRollover.pipe(pipeline.metadataStream); // ADTS

  pipeline.timestampRollover.pipe(pipeline.adts);
  pipeline.elementary.on('data', function (data) {
    if (data.type !== 'metadata') {
      return;
    }

    for (var i = 0; i < data.tracks.length; i++) {
      if (!pipeline.tracks[data.tracks[i].type]) {
        pipeline.tracks[data.tracks[i].type] = data.tracks[i];
        pipeline.tracks[data.tracks[i].type].timelineStartInfo.baseMediaDecodeTime = options.baseMediaDecodeTime;
      }
    }

    if (pipeline.tracks.video && !pipeline.videoSegmentStream) {
      pipeline.videoSegmentStream = new VideoSegmentStream(pipeline.tracks.video, options);
      pipeline.videoSegmentStream.on('timelineStartInfo', function (timelineStartInfo) {
        if (pipeline.tracks.audio && !options.keepOriginalTimestamps) {
          pipeline.audioSegmentStream.setEarliestDts(timelineStartInfo.dts - options.baseMediaDecodeTime);
        }
      });
      pipeline.videoSegmentStream.on('timingInfo', pipeline.trigger.bind(pipeline, 'videoTimingInfo'));
      pipeline.videoSegmentStream.on('data', function (data) {
        pipeline.trigger('data', {
          type: 'video',
          data: data
        });
      });
      pipeline.videoSegmentStream.on('done', pipeline.trigger.bind(pipeline, 'done'));
      pipeline.videoSegmentStream.on('partialdone', pipeline.trigger.bind(pipeline, 'partialdone'));
      pipeline.videoSegmentStream.on('endedtimeline', pipeline.trigger.bind(pipeline, 'endedtimeline'));
      pipeline.h264.pipe(pipeline.videoSegmentStream);
    }

    if (pipeline.tracks.audio && !pipeline.audioSegmentStream) {
      pipeline.audioSegmentStream = new AudioSegmentStream(pipeline.tracks.audio, options);
      pipeline.audioSegmentStream.on('data', function (data) {
        pipeline.trigger('data', {
          type: 'audio',
          data: data
        });
      });
      pipeline.audioSegmentStream.on('done', pipeline.trigger.bind(pipeline, 'done'));
      pipeline.audioSegmentStream.on('partialdone', pipeline.trigger.bind(pipeline, 'partialdone'));
      pipeline.audioSegmentStream.on('endedtimeline', pipeline.trigger.bind(pipeline, 'endedtimeline'));
      pipeline.audioSegmentStream.on('timingInfo', pipeline.trigger.bind(pipeline, 'audioTimingInfo'));
      pipeline.adts.pipe(pipeline.audioSegmentStream);
    } // emit pmt info


    pipeline.trigger('trackinfo', {
      hasAudio: !!pipeline.tracks.audio,
      hasVideo: !!pipeline.tracks.video
    });
  });
  pipeline.captionStream.on('data', function (caption) {
    var timelineStartPts;

    if (pipeline.tracks.video) {
      timelineStartPts = pipeline.tracks.video.timelineStartInfo.pts || 0;
    } else {
      // This will only happen if we encounter caption packets before
      // video data in a segment. This is an unusual/unlikely scenario,
      // so we assume the timeline starts at zero for now.
      timelineStartPts = 0;
    } // Translate caption PTS times into second offsets into the
    // video timeline for the segment


    caption.startTime = clock.metadataTsToSeconds(caption.startPts, timelineStartPts, options.keepOriginalTimestamps);
    caption.endTime = clock.metadataTsToSeconds(caption.endPts, timelineStartPts, options.keepOriginalTimestamps);
    pipeline.trigger('caption', caption);
  });
  pipeline = createPipeline(pipeline);
  pipeline.metadataStream.on('data', pipeline.trigger.bind(pipeline, 'id3Frame'));
  return pipeline;
};

var aacPipeline = function aacPipeline(options) {
  var pipeline = {
    type: 'aac',
    tracks: {
      audio: null
    },
    metadataStream: new m2ts.MetadataStream(),
    aacStream: new AacStream(),
    audioRollover: new m2ts.TimestampRolloverStream('audio'),
    timedMetadataRollover: new m2ts.TimestampRolloverStream('timed-metadata'),
    adtsStream: new AdtsStream(true)
  }; // set up the parsing pipeline

  pipeline.headOfPipeline = pipeline.aacStream;
  pipeline.aacStream.pipe(pipeline.audioRollover).pipe(pipeline.adtsStream);
  pipeline.aacStream.pipe(pipeline.timedMetadataRollover).pipe(pipeline.metadataStream);
  pipeline.metadataStream.on('timestamp', function (frame) {
    pipeline.aacStream.setTimestamp(frame.timeStamp);
  });
  pipeline.aacStream.on('data', function (data) {
    if (data.type !== 'timed-metadata' && data.type !== 'audio' || pipeline.audioSegmentStream) {
      return;
    }

    pipeline.tracks.audio = pipeline.tracks.audio || {
      timelineStartInfo: {
        baseMediaDecodeTime: options.baseMediaDecodeTime
      },
      codec: 'adts',
      type: 'audio'
    }; // hook up the audio segment stream to the first track with aac data

    pipeline.audioSegmentStream = new AudioSegmentStream(pipeline.tracks.audio, options);
    pipeline.audioSegmentStream.on('data', function (data) {
      pipeline.trigger('data', {
        type: 'audio',
        data: data
      });
    });
    pipeline.audioSegmentStream.on('partialdone', pipeline.trigger.bind(pipeline, 'partialdone'));
    pipeline.audioSegmentStream.on('done', pipeline.trigger.bind(pipeline, 'done'));
    pipeline.audioSegmentStream.on('endedtimeline', pipeline.trigger.bind(pipeline, 'endedtimeline'));
    pipeline.audioSegmentStream.on('timingInfo', pipeline.trigger.bind(pipeline, 'audioTimingInfo')); // Set up the final part of the audio pipeline

    pipeline.adtsStream.pipe(pipeline.audioSegmentStream);
    pipeline.trigger('trackinfo', {
      hasAudio: !!pipeline.tracks.audio,
      hasVideo: !!pipeline.tracks.video
    });
  }); // set the pipeline up as a stream before binding to get access to the trigger function

  pipeline = createPipeline(pipeline);
  pipeline.metadataStream.on('data', pipeline.trigger.bind(pipeline, 'id3Frame'));
  return pipeline;
};

var setupPipelineListeners = function setupPipelineListeners(pipeline, transmuxer) {
  pipeline.on('data', transmuxer.trigger.bind(transmuxer, 'data'));
  pipeline.on('done', transmuxer.trigger.bind(transmuxer, 'done'));
  pipeline.on('partialdone', transmuxer.trigger.bind(transmuxer, 'partialdone'));
  pipeline.on('endedtimeline', transmuxer.trigger.bind(transmuxer, 'endedtimeline'));
  pipeline.on('audioTimingInfo', transmuxer.trigger.bind(transmuxer, 'audioTimingInfo'));
  pipeline.on('videoTimingInfo', transmuxer.trigger.bind(transmuxer, 'videoTimingInfo'));
  pipeline.on('trackinfo', transmuxer.trigger.bind(transmuxer, 'trackinfo'));
  pipeline.on('id3Frame', function (event) {
    // add this to every single emitted segment even though it's only needed for the first
    event.dispatchType = pipeline.metadataStream.dispatchType; // keep original time, can be adjusted if needed at a higher level

    event.cueTime = clock.videoTsToSeconds(event.pts);
    transmuxer.trigger('id3Frame', event);
  });
  pipeline.on('caption', function (event) {
    transmuxer.trigger('caption', event);
  });
};

var Transmuxer = function Transmuxer(options) {
  var pipeline = null,
      hasFlushed = true;
  options = options || {};
  Transmuxer.prototype.init.call(this);
  options.baseMediaDecodeTime = options.baseMediaDecodeTime || 0;

  this.push = function (bytes) {
    if (hasFlushed) {
      var isAac = isLikelyAacData(bytes);

      if (isAac && (!pipeline || pipeline.type !== 'aac')) {
        pipeline = aacPipeline(options);
        setupPipelineListeners(pipeline, this);
      } else if (!isAac && (!pipeline || pipeline.type !== 'ts')) {
        pipeline = tsPipeline(options);
        setupPipelineListeners(pipeline, this);
      }

      hasFlushed = false;
    }

    pipeline.headOfPipeline.push(bytes);
  };

  this.flush = function () {
    if (!pipeline) {
      return;
    }

    hasFlushed = true;
    pipeline.headOfPipeline.flush();
  };

  this.partialFlush = function () {
    if (!pipeline) {
      return;
    }

    pipeline.headOfPipeline.partialFlush();
  };

  this.endTimeline = function () {
    if (!pipeline) {
      return;
    }

    pipeline.headOfPipeline.endTimeline();
  };

  this.reset = function () {
    if (!pipeline) {
      return;
    }

    pipeline.headOfPipeline.reset();
  };

  this.setBaseMediaDecodeTime = function (baseMediaDecodeTime) {
    if (!options.keepOriginalTimestamps) {
      options.baseMediaDecodeTime = baseMediaDecodeTime;
    }

    if (!pipeline) {
      return;
    }

    if (pipeline.tracks.audio) {
      pipeline.tracks.audio.timelineStartInfo.dts = undefined;
      pipeline.tracks.audio.timelineStartInfo.pts = undefined;
      trackInfo.clearDtsInfo(pipeline.tracks.audio);

      if (pipeline.audioRollover) {
        pipeline.audioRollover.discontinuity();
      }
    }

    if (pipeline.tracks.video) {
      if (pipeline.videoSegmentStream) {
        pipeline.videoSegmentStream.gopCache_ = [];
      }

      pipeline.tracks.video.timelineStartInfo.dts = undefined;
      pipeline.tracks.video.timelineStartInfo.pts = undefined;
      trackInfo.clearDtsInfo(pipeline.tracks.video); // pipeline.captionStream.reset();
    }

    if (pipeline.timestampRollover) {
      pipeline.timestampRollover.discontinuity();
    }
  };

  this.setRemux = function (val) {
    options.remux = val;

    if (pipeline && pipeline.coalesceStream) {
      pipeline.coalesceStream.setRemux(val);
    }
  };

  this.setAudioAppendStart = function (audioAppendStart) {
    if (!pipeline || !pipeline.tracks.audio || !pipeline.audioSegmentStream) {
      return;
    }

    pipeline.audioSegmentStream.setAudioAppendStart(audioAppendStart);
  }; // TODO GOP alignment support
  // Support may be a bit trickier than with full segment appends, as GOPs may be split
  // and processed in a more granular fashion


  this.alignGopsWith = function (gopsToAlignWith) {
    return;
  };
};

Transmuxer.prototype = new Stream();
module.exports = Transmuxer;