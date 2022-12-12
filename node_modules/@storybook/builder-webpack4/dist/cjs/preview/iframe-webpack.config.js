"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = void 0;

require("core-js/modules/es.promise.js");

var _path = _interopRequireDefault(require("path"));

var _webpack = require("webpack");

var _htmlWebpackPlugin = _interopRequireDefault(require("html-webpack-plugin"));

var _caseSensitivePathsWebpackPlugin = _interopRequireDefault(require("case-sensitive-paths-webpack-plugin"));

var _terserWebpackPlugin = _interopRequireDefault(require("terser-webpack-plugin"));

var _webpackVirtualModules = _interopRequireDefault(require("webpack-virtual-modules"));

var _pnpWebpackPlugin = _interopRequireDefault(require("pnp-webpack-plugin"));

var _forkTsCheckerWebpackPlugin = _interopRequireDefault(require("fork-ts-checker-webpack-plugin"));

var _webpackFilterWarningsPlugin = _interopRequireDefault(require("webpack-filter-warnings-plugin"));

var _paths = _interopRequireDefault(require("@storybook/theming/paths"));

var _coreCommon = require("@storybook/core-common");

var _babelLoaderPreview = require("./babel-loader-preview");

var _useBaseTsSupport = require("./useBaseTsSupport");

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function ownKeys(object, enumerableOnly) { var keys = Object.keys(object); if (Object.getOwnPropertySymbols) { var symbols = Object.getOwnPropertySymbols(object); enumerableOnly && (symbols = symbols.filter(function (sym) { return Object.getOwnPropertyDescriptor(object, sym).enumerable; })), keys.push.apply(keys, symbols); } return keys; }

function _objectSpread(target) { for (var i = 1; i < arguments.length; i++) { var source = null != arguments[i] ? arguments[i] : {}; i % 2 ? ownKeys(Object(source), !0).forEach(function (key) { _defineProperty(target, key, source[key]); }) : Object.getOwnPropertyDescriptors ? Object.defineProperties(target, Object.getOwnPropertyDescriptors(source)) : ownKeys(Object(source)).forEach(function (key) { Object.defineProperty(target, key, Object.getOwnPropertyDescriptor(source, key)); }); } return target; }

function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }

var storybookPaths = ['addons', 'api', 'channels', 'channel-postmessage', 'components', 'core-events', 'router', 'theming', 'semver', 'client-api', 'client-logger', 'preview-web', 'store'].reduce(function (acc, sbPackage) {
  return _objectSpread(_objectSpread({}, acc), {}, {
    [`@storybook/${sbPackage}`]: _path.default.dirname(require.resolve(`@storybook/${sbPackage}/package.json`))
  });
}, {});

