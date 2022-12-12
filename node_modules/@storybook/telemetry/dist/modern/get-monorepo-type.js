import fs from 'fs-extra';
import path from 'path';
import { getProjectRoot } from '@storybook/core-common';
export const monorepoConfigs = {
  Nx: 'nx.json',
  Turborepo: 'turbo.json',
  Lerna: 'lerna.json',
  Rush: 'rush.json',
  Lage: 'lage.config.json'
};
export const getMonorepoType = () => {
  const projectRootPath = getProjectRoot();
  if (!projectRootPath) return undefined;
  const monorepoType = Object.keys(monorepoConfigs).find(monorepo => {
    const configFile = path.join(projectRootPath, monorepoConfigs[monorepo]);
    return fs.existsSync(configFile);
  });

  if (monorepoType) {
    return monorepoType;
  }

  if (!fs.existsSync(path.join(projectRootPath, 'package.json'))) return undefined;
  const packageJson = fs.readJsonSync(path.join(projectRootPath, 'package.json'));

  if (packageJson !== null && packageJson !== void 0 && packageJson.workspaces) {
    return 'Workspaces';
  }

  return undefined;
};