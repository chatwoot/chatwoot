// TODO handle fmp4 case where the timing info is accurate and doesn't involve transmux

/**
 * @file time.js
 */

import Playlist from '../playlist';

// Add 25% to the segment duration to account for small discrepencies in segment timing.
// 25% was arbitrarily chosen, and may need to be refined over time.
const SEGMENT_END_FUDGE_PERCENT = 0.25;

/**
 * Converts a player time (any time that can be gotten/set from player.currentTime(),
 * e.g., any time within player.seekable().start(0) to player.seekable().end(0)) to a
 * program time (any time referencing the real world (e.g., EXT-X-PROGRAM-DATE-TIME)).
 *
 * The containing segment is required as the EXT-X-PROGRAM-DATE-TIME serves as an "anchor
 * point" (a point where we have a mapping from program time to player time, with player
 * time being the post transmux start of the segment).
 *
 * For more details, see [this doc](../../docs/program-time-from-player-time.md).
 *
 * @param {number} playerTime the player time
 * @param {Object} segment the segment which contains the player time
 * @return {Date} program time
 */
export const playerTimeToProgramTime = (playerTime, segment) => {
  if (!segment.dateTimeObject) {
    // Can't convert without an "anchor point" for the program time (i.e., a time that can
    // be used to map the start of a segment with a real world time).
    return null;
  }

  const transmuxerPrependedSeconds = segment.videoTimingInfo.transmuxerPrependedSeconds;
  const transmuxedStart = segment.videoTimingInfo.transmuxedPresentationStart;

  // get the start of the content from before old content is prepended
  const startOfSegment = transmuxedStart + transmuxerPrependedSeconds;
  const offsetFromSegmentStart = playerTime - startOfSegment;

  return new Date(segment.dateTimeObject.getTime() + offsetFromSegmentStart * 1000);
};

export const originalSegmentVideoDuration = (videoTimingInfo) => {
  return videoTimingInfo.transmuxedPresentationEnd -
    videoTimingInfo.transmuxedPresentationStart -
    videoTimingInfo.transmuxerPrependedSeconds;
};

/**
 * Finds a segment that contains the time requested given as an ISO-8601 string. The
 * returned segment might be an estimate or an accurate match.
 *
 * @param {string} programTime The ISO-8601 programTime to find a match for
 * @param {Object} playlist A playlist object to search within
 */
export const findSegmentForProgramTime = (programTime, playlist) => {
  // Assumptions:
  //  - verifyProgramDateTimeTags has already been run
  //  - live streams have been started

  let dateTimeObject;

  try {
    dateTimeObject = new Date(programTime);
  } catch (e) {
    return null;
  }

  if (!playlist || !playlist.segments || playlist.segments.length === 0) {
    return null;
  }

  let segment = playlist.segments[0];

  if (dateTimeObject < segment.dateTimeObject) {
    // Requested time is before stream start.
    return null;
  }

  for (let i = 0; i < playlist.segments.length - 1; i++) {
    segment = playlist.segments[i];

    const nextSegmentStart = playlist.segments[i + 1].dateTimeObject;

    if (dateTimeObject < nextSegmentStart) {
      break;
    }
  }

  const lastSegment = playlist.segments[playlist.segments.length - 1];
  const lastSegmentStart = lastSegment.dateTimeObject;
  const lastSegmentDuration = lastSegment.videoTimingInfo ?
    originalSegmentVideoDuration(lastSegment.videoTimingInfo) :
    lastSegment.duration + lastSegment.duration * SEGMENT_END_FUDGE_PERCENT;
  const lastSegmentEnd =
    new Date(lastSegmentStart.getTime() + lastSegmentDuration * 1000);

  if (dateTimeObject > lastSegmentEnd) {
    // Beyond the end of the stream, or our best guess of the end of the stream.
    return null;
  }

  if (dateTimeObject > lastSegmentStart) {
    segment = lastSegment;
  }

  return {
    segment,
    estimatedStart: segment.videoTimingInfo ?
      segment.videoTimingInfo.transmuxedPresentationStart :
      Playlist.duration(
        playlist,
        playlist.mediaSequence + playlist.segments.indexOf(segment)
      ),
    // Although, given that all segments have accurate date time objects, the segment
    // selected should be accurate, unless the video has been transmuxed at some point
    // (determined by the presence of the videoTimingInfo object), the segment's "player
    // time" (the start time in the player) can't be considered accurate.
    type: segment.videoTimingInfo ? 'accurate' : 'estimate'
  };
};