var _default = async function _default(options) {
  var babelOptions = options.babelOptions,
      _options$outputDir = options.outputDir,
      outputDir = _options$outputDir === void 0 ? _path.default.join('.', 'public') : _options$outputDir,
      quiet = options.quiet,
      packageJson = options.packageJson,
      configType = options.configType,
      framework = options.framework,
      frameworkPath = options.frameworkPath,
      presets = options.presets,
      previewUrl = options.previewUrl,
      typescriptOptions = options.typescriptOptions,
      modern = options.modern,
      features = options.features,
      serverChannelUrl = options.serverChannelUrl;
  var logLevel = await presets.apply('logLevel', undefined);
  var frameworkOptions = await presets.apply(`${framework}Options`, {});
  var headHtmlSnippet = await presets.apply('previewHead');
  var bodyHtmlSnippet = await presets.apply('previewBody');
  var template = await presets.apply('previewMainTemplate');
  var envs = await presets.apply('env');
  var coreOptions = await presets.apply('core');
  var babelLoader = (0, _babelLoaderPreview.createBabelLoader)(babelOptions, framework);
  var isProd = configType === 'PRODUCTION';
  var configs = [...(await presets.apply('config', [], options)), (0, _coreCommon.loadPreviewOrConfigFile)(options)].filter(Boolean);
  var entries = await presets.apply('entries', [], options);
  var workingDir = process.cwd();
  var stories = (0, _coreCommon.normalizeStories)(await presets.apply('stories', [], options), {
    configDir: options.configDir,
    workingDir: workingDir
  });
  var virtualModuleMapping = {};

  if (features !== null && features !== void 0 && features.storyStoreV7) {
    var storiesFilename = 'storybook-stories.js';

    var storiesPath = _path.default.resolve(_path.default.join(workingDir, storiesFilename));

    virtualModuleMapping[storiesPath] = (0, _coreCommon.toImportFn)(stories);

    var configEntryPath = _path.default.resolve(_path.default.join(workingDir, 'storybook-config-entry.js'));

    virtualModuleMapping[configEntryPath] = (0, _coreCommon.handlebars)(await (0, _coreCommon.readTemplate)(require.resolve('@storybook/builder-webpack4/templates/virtualModuleModernEntry.js.handlebars')), {
      storiesFilename: storiesFilename,
      configs: configs
    } // We need to double escape `\` for webpack. We may have some in windows paths
    ).replace(/\\/g, '\\\\');
    entries.push(configEntryPath);
  } else {
    var frameworkInitEntry = _path.default.resolve(_path.default.join(workingDir, 'storybook-init-framework-entry.js'));

    var frameworkImportPath = frameworkPath || `@storybook/${framework}`;
    virtualModuleMapping[frameworkInitEntry] = `import '${frameworkImportPath}';`;
    entries.push(frameworkInitEntry);
    var entryTemplate = await (0, _coreCommon.readTemplate)(_path.default.join(__dirname, 'virtualModuleEntry.template.js'));
    configs.forEach(function (configFilename) {
      var clientApi = storybookPaths['@storybook/client-api'];
      var clientLogger = storybookPaths['@storybook/client-logger'];
      virtualModuleMapping[`${configFilename}-generated-config-entry.js`] = (0, _coreCommon.interpolate)(entryTemplate, {
        configFilename: configFilename,
        clientApi: clientApi,
        clientLogger: clientLogger
      });
      entries.push(`${configFilename}-generated-config-entry.js`);
    });

    if (stories.length > 0) {
      var storyTemplate = await (0, _coreCommon.readTemplate)(_path.default.join(__dirname, 'virtualModuleStory.template.js'));

      var _storiesFilename = _path.default.resolve(_path.default.join(workingDir, `generated-stories-entry.js`));

      virtualModuleMapping[_storiesFilename] = (0, _coreCommon.interpolate)(storyTemplate, {
        frameworkImportPath: frameworkImportPath
      }) // Make sure we also replace quotes for this one
      .replace("'{{stories}}'", stories.map(_coreCommon.toRequireContextString).join(','));
      entries.push(_storiesFilename);
    }
  }

  var shouldCheckTs = (0, _useBaseTsSupport.useBaseTsSupport)(framework) && typescriptOptions.check;
  var tsCheckOptions = typescriptOptions.checkOptions || {};
  return {
    name: 'preview',
    mode: isProd ? 'production' : 'development',
    bail: isProd,
    devtool: 'cheap-module-source-map',
    entry: entries,
    // stats: 'errors-only',
    output: {
      path: _path.default.resolve(process.cwd(), outputDir),
      filename: isProd ? '[name].[contenthash:8].iframe.bundle.js' : '[name].iframe.bundle.js',
      publicPath: ''
    },
    watchOptions: {
      ignored: /node_modules/
    },
    plugins: [new _webpackFilterWarningsPlugin.default({
      exclude: /export '\S+' was not found in 'global'/
    }), Object.keys(virtualModuleMapping).length > 0 ? new _webpackVirtualModules.default(virtualModuleMapping) : null, new _htmlWebpackPlugin.default({
      filename: `iframe.html`,
      // FIXME: `none` isn't a known option
      chunksSortMode: 'none',
      alwaysWriteToDisk: true,
      inject: false,
      template: template,
      templateParameters: {
        version: packageJson.version,
        globals: {
          CONFIG_TYPE: configType,
          LOGLEVEL: logLevel,
          FRAMEWORK_OPTIONS: frameworkOptions,
          CHANNEL_OPTIONS: coreOptions === null || coreOptions === void 0 ? void 0 : coreOptions.channelOptions,
          FEATURES: features,
          PREVIEW_URL: previewUrl,
          STORIES: stories.map(function (specifier) {
            return _objectSpread(_objectSpread({}, specifier), {}, {
              importPathMatcher: specifier.importPathMatcher.source
            });
          }),
          SERVER_CHANNEL_URL: serverChannelUrl
        },
        headHtmlSnippet: headHtmlSnippet,
        bodyHtmlSnippet: bodyHtmlSnippet
      },
      minify: {
        collapseWhitespace: true,
        removeComments: true,
        removeRedundantAttributes: true,
        removeScriptTypeAttributes: false,
        removeStyleLinkTypeAttributes: true,
        useShortDoctype: true
      }
    }), new _webpack.DefinePlugin(_objectSpread(_objectSpread({}, (0, _coreCommon.stringifyProcessEnvs)(envs)), {}, {
      NODE_ENV: JSON.stringify(envs.NODE_ENV)
    })), isProd ? null : new _webpack.HotModuleReplacementPlugin(), new _caseSensitivePathsWebpackPlugin.default(), quiet ? null : new _webpack.ProgressPlugin({}), shouldCheckTs ? new _forkTsCheckerWebpackPlugin.default(tsCheckOptions) : null].filter(Boolean),
    module: {
      rules: [babelLoader, (0, _coreCommon.es6Transpiler)(), {
        test: /\.md$/,
        use: [{
          loader: require.resolve('raw-loader')
        }]
      }]
    },
    resolve: {
      extensions: ['.mjs', '.js', '.jsx', '.ts', '.tsx', '.json', '.cjs'],
      modules: ['node_modules'].concat(envs.NODE_PATH || []),
      mainFields: [modern ? 'sbmodern' : null, 'browser', 'module', 'main'].filter(Boolean),
      alias: _objectSpread(_objectSpread(_objectSpread({}, features !== null && features !== void 0 && features.emotionAlias ? _paths.default : {}), storybookPaths), {}, {
        react: _path.default.dirname(require.resolve('react/package.json')),
        'react-dom': _path.default.dirname(require.resolve('react-dom/package.json'))
      }),
      plugins: [// Transparently resolve packages via PnP when needed; noop otherwise
      _pnpWebpackPlugin.default]
    },
    resolveLoader: {
      plugins: [_pnpWebpackPlugin.default.moduleLoader(module)]
    },
    optimization: {
      splitChunks: {
        chunks: 'all'
      },
      runtimeChunk: true,
      sideEffects: true,
      usedExports: true,
      moduleIds: 'named',
      minimizer: isProd ? [new _terserWebpackPlugin.default({
        parallel: true,
        terserOptions: {
          sourceMap: true,
          mangle: false,
          keep_fnames: true
        }
      })] : []
    },
    performance: {
      hints: isProd ? 'warning' : false
    }
  };
};

exports.default = _default;