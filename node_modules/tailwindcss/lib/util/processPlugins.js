"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = _default;

var _lodash = _interopRequireDefault(require("lodash"));

var _postcss = _interopRequireDefault(require("postcss"));

var _browserslist = _interopRequireDefault(require("browserslist"));

var _node = _interopRequireDefault(require("postcss/lib/node"));

var _isFunction = _interopRequireDefault(require("lodash/isFunction"));

var _escapeClassName = _interopRequireDefault(require("../util/escapeClassName"));

var _generateVariantFunction = _interopRequireDefault(require("../util/generateVariantFunction"));

var _parseObjectStyles = _interopRequireDefault(require("../util/parseObjectStyles"));

var _prefixSelector = _interopRequireDefault(require("../util/prefixSelector"));

var _wrapWithVariants = _interopRequireDefault(require("../util/wrapWithVariants"));

var _cloneNodes = _interopRequireDefault(require("../util/cloneNodes"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function parseStyles(styles) {
  if (!Array.isArray(styles)) {
    return parseStyles([styles]);
  }

  return _lodash.default.flatMap(styles, style => style instanceof _node.default ? style : (0, _parseObjectStyles.default)(style));
}

function wrapWithLayer(rules, layer) {
  return _postcss.default.atRule({
    name: 'layer',
    params: layer
  }).append((0, _cloneNodes.default)(Array.isArray(rules) ? rules : [rules]));
}

function isKeyframeRule(rule) {
  return rule.parent && rule.parent.type === 'atrule' && /keyframes$/.test(rule.parent.name);
}

function _default(plugins, config) {
  const pluginBaseStyles = [];
  const pluginComponents = [];
  const pluginUtilities = [];
  const pluginVariantGenerators = {};

  const applyConfiguredPrefix = selector => {
    return (0, _prefixSelector.default)(config.prefix, selector);
  };

  const getConfigValue = (path, defaultValue) => path ? _lodash.default.get(config, path, defaultValue) : config;

  const browserslistTarget = (0, _browserslist.default)().includes('ie 11') ? 'ie11' : 'relaxed';
  plugins.forEach(plugin => {
    if (plugin.__isOptionsFunction) {
      plugin = plugin();
    }

    const handler = (0, _isFunction.default)(plugin) ? plugin : _lodash.default.get(plugin, 'handler', () => {});
    handler({
      postcss: _postcss.default,
      config: getConfigValue,
      theme: (path, defaultValue) => {
        const value = getConfigValue(`theme.${path}`, defaultValue);

        const [rootPath] = _lodash.default.toPath(path);

        if (['fontSize', 'outline'].includes(rootPath)) {
          return Array.isArray(value) ? value[0] : value;
        }

        return value;
      },
      corePlugins: path => {
        if (Array.isArray(config.corePlugins)) {
          return config.corePlugins.includes(path);
        }

        return getConfigValue(`corePlugins.${path}`, true);
      },
      variants: (path, defaultValue) => {
        if (Array.isArray(config.variants)) {
          return config.variants;
        }

        return getConfigValue(`variants.${path}`, defaultValue);
      },
      target: path => {
        if (_lodash.default.isString(config.target)) {
          return config.target === 'browserslist' ? browserslistTarget : config.target;
        }

        const [defaultTarget, targetOverrides] = getConfigValue('target', 'relaxed');

        const target = _lodash.default.get(targetOverrides, path, defaultTarget);

        return target === 'browserslist' ? browserslistTarget : target;
      },
      e: _escapeClassName.default,
      prefix: applyConfiguredPrefix,
      addUtilities: (utilities, options) => {
        const defaultOptions = {
          variants: [],
          respectPrefix: true,
          respectImportant: true
        };
        options = Array.isArray(options) ? Object.assign({}, defaultOptions, {
          variants: options
        }) : _lodash.default.defaults(options, defaultOptions);

        const styles = _postcss.default.root({
          nodes: parseStyles(utilities)
        });

        styles.walkRules(rule => {
          if (options.respectPrefix && !isKeyframeRule(rule)) {
            rule.selector = applyConfiguredPrefix(rule.selector);
          }

          if (options.respectImportant && config.important) {
            rule.__tailwind = { ...rule.__tailwind,
              important: config.important
            };
          }
        });
        pluginUtilities.push(wrapWithLayer((0, _wrapWithVariants.default)(styles.nodes, options.variants), 'utilities'));
      },
      addComponents: (components, options) => {
        const defaultOptions = {
          variants: [],
          respectPrefix: true
        };
        options = Array.isArray(options) ? Object.assign({}, defaultOptions, {
          variants: options
        }) : _lodash.default.defaults(options, defaultOptions);

        const styles = _postcss.default.root({
          nodes: parseStyles(components)
        });

        styles.walkRules(rule => {
          if (options.respectPrefix && !isKeyframeRule(rule)) {
            rule.selector = applyConfiguredPrefix(rule.selector);
          }
        });
        pluginComponents.push(wrapWithLayer((0, _wrapWithVariants.default)(styles.nodes, options.variants), 'components'));
      },
      addBase: baseStyles => {
        pluginBaseStyles.push(wrapWithLayer(parseStyles(baseStyles), 'base'));
      },
      addVariant: (name, generator, options = {}) => {
        pluginVariantGenerators[name] = (0, _generateVariantFunction.default)(generator, options);
      }
    });
  });
  return {
    base: pluginBaseStyles,
    components: pluginComponents,
    utilities: pluginUtilities,
    variantGenerators: pluginVariantGenerators
  };
}