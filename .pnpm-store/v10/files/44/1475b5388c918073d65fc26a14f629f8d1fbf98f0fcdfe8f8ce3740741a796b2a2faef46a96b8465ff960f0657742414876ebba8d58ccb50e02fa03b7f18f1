/**
 * mux.js
 *
 * Copyright (c) Brightcove
 * Licensed Apache-2.0 https://github.com/videojs/mux.js/blob/master/LICENSE
 *
 * Parse the internal MP4 structure into an equivalent javascript
 * object.
 */
'use strict';

var numberHelpers = require('../utils/numbers.js');

var MAX_UINT32 = numberHelpers.MAX_UINT32;
var getUint64 = numberHelpers.getUint64;

var inspectMp4,
    _textifyMp,
    parseMp4Date = function parseMp4Date(seconds) {
  return new Date(seconds * 1000 - 2082844800000);
},
    parseType = require('../mp4/parse-type'),
    findBox = require('../mp4/find-box'),
    nalParse = function nalParse(avcStream) {
  var avcView = new DataView(avcStream.buffer, avcStream.byteOffset, avcStream.byteLength),
      result = [],
      i,
      length;

  for (i = 0; i + 4 < avcStream.length; i += length) {
    length = avcView.getUint32(i);
    i += 4; // bail if this doesn't appear to be an H264 stream

    if (length <= 0) {
      result.push('<span style=\'color:red;\'>MALFORMED DATA</span>');
      continue;
    }

    switch (avcStream[i] & 0x1F) {
      case 0x01:
        result.push('slice_layer_without_partitioning_rbsp');
        break;

      case 0x05:
        result.push('slice_layer_without_partitioning_rbsp_idr');
        break;

      case 0x06:
        result.push('sei_rbsp');
        break;

      case 0x07:
        result.push('seq_parameter_set_rbsp');
        break;

      case 0x08:
        result.push('pic_parameter_set_rbsp');
        break;

      case 0x09:
        result.push('access_unit_delimiter_rbsp');
        break;

      default:
        result.push('UNKNOWN NAL - ' + avcStream[i] & 0x1F);
        break;
    }
  }

  return result;
},
    // registry of handlers for individual mp4 box types
