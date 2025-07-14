/**
 * mux.js
 *
 * Copyright (c) Brightcove
 * Licensed Apache-2.0 https://github.com/videojs/mux.js/blob/master/LICENSE
 */
'use strict';

var Stream = require('../utils/stream.js');
var FlvTag = require('./flv-tag.js');
var m2ts = require('../m2ts/m2ts.js');
var AdtsStream = require('../codecs/adts.js');
var H264Stream = require('../codecs/h264').H264Stream;
var CoalesceStream = require('./coalesce-stream.js');
var TagList = require('./tag-list.js');

var
  Transmuxer,
  VideoSegmentStream,
  AudioSegmentStream,
  collectTimelineInfo,
  metaDataTag,
  extraDataTag;

/**
 * Store information about the start and end of the tracka and the
 * duration for each frame/sample we process in order to calculate
 * the baseMediaDecodeTime
 */
collectTimelineInfo = function(track, data) {
  if (typeof data.pts === 'number') {
    if (track.timelineStartInfo.pts === undefined) {
      track.timelineStartInfo.pts = data.pts;
    } else {
      track.timelineStartInfo.pts =
        Math.min(track.timelineStartInfo.pts, data.pts);
    }
  }

  if (typeof data.dts === 'number') {
    if (track.timelineStartInfo.dts === undefined) {
      track.timelineStartInfo.dts = data.dts;
    } else {
      track.timelineStartInfo.dts =
        Math.min(track.timelineStartInfo.dts, data.dts);
    }
  }
};

metaDataTag = function(track, pts) {
  var
    tag = new FlvTag(FlvTag.METADATA_TAG); // :FlvTag

  tag.dts = pts;
  tag.pts = pts;

  tag.writeMetaDataDouble('videocodecid', 7);
  tag.writeMetaDataDouble('width', track.width);
  tag.writeMetaDataDouble('height', track.height);

  return tag;
};

extraDataTag = function(track, pts) {
  var
    i,
    tag = new FlvTag(FlvTag.VIDEO_TAG, true);

  tag.dts = pts;
  tag.pts = pts;

  tag.writeByte(0x01);// version
  tag.writeByte(track.profileIdc);// profile
  tag.writeByte(track.profileCompatibility);// compatibility
  tag.writeByte(track.levelIdc);// level
  tag.writeByte(0xFC | 0x03); // reserved (6 bits), NULA length size - 1 (2 bits)
  tag.writeByte(0xE0 | 0x01); // reserved (3 bits), num of SPS (5 bits)
  tag.writeShort(track.sps[0].length); // data of SPS
  tag.writeBytes(track.sps[0]); // SPS

  tag.writeByte(track.pps.length); // num of PPS (will there ever be more that 1 PPS?)
  for (i = 0; i < track.pps.length; ++i) {
    tag.writeShort(track.pps[i].length); // 2 bytes for length of PPS
    tag.writeBytes(track.pps[i]); // data of PPS
  }

  return tag;
};

/**
 * Constructs a single-track, media segment from AAC data
 * events. The output of this stream can be fed to flash.
 */
