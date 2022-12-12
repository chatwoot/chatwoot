import "core-js/modules/es.promise.js";

function ownKeys(object, enumerableOnly) { var keys = Object.keys(object); if (Object.getOwnPropertySymbols) { var symbols = Object.getOwnPropertySymbols(object); enumerableOnly && (symbols = symbols.filter(function (sym) { return Object.getOwnPropertyDescriptor(object, sym).enumerable; })), keys.push.apply(keys, symbols); } return keys; }

function _objectSpread(target) { for (var i = 1; i < arguments.length; i++) { var source = null != arguments[i] ? arguments[i] : {}; i % 2 ? ownKeys(Object(source), !0).forEach(function (key) { _defineProperty(target, key, source[key]); }) : Object.getOwnPropertyDescriptors ? Object.defineProperties(target, Object.getOwnPropertyDescriptors(source)) : ownKeys(Object(source)).forEach(function (key) { Object.defineProperty(target, key, Object.getOwnPropertyDescriptor(source, key)); }); } return target; }

function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }

import path from 'path';
import { DefinePlugin, HotModuleReplacementPlugin, ProgressPlugin } from 'webpack'; // @ts-ignore

import HtmlWebpackPlugin from 'html-webpack-plugin';
import CaseSensitivePathsPlugin from 'case-sensitive-paths-webpack-plugin';
import TerserWebpackPlugin from 'terser-webpack-plugin';
import VirtualModulePlugin from 'webpack-virtual-modules';
import PnpWebpackPlugin from 'pnp-webpack-plugin';
import ForkTsCheckerWebpackPlugin from 'fork-ts-checker-webpack-plugin'; // @ts-ignore

