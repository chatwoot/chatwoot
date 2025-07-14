/**
 * @license
 * Video.js 7.18.1 <http://videojs.com/>
 * Copyright Brightcove, Inc. <https://www.brightcove.com/>
 * Available under Apache License Version 2.0
 * <https://github.com/videojs/video.js/blob/main/LICENSE>
 *
 * Includes vtt.js <https://github.com/mozilla/vtt.js>
 * Available under Apache License Version 2.0
 * <https://github.com/mozilla/vtt.js/blob/main/LICENSE>
 */

'use strict';

var window = require('global/window');
var document = require('global/document');
var _extends = require('@babel/runtime/helpers/extends');
var keycode = require('keycode');
var _assertThisInitialized = require('@babel/runtime/helpers/assertThisInitialized');
var _inheritsLoose = require('@babel/runtime/helpers/inheritsLoose');
var safeParseTuple = require('safe-json-parse/tuple');
var XHR = require('@videojs/xhr');
var vtt = require('videojs-vtt.js');
var _construct = require('@babel/runtime/helpers/construct');
var _inherits = require('@babel/runtime/helpers/inherits');

function _interopDefaultLegacy (e) { return e && typeof e === 'object' && 'default' in e ? e : { 'default': e }; }

var window__default = /*#__PURE__*/_interopDefaultLegacy(window);
var document__default = /*#__PURE__*/_interopDefaultLegacy(document);
var _extends__default = /*#__PURE__*/_interopDefaultLegacy(_extends);
var keycode__default = /*#__PURE__*/_interopDefaultLegacy(keycode);
var _assertThisInitialized__default = /*#__PURE__*/_interopDefaultLegacy(_assertThisInitialized);
var _inheritsLoose__default = /*#__PURE__*/_interopDefaultLegacy(_inheritsLoose);
var safeParseTuple__default = /*#__PURE__*/_interopDefaultLegacy(safeParseTuple);
var XHR__default = /*#__PURE__*/_interopDefaultLegacy(XHR);
var vtt__default = /*#__PURE__*/_interopDefaultLegacy(vtt);
var _construct__default = /*#__PURE__*/_interopDefaultLegacy(_construct);
var _inherits__default = /*#__PURE__*/_interopDefaultLegacy(_inherits);

var version = "7.18.1";

/**
 * An Object that contains lifecycle hooks as keys which point to an array
 * of functions that are run when a lifecycle is triggered
 *
 * @private
 */
var hooks_ = {};
/**
 * Get a list of hooks for a specific lifecycle
 *
 * @param  {string} type
 *         the lifecyle to get hooks from
 *
 * @param  {Function|Function[]} [fn]
 *         Optionally add a hook (or hooks) to the lifecycle that your are getting.
 *
 * @return {Array}
 *         an array of hooks, or an empty array if there are none.
 */

var hooks = function hooks(type, fn) {
  hooks_[type] = hooks_[type] || [];

  if (fn) {
    hooks_[type] = hooks_[type].concat(fn);
  }

  return hooks_[type];
};
/**
 * Add a function hook to a specific videojs lifecycle.
 *
 * @param {string} type
 *        the lifecycle to hook the function to.
 *
 * @param {Function|Function[]}
 *        The function or array of functions to attach.
 */


var hook = function hook(type, fn) {
  hooks(type, fn);
};
/**
 * Remove a hook from a specific videojs lifecycle.
 *
 * @param  {string} type
 *         the lifecycle that the function hooked to
 *
 * @param  {Function} fn
 *         The hooked function to remove
 *
 * @return {boolean}
 *         The function that was removed or undef
 */


var removeHook = function removeHook(type, fn) {
  var index = hooks(type).indexOf(fn);

  if (index <= -1) {
    return false;
  }

  hooks_[type] = hooks_[type].slice();
  hooks_[type].splice(index, 1);
  return true;
};
/**
 * Add a function hook that will only run once to a specific videojs lifecycle.
 *
 * @param {string} type
 *        the lifecycle to hook the function to.
 *
 * @param {Function|Function[]}
 *        The function or array of functions to attach.
 */


var hookOnce = function hookOnce(type, fn) {
  hooks(type, [].concat(fn).map(function (original) {
    var wrapper = function wrapper() {
      removeHook(type, wrapper);
      return original.apply(void 0, arguments);
    };

    return wrapper;
  }));
};

/**
 * @file fullscreen-api.js
 * @module fullscreen-api
 * @private
 */
/**
 * Store the browser-specific methods for the fullscreen API.
 *
 * @type {Object}
 * @see [Specification]{@link https://fullscreen.spec.whatwg.org}
 * @see [Map Approach From Screenfull.js]{@link https://github.com/sindresorhus/screenfull.js}
 */

var FullscreenApi = {
  prefixed: true
}; // browser API methods

var apiMap = [['requestFullscreen', 'exitFullscreen', 'fullscreenElement', 'fullscreenEnabled', 'fullscreenchange', 'fullscreenerror', 'fullscreen'], // WebKit
['webkitRequestFullscreen', 'webkitExitFullscreen', 'webkitFullscreenElement', 'webkitFullscreenEnabled', 'webkitfullscreenchange', 'webkitfullscreenerror', '-webkit-full-screen'], // Mozilla
['mozRequestFullScreen', 'mozCancelFullScreen', 'mozFullScreenElement', 'mozFullScreenEnabled', 'mozfullscreenchange', 'mozfullscreenerror', '-moz-full-screen'], // Microsoft
['msRequestFullscreen', 'msExitFullscreen', 'msFullscreenElement', 'msFullscreenEnabled', 'MSFullscreenChange', 'MSFullscreenError', '-ms-fullscreen']];
var specApi = apiMap[0];
var browserApi; // determine the supported set of functions

for (var i = 0; i < apiMap.length; i++) {
  // check for exitFullscreen function
  if (apiMap[i][1] in document__default['default']) {
    browserApi = apiMap[i];
    break;
  }
} // map the browser API names to the spec API names


if (browserApi) {
  for (var _i = 0; _i < browserApi.length; _i++) {
    FullscreenApi[specApi[_i]] = browserApi[_i];
  }

  FullscreenApi.prefixed = browserApi[0] !== specApi[0];
}

/**
 * @file create-logger.js
 * @module create-logger
 */

var history = [];
/**
 * Log messages to the console and history based on the type of message
 *
 * @private
 * @param  {string} type
 *         The name of the console method to use.
 *
 * @param  {Array} args
 *         The arguments to be passed to the matching console method.
 */

var LogByTypeFactory = function LogByTypeFactory(name, log) {
  return function (type, level, args) {
    var lvl = log.levels[level];
    var lvlRegExp = new RegExp("^(" + lvl + ")$");

    if (type !== 'log') {
      // Add the type to the front of the message when it's not "log".
      args.unshift(type.toUpperCase() + ':');
    } // Add console prefix after adding to history.


    args.unshift(name + ':'); // Add a clone of the args at this point to history.

    if (history) {
      history.push([].concat(args)); // only store 1000 history entries

      var splice = history.length - 1000;
      history.splice(0, splice > 0 ? splice : 0);
    } // If there's no console then don't try to output messages, but they will
    // still be stored in history.


    if (!window__default['default'].console) {
      return;
    } // Was setting these once outside of this function, but containing them
    // in the function makes it easier to test cases where console doesn't exist
    // when the module is executed.


    var fn = window__default['default'].console[type];

    if (!fn && type === 'debug') {
      // Certain browsers don't have support for console.debug. For those, we
      // should default to the closest comparable log.
      fn = window__default['default'].console.info || window__default['default'].console.log;
    } // Bail out if there's no console or if this type is not allowed by the
    // current logging level.


    if (!fn || !lvl || !lvlRegExp.test(type)) {
      return;
    }

    fn[Array.isArray(args) ? 'apply' : 'call'](window__default['default'].console, args);
  };
};

function createLogger$1(name) {
  // This is the private tracking variable for logging level.
  var level = 'info'; // the curried logByType bound to the specific log and history

  var logByType;
  /**
   * Logs plain debug messages. Similar to `console.log`.
   *
   * Due to [limitations](https://github.com/jsdoc3/jsdoc/issues/955#issuecomment-313829149)
   * of our JSDoc template, we cannot properly document this as both a function
   * and a namespace, so its function signature is documented here.
   *
   * #### Arguments
   * ##### *args
   * Mixed[]
   *
   * Any combination of values that could be passed to `console.log()`.
   *
   * #### Return Value
   *
   * `undefined`
   *
   * @namespace
   * @param    {Mixed[]} args
   *           One or more messages or objects that should be logged.
   */

  var log = function log() {
    for (var _len = arguments.length, args = new Array(_len), _key = 0; _key < _len; _key++) {
      args[_key] = arguments[_key];
    }

    logByType('log', level, args);
  }; // This is the logByType helper that the logging methods below use


  logByType = LogByTypeFactory(name, log);
  /**
   * Create a new sublogger which chains the old name to the new name.
   *
   * For example, doing `videojs.log.createLogger('player')` and then using that logger will log the following:
   * ```js
   *  mylogger('foo');
   *  // > VIDEOJS: player: foo
   * ```
   *
   * @param {string} name
   *        The name to add call the new logger
   * @return {Object}
   */

  log.createLogger = function (subname) {
    return createLogger$1(name + ': ' + subname);
  };
  /**
   * Enumeration of available logging levels, where the keys are the level names
   * and the values are `|`-separated strings containing logging methods allowed
   * in that logging level. These strings are used to create a regular expression
   * matching the function name being called.
   *
   * Levels provided by Video.js are:
   *
   * - `off`: Matches no calls. Any value that can be cast to `false` will have
   *   this effect. The most restrictive.
   * - `all`: Matches only Video.js-provided functions (`debug`, `log`,
   *   `log.warn`, and `log.error`).
   * - `debug`: Matches `log.debug`, `log`, `log.warn`, and `log.error` calls.
   * - `info` (default): Matches `log`, `log.warn`, and `log.error` calls.
   * - `warn`: Matches `log.warn` and `log.error` calls.
   * - `error`: Matches only `log.error` calls.
   *
   * @type {Object}
   */


  log.levels = {
    all: 'debug|log|warn|error',
    off: '',
    debug: 'debug|log|warn|error',
    info: 'log|warn|error',
    warn: 'warn|error',
    error: 'error',
    DEFAULT: level
  };
  /**
   * Get or set the current logging level.
   *
   * If a string matching a key from {@link module:log.levels} is provided, acts
   * as a setter.
   *
   * @param  {string} [lvl]
   *         Pass a valid level to set a new logging level.
   *
   * @return {string}
   *         The current logging level.
   */

  log.level = function (lvl) {
    if (typeof lvl === 'string') {
      if (!log.levels.hasOwnProperty(lvl)) {
        throw new Error("\"" + lvl + "\" in not a valid log level");
      }

      level = lvl;
    }

    return level;
  };
  /**
   * Returns an array containing everything that has been logged to the history.
   *
   * This array is a shallow clone of the internal history record. However, its
   * contents are _not_ cloned; so, mutating objects inside this array will
   * mutate them in history.
   *
   * @return {Array}
   */


  log.history = function () {
    return history ? [].concat(history) : [];
  };
  /**
   * Allows you to filter the history by the given logger name
   *
   * @param {string} fname
   *        The name to filter by
   *
   * @return {Array}
   *         The filtered list to return
   */


  log.history.filter = function (fname) {
    return (history || []).filter(function (historyItem) {
      // if the first item in each historyItem includes `fname`, then it's a match
      return new RegExp(".*" + fname + ".*").test(historyItem[0]);
    });
  };
  /**
   * Clears the internal history tracking, but does not prevent further history
   * tracking.
   */


  log.history.clear = function () {
    if (history) {
      history.length = 0;
    }
  };
  /**
   * Disable history tracking if it is currently enabled.
   */


  log.history.disable = function () {
    if (history !== null) {
      history.length = 0;
      history = null;
    }
  };
  /**
   * Enable history tracking if it is currently disabled.
   */


  log.history.enable = function () {
    if (history === null) {
      history = [];
    }
  };
  /**
   * Logs error messages. Similar to `console.error`.
   *
   * @param {Mixed[]} args
   *        One or more messages or objects that should be logged as an error
   */


  log.error = function () {
    for (var _len2 = arguments.length, args = new Array(_len2), _key2 = 0; _key2 < _len2; _key2++) {
      args[_key2] = arguments[_key2];
    }

    return logByType('error', level, args);
  };
  /**
   * Logs warning messages. Similar to `console.warn`.
   *
   * @param {Mixed[]} args
   *        One or more messages or objects that should be logged as a warning.
   */


  log.warn = function () {
    for (var _len3 = arguments.length, args = new Array(_len3), _key3 = 0; _key3 < _len3; _key3++) {
      args[_key3] = arguments[_key3];
    }

    return logByType('warn', level, args);
  };
  /**
   * Logs debug messages. Similar to `console.debug`, but may also act as a comparable
   * log if `console.debug` is not available
   *
   * @param {Mixed[]} args
   *        One or more messages or objects that should be logged as debug.
   */


  log.debug = function () {
    for (var _len4 = arguments.length, args = new Array(_len4), _key4 = 0; _key4 < _len4; _key4++) {
      args[_key4] = arguments[_key4];
    }

    return logByType('debug', level, args);
  };

  return log;
}

/**
 * @file log.js
 * @module log
 */
var log = createLogger$1('VIDEOJS');
var createLogger = log.createLogger;

/**
 * @file obj.js
 * @module obj
 */

/**
 * @callback obj:EachCallback
 *
 * @param {Mixed} value
 *        The current key for the object that is being iterated over.
 *
 * @param {string} key
 *        The current key-value for object that is being iterated over
 */

/**
 * @callback obj:ReduceCallback
 *
 * @param {Mixed} accum
 *        The value that is accumulating over the reduce loop.
 *
 * @param {Mixed} value
 *        The current key for the object that is being iterated over.
 *
 * @param {string} key
 *        The current key-value for object that is being iterated over
 *
 * @return {Mixed}
 *         The new accumulated value.
 */
var toString = Object.prototype.toString;
/**
 * Get the keys of an Object
 *
 * @param {Object}
 *        The Object to get the keys from
 *
 * @return {string[]}
 *         An array of the keys from the object. Returns an empty array if the
 *         object passed in was invalid or had no keys.
 *
 * @private
 */

var keys = function keys(object) {
  return isObject(object) ? Object.keys(object) : [];
};
/**
 * Array-like iteration for objects.
 *
 * @param {Object} object
 *        The object to iterate over
 *
 * @param {obj:EachCallback} fn
 *        The callback function which is called for each key in the object.
 */


function each(object, fn) {
  keys(object).forEach(function (key) {
    return fn(object[key], key);
  });
}
/**
 * Array-like reduce for objects.
 *
 * @param {Object} object
 *        The Object that you want to reduce.
 *
 * @param {Function} fn
 *         A callback function which is called for each key in the object. It
 *         receives the accumulated value and the per-iteration value and key
 *         as arguments.
 *
 * @param {Mixed} [initial = 0]
 *        Starting value
 *
 * @return {Mixed}
 *         The final accumulated value.
 */

function reduce(object, fn, initial) {
  if (initial === void 0) {
    initial = 0;
  }

  return keys(object).reduce(function (accum, key) {
    return fn(accum, object[key], key);
  }, initial);
}
/**
 * Object.assign-style object shallow merge/extend.
 *
 * @param  {Object} target
 * @param  {Object} ...sources
 * @return {Object}
 */

function assign(target) {
  for (var _len = arguments.length, sources = new Array(_len > 1 ? _len - 1 : 0), _key = 1; _key < _len; _key++) {
    sources[_key - 1] = arguments[_key];
  }

  if (Object.assign) {
    return _extends__default['default'].apply(void 0, [target].concat(sources));
  }

  sources.forEach(function (source) {
    if (!source) {
      return;
    }

    each(source, function (value, key) {
      target[key] = value;
    });
  });
  return target;
}
/**
 * Returns whether a value is an object of any kind - including DOM nodes,
 * arrays, regular expressions, etc. Not functions, though.
 *
 * This avoids the gotcha where using `typeof` on a `null` value
 * results in `'object'`.
 *
 * @param  {Object} value
 * @return {boolean}
 */

function isObject(value) {
  return !!value && typeof value === 'object';
}
/**
 * Returns whether an object appears to be a "plain" object - that is, a
 * direct instance of `Object`.
 *
 * @param  {Object} value
 * @return {boolean}
 */

function isPlain(value) {
  return isObject(value) && toString.call(value) === '[object Object]' && value.constructor === Object;
}

/**
 * @file computed-style.js
 * @module computed-style
 */
/**
 * A safe getComputedStyle.
 *
 * This is needed because in Firefox, if the player is loaded in an iframe with
 * `display:none`, then `getComputedStyle` returns `null`, so, we do a
 * null-check to make sure that the player doesn't break in these cases.
 *
 * @function
 * @param    {Element} el
 *           The element you want the computed style of
 *
 * @param    {string} prop
 *           The property name you want
 *
 * @see      https://bugzilla.mozilla.org/show_bug.cgi?id=548397
 */

function computedStyle(el, prop) {
  if (!el || !prop) {
    return '';
  }

  if (typeof window__default['default'].getComputedStyle === 'function') {
    var computedStyleValue;

    try {
      computedStyleValue = window__default['default'].getComputedStyle(el);
    } catch (e) {
      return '';
    }

    return computedStyleValue ? computedStyleValue.getPropertyValue(prop) || computedStyleValue[prop] : '';
  }

  return '';
}

/**
 * @file browser.js
 * @module browser
 */
var USER_AGENT = window__default['default'].navigator && window__default['default'].navigator.userAgent || '';
var webkitVersionMap = /AppleWebKit\/([\d.]+)/i.exec(USER_AGENT);
var appleWebkitVersion = webkitVersionMap ? parseFloat(webkitVersionMap.pop()) : null;
/**
 * Whether or not this device is an iPod.
 *
 * @static
 * @const
 * @type {Boolean}
 */

var IS_IPOD = /iPod/i.test(USER_AGENT);
/**
 * The detected iOS version - or `null`.
 *
 * @static
 * @const
 * @type {string|null}
 */

var IOS_VERSION = function () {
  var match = USER_AGENT.match(/OS (\d+)_/i);

  if (match && match[1]) {
    return match[1];
  }

  return null;
}();
/**
 * Whether or not this is an Android device.
 *
 * @static
 * @const
 * @type {Boolean}
 */

var IS_ANDROID = /Android/i.test(USER_AGENT);
/**
 * The detected Android version - or `null`.
 *
 * @static
 * @const
 * @type {number|string|null}
 */

var ANDROID_VERSION = function () {
  // This matches Android Major.Minor.Patch versions
  // ANDROID_VERSION is Major.Minor as a Number, if Minor isn't available, then only Major is returned
  var match = USER_AGENT.match(/Android (\d+)(?:\.(\d+))?(?:\.(\d+))*/i);

  if (!match) {
    return null;
  }

  var major = match[1] && parseFloat(match[1]);
  var minor = match[2] && parseFloat(match[2]);

  if (major && minor) {
    return parseFloat(match[1] + '.' + match[2]);
  } else if (major) {
    return major;
  }

  return null;
}();
/**
 * Whether or not this is a native Android browser.
 *
 * @static
 * @const
 * @type {Boolean}
 */

var IS_NATIVE_ANDROID = IS_ANDROID && ANDROID_VERSION < 5 && appleWebkitVersion < 537;
/**
 * Whether or not this is Mozilla Firefox.
 *
 * @static
 * @const
 * @type {Boolean}
 */

var IS_FIREFOX = /Firefox/i.test(USER_AGENT);
/**
 * Whether or not this is Microsoft Edge.
 *
 * @static
 * @const
 * @type {Boolean}
 */

var IS_EDGE = /Edg/i.test(USER_AGENT);
/**
 * Whether or not this is Google Chrome.
 *
 * This will also be `true` for Chrome on iOS, which will have different support
 * as it is actually Safari under the hood.
 *
 * @static
 * @const
 * @type {Boolean}
 */

var IS_CHROME = !IS_EDGE && (/Chrome/i.test(USER_AGENT) || /CriOS/i.test(USER_AGENT));
/**
 * The detected Google Chrome version - or `null`.
 *
 * @static
 * @const
 * @type {number|null}
 */

var CHROME_VERSION = function () {
  var match = USER_AGENT.match(/(Chrome|CriOS)\/(\d+)/);

  if (match && match[2]) {
    return parseFloat(match[2]);
  }

  return null;
}();
/**
 * The detected Internet Explorer version - or `null`.
 *
 * @static
 * @const
 * @type {number|null}
 */

var IE_VERSION = function () {
  var result = /MSIE\s(\d+)\.\d/.exec(USER_AGENT);
  var version = result && parseFloat(result[1]);

  if (!version && /Trident\/7.0/i.test(USER_AGENT) && /rv:11.0/.test(USER_AGENT)) {
    // IE 11 has a different user agent string than other IE versions
    version = 11.0;
  }

  return version;
}();
/**
 * Whether or not this is desktop Safari.
 *
 * @static
 * @const
 * @type {Boolean}
 */

var IS_SAFARI = /Safari/i.test(USER_AGENT) && !IS_CHROME && !IS_ANDROID && !IS_EDGE;
/**
 * Whether or not this is a Windows machine.
 *
 * @static
 * @const
 * @type {Boolean}
 */

var IS_WINDOWS = /Windows/i.test(USER_AGENT);
/**
 * Whether or not this device is touch-enabled.
 *
 * @static
 * @const
 * @type {Boolean}
 */

var TOUCH_ENABLED = Boolean(isReal() && ('ontouchstart' in window__default['default'] || window__default['default'].navigator.maxTouchPoints || window__default['default'].DocumentTouch && window__default['default'].document instanceof window__default['default'].DocumentTouch));
/**
 * Whether or not this device is an iPad.
 *
 * @static
 * @const
 * @type {Boolean}
 */

var IS_IPAD = /iPad/i.test(USER_AGENT) || IS_SAFARI && TOUCH_ENABLED && !/iPhone/i.test(USER_AGENT);
/**
 * Whether or not this device is an iPhone.
 *
 * @static
 * @const
 * @type {Boolean}
 */
// The Facebook app's UIWebView identifies as both an iPhone and iPad, so
// to identify iPhones, we need to exclude iPads.
// http://artsy.github.io/blog/2012/10/18/the-perils-of-ios-user-agent-sniffing/

var IS_IPHONE = /iPhone/i.test(USER_AGENT) && !IS_IPAD;
/**
 * Whether or not this is an iOS device.
 *
 * @static
 * @const
 * @type {Boolean}
 */

var IS_IOS = IS_IPHONE || IS_IPAD || IS_IPOD;
/**
 * Whether or not this is any flavor of Safari - including iOS.
 *
 * @static
 * @const
 * @type {Boolean}
 */

var IS_ANY_SAFARI = (IS_SAFARI || IS_IOS) && !IS_CHROME;

var browser = /*#__PURE__*/Object.freeze({
  __proto__: null,
  IS_IPOD: IS_IPOD,
  IOS_VERSION: IOS_VERSION,
  IS_ANDROID: IS_ANDROID,
  ANDROID_VERSION: ANDROID_VERSION,
  IS_NATIVE_ANDROID: IS_NATIVE_ANDROID,
  IS_FIREFOX: IS_FIREFOX,
  IS_EDGE: IS_EDGE,
  IS_CHROME: IS_CHROME,
  CHROME_VERSION: CHROME_VERSION,
  IE_VERSION: IE_VERSION,
  IS_SAFARI: IS_SAFARI,
  IS_WINDOWS: IS_WINDOWS,
  TOUCH_ENABLED: TOUCH_ENABLED,
  IS_IPAD: IS_IPAD,
  IS_IPHONE: IS_IPHONE,
  IS_IOS: IS_IOS,
  IS_ANY_SAFARI: IS_ANY_SAFARI
});

/**
 * @file dom.js
 * @module dom
 */
/**
 * Detect if a value is a string with any non-whitespace characters.
 *
 * @private
 * @param  {string} str
 *         The string to check
 *
 * @return {boolean}
 *         Will be `true` if the string is non-blank, `false` otherwise.
 *
 */

function isNonBlankString(str) {
  // we use str.trim as it will trim any whitespace characters
  // from the front or back of non-whitespace characters. aka
  // Any string that contains non-whitespace characters will
  // still contain them after `trim` but whitespace only strings
  // will have a length of 0, failing this check.
  return typeof str === 'string' && Boolean(str.trim());
}
/**
 * Throws an error if the passed string has whitespace. This is used by
 * class methods to be relatively consistent with the classList API.
 *
 * @private
 * @param  {string} str
 *         The string to check for whitespace.
 *
 * @throws {Error}
 *         Throws an error if there is whitespace in the string.
 */


function throwIfWhitespace(str) {
  // str.indexOf instead of regex because str.indexOf is faster performance wise.
  if (str.indexOf(' ') >= 0) {
    throw new Error('class has illegal whitespace characters');
  }
}
/**
 * Produce a regular expression for matching a className within an elements className.
 *
 * @private
 * @param  {string} className
 *         The className to generate the RegExp for.
 *
 * @return {RegExp}
 *         The RegExp that will check for a specific `className` in an elements
 *         className.
 */


function classRegExp(className) {
  return new RegExp('(^|\\s)' + className + '($|\\s)');
}
/**
 * Whether the current DOM interface appears to be real (i.e. not simulated).
 *
 * @return {boolean}
 *         Will be `true` if the DOM appears to be real, `false` otherwise.
 */


function isReal() {
  // Both document and window will never be undefined thanks to `global`.
  return document__default['default'] === window__default['default'].document;
}
/**
 * Determines, via duck typing, whether or not a value is a DOM element.
 *
 * @param  {Mixed} value
 *         The value to check.
 *
 * @return {boolean}
 *         Will be `true` if the value is a DOM element, `false` otherwise.
 */

function isEl(value) {
  return isObject(value) && value.nodeType === 1;
}
/**
 * Determines if the current DOM is embedded in an iframe.
 *
 * @return {boolean}
 *         Will be `true` if the DOM is embedded in an iframe, `false`
 *         otherwise.
 */

function isInFrame() {
  // We need a try/catch here because Safari will throw errors when attempting
  // to get either `parent` or `self`
  try {
    return window__default['default'].parent !== window__default['default'].self;
  } catch (x) {
    return true;
  }
}
/**
 * Creates functions to query the DOM using a given method.
 *
 * @private
 * @param   {string} method
 *          The method to create the query with.
 *
 * @return  {Function}
 *          The query method
 */

function createQuerier(method) {
  return function (selector, context) {
    if (!isNonBlankString(selector)) {
      return document__default['default'][method](null);
    }

    if (isNonBlankString(context)) {
      context = document__default['default'].querySelector(context);
    }

    var ctx = isEl(context) ? context : document__default['default'];
    return ctx[method] && ctx[method](selector);
  };
}
/**
 * Creates an element and applies properties, attributes, and inserts content.
 *
 * @param  {string} [tagName='div']
 *         Name of tag to be created.
 *
 * @param  {Object} [properties={}]
 *         Element properties to be applied.
 *
 * @param  {Object} [attributes={}]
 *         Element attributes to be applied.
 *
 * @param {module:dom~ContentDescriptor} content
 *        A content descriptor object.
 *
 * @return {Element}
 *         The element that was created.
 */


function createEl(tagName, properties, attributes, content) {
  if (tagName === void 0) {
    tagName = 'div';
  }

  if (properties === void 0) {
    properties = {};
  }

  if (attributes === void 0) {
    attributes = {};
  }

  var el = document__default['default'].createElement(tagName);
  Object.getOwnPropertyNames(properties).forEach(function (propName) {
    var val = properties[propName]; // See #2176
    // We originally were accepting both properties and attributes in the
    // same object, but that doesn't work so well.

    if (propName.indexOf('aria-') !== -1 || propName === 'role' || propName === 'type') {
      log.warn('Setting attributes in the second argument of createEl()\n' + 'has been deprecated. Use the third argument instead.\n' + ("createEl(type, properties, attributes). Attempting to set " + propName + " to " + val + "."));
      el.setAttribute(propName, val); // Handle textContent since it's not supported everywhere and we have a
      // method for it.
    } else if (propName === 'textContent') {
      textContent(el, val);
    } else if (el[propName] !== val || propName === 'tabIndex') {
      el[propName] = val;
    }
  });
  Object.getOwnPropertyNames(attributes).forEach(function (attrName) {
    el.setAttribute(attrName, attributes[attrName]);
  });

  if (content) {
    appendContent(el, content);
  }

  return el;
}
/**
 * Injects text into an element, replacing any existing contents entirely.
 *
 * @param  {Element} el
 *         The element to add text content into
 *
 * @param  {string} text
 *         The text content to add.
 *
 * @return {Element}
 *         The element with added text content.
 */

function textContent(el, text) {
  if (typeof el.textContent === 'undefined') {
    el.innerText = text;
  } else {
    el.textContent = text;
  }

  return el;
}
/**
 * Insert an element as the first child node of another
 *
 * @param {Element} child
 *        Element to insert
 *
 * @param {Element} parent
 *        Element to insert child into
 */

function prependTo(child, parent) {
  if (parent.firstChild) {
    parent.insertBefore(child, parent.firstChild);
  } else {
    parent.appendChild(child);
  }
}
/**
 * Check if an element has a class name.
 *
 * @param  {Element} element
 *         Element to check
 *
 * @param  {string} classToCheck
 *         Class name to check for
 *
 * @return {boolean}
 *         Will be `true` if the element has a class, `false` otherwise.
 *
 * @throws {Error}
 *         Throws an error if `classToCheck` has white space.
 */

function hasClass(element, classToCheck) {
  throwIfWhitespace(classToCheck);

  if (element.classList) {
    return element.classList.contains(classToCheck);
  }

  return classRegExp(classToCheck).test(element.className);
}
/**
 * Add a class name to an element.
 *
 * @param  {Element} element
 *         Element to add class name to.
 *
 * @param  {string} classToAdd
 *         Class name to add.
 *
 * @return {Element}
 *         The DOM element with the added class name.
 */

function addClass(element, classToAdd) {
  if (element.classList) {
    element.classList.add(classToAdd); // Don't need to `throwIfWhitespace` here because `hasElClass` will do it
    // in the case of classList not being supported.
  } else if (!hasClass(element, classToAdd)) {
    element.className = (element.className + ' ' + classToAdd).trim();
  }

  return element;
}
/**
 * Remove a class name from an element.
 *
 * @param  {Element} element
 *         Element to remove a class name from.
 *
 * @param  {string} classToRemove
 *         Class name to remove
 *
 * @return {Element}
 *         The DOM element with class name removed.
 */

function removeClass(element, classToRemove) {
  // Protect in case the player gets disposed
  if (!element) {
    log.warn("removeClass was called with an element that doesn't exist");
    return null;
  }

  if (element.classList) {
    element.classList.remove(classToRemove);
  } else {
    throwIfWhitespace(classToRemove);
    element.className = element.className.split(/\s+/).filter(function (c) {
      return c !== classToRemove;
    }).join(' ');
  }

  return element;
}
/**
 * The callback definition for toggleClass.
 *
 * @callback module:dom~PredicateCallback
 * @param    {Element} element
 *           The DOM element of the Component.
 *
 * @param    {string} classToToggle
 *           The `className` that wants to be toggled
 *
 * @return   {boolean|undefined}
 *           If `true` is returned, the `classToToggle` will be added to the
 *           `element`. If `false`, the `classToToggle` will be removed from
 *           the `element`. If `undefined`, the callback will be ignored.
 */

/**
 * Adds or removes a class name to/from an element depending on an optional
 * condition or the presence/absence of the class name.
 *
 * @param  {Element} element
 *         The element to toggle a class name on.
 *
 * @param  {string} classToToggle
 *         The class that should be toggled.
 *
 * @param  {boolean|module:dom~PredicateCallback} [predicate]
 *         See the return value for {@link module:dom~PredicateCallback}
 *
 * @return {Element}
 *         The element with a class that has been toggled.
 */

function toggleClass(element, classToToggle, predicate) {
  // This CANNOT use `classList` internally because IE11 does not support the
  // second parameter to the `classList.toggle()` method! Which is fine because
  // `classList` will be used by the add/remove functions.
  var has = hasClass(element, classToToggle);

  if (typeof predicate === 'function') {
    predicate = predicate(element, classToToggle);
  }

  if (typeof predicate !== 'boolean') {
    predicate = !has;
  } // If the necessary class operation matches the current state of the
  // element, no action is required.


  if (predicate === has) {
    return;
  }

  if (predicate) {
    addClass(element, classToToggle);
  } else {
    removeClass(element, classToToggle);
  }

  return element;
}
/**
 * Apply attributes to an HTML element.
 *
 * @param {Element} el
 *        Element to add attributes to.
 *
 * @param {Object} [attributes]
 *        Attributes to be applied.
 */

function setAttributes(el, attributes) {
  Object.getOwnPropertyNames(attributes).forEach(function (attrName) {
    var attrValue = attributes[attrName];

    if (attrValue === null || typeof attrValue === 'undefined' || attrValue === false) {
      el.removeAttribute(attrName);
    } else {
      el.setAttribute(attrName, attrValue === true ? '' : attrValue);
    }
  });
}
/**
 * Get an element's attribute values, as defined on the HTML tag.
 *
 * Attributes are not the same as properties. They're defined on the tag
 * or with setAttribute.
 *
 * @param  {Element} tag
 *         Element from which to get tag attributes.
 *
 * @return {Object}
 *         All attributes of the element. Boolean attributes will be `true` or
 *         `false`, others will be strings.
 */

function getAttributes(tag) {
  var obj = {}; // known boolean attributes
  // we can check for matching boolean properties, but not all browsers
  // and not all tags know about these attributes, so, we still want to check them manually

  var knownBooleans = ',' + 'autoplay,controls,playsinline,loop,muted,default,defaultMuted' + ',';

  if (tag && tag.attributes && tag.attributes.length > 0) {
    var attrs = tag.attributes;

    for (var i = attrs.length - 1; i >= 0; i--) {
      var attrName = attrs[i].name;
      var attrVal = attrs[i].value; // check for known booleans
      // the matching element property will return a value for typeof

      if (typeof tag[attrName] === 'boolean' || knownBooleans.indexOf(',' + attrName + ',') !== -1) {
        // the value of an included boolean attribute is typically an empty
        // string ('') which would equal false if we just check for a false value.
        // we also don't want support bad code like autoplay='false'
        attrVal = attrVal !== null ? true : false;
      }

      obj[attrName] = attrVal;
    }
  }

  return obj;
}
/**
 * Get the value of an element's attribute.
 *
 * @param {Element} el
 *        A DOM element.
 *
 * @param {string} attribute
 *        Attribute to get the value of.
 *
 * @return {string}
 *         The value of the attribute.
 */

function getAttribute(el, attribute) {
  return el.getAttribute(attribute);
}
/**
 * Set the value of an element's attribute.
 *
 * @param {Element} el
 *        A DOM element.
 *
 * @param {string} attribute
 *        Attribute to set.
 *
 * @param {string} value
 *        Value to set the attribute to.
 */

function setAttribute(el, attribute, value) {
  el.setAttribute(attribute, value);
}
/**
 * Remove an element's attribute.
 *
 * @param {Element} el
 *        A DOM element.
 *
 * @param {string} attribute
 *        Attribute to remove.
 */

function removeAttribute(el, attribute) {
  el.removeAttribute(attribute);
}
/**
 * Attempt to block the ability to select text.
 */

function blockTextSelection() {
  document__default['default'].body.focus();

  document__default['default'].onselectstart = function () {
    return false;
  };
}
/**
 * Turn off text selection blocking.
 */

function unblockTextSelection() {
  document__default['default'].onselectstart = function () {
    return true;
  };
}
/**
 * Identical to the native `getBoundingClientRect` function, but ensures that
 * the method is supported at all (it is in all browsers we claim to support)
 * and that the element is in the DOM before continuing.
 *
 * This wrapper function also shims properties which are not provided by some
 * older browsers (namely, IE8).
 *
 * Additionally, some browsers do not support adding properties to a
 * `ClientRect`/`DOMRect` object; so, we shallow-copy it with the standard
 * properties (except `x` and `y` which are not widely supported). This helps
 * avoid implementations where keys are non-enumerable.
 *
 * @param  {Element} el
 *         Element whose `ClientRect` we want to calculate.
 *
 * @return {Object|undefined}
 *         Always returns a plain object - or `undefined` if it cannot.
 */

function getBoundingClientRect(el) {
  if (el && el.getBoundingClientRect && el.parentNode) {
    var rect = el.getBoundingClientRect();
    var result = {};
    ['bottom', 'height', 'left', 'right', 'top', 'width'].forEach(function (k) {
      if (rect[k] !== undefined) {
        result[k] = rect[k];
      }
    });

    if (!result.height) {
      result.height = parseFloat(computedStyle(el, 'height'));
    }

    if (!result.width) {
      result.width = parseFloat(computedStyle(el, 'width'));
    }

    return result;
  }
}
/**
 * Represents the position of a DOM element on the page.
 *
 * @typedef  {Object} module:dom~Position
 *
 * @property {number} left
 *           Pixels to the left.
 *
 * @property {number} top
 *           Pixels from the top.
 */

/**
 * Get the position of an element in the DOM.
 *
 * Uses `getBoundingClientRect` technique from John Resig.
 *
 * @see http://ejohn.org/blog/getboundingclientrect-is-awesome/
 *
 * @param  {Element} el
 *         Element from which to get offset.
 *
 * @return {module:dom~Position}
 *         The position of the element that was passed in.
 */

function findPosition(el) {
  if (!el || el && !el.offsetParent) {
    return {
      left: 0,
      top: 0,
      width: 0,
      height: 0
    };
  }

  var width = el.offsetWidth;
  var height = el.offsetHeight;
  var left = 0;
  var top = 0;

  while (el.offsetParent && el !== document__default['default'][FullscreenApi.fullscreenElement]) {
    left += el.offsetLeft;
    top += el.offsetTop;
    el = el.offsetParent;
  }

  return {
    left: left,
    top: top,
    width: width,
    height: height
  };
}
/**
 * Represents x and y coordinates for a DOM element or mouse pointer.
 *
 * @typedef  {Object} module:dom~Coordinates
 *
 * @property {number} x
 *           x coordinate in pixels
 *
 * @property {number} y
 *           y coordinate in pixels
 */

/**
 * Get the pointer position within an element.
 *
 * The base on the coordinates are the bottom left of the element.
 *
 * @param  {Element} el
 *         Element on which to get the pointer position on.
 *
 * @param  {EventTarget~Event} event
 *         Event object.
 *
 * @return {module:dom~Coordinates}
 *         A coordinates object corresponding to the mouse position.
 *
 */

function getPointerPosition(el, event) {
  var translated = {
    x: 0,
    y: 0
  };

  if (IS_IOS) {
    var item = el;

    while (item && item.nodeName.toLowerCase() !== 'html') {
      var transform = computedStyle(item, 'transform');

      if (/^matrix/.test(transform)) {
        var values = transform.slice(7, -1).split(/,\s/).map(Number);
        translated.x += values[4];
        translated.y += values[5];
      } else if (/^matrix3d/.test(transform)) {
        var _values = transform.slice(9, -1).split(/,\s/).map(Number);

        translated.x += _values[12];
        translated.y += _values[13];
      }

      item = item.parentNode;
    }
  }

  var position = {};
  var boxTarget = findPosition(event.target);
  var box = findPosition(el);
  var boxW = box.width;
  var boxH = box.height;
  var offsetY = event.offsetY - (box.top - boxTarget.top);
  var offsetX = event.offsetX - (box.left - boxTarget.left);

  if (event.changedTouches) {
    offsetX = event.changedTouches[0].pageX - box.left;
    offsetY = event.changedTouches[0].pageY + box.top;

    if (IS_IOS) {
      offsetX -= translated.x;
      offsetY -= translated.y;
    }
  }

  position.y = 1 - Math.max(0, Math.min(1, offsetY / boxH));
  position.x = Math.max(0, Math.min(1, offsetX / boxW));
  return position;
}
/**
 * Determines, via duck typing, whether or not a value is a text node.
 *
 * @param  {Mixed} value
 *         Check if this value is a text node.
 *
 * @return {boolean}
 *         Will be `true` if the value is a text node, `false` otherwise.
 */

function isTextNode(value) {
  return isObject(value) && value.nodeType === 3;
}
/**
 * Empties the contents of an element.
 *
 * @param  {Element} el
 *         The element to empty children from
 *
 * @return {Element}
 *         The element with no children
 */

function emptyEl(el) {
  while (el.firstChild) {
    el.removeChild(el.firstChild);
  }

  return el;
}
/**
 * This is a mixed value that describes content to be injected into the DOM
 * via some method. It can be of the following types:
 *
 * Type       | Description
 * -----------|-------------
 * `string`   | The value will be normalized into a text node.
 * `Element`  | The value will be accepted as-is.
 * `TextNode` | The value will be accepted as-is.
 * `Array`    | A one-dimensional array of strings, elements, text nodes, or functions. These functions should return a string, element, or text node (any other return value, like an array, will be ignored).
 * `Function` | A function, which is expected to return a string, element, text node, or array - any of the other possible values described above. This means that a content descriptor could be a function that returns an array of functions, but those second-level functions must return strings, elements, or text nodes.
 *
 * @typedef {string|Element|TextNode|Array|Function} module:dom~ContentDescriptor
 */

/**
 * Normalizes content for eventual insertion into the DOM.
 *
 * This allows a wide range of content definition methods, but helps protect
 * from falling into the trap of simply writing to `innerHTML`, which could
 * be an XSS concern.
 *
 * The content for an element can be passed in multiple types and
 * combinations, whose behavior is as follows:
 *
 * @param {module:dom~ContentDescriptor} content
 *        A content descriptor value.
 *
 * @return {Array}
 *         All of the content that was passed in, normalized to an array of
 *         elements or text nodes.
 */

function normalizeContent(content) {
  // First, invoke content if it is a function. If it produces an array,
  // that needs to happen before normalization.
  if (typeof content === 'function') {
    content = content();
  } // Next up, normalize to an array, so one or many items can be normalized,
  // filtered, and returned.


  return (Array.isArray(content) ? content : [content]).map(function (value) {
    // First, invoke value if it is a function to produce a new value,
    // which will be subsequently normalized to a Node of some kind.
    if (typeof value === 'function') {
      value = value();
    }

    if (isEl(value) || isTextNode(value)) {
      return value;
    }

    if (typeof value === 'string' && /\S/.test(value)) {
      return document__default['default'].createTextNode(value);
    }
  }).filter(function (value) {
    return value;
  });
}
/**
 * Normalizes and appends content to an element.
 *
 * @param  {Element} el
 *         Element to append normalized content to.
 *
 * @param {module:dom~ContentDescriptor} content
 *        A content descriptor value.
 *
 * @return {Element}
 *         The element with appended normalized content.
 */

function appendContent(el, content) {
  normalizeContent(content).forEach(function (node) {
    return el.appendChild(node);
  });
  return el;
}
/**
 * Normalizes and inserts content into an element; this is identical to
 * `appendContent()`, except it empties the element first.
 *
 * @param {Element} el
 *        Element to insert normalized content into.
 *
 * @param {module:dom~ContentDescriptor} content
 *        A content descriptor value.
 *
 * @return {Element}
 *         The element with inserted normalized content.
 */

function insertContent(el, content) {
  return appendContent(emptyEl(el), content);
}
/**
 * Check if an event was a single left click.
 *
 * @param  {EventTarget~Event} event
 *         Event object.
 *
 * @return {boolean}
 *         Will be `true` if a single left click, `false` otherwise.
 */

function isSingleLeftClick(event) {
  // Note: if you create something draggable, be sure to
  // call it on both `mousedown` and `mousemove` event,
  // otherwise `mousedown` should be enough for a button
  if (event.button === undefined && event.buttons === undefined) {
    // Why do we need `buttons` ?
    // Because, middle mouse sometimes have this:
    // e.button === 0 and e.buttons === 4
    // Furthermore, we want to prevent combination click, something like
    // HOLD middlemouse then left click, that would be
    // e.button === 0, e.buttons === 5
    // just `button` is not gonna work
    // Alright, then what this block does ?
    // this is for chrome `simulate mobile devices`
    // I want to support this as well
    return true;
  }

  if (event.button === 0 && event.buttons === undefined) {
    // Touch screen, sometimes on some specific device, `buttons`
    // doesn't have anything (safari on ios, blackberry...)
    return true;
  } // `mouseup` event on a single left click has
  // `button` and `buttons` equal to 0


  if (event.type === 'mouseup' && event.button === 0 && event.buttons === 0) {
    return true;
  }

  if (event.button !== 0 || event.buttons !== 1) {
    // This is the reason we have those if else block above
    // if any special case we can catch and let it slide
    // we do it above, when get to here, this definitely
    // is-not-left-click
    return false;
  }

  return true;
}
/**
 * Finds a single DOM element matching `selector` within the optional
 * `context` of another DOM element (defaulting to `document`).
 *
 * @param  {string} selector
 *         A valid CSS selector, which will be passed to `querySelector`.
 *
 * @param  {Element|String} [context=document]
 *         A DOM element within which to query. Can also be a selector
 *         string in which case the first matching element will be used
 *         as context. If missing (or no element matches selector), falls
 *         back to `document`.
 *
 * @return {Element|null}
 *         The element that was found or null.
 */

var $ = createQuerier('querySelector');
/**
 * Finds a all DOM elements matching `selector` within the optional
 * `context` of another DOM element (defaulting to `document`).
 *
 * @param  {string} selector
 *         A valid CSS selector, which will be passed to `querySelectorAll`.
 *
 * @param  {Element|String} [context=document]
 *         A DOM element within which to query. Can also be a selector
 *         string in which case the first matching element will be used
 *         as context. If missing (or no element matches selector), falls
 *         back to `document`.
 *
 * @return {NodeList}
 *         A element list of elements that were found. Will be empty if none
 *         were found.
 *
 */

var $$ = createQuerier('querySelectorAll');

var Dom = /*#__PURE__*/Object.freeze({
  __proto__: null,
  isReal: isReal,
  isEl: isEl,
  isInFrame: isInFrame,
  createEl: createEl,
  textContent: textContent,
  prependTo: prependTo,
  hasClass: hasClass,
  addClass: addClass,
  removeClass: removeClass,
  toggleClass: toggleClass,
  setAttributes: setAttributes,
  getAttributes: getAttributes,
  getAttribute: getAttribute,
  setAttribute: setAttribute,
  removeAttribute: removeAttribute,
  blockTextSelection: blockTextSelection,
  unblockTextSelection: unblockTextSelection,
  getBoundingClientRect: getBoundingClientRect,
  findPosition: findPosition,
  getPointerPosition: getPointerPosition,
  isTextNode: isTextNode,
  emptyEl: emptyEl,
  normalizeContent: normalizeContent,
  appendContent: appendContent,
  insertContent: insertContent,
  isSingleLeftClick: isSingleLeftClick,
  $: $,
  $$: $$
});

/**
 * @file setup.js - Functions for setting up a player without
 * user interaction based on the data-setup `attribute` of the video tag.
 *
 * @module setup
 */
var _windowLoaded = false;
var videojs$1;
/**
 * Set up any tags that have a data-setup `attribute` when the player is started.
 */

var autoSetup = function autoSetup() {
  if (videojs$1.options.autoSetup === false) {
    return;
  }

  var vids = Array.prototype.slice.call(document__default['default'].getElementsByTagName('video'));
  var audios = Array.prototype.slice.call(document__default['default'].getElementsByTagName('audio'));
  var divs = Array.prototype.slice.call(document__default['default'].getElementsByTagName('video-js'));
  var mediaEls = vids.concat(audios, divs); // Check if any media elements exist

  if (mediaEls && mediaEls.length > 0) {
    for (var i = 0, e = mediaEls.length; i < e; i++) {
      var mediaEl = mediaEls[i]; // Check if element exists, has getAttribute func.

      if (mediaEl && mediaEl.getAttribute) {
        // Make sure this player hasn't already been set up.
        if (mediaEl.player === undefined) {
          var options = mediaEl.getAttribute('data-setup'); // Check if data-setup attr exists.
          // We only auto-setup if they've added the data-setup attr.

          if (options !== null) {
            // Create new video.js instance.
            videojs$1(mediaEl);
          }
        } // If getAttribute isn't defined, we need to wait for the DOM.

      } else {
        autoSetupTimeout(1);
        break;
      }
    } // No videos were found, so keep looping unless page is finished loading.

  } else if (!_windowLoaded) {
    autoSetupTimeout(1);
  }
};
/**
 * Wait until the page is loaded before running autoSetup. This will be called in
 * autoSetup if `hasLoaded` returns false.
 *
 * @param {number} wait
 *        How long to wait in ms
 *
 * @param {module:videojs} [vjs]
 *        The videojs library function
 */


function autoSetupTimeout(wait, vjs) {
  // Protect against breakage in non-browser environments
  if (!isReal()) {
    return;
  }

  if (vjs) {
    videojs$1 = vjs;
  }

  window__default['default'].setTimeout(autoSetup, wait);
}
/**
 * Used to set the internal tracking of window loaded state to true.
 *
 * @private
 */


function setWindowLoaded() {
  _windowLoaded = true;
  window__default['default'].removeEventListener('load', setWindowLoaded);
}

if (isReal()) {
  if (document__default['default'].readyState === 'complete') {
    setWindowLoaded();
  } else {
    /**
     * Listen for the load event on window, and set _windowLoaded to true.
     *
     * We use a standard event listener here to avoid incrementing the GUID
     * before any players are created.
     *
     * @listens load
     */
    window__default['default'].addEventListener('load', setWindowLoaded);
  }
}

/**
 * @file stylesheet.js
 * @module stylesheet
 */
/**
 * Create a DOM syle element given a className for it.
 *
 * @param {string} className
 *        The className to add to the created style element.
 *
 * @return {Element}
 *         The element that was created.
 */

var createStyleElement = function createStyleElement(className) {
  var style = document__default['default'].createElement('style');
  style.className = className;
  return style;
};
/**
 * Add text to a DOM element.
 *
 * @param {Element} el
 *        The Element to add text content to.
 *
 * @param {string} content
 *        The text to add to the element.
 */

var setTextContent = function setTextContent(el, content) {
  if (el.styleSheet) {
    el.styleSheet.cssText = content;
  } else {
    el.textContent = content;
  }
};

/**
 * @file guid.js
 * @module guid
 */
// Default value for GUIDs. This allows us to reset the GUID counter in tests.
//
// The initial GUID is 3 because some users have come to rely on the first
// default player ID ending up as `vjs_video_3`.
//
// See: https://github.com/videojs/video.js/pull/6216
var _initialGuid = 3;
/**
 * Unique ID for an element or function
 *
 * @type {Number}
 */

var _guid = _initialGuid;
/**
 * Get a unique auto-incrementing ID by number that has not been returned before.
 *
 * @return {number}
 *         A new unique ID.
 */

function newGUID() {
  return _guid++;
}

/**
 * @file dom-data.js
 * @module dom-data
 */
var FakeWeakMap;

if (!window__default['default'].WeakMap) {
  FakeWeakMap = /*#__PURE__*/function () {
    function FakeWeakMap() {
      this.vdata = 'vdata' + Math.floor(window__default['default'].performance && window__default['default'].performance.now() || Date.now());
      this.data = {};
    }

    var _proto = FakeWeakMap.prototype;

    _proto.set = function set(key, value) {
      var access = key[this.vdata] || newGUID();

      if (!key[this.vdata]) {
        key[this.vdata] = access;
      }

      this.data[access] = value;
      return this;
    };

    _proto.get = function get(key) {
      var access = key[this.vdata]; // we have data, return it

      if (access) {
        return this.data[access];
      } // we don't have data, return nothing.
      // return undefined explicitly as that's the contract for this method


      log('We have no data for this element', key);
      return undefined;
    };

    _proto.has = function has(key) {
      var access = key[this.vdata];
      return access in this.data;
    };

    _proto["delete"] = function _delete(key) {
      var access = key[this.vdata];

      if (access) {
        delete this.data[access];
        delete key[this.vdata];
      }
    };

    return FakeWeakMap;
  }();
}
/**
 * Element Data Store.
 *
 * Allows for binding data to an element without putting it directly on the
 * element. Ex. Event listeners are stored here.
 * (also from jsninja.com, slightly modified and updated for closure compiler)
 *
 * @type {Object}
 * @private
 */


var DomData = window__default['default'].WeakMap ? new WeakMap() : new FakeWeakMap();

/**
 * @file events.js. An Event System (John Resig - Secrets of a JS Ninja http://jsninja.com/)
 * (Original book version wasn't completely usable, so fixed some things and made Closure Compiler compatible)
 * This should work very similarly to jQuery's events, however it's based off the book version which isn't as
 * robust as jquery's, so there's probably some differences.
 *
 * @file events.js
 * @module events
 */
/**
 * Clean up the listener cache and dispatchers
 *
 * @param {Element|Object} elem
 *        Element to clean up
 *
 * @param {string} type
 *        Type of event to clean up
 */

function _cleanUpEvents(elem, type) {
  if (!DomData.has(elem)) {
    return;
  }

  var data = DomData.get(elem); // Remove the events of a particular type if there are none left

  if (data.handlers[type].length === 0) {
    delete data.handlers[type]; // data.handlers[type] = null;
    // Setting to null was causing an error with data.handlers
    // Remove the meta-handler from the element

    if (elem.removeEventListener) {
      elem.removeEventListener(type, data.dispatcher, false);
    } else if (elem.detachEvent) {
      elem.detachEvent('on' + type, data.dispatcher);
    }
  } // Remove the events object if there are no types left


  if (Object.getOwnPropertyNames(data.handlers).length <= 0) {
    delete data.handlers;
    delete data.dispatcher;
    delete data.disabled;
  } // Finally remove the element data if there is no data left


  if (Object.getOwnPropertyNames(data).length === 0) {
    DomData["delete"](elem);
  }
}
/**
 * Loops through an array of event types and calls the requested method for each type.
 *
 * @param {Function} fn
 *        The event method we want to use.
 *
 * @param {Element|Object} elem
 *        Element or object to bind listeners to
 *
 * @param {string} type
 *        Type of event to bind to.
 *
 * @param {EventTarget~EventListener} callback
 *        Event listener.
 */


function _handleMultipleEvents(fn, elem, types, callback) {
  types.forEach(function (type) {
    // Call the event method for each one of the types
    fn(elem, type, callback);
  });
}
/**
 * Fix a native event to have standard property values
 *
 * @param {Object} event
 *        Event object to fix.
 *
 * @return {Object}
 *         Fixed event object.
 */


function fixEvent(event) {
  if (event.fixed_) {
    return event;
  }

  function returnTrue() {
    return true;
  }

  function returnFalse() {
    return false;
  } // Test if fixing up is needed
  // Used to check if !event.stopPropagation instead of isPropagationStopped
  // But native events return true for stopPropagation, but don't have
  // other expected methods like isPropagationStopped. Seems to be a problem
  // with the Javascript Ninja code. So we're just overriding all events now.


  if (!event || !event.isPropagationStopped || !event.isImmediatePropagationStopped) {
    var old = event || window__default['default'].event;
    event = {}; // Clone the old object so that we can modify the values event = {};
    // IE8 Doesn't like when you mess with native event properties
    // Firefox returns false for event.hasOwnProperty('type') and other props
    //  which makes copying more difficult.
    // TODO: Probably best to create a whitelist of event props

    for (var key in old) {
      // Safari 6.0.3 warns you if you try to copy deprecated layerX/Y
      // Chrome warns you if you try to copy deprecated keyboardEvent.keyLocation
      // and webkitMovementX/Y
      if (key !== 'layerX' && key !== 'layerY' && key !== 'keyLocation' && key !== 'webkitMovementX' && key !== 'webkitMovementY') {
        // Chrome 32+ warns if you try to copy deprecated returnValue, but
        // we still want to if preventDefault isn't supported (IE8).
        if (!(key === 'returnValue' && old.preventDefault)) {
          event[key] = old[key];
        }
      }
    } // The event occurred on this element


    if (!event.target) {
      event.target = event.srcElement || document__default['default'];
    } // Handle which other element the event is related to


    if (!event.relatedTarget) {
      event.relatedTarget = event.fromElement === event.target ? event.toElement : event.fromElement;
    } // Stop the default browser action


    event.preventDefault = function () {
      if (old.preventDefault) {
        old.preventDefault();
      }

      event.returnValue = false;
      old.returnValue = false;
      event.defaultPrevented = true;
    };

    event.defaultPrevented = false; // Stop the event from bubbling

    event.stopPropagation = function () {
      if (old.stopPropagation) {
        old.stopPropagation();
      }

      event.cancelBubble = true;
      old.cancelBubble = true;
      event.isPropagationStopped = returnTrue;
    };

    event.isPropagationStopped = returnFalse; // Stop the event from bubbling and executing other handlers

    event.stopImmediatePropagation = function () {
      if (old.stopImmediatePropagation) {
        old.stopImmediatePropagation();
      }

      event.isImmediatePropagationStopped = returnTrue;
      event.stopPropagation();
    };

    event.isImmediatePropagationStopped = returnFalse; // Handle mouse position

    if (event.clientX !== null && event.clientX !== undefined) {
      var doc = document__default['default'].documentElement;
      var body = document__default['default'].body;
      event.pageX = event.clientX + (doc && doc.scrollLeft || body && body.scrollLeft || 0) - (doc && doc.clientLeft || body && body.clientLeft || 0);
      event.pageY = event.clientY + (doc && doc.scrollTop || body && body.scrollTop || 0) - (doc && doc.clientTop || body && body.clientTop || 0);
    } // Handle key presses


    event.which = event.charCode || event.keyCode; // Fix button for mouse clicks:
    // 0 == left; 1 == middle; 2 == right

    if (event.button !== null && event.button !== undefined) {
      // The following is disabled because it does not pass videojs-standard
      // and... yikes.

      /* eslint-disable */
      event.button = event.button & 1 ? 0 : event.button & 4 ? 1 : event.button & 2 ? 2 : 0;
      /* eslint-enable */
    }
  }

  event.fixed_ = true; // Returns fixed-up instance

  return event;
}
/**
 * Whether passive event listeners are supported
 */

var _supportsPassive;

var supportsPassive = function supportsPassive() {
  if (typeof _supportsPassive !== 'boolean') {
    _supportsPassive = false;

    try {
      var opts = Object.defineProperty({}, 'passive', {
        get: function get() {
          _supportsPassive = true;
        }
      });
      window__default['default'].addEventListener('test', null, opts);
      window__default['default'].removeEventListener('test', null, opts);
    } catch (e) {// disregard
    }
  }

  return _supportsPassive;
};
/**
 * Touch events Chrome expects to be passive
 */


var passiveEvents = ['touchstart', 'touchmove'];
/**
 * Add an event listener to element
 * It stores the handler function in a separate cache object
 * and adds a generic handler to the element's event,
 * along with a unique id (guid) to the element.
 *
 * @param {Element|Object} elem
 *        Element or object to bind listeners to
 *
 * @param {string|string[]} type
 *        Type of event to bind to.
 *
 * @param {EventTarget~EventListener} fn
 *        Event listener.
 */

function on(elem, type, fn) {
  if (Array.isArray(type)) {
    return _handleMultipleEvents(on, elem, type, fn);
  }

  if (!DomData.has(elem)) {
    DomData.set(elem, {});
  }

  var data = DomData.get(elem); // We need a place to store all our handler data

  if (!data.handlers) {
    data.handlers = {};
  }

  if (!data.handlers[type]) {
    data.handlers[type] = [];
  }

  if (!fn.guid) {
    fn.guid = newGUID();
  }

  data.handlers[type].push(fn);

  if (!data.dispatcher) {
    data.disabled = false;

    data.dispatcher = function (event, hash) {
      if (data.disabled) {
        return;
      }

      event = fixEvent(event);
      var handlers = data.handlers[event.type];

      if (handlers) {
        // Copy handlers so if handlers are added/removed during the process it doesn't throw everything off.
        var handlersCopy = handlers.slice(0);

        for (var m = 0, n = handlersCopy.length; m < n; m++) {
          if (event.isImmediatePropagationStopped()) {
            break;
          } else {
            try {
              handlersCopy[m].call(elem, event, hash);
            } catch (e) {
              log.error(e);
            }
          }
        }
      }
    };
  }

  if (data.handlers[type].length === 1) {
    if (elem.addEventListener) {
      var options = false;

      if (supportsPassive() && passiveEvents.indexOf(type) > -1) {
        options = {
          passive: true
        };
      }

      elem.addEventListener(type, data.dispatcher, options);
    } else if (elem.attachEvent) {
      elem.attachEvent('on' + type, data.dispatcher);
    }
  }
}
/**
 * Removes event listeners from an element
 *
 * @param {Element|Object} elem
 *        Object to remove listeners from.
 *
 * @param {string|string[]} [type]
 *        Type of listener to remove. Don't include to remove all events from element.
 *
 * @param {EventTarget~EventListener} [fn]
 *        Specific listener to remove. Don't include to remove listeners for an event
 *        type.
 */

function off(elem, type, fn) {
  // Don't want to add a cache object through getElData if not needed
  if (!DomData.has(elem)) {
    return;
  }

  var data = DomData.get(elem); // If no events exist, nothing to unbind

  if (!data.handlers) {
    return;
  }

  if (Array.isArray(type)) {
    return _handleMultipleEvents(off, elem, type, fn);
  } // Utility function


  var removeType = function removeType(el, t) {
    data.handlers[t] = [];

    _cleanUpEvents(el, t);
  }; // Are we removing all bound events?


  if (type === undefined) {
    for (var t in data.handlers) {
      if (Object.prototype.hasOwnProperty.call(data.handlers || {}, t)) {
        removeType(elem, t);
      }
    }

    return;
  }

  var handlers = data.handlers[type]; // If no handlers exist, nothing to unbind

  if (!handlers) {
    return;
  } // If no listener was provided, remove all listeners for type


  if (!fn) {
    removeType(elem, type);
    return;
  } // We're only removing a single handler


  if (fn.guid) {
    for (var n = 0; n < handlers.length; n++) {
      if (handlers[n].guid === fn.guid) {
        handlers.splice(n--, 1);
      }
    }
  }

  _cleanUpEvents(elem, type);
}
/**
 * Trigger an event for an element
 *
 * @param {Element|Object} elem
 *        Element to trigger an event on
 *
 * @param {EventTarget~Event|string} event
 *        A string (the type) or an event object with a type attribute
 *
 * @param {Object} [hash]
 *        data hash to pass along with the event
 *
 * @return {boolean|undefined}
 *         Returns the opposite of `defaultPrevented` if default was
 *         prevented. Otherwise, returns `undefined`
 */

function trigger(elem, event, hash) {
  // Fetches element data and a reference to the parent (for bubbling).
  // Don't want to add a data object to cache for every parent,
  // so checking hasElData first.
  var elemData = DomData.has(elem) ? DomData.get(elem) : {};
  var parent = elem.parentNode || elem.ownerDocument; // type = event.type || event,
  // handler;
  // If an event name was passed as a string, creates an event out of it

  if (typeof event === 'string') {
    event = {
      type: event,
      target: elem
    };
  } else if (!event.target) {
    event.target = elem;
  } // Normalizes the event properties.


  event = fixEvent(event); // If the passed element has a dispatcher, executes the established handlers.

  if (elemData.dispatcher) {
    elemData.dispatcher.call(elem, event, hash);
  } // Unless explicitly stopped or the event does not bubble (e.g. media events)
  // recursively calls this function to bubble the event up the DOM.


  if (parent && !event.isPropagationStopped() && event.bubbles === true) {
    trigger.call(null, parent, event, hash); // If at the top of the DOM, triggers the default action unless disabled.
  } else if (!parent && !event.defaultPrevented && event.target && event.target[event.type]) {
    if (!DomData.has(event.target)) {
      DomData.set(event.target, {});
    }

    var targetData = DomData.get(event.target); // Checks if the target has a default action for this event.

    if (event.target[event.type]) {
      // Temporarily disables event dispatching on the target as we have already executed the handler.
      targetData.disabled = true; // Executes the default action.

      if (typeof event.target[event.type] === 'function') {
        event.target[event.type]();
      } // Re-enables event dispatching.


      targetData.disabled = false;
    }
  } // Inform the triggerer if the default was prevented by returning false


  return !event.defaultPrevented;
}
/**
 * Trigger a listener only once for an event.
 *
 * @param {Element|Object} elem
 *        Element or object to bind to.
 *
 * @param {string|string[]} type
 *        Name/type of event
 *
 * @param {Event~EventListener} fn
 *        Event listener function
 */

function one(elem, type, fn) {
  if (Array.isArray(type)) {
    return _handleMultipleEvents(one, elem, type, fn);
  }

  var func = function func() {
    off(elem, type, func);
    fn.apply(this, arguments);
  }; // copy the guid to the new function so it can removed using the original function's ID


  func.guid = fn.guid = fn.guid || newGUID();
  on(elem, type, func);
}
/**
 * Trigger a listener only once and then turn if off for all
 * configured events
 *
 * @param {Element|Object} elem
 *        Element or object to bind to.
 *
 * @param {string|string[]} type
 *        Name/type of event
 *
 * @param {Event~EventListener} fn
 *        Event listener function
 */

function any(elem, type, fn) {
  var func = function func() {
    off(elem, type, func);
    fn.apply(this, arguments);
  }; // copy the guid to the new function so it can removed using the original function's ID


  func.guid = fn.guid = fn.guid || newGUID(); // multiple ons, but one off for everything

  on(elem, type, func);
}

var Events = /*#__PURE__*/Object.freeze({
  __proto__: null,
  fixEvent: fixEvent,
  on: on,
  off: off,
  trigger: trigger,
  one: one,
  any: any
});

/**
 * @file fn.js
 * @module fn
 */
var UPDATE_REFRESH_INTERVAL = 30;
/**
 * Bind (a.k.a proxy or context). A simple method for changing the context of
 * a function.
 *
 * It also stores a unique id on the function so it can be easily removed from
 * events.
 *
 * @function
 * @param    {Mixed} context
 *           The object to bind as scope.
 *
 * @param    {Function} fn
 *           The function to be bound to a scope.
 *
 * @param    {number} [uid]
 *           An optional unique ID for the function to be set
 *
 * @return   {Function}
 *           The new function that will be bound into the context given
 */

var bind = function bind(context, fn, uid) {
  // Make sure the function has a unique ID
  if (!fn.guid) {
    fn.guid = newGUID();
  } // Create the new function that changes the context


  var bound = fn.bind(context); // Allow for the ability to individualize this function
  // Needed in the case where multiple objects might share the same prototype
  // IF both items add an event listener with the same function, then you try to remove just one
  // it will remove both because they both have the same guid.
  // when using this, you need to use the bind method when you remove the listener as well.
  // currently used in text tracks

  bound.guid = uid ? uid + '_' + fn.guid : fn.guid;
  return bound;
};
/**
 * Wraps the given function, `fn`, with a new function that only invokes `fn`
 * at most once per every `wait` milliseconds.
 *
 * @function
 * @param    {Function} fn
 *           The function to be throttled.
 *
 * @param    {number}   wait
 *           The number of milliseconds by which to throttle.
 *
 * @return   {Function}
 */

var throttle = function throttle(fn, wait) {
  var last = window__default['default'].performance.now();

  var throttled = function throttled() {
    var now = window__default['default'].performance.now();

    if (now - last >= wait) {
      fn.apply(void 0, arguments);
      last = now;
    }
  };

  return throttled;
};
/**
 * Creates a debounced function that delays invoking `func` until after `wait`
 * milliseconds have elapsed since the last time the debounced function was
 * invoked.
 *
 * Inspired by lodash and underscore implementations.
 *
 * @function
 * @param    {Function} func
 *           The function to wrap with debounce behavior.
 *
 * @param    {number} wait
 *           The number of milliseconds to wait after the last invocation.
 *
 * @param    {boolean} [immediate]
 *           Whether or not to invoke the function immediately upon creation.
 *
 * @param    {Object} [context=window]
 *           The "context" in which the debounced function should debounce. For
 *           example, if this function should be tied to a Video.js player,
 *           the player can be passed here. Alternatively, defaults to the
 *           global `window` object.
 *
 * @return   {Function}
 *           A debounced function.
 */

var debounce = function debounce(func, wait, immediate, context) {
  if (context === void 0) {
    context = window__default['default'];
  }

  var timeout;

  var cancel = function cancel() {
    context.clearTimeout(timeout);
    timeout = null;
  };
  /* eslint-disable consistent-this */


  var debounced = function debounced() {
    var self = this;
    var args = arguments;

    var _later = function later() {
      timeout = null;
      _later = null;

      if (!immediate) {
        func.apply(self, args);
      }
    };

    if (!timeout && immediate) {
      func.apply(self, args);
    }

    context.clearTimeout(timeout);
    timeout = context.setTimeout(_later, wait);
  };
  /* eslint-enable consistent-this */


  debounced.cancel = cancel;
  return debounced;
};

/**
 * @file src/js/event-target.js
 */
/**
 * `EventTarget` is a class that can have the same API as the DOM `EventTarget`. It
 * adds shorthand functions that wrap around lengthy functions. For example:
 * the `on` function is a wrapper around `addEventListener`.
 *
 * @see [EventTarget Spec]{@link https://www.w3.org/TR/DOM-Level-2-Events/events.html#Events-EventTarget}
 * @class EventTarget
 */

var EventTarget = function EventTarget() {};
/**
 * A Custom DOM event.
 *
 * @typedef {Object} EventTarget~Event
 * @see [Properties]{@link https://developer.mozilla.org/en-US/docs/Web/API/CustomEvent}
 */

/**
 * All event listeners should follow the following format.
 *
 * @callback EventTarget~EventListener
 * @this {EventTarget}
 *
 * @param {EventTarget~Event} event
 *        the event that triggered this function
 *
 * @param {Object} [hash]
 *        hash of data sent during the event
 */

/**
 * An object containing event names as keys and booleans as values.
 *
 * > NOTE: If an event name is set to a true value here {@link EventTarget#trigger}
 *         will have extra functionality. See that function for more information.
 *
 * @property EventTarget.prototype.allowedEvents_
 * @private
 */


EventTarget.prototype.allowedEvents_ = {};
/**
 * Adds an `event listener` to an instance of an `EventTarget`. An `event listener` is a
 * function that will get called when an event with a certain name gets triggered.
 *
 * @param {string|string[]} type
 *        An event name or an array of event names.
 *
 * @param {EventTarget~EventListener} fn
 *        The function to call with `EventTarget`s
 */

EventTarget.prototype.on = function (type, fn) {
  // Remove the addEventListener alias before calling Events.on
  // so we don't get into an infinite type loop
  var ael = this.addEventListener;

  this.addEventListener = function () {};

  on(this, type, fn);
  this.addEventListener = ael;
};
/**
 * An alias of {@link EventTarget#on}. Allows `EventTarget` to mimic
 * the standard DOM API.
 *
 * @function
 * @see {@link EventTarget#on}
 */


EventTarget.prototype.addEventListener = EventTarget.prototype.on;
/**
 * Removes an `event listener` for a specific event from an instance of `EventTarget`.
 * This makes it so that the `event listener` will no longer get called when the
 * named event happens.
 *
 * @param {string|string[]} type
 *        An event name or an array of event names.
 *
 * @param {EventTarget~EventListener} fn
 *        The function to remove.
 */

EventTarget.prototype.off = function (type, fn) {
  off(this, type, fn);
};
/**
 * An alias of {@link EventTarget#off}. Allows `EventTarget` to mimic
 * the standard DOM API.
 *
 * @function
 * @see {@link EventTarget#off}
 */


EventTarget.prototype.removeEventListener = EventTarget.prototype.off;
/**
 * This function will add an `event listener` that gets triggered only once. After the
 * first trigger it will get removed. This is like adding an `event listener`
 * with {@link EventTarget#on} that calls {@link EventTarget#off} on itself.
 *
 * @param {string|string[]} type
 *        An event name or an array of event names.
 *
 * @param {EventTarget~EventListener} fn
 *        The function to be called once for each event name.
 */

EventTarget.prototype.one = function (type, fn) {
  // Remove the addEventListener aliasing Events.on
  // so we don't get into an infinite type loop
  var ael = this.addEventListener;

  this.addEventListener = function () {};

  one(this, type, fn);
  this.addEventListener = ael;
};

EventTarget.prototype.any = function (type, fn) {
  // Remove the addEventListener aliasing Events.on
  // so we don't get into an infinite type loop
  var ael = this.addEventListener;

  this.addEventListener = function () {};

  any(this, type, fn);
  this.addEventListener = ael;
};
/**
 * This function causes an event to happen. This will then cause any `event listeners`
 * that are waiting for that event, to get called. If there are no `event listeners`
 * for an event then nothing will happen.
 *
 * If the name of the `Event` that is being triggered is in `EventTarget.allowedEvents_`.
 * Trigger will also call the `on` + `uppercaseEventName` function.
 *
 * Example:
 * 'click' is in `EventTarget.allowedEvents_`, so, trigger will attempt to call
 * `onClick` if it exists.
 *
 * @param {string|EventTarget~Event|Object} event
 *        The name of the event, an `Event`, or an object with a key of type set to
 *        an event name.
 */


EventTarget.prototype.trigger = function (event) {
  var type = event.type || event; // deprecation
  // In a future version we should default target to `this`
  // similar to how we default the target to `elem` in
  // `Events.trigger`. Right now the default `target` will be
  // `document` due to the `Event.fixEvent` call.

  if (typeof event === 'string') {
    event = {
      type: type
    };
  }

  event = fixEvent(event);

  if (this.allowedEvents_[type] && this['on' + type]) {
    this['on' + type](event);
  }

  trigger(this, event);
};
/**
 * An alias of {@link EventTarget#trigger}. Allows `EventTarget` to mimic
 * the standard DOM API.
 *
 * @function
 * @see {@link EventTarget#trigger}
 */


EventTarget.prototype.dispatchEvent = EventTarget.prototype.trigger;
var EVENT_MAP;

EventTarget.prototype.queueTrigger = function (event) {
  var _this = this;

  // only set up EVENT_MAP if it'll be used
  if (!EVENT_MAP) {
    EVENT_MAP = new Map();
  }

  var type = event.type || event;
  var map = EVENT_MAP.get(this);

  if (!map) {
    map = new Map();
    EVENT_MAP.set(this, map);
  }

  var oldTimeout = map.get(type);
  map["delete"](type);
  window__default['default'].clearTimeout(oldTimeout);
  var timeout = window__default['default'].setTimeout(function () {
    // if we cleared out all timeouts for the current target, delete its map
    if (map.size === 0) {
      map = null;
      EVENT_MAP["delete"](_this);
    }

    _this.trigger(event);
  }, 0);
  map.set(type, timeout);
};

/**
 * @file mixins/evented.js
 * @module evented
 */

var objName = function objName(obj) {
  if (typeof obj.name === 'function') {
    return obj.name();
  }

  if (typeof obj.name === 'string') {
    return obj.name;
  }

  if (obj.name_) {
    return obj.name_;
  }

  if (obj.constructor && obj.constructor.name) {
    return obj.constructor.name;
  }

  return typeof obj;
};
/**
 * Returns whether or not an object has had the evented mixin applied.
 *
 * @param  {Object} object
 *         An object to test.
 *
 * @return {boolean}
 *         Whether or not the object appears to be evented.
 */


var isEvented = function isEvented(object) {
  return object instanceof EventTarget || !!object.eventBusEl_ && ['on', 'one', 'off', 'trigger'].every(function (k) {
    return typeof object[k] === 'function';
  });
};
/**
 * Adds a callback to run after the evented mixin applied.
 *
 * @param  {Object} object
 *         An object to Add
 * @param  {Function} callback
 *         The callback to run.
 */


var addEventedCallback = function addEventedCallback(target, callback) {
  if (isEvented(target)) {
    callback();
  } else {
    if (!target.eventedCallbacks) {
      target.eventedCallbacks = [];
    }

    target.eventedCallbacks.push(callback);
  }
};
/**
 * Whether a value is a valid event type - non-empty string or array.
 *
 * @private
 * @param  {string|Array} type
 *         The type value to test.
 *
 * @return {boolean}
 *         Whether or not the type is a valid event type.
 */


var isValidEventType = function isValidEventType(type) {
  return (// The regex here verifies that the `type` contains at least one non-
    // whitespace character.
    typeof type === 'string' && /\S/.test(type) || Array.isArray(type) && !!type.length
  );
};
/**
 * Validates a value to determine if it is a valid event target. Throws if not.
 *
 * @private
 * @throws {Error}
 *         If the target does not appear to be a valid event target.
 *
 * @param  {Object} target
 *         The object to test.
 *
 * @param  {Object} obj
 *         The evented object we are validating for
 *
 * @param  {string} fnName
 *         The name of the evented mixin function that called this.
 */


var validateTarget = function validateTarget(target, obj, fnName) {
  if (!target || !target.nodeName && !isEvented(target)) {
    throw new Error("Invalid target for " + objName(obj) + "#" + fnName + "; must be a DOM node or evented object.");
  }
};
/**
 * Validates a value to determine if it is a valid event target. Throws if not.
 *
 * @private
 * @throws {Error}
 *         If the type does not appear to be a valid event type.
 *
 * @param  {string|Array} type
 *         The type to test.
 *
 * @param  {Object} obj
*         The evented object we are validating for
 *
 * @param  {string} fnName
 *         The name of the evented mixin function that called this.
 */


var validateEventType = function validateEventType(type, obj, fnName) {
  if (!isValidEventType(type)) {
    throw new Error("Invalid event type for " + objName(obj) + "#" + fnName + "; must be a non-empty string or array.");
  }
};
/**
 * Validates a value to determine if it is a valid listener. Throws if not.
 *
 * @private
 * @throws {Error}
 *         If the listener is not a function.
 *
 * @param  {Function} listener
 *         The listener to test.
 *
 * @param  {Object} obj
 *         The evented object we are validating for
 *
 * @param  {string} fnName
 *         The name of the evented mixin function that called this.
 */


var validateListener = function validateListener(listener, obj, fnName) {
  if (typeof listener !== 'function') {
    throw new Error("Invalid listener for " + objName(obj) + "#" + fnName + "; must be a function.");
  }
};
/**
 * Takes an array of arguments given to `on()` or `one()`, validates them, and
 * normalizes them into an object.
 *
 * @private
 * @param  {Object} self
 *         The evented object on which `on()` or `one()` was called. This
 *         object will be bound as the `this` value for the listener.
 *
 * @param  {Array} args
 *         An array of arguments passed to `on()` or `one()`.
 *
 * @param  {string} fnName
 *         The name of the evented mixin function that called this.
 *
 * @return {Object}
 *         An object containing useful values for `on()` or `one()` calls.
 */


var normalizeListenArgs = function normalizeListenArgs(self, args, fnName) {
  // If the number of arguments is less than 3, the target is always the
  // evented object itself.
  var isTargetingSelf = args.length < 3 || args[0] === self || args[0] === self.eventBusEl_;
  var target;
  var type;
  var listener;

  if (isTargetingSelf) {
    target = self.eventBusEl_; // Deal with cases where we got 3 arguments, but we are still listening to
    // the evented object itself.

    if (args.length >= 3) {
      args.shift();
    }

    type = args[0];
    listener = args[1];
  } else {
    target = args[0];
    type = args[1];
    listener = args[2];
  }

  validateTarget(target, self, fnName);
  validateEventType(type, self, fnName);
  validateListener(listener, self, fnName);
  listener = bind(self, listener);
  return {
    isTargetingSelf: isTargetingSelf,
    target: target,
    type: type,
    listener: listener
  };
};
/**
 * Adds the listener to the event type(s) on the target, normalizing for
 * the type of target.
 *
 * @private
 * @param  {Element|Object} target
 *         A DOM node or evented object.
 *
 * @param  {string} method
 *         The event binding method to use ("on" or "one").
 *
 * @param  {string|Array} type
 *         One or more event type(s).
 *
 * @param  {Function} listener
 *         A listener function.
 */


var listen = function listen(target, method, type, listener) {
  validateTarget(target, target, method);

  if (target.nodeName) {
    Events[method](target, type, listener);
  } else {
    target[method](type, listener);
  }
};
/**
 * Contains methods that provide event capabilities to an object which is passed
 * to {@link module:evented|evented}.
 *
 * @mixin EventedMixin
 */


var EventedMixin = {
  /**
   * Add a listener to an event (or events) on this object or another evented
   * object.
   *
   * @param  {string|Array|Element|Object} targetOrType
   *         If this is a string or array, it represents the event type(s)
   *         that will trigger the listener.
   *
   *         Another evented object can be passed here instead, which will
   *         cause the listener to listen for events on _that_ object.
   *
   *         In either case, the listener's `this` value will be bound to
   *         this object.
   *
   * @param  {string|Array|Function} typeOrListener
   *         If the first argument was a string or array, this should be the
   *         listener function. Otherwise, this is a string or array of event
   *         type(s).
   *
   * @param  {Function} [listener]
   *         If the first argument was another evented object, this will be
   *         the listener function.
   */
  on: function on() {
    var _this = this;

    for (var _len = arguments.length, args = new Array(_len), _key = 0; _key < _len; _key++) {
      args[_key] = arguments[_key];
    }

    var _normalizeListenArgs = normalizeListenArgs(this, args, 'on'),
        isTargetingSelf = _normalizeListenArgs.isTargetingSelf,
        target = _normalizeListenArgs.target,
        type = _normalizeListenArgs.type,
        listener = _normalizeListenArgs.listener;

    listen(target, 'on', type, listener); // If this object is listening to another evented object.

    if (!isTargetingSelf) {
      // If this object is disposed, remove the listener.
      var removeListenerOnDispose = function removeListenerOnDispose() {
        return _this.off(target, type, listener);
      }; // Use the same function ID as the listener so we can remove it later it
      // using the ID of the original listener.


      removeListenerOnDispose.guid = listener.guid; // Add a listener to the target's dispose event as well. This ensures
      // that if the target is disposed BEFORE this object, we remove the
      // removal listener that was just added. Otherwise, we create a memory leak.

      var removeRemoverOnTargetDispose = function removeRemoverOnTargetDispose() {
        return _this.off('dispose', removeListenerOnDispose);
      }; // Use the same function ID as the listener so we can remove it later
      // it using the ID of the original listener.


      removeRemoverOnTargetDispose.guid = listener.guid;
      listen(this, 'on', 'dispose', removeListenerOnDispose);
      listen(target, 'on', 'dispose', removeRemoverOnTargetDispose);
    }
  },

  /**
   * Add a listener to an event (or events) on this object or another evented
   * object. The listener will be called once per event and then removed.
   *
   * @param  {string|Array|Element|Object} targetOrType
   *         If this is a string or array, it represents the event type(s)
   *         that will trigger the listener.
   *
   *         Another evented object can be passed here instead, which will
   *         cause the listener to listen for events on _that_ object.
   *
   *         In either case, the listener's `this` value will be bound to
   *         this object.
   *
   * @param  {string|Array|Function} typeOrListener
   *         If the first argument was a string or array, this should be the
   *         listener function. Otherwise, this is a string or array of event
   *         type(s).
   *
   * @param  {Function} [listener]
   *         If the first argument was another evented object, this will be
   *         the listener function.
   */
  one: function one() {
    var _this2 = this;

    for (var _len2 = arguments.length, args = new Array(_len2), _key2 = 0; _key2 < _len2; _key2++) {
      args[_key2] = arguments[_key2];
    }

    var _normalizeListenArgs2 = normalizeListenArgs(this, args, 'one'),
        isTargetingSelf = _normalizeListenArgs2.isTargetingSelf,
        target = _normalizeListenArgs2.target,
        type = _normalizeListenArgs2.type,
        listener = _normalizeListenArgs2.listener; // Targeting this evented object.


    if (isTargetingSelf) {
      listen(target, 'one', type, listener); // Targeting another evented object.
    } else {
      // TODO: This wrapper is incorrect! It should only
      //       remove the wrapper for the event type that called it.
      //       Instead all listners are removed on the first trigger!
      //       see https://github.com/videojs/video.js/issues/5962
      var wrapper = function wrapper() {
        _this2.off(target, type, wrapper);

        for (var _len3 = arguments.length, largs = new Array(_len3), _key3 = 0; _key3 < _len3; _key3++) {
          largs[_key3] = arguments[_key3];
        }

        listener.apply(null, largs);
      }; // Use the same function ID as the listener so we can remove it later
      // it using the ID of the original listener.


      wrapper.guid = listener.guid;
      listen(target, 'one', type, wrapper);
    }
  },

  /**
   * Add a listener to an event (or events) on this object or another evented
   * object. The listener will only be called once for the first event that is triggered
   * then removed.
   *
   * @param  {string|Array|Element|Object} targetOrType
   *         If this is a string or array, it represents the event type(s)
   *         that will trigger the listener.
   *
   *         Another evented object can be passed here instead, which will
   *         cause the listener to listen for events on _that_ object.
   *
   *         In either case, the listener's `this` value will be bound to
   *         this object.
   *
   * @param  {string|Array|Function} typeOrListener
   *         If the first argument was a string or array, this should be the
   *         listener function. Otherwise, this is a string or array of event
   *         type(s).
   *
   * @param  {Function} [listener]
   *         If the first argument was another evented object, this will be
   *         the listener function.
   */
  any: function any() {
    var _this3 = this;

    for (var _len4 = arguments.length, args = new Array(_len4), _key4 = 0; _key4 < _len4; _key4++) {
      args[_key4] = arguments[_key4];
    }

    var _normalizeListenArgs3 = normalizeListenArgs(this, args, 'any'),
        isTargetingSelf = _normalizeListenArgs3.isTargetingSelf,
        target = _normalizeListenArgs3.target,
        type = _normalizeListenArgs3.type,
        listener = _normalizeListenArgs3.listener; // Targeting this evented object.


    if (isTargetingSelf) {
      listen(target, 'any', type, listener); // Targeting another evented object.
    } else {
      var wrapper = function wrapper() {
        _this3.off(target, type, wrapper);

        for (var _len5 = arguments.length, largs = new Array(_len5), _key5 = 0; _key5 < _len5; _key5++) {
          largs[_key5] = arguments[_key5];
        }

        listener.apply(null, largs);
      }; // Use the same function ID as the listener so we can remove it later
      // it using the ID of the original listener.


      wrapper.guid = listener.guid;
      listen(target, 'any', type, wrapper);
    }
  },

  /**
   * Removes listener(s) from event(s) on an evented object.
   *
   * @param  {string|Array|Element|Object} [targetOrType]
   *         If this is a string or array, it represents the event type(s).
   *
   *         Another evented object can be passed here instead, in which case
   *         ALL 3 arguments are _required_.
   *
   * @param  {string|Array|Function} [typeOrListener]
   *         If the first argument was a string or array, this may be the
   *         listener function. Otherwise, this is a string or array of event
   *         type(s).
   *
   * @param  {Function} [listener]
   *         If the first argument was another evented object, this will be
   *         the listener function; otherwise, _all_ listeners bound to the
   *         event type(s) will be removed.
   */
  off: function off$1(targetOrType, typeOrListener, listener) {
    // Targeting this evented object.
    if (!targetOrType || isValidEventType(targetOrType)) {
      off(this.eventBusEl_, targetOrType, typeOrListener); // Targeting another evented object.
    } else {
      var target = targetOrType;
      var type = typeOrListener; // Fail fast and in a meaningful way!

      validateTarget(target, this, 'off');
      validateEventType(type, this, 'off');
      validateListener(listener, this, 'off'); // Ensure there's at least a guid, even if the function hasn't been used

      listener = bind(this, listener); // Remove the dispose listener on this evented object, which was given
      // the same guid as the event listener in on().

      this.off('dispose', listener);

      if (target.nodeName) {
        off(target, type, listener);
        off(target, 'dispose', listener);
      } else if (isEvented(target)) {
        target.off(type, listener);
        target.off('dispose', listener);
      }
    }
  },

  /**
   * Fire an event on this evented object, causing its listeners to be called.
   *
   * @param   {string|Object} event
   *          An event type or an object with a type property.
   *
   * @param   {Object} [hash]
   *          An additional object to pass along to listeners.
   *
   * @return {boolean}
   *          Whether or not the default behavior was prevented.
   */
  trigger: function trigger$1(event, hash) {
    validateTarget(this.eventBusEl_, this, 'trigger');
    var type = event && typeof event !== 'string' ? event.type : event;

    if (!isValidEventType(type)) {
      var error = "Invalid event type for " + objName(this) + "#trigger; " + 'must be a non-empty string or object with a type key that has a non-empty value.';

      if (event) {
        (this.log || log).error(error);
      } else {
        throw new Error(error);
      }
    }

    return trigger(this.eventBusEl_, event, hash);
  }
};
/**
 * Applies {@link module:evented~EventedMixin|EventedMixin} to a target object.
 *
 * @param  {Object} target
 *         The object to which to add event methods.
 *
 * @param  {Object} [options={}]
 *         Options for customizing the mixin behavior.
 *
 * @param  {string} [options.eventBusKey]
 *         By default, adds a `eventBusEl_` DOM element to the target object,
 *         which is used as an event bus. If the target object already has a
 *         DOM element that should be used, pass its key here.
 *
 * @return {Object}
 *         The target object.
 */

function evented(target, options) {
  if (options === void 0) {
    options = {};
  }

  var _options = options,
      eventBusKey = _options.eventBusKey; // Set or create the eventBusEl_.

  if (eventBusKey) {
    if (!target[eventBusKey].nodeName) {
      throw new Error("The eventBusKey \"" + eventBusKey + "\" does not refer to an element.");
    }

    target.eventBusEl_ = target[eventBusKey];
  } else {
    target.eventBusEl_ = createEl('span', {
      className: 'vjs-event-bus'
    });
  }

  assign(target, EventedMixin);

  if (target.eventedCallbacks) {
    target.eventedCallbacks.forEach(function (callback) {
      callback();
    });
  } // When any evented object is disposed, it removes all its listeners.


  target.on('dispose', function () {
    target.off();
    [target, target.el_, target.eventBusEl_].forEach(function (val) {
      if (val && DomData.has(val)) {
        DomData["delete"](val);
      }
    });
    window__default['default'].setTimeout(function () {
      target.eventBusEl_ = null;
    }, 0);
  });
  return target;
}

/**
 * @file mixins/stateful.js
 * @module stateful
 */
/**
 * Contains methods that provide statefulness to an object which is passed
 * to {@link module:stateful}.
 *
 * @mixin StatefulMixin
 */

var StatefulMixin = {
  /**
   * A hash containing arbitrary keys and values representing the state of
   * the object.
   *
   * @type {Object}
   */
  state: {},

  /**
   * Set the state of an object by mutating its
   * {@link module:stateful~StatefulMixin.state|state} object in place.
   *
   * @fires   module:stateful~StatefulMixin#statechanged
   * @param   {Object|Function} stateUpdates
   *          A new set of properties to shallow-merge into the plugin state.
   *          Can be a plain object or a function returning a plain object.
   *
   * @return {Object|undefined}
   *          An object containing changes that occurred. If no changes
   *          occurred, returns `undefined`.
   */
  setState: function setState(stateUpdates) {
    var _this = this;

    // Support providing the `stateUpdates` state as a function.
    if (typeof stateUpdates === 'function') {
      stateUpdates = stateUpdates();
    }

    var changes;
    each(stateUpdates, function (value, key) {
      // Record the change if the value is different from what's in the
      // current state.
      if (_this.state[key] !== value) {
        changes = changes || {};
        changes[key] = {
          from: _this.state[key],
          to: value
        };
      }

      _this.state[key] = value;
    }); // Only trigger "statechange" if there were changes AND we have a trigger
    // function. This allows us to not require that the target object be an
    // evented object.

    if (changes && isEvented(this)) {
      /**
       * An event triggered on an object that is both
       * {@link module:stateful|stateful} and {@link module:evented|evented}
       * indicating that its state has changed.
       *
       * @event    module:stateful~StatefulMixin#statechanged
       * @type     {Object}
       * @property {Object} changes
       *           A hash containing the properties that were changed and
       *           the values they were changed `from` and `to`.
       */
      this.trigger({
        changes: changes,
        type: 'statechanged'
      });
    }

    return changes;
  }
};
/**
 * Applies {@link module:stateful~StatefulMixin|StatefulMixin} to a target
 * object.
 *
 * If the target object is {@link module:evented|evented} and has a
 * `handleStateChanged` method, that method will be automatically bound to the
 * `statechanged` event on itself.
 *
 * @param   {Object} target
 *          The object to be made stateful.
 *
 * @param   {Object} [defaultState]
 *          A default set of properties to populate the newly-stateful object's
 *          `state` property.
 *
 * @return {Object}
 *          Returns the `target`.
 */

function stateful(target, defaultState) {
  assign(target, StatefulMixin); // This happens after the mixing-in because we need to replace the `state`
  // added in that step.

  target.state = assign({}, target.state, defaultState); // Auto-bind the `handleStateChanged` method of the target object if it exists.

  if (typeof target.handleStateChanged === 'function' && isEvented(target)) {
    target.on('statechanged', target.handleStateChanged);
  }

  return target;
}

/**
 * @file string-cases.js
 * @module to-lower-case
 */

/**
 * Lowercase the first letter of a string.
 *
 * @param {string} string
 *        String to be lowercased
 *
 * @return {string}
 *         The string with a lowercased first letter
 */
var toLowerCase = function toLowerCase(string) {
  if (typeof string !== 'string') {
    return string;
  }

  return string.replace(/./, function (w) {
    return w.toLowerCase();
  });
};
/**
 * Uppercase the first letter of a string.
 *
 * @param {string} string
 *        String to be uppercased
 *
 * @return {string}
 *         The string with an uppercased first letter
 */

var toTitleCase = function toTitleCase(string) {
  if (typeof string !== 'string') {
    return string;
  }

  return string.replace(/./, function (w) {
    return w.toUpperCase();
  });
};
/**
 * Compares the TitleCase versions of the two strings for equality.
 *
 * @param {string} str1
 *        The first string to compare
 *
 * @param {string} str2
 *        The second string to compare
 *
 * @return {boolean}
 *         Whether the TitleCase versions of the strings are equal
 */

var titleCaseEquals = function titleCaseEquals(str1, str2) {
  return toTitleCase(str1) === toTitleCase(str2);
};

/**
 * @file merge-options.js
 * @module merge-options
 */
/**
 * Merge two objects recursively.
 *
 * Performs a deep merge like
 * {@link https://lodash.com/docs/4.17.10#merge|lodash.merge}, but only merges
 * plain objects (not arrays, elements, or anything else).
 *
 * Non-plain object values will be copied directly from the right-most
 * argument.
 *
 * @static
 * @param   {Object[]} sources
 *          One or more objects to merge into a new object.
 *
 * @return {Object}
 *          A new object that is the merged result of all sources.
 */

function mergeOptions() {
  var result = {};

  for (var _len = arguments.length, sources = new Array(_len), _key = 0; _key < _len; _key++) {
    sources[_key] = arguments[_key];
  }

  sources.forEach(function (source) {
    if (!source) {
      return;
    }

    each(source, function (value, key) {
      if (!isPlain(value)) {
        result[key] = value;
        return;
      }

      if (!isPlain(result[key])) {
        result[key] = {};
      }

      result[key] = mergeOptions(result[key], value);
    });
  });
  return result;
}

var MapSham = /*#__PURE__*/function () {
  function MapSham() {
    this.map_ = {};
  }

  var _proto = MapSham.prototype;

  _proto.has = function has(key) {
    return key in this.map_;
  };

  _proto["delete"] = function _delete(key) {
    var has = this.has(key);
    delete this.map_[key];
    return has;
  };

  _proto.set = function set(key, value) {
    this.map_[key] = value;
    return this;
  };

  _proto.forEach = function forEach(callback, thisArg) {
    for (var key in this.map_) {
      callback.call(thisArg, this.map_[key], key, this);
    }
  };

  return MapSham;
}();

var Map$1 = window__default['default'].Map ? window__default['default'].Map : MapSham;

var SetSham = /*#__PURE__*/function () {
  function SetSham() {
    this.set_ = {};
  }

  var _proto = SetSham.prototype;

  _proto.has = function has(key) {
    return key in this.set_;
  };

  _proto["delete"] = function _delete(key) {
    var has = this.has(key);
    delete this.set_[key];
    return has;
  };

  _proto.add = function add(key) {
    this.set_[key] = 1;
    return this;
  };

  _proto.forEach = function forEach(callback, thisArg) {
    for (var key in this.set_) {
      callback.call(thisArg, key, key, this);
    }
  };

  return SetSham;
}();

var Set = window__default['default'].Set ? window__default['default'].Set : SetSham;

/**
 * Player Component - Base class for all UI objects
 *
 * @file component.js
 */
/**
 * Base class for all UI Components.
 * Components are UI objects which represent both a javascript object and an element
 * in the DOM. They can be children of other components, and can have
 * children themselves.
 *
 * Components can also use methods from {@link EventTarget}
 */

var Component = /*#__PURE__*/function () {
  /**
   * A callback that is called when a component is ready. Does not have any
   * paramters and any callback value will be ignored.
   *
   * @callback Component~ReadyCallback
   * @this Component
   */

  /**
   * Creates an instance of this class.
   *
   * @param {Player} player
   *        The `Player` that this class should be attached to.
   *
   * @param {Object} [options]
   *        The key/value store of player options.
   *
   * @param {Object[]} [options.children]
   *        An array of children objects to intialize this component with. Children objects have
   *        a name property that will be used if more than one component of the same type needs to be
   *        added.
   *
   * @param {Component~ReadyCallback} [ready]
   *        Function that gets called when the `Component` is ready.
   */
  function Component(player, options, ready) {
    // The component might be the player itself and we can't pass `this` to super
    if (!player && this.play) {
      this.player_ = player = this; // eslint-disable-line
    } else {
      this.player_ = player;
    }

    this.isDisposed_ = false; // Hold the reference to the parent component via `addChild` method

    this.parentComponent_ = null; // Make a copy of prototype.options_ to protect against overriding defaults

    this.options_ = mergeOptions({}, this.options_); // Updated options with supplied options

    options = this.options_ = mergeOptions(this.options_, options); // Get ID from options or options element if one is supplied

    this.id_ = options.id || options.el && options.el.id; // If there was no ID from the options, generate one

    if (!this.id_) {
      // Don't require the player ID function in the case of mock players
      var id = player && player.id && player.id() || 'no_player';
      this.id_ = id + "_component_" + newGUID();
    }

    this.name_ = options.name || null; // Create element if one wasn't provided in options

    if (options.el) {
      this.el_ = options.el;
    } else if (options.createEl !== false) {
      this.el_ = this.createEl();
    } // if evented is anything except false, we want to mixin in evented


    if (options.evented !== false) {
      // Make this an evented object and use `el_`, if available, as its event bus
      evented(this, {
        eventBusKey: this.el_ ? 'el_' : null
      });
      this.handleLanguagechange = this.handleLanguagechange.bind(this);
      this.on(this.player_, 'languagechange', this.handleLanguagechange);
    }

    stateful(this, this.constructor.defaultState);
    this.children_ = [];
    this.childIndex_ = {};
    this.childNameIndex_ = {};
    this.setTimeoutIds_ = new Set();
    this.setIntervalIds_ = new Set();
    this.rafIds_ = new Set();
    this.namedRafs_ = new Map$1();
    this.clearingTimersOnDispose_ = false; // Add any child components in options

    if (options.initChildren !== false) {
      this.initChildren();
    } // Don't want to trigger ready here or it will go before init is actually
    // finished for all children that run this constructor


    this.ready(ready);

    if (options.reportTouchActivity !== false) {
      this.enableTouchActivity();
    }
  }
  /**
   * Dispose of the `Component` and all child components.
   *
   * @fires Component#dispose
   */


  var _proto = Component.prototype;

  _proto.dispose = function dispose() {
    // Bail out if the component has already been disposed.
    if (this.isDisposed_) {
      return;
    }

    if (this.readyQueue_) {
      this.readyQueue_.length = 0;
    }
    /**
     * Triggered when a `Component` is disposed.
     *
     * @event Component#dispose
     * @type {EventTarget~Event}
     *
     * @property {boolean} [bubbles=false]
     *           set to false so that the dispose event does not
     *           bubble up
     */


    this.trigger({
      type: 'dispose',
      bubbles: false
    });
    this.isDisposed_ = true; // Dispose all children.

    if (this.children_) {
      for (var i = this.children_.length - 1; i >= 0; i--) {
        if (this.children_[i].dispose) {
          this.children_[i].dispose();
        }
      }
    } // Delete child references


    this.children_ = null;
    this.childIndex_ = null;
    this.childNameIndex_ = null;
    this.parentComponent_ = null;

    if (this.el_) {
      // Remove element from DOM
      if (this.el_.parentNode) {
        this.el_.parentNode.removeChild(this.el_);
      }

      this.el_ = null;
    } // remove reference to the player after disposing of the element


    this.player_ = null;
  }
  /**
   * Determine whether or not this component has been disposed.
   *
   * @return {boolean}
   *         If the component has been disposed, will be `true`. Otherwise, `false`.
   */
  ;

  _proto.isDisposed = function isDisposed() {
    return Boolean(this.isDisposed_);
  }
  /**
   * Return the {@link Player} that the `Component` has attached to.
   *
   * @return {Player}
   *         The player that this `Component` has attached to.
   */
  ;

  _proto.player = function player() {
    return this.player_;
  }
  /**
   * Deep merge of options objects with new options.
   * > Note: When both `obj` and `options` contain properties whose values are objects.
   *         The two properties get merged using {@link module:mergeOptions}
   *
   * @param {Object} obj
   *        The object that contains new options.
   *
   * @return {Object}
   *         A new object of `this.options_` and `obj` merged together.
   */
  ;

  _proto.options = function options(obj) {
    if (!obj) {
      return this.options_;
    }

    this.options_ = mergeOptions(this.options_, obj);
    return this.options_;
  }
  /**
   * Get the `Component`s DOM element
   *
   * @return {Element}
   *         The DOM element for this `Component`.
   */
  ;

  _proto.el = function el() {
    return this.el_;
  }
  /**
   * Create the `Component`s DOM element.
   *
   * @param {string} [tagName]
   *        Element's DOM node type. e.g. 'div'
   *
   * @param {Object} [properties]
   *        An object of properties that should be set.
   *
   * @param {Object} [attributes]
   *        An object of attributes that should be set.
   *
   * @return {Element}
   *         The element that gets created.
   */
  ;

  _proto.createEl = function createEl$1(tagName, properties, attributes) {
    return createEl(tagName, properties, attributes);
  }
  /**
   * Localize a string given the string in english.
   *
   * If tokens are provided, it'll try and run a simple token replacement on the provided string.
   * The tokens it looks for look like `{1}` with the index being 1-indexed into the tokens array.
   *
   * If a `defaultValue` is provided, it'll use that over `string`,
   * if a value isn't found in provided language files.
   * This is useful if you want to have a descriptive key for token replacement
   * but have a succinct localized string and not require `en.json` to be included.
   *
   * Currently, it is used for the progress bar timing.
   * ```js
   * {
   *   "progress bar timing: currentTime={1} duration={2}": "{1} of {2}"
   * }
   * ```
   * It is then used like so:
   * ```js
   * this.localize('progress bar timing: currentTime={1} duration{2}',
   *               [this.player_.currentTime(), this.player_.duration()],
   *               '{1} of {2}');
   * ```
   *
   * Which outputs something like: `01:23 of 24:56`.
   *
   *
   * @param {string} string
   *        The string to localize and the key to lookup in the language files.
   * @param {string[]} [tokens]
   *        If the current item has token replacements, provide the tokens here.
   * @param {string} [defaultValue]
   *        Defaults to `string`. Can be a default value to use for token replacement
   *        if the lookup key is needed to be separate.
   *
   * @return {string}
   *         The localized string or if no localization exists the english string.
   */
  ;

  _proto.localize = function localize(string, tokens, defaultValue) {
    if (defaultValue === void 0) {
      defaultValue = string;
    }

    var code = this.player_.language && this.player_.language();
    var languages = this.player_.languages && this.player_.languages();
    var language = languages && languages[code];
    var primaryCode = code && code.split('-')[0];
    var primaryLang = languages && languages[primaryCode];
    var localizedString = defaultValue;

    if (language && language[string]) {
      localizedString = language[string];
    } else if (primaryLang && primaryLang[string]) {
      localizedString = primaryLang[string];
    }

    if (tokens) {
      localizedString = localizedString.replace(/\{(\d+)\}/g, function (match, index) {
        var value = tokens[index - 1];
        var ret = value;

        if (typeof value === 'undefined') {
          ret = match;
        }

        return ret;
      });
    }

    return localizedString;
  }
  /**
   * Handles language change for the player in components. Should be overriden by sub-components.
   *
   * @abstract
   */
  ;

  _proto.handleLanguagechange = function handleLanguagechange() {}
  /**
   * Return the `Component`s DOM element. This is where children get inserted.
   * This will usually be the the same as the element returned in {@link Component#el}.
   *
   * @return {Element}
   *         The content element for this `Component`.
   */
  ;

  _proto.contentEl = function contentEl() {
    return this.contentEl_ || this.el_;
  }
  /**
   * Get this `Component`s ID
   *
   * @return {string}
   *         The id of this `Component`
   */
  ;

  _proto.id = function id() {
    return this.id_;
  }
  /**
   * Get the `Component`s name. The name gets used to reference the `Component`
   * and is set during registration.
   *
   * @return {string}
   *         The name of this `Component`.
   */
  ;

  _proto.name = function name() {
    return this.name_;
  }
  /**
   * Get an array of all child components
   *
   * @return {Array}
   *         The children
   */
  ;

  _proto.children = function children() {
    return this.children_;
  }
  /**
   * Returns the child `Component` with the given `id`.
   *
   * @param {string} id
   *        The id of the child `Component` to get.
   *
   * @return {Component|undefined}
   *         The child `Component` with the given `id` or undefined.
   */
  ;

  _proto.getChildById = function getChildById(id) {
    return this.childIndex_[id];
  }
  /**
   * Returns the child `Component` with the given `name`.
   *
   * @param {string} name
   *        The name of the child `Component` to get.
   *
   * @return {Component|undefined}
   *         The child `Component` with the given `name` or undefined.
   */
  ;

  _proto.getChild = function getChild(name) {
    if (!name) {
      return;
    }

    return this.childNameIndex_[name];
  }
  /**
   * Returns the descendant `Component` following the givent
   * descendant `names`. For instance ['foo', 'bar', 'baz'] would
   * try to get 'foo' on the current component, 'bar' on the 'foo'
   * component and 'baz' on the 'bar' component and return undefined
   * if any of those don't exist.
   *
   * @param {...string[]|...string} names
   *        The name of the child `Component` to get.
   *
   * @return {Component|undefined}
   *         The descendant `Component` following the given descendant
   *         `names` or undefined.
   */
  ;

  _proto.getDescendant = function getDescendant() {
    for (var _len = arguments.length, names = new Array(_len), _key = 0; _key < _len; _key++) {
      names[_key] = arguments[_key];
    }

    // flatten array argument into the main array
    names = names.reduce(function (acc, n) {
      return acc.concat(n);
    }, []);
    var currentChild = this;

    for (var i = 0; i < names.length; i++) {
      currentChild = currentChild.getChild(names[i]);

      if (!currentChild || !currentChild.getChild) {
        return;
      }
    }

    return currentChild;
  }
  /**
   * Add a child `Component` inside the current `Component`.
   *
   *
   * @param {string|Component} child
   *        The name or instance of a child to add.
   *
   * @param {Object} [options={}]
   *        The key/value store of options that will get passed to children of
   *        the child.
   *
   * @param {number} [index=this.children_.length]
   *        The index to attempt to add a child into.
   *
   * @return {Component}
   *         The `Component` that gets added as a child. When using a string the
   *         `Component` will get created by this process.
   */
  ;

  _proto.addChild = function addChild(child, options, index) {
    if (options === void 0) {
      options = {};
    }

    if (index === void 0) {
      index = this.children_.length;
    }

    var component;
    var componentName; // If child is a string, create component with options

    if (typeof child === 'string') {
      componentName = toTitleCase(child);
      var componentClassName = options.componentClass || componentName; // Set name through options

      options.name = componentName; // Create a new object & element for this controls set
      // If there's no .player_, this is a player

      var ComponentClass = Component.getComponent(componentClassName);

      if (!ComponentClass) {
        throw new Error("Component " + componentClassName + " does not exist");
      } // data stored directly on the videojs object may be
      // misidentified as a component to retain
      // backwards-compatibility with 4.x. check to make sure the
      // component class can be instantiated.


      if (typeof ComponentClass !== 'function') {
        return null;
      }

      component = new ComponentClass(this.player_ || this, options); // child is a component instance
    } else {
      component = child;
    }

    if (component.parentComponent_) {
      component.parentComponent_.removeChild(component);
    }

    this.children_.splice(index, 0, component);
    component.parentComponent_ = this;

    if (typeof component.id === 'function') {
      this.childIndex_[component.id()] = component;
    } // If a name wasn't used to create the component, check if we can use the
    // name function of the component


    componentName = componentName || component.name && toTitleCase(component.name());

    if (componentName) {
      this.childNameIndex_[componentName] = component;
      this.childNameIndex_[toLowerCase(componentName)] = component;
    } // Add the UI object's element to the container div (box)
    // Having an element is not required


    if (typeof component.el === 'function' && component.el()) {
      // If inserting before a component, insert before that component's element
      var refNode = null;

      if (this.children_[index + 1]) {
        // Most children are components, but the video tech is an HTML element
        if (this.children_[index + 1].el_) {
          refNode = this.children_[index + 1].el_;
        } else if (isEl(this.children_[index + 1])) {
          refNode = this.children_[index + 1];
        }
      }

      this.contentEl().insertBefore(component.el(), refNode);
    } // Return so it can stored on parent object if desired.


    return component;
  }
  /**
   * Remove a child `Component` from this `Component`s list of children. Also removes
   * the child `Component`s element from this `Component`s element.
   *
   * @param {Component} component
   *        The child `Component` to remove.
   */
  ;

  _proto.removeChild = function removeChild(component) {
    if (typeof component === 'string') {
      component = this.getChild(component);
    }

    if (!component || !this.children_) {
      return;
    }

    var childFound = false;

    for (var i = this.children_.length - 1; i >= 0; i--) {
      if (this.children_[i] === component) {
        childFound = true;
        this.children_.splice(i, 1);
        break;
      }
    }

    if (!childFound) {
      return;
    }

    component.parentComponent_ = null;
    this.childIndex_[component.id()] = null;
    this.childNameIndex_[toTitleCase(component.name())] = null;
    this.childNameIndex_[toLowerCase(component.name())] = null;
    var compEl = component.el();

    if (compEl && compEl.parentNode === this.contentEl()) {
      this.contentEl().removeChild(component.el());
    }
  }
  /**
   * Add and initialize default child `Component`s based upon options.
   */
  ;

  _proto.initChildren = function initChildren() {
    var _this = this;

    var children = this.options_.children;

    if (children) {
      // `this` is `parent`
      var parentOptions = this.options_;

      var handleAdd = function handleAdd(child) {
        var name = child.name;
        var opts = child.opts; // Allow options for children to be set at the parent options
        // e.g. videojs(id, { controlBar: false });
        // instead of videojs(id, { children: { controlBar: false });

        if (parentOptions[name] !== undefined) {
          opts = parentOptions[name];
        } // Allow for disabling default components
        // e.g. options['children']['posterImage'] = false


        if (opts === false) {
          return;
        } // Allow options to be passed as a simple boolean if no configuration
        // is necessary.


        if (opts === true) {
          opts = {};
        } // We also want to pass the original player options
        // to each component as well so they don't need to
        // reach back into the player for options later.


        opts.playerOptions = _this.options_.playerOptions; // Create and add the child component.
        // Add a direct reference to the child by name on the parent instance.
        // If two of the same component are used, different names should be supplied
        // for each

        var newChild = _this.addChild(name, opts);

        if (newChild) {
          _this[name] = newChild;
        }
      }; // Allow for an array of children details to passed in the options


      var workingChildren;
      var Tech = Component.getComponent('Tech');

      if (Array.isArray(children)) {
        workingChildren = children;
      } else {
        workingChildren = Object.keys(children);
      }

      workingChildren // children that are in this.options_ but also in workingChildren  would
      // give us extra children we do not want. So, we want to filter them out.
      .concat(Object.keys(this.options_).filter(function (child) {
        return !workingChildren.some(function (wchild) {
          if (typeof wchild === 'string') {
            return child === wchild;
          }

          return child === wchild.name;
        });
      })).map(function (child) {
        var name;
        var opts;

        if (typeof child === 'string') {
          name = child;
          opts = children[name] || _this.options_[name] || {};
        } else {
          name = child.name;
          opts = child;
        }

        return {
          name: name,
          opts: opts
        };
      }).filter(function (child) {
        // we have to make sure that child.name isn't in the techOrder since
        // techs are registerd as Components but can't aren't compatible
        // See https://github.com/videojs/video.js/issues/2772
        var c = Component.getComponent(child.opts.componentClass || toTitleCase(child.name));
        return c && !Tech.isTech(c);
      }).forEach(handleAdd);
    }
  }
  /**
   * Builds the default DOM class name. Should be overriden by sub-components.
   *
   * @return {string}
   *         The DOM class name for this object.
   *
   * @abstract
   */
  ;

  _proto.buildCSSClass = function buildCSSClass() {
    // Child classes can include a function that does:
    // return 'CLASS NAME' + this._super();
    return '';
  }
  /**
   * Bind a listener to the component's ready state.
   * Different from event listeners in that if the ready event has already happened
   * it will trigger the function immediately.
   *
   * @return {Component}
   *         Returns itself; method can be chained.
   */
  ;

  _proto.ready = function ready(fn, sync) {
    if (sync === void 0) {
      sync = false;
    }

    if (!fn) {
      return;
    }

    if (!this.isReady_) {
      this.readyQueue_ = this.readyQueue_ || [];
      this.readyQueue_.push(fn);
      return;
    }

    if (sync) {
      fn.call(this);
    } else {
      // Call the function asynchronously by default for consistency
      this.setTimeout(fn, 1);
    }
  }
  /**
   * Trigger all the ready listeners for this `Component`.
   *
   * @fires Component#ready
   */
  ;

  _proto.triggerReady = function triggerReady() {
    this.isReady_ = true; // Ensure ready is triggered asynchronously

    this.setTimeout(function () {
      var readyQueue = this.readyQueue_; // Reset Ready Queue

      this.readyQueue_ = [];

      if (readyQueue && readyQueue.length > 0) {
        readyQueue.forEach(function (fn) {
          fn.call(this);
        }, this);
      } // Allow for using event listeners also

      /**
       * Triggered when a `Component` is ready.
       *
       * @event Component#ready
       * @type {EventTarget~Event}
       */


      this.trigger('ready');
    }, 1);
  }
  /**
   * Find a single DOM element matching a `selector`. This can be within the `Component`s
   * `contentEl()` or another custom context.
   *
   * @param {string} selector
   *        A valid CSS selector, which will be passed to `querySelector`.
   *
   * @param {Element|string} [context=this.contentEl()]
   *        A DOM element within which to query. Can also be a selector string in
   *        which case the first matching element will get used as context. If
   *        missing `this.contentEl()` gets used. If  `this.contentEl()` returns
   *        nothing it falls back to `document`.
   *
   * @return {Element|null}
   *         the dom element that was found, or null
   *
   * @see [Information on CSS Selectors](https://developer.mozilla.org/en-US/docs/Web/Guide/CSS/Getting_Started/Selectors)
   */
  ;

  _proto.$ = function $$1(selector, context) {
    return $(selector, context || this.contentEl());
  }
  /**
   * Finds all DOM element matching a `selector`. This can be within the `Component`s
   * `contentEl()` or another custom context.
   *
   * @param {string} selector
   *        A valid CSS selector, which will be passed to `querySelectorAll`.
   *
   * @param {Element|string} [context=this.contentEl()]
   *        A DOM element within which to query. Can also be a selector string in
   *        which case the first matching element will get used as context. If
   *        missing `this.contentEl()` gets used. If  `this.contentEl()` returns
   *        nothing it falls back to `document`.
   *
   * @return {NodeList}
   *         a list of dom elements that were found
   *
   * @see [Information on CSS Selectors](https://developer.mozilla.org/en-US/docs/Web/Guide/CSS/Getting_Started/Selectors)
   */
  ;

  _proto.$$ = function $$$1(selector, context) {
    return $$(selector, context || this.contentEl());
  }
  /**
   * Check if a component's element has a CSS class name.
   *
   * @param {string} classToCheck
   *        CSS class name to check.
   *
   * @return {boolean}
   *         - True if the `Component` has the class.
   *         - False if the `Component` does not have the class`
   */
  ;

  _proto.hasClass = function hasClass$1(classToCheck) {
    return hasClass(this.el_, classToCheck);
  }
  /**
   * Add a CSS class name to the `Component`s element.
   *
   * @param {string} classToAdd
   *        CSS class name to add
   */
  ;

  _proto.addClass = function addClass$1(classToAdd) {
    addClass(this.el_, classToAdd);
  }
  /**
   * Remove a CSS class name from the `Component`s element.
   *
   * @param {string} classToRemove
   *        CSS class name to remove
   */
  ;

  _proto.removeClass = function removeClass$1(classToRemove) {
    removeClass(this.el_, classToRemove);
  }
  /**
   * Add or remove a CSS class name from the component's element.
   * - `classToToggle` gets added when {@link Component#hasClass} would return false.
   * - `classToToggle` gets removed when {@link Component#hasClass} would return true.
   *
   * @param  {string} classToToggle
   *         The class to add or remove based on (@link Component#hasClass}
   *
   * @param  {boolean|Dom~predicate} [predicate]
   *         An {@link Dom~predicate} function or a boolean
   */
  ;

  _proto.toggleClass = function toggleClass$1(classToToggle, predicate) {
    toggleClass(this.el_, classToToggle, predicate);
  }
  /**
   * Show the `Component`s element if it is hidden by removing the
   * 'vjs-hidden' class name from it.
   */
  ;

  _proto.show = function show() {
    this.removeClass('vjs-hidden');
  }
  /**
   * Hide the `Component`s element if it is currently showing by adding the
   * 'vjs-hidden` class name to it.
   */
  ;

  _proto.hide = function hide() {
    this.addClass('vjs-hidden');
  }
  /**
   * Lock a `Component`s element in its visible state by adding the 'vjs-lock-showing'
   * class name to it. Used during fadeIn/fadeOut.
   *
   * @private
   */
  ;

  _proto.lockShowing = function lockShowing() {
    this.addClass('vjs-lock-showing');
  }
  /**
   * Unlock a `Component`s element from its visible state by removing the 'vjs-lock-showing'
   * class name from it. Used during fadeIn/fadeOut.
   *
   * @private
   */
  ;

  _proto.unlockShowing = function unlockShowing() {
    this.removeClass('vjs-lock-showing');
  }
  /**
   * Get the value of an attribute on the `Component`s element.
   *
   * @param {string} attribute
   *        Name of the attribute to get the value from.
   *
   * @return {string|null}
   *         - The value of the attribute that was asked for.
   *         - Can be an empty string on some browsers if the attribute does not exist
   *           or has no value
   *         - Most browsers will return null if the attibute does not exist or has
   *           no value.
   *
   * @see [DOM API]{@link https://developer.mozilla.org/en-US/docs/Web/API/Element/getAttribute}
   */
  ;

  _proto.getAttribute = function getAttribute$1(attribute) {
    return getAttribute(this.el_, attribute);
  }
  /**
   * Set the value of an attribute on the `Component`'s element
   *
   * @param {string} attribute
   *        Name of the attribute to set.
   *
   * @param {string} value
   *        Value to set the attribute to.
   *
   * @see [DOM API]{@link https://developer.mozilla.org/en-US/docs/Web/API/Element/setAttribute}
   */
  ;

  _proto.setAttribute = function setAttribute$1(attribute, value) {
    setAttribute(this.el_, attribute, value);
  }
  /**
   * Remove an attribute from the `Component`s element.
   *
   * @param {string} attribute
   *        Name of the attribute to remove.
   *
   * @see [DOM API]{@link https://developer.mozilla.org/en-US/docs/Web/API/Element/removeAttribute}
   */
  ;

  _proto.removeAttribute = function removeAttribute$1(attribute) {
    removeAttribute(this.el_, attribute);
  }
  /**
   * Get or set the width of the component based upon the CSS styles.
   * See {@link Component#dimension} for more detailed information.
   *
   * @param {number|string} [num]
   *        The width that you want to set postfixed with '%', 'px' or nothing.
   *
   * @param {boolean} [skipListeners]
   *        Skip the componentresize event trigger
   *
   * @return {number|string}
   *         The width when getting, zero if there is no width. Can be a string
   *           postpixed with '%' or 'px'.
   */
  ;

  _proto.width = function width(num, skipListeners) {
    return this.dimension('width', num, skipListeners);
  }
  /**
   * Get or set the height of the component based upon the CSS styles.
   * See {@link Component#dimension} for more detailed information.
   *
   * @param {number|string} [num]
   *        The height that you want to set postfixed with '%', 'px' or nothing.
   *
   * @param {boolean} [skipListeners]
   *        Skip the componentresize event trigger
   *
   * @return {number|string}
   *         The width when getting, zero if there is no width. Can be a string
   *         postpixed with '%' or 'px'.
   */
  ;

  _proto.height = function height(num, skipListeners) {
    return this.dimension('height', num, skipListeners);
  }
  /**
   * Set both the width and height of the `Component` element at the same time.
   *
   * @param  {number|string} width
   *         Width to set the `Component`s element to.
   *
   * @param  {number|string} height
   *         Height to set the `Component`s element to.
   */
  ;

  _proto.dimensions = function dimensions(width, height) {
    // Skip componentresize listeners on width for optimization
    this.width(width, true);
    this.height(height);
  }
  /**
   * Get or set width or height of the `Component` element. This is the shared code
   * for the {@link Component#width} and {@link Component#height}.
   *
   * Things to know:
   * - If the width or height in an number this will return the number postfixed with 'px'.
   * - If the width/height is a percent this will return the percent postfixed with '%'
   * - Hidden elements have a width of 0 with `window.getComputedStyle`. This function
   *   defaults to the `Component`s `style.width` and falls back to `window.getComputedStyle`.
   *   See [this]{@link http://www.foliotek.com/devblog/getting-the-width-of-a-hidden-element-with-jquery-using-width/}
   *   for more information
   * - If you want the computed style of the component, use {@link Component#currentWidth}
   *   and {@link {Component#currentHeight}
   *
   * @fires Component#componentresize
   *
   * @param {string} widthOrHeight
   8        'width' or 'height'
   *
   * @param  {number|string} [num]
   8         New dimension
   *
   * @param  {boolean} [skipListeners]
   *         Skip componentresize event trigger
   *
   * @return {number}
   *         The dimension when getting or 0 if unset
   */
  ;

  _proto.dimension = function dimension(widthOrHeight, num, skipListeners) {
    if (num !== undefined) {
      // Set to zero if null or literally NaN (NaN !== NaN)
      if (num === null || num !== num) {
        num = 0;
      } // Check if using css width/height (% or px) and adjust


      if (('' + num).indexOf('%') !== -1 || ('' + num).indexOf('px') !== -1) {
        this.el_.style[widthOrHeight] = num;
      } else if (num === 'auto') {
        this.el_.style[widthOrHeight] = '';
      } else {
        this.el_.style[widthOrHeight] = num + 'px';
      } // skipListeners allows us to avoid triggering the resize event when setting both width and height


      if (!skipListeners) {
        /**
         * Triggered when a component is resized.
         *
         * @event Component#componentresize
         * @type {EventTarget~Event}
         */
        this.trigger('componentresize');
      }

      return;
    } // Not setting a value, so getting it
    // Make sure element exists


    if (!this.el_) {
      return 0;
    } // Get dimension value from style


    var val = this.el_.style[widthOrHeight];
    var pxIndex = val.indexOf('px');

    if (pxIndex !== -1) {
      // Return the pixel value with no 'px'
      return parseInt(val.slice(0, pxIndex), 10);
    } // No px so using % or no style was set, so falling back to offsetWidth/height
    // If component has display:none, offset will return 0
    // TODO: handle display:none and no dimension style using px


    return parseInt(this.el_['offset' + toTitleCase(widthOrHeight)], 10);
  }
  /**
   * Get the computed width or the height of the component's element.
   *
   * Uses `window.getComputedStyle`.
   *
   * @param {string} widthOrHeight
   *        A string containing 'width' or 'height'. Whichever one you want to get.
   *
   * @return {number}
   *         The dimension that gets asked for or 0 if nothing was set
   *         for that dimension.
   */
  ;

  _proto.currentDimension = function currentDimension(widthOrHeight) {
    var computedWidthOrHeight = 0;

    if (widthOrHeight !== 'width' && widthOrHeight !== 'height') {
      throw new Error('currentDimension only accepts width or height value');
    }

    computedWidthOrHeight = computedStyle(this.el_, widthOrHeight); // remove 'px' from variable and parse as integer

    computedWidthOrHeight = parseFloat(computedWidthOrHeight); // if the computed value is still 0, it's possible that the browser is lying
    // and we want to check the offset values.
    // This code also runs wherever getComputedStyle doesn't exist.

    if (computedWidthOrHeight === 0 || isNaN(computedWidthOrHeight)) {
      var rule = "offset" + toTitleCase(widthOrHeight);
      computedWidthOrHeight = this.el_[rule];
    }

    return computedWidthOrHeight;
  }
  /**
   * An object that contains width and height values of the `Component`s
   * computed style. Uses `window.getComputedStyle`.
   *
   * @typedef {Object} Component~DimensionObject
   *
   * @property {number} width
   *           The width of the `Component`s computed style.
   *
   * @property {number} height
   *           The height of the `Component`s computed style.
   */

  /**
   * Get an object that contains computed width and height values of the
   * component's element.
   *
   * Uses `window.getComputedStyle`.
   *
   * @return {Component~DimensionObject}
   *         The computed dimensions of the component's element.
   */
  ;

  _proto.currentDimensions = function currentDimensions() {
    return {
      width: this.currentDimension('width'),
      height: this.currentDimension('height')
    };
  }
  /**
   * Get the computed width of the component's element.
   *
   * Uses `window.getComputedStyle`.
   *
   * @return {number}
   *         The computed width of the component's element.
   */
  ;

  _proto.currentWidth = function currentWidth() {
    return this.currentDimension('width');
  }
  /**
   * Get the computed height of the component's element.
   *
   * Uses `window.getComputedStyle`.
   *
   * @return {number}
   *         The computed height of the component's element.
   */
  ;

  _proto.currentHeight = function currentHeight() {
    return this.currentDimension('height');
  }
  /**
   * Set the focus to this component
   */
  ;

  _proto.focus = function focus() {
    this.el_.focus();
  }
  /**
   * Remove the focus from this component
   */
  ;

  _proto.blur = function blur() {
    this.el_.blur();
  }
  /**
   * When this Component receives a `keydown` event which it does not process,
   *  it passes the event to the Player for handling.
   *
   * @param {EventTarget~Event} event
   *        The `keydown` event that caused this function to be called.
   */
  ;

  _proto.handleKeyDown = function handleKeyDown(event) {
    if (this.player_) {
      // We only stop propagation here because we want unhandled events to fall
      // back to the browser. Exclude Tab for focus trapping.
      if (!keycode__default['default'].isEventKey(event, 'Tab')) {
        event.stopPropagation();
      }

      this.player_.handleKeyDown(event);
    }
  }
  /**
   * Many components used to have a `handleKeyPress` method, which was poorly
   * named because it listened to a `keydown` event. This method name now
   * delegates to `handleKeyDown`. This means anyone calling `handleKeyPress`
   * will not see their method calls stop working.
   *
   * @param {EventTarget~Event} event
   *        The event that caused this function to be called.
   */
  ;

  _proto.handleKeyPress = function handleKeyPress(event) {
    this.handleKeyDown(event);
  }
  /**
   * Emit a 'tap' events when touch event support gets detected. This gets used to
   * support toggling the controls through a tap on the video. They get enabled
   * because every sub-component would have extra overhead otherwise.
   *
   * @private
   * @fires Component#tap
   * @listens Component#touchstart
   * @listens Component#touchmove
   * @listens Component#touchleave
   * @listens Component#touchcancel
   * @listens Component#touchend
    */
  ;

  _proto.emitTapEvents = function emitTapEvents() {
    // Track the start time so we can determine how long the touch lasted
    var touchStart = 0;
    var firstTouch = null; // Maximum movement allowed during a touch event to still be considered a tap
    // Other popular libs use anywhere from 2 (hammer.js) to 15,
    // so 10 seems like a nice, round number.

    var tapMovementThreshold = 10; // The maximum length a touch can be while still being considered a tap

    var touchTimeThreshold = 200;
    var couldBeTap;
    this.on('touchstart', function (event) {
      // If more than one finger, don't consider treating this as a click
      if (event.touches.length === 1) {
        // Copy pageX/pageY from the object
        firstTouch = {
          pageX: event.touches[0].pageX,
          pageY: event.touches[0].pageY
        }; // Record start time so we can detect a tap vs. "touch and hold"

        touchStart = window__default['default'].performance.now(); // Reset couldBeTap tracking

        couldBeTap = true;
      }
    });
    this.on('touchmove', function (event) {
      // If more than one finger, don't consider treating this as a click
      if (event.touches.length > 1) {
        couldBeTap = false;
      } else if (firstTouch) {
        // Some devices will throw touchmoves for all but the slightest of taps.
        // So, if we moved only a small distance, this could still be a tap
        var xdiff = event.touches[0].pageX - firstTouch.pageX;
        var ydiff = event.touches[0].pageY - firstTouch.pageY;
        var touchDistance = Math.sqrt(xdiff * xdiff + ydiff * ydiff);

        if (touchDistance > tapMovementThreshold) {
          couldBeTap = false;
        }
      }
    });

    var noTap = function noTap() {
      couldBeTap = false;
    }; // TODO: Listen to the original target. http://youtu.be/DujfpXOKUp8?t=13m8s


    this.on('touchleave', noTap);
    this.on('touchcancel', noTap); // When the touch ends, measure how long it took and trigger the appropriate
    // event

    this.on('touchend', function (event) {
      firstTouch = null; // Proceed only if the touchmove/leave/cancel event didn't happen

      if (couldBeTap === true) {
        // Measure how long the touch lasted
        var touchTime = window__default['default'].performance.now() - touchStart; // Make sure the touch was less than the threshold to be considered a tap

        if (touchTime < touchTimeThreshold) {
          // Don't let browser turn this into a click
          event.preventDefault();
          /**
           * Triggered when a `Component` is tapped.
           *
           * @event Component#tap
           * @type {EventTarget~Event}
           */

          this.trigger('tap'); // It may be good to copy the touchend event object and change the
          // type to tap, if the other event properties aren't exact after
          // Events.fixEvent runs (e.g. event.target)
        }
      }
    });
  }
  /**
   * This function reports user activity whenever touch events happen. This can get
   * turned off by any sub-components that wants touch events to act another way.
   *
   * Report user touch activity when touch events occur. User activity gets used to
   * determine when controls should show/hide. It is simple when it comes to mouse
   * events, because any mouse event should show the controls. So we capture mouse
   * events that bubble up to the player and report activity when that happens.
   * With touch events it isn't as easy as `touchstart` and `touchend` toggle player
   * controls. So touch events can't help us at the player level either.
   *
   * User activity gets checked asynchronously. So what could happen is a tap event
   * on the video turns the controls off. Then the `touchend` event bubbles up to
   * the player. Which, if it reported user activity, would turn the controls right
   * back on. We also don't want to completely block touch events from bubbling up.
   * Furthermore a `touchmove` event and anything other than a tap, should not turn
   * controls back on.
   *
   * @listens Component#touchstart
   * @listens Component#touchmove
   * @listens Component#touchend
   * @listens Component#touchcancel
   */
  ;

  _proto.enableTouchActivity = function enableTouchActivity() {
    // Don't continue if the root player doesn't support reporting user activity
    if (!this.player() || !this.player().reportUserActivity) {
      return;
    } // listener for reporting that the user is active


    var report = bind(this.player(), this.player().reportUserActivity);
    var touchHolding;
    this.on('touchstart', function () {
      report(); // For as long as the they are touching the device or have their mouse down,
      // we consider them active even if they're not moving their finger or mouse.
      // So we want to continue to update that they are active

      this.clearInterval(touchHolding); // report at the same interval as activityCheck

      touchHolding = this.setInterval(report, 250);
    });

    var touchEnd = function touchEnd(event) {
      report(); // stop the interval that maintains activity if the touch is holding

      this.clearInterval(touchHolding);
    };

    this.on('touchmove', report);
    this.on('touchend', touchEnd);
    this.on('touchcancel', touchEnd);
  }
  /**
   * A callback that has no parameters and is bound into `Component`s context.
   *
   * @callback Component~GenericCallback
   * @this Component
   */

  /**
   * Creates a function that runs after an `x` millisecond timeout. This function is a
   * wrapper around `window.setTimeout`. There are a few reasons to use this one
   * instead though:
   * 1. It gets cleared via  {@link Component#clearTimeout} when
   *    {@link Component#dispose} gets called.
   * 2. The function callback will gets turned into a {@link Component~GenericCallback}
   *
   * > Note: You can't use `window.clearTimeout` on the id returned by this function. This
   *         will cause its dispose listener not to get cleaned up! Please use
   *         {@link Component#clearTimeout} or {@link Component#dispose} instead.
   *
   * @param {Component~GenericCallback} fn
   *        The function that will be run after `timeout`.
   *
   * @param {number} timeout
   *        Timeout in milliseconds to delay before executing the specified function.
   *
   * @return {number}
   *         Returns a timeout ID that gets used to identify the timeout. It can also
   *         get used in {@link Component#clearTimeout} to clear the timeout that
   *         was set.
   *
   * @listens Component#dispose
   * @see [Similar to]{@link https://developer.mozilla.org/en-US/docs/Web/API/WindowTimers/setTimeout}
   */
  ;

  _proto.setTimeout = function setTimeout(fn, timeout) {
    var _this2 = this;

    // declare as variables so they are properly available in timeout function
    // eslint-disable-next-line
    var timeoutId;
    fn = bind(this, fn);
    this.clearTimersOnDispose_();
    timeoutId = window__default['default'].setTimeout(function () {
      if (_this2.setTimeoutIds_.has(timeoutId)) {
        _this2.setTimeoutIds_["delete"](timeoutId);
      }

      fn();
    }, timeout);
    this.setTimeoutIds_.add(timeoutId);
    return timeoutId;
  }
  /**
   * Clears a timeout that gets created via `window.setTimeout` or
   * {@link Component#setTimeout}. If you set a timeout via {@link Component#setTimeout}
   * use this function instead of `window.clearTimout`. If you don't your dispose
   * listener will not get cleaned up until {@link Component#dispose}!
   *
   * @param {number} timeoutId
   *        The id of the timeout to clear. The return value of
   *        {@link Component#setTimeout} or `window.setTimeout`.
   *
   * @return {number}
   *         Returns the timeout id that was cleared.
   *
   * @see [Similar to]{@link https://developer.mozilla.org/en-US/docs/Web/API/WindowTimers/clearTimeout}
   */
  ;

  _proto.clearTimeout = function clearTimeout(timeoutId) {
    if (this.setTimeoutIds_.has(timeoutId)) {
      this.setTimeoutIds_["delete"](timeoutId);
      window__default['default'].clearTimeout(timeoutId);
    }

    return timeoutId;
  }
  /**
   * Creates a function that gets run every `x` milliseconds. This function is a wrapper
   * around `window.setInterval`. There are a few reasons to use this one instead though.
   * 1. It gets cleared via  {@link Component#clearInterval} when
   *    {@link Component#dispose} gets called.
   * 2. The function callback will be a {@link Component~GenericCallback}
   *
   * @param {Component~GenericCallback} fn
   *        The function to run every `x` seconds.
   *
   * @param {number} interval
   *        Execute the specified function every `x` milliseconds.
   *
   * @return {number}
   *         Returns an id that can be used to identify the interval. It can also be be used in
   *         {@link Component#clearInterval} to clear the interval.
   *
   * @listens Component#dispose
   * @see [Similar to]{@link https://developer.mozilla.org/en-US/docs/Web/API/WindowTimers/setInterval}
   */
  ;

  _proto.setInterval = function setInterval(fn, interval) {
    fn = bind(this, fn);
    this.clearTimersOnDispose_();
    var intervalId = window__default['default'].setInterval(fn, interval);
    this.setIntervalIds_.add(intervalId);
    return intervalId;
  }
  /**
   * Clears an interval that gets created via `window.setInterval` or
   * {@link Component#setInterval}. If you set an inteval via {@link Component#setInterval}
   * use this function instead of `window.clearInterval`. If you don't your dispose
   * listener will not get cleaned up until {@link Component#dispose}!
   *
   * @param {number} intervalId
   *        The id of the interval to clear. The return value of
   *        {@link Component#setInterval} or `window.setInterval`.
   *
   * @return {number}
   *         Returns the interval id that was cleared.
   *
   * @see [Similar to]{@link https://developer.mozilla.org/en-US/docs/Web/API/WindowTimers/clearInterval}
   */
  ;

  _proto.clearInterval = function clearInterval(intervalId) {
    if (this.setIntervalIds_.has(intervalId)) {
      this.setIntervalIds_["delete"](intervalId);
      window__default['default'].clearInterval(intervalId);
    }

    return intervalId;
  }
  /**
   * Queues up a callback to be passed to requestAnimationFrame (rAF), but
   * with a few extra bonuses:
   *
   * - Supports browsers that do not support rAF by falling back to
   *   {@link Component#setTimeout}.
   *
   * - The callback is turned into a {@link Component~GenericCallback} (i.e.
   *   bound to the component).
   *
   * - Automatic cancellation of the rAF callback is handled if the component
   *   is disposed before it is called.
   *
   * @param  {Component~GenericCallback} fn
   *         A function that will be bound to this component and executed just
   *         before the browser's next repaint.
   *
   * @return {number}
   *         Returns an rAF ID that gets used to identify the timeout. It can
   *         also be used in {@link Component#cancelAnimationFrame} to cancel
   *         the animation frame callback.
   *
   * @listens Component#dispose
   * @see [Similar to]{@link https://developer.mozilla.org/en-US/docs/Web/API/window/requestAnimationFrame}
   */
  ;

  _proto.requestAnimationFrame = function requestAnimationFrame(fn) {
    var _this3 = this;

    // Fall back to using a timer.
    if (!this.supportsRaf_) {
      return this.setTimeout(fn, 1000 / 60);
    }

    this.clearTimersOnDispose_(); // declare as variables so they are properly available in rAF function
    // eslint-disable-next-line

    var id;
    fn = bind(this, fn);
    id = window__default['default'].requestAnimationFrame(function () {
      if (_this3.rafIds_.has(id)) {
        _this3.rafIds_["delete"](id);
      }

      fn();
    });
    this.rafIds_.add(id);
    return id;
  }
  /**
   * Request an animation frame, but only one named animation
   * frame will be queued. Another will never be added until
   * the previous one finishes.
   *
   * @param {string} name
   *        The name to give this requestAnimationFrame
   *
   * @param  {Component~GenericCallback} fn
   *         A function that will be bound to this component and executed just
   *         before the browser's next repaint.
   */
  ;

  _proto.requestNamedAnimationFrame = function requestNamedAnimationFrame(name, fn) {
    var _this4 = this;

    if (this.namedRafs_.has(name)) {
      return;
    }

    this.clearTimersOnDispose_();
    fn = bind(this, fn);
    var id = this.requestAnimationFrame(function () {
      fn();

      if (_this4.namedRafs_.has(name)) {
        _this4.namedRafs_["delete"](name);
      }
    });
    this.namedRafs_.set(name, id);
    return name;
  }
  /**
   * Cancels a current named animation frame if it exists.
   *
   * @param {string} name
   *        The name of the requestAnimationFrame to cancel.
   */
  ;

  _proto.cancelNamedAnimationFrame = function cancelNamedAnimationFrame(name) {
    if (!this.namedRafs_.has(name)) {
      return;
    }

    this.cancelAnimationFrame(this.namedRafs_.get(name));
    this.namedRafs_["delete"](name);
  }
  /**
   * Cancels a queued callback passed to {@link Component#requestAnimationFrame}
   * (rAF).
   *
   * If you queue an rAF callback via {@link Component#requestAnimationFrame},
   * use this function instead of `window.cancelAnimationFrame`. If you don't,
   * your dispose listener will not get cleaned up until {@link Component#dispose}!
   *
   * @param {number} id
   *        The rAF ID to clear. The return value of {@link Component#requestAnimationFrame}.
   *
   * @return {number}
   *         Returns the rAF ID that was cleared.
   *
   * @see [Similar to]{@link https://developer.mozilla.org/en-US/docs/Web/API/window/cancelAnimationFrame}
   */
  ;

  _proto.cancelAnimationFrame = function cancelAnimationFrame(id) {
    // Fall back to using a timer.
    if (!this.supportsRaf_) {
      return this.clearTimeout(id);
    }

    if (this.rafIds_.has(id)) {
      this.rafIds_["delete"](id);
      window__default['default'].cancelAnimationFrame(id);
    }

    return id;
  }
  /**
   * A function to setup `requestAnimationFrame`, `setTimeout`,
   * and `setInterval`, clearing on dispose.
   *
   * > Previously each timer added and removed dispose listeners on it's own.
   * For better performance it was decided to batch them all, and use `Set`s
   * to track outstanding timer ids.
   *
   * @private
   */
  ;

  _proto.clearTimersOnDispose_ = function clearTimersOnDispose_() {
    var _this5 = this;

    if (this.clearingTimersOnDispose_) {
      return;
    }

    this.clearingTimersOnDispose_ = true;
    this.one('dispose', function () {
      [['namedRafs_', 'cancelNamedAnimationFrame'], ['rafIds_', 'cancelAnimationFrame'], ['setTimeoutIds_', 'clearTimeout'], ['setIntervalIds_', 'clearInterval']].forEach(function (_ref) {
        var idName = _ref[0],
            cancelName = _ref[1];

        // for a `Set` key will actually be the value again
        // so forEach((val, val) =>` but for maps we want to use
        // the key.
        _this5[idName].forEach(function (val, key) {
          return _this5[cancelName](key);
        });
      });
      _this5.clearingTimersOnDispose_ = false;
    });
  }
  /**
   * Register a `Component` with `videojs` given the name and the component.
   *
   * > NOTE: {@link Tech}s should not be registered as a `Component`. {@link Tech}s
   *         should be registered using {@link Tech.registerTech} or
   *         {@link videojs:videojs.registerTech}.
   *
   * > NOTE: This function can also be seen on videojs as
   *         {@link videojs:videojs.registerComponent}.
   *
   * @param {string} name
   *        The name of the `Component` to register.
   *
   * @param {Component} ComponentToRegister
   *        The `Component` class to register.
   *
   * @return {Component}
   *         The `Component` that was registered.
   */
  ;

  Component.registerComponent = function registerComponent(name, ComponentToRegister) {
    if (typeof name !== 'string' || !name) {
      throw new Error("Illegal component name, \"" + name + "\"; must be a non-empty string.");
    }

    var Tech = Component.getComponent('Tech'); // We need to make sure this check is only done if Tech has been registered.

    var isTech = Tech && Tech.isTech(ComponentToRegister);
    var isComp = Component === ComponentToRegister || Component.prototype.isPrototypeOf(ComponentToRegister.prototype);

    if (isTech || !isComp) {
      var reason;

      if (isTech) {
        reason = 'techs must be registered using Tech.registerTech()';
      } else {
        reason = 'must be a Component subclass';
      }

      throw new Error("Illegal component, \"" + name + "\"; " + reason + ".");
    }

    name = toTitleCase(name);

    if (!Component.components_) {
      Component.components_ = {};
    }

    var Player = Component.getComponent('Player');

    if (name === 'Player' && Player && Player.players) {
      var players = Player.players;
      var playerNames = Object.keys(players); // If we have players that were disposed, then their name will still be
      // in Players.players. So, we must loop through and verify that the value
      // for each item is not null. This allows registration of the Player component
      // after all players have been disposed or before any were created.

      if (players && playerNames.length > 0 && playerNames.map(function (pname) {
        return players[pname];
      }).every(Boolean)) {
        throw new Error('Can not register Player component after player has been created.');
      }
    }

    Component.components_[name] = ComponentToRegister;
    Component.components_[toLowerCase(name)] = ComponentToRegister;
    return ComponentToRegister;
  }
  /**
   * Get a `Component` based on the name it was registered with.
   *
   * @param {string} name
   *        The Name of the component to get.
   *
   * @return {Component}
   *         The `Component` that got registered under the given name.
   */
  ;

  Component.getComponent = function getComponent(name) {
    if (!name || !Component.components_) {
      return;
    }

    return Component.components_[name];
  };

  return Component;
}();
/**
 * Whether or not this component supports `requestAnimationFrame`.
 *
 * This is exposed primarily for testing purposes.
 *
 * @private
 * @type {Boolean}
 */


Component.prototype.supportsRaf_ = typeof window__default['default'].requestAnimationFrame === 'function' && typeof window__default['default'].cancelAnimationFrame === 'function';
Component.registerComponent('Component', Component);

/**
 * @file time-ranges.js
 * @module time-ranges
 */
/**
 * Returns the time for the specified index at the start or end
 * of a TimeRange object.
 *
 * @typedef    {Function} TimeRangeIndex
 *
 * @param      {number} [index=0]
 *             The range number to return the time for.
 *
 * @return     {number}
 *             The time offset at the specified index.
 *
 * @deprecated The index argument must be provided.
 *             In the future, leaving it out will throw an error.
 */

/**
 * An object that contains ranges of time.
 *
 * @typedef  {Object} TimeRange
 *
 * @property {number} length
 *           The number of time ranges represented by this object.
 *
 * @property {module:time-ranges~TimeRangeIndex} start
 *           Returns the time offset at which a specified time range begins.
 *
 * @property {module:time-ranges~TimeRangeIndex} end
 *           Returns the time offset at which a specified time range ends.
 *
 * @see https://developer.mozilla.org/en-US/docs/Web/API/TimeRanges
 */

/**
 * Check if any of the time ranges are over the maximum index.
 *
 * @private
 * @param   {string} fnName
 *          The function name to use for logging
 *
 * @param   {number} index
 *          The index to check
 *
 * @param   {number} maxIndex
 *          The maximum possible index
 *
 * @throws  {Error} if the timeRanges provided are over the maxIndex
 */

function rangeCheck(fnName, index, maxIndex) {
  if (typeof index !== 'number' || index < 0 || index > maxIndex) {
    throw new Error("Failed to execute '" + fnName + "' on 'TimeRanges': The index provided (" + index + ") is non-numeric or out of bounds (0-" + maxIndex + ").");
  }
}
/**
 * Get the time for the specified index at the start or end
 * of a TimeRange object.
 *
 * @private
 * @param      {string} fnName
 *             The function name to use for logging
 *
 * @param      {string} valueIndex
 *             The property that should be used to get the time. should be
 *             'start' or 'end'
 *
 * @param      {Array} ranges
 *             An array of time ranges
 *
 * @param      {Array} [rangeIndex=0]
 *             The index to start the search at
 *
 * @return     {number}
 *             The time that offset at the specified index.
 *
 * @deprecated rangeIndex must be set to a value, in the future this will throw an error.
 * @throws     {Error} if rangeIndex is more than the length of ranges
 */


function getRange(fnName, valueIndex, ranges, rangeIndex) {
  rangeCheck(fnName, rangeIndex, ranges.length - 1);
  return ranges[rangeIndex][valueIndex];
}
/**
 * Create a time range object given ranges of time.
 *
 * @private
 * @param   {Array} [ranges]
 *          An array of time ranges.
 */


function createTimeRangesObj(ranges) {
  var timeRangesObj;

  if (ranges === undefined || ranges.length === 0) {
    timeRangesObj = {
      length: 0,
      start: function start() {
        throw new Error('This TimeRanges object is empty');
      },
      end: function end() {
        throw new Error('This TimeRanges object is empty');
      }
    };
  } else {
    timeRangesObj = {
      length: ranges.length,
      start: getRange.bind(null, 'start', 0, ranges),
      end: getRange.bind(null, 'end', 1, ranges)
    };
  }

  if (window__default['default'].Symbol && window__default['default'].Symbol.iterator) {
    timeRangesObj[window__default['default'].Symbol.iterator] = function () {
      return (ranges || []).values();
    };
  }

  return timeRangesObj;
}
/**
 * Create a `TimeRange` object which mimics an
 * {@link https://developer.mozilla.org/en-US/docs/Web/API/TimeRanges|HTML5 TimeRanges instance}.
 *
 * @param {number|Array[]} start
 *        The start of a single range (a number) or an array of ranges (an
 *        array of arrays of two numbers each).
 *
 * @param {number} end
 *        The end of a single range. Cannot be used with the array form of
 *        the `start` argument.
 */


function createTimeRanges(start, end) {
  if (Array.isArray(start)) {
    return createTimeRangesObj(start);
  } else if (start === undefined || end === undefined) {
    return createTimeRangesObj();
  }

  return createTimeRangesObj([[start, end]]);
}

/**
 * @file buffer.js
 * @module buffer
 */
/**
 * Compute the percentage of the media that has been buffered.
 *
 * @param {TimeRange} buffered
 *        The current `TimeRange` object representing buffered time ranges
 *
 * @param {number} duration
 *        Total duration of the media
 *
 * @return {number}
 *         Percent buffered of the total duration in decimal form.
 */

function bufferedPercent(buffered, duration) {
  var bufferedDuration = 0;
  var start;
  var end;

  if (!duration) {
    return 0;
  }

  if (!buffered || !buffered.length) {
    buffered = createTimeRanges(0, 0);
  }

  for (var i = 0; i < buffered.length; i++) {
    start = buffered.start(i);
    end = buffered.end(i); // buffered end can be bigger than duration by a very small fraction

    if (end > duration) {
      end = duration;
    }

    bufferedDuration += end - start;
  }

  return bufferedDuration / duration;
}

/**
 * @file media-error.js
 */
/**
 * A Custom `MediaError` class which mimics the standard HTML5 `MediaError` class.
 *
 * @param {number|string|Object|MediaError} value
 *        This can be of multiple types:
 *        - number: should be a standard error code
 *        - string: an error message (the code will be 0)
 *        - Object: arbitrary properties
 *        - `MediaError` (native): used to populate a video.js `MediaError` object
 *        - `MediaError` (video.js): will return itself if it's already a
 *          video.js `MediaError` object.
 *
 * @see [MediaError Spec]{@link https://dev.w3.org/html5/spec-author-view/video.html#mediaerror}
 * @see [Encrypted MediaError Spec]{@link https://www.w3.org/TR/2013/WD-encrypted-media-20130510/#error-codes}
 *
 * @class MediaError
 */

function MediaError(value) {
  // Allow redundant calls to this constructor to avoid having `instanceof`
  // checks peppered around the code.
  if (value instanceof MediaError) {
    return value;
  }

  if (typeof value === 'number') {
    this.code = value;
  } else if (typeof value === 'string') {
    // default code is zero, so this is a custom error
    this.message = value;
  } else if (isObject(value)) {
    // We assign the `code` property manually because native `MediaError` objects
    // do not expose it as an own/enumerable property of the object.
    if (typeof value.code === 'number') {
      this.code = value.code;
    }

    assign(this, value);
  }

  if (!this.message) {
    this.message = MediaError.defaultMessages[this.code] || '';
  }
}
/**
 * The error code that refers two one of the defined `MediaError` types
 *
 * @type {Number}
 */


MediaError.prototype.code = 0;
/**
 * An optional message that to show with the error. Message is not part of the HTML5
 * video spec but allows for more informative custom errors.
 *
 * @type {String}
 */

MediaError.prototype.message = '';
/**
 * An optional status code that can be set by plugins to allow even more detail about
 * the error. For example a plugin might provide a specific HTTP status code and an
 * error message for that code. Then when the plugin gets that error this class will
 * know how to display an error message for it. This allows a custom message to show
 * up on the `Player` error overlay.
 *
 * @type {Array}
 */

MediaError.prototype.status = null;
/**
 * Errors indexed by the W3C standard. The order **CANNOT CHANGE**! See the
 * specification listed under {@link MediaError} for more information.
 *
 * @enum {array}
 * @readonly
 * @property {string} 0 - MEDIA_ERR_CUSTOM
 * @property {string} 1 - MEDIA_ERR_ABORTED
 * @property {string} 2 - MEDIA_ERR_NETWORK
 * @property {string} 3 - MEDIA_ERR_DECODE
 * @property {string} 4 - MEDIA_ERR_SRC_NOT_SUPPORTED
 * @property {string} 5 - MEDIA_ERR_ENCRYPTED
 */

MediaError.errorTypes = ['MEDIA_ERR_CUSTOM', 'MEDIA_ERR_ABORTED', 'MEDIA_ERR_NETWORK', 'MEDIA_ERR_DECODE', 'MEDIA_ERR_SRC_NOT_SUPPORTED', 'MEDIA_ERR_ENCRYPTED'];
/**
 * The default `MediaError` messages based on the {@link MediaError.errorTypes}.
 *
 * @type {Array}
 * @constant
 */

MediaError.defaultMessages = {
  1: 'You aborted the media playback',
  2: 'A network error caused the media download to fail part-way.',
  3: 'The media playback was aborted due to a corruption problem or because the media used features your browser did not support.',
  4: 'The media could not be loaded, either because the server or network failed or because the format is not supported.',
  5: 'The media is encrypted and we do not have the keys to decrypt it.'
}; // Add types as properties on MediaError
// e.g. MediaError.MEDIA_ERR_SRC_NOT_SUPPORTED = 4;

for (var errNum = 0; errNum < MediaError.errorTypes.length; errNum++) {
  MediaError[MediaError.errorTypes[errNum]] = errNum; // values should be accessible on both the class and instance

  MediaError.prototype[MediaError.errorTypes[errNum]] = errNum;
} // jsdocs for instance/static members added above

/**
 * Returns whether an object is `Promise`-like (i.e. has a `then` method).
 *
 * @param  {Object}  value
 *         An object that may or may not be `Promise`-like.
 *
 * @return {boolean}
 *         Whether or not the object is `Promise`-like.
 */
function isPromise(value) {
  return value !== undefined && value !== null && typeof value.then === 'function';
}
/**
 * Silence a Promise-like object.
 *
 * This is useful for avoiding non-harmful, but potentially confusing "uncaught
 * play promise" rejection error messages.
 *
 * @param  {Object} value
 *         An object that may or may not be `Promise`-like.
 */

function silencePromise(value) {
  if (isPromise(value)) {
    value.then(null, function (e) {});
  }
}

/**
 * @file text-track-list-converter.js Utilities for capturing text track state and
 * re-creating tracks based on a capture.
 *
 * @module text-track-list-converter
 */

/**
 * Examine a single {@link TextTrack} and return a JSON-compatible javascript object that
 * represents the {@link TextTrack}'s state.
 *
 * @param {TextTrack} track
 *        The text track to query.
 *
 * @return {Object}
 *         A serializable javascript representation of the TextTrack.
 * @private
 */
var trackToJson_ = function trackToJson_(track) {
  var ret = ['kind', 'label', 'language', 'id', 'inBandMetadataTrackDispatchType', 'mode', 'src'].reduce(function (acc, prop, i) {
    if (track[prop]) {
      acc[prop] = track[prop];
    }

    return acc;
  }, {
    cues: track.cues && Array.prototype.map.call(track.cues, function (cue) {
      return {
        startTime: cue.startTime,
        endTime: cue.endTime,
        text: cue.text,
        id: cue.id
      };
    })
  });
  return ret;
};
/**
 * Examine a {@link Tech} and return a JSON-compatible javascript array that represents the
 * state of all {@link TextTrack}s currently configured. The return array is compatible with
 * {@link text-track-list-converter:jsonToTextTracks}.
 *
 * @param {Tech} tech
 *        The tech object to query
 *
 * @return {Array}
 *         A serializable javascript representation of the {@link Tech}s
 *         {@link TextTrackList}.
 */


var textTracksToJson = function textTracksToJson(tech) {
  var trackEls = tech.$$('track');
  var trackObjs = Array.prototype.map.call(trackEls, function (t) {
    return t.track;
  });
  var tracks = Array.prototype.map.call(trackEls, function (trackEl) {
    var json = trackToJson_(trackEl.track);

    if (trackEl.src) {
      json.src = trackEl.src;
    }

    return json;
  });
  return tracks.concat(Array.prototype.filter.call(tech.textTracks(), function (track) {
    return trackObjs.indexOf(track) === -1;
  }).map(trackToJson_));
};
/**
 * Create a set of remote {@link TextTrack}s on a {@link Tech} based on an array of javascript
 * object {@link TextTrack} representations.
 *
 * @param {Array} json
 *        An array of `TextTrack` representation objects, like those that would be
 *        produced by `textTracksToJson`.
 *
 * @param {Tech} tech
 *        The `Tech` to create the `TextTrack`s on.
 */


var jsonToTextTracks = function jsonToTextTracks(json, tech) {
  json.forEach(function (track) {
    var addedTrack = tech.addRemoteTextTrack(track).track;

    if (!track.src && track.cues) {
      track.cues.forEach(function (cue) {
        return addedTrack.addCue(cue);
      });
    }
  });
  return tech.textTracks();
};

var textTrackConverter = {
  textTracksToJson: textTracksToJson,
  jsonToTextTracks: jsonToTextTracks,
  trackToJson_: trackToJson_
};

var MODAL_CLASS_NAME = 'vjs-modal-dialog';
/**
 * The `ModalDialog` displays over the video and its controls, which blocks
 * interaction with the player until it is closed.
 *
 * Modal dialogs include a "Close" button and will close when that button
 * is activated - or when ESC is pressed anywhere.
 *
 * @extends Component
 */

var ModalDialog = /*#__PURE__*/function (_Component) {
  _inheritsLoose__default['default'](ModalDialog, _Component);

  /**
   * Create an instance of this class.
   *
   * @param {Player} player
   *        The `Player` that this class should be attached to.
   *
   * @param {Object} [options]
   *        The key/value store of player options.
   *
   * @param {Mixed} [options.content=undefined]
   *        Provide customized content for this modal.
   *
   * @param {string} [options.description]
   *        A text description for the modal, primarily for accessibility.
   *
   * @param {boolean} [options.fillAlways=false]
   *        Normally, modals are automatically filled only the first time
   *        they open. This tells the modal to refresh its content
   *        every time it opens.
   *
   * @param {string} [options.label]
   *        A text label for the modal, primarily for accessibility.
   *
   * @param {boolean} [options.pauseOnOpen=true]
   *        If `true`, playback will will be paused if playing when
   *        the modal opens, and resumed when it closes.
   *
   * @param {boolean} [options.temporary=true]
   *        If `true`, the modal can only be opened once; it will be
   *        disposed as soon as it's closed.
   *
   * @param {boolean} [options.uncloseable=false]
   *        If `true`, the user will not be able to close the modal
   *        through the UI in the normal ways. Programmatic closing is
   *        still possible.
   */
  function ModalDialog(player, options) {
    var _this;

    _this = _Component.call(this, player, options) || this;

    _this.handleKeyDown_ = function (e) {
      return _this.handleKeyDown(e);
    };

    _this.close_ = function (e) {
      return _this.close(e);
    };

    _this.opened_ = _this.hasBeenOpened_ = _this.hasBeenFilled_ = false;

    _this.closeable(!_this.options_.uncloseable);

    _this.content(_this.options_.content); // Make sure the contentEl is defined AFTER any children are initialized
    // because we only want the contents of the modal in the contentEl
    // (not the UI elements like the close button).


    _this.contentEl_ = createEl('div', {
      className: MODAL_CLASS_NAME + "-content"
    }, {
      role: 'document'
    });
    _this.descEl_ = createEl('p', {
      className: MODAL_CLASS_NAME + "-description vjs-control-text",
      id: _this.el().getAttribute('aria-describedby')
    });
    textContent(_this.descEl_, _this.description());

    _this.el_.appendChild(_this.descEl_);

    _this.el_.appendChild(_this.contentEl_);

    return _this;
  }
  /**
   * Create the `ModalDialog`'s DOM element
   *
   * @return {Element}
   *         The DOM element that gets created.
   */


  var _proto = ModalDialog.prototype;

  _proto.createEl = function createEl() {
    return _Component.prototype.createEl.call(this, 'div', {
      className: this.buildCSSClass(),
      tabIndex: -1
    }, {
      'aria-describedby': this.id() + "_description",
      'aria-hidden': 'true',
      'aria-label': this.label(),
      'role': 'dialog'
    });
  };

  _proto.dispose = function dispose() {
    this.contentEl_ = null;
    this.descEl_ = null;
    this.previouslyActiveEl_ = null;

    _Component.prototype.dispose.call(this);
  }
  /**
   * Builds the default DOM `className`.
   *
   * @return {string}
   *         The DOM `className` for this object.
   */
  ;

  _proto.buildCSSClass = function buildCSSClass() {
    return MODAL_CLASS_NAME + " vjs-hidden " + _Component.prototype.buildCSSClass.call(this);
  }
  /**
   * Returns the label string for this modal. Primarily used for accessibility.
   *
   * @return {string}
   *         the localized or raw label of this modal.
   */
  ;

  _proto.label = function label() {
    return this.localize(this.options_.label || 'Modal Window');
  }
  /**
   * Returns the description string for this modal. Primarily used for
   * accessibility.
   *
   * @return {string}
   *         The localized or raw description of this modal.
   */
  ;

  _proto.description = function description() {
    var desc = this.options_.description || this.localize('This is a modal window.'); // Append a universal closeability message if the modal is closeable.

    if (this.closeable()) {
      desc += ' ' + this.localize('This modal can be closed by pressing the Escape key or activating the close button.');
    }

    return desc;
  }
  /**
   * Opens the modal.
   *
   * @fires ModalDialog#beforemodalopen
   * @fires ModalDialog#modalopen
   */
  ;

  _proto.open = function open() {
    if (!this.opened_) {
      var player = this.player();
      /**
        * Fired just before a `ModalDialog` is opened.
        *
        * @event ModalDialog#beforemodalopen
        * @type {EventTarget~Event}
        */

      this.trigger('beforemodalopen');
      this.opened_ = true; // Fill content if the modal has never opened before and
      // never been filled.

      if (this.options_.fillAlways || !this.hasBeenOpened_ && !this.hasBeenFilled_) {
        this.fill();
      } // If the player was playing, pause it and take note of its previously
      // playing state.


      this.wasPlaying_ = !player.paused();

      if (this.options_.pauseOnOpen && this.wasPlaying_) {
        player.pause();
      }

      this.on('keydown', this.handleKeyDown_); // Hide controls and note if they were enabled.

      this.hadControls_ = player.controls();
      player.controls(false);
      this.show();
      this.conditionalFocus_();
      this.el().setAttribute('aria-hidden', 'false');
      /**
        * Fired just after a `ModalDialog` is opened.
        *
        * @event ModalDialog#modalopen
        * @type {EventTarget~Event}
        */

      this.trigger('modalopen');
      this.hasBeenOpened_ = true;
    }
  }
  /**
   * If the `ModalDialog` is currently open or closed.
   *
   * @param  {boolean} [value]
   *         If given, it will open (`true`) or close (`false`) the modal.
   *
   * @return {boolean}
   *         the current open state of the modaldialog
   */
  ;

  _proto.opened = function opened(value) {
    if (typeof value === 'boolean') {
      this[value ? 'open' : 'close']();
    }

    return this.opened_;
  }
  /**
   * Closes the modal, does nothing if the `ModalDialog` is
   * not open.
   *
   * @fires ModalDialog#beforemodalclose
   * @fires ModalDialog#modalclose
   */
  ;

  _proto.close = function close() {
    if (!this.opened_) {
      return;
    }

    var player = this.player();
    /**
      * Fired just before a `ModalDialog` is closed.
      *
      * @event ModalDialog#beforemodalclose
      * @type {EventTarget~Event}
      */

    this.trigger('beforemodalclose');
    this.opened_ = false;

    if (this.wasPlaying_ && this.options_.pauseOnOpen) {
      player.play();
    }

    this.off('keydown', this.handleKeyDown_);

    if (this.hadControls_) {
      player.controls(true);
    }

    this.hide();
    this.el().setAttribute('aria-hidden', 'true');
    /**
      * Fired just after a `ModalDialog` is closed.
      *
      * @event ModalDialog#modalclose
      * @type {EventTarget~Event}
      */

    this.trigger('modalclose');
    this.conditionalBlur_();

    if (this.options_.temporary) {
      this.dispose();
    }
  }
  /**
   * Check to see if the `ModalDialog` is closeable via the UI.
   *
   * @param  {boolean} [value]
   *         If given as a boolean, it will set the `closeable` option.
   *
   * @return {boolean}
   *         Returns the final value of the closable option.
   */
  ;

  _proto.closeable = function closeable(value) {
    if (typeof value === 'boolean') {
      var closeable = this.closeable_ = !!value;
      var close = this.getChild('closeButton'); // If this is being made closeable and has no close button, add one.

      if (closeable && !close) {
        // The close button should be a child of the modal - not its
        // content element, so temporarily change the content element.
        var temp = this.contentEl_;
        this.contentEl_ = this.el_;
        close = this.addChild('closeButton', {
          controlText: 'Close Modal Dialog'
        });
        this.contentEl_ = temp;
        this.on(close, 'close', this.close_);
      } // If this is being made uncloseable and has a close button, remove it.


      if (!closeable && close) {
        this.off(close, 'close', this.close_);
        this.removeChild(close);
        close.dispose();
      }
    }

    return this.closeable_;
  }
  /**
   * Fill the modal's content element with the modal's "content" option.
   * The content element will be emptied before this change takes place.
   */
  ;

  _proto.fill = function fill() {
    this.fillWith(this.content());
  }
  /**
   * Fill the modal's content element with arbitrary content.
   * The content element will be emptied before this change takes place.
   *
   * @fires ModalDialog#beforemodalfill
   * @fires ModalDialog#modalfill
   *
   * @param {Mixed} [content]
   *        The same rules apply to this as apply to the `content` option.
   */
  ;

  _proto.fillWith = function fillWith(content) {
    var contentEl = this.contentEl();
    var parentEl = contentEl.parentNode;
    var nextSiblingEl = contentEl.nextSibling;
    /**
      * Fired just before a `ModalDialog` is filled with content.
      *
      * @event ModalDialog#beforemodalfill
      * @type {EventTarget~Event}
      */

    this.trigger('beforemodalfill');
    this.hasBeenFilled_ = true; // Detach the content element from the DOM before performing
    // manipulation to avoid modifying the live DOM multiple times.

    parentEl.removeChild(contentEl);
    this.empty();
    insertContent(contentEl, content);
    /**
     * Fired just after a `ModalDialog` is filled with content.
     *
     * @event ModalDialog#modalfill
     * @type {EventTarget~Event}
     */

    this.trigger('modalfill'); // Re-inject the re-filled content element.

    if (nextSiblingEl) {
      parentEl.insertBefore(contentEl, nextSiblingEl);
    } else {
      parentEl.appendChild(contentEl);
    } // make sure that the close button is last in the dialog DOM


    var closeButton = this.getChild('closeButton');

    if (closeButton) {
      parentEl.appendChild(closeButton.el_);
    }
  }
  /**
   * Empties the content element. This happens anytime the modal is filled.
   *
   * @fires ModalDialog#beforemodalempty
   * @fires ModalDialog#modalempty
   */
  ;

  _proto.empty = function empty() {
    /**
    * Fired just before a `ModalDialog` is emptied.
    *
    * @event ModalDialog#beforemodalempty
    * @type {EventTarget~Event}
    */
    this.trigger('beforemodalempty');
    emptyEl(this.contentEl());
    /**
    * Fired just after a `ModalDialog` is emptied.
    *
    * @event ModalDialog#modalempty
    * @type {EventTarget~Event}
    */

    this.trigger('modalempty');
  }
  /**
   * Gets or sets the modal content, which gets normalized before being
   * rendered into the DOM.
   *
   * This does not update the DOM or fill the modal, but it is called during
   * that process.
   *
   * @param  {Mixed} [value]
   *         If defined, sets the internal content value to be used on the
   *         next call(s) to `fill`. This value is normalized before being
   *         inserted. To "clear" the internal content value, pass `null`.
   *
   * @return {Mixed}
   *         The current content of the modal dialog
   */
  ;

  _proto.content = function content(value) {
    if (typeof value !== 'undefined') {
      this.content_ = value;
    }

    return this.content_;
  }
  /**
   * conditionally focus the modal dialog if focus was previously on the player.
   *
   * @private
   */
  ;

  _proto.conditionalFocus_ = function conditionalFocus_() {
    var activeEl = document__default['default'].activeElement;
    var playerEl = this.player_.el_;
    this.previouslyActiveEl_ = null;

    if (playerEl.contains(activeEl) || playerEl === activeEl) {
      this.previouslyActiveEl_ = activeEl;
      this.focus();
    }
  }
  /**
   * conditionally blur the element and refocus the last focused element
   *
   * @private
   */
  ;

  _proto.conditionalBlur_ = function conditionalBlur_() {
    if (this.previouslyActiveEl_) {
      this.previouslyActiveEl_.focus();
      this.previouslyActiveEl_ = null;
    }
  }
  /**
   * Keydown handler. Attached when modal is focused.
   *
   * @listens keydown
   */
  ;

  _proto.handleKeyDown = function handleKeyDown(event) {
    // Do not allow keydowns to reach out of the modal dialog.
    event.stopPropagation();

    if (keycode__default['default'].isEventKey(event, 'Escape') && this.closeable()) {
      event.preventDefault();
      this.close();
      return;
    } // exit early if it isn't a tab key


    if (!keycode__default['default'].isEventKey(event, 'Tab')) {
      return;
    }

    var focusableEls = this.focusableEls_();
    var activeEl = this.el_.querySelector(':focus');
    var focusIndex;

    for (var i = 0; i < focusableEls.length; i++) {
      if (activeEl === focusableEls[i]) {
        focusIndex = i;
        break;
      }
    }

    if (document__default['default'].activeElement === this.el_) {
      focusIndex = 0;
    }

    if (event.shiftKey && focusIndex === 0) {
      focusableEls[focusableEls.length - 1].focus();
      event.preventDefault();
    } else if (!event.shiftKey && focusIndex === focusableEls.length - 1) {
      focusableEls[0].focus();
      event.preventDefault();
    }
  }
  /**
   * get all focusable elements
   *
   * @private
   */
  ;

  _proto.focusableEls_ = function focusableEls_() {
    var allChildren = this.el_.querySelectorAll('*');
    return Array.prototype.filter.call(allChildren, function (child) {
      return (child instanceof window__default['default'].HTMLAnchorElement || child instanceof window__default['default'].HTMLAreaElement) && child.hasAttribute('href') || (child instanceof window__default['default'].HTMLInputElement || child instanceof window__default['default'].HTMLSelectElement || child instanceof window__default['default'].HTMLTextAreaElement || child instanceof window__default['default'].HTMLButtonElement) && !child.hasAttribute('disabled') || child instanceof window__default['default'].HTMLIFrameElement || child instanceof window__default['default'].HTMLObjectElement || child instanceof window__default['default'].HTMLEmbedElement || child.hasAttribute('tabindex') && child.getAttribute('tabindex') !== -1 || child.hasAttribute('contenteditable');
    });
  };

  return ModalDialog;
}(Component);
/**
 * Default options for `ModalDialog` default options.
 *
 * @type {Object}
 * @private
 */


ModalDialog.prototype.options_ = {
  pauseOnOpen: true,
  temporary: true
};
Component.registerComponent('ModalDialog', ModalDialog);

/**
 * Common functionaliy between {@link TextTrackList}, {@link AudioTrackList}, and
 * {@link VideoTrackList}
 *
 * @extends EventTarget
 */

var TrackList = /*#__PURE__*/function (_EventTarget) {
  _inheritsLoose__default['default'](TrackList, _EventTarget);

  /**
   * Create an instance of this class
   *
   * @param {Track[]} tracks
   *        A list of tracks to initialize the list with.
   *
   * @abstract
   */
  function TrackList(tracks) {
    var _this;

    if (tracks === void 0) {
      tracks = [];
    }

    _this = _EventTarget.call(this) || this;
    _this.tracks_ = [];
    /**
     * @memberof TrackList
     * @member {number} length
     *         The current number of `Track`s in the this Trackist.
     * @instance
     */

    Object.defineProperty(_assertThisInitialized__default['default'](_this), 'length', {
      get: function get() {
        return this.tracks_.length;
      }
    });

    for (var i = 0; i < tracks.length; i++) {
      _this.addTrack(tracks[i]);
    }

    return _this;
  }
  /**
   * Add a {@link Track} to the `TrackList`
   *
   * @param {Track} track
   *        The audio, video, or text track to add to the list.
   *
   * @fires TrackList#addtrack
   */


  var _proto = TrackList.prototype;

  _proto.addTrack = function addTrack(track) {
    var _this2 = this;

    var index = this.tracks_.length;

    if (!('' + index in this)) {
      Object.defineProperty(this, index, {
        get: function get() {
          return this.tracks_[index];
        }
      });
    } // Do not add duplicate tracks


    if (this.tracks_.indexOf(track) === -1) {
      this.tracks_.push(track);
      /**
       * Triggered when a track is added to a track list.
       *
       * @event TrackList#addtrack
       * @type {EventTarget~Event}
       * @property {Track} track
       *           A reference to track that was added.
       */

      this.trigger({
        track: track,
        type: 'addtrack',
        target: this
      });
    }
    /**
     * Triggered when a track label is changed.
     *
     * @event TrackList#addtrack
     * @type {EventTarget~Event}
     * @property {Track} track
     *           A reference to track that was added.
     */


    track.labelchange_ = function () {
      _this2.trigger({
        track: track,
        type: 'labelchange',
        target: _this2
      });
    };

    if (isEvented(track)) {
      track.addEventListener('labelchange', track.labelchange_);
    }
  }
  /**
   * Remove a {@link Track} from the `TrackList`
   *
   * @param {Track} rtrack
   *        The audio, video, or text track to remove from the list.
   *
   * @fires TrackList#removetrack
   */
  ;

  _proto.removeTrack = function removeTrack(rtrack) {
    var track;

    for (var i = 0, l = this.length; i < l; i++) {
      if (this[i] === rtrack) {
        track = this[i];

        if (track.off) {
          track.off();
        }

        this.tracks_.splice(i, 1);
        break;
      }
    }

    if (!track) {
      return;
    }
    /**
     * Triggered when a track is removed from track list.
     *
     * @event TrackList#removetrack
     * @type {EventTarget~Event}
     * @property {Track} track
     *           A reference to track that was removed.
     */


    this.trigger({
      track: track,
      type: 'removetrack',
      target: this
    });
  }
  /**
   * Get a Track from the TrackList by a tracks id
   *
   * @param {string} id - the id of the track to get
   * @method getTrackById
   * @return {Track}
   * @private
   */
  ;

  _proto.getTrackById = function getTrackById(id) {
    var result = null;

    for (var i = 0, l = this.length; i < l; i++) {
      var track = this[i];

      if (track.id === id) {
        result = track;
        break;
      }
    }

    return result;
  };

  return TrackList;
}(EventTarget);
/**
 * Triggered when a different track is selected/enabled.
 *
 * @event TrackList#change
 * @type {EventTarget~Event}
 */

/**
 * Events that can be called with on + eventName. See {@link EventHandler}.
 *
 * @property {Object} TrackList#allowedEvents_
 * @private
 */


TrackList.prototype.allowedEvents_ = {
  change: 'change',
  addtrack: 'addtrack',
  removetrack: 'removetrack',
  labelchange: 'labelchange'
}; // emulate attribute EventHandler support to allow for feature detection

for (var event in TrackList.prototype.allowedEvents_) {
  TrackList.prototype['on' + event] = null;
}

/**
 * Anywhere we call this function we diverge from the spec
 * as we only support one enabled audiotrack at a time
 *
 * @param {AudioTrackList} list
 *        list to work on
 *
 * @param {AudioTrack} track
 *        The track to skip
 *
 * @private
 */

var disableOthers$1 = function disableOthers(list, track) {
  for (var i = 0; i < list.length; i++) {
    if (!Object.keys(list[i]).length || track.id === list[i].id) {
      continue;
    } // another audio track is enabled, disable it


    list[i].enabled = false;
  }
};
/**
 * The current list of {@link AudioTrack} for a media file.
 *
 * @see [Spec]{@link https://html.spec.whatwg.org/multipage/embedded-content.html#audiotracklist}
 * @extends TrackList
 */


var AudioTrackList = /*#__PURE__*/function (_TrackList) {
  _inheritsLoose__default['default'](AudioTrackList, _TrackList);

  /**
   * Create an instance of this class.
   *
   * @param {AudioTrack[]} [tracks=[]]
   *        A list of `AudioTrack` to instantiate the list with.
   */
  function AudioTrackList(tracks) {
    var _this;

    if (tracks === void 0) {
      tracks = [];
    }

    // make sure only 1 track is enabled
    // sorted from last index to first index
    for (var i = tracks.length - 1; i >= 0; i--) {
      if (tracks[i].enabled) {
        disableOthers$1(tracks, tracks[i]);
        break;
      }
    }

    _this = _TrackList.call(this, tracks) || this;
    _this.changing_ = false;
    return _this;
  }
  /**
   * Add an {@link AudioTrack} to the `AudioTrackList`.
   *
   * @param {AudioTrack} track
   *        The AudioTrack to add to the list
   *
   * @fires TrackList#addtrack
   */


  var _proto = AudioTrackList.prototype;

  _proto.addTrack = function addTrack(track) {
    var _this2 = this;

    if (track.enabled) {
      disableOthers$1(this, track);
    }

    _TrackList.prototype.addTrack.call(this, track); // native tracks don't have this


    if (!track.addEventListener) {
      return;
    }

    track.enabledChange_ = function () {
      // when we are disabling other tracks (since we don't support
      // more than one track at a time) we will set changing_
      // to true so that we don't trigger additional change events
      if (_this2.changing_) {
        return;
      }

      _this2.changing_ = true;
      disableOthers$1(_this2, track);
      _this2.changing_ = false;

      _this2.trigger('change');
    };
    /**
     * @listens AudioTrack#enabledchange
     * @fires TrackList#change
     */


    track.addEventListener('enabledchange', track.enabledChange_);
  };

  _proto.removeTrack = function removeTrack(rtrack) {
    _TrackList.prototype.removeTrack.call(this, rtrack);

    if (rtrack.removeEventListener && rtrack.enabledChange_) {
      rtrack.removeEventListener('enabledchange', rtrack.enabledChange_);
      rtrack.enabledChange_ = null;
    }
  };

  return AudioTrackList;
}(TrackList);

/**
 * Un-select all other {@link VideoTrack}s that are selected.
 *
 * @param {VideoTrackList} list
 *        list to work on
 *
 * @param {VideoTrack} track
 *        The track to skip
 *
 * @private
 */

var disableOthers = function disableOthers(list, track) {
  for (var i = 0; i < list.length; i++) {
    if (!Object.keys(list[i]).length || track.id === list[i].id) {
      continue;
    } // another video track is enabled, disable it


    list[i].selected = false;
  }
};
/**
 * The current list of {@link VideoTrack} for a video.
 *
 * @see [Spec]{@link https://html.spec.whatwg.org/multipage/embedded-content.html#videotracklist}
 * @extends TrackList
 */


var VideoTrackList = /*#__PURE__*/function (_TrackList) {
  _inheritsLoose__default['default'](VideoTrackList, _TrackList);

  /**
   * Create an instance of this class.
   *
   * @param {VideoTrack[]} [tracks=[]]
   *        A list of `VideoTrack` to instantiate the list with.
   */
  function VideoTrackList(tracks) {
    var _this;

    if (tracks === void 0) {
      tracks = [];
    }

    // make sure only 1 track is enabled
    // sorted from last index to first index
    for (var i = tracks.length - 1; i >= 0; i--) {
      if (tracks[i].selected) {
        disableOthers(tracks, tracks[i]);
        break;
      }
    }

    _this = _TrackList.call(this, tracks) || this;
    _this.changing_ = false;
    /**
     * @member {number} VideoTrackList#selectedIndex
     *         The current index of the selected {@link VideoTrack`}.
     */

    Object.defineProperty(_assertThisInitialized__default['default'](_this), 'selectedIndex', {
      get: function get() {
        for (var _i = 0; _i < this.length; _i++) {
          if (this[_i].selected) {
            return _i;
          }
        }

        return -1;
      },
      set: function set() {}
    });
    return _this;
  }
  /**
   * Add a {@link VideoTrack} to the `VideoTrackList`.
   *
   * @param {VideoTrack} track
   *        The VideoTrack to add to the list
   *
   * @fires TrackList#addtrack
   */


  var _proto = VideoTrackList.prototype;

  _proto.addTrack = function addTrack(track) {
    var _this2 = this;

    if (track.selected) {
      disableOthers(this, track);
    }

    _TrackList.prototype.addTrack.call(this, track); // native tracks don't have this


    if (!track.addEventListener) {
      return;
    }

    track.selectedChange_ = function () {
      if (_this2.changing_) {
        return;
      }

      _this2.changing_ = true;
      disableOthers(_this2, track);
      _this2.changing_ = false;

      _this2.trigger('change');
    };
    /**
     * @listens VideoTrack#selectedchange
     * @fires TrackList#change
     */


    track.addEventListener('selectedchange', track.selectedChange_);
  };

  _proto.removeTrack = function removeTrack(rtrack) {
    _TrackList.prototype.removeTrack.call(this, rtrack);

    if (rtrack.removeEventListener && rtrack.selectedChange_) {
      rtrack.removeEventListener('selectedchange', rtrack.selectedChange_);
      rtrack.selectedChange_ = null;
    }
  };

  return VideoTrackList;
}(TrackList);

/**
 * The current list of {@link TextTrack} for a media file.
 *
 * @see [Spec]{@link https://html.spec.whatwg.org/multipage/embedded-content.html#texttracklist}
 * @extends TrackList
 */

var TextTrackList = /*#__PURE__*/function (_TrackList) {
  _inheritsLoose__default['default'](TextTrackList, _TrackList);

  function TextTrackList() {
    return _TrackList.apply(this, arguments) || this;
  }

  var _proto = TextTrackList.prototype;

  /**
   * Add a {@link TextTrack} to the `TextTrackList`
   *
   * @param {TextTrack} track
   *        The text track to add to the list.
   *
   * @fires TrackList#addtrack
   */
  _proto.addTrack = function addTrack(track) {
    var _this = this;

    _TrackList.prototype.addTrack.call(this, track);

    if (!this.queueChange_) {
      this.queueChange_ = function () {
        return _this.queueTrigger('change');
      };
    }

    if (!this.triggerSelectedlanguagechange) {
      this.triggerSelectedlanguagechange_ = function () {
        return _this.trigger('selectedlanguagechange');
      };
    }
    /**
     * @listens TextTrack#modechange
     * @fires TrackList#change
     */


    track.addEventListener('modechange', this.queueChange_);
    var nonLanguageTextTrackKind = ['metadata', 'chapters'];

    if (nonLanguageTextTrackKind.indexOf(track.kind) === -1) {
      track.addEventListener('modechange', this.triggerSelectedlanguagechange_);
    }
  };

  _proto.removeTrack = function removeTrack(rtrack) {
    _TrackList.prototype.removeTrack.call(this, rtrack); // manually remove the event handlers we added


    if (rtrack.removeEventListener) {
      if (this.queueChange_) {
        rtrack.removeEventListener('modechange', this.queueChange_);
      }

      if (this.selectedlanguagechange_) {
        rtrack.removeEventListener('modechange', this.triggerSelectedlanguagechange_);
      }
    }
  };

  return TextTrackList;
}(TrackList);

/**
 * @file html-track-element-list.js
 */

/**
 * The current list of {@link HtmlTrackElement}s.
 */
var HtmlTrackElementList = /*#__PURE__*/function () {
  /**
   * Create an instance of this class.
   *
   * @param {HtmlTrackElement[]} [tracks=[]]
   *        A list of `HtmlTrackElement` to instantiate the list with.
   */
  function HtmlTrackElementList(trackElements) {
    if (trackElements === void 0) {
      trackElements = [];
    }

    this.trackElements_ = [];
    /**
     * @memberof HtmlTrackElementList
     * @member {number} length
     *         The current number of `Track`s in the this Trackist.
     * @instance
     */

    Object.defineProperty(this, 'length', {
      get: function get() {
        return this.trackElements_.length;
      }
    });

    for (var i = 0, length = trackElements.length; i < length; i++) {
      this.addTrackElement_(trackElements[i]);
    }
  }
  /**
   * Add an {@link HtmlTrackElement} to the `HtmlTrackElementList`
   *
   * @param {HtmlTrackElement} trackElement
   *        The track element to add to the list.
   *
   * @private
   */


  var _proto = HtmlTrackElementList.prototype;

  _proto.addTrackElement_ = function addTrackElement_(trackElement) {
    var index = this.trackElements_.length;

    if (!('' + index in this)) {
      Object.defineProperty(this, index, {
        get: function get() {
          return this.trackElements_[index];
        }
      });
    } // Do not add duplicate elements


    if (this.trackElements_.indexOf(trackElement) === -1) {
      this.trackElements_.push(trackElement);
    }
  }
  /**
   * Get an {@link HtmlTrackElement} from the `HtmlTrackElementList` given an
   * {@link TextTrack}.
   *
   * @param {TextTrack} track
   *        The track associated with a track element.
   *
   * @return {HtmlTrackElement|undefined}
   *         The track element that was found or undefined.
   *
   * @private
   */
  ;

  _proto.getTrackElementByTrack_ = function getTrackElementByTrack_(track) {
    var trackElement_;

    for (var i = 0, length = this.trackElements_.length; i < length; i++) {
      if (track === this.trackElements_[i].track) {
        trackElement_ = this.trackElements_[i];
        break;
      }
    }

    return trackElement_;
  }
  /**
   * Remove a {@link HtmlTrackElement} from the `HtmlTrackElementList`
   *
   * @param {HtmlTrackElement} trackElement
   *        The track element to remove from the list.
   *
   * @private
   */
  ;

  _proto.removeTrackElement_ = function removeTrackElement_(trackElement) {
    for (var i = 0, length = this.trackElements_.length; i < length; i++) {
      if (trackElement === this.trackElements_[i]) {
        if (this.trackElements_[i].track && typeof this.trackElements_[i].track.off === 'function') {
          this.trackElements_[i].track.off();
        }

        if (typeof this.trackElements_[i].off === 'function') {
          this.trackElements_[i].off();
        }

        this.trackElements_.splice(i, 1);
        break;
      }
    }
  };

  return HtmlTrackElementList;
}();

/**
 * @file text-track-cue-list.js
 */

/**
 * @typedef {Object} TextTrackCueList~TextTrackCue
 *
 * @property {string} id
 *           The unique id for this text track cue
 *
 * @property {number} startTime
 *           The start time for this text track cue
 *
 * @property {number} endTime
 *           The end time for this text track cue
 *
 * @property {boolean} pauseOnExit
 *           Pause when the end time is reached if true.
 *
 * @see [Spec]{@link https://html.spec.whatwg.org/multipage/embedded-content.html#texttrackcue}
 */

/**
 * A List of TextTrackCues.
 *
 * @see [Spec]{@link https://html.spec.whatwg.org/multipage/embedded-content.html#texttrackcuelist}
 */
var TextTrackCueList = /*#__PURE__*/function () {
  /**
   * Create an instance of this class..
   *
   * @param {Array} cues
   *        A list of cues to be initialized with
   */
  function TextTrackCueList(cues) {
    TextTrackCueList.prototype.setCues_.call(this, cues);
    /**
     * @memberof TextTrackCueList
     * @member {number} length
     *         The current number of `TextTrackCue`s in the TextTrackCueList.
     * @instance
     */

    Object.defineProperty(this, 'length', {
      get: function get() {
        return this.length_;
      }
    });
  }
  /**
   * A setter for cues in this list. Creates getters
   * an an index for the cues.
   *
   * @param {Array} cues
   *        An array of cues to set
   *
   * @private
   */


  var _proto = TextTrackCueList.prototype;

  _proto.setCues_ = function setCues_(cues) {
    var oldLength = this.length || 0;
    var i = 0;
    var l = cues.length;
    this.cues_ = cues;
    this.length_ = cues.length;

    var defineProp = function defineProp(index) {
      if (!('' + index in this)) {
        Object.defineProperty(this, '' + index, {
          get: function get() {
            return this.cues_[index];
          }
        });
      }
    };

    if (oldLength < l) {
      i = oldLength;

      for (; i < l; i++) {
        defineProp.call(this, i);
      }
    }
  }
  /**
   * Get a `TextTrackCue` that is currently in the `TextTrackCueList` by id.
   *
   * @param {string} id
   *        The id of the cue that should be searched for.
   *
   * @return {TextTrackCueList~TextTrackCue|null}
   *         A single cue or null if none was found.
   */
  ;

  _proto.getCueById = function getCueById(id) {
    var result = null;

    for (var i = 0, l = this.length; i < l; i++) {
      var cue = this[i];

      if (cue.id === id) {
        result = cue;
        break;
      }
    }

    return result;
  };

  return TextTrackCueList;
}();

/**
 * @file track-kinds.js
 */

/**
 * All possible `VideoTrackKind`s
 *
 * @see https://html.spec.whatwg.org/multipage/embedded-content.html#dom-videotrack-kind
 * @typedef VideoTrack~Kind
 * @enum
 */
var VideoTrackKind = {
  alternative: 'alternative',
  captions: 'captions',
  main: 'main',
  sign: 'sign',
  subtitles: 'subtitles',
  commentary: 'commentary'
};
/**
 * All possible `AudioTrackKind`s
 *
 * @see https://html.spec.whatwg.org/multipage/embedded-content.html#dom-audiotrack-kind
 * @typedef AudioTrack~Kind
 * @enum
 */

var AudioTrackKind = {
  'alternative': 'alternative',
  'descriptions': 'descriptions',
  'main': 'main',
  'main-desc': 'main-desc',
  'translation': 'translation',
  'commentary': 'commentary'
};
/**
 * All possible `TextTrackKind`s
 *
 * @see https://html.spec.whatwg.org/multipage/embedded-content.html#dom-texttrack-kind
 * @typedef TextTrack~Kind
 * @enum
 */

var TextTrackKind = {
  subtitles: 'subtitles',
  captions: 'captions',
  descriptions: 'descriptions',
  chapters: 'chapters',
  metadata: 'metadata'
};
/**
 * All possible `TextTrackMode`s
 *
 * @see https://html.spec.whatwg.org/multipage/embedded-content.html#texttrackmode
 * @typedef TextTrack~Mode
 * @enum
 */

var TextTrackMode = {
  disabled: 'disabled',
  hidden: 'hidden',
  showing: 'showing'
};

/**
 * A Track class that contains all of the common functionality for {@link AudioTrack},
 * {@link VideoTrack}, and {@link TextTrack}.
 *
 * > Note: This class should not be used directly
 *
 * @see {@link https://html.spec.whatwg.org/multipage/embedded-content.html}
 * @extends EventTarget
 * @abstract
 */

var Track = /*#__PURE__*/function (_EventTarget) {
  _inheritsLoose__default['default'](Track, _EventTarget);

  /**
   * Create an instance of this class.
   *
   * @param {Object} [options={}]
   *        Object of option names and values
   *
   * @param {string} [options.kind='']
   *        A valid kind for the track type you are creating.
   *
   * @param {string} [options.id='vjs_track_' + Guid.newGUID()]
   *        A unique id for this AudioTrack.
   *
   * @param {string} [options.label='']
   *        The menu label for this track.
   *
   * @param {string} [options.language='']
   *        A valid two character language code.
   *
   * @abstract
   */
  function Track(options) {
    var _this;

    if (options === void 0) {
      options = {};
    }

    _this = _EventTarget.call(this) || this;
    var trackProps = {
      id: options.id || 'vjs_track_' + newGUID(),
      kind: options.kind || '',
      language: options.language || ''
    };
    var label = options.label || '';
    /**
     * @memberof Track
     * @member {string} id
     *         The id of this track. Cannot be changed after creation.
     * @instance
     *
     * @readonly
     */

    /**
     * @memberof Track
     * @member {string} kind
     *         The kind of track that this is. Cannot be changed after creation.
     * @instance
     *
     * @readonly
     */

    /**
     * @memberof Track
     * @member {string} language
     *         The two letter language code for this track. Cannot be changed after
     *         creation.
     * @instance
     *
     * @readonly
     */

    var _loop = function _loop(key) {
      Object.defineProperty(_assertThisInitialized__default['default'](_this), key, {
        get: function get() {
          return trackProps[key];
        },
        set: function set() {}
      });
    };

    for (var key in trackProps) {
      _loop(key);
    }
    /**
     * @memberof Track
     * @member {string} label
     *         The label of this track. Cannot be changed after creation.
     * @instance
     *
     * @fires Track#labelchange
     */


    Object.defineProperty(_assertThisInitialized__default['default'](_this), 'label', {
      get: function get() {
        return label;
      },
      set: function set(newLabel) {
        if (newLabel !== label) {
          label = newLabel;
          /**
           * An event that fires when label changes on this track.
           *
           * > Note: This is not part of the spec!
           *
           * @event Track#labelchange
           * @type {EventTarget~Event}
           */

          this.trigger('labelchange');
        }
      }
    });
    return _this;
  }

  return Track;
}(EventTarget);

/**
 * @file url.js
 * @module url
 */
/**
 * @typedef {Object} url:URLObject
 *
 * @property {string} protocol
 *           The protocol of the url that was parsed.
 *
 * @property {string} hostname
 *           The hostname of the url that was parsed.
 *
 * @property {string} port
 *           The port of the url that was parsed.
 *
 * @property {string} pathname
 *           The pathname of the url that was parsed.
 *
 * @property {string} search
 *           The search query of the url that was parsed.
 *
 * @property {string} hash
 *           The hash of the url that was parsed.
 *
 * @property {string} host
 *           The host of the url that was parsed.
 */

/**
 * Resolve and parse the elements of a URL.
 *
 * @function
 * @param    {String} url
 *           The url to parse
 *
 * @return   {url:URLObject}
 *           An object of url details
 */

var parseUrl = function parseUrl(url) {
  // This entire method can be replace with URL once we are able to drop IE11
  var props = ['protocol', 'hostname', 'port', 'pathname', 'search', 'hash', 'host']; // add the url to an anchor and let the browser parse the URL

  var a = document__default['default'].createElement('a');
  a.href = url; // Copy the specific URL properties to a new object
  // This is also needed for IE because the anchor loses its
  // properties when it's removed from the dom

  var details = {};

  for (var i = 0; i < props.length; i++) {
    details[props[i]] = a[props[i]];
  } // IE adds the port to the host property unlike everyone else. If
  // a port identifier is added for standard ports, strip it.


  if (details.protocol === 'http:') {
    details.host = details.host.replace(/:80$/, '');
  }

  if (details.protocol === 'https:') {
    details.host = details.host.replace(/:443$/, '');
  }

  if (!details.protocol) {
    details.protocol = window__default['default'].location.protocol;
  }
  /* istanbul ignore if */


  if (!details.host) {
    details.host = window__default['default'].location.host;
  }

  return details;
};
/**
 * Get absolute version of relative URL. Used to tell Flash the correct URL.
 *
 * @function
 * @param    {string} url
 *           URL to make absolute
 *
 * @return   {string}
 *           Absolute URL
 *
 * @see      http://stackoverflow.com/questions/470832/getting-an-absolute-url-from-a-relative-one-ie6-issue
 */

var getAbsoluteURL = function getAbsoluteURL(url) {
  // Check if absolute URL
  if (!url.match(/^https?:\/\//)) {
    // Convert to absolute URL. Flash hosted off-site needs an absolute URL.
    // add the url to an anchor and let the browser parse the URL
    var a = document__default['default'].createElement('a');
    a.href = url;
    url = a.href;
  }

  return url;
};
/**
 * Returns the extension of the passed file name. It will return an empty string
 * if passed an invalid path.
 *
 * @function
 * @param    {string} path
 *           The fileName path like '/path/to/file.mp4'
 *
 * @return  {string}
 *           The extension in lower case or an empty string if no
 *           extension could be found.
 */

var getFileExtension = function getFileExtension(path) {
  if (typeof path === 'string') {
    var splitPathRe = /^(\/?)([\s\S]*?)((?:\.{1,2}|[^\/]+?)(\.([^\.\/\?]+)))(?:[\/]*|[\?].*)$/;
    var pathParts = splitPathRe.exec(path);

    if (pathParts) {
      return pathParts.pop().toLowerCase();
    }
  }

  return '';
};
/**
 * Returns whether the url passed is a cross domain request or not.
 *
 * @function
 * @param    {string} url
 *           The url to check.
 *
 * @param    {Object} [winLoc]
 *           the domain to check the url against, defaults to window.location
 *
 * @param    {string} [winLoc.protocol]
 *           The window location protocol defaults to window.location.protocol
 *
 * @param    {string} [winLoc.host]
 *           The window location host defaults to window.location.host
 *
 * @return   {boolean}
 *           Whether it is a cross domain request or not.
 */

var isCrossOrigin = function isCrossOrigin(url, winLoc) {
  if (winLoc === void 0) {
    winLoc = window__default['default'].location;
  }

  var urlInfo = parseUrl(url); // IE8 protocol relative urls will return ':' for protocol

  var srcProtocol = urlInfo.protocol === ':' ? winLoc.protocol : urlInfo.protocol; // Check if url is for another domain/origin
  // IE8 doesn't know location.origin, so we won't rely on it here

  var crossOrigin = srcProtocol + urlInfo.host !== winLoc.protocol + winLoc.host;
  return crossOrigin;
};

var Url = /*#__PURE__*/Object.freeze({
  __proto__: null,
  parseUrl: parseUrl,
  getAbsoluteURL: getAbsoluteURL,
  getFileExtension: getFileExtension,
  isCrossOrigin: isCrossOrigin
});

/**
 * Takes a webvtt file contents and parses it into cues
 *
 * @param {string} srcContent
 *        webVTT file contents
 *
 * @param {TextTrack} track
 *        TextTrack to add cues to. Cues come from the srcContent.
 *
 * @private
 */

var parseCues = function parseCues(srcContent, track) {
  var parser = new window__default['default'].WebVTT.Parser(window__default['default'], window__default['default'].vttjs, window__default['default'].WebVTT.StringDecoder());
  var errors = [];

  parser.oncue = function (cue) {
    track.addCue(cue);
  };

  parser.onparsingerror = function (error) {
    errors.push(error);
  };

  parser.onflush = function () {
    track.trigger({
      type: 'loadeddata',
      target: track
    });
  };

  parser.parse(srcContent);

  if (errors.length > 0) {
    if (window__default['default'].console && window__default['default'].console.groupCollapsed) {
      window__default['default'].console.groupCollapsed("Text Track parsing errors for " + track.src);
    }

    errors.forEach(function (error) {
      return log.error(error);
    });

    if (window__default['default'].console && window__default['default'].console.groupEnd) {
      window__default['default'].console.groupEnd();
    }
  }

  parser.flush();
};
/**
 * Load a `TextTrack` from a specified url.
 *
 * @param {string} src
 *        Url to load track from.
 *
 * @param {TextTrack} track
 *        Track to add cues to. Comes from the content at the end of `url`.
 *
 * @private
 */


var loadTrack = function loadTrack(src, track) {
  var opts = {
    uri: src
  };
  var crossOrigin = isCrossOrigin(src);

  if (crossOrigin) {
    opts.cors = crossOrigin;
  }

  var withCredentials = track.tech_.crossOrigin() === 'use-credentials';

  if (withCredentials) {
    opts.withCredentials = withCredentials;
  }

  XHR__default['default'](opts, bind(this, function (err, response, responseBody) {
    if (err) {
      return log.error(err, response);
    }

    track.loaded_ = true; // Make sure that vttjs has loaded, otherwise, wait till it finished loading
    // NOTE: this is only used for the alt/video.novtt.js build

    if (typeof window__default['default'].WebVTT !== 'function') {
      if (track.tech_) {
        // to prevent use before define eslint error, we define loadHandler
        // as a let here
        track.tech_.any(['vttjsloaded', 'vttjserror'], function (event) {
          if (event.type === 'vttjserror') {
            log.error("vttjs failed to load, stopping trying to process " + track.src);
            return;
          }

          return parseCues(responseBody, track);
        });
      }
    } else {
      parseCues(responseBody, track);
    }
  }));
};
/**
 * A representation of a single `TextTrack`.
 *
 * @see [Spec]{@link https://html.spec.whatwg.org/multipage/embedded-content.html#texttrack}
 * @extends Track
 */


var TextTrack = /*#__PURE__*/function (_Track) {
  _inheritsLoose__default['default'](TextTrack, _Track);

  /**
   * Create an instance of this class.
   *
   * @param {Object} options={}
   *        Object of option names and values
   *
   * @param {Tech} options.tech
   *        A reference to the tech that owns this TextTrack.
   *
   * @param {TextTrack~Kind} [options.kind='subtitles']
   *        A valid text track kind.
   *
   * @param {TextTrack~Mode} [options.mode='disabled']
   *        A valid text track mode.
   *
   * @param {string} [options.id='vjs_track_' + Guid.newGUID()]
   *        A unique id for this TextTrack.
   *
   * @param {string} [options.label='']
   *        The menu label for this track.
   *
   * @param {string} [options.language='']
   *        A valid two character language code.
   *
   * @param {string} [options.srclang='']
   *        A valid two character language code. An alternative, but deprioritized
   *        version of `options.language`
   *
   * @param {string} [options.src]
   *        A url to TextTrack cues.
   *
   * @param {boolean} [options.default]
   *        If this track should default to on or off.
   */
  function TextTrack(options) {
    var _this;

    if (options === void 0) {
      options = {};
    }

    if (!options.tech) {
      throw new Error('A tech was not provided.');
    }

    var settings = mergeOptions(options, {
      kind: TextTrackKind[options.kind] || 'subtitles',
      language: options.language || options.srclang || ''
    });
    var mode = TextTrackMode[settings.mode] || 'disabled';
    var default_ = settings["default"];

    if (settings.kind === 'metadata' || settings.kind === 'chapters') {
      mode = 'hidden';
    }

    _this = _Track.call(this, settings) || this;
    _this.tech_ = settings.tech;
    _this.cues_ = [];
    _this.activeCues_ = [];
    _this.preload_ = _this.tech_.preloadTextTracks !== false;
    var cues = new TextTrackCueList(_this.cues_);
    var activeCues = new TextTrackCueList(_this.activeCues_);
    var changed = false;
    var timeupdateHandler = bind(_assertThisInitialized__default['default'](_this), function () {
      if (!this.tech_.isReady_ || this.tech_.isDisposed()) {
        return;
      } // Accessing this.activeCues for the side-effects of updating itself
      // due to its nature as a getter function. Do not remove or cues will
      // stop updating!
      // Use the setter to prevent deletion from uglify (pure_getters rule)


      this.activeCues = this.activeCues;

      if (changed) {
        this.trigger('cuechange');
        changed = false;
      }
    });

    var disposeHandler = function disposeHandler() {
      _this.tech_.off('timeupdate', timeupdateHandler);
    };

    _this.tech_.one('dispose', disposeHandler);

    if (mode !== 'disabled') {
      _this.tech_.on('timeupdate', timeupdateHandler);
    }

    Object.defineProperties(_assertThisInitialized__default['default'](_this), {
      /**
       * @memberof TextTrack
       * @member {boolean} default
       *         If this track was set to be on or off by default. Cannot be changed after
       *         creation.
       * @instance
       *
       * @readonly
       */
      "default": {
        get: function get() {
          return default_;
        },
        set: function set() {}
      },

      /**
       * @memberof TextTrack
       * @member {string} mode
       *         Set the mode of this TextTrack to a valid {@link TextTrack~Mode}. Will
       *         not be set if setting to an invalid mode.
       * @instance
       *
       * @fires TextTrack#modechange
       */
      mode: {
        get: function get() {
          return mode;
        },
        set: function set(newMode) {
          if (!TextTrackMode[newMode]) {
            return;
          }

          if (mode === newMode) {
            return;
          }

          mode = newMode;

          if (!this.preload_ && mode !== 'disabled' && this.cues.length === 0) {
            // On-demand load.
            loadTrack(this.src, this);
          }

          this.tech_.off('timeupdate', timeupdateHandler);

          if (mode !== 'disabled') {
            this.tech_.on('timeupdate', timeupdateHandler);
          }
          /**
           * An event that fires when mode changes on this track. This allows
           * the TextTrackList that holds this track to act accordingly.
           *
           * > Note: This is not part of the spec!
           *
           * @event TextTrack#modechange
           * @type {EventTarget~Event}
           */


          this.trigger('modechange');
        }
      },

      /**
       * @memberof TextTrack
       * @member {TextTrackCueList} cues
       *         The text track cue list for this TextTrack.
       * @instance
       */
      cues: {
        get: function get() {
          if (!this.loaded_) {
            return null;
          }

          return cues;
        },
        set: function set() {}
      },

      /**
       * @memberof TextTrack
       * @member {TextTrackCueList} activeCues
       *         The list text track cues that are currently active for this TextTrack.
       * @instance
       */
      activeCues: {
        get: function get() {
          if (!this.loaded_) {
            return null;
          } // nothing to do


          if (this.cues.length === 0) {
            return activeCues;
          }

          var ct = this.tech_.currentTime();
          var active = [];

          for (var i = 0, l = this.cues.length; i < l; i++) {
            var cue = this.cues[i];

            if (cue.startTime <= ct && cue.endTime >= ct) {
              active.push(cue);
            } else if (cue.startTime === cue.endTime && cue.startTime <= ct && cue.startTime + 0.5 >= ct) {
              active.push(cue);
            }
          }

          changed = false;

          if (active.length !== this.activeCues_.length) {
            changed = true;
          } else {
            for (var _i = 0; _i < active.length; _i++) {
              if (this.activeCues_.indexOf(active[_i]) === -1) {
                changed = true;
              }
            }
          }

          this.activeCues_ = active;
          activeCues.setCues_(this.activeCues_);
          return activeCues;
        },
        // /!\ Keep this setter empty (see the timeupdate handler above)
        set: function set() {}
      }
    });

    if (settings.src) {
      _this.src = settings.src;

      if (!_this.preload_) {
        // Tracks will load on-demand.
        // Act like we're loaded for other purposes.
        _this.loaded_ = true;
      }

      if (_this.preload_ || settings.kind !== 'subtitles' && settings.kind !== 'captions') {
        loadTrack(_this.src, _assertThisInitialized__default['default'](_this));
      }
    } else {
      _this.loaded_ = true;
    }

    return _this;
  }
  /**
   * Add a cue to the internal list of cues.
   *
   * @param {TextTrack~Cue} cue
   *        The cue to add to our internal list
   */


  var _proto = TextTrack.prototype;

  _proto.addCue = function addCue(originalCue) {
    var cue = originalCue;

    if (window__default['default'].vttjs && !(originalCue instanceof window__default['default'].vttjs.VTTCue)) {
      cue = new window__default['default'].vttjs.VTTCue(originalCue.startTime, originalCue.endTime, originalCue.text);

      for (var prop in originalCue) {
        if (!(prop in cue)) {
          cue[prop] = originalCue[prop];
        }
      } // make sure that `id` is copied over


      cue.id = originalCue.id;
      cue.originalCue_ = originalCue;
    }

    var tracks = this.tech_.textTracks();

    for (var i = 0; i < tracks.length; i++) {
      if (tracks[i] !== this) {
        tracks[i].removeCue(cue);
      }
    }

    this.cues_.push(cue);
    this.cues.setCues_(this.cues_);
  }
  /**
   * Remove a cue from our internal list
   *
   * @param {TextTrack~Cue} removeCue
   *        The cue to remove from our internal list
   */
  ;

  _proto.removeCue = function removeCue(_removeCue) {
    var i = this.cues_.length;

    while (i--) {
      var cue = this.cues_[i];

      if (cue === _removeCue || cue.originalCue_ && cue.originalCue_ === _removeCue) {
        this.cues_.splice(i, 1);
        this.cues.setCues_(this.cues_);
        break;
      }
    }
  };

  return TextTrack;
}(Track);
/**
 * cuechange - One or more cues in the track have become active or stopped being active.
 */


TextTrack.prototype.allowedEvents_ = {
  cuechange: 'cuechange'
};

/**
 * A representation of a single `AudioTrack`. If it is part of an {@link AudioTrackList}
 * only one `AudioTrack` in the list will be enabled at a time.
 *
 * @see [Spec]{@link https://html.spec.whatwg.org/multipage/embedded-content.html#audiotrack}
 * @extends Track
 */

var AudioTrack = /*#__PURE__*/function (_Track) {
  _inheritsLoose__default['default'](AudioTrack, _Track);

  /**
   * Create an instance of this class.
   *
   * @param {Object} [options={}]
   *        Object of option names and values
   *
   * @param {AudioTrack~Kind} [options.kind='']
   *        A valid audio track kind
   *
   * @param {string} [options.id='vjs_track_' + Guid.newGUID()]
   *        A unique id for this AudioTrack.
   *
   * @param {string} [options.label='']
   *        The menu label for this track.
   *
   * @param {string} [options.language='']
   *        A valid two character language code.
   *
   * @param {boolean} [options.enabled]
   *        If this track is the one that is currently playing. If this track is part of
   *        an {@link AudioTrackList}, only one {@link AudioTrack} will be enabled.
   */
  function AudioTrack(options) {
    var _this;

    if (options === void 0) {
      options = {};
    }

    var settings = mergeOptions(options, {
      kind: AudioTrackKind[options.kind] || ''
    });
    _this = _Track.call(this, settings) || this;
    var enabled = false;
    /**
     * @memberof AudioTrack
     * @member {boolean} enabled
     *         If this `AudioTrack` is enabled or not. When setting this will
     *         fire {@link AudioTrack#enabledchange} if the state of enabled is changed.
     * @instance
     *
     * @fires VideoTrack#selectedchange
     */

    Object.defineProperty(_assertThisInitialized__default['default'](_this), 'enabled', {
      get: function get() {
        return enabled;
      },
      set: function set(newEnabled) {
        // an invalid or unchanged value
        if (typeof newEnabled !== 'boolean' || newEnabled === enabled) {
          return;
        }

        enabled = newEnabled;
        /**
         * An event that fires when enabled changes on this track. This allows
         * the AudioTrackList that holds this track to act accordingly.
         *
         * > Note: This is not part of the spec! Native tracks will do
         *         this internally without an event.
         *
         * @event AudioTrack#enabledchange
         * @type {EventTarget~Event}
         */

        this.trigger('enabledchange');
      }
    }); // if the user sets this track to selected then
    // set selected to that true value otherwise
    // we keep it false

    if (settings.enabled) {
      _this.enabled = settings.enabled;
    }

    _this.loaded_ = true;
    return _this;
  }

  return AudioTrack;
}(Track);

/**
 * A representation of a single `VideoTrack`.
 *
 * @see [Spec]{@link https://html.spec.whatwg.org/multipage/embedded-content.html#videotrack}
 * @extends Track
 */

var VideoTrack = /*#__PURE__*/function (_Track) {
  _inheritsLoose__default['default'](VideoTrack, _Track);

  /**
   * Create an instance of this class.
   *
   * @param {Object} [options={}]
   *        Object of option names and values
   *
   * @param {string} [options.kind='']
   *        A valid {@link VideoTrack~Kind}
   *
   * @param {string} [options.id='vjs_track_' + Guid.newGUID()]
   *        A unique id for this AudioTrack.
   *
   * @param {string} [options.label='']
   *        The menu label for this track.
   *
   * @param {string} [options.language='']
   *        A valid two character language code.
   *
   * @param {boolean} [options.selected]
   *        If this track is the one that is currently playing.
   */
  function VideoTrack(options) {
    var _this;

    if (options === void 0) {
      options = {};
    }

    var settings = mergeOptions(options, {
      kind: VideoTrackKind[options.kind] || ''
    });
    _this = _Track.call(this, settings) || this;
    var selected = false;
    /**
     * @memberof VideoTrack
     * @member {boolean} selected
     *         If this `VideoTrack` is selected or not. When setting this will
     *         fire {@link VideoTrack#selectedchange} if the state of selected changed.
     * @instance
     *
     * @fires VideoTrack#selectedchange
     */

    Object.defineProperty(_assertThisInitialized__default['default'](_this), 'selected', {
      get: function get() {
        return selected;
      },
      set: function set(newSelected) {
        // an invalid or unchanged value
        if (typeof newSelected !== 'boolean' || newSelected === selected) {
          return;
        }

        selected = newSelected;
        /**
         * An event that fires when selected changes on this track. This allows
         * the VideoTrackList that holds this track to act accordingly.
         *
         * > Note: This is not part of the spec! Native tracks will do
         *         this internally without an event.
         *
         * @event VideoTrack#selectedchange
         * @type {EventTarget~Event}
         */

        this.trigger('selectedchange');
      }
    }); // if the user sets this track to selected then
    // set selected to that true value otherwise
    // we keep it false

    if (settings.selected) {
      _this.selected = settings.selected;
    }

    return _this;
  }

  return VideoTrack;
}(Track);

/**
 * @memberof HTMLTrackElement
 * @typedef {HTMLTrackElement~ReadyState}
 * @enum {number}
 */

var NONE = 0;
var LOADING = 1;
var LOADED = 2;
var ERROR = 3;
/**
 * A single track represented in the DOM.
 *
 * @see [Spec]{@link https://html.spec.whatwg.org/multipage/embedded-content.html#htmltrackelement}
 * @extends EventTarget
 */

var HTMLTrackElement = /*#__PURE__*/function (_EventTarget) {
  _inheritsLoose__default['default'](HTMLTrackElement, _EventTarget);

  /**
   * Create an instance of this class.
   *
   * @param {Object} options={}
   *        Object of option names and values
   *
   * @param {Tech} options.tech
   *        A reference to the tech that owns this HTMLTrackElement.
   *
   * @param {TextTrack~Kind} [options.kind='subtitles']
   *        A valid text track kind.
   *
   * @param {TextTrack~Mode} [options.mode='disabled']
   *        A valid text track mode.
   *
   * @param {string} [options.id='vjs_track_' + Guid.newGUID()]
   *        A unique id for this TextTrack.
   *
   * @param {string} [options.label='']
   *        The menu label for this track.
   *
   * @param {string} [options.language='']
   *        A valid two character language code.
   *
   * @param {string} [options.srclang='']
   *        A valid two character language code. An alternative, but deprioritized
   *        version of `options.language`
   *
   * @param {string} [options.src]
   *        A url to TextTrack cues.
   *
   * @param {boolean} [options.default]
   *        If this track should default to on or off.
   */
  function HTMLTrackElement(options) {
    var _this;

    if (options === void 0) {
      options = {};
    }

    _this = _EventTarget.call(this) || this;
    var readyState;
    var track = new TextTrack(options);
    _this.kind = track.kind;
    _this.src = track.src;
    _this.srclang = track.language;
    _this.label = track.label;
    _this["default"] = track["default"];
    Object.defineProperties(_assertThisInitialized__default['default'](_this), {
      /**
       * @memberof HTMLTrackElement
       * @member {HTMLTrackElement~ReadyState} readyState
       *         The current ready state of the track element.
       * @instance
       */
      readyState: {
        get: function get() {
          return readyState;
        }
      },

      /**
       * @memberof HTMLTrackElement
       * @member {TextTrack} track
       *         The underlying TextTrack object.
       * @instance
       *
       */
      track: {
        get: function get() {
          return track;
        }
      }
    });
    readyState = NONE;
    /**
     * @listens TextTrack#loadeddata
     * @fires HTMLTrackElement#load
     */

    track.addEventListener('loadeddata', function () {
      readyState = LOADED;

      _this.trigger({
        type: 'load',
        target: _assertThisInitialized__default['default'](_this)
      });
    });
    return _this;
  }

  return HTMLTrackElement;
}(EventTarget);

HTMLTrackElement.prototype.allowedEvents_ = {
  load: 'load'
};
HTMLTrackElement.NONE = NONE;
HTMLTrackElement.LOADING = LOADING;
HTMLTrackElement.LOADED = LOADED;
HTMLTrackElement.ERROR = ERROR;

/*
 * This file contains all track properties that are used in
 * player.js, tech.js, html5.js and possibly other techs in the future.
 */

var NORMAL = {
  audio: {
    ListClass: AudioTrackList,
    TrackClass: AudioTrack,
    capitalName: 'Audio'
  },
  video: {
    ListClass: VideoTrackList,
    TrackClass: VideoTrack,
    capitalName: 'Video'
  },
  text: {
    ListClass: TextTrackList,
    TrackClass: TextTrack,
    capitalName: 'Text'
  }
};
Object.keys(NORMAL).forEach(function (type) {
  NORMAL[type].getterName = type + "Tracks";
  NORMAL[type].privateName = type + "Tracks_";
});
var REMOTE = {
  remoteText: {
    ListClass: TextTrackList,
    TrackClass: TextTrack,
    capitalName: 'RemoteText',
    getterName: 'remoteTextTracks',
    privateName: 'remoteTextTracks_'
  },
  remoteTextEl: {
    ListClass: HtmlTrackElementList,
    TrackClass: HTMLTrackElement,
    capitalName: 'RemoteTextTrackEls',
    getterName: 'remoteTextTrackEls',
    privateName: 'remoteTextTrackEls_'
  }
};

var ALL = _extends__default['default']({}, NORMAL, REMOTE);

REMOTE.names = Object.keys(REMOTE);
NORMAL.names = Object.keys(NORMAL);
ALL.names = [].concat(REMOTE.names).concat(NORMAL.names);

/**
 * An Object containing a structure like: `{src: 'url', type: 'mimetype'}` or string
 * that just contains the src url alone.
 * * `var SourceObject = {src: 'http://ex.com/video.mp4', type: 'video/mp4'};`
   * `var SourceString = 'http://example.com/some-video.mp4';`
 *
 * @typedef {Object|string} Tech~SourceObject
 *
 * @property {string} src
 *           The url to the source
 *
 * @property {string} type
 *           The mime type of the source
 */

/**
 * A function used by {@link Tech} to create a new {@link TextTrack}.
 *
 * @private
 *
 * @param {Tech} self
 *        An instance of the Tech class.
 *
 * @param {string} kind
 *        `TextTrack` kind (subtitles, captions, descriptions, chapters, or metadata)
 *
 * @param {string} [label]
 *        Label to identify the text track
 *
 * @param {string} [language]
 *        Two letter language abbreviation
 *
 * @param {Object} [options={}]
 *        An object with additional text track options
 *
 * @return {TextTrack}
 *          The text track that was created.
 */

function createTrackHelper(self, kind, label, language, options) {
  if (options === void 0) {
    options = {};
  }

  var tracks = self.textTracks();
  options.kind = kind;

  if (label) {
    options.label = label;
  }

  if (language) {
    options.language = language;
  }

  options.tech = self;
  var track = new ALL.text.TrackClass(options);
  tracks.addTrack(track);
  return track;
}
/**
 * This is the base class for media playback technology controllers, such as
 * {@link HTML5}
 *
 * @extends Component
 */


var Tech = /*#__PURE__*/function (_Component) {
  _inheritsLoose__default['default'](Tech, _Component);

  /**
  * Create an instance of this Tech.
  *
  * @param {Object} [options]
  *        The key/value store of player options.
  *
  * @param {Component~ReadyCallback} ready
  *        Callback function to call when the `HTML5` Tech is ready.
  */
  function Tech(options, ready) {
    var _this;

    if (options === void 0) {
      options = {};
    }

    if (ready === void 0) {
      ready = function ready() {};
    }

    // we don't want the tech to report user activity automatically.
    // This is done manually in addControlsListeners
    options.reportTouchActivity = false;
    _this = _Component.call(this, null, options, ready) || this;

    _this.onDurationChange_ = function (e) {
      return _this.onDurationChange(e);
    };

    _this.trackProgress_ = function (e) {
      return _this.trackProgress(e);
    };

    _this.trackCurrentTime_ = function (e) {
      return _this.trackCurrentTime(e);
    };

    _this.stopTrackingCurrentTime_ = function (e) {
      return _this.stopTrackingCurrentTime(e);
    };

    _this.disposeSourceHandler_ = function (e) {
      return _this.disposeSourceHandler(e);
    }; // keep track of whether the current source has played at all to
    // implement a very limited played()


    _this.hasStarted_ = false;

    _this.on('playing', function () {
      this.hasStarted_ = true;
    });

    _this.on('loadstart', function () {
      this.hasStarted_ = false;
    });

    ALL.names.forEach(function (name) {
      var props = ALL[name];

      if (options && options[props.getterName]) {
        _this[props.privateName] = options[props.getterName];
      }
    }); // Manually track progress in cases where the browser/tech doesn't report it.

    if (!_this.featuresProgressEvents) {
      _this.manualProgressOn();
    } // Manually track timeupdates in cases where the browser/tech doesn't report it.


    if (!_this.featuresTimeupdateEvents) {
      _this.manualTimeUpdatesOn();
    }

    ['Text', 'Audio', 'Video'].forEach(function (track) {
      if (options["native" + track + "Tracks"] === false) {
        _this["featuresNative" + track + "Tracks"] = false;
      }
    });

    if (options.nativeCaptions === false || options.nativeTextTracks === false) {
      _this.featuresNativeTextTracks = false;
    } else if (options.nativeCaptions === true || options.nativeTextTracks === true) {
      _this.featuresNativeTextTracks = true;
    }

    if (!_this.featuresNativeTextTracks) {
      _this.emulateTextTracks();
    }

    _this.preloadTextTracks = options.preloadTextTracks !== false;
    _this.autoRemoteTextTracks_ = new ALL.text.ListClass();

    _this.initTrackListeners(); // Turn on component tap events only if not using native controls


    if (!options.nativeControlsForTouch) {
      _this.emitTapEvents();
    }

    if (_this.constructor) {
      _this.name_ = _this.constructor.name || 'Unknown Tech';
    }

    return _this;
  }
  /**
   * A special function to trigger source set in a way that will allow player
   * to re-trigger if the player or tech are not ready yet.
   *
   * @fires Tech#sourceset
   * @param {string} src The source string at the time of the source changing.
   */


  var _proto = Tech.prototype;

  _proto.triggerSourceset = function triggerSourceset(src) {
    var _this2 = this;

    if (!this.isReady_) {
      // on initial ready we have to trigger source set
      // 1ms after ready so that player can watch for it.
      this.one('ready', function () {
        return _this2.setTimeout(function () {
          return _this2.triggerSourceset(src);
        }, 1);
      });
    }
    /**
     * Fired when the source is set on the tech causing the media element
     * to reload.
     *
     * @see {@link Player#event:sourceset}
     * @event Tech#sourceset
     * @type {EventTarget~Event}
     */


    this.trigger({
      src: src,
      type: 'sourceset'
    });
  }
  /* Fallbacks for unsupported event types
  ================================================================================ */

  /**
   * Polyfill the `progress` event for browsers that don't support it natively.
   *
   * @see {@link Tech#trackProgress}
   */
  ;

  _proto.manualProgressOn = function manualProgressOn() {
    this.on('durationchange', this.onDurationChange_);
    this.manualProgress = true; // Trigger progress watching when a source begins loading

    this.one('ready', this.trackProgress_);
  }
  /**
   * Turn off the polyfill for `progress` events that was created in
   * {@link Tech#manualProgressOn}
   */
  ;

  _proto.manualProgressOff = function manualProgressOff() {
    this.manualProgress = false;
    this.stopTrackingProgress();
    this.off('durationchange', this.onDurationChange_);
  }
  /**
   * This is used to trigger a `progress` event when the buffered percent changes. It
   * sets an interval function that will be called every 500 milliseconds to check if the
   * buffer end percent has changed.
   *
   * > This function is called by {@link Tech#manualProgressOn}
   *
   * @param {EventTarget~Event} event
   *        The `ready` event that caused this to run.
   *
   * @listens Tech#ready
   * @fires Tech#progress
   */
  ;

  _proto.trackProgress = function trackProgress(event) {
    this.stopTrackingProgress();
    this.progressInterval = this.setInterval(bind(this, function () {
      // Don't trigger unless buffered amount is greater than last time
      var numBufferedPercent = this.bufferedPercent();

      if (this.bufferedPercent_ !== numBufferedPercent) {
        /**
         * See {@link Player#progress}
         *
         * @event Tech#progress
         * @type {EventTarget~Event}
         */
        this.trigger('progress');
      }

      this.bufferedPercent_ = numBufferedPercent;

      if (numBufferedPercent === 1) {
        this.stopTrackingProgress();
      }
    }), 500);
  }
  /**
   * Update our internal duration on a `durationchange` event by calling
   * {@link Tech#duration}.
   *
   * @param {EventTarget~Event} event
   *        The `durationchange` event that caused this to run.
   *
   * @listens Tech#durationchange
   */
  ;

  _proto.onDurationChange = function onDurationChange(event) {
    this.duration_ = this.duration();
  }
  /**
   * Get and create a `TimeRange` object for buffering.
   *
   * @return {TimeRange}
   *         The time range object that was created.
   */
  ;

  _proto.buffered = function buffered() {
    return createTimeRanges(0, 0);
  }
  /**
   * Get the percentage of the current video that is currently buffered.
   *
   * @return {number}
   *         A number from 0 to 1 that represents the decimal percentage of the
   *         video that is buffered.
   *
   */
  ;

  _proto.bufferedPercent = function bufferedPercent$1() {
    return bufferedPercent(this.buffered(), this.duration_);
  }
  /**
   * Turn off the polyfill for `progress` events that was created in
   * {@link Tech#manualProgressOn}
   * Stop manually tracking progress events by clearing the interval that was set in
   * {@link Tech#trackProgress}.
   */
  ;

  _proto.stopTrackingProgress = function stopTrackingProgress() {
    this.clearInterval(this.progressInterval);
  }
  /**
   * Polyfill the `timeupdate` event for browsers that don't support it.
   *
   * @see {@link Tech#trackCurrentTime}
   */
  ;

  _proto.manualTimeUpdatesOn = function manualTimeUpdatesOn() {
    this.manualTimeUpdates = true;
    this.on('play', this.trackCurrentTime_);
    this.on('pause', this.stopTrackingCurrentTime_);
  }
  /**
   * Turn off the polyfill for `timeupdate` events that was created in
   * {@link Tech#manualTimeUpdatesOn}
   */
  ;

  _proto.manualTimeUpdatesOff = function manualTimeUpdatesOff() {
    this.manualTimeUpdates = false;
    this.stopTrackingCurrentTime();
    this.off('play', this.trackCurrentTime_);
    this.off('pause', this.stopTrackingCurrentTime_);
  }
  /**
   * Sets up an interval function to track current time and trigger `timeupdate` every
   * 250 milliseconds.
   *
   * @listens Tech#play
   * @triggers Tech#timeupdate
   */
  ;

  _proto.trackCurrentTime = function trackCurrentTime() {
    if (this.currentTimeInterval) {
      this.stopTrackingCurrentTime();
    }

    this.currentTimeInterval = this.setInterval(function () {
      /**
       * Triggered at an interval of 250ms to indicated that time is passing in the video.
       *
       * @event Tech#timeupdate
       * @type {EventTarget~Event}
       */
      this.trigger({
        type: 'timeupdate',
        target: this,
        manuallyTriggered: true
      }); // 42 = 24 fps // 250 is what Webkit uses // FF uses 15
    }, 250);
  }
  /**
   * Stop the interval function created in {@link Tech#trackCurrentTime} so that the
   * `timeupdate` event is no longer triggered.
   *
   * @listens {Tech#pause}
   */
  ;

  _proto.stopTrackingCurrentTime = function stopTrackingCurrentTime() {
    this.clearInterval(this.currentTimeInterval); // #1002 - if the video ends right before the next timeupdate would happen,
    // the progress bar won't make it all the way to the end

    this.trigger({
      type: 'timeupdate',
      target: this,
      manuallyTriggered: true
    });
  }
  /**
   * Turn off all event polyfills, clear the `Tech`s {@link AudioTrackList},
   * {@link VideoTrackList}, and {@link TextTrackList}, and dispose of this Tech.
   *
   * @fires Component#dispose
   */
  ;

  _proto.dispose = function dispose() {
    // clear out all tracks because we can't reuse them between techs
    this.clearTracks(NORMAL.names); // Turn off any manual progress or timeupdate tracking

    if (this.manualProgress) {
      this.manualProgressOff();
    }

    if (this.manualTimeUpdates) {
      this.manualTimeUpdatesOff();
    }

    _Component.prototype.dispose.call(this);
  }
  /**
   * Clear out a single `TrackList` or an array of `TrackLists` given their names.
   *
   * > Note: Techs without source handlers should call this between sources for `video`
   *         & `audio` tracks. You don't want to use them between tracks!
   *
   * @param {string[]|string} types
   *        TrackList names to clear, valid names are `video`, `audio`, and
   *        `text`.
   */
  ;

  _proto.clearTracks = function clearTracks(types) {
    var _this3 = this;

    types = [].concat(types); // clear out all tracks because we can't reuse them between techs

    types.forEach(function (type) {
      var list = _this3[type + "Tracks"]() || [];
      var i = list.length;

      while (i--) {
        var track = list[i];

        if (type === 'text') {
          _this3.removeRemoteTextTrack(track);
        }

        list.removeTrack(track);
      }
    });
  }
  /**
   * Remove any TextTracks added via addRemoteTextTrack that are
   * flagged for automatic garbage collection
   */
  ;

  _proto.cleanupAutoTextTracks = function cleanupAutoTextTracks() {
    var list = this.autoRemoteTextTracks_ || [];
    var i = list.length;

    while (i--) {
      var track = list[i];
      this.removeRemoteTextTrack(track);
    }
  }
  /**
   * Reset the tech, which will removes all sources and reset the internal readyState.
   *
   * @abstract
   */
  ;

  _proto.reset = function reset() {}
  /**
   * Get the value of `crossOrigin` from the tech.
   *
   * @abstract
   *
   * @see {Html5#crossOrigin}
   */
  ;

  _proto.crossOrigin = function crossOrigin() {}
  /**
   * Set the value of `crossOrigin` on the tech.
   *
   * @abstract
   *
   * @param {string} crossOrigin the crossOrigin value
   * @see {Html5#setCrossOrigin}
   */
  ;

  _proto.setCrossOrigin = function setCrossOrigin() {}
  /**
   * Get or set an error on the Tech.
   *
   * @param {MediaError} [err]
   *        Error to set on the Tech
   *
   * @return {MediaError|null}
   *         The current error object on the tech, or null if there isn't one.
   */
  ;

  _proto.error = function error(err) {
    if (err !== undefined) {
      this.error_ = new MediaError(err);
      this.trigger('error');
    }

    return this.error_;
  }
  /**
   * Returns the `TimeRange`s that have been played through for the current source.
   *
   * > NOTE: This implementation is incomplete. It does not track the played `TimeRange`.
   *         It only checks whether the source has played at all or not.
   *
   * @return {TimeRange}
   *         - A single time range if this video has played
   *         - An empty set of ranges if not.
   */
  ;

  _proto.played = function played() {
    if (this.hasStarted_) {
      return createTimeRanges(0, 0);
    }

    return createTimeRanges();
  }
  /**
   * Start playback
   *
   * @abstract
   *
   * @see {Html5#play}
   */
  ;

  _proto.play = function play() {}
  /**
   * Set whether we are scrubbing or not
   *
   * @abstract
   *
   * @see {Html5#setScrubbing}
   */
  ;

  _proto.setScrubbing = function setScrubbing() {}
  /**
   * Get whether we are scrubbing or not
   *
   * @abstract
   *
   * @see {Html5#scrubbing}
   */
  ;

  _proto.scrubbing = function scrubbing() {}
  /**
   * Causes a manual time update to occur if {@link Tech#manualTimeUpdatesOn} was
   * previously called.
   *
   * @fires Tech#timeupdate
   */
  ;

  _proto.setCurrentTime = function setCurrentTime() {
    // improve the accuracy of manual timeupdates
    if (this.manualTimeUpdates) {
      /**
       * A manual `timeupdate` event.
       *
       * @event Tech#timeupdate
       * @type {EventTarget~Event}
       */
      this.trigger({
        type: 'timeupdate',
        target: this,
        manuallyTriggered: true
      });
    }
  }
  /**
   * Turn on listeners for {@link VideoTrackList}, {@link {AudioTrackList}, and
   * {@link TextTrackList} events.
   *
   * This adds {@link EventTarget~EventListeners} for `addtrack`, and  `removetrack`.
   *
   * @fires Tech#audiotrackchange
   * @fires Tech#videotrackchange
   * @fires Tech#texttrackchange
   */
  ;

  _proto.initTrackListeners = function initTrackListeners() {
    var _this4 = this;

    /**
      * Triggered when tracks are added or removed on the Tech {@link AudioTrackList}
      *
      * @event Tech#audiotrackchange
      * @type {EventTarget~Event}
      */

    /**
      * Triggered when tracks are added or removed on the Tech {@link VideoTrackList}
      *
      * @event Tech#videotrackchange
      * @type {EventTarget~Event}
      */

    /**
      * Triggered when tracks are added or removed on the Tech {@link TextTrackList}
      *
      * @event Tech#texttrackchange
      * @type {EventTarget~Event}
      */
    NORMAL.names.forEach(function (name) {
      var props = NORMAL[name];

      var trackListChanges = function trackListChanges() {
        _this4.trigger(name + "trackchange");
      };

      var tracks = _this4[props.getterName]();

      tracks.addEventListener('removetrack', trackListChanges);
      tracks.addEventListener('addtrack', trackListChanges);

      _this4.on('dispose', function () {
        tracks.removeEventListener('removetrack', trackListChanges);
        tracks.removeEventListener('addtrack', trackListChanges);
      });
    });
  }
  /**
   * Emulate TextTracks using vtt.js if necessary
   *
   * @fires Tech#vttjsloaded
   * @fires Tech#vttjserror
   */
  ;

  _proto.addWebVttScript_ = function addWebVttScript_() {
    var _this5 = this;

    if (window__default['default'].WebVTT) {
      return;
    } // Initially, Tech.el_ is a child of a dummy-div wait until the Component system
    // signals that the Tech is ready at which point Tech.el_ is part of the DOM
    // before inserting the WebVTT script


    if (document__default['default'].body.contains(this.el())) {
      // load via require if available and vtt.js script location was not passed in
      // as an option. novtt builds will turn the above require call into an empty object
      // which will cause this if check to always fail.
      if (!this.options_['vtt.js'] && isPlain(vtt__default['default']) && Object.keys(vtt__default['default']).length > 0) {
        this.trigger('vttjsloaded');
        return;
      } // load vtt.js via the script location option or the cdn of no location was
      // passed in


      var script = document__default['default'].createElement('script');
      script.src = this.options_['vtt.js'] || 'https://vjs.zencdn.net/vttjs/0.14.1/vtt.min.js';

      script.onload = function () {
        /**
         * Fired when vtt.js is loaded.
         *
         * @event Tech#vttjsloaded
         * @type {EventTarget~Event}
         */
        _this5.trigger('vttjsloaded');
      };

      script.onerror = function () {
        /**
         * Fired when vtt.js was not loaded due to an error
         *
         * @event Tech#vttjsloaded
         * @type {EventTarget~Event}
         */
        _this5.trigger('vttjserror');
      };

      this.on('dispose', function () {
        script.onload = null;
        script.onerror = null;
      }); // but have not loaded yet and we set it to true before the inject so that
      // we don't overwrite the injected window.WebVTT if it loads right away

      window__default['default'].WebVTT = true;
      this.el().parentNode.appendChild(script);
    } else {
      this.ready(this.addWebVttScript_);
    }
  }
  /**
   * Emulate texttracks
   *
   */
  ;

  _proto.emulateTextTracks = function emulateTextTracks() {
    var _this6 = this;

    var tracks = this.textTracks();
    var remoteTracks = this.remoteTextTracks();

    var handleAddTrack = function handleAddTrack(e) {
      return tracks.addTrack(e.track);
    };

    var handleRemoveTrack = function handleRemoveTrack(e) {
      return tracks.removeTrack(e.track);
    };

    remoteTracks.on('addtrack', handleAddTrack);
    remoteTracks.on('removetrack', handleRemoveTrack);
    this.addWebVttScript_();

    var updateDisplay = function updateDisplay() {
      return _this6.trigger('texttrackchange');
    };

    var textTracksChanges = function textTracksChanges() {
      updateDisplay();

      for (var i = 0; i < tracks.length; i++) {
        var track = tracks[i];
        track.removeEventListener('cuechange', updateDisplay);

        if (track.mode === 'showing') {
          track.addEventListener('cuechange', updateDisplay);
        }
      }
    };

    textTracksChanges();
    tracks.addEventListener('change', textTracksChanges);
    tracks.addEventListener('addtrack', textTracksChanges);
    tracks.addEventListener('removetrack', textTracksChanges);
    this.on('dispose', function () {
      remoteTracks.off('addtrack', handleAddTrack);
      remoteTracks.off('removetrack', handleRemoveTrack);
      tracks.removeEventListener('change', textTracksChanges);
      tracks.removeEventListener('addtrack', textTracksChanges);
      tracks.removeEventListener('removetrack', textTracksChanges);

      for (var i = 0; i < tracks.length; i++) {
        var track = tracks[i];
        track.removeEventListener('cuechange', updateDisplay);
      }
    });
  }
  /**
   * Create and returns a remote {@link TextTrack} object.
   *
   * @param {string} kind
   *        `TextTrack` kind (subtitles, captions, descriptions, chapters, or metadata)
   *
   * @param {string} [label]
   *        Label to identify the text track
   *
   * @param {string} [language]
   *        Two letter language abbreviation
   *
   * @return {TextTrack}
   *         The TextTrack that gets created.
   */
  ;

  _proto.addTextTrack = function addTextTrack(kind, label, language) {
    if (!kind) {
      throw new Error('TextTrack kind is required but was not provided');
    }

    return createTrackHelper(this, kind, label, language);
  }
  /**
   * Create an emulated TextTrack for use by addRemoteTextTrack
   *
   * This is intended to be overridden by classes that inherit from
   * Tech in order to create native or custom TextTracks.
   *
   * @param {Object} options
   *        The object should contain the options to initialize the TextTrack with.
   *
   * @param {string} [options.kind]
   *        `TextTrack` kind (subtitles, captions, descriptions, chapters, or metadata).
   *
   * @param {string} [options.label].
   *        Label to identify the text track
   *
   * @param {string} [options.language]
   *        Two letter language abbreviation.
   *
   * @return {HTMLTrackElement}
   *         The track element that gets created.
   */
  ;

  _proto.createRemoteTextTrack = function createRemoteTextTrack(options) {
    var track = mergeOptions(options, {
      tech: this
    });
    return new REMOTE.remoteTextEl.TrackClass(track);
  }
  /**
   * Creates a remote text track object and returns an html track element.
   *
   * > Note: This can be an emulated {@link HTMLTrackElement} or a native one.
   *
   * @param {Object} options
   *        See {@link Tech#createRemoteTextTrack} for more detailed properties.
   *
   * @param {boolean} [manualCleanup=true]
   *        - When false: the TextTrack will be automatically removed from the video
   *          element whenever the source changes
   *        - When True: The TextTrack will have to be cleaned up manually
   *
   * @return {HTMLTrackElement}
   *         An Html Track Element.
   *
   * @deprecated The default functionality for this function will be equivalent
   *             to "manualCleanup=false" in the future. The manualCleanup parameter will
   *             also be removed.
   */
  ;

  _proto.addRemoteTextTrack = function addRemoteTextTrack(options, manualCleanup) {
    var _this7 = this;

    if (options === void 0) {
      options = {};
    }

    var htmlTrackElement = this.createRemoteTextTrack(options);

    if (manualCleanup !== true && manualCleanup !== false) {
      // deprecation warning
      log.warn('Calling addRemoteTextTrack without explicitly setting the "manualCleanup" parameter to `true` is deprecated and default to `false` in future version of video.js');
      manualCleanup = true;
    } // store HTMLTrackElement and TextTrack to remote list


    this.remoteTextTrackEls().addTrackElement_(htmlTrackElement);
    this.remoteTextTracks().addTrack(htmlTrackElement.track);

    if (manualCleanup !== true) {
      // create the TextTrackList if it doesn't exist
      this.ready(function () {
        return _this7.autoRemoteTextTracks_.addTrack(htmlTrackElement.track);
      });
    }

    return htmlTrackElement;
  }
  /**
   * Remove a remote text track from the remote `TextTrackList`.
   *
   * @param {TextTrack} track
   *        `TextTrack` to remove from the `TextTrackList`
   */
  ;

  _proto.removeRemoteTextTrack = function removeRemoteTextTrack(track) {
    var trackElement = this.remoteTextTrackEls().getTrackElementByTrack_(track); // remove HTMLTrackElement and TextTrack from remote list

    this.remoteTextTrackEls().removeTrackElement_(trackElement);
    this.remoteTextTracks().removeTrack(track);
    this.autoRemoteTextTracks_.removeTrack(track);
  }
  /**
   * Gets available media playback quality metrics as specified by the W3C's Media
   * Playback Quality API.
   *
   * @see [Spec]{@link https://wicg.github.io/media-playback-quality}
   *
   * @return {Object}
   *         An object with supported media playback quality metrics
   *
   * @abstract
   */
  ;

  _proto.getVideoPlaybackQuality = function getVideoPlaybackQuality() {
    return {};
  }
  /**
   * Attempt to create a floating video window always on top of other windows
   * so that users may continue consuming media while they interact with other
   * content sites, or applications on their device.
   *
   * @see [Spec]{@link https://wicg.github.io/picture-in-picture}
   *
   * @return {Promise|undefined}
   *         A promise with a Picture-in-Picture window if the browser supports
   *         Promises (or one was passed in as an option). It returns undefined
   *         otherwise.
   *
   * @abstract
   */
  ;

  _proto.requestPictureInPicture = function requestPictureInPicture() {
    var PromiseClass = this.options_.Promise || window__default['default'].Promise;

    if (PromiseClass) {
      return PromiseClass.reject();
    }
  }
  /**
   * A method to check for the value of the 'disablePictureInPicture' <video> property.
   * Defaults to true, as it should be considered disabled if the tech does not support pip
   *
   * @abstract
   */
  ;

  _proto.disablePictureInPicture = function disablePictureInPicture() {
    return true;
  }
  /**
   * A method to set or unset the 'disablePictureInPicture' <video> property.
   *
   * @abstract
   */
  ;

  _proto.setDisablePictureInPicture = function setDisablePictureInPicture() {}
  /**
   * A method to set a poster from a `Tech`.
   *
   * @abstract
   */
  ;

  _proto.setPoster = function setPoster() {}
  /**
   * A method to check for the presence of the 'playsinline' <video> attribute.
   *
   * @abstract
   */
  ;

  _proto.playsinline = function playsinline() {}
  /**
   * A method to set or unset the 'playsinline' <video> attribute.
   *
   * @abstract
   */
  ;

  _proto.setPlaysinline = function setPlaysinline() {}
  /**
   * Attempt to force override of native audio tracks.
   *
   * @param {boolean} override - If set to true native audio will be overridden,
   * otherwise native audio will potentially be used.
   *
   * @abstract
   */
  ;

  _proto.overrideNativeAudioTracks = function overrideNativeAudioTracks() {}
  /**
   * Attempt to force override of native video tracks.
   *
   * @param {boolean} override - If set to true native video will be overridden,
   * otherwise native video will potentially be used.
   *
   * @abstract
   */
  ;

  _proto.overrideNativeVideoTracks = function overrideNativeVideoTracks() {}
  /*
   * Check if the tech can support the given mime-type.
   *
   * The base tech does not support any type, but source handlers might
   * overwrite this.
   *
   * @param  {string} type
   *         The mimetype to check for support
   *
   * @return {string}
   *         'probably', 'maybe', or empty string
   *
   * @see [Spec]{@link https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/canPlayType}
   *
   * @abstract
   */
  ;

  _proto.canPlayType = function canPlayType() {
    return '';
  }
  /**
   * Check if the type is supported by this tech.
   *
   * The base tech does not support any type, but source handlers might
   * overwrite this.
   *
   * @param {string} type
   *        The media type to check
   * @return {string} Returns the native video element's response
   */
  ;

  Tech.canPlayType = function canPlayType() {
    return '';
  }
  /**
   * Check if the tech can support the given source
   *
   * @param {Object} srcObj
   *        The source object
   * @param {Object} options
   *        The options passed to the tech
   * @return {string} 'probably', 'maybe', or '' (empty string)
   */
  ;

  Tech.canPlaySource = function canPlaySource(srcObj, options) {
    return Tech.canPlayType(srcObj.type);
  }
  /*
   * Return whether the argument is a Tech or not.
   * Can be passed either a Class like `Html5` or a instance like `player.tech_`
   *
   * @param {Object} component
   *        The item to check
   *
   * @return {boolean}
   *         Whether it is a tech or not
   *         - True if it is a tech
   *         - False if it is not
   */
  ;

  Tech.isTech = function isTech(component) {
    return component.prototype instanceof Tech || component instanceof Tech || component === Tech;
  }
  /**
   * Registers a `Tech` into a shared list for videojs.
   *
   * @param {string} name
   *        Name of the `Tech` to register.
   *
   * @param {Object} tech
   *        The `Tech` class to register.
   */
  ;

  Tech.registerTech = function registerTech(name, tech) {
    if (!Tech.techs_) {
      Tech.techs_ = {};
    }

    if (!Tech.isTech(tech)) {
      throw new Error("Tech " + name + " must be a Tech");
    }

    if (!Tech.canPlayType) {
      throw new Error('Techs must have a static canPlayType method on them');
    }

    if (!Tech.canPlaySource) {
      throw new Error('Techs must have a static canPlaySource method on them');
    }

    name = toTitleCase(name);
    Tech.techs_[name] = tech;
    Tech.techs_[toLowerCase(name)] = tech;

    if (name !== 'Tech') {
      // camel case the techName for use in techOrder
      Tech.defaultTechOrder_.push(name);
    }

    return tech;
  }
  /**
   * Get a `Tech` from the shared list by name.
   *
   * @param {string} name
   *        `camelCase` or `TitleCase` name of the Tech to get
   *
   * @return {Tech|undefined}
   *         The `Tech` or undefined if there was no tech with the name requested.
   */
  ;

  Tech.getTech = function getTech(name) {
    if (!name) {
      return;
    }

    if (Tech.techs_ && Tech.techs_[name]) {
      return Tech.techs_[name];
    }

    name = toTitleCase(name);

    if (window__default['default'] && window__default['default'].videojs && window__default['default'].videojs[name]) {
      log.warn("The " + name + " tech was added to the videojs object when it should be registered using videojs.registerTech(name, tech)");
      return window__default['default'].videojs[name];
    }
  };

  return Tech;
}(Component);
/**
 * Get the {@link VideoTrackList}
 *
 * @returns {VideoTrackList}
 * @method Tech.prototype.videoTracks
 */

/**
 * Get the {@link AudioTrackList}
 *
 * @returns {AudioTrackList}
 * @method Tech.prototype.audioTracks
 */

/**
 * Get the {@link TextTrackList}
 *
 * @returns {TextTrackList}
 * @method Tech.prototype.textTracks
 */

/**
 * Get the remote element {@link TextTrackList}
 *
 * @returns {TextTrackList}
 * @method Tech.prototype.remoteTextTracks
 */

/**
 * Get the remote element {@link HtmlTrackElementList}
 *
 * @returns {HtmlTrackElementList}
 * @method Tech.prototype.remoteTextTrackEls
 */


ALL.names.forEach(function (name) {
  var props = ALL[name];

  Tech.prototype[props.getterName] = function () {
    this[props.privateName] = this[props.privateName] || new props.ListClass();
    return this[props.privateName];
  };
});
/**
 * List of associated text tracks
 *
 * @type {TextTrackList}
 * @private
 * @property Tech#textTracks_
 */

/**
 * List of associated audio tracks.
 *
 * @type {AudioTrackList}
 * @private
 * @property Tech#audioTracks_
 */

/**
 * List of associated video tracks.
 *
 * @type {VideoTrackList}
 * @private
 * @property Tech#videoTracks_
 */

/**
 * Boolean indicating whether the `Tech` supports volume control.
 *
 * @type {boolean}
 * @default
 */

Tech.prototype.featuresVolumeControl = true;
/**
 * Boolean indicating whether the `Tech` supports muting volume.
 *
 * @type {bolean}
 * @default
 */

Tech.prototype.featuresMuteControl = true;
/**
 * Boolean indicating whether the `Tech` supports fullscreen resize control.
 * Resizing plugins using request fullscreen reloads the plugin
 *
 * @type {boolean}
 * @default
 */

Tech.prototype.featuresFullscreenResize = false;
/**
 * Boolean indicating whether the `Tech` supports changing the speed at which the video
 * plays. Examples:
 *   - Set player to play 2x (twice) as fast
 *   - Set player to play 0.5x (half) as fast
 *
 * @type {boolean}
 * @default
 */

Tech.prototype.featuresPlaybackRate = false;
/**
 * Boolean indicating whether the `Tech` supports the `progress` event. This is currently
 * not triggered by video-js-swf. This will be used to determine if
 * {@link Tech#manualProgressOn} should be called.
 *
 * @type {boolean}
 * @default
 */

Tech.prototype.featuresProgressEvents = false;
/**
 * Boolean indicating whether the `Tech` supports the `sourceset` event.
 *
 * A tech should set this to `true` and then use {@link Tech#triggerSourceset}
 * to trigger a {@link Tech#event:sourceset} at the earliest time after getting
 * a new source.
 *
 * @type {boolean}
 * @default
 */

Tech.prototype.featuresSourceset = false;
/**
 * Boolean indicating whether the `Tech` supports the `timeupdate` event. This is currently
 * not triggered by video-js-swf. This will be used to determine if
 * {@link Tech#manualTimeUpdates} should be called.
 *
 * @type {boolean}
 * @default
 */

Tech.prototype.featuresTimeupdateEvents = false;
/**
 * Boolean indicating whether the `Tech` supports the native `TextTrack`s.
 * This will help us integrate with native `TextTrack`s if the browser supports them.
 *
 * @type {boolean}
 * @default
 */

Tech.prototype.featuresNativeTextTracks = false;
/**
 * A functional mixin for techs that want to use the Source Handler pattern.
 * Source handlers are scripts for handling specific formats.
 * The source handler pattern is used for adaptive formats (HLS, DASH) that
 * manually load video data and feed it into a Source Buffer (Media Source Extensions)
 * Example: `Tech.withSourceHandlers.call(MyTech);`
 *
 * @param {Tech} _Tech
 *        The tech to add source handler functions to.
 *
 * @mixes Tech~SourceHandlerAdditions
 */

Tech.withSourceHandlers = function (_Tech) {
  /**
   * Register a source handler
   *
   * @param {Function} handler
   *        The source handler class
   *
   * @param {number} [index]
   *        Register it at the following index
   */
  _Tech.registerSourceHandler = function (handler, index) {
    var handlers = _Tech.sourceHandlers;

    if (!handlers) {
      handlers = _Tech.sourceHandlers = [];
    }

    if (index === undefined) {
      // add to the end of the list
      index = handlers.length;
    }

    handlers.splice(index, 0, handler);
  };
  /**
   * Check if the tech can support the given type. Also checks the
   * Techs sourceHandlers.
   *
   * @param {string} type
   *         The mimetype to check.
   *
   * @return {string}
   *         'probably', 'maybe', or '' (empty string)
   */


  _Tech.canPlayType = function (type) {
    var handlers = _Tech.sourceHandlers || [];
    var can;

    for (var i = 0; i < handlers.length; i++) {
      can = handlers[i].canPlayType(type);

      if (can) {
        return can;
      }
    }

    return '';
  };
  /**
   * Returns the first source handler that supports the source.
   *
   * TODO: Answer question: should 'probably' be prioritized over 'maybe'
   *
   * @param {Tech~SourceObject} source
   *        The source object
   *
   * @param {Object} options
   *        The options passed to the tech
   *
   * @return {SourceHandler|null}
   *          The first source handler that supports the source or null if
   *          no SourceHandler supports the source
   */


  _Tech.selectSourceHandler = function (source, options) {
    var handlers = _Tech.sourceHandlers || [];
    var can;

    for (var i = 0; i < handlers.length; i++) {
      can = handlers[i].canHandleSource(source, options);

      if (can) {
        return handlers[i];
      }
    }

    return null;
  };
  /**
   * Check if the tech can support the given source.
   *
   * @param {Tech~SourceObject} srcObj
   *        The source object
   *
   * @param {Object} options
   *        The options passed to the tech
   *
   * @return {string}
   *         'probably', 'maybe', or '' (empty string)
   */


  _Tech.canPlaySource = function (srcObj, options) {
    var sh = _Tech.selectSourceHandler(srcObj, options);

    if (sh) {
      return sh.canHandleSource(srcObj, options);
    }

    return '';
  };
  /**
   * When using a source handler, prefer its implementation of
   * any function normally provided by the tech.
   */


  var deferrable = ['seekable', 'seeking', 'duration'];
  /**
   * A wrapper around {@link Tech#seekable} that will call a `SourceHandler`s seekable
   * function if it exists, with a fallback to the Techs seekable function.
   *
   * @method _Tech.seekable
   */

  /**
   * A wrapper around {@link Tech#duration} that will call a `SourceHandler`s duration
   * function if it exists, otherwise it will fallback to the techs duration function.
   *
   * @method _Tech.duration
   */

  deferrable.forEach(function (fnName) {
    var originalFn = this[fnName];

    if (typeof originalFn !== 'function') {
      return;
    }

    this[fnName] = function () {
      if (this.sourceHandler_ && this.sourceHandler_[fnName]) {
        return this.sourceHandler_[fnName].apply(this.sourceHandler_, arguments);
      }

      return originalFn.apply(this, arguments);
    };
  }, _Tech.prototype);
  /**
   * Create a function for setting the source using a source object
   * and source handlers.
   * Should never be called unless a source handler was found.
   *
   * @param {Tech~SourceObject} source
   *        A source object with src and type keys
   */

  _Tech.prototype.setSource = function (source) {
    var sh = _Tech.selectSourceHandler(source, this.options_);

    if (!sh) {
      // Fall back to a native source hander when unsupported sources are
      // deliberately set
      if (_Tech.nativeSourceHandler) {
        sh = _Tech.nativeSourceHandler;
      } else {
        log.error('No source handler found for the current source.');
      }
    } // Dispose any existing source handler


    this.disposeSourceHandler();
    this.off('dispose', this.disposeSourceHandler_);

    if (sh !== _Tech.nativeSourceHandler) {
      this.currentSource_ = source;
    }

    this.sourceHandler_ = sh.handleSource(source, this, this.options_);
    this.one('dispose', this.disposeSourceHandler_);
  };
  /**
   * Clean up any existing SourceHandlers and listeners when the Tech is disposed.
   *
   * @listens Tech#dispose
   */


  _Tech.prototype.disposeSourceHandler = function () {
    // if we have a source and get another one
    // then we are loading something new
    // than clear all of our current tracks
    if (this.currentSource_) {
      this.clearTracks(['audio', 'video']);
      this.currentSource_ = null;
    } // always clean up auto-text tracks


    this.cleanupAutoTextTracks();

    if (this.sourceHandler_) {
      if (this.sourceHandler_.dispose) {
        this.sourceHandler_.dispose();
      }

      this.sourceHandler_ = null;
    }
  };
}; // The base Tech class needs to be registered as a Component. It is the only
// Tech that can be registered as a Component.


Component.registerComponent('Tech', Tech);
Tech.registerTech('Tech', Tech);
/**
 * A list of techs that should be added to techOrder on Players
 *
 * @private
 */

Tech.defaultTechOrder_ = [];

/**
 * @file middleware.js
 * @module middleware
 */
var middlewares = {};
var middlewareInstances = {};
var TERMINATOR = {};
/**
 * A middleware object is a plain JavaScript object that has methods that
 * match the {@link Tech} methods found in the lists of allowed
 * {@link module:middleware.allowedGetters|getters},
 * {@link module:middleware.allowedSetters|setters}, and
 * {@link module:middleware.allowedMediators|mediators}.
 *
 * @typedef {Object} MiddlewareObject
 */

/**
 * A middleware factory function that should return a
 * {@link module:middleware~MiddlewareObject|MiddlewareObject}.
 *
 * This factory will be called for each player when needed, with the player
 * passed in as an argument.
 *
 * @callback MiddlewareFactory
 * @param {Player} player
 *        A Video.js player.
 */

/**
 * Define a middleware that the player should use by way of a factory function
 * that returns a middleware object.
 *
 * @param  {string} type
 *         The MIME type to match or `"*"` for all MIME types.
 *
 * @param  {MiddlewareFactory} middleware
 *         A middleware factory function that will be executed for
 *         matching types.
 */

function use(type, middleware) {
  middlewares[type] = middlewares[type] || [];
  middlewares[type].push(middleware);
}
/**
 * Asynchronously sets a source using middleware by recursing through any
 * matching middlewares and calling `setSource` on each, passing along the
 * previous returned value each time.
 *
 * @param  {Player} player
 *         A {@link Player} instance.
 *
 * @param  {Tech~SourceObject} src
 *         A source object.
 *
 * @param  {Function}
 *         The next middleware to run.
 */

function setSource(player, src, next) {
  player.setTimeout(function () {
    return setSourceHelper(src, middlewares[src.type], next, player);
  }, 1);
}
/**
 * When the tech is set, passes the tech to each middleware's `setTech` method.
 *
 * @param {Object[]} middleware
 *        An array of middleware instances.
 *
 * @param {Tech} tech
 *        A Video.js tech.
 */

function setTech(middleware, tech) {
  middleware.forEach(function (mw) {
    return mw.setTech && mw.setTech(tech);
  });
}
/**
 * Calls a getter on the tech first, through each middleware
 * from right to left to the player.
 *
 * @param  {Object[]} middleware
 *         An array of middleware instances.
 *
 * @param  {Tech} tech
 *         The current tech.
 *
 * @param  {string} method
 *         A method name.
 *
 * @return {Mixed}
 *         The final value from the tech after middleware has intercepted it.
 */

function get(middleware, tech, method) {
  return middleware.reduceRight(middlewareIterator(method), tech[method]());
}
/**
 * Takes the argument given to the player and calls the setter method on each
 * middleware from left to right to the tech.
 *
 * @param  {Object[]} middleware
 *         An array of middleware instances.
 *
 * @param  {Tech} tech
 *         The current tech.
 *
 * @param  {string} method
 *         A method name.
 *
 * @param  {Mixed} arg
 *         The value to set on the tech.
 *
 * @return {Mixed}
 *         The return value of the `method` of the `tech`.
 */

function set(middleware, tech, method, arg) {
  return tech[method](middleware.reduce(middlewareIterator(method), arg));
}
/**
 * Takes the argument given to the player and calls the `call` version of the
 * method on each middleware from left to right.
 *
 * Then, call the passed in method on the tech and return the result unchanged
 * back to the player, through middleware, this time from right to left.
 *
 * @param  {Object[]} middleware
 *         An array of middleware instances.
 *
 * @param  {Tech} tech
 *         The current tech.
 *
 * @param  {string} method
 *         A method name.
 *
 * @param  {Mixed} arg
 *         The value to set on the tech.
 *
 * @return {Mixed}
 *         The return value of the `method` of the `tech`, regardless of the
 *         return values of middlewares.
 */

function mediate(middleware, tech, method, arg) {
  if (arg === void 0) {
    arg = null;
  }

  var callMethod = 'call' + toTitleCase(method);
  var middlewareValue = middleware.reduce(middlewareIterator(callMethod), arg);
  var terminated = middlewareValue === TERMINATOR; // deprecated. The `null` return value should instead return TERMINATOR to
  // prevent confusion if a techs method actually returns null.

  var returnValue = terminated ? null : tech[method](middlewareValue);
  executeRight(middleware, method, returnValue, terminated);
  return returnValue;
}
/**
 * Enumeration of allowed getters where the keys are method names.
 *
 * @type {Object}
 */

var allowedGetters = {
  buffered: 1,
  currentTime: 1,
  duration: 1,
  muted: 1,
  played: 1,
  paused: 1,
  seekable: 1,
  volume: 1,
  ended: 1
};
/**
 * Enumeration of allowed setters where the keys are method names.
 *
 * @type {Object}
 */

var allowedSetters = {
  setCurrentTime: 1,
  setMuted: 1,
  setVolume: 1
};
/**
 * Enumeration of allowed mediators where the keys are method names.
 *
 * @type {Object}
 */

var allowedMediators = {
  play: 1,
  pause: 1
};

function middlewareIterator(method) {
  return function (value, mw) {
    // if the previous middleware terminated, pass along the termination
    if (value === TERMINATOR) {
      return TERMINATOR;
    }

    if (mw[method]) {
      return mw[method](value);
    }

    return value;
  };
}

function executeRight(mws, method, value, terminated) {
  for (var i = mws.length - 1; i >= 0; i--) {
    var mw = mws[i];

    if (mw[method]) {
      mw[method](terminated, value);
    }
  }
}
/**
 * Clear the middleware cache for a player.
 *
 * @param  {Player} player
 *         A {@link Player} instance.
 */


function clearCacheForPlayer(player) {
  middlewareInstances[player.id()] = null;
}
/**
 * {
 *  [playerId]: [[mwFactory, mwInstance], ...]
 * }
 *
 * @private
 */

function getOrCreateFactory(player, mwFactory) {
  var mws = middlewareInstances[player.id()];
  var mw = null;

  if (mws === undefined || mws === null) {
    mw = mwFactory(player);
    middlewareInstances[player.id()] = [[mwFactory, mw]];
    return mw;
  }

  for (var i = 0; i < mws.length; i++) {
    var _mws$i = mws[i],
        mwf = _mws$i[0],
        mwi = _mws$i[1];

    if (mwf !== mwFactory) {
      continue;
    }

    mw = mwi;
  }

  if (mw === null) {
    mw = mwFactory(player);
    mws.push([mwFactory, mw]);
  }

  return mw;
}

function setSourceHelper(src, middleware, next, player, acc, lastRun) {
  if (src === void 0) {
    src = {};
  }

  if (middleware === void 0) {
    middleware = [];
  }

  if (acc === void 0) {
    acc = [];
  }

  if (lastRun === void 0) {
    lastRun = false;
  }

  var _middleware = middleware,
      mwFactory = _middleware[0],
      mwrest = _middleware.slice(1); // if mwFactory is a string, then we're at a fork in the road


  if (typeof mwFactory === 'string') {
    setSourceHelper(src, middlewares[mwFactory], next, player, acc, lastRun); // if we have an mwFactory, call it with the player to get the mw,
    // then call the mw's setSource method
  } else if (mwFactory) {
    var mw = getOrCreateFactory(player, mwFactory); // if setSource isn't present, implicitly select this middleware

    if (!mw.setSource) {
      acc.push(mw);
      return setSourceHelper(src, mwrest, next, player, acc, lastRun);
    }

    mw.setSource(assign({}, src), function (err, _src) {
      // something happened, try the next middleware on the current level
      // make sure to use the old src
      if (err) {
        return setSourceHelper(src, mwrest, next, player, acc, lastRun);
      } // we've succeeded, now we need to go deeper


      acc.push(mw); // if it's the same type, continue down the current chain
      // otherwise, we want to go down the new chain

      setSourceHelper(_src, src.type === _src.type ? mwrest : middlewares[_src.type], next, player, acc, lastRun);
    });
  } else if (mwrest.length) {
    setSourceHelper(src, mwrest, next, player, acc, lastRun);
  } else if (lastRun) {
    next(src, acc);
  } else {
    setSourceHelper(src, middlewares['*'], next, player, acc, true);
  }
}

/**
 * Mimetypes
 *
 * @see http://hul.harvard.edu/ois/////systems/wax/wax-public-help/mimetypes.htm
 * @typedef Mimetypes~Kind
 * @enum
 */

var MimetypesKind = {
  opus: 'video/ogg',
  ogv: 'video/ogg',
  mp4: 'video/mp4',
  mov: 'video/mp4',
  m4v: 'video/mp4',
  mkv: 'video/x-matroska',
  m4a: 'audio/mp4',
  mp3: 'audio/mpeg',
  aac: 'audio/aac',
  caf: 'audio/x-caf',
  flac: 'audio/flac',
  oga: 'audio/ogg',
  wav: 'audio/wav',
  m3u8: 'application/x-mpegURL',
  jpg: 'image/jpeg',
  jpeg: 'image/jpeg',
  gif: 'image/gif',
  png: 'image/png',
  svg: 'image/svg+xml',
  webp: 'image/webp'
};
/**
 * Get the mimetype of a given src url if possible
 *
 * @param {string} src
 *        The url to the src
 *
 * @return {string}
 *         return the mimetype if it was known or empty string otherwise
 */

var getMimetype = function getMimetype(src) {
  if (src === void 0) {
    src = '';
  }

  var ext = getFileExtension(src);
  var mimetype = MimetypesKind[ext.toLowerCase()];
  return mimetype || '';
};
/**
 * Find the mime type of a given source string if possible. Uses the player
 * source cache.
 *
 * @param {Player} player
 *        The player object
 *
 * @param {string} src
 *        The source string
 *
 * @return {string}
 *         The type that was found
 */

var findMimetype = function findMimetype(player, src) {
  if (!src) {
    return '';
  } // 1. check for the type in the `source` cache


  if (player.cache_.source.src === src && player.cache_.source.type) {
    return player.cache_.source.type;
  } // 2. see if we have this source in our `currentSources` cache


  var matchingSources = player.cache_.sources.filter(function (s) {
    return s.src === src;
  });

  if (matchingSources.length) {
    return matchingSources[0].type;
  } // 3. look for the src url in source elements and use the type there


  var sources = player.$$('source');

  for (var i = 0; i < sources.length; i++) {
    var s = sources[i];

    if (s.type && s.src && s.src === src) {
      return s.type;
    }
  } // 4. finally fallback to our list of mime types based on src url extension


  return getMimetype(src);
};

/**
 * @module filter-source
 */
/**
 * Filter out single bad source objects or multiple source objects in an
 * array. Also flattens nested source object arrays into a 1 dimensional
 * array of source objects.
 *
 * @param {Tech~SourceObject|Tech~SourceObject[]} src
 *        The src object to filter
 *
 * @return {Tech~SourceObject[]}
 *         An array of sourceobjects containing only valid sources
 *
 * @private
 */

var filterSource = function filterSource(src) {
  // traverse array
  if (Array.isArray(src)) {
    var newsrc = [];
    src.forEach(function (srcobj) {
      srcobj = filterSource(srcobj);

      if (Array.isArray(srcobj)) {
        newsrc = newsrc.concat(srcobj);
      } else if (isObject(srcobj)) {
        newsrc.push(srcobj);
      }
    });
    src = newsrc;
  } else if (typeof src === 'string' && src.trim()) {
    // convert string into object
    src = [fixSource({
      src: src
    })];
  } else if (isObject(src) && typeof src.src === 'string' && src.src && src.src.trim()) {
    // src is already valid
    src = [fixSource(src)];
  } else {
    // invalid source, turn it into an empty array
    src = [];
  }

  return src;
};
/**
 * Checks src mimetype, adding it when possible
 *
 * @param {Tech~SourceObject} src
 *        The src object to check
 * @return {Tech~SourceObject}
 *        src Object with known type
 */


function fixSource(src) {
  if (!src.type) {
    var mimetype = getMimetype(src.src);

    if (mimetype) {
      src.type = mimetype;
    }
  }

  return src;
}

/**
 * The `MediaLoader` is the `Component` that decides which playback technology to load
 * when a player is initialized.
 *
 * @extends Component
 */

var MediaLoader = /*#__PURE__*/function (_Component) {
  _inheritsLoose__default['default'](MediaLoader, _Component);

  /**
   * Create an instance of this class.
   *
   * @param {Player} player
   *        The `Player` that this class should attach to.
   *
   * @param {Object} [options]
   *        The key/value store of player options.
   *
   * @param {Component~ReadyCallback} [ready]
   *        The function that is run when this component is ready.
   */
  function MediaLoader(player, options, ready) {
    var _this;

    // MediaLoader has no element
    var options_ = mergeOptions({
      createEl: false
    }, options);
    _this = _Component.call(this, player, options_, ready) || this; // If there are no sources when the player is initialized,
    // load the first supported playback technology.

    if (!options.playerOptions.sources || options.playerOptions.sources.length === 0) {
      for (var i = 0, j = options.playerOptions.techOrder; i < j.length; i++) {
        var techName = toTitleCase(j[i]);
        var tech = Tech.getTech(techName); // Support old behavior of techs being registered as components.
        // Remove once that deprecated behavior is removed.

        if (!techName) {
          tech = Component.getComponent(techName);
        } // Check if the browser supports this technology


        if (tech && tech.isSupported()) {
          player.loadTech_(techName);
          break;
        }
      }
    } else {
      // Loop through playback technologies (e.g. HTML5) and check for support.
      // Then load the best source.
      // A few assumptions here:
      //   All playback technologies respect preload false.
      player.src(options.playerOptions.sources);
    }

    return _this;
  }

  return MediaLoader;
}(Component);

Component.registerComponent('MediaLoader', MediaLoader);

/**
 * Component which is clickable or keyboard actionable, but is not a
 * native HTML button.
 *
 * @extends Component
 */

var ClickableComponent = /*#__PURE__*/function (_Component) {
  _inheritsLoose__default['default'](ClickableComponent, _Component);

  /**
   * Creates an instance of this class.
   *
   * @param  {Player} player
   *         The `Player` that this class should be attached to.
   *
   * @param  {Object} [options]
   *         The key/value store of player options.
   *
   * @param  {function} [options.clickHandler]
   *         The function to call when the button is clicked / activated
   */
  function ClickableComponent(player, options) {
    var _this;

    _this = _Component.call(this, player, options) || this;

    _this.handleMouseOver_ = function (e) {
      return _this.handleMouseOver(e);
    };

    _this.handleMouseOut_ = function (e) {
      return _this.handleMouseOut(e);
    };

    _this.handleClick_ = function (e) {
      return _this.handleClick(e);
    };

    _this.handleKeyDown_ = function (e) {
      return _this.handleKeyDown(e);
    };

    _this.emitTapEvents();

    _this.enable();

    return _this;
  }
  /**
   * Create the `ClickableComponent`s DOM element.
   *
   * @param {string} [tag=div]
   *        The element's node type.
   *
   * @param {Object} [props={}]
   *        An object of properties that should be set on the element.
   *
   * @param {Object} [attributes={}]
   *        An object of attributes that should be set on the element.
   *
   * @return {Element}
   *         The element that gets created.
   */


  var _proto = ClickableComponent.prototype;

  _proto.createEl = function createEl$1(tag, props, attributes) {
    if (tag === void 0) {
      tag = 'div';
    }

    if (props === void 0) {
      props = {};
    }

    if (attributes === void 0) {
      attributes = {};
    }

    props = assign({
      className: this.buildCSSClass(),
      tabIndex: 0
    }, props);

    if (tag === 'button') {
      log.error("Creating a ClickableComponent with an HTML element of " + tag + " is not supported; use a Button instead.");
    } // Add ARIA attributes for clickable element which is not a native HTML button


    attributes = assign({
      role: 'button'
    }, attributes);
    this.tabIndex_ = props.tabIndex;
    var el = createEl(tag, props, attributes);
    el.appendChild(createEl('span', {
      className: 'vjs-icon-placeholder'
    }, {
      'aria-hidden': true
    }));
    this.createControlTextEl(el);
    return el;
  };

  _proto.dispose = function dispose() {
    // remove controlTextEl_ on dispose
    this.controlTextEl_ = null;

    _Component.prototype.dispose.call(this);
  }
  /**
   * Create a control text element on this `ClickableComponent`
   *
   * @param {Element} [el]
   *        Parent element for the control text.
   *
   * @return {Element}
   *         The control text element that gets created.
   */
  ;

  _proto.createControlTextEl = function createControlTextEl(el) {
    this.controlTextEl_ = createEl('span', {
      className: 'vjs-control-text'
    }, {
      // let the screen reader user know that the text of the element may change
      'aria-live': 'polite'
    });

    if (el) {
      el.appendChild(this.controlTextEl_);
    }

    this.controlText(this.controlText_, el);
    return this.controlTextEl_;
  }
  /**
   * Get or set the localize text to use for the controls on the `ClickableComponent`.
   *
   * @param {string} [text]
   *        Control text for element.
   *
   * @param {Element} [el=this.el()]
   *        Element to set the title on.
   *
   * @return {string}
   *         - The control text when getting
   */
  ;

  _proto.controlText = function controlText(text, el) {
    if (el === void 0) {
      el = this.el();
    }

    if (text === undefined) {
      return this.controlText_ || 'Need Text';
    }

    var localizedText = this.localize(text);
    this.controlText_ = text;
    textContent(this.controlTextEl_, localizedText);

    if (!this.nonIconControl && !this.player_.options_.noUITitleAttributes) {
      // Set title attribute if only an icon is shown
      el.setAttribute('title', localizedText);
    }
  }
  /**
   * Builds the default DOM `className`.
   *
   * @return {string}
   *         The DOM `className` for this object.
   */
  ;

  _proto.buildCSSClass = function buildCSSClass() {
    return "vjs-control vjs-button " + _Component.prototype.buildCSSClass.call(this);
  }
  /**
   * Enable this `ClickableComponent`
   */
  ;

  _proto.enable = function enable() {
    if (!this.enabled_) {
      this.enabled_ = true;
      this.removeClass('vjs-disabled');
      this.el_.setAttribute('aria-disabled', 'false');

      if (typeof this.tabIndex_ !== 'undefined') {
        this.el_.setAttribute('tabIndex', this.tabIndex_);
      }

      this.on(['tap', 'click'], this.handleClick_);
      this.on('keydown', this.handleKeyDown_);
    }
  }
  /**
   * Disable this `ClickableComponent`
   */
  ;

  _proto.disable = function disable() {
    this.enabled_ = false;
    this.addClass('vjs-disabled');
    this.el_.setAttribute('aria-disabled', 'true');

    if (typeof this.tabIndex_ !== 'undefined') {
      this.el_.removeAttribute('tabIndex');
    }

    this.off('mouseover', this.handleMouseOver_);
    this.off('mouseout', this.handleMouseOut_);
    this.off(['tap', 'click'], this.handleClick_);
    this.off('keydown', this.handleKeyDown_);
  }
  /**
   * Handles language change in ClickableComponent for the player in components
   *
   *
   */
  ;

  _proto.handleLanguagechange = function handleLanguagechange() {
    this.controlText(this.controlText_);
  }
  /**
   * Event handler that is called when a `ClickableComponent` receives a
   * `click` or `tap` event.
   *
   * @param {EventTarget~Event} event
   *        The `tap` or `click` event that caused this function to be called.
   *
   * @listens tap
   * @listens click
   * @abstract
   */
  ;

  _proto.handleClick = function handleClick(event) {
    if (this.options_.clickHandler) {
      this.options_.clickHandler.call(this, arguments);
    }
  }
  /**
   * Event handler that is called when a `ClickableComponent` receives a
   * `keydown` event.
   *
   * By default, if the key is Space or Enter, it will trigger a `click` event.
   *
   * @param {EventTarget~Event} event
   *        The `keydown` event that caused this function to be called.
   *
   * @listens keydown
   */
  ;

  _proto.handleKeyDown = function handleKeyDown(event) {
    // Support Space or Enter key operation to fire a click event. Also,
    // prevent the event from propagating through the DOM and triggering
    // Player hotkeys.
    if (keycode__default['default'].isEventKey(event, 'Space') || keycode__default['default'].isEventKey(event, 'Enter')) {
      event.preventDefault();
      event.stopPropagation();
      this.trigger('click');
    } else {
      // Pass keypress handling up for unsupported keys
      _Component.prototype.handleKeyDown.call(this, event);
    }
  };

  return ClickableComponent;
}(Component);

Component.registerComponent('ClickableComponent', ClickableComponent);

/**
 * A `ClickableComponent` that handles showing the poster image for the player.
 *
 * @extends ClickableComponent
 */

var PosterImage = /*#__PURE__*/function (_ClickableComponent) {
  _inheritsLoose__default['default'](PosterImage, _ClickableComponent);

  /**
   * Create an instance of this class.
   *
   * @param {Player} player
   *        The `Player` that this class should attach to.
   *
   * @param {Object} [options]
   *        The key/value store of player options.
   */
  function PosterImage(player, options) {
    var _this;

    _this = _ClickableComponent.call(this, player, options) || this;

    _this.update();

    _this.update_ = function (e) {
      return _this.update(e);
    };

    player.on('posterchange', _this.update_);
    return _this;
  }
  /**
   * Clean up and dispose of the `PosterImage`.
   */


  var _proto = PosterImage.prototype;

  _proto.dispose = function dispose() {
    this.player().off('posterchange', this.update_);

    _ClickableComponent.prototype.dispose.call(this);
  }
  /**
   * Create the `PosterImage`s DOM element.
   *
   * @return {Element}
   *         The element that gets created.
   */
  ;

  _proto.createEl = function createEl$1() {
    var el = createEl('div', {
      className: 'vjs-poster',
      // Don't want poster to be tabbable.
      tabIndex: -1
    });
    return el;
  }
  /**
   * An {@link EventTarget~EventListener} for {@link Player#posterchange} events.
   *
   * @listens Player#posterchange
   *
   * @param {EventTarget~Event} [event]
   *        The `Player#posterchange` event that triggered this function.
   */
  ;

  _proto.update = function update(event) {
    var url = this.player().poster();
    this.setSrc(url); // If there's no poster source we should display:none on this component
    // so it's not still clickable or right-clickable

    if (url) {
      this.show();
    } else {
      this.hide();
    }
  }
  /**
   * Set the source of the `PosterImage` depending on the display method.
   *
   * @param {string} url
   *        The URL to the source for the `PosterImage`.
   */
  ;

  _proto.setSrc = function setSrc(url) {
    var backgroundImage = ''; // Any falsy value should stay as an empty string, otherwise
    // this will throw an extra error

    if (url) {
      backgroundImage = "url(\"" + url + "\")";
    }

    this.el_.style.backgroundImage = backgroundImage;
  }
  /**
   * An {@link EventTarget~EventListener} for clicks on the `PosterImage`. See
   * {@link ClickableComponent#handleClick} for instances where this will be triggered.
   *
   * @listens tap
   * @listens click
   * @listens keydown
   *
   * @param {EventTarget~Event} event
   +        The `click`, `tap` or `keydown` event that caused this function to be called.
   */
  ;

  _proto.handleClick = function handleClick(event) {
    // We don't want a click to trigger playback when controls are disabled
    if (!this.player_.controls()) {
      return;
    }

    var sourceIsEncrypted = this.player_.usingPlugin('eme') && this.player_.eme.sessions && this.player_.eme.sessions.length > 0;

    if (this.player_.tech(true) && // We've observed a bug in IE and Edge when playing back DRM content where
    // calling .focus() on the video element causes the video to go black,
    // so we avoid it in that specific case
    !((IE_VERSION || IS_EDGE) && sourceIsEncrypted)) {
      this.player_.tech(true).focus();
    }

    if (this.player_.paused()) {
      silencePromise(this.player_.play());
    } else {
      this.player_.pause();
    }
  };

  return PosterImage;
}(ClickableComponent);

Component.registerComponent('PosterImage', PosterImage);

var darkGray = '#222';
var lightGray = '#ccc';
var fontMap = {
  monospace: 'monospace',
  sansSerif: 'sans-serif',
  serif: 'serif',
  monospaceSansSerif: '"Andale Mono", "Lucida Console", monospace',
  monospaceSerif: '"Courier New", monospace',
  proportionalSansSerif: 'sans-serif',
  proportionalSerif: 'serif',
  casual: '"Comic Sans MS", Impact, fantasy',
  script: '"Monotype Corsiva", cursive',
  smallcaps: '"Andale Mono", "Lucida Console", monospace, sans-serif'
};
/**
 * Construct an rgba color from a given hex color code.
 *
 * @param {number} color
 *        Hex number for color, like #f0e or #f604e2.
 *
 * @param {number} opacity
 *        Value for opacity, 0.0 - 1.0.
 *
 * @return {string}
 *         The rgba color that was created, like 'rgba(255, 0, 0, 0.3)'.
 */

function constructColor(color, opacity) {
  var hex;

  if (color.length === 4) {
    // color looks like "#f0e"
    hex = color[1] + color[1] + color[2] + color[2] + color[3] + color[3];
  } else if (color.length === 7) {
    // color looks like "#f604e2"
    hex = color.slice(1);
  } else {
    throw new Error('Invalid color code provided, ' + color + '; must be formatted as e.g. #f0e or #f604e2.');
  }

  return 'rgba(' + parseInt(hex.slice(0, 2), 16) + ',' + parseInt(hex.slice(2, 4), 16) + ',' + parseInt(hex.slice(4, 6), 16) + ',' + opacity + ')';
}
/**
 * Try to update the style of a DOM element. Some style changes will throw an error,
 * particularly in IE8. Those should be noops.
 *
 * @param {Element} el
 *        The DOM element to be styled.
 *
 * @param {string} style
 *        The CSS property on the element that should be styled.
 *
 * @param {string} rule
 *        The style rule that should be applied to the property.
 *
 * @private
 */

function tryUpdateStyle(el, style, rule) {
  try {
    el.style[style] = rule;
  } catch (e) {
    // Satisfies linter.
    return;
  }
}
/**
 * The component for displaying text track cues.
 *
 * @extends Component
 */


var TextTrackDisplay = /*#__PURE__*/function (_Component) {
  _inheritsLoose__default['default'](TextTrackDisplay, _Component);

  /**
   * Creates an instance of this class.
   *
   * @param {Player} player
   *        The `Player` that this class should be attached to.
   *
   * @param {Object} [options]
   *        The key/value store of player options.
   *
   * @param {Component~ReadyCallback} [ready]
   *        The function to call when `TextTrackDisplay` is ready.
   */
  function TextTrackDisplay(player, options, ready) {
    var _this;

    _this = _Component.call(this, player, options, ready) || this;

    var updateDisplayHandler = function updateDisplayHandler(e) {
      return _this.updateDisplay(e);
    };

    player.on('loadstart', function (e) {
      return _this.toggleDisplay(e);
    });
    player.on('texttrackchange', updateDisplayHandler);
    player.on('loadedmetadata', function (e) {
      return _this.preselectTrack(e);
    }); // This used to be called during player init, but was causing an error
    // if a track should show by default and the display hadn't loaded yet.
    // Should probably be moved to an external track loader when we support
    // tracks that don't need a display.

    player.ready(bind(_assertThisInitialized__default['default'](_this), function () {
      if (player.tech_ && player.tech_.featuresNativeTextTracks) {
        this.hide();
        return;
      }

      player.on('fullscreenchange', updateDisplayHandler);
      player.on('playerresize', updateDisplayHandler);
      window__default['default'].addEventListener('orientationchange', updateDisplayHandler);
      player.on('dispose', function () {
        return window__default['default'].removeEventListener('orientationchange', updateDisplayHandler);
      });
      var tracks = this.options_.playerOptions.tracks || [];

      for (var i = 0; i < tracks.length; i++) {
        this.player_.addRemoteTextTrack(tracks[i], true);
      }

      this.preselectTrack();
    }));
    return _this;
  }
  /**
  * Preselect a track following this precedence:
  * - matches the previously selected {@link TextTrack}'s language and kind
  * - matches the previously selected {@link TextTrack}'s language only
  * - is the first default captions track
  * - is the first default descriptions track
  *
  * @listens Player#loadstart
  */


  var _proto = TextTrackDisplay.prototype;

  _proto.preselectTrack = function preselectTrack() {
    var modes = {
      captions: 1,
      subtitles: 1
    };
    var trackList = this.player_.textTracks();
    var userPref = this.player_.cache_.selectedLanguage;
    var firstDesc;
    var firstCaptions;
    var preferredTrack;

    for (var i = 0; i < trackList.length; i++) {
      var track = trackList[i];

      if (userPref && userPref.enabled && userPref.language && userPref.language === track.language && track.kind in modes) {
        // Always choose the track that matches both language and kind
        if (track.kind === userPref.kind) {
          preferredTrack = track; // or choose the first track that matches language
        } else if (!preferredTrack) {
          preferredTrack = track;
        } // clear everything if offTextTrackMenuItem was clicked

      } else if (userPref && !userPref.enabled) {
        preferredTrack = null;
        firstDesc = null;
        firstCaptions = null;
      } else if (track["default"]) {
        if (track.kind === 'descriptions' && !firstDesc) {
          firstDesc = track;
        } else if (track.kind in modes && !firstCaptions) {
          firstCaptions = track;
        }
      }
    } // The preferredTrack matches the user preference and takes
    // precedence over all the other tracks.
    // So, display the preferredTrack before the first default track
    // and the subtitles/captions track before the descriptions track


    if (preferredTrack) {
      preferredTrack.mode = 'showing';
    } else if (firstCaptions) {
      firstCaptions.mode = 'showing';
    } else if (firstDesc) {
      firstDesc.mode = 'showing';
    }
  }
  /**
   * Turn display of {@link TextTrack}'s from the current state into the other state.
   * There are only two states:
   * - 'shown'
   * - 'hidden'
   *
   * @listens Player#loadstart
   */
  ;

  _proto.toggleDisplay = function toggleDisplay() {
    if (this.player_.tech_ && this.player_.tech_.featuresNativeTextTracks) {
      this.hide();
    } else {
      this.show();
    }
  }
  /**
   * Create the {@link Component}'s DOM element.
   *
   * @return {Element}
   *         The element that was created.
   */
  ;

  _proto.createEl = function createEl() {
    return _Component.prototype.createEl.call(this, 'div', {
      className: 'vjs-text-track-display'
    }, {
      'translate': 'yes',
      'aria-live': 'off',
      'aria-atomic': 'true'
    });
  }
  /**
   * Clear all displayed {@link TextTrack}s.
   */
  ;

  _proto.clearDisplay = function clearDisplay() {
    if (typeof window__default['default'].WebVTT === 'function') {
      window__default['default'].WebVTT.processCues(window__default['default'], [], this.el_);
    }
  }
  /**
   * Update the displayed TextTrack when a either a {@link Player#texttrackchange} or
   * a {@link Player#fullscreenchange} is fired.
   *
   * @listens Player#texttrackchange
   * @listens Player#fullscreenchange
   */
  ;

  _proto.updateDisplay = function updateDisplay() {
    var tracks = this.player_.textTracks();
    var allowMultipleShowingTracks = this.options_.allowMultipleShowingTracks;
    this.clearDisplay();

    if (allowMultipleShowingTracks) {
      var showingTracks = [];

      for (var _i = 0; _i < tracks.length; ++_i) {
        var track = tracks[_i];

        if (track.mode !== 'showing') {
          continue;
        }

        showingTracks.push(track);
      }

      this.updateForTrack(showingTracks);
      return;
    } //  Track display prioritization model: if multiple tracks are 'showing',
    //  display the first 'subtitles' or 'captions' track which is 'showing',
    //  otherwise display the first 'descriptions' track which is 'showing'


    var descriptionsTrack = null;
    var captionsSubtitlesTrack = null;
    var i = tracks.length;

    while (i--) {
      var _track = tracks[i];

      if (_track.mode === 'showing') {
        if (_track.kind === 'descriptions') {
          descriptionsTrack = _track;
        } else {
          captionsSubtitlesTrack = _track;
        }
      }
    }

    if (captionsSubtitlesTrack) {
      if (this.getAttribute('aria-live') !== 'off') {
        this.setAttribute('aria-live', 'off');
      }

      this.updateForTrack(captionsSubtitlesTrack);
    } else if (descriptionsTrack) {
      if (this.getAttribute('aria-live') !== 'assertive') {
        this.setAttribute('aria-live', 'assertive');
      }

      this.updateForTrack(descriptionsTrack);
    }
  }
  /**
   * Style {@Link TextTrack} activeCues according to {@Link TextTrackSettings}.
   *
   * @param {TextTrack} track
   *        Text track object containing active cues to style.
   */
  ;

  _proto.updateDisplayState = function updateDisplayState(track) {
    var overrides = this.player_.textTrackSettings.getValues();
    var cues = track.activeCues;
    var i = cues.length;

    while (i--) {
      var cue = cues[i];

      if (!cue) {
        continue;
      }

      var cueDiv = cue.displayState;

      if (overrides.color) {
        cueDiv.firstChild.style.color = overrides.color;
      }

      if (overrides.textOpacity) {
        tryUpdateStyle(cueDiv.firstChild, 'color', constructColor(overrides.color || '#fff', overrides.textOpacity));
      }

      if (overrides.backgroundColor) {
        cueDiv.firstChild.style.backgroundColor = overrides.backgroundColor;
      }

      if (overrides.backgroundOpacity) {
        tryUpdateStyle(cueDiv.firstChild, 'backgroundColor', constructColor(overrides.backgroundColor || '#000', overrides.backgroundOpacity));
      }

      if (overrides.windowColor) {
        if (overrides.windowOpacity) {
          tryUpdateStyle(cueDiv, 'backgroundColor', constructColor(overrides.windowColor, overrides.windowOpacity));
        } else {
          cueDiv.style.backgroundColor = overrides.windowColor;
        }
      }

      if (overrides.edgeStyle) {
        if (overrides.edgeStyle === 'dropshadow') {
          cueDiv.firstChild.style.textShadow = "2px 2px 3px " + darkGray + ", 2px 2px 4px " + darkGray + ", 2px 2px 5px " + darkGray;
        } else if (overrides.edgeStyle === 'raised') {
          cueDiv.firstChild.style.textShadow = "1px 1px " + darkGray + ", 2px 2px " + darkGray + ", 3px 3px " + darkGray;
        } else if (overrides.edgeStyle === 'depressed') {
          cueDiv.firstChild.style.textShadow = "1px 1px " + lightGray + ", 0 1px " + lightGray + ", -1px -1px " + darkGray + ", 0 -1px " + darkGray;
        } else if (overrides.edgeStyle === 'uniform') {
          cueDiv.firstChild.style.textShadow = "0 0 4px " + darkGray + ", 0 0 4px " + darkGray + ", 0 0 4px " + darkGray + ", 0 0 4px " + darkGray;
        }
      }

      if (overrides.fontPercent && overrides.fontPercent !== 1) {
        var fontSize = window__default['default'].parseFloat(cueDiv.style.fontSize);
        cueDiv.style.fontSize = fontSize * overrides.fontPercent + 'px';
        cueDiv.style.height = 'auto';
        cueDiv.style.top = 'auto';
      }

      if (overrides.fontFamily && overrides.fontFamily !== 'default') {
        if (overrides.fontFamily === 'small-caps') {
          cueDiv.firstChild.style.fontVariant = 'small-caps';
        } else {
          cueDiv.firstChild.style.fontFamily = fontMap[overrides.fontFamily];
        }
      }
    }
  }
  /**
   * Add an {@link TextTrack} to to the {@link Tech}s {@link TextTrackList}.
   *
   * @param {TextTrack|TextTrack[]} tracks
   *        Text track object or text track array to be added to the list.
   */
  ;

  _proto.updateForTrack = function updateForTrack(tracks) {
    if (!Array.isArray(tracks)) {
      tracks = [tracks];
    }

    if (typeof window__default['default'].WebVTT !== 'function' || tracks.every(function (track) {
      return !track.activeCues;
    })) {
      return;
    }

    var cues = []; // push all active track cues

    for (var i = 0; i < tracks.length; ++i) {
      var track = tracks[i];

      for (var j = 0; j < track.activeCues.length; ++j) {
        cues.push(track.activeCues[j]);
      }
    } // removes all cues before it processes new ones


    window__default['default'].WebVTT.processCues(window__default['default'], cues, this.el_); // add unique class to each language text track & add settings styling if necessary

    for (var _i2 = 0; _i2 < tracks.length; ++_i2) {
      var _track2 = tracks[_i2];

      for (var _j = 0; _j < _track2.activeCues.length; ++_j) {
        var cueEl = _track2.activeCues[_j].displayState;
        addClass(cueEl, 'vjs-text-track-cue');
        addClass(cueEl, 'vjs-text-track-cue-' + (_track2.language ? _track2.language : _i2));

        if (_track2.language) {
          setAttribute(cueEl, 'lang', _track2.language);
        }
      }

      if (this.player_.textTrackSettings) {
        this.updateDisplayState(_track2);
      }
    }
  };

  return TextTrackDisplay;
}(Component);

Component.registerComponent('TextTrackDisplay', TextTrackDisplay);

/**
 * A loading spinner for use during waiting/loading events.
 *
 * @extends Component
 */

var LoadingSpinner = /*#__PURE__*/function (_Component) {
  _inheritsLoose__default['default'](LoadingSpinner, _Component);

  function LoadingSpinner() {
    return _Component.apply(this, arguments) || this;
  }

  var _proto = LoadingSpinner.prototype;

  /**
   * Create the `LoadingSpinner`s DOM element.
   *
   * @return {Element}
   *         The dom element that gets created.
   */
  _proto.createEl = function createEl$1() {
    var isAudio = this.player_.isAudio();
    var playerType = this.localize(isAudio ? 'Audio Player' : 'Video Player');
    var controlText = createEl('span', {
      className: 'vjs-control-text',
      textContent: this.localize('{1} is loading.', [playerType])
    });

    var el = _Component.prototype.createEl.call(this, 'div', {
      className: 'vjs-loading-spinner',
      dir: 'ltr'
    });

    el.appendChild(controlText);
    return el;
  };

  return LoadingSpinner;
}(Component);

Component.registerComponent('LoadingSpinner', LoadingSpinner);

/**
 * Base class for all buttons.
 *
 * @extends ClickableComponent
 */

var Button = /*#__PURE__*/function (_ClickableComponent) {
  _inheritsLoose__default['default'](Button, _ClickableComponent);

  function Button() {
    return _ClickableComponent.apply(this, arguments) || this;
  }

  var _proto = Button.prototype;

  /**
   * Create the `Button`s DOM element.
   *
   * @param {string} [tag="button"]
   *        The element's node type. This argument is IGNORED: no matter what
   *        is passed, it will always create a `button` element.
   *
   * @param {Object} [props={}]
   *        An object of properties that should be set on the element.
   *
   * @param {Object} [attributes={}]
   *        An object of attributes that should be set on the element.
   *
   * @return {Element}
   *         The element that gets created.
   */
  _proto.createEl = function createEl$1(tag, props, attributes) {
    if (props === void 0) {
      props = {};
    }

    if (attributes === void 0) {
      attributes = {};
    }

    tag = 'button';
    props = assign({
      className: this.buildCSSClass()
    }, props); // Add attributes for button element

    attributes = assign({
      // Necessary since the default button type is "submit"
      type: 'button'
    }, attributes);

    var el = createEl(tag, props, attributes);

    el.appendChild(createEl('span', {
      className: 'vjs-icon-placeholder'
    }, {
      'aria-hidden': true
    }));
    this.createControlTextEl(el);
    return el;
  }
  /**
   * Add a child `Component` inside of this `Button`.
   *
   * @param {string|Component} child
   *        The name or instance of a child to add.
   *
   * @param {Object} [options={}]
   *        The key/value store of options that will get passed to children of
   *        the child.
   *
   * @return {Component}
   *         The `Component` that gets added as a child. When using a string the
   *         `Component` will get created by this process.
   *
   * @deprecated since version 5
   */
  ;

  _proto.addChild = function addChild(child, options) {
    if (options === void 0) {
      options = {};
    }

    var className = this.constructor.name;
    log.warn("Adding an actionable (user controllable) child to a Button (" + className + ") is not supported; use a ClickableComponent instead."); // Avoid the error message generated by ClickableComponent's addChild method

    return Component.prototype.addChild.call(this, child, options);
  }
  /**
   * Enable the `Button` element so that it can be activated or clicked. Use this with
   * {@link Button#disable}.
   */
  ;

  _proto.enable = function enable() {
    _ClickableComponent.prototype.enable.call(this);

    this.el_.removeAttribute('disabled');
  }
  /**
   * Disable the `Button` element so that it cannot be activated or clicked. Use this with
   * {@link Button#enable}.
   */
  ;

  _proto.disable = function disable() {
    _ClickableComponent.prototype.disable.call(this);

    this.el_.setAttribute('disabled', 'disabled');
  }
  /**
   * This gets called when a `Button` has focus and `keydown` is triggered via a key
   * press.
   *
   * @param {EventTarget~Event} event
   *        The event that caused this function to get called.
   *
   * @listens keydown
   */
  ;

  _proto.handleKeyDown = function handleKeyDown(event) {
    // Ignore Space or Enter key operation, which is handled by the browser for
    // a button - though not for its super class, ClickableComponent. Also,
    // prevent the event from propagating through the DOM and triggering Player
    // hotkeys. We do not preventDefault here because we _want_ the browser to
    // handle it.
    if (keycode__default['default'].isEventKey(event, 'Space') || keycode__default['default'].isEventKey(event, 'Enter')) {
      event.stopPropagation();
      return;
    } // Pass keypress handling up for unsupported keys


    _ClickableComponent.prototype.handleKeyDown.call(this, event);
  };

  return Button;
}(ClickableComponent);

Component.registerComponent('Button', Button);

/**
 * The initial play button that shows before the video has played. The hiding of the
 * `BigPlayButton` get done via CSS and `Player` states.
 *
 * @extends Button
 */

var BigPlayButton = /*#__PURE__*/function (_Button) {
  _inheritsLoose__default['default'](BigPlayButton, _Button);

  function BigPlayButton(player, options) {
    var _this;

    _this = _Button.call(this, player, options) || this;
    _this.mouseused_ = false;

    _this.on('mousedown', function (e) {
      return _this.handleMouseDown(e);
    });

    return _this;
  }
  /**
   * Builds the default DOM `className`.
   *
   * @return {string}
   *         The DOM `className` for this object. Always returns 'vjs-big-play-button'.
   */


  var _proto = BigPlayButton.prototype;

  _proto.buildCSSClass = function buildCSSClass() {
    return 'vjs-big-play-button';
  }
  /**
   * This gets called when a `BigPlayButton` "clicked". See {@link ClickableComponent}
   * for more detailed information on what a click can be.
   *
   * @param {EventTarget~Event} event
   *        The `keydown`, `tap`, or `click` event that caused this function to be
   *        called.
   *
   * @listens tap
   * @listens click
   */
  ;

  _proto.handleClick = function handleClick(event) {
    var playPromise = this.player_.play(); // exit early if clicked via the mouse

    if (this.mouseused_ && event.clientX && event.clientY) {
      var sourceIsEncrypted = this.player_.usingPlugin('eme') && this.player_.eme.sessions && this.player_.eme.sessions.length > 0;
      silencePromise(playPromise);

      if (this.player_.tech(true) && // We've observed a bug in IE and Edge when playing back DRM content where
      // calling .focus() on the video element causes the video to go black,
      // so we avoid it in that specific case
      !((IE_VERSION || IS_EDGE) && sourceIsEncrypted)) {
        this.player_.tech(true).focus();
      }

      return;
    }

    var cb = this.player_.getChild('controlBar');
    var playToggle = cb && cb.getChild('playToggle');

    if (!playToggle) {
      this.player_.tech(true).focus();
      return;
    }

    var playFocus = function playFocus() {
      return playToggle.focus();
    };

    if (isPromise(playPromise)) {
      playPromise.then(playFocus, function () {});
    } else {
      this.setTimeout(playFocus, 1);
    }
  };

  _proto.handleKeyDown = function handleKeyDown(event) {
    this.mouseused_ = false;

    _Button.prototype.handleKeyDown.call(this, event);
  };

  _proto.handleMouseDown = function handleMouseDown(event) {
    this.mouseused_ = true;
  };

  return BigPlayButton;
}(Button);
/**
 * The text that should display over the `BigPlayButton`s controls. Added to for localization.
 *
 * @type {string}
 * @private
 */


BigPlayButton.prototype.controlText_ = 'Play Video';
Component.registerComponent('BigPlayButton', BigPlayButton);

/**
 * The `CloseButton` is a `{@link Button}` that fires a `close` event when
 * it gets clicked.
 *
 * @extends Button
 */

var CloseButton = /*#__PURE__*/function (_Button) {
  _inheritsLoose__default['default'](CloseButton, _Button);

  /**
  * Creates an instance of the this class.
  *
  * @param  {Player} player
  *         The `Player` that this class should be attached to.
  *
  * @param  {Object} [options]
  *         The key/value store of player options.
  */
  function CloseButton(player, options) {
    var _this;

    _this = _Button.call(this, player, options) || this;

    _this.controlText(options && options.controlText || _this.localize('Close'));

    return _this;
  }
  /**
  * Builds the default DOM `className`.
  *
  * @return {string}
  *         The DOM `className` for this object.
  */


  var _proto = CloseButton.prototype;

  _proto.buildCSSClass = function buildCSSClass() {
    return "vjs-close-button " + _Button.prototype.buildCSSClass.call(this);
  }
  /**
   * This gets called when a `CloseButton` gets clicked. See
   * {@link ClickableComponent#handleClick} for more information on when
   * this will be triggered
   *
   * @param {EventTarget~Event} event
   *        The `keydown`, `tap`, or `click` event that caused this function to be
   *        called.
   *
   * @listens tap
   * @listens click
   * @fires CloseButton#close
   */
  ;

  _proto.handleClick = function handleClick(event) {
    /**
     * Triggered when the a `CloseButton` is clicked.
     *
     * @event CloseButton#close
     * @type {EventTarget~Event}
     *
     * @property {boolean} [bubbles=false]
     *           set to false so that the close event does not
     *           bubble up to parents if there is no listener
     */
    this.trigger({
      type: 'close',
      bubbles: false
    });
  }
  /**
   * Event handler that is called when a `CloseButton` receives a
   * `keydown` event.
   *
   * By default, if the key is Esc, it will trigger a `click` event.
   *
   * @param {EventTarget~Event} event
   *        The `keydown` event that caused this function to be called.
   *
   * @listens keydown
   */
  ;

  _proto.handleKeyDown = function handleKeyDown(event) {
    // Esc button will trigger `click` event
    if (keycode__default['default'].isEventKey(event, 'Esc')) {
      event.preventDefault();
      event.stopPropagation();
      this.trigger('click');
    } else {
      // Pass keypress handling up for unsupported keys
      _Button.prototype.handleKeyDown.call(this, event);
    }
  };

  return CloseButton;
}(Button);

Component.registerComponent('CloseButton', CloseButton);

/**
 * Button to toggle between play and pause.
 *
 * @extends Button
 */

var PlayToggle = /*#__PURE__*/function (_Button) {
  _inheritsLoose__default['default'](PlayToggle, _Button);

  /**
   * Creates an instance of this class.
   *
   * @param {Player} player
   *        The `Player` that this class should be attached to.
   *
   * @param {Object} [options={}]
   *        The key/value store of player options.
   */
  function PlayToggle(player, options) {
    var _this;

    if (options === void 0) {
      options = {};
    }

    _this = _Button.call(this, player, options) || this; // show or hide replay icon

    options.replay = options.replay === undefined || options.replay;

    _this.on(player, 'play', function (e) {
      return _this.handlePlay(e);
    });

    _this.on(player, 'pause', function (e) {
      return _this.handlePause(e);
    });

    if (options.replay) {
      _this.on(player, 'ended', function (e) {
        return _this.handleEnded(e);
      });
    }

    return _this;
  }
  /**
   * Builds the default DOM `className`.
   *
   * @return {string}
   *         The DOM `className` for this object.
   */


  var _proto = PlayToggle.prototype;

  _proto.buildCSSClass = function buildCSSClass() {
    return "vjs-play-control " + _Button.prototype.buildCSSClass.call(this);
  }
  /**
   * This gets called when an `PlayToggle` is "clicked". See
   * {@link ClickableComponent} for more detailed information on what a click can be.
   *
   * @param {EventTarget~Event} [event]
   *        The `keydown`, `tap`, or `click` event that caused this function to be
   *        called.
   *
   * @listens tap
   * @listens click
   */
  ;

  _proto.handleClick = function handleClick(event) {
    if (this.player_.paused()) {
      silencePromise(this.player_.play());
    } else {
      this.player_.pause();
    }
  }
  /**
   * This gets called once after the video has ended and the user seeks so that
   * we can change the replay button back to a play button.
   *
   * @param {EventTarget~Event} [event]
   *        The event that caused this function to run.
   *
   * @listens Player#seeked
   */
  ;

  _proto.handleSeeked = function handleSeeked(event) {
    this.removeClass('vjs-ended');

    if (this.player_.paused()) {
      this.handlePause(event);
    } else {
      this.handlePlay(event);
    }
  }
  /**
   * Add the vjs-playing class to the element so it can change appearance.
   *
   * @param {EventTarget~Event} [event]
   *        The event that caused this function to run.
   *
   * @listens Player#play
   */
  ;

  _proto.handlePlay = function handlePlay(event) {
    this.removeClass('vjs-ended');
    this.removeClass('vjs-paused');
    this.addClass('vjs-playing'); // change the button text to "Pause"

    this.controlText('Pause');
  }
  /**
   * Add the vjs-paused class to the element so it can change appearance.
   *
   * @param {EventTarget~Event} [event]
   *        The event that caused this function to run.
   *
   * @listens Player#pause
   */
  ;

  _proto.handlePause = function handlePause(event) {
    this.removeClass('vjs-playing');
    this.addClass('vjs-paused'); // change the button text to "Play"

    this.controlText('Play');
  }
  /**
   * Add the vjs-ended class to the element so it can change appearance
   *
   * @param {EventTarget~Event} [event]
   *        The event that caused this function to run.
   *
   * @listens Player#ended
   */
  ;

  _proto.handleEnded = function handleEnded(event) {
    var _this2 = this;

    this.removeClass('vjs-playing');
    this.addClass('vjs-ended'); // change the button text to "Replay"

    this.controlText('Replay'); // on the next seek remove the replay button

    this.one(this.player_, 'seeked', function (e) {
      return _this2.handleSeeked(e);
    });
  };

  return PlayToggle;
}(Button);
/**
 * The text that should display over the `PlayToggle`s controls. Added for localization.
 *
 * @type {string}
 * @private
 */


PlayToggle.prototype.controlText_ = 'Play';
Component.registerComponent('PlayToggle', PlayToggle);

/**
 * @file format-time.js
 * @module format-time
 */

/**
 * Format seconds as a time string, H:MM:SS or M:SS. Supplying a guide (in
 * seconds) will force a number of leading zeros to cover the length of the
 * guide.
 *
 * @private
 * @param  {number} seconds
 *         Number of seconds to be turned into a string
 *
 * @param  {number} guide
 *         Number (in seconds) to model the string after
 *
 * @return {string}
 *         Time formatted as H:MM:SS or M:SS
 */
var defaultImplementation = function defaultImplementation(seconds, guide) {
  seconds = seconds < 0 ? 0 : seconds;
  var s = Math.floor(seconds % 60);
  var m = Math.floor(seconds / 60 % 60);
  var h = Math.floor(seconds / 3600);
  var gm = Math.floor(guide / 60 % 60);
  var gh = Math.floor(guide / 3600); // handle invalid times

  if (isNaN(seconds) || seconds === Infinity) {
    // '-' is false for all relational operators (e.g. <, >=) so this setting
    // will add the minimum number of fields specified by the guide
    h = m = s = '-';
  } // Check if we need to show hours


  h = h > 0 || gh > 0 ? h + ':' : ''; // If hours are showing, we may need to add a leading zero.
  // Always show at least one digit of minutes.

  m = ((h || gm >= 10) && m < 10 ? '0' + m : m) + ':'; // Check if leading zero is need for seconds

  s = s < 10 ? '0' + s : s;
  return h + m + s;
}; // Internal pointer to the current implementation.


var implementation = defaultImplementation;
/**
 * Replaces the default formatTime implementation with a custom implementation.
 *
 * @param {Function} customImplementation
 *        A function which will be used in place of the default formatTime
 *        implementation. Will receive the current time in seconds and the
 *        guide (in seconds) as arguments.
 */

function setFormatTime(customImplementation) {
  implementation = customImplementation;
}
/**
 * Resets formatTime to the default implementation.
 */

function resetFormatTime() {
  implementation = defaultImplementation;
}
/**
 * Delegates to either the default time formatting function or a custom
 * function supplied via `setFormatTime`.
 *
 * Formats seconds as a time string (H:MM:SS or M:SS). Supplying a
 * guide (in seconds) will force a number of leading zeros to cover the
 * length of the guide.
 *
 * @static
 * @example  formatTime(125, 600) === "02:05"
 * @param    {number} seconds
 *           Number of seconds to be turned into a string
 *
 * @param    {number} guide
 *           Number (in seconds) to model the string after
 *
 * @return   {string}
 *           Time formatted as H:MM:SS or M:SS
 */

function formatTime(seconds, guide) {
  if (guide === void 0) {
    guide = seconds;
  }

  return implementation(seconds, guide);
}

/**
 * Displays time information about the video
 *
 * @extends Component
 */

var TimeDisplay = /*#__PURE__*/function (_Component) {
  _inheritsLoose__default['default'](TimeDisplay, _Component);

  /**
   * Creates an instance of this class.
   *
   * @param {Player} player
   *        The `Player` that this class should be attached to.
   *
   * @param {Object} [options]
   *        The key/value store of player options.
   */
  function TimeDisplay(player, options) {
    var _this;

    _this = _Component.call(this, player, options) || this;

    _this.on(player, ['timeupdate', 'ended'], function (e) {
      return _this.updateContent(e);
    });

    _this.updateTextNode_();

    return _this;
  }
  /**
   * Create the `Component`'s DOM element
   *
   * @return {Element}
   *         The element that was created.
   */


  var _proto = TimeDisplay.prototype;

  _proto.createEl = function createEl$1() {
    var className = this.buildCSSClass();

    var el = _Component.prototype.createEl.call(this, 'div', {
      className: className + " vjs-time-control vjs-control"
    });

    var span = createEl('span', {
      className: 'vjs-control-text',
      textContent: this.localize(this.labelText_) + "\xA0"
    }, {
      role: 'presentation'
    });
    el.appendChild(span);
    this.contentEl_ = createEl('span', {
      className: className + "-display"
    }, {
      // tell screen readers not to automatically read the time as it changes
      'aria-live': 'off',
      // span elements have no implicit role, but some screen readers (notably VoiceOver)
      // treat them as a break between items in the DOM when using arrow keys
      // (or left-to-right swipes on iOS) to read contents of a page. Using
      // role='presentation' causes VoiceOver to NOT treat this span as a break.
      'role': 'presentation'
    });
    el.appendChild(this.contentEl_);
    return el;
  };

  _proto.dispose = function dispose() {
    this.contentEl_ = null;
    this.textNode_ = null;

    _Component.prototype.dispose.call(this);
  }
  /**
   * Updates the time display text node with a new time
   *
   * @param {number} [time=0] the time to update to
   *
   * @private
   */
  ;

  _proto.updateTextNode_ = function updateTextNode_(time) {
    var _this2 = this;

    if (time === void 0) {
      time = 0;
    }

    time = formatTime(time);

    if (this.formattedTime_ === time) {
      return;
    }

    this.formattedTime_ = time;
    this.requestNamedAnimationFrame('TimeDisplay#updateTextNode_', function () {
      if (!_this2.contentEl_) {
        return;
      }

      var oldNode = _this2.textNode_;

      if (oldNode && _this2.contentEl_.firstChild !== oldNode) {
        oldNode = null;
        log.warn('TimeDisplay#updateTextnode_: Prevented replacement of text node element since it was no longer a child of this node. Appending a new node instead.');
      }

      _this2.textNode_ = document__default['default'].createTextNode(_this2.formattedTime_);

      if (!_this2.textNode_) {
        return;
      }

      if (oldNode) {
        _this2.contentEl_.replaceChild(_this2.textNode_, oldNode);
      } else {
        _this2.contentEl_.appendChild(_this2.textNode_);
      }
    });
  }
  /**
   * To be filled out in the child class, should update the displayed time
   * in accordance with the fact that the current time has changed.
   *
   * @param {EventTarget~Event} [event]
   *        The `timeupdate`  event that caused this to run.
   *
   * @listens Player#timeupdate
   */
  ;

  _proto.updateContent = function updateContent(event) {};

  return TimeDisplay;
}(Component);
/**
 * The text that is added to the `TimeDisplay` for screen reader users.
 *
 * @type {string}
 * @private
 */


TimeDisplay.prototype.labelText_ = 'Time';
/**
 * The text that should display over the `TimeDisplay`s controls. Added to for localization.
 *
 * @type {string}
 * @private
 *
 * @deprecated in v7; controlText_ is not used in non-active display Components
 */

TimeDisplay.prototype.controlText_ = 'Time';
Component.registerComponent('TimeDisplay', TimeDisplay);

/**
 * Displays the current time
 *
 * @extends Component
 */

var CurrentTimeDisplay = /*#__PURE__*/function (_TimeDisplay) {
  _inheritsLoose__default['default'](CurrentTimeDisplay, _TimeDisplay);

  function CurrentTimeDisplay() {
    return _TimeDisplay.apply(this, arguments) || this;
  }

  var _proto = CurrentTimeDisplay.prototype;

  /**
   * Builds the default DOM `className`.
   *
   * @return {string}
   *         The DOM `className` for this object.
   */
  _proto.buildCSSClass = function buildCSSClass() {
    return 'vjs-current-time';
  }
  /**
   * Update current time display
   *
   * @param {EventTarget~Event} [event]
   *        The `timeupdate` event that caused this function to run.
   *
   * @listens Player#timeupdate
   */
  ;

  _proto.updateContent = function updateContent(event) {
    // Allows for smooth scrubbing, when player can't keep up.
    var time;

    if (this.player_.ended()) {
      time = this.player_.duration();
    } else {
      time = this.player_.scrubbing() ? this.player_.getCache().currentTime : this.player_.currentTime();
    }

    this.updateTextNode_(time);
  };

  return CurrentTimeDisplay;
}(TimeDisplay);
/**
 * The text that is added to the `CurrentTimeDisplay` for screen reader users.
 *
 * @type {string}
 * @private
 */


CurrentTimeDisplay.prototype.labelText_ = 'Current Time';
/**
 * The text that should display over the `CurrentTimeDisplay`s controls. Added to for localization.
 *
 * @type {string}
 * @private
 *
 * @deprecated in v7; controlText_ is not used in non-active display Components
 */

CurrentTimeDisplay.prototype.controlText_ = 'Current Time';
Component.registerComponent('CurrentTimeDisplay', CurrentTimeDisplay);

/**
 * Displays the duration
 *
 * @extends Component
 */

var DurationDisplay = /*#__PURE__*/function (_TimeDisplay) {
  _inheritsLoose__default['default'](DurationDisplay, _TimeDisplay);

  /**
   * Creates an instance of this class.
   *
   * @param {Player} player
   *        The `Player` that this class should be attached to.
   *
   * @param {Object} [options]
   *        The key/value store of player options.
   */
  function DurationDisplay(player, options) {
    var _this;

    _this = _TimeDisplay.call(this, player, options) || this;

    var updateContent = function updateContent(e) {
      return _this.updateContent(e);
    }; // we do not want to/need to throttle duration changes,
    // as they should always display the changed duration as
    // it has changed


    _this.on(player, 'durationchange', updateContent); // Listen to loadstart because the player duration is reset when a new media element is loaded,
    // but the durationchange on the user agent will not fire.
    // @see [Spec]{@link https://www.w3.org/TR/2011/WD-html5-20110113/video.html#media-element-load-algorithm}


    _this.on(player, 'loadstart', updateContent); // Also listen for timeupdate (in the parent) and loadedmetadata because removing those
    // listeners could have broken dependent applications/libraries. These
    // can likely be removed for 7.0.


    _this.on(player, 'loadedmetadata', updateContent);

    return _this;
  }
  /**
   * Builds the default DOM `className`.
   *
   * @return {string}
   *         The DOM `className` for this object.
   */


  var _proto = DurationDisplay.prototype;

  _proto.buildCSSClass = function buildCSSClass() {
    return 'vjs-duration';
  }
  /**
   * Update duration time display.
   *
   * @param {EventTarget~Event} [event]
   *        The `durationchange`, `timeupdate`, or `loadedmetadata` event that caused
   *        this function to be called.
   *
   * @listens Player#durationchange
   * @listens Player#timeupdate
   * @listens Player#loadedmetadata
   */
  ;

  _proto.updateContent = function updateContent(event) {
    var duration = this.player_.duration();
    this.updateTextNode_(duration);
  };

  return DurationDisplay;
}(TimeDisplay);
/**
 * The text that is added to the `DurationDisplay` for screen reader users.
 *
 * @type {string}
 * @private
 */


DurationDisplay.prototype.labelText_ = 'Duration';
/**
 * The text that should display over the `DurationDisplay`s controls. Added to for localization.
 *
 * @type {string}
 * @private
 *
 * @deprecated in v7; controlText_ is not used in non-active display Components
 */

DurationDisplay.prototype.controlText_ = 'Duration';
Component.registerComponent('DurationDisplay', DurationDisplay);

/**
 * The separator between the current time and duration.
 * Can be hidden if it's not needed in the design.
 *
 * @extends Component
 */

var TimeDivider = /*#__PURE__*/function (_Component) {
  _inheritsLoose__default['default'](TimeDivider, _Component);

  function TimeDivider() {
    return _Component.apply(this, arguments) || this;
  }

  var _proto = TimeDivider.prototype;

  /**
   * Create the component's DOM element
   *
   * @return {Element}
   *         The element that was created.
   */
  _proto.createEl = function createEl() {
    var el = _Component.prototype.createEl.call(this, 'div', {
      className: 'vjs-time-control vjs-time-divider'
    }, {
      // this element and its contents can be hidden from assistive techs since
      // it is made extraneous by the announcement of the control text
      // for the current time and duration displays
      'aria-hidden': true
    });

    var div = _Component.prototype.createEl.call(this, 'div');

    var span = _Component.prototype.createEl.call(this, 'span', {
      textContent: '/'
    });

    div.appendChild(span);
    el.appendChild(div);
    return el;
  };

  return TimeDivider;
}(Component);

Component.registerComponent('TimeDivider', TimeDivider);

/**
 * Displays the time left in the video
 *
 * @extends Component
 */

var RemainingTimeDisplay = /*#__PURE__*/function (_TimeDisplay) {
  _inheritsLoose__default['default'](RemainingTimeDisplay, _TimeDisplay);

  /**
   * Creates an instance of this class.
   *
   * @param {Player} player
   *        The `Player` that this class should be attached to.
   *
   * @param {Object} [options]
   *        The key/value store of player options.
   */
  function RemainingTimeDisplay(player, options) {
    var _this;

    _this = _TimeDisplay.call(this, player, options) || this;

    _this.on(player, 'durationchange', function (e) {
      return _this.updateContent(e);
    });

    return _this;
  }
  /**
   * Builds the default DOM `className`.
   *
   * @return {string}
   *         The DOM `className` for this object.
   */


  var _proto = RemainingTimeDisplay.prototype;

  _proto.buildCSSClass = function buildCSSClass() {
    return 'vjs-remaining-time';
  }
  /**
   * Create the `Component`'s DOM element with the "minus" characted prepend to the time
   *
   * @return {Element}
   *         The element that was created.
   */
  ;

  _proto.createEl = function createEl$1() {
    var el = _TimeDisplay.prototype.createEl.call(this);

    if (this.options_.displayNegative !== false) {
      el.insertBefore(createEl('span', {}, {
        'aria-hidden': true
      }, '-'), this.contentEl_);
    }

    return el;
  }
  /**
   * Update remaining time display.
   *
   * @param {EventTarget~Event} [event]
   *        The `timeupdate` or `durationchange` event that caused this to run.
   *
   * @listens Player#timeupdate
   * @listens Player#durationchange
   */
  ;

  _proto.updateContent = function updateContent(event) {
    if (typeof this.player_.duration() !== 'number') {
      return;
    }

    var time; // @deprecated We should only use remainingTimeDisplay
    // as of video.js 7

    if (this.player_.ended()) {
      time = 0;
    } else if (this.player_.remainingTimeDisplay) {
      time = this.player_.remainingTimeDisplay();
    } else {
      time = this.player_.remainingTime();
    }

    this.updateTextNode_(time);
  };

  return RemainingTimeDisplay;
}(TimeDisplay);
/**
 * The text that is added to the `RemainingTimeDisplay` for screen reader users.
 *
 * @type {string}
 * @private
 */


RemainingTimeDisplay.prototype.labelText_ = 'Remaining Time';
/**
 * The text that should display over the `RemainingTimeDisplay`s controls. Added to for localization.
 *
 * @type {string}
 * @private
 *
 * @deprecated in v7; controlText_ is not used in non-active display Components
 */

RemainingTimeDisplay.prototype.controlText_ = 'Remaining Time';
Component.registerComponent('RemainingTimeDisplay', RemainingTimeDisplay);

/**
 * Displays the live indicator when duration is Infinity.
 *
 * @extends Component
 */

var LiveDisplay = /*#__PURE__*/function (_Component) {
  _inheritsLoose__default['default'](LiveDisplay, _Component);

  /**
   * Creates an instance of this class.
   *
   * @param {Player} player
   *        The `Player` that this class should be attached to.
   *
   * @param {Object} [options]
   *        The key/value store of player options.
   */
  function LiveDisplay(player, options) {
    var _this;

    _this = _Component.call(this, player, options) || this;

    _this.updateShowing();

    _this.on(_this.player(), 'durationchange', function (e) {
      return _this.updateShowing(e);
    });

    return _this;
  }
  /**
   * Create the `Component`'s DOM element
   *
   * @return {Element}
   *         The element that was created.
   */


  var _proto = LiveDisplay.prototype;

  _proto.createEl = function createEl$1() {
    var el = _Component.prototype.createEl.call(this, 'div', {
      className: 'vjs-live-control vjs-control'
    });

    this.contentEl_ = createEl('div', {
      className: 'vjs-live-display'
    }, {
      'aria-live': 'off'
    });
    this.contentEl_.appendChild(createEl('span', {
      className: 'vjs-control-text',
      textContent: this.localize('Stream Type') + "\xA0"
    }));
    this.contentEl_.appendChild(document__default['default'].createTextNode(this.localize('LIVE')));
    el.appendChild(this.contentEl_);
    return el;
  };

  _proto.dispose = function dispose() {
    this.contentEl_ = null;

    _Component.prototype.dispose.call(this);
  }
  /**
   * Check the duration to see if the LiveDisplay should be showing or not. Then show/hide
   * it accordingly
   *
   * @param {EventTarget~Event} [event]
   *        The {@link Player#durationchange} event that caused this function to run.
   *
   * @listens Player#durationchange
   */
  ;

  _proto.updateShowing = function updateShowing(event) {
    if (this.player().duration() === Infinity) {
      this.show();
    } else {
      this.hide();
    }
  };

  return LiveDisplay;
}(Component);

Component.registerComponent('LiveDisplay', LiveDisplay);

/**
 * Displays the live indicator when duration is Infinity.
 *
 * @extends Component
 */

var SeekToLive = /*#__PURE__*/function (_Button) {
  _inheritsLoose__default['default'](SeekToLive, _Button);

  /**
   * Creates an instance of this class.
   *
   * @param {Player} player
   *        The `Player` that this class should be attached to.
   *
   * @param {Object} [options]
   *        The key/value store of player options.
   */
  function SeekToLive(player, options) {
    var _this;

    _this = _Button.call(this, player, options) || this;

    _this.updateLiveEdgeStatus();

    if (_this.player_.liveTracker) {
      _this.updateLiveEdgeStatusHandler_ = function (e) {
        return _this.updateLiveEdgeStatus(e);
      };

      _this.on(_this.player_.liveTracker, 'liveedgechange', _this.updateLiveEdgeStatusHandler_);
    }

    return _this;
  }
  /**
   * Create the `Component`'s DOM element
   *
   * @return {Element}
   *         The element that was created.
   */


  var _proto = SeekToLive.prototype;

  _proto.createEl = function createEl$1() {
    var el = _Button.prototype.createEl.call(this, 'button', {
      className: 'vjs-seek-to-live-control vjs-control'
    });

    this.textEl_ = createEl('span', {
      className: 'vjs-seek-to-live-text',
      textContent: this.localize('LIVE')
    }, {
      'aria-hidden': 'true'
    });
    el.appendChild(this.textEl_);
    return el;
  }
  /**
   * Update the state of this button if we are at the live edge
   * or not
   */
  ;

  _proto.updateLiveEdgeStatus = function updateLiveEdgeStatus() {
    // default to live edge
    if (!this.player_.liveTracker || this.player_.liveTracker.atLiveEdge()) {
      this.setAttribute('aria-disabled', true);
      this.addClass('vjs-at-live-edge');
      this.controlText('Seek to live, currently playing live');
    } else {
      this.setAttribute('aria-disabled', false);
      this.removeClass('vjs-at-live-edge');
      this.controlText('Seek to live, currently behind live');
    }
  }
  /**
   * On click bring us as near to the live point as possible.
   * This requires that we wait for the next `live-seekable-change`
   * event which will happen every segment length seconds.
   */
  ;

  _proto.handleClick = function handleClick() {
    this.player_.liveTracker.seekToLiveEdge();
  }
  /**
   * Dispose of the element and stop tracking
   */
  ;

  _proto.dispose = function dispose() {
    if (this.player_.liveTracker) {
      this.off(this.player_.liveTracker, 'liveedgechange', this.updateLiveEdgeStatusHandler_);
    }

    this.textEl_ = null;

    _Button.prototype.dispose.call(this);
  };

  return SeekToLive;
}(Button);

SeekToLive.prototype.controlText_ = 'Seek to live, currently playing live';
Component.registerComponent('SeekToLive', SeekToLive);

/**
 * Keep a number between a min and a max value
 *
 * @param {number} number
 *        The number to clamp
 *
 * @param {number} min
 *        The minimum value
 * @param {number} max
 *        The maximum value
 *
 * @return {number}
 *         the clamped number
 */
var clamp = function clamp(number, min, max) {
  number = Number(number);
  return Math.min(max, Math.max(min, isNaN(number) ? min : number));
};

/**
 * The base functionality for a slider. Can be vertical or horizontal.
 * For instance the volume bar or the seek bar on a video is a slider.
 *
 * @extends Component
 */

var Slider = /*#__PURE__*/function (_Component) {
  _inheritsLoose__default['default'](Slider, _Component);

  /**
  * Create an instance of this class
  *
  * @param {Player} player
  *        The `Player` that this class should be attached to.
  *
  * @param {Object} [options]
  *        The key/value store of player options.
  */
  function Slider(player, options) {
    var _this;

    _this = _Component.call(this, player, options) || this;

    _this.handleMouseDown_ = function (e) {
      return _this.handleMouseDown(e);
    };

    _this.handleMouseUp_ = function (e) {
      return _this.handleMouseUp(e);
    };

    _this.handleKeyDown_ = function (e) {
      return _this.handleKeyDown(e);
    };

    _this.handleClick_ = function (e) {
      return _this.handleClick(e);
    };

    _this.handleMouseMove_ = function (e) {
      return _this.handleMouseMove(e);
    };

    _this.update_ = function (e) {
      return _this.update(e);
    }; // Set property names to bar to match with the child Slider class is looking for


    _this.bar = _this.getChild(_this.options_.barName); // Set a horizontal or vertical class on the slider depending on the slider type

    _this.vertical(!!_this.options_.vertical);

    _this.enable();

    return _this;
  }
  /**
   * Are controls are currently enabled for this slider or not.
   *
   * @return {boolean}
   *         true if controls are enabled, false otherwise
   */


  var _proto = Slider.prototype;

  _proto.enabled = function enabled() {
    return this.enabled_;
  }
  /**
   * Enable controls for this slider if they are disabled
   */
  ;

  _proto.enable = function enable() {
    if (this.enabled()) {
      return;
    }

    this.on('mousedown', this.handleMouseDown_);
    this.on('touchstart', this.handleMouseDown_);
    this.on('keydown', this.handleKeyDown_);
    this.on('click', this.handleClick_); // TODO: deprecated, controlsvisible does not seem to be fired

    this.on(this.player_, 'controlsvisible', this.update);

    if (this.playerEvent) {
      this.on(this.player_, this.playerEvent, this.update);
    }

    this.removeClass('disabled');
    this.setAttribute('tabindex', 0);
    this.enabled_ = true;
  }
  /**
   * Disable controls for this slider if they are enabled
   */
  ;

  _proto.disable = function disable() {
    if (!this.enabled()) {
      return;
    }

    var doc = this.bar.el_.ownerDocument;
    this.off('mousedown', this.handleMouseDown_);
    this.off('touchstart', this.handleMouseDown_);
    this.off('keydown', this.handleKeyDown_);
    this.off('click', this.handleClick_);
    this.off(this.player_, 'controlsvisible', this.update_);
    this.off(doc, 'mousemove', this.handleMouseMove_);
    this.off(doc, 'mouseup', this.handleMouseUp_);
    this.off(doc, 'touchmove', this.handleMouseMove_);
    this.off(doc, 'touchend', this.handleMouseUp_);
    this.removeAttribute('tabindex');
    this.addClass('disabled');

    if (this.playerEvent) {
      this.off(this.player_, this.playerEvent, this.update);
    }

    this.enabled_ = false;
  }
  /**
   * Create the `Slider`s DOM element.
   *
   * @param {string} type
   *        Type of element to create.
   *
   * @param {Object} [props={}]
   *        List of properties in Object form.
   *
   * @param {Object} [attributes={}]
   *        list of attributes in Object form.
   *
   * @return {Element}
   *         The element that gets created.
   */
  ;

  _proto.createEl = function createEl(type, props, attributes) {
    if (props === void 0) {
      props = {};
    }

    if (attributes === void 0) {
      attributes = {};
    }

    // Add the slider element class to all sub classes
    props.className = props.className + ' vjs-slider';
    props = assign({
      tabIndex: 0
    }, props);
    attributes = assign({
      'role': 'slider',
      'aria-valuenow': 0,
      'aria-valuemin': 0,
      'aria-valuemax': 100,
      'tabIndex': 0
    }, attributes);
    return _Component.prototype.createEl.call(this, type, props, attributes);
  }
  /**
   * Handle `mousedown` or `touchstart` events on the `Slider`.
   *
   * @param {EventTarget~Event} event
   *        `mousedown` or `touchstart` event that triggered this function
   *
   * @listens mousedown
   * @listens touchstart
   * @fires Slider#slideractive
   */
  ;

  _proto.handleMouseDown = function handleMouseDown(event) {
    var doc = this.bar.el_.ownerDocument;

    if (event.type === 'mousedown') {
      event.preventDefault();
    } // Do not call preventDefault() on touchstart in Chrome
    // to avoid console warnings. Use a 'touch-action: none' style
    // instead to prevent unintented scrolling.
    // https://developers.google.com/web/updates/2017/01/scrolling-intervention


    if (event.type === 'touchstart' && !IS_CHROME) {
      event.preventDefault();
    }

    blockTextSelection();
    this.addClass('vjs-sliding');
    /**
     * Triggered when the slider is in an active state
     *
     * @event Slider#slideractive
     * @type {EventTarget~Event}
     */

    this.trigger('slideractive');
    this.on(doc, 'mousemove', this.handleMouseMove_);
    this.on(doc, 'mouseup', this.handleMouseUp_);
    this.on(doc, 'touchmove', this.handleMouseMove_);
    this.on(doc, 'touchend', this.handleMouseUp_);
    this.handleMouseMove(event, true);
  }
  /**
   * Handle the `mousemove`, `touchmove`, and `mousedown` events on this `Slider`.
   * The `mousemove` and `touchmove` events will only only trigger this function during
   * `mousedown` and `touchstart`. This is due to {@link Slider#handleMouseDown} and
   * {@link Slider#handleMouseUp}.
   *
   * @param {EventTarget~Event} event
   *        `mousedown`, `mousemove`, `touchstart`, or `touchmove` event that triggered
   *        this function
   * @param {boolean} mouseDown this is a flag that should be set to true if `handleMouseMove` is called directly. It allows us to skip things that should not happen if coming from mouse down but should happen on regular mouse move handler. Defaults to false.
   *
   * @listens mousemove
   * @listens touchmove
   */
  ;

  _proto.handleMouseMove = function handleMouseMove(event) {}
  /**
   * Handle `mouseup` or `touchend` events on the `Slider`.
   *
   * @param {EventTarget~Event} event
   *        `mouseup` or `touchend` event that triggered this function.
   *
   * @listens touchend
   * @listens mouseup
   * @fires Slider#sliderinactive
   */
  ;

  _proto.handleMouseUp = function handleMouseUp() {
    var doc = this.bar.el_.ownerDocument;
    unblockTextSelection();
    this.removeClass('vjs-sliding');
    /**
     * Triggered when the slider is no longer in an active state.
     *
     * @event Slider#sliderinactive
     * @type {EventTarget~Event}
     */

    this.trigger('sliderinactive');
    this.off(doc, 'mousemove', this.handleMouseMove_);
    this.off(doc, 'mouseup', this.handleMouseUp_);
    this.off(doc, 'touchmove', this.handleMouseMove_);
    this.off(doc, 'touchend', this.handleMouseUp_);
    this.update();
  }
  /**
   * Update the progress bar of the `Slider`.
   *
   * @return {number}
   *          The percentage of progress the progress bar represents as a
   *          number from 0 to 1.
   */
  ;

  _proto.update = function update() {
    var _this2 = this;

    // In VolumeBar init we have a setTimeout for update that pops and update
    // to the end of the execution stack. The player is destroyed before then
    // update will cause an error
    // If there's no bar...
    if (!this.el_ || !this.bar) {
      return;
    } // clamp progress between 0 and 1
    // and only round to four decimal places, as we round to two below


    var progress = this.getProgress();

    if (progress === this.progress_) {
      return progress;
    }

    this.progress_ = progress;
    this.requestNamedAnimationFrame('Slider#update', function () {
      // Set the new bar width or height
      var sizeKey = _this2.vertical() ? 'height' : 'width'; // Convert to a percentage for css value

      _this2.bar.el().style[sizeKey] = (progress * 100).toFixed(2) + '%';
    });
    return progress;
  }
  /**
   * Get the percentage of the bar that should be filled
   * but clamped and rounded.
   *
   * @return {number}
   *         percentage filled that the slider is
   */
  ;

  _proto.getProgress = function getProgress() {
    return Number(clamp(this.getPercent(), 0, 1).toFixed(4));
  }
  /**
   * Calculate distance for slider
   *
   * @param {EventTarget~Event} event
   *        The event that caused this function to run.
   *
   * @return {number}
   *         The current position of the Slider.
   *         - position.x for vertical `Slider`s
   *         - position.y for horizontal `Slider`s
   */
  ;

  _proto.calculateDistance = function calculateDistance(event) {
    var position = getPointerPosition(this.el_, event);

    if (this.vertical()) {
      return position.y;
    }

    return position.x;
  }
  /**
   * Handle a `keydown` event on the `Slider`. Watches for left, rigth, up, and down
   * arrow keys. This function will only be called when the slider has focus. See
   * {@link Slider#handleFocus} and {@link Slider#handleBlur}.
   *
   * @param {EventTarget~Event} event
   *        the `keydown` event that caused this function to run.
   *
   * @listens keydown
   */
  ;

  _proto.handleKeyDown = function handleKeyDown(event) {
    // Left and Down Arrows
    if (keycode__default['default'].isEventKey(event, 'Left') || keycode__default['default'].isEventKey(event, 'Down')) {
      event.preventDefault();
      event.stopPropagation();
      this.stepBack(); // Up and Right Arrows
    } else if (keycode__default['default'].isEventKey(event, 'Right') || keycode__default['default'].isEventKey(event, 'Up')) {
      event.preventDefault();
      event.stopPropagation();
      this.stepForward();
    } else {
      // Pass keydown handling up for unsupported keys
      _Component.prototype.handleKeyDown.call(this, event);
    }
  }
  /**
   * Listener for click events on slider, used to prevent clicks
   *   from bubbling up to parent elements like button menus.
   *
   * @param {Object} event
   *        Event that caused this object to run
   */
  ;

  _proto.handleClick = function handleClick(event) {
    event.stopPropagation();
    event.preventDefault();
  }
  /**
   * Get/set if slider is horizontal for vertical
   *
   * @param {boolean} [bool]
   *        - true if slider is vertical,
   *        - false is horizontal
   *
   * @return {boolean}
   *         - true if slider is vertical, and getting
   *         - false if the slider is horizontal, and getting
   */
  ;

  _proto.vertical = function vertical(bool) {
    if (bool === undefined) {
      return this.vertical_ || false;
    }

    this.vertical_ = !!bool;

    if (this.vertical_) {
      this.addClass('vjs-slider-vertical');
    } else {
      this.addClass('vjs-slider-horizontal');
    }
  };

  return Slider;
}(Component);

Component.registerComponent('Slider', Slider);

var percentify = function percentify(time, end) {
  return clamp(time / end * 100, 0, 100).toFixed(2) + '%';
};
/**
 * Shows loading progress
 *
 * @extends Component
 */


var LoadProgressBar = /*#__PURE__*/function (_Component) {
  _inheritsLoose__default['default'](LoadProgressBar, _Component);

  /**
   * Creates an instance of this class.
   *
   * @param {Player} player
   *        The `Player` that this class should be attached to.
   *
   * @param {Object} [options]
   *        The key/value store of player options.
   */
  function LoadProgressBar(player, options) {
    var _this;

    _this = _Component.call(this, player, options) || this;
    _this.partEls_ = [];

    _this.on(player, 'progress', function (e) {
      return _this.update(e);
    });

    return _this;
  }
  /**
   * Create the `Component`'s DOM element
   *
   * @return {Element}
   *         The element that was created.
   */


  var _proto = LoadProgressBar.prototype;

  _proto.createEl = function createEl$1() {
    var el = _Component.prototype.createEl.call(this, 'div', {
      className: 'vjs-load-progress'
    });

    var wrapper = createEl('span', {
      className: 'vjs-control-text'
    });
    var loadedText = createEl('span', {
      textContent: this.localize('Loaded')
    });
    var separator = document__default['default'].createTextNode(': ');
    this.percentageEl_ = createEl('span', {
      className: 'vjs-control-text-loaded-percentage',
      textContent: '0%'
    });
    el.appendChild(wrapper);
    wrapper.appendChild(loadedText);
    wrapper.appendChild(separator);
    wrapper.appendChild(this.percentageEl_);
    return el;
  };

  _proto.dispose = function dispose() {
    this.partEls_ = null;
    this.percentageEl_ = null;

    _Component.prototype.dispose.call(this);
  }
  /**
   * Update progress bar
   *
   * @param {EventTarget~Event} [event]
   *        The `progress` event that caused this function to run.
   *
   * @listens Player#progress
   */
  ;

  _proto.update = function update(event) {
    var _this2 = this;

    this.requestNamedAnimationFrame('LoadProgressBar#update', function () {
      var liveTracker = _this2.player_.liveTracker;

      var buffered = _this2.player_.buffered();

      var duration = liveTracker && liveTracker.isLive() ? liveTracker.seekableEnd() : _this2.player_.duration();

      var bufferedEnd = _this2.player_.bufferedEnd();

      var children = _this2.partEls_;
      var percent = percentify(bufferedEnd, duration);

      if (_this2.percent_ !== percent) {
        // update the width of the progress bar
        _this2.el_.style.width = percent; // update the control-text

        textContent(_this2.percentageEl_, percent);
        _this2.percent_ = percent;
      } // add child elements to represent the individual buffered time ranges


      for (var i = 0; i < buffered.length; i++) {
        var start = buffered.start(i);
        var end = buffered.end(i);
        var part = children[i];

        if (!part) {
          part = _this2.el_.appendChild(createEl());
          children[i] = part;
        } //  only update if changed


        if (part.dataset.start === start && part.dataset.end === end) {
          continue;
        }

        part.dataset.start = start;
        part.dataset.end = end; // set the percent based on the width of the progress bar (bufferedEnd)

        part.style.left = percentify(start, bufferedEnd);
        part.style.width = percentify(end - start, bufferedEnd);
      } // remove unused buffered range elements


      for (var _i = children.length; _i > buffered.length; _i--) {
        _this2.el_.removeChild(children[_i - 1]);
      }

      children.length = buffered.length;
    });
  };

  return LoadProgressBar;
}(Component);

Component.registerComponent('LoadProgressBar', LoadProgressBar);

/**
 * Time tooltips display a time above the progress bar.
 *
 * @extends Component
 */

var TimeTooltip = /*#__PURE__*/function (_Component) {
  _inheritsLoose__default['default'](TimeTooltip, _Component);

  /**
   * Creates an instance of this class.
   *
   * @param {Player} player
   *        The {@link Player} that this class should be attached to.
   *
   * @param {Object} [options]
   *        The key/value store of player options.
   */
  function TimeTooltip(player, options) {
    var _this;

    _this = _Component.call(this, player, options) || this;
    _this.update = throttle(bind(_assertThisInitialized__default['default'](_this), _this.update), UPDATE_REFRESH_INTERVAL);
    return _this;
  }
  /**
   * Create the time tooltip DOM element
   *
   * @return {Element}
   *         The element that was created.
   */


  var _proto = TimeTooltip.prototype;

  _proto.createEl = function createEl() {
    return _Component.prototype.createEl.call(this, 'div', {
      className: 'vjs-time-tooltip'
    }, {
      'aria-hidden': 'true'
    });
  }
  /**
   * Updates the position of the time tooltip relative to the `SeekBar`.
   *
   * @param {Object} seekBarRect
   *        The `ClientRect` for the {@link SeekBar} element.
   *
   * @param {number} seekBarPoint
   *        A number from 0 to 1, representing a horizontal reference point
   *        from the left edge of the {@link SeekBar}
   */
  ;

  _proto.update = function update(seekBarRect, seekBarPoint, content) {
    var tooltipRect = findPosition(this.el_);
    var playerRect = getBoundingClientRect(this.player_.el());
    var seekBarPointPx = seekBarRect.width * seekBarPoint; // do nothing if either rect isn't available
    // for example, if the player isn't in the DOM for testing

    if (!playerRect || !tooltipRect) {
      return;
    } // This is the space left of the `seekBarPoint` available within the bounds
    // of the player. We calculate any gap between the left edge of the player
    // and the left edge of the `SeekBar` and add the number of pixels in the
    // `SeekBar` before hitting the `seekBarPoint`


    var spaceLeftOfPoint = seekBarRect.left - playerRect.left + seekBarPointPx; // This is the space right of the `seekBarPoint` available within the bounds
    // of the player. We calculate the number of pixels from the `seekBarPoint`
    // to the right edge of the `SeekBar` and add to that any gap between the
    // right edge of the `SeekBar` and the player.

    var spaceRightOfPoint = seekBarRect.width - seekBarPointPx + (playerRect.right - seekBarRect.right); // This is the number of pixels by which the tooltip will need to be pulled
    // further to the right to center it over the `seekBarPoint`.

    var pullTooltipBy = tooltipRect.width / 2; // Adjust the `pullTooltipBy` distance to the left or right depending on
    // the results of the space calculations above.

    if (spaceLeftOfPoint < pullTooltipBy) {
      pullTooltipBy += pullTooltipBy - spaceLeftOfPoint;
    } else if (spaceRightOfPoint < pullTooltipBy) {
      pullTooltipBy = spaceRightOfPoint;
    } // Due to the imprecision of decimal/ratio based calculations and varying
    // rounding behaviors, there are cases where the spacing adjustment is off
    // by a pixel or two. This adds insurance to these calculations.


    if (pullTooltipBy < 0) {
      pullTooltipBy = 0;
    } else if (pullTooltipBy > tooltipRect.width) {
      pullTooltipBy = tooltipRect.width;
    } // prevent small width fluctuations within 0.4px from
    // changing the value below.
    // This really helps for live to prevent the play
    // progress time tooltip from jittering


    pullTooltipBy = Math.round(pullTooltipBy);
    this.el_.style.right = "-" + pullTooltipBy + "px";
    this.write(content);
  }
  /**
   * Write the time to the tooltip DOM element.
   *
   * @param {string} content
   *        The formatted time for the tooltip.
   */
  ;

  _proto.write = function write(content) {
    textContent(this.el_, content);
  }
  /**
   * Updates the position of the time tooltip relative to the `SeekBar`.
   *
   * @param {Object} seekBarRect
   *        The `ClientRect` for the {@link SeekBar} element.
   *
   * @param {number} seekBarPoint
   *        A number from 0 to 1, representing a horizontal reference point
   *        from the left edge of the {@link SeekBar}
   *
   * @param {number} time
   *        The time to update the tooltip to, not used during live playback
   *
   * @param {Function} cb
   *        A function that will be called during the request animation frame
   *        for tooltips that need to do additional animations from the default
   */
  ;

  _proto.updateTime = function updateTime(seekBarRect, seekBarPoint, time, cb) {
    var _this2 = this;

    this.requestNamedAnimationFrame('TimeTooltip#updateTime', function () {
      var content;

      var duration = _this2.player_.duration();

      if (_this2.player_.liveTracker && _this2.player_.liveTracker.isLive()) {
        var liveWindow = _this2.player_.liveTracker.liveWindow();

        var secondsBehind = liveWindow - seekBarPoint * liveWindow;
        content = (secondsBehind < 1 ? '' : '-') + formatTime(secondsBehind, liveWindow);
      } else {
        content = formatTime(time, duration);
      }

      _this2.update(seekBarRect, seekBarPoint, content);

      if (cb) {
        cb();
      }
    });
  };

  return TimeTooltip;
}(Component);

Component.registerComponent('TimeTooltip', TimeTooltip);

/**
 * Used by {@link SeekBar} to display media playback progress as part of the
 * {@link ProgressControl}.
 *
 * @extends Component
 */

var PlayProgressBar = /*#__PURE__*/function (_Component) {
  _inheritsLoose__default['default'](PlayProgressBar, _Component);

  /**
   * Creates an instance of this class.
   *
   * @param {Player} player
   *        The {@link Player} that this class should be attached to.
   *
   * @param {Object} [options]
   *        The key/value store of player options.
   */
  function PlayProgressBar(player, options) {
    var _this;

    _this = _Component.call(this, player, options) || this;
    _this.update = throttle(bind(_assertThisInitialized__default['default'](_this), _this.update), UPDATE_REFRESH_INTERVAL);
    return _this;
  }
  /**
   * Create the the DOM element for this class.
   *
   * @return {Element}
   *         The element that was created.
   */


  var _proto = PlayProgressBar.prototype;

  _proto.createEl = function createEl() {
    return _Component.prototype.createEl.call(this, 'div', {
      className: 'vjs-play-progress vjs-slider-bar'
    }, {
      'aria-hidden': 'true'
    });
  }
  /**
   * Enqueues updates to its own DOM as well as the DOM of its
   * {@link TimeTooltip} child.
   *
   * @param {Object} seekBarRect
   *        The `ClientRect` for the {@link SeekBar} element.
   *
   * @param {number} seekBarPoint
   *        A number from 0 to 1, representing a horizontal reference point
   *        from the left edge of the {@link SeekBar}
   */
  ;

  _proto.update = function update(seekBarRect, seekBarPoint) {
    var timeTooltip = this.getChild('timeTooltip');

    if (!timeTooltip) {
      return;
    }

    var time = this.player_.scrubbing() ? this.player_.getCache().currentTime : this.player_.currentTime();
    timeTooltip.updateTime(seekBarRect, seekBarPoint, time);
  };

  return PlayProgressBar;
}(Component);
/**
 * Default options for {@link PlayProgressBar}.
 *
 * @type {Object}
 * @private
 */


PlayProgressBar.prototype.options_ = {
  children: []
}; // Time tooltips should not be added to a player on mobile devices

if (!IS_IOS && !IS_ANDROID) {
  PlayProgressBar.prototype.options_.children.push('timeTooltip');
}

Component.registerComponent('PlayProgressBar', PlayProgressBar);

/**
 * The {@link MouseTimeDisplay} component tracks mouse movement over the
 * {@link ProgressControl}. It displays an indicator and a {@link TimeTooltip}
 * indicating the time which is represented by a given point in the
 * {@link ProgressControl}.
 *
 * @extends Component
 */

var MouseTimeDisplay = /*#__PURE__*/function (_Component) {
  _inheritsLoose__default['default'](MouseTimeDisplay, _Component);

  /**
   * Creates an instance of this class.
   *
   * @param {Player} player
   *        The {@link Player} that this class should be attached to.
   *
   * @param {Object} [options]
   *        The key/value store of player options.
   */
  function MouseTimeDisplay(player, options) {
    var _this;

    _this = _Component.call(this, player, options) || this;
    _this.update = throttle(bind(_assertThisInitialized__default['default'](_this), _this.update), UPDATE_REFRESH_INTERVAL);
    return _this;
  }
  /**
   * Create the DOM element for this class.
   *
   * @return {Element}
   *         The element that was created.
   */


  var _proto = MouseTimeDisplay.prototype;

  _proto.createEl = function createEl() {
    return _Component.prototype.createEl.call(this, 'div', {
      className: 'vjs-mouse-display'
    });
  }
  /**
   * Enqueues updates to its own DOM as well as the DOM of its
   * {@link TimeTooltip} child.
   *
   * @param {Object} seekBarRect
   *        The `ClientRect` for the {@link SeekBar} element.
   *
   * @param {number} seekBarPoint
   *        A number from 0 to 1, representing a horizontal reference point
   *        from the left edge of the {@link SeekBar}
   */
  ;

  _proto.update = function update(seekBarRect, seekBarPoint) {
    var _this2 = this;

    var time = seekBarPoint * this.player_.duration();
    this.getChild('timeTooltip').updateTime(seekBarRect, seekBarPoint, time, function () {
      _this2.el_.style.left = seekBarRect.width * seekBarPoint + "px";
    });
  };

  return MouseTimeDisplay;
}(Component);
/**
 * Default options for `MouseTimeDisplay`
 *
 * @type {Object}
 * @private
 */


MouseTimeDisplay.prototype.options_ = {
  children: ['timeTooltip']
};
Component.registerComponent('MouseTimeDisplay', MouseTimeDisplay);

var STEP_SECONDS = 5; // The multiplier of STEP_SECONDS that PgUp/PgDown move the timeline.

var PAGE_KEY_MULTIPLIER = 12;
/**
 * Seek bar and container for the progress bars. Uses {@link PlayProgressBar}
 * as its `bar`.
 *
 * @extends Slider
 */

var SeekBar = /*#__PURE__*/function (_Slider) {
  _inheritsLoose__default['default'](SeekBar, _Slider);

  /**
   * Creates an instance of this class.
   *
   * @param {Player} player
   *        The `Player` that this class should be attached to.
   *
   * @param {Object} [options]
   *        The key/value store of player options.
   */
  function SeekBar(player, options) {
    var _this;

    _this = _Slider.call(this, player, options) || this;

    _this.setEventHandlers_();

    return _this;
  }
  /**
   * Sets the event handlers
   *
   * @private
   */


  var _proto = SeekBar.prototype;

  _proto.setEventHandlers_ = function setEventHandlers_() {
    var _this2 = this;

    this.update_ = bind(this, this.update);
    this.update = throttle(this.update_, UPDATE_REFRESH_INTERVAL);
    this.on(this.player_, ['ended', 'durationchange', 'timeupdate'], this.update);

    if (this.player_.liveTracker) {
      this.on(this.player_.liveTracker, 'liveedgechange', this.update);
    } // when playing, let's ensure we smoothly update the play progress bar
    // via an interval


    this.updateInterval = null;

    this.enableIntervalHandler_ = function (e) {
      return _this2.enableInterval_(e);
    };

    this.disableIntervalHandler_ = function (e) {
      return _this2.disableInterval_(e);
    };

    this.on(this.player_, ['playing'], this.enableIntervalHandler_);
    this.on(this.player_, ['ended', 'pause', 'waiting'], this.disableIntervalHandler_); // we don't need to update the play progress if the document is hidden,
    // also, this causes the CPU to spike and eventually crash the page on IE11.

    if ('hidden' in document__default['default'] && 'visibilityState' in document__default['default']) {
      this.on(document__default['default'], 'visibilitychange', this.toggleVisibility_);
    }
  };

  _proto.toggleVisibility_ = function toggleVisibility_(e) {
    if (document__default['default'].visibilityState === 'hidden') {
      this.cancelNamedAnimationFrame('SeekBar#update');
      this.cancelNamedAnimationFrame('Slider#update');
      this.disableInterval_(e);
    } else {
      if (!this.player_.ended() && !this.player_.paused()) {
        this.enableInterval_();
      } // we just switched back to the page and someone may be looking, so, update ASAP


      this.update();
    }
  };

  _proto.enableInterval_ = function enableInterval_() {
    if (this.updateInterval) {
      return;
    }

    this.updateInterval = this.setInterval(this.update, UPDATE_REFRESH_INTERVAL);
  };

  _proto.disableInterval_ = function disableInterval_(e) {
    if (this.player_.liveTracker && this.player_.liveTracker.isLive() && e && e.type !== 'ended') {
      return;
    }

    if (!this.updateInterval) {
      return;
    }

    this.clearInterval(this.updateInterval);
    this.updateInterval = null;
  }
  /**
   * Create the `Component`'s DOM element
   *
   * @return {Element}
   *         The element that was created.
   */
  ;

  _proto.createEl = function createEl() {
    return _Slider.prototype.createEl.call(this, 'div', {
      className: 'vjs-progress-holder'
    }, {
      'aria-label': this.localize('Progress Bar')
    });
  }
  /**
   * This function updates the play progress bar and accessibility
   * attributes to whatever is passed in.
   *
   * @param {EventTarget~Event} [event]
   *        The `timeupdate` or `ended` event that caused this to run.
   *
   * @listens Player#timeupdate
   *
   * @return {number}
   *          The current percent at a number from 0-1
   */
  ;

  _proto.update = function update(event) {
    var _this3 = this;

    // ignore updates while the tab is hidden
    if (document__default['default'].visibilityState === 'hidden') {
      return;
    }

    var percent = _Slider.prototype.update.call(this);

    this.requestNamedAnimationFrame('SeekBar#update', function () {
      var currentTime = _this3.player_.ended() ? _this3.player_.duration() : _this3.getCurrentTime_();
      var liveTracker = _this3.player_.liveTracker;

      var duration = _this3.player_.duration();

      if (liveTracker && liveTracker.isLive()) {
        duration = _this3.player_.liveTracker.liveCurrentTime();
      }

      if (_this3.percent_ !== percent) {
        // machine readable value of progress bar (percentage complete)
        _this3.el_.setAttribute('aria-valuenow', (percent * 100).toFixed(2));

        _this3.percent_ = percent;
      }

      if (_this3.currentTime_ !== currentTime || _this3.duration_ !== duration) {
        // human readable value of progress bar (time complete)
        _this3.el_.setAttribute('aria-valuetext', _this3.localize('progress bar timing: currentTime={1} duration={2}', [formatTime(currentTime, duration), formatTime(duration, duration)], '{1} of {2}'));

        _this3.currentTime_ = currentTime;
        _this3.duration_ = duration;
      } // update the progress bar time tooltip with the current time


      if (_this3.bar) {
        _this3.bar.update(getBoundingClientRect(_this3.el()), _this3.getProgress());
      }
    });
    return percent;
  }
  /**
   * Prevent liveThreshold from causing seeks to seem like they
   * are not happening from a user perspective.
   *
   * @param {number} ct
   *        current time to seek to
   */
  ;

  _proto.userSeek_ = function userSeek_(ct) {
    if (this.player_.liveTracker && this.player_.liveTracker.isLive()) {
      this.player_.liveTracker.nextSeekedFromUser();
    }

    this.player_.currentTime(ct);
  }
  /**
   * Get the value of current time but allows for smooth scrubbing,
   * when player can't keep up.
   *
   * @return {number}
   *         The current time value to display
   *
   * @private
   */
  ;

  _proto.getCurrentTime_ = function getCurrentTime_() {
    return this.player_.scrubbing() ? this.player_.getCache().currentTime : this.player_.currentTime();
  }
  /**
   * Get the percentage of media played so far.
   *
   * @return {number}
   *         The percentage of media played so far (0 to 1).
   */
  ;

  _proto.getPercent = function getPercent() {
    var currentTime = this.getCurrentTime_();
    var percent;
    var liveTracker = this.player_.liveTracker;

    if (liveTracker && liveTracker.isLive()) {
      percent = (currentTime - liveTracker.seekableStart()) / liveTracker.liveWindow(); // prevent the percent from changing at the live edge

      if (liveTracker.atLiveEdge()) {
        percent = 1;
      }
    } else {
      percent = currentTime / this.player_.duration();
    }

    return percent;
  }
  /**
   * Handle mouse down on seek bar
   *
   * @param {EventTarget~Event} event
   *        The `mousedown` event that caused this to run.
   *
   * @listens mousedown
   */
  ;

  _proto.handleMouseDown = function handleMouseDown(event) {
    if (!isSingleLeftClick(event)) {
      return;
    } // Stop event propagation to prevent double fire in progress-control.js


    event.stopPropagation();
    this.videoWasPlaying = !this.player_.paused();
    this.player_.pause();

    _Slider.prototype.handleMouseDown.call(this, event);
  }
  /**
   * Handle mouse move on seek bar
   *
   * @param {EventTarget~Event} event
   *        The `mousemove` event that caused this to run.
   * @param {boolean} mouseDown this is a flag that should be set to true if `handleMouseMove` is called directly. It allows us to skip things that should not happen if coming from mouse down but should happen on regular mouse move handler. Defaults to false
   *
   * @listens mousemove
   */
  ;

  _proto.handleMouseMove = function handleMouseMove(event, mouseDown) {
    if (mouseDown === void 0) {
      mouseDown = false;
    }

    if (!isSingleLeftClick(event)) {
      return;
    }

    if (!mouseDown && !this.player_.scrubbing()) {
      this.player_.scrubbing(true);
    }

    var newTime;
    var distance = this.calculateDistance(event);
    var liveTracker = this.player_.liveTracker;

    if (!liveTracker || !liveTracker.isLive()) {
      newTime = distance * this.player_.duration(); // Don't let video end while scrubbing.

      if (newTime === this.player_.duration()) {
        newTime = newTime - 0.1;
      }
    } else {
      if (distance >= 0.99) {
        liveTracker.seekToLiveEdge();
        return;
      }

      var seekableStart = liveTracker.seekableStart();
      var seekableEnd = liveTracker.liveCurrentTime();
      newTime = seekableStart + distance * liveTracker.liveWindow(); // Don't let video end while scrubbing.

      if (newTime >= seekableEnd) {
        newTime = seekableEnd;
      } // Compensate for precision differences so that currentTime is not less
      // than seekable start


      if (newTime <= seekableStart) {
        newTime = seekableStart + 0.1;
      } // On android seekableEnd can be Infinity sometimes,
      // this will cause newTime to be Infinity, which is
      // not a valid currentTime.


      if (newTime === Infinity) {
        return;
      }
    } // Set new time (tell player to seek to new time)


    this.userSeek_(newTime);
  };

  _proto.enable = function enable() {
    _Slider.prototype.enable.call(this);

    var mouseTimeDisplay = this.getChild('mouseTimeDisplay');

    if (!mouseTimeDisplay) {
      return;
    }

    mouseTimeDisplay.show();
  };

  _proto.disable = function disable() {
    _Slider.prototype.disable.call(this);

    var mouseTimeDisplay = this.getChild('mouseTimeDisplay');

    if (!mouseTimeDisplay) {
      return;
    }

    mouseTimeDisplay.hide();
  }
  /**
   * Handle mouse up on seek bar
   *
   * @param {EventTarget~Event} event
   *        The `mouseup` event that caused this to run.
   *
   * @listens mouseup
   */
  ;

  _proto.handleMouseUp = function handleMouseUp(event) {
    _Slider.prototype.handleMouseUp.call(this, event); // Stop event propagation to prevent double fire in progress-control.js


    if (event) {
      event.stopPropagation();
    }

    this.player_.scrubbing(false);
    /**
     * Trigger timeupdate because we're done seeking and the time has changed.
     * This is particularly useful for if the player is paused to time the time displays.
     *
     * @event Tech#timeupdate
     * @type {EventTarget~Event}
     */

    this.player_.trigger({
      type: 'timeupdate',
      target: this,
      manuallyTriggered: true
    });

    if (this.videoWasPlaying) {
      silencePromise(this.player_.play());
    } else {
      // We're done seeking and the time has changed.
      // If the player is paused, make sure we display the correct time on the seek bar.
      this.update_();
    }
  }
  /**
   * Move more quickly fast forward for keyboard-only users
   */
  ;

  _proto.stepForward = function stepForward() {
    this.userSeek_(this.player_.currentTime() + STEP_SECONDS);
  }
  /**
   * Move more quickly rewind for keyboard-only users
   */
  ;

  _proto.stepBack = function stepBack() {
    this.userSeek_(this.player_.currentTime() - STEP_SECONDS);
  }
  /**
   * Toggles the playback state of the player
   * This gets called when enter or space is used on the seekbar
   *
   * @param {EventTarget~Event} event
   *        The `keydown` event that caused this function to be called
   *
   */
  ;

  _proto.handleAction = function handleAction(event) {
    if (this.player_.paused()) {
      this.player_.play();
    } else {
      this.player_.pause();
    }
  }
  /**
   * Called when this SeekBar has focus and a key gets pressed down.
   * Supports the following keys:
   *
   *   Space or Enter key fire a click event
   *   Home key moves to start of the timeline
   *   End key moves to end of the timeline
   *   Digit "0" through "9" keys move to 0%, 10% ... 80%, 90% of the timeline
   *   PageDown key moves back a larger step than ArrowDown
   *   PageUp key moves forward a large step
   *
   * @param {EventTarget~Event} event
   *        The `keydown` event that caused this function to be called.
   *
   * @listens keydown
   */
  ;

  _proto.handleKeyDown = function handleKeyDown(event) {
    var liveTracker = this.player_.liveTracker;

    if (keycode__default['default'].isEventKey(event, 'Space') || keycode__default['default'].isEventKey(event, 'Enter')) {
      event.preventDefault();
      event.stopPropagation();
      this.handleAction(event);
    } else if (keycode__default['default'].isEventKey(event, 'Home')) {
      event.preventDefault();
      event.stopPropagation();
      this.userSeek_(0);
    } else if (keycode__default['default'].isEventKey(event, 'End')) {
      event.preventDefault();
      event.stopPropagation();

      if (liveTracker && liveTracker.isLive()) {
        this.userSeek_(liveTracker.liveCurrentTime());
      } else {
        this.userSeek_(this.player_.duration());
      }
    } else if (/^[0-9]$/.test(keycode__default['default'](event))) {
      event.preventDefault();
      event.stopPropagation();
      var gotoFraction = (keycode__default['default'].codes[keycode__default['default'](event)] - keycode__default['default'].codes['0']) * 10.0 / 100.0;

      if (liveTracker && liveTracker.isLive()) {
        this.userSeek_(liveTracker.seekableStart() + liveTracker.liveWindow() * gotoFraction);
      } else {
        this.userSeek_(this.player_.duration() * gotoFraction);
      }
    } else if (keycode__default['default'].isEventKey(event, 'PgDn')) {
      event.preventDefault();
      event.stopPropagation();
      this.userSeek_(this.player_.currentTime() - STEP_SECONDS * PAGE_KEY_MULTIPLIER);
    } else if (keycode__default['default'].isEventKey(event, 'PgUp')) {
      event.preventDefault();
      event.stopPropagation();
      this.userSeek_(this.player_.currentTime() + STEP_SECONDS * PAGE_KEY_MULTIPLIER);
    } else {
      // Pass keydown handling up for unsupported keys
      _Slider.prototype.handleKeyDown.call(this, event);
    }
  };

  _proto.dispose = function dispose() {
    this.disableInterval_();
    this.off(this.player_, ['ended', 'durationchange', 'timeupdate'], this.update);

    if (this.player_.liveTracker) {
      this.off(this.player_.liveTracker, 'liveedgechange', this.update);
    }

    this.off(this.player_, ['playing'], this.enableIntervalHandler_);
    this.off(this.player_, ['ended', 'pause', 'waiting'], this.disableIntervalHandler_); // we don't need to update the play progress if the document is hidden,
    // also, this causes the CPU to spike and eventually crash the page on IE11.

    if ('hidden' in document__default['default'] && 'visibilityState' in document__default['default']) {
      this.off(document__default['default'], 'visibilitychange', this.toggleVisibility_);
    }

    _Slider.prototype.dispose.call(this);
  };

  return SeekBar;
}(Slider);
/**
 * Default options for the `SeekBar`
 *
 * @type {Object}
 * @private
 */


SeekBar.prototype.options_ = {
  children: ['loadProgressBar', 'playProgressBar'],
  barName: 'playProgressBar'
}; // MouseTimeDisplay tooltips should not be added to a player on mobile devices

if (!IS_IOS && !IS_ANDROID) {
  SeekBar.prototype.options_.children.splice(1, 0, 'mouseTimeDisplay');
}

Component.registerComponent('SeekBar', SeekBar);

/**
 * The Progress Control component contains the seek bar, load progress,
 * and play progress.
 *
 * @extends Component
 */

var ProgressControl = /*#__PURE__*/function (_Component) {
  _inheritsLoose__default['default'](ProgressControl, _Component);

  /**
   * Creates an instance of this class.
   *
   * @param {Player} player
   *        The `Player` that this class should be attached to.
   *
   * @param {Object} [options]
   *        The key/value store of player options.
   */
  function ProgressControl(player, options) {
    var _this;

    _this = _Component.call(this, player, options) || this;
    _this.handleMouseMove = throttle(bind(_assertThisInitialized__default['default'](_this), _this.handleMouseMove), UPDATE_REFRESH_INTERVAL);
    _this.throttledHandleMouseSeek = throttle(bind(_assertThisInitialized__default['default'](_this), _this.handleMouseSeek), UPDATE_REFRESH_INTERVAL);

    _this.handleMouseUpHandler_ = function (e) {
      return _this.handleMouseUp(e);
    };

    _this.handleMouseDownHandler_ = function (e) {
      return _this.handleMouseDown(e);
    };

    _this.enable();

    return _this;
  }
  /**
   * Create the `Component`'s DOM element
   *
   * @return {Element}
   *         The element that was created.
   */


  var _proto = ProgressControl.prototype;

  _proto.createEl = function createEl() {
    return _Component.prototype.createEl.call(this, 'div', {
      className: 'vjs-progress-control vjs-control'
    });
  }
  /**
   * When the mouse moves over the `ProgressControl`, the pointer position
   * gets passed down to the `MouseTimeDisplay` component.
   *
   * @param {EventTarget~Event} event
   *        The `mousemove` event that caused this function to run.
   *
   * @listen mousemove
   */
  ;

  _proto.handleMouseMove = function handleMouseMove(event) {
    var seekBar = this.getChild('seekBar');

    if (!seekBar) {
      return;
    }

    var playProgressBar = seekBar.getChild('playProgressBar');
    var mouseTimeDisplay = seekBar.getChild('mouseTimeDisplay');

    if (!playProgressBar && !mouseTimeDisplay) {
      return;
    }

    var seekBarEl = seekBar.el();
    var seekBarRect = findPosition(seekBarEl);
    var seekBarPoint = getPointerPosition(seekBarEl, event).x; // The default skin has a gap on either side of the `SeekBar`. This means
    // that it's possible to trigger this behavior outside the boundaries of
    // the `SeekBar`. This ensures we stay within it at all times.

    seekBarPoint = clamp(seekBarPoint, 0, 1);

    if (mouseTimeDisplay) {
      mouseTimeDisplay.update(seekBarRect, seekBarPoint);
    }

    if (playProgressBar) {
      playProgressBar.update(seekBarRect, seekBar.getProgress());
    }
  }
  /**
   * A throttled version of the {@link ProgressControl#handleMouseSeek} listener.
   *
   * @method ProgressControl#throttledHandleMouseSeek
   * @param {EventTarget~Event} event
   *        The `mousemove` event that caused this function to run.
   *
   * @listen mousemove
   * @listen touchmove
   */

  /**
   * Handle `mousemove` or `touchmove` events on the `ProgressControl`.
   *
   * @param {EventTarget~Event} event
   *        `mousedown` or `touchstart` event that triggered this function
   *
   * @listens mousemove
   * @listens touchmove
   */
  ;

  _proto.handleMouseSeek = function handleMouseSeek(event) {
    var seekBar = this.getChild('seekBar');

    if (seekBar) {
      seekBar.handleMouseMove(event);
    }
  }
  /**
   * Are controls are currently enabled for this progress control.
   *
   * @return {boolean}
   *         true if controls are enabled, false otherwise
   */
  ;

  _proto.enabled = function enabled() {
    return this.enabled_;
  }
  /**
   * Disable all controls on the progress control and its children
   */
  ;

  _proto.disable = function disable() {
    this.children().forEach(function (child) {
      return child.disable && child.disable();
    });

    if (!this.enabled()) {
      return;
    }

    this.off(['mousedown', 'touchstart'], this.handleMouseDownHandler_);
    this.off(this.el_, 'mousemove', this.handleMouseMove);
    this.removeListenersAddedOnMousedownAndTouchstart();
    this.addClass('disabled');
    this.enabled_ = false; // Restore normal playback state if controls are disabled while scrubbing

    if (this.player_.scrubbing()) {
      var seekBar = this.getChild('seekBar');
      this.player_.scrubbing(false);

      if (seekBar.videoWasPlaying) {
        silencePromise(this.player_.play());
      }
    }
  }
  /**
   * Enable all controls on the progress control and its children
   */
  ;

  _proto.enable = function enable() {
    this.children().forEach(function (child) {
      return child.enable && child.enable();
    });

    if (this.enabled()) {
      return;
    }

    this.on(['mousedown', 'touchstart'], this.handleMouseDownHandler_);
    this.on(this.el_, 'mousemove', this.handleMouseMove);
    this.removeClass('disabled');
    this.enabled_ = true;
  }
  /**
   * Cleanup listeners after the user finishes interacting with the progress controls
   */
  ;

  _proto.removeListenersAddedOnMousedownAndTouchstart = function removeListenersAddedOnMousedownAndTouchstart() {
    var doc = this.el_.ownerDocument;
    this.off(doc, 'mousemove', this.throttledHandleMouseSeek);
    this.off(doc, 'touchmove', this.throttledHandleMouseSeek);
    this.off(doc, 'mouseup', this.handleMouseUpHandler_);
    this.off(doc, 'touchend', this.handleMouseUpHandler_);
  }
  /**
   * Handle `mousedown` or `touchstart` events on the `ProgressControl`.
   *
   * @param {EventTarget~Event} event
   *        `mousedown` or `touchstart` event that triggered this function
   *
   * @listens mousedown
   * @listens touchstart
   */
  ;

  _proto.handleMouseDown = function handleMouseDown(event) {
    var doc = this.el_.ownerDocument;
    var seekBar = this.getChild('seekBar');

    if (seekBar) {
      seekBar.handleMouseDown(event);
    }

    this.on(doc, 'mousemove', this.throttledHandleMouseSeek);
    this.on(doc, 'touchmove', this.throttledHandleMouseSeek);
    this.on(doc, 'mouseup', this.handleMouseUpHandler_);
    this.on(doc, 'touchend', this.handleMouseUpHandler_);
  }
  /**
   * Handle `mouseup` or `touchend` events on the `ProgressControl`.
   *
   * @param {EventTarget~Event} event
   *        `mouseup` or `touchend` event that triggered this function.
   *
   * @listens touchend
   * @listens mouseup
   */
  ;

  _proto.handleMouseUp = function handleMouseUp(event) {
    var seekBar = this.getChild('seekBar');

    if (seekBar) {
      seekBar.handleMouseUp(event);
    }

    this.removeListenersAddedOnMousedownAndTouchstart();
  };

  return ProgressControl;
}(Component);
/**
 * Default options for `ProgressControl`
 *
 * @type {Object}
 * @private
 */


ProgressControl.prototype.options_ = {
  children: ['seekBar']
};
Component.registerComponent('ProgressControl', ProgressControl);

/**
 * Toggle Picture-in-Picture mode
 *
 * @extends Button
 */

var PictureInPictureToggle = /*#__PURE__*/function (_Button) {
  _inheritsLoose__default['default'](PictureInPictureToggle, _Button);

  /**
   * Creates an instance of this class.
   *
   * @param {Player} player
   *        The `Player` that this class should be attached to.
   *
   * @param {Object} [options]
   *        The key/value store of player options.
   *
   * @listens Player#enterpictureinpicture
   * @listens Player#leavepictureinpicture
   */
  function PictureInPictureToggle(player, options) {
    var _this;

    _this = _Button.call(this, player, options) || this;

    _this.on(player, ['enterpictureinpicture', 'leavepictureinpicture'], function (e) {
      return _this.handlePictureInPictureChange(e);
    });

    _this.on(player, ['disablepictureinpicturechanged', 'loadedmetadata'], function (e) {
      return _this.handlePictureInPictureEnabledChange(e);
    }); // TODO: Deactivate button on player emptied event.


    _this.disable();

    return _this;
  }
  /**
   * Builds the default DOM `className`.
   *
   * @return {string}
   *         The DOM `className` for this object.
   */


  var _proto = PictureInPictureToggle.prototype;

  _proto.buildCSSClass = function buildCSSClass() {
    return "vjs-picture-in-picture-control " + _Button.prototype.buildCSSClass.call(this);
  }
  /**
   * Enables or disables button based on document.pictureInPictureEnabled property value
   * or on value returned by player.disablePictureInPicture() method.
   */
  ;

  _proto.handlePictureInPictureEnabledChange = function handlePictureInPictureEnabledChange() {
    if (document__default['default'].pictureInPictureEnabled && this.player_.disablePictureInPicture() === false) {
      this.enable();
    } else {
      this.disable();
    }
  }
  /**
   * Handles enterpictureinpicture and leavepictureinpicture on the player and change control text accordingly.
   *
   * @param {EventTarget~Event} [event]
   *        The {@link Player#enterpictureinpicture} or {@link Player#leavepictureinpicture} event that caused this function to be
   *        called.
   *
   * @listens Player#enterpictureinpicture
   * @listens Player#leavepictureinpicture
   */
  ;

  _proto.handlePictureInPictureChange = function handlePictureInPictureChange(event) {
    if (this.player_.isInPictureInPicture()) {
      this.controlText('Exit Picture-in-Picture');
    } else {
      this.controlText('Picture-in-Picture');
    }

    this.handlePictureInPictureEnabledChange();
  }
  /**
   * This gets called when an `PictureInPictureToggle` is "clicked". See
   * {@link ClickableComponent} for more detailed information on what a click can be.
   *
   * @param {EventTarget~Event} [event]
   *        The `keydown`, `tap`, or `click` event that caused this function to be
   *        called.
   *
   * @listens tap
   * @listens click
   */
  ;

  _proto.handleClick = function handleClick(event) {
    if (!this.player_.isInPictureInPicture()) {
      this.player_.requestPictureInPicture();
    } else {
      this.player_.exitPictureInPicture();
    }
  };

  return PictureInPictureToggle;
}(Button);
/**
 * The text that should display over the `PictureInPictureToggle`s controls. Added for localization.
 *
 * @type {string}
 * @private
 */


PictureInPictureToggle.prototype.controlText_ = 'Picture-in-Picture';
Component.registerComponent('PictureInPictureToggle', PictureInPictureToggle);

/**
 * Toggle fullscreen video
 *
 * @extends Button
 */

var FullscreenToggle = /*#__PURE__*/function (_Button) {
  _inheritsLoose__default['default'](FullscreenToggle, _Button);

  /**
   * Creates an instance of this class.
   *
   * @param {Player} player
   *        The `Player` that this class should be attached to.
   *
   * @param {Object} [options]
   *        The key/value store of player options.
   */
  function FullscreenToggle(player, options) {
    var _this;

    _this = _Button.call(this, player, options) || this;

    _this.on(player, 'fullscreenchange', function (e) {
      return _this.handleFullscreenChange(e);
    });

    if (document__default['default'][player.fsApi_.fullscreenEnabled] === false) {
      _this.disable();
    }

    return _this;
  }
  /**
   * Builds the default DOM `className`.
   *
   * @return {string}
   *         The DOM `className` for this object.
   */


  var _proto = FullscreenToggle.prototype;

  _proto.buildCSSClass = function buildCSSClass() {
    return "vjs-fullscreen-control " + _Button.prototype.buildCSSClass.call(this);
  }
  /**
   * Handles fullscreenchange on the player and change control text accordingly.
   *
   * @param {EventTarget~Event} [event]
   *        The {@link Player#fullscreenchange} event that caused this function to be
   *        called.
   *
   * @listens Player#fullscreenchange
   */
  ;

  _proto.handleFullscreenChange = function handleFullscreenChange(event) {
    if (this.player_.isFullscreen()) {
      this.controlText('Non-Fullscreen');
    } else {
      this.controlText('Fullscreen');
    }
  }
  /**
   * This gets called when an `FullscreenToggle` is "clicked". See
   * {@link ClickableComponent} for more detailed information on what a click can be.
   *
   * @param {EventTarget~Event} [event]
   *        The `keydown`, `tap`, or `click` event that caused this function to be
   *        called.
   *
   * @listens tap
   * @listens click
   */
  ;

  _proto.handleClick = function handleClick(event) {
    if (!this.player_.isFullscreen()) {
      this.player_.requestFullscreen();
    } else {
      this.player_.exitFullscreen();
    }
  };

  return FullscreenToggle;
}(Button);
/**
 * The text that should display over the `FullscreenToggle`s controls. Added for localization.
 *
 * @type {string}
 * @private
 */


FullscreenToggle.prototype.controlText_ = 'Fullscreen';
Component.registerComponent('FullscreenToggle', FullscreenToggle);

/**
 * Check if volume control is supported and if it isn't hide the
 * `Component` that was passed  using the `vjs-hidden` class.
 *
 * @param {Component} self
 *        The component that should be hidden if volume is unsupported
 *
 * @param {Player} player
 *        A reference to the player
 *
 * @private
 */
var checkVolumeSupport = function checkVolumeSupport(self, player) {
  // hide volume controls when they're not supported by the current tech
  if (player.tech_ && !player.tech_.featuresVolumeControl) {
    self.addClass('vjs-hidden');
  }

  self.on(player, 'loadstart', function () {
    if (!player.tech_.featuresVolumeControl) {
      self.addClass('vjs-hidden');
    } else {
      self.removeClass('vjs-hidden');
    }
  });
};

/**
 * Shows volume level
 *
 * @extends Component
 */

var VolumeLevel = /*#__PURE__*/function (_Component) {
  _inheritsLoose__default['default'](VolumeLevel, _Component);

  function VolumeLevel() {
    return _Component.apply(this, arguments) || this;
  }

  var _proto = VolumeLevel.prototype;

  /**
   * Create the `Component`'s DOM element
   *
   * @return {Element}
   *         The element that was created.
   */
  _proto.createEl = function createEl() {
    var el = _Component.prototype.createEl.call(this, 'div', {
      className: 'vjs-volume-level'
    });

    el.appendChild(_Component.prototype.createEl.call(this, 'span', {
      className: 'vjs-control-text'
    }));
    return el;
  };

  return VolumeLevel;
}(Component);

Component.registerComponent('VolumeLevel', VolumeLevel);

/**
 * Volume level tooltips display a volume above or side by side the volume bar.
 *
 * @extends Component
 */

var VolumeLevelTooltip = /*#__PURE__*/function (_Component) {
  _inheritsLoose__default['default'](VolumeLevelTooltip, _Component);

  /**
   * Creates an instance of this class.
   *
   * @param {Player} player
   *        The {@link Player} that this class should be attached to.
   *
   * @param {Object} [options]
   *        The key/value store of player options.
   */
  function VolumeLevelTooltip(player, options) {
    var _this;

    _this = _Component.call(this, player, options) || this;
    _this.update = throttle(bind(_assertThisInitialized__default['default'](_this), _this.update), UPDATE_REFRESH_INTERVAL);
    return _this;
  }
  /**
   * Create the volume tooltip DOM element
   *
   * @return {Element}
   *         The element that was created.
   */


  var _proto = VolumeLevelTooltip.prototype;

  _proto.createEl = function createEl() {
    return _Component.prototype.createEl.call(this, 'div', {
      className: 'vjs-volume-tooltip'
    }, {
      'aria-hidden': 'true'
    });
  }
  /**
   * Updates the position of the tooltip relative to the `VolumeBar` and
   * its content text.
   *
   * @param {Object} rangeBarRect
   *        The `ClientRect` for the {@link VolumeBar} element.
   *
   * @param {number} rangeBarPoint
   *        A number from 0 to 1, representing a horizontal/vertical reference point
   *        from the left edge of the {@link VolumeBar}
   *
   * @param {boolean} vertical
   *        Referees to the Volume control position
   *        in the control bar{@link VolumeControl}
   *
   */
  ;

  _proto.update = function update(rangeBarRect, rangeBarPoint, vertical, content) {
    if (!vertical) {
      var tooltipRect = getBoundingClientRect(this.el_);
      var playerRect = getBoundingClientRect(this.player_.el());
      var volumeBarPointPx = rangeBarRect.width * rangeBarPoint;

      if (!playerRect || !tooltipRect) {
        return;
      }

      var spaceLeftOfPoint = rangeBarRect.left - playerRect.left + volumeBarPointPx;
      var spaceRightOfPoint = rangeBarRect.width - volumeBarPointPx + (playerRect.right - rangeBarRect.right);
      var pullTooltipBy = tooltipRect.width / 2;

      if (spaceLeftOfPoint < pullTooltipBy) {
        pullTooltipBy += pullTooltipBy - spaceLeftOfPoint;
      } else if (spaceRightOfPoint < pullTooltipBy) {
        pullTooltipBy = spaceRightOfPoint;
      }

      if (pullTooltipBy < 0) {
        pullTooltipBy = 0;
      } else if (pullTooltipBy > tooltipRect.width) {
        pullTooltipBy = tooltipRect.width;
      }

      this.el_.style.right = "-" + pullTooltipBy + "px";
    }

    this.write(content + "%");
  }
  /**
   * Write the volume to the tooltip DOM element.
   *
   * @param {string} content
   *        The formatted volume for the tooltip.
   */
  ;

  _proto.write = function write(content) {
    textContent(this.el_, content);
  }
  /**
   * Updates the position of the volume tooltip relative to the `VolumeBar`.
   *
   * @param {Object} rangeBarRect
   *        The `ClientRect` for the {@link VolumeBar} element.
   *
   * @param {number} rangeBarPoint
   *        A number from 0 to 1, representing a horizontal/vertical reference point
   *        from the left edge of the {@link VolumeBar}
   *
   * @param {boolean} vertical
   *        Referees to the Volume control position
   *        in the control bar{@link VolumeControl}
   *
   * @param {number} volume
   *        The volume level to update the tooltip to
   *
   * @param {Function} cb
   *        A function that will be called during the request animation frame
   *        for tooltips that need to do additional animations from the default
   */
  ;

  _proto.updateVolume = function updateVolume(rangeBarRect, rangeBarPoint, vertical, volume, cb) {
    var _this2 = this;

    this.requestNamedAnimationFrame('VolumeLevelTooltip#updateVolume', function () {
      _this2.update(rangeBarRect, rangeBarPoint, vertical, volume.toFixed(0));

      if (cb) {
        cb();
      }
    });
  };

  return VolumeLevelTooltip;
}(Component);

Component.registerComponent('VolumeLevelTooltip', VolumeLevelTooltip);

/**
 * The {@link MouseVolumeLevelDisplay} component tracks mouse movement over the
 * {@link VolumeControl}. It displays an indicator and a {@link VolumeLevelTooltip}
 * indicating the volume level which is represented by a given point in the
 * {@link VolumeBar}.
 *
 * @extends Component
 */

var MouseVolumeLevelDisplay = /*#__PURE__*/function (_Component) {
  _inheritsLoose__default['default'](MouseVolumeLevelDisplay, _Component);

  /**
   * Creates an instance of this class.
   *
   * @param {Player} player
   *        The {@link Player} that this class should be attached to.
   *
   * @param {Object} [options]
   *        The key/value store of player options.
   */
  function MouseVolumeLevelDisplay(player, options) {
    var _this;

    _this = _Component.call(this, player, options) || this;
    _this.update = throttle(bind(_assertThisInitialized__default['default'](_this), _this.update), UPDATE_REFRESH_INTERVAL);
    return _this;
  }
  /**
   * Create the DOM element for this class.
   *
   * @return {Element}
   *         The element that was created.
   */


  var _proto = MouseVolumeLevelDisplay.prototype;

  _proto.createEl = function createEl() {
    return _Component.prototype.createEl.call(this, 'div', {
      className: 'vjs-mouse-display'
    });
  }
  /**
   * Enquires updates to its own DOM as well as the DOM of its
   * {@link VolumeLevelTooltip} child.
   *
   * @param {Object} rangeBarRect
   *        The `ClientRect` for the {@link VolumeBar} element.
   *
   * @param {number} rangeBarPoint
   *        A number from 0 to 1, representing a horizontal/vertical reference point
   *        from the left edge of the {@link VolumeBar}
   *
   * @param {boolean} vertical
   *        Referees to the Volume control position
   *        in the control bar{@link VolumeControl}
   *
   */
  ;

  _proto.update = function update(rangeBarRect, rangeBarPoint, vertical) {
    var _this2 = this;

    var volume = 100 * rangeBarPoint;
    this.getChild('volumeLevelTooltip').updateVolume(rangeBarRect, rangeBarPoint, vertical, volume, function () {
      if (vertical) {
        _this2.el_.style.bottom = rangeBarRect.height * rangeBarPoint + "px";
      } else {
        _this2.el_.style.left = rangeBarRect.width * rangeBarPoint + "px";
      }
    });
  };

  return MouseVolumeLevelDisplay;
}(Component);
/**
 * Default options for `MouseVolumeLevelDisplay`
 *
 * @type {Object}
 * @private
 */


MouseVolumeLevelDisplay.prototype.options_ = {
  children: ['volumeLevelTooltip']
};
Component.registerComponent('MouseVolumeLevelDisplay', MouseVolumeLevelDisplay);

/**
 * The bar that contains the volume level and can be clicked on to adjust the level
 *
 * @extends Slider
 */

var VolumeBar = /*#__PURE__*/function (_Slider) {
  _inheritsLoose__default['default'](VolumeBar, _Slider);

  /**
   * Creates an instance of this class.
   *
   * @param {Player} player
   *        The `Player` that this class should be attached to.
   *
   * @param {Object} [options]
   *        The key/value store of player options.
   */
  function VolumeBar(player, options) {
    var _this;

    _this = _Slider.call(this, player, options) || this;

    _this.on('slideractive', function (e) {
      return _this.updateLastVolume_(e);
    });

    _this.on(player, 'volumechange', function (e) {
      return _this.updateARIAAttributes(e);
    });

    player.ready(function () {
      return _this.updateARIAAttributes();
    });
    return _this;
  }
  /**
   * Create the `Component`'s DOM element
   *
   * @return {Element}
   *         The element that was created.
   */


  var _proto = VolumeBar.prototype;

  _proto.createEl = function createEl() {
    return _Slider.prototype.createEl.call(this, 'div', {
      className: 'vjs-volume-bar vjs-slider-bar'
    }, {
      'aria-label': this.localize('Volume Level'),
      'aria-live': 'polite'
    });
  }
  /**
   * Handle mouse down on volume bar
   *
   * @param {EventTarget~Event} event
   *        The `mousedown` event that caused this to run.
   *
   * @listens mousedown
   */
  ;

  _proto.handleMouseDown = function handleMouseDown(event) {
    if (!isSingleLeftClick(event)) {
      return;
    }

    _Slider.prototype.handleMouseDown.call(this, event);
  }
  /**
   * Handle movement events on the {@link VolumeMenuButton}.
   *
   * @param {EventTarget~Event} event
   *        The event that caused this function to run.
   *
   * @listens mousemove
   */
  ;

  _proto.handleMouseMove = function handleMouseMove(event) {
    var mouseVolumeLevelDisplay = this.getChild('mouseVolumeLevelDisplay');

    if (mouseVolumeLevelDisplay) {
      var volumeBarEl = this.el();
      var volumeBarRect = getBoundingClientRect(volumeBarEl);
      var vertical = this.vertical();
      var volumeBarPoint = getPointerPosition(volumeBarEl, event);
      volumeBarPoint = vertical ? volumeBarPoint.y : volumeBarPoint.x; // The default skin has a gap on either side of the `VolumeBar`. This means
      // that it's possible to trigger this behavior outside the boundaries of
      // the `VolumeBar`. This ensures we stay within it at all times.

      volumeBarPoint = clamp(volumeBarPoint, 0, 1);
      mouseVolumeLevelDisplay.update(volumeBarRect, volumeBarPoint, vertical);
    }

    if (!isSingleLeftClick(event)) {
      return;
    }

    this.checkMuted();
    this.player_.volume(this.calculateDistance(event));
  }
  /**
   * If the player is muted unmute it.
   */
  ;

  _proto.checkMuted = function checkMuted() {
    if (this.player_.muted()) {
      this.player_.muted(false);
    }
  }
  /**
   * Get percent of volume level
   *
   * @return {number}
   *         Volume level percent as a decimal number.
   */
  ;

  _proto.getPercent = function getPercent() {
    if (this.player_.muted()) {
      return 0;
    }

    return this.player_.volume();
  }
  /**
   * Increase volume level for keyboard users
   */
  ;

  _proto.stepForward = function stepForward() {
    this.checkMuted();
    this.player_.volume(this.player_.volume() + 0.1);
  }
  /**
   * Decrease volume level for keyboard users
   */
  ;

  _proto.stepBack = function stepBack() {
    this.checkMuted();
    this.player_.volume(this.player_.volume() - 0.1);
  }
  /**
   * Update ARIA accessibility attributes
   *
   * @param {EventTarget~Event} [event]
   *        The `volumechange` event that caused this function to run.
   *
   * @listens Player#volumechange
   */
  ;

  _proto.updateARIAAttributes = function updateARIAAttributes(event) {
    var ariaValue = this.player_.muted() ? 0 : this.volumeAsPercentage_();
    this.el_.setAttribute('aria-valuenow', ariaValue);
    this.el_.setAttribute('aria-valuetext', ariaValue + '%');
  }
  /**
   * Returns the current value of the player volume as a percentage
   *
   * @private
   */
  ;

  _proto.volumeAsPercentage_ = function volumeAsPercentage_() {
    return Math.round(this.player_.volume() * 100);
  }
  /**
   * When user starts dragging the VolumeBar, store the volume and listen for
   * the end of the drag. When the drag ends, if the volume was set to zero,
   * set lastVolume to the stored volume.
   *
   * @listens slideractive
   * @private
   */
  ;

  _proto.updateLastVolume_ = function updateLastVolume_() {
    var _this2 = this;

    var volumeBeforeDrag = this.player_.volume();
    this.one('sliderinactive', function () {
      if (_this2.player_.volume() === 0) {
        _this2.player_.lastVolume_(volumeBeforeDrag);
      }
    });
  };

  return VolumeBar;
}(Slider);
/**
 * Default options for the `VolumeBar`
 *
 * @type {Object}
 * @private
 */


VolumeBar.prototype.options_ = {
  children: ['volumeLevel'],
  barName: 'volumeLevel'
}; // MouseVolumeLevelDisplay tooltip should not be added to a player on mobile devices

if (!IS_IOS && !IS_ANDROID) {
  VolumeBar.prototype.options_.children.splice(0, 0, 'mouseVolumeLevelDisplay');
}
/**
 * Call the update event for this Slider when this event happens on the player.
 *
 * @type {string}
 */


VolumeBar.prototype.playerEvent = 'volumechange';
Component.registerComponent('VolumeBar', VolumeBar);

/**
 * The component for controlling the volume level
 *
 * @extends Component
 */

var VolumeControl = /*#__PURE__*/function (_Component) {
  _inheritsLoose__default['default'](VolumeControl, _Component);

  /**
   * Creates an instance of this class.
   *
   * @param {Player} player
   *        The `Player` that this class should be attached to.
   *
   * @param {Object} [options={}]
   *        The key/value store of player options.
   */
  function VolumeControl(player, options) {
    var _this;

    if (options === void 0) {
      options = {};
    }

    options.vertical = options.vertical || false; // Pass the vertical option down to the VolumeBar if
    // the VolumeBar is turned on.

    if (typeof options.volumeBar === 'undefined' || isPlain(options.volumeBar)) {
      options.volumeBar = options.volumeBar || {};
      options.volumeBar.vertical = options.vertical;
    }

    _this = _Component.call(this, player, options) || this; // hide this control if volume support is missing

    checkVolumeSupport(_assertThisInitialized__default['default'](_this), player);
    _this.throttledHandleMouseMove = throttle(bind(_assertThisInitialized__default['default'](_this), _this.handleMouseMove), UPDATE_REFRESH_INTERVAL);

    _this.handleMouseUpHandler_ = function (e) {
      return _this.handleMouseUp(e);
    };

    _this.on('mousedown', function (e) {
      return _this.handleMouseDown(e);
    });

    _this.on('touchstart', function (e) {
      return _this.handleMouseDown(e);
    });

    _this.on('mousemove', function (e) {
      return _this.handleMouseMove(e);
    }); // while the slider is active (the mouse has been pressed down and
    // is dragging) or in focus we do not want to hide the VolumeBar


    _this.on(_this.volumeBar, ['focus', 'slideractive'], function () {
      _this.volumeBar.addClass('vjs-slider-active');

      _this.addClass('vjs-slider-active');

      _this.trigger('slideractive');
    });

    _this.on(_this.volumeBar, ['blur', 'sliderinactive'], function () {
      _this.volumeBar.removeClass('vjs-slider-active');

      _this.removeClass('vjs-slider-active');

      _this.trigger('sliderinactive');
    });

    return _this;
  }
  /**
   * Create the `Component`'s DOM element
   *
   * @return {Element}
   *         The element that was created.
   */


  var _proto = VolumeControl.prototype;

  _proto.createEl = function createEl() {
    var orientationClass = 'vjs-volume-horizontal';

    if (this.options_.vertical) {
      orientationClass = 'vjs-volume-vertical';
    }

    return _Component.prototype.createEl.call(this, 'div', {
      className: "vjs-volume-control vjs-control " + orientationClass
    });
  }
  /**
   * Handle `mousedown` or `touchstart` events on the `VolumeControl`.
   *
   * @param {EventTarget~Event} event
   *        `mousedown` or `touchstart` event that triggered this function
   *
   * @listens mousedown
   * @listens touchstart
   */
  ;

  _proto.handleMouseDown = function handleMouseDown(event) {
    var doc = this.el_.ownerDocument;
    this.on(doc, 'mousemove', this.throttledHandleMouseMove);
    this.on(doc, 'touchmove', this.throttledHandleMouseMove);
    this.on(doc, 'mouseup', this.handleMouseUpHandler_);
    this.on(doc, 'touchend', this.handleMouseUpHandler_);
  }
  /**
   * Handle `mouseup` or `touchend` events on the `VolumeControl`.
   *
   * @param {EventTarget~Event} event
   *        `mouseup` or `touchend` event that triggered this function.
   *
   * @listens touchend
   * @listens mouseup
   */
  ;

  _proto.handleMouseUp = function handleMouseUp(event) {
    var doc = this.el_.ownerDocument;
    this.off(doc, 'mousemove', this.throttledHandleMouseMove);
    this.off(doc, 'touchmove', this.throttledHandleMouseMove);
    this.off(doc, 'mouseup', this.handleMouseUpHandler_);
    this.off(doc, 'touchend', this.handleMouseUpHandler_);
  }
  /**
   * Handle `mousedown` or `touchstart` events on the `VolumeControl`.
   *
   * @param {EventTarget~Event} event
   *        `mousedown` or `touchstart` event that triggered this function
   *
   * @listens mousedown
   * @listens touchstart
   */
  ;

  _proto.handleMouseMove = function handleMouseMove(event) {
    this.volumeBar.handleMouseMove(event);
  };

  return VolumeControl;
}(Component);
/**
 * Default options for the `VolumeControl`
 *
 * @type {Object}
 * @private
 */


VolumeControl.prototype.options_ = {
  children: ['volumeBar']
};
Component.registerComponent('VolumeControl', VolumeControl);

/**
 * Check if muting volume is supported and if it isn't hide the mute toggle
 * button.
 *
 * @param {Component} self
 *        A reference to the mute toggle button
 *
 * @param {Player} player
 *        A reference to the player
 *
 * @private
 */
var checkMuteSupport = function checkMuteSupport(self, player) {
  // hide mute toggle button if it's not supported by the current tech
  if (player.tech_ && !player.tech_.featuresMuteControl) {
    self.addClass('vjs-hidden');
  }

  self.on(player, 'loadstart', function () {
    if (!player.tech_.featuresMuteControl) {
      self.addClass('vjs-hidden');
    } else {
      self.removeClass('vjs-hidden');
    }
  });
};

/**
 * A button component for muting the audio.
 *
 * @extends Button
 */

var MuteToggle = /*#__PURE__*/function (_Button) {
  _inheritsLoose__default['default'](MuteToggle, _Button);

  /**
   * Creates an instance of this class.
   *
   * @param {Player} player
   *        The `Player` that this class should be attached to.
   *
   * @param {Object} [options]
   *        The key/value store of player options.
   */
  function MuteToggle(player, options) {
    var _this;

    _this = _Button.call(this, player, options) || this; // hide this control if volume support is missing

    checkMuteSupport(_assertThisInitialized__default['default'](_this), player);

    _this.on(player, ['loadstart', 'volumechange'], function (e) {
      return _this.update(e);
    });

    return _this;
  }
  /**
   * Builds the default DOM `className`.
   *
   * @return {string}
   *         The DOM `className` for this object.
   */


  var _proto = MuteToggle.prototype;

  _proto.buildCSSClass = function buildCSSClass() {
    return "vjs-mute-control " + _Button.prototype.buildCSSClass.call(this);
  }
  /**
   * This gets called when an `MuteToggle` is "clicked". See
   * {@link ClickableComponent} for more detailed information on what a click can be.
   *
   * @param {EventTarget~Event} [event]
   *        The `keydown`, `tap`, or `click` event that caused this function to be
   *        called.
   *
   * @listens tap
   * @listens click
   */
  ;

  _proto.handleClick = function handleClick(event) {
    var vol = this.player_.volume();
    var lastVolume = this.player_.lastVolume_();

    if (vol === 0) {
      var volumeToSet = lastVolume < 0.1 ? 0.1 : lastVolume;
      this.player_.volume(volumeToSet);
      this.player_.muted(false);
    } else {
      this.player_.muted(this.player_.muted() ? false : true);
    }
  }
  /**
   * Update the `MuteToggle` button based on the state of `volume` and `muted`
   * on the player.
   *
   * @param {EventTarget~Event} [event]
   *        The {@link Player#loadstart} event if this function was called
   *        through an event.
   *
   * @listens Player#loadstart
   * @listens Player#volumechange
   */
  ;

  _proto.update = function update(event) {
    this.updateIcon_();
    this.updateControlText_();
  }
  /**
   * Update the appearance of the `MuteToggle` icon.
   *
   * Possible states (given `level` variable below):
   * - 0: crossed out
   * - 1: zero bars of volume
   * - 2: one bar of volume
   * - 3: two bars of volume
   *
   * @private
   */
  ;

  _proto.updateIcon_ = function updateIcon_() {
    var vol = this.player_.volume();
    var level = 3; // in iOS when a player is loaded with muted attribute
    // and volume is changed with a native mute button
    // we want to make sure muted state is updated

    if (IS_IOS && this.player_.tech_ && this.player_.tech_.el_) {
      this.player_.muted(this.player_.tech_.el_.muted);
    }

    if (vol === 0 || this.player_.muted()) {
      level = 0;
    } else if (vol < 0.33) {
      level = 1;
    } else if (vol < 0.67) {
      level = 2;
    } // TODO improve muted icon classes


    for (var i = 0; i < 4; i++) {
      removeClass(this.el_, "vjs-vol-" + i);
    }

    addClass(this.el_, "vjs-vol-" + level);
  }
  /**
   * If `muted` has changed on the player, update the control text
   * (`title` attribute on `vjs-mute-control` element and content of
   * `vjs-control-text` element).
   *
   * @private
   */
  ;

  _proto.updateControlText_ = function updateControlText_() {
    var soundOff = this.player_.muted() || this.player_.volume() === 0;
    var text = soundOff ? 'Unmute' : 'Mute';

    if (this.controlText() !== text) {
      this.controlText(text);
    }
  };

  return MuteToggle;
}(Button);
/**
 * The text that should display over the `MuteToggle`s controls. Added for localization.
 *
 * @type {string}
 * @private
 */


MuteToggle.prototype.controlText_ = 'Mute';
Component.registerComponent('MuteToggle', MuteToggle);

/**
 * A Component to contain the MuteToggle and VolumeControl so that
 * they can work together.
 *
 * @extends Component
 */

var VolumePanel = /*#__PURE__*/function (_Component) {
  _inheritsLoose__default['default'](VolumePanel, _Component);

  /**
   * Creates an instance of this class.
   *
   * @param {Player} player
   *        The `Player` that this class should be attached to.
   *
   * @param {Object} [options={}]
   *        The key/value store of player options.
   */
  function VolumePanel(player, options) {
    var _this;

    if (options === void 0) {
      options = {};
    }

    if (typeof options.inline !== 'undefined') {
      options.inline = options.inline;
    } else {
      options.inline = true;
    } // pass the inline option down to the VolumeControl as vertical if
    // the VolumeControl is on.


    if (typeof options.volumeControl === 'undefined' || isPlain(options.volumeControl)) {
      options.volumeControl = options.volumeControl || {};
      options.volumeControl.vertical = !options.inline;
    }

    _this = _Component.call(this, player, options) || this; // this handler is used by mouse handler methods below

    _this.handleKeyPressHandler_ = function (e) {
      return _this.handleKeyPress(e);
    };

    _this.on(player, ['loadstart'], function (e) {
      return _this.volumePanelState_(e);
    });

    _this.on(_this.muteToggle, 'keyup', function (e) {
      return _this.handleKeyPress(e);
    });

    _this.on(_this.volumeControl, 'keyup', function (e) {
      return _this.handleVolumeControlKeyUp(e);
    });

    _this.on('keydown', function (e) {
      return _this.handleKeyPress(e);
    });

    _this.on('mouseover', function (e) {
      return _this.handleMouseOver(e);
    });

    _this.on('mouseout', function (e) {
      return _this.handleMouseOut(e);
    }); // while the slider is active (the mouse has been pressed down and
    // is dragging) we do not want to hide the VolumeBar


    _this.on(_this.volumeControl, ['slideractive'], _this.sliderActive_);

    _this.on(_this.volumeControl, ['sliderinactive'], _this.sliderInactive_);

    return _this;
  }
  /**
   * Add vjs-slider-active class to the VolumePanel
   *
   * @listens VolumeControl#slideractive
   * @private
   */


  var _proto = VolumePanel.prototype;

  _proto.sliderActive_ = function sliderActive_() {
    this.addClass('vjs-slider-active');
  }
  /**
   * Removes vjs-slider-active class to the VolumePanel
   *
   * @listens VolumeControl#sliderinactive
   * @private
   */
  ;

  _proto.sliderInactive_ = function sliderInactive_() {
    this.removeClass('vjs-slider-active');
  }
  /**
   * Adds vjs-hidden or vjs-mute-toggle-only to the VolumePanel
   * depending on MuteToggle and VolumeControl state
   *
   * @listens Player#loadstart
   * @private
   */
  ;

  _proto.volumePanelState_ = function volumePanelState_() {
    // hide volume panel if neither volume control or mute toggle
    // are displayed
    if (this.volumeControl.hasClass('vjs-hidden') && this.muteToggle.hasClass('vjs-hidden')) {
      this.addClass('vjs-hidden');
    } // if only mute toggle is visible we don't want
    // volume panel expanding when hovered or active


    if (this.volumeControl.hasClass('vjs-hidden') && !this.muteToggle.hasClass('vjs-hidden')) {
      this.addClass('vjs-mute-toggle-only');
    }
  }
  /**
   * Create the `Component`'s DOM element
   *
   * @return {Element}
   *         The element that was created.
   */
  ;

  _proto.createEl = function createEl() {
    var orientationClass = 'vjs-volume-panel-horizontal';

    if (!this.options_.inline) {
      orientationClass = 'vjs-volume-panel-vertical';
    }

    return _Component.prototype.createEl.call(this, 'div', {
      className: "vjs-volume-panel vjs-control " + orientationClass
    });
  }
  /**
   * Dispose of the `volume-panel` and all child components.
   */
  ;

  _proto.dispose = function dispose() {
    this.handleMouseOut();

    _Component.prototype.dispose.call(this);
  }
  /**
   * Handles `keyup` events on the `VolumeControl`, looking for ESC, which closes
   * the volume panel and sets focus on `MuteToggle`.
   *
   * @param {EventTarget~Event} event
   *        The `keyup` event that caused this function to be called.
   *
   * @listens keyup
   */
  ;

  _proto.handleVolumeControlKeyUp = function handleVolumeControlKeyUp(event) {
    if (keycode__default['default'].isEventKey(event, 'Esc')) {
      this.muteToggle.focus();
    }
  }
  /**
   * This gets called when a `VolumePanel` gains hover via a `mouseover` event.
   * Turns on listening for `mouseover` event. When they happen it
   * calls `this.handleMouseOver`.
   *
   * @param {EventTarget~Event} event
   *        The `mouseover` event that caused this function to be called.
   *
   * @listens mouseover
   */
  ;

  _proto.handleMouseOver = function handleMouseOver(event) {
    this.addClass('vjs-hover');
    on(document__default['default'], 'keyup', this.handleKeyPressHandler_);
  }
  /**
   * This gets called when a `VolumePanel` gains hover via a `mouseout` event.
   * Turns on listening for `mouseout` event. When they happen it
   * calls `this.handleMouseOut`.
   *
   * @param {EventTarget~Event} event
   *        The `mouseout` event that caused this function to be called.
   *
   * @listens mouseout
   */
  ;

  _proto.handleMouseOut = function handleMouseOut(event) {
    this.removeClass('vjs-hover');
    off(document__default['default'], 'keyup', this.handleKeyPressHandler_);
  }
  /**
   * Handles `keyup` event on the document or `keydown` event on the `VolumePanel`,
   * looking for ESC, which hides the `VolumeControl`.
   *
   * @param {EventTarget~Event} event
   *        The keypress that triggered this event.
   *
   * @listens keydown | keyup
   */
  ;

  _proto.handleKeyPress = function handleKeyPress(event) {
    if (keycode__default['default'].isEventKey(event, 'Esc')) {
      this.handleMouseOut();
    }
  };

  return VolumePanel;
}(Component);
/**
 * Default options for the `VolumeControl`
 *
 * @type {Object}
 * @private
 */


VolumePanel.prototype.options_ = {
  children: ['muteToggle', 'volumeControl']
};
Component.registerComponent('VolumePanel', VolumePanel);

/**
 * The Menu component is used to build popup menus, including subtitle and
 * captions selection menus.
 *
 * @extends Component
 */

var Menu = /*#__PURE__*/function (_Component) {
  _inheritsLoose__default['default'](Menu, _Component);

  /**
   * Create an instance of this class.
   *
   * @param {Player} player
   *        the player that this component should attach to
   *
   * @param {Object} [options]
   *        Object of option names and values
   *
   */
  function Menu(player, options) {
    var _this;

    _this = _Component.call(this, player, options) || this;

    if (options) {
      _this.menuButton_ = options.menuButton;
    }

    _this.focusedChild_ = -1;

    _this.on('keydown', function (e) {
      return _this.handleKeyDown(e);
    }); // All the menu item instances share the same blur handler provided by the menu container.


    _this.boundHandleBlur_ = function (e) {
      return _this.handleBlur(e);
    };

    _this.boundHandleTapClick_ = function (e) {
      return _this.handleTapClick(e);
    };

    return _this;
  }
  /**
   * Add event listeners to the {@link MenuItem}.
   *
   * @param {Object} component
   *        The instance of the `MenuItem` to add listeners to.
   *
   */


  var _proto = Menu.prototype;

  _proto.addEventListenerForItem = function addEventListenerForItem(component) {
    if (!(component instanceof Component)) {
      return;
    }

    this.on(component, 'blur', this.boundHandleBlur_);
    this.on(component, ['tap', 'click'], this.boundHandleTapClick_);
  }
  /**
   * Remove event listeners from the {@link MenuItem}.
   *
   * @param {Object} component
   *        The instance of the `MenuItem` to remove listeners.
   *
   */
  ;

  _proto.removeEventListenerForItem = function removeEventListenerForItem(component) {
    if (!(component instanceof Component)) {
      return;
    }

    this.off(component, 'blur', this.boundHandleBlur_);
    this.off(component, ['tap', 'click'], this.boundHandleTapClick_);
  }
  /**
   * This method will be called indirectly when the component has been added
   * before the component adds to the new menu instance by `addItem`.
   * In this case, the original menu instance will remove the component
   * by calling `removeChild`.
   *
   * @param {Object} component
   *        The instance of the `MenuItem`
   */
  ;

  _proto.removeChild = function removeChild(component) {
    if (typeof component === 'string') {
      component = this.getChild(component);
    }

    this.removeEventListenerForItem(component);

    _Component.prototype.removeChild.call(this, component);
  }
  /**
   * Add a {@link MenuItem} to the menu.
   *
   * @param {Object|string} component
   *        The name or instance of the `MenuItem` to add.
   *
   */
  ;

  _proto.addItem = function addItem(component) {
    var childComponent = this.addChild(component);

    if (childComponent) {
      this.addEventListenerForItem(childComponent);
    }
  }
  /**
   * Create the `Menu`s DOM element.
   *
   * @return {Element}
   *         the element that was created
   */
  ;

  _proto.createEl = function createEl$1() {
    var contentElType = this.options_.contentElType || 'ul';
    this.contentEl_ = createEl(contentElType, {
      className: 'vjs-menu-content'
    });
    this.contentEl_.setAttribute('role', 'menu');

    var el = _Component.prototype.createEl.call(this, 'div', {
      append: this.contentEl_,
      className: 'vjs-menu'
    });

    el.appendChild(this.contentEl_); // Prevent clicks from bubbling up. Needed for Menu Buttons,
    // where a click on the parent is significant

    on(el, 'click', function (event) {
      event.preventDefault();
      event.stopImmediatePropagation();
    });
    return el;
  };

  _proto.dispose = function dispose() {
    this.contentEl_ = null;
    this.boundHandleBlur_ = null;
    this.boundHandleTapClick_ = null;

    _Component.prototype.dispose.call(this);
  }
  /**
   * Called when a `MenuItem` loses focus.
   *
   * @param {EventTarget~Event} event
   *        The `blur` event that caused this function to be called.
   *
   * @listens blur
   */
  ;

  _proto.handleBlur = function handleBlur(event) {
    var relatedTarget = event.relatedTarget || document__default['default'].activeElement; // Close menu popup when a user clicks outside the menu

    if (!this.children().some(function (element) {
      return element.el() === relatedTarget;
    })) {
      var btn = this.menuButton_;

      if (btn && btn.buttonPressed_ && relatedTarget !== btn.el().firstChild) {
        btn.unpressButton();
      }
    }
  }
  /**
   * Called when a `MenuItem` gets clicked or tapped.
   *
   * @param {EventTarget~Event} event
   *        The `click` or `tap` event that caused this function to be called.
   *
   * @listens click,tap
   */
  ;

  _proto.handleTapClick = function handleTapClick(event) {
    // Unpress the associated MenuButton, and move focus back to it
    if (this.menuButton_) {
      this.menuButton_.unpressButton();
      var childComponents = this.children();

      if (!Array.isArray(childComponents)) {
        return;
      }

      var foundComponent = childComponents.filter(function (component) {
        return component.el() === event.target;
      })[0];

      if (!foundComponent) {
        return;
      } // don't focus menu button if item is a caption settings item
      // because focus will move elsewhere


      if (foundComponent.name() !== 'CaptionSettingsMenuItem') {
        this.menuButton_.focus();
      }
    }
  }
  /**
   * Handle a `keydown` event on this menu. This listener is added in the constructor.
   *
   * @param {EventTarget~Event} event
   *        A `keydown` event that happened on the menu.
   *
   * @listens keydown
   */
  ;

  _proto.handleKeyDown = function handleKeyDown(event) {
    // Left and Down Arrows
    if (keycode__default['default'].isEventKey(event, 'Left') || keycode__default['default'].isEventKey(event, 'Down')) {
      event.preventDefault();
      event.stopPropagation();
      this.stepForward(); // Up and Right Arrows
    } else if (keycode__default['default'].isEventKey(event, 'Right') || keycode__default['default'].isEventKey(event, 'Up')) {
      event.preventDefault();
      event.stopPropagation();
      this.stepBack();
    }
  }
  /**
   * Move to next (lower) menu item for keyboard users.
   */
  ;

  _proto.stepForward = function stepForward() {
    var stepChild = 0;

    if (this.focusedChild_ !== undefined) {
      stepChild = this.focusedChild_ + 1;
    }

    this.focus(stepChild);
  }
  /**
   * Move to previous (higher) menu item for keyboard users.
   */
  ;

  _proto.stepBack = function stepBack() {
    var stepChild = 0;

    if (this.focusedChild_ !== undefined) {
      stepChild = this.focusedChild_ - 1;
    }

    this.focus(stepChild);
  }
  /**
   * Set focus on a {@link MenuItem} in the `Menu`.
   *
   * @param {Object|string} [item=0]
   *        Index of child item set focus on.
   */
  ;

  _proto.focus = function focus(item) {
    if (item === void 0) {
      item = 0;
    }

    var children = this.children().slice();
    var haveTitle = children.length && children[0].hasClass('vjs-menu-title');

    if (haveTitle) {
      children.shift();
    }

    if (children.length > 0) {
      if (item < 0) {
        item = 0;
      } else if (item >= children.length) {
        item = children.length - 1;
      }

      this.focusedChild_ = item;
      children[item].el_.focus();
    }
  };

  return Menu;
}(Component);

Component.registerComponent('Menu', Menu);

/**
 * A `MenuButton` class for any popup {@link Menu}.
 *
 * @extends Component
 */

var MenuButton = /*#__PURE__*/function (_Component) {
  _inheritsLoose__default['default'](MenuButton, _Component);

  /**
   * Creates an instance of this class.
   *
   * @param {Player} player
   *        The `Player` that this class should be attached to.
   *
   * @param {Object} [options={}]
   *        The key/value store of player options.
   */
  function MenuButton(player, options) {
    var _this;

    if (options === void 0) {
      options = {};
    }

    _this = _Component.call(this, player, options) || this;
    _this.menuButton_ = new Button(player, options);

    _this.menuButton_.controlText(_this.controlText_);

    _this.menuButton_.el_.setAttribute('aria-haspopup', 'true'); // Add buildCSSClass values to the button, not the wrapper


    var buttonClass = Button.prototype.buildCSSClass();
    _this.menuButton_.el_.className = _this.buildCSSClass() + ' ' + buttonClass;

    _this.menuButton_.removeClass('vjs-control');

    _this.addChild(_this.menuButton_);

    _this.update();

    _this.enabled_ = true;

    var handleClick = function handleClick(e) {
      return _this.handleClick(e);
    };

    _this.handleMenuKeyUp_ = function (e) {
      return _this.handleMenuKeyUp(e);
    };

    _this.on(_this.menuButton_, 'tap', handleClick);

    _this.on(_this.menuButton_, 'click', handleClick);

    _this.on(_this.menuButton_, 'keydown', function (e) {
      return _this.handleKeyDown(e);
    });

    _this.on(_this.menuButton_, 'mouseenter', function () {
      _this.addClass('vjs-hover');

      _this.menu.show();

      on(document__default['default'], 'keyup', _this.handleMenuKeyUp_);
    });

    _this.on('mouseleave', function (e) {
      return _this.handleMouseLeave(e);
    });

    _this.on('keydown', function (e) {
      return _this.handleSubmenuKeyDown(e);
    });

    return _this;
  }
  /**
   * Update the menu based on the current state of its items.
   */


  var _proto = MenuButton.prototype;

  _proto.update = function update() {
    var menu = this.createMenu();

    if (this.menu) {
      this.menu.dispose();
      this.removeChild(this.menu);
    }

    this.menu = menu;
    this.addChild(menu);
    /**
     * Track the state of the menu button
     *
     * @type {Boolean}
     * @private
     */

    this.buttonPressed_ = false;
    this.menuButton_.el_.setAttribute('aria-expanded', 'false');

    if (this.items && this.items.length <= this.hideThreshold_) {
      this.hide();
    } else {
      this.show();
    }
  }
  /**
   * Create the menu and add all items to it.
   *
   * @return {Menu}
   *         The constructed menu
   */
  ;

  _proto.createMenu = function createMenu() {
    var menu = new Menu(this.player_, {
      menuButton: this
    });
    /**
     * Hide the menu if the number of items is less than or equal to this threshold. This defaults
     * to 0 and whenever we add items which can be hidden to the menu we'll increment it. We list
     * it here because every time we run `createMenu` we need to reset the value.
     *
     * @protected
     * @type {Number}
     */

    this.hideThreshold_ = 0; // Add a title list item to the top

    if (this.options_.title) {
      var titleEl = createEl('li', {
        className: 'vjs-menu-title',
        textContent: toTitleCase(this.options_.title),
        tabIndex: -1
      });
      var titleComponent = new Component(this.player_, {
        el: titleEl
      });
      menu.addItem(titleComponent);
    }

    this.items = this.createItems();

    if (this.items) {
      // Add menu items to the menu
      for (var i = 0; i < this.items.length; i++) {
        menu.addItem(this.items[i]);
      }
    }

    return menu;
  }
  /**
   * Create the list of menu items. Specific to each subclass.
   *
   * @abstract
   */
  ;

  _proto.createItems = function createItems() {}
  /**
   * Create the `MenuButtons`s DOM element.
   *
   * @return {Element}
   *         The element that gets created.
   */
  ;

  _proto.createEl = function createEl() {
    return _Component.prototype.createEl.call(this, 'div', {
      className: this.buildWrapperCSSClass()
    }, {});
  }
  /**
   * Allow sub components to stack CSS class names for the wrapper element
   *
   * @return {string}
   *         The constructed wrapper DOM `className`
   */
  ;

  _proto.buildWrapperCSSClass = function buildWrapperCSSClass() {
    var menuButtonClass = 'vjs-menu-button'; // If the inline option is passed, we want to use different styles altogether.

    if (this.options_.inline === true) {
      menuButtonClass += '-inline';
    } else {
      menuButtonClass += '-popup';
    } // TODO: Fix the CSS so that this isn't necessary


    var buttonClass = Button.prototype.buildCSSClass();
    return "vjs-menu-button " + menuButtonClass + " " + buttonClass + " " + _Component.prototype.buildCSSClass.call(this);
  }
  /**
   * Builds the default DOM `className`.
   *
   * @return {string}
   *         The DOM `className` for this object.
   */
  ;

  _proto.buildCSSClass = function buildCSSClass() {
    var menuButtonClass = 'vjs-menu-button'; // If the inline option is passed, we want to use different styles altogether.

    if (this.options_.inline === true) {
      menuButtonClass += '-inline';
    } else {
      menuButtonClass += '-popup';
    }

    return "vjs-menu-button " + menuButtonClass + " " + _Component.prototype.buildCSSClass.call(this);
  }
  /**
   * Get or set the localized control text that will be used for accessibility.
   *
   * > NOTE: This will come from the internal `menuButton_` element.
   *
   * @param {string} [text]
   *        Control text for element.
   *
   * @param {Element} [el=this.menuButton_.el()]
   *        Element to set the title on.
   *
   * @return {string}
   *         - The control text when getting
   */
  ;

  _proto.controlText = function controlText(text, el) {
    if (el === void 0) {
      el = this.menuButton_.el();
    }

    return this.menuButton_.controlText(text, el);
  }
  /**
   * Dispose of the `menu-button` and all child components.
   */
  ;

  _proto.dispose = function dispose() {
    this.handleMouseLeave();

    _Component.prototype.dispose.call(this);
  }
  /**
   * Handle a click on a `MenuButton`.
   * See {@link ClickableComponent#handleClick} for instances where this is called.
   *
   * @param {EventTarget~Event} event
   *        The `keydown`, `tap`, or `click` event that caused this function to be
   *        called.
   *
   * @listens tap
   * @listens click
   */
  ;

  _proto.handleClick = function handleClick(event) {
    if (this.buttonPressed_) {
      this.unpressButton();
    } else {
      this.pressButton();
    }
  }
  /**
   * Handle `mouseleave` for `MenuButton`.
   *
   * @param {EventTarget~Event} event
   *        The `mouseleave` event that caused this function to be called.
   *
   * @listens mouseleave
   */
  ;

  _proto.handleMouseLeave = function handleMouseLeave(event) {
    this.removeClass('vjs-hover');
    off(document__default['default'], 'keyup', this.handleMenuKeyUp_);
  }
  /**
   * Set the focus to the actual button, not to this element
   */
  ;

  _proto.focus = function focus() {
    this.menuButton_.focus();
  }
  /**
   * Remove the focus from the actual button, not this element
   */
  ;

  _proto.blur = function blur() {
    this.menuButton_.blur();
  }
  /**
   * Handle tab, escape, down arrow, and up arrow keys for `MenuButton`. See
   * {@link ClickableComponent#handleKeyDown} for instances where this is called.
   *
   * @param {EventTarget~Event} event
   *        The `keydown` event that caused this function to be called.
   *
   * @listens keydown
   */
  ;

  _proto.handleKeyDown = function handleKeyDown(event) {
    // Escape or Tab unpress the 'button'
    if (keycode__default['default'].isEventKey(event, 'Esc') || keycode__default['default'].isEventKey(event, 'Tab')) {
      if (this.buttonPressed_) {
        this.unpressButton();
      } // Don't preventDefault for Tab key - we still want to lose focus


      if (!keycode__default['default'].isEventKey(event, 'Tab')) {
        event.preventDefault(); // Set focus back to the menu button's button

        this.menuButton_.focus();
      } // Up Arrow or Down Arrow also 'press' the button to open the menu

    } else if (keycode__default['default'].isEventKey(event, 'Up') || keycode__default['default'].isEventKey(event, 'Down')) {
      if (!this.buttonPressed_) {
        event.preventDefault();
        this.pressButton();
      }
    }
  }
  /**
   * Handle a `keyup` event on a `MenuButton`. The listener for this is added in
   * the constructor.
   *
   * @param {EventTarget~Event} event
   *        Key press event
   *
   * @listens keyup
   */
  ;

  _proto.handleMenuKeyUp = function handleMenuKeyUp(event) {
    // Escape hides popup menu
    if (keycode__default['default'].isEventKey(event, 'Esc') || keycode__default['default'].isEventKey(event, 'Tab')) {
      this.removeClass('vjs-hover');
    }
  }
  /**
   * This method name now delegates to `handleSubmenuKeyDown`. This means
   * anyone calling `handleSubmenuKeyPress` will not see their method calls
   * stop working.
   *
   * @param {EventTarget~Event} event
   *        The event that caused this function to be called.
   */
  ;

  _proto.handleSubmenuKeyPress = function handleSubmenuKeyPress(event) {
    this.handleSubmenuKeyDown(event);
  }
  /**
   * Handle a `keydown` event on a sub-menu. The listener for this is added in
   * the constructor.
   *
   * @param {EventTarget~Event} event
   *        Key press event
   *
   * @listens keydown
   */
  ;

  _proto.handleSubmenuKeyDown = function handleSubmenuKeyDown(event) {
    // Escape or Tab unpress the 'button'
    if (keycode__default['default'].isEventKey(event, 'Esc') || keycode__default['default'].isEventKey(event, 'Tab')) {
      if (this.buttonPressed_) {
        this.unpressButton();
      } // Don't preventDefault for Tab key - we still want to lose focus


      if (!keycode__default['default'].isEventKey(event, 'Tab')) {
        event.preventDefault(); // Set focus back to the menu button's button

        this.menuButton_.focus();
      }
    }
  }
  /**
   * Put the current `MenuButton` into a pressed state.
   */
  ;

  _proto.pressButton = function pressButton() {
    if (this.enabled_) {
      this.buttonPressed_ = true;
      this.menu.show();
      this.menu.lockShowing();
      this.menuButton_.el_.setAttribute('aria-expanded', 'true'); // set the focus into the submenu, except on iOS where it is resulting in
      // undesired scrolling behavior when the player is in an iframe

      if (IS_IOS && isInFrame()) {
        // Return early so that the menu isn't focused
        return;
      }

      this.menu.focus();
    }
  }
  /**
   * Take the current `MenuButton` out of a pressed state.
   */
  ;

  _proto.unpressButton = function unpressButton() {
    if (this.enabled_) {
      this.buttonPressed_ = false;
      this.menu.unlockShowing();
      this.menu.hide();
      this.menuButton_.el_.setAttribute('aria-expanded', 'false');
    }
  }
  /**
   * Disable the `MenuButton`. Don't allow it to be clicked.
   */
  ;

  _proto.disable = function disable() {
    this.unpressButton();
    this.enabled_ = false;
    this.addClass('vjs-disabled');
    this.menuButton_.disable();
  }
  /**
   * Enable the `MenuButton`. Allow it to be clicked.
   */
  ;

  _proto.enable = function enable() {
    this.enabled_ = true;
    this.removeClass('vjs-disabled');
    this.menuButton_.enable();
  };

  return MenuButton;
}(Component);

Component.registerComponent('MenuButton', MenuButton);

/**
 * The base class for buttons that toggle specific  track types (e.g. subtitles).
 *
 * @extends MenuButton
 */

var TrackButton = /*#__PURE__*/function (_MenuButton) {
  _inheritsLoose__default['default'](TrackButton, _MenuButton);

  /**
   * Creates an instance of this class.
   *
   * @param {Player} player
   *        The `Player` that this class should be attached to.
   *
   * @param {Object} [options]
   *        The key/value store of player options.
   */
  function TrackButton(player, options) {
    var _this;

    var tracks = options.tracks;
    _this = _MenuButton.call(this, player, options) || this;

    if (_this.items.length <= 1) {
      _this.hide();
    }

    if (!tracks) {
      return _assertThisInitialized__default['default'](_this);
    }

    var updateHandler = bind(_assertThisInitialized__default['default'](_this), _this.update);
    tracks.addEventListener('removetrack', updateHandler);
    tracks.addEventListener('addtrack', updateHandler);
    tracks.addEventListener('labelchange', updateHandler);

    _this.player_.on('ready', updateHandler);

    _this.player_.on('dispose', function () {
      tracks.removeEventListener('removetrack', updateHandler);
      tracks.removeEventListener('addtrack', updateHandler);
      tracks.removeEventListener('labelchange', updateHandler);
    });

    return _this;
  }

  return TrackButton;
}(MenuButton);

Component.registerComponent('TrackButton', TrackButton);

/**
 * @file menu-keys.js
 */

/**
  * All keys used for operation of a menu (`MenuButton`, `Menu`, and `MenuItem`)
  * Note that 'Enter' and 'Space' are not included here (otherwise they would
  * prevent the `MenuButton` and `MenuItem` from being keyboard-clickable)
  * @typedef MenuKeys
  * @array
  */
var MenuKeys = ['Tab', 'Esc', 'Up', 'Down', 'Right', 'Left'];

/**
 * The component for a menu item. `<li>`
 *
 * @extends ClickableComponent
 */

var MenuItem = /*#__PURE__*/function (_ClickableComponent) {
  _inheritsLoose__default['default'](MenuItem, _ClickableComponent);

  /**
   * Creates an instance of the this class.
   *
   * @param {Player} player
   *        The `Player` that this class should be attached to.
   *
   * @param {Object} [options={}]
   *        The key/value store of player options.
   *
   */
  function MenuItem(player, options) {
    var _this;

    _this = _ClickableComponent.call(this, player, options) || this;
    _this.selectable = options.selectable;
    _this.isSelected_ = options.selected || false;
    _this.multiSelectable = options.multiSelectable;

    _this.selected(_this.isSelected_);

    if (_this.selectable) {
      if (_this.multiSelectable) {
        _this.el_.setAttribute('role', 'menuitemcheckbox');
      } else {
        _this.el_.setAttribute('role', 'menuitemradio');
      }
    } else {
      _this.el_.setAttribute('role', 'menuitem');
    }

    return _this;
  }
  /**
   * Create the `MenuItem's DOM element
   *
   * @param {string} [type=li]
   *        Element's node type, not actually used, always set to `li`.
   *
   * @param {Object} [props={}]
   *        An object of properties that should be set on the element
   *
   * @param {Object} [attrs={}]
   *        An object of attributes that should be set on the element
   *
   * @return {Element}
   *         The element that gets created.
   */


  var _proto = MenuItem.prototype;

  _proto.createEl = function createEl$1(type, props, attrs) {
    // The control is textual, not just an icon
    this.nonIconControl = true;

    var el = _ClickableComponent.prototype.createEl.call(this, 'li', assign({
      className: 'vjs-menu-item',
      tabIndex: -1
    }, props), attrs); // swap icon with menu item text.


    el.replaceChild(createEl('span', {
      className: 'vjs-menu-item-text',
      textContent: this.localize(this.options_.label)
    }), el.querySelector('.vjs-icon-placeholder'));
    return el;
  }
  /**
   * Ignore keys which are used by the menu, but pass any other ones up. See
   * {@link ClickableComponent#handleKeyDown} for instances where this is called.
   *
   * @param {EventTarget~Event} event
   *        The `keydown` event that caused this function to be called.
   *
   * @listens keydown
   */
  ;

  _proto.handleKeyDown = function handleKeyDown(event) {
    if (!MenuKeys.some(function (key) {
      return keycode__default['default'].isEventKey(event, key);
    })) {
      // Pass keydown handling up for unused keys
      _ClickableComponent.prototype.handleKeyDown.call(this, event);
    }
  }
  /**
   * Any click on a `MenuItem` puts it into the selected state.
   * See {@link ClickableComponent#handleClick} for instances where this is called.
   *
   * @param {EventTarget~Event} event
   *        The `keydown`, `tap`, or `click` event that caused this function to be
   *        called.
   *
   * @listens tap
   * @listens click
   */
  ;

  _proto.handleClick = function handleClick(event) {
    this.selected(true);
  }
  /**
   * Set the state for this menu item as selected or not.
   *
   * @param {boolean} selected
   *        if the menu item is selected or not
   */
  ;

  _proto.selected = function selected(_selected) {
    if (this.selectable) {
      if (_selected) {
        this.addClass('vjs-selected');
        this.el_.setAttribute('aria-checked', 'true'); // aria-checked isn't fully supported by browsers/screen readers,
        // so indicate selected state to screen reader in the control text.

        this.controlText(', selected');
        this.isSelected_ = true;
      } else {
        this.removeClass('vjs-selected');
        this.el_.setAttribute('aria-checked', 'false'); // Indicate un-selected state to screen reader

        this.controlText('');
        this.isSelected_ = false;
      }
    }
  };

  return MenuItem;
}(ClickableComponent);

Component.registerComponent('MenuItem', MenuItem);

/**
 * The specific menu item type for selecting a language within a text track kind
 *
 * @extends MenuItem
 */

var TextTrackMenuItem = /*#__PURE__*/function (_MenuItem) {
  _inheritsLoose__default['default'](TextTrackMenuItem, _MenuItem);

  /**
   * Creates an instance of this class.
   *
   * @param {Player} player
   *        The `Player` that this class should be attached to.
   *
   * @param {Object} [options]
   *        The key/value store of player options.
   */
  function TextTrackMenuItem(player, options) {
    var _this;

    var track = options.track;
    var tracks = player.textTracks(); // Modify options for parent MenuItem class's init.

    options.label = track.label || track.language || 'Unknown';
    options.selected = track.mode === 'showing';
    _this = _MenuItem.call(this, player, options) || this;
    _this.track = track; // Determine the relevant kind(s) of tracks for this component and filter
    // out empty kinds.

    _this.kinds = (options.kinds || [options.kind || _this.track.kind]).filter(Boolean);

    var changeHandler = function changeHandler() {
      for (var _len = arguments.length, args = new Array(_len), _key = 0; _key < _len; _key++) {
        args[_key] = arguments[_key];
      }

      _this.handleTracksChange.apply(_assertThisInitialized__default['default'](_this), args);
    };

    var selectedLanguageChangeHandler = function selectedLanguageChangeHandler() {
      for (var _len2 = arguments.length, args = new Array(_len2), _key2 = 0; _key2 < _len2; _key2++) {
        args[_key2] = arguments[_key2];
      }

      _this.handleSelectedLanguageChange.apply(_assertThisInitialized__default['default'](_this), args);
    };

    player.on(['loadstart', 'texttrackchange'], changeHandler);
    tracks.addEventListener('change', changeHandler);
    tracks.addEventListener('selectedlanguagechange', selectedLanguageChangeHandler);

    _this.on('dispose', function () {
      player.off(['loadstart', 'texttrackchange'], changeHandler);
      tracks.removeEventListener('change', changeHandler);
      tracks.removeEventListener('selectedlanguagechange', selectedLanguageChangeHandler);
    }); // iOS7 doesn't dispatch change events to TextTrackLists when an
    // associated track's mode changes. Without something like
    // Object.observe() (also not present on iOS7), it's not
    // possible to detect changes to the mode attribute and polyfill
    // the change event. As a poor substitute, we manually dispatch
    // change events whenever the controls modify the mode.


    if (tracks.onchange === undefined) {
      var event;

      _this.on(['tap', 'click'], function () {
        if (typeof window__default['default'].Event !== 'object') {
          // Android 2.3 throws an Illegal Constructor error for window.Event
          try {
            event = new window__default['default'].Event('change');
          } catch (err) {// continue regardless of error
          }
        }

        if (!event) {
          event = document__default['default'].createEvent('Event');
          event.initEvent('change', true, true);
        }

        tracks.dispatchEvent(event);
      });
    } // set the default state based on current tracks


    _this.handleTracksChange();

    return _this;
  }
  /**
   * This gets called when an `TextTrackMenuItem` is "clicked". See
   * {@link ClickableComponent} for more detailed information on what a click can be.
   *
   * @param {EventTarget~Event} event
   *        The `keydown`, `tap`, or `click` event that caused this function to be
   *        called.
   *
   * @listens tap
   * @listens click
   */


  var _proto = TextTrackMenuItem.prototype;

  _proto.handleClick = function handleClick(event) {
    var referenceTrack = this.track;
    var tracks = this.player_.textTracks();

    _MenuItem.prototype.handleClick.call(this, event);

    if (!tracks) {
      return;
    }

    for (var i = 0; i < tracks.length; i++) {
      var track = tracks[i]; // If the track from the text tracks list is not of the right kind,
      // skip it. We do not want to affect tracks of incompatible kind(s).

      if (this.kinds.indexOf(track.kind) === -1) {
        continue;
      } // If this text track is the component's track and it is not showing,
      // set it to showing.


      if (track === referenceTrack) {
        if (track.mode !== 'showing') {
          track.mode = 'showing';
        } // If this text track is not the component's track and it is not
        // disabled, set it to disabled.

      } else if (track.mode !== 'disabled') {
        track.mode = 'disabled';
      }
    }
  }
  /**
   * Handle text track list change
   *
   * @param {EventTarget~Event} event
   *        The `change` event that caused this function to be called.
   *
   * @listens TextTrackList#change
   */
  ;

  _proto.handleTracksChange = function handleTracksChange(event) {
    var shouldBeSelected = this.track.mode === 'showing'; // Prevent redundant selected() calls because they may cause
    // screen readers to read the appended control text unnecessarily

    if (shouldBeSelected !== this.isSelected_) {
      this.selected(shouldBeSelected);
    }
  };

  _proto.handleSelectedLanguageChange = function handleSelectedLanguageChange(event) {
    if (this.track.mode === 'showing') {
      var selectedLanguage = this.player_.cache_.selectedLanguage; // Don't replace the kind of track across the same language

      if (selectedLanguage && selectedLanguage.enabled && selectedLanguage.language === this.track.language && selectedLanguage.kind !== this.track.kind) {
        return;
      }

      this.player_.cache_.selectedLanguage = {
        enabled: true,
        language: this.track.language,
        kind: this.track.kind
      };
    }
  };

  _proto.dispose = function dispose() {
    // remove reference to track object on dispose
    this.track = null;

    _MenuItem.prototype.dispose.call(this);
  };

  return TextTrackMenuItem;
}(MenuItem);

Component.registerComponent('TextTrackMenuItem', TextTrackMenuItem);

/**
 * A special menu item for turning of a specific type of text track
 *
 * @extends TextTrackMenuItem
 */

var OffTextTrackMenuItem = /*#__PURE__*/function (_TextTrackMenuItem) {
  _inheritsLoose__default['default'](OffTextTrackMenuItem, _TextTrackMenuItem);

  /**
   * Creates an instance of this class.
   *
   * @param {Player} player
   *        The `Player` that this class should be attached to.
   *
   * @param {Object} [options]
   *        The key/value store of player options.
   */
  function OffTextTrackMenuItem(player, options) {
    // Create pseudo track info
    // Requires options['kind']
    options.track = {
      player: player,
      // it is no longer necessary to store `kind` or `kinds` on the track itself
      // since they are now stored in the `kinds` property of all instances of
      // TextTrackMenuItem, but this will remain for backwards compatibility
      kind: options.kind,
      kinds: options.kinds,
      "default": false,
      mode: 'disabled'
    };

    if (!options.kinds) {
      options.kinds = [options.kind];
    }

    if (options.label) {
      options.track.label = options.label;
    } else {
      options.track.label = options.kinds.join(' and ') + ' off';
    } // MenuItem is selectable


    options.selectable = true; // MenuItem is NOT multiSelectable (i.e. only one can be marked "selected" at a time)

    options.multiSelectable = false;
    return _TextTrackMenuItem.call(this, player, options) || this;
  }
  /**
   * Handle text track change
   *
   * @param {EventTarget~Event} event
   *        The event that caused this function to run
   */


  var _proto = OffTextTrackMenuItem.prototype;

  _proto.handleTracksChange = function handleTracksChange(event) {
    var tracks = this.player().textTracks();
    var shouldBeSelected = true;

    for (var i = 0, l = tracks.length; i < l; i++) {
      var track = tracks[i];

      if (this.options_.kinds.indexOf(track.kind) > -1 && track.mode === 'showing') {
        shouldBeSelected = false;
        break;
      }
    } // Prevent redundant selected() calls because they may cause
    // screen readers to read the appended control text unnecessarily


    if (shouldBeSelected !== this.isSelected_) {
      this.selected(shouldBeSelected);
    }
  };

  _proto.handleSelectedLanguageChange = function handleSelectedLanguageChange(event) {
    var tracks = this.player().textTracks();
    var allHidden = true;

    for (var i = 0, l = tracks.length; i < l; i++) {
      var track = tracks[i];

      if (['captions', 'descriptions', 'subtitles'].indexOf(track.kind) > -1 && track.mode === 'showing') {
        allHidden = false;
        break;
      }
    }

    if (allHidden) {
      this.player_.cache_.selectedLanguage = {
        enabled: false
      };
    }
  };

  return OffTextTrackMenuItem;
}(TextTrackMenuItem);

Component.registerComponent('OffTextTrackMenuItem', OffTextTrackMenuItem);

/**
 * The base class for buttons that toggle specific text track types (e.g. subtitles)
 *
 * @extends MenuButton
 */

var TextTrackButton = /*#__PURE__*/function (_TrackButton) {
  _inheritsLoose__default['default'](TextTrackButton, _TrackButton);

  /**
   * Creates an instance of this class.
   *
   * @param {Player} player
   *        The `Player` that this class should be attached to.
   *
   * @param {Object} [options={}]
   *        The key/value store of player options.
   */
  function TextTrackButton(player, options) {
    if (options === void 0) {
      options = {};
    }

    options.tracks = player.textTracks();
    return _TrackButton.call(this, player, options) || this;
  }
  /**
   * Create a menu item for each text track
   *
   * @param {TextTrackMenuItem[]} [items=[]]
   *        Existing array of items to use during creation
   *
   * @return {TextTrackMenuItem[]}
   *         Array of menu items that were created
   */


  var _proto = TextTrackButton.prototype;

  _proto.createItems = function createItems(items, TrackMenuItem) {
    if (items === void 0) {
      items = [];
    }

    if (TrackMenuItem === void 0) {
      TrackMenuItem = TextTrackMenuItem;
    }

    // Label is an override for the [track] off label
    // USed to localise captions/subtitles
    var label;

    if (this.label_) {
      label = this.label_ + " off";
    } // Add an OFF menu item to turn all tracks off


    items.push(new OffTextTrackMenuItem(this.player_, {
      kinds: this.kinds_,
      kind: this.kind_,
      label: label
    }));
    this.hideThreshold_ += 1;
    var tracks = this.player_.textTracks();

    if (!Array.isArray(this.kinds_)) {
      this.kinds_ = [this.kind_];
    }

    for (var i = 0; i < tracks.length; i++) {
      var track = tracks[i]; // only add tracks that are of an appropriate kind and have a label

      if (this.kinds_.indexOf(track.kind) > -1) {
        var item = new TrackMenuItem(this.player_, {
          track: track,
          kinds: this.kinds_,
          kind: this.kind_,
          // MenuItem is selectable
          selectable: true,
          // MenuItem is NOT multiSelectable (i.e. only one can be marked "selected" at a time)
          multiSelectable: false
        });
        item.addClass("vjs-" + track.kind + "-menu-item");
        items.push(item);
      }
    }

    return items;
  };

  return TextTrackButton;
}(TrackButton);

Component.registerComponent('TextTrackButton', TextTrackButton);

/**
 * The chapter track menu item
 *
 * @extends MenuItem
 */

var ChaptersTrackMenuItem = /*#__PURE__*/function (_MenuItem) {
  _inheritsLoose__default['default'](ChaptersTrackMenuItem, _MenuItem);

  /**
   * Creates an instance of this class.
   *
   * @param {Player} player
   *        The `Player` that this class should be attached to.
   *
   * @param {Object} [options]
   *        The key/value store of player options.
   */
  function ChaptersTrackMenuItem(player, options) {
    var _this;

    var track = options.track;
    var cue = options.cue;
    var currentTime = player.currentTime(); // Modify options for parent MenuItem class's init.

    options.selectable = true;
    options.multiSelectable = false;
    options.label = cue.text;
    options.selected = cue.startTime <= currentTime && currentTime < cue.endTime;
    _this = _MenuItem.call(this, player, options) || this;
    _this.track = track;
    _this.cue = cue;
    track.addEventListener('cuechange', bind(_assertThisInitialized__default['default'](_this), _this.update));
    return _this;
  }
  /**
   * This gets called when an `ChaptersTrackMenuItem` is "clicked". See
   * {@link ClickableComponent} for more detailed information on what a click can be.
   *
   * @param {EventTarget~Event} [event]
   *        The `keydown`, `tap`, or `click` event that caused this function to be
   *        called.
   *
   * @listens tap
   * @listens click
   */


  var _proto = ChaptersTrackMenuItem.prototype;

  _proto.handleClick = function handleClick(event) {
    _MenuItem.prototype.handleClick.call(this);

    this.player_.currentTime(this.cue.startTime);
    this.update(this.cue.startTime);
  }
  /**
   * Update chapter menu item
   *
   * @param {EventTarget~Event} [event]
   *        The `cuechange` event that caused this function to run.
   *
   * @listens TextTrack#cuechange
   */
  ;

  _proto.update = function update(event) {
    var cue = this.cue;
    var currentTime = this.player_.currentTime(); // vjs.log(currentTime, cue.startTime);

    this.selected(cue.startTime <= currentTime && currentTime < cue.endTime);
  };

  return ChaptersTrackMenuItem;
}(MenuItem);

Component.registerComponent('ChaptersTrackMenuItem', ChaptersTrackMenuItem);

/**
 * The button component for toggling and selecting chapters
 * Chapters act much differently than other text tracks
 * Cues are navigation vs. other tracks of alternative languages
 *
 * @extends TextTrackButton
 */

var ChaptersButton = /*#__PURE__*/function (_TextTrackButton) {
  _inheritsLoose__default['default'](ChaptersButton, _TextTrackButton);

  /**
   * Creates an instance of this class.
   *
   * @param {Player} player
   *        The `Player` that this class should be attached to.
   *
   * @param {Object} [options]
   *        The key/value store of player options.
   *
   * @param {Component~ReadyCallback} [ready]
   *        The function to call when this function is ready.
   */
  function ChaptersButton(player, options, ready) {
    return _TextTrackButton.call(this, player, options, ready) || this;
  }
  /**
   * Builds the default DOM `className`.
   *
   * @return {string}
   *         The DOM `className` for this object.
   */


  var _proto = ChaptersButton.prototype;

  _proto.buildCSSClass = function buildCSSClass() {
    return "vjs-chapters-button " + _TextTrackButton.prototype.buildCSSClass.call(this);
  };

  _proto.buildWrapperCSSClass = function buildWrapperCSSClass() {
    return "vjs-chapters-button " + _TextTrackButton.prototype.buildWrapperCSSClass.call(this);
  }
  /**
   * Update the menu based on the current state of its items.
   *
   * @param {EventTarget~Event} [event]
   *        An event that triggered this function to run.
   *
   * @listens TextTrackList#addtrack
   * @listens TextTrackList#removetrack
   * @listens TextTrackList#change
   */
  ;

  _proto.update = function update(event) {
    if (!this.track_ || event && (event.type === 'addtrack' || event.type === 'removetrack')) {
      this.setTrack(this.findChaptersTrack());
    }

    _TextTrackButton.prototype.update.call(this);
  }
  /**
   * Set the currently selected track for the chapters button.
   *
   * @param {TextTrack} track
   *        The new track to select. Nothing will change if this is the currently selected
   *        track.
   */
  ;

  _proto.setTrack = function setTrack(track) {
    if (this.track_ === track) {
      return;
    }

    if (!this.updateHandler_) {
      this.updateHandler_ = this.update.bind(this);
    } // here this.track_ refers to the old track instance


    if (this.track_) {
      var remoteTextTrackEl = this.player_.remoteTextTrackEls().getTrackElementByTrack_(this.track_);

      if (remoteTextTrackEl) {
        remoteTextTrackEl.removeEventListener('load', this.updateHandler_);
      }

      this.track_ = null;
    }

    this.track_ = track; // here this.track_ refers to the new track instance

    if (this.track_) {
      this.track_.mode = 'hidden';

      var _remoteTextTrackEl = this.player_.remoteTextTrackEls().getTrackElementByTrack_(this.track_);

      if (_remoteTextTrackEl) {
        _remoteTextTrackEl.addEventListener('load', this.updateHandler_);
      }
    }
  }
  /**
   * Find the track object that is currently in use by this ChaptersButton
   *
   * @return {TextTrack|undefined}
   *         The current track or undefined if none was found.
   */
  ;

  _proto.findChaptersTrack = function findChaptersTrack() {
    var tracks = this.player_.textTracks() || [];

    for (var i = tracks.length - 1; i >= 0; i--) {
      // We will always choose the last track as our chaptersTrack
      var track = tracks[i];

      if (track.kind === this.kind_) {
        return track;
      }
    }
  }
  /**
   * Get the caption for the ChaptersButton based on the track label. This will also
   * use the current tracks localized kind as a fallback if a label does not exist.
   *
   * @return {string}
   *         The tracks current label or the localized track kind.
   */
  ;

  _proto.getMenuCaption = function getMenuCaption() {
    if (this.track_ && this.track_.label) {
      return this.track_.label;
    }

    return this.localize(toTitleCase(this.kind_));
  }
  /**
   * Create menu from chapter track
   *
   * @return {Menu}
   *         New menu for the chapter buttons
   */
  ;

  _proto.createMenu = function createMenu() {
    this.options_.title = this.getMenuCaption();
    return _TextTrackButton.prototype.createMenu.call(this);
  }
  /**
   * Create a menu item for each text track
   *
   * @return {TextTrackMenuItem[]}
   *         Array of menu items
   */
  ;

  _proto.createItems = function createItems() {
    var items = [];

    if (!this.track_) {
      return items;
    }

    var cues = this.track_.cues;

    if (!cues) {
      return items;
    }

    for (var i = 0, l = cues.length; i < l; i++) {
      var cue = cues[i];
      var mi = new ChaptersTrackMenuItem(this.player_, {
        track: this.track_,
        cue: cue
      });
      items.push(mi);
    }

    return items;
  };

  return ChaptersButton;
}(TextTrackButton);
/**
 * `kind` of TextTrack to look for to associate it with this menu.
 *
 * @type {string}
 * @private
 */


ChaptersButton.prototype.kind_ = 'chapters';
/**
 * The text that should display over the `ChaptersButton`s controls. Added for localization.
 *
 * @type {string}
 * @private
 */

ChaptersButton.prototype.controlText_ = 'Chapters';
Component.registerComponent('ChaptersButton', ChaptersButton);

/**
 * The button component for toggling and selecting descriptions
 *
 * @extends TextTrackButton
 */

var DescriptionsButton = /*#__PURE__*/function (_TextTrackButton) {
  _inheritsLoose__default['default'](DescriptionsButton, _TextTrackButton);

  /**
   * Creates an instance of this class.
   *
   * @param {Player} player
   *        The `Player` that this class should be attached to.
   *
   * @param {Object} [options]
   *        The key/value store of player options.
   *
   * @param {Component~ReadyCallback} [ready]
   *        The function to call when this component is ready.
   */
  function DescriptionsButton(player, options, ready) {
    var _this;

    _this = _TextTrackButton.call(this, player, options, ready) || this;
    var tracks = player.textTracks();
    var changeHandler = bind(_assertThisInitialized__default['default'](_this), _this.handleTracksChange);
    tracks.addEventListener('change', changeHandler);

    _this.on('dispose', function () {
      tracks.removeEventListener('change', changeHandler);
    });

    return _this;
  }
  /**
   * Handle text track change
   *
   * @param {EventTarget~Event} event
   *        The event that caused this function to run
   *
   * @listens TextTrackList#change
   */


  var _proto = DescriptionsButton.prototype;

  _proto.handleTracksChange = function handleTracksChange(event) {
    var tracks = this.player().textTracks();
    var disabled = false; // Check whether a track of a different kind is showing

    for (var i = 0, l = tracks.length; i < l; i++) {
      var track = tracks[i];

      if (track.kind !== this.kind_ && track.mode === 'showing') {
        disabled = true;
        break;
      }
    } // If another track is showing, disable this menu button


    if (disabled) {
      this.disable();
    } else {
      this.enable();
    }
  }
  /**
   * Builds the default DOM `className`.
   *
   * @return {string}
   *         The DOM `className` for this object.
   */
  ;

  _proto.buildCSSClass = function buildCSSClass() {
    return "vjs-descriptions-button " + _TextTrackButton.prototype.buildCSSClass.call(this);
  };

  _proto.buildWrapperCSSClass = function buildWrapperCSSClass() {
    return "vjs-descriptions-button " + _TextTrackButton.prototype.buildWrapperCSSClass.call(this);
  };

  return DescriptionsButton;
}(TextTrackButton);
/**
 * `kind` of TextTrack to look for to associate it with this menu.
 *
 * @type {string}
 * @private
 */


DescriptionsButton.prototype.kind_ = 'descriptions';
/**
 * The text that should display over the `DescriptionsButton`s controls. Added for localization.
 *
 * @type {string}
 * @private
 */

DescriptionsButton.prototype.controlText_ = 'Descriptions';
Component.registerComponent('DescriptionsButton', DescriptionsButton);

/**
 * The button component for toggling and selecting subtitles
 *
 * @extends TextTrackButton
 */

var SubtitlesButton = /*#__PURE__*/function (_TextTrackButton) {
  _inheritsLoose__default['default'](SubtitlesButton, _TextTrackButton);

  /**
   * Creates an instance of this class.
   *
   * @param {Player} player
   *        The `Player` that this class should be attached to.
   *
   * @param {Object} [options]
   *        The key/value store of player options.
   *
   * @param {Component~ReadyCallback} [ready]
   *        The function to call when this component is ready.
   */
  function SubtitlesButton(player, options, ready) {
    return _TextTrackButton.call(this, player, options, ready) || this;
  }
  /**
   * Builds the default DOM `className`.
   *
   * @return {string}
   *         The DOM `className` for this object.
   */


  var _proto = SubtitlesButton.prototype;

  _proto.buildCSSClass = function buildCSSClass() {
    return "vjs-subtitles-button " + _TextTrackButton.prototype.buildCSSClass.call(this);
  };

  _proto.buildWrapperCSSClass = function buildWrapperCSSClass() {
    return "vjs-subtitles-button " + _TextTrackButton.prototype.buildWrapperCSSClass.call(this);
  };

  return SubtitlesButton;
}(TextTrackButton);
/**
 * `kind` of TextTrack to look for to associate it with this menu.
 *
 * @type {string}
 * @private
 */


SubtitlesButton.prototype.kind_ = 'subtitles';
/**
 * The text that should display over the `SubtitlesButton`s controls. Added for localization.
 *
 * @type {string}
 * @private
 */

SubtitlesButton.prototype.controlText_ = 'Subtitles';
Component.registerComponent('SubtitlesButton', SubtitlesButton);

/**
 * The menu item for caption track settings menu
 *
 * @extends TextTrackMenuItem
 */

var CaptionSettingsMenuItem = /*#__PURE__*/function (_TextTrackMenuItem) {
  _inheritsLoose__default['default'](CaptionSettingsMenuItem, _TextTrackMenuItem);

  /**
   * Creates an instance of this class.
   *
   * @param {Player} player
   *        The `Player` that this class should be attached to.
   *
   * @param {Object} [options]
   *        The key/value store of player options.
   */
  function CaptionSettingsMenuItem(player, options) {
    var _this;

    options.track = {
      player: player,
      kind: options.kind,
      label: options.kind + ' settings',
      selectable: false,
      "default": false,
      mode: 'disabled'
    }; // CaptionSettingsMenuItem has no concept of 'selected'

    options.selectable = false;
    options.name = 'CaptionSettingsMenuItem';
    _this = _TextTrackMenuItem.call(this, player, options) || this;

    _this.addClass('vjs-texttrack-settings');

    _this.controlText(', opens ' + options.kind + ' settings dialog');

    return _this;
  }
  /**
   * This gets called when an `CaptionSettingsMenuItem` is "clicked". See
   * {@link ClickableComponent} for more detailed information on what a click can be.
   *
   * @param {EventTarget~Event} [event]
   *        The `keydown`, `tap`, or `click` event that caused this function to be
   *        called.
   *
   * @listens tap
   * @listens click
   */


  var _proto = CaptionSettingsMenuItem.prototype;

  _proto.handleClick = function handleClick(event) {
    this.player().getChild('textTrackSettings').open();
  };

  return CaptionSettingsMenuItem;
}(TextTrackMenuItem);

Component.registerComponent('CaptionSettingsMenuItem', CaptionSettingsMenuItem);

/**
 * The button component for toggling and selecting captions
 *
 * @extends TextTrackButton
 */

var CaptionsButton = /*#__PURE__*/function (_TextTrackButton) {
  _inheritsLoose__default['default'](CaptionsButton, _TextTrackButton);

  /**
   * Creates an instance of this class.
   *
   * @param {Player} player
   *        The `Player` that this class should be attached to.
   *
   * @param {Object} [options]
   *        The key/value store of player options.
   *
   * @param {Component~ReadyCallback} [ready]
   *        The function to call when this component is ready.
   */
  function CaptionsButton(player, options, ready) {
    return _TextTrackButton.call(this, player, options, ready) || this;
  }
  /**
   * Builds the default DOM `className`.
   *
   * @return {string}
   *         The DOM `className` for this object.
   */


  var _proto = CaptionsButton.prototype;

  _proto.buildCSSClass = function buildCSSClass() {
    return "vjs-captions-button " + _TextTrackButton.prototype.buildCSSClass.call(this);
  };

  _proto.buildWrapperCSSClass = function buildWrapperCSSClass() {
    return "vjs-captions-button " + _TextTrackButton.prototype.buildWrapperCSSClass.call(this);
  }
  /**
   * Create caption menu items
   *
   * @return {CaptionSettingsMenuItem[]}
   *         The array of current menu items.
   */
  ;

  _proto.createItems = function createItems() {
    var items = [];

    if (!(this.player().tech_ && this.player().tech_.featuresNativeTextTracks) && this.player().getChild('textTrackSettings')) {
      items.push(new CaptionSettingsMenuItem(this.player_, {
        kind: this.kind_
      }));
      this.hideThreshold_ += 1;
    }

    return _TextTrackButton.prototype.createItems.call(this, items);
  };

  return CaptionsButton;
}(TextTrackButton);
/**
 * `kind` of TextTrack to look for to associate it with this menu.
 *
 * @type {string}
 * @private
 */


CaptionsButton.prototype.kind_ = 'captions';
/**
 * The text that should display over the `CaptionsButton`s controls. Added for localization.
 *
 * @type {string}
 * @private
 */

CaptionsButton.prototype.controlText_ = 'Captions';
Component.registerComponent('CaptionsButton', CaptionsButton);

/**
 * SubsCapsMenuItem has an [cc] icon to distinguish captions from subtitles
 * in the SubsCapsMenu.
 *
 * @extends TextTrackMenuItem
 */

var SubsCapsMenuItem = /*#__PURE__*/function (_TextTrackMenuItem) {
  _inheritsLoose__default['default'](SubsCapsMenuItem, _TextTrackMenuItem);

  function SubsCapsMenuItem() {
    return _TextTrackMenuItem.apply(this, arguments) || this;
  }

  var _proto = SubsCapsMenuItem.prototype;

  _proto.createEl = function createEl$1(type, props, attrs) {
    var el = _TextTrackMenuItem.prototype.createEl.call(this, type, props, attrs);

    var parentSpan = el.querySelector('.vjs-menu-item-text');

    if (this.options_.track.kind === 'captions') {
      parentSpan.appendChild(createEl('span', {
        className: 'vjs-icon-placeholder'
      }, {
        'aria-hidden': true
      }));
      parentSpan.appendChild(createEl('span', {
        className: 'vjs-control-text',
        // space added as the text will visually flow with the
        // label
        textContent: " " + this.localize('Captions')
      }));
    }

    return el;
  };

  return SubsCapsMenuItem;
}(TextTrackMenuItem);

Component.registerComponent('SubsCapsMenuItem', SubsCapsMenuItem);

/**
 * The button component for toggling and selecting captions and/or subtitles
 *
 * @extends TextTrackButton
 */

var SubsCapsButton = /*#__PURE__*/function (_TextTrackButton) {
  _inheritsLoose__default['default'](SubsCapsButton, _TextTrackButton);

  function SubsCapsButton(player, options) {
    var _this;

    if (options === void 0) {
      options = {};
    }

    _this = _TextTrackButton.call(this, player, options) || this; // Although North America uses "captions" in most cases for
    // "captions and subtitles" other locales use "subtitles"

    _this.label_ = 'subtitles';

    if (['en', 'en-us', 'en-ca', 'fr-ca'].indexOf(_this.player_.language_) > -1) {
      _this.label_ = 'captions';
    }

    _this.menuButton_.controlText(toTitleCase(_this.label_));

    return _this;
  }
  /**
   * Builds the default DOM `className`.
   *
   * @return {string}
   *         The DOM `className` for this object.
   */


  var _proto = SubsCapsButton.prototype;

  _proto.buildCSSClass = function buildCSSClass() {
    return "vjs-subs-caps-button " + _TextTrackButton.prototype.buildCSSClass.call(this);
  };

  _proto.buildWrapperCSSClass = function buildWrapperCSSClass() {
    return "vjs-subs-caps-button " + _TextTrackButton.prototype.buildWrapperCSSClass.call(this);
  }
  /**
   * Create caption/subtitles menu items
   *
   * @return {CaptionSettingsMenuItem[]}
   *         The array of current menu items.
   */
  ;

  _proto.createItems = function createItems() {
    var items = [];

    if (!(this.player().tech_ && this.player().tech_.featuresNativeTextTracks) && this.player().getChild('textTrackSettings')) {
      items.push(new CaptionSettingsMenuItem(this.player_, {
        kind: this.label_
      }));
      this.hideThreshold_ += 1;
    }

    items = _TextTrackButton.prototype.createItems.call(this, items, SubsCapsMenuItem);
    return items;
  };

  return SubsCapsButton;
}(TextTrackButton);
/**
 * `kind`s of TextTrack to look for to associate it with this menu.
 *
 * @type {array}
 * @private
 */


SubsCapsButton.prototype.kinds_ = ['captions', 'subtitles'];
/**
 * The text that should display over the `SubsCapsButton`s controls.
 *
 *
 * @type {string}
 * @private
 */

SubsCapsButton.prototype.controlText_ = 'Subtitles';
Component.registerComponent('SubsCapsButton', SubsCapsButton);

/**
 * An {@link AudioTrack} {@link MenuItem}
 *
 * @extends MenuItem
 */

var AudioTrackMenuItem = /*#__PURE__*/function (_MenuItem) {
  _inheritsLoose__default['default'](AudioTrackMenuItem, _MenuItem);

  /**
   * Creates an instance of this class.
   *
   * @param {Player} player
   *        The `Player` that this class should be attached to.
   *
   * @param {Object} [options]
   *        The key/value store of player options.
   */
  function AudioTrackMenuItem(player, options) {
    var _this;

    var track = options.track;
    var tracks = player.audioTracks(); // Modify options for parent MenuItem class's init.

    options.label = track.label || track.language || 'Unknown';
    options.selected = track.enabled;
    _this = _MenuItem.call(this, player, options) || this;
    _this.track = track;

    _this.addClass("vjs-" + track.kind + "-menu-item");

    var changeHandler = function changeHandler() {
      for (var _len = arguments.length, args = new Array(_len), _key = 0; _key < _len; _key++) {
        args[_key] = arguments[_key];
      }

      _this.handleTracksChange.apply(_assertThisInitialized__default['default'](_this), args);
    };

    tracks.addEventListener('change', changeHandler);

    _this.on('dispose', function () {
      tracks.removeEventListener('change', changeHandler);
    });

    return _this;
  }

  var _proto = AudioTrackMenuItem.prototype;

  _proto.createEl = function createEl$1(type, props, attrs) {
    var el = _MenuItem.prototype.createEl.call(this, type, props, attrs);

    var parentSpan = el.querySelector('.vjs-menu-item-text');

    if (this.options_.track.kind === 'main-desc') {
      parentSpan.appendChild(createEl('span', {
        className: 'vjs-icon-placeholder'
      }, {
        'aria-hidden': true
      }));
      parentSpan.appendChild(createEl('span', {
        className: 'vjs-control-text',
        textContent: ' ' + this.localize('Descriptions')
      }));
    }

    return el;
  }
  /**
   * This gets called when an `AudioTrackMenuItem is "clicked". See {@link ClickableComponent}
   * for more detailed information on what a click can be.
   *
   * @param {EventTarget~Event} [event]
   *        The `keydown`, `tap`, or `click` event that caused this function to be
   *        called.
   *
   * @listens tap
   * @listens click
   */
  ;

  _proto.handleClick = function handleClick(event) {
    _MenuItem.prototype.handleClick.call(this, event); // the audio track list will automatically toggle other tracks
    // off for us.


    this.track.enabled = true; // when native audio tracks are used, we want to make sure that other tracks are turned off

    if (this.player_.tech_.featuresNativeAudioTracks) {
      var tracks = this.player_.audioTracks();

      for (var i = 0; i < tracks.length; i++) {
        var track = tracks[i]; // skip the current track since we enabled it above

        if (track === this.track) {
          continue;
        }

        track.enabled = track === this.track;
      }
    }
  }
  /**
   * Handle any {@link AudioTrack} change.
   *
   * @param {EventTarget~Event} [event]
   *        The {@link AudioTrackList#change} event that caused this to run.
   *
   * @listens AudioTrackList#change
   */
  ;

  _proto.handleTracksChange = function handleTracksChange(event) {
    this.selected(this.track.enabled);
  };

  return AudioTrackMenuItem;
}(MenuItem);

Component.registerComponent('AudioTrackMenuItem', AudioTrackMenuItem);

/**
 * The base class for buttons that toggle specific {@link AudioTrack} types.
 *
 * @extends TrackButton
 */

var AudioTrackButton = /*#__PURE__*/function (_TrackButton) {
  _inheritsLoose__default['default'](AudioTrackButton, _TrackButton);

  /**
   * Creates an instance of this class.
   *
   * @param {Player} player
   *        The `Player` that this class should be attached to.
   *
   * @param {Object} [options={}]
   *        The key/value store of player options.
   */
  function AudioTrackButton(player, options) {
    if (options === void 0) {
      options = {};
    }

    options.tracks = player.audioTracks();
    return _TrackButton.call(this, player, options) || this;
  }
  /**
   * Builds the default DOM `className`.
   *
   * @return {string}
   *         The DOM `className` for this object.
   */


  var _proto = AudioTrackButton.prototype;

  _proto.buildCSSClass = function buildCSSClass() {
    return "vjs-audio-button " + _TrackButton.prototype.buildCSSClass.call(this);
  };

  _proto.buildWrapperCSSClass = function buildWrapperCSSClass() {
    return "vjs-audio-button " + _TrackButton.prototype.buildWrapperCSSClass.call(this);
  }
  /**
   * Create a menu item for each audio track
   *
   * @param {AudioTrackMenuItem[]} [items=[]]
   *        An array of existing menu items to use.
   *
   * @return {AudioTrackMenuItem[]}
   *         An array of menu items
   */
  ;

  _proto.createItems = function createItems(items) {
    if (items === void 0) {
      items = [];
    }

    // if there's only one audio track, there no point in showing it
    this.hideThreshold_ = 1;
    var tracks = this.player_.audioTracks();

    for (var i = 0; i < tracks.length; i++) {
      var track = tracks[i];
      items.push(new AudioTrackMenuItem(this.player_, {
        track: track,
        // MenuItem is selectable
        selectable: true,
        // MenuItem is NOT multiSelectable (i.e. only one can be marked "selected" at a time)
        multiSelectable: false
      }));
    }

    return items;
  };

  return AudioTrackButton;
}(TrackButton);
/**
 * The text that should display over the `AudioTrackButton`s controls. Added for localization.
 *
 * @type {string}
 * @private
 */


AudioTrackButton.prototype.controlText_ = 'Audio Track';
Component.registerComponent('AudioTrackButton', AudioTrackButton);

/**
 * The specific menu item type for selecting a playback rate.
 *
 * @extends MenuItem
 */

var PlaybackRateMenuItem = /*#__PURE__*/function (_MenuItem) {
  _inheritsLoose__default['default'](PlaybackRateMenuItem, _MenuItem);

  /**
   * Creates an instance of this class.
   *
   * @param {Player} player
   *        The `Player` that this class should be attached to.
   *
   * @param {Object} [options]
   *        The key/value store of player options.
   */
  function PlaybackRateMenuItem(player, options) {
    var _this;

    var label = options.rate;
    var rate = parseFloat(label, 10); // Modify options for parent MenuItem class's init.

    options.label = label;
    options.selected = rate === player.playbackRate();
    options.selectable = true;
    options.multiSelectable = false;
    _this = _MenuItem.call(this, player, options) || this;
    _this.label = label;
    _this.rate = rate;

    _this.on(player, 'ratechange', function (e) {
      return _this.update(e);
    });

    return _this;
  }
  /**
   * This gets called when an `PlaybackRateMenuItem` is "clicked". See
   * {@link ClickableComponent} for more detailed information on what a click can be.
   *
   * @param {EventTarget~Event} [event]
   *        The `keydown`, `tap`, or `click` event that caused this function to be
   *        called.
   *
   * @listens tap
   * @listens click
   */


  var _proto = PlaybackRateMenuItem.prototype;

  _proto.handleClick = function handleClick(event) {
    _MenuItem.prototype.handleClick.call(this);

    this.player().playbackRate(this.rate);
  }
  /**
   * Update the PlaybackRateMenuItem when the playbackrate changes.
   *
   * @param {EventTarget~Event} [event]
   *        The `ratechange` event that caused this function to run.
   *
   * @listens Player#ratechange
   */
  ;

  _proto.update = function update(event) {
    this.selected(this.player().playbackRate() === this.rate);
  };

  return PlaybackRateMenuItem;
}(MenuItem);
/**
 * The text that should display over the `PlaybackRateMenuItem`s controls. Added for localization.
 *
 * @type {string}
 * @private
 */


PlaybackRateMenuItem.prototype.contentElType = 'button';
Component.registerComponent('PlaybackRateMenuItem', PlaybackRateMenuItem);

/**
 * The component for controlling the playback rate.
 *
 * @extends MenuButton
 */

var PlaybackRateMenuButton = /*#__PURE__*/function (_MenuButton) {
  _inheritsLoose__default['default'](PlaybackRateMenuButton, _MenuButton);

  /**
   * Creates an instance of this class.
   *
   * @param {Player} player
   *        The `Player` that this class should be attached to.
   *
   * @param {Object} [options]
   *        The key/value store of player options.
   */
  function PlaybackRateMenuButton(player, options) {
    var _this;

    _this = _MenuButton.call(this, player, options) || this;

    _this.menuButton_.el_.setAttribute('aria-describedby', _this.labelElId_);

    _this.updateVisibility();

    _this.updateLabel();

    _this.on(player, 'loadstart', function (e) {
      return _this.updateVisibility(e);
    });

    _this.on(player, 'ratechange', function (e) {
      return _this.updateLabel(e);
    });

    _this.on(player, 'playbackrateschange', function (e) {
      return _this.handlePlaybackRateschange(e);
    });

    return _this;
  }
  /**
   * Create the `Component`'s DOM element
   *
   * @return {Element}
   *         The element that was created.
   */


  var _proto = PlaybackRateMenuButton.prototype;

  _proto.createEl = function createEl$1() {
    var el = _MenuButton.prototype.createEl.call(this);

    this.labelElId_ = 'vjs-playback-rate-value-label-' + this.id_;
    this.labelEl_ = createEl('div', {
      className: 'vjs-playback-rate-value',
      id: this.labelElId_,
      textContent: '1x'
    });
    el.appendChild(this.labelEl_);
    return el;
  };

  _proto.dispose = function dispose() {
    this.labelEl_ = null;

    _MenuButton.prototype.dispose.call(this);
  }
  /**
   * Builds the default DOM `className`.
   *
   * @return {string}
   *         The DOM `className` for this object.
   */
  ;

  _proto.buildCSSClass = function buildCSSClass() {
    return "vjs-playback-rate " + _MenuButton.prototype.buildCSSClass.call(this);
  };

  _proto.buildWrapperCSSClass = function buildWrapperCSSClass() {
    return "vjs-playback-rate " + _MenuButton.prototype.buildWrapperCSSClass.call(this);
  }
  /**
   * Create the list of menu items. Specific to each subclass.
   *
   */
  ;

  _proto.createItems = function createItems() {
    var rates = this.playbackRates();
    var items = [];

    for (var i = rates.length - 1; i >= 0; i--) {
      items.push(new PlaybackRateMenuItem(this.player(), {
        rate: rates[i] + 'x'
      }));
    }

    return items;
  }
  /**
   * Updates ARIA accessibility attributes
   */
  ;

  _proto.updateARIAAttributes = function updateARIAAttributes() {
    // Current playback rate
    this.el().setAttribute('aria-valuenow', this.player().playbackRate());
  }
  /**
   * This gets called when an `PlaybackRateMenuButton` is "clicked". See
   * {@link ClickableComponent} for more detailed information on what a click can be.
   *
   * @param {EventTarget~Event} [event]
   *        The `keydown`, `tap`, or `click` event that caused this function to be
   *        called.
   *
   * @listens tap
   * @listens click
   */
  ;

  _proto.handleClick = function handleClick(event) {
    // select next rate option
    var currentRate = this.player().playbackRate();
    var rates = this.playbackRates();
    var currentIndex = rates.indexOf(currentRate); // this get the next rate and it will select first one if the last one currently selected

    var newIndex = (currentIndex + 1) % rates.length;
    this.player().playbackRate(rates[newIndex]);
  }
  /**
   * On playbackrateschange, update the menu to account for the new items.
   *
   * @listens Player#playbackrateschange
   */
  ;

  _proto.handlePlaybackRateschange = function handlePlaybackRateschange(event) {
    this.update();
  }
  /**
   * Get possible playback rates
   *
   * @return {Array}
   *         All possible playback rates
   */
  ;

  _proto.playbackRates = function playbackRates() {
    var player = this.player();
    return player.playbackRates && player.playbackRates() || [];
  }
  /**
   * Get whether playback rates is supported by the tech
   * and an array of playback rates exists
   *
   * @return {boolean}
   *         Whether changing playback rate is supported
   */
  ;

  _proto.playbackRateSupported = function playbackRateSupported() {
    return this.player().tech_ && this.player().tech_.featuresPlaybackRate && this.playbackRates() && this.playbackRates().length > 0;
  }
  /**
   * Hide playback rate controls when they're no playback rate options to select
   *
   * @param {EventTarget~Event} [event]
   *        The event that caused this function to run.
   *
   * @listens Player#loadstart
   */
  ;

  _proto.updateVisibility = function updateVisibility(event) {
    if (this.playbackRateSupported()) {
      this.removeClass('vjs-hidden');
    } else {
      this.addClass('vjs-hidden');
    }
  }
  /**
   * Update button label when rate changed
   *
   * @param {EventTarget~Event} [event]
   *        The event that caused this function to run.
   *
   * @listens Player#ratechange
   */
  ;

  _proto.updateLabel = function updateLabel(event) {
    if (this.playbackRateSupported()) {
      this.labelEl_.textContent = this.player().playbackRate() + 'x';
    }
  };

  return PlaybackRateMenuButton;
}(MenuButton);
/**
 * The text that should display over the `FullscreenToggle`s controls. Added for localization.
 *
 * @type {string}
 * @private
 */


PlaybackRateMenuButton.prototype.controlText_ = 'Playback Rate';
Component.registerComponent('PlaybackRateMenuButton', PlaybackRateMenuButton);

/**
 * Just an empty spacer element that can be used as an append point for plugins, etc.
 * Also can be used to create space between elements when necessary.
 *
 * @extends Component
 */

var Spacer = /*#__PURE__*/function (_Component) {
  _inheritsLoose__default['default'](Spacer, _Component);

  function Spacer() {
    return _Component.apply(this, arguments) || this;
  }

  var _proto = Spacer.prototype;

  /**
  * Builds the default DOM `className`.
  *
  * @return {string}
  *         The DOM `className` for this object.
  */
  _proto.buildCSSClass = function buildCSSClass() {
    return "vjs-spacer " + _Component.prototype.buildCSSClass.call(this);
  }
  /**
   * Create the `Component`'s DOM element
   *
   * @return {Element}
   *         The element that was created.
   */
  ;

  _proto.createEl = function createEl(tag, props, attributes) {
    if (tag === void 0) {
      tag = 'div';
    }

    if (props === void 0) {
      props = {};
    }

    if (attributes === void 0) {
      attributes = {};
    }

    if (!props.className) {
      props.className = this.buildCSSClass();
    }

    return _Component.prototype.createEl.call(this, tag, props, attributes);
  };

  return Spacer;
}(Component);

Component.registerComponent('Spacer', Spacer);

/**
 * Spacer specifically meant to be used as an insertion point for new plugins, etc.
 *
 * @extends Spacer
 */

var CustomControlSpacer = /*#__PURE__*/function (_Spacer) {
  _inheritsLoose__default['default'](CustomControlSpacer, _Spacer);

  function CustomControlSpacer() {
    return _Spacer.apply(this, arguments) || this;
  }

  var _proto = CustomControlSpacer.prototype;

  /**
   * Builds the default DOM `className`.
   *
   * @return {string}
   *         The DOM `className` for this object.
   */
  _proto.buildCSSClass = function buildCSSClass() {
    return "vjs-custom-control-spacer " + _Spacer.prototype.buildCSSClass.call(this);
  }
  /**
   * Create the `Component`'s DOM element
   *
   * @return {Element}
   *         The element that was created.
   */
  ;

  _proto.createEl = function createEl() {
    return _Spacer.prototype.createEl.call(this, 'div', {
      className: this.buildCSSClass(),
      // No-flex/table-cell mode requires there be some content
      // in the cell to fill the remaining space of the table.
      textContent: "\xA0"
    });
  };

  return CustomControlSpacer;
}(Spacer);

Component.registerComponent('CustomControlSpacer', CustomControlSpacer);

/**
 * Container of main controls.
 *
 * @extends Component
 */

var ControlBar = /*#__PURE__*/function (_Component) {
  _inheritsLoose__default['default'](ControlBar, _Component);

  function ControlBar() {
    return _Component.apply(this, arguments) || this;
  }

  var _proto = ControlBar.prototype;

  /**
   * Create the `Component`'s DOM element
   *
   * @return {Element}
   *         The element that was created.
   */
  _proto.createEl = function createEl() {
    return _Component.prototype.createEl.call(this, 'div', {
      className: 'vjs-control-bar',
      dir: 'ltr'
    });
  };

  return ControlBar;
}(Component);
/**
 * Default options for `ControlBar`
 *
 * @type {Object}
 * @private
 */


ControlBar.prototype.options_ = {
  children: ['playToggle', 'volumePanel', 'currentTimeDisplay', 'timeDivider', 'durationDisplay', 'progressControl', 'liveDisplay', 'seekToLive', 'remainingTimeDisplay', 'customControlSpacer', 'playbackRateMenuButton', 'chaptersButton', 'descriptionsButton', 'subsCapsButton', 'audioTrackButton', 'fullscreenToggle']
};

if ('exitPictureInPicture' in document__default['default']) {
  ControlBar.prototype.options_.children.splice(ControlBar.prototype.options_.children.length - 1, 0, 'pictureInPictureToggle');
}

Component.registerComponent('ControlBar', ControlBar);

/**
 * A display that indicates an error has occurred. This means that the video
 * is unplayable.
 *
 * @extends ModalDialog
 */

var ErrorDisplay = /*#__PURE__*/function (_ModalDialog) {
  _inheritsLoose__default['default'](ErrorDisplay, _ModalDialog);

  /**
   * Creates an instance of this class.
   *
   * @param  {Player} player
   *         The `Player` that this class should be attached to.
   *
   * @param  {Object} [options]
   *         The key/value store of player options.
   */
  function ErrorDisplay(player, options) {
    var _this;

    _this = _ModalDialog.call(this, player, options) || this;

    _this.on(player, 'error', function (e) {
      return _this.open(e);
    });

    return _this;
  }
  /**
   * Builds the default DOM `className`.
   *
   * @return {string}
   *         The DOM `className` for this object.
   *
   * @deprecated Since version 5.
   */


  var _proto = ErrorDisplay.prototype;

  _proto.buildCSSClass = function buildCSSClass() {
    return "vjs-error-display " + _ModalDialog.prototype.buildCSSClass.call(this);
  }
  /**
   * Gets the localized error message based on the `Player`s error.
   *
   * @return {string}
   *         The `Player`s error message localized or an empty string.
   */
  ;

  _proto.content = function content() {
    var error = this.player().error();
    return error ? this.localize(error.message) : '';
  };

  return ErrorDisplay;
}(ModalDialog);
/**
 * The default options for an `ErrorDisplay`.
 *
 * @private
 */


ErrorDisplay.prototype.options_ = _extends__default['default']({}, ModalDialog.prototype.options_, {
  pauseOnOpen: false,
  fillAlways: true,
  temporary: false,
  uncloseable: true
});
Component.registerComponent('ErrorDisplay', ErrorDisplay);

var LOCAL_STORAGE_KEY = 'vjs-text-track-settings';
var COLOR_BLACK = ['#000', 'Black'];
var COLOR_BLUE = ['#00F', 'Blue'];
var COLOR_CYAN = ['#0FF', 'Cyan'];
var COLOR_GREEN = ['#0F0', 'Green'];
var COLOR_MAGENTA = ['#F0F', 'Magenta'];
var COLOR_RED = ['#F00', 'Red'];
var COLOR_WHITE = ['#FFF', 'White'];
var COLOR_YELLOW = ['#FF0', 'Yellow'];
var OPACITY_OPAQUE = ['1', 'Opaque'];
var OPACITY_SEMI = ['0.5', 'Semi-Transparent'];
var OPACITY_TRANS = ['0', 'Transparent']; // Configuration for the various <select> elements in the DOM of this component.
//
// Possible keys include:
//
// `default`:
//   The default option index. Only needs to be provided if not zero.
// `parser`:
//   A function which is used to parse the value from the selected option in
//   a customized way.
// `selector`:
//   The selector used to find the associated <select> element.

var selectConfigs = {
  backgroundColor: {
    selector: '.vjs-bg-color > select',
    id: 'captions-background-color-%s',
    label: 'Color',
    options: [COLOR_BLACK, COLOR_WHITE, COLOR_RED, COLOR_GREEN, COLOR_BLUE, COLOR_YELLOW, COLOR_MAGENTA, COLOR_CYAN]
  },
  backgroundOpacity: {
    selector: '.vjs-bg-opacity > select',
    id: 'captions-background-opacity-%s',
    label: 'Transparency',
    options: [OPACITY_OPAQUE, OPACITY_SEMI, OPACITY_TRANS]
  },
  color: {
    selector: '.vjs-fg-color > select',
    id: 'captions-foreground-color-%s',
    label: 'Color',
    options: [COLOR_WHITE, COLOR_BLACK, COLOR_RED, COLOR_GREEN, COLOR_BLUE, COLOR_YELLOW, COLOR_MAGENTA, COLOR_CYAN]
  },
  edgeStyle: {
    selector: '.vjs-edge-style > select',
    id: '%s',
    label: 'Text Edge Style',
    options: [['none', 'None'], ['raised', 'Raised'], ['depressed', 'Depressed'], ['uniform', 'Uniform'], ['dropshadow', 'Dropshadow']]
  },
  fontFamily: {
    selector: '.vjs-font-family > select',
    id: 'captions-font-family-%s',
    label: 'Font Family',
    options: [['proportionalSansSerif', 'Proportional Sans-Serif'], ['monospaceSansSerif', 'Monospace Sans-Serif'], ['proportionalSerif', 'Proportional Serif'], ['monospaceSerif', 'Monospace Serif'], ['casual', 'Casual'], ['script', 'Script'], ['small-caps', 'Small Caps']]
  },
  fontPercent: {
    selector: '.vjs-font-percent > select',
    id: 'captions-font-size-%s',
    label: 'Font Size',
    options: [['0.50', '50%'], ['0.75', '75%'], ['1.00', '100%'], ['1.25', '125%'], ['1.50', '150%'], ['1.75', '175%'], ['2.00', '200%'], ['3.00', '300%'], ['4.00', '400%']],
    "default": 2,
    parser: function parser(v) {
      return v === '1.00' ? null : Number(v);
    }
  },
  textOpacity: {
    selector: '.vjs-text-opacity > select',
    id: 'captions-foreground-opacity-%s',
    label: 'Transparency',
    options: [OPACITY_OPAQUE, OPACITY_SEMI]
  },
  // Options for this object are defined below.
  windowColor: {
    selector: '.vjs-window-color > select',
    id: 'captions-window-color-%s',
    label: 'Color'
  },
  // Options for this object are defined below.
  windowOpacity: {
    selector: '.vjs-window-opacity > select',
    id: 'captions-window-opacity-%s',
    label: 'Transparency',
    options: [OPACITY_TRANS, OPACITY_SEMI, OPACITY_OPAQUE]
  }
};
selectConfigs.windowColor.options = selectConfigs.backgroundColor.options;
/**
 * Get the actual value of an option.
 *
 * @param  {string} value
 *         The value to get
 *
 * @param  {Function} [parser]
 *         Optional function to adjust the value.
 *
 * @return {Mixed}
 *         - Will be `undefined` if no value exists
 *         - Will be `undefined` if the given value is "none".
 *         - Will be the actual value otherwise.
 *
 * @private
 */

function parseOptionValue(value, parser) {
  if (parser) {
    value = parser(value);
  }

  if (value && value !== 'none') {
    return value;
  }
}
/**
 * Gets the value of the selected <option> element within a <select> element.
 *
 * @param  {Element} el
 *         the element to look in
 *
 * @param  {Function} [parser]
 *         Optional function to adjust the value.
 *
 * @return {Mixed}
 *         - Will be `undefined` if no value exists
 *         - Will be `undefined` if the given value is "none".
 *         - Will be the actual value otherwise.
 *
 * @private
 */


function getSelectedOptionValue(el, parser) {
  var value = el.options[el.options.selectedIndex].value;
  return parseOptionValue(value, parser);
}
/**
 * Sets the selected <option> element within a <select> element based on a
 * given value.
 *
 * @param {Element} el
 *        The element to look in.
 *
 * @param {string} value
 *        the property to look on.
 *
 * @param {Function} [parser]
 *        Optional function to adjust the value before comparing.
 *
 * @private
 */


function setSelectedOption(el, value, parser) {
  if (!value) {
    return;
  }

  for (var i = 0; i < el.options.length; i++) {
    if (parseOptionValue(el.options[i].value, parser) === value) {
      el.selectedIndex = i;
      break;
    }
  }
}
/**
 * Manipulate Text Tracks settings.
 *
 * @extends ModalDialog
 */


var TextTrackSettings = /*#__PURE__*/function (_ModalDialog) {
  _inheritsLoose__default['default'](TextTrackSettings, _ModalDialog);

  /**
   * Creates an instance of this class.
   *
   * @param {Player} player
   *         The `Player` that this class should be attached to.
   *
   * @param {Object} [options]
   *         The key/value store of player options.
   */
  function TextTrackSettings(player, options) {
    var _this;

    options.temporary = false;
    _this = _ModalDialog.call(this, player, options) || this;
    _this.updateDisplay = _this.updateDisplay.bind(_assertThisInitialized__default['default'](_this)); // fill the modal and pretend we have opened it

    _this.fill();

    _this.hasBeenOpened_ = _this.hasBeenFilled_ = true;
    _this.endDialog = createEl('p', {
      className: 'vjs-control-text',
      textContent: _this.localize('End of dialog window.')
    });

    _this.el().appendChild(_this.endDialog);

    _this.setDefaults(); // Grab `persistTextTrackSettings` from the player options if not passed in child options


    if (options.persistTextTrackSettings === undefined) {
      _this.options_.persistTextTrackSettings = _this.options_.playerOptions.persistTextTrackSettings;
    }

    _this.on(_this.$('.vjs-done-button'), 'click', function () {
      _this.saveSettings();

      _this.close();
    });

    _this.on(_this.$('.vjs-default-button'), 'click', function () {
      _this.setDefaults();

      _this.updateDisplay();
    });

    each(selectConfigs, function (config) {
      _this.on(_this.$(config.selector), 'change', _this.updateDisplay);
    });

    if (_this.options_.persistTextTrackSettings) {
      _this.restoreSettings();
    }

    return _this;
  }

  var _proto = TextTrackSettings.prototype;

  _proto.dispose = function dispose() {
    this.endDialog = null;

    _ModalDialog.prototype.dispose.call(this);
  }
  /**
   * Create a <select> element with configured options.
   *
   * @param {string} key
   *        Configuration key to use during creation.
   *
   * @return {string}
   *         An HTML string.
   *
   * @private
   */
  ;

  _proto.createElSelect_ = function createElSelect_(key, legendId, type) {
    var _this2 = this;

    if (legendId === void 0) {
      legendId = '';
    }

    if (type === void 0) {
      type = 'label';
    }

    var config = selectConfigs[key];
    var id = config.id.replace('%s', this.id_);
    var selectLabelledbyIds = [legendId, id].join(' ').trim();
    return ["<" + type + " id=\"" + id + "\" class=\"" + (type === 'label' ? 'vjs-label' : '') + "\">", this.localize(config.label), "</" + type + ">", "<select aria-labelledby=\"" + selectLabelledbyIds + "\">"].concat(config.options.map(function (o) {
      var optionId = id + '-' + o[1].replace(/\W+/g, '');
      return ["<option id=\"" + optionId + "\" value=\"" + o[0] + "\" ", "aria-labelledby=\"" + selectLabelledbyIds + " " + optionId + "\">", _this2.localize(o[1]), '</option>'].join('');
    })).concat('</select>').join('');
  }
  /**
   * Create foreground color element for the component
   *
   * @return {string}
   *         An HTML string.
   *
   * @private
   */
  ;

  _proto.createElFgColor_ = function createElFgColor_() {
    var legendId = "captions-text-legend-" + this.id_;
    return ['<fieldset class="vjs-fg-color vjs-track-setting">', "<legend id=\"" + legendId + "\">", this.localize('Text'), '</legend>', this.createElSelect_('color', legendId), '<span class="vjs-text-opacity vjs-opacity">', this.createElSelect_('textOpacity', legendId), '</span>', '</fieldset>'].join('');
  }
  /**
   * Create background color element for the component
   *
   * @return {string}
   *         An HTML string.
   *
   * @private
   */
  ;

  _proto.createElBgColor_ = function createElBgColor_() {
    var legendId = "captions-background-" + this.id_;
    return ['<fieldset class="vjs-bg-color vjs-track-setting">', "<legend id=\"" + legendId + "\">", this.localize('Background'), '</legend>', this.createElSelect_('backgroundColor', legendId), '<span class="vjs-bg-opacity vjs-opacity">', this.createElSelect_('backgroundOpacity', legendId), '</span>', '</fieldset>'].join('');
  }
  /**
   * Create window color element for the component
   *
   * @return {string}
   *         An HTML string.
   *
   * @private
   */
  ;

  _proto.createElWinColor_ = function createElWinColor_() {
    var legendId = "captions-window-" + this.id_;
    return ['<fieldset class="vjs-window-color vjs-track-setting">', "<legend id=\"" + legendId + "\">", this.localize('Window'), '</legend>', this.createElSelect_('windowColor', legendId), '<span class="vjs-window-opacity vjs-opacity">', this.createElSelect_('windowOpacity', legendId), '</span>', '</fieldset>'].join('');
  }
  /**
   * Create color elements for the component
   *
   * @return {Element}
   *         The element that was created
   *
   * @private
   */
  ;

  _proto.createElColors_ = function createElColors_() {
    return createEl('div', {
      className: 'vjs-track-settings-colors',
      innerHTML: [this.createElFgColor_(), this.createElBgColor_(), this.createElWinColor_()].join('')
    });
  }
  /**
   * Create font elements for the component
   *
   * @return {Element}
   *         The element that was created.
   *
   * @private
   */
  ;

  _proto.createElFont_ = function createElFont_() {
    return createEl('div', {
      className: 'vjs-track-settings-font',
      innerHTML: ['<fieldset class="vjs-font-percent vjs-track-setting">', this.createElSelect_('fontPercent', '', 'legend'), '</fieldset>', '<fieldset class="vjs-edge-style vjs-track-setting">', this.createElSelect_('edgeStyle', '', 'legend'), '</fieldset>', '<fieldset class="vjs-font-family vjs-track-setting">', this.createElSelect_('fontFamily', '', 'legend'), '</fieldset>'].join('')
    });
  }
  /**
   * Create controls for the component
   *
   * @return {Element}
   *         The element that was created.
   *
   * @private
   */
  ;

  _proto.createElControls_ = function createElControls_() {
    var defaultsDescription = this.localize('restore all settings to the default values');
    return createEl('div', {
      className: 'vjs-track-settings-controls',
      innerHTML: ["<button type=\"button\" class=\"vjs-default-button\" title=\"" + defaultsDescription + "\">", this.localize('Reset'), "<span class=\"vjs-control-text\"> " + defaultsDescription + "</span>", '</button>', "<button type=\"button\" class=\"vjs-done-button\">" + this.localize('Done') + "</button>"].join('')
    });
  };

  _proto.content = function content() {
    return [this.createElColors_(), this.createElFont_(), this.createElControls_()];
  };

  _proto.label = function label() {
    return this.localize('Caption Settings Dialog');
  };

  _proto.description = function description() {
    return this.localize('Beginning of dialog window. Escape will cancel and close the window.');
  };

  _proto.buildCSSClass = function buildCSSClass() {
    return _ModalDialog.prototype.buildCSSClass.call(this) + ' vjs-text-track-settings';
  }
  /**
   * Gets an object of text track settings (or null).
   *
   * @return {Object}
   *         An object with config values parsed from the DOM or localStorage.
   */
  ;

  _proto.getValues = function getValues() {
    var _this3 = this;

    return reduce(selectConfigs, function (accum, config, key) {
      var value = getSelectedOptionValue(_this3.$(config.selector), config.parser);

      if (value !== undefined) {
        accum[key] = value;
      }

      return accum;
    }, {});
  }
  /**
   * Sets text track settings from an object of values.
   *
   * @param {Object} values
   *        An object with config values parsed from the DOM or localStorage.
   */
  ;

  _proto.setValues = function setValues(values) {
    var _this4 = this;

    each(selectConfigs, function (config, key) {
      setSelectedOption(_this4.$(config.selector), values[key], config.parser);
    });
  }
  /**
   * Sets all `<select>` elements to their default values.
   */
  ;

  _proto.setDefaults = function setDefaults() {
    var _this5 = this;

    each(selectConfigs, function (config) {
      var index = config.hasOwnProperty('default') ? config["default"] : 0;
      _this5.$(config.selector).selectedIndex = index;
    });
  }
  /**
   * Restore texttrack settings from localStorage
   */
  ;

  _proto.restoreSettings = function restoreSettings() {
    var values;

    try {
      values = JSON.parse(window__default['default'].localStorage.getItem(LOCAL_STORAGE_KEY));
    } catch (err) {
      log.warn(err);
    }

    if (values) {
      this.setValues(values);
    }
  }
  /**
   * Save text track settings to localStorage
   */
  ;

  _proto.saveSettings = function saveSettings() {
    if (!this.options_.persistTextTrackSettings) {
      return;
    }

    var values = this.getValues();

    try {
      if (Object.keys(values).length) {
        window__default['default'].localStorage.setItem(LOCAL_STORAGE_KEY, JSON.stringify(values));
      } else {
        window__default['default'].localStorage.removeItem(LOCAL_STORAGE_KEY);
      }
    } catch (err) {
      log.warn(err);
    }
  }
  /**
   * Update display of text track settings
   */
  ;

  _proto.updateDisplay = function updateDisplay() {
    var ttDisplay = this.player_.getChild('textTrackDisplay');

    if (ttDisplay) {
      ttDisplay.updateDisplay();
    }
  }
  /**
   * conditionally blur the element and refocus the captions button
   *
   * @private
   */
  ;

  _proto.conditionalBlur_ = function conditionalBlur_() {
    this.previouslyActiveEl_ = null;
    var cb = this.player_.controlBar;
    var subsCapsBtn = cb && cb.subsCapsButton;
    var ccBtn = cb && cb.captionsButton;

    if (subsCapsBtn) {
      subsCapsBtn.focus();
    } else if (ccBtn) {
      ccBtn.focus();
    }
  };

  return TextTrackSettings;
}(ModalDialog);

Component.registerComponent('TextTrackSettings', TextTrackSettings);

/**
 * A Resize Manager. It is in charge of triggering `playerresize` on the player in the right conditions.
 *
 * It'll either create an iframe and use a debounced resize handler on it or use the new {@link https://wicg.github.io/ResizeObserver/|ResizeObserver}.
 *
 * If the ResizeObserver is available natively, it will be used. A polyfill can be passed in as an option.
 * If a `playerresize` event is not needed, the ResizeManager component can be removed from the player, see the example below.
 * @example <caption>How to disable the resize manager</caption>
 * const player = videojs('#vid', {
 *   resizeManager: false
 * });
 *
 * @see {@link https://wicg.github.io/ResizeObserver/|ResizeObserver specification}
 *
 * @extends Component
 */

var ResizeManager = /*#__PURE__*/function (_Component) {
  _inheritsLoose__default['default'](ResizeManager, _Component);

  /**
   * Create the ResizeManager.
   *
   * @param {Object} player
   *        The `Player` that this class should be attached to.
   *
   * @param {Object} [options]
   *        The key/value store of ResizeManager options.
   *
   * @param {Object} [options.ResizeObserver]
   *        A polyfill for ResizeObserver can be passed in here.
   *        If this is set to null it will ignore the native ResizeObserver and fall back to the iframe fallback.
   */
  function ResizeManager(player, options) {
    var _this;

    var RESIZE_OBSERVER_AVAILABLE = options.ResizeObserver || window__default['default'].ResizeObserver; // if `null` was passed, we want to disable the ResizeObserver

    if (options.ResizeObserver === null) {
      RESIZE_OBSERVER_AVAILABLE = false;
    } // Only create an element when ResizeObserver isn't available


    var options_ = mergeOptions({
      createEl: !RESIZE_OBSERVER_AVAILABLE,
      reportTouchActivity: false
    }, options);
    _this = _Component.call(this, player, options_) || this;
    _this.ResizeObserver = options.ResizeObserver || window__default['default'].ResizeObserver;
    _this.loadListener_ = null;
    _this.resizeObserver_ = null;
    _this.debouncedHandler_ = debounce(function () {
      _this.resizeHandler();
    }, 100, false, _assertThisInitialized__default['default'](_this));

    if (RESIZE_OBSERVER_AVAILABLE) {
      _this.resizeObserver_ = new _this.ResizeObserver(_this.debouncedHandler_);

      _this.resizeObserver_.observe(player.el());
    } else {
      _this.loadListener_ = function () {
        if (!_this.el_ || !_this.el_.contentWindow) {
          return;
        }

        var debouncedHandler_ = _this.debouncedHandler_;

        var unloadListener_ = _this.unloadListener_ = function () {
          off(this, 'resize', debouncedHandler_);
          off(this, 'unload', unloadListener_);
          unloadListener_ = null;
        }; // safari and edge can unload the iframe before resizemanager dispose
        // we have to dispose of event handlers correctly before that happens


        on(_this.el_.contentWindow, 'unload', unloadListener_);
        on(_this.el_.contentWindow, 'resize', debouncedHandler_);
      };

      _this.one('load', _this.loadListener_);
    }

    return _this;
  }

  var _proto = ResizeManager.prototype;

  _proto.createEl = function createEl() {
    return _Component.prototype.createEl.call(this, 'iframe', {
      className: 'vjs-resize-manager',
      tabIndex: -1
    }, {
      'aria-hidden': 'true'
    });
  }
  /**
   * Called when a resize is triggered on the iframe or a resize is observed via the ResizeObserver
   *
   * @fires Player#playerresize
   */
  ;

  _proto.resizeHandler = function resizeHandler() {
    /**
     * Called when the player size has changed
     *
     * @event Player#playerresize
     * @type {EventTarget~Event}
     */
    // make sure player is still around to trigger
    // prevents this from causing an error after dispose
    if (!this.player_ || !this.player_.trigger) {
      return;
    }

    this.player_.trigger('playerresize');
  };

  _proto.dispose = function dispose() {
    if (this.debouncedHandler_) {
      this.debouncedHandler_.cancel();
    }

    if (this.resizeObserver_) {
      if (this.player_.el()) {
        this.resizeObserver_.unobserve(this.player_.el());
      }

      this.resizeObserver_.disconnect();
    }

    if (this.loadListener_) {
      this.off('load', this.loadListener_);
    }

    if (this.el_ && this.el_.contentWindow && this.unloadListener_) {
      this.unloadListener_.call(this.el_.contentWindow);
    }

    this.ResizeObserver = null;
    this.resizeObserver = null;
    this.debouncedHandler_ = null;
    this.loadListener_ = null;

    _Component.prototype.dispose.call(this);
  };

  return ResizeManager;
}(Component);

Component.registerComponent('ResizeManager', ResizeManager);

var defaults = {
  trackingThreshold: 20,
  liveTolerance: 15
};
/*
  track when we are at the live edge, and other helpers for live playback */

/**
 * A class for checking live current time and determining when the player
 * is at or behind the live edge.
 */

var LiveTracker = /*#__PURE__*/function (_Component) {
  _inheritsLoose__default['default'](LiveTracker, _Component);

  /**
   * Creates an instance of this class.
   *
   * @param {Player} player
   *        The `Player` that this class should be attached to.
   *
   * @param {Object} [options]
   *        The key/value store of player options.
   *
   * @param {number} [options.trackingThreshold=20]
   *        Number of seconds of live window (seekableEnd - seekableStart) that
   *        media needs to have before the liveui will be shown.
   *
   * @param {number} [options.liveTolerance=15]
   *        Number of seconds behind live that we have to be
   *        before we will be considered non-live. Note that this will only
   *        be used when playing at the live edge. This allows large seekable end
   *        changes to not effect wether we are live or not.
   */
  function LiveTracker(player, options) {
    var _this;

    // LiveTracker does not need an element
    var options_ = mergeOptions(defaults, options, {
      createEl: false
    });
    _this = _Component.call(this, player, options_) || this;

    _this.handleVisibilityChange_ = function (e) {
      return _this.handleVisibilityChange(e);
    };

    _this.trackLiveHandler_ = function () {
      return _this.trackLive_();
    };

    _this.handlePlay_ = function (e) {
      return _this.handlePlay(e);
    };

    _this.handleFirstTimeupdate_ = function (e) {
      return _this.handleFirstTimeupdate(e);
    };

    _this.handleSeeked_ = function (e) {
      return _this.handleSeeked(e);
    };

    _this.seekToLiveEdge_ = function (e) {
      return _this.seekToLiveEdge(e);
    };

    _this.reset_();

    _this.on(_this.player_, 'durationchange', function (e) {
      return _this.handleDurationchange(e);
    }); // we should try to toggle tracking on canplay as native playback engines, like Safari
    // may not have the proper values for things like seekableEnd until then


    _this.on(_this.player_, 'canplay', function () {
      return _this.toggleTracking();
    }); // we don't need to track live playback if the document is hidden,
    // also, tracking when the document is hidden can
    // cause the CPU to spike and eventually crash the page on IE11.


    if (IE_VERSION && 'hidden' in document__default['default'] && 'visibilityState' in document__default['default']) {
      _this.on(document__default['default'], 'visibilitychange', _this.handleVisibilityChange_);
    }

    return _this;
  }
  /**
   * toggle tracking based on document visiblility
   */


  var _proto = LiveTracker.prototype;

  _proto.handleVisibilityChange = function handleVisibilityChange() {
    if (this.player_.duration() !== Infinity) {
      return;
    }

    if (document__default['default'].hidden) {
      this.stopTracking();
    } else {
      this.startTracking();
    }
  }
  /**
   * all the functionality for tracking when seek end changes
   * and for tracking how far past seek end we should be
   */
  ;

  _proto.trackLive_ = function trackLive_() {
    var seekable = this.player_.seekable(); // skip undefined seekable

    if (!seekable || !seekable.length) {
      return;
    }

    var newTime = Number(window__default['default'].performance.now().toFixed(4));
    var deltaTime = this.lastTime_ === -1 ? 0 : (newTime - this.lastTime_) / 1000;
    this.lastTime_ = newTime;
    this.pastSeekEnd_ = this.pastSeekEnd() + deltaTime;
    var liveCurrentTime = this.liveCurrentTime();
    var currentTime = this.player_.currentTime(); // we are behind live if any are true
    // 1. the player is paused
    // 2. the user seeked to a location 2 seconds away from live
    // 3. the difference between live and current time is greater
    //    liveTolerance which defaults to 15s

    var isBehind = this.player_.paused() || this.seekedBehindLive_ || Math.abs(liveCurrentTime - currentTime) > this.options_.liveTolerance; // we cannot be behind if
    // 1. until we have not seen a timeupdate yet
    // 2. liveCurrentTime is Infinity, which happens on Android and Native Safari

    if (!this.timeupdateSeen_ || liveCurrentTime === Infinity) {
      isBehind = false;
    }

    if (isBehind !== this.behindLiveEdge_) {
      this.behindLiveEdge_ = isBehind;
      this.trigger('liveedgechange');
    }
  }
  /**
   * handle a durationchange event on the player
   * and start/stop tracking accordingly.
   */
  ;

  _proto.handleDurationchange = function handleDurationchange() {
    this.toggleTracking();
  }
  /**
   * start/stop tracking
   */
  ;

  _proto.toggleTracking = function toggleTracking() {
    if (this.player_.duration() === Infinity && this.liveWindow() >= this.options_.trackingThreshold) {
      if (this.player_.options_.liveui) {
        this.player_.addClass('vjs-liveui');
      }

      this.startTracking();
    } else {
      this.player_.removeClass('vjs-liveui');
      this.stopTracking();
    }
  }
  /**
   * start tracking live playback
   */
  ;

  _proto.startTracking = function startTracking() {
    if (this.isTracking()) {
      return;
    } // If we haven't seen a timeupdate, we need to check whether playback
    // began before this component started tracking. This can happen commonly
    // when using autoplay.


    if (!this.timeupdateSeen_) {
      this.timeupdateSeen_ = this.player_.hasStarted();
    }

    this.trackingInterval_ = this.setInterval(this.trackLiveHandler_, UPDATE_REFRESH_INTERVAL);
    this.trackLive_();
    this.on(this.player_, ['play', 'pause'], this.trackLiveHandler_);

    if (!this.timeupdateSeen_) {
      this.one(this.player_, 'play', this.handlePlay_);
      this.one(this.player_, 'timeupdate', this.handleFirstTimeupdate_);
    } else {
      this.on(this.player_, 'seeked', this.handleSeeked_);
    }
  }
  /**
   * handle the first timeupdate on the player if it wasn't already playing
   * when live tracker started tracking.
   */
  ;

  _proto.handleFirstTimeupdate = function handleFirstTimeupdate() {
    this.timeupdateSeen_ = true;
    this.on(this.player_, 'seeked', this.handleSeeked_);
  }
  /**
   * Keep track of what time a seek starts, and listen for seeked
   * to find where a seek ends.
   */
  ;

  _proto.handleSeeked = function handleSeeked() {
    var timeDiff = Math.abs(this.liveCurrentTime() - this.player_.currentTime());
    this.seekedBehindLive_ = this.nextSeekedFromUser_ && timeDiff > 2;
    this.nextSeekedFromUser_ = false;
    this.trackLive_();
  }
  /**
   * handle the first play on the player, and make sure that we seek
   * right to the live edge.
   */
  ;

  _proto.handlePlay = function handlePlay() {
    this.one(this.player_, 'timeupdate', this.seekToLiveEdge_);
  }
  /**
   * Stop tracking, and set all internal variables to
   * their initial value.
   */
  ;

  _proto.reset_ = function reset_() {
    this.lastTime_ = -1;
    this.pastSeekEnd_ = 0;
    this.lastSeekEnd_ = -1;
    this.behindLiveEdge_ = true;
    this.timeupdateSeen_ = false;
    this.seekedBehindLive_ = false;
    this.nextSeekedFromUser_ = false;
    this.clearInterval(this.trackingInterval_);
    this.trackingInterval_ = null;
    this.off(this.player_, ['play', 'pause'], this.trackLiveHandler_);
    this.off(this.player_, 'seeked', this.handleSeeked_);
    this.off(this.player_, 'play', this.handlePlay_);
    this.off(this.player_, 'timeupdate', this.handleFirstTimeupdate_);
    this.off(this.player_, 'timeupdate', this.seekToLiveEdge_);
  }
  /**
   * The next seeked event is from the user. Meaning that any seek
   * > 2s behind live will be considered behind live for real and
   * liveTolerance will be ignored.
   */
  ;

  _proto.nextSeekedFromUser = function nextSeekedFromUser() {
    this.nextSeekedFromUser_ = true;
  }
  /**
   * stop tracking live playback
   */
  ;

  _proto.stopTracking = function stopTracking() {
    if (!this.isTracking()) {
      return;
    }

    this.reset_();
    this.trigger('liveedgechange');
  }
  /**
   * A helper to get the player seekable end
   * so that we don't have to null check everywhere
   *
   * @return {number}
   *         The furthest seekable end or Infinity.
   */
  ;

  _proto.seekableEnd = function seekableEnd() {
    var seekable = this.player_.seekable();
    var seekableEnds = [];
    var i = seekable ? seekable.length : 0;

    while (i--) {
      seekableEnds.push(seekable.end(i));
    } // grab the furthest seekable end after sorting, or if there are none
    // default to Infinity


    return seekableEnds.length ? seekableEnds.sort()[seekableEnds.length - 1] : Infinity;
  }
  /**
   * A helper to get the player seekable start
   * so that we don't have to null check everywhere
   *
   * @return {number}
   *         The earliest seekable start or 0.
   */
  ;

  _proto.seekableStart = function seekableStart() {
    var seekable = this.player_.seekable();
    var seekableStarts = [];
    var i = seekable ? seekable.length : 0;

    while (i--) {
      seekableStarts.push(seekable.start(i));
    } // grab the first seekable start after sorting, or if there are none
    // default to 0


    return seekableStarts.length ? seekableStarts.sort()[0] : 0;
  }
  /**
   * Get the live time window aka
   * the amount of time between seekable start and
   * live current time.
   *
   * @return {number}
   *         The amount of seconds that are seekable in
   *         the live video.
   */
  ;

  _proto.liveWindow = function liveWindow() {
    var liveCurrentTime = this.liveCurrentTime(); // if liveCurrenTime is Infinity then we don't have a liveWindow at all

    if (liveCurrentTime === Infinity) {
      return 0;
    }

    return liveCurrentTime - this.seekableStart();
  }
  /**
   * Determines if the player is live, only checks if this component
   * is tracking live playback or not
   *
   * @return {boolean}
   *         Wether liveTracker is tracking
   */
  ;

  _proto.isLive = function isLive() {
    return this.isTracking();
  }
  /**
   * Determines if currentTime is at the live edge and won't fall behind
   * on each seekableendchange
   *
   * @return {boolean}
   *         Wether playback is at the live edge
   */
  ;

  _proto.atLiveEdge = function atLiveEdge() {
    return !this.behindLiveEdge();
  }
  /**
   * get what we expect the live current time to be
   *
   * @return {number}
   *         The expected live current time
   */
  ;

  _proto.liveCurrentTime = function liveCurrentTime() {
    return this.pastSeekEnd() + this.seekableEnd();
  }
  /**
   * The number of seconds that have occured after seekable end
   * changed. This will be reset to 0 once seekable end changes.
   *
   * @return {number}
   *         Seconds past the current seekable end
   */
  ;

  _proto.pastSeekEnd = function pastSeekEnd() {
    var seekableEnd = this.seekableEnd();

    if (this.lastSeekEnd_ !== -1 && seekableEnd !== this.lastSeekEnd_) {
      this.pastSeekEnd_ = 0;
    }

    this.lastSeekEnd_ = seekableEnd;
    return this.pastSeekEnd_;
  }
  /**
   * If we are currently behind the live edge, aka currentTime will be
   * behind on a seekableendchange
   *
   * @return {boolean}
   *         If we are behind the live edge
   */
  ;

  _proto.behindLiveEdge = function behindLiveEdge() {
    return this.behindLiveEdge_;
  }
  /**
   * Wether live tracker is currently tracking or not.
   */
  ;

  _proto.isTracking = function isTracking() {
    return typeof this.trackingInterval_ === 'number';
  }
  /**
   * Seek to the live edge if we are behind the live edge
   */
  ;

  _proto.seekToLiveEdge = function seekToLiveEdge() {
    this.seekedBehindLive_ = false;

    if (this.atLiveEdge()) {
      return;
    }

    this.nextSeekedFromUser_ = false;
    this.player_.currentTime(this.liveCurrentTime());
  }
  /**
   * Dispose of liveTracker
   */
  ;

  _proto.dispose = function dispose() {
    this.off(document__default['default'], 'visibilitychange', this.handleVisibilityChange_);
    this.stopTracking();

    _Component.prototype.dispose.call(this);
  };

  return LiveTracker;
}(Component);

Component.registerComponent('LiveTracker', LiveTracker);

/**
 * This function is used to fire a sourceset when there is something
 * similar to `mediaEl.load()` being called. It will try to find the source via
 * the `src` attribute and then the `<source>` elements. It will then fire `sourceset`
 * with the source that was found or empty string if we cannot know. If it cannot
 * find a source then `sourceset` will not be fired.
 *
 * @param {Html5} tech
 *        The tech object that sourceset was setup on
 *
 * @return {boolean}
 *         returns false if the sourceset was not fired and true otherwise.
 */

var sourcesetLoad = function sourcesetLoad(tech) {
  var el = tech.el(); // if `el.src` is set, that source will be loaded.

  if (el.hasAttribute('src')) {
    tech.triggerSourceset(el.src);
    return true;
  }
  /**
   * Since there isn't a src property on the media element, source elements will be used for
   * implementing the source selection algorithm. This happens asynchronously and
   * for most cases were there is more than one source we cannot tell what source will
   * be loaded, without re-implementing the source selection algorithm. At this time we are not
   * going to do that. There are three special cases that we do handle here though:
   *
   * 1. If there are no sources, do not fire `sourceset`.
   * 2. If there is only one `<source>` with a `src` property/attribute that is our `src`
   * 3. If there is more than one `<source>` but all of them have the same `src` url.
   *    That will be our src.
   */


  var sources = tech.$$('source');
  var srcUrls = [];
  var src = ''; // if there are no sources, do not fire sourceset

  if (!sources.length) {
    return false;
  } // only count valid/non-duplicate source elements


  for (var i = 0; i < sources.length; i++) {
    var url = sources[i].src;

    if (url && srcUrls.indexOf(url) === -1) {
      srcUrls.push(url);
    }
  } // there were no valid sources


  if (!srcUrls.length) {
    return false;
  } // there is only one valid source element url
  // use that


  if (srcUrls.length === 1) {
    src = srcUrls[0];
  }

  tech.triggerSourceset(src);
  return true;
};
/**
 * our implementation of an `innerHTML` descriptor for browsers
 * that do not have one.
 */


var innerHTMLDescriptorPolyfill = Object.defineProperty({}, 'innerHTML', {
  get: function get() {
    return this.cloneNode(true).innerHTML;
  },
  set: function set(v) {
    // make a dummy node to use innerHTML on
    var dummy = document__default['default'].createElement(this.nodeName.toLowerCase()); // set innerHTML to the value provided

    dummy.innerHTML = v; // make a document fragment to hold the nodes from dummy

    var docFrag = document__default['default'].createDocumentFragment(); // copy all of the nodes created by the innerHTML on dummy
    // to the document fragment

    while (dummy.childNodes.length) {
      docFrag.appendChild(dummy.childNodes[0]);
    } // remove content


    this.innerText = ''; // now we add all of that html in one by appending the
    // document fragment. This is how innerHTML does it.

    window__default['default'].Element.prototype.appendChild.call(this, docFrag); // then return the result that innerHTML's setter would

    return this.innerHTML;
  }
});
/**
 * Get a property descriptor given a list of priorities and the
 * property to get.
 */

var getDescriptor = function getDescriptor(priority, prop) {
  var descriptor = {};

  for (var i = 0; i < priority.length; i++) {
    descriptor = Object.getOwnPropertyDescriptor(priority[i], prop);

    if (descriptor && descriptor.set && descriptor.get) {
      break;
    }
  }

  descriptor.enumerable = true;
  descriptor.configurable = true;
  return descriptor;
};

var getInnerHTMLDescriptor = function getInnerHTMLDescriptor(tech) {
  return getDescriptor([tech.el(), window__default['default'].HTMLMediaElement.prototype, window__default['default'].Element.prototype, innerHTMLDescriptorPolyfill], 'innerHTML');
};
/**
 * Patches browser internal functions so that we can tell synchronously
 * if a `<source>` was appended to the media element. For some reason this
 * causes a `sourceset` if the the media element is ready and has no source.
 * This happens when:
 * - The page has just loaded and the media element does not have a source.
 * - The media element was emptied of all sources, then `load()` was called.
 *
 * It does this by patching the following functions/properties when they are supported:
 *
 * - `append()` - can be used to add a `<source>` element to the media element
 * - `appendChild()` - can be used to add a `<source>` element to the media element
 * - `insertAdjacentHTML()` -  can be used to add a `<source>` element to the media element
 * - `innerHTML` -  can be used to add a `<source>` element to the media element
 *
 * @param {Html5} tech
 *        The tech object that sourceset is being setup on.
 */


var firstSourceWatch = function firstSourceWatch(tech) {
  var el = tech.el(); // make sure firstSourceWatch isn't setup twice.

  if (el.resetSourceWatch_) {
    return;
  }

  var old = {};
  var innerDescriptor = getInnerHTMLDescriptor(tech);

  var appendWrapper = function appendWrapper(appendFn) {
    return function () {
      for (var _len = arguments.length, args = new Array(_len), _key = 0; _key < _len; _key++) {
        args[_key] = arguments[_key];
      }

      var retval = appendFn.apply(el, args);
      sourcesetLoad(tech);
      return retval;
    };
  };

  ['append', 'appendChild', 'insertAdjacentHTML'].forEach(function (k) {
    if (!el[k]) {
      return;
    } // store the old function


    old[k] = el[k]; // call the old function with a sourceset if a source
    // was loaded

    el[k] = appendWrapper(old[k]);
  });
  Object.defineProperty(el, 'innerHTML', mergeOptions(innerDescriptor, {
    set: appendWrapper(innerDescriptor.set)
  }));

  el.resetSourceWatch_ = function () {
    el.resetSourceWatch_ = null;
    Object.keys(old).forEach(function (k) {
      el[k] = old[k];
    });
    Object.defineProperty(el, 'innerHTML', innerDescriptor);
  }; // on the first sourceset, we need to revert our changes


  tech.one('sourceset', el.resetSourceWatch_);
};
/**
 * our implementation of a `src` descriptor for browsers
 * that do not have one.
 */


var srcDescriptorPolyfill = Object.defineProperty({}, 'src', {
  get: function get() {
    if (this.hasAttribute('src')) {
      return getAbsoluteURL(window__default['default'].Element.prototype.getAttribute.call(this, 'src'));
    }

    return '';
  },
  set: function set(v) {
    window__default['default'].Element.prototype.setAttribute.call(this, 'src', v);
    return v;
  }
});

var getSrcDescriptor = function getSrcDescriptor(tech) {
  return getDescriptor([tech.el(), window__default['default'].HTMLMediaElement.prototype, srcDescriptorPolyfill], 'src');
};
/**
 * setup `sourceset` handling on the `Html5` tech. This function
 * patches the following element properties/functions:
 *
 * - `src` - to determine when `src` is set
 * - `setAttribute()` - to determine when `src` is set
 * - `load()` - this re-triggers the source selection algorithm, and can
 *              cause a sourceset.
 *
 * If there is no source when we are adding `sourceset` support or during a `load()`
 * we also patch the functions listed in `firstSourceWatch`.
 *
 * @param {Html5} tech
 *        The tech to patch
 */


var setupSourceset = function setupSourceset(tech) {
  if (!tech.featuresSourceset) {
    return;
  }

  var el = tech.el(); // make sure sourceset isn't setup twice.

  if (el.resetSourceset_) {
    return;
  }

  var srcDescriptor = getSrcDescriptor(tech);
  var oldSetAttribute = el.setAttribute;
  var oldLoad = el.load;
  Object.defineProperty(el, 'src', mergeOptions(srcDescriptor, {
    set: function set(v) {
      var retval = srcDescriptor.set.call(el, v); // we use the getter here to get the actual value set on src

      tech.triggerSourceset(el.src);
      return retval;
    }
  }));

  el.setAttribute = function (n, v) {
    var retval = oldSetAttribute.call(el, n, v);

    if (/src/i.test(n)) {
      tech.triggerSourceset(el.src);
    }

    return retval;
  };

  el.load = function () {
    var retval = oldLoad.call(el); // if load was called, but there was no source to fire
    // sourceset on. We have to watch for a source append
    // as that can trigger a `sourceset` when the media element
    // has no source

    if (!sourcesetLoad(tech)) {
      tech.triggerSourceset('');
      firstSourceWatch(tech);
    }

    return retval;
  };

  if (el.currentSrc) {
    tech.triggerSourceset(el.currentSrc);
  } else if (!sourcesetLoad(tech)) {
    firstSourceWatch(tech);
  }

  el.resetSourceset_ = function () {
    el.resetSourceset_ = null;
    el.load = oldLoad;
    el.setAttribute = oldSetAttribute;
    Object.defineProperty(el, 'src', srcDescriptor);

    if (el.resetSourceWatch_) {
      el.resetSourceWatch_();
    }
  };
};

/**
 * Object.defineProperty but "lazy", which means that the value is only set after
 * it retrieved the first time, rather than being set right away.
 *
 * @param {Object} obj the object to set the property on
 * @param {string} key the key for the property to set
 * @param {Function} getValue the function used to get the value when it is needed.
 * @param {boolean} setter wether a setter shoould be allowed or not
 */
var defineLazyProperty = function defineLazyProperty(obj, key, getValue, setter) {
  if (setter === void 0) {
    setter = true;
  }

  var set = function set(value) {
    return Object.defineProperty(obj, key, {
      value: value,
      enumerable: true,
      writable: true
    });
  };

  var options = {
    configurable: true,
    enumerable: true,
    get: function get() {
      var value = getValue();
      set(value);
      return value;
    }
  };

  if (setter) {
    options.set = set;
  }

  return Object.defineProperty(obj, key, options);
};

/**
 * HTML5 Media Controller - Wrapper for HTML5 Media API
 *
 * @mixes Tech~SourceHandlerAdditions
 * @extends Tech
 */

var Html5 = /*#__PURE__*/function (_Tech) {
  _inheritsLoose__default['default'](Html5, _Tech);

  /**
  * Create an instance of this Tech.
  *
  * @param {Object} [options]
  *        The key/value store of player options.
  *
  * @param {Component~ReadyCallback} ready
  *        Callback function to call when the `HTML5` Tech is ready.
  */
  function Html5(options, ready) {
    var _this;

    _this = _Tech.call(this, options, ready) || this;
    var source = options.source;
    var crossoriginTracks = false; // Set the source if one is provided
    // 1) Check if the source is new (if not, we want to keep the original so playback isn't interrupted)
    // 2) Check to see if the network state of the tag was failed at init, and if so, reset the source
    // anyway so the error gets fired.

    if (source && (_this.el_.currentSrc !== source.src || options.tag && options.tag.initNetworkState_ === 3)) {
      _this.setSource(source);
    } else {
      _this.handleLateInit_(_this.el_);
    } // setup sourceset after late sourceset/init


    if (options.enableSourceset) {
      _this.setupSourcesetHandling_();
    }

    _this.isScrubbing_ = false;

    if (_this.el_.hasChildNodes()) {
      var nodes = _this.el_.childNodes;
      var nodesLength = nodes.length;
      var removeNodes = [];

      while (nodesLength--) {
        var node = nodes[nodesLength];
        var nodeName = node.nodeName.toLowerCase();

        if (nodeName === 'track') {
          if (!_this.featuresNativeTextTracks) {
            // Empty video tag tracks so the built-in player doesn't use them also.
            // This may not be fast enough to stop HTML5 browsers from reading the tags
            // so we'll need to turn off any default tracks if we're manually doing
            // captions and subtitles. videoElement.textTracks
            removeNodes.push(node);
          } else {
            // store HTMLTrackElement and TextTrack to remote list
            _this.remoteTextTrackEls().addTrackElement_(node);

            _this.remoteTextTracks().addTrack(node.track);

            _this.textTracks().addTrack(node.track);

            if (!crossoriginTracks && !_this.el_.hasAttribute('crossorigin') && isCrossOrigin(node.src)) {
              crossoriginTracks = true;
            }
          }
        }
      }

      for (var i = 0; i < removeNodes.length; i++) {
        _this.el_.removeChild(removeNodes[i]);
      }
    }

    _this.proxyNativeTracks_();

    if (_this.featuresNativeTextTracks && crossoriginTracks) {
      log.warn('Text Tracks are being loaded from another origin but the crossorigin attribute isn\'t used.\n' + 'This may prevent text tracks from loading.');
    } // prevent iOS Safari from disabling metadata text tracks during native playback


    _this.restoreMetadataTracksInIOSNativePlayer_(); // Determine if native controls should be used
    // Our goal should be to get the custom controls on mobile solid everywhere
    // so we can remove this all together. Right now this will block custom
    // controls on touch enabled laptops like the Chrome Pixel


    if ((TOUCH_ENABLED || IS_IPHONE || IS_NATIVE_ANDROID) && options.nativeControlsForTouch === true) {
      _this.setControls(true);
    } // on iOS, we want to proxy `webkitbeginfullscreen` and `webkitendfullscreen`
    // into a `fullscreenchange` event


    _this.proxyWebkitFullscreen_();

    _this.triggerReady();

    return _this;
  }
  /**
   * Dispose of `HTML5` media element and remove all tracks.
   */


  var _proto = Html5.prototype;

  _proto.dispose = function dispose() {
    if (this.el_ && this.el_.resetSourceset_) {
      this.el_.resetSourceset_();
    }

    Html5.disposeMediaElement(this.el_);
    this.options_ = null; // tech will handle clearing of the emulated track list

    _Tech.prototype.dispose.call(this);
  }
  /**
   * Modify the media element so that we can detect when
   * the source is changed. Fires `sourceset` just after the source has changed
   */
  ;

  _proto.setupSourcesetHandling_ = function setupSourcesetHandling_() {
    setupSourceset(this);
  }
  /**
   * When a captions track is enabled in the iOS Safari native player, all other
   * tracks are disabled (including metadata tracks), which nulls all of their
   * associated cue points. This will restore metadata tracks to their pre-fullscreen
   * state in those cases so that cue points are not needlessly lost.
   *
   * @private
   */
  ;

  _proto.restoreMetadataTracksInIOSNativePlayer_ = function restoreMetadataTracksInIOSNativePlayer_() {
    var textTracks = this.textTracks();
    var metadataTracksPreFullscreenState; // captures a snapshot of every metadata track's current state

    var takeMetadataTrackSnapshot = function takeMetadataTrackSnapshot() {
      metadataTracksPreFullscreenState = [];

      for (var i = 0; i < textTracks.length; i++) {
        var track = textTracks[i];

        if (track.kind === 'metadata') {
          metadataTracksPreFullscreenState.push({
            track: track,
            storedMode: track.mode
          });
        }
      }
    }; // snapshot each metadata track's initial state, and update the snapshot
    // each time there is a track 'change' event


    takeMetadataTrackSnapshot();
    textTracks.addEventListener('change', takeMetadataTrackSnapshot);
    this.on('dispose', function () {
      return textTracks.removeEventListener('change', takeMetadataTrackSnapshot);
    });

    var restoreTrackMode = function restoreTrackMode() {
      for (var i = 0; i < metadataTracksPreFullscreenState.length; i++) {
        var storedTrack = metadataTracksPreFullscreenState[i];

        if (storedTrack.track.mode === 'disabled' && storedTrack.track.mode !== storedTrack.storedMode) {
          storedTrack.track.mode = storedTrack.storedMode;
        }
      } // we only want this handler to be executed on the first 'change' event


      textTracks.removeEventListener('change', restoreTrackMode);
    }; // when we enter fullscreen playback, stop updating the snapshot and
    // restore all track modes to their pre-fullscreen state


    this.on('webkitbeginfullscreen', function () {
      textTracks.removeEventListener('change', takeMetadataTrackSnapshot); // remove the listener before adding it just in case it wasn't previously removed

      textTracks.removeEventListener('change', restoreTrackMode);
      textTracks.addEventListener('change', restoreTrackMode);
    }); // start updating the snapshot again after leaving fullscreen

    this.on('webkitendfullscreen', function () {
      // remove the listener before adding it just in case it wasn't previously removed
      textTracks.removeEventListener('change', takeMetadataTrackSnapshot);
      textTracks.addEventListener('change', takeMetadataTrackSnapshot); // remove the restoreTrackMode handler in case it wasn't triggered during fullscreen playback

      textTracks.removeEventListener('change', restoreTrackMode);
    });
  }
  /**
   * Attempt to force override of tracks for the given type
   *
   * @param {string} type - Track type to override, possible values include 'Audio',
   * 'Video', and 'Text'.
   * @param {boolean} override - If set to true native audio/video will be overridden,
   * otherwise native audio/video will potentially be used.
   * @private
   */
  ;

  _proto.overrideNative_ = function overrideNative_(type, override) {
    var _this2 = this;

    // If there is no behavioral change don't add/remove listeners
    if (override !== this["featuresNative" + type + "Tracks"]) {
      return;
    }

    var lowerCaseType = type.toLowerCase();

    if (this[lowerCaseType + "TracksListeners_"]) {
      Object.keys(this[lowerCaseType + "TracksListeners_"]).forEach(function (eventName) {
        var elTracks = _this2.el()[lowerCaseType + "Tracks"];

        elTracks.removeEventListener(eventName, _this2[lowerCaseType + "TracksListeners_"][eventName]);
      });
    }

    this["featuresNative" + type + "Tracks"] = !override;
    this[lowerCaseType + "TracksListeners_"] = null;
    this.proxyNativeTracksForType_(lowerCaseType);
  }
  /**
   * Attempt to force override of native audio tracks.
   *
   * @param {boolean} override - If set to true native audio will be overridden,
   * otherwise native audio will potentially be used.
   */
  ;

  _proto.overrideNativeAudioTracks = function overrideNativeAudioTracks(override) {
    this.overrideNative_('Audio', override);
  }
  /**
   * Attempt to force override of native video tracks.
   *
   * @param {boolean} override - If set to true native video will be overridden,
   * otherwise native video will potentially be used.
   */
  ;

  _proto.overrideNativeVideoTracks = function overrideNativeVideoTracks(override) {
    this.overrideNative_('Video', override);
  }
  /**
   * Proxy native track list events for the given type to our track
   * lists if the browser we are playing in supports that type of track list.
   *
   * @param {string} name - Track type; values include 'audio', 'video', and 'text'
   * @private
   */
  ;

  _proto.proxyNativeTracksForType_ = function proxyNativeTracksForType_(name) {
    var _this3 = this;

    var props = NORMAL[name];
    var elTracks = this.el()[props.getterName];
    var techTracks = this[props.getterName]();

    if (!this["featuresNative" + props.capitalName + "Tracks"] || !elTracks || !elTracks.addEventListener) {
      return;
    }

    var listeners = {
      change: function change(e) {
        var event = {
          type: 'change',
          target: techTracks,
          currentTarget: techTracks,
          srcElement: techTracks
        };
        techTracks.trigger(event); // if we are a text track change event, we should also notify the
        // remote text track list. This can potentially cause a false positive
        // if we were to get a change event on a non-remote track and
        // we triggered the event on the remote text track list which doesn't
        // contain that track. However, best practices mean looping through the
        // list of tracks and searching for the appropriate mode value, so,
        // this shouldn't pose an issue

        if (name === 'text') {
          _this3[REMOTE.remoteText.getterName]().trigger(event);
        }
      },
      addtrack: function addtrack(e) {
        techTracks.addTrack(e.track);
      },
      removetrack: function removetrack(e) {
        techTracks.removeTrack(e.track);
      }
    };

    var removeOldTracks = function removeOldTracks() {
      var removeTracks = [];

      for (var i = 0; i < techTracks.length; i++) {
        var found = false;

        for (var j = 0; j < elTracks.length; j++) {
          if (elTracks[j] === techTracks[i]) {
            found = true;
            break;
          }
        }

        if (!found) {
          removeTracks.push(techTracks[i]);
        }
      }

      while (removeTracks.length) {
        techTracks.removeTrack(removeTracks.shift());
      }
    };

    this[props.getterName + 'Listeners_'] = listeners;
    Object.keys(listeners).forEach(function (eventName) {
      var listener = listeners[eventName];
      elTracks.addEventListener(eventName, listener);

      _this3.on('dispose', function (e) {
        return elTracks.removeEventListener(eventName, listener);
      });
    }); // Remove (native) tracks that are not used anymore

    this.on('loadstart', removeOldTracks);
    this.on('dispose', function (e) {
      return _this3.off('loadstart', removeOldTracks);
    });
  }
  /**
   * Proxy all native track list events to our track lists if the browser we are playing
   * in supports that type of track list.
   *
   * @private
   */
  ;

  _proto.proxyNativeTracks_ = function proxyNativeTracks_() {
    var _this4 = this;

    NORMAL.names.forEach(function (name) {
      _this4.proxyNativeTracksForType_(name);
    });
  }
  /**
   * Create the `Html5` Tech's DOM element.
   *
   * @return {Element}
   *         The element that gets created.
   */
  ;

  _proto.createEl = function createEl() {
    var el = this.options_.tag; // Check if this browser supports moving the element into the box.
    // On the iPhone video will break if you move the element,
    // So we have to create a brand new element.
    // If we ingested the player div, we do not need to move the media element.

    if (!el || !(this.options_.playerElIngest || this.movingMediaElementInDOM)) {
      // If the original tag is still there, clone and remove it.
      if (el) {
        var clone = el.cloneNode(true);

        if (el.parentNode) {
          el.parentNode.insertBefore(clone, el);
        }

        Html5.disposeMediaElement(el);
        el = clone;
      } else {
        el = document__default['default'].createElement('video'); // determine if native controls should be used

        var tagAttributes = this.options_.tag && getAttributes(this.options_.tag);
        var attributes = mergeOptions({}, tagAttributes);

        if (!TOUCH_ENABLED || this.options_.nativeControlsForTouch !== true) {
          delete attributes.controls;
        }

        setAttributes(el, assign(attributes, {
          id: this.options_.techId,
          "class": 'vjs-tech'
        }));
      }

      el.playerId = this.options_.playerId;
    }

    if (typeof this.options_.preload !== 'undefined') {
      setAttribute(el, 'preload', this.options_.preload);
    }

    if (this.options_.disablePictureInPicture !== undefined) {
      el.disablePictureInPicture = this.options_.disablePictureInPicture;
    } // Update specific tag settings, in case they were overridden
    // `autoplay` has to be *last* so that `muted` and `playsinline` are present
    // when iOS/Safari or other browsers attempt to autoplay.


    var settingsAttrs = ['loop', 'muted', 'playsinline', 'autoplay'];

    for (var i = 0; i < settingsAttrs.length; i++) {
      var attr = settingsAttrs[i];
      var value = this.options_[attr];

      if (typeof value !== 'undefined') {
        if (value) {
          setAttribute(el, attr, attr);
        } else {
          removeAttribute(el, attr);
        }

        el[attr] = value;
      }
    }

    return el;
  }
  /**
   * This will be triggered if the loadstart event has already fired, before videojs was
   * ready. Two known examples of when this can happen are:
   * 1. If we're loading the playback object after it has started loading
   * 2. The media is already playing the (often with autoplay on) then
   *
   * This function will fire another loadstart so that videojs can catchup.
   *
   * @fires Tech#loadstart
   *
   * @return {undefined}
   *         returns nothing.
   */
  ;

  _proto.handleLateInit_ = function handleLateInit_(el) {
    if (el.networkState === 0 || el.networkState === 3) {
      // The video element hasn't started loading the source yet
      // or didn't find a source
      return;
    }

    if (el.readyState === 0) {
      // NetworkState is set synchronously BUT loadstart is fired at the
      // end of the current stack, usually before setInterval(fn, 0).
      // So at this point we know loadstart may have already fired or is
      // about to fire, and either way the player hasn't seen it yet.
      // We don't want to fire loadstart prematurely here and cause a
      // double loadstart so we'll wait and see if it happens between now
      // and the next loop, and fire it if not.
      // HOWEVER, we also want to make sure it fires before loadedmetadata
      // which could also happen between now and the next loop, so we'll
      // watch for that also.
      var loadstartFired = false;

      var setLoadstartFired = function setLoadstartFired() {
        loadstartFired = true;
      };

      this.on('loadstart', setLoadstartFired);

      var triggerLoadstart = function triggerLoadstart() {
        // We did miss the original loadstart. Make sure the player
        // sees loadstart before loadedmetadata
        if (!loadstartFired) {
          this.trigger('loadstart');
        }
      };

      this.on('loadedmetadata', triggerLoadstart);
      this.ready(function () {
        this.off('loadstart', setLoadstartFired);
        this.off('loadedmetadata', triggerLoadstart);

        if (!loadstartFired) {
          // We did miss the original native loadstart. Fire it now.
          this.trigger('loadstart');
        }
      });
      return;
    } // From here on we know that loadstart already fired and we missed it.
    // The other readyState events aren't as much of a problem if we double
    // them, so not going to go to as much trouble as loadstart to prevent
    // that unless we find reason to.


    var eventsToTrigger = ['loadstart']; // loadedmetadata: newly equal to HAVE_METADATA (1) or greater

    eventsToTrigger.push('loadedmetadata'); // loadeddata: newly increased to HAVE_CURRENT_DATA (2) or greater

    if (el.readyState >= 2) {
      eventsToTrigger.push('loadeddata');
    } // canplay: newly increased to HAVE_FUTURE_DATA (3) or greater


    if (el.readyState >= 3) {
      eventsToTrigger.push('canplay');
    } // canplaythrough: newly equal to HAVE_ENOUGH_DATA (4)


    if (el.readyState >= 4) {
      eventsToTrigger.push('canplaythrough');
    } // We still need to give the player time to add event listeners


    this.ready(function () {
      eventsToTrigger.forEach(function (type) {
        this.trigger(type);
      }, this);
    });
  }
  /**
   * Set whether we are scrubbing or not.
   * This is used to decide whether we should use `fastSeek` or not.
   * `fastSeek` is used to provide trick play on Safari browsers.
   *
   * @param {boolean} isScrubbing
   *                  - true for we are currently scrubbing
   *                  - false for we are no longer scrubbing
   */
  ;

  _proto.setScrubbing = function setScrubbing(isScrubbing) {
    this.isScrubbing_ = isScrubbing;
  }
  /**
   * Get whether we are scrubbing or not.
   *
   * @return {boolean} isScrubbing
   *                  - true for we are currently scrubbing
   *                  - false for we are no longer scrubbing
   */
  ;

  _proto.scrubbing = function scrubbing() {
    return this.isScrubbing_;
  }
  /**
   * Set current time for the `HTML5` tech.
   *
   * @param {number} seconds
   *        Set the current time of the media to this.
   */
  ;

  _proto.setCurrentTime = function setCurrentTime(seconds) {
    try {
      if (this.isScrubbing_ && this.el_.fastSeek && IS_ANY_SAFARI) {
        this.el_.fastSeek(seconds);
      } else {
        this.el_.currentTime = seconds;
      }
    } catch (e) {
      log(e, 'Video is not ready. (Video.js)'); // this.warning(VideoJS.warnings.videoNotReady);
    }
  }
  /**
   * Get the current duration of the HTML5 media element.
   *
   * @return {number}
   *         The duration of the media or 0 if there is no duration.
   */
  ;

  _proto.duration = function duration() {
    var _this5 = this;

    // Android Chrome will report duration as Infinity for VOD HLS until after
    // playback has started, which triggers the live display erroneously.
    // Return NaN if playback has not started and trigger a durationupdate once
    // the duration can be reliably known.
    if (this.el_.duration === Infinity && IS_ANDROID && IS_CHROME && this.el_.currentTime === 0) {
      // Wait for the first `timeupdate` with currentTime > 0 - there may be
      // several with 0
      var checkProgress = function checkProgress() {
        if (_this5.el_.currentTime > 0) {
          // Trigger durationchange for genuinely live video
          if (_this5.el_.duration === Infinity) {
            _this5.trigger('durationchange');
          }

          _this5.off('timeupdate', checkProgress);
        }
      };

      this.on('timeupdate', checkProgress);
      return NaN;
    }

    return this.el_.duration || NaN;
  }
  /**
   * Get the current width of the HTML5 media element.
   *
   * @return {number}
   *         The width of the HTML5 media element.
   */
  ;

  _proto.width = function width() {
    return this.el_.offsetWidth;
  }
  /**
   * Get the current height of the HTML5 media element.
   *
   * @return {number}
   *         The height of the HTML5 media element.
   */
  ;

  _proto.height = function height() {
    return this.el_.offsetHeight;
  }
  /**
   * Proxy iOS `webkitbeginfullscreen` and `webkitendfullscreen` into
   * `fullscreenchange` event.
   *
   * @private
   * @fires fullscreenchange
   * @listens webkitendfullscreen
   * @listens webkitbeginfullscreen
   * @listens webkitbeginfullscreen
   */
  ;

  _proto.proxyWebkitFullscreen_ = function proxyWebkitFullscreen_() {
    var _this6 = this;

    if (!('webkitDisplayingFullscreen' in this.el_)) {
      return;
    }

    var endFn = function endFn() {
      this.trigger('fullscreenchange', {
        isFullscreen: false
      }); // Safari will sometimes set contols on the videoelement when existing fullscreen.

      if (this.el_.controls && !this.options_.nativeControlsForTouch && this.controls()) {
        this.el_.controls = false;
      }
    };

    var beginFn = function beginFn() {
      if ('webkitPresentationMode' in this.el_ && this.el_.webkitPresentationMode !== 'picture-in-picture') {
        this.one('webkitendfullscreen', endFn);
        this.trigger('fullscreenchange', {
          isFullscreen: true,
          // set a flag in case another tech triggers fullscreenchange
          nativeIOSFullscreen: true
        });
      }
    };

    this.on('webkitbeginfullscreen', beginFn);
    this.on('dispose', function () {
      _this6.off('webkitbeginfullscreen', beginFn);

      _this6.off('webkitendfullscreen', endFn);
    });
  }
  /**
   * Check if fullscreen is supported on the current playback device.
   *
   * @return {boolean}
   *         - True if fullscreen is supported.
   *         - False if fullscreen is not supported.
   */
  ;

  _proto.supportsFullScreen = function supportsFullScreen() {
    if (typeof this.el_.webkitEnterFullScreen === 'function') {
      var userAgent = window__default['default'].navigator && window__default['default'].navigator.userAgent || ''; // Seems to be broken in Chromium/Chrome && Safari in Leopard

      if (/Android/.test(userAgent) || !/Chrome|Mac OS X 10.5/.test(userAgent)) {
        return true;
      }
    }

    return false;
  }
  /**
   * Request that the `HTML5` Tech enter fullscreen.
   */
  ;

  _proto.enterFullScreen = function enterFullScreen() {
    var video = this.el_;

    if (video.paused && video.networkState <= video.HAVE_METADATA) {
      // attempt to prime the video element for programmatic access
      // this isn't necessary on the desktop but shouldn't hurt
      silencePromise(this.el_.play()); // playing and pausing synchronously during the transition to fullscreen
      // can get iOS ~6.1 devices into a play/pause loop

      this.setTimeout(function () {
        video.pause();

        try {
          video.webkitEnterFullScreen();
        } catch (e) {
          this.trigger('fullscreenerror', e);
        }
      }, 0);
    } else {
      try {
        video.webkitEnterFullScreen();
      } catch (e) {
        this.trigger('fullscreenerror', e);
      }
    }
  }
  /**
   * Request that the `HTML5` Tech exit fullscreen.
   */
  ;

  _proto.exitFullScreen = function exitFullScreen() {
    if (!this.el_.webkitDisplayingFullscreen) {
      this.trigger('fullscreenerror', new Error('The video is not fullscreen'));
      return;
    }

    this.el_.webkitExitFullScreen();
  }
  /**
   * Create a floating video window always on top of other windows so that users may
   * continue consuming media while they interact with other content sites, or
   * applications on their device.
   *
   * @see [Spec]{@link https://wicg.github.io/picture-in-picture}
   *
   * @return {Promise}
   *         A promise with a Picture-in-Picture window.
   */
  ;

  _proto.requestPictureInPicture = function requestPictureInPicture() {
    return this.el_.requestPictureInPicture();
  }
  /**
   * A getter/setter for the `Html5` Tech's source object.
   * > Note: Please use {@link Html5#setSource}
   *
   * @param {Tech~SourceObject} [src]
   *        The source object you want to set on the `HTML5` techs element.
   *
   * @return {Tech~SourceObject|undefined}
   *         - The current source object when a source is not passed in.
   *         - undefined when setting
   *
   * @deprecated Since version 5.
   */
  ;

  _proto.src = function src(_src) {
    if (_src === undefined) {
      return this.el_.src;
    } // Setting src through `src` instead of `setSrc` will be deprecated


    this.setSrc(_src);
  }
  /**
   * Reset the tech by removing all sources and then calling
   * {@link Html5.resetMediaElement}.
   */
  ;

  _proto.reset = function reset() {
    Html5.resetMediaElement(this.el_);
  }
  /**
   * Get the current source on the `HTML5` Tech. Falls back to returning the source from
   * the HTML5 media element.
   *
   * @return {Tech~SourceObject}
   *         The current source object from the HTML5 tech. With a fallback to the
   *         elements source.
   */
  ;

  _proto.currentSrc = function currentSrc() {
    if (this.currentSource_) {
      return this.currentSource_.src;
    }

    return this.el_.currentSrc;
  }
  /**
   * Set controls attribute for the HTML5 media Element.
   *
   * @param {string} val
   *        Value to set the controls attribute to
   */
  ;

  _proto.setControls = function setControls(val) {
    this.el_.controls = !!val;
  }
  /**
   * Create and returns a remote {@link TextTrack} object.
   *
   * @param {string} kind
   *        `TextTrack` kind (subtitles, captions, descriptions, chapters, or metadata)
   *
   * @param {string} [label]
   *        Label to identify the text track
   *
   * @param {string} [language]
   *        Two letter language abbreviation
   *
   * @return {TextTrack}
   *         The TextTrack that gets created.
   */
  ;

  _proto.addTextTrack = function addTextTrack(kind, label, language) {
    if (!this.featuresNativeTextTracks) {
      return _Tech.prototype.addTextTrack.call(this, kind, label, language);
    }

    return this.el_.addTextTrack(kind, label, language);
  }
  /**
   * Creates either native TextTrack or an emulated TextTrack depending
   * on the value of `featuresNativeTextTracks`
   *
   * @param {Object} options
   *        The object should contain the options to initialize the TextTrack with.
   *
   * @param {string} [options.kind]
   *        `TextTrack` kind (subtitles, captions, descriptions, chapters, or metadata).
   *
   * @param {string} [options.label]
   *        Label to identify the text track
   *
   * @param {string} [options.language]
   *        Two letter language abbreviation.
   *
   * @param {boolean} [options.default]
   *        Default this track to on.
   *
   * @param {string} [options.id]
   *        The internal id to assign this track.
   *
   * @param {string} [options.src]
   *        A source url for the track.
   *
   * @return {HTMLTrackElement}
   *         The track element that gets created.
   */
  ;

  _proto.createRemoteTextTrack = function createRemoteTextTrack(options) {
    if (!this.featuresNativeTextTracks) {
      return _Tech.prototype.createRemoteTextTrack.call(this, options);
    }

    var htmlTrackElement = document__default['default'].createElement('track');

    if (options.kind) {
      htmlTrackElement.kind = options.kind;
    }

    if (options.label) {
      htmlTrackElement.label = options.label;
    }

    if (options.language || options.srclang) {
      htmlTrackElement.srclang = options.language || options.srclang;
    }

    if (options["default"]) {
      htmlTrackElement["default"] = options["default"];
    }

    if (options.id) {
      htmlTrackElement.id = options.id;
    }

    if (options.src) {
      htmlTrackElement.src = options.src;
    }

    return htmlTrackElement;
  }
  /**
   * Creates a remote text track object and returns an html track element.
   *
   * @param {Object} options The object should contain values for
   * kind, language, label, and src (location of the WebVTT file)
   * @param {boolean} [manualCleanup=true] if set to false, the TextTrack will be
   * automatically removed from the video element whenever the source changes
   * @return {HTMLTrackElement} An Html Track Element.
   * This can be an emulated {@link HTMLTrackElement} or a native one.
   * @deprecated The default value of the "manualCleanup" parameter will default
   * to "false" in upcoming versions of Video.js
   */
  ;

  _proto.addRemoteTextTrack = function addRemoteTextTrack(options, manualCleanup) {
    var htmlTrackElement = _Tech.prototype.addRemoteTextTrack.call(this, options, manualCleanup);

    if (this.featuresNativeTextTracks) {
      this.el().appendChild(htmlTrackElement);
    }

    return htmlTrackElement;
  }
  /**
   * Remove remote `TextTrack` from `TextTrackList` object
   *
   * @param {TextTrack} track
   *        `TextTrack` object to remove
   */
  ;

  _proto.removeRemoteTextTrack = function removeRemoteTextTrack(track) {
    _Tech.prototype.removeRemoteTextTrack.call(this, track);

    if (this.featuresNativeTextTracks) {
      var tracks = this.$$('track');
      var i = tracks.length;

      while (i--) {
        if (track === tracks[i] || track === tracks[i].track) {
          this.el().removeChild(tracks[i]);
        }
      }
    }
  }
  /**
   * Gets available media playback quality metrics as specified by the W3C's Media
   * Playback Quality API.
   *
   * @see [Spec]{@link https://wicg.github.io/media-playback-quality}
   *
   * @return {Object}
   *         An object with supported media playback quality metrics
   */
  ;

  _proto.getVideoPlaybackQuality = function getVideoPlaybackQuality() {
    if (typeof this.el().getVideoPlaybackQuality === 'function') {
      return this.el().getVideoPlaybackQuality();
    }

    var videoPlaybackQuality = {};

    if (typeof this.el().webkitDroppedFrameCount !== 'undefined' && typeof this.el().webkitDecodedFrameCount !== 'undefined') {
      videoPlaybackQuality.droppedVideoFrames = this.el().webkitDroppedFrameCount;
      videoPlaybackQuality.totalVideoFrames = this.el().webkitDecodedFrameCount;
    }

    if (window__default['default'].performance && typeof window__default['default'].performance.now === 'function') {
      videoPlaybackQuality.creationTime = window__default['default'].performance.now();
    } else if (window__default['default'].performance && window__default['default'].performance.timing && typeof window__default['default'].performance.timing.navigationStart === 'number') {
      videoPlaybackQuality.creationTime = window__default['default'].Date.now() - window__default['default'].performance.timing.navigationStart;
    }

    return videoPlaybackQuality;
  };

  return Html5;
}(Tech);
/* HTML5 Support Testing ---------------------------------------------------- */

/**
 * Element for testing browser HTML5 media capabilities
 *
 * @type {Element}
 * @constant
 * @private
 */


defineLazyProperty(Html5, 'TEST_VID', function () {
  if (!isReal()) {
    return;
  }

  var video = document__default['default'].createElement('video');
  var track = document__default['default'].createElement('track');
  track.kind = 'captions';
  track.srclang = 'en';
  track.label = 'English';
  video.appendChild(track);
  return video;
});
/**
 * Check if HTML5 media is supported by this browser/device.
 *
 * @return {boolean}
 *         - True if HTML5 media is supported.
 *         - False if HTML5 media is not supported.
 */

Html5.isSupported = function () {
  // IE with no Media Player is a LIAR! (#984)
  try {
    Html5.TEST_VID.volume = 0.5;
  } catch (e) {
    return false;
  }

  return !!(Html5.TEST_VID && Html5.TEST_VID.canPlayType);
};
/**
 * Check if the tech can support the given type
 *
 * @param {string} type
 *        The mimetype to check
 * @return {string} 'probably', 'maybe', or '' (empty string)
 */


Html5.canPlayType = function (type) {
  return Html5.TEST_VID.canPlayType(type);
};
/**
 * Check if the tech can support the given source
 *
 * @param {Object} srcObj
 *        The source object
 * @param {Object} options
 *        The options passed to the tech
 * @return {string} 'probably', 'maybe', or '' (empty string)
 */


Html5.canPlaySource = function (srcObj, options) {
  return Html5.canPlayType(srcObj.type);
};
/**
 * Check if the volume can be changed in this browser/device.
 * Volume cannot be changed in a lot of mobile devices.
 * Specifically, it can't be changed from 1 on iOS.
 *
 * @return {boolean}
 *         - True if volume can be controlled
 *         - False otherwise
 */


Html5.canControlVolume = function () {
  // IE will error if Windows Media Player not installed #3315
  try {
    var volume = Html5.TEST_VID.volume;
    Html5.TEST_VID.volume = volume / 2 + 0.1;
    var canControl = volume !== Html5.TEST_VID.volume; // With the introduction of iOS 15, there are cases where the volume is read as
    // changed but reverts back to its original state at the start of the next tick.
    // To determine whether volume can be controlled on iOS,
    // a timeout is set and the volume is checked asynchronously.
    // Since `features` doesn't currently work asynchronously, the value is manually set.

    if (canControl && IS_IOS) {
      window__default['default'].setTimeout(function () {
        if (Html5 && Html5.prototype) {
          Html5.prototype.featuresVolumeControl = volume !== Html5.TEST_VID.volume;
        }
      }); // default iOS to false, which will be updated in the timeout above.

      return false;
    }

    return canControl;
  } catch (e) {
    return false;
  }
};
/**
 * Check if the volume can be muted in this browser/device.
 * Some devices, e.g. iOS, don't allow changing volume
 * but permits muting/unmuting.
 *
 * @return {bolean}
 *      - True if volume can be muted
 *      - False otherwise
 */


Html5.canMuteVolume = function () {
  try {
    var muted = Html5.TEST_VID.muted; // in some versions of iOS muted property doesn't always
    // work, so we want to set both property and attribute

    Html5.TEST_VID.muted = !muted;

    if (Html5.TEST_VID.muted) {
      setAttribute(Html5.TEST_VID, 'muted', 'muted');
    } else {
      removeAttribute(Html5.TEST_VID, 'muted', 'muted');
    }

    return muted !== Html5.TEST_VID.muted;
  } catch (e) {
    return false;
  }
};
/**
 * Check if the playback rate can be changed in this browser/device.
 *
 * @return {boolean}
 *         - True if playback rate can be controlled
 *         - False otherwise
 */


Html5.canControlPlaybackRate = function () {
  // Playback rate API is implemented in Android Chrome, but doesn't do anything
  // https://github.com/videojs/video.js/issues/3180
  if (IS_ANDROID && IS_CHROME && CHROME_VERSION < 58) {
    return false;
  } // IE will error if Windows Media Player not installed #3315


  try {
    var playbackRate = Html5.TEST_VID.playbackRate;
    Html5.TEST_VID.playbackRate = playbackRate / 2 + 0.1;
    return playbackRate !== Html5.TEST_VID.playbackRate;
  } catch (e) {
    return false;
  }
};
/**
 * Check if we can override a video/audio elements attributes, with
 * Object.defineProperty.
 *
 * @return {boolean}
 *         - True if builtin attributes can be overridden
 *         - False otherwise
 */


Html5.canOverrideAttributes = function () {
  // if we cannot overwrite the src/innerHTML property, there is no support
  // iOS 7 safari for instance cannot do this.
  try {
    var noop = function noop() {};

    Object.defineProperty(document__default['default'].createElement('video'), 'src', {
      get: noop,
      set: noop
    });
    Object.defineProperty(document__default['default'].createElement('audio'), 'src', {
      get: noop,
      set: noop
    });
    Object.defineProperty(document__default['default'].createElement('video'), 'innerHTML', {
      get: noop,
      set: noop
    });
    Object.defineProperty(document__default['default'].createElement('audio'), 'innerHTML', {
      get: noop,
      set: noop
    });
  } catch (e) {
    return false;
  }

  return true;
};
/**
 * Check to see if native `TextTrack`s are supported by this browser/device.
 *
 * @return {boolean}
 *         - True if native `TextTrack`s are supported.
 *         - False otherwise
 */


Html5.supportsNativeTextTracks = function () {
  return IS_ANY_SAFARI || IS_IOS && IS_CHROME;
};
/**
 * Check to see if native `VideoTrack`s are supported by this browser/device
 *
 * @return {boolean}
 *        - True if native `VideoTrack`s are supported.
 *        - False otherwise
 */


Html5.supportsNativeVideoTracks = function () {
  return !!(Html5.TEST_VID && Html5.TEST_VID.videoTracks);
};
/**
 * Check to see if native `AudioTrack`s are supported by this browser/device
 *
 * @return {boolean}
 *        - True if native `AudioTrack`s are supported.
 *        - False otherwise
 */


Html5.supportsNativeAudioTracks = function () {
  return !!(Html5.TEST_VID && Html5.TEST_VID.audioTracks);
};
/**
 * An array of events available on the Html5 tech.
 *
 * @private
 * @type {Array}
 */


Html5.Events = ['loadstart', 'suspend', 'abort', 'error', 'emptied', 'stalled', 'loadedmetadata', 'loadeddata', 'canplay', 'canplaythrough', 'playing', 'waiting', 'seeking', 'seeked', 'ended', 'durationchange', 'timeupdate', 'progress', 'play', 'pause', 'ratechange', 'resize', 'volumechange'];
/**
 * Boolean indicating whether the `Tech` supports volume control.
 *
 * @type {boolean}
 * @default {@link Html5.canControlVolume}
 */

/**
 * Boolean indicating whether the `Tech` supports muting volume.
 *
 * @type {bolean}
 * @default {@link Html5.canMuteVolume}
 */

/**
 * Boolean indicating whether the `Tech` supports changing the speed at which the media
 * plays. Examples:
 *   - Set player to play 2x (twice) as fast
 *   - Set player to play 0.5x (half) as fast
 *
 * @type {boolean}
 * @default {@link Html5.canControlPlaybackRate}
 */

/**
 * Boolean indicating whether the `Tech` supports the `sourceset` event.
 *
 * @type {boolean}
 * @default
 */

/**
 * Boolean indicating whether the `HTML5` tech currently supports native `TextTrack`s.
 *
 * @type {boolean}
 * @default {@link Html5.supportsNativeTextTracks}
 */

/**
 * Boolean indicating whether the `HTML5` tech currently supports native `VideoTrack`s.
 *
 * @type {boolean}
 * @default {@link Html5.supportsNativeVideoTracks}
 */

/**
 * Boolean indicating whether the `HTML5` tech currently supports native `AudioTrack`s.
 *
 * @type {boolean}
 * @default {@link Html5.supportsNativeAudioTracks}
 */

[['featuresMuteControl', 'canMuteVolume'], ['featuresPlaybackRate', 'canControlPlaybackRate'], ['featuresSourceset', 'canOverrideAttributes'], ['featuresNativeTextTracks', 'supportsNativeTextTracks'], ['featuresNativeVideoTracks', 'supportsNativeVideoTracks'], ['featuresNativeAudioTracks', 'supportsNativeAudioTracks']].forEach(function (_ref) {
  var key = _ref[0],
      fn = _ref[1];
  defineLazyProperty(Html5.prototype, key, function () {
    return Html5[fn]();
  }, true);
});
Html5.prototype.featuresVolumeControl = Html5.canControlVolume();
/**
 * Boolean indicating whether the `HTML5` tech currently supports the media element
 * moving in the DOM. iOS breaks if you move the media element, so this is set this to
 * false there. Everywhere else this should be true.
 *
 * @type {boolean}
 * @default
 */

Html5.prototype.movingMediaElementInDOM = !IS_IOS; // TODO: Previous comment: No longer appears to be used. Can probably be removed.
//       Is this true?

/**
 * Boolean indicating whether the `HTML5` tech currently supports automatic media resize
 * when going into fullscreen.
 *
 * @type {boolean}
 * @default
 */

Html5.prototype.featuresFullscreenResize = true;
/**
 * Boolean indicating whether the `HTML5` tech currently supports the progress event.
 * If this is false, manual `progress` events will be triggered instead.
 *
 * @type {boolean}
 * @default
 */

Html5.prototype.featuresProgressEvents = true;
/**
 * Boolean indicating whether the `HTML5` tech currently supports the timeupdate event.
 * If this is false, manual `timeupdate` events will be triggered instead.
 *
 * @default
 */

Html5.prototype.featuresTimeupdateEvents = true; // HTML5 Feature detection and Device Fixes --------------------------------- //

var canPlayType;

Html5.patchCanPlayType = function () {
  // Android 4.0 and above can play HLS to some extent but it reports being unable to do so
  // Firefox and Chrome report correctly
  if (ANDROID_VERSION >= 4.0 && !IS_FIREFOX && !IS_CHROME) {
    canPlayType = Html5.TEST_VID && Html5.TEST_VID.constructor.prototype.canPlayType;

    Html5.TEST_VID.constructor.prototype.canPlayType = function (type) {
      var mpegurlRE = /^application\/(?:x-|vnd\.apple\.)mpegurl/i;

      if (type && mpegurlRE.test(type)) {
        return 'maybe';
      }

      return canPlayType.call(this, type);
    };
  }
};

Html5.unpatchCanPlayType = function () {
  var r = Html5.TEST_VID.constructor.prototype.canPlayType;

  if (canPlayType) {
    Html5.TEST_VID.constructor.prototype.canPlayType = canPlayType;
  }

  return r;
}; // by default, patch the media element


Html5.patchCanPlayType();

Html5.disposeMediaElement = function (el) {
  if (!el) {
    return;
  }

  if (el.parentNode) {
    el.parentNode.removeChild(el);
  } // remove any child track or source nodes to prevent their loading


  while (el.hasChildNodes()) {
    el.removeChild(el.firstChild);
  } // remove any src reference. not setting `src=''` because that causes a warning
  // in firefox


  el.removeAttribute('src'); // force the media element to update its loading state by calling load()
  // however IE on Windows 7N has a bug that throws an error so need a try/catch (#793)

  if (typeof el.load === 'function') {
    // wrapping in an iife so it's not deoptimized (#1060#discussion_r10324473)
    (function () {
      try {
        el.load();
      } catch (e) {// not supported
      }
    })();
  }
};

Html5.resetMediaElement = function (el) {
  if (!el) {
    return;
  }

  var sources = el.querySelectorAll('source');
  var i = sources.length;

  while (i--) {
    el.removeChild(sources[i]);
  } // remove any src reference.
  // not setting `src=''` because that throws an error


  el.removeAttribute('src');

  if (typeof el.load === 'function') {
    // wrapping in an iife so it's not deoptimized (#1060#discussion_r10324473)
    (function () {
      try {
        el.load();
      } catch (e) {// satisfy linter
      }
    })();
  }
};
/* Native HTML5 element property wrapping ----------------------------------- */
// Wrap native boolean attributes with getters that check both property and attribute
// The list is as followed:
// muted, defaultMuted, autoplay, controls, loop, playsinline


[
/**
 * Get the value of `muted` from the media element. `muted` indicates
 * that the volume for the media should be set to silent. This does not actually change
 * the `volume` attribute.
 *
 * @method Html5#muted
 * @return {boolean}
 *         - True if the value of `volume` should be ignored and the audio set to silent.
 *         - False if the value of `volume` should be used.
 *
 * @see [Spec]{@link https://www.w3.org/TR/html5/embedded-content-0.html#dom-media-muted}
 */
'muted',
/**
 * Get the value of `defaultMuted` from the media element. `defaultMuted` indicates
 * whether the media should start muted or not. Only changes the default state of the
 * media. `muted` and `defaultMuted` can have different values. {@link Html5#muted} indicates the
 * current state.
 *
 * @method Html5#defaultMuted
 * @return {boolean}
 *         - The value of `defaultMuted` from the media element.
 *         - True indicates that the media should start muted.
 *         - False indicates that the media should not start muted
 *
 * @see [Spec]{@link https://www.w3.org/TR/html5/embedded-content-0.html#dom-media-defaultmuted}
 */
'defaultMuted',
/**
 * Get the value of `autoplay` from the media element. `autoplay` indicates
 * that the media should start to play as soon as the page is ready.
 *
 * @method Html5#autoplay
 * @return {boolean}
 *         - The value of `autoplay` from the media element.
 *         - True indicates that the media should start as soon as the page loads.
 *         - False indicates that the media should not start as soon as the page loads.
 *
 * @see [Spec]{@link https://www.w3.org/TR/html5/embedded-content-0.html#attr-media-autoplay}
 */
'autoplay',
/**
 * Get the value of `controls` from the media element. `controls` indicates
 * whether the native media controls should be shown or hidden.
 *
 * @method Html5#controls
 * @return {boolean}
 *         - The value of `controls` from the media element.
 *         - True indicates that native controls should be showing.
 *         - False indicates that native controls should be hidden.
 *
 * @see [Spec]{@link https://www.w3.org/TR/html5/embedded-content-0.html#attr-media-controls}
 */
'controls',
/**
 * Get the value of `loop` from the media element. `loop` indicates
 * that the media should return to the start of the media and continue playing once
 * it reaches the end.
 *
 * @method Html5#loop
 * @return {boolean}
 *         - The value of `loop` from the media element.
 *         - True indicates that playback should seek back to start once
 *           the end of a media is reached.
 *         - False indicates that playback should not loop back to the start when the
 *           end of the media is reached.
 *
 * @see [Spec]{@link https://www.w3.org/TR/html5/embedded-content-0.html#attr-media-loop}
 */
'loop',
/**
 * Get the value of `playsinline` from the media element. `playsinline` indicates
 * to the browser that non-fullscreen playback is preferred when fullscreen
 * playback is the native default, such as in iOS Safari.
 *
 * @method Html5#playsinline
 * @return {boolean}
 *         - The value of `playsinline` from the media element.
 *         - True indicates that the media should play inline.
 *         - False indicates that the media should not play inline.
 *
 * @see [Spec]{@link https://html.spec.whatwg.org/#attr-video-playsinline}
 */
'playsinline'].forEach(function (prop) {
  Html5.prototype[prop] = function () {
    return this.el_[prop] || this.el_.hasAttribute(prop);
  };
}); // Wrap native boolean attributes with setters that set both property and attribute
// The list is as followed:
// setMuted, setDefaultMuted, setAutoplay, setLoop, setPlaysinline
// setControls is special-cased above

[
/**
 * Set the value of `muted` on the media element. `muted` indicates that the current
 * audio level should be silent.
 *
 * @method Html5#setMuted
 * @param {boolean} muted
 *        - True if the audio should be set to silent
 *        - False otherwise
 *
 * @see [Spec]{@link https://www.w3.org/TR/html5/embedded-content-0.html#dom-media-muted}
 */
'muted',
/**
 * Set the value of `defaultMuted` on the media element. `defaultMuted` indicates that the current
 * audio level should be silent, but will only effect the muted level on initial playback..
 *
 * @method Html5.prototype.setDefaultMuted
 * @param {boolean} defaultMuted
 *        - True if the audio should be set to silent
 *        - False otherwise
 *
 * @see [Spec]{@link https://www.w3.org/TR/html5/embedded-content-0.html#dom-media-defaultmuted}
 */
'defaultMuted',
/**
 * Set the value of `autoplay` on the media element. `autoplay` indicates
 * that the media should start to play as soon as the page is ready.
 *
 * @method Html5#setAutoplay
 * @param {boolean} autoplay
 *         - True indicates that the media should start as soon as the page loads.
 *         - False indicates that the media should not start as soon as the page loads.
 *
 * @see [Spec]{@link https://www.w3.org/TR/html5/embedded-content-0.html#attr-media-autoplay}
 */
'autoplay',
/**
 * Set the value of `loop` on the media element. `loop` indicates
 * that the media should return to the start of the media and continue playing once
 * it reaches the end.
 *
 * @method Html5#setLoop
 * @param {boolean} loop
 *         - True indicates that playback should seek back to start once
 *           the end of a media is reached.
 *         - False indicates that playback should not loop back to the start when the
 *           end of the media is reached.
 *
 * @see [Spec]{@link https://www.w3.org/TR/html5/embedded-content-0.html#attr-media-loop}
 */
'loop',
/**
 * Set the value of `playsinline` from the media element. `playsinline` indicates
 * to the browser that non-fullscreen playback is preferred when fullscreen
 * playback is the native default, such as in iOS Safari.
 *
 * @method Html5#setPlaysinline
 * @param {boolean} playsinline
 *         - True indicates that the media should play inline.
 *         - False indicates that the media should not play inline.
 *
 * @see [Spec]{@link https://html.spec.whatwg.org/#attr-video-playsinline}
 */
'playsinline'].forEach(function (prop) {
  Html5.prototype['set' + toTitleCase(prop)] = function (v) {
    this.el_[prop] = v;

    if (v) {
      this.el_.setAttribute(prop, prop);
    } else {
      this.el_.removeAttribute(prop);
    }
  };
}); // Wrap native properties with a getter
// The list is as followed
// paused, currentTime, buffered, volume, poster, preload, error, seeking
// seekable, ended, playbackRate, defaultPlaybackRate, disablePictureInPicture
// played, networkState, readyState, videoWidth, videoHeight, crossOrigin

[
/**
 * Get the value of `paused` from the media element. `paused` indicates whether the media element
 * is currently paused or not.
 *
 * @method Html5#paused
 * @return {boolean}
 *         The value of `paused` from the media element.
 *
 * @see [Spec]{@link https://www.w3.org/TR/html5/embedded-content-0.html#dom-media-paused}
 */
'paused',
/**
 * Get the value of `currentTime` from the media element. `currentTime` indicates
 * the current second that the media is at in playback.
 *
 * @method Html5#currentTime
 * @return {number}
 *         The value of `currentTime` from the media element.
 *
 * @see [Spec]{@link https://www.w3.org/TR/html5/embedded-content-0.html#dom-media-currenttime}
 */
'currentTime',
/**
 * Get the value of `buffered` from the media element. `buffered` is a `TimeRange`
 * object that represents the parts of the media that are already downloaded and
 * available for playback.
 *
 * @method Html5#buffered
 * @return {TimeRange}
 *         The value of `buffered` from the media element.
 *
 * @see [Spec]{@link https://www.w3.org/TR/html5/embedded-content-0.html#dom-media-buffered}
 */
'buffered',
/**
 * Get the value of `volume` from the media element. `volume` indicates
 * the current playback volume of audio for a media. `volume` will be a value from 0
 * (silent) to 1 (loudest and default).
 *
 * @method Html5#volume
 * @return {number}
 *         The value of `volume` from the media element. Value will be between 0-1.
 *
 * @see [Spec]{@link https://www.w3.org/TR/html5/embedded-content-0.html#dom-a-volume}
 */
'volume',
/**
 * Get the value of `poster` from the media element. `poster` indicates
 * that the url of an image file that can/will be shown when no media data is available.
 *
 * @method Html5#poster
 * @return {string}
 *         The value of `poster` from the media element. Value will be a url to an
 *         image.
 *
 * @see [Spec]{@link https://www.w3.org/TR/html5/embedded-content-0.html#attr-video-poster}
 */
'poster',
/**
 * Get the value of `preload` from the media element. `preload` indicates
 * what should download before the media is interacted with. It can have the following
 * values:
 * - none: nothing should be downloaded
 * - metadata: poster and the first few frames of the media may be downloaded to get
 *   media dimensions and other metadata
 * - auto: allow the media and metadata for the media to be downloaded before
 *    interaction
 *
 * @method Html5#preload
 * @return {string}
 *         The value of `preload` from the media element. Will be 'none', 'metadata',
 *         or 'auto'.
 *
 * @see [Spec]{@link https://www.w3.org/TR/html5/embedded-content-0.html#attr-media-preload}
 */
'preload',
/**
 * Get the value of the `error` from the media element. `error` indicates any
 * MediaError that may have occurred during playback. If error returns null there is no
 * current error.
 *
 * @method Html5#error
 * @return {MediaError|null}
 *         The value of `error` from the media element. Will be `MediaError` if there
 *         is a current error and null otherwise.
 *
 * @see [Spec]{@link https://www.w3.org/TR/html5/embedded-content-0.html#dom-media-error}
 */
'error',
/**
 * Get the value of `seeking` from the media element. `seeking` indicates whether the
 * media is currently seeking to a new position or not.
 *
 * @method Html5#seeking
 * @return {boolean}
 *         - The value of `seeking` from the media element.
 *         - True indicates that the media is currently seeking to a new position.
 *         - False indicates that the media is not seeking to a new position at this time.
 *
 * @see [Spec]{@link https://www.w3.org/TR/html5/embedded-content-0.html#dom-media-seeking}
 */
'seeking',
/**
 * Get the value of `seekable` from the media element. `seekable` returns a
 * `TimeRange` object indicating ranges of time that can currently be `seeked` to.
 *
 * @method Html5#seekable
 * @return {TimeRange}
 *         The value of `seekable` from the media element. A `TimeRange` object
 *         indicating the current ranges of time that can be seeked to.
 *
 * @see [Spec]{@link https://www.w3.org/TR/html5/embedded-content-0.html#dom-media-seekable}
 */
'seekable',
/**
 * Get the value of `ended` from the media element. `ended` indicates whether
 * the media has reached the end or not.
 *
 * @method Html5#ended
 * @return {boolean}
 *         - The value of `ended` from the media element.
 *         - True indicates that the media has ended.
 *         - False indicates that the media has not ended.
 *
 * @see [Spec]{@link https://www.w3.org/TR/html5/embedded-content-0.html#dom-media-ended}
 */
'ended',
/**
 * Get the value of `playbackRate` from the media element. `playbackRate` indicates
 * the rate at which the media is currently playing back. Examples:
 *   - if playbackRate is set to 2, media will play twice as fast.
 *   - if playbackRate is set to 0.5, media will play half as fast.
 *
 * @method Html5#playbackRate
 * @return {number}
 *         The value of `playbackRate` from the media element. A number indicating
 *         the current playback speed of the media, where 1 is normal speed.
 *
 * @see [Spec]{@link https://www.w3.org/TR/html5/embedded-content-0.html#dom-media-playbackrate}
 */
'playbackRate',
/**
 * Get the value of `defaultPlaybackRate` from the media element. `defaultPlaybackRate` indicates
 * the rate at which the media is currently playing back. This value will not indicate the current
 * `playbackRate` after playback has started, use {@link Html5#playbackRate} for that.
 *
 * Examples:
 *   - if defaultPlaybackRate is set to 2, media will play twice as fast.
 *   - if defaultPlaybackRate is set to 0.5, media will play half as fast.
 *
 * @method Html5.prototype.defaultPlaybackRate
 * @return {number}
 *         The value of `defaultPlaybackRate` from the media element. A number indicating
 *         the current playback speed of the media, where 1 is normal speed.
 *
 * @see [Spec]{@link https://www.w3.org/TR/html5/embedded-content-0.html#dom-media-playbackrate}
 */
'defaultPlaybackRate',
/**
 * Get the value of 'disablePictureInPicture' from the video element.
 *
 * @method Html5#disablePictureInPicture
 * @return {boolean} value
 *         - The value of `disablePictureInPicture` from the video element.
 *         - True indicates that the video can't be played in Picture-In-Picture mode
 *         - False indicates that the video can be played in Picture-In-Picture mode
 *
 * @see [Spec]{@link https://w3c.github.io/picture-in-picture/#disable-pip}
 */
'disablePictureInPicture',
/**
 * Get the value of `played` from the media element. `played` returns a `TimeRange`
 * object representing points in the media timeline that have been played.
 *
 * @method Html5#played
 * @return {TimeRange}
 *         The value of `played` from the media element. A `TimeRange` object indicating
 *         the ranges of time that have been played.
 *
 * @see [Spec]{@link https://www.w3.org/TR/html5/embedded-content-0.html#dom-media-played}
 */
'played',
/**
 * Get the value of `networkState` from the media element. `networkState` indicates
 * the current network state. It returns an enumeration from the following list:
 * - 0: NETWORK_EMPTY
 * - 1: NETWORK_IDLE
 * - 2: NETWORK_LOADING
 * - 3: NETWORK_NO_SOURCE
 *
 * @method Html5#networkState
 * @return {number}
 *         The value of `networkState` from the media element. This will be a number
 *         from the list in the description.
 *
 * @see [Spec] {@link https://www.w3.org/TR/html5/embedded-content-0.html#dom-media-networkstate}
 */
'networkState',
/**
 * Get the value of `readyState` from the media element. `readyState` indicates
 * the current state of the media element. It returns an enumeration from the
 * following list:
 * - 0: HAVE_NOTHING
 * - 1: HAVE_METADATA
 * - 2: HAVE_CURRENT_DATA
 * - 3: HAVE_FUTURE_DATA
 * - 4: HAVE_ENOUGH_DATA
 *
 * @method Html5#readyState
 * @return {number}
 *         The value of `readyState` from the media element. This will be a number
 *         from the list in the description.
 *
 * @see [Spec] {@link https://www.w3.org/TR/html5/embedded-content-0.html#ready-states}
 */
'readyState',
/**
 * Get the value of `videoWidth` from the video element. `videoWidth` indicates
 * the current width of the video in css pixels.
 *
 * @method Html5#videoWidth
 * @return {number}
 *         The value of `videoWidth` from the video element. This will be a number
 *         in css pixels.
 *
 * @see [Spec] {@link https://www.w3.org/TR/html5/embedded-content-0.html#dom-video-videowidth}
 */
'videoWidth',
/**
 * Get the value of `videoHeight` from the video element. `videoHeight` indicates
 * the current height of the video in css pixels.
 *
 * @method Html5#videoHeight
 * @return {number}
 *         The value of `videoHeight` from the video element. This will be a number
 *         in css pixels.
 *
 * @see [Spec] {@link https://www.w3.org/TR/html5/embedded-content-0.html#dom-video-videowidth}
 */
'videoHeight',
/**
 * Get the value of `crossOrigin` from the media element. `crossOrigin` indicates
 * to the browser that should sent the cookies along with the requests for the
 * different assets/playlists
 *
 * @method Html5#crossOrigin
 * @return {string}
 *         - anonymous indicates that the media should not sent cookies.
 *         - use-credentials indicates that the media should sent cookies along the requests.
 *
 * @see [Spec]{@link https://html.spec.whatwg.org/#attr-media-crossorigin}
 */
'crossOrigin'].forEach(function (prop) {
  Html5.prototype[prop] = function () {
    return this.el_[prop];
  };
}); // Wrap native properties with a setter in this format:
// set + toTitleCase(name)
// The list is as follows:
// setVolume, setSrc, setPoster, setPreload, setPlaybackRate, setDefaultPlaybackRate,
// setDisablePictureInPicture, setCrossOrigin

[
/**
 * Set the value of `volume` on the media element. `volume` indicates the current
 * audio level as a percentage in decimal form. This means that 1 is 100%, 0.5 is 50%, and
 * so on.
 *
 * @method Html5#setVolume
 * @param {number} percentAsDecimal
 *        The volume percent as a decimal. Valid range is from 0-1.
 *
 * @see [Spec]{@link https://www.w3.org/TR/html5/embedded-content-0.html#dom-a-volume}
 */
'volume',
/**
 * Set the value of `src` on the media element. `src` indicates the current
 * {@link Tech~SourceObject} for the media.
 *
 * @method Html5#setSrc
 * @param {Tech~SourceObject} src
 *        The source object to set as the current source.
 *
 * @see [Spec]{@link https://www.w3.org/TR/html5/embedded-content-0.html#dom-media-src}
 */
'src',
/**
 * Set the value of `poster` on the media element. `poster` is the url to
 * an image file that can/will be shown when no media data is available.
 *
 * @method Html5#setPoster
 * @param {string} poster
 *        The url to an image that should be used as the `poster` for the media
 *        element.
 *
 * @see [Spec]{@link https://www.w3.org/TR/html5/embedded-content-0.html#attr-media-poster}
 */
'poster',
/**
 * Set the value of `preload` on the media element. `preload` indicates
 * what should download before the media is interacted with. It can have the following
 * values:
 * - none: nothing should be downloaded
 * - metadata: poster and the first few frames of the media may be downloaded to get
 *   media dimensions and other metadata
 * - auto: allow the media and metadata for the media to be downloaded before
 *    interaction
 *
 * @method Html5#setPreload
 * @param {string} preload
 *         The value of `preload` to set on the media element. Must be 'none', 'metadata',
 *         or 'auto'.
 *
 * @see [Spec]{@link https://www.w3.org/TR/html5/embedded-content-0.html#attr-media-preload}
 */
'preload',
/**
 * Set the value of `playbackRate` on the media element. `playbackRate` indicates
 * the rate at which the media should play back. Examples:
 *   - if playbackRate is set to 2, media will play twice as fast.
 *   - if playbackRate is set to 0.5, media will play half as fast.
 *
 * @method Html5#setPlaybackRate
 * @return {number}
 *         The value of `playbackRate` from the media element. A number indicating
 *         the current playback speed of the media, where 1 is normal speed.
 *
 * @see [Spec]{@link https://www.w3.org/TR/html5/embedded-content-0.html#dom-media-playbackrate}
 */
'playbackRate',
/**
 * Set the value of `defaultPlaybackRate` on the media element. `defaultPlaybackRate` indicates
 * the rate at which the media should play back upon initial startup. Changing this value
 * after a video has started will do nothing. Instead you should used {@link Html5#setPlaybackRate}.
 *
 * Example Values:
 *   - if playbackRate is set to 2, media will play twice as fast.
 *   - if playbackRate is set to 0.5, media will play half as fast.
 *
 * @method Html5.prototype.setDefaultPlaybackRate
 * @return {number}
 *         The value of `defaultPlaybackRate` from the media element. A number indicating
 *         the current playback speed of the media, where 1 is normal speed.
 *
 * @see [Spec]{@link https://www.w3.org/TR/html5/embedded-content-0.html#dom-media-defaultplaybackrate}
 */
'defaultPlaybackRate',
/**
 * Prevents the browser from suggesting a Picture-in-Picture context menu
 * or to request Picture-in-Picture automatically in some cases.
 *
 * @method Html5#setDisablePictureInPicture
 * @param {boolean} value
 *         The true value will disable Picture-in-Picture mode.
 *
 * @see [Spec]{@link https://w3c.github.io/picture-in-picture/#disable-pip}
 */
'disablePictureInPicture',
/**
 * Set the value of `crossOrigin` from the media element. `crossOrigin` indicates
 * to the browser that should sent the cookies along with the requests for the
 * different assets/playlists
 *
 * @method Html5#setCrossOrigin
 * @param {string} crossOrigin
 *         - anonymous indicates that the media should not sent cookies.
 *         - use-credentials indicates that the media should sent cookies along the requests.
 *
 * @see [Spec]{@link https://html.spec.whatwg.org/#attr-media-crossorigin}
 */
'crossOrigin'].forEach(function (prop) {
  Html5.prototype['set' + toTitleCase(prop)] = function (v) {
    this.el_[prop] = v;
  };
}); // wrap native functions with a function
// The list is as follows:
// pause, load, play

[
/**
 * A wrapper around the media elements `pause` function. This will call the `HTML5`
 * media elements `pause` function.
 *
 * @method Html5#pause
 * @see [Spec]{@link https://www.w3.org/TR/html5/embedded-content-0.html#dom-media-pause}
 */
'pause',
/**
 * A wrapper around the media elements `load` function. This will call the `HTML5`s
 * media element `load` function.
 *
 * @method Html5#load
 * @see [Spec]{@link https://www.w3.org/TR/html5/embedded-content-0.html#dom-media-load}
 */
'load',
/**
 * A wrapper around the media elements `play` function. This will call the `HTML5`s
 * media element `play` function.
 *
 * @method Html5#play
 * @see [Spec]{@link https://www.w3.org/TR/html5/embedded-content-0.html#dom-media-play}
 */
'play'].forEach(function (prop) {
  Html5.prototype[prop] = function () {
    return this.el_[prop]();
  };
});
Tech.withSourceHandlers(Html5);
/**
 * Native source handler for Html5, simply passes the source to the media element.
 *
 * @property {Tech~SourceObject} source
 *        The source object
 *
 * @property {Html5} tech
 *        The instance of the HTML5 tech.
 */

Html5.nativeSourceHandler = {};
/**
 * Check if the media element can play the given mime type.
 *
 * @param {string} type
 *        The mimetype to check
 *
 * @return {string}
 *         'probably', 'maybe', or '' (empty string)
 */

Html5.nativeSourceHandler.canPlayType = function (type) {
  // IE without MediaPlayer throws an error (#519)
  try {
    return Html5.TEST_VID.canPlayType(type);
  } catch (e) {
    return '';
  }
};
/**
 * Check if the media element can handle a source natively.
 *
 * @param {Tech~SourceObject} source
 *         The source object
 *
 * @param {Object} [options]
 *         Options to be passed to the tech.
 *
 * @return {string}
 *         'probably', 'maybe', or '' (empty string).
 */


Html5.nativeSourceHandler.canHandleSource = function (source, options) {
  // If a type was provided we should rely on that
  if (source.type) {
    return Html5.nativeSourceHandler.canPlayType(source.type); // If no type, fall back to checking 'video/[EXTENSION]'
  } else if (source.src) {
    var ext = getFileExtension(source.src);
    return Html5.nativeSourceHandler.canPlayType("video/" + ext);
  }

  return '';
};
/**
 * Pass the source to the native media element.
 *
 * @param {Tech~SourceObject} source
 *        The source object
 *
 * @param {Html5} tech
 *        The instance of the Html5 tech
 *
 * @param {Object} [options]
 *        The options to pass to the source
 */


Html5.nativeSourceHandler.handleSource = function (source, tech, options) {
  tech.setSrc(source.src);
};
/**
 * A noop for the native dispose function, as cleanup is not needed.
 */


Html5.nativeSourceHandler.dispose = function () {}; // Register the native source handler


Html5.registerSourceHandler(Html5.nativeSourceHandler);
Tech.registerTech('Html5', Html5);

// on the player when they happen

var TECH_EVENTS_RETRIGGER = [
/**
 * Fired while the user agent is downloading media data.
 *
 * @event Player#progress
 * @type {EventTarget~Event}
 */

/**
 * Retrigger the `progress` event that was triggered by the {@link Tech}.
 *
 * @private
 * @method Player#handleTechProgress_
 * @fires Player#progress
 * @listens Tech#progress
 */
'progress',
/**
 * Fires when the loading of an audio/video is aborted.
 *
 * @event Player#abort
 * @type {EventTarget~Event}
 */

/**
 * Retrigger the `abort` event that was triggered by the {@link Tech}.
 *
 * @private
 * @method Player#handleTechAbort_
 * @fires Player#abort
 * @listens Tech#abort
 */
'abort',
/**
 * Fires when the browser is intentionally not getting media data.
 *
 * @event Player#suspend
 * @type {EventTarget~Event}
 */

/**
 * Retrigger the `suspend` event that was triggered by the {@link Tech}.
 *
 * @private
 * @method Player#handleTechSuspend_
 * @fires Player#suspend
 * @listens Tech#suspend
 */
'suspend',
/**
 * Fires when the current playlist is empty.
 *
 * @event Player#emptied
 * @type {EventTarget~Event}
 */

/**
 * Retrigger the `emptied` event that was triggered by the {@link Tech}.
 *
 * @private
 * @method Player#handleTechEmptied_
 * @fires Player#emptied
 * @listens Tech#emptied
 */
'emptied',
/**
 * Fires when the browser is trying to get media data, but data is not available.
 *
 * @event Player#stalled
 * @type {EventTarget~Event}
 */

/**
 * Retrigger the `stalled` event that was triggered by the {@link Tech}.
 *
 * @private
 * @method Player#handleTechStalled_
 * @fires Player#stalled
 * @listens Tech#stalled
 */
'stalled',
/**
 * Fires when the browser has loaded meta data for the audio/video.
 *
 * @event Player#loadedmetadata
 * @type {EventTarget~Event}
 */

/**
 * Retrigger the `loadedmetadata` event that was triggered by the {@link Tech}.
 *
 * @private
 * @method Player#handleTechLoadedmetadata_
 * @fires Player#loadedmetadata
 * @listens Tech#loadedmetadata
 */
'loadedmetadata',
/**
 * Fires when the browser has loaded the current frame of the audio/video.
 *
 * @event Player#loadeddata
 * @type {event}
 */

/**
 * Retrigger the `loadeddata` event that was triggered by the {@link Tech}.
 *
 * @private
 * @method Player#handleTechLoaddeddata_
 * @fires Player#loadeddata
 * @listens Tech#loadeddata
 */
'loadeddata',
/**
 * Fires when the current playback position has changed.
 *
 * @event Player#timeupdate
 * @type {event}
 */

/**
 * Retrigger the `timeupdate` event that was triggered by the {@link Tech}.
 *
 * @private
 * @method Player#handleTechTimeUpdate_
 * @fires Player#timeupdate
 * @listens Tech#timeupdate
 */
'timeupdate',
/**
 * Fires when the video's intrinsic dimensions change
 *
 * @event Player#resize
 * @type {event}
 */

/**
 * Retrigger the `resize` event that was triggered by the {@link Tech}.
 *
 * @private
 * @method Player#handleTechResize_
 * @fires Player#resize
 * @listens Tech#resize
 */
'resize',
/**
 * Fires when the volume has been changed
 *
 * @event Player#volumechange
 * @type {event}
 */

/**
 * Retrigger the `volumechange` event that was triggered by the {@link Tech}.
 *
 * @private
 * @method Player#handleTechVolumechange_
 * @fires Player#volumechange
 * @listens Tech#volumechange
 */
'volumechange',
/**
 * Fires when the text track has been changed
 *
 * @event Player#texttrackchange
 * @type {event}
 */

/**
 * Retrigger the `texttrackchange` event that was triggered by the {@link Tech}.
 *
 * @private
 * @method Player#handleTechTexttrackchange_
 * @fires Player#texttrackchange
 * @listens Tech#texttrackchange
 */
'texttrackchange']; // events to queue when playback rate is zero
// this is a hash for the sole purpose of mapping non-camel-cased event names
// to camel-cased function names

var TECH_EVENTS_QUEUE = {
  canplay: 'CanPlay',
  canplaythrough: 'CanPlayThrough',
  playing: 'Playing',
  seeked: 'Seeked'
};
var BREAKPOINT_ORDER = ['tiny', 'xsmall', 'small', 'medium', 'large', 'xlarge', 'huge'];
var BREAKPOINT_CLASSES = {}; // grep: vjs-layout-tiny
// grep: vjs-layout-x-small
// grep: vjs-layout-small
// grep: vjs-layout-medium
// grep: vjs-layout-large
// grep: vjs-layout-x-large
// grep: vjs-layout-huge

BREAKPOINT_ORDER.forEach(function (k) {
  var v = k.charAt(0) === 'x' ? "x-" + k.substring(1) : k;
  BREAKPOINT_CLASSES[k] = "vjs-layout-" + v;
});
var DEFAULT_BREAKPOINTS = {
  tiny: 210,
  xsmall: 320,
  small: 425,
  medium: 768,
  large: 1440,
  xlarge: 2560,
  huge: Infinity
};
/**
 * An instance of the `Player` class is created when any of the Video.js setup methods
 * are used to initialize a video.
 *
 * After an instance has been created it can be accessed globally in two ways:
 * 1. By calling `videojs('example_video_1');`
 * 2. By using it directly via  `videojs.players.example_video_1;`
 *
 * @extends Component
 */

var Player = /*#__PURE__*/function (_Component) {
  _inheritsLoose__default['default'](Player, _Component);

  /**
   * Create an instance of this class.
   *
   * @param {Element} tag
   *        The original video DOM element used for configuring options.
   *
   * @param {Object} [options]
   *        Object of option names and values.
   *
   * @param {Component~ReadyCallback} [ready]
   *        Ready callback function.
   */
  function Player(tag, options, ready) {
    var _this;

    // Make sure tag ID exists
    tag.id = tag.id || options.id || "vjs_video_" + newGUID(); // Set Options
    // The options argument overrides options set in the video tag
    // which overrides globally set options.
    // This latter part coincides with the load order
    // (tag must exist before Player)

    options = assign(Player.getTagSettings(tag), options); // Delay the initialization of children because we need to set up
    // player properties first, and can't use `this` before `super()`

    options.initChildren = false; // Same with creating the element

    options.createEl = false; // don't auto mixin the evented mixin

    options.evented = false; // we don't want the player to report touch activity on itself
    // see enableTouchActivity in Component

    options.reportTouchActivity = false; // If language is not set, get the closest lang attribute

    if (!options.language) {
      if (typeof tag.closest === 'function') {
        var closest = tag.closest('[lang]');

        if (closest && closest.getAttribute) {
          options.language = closest.getAttribute('lang');
        }
      } else {
        var element = tag;

        while (element && element.nodeType === 1) {
          if (getAttributes(element).hasOwnProperty('lang')) {
            options.language = element.getAttribute('lang');
            break;
          }

          element = element.parentNode;
        }
      }
    } // Run base component initializing with new options


    _this = _Component.call(this, null, options, ready) || this; // Create bound methods for document listeners.

    _this.boundDocumentFullscreenChange_ = function (e) {
      return _this.documentFullscreenChange_(e);
    };

    _this.boundFullWindowOnEscKey_ = function (e) {
      return _this.fullWindowOnEscKey(e);
    };

    _this.boundUpdateStyleEl_ = function (e) {
      return _this.updateStyleEl_(e);
    };

    _this.boundApplyInitTime_ = function (e) {
      return _this.applyInitTime_(e);
    };

    _this.boundUpdateCurrentBreakpoint_ = function (e) {
      return _this.updateCurrentBreakpoint_(e);
    };

    _this.boundHandleTechClick_ = function (e) {
      return _this.handleTechClick_(e);
    };

    _this.boundHandleTechDoubleClick_ = function (e) {
      return _this.handleTechDoubleClick_(e);
    };

    _this.boundHandleTechTouchStart_ = function (e) {
      return _this.handleTechTouchStart_(e);
    };

    _this.boundHandleTechTouchMove_ = function (e) {
      return _this.handleTechTouchMove_(e);
    };

    _this.boundHandleTechTouchEnd_ = function (e) {
      return _this.handleTechTouchEnd_(e);
    };

    _this.boundHandleTechTap_ = function (e) {
      return _this.handleTechTap_(e);
    }; // default isFullscreen_ to false


    _this.isFullscreen_ = false; // create logger

    _this.log = createLogger(_this.id_); // Hold our own reference to fullscreen api so it can be mocked in tests

    _this.fsApi_ = FullscreenApi; // Tracks when a tech changes the poster

    _this.isPosterFromTech_ = false; // Holds callback info that gets queued when playback rate is zero
    // and a seek is happening

    _this.queuedCallbacks_ = []; // Turn off API access because we're loading a new tech that might load asynchronously

    _this.isReady_ = false; // Init state hasStarted_

    _this.hasStarted_ = false; // Init state userActive_

    _this.userActive_ = false; // Init debugEnabled_

    _this.debugEnabled_ = false; // if the global option object was accidentally blown away by
    // someone, bail early with an informative error

    if (!_this.options_ || !_this.options_.techOrder || !_this.options_.techOrder.length) {
      throw new Error('No techOrder specified. Did you overwrite ' + 'videojs.options instead of just changing the ' + 'properties you want to override?');
    } // Store the original tag used to set options


    _this.tag = tag; // Store the tag attributes used to restore html5 element

    _this.tagAttributes = tag && getAttributes(tag); // Update current language

    _this.language(_this.options_.language); // Update Supported Languages


    if (options.languages) {
      // Normalise player option languages to lowercase
      var languagesToLower = {};
      Object.getOwnPropertyNames(options.languages).forEach(function (name) {
        languagesToLower[name.toLowerCase()] = options.languages[name];
      });
      _this.languages_ = languagesToLower;
    } else {
      _this.languages_ = Player.prototype.options_.languages;
    }

    _this.resetCache_(); // Set poster


    _this.poster_ = options.poster || ''; // Set controls

    _this.controls_ = !!options.controls; // Original tag settings stored in options
    // now remove immediately so native controls don't flash.
    // May be turned back on by HTML5 tech if nativeControlsForTouch is true

    tag.controls = false;
    tag.removeAttribute('controls');
    _this.changingSrc_ = false;
    _this.playCallbacks_ = [];
    _this.playTerminatedQueue_ = []; // the attribute overrides the option

    if (tag.hasAttribute('autoplay')) {
      _this.autoplay(true);
    } else {
      // otherwise use the setter to validate and
      // set the correct value.
      _this.autoplay(_this.options_.autoplay);
    } // check plugins


    if (options.plugins) {
      Object.keys(options.plugins).forEach(function (name) {
        if (typeof _this[name] !== 'function') {
          throw new Error("plugin \"" + name + "\" does not exist");
        }
      });
    }
    /*
     * Store the internal state of scrubbing
     *
     * @private
     * @return {Boolean} True if the user is scrubbing
     */


    _this.scrubbing_ = false;
    _this.el_ = _this.createEl(); // Make this an evented object and use `el_` as its event bus.

    evented(_assertThisInitialized__default['default'](_this), {
      eventBusKey: 'el_'
    }); // listen to document and player fullscreenchange handlers so we receive those events
    // before a user can receive them so we can update isFullscreen appropriately.
    // make sure that we listen to fullscreenchange events before everything else to make sure that
    // our isFullscreen method is updated properly for internal components as well as external.

    if (_this.fsApi_.requestFullscreen) {
      on(document__default['default'], _this.fsApi_.fullscreenchange, _this.boundDocumentFullscreenChange_);

      _this.on(_this.fsApi_.fullscreenchange, _this.boundDocumentFullscreenChange_);
    }

    if (_this.fluid_) {
      _this.on(['playerreset', 'resize'], _this.boundUpdateStyleEl_);
    } // We also want to pass the original player options to each component and plugin
    // as well so they don't need to reach back into the player for options later.
    // We also need to do another copy of this.options_ so we don't end up with
    // an infinite loop.


    var playerOptionsCopy = mergeOptions(_this.options_); // Load plugins

    if (options.plugins) {
      Object.keys(options.plugins).forEach(function (name) {
        _this[name](options.plugins[name]);
      });
    } // Enable debug mode to fire debugon event for all plugins.


    if (options.debug) {
      _this.debug(true);
    }

    _this.options_.playerOptions = playerOptionsCopy;
    _this.middleware_ = [];

    _this.playbackRates(options.playbackRates);

    _this.initChildren(); // Set isAudio based on whether or not an audio tag was used


    _this.isAudio(tag.nodeName.toLowerCase() === 'audio'); // Update controls className. Can't do this when the controls are initially
    // set because the element doesn't exist yet.


    if (_this.controls()) {
      _this.addClass('vjs-controls-enabled');
    } else {
      _this.addClass('vjs-controls-disabled');
    } // Set ARIA label and region role depending on player type


    _this.el_.setAttribute('role', 'region');

    if (_this.isAudio()) {
      _this.el_.setAttribute('aria-label', _this.localize('Audio Player'));
    } else {
      _this.el_.setAttribute('aria-label', _this.localize('Video Player'));
    }

    if (_this.isAudio()) {
      _this.addClass('vjs-audio');
    }

    if (_this.flexNotSupported_()) {
      _this.addClass('vjs-no-flex');
    } // TODO: Make this smarter. Toggle user state between touching/mousing
    // using events, since devices can have both touch and mouse events.
    // TODO: Make this check be performed again when the window switches between monitors
    // (See https://github.com/videojs/video.js/issues/5683)


    if (TOUCH_ENABLED) {
      _this.addClass('vjs-touch-enabled');
    } // iOS Safari has broken hover handling


    if (!IS_IOS) {
      _this.addClass('vjs-workinghover');
    } // Make player easily findable by ID


    Player.players[_this.id_] = _assertThisInitialized__default['default'](_this); // Add a major version class to aid css in plugins

    var majorVersion = version.split('.')[0];

    _this.addClass("vjs-v" + majorVersion); // When the player is first initialized, trigger activity so components
    // like the control bar show themselves if needed


    _this.userActive(true);

    _this.reportUserActivity();

    _this.one('play', function (e) {
      return _this.listenForUserActivity_(e);
    });

    _this.on('stageclick', function (e) {
      return _this.handleStageClick_(e);
    });

    _this.on('keydown', function (e) {
      return _this.handleKeyDown(e);
    });

    _this.on('languagechange', function (e) {
      return _this.handleLanguagechange(e);
    });

    _this.breakpoints(_this.options_.breakpoints);

    _this.responsive(_this.options_.responsive);

    return _this;
  }
  /**
   * Destroys the video player and does any necessary cleanup.
   *
   * This is especially helpful if you are dynamically adding and removing videos
   * to/from the DOM.
   *
   * @fires Player#dispose
   */


  var _proto = Player.prototype;

  _proto.dispose = function dispose() {
    var _this2 = this;

    /**
     * Called when the player is being disposed of.
     *
     * @event Player#dispose
     * @type {EventTarget~Event}
     */
    this.trigger('dispose'); // prevent dispose from being called twice

    this.off('dispose'); // Make sure all player-specific document listeners are unbound. This is

    off(document__default['default'], this.fsApi_.fullscreenchange, this.boundDocumentFullscreenChange_);
    off(document__default['default'], 'keydown', this.boundFullWindowOnEscKey_);

    if (this.styleEl_ && this.styleEl_.parentNode) {
      this.styleEl_.parentNode.removeChild(this.styleEl_);
      this.styleEl_ = null;
    } // Kill reference to this player


    Player.players[this.id_] = null;

    if (this.tag && this.tag.player) {
      this.tag.player = null;
    }

    if (this.el_ && this.el_.player) {
      this.el_.player = null;
    }

    if (this.tech_) {
      this.tech_.dispose();
      this.isPosterFromTech_ = false;
      this.poster_ = '';
    }

    if (this.playerElIngest_) {
      this.playerElIngest_ = null;
    }

    if (this.tag) {
      this.tag = null;
    }

    clearCacheForPlayer(this); // remove all event handlers for track lists
    // all tracks and track listeners are removed on
    // tech dispose

    ALL.names.forEach(function (name) {
      var props = ALL[name];

      var list = _this2[props.getterName](); // if it is not a native list
      // we have to manually remove event listeners


      if (list && list.off) {
        list.off();
      }
    }); // the actual .el_ is removed here

    _Component.prototype.dispose.call(this);
  }
  /**
   * Create the `Player`'s DOM element.
   *
   * @return {Element}
   *         The DOM element that gets created.
   */
  ;

  _proto.createEl = function createEl() {
    var tag = this.tag;
    var el;
    var playerElIngest = this.playerElIngest_ = tag.parentNode && tag.parentNode.hasAttribute && tag.parentNode.hasAttribute('data-vjs-player');
    var divEmbed = this.tag.tagName.toLowerCase() === 'video-js';

    if (playerElIngest) {
      el = this.el_ = tag.parentNode;
    } else if (!divEmbed) {
      el = this.el_ = _Component.prototype.createEl.call(this, 'div');
    } // Copy over all the attributes from the tag, including ID and class
    // ID will now reference player box, not the video tag


    var attrs = getAttributes(tag);

    if (divEmbed) {
      el = this.el_ = tag;
      tag = this.tag = document__default['default'].createElement('video');

      while (el.children.length) {
        tag.appendChild(el.firstChild);
      }

      if (!hasClass(el, 'video-js')) {
        addClass(el, 'video-js');
      }

      el.appendChild(tag);
      playerElIngest = this.playerElIngest_ = el; // move properties over from our custom `video-js` element
      // to our new `video` element. This will move things like
      // `src` or `controls` that were set via js before the player
      // was initialized.

      Object.keys(el).forEach(function (k) {
        try {
          tag[k] = el[k];
        } catch (e) {// we got a a property like outerHTML which we can't actually copy, ignore it
        }
      });
    } // set tabindex to -1 to remove the video element from the focus order


    tag.setAttribute('tabindex', '-1');
    attrs.tabindex = '-1'; // Workaround for #4583 (JAWS+IE doesn't announce BPB or play button), and
    // for the same issue with Chrome (on Windows) with JAWS.
    // See https://github.com/FreedomScientific/VFO-standards-support/issues/78
    // Note that we can't detect if JAWS is being used, but this ARIA attribute
    //  doesn't change behavior of IE11 or Chrome if JAWS is not being used

    if (IE_VERSION || IS_CHROME && IS_WINDOWS) {
      tag.setAttribute('role', 'application');
      attrs.role = 'application';
    } // Remove width/height attrs from tag so CSS can make it 100% width/height


    tag.removeAttribute('width');
    tag.removeAttribute('height');

    if ('width' in attrs) {
      delete attrs.width;
    }

    if ('height' in attrs) {
      delete attrs.height;
    }

    Object.getOwnPropertyNames(attrs).forEach(function (attr) {
      // don't copy over the class attribute to the player element when we're in a div embed
      // the class is already set up properly in the divEmbed case
      // and we want to make sure that the `video-js` class doesn't get lost
      if (!(divEmbed && attr === 'class')) {
        el.setAttribute(attr, attrs[attr]);
      }

      if (divEmbed) {
        tag.setAttribute(attr, attrs[attr]);
      }
    }); // Update tag id/class for use as HTML5 playback tech
    // Might think we should do this after embedding in container so .vjs-tech class
    // doesn't flash 100% width/height, but class only applies with .video-js parent

    tag.playerId = tag.id;
    tag.id += '_html5_api';
    tag.className = 'vjs-tech'; // Make player findable on elements

    tag.player = el.player = this; // Default state of video is paused

    this.addClass('vjs-paused'); // Add a style element in the player that we'll use to set the width/height
    // of the player in a way that's still overrideable by CSS, just like the
    // video element

    if (window__default['default'].VIDEOJS_NO_DYNAMIC_STYLE !== true) {
      this.styleEl_ = createStyleElement('vjs-styles-dimensions');
      var defaultsStyleEl = $('.vjs-styles-defaults');
      var head = $('head');
      head.insertBefore(this.styleEl_, defaultsStyleEl ? defaultsStyleEl.nextSibling : head.firstChild);
    }

    this.fill_ = false;
    this.fluid_ = false; // Pass in the width/height/aspectRatio options which will update the style el

    this.width(this.options_.width);
    this.height(this.options_.height);
    this.fill(this.options_.fill);
    this.fluid(this.options_.fluid);
    this.aspectRatio(this.options_.aspectRatio); // support both crossOrigin and crossorigin to reduce confusion and issues around the name

    this.crossOrigin(this.options_.crossOrigin || this.options_.crossorigin); // Hide any links within the video/audio tag,
    // because IE doesn't hide them completely from screen readers.

    var links = tag.getElementsByTagName('a');

    for (var i = 0; i < links.length; i++) {
      var linkEl = links.item(i);
      addClass(linkEl, 'vjs-hidden');
      linkEl.setAttribute('hidden', 'hidden');
    } // insertElFirst seems to cause the networkState to flicker from 3 to 2, so
    // keep track of the original for later so we can know if the source originally failed


    tag.initNetworkState_ = tag.networkState; // Wrap video tag in div (el/box) container

    if (tag.parentNode && !playerElIngest) {
      tag.parentNode.insertBefore(el, tag);
    } // insert the tag as the first child of the player element
    // then manually add it to the children array so that this.addChild
    // will work properly for other components
    //
    // Breaks iPhone, fixed in HTML5 setup.


    prependTo(tag, el);
    this.children_.unshift(tag); // Set lang attr on player to ensure CSS :lang() in consistent with player
    // if it's been set to something different to the doc

    this.el_.setAttribute('lang', this.language_);
    this.el_.setAttribute('translate', 'no');
    this.el_ = el;
    return el;
  }
  /**
   * Get or set the `Player`'s crossOrigin option. For the HTML5 player, this
   * sets the `crossOrigin` property on the `<video>` tag to control the CORS
   * behavior.
   *
   * @see [Video Element Attributes]{@link https://developer.mozilla.org/en-US/docs/Web/HTML/Element/video#attr-crossorigin}
   *
   * @param {string} [value]
   *        The value to set the `Player`'s crossOrigin to. If an argument is
   *        given, must be one of `anonymous` or `use-credentials`.
   *
   * @return {string|undefined}
   *         - The current crossOrigin value of the `Player` when getting.
   *         - undefined when setting
   */
  ;

  _proto.crossOrigin = function crossOrigin(value) {
    if (!value) {
      return this.techGet_('crossOrigin');
    }

    if (value !== 'anonymous' && value !== 'use-credentials') {
      log.warn("crossOrigin must be \"anonymous\" or \"use-credentials\", given \"" + value + "\"");
      return;
    }

    this.techCall_('setCrossOrigin', value);
    return;
  }
  /**
   * A getter/setter for the `Player`'s width. Returns the player's configured value.
   * To get the current width use `currentWidth()`.
   *
   * @param {number} [value]
   *        The value to set the `Player`'s width to.
   *
   * @return {number}
   *         The current width of the `Player` when getting.
   */
  ;

  _proto.width = function width(value) {
    return this.dimension('width', value);
  }
  /**
   * A getter/setter for the `Player`'s height. Returns the player's configured value.
   * To get the current height use `currentheight()`.
   *
   * @param {number} [value]
   *        The value to set the `Player`'s heigth to.
   *
   * @return {number}
   *         The current height of the `Player` when getting.
   */
  ;

  _proto.height = function height(value) {
    return this.dimension('height', value);
  }
  /**
   * A getter/setter for the `Player`'s width & height.
   *
   * @param {string} dimension
   *        This string can be:
   *        - 'width'
   *        - 'height'
   *
   * @param {number} [value]
   *        Value for dimension specified in the first argument.
   *
   * @return {number}
   *         The dimension arguments value when getting (width/height).
   */
  ;

  _proto.dimension = function dimension(_dimension, value) {
    var privDimension = _dimension + '_';

    if (value === undefined) {
      return this[privDimension] || 0;
    }

    if (value === '' || value === 'auto') {
      // If an empty string is given, reset the dimension to be automatic
      this[privDimension] = undefined;
      this.updateStyleEl_();
      return;
    }

    var parsedVal = parseFloat(value);

    if (isNaN(parsedVal)) {
      log.error("Improper value \"" + value + "\" supplied for for " + _dimension);
      return;
    }

    this[privDimension] = parsedVal;
    this.updateStyleEl_();
  }
  /**
   * A getter/setter/toggler for the vjs-fluid `className` on the `Player`.
   *
   * Turning this on will turn off fill mode.
   *
   * @param {boolean} [bool]
   *        - A value of true adds the class.
   *        - A value of false removes the class.
   *        - No value will be a getter.
   *
   * @return {boolean|undefined}
   *         - The value of fluid when getting.
   *         - `undefined` when setting.
   */
  ;

  _proto.fluid = function fluid(bool) {
    var _this3 = this;

    if (bool === undefined) {
      return !!this.fluid_;
    }

    this.fluid_ = !!bool;

    if (isEvented(this)) {
      this.off(['playerreset', 'resize'], this.boundUpdateStyleEl_);
    }

    if (bool) {
      this.addClass('vjs-fluid');
      this.fill(false);
      addEventedCallback(this, function () {
        _this3.on(['playerreset', 'resize'], _this3.boundUpdateStyleEl_);
      });
    } else {
      this.removeClass('vjs-fluid');
    }

    this.updateStyleEl_();
  }
  /**
   * A getter/setter/toggler for the vjs-fill `className` on the `Player`.
   *
   * Turning this on will turn off fluid mode.
   *
   * @param {boolean} [bool]
   *        - A value of true adds the class.
   *        - A value of false removes the class.
   *        - No value will be a getter.
   *
   * @return {boolean|undefined}
   *         - The value of fluid when getting.
   *         - `undefined` when setting.
   */
  ;

  _proto.fill = function fill(bool) {
    if (bool === undefined) {
      return !!this.fill_;
    }

    this.fill_ = !!bool;

    if (bool) {
      this.addClass('vjs-fill');
      this.fluid(false);
    } else {
      this.removeClass('vjs-fill');
    }
  }
  /**
   * Get/Set the aspect ratio
   *
   * @param {string} [ratio]
   *        Aspect ratio for player
   *
   * @return {string|undefined}
   *         returns the current aspect ratio when getting
   */

  /**
   * A getter/setter for the `Player`'s aspect ratio.
   *
   * @param {string} [ratio]
   *        The value to set the `Player`'s aspect ratio to.
   *
   * @return {string|undefined}
   *         - The current aspect ratio of the `Player` when getting.
   *         - undefined when setting
   */
  ;

  _proto.aspectRatio = function aspectRatio(ratio) {
    if (ratio === undefined) {
      return this.aspectRatio_;
    } // Check for width:height format


    if (!/^\d+\:\d+$/.test(ratio)) {
      throw new Error('Improper value supplied for aspect ratio. The format should be width:height, for example 16:9.');
    }

    this.aspectRatio_ = ratio; // We're assuming if you set an aspect ratio you want fluid mode,
    // because in fixed mode you could calculate width and height yourself.

    this.fluid(true);
    this.updateStyleEl_();
  }
  /**
   * Update styles of the `Player` element (height, width and aspect ratio).
   *
   * @private
   * @listens Tech#loadedmetadata
   */
  ;

  _proto.updateStyleEl_ = function updateStyleEl_() {
    if (window__default['default'].VIDEOJS_NO_DYNAMIC_STYLE === true) {
      var _width = typeof this.width_ === 'number' ? this.width_ : this.options_.width;

      var _height = typeof this.height_ === 'number' ? this.height_ : this.options_.height;

      var techEl = this.tech_ && this.tech_.el();

      if (techEl) {
        if (_width >= 0) {
          techEl.width = _width;
        }

        if (_height >= 0) {
          techEl.height = _height;
        }
      }

      return;
    }

    var width;
    var height;
    var aspectRatio;
    var idClass; // The aspect ratio is either used directly or to calculate width and height.

    if (this.aspectRatio_ !== undefined && this.aspectRatio_ !== 'auto') {
      // Use any aspectRatio that's been specifically set
      aspectRatio = this.aspectRatio_;
    } else if (this.videoWidth() > 0) {
      // Otherwise try to get the aspect ratio from the video metadata
      aspectRatio = this.videoWidth() + ':' + this.videoHeight();
    } else {
      // Or use a default. The video element's is 2:1, but 16:9 is more common.
      aspectRatio = '16:9';
    } // Get the ratio as a decimal we can use to calculate dimensions


    var ratioParts = aspectRatio.split(':');
    var ratioMultiplier = ratioParts[1] / ratioParts[0];

    if (this.width_ !== undefined) {
      // Use any width that's been specifically set
      width = this.width_;
    } else if (this.height_ !== undefined) {
      // Or calulate the width from the aspect ratio if a height has been set
      width = this.height_ / ratioMultiplier;
    } else {
      // Or use the video's metadata, or use the video el's default of 300
      width = this.videoWidth() || 300;
    }

    if (this.height_ !== undefined) {
      // Use any height that's been specifically set
      height = this.height_;
    } else {
      // Otherwise calculate the height from the ratio and the width
      height = width * ratioMultiplier;
    } // Ensure the CSS class is valid by starting with an alpha character


    if (/^[^a-zA-Z]/.test(this.id())) {
      idClass = 'dimensions-' + this.id();
    } else {
      idClass = this.id() + '-dimensions';
    } // Ensure the right class is still on the player for the style element


    this.addClass(idClass);
    setTextContent(this.styleEl_, "\n      ." + idClass + " {\n        width: " + width + "px;\n        height: " + height + "px;\n      }\n\n      ." + idClass + ".vjs-fluid {\n        padding-top: " + ratioMultiplier * 100 + "%;\n      }\n    ");
  }
  /**
   * Load/Create an instance of playback {@link Tech} including element
   * and API methods. Then append the `Tech` element in `Player` as a child.
   *
   * @param {string} techName
   *        name of the playback technology
   *
   * @param {string} source
   *        video source
   *
   * @private
   */
  ;

  _proto.loadTech_ = function loadTech_(techName, source) {
    var _this4 = this;

    // Pause and remove current playback technology
    if (this.tech_) {
      this.unloadTech_();
    }

    var titleTechName = toTitleCase(techName);
    var camelTechName = techName.charAt(0).toLowerCase() + techName.slice(1); // get rid of the HTML5 video tag as soon as we are using another tech

    if (titleTechName !== 'Html5' && this.tag) {
      Tech.getTech('Html5').disposeMediaElement(this.tag);
      this.tag.player = null;
      this.tag = null;
    }

    this.techName_ = titleTechName; // Turn off API access because we're loading a new tech that might load asynchronously

    this.isReady_ = false;
    var autoplay = this.autoplay(); // if autoplay is a string (or `true` with normalizeAutoplay: true) we pass false to the tech
    // because the player is going to handle autoplay on `loadstart`

    if (typeof this.autoplay() === 'string' || this.autoplay() === true && this.options_.normalizeAutoplay) {
      autoplay = false;
    } // Grab tech-specific options from player options and add source and parent element to use.


    var techOptions = {
      source: source,
      autoplay: autoplay,
      'nativeControlsForTouch': this.options_.nativeControlsForTouch,
      'playerId': this.id(),
      'techId': this.id() + "_" + camelTechName + "_api",
      'playsinline': this.options_.playsinline,
      'preload': this.options_.preload,
      'loop': this.options_.loop,
      'disablePictureInPicture': this.options_.disablePictureInPicture,
      'muted': this.options_.muted,
      'poster': this.poster(),
      'language': this.language(),
      'playerElIngest': this.playerElIngest_ || false,
      'vtt.js': this.options_['vtt.js'],
      'canOverridePoster': !!this.options_.techCanOverridePoster,
      'enableSourceset': this.options_.enableSourceset,
      'Promise': this.options_.Promise
    };
    ALL.names.forEach(function (name) {
      var props = ALL[name];
      techOptions[props.getterName] = _this4[props.privateName];
    });
    assign(techOptions, this.options_[titleTechName]);
    assign(techOptions, this.options_[camelTechName]);
    assign(techOptions, this.options_[techName.toLowerCase()]);

    if (this.tag) {
      techOptions.tag = this.tag;
    }

    if (source && source.src === this.cache_.src && this.cache_.currentTime > 0) {
      techOptions.startTime = this.cache_.currentTime;
    } // Initialize tech instance


    var TechClass = Tech.getTech(techName);

    if (!TechClass) {
      throw new Error("No Tech named '" + titleTechName + "' exists! '" + titleTechName + "' should be registered using videojs.registerTech()'");
    }

    this.tech_ = new TechClass(techOptions); // player.triggerReady is always async, so don't need this to be async

    this.tech_.ready(bind(this, this.handleTechReady_), true);
    textTrackConverter.jsonToTextTracks(this.textTracksJson_ || [], this.tech_); // Listen to all HTML5-defined events and trigger them on the player

    TECH_EVENTS_RETRIGGER.forEach(function (event) {
      _this4.on(_this4.tech_, event, function (e) {
        return _this4["handleTech" + toTitleCase(event) + "_"](e);
      });
    });
    Object.keys(TECH_EVENTS_QUEUE).forEach(function (event) {
      _this4.on(_this4.tech_, event, function (eventObj) {
        if (_this4.tech_.playbackRate() === 0 && _this4.tech_.seeking()) {
          _this4.queuedCallbacks_.push({
            callback: _this4["handleTech" + TECH_EVENTS_QUEUE[event] + "_"].bind(_this4),
            event: eventObj
          });

          return;
        }

        _this4["handleTech" + TECH_EVENTS_QUEUE[event] + "_"](eventObj);
      });
    });
    this.on(this.tech_, 'loadstart', function (e) {
      return _this4.handleTechLoadStart_(e);
    });
    this.on(this.tech_, 'sourceset', function (e) {
      return _this4.handleTechSourceset_(e);
    });
    this.on(this.tech_, 'waiting', function (e) {
      return _this4.handleTechWaiting_(e);
    });
    this.on(this.tech_, 'ended', function (e) {
      return _this4.handleTechEnded_(e);
    });
    this.on(this.tech_, 'seeking', function (e) {
      return _this4.handleTechSeeking_(e);
    });
    this.on(this.tech_, 'play', function (e) {
      return _this4.handleTechPlay_(e);
    });
    this.on(this.tech_, 'firstplay', function (e) {
      return _this4.handleTechFirstPlay_(e);
    });
    this.on(this.tech_, 'pause', function (e) {
      return _this4.handleTechPause_(e);
    });
    this.on(this.tech_, 'durationchange', function (e) {
      return _this4.handleTechDurationChange_(e);
    });
    this.on(this.tech_, 'fullscreenchange', function (e, data) {
      return _this4.handleTechFullscreenChange_(e, data);
    });
    this.on(this.tech_, 'fullscreenerror', function (e, err) {
      return _this4.handleTechFullscreenError_(e, err);
    });
    this.on(this.tech_, 'enterpictureinpicture', function (e) {
      return _this4.handleTechEnterPictureInPicture_(e);
    });
    this.on(this.tech_, 'leavepictureinpicture', function (e) {
      return _this4.handleTechLeavePictureInPicture_(e);
    });
    this.on(this.tech_, 'error', function (e) {
      return _this4.handleTechError_(e);
    });
    this.on(this.tech_, 'posterchange', function (e) {
      return _this4.handleTechPosterChange_(e);
    });
    this.on(this.tech_, 'textdata', function (e) {
      return _this4.handleTechTextData_(e);
    });
    this.on(this.tech_, 'ratechange', function (e) {
      return _this4.handleTechRateChange_(e);
    });
    this.on(this.tech_, 'loadedmetadata', this.boundUpdateStyleEl_);
    this.usingNativeControls(this.techGet_('controls'));

    if (this.controls() && !this.usingNativeControls()) {
      this.addTechControlsListeners_();
    } // Add the tech element in the DOM if it was not already there
    // Make sure to not insert the original video element if using Html5


    if (this.tech_.el().parentNode !== this.el() && (titleTechName !== 'Html5' || !this.tag)) {
      prependTo(this.tech_.el(), this.el());
    } // Get rid of the original video tag reference after the first tech is loaded


    if (this.tag) {
      this.tag.player = null;
      this.tag = null;
    }
  }
  /**
   * Unload and dispose of the current playback {@link Tech}.
   *
   * @private
   */
  ;

  _proto.unloadTech_ = function unloadTech_() {
    var _this5 = this;

    // Save the current text tracks so that we can reuse the same text tracks with the next tech
    ALL.names.forEach(function (name) {
      var props = ALL[name];
      _this5[props.privateName] = _this5[props.getterName]();
    });
    this.textTracksJson_ = textTrackConverter.textTracksToJson(this.tech_);
    this.isReady_ = false;
    this.tech_.dispose();
    this.tech_ = false;

    if (this.isPosterFromTech_) {
      this.poster_ = '';
      this.trigger('posterchange');
    }

    this.isPosterFromTech_ = false;
  }
  /**
   * Return a reference to the current {@link Tech}.
   * It will print a warning by default about the danger of using the tech directly
   * but any argument that is passed in will silence the warning.
   *
   * @param {*} [safety]
   *        Anything passed in to silence the warning
   *
   * @return {Tech}
   *         The Tech
   */
  ;

  _proto.tech = function tech(safety) {
    if (safety === undefined) {
      log.warn('Using the tech directly can be dangerous. I hope you know what you\'re doing.\n' + 'See https://github.com/videojs/video.js/issues/2617 for more info.\n');
    }

    return this.tech_;
  }
  /**
   * Set up click and touch listeners for the playback element
   *
   * - On desktops: a click on the video itself will toggle playback
   * - On mobile devices: a click on the video toggles controls
   *   which is done by toggling the user state between active and
   *   inactive
   * - A tap can signal that a user has become active or has become inactive
   *   e.g. a quick tap on an iPhone movie should reveal the controls. Another
   *   quick tap should hide them again (signaling the user is in an inactive
   *   viewing state)
   * - In addition to this, we still want the user to be considered inactive after
   *   a few seconds of inactivity.
   *
   * > Note: the only part of iOS interaction we can't mimic with this setup
   * is a touch and hold on the video element counting as activity in order to
   * keep the controls showing, but that shouldn't be an issue. A touch and hold
   * on any controls will still keep the user active
   *
   * @private
   */
  ;

  _proto.addTechControlsListeners_ = function addTechControlsListeners_() {
    // Make sure to remove all the previous listeners in case we are called multiple times.
    this.removeTechControlsListeners_();
    this.on(this.tech_, 'click', this.boundHandleTechClick_);
    this.on(this.tech_, 'dblclick', this.boundHandleTechDoubleClick_); // If the controls were hidden we don't want that to change without a tap event
    // so we'll check if the controls were already showing before reporting user
    // activity

    this.on(this.tech_, 'touchstart', this.boundHandleTechTouchStart_);
    this.on(this.tech_, 'touchmove', this.boundHandleTechTouchMove_);
    this.on(this.tech_, 'touchend', this.boundHandleTechTouchEnd_); // The tap listener needs to come after the touchend listener because the tap
    // listener cancels out any reportedUserActivity when setting userActive(false)

    this.on(this.tech_, 'tap', this.boundHandleTechTap_);
  }
  /**
   * Remove the listeners used for click and tap controls. This is needed for
   * toggling to controls disabled, where a tap/touch should do nothing.
   *
   * @private
   */
  ;

  _proto.removeTechControlsListeners_ = function removeTechControlsListeners_() {
    // We don't want to just use `this.off()` because there might be other needed
    // listeners added by techs that extend this.
    this.off(this.tech_, 'tap', this.boundHandleTechTap_);
    this.off(this.tech_, 'touchstart', this.boundHandleTechTouchStart_);
    this.off(this.tech_, 'touchmove', this.boundHandleTechTouchMove_);
    this.off(this.tech_, 'touchend', this.boundHandleTechTouchEnd_);
    this.off(this.tech_, 'click', this.boundHandleTechClick_);
    this.off(this.tech_, 'dblclick', this.boundHandleTechDoubleClick_);
  }
  /**
   * Player waits for the tech to be ready
   *
   * @private
   */
  ;

  _proto.handleTechReady_ = function handleTechReady_() {
    this.triggerReady(); // Keep the same volume as before

    if (this.cache_.volume) {
      this.techCall_('setVolume', this.cache_.volume);
    } // Look if the tech found a higher resolution poster while loading


    this.handleTechPosterChange_(); // Update the duration if available

    this.handleTechDurationChange_();
  }
  /**
   * Retrigger the `loadstart` event that was triggered by the {@link Tech}. This
   * function will also trigger {@link Player#firstplay} if it is the first loadstart
   * for a video.
   *
   * @fires Player#loadstart
   * @fires Player#firstplay
   * @listens Tech#loadstart
   * @private
   */
  ;

  _proto.handleTechLoadStart_ = function handleTechLoadStart_() {
    // TODO: Update to use `emptied` event instead. See #1277.
    this.removeClass('vjs-ended');
    this.removeClass('vjs-seeking'); // reset the error state

    this.error(null); // Update the duration

    this.handleTechDurationChange_(); // If it's already playing we want to trigger a firstplay event now.
    // The firstplay event relies on both the play and loadstart events
    // which can happen in any order for a new source

    if (!this.paused()) {
      /**
       * Fired when the user agent begins looking for media data
       *
       * @event Player#loadstart
       * @type {EventTarget~Event}
       */
      this.trigger('loadstart');
      this.trigger('firstplay');
    } else {
      // reset the hasStarted state
      this.hasStarted(false);
      this.trigger('loadstart');
    } // autoplay happens after loadstart for the browser,
    // so we mimic that behavior


    this.manualAutoplay_(this.autoplay() === true && this.options_.normalizeAutoplay ? 'play' : this.autoplay());
  }
  /**
   * Handle autoplay string values, rather than the typical boolean
   * values that should be handled by the tech. Note that this is not
   * part of any specification. Valid values and what they do can be
   * found on the autoplay getter at Player#autoplay()
   */
  ;

  _proto.manualAutoplay_ = function manualAutoplay_(type) {
    var _this6 = this;

    if (!this.tech_ || typeof type !== 'string') {
      return;
    } // Save original muted() value, set muted to true, and attempt to play().
    // On promise rejection, restore muted from saved value


    var resolveMuted = function resolveMuted() {
      var previouslyMuted = _this6.muted();

      _this6.muted(true);

      var restoreMuted = function restoreMuted() {
        _this6.muted(previouslyMuted);
      }; // restore muted on play terminatation


      _this6.playTerminatedQueue_.push(restoreMuted);

      var mutedPromise = _this6.play();

      if (!isPromise(mutedPromise)) {
        return;
      }

      return mutedPromise["catch"](function (err) {
        restoreMuted();
        throw new Error("Rejection at manualAutoplay. Restoring muted value. " + (err ? err : ''));
      });
    };

    var promise; // if muted defaults to true
    // the only thing we can do is call play

    if (type === 'any' && !this.muted()) {
      promise = this.play();

      if (isPromise(promise)) {
        promise = promise["catch"](resolveMuted);
      }
    } else if (type === 'muted' && !this.muted()) {
      promise = resolveMuted();
    } else {
      promise = this.play();
    }

    if (!isPromise(promise)) {
      return;
    }

    return promise.then(function () {
      _this6.trigger({
        type: 'autoplay-success',
        autoplay: type
      });
    })["catch"](function () {
      _this6.trigger({
        type: 'autoplay-failure',
        autoplay: type
      });
    });
  }
  /**
   * Update the internal source caches so that we return the correct source from
   * `src()`, `currentSource()`, and `currentSources()`.
   *
   * > Note: `currentSources` will not be updated if the source that is passed in exists
   *         in the current `currentSources` cache.
   *
   *
   * @param {Tech~SourceObject} srcObj
   *        A string or object source to update our caches to.
   */
  ;

  _proto.updateSourceCaches_ = function updateSourceCaches_(srcObj) {
    if (srcObj === void 0) {
      srcObj = '';
    }

    var src = srcObj;
    var type = '';

    if (typeof src !== 'string') {
      src = srcObj.src;
      type = srcObj.type;
    } // make sure all the caches are set to default values
    // to prevent null checking


    this.cache_.source = this.cache_.source || {};
    this.cache_.sources = this.cache_.sources || []; // try to get the type of the src that was passed in

    if (src && !type) {
      type = findMimetype(this, src);
    } // update `currentSource` cache always


    this.cache_.source = mergeOptions({}, srcObj, {
      src: src,
      type: type
    });
    var matchingSources = this.cache_.sources.filter(function (s) {
      return s.src && s.src === src;
    });
    var sourceElSources = [];
    var sourceEls = this.$$('source');
    var matchingSourceEls = [];

    for (var i = 0; i < sourceEls.length; i++) {
      var sourceObj = getAttributes(sourceEls[i]);
      sourceElSources.push(sourceObj);

      if (sourceObj.src && sourceObj.src === src) {
        matchingSourceEls.push(sourceObj.src);
      }
    } // if we have matching source els but not matching sources
    // the current source cache is not up to date


    if (matchingSourceEls.length && !matchingSources.length) {
      this.cache_.sources = sourceElSources; // if we don't have matching source or source els set the
      // sources cache to the `currentSource` cache
    } else if (!matchingSources.length) {
      this.cache_.sources = [this.cache_.source];
    } // update the tech `src` cache


    this.cache_.src = src;
  }
  /**
   * *EXPERIMENTAL* Fired when the source is set or changed on the {@link Tech}
   * causing the media element to reload.
   *
   * It will fire for the initial source and each subsequent source.
   * This event is a custom event from Video.js and is triggered by the {@link Tech}.
   *
   * The event object for this event contains a `src` property that will contain the source
   * that was available when the event was triggered. This is generally only necessary if Video.js
   * is switching techs while the source was being changed.
   *
   * It is also fired when `load` is called on the player (or media element)
   * because the {@link https://html.spec.whatwg.org/multipage/media.html#dom-media-load|specification for `load`}
   * says that the resource selection algorithm needs to be aborted and restarted.
   * In this case, it is very likely that the `src` property will be set to the
   * empty string `""` to indicate we do not know what the source will be but
   * that it is changing.
   *
   * *This event is currently still experimental and may change in minor releases.*
   * __To use this, pass `enableSourceset` option to the player.__
   *
   * @event Player#sourceset
   * @type {EventTarget~Event}
   * @prop {string} src
   *                The source url available when the `sourceset` was triggered.
   *                It will be an empty string if we cannot know what the source is
   *                but know that the source will change.
   */

  /**
   * Retrigger the `sourceset` event that was triggered by the {@link Tech}.
   *
   * @fires Player#sourceset
   * @listens Tech#sourceset
   * @private
   */
  ;

  _proto.handleTechSourceset_ = function handleTechSourceset_(event) {
    var _this7 = this;

    // only update the source cache when the source
    // was not updated using the player api
    if (!this.changingSrc_) {
      var updateSourceCaches = function updateSourceCaches(src) {
        return _this7.updateSourceCaches_(src);
      };

      var playerSrc = this.currentSource().src;
      var eventSrc = event.src; // if we have a playerSrc that is not a blob, and a tech src that is a blob

      if (playerSrc && !/^blob:/.test(playerSrc) && /^blob:/.test(eventSrc)) {
        // if both the tech source and the player source were updated we assume
        // something like @videojs/http-streaming did the sourceset and skip updating the source cache.
        if (!this.lastSource_ || this.lastSource_.tech !== eventSrc && this.lastSource_.player !== playerSrc) {
          updateSourceCaches = function updateSourceCaches() {};
        }
      } // update the source to the initial source right away
      // in some cases this will be empty string


      updateSourceCaches(eventSrc); // if the `sourceset` `src` was an empty string
      // wait for a `loadstart` to update the cache to `currentSrc`.
      // If a sourceset happens before a `loadstart`, we reset the state

      if (!event.src) {
        this.tech_.any(['sourceset', 'loadstart'], function (e) {
          // if a sourceset happens before a `loadstart` there
          // is nothing to do as this `handleTechSourceset_`
          // will be called again and this will be handled there.
          if (e.type === 'sourceset') {
            return;
          }

          var techSrc = _this7.techGet('currentSrc');

          _this7.lastSource_.tech = techSrc;

          _this7.updateSourceCaches_(techSrc);
        });
      }
    }

    this.lastSource_ = {
      player: this.currentSource().src,
      tech: event.src
    };
    this.trigger({
      src: event.src,
      type: 'sourceset'
    });
  }
  /**
   * Add/remove the vjs-has-started class
   *
   * @fires Player#firstplay
   *
   * @param {boolean} request
   *        - true: adds the class
   *        - false: remove the class
   *
   * @return {boolean}
   *         the boolean value of hasStarted_
   */
  ;

  _proto.hasStarted = function hasStarted(request) {
    if (request === undefined) {
      // act as getter, if we have no request to change
      return this.hasStarted_;
    }

    if (request === this.hasStarted_) {
      return;
    }

    this.hasStarted_ = request;

    if (this.hasStarted_) {
      this.addClass('vjs-has-started');
      this.trigger('firstplay');
    } else {
      this.removeClass('vjs-has-started');
    }
  }
  /**
   * Fired whenever the media begins or resumes playback
   *
   * @see [Spec]{@link https://html.spec.whatwg.org/multipage/embedded-content.html#dom-media-play}
   * @fires Player#play
   * @listens Tech#play
   * @private
   */
  ;

  _proto.handleTechPlay_ = function handleTechPlay_() {
    this.removeClass('vjs-ended');
    this.removeClass('vjs-paused');
    this.addClass('vjs-playing'); // hide the poster when the user hits play

    this.hasStarted(true);
    /**
     * Triggered whenever an {@link Tech#play} event happens. Indicates that
     * playback has started or resumed.
     *
     * @event Player#play
     * @type {EventTarget~Event}
     */

    this.trigger('play');
  }
  /**
   * Retrigger the `ratechange` event that was triggered by the {@link Tech}.
   *
   * If there were any events queued while the playback rate was zero, fire
   * those events now.
   *
   * @private
   * @method Player#handleTechRateChange_
   * @fires Player#ratechange
   * @listens Tech#ratechange
   */
  ;

  _proto.handleTechRateChange_ = function handleTechRateChange_() {
    if (this.tech_.playbackRate() > 0 && this.cache_.lastPlaybackRate === 0) {
      this.queuedCallbacks_.forEach(function (queued) {
        return queued.callback(queued.event);
      });
      this.queuedCallbacks_ = [];
    }

    this.cache_.lastPlaybackRate = this.tech_.playbackRate();
    /**
     * Fires when the playing speed of the audio/video is changed
     *
     * @event Player#ratechange
     * @type {event}
     */

    this.trigger('ratechange');
  }
  /**
   * Retrigger the `waiting` event that was triggered by the {@link Tech}.
   *
   * @fires Player#waiting
   * @listens Tech#waiting
   * @private
   */
  ;

  _proto.handleTechWaiting_ = function handleTechWaiting_() {
    var _this8 = this;

    this.addClass('vjs-waiting');
    /**
     * A readyState change on the DOM element has caused playback to stop.
     *
     * @event Player#waiting
     * @type {EventTarget~Event}
     */

    this.trigger('waiting'); // Browsers may emit a timeupdate event after a waiting event. In order to prevent
    // premature removal of the waiting class, wait for the time to change.

    var timeWhenWaiting = this.currentTime();

    var timeUpdateListener = function timeUpdateListener() {
      if (timeWhenWaiting !== _this8.currentTime()) {
        _this8.removeClass('vjs-waiting');

        _this8.off('timeupdate', timeUpdateListener);
      }
    };

    this.on('timeupdate', timeUpdateListener);
  }
  /**
   * Retrigger the `canplay` event that was triggered by the {@link Tech}.
   * > Note: This is not consistent between browsers. See #1351
   *
   * @fires Player#canplay
   * @listens Tech#canplay
   * @private
   */
  ;

  _proto.handleTechCanPlay_ = function handleTechCanPlay_() {
    this.removeClass('vjs-waiting');
    /**
     * The media has a readyState of HAVE_FUTURE_DATA or greater.
     *
     * @event Player#canplay
     * @type {EventTarget~Event}
     */

    this.trigger('canplay');
  }
  /**
   * Retrigger the `canplaythrough` event that was triggered by the {@link Tech}.
   *
   * @fires Player#canplaythrough
   * @listens Tech#canplaythrough
   * @private
   */
  ;

  _proto.handleTechCanPlayThrough_ = function handleTechCanPlayThrough_() {
    this.removeClass('vjs-waiting');
    /**
     * The media has a readyState of HAVE_ENOUGH_DATA or greater. This means that the
     * entire media file can be played without buffering.
     *
     * @event Player#canplaythrough
     * @type {EventTarget~Event}
     */

    this.trigger('canplaythrough');
  }
  /**
   * Retrigger the `playing` event that was triggered by the {@link Tech}.
   *
   * @fires Player#playing
   * @listens Tech#playing
   * @private
   */
  ;

  _proto.handleTechPlaying_ = function handleTechPlaying_() {
    this.removeClass('vjs-waiting');
    /**
     * The media is no longer blocked from playback, and has started playing.
     *
     * @event Player#playing
     * @type {EventTarget~Event}
     */

    this.trigger('playing');
  }
  /**
   * Retrigger the `seeking` event that was triggered by the {@link Tech}.
   *
   * @fires Player#seeking
   * @listens Tech#seeking
   * @private
   */
  ;

  _proto.handleTechSeeking_ = function handleTechSeeking_() {
    this.addClass('vjs-seeking');
    /**
     * Fired whenever the player is jumping to a new time
     *
     * @event Player#seeking
     * @type {EventTarget~Event}
     */

    this.trigger('seeking');
  }
  /**
   * Retrigger the `seeked` event that was triggered by the {@link Tech}.
   *
   * @fires Player#seeked
   * @listens Tech#seeked
   * @private
   */
  ;

  _proto.handleTechSeeked_ = function handleTechSeeked_() {
    this.removeClass('vjs-seeking');
    this.removeClass('vjs-ended');
    /**
     * Fired when the player has finished jumping to a new time
     *
     * @event Player#seeked
     * @type {EventTarget~Event}
     */

    this.trigger('seeked');
  }
  /**
   * Retrigger the `firstplay` event that was triggered by the {@link Tech}.
   *
   * @fires Player#firstplay
   * @listens Tech#firstplay
   * @deprecated As of 6.0 firstplay event is deprecated.
   *             As of 6.0 passing the `starttime` option to the player and the firstplay event are deprecated.
   * @private
   */
  ;

  _proto.handleTechFirstPlay_ = function handleTechFirstPlay_() {
    // If the first starttime attribute is specified
    // then we will start at the given offset in seconds
    if (this.options_.starttime) {
      log.warn('Passing the `starttime` option to the player will be deprecated in 6.0');
      this.currentTime(this.options_.starttime);
    }

    this.addClass('vjs-has-started');
    /**
     * Fired the first time a video is played. Not part of the HLS spec, and this is
     * probably not the best implementation yet, so use sparingly. If you don't have a
     * reason to prevent playback, use `myPlayer.one('play');` instead.
     *
     * @event Player#firstplay
     * @deprecated As of 6.0 firstplay event is deprecated.
     * @type {EventTarget~Event}
     */

    this.trigger('firstplay');
  }
  /**
   * Retrigger the `pause` event that was triggered by the {@link Tech}.
   *
   * @fires Player#pause
   * @listens Tech#pause
   * @private
   */
  ;

  _proto.handleTechPause_ = function handleTechPause_() {
    this.removeClass('vjs-playing');
    this.addClass('vjs-paused');
    /**
     * Fired whenever the media has been paused
     *
     * @event Player#pause
     * @type {EventTarget~Event}
     */

    this.trigger('pause');
  }
  /**
   * Retrigger the `ended` event that was triggered by the {@link Tech}.
   *
   * @fires Player#ended
   * @listens Tech#ended
   * @private
   */
  ;

  _proto.handleTechEnded_ = function handleTechEnded_() {
    this.addClass('vjs-ended');
    this.removeClass('vjs-waiting');

    if (this.options_.loop) {
      this.currentTime(0);
      this.play();
    } else if (!this.paused()) {
      this.pause();
    }
    /**
     * Fired when the end of the media resource is reached (currentTime == duration)
     *
     * @event Player#ended
     * @type {EventTarget~Event}
     */


    this.trigger('ended');
  }
  /**
   * Fired when the duration of the media resource is first known or changed
   *
   * @listens Tech#durationchange
   * @private
   */
  ;

  _proto.handleTechDurationChange_ = function handleTechDurationChange_() {
    this.duration(this.techGet_('duration'));
  }
  /**
   * Handle a click on the media element to play/pause
   *
   * @param {EventTarget~Event} event
   *        the event that caused this function to trigger
   *
   * @listens Tech#click
   * @private
   */
  ;

  _proto.handleTechClick_ = function handleTechClick_(event) {
    // When controls are disabled a click should not toggle playback because
    // the click is considered a control
    if (!this.controls_) {
      return;
    }

    if (this.options_ === undefined || this.options_.userActions === undefined || this.options_.userActions.click === undefined || this.options_.userActions.click !== false) {
      if (this.options_ !== undefined && this.options_.userActions !== undefined && typeof this.options_.userActions.click === 'function') {
        this.options_.userActions.click.call(this, event);
      } else if (this.paused()) {
        silencePromise(this.play());
      } else {
        this.pause();
      }
    }
  }
  /**
   * Handle a double-click on the media element to enter/exit fullscreen
   *
   * @param {EventTarget~Event} event
   *        the event that caused this function to trigger
   *
   * @listens Tech#dblclick
   * @private
   */
  ;

  _proto.handleTechDoubleClick_ = function handleTechDoubleClick_(event) {
    if (!this.controls_) {
      return;
    } // we do not want to toggle fullscreen state
    // when double-clicking inside a control bar or a modal


    var inAllowedEls = Array.prototype.some.call(this.$$('.vjs-control-bar, .vjs-modal-dialog'), function (el) {
      return el.contains(event.target);
    });

    if (!inAllowedEls) {
      /*
       * options.userActions.doubleClick
       *
       * If `undefined` or `true`, double-click toggles fullscreen if controls are present
       * Set to `false` to disable double-click handling
       * Set to a function to substitute an external double-click handler
       */
      if (this.options_ === undefined || this.options_.userActions === undefined || this.options_.userActions.doubleClick === undefined || this.options_.userActions.doubleClick !== false) {
        if (this.options_ !== undefined && this.options_.userActions !== undefined && typeof this.options_.userActions.doubleClick === 'function') {
          this.options_.userActions.doubleClick.call(this, event);
        } else if (this.isFullscreen()) {
          this.exitFullscreen();
        } else {
          this.requestFullscreen();
        }
      }
    }
  }
  /**
   * Handle a tap on the media element. It will toggle the user
   * activity state, which hides and shows the controls.
   *
   * @listens Tech#tap
   * @private
   */
  ;

  _proto.handleTechTap_ = function handleTechTap_() {
    this.userActive(!this.userActive());
  }
  /**
   * Handle touch to start
   *
   * @listens Tech#touchstart
   * @private
   */
  ;

  _proto.handleTechTouchStart_ = function handleTechTouchStart_() {
    this.userWasActive = this.userActive();
  }
  /**
   * Handle touch to move
   *
   * @listens Tech#touchmove
   * @private
   */
  ;

  _proto.handleTechTouchMove_ = function handleTechTouchMove_() {
    if (this.userWasActive) {
      this.reportUserActivity();
    }
  }
  /**
   * Handle touch to end
   *
   * @param {EventTarget~Event} event
   *        the touchend event that triggered
   *        this function
   *
   * @listens Tech#touchend
   * @private
   */
  ;

  _proto.handleTechTouchEnd_ = function handleTechTouchEnd_(event) {
    // Stop the mouse events from also happening
    if (event.cancelable) {
      event.preventDefault();
    }
  }
  /**
   * native click events on the SWF aren't triggered on IE11, Win8.1RT
   * use stageclick events triggered from inside the SWF instead
   *
   * @private
   * @listens stageclick
   */
  ;

  _proto.handleStageClick_ = function handleStageClick_() {
    this.reportUserActivity();
  }
  /**
   * @private
   */
  ;

  _proto.toggleFullscreenClass_ = function toggleFullscreenClass_() {
    if (this.isFullscreen()) {
      this.addClass('vjs-fullscreen');
    } else {
      this.removeClass('vjs-fullscreen');
    }
  }
  /**
   * when the document fschange event triggers it calls this
   */
  ;

  _proto.documentFullscreenChange_ = function documentFullscreenChange_(e) {
    var targetPlayer = e.target.player; // if another player was fullscreen
    // do a null check for targetPlayer because older firefox's would put document as e.target

    if (targetPlayer && targetPlayer !== this) {
      return;
    }

    var el = this.el();
    var isFs = document__default['default'][this.fsApi_.fullscreenElement] === el;

    if (!isFs && el.matches) {
      isFs = el.matches(':' + this.fsApi_.fullscreen);
    } else if (!isFs && el.msMatchesSelector) {
      isFs = el.msMatchesSelector(':' + this.fsApi_.fullscreen);
    }

    this.isFullscreen(isFs);
  }
  /**
   * Handle Tech Fullscreen Change
   *
   * @param {EventTarget~Event} event
   *        the fullscreenchange event that triggered this function
   *
   * @param {Object} data
   *        the data that was sent with the event
   *
   * @private
   * @listens Tech#fullscreenchange
   * @fires Player#fullscreenchange
   */
  ;

  _proto.handleTechFullscreenChange_ = function handleTechFullscreenChange_(event, data) {
    var _this9 = this;

    if (data) {
      if (data.nativeIOSFullscreen) {
        this.addClass('vjs-ios-native-fs');
        this.tech_.one('webkitendfullscreen', function () {
          _this9.removeClass('vjs-ios-native-fs');
        });
      }

      this.isFullscreen(data.isFullscreen);
    }
  };

  _proto.handleTechFullscreenError_ = function handleTechFullscreenError_(event, err) {
    this.trigger('fullscreenerror', err);
  }
  /**
   * @private
   */
  ;

  _proto.togglePictureInPictureClass_ = function togglePictureInPictureClass_() {
    if (this.isInPictureInPicture()) {
      this.addClass('vjs-picture-in-picture');
    } else {
      this.removeClass('vjs-picture-in-picture');
    }
  }
  /**
   * Handle Tech Enter Picture-in-Picture.
   *
   * @param {EventTarget~Event} event
   *        the enterpictureinpicture event that triggered this function
   *
   * @private
   * @listens Tech#enterpictureinpicture
   */
  ;

  _proto.handleTechEnterPictureInPicture_ = function handleTechEnterPictureInPicture_(event) {
    this.isInPictureInPicture(true);
  }
  /**
   * Handle Tech Leave Picture-in-Picture.
   *
   * @param {EventTarget~Event} event
   *        the leavepictureinpicture event that triggered this function
   *
   * @private
   * @listens Tech#leavepictureinpicture
   */
  ;

  _proto.handleTechLeavePictureInPicture_ = function handleTechLeavePictureInPicture_(event) {
    this.isInPictureInPicture(false);
  }
  /**
   * Fires when an error occurred during the loading of an audio/video.
   *
   * @private
   * @listens Tech#error
   */
  ;

  _proto.handleTechError_ = function handleTechError_() {
    var error = this.tech_.error();
    this.error(error);
  }
  /**
   * Retrigger the `textdata` event that was triggered by the {@link Tech}.
   *
   * @fires Player#textdata
   * @listens Tech#textdata
   * @private
   */
  ;

  _proto.handleTechTextData_ = function handleTechTextData_() {
    var data = null;

    if (arguments.length > 1) {
      data = arguments[1];
    }
    /**
     * Fires when we get a textdata event from tech
     *
     * @event Player#textdata
     * @type {EventTarget~Event}
     */


    this.trigger('textdata', data);
  }
  /**
   * Get object for cached values.
   *
   * @return {Object}
   *         get the current object cache
   */
  ;

  _proto.getCache = function getCache() {
    return this.cache_;
  }
  /**
   * Resets the internal cache object.
   *
   * Using this function outside the player constructor or reset method may
   * have unintended side-effects.
   *
   * @private
   */
  ;

  _proto.resetCache_ = function resetCache_() {
    this.cache_ = {
      // Right now, the currentTime is not _really_ cached because it is always
      // retrieved from the tech (see: currentTime). However, for completeness,
      // we set it to zero here to ensure that if we do start actually caching
      // it, we reset it along with everything else.
      currentTime: 0,
      initTime: 0,
      inactivityTimeout: this.options_.inactivityTimeout,
      duration: NaN,
      lastVolume: 1,
      lastPlaybackRate: this.defaultPlaybackRate(),
      media: null,
      src: '',
      source: {},
      sources: [],
      playbackRates: [],
      volume: 1
    };
  }
  /**
   * Pass values to the playback tech
   *
   * @param {string} [method]
   *        the method to call
   *
   * @param {Object} arg
   *        the argument to pass
   *
   * @private
   */
  ;

  _proto.techCall_ = function techCall_(method, arg) {
    // If it's not ready yet, call method when it is
    this.ready(function () {
      if (method in allowedSetters) {
        return set(this.middleware_, this.tech_, method, arg);
      } else if (method in allowedMediators) {
        return mediate(this.middleware_, this.tech_, method, arg);
      }

      try {
        if (this.tech_) {
          this.tech_[method](arg);
        }
      } catch (e) {
        log(e);
        throw e;
      }
    }, true);
  }
  /**
   * Get calls can't wait for the tech, and sometimes don't need to.
   *
   * @param {string} method
   *        Tech method
   *
   * @return {Function|undefined}
   *         the method or undefined
   *
   * @private
   */
  ;

  _proto.techGet_ = function techGet_(method) {
    if (!this.tech_ || !this.tech_.isReady_) {
      return;
    }

    if (method in allowedGetters) {
      return get(this.middleware_, this.tech_, method);
    } else if (method in allowedMediators) {
      return mediate(this.middleware_, this.tech_, method);
    } // Flash likes to die and reload when you hide or reposition it.
    // In these cases the object methods go away and we get errors.
    // TODO: Is this needed for techs other than Flash?
    // When that happens we'll catch the errors and inform tech that it's not ready any more.


    try {
      return this.tech_[method]();
    } catch (e) {
      // When building additional tech libs, an expected method may not be defined yet
      if (this.tech_[method] === undefined) {
        log("Video.js: " + method + " method not defined for " + this.techName_ + " playback technology.", e);
        throw e;
      } // When a method isn't available on the object it throws a TypeError


      if (e.name === 'TypeError') {
        log("Video.js: " + method + " unavailable on " + this.techName_ + " playback technology element.", e);
        this.tech_.isReady_ = false;
        throw e;
      } // If error unknown, just log and throw


      log(e);
      throw e;
    }
  }
  /**
   * Attempt to begin playback at the first opportunity.
   *
   * @return {Promise|undefined}
   *         Returns a promise if the browser supports Promises (or one
   *         was passed in as an option). This promise will be resolved on
   *         the return value of play. If this is undefined it will fulfill the
   *         promise chain otherwise the promise chain will be fulfilled when
   *         the promise from play is fulfilled.
   */
  ;

  _proto.play = function play() {
    var _this10 = this;

    var PromiseClass = this.options_.Promise || window__default['default'].Promise;

    if (PromiseClass) {
      return new PromiseClass(function (resolve) {
        _this10.play_(resolve);
      });
    }

    return this.play_();
  }
  /**
   * The actual logic for play, takes a callback that will be resolved on the
   * return value of play. This allows us to resolve to the play promise if there
   * is one on modern browsers.
   *
   * @private
   * @param {Function} [callback]
   *        The callback that should be called when the techs play is actually called
   */
  ;

  _proto.play_ = function play_(callback) {
    var _this11 = this;

    if (callback === void 0) {
      callback = silencePromise;
    }

    this.playCallbacks_.push(callback);
    var isSrcReady = Boolean(!this.changingSrc_ && (this.src() || this.currentSrc())); // treat calls to play_ somewhat like the `one` event function

    if (this.waitToPlay_) {
      this.off(['ready', 'loadstart'], this.waitToPlay_);
      this.waitToPlay_ = null;
    } // if the player/tech is not ready or the src itself is not ready
    // queue up a call to play on `ready` or `loadstart`


    if (!this.isReady_ || !isSrcReady) {
      this.waitToPlay_ = function (e) {
        _this11.play_();
      };

      this.one(['ready', 'loadstart'], this.waitToPlay_); // if we are in Safari, there is a high chance that loadstart will trigger after the gesture timeperiod
      // in that case, we need to prime the video element by calling load so it'll be ready in time

      if (!isSrcReady && (IS_ANY_SAFARI || IS_IOS)) {
        this.load();
      }

      return;
    } // If the player/tech is ready and we have a source, we can attempt playback.


    var val = this.techGet_('play'); // play was terminated if the returned value is null

    if (val === null) {
      this.runPlayTerminatedQueue_();
    } else {
      this.runPlayCallbacks_(val);
    }
  }
  /**
   * These functions will be run when if play is terminated. If play
   * runPlayCallbacks_ is run these function will not be run. This allows us
   * to differenciate between a terminated play and an actual call to play.
   */
  ;

  _proto.runPlayTerminatedQueue_ = function runPlayTerminatedQueue_() {
    var queue = this.playTerminatedQueue_.slice(0);
    this.playTerminatedQueue_ = [];
    queue.forEach(function (q) {
      q();
    });
  }
  /**
   * When a callback to play is delayed we have to run these
   * callbacks when play is actually called on the tech. This function
   * runs the callbacks that were delayed and accepts the return value
   * from the tech.
   *
   * @param {undefined|Promise} val
   *        The return value from the tech.
   */
  ;

  _proto.runPlayCallbacks_ = function runPlayCallbacks_(val) {
    var callbacks = this.playCallbacks_.slice(0);
    this.playCallbacks_ = []; // clear play terminatedQueue since we finished a real play

    this.playTerminatedQueue_ = [];
    callbacks.forEach(function (cb) {
      cb(val);
    });
  }
  /**
   * Pause the video playback
   *
   * @return {Player}
   *         A reference to the player object this function was called on
   */
  ;

  _proto.pause = function pause() {
    this.techCall_('pause');
  }
  /**
   * Check if the player is paused or has yet to play
   *
   * @return {boolean}
   *         - false: if the media is currently playing
   *         - true: if media is not currently playing
   */
  ;

  _proto.paused = function paused() {
    // The initial state of paused should be true (in Safari it's actually false)
    return this.techGet_('paused') === false ? false : true;
  }
  /**
   * Get a TimeRange object representing the current ranges of time that the user
   * has played.
   *
   * @return {TimeRange}
   *         A time range object that represents all the increments of time that have
   *         been played.
   */
  ;

  _proto.played = function played() {
    return this.techGet_('played') || createTimeRanges(0, 0);
  }
  /**
   * Returns whether or not the user is "scrubbing". Scrubbing is
   * when the user has clicked the progress bar handle and is
   * dragging it along the progress bar.
   *
   * @param {boolean} [isScrubbing]
   *        whether the user is or is not scrubbing
   *
   * @return {boolean}
   *         The value of scrubbing when getting
   */
  ;

  _proto.scrubbing = function scrubbing(isScrubbing) {
    if (typeof isScrubbing === 'undefined') {
      return this.scrubbing_;
    }

    this.scrubbing_ = !!isScrubbing;
    this.techCall_('setScrubbing', this.scrubbing_);

    if (isScrubbing) {
      this.addClass('vjs-scrubbing');
    } else {
      this.removeClass('vjs-scrubbing');
    }
  }
  /**
   * Get or set the current time (in seconds)
   *
   * @param {number|string} [seconds]
   *        The time to seek to in seconds
   *
   * @return {number}
   *         - the current time in seconds when getting
   */
  ;

  _proto.currentTime = function currentTime(seconds) {
    if (typeof seconds !== 'undefined') {
      if (seconds < 0) {
        seconds = 0;
      }

      if (!this.isReady_ || this.changingSrc_ || !this.tech_ || !this.tech_.isReady_) {
        this.cache_.initTime = seconds;
        this.off('canplay', this.boundApplyInitTime_);
        this.one('canplay', this.boundApplyInitTime_);
        return;
      }

      this.techCall_('setCurrentTime', seconds);
      this.cache_.initTime = 0;
      return;
    } // cache last currentTime and return. default to 0 seconds
    //
    // Caching the currentTime is meant to prevent a massive amount of reads on the tech's
    // currentTime when scrubbing, but may not provide much performance benefit afterall.
    // Should be tested. Also something has to read the actual current time or the cache will
    // never get updated.


    this.cache_.currentTime = this.techGet_('currentTime') || 0;
    return this.cache_.currentTime;
  }
  /**
   * Apply the value of initTime stored in cache as currentTime.
   *
   * @private
   */
  ;

  _proto.applyInitTime_ = function applyInitTime_() {
    this.currentTime(this.cache_.initTime);
  }
  /**
   * Normally gets the length in time of the video in seconds;
   * in all but the rarest use cases an argument will NOT be passed to the method
   *
   * > **NOTE**: The video must have started loading before the duration can be
   * known, and depending on preload behaviour may not be known until the video starts
   * playing.
   *
   * @fires Player#durationchange
   *
   * @param {number} [seconds]
   *        The duration of the video to set in seconds
   *
   * @return {number}
   *         - The duration of the video in seconds when getting
   */
  ;

  _proto.duration = function duration(seconds) {
    if (seconds === undefined) {
      // return NaN if the duration is not known
      return this.cache_.duration !== undefined ? this.cache_.duration : NaN;
    }

    seconds = parseFloat(seconds); // Standardize on Infinity for signaling video is live

    if (seconds < 0) {
      seconds = Infinity;
    }

    if (seconds !== this.cache_.duration) {
      // Cache the last set value for optimized scrubbing (esp. Flash)
      // TODO: Required for techs other than Flash?
      this.cache_.duration = seconds;

      if (seconds === Infinity) {
        this.addClass('vjs-live');
      } else {
        this.removeClass('vjs-live');
      }

      if (!isNaN(seconds)) {
        // Do not fire durationchange unless the duration value is known.
        // @see [Spec]{@link https://www.w3.org/TR/2011/WD-html5-20110113/video.html#media-element-load-algorithm}

        /**
         * @event Player#durationchange
         * @type {EventTarget~Event}
         */
        this.trigger('durationchange');
      }
    }
  }
  /**
   * Calculates how much time is left in the video. Not part
   * of the native video API.
   *
   * @return {number}
   *         The time remaining in seconds
   */
  ;

  _proto.remainingTime = function remainingTime() {
    return this.duration() - this.currentTime();
  }
  /**
   * A remaining time function that is intented to be used when
   * the time is to be displayed directly to the user.
   *
   * @return {number}
   *         The rounded time remaining in seconds
   */
  ;

  _proto.remainingTimeDisplay = function remainingTimeDisplay() {
    return Math.floor(this.duration()) - Math.floor(this.currentTime());
  } //
  // Kind of like an array of portions of the video that have been downloaded.

  /**
   * Get a TimeRange object with an array of the times of the video
   * that have been downloaded. If you just want the percent of the
   * video that's been downloaded, use bufferedPercent.
   *
   * @see [Buffered Spec]{@link http://dev.w3.org/html5/spec/video.html#dom-media-buffered}
   *
   * @return {TimeRange}
   *         A mock TimeRange object (following HTML spec)
   */
  ;

  _proto.buffered = function buffered() {
    var buffered = this.techGet_('buffered');

    if (!buffered || !buffered.length) {
      buffered = createTimeRanges(0, 0);
    }

    return buffered;
  }
  /**
   * Get the percent (as a decimal) of the video that's been downloaded.
   * This method is not a part of the native HTML video API.
   *
   * @return {number}
   *         A decimal between 0 and 1 representing the percent
   *         that is buffered 0 being 0% and 1 being 100%
   */
  ;

  _proto.bufferedPercent = function bufferedPercent$1() {
    return bufferedPercent(this.buffered(), this.duration());
  }
  /**
   * Get the ending time of the last buffered time range
   * This is used in the progress bar to encapsulate all time ranges.
   *
   * @return {number}
   *         The end of the last buffered time range
   */
  ;

  _proto.bufferedEnd = function bufferedEnd() {
    var buffered = this.buffered();
    var duration = this.duration();
    var end = buffered.end(buffered.length - 1);

    if (end > duration) {
      end = duration;
    }

    return end;
  }
  /**
   * Get or set the current volume of the media
   *
   * @param  {number} [percentAsDecimal]
   *         The new volume as a decimal percent:
   *         - 0 is muted/0%/off
   *         - 1.0 is 100%/full
   *         - 0.5 is half volume or 50%
   *
   * @return {number}
   *         The current volume as a percent when getting
   */
  ;

  _proto.volume = function volume(percentAsDecimal) {
    var vol;

    if (percentAsDecimal !== undefined) {
      // Force value to between 0 and 1
      vol = Math.max(0, Math.min(1, parseFloat(percentAsDecimal)));
      this.cache_.volume = vol;
      this.techCall_('setVolume', vol);

      if (vol > 0) {
        this.lastVolume_(vol);
      }

      return;
    } // Default to 1 when returning current volume.


    vol = parseFloat(this.techGet_('volume'));
    return isNaN(vol) ? 1 : vol;
  }
  /**
   * Get the current muted state, or turn mute on or off
   *
   * @param {boolean} [muted]
   *        - true to mute
   *        - false to unmute
   *
   * @return {boolean}
   *         - true if mute is on and getting
   *         - false if mute is off and getting
   */
  ;

  _proto.muted = function muted(_muted) {
    if (_muted !== undefined) {
      this.techCall_('setMuted', _muted);
      return;
    }

    return this.techGet_('muted') || false;
  }
  /**
   * Get the current defaultMuted state, or turn defaultMuted on or off. defaultMuted
   * indicates the state of muted on initial playback.
   *
   * ```js
   *   var myPlayer = videojs('some-player-id');
   *
   *   myPlayer.src("http://www.example.com/path/to/video.mp4");
   *
   *   // get, should be false
   *   console.log(myPlayer.defaultMuted());
   *   // set to true
   *   myPlayer.defaultMuted(true);
   *   // get should be true
   *   console.log(myPlayer.defaultMuted());
   * ```
   *
   * @param {boolean} [defaultMuted]
   *        - true to mute
   *        - false to unmute
   *
   * @return {boolean|Player}
   *         - true if defaultMuted is on and getting
   *         - false if defaultMuted is off and getting
   *         - A reference to the current player when setting
   */
  ;

  _proto.defaultMuted = function defaultMuted(_defaultMuted) {
    if (_defaultMuted !== undefined) {
      return this.techCall_('setDefaultMuted', _defaultMuted);
    }

    return this.techGet_('defaultMuted') || false;
  }
  /**
   * Get the last volume, or set it
   *
   * @param  {number} [percentAsDecimal]
   *         The new last volume as a decimal percent:
   *         - 0 is muted/0%/off
   *         - 1.0 is 100%/full
   *         - 0.5 is half volume or 50%
   *
   * @return {number}
   *         the current value of lastVolume as a percent when getting
   *
   * @private
   */
  ;

  _proto.lastVolume_ = function lastVolume_(percentAsDecimal) {
    if (percentAsDecimal !== undefined && percentAsDecimal !== 0) {
      this.cache_.lastVolume = percentAsDecimal;
      return;
    }

    return this.cache_.lastVolume;
  }
  /**
   * Check if current tech can support native fullscreen
   * (e.g. with built in controls like iOS)
   *
   * @return {boolean}
   *         if native fullscreen is supported
   */
  ;

  _proto.supportsFullScreen = function supportsFullScreen() {
    return this.techGet_('supportsFullScreen') || false;
  }
  /**
   * Check if the player is in fullscreen mode or tell the player that it
   * is or is not in fullscreen mode.
   *
   * > NOTE: As of the latest HTML5 spec, isFullscreen is no longer an official
   * property and instead document.fullscreenElement is used. But isFullscreen is
   * still a valuable property for internal player workings.
   *
   * @param  {boolean} [isFS]
   *         Set the players current fullscreen state
   *
   * @return {boolean}
   *         - true if fullscreen is on and getting
   *         - false if fullscreen is off and getting
   */
  ;

  _proto.isFullscreen = function isFullscreen(isFS) {
    if (isFS !== undefined) {
      var oldValue = this.isFullscreen_;
      this.isFullscreen_ = Boolean(isFS); // if we changed fullscreen state and we're in prefixed mode, trigger fullscreenchange
      // this is the only place where we trigger fullscreenchange events for older browsers
      // fullWindow mode is treated as a prefixed event and will get a fullscreenchange event as well

      if (this.isFullscreen_ !== oldValue && this.fsApi_.prefixed) {
        /**
           * @event Player#fullscreenchange
           * @type {EventTarget~Event}
           */
        this.trigger('fullscreenchange');
      }

      this.toggleFullscreenClass_();
      return;
    }

    return this.isFullscreen_;
  }
  /**
   * Increase the size of the video to full screen
   * In some browsers, full screen is not supported natively, so it enters
   * "full window mode", where the video fills the browser window.
   * In browsers and devices that support native full screen, sometimes the
   * browser's default controls will be shown, and not the Video.js custom skin.
   * This includes most mobile devices (iOS, Android) and older versions of
   * Safari.
   *
   * @param  {Object} [fullscreenOptions]
   *         Override the player fullscreen options
   *
   * @fires Player#fullscreenchange
   */
  ;

  _proto.requestFullscreen = function requestFullscreen(fullscreenOptions) {
    var PromiseClass = this.options_.Promise || window__default['default'].Promise;

    if (PromiseClass) {
      var self = this;
      return new PromiseClass(function (resolve, reject) {
        function offHandler() {
          self.off('fullscreenerror', errorHandler);
          self.off('fullscreenchange', changeHandler);
        }

        function changeHandler() {
          offHandler();
          resolve();
        }

        function errorHandler(e, err) {
          offHandler();
          reject(err);
        }

        self.one('fullscreenchange', changeHandler);
        self.one('fullscreenerror', errorHandler);
        var promise = self.requestFullscreenHelper_(fullscreenOptions);

        if (promise) {
          promise.then(offHandler, offHandler);
          promise.then(resolve, reject);
        }
      });
    }

    return this.requestFullscreenHelper_();
  };

  _proto.requestFullscreenHelper_ = function requestFullscreenHelper_(fullscreenOptions) {
    var _this12 = this;

    var fsOptions; // Only pass fullscreen options to requestFullscreen in spec-compliant browsers.
    // Use defaults or player configured option unless passed directly to this method.

    if (!this.fsApi_.prefixed) {
      fsOptions = this.options_.fullscreen && this.options_.fullscreen.options || {};

      if (fullscreenOptions !== undefined) {
        fsOptions = fullscreenOptions;
      }
    } // This method works as follows:
    // 1. if a fullscreen api is available, use it
    //   1. call requestFullscreen with potential options
    //   2. if we got a promise from above, use it to update isFullscreen()
    // 2. otherwise, if the tech supports fullscreen, call `enterFullScreen` on it.
    //   This is particularly used for iPhone, older iPads, and non-safari browser on iOS.
    // 3. otherwise, use "fullWindow" mode


    if (this.fsApi_.requestFullscreen) {
      var promise = this.el_[this.fsApi_.requestFullscreen](fsOptions);

      if (promise) {
        promise.then(function () {
          return _this12.isFullscreen(true);
        }, function () {
          return _this12.isFullscreen(false);
        });
      }

      return promise;
    } else if (this.tech_.supportsFullScreen() && !this.options_.preferFullWindow === true) {
      // we can't take the video.js controls fullscreen but we can go fullscreen
      // with native controls
      this.techCall_('enterFullScreen');
    } else {
      // fullscreen isn't supported so we'll just stretch the video element to
      // fill the viewport
      this.enterFullWindow();
    }
  }
  /**
   * Return the video to its normal size after having been in full screen mode
   *
   * @fires Player#fullscreenchange
   */
  ;

  _proto.exitFullscreen = function exitFullscreen() {
    var PromiseClass = this.options_.Promise || window__default['default'].Promise;

    if (PromiseClass) {
      var self = this;
      return new PromiseClass(function (resolve, reject) {
        function offHandler() {
          self.off('fullscreenerror', errorHandler);
          self.off('fullscreenchange', changeHandler);
        }

        function changeHandler() {
          offHandler();
          resolve();
        }

        function errorHandler(e, err) {
          offHandler();
          reject(err);
        }

        self.one('fullscreenchange', changeHandler);
        self.one('fullscreenerror', errorHandler);
        var promise = self.exitFullscreenHelper_();

        if (promise) {
          promise.then(offHandler, offHandler); // map the promise to our resolve/reject methods

          promise.then(resolve, reject);
        }
      });
    }

    return this.exitFullscreenHelper_();
  };

  _proto.exitFullscreenHelper_ = function exitFullscreenHelper_() {
    var _this13 = this;

    if (this.fsApi_.requestFullscreen) {
      var promise = document__default['default'][this.fsApi_.exitFullscreen]();

      if (promise) {
        // we're splitting the promise here, so, we want to catch the
        // potential error so that this chain doesn't have unhandled errors
        silencePromise(promise.then(function () {
          return _this13.isFullscreen(false);
        }));
      }

      return promise;
    } else if (this.tech_.supportsFullScreen() && !this.options_.preferFullWindow === true) {
      this.techCall_('exitFullScreen');
    } else {
      this.exitFullWindow();
    }
  }
  /**
   * When fullscreen isn't supported we can stretch the
   * video container to as wide as the browser will let us.
   *
   * @fires Player#enterFullWindow
   */
  ;

  _proto.enterFullWindow = function enterFullWindow() {
    this.isFullscreen(true);
    this.isFullWindow = true; // Storing original doc overflow value to return to when fullscreen is off

    this.docOrigOverflow = document__default['default'].documentElement.style.overflow; // Add listener for esc key to exit fullscreen

    on(document__default['default'], 'keydown', this.boundFullWindowOnEscKey_); // Hide any scroll bars

    document__default['default'].documentElement.style.overflow = 'hidden'; // Apply fullscreen styles

    addClass(document__default['default'].body, 'vjs-full-window');
    /**
     * @event Player#enterFullWindow
     * @type {EventTarget~Event}
     */

    this.trigger('enterFullWindow');
  }
  /**
   * Check for call to either exit full window or
   * full screen on ESC key
   *
   * @param {string} event
   *        Event to check for key press
   */
  ;

  _proto.fullWindowOnEscKey = function fullWindowOnEscKey(event) {
    if (keycode__default['default'].isEventKey(event, 'Esc')) {
      if (this.isFullscreen() === true) {
        if (!this.isFullWindow) {
          this.exitFullscreen();
        } else {
          this.exitFullWindow();
        }
      }
    }
  }
  /**
   * Exit full window
   *
   * @fires Player#exitFullWindow
   */
  ;

  _proto.exitFullWindow = function exitFullWindow() {
    this.isFullscreen(false);
    this.isFullWindow = false;
    off(document__default['default'], 'keydown', this.boundFullWindowOnEscKey_); // Unhide scroll bars.

    document__default['default'].documentElement.style.overflow = this.docOrigOverflow; // Remove fullscreen styles

    removeClass(document__default['default'].body, 'vjs-full-window'); // Resize the box, controller, and poster to original sizes
    // this.positionAll();

    /**
     * @event Player#exitFullWindow
     * @type {EventTarget~Event}
     */

    this.trigger('exitFullWindow');
  }
  /**
   * Disable Picture-in-Picture mode.
   *
   * @param {boolean} value
   *                  - true will disable Picture-in-Picture mode
   *                  - false will enable Picture-in-Picture mode
   */
  ;

  _proto.disablePictureInPicture = function disablePictureInPicture(value) {
    if (value === undefined) {
      return this.techGet_('disablePictureInPicture');
    }

    this.techCall_('setDisablePictureInPicture', value);
    this.options_.disablePictureInPicture = value;
    this.trigger('disablepictureinpicturechanged');
  }
  /**
   * Check if the player is in Picture-in-Picture mode or tell the player that it
   * is or is not in Picture-in-Picture mode.
   *
   * @param  {boolean} [isPiP]
   *         Set the players current Picture-in-Picture state
   *
   * @return {boolean}
   *         - true if Picture-in-Picture is on and getting
   *         - false if Picture-in-Picture is off and getting
   */
  ;

  _proto.isInPictureInPicture = function isInPictureInPicture(isPiP) {
    if (isPiP !== undefined) {
      this.isInPictureInPicture_ = !!isPiP;
      this.togglePictureInPictureClass_();
      return;
    }

    return !!this.isInPictureInPicture_;
  }
  /**
   * Create a floating video window always on top of other windows so that users may
   * continue consuming media while they interact with other content sites, or
   * applications on their device.
   *
   * @see [Spec]{@link https://wicg.github.io/picture-in-picture}
   *
   * @fires Player#enterpictureinpicture
   *
   * @return {Promise}
   *         A promise with a Picture-in-Picture window.
   */
  ;

  _proto.requestPictureInPicture = function requestPictureInPicture() {
    if ('pictureInPictureEnabled' in document__default['default'] && this.disablePictureInPicture() === false) {
      /**
       * This event fires when the player enters picture in picture mode
       *
       * @event Player#enterpictureinpicture
       * @type {EventTarget~Event}
       */
      return this.techGet_('requestPictureInPicture');
    }
  }
  /**
   * Exit Picture-in-Picture mode.
   *
   * @see [Spec]{@link https://wicg.github.io/picture-in-picture}
   *
   * @fires Player#leavepictureinpicture
   *
   * @return {Promise}
   *         A promise.
   */
  ;

  _proto.exitPictureInPicture = function exitPictureInPicture() {
    if ('pictureInPictureEnabled' in document__default['default']) {
      /**
       * This event fires when the player leaves picture in picture mode
       *
       * @event Player#leavepictureinpicture
       * @type {EventTarget~Event}
       */
      return document__default['default'].exitPictureInPicture();
    }
  }
  /**
   * Called when this Player has focus and a key gets pressed down, or when
   * any Component of this player receives a key press that it doesn't handle.
   * This allows player-wide hotkeys (either as defined below, or optionally
   * by an external function).
   *
   * @param {EventTarget~Event} event
   *        The `keydown` event that caused this function to be called.
   *
   * @listens keydown
   */
  ;

  _proto.handleKeyDown = function handleKeyDown(event) {
    var userActions = this.options_.userActions; // Bail out if hotkeys are not configured.

    if (!userActions || !userActions.hotkeys) {
      return;
    } // Function that determines whether or not to exclude an element from
    // hotkeys handling.


    var excludeElement = function excludeElement(el) {
      var tagName = el.tagName.toLowerCase(); // The first and easiest test is for `contenteditable` elements.

      if (el.isContentEditable) {
        return true;
      } // Inputs matching these types will still trigger hotkey handling as
      // they are not text inputs.


      var allowedInputTypes = ['button', 'checkbox', 'hidden', 'radio', 'reset', 'submit'];

      if (tagName === 'input') {
        return allowedInputTypes.indexOf(el.type) === -1;
      } // The final test is by tag name. These tags will be excluded entirely.


      var excludedTags = ['textarea'];
      return excludedTags.indexOf(tagName) !== -1;
    }; // Bail out if the user is focused on an interactive form element.


    if (excludeElement(this.el_.ownerDocument.activeElement)) {
      return;
    }

    if (typeof userActions.hotkeys === 'function') {
      userActions.hotkeys.call(this, event);
    } else {
      this.handleHotkeys(event);
    }
  }
  /**
   * Called when this Player receives a hotkey keydown event.
   * Supported player-wide hotkeys are:
   *
   *   f          - toggle fullscreen
   *   m          - toggle mute
   *   k or Space - toggle play/pause
   *
   * @param {EventTarget~Event} event
   *        The `keydown` event that caused this function to be called.
   */
  ;

  _proto.handleHotkeys = function handleHotkeys(event) {
    var hotkeys = this.options_.userActions ? this.options_.userActions.hotkeys : {}; // set fullscreenKey, muteKey, playPauseKey from `hotkeys`, use defaults if not set

    var _hotkeys$fullscreenKe = hotkeys.fullscreenKey,
        fullscreenKey = _hotkeys$fullscreenKe === void 0 ? function (keydownEvent) {
      return keycode__default['default'].isEventKey(keydownEvent, 'f');
    } : _hotkeys$fullscreenKe,
        _hotkeys$muteKey = hotkeys.muteKey,
        muteKey = _hotkeys$muteKey === void 0 ? function (keydownEvent) {
      return keycode__default['default'].isEventKey(keydownEvent, 'm');
    } : _hotkeys$muteKey,
        _hotkeys$playPauseKey = hotkeys.playPauseKey,
        playPauseKey = _hotkeys$playPauseKey === void 0 ? function (keydownEvent) {
      return keycode__default['default'].isEventKey(keydownEvent, 'k') || keycode__default['default'].isEventKey(keydownEvent, 'Space');
    } : _hotkeys$playPauseKey;

    if (fullscreenKey.call(this, event)) {
      event.preventDefault();
      event.stopPropagation();
      var FSToggle = Component.getComponent('FullscreenToggle');

      if (document__default['default'][this.fsApi_.fullscreenEnabled] !== false) {
        FSToggle.prototype.handleClick.call(this, event);
      }
    } else if (muteKey.call(this, event)) {
      event.preventDefault();
      event.stopPropagation();
      var MuteToggle = Component.getComponent('MuteToggle');
      MuteToggle.prototype.handleClick.call(this, event);
    } else if (playPauseKey.call(this, event)) {
      event.preventDefault();
      event.stopPropagation();
      var PlayToggle = Component.getComponent('PlayToggle');
      PlayToggle.prototype.handleClick.call(this, event);
    }
  }
  /**
   * Check whether the player can play a given mimetype
   *
   * @see https://www.w3.org/TR/2011/WD-html5-20110113/video.html#dom-navigator-canplaytype
   *
   * @param {string} type
   *        The mimetype to check
   *
   * @return {string}
   *         'probably', 'maybe', or '' (empty string)
   */
  ;

  _proto.canPlayType = function canPlayType(type) {
    var can; // Loop through each playback technology in the options order

    for (var i = 0, j = this.options_.techOrder; i < j.length; i++) {
      var techName = j[i];
      var tech = Tech.getTech(techName); // Support old behavior of techs being registered as components.
      // Remove once that deprecated behavior is removed.

      if (!tech) {
        tech = Component.getComponent(techName);
      } // Check if the current tech is defined before continuing


      if (!tech) {
        log.error("The \"" + techName + "\" tech is undefined. Skipped browser support check for that tech.");
        continue;
      } // Check if the browser supports this technology


      if (tech.isSupported()) {
        can = tech.canPlayType(type);

        if (can) {
          return can;
        }
      }
    }

    return '';
  }
  /**
   * Select source based on tech-order or source-order
   * Uses source-order selection if `options.sourceOrder` is truthy. Otherwise,
   * defaults to tech-order selection
   *
   * @param {Array} sources
   *        The sources for a media asset
   *
   * @return {Object|boolean}
   *         Object of source and tech order or false
   */
  ;

  _proto.selectSource = function selectSource(sources) {
    var _this14 = this;

    // Get only the techs specified in `techOrder` that exist and are supported by the
    // current platform
    var techs = this.options_.techOrder.map(function (techName) {
      return [techName, Tech.getTech(techName)];
    }).filter(function (_ref) {
      var techName = _ref[0],
          tech = _ref[1];

      // Check if the current tech is defined before continuing
      if (tech) {
        // Check if the browser supports this technology
        return tech.isSupported();
      }

      log.error("The \"" + techName + "\" tech is undefined. Skipped browser support check for that tech.");
      return false;
    }); // Iterate over each `innerArray` element once per `outerArray` element and execute
    // `tester` with both. If `tester` returns a non-falsy value, exit early and return
    // that value.

    var findFirstPassingTechSourcePair = function findFirstPassingTechSourcePair(outerArray, innerArray, tester) {
      var found;
      outerArray.some(function (outerChoice) {
        return innerArray.some(function (innerChoice) {
          found = tester(outerChoice, innerChoice);

          if (found) {
            return true;
          }
        });
      });
      return found;
    };

    var foundSourceAndTech;

    var flip = function flip(fn) {
      return function (a, b) {
        return fn(b, a);
      };
    };

    var finder = function finder(_ref2, source) {
      var techName = _ref2[0],
          tech = _ref2[1];

      if (tech.canPlaySource(source, _this14.options_[techName.toLowerCase()])) {
        return {
          source: source,
          tech: techName
        };
      }
    }; // Depending on the truthiness of `options.sourceOrder`, we swap the order of techs and sources
    // to select from them based on their priority.


    if (this.options_.sourceOrder) {
      // Source-first ordering
      foundSourceAndTech = findFirstPassingTechSourcePair(sources, techs, flip(finder));
    } else {
      // Tech-first ordering
      foundSourceAndTech = findFirstPassingTechSourcePair(techs, sources, finder);
    }

    return foundSourceAndTech || false;
  }
  /**
   * Executes source setting and getting logic
   *
   * @param {Tech~SourceObject|Tech~SourceObject[]|string} [source]
   *        A SourceObject, an array of SourceObjects, or a string referencing
   *        a URL to a media source. It is _highly recommended_ that an object
   *        or array of objects is used here, so that source selection
   *        algorithms can take the `type` into account.
   *
   *        If not provided, this method acts as a getter.
   * @param {boolean} isRetry
   *        Indicates whether this is being called internally as a result of a retry
   *
   * @return {string|undefined}
   *         If the `source` argument is missing, returns the current source
   *         URL. Otherwise, returns nothing/undefined.
   */
  ;

  _proto.handleSrc_ = function handleSrc_(source, isRetry) {
    var _this15 = this;

    // getter usage
    if (typeof source === 'undefined') {
      return this.cache_.src || '';
    } // Reset retry behavior for new source


    if (this.resetRetryOnError_) {
      this.resetRetryOnError_();
    } // filter out invalid sources and turn our source into
    // an array of source objects


    var sources = filterSource(source); // if a source was passed in then it is invalid because
    // it was filtered to a zero length Array. So we have to
    // show an error

    if (!sources.length) {
      this.setTimeout(function () {
        this.error({
          code: 4,
          message: this.localize(this.options_.notSupportedMessage)
        });
      }, 0);
      return;
    } // initial sources


    this.changingSrc_ = true; // Only update the cached source list if we are not retrying a new source after error,
    // since in that case we want to include the failed source(s) in the cache

    if (!isRetry) {
      this.cache_.sources = sources;
    }

    this.updateSourceCaches_(sources[0]); // middlewareSource is the source after it has been changed by middleware

    setSource(this, sources[0], function (middlewareSource, mws) {
      _this15.middleware_ = mws; // since sourceSet is async we have to update the cache again after we select a source since
      // the source that is selected could be out of order from the cache update above this callback.

      if (!isRetry) {
        _this15.cache_.sources = sources;
      }

      _this15.updateSourceCaches_(middlewareSource);

      var err = _this15.src_(middlewareSource);

      if (err) {
        if (sources.length > 1) {
          return _this15.handleSrc_(sources.slice(1));
        }

        _this15.changingSrc_ = false; // We need to wrap this in a timeout to give folks a chance to add error event handlers

        _this15.setTimeout(function () {
          this.error({
            code: 4,
            message: this.localize(this.options_.notSupportedMessage)
          });
        }, 0); // we could not find an appropriate tech, but let's still notify the delegate that this is it
        // this needs a better comment about why this is needed


        _this15.triggerReady();

        return;
      }

      setTech(mws, _this15.tech_);
    }); // Try another available source if this one fails before playback.

    if (this.options_.retryOnError && sources.length > 1) {
      var retry = function retry() {
        // Remove the error modal
        _this15.error(null);

        _this15.handleSrc_(sources.slice(1), true);
      };

      var stopListeningForErrors = function stopListeningForErrors() {
        _this15.off('error', retry);
      };

      this.one('error', retry);
      this.one('playing', stopListeningForErrors);

      this.resetRetryOnError_ = function () {
        _this15.off('error', retry);

        _this15.off('playing', stopListeningForErrors);
      };
    }
  }
  /**
   * Get or set the video source.
   *
   * @param {Tech~SourceObject|Tech~SourceObject[]|string} [source]
   *        A SourceObject, an array of SourceObjects, or a string referencing
   *        a URL to a media source. It is _highly recommended_ that an object
   *        or array of objects is used here, so that source selection
   *        algorithms can take the `type` into account.
   *
   *        If not provided, this method acts as a getter.
   *
   * @return {string|undefined}
   *         If the `source` argument is missing, returns the current source
   *         URL. Otherwise, returns nothing/undefined.
   */
  ;

  _proto.src = function src(source) {
    return this.handleSrc_(source, false);
  }
  /**
   * Set the source object on the tech, returns a boolean that indicates whether
   * there is a tech that can play the source or not
   *
   * @param {Tech~SourceObject} source
   *        The source object to set on the Tech
   *
   * @return {boolean}
   *         - True if there is no Tech to playback this source
   *         - False otherwise
   *
   * @private
   */
  ;

  _proto.src_ = function src_(source) {
    var _this16 = this;

    var sourceTech = this.selectSource([source]);

    if (!sourceTech) {
      return true;
    }

    if (!titleCaseEquals(sourceTech.tech, this.techName_)) {
      this.changingSrc_ = true; // load this technology with the chosen source

      this.loadTech_(sourceTech.tech, sourceTech.source);
      this.tech_.ready(function () {
        _this16.changingSrc_ = false;
      });
      return false;
    } // wait until the tech is ready to set the source
    // and set it synchronously if possible (#2326)


    this.ready(function () {
      // The setSource tech method was added with source handlers
      // so older techs won't support it
      // We need to check the direct prototype for the case where subclasses
      // of the tech do not support source handlers
      if (this.tech_.constructor.prototype.hasOwnProperty('setSource')) {
        this.techCall_('setSource', source);
      } else {
        this.techCall_('src', source.src);
      }

      this.changingSrc_ = false;
    }, true);
    return false;
  }
  /**
   * Begin loading the src data.
   */
  ;

  _proto.load = function load() {
    this.techCall_('load');
  }
  /**
   * Reset the player. Loads the first tech in the techOrder,
   * removes all the text tracks in the existing `tech`,
   * and calls `reset` on the `tech`.
   */
  ;

  _proto.reset = function reset() {
    var _this17 = this;

    var PromiseClass = this.options_.Promise || window__default['default'].Promise;

    if (this.paused() || !PromiseClass) {
      this.doReset_();
    } else {
      var playPromise = this.play();
      silencePromise(playPromise.then(function () {
        return _this17.doReset_();
      }));
    }
  };

  _proto.doReset_ = function doReset_() {
    if (this.tech_) {
      this.tech_.clearTracks('text');
    }

    this.resetCache_();
    this.poster('');
    this.loadTech_(this.options_.techOrder[0], null);
    this.techCall_('reset');
    this.resetControlBarUI_();

    if (isEvented(this)) {
      this.trigger('playerreset');
    }
  }
  /**
   * Reset Control Bar's UI by calling sub-methods that reset
   * all of Control Bar's components
   */
  ;

  _proto.resetControlBarUI_ = function resetControlBarUI_() {
    this.resetProgressBar_();
    this.resetPlaybackRate_();
    this.resetVolumeBar_();
  }
  /**
   * Reset tech's progress so progress bar is reset in the UI
   */
  ;

  _proto.resetProgressBar_ = function resetProgressBar_() {
    this.currentTime(0);
    var _this$controlBar = this.controlBar,
        durationDisplay = _this$controlBar.durationDisplay,
        remainingTimeDisplay = _this$controlBar.remainingTimeDisplay;

    if (durationDisplay) {
      durationDisplay.updateContent();
    }

    if (remainingTimeDisplay) {
      remainingTimeDisplay.updateContent();
    }
  }
  /**
   * Reset Playback ratio
   */
  ;

  _proto.resetPlaybackRate_ = function resetPlaybackRate_() {
    this.playbackRate(this.defaultPlaybackRate());
    this.handleTechRateChange_();
  }
  /**
   * Reset Volume bar
   */
  ;

  _proto.resetVolumeBar_ = function resetVolumeBar_() {
    this.volume(1.0);
    this.trigger('volumechange');
  }
  /**
   * Returns all of the current source objects.
   *
   * @return {Tech~SourceObject[]}
   *         The current source objects
   */
  ;

  _proto.currentSources = function currentSources() {
    var source = this.currentSource();
    var sources = []; // assume `{}` or `{ src }`

    if (Object.keys(source).length !== 0) {
      sources.push(source);
    }

    return this.cache_.sources || sources;
  }
  /**
   * Returns the current source object.
   *
   * @return {Tech~SourceObject}
   *         The current source object
   */
  ;

  _proto.currentSource = function currentSource() {
    return this.cache_.source || {};
  }
  /**
   * Returns the fully qualified URL of the current source value e.g. http://mysite.com/video.mp4
   * Can be used in conjunction with `currentType` to assist in rebuilding the current source object.
   *
   * @return {string}
   *         The current source
   */
  ;

  _proto.currentSrc = function currentSrc() {
    return this.currentSource() && this.currentSource().src || '';
  }
  /**
   * Get the current source type e.g. video/mp4
   * This can allow you rebuild the current source object so that you could load the same
   * source and tech later
   *
   * @return {string}
   *         The source MIME type
   */
  ;

  _proto.currentType = function currentType() {
    return this.currentSource() && this.currentSource().type || '';
  }
  /**
   * Get or set the preload attribute
   *
   * @param {boolean} [value]
   *        - true means that we should preload
   *        - false means that we should not preload
   *
   * @return {string}
   *         The preload attribute value when getting
   */
  ;

  _proto.preload = function preload(value) {
    if (value !== undefined) {
      this.techCall_('setPreload', value);
      this.options_.preload = value;
      return;
    }

    return this.techGet_('preload');
  }
  /**
   * Get or set the autoplay option. When this is a boolean it will
   * modify the attribute on the tech. When this is a string the attribute on
   * the tech will be removed and `Player` will handle autoplay on loadstarts.
   *
   * @param {boolean|string} [value]
   *        - true: autoplay using the browser behavior
   *        - false: do not autoplay
   *        - 'play': call play() on every loadstart
   *        - 'muted': call muted() then play() on every loadstart
   *        - 'any': call play() on every loadstart. if that fails call muted() then play().
   *        - *: values other than those listed here will be set `autoplay` to true
   *
   * @return {boolean|string}
   *         The current value of autoplay when getting
   */
  ;

  _proto.autoplay = function autoplay(value) {
    // getter usage
    if (value === undefined) {
      return this.options_.autoplay || false;
    }

    var techAutoplay; // if the value is a valid string set it to that, or normalize `true` to 'play', if need be

    if (typeof value === 'string' && /(any|play|muted)/.test(value) || value === true && this.options_.normalizeAutoplay) {
      this.options_.autoplay = value;
      this.manualAutoplay_(typeof value === 'string' ? value : 'play');
      techAutoplay = false; // any falsy value sets autoplay to false in the browser,
      // lets do the same
    } else if (!value) {
      this.options_.autoplay = false; // any other value (ie truthy) sets autoplay to true
    } else {
      this.options_.autoplay = true;
    }

    techAutoplay = typeof techAutoplay === 'undefined' ? this.options_.autoplay : techAutoplay; // if we don't have a tech then we do not queue up
    // a setAutoplay call on tech ready. We do this because the
    // autoplay option will be passed in the constructor and we
    // do not need to set it twice

    if (this.tech_) {
      this.techCall_('setAutoplay', techAutoplay);
    }
  }
  /**
   * Set or unset the playsinline attribute.
   * Playsinline tells the browser that non-fullscreen playback is preferred.
   *
   * @param {boolean} [value]
   *        - true means that we should try to play inline by default
   *        - false means that we should use the browser's default playback mode,
   *          which in most cases is inline. iOS Safari is a notable exception
   *          and plays fullscreen by default.
   *
   * @return {string|Player}
   *         - the current value of playsinline
   *         - the player when setting
   *
   * @see [Spec]{@link https://html.spec.whatwg.org/#attr-video-playsinline}
   */
  ;

  _proto.playsinline = function playsinline(value) {
    if (value !== undefined) {
      this.techCall_('setPlaysinline', value);
      this.options_.playsinline = value;
      return this;
    }

    return this.techGet_('playsinline');
  }
  /**
   * Get or set the loop attribute on the video element.
   *
   * @param {boolean} [value]
   *        - true means that we should loop the video
   *        - false means that we should not loop the video
   *
   * @return {boolean}
   *         The current value of loop when getting
   */
  ;

  _proto.loop = function loop(value) {
    if (value !== undefined) {
      this.techCall_('setLoop', value);
      this.options_.loop = value;
      return;
    }

    return this.techGet_('loop');
  }
  /**
   * Get or set the poster image source url
   *
   * @fires Player#posterchange
   *
   * @param {string} [src]
   *        Poster image source URL
   *
   * @return {string}
   *         The current value of poster when getting
   */
  ;

  _proto.poster = function poster(src) {
    if (src === undefined) {
      return this.poster_;
    } // The correct way to remove a poster is to set as an empty string
    // other falsey values will throw errors


    if (!src) {
      src = '';
    }

    if (src === this.poster_) {
      return;
    } // update the internal poster variable


    this.poster_ = src; // update the tech's poster

    this.techCall_('setPoster', src);
    this.isPosterFromTech_ = false; // alert components that the poster has been set

    /**
     * This event fires when the poster image is changed on the player.
     *
     * @event Player#posterchange
     * @type {EventTarget~Event}
     */

    this.trigger('posterchange');
  }
  /**
   * Some techs (e.g. YouTube) can provide a poster source in an
   * asynchronous way. We want the poster component to use this
   * poster source so that it covers up the tech's controls.
   * (YouTube's play button). However we only want to use this
   * source if the player user hasn't set a poster through
   * the normal APIs.
   *
   * @fires Player#posterchange
   * @listens Tech#posterchange
   * @private
   */
  ;

  _proto.handleTechPosterChange_ = function handleTechPosterChange_() {
    if ((!this.poster_ || this.options_.techCanOverridePoster) && this.tech_ && this.tech_.poster) {
      var newPoster = this.tech_.poster() || '';

      if (newPoster !== this.poster_) {
        this.poster_ = newPoster;
        this.isPosterFromTech_ = true; // Let components know the poster has changed

        this.trigger('posterchange');
      }
    }
  }
  /**
   * Get or set whether or not the controls are showing.
   *
   * @fires Player#controlsenabled
   *
   * @param {boolean} [bool]
   *        - true to turn controls on
   *        - false to turn controls off
   *
   * @return {boolean}
   *         The current value of controls when getting
   */
  ;

  _proto.controls = function controls(bool) {
    if (bool === undefined) {
      return !!this.controls_;
    }

    bool = !!bool; // Don't trigger a change event unless it actually changed

    if (this.controls_ === bool) {
      return;
    }

    this.controls_ = bool;

    if (this.usingNativeControls()) {
      this.techCall_('setControls', bool);
    }

    if (this.controls_) {
      this.removeClass('vjs-controls-disabled');
      this.addClass('vjs-controls-enabled');
      /**
       * @event Player#controlsenabled
       * @type {EventTarget~Event}
       */

      this.trigger('controlsenabled');

      if (!this.usingNativeControls()) {
        this.addTechControlsListeners_();
      }
    } else {
      this.removeClass('vjs-controls-enabled');
      this.addClass('vjs-controls-disabled');
      /**
       * @event Player#controlsdisabled
       * @type {EventTarget~Event}
       */

      this.trigger('controlsdisabled');

      if (!this.usingNativeControls()) {
        this.removeTechControlsListeners_();
      }
    }
  }
  /**
   * Toggle native controls on/off. Native controls are the controls built into
   * devices (e.g. default iPhone controls) or other techs
   * (e.g. Vimeo Controls)
   * **This should only be set by the current tech, because only the tech knows
   * if it can support native controls**
   *
   * @fires Player#usingnativecontrols
   * @fires Player#usingcustomcontrols
   *
   * @param {boolean} [bool]
   *        - true to turn native controls on
   *        - false to turn native controls off
   *
   * @return {boolean}
   *         The current value of native controls when getting
   */
  ;

  _proto.usingNativeControls = function usingNativeControls(bool) {
    if (bool === undefined) {
      return !!this.usingNativeControls_;
    }

    bool = !!bool; // Don't trigger a change event unless it actually changed

    if (this.usingNativeControls_ === bool) {
      return;
    }

    this.usingNativeControls_ = bool;

    if (this.usingNativeControls_) {
      this.addClass('vjs-using-native-controls');
      /**
       * player is using the native device controls
       *
       * @event Player#usingnativecontrols
       * @type {EventTarget~Event}
       */

      this.trigger('usingnativecontrols');
    } else {
      this.removeClass('vjs-using-native-controls');
      /**
       * player is using the custom HTML controls
       *
       * @event Player#usingcustomcontrols
       * @type {EventTarget~Event}
       */

      this.trigger('usingcustomcontrols');
    }
  }
  /**
   * Set or get the current MediaError
   *
   * @fires Player#error
   *
   * @param  {MediaError|string|number} [err]
   *         A MediaError or a string/number to be turned
   *         into a MediaError
   *
   * @return {MediaError|null}
   *         The current MediaError when getting (or null)
   */
  ;

  _proto.error = function error(err) {
    var _this18 = this;

    if (err === undefined) {
      return this.error_ || null;
    } // allow hooks to modify error object


    hooks('beforeerror').forEach(function (hookFunction) {
      var newErr = hookFunction(_this18, err);

      if (!(isObject(newErr) && !Array.isArray(newErr) || typeof newErr === 'string' || typeof newErr === 'number' || newErr === null)) {
        _this18.log.error('please return a value that MediaError expects in beforeerror hooks');

        return;
      }

      err = newErr;
    }); // Suppress the first error message for no compatible source until
    // user interaction

    if (this.options_.suppressNotSupportedError && err && err.code === 4) {
      var triggerSuppressedError = function triggerSuppressedError() {
        this.error(err);
      };

      this.options_.suppressNotSupportedError = false;
      this.any(['click', 'touchstart'], triggerSuppressedError);
      this.one('loadstart', function () {
        this.off(['click', 'touchstart'], triggerSuppressedError);
      });
      return;
    } // restoring to default


    if (err === null) {
      this.error_ = err;
      this.removeClass('vjs-error');

      if (this.errorDisplay) {
        this.errorDisplay.close();
      }

      return;
    }

    this.error_ = new MediaError(err); // add the vjs-error classname to the player

    this.addClass('vjs-error'); // log the name of the error type and any message
    // IE11 logs "[object object]" and required you to expand message to see error object

    log.error("(CODE:" + this.error_.code + " " + MediaError.errorTypes[this.error_.code] + ")", this.error_.message, this.error_);
    /**
     * @event Player#error
     * @type {EventTarget~Event}
     */

    this.trigger('error'); // notify hooks of the per player error

    hooks('error').forEach(function (hookFunction) {
      return hookFunction(_this18, _this18.error_);
    });
    return;
  }
  /**
   * Report user activity
   *
   * @param {Object} event
   *        Event object
   */
  ;

  _proto.reportUserActivity = function reportUserActivity(event) {
    this.userActivity_ = true;
  }
  /**
   * Get/set if user is active
   *
   * @fires Player#useractive
   * @fires Player#userinactive
   *
   * @param {boolean} [bool]
   *        - true if the user is active
   *        - false if the user is inactive
   *
   * @return {boolean}
   *         The current value of userActive when getting
   */
  ;

  _proto.userActive = function userActive(bool) {
    if (bool === undefined) {
      return this.userActive_;
    }

    bool = !!bool;

    if (bool === this.userActive_) {
      return;
    }

    this.userActive_ = bool;

    if (this.userActive_) {
      this.userActivity_ = true;
      this.removeClass('vjs-user-inactive');
      this.addClass('vjs-user-active');
      /**
       * @event Player#useractive
       * @type {EventTarget~Event}
       */

      this.trigger('useractive');
      return;
    } // Chrome/Safari/IE have bugs where when you change the cursor it can
    // trigger a mousemove event. This causes an issue when you're hiding
    // the cursor when the user is inactive, and a mousemove signals user
    // activity. Making it impossible to go into inactive mode. Specifically
    // this happens in fullscreen when we really need to hide the cursor.
    //
    // When this gets resolved in ALL browsers it can be removed
    // https://code.google.com/p/chromium/issues/detail?id=103041


    if (this.tech_) {
      this.tech_.one('mousemove', function (e) {
        e.stopPropagation();
        e.preventDefault();
      });
    }

    this.userActivity_ = false;
    this.removeClass('vjs-user-active');
    this.addClass('vjs-user-inactive');
    /**
     * @event Player#userinactive
     * @type {EventTarget~Event}
     */

    this.trigger('userinactive');
  }
  /**
   * Listen for user activity based on timeout value
   *
   * @private
   */
  ;

  _proto.listenForUserActivity_ = function listenForUserActivity_() {
    var mouseInProgress;
    var lastMoveX;
    var lastMoveY;
    var handleActivity = bind(this, this.reportUserActivity);

    var handleMouseMove = function handleMouseMove(e) {
      // #1068 - Prevent mousemove spamming
      // Chrome Bug: https://code.google.com/p/chromium/issues/detail?id=366970
      if (e.screenX !== lastMoveX || e.screenY !== lastMoveY) {
        lastMoveX = e.screenX;
        lastMoveY = e.screenY;
        handleActivity();
      }
    };

    var handleMouseDown = function handleMouseDown() {
      handleActivity(); // For as long as the they are touching the device or have their mouse down,
      // we consider them active even if they're not moving their finger or mouse.
      // So we want to continue to update that they are active

      this.clearInterval(mouseInProgress); // Setting userActivity=true now and setting the interval to the same time
      // as the activityCheck interval (250) should ensure we never miss the
      // next activityCheck

      mouseInProgress = this.setInterval(handleActivity, 250);
    };

    var handleMouseUpAndMouseLeave = function handleMouseUpAndMouseLeave(event) {
      handleActivity(); // Stop the interval that maintains activity if the mouse/touch is down

      this.clearInterval(mouseInProgress);
    }; // Any mouse movement will be considered user activity


    this.on('mousedown', handleMouseDown);
    this.on('mousemove', handleMouseMove);
    this.on('mouseup', handleMouseUpAndMouseLeave);
    this.on('mouseleave', handleMouseUpAndMouseLeave);
    var controlBar = this.getChild('controlBar'); // Fixes bug on Android & iOS where when tapping progressBar (when control bar is displayed)
    // controlBar would no longer be hidden by default timeout.

    if (controlBar && !IS_IOS && !IS_ANDROID) {
      controlBar.on('mouseenter', function (event) {
        if (this.player().options_.inactivityTimeout !== 0) {
          this.player().cache_.inactivityTimeout = this.player().options_.inactivityTimeout;
        }

        this.player().options_.inactivityTimeout = 0;
      });
      controlBar.on('mouseleave', function (event) {
        this.player().options_.inactivityTimeout = this.player().cache_.inactivityTimeout;
      });
    } // Listen for keyboard navigation
    // Shouldn't need to use inProgress interval because of key repeat


    this.on('keydown', handleActivity);
    this.on('keyup', handleActivity); // Run an interval every 250 milliseconds instead of stuffing everything into
    // the mousemove/touchmove function itself, to prevent performance degradation.
    // `this.reportUserActivity` simply sets this.userActivity_ to true, which
    // then gets picked up by this loop
    // http://ejohn.org/blog/learning-from-twitter/

    var inactivityTimeout;
    this.setInterval(function () {
      // Check to see if mouse/touch activity has happened
      if (!this.userActivity_) {
        return;
      } // Reset the activity tracker


      this.userActivity_ = false; // If the user state was inactive, set the state to active

      this.userActive(true); // Clear any existing inactivity timeout to start the timer over

      this.clearTimeout(inactivityTimeout);
      var timeout = this.options_.inactivityTimeout;

      if (timeout <= 0) {
        return;
      } // In <timeout> milliseconds, if no more activity has occurred the
      // user will be considered inactive


      inactivityTimeout = this.setTimeout(function () {
        // Protect against the case where the inactivityTimeout can trigger just
        // before the next user activity is picked up by the activity check loop
        // causing a flicker
        if (!this.userActivity_) {
          this.userActive(false);
        }
      }, timeout);
    }, 250);
  }
  /**
   * Gets or sets the current playback rate. A playback rate of
   * 1.0 represents normal speed and 0.5 would indicate half-speed
   * playback, for instance.
   *
   * @see https://html.spec.whatwg.org/multipage/embedded-content.html#dom-media-playbackrate
   *
   * @param {number} [rate]
   *       New playback rate to set.
   *
   * @return {number}
   *         The current playback rate when getting or 1.0
   */
  ;

  _proto.playbackRate = function playbackRate(rate) {
    if (rate !== undefined) {
      // NOTE: this.cache_.lastPlaybackRate is set from the tech handler
      // that is registered above
      this.techCall_('setPlaybackRate', rate);
      return;
    }

    if (this.tech_ && this.tech_.featuresPlaybackRate) {
      return this.cache_.lastPlaybackRate || this.techGet_('playbackRate');
    }

    return 1.0;
  }
  /**
   * Gets or sets the current default playback rate. A default playback rate of
   * 1.0 represents normal speed and 0.5 would indicate half-speed playback, for instance.
   * defaultPlaybackRate will only represent what the initial playbackRate of a video was, not
   * not the current playbackRate.
   *
   * @see https://html.spec.whatwg.org/multipage/embedded-content.html#dom-media-defaultplaybackrate
   *
   * @param {number} [rate]
   *       New default playback rate to set.
   *
   * @return {number|Player}
   *         - The default playback rate when getting or 1.0
   *         - the player when setting
   */
  ;

  _proto.defaultPlaybackRate = function defaultPlaybackRate(rate) {
    if (rate !== undefined) {
      return this.techCall_('setDefaultPlaybackRate', rate);
    }

    if (this.tech_ && this.tech_.featuresPlaybackRate) {
      return this.techGet_('defaultPlaybackRate');
    }

    return 1.0;
  }
  /**
   * Gets or sets the audio flag
   *
   * @param {boolean} bool
   *        - true signals that this is an audio player
   *        - false signals that this is not an audio player
   *
   * @return {boolean}
   *         The current value of isAudio when getting
   */
  ;

  _proto.isAudio = function isAudio(bool) {
    if (bool !== undefined) {
      this.isAudio_ = !!bool;
      return;
    }

    return !!this.isAudio_;
  }
  /**
   * A helper method for adding a {@link TextTrack} to our
   * {@link TextTrackList}.
   *
   * In addition to the W3C settings we allow adding additional info through options.
   *
   * @see http://www.w3.org/html/wg/drafts/html/master/embedded-content-0.html#dom-media-addtexttrack
   *
   * @param {string} [kind]
   *        the kind of TextTrack you are adding
   *
   * @param {string} [label]
   *        the label to give the TextTrack label
   *
   * @param {string} [language]
   *        the language to set on the TextTrack
   *
   * @return {TextTrack|undefined}
   *         the TextTrack that was added or undefined
   *         if there is no tech
   */
  ;

  _proto.addTextTrack = function addTextTrack(kind, label, language) {
    if (this.tech_) {
      return this.tech_.addTextTrack(kind, label, language);
    }
  }
  /**
   * Create a remote {@link TextTrack} and an {@link HTMLTrackElement}.
   * When manualCleanup is set to false, the track will be automatically removed
   * on source changes.
   *
   * @param {Object} options
   *        Options to pass to {@link HTMLTrackElement} during creation. See
   *        {@link HTMLTrackElement} for object properties that you should use.
   *
   * @param {boolean} [manualCleanup=true] if set to false, the TextTrack will be
   *                                       removed on a source change
   *
   * @return {HtmlTrackElement}
   *         the HTMLTrackElement that was created and added
   *         to the HtmlTrackElementList and the remote
   *         TextTrackList
   *
   * @deprecated The default value of the "manualCleanup" parameter will default
   *             to "false" in upcoming versions of Video.js
   */
  ;

  _proto.addRemoteTextTrack = function addRemoteTextTrack(options, manualCleanup) {
    if (this.tech_) {
      return this.tech_.addRemoteTextTrack(options, manualCleanup);
    }
  }
  /**
   * Remove a remote {@link TextTrack} from the respective
   * {@link TextTrackList} and {@link HtmlTrackElementList}.
   *
   * @param {Object} track
   *        Remote {@link TextTrack} to remove
   *
   * @return {undefined}
   *         does not return anything
   */
  ;

  _proto.removeRemoteTextTrack = function removeRemoteTextTrack(obj) {
    if (obj === void 0) {
      obj = {};
    }

    var _obj = obj,
        track = _obj.track;

    if (!track) {
      track = obj;
    } // destructure the input into an object with a track argument, defaulting to arguments[0]
    // default the whole argument to an empty object if nothing was passed in


    if (this.tech_) {
      return this.tech_.removeRemoteTextTrack(track);
    }
  }
  /**
   * Gets available media playback quality metrics as specified by the W3C's Media
   * Playback Quality API.
   *
   * @see [Spec]{@link https://wicg.github.io/media-playback-quality}
   *
   * @return {Object|undefined}
   *         An object with supported media playback quality metrics or undefined if there
   *         is no tech or the tech does not support it.
   */
  ;

  _proto.getVideoPlaybackQuality = function getVideoPlaybackQuality() {
    return this.techGet_('getVideoPlaybackQuality');
  }
  /**
   * Get video width
   *
   * @return {number}
   *         current video width
   */
  ;

  _proto.videoWidth = function videoWidth() {
    return this.tech_ && this.tech_.videoWidth && this.tech_.videoWidth() || 0;
  }
  /**
   * Get video height
   *
   * @return {number}
   *         current video height
   */
  ;

  _proto.videoHeight = function videoHeight() {
    return this.tech_ && this.tech_.videoHeight && this.tech_.videoHeight() || 0;
  }
  /**
   * The player's language code.
   *
   * Changing the langauge will trigger
   * [languagechange]{@link Player#event:languagechange}
   * which Components can use to update control text.
   * ClickableComponent will update its control text by default on
   * [languagechange]{@link Player#event:languagechange}.
   *
   * @fires Player#languagechange
   *
   * @param {string} [code]
   *        the language code to set the player to
   *
   * @return {string}
   *         The current language code when getting
   */
  ;

  _proto.language = function language(code) {
    if (code === undefined) {
      return this.language_;
    }

    if (this.language_ !== String(code).toLowerCase()) {
      this.language_ = String(code).toLowerCase(); // during first init, it's possible some things won't be evented

      if (isEvented(this)) {
        /**
        * fires when the player language change
        *
        * @event Player#languagechange
        * @type {EventTarget~Event}
        */
        this.trigger('languagechange');
      }
    }
  }
  /**
   * Get the player's language dictionary
   * Merge every time, because a newly added plugin might call videojs.addLanguage() at any time
   * Languages specified directly in the player options have precedence
   *
   * @return {Array}
   *         An array of of supported languages
   */
  ;

  _proto.languages = function languages() {
    return mergeOptions(Player.prototype.options_.languages, this.languages_);
  }
  /**
   * returns a JavaScript object reperesenting the current track
   * information. **DOES not return it as JSON**
   *
   * @return {Object}
   *         Object representing the current of track info
   */
  ;

  _proto.toJSON = function toJSON() {
    var options = mergeOptions(this.options_);
    var tracks = options.tracks;
    options.tracks = [];

    for (var i = 0; i < tracks.length; i++) {
      var track = tracks[i]; // deep merge tracks and null out player so no circular references

      track = mergeOptions(track);
      track.player = undefined;
      options.tracks[i] = track;
    }

    return options;
  }
  /**
   * Creates a simple modal dialog (an instance of the {@link ModalDialog}
   * component) that immediately overlays the player with arbitrary
   * content and removes itself when closed.
   *
   * @param {string|Function|Element|Array|null} content
   *        Same as {@link ModalDialog#content}'s param of the same name.
   *        The most straight-forward usage is to provide a string or DOM
   *        element.
   *
   * @param {Object} [options]
   *        Extra options which will be passed on to the {@link ModalDialog}.
   *
   * @return {ModalDialog}
   *         the {@link ModalDialog} that was created
   */
  ;

  _proto.createModal = function createModal(content, options) {
    var _this19 = this;

    options = options || {};
    options.content = content || '';
    var modal = new ModalDialog(this, options);
    this.addChild(modal);
    modal.on('dispose', function () {
      _this19.removeChild(modal);
    });
    modal.open();
    return modal;
  }
  /**
   * Change breakpoint classes when the player resizes.
   *
   * @private
   */
  ;

  _proto.updateCurrentBreakpoint_ = function updateCurrentBreakpoint_() {
    if (!this.responsive()) {
      return;
    }

    var currentBreakpoint = this.currentBreakpoint();
    var currentWidth = this.currentWidth();

    for (var i = 0; i < BREAKPOINT_ORDER.length; i++) {
      var candidateBreakpoint = BREAKPOINT_ORDER[i];
      var maxWidth = this.breakpoints_[candidateBreakpoint];

      if (currentWidth <= maxWidth) {
        // The current breakpoint did not change, nothing to do.
        if (currentBreakpoint === candidateBreakpoint) {
          return;
        } // Only remove a class if there is a current breakpoint.


        if (currentBreakpoint) {
          this.removeClass(BREAKPOINT_CLASSES[currentBreakpoint]);
        }

        this.addClass(BREAKPOINT_CLASSES[candidateBreakpoint]);
        this.breakpoint_ = candidateBreakpoint;
        break;
      }
    }
  }
  /**
   * Removes the current breakpoint.
   *
   * @private
   */
  ;

  _proto.removeCurrentBreakpoint_ = function removeCurrentBreakpoint_() {
    var className = this.currentBreakpointClass();
    this.breakpoint_ = '';

    if (className) {
      this.removeClass(className);
    }
  }
  /**
   * Get or set breakpoints on the player.
   *
   * Calling this method with an object or `true` will remove any previous
   * custom breakpoints and start from the defaults again.
   *
   * @param  {Object|boolean} [breakpoints]
   *         If an object is given, it can be used to provide custom
   *         breakpoints. If `true` is given, will set default breakpoints.
   *         If this argument is not given, will simply return the current
   *         breakpoints.
   *
   * @param  {number} [breakpoints.tiny]
   *         The maximum width for the "vjs-layout-tiny" class.
   *
   * @param  {number} [breakpoints.xsmall]
   *         The maximum width for the "vjs-layout-x-small" class.
   *
   * @param  {number} [breakpoints.small]
   *         The maximum width for the "vjs-layout-small" class.
   *
   * @param  {number} [breakpoints.medium]
   *         The maximum width for the "vjs-layout-medium" class.
   *
   * @param  {number} [breakpoints.large]
   *         The maximum width for the "vjs-layout-large" class.
   *
   * @param  {number} [breakpoints.xlarge]
   *         The maximum width for the "vjs-layout-x-large" class.
   *
   * @param  {number} [breakpoints.huge]
   *         The maximum width for the "vjs-layout-huge" class.
   *
   * @return {Object}
   *         An object mapping breakpoint names to maximum width values.
   */
  ;

  _proto.breakpoints = function breakpoints(_breakpoints) {
    // Used as a getter.
    if (_breakpoints === undefined) {
      return assign(this.breakpoints_);
    }

    this.breakpoint_ = '';
    this.breakpoints_ = assign({}, DEFAULT_BREAKPOINTS, _breakpoints); // When breakpoint definitions change, we need to update the currently
    // selected breakpoint.

    this.updateCurrentBreakpoint_(); // Clone the breakpoints before returning.

    return assign(this.breakpoints_);
  }
  /**
   * Get or set a flag indicating whether or not this player should adjust
   * its UI based on its dimensions.
   *
   * @param  {boolean} value
   *         Should be `true` if the player should adjust its UI based on its
   *         dimensions; otherwise, should be `false`.
   *
   * @return {boolean}
   *         Will be `true` if this player should adjust its UI based on its
   *         dimensions; otherwise, will be `false`.
   */
  ;

  _proto.responsive = function responsive(value) {
    // Used as a getter.
    if (value === undefined) {
      return this.responsive_;
    }

    value = Boolean(value);
    var current = this.responsive_; // Nothing changed.

    if (value === current) {
      return;
    } // The value actually changed, set it.


    this.responsive_ = value; // Start listening for breakpoints and set the initial breakpoint if the
    // player is now responsive.

    if (value) {
      this.on('playerresize', this.boundUpdateCurrentBreakpoint_);
      this.updateCurrentBreakpoint_(); // Stop listening for breakpoints if the player is no longer responsive.
    } else {
      this.off('playerresize', this.boundUpdateCurrentBreakpoint_);
      this.removeCurrentBreakpoint_();
    }

    return value;
  }
  /**
   * Get current breakpoint name, if any.
   *
   * @return {string}
   *         If there is currently a breakpoint set, returns a the key from the
   *         breakpoints object matching it. Otherwise, returns an empty string.
   */
  ;

  _proto.currentBreakpoint = function currentBreakpoint() {
    return this.breakpoint_;
  }
  /**
   * Get the current breakpoint class name.
   *
   * @return {string}
   *         The matching class name (e.g. `"vjs-layout-tiny"` or
   *         `"vjs-layout-large"`) for the current breakpoint. Empty string if
   *         there is no current breakpoint.
   */
  ;

  _proto.currentBreakpointClass = function currentBreakpointClass() {
    return BREAKPOINT_CLASSES[this.breakpoint_] || '';
  }
  /**
   * An object that describes a single piece of media.
   *
   * Properties that are not part of this type description will be retained; so,
   * this can be viewed as a generic metadata storage mechanism as well.
   *
   * @see      {@link https://wicg.github.io/mediasession/#the-mediametadata-interface}
   * @typedef  {Object} Player~MediaObject
   *
   * @property {string} [album]
   *           Unused, except if this object is passed to the `MediaSession`
   *           API.
   *
   * @property {string} [artist]
   *           Unused, except if this object is passed to the `MediaSession`
   *           API.
   *
   * @property {Object[]} [artwork]
   *           Unused, except if this object is passed to the `MediaSession`
   *           API. If not specified, will be populated via the `poster`, if
   *           available.
   *
   * @property {string} [poster]
   *           URL to an image that will display before playback.
   *
   * @property {Tech~SourceObject|Tech~SourceObject[]|string} [src]
   *           A single source object, an array of source objects, or a string
   *           referencing a URL to a media source. It is _highly recommended_
   *           that an object or array of objects is used here, so that source
   *           selection algorithms can take the `type` into account.
   *
   * @property {string} [title]
   *           Unused, except if this object is passed to the `MediaSession`
   *           API.
   *
   * @property {Object[]} [textTracks]
   *           An array of objects to be used to create text tracks, following
   *           the {@link https://www.w3.org/TR/html50/embedded-content-0.html#the-track-element|native track element format}.
   *           For ease of removal, these will be created as "remote" text
   *           tracks and set to automatically clean up on source changes.
   *
   *           These objects may have properties like `src`, `kind`, `label`,
   *           and `language`, see {@link Tech#createRemoteTextTrack}.
   */

  /**
   * Populate the player using a {@link Player~MediaObject|MediaObject}.
   *
   * @param  {Player~MediaObject} media
   *         A media object.
   *
   * @param  {Function} ready
   *         A callback to be called when the player is ready.
   */
  ;

  _proto.loadMedia = function loadMedia(media, ready) {
    var _this20 = this;

    if (!media || typeof media !== 'object') {
      return;
    }

    this.reset(); // Clone the media object so it cannot be mutated from outside.

    this.cache_.media = mergeOptions(media);
    var _this$cache_$media = this.cache_.media,
        artwork = _this$cache_$media.artwork,
        poster = _this$cache_$media.poster,
        src = _this$cache_$media.src,
        textTracks = _this$cache_$media.textTracks; // If `artwork` is not given, create it using `poster`.

    if (!artwork && poster) {
      this.cache_.media.artwork = [{
        src: poster,
        type: getMimetype(poster)
      }];
    }

    if (src) {
      this.src(src);
    }

    if (poster) {
      this.poster(poster);
    }

    if (Array.isArray(textTracks)) {
      textTracks.forEach(function (tt) {
        return _this20.addRemoteTextTrack(tt, false);
      });
    }

    this.ready(ready);
  }
  /**
   * Get a clone of the current {@link Player~MediaObject} for this player.
   *
   * If the `loadMedia` method has not been used, will attempt to return a
   * {@link Player~MediaObject} based on the current state of the player.
   *
   * @return {Player~MediaObject}
   */
  ;

  _proto.getMedia = function getMedia() {
    if (!this.cache_.media) {
      var poster = this.poster();
      var src = this.currentSources();
      var textTracks = Array.prototype.map.call(this.remoteTextTracks(), function (tt) {
        return {
          kind: tt.kind,
          label: tt.label,
          language: tt.language,
          src: tt.src
        };
      });
      var media = {
        src: src,
        textTracks: textTracks
      };

      if (poster) {
        media.poster = poster;
        media.artwork = [{
          src: media.poster,
          type: getMimetype(media.poster)
        }];
      }

      return media;
    }

    return mergeOptions(this.cache_.media);
  }
  /**
   * Gets tag settings
   *
   * @param {Element} tag
   *        The player tag
   *
   * @return {Object}
   *         An object containing all of the settings
   *         for a player tag
   */
  ;

  Player.getTagSettings = function getTagSettings(tag) {
    var baseOptions = {
      sources: [],
      tracks: []
    };
    var tagOptions = getAttributes(tag);
    var dataSetup = tagOptions['data-setup'];

    if (hasClass(tag, 'vjs-fill')) {
      tagOptions.fill = true;
    }

    if (hasClass(tag, 'vjs-fluid')) {
      tagOptions.fluid = true;
    } // Check if data-setup attr exists.


    if (dataSetup !== null) {
      // Parse options JSON
      // If empty string, make it a parsable json object.
      var _safeParseTuple = safeParseTuple__default['default'](dataSetup || '{}'),
          err = _safeParseTuple[0],
          data = _safeParseTuple[1];

      if (err) {
        log.error(err);
      }

      assign(tagOptions, data);
    }

    assign(baseOptions, tagOptions); // Get tag children settings

    if (tag.hasChildNodes()) {
      var children = tag.childNodes;

      for (var i = 0, j = children.length; i < j; i++) {
        var child = children[i]; // Change case needed: http://ejohn.org/blog/nodename-case-sensitivity/

        var childName = child.nodeName.toLowerCase();

        if (childName === 'source') {
          baseOptions.sources.push(getAttributes(child));
        } else if (childName === 'track') {
          baseOptions.tracks.push(getAttributes(child));
        }
      }
    }

    return baseOptions;
  }
  /**
   * Determine whether or not flexbox is supported
   *
   * @return {boolean}
   *         - true if flexbox is supported
   *         - false if flexbox is not supported
   */
  ;

  _proto.flexNotSupported_ = function flexNotSupported_() {
    var elem = document__default['default'].createElement('i'); // Note: We don't actually use flexBasis (or flexOrder), but it's one of the more
    // common flex features that we can rely on when checking for flex support.

    return !('flexBasis' in elem.style || 'webkitFlexBasis' in elem.style || 'mozFlexBasis' in elem.style || 'msFlexBasis' in elem.style || // IE10-specific (2012 flex spec), available for completeness
    'msFlexOrder' in elem.style);
  }
  /**
   * Set debug mode to enable/disable logs at info level.
   *
   * @param {boolean} enabled
   * @fires Player#debugon
   * @fires Player#debugoff
   */
  ;

  _proto.debug = function debug(enabled) {
    if (enabled === undefined) {
      return this.debugEnabled_;
    }

    if (enabled) {
      this.trigger('debugon');
      this.previousLogLevel_ = this.log.level;
      this.log.level('debug');
      this.debugEnabled_ = true;
    } else {
      this.trigger('debugoff');
      this.log.level(this.previousLogLevel_);
      this.previousLogLevel_ = undefined;
      this.debugEnabled_ = false;
    }
  }
  /**
   * Set or get current playback rates.
   * Takes an array and updates the playback rates menu with the new items.
   * Pass in an empty array to hide the menu.
   * Values other than arrays are ignored.
   *
   * @fires Player#playbackrateschange
   * @param {number[]} newRates
   *                   The new rates that the playback rates menu should update to.
   *                   An empty array will hide the menu
   * @return {number[]} When used as a getter will return the current playback rates
   */
  ;

  _proto.playbackRates = function playbackRates(newRates) {
    if (newRates === undefined) {
      return this.cache_.playbackRates;
    } // ignore any value that isn't an array


    if (!Array.isArray(newRates)) {
      return;
    } // ignore any arrays that don't only contain numbers


    if (!newRates.every(function (rate) {
      return typeof rate === 'number';
    })) {
      return;
    }

    this.cache_.playbackRates = newRates;
    /**
    * fires when the playback rates in a player are changed
    *
    * @event Player#playbackrateschange
    * @type {EventTarget~Event}
    */

    this.trigger('playbackrateschange');
  };

  return Player;
}(Component);
/**
 * Get the {@link VideoTrackList}
 * @link https://html.spec.whatwg.org/multipage/embedded-content.html#videotracklist
 *
 * @return {VideoTrackList}
 *         the current video track list
 *
 * @method Player.prototype.videoTracks
 */

/**
 * Get the {@link AudioTrackList}
 * @link https://html.spec.whatwg.org/multipage/embedded-content.html#audiotracklist
 *
 * @return {AudioTrackList}
 *         the current audio track list
 *
 * @method Player.prototype.audioTracks
 */

/**
 * Get the {@link TextTrackList}
 *
 * @link http://www.w3.org/html/wg/drafts/html/master/embedded-content-0.html#dom-media-texttracks
 *
 * @return {TextTrackList}
 *         the current text track list
 *
 * @method Player.prototype.textTracks
 */

/**
 * Get the remote {@link TextTrackList}
 *
 * @return {TextTrackList}
 *         The current remote text track list
 *
 * @method Player.prototype.remoteTextTracks
 */

/**
 * Get the remote {@link HtmlTrackElementList} tracks.
 *
 * @return {HtmlTrackElementList}
 *         The current remote text track element list
 *
 * @method Player.prototype.remoteTextTrackEls
 */


ALL.names.forEach(function (name) {
  var props = ALL[name];

  Player.prototype[props.getterName] = function () {
    if (this.tech_) {
      return this.tech_[props.getterName]();
    } // if we have not yet loadTech_, we create {video,audio,text}Tracks_
    // these will be passed to the tech during loading


    this[props.privateName] = this[props.privateName] || new props.ListClass();
    return this[props.privateName];
  };
});
/**
 * Get or set the `Player`'s crossorigin option. For the HTML5 player, this
 * sets the `crossOrigin` property on the `<video>` tag to control the CORS
 * behavior.
 *
 * @see [Video Element Attributes]{@link https://developer.mozilla.org/en-US/docs/Web/HTML/Element/video#attr-crossorigin}
 *
 * @param {string} [value]
 *        The value to set the `Player`'s crossorigin to. If an argument is
 *        given, must be one of `anonymous` or `use-credentials`.
 *
 * @return {string|undefined}
 *         - The current crossorigin value of the `Player` when getting.
 *         - undefined when setting
 */

Player.prototype.crossorigin = Player.prototype.crossOrigin;
/**
 * Global enumeration of players.
 *
 * The keys are the player IDs and the values are either the {@link Player}
 * instance or `null` for disposed players.
 *
 * @type {Object}
 */

Player.players = {};
var navigator = window__default['default'].navigator;
/*
 * Player instance options, surfaced using options
 * options = Player.prototype.options_
 * Make changes in options, not here.
 *
 * @type {Object}
 * @private
 */

Player.prototype.options_ = {
  // Default order of fallback technology
  techOrder: Tech.defaultTechOrder_,
  html5: {},
  // default inactivity timeout
  inactivityTimeout: 2000,
  // default playback rates
  playbackRates: [],
  // Add playback rate selection by adding rates
  // 'playbackRates': [0.5, 1, 1.5, 2],
  liveui: false,
  // Included control sets
  children: ['mediaLoader', 'posterImage', 'textTrackDisplay', 'loadingSpinner', 'bigPlayButton', 'liveTracker', 'controlBar', 'errorDisplay', 'textTrackSettings', 'resizeManager'],
  language: navigator && (navigator.languages && navigator.languages[0] || navigator.userLanguage || navigator.language) || 'en',
  // locales and their language translations
  languages: {},
  // Default message to show when a video cannot be played.
  notSupportedMessage: 'No compatible source was found for this media.',
  normalizeAutoplay: false,
  fullscreen: {
    options: {
      navigationUI: 'hide'
    }
  },
  breakpoints: {},
  responsive: false
};
[
/**
 * Returns whether or not the player is in the "ended" state.
 *
 * @return {Boolean} True if the player is in the ended state, false if not.
 * @method Player#ended
 */
'ended',
/**
 * Returns whether or not the player is in the "seeking" state.
 *
 * @return {Boolean} True if the player is in the seeking state, false if not.
 * @method Player#seeking
 */
'seeking',
/**
 * Returns the TimeRanges of the media that are currently available
 * for seeking to.
 *
 * @return {TimeRanges} the seekable intervals of the media timeline
 * @method Player#seekable
 */
'seekable',
/**
 * Returns the current state of network activity for the element, from
 * the codes in the list below.
 * - NETWORK_EMPTY (numeric value 0)
 *   The element has not yet been initialised. All attributes are in
 *   their initial states.
 * - NETWORK_IDLE (numeric value 1)
 *   The element's resource selection algorithm is active and has
 *   selected a resource, but it is not actually using the network at
 *   this time.
 * - NETWORK_LOADING (numeric value 2)
 *   The user agent is actively trying to download data.
 * - NETWORK_NO_SOURCE (numeric value 3)
 *   The element's resource selection algorithm is active, but it has
 *   not yet found a resource to use.
 *
 * @see https://html.spec.whatwg.org/multipage/embedded-content.html#network-states
 * @return {number} the current network activity state
 * @method Player#networkState
 */
'networkState',
/**
 * Returns a value that expresses the current state of the element
 * with respect to rendering the current playback position, from the
 * codes in the list below.
 * - HAVE_NOTHING (numeric value 0)
 *   No information regarding the media resource is available.
 * - HAVE_METADATA (numeric value 1)
 *   Enough of the resource has been obtained that the duration of the
 *   resource is available.
 * - HAVE_CURRENT_DATA (numeric value 2)
 *   Data for the immediate current playback position is available.
 * - HAVE_FUTURE_DATA (numeric value 3)
 *   Data for the immediate current playback position is available, as
 *   well as enough data for the user agent to advance the current
 *   playback position in the direction of playback.
 * - HAVE_ENOUGH_DATA (numeric value 4)
 *   The user agent estimates that enough data is available for
 *   playback to proceed uninterrupted.
 *
 * @see https://html.spec.whatwg.org/multipage/embedded-content.html#dom-media-readystate
 * @return {number} the current playback rendering state
 * @method Player#readyState
 */
'readyState'].forEach(function (fn) {
  Player.prototype[fn] = function () {
    return this.techGet_(fn);
  };
});
TECH_EVENTS_RETRIGGER.forEach(function (event) {
  Player.prototype["handleTech" + toTitleCase(event) + "_"] = function () {
    return this.trigger(event);
  };
});
/**
 * Fired when the player has initial duration and dimension information
 *
 * @event Player#loadedmetadata
 * @type {EventTarget~Event}
 */

/**
 * Fired when the player has downloaded data at the current playback position
 *
 * @event Player#loadeddata
 * @type {EventTarget~Event}
 */

/**
 * Fired when the current playback position has changed *
 * During playback this is fired every 15-250 milliseconds, depending on the
 * playback technology in use.
 *
 * @event Player#timeupdate
 * @type {EventTarget~Event}
 */

/**
 * Fired when the volume changes
 *
 * @event Player#volumechange
 * @type {EventTarget~Event}
 */

/**
 * Reports whether or not a player has a plugin available.
 *
 * This does not report whether or not the plugin has ever been initialized
 * on this player. For that, [usingPlugin]{@link Player#usingPlugin}.
 *
 * @method Player#hasPlugin
 * @param  {string}  name
 *         The name of a plugin.
 *
 * @return {boolean}
 *         Whether or not this player has the requested plugin available.
 */

/**
 * Reports whether or not a player is using a plugin by name.
 *
 * For basic plugins, this only reports whether the plugin has _ever_ been
 * initialized on this player.
 *
 * @method Player#usingPlugin
 * @param  {string} name
 *         The name of a plugin.
 *
 * @return {boolean}
 *         Whether or not this player is using the requested plugin.
 */

Component.registerComponent('Player', Player);

/**
 * The base plugin name.
 *
 * @private
 * @constant
 * @type {string}
 */

var BASE_PLUGIN_NAME = 'plugin';
/**
 * The key on which a player's active plugins cache is stored.
 *
 * @private
 * @constant
 * @type     {string}
 */

var PLUGIN_CACHE_KEY = 'activePlugins_';
/**
 * Stores registered plugins in a private space.
 *
 * @private
 * @type    {Object}
 */

var pluginStorage = {};
/**
 * Reports whether or not a plugin has been registered.
 *
 * @private
 * @param   {string} name
 *          The name of a plugin.
 *
 * @return {boolean}
 *          Whether or not the plugin has been registered.
 */

var pluginExists = function pluginExists(name) {
  return pluginStorage.hasOwnProperty(name);
};
/**
 * Get a single registered plugin by name.
 *
 * @private
 * @param   {string} name
 *          The name of a plugin.
 *
 * @return {Function|undefined}
 *          The plugin (or undefined).
 */


var getPlugin = function getPlugin(name) {
  return pluginExists(name) ? pluginStorage[name] : undefined;
};
/**
 * Marks a plugin as "active" on a player.
 *
 * Also, ensures that the player has an object for tracking active plugins.
 *
 * @private
 * @param   {Player} player
 *          A Video.js player instance.
 *
 * @param   {string} name
 *          The name of a plugin.
 */


var markPluginAsActive = function markPluginAsActive(player, name) {
  player[PLUGIN_CACHE_KEY] = player[PLUGIN_CACHE_KEY] || {};
  player[PLUGIN_CACHE_KEY][name] = true;
};
/**
 * Triggers a pair of plugin setup events.
 *
 * @private
 * @param  {Player} player
 *         A Video.js player instance.
 *
 * @param  {Plugin~PluginEventHash} hash
 *         A plugin event hash.
 *
 * @param  {boolean} [before]
 *         If true, prefixes the event name with "before". In other words,
 *         use this to trigger "beforepluginsetup" instead of "pluginsetup".
 */


var triggerSetupEvent = function triggerSetupEvent(player, hash, before) {
  var eventName = (before ? 'before' : '') + 'pluginsetup';
  player.trigger(eventName, hash);
  player.trigger(eventName + ':' + hash.name, hash);
};
/**
 * Takes a basic plugin function and returns a wrapper function which marks
 * on the player that the plugin has been activated.
 *
 * @private
 * @param   {string} name
 *          The name of the plugin.
 *
 * @param   {Function} plugin
 *          The basic plugin.
 *
 * @return {Function}
 *          A wrapper function for the given plugin.
 */


var createBasicPlugin = function createBasicPlugin(name, plugin) {
  var basicPluginWrapper = function basicPluginWrapper() {
    // We trigger the "beforepluginsetup" and "pluginsetup" events on the player
    // regardless, but we want the hash to be consistent with the hash provided
    // for advanced plugins.
    //
    // The only potentially counter-intuitive thing here is the `instance` in
    // the "pluginsetup" event is the value returned by the `plugin` function.
    triggerSetupEvent(this, {
      name: name,
      plugin: plugin,
      instance: null
    }, true);
    var instance = plugin.apply(this, arguments);
    markPluginAsActive(this, name);
    triggerSetupEvent(this, {
      name: name,
      plugin: plugin,
      instance: instance
    });
    return instance;
  };

  Object.keys(plugin).forEach(function (prop) {
    basicPluginWrapper[prop] = plugin[prop];
  });
  return basicPluginWrapper;
};
/**
 * Takes a plugin sub-class and returns a factory function for generating
 * instances of it.
 *
 * This factory function will replace itself with an instance of the requested
 * sub-class of Plugin.
 *
 * @private
 * @param   {string} name
 *          The name of the plugin.
 *
 * @param   {Plugin} PluginSubClass
 *          The advanced plugin.
 *
 * @return {Function}
 */


var createPluginFactory = function createPluginFactory(name, PluginSubClass) {
  // Add a `name` property to the plugin prototype so that each plugin can
  // refer to itself by name.
  PluginSubClass.prototype.name = name;
  return function () {
    triggerSetupEvent(this, {
      name: name,
      plugin: PluginSubClass,
      instance: null
    }, true);

    for (var _len = arguments.length, args = new Array(_len), _key = 0; _key < _len; _key++) {
      args[_key] = arguments[_key];
    }

    var instance = _construct__default['default'](PluginSubClass, [this].concat(args)); // The plugin is replaced by a function that returns the current instance.


    this[name] = function () {
      return instance;
    };

    triggerSetupEvent(this, instance.getEventHash());
    return instance;
  };
};
/**
 * Parent class for all advanced plugins.
 *
 * @mixes   module:evented~EventedMixin
 * @mixes   module:stateful~StatefulMixin
 * @fires   Player#beforepluginsetup
 * @fires   Player#beforepluginsetup:$name
 * @fires   Player#pluginsetup
 * @fires   Player#pluginsetup:$name
 * @listens Player#dispose
 * @throws  {Error}
 *          If attempting to instantiate the base {@link Plugin} class
 *          directly instead of via a sub-class.
 */


var Plugin = /*#__PURE__*/function () {
  /**
   * Creates an instance of this class.
   *
   * Sub-classes should call `super` to ensure plugins are properly initialized.
   *
   * @param {Player} player
   *        A Video.js player instance.
   */
  function Plugin(player) {
    if (this.constructor === Plugin) {
      throw new Error('Plugin must be sub-classed; not directly instantiated.');
    }

    this.player = player;

    if (!this.log) {
      this.log = this.player.log.createLogger(this.name);
    } // Make this object evented, but remove the added `trigger` method so we
    // use the prototype version instead.


    evented(this);
    delete this.trigger;
    stateful(this, this.constructor.defaultState);
    markPluginAsActive(player, this.name); // Auto-bind the dispose method so we can use it as a listener and unbind
    // it later easily.

    this.dispose = this.dispose.bind(this); // If the player is disposed, dispose the plugin.

    player.on('dispose', this.dispose);
  }
  /**
   * Get the version of the plugin that was set on <pluginName>.VERSION
   */


  var _proto = Plugin.prototype;

  _proto.version = function version() {
    return this.constructor.VERSION;
  }
  /**
   * Each event triggered by plugins includes a hash of additional data with
   * conventional properties.
   *
   * This returns that object or mutates an existing hash.
   *
   * @param   {Object} [hash={}]
   *          An object to be used as event an event hash.
   *
   * @return {Plugin~PluginEventHash}
   *          An event hash object with provided properties mixed-in.
   */
  ;

  _proto.getEventHash = function getEventHash(hash) {
    if (hash === void 0) {
      hash = {};
    }

    hash.name = this.name;
    hash.plugin = this.constructor;
    hash.instance = this;
    return hash;
  }
  /**
   * Triggers an event on the plugin object and overrides
   * {@link module:evented~EventedMixin.trigger|EventedMixin.trigger}.
   *
   * @param   {string|Object} event
   *          An event type or an object with a type property.
   *
   * @param   {Object} [hash={}]
   *          Additional data hash to merge with a
   *          {@link Plugin~PluginEventHash|PluginEventHash}.
   *
   * @return {boolean}
   *          Whether or not default was prevented.
   */
  ;

  _proto.trigger = function trigger$1(event, hash) {
    if (hash === void 0) {
      hash = {};
    }

    return trigger(this.eventBusEl_, event, this.getEventHash(hash));
  }
  /**
   * Handles "statechanged" events on the plugin. No-op by default, override by
   * subclassing.
   *
   * @abstract
   * @param    {Event} e
   *           An event object provided by a "statechanged" event.
   *
   * @param    {Object} e.changes
   *           An object describing changes that occurred with the "statechanged"
   *           event.
   */
  ;

  _proto.handleStateChanged = function handleStateChanged(e) {}
  /**
   * Disposes a plugin.
   *
   * Subclasses can override this if they want, but for the sake of safety,
   * it's probably best to subscribe the "dispose" event.
   *
   * @fires Plugin#dispose
   */
  ;

  _proto.dispose = function dispose() {
    var name = this.name,
        player = this.player;
    /**
     * Signals that a advanced plugin is about to be disposed.
     *
     * @event Plugin#dispose
     * @type  {EventTarget~Event}
     */

    this.trigger('dispose');
    this.off();
    player.off('dispose', this.dispose); // Eliminate any possible sources of leaking memory by clearing up
    // references between the player and the plugin instance and nulling out
    // the plugin's state and replacing methods with a function that throws.

    player[PLUGIN_CACHE_KEY][name] = false;
    this.player = this.state = null; // Finally, replace the plugin name on the player with a new factory
    // function, so that the plugin is ready to be set up again.

    player[name] = createPluginFactory(name, pluginStorage[name]);
  }
  /**
   * Determines if a plugin is a basic plugin (i.e. not a sub-class of `Plugin`).
   *
   * @param   {string|Function} plugin
   *          If a string, matches the name of a plugin. If a function, will be
   *          tested directly.
   *
   * @return {boolean}
   *          Whether or not a plugin is a basic plugin.
   */
  ;

  Plugin.isBasic = function isBasic(plugin) {
    var p = typeof plugin === 'string' ? getPlugin(plugin) : plugin;
    return typeof p === 'function' && !Plugin.prototype.isPrototypeOf(p.prototype);
  }
  /**
   * Register a Video.js plugin.
   *
   * @param   {string} name
   *          The name of the plugin to be registered. Must be a string and
   *          must not match an existing plugin or a method on the `Player`
   *          prototype.
   *
   * @param   {Function} plugin
   *          A sub-class of `Plugin` or a function for basic plugins.
   *
   * @return {Function}
   *          For advanced plugins, a factory function for that plugin. For
   *          basic plugins, a wrapper function that initializes the plugin.
   */
  ;

  Plugin.registerPlugin = function registerPlugin(name, plugin) {
    if (typeof name !== 'string') {
      throw new Error("Illegal plugin name, \"" + name + "\", must be a string, was " + typeof name + ".");
    }

    if (pluginExists(name)) {
      log.warn("A plugin named \"" + name + "\" already exists. You may want to avoid re-registering plugins!");
    } else if (Player.prototype.hasOwnProperty(name)) {
      throw new Error("Illegal plugin name, \"" + name + "\", cannot share a name with an existing player method!");
    }

    if (typeof plugin !== 'function') {
      throw new Error("Illegal plugin for \"" + name + "\", must be a function, was " + typeof plugin + ".");
    }

    pluginStorage[name] = plugin; // Add a player prototype method for all sub-classed plugins (but not for
    // the base Plugin class).

    if (name !== BASE_PLUGIN_NAME) {
      if (Plugin.isBasic(plugin)) {
        Player.prototype[name] = createBasicPlugin(name, plugin);
      } else {
        Player.prototype[name] = createPluginFactory(name, plugin);
      }
    }

    return plugin;
  }
  /**
   * De-register a Video.js plugin.
   *
   * @param  {string} name
   *         The name of the plugin to be de-registered. Must be a string that
   *         matches an existing plugin.
   *
   * @throws {Error}
   *         If an attempt is made to de-register the base plugin.
   */
  ;

  Plugin.deregisterPlugin = function deregisterPlugin(name) {
    if (name === BASE_PLUGIN_NAME) {
      throw new Error('Cannot de-register base plugin.');
    }

    if (pluginExists(name)) {
      delete pluginStorage[name];
      delete Player.prototype[name];
    }
  }
  /**
   * Gets an object containing multiple Video.js plugins.
   *
   * @param   {Array} [names]
   *          If provided, should be an array of plugin names. Defaults to _all_
   *          plugin names.
   *
   * @return {Object|undefined}
   *          An object containing plugin(s) associated with their name(s) or
   *          `undefined` if no matching plugins exist).
   */
  ;

  Plugin.getPlugins = function getPlugins(names) {
    if (names === void 0) {
      names = Object.keys(pluginStorage);
    }

    var result;
    names.forEach(function (name) {
      var plugin = getPlugin(name);

      if (plugin) {
        result = result || {};
        result[name] = plugin;
      }
    });
    return result;
  }
  /**
   * Gets a plugin's version, if available
   *
   * @param   {string} name
   *          The name of a plugin.
   *
   * @return {string}
   *          The plugin's version or an empty string.
   */
  ;

  Plugin.getPluginVersion = function getPluginVersion(name) {
    var plugin = getPlugin(name);
    return plugin && plugin.VERSION || '';
  };

  return Plugin;
}();
/**
 * Gets a plugin by name if it exists.
 *
 * @static
 * @method   getPlugin
 * @memberOf Plugin
 * @param    {string} name
 *           The name of a plugin.
 *
 * @returns  {Function|undefined}
 *           The plugin (or `undefined`).
 */


Plugin.getPlugin = getPlugin;
/**
 * The name of the base plugin class as it is registered.
 *
 * @type {string}
 */

Plugin.BASE_PLUGIN_NAME = BASE_PLUGIN_NAME;
Plugin.registerPlugin(BASE_PLUGIN_NAME, Plugin);
/**
 * Documented in player.js
 *
 * @ignore
 */

Player.prototype.usingPlugin = function (name) {
  return !!this[PLUGIN_CACHE_KEY] && this[PLUGIN_CACHE_KEY][name] === true;
};
/**
 * Documented in player.js
 *
 * @ignore
 */


Player.prototype.hasPlugin = function (name) {
  return !!pluginExists(name);
};
/**
 * Signals that a plugin is about to be set up on a player.
 *
 * @event    Player#beforepluginsetup
 * @type     {Plugin~PluginEventHash}
 */

/**
 * Signals that a plugin is about to be set up on a player - by name. The name
 * is the name of the plugin.
 *
 * @event    Player#beforepluginsetup:$name
 * @type     {Plugin~PluginEventHash}
 */

/**
 * Signals that a plugin has just been set up on a player.
 *
 * @event    Player#pluginsetup
 * @type     {Plugin~PluginEventHash}
 */

/**
 * Signals that a plugin has just been set up on a player - by name. The name
 * is the name of the plugin.
 *
 * @event    Player#pluginsetup:$name
 * @type     {Plugin~PluginEventHash}
 */

/**
 * @typedef  {Object} Plugin~PluginEventHash
 *
 * @property {string} instance
 *           For basic plugins, the return value of the plugin function. For
 *           advanced plugins, the plugin instance on which the event is fired.
 *
 * @property {string} name
 *           The name of the plugin.
 *
 * @property {string} plugin
 *           For basic plugins, the plugin function. For advanced plugins, the
 *           plugin class/constructor.
 */

/**
 * @file extend.js
 * @module extend
 */
/**
 * Used to subclass an existing class by emulating ES subclassing using the
 * `extends` keyword.
 *
 * @function
 * @example
 * var MyComponent = videojs.extend(videojs.getComponent('Component'), {
 *   myCustomMethod: function() {
 *     // Do things in my method.
 *   }
 * });
 *
 * @param    {Function} superClass
 *           The class to inherit from
 *
 * @param    {Object}   [subClassMethods={}]
 *           Methods of the new class
 *
 * @return   {Function}
 *           The new class with subClassMethods that inherited superClass.
 */

var extend = function extend(superClass, subClassMethods) {
  if (subClassMethods === void 0) {
    subClassMethods = {};
  }

  var subClass = function subClass() {
    superClass.apply(this, arguments);
  };

  var methods = {};

  if (typeof subClassMethods === 'object') {
    if (subClassMethods.constructor !== Object.prototype.constructor) {
      subClass = subClassMethods.constructor;
    }

    methods = subClassMethods;
  } else if (typeof subClassMethods === 'function') {
    subClass = subClassMethods;
  }

  _inherits__default['default'](subClass, superClass); // this is needed for backward-compatibility and node compatibility.


  if (superClass) {
    subClass.super_ = superClass;
  } // Extend subObj's prototype with functions and other properties from props


  for (var name in methods) {
    if (methods.hasOwnProperty(name)) {
      subClass.prototype[name] = methods[name];
    }
  }

  return subClass;
};

/**
 * @file video.js
 * @module videojs
 */
/**
 * Normalize an `id` value by trimming off a leading `#`
 *
 * @private
 * @param   {string} id
 *          A string, maybe with a leading `#`.
 *
 * @return {string}
 *          The string, without any leading `#`.
 */

var normalizeId = function normalizeId(id) {
  return id.indexOf('#') === 0 ? id.slice(1) : id;
};
/**
 * The `videojs()` function doubles as the main function for users to create a
 * {@link Player} instance as well as the main library namespace.
 *
 * It can also be used as a getter for a pre-existing {@link Player} instance.
 * However, we _strongly_ recommend using `videojs.getPlayer()` for this
 * purpose because it avoids any potential for unintended initialization.
 *
 * Due to [limitations](https://github.com/jsdoc3/jsdoc/issues/955#issuecomment-313829149)
 * of our JSDoc template, we cannot properly document this as both a function
 * and a namespace, so its function signature is documented here.
 *
 * #### Arguments
 * ##### id
 * string|Element, **required**
 *
 * Video element or video element ID.
 *
 * ##### options
 * Object, optional
 *
 * Options object for providing settings.
 * See: [Options Guide](https://docs.videojs.com/tutorial-options.html).
 *
 * ##### ready
 * {@link Component~ReadyCallback}, optional
 *
 * A function to be called when the {@link Player} and {@link Tech} are ready.
 *
 * #### Return Value
 *
 * The `videojs()` function returns a {@link Player} instance.
 *
 * @namespace
 *
 * @borrows AudioTrack as AudioTrack
 * @borrows Component.getComponent as getComponent
 * @borrows module:computed-style~computedStyle as computedStyle
 * @borrows module:events.on as on
 * @borrows module:events.one as one
 * @borrows module:events.off as off
 * @borrows module:events.trigger as trigger
 * @borrows EventTarget as EventTarget
 * @borrows module:extend~extend as extend
 * @borrows module:fn.bind as bind
 * @borrows module:format-time.formatTime as formatTime
 * @borrows module:format-time.resetFormatTime as resetFormatTime
 * @borrows module:format-time.setFormatTime as setFormatTime
 * @borrows module:merge-options.mergeOptions as mergeOptions
 * @borrows module:middleware.use as use
 * @borrows Player.players as players
 * @borrows Plugin.registerPlugin as registerPlugin
 * @borrows Plugin.deregisterPlugin as deregisterPlugin
 * @borrows Plugin.getPlugins as getPlugins
 * @borrows Plugin.getPlugin as getPlugin
 * @borrows Plugin.getPluginVersion as getPluginVersion
 * @borrows Tech.getTech as getTech
 * @borrows Tech.registerTech as registerTech
 * @borrows TextTrack as TextTrack
 * @borrows module:time-ranges.createTimeRanges as createTimeRange
 * @borrows module:time-ranges.createTimeRanges as createTimeRanges
 * @borrows module:url.isCrossOrigin as isCrossOrigin
 * @borrows module:url.parseUrl as parseUrl
 * @borrows VideoTrack as VideoTrack
 *
 * @param  {string|Element} id
 *         Video element or video element ID.
 *
 * @param  {Object} [options]
 *         Options object for providing settings.
 *         See: [Options Guide](https://docs.videojs.com/tutorial-options.html).
 *
 * @param  {Component~ReadyCallback} [ready]
 *         A function to be called when the {@link Player} and {@link Tech} are
 *         ready.
 *
 * @return {Player}
 *         The `videojs()` function returns a {@link Player|Player} instance.
 */


function videojs(id, options, ready) {
  var player = videojs.getPlayer(id);

  if (player) {
    if (options) {
      log.warn("Player \"" + id + "\" is already initialised. Options will not be applied.");
    }

    if (ready) {
      player.ready(ready);
    }

    return player;
  }

  var el = typeof id === 'string' ? $('#' + normalizeId(id)) : id;

  if (!isEl(el)) {
    throw new TypeError('The element or ID supplied is not valid. (videojs)');
  } // document.body.contains(el) will only check if el is contained within that one document.
  // This causes problems for elements in iframes.
  // Instead, use the element's ownerDocument instead of the global document.
  // This will make sure that the element is indeed in the dom of that document.
  // Additionally, check that the document in question has a default view.
  // If the document is no longer attached to the dom, the defaultView of the document will be null.


  if (!el.ownerDocument.defaultView || !el.ownerDocument.body.contains(el)) {
    log.warn('The element supplied is not included in the DOM');
  }

  options = options || {};
  hooks('beforesetup').forEach(function (hookFunction) {
    var opts = hookFunction(el, mergeOptions(options));

    if (!isObject(opts) || Array.isArray(opts)) {
      log.error('please return an object in beforesetup hooks');
      return;
    }

    options = mergeOptions(options, opts);
  }); // We get the current "Player" component here in case an integration has
  // replaced it with a custom player.

  var PlayerComponent = Component.getComponent('Player');
  player = new PlayerComponent(el, options, ready);
  hooks('setup').forEach(function (hookFunction) {
    return hookFunction(player);
  });
  return player;
}

videojs.hooks_ = hooks_;
videojs.hooks = hooks;
videojs.hook = hook;
videojs.hookOnce = hookOnce;
videojs.removeHook = removeHook; // Add default styles

if (window__default['default'].VIDEOJS_NO_DYNAMIC_STYLE !== true && isReal()) {
  var style = $('.vjs-styles-defaults');

  if (!style) {
    style = createStyleElement('vjs-styles-defaults');
    var head = $('head');

    if (head) {
      head.insertBefore(style, head.firstChild);
    }

    setTextContent(style, "\n      .video-js {\n        width: 300px;\n        height: 150px;\n      }\n\n      .vjs-fluid {\n        padding-top: 56.25%\n      }\n    ");
  }
} // Run Auto-load players
// You have to wait at least once in case this script is loaded after your
// video in the DOM (weird behavior only with minified version)


autoSetupTimeout(1, videojs);
/**
 * Current Video.js version. Follows [semantic versioning](https://semver.org/).
 *
 * @type {string}
 */

videojs.VERSION = version;
/**
 * The global options object. These are the settings that take effect
 * if no overrides are specified when the player is created.
 *
 * @type {Object}
 */

videojs.options = Player.prototype.options_;
/**
 * Get an object with the currently created players, keyed by player ID
 *
 * @return {Object}
 *         The created players
 */

videojs.getPlayers = function () {
  return Player.players;
};
/**
 * Get a single player based on an ID or DOM element.
 *
 * This is useful if you want to check if an element or ID has an associated
 * Video.js player, but not create one if it doesn't.
 *
 * @param   {string|Element} id
 *          An HTML element - `<video>`, `<audio>`, or `<video-js>` -
 *          or a string matching the `id` of such an element.
 *
 * @return {Player|undefined}
 *          A player instance or `undefined` if there is no player instance
 *          matching the argument.
 */


videojs.getPlayer = function (id) {
  var players = Player.players;
  var tag;

  if (typeof id === 'string') {
    var nId = normalizeId(id);
    var player = players[nId];

    if (player) {
      return player;
    }

    tag = $('#' + nId);
  } else {
    tag = id;
  }

  if (isEl(tag)) {
    var _tag = tag,
        _player = _tag.player,
        playerId = _tag.playerId; // Element may have a `player` property referring to an already created
    // player instance. If so, return that.

    if (_player || players[playerId]) {
      return _player || players[playerId];
    }
  }
};
/**
 * Returns an array of all current players.
 *
 * @return {Array}
 *         An array of all players. The array will be in the order that
 *         `Object.keys` provides, which could potentially vary between
 *         JavaScript engines.
 *
 */


videojs.getAllPlayers = function () {
  return (// Disposed players leave a key with a `null` value, so we need to make sure
    // we filter those out.
    Object.keys(Player.players).map(function (k) {
      return Player.players[k];
    }).filter(Boolean)
  );
};

videojs.players = Player.players;
videojs.getComponent = Component.getComponent;
/**
 * Register a component so it can referred to by name. Used when adding to other
 * components, either through addChild `component.addChild('myComponent')` or through
 * default children options  `{ children: ['myComponent'] }`.
 *
 * > NOTE: You could also just initialize the component before adding.
 * `component.addChild(new MyComponent());`
 *
 * @param {string} name
 *        The class name of the component
 *
 * @param {Component} comp
 *        The component class
 *
 * @return {Component}
 *         The newly registered component
 */

videojs.registerComponent = function (name, comp) {
  if (Tech.isTech(comp)) {
    log.warn("The " + name + " tech was registered as a component. It should instead be registered using videojs.registerTech(name, tech)");
  }

  Component.registerComponent.call(Component, name, comp);
};

videojs.getTech = Tech.getTech;
videojs.registerTech = Tech.registerTech;
videojs.use = use;
/**
 * An object that can be returned by a middleware to signify
 * that the middleware is being terminated.
 *
 * @type {object}
 * @property {object} middleware.TERMINATOR
 */

Object.defineProperty(videojs, 'middleware', {
  value: {},
  writeable: false,
  enumerable: true
});
Object.defineProperty(videojs.middleware, 'TERMINATOR', {
  value: TERMINATOR,
  writeable: false,
  enumerable: true
});
/**
 * A reference to the {@link module:browser|browser utility module} as an object.
 *
 * @type {Object}
 * @see  {@link module:browser|browser}
 */

videojs.browser = browser;
/**
 * Use {@link module:browser.TOUCH_ENABLED|browser.TOUCH_ENABLED} instead; only
 * included for backward-compatibility with 4.x.
 *
 * @deprecated Since version 5.0, use {@link module:browser.TOUCH_ENABLED|browser.TOUCH_ENABLED instead.
 * @type {boolean}
 */

videojs.TOUCH_ENABLED = TOUCH_ENABLED;
videojs.extend = extend;
videojs.mergeOptions = mergeOptions;
videojs.bind = bind;
videojs.registerPlugin = Plugin.registerPlugin;
videojs.deregisterPlugin = Plugin.deregisterPlugin;
/**
 * Deprecated method to register a plugin with Video.js
 *
 * @deprecated videojs.plugin() is deprecated; use videojs.registerPlugin() instead
 *
 * @param {string} name
 *        The plugin name
 *
 * @param {Plugin|Function} plugin
 *         The plugin sub-class or function
 */

videojs.plugin = function (name, plugin) {
  log.warn('videojs.plugin() is deprecated; use videojs.registerPlugin() instead');
  return Plugin.registerPlugin(name, plugin);
};

videojs.getPlugins = Plugin.getPlugins;
videojs.getPlugin = Plugin.getPlugin;
videojs.getPluginVersion = Plugin.getPluginVersion;
/**
 * Adding languages so that they're available to all players.
 * Example: `videojs.addLanguage('es', { 'Hello': 'Hola' });`
 *
 * @param {string} code
 *        The language code or dictionary property
 *
 * @param {Object} data
 *        The data values to be translated
 *
 * @return {Object}
 *         The resulting language dictionary object
 */

videojs.addLanguage = function (code, data) {
  var _mergeOptions;

  code = ('' + code).toLowerCase();
  videojs.options.languages = mergeOptions(videojs.options.languages, (_mergeOptions = {}, _mergeOptions[code] = data, _mergeOptions));
  return videojs.options.languages[code];
};
/**
 * A reference to the {@link module:log|log utility module} as an object.
 *
 * @type {Function}
 * @see  {@link module:log|log}
 */


videojs.log = log;
videojs.createLogger = createLogger;
videojs.createTimeRange = videojs.createTimeRanges = createTimeRanges;
videojs.formatTime = formatTime;
videojs.setFormatTime = setFormatTime;
videojs.resetFormatTime = resetFormatTime;
videojs.parseUrl = parseUrl;
videojs.isCrossOrigin = isCrossOrigin;
videojs.EventTarget = EventTarget;
videojs.on = on;
videojs.one = one;
videojs.off = off;
videojs.trigger = trigger;
/**
 * A cross-browser XMLHttpRequest wrapper.
 *
 * @function
 * @param    {Object} options
 *           Settings for the request.
 *
 * @return   {XMLHttpRequest|XDomainRequest}
 *           The request object.
 *
 * @see      https://github.com/Raynos/xhr
 */

videojs.xhr = XHR__default['default'];
videojs.TextTrack = TextTrack;
videojs.AudioTrack = AudioTrack;
videojs.VideoTrack = VideoTrack;
['isEl', 'isTextNode', 'createEl', 'hasClass', 'addClass', 'removeClass', 'toggleClass', 'setAttributes', 'getAttributes', 'emptyEl', 'appendContent', 'insertContent'].forEach(function (k) {
  videojs[k] = function () {
    log.warn("videojs." + k + "() is deprecated; use videojs.dom." + k + "() instead");
    return Dom[k].apply(null, arguments);
  };
});
videojs.computedStyle = computedStyle;
/**
 * A reference to the {@link module:dom|DOM utility module} as an object.
 *
 * @type {Object}
 * @see  {@link module:dom|dom}
 */

videojs.dom = Dom;
/**
 * A reference to the {@link module:url|URL utility module} as an object.
 *
 * @type {Object}
 * @see  {@link module:url|url}
 */

videojs.url = Url;
videojs.defineLazyProperty = defineLazyProperty; // Adding less ambiguous text for fullscreen button.
// In a major update this could become the default text and key.

videojs.addLanguage('en', {
  'Non-Fullscreen': 'Exit Fullscreen'
});

module.exports = videojs;
