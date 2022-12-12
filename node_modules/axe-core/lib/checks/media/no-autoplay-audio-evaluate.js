function noAutoplayAudioEvaluate(node, options) {
  /**
   * if duration cannot be read, this means `preloadMedia` has failed
   */
  if (!node.duration) {
    console.warn(`axe.utils.preloadMedia did not load metadata`);
    return undefined;
  }

  /**
   * Compute playable duration and verify if it within allowed duration
   */
  const { allowedDuration = 3 } = options;
  const playableDuration = getPlayableDuration(node);
  if (playableDuration <= allowedDuration && !node.hasAttribute('loop')) {
    return true;
  }

  /**
   * if media element does not provide controls mechanism
   * -> fail
   */
  if (!node.hasAttribute('controls')) {
    return false;
  }

  return true;

  /**
   * Compute playback duration
   * @param {HTMLMediaElement} elm media element
   */
  function getPlayableDuration(elm) {
    if (!elm.currentSrc) {
      return 0;
    }

    const playbackRange = getPlaybackRange(elm.currentSrc);
    if (!playbackRange) {
      return Math.abs(elm.duration - (elm.currentTime || 0));
    }

    if (playbackRange.length === 1) {
      return Math.abs(elm.duration - playbackRange[0]);
    }

    return Math.abs(playbackRange[1] - playbackRange[0]);
  }

  /**
   * Get playback range from a media elements source, if specified
   * See - https://developer.mozilla.org/de/docs/Web/HTML/Using_HTML5_audio_and_video#Specifying_playback_range
   *
   * Eg:
   * src='....someMedia.mp3#t=8'
   * 	-> should yeild [8]
   * src='....someMedia.mp3#t=10,12'
   *  -> should yeild [10,12]
   * @param {String} src media src
   * @returns {Array|undefined}
   */
  function getPlaybackRange(src) {
    const match = src.match(/#t=(.*)/);
    if (!match) {
      return;
    }
    const [, value] = match;
    const ranges = value.split(',');

    return ranges.map(range => {
      // range is denoted in HH:MM:SS -> convert to seconds
      if (/:/.test(range)) {
        return convertHourMinSecToSeconds(range);
      }
      return parseFloat(range);
    });
  }

  /**
   * Add HH, MM, SS to seconds
   * @param {String} hhMmSs time expressed in HH:MM:SS
   */
  function convertHourMinSecToSeconds(hhMmSs) {
    const parts = hhMmSs.split(':');
    let secs = 0;
    let mins = 1;

    while (parts.length > 0) {
      secs += mins * parseInt(parts.pop(), 10);
      mins *= 60;
    }

    return parseFloat(secs);
  }
}

export default noAutoplayAudioEvaluate;
