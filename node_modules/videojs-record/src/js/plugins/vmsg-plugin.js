/**
 * @file vmsg-plugin.js
 * @since 3.3.0
 */

import videojs from 'video.js';

import {Recorder} from 'vmsg';

const RecordEngine = videojs.getComponent('RecordEngine');

/**
 * Audio-only engine for the vmsg library.
 *
 * @class
 * @augments videojs.RecordEngine
 */
class VmsgEngine extends RecordEngine {
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
         * Path to `vmsg.wasm` WebAssembly script.
         *
         * @type {string}
         */
        this.audioWebAssemblyURL = 'vmsg.wasm';
        /**
         * Additional configuration options for the vmsg library.
         *
         * @type {object}
         */
        this.pluginLibraryOptions = {};
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
        this.inputStream = stream;
        this.mediaType = mediaType;
        this.debug = debug;

        // minimal default config
        this.config = {
            wasmURL: this.audioWebAssemblyURL
        };

        // extend config with optional options
        this.config = Object.assign(this.config, this.pluginLibraryOptions);

        this.engine = new Recorder(this.config,
            this.onRecordingAvailable.bind(this));
        this.engine.stream = this.inputStream;

        let AudioContext = window.AudioContext || window.webkitAudioContext;
        this.audioContext = new AudioContext();

        this.audioSourceNode = this.audioContext.createMediaStreamSource(
            this.inputStream);
        // a bufferSize of 0 instructs the browser to choose the best bufferSize
        this.processor = this.audioContext.createScriptProcessor(
            0, 1, 1);
        this.audioSourceNode.connect(this.processor);

        this.engine.initWorker().catch((err) => {
            // invalid message received
            this.player().trigger('error', err);
        });
    }

    /**
     * Start recording.
     */
    start() {
        this.engine.blob = null;
        if (this.engine.blobURL) {
            URL.revokeObjectURL(this.engine.blobURL);
        }
        this.engine.blobURL = null;

        this.engine.worker.postMessage({
            type: 'start',
            data: this.audioContext.sampleRate
        });
        this.processor.onaudioprocess = this.onAudioProcess.bind(this);
        this.processor.connect(this.audioContext.destination);
    }

    /**
     * Stop recording.
     */
    stop() {
        if (this.processor) {
            this.processor.disconnect();
            this.processor.onaudioprocess = null;
        }
        if (this.engine && this.engine.worker !== undefined) {
            this.engine.worker.postMessage({type: 'stop', data: null});
        }
    }

    /**
     * Destroy engine.
     */
    destroy() {
        if (this.engine && typeof this.engine.close === 'function') {
            this.engine.close();
        }
    }

    /**
     * Continuous encoding of audio data.
     * @private
     * @param {object} event - Audio buffer.
     */
    onAudioProcess(event) {
        const samples = event.inputBuffer.getChannelData(0);
        this.engine.worker.postMessage({type: 'data', data: samples});
    }

    /**
     * @private
     */
    onRecordingAvailable() {
        this.onStopRecording(this.engine.blob);
    }
}

// expose plugin
videojs.VmsgEngine = VmsgEngine;

export default VmsgEngine;
