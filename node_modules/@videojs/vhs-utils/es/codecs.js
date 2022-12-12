import window from 'global/window';
var regexs = {
  // to determine mime types
  mp4: /^(av0?1|avc0?[1234]|vp0?9|flac|opus|mp3|mp4a|mp4v|stpp.ttml.im1t)/,
  webm: /^(vp0?[89]|av0?1|opus|vorbis)/,
  ogg: /^(vp0?[89]|theora|flac|opus|vorbis)/,
  // to determine if a codec is audio or video
  video: /^(av0?1|avc0?[1234]|vp0?[89]|hvc1|hev1|theora|mp4v)/,
  audio: /^(mp4a|flac|vorbis|opus|ac-[34]|ec-3|alac|mp3|speex|aac)/,
  text: /^(stpp.ttml.im1t)/,
  // mux.js support regex
  muxerVideo: /^(avc0?1)/,
  muxerAudio: /^(mp4a)/,
  // match nothing as muxer does not support text right now.
  // there cannot never be a character before the start of a string
  // so this matches nothing.
  muxerText: /a^/
};
var mediaTypes = ['video', 'audio', 'text'];
var upperMediaTypes = ['Video', 'Audio', 'Text'];
/**
 * Replace the old apple-style `avc1.<dd>.<dd>` codec string with the standard
 * `avc1.<hhhhhh>`
 *
 * @param {string} codec
 *        Codec string to translate
 * @return {string}
 *         The translated codec string
 */

export var translateLegacyCodec = function translateLegacyCodec(codec) {
  if (!codec) {
    return codec;
  }

  return codec.replace(/avc1\.(\d+)\.(\d+)/i, function (orig, profile, avcLevel) {
    var profileHex = ('00' + Number(profile).toString(16)).slice(-2);
    var avcLevelHex = ('00' + Number(avcLevel).toString(16)).slice(-2);
    return 'avc1.' + profileHex + '00' + avcLevelHex;
  });
};
/**
 * Replace the old apple-style `avc1.<dd>.<dd>` codec strings with the standard
 * `avc1.<hhhhhh>`
 *
 * @param {string[]} codecs
 *        An array of codec strings to translate
 * @return {string[]}
 *         The translated array of codec strings
 */

export var translateLegacyCodecs = function translateLegacyCodecs(codecs) {
  return codecs.map(translateLegacyCodec);
};
/**
 * Replace codecs in the codec string with the old apple-style `avc1.<dd>.<dd>` to the
 * standard `avc1.<hhhhhh>`.
 *
 * @param {string} codecString
 *        The codec string
 * @return {string}
 *         The codec string with old apple-style codecs replaced
 *
 * @private
 */

export var mapLegacyAvcCodecs = function mapLegacyAvcCodecs(codecString) {
  return codecString.replace(/avc1\.(\d+)\.(\d+)/i, function (match) {
    return translateLegacyCodecs([match])[0];
  });
};
/**
 * @typedef {Object} ParsedCodecInfo
 * @property {number} codecCount
 *           Number of codecs parsed
 * @property {string} [videoCodec]
 *           Parsed video codec (if found)
 * @property {string} [videoObjectTypeIndicator]
 *           Video object type indicator (if found)
 * @property {string|null} audioProfile
 *           Audio profile
 */

/**
 * Parses a codec string to retrieve the number of codecs specified, the video codec and
 * object type indicator, and the audio profile.
 *
 * @param {string} [codecString]
 *        The codec string to parse
 * @return {ParsedCodecInfo}
 *         Parsed codec info
 */

