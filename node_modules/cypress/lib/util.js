"use strict";

function _templateObject2() {
  var data = _taggedTemplateLiteral(["\n        Platform: ", " (", ")\n        Cypress Version: ", "\n      "]);

  _templateObject2 = function _templateObject2() {
    return data;
  };

  return data;
}

function _toConsumableArray(arr) { return _arrayWithoutHoles(arr) || _iterableToArray(arr) || _unsupportedIterableToArray(arr) || _nonIterableSpread(); }

function _nonIterableSpread() { throw new TypeError("Invalid attempt to spread non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen); }

function _iterableToArray(iter) { if (typeof Symbol !== "undefined" && Symbol.iterator in Object(iter)) return Array.from(iter); }

function _arrayWithoutHoles(arr) { if (Array.isArray(arr)) return _arrayLikeToArray(arr); }

function _arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

function _templateObject() {
  var data = _taggedTemplateLiteral(["\n\n    ", " Warning: Cypress failed to start.\n\n    This is likely due to a misconfigured DISPLAY environment variable.\n\n    DISPLAY was set to: \"", "\"\n\n    Cypress will attempt to fix the problem and rerun.\n  "]);

  _templateObject = function _templateObject() {
    return data;
  };

  return data;
}

function _taggedTemplateLiteral(strings, raw) { if (!raw) { raw = strings.slice(0); } return Object.freeze(Object.defineProperties(strings, { raw: { value: Object.freeze(raw) } })); }

var _ = require('lodash');

var R = require('ramda');

var os = require('os');

var ospath = require('ospath');

var crypto = require('crypto');

var la = require('lazy-ass');

var is = require('check-more-types');

var tty = require('tty');

var path = require('path');

var _isCi = require('is-ci');

var execa = require('execa');

var getos = require('getos');

var chalk = require('chalk');

var Promise = require('bluebird');

var cachedir = require('cachedir');

var logSymbols = require('log-symbols');

var executable = require('executable');

var _require = require('common-tags'),
    stripIndent = _require.stripIndent;

var _supportsColor = require('supports-color');

var _isInstalledGlobally = require('is-installed-globally');

var pkg = require(path.join(__dirname, '..', 'package.json'));

var logger = require('./logger');

var debug = require('debug')('cypress:cli');

var fs = require('./fs');

var issuesUrl = 'https://github.com/cypress-io/cypress/issues';
var getosAsync = Promise.promisify(getos);
/**
 * Returns SHA512 of a file
 *
 * Implementation lifted from https://github.com/sindresorhus/hasha
 * but without bringing that dependency (since hasha is Node v8+)
 */

var getFileChecksum = function getFileChecksum(filename) {
  la(is.unemptyString(filename), 'expected filename', filename);

  var hashStream = function hashStream() {
    var s = crypto.createHash('sha512');
    s.setEncoding('hex');
    return s;
  };

  return new Promise(function (resolve, reject) {
    var stream = fs.createReadStream(filename);
    stream.on('error', reject).pipe(hashStream()).on('error', reject).on('finish', function () {
      resolve(this.read());
    });
  });
};

var getFileSize = function getFileSize(filename) {
  la(is.unemptyString(filename), 'expected filename', filename);
  return fs.statAsync(filename).get('size');
};

var isBrokenGtkDisplayRe = /Gtk: cannot open display/;

var stringify = function stringify(val) {
  return _.isObject(val) ? JSON.stringify(val) : val;
};

function normalizeModuleOptions() {
  var options = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : {};
  return _.mapValues(options, stringify);
}
/**
 * Returns true if the platform is Linux. We do a lot of different
 * stuff on Linux (like Xvfb) and it helps to has readable code
 */


var isLinux = function isLinux() {
  return os.platform() === 'linux';
};
/**
   * If the DISPLAY variable is set incorrectly, when trying to spawn
   * Cypress executable we get an error like this:
  ```
  [1005:0509/184205.663837:WARNING:browser_main_loop.cc(258)] Gtk: cannot open display: 99
  ```
   */


var isBrokenGtkDisplay = function isBrokenGtkDisplay(str) {
  return isBrokenGtkDisplayRe.test(str);
};

var isPossibleLinuxWithIncorrectDisplay = function isPossibleLinuxWithIncorrectDisplay() {
  return isLinux() && process.env.DISPLAY;
};

var logBrokenGtkDisplayWarning = function logBrokenGtkDisplayWarning() {
  debug('Cypress exited due to a broken gtk display because of a potential invalid DISPLAY env... retrying after starting Xvfb'); // if we get this error, we are on Linux and DISPLAY is set

  logger.warn(stripIndent(_templateObject(), logSymbols.warning, process.env.DISPLAY));
  logger.warn();
};

function stdoutLineMatches(expectedLine, stdout) {
  var lines = stdout.split('\n').map(R.trim);
  var lineMatches = R.equals(expectedLine);
  return lines.some(lineMatches);
}
/**
 * Confirms if given value is a valid CYPRESS_INTERNAL_ENV value. Undefined values
 * are valid, because the system can set the default one.
 *
 * @param {string} value
 * @example util.isValidCypressInternalEnvValue(process.env.CYPRESS_INTERNAL_ENV)
 */


function isValidCypressInternalEnvValue(value) {
  if (_.isUndefined(value)) {
    // will get default value
    return true;
  } // names of config environments, see "packages/server/config/app.yml"


  var names = ['development', 'test', 'staging', 'production'];
  return _.includes(names, value);
}
/**
 * Confirms if given value is a non-production CYPRESS_INTERNAL_ENV value.
 * Undefined values are valid, because the system can set the default one.
 *
 * @param {string} value
 * @example util.isNonProductionCypressInternalEnvValue(process.env.CYPRESS_INTERNAL_ENV)
 */


function isNonProductionCypressInternalEnvValue(value) {
  return !_.isUndefined(value) && value !== 'production';
}
/**
 * Prints NODE_OPTIONS using debug() module, but only
 * if DEBUG=cypress... is set
 */


function printNodeOptions() {
  var log = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : debug;

  if (!log.enabled) {
    return;
  }

  if (process.env.NODE_OPTIONS) {
    log('NODE_OPTIONS=%s', process.env.NODE_OPTIONS);
  } else {
    log('NODE_OPTIONS is not set');
  }
}
/**
 * Removes double quote characters
 * from the start and end of the given string IF they are both present
 *
 * @param {string} str Input string
 * @returns {string} Trimmed string or the original string if there are no double quotes around it.
 * @example
  ```
  dequote('"foo"')
  // returns string 'foo'
  dequote('foo')
  // returns string 'foo'
  ```
 */


var dequote = function dequote(str) {
  la(is.string(str), 'expected a string to remove double quotes', str);

  if (str.length > 1 && str[0] === '"' && str[str.length - 1] === '"') {
    return str.substr(1, str.length - 2);
  }

  return str;
};

var parseOpts = function parseOpts(opts) {
  opts = _.pick(opts, 'browser', 'cachePath', 'cacheList', 'cacheClear', 'ciBuildId', 'config', 'configFile', 'cypressVersion', 'destination', 'detached', 'dev', 'exit', 'env', 'force', 'global', 'group', 'headed', 'headless', 'key', 'path', 'parallel', 'port', 'project', 'quiet', 'reporter', 'reporterOptions', 'record', 'spec', 'tag');

  if (opts.exit) {
    opts = _.omit(opts, 'exit');
  } // some options might be quoted - which leads to unexpected results
  // remove double quotes from certain options


  var removeQuotes = {
    group: dequote,
    ciBuildId: dequote
  };
  var cleanOpts = R.evolve(removeQuotes, opts);
  debug('parsed cli options %o', cleanOpts);
  return cleanOpts;
};
/**
 * Copy of packages/server/lib/browsers/utils.ts
 * because we need same functionality in CLI to show the path :(
 */


var getApplicationDataFolder = function getApplicationDataFolder() {
  var _process = process,
      env = _process.env; // allow overriding the app_data folder

  var folder = env.CYPRESS_KONFIG_ENV || env.CYPRESS_INTERNAL_ENV || 'development';
  var PRODUCT_NAME = pkg.productName || pkg.name;
  var OS_DATA_PATH = ospath.data();
  var ELECTRON_APP_DATA_PATH = path.join(OS_DATA_PATH, PRODUCT_NAME);

  for (var _len = arguments.length, paths = new Array(_len), _key = 0; _key < _len; _key++) {
    paths[_key] = arguments[_key];
  }

  var p = path.join.apply(path, [ELECTRON_APP_DATA_PATH, 'cy', folder].concat(paths));
  return p;
};

var util = {
  normalizeModuleOptions: normalizeModuleOptions,
  parseOpts: parseOpts,
  isValidCypressInternalEnvValue: isValidCypressInternalEnvValue,
  isNonProductionCypressInternalEnvValue: isNonProductionCypressInternalEnvValue,
  printNodeOptions: printNodeOptions,
  isCi: function isCi() {
    return _isCi;
  },
  getEnvOverrides: function getEnvOverrides() {
    var options = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : {};
    return _.chain({}).extend(util.getEnvColors()).extend(util.getForceTty()).omitBy(_.isUndefined) // remove undefined values
    .mapValues(function (value) {
      // stringify to 1 or 0
      return value ? '1' : '0';
    }).extend(util.getNodeOptions(options)).value();
  },
  getNodeOptions: function getNodeOptions(options, nodeVersion) {
    if (!nodeVersion) {
      nodeVersion = Number(process.versions.node.split('.')[0]);
    }

    if (options.dev && nodeVersion < 12) {
      // `node` is used instead of Electron when --dev is passed, so this won't work if Node is too old
      debug('NODE_OPTIONS=--max-http-header-size could not be set because we\'re in dev mode and Node is < 12.0.0');
      return;
    } // https://github.com/cypress-io/cypress/issues/5431


    var NODE_OPTIONS = "--max-http-header-size=".concat(Math.pow(1024, 2), " --http-parser=legacy");

    if (_.isString(process.env.NODE_OPTIONS)) {
      return {
        NODE_OPTIONS: "".concat(NODE_OPTIONS, " ").concat(process.env.NODE_OPTIONS),
        ORIGINAL_NODE_OPTIONS: process.env.NODE_OPTIONS || ''
      };
    }

    return {
      NODE_OPTIONS: NODE_OPTIONS
    };
  },
  getForceTty: function getForceTty() {
    return {
      FORCE_STDIN_TTY: util.isTty(process.stdin.fd),
      FORCE_STDOUT_TTY: util.isTty(process.stdout.fd),
      FORCE_STDERR_TTY: util.isTty(process.stderr.fd)
    };
  },
  getEnvColors: function getEnvColors() {
    var sc = util.supportsColor();
    return {
      FORCE_COLOR: sc,
      DEBUG_COLORS: sc,
      MOCHA_COLORS: sc ? true : undefined
    };
  },
  isTty: function isTty(fd) {
    return tty.isatty(fd);
  },
  supportsColor: function supportsColor() {
    // if we've been explictly told not to support
    // color then turn this off
    if (process.env.NO_COLOR) {
      return false;
    } // https://github.com/cypress-io/cypress/issues/1747
    // always return true in CI providers


    if (process.env.CI) {
      return true;
    } // ensure that both stdout and stderr support color


    return Boolean(_supportsColor.stdout) && Boolean(_supportsColor.stderr);
  },
  cwd: function cwd() {
    return process.cwd();
  },
  pkgVersion: function pkgVersion() {
    return pkg.version;
  },
  exit: function exit(code) {
    process.exit(code);
  },
  logErrorExit1: function logErrorExit1(err) {
    logger.error(err.message);
    process.exit(1);
  },
  dequote: dequote,
  titleize: function titleize() {
    for (var _len2 = arguments.length, args = new Array(_len2), _key2 = 0; _key2 < _len2; _key2++) {
      args[_key2] = arguments[_key2];
    }

    // prepend first arg with space
    // and pad so that all messages line up
    args[0] = _.padEnd(" ".concat(args[0]), 24); // get rid of any falsy values

    args = _.compact(args);
    return chalk.blue.apply(chalk, _toConsumableArray(args));
  },
  calculateEta: function calculateEta(percent, elapsed) {
    // returns the number of seconds remaining
    // if we're at 100% already just return 0
    if (percent === 100) {
      return 0;
    } // take the percentage and divide by one
    // and multiple that against elapsed
    // subtracting what's already elapsed


    return elapsed * (1 / (percent / 100)) - elapsed;
  },
  convertPercentToPercentage: function convertPercentToPercentage(num) {
    // convert a percent with values between 0 and 1
    // with decimals, so that it is between 0 and 100
    // and has no decimal places
    return Math.round(_.isFinite(num) ? num * 100 : 0);
  },
  secsRemaining: function secsRemaining(eta) {
    // calculate the seconds reminaing with no decimal places
    return (_.isFinite(eta) ? eta / 1000 : 0).toFixed(0);
  },
  setTaskTitle: function setTaskTitle(task, title, renderer) {
    // only update the renderer title when not running in CI
    if (renderer === 'default' && task.title !== title) {
      task.title = title;
    }
  },
  isInstalledGlobally: function isInstalledGlobally() {
    return _isInstalledGlobally;
  },
  isSemver: function isSemver(str) {
    return /^(\d+\.)?(\d+\.)?(\*|\d+)$/.test(str);
  },
  isExecutableAsync: function isExecutableAsync(filePath) {
    return Promise.resolve(executable(filePath));
  },
  isLinux: isLinux,
  getOsVersionAsync: function getOsVersionAsync() {
    return Promise["try"](function () {
      if (isLinux()) {
        return getosAsync().then(function (osInfo) {
          return [osInfo.dist, osInfo.release].join(' - ');
        })["catch"](function () {
          return os.release();
        });
      }

      return os.release();
    });
  },
  getPlatformInfo: function getPlatformInfo() {
    return util.getOsVersionAsync().then(function (version) {
      return stripIndent(_templateObject2(), os.platform(), version, util.pkgVersion());
    });
  },
  // attention:
  // when passing relative path to NPM post install hook, the current working
  // directory is set to the `node_modules/cypress` folder
  // the user is probably passing relative path with respect to root package folder
  formAbsolutePath: function formAbsolutePath(filename) {
    if (path.isAbsolute(filename)) {
      return filename;
    }

    return path.join(process.cwd(), '..', '..', filename);
  },
  getEnv: function getEnv(varName, trim) {
    la(is.unemptyString(varName), 'expected environment variable name, not', varName);
    var envVar = process.env[varName];
    var configVar = process.env["npm_config_".concat(varName)];
    var packageConfigVar = process.env["npm_package_config_".concat(varName)];
    var result;

    if (envVar) {
      debug("Using ".concat(varName, " from environment variable"));
      result = envVar;
    } else if (configVar) {
      debug("Using ".concat(varName, " from npm config"));
      result = configVar;
    } else if (packageConfigVar) {
      debug("Using ".concat(varName, " from package.json config"));
      result = packageConfigVar;
    } // environment variables are often set double quotes to escape characters
    // and on Windows it can lead to weird things: for example
    //  set FOO="C:\foo.txt" && node -e "console.log('>>>%s<<<', process.env.FOO)"
    // will print
    //    >>>"C:\foo.txt" <<<
    // see https://github.com/cypress-io/cypress/issues/4506#issuecomment-506029942
    // so for sanity sake we should first trim whitespace characters and remove
    // double quotes around environment strings if the caller is expected to
    // use this environment string as a file path


    return trim ? dequote(_.trim(result)) : result;
  },
  getCacheDir: function getCacheDir() {
    return cachedir('Cypress');
  },
  isPostInstall: function isPostInstall() {
    return process.env.npm_lifecycle_event === 'postinstall';
  },
  exec: execa,
  stdoutLineMatches: stdoutLineMatches,
  issuesUrl: issuesUrl,
  isBrokenGtkDisplay: isBrokenGtkDisplay,
  logBrokenGtkDisplayWarning: logBrokenGtkDisplayWarning,
  isPossibleLinuxWithIncorrectDisplay: isPossibleLinuxWithIncorrectDisplay,
  getGitHubIssueUrl: function getGitHubIssueUrl(number) {
    la(is.positive(number), 'github issue should be a positive number', number);
    la(_.isInteger(number), 'github issue should be an integer', number);
    return "".concat(issuesUrl, "/").concat(number);
  },
  getFileChecksum: getFileChecksum,
  getFileSize: getFileSize,
  getApplicationDataFolder: getApplicationDataFolder
};
module.exports = util;