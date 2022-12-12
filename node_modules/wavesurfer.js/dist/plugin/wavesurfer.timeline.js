/*!
 * wavesurfer.js timeline plugin 6.1.0 (2022-03-31)
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
		root["WaveSurfer"] = root["WaveSurfer"] || {}, root["WaveSurfer"]["timeline"] = factory();
})(self, function() {
return /******/ (() => { // webpackBootstrap
/******/ 	"use strict";
/******/ 	var __webpack_modules__ = ({

/***/ "./src/plugin/timeline/index.js":
/*!**************************************!*\
  !*** ./src/plugin/timeline/index.js ***!
  \**************************************/
/***/ ((module, exports) => {



Object.defineProperty(exports, "__esModule", ({
  value: true
}));
exports["default"] = void 0;

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } }

function _createClass(Constructor, protoProps, staticProps) { if (protoProps) _defineProperties(Constructor.prototype, protoProps); if (staticProps) _defineProperties(Constructor, staticProps); Object.defineProperty(Constructor, "prototype", { writable: false }); return Constructor; }

function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }

/**
 * @typedef {Object} TimelinePluginParams
 * @desc Extends the `WavesurferParams` wavesurfer was initialised with
 * @property {!string|HTMLElement} container CSS selector or HTML element where
 * the timeline should be drawn. This is the only required parameter.
 * @property {number} notchPercentHeight=90 Height of notches in percent
 * @property {string} unlabeledNotchColor='#c0c0c0' The colour of the notches
 * that do not have labels
 * @property {string} primaryColor='#000' The colour of the main notches
 * @property {string} secondaryColor='#c0c0c0' The colour of the secondary
 * notches
 * @property {string} primaryFontColor='#000' The colour of the labels next to
 * the main notches
 * @property {string} secondaryFontColor='#000' The colour of the labels next to
 * the secondary notches
 * @property {number} labelPadding=5 The padding between the label and the notch
 * @property {?number} zoomDebounce A debounce timeout to increase rendering
 * performance for large files
 * @property {string} fontFamily='Arial'
 * @property {number} fontSize=10 Font size of labels in pixels
 * @property {?number} duration Length of the track in seconds. Overrides
 * getDuration() for setting length of timeline
 * @property {function} formatTimeCallback (sec, pxPerSec) -> label
 * @property {function} timeInterval (pxPerSec) -> seconds between notches
 * @property {function} primaryLabelInterval (pxPerSec) -> cadence between
 * labels in primary color
 * @property {function} secondaryLabelInterval (pxPerSec) -> cadence between
 * labels in secondary color
 * @property {?number} offset Offset for the timeline start in seconds. May also be
 * negative.
 * @property {?boolean} deferInit Set to true to manually call
 * `initPlugin('timeline')`
 */

/**
 * Adds a timeline to the waveform.
 *
 * @implements {PluginClass}
 * @extends {Observer}
 * @example
 * // es6
 * import TimelinePlugin from 'wavesurfer.timeline.js';
 *
 * // commonjs
 * var TimelinePlugin = require('wavesurfer.timeline.js');
 *
 * // if you are using <script> tags
 * var TimelinePlugin = window.WaveSurfer.timeline;
 *
 * // ... initialising wavesurfer with the plugin
 * var wavesurfer = WaveSurfer.create({
 *   // wavesurfer options ...
 *   plugins: [
 *     TimelinePlugin.create({
 *       // plugin options ...
 *     })
 *   ]
 * });
 */
var TimelinePlugin = /*#__PURE__*/function () {
  /**
   * Creates an instance of TimelinePlugin.
   *
   * You probably want to use TimelinePlugin.create()
   *
   * @param {TimelinePluginParams} params Plugin parameters
   * @param {object} ws Wavesurfer instance
   */
  function TimelinePlugin(params, _ws) {
    var _this = this;

    _classCallCheck(this, TimelinePlugin);

    _defineProperty(this, "_onScroll", function () {
      if (_this.wrapper && _this.drawer.wrapper) {
        _this.wrapper.scrollLeft = _this.drawer.wrapper.scrollLeft;
      }
    });

    _defineProperty(this, "_onRedraw", function () {
      return _this.render();
    });

    _defineProperty(this, "_onReady", function () {
      var ws = _this.wavesurfer;
      _this.drawer = ws.drawer;
      _this.pixelRatio = ws.drawer.params.pixelRatio;
      _this.maxCanvasWidth = ws.drawer.maxCanvasWidth || ws.drawer.width;
      _this.maxCanvasElementWidth = ws.drawer.maxCanvasElementWidth || Math.round(_this.maxCanvasWidth / _this.pixelRatio); // add listeners

      ws.drawer.wrapper.addEventListener('scroll', _this._onScroll);
      ws.on('redraw', _this._onRedraw);
      ws.on('zoom', _this._onZoom);

      _this.render();
    });

    _defineProperty(this, "_onWrapperClick", function (e) {
      e.preventDefault();
      var relX = 'offsetX' in e ? e.offsetX : e.layerX;

      _this.fireEvent('click', relX / _this.wrapper.scrollWidth || 0);
    });

    this.container = 'string' == typeof params.container ? document.querySelector(params.container) : params.container;

    if (!this.container) {
      throw new Error('No container for wavesurfer timeline');
    }

    this.wavesurfer = _ws;
    this.util = _ws.util;
    this.params = Object.assign({}, {
      height: 20,
      notchPercentHeight: 90,
      labelPadding: 5,
      unlabeledNotchColor: '#c0c0c0',
      primaryColor: '#000',
      secondaryColor: '#c0c0c0',
      primaryFontColor: '#000',
      secondaryFontColor: '#000',
      fontFamily: 'Arial',
      fontSize: 10,
      duration: null,
      zoomDebounce: false,
      formatTimeCallback: this.defaultFormatTimeCallback,
      timeInterval: this.defaultTimeInterval,
      primaryLabelInterval: this.defaultPrimaryLabelInterval,
      secondaryLabelInterval: this.defaultSecondaryLabelInterval,
      offset: 0
    }, params);
    this.canvases = [];
    this.wrapper = null;
    this.drawer = null;
    this.pixelRatio = null;
    this.maxCanvasWidth = null;
    this.maxCanvasElementWidth = null;
    /**
     * This event handler has to be in the constructor function because it
     * relies on the debounce function which is only available after
     * instantiation
     *
     * Use a debounced function if `params.zoomDebounce` is defined
     *
     * @returns {void}
     */

    this._onZoom = this.params.zoomDebounce ? this.wavesurfer.util.debounce(function () {
      return _this.render();
    }, this.params.zoomDebounce) : function () {
      return _this.render();
    };
  }
  /**
   * Initialisation function used by the plugin API
   */


  _createClass(TimelinePlugin, [{
    key: "init",
    value: function init() {
      // Check if ws is ready
      if (this.wavesurfer.isReady) {
        this._onReady();
      } else {
        this.wavesurfer.once('ready', this._onReady);
      }
    }
    /**
     * Destroy function used by the plugin API
     */

  }, {
    key: "destroy",
    value: function destroy() {
      this.unAll();
      this.wavesurfer.un('redraw', this._onRedraw);
      this.wavesurfer.un('zoom', this._onZoom);
      this.wavesurfer.un('ready', this._onReady);
      this.wavesurfer.drawer.wrapper.removeEventListener('scroll', this._onScroll);

      if (this.wrapper && this.wrapper.parentNode) {
        this.wrapper.removeEventListener('click', this._onWrapperClick);
        this.wrapper.parentNode.removeChild(this.wrapper);
        this.wrapper = null;
      }
    }
    /**
     * Create a timeline element to wrap the canvases drawn by this plugin
     *
     */

  }, {
    key: "createWrapper",
    value: function createWrapper() {
      var wsParams = this.wavesurfer.params;
      this.container.innerHTML = '';
      this.wrapper = this.container.appendChild(document.createElement('timeline'));
      this.util.style(this.wrapper, {
        display: 'block',
        position: 'relative',
        userSelect: 'none',
        webkitUserSelect: 'none',
        height: "".concat(this.params.height, "px")
      });

      if (wsParams.fillParent || wsParams.scrollParent) {
        this.util.style(this.wrapper, {
          width: '100%',
          overflowX: 'hidden',
          overflowY: 'hidden'
        });
      }

      this.wrapper.addEventListener('click', this._onWrapperClick);
    }
    /**
     * Render the timeline (also updates the already rendered timeline)
     *
     */

  }, {
    key: "render",
    value: function render() {
      if (!this.wrapper) {
        this.createWrapper();
      }

      this.updateCanvases();
      this.updateCanvasesPositioning();
      this.renderCanvases();
    }
    /**
     * Add new timeline canvas
     *
     */

  }, {
    key: "addCanvas",
    value: function addCanvas() {
      var canvas = this.wrapper.appendChild(document.createElement('canvas'));
      this.canvases.push(canvas);
      this.util.style(canvas, {
        position: 'absolute',
        zIndex: 4
      });
    }
    /**
     * Remove timeline canvas
     *
     */

  }, {
    key: "removeCanvas",
    value: function removeCanvas() {
      var canvas = this.canvases.pop();
      canvas.parentElement.removeChild(canvas);
    }
    /**
     * Make sure the correct of timeline canvas elements exist and are cached in
     * this.canvases
     *
     */

  }, {
    key: "updateCanvases",
    value: function updateCanvases() {
      var totalWidth = Math.round(this.drawer.wrapper.scrollWidth);
      var requiredCanvases = Math.ceil(totalWidth / this.maxCanvasElementWidth);

      while (this.canvases.length < requiredCanvases) {
        this.addCanvas();
      }

      while (this.canvases.length > requiredCanvases) {
        this.removeCanvas();
      }
    }
    /**
     * Update the dimensions and positioning style for all the timeline canvases
     *
     */

  }, {
    key: "updateCanvasesPositioning",
    value: function updateCanvasesPositioning() {
      var _this2 = this;

      // cache length for performance
      var canvasesLength = this.canvases.length;
      this.canvases.forEach(function (canvas, i) {
        // canvas width is the max element width, or if it is the last the
        // required width
        var canvasWidth = i === canvasesLength - 1 ? _this2.drawer.wrapper.scrollWidth - _this2.maxCanvasElementWidth * (canvasesLength - 1) : _this2.maxCanvasElementWidth; // set dimensions and style

        canvas.width = canvasWidth * _this2.pixelRatio; // on certain pixel ratios the canvas appears cut off at the bottom,
        // therefore leave 1px extra

        canvas.height = (_this2.params.height + 1) * _this2.pixelRatio;

        _this2.util.style(canvas, {
          width: "".concat(canvasWidth, "px"),
          height: "".concat(_this2.params.height, "px"),
          left: "".concat(i * _this2.maxCanvasElementWidth, "px")
        });
      });
    }
    /**
     * Render the timeline labels and notches
     *
     */

  }, {
    key: "renderCanvases",
    value: function renderCanvases() {
      var _this3 = this;

      var duration = this.params.duration || this.wavesurfer.backend.getDuration();

      if (duration <= 0) {
        return;
      }

      var wsParams = this.wavesurfer.params;
      var fontSize = this.params.fontSize * wsParams.pixelRatio;
      var totalSeconds = parseInt(duration, 10) + 1;
      var width = wsParams.fillParent && !wsParams.scrollParent ? this.drawer.getWidth() : this.drawer.wrapper.scrollWidth * wsParams.pixelRatio;
      var height1 = this.params.height * this.pixelRatio;
      var height2 = this.params.height * (this.params.notchPercentHeight / 100) * this.pixelRatio;
      var pixelsPerSecond = width / duration;
      var formatTime = this.params.formatTimeCallback; // if parameter is function, call the function with
      // pixelsPerSecond, otherwise simply take the value as-is

      var intervalFnOrVal = function intervalFnOrVal(option) {
        return typeof option === 'function' ? option(pixelsPerSecond) : option;
      };

      var timeInterval = intervalFnOrVal(this.params.timeInterval);
      var primaryLabelInterval = intervalFnOrVal(this.params.primaryLabelInterval);
      var secondaryLabelInterval = intervalFnOrVal(this.params.secondaryLabelInterval);
      var curPixel = pixelsPerSecond * this.params.offset;
      var curSeconds = 0;
      var i; // build an array of position data with index, second and pixel data,
      // this is then used multiple times below

      var positioning = []; // render until end in case we have a negative offset

      var renderSeconds = this.params.offset < 0 ? totalSeconds - this.params.offset : totalSeconds;

      for (i = 0; i < renderSeconds / timeInterval; i++) {
        positioning.push([i, curSeconds, curPixel]);
        curSeconds += timeInterval;
        curPixel += pixelsPerSecond * timeInterval;
      } // iterate over each position


      var renderPositions = function renderPositions(cb) {
        positioning.forEach(function (pos) {
          cb(pos[0], pos[1], pos[2]);
        });
      }; // render primary labels


      this.setFillStyles(this.params.primaryColor);
      this.setFonts("".concat(fontSize, "px ").concat(this.params.fontFamily));
      this.setFillStyles(this.params.primaryFontColor);
      renderPositions(function (i, curSeconds, curPixel) {
        if (i % primaryLabelInterval === 0) {
          _this3.fillRect(curPixel, 0, 1, height1);

          _this3.fillText(formatTime(curSeconds, pixelsPerSecond), curPixel + _this3.params.labelPadding * _this3.pixelRatio, height1);
        }
      }); // render secondary labels

      this.setFillStyles(this.params.secondaryColor);
      this.setFonts("".concat(fontSize, "px ").concat(this.params.fontFamily));
      this.setFillStyles(this.params.secondaryFontColor);
      renderPositions(function (i, curSeconds, curPixel) {
        if (i % secondaryLabelInterval === 0) {
          _this3.fillRect(curPixel, 0, 1, height1);

          _this3.fillText(formatTime(curSeconds, pixelsPerSecond), curPixel + _this3.params.labelPadding * _this3.pixelRatio, height1);
        }
      }); // render the actual notches (when no labels are used)

      this.setFillStyles(this.params.unlabeledNotchColor);
      renderPositions(function (i, curSeconds, curPixel) {
        if (i % secondaryLabelInterval !== 0 && i % primaryLabelInterval !== 0) {
          _this3.fillRect(curPixel, 0, 1, height2);
        }
      });
    }
    /**
     * Set the canvas fill style
     *
     * @param {DOMString|CanvasGradient|CanvasPattern} fillStyle Fill style to
     * use
     */

  }, {
    key: "setFillStyles",
    value: function setFillStyles(fillStyle) {
      this.canvases.forEach(function (canvas) {
        var context = canvas.getContext('2d');

        if (context) {
          context.fillStyle = fillStyle;
        }
      });
    }
    /**
     * Set the canvas font
     *
     * @param {DOMString} font Font to use
     */

  }, {
    key: "setFonts",
    value: function setFonts(font) {
      this.canvases.forEach(function (canvas) {
        var context = canvas.getContext('2d');

        if (context) {
          context.font = font;
        }
      });
    }
    /**
     * Draw a rectangle on the canvases
     *
     * (it figures out the offset for each canvas)
     *
     * @param {number} x X-position
     * @param {number} y Y-position
     * @param {number} width Width
     * @param {number} height Height
     */

  }, {
    key: "fillRect",
    value: function fillRect(x, y, width, height) {
      var _this4 = this;

      this.canvases.forEach(function (canvas, i) {
        var leftOffset = i * _this4.maxCanvasWidth;
        var intersection = {
          x1: Math.max(x, i * _this4.maxCanvasWidth),
          y1: y,
          x2: Math.min(x + width, i * _this4.maxCanvasWidth + canvas.width),
          y2: y + height
        };

        if (intersection.x1 < intersection.x2) {
          var context = canvas.getContext('2d');

          if (context) {
            context.fillRect(intersection.x1 - leftOffset, intersection.y1, intersection.x2 - intersection.x1, intersection.y2 - intersection.y1);
          }
        }
      });
    }
    /**
     * Fill a given text on the canvases
     *
     * @param {string} text Text to render
     * @param {number} x X-position
     * @param {number} y Y-position
     */

  }, {
    key: "fillText",
    value: function fillText(text, x, y) {
      var textWidth;
      var xOffset = 0;
      this.canvases.forEach(function (canvas) {
        var context = canvas.getContext('2d');

        if (context) {
          var canvasWidth = context.canvas.width;

          if (xOffset > x + textWidth) {
            return;
          }

          if (xOffset + canvasWidth > x && context) {
            textWidth = context.measureText(text).width;
            context.fillText(text, x - xOffset, y);
          }

          xOffset += canvasWidth;
        }
      });
    }
    /**
     * Turn the time into a suitable label for the time.
     *
     * @param {number} seconds Seconds to format
     * @param {number} pxPerSec Pixels per second
     * @returns {number} Time
     */

  }, {
    key: "defaultFormatTimeCallback",
    value: function defaultFormatTimeCallback(seconds, pxPerSec) {
      if (seconds / 60 > 1) {
        // calculate minutes and seconds from seconds count
        var minutes = parseInt(seconds / 60, 10);
        seconds = parseInt(seconds % 60, 10); // fill up seconds with zeroes

        seconds = seconds < 10 ? '0' + seconds : seconds;
        return "".concat(minutes, ":").concat(seconds);
      }

      return Math.round(seconds * 1000) / 1000;
    }
    /**
     * Return how many seconds should be between each notch
     *
     * @param {number} pxPerSec Pixels per second
     * @returns {number} Time
     */

  }, {
    key: "defaultTimeInterval",
    value: function defaultTimeInterval(pxPerSec) {
      if (pxPerSec >= 25) {
        return 1;
      } else if (pxPerSec * 5 >= 25) {
        return 5;
      } else if (pxPerSec * 15 >= 25) {
        return 15;
      }

      return Math.ceil(0.5 / pxPerSec) * 60;
    }
    /**
     * Return the cadence of notches that get labels in the primary color.
     *
     * @param {number} pxPerSec Pixels per second
     * @returns {number} Cadence
     */

  }, {
    key: "defaultPrimaryLabelInterval",
    value: function defaultPrimaryLabelInterval(pxPerSec) {
      if (pxPerSec >= 25) {
        return 10;
      } else if (pxPerSec * 5 >= 25) {
        return 6;
      } else if (pxPerSec * 15 >= 25) {
        return 4;
      }

      return 4;
    }
    /**
     * Return the cadence of notches that get labels in the secondary color.
     *
     * @param {number} pxPerSec Pixels per second
     * @returns {number} Cadence
     */

  }, {
    key: "defaultSecondaryLabelInterval",
    value: function defaultSecondaryLabelInterval(pxPerSec) {
      if (pxPerSec >= 25) {
        return 5;
      } else if (pxPerSec * 5 >= 25) {
        return 2;
      } else if (pxPerSec * 15 >= 25) {
        return 2;
      }

      return 2;
    }
  }], [{
    key: "create",
    value:
    /**
     * Timeline plugin definition factory
     *
     * This function must be used to create a plugin definition which can be
     * used by wavesurfer to correctly instantiate the plugin.
     *
     * @param  {TimelinePluginParams} params parameters use to initialise the plugin
     * @return {PluginDefinition} an object representing the plugin
     */
    function create(params) {
      return {
        name: 'timeline',
        deferInit: params && params.deferInit ? params.deferInit : false,
        params: params,
        instance: TimelinePlugin
      };
    } // event handlers

  }]);

  return TimelinePlugin;
}();

exports["default"] = TimelinePlugin;
module.exports = exports.default;

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
/******/ 	var __webpack_exports__ = __webpack_require__("./src/plugin/timeline/index.js");
/******/ 	
/******/ 	return __webpack_exports__;
/******/ })()
;
});
//# sourceMappingURL=wavesurfer.timeline.js.map