/**
 * @file record-canvas
 * @since 2.0.0
 */

import videojs from 'video.js';

const Component = videojs.getComponent('Component');

/**
 * Canvas for displaying snapshot image.
 *
 * @class
 * @augments videojs.Component
*/
class RecordCanvas extends Component {

    /**
     * Create the `RecordCanvas`s DOM element.
     *
     * @return {Element}
     *         The dom element that gets created.
     */
    createEl() {
        const canvasElement = videojs.dom.createEl('canvas');
        const el = super.createEl('div', {
            className: 'vjs-record-canvas',
            dir: 'ltr'
        });
        el.appendChild(canvasElement);

        return el;
    }
}

Component.registerComponent('RecordCanvas', RecordCanvas);

export default RecordCanvas;
