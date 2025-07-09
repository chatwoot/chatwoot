/**
 * @file sync-controller.js
 */

import {sumDurations, getPartsAndSegments} from './playlist';
import videojs from 'video.js';
import logger from './util/logger';

// The maximum gap allowed between two media sequence tags when trying to
// synchronize expired playlist segments.
// the max media sequence diff is 48 hours of live stream
// content with two second segments. Anything larger than that
// will likely be invalid.
const MAX_MEDIA_SEQUENCE_DIFF_FOR_SYNC = 86400;

export const syncPointStrategies = [
  // Stategy "VOD": Handle the VOD-case where the sync-point is *always*
  //                the equivalence display-time 0 === segment-index 0
  {
    name: 'VOD',
    run: (syncController, playlist, duration, currentTimeline, currentTime) => {
      if (duration !== Infinity) {
        const syncPoint = {
          time: 0,
          segmentIndex: 0,
          partIndex: null
        };

        return syncPoint;
      }
      return null;
    }
  },
  // Stategy "ProgramDateTime": We have a program-date-time tag in this playlist
  {
    name: 'ProgramDateTime',
    run: (syncController, playlist, duration, currentTimeline, currentTime) => {
      if (!Object.keys(syncController.timelineToDatetimeMappings).length) {
        return null;
      }

      let syncPoint = null;
      let lastDistance = null;
      const partsAndSegments = getPartsAndSegments(playlist);

      currentTime = currentTime || 0;
      for (let i = 0; i < partsAndSegments.length; i++) {
        // start from the end and loop backwards for live
        // or start from the front and loop forwards for non-live
        const index = (playlist.endList || currentTime === 0) ? i : partsAndSegments.length - (i + 1);
        const partAndSegment = partsAndSegments[index];
        const segment = partAndSegment.segment;
        const datetimeMapping =
          syncController.timelineToDatetimeMappings[segment.timeline];

        if (!datetimeMapping || !segment.dateTimeObject) {
          continue;
        }

        const segmentTime = segment.dateTimeObject.getTime() / 1000;
        let start = segmentTime + datetimeMapping;

        // take part duration into account.
        if (segment.parts && typeof partAndSegment.partIndex === 'number') {
          for (let z = 0; z < partAndSegment.partIndex; z++) {
            start += segment.parts[z].duration;
          }
        }
        const distance = Math.abs(currentTime - start);

        // Once the distance begins to increase, or if distance is 0, we have passed
        // currentTime and can stop looking for better candidates
        if (lastDistance !== null && (distance === 0 || lastDistance < distance)) {
          break;
        }

        lastDistance = distance;
        syncPoint = {
          time: start,
          segmentIndex: partAndSegment.segmentIndex,
          partIndex: partAndSegment.partIndex
        };
      }
      return syncPoint;
    }
  },
  // Stategy "Segment": We have a known time mapping for a timeline and a
  //                    segment in the current timeline with timing data
  {
    name: 'Segment',
    run: (syncController, playlist, duration, currentTimeline, currentTime) => {
      let syncPoint = null;
      let lastDistance = null;

      currentTime = currentTime || 0;
      const partsAndSegments = getPartsAndSegments(playlist);

      for (let i = 0; i < partsAndSegments.length; i++) {
        // start from the end and loop backwards for live
        // or start from the front and loop forwards for non-live
        const index = (playlist.endList || currentTime === 0) ? i : partsAndSegments.length - (i + 1);
        const partAndSegment = partsAndSegments[index];
        const segment = partAndSegment.segment;
        const start = partAndSegment.part && partAndSegment.part.start || segment && segment.start;

        if (segment.timeline === currentTimeline && typeof start !== 'undefined') {
          const distance = Math.abs(currentTime - start);

          // Once the distance begins to increase, we have passed
          // currentTime and can stop looking for better candidates
          if (lastDistance !== null && lastDistance < distance) {
            break;
          }

          if (!syncPoint || lastDistance === null || lastDistance >= distance) {
            lastDistance = distance;
            syncPoint = {
              time: start,
              segmentIndex: partAndSegment.segmentIndex,
              partIndex: partAndSegment.partIndex
            };
          }

        }
      }
      return syncPoint;
    }
  },
  // Stategy "Discontinuity": We have a discontinuity with a known
  //                          display-time
  {
    name: 'Discontinuity',
    run: (syncController, playlist, duration, currentTimeline, currentTime) => {
      let syncPoint = null;

      currentTime = currentTime || 0;

      if (playlist.discontinuityStarts && playlist.discontinuityStarts.length) {
        let lastDistance = null;

        for (let i = 0; i < playlist.discontinuityStarts.length; i++) {
          const segmentIndex = playlist.discontinuityStarts[i];
          const discontinuity = playlist.discontinuitySequence + i + 1;
          const discontinuitySync = syncController.discontinuities[discontinuity];

          if (discontinuitySync) {
            const distance = Math.abs(currentTime - discontinuitySync.time);

            // Once the distance begins to increase, we have passed
            // currentTime and can stop looking for better candidates
            if (lastDistance !== null && lastDistance < distance) {
              break;
            }

            if (!syncPoint || lastDistance === null || lastDistance >= distance) {
              lastDistance = distance;
              syncPoint = {
                time: discontinuitySync.time,
                segmentIndex,
                partIndex: null
              };
            }
          }
        }
      }
      return syncPoint;
    }
  },
  // Stategy "Playlist": We have a playlist with a known mapping of
  //                     segment index to display time
  {
    name: 'Playlist',
    run: (syncController, playlist, duration, currentTimeline, currentTime) => {
      if (playlist.syncInfo) {
        const syncPoint = {
          time: playlist.syncInfo.time,
          segmentIndex: playlist.syncInfo.mediaSequence - playlist.mediaSequence,
          partIndex: null
        };

        return syncPoint;
      }
      return null;
    }
  }
];

