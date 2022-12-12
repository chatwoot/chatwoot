import "core-js/modules/es.array.find.js";
import "core-js/modules/es.object.to-string.js";
import "core-js/modules/es.object.keys.js";
import "core-js/modules/es.array.join.js";
import fs from 'fs-extra';
import path from 'path';
import { getProjectRoot } from '@storybook/core-common';
export var monorepoConfigs = {
  Nx: 'nx.json',
  Turborepo: 'turbo.json',
  Lerna: 'lerna.json',
  Rush: 'rush.json',
  Lage: 'lage.config.json'
};
export var getMonorepoType = function getMonorepoType() {
  var projectRootPath = getProjectRoot();
  if (!projectRootPath) return undefined;
  var monorepoType = Object.keys(monorepoConfigs).find(function (monorepo) {
    var configFile = path.join(projectRootPath, monorepoConfigs[monorepo]);
    return fs.existsSync(configFile);
  });

  if (monorepoType) {
    return monorepoType;
  }

  if (!fs.existsSync(path.join(projectRootPath, 'package.json'))) return undefined;
  var packageJson = fs.readJsonSync(path.join(projectRootPath, 'package.json'));

  if (packageJson !== null && packageJson !== void 0 && packageJson.workspaces) {
    return 'Workspaces';
  }

  return undefined;
};