/*!
 * videojs-wavesurfer
 * @version 3.8.0
 * @see https://github.com/collab-project/videojs-wavesurfer
 * @copyright 2014-2021 Collab
 * @license MIT
 */
(function webpackUniversalModuleDefinition(root, factory) {
	if(typeof exports === 'object' && typeof module === 'object')
		module.exports = factory(require("video.js"), require("wavesurfer.js"));
	else if(typeof define === 'function' && define.amd)
		define("VideojsWavesurfer", ["video.js", "wavesurfer.js"], factory);
	else if(typeof exports === 'object')
		exports["VideojsWavesurfer"] = factory(require("video.js"), require("wavesurfer.js"));
	else
		root["VideojsWavesurfer"] = factory(root["videojs"], root["WaveSurfer"]);
})(self, function(__WEBPACK_EXTERNAL_MODULE_video_js__, __WEBPACK_EXTERNAL_MODULE_wavesurfer_js__) {
return /******/ (() => { // webpackBootstrap
/******/ 	var __webpack_modules__ = ({

/***/ "./node_modules/add-zero/index.js":
/*!****************************************!*\
  !*** ./node_modules/add-zero/index.js ***!
  \****************************************/
/***/ (function(module, exports, __webpack_require__) {

var __WEBPACK_AMD_DEFINE_RESULT__;(function(exports) {

  'use strict';

  function addZero(value, digits) {
    digits = digits || 2;

    var isNegative = Number(value) < 0;
    var buffer = value.toString();
    var size = 0;

    // Strip minus sign if number is negative
    if(isNegative) {
      buffer = buffer.slice(1);
    }

    size = digits - buffer.length + 1;
    buffer = new Array(size).join('0').concat(buffer);

    // Adds back minus sign if needed
    return (isNegative ? '-' : '') + buffer;
  }

  if(true) {
    !(__WEBPACK_AMD_DEFINE_RESULT__ = (function() { return addZero; }).call(exports, __webpack_require__, exports, module),
		__WEBPACK_AMD_DEFINE_RESULT__ !== undefined && (module.exports = __WEBPACK_AMD_DEFINE_RESULT__));
  } else {}

})(this);


/***/ }),

/***/ "./src/js/defaults.js":
/*!****************************!*\
  !*** ./src/js/defaults.js ***!
  \****************************/
/***/ ((module, exports) => {

"use strict";


Object.defineProperty(exports, "__esModule", ({
  value: true
}));
exports.default = void 0;
var pluginDefaultOptions = {
  debug: false,
  displayMilliseconds: true
};
var _default = pluginDefaultOptions;
exports.default = _default;
module.exports = exports.default;

/***/ }),

/***/ "./src/js/event.js":
/*!*************************!*\
  !*** ./src/js/event.js ***!
  \*************************/
/***/ ((module, exports) => {

"use strict";


Object.defineProperty(exports, "__esModule", ({
  value: true
}));
exports.default = void 0;

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

var Event = function Event() {
  _classCallCheck(this, Event);
};

Event.READY = 'ready';
Event.ERROR = 'error';
Event.VOLUMECHANGE = 'volumechange';
Event.FULLSCREENCHANGE = 'fullscreenchange';
Event.TIMEUPDATE = 'timeupdate';
Event.ENDED = 'ended';
Event.PAUSE = 'pause';
Event.FINISH = 'finish';
Event.SEEK = 'seek';
Event.REDRAW = 'redraw';
Event.AUDIOPROCESS = 'audioprocess';
Event.DEVICE_READY = 'deviceReady';
Event.DEVICE_ERROR = 'deviceError';
Event.AUDIO_OUTPUT_READY = 'audioOutputReady';
Event.WAVE_READY = 'waveReady';
Event.PLAYBACK_FINISH = 'playbackFinish';
Event.ABORT = 'abort';
Event.RESIZE = 'resize';
Object.freeze(Event);
var _default = Event;
exports.default = _default;
module.exports = exports.default;

/***/ }),

/***/ "./src/js/middleware.js":
/*!******************************!*\
  !*** ./src/js/middleware.js ***!
  \******************************/
/***/ ((module, exports) => {

"use strict";


Object.defineProperty(exports, "__esModule", ({
  value: true
}));
exports.default = void 0;
var WavesurferMiddleware = {
  setSource: function setSource(srcObj, next) {
    if (this.player.usingPlugin('wavesurfer')) {
      var backend = this.player.wavesurfer().surfer.params.backend;
      var src = srcObj.src;
      var peaks = srcObj.peaks;

      switch (backend) {
        case 'WebAudio':
          this.player.wavesurfer().load(src);
          break;

        default:
          next(null, srcObj);
          var element = this.player.tech_.el();

          if (peaks === undefined) {
            this.player.wavesurfer().load(element);
          } else {
            this.player.wavesurfer().load(element, peaks);
          }

          break;
      }
    } else {
      next(null, srcObj);
    }
  }
};
var _default = WavesurferMiddleware;
exports.default = _default;
module.exports = exports.default;

/***/ }),

/***/ "./src/js/utils/format-time.js":
/*!*************************************!*\
  !*** ./src/js/utils/format-time.js ***!
  \*************************************/
/***/ ((module, exports, __webpack_require__) => {

"use strict";


Object.defineProperty(exports, "__esModule", ({
  value: true
}));
exports.default = void 0;

var _addZero = _interopRequireDefault(__webpack_require__(/*! add-zero */ "./node_modules/add-zero/index.js"));

var _parseMs = _interopRequireDefault(__webpack_require__(/*! parse-ms */ "./node_modules/parse-ms/index.js"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var formatTime = function formatTime(seconds, guide) {
  var displayMilliseconds = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : true;
  seconds = seconds < 0 ? 0 : seconds;

  if (isNaN(seconds) || seconds === Infinity) {
    seconds = 0;
  }

  var inputTime = (0, _parseMs.default)(seconds * 1000);
  var guideTime = inputTime;

  if (guide !== undefined) {
    guideTime = (0, _parseMs.default)(guide * 1000);
  }

  var hr = (0, _addZero.default)(inputTime.hours);
  var min = (0, _addZero.default)(inputTime.minutes);
  var sec = (0, _addZero.default)(inputTime.seconds);
  var ms = (0, _addZero.default)(inputTime.milliseconds, 3);

  if (inputTime.days > 0 || guideTime.days > 0) {
    var day = (0, _addZero.default)(inputTime.days);
    return "".concat(day, ":").concat(hr, ":").concat(min, ":").concat(sec);
  }

  if (inputTime.hours > 0 || guideTime.hours > 0) {
    return "".concat(hr, ":").concat(min, ":").concat(sec);
  }

  if (displayMilliseconds) {
    return "".concat(min, ":").concat(sec, ":").concat(ms);
  }

  return "".concat(min, ":").concat(sec);
};

var _default = formatTime;
exports.default = _default;
module.exports = exports.default;

/***/ }),

/***/ "./src/js/utils/log.js":
/*!*****************************!*\
  !*** ./src/js/utils/log.js ***!
  \*****************************/
/***/ ((module, exports, __webpack_require__) => {

"use strict";


Object.defineProperty(exports, "__esModule", ({
  value: true
}));
exports.default = void 0;

var _video = _interopRequireDefault(__webpack_require__(/*! video.js */ "video.js"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var ERROR = 'error';
var WARN = 'warn';

var log = function log(args, logType, debug) {
  if (debug === true) {
    if (logType === ERROR) {
      _video.default.log.error(args);
    } else if (logType === WARN) {
      _video.default.log.warn(args);
    } else {
      _video.default.log(args);
    }
  }
};

var _default = log;
exports.default = _default;
module.exports = exports.default;

/***/ }),

/***/ "./node_modules/global/window.js":
/*!***************************************!*\
  !*** ./node_modules/global/window.js ***!
  \***************************************/
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var win;

if (typeof window !== "undefined") {
    win = window;
} else if (typeof __webpack_require__.g !== "undefined") {
    win = __webpack_require__.g;
} else if (typeof self !== "undefined"){
    win = self;
} else {
    win = {};
}

module.exports = win;


/***/ }),

/***/ "./node_modules/parse-ms/index.js":
/*!****************************************!*\
  !*** ./node_modules/parse-ms/index.js ***!
  \****************************************/
/***/ ((__unused_webpack___webpack_module__, __webpack_exports__, __webpack_require__) => {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "default": () => (/* binding */ parseMilliseconds)
/* harmony export */ });
function parseMilliseconds(milliseconds) {
	if (typeof milliseconds !== 'number') {
		throw new TypeError('Expected a number');
	}

	const roundTowardsZero = milliseconds > 0 ? Math.floor : Math.ceil;

	return {
		days: roundTowardsZero(milliseconds / 86400000),
		hours: roundTowardsZero(milliseconds / 3600000) % 24,
		minutes: roundTowardsZero(milliseconds / 60000) % 60,
		seconds: roundTowardsZero(milliseconds / 1000) % 60,
		milliseconds: roundTowardsZero(milliseconds) % 1000,
		microseconds: roundTowardsZero(milliseconds * 1000) % 1000,
		nanoseconds: roundTowardsZero(milliseconds * 1e6) % 1000
	};
}


/***/ }),

/***/ "video.js":
/*!*************************************************************************************************!*\
  !*** external {"commonjs":"video.js","commonjs2":"video.js","amd":"video.js","root":"videojs"} ***!
  \*************************************************************************************************/
/***/ ((module) => {

"use strict";
module.exports = __WEBPACK_EXTERNAL_MODULE_video_js__;

/***/ }),

/***/ "wavesurfer.js":
/*!*******************************************************************************************************************!*\
  !*** external {"commonjs":"wavesurfer.js","commonjs2":"wavesurfer.js","amd":"wavesurfer.js","root":"WaveSurfer"} ***!
  \*******************************************************************************************************************/
/***/ ((module) => {

"use strict";
module.exports = __WEBPACK_EXTERNAL_MODULE_wavesurfer_js__;

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
/******/ 		__webpack_modules__[moduleId].call(module.exports, module, module.exports, __webpack_require__);
/******/ 	
/******/ 		// Return the exports of the module
/******/ 		return module.exports;
/******/ 	}
/******/ 	
/************************************************************************/
/******/ 	/* webpack/runtime/define property getters */
/******/ 	(() => {
/******/ 		// define getter functions for harmony exports
/******/ 		__webpack_require__.d = (exports, definition) => {
/******/ 			for(var key in definition) {
/******/ 				if(__webpack_require__.o(definition, key) && !__webpack_require__.o(exports, key)) {
/******/ 					Object.defineProperty(exports, key, { enumerable: true, get: definition[key] });
/******/ 				}
/******/ 			}
/******/ 		};
/******/ 	})();
/******/ 	
/******/ 	/* webpack/runtime/global */
/******/ 	(() => {
/******/ 		__webpack_require__.g = (function() {
/******/ 			if (typeof globalThis === 'object') return globalThis;
/******/ 			try {
/******/ 				return this || new Function('return this')();
/******/ 			} catch (e) {
/******/ 				if (typeof window === 'object') return window;
/******/ 			}
/******/ 		})();
/******/ 	})();
/******/ 	
/******/ 	/* webpack/runtime/hasOwnProperty shorthand */
/******/ 	(() => {
/******/ 		__webpack_require__.o = (obj, prop) => (Object.prototype.hasOwnProperty.call(obj, prop))
/******/ 	})();
/******/ 	
/******/ 	/* webpack/runtime/make namespace object */
/******/ 	(() => {
/******/ 		// define __esModule on exports
/******/ 		__webpack_require__.r = (exports) => {
/******/ 			if(typeof Symbol !== 'undefined' && Symbol.toStringTag) {
/******/ 				Object.defineProperty(exports, Symbol.toStringTag, { value: 'Module' });
/******/ 			}
/******/ 			Object.defineProperty(exports, '__esModule', { value: true });
/******/ 		};
/******/ 	})();
/******/ 	
/************************************************************************/
var __webpack_exports__ = {};
// This entry need to be wrapped in an IIFE because it need to be in strict mode.
(() => {
"use strict";
var exports = __webpack_exports__;
/*!**************************************!*\
  !*** ./src/js/videojs.wavesurfer.js ***!
  \**************************************/


function _typeof(obj) { "@babel/helpers - typeof"; if (typeof Symbol === "function" && typeof Symbol.iterator === "symbol") { _typeof = function _typeof(obj) { return typeof obj; }; } else { _typeof = function _typeof(obj) { return obj && typeof Symbol === "function" && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; }; } return _typeof(obj); }

Object.defineProperty(exports, "__esModule", ({
  value: true
}));
exports.Wavesurfer = void 0;

var _event = _interopRequireDefault(__webpack_require__(/*! ./event */ "./src/js/event.js"));

var _log2 = _interopRequireDefault(__webpack_require__(/*! ./utils/log */ "./src/js/utils/log.js"));

var _formatTime = _interopRequireDefault(__webpack_require__(/*! ./utils/format-time */ "./src/js/utils/format-time.js"));

var _defaults = _interopRequireDefault(__webpack_require__(/*! ./defaults */ "./src/js/defaults.js"));

var _middleware = _interopRequireDefault(__webpack_require__(/*! ./middleware */ "./src/js/middleware.js"));

var _window = _interopRequireDefault(__webpack_require__(/*! global/window */ "./node_modules/global/window.js"));

var _video = _interopRequireDefault(__webpack_require__(/*! video.js */ "video.js"));

var _wavesurfer = _interopRequireDefault(__webpack_require__(/*! wavesurfer.js */ "wavesurfer.js"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } }

function _createClass(Constructor, protoProps, staticProps) { if (protoProps) _defineProperties(Constructor.prototype, protoProps); if (staticProps) _defineProperties(Constructor, staticProps); return Constructor; }

function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function"); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, writable: true, configurable: true } }); if (superClass) _setPrototypeOf(subClass, superClass); }

function _setPrototypeOf(o, p) { _setPrototypeOf = Object.setPrototypeOf || function _setPrototypeOf(o, p) { o.__proto__ = p; return o; }; return _setPrototypeOf(o, p); }

function _createSuper(Derived) { var hasNativeReflectConstruct = _isNativeReflectConstruct(); return function _createSuperInternal() { var Super = _getPrototypeOf(Derived), result; if (hasNativeReflectConstruct) { var NewTarget = _getPrototypeOf(this).constructor; result = Reflect.construct(Super, arguments, NewTarget); } else { result = Super.apply(this, arguments); } return _possibleConstructorReturn(this, result); }; }

function _possibleConstructorReturn(self, call) { if (call && (_typeof(call) === "object" || typeof call === "function")) { return call; } return _assertThisInitialized(self); }

function _assertThisInitialized(self) { if (self === void 0) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return self; }

function _isNativeReflectConstruct() { if (typeof Reflect === "undefined" || !Reflect.construct) return false; if (Reflect.construct.sham) return false; if (typeof Proxy === "function") return true; try { Boolean.prototype.valueOf.call(Reflect.construct(Boolean, [], function () {})); return true; } catch (e) { return false; } }

function _getPrototypeOf(o) { _getPrototypeOf = Object.setPrototypeOf ? Object.getPrototypeOf : function _getPrototypeOf(o) { return o.__proto__ || Object.getPrototypeOf(o); }; return _getPrototypeOf(o); }

var Plugin = _video.default.getPlugin('plugin');

var wavesurferPluginName = 'wavesurfer';
var wavesurferClassName = 'vjs-wavedisplay';
var wavesurferStyleName = 'vjs-wavesurfer';
var WEBAUDIO = 'WebAudio';
var MEDIAELEMENT = 'MediaElement';
var MEDIAELEMENT_WEBAUDIO = 'MediaElementWebAudio';

var Wavesurfer = function (_Plugin) {
  _inherits(Wavesurfer, _Plugin);

  var _super = _createSuper(Wavesurfer);

  function Wavesurfer(player, options) {
    var _this;

    _classCallCheck(this, Wavesurfer);

    _this = _super.call(this, player, options);
    player.addClass(wavesurferStyleName);
    options = _video.default.mergeOptions(_defaults.default, options);
    _this.waveReady = false;
    _this.waveFinished = false;
    _this.liveMode = false;
    _this.backend = null;
    _this.debug = options.debug.toString() === 'true';
    _this.textTracksEnabled = _this.player.options_.tracks.length > 0;
    _this.displayMilliseconds = options.displayMilliseconds;

    if (options.formatTime && typeof options.formatTime === 'function') {
      _this.setFormatTime(options.formatTime);
    } else {
      _this.setFormatTime(function (seconds, guide) {
        return (0, _formatTime.default)(seconds, guide, _this.displayMilliseconds);
      });
    }

    _this.player.one(_event.default.READY, _this.initialize.bind(_assertThisInitialized(_this)));

    return _this;
  }

  _createClass(Wavesurfer, [{
    key: "initialize",
    value: function initialize() {
      var _this2 = this;

      if (this.player.bigPlayButton !== undefined) {
        this.player.bigPlayButton.hide();
      }

      var mergedOptions = this.parseOptions(this.player.options_.plugins.wavesurfer);

      if (this.player.options_.controls === true) {
        this.player.controlBar.show();
        this.player.controlBar.el_.style.display = 'flex';

        if (this.backend === WEBAUDIO && this.player.controlBar.progressControl !== undefined) {
          this.player.controlBar.progressControl.hide();
        }

        if (this.player.controlBar.pictureInPictureToggle !== undefined) {
          this.player.controlBar.pictureInPictureToggle.hide();
        }

        var uiElements = ['currentTimeDisplay', 'timeDivider', 'durationDisplay'];
        uiElements.forEach(function (element) {
          element = _this2.player.controlBar[element];

          if (element !== undefined) {
            element.el_.style.display = 'block';
            element.show();
          }
        });

        if (this.player.controlBar.remainingTimeDisplay !== undefined) {
          this.player.controlBar.remainingTimeDisplay.hide();
        }

        if (this.backend === WEBAUDIO && this.player.controlBar.playToggle !== undefined) {
          this.player.controlBar.playToggle.on(['tap', 'click'], this.onPlayToggle.bind(this));
          this.player.controlBar.playToggle.hide();
        }
      }

      this.surfer = _wavesurfer.default.create(mergedOptions);
      this.surfer.on(_event.default.ERROR, this.onWaveError.bind(this));
      this.surfer.on(_event.default.FINISH, this.onWaveFinish.bind(this));
      this.backend = this.surfer.params.backend;
      this.log('Using wavesurfer.js ' + this.backend + ' backend.');

      if ('microphone' in this.player.wavesurfer().surfer.getActivePlugins()) {
        this.liveMode = true;
        this.waveReady = true;
        this.log('wavesurfer.js microphone plugin enabled.');
        this.player.controlBar.playToggle.show();
        this.surfer.microphone.on(_event.default.DEVICE_ERROR, this.onWaveError.bind(this));
      }

      this.surferReady = this.onWaveReady.bind(this);

      if (this.backend === WEBAUDIO) {
        this.surferProgress = this.onWaveProgress.bind(this);
        this.surferSeek = this.onWaveSeek.bind(this);

        if (this.player.muted()) {
          this.setVolume(0);
        }
      }

      if (!this.liveMode) {
        this.setupPlaybackEvents(true);
      }

      this.player.on(_event.default.VOLUMECHANGE, this.onVolumeChange.bind(this));
      this.player.on(_event.default.FULLSCREENCHANGE, this.onScreenChange.bind(this));

      if (this.player.options_.fluid === true) {
        this.surfer.drawer.wrapper.className = wavesurferClassName;
      }
    }
  }, {
    key: "parseOptions",
    value: function parseOptions() {
      var surferOpts = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : {};
      var rect = this.player.el_.getBoundingClientRect();
      this.originalWidth = this.player.options_.width || rect.width;
      this.originalHeight = this.player.options_.height || rect.height;
      var controlBarHeight = this.player.controlBar.height();

      if (this.player.options_.controls === true && controlBarHeight === 0) {
        controlBarHeight = 30;
      }

      if (surferOpts.container === undefined) {
        surferOpts.container = this.player.el_;
      }

      if (surferOpts.waveformHeight === undefined) {
        var playerHeight = rect.height;
        surferOpts.height = playerHeight - controlBarHeight;
      } else {
        surferOpts.height = surferOpts.waveformHeight;
      }

      if (surferOpts.splitChannels && surferOpts.splitChannels === true) {
        surferOpts.height /= 2;
      }

      if ('backend' in surferOpts) {
        this.backend = surferOpts.backend;
      } else {
        surferOpts.backend = this.backend = MEDIAELEMENT;
      }

      return surferOpts;
    }
  }, {
    key: "setupPlaybackEvents",
    value: function setupPlaybackEvents(enable) {
      if (enable === false) {
        this.surfer.un(_event.default.READY, this.surferReady);

        if (this.backend === WEBAUDIO) {
          this.surfer.un(_event.default.AUDIOPROCESS, this.surferProgress);
          this.surfer.un(_event.default.SEEK, this.surferSeek);
        }
      } else if (enable === true) {
        this.surfer.on(_event.default.READY, this.surferReady);

        if (this.backend === WEBAUDIO) {
          this.surfer.on(_event.default.AUDIOPROCESS, this.surferProgress);
          this.surfer.on(_event.default.SEEK, this.surferSeek);
        }
      }
    }
  }, {
    key: "load",
    value: function load(url, peaks) {
      if (url instanceof Blob || url instanceof File) {
        this.log('Loading object: ' + JSON.stringify(url));
        this.surfer.loadBlob(url);
      } else {
        if (peaks !== undefined) {
          this.loadPeaks(url, peaks);
        } else {
          if (typeof url === 'string') {
            this.log('Loading URL: ' + url);
          } else {
            this.log('Loading element: ' + url);
          }

          this.surfer.load(url);
        }
      }
    }
  }, {
    key: "loadPeaks",
    value: function loadPeaks(url, peaks) {
      var _this3 = this;

      if (Array.isArray(peaks)) {
        this.log('Loading URL with array of peaks: ' + url);
        this.surfer.load(url, peaks);
      } else {
        var requestOptions = {
          url: peaks,
          responseType: 'json'
        };

        if (this.player.options_.plugins.wavesurfer.xhr !== undefined) {
          requestOptions.xhr = this.player.options_.plugins.wavesurfer.xhr;
        }

        var request = _wavesurfer.default.util.fetchFile(requestOptions);

        request.once('success', function (data) {
          _this3.log('Loaded Peak Data URL: ' + peaks);

          if (data && data.data) {
            _this3.surfer.load(url, data.data);
          } else {
            _this3.player.trigger(_event.default.ERROR, 'Could not load peaks data from ' + peaks);

            _this3.log(err, 'error');
          }
        });
        request.once('error', function (e) {
          _this3.player.trigger(_event.default.ERROR, 'Unable to retrieve peak data from ' + peaks + '. Status code: ' + request.response.status);
        });
      }
    }
  }, {
    key: "play",
    value: function play() {
      if (this.player.controlBar.playToggle !== undefined && this.player.controlBar.playToggle.contentEl()) {
        this.player.controlBar.playToggle.handlePlay();
      }

      if (this.liveMode) {
        if (!this.surfer.microphone.active) {
          this.log('Start microphone');
          this.surfer.microphone.start();
        } else {
          var paused = !this.surfer.microphone.paused;

          if (paused) {
            this.pause();
          } else {
            this.log('Resume microphone');
            this.surfer.microphone.play();
          }
        }
      } else {
        this.log('Start playback');
        this.player.play();
        this.surfer.play();
      }
    }
  }, {
    key: "pause",
    value: function pause() {
      if (this.player.controlBar.playToggle !== undefined && this.player.controlBar.playToggle.contentEl()) {
        this.player.controlBar.playToggle.handlePause();
      }

      if (this.liveMode) {
        this.log('Pause microphone');
        this.surfer.microphone.pause();
      } else {
        this.log('Pause playback');

        if (!this.waveFinished) {
          this.surfer.pause();
        } else {
          this.waveFinished = false;
        }

        this.setCurrentTime();
      }
    }
  }, {
    key: "dispose",
    value: function dispose() {
      if (this.surfer) {
        if (this.liveMode && this.surfer.microphone) {
          this.surfer.microphone.destroy();
          this.log('Destroyed microphone plugin');
        }

        this.surfer.destroy();
      }

      this.log('Destroyed plugin');
    }
  }, {
    key: "isDestroyed",
    value: function isDestroyed() {
      return this.player && this.player.children() === null;
    }
  }, {
    key: "destroy",
    value: function destroy() {
      this.player.dispose();
    }
  }, {
    key: "setVolume",
    value: function setVolume(volume) {
      if (volume !== undefined) {
        this.log('Changing volume to: ' + volume);
        this.player.volume(volume);
      }
    }
  }, {
    key: "exportImage",
    value: function exportImage(format, quality) {
      var type = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : 'blob';
      return this.surfer.exportImage(format, quality, type);
    }
  }, {
    key: "setAudioOutput",
    value: function setAudioOutput(deviceId) {
      var _this4 = this;

      if (deviceId) {
        this.surfer.setSinkId(deviceId).then(function (result) {
          _this4.player.trigger(_event.default.AUDIO_OUTPUT_READY);
        }).catch(function (err) {
          _this4.player.trigger(_event.default.ERROR, err);

          _this4.log(err, 'error');
        });
      }
    }
  }, {
    key: "getCurrentTime",
    value: function getCurrentTime() {
      var currentTime = this.surfer.getCurrentTime();
      currentTime = isNaN(currentTime) ? 0 : currentTime;
      return currentTime;
    }
  }, {
    key: "setCurrentTime",
    value: function setCurrentTime(currentTime, duration) {
      if (currentTime === undefined) {
        currentTime = this.surfer.getCurrentTime();
      }

      if (duration === undefined) {
        duration = this.surfer.getDuration();
      }

      currentTime = isNaN(currentTime) ? 0 : currentTime;
      duration = isNaN(duration) ? 0 : duration;

      if (this.player.controlBar.currentTimeDisplay && this.player.controlBar.currentTimeDisplay.contentEl() && this.player.controlBar.currentTimeDisplay.contentEl().lastChild) {
        var time = Math.min(currentTime, duration);
        this.player.controlBar.currentTimeDisplay.formattedTime_ = this.player.controlBar.currentTimeDisplay.contentEl().lastChild.textContent = this._formatTime(time, duration, this.displayMilliseconds);
      }

      if (this.textTracksEnabled && this.player.tech_ && this.player.tech_.el_) {
        this.player.tech_.setCurrentTime(currentTime);
      }
    }
  }, {
    key: "getDuration",
    value: function getDuration() {
      var duration = this.surfer.getDuration();
      duration = isNaN(duration) ? 0 : duration;
      return duration;
    }
  }, {
    key: "setDuration",
    value: function setDuration(duration) {
      if (duration === undefined) {
        duration = this.surfer.getDuration();
      }

      duration = isNaN(duration) ? 0 : duration;

      if (this.player.controlBar.durationDisplay && this.player.controlBar.durationDisplay.contentEl() && this.player.controlBar.durationDisplay.contentEl().lastChild) {
        this.player.controlBar.durationDisplay.formattedTime_ = this.player.controlBar.durationDisplay.contentEl().lastChild.textContent = this._formatTime(duration, duration, this.displayMilliseconds);
      }
    }
  }, {
    key: "onWaveReady",
    value: function onWaveReady() {
      var _this5 = this;

      this.waveReady = true;
      this.waveFinished = false;
      this.liveMode = false;
      this.log('Waveform is ready');
      this.player.trigger(_event.default.WAVE_READY);

      if (this.backend === WEBAUDIO) {
        this.setCurrentTime();
        this.setDuration();

        if (this.player.controlBar.playToggle !== undefined && this.player.controlBar.playToggle.contentEl()) {
          this.player.controlBar.playToggle.show();
        }
      }

      if (this.player.loadingSpinner.contentEl()) {
        this.player.loadingSpinner.hide();
      }

      if (this.player.options_.autoplay === true) {
        this.setVolume(0);

        if (this.backend === WEBAUDIO) {
          this.play();
        } else {
          this.player.play().catch(function (e) {
            _this5.onWaveError(e);
          });
        }
      }
    }
  }, {
    key: "onWaveFinish",
    value: function onWaveFinish() {
      var _this6 = this;

      this.log('Finished playback');
      this.player.trigger(_event.default.PLAYBACK_FINISH);

      if (this.player.options_.loop === true) {
        if (this.backend === WEBAUDIO) {
          this.surfer.stop();
          this.play();
        }
      } else {
        this.waveFinished = true;

        if (this.backend === WEBAUDIO) {
          this.pause();
          this.player.trigger(_event.default.ENDED);
          this.surfer.once(_event.default.SEEK, function () {
            if (_this6.player.controlBar.playToggle !== undefined) {
              _this6.player.controlBar.playToggle.removeClass('vjs-ended');
            }

            _this6.player.trigger(_event.default.PAUSE);
          });
        }
      }
    }
  }, {
    key: "onWaveProgress",
    value: function onWaveProgress(time) {
      this.setCurrentTime();
    }
  }, {
    key: "onWaveSeek",
    value: function onWaveSeek() {
      this.setCurrentTime();
    }
  }, {
    key: "onWaveError",
    value: function onWaveError(error) {
      if (error.name && error.name === 'AbortError' || error.name === 'DOMException' && error.message.startsWith('The operation was aborted')) {
        this.player.trigger(_event.default.ABORT, error);
      } else {
        this.player.trigger(_event.default.ERROR, error);
        this.log(error, 'error');
      }
    }
  }, {
    key: "onPlayToggle",
    value: function onPlayToggle() {
      if (this.player.controlBar.playToggle !== undefined && this.player.controlBar.playToggle.hasClass('vjs-ended')) {
        this.player.controlBar.playToggle.removeClass('vjs-ended');
      }

      if (this.surfer.isPlaying()) {
        this.pause();
      } else {
        this.play();
      }
    }
  }, {
    key: "onVolumeChange",
    value: function onVolumeChange() {
      var volume = this.player.volume();

      if (this.player.muted()) {
        volume = 0;
      }

      this.surfer.setVolume(volume);
    }
  }, {
    key: "onScreenChange",
    value: function onScreenChange() {
      var _this7 = this;

      var fullscreenDelay = this.player.setInterval(function () {
        var isFullscreen = _this7.player.isFullscreen();

        var newWidth, newHeight;

        if (!isFullscreen) {
          newWidth = _this7.originalWidth;
          newHeight = _this7.originalHeight;
        }

        if (_this7.waveReady) {
          if (_this7.liveMode && !_this7.surfer.microphone.active) {
            return;
          }

          _this7.redrawWaveform(newWidth, newHeight);
        }

        _this7.player.clearInterval(fullscreenDelay);
      }, 100);
    }
  }, {
    key: "redrawWaveform",
    value: function redrawWaveform(newWidth, newHeight) {
      if (!this.isDestroyed()) {
        if (this.player.el_) {
          var rect = this.player.el_.getBoundingClientRect();

          if (newWidth === undefined) {
            newWidth = rect.width;
          }

          if (newHeight === undefined) {
            newHeight = rect.height;
          }
        }

        this.surfer.drawer.destroy();
        this.surfer.params.width = newWidth;
        this.surfer.params.height = newHeight - this.player.controlBar.height();
        this.surfer.createDrawer();
        this.surfer.drawer.wrapper.className = wavesurferClassName;
        this.surfer.drawBuffer();
        this.surfer.drawer.progress(this.surfer.backend.getPlayedPercents());
      }
    }
  }, {
    key: "log",
    value: function log(args, logType) {
      (0, _log2.default)(args, logType, this.debug);
    }
  }, {
    key: "setFormatTime",
    value: function setFormatTime(customImplementation) {
      this._formatTime = customImplementation;

      _video.default.setFormatTime(this._formatTime);
    }
  }]);

  return Wavesurfer;
}(Plugin);

exports.Wavesurfer = Wavesurfer;
Wavesurfer.VERSION = "3.8.0";
_video.default.Wavesurfer = Wavesurfer;

if (_video.default.getPlugin(wavesurferPluginName) === undefined) {
  _video.default.registerPlugin(wavesurferPluginName, Wavesurfer);
}

_video.default.use('*', function (player) {
  _middleware.default.player = player;
  return _middleware.default;
});
})();

/******/ 	return __webpack_exports__;
/******/ })()
;
});