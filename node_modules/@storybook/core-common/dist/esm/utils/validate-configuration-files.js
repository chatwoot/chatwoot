import dedent from 'ts-dedent';
import deprecate from 'util-deprecate';
import glob from 'glob';
import path from 'path';
import { boost } from './interpret-files';
var warnLegacyConfigurationFiles = deprecate(function () {}, dedent`
    Configuration files such as "config", "presets" and "addons" are deprecated and will be removed in Storybook 7.0.
    Read more about it in the migration guide: https://github.com/storybookjs/storybook/blob/master/MIGRATION.md#to-mainjs-configuration
  `);

var errorMixingConfigFiles = function (first, second, configDir) {
  var firstPath = path.resolve(configDir, first);
  var secondPath = path.resolve(configDir, second);
  throw new Error(dedent`
    You have mixing configuration files:
    ${firstPath}
    ${secondPath}
    "${first}" and "${second}" cannot coexist.
    Please check the documentation for migration steps: https://github.com/storybookjs/storybook/blob/master/MIGRATION.md#to-mainjs-configuration
  `);
};

export function validateConfigurationFiles(configDir) {
  var extensionsPattern = `{${Array.from(boost).join(',')}}`;

  var exists = function (file) {
    return !!glob.sync(path.resolve(configDir, `${file}${extensionsPattern}`)).length;
  };

  var main = exists('main');
  var config = exists('config');

  if (!main && !config) {
    throw new Error(dedent`
      No configuration files have been found in your configDir (${path.resolve(configDir)}).
      Storybook needs either a "main" or "config" file.
    `);
  }

  if (main && config) {
    throw new Error(dedent`
      You have both a "main" and a "config". Please remove the "config" file from your configDir (${path.resolve(configDir, 'config')})`);
  }

  var presets = exists('presets');

  if (main && presets) {
    errorMixingConfigFiles('main', 'presets', configDir);
  }

  var preview = exists('preview');

  if (preview && config) {
    errorMixingConfigFiles('preview', 'config', configDir);
  }

  var addons = exists('addons');
  var manager = exists('manager');

  if (manager && addons) {
    errorMixingConfigFiles('manager', 'addons', configDir);
  }

  if (presets || config || addons) {
    warnLegacyConfigurationFiles();
  }
}