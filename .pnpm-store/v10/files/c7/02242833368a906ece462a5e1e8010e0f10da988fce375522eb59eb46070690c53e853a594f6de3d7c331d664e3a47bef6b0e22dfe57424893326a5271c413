/**
 * @file record-toggle.js
 * @since 2.0.0
 */

import videojs from 'video.js';

import Event from '../event';

const Button = videojs.getComponent('Button');
const Component = videojs.getComponent('Component');

/**
 * Button to toggle between start and stop recording.
 *
 * @class
 * @augments videojs.Button
*/
class RecordToggle extends Button {
    /**
     * Builds the default DOM `className`.
     *
     * @return {string}
     *         The DOM `className` for this object.
     */
    buildCSSClass() {
        return 'vjs-record-button vjs-control vjs-button vjs-icon-record-start';
    }

    /**
     * Enable the `RecordToggle` element so that it can be activated or clicked.
     */
    enable() {
        super.enable();

        this.on(this.player_, Event.START_RECORD, this.onStart);
        this.on(this.player_, Event.STOP_RECORD, this.onStop);
    }

    /**
     * Disable the `RecordToggle` element so that it cannot be activated or clicked.
     */
    disable() {
        super.disable();

        this.off(this.player_, Event.START_RECORD, this.onStart);
        this.off(this.player_, Event.STOP_RECORD, this.onStop);
    }

    /**
     * Show the `RecordToggle` element if it is hidden by removing the
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
        if (!recorder.isRecording()) {
            recorder.start();
        } else {
            recorder.stop();
        }
    }

    /**
     * Add the vjs-icon-record-stop class to the element so it can change appearance.
     *
     * @param {EventTarget~Event} [event]
     *        The event that caused this function to run.
     *
     * @listens Player#startRecord
     */
    onStart(event) {
        // replace element class so it can change appearance
        this.removeClass('vjs-icon-record-start');
        this.addClass('vjs-icon-record-stop');

        // change the button text
        this.controlText('Stop');
    }

    /**
     * Add the vjs-icon-record-start class to the element so it can change appearance.
     *
     * @param {EventTarget~Event} [event]
     *        The event that caused this function to run.
     *
     * @listens Player#stopRecord
     */
    onStop(event) {
        // replace element class so it can change appearance
        this.removeClass('vjs-icon-record-stop');
        this.addClass('vjs-icon-record-start');

        // change the button text
        this.controlText('Record');
    }
}

/**
 * The text that should display over the `RecordToggle`s controls. Added for localization.
 *
 * @type {string}
 * @private
 */
RecordToggle.prototype.controlText_ = 'Record';

Component.registerComponent('RecordToggle', RecordToggle);

export default RecordToggle;
