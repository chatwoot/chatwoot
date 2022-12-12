import "core-js/modules/es.symbol.js";
import "core-js/modules/es.symbol.description.js";
import "core-js/modules/es.symbol.iterator.js";
import "core-js/modules/es.function.name.js";
import "core-js/modules/es.array.from.js";
import "core-js/modules/es.object.keys.js";
var _excluded = ["cache"];
import "regenerator-runtime/runtime.js";

function _objectWithoutProperties(source, excluded) { if (source == null) return {}; var target = _objectWithoutPropertiesLoose(source, excluded); var key, i; if (Object.getOwnPropertySymbols) { var sourceSymbolKeys = Object.getOwnPropertySymbols(source); for (i = 0; i < sourceSymbolKeys.length; i++) { key = sourceSymbolKeys[i]; if (excluded.indexOf(key) >= 0) continue; if (!Object.prototype.propertyIsEnumerable.call(source, key)) continue; target[key] = source[key]; } } return target; }

function _objectWithoutPropertiesLoose(source, excluded) { if (source == null) return {}; var target = {}; var sourceKeys = Object.keys(source); var key, i; for (i = 0; i < sourceKeys.length; i++) { key = sourceKeys[i]; if (excluded.indexOf(key) >= 0) continue; target[key] = source[key]; } return target; }

import "core-js/modules/es.array.slice.js";
import "core-js/modules/es.regexp.exec.js";
import "core-js/modules/es.string.match.js";
import "core-js/modules/es.array.concat.js";
import "core-js/modules/es.array.iterator.js";
import "core-js/modules/es.object.to-string.js";
import "core-js/modules/es.promise.js";
import "core-js/modules/es.string.iterator.js";
import "core-js/modules/web.dom-collections.iterator.js";
import "core-js/modules/es.array.map.js";
import "core-js/modules/es.array.join.js";

function _slicedToArray(arr, i) { return _arrayWithHoles(arr) || _iterableToArrayLimit(arr, i) || _unsupportedIterableToArray(arr, i) || _nonIterableRest(); }

