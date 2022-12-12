/*!
 * wavesurfer.js regions plugin 6.1.0 (2022-03-31)
 * https://wavesurfer-js.org
 * @license BSD-3-Clause
 */
(function webpackUniversalModuleDefinition(root, factory) {
	if(typeof exports === 'object' && typeof module === 'object')
		module.exports = factory();
	else if(typeof define === 'function' && define.amd)
		define("WaveSurfer", [], factory);
	else if(typeof exports === 'object')
		exports["WaveSurfer"] = factory();
	else
		root["WaveSurfer"] = root["WaveSurfer"] || {}, root["WaveSurfer"]["regions"] = factory();
})(self, function() {
return /******/ (() => { // webpackBootstrap
/******/ 	"use strict";
/******/ 	var __webpack_modules__ = ({

/***/ "./src/plugin/regions/index.js":
/*!*************************************!*\
  !*** ./src/plugin/regions/index.js ***!
  \*************************************/
/***/ ((module, exports, __webpack_require__) => {



Object.defineProperty(exports, "__esModule", ({
  value: true
}));
exports["default"] = void 0;

var _region = __webpack_require__(/*! ./region.js */ "./src/plugin/regions/region.js");

function ownKeys(object, enumerableOnly) { var keys = Object.keys(object); if (Object.getOwnPropertySymbols) { var symbols = Object.getOwnPropertySymbols(object); enumerableOnly && (symbols = symbols.filter(function (sym) { return Object.getOwnPropertyDescriptor(object, sym).enumerable; })), keys.push.apply(keys, symbols); } return keys; }

function _objectSpread(target) { for (var i = 1; i < arguments.length; i++) { var source = null != arguments[i] ? arguments[i] : {}; i % 2 ? ownKeys(Object(source), !0).forEach(function (key) { _defineProperty(target, key, source[key]); }) : Object.getOwnPropertyDescriptors ? Object.defineProperties(target, Object.getOwnPropertyDescriptors(source)) : ownKeys(Object(source)).forEach(function (key) { Object.defineProperty(target, key, Object.getOwnPropertyDescriptor(source, key)); }); } return target; }

function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } }

function _createClass(Constructor, protoProps, staticProps) { if (protoProps) _defineProperties(Constructor.prototype, protoProps); if (staticProps) _defineProperties(Constructor, staticProps); Object.defineProperty(Constructor, "prototype", { writable: false }); return Constructor; }

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
var RegionsPlugin = /*#__PURE__*/function () {
  function RegionsPlugin(params, ws) {
    var _this = this;

    _classCallCheck(this, RegionsPlugin);

    this.params = params;
    this.wavesurfer = ws;
    this.util = _objectSpread(_objectSpread({}, ws.util), {}, {
      getRegionSnapToGridValue: function getRegionSnapToGridValue(value) {
        return _this.getRegionSnapToGridValue(value, params);
      }
    });
    this.maxRegions = params.maxRegions;
    this.regionsMinLength = params.regionsMinLength || null; // turn the plugin instance into an observer

    var observerPrototypeKeys = Object.getOwnPropertyNames(this.util.Observer.prototype);
    observerPrototypeKeys.forEach(function (key) {
      _region.Region.prototype[key] = _this.util.Observer.prototype[key];
    });
    this.wavesurfer.Region = _region.Region; // By default, scroll the container if the user drags a region
    // within 5% (based on its initial size) of its edge

    var scrollWidthProportion = 0.05;

    this._onBackendCreated = function () {
      _this.wrapper = _this.wavesurfer.drawer.wrapper;
      _this.orientation = _this.wavesurfer.drawer.orientation;
      _this.defaultEdgeScrollWidth = _this.wrapper.clientWidth * scrollWidthProportion;

      if (_this.params.regions) {
        _this.params.regions.forEach(function (region) {
          _this.add(region);
        });
      }
    }; // Id-based hash of regions


    this.list = {};

    this._onReady = function () {
      _this.wrapper = _this.wavesurfer.drawer.wrapper;
      _this.vertical = _this.wavesurfer.drawer.params.vertical;

      if (_this.params.dragSelection) {
        _this.enableDragSelection(_this.params);
      }

      Object.keys(_this.list).forEach(function (id) {
        _this.list[id].updateRender();
      });
    };
  }

  _createClass(RegionsPlugin, [{
    key: "init",
    value: function init() {
      // Check if ws is ready
      if (this.wavesurfer.isReady) {
        this._onBackendCreated();

        this._onReady();
      } else {
        this.wavesurfer.once('ready', this._onReady);
        this.wavesurfer.once('backend-created', this._onBackendCreated);
      }
    }
  }, {
    key: "destroy",
    value: function destroy() {
      this.wavesurfer.un('ready', this._onReady);
      this.wavesurfer.un('backend-created', this._onBackendCreated); // Disabling `region-removed' because destroying the plugin calls
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

  }, {
    key: "wouldExceedMaxRegions",
    value: function wouldExceedMaxRegions() {
      return this.maxRegions && Object.keys(this.list).length >= this.maxRegions;
    }
    /**
     * Add a region
     *
     * @param {object} params Region parameters
     * @return {Region} The created region
     */

  }, {
    key: "add",
    value: function add(params) {
      var _this2 = this;

      if (this.wouldExceedMaxRegions()) {
        return null;
      }

      params = _objectSpread({
        edgeScrollWidth: this.params.edgeScrollWidth || this.defaultEdgeScrollWidth
      }, params); // Take formatTimeCallback from plugin params if not already set

      if (!params.formatTimeCallback && this.params.formatTimeCallback) {
        params = _objectSpread(_objectSpread({}, params), {}, {
          formatTimeCallback: this.params.formatTimeCallback
        });
      }

      if (!params.minLength && this.regionsMinLength) {
        params = _objectSpread(_objectSpread({}, params), {}, {
          minLength: this.regionsMinLength
        });
      }

      var region = new this.wavesurfer.Region(params, this.util, this.wavesurfer);
      this.list[region.id] = region;
      region.on('remove', function () {
        delete _this2.list[region.id];
      });
      return region;
    }
    /**
     * Remove all regions
     */

  }, {
    key: "clear",
    value: function clear() {
      var _this3 = this;

      Object.keys(this.list).forEach(function (id) {
        _this3.list[id].remove();
      });
    }
  }, {
    key: "enableDragSelection",
    value: function enableDragSelection(params) {
      var _this4 = this;

      this.disableDragSelection();
      var slop = params.slop || 2;
      var container = this.wavesurfer.drawer.container;
      var scroll = params.scroll !== false && this.wavesurfer.params.scrollParent;
      var scrollSpeed = params.scrollSpeed || 1;
      var scrollThreshold = params.scrollThreshold || 10;
      var drag;
      var duration = this.wavesurfer.getDuration();
      var maxScroll;
      var start;
      var region;
      var touchId;
      var pxMove = 0;
      var scrollDirection;
      var wrapperRect; // Scroll when the user is dragging within the threshold

      var edgeScroll = function edgeScroll(e) {
        if (!region || !scrollDirection) {
          return;
        } // Update scroll position


        var scrollLeft = _this4.wrapper.scrollLeft + scrollSpeed * scrollDirection;
        _this4.wrapper.scrollLeft = scrollLeft = Math.min(maxScroll, Math.max(0, scrollLeft)); // Update range

        var end = _this4.wavesurfer.drawer.handleEvent(e);

        region.update({
          start: Math.min(end * duration, start * duration),
          end: Math.max(end * duration, start * duration)
        }); // Check that there is more to scroll and repeat

        if (scrollLeft < maxScroll && scrollLeft > 0) {
          window.requestAnimationFrame(function () {
            edgeScroll(e);
          });
        }
      };

      var eventDown = function eventDown(e) {
        if (e.touches && e.touches.length > 1) {
          return;
        }

        duration = _this4.wavesurfer.getDuration();
        touchId = e.targetTouches ? e.targetTouches[0].identifier : null; // Store for scroll calculations

        maxScroll = _this4.wrapper.scrollWidth - _this4.wrapper.clientWidth;
        wrapperRect = _this4.util.withOrientation(_this4.wrapper.getBoundingClientRect(), _this4.vertical); // set the region channel index based on the clicked area

        if (_this4.wavesurfer.params.splitChannels) {
          var y = (e.touches ? e.touches[0].clientY : e.clientY) - wrapperRect.top;
          var channelCount = _this4.wavesurfer.backend.buffer != null ? _this4.wavesurfer.backend.buffer.numberOfChannels : 1;
          var channelHeight = _this4.wrapper.clientHeight / channelCount;
          var channelIdx = Math.floor(y / channelHeight);
          params.channelIdx = channelIdx;
          var channelColors = _this4.wavesurfer.params.splitChannelsOptions.channelColors[channelIdx];

          if (channelColors && channelColors.dragColor) {
            params.color = channelColors.dragColor;
          }
        }

        drag = true;
        start = _this4.wavesurfer.drawer.handleEvent(e, true);
        region = null;
        scrollDirection = null;
      };

      this.wrapper.addEventListener('mousedown', eventDown);
      this.wrapper.addEventListener('touchstart', eventDown);
      this.on('disable-drag-selection', function () {
        _this4.wrapper.removeEventListener('touchstart', eventDown);

        _this4.wrapper.removeEventListener('mousedown', eventDown);
      });

      var eventUp = function eventUp(e) {
        if (e.touches && e.touches.length > 1) {
          return;
        }

        drag = false;
        pxMove = 0;
        scrollDirection = null;

        if (region) {
          _this4.util.preventClick();

          region.fireEvent('update-end', e);

          _this4.wavesurfer.fireEvent('region-update-end', region, e);
        }

        region = null;
      };

      this.wrapper.addEventListener('mouseleave', eventUp);
      this.wrapper.addEventListener('mouseup', eventUp);
      this.wrapper.addEventListener('touchend', eventUp);
      document.body.addEventListener('mouseup', eventUp);
      document.body.addEventListener('touchend', eventUp);
      this.on('disable-drag-selection', function () {
        document.body.removeEventListener('mouseup', eventUp);
        document.body.removeEventListener('touchend', eventUp);

        _this4.wrapper.removeEventListener('touchend', eventUp);

        _this4.wrapper.removeEventListener('mouseup', eventUp);

        _this4.wrapper.removeEventListener('mouseleave', eventUp);
      });

      var eventMove = function eventMove(event) {
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
        } // auto-create a region during mouse drag, unless region-count would exceed "maxRegions"


        if (!region) {
          region = _this4.add(params || {});

          if (!region) {
            return;
          }
        }

        var end = _this4.wavesurfer.drawer.handleEvent(event);

        var startUpdate = _this4.wavesurfer.regions.util.getRegionSnapToGridValue(start * duration);

        var endUpdate = _this4.wavesurfer.regions.util.getRegionSnapToGridValue(end * duration);

        region.update({
          start: Math.min(endUpdate, startUpdate),
          end: Math.max(endUpdate, startUpdate)
        });

        var orientedEvent = _this4.util.withOrientation(event, _this4.vertical); // If scrolling is enabled


        if (scroll && container.clientWidth < _this4.wrapper.scrollWidth) {
          // Check threshold based on mouse
          var x = orientedEvent.clientX - wrapperRect.left;

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
      this.on('disable-drag-selection', function () {
        _this4.wrapper.removeEventListener('touchmove', eventMove);

        _this4.wrapper.removeEventListener('mousemove', eventMove);
      });
      this.wavesurfer.on('region-created', function (region) {
        if (_this4.regionsMinLength) {
          region.minLength = _this4.regionsMinLength;
        }
      });
    }
  }, {
    key: "disableDragSelection",
    value: function disableDragSelection() {
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

  }, {
    key: "getCurrentRegion",
    value: function getCurrentRegion() {
      var _this5 = this;

      var time = this.wavesurfer.getCurrentTime();
      var min = null;
      Object.keys(this.list).forEach(function (id) {
        var cur = _this5.list[id];

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

  }, {
    key: "getRegionSnapToGridValue",
    value: function getRegionSnapToGridValue(value, params) {
      if (params.snapToGridInterval) {
        // the regions should snap to a grid
        var offset = params.snapToGridOffset || 0;
        return Math.round((value - offset) / params.snapToGridInterval) * params.snapToGridInterval + offset;
      } // no snap-to-grid


      return value;
    }
  }], [{
    key: "create",
    value:
    /**
     * Regions plugin definition factory
     *
     * This function must be used to create a plugin definition which can be
     * used by wavesurfer to correctly instantiate the plugin.
     *
     * @param {RegionsPluginParams} params parameters use to initialise the plugin
     * @return {PluginDefinition} an object representing the plugin
     */
    function create(params) {
      return {
        name: 'regions',
        deferInit: params && params.deferInit ? params.deferInit : false,
        params: params,
        staticProps: {
          addRegion: function addRegion(options) {
            if (!this.initialisedPluginList.regions) {
              this.initPlugin('regions');
            }

            return this.regions.add(options);
          },
          clearRegions: function clearRegions() {
            this.regions && this.regions.clear();
          },
          enableDragSelection: function enableDragSelection(options) {
            if (!this.initialisedPluginList.regions) {
              this.initPlugin('regions');
            }

            this.regions.enableDragSelection(options);
          },
          disableDragSelection: function disableDragSelection() {
            this.regions.disableDragSelection();
          }
        },
        instance: RegionsPlugin
      };
    }
  }]);

  return RegionsPlugin;
}();

exports["default"] = RegionsPlugin;
module.exports = exports.default;

/***/ }),

/***/ "./src/plugin/regions/region.js":
/*!**************************************!*\
  !*** ./src/plugin/regions/region.js ***!
  \**************************************/
/***/ ((__unused_webpack_module, exports) => {



Object.defineProperty(exports, "__esModule", ({
  value: true
}));
exports.Region = void 0;

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } }

function _createClass(Constructor, protoProps, staticProps) { if (protoProps) _defineProperties(Constructor.prototype, protoProps); if (staticProps) _defineProperties(Constructor, staticProps); Object.defineProperty(Constructor, "prototype", { writable: false }); return Constructor; }

/**
 *  @since 4.0.0
 *
 * (Single) Region plugin class
 *
 * Must be turned into an observer before instantiating. This is done in
 * `RegionsPlugin` (main plugin class).
 *
 * @extends {Observer}
 */
var Region = /*#__PURE__*/function () {
  function Region(params, regionsUtils, ws) {
    var _params$showTooltip,
        _this = this;

    _classCallCheck(this, Region);

    this.wavesurfer = ws;
    this.wrapper = ws.drawer.wrapper;
    this.util = ws.util;
    this.style = this.util.style;
    this.regionsUtil = regionsUtils;
    this.vertical = ws.drawer.params.vertical;
    this.id = params.id == null ? ws.util.getId() : params.id;
    this.start = Number(params.start) || 0;
    this.end = params.end == null ? // small marker-like region
    this.start + 4 / this.wrapper.scrollWidth * this.wavesurfer.getDuration() : Number(params.end);
    this.resize = params.resize === undefined ? true : Boolean(params.resize);
    this.drag = params.drag === undefined ? true : Boolean(params.drag); // reflect resize and drag state of region for region-updated listener

    this.isResizing = false;
    this.isDragging = false;
    this.loop = Boolean(params.loop);
    this.color = params.color || 'rgba(0, 0, 0, 0.1)'; // The left and right handleStyle properties can be set to 'none' for
    // no styling or can be assigned an object containing CSS properties.

    this.handleStyle = params.handleStyle || {
      left: {},
      right: {}
    };
    this.handleLeftEl = null;
    this.handleRightEl = null;
    this.data = params.data || {};
    this.attributes = params.attributes || {};
    this.showTooltip = (_params$showTooltip = params.showTooltip) !== null && _params$showTooltip !== void 0 ? _params$showTooltip : true;
    this.maxLength = params.maxLength; // It assumes the minLength parameter value, or the regionsMinLength parameter value, if the first one not provided

    this.minLength = params.minLength;

    this._onRedraw = function () {
      return _this.updateRender();
    };

    this.scroll = params.scroll !== false && ws.params.scrollParent;
    this.scrollSpeed = params.scrollSpeed || 1;
    this.scrollThreshold = params.scrollThreshold || 10; // Determines whether the context menu is prevented from being opened.

    this.preventContextMenu = params.preventContextMenu === undefined ? false : Boolean(params.preventContextMenu); // select channel ID to set region

    var channelIdx = params.channelIdx == null ? -1 : parseInt(params.channelIdx);
    this.channelIdx = channelIdx;
    this.regionHeight = '100%';
    this.marginTop = '0px';

    if (channelIdx !== -1) {
      var channelCount = this.wavesurfer.backend.buffer != null ? this.wavesurfer.backend.buffer.numberOfChannels : -1;

      if (channelCount >= 0 && channelIdx < channelCount) {
        this.regionHeight = Math.floor(1 / channelCount * 100) + '%';
        this.marginTop = this.wavesurfer.getHeight() * channelIdx + 'px';
      }
    }

    this.formatTimeCallback = params.formatTimeCallback;
    this.edgeScrollWidth = params.edgeScrollWidth;
    this.bindInOut();
    this.render();
    this.wavesurfer.on('zoom', this._onRedraw);
    this.wavesurfer.on('redraw', this._onRedraw);
    this.wavesurfer.fireEvent('region-created', this);
  }
  /* Update region params. */


  _createClass(Region, [{
    key: "update",
    value: function update(params, eventParams) {
      if (params.start != null) {
        this.start = Number(params.start);
      }

      if (params.end != null) {
        this.end = Number(params.end);
      }

      if (params.loop != null) {
        this.loop = Boolean(params.loop);
      }

      if (params.color != null) {
        this.color = params.color;
      }

      if (params.handleStyle != null) {
        this.handleStyle = params.handleStyle;
      }

      if (params.data != null) {
        this.data = params.data;
      }

      if (params.resize != null) {
        this.resize = Boolean(params.resize);
        this.updateHandlesResize(this.resize);
      }

      if (params.drag != null) {
        this.drag = Boolean(params.drag);
      }

      if (params.maxLength != null) {
        this.maxLength = Number(params.maxLength);
      }

      if (params.minLength != null) {
        this.minLength = Number(params.minLength);
      }

      if (params.attributes != null) {
        this.attributes = params.attributes;
      }

      this.updateRender();
      this.fireEvent('update');
      this.wavesurfer.fireEvent('region-updated', this, eventParams);
    }
    /* Remove a single region. */

  }, {
    key: "remove",
    value: function remove() {
      if (this.element) {
        this.wrapper.removeChild(this.element.domElement);
        this.element = null;
        this.fireEvent('remove');
        this.wavesurfer.un('zoom', this._onRedraw);
        this.wavesurfer.un('redraw', this._onRedraw);
        this.wavesurfer.fireEvent('region-removed', this);
      }
    }
    /**
     * Play the audio region.
     * @param {number} start Optional offset to start playing at
     */

  }, {
    key: "play",
    value: function play(start) {
      var s = start || this.start;
      this.wavesurfer.play(s, this.end);
      this.fireEvent('play');
      this.wavesurfer.fireEvent('region-play', this);
    }
    /**
     * Play the audio region in a loop.
     * @param {number} start Optional offset to start playing at
     * */

  }, {
    key: "playLoop",
    value: function playLoop(start) {
      this.loop = true;
      this.play(start);
    }
    /**
     * Set looping on/off.
     * @param {boolean} loop True if should play in loop
     */

  }, {
    key: "setLoop",
    value: function setLoop(loop) {
      this.loop = loop;
    }
    /* Render a region as a DOM element. */

  }, {
    key: "render",
    value: function render() {
      this.element = this.util.withOrientation(this.wrapper.appendChild(document.createElement('region')), this.vertical);
      this.element.className = 'wavesurfer-region';

      if (this.showTooltip) {
        this.element.title = this.formatTime(this.start, this.end);
      }

      this.element.setAttribute('data-id', this.id);

      for (var attrname in this.attributes) {
        this.element.setAttribute('data-region-' + attrname, this.attributes[attrname]);
      }

      this.style(this.element, {
        position: 'absolute',
        zIndex: 3,
        height: this.regionHeight,
        top: this.marginTop
      });
      /* Resize handles */

      if (this.resize) {
        this.handleLeftEl = this.util.withOrientation(this.element.appendChild(document.createElement('handle')), this.vertical);
        this.handleRightEl = this.util.withOrientation(this.element.appendChild(document.createElement('handle')), this.vertical);
        this.handleLeftEl.className = 'wavesurfer-handle wavesurfer-handle-start';
        this.handleRightEl.className = 'wavesurfer-handle wavesurfer-handle-end'; // Default CSS properties for both handles.

        var css = {
          cursor: this.vertical ? 'row-resize' : 'col-resize',
          position: 'absolute',
          top: '0px',
          width: '2px',
          height: '100%',
          backgroundColor: 'rgba(0, 0, 0, 1)'
        }; // Merge CSS properties per handle.

        var handleLeftCss = this.handleStyle.left !== 'none' ? Object.assign({
          left: '0px'
        }, css, this.handleStyle.left) : null;
        var handleRightCss = this.handleStyle.right !== 'none' ? Object.assign({
          right: '0px'
        }, css, this.handleStyle.right) : null;

        if (handleLeftCss) {
          this.style(this.handleLeftEl, handleLeftCss);
        }

        if (handleRightCss) {
          this.style(this.handleRightEl, handleRightCss);
        }
      }

      this.updateRender();
      this.bindEvents();
    }
  }, {
    key: "formatTime",
    value: function formatTime(start, end) {
      if (this.formatTimeCallback) {
        return this.formatTimeCallback(start, end);
      }

      return (start == end ? [start] : [start, end]).map(function (time) {
        return [Math.floor(time % 3600 / 60), // minutes
        ('00' + Math.floor(time % 60)).slice(-2) // seconds
        ].join(':');
      }).join('-');
    }
  }, {
    key: "getWidth",
    value: function getWidth() {
      return this.wavesurfer.drawer.width / this.wavesurfer.params.pixelRatio;
    }
    /* Update element's position, width, color. */

  }, {
    key: "updateRender",
    value: function updateRender() {
      // duration varies during loading process, so don't overwrite important data
      var dur = this.wavesurfer.getDuration();
      var width = this.getWidth();
      var startLimited = this.start;
      var endLimited = this.end;

      if (startLimited < 0) {
        startLimited = 0;
        endLimited = endLimited - startLimited;
      }

      if (endLimited > dur) {
        endLimited = dur;
        startLimited = dur - (endLimited - startLimited);
      }

      if (this.minLength != null) {
        endLimited = Math.max(startLimited + this.minLength, endLimited);
      }

      if (this.maxLength != null) {
        endLimited = Math.min(startLimited + this.maxLength, endLimited);
      }

      if (this.element != null) {
        // Calculate the left and width values of the region such that
        // no gaps appear between regions.
        var left = Math.round(startLimited / dur * width);
        var regionWidth = Math.round(endLimited / dur * width) - left;
        this.style(this.element, {
          left: left + 'px',
          width: regionWidth + 'px',
          backgroundColor: this.color,
          cursor: this.drag ? 'move' : 'default'
        });

        for (var attrname in this.attributes) {
          this.element.setAttribute('data-region-' + attrname, this.attributes[attrname]);
        }

        if (this.showTooltip) {
          this.element.title = this.formatTime(this.start, this.end);
        }
      }
    }
    /* Bind audio events. */

  }, {
    key: "bindInOut",
    value: function bindInOut() {
      var _this2 = this;

      this.firedIn = false;
      this.firedOut = false;

      var onProcess = function onProcess(time) {
        var start = Math.round(_this2.start * 10) / 10;
        var end = Math.round(_this2.end * 10) / 10;
        time = Math.round(time * 10) / 10;

        if (!_this2.firedOut && _this2.firedIn && (start > time || end <= time)) {
          _this2.firedOut = true;
          _this2.firedIn = false;

          _this2.fireEvent('out');

          _this2.wavesurfer.fireEvent('region-out', _this2);
        }

        if (!_this2.firedIn && start <= time && end > time) {
          _this2.firedIn = true;
          _this2.firedOut = false;

          _this2.fireEvent('in');

          _this2.wavesurfer.fireEvent('region-in', _this2);
        }
      };

      this.wavesurfer.backend.on('audioprocess', onProcess);
      this.on('remove', function () {
        _this2.wavesurfer.backend.un('audioprocess', onProcess);
      });
      /* Loop playback. */

      this.on('out', function () {
        if (_this2.loop) {
          var realTime = _this2.wavesurfer.getCurrentTime();

          if (realTime >= _this2.start && realTime <= _this2.end) {
            _this2.wavesurfer.play(_this2.start);
          }
        }
      });
    }
    /* Bind DOM events. */

  }, {
    key: "bindEvents",
    value: function bindEvents() {
      var _this3 = this;

      var preventContextMenu = this.preventContextMenu;
      this.element.addEventListener('mouseenter', function (e) {
        _this3.fireEvent('mouseenter', e);

        _this3.wavesurfer.fireEvent('region-mouseenter', _this3, e);
      });
      this.element.addEventListener('mouseleave', function (e) {
        _this3.fireEvent('mouseleave', e);

        _this3.wavesurfer.fireEvent('region-mouseleave', _this3, e);
      });
      this.element.addEventListener('click', function (e) {
        e.preventDefault();

        _this3.fireEvent('click', e);

        _this3.wavesurfer.fireEvent('region-click', _this3, e);
      });
      this.element.addEventListener('dblclick', function (e) {
        e.stopPropagation();
        e.preventDefault();

        _this3.fireEvent('dblclick', e);

        _this3.wavesurfer.fireEvent('region-dblclick', _this3, e);
      });
      this.element.addEventListener('contextmenu', function (e) {
        if (preventContextMenu) {
          e.preventDefault();
        }

        _this3.fireEvent('contextmenu', e);

        _this3.wavesurfer.fireEvent('region-contextmenu', _this3, e);
      });
      /* Drag or resize on mousemove. */

      if (this.drag || this.resize) {
        this.bindDragEvents();
      }
    }
  }, {
    key: "bindDragEvents",
    value: function bindDragEvents() {
      var _this4 = this;

      var container = this.wavesurfer.drawer.container;
      var scrollSpeed = this.scrollSpeed;
      var scrollThreshold = this.scrollThreshold;
      var startTime;
      var touchId;
      var drag;
      var maxScroll;
      var resize;
      var updated = false;
      var scrollDirection;
      var wrapperRect;
      var regionLeftHalfTime;
      var regionRightHalfTime; // Scroll when the user is dragging within the threshold

      var edgeScroll = function edgeScroll(event) {
        var orientedEvent = _this4.util.withOrientation(event, _this4.vertical);

        var duration = _this4.wavesurfer.getDuration();

        if (!scrollDirection || !drag && !resize) {
          return;
        }

        var x = orientedEvent.clientX;
        var distanceBetweenCursorAndWrapperEdge = 0;
        var regionHalfTimeWidth = 0;
        var adjustment = 0; // Get the currently selected time according to the mouse position

        var time = _this4.regionsUtil.getRegionSnapToGridValue(_this4.wavesurfer.drawer.handleEvent(event) * duration);

        if (drag) {
          // Considering the point of contact with the region while edgescrolling
          if (scrollDirection === -1) {
            regionHalfTimeWidth = regionLeftHalfTime * _this4.wavesurfer.params.minPxPerSec;
            distanceBetweenCursorAndWrapperEdge = x - wrapperRect.left;
          } else {
            regionHalfTimeWidth = regionRightHalfTime * _this4.wavesurfer.params.minPxPerSec;
            distanceBetweenCursorAndWrapperEdge = wrapperRect.right - x;
          }
        } else {
          // Considering minLength while edgescroll
          var minLength = _this4.minLength;

          if (!minLength) {
            minLength = 0;
          }

          if (resize === 'start') {
            if (time > _this4.end - minLength) {
              time = _this4.end - minLength;
              adjustment = scrollSpeed * scrollDirection;
            }

            if (time < 0) {
              time = 0;
            }
          } else if (resize === 'end') {
            if (time < _this4.start + minLength) {
              time = _this4.start + minLength;
              adjustment = scrollSpeed * scrollDirection;
            }

            if (time > duration) {
              time = duration;
            }
          }
        } // Don't edgescroll if region has reached min or max limit


        var wrapperScrollLeft = _this4.wrapper.scrollLeft;

        if (scrollDirection === -1) {
          if (Math.round(wrapperScrollLeft) === 0) {
            return;
          }

          if (Math.round(wrapperScrollLeft - regionHalfTimeWidth + distanceBetweenCursorAndWrapperEdge) <= 0) {
            return;
          }
        } else {
          if (Math.round(wrapperScrollLeft) === maxScroll) {
            return;
          }

          if (Math.round(wrapperScrollLeft + regionHalfTimeWidth - distanceBetweenCursorAndWrapperEdge) >= maxScroll) {
            return;
          }
        } // Update scroll position


        var scrollLeft = wrapperScrollLeft - adjustment + scrollSpeed * scrollDirection;

        if (scrollDirection === -1) {
          var calculatedLeft = Math.max(0 + regionHalfTimeWidth - distanceBetweenCursorAndWrapperEdge, scrollLeft);
          _this4.wrapper.scrollLeft = scrollLeft = calculatedLeft;
        } else {
          var calculatedRight = Math.min(maxScroll - regionHalfTimeWidth + distanceBetweenCursorAndWrapperEdge, scrollLeft);
          _this4.wrapper.scrollLeft = scrollLeft = calculatedRight;
        }

        var delta = time - startTime;
        startTime = time; // Continue dragging or resizing

        drag ? _this4.onDrag(delta) : _this4.onResize(delta, resize); // Repeat

        window.requestAnimationFrame(function () {
          edgeScroll(event);
        });
      };

      var onDown = function onDown(event) {
        var duration = _this4.wavesurfer.getDuration();

        if (event.touches && event.touches.length > 1) {
          return;
        }

        touchId = event.targetTouches ? event.targetTouches[0].identifier : null; // stop the event propagation, if this region is resizable or draggable
        // and the event is therefore handled here.

        if (_this4.drag || _this4.resize) {
          event.stopPropagation();
        } // Store the selected startTime we begun dragging or resizing


        startTime = _this4.regionsUtil.getRegionSnapToGridValue(_this4.wavesurfer.drawer.handleEvent(event, true) * duration); // Store the selected point of contact when we begin dragging

        regionLeftHalfTime = startTime - _this4.start;
        regionRightHalfTime = _this4.end - startTime; // Store for scroll calculations

        maxScroll = _this4.wrapper.scrollWidth - _this4.wrapper.clientWidth;
        wrapperRect = _this4.util.withOrientation(_this4.wrapper.getBoundingClientRect(), _this4.vertical);
        _this4.isResizing = false;
        _this4.isDragging = false;

        if (event.target.tagName.toLowerCase() === 'handle') {
          _this4.isResizing = true;
          resize = event.target.classList.contains('wavesurfer-handle-start') ? 'start' : 'end';
        } else {
          _this4.isDragging = true;
          drag = true;
          resize = false;
        }
      };

      var onUp = function onUp(event) {
        if (event.touches && event.touches.length > 1) {
          return;
        }

        if (drag || resize) {
          _this4.isDragging = false;
          _this4.isResizing = false;
          drag = false;
          scrollDirection = null;
          resize = false;
        }

        if (updated) {
          updated = false;

          _this4.util.preventClick();

          _this4.fireEvent('update-end', event);

          _this4.wavesurfer.fireEvent('region-update-end', _this4, event);
        }
      };

      var onMove = function onMove(event) {
        var duration = _this4.wavesurfer.getDuration();

        var orientedEvent = _this4.util.withOrientation(event, _this4.vertical);

        if (event.touches && event.touches.length > 1) {
          return;
        }

        if (event.targetTouches && event.targetTouches[0].identifier != touchId) {
          return;
        }

        if (!drag && !resize) {
          return;
        }

        var oldTime = startTime;

        var time = _this4.regionsUtil.getRegionSnapToGridValue(_this4.wavesurfer.drawer.handleEvent(event) * duration);

        if (drag) {
          // To maintain relative cursor start point while dragging
          var maxEnd = _this4.wavesurfer.getDuration();

          if (time > maxEnd - regionRightHalfTime) {
            time = maxEnd - regionRightHalfTime;
          }

          if (time - regionLeftHalfTime < 0) {
            time = regionLeftHalfTime;
          }
        }

        if (resize) {
          // To maintain relative cursor start point while resizing
          // we have to handle for minLength
          var minLength = _this4.minLength;

          if (!minLength) {
            minLength = 0;
          }

          if (resize === 'start') {
            if (time > _this4.end - minLength) {
              time = _this4.end - minLength;
            }

            if (time < 0) {
              time = 0;
            }
          } else if (resize === 'end') {
            if (time < _this4.start + minLength) {
              time = _this4.start + minLength;
            }

            if (time > duration) {
              time = duration;
            }
          }
        }

        var delta = time - startTime;
        startTime = time; // Drag

        if (_this4.drag && drag) {
          updated = updated || !!delta;

          _this4.onDrag(delta);
        } // Resize


        if (_this4.resize && resize) {
          updated = updated || !!delta;

          _this4.onResize(delta, resize);
        }

        if (_this4.scroll && container.clientWidth < _this4.wrapper.scrollWidth) {
          // Triggering edgescroll from within edgeScrollWidth
          var x = orientedEvent.clientX; // Check direction

          if (x < wrapperRect.left + _this4.edgeScrollWidth) {
            scrollDirection = -1;
          } else if (x > wrapperRect.right - _this4.edgeScrollWidth) {
            scrollDirection = 1;
          } else {
            scrollDirection = null;
          }

          if (scrollDirection) {
            edgeScroll(event);
          }
        }
      };

      this.element.addEventListener('mousedown', onDown);
      this.element.addEventListener('touchstart', onDown);
      document.body.addEventListener('mousemove', onMove);
      document.body.addEventListener('touchmove', onMove, {
        passive: false
      });
      document.addEventListener('mouseup', onUp);
      document.body.addEventListener('touchend', onUp);
      this.on('remove', function () {
        document.removeEventListener('mouseup', onUp);
        document.body.removeEventListener('touchend', onUp);
        document.body.removeEventListener('mousemove', onMove);
        document.body.removeEventListener('touchmove', onMove);
      });
      this.wavesurfer.on('destroy', function () {
        document.removeEventListener('mouseup', onUp);
        document.body.removeEventListener('touchend', onUp);
      });
    }
  }, {
    key: "onDrag",
    value: function onDrag(delta) {
      var maxEnd = this.wavesurfer.getDuration();

      if (this.end + delta > maxEnd) {
        delta = maxEnd - this.end;
      }

      if (this.start + delta < 0) {
        delta = this.start * -1;
      }

      var eventParams = {
        direction: this._getDragDirection(delta),
        action: 'drag'
      };
      this.update({
        start: this.start + delta,
        end: this.end + delta
      }, eventParams);
    }
    /**
     * Returns the direction of dragging region based on delta
     * Negative delta means region is moving to the left
     * Positive - to the right
     * For zero delta the direction is not defined
     * @param {number} delta Drag offset
     * @returns {string|null} Direction 'left', 'right' or null
     */

  }, {
    key: "_getDragDirection",
    value: function _getDragDirection(delta) {
      if (delta < 0) {
        return 'left';
      }

      if (delta > 0) {
        return 'right';
      }

      return null;
    }
    /**
     * @example
     * onResize(-5, 'start') // Moves the start point 5 seconds back
     * onResize(0.5, 'end') // Moves the end point 0.5 seconds forward
     *
     * @param {number} delta How much to add or subtract, given in seconds
     * @param {string} direction 'start 'or 'end'
     */

  }, {
    key: "onResize",
    value: function onResize(delta, direction) {
      var duration = this.wavesurfer.getDuration();
      var eventParams = {
        action: 'resize',
        direction: direction === 'start' ? 'left' : 'right'
      };

      if (direction === 'start') {
        // Check if changing the start by the given delta would result in the region being smaller than minLength
        if (delta > 0 && this.end - (this.start + delta) < this.minLength) {
          delta = this.end - this.minLength - this.start;
        } // Check if changing the start by the given delta would result in the region being larger than maxLength


        if (delta < 0 && this.end - (this.start + delta) > this.maxLength) {
          delta = this.end - this.start - this.maxLength;
        }

        if (delta < 0 && this.start + delta < 0) {
          delta = this.start * -1;
        }

        this.update({
          start: Math.min(this.start + delta, this.end),
          end: Math.max(this.start + delta, this.end)
        }, eventParams);
      } else {
        // Check if changing the end by the given delta would result in the region being smaller than minLength
        if (delta < 0 && this.end + delta - this.start < this.minLength) {
          delta = this.start + this.minLength - this.end;
        } // Check if changing the end by the given delta would result in the region being larger than maxLength


        if (delta > 0 && this.end + delta - this.start > this.maxLength) {
          delta = this.maxLength - (this.end - this.start);
        }

        if (delta > 0 && this.end + delta > duration) {
          delta = duration - this.end;
        }

        this.update({
          start: Math.min(this.end + delta, this.start),
          end: Math.max(this.end + delta, this.start)
        }, eventParams);
      }
    }
  }, {
    key: "updateHandlesResize",
    value: function updateHandlesResize(resize) {
      var cursorStyle;

      if (resize) {
        cursorStyle = this.vertical ? 'row-resize' : 'col-resize';
      } else {
        cursorStyle = 'auto';
      }

      this.handleLeftEl && this.style(this.handleLeftEl, {
        cursor: cursorStyle
      });
      this.handleRightEl && this.style(this.handleRightEl, {
        cursor: cursorStyle
      });
    }
  }]);

  return Region;
}();

exports.Region = Region;

/***/ })

/******/ 	});
/************************************************************************/
/******/ 	// The module cache
/******/ 	var __webpack_module_cache__ = {};
/******/ 	
/******/ 	// The require function
/******/ 	function __webpack_require__(moduleId) {
/******/ 		// Check if module is in cache
/******/ 		var cachedModule = __webpack_module_cache__[moduleId];
/******/ 		if (cachedModule !== undefined) {
/******/ 			return cachedModule.exports;
/******/ 		}
/******/ 		// Create a new module (and put it into the cache)
/******/ 		var module = __webpack_module_cache__[moduleId] = {
/******/ 			// no module.id needed
/******/ 			// no module.loaded needed
/******/ 			exports: {}
/******/ 		};
/******/ 	
/******/ 		// Execute the module function
/******/ 		__webpack_modules__[moduleId](module, module.exports, __webpack_require__);
/******/ 	
/******/ 		// Return the exports of the module
/******/ 		return module.exports;
/******/ 	}
/******/ 	
/************************************************************************/
/******/ 	
/******/ 	// startup
/******/ 	// Load entry module and return exports
/******/ 	// This entry module is referenced by other modules so it can't be inlined
/******/ 	var __webpack_exports__ = __webpack_require__("./src/plugin/regions/index.js");
/******/ 	
/******/ 	return __webpack_exports__;
/******/ })()
;
});
//# sourceMappingURL=wavesurfer.regions.js.map