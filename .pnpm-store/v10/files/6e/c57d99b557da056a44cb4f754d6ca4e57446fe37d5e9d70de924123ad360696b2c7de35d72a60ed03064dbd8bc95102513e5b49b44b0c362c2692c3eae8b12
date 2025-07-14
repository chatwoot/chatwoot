import videojs from 'video.js';

const defaultOptions = {
  errorInterval: 30,
  getSource(next) {
    const tech = this.tech({ IWillNotUseThisInPlugins: true });
    const sourceObj = tech.currentSource_ || this.currentSource();

    return next(sourceObj);
  }
};

/**
 * Main entry point for the plugin
 *
 * @param {Player} player a reference to a videojs Player instance
 * @param {Object} [options] an object with plugin options
 * @private
 */
const initPlugin = function(player, options) {
  let lastCalled = 0;
  let seekTo = 0;
  const localOptions = videojs.mergeOptions(defaultOptions, options);

  player.ready(() => {
    player.trigger({type: 'usage', name: 'vhs-error-reload-initialized'});
    player.trigger({type: 'usage', name: 'hls-error-reload-initialized'});
  });

  /**
   * Player modifications to perform that must wait until `loadedmetadata`
   * has been triggered
   *
   * @private
   */
  const loadedMetadataHandler = function() {
    if (seekTo) {
      player.currentTime(seekTo);
    }
  };

  /**
   * Set the source on the player element, play, and seek if necessary
   *
   * @param {Object} sourceObj An object specifying the source url and mime-type to play
   * @private
   */
  const setSource = function(sourceObj) {
    if (sourceObj === null || sourceObj === undefined) {
      return;
    }
    seekTo = (player.duration() !== Infinity && player.currentTime()) || 0;

    player.one('loadedmetadata', loadedMetadataHandler);

    player.src(sourceObj);
    player.trigger({type: 'usage', name: 'vhs-error-reload'});
    player.trigger({type: 'usage', name: 'hls-error-reload'});
    player.play();
  };

  /**
   * Attempt to get a source from either the built-in getSource function
   * or a custom function provided via the options
   *
   * @private
   */
  const errorHandler = function() {
    // Do not attempt to reload the source if a source-reload occurred before
    // 'errorInterval' time has elapsed since the last source-reload
    if (Date.now() - lastCalled < localOptions.errorInterval * 1000) {
      player.trigger({type: 'usage', name: 'vhs-error-reload-canceled'});
      player.trigger({type: 'usage', name: 'hls-error-reload-canceled'});
      return;
    }

    if (!localOptions.getSource ||
        typeof localOptions.getSource !== 'function') {
      videojs.log.error('ERROR: reloadSourceOnError - The option getSource must be a function!');
      return;
    }
    lastCalled = Date.now();

    return localOptions.getSource.call(player, setSource);
  };

  /**
   * Unbind any event handlers that were bound by the plugin
   *
   * @private
   */
  const cleanupEvents = function() {
    player.off('loadedmetadata', loadedMetadataHandler);
    player.off('error', errorHandler);
    player.off('dispose', cleanupEvents);
  };

  /**
   * Cleanup before re-initializing the plugin
   *
   * @param {Object} [newOptions] an object with plugin options
   * @private
   */
  const reinitPlugin = function(newOptions) {
    cleanupEvents();
    initPlugin(player, newOptions);
  };

  player.on('error', errorHandler);
  player.on('dispose', cleanupEvents);

  // Overwrite the plugin function so that we can correctly cleanup before
  // initializing the plugin
  player.reloadSourceOnError = reinitPlugin;
};

/**
 * Reload the source when an error is detected as long as there
 * wasn't an error previously within the last 30 seconds
 *
 * @param {Object} [options] an object with plugin options
 */
const reloadSourceOnError = function(options) {
  initPlugin(this, options);
};

export default reloadSourceOnError;
