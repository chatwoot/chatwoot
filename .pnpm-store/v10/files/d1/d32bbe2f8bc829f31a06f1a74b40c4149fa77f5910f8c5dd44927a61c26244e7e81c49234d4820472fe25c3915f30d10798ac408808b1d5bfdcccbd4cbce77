/**
 * Calculates the R (repetition) value for a live stream (for the final segment
 * in a manifest where the r value is negative 1)
 *
 * @param {Object} attributes
 *        Object containing all inherited attributes from parent elements with attribute
 *        names as keys
 * @param {number} time
 *        current time (typically the total time up until the final segment)
 * @param {number} duration
 *        duration property for the given <S />
 *
 * @return {number}
 *        R value to reach the end of the given period
 */
const getLiveRValue = (attributes, time, duration) => {
  const {
    NOW,
    clientOffset,
    availabilityStartTime,
    timescale = 1,
    periodStart = 0,
    minimumUpdatePeriod = 0
  } = attributes;
  const now = (NOW + clientOffset) / 1000;
  const periodStartWC = availabilityStartTime + periodStart;
  const periodEndWC = now + minimumUpdatePeriod;
  const periodDuration = periodEndWC - periodStartWC;

  return Math.ceil(((periodDuration * timescale) - time) / duration);
};

/**
 * Uses information provided by SegmentTemplate.SegmentTimeline to determine segment
 * timing and duration
 *
 * @param {Object} attributes
 *        Object containing all inherited attributes from parent elements with attribute
 *        names as keys
 * @param {Object[]} segmentTimeline
 *        List of objects representing the attributes of each S element contained within
 *
 * @return {{number: number, duration: number, time: number, timeline: number}[]}
 *         List of Objects with segment timing and duration info
 */
export const parseByTimeline = (attributes, segmentTimeline) => {
  const {
    type,
    minimumUpdatePeriod = 0,
    media = '',
    sourceDuration,
    timescale = 1,
    startNumber = 1,
    periodStart: timeline
  } = attributes;
  const segments = [];
  let time = -1;

  for (let sIndex = 0; sIndex < segmentTimeline.length; sIndex++) {
    const S = segmentTimeline[sIndex];
    const duration = S.d;
    const repeat = S.r || 0;
    const segmentTime = S.t || 0;

    if (time < 0) {
      // first segment
      time = segmentTime;
    }

    if (segmentTime && segmentTime > time) {
      // discontinuity

      // TODO: How to handle this type of discontinuity
      // timeline++ here would treat it like HLS discontuity and content would
      // get appended without gap
      // E.G.
      //  <S t="0" d="1" />
      //  <S d="1" />
      //  <S d="1" />
      //  <S t="5" d="1" />
      // would have $Time$ values of [0, 1, 2, 5]
      // should this be appened at time positions [0, 1, 2, 3],(#EXT-X-DISCONTINUITY)
      // or [0, 1, 2, gap, gap, 5]? (#EXT-X-GAP)
      // does the value of sourceDuration consider this when calculating arbitrary
      // negative @r repeat value?
      // E.G. Same elements as above with this added at the end
      //  <S d="1" r="-1" />
      //  with a sourceDuration of 10
      // Would the 2 gaps be included in the time duration calculations resulting in
      // 8 segments with $Time$ values of [0, 1, 2, 5, 6, 7, 8, 9] or 10 segments
      // with $Time$ values of [0, 1, 2, 5, 6, 7, 8, 9, 10, 11] ?

      time = segmentTime;
    }

    let count;

    if (repeat < 0) {
      const nextS = sIndex + 1;

      if (nextS === segmentTimeline.length) {
        // last segment
        if (type === 'dynamic' &&
            minimumUpdatePeriod > 0 &&
            media.indexOf('$Number$') > 0) {
          count = getLiveRValue(attributes, time, duration);
        } else {
          // TODO: This may be incorrect depending on conclusion of TODO above
          count = ((sourceDuration * timescale) - time) / duration;
        }
      } else {
        count = (segmentTimeline[nextS].t - time) / duration;
      }
    } else {
      count = repeat + 1;
    }

    const end = startNumber + segments.length + count;
    let number = startNumber + segments.length;

    while (number < end) {
      segments.push({ number, duration: duration / timescale, time, timeline });
      time += duration;
      number++;
    }
  }

  return segments;
};
