"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.normalizeCoreJSOption = normalizeCoreJSOption;
exports.default = normalizeOptions;
exports.validateUseBuiltInsOption = exports.validateModulesOption = exports.checkDuplicateIncludeExcludes = exports.normalizePluginName = void 0;

var _semver = require("semver");

var _corejs2BuiltIns = _interopRequireDefault(require("@babel/compat-data/corejs2-built-ins"));

var _pluginsCompatData = require("./plugins-compat-data");

var _moduleTransformations = _interopRequireDefault(require("./module-transformations"));

var _options = require("./options");

var _helperValidatorOption = require("@babel/helper-validator-option");

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

const corejs3Polyfills = require("core-js-compat/data.json");

const corejs2DefaultWebIncludes = ["web.timers", "web.immediate", "web.dom.iterable"];
const v = new _helperValidatorOption.OptionValidator("@babel/preset-env");
const allPluginsList = Object.keys(_pluginsCompatData.plugins);
const modulePlugins = ["proposal-dynamic-import", ...Object.keys(_moduleTransformations.default).map(m => _moduleTransformations.default[m])];

const getValidIncludesAndExcludes = (type, corejs) => new Set([...allPluginsList, ...(type === "exclude" ? modulePlugins : []), ...(corejs ? corejs == 2 ? [...Object.keys(_corejs2BuiltIns.default), ...corejs2DefaultWebIncludes] : Object.keys(corejs3Polyfills) : [])]);

const pluginToRegExp = plugin => {
  if (plugin instanceof RegExp) return plugin;

  try {
    return new RegExp(`^${normalizePluginName(plugin)}$`);
  } catch (e) {
    return null;
  }
};

const selectPlugins = (regexp, type, corejs) => Array.from(getValidIncludesAndExcludes(type, corejs)).filter(item => regexp instanceof RegExp && regexp.test(item));

const flatten = array => [].concat(...array);

const expandIncludesAndExcludes = (plugins = [], type, corejs) => {
  if (plugins.length === 0) return [];
  const selectedPlugins = plugins.map(plugin => selectPlugins(pluginToRegExp(plugin), type, corejs));
  const invalidRegExpList = plugins.filter((p, i) => selectedPlugins[i].length === 0);
  v.invariant(invalidRegExpList.length === 0, `The plugins/built-ins '${invalidRegExpList.join(", ")}' passed to the '${type}' option are not
    valid. Please check data/[plugin-features|built-in-features].js in babel-preset-env`);
  return flatten(selectedPlugins);
};

const normalizePluginName = plugin => plugin.replace(/^(@babel\/|babel-)(plugin-)?/, "");

exports.normalizePluginName = normalizePluginName;

const checkDuplicateIncludeExcludes = (include = [], exclude = []) => {
  const duplicates = include.filter(opt => exclude.indexOf(opt) >= 0);
  v.invariant(duplicates.length === 0, `The plugins/built-ins '${duplicates.join(", ")}' were found in both the "include" and
    "exclude" options.`);
};

exports.checkDuplicateIncludeExcludes = checkDuplicateIncludeExcludes;

const normalizeTargets = targets => {
  if (typeof targets === "string" || Array.isArray(targets)) {
    return {
      browsers: targets
    };
  }

  return Object.assign({}, targets);
};

const validateModulesOption = (modulesOpt = _options.ModulesOption.auto) => {
  v.invariant(_options.ModulesOption[modulesOpt.toString()] || modulesOpt === _options.ModulesOption.false, `The 'modules' option must be one of \n` + ` - 'false' to indicate no module processing\n` + ` - a specific module type: 'commonjs', 'amd', 'umd', 'systemjs'` + ` - 'auto' (default) which will automatically select 'false' if the current\n` + `   process is known to support ES module syntax, or "commonjs" otherwise\n`);
  return modulesOpt;
};

exports.validateModulesOption = validateModulesOption;

