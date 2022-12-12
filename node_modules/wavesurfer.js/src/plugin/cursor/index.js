/**
 * @typedef {Object} CursorPluginParams
 * @property {?boolean} deferInit Set to true to stop auto init in `addPlugin()`
 * @property {boolean} hideOnBlur=true Hide the cursor when the mouse leaves the
 * waveform
 * @property {string} width='1px' The width of the cursor
 * @property {string} color='black' The color of the cursor
 * @property {number|string} opacity='0.25' The opacity of the cursor
 * @property {string} style='solid' The border style of the cursor
 * @property {number} zIndex=3 The z-index of the cursor element
 * @property {object} customStyle An object with custom styles which are applied
 * to the cursor element
 * @property {boolean} showTime=false Show the time on the cursor.
 * @property {object} customShowTimeStyle An object with custom styles which are
 * applied to the cursor time element.
 * @property {boolean} followCursorY=false Use `true` to make the time on
 * the cursor follow the x and the y-position of the mouse. Use `false` to make the
 * it only follow the x-position of the mouse.
 * @property {function} formatTimeCallback Formats the timestamp on the cursor.
 */

/**
 * Displays a thin line at the position of the cursor on the waveform.
 *
 * @implements {PluginClass}
 * @extends {Observer}
 * @example
 * // es6
 * import CursorPlugin from 'wavesurfer.cursor.js';
 *
 * // commonjs
 * var CursorPlugin = require('wavesurfer.cursor.js');
 *
 * // if you are using <script> tags
 * var CursorPlugin = window.WaveSurfer.cursor;
 *
 * // ... initialising wavesurfer with the plugin
 * var wavesurfer = WaveSurfer.create({
 *   // wavesurfer options ...
 *   plugins: [
 *     CursorPlugin.create({
 *       // plugin options ...
 *     })
 *   ]
 * });
 */
export default class CursorPlugin {
    /**
     * Cursor plugin definition factory
     *
     * This function must be used to create a plugin definition which can be
     * used by wavesurfer to correctly instantiate the plugin.
     *
     * @param  {CursorPluginParams} params parameters use to initialise the
     * plugin
     * @return {PluginDefinition} an object representing the plugin
     */
    static create(params) {
        return {
            name: 'cursor',
            deferInit: params && params.deferInit ? params.deferInit : false,
            params: params,
            staticProps: {},
            instance: CursorPlugin
        };
    }

    /**
     * @type {CursorPluginParams}
     */
    defaultParams = {
        hideOnBlur: true,
        width: '1px',
        color: 'black',
        opacity: '0.25',
        style: 'solid',
        zIndex: 4,
        customStyle: {},
        customShowTimeStyle: {},
        showTime: false,
        followCursorY: false,
        formatTimeCallback: null
    };

    /**
     * @param {object} e Mouse move event
     */
    _onMousemove = e => {
        const event = this.util.withOrientation(e, this.wavesurfer.params.vertical);
        const bbox = this.wrapper.getBoundingClientRect();
        let y = 0;
        let x = this.wrapper.scrollLeft + event.clientX - bbox.left;
        let flip = bbox.right < event.clientX + this.displayTime.getBoundingClientRect().width;

        if (this.params.showTime && this.params.followCursorY) {
            // follow y-position of the mouse
            y = event.clientY - (bbox.top + bbox.height / 2);
        }

        this.updateCursorPosition(x, y, flip);
    };

    /**
     * @returns {void}
     */
    _onMouseenter = () => this.showCursor();

    /**
     * @returns {void}
     */
    _onMouseleave = () => this.hideCursor();

    /**
     * Construct the plugin class. You probably want to use `CursorPlugin.create`
     * instead.
     *
     * @param {CursorPluginParams} params Plugin parameters
     * @param {object} ws Wavesurfer instance
     */
    constructor(params, ws) {
        this.wavesurfer = ws;
        this.style = ws.util.style;
        this.util = ws.util;
        /**
         * The cursor HTML element
         *
         * @type {?HTMLElement}
         */
        this.cursor = null;
        /**
         * displays the time next to the cursor
         *
         * @type {?HTMLElement}
         */
        this.showTime = null;
        /**
         * The html container that will display the time
         *
         * @type {?HTMLElement}
         */
        this.displayTime = null;

        this.params = Object.assign({}, this.defaultParams, params);
    }