export default class SyncController extends videojs.EventTarget {
  constructor(options = {}) {
    super();
    // ...for synching across variants
    this.timelines = [];
    this.discontinuities = [];
    this.timelineToDatetimeMappings = {};

    this.logger_ = logger('SyncController');
  }

  /**
   * Find a sync-point for the playlist specified
   *
   * A sync-point is defined as a known mapping from display-time to
   * a segment-index in the current playlist.
   *
   * @param {Playlist} playlist
   *        The playlist that needs a sync-point
   * @param {number} duration
   *        Duration of the MediaSource (Infinite if playing a live source)
   * @param {number} currentTimeline
   *        The last timeline from which a segment was loaded
   * @return {Object}
   *          A sync-point object
   */
  getSyncPoint(playlist, duration, currentTimeline, currentTime) {
    const syncPoints = this.runStrategies_(
      playlist,
      duration,
      currentTimeline,
      currentTime
    );

    if (!syncPoints.length) {
      // Signal that we need to attempt to get a sync-point manually
      // by fetching a segment in the playlist and constructing
      // a sync-point from that information
      return null;
    }

    // Now find the sync-point that is closest to the currentTime because
    // that should result in the most accurate guess about which segment
    // to fetch
    return this.selectSyncPoint_(syncPoints, { key: 'time', value: currentTime });
  }

