/**
 * @file lamejs-plugin.js
 * @since 1.1.0
 */

import videojs from 'video.js';

const RecordEngine = videojs.getComponent('RecordEngine');

/**
 * Audio-only engine for the lamejs library.
 *
 * @class
 * @augments RecordEngine
 */
class LamejsEngine extends RecordEngine {
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
         * Specifies the sample rate to encode at.
         *
         * @type {number}
         */
        this.sampleRate = 44100;
        /**
         * Specifies the bitrate in kbps.
         *
         * @type {number}
         */
        this.bitRate = 128;
        /**
         * Path to `worker-realtime.js` worker script.
         *
         * @type {string}
         */
        this.audioWorkerURL = 'worker-realtime.js';
        /**
         * Mime-type for audio output.
         *
         * @type {string}
         */
        this.audioType = 'audio/mpeg';
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

        this.config = {
            debug: this.debug,
            sampleRate: this.sampleRate,
            bitRate: this.bitRate
        };

        this.engine = new Worker(this.audioWorkerURL);
        this.engine.onmessage = this.onWorkerMessage.bind(this);
        this.engine.postMessage({cmd: 'init', config: this.config});
    }

    /**
     * Start recording.
     */
    start() {
        let AudioContext = window.AudioContext || window.webkitAudioContext;
        this.audioContext = new AudioContext();

        this.audioSourceNode = this.audioContext.createMediaStreamSource(
            this.inputStream);
        // a bufferSize of 0 instructs the browser to choose the best bufferSize
        this.processor = this.audioContext.createScriptProcessor(
            0, 1, 1);
        this.processor.onaudioprocess = this.onAudioProcess.bind(this);
        this.audioSourceNode.connect(this.processor);
        this.processor.connect(this.audioContext.destination);
    }

    /**
     * Stop recording.
     */
    stop() {
        if (this.processor && this.audioSourceNode) {
            this.audioSourceNode.disconnect();
            this.processor.disconnect();
            this.processor.onaudioprocess = null;
        }
        if (this.audioContext) {
            // ignore errors about already being closed
            this.audioContext.close().then(() => {}).catch((reason) => {});
        }

        // free up memory
        this.engine.postMessage({cmd: 'finish'});
    }

    /**
     * Received a message from the worker.
     *
     * @private
     * @param {Object} ev - Worker responded with event object.
     */
    onWorkerMessage(ev) {
        switch (ev.data.cmd) {
            case 'end':
                this.onStopRecording(new Blob(ev.data.buf,
                    {type: this.audioType}));
                break;

            case 'error':
                this.player().trigger('error', ev.data.error);
                break;

            default:
                // invalid message received
                this.player().trigger('error', ev.data);
                break;
        }
    }

    /**
     * Continuous encoding of audio data.
     *
     * @private
     * @param {Object} ev - onaudioprocess responded with data object.
     */
    onAudioProcess(ev) {
        // send microphone data to LAME for MP3 encoding while recording
        let data = ev.inputBuffer.getChannelData(0);

        this.engine.postMessage({cmd: 'encode', buf: data});
    }
}

// expose plugin
videojs.LamejsEngine = LamejsEngine;

export default LamejsEngine;
