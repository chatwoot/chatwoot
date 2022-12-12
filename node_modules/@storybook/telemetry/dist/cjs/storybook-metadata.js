"use strict";

require("core-js/modules/es.array.slice.js");

require("core-js/modules/es.array.from.js");

require("core-js/modules/es.string.iterator.js");

require("core-js/modules/es.symbol.js");

require("core-js/modules/es.symbol.description.js");

require("core-js/modules/es.symbol.iterator.js");

require("core-js/modules/es.array.iterator.js");

require("core-js/modules/web.dom-collections.iterator.js");

require("core-js/modules/es.promise.js");

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.metaFrameworks = exports.getStorybookMetadata = exports.computeStorybookMetadata = void 0;

require("regenerator-runtime/runtime.js");

require("core-js/modules/es.array.map.js");

require("core-js/modules/es.object.assign.js");

require("core-js/modules/es.array.find.js");

require("core-js/modules/es.object.to-string.js");

require("core-js/modules/es.object.keys.js");

require("core-js/modules/es.function.name.js");

require("core-js/modules/web.dom-collections.for-each.js");

require("core-js/modules/es.regexp.exec.js");

require("core-js/modules/es.string.replace.js");

require("core-js/modules/es.array.filter.js");

require("core-js/modules/es.array.includes.js");

require("core-js/modules/es.string.includes.js");

var _readPkgUp = _interopRequireDefault(require("read-pkg-up"));

var _detectPackageManager = require("detect-package-manager");

var _coreCommon = require("@storybook/core-common");

var _packageVersions = require("./package-versions");

var _getMonorepoType = require("./get-monorepo-type");

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }

function asyncGeneratorStep(gen, resolve, reject, _next, _throw, key, arg) { try { var info = gen[key](arg); var value = info.value; } catch (error) { reject(error); return; } if (info.done) { resolve(value); } else { Promise.resolve(value).then(_next, _throw); } }

function _asyncToGenerator(fn) { return function () { var self = this, args = arguments; return new Promise(function (resolve, reject) { var gen = fn.apply(self, args); function _next(value) { asyncGeneratorStep(gen, resolve, reject, _next, _throw, "next", value); } function _throw(err) { asyncGeneratorStep(gen, resolve, reject, _next, _throw, "throw", err); } _next(undefined); }); }; }

