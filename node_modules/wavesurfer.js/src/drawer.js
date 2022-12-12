import * as util from './util';

/**
 * Parent class for renderers
 *
 * @extends {Observer}
 */
export default class Drawer extends util.Observer {
    /**
     * @param {HTMLElement} container The container node of the wavesurfer instance
     * @param {WavesurferParams} params The wavesurfer initialisation options
     */
    constructor(container, params) {
        super();

        this.container = util.withOrientation(container, params.vertical);
        /**
         * @type {WavesurferParams}
         */
        this.params = params;
        /**
         * The width of the renderer
         * @type {number}
         */
        this.width = 0;
        /**
         * The height of the renderer
         * @type {number}
         */
        this.height = params.height * this.params.pixelRatio;

        this.lastPos = 0;
        /**
         * The `<wave>` element which is added to the container
         * @type {HTMLElement}
         */
        this.wrapper = null;
    }

    /**
     * Alias of `util.style`
     *
     * @param {HTMLElement} el The element that the styles will be applied to
     * @param {Object} styles The map of propName: attribute, both are used as-is
     * @return {HTMLElement} el
     */
    style(el, styles) {
        return util.style(el, styles);
    }

    /**
     * Create the wrapper `<wave>` element, style it and set up the events for
     * interaction
     */
    createWrapper() {
        this.wrapper = util.withOrientation(
            this.container.appendChild(document.createElement('wave')),
            this.params.vertical
        );

        this.style(this.wrapper, {
            display: 'block',
            position: 'relative',
            userSelect: 'none',
            webkitUserSelect: 'none',
            height: this.params.height + 'px'
        });

        if (this.params.fillParent || this.params.scrollParent) {
            this.style(this.wrapper, {
                width: '100%',
                cursor: this.params.hideCursor ? 'none' : 'auto',
                overflowX: this.params.hideScrollbar ? 'hidden' : 'auto',
                overflowY: 'hidden'
            });
        }

        this.setupWrapperEvents();
    }

    /**
     * Handle click event
     *
     * @param {Event} e Click event
     * @param {?boolean} noPrevent Set to true to not call `e.preventDefault()`
     * @return {number} Playback position from 0 to 1
     */
    handleEvent(e, noPrevent) {
        !noPrevent && e.preventDefault();

        const clientX = util.withOrientation(
            e.targetTouches ? e.targetTouches[0] : e,
            this.params.vertical
        ).clientX;
        const bbox = this.wrapper.getBoundingClientRect();

        const nominalWidth = this.width;
        const parentWidth = this.getWidth();
        const progressPixels = this.getProgressPixels(bbox, clientX);

        let progress;
        if (!this.params.fillParent && nominalWidth < parentWidth) {
            progress = progressPixels *
                (this.params.pixelRatio / nominalWidth) || 0;
        } else {
            progress = (progressPixels + this.wrapper.scrollLeft) /
                this.wrapper.scrollWidth || 0;
        }

        return util.clamp(progress, 0, 1);
    }

    getProgressPixels(wrapperBbox, clientX) {
        if (this.params.rtl) {
            return wrapperBbox.right - clientX;
        } else {
            return clientX - wrapperBbox.left;
        }
    }

    setupWrapperEvents() {
        this.wrapper.addEventListener('click', e => {
            const orientedEvent = util.withOrientation(e, this.params.vertical);
            const scrollbarHeight = this.wrapper.offsetHeight -
                  this.wrapper.clientHeight;

            if (scrollbarHeight !== 0) {
                // scrollbar is visible.  Check if click was on it
                const bbox = this.wrapper.getBoundingClientRect();
                if (orientedEvent.clientY >= bbox.bottom - scrollbarHeight) {
                    // ignore mousedown as it was on the scrollbar
                    return;
                }
            }

            if (this.params.interact) {
                this.fireEvent('click', e, this.handleEvent(e));
            }
        });

        this.wrapper.addEventListener('dblclick', e => {
            if (this.params.interact) {
                this.fireEvent('dblclick', e, this.handleEvent(e));
            }
        });

        this.wrapper.addEventListener('scroll', e =>
            this.fireEvent('scroll', e)
        );
    }

    /**
     * Draw peaks on the canvas
     *
     * @param {number[]|Number.<Array[]>} peaks Can also be an array of arrays
     * for split channel rendering
     * @param {number} length The width of the area that should be drawn
     * @param {number} start The x-offset of the beginning of the area that
     * should be rendered
     * @param {number} end The x-offset of the end of the area that should be
     * rendered
     */
    drawPeaks(peaks, length, start, end) {
        if (!this.setWidth(length)) {
            this.clearWave();
        }

        this.params.barWidth
            ? this.drawBars(peaks, 0, start, end)
            : this.drawWave(peaks, 0, start, end);
    }

    /**
     * Scroll to the beginning
     */
    resetScroll() {
        if (this.wrapper !== null) {
            this.wrapper.scrollLeft = 0;
        }
    }

    /**
     * Recenter the view-port at a certain percent of the waveform
     *
     * @param {number} percent Value from 0 to 1 on the waveform
     */
    recenter(percent) {
        const position = this.wrapper.scrollWidth * percent;
        this.recenterOnPosition(position, true);
    }

