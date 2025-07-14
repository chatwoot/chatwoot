/**
 * @file opus-recorder-plugin.js
 * @since 1.1.0
 */

import videojs from 'video.js';

const RecordEngine = videojs.getComponent('RecordEngine');

/**
 * Audio-only engine for the opus-recorder library.
 *
 * Audio is encoded using libopus.
 *
 * @class
 * @augments RecordEngine
 */
class OpusRecorderEngine extends RecordEngine {
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
        this.audioChannels = 1;
        /**
         * The length of the buffer that the internal `JavaScriptNode`
         * uses to capture the audio. Can be tweaked if experiencing
         * performance issues.
         *
         * @type {number}
         */
        this.bufferSize = 4096;
        /**
         * Specifies the sample rate to encode at. Supported values are
         * 8000, 12000, 16000, 24000 or 48000.
         *
         * @type {number}
         */
        this.sampleRate = 48000;
        /**
         * Path to `encoderWorker.min.js` or `waveWorker.min.js` worker
         * script.
         *
         * @type {string}
         */
        this.audioWorkerURL = 'encoderWorker.min.js';
        /**
         * Mime-type for audio output. Also supports `audio/wav`; but make sure
         * to use waveEncoder worker in that case.
         *
         * @type {string}
         */
        this.audioType = 'audio/ogg';
        /**
         * Additional configuration options for the opus-recorder library.
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

        // create new AudioContext
        let AudioContext = window.AudioContext || window.webkitAudioContext;
        this.audioContext = new AudioContext();
        this.audioSourceNode = this.audioContext.createMediaStreamSource(
            this.inputStream);

        // minimal default config
        this.config = {
            numberOfChannels: this.audioChannels,
            bufferLength: this.bufferSize,
            encoderSampleRate: this.sampleRate,
            encoderPath: this.audioWorkerURL,
            sourceNode: this.audioSourceNode
        };

        // extend config with optional options
        this.config = Object.assign(this.config, this.pluginLibraryOptions);

        // create Recorder engine
        this.engine = new Recorder(this.config);
        this.engine.ondataavailable = this.onRecordingAvailable.bind(this);
    }

    /**
     * Start recording.
     */
    start() {
        this.engine.start().then(() => {
            // recording started ok
        }).catch((err) => {
            // can't start playback
            this.player().trigger('error', err);
        });
    }

    /**
     * Stop recording.
     */
    stop() {
        this.engine.stop();
    }

    /**
     * Pause recording.
     */
    pause() {
        this.engine.pause();
    }

    /**
     * Resume recording.
     */
    resume() {
        this.engine.resume();
    }

    /**
     * @private
     * @param {Object} data - Audio data returned by opus-recorder.
     */
    onRecordingAvailable(data) {
        // Opus format stored in an Ogg container
        let blob = new Blob([data], {type: this.audioType});

        this.onStopRecording(blob);
    }
}

// expose plugin
videojs.OpusRecorderEngine = OpusRecorderEngine;

export default OpusRecorderEngine;