export var parseCodecs = function parseCodecs(codecString) {
  if (codecString === void 0) {
    codecString = '';
  }

  var codecs = codecString.split(',');
  var result = [];
  codecs.forEach(function (codec) {
    codec = codec.trim();
    var codecType;
    mediaTypes.forEach(function (name) {
      var match = regexs[name].exec(codec.toLowerCase());

      if (!match || match.length <= 1) {
        return;
      }

      codecType = name; // maintain codec case

      var type = codec.substring(0, match[1].length);
      var details = codec.replace(type, '');
      result.push({
        type: type,
        details: details,
        mediaType: name
      });
    });

    if (!codecType) {
      result.push({
        type: codec,
        details: '',
        mediaType: 'unknown'
      });
    }
  });
  return result;
};
/**
 * Returns a ParsedCodecInfo object for the default alternate audio playlist if there is
 * a default alternate audio playlist for the provided audio group.
 *
 * @param {Object} master
 *        The master playlist
 * @param {string} audioGroupId
 *        ID of the audio group for which to find the default codec info
 * @return {ParsedCodecInfo}
 *         Parsed codec info
 */

export var codecsFromDefault = function codecsFromDefault(master, audioGroupId) {
  if (!master.mediaGroups.AUDIO || !audioGroupId) {
    return null;
  }

  var audioGroup = master.mediaGroups.AUDIO[audioGroupId];

  if (!audioGroup) {
    return null;
  }

  for (var name in audioGroup) {
    var audioType = audioGroup[name];

    if (audioType.default && audioType.playlists) {
      // codec should be the same for all playlists within the audio type
      return parseCodecs(audioType.playlists[0].attributes.CODECS);
    }
  }

  return null;
};
export var isVideoCodec = function isVideoCodec(codec) {
  if (codec === void 0) {
    codec = '';
  }

  return regexs.video.test(codec.trim().toLowerCase());
};
export var isAudioCodec = function isAudioCodec(codec) {
  if (codec === void 0) {
    codec = '';
  }

  return regexs.audio.test(codec.trim().toLowerCase());
};
export var isTextCodec = function isTextCodec(codec) {
  if (codec === void 0) {
    codec = '';
  }

  return regexs.text.test(codec.trim().toLowerCase());
};
export var getMimeForCodec = function getMimeForCodec(codecString) {
  if (!codecString || typeof codecString !== 'string') {
    return;
  }

  var codecs = codecString.toLowerCase().split(',').map(function (c) {
    return translateLegacyCodec(c.trim());
  }); // default to video type

  var type = 'video'; // only change to audio type if the only codec we have is
  // audio

  if (codecs.length === 1 && isAudioCodec(codecs[0])) {
    type = 'audio';
  } else if (codecs.length === 1 && isTextCodec(codecs[0])) {
    // text uses application/<container> for now
    type = 'application';
  } // default the container to mp4


  var container = 'mp4'; // every codec must be able to go into the container
  // for that container to be the correct one

  if (codecs.every(function (c) {
    return regexs.mp4.test(c);
  })) {
    container = 'mp4';
  } else if (codecs.every(function (c) {
    return regexs.webm.test(c);
  })) {
    container = 'webm';
  } else if (codecs.every(function (c) {
    return regexs.ogg.test(c);
  })) {
    container = 'ogg';
  }

  return type + "/" + container + ";codecs=\"" + codecString + "\"";
};
export var browserSupportsCodec = function browserSupportsCodec(codecString) {
  if (codecString === void 0) {
    codecString = '';
  }

  return window.MediaSource && window.MediaSource.isTypeSupported && window.MediaSource.isTypeSupported(getMimeForCodec(codecString)) || false;
};
export var muxerSupportsCodec = function muxerSupportsCodec(codecString) {
  if (codecString === void 0) {
    codecString = '';
  }

  return codecString.toLowerCase().split(',').every(function (codec) {
    codec = codec.trim(); // any match is supported.

    for (var i = 0; i < upperMediaTypes.length; i++) {
      var type = upperMediaTypes[i];

      if (regexs["muxer" + type].test(codec)) {
        return true;
      }
    }

    return false;
  });
};
export var DEFAULT_AUDIO_CODEC = 'mp4a.40.2';
export var DEFAULT_VIDEO_CODEC = 'avc1.4d400d';