import "core-js/modules/es.promise.js";
import path from 'path';
import { getInterpretedFile, serverRequire } from '@storybook/core-common';
export async function getManagerBuilder(configDir) {
  var _core$builder;

  var main = path.resolve(configDir, 'main');
  var mainFile = getInterpretedFile(main);

  var _ref = mainFile ? serverRequire(mainFile) : {
    core: null
  },
      core = _ref.core;

  var builderName = typeof (core === null || core === void 0 ? void 0 : core.builder) === 'string' ? core.builder : core === null || core === void 0 ? void 0 : (_core$builder = core.builder) === null || _core$builder === void 0 ? void 0 : _core$builder.name; // Builder can be any string including community builders like `storybook-builder-vite`.
  // - For now, `webpack5` triggers `manager-webpack5`
  // - Everything else builds with `manager-webpack4`
  //
  // Unlike preview builders, manager building is not pluggable!

  var builderPackage = ['webpack5', '@storybook/builder-webpack5'].includes(builderName) ? require.resolve('@storybook/manager-webpack5', {
    paths: [main]
  }) : '@storybook/manager-webpack4';
  var managerBuilder = await import(builderPackage);
  return managerBuilder;
}