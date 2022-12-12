import { checkAddonOrder, serverRequire } from '@storybook/core-common';
import path from 'path';
export const checkDocsLoaded = configDir => {
  checkAddonOrder({
    before: {
      name: '@storybook/addon-docs',
      inEssentials: true
    },
    after: {
      name: '@storybook/addon-controls',
      inEssentials: true
    },
    configFile: path.isAbsolute(configDir) ? path.join(configDir, 'main') : path.join(process.cwd(), configDir, 'main'),
    getConfig: configFile => serverRequire(configFile)
  });
};