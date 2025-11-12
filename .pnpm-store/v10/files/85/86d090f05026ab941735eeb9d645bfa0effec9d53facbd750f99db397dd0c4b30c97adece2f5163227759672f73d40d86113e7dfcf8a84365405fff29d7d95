/*!
 * videojs-record
 * @version 4.5.0
 * @see https://github.com/collab-project/videojs-record
 * @copyright 2014-2021 Collab
 * @license MIT
 */
(function webpackUniversalModuleDefinition(root, factory) {
	if(typeof exports === 'object' && typeof module === 'object')
		module.exports = factory(require("recordrtc"), require("video.js"));
	else if(typeof define === 'function' && define.amd)
		define("VideojsRecord", ["recordrtc", "video.js"], factory);
	else if(typeof exports === 'object')
		exports["VideojsRecord"] = factory(require("recordrtc"), require("video.js"));
	else
		root["VideojsRecord"] = factory(root["RecordRTC"], root["videojs"]);
})(self, function(__WEBPACK_EXTERNAL_MODULE_recordrtc__, __WEBPACK_EXTERNAL_MODULE_video_js__) {
return /******/ (() => { // webpackBootstrap
/******/ 	var __webpack_modules__ = ({

/***/ "./node_modules/@babel/runtime/helpers/assertThisInitialized.js":
/*!**********************************************************************!*\
  !*** ./node_modules/@babel/runtime/helpers/assertThisInitialized.js ***!
  \**********************************************************************/
/***/ ((module) => {

function _assertThisInitialized(self) {
  if (self === void 0) {
    throw new ReferenceError("this hasn't been initialised - super() hasn't been called");
  }

  return self;
}

module.exports = _assertThisInitialized;

/***/ }),

/***/ "./node_modules/@babel/runtime/helpers/asyncToGenerator.js":
/*!*****************************************************************!*\
  !*** ./node_modules/@babel/runtime/helpers/asyncToGenerator.js ***!
  \*****************************************************************/
/***/ ((module) => {

function asyncGeneratorStep(gen, resolve, reject, _next, _throw, key, arg) {
  try {
    var info = gen[key](arg);
    var value = info.value;
  } catch (error) {
    reject(error);
    return;
  }

  if (info.done) {
    resolve(value);
  } else {
    Promise.resolve(value).then(_next, _throw);
  }
}

function _asyncToGenerator(fn) {
  return function () {
    var self = this,
        args = arguments;
    return new Promise(function (resolve, reject) {
      var gen = fn.apply(self, args);

      function _next(value) {
        asyncGeneratorStep(gen, resolve, reject, _next, _throw, "next", value);
      }

      function _throw(err) {
        asyncGeneratorStep(gen, resolve, reject, _next, _throw, "throw", err);
      }

      _next(undefined);
    });
  };
}

module.exports = _asyncToGenerator;

/***/ }),

/***/ "./node_modules/@babel/runtime/helpers/classCallCheck.js":
/*!***************************************************************!*\
  !*** ./node_modules/@babel/runtime/helpers/classCallCheck.js ***!
  \***************************************************************/
/***/ ((module) => {

function _classCallCheck(instance, Constructor) {
  if (!(instance instanceof Constructor)) {
    throw new TypeError("Cannot call a class as a function");
  }
}

module.exports = _classCallCheck;

/***/ }),

/***/ "./node_modules/@babel/runtime/helpers/createClass.js":
/*!************************************************************!*\
  !*** ./node_modules/@babel/runtime/helpers/createClass.js ***!
  \************************************************************/
/***/ ((module) => {

function _defineProperties(target, props) {
  for (var i = 0; i < props.length; i++) {
    var descriptor = props[i];
    descriptor.enumerable = descriptor.enumerable || false;
    descriptor.configurable = true;
    if ("value" in descriptor) descriptor.writable = true;
    Object.defineProperty(target, descriptor.key, descriptor);
  }
}

function _createClass(Constructor, protoProps, staticProps) {
  if (protoProps) _defineProperties(Constructor.prototype, protoProps);
  if (staticProps) _defineProperties(Constructor, staticProps);
  return Constructor;
}

module.exports = _createClass;

/***/ }),

/***/ "./node_modules/@babel/runtime/helpers/get.js":
/*!****************************************************!*\
  !*** ./node_modules/@babel/runtime/helpers/get.js ***!
  \****************************************************/
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var superPropBase = __webpack_require__(/*! ./superPropBase */ "./node_modules/@babel/runtime/helpers/superPropBase.js");

function _get(target, property, receiver) {
  if (typeof Reflect !== "undefined" && Reflect.get) {
    module.exports = _get = Reflect.get;
  } else {
    module.exports = _get = function _get(target, property, receiver) {
      var base = superPropBase(target, property);
      if (!base) return;
      var desc = Object.getOwnPropertyDescriptor(base, property);

      if (desc.get) {
        return desc.get.call(receiver);
      }

      return desc.value;
    };
  }

  return _get(target, property, receiver || target);
}

module.exports = _get;

/***/ }),

/***/ "./node_modules/@babel/runtime/helpers/getPrototypeOf.js":
/*!***************************************************************!*\
  !*** ./node_modules/@babel/runtime/helpers/getPrototypeOf.js ***!
  \***************************************************************/
/***/ ((module) => {

function _getPrototypeOf(o) {
  module.exports = _getPrototypeOf = Object.setPrototypeOf ? Object.getPrototypeOf : function _getPrototypeOf(o) {
    return o.__proto__ || Object.getPrototypeOf(o);
  };
  return _getPrototypeOf(o);
}

module.exports = _getPrototypeOf;

/***/ }),

/***/ "./node_modules/@babel/runtime/helpers/inherits.js":
/*!*********************************************************!*\
  !*** ./node_modules/@babel/runtime/helpers/inherits.js ***!
  \*********************************************************/
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var setPrototypeOf = __webpack_require__(/*! ./setPrototypeOf */ "./node_modules/@babel/runtime/helpers/setPrototypeOf.js");

function _inherits(subClass, superClass) {
  if (typeof superClass !== "function" && superClass !== null) {
    throw new TypeError("Super expression must either be null or a function");
  }

  subClass.prototype = Object.create(superClass && superClass.prototype, {
    constructor: {
      value: subClass,
      writable: true,
      configurable: true
    }
  });
  if (superClass) setPrototypeOf(subClass, superClass);
}

module.exports = _inherits;

/***/ }),

/***/ "./node_modules/@babel/runtime/helpers/interopRequireDefault.js":
/*!**********************************************************************!*\
  !*** ./node_modules/@babel/runtime/helpers/interopRequireDefault.js ***!
  \**********************************************************************/
/***/ ((module) => {

function _interopRequireDefault(obj) {
  return obj && obj.__esModule ? obj : {
    "default": obj
  };
}

module.exports = _interopRequireDefault;

/***/ }),

/***/ "./node_modules/@babel/runtime/helpers/possibleConstructorReturn.js":
/*!**************************************************************************!*\
  !*** ./node_modules/@babel/runtime/helpers/possibleConstructorReturn.js ***!
  \**************************************************************************/
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var _typeof = __webpack_require__(/*! ../helpers/typeof */ "./node_modules/@babel/runtime/helpers/typeof.js");

var assertThisInitialized = __webpack_require__(/*! ./assertThisInitialized */ "./node_modules/@babel/runtime/helpers/assertThisInitialized.js");

function _possibleConstructorReturn(self, call) {
  if (call && (_typeof(call) === "object" || typeof call === "function")) {
    return call;
  }

  return assertThisInitialized(self);
}

module.exports = _possibleConstructorReturn;

/***/ }),

/***/ "./node_modules/@babel/runtime/helpers/setPrototypeOf.js":
/*!***************************************************************!*\
  !*** ./node_modules/@babel/runtime/helpers/setPrototypeOf.js ***!
  \***************************************************************/
/***/ ((module) => {

function _setPrototypeOf(o, p) {
  module.exports = _setPrototypeOf = Object.setPrototypeOf || function _setPrototypeOf(o, p) {
    o.__proto__ = p;
    return o;
  };

  return _setPrototypeOf(o, p);
}

module.exports = _setPrototypeOf;

/***/ }),

/***/ "./node_modules/@babel/runtime/helpers/superPropBase.js":
/*!**************************************************************!*\
  !*** ./node_modules/@babel/runtime/helpers/superPropBase.js ***!
  \**************************************************************/
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var getPrototypeOf = __webpack_require__(/*! ./getPrototypeOf */ "./node_modules/@babel/runtime/helpers/getPrototypeOf.js");

function _superPropBase(object, property) {
  while (!Object.prototype.hasOwnProperty.call(object, property)) {
    object = getPrototypeOf(object);
    if (object === null) break;
  }

  return object;
}

module.exports = _superPropBase;

/***/ }),

/***/ "./node_modules/@babel/runtime/helpers/typeof.js":
/*!*******************************************************!*\
  !*** ./node_modules/@babel/runtime/helpers/typeof.js ***!
  \*******************************************************/
/***/ ((module) => {

function _typeof(obj) {
  "@babel/helpers - typeof";

  if (typeof Symbol === "function" && typeof Symbol.iterator === "symbol") {
    module.exports = _typeof = function _typeof(obj) {
      return typeof obj;
    };
  } else {
    module.exports = _typeof = function _typeof(obj) {
      return obj && typeof Symbol === "function" && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj;
    };
  }

  return _typeof(obj);
}

module.exports = _typeof;

/***/ }),

/***/ "./node_modules/@babel/runtime/regenerator/index.js":
/*!**********************************************************!*\
  !*** ./node_modules/@babel/runtime/regenerator/index.js ***!
  \**********************************************************/
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

module.exports = __webpack_require__(/*! regenerator-runtime */ "./node_modules/regenerator-runtime/runtime.js");


/***/ }),

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

/***/ "./src/js/controls/animation-display.js":
/*!**********************************************!*\
  !*** ./src/js/controls/animation-display.js ***!
  \**********************************************/
/***/ ((module, exports, __webpack_require__) => {

"use strict";


var _interopRequireDefault = __webpack_require__(/*! @babel/runtime/helpers/interopRequireDefault */ "./node_modules/@babel/runtime/helpers/interopRequireDefault.js");

Object.defineProperty(exports, "__esModule", ({
  value: true
}));
exports.default = void 0;

var _classCallCheck2 = _interopRequireDefault(__webpack_require__(/*! @babel/runtime/helpers/classCallCheck */ "./node_modules/@babel/runtime/helpers/classCallCheck.js"));

var _createClass2 = _interopRequireDefault(__webpack_require__(/*! @babel/runtime/helpers/createClass */ "./node_modules/@babel/runtime/helpers/createClass.js"));

var _get2 = _interopRequireDefault(__webpack_require__(/*! @babel/runtime/helpers/get */ "./node_modules/@babel/runtime/helpers/get.js"));

var _inherits2 = _interopRequireDefault(__webpack_require__(/*! @babel/runtime/helpers/inherits */ "./node_modules/@babel/runtime/helpers/inherits.js"));

var _possibleConstructorReturn2 = _interopRequireDefault(__webpack_require__(/*! @babel/runtime/helpers/possibleConstructorReturn */ "./node_modules/@babel/runtime/helpers/possibleConstructorReturn.js"));

var _getPrototypeOf2 = _interopRequireDefault(__webpack_require__(/*! @babel/runtime/helpers/getPrototypeOf */ "./node_modules/@babel/runtime/helpers/getPrototypeOf.js"));

var _video = _interopRequireDefault(__webpack_require__(/*! video.js */ "video.js"));

function _createSuper(Derived) { var hasNativeReflectConstruct = _isNativeReflectConstruct(); return function _createSuperInternal() { var Super = (0, _getPrototypeOf2.default)(Derived), result; if (hasNativeReflectConstruct) { var NewTarget = (0, _getPrototypeOf2.default)(this).constructor; result = Reflect.construct(Super, arguments, NewTarget); } else { result = Super.apply(this, arguments); } return (0, _possibleConstructorReturn2.default)(this, result); }; }

function _isNativeReflectConstruct() { if (typeof Reflect === "undefined" || !Reflect.construct) return false; if (Reflect.construct.sham) return false; if (typeof Proxy === "function") return true; try { Boolean.prototype.valueOf.call(Reflect.construct(Boolean, [], function () {})); return true; } catch (e) { return false; } }

var Component = _video.default.getComponent('Component');

var AnimationDisplay = function (_Component) {
  (0, _inherits2.default)(AnimationDisplay, _Component);

  var _super = _createSuper(AnimationDisplay);

  function AnimationDisplay() {
    (0, _classCallCheck2.default)(this, AnimationDisplay);
    return _super.apply(this, arguments);
  }

  (0, _createClass2.default)(AnimationDisplay, [{
    key: "createEl",
    value: function createEl() {
      var imgElement = _video.default.dom.createEl('img');

      var el = (0, _get2.default)((0, _getPrototypeOf2.default)(AnimationDisplay.prototype), "createEl", this).call(this, 'div', {
        className: 'vjs-animation-display',
        dir: 'ltr'
      });
      el.appendChild(imgElement);
      return el;
    }
  }]);
  return AnimationDisplay;
}(Component);

Component.registerComponent('AnimationDisplay', AnimationDisplay);
var _default = AnimationDisplay;
exports.default = _default;
module.exports = exports.default;

/***/ }),

/***/ "./src/js/controls/camera-button.js":
/*!******************************************!*\
  !*** ./src/js/controls/camera-button.js ***!
  \******************************************/
/***/ ((module, exports, __webpack_require__) => {

"use strict";


var _interopRequireDefault = __webpack_require__(/*! @babel/runtime/helpers/interopRequireDefault */ "./node_modules/@babel/runtime/helpers/interopRequireDefault.js");

Object.defineProperty(exports, "__esModule", ({
  value: true
}));
exports.default = void 0;

var _classCallCheck2 = _interopRequireDefault(__webpack_require__(/*! @babel/runtime/helpers/classCallCheck */ "./node_modules/@babel/runtime/helpers/classCallCheck.js"));

var _createClass2 = _interopRequireDefault(__webpack_require__(/*! @babel/runtime/helpers/createClass */ "./node_modules/@babel/runtime/helpers/createClass.js"));

var _get2 = _interopRequireDefault(__webpack_require__(/*! @babel/runtime/helpers/get */ "./node_modules/@babel/runtime/helpers/get.js"));

var _inherits2 = _interopRequireDefault(__webpack_require__(/*! @babel/runtime/helpers/inherits */ "./node_modules/@babel/runtime/helpers/inherits.js"));

var _possibleConstructorReturn2 = _interopRequireDefault(__webpack_require__(/*! @babel/runtime/helpers/possibleConstructorReturn */ "./node_modules/@babel/runtime/helpers/possibleConstructorReturn.js"));

var _getPrototypeOf2 = _interopRequireDefault(__webpack_require__(/*! @babel/runtime/helpers/getPrototypeOf */ "./node_modules/@babel/runtime/helpers/getPrototypeOf.js"));

var _video = _interopRequireDefault(__webpack_require__(/*! video.js */ "video.js"));

var _event = _interopRequireDefault(__webpack_require__(/*! ../event */ "./src/js/event.js"));

function _createSuper(Derived) { var hasNativeReflectConstruct = _isNativeReflectConstruct(); return function _createSuperInternal() { var Super = (0, _getPrototypeOf2.default)(Derived), result; if (hasNativeReflectConstruct) { var NewTarget = (0, _getPrototypeOf2.default)(this).constructor; result = Reflect.construct(Super, arguments, NewTarget); } else { result = Super.apply(this, arguments); } return (0, _possibleConstructorReturn2.default)(this, result); }; }

function _isNativeReflectConstruct() { if (typeof Reflect === "undefined" || !Reflect.construct) return false; if (Reflect.construct.sham) return false; if (typeof Proxy === "function") return true; try { Boolean.prototype.valueOf.call(Reflect.construct(Boolean, [], function () {})); return true; } catch (e) { return false; } }

var Button = _video.default.getComponent('Button');

var Component = _video.default.getComponent('Component');

var CameraButton = function (_Button) {
  (0, _inherits2.default)(CameraButton, _Button);

  var _super = _createSuper(CameraButton);

  function CameraButton() {
    (0, _classCallCheck2.default)(this, CameraButton);
    return _super.apply(this, arguments);
  }

  (0, _createClass2.default)(CameraButton, [{
    key: "buildCSSClass",
    value: function buildCSSClass() {
      return 'vjs-camera-button vjs-control vjs-button vjs-icon-photo-camera';
    }
  }, {
    key: "enable",
    value: function enable() {
      (0, _get2.default)((0, _getPrototypeOf2.default)(CameraButton.prototype), "enable", this).call(this);
      this.on(this.player_, _event.default.START_RECORD, this.onStart);
      this.on(this.player_, _event.default.STOP_RECORD, this.onStop);
    }
  }, {
    key: "disable",
    value: function disable() {
      (0, _get2.default)((0, _getPrototypeOf2.default)(CameraButton.prototype), "disable", this).call(this);
      this.off(this.player_, _event.default.START_RECORD, this.onStart);
      this.off(this.player_, _event.default.STOP_RECORD, this.onStop);
    }
  }, {
    key: "show",
    value: function show() {
      if (this.layoutExclude && this.layoutExclude === true) {
        return;
      }

      (0, _get2.default)((0, _getPrototypeOf2.default)(CameraButton.prototype), "show", this).call(this);
    }
  }, {
    key: "handleClick",
    value: function handleClick(event) {
      var recorder = this.player_.record();

      if (!recorder.isProcessing()) {
        recorder.start();
      } else {
        recorder.retrySnapshot();
        this.onStop();
        this.player_.trigger(_event.default.RETRY);
      }
    }
  }, {
    key: "onStart",
    value: function onStart(event) {
      this.removeClass('vjs-icon-photo-camera');
      this.addClass('vjs-icon-replay');
      this.controlText('Retry');
    }
  }, {
    key: "onStop",
    value: function onStop(event) {
      this.removeClass('vjs-icon-replay');
      this.addClass('vjs-icon-photo-camera');
      this.controlText('Image');
    }
  }]);
  return CameraButton;
}(Button);

CameraButton.prototype.controlText_ = 'Image';
Component.registerComponent('CameraButton', CameraButton);
var _default = CameraButton;
exports.default = _default;
module.exports = exports.default;

/***/ }),

/***/ "./src/js/controls/device-button.js":
/*!******************************************!*\
  !*** ./src/js/controls/device-button.js ***!
  \******************************************/