/**
 * Finds a segment that contains the given player time(in seconds).
 *
 * @param {number} time The player time to find a match for
 * @param {Object} playlist A playlist object to search within
 */
export const findSegmentForPlayerTime = (time, playlist) => {
  // Assumptions:
  // - there will always be a segment.duration
  // - we can start from zero
  // - segments are in time order

  if (!playlist || !playlist.segments || playlist.segments.length === 0) {
    return null;
  }

  let segmentEnd = 0;
  let segment;

  for (let i = 0; i < playlist.segments.length; i++) {
    segment = playlist.segments[i];

    // videoTimingInfo is set after the segment is downloaded and transmuxed, and
    // should contain the most accurate values we have for the segment's player times.
    //
    // Use the accurate transmuxedPresentationEnd value if it is available, otherwise fall
    // back to an estimate based on the manifest derived (inaccurate) segment.duration, to
    // calculate an end value.
    segmentEnd = segment.videoTimingInfo ?
      segment.videoTimingInfo.transmuxedPresentationEnd : segmentEnd + segment.duration;

    if (time <= segmentEnd) {
      break;
    }
  }

  const lastSegment = playlist.segments[playlist.segments.length - 1];

  if (lastSegment.videoTimingInfo &&
      lastSegment.videoTimingInfo.transmuxedPresentationEnd < time) {
    // The time requested is beyond the stream end.
    return null;
  }

  if (time > segmentEnd) {
    // The time is within or beyond the last segment.
    //
    // Check to see if the time is beyond a reasonable guess of the end of the stream.
    if (time > segmentEnd + (lastSegment.duration * SEGMENT_END_FUDGE_PERCENT)) {
      // Technically, because the duration value is only an estimate, the time may still
      // exist in the last segment, however, there isn't enough information to make even
      // a reasonable estimate.
      return null;
    }

    segment = lastSegment;
  }

  return {
    segment,
    estimatedStart: segment.videoTimingInfo ?
      segment.videoTimingInfo.transmuxedPresentationStart : segmentEnd - segment.duration,
    // Because videoTimingInfo is only set after transmux, it is the only way to get
    // accurate timing values.
    type: segment.videoTimingInfo ? 'accurate' : 'estimate'
  };
};

/**
 * Gives the offset of the comparisonTimestamp from the programTime timestamp in seconds.
 * If the offset returned is positive, the programTime occurs after the
 * comparisonTimestamp.
 * If the offset is negative, the programTime occurs before the comparisonTimestamp.
 *
 * @param {string} comparisonTimeStamp An ISO-8601 timestamp to compare against
 * @param {string} programTime The programTime as an ISO-8601 string
 * @return {number} offset
 */
export const getOffsetFromTimestamp = (comparisonTimeStamp, programTime) => {
  let segmentDateTime;
  let programDateTime;

  try {
    segmentDateTime = new Date(comparisonTimeStamp);
    programDateTime = new Date(programTime);
  } catch (e) {
    // TODO handle error
  }

  const segmentTimeEpoch = segmentDateTime.getTime();
  const programTimeEpoch = programDateTime.getTime();

  return (programTimeEpoch - segmentTimeEpoch) / 1000;
};

/**
 * Checks that all segments in this playlist have programDateTime tags.
 *
 * @param {Object} playlist A playlist object
 */
export const verifyProgramDateTimeTags = (playlist) => {
  if (!playlist.segments || playlist.segments.length === 0) {
    return false;
  }

  for (let i = 0; i < playlist.segments.length; i++) {
    const segment = playlist.segments[i];

    if (!segment.dateTimeObject) {
      return false;
    }
  }

  return true;
};

