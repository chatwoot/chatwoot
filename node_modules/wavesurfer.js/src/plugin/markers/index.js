/**
 * @typedef {Object} MarkerParams
 * @desc The parameters used to describe a marker.
 * @example wavesurfer.addMarker(regionParams);
 * @property {number} time The time to set the marker at
 * @property {?label} string An optional marker label
 * @property {?color} string Background color for marker
 * @property {?position} string "top" or "bottom", defaults to "bottom"
 * @property {?markerElement} element An HTML element to display instead of the default marker image
 * @property {?draggable} boolean Set marker as draggable, defaults to false
 */


/**
 * Markers are points in time in the audio that can be jumped to.
 *
 * @implements {PluginClass}
 *
 * @example
 * import MarkersPlugin from 'wavesurfer.markers.js';
 *
 * // if you are using <script> tags
 * var MarkerPlugin = window.WaveSurfer.markers;
 *
 * // ... initialising wavesurfer with the plugin
 * var wavesurfer = WaveSurfer.create({
 *   // wavesurfer options ...
 *   plugins: [
 *     MarkersPlugin.create({
 *       // plugin options ...
 *     })
 *   ]
 * });
 */

const DEFAULT_FILL_COLOR = "#D8D8D8";
const DEFAULT_POSITION = "bottom";

export default class MarkersPlugin {
    /**
     * @typedef {Object} MarkersPluginParams
     * @property {?MarkerParams[]} markers Initial set of markers
     * @fires MarkersPlugin#marker-click
     * @fires MarkersPlugin#marker-drag
     * @fires MarkersPlugin#marker-drop
     */

    /**
     * Markers plugin definition factory
     *
     * This function must be used to create a plugin definition which can be
     * used by wavesurfer to correctly instantiate the plugin.
     *
     * @param {MarkersPluginParams} params parameters use to initialise the plugin
     * @since 4.6.0
     * @return {PluginDefinition} an object representing the plugin
     */
    static create(params) {
        return {
            name: 'markers',
            deferInit: params && params.deferInit ? params.deferInit : false,
            params: params,
            staticProps: {
                addMarker(options) {
                    if (!this.initialisedPluginList.markers) {
                        this.initPlugin('markers');
                    }
                    return this.markers.add(options);
                },
                clearMarkers() {
                    this.markers && this.markers.clear();
                }
            },
            instance: MarkersPlugin
        };
    }

