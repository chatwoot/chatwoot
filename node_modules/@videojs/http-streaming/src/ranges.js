/**
 * ranges
 *
 * Utilities for working with TimeRanges.
 *
 */

import videojs from 'video.js';

// Fudge factor to account for TimeRanges rounding
export const TIME_FUDGE_FACTOR = 1 / 30;
// Comparisons between time values such as current time and the end of the buffered range
// can be misleading because of precision differences or when the current media has poorly
// aligned audio and video, which can cause values to be slightly off from what you would
// expect. This value is what we consider to be safe to use in such comparisons to account
// for these scenarios.
export const SAFE_TIME_DELTA = TIME_FUDGE_FACTOR * 3;

/**
 * Clamps a value to within a range
 *
 * @param {number} num - the value to clamp
 * @param {number} start - the start of the range to clamp within, inclusive
 * @param {number} end - the end of the range to clamp within, inclusive
 * @return {number}
 */
const clamp = function(num, [start, end]) {
  return Math.min(Math.max(start, num), end);
};
const filterRanges = function(timeRanges, predicate) {
  const results = [];
  let i;

  if (timeRanges && timeRanges.length) {
    // Search for ranges that match the predicate
    for (i = 0; i < timeRanges.length; i++) {
      if (predicate(timeRanges.start(i), timeRanges.end(i))) {
        results.push([timeRanges.start(i), timeRanges.end(i)]);
      }
    }
  }

  return videojs.createTimeRanges(results);
};

/**
 * Attempts to find the buffered TimeRange that contains the specified
 * time.
 *
 * @param {TimeRanges} buffered - the TimeRanges object to query
 * @param {number} time  - the time to filter on.
 * @return {TimeRanges} a new TimeRanges object
 */
export const findRange = function(buffered, time) {
  return filterRanges(buffered, function(start, end) {
    return start - SAFE_TIME_DELTA <= time &&
      end + SAFE_TIME_DELTA >= time;
  });
};

/**
 * Returns the TimeRanges that begin later than the specified time.
 *
 * @param {TimeRanges} timeRanges - the TimeRanges object to query
 * @param {number} time - the time to filter on.
 * @return {TimeRanges} a new TimeRanges object.
 */
export const findNextRange = function(timeRanges, time) {
  return filterRanges(timeRanges, function(start) {
    return start - TIME_FUDGE_FACTOR >= time;
  });
};

/**
 * Returns gaps within a list of TimeRanges
 *
 * @param {TimeRanges} buffered - the TimeRanges object
 * @return {TimeRanges} a TimeRanges object of gaps
 */
export const findGaps = function(buffered) {
  if (buffered.length < 2) {
    return videojs.createTimeRanges();
  }

  const ranges = [];

  for (let i = 1; i < buffered.length; i++) {
    const start = buffered.end(i - 1);
    const end = buffered.start(i);

    ranges.push([start, end]);
  }

  return videojs.createTimeRanges(ranges);
};

/**
 * Search for a likely end time for the segment that was just appened
 * based on the state of the `buffered` property before and after the
 * append. If we fin only one such uncommon end-point return it.
 *
 * @param {TimeRanges} original - the buffered time ranges before the update
 * @param {TimeRanges} update - the buffered time ranges after the update
 * @return {number|null} the end time added between `original` and `update`,
 * or null if one cannot be unambiguously determined.
 */
export const findSoleUncommonTimeRangesEnd = function(original, update) {
  let i;
  let start;
  let end;
  const result = [];
  const edges = [];

  // In order to qualify as a possible candidate, the end point must:
  //  1) Not have already existed in the `original` ranges
  //  2) Not result from the shrinking of a range that already existed
  //     in the `original` ranges
  //  3) Not be contained inside of a range that existed in `original`
  const overlapsCurrentEnd = function(span) {
    return (span[0] <= end && span[1] >= end);
  };

  if (original) {
    // Save all the edges in the `original` TimeRanges object
    for (i = 0; i < original.length; i++) {
      start = original.start(i);
      end = original.end(i);

      edges.push([start, end]);
    }
  }

  if (update) {
    // Save any end-points in `update` that are not in the `original`
    // TimeRanges object
    for (i = 0; i < update.length; i++) {
      start = update.start(i);
      end = update.end(i);

      if (edges.some(overlapsCurrentEnd)) {
        continue;
      }

      // at this point it must be a unique non-shrinking end edge
      result.push(end);
    }
  }

  // we err on the side of caution and return null if didn't find
  // exactly *one* differing end edge in the search above
  if (result.length !== 1) {
    return null;
  }

  return result[0];
};

