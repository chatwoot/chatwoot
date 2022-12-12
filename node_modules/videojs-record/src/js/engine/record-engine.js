/**
 * @file record-engine.js
 * @since 2.0.0
 */

import videojs from 'video.js';

import Event from '../event';
import {downloadBlob, addFileInfo} from '../utils/file-util';

const Component = videojs.getComponent('Component');

// supported recorder plugin engines
// builtin
const RECORDRTC = 'recordrtc';

// audio
const LIBVORBISJS = 'libvorbis.js';
const RECORDERJS = 'recorder.js';
const LAMEJS = 'lamejs';
const OPUSRECORDER = 'opus-recorder';
const OPUSMEDIARECORDER = 'opus-media-recorder';
const VMSG = 'vmsg';

// video
const WEBMWASM = 'webm-wasm';

// all audio plugins
const AUDIO_PLUGINS = [
    LIBVORBISJS, RECORDERJS, LAMEJS, OPUSRECORDER, OPUSMEDIARECORDER, VMSG
];

// all video plugins
const VIDEO_PLUGINS = [WEBMWASM];

// all record plugins
const RECORD_PLUGINS = AUDIO_PLUGINS.concat(VIDEO_PLUGINS);


/**
 * Base class for recorder backends.
 * @class
 * @augments videojs.Component
 */
class RecordEngine extends Component {
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
        // auto mixin the evented mixin (required since video.js v6.6.0)
        options.evented = true;

        super(player, options);
    }

    /**
     * Remove any temporary data and references to streams.
     * @private
     */
    dispose() {
        // dispose previous recording
        if (this.recordedData !== undefined) {
            URL.revokeObjectURL(this.recordedData);
        }
    }

    /**
     * Destroy engine.
     */
    destroy() {}

    /**
     * Add filename and timestamp to recorded file object.
     *
     * @param {(Blob|File)} fileObj - Blob or File object to modify.
     */
    addFileInfo(fileObj) {
        addFileInfo(fileObj);
    }

    /**
     * Invoked when recording is stopped and resulting stream is available.
     *
     * @param {blob} data - Reference to the recorded `Blob`.
     * @private
     */
    onStopRecording(data) {
        this.recordedData = data;

        // add filename and timestamp to recorded file object
        this.addFileInfo(this.recordedData);

        // remove reference to recorded stream
        this.dispose();

        // notify listeners
        this.trigger(Event.RECORD_COMPLETE);
    }

    /**
     * Show save as dialog in browser so the user can store the recorded
     * media locally.
     *
     * @param {Object} name - Object with names for the particular blob(s)
     *     you want to save. File extensions are added automatically. For
     *     example: {'video': 'name-of-video-file'}. Supported keys are
     *     'audio', 'video' and 'gif'.
     * @example
     * // save recorded video file as 'foo.webm'
     * player.record().saveAs({'video': 'foo'});
     * @returns {void}
     */
    saveAs(name) {
        let fileName = name[Object.keys(name)[0]];

        // download recorded file
        downloadBlob(fileName, this.recordedData);
    }
}

// expose component for external plugins
videojs.RecordEngine = RecordEngine;
Component.registerComponent('RecordEngine', RecordEngine);

export {
    RecordEngine, RECORD_PLUGINS, AUDIO_PLUGINS, VIDEO_PLUGINS,
    RECORDRTC, LIBVORBISJS, RECORDERJS, LAMEJS, OPUSRECORDER,
    OPUSMEDIARECORDER, VMSG, WEBMWASM
};
