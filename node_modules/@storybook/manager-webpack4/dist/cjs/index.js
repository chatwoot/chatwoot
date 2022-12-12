"use strict";

function _typeof(obj) { "@babel/helpers - typeof"; return _typeof = "function" == typeof Symbol && "symbol" == typeof Symbol.iterator ? function (obj) { return typeof obj; } : function (obj) { return obj && "function" == typeof Symbol && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; }, _typeof(obj); }

require("core-js/modules/es.symbol.iterator.js");

require("core-js/modules/es.array.slice.js");

require("core-js/modules/es.array.from.js");

require("core-js/modules/es.regexp.exec.js");

require("core-js/modules/es.weak-map.js");

require("core-js/modules/es.object.get-own-property-descriptor.js");

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.start = exports.overridePresets = exports.makeStatsFromError = exports.getConfig = exports.executor = exports.corePresets = exports.build = exports.bail = exports.WEBPACK_VERSION = void 0;

require("regenerator-runtime/runtime.js");

require("core-js/modules/es.object.to-string.js");

require("core-js/modules/es.promise.js");

require("core-js/modules/es.symbol.js");

require("core-js/modules/es.symbol.description.js");

require("core-js/modules/es.symbol.async-iterator.js");

require("core-js/modules/es.array.iterator.js");

require("core-js/modules/es.string.iterator.js");

require("core-js/modules/web.dom-collections.iterator.js");

require("core-js/modules/es.function.name.js");

require("core-js/modules/web.dom-collections.for-each.js");

require("core-js/modules/es.object.assign.js");

var _webpack = _interopRequireWildcard(require("webpack"));

var _webpackDevMiddleware = _interopRequireDefault(require("webpack-dev-middleware"));

var _nodeLogger = require("@storybook/node-logger");

var _coreCommon = require("@storybook/core-common");

var _findUp = _interopRequireDefault(require("find-up"));

var _fsExtra = _interopRequireDefault(require("fs-extra"));

var _express = _interopRequireDefault(require("express"));

var _managerConfig = require("./manager-config");

var _managerCache = require("./utils/manager-cache");

var _prebuiltManager = require("./utils/prebuilt-manager");

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _getRequireWildcardCache(nodeInterop) { if (typeof WeakMap !== "function") return null; var cacheBabelInterop = new WeakMap(); var cacheNodeInterop = new WeakMap(); return (_getRequireWildcardCache = function _getRequireWildcardCache(nodeInterop) { return nodeInterop ? cacheNodeInterop : cacheBabelInterop; })(nodeInterop); }

function _interopRequireWildcard(obj, nodeInterop) { if (!nodeInterop && obj && obj.__esModule) { return obj; } if (obj === null || _typeof(obj) !== "object" && typeof obj !== "function") { return { default: obj }; } var cache = _getRequireWildcardCache(nodeInterop); if (cache && cache.has(obj)) { return cache.get(obj); } var newObj = {}; var hasPropertyDescriptor = Object.defineProperty && Object.getOwnPropertyDescriptor; for (var key in obj) { if (key !== "default" && Object.prototype.hasOwnProperty.call(obj, key)) { var desc = hasPropertyDescriptor ? Object.getOwnPropertyDescriptor(obj, key) : null; if (desc && (desc.get || desc.set)) { Object.defineProperty(newObj, key, desc); } else { newObj[key] = obj[key]; } } } newObj.default = obj; if (cache) { cache.set(obj, newObj); } return newObj; }

function _slicedToArray(arr, i) { return _arrayWithHoles(arr) || _iterableToArrayLimit(arr, i) || _unsupportedIterableToArray(arr, i) || _nonIterableRest(); }

