/**
 * @file opus-media-recorder-plugin.js
 * @since 4.2.0
 */

import videojs from 'video.js';

const RecordEngine = videojs.getComponent('RecordEngine');

/**
 * Audio-only engine for the opus-media-recorder library.
 *
 * opus-media-recorder uses WebAssembly compiled from popular
 * libraries (e.g libopus, libogg, libwebm, and speexdsp) to
 * ensure good performance and standards-compliance.
 *
 * @class
 * @augments RecordEngine
 */
class OpusMediaRecorderEngine extends RecordEngine {
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
         * Mime-type for audio output.
         *
         * Choose desired format like `audio/webm`. Default is `audio/ogg`.
         *
         * @type {string}
         */
        this.audioType = 'audio/ogg';
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
        this.chunks = [];

        const workerOptions = this.audioWebAssemblyURL;
        workerOptions.encoderWorkerFactory = () => {
            return new Worker(this.audioWorkerURL);
        };

        this.recAvailableCallback = this.onData.bind(this);

        const recOptions = {mimeType: this.audioType};
        this.engine = new MediaRecorder(stream, recOptions, workerOptions);
        this.engine.onstop = this.onRecordingAvailable.bind(this);
    }

    /**
     * Start recording.
     */
    start() {
        this.chunks = [];
        this.engine.addEventListener('dataavailable', this.recAvailableCallback);

        const timeSliceMs = 60000;
        this.engine.start(timeSliceMs);
    }

    /**
     * Stop recording.
     */
    stop() {
        this.engine.stop();
    }

    /**
     * @private
     * @param {Object} event - ondataavailable responded with data object.
     */
    onData(event) {
        this.chunks.push(event.data);
    }

    /**
     * @private
     * @param {Object} event - Audio data returned by opus-media-recorder.
     */
    onRecordingAvailable(event) {
        this.engine.removeEventListener('dataavailable', this.recAvailableCallback);

        let blob = new Blob(this.chunks, {type: this.engine.mimeType});
        this.chunks = [];

        this.onStopRecording(blob);
    }
}

// expose plugin
videojs.OpusMediaRecorderEngine = OpusMediaRecorderEngine;

export default OpusMediaRecorderEngine;