AudioSegmentStream = function(track) {
  var
    adtsFrames = [],
    videoKeyFrames = [],
    oldExtraData;

  AudioSegmentStream.prototype.init.call(this);

  this.push = function(data) {
    collectTimelineInfo(track, data);

    if (track) {
      track.audioobjecttype = data.audioobjecttype;
      track.channelcount = data.channelcount;
      track.samplerate = data.samplerate;
      track.samplingfrequencyindex = data.samplingfrequencyindex;
      track.samplesize = data.samplesize;
      track.extraData = (track.audioobjecttype << 11) |
                        (track.samplingfrequencyindex << 7) |
                        (track.channelcount << 3);
    }

    data.pts = Math.round(data.pts / 90);
    data.dts = Math.round(data.dts / 90);

    // buffer audio data until end() is called
    adtsFrames.push(data);
  };

  this.flush = function() {
    var currentFrame, adtsFrame, lastMetaPts, tags = new TagList();
    // return early if no audio data has been observed
    if (adtsFrames.length === 0) {
      this.trigger('done', 'AudioSegmentStream');
      return;
    }

    lastMetaPts = -Infinity;

    while (adtsFrames.length) {
      currentFrame = adtsFrames.shift();

      // write out a metadata frame at every video key frame
      if (videoKeyFrames.length && currentFrame.pts >= videoKeyFrames[0]) {
        lastMetaPts = videoKeyFrames.shift();
        this.writeMetaDataTags(tags, lastMetaPts);
      }

      // also write out metadata tags every 1 second so that the decoder
      // is re-initialized quickly after seeking into a different
      // audio configuration.
      if (track.extraData !== oldExtraData || currentFrame.pts - lastMetaPts >= 1000) {
        this.writeMetaDataTags(tags, currentFrame.pts);
        oldExtraData = track.extraData;
        lastMetaPts = currentFrame.pts;
      }

      adtsFrame = new FlvTag(FlvTag.AUDIO_TAG);
      adtsFrame.pts = currentFrame.pts;
      adtsFrame.dts = currentFrame.dts;

      adtsFrame.writeBytes(currentFrame.data);

      tags.push(adtsFrame.finalize());
    }

    videoKeyFrames.length = 0;
    oldExtraData = null;
    this.trigger('data', {track: track, tags: tags.list});

    this.trigger('done', 'AudioSegmentStream');
  };

  this.writeMetaDataTags = function(tags, pts) {
    var adtsFrame;

    adtsFrame = new FlvTag(FlvTag.METADATA_TAG);
    // For audio, DTS is always the same as PTS. We want to set the DTS
    // however so we can compare with video DTS to determine approximate
    // packet order
    adtsFrame.pts = pts;
    adtsFrame.dts = pts;

    // AAC is always 10
    adtsFrame.writeMetaDataDouble('audiocodecid', 10);
    adtsFrame.writeMetaDataBoolean('stereo', track.channelcount === 2);
    adtsFrame.writeMetaDataDouble('audiosamplerate', track.samplerate);
    // Is AAC always 16 bit?
    adtsFrame.writeMetaDataDouble('audiosamplesize', 16);

    tags.push(adtsFrame.finalize());

    adtsFrame = new FlvTag(FlvTag.AUDIO_TAG, true);
    // For audio, DTS is always the same as PTS. We want to set the DTS
    // however so we can compare with video DTS to determine approximate
    // packet order
    adtsFrame.pts = pts;
    adtsFrame.dts = pts;

    adtsFrame.view.setUint16(adtsFrame.position, track.extraData);
    adtsFrame.position += 2;
    adtsFrame.length = Math.max(adtsFrame.length, adtsFrame.position);

    tags.push(adtsFrame.finalize());
  };

  this.onVideoKeyFrame = function(pts) {
    videoKeyFrames.push(pts);
  };
};
AudioSegmentStream.prototype = new Stream();

/**
 * Store FlvTags for the h264 stream
 * @param track {object} track metadata configuration
 */
VideoSegmentStream = function(track) {
  var
    nalUnits = [],
    config,
    h264Frame;
  VideoSegmentStream.prototype.init.call(this);

  this.finishFrame = function(tags, frame) {
    if (!frame) {
      return;
    }
    // Check if keyframe and the length of tags.
    // This makes sure we write metadata on the first frame of a segment.
    if (config && track && track.newMetadata &&
        (frame.keyFrame || tags.length === 0)) {
      // Push extra data on every IDR frame in case we did a stream change + seek
      var metaTag = metaDataTag(config, frame.dts).finalize();
      var extraTag = extraDataTag(track, frame.dts).finalize();

      metaTag.metaDataTag = extraTag.metaDataTag = true;

      tags.push(metaTag);
      tags.push(extraTag);
      track.newMetadata = false;

      this.trigger('keyframe', frame.dts);
    }

    frame.endNalUnit();
    tags.push(frame.finalize());
    h264Frame = null;
  };

  this.push = function(data) {
    collectTimelineInfo(track, data);

    data.pts = Math.round(data.pts / 90);
    data.dts = Math.round(data.dts / 90);

    // buffer video until flush() is called
    nalUnits.push(data);
  };

  this.flush = function() {
    var
      currentNal,
      tags = new TagList();

    // Throw away nalUnits at the start of the byte stream until we find
    // the first AUD
    while (nalUnits.length) {
      if (nalUnits[0].nalUnitType === 'access_unit_delimiter_rbsp') {
        break;
      }
      nalUnits.shift();
    }

    // return early if no video data has been observed
    if (nalUnits.length === 0) {
      this.trigger('done', 'VideoSegmentStream');
      return;
    }

    while (nalUnits.length) {
      currentNal = nalUnits.shift();

      // record the track config
      if (currentNal.nalUnitType === 'seq_parameter_set_rbsp') {
        track.newMetadata = true;
        config = currentNal.config;
        track.width = config.width;
        track.height = config.height;
        track.sps = [currentNal.data];
        track.profileIdc = config.profileIdc;
        track.levelIdc = config.levelIdc;
        track.profileCompatibility = config.profileCompatibility;
        h264Frame.endNalUnit();
      } else if (currentNal.nalUnitType === 'pic_parameter_set_rbsp') {
        track.newMetadata = true;
        track.pps = [currentNal.data];
        h264Frame.endNalUnit();
      } else if (currentNal.nalUnitType === 'access_unit_delimiter_rbsp') {
        if (h264Frame) {
          this.finishFrame(tags, h264Frame);
        }
        h264Frame = new FlvTag(FlvTag.VIDEO_TAG);
        h264Frame.pts = currentNal.pts;
        h264Frame.dts = currentNal.dts;
      } else {
        if (currentNal.nalUnitType === 'slice_layer_without_partitioning_rbsp_idr') {
          // the current sample is a key frame
          h264Frame.keyFrame = true;
        }
        h264Frame.endNalUnit();
      }
      h264Frame.startNalUnit();
      h264Frame.writeBytes(currentNal.data);
    }
    if (h264Frame) {
      this.finishFrame(tags, h264Frame);
    }

    this.trigger('data', {track: track, tags: tags.list});

    // Continue with the flush process now
    this.trigger('done', 'VideoSegmentStream');
  };
};

