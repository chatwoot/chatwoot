/**
 * mux.js
 *
 * Copyright (c) Brightcove
 * Licensed Apache-2.0 https://github.com/videojs/mux.js/blob/master/LICENSE
 *
 * Functions that generate fragmented MP4s suitable for use with Media
 * Source Extensions.
 */
'use strict';

var MAX_UINT32 = require('../utils/numbers.js').MAX_UINT32;


var box, dinf, esds, ftyp, mdat, mfhd, minf, moof, moov, mvex, mvhd,
    trak, tkhd, mdia, mdhd, hdlr, sdtp, stbl, stsd, traf, trex,
    trun, types, MAJOR_BRAND, MINOR_VERSION, AVC1_BRAND, VIDEO_HDLR,
    AUDIO_HDLR, HDLR_TYPES, VMHD, SMHD, DREF, STCO, STSC, STSZ, STTS;

// pre-calculate constants
(function() {
  var i;
  types = {
    avc1: [], // codingname
    avcC: [],
    btrt: [],
    dinf: [],
    dref: [],
    esds: [],
    ftyp: [],
    hdlr: [],
    mdat: [],
    mdhd: [],
    mdia: [],
    mfhd: [],
    minf: [],
    moof: [],
    moov: [],
    mp4a: [], // codingname
    mvex: [],
    mvhd: [],
    pasp: [],
    sdtp: [],
    smhd: [],
    stbl: [],
    stco: [],
    stsc: [],
    stsd: [],
    stsz: [],
    stts: [],
    styp: [],
    tfdt: [],
    tfhd: [],
    traf: [],
    trak: [],
    trun: [],
    trex: [],
    tkhd: [],
    vmhd: []
  };

  // In environments where Uint8Array is undefined (e.g., IE8), skip set up so that we
  // don't throw an error
  if (typeof Uint8Array === 'undefined') {
    return;
  }

  for (i in types) {
    if (types.hasOwnProperty(i)) {
      types[i] = [
        i.charCodeAt(0),
        i.charCodeAt(1),
        i.charCodeAt(2),
        i.charCodeAt(3)
      ];
    }
  }

  MAJOR_BRAND = new Uint8Array([
    'i'.charCodeAt(0),
    's'.charCodeAt(0),
    'o'.charCodeAt(0),
    'm'.charCodeAt(0)
  ]);
  AVC1_BRAND = new Uint8Array([
    'a'.charCodeAt(0),
    'v'.charCodeAt(0),
    'c'.charCodeAt(0),
    '1'.charCodeAt(0)
  ]);
  MINOR_VERSION = new Uint8Array([0, 0, 0, 1]);
  VIDEO_HDLR = new Uint8Array([
    0x00, // version 0
    0x00, 0x00, 0x00, // flags
    0x00, 0x00, 0x00, 0x00, // pre_defined
    0x76, 0x69, 0x64, 0x65, // handler_type: 'vide'
    0x00, 0x00, 0x00, 0x00, // reserved
    0x00, 0x00, 0x00, 0x00, // reserved
    0x00, 0x00, 0x00, 0x00, // reserved
    0x56, 0x69, 0x64, 0x65,
    0x6f, 0x48, 0x61, 0x6e,
    0x64, 0x6c, 0x65, 0x72, 0x00 // name: 'VideoHandler'
  ]);
  AUDIO_HDLR = new Uint8Array([
    0x00, // version 0
    0x00, 0x00, 0x00, // flags
    0x00, 0x00, 0x00, 0x00, // pre_defined
    0x73, 0x6f, 0x75, 0x6e, // handler_type: 'soun'
    0x00, 0x00, 0x00, 0x00, // reserved
    0x00, 0x00, 0x00, 0x00, // reserved
    0x00, 0x00, 0x00, 0x00, // reserved
    0x53, 0x6f, 0x75, 0x6e,
    0x64, 0x48, 0x61, 0x6e,
    0x64, 0x6c, 0x65, 0x72, 0x00 // name: 'SoundHandler'
  ]);
  HDLR_TYPES = {
    video: VIDEO_HDLR,
    audio: AUDIO_HDLR
  };
  DREF = new Uint8Array([
    0x00, // version 0
    0x00, 0x00, 0x00, // flags
    0x00, 0x00, 0x00, 0x01, // entry_count
    0x00, 0x00, 0x00, 0x0c, // entry_size
    0x75, 0x72, 0x6c, 0x20, // 'url' type
    0x00, // version 0
    0x00, 0x00, 0x01 // entry_flags
  ]);
  SMHD = new Uint8Array([
    0x00,             // version
    0x00, 0x00, 0x00, // flags
    0x00, 0x00,       // balance, 0 means centered
    0x00, 0x00        // reserved
  ]);
  STCO = new Uint8Array([
    0x00, // version
    0x00, 0x00, 0x00, // flags
    0x00, 0x00, 0x00, 0x00 // entry_count
  ]);
  STSC = STCO;
  STSZ = new Uint8Array([
    0x00, // version
    0x00, 0x00, 0x00, // flags
    0x00, 0x00, 0x00, 0x00, // sample_size
    0x00, 0x00, 0x00, 0x00 // sample_count
  ]);
  STTS = STCO;
  VMHD = new Uint8Array([
    0x00, // version
    0x00, 0x00, 0x01, // flags
    0x00, 0x00, // graphicsmode
    0x00, 0x00,
    0x00, 0x00,
    0x00, 0x00 // opcolor
  ]);
}());