function _nonIterableRest() { throw new TypeError("Invalid attempt to destructure non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen); }

function _arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

function _iterableToArrayLimit(arr, i) { var _i = arr == null ? null : typeof Symbol !== "undefined" && arr[Symbol.iterator] || arr["@@iterator"]; if (_i == null) return; var _arr = []; var _n = true; var _d = false; var _s, _e; try { for (_i = _i.call(arr); !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"] != null) _i["return"](); } finally { if (_d) throw _e; } } return _arr; }

function _arrayWithHoles(arr) { if (Array.isArray(arr)) return arr; }

function asyncGeneratorStep(gen, resolve, reject, _next, _throw, key, arg) { try { var info = gen[key](arg); var value = info.value; } catch (error) { reject(error); return; } if (info.done) { resolve(value); } else { Promise.resolve(value).then(_next, _throw); } }

function _asyncToGenerator(fn) { return function () { var self = this, args = arguments; return new Promise(function (resolve, reject) { var gen = fn.apply(self, args); function _next(value) { asyncGeneratorStep(gen, resolve, reject, _next, _throw, "next", value); } function _throw(err) { asyncGeneratorStep(gen, resolve, reject, _next, _throw, "throw", err); } _next(undefined); }); }; }

function _awaitAsyncGenerator(value) { return new _AwaitValue(value); }

function _wrapAsyncGenerator(fn) { return function () { return new _AsyncGenerator(fn.apply(this, arguments)); }; }

function _AsyncGenerator(gen) { var front, back; function send(key, arg) { return new Promise(function (resolve, reject) { var request = { key: key, arg: arg, resolve: resolve, reject: reject, next: null }; if (back) { back = back.next = request; } else { front = back = request; resume(key, arg); } }); } function resume(key, arg) { try { var result = gen[key](arg); var value = result.value; var wrappedAwait = value instanceof _AwaitValue; Promise.resolve(wrappedAwait ? value.wrapped : value).then(function (arg) { if (wrappedAwait) { resume(key === "return" ? "return" : "next", arg); return; } settle(result.done ? "return" : "normal", arg); }, function (err) { resume("throw", err); }); } catch (err) { settle("throw", err); } } function settle(type, value) { switch (type) { case "return": front.resolve({ value: value, done: true }); break; case "throw": front.reject(value); break; default: front.resolve({ value: value, done: false }); break; } front = front.next; if (front) { resume(front.key, front.arg); } else { back = null; } } this._invoke = send; if (typeof gen.return !== "function") { this.return = undefined; } }

_AsyncGenerator.prototype[typeof Symbol === "function" && Symbol.asyncIterator || "@@asyncIterator"] = function () { return this; };

_AsyncGenerator.prototype.next = function (arg) { return this._invoke("next", arg); };

_AsyncGenerator.prototype.throw = function (arg) { return this._invoke("throw", arg); };

_AsyncGenerator.prototype.return = function (arg) { return this._invoke("return", arg); };

function _AwaitValue(value) { this.wrapped = value; }

var compilation;
var reject;
var WEBPACK_VERSION = '4';
exports.WEBPACK_VERSION = WEBPACK_VERSION;
var getConfig = _managerConfig.getManagerWebpackConfig;
exports.getConfig = getConfig;

var makeStatsFromError = function makeStatsFromError(err) {
  return {
    hasErrors: function hasErrors() {
      return true;
    },
    hasWarnings: function hasWarnings() {
      return false;
    },
    toJson: function toJson() {
      return {
        warnings: [],
        errors: [err]
      };
    }
  };
};

exports.makeStatsFromError = makeStatsFromError;
var executor = {
  get: function () {
    var _get = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee(options) {
      var _yield$options$preset;

      var version, webpackInstance;
      return regeneratorRuntime.wrap(function _callee$(_context) {
        while (1) {
          switch (_context.prev = _context.next) {
            case 0:
              _context.next = 2;
              return options.presets.apply('webpackVersion');

            case 2:
              _context.t0 = _context.sent;

              if (_context.t0) {
                _context.next = 5;
                break;
              }

              _context.t0 = WEBPACK_VERSION;

            case 5:
              version = _context.t0;
              _context.next = 8;
              return options.presets.apply('webpackInstance');

            case 8:
              _context.t3 = _yield$options$preset = _context.sent;
              _context.t2 = _context.t3 === null;

              if (_context.t2) {
                _context.next = 12;
                break;
              }

              _context.t2 = _yield$options$preset === void 0;

            case 12:
              if (!_context.t2) {
                _context.next = 16;
                break;
              }

              _context.t4 = void 0;
              _context.next = 17;
              break;

            case 16:
              _context.t4 = _yield$options$preset.default;

            case 17:
              _context.t1 = _context.t4;

              if (_context.t1) {
                _context.next = 20;
                break;
              }

              _context.t1 = _webpack.default;

            case 20:
              webpackInstance = _context.t1;
              (0, _coreCommon.checkWebpackVersion)({
                version: version
              }, WEBPACK_VERSION, "manager-webpack".concat(WEBPACK_VERSION));
              return _context.abrupt("return", webpackInstance);

            case 23:
            case "end":
              return _context.stop();
          }
        }
      }, _callee);
    }));

    function get(_x3) {
      return _get.apply(this, arguments);
    }

    return get;
  }()
};
exports.executor = executor;
var asyncIterator;

var bail = /*#__PURE__*/function () {
  var _ref = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee2() {
    return regeneratorRuntime.wrap(function _callee2$(_context2) {
      while (1) {
        switch (_context2.prev = _context2.next) {
          case 0:
            if (!asyncIterator) {
              _context2.next = 8;
              break;
            }

            _context2.prev = 1;
            _context2.next = 4;
            return asyncIterator.throw(new Error());

          case 4:
            _context2.next = 8;
            break;

          case 6:
            _context2.prev = 6;
            _context2.t0 = _context2["catch"](1);

          case 8:
            if (reject) {
              reject();
            } // we wait for the compiler to finish it's work, so it's command-line output doesn't interfere


            return _context2.abrupt("return", new Promise(function (res, rej) {
              if (process && compilation) {
                try {
                  compilation.close(function () {
                    return res();
                  });

                  _nodeLogger.logger.warn('Force closed manager build');
                } catch (err) {
                  _nodeLogger.logger.warn('Unable to close manager build!');

                  res();
                }
              } else {
                res();
              }
            }));

          case 10:
          case "end":
            return _context2.stop();
        }
      }
    }, _callee2, null, [[1, 6]]);
  }));

  return function bail() {
    return _ref.apply(this, arguments);
  };
}();
/**
 * This function is a generator so that we can abort it mid process
 * in case of failure coming from other processes e.g. preview builder
 *
 * I am sorry for making you read about generators today :')
 */


exports.bail = bail;

var starter = /*#__PURE__*/function () {
  var _starterGeneratorFn = _wrapAsyncGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee3(_ref2) {
    var _config$output;

    var startTime, options, router, prebuiltDir, config, packageFile, _yield$_awaitAsyncGen, storybookVersion, cacheKey, _yield$_awaitAsyncGen2, _yield$_awaitAsyncGen3, useCache, hasOutput, webpackInstance, compiler, err, _yield$_awaitAsyncGen4, handler, modulesCount, middlewareOptions, stats;

    return regeneratorRuntime.wrap(function _callee3$(_context3) {
      while (1) {
        switch (_context3.prev = _context3.next) {
          case 0:
            startTime = _ref2.startTime, options = _ref2.options, router = _ref2.router;
            _context3.next = 3;
            return _awaitAsyncGenerator((0, _prebuiltManager.getPrebuiltDir)(options));

          case 3:
            prebuiltDir = _context3.sent;

            if (!(prebuiltDir && options.managerCache && !options.smokeTest)) {
              _context3.next = 8;
              break;
            }

            _nodeLogger.logger.info('=> Using prebuilt manager');

            router.use('/', _express.default.static(prebuiltDir));
            return _context3.abrupt("return");

          case 8:
            _context3.next = 10;
            return;

          case 10:
            _context3.next = 12;
            return _awaitAsyncGenerator(getConfig(options));

          case 12:
            config = _context3.sent;
            _context3.next = 15;
            return;

          case 15:
            if (!options.cache) {
              _context3.next = 54;
              break;
            }

            _context3.next = 18;
            return _awaitAsyncGenerator((0, _findUp.default)('package.json', {
              cwd: __dirname
            }));

          case 18:
            packageFile = _context3.sent;
            _context3.next = 21;
            return;

          case 21:
            _context3.next = 23;
            return _awaitAsyncGenerator(_fsExtra.default.readJSON(packageFile));

          case 23:
            _yield$_awaitAsyncGen = _context3.sent;
            storybookVersion = _yield$_awaitAsyncGen.version;
            _context3.next = 27;
            return;

          case 27:
            cacheKey = "managerConfig-webpack".concat(WEBPACK_VERSION, "@").concat(storybookVersion);

            if (!options.managerCache) {
              _context3.next = 44;
              break;
            }

            _context3.next = 31;
            return _awaitAsyncGenerator(Promise.all([// useManagerCache sets the cache, so it must run even if outputDir doesn't exist yet,
            // otherwise the 2nd run won't be able to use the manager built on the 1st run.
            (0, _managerCache.useManagerCache)(cacheKey, options, config), _fsExtra.default.pathExists(options.outputDir)]));

          case 31:
            _yield$_awaitAsyncGen2 = _context3.sent;
            _yield$_awaitAsyncGen3 = _slicedToArray(_yield$_awaitAsyncGen2, 2);
            useCache = _yield$_awaitAsyncGen3[0];
            hasOutput = _yield$_awaitAsyncGen3[1];
            _context3.next = 37;
            return;

          case 37:
            if (!(useCache && hasOutput && !options.smokeTest)) {
              _context3.next = 42;
              break;
            }

            _nodeLogger.logger.line(1); // force starting new line


            _nodeLogger.logger.info('=> Using cached manager');

            router.use('/', _express.default.static(options.outputDir));
            return _context3.abrupt("return");

          case 42:
            _context3.next = 54;
            break;

          case 44:
            _context3.t0 = !options.smokeTest;

            if (!_context3.t0) {
              _context3.next = 49;
              break;
            }

            _context3.next = 48;
            return _awaitAsyncGenerator((0, _managerCache.clearManagerCache)(cacheKey, options));

          case 48:
            _context3.t0 = _context3.sent;

          case 49:
            if (!_context3.t0) {
              _context3.next = 54;
              break;
            }

            _context3.next = 52;
            return;

          case 52:
            _nodeLogger.logger.line(1); // force starting new line


            _nodeLogger.logger.info('=> Cleared cached manager config');

          case 54:
            _context3.next = 56;
            return _awaitAsyncGenerator(executor.get(options));

          case 56:
            webpackInstance = _context3.sent;
            _context3.next = 59;
            return;

          case 59:
            compiler = webpackInstance(config);

            if (compiler) {
              _context3.next = 64;
              break;
            }

            err = "".concat(config.name, ": missing webpack compiler at runtime!");

            _nodeLogger.logger.error(err); // eslint-disable-next-line consistent-return


            return _context3.abrupt("return", {
              bail: bail,
              totalTime: process.hrtime(startTime),
              stats: makeStatsFromError(err)
            });

          case 64:
            _context3.next = 66;
            return _awaitAsyncGenerator((0, _coreCommon.useProgressReporting)(router, startTime, options));

          case 66:
            _yield$_awaitAsyncGen4 = _context3.sent;
            handler = _yield$_awaitAsyncGen4.handler;
            modulesCount = _yield$_awaitAsyncGen4.modulesCount;
            _context3.next = 71;
            return;

          case 71:
            new _webpack.ProgressPlugin({
              handler: handler,
              modulesCount: modulesCount
            }).apply(compiler);
            middlewareOptions = {
              publicPath: (_config$output = config.output) === null || _config$output === void 0 ? void 0 : _config$output.publicPath,
              writeToDisk: true,
              watchOptions: config.watchOptions || {}
            };
            compilation = (0, _webpackDevMiddleware.default)(compiler, middlewareOptions);
            router.use(compilation);
            _context3.next = 77;
            return _awaitAsyncGenerator(new Promise(function (ready, stop) {
              compilation.waitUntilValid(ready);
              reject = stop;
            }));

          case 77:
            stats = _context3.sent;
            _context3.next = 80;
            return;

          case 80:
            if (stats) {
              _context3.next = 82;
              break;
            }

            throw new Error('no stats after building manager');

          case 82:
            return _context3.abrupt("return", {
              bail: bail,
              stats: stats,
              totalTime: process.hrtime(startTime)
            });

          case 83:
          case "end":
            return _context3.stop();
        }
      }
    }, _callee3);
  }));

  function starterGeneratorFn(_x) {
    return _starterGeneratorFn.apply(this, arguments);
  }

  return starterGeneratorFn;
}();

