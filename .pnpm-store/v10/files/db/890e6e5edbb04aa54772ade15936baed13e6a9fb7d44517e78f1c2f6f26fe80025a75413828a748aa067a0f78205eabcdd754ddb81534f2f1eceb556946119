import { version } from '../package.json';
import { toM3u8, generateSidxKey } from './toM3u8';
import { toPlaylists } from './toPlaylists';
import { inheritAttributes } from './inheritAttributes';
import { stringToMpdXml } from './stringToMpdXml';
import { parseUTCTimingScheme } from './parseUTCTimingScheme';
import {addSidxSegmentsToPlaylist} from './segment/segmentBase.js';

const VERSION = version;

/*
 * Given a DASH manifest string and options, parses the DASH manifest into an object in the
 * form outputed by m3u8-parser and accepted by videojs/http-streaming.
 *
 * For live DASH manifests, if `previousManifest` is provided in options, then the newly
 * parsed DASH manifest will have its media sequence and discontinuity sequence values
 * updated to reflect its position relative to the prior manifest.
 *
 * @param {string} manifestString - the DASH manifest as a string
 * @param {options} [options] - any options
 *
 * @return {Object} the manifest object
 */
const parse = (manifestString, options = {}) => {
  const parsedManifestInfo = inheritAttributes(stringToMpdXml(manifestString), options);
  const playlists = toPlaylists(parsedManifestInfo.representationInfo);

  return toM3u8({
    dashPlaylists: playlists,
    locations: parsedManifestInfo.locations,
    sidxMapping: options.sidxMapping,
    previousManifest: options.previousManifest
  });
};

/**
 * Parses the manifest for a UTCTiming node, returning the nodes attributes if found
 *
 * @param {string} manifestString
 *        XML string of the MPD manifest
 * @return {Object|null}
 *         Attributes of UTCTiming node specified in the manifest. Null if none found
 */
const parseUTCTiming = (manifestString) =>
  parseUTCTimingScheme(stringToMpdXml(manifestString));

export {
  VERSION,
  parse,
  parseUTCTiming,
  stringToMpdXml,
  inheritAttributes,
  toPlaylists,
  toM3u8,
  addSidxSegmentsToPlaylist,
  generateSidxKey
};
