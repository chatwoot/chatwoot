/**
 * @file record-mode.js
 * @since 2.0.0
 */

// recorder modes
const IMAGE_ONLY = 'image_only';
const AUDIO_ONLY = 'audio_only';
const VIDEO_ONLY = 'video_only';
const AUDIO_VIDEO = 'audio_video';
const AUDIO_SCREEN = 'audio_screen';
const ANIMATION = 'animation';
const SCREEN_ONLY = 'screen_only';


const getRecorderMode = function(image, audio, video, animation, screen) {
    if (isModeEnabled(image)) {
        return IMAGE_ONLY;

    } else if (isModeEnabled(animation)) {
        return ANIMATION;

    } else if (isModeEnabled(audio) && isModeEnabled(video)) {
        return AUDIO_VIDEO;

    } else if (isModeEnabled(audio) && isModeEnabled(screen)) {
        return AUDIO_SCREEN;

    } else if (!isModeEnabled(audio) && isModeEnabled(screen)) {
        return SCREEN_ONLY;

    } else if (isModeEnabled(audio) && !isModeEnabled(video)) {
        return AUDIO_ONLY;

    } else if (!isModeEnabled(audio) && isModeEnabled(video)) {
        return VIDEO_ONLY;
    }
};

/**
 * Check whether mode is enabled or not.
 *
 * @param {(Object|Boolean)} mode - Mode.
 * @returns {Boolean} Return boolean indicating whether mode is enabled or not.
 * @private
 */
const isModeEnabled = function(mode) {
    return mode === Object(mode) || mode === true;
};

export {
    getRecorderMode,
    IMAGE_ONLY, AUDIO_ONLY, VIDEO_ONLY, AUDIO_VIDEO, ANIMATION, SCREEN_ONLY, AUDIO_SCREEN
};