/**
 * Calculate the intersection of two TimeRanges
 *
 * @param {TimeRanges} bufferA
 * @param {TimeRanges} bufferB
 * @return {TimeRanges} The interesection of `bufferA` with `bufferB`
 */
export const bufferIntersection = function(bufferA, bufferB) {
  let start = null;
  let end = null;
  let arity = 0;
  const extents = [];
  const ranges = [];

  if (!bufferA || !bufferA.length || !bufferB || !bufferB.length) {
    return videojs.createTimeRange();
  }

  // Handle the case where we have both buffers and create an
  // intersection of the two
  let count = bufferA.length;

  // A) Gather up all start and end times
  while (count--) {
    extents.push({time: bufferA.start(count), type: 'start'});
    extents.push({time: bufferA.end(count), type: 'end'});
  }
  count = bufferB.length;
  while (count--) {
    extents.push({time: bufferB.start(count), type: 'start'});
    extents.push({time: bufferB.end(count), type: 'end'});
  }
  // B) Sort them by time
  extents.sort(function(a, b) {
    return a.time - b.time;
  });

  // C) Go along one by one incrementing arity for start and decrementing
  //    arity for ends
  for (count = 0; count < extents.length; count++) {
    if (extents[count].type === 'start') {
      arity++;

      // D) If arity is ever incremented to 2 we are entering an
      //    overlapping range
      if (arity === 2) {
        start = extents[count].time;
      }
    } else if (extents[count].type === 'end') {
      arity--;

      // E) If arity is ever decremented to 1 we leaving an
      //    overlapping range
      if (arity === 1) {
        end = extents[count].time;
      }
    }

    // F) Record overlapping ranges
    if (start !== null && end !== null) {
      ranges.push([start, end]);
      start = null;
      end = null;
    }
  }

  return videojs.createTimeRanges(ranges);
};

/**
 * Calculates the percentage of `segmentRange` that overlaps the
 * `buffered` time ranges.
 *
 * @param {TimeRanges} segmentRange - the time range that the segment
 * covers adjusted according to currentTime
 * @param {TimeRanges} referenceRange - the original time range that the
 * segment covers
 * @param {number} currentTime - time in seconds where the current playback
 * is at
 * @param {TimeRanges} buffered - the currently buffered time ranges
 * @return {number} percent of the segment currently buffered
 */
const calculateBufferedPercent = function(
  adjustedRange,
  referenceRange,
  currentTime,
  buffered
) {
  const referenceDuration = referenceRange.end(0) - referenceRange.start(0);
  const adjustedDuration = adjustedRange.end(0) - adjustedRange.start(0);
  const bufferMissingFromAdjusted = referenceDuration - adjustedDuration;
  const adjustedIntersection = bufferIntersection(adjustedRange, buffered);
  const referenceIntersection = bufferIntersection(referenceRange, buffered);
  let adjustedOverlap = 0;
  let referenceOverlap = 0;

  let count = adjustedIntersection.length;

  while (count--) {
    adjustedOverlap += adjustedIntersection.end(count) -
                       adjustedIntersection.start(count);

    // If the current overlap segment starts at currentTime, then increase the
    // overlap duration so that it actually starts at the beginning of referenceRange
    // by including the difference between the two Range's durations
    // This is a work around for the way Flash has no buffer before currentTime
    // TODO: see if this is still necessary since Flash isn't included
    if (adjustedIntersection.start(count) === currentTime) {
      adjustedOverlap += bufferMissingFromAdjusted;
    }
  }

  count = referenceIntersection.length;

  while (count--) {
    referenceOverlap += referenceIntersection.end(count) -
                        referenceIntersection.start(count);
  }

  // Use whichever value is larger for the percentage-buffered since that value
  // is likely more accurate because the only way
  return Math.max(adjustedOverlap, referenceOverlap) / referenceDuration * 100;
};

/**
 * Return the amount of a range specified by the startOfSegment and segmentDuration
 * overlaps the current buffered content.
 *
 * @param {number} startOfSegment - the time where the segment begins
 * @param {number} segmentDuration - the duration of the segment in seconds
 * @param {number} currentTime - time in seconds where the current playback
 * is at
 * @param {TimeRanges} buffered - the state of the buffer
 * @return {number} percentage of the segment's time range that is
 * already in `buffered`
 */
