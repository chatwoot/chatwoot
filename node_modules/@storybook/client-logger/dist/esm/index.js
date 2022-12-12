import "core-js/modules/es.array.concat.js";
import "core-js/modules/es.array.iterator.js";
import "core-js/modules/es.object.to-string.js";
import "core-js/modules/es.set.js";
import "core-js/modules/es.string.iterator.js";
import "core-js/modules/web.dom-collections.iterator.js";
import "core-js/modules/es.regexp.exec.js";
import "core-js/modules/es.string.replace.js";
import global from 'global';
var LOGLEVEL = global.LOGLEVEL,
    console = global.console;
var levels = {
  trace: 1,
  debug: 2,
  info: 3,
  warn: 4,
  error: 5,
  silent: 10
};
var currentLogLevelString = LOGLEVEL;
var currentLogLevelNumber = levels[currentLogLevelString] || levels.info;
export var logger = {
  trace: function trace(message) {
    for (var _len = arguments.length, rest = new Array(_len > 1 ? _len - 1 : 0), _key = 1; _key < _len; _key++) {
      rest[_key - 1] = arguments[_key];
    }

    return currentLogLevelNumber <= levels.trace && console.trace.apply(console, [message].concat(rest));
  },
  debug: function debug(message) {
    for (var _len2 = arguments.length, rest = new Array(_len2 > 1 ? _len2 - 1 : 0), _key2 = 1; _key2 < _len2; _key2++) {
      rest[_key2 - 1] = arguments[_key2];
    }

    return currentLogLevelNumber <= levels.debug && console.debug.apply(console, [message].concat(rest));
  },
  info: function info(message) {
    for (var _len3 = arguments.length, rest = new Array(_len3 > 1 ? _len3 - 1 : 0), _key3 = 1; _key3 < _len3; _key3++) {
      rest[_key3 - 1] = arguments[_key3];
    }

    return currentLogLevelNumber <= levels.info && console.info.apply(console, [message].concat(rest));
  },
  warn: function warn(message) {
    for (var _len4 = arguments.length, rest = new Array(_len4 > 1 ? _len4 - 1 : 0), _key4 = 1; _key4 < _len4; _key4++) {
      rest[_key4 - 1] = arguments[_key4];
    }

    return currentLogLevelNumber <= levels.warn && console.warn.apply(console, [message].concat(rest));
  },
  error: function error(message) {
    for (var _len5 = arguments.length, rest = new Array(_len5 > 1 ? _len5 - 1 : 0), _key5 = 1; _key5 < _len5; _key5++) {
      rest[_key5 - 1] = arguments[_key5];
    }

    return currentLogLevelNumber <= levels.error && console.error.apply(console, [message].concat(rest));
  },
  log: function log(message) {
    for (var _len6 = arguments.length, rest = new Array(_len6 > 1 ? _len6 - 1 : 0), _key6 = 1; _key6 < _len6; _key6++) {
      rest[_key6 - 1] = arguments[_key6];
    }

    return currentLogLevelNumber < levels.silent && console.log.apply(console, [message].concat(rest));
  }
};
var logged = new Set();
export var once = function once(type) {
  return function (message) {
    if (logged.has(message)) return undefined;
    logged.add(message);

    for (var _len7 = arguments.length, rest = new Array(_len7 > 1 ? _len7 - 1 : 0), _key7 = 1; _key7 < _len7; _key7++) {
      rest[_key7 - 1] = arguments[_key7];
    }

    return logger[type].apply(logger, [message].concat(rest));
  };
};

once.clear = function () {
  return logged.clear();
};

once.trace = once('trace');
once.debug = once('debug');
once.info = once('info');
once.warn = once('warn');
once.error = once('error');
once.log = once('log');
export var pretty = function pretty(type) {
  return function () {
    var argArray = [];

    for (var _len8 = arguments.length, args = new Array(_len8), _key8 = 0; _key8 < _len8; _key8++) {
      args[_key8] = arguments[_key8];
    }

    if (args.length) {
      var startTagRe = /<span\s+style=(['"])([^'"]*)\1\s*>/gi;
      var endTagRe = /<\/span>/gi;
      var reResultArray;
      argArray.push(args[0].replace(startTagRe, '%c').replace(endTagRe, '%c')); // eslint-disable-next-line no-cond-assign

      while (reResultArray = startTagRe.exec(args[0])) {
        argArray.push(reResultArray[2]);
        argArray.push('');
      } // pass through subsequent args since chrome dev tools does not (yet) support console.log styling of the following form: console.log('%cBlue!', 'color: blue;', '%cRed!', 'color: red;');
      // eslint-disable-next-line no-plusplus


      for (var j = 1; j < args.length; j++) {
        argArray.push(args[j]);
      }
    } // eslint-disable-next-line prefer-spread


    logger[type].apply(logger, argArray);
  };
};
pretty.trace = pretty('trace');
pretty.debug = pretty('debug');
pretty.info = pretty('info');
pretty.warn = pretty('warn');
pretty.error = pretty('error');