/***/ ((module, exports, __webpack_require__) => {

"use strict";


var _interopRequireDefault = __webpack_require__(/*! @babel/runtime/helpers/interopRequireDefault */ "./node_modules/@babel/runtime/helpers/interopRequireDefault.js");

Object.defineProperty(exports, "__esModule", ({
  value: true
}));
exports.default = void 0;

var _classCallCheck2 = _interopRequireDefault(__webpack_require__(/*! @babel/runtime/helpers/classCallCheck */ "./node_modules/@babel/runtime/helpers/classCallCheck.js"));

var _createClass2 = _interopRequireDefault(__webpack_require__(/*! @babel/runtime/helpers/createClass */ "./node_modules/@babel/runtime/helpers/createClass.js"));

var _get2 = _interopRequireDefault(__webpack_require__(/*! @babel/runtime/helpers/get */ "./node_modules/@babel/runtime/helpers/get.js"));

var _inherits2 = _interopRequireDefault(__webpack_require__(/*! @babel/runtime/helpers/inherits */ "./node_modules/@babel/runtime/helpers/inherits.js"));

var _possibleConstructorReturn2 = _interopRequireDefault(__webpack_require__(/*! @babel/runtime/helpers/possibleConstructorReturn */ "./node_modules/@babel/runtime/helpers/possibleConstructorReturn.js"));

var _getPrototypeOf2 = _interopRequireDefault(__webpack_require__(/*! @babel/runtime/helpers/getPrototypeOf */ "./node_modules/@babel/runtime/helpers/getPrototypeOf.js"));

var _video = _interopRequireDefault(__webpack_require__(/*! video.js */ "video.js"));

function _createSuper(Derived) { var hasNativeReflectConstruct = _isNativeReflectConstruct(); return function _createSuperInternal() { var Super = (0, _getPrototypeOf2.default)(Derived), result; if (hasNativeReflectConstruct) { var NewTarget = (0, _getPrototypeOf2.default)(this).constructor; result = Reflect.construct(Super, arguments, NewTarget); } else { result = Super.apply(this, arguments); } return (0, _possibleConstructorReturn2.default)(this, result); }; }

function _isNativeReflectConstruct() { if (typeof Reflect === "undefined" || !Reflect.construct) return false; if (Reflect.construct.sham) return false; if (typeof Proxy === "function") return true; try { Boolean.prototype.valueOf.call(Reflect.construct(Boolean, [], function () {})); return true; } catch (e) { return false; } }

var Button = _video.default.getComponent('Button');

var Component = _video.default.getComponent('Component');

var DeviceButton = function (_Button) {
  (0, _inherits2.default)(DeviceButton, _Button);

  var _super = _createSuper(DeviceButton);

  function DeviceButton() {
    (0, _classCallCheck2.default)(this, DeviceButton);
    return _super.apply(this, arguments);
  }

  (0, _createClass2.default)(DeviceButton, [{
    key: "handleClick",
    value: function handleClick(event) {
      this.player_.record().getDevice();
    }
  }, {
    key: "show",
    value: function show() {
      if (this.layoutExclude && this.layoutExclude === true) {
        return;
      }

      (0, _get2.default)((0, _getPrototypeOf2.default)(DeviceButton.prototype), "show", this).call(this);
    }
  }]);
  return DeviceButton;
}(Button);

DeviceButton.prototype.controlText_ = 'Device';
Component.registerComponent('DeviceButton', DeviceButton);
var _default = DeviceButton;
exports.default = _default;
module.exports = exports.default;

/***/ }),

/***/ "./src/js/controls/picture-in-picture-toggle.js":
/*!******************************************************!*\
  !*** ./src/js/controls/picture-in-picture-toggle.js ***!
  \******************************************************/
/***/ ((module, exports, __webpack_require__) => {

"use strict";


var _interopRequireDefault = __webpack_require__(/*! @babel/runtime/helpers/interopRequireDefault */ "./node_modules/@babel/runtime/helpers/interopRequireDefault.js");

Object.defineProperty(exports, "__esModule", ({
  value: true
}));
exports.default = void 0;

var _regenerator = _interopRequireDefault(__webpack_require__(/*! @babel/runtime/regenerator */ "./node_modules/@babel/runtime/regenerator/index.js"));

var _asyncToGenerator2 = _interopRequireDefault(__webpack_require__(/*! @babel/runtime/helpers/asyncToGenerator */ "./node_modules/@babel/runtime/helpers/asyncToGenerator.js"));

var _classCallCheck2 = _interopRequireDefault(__webpack_require__(/*! @babel/runtime/helpers/classCallCheck */ "./node_modules/@babel/runtime/helpers/classCallCheck.js"));

var _createClass2 = _interopRequireDefault(__webpack_require__(/*! @babel/runtime/helpers/createClass */ "./node_modules/@babel/runtime/helpers/createClass.js"));

var _get2 = _interopRequireDefault(__webpack_require__(/*! @babel/runtime/helpers/get */ "./node_modules/@babel/runtime/helpers/get.js"));

var _inherits2 = _interopRequireDefault(__webpack_require__(/*! @babel/runtime/helpers/inherits */ "./node_modules/@babel/runtime/helpers/inherits.js"));

var _possibleConstructorReturn2 = _interopRequireDefault(__webpack_require__(/*! @babel/runtime/helpers/possibleConstructorReturn */ "./node_modules/@babel/runtime/helpers/possibleConstructorReturn.js"));

var _getPrototypeOf2 = _interopRequireDefault(__webpack_require__(/*! @babel/runtime/helpers/getPrototypeOf */ "./node_modules/@babel/runtime/helpers/getPrototypeOf.js"));

var _video = _interopRequireDefault(__webpack_require__(/*! video.js */ "video.js"));

var _event = _interopRequireDefault(__webpack_require__(/*! ../event */ "./src/js/event.js"));

function _createSuper(Derived) { var hasNativeReflectConstruct = _isNativeReflectConstruct(); return function _createSuperInternal() { var Super = (0, _getPrototypeOf2.default)(Derived), result; if (hasNativeReflectConstruct) { var NewTarget = (0, _getPrototypeOf2.default)(this).constructor; result = Reflect.construct(Super, arguments, NewTarget); } else { result = Super.apply(this, arguments); } return (0, _possibleConstructorReturn2.default)(this, result); }; }

function _isNativeReflectConstruct() { if (typeof Reflect === "undefined" || !Reflect.construct) return false; if (Reflect.construct.sham) return false; if (typeof Proxy === "function") return true; try { Boolean.prototype.valueOf.call(Reflect.construct(Boolean, [], function () {})); return true; } catch (e) { return false; } }

var Button = _video.default.getComponent('Button');

var Component = _video.default.getComponent('Component');

var PictureInPictureToggle = function (_Button) {
  (0, _inherits2.default)(PictureInPictureToggle, _Button);

  var _super = _createSuper(PictureInPictureToggle);

  function PictureInPictureToggle(player, options) {
    var _this;

    (0, _classCallCheck2.default)(this, PictureInPictureToggle);
    _this = _super.call(this, player, options);

    _this.on(_this.player_, _event.default.ENTER_PIP, _this.onStart);

    _this.on(_this.player_, _event.default.LEAVE_PIP, _this.onStop);

    return _this;
  }

  (0, _createClass2.default)(PictureInPictureToggle, [{
    key: "buildCSSClass",
    value: function buildCSSClass() {
      return 'vjs-pip-button vjs-control vjs-button vjs-icon-picture-in-picture-start';
    }
  }, {
    key: "show",
    value: function show() {
      if (this.layoutExclude && this.layoutExclude === true) {
        return;
      }

      (0, _get2.default)((0, _getPrototypeOf2.default)(PictureInPictureToggle.prototype), "show", this).call(this);
    }
  }, {
    key: "handleClick",
    value: function () {
      var _handleClick = (0, _asyncToGenerator2.default)(_regenerator.default.mark(function _callee(event) {
        var recorder;
        return _regenerator.default.wrap(function _callee$(_context) {
          while (1) {
            switch (_context.prev = _context.next) {
              case 0:
                recorder = this.player_.record();
                this.disable();
                _context.prev = 2;

                if (!(recorder.mediaElement !== document.pictureInPictureElement)) {
                  _context.next = 8;
                  break;
                }

                _context.next = 6;
                return recorder.mediaElement.requestPictureInPicture();

              case 6:
                _context.next = 10;
                break;

              case 8:
                _context.next = 10;
                return document.exitPictureInPicture();

              case 10:
                _context.next = 15;
                break;

              case 12:
                _context.prev = 12;
                _context.t0 = _context["catch"](2);
                this.player_.trigger(_event.default.ERROR, _context.t0);

              case 15:
                _context.prev = 15;
                this.enable();
                return _context.finish(15);

              case 18:
              case "end":
                return _context.stop();
            }
          }
        }, _callee, this, [[2, 12, 15, 18]]);
      }));

      function handleClick(_x) {
        return _handleClick.apply(this, arguments);
      }

      return handleClick;
    }()
  }, {
    key: "onStart",
    value: function onStart(event) {
      this.removeClass('vjs-icon-picture-in-picture-start');
      this.addClass('vjs-icon-picture-in-picture-stop');
    }
  }, {
    key: "onStop",
    value: function onStop(event) {
      this.removeClass('vjs-icon-picture-in-picture-stop');
      this.addClass('vjs-icon-picture-in-picture-start');
    }
  }]);
  return PictureInPictureToggle;
}(Button);

PictureInPictureToggle.prototype.controlText_ = 'Picture in Picture';
Component.registerComponent('PictureInPictureToggle', PictureInPictureToggle);
var _default = PictureInPictureToggle;
exports.default = _default;
module.exports = exports.default;

/***/ }),

/***/ "./src/js/controls/record-canvas.js":
/*!******************************************!*\
  !*** ./src/js/controls/record-canvas.js ***!
  \******************************************/
/***/ ((module, exports, __webpack_require__) => {

"use strict";


var _interopRequireDefault = __webpack_require__(/*! @babel/runtime/helpers/interopRequireDefault */ "./node_modules/@babel/runtime/helpers/interopRequireDefault.js");

Object.defineProperty(exports, "__esModule", ({
  value: true
}));
exports.default = void 0;

var _classCallCheck2 = _interopRequireDefault(__webpack_require__(/*! @babel/runtime/helpers/classCallCheck */ "./node_modules/@babel/runtime/helpers/classCallCheck.js"));

var _createClass2 = _interopRequireDefault(__webpack_require__(/*! @babel/runtime/helpers/createClass */ "./node_modules/@babel/runtime/helpers/createClass.js"));

var _get2 = _interopRequireDefault(__webpack_require__(/*! @babel/runtime/helpers/get */ "./node_modules/@babel/runtime/helpers/get.js"));

var _inherits2 = _interopRequireDefault(__webpack_require__(/*! @babel/runtime/helpers/inherits */ "./node_modules/@babel/runtime/helpers/inherits.js"));

var _possibleConstructorReturn2 = _interopRequireDefault(__webpack_require__(/*! @babel/runtime/helpers/possibleConstructorReturn */ "./node_modules/@babel/runtime/helpers/possibleConstructorReturn.js"));

var _getPrototypeOf2 = _interopRequireDefault(__webpack_require__(/*! @babel/runtime/helpers/getPrototypeOf */ "./node_modules/@babel/runtime/helpers/getPrototypeOf.js"));

var _video = _interopRequireDefault(__webpack_require__(/*! video.js */ "video.js"));

function _createSuper(Derived) { var hasNativeReflectConstruct = _isNativeReflectConstruct(); return function _createSuperInternal() { var Super = (0, _getPrototypeOf2.default)(Derived), result; if (hasNativeReflectConstruct) { var NewTarget = (0, _getPrototypeOf2.default)(this).constructor; result = Reflect.construct(Super, arguments, NewTarget); } else { result = Super.apply(this, arguments); } return (0, _possibleConstructorReturn2.default)(this, result); }; }

function _isNativeReflectConstruct() { if (typeof Reflect === "undefined" || !Reflect.construct) return false; if (Reflect.construct.sham) return false; if (typeof Proxy === "function") return true; try { Boolean.prototype.valueOf.call(Reflect.construct(Boolean, [], function () {})); return true; } catch (e) { return false; } }

var Component = _video.default.getComponent('Component');

var RecordCanvas = function (_Component) {
  (0, _inherits2.default)(RecordCanvas, _Component);

  var _super = _createSuper(RecordCanvas);

  function RecordCanvas() {
    (0, _classCallCheck2.default)(this, RecordCanvas);
    return _super.apply(this, arguments);
  }

  (0, _createClass2.default)(RecordCanvas, [{
    key: "createEl",
    value: function createEl() {
      var canvasElement = _video.default.dom.createEl('canvas');

      var el = (0, _get2.default)((0, _getPrototypeOf2.default)(RecordCanvas.prototype), "createEl", this).call(this, 'div', {
        className: 'vjs-record-canvas',
        dir: 'ltr'
      });
      el.appendChild(canvasElement);
      return el;
    }
  }]);
  return RecordCanvas;
}(Component);

Component.registerComponent('RecordCanvas', RecordCanvas);
var _default = RecordCanvas;
exports.default = _default;
module.exports = exports.default;

/***/ }),

/***/ "./src/js/controls/record-indicator.js":
/*!*********************************************!*\
  !*** ./src/js/controls/record-indicator.js ***!
  \*********************************************/
/***/ ((module, exports, __webpack_require__) => {

"use strict";


var _interopRequireDefault = __webpack_require__(/*! @babel/runtime/helpers/interopRequireDefault */ "./node_modules/@babel/runtime/helpers/interopRequireDefault.js");

Object.defineProperty(exports, "__esModule", ({
  value: true
}));
exports.default = void 0;

var _classCallCheck2 = _interopRequireDefault(__webpack_require__(/*! @babel/runtime/helpers/classCallCheck */ "./node_modules/@babel/runtime/helpers/classCallCheck.js"));

var _createClass2 = _interopRequireDefault(__webpack_require__(/*! @babel/runtime/helpers/createClass */ "./node_modules/@babel/runtime/helpers/createClass.js"));

var _get2 = _interopRequireDefault(__webpack_require__(/*! @babel/runtime/helpers/get */ "./node_modules/@babel/runtime/helpers/get.js"));

var _inherits2 = _interopRequireDefault(__webpack_require__(/*! @babel/runtime/helpers/inherits */ "./node_modules/@babel/runtime/helpers/inherits.js"));

var _possibleConstructorReturn2 = _interopRequireDefault(__webpack_require__(/*! @babel/runtime/helpers/possibleConstructorReturn */ "./node_modules/@babel/runtime/helpers/possibleConstructorReturn.js"));

var _getPrototypeOf2 = _interopRequireDefault(__webpack_require__(/*! @babel/runtime/helpers/getPrototypeOf */ "./node_modules/@babel/runtime/helpers/getPrototypeOf.js"));

var _video = _interopRequireDefault(__webpack_require__(/*! video.js */ "video.js"));

var _event = _interopRequireDefault(__webpack_require__(/*! ../event */ "./src/js/event.js"));

function _createSuper(Derived) { var hasNativeReflectConstruct = _isNativeReflectConstruct(); return function _createSuperInternal() { var Super = (0, _getPrototypeOf2.default)(Derived), result; if (hasNativeReflectConstruct) { var NewTarget = (0, _getPrototypeOf2.default)(this).constructor; result = Reflect.construct(Super, arguments, NewTarget); } else { result = Super.apply(this, arguments); } return (0, _possibleConstructorReturn2.default)(this, result); }; }

function _isNativeReflectConstruct() { if (typeof Reflect === "undefined" || !Reflect.construct) return false; if (Reflect.construct.sham) return false; if (typeof Proxy === "function") return true; try { Boolean.prototype.valueOf.call(Reflect.construct(Boolean, [], function () {})); return true; } catch (e) { return false; } }

var Component = _video.default.getComponent('Component');

var RecordIndicator = function (_Component) {
  (0, _inherits2.default)(RecordIndicator, _Component);

  var _super = _createSuper(RecordIndicator);

  function RecordIndicator(player, options) {
    var _this;

    (0, _classCallCheck2.default)(this, RecordIndicator);
    _this = _super.call(this, player, options);

    _this.enable();

    return _this;
  }

  (0, _createClass2.default)(RecordIndicator, [{
    key: "createEl",
    value: function createEl() {
      var props = {
        className: 'vjs-record-indicator vjs-control',
        dir: 'ltr'
      };
      var attr = {
        'data-label': this.localize('REC')
      };
      return (0, _get2.default)((0, _getPrototypeOf2.default)(RecordIndicator.prototype), "createEl", this).call(this, 'div', props, attr);
    }
  }, {
    key: "enable",
    value: function enable() {
      this.on(this.player_, _event.default.START_RECORD, this.show);
      this.on(this.player_, _event.default.STOP_RECORD, this.hide);
    }
  }, {
    key: "disable",
    value: function disable() {
      this.off(this.player_, _event.default.START_RECORD, this.show);
      this.off(this.player_, _event.default.STOP_RECORD, this.hide);
    }
  }, {
    key: "show",
    value: function show() {
      if (this.layoutExclude && this.layoutExclude === true) {
        return;
      }

      (0, _get2.default)((0, _getPrototypeOf2.default)(RecordIndicator.prototype), "show", this).call(this);
    }
  }]);
  return RecordIndicator;
}(Component);

Component.registerComponent('RecordIndicator', RecordIndicator);
var _default = RecordIndicator;
exports.default = _default;
module.exports = exports.default;

/***/ }),

/***/ "./src/js/controls/record-toggle.js":
/*!******************************************!*\
  !*** ./src/js/controls/record-toggle.js ***!
  \******************************************/
