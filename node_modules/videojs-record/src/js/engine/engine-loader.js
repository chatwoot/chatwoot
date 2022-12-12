/**
 * @file engine-loader.js
 * @since 3.3.0
 */

import videojs from 'video.js';

import RecordRTCEngine from './record-rtc';
import {CONVERT_PLUGINS, TSEBML, FFMPEGJS, FFMPEGWASM} from './convert-engine';
import {RECORDRTC, LIBVORBISJS, RECORDERJS, LAMEJS, OPUSRECORDER, OPUSMEDIARECORDER, VMSG, WEBMWASM, AUDIO_PLUGINS} from './record-engine';

/**
 * Get audio plugin engine class.
 *
 * @private
 * @param {String} audioEngine - Name of the audio engine.
 * @returns {Object} Audio engine class.
 */
const getAudioEngine = function(audioEngine) {
    let AudioEngineClass;
    switch (audioEngine) {
        case RECORDRTC:
            // RecordRTC.js (default)
            AudioEngineClass = RecordRTCEngine;
            break;

        case LIBVORBISJS:
            // libvorbis.js
            AudioEngineClass = videojs.LibVorbisEngine;
            break;

        case RECORDERJS:
            // recorder.js
            AudioEngineClass = videojs.RecorderjsEngine;
            break;

        case LAMEJS:
            // lamejs
            AudioEngineClass = videojs.LamejsEngine;
            break;

        case OPUSRECORDER:
            // opus-recorder
            AudioEngineClass = videojs.OpusRecorderEngine;
            break;

        case OPUSMEDIARECORDER:
            // opus-media-recorder
            AudioEngineClass = videojs.OpusMediaRecorderEngine;
            break;

        case VMSG:
            // vmsg
            AudioEngineClass = videojs.VmsgEngine;
            break;

        default:
            // unknown engine
            throw new Error('Unknown audioEngine: ' + audioEngine);
    }
    return AudioEngineClass;
};


/**
 * Get video plugin engine class.
 *
 * @private
 * @param {String} videoEngine - Name of the video engine.
 * @returns {Object} Video engine class.
 */
const getVideoEngine = function(videoEngine) {
    let VideoEngineClass;
    switch (videoEngine) {
        case RECORDRTC:
            // RecordRTC.js (default)
            VideoEngineClass = RecordRTCEngine;
            break;

        case WEBMWASM:
            // webm-wasm
            VideoEngineClass = videojs.WebmWasmEngine;
            break;

        default:
            // unknown engine
            throw new Error('Unknown videoEngine: ' + videoEngine);
    }
    return VideoEngineClass;
};

/**
 * Check whether any audio record plugins are enabled.
 *
 * @private
 * @param {String} audioEngine - Name of the audio engine.
 * @returns {Boolean} Whether any audio plugins are enabled or not.
 */
const isAudioPluginActive = function(audioEngine) {
    return AUDIO_PLUGINS.indexOf(audioEngine) > -1;
};

/**
 * Get converter plugin engine class.
 *
 * @private
 * @param {String} convertEngine - Name of the convert engine.
 * @returns {Object} Convert engine class.
 */
const getConvertEngine = function(convertEngine) {
    let ConvertEngineClass;
    switch (convertEngine) {
        case '':
            // disabled (default)
            break;

        case TSEBML:
            // ts-ebml
            ConvertEngineClass = videojs.TsEBMLEngine;
            break;

        case FFMPEGJS:
            // ffmpeg.js
            ConvertEngineClass = videojs.FFmpegjsEngine;
            break;

        case FFMPEGWASM:
            // ffmpeg.wasm
            ConvertEngineClass = videojs.FFmpegWasmEngine;
            break;

        default:
            // unknown engine
            throw new Error('Unknown convertEngine: ' + convertEngine);
    }
    return ConvertEngineClass;
};

export {
    getAudioEngine, isAudioPluginActive, getVideoEngine, getConvertEngine
};