    _onReady() {
        this.wrapper = this.wavesurfer.drawer.wrapper;
        this.cursor = this.util.withOrientation(this.wrapper.appendChild(
            document.createElement('cursor'),
        ), this.wavesurfer.params.vertical);

        this.style(this.cursor,
            Object.assign(
                {
                    position: 'absolute',
                    zIndex: this.params.zIndex,
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: '0',
                    display: 'flex',
                    borderRightStyle: this.params.style,
                    borderRightWidth: this.params.width,
                    borderRightColor: this.params.color,
                    opacity: this.params.opacity,
                    pointerEvents: 'none'
                },
                this.params.customStyle
            )
        );

        if (this.params.showTime) {
            this.showTime = this.util.withOrientation(this.wrapper.appendChild(
                document.createElement('showTitle')
            ), this.wavesurfer.params.vertical);
            this.style(
                this.showTime,
                Object.assign(
                    {
                        position: 'absolute',
                        zIndex: this.params.zIndex,
                        left: 0,
                        top: 0,
                        bottom: 0,
                        width: 'auto',
                        display: 'flex',
                        opacity: this.params.opacity,
                        pointerEvents: 'none',
                        height: '100%'
                    },
                    this.params.customStyle
                )
            );

            this.displayTime = this.util.withOrientation(this.showTime.appendChild(
                document.createElement('div'),
            ), this.wavesurfer.params.vertical);

            this.style(this.displayTime,
                Object.assign(
                    {
                        display: 'inline',
                        pointerEvents: 'none',
                        margin: 'auto',
                        visibility: 'hidden' // initial value will be hidden just for measuring purpose
                    },
                    this.params.customShowTimeStyle
                )
            );

            // initial value to measure display width
            this.displayTime.innerHTML = this.formatTime(0);
        }

        this.wrapper.addEventListener('mousemove', this._onMousemove);
        if (this.params.hideOnBlur) {
            // ensure elements are hidden initially
            this.hideCursor();
            this.wrapper.addEventListener('mouseenter', this._onMouseenter);
            this.wrapper.addEventListener('mouseleave', this._onMouseleave);
        }
    }

    /**
     * Initialise the plugin (used by the Plugin API)
     */
    init() {
        if (this.wavesurfer.isReady) {
            this._onReady();
        } else {
            this.wavesurfer.once('ready', () => this._onReady());
        }
    }

    /**
     * Destroy the plugin (used by the Plugin API)
     */
    destroy() {
        if (this.params.showTime) {
            this.showTime.remove();
        }
        this.cursor.remove();
        this.wrapper.removeEventListener('mousemove', this._onMousemove);
        if (this.params.hideOnBlur) {
            this.wrapper.removeEventListener('mouseenter', this._onMouseenter);
            this.wrapper.removeEventListener('mouseleave', this._onMouseleave);
        }
    }

    /**
     * Update the cursor position
     *
     * @param {number} xpos The x offset of the cursor in pixels
     * @param {number} ypos The y offset of the cursor in pixels
     * @param {boolean} flip Flag to flip duration text from right to left
     */
    updateCursorPosition(xpos, ypos, flip = false) {
        this.style(this.cursor, {
            left: `${xpos}px`
        });
        if (this.params.showTime) {
            const duration = this.wavesurfer.getDuration();
            const elementWidth =
                this.wavesurfer.drawer.width /
                this.wavesurfer.params.pixelRatio;
            const scrollWidth = this.wavesurfer.drawer.getScrollX();

            const scrollTime =
                (duration / this.wavesurfer.drawer.width) * scrollWidth;

            const timeValue =
                Math.max(0, ((xpos - this.wrapper.scrollLeft) / elementWidth) * duration) + scrollTime;
            const formatValue = this.formatTime(timeValue);
            if (flip) {
                const textOffset = this.displayTime.getBoundingClientRect().width;
                xpos -= textOffset;
            }
            this.style(this.showTime, {
                left: `${xpos}px`,
                top: `${ypos}px`
            });
            this.style(this.displayTime, {
                visibility: 'visible'
            });
            this.displayTime.innerHTML = `${formatValue}`;
        }
    }

    /**
     * Show the cursor
     */
    showCursor() {
        this.style(this.cursor, {
            display: 'flex'
        });
        if (this.params.showTime) {
            this.style(this.showTime, {
                display: 'flex'
            });
        }
    }

    /**
     * Hide the cursor
     */
    hideCursor() {
        this.style(this.cursor, {
            display: 'none'
        });
        if (this.params.showTime) {
            this.style(this.showTime, {
                display: 'none'
            });
        }
    }

    /**
     * Format the timestamp for `cursorTime`.
     *
     * @param {number} cursorTime Time in seconds
     * @returns {string} Formatted timestamp
     */
    formatTime(cursorTime) {
        cursorTime = isNaN(cursorTime) ? 0 : cursorTime;

        if (this.params.formatTimeCallback) {
            return this.params.formatTimeCallback(cursorTime);
        }
        return [cursorTime].map(time =>
            [
                Math.floor((time % 3600) / 60), // minutes
                ('00' + Math.floor(time % 60)).slice(-2), // seconds
                ('000' + Math.floor((time % 1) * 1000)).slice(-3) // milliseconds
            ].join(':')
        );
    }
}