/***/ ((module, exports, __webpack_require__) => {

"use strict";


var _interopRequireDefault = __webpack_require__(/*! @babel/runtime/helpers/interopRequireDefault */ "./node_modules/@babel/runtime/helpers/interopRequireDefault.js");

Object.defineProperty(exports, "__esModule", ({
  value: true
}));
exports.default = void 0;

var _classCallCheck2 = _interopRequireDefault(__webpack_require__(/*! @babel/runtime/helpers/classCallCheck */ "./node_modules/@babel/runtime/helpers/classCallCheck.js"));

var _createClass2 = _interopRequireDefault(__webpack_require__(/*! @babel/runtime/helpers/createClass */ "./node_modules/@babel/runtime/helpers/createClass.js"));

var _get2 = _interopRequireDefault(__webpack_require__(/*! @babel/runtime/helpers/get */ "./node_modules/@babel/runtime/helpers/get.js"));

var _inherits2 = _interopRequireDefault(__webpack_require__(/*! @babel/runtime/helpers/inherits */ "./node_modules/@babel/runtime/helpers/inherits.js"));

var _possibleConstructorReturn2 = _interopRequireDefault(__webpack_require__(/*! @babel/runtime/helpers/possibleConstructorReturn */ "./node_modules/@babel/runtime/helpers/possibleConstructorReturn.js"));

var _getPrototypeOf2 = _interopRequireDefault(__webpack_require__(/*! @babel/runtime/helpers/getPrototypeOf */ "./node_modules/@babel/runtime/helpers/getPrototypeOf.js"));

var _video = _interopRequireDefault(__webpack_require__(/*! video.js */ "video.js"));

var _event = _interopRequireDefault(__webpack_require__(/*! ../event */ "./src/js/event.js"));

function _createSuper(Derived) { var hasNativeReflectConstruct = _isNativeReflectConstruct(); return function _createSuperInternal() { var Super = (0, _getPrototypeOf2.default)(Derived), result; if (hasNativeReflectConstruct) { var NewTarget = (0, _getPrototypeOf2.default)(this).constructor; result = Reflect.construct(Super, arguments, NewTarget); } else { result = Super.apply(this, arguments); } return (0, _possibleConstructorReturn2.default)(this, result); }; }

function _isNativeReflectConstruct() { if (typeof Reflect === "undefined" || !Reflect.construct) return false; if (Reflect.construct.sham) return false; if (typeof Proxy === "function") return true; try { Boolean.prototype.valueOf.call(Reflect.construct(Boolean, [], function () {})); return true; } catch (e) { return false; } }

var Button = _video.default.getComponent('Button');

var Component = _video.default.getComponent('Component');

var RecordToggle = function (_Button) {
  (0, _inherits2.default)(RecordToggle, _Button);

  var _super = _createSuper(RecordToggle);

  function RecordToggle() {
    (0, _classCallCheck2.default)(this, RecordToggle);
    return _super.apply(this, arguments);
  }

  (0, _createClass2.default)(RecordToggle, [{
    key: "buildCSSClass",
    value: function buildCSSClass() {
      return 'vjs-record-button vjs-control vjs-button vjs-icon-record-start';
    }
  }, {
    key: "enable",
    value: function enable() {
      (0, _get2.default)((0, _getPrototypeOf2.default)(RecordToggle.prototype), "enable", this).call(this);
      this.on(this.player_, _event.default.START_RECORD, this.onStart);
      this.on(this.player_, _event.default.STOP_RECORD, this.onStop);
    }
  }, {
    key: "disable",
    value: function disable() {
      (0, _get2.default)((0, _getPrototypeOf2.default)(RecordToggle.prototype), "disable", this).call(this);
      this.off(this.player_, _event.default.START_RECORD, this.onStart);
      this.off(this.player_, _event.default.STOP_RECORD, this.onStop);
    }
  }, {
    key: "show",
    value: function show() {
      if (this.layoutExclude && this.layoutExclude === true) {
        return;
      }

      (0, _get2.default)((0, _getPrototypeOf2.default)(RecordToggle.prototype), "show", this).call(this);
    }
  }, {
    key: "handleClick",
    value: function handleClick(event) {
      var recorder = this.player_.record();

      if (!recorder.isRecording()) {
        recorder.start();
      } else {
        recorder.stop();
      }
    }
  }, {
    key: "onStart",
    value: function onStart(event) {
      this.removeClass('vjs-icon-record-start');
      this.addClass('vjs-icon-record-stop');
      this.controlText('Stop');
    }
  }, {
    key: "onStop",
    value: function onStop(event) {
      this.removeClass('vjs-icon-record-stop');
      this.addClass('vjs-icon-record-start');
      this.controlText('Record');
    }
  }]);
  return RecordToggle;
}(Button);

RecordToggle.prototype.controlText_ = 'Record';
Component.registerComponent('RecordToggle', RecordToggle);
var _default = RecordToggle;
exports.default = _default;
module.exports = exports.default;

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
  image: false,
  audio: false,
  video: false,
  animation: false,
  screen: false,
  maxLength: 10,
  maxFileSize: 0,
  displayMilliseconds: false,
  formatTime: undefined,
  frameWidth: 320,
  frameHeight: 240,
  debug: false,
  pip: false,
  autoMuteDevice: false,
  videoBitRate: 1200,
  videoEngine: 'recordrtc',
  videoFrameRate: 30,
  videoMimeType: 'video/webm',
  videoRecorderType: 'auto',
  videoWorkerURL: '',
  videoWebAssemblyURL: '',
  audioEngine: 'recordrtc',
  audioRecorderType: 'auto',
  audioMimeType: 'auto',
  audioBufferSize: 4096,
  audioSampleRate: 44100,
  audioBitRate: 128,
  audioChannels: 2,
  audioWorkerURL: '',
  audioWebAssemblyURL: '',
  audioBufferUpdate: false,
  animationFrameRate: 200,
  animationQuality: 10,
  imageOutputType: 'dataURL',
  imageOutputFormat: 'image/png',
  imageOutputQuality: 0.92,
  timeSlice: 0,
  convertEngine: '',
  convertWorkerURL: '',
  convertOptions: [],
  convertAuto: true,
  hotKeys: false,
  pluginLibraryOptions: {}
};
var _default = pluginDefaultOptions;
exports.default = _default;
module.exports = exports.default;

/***/ }),

/***/ "./src/js/engine/convert-engine.js":
/*!*****************************************!*\
  !*** ./src/js/engine/convert-engine.js ***!
  \*****************************************/
/***/ ((__unused_webpack_module, exports, __webpack_require__) => {

"use strict";


var _interopRequireDefault = __webpack_require__(/*! @babel/runtime/helpers/interopRequireDefault */ "./node_modules/@babel/runtime/helpers/interopRequireDefault.js");

Object.defineProperty(exports, "__esModule", ({
  value: true
}));
exports.FFMPEGWASM = exports.FFMPEGJS = exports.TSEBML = exports.CONVERT_PLUGINS = exports.ConvertEngine = void 0;

var _classCallCheck2 = _interopRequireDefault(__webpack_require__(/*! @babel/runtime/helpers/classCallCheck */ "./node_modules/@babel/runtime/helpers/classCallCheck.js"));

var _createClass2 = _interopRequireDefault(__webpack_require__(/*! @babel/runtime/helpers/createClass */ "./node_modules/@babel/runtime/helpers/createClass.js"));

var _inherits2 = _interopRequireDefault(__webpack_require__(/*! @babel/runtime/helpers/inherits */ "./node_modules/@babel/runtime/helpers/inherits.js"));

var _possibleConstructorReturn2 = _interopRequireDefault(__webpack_require__(/*! @babel/runtime/helpers/possibleConstructorReturn */ "./node_modules/@babel/runtime/helpers/possibleConstructorReturn.js"));

var _getPrototypeOf2 = _interopRequireDefault(__webpack_require__(/*! @babel/runtime/helpers/getPrototypeOf */ "./node_modules/@babel/runtime/helpers/getPrototypeOf.js"));

var _video = _interopRequireDefault(__webpack_require__(/*! video.js */ "video.js"));

var _fileUtil = __webpack_require__(/*! ../utils/file-util */ "./src/js/utils/file-util.js");

function _createSuper(Derived) { var hasNativeReflectConstruct = _isNativeReflectConstruct(); return function _createSuperInternal() { var Super = (0, _getPrototypeOf2.default)(Derived), result; if (hasNativeReflectConstruct) { var NewTarget = (0, _getPrototypeOf2.default)(this).constructor; result = Reflect.construct(Super, arguments, NewTarget); } else { result = Super.apply(this, arguments); } return (0, _possibleConstructorReturn2.default)(this, result); }; }

function _isNativeReflectConstruct() { if (typeof Reflect === "undefined" || !Reflect.construct) return false; if (Reflect.construct.sham) return false; if (typeof Proxy === "function") return true; try { Boolean.prototype.valueOf.call(Reflect.construct(Boolean, [], function () {})); return true; } catch (e) { return false; } }

var Component = _video.default.getComponent('Component');

var TSEBML = 'ts-ebml';
exports.TSEBML = TSEBML;
var FFMPEGJS = 'ffmpeg.js';
exports.FFMPEGJS = FFMPEGJS;
var FFMPEGWASM = 'ffmpeg.wasm';
exports.FFMPEGWASM = FFMPEGWASM;
var CONVERT_PLUGINS = [TSEBML, FFMPEGJS, FFMPEGWASM];
exports.CONVERT_PLUGINS = CONVERT_PLUGINS;

var ConvertEngine = function (_Component) {
  (0, _inherits2.default)(ConvertEngine, _Component);

  var _super = _createSuper(ConvertEngine);

  function ConvertEngine(player, options) {
    (0, _classCallCheck2.default)(this, ConvertEngine);
    options.evented = true;
    return _super.call(this, player, options);
  }

  (0, _createClass2.default)(ConvertEngine, [{
    key: "setup",
    value: function setup(mediaType, debug) {
      this.mediaType = mediaType;
      this.debug = debug;
    }
  }, {
    key: "loadBlob",
    value: function loadBlob(data) {
      return (0, _fileUtil.blobToArrayBuffer)(data);
    }
  }, {
    key: "addFileInfo",
    value: function addFileInfo(fileObj, now) {
      (0, _fileUtil.addFileInfo)(fileObj, now);
    }
  }, {
    key: "saveAs",
    value: function saveAs(name) {
      var fileName = name[Object.keys(name)[0]];
      (0, _fileUtil.downloadBlob)(fileName, this.player().convertedData);
    }
  }]);
  return ConvertEngine;
}(Component);

exports.ConvertEngine = ConvertEngine;
_video.default.ConvertEngine = ConvertEngine;
Component.registerComponent('ConvertEngine', ConvertEngine);

/***/ }),

/***/ "./src/js/engine/engine-loader.js":
/*!****************************************!*\
  !*** ./src/js/engine/engine-loader.js ***!
  \****************************************/
/***/ ((__unused_webpack_module, exports, __webpack_require__) => {

"use strict";


var _interopRequireDefault = __webpack_require__(/*! @babel/runtime/helpers/interopRequireDefault */ "./node_modules/@babel/runtime/helpers/interopRequireDefault.js");

Object.defineProperty(exports, "__esModule", ({
  value: true
}));
exports.getConvertEngine = exports.getVideoEngine = exports.isAudioPluginActive = exports.getAudioEngine = void 0;

var _video = _interopRequireDefault(__webpack_require__(/*! video.js */ "video.js"));

var _recordRtc = _interopRequireDefault(__webpack_require__(/*! ./record-rtc */ "./src/js/engine/record-rtc.js"));

var _convertEngine = __webpack_require__(/*! ./convert-engine */ "./src/js/engine/convert-engine.js");

var _recordEngine = __webpack_require__(/*! ./record-engine */ "./src/js/engine/record-engine.js");

var getAudioEngine = function getAudioEngine(audioEngine) {
  var AudioEngineClass;

  switch (audioEngine) {
    case _recordEngine.RECORDRTC:
      AudioEngineClass = _recordRtc.default;
      break;

    case _recordEngine.LIBVORBISJS:
      AudioEngineClass = _video.default.LibVorbisEngine;
      break;

    case _recordEngine.RECORDERJS:
      AudioEngineClass = _video.default.RecorderjsEngine;
      break;

    case _recordEngine.LAMEJS:
      AudioEngineClass = _video.default.LamejsEngine;
      break;

    case _recordEngine.OPUSRECORDER:
      AudioEngineClass = _video.default.OpusRecorderEngine;
      break;

    case _recordEngine.OPUSMEDIARECORDER:
      AudioEngineClass = _video.default.OpusMediaRecorderEngine;
      break;

    case _recordEngine.VMSG:
      AudioEngineClass = _video.default.VmsgEngine;
      break;

    default:
      throw new Error('Unknown audioEngine: ' + audioEngine);
  }

  return AudioEngineClass;
};

exports.getAudioEngine = getAudioEngine;

var getVideoEngine = function getVideoEngine(videoEngine) {
  var VideoEngineClass;

  switch (videoEngine) {
    case _recordEngine.RECORDRTC:
      VideoEngineClass = _recordRtc.default;
      break;

    case _recordEngine.WEBMWASM:
      VideoEngineClass = _video.default.WebmWasmEngine;
      break;

    default:
      throw new Error('Unknown videoEngine: ' + videoEngine);
  }

  return VideoEngineClass;
};

exports.getVideoEngine = getVideoEngine;

var isAudioPluginActive = function isAudioPluginActive(audioEngine) {
  return _recordEngine.AUDIO_PLUGINS.indexOf(audioEngine) > -1;
};

exports.isAudioPluginActive = isAudioPluginActive;

var getConvertEngine = function getConvertEngine(convertEngine) {
  var ConvertEngineClass;

  switch (convertEngine) {
    case '':
      break;

    case _convertEngine.TSEBML:
      ConvertEngineClass = _video.default.TsEBMLEngine;
      break;

    case _convertEngine.FFMPEGJS:
      ConvertEngineClass = _video.default.FFmpegjsEngine;
      break;

    case _convertEngine.FFMPEGWASM:
      ConvertEngineClass = _video.default.FFmpegWasmEngine;
      break;

    default:
      throw new Error('Unknown convertEngine: ' + convertEngine);
  }

  return ConvertEngineClass;
};

exports.getConvertEngine = getConvertEngine;

/***/ }),

/***/ "./src/js/engine/record-engine.js":
/*!****************************************!*\
  !*** ./src/js/engine/record-engine.js ***!
  \****************************************/
/***/ ((__unused_webpack_module, exports, __webpack_require__) => {

"use strict";


var _interopRequireDefault = __webpack_require__(/*! @babel/runtime/helpers/interopRequireDefault */ "./node_modules/@babel/runtime/helpers/interopRequireDefault.js");

Object.defineProperty(exports, "__esModule", ({
  value: true
}));
exports.WEBMWASM = exports.VMSG = exports.OPUSMEDIARECORDER = exports.OPUSRECORDER = exports.LAMEJS = exports.RECORDERJS = exports.LIBVORBISJS = exports.RECORDRTC = exports.VIDEO_PLUGINS = exports.AUDIO_PLUGINS = exports.RECORD_PLUGINS = exports.RecordEngine = void 0;

var _classCallCheck2 = _interopRequireDefault(__webpack_require__(/*! @babel/runtime/helpers/classCallCheck */ "./node_modules/@babel/runtime/helpers/classCallCheck.js"));

var _createClass2 = _interopRequireDefault(__webpack_require__(/*! @babel/runtime/helpers/createClass */ "./node_modules/@babel/runtime/helpers/createClass.js"));

var _inherits2 = _interopRequireDefault(__webpack_require__(/*! @babel/runtime/helpers/inherits */ "./node_modules/@babel/runtime/helpers/inherits.js"));

var _possibleConstructorReturn2 = _interopRequireDefault(__webpack_require__(/*! @babel/runtime/helpers/possibleConstructorReturn */ "./node_modules/@babel/runtime/helpers/possibleConstructorReturn.js"));

var _getPrototypeOf2 = _interopRequireDefault(__webpack_require__(/*! @babel/runtime/helpers/getPrototypeOf */ "./node_modules/@babel/runtime/helpers/getPrototypeOf.js"));

var _video = _interopRequireDefault(__webpack_require__(/*! video.js */ "video.js"));

var _event = _interopRequireDefault(__webpack_require__(/*! ../event */ "./src/js/event.js"));

var _fileUtil = __webpack_require__(/*! ../utils/file-util */ "./src/js/utils/file-util.js");

function _createSuper(Derived) { var hasNativeReflectConstruct = _isNativeReflectConstruct(); return function _createSuperInternal() { var Super = (0, _getPrototypeOf2.default)(Derived), result; if (hasNativeReflectConstruct) { var NewTarget = (0, _getPrototypeOf2.default)(this).constructor; result = Reflect.construct(Super, arguments, NewTarget); } else { result = Super.apply(this, arguments); } return (0, _possibleConstructorReturn2.default)(this, result); }; }

function _isNativeReflectConstruct() { if (typeof Reflect === "undefined" || !Reflect.construct) return false; if (Reflect.construct.sham) return false; if (typeof Proxy === "function") return true; try { Boolean.prototype.valueOf.call(Reflect.construct(Boolean, [], function () {})); return true; } catch (e) { return false; } }

var Component = _video.default.getComponent('Component');

var RECORDRTC = 'recordrtc';
exports.RECORDRTC = RECORDRTC;
var LIBVORBISJS = 'libvorbis.js';
exports.LIBVORBISJS = LIBVORBISJS;
var RECORDERJS = 'recorder.js';
exports.RECORDERJS = RECORDERJS;
var LAMEJS = 'lamejs';
exports.LAMEJS = LAMEJS;
var OPUSRECORDER = 'opus-recorder';
exports.OPUSRECORDER = OPUSRECORDER;
var OPUSMEDIARECORDER = 'opus-media-recorder';
exports.OPUSMEDIARECORDER = OPUSMEDIARECORDER;
var VMSG = 'vmsg';
exports.VMSG = VMSG;
var WEBMWASM = 'webm-wasm';
exports.WEBMWASM = WEBMWASM;
var AUDIO_PLUGINS = [LIBVORBISJS, RECORDERJS, LAMEJS, OPUSRECORDER, OPUSMEDIARECORDER, VMSG];
exports.AUDIO_PLUGINS = AUDIO_PLUGINS;
var VIDEO_PLUGINS = [WEBMWASM];
exports.VIDEO_PLUGINS = VIDEO_PLUGINS;
var RECORD_PLUGINS = AUDIO_PLUGINS.concat(VIDEO_PLUGINS);
exports.RECORD_PLUGINS = RECORD_PLUGINS;

var RecordEngine = function (_Component) {
  (0, _inherits2.default)(RecordEngine, _Component);

  var _super = _createSuper(RecordEngine);

  function RecordEngine(player, options) {
    (0, _classCallCheck2.default)(this, RecordEngine);
    options.evented = true;
    return _super.call(this, player, options);
  }

  (0, _createClass2.default)(RecordEngine, [{
    key: "dispose",
    value: function dispose() {
      if (this.recordedData !== undefined) {
        URL.revokeObjectURL(this.recordedData);
      }
    }
  }, {
    key: "destroy",
    value: function destroy() {}
  }, {
    key: "addFileInfo",
    value: function addFileInfo(fileObj) {
      (0, _fileUtil.addFileInfo)(fileObj);
    }
  }, {
    key: "onStopRecording",
    value: function onStopRecording(data) {
      this.recordedData = data;
      this.addFileInfo(this.recordedData);
      this.dispose();
      this.trigger(_event.default.RECORD_COMPLETE);
    }
  }, {
    key: "saveAs",
    value: function saveAs(name) {
      var fileName = name[Object.keys(name)[0]];
      (0, _fileUtil.downloadBlob)(fileName, this.recordedData);
    }
  }]);
  return RecordEngine;
}(Component);

exports.RecordEngine = RecordEngine;
_video.default.RecordEngine = RecordEngine;
Component.registerComponent('RecordEngine', RecordEngine);

/***/ }),

/***/ "./src/js/engine/record-mode.js":
/*!**************************************!*\
  !*** ./src/js/engine/record-mode.js ***!
  \**************************************/