/**
 * Returns the programTime of the media given a playlist and a playerTime.
 * The playlist must have programDateTime tags for a programDateTime tag to be returned.
 * If the segments containing the time requested have not been buffered yet, an estimate
 * may be returned to the callback.
 *
 * @param {Object} args
 * @param {Object} args.playlist A playlist object to search within
 * @param {number} time A playerTime in seconds
 * @param {Function} callback(err, programTime)
 * @return {string} err.message A detailed error message
 * @return {Object} programTime
 * @return {number} programTime.mediaSeconds The streamTime in seconds
 * @return {string} programTime.programDateTime The programTime as an ISO-8601 String
 */
export const getProgramTime = ({
  playlist,
  time = undefined,
  callback
}) => {

  if (!callback) {
    throw new Error('getProgramTime: callback must be provided');
  }

  if (!playlist || time === undefined) {
    return callback({
      message: 'getProgramTime: playlist and time must be provided'
    });
  }

  const matchedSegment = findSegmentForPlayerTime(time, playlist);

  if (!matchedSegment) {
    return callback({
      message: 'valid programTime was not found'
    });
  }

  if (matchedSegment.type === 'estimate') {
    return callback({
      message:
        'Accurate programTime could not be determined.' +
        ' Please seek to e.seekTime and try again',
      seekTime: matchedSegment.estimatedStart
    });
  }

  const programTimeObject = {
    mediaSeconds: time
  };
  const programTime = playerTimeToProgramTime(time, matchedSegment.segment);

  if (programTime) {
    programTimeObject.programDateTime = programTime.toISOString();
  }

  return callback(null, programTimeObject);
};

/**
 * Seeks in the player to a time that matches the given programTime ISO-8601 string.
 *
 * @param {Object} args
 * @param {string} args.programTime A programTime to seek to as an ISO-8601 String
 * @param {Object} args.playlist A playlist to look within
 * @param {number} args.retryCount The number of times to try for an accurate seek. Default is 2.
 * @param {Function} args.seekTo A method to perform a seek
 * @param {boolean} args.pauseAfterSeek Whether to end in a paused state after seeking. Default is true.
 * @param {Object} args.tech The tech to seek on
 * @param {Function} args.callback(err, newTime) A callback to return the new time to
 * @return {string} err.message A detailed error message
 * @return {number} newTime The exact time that was seeked to in seconds
 */
export const seekToProgramTime = ({
  programTime,
  playlist,
  retryCount = 2,
  seekTo,
  pauseAfterSeek = true,
  tech,
  callback
}) => {

  if (!callback) {
    throw new Error('seekToProgramTime: callback must be provided');
  }

  if (typeof programTime === 'undefined' || !playlist || !seekTo) {
    return callback({
      message: 'seekToProgramTime: programTime, seekTo and playlist must be provided'
    });
  }

  if (!playlist.endList && !tech.hasStarted_) {
    return callback({
      message: 'player must be playing a live stream to start buffering'
    });
  }

  if (!verifyProgramDateTimeTags(playlist)) {
    return callback({
      message: 'programDateTime tags must be provided in the manifest ' + playlist.resolvedUri
    });
  }

  const matchedSegment = findSegmentForProgramTime(programTime, playlist);

  // no match
  if (!matchedSegment) {
    return callback({
      message: `${programTime} was not found in the stream`
    });
  }

  const segment = matchedSegment.segment;
  const mediaOffset = getOffsetFromTimestamp(
    segment.dateTimeObject,
    programTime
  );

  if (matchedSegment.type === 'estimate') {
    // we've run out of retries
    if (retryCount === 0) {
      return callback({
        message: `${programTime} is not buffered yet. Try again`
      });
    }

    seekTo(matchedSegment.estimatedStart + mediaOffset);

    tech.one('seeked', () => {
      seekToProgramTime({
        programTime,
        playlist,
        retryCount: retryCount - 1,
        seekTo,
        pauseAfterSeek,
        tech,
        callback
      });
    });

    return;
  }

  // Since the segment.start value is determined from the buffered end or ending time
  // of the prior segment, the seekToTime doesn't need to account for any transmuxer
  // modifications.
  const seekToTime = segment.start + mediaOffset;
  const seekedCallback = () => {
    return callback(null, tech.currentTime());
  };

  // listen for seeked event
  tech.one('seeked', seekedCallback);
  // pause before seeking as video.js will restore this state
  if (pauseAfterSeek) {
    tech.pause();
  }
  seekTo(seekToTime);
};
