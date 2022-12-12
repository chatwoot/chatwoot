import { pathExists } from 'fs-extra';
import path from 'path';
import { getInterpretedFile, loadManagerOrAddonsFile, serverRequire } from '@storybook/core-common';
import { getAutoRefs } from '../manager-config'; // Addons automatically installed when running `sb init` (see baseGenerator.ts)

export const DEFAULT_ADDONS = ['@storybook/addon-links', '@storybook/addon-essentials']; // Addons we can safely ignore because they don't affect the manager

export const IGNORED_ADDONS = ['@storybook/preset-create-react-app', '@storybook/preset-scss', '@storybook/preset-typescript', ...DEFAULT_ADDONS];
export const getPrebuiltDir = async options => {
  const {
    configDir,
    smokeTest,
    managerCache
  } = options;
  if (managerCache === false || smokeTest) return false;
  const prebuiltDir = path.join(__dirname, '../../../prebuilt');
  const hasPrebuiltManager = await pathExists(path.join(prebuiltDir, 'index.html'));
  if (!hasPrebuiltManager) return false;
  const hasManagerConfig = !!loadManagerOrAddonsFile({
    configDir
  });
  if (hasManagerConfig) return false;
  const mainConfigFile = getInterpretedFile(path.resolve(configDir, 'main'));
  if (!mainConfigFile) return false;
  const {
    addons,
    refs,
    managerBabel,
    managerWebpack,
    features
  } = serverRequire(mainConfigFile);
  if (!addons || refs || managerBabel || managerWebpack || features) return false;
  if (DEFAULT_ADDONS.some(addon => !addons.includes(addon))) return false;
  if (addons.some(addon => !IGNORED_ADDONS.includes(addon))) return false; // Auto refs will not be listed in the config, so we have to verify there aren't any

  const autoRefs = await getAutoRefs(options);
  if (autoRefs.length > 0) return false;
  return prebuiltDir;
};