box = function(type) {
  var
    payload = [],
    size = 0,
    i,
    result,
    view;

  for (i = 1; i < arguments.length; i++) {
    payload.push(arguments[i]);
  }

  i = payload.length;

  // calculate the total size we need to allocate
  while (i--) {
    size += payload[i].byteLength;
  }
  result = new Uint8Array(size + 8);
  view = new DataView(result.buffer, result.byteOffset, result.byteLength);
  view.setUint32(0, result.byteLength);
  result.set(type, 4);

  // copy the payload into the result
  for (i = 0, size = 8; i < payload.length; i++) {
    result.set(payload[i], size);
    size += payload[i].byteLength;
  }
  return result;
};

dinf = function() {
  return box(types.dinf, box(types.dref, DREF));
};

esds = function(track) {
  return box(types.esds, new Uint8Array([
    0x00, // version
    0x00, 0x00, 0x00, // flags

    // ES_Descriptor
    0x03, // tag, ES_DescrTag
    0x19, // length
    0x00, 0x00, // ES_ID
    0x00, // streamDependenceFlag, URL_flag, reserved, streamPriority

    // DecoderConfigDescriptor
    0x04, // tag, DecoderConfigDescrTag
    0x11, // length
    0x40, // object type
    0x15,  // streamType
    0x00, 0x06, 0x00, // bufferSizeDB
    0x00, 0x00, 0xda, 0xc0, // maxBitrate
    0x00, 0x00, 0xda, 0xc0, // avgBitrate

    // DecoderSpecificInfo
    0x05, // tag, DecoderSpecificInfoTag
    0x02, // length
    // ISO/IEC 14496-3, AudioSpecificConfig
    // for samplingFrequencyIndex see ISO/IEC 13818-7:2006, 8.1.3.2.2, Table 35
    (track.audioobjecttype << 3) | (track.samplingfrequencyindex >>> 1),
    (track.samplingfrequencyindex << 7) | (track.channelcount << 3),
    0x06, 0x01, 0x02 // GASpecificConfig
  ]));
};

ftyp = function() {
  return box(types.ftyp, MAJOR_BRAND, MINOR_VERSION, MAJOR_BRAND, AVC1_BRAND);
};