parse = {
  // codingname, not a first-class box type. stsd entries share the
  // same format as real boxes so the parsing infrastructure can be
  // shared
  avc1: function avc1(data) {
    var view = new DataView(data.buffer, data.byteOffset, data.byteLength);
    return {
      dataReferenceIndex: view.getUint16(6),
      width: view.getUint16(24),
      height: view.getUint16(26),
      horizresolution: view.getUint16(28) + view.getUint16(30) / 16,
      vertresolution: view.getUint16(32) + view.getUint16(34) / 16,
      frameCount: view.getUint16(40),
      depth: view.getUint16(74),
      config: inspectMp4(data.subarray(78, data.byteLength))
    };
  },
  avcC: function avcC(data) {
    var view = new DataView(data.buffer, data.byteOffset, data.byteLength),
        result = {
      configurationVersion: data[0],
      avcProfileIndication: data[1],
      profileCompatibility: data[2],
      avcLevelIndication: data[3],
      lengthSizeMinusOne: data[4] & 0x03,
      sps: [],
      pps: []
    },
        numOfSequenceParameterSets = data[5] & 0x1f,
        numOfPictureParameterSets,
        nalSize,
        offset,
        i; // iterate past any SPSs

    offset = 6;

    for (i = 0; i < numOfSequenceParameterSets; i++) {
      nalSize = view.getUint16(offset);
      offset += 2;
      result.sps.push(new Uint8Array(data.subarray(offset, offset + nalSize)));
      offset += nalSize;
    } // iterate past any PPSs


    numOfPictureParameterSets = data[offset];
    offset++;

    for (i = 0; i < numOfPictureParameterSets; i++) {
      nalSize = view.getUint16(offset);
      offset += 2;
      result.pps.push(new Uint8Array(data.subarray(offset, offset + nalSize)));
      offset += nalSize;
    }

    return result;
  },
  btrt: function btrt(data) {
    var view = new DataView(data.buffer, data.byteOffset, data.byteLength);
    return {
      bufferSizeDB: view.getUint32(0),
      maxBitrate: view.getUint32(4),
      avgBitrate: view.getUint32(8)
    };
  },
  edts: function edts(data) {
    return {
      boxes: inspectMp4(data)
    };
  },
  elst: function elst(data) {
    var view = new DataView(data.buffer, data.byteOffset, data.byteLength),
        result = {
      version: view.getUint8(0),
      flags: new Uint8Array(data.subarray(1, 4)),
      edits: []
    },
        entryCount = view.getUint32(4),
        i;

    for (i = 8; entryCount; entryCount--) {
      if (result.version === 0) {
        result.edits.push({
          segmentDuration: view.getUint32(i),
          mediaTime: view.getInt32(i + 4),
          mediaRate: view.getUint16(i + 8) + view.getUint16(i + 10) / (256 * 256)
        });
        i += 12;
      } else {
        result.edits.push({
          segmentDuration: getUint64(data.subarray(i)),
          mediaTime: getUint64(data.subarray(i + 8)),
          mediaRate: view.getUint16(i + 16) + view.getUint16(i + 18) / (256 * 256)
        });
        i += 20;
      }
    }

    return result;
  },
  esds: function esds(data) {
    return {
      version: data[0],
      flags: new Uint8Array(data.subarray(1, 4)),
      esId: data[6] << 8 | data[7],
      streamPriority: data[8] & 0x1f,
      decoderConfig: {
        objectProfileIndication: data[11],
        streamType: data[12] >>> 2 & 0x3f,
        bufferSize: data[13] << 16 | data[14] << 8 | data[15],
        maxBitrate: data[16] << 24 | data[17] << 16 | data[18] << 8 | data[19],
        avgBitrate: data[20] << 24 | data[21] << 16 | data[22] << 8 | data[23],
        decoderConfigDescriptor: {
          tag: data[24],
          length: data[25],
          audioObjectType: data[26] >>> 3 & 0x1f,
          samplingFrequencyIndex: (data[26] & 0x07) << 1 | data[27] >>> 7 & 0x01,
          channelConfiguration: data[27] >>> 3 & 0x0f
        }
      }
    };
  },
  ftyp: function ftyp(data) {
    var view = new DataView(data.buffer, data.byteOffset, data.byteLength),
        result = {
      majorBrand: parseType(data.subarray(0, 4)),
      minorVersion: view.getUint32(4),
      compatibleBrands: []
    },
        i = 8;

    while (i < data.byteLength) {
      result.compatibleBrands.push(parseType(data.subarray(i, i + 4)));
      i += 4;
    }

    return result;
  },
  dinf: function dinf(data) {
    return {
      boxes: inspectMp4(data)
    };
  },
  dref: function dref(data) {
    return {
      version: data[0],
      flags: new Uint8Array(data.subarray(1, 4)),
      dataReferences: inspectMp4(data.subarray(8))
    };
  },
  hdlr: function hdlr(data) {
    var view = new DataView(data.buffer, data.byteOffset, data.byteLength),
        result = {
      version: view.getUint8(0),
      flags: new Uint8Array(data.subarray(1, 4)),
      handlerType: parseType(data.subarray(8, 12)),
      name: ''
    },
        i = 8; // parse out the name field

    for (i = 24; i < data.byteLength; i++) {
      if (data[i] === 0x00) {
        // the name field is null-terminated
        i++;
        break;
      }

      result.name += String.fromCharCode(data[i]);
    } // decode UTF-8 to javascript's internal representation
    // see http://ecmanaut.blogspot.com/2006/07/encoding-decoding-utf8-in-javascript.html


    result.name = decodeURIComponent(escape(result.name));
    return result;
  },
  mdat: function mdat(data) {
    return {
      byteLength: data.byteLength,
      nals: nalParse(data)
    };
  },
  mdhd: function mdhd(data) {
    var view = new DataView(data.buffer, data.byteOffset, data.byteLength),
        i = 4,
        language,
        result = {
      version: view.getUint8(0),
      flags: new Uint8Array(data.subarray(1, 4)),
      language: ''
    };

    if (result.version === 1) {
      i += 4;
      result.creationTime = parseMp4Date(view.getUint32(i)); // truncating top 4 bytes

      i += 8;
      result.modificationTime = parseMp4Date(view.getUint32(i)); // truncating top 4 bytes

      i += 4;
      result.timescale = view.getUint32(i);
      i += 8;
      result.duration = view.getUint32(i); // truncating top 4 bytes
    } else {
      result.creationTime = parseMp4Date(view.getUint32(i));
      i += 4;
      result.modificationTime = parseMp4Date(view.getUint32(i));
      i += 4;
      result.timescale = view.getUint32(i);
      i += 4;
      result.duration = view.getUint32(i);
    }

    i += 4; // language is stored as an ISO-639-2/T code in an array of three 5-bit fields
    // each field is the packed difference between its ASCII value and 0x60

    language = view.getUint16(i);
    result.language += String.fromCharCode((language >> 10) + 0x60);
    result.language += String.fromCharCode(((language & 0x03e0) >> 5) + 0x60);
    result.language += String.fromCharCode((language & 0x1f) + 0x60);
    return result;
  },
  mdia: function mdia(data) {
    return {
      boxes: inspectMp4(data)
    };
  },
  mfhd: function mfhd(data) {
    return {
      version: data[0],
      flags: new Uint8Array(data.subarray(1, 4)),
      sequenceNumber: data[4] << 24 | data[5] << 16 | data[6] << 8 | data[7]
    };
  },
  minf: function minf(data) {
    return {
      boxes: inspectMp4(data)
    };
  },
  // codingname, not a first-class box type. stsd entries share the
  // same format as real boxes so the parsing infrastructure can be
  // shared
  mp4a: function mp4a(data) {
    var view = new DataView(data.buffer, data.byteOffset, data.byteLength),
        result = {
      // 6 bytes reserved
      dataReferenceIndex: view.getUint16(6),
      // 4 + 4 bytes reserved
      channelcount: view.getUint16(16),
      samplesize: view.getUint16(18),
      // 2 bytes pre_defined
      // 2 bytes reserved
      samplerate: view.getUint16(24) + view.getUint16(26) / 65536
    }; // if there are more bytes to process, assume this is an ISO/IEC
    // 14496-14 MP4AudioSampleEntry and parse the ESDBox

    if (data.byteLength > 28) {
      result.streamDescriptor = inspectMp4(data.subarray(28))[0];
    }

    return result;
  },
  moof: function moof(data) {
    return {
      boxes: inspectMp4(data)
    };
  },
  moov: function moov(data) {
    return {
      boxes: inspectMp4(data)
    };
  },
  mvex: function mvex(data) {
    return {
      boxes: inspectMp4(data)
    };
  },
  mvhd: function mvhd(data) {
    var view = new DataView(data.buffer, data.byteOffset, data.byteLength),
        i = 4,
        result = {
      version: view.getUint8(0),
      flags: new Uint8Array(data.subarray(1, 4))
    };

    if (result.version === 1) {
      i += 4;
      result.creationTime = parseMp4Date(view.getUint32(i)); // truncating top 4 bytes

      i += 8;
      result.modificationTime = parseMp4Date(view.getUint32(i)); // truncating top 4 bytes

      i += 4;
      result.timescale = view.getUint32(i);
      i += 8;
      result.duration = view.getUint32(i); // truncating top 4 bytes
    } else {
      result.creationTime = parseMp4Date(view.getUint32(i));
      i += 4;
      result.modificationTime = parseMp4Date(view.getUint32(i));
      i += 4;
      result.timescale = view.getUint32(i);
      i += 4;
      result.duration = view.getUint32(i);
    }

    i += 4; // convert fixed-point, base 16 back to a number

    result.rate = view.getUint16(i) + view.getUint16(i + 2) / 16;
    i += 4;
    result.volume = view.getUint8(i) + view.getUint8(i + 1) / 8;
    i += 2;
    i += 2;
    i += 2 * 4;
    result.matrix = new Uint32Array(data.subarray(i, i + 9 * 4));
    i += 9 * 4;
    i += 6 * 4;
    result.nextTrackId = view.getUint32(i);
    return result;
  },
  pdin: function pdin(data) {
    var view = new DataView(data.buffer, data.byteOffset, data.byteLength);
    return {
      version: view.getUint8(0),
      flags: new Uint8Array(data.subarray(1, 4)),
      rate: view.getUint32(4),
      initialDelay: view.getUint32(8)
    };
  },
  sdtp: function sdtp(data) {
    var result = {
      version: data[0],
      flags: new Uint8Array(data.subarray(1, 4)),
      samples: []
    },
        i;

    for (i = 4; i < data.byteLength; i++) {
      result.samples.push({
        dependsOn: (data[i] & 0x30) >> 4,
        isDependedOn: (data[i] & 0x0c) >> 2,
        hasRedundancy: data[i] & 0x03
      });
    }

    return result;
  },
  sidx: require('./parse-sidx.js'),
  smhd: function smhd(data) {
    return {
      version: data[0],
      flags: new Uint8Array(data.subarray(1, 4)),
      balance: data[4] + data[5] / 256
    };
  },
  stbl: function stbl(data) {
    return {
      boxes: inspectMp4(data)
    };
  },
  ctts: function ctts(data) {
    var view = new DataView(data.buffer, data.byteOffset, data.byteLength),
        result = {
      version: view.getUint8(0),
      flags: new Uint8Array(data.subarray(1, 4)),
      compositionOffsets: []
    },
        entryCount = view.getUint32(4),
        i;

    for (i = 8; entryCount; i += 8, entryCount--) {
      result.compositionOffsets.push({
        sampleCount: view.getUint32(i),
        sampleOffset: view[result.version === 0 ? 'getUint32' : 'getInt32'](i + 4)
      });
    }

    return result;
  },
  stss: function stss(data) {
    var view = new DataView(data.buffer, data.byteOffset, data.byteLength),
        result = {
      version: view.getUint8(0),
      flags: new Uint8Array(data.subarray(1, 4)),
      syncSamples: []
    },
        entryCount = view.getUint32(4),
        i;

    for (i = 8; entryCount; i += 4, entryCount--) {
      result.syncSamples.push(view.getUint32(i));
    }

    return result;
  },
  stco: function stco(data) {
    var view = new DataView(data.buffer, data.byteOffset, data.byteLength),
        result = {
      version: data[0],
      flags: new Uint8Array(data.subarray(1, 4)),
      chunkOffsets: []
    },
        entryCount = view.getUint32(4),
        i;

    for (i = 8; entryCount; i += 4, entryCount--) {
      result.chunkOffsets.push(view.getUint32(i));
    }

    return result;
  },
  stsc: function stsc(data) {
    var view = new DataView(data.buffer, data.byteOffset, data.byteLength),
        entryCount = view.getUint32(4),
        result = {
      version: data[0],
      flags: new Uint8Array(data.subarray(1, 4)),
      sampleToChunks: []
    },
        i;

    for (i = 8; entryCount; i += 12, entryCount--) {
      result.sampleToChunks.push({
        firstChunk: view.getUint32(i),
        samplesPerChunk: view.getUint32(i + 4),
        sampleDescriptionIndex: view.getUint32(i + 8)
      });
    }

    return result;
  },
  stsd: function stsd(data) {
    return {
      version: data[0],
      flags: new Uint8Array(data.subarray(1, 4)),
      sampleDescriptions: inspectMp4(data.subarray(8))
    };
  },
  stsz: function stsz(data) {
    var view = new DataView(data.buffer, data.byteOffset, data.byteLength),
        result = {
      version: data[0],
      flags: new Uint8Array(data.subarray(1, 4)),
      sampleSize: view.getUint32(4),
      entries: []
    },
        i;

    for (i = 12; i < data.byteLength; i += 4) {
      result.entries.push(view.getUint32(i));
    }

    return result;
  },
  stts: function stts(data) {
    var view = new DataView(data.buffer, data.byteOffset, data.byteLength),
        result = {
      version: data[0],
      flags: new Uint8Array(data.subarray(1, 4)),
      timeToSamples: []
    },
        entryCount = view.getUint32(4),
        i;

    for (i = 8; entryCount; i += 8, entryCount--) {
      result.timeToSamples.push({
        sampleCount: view.getUint32(i),
        sampleDelta: view.getUint32(i + 4)
      });
    }

    return result;
  },
  styp: function styp(data) {
    return parse.ftyp(data);
  },
  tfdt: require('./parse-tfdt.js'),
  tfhd: require('./parse-tfhd.js'),
  tkhd: function tkhd(data) {
    var view = new DataView(data.buffer, data.byteOffset, data.byteLength),
        i = 4,
        result = {
      version: view.getUint8(0),
      flags: new Uint8Array(data.subarray(1, 4))
    };

    if (result.version === 1) {
      i += 4;
      result.creationTime = parseMp4Date(view.getUint32(i)); // truncating top 4 bytes

      i += 8;
      result.modificationTime = parseMp4Date(view.getUint32(i)); // truncating top 4 bytes

      i += 4;
      result.trackId = view.getUint32(i);
      i += 4;
      i += 8;
      result.duration = view.getUint32(i); // truncating top 4 bytes
    } else {
      result.creationTime = parseMp4Date(view.getUint32(i));
      i += 4;
      result.modificationTime = parseMp4Date(view.getUint32(i));
      i += 4;
      result.trackId = view.getUint32(i);
      i += 4;
      i += 4;
      result.duration = view.getUint32(i);
    }

    i += 4;
    i += 2 * 4;
    result.layer = view.getUint16(i);
    i += 2;
    result.alternateGroup = view.getUint16(i);
    i += 2; // convert fixed-point, base 16 back to a number

    result.volume = view.getUint8(i) + view.getUint8(i + 1) / 8;
    i += 2;
    i += 2;
    result.matrix = new Uint32Array(data.subarray(i, i + 9 * 4));
    i += 9 * 4;
    result.width = view.getUint16(i) + view.getUint16(i + 2) / 65536;
    i += 4;
    result.height = view.getUint16(i) + view.getUint16(i + 2) / 65536;
    return result;
  },
  traf: function traf(data) {
    return {
      boxes: inspectMp4(data)
    };
  },
  trak: function trak(data) {
    return {
      boxes: inspectMp4(data)
    };
  },
  trex: function trex(data) {
    var view = new DataView(data.buffer, data.byteOffset, data.byteLength);
    return {
      version: data[0],
      flags: new Uint8Array(data.subarray(1, 4)),
      trackId: view.getUint32(4),
      defaultSampleDescriptionIndex: view.getUint32(8),
      defaultSampleDuration: view.getUint32(12),
      defaultSampleSize: view.getUint32(16),
      sampleDependsOn: data[20] & 0x03,
      sampleIsDependedOn: (data[21] & 0xc0) >> 6,
      sampleHasRedundancy: (data[21] & 0x30) >> 4,
      samplePaddingValue: (data[21] & 0x0e) >> 1,
      sampleIsDifferenceSample: !!(data[21] & 0x01),
      sampleDegradationPriority: view.getUint16(22)
    };
  },
  trun: require('./parse-trun.js'),
  'url ': function url(data) {
    return {
      version: data[0],
      flags: new Uint8Array(data.subarray(1, 4))
    };
  },
  vmhd: function vmhd(data) {
    var view = new DataView(data.buffer, data.byteOffset, data.byteLength);
    return {
      version: data[0],
      flags: new Uint8Array(data.subarray(1, 4)),
      graphicsmode: view.getUint16(4),
      opcolor: new Uint16Array([view.getUint16(6), view.getUint16(8), view.getUint16(10)])
    };
  }
};
/**
 * Return a javascript array of box objects parsed from an ISO base
 * media file.
 * @param data {Uint8Array} the binary data of the media to be inspected
 * @return {array} a javascript array of potentially nested box objects
 */