function _createForOfIteratorHelper(o, allowArrayLike) { var it = typeof Symbol !== "undefined" && o[Symbol.iterator] || o["@@iterator"]; if (!it) { if (Array.isArray(o) || (it = _unsupportedIterableToArray(o)) || allowArrayLike && o && typeof o.length === "number") { if (it) o = it; var i = 0; var F = function F() {}; return { s: F, n: function n() { if (i >= o.length) return { done: true }; return { done: false, value: o[i++] }; }, e: function e(_e) { throw _e; }, f: F }; } throw new TypeError("Invalid attempt to iterate non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); } var normalCompletion = true, didErr = false, err; return { s: function s() { it = it.call(o); }, n: function n() { var step = it.next(); normalCompletion = step.done; return step; }, e: function e(_e2) { didErr = true; err = _e2; }, f: function f() { try { if (!normalCompletion && it.return != null) it.return(); } finally { if (didErr) throw err; } } }; }

function _unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen); }

function _arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

var metaFrameworks = {
  next: 'Next',
  'react-scripts': 'CRA',
  gatsby: 'Gatsby',
  '@nuxtjs/storybook': 'nuxt',
  '@nrwl/storybook': 'nx',
  '@vue/cli-service': 'vue-cli',
  '@sveltejs/kit': 'svelte-kit'
}; // @TODO: This should be removed in 7.0 as the framework.options field in main.js will replace this

exports.metaFrameworks = metaFrameworks;

var getFrameworkOptions = function getFrameworkOptions(mainConfig) {
  var possibleOptions = ['angular', 'ember', 'html', 'preact', 'react', 'server', 'svelte', 'vue', 'vue3', 'webComponents'].map(function (opt) {
    return "".concat(opt, "Options");
  }); // eslint-disable-next-line no-restricted-syntax

  var _iterator = _createForOfIteratorHelper(possibleOptions),
      _step;

  try {
    for (_iterator.s(); !(_step = _iterator.n()).done;) {
      var opt = _step.value;

      if (opt in mainConfig) {
        return mainConfig[opt];
      }
    }
  } catch (err) {
    _iterator.e(err);
  } finally {
    _iterator.f();
  }

  return undefined;
}; // Analyze a combination of information from main.js and package.json
// to provide telemetry over a Storybook project


var computeStorybookMetadata = /*#__PURE__*/function () {
  var _ref2 = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee(_ref) {
    var _mainConfig$core, _storybookPackages$st;

    var packageJson, mainConfig, metadata, allDependencies, metaFramework, _yield$getActualPacka, version, monorepoType, packageManagerType, packageManagerVerson, _builder$options, builder, addons, addonVersions, addonNames, storybookPackages, storybookPackageVersions, language, hasStorybookEslint, storybookInfo, storybookVersion;

    return regeneratorRuntime.wrap(function _callee$(_context) {
      while (1) {
        switch (_context.prev = _context.next) {
          case 0:
            packageJson = _ref.packageJson, mainConfig = _ref.mainConfig;
            metadata = {
              generatedAt: new Date().getTime(),
              builder: {
                name: 'webpack4'
              },
              hasCustomBabel: false,
              hasCustomWebpack: false,
              hasStaticDirs: false,
              hasStorybookEslint: false,
              refCount: 0
            };
            allDependencies = Object.assign({}, packageJson === null || packageJson === void 0 ? void 0 : packageJson.dependencies, packageJson === null || packageJson === void 0 ? void 0 : packageJson.devDependencies, packageJson === null || packageJson === void 0 ? void 0 : packageJson.peerDependencies);
            metaFramework = Object.keys(allDependencies).find(function (dep) {
              return !!metaFrameworks[dep];
            });

            if (!metaFramework) {
              _context.next = 10;
              break;
            }

            _context.next = 7;
            return (0, _packageVersions.getActualPackageVersion)(metaFramework);

          case 7:
            _yield$getActualPacka = _context.sent;
            version = _yield$getActualPacka.version;
            metadata.metaFramework = {
              name: metaFrameworks[metaFramework],
              packageName: metaFramework,
              version: version
            };

          case 10:
            monorepoType = (0, _getMonorepoType.getMonorepoType)();

            if (monorepoType) {
              metadata.monorepo = monorepoType;
            }

            _context.prev = 12;
            _context.next = 15;
            return (0, _detectPackageManager.detect)({
              cwd: (0, _coreCommon.getProjectRoot)()
            });

          case 15:
            packageManagerType = _context.sent;
            _context.next = 18;
            return (0, _detectPackageManager.getNpmVersion)(packageManagerType);

          case 18:
            packageManagerVerson = _context.sent;
            metadata.packageManager = {
              type: packageManagerType,
              version: packageManagerVerson
            }; // Better be safe than sorry, some codebases/paths might end up breaking with something like "spawn pnpm ENOENT"
            // so we just set the package manager if the detection is successful
            // eslint-disable-next-line no-empty

            _context.next = 24;
            break;

          case 22:
            _context.prev = 22;
            _context.t0 = _context["catch"](12);

          case 24:
            metadata.hasCustomBabel = !!mainConfig.babel;
            metadata.hasCustomWebpack = !!mainConfig.webpackFinal;
            metadata.hasStaticDirs = !!mainConfig.staticDirs;

            if (mainConfig.typescript) {
              metadata.typescriptOptions = mainConfig.typescript;
            }

            if ((_mainConfig$core = mainConfig.core) !== null && _mainConfig$core !== void 0 && _mainConfig$core.builder) {
              builder = mainConfig.core.builder;
              metadata.builder = {
                name: typeof builder === 'string' ? builder : builder.name,
                options: typeof builder === 'string' ? undefined : (_builder$options = builder === null || builder === void 0 ? void 0 : builder.options) !== null && _builder$options !== void 0 ? _builder$options : undefined
              };
            }

            if (mainConfig.refs) {
              metadata.refCount = Object.keys(mainConfig.refs).length;
            }

            if (mainConfig.features) {
              metadata.features = mainConfig.features;
            }

            addons = {};

            if (mainConfig.addons) {
              mainConfig.addons.forEach(function (addon) {
                var result;
                var options;

                if (typeof addon === 'string') {
                  result = addon.replace('/register', '').replace('/preset', '');
                } else {
                  options = addon.options;
                  result = addon.name;
                }

                addons[result] = {
                  options: options,
                  version: undefined
                };
              });
            }

            _context.next = 35;
            return (0, _packageVersions.getActualPackageVersions)(addons);

          case 35:
            addonVersions = _context.sent;
            addonVersions.forEach(function (_ref3) {
              var name = _ref3.name,
                  version = _ref3.version;
              addons[name].version = version;
            });
            addonNames = Object.keys(addons); // all Storybook deps minus the addons

            storybookPackages = Object.keys(allDependencies).filter(function (dep) {
              return dep.includes('storybook') && !addonNames.includes(dep);
            }).reduce(function (acc, dep) {
              return Object.assign({}, acc, _defineProperty({}, dep, {
                version: undefined
              }));
            }, {});
            _context.next = 41;
            return (0, _packageVersions.getActualPackageVersions)(storybookPackages);

          case 41:
            storybookPackageVersions = _context.sent;
            storybookPackageVersions.forEach(function (_ref4) {
              var name = _ref4.name,
                  version = _ref4.version;
              storybookPackages[name].version = version;
            });
            language = allDependencies.typescript ? 'typescript' : 'javascript';
            hasStorybookEslint = !!allDependencies['eslint-plugin-storybook'];
            storybookInfo = (0, _coreCommon.getStorybookInfo)(packageJson);
            storybookVersion = ((_storybookPackages$st = storybookPackages[storybookInfo.frameworkPackage]) === null || _storybookPackages$st === void 0 ? void 0 : _storybookPackages$st.version) || storybookInfo.version;
            return _context.abrupt("return", Object.assign({}, metadata, {
              storybookVersion: storybookVersion,
              language: language,
              storybookPackages: storybookPackages,
              framework: {
                name: storybookInfo.framework,
                options: getFrameworkOptions(mainConfig)
              },
              addons: addons,
              hasStorybookEslint: hasStorybookEslint
            }));

          case 48:
          case "end":
            return _context.stop();
        }
      }
    }, _callee, null, [[12, 22]]);
  }));

  return function computeStorybookMetadata(_x) {
    return _ref2.apply(this, arguments);
  };
}();