hdlr = function(type) {
  return box(types.hdlr, HDLR_TYPES[type]);
};
mdat = function(data) {
  return box(types.mdat, data);
};
mdhd = function(track) {
  var result = new Uint8Array([
    0x00,                   // version 0
    0x00, 0x00, 0x00,       // flags
    0x00, 0x00, 0x00, 0x02, // creation_time
    0x00, 0x00, 0x00, 0x03, // modification_time
    0x00, 0x01, 0x5f, 0x90, // timescale, 90,000 "ticks" per second

    (track.duration >>> 24) & 0xFF,
    (track.duration >>> 16) & 0xFF,
    (track.duration >>>  8) & 0xFF,
    track.duration & 0xFF,  // duration
    0x55, 0xc4,             // 'und' language (undetermined)
    0x00, 0x00
  ]);

  // Use the sample rate from the track metadata, when it is
  // defined. The sample rate can be parsed out of an ADTS header, for
  // instance.
  if (track.samplerate) {
    result[12] = (track.samplerate >>> 24) & 0xFF;
    result[13] = (track.samplerate >>> 16) & 0xFF;
    result[14] = (track.samplerate >>>  8) & 0xFF;
    result[15] = (track.samplerate)        & 0xFF;
  }

  return box(types.mdhd, result);
};
mdia = function(track) {
  return box(types.mdia, mdhd(track), hdlr(track.type), minf(track));
};
mfhd = function(sequenceNumber) {
  return box(types.mfhd, new Uint8Array([
    0x00,
    0x00, 0x00, 0x00, // flags
    (sequenceNumber & 0xFF000000) >> 24,
    (sequenceNumber & 0xFF0000) >> 16,
    (sequenceNumber & 0xFF00) >> 8,
    sequenceNumber & 0xFF // sequence_number
  ]));
};
minf = function(track) {
  return box(types.minf,
             track.type === 'video' ? box(types.vmhd, VMHD) : box(types.smhd, SMHD),
             dinf(),
             stbl(track));
};
moof = function(sequenceNumber, tracks) {
  var
    trackFragments = [],
    i = tracks.length;
  // build traf boxes for each track fragment
  while (i--) {
    trackFragments[i] = traf(tracks[i]);
  }
  return box.apply(null, [
    types.moof,
    mfhd(sequenceNumber)
  ].concat(trackFragments));
};
/**
 * Returns a movie box.
 * @param tracks {array} the tracks associated with this movie
 * @see ISO/IEC 14496-12:2012(E), section 8.2.1
 */
moov = function(tracks) {
  var
    i = tracks.length,
    boxes = [];

  while (i--) {
    boxes[i] = trak(tracks[i]);
  }

  return box.apply(null, [types.moov, mvhd(0xffffffff)].concat(boxes).concat(mvex(tracks)));
};
mvex = function(tracks) {
  var
    i = tracks.length,
    boxes = [];

  while (i--) {
    boxes[i] = trex(tracks[i]);
  }
  return box.apply(null, [types.mvex].concat(boxes));
};
mvhd = function(duration) {
  var
    bytes = new Uint8Array([
      0x00, // version 0
      0x00, 0x00, 0x00, // flags
      0x00, 0x00, 0x00, 0x01, // creation_time
      0x00, 0x00, 0x00, 0x02, // modification_time
      0x00, 0x01, 0x5f, 0x90, // timescale, 90,000 "ticks" per second
      (duration & 0xFF000000) >> 24,
      (duration & 0xFF0000) >> 16,
      (duration & 0xFF00) >> 8,
      duration & 0xFF, // duration
      0x00, 0x01, 0x00, 0x00, // 1.0 rate
      0x01, 0x00, // 1.0 volume
      0x00, 0x00, // reserved
      0x00, 0x00, 0x00, 0x00, // reserved
      0x00, 0x00, 0x00, 0x00, // reserved
      0x00, 0x01, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00,
      0x00, 0x01, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00,
      0x40, 0x00, 0x00, 0x00, // transformation: unity matrix
      0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, // pre_defined
      0xff, 0xff, 0xff, 0xff // next_track_ID
    ]);
  return box(types.mvhd, bytes);
};

