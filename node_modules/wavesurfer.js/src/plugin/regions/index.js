/**
 *  @since 4.0.0 This class has been split
 *
 * @typedef {Object} RegionsPluginParams
 * @property {?boolean} dragSelection Enable creating regions by dragging with
 * the mouse
 * @property {?RegionParams[]} regions Regions that should be added upon
 * initialisation
 * @property {number} slop=2 The sensitivity of the mouse dragging
 * @property {?number} snapToGridInterval Snap the regions to a grid of the specified multiples in seconds
 * @property {?number} snapToGridOffset Shift the snap-to-grid by the specified seconds. May also be negative.
 * @property {?boolean} deferInit Set to true to manually call
 * @property {number} maxRegions Maximum number of regions that may be created by the user at one time.
 * `initPlugin('regions')`
 * @property {function} formatTimeCallback Allows custom formating for region tooltip.
 * @property {?number} edgeScrollWidth='5% from container edges' Optional width for edgeScroll to start
 */

/**
 * @typedef {Object} RegionParams
 * @desc The parameters used to describe a region.
 * @example wavesurfer.addRegion(regionParams);
 * @property {string} id=→random The id of the region
 * @property {number} start=0 The start position of the region (in seconds).
 * @property {number} end=0 The end position of the region (in seconds).
 * @property {?boolean} loop Whether to loop the region when played back.
 * @property {boolean} drag=true Allow/disallow dragging the region.
 * @property {boolean} resize=true Allow/disallow resizing the region.
 * @property {string} [color='rgba(0, 0, 0, 0.1)'] HTML color code.
 * @property {?number} channelIdx Select channel to draw the region on (if there are multiple channel waveforms).
 * @property {?object} handleStyle A set of CSS properties used to style the left and right handle.
 * @property {?boolean} preventContextMenu=false Determines whether the context menu is prevented from being opened.
 * @property {boolean} showTooltip=true Enable/disable tooltip displaying start and end times when hovering over region.
 */

import {Region} from "./region.js";

/**
 * Regions are visual overlays on waveform that can be used to play and loop
 * portions of audio. Regions can be dragged and resized.
 *
 * Visual customization is possible via CSS (using the selectors
 * `.wavesurfer-region` and `.wavesurfer-handle`).
 *
 * @implements {PluginClass}
 * @extends {Observer}
 *
 * @example
 * // es6
 * import RegionsPlugin from 'wavesurfer.regions.js';
 *
 * // commonjs
 * var RegionsPlugin = require('wavesurfer.regions.js');
 *
 * // if you are using <script> tags
 * var RegionsPlugin = window.WaveSurfer.regions;
 *
 * // ... initialising wavesurfer with the plugin
 * var wavesurfer = WaveSurfer.create({
 *   // wavesurfer options ...
 *   plugins: [
 *     RegionsPlugin.create({
 *       // plugin options ...
 *     })
 *   ]
 * });
 */
export default class RegionsPlugin {
    /**
     * Regions plugin definition factory
     *
     * This function must be used to create a plugin definition which can be
     * used by wavesurfer to correctly instantiate the plugin.
     *
     * @param {RegionsPluginParams} params parameters use to initialise the plugin
     * @return {PluginDefinition} an object representing the plugin
     */
    static create(params) {
        return {
            name: 'regions',
            deferInit: params && params.deferInit ? params.deferInit : false,
            params: params,
            staticProps: {
                addRegion(options) {
                    if (!this.initialisedPluginList.regions) {
                        this.initPlugin('regions');
                    }
                    return this.regions.add(options);
                },

                clearRegions() {
                    this.regions && this.regions.clear();
                },

                enableDragSelection(options) {
                    if (!this.initialisedPluginList.regions) {
                        this.initPlugin('regions');
                    }
                    this.regions.enableDragSelection(options);
                },

                disableDragSelection() {
                    this.regions.disableDragSelection();
                }
            },
            instance: RegionsPlugin
        };
    }

    constructor(params, ws) {
        this.params = params;
        this.wavesurfer = ws;
        this.util = {
            ...ws.util,
            getRegionSnapToGridValue: value => {
                return this.getRegionSnapToGridValue(value, params);
            }
        };
        this.maxRegions = params.maxRegions;
        this.regionsMinLength = params.regionsMinLength || null;

        // turn the plugin instance into an observer
        const observerPrototypeKeys = Object.getOwnPropertyNames(
            this.util.Observer.prototype
        );
        observerPrototypeKeys.forEach(key => {
            Region.prototype[key] = this.util.Observer.prototype[key];
        });
        this.wavesurfer.Region = Region;

        // By default, scroll the container if the user drags a region
        // within 5% (based on its initial size) of its edge
        const scrollWidthProportion = 0.05;
        this._onBackendCreated = () => {
            this.wrapper = this.wavesurfer.drawer.wrapper;
            this.orientation = this.wavesurfer.drawer.orientation;
            this.defaultEdgeScrollWidth = this.wrapper.clientWidth * scrollWidthProportion;
            if (this.params.regions) {
                this.params.regions.forEach(region => {
                    this.add(region);
                });
            }
        };

        // Id-based hash of regions
        this.list = {};
        this._onReady = () => {
            this.wrapper = this.wavesurfer.drawer.wrapper;
            this.vertical = this.wavesurfer.drawer.params.vertical;
            if (this.params.dragSelection) {
                this.enableDragSelection(this.params);
            }
            Object.keys(this.list).forEach(id => {
                this.list[id].updateRender();
            });
        };
    }