inspectMp4 = function inspectMp4(data) {
  var i = 0,
      result = [],
      view,
      size,
      type,
      end,
      box; // Convert data from Uint8Array to ArrayBuffer, to follow Dataview API

  var ab = new ArrayBuffer(data.length);
  var v = new Uint8Array(ab);

  for (var z = 0; z < data.length; ++z) {
    v[z] = data[z];
  }

  view = new DataView(ab);

  while (i < data.byteLength) {
    // parse box data
    size = view.getUint32(i);
    type = parseType(data.subarray(i + 4, i + 8));
    end = size > 1 ? i + size : data.byteLength; // parse type-specific data

    box = (parse[type] || function (data) {
      return {
        data: data
      };
    })(data.subarray(i + 8, end));

    box.size = size;
    box.type = type; // store this box and move to the next

    result.push(box);
    i = end;
  }

  return result;
};
/**
 * Returns a textual representation of the javascript represtentation
 * of an MP4 file. You can use it as an alternative to
 * JSON.stringify() to compare inspected MP4s.
 * @param inspectedMp4 {array} the parsed array of boxes in an MP4
 * file
 * @param depth {number} (optional) the number of ancestor boxes of
 * the elements of inspectedMp4. Assumed to be zero if unspecified.
 * @return {string} a text representation of the parsed MP4
 */


