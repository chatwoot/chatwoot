import {
  toUint8,
  bytesToNumber,
  bytesMatch,
  bytesToString,
  numberToBytes,
  padStart
} from './byte-helpers';
import {getAvcCodec, getHvcCodec, getAv1Codec} from './codec-helpers.js';

// relevant specs for this parser:
// https://matroska-org.github.io/libebml/specs.html
// https://www.matroska.org/technical/elements.html
// https://www.webmproject.org/docs/container/

export const EBML_TAGS = {
  EBML: toUint8([0x1A, 0x45, 0xDF, 0xA3]),
  DocType: toUint8([0x42, 0x82]),
  Segment: toUint8([0x18, 0x53, 0x80, 0x67]),
  SegmentInfo: toUint8([0x15, 0x49, 0xA9, 0x66]),
  Tracks: toUint8([0x16, 0x54, 0xAE, 0x6B]),
  Track: toUint8([0xAE]),
  TrackNumber: toUint8([0xd7]),
  DefaultDuration: toUint8([0x23, 0xe3, 0x83]),
  TrackEntry: toUint8([0xAE]),
  TrackType: toUint8([0x83]),
  FlagDefault: toUint8([0x88]),
  CodecID: toUint8([0x86]),
  CodecPrivate: toUint8([0x63, 0xA2]),
  VideoTrack: toUint8([0xe0]),
  AudioTrack: toUint8([0xe1]),

  // Not used yet, but will be used for live webm/mkv
  // see https://www.matroska.org/technical/basics.html#block-structure
  // see https://www.matroska.org/technical/basics.html#simpleblock-structure
  Cluster: toUint8([0x1F, 0x43, 0xB6, 0x75]),
  Timestamp: toUint8([0xE7]),
  TimestampScale: toUint8([0x2A, 0xD7, 0xB1]),
  BlockGroup: toUint8([0xA0]),
  BlockDuration: toUint8([0x9B]),
  Block: toUint8([0xA1]),
  SimpleBlock: toUint8([0xA3])
};

/**
 * This is a simple table to determine the length
 * of things in ebml. The length is one based (starts at 1,
 * rather than zero) and for every zero bit before a one bit
 * we add one to length. We also need this table because in some
 * case we have to xor all the length bits from another value.
 */
const LENGTH_TABLE = [
  0b10000000,
  0b01000000,
  0b00100000,
  0b00010000,
  0b00001000,
  0b00000100,
  0b00000010,
  0b00000001
];

const getLength = function(byte) {
  let len = 1;

  for (let i = 0; i < LENGTH_TABLE.length; i++) {
    if (byte & LENGTH_TABLE[i]) {
      break;
    }

    len++;
  }

  return len;
};

// length in ebml is stored in the first 4 to 8 bits
// of the first byte. 4 for the id length and 8 for the
// data size length. Length is measured by converting the number to binary
// then 1 + the number of zeros before a 1 is encountered starting
// from the left.
const getvint = function(bytes, offset, removeLength = true, signed = false) {
  const length = getLength(bytes[offset]);
  let valueBytes = bytes.subarray(offset, offset + length);

  // NOTE that we do **not** subarray here because we need to copy these bytes
  // as they will be modified below to remove the dataSizeLen bits and we do not
  // want to modify the original data. normally we could just call slice on
  // uint8array but ie 11 does not support that...
  if (removeLength) {
    valueBytes = Array.prototype.slice.call(bytes, offset, offset + length);
    valueBytes[0] ^= LENGTH_TABLE[length - 1];
  }

  return {
    length,
    value: bytesToNumber(valueBytes, {signed}),
    bytes: valueBytes
  };
};

const normalizePath = function(path) {
  if (typeof path === 'string') {
    return path.match(/.{1,2}/g).map((p) => normalizePath(p));
  }

  if (typeof path === 'number') {
    return numberToBytes(path);
  }

  return path;
};

const normalizePaths = function(paths) {
  if (!Array.isArray(paths)) {
    return [normalizePath(paths)];
  }

  return paths.map((p) => normalizePath(p));
};

const getInfinityDataSize = (id, bytes, offset) => {
  if (offset >= bytes.length) {
    return bytes.length;
  }
  const innerid = getvint(bytes, offset, false);

  if (bytesMatch(id.bytes, innerid.bytes)) {
    return offset;
  }

  const dataHeader = getvint(bytes, offset + innerid.length);

  return getInfinityDataSize(id, bytes, offset + dataHeader.length + dataHeader.value + innerid.length);
};

