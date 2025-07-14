import { findChildren } from './utils/xml';
import { parseAttributes } from './parseAttributes';
import errors from './errors';

/**
 * Parses the manifest for a UTCTiming node, returning the nodes attributes if found
 *
 * @param {string} mpd
 *        XML string of the MPD manifest
 * @return {Object|null}
 *         Attributes of UTCTiming node specified in the manifest. Null if none found
 */
export const parseUTCTimingScheme = (mpd) => {
  const UTCTimingNode = findChildren(mpd, 'UTCTiming')[0];

  if (!UTCTimingNode) {
    return null;
  }

  const attributes = parseAttributes(UTCTimingNode);

  switch (attributes.schemeIdUri) {
  case 'urn:mpeg:dash:utc:http-head:2014':
  case 'urn:mpeg:dash:utc:http-head:2012':
    attributes.method = 'HEAD';
    break;
  case 'urn:mpeg:dash:utc:http-xsdate:2014':
  case 'urn:mpeg:dash:utc:http-iso:2014':
  case 'urn:mpeg:dash:utc:http-xsdate:2012':
  case 'urn:mpeg:dash:utc:http-iso:2012':
    attributes.method = 'GET';
    break;
  case 'urn:mpeg:dash:utc:direct:2014':
  case 'urn:mpeg:dash:utc:direct:2012':
    attributes.method = 'DIRECT';
    attributes.value = Date.parse(attributes.value);
    break;
  case 'urn:mpeg:dash:utc:http-ntp:2014':
  case 'urn:mpeg:dash:utc:ntp:2014':
  case 'urn:mpeg:dash:utc:sntp:2014':
  default:
    throw new Error(errors.UNSUPPORTED_UTC_TIMING_SCHEME);
  }

  return attributes;
};