  /**
   * Calculate the amount of time that has expired off the playlist during playback
   *
   * @param {Playlist} playlist
   *        Playlist object to calculate expired from
   * @param {number} duration
   *        Duration of the MediaSource (Infinity if playling a live source)
   * @return {number|null}
   *          The amount of time that has expired off the playlist during playback. Null
   *          if no sync-points for the playlist can be found.
   */
  getExpiredTime(playlist, duration) {
    if (!playlist || !playlist.segments) {
      return null;
    }

    const syncPoints = this.runStrategies_(
      playlist,
      duration,
      playlist.discontinuitySequence,
      0
    );

    // Without sync-points, there is not enough information to determine the expired time
    if (!syncPoints.length) {
      return null;
    }

    const syncPoint = this.selectSyncPoint_(syncPoints, {
      key: 'segmentIndex',
      value: 0
    });

    // If the sync-point is beyond the start of the playlist, we want to subtract the
    // duration from index 0 to syncPoint.segmentIndex instead of adding.
    if (syncPoint.segmentIndex > 0) {
      syncPoint.time *= -1;
    }

    return Math.abs(syncPoint.time + sumDurations({
      defaultDuration: playlist.targetDuration,
      durationList: playlist.segments,
      startIndex: syncPoint.segmentIndex,
      endIndex: 0
    }));
  }

  /**
   * Runs each sync-point strategy and returns a list of sync-points returned by the
   * strategies
   *
   * @private
   * @param {Playlist} playlist
   *        The playlist that needs a sync-point
   * @param {number} duration
   *        Duration of the MediaSource (Infinity if playing a live source)
   * @param {number} currentTimeline
   *        The last timeline from which a segment was loaded
   * @return {Array}
   *          A list of sync-point objects
   */
  runStrategies_(playlist, duration, currentTimeline, currentTime) {
    const syncPoints = [];

    // Try to find a sync-point in by utilizing various strategies...
    for (let i = 0; i < syncPointStrategies.length; i++) {
      const strategy = syncPointStrategies[i];
      const syncPoint = strategy.run(
        this,
        playlist,
        duration,
        currentTimeline,
        currentTime
      );

      if (syncPoint) {
        syncPoint.strategy = strategy.name;
        syncPoints.push({
          strategy: strategy.name,
          syncPoint
        });
      }
    }

    return syncPoints;
  }

  /**
   * Selects the sync-point nearest the specified target
   *
   * @private
   * @param {Array} syncPoints
   *        List of sync-points to select from
   * @param {Object} target
   *        Object specifying the property and value we are targeting
   * @param {string} target.key
   *        Specifies the property to target. Must be either 'time' or 'segmentIndex'
   * @param {number} target.value
   *        The value to target for the specified key.
   * @return {Object}
   *          The sync-point nearest the target
   */
  selectSyncPoint_(syncPoints, target) {
    let bestSyncPoint = syncPoints[0].syncPoint;
    let bestDistance = Math.abs(syncPoints[0].syncPoint[target.key] - target.value);
    let bestStrategy = syncPoints[0].strategy;

    for (let i = 1; i < syncPoints.length; i++) {
      const newDistance = Math.abs(syncPoints[i].syncPoint[target.key] - target.value);

      if (newDistance < bestDistance) {
        bestDistance = newDistance;
        bestSyncPoint = syncPoints[i].syncPoint;
        bestStrategy = syncPoints[i].strategy;
      }
    }

    this.logger_(`syncPoint for [${target.key}: ${target.value}] chosen with strategy` +
      ` [${bestStrategy}]: [time:${bestSyncPoint.time},` +
      ` segmentIndex:${bestSyncPoint.segmentIndex}` +
      (typeof bestSyncPoint.partIndex === 'number' ? `,partIndex:${bestSyncPoint.partIndex}` : '') +
      ']');

    return bestSyncPoint;
  }

