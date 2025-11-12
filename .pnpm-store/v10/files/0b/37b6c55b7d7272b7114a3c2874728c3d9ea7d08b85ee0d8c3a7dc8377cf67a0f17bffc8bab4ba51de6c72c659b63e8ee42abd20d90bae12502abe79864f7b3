import { bytesToString, toUint8, toHexString, bytesMatch } from './byte-helpers.js';
import { parseTracks as parseEbmlTracks } from './ebml-helpers.js';
import { parseTracks as parseMp4Tracks } from './mp4-helpers.js';
import { findFourCC } from './riff-helpers.js';
import { getPages } from './ogg-helpers.js';
import { detectContainerForBytes } from './containers.js';
import { findH264Nal, findH265Nal } from './nal-helpers.js';
import { parseTs } from './m2ts-helpers.js';
import { getAvcCodec, getHvcCodec } from './codec-helpers.js';
import { getId3Offset } from './id3-helpers.js'; // https://docs.microsoft.com/en-us/windows/win32/medfound/audio-subtype-guids
// https://tools.ietf.org/html/rfc2361

var wFormatTagCodec = function wFormatTagCodec(wFormatTag) {
  wFormatTag = toUint8(wFormatTag);

  if (bytesMatch(wFormatTag, [0x00, 0x55])) {
    return 'mp3';
  } else if (bytesMatch(wFormatTag, [0x16, 0x00]) || bytesMatch(wFormatTag, [0x00, 0xFF])) {
    return 'aac';
  } else if (bytesMatch(wFormatTag, [0x70, 0x4f])) {
    return 'opus';
  } else if (bytesMatch(wFormatTag, [0x6C, 0x61])) {
    return 'alac';
  } else if (bytesMatch(wFormatTag, [0xF1, 0xAC])) {
    return 'flac';
  } else if (bytesMatch(wFormatTag, [0x20, 0x00])) {
    return 'ac-3';
  } else if (bytesMatch(wFormatTag, [0xFF, 0xFE])) {
    return 'ec-3';
  } else if (bytesMatch(wFormatTag, [0x00, 0x50])) {
    return 'mp2';
  } else if (bytesMatch(wFormatTag, [0x56, 0x6f])) {
    return 'vorbis';
  } else if (bytesMatch(wFormatTag, [0xA1, 0x09])) {
    return 'speex';
  }

  return '';
};

var formatMimetype = function formatMimetype(name, codecs) {
  var codecString = ['video', 'audio'].reduce(function (acc, type) {
    if (codecs[type]) {
      acc += (acc.length ? ',' : '') + codecs[type];
    }

    return acc;
  }, '');
  return (codecs.video ? 'video' : 'audio') + "/" + name + (codecString ? ";codecs=\"" + codecString + "\"" : '');
};

