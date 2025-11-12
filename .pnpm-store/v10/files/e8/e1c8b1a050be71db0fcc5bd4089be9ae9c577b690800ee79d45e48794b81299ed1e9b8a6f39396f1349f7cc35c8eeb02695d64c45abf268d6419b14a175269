/**
 * @file playlist.js
 *
 * Playlist related utilities.
 */
import videojs from 'video.js';
import window from 'global/window';
import {isAudioCodec} from '@videojs/vhs-utils/es/codecs.js';
import {TIME_FUDGE_FACTOR} from './ranges.js';

const {createTimeRange} = videojs;

/**
 * Get the duration of a segment, with special cases for
 * llhls segments that do not have a duration yet.
 *
 * @param {Object} playlist
 *        the playlist that the segment belongs to.
 * @param {Object} segment
 *        the segment to get a duration for.
 *
 * @return {number}
 *          the segment duration
 */
export const segmentDurationWithParts = (playlist, segment) => {
  // if this isn't a preload segment
  // then we will have a segment duration that is accurate.
  if (!segment.preload) {
    return segment.duration;
  }

  // otherwise we have to add up parts and preload hints
  // to get an up to date duration.
  let result = 0;

  (segment.parts || []).forEach(function(p) {
    result += p.duration;
  });

  // for preload hints we have to use partTargetDuration
  // as they won't even have a duration yet.
  (segment.preloadHints || []).forEach(function(p) {
    if (p.type === 'PART') {
      result += playlist.partTargetDuration;
    }
  });

  return result;
};
/**
 * A function to get a combined list of parts and segments with durations
 * and indexes.
 *
 * @param {Playlist} playlist the playlist to get the list for.
 *
 * @return {Array} The part/segment list.
 */
export const getPartsAndSegments = (playlist) => (playlist.segments || []).reduce((acc, segment, si) => {
  if (segment.parts) {
    segment.parts.forEach(function(part, pi) {
      acc.push({duration: part.duration, segmentIndex: si, partIndex: pi, part, segment});
    });
  } else {
    acc.push({duration: segment.duration, segmentIndex: si, partIndex: null, segment, part: null});
  }
  return acc;
}, []);

export const getLastParts = (media) => {
  const lastSegment = media.segments && media.segments.length && media.segments[media.segments.length - 1];

  return lastSegment && lastSegment.parts || [];
};

export const getKnownPartCount = ({preloadSegment}) => {
  if (!preloadSegment) {
    return;
  }
  const {parts, preloadHints} = preloadSegment;
  let partCount = (preloadHints || [])
    .reduce((count, hint) => count + (hint.type === 'PART' ? 1 : 0), 0);

  partCount += (parts && parts.length) ? parts.length : 0;

  return partCount;
};
/**
 * Get the number of seconds to delay from the end of a
 * live playlist.
 *
 * @param {Playlist} master the master playlist
 * @param {Playlist} media the media playlist
 * @return {number} the hold back in seconds.
 */
export const liveEdgeDelay = (master, media) => {
  if (media.endList) {
    return 0;
  }

  // dash suggestedPresentationDelay trumps everything
  if (master && master.suggestedPresentationDelay) {
    return master.suggestedPresentationDelay;
  }

  const hasParts = getLastParts(media).length > 0;

  // look for "part" delays from ll-hls first
  if (hasParts && media.serverControl && media.serverControl.partHoldBack) {
    return media.serverControl.partHoldBack;
  } else if (hasParts && media.partTargetDuration) {
    return media.partTargetDuration * 3;

  // finally look for full segment delays
  } else if (media.serverControl && media.serverControl.holdBack) {
    return media.serverControl.holdBack;
  } else if (media.targetDuration) {
    return media.targetDuration * 3;
  }

  return 0;
};

/**
 * walk backward until we find a duration we can use
 * or return a failure
 *
 * @param {Playlist} playlist the playlist to walk through
 * @param {Number} endSequence the mediaSequence to stop walking on
 */

const backwardDuration = function(playlist, endSequence) {
  let result = 0;
  let i = endSequence - playlist.mediaSequence;
  // if a start time is available for segment immediately following
  // the interval, use it
  let segment = playlist.segments[i];

  // Walk backward until we find the latest segment with timeline
  // information that is earlier than endSequence
  if (segment) {
    if (typeof segment.start !== 'undefined') {
      return { result: segment.start, precise: true };
    }
    if (typeof segment.end !== 'undefined') {
      return {
        result: segment.end - segment.duration,
        precise: true
      };
    }
  }
  while (i--) {
    segment = playlist.segments[i];
    if (typeof segment.end !== 'undefined') {
      return { result: result + segment.end, precise: true };
    }

    result += segmentDurationWithParts(playlist, segment);

    if (typeof segment.start !== 'undefined') {
      return { result: result + segment.start, precise: true };
    }
  }
  return { result, precise: false };
};