export const getSegmentBufferedPercent = function(
  startOfSegment,
  segmentDuration,
  currentTime,
  buffered
) {
  const endOfSegment = startOfSegment + segmentDuration;

  // The entire time range of the segment
  const originalSegmentRange = videojs.createTimeRanges([[
    startOfSegment,
    endOfSegment
  ]]);

  // The adjusted segment time range that is setup such that it starts
  // no earlier than currentTime
  // Flash has no notion of a back-buffer so adjustedSegmentRange adjusts
  // for that and the function will still return 100% if a only half of a
  // segment is actually in the buffer as long as the currentTime is also
  // half-way through the segment
  const adjustedSegmentRange = videojs.createTimeRanges([[
    clamp(startOfSegment, [currentTime, endOfSegment]),
    endOfSegment
  ]]);

  // This condition happens when the currentTime is beyond the segment's
  // end time
  if (adjustedSegmentRange.start(0) === adjustedSegmentRange.end(0)) {
    return 0;
  }

  const percent = calculateBufferedPercent(
    adjustedSegmentRange,
    originalSegmentRange,
    currentTime,
    buffered
  );

  // If the segment is reported as having a zero duration, return 0%
  // since it is likely that we will need to fetch the segment
  if (isNaN(percent) || percent === Infinity || percent === -Infinity) {
    return 0;
  }

  return percent;
};

/**
 * Gets a human readable string for a TimeRange
 *
 * @param {TimeRange} range
 * @return {string} a human readable string
 */
export const printableRange = (range) => {
  const strArr = [];

  if (!range || !range.length) {
    return '';
  }

  for (let i = 0; i < range.length; i++) {
    strArr.push(range.start(i) + ' => ' + range.end(i));
  }

  return strArr.join(', ');
};

/**
 * Calculates the amount of time left in seconds until the player hits the end of the
 * buffer and causes a rebuffer
 *
 * @param {TimeRange} buffered
 *        The state of the buffer
 * @param {Numnber} currentTime
 *        The current time of the player
 * @param {number} playbackRate
 *        The current playback rate of the player. Defaults to 1.
 * @return {number}
 *         Time until the player has to start rebuffering in seconds.
 * @function timeUntilRebuffer
 */
export const timeUntilRebuffer = function(buffered, currentTime, playbackRate = 1) {
  const bufferedEnd = buffered.length ? buffered.end(buffered.length - 1) : 0;

  return (bufferedEnd - currentTime) / playbackRate;
};

/**
 * Converts a TimeRanges object into an array representation
 *
 * @param {TimeRanges} timeRanges
 * @return {Array}
 */
export const timeRangesToArray = (timeRanges) => {
  const timeRangesList = [];

  for (let i = 0; i < timeRanges.length; i++) {
    timeRangesList.push({
      start: timeRanges.start(i),
      end: timeRanges.end(i)
    });
  }

  return timeRangesList;
};

/**
 * Determines if two time range objects are different.
 *
 * @param {TimeRange} a
 *        the first time range object to check
 *
 * @param {TimeRange} b
 *        the second time range object to check
 *
 * @return {Boolean}
 *         Whether the time range objects differ
 */

export const isRangeDifferent = function(a, b) {
  // same object
  if (a === b) {
    return false;
  }

  // one or the other is undefined
  if (!a && b || (!b && a)) {
    return true;
  }

  // length is different
  if (a.length !== b.length) {
    return true;
  }

  // see if any start/end pair is different
  for (let i = 0; i < a.length; i++) {
    if (a.start(i) !== b.start(i) || a.end(i) !== b.end(i)) {
      return true;
    }
  }

  // if the length and every pair is the same
  // this is the same time range
  return false;
};

export const lastBufferedEnd = function(a) {
  if (!a || !a.length || !a.end) {
    return;
  }

  return a.end(a.length - 1);
};

/**
 * A utility function to add up the amount of time in a timeRange
 * after a specified startTime.
 * ie:[[0, 10], [20, 40], [50, 60]] with a startTime 0
 *     would return 40 as there are 40s seconds after 0 in the timeRange
 *
 * @param {TimeRange} range
 *        The range to check against
 * @param {number} startTime
 *        The time in the time range that you should start counting from
 *
 * @return {number}
 *          The number of seconds in the buffer passed the specified time.
 */
export const timeAheadOf = function(range, startTime) {
  let time = 0;

  if (!range || !range.length) {
    return time;
  }

  for (let i = 0; i < range.length; i++) {
    const start = range.start(i);
    const end = range.end(i);

    // startTime is after this range entirely
    if (startTime > end) {
      continue;
    }

    // startTime is within this range
    if (startTime > start && startTime <= end) {
      time += end - startTime;
      continue;
    }

    // startTime is before this range.
    time += end - start;
  }

  return time;
};