/**
 * Notes on the EBLM format.
 *
 * EBLM uses "vints" tags. Every vint tag contains
 * two parts
 *
 * 1. The length from the first byte. You get this by
 *    converting the byte to binary and counting the zeros
 *    before a 1. Then you add 1 to that. Examples
 *    00011111 = length 4 because there are 3 zeros before a 1.
 *    00100000 = length 3 because there are 2 zeros before a 1.
 *    00000011 = length 7 because there are 6 zeros before a 1.
 *
 * 2. The bits used for length are removed from the first byte
 *    Then all the bytes are merged into a value. NOTE: this
 *    is not the case for id ebml tags as there id includes
 *    length bits.
 *
 */
export const findEbml = function(bytes, paths) {
  paths = normalizePaths(paths);
  bytes = toUint8(bytes);
  let results = [];

  if (!paths.length) {
    return results;
  }

  let i = 0;

  while (i < bytes.length) {
    const id = getvint(bytes, i, false);
    const dataHeader = getvint(bytes, i + id.length);
    const dataStart = i + id.length + dataHeader.length;

    // dataSize is unknown or this is a live stream
    if (dataHeader.value === 0x7f) {
      dataHeader.value = getInfinityDataSize(id, bytes, dataStart);

      if (dataHeader.value !== bytes.length) {
        dataHeader.value -= dataStart;
      }
    }
    const dataEnd = (dataStart + dataHeader.value) > bytes.length ? bytes.length : (dataStart + dataHeader.value);
    const data = bytes.subarray(dataStart, dataEnd);

    if (bytesMatch(paths[0], id.bytes)) {
      if (paths.length === 1) {
        // this is the end of the paths and we've found the tag we were
        // looking for
        results.push(data);
      } else {
        // recursively search for the next tag inside of the data
        // of this one
        results = results.concat(findEbml(data, paths.slice(1)));
      }
    }

    const totalLength = id.length + dataHeader.length + data.length;

    // move past this tag entirely, we are not looking for it
    i += totalLength;
  }

  return results;
};

// see https://www.matroska.org/technical/basics.html#block-structure
export const decodeBlock = function(block, type, timestampScale, clusterTimestamp) {
  let duration;

  if (type === 'group') {
    duration = findEbml(block, [EBML_TAGS.BlockDuration])[0];
    if (duration) {
      duration = bytesToNumber(duration);
      duration = (((1 / timestampScale) * (duration)) * timestampScale) / 1000;
    }
    block = findEbml(block, [EBML_TAGS.Block])[0];
    type = 'block';
    // treat data as a block after this point
  }
  const dv = new DataView(block.buffer, block.byteOffset, block.byteLength);
  const trackNumber = getvint(block, 0);
  const timestamp = dv.getInt16(trackNumber.length, false);
  const flags = block[trackNumber.length + 2];
  const data = block.subarray(trackNumber.length + 3);
  // pts/dts in seconds
  const ptsdts = (((1 / timestampScale) * (clusterTimestamp + timestamp)) * timestampScale) / 1000;

  // return the frame
  const parsed = {
    duration,
    trackNumber: trackNumber.value,
    keyframe: type === 'simple' && (flags >> 7) === 1,
    invisible: ((flags & 0x08) >> 3) === 1,
    lacing: ((flags & 0x06) >> 1),
    discardable: type === 'simple' && (flags & 0x01) === 1,
    frames: [],
    pts: ptsdts,
    dts: ptsdts,
    timestamp
  };

  if (!parsed.lacing) {
    parsed.frames.push(data);
    return parsed;
  }

  const numberOfFrames = data[0] + 1;

  const frameSizes = [];
  let offset = 1;

  // Fixed
  if (parsed.lacing === 2) {
    const sizeOfFrame = (data.length - offset) / numberOfFrames;

    for (let i = 0; i < numberOfFrames; i++) {
      frameSizes.push(sizeOfFrame);
    }
  }

  // xiph
  if (parsed.lacing === 1) {
    for (let i = 0; i < numberOfFrames - 1; i++) {
      let size = 0;

      do {
        size += data[offset];
        offset++;
      } while (data[offset - 1] === 0xFF);

      frameSizes.push(size);
    }
  }

  // ebml
  if (parsed.lacing === 3) {
    // first vint is unsinged
    // after that vints are singed and
    // based on a compounding size
    let size = 0;

    for (let i = 0; i < numberOfFrames - 1; i++) {
      const vint = i === 0 ? getvint(data, offset) : getvint(data, offset, true, true);

      size += vint.value;
      frameSizes.push(size);
      offset += vint.length;
    }
  }

  frameSizes.forEach(function(size) {
    parsed.frames.push(data.subarray(offset, offset + size));
    offset += size;
  });

  return parsed;
};

