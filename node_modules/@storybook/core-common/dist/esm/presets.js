var _excluded = ["type", "name"],
    _excluded2 = ["addons", "presets", "framework"],
    _excluded3 = ["corePresets", "frameworkPresets", "overridePresets"];
import "core-js/modules/es.promise.js";

function _objectWithoutProperties(source, excluded) { if (source == null) return {}; var target = _objectWithoutPropertiesLoose(source, excluded); var key, i; if (Object.getOwnPropertySymbols) { var sourceSymbolKeys = Object.getOwnPropertySymbols(source); for (i = 0; i < sourceSymbolKeys.length; i++) { key = sourceSymbolKeys[i]; if (excluded.indexOf(key) >= 0) continue; if (!Object.prototype.propertyIsEnumerable.call(source, key)) continue; target[key] = source[key]; } } return target; }

function _objectWithoutPropertiesLoose(source, excluded) { if (source == null) return {}; var target = {}; var sourceKeys = Object.keys(source); var key, i; for (i = 0; i < sourceKeys.length; i++) { key = sourceKeys[i]; if (excluded.indexOf(key) >= 0) continue; target[key] = source[key]; } return target; }

function ownKeys(object, enumerableOnly) { var keys = Object.keys(object); if (Object.getOwnPropertySymbols) { var symbols = Object.getOwnPropertySymbols(object); enumerableOnly && (symbols = symbols.filter(function (sym) { return Object.getOwnPropertyDescriptor(object, sym).enumerable; })), keys.push.apply(keys, symbols); } return keys; }

function _objectSpread(target) { for (var i = 1; i < arguments.length; i++) { var source = null != arguments[i] ? arguments[i] : {}; i % 2 ? ownKeys(Object(source), !0).forEach(function (key) { _defineProperty(target, key, source[key]); }) : Object.getOwnPropertyDescriptors ? Object.defineProperties(target, Object.getOwnPropertyDescriptors(source)) : ownKeys(Object(source)).forEach(function (key) { Object.defineProperty(target, key, Object.getOwnPropertyDescriptor(source, key)); }); } return target; }

function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }

import dedent from 'ts-dedent';
import { resolve } from 'path';
import { logger } from '@storybook/node-logger';
import { loadCustomPresets } from './utils/load-custom-presets';
import { serverRequire } from './utils/interpret-require';
import { safeResolve, safeResolveFrom } from './utils/safeResolve';

var isObject = function (val) {
  return val != null && typeof val === 'object' && Array.isArray(val) === false;
};

var isFunction = function (val) {
  return typeof val === 'function';
};

export function filterPresetsConfig(presetsConfig) {
  return presetsConfig.filter(function (preset) {
    var presetName = typeof preset === 'string' ? preset : preset.name;
    return !/@storybook[\\\\/]preset-typescript/.test(presetName);
  });
}

function resolvePresetFunction(input, presetOptions, framework, storybookOptions) {
  var prepend = [framework].filter(Boolean);

  if (isFunction(input)) {
    return [...prepend, ...input(_objectSpread(_objectSpread({}, storybookOptions), presetOptions))];
  }

  if (Array.isArray(input)) {
    return [...prepend, ...input];
  }

  return [];
}
/**
 * Parse an addon into either a managerEntries or a preset. Throw on invalid input.
 *
 * Valid inputs:
 * - '@storybook/addon-actions/manager'
 *   =>  { type: 'virtual', item }
 *
 * - '@storybook/addon-docs/preset'
 *   =>  { type: 'presets', item }
 *
 * - '@storybook/addon-docs'
 *   =>  { type: 'presets', item: '@storybook/addon-docs/preset' }
 *
 * - { name: '@storybook/addon-docs(/preset)?', options: { ... } }
 *   =>  { type: 'presets', item: { name: '@storybook/addon-docs/preset', options } }
 */


