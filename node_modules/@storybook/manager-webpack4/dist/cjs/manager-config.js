"use strict";

require("core-js/modules/es.array.slice.js");

require("core-js/modules/es.object.freeze.js");

require("core-js/modules/es.symbol.js");

require("core-js/modules/es.symbol.description.js");

require("core-js/modules/es.symbol.iterator.js");

require("core-js/modules/es.array.from.js");

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.getAutoRefs = void 0;
exports.getManagerWebpackConfig = getManagerWebpackConfig;

require("regenerator-runtime/runtime.js");

require("core-js/modules/es.array.filter.js");

require("core-js/modules/es.object.to-string.js");

require("core-js/modules/es.object.keys.js");

require("core-js/modules/es.object.assign.js");

require("core-js/modules/es.array.includes.js");

require("core-js/modules/es.string.includes.js");

require("core-js/modules/es.array.iterator.js");

require("core-js/modules/es.promise.js");

require("core-js/modules/es.string.iterator.js");

require("core-js/modules/web.dom-collections.iterator.js");

require("core-js/modules/es.array.map.js");

require("core-js/modules/es.array.join.js");

require("core-js/modules/es.function.name.js");

require("core-js/modules/es.regexp.exec.js");

require("core-js/modules/es.string.replace.js");

require("core-js/modules/es.string.trim.js");

require("core-js/modules/es.array.concat.js");

require("core-js/modules/es.object.entries.js");

require("core-js/modules/web.dom-collections.for-each.js");

var _path = _interopRequireDefault(require("path"));

var _fsExtra = _interopRequireDefault(require("fs-extra"));

var _findUp = _interopRequireDefault(require("find-up"));

var _resolveFrom = _interopRequireDefault(require("resolve-from"));

var _nodeFetch = _interopRequireDefault(require("node-fetch"));

var _utilDeprecate = _interopRequireDefault(require("util-deprecate"));

var _tsDedent = _interopRequireDefault(require("ts-dedent"));

var _templateObject;

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _slicedToArray(arr, i) { return _arrayWithHoles(arr) || _iterableToArrayLimit(arr, i) || _unsupportedIterableToArray(arr, i) || _nonIterableRest(); }