// VP9 Codec Feature Metadata (CodecPrivate)
// https://www.webmproject.org/docs/container/
const parseVp9Private = (bytes) => {
  let i = 0;
  const params = {};

  while (i < bytes.length) {
    const id = bytes[i] & 0x7f;
    const len = bytes[i + 1];
    let val;

    if (len === 1) {
      val = bytes[i + 2];
    } else {
      val = bytes.subarray(i + 2, i + 2 + len);
    }

    if (id === 1) {
      params.profile = val;
    } else if (id === 2) {
      params.level = val;
    } else if (id === 3) {
      params.bitDepth = val;
    } else if (id === 4) {
      params.chromaSubsampling = val;
    } else {
      params[id] = val;
    }

    i += 2 + len;
  }

  return params;
};

export const parseTracks = function(bytes) {
  bytes = toUint8(bytes);
  const decodedTracks = [];
  let tracks = findEbml(bytes, [EBML_TAGS.Segment, EBML_TAGS.Tracks, EBML_TAGS.Track]);

  if (!tracks.length) {
    tracks = findEbml(bytes, [EBML_TAGS.Tracks, EBML_TAGS.Track]);
  }

  if (!tracks.length) {
    tracks = findEbml(bytes, [EBML_TAGS.Track]);
  }

  if (!tracks.length) {
    return decodedTracks;
  }

  tracks.forEach(function(track) {
    let trackType = findEbml(track, EBML_TAGS.TrackType)[0];

    if (!trackType || !trackType.length) {
      return;
    }

    // 1 is video, 2 is audio, 17 is subtitle
    // other values are unimportant in this context
    if (trackType[0] === 1) {
      trackType = 'video';
    } else if (trackType[0] === 2) {
      trackType = 'audio';
    } else if (trackType[0] === 17) {
      trackType = 'subtitle';
    } else {
      return;
    }

    // todo parse language
    const decodedTrack = {
      rawCodec: bytesToString(findEbml(track, [EBML_TAGS.CodecID])[0]),
      type: trackType,
      codecPrivate: findEbml(track, [EBML_TAGS.CodecPrivate])[0],
      number: bytesToNumber(findEbml(track, [EBML_TAGS.TrackNumber])[0]),
      defaultDuration: bytesToNumber(findEbml(track, [EBML_TAGS.DefaultDuration])[0]),
      default: findEbml(track, [EBML_TAGS.FlagDefault])[0],
      rawData: track
    };

    let codec = '';

    if ((/V_MPEG4\/ISO\/AVC/).test(decodedTrack.rawCodec)) {
      codec = `avc1.${getAvcCodec(decodedTrack.codecPrivate)}`;
    } else if ((/V_MPEGH\/ISO\/HEVC/).test(decodedTrack.rawCodec)) {
      codec = `hev1.${getHvcCodec(decodedTrack.codecPrivate)}`;
    } else if ((/V_MPEG4\/ISO\/ASP/).test(decodedTrack.rawCodec)) {
      if (decodedTrack.codecPrivate) {
        codec = 'mp4v.20.' + decodedTrack.codecPrivate[4].toString();
      } else {
        codec = 'mp4v.20.9';
      }
    } else if ((/^V_THEORA/).test(decodedTrack.rawCodec)) {
      codec = 'theora';
    } else if ((/^V_VP8/).test(decodedTrack.rawCodec)) {
      codec = 'vp8';
    } else if ((/^V_VP9/).test(decodedTrack.rawCodec)) {
      if (decodedTrack.codecPrivate) {
        const {profile, level, bitDepth, chromaSubsampling} = parseVp9Private(decodedTrack.codecPrivate);

        codec = 'vp09.';
        codec += `${padStart(profile, 2, '0')}.`;
        codec += `${padStart(level, 2, '0')}.`;
        codec += `${padStart(bitDepth, 2, '0')}.`;
        codec += `${padStart(chromaSubsampling, 2, '0')}`;

        // Video -> Colour -> Ebml name
        const matrixCoefficients = findEbml(track, [0xE0, [0x55, 0xB0], [0x55, 0xB1]])[0] || [];
        const videoFullRangeFlag = findEbml(track, [0xE0, [0x55, 0xB0], [0x55, 0xB9]])[0] || [];
        const transferCharacteristics = findEbml(track, [0xE0, [0x55, 0xB0], [0x55, 0xBA]])[0] || [];
        const colourPrimaries = findEbml(track, [0xE0, [0x55, 0xB0], [0x55, 0xBB]])[0] || [];

        // if we find any optional codec parameter specify them all.
        if (matrixCoefficients.length ||
          videoFullRangeFlag.length ||
          transferCharacteristics.length ||
          colourPrimaries.length) {
          codec += `.${padStart(colourPrimaries[0], 2, '0')}`;
          codec += `.${padStart(transferCharacteristics[0], 2, '0')}`;
          codec += `.${padStart(matrixCoefficients[0], 2, '0')}`;
          codec += `.${padStart(videoFullRangeFlag[0], 2, '0')}`;
        }

      } else {
        codec = 'vp9';
      }
    } else if ((/^V_AV1/).test(decodedTrack.rawCodec)) {
      codec = `av01.${getAv1Codec(decodedTrack.codecPrivate)}`;
    } else if ((/A_ALAC/).test(decodedTrack.rawCodec)) {
      codec = 'alac';
    } else if ((/A_MPEG\/L2/).test(decodedTrack.rawCodec)) {
      codec = 'mp2';
    } else if ((/A_MPEG\/L3/).test(decodedTrack.rawCodec)) {
      codec = 'mp3';
    } else if ((/^A_AAC/).test(decodedTrack.rawCodec)) {
      if (decodedTrack.codecPrivate) {
        codec = 'mp4a.40.' + (decodedTrack.codecPrivate[0] >>> 3).toString();
      } else {
        codec = 'mp4a.40.2';
      }
    } else if ((/^A_AC3/).test(decodedTrack.rawCodec)) {
      codec = 'ac-3';
    } else if ((/^A_PCM/).test(decodedTrack.rawCodec)) {
      codec = 'pcm';
    } else if ((/^A_MS\/ACM/).test(decodedTrack.rawCodec)) {
      codec = 'speex';
    } else if ((/^A_EAC3/).test(decodedTrack.rawCodec)) {
      codec = 'ec-3';
    } else if ((/^A_VORBIS/).test(decodedTrack.rawCodec)) {
      codec = 'vorbis';
    } else if ((/^A_FLAC/).test(decodedTrack.rawCodec)) {
      codec = 'flac';
    } else if ((/^A_OPUS/).test(decodedTrack.rawCodec)) {
      codec = 'opus';
    }

    decodedTrack.codec = codec;
    decodedTracks.push(decodedTrack);
  });

  return decodedTracks.sort((a, b) => a.number - b.number);
};

