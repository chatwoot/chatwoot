/**
 * @file picture-in-picture-toggle.js
 * @since 3.5.0
 */

import videojs from 'video.js';

import Event from '../event';

const Button = videojs.getComponent('Button');
const Component = videojs.getComponent('Component');

/**
 * Button to toggle Picture-in-Picture mode.
 *
 * @class
 * @augments videojs.Button
*/
class PictureInPictureToggle extends Button {
    /**
     * The constructor function for the class.
     *
     * @private
     * @param {(videojs.Player|Object)} player - Video.js player instance.
     * @param {Object} options - Player options.
     */
    constructor(player, options) {
        super(player, options);

        // listen for events
        this.on(this.player_, Event.ENTER_PIP, this.onStart);
        this.on(this.player_, Event.LEAVE_PIP, this.onStop);
    }

    /**
     * Builds the default DOM `className`.
     *
     * @return {string}
     *         The DOM `className` for this object.
     */
    buildCSSClass() {
        return 'vjs-pip-button vjs-control vjs-button vjs-icon-picture-in-picture-start';
    }

    /**
     * Show the `PictureInPictureToggle` element if it is hidden by removing the
     * 'vjs-hidden' class name from it.
     */
    show() {
        if (this.layoutExclude && this.layoutExclude === true) {
            // ignore
            return;
        }
        super.show();
    }

    /**
     * This gets called when the button is clicked.
     *
     * @param {EventTarget~Event} event
     *        The `tap` or `click` event that caused this function to be
     *        called.
     *
     * @listens tap
     * @listens click
     */
    async handleClick(event) {
        let recorder = this.player_.record();

        // disable button during picture-in-picture switch
        this.disable();

        // switch picture-in-picture mode
        try {
            if (recorder.mediaElement !== document.pictureInPictureElement) {
                // request picture-in-picture
                await recorder.mediaElement.requestPictureInPicture();
            } else {
                // exit picture-in-picture
                await document.exitPictureInPicture();
            }
        } catch (error) {
            // notify listeners
            this.player_.trigger(Event.ERROR, error);
        } finally {
            // switch completed
            this.enable();
        }
    }

    /**
     * Add the vjs-icon-picture-in-picture-stop class to the element so it can
     * change appearance.
     *
     * @param {EventTarget~Event} [event]
     *        The event that caused this function to run.
     *
     * @listens Player#enterPIP
     */
    onStart(event) {
        // replace element class so it can change appearance
        this.removeClass('vjs-icon-picture-in-picture-start');
        this.addClass('vjs-icon-picture-in-picture-stop');
    }

    /**
     * Add the vjs-icon-picture-in-picture-start class to the element so it can
     * change appearance.
     *
     * @param {EventTarget~Event} [event]
     *        The event that caused this function to run.
     *
     * @listens Player#leavePIP
     */
    onStop(event) {
        // replace element class so it can change appearance
        this.removeClass('vjs-icon-picture-in-picture-stop');
        this.addClass('vjs-icon-picture-in-picture-start');
    }
}

/**
 * The text that should display over the `PictureInPictureToggle`s controls.
 *
 * Added for localization.
 *
 * @type {string}
 * @private
 */
PictureInPictureToggle.prototype.controlText_ = 'Picture in Picture';

Component.registerComponent('PictureInPictureToggle', PictureInPictureToggle);

export default PictureInPictureToggle;
