/**
 * @typedef {Object} MediaSessionPluginParams
 * @property {MediaMetadata} metadata A MediaMetadata object: a representation
 * of the metadata associated with a MediaSession that can be used by user agents
 * to provide a customized user interface.
 * @property {?boolean} deferInit Set to true to manually call
 * `initPlugin('mediasession')`
 */

/**
 * Visualize MediaSession information for a wavesurfer instance.
 *
 * @implements {PluginClass}
 * @extends {Observer}
 * @example
 * // es6
 * import MediaSessionPlugin from 'wavesurfer.mediasession.js';
 *
 * // commonjs
 * var MediaSessionPlugin = require('wavesurfer.mediasession.js');
 *
 * // if you are using <script> tags
 * var MediaSessionPlugin = window.WaveSurfer.mediasession;
 *
 * // ... initialising wavesurfer with the plugin
 * var wavesurfer = WaveSurfer.create({
 *   // wavesurfer options ...
 *   plugins: [
 *     MediaSessionPlugin.create({
 *       // plugin options ...
 *     })
 *   ]
 * });
 */
export default class MediaSessionPlugin {
    /**
     * MediaSession plugin definition factory
     *
     * This function must be used to create a plugin definition which can be
     * used by wavesurfer to correctly instantiate the plugin.
     *
     * @param  {MediaSessionPluginParams} params parameters use to initialise the plugin
     * @return {PluginDefinition} an object representing the plugin
     */
    static create(params) {
        return {
            name: 'mediasession',
            deferInit: params && params.deferInit ? params.deferInit : false,
            params: params,
            instance: MediaSessionPlugin
        };
    }

    constructor(params, ws) {
        this.params = params;
        this.wavesurfer = ws;

        if ('mediaSession' in navigator) {
            // update metadata
            this.metadata = this.params.metadata;
            this.update();

            // update metadata when playback starts
            this.wavesurfer.on('play', () => {
                this.update();
            });

            // set playback action handlers
            navigator.mediaSession.setActionHandler('play', () => {
                this.wavesurfer.play();
            });
            navigator.mediaSession.setActionHandler('pause', () => {
                this.wavesurfer.playPause();
            });
            navigator.mediaSession.setActionHandler('seekbackward', () => {
                this.wavesurfer.skipBackward();
            });
            navigator.mediaSession.setActionHandler('seekforward', () => {
                this.wavesurfer.skipForward();
            });
        }
    }

    init() {}

    destroy() {}

    update() {
        if (typeof MediaMetadata === typeof Function) {
            // set metadata
            navigator.mediaSession.metadata = new MediaMetadata(this.metadata);
        }
    }
}