var parseCodecFrom = {
  mov: function mov(bytes) {
    // mov and mp4 both use a nearly identical box structure.
    var retval = parseCodecFrom.mp4(bytes);

    if (retval.mimetype) {
      retval.mimetype = retval.mimetype.replace('mp4', 'quicktime');
    }

    return retval;
  },
  mp4: function mp4(bytes) {
    bytes = toUint8(bytes);
    var codecs = {};
    var tracks = parseMp4Tracks(bytes);

    for (var i = 0; i < tracks.length; i++) {
      var track = tracks[i];

      if (track.type === 'audio' && !codecs.audio) {
        codecs.audio = track.codec;
      }

      if (track.type === 'video' && !codecs.video) {
        codecs.video = track.codec;
      }
    }

    return {
      codecs: codecs,
      mimetype: formatMimetype('mp4', codecs)
    };
  },
  '3gp': function gp(bytes) {
    return {
      codecs: {},
      mimetype: 'video/3gpp'
    };
  },
  ogg: function ogg(bytes) {
    var pages = getPages(bytes, 0, 4);
    var codecs = {};
    pages.forEach(function (page) {
      if (bytesMatch(page, [0x4F, 0x70, 0x75, 0x73], {
        offset: 28
      })) {
        codecs.audio = 'opus';
      } else if (bytesMatch(page, [0x56, 0x50, 0x38, 0x30], {
        offset: 29
      })) {
        codecs.video = 'vp8';
      } else if (bytesMatch(page, [0x74, 0x68, 0x65, 0x6F, 0x72, 0x61], {
        offset: 29
      })) {
        codecs.video = 'theora';
      } else if (bytesMatch(page, [0x46, 0x4C, 0x41, 0x43], {
        offset: 29
      })) {
        codecs.audio = 'flac';
      } else if (bytesMatch(page, [0x53, 0x70, 0x65, 0x65, 0x78], {
        offset: 28
      })) {
        codecs.audio = 'speex';
      } else if (bytesMatch(page, [0x76, 0x6F, 0x72, 0x62, 0x69, 0x73], {
        offset: 29
      })) {
        codecs.audio = 'vorbis';
      }
    });
    return {
      codecs: codecs,
      mimetype: formatMimetype('ogg', codecs)
    };
  },
  wav: function wav(bytes) {
    var format = findFourCC(bytes, ['WAVE', 'fmt'])[0];
    var wFormatTag = Array.prototype.slice.call(format, 0, 2).reverse();
    var mimetype = 'audio/vnd.wave';
    var codecs = {
      audio: wFormatTagCodec(wFormatTag)
    };
    var codecString = wFormatTag.reduce(function (acc, v) {
      if (v) {
        acc += toHexString(v);
      }

      return acc;
    }, '');

    if (codecString) {
      mimetype += ";codec=" + codecString;
    }

    if (codecString && !codecs.audio) {
      codecs.audio = codecString;
    }

    return {
      codecs: codecs,
      mimetype: mimetype
    };
  },
  avi: function avi(bytes) {
    var movi = findFourCC(bytes, ['AVI', 'movi'])[0];
    var strls = findFourCC(bytes, ['AVI', 'hdrl', 'strl']);
    var codecs = {};
    strls.forEach(function (strl) {
      var strh = findFourCC(strl, ['strh'])[0];
      var strf = findFourCC(strl, ['strf'])[0]; // now parse AVIStreamHeader to get codec and type:
      // https://docs.microsoft.com/en-us/previous-versions/windows/desktop/api/avifmt/ns-avifmt-avistreamheader

      var type = bytesToString(strh.subarray(0, 4));
      var codec;
      var codecType;

      if (type === 'vids') {
        // https://docs.microsoft.com/en-us/windows/win32/api/wingdi/ns-wingdi-bitmapinfoheader
        var handler = bytesToString(strh.subarray(4, 8));
        var compression = bytesToString(strf.subarray(16, 20)); // look for 00dc (compressed video fourcc code) or 00db (uncompressed video fourcc code)

        var videoData = findFourCC(movi, ['00dc'])[0] || findFourCC(movi, ['00db'][0]);

        if (handler === 'H264' || compression === 'H264') {
          if (videoData && videoData.length) {
            codec = parseCodecFrom.h264(videoData).codecs.video;
          } else {
            codec = 'avc1';
          }
        } else if (handler === 'HEVC' || compression === 'HEVC') {
          if (videoData && videoData.length) {
            codec = parseCodecFrom.h265(videoData).codecs.video;
          } else {
            codec = 'hev1';
          }
        } else if (handler === 'FMP4' || compression === 'FMP4') {
          if (movi.length) {
            codec = 'mp4v.20.' + movi[12].toString();
          } else {
            codec = 'mp4v.20';
          }
        } else if (handler === 'VP80' || compression === 'VP80') {
          codec = 'vp8';
        } else if (handler === 'VP90' || compression === 'VP90') {
          codec = 'vp9';
        } else if (handler === 'AV01' || compression === 'AV01') {
          codec = 'av01';
        } else if (handler === 'theo' || compression === 'theora') {
          codec = 'theora';
        } else {
          if (videoData && videoData.length) {
            var result = detectContainerForBytes(videoData);

            if (result === 'h264') {
              codec = parseCodecFrom.h264(movi).codecs.video;
            }

            if (result === 'h265') {
              codec = parseCodecFrom.h265(movi).codecs.video;
            }
          }

          if (!codec) {
            codec = handler || compression;
          }
        }

        codecType = 'video';
      } else if (type === 'auds') {
        codecType = 'audio'; // look for 00wb (audio data fourcc)
        // const audioData = findFourCC(movi, ['01wb']);

        var wFormatTag = Array.prototype.slice.call(strf, 0, 2).reverse();
        codecs.audio = wFormatTagCodec(wFormatTag);
      } else {
        return;
      }

      if (codec) {
        codecs[codecType] = codec;
      }
    });
    return {
      codecs: codecs,
      mimetype: formatMimetype('avi', codecs)
    };
  },
  ts: function ts(bytes) {
    var result = parseTs(bytes);
    var codecs = {};
    Object.keys(result.streams).forEach(function (esPid) {
      var stream = result.streams[esPid];

      if (stream.codec === 'avc1' && stream.packets.length) {
        stream.codec = parseCodecFrom.h264(stream.packets[0]).codecs.video;
      } else if (stream.codec === 'hev1' && stream.packets.length) {
        stream.codec = parseCodecFrom.h265(stream.packets[0]).codecs.video;
      }

      codecs[stream.type] = stream.codec;
    });
    return {
      codecs: codecs,
      mimetype: formatMimetype('mp2t', codecs)
    };
  },
  webm: function webm(bytes) {
    // mkv and webm both use ebml to store code info
    var retval = parseCodecFrom.mkv(bytes);

    if (retval.mimetype) {
      retval.mimetype = retval.mimetype.replace('x-matroska', 'webm');
    }

    return retval;
  },
  mkv: function mkv(bytes) {
    var codecs = {};
    var tracks = parseEbmlTracks(bytes);

    for (var i = 0; i < tracks.length; i++) {
      var track = tracks[i];

      if (track.type === 'audio' && !codecs.audio) {
        codecs.audio = track.codec;
      }

      if (track.type === 'video' && !codecs.video) {
        codecs.video = track.codec;
      }
    }

    return {
      codecs: codecs,
      mimetype: formatMimetype('x-matroska', codecs)
    };
  },
  aac: function aac(bytes) {
    return {
      codecs: {
        audio: 'aac'
      },
      mimetype: 'audio/aac'
    };
  },
  ac3: function ac3(bytes) {
    // past id3 and syncword
    var offset = getId3Offset(bytes) + 2; // default to ac-3

    var codec = 'ac-3';

    if (bytesMatch(bytes, [0xB8, 0xE0], {
      offset: offset
    })) {
      codec = 'ac-3'; // 0x01, 0x7F
    } else if (bytesMatch(bytes, [0x01, 0x7f], {
      offset: offset
    })) {
      codec = 'ec-3';
    }

    return {
      codecs: {
        audio: codec
      },
      mimetype: 'audio/vnd.dolby.dd-raw'
    };
  },
  mp3: function mp3(bytes) {
    return {
      codecs: {
        audio: 'mp3'
      },
      mimetype: 'audio/mpeg'
    };
  },
  flac: function flac(bytes) {
    return {
      codecs: {
        audio: 'flac'
      },
      mimetype: 'audio/flac'
    };
  },
  'h264': function h264(bytes) {
    // find seq_parameter_set_rbsp to get encoding settings for codec
    var nal = findH264Nal(bytes, 7, 3);
    var retval = {
      codecs: {
        video: 'avc1'
      },
      mimetype: 'video/h264'
    };

    if (nal.length) {
      retval.codecs.video += "." + getAvcCodec(nal);
    }

    return retval;
  },
  'h265': function h265(bytes) {
    var retval = {
      codecs: {
        video: 'hev1'
      },
      mimetype: 'video/h265'
    }; // find video_parameter_set_rbsp or seq_parameter_set_rbsp
    // to get encoding settings for codec

    var nal = findH265Nal(bytes, [32, 33], 3);

    if (nal.length) {
      var type = nal[0] >> 1 & 0x3F; // profile_tier_level starts at byte 5 for video_parameter_set_rbsp
      // byte 2 for seq_parameter_set_rbsp

      retval.codecs.video += "." + getHvcCodec(nal.subarray(type === 32 ? 5 : 2));
    }

    return retval;
  }
};
export var parseFormatForBytes = function parseFormatForBytes(bytes) {
  bytes = toUint8(bytes);
  var result = {
    codecs: {},
    container: detectContainerForBytes(bytes),
    mimetype: ''
  };
  var parseCodecFn = parseCodecFrom[result.container];

  if (parseCodecFn) {
    var parsed = parseCodecFn ? parseCodecFn(bytes) : {};
    result.codecs = parsed.codecs || {};
    result.mimetype = parsed.mimetype || '';
  }

  return result;
};