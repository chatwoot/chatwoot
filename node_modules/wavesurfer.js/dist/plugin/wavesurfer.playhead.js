/*!
 * wavesurfer.js playhead plugin 6.1.0 (2022-03-31)
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
		root["WaveSurfer"] = root["WaveSurfer"] || {}, root["WaveSurfer"]["playhead"] = factory();
})(self, function() {
return /******/ (() => { // webpackBootstrap
/******/ 	"use strict";
/******/ 	var __webpack_modules__ = ({

/***/ "./src/plugin/playhead/index.js":
/*!**************************************!*\
  !*** ./src/plugin/playhead/index.js ***!
  \**************************************/
/***/ ((module, exports) => {



Object.defineProperty(exports, "__esModule", ({
  value: true
}));
exports["default"] = void 0;

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } }

function _createClass(Constructor, protoProps, staticProps) { if (protoProps) _defineProperties(Constructor.prototype, protoProps); if (staticProps) _defineProperties(Constructor, staticProps); Object.defineProperty(Constructor, "prototype", { writable: false }); return Constructor; }

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
var DEFAULT_FILL_COLOR = '#CF2F00';

var PlayheadPlugin = /*#__PURE__*/function () {
  function PlayheadPlugin(params, ws) {
    var _this = this;

    _classCallCheck(this, PlayheadPlugin);

    this.params = params;
    this.options = {};
    ['draw', 'moveOnSeek', 'returnOnPause'].forEach(function (opt) {
      if (opt in params) {
        _this.options[opt] = params[opt];
      } else {
        _this.options[opt] = true;
      }
    });
    this.wavesurfer = ws;
    this.util = ws.util;
    this.style = this.util.style;
    this.markerWidth = 21;
    this.markerHeight = 16;
    this.playheadTime = 0;
    this.unFuns = [];

    this._onResize = function () {
      _this._updatePlayheadPosition();
    };

    this._onReady = function () {
      _this.wrapper = _this.wavesurfer.drawer.wrapper;

      _this._updatePlayheadPosition();
    };
  }

  _createClass(PlayheadPlugin, [{
    key: "_onBackendCreated",
    value: function _onBackendCreated() {
      var _this2 = this;

      this.wrapper = this.wavesurfer.drawer.wrapper;

      if (this.options.draw) {
        this._createPlayheadElement();

        window.addEventListener('resize', this._onResize, true);
        window.addEventListener('orientationchange', this._onResize, true);
        this.wavesurferOn('zoom', this._onResize);
      }

      this.wavesurferOn('pause', function () {
        if (_this2.options.returnOnPause) {
          _this2.wavesurfer.setCurrentTime(_this2.playheadTime);
        }
      });
      this.wavesurferOn('seek', function () {
        if (_this2.options.moveOnSeek) {
          _this2.playheadTime = _this2.wavesurfer.getCurrentTime();

          _this2._updatePlayheadPosition();
        }
      });
      this.playheadTime = this.wavesurfer.getCurrentTime();
    }
  }, {
    key: "wavesurferOn",
    value: function wavesurferOn(ev, fn) {
      var _this3 = this;

      var ret = this.wavesurfer.on(ev, fn);
      this.unFuns.push(function () {
        _this3.wavesurfer.un(ev, fn);
      });
      return ret;
    }
  }, {
    key: "init",
    value: function init() {
      var _this4 = this;

      if (this.wavesurfer.isReady) {
        this._onBackendCreated();

        this._onReady();
      } else {
        var r;
        this.wavesurfer.once('ready', function () {
          return _this4._onReady();
        });
        this.wavesurfer.once('backend-created', function () {
          return _this4._onBackendCreated();
        });
      }
    }
  }, {
    key: "destroy",
    value: function destroy() {
      this.unFuns.forEach(function (f) {
        return f();
      });
      this.unFuns = [];
      this.wrapper.removeChild(this.element);
      window.removeEventListener('resize', this._onResize, true);
      window.removeEventListener('orientationchange', this._onResize, true);
    }
  }, {
    key: "setPlayheadTime",
    value: function setPlayheadTime(time) {
      this.playheadTime = time;

      if (!this.wavesurfer.isPlaying()) {
        this.wavesurfer.setCurrentTime(time);
      }

      this._updatePlayheadPosition();
    }
  }, {
    key: "_createPointerSVG",
    value: function _createPointerSVG() {
      var svgNS = 'http://www.w3.org/2000/svg';
      var el = document.createElementNS(svgNS, 'svg');
      var path = document.createElementNS(svgNS, 'path');
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
  }, {
    key: "_createPlayheadElement",
    value: function _createPlayheadElement() {
      var _this5 = this;

      var el = document.createElement('playhead');
      el.className = 'wavesurfer-playhead';
      this.style(el, {
        position: 'absolute',
        height: '100%',
        display: 'flex',
        'flex-direction': 'column'
      });

      var pointer = this._createPointerSVG();

      el.appendChild(pointer);
      pointer.addEventListener('click', function (e) {
        e.stopPropagation();

        _this5.wavesurfer.setCurrentTime(_this5.playheadTime);
      });
      var line = document.createElement('div');
      this.style(line, {
        'flex-grow': 1,
        'margin-left': this.markerWidth / 2 - 0.5 + 'px',
        background: 'black',
        width: '1px',
        opacity: 0.1
      });
      el.appendChild(line);
      this.element = el;
      this.wrapper.appendChild(el);
    }
  }, {
    key: "_updatePlayheadPosition",
    value: function _updatePlayheadPosition() {
      if (!this.element) {
        return;
      }

      var duration = this.wavesurfer.getDuration();
      var elementWidth = this.wavesurfer.drawer.width / this.wavesurfer.params.pixelRatio;
      var positionPct = this.playheadTime / duration;
      this.style(this.element, {
        left: elementWidth * positionPct - this.markerWidth / 2 + 'px'
      });
    }
  }], [{
    key: "create",
    value:
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
    function create(params) {
      return {
        name: 'playhead',
        deferInit: params && params.deferInit ? params.deferInit : false,
        params: params,
        instance: PlayheadPlugin
      };
    }
  }]);

  return PlayheadPlugin;
}();

exports["default"] = PlayheadPlugin;
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
/******/ 	var __webpack_exports__ = __webpack_require__("./src/plugin/playhead/index.js");
/******/ 	
/******/ 	return __webpack_exports__;
/******/ })()
;
});
//# sourceMappingURL=wavesurfer.playhead.js.map