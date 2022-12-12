function noAutoplayAudioMatches(node) {
  /**
   * Ignore media nodes without `currenSrc`
   * 	Notes:
   * 	- https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/currentSrc
   * 	- https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/src
   */
  if (!node.currentSrc) {
    return false;
  }

  /**
   * Ignore media nodes which are `paused` or `muted`
   */
  if (node.hasAttribute('paused') || node.hasAttribute('muted')) {
    return false;
  }

  return true;
}

export default noAutoplayAudioMatches;
