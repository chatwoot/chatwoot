import "core-js/modules/es.promise.js";
import fetch from 'node-fetch';
import chalk from 'chalk';
import { colors } from '@storybook/node-logger';
import semver from '@storybook/semver';
import dedent from 'ts-dedent';
import { cache } from '@storybook/core-common';
var _process$env = process.env,
    _process$env$STORYBOO = _process$env.STORYBOOK_VERSION_BASE,
    STORYBOOK_VERSION_BASE = _process$env$STORYBOO === void 0 ? 'https://storybook.js.org' : _process$env$STORYBOO,
    CI = _process$env.CI;
export var updateCheck = async function (version) {
  var result;
  var time = Date.now();

  try {
    var fromCache = await cache.get('lastUpdateCheck', {
      success: false,
      time: 0
    }); // if last check was more then 24h ago

    if (time - 86400000 > fromCache.time && !CI) {
      var fromFetch = await Promise.race([fetch(`${STORYBOOK_VERSION_BASE}/versions.json?current=${version}`), // if fetch is too slow, we won't wait for it
      new Promise(function (res, rej) {
        return global.setTimeout(rej, 1500);
      })]);
      var data = await fromFetch.json();
      result = {
        success: true,
        data: data,
        time: time
      };
      await cache.set('lastUpdateCheck', result);
    } else {
      result = fromCache;
    }
  } catch (error) {
    result = {
      success: false,
      error: error,
      time: time
    };
  }

  return result;
};
export function createUpdateMessage(updateInfo, version) {
  var updateMessage;

  try {
    var suffix = semver.prerelease(updateInfo.data.latest.version) ? '--prerelease' : '';
    var upgradeCommand = `npx storybook@latest upgrade ${suffix}`.trim();
    updateMessage = updateInfo.success && semver.lt(version, updateInfo.data.latest.version) ? dedent`
          ${colors.orange(`A new version (${chalk.bold(updateInfo.data.latest.version)}) is available!`)}

          ${chalk.gray('Upgrade now:')} ${colors.green(upgradeCommand)}

          ${chalk.gray('Read full changelog:')} ${chalk.gray.underline('https://github.com/storybookjs/storybook/blob/next/CHANGELOG.md')}
        ` : '';
  } catch (e) {
    updateMessage = '';
  }

  return updateMessage;
}