import FilterWarningsPlugin from 'webpack-filter-warnings-plugin';
import themingPaths from '@storybook/theming/paths';
import { toRequireContextString, stringifyProcessEnvs, es6Transpiler, handlebars, interpolate, toImportFn, normalizeStories, loadPreviewOrConfigFile, readTemplate } from '@storybook/core-common';
import { createBabelLoader } from './babel-loader-preview';
import { useBaseTsSupport } from './useBaseTsSupport';
var storybookPaths = ['addons', 'api', 'channels', 'channel-postmessage', 'components', 'core-events', 'router', 'theming', 'semver', 'client-api', 'client-logger', 'preview-web', 'store'].reduce(function (acc, sbPackage) {
  return _objectSpread(_objectSpread({}, acc), {}, {
    [`@storybook/${sbPackage}`]: path.dirname(require.resolve(`@storybook/${sbPackage}/package.json`))
  });
}, {});
export default (async function (options) {
  var babelOptions = options.babelOptions,
      _options$outputDir = options.outputDir,
      outputDir = _options$outputDir === void 0 ? path.join('.', 'public') : _options$outputDir,
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
  var babelLoader = createBabelLoader(babelOptions, framework);
  var isProd = configType === 'PRODUCTION';
  var configs = [...(await presets.apply('config', [], options)), loadPreviewOrConfigFile(options)].filter(Boolean);
  var entries = await presets.apply('entries', [], options);
  var workingDir = process.cwd();
  var stories = normalizeStories(await presets.apply('stories', [], options), {
    configDir: options.configDir,
    workingDir: workingDir
  });
  var virtualModuleMapping = {};

  if (features !== null && features !== void 0 && features.storyStoreV7) {
    var storiesFilename = 'storybook-stories.js';
    var storiesPath = path.resolve(path.join(workingDir, storiesFilename));
    virtualModuleMapping[storiesPath] = toImportFn(stories);
    var configEntryPath = path.resolve(path.join(workingDir, 'storybook-config-entry.js'));
    virtualModuleMapping[configEntryPath] = handlebars(await readTemplate(require.resolve('@storybook/builder-webpack4/templates/virtualModuleModernEntry.js.handlebars')), {
      storiesFilename: storiesFilename,
      configs: configs
    } // We need to double escape `\` for webpack. We may have some in windows paths
    ).replace(/\\/g, '\\\\');
    entries.push(configEntryPath);
  } else {
    var frameworkInitEntry = path.resolve(path.join(workingDir, 'storybook-init-framework-entry.js'));
    var frameworkImportPath = frameworkPath || `@storybook/${framework}`;
    virtualModuleMapping[frameworkInitEntry] = `import '${frameworkImportPath}';`;
    entries.push(frameworkInitEntry);
    var entryTemplate = await readTemplate(path.join(__dirname, 'virtualModuleEntry.template.js'));
    configs.forEach(function (configFilename) {
      var clientApi = storybookPaths['@storybook/client-api'];
      var clientLogger = storybookPaths['@storybook/client-logger'];
      virtualModuleMapping[`${configFilename}-generated-config-entry.js`] = interpolate(entryTemplate, {
        configFilename: configFilename,
        clientApi: clientApi,
        clientLogger: clientLogger
      });
      entries.push(`${configFilename}-generated-config-entry.js`);
    });

    if (stories.length > 0) {
      var storyTemplate = await readTemplate(path.join(__dirname, 'virtualModuleStory.template.js'));

      var _storiesFilename = path.resolve(path.join(workingDir, `generated-stories-entry.js`));

      virtualModuleMapping[_storiesFilename] = interpolate(storyTemplate, {
        frameworkImportPath: frameworkImportPath
      }) // Make sure we also replace quotes for this one
      .replace("'{{stories}}'", stories.map(toRequireContextString).join(','));
      entries.push(_storiesFilename);
    }
  }

  var shouldCheckTs = useBaseTsSupport(framework) && typescriptOptions.check;
  var tsCheckOptions = typescriptOptions.checkOptions || {};
  return {
    name: 'preview',
    mode: isProd ? 'production' : 'development',
    bail: isProd,
    devtool: 'cheap-module-source-map',
    entry: entries,
    // stats: 'errors-only',
    output: {
      path: path.resolve(process.cwd(), outputDir),
      filename: isProd ? '[name].[contenthash:8].iframe.bundle.js' : '[name].iframe.bundle.js',
      publicPath: ''
    },
    watchOptions: {
      ignored: /node_modules/
    },
    plugins: [new FilterWarningsPlugin({
      exclude: /export '\S+' was not found in 'global'/
    }), Object.keys(virtualModuleMapping).length > 0 ? new VirtualModulePlugin(virtualModuleMapping) : null, new HtmlWebpackPlugin({
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
    }), new DefinePlugin(_objectSpread(_objectSpread({}, stringifyProcessEnvs(envs)), {}, {
      NODE_ENV: JSON.stringify(envs.NODE_ENV)
    })), isProd ? null : new HotModuleReplacementPlugin(), new CaseSensitivePathsPlugin(), quiet ? null : new ProgressPlugin({}), shouldCheckTs ? new ForkTsCheckerWebpackPlugin(tsCheckOptions) : null].filter(Boolean),
    module: {
      rules: [babelLoader, es6Transpiler(), {
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
      alias: _objectSpread(_objectSpread(_objectSpread({}, features !== null && features !== void 0 && features.emotionAlias ? themingPaths : {}), storybookPaths), {}, {
        react: path.dirname(require.resolve('react/package.json')),
        'react-dom': path.dirname(require.resolve('react-dom/package.json'))
      }),
      plugins: [// Transparently resolve packages via PnP when needed; noop otherwise
      PnpWebpackPlugin]
    },
    resolveLoader: {
      plugins: [PnpWebpackPlugin.moduleLoader(module)]
    },
    optimization: {
      splitChunks: {
        chunks: 'all'
      },
      runtimeChunk: true,
      sideEffects: true,
      usedExports: true,
      moduleIds: 'named',
      minimizer: isProd ? [new TerserWebpackPlugin({
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
});