var start = /*#__PURE__*/function () {
  var _ref3 = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee4(options) {
    var result;
    return regeneratorRuntime.wrap(function _callee4$(_context4) {
      while (1) {
        switch (_context4.prev = _context4.next) {
          case 0:
            asyncIterator = starter(options);

          case 1:
            _context4.next = 3;
            return asyncIterator.next();

          case 3:
            result = _context4.sent;

          case 4:
            if (!result.done) {
              _context4.next = 1;
              break;
            }

          case 5:
            return _context4.abrupt("return", result.value);

          case 6:
          case "end":
            return _context4.stop();
        }
      }
    }, _callee4);
  }));

  return function start(_x4) {
    return _ref3.apply(this, arguments);
  };
}();
/**
 * This function is a generator so that we can abort it mid process
 * in case of failure coming from other processes e.g. preview builder
 *
 * I am sorry for making you read about generators today :')
 */


exports.start = start;

var builder = /*#__PURE__*/function () {
  var _builderGeneratorFn = _wrapAsyncGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee5(_ref4) {
    var startTime, options, webpackInstance, config, statsOptions, compiler, err;
    return regeneratorRuntime.wrap(function _callee5$(_context5) {
      while (1) {
        switch (_context5.prev = _context5.next) {
          case 0:
            startTime = _ref4.startTime, options = _ref4.options;

            _nodeLogger.logger.info('=> Compiling manager..');

            _context5.next = 4;
            return _awaitAsyncGenerator(executor.get(options));

          case 4:
            webpackInstance = _context5.sent;
            _context5.next = 7;
            return;

          case 7:
            _context5.next = 9;
            return _awaitAsyncGenerator(getConfig(options));

          case 9:
            config = _context5.sent;
            _context5.next = 12;
            return;

          case 12:
            statsOptions = typeof config.stats === 'boolean' ? 'minimal' : config.stats;
            compiler = webpackInstance(config);

            if (compiler) {
              _context5.next = 18;
              break;
            }

            err = "".concat(config.name, ": missing webpack compiler at runtime!");

            _nodeLogger.logger.error(err);

            return _context5.abrupt("return", Promise.resolve(makeStatsFromError(err)));

          case 18:
            _context5.next = 20;
            return;

          case 20:
            return _context5.abrupt("return", new Promise(function (succeed, fail) {
              compiler.run(function (error, stats) {
                if (error || !stats || stats.hasErrors()) {
                  _nodeLogger.logger.error('=> Failed to build the manager');

                  if (error) {
                    _nodeLogger.logger.error(error.message);
                  }

                  if (stats && (stats.hasErrors() || stats.hasWarnings())) {
                    var _stats$toJson = stats.toJson(statsOptions),
                        warnings = _stats$toJson.warnings,
                        errors = _stats$toJson.errors;

                    errors.forEach(function (e) {
                      return _nodeLogger.logger.error(e);
                    });
                    warnings.forEach(function (e) {
                      return _nodeLogger.logger.error(e);
                    });
                  }

                  process.exitCode = 1;
                  fail(error || stats);
                } else {
                  var _statsData$warnings;

                  _nodeLogger.logger.trace({
                    message: '=> Manager built',
                    time: process.hrtime(startTime)
                  });

                  var statsData = stats.toJson(typeof statsOptions === 'string' ? statsOptions : Object.assign({}, statsOptions, {
                    warnings: true
                  }));
                  statsData === null || statsData === void 0 ? void 0 : (_statsData$warnings = statsData.warnings) === null || _statsData$warnings === void 0 ? void 0 : _statsData$warnings.forEach(function (e) {
                    return _nodeLogger.logger.warn(e);
                  });
                  succeed(stats);
                }
              });
            }));

          case 21:
          case "end":
            return _context5.stop();
        }
      }
    }, _callee5);
  }));

  function builderGeneratorFn(_x2) {
    return _builderGeneratorFn.apply(this, arguments);
  }

  return builderGeneratorFn;
}();

var build = /*#__PURE__*/function () {
  var _ref5 = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee6(options) {
    var result;
    return regeneratorRuntime.wrap(function _callee6$(_context6) {
      while (1) {
        switch (_context6.prev = _context6.next) {
          case 0:
            asyncIterator = builder(options);

          case 1:
            _context6.next = 3;
            return asyncIterator.next();

          case 3:
            result = _context6.sent;

          case 4:
            if (!result.done) {
              _context6.next = 1;
              break;
            }

          case 5:
            return _context6.abrupt("return", result.value);

          case 6:
          case "end":
            return _context6.stop();
        }
      }
    }, _callee6);
  }));

  return function build(_x5) {
    return _ref5.apply(this, arguments);
  };
}();

exports.build = build;
var corePresets = [require.resolve('./presets/manager-preset')];
exports.corePresets = corePresets;
var overridePresets = [];
exports.overridePresets = overridePresets;