    init() {
        // Check if ws is ready
        if (this.wavesurfer.isReady) {
            this._onBackendCreated();
            this._onReady();
        } else {
            this.wavesurfer.once('ready', this._onReady);
            this.wavesurfer.once('backend-created', this._onBackendCreated);
        }
    }

    destroy() {
        this.wavesurfer.un('ready', this._onReady);
        this.wavesurfer.un('backend-created', this._onBackendCreated);
        // Disabling `region-removed' because destroying the plugin calls
        // the Region.remove() method that is also used to remove regions based
        // on user input. This can cause confusion since teardown is not a
        // user event, but would emit `region-removed` as if it was.
        this.wavesurfer.setDisabledEventEmissions(['region-removed']);
        this.disableDragSelection();
        this.clear();
    }

    /**
     * check to see if adding a new region would exceed maxRegions
     * @return {boolean} whether we should proceed and create a region
     * @private
     */
    wouldExceedMaxRegions() {
        return (
            this.maxRegions && Object.keys(this.list).length >= this.maxRegions
        );
    }

    /**
     * Add a region
     *
     * @param {object} params Region parameters
     * @return {Region} The created region
     */
    add(params) {
        if (this.wouldExceedMaxRegions()) {
            return null;
        }

        params = {
            edgeScrollWidth: this.params.edgeScrollWidth || this.defaultEdgeScrollWidth,
            ...params
        };

        // Take formatTimeCallback from plugin params if not already set
        if (!params.formatTimeCallback && this.params.formatTimeCallback) {
            params = {...params, formatTimeCallback: this.params.formatTimeCallback};
        }

        if (!params.minLength && this.regionsMinLength) {
            params = {...params, minLength: this.regionsMinLength};
        }

        const region = new this.wavesurfer.Region(params, this.util, this.wavesurfer);

        this.list[region.id] = region;

        region.on('remove', () => {
            delete this.list[region.id];
        });

        return region;
    }

    /**
     * Remove all regions
     */
    clear() {
        Object.keys(this.list).forEach(id => {
            this.list[id].remove();
        });
    }

