/**
 * @file animation-display.js
 * @since 2.0.0
 */

import videojs from 'video.js';

const Component = videojs.getComponent('Component');

/**
 * Image for displaying animated GIF image.
 *
 * @class
 * @augments videojs.Component
*/
class AnimationDisplay extends Component {

    /**
     * Create the `AnimationDisplay`s DOM element.
     *
     * @return {Element}
     *         The dom element that gets created.
     */
    createEl() {
        const imgElement = videojs.dom.createEl('img');
        const el = super.createEl('div', {
            className: 'vjs-animation-display',
            dir: 'ltr'
        });
        el.appendChild(imgElement);

        return el;
    }
}

Component.registerComponent('AnimationDisplay', AnimationDisplay);

export default AnimationDisplay;
