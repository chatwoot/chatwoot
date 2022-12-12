/*!
 * wavesurfer.js cursor plugin 6.1.0 (2022-03-31)
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
		root["WaveSurfer"] = root["WaveSurfer"] || {}, root["WaveSurfer"]["cursor"] = factory();
})(self, function() {
return /******/ (() => { // webpackBootstrap
/******/ 	"use strict";
/******/ 	var __webpack_modules__ = ({

/***/ "./src/plugin/cursor/index.js":
/*!************************************!*\
  !*** ./src/plugin/cursor/index.js ***!
  \************************************/
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
var CursorPlugin = /*#__PURE__*/function () {
  /**
   * Construct the plugin class. You probably want to use `CursorPlugin.create`
   * instead.
   *
   * @param {CursorPluginParams} params Plugin parameters
   * @param {object} ws Wavesurfer instance
   */
  function CursorPlugin(params, ws) {
    var _this = this;

    _classCallCheck(this, CursorPlugin);

    _defineProperty(this, "defaultParams", {
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
    });

    _defineProperty(this, "_onMousemove", function (e) {
      var event = _this.util.withOrientation(e, _this.wavesurfer.params.vertical);

      var bbox = _this.wrapper.getBoundingClientRect();

      var y = 0;
      var x = _this.wrapper.scrollLeft + event.clientX - bbox.left;

      var flip = bbox.right < event.clientX + _this.displayTime.getBoundingClientRect().width;

      if (_this.params.showTime && _this.params.followCursorY) {
        // follow y-position of the mouse
        y = event.clientY - (bbox.top + bbox.height / 2);
      }

      _this.updateCursorPosition(x, y, flip);
    });

    _defineProperty(this, "_onMouseenter", function () {
      return _this.showCursor();
    });

    _defineProperty(this, "_onMouseleave", function () {
      return _this.hideCursor();
    });

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

  _createClass(CursorPlugin, [{
    key: "_onReady",
    value: function _onReady() {
      this.wrapper = this.wavesurfer.drawer.wrapper;
      this.cursor = this.util.withOrientation(this.wrapper.appendChild(document.createElement('cursor')), this.wavesurfer.params.vertical);
      this.style(this.cursor, Object.assign({
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
      }, this.params.customStyle));

      if (this.params.showTime) {
        this.showTime = this.util.withOrientation(this.wrapper.appendChild(document.createElement('showTitle')), this.wavesurfer.params.vertical);
        this.style(this.showTime, Object.assign({
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
        }, this.params.customStyle));
        this.displayTime = this.util.withOrientation(this.showTime.appendChild(document.createElement('div')), this.wavesurfer.params.vertical);
        this.style(this.displayTime, Object.assign({
          display: 'inline',
          pointerEvents: 'none',
          margin: 'auto',
          visibility: 'hidden' // initial value will be hidden just for measuring purpose

        }, this.params.customShowTimeStyle)); // initial value to measure display width

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

  }, {
    key: "init",
    value: function init() {
      var _this2 = this;

      if (this.wavesurfer.isReady) {
        this._onReady();
      } else {
        this.wavesurfer.once('ready', function () {
          return _this2._onReady();
        });
      }
    }
    /**
     * Destroy the plugin (used by the Plugin API)
     */

  }, {
    key: "destroy",
    value: function destroy() {
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

  }, {
    key: "updateCursorPosition",
    value: function updateCursorPosition(xpos, ypos) {
      var flip = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : false;
      this.style(this.cursor, {
        left: "".concat(xpos, "px")
      });

      if (this.params.showTime) {
        var duration = this.wavesurfer.getDuration();
        var elementWidth = this.wavesurfer.drawer.width / this.wavesurfer.params.pixelRatio;
        var scrollWidth = this.wavesurfer.drawer.getScrollX();
        var scrollTime = duration / this.wavesurfer.drawer.width * scrollWidth;
        var timeValue = Math.max(0, (xpos - this.wrapper.scrollLeft) / elementWidth * duration) + scrollTime;
        var formatValue = this.formatTime(timeValue);

        if (flip) {
          var textOffset = this.displayTime.getBoundingClientRect().width;
          xpos -= textOffset;
        }

        this.style(this.showTime, {
          left: "".concat(xpos, "px"),
          top: "".concat(ypos, "px")
        });
        this.style(this.displayTime, {
          visibility: 'visible'
        });
        this.displayTime.innerHTML = "".concat(formatValue);
      }
    }
    /**
     * Show the cursor
     */

  }, {
    key: "showCursor",
    value: function showCursor() {
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

  }, {
    key: "hideCursor",
    value: function hideCursor() {
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

  }, {
    key: "formatTime",
    value: function formatTime(cursorTime) {
      cursorTime = isNaN(cursorTime) ? 0 : cursorTime;

      if (this.params.formatTimeCallback) {
        return this.params.formatTimeCallback(cursorTime);
      }

      return [cursorTime].map(function (time) {
        return [Math.floor(time % 3600 / 60), // minutes
        ('00' + Math.floor(time % 60)).slice(-2), // seconds
        ('000' + Math.floor(time % 1 * 1000)).slice(-3) // milliseconds
        ].join(':');
      });
    }
  }], [{
    key: "create",
    value:
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
    function create(params) {
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

  }]);

  return CursorPlugin;
}();

exports["default"] = CursorPlugin;
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
/******/ 	var __webpack_exports__ = __webpack_require__("./src/plugin/cursor/index.js");
/******/ 	
/******/ 	return __webpack_exports__;
/******/ })()
;
});
//# sourceMappingURL=wavesurfer.cursor.js.map