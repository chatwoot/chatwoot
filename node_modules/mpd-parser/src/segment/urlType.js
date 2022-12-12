import resolveUrl from '@videojs/vhs-utils/es/resolve-url';
import window from 'global/window';

/**
 * @typedef {Object} SingleUri
 * @property {string} uri - relative location of segment
 * @property {string} resolvedUri - resolved location of segment
 * @property {Object} byterange - Object containing information on how to make byte range
 *   requests following byte-range-spec per RFC2616.
 * @property {String} byterange.length - length of range request
 * @property {String} byterange.offset - byte offset of range request
 *
 * @see https://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.35.1
 */

/**
 * Converts a URLType node (5.3.9.2.3 Table 13) to a segment object
 * that conforms to how m3u8-parser is structured
 *
 * @see https://github.com/videojs/m3u8-parser
 *
 * @param {string} baseUrl - baseUrl provided by <BaseUrl> nodes
 * @param {string} source - source url for segment
 * @param {string} range - optional range used for range calls,
 *   follows  RFC 2616, Clause 14.35.1
 * @return {SingleUri} full segment information transformed into a format similar
 *   to m3u8-parser
 */
export const urlTypeToSegment = ({ baseUrl = '', source = '', range = '', indexRange = '' }) => {
  const segment = {
    uri: source,
    resolvedUri: resolveUrl(baseUrl || '', source)
  };

  if (range || indexRange) {
    const rangeStr = range ? range : indexRange;
    const ranges = rangeStr.split('-');

    // default to parsing this as a BigInt if possible
    let startRange = window.BigInt ? window.BigInt(ranges[0]) : parseInt(ranges[0], 10);
    let endRange = window.BigInt ? window.BigInt(ranges[1]) : parseInt(ranges[1], 10);

    // convert back to a number if less than MAX_SAFE_INTEGER
    if (startRange < Number.MAX_SAFE_INTEGER && typeof startRange === 'bigint') {
      startRange = Number(startRange);
    }

    if (endRange < Number.MAX_SAFE_INTEGER && typeof endRange === 'bigint') {
      endRange = Number(endRange);
    }

    let length;

    if (typeof endRange === 'bigint' || typeof startRange === 'bigint') {
      length = window.BigInt(endRange) - window.BigInt(startRange) + window.BigInt(1);
    } else {
      length = endRange - startRange + 1;
    }

    if (typeof length === 'bigint' && length < Number.MAX_SAFE_INTEGER) {
      length = Number(length);
    }

    // byterange should be inclusive according to
    // RFC 2616, Clause 14.35.1
    segment.byterange = {
      length,
      offset: startRange
    };
  }

  return segment;
};

export const byteRangeToString = (byterange) => {
  // `endRange` is one less than `offset + length` because the HTTP range
  // header uses inclusive ranges
  let endRange;

  if (typeof byterange.offset === 'bigint' || typeof byterange.length === 'bigint') {
    endRange = window.BigInt(byterange.offset) + window.BigInt(byterange.length) - window.BigInt(1);
  } else {
    endRange = byterange.offset + byterange.length - 1;
  }

  return `${byterange.offset}-${endRange}`;
};

export default urlTypeToSegment;