/**
 * walk forward until we find a duration we can use
 * or return a failure
 *
 * @param {Playlist} playlist the playlist to walk through
 * @param {number} endSequence the mediaSequence to stop walking on
 */
const forwardDuration = function(playlist, endSequence) {
  let result = 0;
  let segment;
  let i = endSequence - playlist.mediaSequence;
  // Walk forward until we find the earliest segment with timeline
  // information

  for (; i < playlist.segments.length; i++) {
    segment = playlist.segments[i];
    if (typeof segment.start !== 'undefined') {
      return {
        result: segment.start - result,
        precise: true
      };
    }

    result += segmentDurationWithParts(playlist, segment);

    if (typeof segment.end !== 'undefined') {
      return {
        result: segment.end - result,
        precise: true
      };
    }

  }
  // indicate we didn't find a useful duration estimate
  return { result: -1, precise: false };
};

/**
  * Calculate the media duration from the segments associated with a
  * playlist. The duration of a subinterval of the available segments
  * may be calculated by specifying an end index.
  *
  * @param {Object} playlist a media playlist object
  * @param {number=} endSequence an exclusive upper boundary
  * for the playlist.  Defaults to playlist length.
  * @param {number} expired the amount of time that has dropped
  * off the front of the playlist in a live scenario
  * @return {number} the duration between the first available segment
  * and end index.
  */
const intervalDuration = function(playlist, endSequence, expired) {
  if (typeof endSequence === 'undefined') {
    endSequence = playlist.mediaSequence + playlist.segments.length;
  }

  if (endSequence < playlist.mediaSequence) {
    return 0;
  }

  // do a backward walk to estimate the duration
  const backward = backwardDuration(playlist, endSequence);

  if (backward.precise) {
    // if we were able to base our duration estimate on timing
    // information provided directly from the Media Source, return
    // it
    return backward.result;
  }

  // walk forward to see if a precise duration estimate can be made
  // that way
  const forward = forwardDuration(playlist, endSequence);

  if (forward.precise) {
    // we found a segment that has been buffered and so it's
    // position is known precisely
    return forward.result;
  }

  // return the less-precise, playlist-based duration estimate
  return backward.result + expired;
};

/**
  * Calculates the duration of a playlist. If a start and end index
  * are specified, the duration will be for the subset of the media
  * timeline between those two indices. The total duration for live
  * playlists is always Infinity.
  *
  * @param {Object} playlist a media playlist object
  * @param {number=} endSequence an exclusive upper
  * boundary for the playlist. Defaults to the playlist media
  * sequence number plus its length.
  * @param {number=} expired the amount of time that has
  * dropped off the front of the playlist in a live scenario
  * @return {number} the duration between the start index and end
  * index.
  */
export const duration = function(playlist, endSequence, expired) {
  if (!playlist) {
    return 0;
  }

  if (typeof expired !== 'number') {
    expired = 0;
  }

  // if a slice of the total duration is not requested, use
  // playlist-level duration indicators when they're present
  if (typeof endSequence === 'undefined') {
    // if present, use the duration specified in the playlist
    if (playlist.totalDuration) {
      return playlist.totalDuration;
    }

    // duration should be Infinity for live playlists
    if (!playlist.endList) {
      return window.Infinity;
    }
  }

  // calculate the total duration based on the segment durations
  return intervalDuration(
    playlist,
    endSequence,
    expired
  );
};

/**
  * Calculate the time between two indexes in the current playlist
  * neight the start- nor the end-index need to be within the current
  * playlist in which case, the targetDuration of the playlist is used
  * to approximate the durations of the segments
  *
  * @param {Array} options.durationList list to iterate over for durations.
  * @param {number} options.defaultDuration duration to use for elements before or after the durationList
  * @param {number} options.startIndex partsAndSegments index to start
  * @param {number} options.endIndex partsAndSegments index to end.
  * @return {number} the number of seconds between startIndex and endIndex
  */
