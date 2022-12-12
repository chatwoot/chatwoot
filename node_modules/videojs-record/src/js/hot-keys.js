/**
 * @file hot-keys.js
 * @since 3.6.0
 */

import {IMAGE_ONLY} from './engine/record-mode';

// check https://github.com/timoxley/keycode for codes
const X_KEY = 88;
const P_KEY = 80;
const C_KEY = 67;

/**
 * Default keyhandler.
 *
 * @param {object} event - Event containing key info.
 * @returns {void}
 * @private
 */
const defaultKeyHandler = function(event) {
    switch (event.which) {
        // 'x' key
        case X_KEY:
            // toggle record
            switch (this.player_.record().getRecordType()) {
                case IMAGE_ONLY:
                    this.player_.cameraButton.trigger('click');
                    break;

                default:
                    this.player_.recordToggle.trigger('click');
            }
            break;

        // 'p' key
        case P_KEY:
            // toggle picture-in-picture (if enabled)
            if (this.player_.record().pictureInPicture === true) {
                this.player_.pipToggle.trigger('click');
            }
            break;

        // 'c' key
        case C_KEY:
            // toggle playback
            if (this.player_.controlBar.playToggle &&
                this.player_.controlBar.playToggle.contentEl()) {
                player.controlBar.playToggle.trigger('click');
            }
            break;
    }
};

export default defaultKeyHandler;
