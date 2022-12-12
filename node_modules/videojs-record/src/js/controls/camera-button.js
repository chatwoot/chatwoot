/**
 * @file camera-button.js
 * @since 2.0.0
 */

import videojs from 'video.js';

import Event from '../event';

const Button = videojs.getComponent('Button');
const Component = videojs.getComponent('Component');

/**
 * Button to toggle between create and retry snapshot image.
 *
 * @class
 * @augments videojs.Button
*/
class CameraButton extends Button {
    /**
     * Builds the default DOM `className`.
     *
     * @return {string}
     *         The DOM `className` for this object.
     */
    buildCSSClass() {
        return 'vjs-camera-button vjs-control vjs-button vjs-icon-photo-camera';
    }

    /**
     * Enable the `CameraButton` element so that it can be activated or clicked.
     */
    enable() {
        super.enable();

        this.on(this.player_, Event.START_RECORD, this.onStart);
        this.on(this.player_, Event.STOP_RECORD, this.onStop);
    }

    /**
     * Disable the `CameraButton` element so that it cannot be activated or clicked.
     */
    disable() {
        super.disable();

        this.off(this.player_, Event.START_RECORD, this.onStart);
        this.off(this.player_, Event.STOP_RECORD, this.onStop);
    }

    /**
     * Show the `CameraButton` element if it is hidden by removing the
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
    handleClick(event) {
        let recorder = this.player_.record();

        if (!recorder.isProcessing()) {
            // create snapshot
            recorder.start();
        } else {
            // retry
            recorder.retrySnapshot();

            // reset camera button appearance
            this.onStop();

            // trigger replay event
            this.player_.trigger(Event.RETRY);
        }
    }

    /**
     * Add the vjs-icon-replay class to the element so it can change appearance.
     *
     * @param {EventTarget~Event} [event]
     *        The event that caused this function to run.
     *
     * @listens Player#startRecord
     */
    onStart(event) {
        // replace element class so it can change appearance
        this.removeClass('vjs-icon-photo-camera');
        this.addClass('vjs-icon-replay');

        // change the button text
        this.controlText('Retry');
    }

    /**
     * Add the vjs-icon-photo-camera class to the element so it can change appearance.
     *
     * @param {EventTarget~Event} [event]
     *        The event that caused this function to run.
     *
     * @listens Player#stopRecord
     */
    onStop(event) {
        // replace element class so it can change appearance
        this.removeClass('vjs-icon-replay');
        this.addClass('vjs-icon-photo-camera');

        // change the button text
        this.controlText('Image');
    }
}

/**
 * The text that should display over the `CameraButton`s controls. Added for localization.
 *
 * @type {string}
 * @private
 */
CameraButton.prototype.controlText_ = 'Image';

Component.registerComponent('CameraButton', CameraButton);

export default CameraButton;