    enableDragSelection(params) {
        this.disableDragSelection();

        const slop = params.slop || 2;
        const container = this.wavesurfer.drawer.container;
        const scroll =
            params.scroll !== false && this.wavesurfer.params.scrollParent;
        const scrollSpeed = params.scrollSpeed || 1;
        const scrollThreshold = params.scrollThreshold || 10;
        let drag;
        let duration = this.wavesurfer.getDuration();
        let maxScroll;
        let start;
        let region;
        let touchId;
        let pxMove = 0;
        let scrollDirection;
        let wrapperRect;

        // Scroll when the user is dragging within the threshold
        const edgeScroll = e => {
            if (!region || !scrollDirection) {
                return;
            }

            // Update scroll position
            let scrollLeft =
                this.wrapper.scrollLeft + scrollSpeed * scrollDirection;
            this.wrapper.scrollLeft = scrollLeft = Math.min(
                maxScroll,
                Math.max(0, scrollLeft)
            );

            // Update range
            const end = this.wavesurfer.drawer.handleEvent(e);
            region.update({
                start: Math.min(end * duration, start * duration),
                end: Math.max(end * duration, start * duration)
            });

            // Check that there is more to scroll and repeat
            if (scrollLeft < maxScroll && scrollLeft > 0) {
                window.requestAnimationFrame(() => {
                    edgeScroll(e);
                });
            }
        };

        const eventDown = e => {
            if (e.touches && e.touches.length > 1) {
                return;
            }
            duration = this.wavesurfer.getDuration();
            touchId = e.targetTouches ? e.targetTouches[0].identifier : null;

            // Store for scroll calculations
            maxScroll = this.wrapper.scrollWidth -
                this.wrapper.clientWidth;
            wrapperRect = this.util.withOrientation(
                this.wrapper.getBoundingClientRect(),
                this.vertical
            );

            // set the region channel index based on the clicked area
            if (this.wavesurfer.params.splitChannels) {
                const y = (e.touches ? e.touches[0].clientY : e.clientY) - wrapperRect.top;
                const channelCount = this.wavesurfer.backend.buffer != null ? this.wavesurfer.backend.buffer.numberOfChannels : 1;
                const channelHeight = this.wrapper.clientHeight / channelCount;
                const channelIdx = Math.floor(y / channelHeight);
                params.channelIdx = channelIdx;
                const channelColors = this.wavesurfer.params.splitChannelsOptions.channelColors[channelIdx];
                if (channelColors && channelColors.dragColor) {
                    params.color = channelColors.dragColor;
                }
            }

            drag = true;
            start = this.wavesurfer.drawer.handleEvent(e, true);
            region = null;
            scrollDirection = null;
        };
        this.wrapper.addEventListener('mousedown', eventDown);
        this.wrapper.addEventListener('touchstart', eventDown);
        this.on('disable-drag-selection', () => {
            this.wrapper.removeEventListener('touchstart', eventDown);
            this.wrapper.removeEventListener('mousedown', eventDown);
        });

        const eventUp = e => {
            if (e.touches && e.touches.length > 1) {
                return;
            }

            drag = false;
            pxMove = 0;
            scrollDirection = null;

            if (region) {
                this.util.preventClick();
                region.fireEvent('update-end', e);
                this.wavesurfer.fireEvent('region-update-end', region, e);
            }

            region = null;
        };
        this.wrapper.addEventListener('mouseleave', eventUp);
        this.wrapper.addEventListener('mouseup', eventUp);
        this.wrapper.addEventListener('touchend', eventUp);

        document.body.addEventListener('mouseup', eventUp);
        document.body.addEventListener('touchend', eventUp);
        this.on('disable-drag-selection', () => {
            document.body.removeEventListener('mouseup', eventUp);
            document.body.removeEventListener('touchend', eventUp);
            this.wrapper.removeEventListener('touchend', eventUp);
            this.wrapper.removeEventListener('mouseup', eventUp);
            this.wrapper.removeEventListener('mouseleave', eventUp);
        });

        const eventMove = event => {
            if (!drag) {
                return;
            }
            if (++pxMove <= slop) {
                return;
            }

            if (event.touches && event.touches.length > 1) {
                return;
            }
            if (event.targetTouches && event.targetTouches[0].identifier != touchId) {
                return;
            }

            // auto-create a region during mouse drag, unless region-count would exceed "maxRegions"
            if (!region) {
                region = this.add(params || {});
                if (!region) {
                    return;
                }
            }

            const end = this.wavesurfer.drawer.handleEvent(event);
            const startUpdate = this.wavesurfer.regions.util.getRegionSnapToGridValue(
                start * duration
            );
            const endUpdate = this.wavesurfer.regions.util.getRegionSnapToGridValue(
                end * duration
            );
            region.update({
                start: Math.min(endUpdate, startUpdate),
                end: Math.max(endUpdate, startUpdate)
            });

            let orientedEvent = this.util.withOrientation(event, this.vertical);

            // If scrolling is enabled
            if (scroll && container.clientWidth < this.wrapper.scrollWidth) {
                // Check threshold based on mouse
                const x = orientedEvent.clientX - wrapperRect.left;
                if (x <= scrollThreshold) {
                    scrollDirection = -1;
                } else if (x >= wrapperRect.right - scrollThreshold) {
                    scrollDirection = 1;
                } else {
                    scrollDirection = null;
                }
                scrollDirection && edgeScroll(event);
            }
        };
        this.wrapper.addEventListener('mousemove', eventMove);
        this.wrapper.addEventListener('touchmove', eventMove);
        this.on('disable-drag-selection', () => {
            this.wrapper.removeEventListener('touchmove', eventMove);
            this.wrapper.removeEventListener('mousemove', eventMove);
        });

        this.wavesurfer.on('region-created', region => {
            if (this.regionsMinLength) {
                region.minLength = this.regionsMinLength;
            }
        });
    }

    disableDragSelection() {
        this.fireEvent('disable-drag-selection');
    }

    /**
     * Get current region
     *
     * The smallest region that contains the current time. If several such
     * regions exist, take the first. Return `null` if none exist.
     *
     * @returns {Region} The current region
     */
    getCurrentRegion() {
        const time = this.wavesurfer.getCurrentTime();
        let min = null;
        Object.keys(this.list).forEach(id => {
            const cur = this.list[id];
            if (cur.start <= time && cur.end >= time) {
                if (!min || cur.end - cur.start < min.end - min.start) {
                    min = cur;
                }
            }
        });

        return min;
    }

    /**
     * Match the value to the grid, if required
     *
     * If the regions plugin params have a snapToGridInterval set, return the
     * value matching the nearest grid interval. If no snapToGridInterval is set,
     * the passed value will be returned without modification.
     *
     * @param {number} value the value to snap to the grid, if needed
     * @param {Object} params the regions plugin params
     * @returns {number} value
     */
    getRegionSnapToGridValue(value, params) {
        if (params.snapToGridInterval) {
            // the regions should snap to a grid
            const offset = params.snapToGridOffset || 0;
            return (
                Math.round((value - offset) / params.snapToGridInterval) *
                    params.snapToGridInterval +
                offset
            );
        }

        // no snap-to-grid
        return value;
    }
}