export const sumDurations = function({defaultDuration, durationList, startIndex, endIndex}) {
  let durations = 0;

  if (startIndex > endIndex) {
    [startIndex, endIndex] = [endIndex, startIndex];
  }

  if (startIndex < 0) {
    for (let i = startIndex; i < Math.min(0, endIndex); i++) {
      durations += defaultDuration;
    }
    startIndex = 0;
  }

  for (let i = startIndex; i < endIndex; i++) {
    durations += durationList[i].duration;
  }

  return durations;
};

/**
 * Calculates the playlist end time
 *
 * @param {Object} playlist a media playlist object
 * @param {number=} expired the amount of time that has
 *                  dropped off the front of the playlist in a live scenario
 * @param {boolean|false} useSafeLiveEnd a boolean value indicating whether or not the
 *                        playlist end calculation should consider the safe live end
 *                        (truncate the playlist end by three segments). This is normally
 *                        used for calculating the end of the playlist's seekable range.
 *                        This takes into account the value of liveEdgePadding.
 *                        Setting liveEdgePadding to 0 is equivalent to setting this to false.
 * @param {number} liveEdgePadding a number indicating how far from the end of the playlist we should be in seconds.
 *                 If this is provided, it is used in the safe live end calculation.
 *                 Setting useSafeLiveEnd=false or liveEdgePadding=0 are equivalent.
 *                 Corresponds to suggestedPresentationDelay in DASH manifests.
 * @return {number} the end time of playlist
 * @function playlistEnd
 */
export const playlistEnd = function(playlist, expired, useSafeLiveEnd, liveEdgePadding) {
  if (!playlist || !playlist.segments) {
    return null;
  }
  if (playlist.endList) {
    return duration(playlist);
  }

  if (expired === null) {
    return null;
  }

  expired = expired || 0;

  let lastSegmentEndTime = intervalDuration(
    playlist,
    playlist.mediaSequence + playlist.segments.length,
    expired
  );

  if (useSafeLiveEnd) {
    liveEdgePadding = typeof liveEdgePadding === 'number' ? liveEdgePadding : liveEdgeDelay(null, playlist);
    lastSegmentEndTime -= liveEdgePadding;
  }

  // don't return a time less than zero
  return Math.max(0, lastSegmentEndTime);
};

/**
  * Calculates the interval of time that is currently seekable in a
  * playlist. The returned time ranges are relative to the earliest
  * moment in the specified playlist that is still available. A full
  * seekable implementation for live streams would need to offset
  * these values by the duration of content that has expired from the
  * stream.
  *
  * @param {Object} playlist a media playlist object
  * dropped off the front of the playlist in a live scenario
  * @param {number=} expired the amount of time that has
  * dropped off the front of the playlist in a live scenario
  * @param {number} liveEdgePadding how far from the end of the playlist we should be in seconds.
  *        Corresponds to suggestedPresentationDelay in DASH manifests.
  * @return {TimeRanges} the periods of time that are valid targets
  * for seeking
  */
export const seekable = function(playlist, expired, liveEdgePadding) {
  const useSafeLiveEnd = true;
  const seekableStart = expired || 0;
  const seekableEnd = playlistEnd(playlist, expired, useSafeLiveEnd, liveEdgePadding);

  if (seekableEnd === null) {
    return createTimeRange();
  }
  return createTimeRange(seekableStart, seekableEnd);
};

/**
 * Determine the index and estimated starting time of the segment that
 * contains a specified playback position in a media playlist.
 *
 * @param {Object} options.playlist the media playlist to query
 * @param {number} options.currentTime The number of seconds since the earliest
 * possible position to determine the containing segment for
 * @param {number} options.startTime the time when the segment/part starts
 * @param {number} options.startingSegmentIndex the segment index to start looking at.
 * @param {number?} [options.startingPartIndex] the part index to look at within the segment.
 *
 * @return {Object} an object with partIndex, segmentIndex, and startTime.
 */
