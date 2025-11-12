/**
 * @file ffmpegjs-plugin.js
 * @since 3.8.0
 */

import videojs from 'video.js';

const ConvertEngine = videojs.getComponent('ConvertEngine');

/**
 * Converter engine using the ffmpeg.js library.
 *
 * Deprecated. Use the ffmpeg.wasm plugin instead.
 *
 * @class
 * @augments videojs.ConvertEngine
 */
class FFmpegjsEngine extends ConvertEngine {
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
         * Path to worker script `ffmpeg-worker-mp4.js` (H.264 & AAC & MP3 encoders)
         * or `ffmpeg-worker-webm.js` (VP8 & Opus encoders).
         *
         * @type {string}
         */
        this.convertWorkerURL = 'ffmpeg-worker-mp4.js';
        /**
         * Mime-type for output.
         *
         * @type {string}
         */
        this.outputType = null;
        /**
         * Additional configuration options for the ffmpeg.js library.
         *
         * @type {object}
         */
        this.pluginLibraryOptions = {};
    }

    /**
     * Setup recording engine.
     *
     * @param {Object} mediaType - Object describing the media type of this
     *     engine.
     * @param {Boolean} debug - Indicating whether or not debug messages should
     *     be printed in the console.
     */
    setup(mediaType, debug) {
        this.mediaType = mediaType;
        this.debug = debug;
        this.stdout = this.stderr = '';

        // set output mime type
        if (this.pluginLibraryOptions.outputType === undefined) {
            throw new Error('no outputType specified!');
        }
        this.outputType = this.pluginLibraryOptions.outputType;

        // setup worker
        this.engine = new Worker(this.convertWorkerURL);
        this.engine.onmessage = this.onWorkerMessage.bind(this);
    }

    /**
     * Invoked when recording is stopped and resulting stream is available.
     *
     * @param {blob} data - Reference to the recorded `Blob` that needs to be
     *     converted.
     */
    convert(data) {
        // save timestamp
        this.timestamp = new Date();
        this.timestamp.setTime(data.lastModified);

        // load and convert blob
        this.loadBlob(data).then((buffer) => {
            // specify input
            let opts = ['-i', data.name];

            // add ffmpeg options
            opts = opts.concat(this.convertOptions);

            // use a temporary name
            opts.push('output_' + this.timestamp.getTime());

            // start conversion
            this.engine.postMessage({
                type: 'run',
                MEMFS: [{name: data.name, data: buffer}],
                arguments: opts
            });
        });
    }

    /**
     * Received a message from the worker.
     *
     * @param {Object} event - Event containing converted data.
     * @private
     */
    onWorkerMessage(event) {
        let msg = event.data;
        switch (msg.type) {
            // worker loaded and ready to accept commands
            case 'ready':
                break;

            // worker started job
            case 'run':
                // notify listeners
                this.player().trigger('startConvert');
                break;

            // job finished with some result
            case 'done':
                // converted data
                let buf;
                try {
                    buf = msg.data.MEMFS[0].data;
                } catch (e) {
                    this.player().trigger('error', this.stderr);
                }

                // store in blob
                let result = new Blob(buf, {type: this.outputType});

                // inject date and name into blob
                this.addFileInfo(result, this.timestamp);

                // store result
                this.player().convertedData = result;

                // notify listeners
                this.player().trigger('finishConvert');
                break;

            // FFmpeg printed to stdout
            case 'stdout':
                this.stdout += msg.data + '\n';
                break;

            // FFmpeg printed to stderr
            case 'stderr':
                this.stderr += msg.data + "\n";
                break;

            // FFmpeg exited
            case 'exit':
                break;

            // FFmpeg terminated abnormally (e.g. out of memory, wasm error)
            case 'abort':
            case 'error':
                this.player().trigger('error', msg.data);
                break;
        }
    }
}

// expose plugin
videojs.FFmpegjsEngine = FFmpegjsEngine;

export default FFmpegjsEngine;