VideoSegmentStream.prototype = new Stream();

/**
 * An object that incrementally transmuxes MPEG2 Trasport Stream
 * chunks into an FLV.
 */
Transmuxer = function(options) {
  var
    self = this,

    packetStream, parseStream, elementaryStream,
    videoTimestampRolloverStream, audioTimestampRolloverStream,
    timedMetadataTimestampRolloverStream,
    adtsStream, h264Stream,
    videoSegmentStream, audioSegmentStream, captionStream,
    coalesceStream;

  Transmuxer.prototype.init.call(this);

  options = options || {};

  // expose the metadata stream
  this.metadataStream = new m2ts.MetadataStream();

  options.metadataStream = this.metadataStream;

  // set up the parsing pipeline
  packetStream = new m2ts.TransportPacketStream();
  parseStream = new m2ts.TransportParseStream();
  elementaryStream = new m2ts.ElementaryStream();
  videoTimestampRolloverStream = new m2ts.TimestampRolloverStream('video');
  audioTimestampRolloverStream = new m2ts.TimestampRolloverStream('audio');
  timedMetadataTimestampRolloverStream = new m2ts.TimestampRolloverStream('timed-metadata');

  adtsStream = new AdtsStream();
  h264Stream = new H264Stream();
  coalesceStream = new CoalesceStream(options);

  // disassemble MPEG2-TS packets into elementary streams
  packetStream
    .pipe(parseStream)
    .pipe(elementaryStream);

  // !!THIS ORDER IS IMPORTANT!!
  // demux the streams
  elementaryStream
    .pipe(videoTimestampRolloverStream)
    .pipe(h264Stream);
  elementaryStream
    .pipe(audioTimestampRolloverStream)
    .pipe(adtsStream);

  elementaryStream
    .pipe(timedMetadataTimestampRolloverStream)
    .pipe(this.metadataStream)
    .pipe(coalesceStream);
  // if CEA-708 parsing is available, hook up a caption stream
  captionStream = new m2ts.CaptionStream(options);
  h264Stream.pipe(captionStream)
    .pipe(coalesceStream);

  // hook up the segment streams once track metadata is delivered
  elementaryStream.on('data', function(data) {
    var i, videoTrack, audioTrack;

    if (data.type === 'metadata') {
      i = data.tracks.length;

      // scan the tracks listed in the metadata
      while (i--) {
        if (data.tracks[i].type === 'video') {
          videoTrack = data.tracks[i];
        } else if (data.tracks[i].type === 'audio') {
          audioTrack = data.tracks[i];
        }
      }

      // hook up the video segment stream to the first track with h264 data
      if (videoTrack && !videoSegmentStream) {
        coalesceStream.numberOfTracks++;
        videoSegmentStream = new VideoSegmentStream(videoTrack);

        // Set up the final part of the video pipeline
        h264Stream
          .pipe(videoSegmentStream)
          .pipe(coalesceStream);
      }

      if (audioTrack && !audioSegmentStream) {
        // hook up the audio segment stream to the first track with aac data
        coalesceStream.numberOfTracks++;
        audioSegmentStream = new AudioSegmentStream(audioTrack);

        // Set up the final part of the audio pipeline
        adtsStream
          .pipe(audioSegmentStream)
          .pipe(coalesceStream);

        if (videoSegmentStream) {
          videoSegmentStream.on('keyframe', audioSegmentStream.onVideoKeyFrame);
        }
      }
    }
  });

  // feed incoming data to the front of the parsing pipeline
  this.push = function(data) {
    packetStream.push(data);
  };

  // flush any buffered data
  this.flush = function() {
    // Start at the top of the pipeline and flush all pending work
    packetStream.flush();
  };

  // Caption data has to be reset when seeking outside buffered range
  this.resetCaptions = function() {
    captionStream.reset();
  };

  // Re-emit any data coming from the coalesce stream to the outside world
  coalesceStream.on('data', function(event) {
    self.trigger('data', event);
  });

  // Let the consumer know we have finished flushing the entire pipeline
  coalesceStream.on('done', function() {
    self.trigger('done');
  });
};
Transmuxer.prototype = new Stream();

// forward compatibility
module.exports = Transmuxer;