/***/ ((__unused_webpack_module, exports) => {

"use strict";


Object.defineProperty(exports, "__esModule", ({
  value: true
}));
exports.AUDIO_SCREEN = exports.SCREEN_ONLY = exports.ANIMATION = exports.AUDIO_VIDEO = exports.VIDEO_ONLY = exports.AUDIO_ONLY = exports.IMAGE_ONLY = exports.getRecorderMode = void 0;
var IMAGE_ONLY = 'image_only';
exports.IMAGE_ONLY = IMAGE_ONLY;
var AUDIO_ONLY = 'audio_only';
exports.AUDIO_ONLY = AUDIO_ONLY;
var VIDEO_ONLY = 'video_only';
exports.VIDEO_ONLY = VIDEO_ONLY;
var AUDIO_VIDEO = 'audio_video';
exports.AUDIO_VIDEO = AUDIO_VIDEO;
var AUDIO_SCREEN = 'audio_screen';
exports.AUDIO_SCREEN = AUDIO_SCREEN;
var ANIMATION = 'animation';
exports.ANIMATION = ANIMATION;
var SCREEN_ONLY = 'screen_only';
exports.SCREEN_ONLY = SCREEN_ONLY;

var getRecorderMode = function getRecorderMode(image, audio, video, animation, screen) {
  if (isModeEnabled(image)) {
    return IMAGE_ONLY;
  } else if (isModeEnabled(animation)) {
    return ANIMATION;
  } else if (isModeEnabled(audio) && isModeEnabled(video)) {
    return AUDIO_VIDEO;
  } else if (isModeEnabled(audio) && isModeEnabled(screen)) {
    return AUDIO_SCREEN;
  } else if (!isModeEnabled(audio) && isModeEnabled(screen)) {
    return SCREEN_ONLY;
  } else if (isModeEnabled(audio) && !isModeEnabled(video)) {
    return AUDIO_ONLY;
  } else if (!isModeEnabled(audio) && isModeEnabled(video)) {
    return VIDEO_ONLY;
  }
};

exports.getRecorderMode = getRecorderMode;

var isModeEnabled = function isModeEnabled(mode) {
  return mode === Object(mode) || mode === true;
};

/***/ }),

/***/ "./src/js/engine/record-rtc.js":
/*!*************************************!*\
  !*** ./src/js/engine/record-rtc.js ***!
  \*************************************/
/***/ ((module, exports, __webpack_require__) => {

"use strict";


var _interopRequireDefault = __webpack_require__(/*! @babel/runtime/helpers/interopRequireDefault */ "./node_modules/@babel/runtime/helpers/interopRequireDefault.js");

Object.defineProperty(exports, "__esModule", ({
  value: true
}));
exports.default = void 0;

var _classCallCheck2 = _interopRequireDefault(__webpack_require__(/*! @babel/runtime/helpers/classCallCheck */ "./node_modules/@babel/runtime/helpers/classCallCheck.js"));

var _createClass2 = _interopRequireDefault(__webpack_require__(/*! @babel/runtime/helpers/createClass */ "./node_modules/@babel/runtime/helpers/createClass.js"));

var _get2 = _interopRequireDefault(__webpack_require__(/*! @babel/runtime/helpers/get */ "./node_modules/@babel/runtime/helpers/get.js"));

var _inherits2 = _interopRequireDefault(__webpack_require__(/*! @babel/runtime/helpers/inherits */ "./node_modules/@babel/runtime/helpers/inherits.js"));

var _possibleConstructorReturn2 = _interopRequireDefault(__webpack_require__(/*! @babel/runtime/helpers/possibleConstructorReturn */ "./node_modules/@babel/runtime/helpers/possibleConstructorReturn.js"));

var _getPrototypeOf2 = _interopRequireDefault(__webpack_require__(/*! @babel/runtime/helpers/getPrototypeOf */ "./node_modules/@babel/runtime/helpers/getPrototypeOf.js"));

var _video = _interopRequireDefault(__webpack_require__(/*! video.js */ "video.js"));

var _recordrtc = _interopRequireDefault(__webpack_require__(/*! recordrtc */ "recordrtc"));

var _event = _interopRequireDefault(__webpack_require__(/*! ../event */ "./src/js/event.js"));

var _recordEngine = __webpack_require__(/*! ./record-engine */ "./src/js/engine/record-engine.js");

var _detectBrowser = __webpack_require__(/*! ../utils/detect-browser */ "./src/js/utils/detect-browser.js");

var _recordMode = __webpack_require__(/*! ./record-mode */ "./src/js/engine/record-mode.js");

function _createSuper(Derived) { var hasNativeReflectConstruct = _isNativeReflectConstruct(); return function _createSuperInternal() { var Super = (0, _getPrototypeOf2.default)(Derived), result; if (hasNativeReflectConstruct) { var NewTarget = (0, _getPrototypeOf2.default)(this).constructor; result = Reflect.construct(Super, arguments, NewTarget); } else { result = Super.apply(this, arguments); } return (0, _possibleConstructorReturn2.default)(this, result); }; }

function _isNativeReflectConstruct() { if (typeof Reflect === "undefined" || !Reflect.construct) return false; if (Reflect.construct.sham) return false; if (typeof Proxy === "function") return true; try { Boolean.prototype.valueOf.call(Reflect.construct(Boolean, [], function () {})); return true; } catch (e) { return false; } }

var Component = _video.default.getComponent('Component');

var RecordRTCEngine = function (_RecordEngine) {
  (0, _inherits2.default)(RecordRTCEngine, _RecordEngine);

  var _super = _createSuper(RecordRTCEngine);

  function RecordRTCEngine() {
    (0, _classCallCheck2.default)(this, RecordRTCEngine);
    return _super.apply(this, arguments);
  }

  (0, _createClass2.default)(RecordRTCEngine, [{
    key: "setup",
    value: function setup(stream, mediaType, debug) {
      this.inputStream = stream;
      this.mediaType = mediaType;
      this.debug = debug;

      if ('screen' in this.mediaType) {
        this.mediaType.video = true;
      }

      if (this.recorderType !== undefined) {
        this.mediaType.video = this.recorderType;
      }

      this.engine = new _recordrtc.default.MRecordRTC();
      this.engine.mediaType = this.mediaType;
      this.engine.disableLogs = !this.debug;
      this.engine.mimeType = this.mimeType;
      this.engine.bufferSize = this.bufferSize;
      this.engine.sampleRate = this.sampleRate;
      this.engine.numberOfAudioChannels = this.audioChannels;
      this.engine.video = this.video;
      this.engine.canvas = this.canvas;
      this.engine.bitrate = this.bitRate;
      this.engine.quality = this.quality;
      this.engine.frameRate = this.frameRate;

      if (this.timeSlice !== undefined) {
        this.engine.timeSlice = this.timeSlice;
        this.engine.onTimeStamp = this.onTimeStamp.bind(this);
      }

      this.engine.workerPath = this.workerPath;
      this.engine.webAssemblyPath = this.videoWebAssemblyURL;
      this.engine.addStream(this.inputStream);
    }
  }, {
    key: "dispose",
    value: function dispose() {
      (0, _get2.default)((0, _getPrototypeOf2.default)(RecordRTCEngine.prototype), "dispose", this).call(this);
      this.destroy();
    }
  }, {
    key: "destroy",
    value: function destroy() {
      if (this.engine && typeof this.engine.destroy === 'function') {
        this.engine.destroy();
      }
    }
  }, {
    key: "start",
    value: function start() {
      this.engine.startRecording();
    }
  }, {
    key: "stop",
    value: function stop() {
      this.engine.stopRecording(this.onStopRecording.bind(this));
    }
  }, {
    key: "pause",
    value: function pause() {
      this.engine.pauseRecording();
    }
  }, {
    key: "resume",
    value: function resume() {
      this.engine.resumeRecording();
    }
  }, {
    key: "saveAs",
    value: function saveAs(name) {
      if (this.engine && name !== undefined) {
        this.engine.save(name);
      }
    }
  }, {
    key: "onStopRecording",
    value: function onStopRecording(audioVideoURL, type) {
      var _this = this;

      URL.revokeObjectURL(audioVideoURL);
      var recordType = this.player().record().getRecordType();
      this.engine.getBlob(function (recording) {
        switch (recordType) {
          case _recordMode.AUDIO_ONLY:
            if (recording.audio !== undefined) {
              _this.recordedData = recording.audio;
            }

            break;

          case _recordMode.VIDEO_ONLY:
          case _recordMode.AUDIO_VIDEO:
          case _recordMode.AUDIO_SCREEN:
          case _recordMode.SCREEN_ONLY:
            if (recording.video !== undefined) {
              _this.recordedData = recording.video;
            }

            break;

          case _recordMode.ANIMATION:
            if (recording.gif !== undefined) {
              _this.recordedData = recording.gif;
            }

            break;
        }

        _this.addFileInfo(_this.recordedData);

        _this.trigger(_event.default.RECORD_COMPLETE);
      });
    }
  }, {
    key: "onTimeStamp",
    value: function onTimeStamp(current, all) {
      this.player().currentTimestamp = current;
      this.player().allTimestamps = all;
      var internal;

      switch (this.player().record().getRecordType()) {
        case _recordMode.AUDIO_ONLY:
          internal = this.engine.audioRecorder;
          break;

        case _recordMode.ANIMATION:
          internal = this.engine.gifRecorder;
          break;

        default:
          internal = this.engine.videoRecorder;
      }

      var maxFileSizeReached = false;

      if (internal) {
        internal = internal.getInternalRecorder();
      }

      if (internal instanceof _recordrtc.default.MediaStreamRecorder === true) {
        this.player().recordedData = internal.getArrayOfBlobs();
        this.addFileInfo(this.player().recordedData[this.player_.recordedData.length - 1]);

        if (this.maxFileSize > 0) {
          var currentSize = new Blob(this.player().recordedData).size;

          if (currentSize >= this.maxFileSize) {
            maxFileSizeReached = true;
          }
        }
      }

      this.player().trigger(_event.default.TIMESTAMP);

      if (maxFileSizeReached) {
        this.player().record().stop();
      }
    }
  }]);
  return RecordRTCEngine;
}(_recordEngine.RecordEngine);

_video.default.RecordRTCEngine = RecordRTCEngine;
Component.registerComponent('RecordRTCEngine', RecordRTCEngine);
var _default = RecordRTCEngine;
exports.default = _default;
module.exports = exports.default;

/***/ }),

/***/ "./src/js/event.js":
/*!*************************!*\
  !*** ./src/js/event.js ***!
  \*************************/
/***/ ((module, exports, __webpack_require__) => {

"use strict";


var _interopRequireDefault = __webpack_require__(/*! @babel/runtime/helpers/interopRequireDefault */ "./node_modules/@babel/runtime/helpers/interopRequireDefault.js");

Object.defineProperty(exports, "__esModule", ({
  value: true
}));
exports.default = void 0;

var _classCallCheck2 = _interopRequireDefault(__webpack_require__(/*! @babel/runtime/helpers/classCallCheck */ "./node_modules/@babel/runtime/helpers/classCallCheck.js"));

var Event = function Event() {
  (0, _classCallCheck2.default)(this, Event);
};

Event.READY = 'ready';
Event.ERROR = 'error';
Event.PLAYING = 'playing';
Event.LOADEDMETADATA = 'loadedmetadata';
Event.LOADSTART = 'loadstart';
Event.USERINACTIVE = 'userinactive';
Event.TIMEUPDATE = 'timeupdate';
Event.DURATIONCHANGE = 'durationchange';
Event.ENDED = 'ended';
Event.PAUSE = 'pause';
Event.PLAY = 'play';
Event.DEVICE_READY = 'deviceReady';
Event.DEVICE_ERROR = 'deviceError';
Event.START_RECORD = 'startRecord';
Event.STOP_RECORD = 'stopRecord';
Event.FINISH_RECORD = 'finishRecord';
Event.RECORD_COMPLETE = 'recordComplete';
Event.PROGRESS_RECORD = 'progressRecord';
Event.TIMESTAMP = 'timestamp';
Event.ENUMERATE_READY = 'enumerateReady';
Event.ENUMERATE_ERROR = 'enumerateError';
Event.AUDIO_BUFFER_UPDATE = 'audioBufferUpdate';
Event.AUDIO_OUTPUT_READY = 'audioOutputReady';
Event.START_CONVERT = 'startConvert';
Event.FINISH_CONVERT = 'finishConvert';
Event.ENTER_PIP = 'enterPIP';
Event.LEAVE_PIP = 'leavePIP';
Event.RETRY = 'retry';
Event.ENTERPICTUREINPICTURE = 'enterpictureinpicture';
Event.LEAVEPICTUREINPICTURE = 'leavepictureinpicture';
Object.freeze(Event);
var _default = Event;
exports.default = _default;
module.exports = exports.default;

/***/ }),

/***/ "./src/js/hot-keys.js":
/*!****************************!*\
  !*** ./src/js/hot-keys.js ***!
  \****************************/
/***/ ((module, exports, __webpack_require__) => {

"use strict";


Object.defineProperty(exports, "__esModule", ({
  value: true
}));
exports.default = void 0;

var _recordMode = __webpack_require__(/*! ./engine/record-mode */ "./src/js/engine/record-mode.js");

var X_KEY = 88;
var P_KEY = 80;
var C_KEY = 67;

var defaultKeyHandler = function defaultKeyHandler(event) {
  switch (event.which) {
    case X_KEY:
      switch (this.player_.record().getRecordType()) {
        case _recordMode.IMAGE_ONLY:
          this.player_.cameraButton.trigger('click');
          break;

        default:
          this.player_.recordToggle.trigger('click');
      }

      break;

    case P_KEY:
      if (this.player_.record().pictureInPicture === true) {
        this.player_.pipToggle.trigger('click');
      }

      break;

    case C_KEY:
      if (this.player_.controlBar.playToggle && this.player_.controlBar.playToggle.contentEl()) {
        player.controlBar.playToggle.trigger('click');
      }

      break;
  }
};

var _default = defaultKeyHandler;
exports.default = _default;
module.exports = exports.default;

/***/ }),

/***/ "./src/js/utils/browser-shim.js":
/*!**************************************!*\
  !*** ./src/js/utils/browser-shim.js ***!
  \**************************************/
/***/ ((module, exports) => {

"use strict";


Object.defineProperty(exports, "__esModule", ({
  value: true
}));
exports.default = void 0;

var setSrcObject = function setSrcObject(stream, element) {
  if ('srcObject' in element) {
    element.srcObject = stream;
  } else if ('mozSrcObject' in element) {
    element.mozSrcObject = stream;
  } else {
    element.srcObject = stream;
  }
};

var _default = setSrcObject;
exports.default = _default;
module.exports = exports.default;

/***/ }),

/***/ "./src/js/utils/compare-version.js":
/*!*****************************************!*\
  !*** ./src/js/utils/compare-version.js ***!
  \*****************************************/
/***/ ((module, exports) => {

"use strict";


Object.defineProperty(exports, "__esModule", ({
  value: true
}));
exports.default = void 0;

var compareVersion = function compareVersion(v1, v2) {
  if (typeof v1 !== 'string') return false;
  if (typeof v2 !== 'string') return false;
  v1 = v1.split('.');
  v2 = v2.split('.');
  var k = Math.min(v1.length, v2.length);
  var i = 0;

  for (i; i < k; ++i) {
    v1[i] = parseInt(v1[i], 10);
    v2[i] = parseInt(v2[i], 10);
    if (v1[i] > v2[i]) return 1;
    if (v1[i] < v2[i]) return -1;
  }

  return v1.length === v2.length ? 0 : v1.length < v2.length ? -1 : 1;
};

var _default = compareVersion;
exports.default = _default;
module.exports = exports.default;

/***/ }),

/***/ "./src/js/utils/detect-browser.js":
/*!****************************************!*\
  !*** ./src/js/utils/detect-browser.js ***!
  \****************************************/
/***/ ((__unused_webpack_module, exports, __webpack_require__) => {

"use strict";


var _interopRequireDefault = __webpack_require__(/*! @babel/runtime/helpers/interopRequireDefault */ "./node_modules/@babel/runtime/helpers/interopRequireDefault.js");

Object.defineProperty(exports, "__esModule", ({
  value: true
}));
exports.isFirefox = exports.isSafari = exports.isChrome = exports.isOpera = exports.isEdge = exports.detectBrowser = void 0;

var _window = _interopRequireDefault(__webpack_require__(/*! global/window */ "./node_modules/global/window.js"));

var detectBrowser = function detectBrowser() {
  var result = {};
  result.browser = null;
  result.version = null;
  result.minVersion = null;

  if (typeof _window.default === 'undefined' || !_window.default.navigator) {
    result.browser = 'Not a supported browser.';
    return result;
  }

  if (navigator.mozGetUserMedia) {
    result.browser = 'firefox';
    result.version = extractVersion(navigator.userAgent, /Firefox\/(\d+)\./, 1);
    result.minVersion = 31;
  } else if (navigator.webkitGetUserMedia) {
    result.browser = 'chrome';
    result.version = extractVersion(navigator.userAgent, /Chrom(e|ium)\/(\d+)\./, 2);
    result.minVersion = 38;
  } else if (navigator.mediaDevices && navigator.userAgent.match(/Edge\/(\d+).(\d+)$/)) {
    result.browser = 'edge';
    result.version = extractVersion(navigator.userAgent, /Edge\/(\d+).(\d+)$/, 2);
    result.minVersion = 10547;
  } else if (_window.default.RTCPeerConnection && navigator.userAgent.match(/AppleWebKit\/(\d+)\./)) {
    result.browser = 'safari';
    result.version = extractVersion(navigator.userAgent, /AppleWebKit\/(\d+)\./, 1);
  } else {
    result.browser = 'Not a supported browser.';
    return result;
  }

  return result;
};

exports.detectBrowser = detectBrowser;

var extractVersion = function extractVersion(uastring, expr, pos) {
  var match = uastring.match(expr);
  return match && match.length >= pos && parseInt(match[pos], 10);
};

var isEdge = function isEdge() {
  return detectBrowser().browser === 'edge';
};

exports.isEdge = isEdge;

var isSafari = function isSafari() {
  return detectBrowser().browser === 'safari';
};

exports.isSafari = isSafari;

var isOpera = function isOpera() {
  return !!_window.default.opera || navigator.userAgent.indexOf('OPR/') !== -1;
};

exports.isOpera = isOpera;

var isChrome = function isChrome() {
  return detectBrowser().browser === 'chrome';
};

exports.isChrome = isChrome;

var isFirefox = function isFirefox() {
  return detectBrowser().browser === 'firefox';
};

exports.isFirefox = isFirefox;

/***/ }),

/***/ "./src/js/utils/file-util.js":
/*!***********************************!*\
  !*** ./src/js/utils/file-util.js ***!
  \***********************************/