    /**
     * Recenter the view-port on a position, either scroll there immediately or
     * in steps of 5 pixels
     *
     * @param {number} position X-offset in pixels
     * @param {boolean} immediate Set to true to immediately scroll somewhere
     */
    recenterOnPosition(position, immediate) {
        const scrollLeft = this.wrapper.scrollLeft;
        const half = ~~(this.wrapper.clientWidth / 2);
        const maxScroll = this.wrapper.scrollWidth - this.wrapper.clientWidth;
        let target = position - half;
        let offset = target - scrollLeft;

        if (maxScroll == 0) {
            // no need to continue if scrollbar is not there
            return;
        }

        // if the cursor is currently visible...
        if (!immediate && -half <= offset && offset < half) {
            // set rate at which waveform is centered
            let rate = this.params.autoCenterRate;

            // make rate depend on width of view and length of waveform
            rate /= half;
            rate *= maxScroll;

            offset = Math.max(-rate, Math.min(rate, offset));
            target = scrollLeft + offset;
        }

        // limit target to valid range (0 to maxScroll)
        target = Math.max(0, Math.min(maxScroll, target));
        // no use attempting to scroll if we're not moving
        if (target != scrollLeft) {
            this.wrapper.scrollLeft = target;
        }
    }

    /**
     * Get the current scroll position in pixels
     *
     * @return {number} Horizontal scroll position in pixels
     */
    getScrollX() {
        let x = 0;
        if (this.wrapper) {
            const pixelRatio = this.params.pixelRatio;
            x = Math.round(this.wrapper.scrollLeft * pixelRatio);

            // In cases of elastic scroll (safari with mouse wheel) you can
            // scroll beyond the limits of the container
            // Calculate and floor the scrollable extent to make sure an out
            // of bounds value is not returned
            // Ticket #1312
            if (this.params.scrollParent) {
                const maxScroll = ~~(
                    this.wrapper.scrollWidth * pixelRatio -
                    this.getWidth()
                );
                x = Math.min(maxScroll, Math.max(0, x));
            }
        }
        return x;
    }

    /**
     * Get the width of the container
     *
     * @return {number} The width of the container
     */
    getWidth() {
        return Math.round(this.container.clientWidth * this.params.pixelRatio);
    }

    /**
     * Set the width of the container
     *
     * @param {number} width The new width of the container
     * @return {boolean} Whether the width of the container was updated or not
     */
    setWidth(width) {
        if (this.width == width) {
            return false;
        }

        this.width = width;

        if (this.params.fillParent || this.params.scrollParent) {
            this.style(this.wrapper, {
                width: ''
            });
        } else {
            const newWidth = ~~(this.width / this.params.pixelRatio) + 'px';
            this.style(this.wrapper, {
                width: newWidth
            });
        }

        this.updateSize();
        return true;
    }

    /**
     * Set the height of the container
     *
     * @param {number} height The new height of the container.
     * @return {boolean} Whether the height of the container was updated or not
     */
    setHeight(height) {
        if (height == this.height) {
            return false;
        }
        this.height = height;

        this.style(this.wrapper, {
            height: ~~(this.height / this.params.pixelRatio) + 'px'
        });

        this.updateSize();
        return true;
    }

    /**
     * Called by wavesurfer when progress should be rendered
     *
     * @param {number} progress From 0 to 1
     */
    progress(progress) {
        const minPxDelta = 1 / this.params.pixelRatio;
        const pos = Math.round(progress * this.width) * minPxDelta;

        if (pos < this.lastPos || pos - this.lastPos >= minPxDelta) {
            this.lastPos = pos;

            if (this.params.scrollParent && this.params.autoCenter) {
                const newPos = ~~(this.wrapper.scrollWidth * progress);
                this.recenterOnPosition(
                    newPos,
                    this.params.autoCenterImmediately
                );
            }

            this.updateProgress(pos);
        }
    }

    /**
     * This is called when wavesurfer is destroyed
     */
    destroy() {
        this.unAll();
        if (this.wrapper) {
            if (this.wrapper.parentNode == this.container.domElement) {
                this.container.removeChild(this.wrapper.domElement);
            }
            this.wrapper = null;
        }
    }

    /* Renderer-specific methods */

    /**
     * Called after cursor related params have changed.
     *
     * @abstract
     */
    updateCursor() {}

    /**
     * Called when the size of the container changes so the renderer can adjust
     *
     * @abstract
     */
    updateSize() {}

    /**
     * Draw a waveform with bars
     *
     * @abstract
     * @param {number[]|Number.<Array[]>} peaks Can also be an array of arrays for split channel
     * rendering
     * @param {number} channelIndex The index of the current channel. Normally
     * should be 0
     * @param {number} start The x-offset of the beginning of the area that
     * should be rendered
     * @param {number} end The x-offset of the end of the area that should be
     * rendered
     */
    drawBars(peaks, channelIndex, start, end) {}

    /**
     * Draw a waveform
     *
     * @abstract
     * @param {number[]|Number.<Array[]>} peaks Can also be an array of arrays for split channel
     * rendering
     * @param {number} channelIndex The index of the current channel. Normally
     * should be 0
     * @param {number} start The x-offset of the beginning of the area that
     * should be rendered
     * @param {number} end The x-offset of the end of the area that should be
     * rendered
     */
    drawWave(peaks, channelIndex, start, end) {}

    /**
     * Clear the waveform
     *
     * @abstract
     */
    clearWave() {}

    /**
     * Render the new progress
     *
     * @abstract
     * @param {number} position X-Offset of progress position in pixels
     */
    updateProgress(position) {}
}