export const parseData = function(data, tracks) {
  const allBlocks = [];

  const segment = findEbml(data, [EBML_TAGS.Segment])[0];
  let timestampScale = findEbml(segment, [EBML_TAGS.SegmentInfo, EBML_TAGS.TimestampScale])[0];

  // in nanoseconds, defaults to 1ms
  if (timestampScale && timestampScale.length) {
    timestampScale = bytesToNumber(timestampScale);
  } else {
    timestampScale = 1000000;
  }

  const clusters = findEbml(segment, [EBML_TAGS.Cluster]);

  if (!tracks) {
    tracks = parseTracks(segment);
  }

  clusters.forEach(function(cluster, ci) {
    const simpleBlocks = findEbml(cluster, [EBML_TAGS.SimpleBlock]).map((b) => ({type: 'simple', data: b}));
    const blockGroups = findEbml(cluster, [EBML_TAGS.BlockGroup]).map((b) => ({type: 'group', data: b}));
    let timestamp = findEbml(cluster, [EBML_TAGS.Timestamp])[0] || 0;

    if (timestamp && timestamp.length) {
      timestamp = bytesToNumber(timestamp);
    }

    // get all blocks then sort them into the correct order
    const blocks = simpleBlocks
      .concat(blockGroups)
      .sort((a, b) => a.data.byteOffset - b.data.byteOffset);

    blocks.forEach(function(block, bi) {
      const decoded = decodeBlock(block.data, block.type, timestampScale, timestamp);

      allBlocks.push(decoded);
    });
  });

  return {tracks, blocks: allBlocks};
};
