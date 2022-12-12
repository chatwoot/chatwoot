/*!
 * wavesurfer.js minimap plugin 6.1.0 (2022-03-31)
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
		root["WaveSurfer"] = root["WaveSurfer"] || {}, root["WaveSurfer"]["minimap"] = factory();
})(self, function() {
return /******/ (() => { // webpackBootstrap
/******/ 	"use strict";
/******/ 	var __webpack_modules__ = ({

/***/ "./src/plugin/minimap/index.js":
/*!*************************************!*\
  !*** ./src/plugin/minimap/index.js ***!
  \*************************************/
/***/ ((module, exports) => {



Object.defineProperty(exports, "__esModule", ({
  value: true
}));
exports["default"] = void 0;

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } }

function _createClass(Constructor, protoProps, staticProps) { if (protoProps) _defineProperties(Constructor.prototype, protoProps); if (staticProps) _defineProperties(Constructor, staticProps); Object.defineProperty(Constructor, "prototype", { writable: false }); return Constructor; }

/*eslint no-console: ["error", { allow: ["warn"] }] */

/**
 * @typedef {Object} MinimapPluginParams
 * @desc Extends the `WavesurferParams` wavesurfer was initialised with
 * @property {?string|HTMLElement} container CSS selector or HTML element where
 * the map should be rendered. By default it is simply appended
 * after the waveform.
 * @property {?boolean} deferInit Set to true to manually call
 * `initPlugin('minimap')`
 */

/**
 * Renders a smaller version waveform as a minimap of the main waveform.
 *
 * @implements {PluginClass}
 * @extends {Observer}
 * @example
 * // es6
 * import MinimapPlugin from 'wavesurfer.minimap.js';
 *
 * // commonjs
 * var MinimapPlugin = require('wavesurfer.minimap.js');
 *
 * // if you are using <script> tags
 * var MinimapPlugin = window.WaveSurfer.minimap;
 *
 * // ... initialising wavesurfer with the plugin
 * var wavesurfer = WaveSurfer.create({
 *   // wavesurfer options ...
 *   plugins: [
 *     MinimapPlugin.create({
 *       // plugin options ...
 *     })
 *   ]
 * });
 */
var MinimapPlugin = /*#__PURE__*/function () {
  function MinimapPlugin(params, ws) {
    var _this = this;

    _classCallCheck(this, MinimapPlugin);

    this.params = Object.assign({}, ws.params, {
      showRegions: false,
      regionsPluginName: params.regionsPluginName || 'regions',
      showOverview: false,
      overviewBorderColor: 'green',
      overviewBorderSize: 2,
      // the container should be different
      container: false,
      height: Math.max(Math.round(ws.params.height / 4), 20)
    }, params, {
      scrollParent: false,
      fillParent: true
    }); // if container is a selector, get the element

    if (typeof params.container === 'string') {
      var el = document.querySelector(params.container);

      if (!el) {
        console.warn("Wavesurfer minimap container ".concat(params.container, " was not found! The minimap will be automatically appended below the waveform."));
      }

      this.params.container = el;
    } // if no container is specified add a new element and insert it


    if (!params.container) {
      this.params.container = ws.util.style(document.createElement('minimap'), {
        display: 'block'
      });
    }

    this.drawer = new ws.Drawer(this.params.container, this.params);
    this.wavesurfer = ws;
    this.util = ws.util;
    this.cleared = false;
    this.renderEvent = 'redraw';
    this.overviewRegion = null;
    this.regionsPlugin = this.wavesurfer[this.params.regionsPluginName];
    this.drawer.createWrapper();
    this.createElements();
    var isInitialised = false; // ws ready event listener

    this._onShouldRender = function () {
      // only bind the events in the first run
      if (!isInitialised) {
        _this.bindWavesurferEvents();

        _this.bindMinimapEvents();

        isInitialised = true;
      } // if there is no such element, append it to the container (below
      // the waveform)


      if (!document.body.contains(_this.params.container)) {
        ws.container.insertBefore(_this.params.container, null);
      }

      if (_this.regionsPlugin && _this.params.showRegions) {
        _this.drawRegions();
      }

      _this.render();
    };

    this._onAudioprocess = function (currentTime) {
      _this.drawer.progress(_this.wavesurfer.backend.getPlayedPercents());
    }; // ws seek event listener


    this._onSeek = function () {
      return _this.drawer.progress(ws.backend.getPlayedPercents());
    }; // event listeners for the overview region


    this._onScroll = function (e) {
      if (!_this.draggingOverview) {
        var orientedTarget = _this.util.withOrientation(e.target, _this.wavesurfer.params.vertical);

        _this.moveOverviewRegion(orientedTarget.scrollLeft / _this.ratio);
      }
    };

    this._onMouseover = function (e) {
      if (_this.draggingOverview) {
        _this.draggingOverview = false;
      }
    };

    var prevWidth = 0;
    this._onResize = ws.util.debounce(function () {
      if (prevWidth != _this.drawer.wrapper.clientWidth) {
        prevWidth = _this.drawer.wrapper.clientWidth;

        _this.render();

        _this.drawer.progress(_this.wavesurfer.backend.getPlayedPercents());
      }
    });

    this._onLoading = function (percent) {
      if (percent >= 100) {
        _this.cleared = false;
        return;
      }

      if (_this.cleared === true) {
        return;
      }

      var len = _this.drawer.getWidth();

      _this.drawer.drawPeaks([0], len, 0, len);

      _this.cleared = true;
    };

    this._onZoom = function (e) {
      _this.render();
    };

    this.wavesurfer.on('zoom', this._onZoom);
  }

  _createClass(MinimapPlugin, [{
    key: "init",
    value: function init() {
      if (this.wavesurfer.isReady) {
        this._onShouldRender();
      }

      this.wavesurfer.on(this.renderEvent, this._onShouldRender);
    }
  }, {
    key: "destroy",
    value: function destroy() {
      window.removeEventListener('resize', this._onResize, true);
      window.removeEventListener('orientationchange', this._onResize, true);
      this.wavesurfer.drawer.wrapper.removeEventListener('mouseover', this._onMouseover);
      this.wavesurfer.un(this.renderEvent, this._onShouldRender);
      this.wavesurfer.un('seek', this._onSeek);
      this.wavesurfer.un('scroll', this._onScroll);
      this.wavesurfer.un('audioprocess', this._onAudioprocess);
      this.wavesurfer.un('zoom', this._onZoom);
      this.wavesurfer.un('loading', this._onLoading);
      this.drawer.destroy();
      this.overviewRegion = null;
      this.unAll();
    }
  }, {
    key: "drawRegions",
    value: function drawRegions() {
      var _this2 = this;

      this.regions = {};
      this.wavesurfer.on('region-created', function (region) {
        _this2.regions[region.id] = region;
        _this2.drawer.wrapper && _this2.renderRegions();
      });
      this.wavesurfer.on('region-updated', function (region) {
        _this2.regions[region.id] = region;
        _this2.drawer.wrapper && _this2.renderRegions();
      });
      this.wavesurfer.on('region-removed', function (region) {
        delete _this2.regions[region.id];
        _this2.drawer.wrapper && _this2.renderRegions();
      });
    }
  }, {
    key: "renderRegions",
    value: function renderRegions() {
      var _this3 = this;

      var regionElements = this.drawer.wrapper.querySelectorAll('region');
      var i;

      for (i = 0; i < regionElements.length; ++i) {
        this.drawer.wrapper.removeChild(regionElements[i]);
      }

      Object.keys(this.regions).forEach(function (id) {
        var region = _this3.regions[id];

        var width = _this3.getWidth() * ((region.end - region.start) / _this3.wavesurfer.getDuration());

        var left = _this3.getWidth() * (region.start / _this3.wavesurfer.getDuration());

        var regionElement = _this3.util.style(document.createElement('region'), {
          height: 'inherit',
          backgroundColor: region.color,
          width: width + 'px',
          left: left + 'px',
          display: 'block',
          position: 'absolute'
        });

        regionElement.classList.add(id);

        _this3.drawer.wrapper.appendChild(regionElement);
      });
    }
  }, {
    key: "createElements",
    value: function createElements() {
      this.drawer.createElements();

      if (this.params.showOverview) {
        this.overviewRegion = this.util.withOrientation(this.drawer.wrapper.appendChild(document.createElement('overview')), this.wavesurfer.params.vertical);
        this.util.style(this.overviewRegion, {
          top: 0,
          bottom: 0,
          width: '0px',
          display: 'block',
          position: 'absolute',
          cursor: 'move',
          border: this.params.overviewBorderSize + 'px solid ' + this.params.overviewBorderColor,
          zIndex: 2,
          opacity: this.params.overviewOpacity
        });
      }
    }
  }, {
    key: "bindWavesurferEvents",
    value: function bindWavesurferEvents() {
      window.addEventListener('resize', this._onResize, true);
      window.addEventListener('orientationchange', this._onResize, true);
      this.wavesurfer.on('audioprocess', this._onAudioprocess);
      this.wavesurfer.on('seek', this._onSeek);
      this.wavesurfer.on('loading', this._onLoading);

      if (this.params.showOverview) {
        this.wavesurfer.on('scroll', this._onScroll);
        this.wavesurfer.drawer.wrapper.addEventListener('mouseover', this._onMouseover);
      }
    }
  }, {
    key: "bindMinimapEvents",
    value: function bindMinimapEvents() {
      var _this4 = this;

      var positionMouseDown = {
        clientX: 0,
        clientY: 0
      };
      var relativePositionX = 0;
      var seek = true; // the following event listeners will be destroyed by using
      // this.unAll() and nullifying the DOM node references after
      // removing them

      if (this.params.interact) {
        this.drawer.wrapper.addEventListener('click', function (event) {
          _this4.fireEvent('click', event, _this4.drawer.handleEvent(event));
        });
        this.on('click', function (event, position) {
          if (seek) {
            _this4.drawer.progress(position);

            _this4.wavesurfer.seekAndCenter(position);
          } else {
            seek = true;
          }
        });
      }

      if (this.params.showOverview) {
        this.overviewRegion.domElement.addEventListener('mousedown', function (e) {
          var event = _this4.util.withOrientation(e, _this4.wavesurfer.params.vertical);

          _this4.draggingOverview = true;
          relativePositionX = event.layerX;
          positionMouseDown.clientX = event.clientX;
          positionMouseDown.clientY = event.clientY;
        });
        this.drawer.wrapper.addEventListener('mousemove', function (e) {
          if (_this4.draggingOverview) {
            var event = _this4.util.withOrientation(e, _this4.wavesurfer.params.vertical);

            _this4.moveOverviewRegion(event.clientX - _this4.drawer.container.getBoundingClientRect().left - relativePositionX);
          }
        });
        this.drawer.wrapper.addEventListener('mouseup', function (e) {
          var event = _this4.util.withOrientation(e, _this4.wavesurfer.params.vertical);

          if (positionMouseDown.clientX - event.clientX === 0 && positionMouseDown.clientX - event.clientX === 0) {
            seek = true;
            _this4.draggingOverview = false;
          } else if (_this4.draggingOverview) {
            seek = false;
            _this4.draggingOverview = false;
          }
        });
      }
    }
  }, {
    key: "render",
    value: function render() {
      var len = this.drawer.getWidth();
      var peaks = this.wavesurfer.backend.getPeaks(len, 0, len);
      this.drawer.drawPeaks(peaks, len, 0, len);
      this.drawer.progress(this.wavesurfer.backend.getPlayedPercents());

      if (this.params.showOverview) {
        //get proportional width of overview region considering the respective
        //width of the drawers
        this.ratio = this.wavesurfer.drawer.width / this.drawer.width;
        this.waveShowedWidth = this.wavesurfer.drawer.width / this.ratio;
        this.waveWidth = this.wavesurfer.drawer.width;
        this.overviewWidth = this.drawer.container.offsetWidth / this.ratio;
        this.overviewPosition = 0;
        this.moveOverviewRegion(this.wavesurfer.drawer.wrapper.scrollLeft / this.ratio);
        this.util.style(this.overviewRegion, {
          width: this.overviewWidth + 'px'
        });
      }
    }
  }, {
    key: "moveOverviewRegion",
    value: function moveOverviewRegion(pixels) {
      if (pixels < 0) {
        this.overviewPosition = 0;
      } else if (pixels + this.overviewWidth < this.drawer.container.offsetWidth) {
        this.overviewPosition = pixels;
      } else {
        this.overviewPosition = this.drawer.container.offsetWidth - this.overviewWidth;
      }

      this.util.style(this.overviewRegion, {
        left: this.overviewPosition + 'px'
      });

      if (this.draggingOverview) {
        this.wavesurfer.drawer.wrapper.scrollLeft = this.overviewPosition * this.ratio;
      }
    }
  }, {
    key: "getWidth",
    value: function getWidth() {
      return this.drawer.width / this.params.pixelRatio;
    }
  }], [{
    key: "create",
    value:
    /**
     * Minimap plugin definition factory
     *
     * This function must be used to create a plugin definition which can be
     * used by wavesurfer to correctly instantiate the plugin.
     *
     * @param  {MinimapPluginParams} params parameters use to initialise the plugin
     * @return {PluginDefinition} an object representing the plugin
     */
    function create(params) {
      return {
        name: 'minimap',
        deferInit: params && params.deferInit ? params.deferInit : false,
        params: params,
        staticProps: {},
        instance: MinimapPlugin
      };
    }
  }]);

  return MinimapPlugin;
}();

exports["default"] = MinimapPlugin;
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
/******/ 	var __webpack_exports__ = __webpack_require__("./src/plugin/minimap/index.js");
/******/ 	
/******/ 	return __webpack_exports__;
/******/ })()
;
});
//# sourceMappingURL=wavesurfer.minimap.js.map