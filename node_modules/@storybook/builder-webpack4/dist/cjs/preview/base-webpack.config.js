"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.createDefaultWebpackConfig = createDefaultWebpackConfig;

require("core-js/modules/es.promise.js");

var _autoprefixer = _interopRequireDefault(require("autoprefixer"));

var _findUp = _interopRequireDefault(require("find-up"));

var _path = _interopRequireDefault(require("path"));

var _nodeLogger = require("@storybook/node-logger");

var _utilDeprecate = _interopRequireDefault(require("util-deprecate"));

var _tsDedent = _interopRequireDefault(require("ts-dedent"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function ownKeys(object, enumerableOnly) { var keys = Object.keys(object); if (Object.getOwnPropertySymbols) { var symbols = Object.getOwnPropertySymbols(object); enumerableOnly && (symbols = symbols.filter(function (sym) { return Object.getOwnPropertyDescriptor(object, sym).enumerable; })), keys.push.apply(keys, symbols); } return keys; }

function _objectSpread(target) { for (var i = 1; i < arguments.length; i++) { var source = null != arguments[i] ? arguments[i] : {}; i % 2 ? ownKeys(Object(source), !0).forEach(function (key) { _defineProperty(target, key, source[key]); }) : Object.getOwnPropertyDescriptors ? Object.defineProperties(target, Object.getOwnPropertyDescriptors(source)) : ownKeys(Object(source)).forEach(function (key) { Object.defineProperty(target, key, Object.getOwnPropertyDescriptor(source, key)); }); } return target; }

function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }

var warnImplicitPostcssPlugins = (0, _utilDeprecate.default)(function () {
  return {
    // Additional config is merged with config, so we have it disabled currently
    config: false,
    plugins: [require('postcss-flexbugs-fixes'), // eslint-disable-line global-require
    (0, _autoprefixer.default)({
      flexbox: 'no-2009'
    })]
  };
}, (0, _tsDedent.default)`
    Default PostCSS plugins are deprecated. When switching to '@storybook/addon-postcss',
    you will need to add your own plugins, such as 'postcss-flexbugs-fixes' and 'autoprefixer'.

    See https://github.com/storybookjs/storybook/blob/next/MIGRATION.md#deprecated-default-postcss-plugins for details.
  `);
var warnGetPostcssOptions = (0, _utilDeprecate.default)(function () {}, (0, _tsDedent.default)`
    Relying on the implicit PostCSS loader is deprecated and will be removed in Storybook 7.0.
    If you need PostCSS, include '@storybook/addon-postcss' in your '.storybook/main.js' file.

    See https://github.com/storybookjs/storybook/blob/next/MIGRATION.md#deprecated-implicit-postcss-loader for details.
    `);

var getPostcssOptions = async function () {
  var postcssConfigFiles = ['.postcssrc', '.postcssrc.json', '.postcssrc.yml', '.postcssrc.js', 'postcss.config.js']; // This is done naturally by newer postcss-loader (through cosmiconfig)

  var customPostcssConfig = await (0, _findUp.default)(postcssConfigFiles);

  if (customPostcssConfig) {
    _nodeLogger.logger.info(`=> Using custom ${_path.default.basename(customPostcssConfig)}`);

    warnGetPostcssOptions();
    return {
      config: customPostcssConfig
    };
  }

  return warnImplicitPostcssPlugins();
};

var presetName = function (preset) {
  return typeof preset === 'string' ? preset : preset.name;
};

async function createDefaultWebpackConfig(storybookBaseConfig, options) {
  if (options.presetsList.some(function (preset) {
    return /@storybook(\/|\\)preset-create-react-app/.test(presetName(preset));
  })) {
    return storybookBaseConfig;
  }

  var hasPostcssAddon = options.presetsList.some(function (preset) {
    return /@storybook(\/|\\)addon-postcss/.test(presetName(preset));
  });
  var features = await options.presets.apply('features');
  var cssLoaders = {};

  if (!hasPostcssAddon) {
    _nodeLogger.logger.info(`=> Using implicit CSS loaders`);

    var use = [// TODO(blaine): Decide if we want to keep style-loader & css-loader in core
    // Trying to apply style-loader or css-loader to files that already have been
    // processed by them causes webpack to crash, so no one else can add similar
    // loader configurations to the `.css` extension.
    require.resolve('style-loader'), {
      loader: require.resolve('css-loader'),
      options: {
        importLoaders: 1
      }
    }, (features === null || features === void 0 ? void 0 : features.postcss) !== false ? {
      loader: require.resolve('postcss-loader'),
      options: {
        postcssOptions: await getPostcssOptions()
      }
    } : null];
    cssLoaders = {
      test: /\.css$/,
      sideEffects: true,
      use: use.filter(Boolean)
    };
  }

  var isProd = storybookBaseConfig.mode !== 'development';
  return _objectSpread(_objectSpread({}, storybookBaseConfig), {}, {
    module: _objectSpread(_objectSpread({}, storybookBaseConfig.module), {}, {
      rules: [...storybookBaseConfig.module.rules, cssLoaders, {
        test: /\.(svg|ico|jpg|jpeg|png|apng|gif|eot|otf|webp|ttf|woff|woff2|cur|ani|pdf)(\?.*)?$/,
        loader: require.resolve('file-loader'),
        options: {
          esModule: false,
          name: isProd ? 'static/media/[name].[contenthash:8].[ext]' : 'static/media/[path][name].[ext]'
        }
      }, {
        test: /\.(mp4|webm|wav|mp3|m4a|aac|oga)(\?.*)?$/,
        loader: require.resolve('url-loader'),
        options: {
          limit: 10000,
          name: isProd ? 'static/media/[name].[contenthash:8].[ext]' : 'static/media/[path][name].[ext]'
        }
      }]
    })
  });
}