/**
 * @file text-tracks.js
 */
import window from 'global/window';
import videojs from 'video.js';

/**
 * Create captions text tracks on video.js if they do not exist
 *
 * @param {Object} inbandTextTracks a reference to current inbandTextTracks
 * @param {Object} tech the video.js tech
 * @param {Object} captionStream the caption stream to create
 * @private
 */
export const createCaptionsTrackIfNotExists = function(inbandTextTracks, tech, captionStream) {
  if (!inbandTextTracks[captionStream]) {
    tech.trigger({type: 'usage', name: 'vhs-608'});
    tech.trigger({type: 'usage', name: 'hls-608'});

    let instreamId = captionStream;

    // we need to translate SERVICEn for 708 to how mux.js currently labels them
    if (/^cc708_/.test(captionStream)) {
      instreamId = 'SERVICE' + captionStream.split('_')[1];
    }

    const track = tech.textTracks().getTrackById(instreamId);

    if (track) {
      // Resuse an existing track with a CC# id because this was
      // very likely created by videojs-contrib-hls from information
      // in the m3u8 for us to use
      inbandTextTracks[captionStream] = track;
    } else {
      // This section gets called when we have caption services that aren't specified in the manifest.
      // Manifest level caption services are handled in media-groups.js under CLOSED-CAPTIONS.
      const captionServices = tech.options_.vhs && tech.options_.vhs.captionServices || {};
      let label = captionStream;
      let language = captionStream;
      let def = false;
      const captionService = captionServices[instreamId];

      if (captionService) {
        label = captionService.label;
        language = captionService.language;
        def = captionService.default;
      }

      // Otherwise, create a track with the default `CC#` label and
      // without a language
      inbandTextTracks[captionStream] = tech.addRemoteTextTrack({
        kind: 'captions',
        id: instreamId,
        // TODO: investigate why this doesn't seem to turn the caption on by default
        default: def,
        label,
        language
      }, false).track;
    }
  }
};

/**
 * Add caption text track data to a source handler given an array of captions
 *
 * @param {Object}
 *   @param {Object} inbandTextTracks the inband text tracks
 *   @param {number} timestampOffset the timestamp offset of the source buffer
 *   @param {Array} captionArray an array of caption data
 * @private
 */
export const addCaptionData = function({
  inbandTextTracks,
  captionArray,
  timestampOffset
}) {
  if (!captionArray) {
    return;
  }

  const Cue = window.WebKitDataCue || window.VTTCue;

  captionArray.forEach((caption) => {
    const track = caption.stream;

    inbandTextTracks[track].addCue(new Cue(
      caption.startTime + timestampOffset,
      caption.endTime + timestampOffset,
      caption.text
    ));
  });
};

/**
 * Define properties on a cue for backwards compatability,
 * but warn the user that the way that they are using it
 * is depricated and will be removed at a later date.
 *
 * @param {Cue} cue the cue to add the properties on
 * @private
 */
const deprecateOldCue = function(cue) {
  Object.defineProperties(cue.frame, {
    id: {
      get() {
        videojs.log.warn('cue.frame.id is deprecated. Use cue.value.key instead.');
        return cue.value.key;
      }
    },
    value: {
      get() {
        videojs.log.warn('cue.frame.value is deprecated. Use cue.value.data instead.');
        return cue.value.data;
      }
    },
    privateData: {
      get() {
        videojs.log.warn('cue.frame.privateData is deprecated. Use cue.value.data instead.');
        return cue.value.data;
      }
    }
  });
};

/**
 * Add metadata text track data to a source handler given an array of metadata
 *
 * @param {Object}
 *   @param {Object} inbandTextTracks the inband text tracks
 *   @param {Array} metadataArray an array of meta data
 *   @param {number} timestampOffset the timestamp offset of the source buffer
 *   @param {number} videoDuration the duration of the video
 * @private
 */