exports.computeStorybookMetadata = computeStorybookMetadata;
var cachedMetadata;

var getStorybookMetadata = /*#__PURE__*/function () {
  var _ref5 = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee2(_configDir) {
    var _ref6;

    var packageJson, configDir, mainConfig;
    return regeneratorRuntime.wrap(function _callee2$(_context2) {
      while (1) {
        switch (_context2.prev = _context2.next) {
          case 0:
            if (!cachedMetadata) {
              _context2.next = 2;
              break;
            }

            return _context2.abrupt("return", cachedMetadata);

          case 2:
            packageJson = _readPkgUp.default.sync({
              cwd: process.cwd()
            }).packageJson;
            configDir = (_ref6 = _configDir || (0, _coreCommon.getStorybookConfiguration)(packageJson.scripts.storybook, '-c', '--config-dir')) !== null && _ref6 !== void 0 ? _ref6 : '.storybook';
            mainConfig = (0, _coreCommon.loadMainConfig)({
              configDir: configDir
            });
            _context2.next = 7;
            return computeStorybookMetadata({
              mainConfig: mainConfig,
              packageJson: packageJson
            });

          case 7:
            cachedMetadata = _context2.sent;
            return _context2.abrupt("return", cachedMetadata);

          case 9:
          case "end":
            return _context2.stop();
        }
      }
    }, _callee2);
  }));

  return function getStorybookMetadata(_x2) {
    return _ref5.apply(this, arguments);
  };
}();

exports.getStorybookMetadata = getStorybookMetadata;