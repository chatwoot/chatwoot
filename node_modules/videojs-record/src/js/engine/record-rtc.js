/**
 * @file record-rtc.js
 * @since 2.0.0
 */

import videojs from 'video.js';

import RecordRTC from 'recordrtc';

import Event from '../event';
import {RecordEngine} from './record-engine';
import {isChrome} from '../utils/detect-browser';
import {IMAGE_ONLY, AUDIO_ONLY, VIDEO_ONLY, AUDIO_VIDEO, ANIMATION, SCREEN_ONLY, AUDIO_SCREEN} from './record-mode';

const Component = videojs.getComponent('Component');

/**
 * Engine used with the MRecordRTC class in the RecordRTC library.
 *
 * @class
 * @augments videojs.RecordEngine
 */
class RecordRTCEngine extends RecordEngine {

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

        if ('screen' in this.mediaType) {
            this.mediaType.video = true;
        }

        // recorder type
        if (this.recorderType !== undefined) {
            this.mediaType.video = this.recorderType;
        }

        // setup RecordRTC
        this.engine = new RecordRTC.MRecordRTC();
        this.engine.mediaType = this.mediaType;
        this.engine.disableLogs = !this.debug;
        this.engine.mimeType = this.mimeType;

        // audio settings
        this.engine.bufferSize = this.bufferSize;
        this.engine.sampleRate = this.sampleRate;
        this.engine.numberOfAudioChannels = this.audioChannels;

        // video/canvas settings
        this.engine.video = this.video;
        this.engine.canvas = this.canvas;
        this.engine.bitrate = this.bitRate;

        // animated gif settings
        this.engine.quality = this.quality;
        this.engine.frameRate = this.frameRate;

        // timeSlice option
        if (this.timeSlice !== undefined) {
            this.engine.timeSlice = this.timeSlice;
            this.engine.onTimeStamp = this.onTimeStamp.bind(this);
        }

        // worker
        this.engine.workerPath = this.workerPath;
        this.engine.webAssemblyPath = this.videoWebAssemblyURL;

        // connect stream to recording engine
        this.engine.addStream(this.inputStream);
    }

    /**
     * Remove any temporary data and references to streams.
     */
    dispose() {
        super.dispose();

        this.destroy();
    }

    /**
     * Destroy engine.
     */
    destroy() {
        if (this.engine && typeof this.engine.destroy === 'function') {
            this.engine.destroy();
        }
    }

    /**
     * Start recording.
     */
    start() {
        this.engine.startRecording();
    }

    /**
     * Stop recording. Result will be available async when onStopRecording
     * is called.
     */
    stop() {
        this.engine.stopRecording(this.onStopRecording.bind(this));
    }

    /**
     * Pause recording.
     */
    pause() {
        this.engine.pauseRecording();
    }

    /**
     * Resume recording.
     */
    resume() {
        this.engine.resumeRecording();
    }

    /**
     * Show save as dialog in browser so the user can store the recorded media
     * locally.
     *
     * @param {object} name - Object with names for the particular blob(s)
     *     you want to save. File extensions are added automatically. For
     *     example: {'video': 'name-of-video-file'}. Supported keys are
     *     'audio', 'video' and 'gif'.
     * @example
     * // save video file as 'foo.webm'
     * player.record().saveAs({'video': 'foo'});
     */
    saveAs(name) {
        if (this.engine && name !== undefined) {
            this.engine.save(name);
        }
    }

    /**
     * Invoked when recording is stopped and resulting stream is available.
     *
     * @private
     * @param {string} audioVideoURL - URI of the recorded Blob
     *     object, e.g. 'blob:http://localhost:8080/10100016-4248-9949-b0d6-0bb40db56eba'
     * @param {string} type - Media type, eg. 'video' or 'audio'.
     */
    onStopRecording(audioVideoURL, type) {
        // garbage collect unused blob
        URL.revokeObjectURL(audioVideoURL);

        // store reference to recorded stream data
        let recordType = this.player().record().getRecordType();
        this.engine.getBlob((recording) => {
            switch (recordType) {
                case AUDIO_ONLY:
                    if (recording.audio !== undefined) {
                        this.recordedData = recording.audio;
                    }
                    break;

                case VIDEO_ONLY:
                case AUDIO_VIDEO:
                case AUDIO_SCREEN:
                case SCREEN_ONLY:
                    // recordrtc returns a single blob that includes both audio
                    // and video data
                    if (recording.video !== undefined) {
                        this.recordedData = recording.video;
                    }
                    break;

                case ANIMATION:
                    if (recording.gif !== undefined) {
                        this.recordedData = recording.gif;
                    }
                    break;
            }
            // inject file info
            this.addFileInfo(this.recordedData);

            // notify listeners
            this.trigger(Event.RECORD_COMPLETE);
        });
    }

    /**
     * Received new timestamp (when timeSlice option is enabled).
     * @private
     * @param {float} current - Current timestamp.
     * @param {array} all - List of timestamps so far.
     */
    onTimeStamp(current, all) {
        this.player().currentTimestamp = current;
        this.player().allTimestamps = all;

        // get blob (only for MediaStreamRecorder)
        let internal;
        switch (this.player().record().getRecordType()) {
            case AUDIO_ONLY:
                internal = this.engine.audioRecorder;
                break;

            case ANIMATION:
                internal = this.engine.gifRecorder;
                break;

            default:
                internal = this.engine.videoRecorder;
        }

        let maxFileSizeReached = false;
        if (internal) {
            internal = internal.getInternalRecorder();
        }

        if ((internal instanceof RecordRTC.MediaStreamRecorder) === true) {
            this.player().recordedData = internal.getArrayOfBlobs();

            // inject file info for newest blob
            this.addFileInfo(
                this.player().recordedData[this.player_.recordedData.length - 1]);

            // check max file size
            if (this.maxFileSize > 0) {
                let currentSize = new Blob(this.player().recordedData).size;
                if (currentSize >= this.maxFileSize) {
                    maxFileSizeReached = true;
                }
            }
        }

        // notify others
        this.player().trigger(Event.TIMESTAMP);

        // automatically stop when max file size was reached
        if (maxFileSizeReached) {
            this.player().record().stop();
        }
    }
}

// expose plugin
videojs.RecordRTCEngine = RecordRTCEngine;

Component.registerComponent('RecordRTCEngine', RecordRTCEngine);

export default RecordRTCEngine;