export const addMetadata = ({
  inbandTextTracks,
  metadataArray,
  timestampOffset,
  videoDuration
}) => {
  if (!metadataArray) {
    return;
  }

  const Cue = window.WebKitDataCue || window.VTTCue;
  const metadataTrack = inbandTextTracks.metadataTrack_;

  if (!metadataTrack) {
    return;
  }

  metadataArray.forEach((metadata) => {
    const time = metadata.cueTime + timestampOffset;

    // if time isn't a finite number between 0 and Infinity, like NaN,
    // ignore this bit of metadata.
    // This likely occurs when you have an non-timed ID3 tag like TIT2,
    // which is the "Title/Songname/Content description" frame
    if (typeof time !== 'number' || window.isNaN(time) || time < 0 || !(time < Infinity)) {
      return;
    }

    metadata.frames.forEach((frame) => {
      const cue = new Cue(
        time,
        time,
        frame.value || frame.url || frame.data || ''
      );

      cue.frame = frame;
      cue.value = frame;
      deprecateOldCue(cue);

      metadataTrack.addCue(cue);
    });
  });

  if (!metadataTrack.cues || !metadataTrack.cues.length) {
    return;
  }

  // Updating the metadeta cues so that
  // the endTime of each cue is the startTime of the next cue
  // the endTime of last cue is the duration of the video
  const cues = metadataTrack.cues;
  const cuesArray = [];

  // Create a copy of the TextTrackCueList...
  // ...disregarding cues with a falsey value
  for (let i = 0; i < cues.length; i++) {
    if (cues[i]) {
      cuesArray.push(cues[i]);
    }
  }

  // Group cues by their startTime value
  const cuesGroupedByStartTime = cuesArray.reduce((obj, cue) => {
    const timeSlot = obj[cue.startTime] || [];

    timeSlot.push(cue);
    obj[cue.startTime] = timeSlot;

    return obj;
  }, {});

  // Sort startTimes by ascending order
  const sortedStartTimes = Object.keys(cuesGroupedByStartTime)
    .sort((a, b) => Number(a) - Number(b));

  // Map each cue group's endTime to the next group's startTime
  sortedStartTimes.forEach((startTime, idx) => {
    const cueGroup = cuesGroupedByStartTime[startTime];
    const nextTime = Number(sortedStartTimes[idx + 1]) || videoDuration;

    // Map each cue's endTime the next group's startTime
    cueGroup.forEach((cue) => {
      cue.endTime = nextTime;
    });
  });
};

/**
 * Create metadata text track on video.js if it does not exist
 *
 * @param {Object} inbandTextTracks a reference to current inbandTextTracks
 * @param {string} dispatchType the inband metadata track dispatch type
 * @param {Object} tech the video.js tech
 * @private
 */
export const createMetadataTrackIfNotExists = (inbandTextTracks, dispatchType, tech) => {
  if (inbandTextTracks.metadataTrack_) {
    return;
  }

  inbandTextTracks.metadataTrack_ = tech.addRemoteTextTrack({
    kind: 'metadata',
    label: 'Timed Metadata'
  }, false).track;

  inbandTextTracks.metadataTrack_.inBandMetadataTrackDispatchType = dispatchType;
};

/**
 * Remove cues from a track on video.js.
 *
 * @param {Double} start start of where we should remove the cue
 * @param {Double} end end of where the we should remove the cue
 * @param {Object} track the text track to remove the cues from
 * @private
 */
export const removeCuesFromTrack = function(start, end, track) {
  let i;
  let cue;

  if (!track) {
    return;
  }

  if (!track.cues) {
    return;
  }

  i = track.cues.length;

  while (i--) {
    cue = track.cues[i];

    // Remove any cue within the provided start and end time
    if (cue.startTime >= start && cue.endTime <= end) {
      track.removeCue(cue);
    }
  }
};

/**
 * Remove duplicate cues from a track on video.js (a cue is considered a
 * duplicate if it has the same time interval and text as another)
 *
 * @param {Object} track the text track to remove the duplicate cues from
 * @private
 */
export const removeDuplicateCuesFromTrack = function(track) {
  const cues = track.cues;

  if (!cues) {
    return;
  }

  for (let i = 0; i < cues.length; i++) {
    const duplicates = [];
    let occurrences = 0;

    for (let j = 0; j < cues.length; j++) {
      if (
        cues[i].startTime === cues[j].startTime &&
        cues[i].endTime === cues[j].endTime &&
        cues[i].text === cues[j].text
      ) {
        occurrences++;

        if (occurrences > 1) {
          duplicates.push(cues[j]);
        }
      }
    }

    if (duplicates.length) {
      duplicates.forEach(dupe => track.removeCue(dupe));
    }
  }
};