sdtp = function(track) {
  var
    samples = track.samples || [],
    bytes = new Uint8Array(4 + samples.length),
    flags,
    i;

  // leave the full box header (4 bytes) all zero

  // write the sample table
  for (i = 0; i < samples.length; i++) {
    flags = samples[i].flags;

    bytes[i + 4] = (flags.dependsOn << 4) |
      (flags.isDependedOn << 2) |
      (flags.hasRedundancy);
  }

  return box(types.sdtp,
             bytes);
};

stbl = function(track) {
  return box(types.stbl,
             stsd(track),
             box(types.stts, STTS),
             box(types.stsc, STSC),
             box(types.stsz, STSZ),
             box(types.stco, STCO));
};

(function() {
  var videoSample, audioSample;

  stsd = function(track) {

    return box(types.stsd, new Uint8Array([
      0x00, // version 0
      0x00, 0x00, 0x00, // flags
      0x00, 0x00, 0x00, 0x01
    ]), track.type === 'video' ? videoSample(track) : audioSample(track));
  };

  videoSample = function(track) {
    var
      sps = track.sps || [],
      pps = track.pps || [],
      sequenceParameterSets = [],
      pictureParameterSets = [],
      i,
      avc1Box;

    // assemble the SPSs
    for (i = 0; i < sps.length; i++) {
      sequenceParameterSets.push((sps[i].byteLength & 0xFF00) >>> 8);
      sequenceParameterSets.push((sps[i].byteLength & 0xFF)); // sequenceParameterSetLength
      sequenceParameterSets = sequenceParameterSets.concat(Array.prototype.slice.call(sps[i])); // SPS
    }

    // assemble the PPSs
    for (i = 0; i < pps.length; i++) {
      pictureParameterSets.push((pps[i].byteLength & 0xFF00) >>> 8);
      pictureParameterSets.push((pps[i].byteLength & 0xFF));
      pictureParameterSets = pictureParameterSets.concat(Array.prototype.slice.call(pps[i]));
    }

    avc1Box = [
      types.avc1, new Uint8Array([
        0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, // reserved
        0x00, 0x01, // data_reference_index
        0x00, 0x00, // pre_defined
        0x00, 0x00, // reserved
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, // pre_defined
        (track.width & 0xff00) >> 8,
        track.width & 0xff, // width
        (track.height & 0xff00) >> 8,
        track.height & 0xff, // height
        0x00, 0x48, 0x00, 0x00, // horizresolution
        0x00, 0x48, 0x00, 0x00, // vertresolution
        0x00, 0x00, 0x00, 0x00, // reserved
        0x00, 0x01, // frame_count
        0x13,
        0x76, 0x69, 0x64, 0x65,
        0x6f, 0x6a, 0x73, 0x2d,
        0x63, 0x6f, 0x6e, 0x74,
        0x72, 0x69, 0x62, 0x2d,
        0x68, 0x6c, 0x73, 0x00,
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, // compressorname
        0x00, 0x18, // depth = 24
        0x11, 0x11 // pre_defined = -1
      ]),
      box(types.avcC, new Uint8Array([
        0x01, // configurationVersion
        track.profileIdc, // AVCProfileIndication
        track.profileCompatibility, // profile_compatibility
        track.levelIdc, // AVCLevelIndication
        0xff // lengthSizeMinusOne, hard-coded to 4 bytes
      ].concat(
        [sps.length], // numOfSequenceParameterSets
        sequenceParameterSets, // "SPS"
        [pps.length], // numOfPictureParameterSets
        pictureParameterSets // "PPS"
      ))),
      box(types.btrt, new Uint8Array([
        0x00, 0x1c, 0x9c, 0x80, // bufferSizeDB
        0x00, 0x2d, 0xc6, 0xc0, // maxBitrate
        0x00, 0x2d, 0xc6, 0xc0 // avgBitrate
      ]))
    ];

    if (track.sarRatio) {
      var
        hSpacing = track.sarRatio[0],
        vSpacing = track.sarRatio[1];

        avc1Box.push(
          box(types.pasp, new Uint8Array([
            (hSpacing & 0xFF000000) >> 24,
            (hSpacing & 0xFF0000) >> 16,
            (hSpacing & 0xFF00) >> 8,
            hSpacing & 0xFF,
            (vSpacing & 0xFF000000) >> 24,
            (vSpacing & 0xFF0000) >> 16,
            (vSpacing & 0xFF00) >> 8,
            vSpacing & 0xFF
          ]))
        );
    }

    return box.apply(null, avc1Box);
  };

  audioSample = function(track) {
    return box(types.mp4a, new Uint8Array([

      // SampleEntry, ISO/IEC 14496-12
      0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, // reserved
      0x00, 0x01, // data_reference_index

      // AudioSampleEntry, ISO/IEC 14496-12
      0x00, 0x00, 0x00, 0x00, // reserved
      0x00, 0x00, 0x00, 0x00, // reserved
      (track.channelcount & 0xff00) >> 8,
      (track.channelcount & 0xff), // channelcount

      (track.samplesize & 0xff00) >> 8,
      (track.samplesize & 0xff), // samplesize
      0x00, 0x00, // pre_defined
      0x00, 0x00, // reserved

      (track.samplerate & 0xff00) >> 8,
      (track.samplerate & 0xff),
      0x00, 0x00 // samplerate, 16.16

      // MP4AudioSampleEntry, ISO/IEC 14496-14
    ]), esds(track));
  };
}());