function _nonIterableRest() { throw new TypeError("Invalid attempt to destructure non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen); }

function _arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

function _iterableToArrayLimit(arr, i) { var _i = arr == null ? null : typeof Symbol !== "undefined" && arr[Symbol.iterator] || arr["@@iterator"]; if (_i == null) return; var _arr = []; var _n = true; var _d = false; var _s, _e; try { for (_i = _i.call(arr); !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"] != null) _i["return"](); } finally { if (_d) throw _e; } } return _arr; }

function _arrayWithHoles(arr) { if (Array.isArray(arr)) return arr; }

function _taggedTemplateLiteral(strings, raw) { if (!raw) { raw = strings.slice(0); } return Object.freeze(Object.defineProperties(strings, { raw: { value: Object.freeze(raw) } })); }

function asyncGeneratorStep(gen, resolve, reject, _next, _throw, key, arg) { try { var info = gen[key](arg); var value = info.value; } catch (error) { reject(error); return; } if (info.done) { resolve(value); } else { Promise.resolve(value).then(_next, _throw); } }

function _asyncToGenerator(fn) { return function () { var self = this, args = arguments; return new Promise(function (resolve, reject) { var gen = fn.apply(self, args); function _next(value) { asyncGeneratorStep(gen, resolve, reject, _next, _throw, "next", value); } function _throw(err) { asyncGeneratorStep(gen, resolve, reject, _next, _throw, "throw", err); } _next(undefined); }); }; }

var getAutoRefs = /*#__PURE__*/function () {
  var _ref = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee2(options) {
    var disabledRefs,
        location,
        directory,
        _yield$fs$readJSON,
        dependencies,
        devDependencies,
        deps,
        list,
        _args2 = arguments;

    return regeneratorRuntime.wrap(function _callee2$(_context2) {
      while (1) {
        switch (_context2.prev = _context2.next) {
          case 0:
            disabledRefs = _args2.length > 1 && _args2[1] !== undefined ? _args2[1] : [];
            _context2.next = 3;
            return (0, _findUp.default)('package.json', {
              cwd: options.configDir
            });

          case 3:
            location = _context2.sent;
            directory = _path.default.dirname(location);
            _context2.next = 7;
            return _fsExtra.default.readJSON(location);

          case 7:
            _yield$fs$readJSON = _context2.sent;
            dependencies = _yield$fs$readJSON.dependencies;
            devDependencies = _yield$fs$readJSON.devDependencies;
            deps = Object.keys(Object.assign({}, dependencies, devDependencies)).filter(function (dep) {
              return !disabledRefs.includes(dep);
            });
            _context2.next = 13;
            return Promise.all(deps.map( /*#__PURE__*/function () {
              var _ref2 = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee(d) {
                var l, _yield$fs$readJSON2, storybook, name, version;

                return regeneratorRuntime.wrap(function _callee$(_context) {
                  while (1) {
                    switch (_context.prev = _context.next) {
                      case 0:
                        _context.prev = 0;
                        l = (0, _resolveFrom.default)(directory, _path.default.join(d, 'package.json'));
                        _context.next = 4;
                        return _fsExtra.default.readJSON(l);

                      case 4:
                        _yield$fs$readJSON2 = _context.sent;
                        storybook = _yield$fs$readJSON2.storybook;
                        name = _yield$fs$readJSON2.name;
                        version = _yield$fs$readJSON2.version;

                        if (!(storybook !== null && storybook !== void 0 && storybook.url)) {
                          _context.next = 10;
                          break;
                        }

                        return _context.abrupt("return", Object.assign({
                          id: name
                        }, storybook, {
                          version: version
                        }));

                      case 10:
                        _context.next = 15;
                        break;

                      case 12:
                        _context.prev = 12;
                        _context.t0 = _context["catch"](0);
                        return _context.abrupt("return", undefined);

                      case 15:
                        return _context.abrupt("return", undefined);

                      case 16:
                      case "end":
                        return _context.stop();
                    }
                  }
                }, _callee, null, [[0, 12]]);
              }));

              return function (_x2) {
                return _ref2.apply(this, arguments);
              };
            }()));

          case 13:
            list = _context2.sent;
            return _context2.abrupt("return", list.filter(Boolean));

          case 15:
          case "end":
            return _context2.stop();
        }
      }
    }, _callee2);
  }));

  return function getAutoRefs(_x) {
    return _ref.apply(this, arguments);
  };
}();

exports.getAutoRefs = getAutoRefs;

var checkRef = function checkRef(url) {
  return (0, _nodeFetch.default)("".concat(url, "/iframe.html")).then(function (_ref3) {
    var ok = _ref3.ok;
    return ok;
  }, function () {
    return false;
  });
};

var stripTrailingSlash = function stripTrailingSlash(url) {
  return url.replace(/\/$/, '');
};

var toTitle = function toTitle(input) {
  var result = input.replace(/[A-Z]/g, function (f) {
    return " ".concat(f);
  }).replace(/[-_][A-Z]/gi, function (f) {
    return " ".concat(f.toUpperCase());
  }).replace(/-/g, ' ').replace(/_/g, ' ');
  return "".concat(result.substring(0, 1).toUpperCase()).concat(result.substring(1)).trim();
};

var deprecatedDefinedRefDisabled = (0, _utilDeprecate.default)(function () {}, (0, _tsDedent.default)(_templateObject || (_templateObject = _taggedTemplateLiteral(["\n    Deprecated parameter: disabled => disable\n\n    https://github.com/storybookjs/storybook/blob/next/MIGRATION.md#deprecated-package-composition-disabled-parameter\n  "]))));

function getManagerWebpackConfig(_x3) {
  return _getManagerWebpackConfig.apply(this, arguments);
}

function _getManagerWebpackConfig() {
  _getManagerWebpackConfig = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee4(options) {
    var presets, definedRefs, disabledRefs, autoRefs, entries, refs;
    return regeneratorRuntime.wrap(function _callee4$(_context4) {
      while (1) {
        switch (_context4.prev = _context4.next) {
          case 0:
            presets = options.presets;
            _context4.next = 3;
            return presets.apply('refs', undefined, options);

          case 3:
            definedRefs = _context4.sent;
            disabledRefs = [];

            if (definedRefs) {
              disabledRefs = Object.entries(definedRefs).filter(function (_ref4) {
                var _ref5 = _slicedToArray(_ref4, 2),
                    key = _ref5[0],
                    value = _ref5[1];

                var disable = value.disable,
                    disabled = value.disabled;

                if (disable || disabled) {
                  if (disabled) {
                    deprecatedDefinedRefDisabled();
                  }

                  delete definedRefs[key]; // Also delete the ref that is disabled in definedRefs

                  return true;
                }

                return false;
              }).map(function (ref) {
                return ref[0];
              });
            }

            _context4.next = 8;
            return getAutoRefs(options, disabledRefs);

          case 8:
            autoRefs = _context4.sent;
            _context4.next = 11;
            return presets.apply('managerEntries', [], options);

          case 11:
            entries = _context4.sent;
            refs = {};

            if (autoRefs && autoRefs.length) {
              autoRefs.forEach(function (_ref6) {
                var id = _ref6.id,
                    url = _ref6.url,
                    title = _ref6.title,
                    version = _ref6.version;
                refs[id.toLowerCase()] = {
                  id: id.toLowerCase(),
                  url: stripTrailingSlash(url),
                  title: title,
                  version: version
                };
              });
            }

            if (definedRefs) {
              Object.entries(definedRefs).forEach(function (_ref7) {
                var _ref8 = _slicedToArray(_ref7, 2),
                    key = _ref8[0],
                    value = _ref8[1];

                var url = typeof value === 'string' ? value : value.url;
                var rest = typeof value === 'string' ? {
                  title: toTitle(key)
                } : Object.assign({}, value, {
                  title: value.title || toTitle(value.key || key)
                });
                refs[key.toLowerCase()] = Object.assign({
                  id: key.toLowerCase()
                }, rest, {
                  url: stripTrailingSlash(url)
                });
              });
            }

            if (!(autoRefs && autoRefs.length || definedRefs)) {
              _context4.next = 19;
              break;
            }

            entries.push(_path.default.resolve(_path.default.join(options.configDir, "generated-refs.js"))); // verify the refs are publicly reachable, if they are not we'll require stories.json at runtime, otherwise the ref won't work

            _context4.next = 19;
            return Promise.all(Object.entries(refs).map( /*#__PURE__*/function () {
              var _ref10 = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee3(_ref9) {
                var _ref11, k, value, ok;

                return regeneratorRuntime.wrap(function _callee3$(_context3) {
                  while (1) {
                    switch (_context3.prev = _context3.next) {
                      case 0:
                        _ref11 = _slicedToArray(_ref9, 2), k = _ref11[0], value = _ref11[1];
                        _context3.next = 3;
                        return checkRef(value.url);

                      case 3:
                        ok = _context3.sent;
                        refs[k] = Object.assign({}, value, {
                          type: ok ? 'server-checked' : 'unknown'
                        });

                      case 5:
                      case "end":
                        return _context3.stop();
                    }
                  }
                }, _callee3);
              }));

              return function (_x4) {
                return _ref10.apply(this, arguments);
              };
            }()));

          case 19:
            return _context4.abrupt("return", presets.apply('managerWebpack', {}, Object.assign({}, options, {
              entries: entries,
              refs: refs
            })));

          case 20:
          case "end":
            return _context4.stop();
        }
      }
    }, _callee4);
  }));
  return _getManagerWebpackConfig.apply(this, arguments);
}