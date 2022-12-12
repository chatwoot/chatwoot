/**
 * @file - codecs.js - Handles tasks regarding codec strings such as translating them to
 * codec strings, or translating codec strings into objects that can be examined.
 */

import {
  translateLegacyCodec,
  parseCodecs,
  codecsFromDefault
} from '@videojs/vhs-utils/es/codecs.js';
import logger from './logger.js';

const logFn = logger('CodecUtils');

/**
 * Returns a set of codec strings parsed from the playlist or the default
 * codec strings if no codecs were specified in the playlist
 *
 * @param {Playlist} media the current media playlist
 * @return {Object} an object with the video and audio codecs
 */
const getCodecs = function(media) {
  // if the codecs were explicitly specified, use them instead of the
  // defaults
  const mediaAttributes = media.attributes || {};

  if (mediaAttributes.CODECS) {
    return parseCodecs(mediaAttributes.CODECS);
  }
};

export const isMaat = (master, media) => {
  const mediaAttributes = media.attributes || {};

  return master && master.mediaGroups && master.mediaGroups.AUDIO &&
    mediaAttributes.AUDIO &&
    master.mediaGroups.AUDIO[mediaAttributes.AUDIO];
};

export const isMuxed = (master, media) => {
  if (!isMaat(master, media)) {
    return true;
  }

  const mediaAttributes = media.attributes || {};
  const audioGroup = master.mediaGroups.AUDIO[mediaAttributes.AUDIO];

  for (const groupId in audioGroup) {
    // If an audio group has a URI (the case for HLS, as HLS will use external playlists),
    // or there are listed playlists (the case for DASH, as the manifest will have already
    // provided all of the details necessary to generate the audio playlist, as opposed to
    // HLS' externally requested playlists), then the content is demuxed.
    if (!audioGroup[groupId].uri && !audioGroup[groupId].playlists) {
      return true;
    }
  }

  return false;
};

export const unwrapCodecList = function(codecList) {
  const codecs = {};

  codecList.forEach(({mediaType, type, details}) => {
    codecs[mediaType] = codecs[mediaType] || [];
    codecs[mediaType].push(translateLegacyCodec(`${type}${details}`));
  });

  Object.keys(codecs).forEach(function(mediaType) {
    if (codecs[mediaType].length > 1) {
      logFn(`multiple ${mediaType} codecs found as attributes: ${codecs[mediaType].join(', ')}. Setting playlist codecs to null so that we wait for mux.js to probe segments for real codecs.`);
      codecs[mediaType] = null;
      return;
    }

    codecs[mediaType] = codecs[mediaType][0];
  });

  return codecs;
};

export const codecCount = function(codecObj) {
  let count = 0;

  if (codecObj.audio) {
    count++;
  }

  if (codecObj.video) {
    count++;
  }

  return count;
};

/**
 * Calculates the codec strings for a working configuration of
 * SourceBuffers to play variant streams in a master playlist. If
 * there is no possible working configuration, an empty object will be
 * returned.
 *
 * @param master {Object} the m3u8 object for the master playlist
 * @param media {Object} the m3u8 object for the variant playlist
 * @return {Object} the codec strings.
 *
 * @private
 */
export const codecsForPlaylist = function(master, media) {
  const mediaAttributes = media.attributes || {};
  const codecInfo = unwrapCodecList(getCodecs(media) || []);

  // HLS with multiple-audio tracks must always get an audio codec.
  // Put another way, there is no way to have a video-only multiple-audio HLS!
  if (isMaat(master, media) && !codecInfo.audio) {
    if (!isMuxed(master, media)) {
      // It is possible for codecs to be specified on the audio media group playlist but
      // not on the rendition playlist. This is mostly the case for DASH, where audio and
      // video are always separate (and separately specified).
      const defaultCodecs = unwrapCodecList(codecsFromDefault(master, mediaAttributes.AUDIO) || []);

      if (defaultCodecs.audio) {
        codecInfo.audio = defaultCodecs.audio;
      }
    }
  }

  return codecInfo;
};
