/**
 * @file webm-wasm-plugin.js
 * @since 3.5.0
 */

import videojs from 'video.js';
import RecordRTC from 'recordrtc';

const RecordRTCEngine = videojs.getComponent('RecordRTCEngine');

/**
 * Video engine plugin for the webm-wasm library.
 *
 * @class
 * @augments videojs.RecordRTCEngine
 */
class WebmWasmEngine extends RecordRTCEngine {
    /**
     * Creates an instance of this class.
     *
     * @param  {Player} player
     *         The `Player` that this class should be attached to.
     *
     * @param  {Object} [options]
     *         The key/value store of player options.
     */
    constructor(player, options) {
        super(player, options);

        /**
         * Enables console logging for debugging purposes.
         *
         * @type {boolean}
         */
        this.debug = false;
        /**
         * Video bitrate in kbps.
         *
         * @type {number}
         */
        this.videoBitRate = 1200;
        /**
         * Video frame rate in fps.
         *
         * @type {number}
         */
        this.videoFrameRate = 30;
        /**
         * Path to `webm-worker.js` worker script.
         *
         * @type {string}
         */
        this.videoWorkerURL = 'webm-worker.js';
        /**
         * Path to `webm-wasm.wasm` WebAssembly script.
         *
         * @type {string}
         */
        this.videoWebAssemblyURL = 'webm-wasm.wasm';
    }

    /**
     * Setup recording engine.
     *
     * @param {LocalMediaStream} stream - Media stream to record.
     * @param {Object} mediaType - Object describing the media type of this
     *     engine.
     * @param {Boolean} debug - Indicating whether or not debug messages should
     *     be printed in the console.
     */
    setup(stream, mediaType, debug) {
        // set options
        this.recorderType = RecordRTC.WebAssemblyRecorder;
        this.workerPath = this.videoWorkerURL;
        this.bitRate = this.videoBitRate;
        this.frameRate = this.videoFrameRate;

        super.setup(stream, mediaType, debug);
    }
}

// expose plugin
videojs.WebmWasmEngine = WebmWasmEngine;

export default WebmWasmEngine;