export const getMediaInfoForTime = function({
  playlist,
  currentTime,
  startingSegmentIndex,
  startingPartIndex,
  startTime,
  experimentalExactManifestTimings
}) {

  let time = currentTime - startTime;
  const partsAndSegments = getPartsAndSegments(playlist);

  let startIndex = 0;

  for (let i = 0; i < partsAndSegments.length; i++) {
    const partAndSegment = partsAndSegments[i];

    if (startingSegmentIndex !== partAndSegment.segmentIndex) {
      continue;
    }

    // skip this if part index does not match.
    if (typeof startingPartIndex === 'number' && typeof partAndSegment.partIndex === 'number' && startingPartIndex !== partAndSegment.partIndex) {
      continue;
    }

    startIndex = i;
    break;
  }

  if (time < 0) {
    // Walk backward from startIndex in the playlist, adding durations
    // until we find a segment that contains `time` and return it
    if (startIndex > 0) {
      for (let i = startIndex - 1; i >= 0; i--) {
        const partAndSegment = partsAndSegments[i];

        time += partAndSegment.duration;

        if (experimentalExactManifestTimings) {
          if (time < 0) {
            continue;
          }
        } else if ((time + TIME_FUDGE_FACTOR) <= 0) {
          continue;
        }
        return {
          partIndex: partAndSegment.partIndex,
          segmentIndex: partAndSegment.segmentIndex,
          startTime: startTime - sumDurations({
            defaultDuration: playlist.targetDuration,
            durationList: partsAndSegments,
            startIndex,
            endIndex: i
          })
        };
      }
    }

    // We were unable to find a good segment within the playlist
    // so select the first segment
    return {
      partIndex: partsAndSegments[0] && partsAndSegments[0].partIndex || null,
      segmentIndex: partsAndSegments[0] && partsAndSegments[0].segmentIndex || 0,
      startTime: currentTime
    };
  }

  // When startIndex is negative, we first walk forward to first segment
  // adding target durations. If we "run out of time" before getting to
  // the first segment, return the first segment
  if (startIndex < 0) {
    for (let i = startIndex; i < 0; i++) {
      time -= playlist.targetDuration;

      if (time < 0) {
        return {
          partIndex: partsAndSegments[0] && partsAndSegments[0].partIndex || null,
          segmentIndex: partsAndSegments[0] && partsAndSegments[0].segmentIndex || 0,
          startTime: currentTime
        };
      }
    }
    startIndex = 0;
  }

  // Walk forward from startIndex in the playlist, subtracting durations
  // until we find a segment that contains `time` and return it
  for (let i = startIndex; i < partsAndSegments.length; i++) {
    const partAndSegment = partsAndSegments[i];

    time -= partAndSegment.duration;

    if (experimentalExactManifestTimings) {
      if (time > 0) {
        continue;
      }
    } else if ((time - TIME_FUDGE_FACTOR) >= 0) {
      continue;
    }

    return {
      partIndex: partAndSegment.partIndex,
      segmentIndex: partAndSegment.segmentIndex,
      startTime: startTime + sumDurations({
        defaultDuration: playlist.targetDuration,
        durationList: partsAndSegments,
        startIndex,
        endIndex: i
      })
    };
  }

  // We are out of possible candidates so load the last one...
  return {
    segmentIndex: partsAndSegments[partsAndSegments.length - 1].segmentIndex,
    partIndex: partsAndSegments[partsAndSegments.length - 1].partIndex,
    startTime: currentTime
  };
};

/**
 * Check whether the playlist is blacklisted or not.
 *
 * @param {Object} playlist the media playlist object
 * @return {boolean} whether the playlist is blacklisted or not
 * @function isBlacklisted
 */
export const isBlacklisted = function(playlist) {
  return playlist.excludeUntil && playlist.excludeUntil > Date.now();
};

/**
 * Check whether the playlist is compatible with current playback configuration or has
 * been blacklisted permanently for being incompatible.
 *
 * @param {Object} playlist the media playlist object
 * @return {boolean} whether the playlist is incompatible or not
 * @function isIncompatible
 */
export const isIncompatible = function(playlist) {
  return playlist.excludeUntil && playlist.excludeUntil === Infinity;
};

/**
 * Check whether the playlist is enabled or not.
 *
 * @param {Object} playlist the media playlist object
 * @return {boolean} whether the playlist is enabled or not
 * @function isEnabled
 */
export const isEnabled = function(playlist) {
  const blacklisted = isBlacklisted(playlist);

  return (!playlist.disabled && !blacklisted);
};

/**
 * Check whether the playlist has been manually disabled through the representations api.
 *
 * @param {Object} playlist the media playlist object
 * @return {boolean} whether the playlist is disabled manually or not
 * @function isDisabled
 */
export const isDisabled = function(playlist) {
  return playlist.disabled;
};

/**
 * Returns whether the current playlist is an AES encrypted HLS stream
 *
 * @return {boolean} true if it's an AES encrypted HLS stream
 */
export const isAes = function(media) {
  for (let i = 0; i < media.segments.length; i++) {
    if (media.segments[i].key) {
      return true;
    }
  }
  return false;
};