tkhd = function(track) {
  var result = new Uint8Array([
    0x00, // version 0
    0x00, 0x00, 0x07, // flags
    0x00, 0x00, 0x00, 0x00, // creation_time
    0x00, 0x00, 0x00, 0x00, // modification_time
    (track.id & 0xFF000000) >> 24,
    (track.id & 0xFF0000) >> 16,
    (track.id & 0xFF00) >> 8,
    track.id & 0xFF, // track_ID
    0x00, 0x00, 0x00, 0x00, // reserved
    (track.duration & 0xFF000000) >> 24,
    (track.duration & 0xFF0000) >> 16,
    (track.duration & 0xFF00) >> 8,
    track.duration & 0xFF, // duration
    0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, // reserved
    0x00, 0x00, // layer
    0x00, 0x00, // alternate_group
    0x01, 0x00, // non-audio track volume
    0x00, 0x00, // reserved
    0x00, 0x01, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00,
    0x00, 0x01, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00,
    0x40, 0x00, 0x00, 0x00, // transformation: unity matrix
    (track.width & 0xFF00) >> 8,
    track.width & 0xFF,
    0x00, 0x00, // width
    (track.height & 0xFF00) >> 8,
    track.height & 0xFF,
    0x00, 0x00 // height
  ]);

  return box(types.tkhd, result);
};

/**
 * Generate a track fragment (traf) box. A traf box collects metadata
 * about tracks in a movie fragment (moof) box.
 */
