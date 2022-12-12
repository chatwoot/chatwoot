import {bytesToString, toUint8, toHexString, bytesMatch} from './byte-helpers.js';
import {parseTracks as parseEbmlTracks} from './ebml-helpers.js';
import {parseTracks as parseMp4Tracks} from './mp4-helpers.js';
import {findFourCC} from './riff-helpers.js';
import {getPages} from './ogg-helpers.js';
import {detectContainerForBytes} from './containers.js';
import {findH264Nal, findH265Nal} from './nal-helpers.js';
import {parseTs} from './m2ts-helpers.js';
import {getAvcCodec, getHvcCodec} from './codec-helpers.js';
import {getId3Offset} from './id3-helpers.js';

// https://docs.microsoft.com/en-us/windows/win32/medfound/audio-subtype-guids
// https://tools.ietf.org/html/rfc2361
const wFormatTagCodec = function(wFormatTag) {
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

const formatMimetype = (name, codecs) => {
  const codecString = ['video', 'audio'].reduce((acc, type) => {
    if (codecs[type]) {
      acc += (acc.length ? ',' : '') + codecs[type];
    }

    return acc;
  }, '');

  return `${(codecs.video ? 'video' : 'audio')}/${name}${codecString ? `;codecs="${codecString}"` : ''}`;
};

const parseCodecFrom = {
  mov(bytes) {
    // mov and mp4 both use a nearly identical box structure.
    const retval = parseCodecFrom.mp4(bytes);

    if (retval.mimetype) {
      retval.mimetype = retval.mimetype.replace('mp4', 'quicktime');
    }

    return retval;
  },
  mp4(bytes) {
    bytes = toUint8(bytes);
    const codecs = {};
    const tracks = parseMp4Tracks(bytes);

    for (let i = 0; i < tracks.length; i++) {
      const track = tracks[i];

      if (track.type === 'audio' && !codecs.audio) {
        codecs.audio = track.codec;
      }

      if (track.type === 'video' && !codecs.video) {
        codecs.video = track.codec;
      }
    }

    return {codecs, mimetype: formatMimetype('mp4', codecs)};
  },
  '3gp'(bytes) {
    return {codecs: {}, mimetype: 'video/3gpp'};
  },
  ogg(bytes) {
    const pages = getPages(bytes, 0, 4);
    const codecs = {};

    pages.forEach(function(page) {
      if (bytesMatch(page, [0x4F, 0x70, 0x75, 0x73], {offset: 28})) {
        codecs.audio = 'opus';
      } else if (bytesMatch(page, [0x56, 0x50, 0x38, 0x30], {offset: 29})) {
        codecs.video = 'vp8';
      } else if (bytesMatch(page, [0x74, 0x68, 0x65, 0x6F, 0x72, 0x61], {offset: 29})) {
        codecs.video = 'theora';
      } else if (bytesMatch(page, [0x46, 0x4C, 0x41, 0x43], {offset: 29})) {
        codecs.audio = 'flac';
      } else if (bytesMatch(page, [0x53, 0x70, 0x65, 0x65, 0x78], {offset: 28})) {
        codecs.audio = 'speex';
      } else if (bytesMatch(page, [0x76, 0x6F, 0x72, 0x62, 0x69, 0x73], {offset: 29})) {
        codecs.audio = 'vorbis';
      }
    });

    return {codecs, mimetype: formatMimetype('ogg', codecs)};
  },
  wav(bytes) {
    const format = findFourCC(bytes, ['WAVE', 'fmt'])[0];
    const wFormatTag = Array.prototype.slice.call(format, 0, 2).reverse();
    let mimetype = 'audio/vnd.wave';
    const codecs = {
      audio: wFormatTagCodec(wFormatTag)
    };

    const codecString = wFormatTag.reduce(function(acc, v) {
      if (v) {
        acc += toHexString(v);
      }
      return acc;
    }, '');

    if (codecString) {
      mimetype += `;codec=${codecString}`;
    }

    if (codecString && !codecs.audio) {
      codecs.audio = codecString;
    }

    return {codecs, mimetype};
  },
  avi(bytes) {
    const movi = findFourCC(bytes, ['AVI', 'movi'])[0];
    const strls = findFourCC(bytes, ['AVI', 'hdrl', 'strl']);
    const codecs = {};

    strls.forEach(function(strl) {
      const strh = findFourCC(strl, ['strh'])[0];
      const strf = findFourCC(strl, ['strf'])[0];

      // now parse AVIStreamHeader to get codec and type:
      // https://docs.microsoft.com/en-us/previous-versions/windows/desktop/api/avifmt/ns-avifmt-avistreamheader
      const type = bytesToString(strh.subarray(0, 4));
      let codec;
      let codecType;

      if (type === 'vids') {
        // https://docs.microsoft.com/en-us/windows/win32/api/wingdi/ns-wingdi-bitmapinfoheader
        const handler = bytesToString(strh.subarray(4, 8));
        const compression = bytesToString(strf.subarray(16, 20));
        // look for 00dc (compressed video fourcc code) or 00db (uncompressed video fourcc code)
        const videoData = findFourCC(movi, ['00dc'])[0] || findFourCC(movi, ['00db'][0]);

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
            const result = detectContainerForBytes(videoData);

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
        codecType = 'audio';
        // look for 00wb (audio data fourcc)
        // const audioData = findFourCC(movi, ['01wb']);
        const wFormatTag = Array.prototype.slice.call(strf, 0, 2).reverse();

        codecs.audio = wFormatTagCodec(wFormatTag);

      } else {
        return;
      }

      if (codec) {
        codecs[codecType] = codec;
      }
    });

    return {codecs, mimetype: formatMimetype('avi', codecs)};
  },

  ts(bytes) {
    const result = parseTs(bytes);
    const codecs = {};

    Object.keys(result.streams).forEach(function(esPid) {
      const stream = result.streams[esPid];

      if (stream.codec === 'avc1' && stream.packets.length) {
        stream.codec = parseCodecFrom.h264(stream.packets[0]).codecs.video;
      } else if (stream.codec === 'hev1' && stream.packets.length) {
        stream.codec = parseCodecFrom.h265(stream.packets[0]).codecs.video;
      }

      codecs[stream.type] = stream.codec;
    });

    return {codecs, mimetype: formatMimetype('mp2t', codecs)};
  },
  webm(bytes) {
    // mkv and webm both use ebml to store code info
    const retval = parseCodecFrom.mkv(bytes);

    if (retval.mimetype) {
      retval.mimetype = retval.mimetype.replace('x-matroska', 'webm');
    }

    return retval;
  },
  mkv(bytes) {
    const codecs = {};
    const tracks = parseEbmlTracks(bytes);

    for (let i = 0; i < tracks.length; i++) {
      const track = tracks[i];

      if (track.type === 'audio' && !codecs.audio) {
        codecs.audio = track.codec;
      }

      if (track.type === 'video' && !codecs.video) {
        codecs.video = track.codec;
      }
    }

    return {codecs, mimetype: formatMimetype('x-matroska', codecs)};
  },
  aac(bytes) {
    return {codecs: {audio: 'aac'}, mimetype: 'audio/aac'};
  },
  ac3(bytes) {
    // past id3 and syncword
    const offset = getId3Offset(bytes) + 2;
    // default to ac-3
    let codec = 'ac-3';

    if (bytesMatch(bytes, [0xB8, 0xE0], {offset})) {
      codec = 'ac-3';
    // 0x01, 0x7F
    } else if (bytesMatch(bytes, [0x01, 0x7f], {offset})) {
      codec = 'ec-3';
    }
    return {codecs: {audio: codec}, mimetype: 'audio/vnd.dolby.dd-raw'};
  },
  mp3(bytes) {
    return {codecs: {audio: 'mp3'}, mimetype: 'audio/mpeg'};
  },
  flac(bytes) {
    return {codecs: {audio: 'flac'}, mimetype: 'audio/flac'};
  },
  'h264'(bytes) {
    // find seq_parameter_set_rbsp to get encoding settings for codec
    const nal = findH264Nal(bytes, 7, 3);
    const retval = {codecs: {video: 'avc1'}, mimetype: 'video/h264'};

    if (nal.length) {
      retval.codecs.video += `.${getAvcCodec(nal)}`;
    }

    return retval;
  },
  'h265'(bytes) {
    const retval = {codecs: {video: 'hev1'}, mimetype: 'video/h265'};

    // find video_parameter_set_rbsp or seq_parameter_set_rbsp
    // to get encoding settings for codec
    const nal = findH265Nal(bytes, [32, 33], 3);

    if (nal.length) {
      const type = (nal[0] >> 1) & 0x3F;

      // profile_tier_level starts at byte 5 for video_parameter_set_rbsp
      // byte 2 for seq_parameter_set_rbsp
      retval.codecs.video += `.${getHvcCodec(nal.subarray(type === 32 ? 5 : 2))}`;
    }

    return retval;
  }
};

export const parseFormatForBytes = (bytes) => {
  bytes = toUint8(bytes);
  const result = {
    codecs: {},
    container: detectContainerForBytes(bytes),
    mimetype: ''
  };

  const parseCodecFn = parseCodecFrom[result.container];

  if (parseCodecFn) {
    const parsed = parseCodecFn ? parseCodecFn(bytes) : {};

    result.codecs = parsed.codecs || {};
    result.mimetype = parsed.mimetype || '';
  }

  return result;
};