/**
 * Checks if the playlist has a value for the specified attribute
 *
 * @param {string} attr
 *        Attribute to check for
 * @param {Object} playlist
 *        The media playlist object
 * @return {boolean}
 *         Whether the playlist contains a value for the attribute or not
 * @function hasAttribute
 */
export const hasAttribute = function(attr, playlist) {
  return playlist.attributes && playlist.attributes[attr];
};

/**
 * Estimates the time required to complete a segment download from the specified playlist
 *
 * @param {number} segmentDuration
 *        Duration of requested segment
 * @param {number} bandwidth
 *        Current measured bandwidth of the player
 * @param {Object} playlist
 *        The media playlist object
 * @param {number=} bytesReceived
 *        Number of bytes already received for the request. Defaults to 0
 * @return {number|NaN}
 *         The estimated time to request the segment. NaN if bandwidth information for
 *         the given playlist is unavailable
 * @function estimateSegmentRequestTime
 */
export const estimateSegmentRequestTime = function(
  segmentDuration,
  bandwidth,
  playlist,
  bytesReceived = 0
) {
  if (!hasAttribute('BANDWIDTH', playlist)) {
    return NaN;
  }

  const size = segmentDuration * playlist.attributes.BANDWIDTH;

  return (size - (bytesReceived * 8)) / bandwidth;
};

/*
 * Returns whether the current playlist is the lowest rendition
 *
 * @return {Boolean} true if on lowest rendition
 */
export const isLowestEnabledRendition = (master, media) => {
  if (master.playlists.length === 1) {
    return true;
  }

  const currentBandwidth = media.attributes.BANDWIDTH || Number.MAX_VALUE;

  return (master.playlists.filter((playlist) => {
    if (!isEnabled(playlist)) {
      return false;
    }

    return (playlist.attributes.BANDWIDTH || 0) < currentBandwidth;

  }).length === 0);
};

export const playlistMatch = (a, b) => {
  // both playlits are null
  // or only one playlist is non-null
  // no match
  if (!a && !b || (!a && b) || (a && !b)) {
    return false;
  }

  // playlist objects are the same, match
  if (a === b) {
    return true;
  }

  // first try to use id as it should be the most
  // accurate
  if (a.id && b.id && a.id === b.id) {
    return true;
  }

  // next try to use reslovedUri as it should be the
  // second most accurate.
  if (a.resolvedUri && b.resolvedUri && a.resolvedUri === b.resolvedUri) {
    return true;
  }

  // finally try to use uri as it should be accurate
  // but might miss a few cases for relative uris
  if (a.uri && b.uri && a.uri === b.uri) {
    return true;
  }

  return false;
};

const someAudioVariant = function(master, callback) {
  const AUDIO = master && master.mediaGroups && master.mediaGroups.AUDIO || {};
  let found = false;

  for (const groupName in AUDIO) {
    for (const label in AUDIO[groupName]) {
      found = callback(AUDIO[groupName][label]);

      if (found) {
        break;
      }
    }

    if (found) {
      break;
    }
  }

  return !!found;
};

export const isAudioOnly = (master) => {
  // we are audio only if we have no main playlists but do
  // have media group playlists.
  if (!master || !master.playlists || !master.playlists.length) {
    // without audio variants or playlists this
    // is not an audio only master.
    const found = someAudioVariant(master, (variant) =>
      (variant.playlists && variant.playlists.length) || variant.uri);

    return found;
  }

  // if every playlist has only an audio codec it is audio only
  for (let i = 0; i < master.playlists.length; i++) {
    const playlist = master.playlists[i];
    const CODECS = playlist.attributes && playlist.attributes.CODECS;

    // all codecs are audio, this is an audio playlist.
    if (CODECS && CODECS.split(',').every((c) => isAudioCodec(c))) {
      continue;
    }

    // playlist is in an audio group it is audio only
    const found = someAudioVariant(master, (variant) => playlistMatch(playlist, variant));

    if (found) {
      continue;
    }

    // if we make it here this playlist isn't audio and we
    // are not audio only
    return false;
  }

  // if we make it past every playlist without returning, then
  // this is an audio only playlist.
  return true;
};

// exports
export default {
  liveEdgeDelay,
  duration,
  seekable,
  getMediaInfoForTime,
  isEnabled,
  isDisabled,
  isBlacklisted,
  isIncompatible,
  playlistEnd,
  isAes,
  hasAttribute,
  estimateSegmentRequestTime,
  isLowestEnabledRendition,
  isAudioOnly,
  playlistMatch,
  segmentDurationWithParts
};