traf = function(track) {
  var trackFragmentHeader, trackFragmentDecodeTime, trackFragmentRun,
      sampleDependencyTable, dataOffset,
      upperWordBaseMediaDecodeTime, lowerWordBaseMediaDecodeTime;

  trackFragmentHeader = box(types.tfhd, new Uint8Array([
    0x00, // version 0
    0x00, 0x00, 0x3a, // flags
    (track.id & 0xFF000000) >> 24,
    (track.id & 0xFF0000) >> 16,
    (track.id & 0xFF00) >> 8,
    (track.id & 0xFF), // track_ID
    0x00, 0x00, 0x00, 0x01, // sample_description_index
    0x00, 0x00, 0x00, 0x00, // default_sample_duration
    0x00, 0x00, 0x00, 0x00, // default_sample_size
    0x00, 0x00, 0x00, 0x00  // default_sample_flags
  ]));

  upperWordBaseMediaDecodeTime = Math.floor(track.baseMediaDecodeTime / (MAX_UINT32));
  lowerWordBaseMediaDecodeTime = Math.floor(track.baseMediaDecodeTime % (MAX_UINT32));

  trackFragmentDecodeTime = box(types.tfdt, new Uint8Array([
    0x01, // version 1
    0x00, 0x00, 0x00, // flags
    // baseMediaDecodeTime
    (upperWordBaseMediaDecodeTime >>> 24) & 0xFF,
    (upperWordBaseMediaDecodeTime >>> 16) & 0xFF,
    (upperWordBaseMediaDecodeTime >>>  8) & 0xFF,
    upperWordBaseMediaDecodeTime & 0xFF,
    (lowerWordBaseMediaDecodeTime >>> 24) & 0xFF,
    (lowerWordBaseMediaDecodeTime >>> 16) & 0xFF,
    (lowerWordBaseMediaDecodeTime >>>  8) & 0xFF,
    lowerWordBaseMediaDecodeTime & 0xFF
  ]));

  // the data offset specifies the number of bytes from the start of
  // the containing moof to the first payload byte of the associated
  // mdat
  dataOffset = (32 + // tfhd
                20 + // tfdt
                8 +  // traf header
                16 + // mfhd
                8 +  // moof header
                8);  // mdat header

  // audio tracks require less metadata
  if (track.type === 'audio') {
    trackFragmentRun = trun(track, dataOffset);
    return box(types.traf,
               trackFragmentHeader,
               trackFragmentDecodeTime,
               trackFragmentRun);
  }

  // video tracks should contain an independent and disposable samples
  // box (sdtp)
  // generate one and adjust offsets to match
  sampleDependencyTable = sdtp(track);
  trackFragmentRun = trun(track,
                          sampleDependencyTable.length + dataOffset);
  return box(types.traf,
             trackFragmentHeader,
             trackFragmentDecodeTime,
             trackFragmentRun,
             sampleDependencyTable);
};

/**
 * Generate a track box.
 * @param track {object} a track definition
 * @return {Uint8Array} the track box
 */
trak = function(track) {
  track.duration = track.duration || 0xffffffff;
  return box(types.trak,
             tkhd(track),
             mdia(track));
};

trex = function(track) {
  var result = new Uint8Array([
    0x00, // version 0
    0x00, 0x00, 0x00, // flags
    (track.id & 0xFF000000) >> 24,
    (track.id & 0xFF0000) >> 16,
    (track.id & 0xFF00) >> 8,
    (track.id & 0xFF), // track_ID
    0x00, 0x00, 0x00, 0x01, // default_sample_description_index
    0x00, 0x00, 0x00, 0x00, // default_sample_duration
    0x00, 0x00, 0x00, 0x00, // default_sample_size
    0x00, 0x01, 0x00, 0x01 // default_sample_flags
  ]);
  // the last two bytes of default_sample_flags is the sample
  // degradation priority, a hint about the importance of this sample
  // relative to others. Lower the degradation priority for all sample
  // types other than video.
  if (track.type !== 'video') {
    result[result.length - 1] = 0x00;
  }

  return box(types.trex, result);
};

