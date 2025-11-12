import { range } from '../utils/list';

/**
 * parse the end number attribue that can be a string
 * number, or undefined.
 *
 * @param {string|number|undefined} endNumber
 *        The end number attribute.
 *
 * @return {number|null}
 *          The result of parsing the end number.
 */
const parseEndNumber = (endNumber) => {
  if (endNumber && typeof endNumber !== 'number') {
    endNumber = parseInt(endNumber, 10);
  }

  if (isNaN(endNumber)) {
    return null;
  }

  return endNumber;
};

/**
 * Functions for calculating the range of available segments in static and dynamic
 * manifests.
 */
export const segmentRange = {
  /**
   * Returns the entire range of available segments for a static MPD
   *
   * @param {Object} attributes
   *        Inheritied MPD attributes
   * @return {{ start: number, end: number }}
   *         The start and end numbers for available segments
   */
  static(attributes) {
    const {
      duration,
      timescale = 1,
      sourceDuration,
      periodDuration
    } = attributes;
    const endNumber = parseEndNumber(attributes.endNumber);
    const segmentDuration = duration / timescale;

    if (typeof endNumber === 'number') {
      return { start: 0, end: endNumber };
    }

    if (typeof periodDuration === 'number') {
      return { start: 0, end: periodDuration / segmentDuration };
    }

    return { start: 0, end: sourceDuration / segmentDuration };
  },

  /**
   * Returns the current live window range of available segments for a dynamic MPD
   *
   * @param {Object} attributes
   *        Inheritied MPD attributes
   * @return {{ start: number, end: number }}
   *         The start and end numbers for available segments
   */
  dynamic(attributes) {
    const {
      NOW,
      clientOffset,
      availabilityStartTime,
      timescale = 1,
      duration,
      periodStart = 0,
      minimumUpdatePeriod = 0,
      timeShiftBufferDepth = Infinity
    } = attributes;
    const endNumber = parseEndNumber(attributes.endNumber);
    // clientOffset is passed in at the top level of mpd-parser and is an offset calculated
    // after retrieving UTC server time.
    const now = (NOW + clientOffset) / 1000;
    // WC stands for Wall Clock.
    // Convert the period start time to EPOCH.
    const periodStartWC = availabilityStartTime + periodStart;
    // Period end in EPOCH is manifest's retrieval time + time until next update.
    const periodEndWC = now + minimumUpdatePeriod;
    const periodDuration = periodEndWC - periodStartWC;
    const segmentCount = Math.ceil(periodDuration * timescale / duration);
    const availableStart =
      Math.floor((now - periodStartWC - timeShiftBufferDepth) * timescale / duration);
    const availableEnd = Math.floor((now - periodStartWC) * timescale / duration);

    return {
      start: Math.max(0, availableStart),
      end: typeof endNumber === 'number' ? endNumber : Math.min(segmentCount, availableEnd)
    };
  }
};

/**
 * Maps a range of numbers to objects with information needed to build the corresponding
 * segment list
 *
 * @name toSegmentsCallback
 * @function
 * @param {number} number
 *        Number of the segment
 * @param {number} index
 *        Index of the number in the range list
 * @return {{ number: Number, duration: Number, timeline: Number, time: Number }}
 *         Object with segment timing and duration info
 */

/**
 * Returns a callback for Array.prototype.map for mapping a range of numbers to
 * information needed to build the segment list.
 *
 * @param {Object} attributes
 *        Inherited MPD attributes
 * @return {toSegmentsCallback}
 *         Callback map function
 */
export const toSegments = (attributes) => (number) => {
  const {
    duration,
    timescale = 1,
    periodStart,
    startNumber = 1
  } = attributes;

  return {
    number: startNumber + number,
    duration: duration / timescale,
    timeline: periodStart,
    time: number * duration
  };
};

/**
 * Returns a list of objects containing segment timing and duration info used for
 * building the list of segments. This uses the @duration attribute specified
 * in the MPD manifest to derive the range of segments.
 *
 * @param {Object} attributes
 *        Inherited MPD attributes
 * @return {{number: number, duration: number, time: number, timeline: number}[]}
 *         List of Objects with segment timing and duration info
 */
export const parseByDuration = (attributes) => {
  const {
    type,
    duration,
    timescale = 1,
    periodDuration,
    sourceDuration
  } = attributes;

  const { start, end } = segmentRange[type](attributes);
  const segments = range(start, end).map(toSegments(attributes));

  if (type === 'static') {
    const index = segments.length - 1;
    // section is either a period or the full source
    const sectionDuration =
      typeof periodDuration === 'number' ? periodDuration : sourceDuration;

    // final segment may be less than full segment duration
    segments[index].duration = sectionDuration - (duration / timescale * index);
  }

  return segments;
};