/***/ ((__unused_webpack_module, exports, __webpack_require__) => {

"use strict";


var _interopRequireDefault = __webpack_require__(/*! @babel/runtime/helpers/interopRequireDefault */ "./node_modules/@babel/runtime/helpers/interopRequireDefault.js");

Object.defineProperty(exports, "__esModule", ({
  value: true
}));
exports.addFileInfo = exports.blobToArrayBuffer = exports.downloadBlob = void 0;

var _mime = _interopRequireDefault(__webpack_require__(/*! ./mime */ "./src/js/utils/mime.js"));

var downloadBlob = function downloadBlob(fileName, data) {
  if (typeof navigator.msSaveOrOpenBlob !== 'undefined') {
    return navigator.msSaveOrOpenBlob(data, fileName);
  } else if (typeof navigator.msSaveBlob !== 'undefined') {
    return navigator.msSaveBlob(data, fileName);
  }

  var hyperlink = document.createElement('a');
  hyperlink.href = URL.createObjectURL(data);
  hyperlink.download = fileName;
  hyperlink.style = 'display:none;opacity:0;color:transparent;';
  (document.body || document.documentElement).appendChild(hyperlink);

  if (typeof hyperlink.click === 'function') {
    hyperlink.click();
  } else {
    hyperlink.target = '_blank';
    hyperlink.dispatchEvent(new MouseEvent('click', {
      view: window,
      bubbles: true,
      cancelable: true
    }));
  }

  URL.revokeObjectURL(hyperlink.href);
};

exports.downloadBlob = downloadBlob;

var blobToArrayBuffer = function blobToArrayBuffer(fileObj) {
  return new Promise(function (resolve, reject) {
    var reader = new FileReader();

    reader.onloadend = function () {
      resolve(reader.result);
    };

    reader.onerror = function (ev) {
      reject(ev.error);
    };

    reader.readAsArrayBuffer(fileObj);
  });
};

exports.blobToArrayBuffer = blobToArrayBuffer;

var addFileInfo = function addFileInfo(fileObj, dateObj, fileExtension) {
  if (fileObj instanceof Blob || fileObj instanceof File) {
    if (dateObj === undefined) {
      dateObj = new Date();
    }

    try {
      fileObj.lastModified = dateObj.getTime();
      fileObj.lastModifiedDate = dateObj;
    } catch (e) {
      if (e instanceof TypeError) {} else {
        throw e;
      }
    }

    if (fileExtension === undefined) {
      fileExtension = '.' + (0, _mime.default)(fileObj.type);
    }

    try {
      fileObj.name = dateObj.getTime() + fileExtension;
    } catch (e) {
      if (e instanceof TypeError) {} else {
        throw e;
      }
    }
  }
};

exports.addFileInfo = addFileInfo;

/***/ }),

/***/ "./src/js/utils/format-time.js":
/*!*************************************!*\
  !*** ./src/js/utils/format-time.js ***!
  \*************************************/
