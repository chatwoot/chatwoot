const _excluded = ["cache"];

function _objectWithoutPropertiesLoose(source, excluded) { if (source == null) return {}; var target = {}; var sourceKeys = Object.keys(source); var key, i; for (i = 0; i < sourceKeys.length; i++) { key = sourceKeys[i]; if (excluded.indexOf(key) >= 0) continue; target[key] = source[key]; } return target; }

import { logger } from '@storybook/node-logger';
import fs from 'fs-extra';
import path from 'path';
import { stringify } from 'telejson';
// The main config file determines the managerConfig value, so is already handled.
// The other files don't affect the manager, so can be safely ignored.
const ignoredConfigFiles = [/^main\.(m?js|ts)$/, /^preview\.(m?js|ts)$/, /^preview-head\.html$/];
export const useManagerCache = async (cacheKey, options, managerConfig) => {
  const [cachedISOTime, cachedConfig] = await options.cache.get(cacheKey).then(str => str.match(/^([0-9TZ.:+-]+)_(.*)/).slice(1)).catch(() => []); // Drop the `cache` property because it'll change as a result of writing to the cache.

  const baseConfig = _objectWithoutPropertiesLoose(managerConfig, _excluded);

  const configString = stringify(baseConfig);
  await options.cache.set(cacheKey, `${new Date().toISOString()}_${configString}`);

  if (configString !== cachedConfig || !cachedISOTime) {
    logger.line(1); // force starting new line

    logger.info('=> Ignoring cached manager due to change in manager config');
    return false;
  } // Check the modification time for all files in the config dir (.storybook) and
  // don't use the cache if any file has been modified since the cache was created.


  const configFiles = await fs.readdir(options.configDir);
  const cacheCreationDate = new Date(cachedISOTime);

  try {
    await Promise.all(configFiles.map(async file => {
      if (ignoredConfigFiles.some(pattern => pattern.test(file))) return;
      const filepath = path.join(options.configDir, file);
      const {
        mtime: fileModificationDate
      } = await fs.stat(filepath);
      if (fileModificationDate > cacheCreationDate) throw filepath;
    }));
    return true;
  } catch (e) {
    if (e instanceof Error) throw e;
    logger.line(1); // force starting new line

    logger.info(`=> Ignoring cached manager due to change in ${e}`);
    return false;
  }
};
export const clearManagerCache = async (cacheKey, options) => {
  if (options.cache && options.cache.fileExists(cacheKey)) {
    await options.cache.remove(cacheKey);
    return true;
  }

  return false;
};