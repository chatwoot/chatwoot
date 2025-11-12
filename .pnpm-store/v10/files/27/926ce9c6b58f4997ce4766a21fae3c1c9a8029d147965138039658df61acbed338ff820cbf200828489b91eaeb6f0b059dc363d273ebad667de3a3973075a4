import { parseByTimeline } from './timelineTimeParser';
import { parseByDuration } from './durationTimeParser';
import urlTypeConverter from './urlType';
import errors from '../errors';

/**
 * Converts a <SegmentUrl> (of type URLType from the DASH spec 5.3.9.2 Table 14)
 * to an object that matches the output of a segment in videojs/mpd-parser
 *
 * @param {Object} attributes
 *   Object containing all inherited attributes from parent elements with attribute
 *   names as keys
 * @param {Object} segmentUrl
 *   <SegmentURL> node to translate into a segment object
 * @return {Object} translated segment object
 */
const SegmentURLToSegmentObject = (attributes, segmentUrl) => {
  const { baseUrl, initialization = {} } = attributes;

  const initSegment = urlTypeConverter({
    baseUrl,
    source: initialization.sourceURL,
    range: initialization.range
  });

  const segment = urlTypeConverter({
    baseUrl,
    source: segmentUrl.media,
    range: segmentUrl.mediaRange
  });

  segment.map = initSegment;

  return segment;
};

/**
 * Generates a list of segments using information provided by the SegmentList element
 * SegmentList (DASH SPEC Section 5.3.9.3.2) contains a set of <SegmentURL> nodes.  Each
 * node should be translated into segment.
 *
 * @param {Object} attributes
 *   Object containing all inherited attributes from parent elements with attribute
 *   names as keys
 * @param {Object[]|undefined} segmentTimeline
 *        List of objects representing the attributes of each S element contained within
 *        the SegmentTimeline element
 * @return {Object.<Array>} list of segments
 */
export const segmentsFromList = (attributes, segmentTimeline) => {
  const {
    duration,
    segmentUrls = [],
    periodStart
  } = attributes;

  // Per spec (5.3.9.2.1) no way to determine segment duration OR
  // if both SegmentTimeline and @duration are defined, it is outside of spec.
  if ((!duration && !segmentTimeline) ||
      (duration && segmentTimeline)) {
    throw new Error(errors.SEGMENT_TIME_UNSPECIFIED);
  }

  const segmentUrlMap = segmentUrls.map(segmentUrlObject =>
    SegmentURLToSegmentObject(attributes, segmentUrlObject));
  let segmentTimeInfo;

  if (duration) {
    segmentTimeInfo = parseByDuration(attributes);
  }

  if (segmentTimeline) {
    segmentTimeInfo = parseByTimeline(attributes, segmentTimeline);
  }

  const segments = segmentTimeInfo.map((segmentTime, index) => {
    if (segmentUrlMap[index]) {
      const segment = segmentUrlMap[index];
      // See DASH spec section 5.3.9.2.2
      // - if timescale isn't present on any level, default to 1.
      const timescale = attributes.timescale || 1;
      // - if presentationTimeOffset isn't present on any level, default to 0
      const presentationTimeOffset = attributes.presentationTimeOffset || 0;

      segment.timeline = segmentTime.timeline;
      segment.duration = segmentTime.duration;
      segment.number = segmentTime.number;
      segment.presentationTime =
        periodStart + ((segmentTime.time - presentationTimeOffset) / timescale);

      return segment;
    }
    // Since we're mapping we should get rid of any blank segments (in case
    // the given SegmentTimeline is handling for more elements than we have
    // SegmentURLs for).
  }).filter(segment => segment);

  return segments;
};
