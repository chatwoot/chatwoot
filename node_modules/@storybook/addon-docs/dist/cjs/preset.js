"use strict";

require("core-js/modules/es.symbol.js");

require("core-js/modules/es.symbol.description.js");

require("core-js/modules/es.symbol.iterator.js");

require("core-js/modules/es.array.iterator.js");

require("core-js/modules/es.string.iterator.js");

require("core-js/modules/web.dom-collections.iterator.js");

require("core-js/modules/es.array.from.js");

require("core-js/modules/es.array.slice.js");

require("core-js/modules/es.function.name.js");

require("core-js/modules/es.promise.js");

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.webpack = webpack;

require("regenerator-runtime/runtime.js");

require("core-js/modules/es.array.concat.js");

require("core-js/modules/es.object.assign.js");

require("core-js/modules/es.array.filter.js");

require("core-js/modules/es.object.to-string.js");

require("core-js/modules/es.regexp.exec.js");

require("core-js/modules/es.regexp.to-string.js");

require("core-js/modules/es.regexp.constructor.js");

var _path = _interopRequireDefault(require("path"));

var _remarkSlug = _interopRequireDefault(require("remark-slug"));

var _remarkExternalLinks = _interopRequireDefault(require("remark-external-links"));

var _global = _interopRequireDefault(require("global"));

var _nodeLogger = require("@storybook/node-logger");

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function asyncGeneratorStep(gen, resolve, reject, _next, _throw, key, arg) { try { var info = gen[key](arg); var value = info.value; } catch (error) { reject(error); return; } if (info.done) { resolve(value); } else { Promise.resolve(value).then(_next, _throw); } }

function _asyncToGenerator(fn) { return function () { var self = this, args = arguments; return new Promise(function (resolve, reject) { var gen = fn.apply(self, args); function _next(value) { asyncGeneratorStep(gen, resolve, reject, _next, _throw, "next", value); } function _throw(err) { asyncGeneratorStep(gen, resolve, reject, _next, _throw, "throw", err); } _next(undefined); }); }; }

function _toConsumableArray(arr) { return _arrayWithoutHoles(arr) || _iterableToArray(arr) || _unsupportedIterableToArray(arr) || _nonIterableSpread(); }

