/**
 * @file recorderjs-plugin.js
 * @since 1.1.0
 */

import videojs from 'video.js';

const RecordEngine = videojs.getComponent('RecordEngine');

/**
 * Audio-only engine for the recorder.js library.
 *
 * @class
 * @augments RecordEngine
 */
class RecorderjsEngine extends RecordEngine {
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
         * The number of channels to record. 1 = mono, 2 = stereo.
         * Maximum 2 channels are supported.
         *
         * @type {number}
         */
        this.audioChannels = 2;
        /**
         * The length of the buffer that the internal `JavaScriptNode`
         * uses to capture the audio. Can be tweaked if experiencing
         * performance issues.
         *
         * @type {number}
         */
        this.bufferSize = 4096;
        /**
         * Mime-type for audio output.
         *
         * @type {string}
         */
        this.audioType = 'audio/wav';
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

        let AudioContext = window.AudioContext || window.webkitAudioContext;
        this.audioContext = new AudioContext();
        this.audioSourceNode = this.audioContext.createMediaStreamSource(
            this.inputStream);

        // setup recorder.js
        this.engine = new Recorder(this.audioSourceNode, {
            bufferLen: this.bufferSize,
            numChannels: this.audioChannels,
            type: this.audioType
        });
    }

    /**
     * Start recording.
     */
    start() {
        this.engine.record();
    }

    /**
     * Stop recording.
     */
    stop() {
        this.engine.stop();

        if (this.engine.exportWAV !== undefined) {
            this.engine.exportWAV(this.onStopRecording.bind(this));
        }
        if (this.engine.clear !== undefined) {
            this.engine.clear();
        }
    }
}

// expose plugin
videojs.RecorderjsEngine = RecorderjsEngine;

export default RecorderjsEngine;