export var resolveAddonName = function (configDir, name, options) {
  var r = name.startsWith('/') ? safeResolve : safeResolveFrom.bind(null, configDir);
  var resolved = r(name);

  if (name.match(/\/(manager|register(-panel)?)(\.(js|ts|tsx|jsx))?$/)) {
    return {
      type: 'virtual',
      name: name,
      managerEntries: [resolved]
    };
  }

  if (name.match(/\/(preset)(\.(js|ts|tsx|jsx))?$/)) {
    return {
      type: 'presets',
      name: resolved
    };
  }

  var path = name; // when user provides full path, we don't need to do anything!

  var managerFile = safeResolve(`${path}/manager`);
  var registerFile = safeResolve(`${path}/register`) || safeResolve(`${path}/register-panel`);
  var previewFile = safeResolve(`${path}/preview`);
  var presetFile = r(`${path}/preset`);

  if (!(managerFile || previewFile) && presetFile) {
    return {
      type: 'presets',
      name: presetFile
    };
  }

  if (managerFile || registerFile || previewFile || presetFile) {
    var managerEntries = [];

    if (managerFile) {
      managerEntries.push(managerFile);
    } // register file is the old way of registering addons


    if (!managerFile && registerFile && !presetFile) {
      managerEntries.push(registerFile);
    }

    return _objectSpread(_objectSpread(_objectSpread({
      type: 'virtual',
      name: path
    }, managerEntries.length ? {
      managerEntries: managerEntries
    } : {}), previewFile ? {
      previewAnnotations: [previewFile]
    } : {}), presetFile ? {
      presets: [{
        name: presetFile,
        options: options
      }]
    } : {});
  }

  return {
    type: 'presets',
    name: resolved
  };
};

var map = function ({
  configDir: configDir
}) {
  return function (item) {
    var options = isObject(item) ? item.options || undefined : undefined;
    var name = isObject(item) ? item.name : item;

    try {
      var resolved = resolveAddonName(configDir, name, options);
      return _objectSpread(_objectSpread({}, options ? {
        options: options
      } : {}), resolved);
    } catch (err) {
      logger.error(`Addon value should end in /manager or /preview or /register OR it should be a valid preset https://storybook.js.org/docs/react/addons/writing-presets/\n${item}`);
    }

    return undefined;
  };
};

function interopRequireDefault(filePath) {
  // eslint-disable-next-line global-require,import/no-dynamic-require
  var result = require(filePath);

  var isES6DefaultExported = typeof result === 'object' && result !== null && typeof result.default !== 'undefined';
  return isES6DefaultExported ? result.default : result;
}

function getContent(input) {
  if (input.type === 'virtual') {
    var type = input.type,
        _name = input.name,
        rest = _objectWithoutProperties(input, _excluded);

    return rest;
  }

  var name = input.name ? input.name : input;
  return interopRequireDefault(name);
}

export function loadPreset(input, level, storybookOptions) {
  try {
    // @ts-ignores
    var name = input.name ? input.name : input; // @ts-ignore

    var presetOptions = input.options ? input.options : {};
    var contents = getContent(input);

    if (typeof contents === 'function') {
      // allow the export of a preset to be a function, that gets storybookOptions
      contents = contents(storybookOptions, presetOptions);
    }

    if (Array.isArray(contents)) {
      var subPresets = contents;
      return loadPresets(subPresets, level + 1, storybookOptions);
    }

    if (isObject(contents)) {
      var _contents = contents,
          addonsInput = _contents.addons,
          presetsInput = _contents.presets,
          framework = _contents.framework,
          rest = _objectWithoutProperties(_contents, _excluded2);

      var _subPresets = resolvePresetFunction(presetsInput, presetOptions, framework, storybookOptions);

      var subAddons = resolvePresetFunction(addonsInput, presetOptions, framework, storybookOptions);
      return [...loadPresets([..._subPresets], level + 1, storybookOptions), ...loadPresets([...subAddons.map(map(storybookOptions))].filter(Boolean), level + 1, storybookOptions), {
        name: name,
        preset: rest,
        options: presetOptions
      }];
    }

    throw new Error(dedent`
      ${input} is not a valid preset
    `);
  } catch (e) {
    var warning = level > 0 ? `  Failed to load preset: ${JSON.stringify(input)} on level ${level}` : `  Failed to load preset: ${JSON.stringify(input)}`;
    logger.warn(warning);
    logger.error(e);
    return [];
  }
}