function _nonIterableRest() { throw new TypeError("Invalid attempt to destructure non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen); }

function _arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

function _iterableToArrayLimit(arr, i) { var _i = arr == null ? null : typeof Symbol !== "undefined" && arr[Symbol.iterator] || arr["@@iterator"]; if (_i == null) return; var _arr = []; var _n = true; var _d = false; var _s, _e; try { for (_i = _i.call(arr); !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"] != null) _i["return"](); } finally { if (_d) throw _e; } } return _arr; }

function _arrayWithHoles(arr) { if (Array.isArray(arr)) return arr; }

function asyncGeneratorStep(gen, resolve, reject, _next, _throw, key, arg) { try { var info = gen[key](arg); var value = info.value; } catch (error) { reject(error); return; } if (info.done) { resolve(value); } else { Promise.resolve(value).then(_next, _throw); } }

function _asyncToGenerator(fn) { return function () { var self = this, args = arguments; return new Promise(function (resolve, reject) { var gen = fn.apply(self, args); function _next(value) { asyncGeneratorStep(gen, resolve, reject, _next, _throw, "next", value); } function _throw(err) { asyncGeneratorStep(gen, resolve, reject, _next, _throw, "throw", err); } _next(undefined); }); }; }

import { logger } from '@storybook/node-logger';
import fs from 'fs-extra';
import path from 'path';
import { stringify } from 'telejson';
// The main config file determines the managerConfig value, so is already handled.
// The other files don't affect the manager, so can be safely ignored.
var ignoredConfigFiles = [/^main\.(m?js|ts)$/, /^preview\.(m?js|ts)$/, /^preview-head\.html$/];
export var useManagerCache = /*#__PURE__*/function () {
  var _ref = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee2(cacheKey, options, managerConfig) {
    var _yield$options$cache$, _yield$options$cache$2, cachedISOTime, cachedConfig, _, baseConfig, configString, configFiles, cacheCreationDate;

    return regeneratorRuntime.wrap(function _callee2$(_context2) {
      while (1) {
        switch (_context2.prev = _context2.next) {
          case 0:
            _context2.next = 2;
            return options.cache.get(cacheKey).then(function (str) {
              return str.match(/^([0-9TZ.:+-]+)_(.*)/).slice(1);
            }).catch(function () {
              return [];
            });

          case 2:
            _yield$options$cache$ = _context2.sent;
            _yield$options$cache$2 = _slicedToArray(_yield$options$cache$, 2);
            cachedISOTime = _yield$options$cache$2[0];
            cachedConfig = _yield$options$cache$2[1];
            // Drop the `cache` property because it'll change as a result of writing to the cache.
            _ = managerConfig.cache, baseConfig = _objectWithoutProperties(managerConfig, _excluded);
            configString = stringify(baseConfig);
            _context2.next = 10;
            return options.cache.set(cacheKey, "".concat(new Date().toISOString(), "_").concat(configString));

          case 10:
            if (!(configString !== cachedConfig || !cachedISOTime)) {
              _context2.next = 14;
              break;
            }

            logger.line(1); // force starting new line

            logger.info('=> Ignoring cached manager due to change in manager config');
            return _context2.abrupt("return", false);

          case 14:
            _context2.next = 16;
            return fs.readdir(options.configDir);

          case 16:
            configFiles = _context2.sent;
            cacheCreationDate = new Date(cachedISOTime);
            _context2.prev = 18;
            _context2.next = 21;
            return Promise.all(configFiles.map( /*#__PURE__*/function () {
              var _ref2 = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee(file) {
                var filepath, _yield$fs$stat, fileModificationDate;

                return regeneratorRuntime.wrap(function _callee$(_context) {
                  while (1) {
                    switch (_context.prev = _context.next) {
                      case 0:
                        if (!ignoredConfigFiles.some(function (pattern) {
                          return pattern.test(file);
                        })) {
                          _context.next = 2;
                          break;
                        }

                        return _context.abrupt("return");

                      case 2:
                        filepath = path.join(options.configDir, file);
                        _context.next = 5;
                        return fs.stat(filepath);

                      case 5:
                        _yield$fs$stat = _context.sent;
                        fileModificationDate = _yield$fs$stat.mtime;

                        if (!(fileModificationDate > cacheCreationDate)) {
                          _context.next = 9;
                          break;
                        }

                        throw filepath;

                      case 9:
                      case "end":
                        return _context.stop();
                    }
                  }
                }, _callee);
              }));

              return function (_x4) {
                return _ref2.apply(this, arguments);
              };
            }()));

          case 21:
            return _context2.abrupt("return", true);

          case 24:
            _context2.prev = 24;
            _context2.t0 = _context2["catch"](18);

            if (!(_context2.t0 instanceof Error)) {
              _context2.next = 28;
              break;
            }

            throw _context2.t0;

          case 28:
            logger.line(1); // force starting new line

            logger.info("=> Ignoring cached manager due to change in ".concat(_context2.t0));
            return _context2.abrupt("return", false);

          case 31:
          case "end":
            return _context2.stop();
        }
      }
    }, _callee2, null, [[18, 24]]);
  }));

  return function useManagerCache(_x, _x2, _x3) {
    return _ref.apply(this, arguments);
  };
}();
export var clearManagerCache = /*#__PURE__*/function () {
  var _ref3 = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee3(cacheKey, options) {
    return regeneratorRuntime.wrap(function _callee3$(_context3) {
      while (1) {
        switch (_context3.prev = _context3.next) {
          case 0:
            if (!(options.cache && options.cache.fileExists(cacheKey))) {
              _context3.next = 4;
              break;
            }

            _context3.next = 3;
            return options.cache.remove(cacheKey);

          case 3:
            return _context3.abrupt("return", true);

          case 4:
            return _context3.abrupt("return", false);

          case 5:
          case "end":
            return _context3.stop();
        }
      }
    }, _callee3);
  }));

  return function clearManagerCache(_x5, _x6) {
    return _ref3.apply(this, arguments);
  };
}();