const validateUseBuiltInsOption = (builtInsOpt = false) => {
  v.invariant(_options.UseBuiltInsOption[builtInsOpt.toString()] || builtInsOpt === _options.UseBuiltInsOption.false, `The 'useBuiltIns' option must be either
    'false' (default) to indicate no polyfill,
    '"entry"' to indicate replacing the entry polyfill, or
    '"usage"' to import only used polyfills per file`);
  return builtInsOpt;
};

exports.validateUseBuiltInsOption = validateUseBuiltInsOption;

function normalizeCoreJSOption(corejs, useBuiltIns) {
  let proposals = false;
  let rawVersion;

  if (useBuiltIns && corejs === undefined) {
    rawVersion = 2;
    console.warn("\nWARNING (@babel/preset-env): We noticed you're using the `useBuiltIns` option without declaring a " + "core-js version. Currently, we assume version 2.x when no version " + "is passed. Since this default version will likely change in future " + "versions of Babel, we recommend explicitly setting the core-js version " + "you are using via the `corejs` option.\n" + "\nYou should also be sure that the version you pass to the `corejs` " + "option matches the version specified in your `package.json`'s " + "`dependencies` section. If it doesn't, you need to run one of the " + "following commands:\n\n" + "  npm install --save core-js@2    npm install --save core-js@3\n" + "  yarn add core-js@2              yarn add core-js@3\n\n" + "More info about useBuiltIns: https://babeljs.io/docs/en/babel-preset-env#usebuiltins\n" + "More info about core-js: https://babeljs.io/docs/en/babel-preset-env#corejs");
  } else if (typeof corejs === "object" && corejs !== null) {
    rawVersion = corejs.version;
    proposals = Boolean(corejs.proposals);
  } else {
    rawVersion = corejs;
  }

  const version = rawVersion ? (0, _semver.coerce)(String(rawVersion)) : false;

  if (!useBuiltIns && version) {
    console.warn("\nWARNING (@babel/preset-env): The `corejs` option only has an effect when the `useBuiltIns` option is not `false`\n");
  }

  if (useBuiltIns && (!version || version.major < 2 || version.major > 3)) {
    throw new RangeError("Invalid Option: The version passed to `corejs` is invalid. Currently, " + "only core-js@2 and core-js@3 are supported.");
  }

  return {
    version,
    proposals
  };
}

function normalizeOptions(opts) {
  v.validateTopLevelOptions(opts, _options.TopLevelOptions);
  const useBuiltIns = validateUseBuiltInsOption(opts.useBuiltIns);
  const corejs = normalizeCoreJSOption(opts.corejs, useBuiltIns);
  const include = expandIncludesAndExcludes(opts.include, _options.TopLevelOptions.include, !!corejs.version && corejs.version.major);
  const exclude = expandIncludesAndExcludes(opts.exclude, _options.TopLevelOptions.exclude, !!corejs.version && corejs.version.major);
  checkDuplicateIncludeExcludes(include, exclude);
  return {
    bugfixes: v.validateBooleanOption(_options.TopLevelOptions.bugfixes, opts.bugfixes, false),
    configPath: v.validateStringOption(_options.TopLevelOptions.configPath, opts.configPath, process.cwd()),
    corejs,
    debug: v.validateBooleanOption(_options.TopLevelOptions.debug, opts.debug, false),
    include,
    exclude,
    forceAllTransforms: v.validateBooleanOption(_options.TopLevelOptions.forceAllTransforms, opts.forceAllTransforms, false),
    ignoreBrowserslistConfig: v.validateBooleanOption(_options.TopLevelOptions.ignoreBrowserslistConfig, opts.ignoreBrowserslistConfig, false),
    loose: v.validateBooleanOption(_options.TopLevelOptions.loose, opts.loose),
    modules: validateModulesOption(opts.modules),
    shippedProposals: v.validateBooleanOption(_options.TopLevelOptions.shippedProposals, opts.shippedProposals, false),
    spec: v.validateBooleanOption(_options.TopLevelOptions.spec, opts.spec, false),
    targets: normalizeTargets(opts.targets),
    useBuiltIns: useBuiltIns,
    browserslistEnv: v.validateStringOption(_options.TopLevelOptions.browserslistEnv, opts.browserslistEnv)
  };
}