    constructor(params, ws) {
        this.params = params;
        this.wavesurfer = ws;
        this.util = ws.util;
        this.style = this.util.style;
        this.markerLineWidth = 1;
        this.markerWidth = 11;
        this.markerHeight = 22;
        this.dragging = false;


        this._onResize = () => {
            this._updateMarkerPositions();
        };

        this._onBackendCreated = () => {
            this.wrapper = this.wavesurfer.drawer.wrapper;
            if (this.params.markers) {
                this.params.markers.forEach(marker => this.add(marker));
            }
            window.addEventListener('resize', this._onResize, true);
            window.addEventListener('orientationchange', this._onResize, true);
            this.wavesurfer.on('zoom', this._onResize);

            if (!this.markers.find(marker => marker.draggable)){
                return;
            }

            this.onMouseMove = (e) => this._onMouseMove(e);
            window.addEventListener('mousemove', this.onMouseMove);

            this.onMouseUp = (e) => this._onMouseUp(e);
            window.addEventListener("mouseup", this.onMouseUp);
        };

        this.markers = [];
        this._onReady = () => {
            this.wrapper = this.wavesurfer.drawer.wrapper;
            this._updateMarkerPositions();
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

        this.wavesurfer.un('zoom', this._onResize);

        window.removeEventListener('resize', this._onResize, true);
        window.removeEventListener('orientationchange', this._onResize, true);

        if (this.onMouseMove) {
            window.removeEventListener('mousemove', this.onMouseMove);
        }
        if (this.onMouseUp) {
            window.removeEventListener("mouseup", this.onMouseUp);
        }

        this.clear();
    }

    /**
     * Add a marker
     *
     * @param {MarkerParams} params Marker definition
     * @return {object} The created marker
     */
    add(params) {
        let marker = {
            time: params.time,
            label: params.label,
            color: params.color || DEFAULT_FILL_COLOR,
            position: params.position || DEFAULT_POSITION,
            draggable: !!params.draggable
        };

        marker.el = this._createMarkerElement(marker, params.markerElement);

        this.wrapper.appendChild(marker.el);
        this.markers.push(marker);
        this._updateMarkerPositions();

        return marker;
    }

    /**
     * Remove a marker
     *
     * @param {number} index Index of the marker to remove
     */
    remove(index) {
        let marker = this.markers[index];
        if (!marker) {
            return;
        }

        this.wrapper.removeChild(marker.el);
        this.markers.splice(index, 1);
    }

    _createPointerSVG(color, position) {
        const svgNS = "http://www.w3.org/2000/svg";

        const el = document.createElementNS(svgNS, "svg");
        const polygon = document.createElementNS(svgNS, "polygon");

        el.setAttribute("viewBox", "0 0 40 80");

        polygon.setAttribute("id", "polygon");
        polygon.setAttribute("stroke", "#979797");
        polygon.setAttribute("fill", color);
        polygon.setAttribute("points", "20 0 40 30 40 80 0 80 0 30");
        if ( position == "top" ) {
            polygon.setAttribute("transform", "rotate(180, 20 40)");
        }

        el.appendChild(polygon);

        this.style(el, {
            width: this.markerWidth + "px",
            height: this.markerHeight + "px",
            "min-width": this.markerWidth + "px",
            "margin-right": "5px",
            "z-index": 4
        });
        return el;
    }

    _createMarkerElement(marker, markerElement) {
        let label = marker.label;

        const el = document.createElement('marker');
        el.className = "wavesurfer-marker";

        this.style(el, {
            position: "absolute",
            height: "100%",
            display: "flex",
            overflow: "hidden",
            "flex-direction": (marker.position == "top" ? "column-reverse" : "column")
        });

        const line = document.createElement('div');
        const width = markerElement ? markerElement.width : this.markerWidth;
        marker.offset = (width - this.markerLineWidth) / 2;
        this.style(line, {
            "flex-grow": 1,
            "margin-left": marker.offset + "px",
            background: "black",
            width: this.markerLineWidth + "px",
            opacity: 0.1
        });
        el.appendChild(line);

        const labelDiv = document.createElement('div');
        const point = markerElement || this._createPointerSVG(marker.color, marker.position);
        if (marker.draggable){
            point.draggable = false;
        }
        labelDiv.appendChild(point);

        if ( label ) {
            const labelEl = document.createElement('span');
            labelEl.innerText = label;
            this.style(labelEl, {
                "font-family": "monospace",
                "font-size": "90%"
            });
            labelDiv.appendChild(labelEl);
        }

        this.style(labelDiv, {
            display: "flex",
            "align-items": "center",
            cursor: "pointer"
        });

        el.appendChild(labelDiv);

        labelDiv.addEventListener("click", e => {
            e.stopPropagation();
            // Click event is caught when the marker-drop event was dispatched.
            // Drop event was dispatched at this moment, but this.dragging
            // is waiting for the next tick to set as false
            if (this.dragging){
                return;
            }
            this.wavesurfer.setCurrentTime(marker.time);
            this.wavesurfer.fireEvent("marker-click", marker, e);
        });

        if (marker.draggable) {
            labelDiv.addEventListener("mousedown", e => {
                this.selectedMarker = marker;
            });
        }
        return el;
    }

    _updateMarkerPositions() {
        for ( let i = 0 ; i < this.markers.length; i++ ) {
            let marker = this.markers[i];
            this._updateMarkerPosition(marker);
        }
    }

    /**
     * Update a marker position based on its time property.
     *
     * @private
     * @param {MarkerParams} params The marker to update.
     * @returns {void}
     */
    _updateMarkerPosition(params) {
        const duration = this.wavesurfer.getDuration();
        const elementWidth =
            this.wavesurfer.drawer.width /
            this.wavesurfer.params.pixelRatio;

        const positionPct = Math.min(params.time / duration, 1);
        const leftPx = ((elementWidth * positionPct) - params.offset);
        this.style(params.el, {
            "left": leftPx + "px",
            "max-width": (elementWidth - leftPx) + "px"
        });
    }

    /**
     * Fires `marker-drag` event, update the `time` property for the
     * selected marker based on the mouse position, and calls to update
     * its position.
     *
     * @private
     * @param {MouseEvent} event The mouse event.
     * @returns {void}
     */
    _onMouseMove(event) {
        if (!this.selectedMarker){
            return;
        }
        if (!this.dragging){
            this.dragging = true;
            this.wavesurfer.fireEvent("marker-drag", this.selectedMarker, event);
        }
        this.selectedMarker.time = this.wavesurfer.drawer.handleEvent(event) * this.wavesurfer.getDuration();
        this._updateMarkerPositions();
    }

    /**
     * Fires `marker-drop` event and unselect the dragged marker.
     *
     * @private
     * @param {MouseEvent} event The mouse event.
     * @returns {void}
     */
    _onMouseUp(event) {
        if (this.selectedMarker) {
            setTimeout(() => {
                this.selectedMarker = false;
                this.dragging = false;
            }, 0);
        }

        if (!this.dragging) {
            return;
        }

        event.stopPropagation();
        const duration = this.wavesurfer.getDuration();
        this.selectedMarker.time = this.wavesurfer.drawer.handleEvent(event) * duration;
        this._updateMarkerPositions();
        this.wavesurfer.fireEvent("marker-drop", this.selectedMarker, event);
    }

    /**
     * Remove all markers
     */
    clear() {
        while ( this.markers.length > 0 ) {
            this.remove(0);
        }
    }
}
