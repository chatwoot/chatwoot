const MPEGURL_REGEX = /^(audio|video|application)\/(x-|vnd\.apple\.)?mpegurl/i;
const DASH_REGEX = /^application\/dash\+xml/i;

/**
 * Returns a string that describes the type of source based on a video source object's
 * media type.
 *
 * @see {@link https://dev.w3.org/html5/pf-summary/video.html#dom-source-type|Source Type}
 *
 * @param {string} type
 *        Video source object media type
 * @return {('hls'|'dash'|'vhs-json'|null)}
 *         VHS source type string
 */
export const simpleTypeFromSourceType = (type) => {
  if (MPEGURL_REGEX.test(type)) {
    return 'hls';
  }

  if (DASH_REGEX.test(type)) {
    return 'dash';
  }

  // Denotes the special case of a manifest object passed to http-streaming instead of a
  // source URL.
  //
  // See https://en.wikipedia.org/wiki/Media_type for details on specifying media types.
  //
  // In this case, vnd stands for vendor, video.js for the organization, VHS for this
  // project, and the +json suffix identifies the structure of the media type.
  if (type === 'application/vnd.videojs.vhs+json') {
    return 'vhs-json';
  }

  return null;
};