function loadPresets(presets, level, storybookOptions) {
  if (!presets || !Array.isArray(presets) || !presets.length) {
    return [];
  }

  if (!level) {
    logger.info('=> Loading presets');
  }

  return presets.reduce(function (acc, preset) {
    var loaded = loadPreset(preset, level, storybookOptions);
    return acc.concat(loaded);
  }, []);
}

function applyPresets(presets, extension, config, args, storybookOptions) {
  var presetResult = new Promise(function (res) {
    return res(config);
  });

  if (!presets.length) {
    return presetResult;
  }

  return presets.reduce(function (accumulationPromise, {
    preset: preset,
    options: options
  }) {
    var change = preset[extension];

    if (!change) {
      return accumulationPromise;
    }

    if (typeof change === 'function') {
      var extensionFn = change;
      var context = {
        preset: preset,
        combinedOptions: _objectSpread(_objectSpread(_objectSpread(_objectSpread({}, storybookOptions), args), options), {}, {
          presetsList: presets,
          presets: {
            apply: async function (ext, c, a = {}) {
              return applyPresets(presets, ext, c, a, storybookOptions);
            }
          }
        })
      };
      return accumulationPromise.then(function (newConfig) {
        return extensionFn.call(context.preset, newConfig, context.combinedOptions);
      });
    }

    return accumulationPromise.then(function (newConfig) {
      if (Array.isArray(newConfig) && Array.isArray(change)) {
        return [...newConfig, ...change];
      }

      if (isObject(newConfig) && isObject(change)) {
        return _objectSpread(_objectSpread({}, newConfig), change);
      }

      return change;
    });
  }, presetResult);
}

export function getPresets(presets, storybookOptions) {
  var loadedPresets = loadPresets(presets, 0, storybookOptions);
  return {
    apply: async function (extension, config, args = {}) {
      return applyPresets(loadedPresets, extension, config, args, storybookOptions);
    }
  };
}
/**
 * Get the `framework` provided in main.js and also do error checking up front
 */

var getFrameworkPackage = function (configDir) {
  var main = serverRequire(resolve(configDir, 'main'));
  if (!main) return null;
  var frameworkPackage = main.framework,
      _main$features = main.features,
      features = _main$features === void 0 ? {} : _main$features;

  if (features.breakingChangesV7 && !frameworkPackage) {
    throw new Error(dedent`
      Expected 'framework' in your main.js, didn't find one.

      You can fix this automatically by running:

      npx sb@next automigrate
    
      More info: https://github.com/storybookjs/storybook/blob/next/MIGRATION.md#mainjs-framework-field
    `);
  }

  return frameworkPackage;
};

export function loadAllPresets(options) {
  var _options$corePresets = options.corePresets,
      corePresets = _options$corePresets === void 0 ? [] : _options$corePresets,
      _options$frameworkPre = options.frameworkPresets,
      frameworkPresets = _options$frameworkPre === void 0 ? [] : _options$frameworkPre,
      _options$overridePres = options.overridePresets,
      overridePresets = _options$overridePres === void 0 ? [] : _options$overridePres,
      restOptions = _objectWithoutProperties(options, _excluded3);

  var frameworkPackage = getFrameworkPackage(options.configDir);
  var presetsConfig = [...corePresets, ...(frameworkPackage ? [] : frameworkPresets), ...loadCustomPresets(options), ...overridePresets]; // Remove `@storybook/preset-typescript` and add a warning if in use.

  var filteredPresetConfig = filterPresetsConfig(presetsConfig);

  if (filteredPresetConfig.length < presetsConfig.length) {
    logger.warn('Storybook now supports TypeScript natively. You can safely remove `@storybook/preset-typescript`.');
  }

  return getPresets(filteredPresetConfig, restOptions);
}