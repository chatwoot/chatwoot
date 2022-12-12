
/**
 * The playhead plugin separates the notion of the currently playing position from
 * a 'play-start' position.  Having a playhead enables a listening pattern
 * (commonly found in DAWs) that involves listening to a section of a track
 * repeatedly, rather than listening to an entire track in a linear fashion.
 *
 * @implements {PluginClass}
 *
 * @example
 * import PlayheadPlugin from 'wavesurfer.playhead.js';
 *
 * // if you are using <script> tags
 * var PlayheadPlugin = window.WaveSurfer.playhead;
 *
 * // ... initialising wavesurfer with the plugin
 * var wavesurfer = WaveSurfer.create({
 *   // wavesurfer options ...
 *   plugins: [
 *     PlayheadPlugin.create({
 *        movePlayheadOnSeek: true,
 *        drawPlayhead: false,
 *        movePlayheadOnPause: false
 *     })
 *   ]
 * });
 */

const DEFAULT_FILL_COLOR = '#CF2F00';

export default class PlayheadPlugin {
    /**
     * @typedef {Object} PlayheadPluginParams
     * @property {?boolean} draw=true Draw the playhead as a triangle/line
     * @property {?boolean} moveOnSeek=true Seeking (via clicking) while playing moves the playhead
     * @property {?boolean} returnOnPause=true Pausing the track returns the seek position to the playhead
     */

    /**
     * Playhead plugin definition factory
     *
     * This function must be used to create a plugin definition which can be
     * used by wavesurfer to correctly instantiate the plugin.
     *
     * @param {PlayheadPluginParams} params parameters use to initialise the plugin
     * @since 5.0.0
     * @return {PluginDefinition} an object representing the plugin
     */
    static create(params) {
        return {
            name: 'playhead',
            deferInit: params && params.deferInit ? params.deferInit : false,
            params: params,
            instance: PlayheadPlugin
        };
    }

    constructor(params, ws) {
        this.params = params;
        this.options = {};

        ['draw', 'moveOnSeek', 'returnOnPause'].forEach(opt => {
            if (opt in params) {
                this.options[opt] = params[opt];
            } else {
                this.options[opt] = true;
            }
        });


        this.wavesurfer = ws;
        this.util = ws.util;
        this.style = this.util.style;
        this.markerWidth = 21;
        this.markerHeight = 16;
        this.playheadTime = 0;
        this.unFuns = [];

        this._onResize = () => {
            this._updatePlayheadPosition();
        };

        this._onReady = () => {
            this.wrapper = this.wavesurfer.drawer.wrapper;
            this._updatePlayheadPosition();
        };
    }

    _onBackendCreated() {
        this.wrapper = this.wavesurfer.drawer.wrapper;

        if (this.options.draw) {
            this._createPlayheadElement();
            window.addEventListener('resize', this._onResize, true);
            window.addEventListener('orientationchange', this._onResize, true);

            this.wavesurferOn('zoom', this._onResize);
        }

        this.wavesurferOn('pause', () => {
            if ( this.options.returnOnPause ) {
                this.wavesurfer.setCurrentTime(this.playheadTime);
            }
        });

        this.wavesurferOn('seek', () => {
            if ( this.options.moveOnSeek ) {
                this.playheadTime = this.wavesurfer.getCurrentTime();
                this._updatePlayheadPosition();
            }
        });

        this.playheadTime = this.wavesurfer.getCurrentTime();
    }

    wavesurferOn(ev, fn) {
        let ret = this.wavesurfer.on(ev, fn);
        this.unFuns.push(() => {
            this.wavesurfer.un(ev, fn);
        });
        return ret;
    }

    init() {
        if (this.wavesurfer.isReady) {
            this._onBackendCreated();
            this._onReady();
        } else {
            let r;

            this.wavesurfer.once('ready', () => this._onReady());
            this.wavesurfer.once('backend-created', () => this._onBackendCreated());
        }
    }

    destroy() {
        this.unFuns.forEach(f => f());
        this.unFuns = [];

        this.wrapper.removeChild(this.element);

        window.removeEventListener('resize', this._onResize, true);
        window.removeEventListener('orientationchange', this._onResize, true);
    }

    setPlayheadTime(time) {
        this.playheadTime = time;

        if (!this.wavesurfer.isPlaying()) {
            this.wavesurfer.setCurrentTime(time);
        }
        this._updatePlayheadPosition();
    }

    _createPointerSVG() {
        const svgNS = 'http://www.w3.org/2000/svg';

        const el = document.createElementNS(svgNS, 'svg');
        const path = document.createElementNS(svgNS, 'path');

        el.setAttribute('viewBox', '0 0 33 30');
        path.setAttribute('d', 'M16.75 31 31.705 5.566A3 3 0 0 0 29.146 1H4.354a3 3 0 0 0-2.56 4.566L16.75 31z');
        path.setAttribute('stroke', '#979797');
        path.setAttribute('fill', DEFAULT_FILL_COLOR);

        el.appendChild(path);

        this.style(el, {
            width: this.markerWidth + 'px',
            height: this.markerHeight + 'px',
            cursor: 'pointer',
            'z-index': 5
        });
        return el;
    }

    _createPlayheadElement() {
        const el = document.createElement('playhead');
        el.className = 'wavesurfer-playhead';

        this.style(el, {
            position: 'absolute',
            height: '100%',
            display: 'flex',
            'flex-direction': 'column'
        });

        const pointer = this._createPointerSVG();
        el.appendChild(pointer);

        pointer.addEventListener('click', e => {
            e.stopPropagation();
            this.wavesurfer.setCurrentTime(this.playheadTime);
        });

        const line = document.createElement('div');
        this.style(line, {
            'flex-grow': 1,
            'margin-left': (this.markerWidth / 2 - 0.5) + 'px',
            background: 'black',
            width: '1px',
            opacity: 0.1
        });

        el.appendChild(line);

        this.element = el;
        this.wrapper.appendChild(el);
    }

    _updatePlayheadPosition() {
        if (!this.element) {
            return;
        }

        const duration = this.wavesurfer.getDuration();
        const elementWidth =
            this.wavesurfer.drawer.width /
            this.wavesurfer.params.pixelRatio;

        const positionPct = this.playheadTime / duration;
        this.style(this.element, {
            left: ((elementWidth * positionPct) - (this.markerWidth / 2)) + 'px'
        });
    }
}
