/**
 * @file convert-engine.js
 * @since 3.3.0
 */

import videojs from 'video.js';

import {blobToArrayBuffer, addFileInfo, downloadBlob} from '../utils/file-util';

const Component = videojs.getComponent('Component');

// supported convert plugin engines
const TSEBML = 'ts-ebml';
const FFMPEGJS = 'ffmpeg.js';
const FFMPEGWASM = 'ffmpeg.wasm';

// all convert plugins
const CONVERT_PLUGINS = [TSEBML, FFMPEGJS, FFMPEGWASM];

/**
 * Base class for converter backends.
 * @class
 * @augments videojs.Component
 */
class ConvertEngine extends Component {
    /**
     * Creates an instance of this class.
     *
     * @param  {Player} player - The `Player` that this class should be
     *     attached to.
     * @param  {Object} [options] - The key/value store of player options.
     */
    constructor(player, options) {
        // auto mixin the evented mixin (required since video.js v6.6.0)
        options.evented = true;

        super(player, options);
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
    }

    /**
     * Load `Blob` and return `Promise`.
     *
     * @param {Blob} data - `Blob` to load.
     * @returns {Promise} - Promise with `ArrayBuffer` data.
     */
    loadBlob(data) {
        return blobToArrayBuffer(data);
    }

    /**
     * Add filename and timestamp to converted file object.
     *
     * @param {(Blob|File)} fileObj - `Blob` or `File` object to modify.
     * @param {date} [now] - Optional date information, default is
     *    current timestamp.
     */
    addFileInfo(fileObj, now) {
        addFileInfo(fileObj, now);
    }

    /**
     * Show save as dialog in browser so the user can store the converted
     * media locally.
     *
     * @param {Object} name - Object with names for the particular blob(s)
     *     you want to save. File extensions are added automatically. For
     *     example: {'video': 'name-of-video-file'}. Supported keys are
     *     'audio', 'video' and 'gif'.
     */
    saveAs(name) {
        let fileName = name[Object.keys(name)[0]];

        // download converted file
        downloadBlob(fileName, this.player().convertedData);
    }
}

// expose component for external plugins
videojs.ConvertEngine = ConvertEngine;
Component.registerComponent('ConvertEngine', ConvertEngine);

export {
    ConvertEngine, CONVERT_PLUGINS, TSEBML, FFMPEGJS, FFMPEGWASM
};