(function() {
  var audioTrun, videoTrun, trunHeader;

  // This method assumes all samples are uniform. That is, if a
  // duration is present for the first sample, it will be present for
  // all subsequent samples.
  // see ISO/IEC 14496-12:2012, Section 8.8.8.1
  trunHeader = function(samples, offset) {
    var durationPresent = 0, sizePresent = 0,
        flagsPresent = 0, compositionTimeOffset = 0;

    // trun flag constants
    if (samples.length) {
      if (samples[0].duration !== undefined) {
        durationPresent = 0x1;
      }
      if (samples[0].size !== undefined) {
        sizePresent = 0x2;
      }
      if (samples[0].flags !== undefined) {
        flagsPresent = 0x4;
      }
      if (samples[0].compositionTimeOffset !== undefined) {
        compositionTimeOffset = 0x8;
      }
    }

    return [
      0x00, // version 0
      0x00,
      durationPresent | sizePresent | flagsPresent | compositionTimeOffset,
      0x01, // flags
      (samples.length & 0xFF000000) >>> 24,
      (samples.length & 0xFF0000) >>> 16,
      (samples.length & 0xFF00) >>> 8,
      samples.length & 0xFF, // sample_count
      (offset & 0xFF000000) >>> 24,
      (offset & 0xFF0000) >>> 16,
      (offset & 0xFF00) >>> 8,
      offset & 0xFF // data_offset
    ];
  };

  videoTrun = function(track, offset) {
    var bytesOffest, bytes, header, samples, sample, i;

    samples = track.samples || [];
    offset += 8 + 12 + (16 * samples.length);
    header = trunHeader(samples, offset);
    bytes = new Uint8Array(header.length + samples.length * 16);
    bytes.set(header);
    bytesOffest = header.length;

    for (i = 0; i < samples.length; i++) {
      sample = samples[i];

      bytes[bytesOffest++] = (sample.duration & 0xFF000000) >>> 24;
      bytes[bytesOffest++] = (sample.duration & 0xFF0000) >>> 16;
      bytes[bytesOffest++] = (sample.duration & 0xFF00) >>> 8;
      bytes[bytesOffest++] = sample.duration & 0xFF; // sample_duration
      bytes[bytesOffest++] = (sample.size & 0xFF000000) >>> 24;
      bytes[bytesOffest++] = (sample.size & 0xFF0000) >>> 16;
      bytes[bytesOffest++] = (sample.size & 0xFF00) >>> 8;
      bytes[bytesOffest++] = sample.size & 0xFF; // sample_size
      bytes[bytesOffest++] = (sample.flags.isLeading << 2) | sample.flags.dependsOn;
      bytes[bytesOffest++] = (sample.flags.isDependedOn << 6) |
          (sample.flags.hasRedundancy << 4) |
          (sample.flags.paddingValue << 1) |
          sample.flags.isNonSyncSample;
      bytes[bytesOffest++] = sample.flags.degradationPriority & 0xF0 << 8;
      bytes[bytesOffest++] = sample.flags.degradationPriority & 0x0F; // sample_flags
      bytes[bytesOffest++] = (sample.compositionTimeOffset & 0xFF000000) >>> 24;
      bytes[bytesOffest++] = (sample.compositionTimeOffset & 0xFF0000) >>> 16;
      bytes[bytesOffest++] = (sample.compositionTimeOffset & 0xFF00) >>> 8;
      bytes[bytesOffest++] = sample.compositionTimeOffset & 0xFF; // sample_composition_time_offset
    }
    return box(types.trun, bytes);
  };

  audioTrun = function(track, offset) {
    var bytes, bytesOffest, header, samples, sample, i;

    samples = track.samples || [];
    offset += 8 + 12 + (8 * samples.length);

    header = trunHeader(samples, offset);
    bytes = new Uint8Array(header.length + samples.length * 8);
    bytes.set(header);
    bytesOffest = header.length;

    for (i = 0; i < samples.length; i++) {
      sample = samples[i];
      bytes[bytesOffest++] = (sample.duration & 0xFF000000) >>> 24;
      bytes[bytesOffest++] = (sample.duration & 0xFF0000) >>> 16;
      bytes[bytesOffest++] = (sample.duration & 0xFF00) >>> 8;
      bytes[bytesOffest++] = sample.duration & 0xFF; // sample_duration
      bytes[bytesOffest++] = (sample.size & 0xFF000000) >>> 24;
      bytes[bytesOffest++] = (sample.size & 0xFF0000) >>> 16;
      bytes[bytesOffest++] = (sample.size & 0xFF00) >>> 8;
      bytes[bytesOffest++] = sample.size & 0xFF; // sample_size
    }

    return box(types.trun, bytes);
  };

  trun = function(track, offset) {
    if (track.type === 'audio') {
      return audioTrun(track, offset);
    }

    return videoTrun(track, offset);
  };
}());

module.exports = {
  ftyp: ftyp,
  mdat: mdat,
  moof: moof,
  moov: moov,
  initSegment: function(tracks) {
    var
      fileType = ftyp(),
      movie = moov(tracks),
      result;

    result = new Uint8Array(fileType.byteLength + movie.byteLength);
    result.set(fileType);
    result.set(movie, fileType.byteLength);
    return result;
  }
};