_textifyMp = function textifyMp4(inspectedMp4, depth) {
  var indent;
  depth = depth || 0;
  indent = new Array(depth * 2 + 1).join(' '); // iterate over all the boxes

  return inspectedMp4.map(function (box, index) {
    // list the box type first at the current indentation level
    return indent + box.type + '\n' + // the type is already included and handle child boxes separately
    Object.keys(box).filter(function (key) {
      return key !== 'type' && key !== 'boxes'; // output all the box properties
    }).map(function (key) {
      var prefix = indent + '  ' + key + ': ',
          value = box[key]; // print out raw bytes as hexademical

      if (value instanceof Uint8Array || value instanceof Uint32Array) {
        var bytes = Array.prototype.slice.call(new Uint8Array(value.buffer, value.byteOffset, value.byteLength)).map(function (byte) {
          return ' ' + ('00' + byte.toString(16)).slice(-2);
        }).join('').match(/.{1,24}/g);

        if (!bytes) {
          return prefix + '<>';
        }

        if (bytes.length === 1) {
          return prefix + '<' + bytes.join('').slice(1) + '>';
        }

        return prefix + '<\n' + bytes.map(function (line) {
          return indent + '  ' + line;
        }).join('\n') + '\n' + indent + '  >';
      } // stringify generic objects


      return prefix + JSON.stringify(value, null, 2).split('\n').map(function (line, index) {
        if (index === 0) {
          return line;
        }

        return indent + '  ' + line;
      }).join('\n');
    }).join('\n') + ( // recursively textify the child boxes
    box.boxes ? '\n' + _textifyMp(box.boxes, depth + 1) : '');
  }).join('\n');
};

module.exports = {
  inspect: inspectMp4,
  textify: _textifyMp,
  parseType: parseType,
  findBox: findBox,
  parseTraf: parse.traf,
  parseTfdt: parse.tfdt,
  parseHdlr: parse.hdlr,
  parseTfhd: parse.tfhd,
  parseTrun: parse.trun,
  parseSidx: parse.sidx
};