  /**
   * Save any meta-data present on the segments when segments leave
   * the live window to the playlist to allow for synchronization at the
   * playlist level later.
   *
   * @param {Playlist} oldPlaylist - The previous active playlist
   * @param {Playlist} newPlaylist - The updated and most current playlist
   */
  saveExpiredSegmentInfo(oldPlaylist, newPlaylist) {
    const mediaSequenceDiff = newPlaylist.mediaSequence - oldPlaylist.mediaSequence;

    // Ignore large media sequence gaps
    if (mediaSequenceDiff > MAX_MEDIA_SEQUENCE_DIFF_FOR_SYNC) {
      videojs.log.warn(`Not saving expired segment info. Media sequence gap ${mediaSequenceDiff} is too large.`);
      return;
    }

    // When a segment expires from the playlist and it has a start time
    // save that information as a possible sync-point reference in future
    for (let i = mediaSequenceDiff - 1; i >= 0; i--) {
      const lastRemovedSegment = oldPlaylist.segments[i];

      if (lastRemovedSegment && typeof lastRemovedSegment.start !== 'undefined') {
        newPlaylist.syncInfo = {
          mediaSequence: oldPlaylist.mediaSequence + i,
          time: lastRemovedSegment.start
        };
        this.logger_(`playlist refresh sync: [time:${newPlaylist.syncInfo.time},` +
          ` mediaSequence: ${newPlaylist.syncInfo.mediaSequence}]`);
        this.trigger('syncinfoupdate');
        break;
      }
    }
  }

  /**
   * Save the mapping from playlist's ProgramDateTime to display. This should only happen
   * before segments start to load.
   *
   * @param {Playlist} playlist - The currently active playlist
   */
  setDateTimeMappingForStart(playlist) {
    // It's possible for the playlist to be updated before playback starts, meaning time
    // zero is not yet set. If, during these playlist refreshes, a discontinuity is
    // crossed, then the old time zero mapping (for the prior timeline) would be retained
    // unless the mappings are cleared.
    this.timelineToDatetimeMappings = {};

    if (playlist.segments &&
        playlist.segments.length &&
        playlist.segments[0].dateTimeObject) {
      const firstSegment = playlist.segments[0];
      const playlistTimestamp = firstSegment.dateTimeObject.getTime() / 1000;

      this.timelineToDatetimeMappings[firstSegment.timeline] = -playlistTimestamp;
    }
  }

  /**
   * Calculates and saves timeline mappings, playlist sync info, and segment timing values
   * based on the latest timing information.
   *
   * @param {Object} options
   *        Options object
   * @param {SegmentInfo} options.segmentInfo
   *        The current active request information
   * @param {boolean} options.shouldSaveTimelineMapping
   *        If there's a timeline change, determines if the timeline mapping should be
   *        saved for timeline mapping and program date time mappings.
   */
  saveSegmentTimingInfo({ segmentInfo, shouldSaveTimelineMapping }) {
    const didCalculateSegmentTimeMapping = this.calculateSegmentTimeMapping_(
      segmentInfo,
      segmentInfo.timingInfo,
      shouldSaveTimelineMapping
    );
    const segment = segmentInfo.segment;

    if (didCalculateSegmentTimeMapping) {
      this.saveDiscontinuitySyncInfo_(segmentInfo);

      // If the playlist does not have sync information yet, record that information
      // now with segment timing information
      if (!segmentInfo.playlist.syncInfo) {
        segmentInfo.playlist.syncInfo = {
          mediaSequence: segmentInfo.playlist.mediaSequence + segmentInfo.mediaIndex,
          time: segment.start
        };
      }
    }

    const dateTime = segment.dateTimeObject;

    if (segment.discontinuity && shouldSaveTimelineMapping && dateTime) {
      this.timelineToDatetimeMappings[segment.timeline] = -(dateTime.getTime() / 1000);
    }
  }

  timestampOffsetForTimeline(timeline) {
    if (typeof this.timelines[timeline] === 'undefined') {
      return null;
    }
    return this.timelines[timeline].time;
  }

  mappingForTimeline(timeline) {
    if (typeof this.timelines[timeline] === 'undefined') {
      return null;
    }
    return this.timelines[timeline].mapping;
  }

