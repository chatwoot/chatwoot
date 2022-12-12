import "core-js/modules/es.promise.js";
import path from 'path';
import { getInterpretedFile, serverRequire } from '@storybook/core-common';
export async function getPreviewBuilder(configDir) {
  var main = path.resolve(configDir, 'main');
  var mainFile = getInterpretedFile(main);

  var _ref = mainFile ? serverRequire(mainFile) : {
    core: null
  },
      core = _ref.core;

  var builderPackage;

  if (core !== null && core !== void 0 && core.builder) {
    var _core$builder;

    var builderName = typeof core.builder === 'string' ? core.builder : (_core$builder = core.builder) === null || _core$builder === void 0 ? void 0 : _core$builder.name;
    builderPackage = require.resolve(['webpack4', 'webpack5'].includes(builderName) ? `@storybook/builder-${builderName}` : builderName, {
      paths: [main]
    });
  } else {
    builderPackage = require.resolve('@storybook/builder-webpack4');
  }

  var previewBuilder = await import(builderPackage);
  return previewBuilder;
}