function _nonIterableSpread() { throw new TypeError("Invalid attempt to spread non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen); }

function _iterableToArray(iter) { if (typeof Symbol !== "undefined" && iter[Symbol.iterator] != null || iter["@@iterator"] != null) return Array.from(iter); }

function _arrayWithoutHoles(arr) { if (Array.isArray(arr)) return _arrayLikeToArray(arr); }

function _arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

function createBabelOptions(_ref) {
  var babelOptions = _ref.babelOptions,
      mdxBabelOptions = _ref.mdxBabelOptions,
      configureJSX = _ref.configureJSX;
  var babelPlugins = (mdxBabelOptions === null || mdxBabelOptions === void 0 ? void 0 : mdxBabelOptions.plugins) || (babelOptions === null || babelOptions === void 0 ? void 0 : babelOptions.plugins) || [];
  var jsxPlugin = [require.resolve('@babel/plugin-transform-react-jsx'), {
    pragma: 'React.createElement',
    pragmaFrag: 'React.Fragment'
  }];
  var plugins = configureJSX ? [].concat(_toConsumableArray(babelPlugins), [jsxPlugin]) : babelPlugins;
  return Object.assign({
    // don't use the root babelrc by default (users can override this in mdxBabelOptions)
    babelrc: false,
    configFile: false
  }, babelOptions, mdxBabelOptions, {
    plugins: plugins
  });
}

function webpack() {
  return _webpack.apply(this, arguments);
}

function _webpack() {
  _webpack = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee() {
    var _global$FEATURES, _global$FEATURES2;

    var webpackConfig,
        options,
        resolvedBabelLoader,
        _webpackConfig$module,
        module,
        babelOptions,
        mdxBabelOptions,
        _options$configureJSX,
        configureJSX,
        _options$sourceLoader,
        sourceLoaderOptions,
        _options$transcludeMa,
        transcludeMarkdown,
        mdxLoaderOptions,
        mdxVersion,
        mdxLoader,
        sourceLoader,
        rules,
        result,
        _args = arguments;

    return regeneratorRuntime.wrap(function _callee$(_context) {
      while (1) {
        switch (_context.prev = _context.next) {
          case 0:
            webpackConfig = _args.length > 0 && _args[0] !== undefined ? _args[0] : {};
            options = _args.length > 1 ? _args[1] : undefined;
            resolvedBabelLoader = require.resolve('babel-loader');
            _webpackConfig$module = webpackConfig.module, module = _webpackConfig$module === void 0 ? {} : _webpackConfig$module; // it will reuse babel options that are already in use in storybook
            // also, these babel options are chained with other presets.

            babelOptions = options.babelOptions, mdxBabelOptions = options.mdxBabelOptions, _options$configureJSX = options.configureJSX, configureJSX = _options$configureJSX === void 0 ? true : _options$configureJSX, _options$sourceLoader = options.sourceLoaderOptions, sourceLoaderOptions = _options$sourceLoader === void 0 ? {
              injectStoryParameters: true
            } : _options$sourceLoader, _options$transcludeMa = options.transcludeMarkdown, transcludeMarkdown = _options$transcludeMa === void 0 ? false : _options$transcludeMa;
            mdxLoaderOptions = {
              skipCsf: true,
              remarkPlugins: [_remarkSlug.default, _remarkExternalLinks.default]
            };
            mdxVersion = (_global$FEATURES = _global.default.FEATURES) !== null && _global$FEATURES !== void 0 && _global$FEATURES.previewMdx2 ? 'MDX2' : 'MDX1';

            _nodeLogger.logger.info("Addon-docs: using ".concat(mdxVersion));

            mdxLoader = (_global$FEATURES2 = _global.default.FEATURES) !== null && _global$FEATURES2 !== void 0 && _global$FEATURES2.previewMdx2 ? require.resolve('@storybook/mdx2-csf/loader') : require.resolve('@storybook/mdx1-csf/loader'); // set `sourceLoaderOptions` to `null` to disable for manual configuration

            sourceLoader = sourceLoaderOptions ? [{
              test: /\.(stories|story)\.[tj]sx?$/,
              loader: require.resolve('@storybook/source-loader'),
              options: Object.assign({}, sourceLoaderOptions, {
                inspectLocalDependencies: true
              }),
              enforce: 'pre'
            }] : [];
            rules = module.rules || [];

            if (transcludeMarkdown) {
              rules = [].concat(_toConsumableArray(rules.filter(function (rule) {
                var _rule$test;

                return ((_rule$test = rule.test) === null || _rule$test === void 0 ? void 0 : _rule$test.toString()) !== '/\\.md$/';
              })), [{
                test: /\.md$/,
                use: [{
                  loader: resolvedBabelLoader,
                  options: createBabelOptions({
                    babelOptions: babelOptions,
                    mdxBabelOptions: mdxBabelOptions,
                    configureJSX: configureJSX
                  })
                }, {
                  loader: mdxLoader,
                  options: mdxLoaderOptions
                }]
              }]);
            }

            result = Object.assign({}, webpackConfig, {
              module: Object.assign({}, module, {
                rules: [].concat(_toConsumableArray(rules), [{
                  test: /\.js$/,
                  include: new RegExp("node_modules\\".concat(_path.default.sep, "acorn-jsx")),
                  use: [{
                    loader: resolvedBabelLoader,
                    options: {
                      presets: [[require.resolve('@babel/preset-env'), {
                        modules: 'commonjs'
                      }]]
                    }
                  }]
                }, {
                  test: /(stories|story)\.mdx$/,
                  use: [{
                    loader: resolvedBabelLoader,
                    options: createBabelOptions({
                      babelOptions: babelOptions,
                      mdxBabelOptions: mdxBabelOptions,
                      configureJSX: configureJSX
                    })
                  }, {
                    loader: mdxLoader
                  }]
                }, {
                  test: /\.mdx$/,
                  exclude: /(stories|story)\.mdx$/,
                  use: [{
                    loader: resolvedBabelLoader,
                    options: createBabelOptions({
                      babelOptions: babelOptions,
                      mdxBabelOptions: mdxBabelOptions,
                      configureJSX: configureJSX
                    })
                  }, {
                    loader: mdxLoader,
                    options: mdxLoaderOptions
                  }]
                }], sourceLoader)
              })
            });
            return _context.abrupt("return", result);

          case 14:
          case "end":
            return _context.stop();
        }
      }
    }, _callee);
  }));
  return _webpack.apply(this, arguments);
}