  /**
   * Use the "media time" for a segment to generate a mapping to "display time" and
   * save that display time to the segment.
   *
   * @private
   * @param {SegmentInfo} segmentInfo
   *        The current active request information
   * @param {Object} timingInfo
   *        The start and end time of the current segment in "media time"
   * @param {boolean} shouldSaveTimelineMapping
   *        If there's a timeline change, determines if the timeline mapping should be
   *        saved in timelines.
   * @return {boolean}
   *          Returns false if segment time mapping could not be calculated
   */
  calculateSegmentTimeMapping_(segmentInfo, timingInfo, shouldSaveTimelineMapping) {
    // TODO: remove side effects
    const segment = segmentInfo.segment;
    const part = segmentInfo.part;
    let mappingObj = this.timelines[segmentInfo.timeline];
    let start;
    let end;

    if (typeof segmentInfo.timestampOffset === 'number') {
      mappingObj = {
        time: segmentInfo.startOfSegment,
        mapping: segmentInfo.startOfSegment - timingInfo.start
      };
      if (shouldSaveTimelineMapping) {
        this.timelines[segmentInfo.timeline] = mappingObj;
        this.trigger('timestampoffset');

        this.logger_(`time mapping for timeline ${segmentInfo.timeline}: ` +
          `[time: ${mappingObj.time}] [mapping: ${mappingObj.mapping}]`);
      }

      start = segmentInfo.startOfSegment;
      end = timingInfo.end + mappingObj.mapping;

    } else if (mappingObj) {
      start = timingInfo.start + mappingObj.mapping;
      end = timingInfo.end + mappingObj.mapping;
    } else {
      return false;
    }

    if (part) {
      part.start = start;
      part.end = end;
    }

    // If we don't have a segment start yet or the start value we got
    // is less than our current segment.start value, save a new start value.
    // We have to do this because parts will have segment timing info saved
    // multiple times and we want segment start to be the earliest part start
    // value for that segment.
    if (!segment.start || start < segment.start) {
      segment.start = start;
    }
    segment.end = end;

    return true;
  }

  /**
   * Each time we have discontinuity in the playlist, attempt to calculate the location
   * in display of the start of the discontinuity and save that. We also save an accuracy
   * value so that we save values with the most accuracy (closest to 0.)
   *
   * @private
   * @param {SegmentInfo} segmentInfo - The current active request information
   */
  saveDiscontinuitySyncInfo_(segmentInfo) {
    const playlist = segmentInfo.playlist;
    const segment = segmentInfo.segment;

    // If the current segment is a discontinuity then we know exactly where
    // the start of the range and it's accuracy is 0 (greater accuracy values
    // mean more approximation)
    if (segment.discontinuity) {
      this.discontinuities[segment.timeline] = {
        time: segment.start,
        accuracy: 0
      };
    } else if (playlist.discontinuityStarts && playlist.discontinuityStarts.length) {
      // Search for future discontinuities that we can provide better timing
      // information for and save that information for sync purposes
      for (let i = 0; i < playlist.discontinuityStarts.length; i++) {
        const segmentIndex = playlist.discontinuityStarts[i];
        const discontinuity = playlist.discontinuitySequence + i + 1;
        const mediaIndexDiff = segmentIndex - segmentInfo.mediaIndex;
        const accuracy = Math.abs(mediaIndexDiff);

        if (!this.discontinuities[discontinuity] ||
             this.discontinuities[discontinuity].accuracy > accuracy) {
          let time;

          if (mediaIndexDiff < 0) {
            time = segment.start - sumDurations({
              defaultDuration: playlist.targetDuration,
              durationList: playlist.segments,
              startIndex: segmentInfo.mediaIndex,
              endIndex: segmentIndex
            });
          } else {
            time = segment.end + sumDurations({
              defaultDuration: playlist.targetDuration,
              durationList: playlist.segments,
              startIndex: segmentInfo.mediaIndex + 1,
              endIndex: segmentIndex
            });
          }

          this.discontinuities[discontinuity] = {
            time,
            accuracy
          };
        }
      }
    }
  }

  dispose() {
    this.trigger('dispose');
    this.off();
  }
}