/***/ ((module, exports, __webpack_require__) => {

"use strict";


var _interopRequireDefault = __webpack_require__(/*! @babel/runtime/helpers/interopRequireDefault */ "./node_modules/@babel/runtime/helpers/interopRequireDefault.js");

Object.defineProperty(exports, "__esModule", ({
  value: true
}));
exports.default = void 0;

var _parseMs = _interopRequireDefault(__webpack_require__(/*! parse-ms */ "./node_modules/parse-ms/index.js"));

var _addZero = _interopRequireDefault(__webpack_require__(/*! add-zero */ "./node_modules/add-zero/index.js"));

var formatTime = function formatTime(seconds, guide) {
  var displayMilliseconds = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : false;
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

/***/ "./src/js/utils/mime.js":
/*!******************************!*\
  !*** ./src/js/utils/mime.js ***!
  \******************************/
/***/ ((module, exports) => {

"use strict";


Object.defineProperty(exports, "__esModule", ({
  value: true
}));
exports.default = void 0;
var EXTRACT_TYPE_REGEXP = /^\s*([^;\s]*)(?:;|\s|$)/;
var Mimetypes = {
  'video/ogg': 'ogv',
  'video/mp4': 'mp4',
  'video/x-matroska': 'mkv',
  'video/webm': 'webm',
  'audio/mp4': 'm4a',
  'audio/mpeg': 'mp3',
  'audio/aac': 'aac',
  'audio/flac': 'flac',
  'audio/ogg': 'oga',
  'audio/wav': 'wav',
  'audio/webm': 'webm',
  'application/x-mpegURL': 'm3u8',
  'image/jpeg': 'jpg',
  'image/gif': 'gif',
  'image/png': 'png',
  'image/svg+xml': 'svg',
  'image/webp': 'webp'
};

var getExtension = function getExtension(mimeType) {
  var match = EXTRACT_TYPE_REGEXP.exec(mimeType);
  var result = match && match[1].toLowerCase();
  return Mimetypes[result];
};

var _default = getExtension;
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

/***/ "./node_modules/regenerator-runtime/runtime.js":
/*!*****************************************************!*\
  !*** ./node_modules/regenerator-runtime/runtime.js ***!
  \*****************************************************/
/***/ ((module) => {

/**
 * Copyright (c) 2014-present, Facebook, Inc.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

var runtime = (function (exports) {
  "use strict";

  var Op = Object.prototype;
  var hasOwn = Op.hasOwnProperty;
  var undefined; // More compressible than void 0.
  var $Symbol = typeof Symbol === "function" ? Symbol : {};
  var iteratorSymbol = $Symbol.iterator || "@@iterator";
  var asyncIteratorSymbol = $Symbol.asyncIterator || "@@asyncIterator";
  var toStringTagSymbol = $Symbol.toStringTag || "@@toStringTag";

  function wrap(innerFn, outerFn, self, tryLocsList) {
    // If outerFn provided and outerFn.prototype is a Generator, then outerFn.prototype instanceof Generator.
    var protoGenerator = outerFn && outerFn.prototype instanceof Generator ? outerFn : Generator;
    var generator = Object.create(protoGenerator.prototype);
    var context = new Context(tryLocsList || []);

    // The ._invoke method unifies the implementations of the .next,
    // .throw, and .return methods.
    generator._invoke = makeInvokeMethod(innerFn, self, context);

    return generator;
  }
  exports.wrap = wrap;

  // Try/catch helper to minimize deoptimizations. Returns a completion
  // record like context.tryEntries[i].completion. This interface could
  // have been (and was previously) designed to take a closure to be
  // invoked without arguments, but in all the cases we care about we
  // already have an existing method we want to call, so there's no need
  // to create a new function object. We can even get away with assuming
  // the method takes exactly one argument, since that happens to be true
  // in every case, so we don't have to touch the arguments object. The
  // only additional allocation required is the completion record, which
  // has a stable shape and so hopefully should be cheap to allocate.
  function tryCatch(fn, obj, arg) {
    try {
      return { type: "normal", arg: fn.call(obj, arg) };
    } catch (err) {
      return { type: "throw", arg: err };
    }
  }

  var GenStateSuspendedStart = "suspendedStart";
  var GenStateSuspendedYield = "suspendedYield";
  var GenStateExecuting = "executing";
  var GenStateCompleted = "completed";

  // Returning this object from the innerFn has the same effect as
  // breaking out of the dispatch switch statement.
  var ContinueSentinel = {};

  // Dummy constructor functions that we use as the .constructor and
  // .constructor.prototype properties for functions that return Generator
  // objects. For full spec compliance, you may wish to configure your
  // minifier not to mangle the names of these two functions.
  function Generator() {}
  function GeneratorFunction() {}
  function GeneratorFunctionPrototype() {}

  // This is a polyfill for %IteratorPrototype% for environments that
  // don't natively support it.
  var IteratorPrototype = {};
  IteratorPrototype[iteratorSymbol] = function () {
    return this;
  };

  var getProto = Object.getPrototypeOf;
  var NativeIteratorPrototype = getProto && getProto(getProto(values([])));
  if (NativeIteratorPrototype &&
      NativeIteratorPrototype !== Op &&
      hasOwn.call(NativeIteratorPrototype, iteratorSymbol)) {
    // This environment has a native %IteratorPrototype%; use it instead
    // of the polyfill.
    IteratorPrototype = NativeIteratorPrototype;
  }

  var Gp = GeneratorFunctionPrototype.prototype =
    Generator.prototype = Object.create(IteratorPrototype);
  GeneratorFunction.prototype = Gp.constructor = GeneratorFunctionPrototype;
  GeneratorFunctionPrototype.constructor = GeneratorFunction;
  GeneratorFunctionPrototype[toStringTagSymbol] =
    GeneratorFunction.displayName = "GeneratorFunction";

  // Helper for defining the .next, .throw, and .return methods of the
  // Iterator interface in terms of a single ._invoke method.
  function defineIteratorMethods(prototype) {
    ["next", "throw", "return"].forEach(function(method) {
      prototype[method] = function(arg) {
        return this._invoke(method, arg);
      };
    });
  }

  exports.isGeneratorFunction = function(genFun) {
    var ctor = typeof genFun === "function" && genFun.constructor;
    return ctor
      ? ctor === GeneratorFunction ||
        // For the native GeneratorFunction constructor, the best we can
        // do is to check its .name property.
        (ctor.displayName || ctor.name) === "GeneratorFunction"
      : false;
  };

  exports.mark = function(genFun) {
    if (Object.setPrototypeOf) {
      Object.setPrototypeOf(genFun, GeneratorFunctionPrototype);
    } else {
      genFun.__proto__ = GeneratorFunctionPrototype;
      if (!(toStringTagSymbol in genFun)) {
        genFun[toStringTagSymbol] = "GeneratorFunction";
      }
    }
    genFun.prototype = Object.create(Gp);
    return genFun;
  };

  // Within the body of any async function, `await x` is transformed to
  // `yield regeneratorRuntime.awrap(x)`, so that the runtime can test
  // `hasOwn.call(value, "__await")` to determine if the yielded value is
  // meant to be awaited.
  exports.awrap = function(arg) {
    return { __await: arg };
  };

  function AsyncIterator(generator, PromiseImpl) {
    function invoke(method, arg, resolve, reject) {
      var record = tryCatch(generator[method], generator, arg);
      if (record.type === "throw") {
        reject(record.arg);
      } else {
        var result = record.arg;
        var value = result.value;
        if (value &&
            typeof value === "object" &&
            hasOwn.call(value, "__await")) {
          return PromiseImpl.resolve(value.__await).then(function(value) {
            invoke("next", value, resolve, reject);
          }, function(err) {
            invoke("throw", err, resolve, reject);
          });
        }

        return PromiseImpl.resolve(value).then(function(unwrapped) {
          // When a yielded Promise is resolved, its final value becomes
          // the .value of the Promise<{value,done}> result for the
          // current iteration.
          result.value = unwrapped;
          resolve(result);
        }, function(error) {
          // If a rejected Promise was yielded, throw the rejection back
          // into the async generator function so it can be handled there.
          return invoke("throw", error, resolve, reject);
        });
      }
    }

    var previousPromise;

    function enqueue(method, arg) {
      function callInvokeWithMethodAndArg() {
        return new PromiseImpl(function(resolve, reject) {
          invoke(method, arg, resolve, reject);
        });
      }

      return previousPromise =
        // If enqueue has been called before, then we want to wait until
        // all previous Promises have been resolved before calling invoke,
        // so that results are always delivered in the correct order. If
        // enqueue has not been called before, then it is important to
        // call invoke immediately, without waiting on a callback to fire,
        // so that the async generator function has the opportunity to do
        // any necessary setup in a predictable way. This predictability
        // is why the Promise constructor synchronously invokes its
        // executor callback, and why async functions synchronously
        // execute code before the first await. Since we implement simple
        // async functions in terms of async generators, it is especially
        // important to get this right, even though it requires care.
        previousPromise ? previousPromise.then(
          callInvokeWithMethodAndArg,
          // Avoid propagating failures to Promises returned by later
          // invocations of the iterator.
          callInvokeWithMethodAndArg
        ) : callInvokeWithMethodAndArg();
    }

    // Define the unified helper method that is used to implement .next,
    // .throw, and .return (see defineIteratorMethods).
    this._invoke = enqueue;
  }

  defineIteratorMethods(AsyncIterator.prototype);
  AsyncIterator.prototype[asyncIteratorSymbol] = function () {
    return this;
  };
  exports.AsyncIterator = AsyncIterator;

  // Note that simple async functions are implemented on top of
  // AsyncIterator objects; they just return a Promise for the value of
  // the final result produced by the iterator.
  exports.async = function(innerFn, outerFn, self, tryLocsList, PromiseImpl) {
    if (PromiseImpl === void 0) PromiseImpl = Promise;

    var iter = new AsyncIterator(
      wrap(innerFn, outerFn, self, tryLocsList),
      PromiseImpl
    );

    return exports.isGeneratorFunction(outerFn)
      ? iter // If outerFn is a generator, return the full iterator.
      : iter.next().then(function(result) {
          return result.done ? result.value : iter.next();
        });
  };

  function makeInvokeMethod(innerFn, self, context) {
    var state = GenStateSuspendedStart;

    return function invoke(method, arg) {
      if (state === GenStateExecuting) {
        throw new Error("Generator is already running");
      }

      if (state === GenStateCompleted) {
        if (method === "throw") {
          throw arg;
        }

        // Be forgiving, per 25.3.3.3.3 of the spec:
        // https://people.mozilla.org/~jorendorff/es6-draft.html#sec-generatorresume
        return doneResult();
      }

      context.method = method;
      context.arg = arg;

      while (true) {
        var delegate = context.delegate;
        if (delegate) {
          var delegateResult = maybeInvokeDelegate(delegate, context);
          if (delegateResult) {
            if (delegateResult === ContinueSentinel) continue;
            return delegateResult;
          }
        }

        if (context.method === "next") {
          // Setting context._sent for legacy support of Babel's
          // function.sent implementation.
          context.sent = context._sent = context.arg;

        } else if (context.method === "throw") {
          if (state === GenStateSuspendedStart) {
            state = GenStateCompleted;
            throw context.arg;
          }

          context.dispatchException(context.arg);

        } else if (context.method === "return") {
          context.abrupt("return", context.arg);
        }

        state = GenStateExecuting;

        var record = tryCatch(innerFn, self, context);
        if (record.type === "normal") {
          // If an exception is thrown from innerFn, we leave state ===
          // GenStateExecuting and loop back for another invocation.
          state = context.done
            ? GenStateCompleted
            : GenStateSuspendedYield;

          if (record.arg === ContinueSentinel) {
            continue;
          }

          return {
            value: record.arg,
            done: context.done
          };

        } else if (record.type === "throw") {
          state = GenStateCompleted;
          // Dispatch the exception by looping back around to the
          // context.dispatchException(context.arg) call above.
          context.method = "throw";
          context.arg = record.arg;
        }
      }
    };
  }

  // Call delegate.iterator[context.method](context.arg) and handle the
  // result, either by returning a { value, done } result from the
  // delegate iterator, or by modifying context.method and context.arg,
  // setting context.delegate to null, and returning the ContinueSentinel.
  function maybeInvokeDelegate(delegate, context) {
    var method = delegate.iterator[context.method];
    if (method === undefined) {
      // A .throw or .return when the delegate iterator has no .throw
      // method always terminates the yield* loop.
      context.delegate = null;

      if (context.method === "throw") {
        // Note: ["return"] must be used for ES3 parsing compatibility.
        if (delegate.iterator["return"]) {
          // If the delegate iterator has a return method, give it a
          // chance to clean up.
          context.method = "return";
          context.arg = undefined;
          maybeInvokeDelegate(delegate, context);

          if (context.method === "throw") {
            // If maybeInvokeDelegate(context) changed context.method from
            // "return" to "throw", let that override the TypeError below.
            return ContinueSentinel;
          }
        }

        context.method = "throw";
        context.arg = new TypeError(
          "The iterator does not provide a 'throw' method");
      }

      return ContinueSentinel;
    }

    var record = tryCatch(method, delegate.iterator, context.arg);

    if (record.type === "throw") {
      context.method = "throw";
      context.arg = record.arg;
      context.delegate = null;
      return ContinueSentinel;
    }

    var info = record.arg;

    if (! info) {
      context.method = "throw";
      context.arg = new TypeError("iterator result is not an object");
      context.delegate = null;
      return ContinueSentinel;
    }

    if (info.done) {
      // Assign the result of the finished delegate to the temporary
      // variable specified by delegate.resultName (see delegateYield).
      context[delegate.resultName] = info.value;

      // Resume execution at the desired location (see delegateYield).
      context.next = delegate.nextLoc;

      // If context.method was "throw" but the delegate handled the
      // exception, let the outer generator proceed normally. If
      // context.method was "next", forget context.arg since it has been
      // "consumed" by the delegate iterator. If context.method was
      // "return", allow the original .return call to continue in the
      // outer generator.
      if (context.method !== "return") {
        context.method = "next";
        context.arg = undefined;
      }

    } else {
      // Re-yield the result returned by the delegate method.
      return info;
    }

    // The delegate iterator is finished, so forget it and continue with
    // the outer generator.
    context.delegate = null;
    return ContinueSentinel;
  }

  // Define Generator.prototype.{next,throw,return} in terms of the
  // unified ._invoke helper method.
  defineIteratorMethods(Gp);

  Gp[toStringTagSymbol] = "Generator";

  // A Generator should always return itself as the iterator object when the
  // @@iterator function is called on it. Some browsers' implementations of the
  // iterator prototype chain incorrectly implement this, causing the Generator
  // object to not be returned from this call. This ensures that doesn't happen.
  // See https://github.com/facebook/regenerator/issues/274 for more details.
  Gp[iteratorSymbol] = function() {
    return this;
  };

  Gp.toString = function() {
    return "[object Generator]";
  };

  function pushTryEntry(locs) {
    var entry = { tryLoc: locs[0] };

    if (1 in locs) {
      entry.catchLoc = locs[1];
    }

    if (2 in locs) {
      entry.finallyLoc = locs[2];
      entry.afterLoc = locs[3];
    }

    this.tryEntries.push(entry);
  }

  function resetTryEntry(entry) {
    var record = entry.completion || {};
    record.type = "normal";
    delete record.arg;
    entry.completion = record;
  }

  function Context(tryLocsList) {
    // The root entry object (effectively a try statement without a catch
    // or a finally block) gives us a place to store values thrown from
    // locations where there is no enclosing try statement.
    this.tryEntries = [{ tryLoc: "root" }];
    tryLocsList.forEach(pushTryEntry, this);
    this.reset(true);
  }

  exports.keys = function(object) {
    var keys = [];
    for (var key in object) {
      keys.push(key);
    }
    keys.reverse();

    // Rather than returning an object with a next method, we keep
    // things simple and return the next function itself.
    return function next() {
      while (keys.length) {
        var key = keys.pop();
        if (key in object) {
          next.value = key;
          next.done = false;
          return next;
        }
      }

      // To avoid creating an additional object, we just hang the .value
      // and .done properties off the next function object itself. This
      // also ensures that the minifier will not anonymize the function.
      next.done = true;
      return next;
    };
  };

  function values(iterable) {
    if (iterable) {
      var iteratorMethod = iterable[iteratorSymbol];
      if (iteratorMethod) {
        return iteratorMethod.call(iterable);
      }

      if (typeof iterable.next === "function") {
        return iterable;
      }

      if (!isNaN(iterable.length)) {
        var i = -1, next = function next() {
          while (++i < iterable.length) {
            if (hasOwn.call(iterable, i)) {
              next.value = iterable[i];
              next.done = false;
              return next;
            }
          }

          next.value = undefined;
          next.done = true;

          return next;
        };

        return next.next = next;
      }
    }

    // Return an iterator with no values.
    return { next: doneResult };
  }
  exports.values = values;

  function doneResult() {
    return { value: undefined, done: true };
  }

  Context.prototype = {
    constructor: Context,

    reset: function(skipTempReset) {
      this.prev = 0;
      this.next = 0;
      // Resetting context._sent for legacy support of Babel's
      // function.sent implementation.
      this.sent = this._sent = undefined;
      this.done = false;
      this.delegate = null;

      this.method = "next";
      this.arg = undefined;

      this.tryEntries.forEach(resetTryEntry);

      if (!skipTempReset) {
        for (var name in this) {
          // Not sure about the optimal order of these conditions:
          if (name.charAt(0) === "t" &&
              hasOwn.call(this, name) &&
              !isNaN(+name.slice(1))) {
            this[name] = undefined;
          }
        }
      }
    },

    stop: function() {
      this.done = true;

      var rootEntry = this.tryEntries[0];
      var rootRecord = rootEntry.completion;
      if (rootRecord.type === "throw") {
        throw rootRecord.arg;
      }

      return this.rval;
    },

    dispatchException: function(exception) {
      if (this.done) {
        throw exception;
      }

      var context = this;
      function handle(loc, caught) {
        record.type = "throw";
        record.arg = exception;
        context.next = loc;

        if (caught) {
          // If the dispatched exception was caught by a catch block,
          // then let that catch block handle the exception normally.
          context.method = "next";
          context.arg = undefined;
        }

        return !! caught;
      }

      for (var i = this.tryEntries.length - 1; i >= 0; --i) {
        var entry = this.tryEntries[i];
        var record = entry.completion;

        if (entry.tryLoc === "root") {
          // Exception thrown outside of any try block that could handle
          // it, so set the completion value of the entire function to
          // throw the exception.
          return handle("end");
        }

        if (entry.tryLoc <= this.prev) {
          var hasCatch = hasOwn.call(entry, "catchLoc");
          var hasFinally = hasOwn.call(entry, "finallyLoc");

          if (hasCatch && hasFinally) {
            if (this.prev < entry.catchLoc) {
              return handle(entry.catchLoc, true);
            } else if (this.prev < entry.finallyLoc) {
              return handle(entry.finallyLoc);
            }

          } else if (hasCatch) {
            if (this.prev < entry.catchLoc) {
              return handle(entry.catchLoc, true);
            }

          } else if (hasFinally) {
            if (this.prev < entry.finallyLoc) {
              return handle(entry.finallyLoc);
            }

          } else {
            throw new Error("try statement without catch or finally");
          }
        }
      }
    },

    abrupt: function(type, arg) {
      for (var i = this.tryEntries.length - 1; i >= 0; --i) {
        var entry = this.tryEntries[i];
        if (entry.tryLoc <= this.prev &&
            hasOwn.call(entry, "finallyLoc") &&
            this.prev < entry.finallyLoc) {
          var finallyEntry = entry;
          break;
        }
      }

      if (finallyEntry &&
          (type === "break" ||
           type === "continue") &&
          finallyEntry.tryLoc <= arg &&
          arg <= finallyEntry.finallyLoc) {
        // Ignore the finally entry if control is not jumping to a
        // location outside the try/catch block.
        finallyEntry = null;
      }

      var record = finallyEntry ? finallyEntry.completion : {};
      record.type = type;
      record.arg = arg;

      if (finallyEntry) {
        this.method = "next";
        this.next = finallyEntry.finallyLoc;
        return ContinueSentinel;
      }

      return this.complete(record);
    },

    complete: function(record, afterLoc) {
      if (record.type === "throw") {
        throw record.arg;
      }

      if (record.type === "break" ||
          record.type === "continue") {
        this.next = record.arg;
      } else if (record.type === "return") {
        this.rval = this.arg = record.arg;
        this.method = "return";
        this.next = "end";
      } else if (record.type === "normal" && afterLoc) {
        this.next = afterLoc;
      }

      return ContinueSentinel;
    },

    finish: function(finallyLoc) {
      for (var i = this.tryEntries.length - 1; i >= 0; --i) {
        var entry = this.tryEntries[i];
        if (entry.finallyLoc === finallyLoc) {
          this.complete(entry.completion, entry.afterLoc);
          resetTryEntry(entry);
          return ContinueSentinel;
        }
      }
    },

    "catch": function(tryLoc) {
      for (var i = this.tryEntries.length - 1; i >= 0; --i) {
        var entry = this.tryEntries[i];
        if (entry.tryLoc === tryLoc) {
          var record = entry.completion;
          if (record.type === "throw") {
            var thrown = record.arg;
            resetTryEntry(entry);
          }
          return thrown;
        }
      }

      // The context.catch method must only be called with a location
      // argument that corresponds to a known catch block.
      throw new Error("illegal catch attempt");
    },

    delegateYield: function(iterable, resultName, nextLoc) {
      this.delegate = {
        iterator: values(iterable),
        resultName: resultName,
        nextLoc: nextLoc
      };

      if (this.method === "next") {
        // Deliberately forget the last sent value so that we don't
        // accidentally pass it on to the delegate.
        this.arg = undefined;
      }

      return ContinueSentinel;
    }
  };

  // Regardless of whether this script is executing as a CommonJS module
  // or not, return the runtime object so that we can declare the variable
  // regeneratorRuntime in the outer scope, which allows this module to be
  // injected easily by `bin/regenerator --include-runtime script.js`.
  return exports;

}(
  // If this script is executing as a CommonJS module, use module.exports
  // as the regeneratorRuntime namespace. Otherwise create a new empty
  // object. Either way, the resulting object will be used to initialize
  // the regeneratorRuntime variable at the top of this file.
   true ? module.exports : 0
));

try {
  regeneratorRuntime = runtime;
} catch (accidentalStrictMode) {
  // This module should not be running in strict mode, so the above
  // assignment should always work unless something is misconfigured. Just
  // in case runtime.js accidentally runs in strict mode, we can escape
  // strict mode using a global Function call. This could conceivably fail
  // if a Content Security Policy forbids using Function, but in that case
  // the proper solution is to fix the accidental strict mode problem. If
  // you've misconfigured your bundler to force strict mode and applied a
  // CSP to forbid Function, and you're not willing to fix either of those
  // problems, please detail your unique predicament in a GitHub issue.
  Function("r", "regeneratorRuntime = r")(runtime);
}


/***/ }),

/***/ "recordrtc":
/*!******************************************************************************************************!*\
  !*** external {"commonjs":"recordrtc","commonjs2":"recordrtc","amd":"recordrtc","root":"RecordRTC"} ***!
  \******************************************************************************************************/
/***/ ((module) => {

"use strict";
module.exports = __WEBPACK_EXTERNAL_MODULE_recordrtc__;

/***/ }),

/***/ "video.js":
/*!*************************************************************************************************!*\
  !*** external {"commonjs":"video.js","commonjs2":"video.js","amd":"video.js","root":"videojs"} ***!
  \*************************************************************************************************/
/***/ ((module) => {

"use strict";
module.exports = __WEBPACK_EXTERNAL_MODULE_video_js__;

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
/*!**********************************!*\
  !*** ./src/js/videojs.record.js ***!
  \**********************************/


var _interopRequireDefault = __webpack_require__(/*! @babel/runtime/helpers/interopRequireDefault */ "./node_modules/@babel/runtime/helpers/interopRequireDefault.js");

Object.defineProperty(exports, "__esModule", ({
  value: true
}));
exports.Record = void 0;

var _typeof2 = _interopRequireDefault(__webpack_require__(/*! @babel/runtime/helpers/typeof */ "./node_modules/@babel/runtime/helpers/typeof.js"));

var _classCallCheck2 = _interopRequireDefault(__webpack_require__(/*! @babel/runtime/helpers/classCallCheck */ "./node_modules/@babel/runtime/helpers/classCallCheck.js"));

var _createClass2 = _interopRequireDefault(__webpack_require__(/*! @babel/runtime/helpers/createClass */ "./node_modules/@babel/runtime/helpers/createClass.js"));

var _assertThisInitialized2 = _interopRequireDefault(__webpack_require__(/*! @babel/runtime/helpers/assertThisInitialized */ "./node_modules/@babel/runtime/helpers/assertThisInitialized.js"));

var _get2 = _interopRequireDefault(__webpack_require__(/*! @babel/runtime/helpers/get */ "./node_modules/@babel/runtime/helpers/get.js"));

var _inherits2 = _interopRequireDefault(__webpack_require__(/*! @babel/runtime/helpers/inherits */ "./node_modules/@babel/runtime/helpers/inherits.js"));

var _possibleConstructorReturn2 = _interopRequireDefault(__webpack_require__(/*! @babel/runtime/helpers/possibleConstructorReturn */ "./node_modules/@babel/runtime/helpers/possibleConstructorReturn.js"));

var _getPrototypeOf2 = _interopRequireDefault(__webpack_require__(/*! @babel/runtime/helpers/getPrototypeOf */ "./node_modules/@babel/runtime/helpers/getPrototypeOf.js"));

var _video = _interopRequireDefault(__webpack_require__(/*! video.js */ "video.js"));

var _animationDisplay = _interopRequireDefault(__webpack_require__(/*! ./controls/animation-display */ "./src/js/controls/animation-display.js"));

var _recordCanvas = _interopRequireDefault(__webpack_require__(/*! ./controls/record-canvas */ "./src/js/controls/record-canvas.js"));

var _deviceButton = _interopRequireDefault(__webpack_require__(/*! ./controls/device-button */ "./src/js/controls/device-button.js"));

var _cameraButton = _interopRequireDefault(__webpack_require__(/*! ./controls/camera-button */ "./src/js/controls/camera-button.js"));

var _recordToggle = _interopRequireDefault(__webpack_require__(/*! ./controls/record-toggle */ "./src/js/controls/record-toggle.js"));

var _recordIndicator = _interopRequireDefault(__webpack_require__(/*! ./controls/record-indicator */ "./src/js/controls/record-indicator.js"));

var _pictureInPictureToggle = _interopRequireDefault(__webpack_require__(/*! ./controls/picture-in-picture-toggle */ "./src/js/controls/picture-in-picture-toggle.js"));

var _event = _interopRequireDefault(__webpack_require__(/*! ./event */ "./src/js/event.js"));

var _hotKeys = _interopRequireDefault(__webpack_require__(/*! ./hot-keys */ "./src/js/hot-keys.js"));

var _defaults = _interopRequireDefault(__webpack_require__(/*! ./defaults */ "./src/js/defaults.js"));

var _formatTime = _interopRequireDefault(__webpack_require__(/*! ./utils/format-time */ "./src/js/utils/format-time.js"));

var _browserShim = _interopRequireDefault(__webpack_require__(/*! ./utils/browser-shim */ "./src/js/utils/browser-shim.js"));

var _compareVersion = _interopRequireDefault(__webpack_require__(/*! ./utils/compare-version */ "./src/js/utils/compare-version.js"));

var _detectBrowser = __webpack_require__(/*! ./utils/detect-browser */ "./src/js/utils/detect-browser.js");

var _engineLoader = __webpack_require__(/*! ./engine/engine-loader */ "./src/js/engine/engine-loader.js");

var _recordMode = __webpack_require__(/*! ./engine/record-mode */ "./src/js/engine/record-mode.js");

function _createSuper(Derived) { var hasNativeReflectConstruct = _isNativeReflectConstruct(); return function _createSuperInternal() { var Super = (0, _getPrototypeOf2.default)(Derived), result; if (hasNativeReflectConstruct) { var NewTarget = (0, _getPrototypeOf2.default)(this).constructor; result = Reflect.construct(Super, arguments, NewTarget); } else { result = Super.apply(this, arguments); } return (0, _possibleConstructorReturn2.default)(this, result); }; }

function _isNativeReflectConstruct() { if (typeof Reflect === "undefined" || !Reflect.construct) return false; if (Reflect.construct.sham) return false; if (typeof Proxy === "function") return true; try { Boolean.prototype.valueOf.call(Reflect.construct(Boolean, [], function () {})); return true; } catch (e) { return false; } }

var Plugin = _video.default.getPlugin('plugin');

var Player = _video.default.getComponent('Player');

var AUTO = 'auto';

var Record = function (_Plugin) {
  (0, _inherits2.default)(Record, _Plugin);

  var _super = _createSuper(Record);

  function Record(player, options) {
    var _this;

    (0, _classCallCheck2.default)(this, Record);
    _this = _super.call(this, player, options);

    Player.prototype.play = function play() {
      var retval = this.techGet_('play');

      if (retval !== undefined && typeof retval.then === 'function') {
        retval.then(null, function (e) {});
      }

      return retval;
    };

    player.addClass('vjs-record');

    _this.loadOptions();

    _this.resetState();

    if (options.formatTime && typeof options.formatTime === 'function') {
      _this.setFormatTime(options.formatTime);
    } else {
      _this.setFormatTime(function (seconds, guide) {
        return (0, _formatTime.default)(seconds, guide, _this.displayMilliseconds);
      });
    }

    var deviceIcon = 'av-perm';

    switch (_this.getRecordType()) {
      case _recordMode.IMAGE_ONLY:
      case _recordMode.VIDEO_ONLY:
      case _recordMode.ANIMATION:
        deviceIcon = 'video-perm';
        break;

      case _recordMode.AUDIO_ONLY:
        deviceIcon = 'audio-perm';
        break;

      case _recordMode.SCREEN_ONLY:
        deviceIcon = 'screen-perm';
        break;

      case _recordMode.AUDIO_SCREEN:
        deviceIcon = 'sv-perm';
        break;
    }

    _deviceButton.default.prototype.buildCSSClass = function () {
      return 'vjs-record vjs-device-button vjs-control vjs-icon-' + deviceIcon;
    };

    player.deviceButton = new _deviceButton.default(player, options);
    player.addChild(player.deviceButton);
    player.recordIndicator = new _recordIndicator.default(player, options);
    player.recordIndicator.hide();
    player.addChild(player.recordIndicator);
    player.recordCanvas = new _recordCanvas.default(player, options);
    player.recordCanvas.hide();
    player.addChild(player.recordCanvas);
    player.animationDisplay = new _animationDisplay.default(player, options);
    player.animationDisplay.hide();
    player.addChild(player.animationDisplay);
    player.cameraButton = new _cameraButton.default(player, options);
    player.cameraButton.hide();
    player.recordToggle = new _recordToggle.default(player, options);
    player.recordToggle.hide();
    var oldVideoJS = _video.default.VERSION === undefined || (0, _compareVersion.default)(_video.default.VERSION, '7.6.0') === -1;

    if (!('pictureInPictureEnabled' in document)) {
      _this.pictureInPicture = false;
    }

    if (_this.pictureInPicture === true) {
      if (oldVideoJS) {
        player.pipToggle = new _pictureInPictureToggle.default(player, options);
        player.pipToggle.hide();
      }

      _this.onEnterPiPHandler = _this.onEnterPiP.bind((0, _assertThisInitialized2.default)(_this));
      _this.onLeavePiPHandler = _this.onLeavePiP.bind((0, _assertThisInitialized2.default)(_this));
    }

    if (_this.player.options_.controlBar) {
      var customUIElements = ['deviceButton', 'recordIndicator', 'cameraButton', 'recordToggle'];

      if (player.pipToggle) {
        customUIElements.push('pipToggle');
      }

      customUIElements.forEach(function (element) {
        if (_this.player.options_.controlBar[element] !== undefined) {
          _this.player[element].layoutExclude = true;

          _this.player[element].hide();
        }
      });
    }

    _this.player.one(_event.default.READY, _this.setupUI.bind((0, _assertThisInitialized2.default)(_this)));

    return _this;
  }

  (0, _createClass2.default)(Record, [{
    key: "loadOptions",
    value: function loadOptions() {
      var newOptions = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : {};

      var recordOptions = _video.default.mergeOptions(_defaults.default, this.player.options_.plugins.record, newOptions);

      this.recordImage = recordOptions.image;
      this.recordAudio = recordOptions.audio;
      this.recordVideo = recordOptions.video;
      this.recordAnimation = recordOptions.animation;
      this.recordScreen = recordOptions.screen;
      this.maxLength = recordOptions.maxLength;
      this.maxFileSize = recordOptions.maxFileSize;
      this.displayMilliseconds = recordOptions.displayMilliseconds;
      this.debug = recordOptions.debug;
      this.pictureInPicture = recordOptions.pip;
      this.recordTimeSlice = recordOptions.timeSlice;
      this.autoMuteDevice = recordOptions.autoMuteDevice;
      this.pluginLibraryOptions = recordOptions.pluginLibraryOptions;
      this.videoFrameWidth = recordOptions.frameWidth;
      this.videoFrameHeight = recordOptions.frameHeight;
      this.videoFrameRate = recordOptions.videoFrameRate;
      this.videoBitRate = recordOptions.videoBitRate;
      this.videoEngine = recordOptions.videoEngine;
      this.videoRecorderType = recordOptions.videoRecorderType;
      this.videoMimeType = recordOptions.videoMimeType;
      this.videoWorkerURL = recordOptions.videoWorkerURL;
      this.videoWebAssemblyURL = recordOptions.videoWebAssemblyURL;
      this.convertEngine = recordOptions.convertEngine;
      this.convertAuto = recordOptions.convertAuto;
      this.convertWorkerURL = recordOptions.convertWorkerURL;
      this.convertOptions = recordOptions.convertOptions;
      this.audioEngine = recordOptions.audioEngine;
      this.audioRecorderType = recordOptions.audioRecorderType;
      this.audioWorkerURL = recordOptions.audioWorkerURL;
      this.audioWebAssemblyURL = recordOptions.audioWebAssemblyURL;
      this.audioBufferSize = recordOptions.audioBufferSize;
      this.audioSampleRate = recordOptions.audioSampleRate;
      this.audioBitRate = recordOptions.audioBitRate;
      this.audioChannels = recordOptions.audioChannels;
      this.audioMimeType = recordOptions.audioMimeType;
      this.audioBufferUpdate = recordOptions.audioBufferUpdate;
      this.imageOutputType = recordOptions.imageOutputType;
      this.imageOutputFormat = recordOptions.imageOutputFormat;
      this.imageOutputQuality = recordOptions.imageOutputQuality;
      this.animationFrameRate = recordOptions.animationFrameRate;
      this.animationQuality = recordOptions.animationQuality;
    }
  }, {
    key: "setupUI",
    value: function setupUI() {
      var _this2 = this;

      this.player.controlBar.addChild(this.player.cameraButton);
      this.player.controlBar.el().insertBefore(this.player.cameraButton.el(), this.player.controlBar.el().firstChild);
      this.player.controlBar.el().insertBefore(this.player.recordToggle.el(), this.player.controlBar.el().firstChild);

      if (this.pictureInPicture === true) {
        if (this.player.controlBar.pictureInPictureToggle === undefined && this.player.pipToggle !== undefined) {
          this.player.controlBar.addChild(this.player.pipToggle);
        } else if (this.player.controlBar.pictureInPictureToggle !== undefined) {
          this.player.pipToggle = this.player.controlBar.pictureInPictureToggle;
          this.player.pipToggle.hide();
        }
      } else if (this.pictureInPicture === false && this.player.controlBar.pictureInPictureToggle !== undefined) {
        this.player.controlBar.pictureInPictureToggle.hide();
      }

      if (this.player.controlBar.remainingTimeDisplay !== undefined) {
        this.player.controlBar.remainingTimeDisplay.el().style.display = 'none';
      }

      if (this.player.controlBar.liveDisplay !== undefined) {
        this.player.controlBar.liveDisplay.el().style.display = 'none';
      }

      this.player.loop(false);

      switch (this.getRecordType()) {
        case _recordMode.AUDIO_ONLY:
          this.surfer = this.player.wavesurfer();
          this.surfer.setFormatTime(this._formatTime);
          break;

        case _recordMode.IMAGE_ONLY:
        case _recordMode.VIDEO_ONLY:
        case _recordMode.AUDIO_VIDEO:
        case _recordMode.ANIMATION:
        case _recordMode.SCREEN_ONLY:
        case _recordMode.AUDIO_SCREEN:
          if (this.player.bigPlayButton !== undefined) {
            this.player.bigPlayButton.hide();
          }

          this.player.one(_event.default.LOADEDMETADATA, function () {
            _this2.setDuration(_this2.maxLength);
          });
          this.player.one(_event.default.LOADSTART, function () {
            _this2.setDuration(_this2.maxLength);
          });

          if (this.player.usingNativeControls_ === true) {
            if (this.player.tech_.el_ !== undefined) {
              this.player.tech_.el_.controls = false;
            }
          }

          this.player.removeTechControlsListeners_();

          if (this.player.options_.controls) {
            if (this.player.controlBar.progressControl !== undefined) {
              this.player.controlBar.progressControl.hide();
            }

            this.player.on(_event.default.USERINACTIVE, function (event) {
              _this2.player.userActive(true);
            });
            this.player.controlBar.show();
            this.player.controlBar.el().style.display = 'flex';
          }

          break;
      }

      this.player.off(_event.default.TIMEUPDATE);
      this.player.off(_event.default.DURATIONCHANGE);
      this.player.off(_event.default.LOADEDMETADATA);
      this.player.off(_event.default.LOADSTART);
      this.player.off(_event.default.ENDED);
      this.setDuration(this.maxLength);

      if (this.player.options_.plugins.record && this.player.options_.plugins.record.hotKeys && this.player.options_.plugins.record.hotKeys !== false) {
        var handler = this.player.options_.plugins.record.hotKeys;

        if (handler === true) {
          handler = _hotKeys.default;
        }

        this.player.options_.userActions = {
          hotkeys: handler
        };
      }

      if (this.player.controlBar.playToggle !== undefined) {
        this.player.controlBar.playToggle.hide();
      }
    }
  }, {
    key: "isRecording",
    value: function isRecording() {
      return this._recording;
    }
  }, {
    key: "isProcessing",
    value: function isProcessing() {
      return this._processing;
    }
  }, {
    key: "isDestroyed",
    value: function isDestroyed() {
      var destroyed = this.player === null;

      if (destroyed === false) {
        destroyed = this.player.children() === null;
      }

      return destroyed;
    }
  }, {
    key: "getDevice",
    value: function getDevice() {
      var _this3 = this;

      if (this.deviceReadyCallback === undefined) {
        this.deviceReadyCallback = this.onDeviceReady.bind(this);
      }

      if (this.deviceErrorCallback === undefined) {
        this.deviceErrorCallback = this.onDeviceError.bind(this);
      }

      if (this.engineStopCallback === undefined) {
        this.engineStopCallback = this.onRecordComplete.bind(this);
      }

      if (this.streamVisibleCallback === undefined) {
        this.streamVisibleCallback = this.onStreamVisible.bind(this);
      }

      if (this.getRecordType() === _recordMode.SCREEN_ONLY || this.getRecordType() === _recordMode.AUDIO_SCREEN) {
        if (navigator.mediaDevices === undefined || navigator.mediaDevices.getDisplayMedia === undefined) {
          this.player.trigger(_event.default.ERROR, 'This browser does not support navigator.mediaDevices.getDisplayMedia');
          return;
        }
      } else {
        if (navigator.mediaDevices === undefined || navigator.mediaDevices.getUserMedia === undefined) {
          this.player.trigger(_event.default.ERROR, 'This browser does not support navigator.mediaDevices.getUserMedia');
          return;
        }
      }

      switch (this.getRecordType()) {
        case _recordMode.AUDIO_ONLY:
          this.mediaType = {
            audio: this.audioRecorderType === AUTO ? true : this.audioRecorderType,
            video: false
          };
          this.surfer.surfer.microphone.un(_event.default.DEVICE_READY, this.deviceReadyCallback);
          this.surfer.surfer.microphone.un(_event.default.DEVICE_ERROR, this.deviceErrorCallback);
          this.surfer.surfer.microphone.on(_event.default.DEVICE_READY, this.deviceReadyCallback);
          this.surfer.surfer.microphone.on(_event.default.DEVICE_ERROR, this.deviceErrorCallback);
          this.surfer.setupPlaybackEvents(false);
          this.surfer.liveMode = true;
          this.surfer.surfer.microphone.paused = false;

          if (this.surfer.surfer.backend.ac.state === 'suspended') {
            this.surfer.surfer.backend.ac.resume();
          }

          if (this.audioBufferUpdate === true) {
            this.surfer.surfer.microphone.reloadBufferFunction = function (event) {
              if (!_this3.surfer.surfer.microphone.paused) {
                _this3.surfer.surfer.empty();

                _this3.surfer.surfer.loadDecodedBuffer(event.inputBuffer);

                _this3.player.recordedData = event.inputBuffer;

                _this3.player.trigger(_event.default.AUDIO_BUFFER_UPDATE);
              }
            };
          }

          this.surfer.surfer.microphone.start();
          break;

        case _recordMode.IMAGE_ONLY:
        case _recordMode.VIDEO_ONLY:
          if (this.getRecordType() === _recordMode.IMAGE_ONLY) {
            this.player.el().firstChild.addEventListener(_event.default.PLAYING, this.streamVisibleCallback);
          }

          this.mediaType = {
            audio: false,
            video: this.videoRecorderType === AUTO ? true : this.videoRecorderType
          };
          navigator.mediaDevices.getUserMedia({
            audio: false,
            video: this.getRecordType() === _recordMode.IMAGE_ONLY ? this.recordImage : this.recordVideo
          }).then(this.onDeviceReady.bind(this)).catch(this.onDeviceError.bind(this));
          break;

        case _recordMode.AUDIO_SCREEN:
          this.mediaType = {
            audio: this.audioRecorderType === AUTO ? true : this.audioRecorderType,
            video: this.videoRecorderType === AUTO ? true : this.videoRecorderType
          };
          var audioScreenConstraints = {};

          if (this.recordScreen === true) {
            audioScreenConstraints = {
              video: true
            };
          } else if ((0, _typeof2.default)(this.recordScreen) === 'object' && this.recordScreen.constructor === Object) {
            audioScreenConstraints = this.recordScreen;
          }

          navigator.mediaDevices.getDisplayMedia(audioScreenConstraints).then(function (screenStream) {
            navigator.mediaDevices.getUserMedia({
              audio: _this3.recordAudio
            }).then(function (mic) {
              screenStream.addTrack(mic.getTracks()[0]);

              _this3.onDeviceReady.bind(_this3)(screenStream);
            }).catch(function (code) {
              if (screenStream.active) {
                screenStream.stop();
              }

              _this3.onDeviceError(code);
            });
          }).catch(this.onDeviceError.bind(this));
          break;

        case _recordMode.AUDIO_VIDEO:
          this.mediaType = {
            audio: this.audioRecorderType === AUTO ? true : this.audioRecorderType,
            video: this.videoRecorderType === AUTO ? true : this.videoRecorderType
          };
          navigator.mediaDevices.getUserMedia({
            audio: this.recordAudio,
            video: this.recordVideo
          }).then(this.onDeviceReady.bind(this)).catch(this.onDeviceError.bind(this));
          break;

        case _recordMode.ANIMATION:
          this.mediaType = {
            audio: false,
            video: false,
            gif: true
          };
          navigator.mediaDevices.getUserMedia({
            audio: false,
            video: this.recordAnimation
          }).then(this.onDeviceReady.bind(this)).catch(this.onDeviceError.bind(this));
          break;

        case _recordMode.SCREEN_ONLY:
          this.mediaType = {
            audio: false,
            video: false,
            screen: true,
            gif: false
          };
          var screenOnlyConstraints = {};

          if (this.recordScreen === true) {
            screenOnlyConstraints = {
              video: true
            };
          } else if ((0, _typeof2.default)(this.recordScreen) === 'object' && this.recordScreen.constructor === Object) {
            screenOnlyConstraints = this.recordScreen;
          }

          navigator.mediaDevices.getDisplayMedia(screenOnlyConstraints).then(this.onDeviceReady.bind(this)).catch(this.onDeviceError.bind(this));
          break;
      }
    }
  }, {
    key: "onDeviceReady",
    value: function onDeviceReady(stream) {
      var _this4 = this;

      this._deviceActive = true;

      if (this.stream !== undefined && this.stream.active) {
        this.stream.stop();
      }

      this.stream = stream;
      this.player.deviceButton.hide();
      this.setDuration(this.maxLength);
      this.setCurrentTime(0);

      if (this.player.controlBar.playToggle !== undefined) {
        this.player.controlBar.playToggle.hide();
      }

      this.off(this.player, _event.default.TIMEUPDATE, this.playbackTimeUpdate);
      this.off(this.player, _event.default.ENDED, this.playbackTimeUpdate);

      if (this.getRecordType() !== _recordMode.IMAGE_ONLY) {
        if (this.getRecordType() !== _recordMode.AUDIO_ONLY && (0, _engineLoader.isAudioPluginActive)(this.audioEngine)) {
          throw new Error('Currently ' + this.audioEngine + ' is only supported in audio-only mode.');
        }

        var EngineClass, engineType;

        switch (this.getRecordType()) {
          case _recordMode.AUDIO_ONLY:
            EngineClass = (0, _engineLoader.getAudioEngine)(this.audioEngine);
            engineType = this.audioEngine;
            break;

          default:
            EngineClass = (0, _engineLoader.getVideoEngine)(this.videoEngine);
            engineType = this.videoEngine;
        }

        try {
          this.engine = new EngineClass(this.player, this.player.options_);
        } catch (err) {
          throw new Error('Could not load ' + engineType + ' plugin');
        }

        this.engine.on(_event.default.RECORD_COMPLETE, this.engineStopCallback);
        this.engine.bufferSize = this.audioBufferSize;
        this.engine.sampleRate = this.audioSampleRate;
        this.engine.bitRate = this.audioBitRate;
        this.engine.audioChannels = this.audioChannels;
        this.engine.audioWorkerURL = this.audioWorkerURL;
        this.engine.audioWebAssemblyURL = this.audioWebAssemblyURL;
        this.engine.mimeType = {
          video: this.videoMimeType,
          gif: 'image/gif'
        };

        if (this.audioMimeType !== null && this.audioMimeType !== AUTO) {
          this.engine.mimeType.audio = this.audioMimeType;
        }

        this.engine.videoWorkerURL = this.videoWorkerURL;
        this.engine.videoWebAssemblyURL = this.videoWebAssemblyURL;
        this.engine.videoBitRate = this.videoBitRate;
        this.engine.videoFrameRate = this.videoFrameRate;
        this.engine.video = {
          width: this.videoFrameWidth,
          height: this.videoFrameHeight
        };
        this.engine.canvas = {
          width: this.videoFrameWidth,
          height: this.videoFrameHeight
        };
        this.engine.quality = this.animationQuality;
        this.engine.frameRate = this.animationFrameRate;

        if (this.recordTimeSlice && this.recordTimeSlice > 0) {
          this.engine.timeSlice = this.recordTimeSlice;
          this.engine.maxFileSize = this.maxFileSize;
        }

        this.engine.pluginLibraryOptions = this.pluginLibraryOptions;
        this.engine.setup(this.stream, this.mediaType, this.debug);

        if (this.convertEngine !== '') {
          var ConvertEngineClass = (0, _engineLoader.getConvertEngine)(this.convertEngine);

          try {
            this.converter = new ConvertEngineClass(this.player, this.player.options_);
          } catch (err) {
            throw new Error('Could not load ' + this.convertEngine + ' plugin');
          }

          this.converter.convertAuto = this.convertAuto;
          this.converter.convertWorkerURL = this.convertWorkerURL;
          this.converter.convertOptions = this.convertOptions;
          this.converter.pluginLibraryOptions = this.pluginLibraryOptions;
          this.converter.setup(this.mediaType, this.debug);
        }

        var uiElements = ['currentTimeDisplay', 'timeDivider', 'durationDisplay'];
        uiElements.forEach(function (element) {
          element = _this4.player.controlBar[element];

          if (element !== undefined) {
            element.el().style.display = 'block';
            element.show();
          }
        });
        this.player.recordToggle.show();
      } else {
        this.player.recordIndicator.disable();
        this.retrySnapshot();
      }

      if (this.getRecordType() !== _recordMode.AUDIO_ONLY) {
        this.mediaElement = this.player.el().firstChild;
        this.mediaElement.controls = false;
        this.mediaElement.muted = true;
        this.displayVolumeControl(false);

        if (this.pictureInPicture === true) {
          this.player.pipToggle.show();
          this.mediaElement.removeEventListener(_event.default.ENTERPICTUREINPICTURE, this.onEnterPiPHandler);
          this.mediaElement.removeEventListener(_event.default.LEAVEPICTUREINPICTURE, this.onLeavePiPHandler);
          this.mediaElement.addEventListener(_event.default.ENTERPICTUREINPICTURE, this.onEnterPiPHandler);
          this.mediaElement.addEventListener(_event.default.LEAVEPICTUREINPICTURE, this.onLeavePiPHandler);
        }

        this.load(this.stream);
        this.player.one(_event.default.LOADEDMETADATA, function () {
          _this4.mediaElement.play();

          _this4.player.trigger(_event.default.DEVICE_READY);
        });
      } else {
        this.player.trigger(_event.default.DEVICE_READY);
      }
    }
  }, {
    key: "onDeviceError",
    value: function onDeviceError(code) {
      this._deviceActive = false;

      if (!this.isDestroyed()) {
        this.player.deviceErrorCode = code;
        this.player.trigger(_event.default.DEVICE_ERROR);
      }
    }
  }, {
    key: "start",
    value: function start() {
      var _this5 = this;

      if (!this.isProcessing()) {
        if (this.stream && this.stream.active === false) {
          this.getDevice();
          return;
        }

        this._recording = true;

        if (this.player.controlBar.playToggle !== undefined) {
          this.player.controlBar.playToggle.hide();
        }

        this.off(this.player, _event.default.TIMEUPDATE, this.playbackTimeUpdate);
        this.off(this.player, _event.default.ENDED, this.playbackTimeUpdate);

        switch (this.getRecordType()) {
          case _recordMode.AUDIO_ONLY:
            this.surfer.setupPlaybackEvents(false);
            this.surfer.surfer.microphone.paused = false;
            this.surfer.liveMode = true;
            this.surfer.surfer.microphone.play();
            break;

          case _recordMode.VIDEO_ONLY:
          case _recordMode.AUDIO_VIDEO:
          case _recordMode.AUDIO_SCREEN:
          case _recordMode.SCREEN_ONLY:
            this.startVideoPreview();
            break;

          case _recordMode.ANIMATION:
            this.player.recordCanvas.hide();
            this.player.animationDisplay.hide();
            this.mediaElement.style.display = 'block';
            this.captureFrame().then(function (result) {
              _this5.startVideoPreview();
            });
            break;
        }

        if (this.autoMuteDevice) {
          this.muteTracks(false);
        }

        switch (this.getRecordType()) {
          case _recordMode.IMAGE_ONLY:
            this.createSnapshot();
            this.player.trigger(_event.default.START_RECORD);
            break;

          case _recordMode.VIDEO_ONLY:
          case _recordMode.AUDIO_VIDEO:
          case _recordMode.AUDIO_SCREEN:
          case _recordMode.ANIMATION:
          case _recordMode.SCREEN_ONLY:
            this.player.one(_event.default.LOADEDMETADATA, function () {
              _this5.startRecording();
            });
            break;

          default:
            this.startRecording();
        }
      }
    }
  }, {
    key: "startRecording",
    value: function startRecording() {
      this.paused = false;
      this.pauseTime = this.pausedTime = 0;
      this.startTime = performance.now();
      var COUNTDOWN_SPEED = 100;
      this.countDown = this.player.setInterval(this.onCountDown.bind(this), COUNTDOWN_SPEED);

      if (this.engine !== undefined) {
        this.engine.dispose();
      }

      this.engine.start();
      this.player.trigger(_event.default.START_RECORD);
    }
  }, {
    key: "stop",
    value: function stop() {
      if (!this.isProcessing()) {
        this._recording = false;
        this._processing = true;

        if (this.getRecordType() !== _recordMode.IMAGE_ONLY) {
          this.player.trigger(_event.default.STOP_RECORD);
          this.player.clearInterval(this.countDown);

          if (this.engine) {
            this.engine.stop();
          }

          if (this.autoMuteDevice) {
            this.muteTracks(true);
          }
        } else {
          if (this.player.recordedData) {
            this.player.trigger(_event.default.FINISH_RECORD);
          }
        }
      }
    }
  }, {
    key: "stopDevice",
    value: function stopDevice() {
      if (this.isRecording()) {
        this.player.one(_event.default.FINISH_RECORD, this.stopStream.bind(this));
        this.stop();
      } else {
        this.stopStream();
      }
    }
  }, {
    key: "stopStream",
    value: function stopStream() {
      if (this.stream) {
        this._deviceActive = false;

        if (this.getRecordType() === _recordMode.AUDIO_ONLY) {
          this.surfer.surfer.microphone.stopDevice();
          return;
        }

        this.stream.getTracks().forEach(function (stream) {
          stream.stop();
        });
      }
    }
  }, {
    key: "pause",
    value: function pause() {
      if (!this.paused) {
        this.pauseTime = performance.now();
        this.paused = true;
        this.engine.pause();
      }
    }
  }, {
    key: "resume",
    value: function resume() {
      if (this.paused) {
        this.pausedTime += performance.now() - this.pauseTime;
        this.engine.resume();
        this.paused = false;
      }
    }
  }, {
    key: "onRecordComplete",
    value: function onRecordComplete() {
      var _this6 = this;

      this.player.recordedData = this.engine.recordedData;

      if (this.player.controlBar.playToggle !== undefined) {
        this.player.controlBar.playToggle.removeClass('vjs-ended');
        this.player.controlBar.playToggle.show();
      }

      if (this.convertAuto === true) {
        this.convert();
      }

      this.player.trigger(_event.default.FINISH_RECORD);

      if (this.isDestroyed()) {
        return;
      }

      switch (this.getRecordType()) {
        case _recordMode.AUDIO_ONLY:
          this.surfer.pause();
          this.surfer.setupPlaybackEvents(true);
          this.player.loadingSpinner.show();
          this.surfer.surfer.once(_event.default.READY, function () {
            _this6._processing = false;
          });
          this.load(this.player.recordedData);
          break;

        case _recordMode.VIDEO_ONLY:
        case _recordMode.AUDIO_VIDEO:
        case _recordMode.AUDIO_SCREEN:
        case _recordMode.SCREEN_ONLY:
          this.player.one(_event.default.PAUSE, function () {
            _this6._processing = false;

            _this6.player.loadingSpinner.hide();

            _this6.setDuration(_this6.streamDuration);

            _this6.on(_this6.player, _event.default.TIMEUPDATE, _this6.playbackTimeUpdate);

            _this6.on(_this6.player, _event.default.ENDED, _this6.playbackTimeUpdate);

            if (_this6.getRecordType() === _recordMode.AUDIO_VIDEO || _this6.getRecordType() === _recordMode.AUDIO_SCREEN) {
              _this6.mediaElement.muted = false;

              _this6.displayVolumeControl(true);
            }

            _this6.load(_this6.player.recordedData);
          });
          this.player.pause();
          break;

        case _recordMode.ANIMATION:
          this._processing = false;
          this.player.loadingSpinner.hide();
          this.setDuration(this.streamDuration);
          this.mediaElement.style.display = 'none';
          this.player.recordCanvas.show();
          this.player.pause();
          this.on(this.player, _event.default.PLAY, this.showAnimation);
          this.on(this.player, _event.default.PAUSE, this.hideAnimation);
          break;
      }
    }
  }, {
    key: "onCountDown",
    value: function onCountDown() {
      if (!this.paused) {
        var now = performance.now();
        var duration = this.maxLength;
        var currentTime = (now - (this.startTime + this.pausedTime)) / 1000;
        this.streamDuration = currentTime;

        if (currentTime >= duration) {
          currentTime = duration;
          this.stop();
        }

        this.setDuration(duration);
        this.setCurrentTime(currentTime, duration);
        this.player.trigger(_event.default.PROGRESS_RECORD);
      }
    }
  }, {
    key: "getCurrentTime",
    value: function getCurrentTime() {
      var currentTime = isNaN(this.streamCurrentTime) ? 0 : this.streamCurrentTime;

      if (this.getRecordType() === _recordMode.AUDIO_ONLY) {
        currentTime = this.surfer.getCurrentTime();
      }

      return currentTime;
    }
  }, {
    key: "setCurrentTime",
    value: function setCurrentTime(currentTime, duration) {
      currentTime = isNaN(currentTime) ? 0 : currentTime;
      duration = isNaN(duration) ? 0 : duration;

      switch (this.getRecordType()) {
        case _recordMode.AUDIO_ONLY:
          this.surfer.setCurrentTime(currentTime, duration);
          break;

        case _recordMode.VIDEO_ONLY:
        case _recordMode.AUDIO_VIDEO:
        case _recordMode.AUDIO_SCREEN:
        case _recordMode.ANIMATION:
        case _recordMode.SCREEN_ONLY:
          if (this.player.controlBar.currentTimeDisplay && this.player.controlBar.currentTimeDisplay.contentEl() && this.player.controlBar.currentTimeDisplay.contentEl().lastChild) {
            this.streamCurrentTime = Math.min(currentTime, duration);
            this.player.controlBar.currentTimeDisplay.formattedTime_ = this.player.controlBar.currentTimeDisplay.contentEl().lastChild.textContent = this._formatTime(this.streamCurrentTime, duration, this.displayMilliseconds);
          }

          break;
      }
    }
  }, {
    key: "getDuration",
    value: function getDuration() {
      var duration = isNaN(this.streamDuration) ? 0 : this.streamDuration;
      return duration;
    }
  }, {
    key: "setDuration",
    value: function setDuration(duration) {
      duration = isNaN(duration) ? 0 : duration;

      switch (this.getRecordType()) {
        case _recordMode.AUDIO_ONLY:
          this.surfer.setDuration(duration);
          break;

        case _recordMode.VIDEO_ONLY:
        case _recordMode.AUDIO_VIDEO:
        case _recordMode.AUDIO_SCREEN:
        case _recordMode.ANIMATION:
        case _recordMode.SCREEN_ONLY:
          if (this.player.controlBar.durationDisplay && this.player.controlBar.durationDisplay.contentEl() && this.player.controlBar.durationDisplay.contentEl().lastChild) {
            this.player.controlBar.durationDisplay.formattedTime_ = this.player.controlBar.durationDisplay.contentEl().lastChild.textContent = this._formatTime(duration, duration, this.displayMilliseconds);
          }

          break;
      }
    }
  }, {
    key: "load",
    value: function load(url) {
      switch (this.getRecordType()) {
        case _recordMode.AUDIO_ONLY:
          this.surfer.load(url);
          break;

        case _recordMode.IMAGE_ONLY:
        case _recordMode.VIDEO_ONLY:
        case _recordMode.AUDIO_VIDEO:
        case _recordMode.AUDIO_SCREEN:
        case _recordMode.ANIMATION:
        case _recordMode.SCREEN_ONLY:
          if (url instanceof Blob || url instanceof File) {
            this.mediaElement.srcObject = null;
            this.mediaElement.src = URL.createObjectURL(url);
          } else {
            (0, _browserShim.default)(url, this.mediaElement);
          }

          break;
      }
    }
  }, {
    key: "saveAs",
    value: function saveAs(name) {
      var type = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : 'record';

      if (type === 'record') {
        if (this.engine && name !== undefined) {
          this.engine.saveAs(name);
        }
      } else if (type === 'convert') {
        if (this.converter && name !== undefined) {
          this.converter.saveAs(name);
        }
      }
    }
  }, {
    key: "dispose",
    value: function dispose() {
      this.player.off(_event.default.READY);
      this.player.off(_event.default.USERINACTIVE);
      this.player.off(_event.default.LOADEDMETADATA);

      if (this.engine) {
        this.engine.dispose();
        this.engine.destroy();
        this.engine.off(_event.default.RECORD_COMPLETE, this.engineStopCallback);
      }

      this.stop();
      this.stopDevice();
      this.removeRecording();
      this.player.clearInterval(this.countDown);

      if (this.getRecordType() === _recordMode.AUDIO_ONLY) {
        if (this.surfer) {
          this.surfer.destroy();
        }
      } else if (this.getRecordType() === _recordMode.IMAGE_ONLY) {
        if (this.mediaElement && this.streamVisibleCallback) {
          this.mediaElement.removeEventListener(_event.default.PLAYING, this.streamVisibleCallback);
        }
      }

      this.resetState();
      (0, _get2.default)((0, _getPrototypeOf2.default)(Record.prototype), "dispose", this).call(this);
    }
  }, {
    key: "destroy",
    value: function destroy() {
      this.player.dispose();
    }
  }, {
    key: "reset",
    value: function reset() {
      var _this7 = this;

      if (this.engine) {
        this.engine.dispose();
        this.engine.off(_event.default.RECORD_COMPLETE, this.engineStopCallback);
      }

      this.stop();
      this.stopDevice();
      this.player.clearInterval(this.countDown);
      this.removeRecording();
      this.loadOptions();
      this.resetState();
      this.setDuration(this.maxLength);
      this.setCurrentTime(0);
      this.player.reset();

      switch (this.getRecordType()) {
        case _recordMode.AUDIO_ONLY:
          if (this.surfer && this.surfer.surfer) {
            this.surfer.surfer.empty();
          }

          break;

        case _recordMode.IMAGE_ONLY:
        case _recordMode.ANIMATION:
          this.player.recordCanvas.hide();
          this.player.cameraButton.hide();
          break;
      }

      if (this.player.controlBar.playToggle !== undefined) {
        this.player.controlBar.playToggle.hide();
      }

      this.player.deviceButton.show();
      this.player.recordToggle.hide();
      this.player.one(_event.default.LOADEDMETADATA, function () {
        _this7.setDuration(_this7.maxLength);
      });
    }
  }, {
    key: "resetState",
    value: function resetState() {
      this._recording = false;
      this._processing = false;
      this._deviceActive = false;
      this.devices = [];
    }
  }, {
    key: "removeRecording",
    value: function removeRecording() {
      if (this.mediaElement && this.mediaElement.src && this.mediaElement.src.startsWith('blob:') === true) {
        URL.revokeObjectURL(this.mediaElement.src);
        this.mediaElement.src = '';
      }
    }
  }, {
    key: "exportImage",
    value: function exportImage() {
      var format = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : 'image/png';
      var quality = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : 1;

      if (this.getRecordType() === _recordMode.AUDIO_ONLY) {
        return this.surfer.surfer.exportImage(format, quality, 'blob');
      } else {
        var recordCanvas = this.player.recordCanvas.el().firstChild;
        this.drawCanvas(recordCanvas, this.mediaElement);
        return new Promise(function (resolve) {
          recordCanvas.toBlob(resolve, format, quality);
        });
      }
    }
  }, {
    key: "muteTracks",
    value: function muteTracks(mute) {
      if ((this.getRecordType() === _recordMode.AUDIO_ONLY || this.getRecordType() === _recordMode.AUDIO_SCREEN || this.getRecordType() === _recordMode.AUDIO_VIDEO) && this.stream.getAudioTracks().length > 0) {
        this.stream.getAudioTracks()[0].enabled = !mute;
      }

      if (this.getRecordType() !== _recordMode.AUDIO_ONLY && this.stream.getVideoTracks().length > 0) {
        this.stream.getVideoTracks()[0].enabled = !mute;
      }
    }
  }, {
    key: "getRecordType",
    value: function getRecordType() {
      return (0, _recordMode.getRecorderMode)(this.recordImage, this.recordAudio, this.recordVideo, this.recordAnimation, this.recordScreen);
    }
  }, {
    key: "convert",
    value: function convert() {
      if (this.converter !== undefined) {
        this.converter.convert(this.player.recordedData);
      }
    }
  }, {
    key: "createSnapshot",
    value: function createSnapshot() {
      var _this8 = this;

      this.captureFrame().then(function (result) {
        if (_this8.imageOutputType === 'blob') {
          result.toBlob(function (blob) {
            _this8.player.recordedData = blob;

            _this8.displaySnapshot();
          });
        } else if (_this8.imageOutputType === 'dataURL') {
          _this8.player.recordedData = result.toDataURL(_this8.imageOutputFormat, _this8.imageOutputQuality);

          _this8.displaySnapshot();
        }
      }, this.imageOutputFormat, this.imageOutputQuality);
    }
  }, {
    key: "displaySnapshot",
    value: function displaySnapshot() {
      this.mediaElement.style.display = 'none';
      this.player.recordCanvas.show();
      this.stop();
    }
  }, {
    key: "retrySnapshot",
    value: function retrySnapshot() {
      this._processing = false;
      this.player.recordCanvas.hide();
      this.player.el().firstChild.style.display = 'block';
    }
  }, {
    key: "captureFrame",
    value: function captureFrame() {
      var _this9 = this;

      var detected = (0, _detectBrowser.detectBrowser)();
      var recordCanvas = this.player.recordCanvas.el().firstChild;
      var track = this.stream.getVideoTracks()[0];
      var settings = track.getSettings();
      recordCanvas.width = settings.width;
      recordCanvas.height = settings.height;
      return new Promise(function (resolve, reject) {
        var cameraAspectRatio = settings.width / settings.height;

        var playerAspectRatio = _this9.player.width() / _this9.player.height();

        var imagePreviewHeight = 0;
        var imagePreviewWidth = 0;
        var imageXPosition = 0;
        var imageYPosition = 0;

        if (cameraAspectRatio >= playerAspectRatio) {
          imagePreviewHeight = settings.height * (_this9.player.width() / settings.width);
          imagePreviewWidth = _this9.player.width();
          imageYPosition = _this9.player.height() / 2 - imagePreviewHeight / 2;
        } else {
          imagePreviewHeight = _this9.player.height();
          imagePreviewWidth = settings.width * (_this9.player.height() / settings.height);
          imageXPosition = _this9.player.width() / 2 - imagePreviewWidth / 2;
        }

        if (detected.browser === 'chrome' && detected.version >= 60 && (typeof ImageCapture === "undefined" ? "undefined" : (0, _typeof2.default)(ImageCapture)) === (typeof Function === "undefined" ? "undefined" : (0, _typeof2.default)(Function))) {
          try {
            var imageCapture = new ImageCapture(track);
            imageCapture.grabFrame().then(function (imageBitmap) {
              _this9.drawCanvas(recordCanvas, imageBitmap, imagePreviewWidth, imagePreviewHeight, imageXPosition, imageYPosition);

              resolve(recordCanvas);
            }).catch(function (error) {});
          } catch (err) {}
        }

        _this9.drawCanvas(recordCanvas, _this9.mediaElement, imagePreviewWidth, imagePreviewHeight, imageXPosition, imageYPosition);

        resolve(recordCanvas);
      });
    }
  }, {
    key: "drawCanvas",
    value: function drawCanvas(canvas, element, width, height) {
      var x = arguments.length > 4 && arguments[4] !== undefined ? arguments[4] : 0;
      var y = arguments.length > 5 && arguments[5] !== undefined ? arguments[5] : 0;

      if (width === undefined) {
        width = canvas.width;
      }

      if (height === undefined) {
        height = canvas.height;
      }

      canvas.getContext('2d').drawImage(element, x, y, width, height);
    }
  }, {
    key: "startVideoPreview",
    value: function startVideoPreview() {
      this.off(_event.default.TIMEUPDATE);
      this.off(_event.default.DURATIONCHANGE);
      this.off(_event.default.LOADEDMETADATA);
      this.off(_event.default.PLAY);
      this.mediaElement.muted = true;
      this.displayVolumeControl(false);
      this.removeRecording();
      this.load(this.stream);
      this.mediaElement.play();
    }
  }, {
    key: "showAnimation",
    value: function showAnimation() {
      var animationDisplay = this.player.animationDisplay.el().firstChild;
      animationDisplay.width = this.player.width();
      animationDisplay.height = this.player.height();
      this.player.recordCanvas.hide();
      (0, _browserShim.default)(this.player.recordedData, animationDisplay);
      this.player.animationDisplay.show();
    }
  }, {
    key: "hideAnimation",
    value: function hideAnimation() {
      this.player.recordCanvas.show();
      this.player.animationDisplay.hide();
    }
  }, {
    key: "playbackTimeUpdate",
    value: function playbackTimeUpdate() {
      this.setCurrentTime(this.player.currentTime(), this.streamDuration);
    }
  }, {
    key: "enumerateDevices",
    value: function enumerateDevices() {
      var _this10 = this;

      if (!navigator.mediaDevices || !navigator.mediaDevices.enumerateDevices) {
        this.player.enumerateErrorCode = 'enumerateDevices() not supported.';
        this.player.trigger(_event.default.ENUMERATE_ERROR);
        return;
      }

      navigator.mediaDevices.enumerateDevices(this).then(function (devices) {
        _this10.devices = [];
        devices.forEach(function (device) {
          _this10.devices.push(device);
        });

        _this10.player.trigger(_event.default.ENUMERATE_READY);
      }).catch(function (err) {
        _this10.player.enumerateErrorCode = err;

        _this10.player.trigger(_event.default.ENUMERATE_ERROR);
      });
    }
  }, {
    key: "setVideoInput",
    value: function setVideoInput(deviceId) {
      if (this.recordVideo === Object(this.recordVideo)) {
        this.recordVideo.deviceId = {
          exact: deviceId
        };
      } else if (this.recordVideo === true) {
        this.recordVideo = {
          deviceId: {
            exact: deviceId
          }
        };
      }

      this.stopDevice();
      this.getDevice();
    }
  }, {
    key: "setAudioInput",
    value: function setAudioInput(deviceId) {
      if (this.recordAudio === Object(this.recordAudio)) {
        this.recordAudio.deviceId = {
          exact: deviceId
        };
      } else if (this.recordAudio === true) {
        this.recordAudio = {
          deviceId: {
            exact: deviceId
          }
        };
      }

      switch (this.getRecordType()) {
        case _recordMode.AUDIO_ONLY:
          this.surfer.surfer.microphone.constraints = {
            video: false,
            audio: this.recordAudio
          };
          break;
      }

      this.stopDevice();
      this.getDevice();
    }
  }, {
    key: "setAudioOutput",
    value: function setAudioOutput(deviceId) {
      var _this11 = this;

      var errorMessage;

      switch (this.getRecordType()) {
        case _recordMode.AUDIO_ONLY:
          this.surfer.surfer.setSinkId(deviceId).then(function (result) {
            _this11.player.trigger(_event.default.AUDIO_OUTPUT_READY);

            return;
          }).catch(function (err) {
            errorMessage = err;
          });
          break;

        default:
          var element = player.tech_.el_;

          if (deviceId) {
            if (typeof element.sinkId !== 'undefined') {
              element.setSinkId(deviceId).then(function (result) {
                _this11.player.trigger(_event.default.AUDIO_OUTPUT_READY);

                return;
              }).catch(function (err) {
                errorMessage = err;
              });
            } else {
              errorMessage = 'Browser does not support audio output device selection.';
            }
          } else {
            errorMessage = "Invalid deviceId: ".concat(deviceId);
          }

          break;
      }

      this.player.trigger(_event.default.ERROR, errorMessage);
    }
  }, {
    key: "setFormatTime",
    value: function setFormatTime(customImplementation) {
      this._formatTime = customImplementation;

      _video.default.setFormatTime(this._formatTime);

      if (this.surfer) {
        this.surfer.setFormatTime(this._formatTime);
      }
    }
  }, {
    key: "displayVolumeControl",
    value: function displayVolumeControl(display) {
      if (this.player.controlBar.volumePanel !== undefined) {
        if (display === true) {
          display = 'flex';
        } else {
          display = 'none';
        }

        this.player.controlBar.volumePanel.el().style.display = display;
      }
    }
  }, {
    key: "onStreamVisible",
    value: function onStreamVisible(event) {
      this.mediaElement.removeEventListener(_event.default.PLAYING, this.streamVisibleCallback);
      this.player.cameraButton.onStop();
      this.player.cameraButton.show();
    }
  }, {
    key: "onEnterPiP",
    value: function onEnterPiP(event) {
      this.player.trigger(_event.default.ENTER_PIP, event);
    }
  }, {
    key: "onLeavePiP",
    value: function onLeavePiP(event) {
      this.player.trigger(_event.default.LEAVE_PIP);
    }
  }]);
  return Record;
}(Plugin);

exports.Record = Record;
Record.VERSION = "4.5.0";
_video.default.Record = Record;

if (_video.default.getPlugin('record') === undefined) {
  _video.default.registerPlugin('record', Record);
}
})();

/******/ 	return __webpack_exports__;
/******/ })()
;
});