/**
 * @file ad-cue-tags.js
 */
import window from 'global/window';

/**
 * Searches for an ad cue that overlaps with the given mediaTime
 *
 * @param {Object} track
 *        the track to find the cue for
 *
 * @param {number} mediaTime
 *        the time to find the cue at
 *
 * @return {Object|null}
 *         the found cue or null
 */
export const findAdCue = function(track, mediaTime) {
  const cues = track.cues;

  for (let i = 0; i < cues.length; i++) {
    const cue = cues[i];

    if (mediaTime >= cue.adStartTime && mediaTime <= cue.adEndTime) {
      return cue;
    }
  }
  return null;
};

export const updateAdCues = function(media, track, offset = 0) {
  if (!media.segments) {
    return;
  }

  let mediaTime = offset;
  let cue;

  for (let i = 0; i < media.segments.length; i++) {
    const segment = media.segments[i];

    if (!cue) {
      // Since the cues will span for at least the segment duration, adding a fudge
      // factor of half segment duration will prevent duplicate cues from being
      // created when timing info is not exact (e.g. cue start time initialized
      // at 10.006677, but next call mediaTime is 10.003332 )
      cue = findAdCue(track, mediaTime + (segment.duration / 2));
    }

    if (cue) {
      if ('cueIn' in segment) {
        // Found a CUE-IN so end the cue
        cue.endTime = mediaTime;
        cue.adEndTime = mediaTime;
        mediaTime += segment.duration;
        cue = null;
        continue;
      }

      if (mediaTime < cue.endTime) {
        // Already processed this mediaTime for this cue
        mediaTime += segment.duration;
        continue;
      }

      // otherwise extend cue until a CUE-IN is found
      cue.endTime += segment.duration;

    } else {
      if ('cueOut' in segment) {
        cue = new window.VTTCue(
          mediaTime,
          mediaTime + segment.duration,
          segment.cueOut
        );
        cue.adStartTime = mediaTime;
        // Assumes tag format to be
        // #EXT-X-CUE-OUT:30
        cue.adEndTime = mediaTime + parseFloat(segment.cueOut);
        track.addCue(cue);
      }

      if ('cueOutCont' in segment) {
        // Entered into the middle of an ad cue
        // Assumes tag formate to be
        // #EXT-X-CUE-OUT-CONT:10/30
        const [adOffset, adTotal] = segment.cueOutCont.split('/').map(parseFloat);

        cue = new window.VTTCue(
          mediaTime,
          mediaTime + segment.duration,
          ''
        );
        cue.adStartTime = mediaTime - adOffset;
        cue.adEndTime = cue.adStartTime + adTotal;
        track.addCue(cue);
      }
    }
    mediaTime += segment.duration;
  }
};
