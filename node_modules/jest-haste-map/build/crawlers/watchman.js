'use strict';

function path() {
  const data = _interopRequireWildcard(require('path'));

  path = function () {
    return data;
  };

  return data;
}

function _fbWatchman() {
  const data = _interopRequireDefault(require('fb-watchman'));

  _fbWatchman = function () {
    return data;
  };

  return data;
}

function _constants() {
  const data = _interopRequireDefault(require('../constants'));

  _constants = function () {
    return data;
  };

  return data;
}

function fastPath() {
  const data = _interopRequireWildcard(require('../lib/fast_path'));

  fastPath = function () {
    return data;
  };

  return data;
}

function _normalizePathSep() {
  const data = _interopRequireDefault(require('../lib/normalizePathSep'));

  _normalizePathSep = function () {
    return data;
  };

  return data;
}

function _interopRequireDefault(obj) {
  return obj && obj.__esModule ? obj : {default: obj};
}

function _getRequireWildcardCache() {
  if (typeof WeakMap !== 'function') return null;
  var cache = new WeakMap();
  _getRequireWildcardCache = function () {
    return cache;
  };
  return cache;
}

function _interopRequireWildcard(obj) {
  if (obj && obj.__esModule) {
    return obj;
  }
  if (obj === null || (typeof obj !== 'object' && typeof obj !== 'function')) {
    return {default: obj};
  }
  var cache = _getRequireWildcardCache();
  if (cache && cache.has(obj)) {
    return cache.get(obj);
  }
  var newObj = {};
  var hasPropertyDescriptor =
    Object.defineProperty && Object.getOwnPropertyDescriptor;
  for (var key in obj) {
    if (Object.prototype.hasOwnProperty.call(obj, key)) {
      var desc = hasPropertyDescriptor
        ? Object.getOwnPropertyDescriptor(obj, key)
        : null;
      if (desc && (desc.get || desc.set)) {
        Object.defineProperty(newObj, key, desc);
      } else {
        newObj[key] = obj[key];
      }
    }
  }
  newObj.default = obj;
  if (cache) {
    cache.set(obj, newObj);
  }
  return newObj;
}

/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
const watchmanURL = 'https://facebook.github.io/watchman/docs/troubleshooting';

function WatchmanError(error) {
  error.message =
    `Watchman error: ${error.message.trim()}. Make sure watchman ` +
    `is running for this project. See ${watchmanURL}.`;
  return error;
}

module.exports = async function watchmanCrawl(options) {
  const fields = ['name', 'exists', 'mtime_ms', 'size'];
  const {data, extensions, ignore, rootDir, roots} = options;
  const defaultWatchExpression = [
    'allof',
    ['type', 'f'],
    ['anyof', ...extensions.map(extension => ['suffix', extension])]
  ];
  const clocks = data.clocks;
  const client = new (_fbWatchman().default.Client)();
  let clientError;
  client.on('error', error => (clientError = WatchmanError(error))); // TODO: type better than `any`

  const cmd = (...args) =>
    new Promise((resolve, reject) =>
      client.command(args, (error, result) =>
        error ? reject(WatchmanError(error)) : resolve(result)
      )
    );

  if (options.computeSha1) {
    const {capabilities} = await cmd('list-capabilities');

    if (capabilities.indexOf('field-content.sha1hex') !== -1) {
      fields.push('content.sha1hex');
    }
  }

  async function getWatchmanRoots(roots) {
    const watchmanRoots = new Map();
    await Promise.all(
      roots.map(async root => {
        const response = await cmd('watch-project', root);
        const existing = watchmanRoots.get(response.watch); // A root can only be filtered if it was never seen with a
        // relative_path before.

        const canBeFiltered = !existing || existing.length > 0;

        if (canBeFiltered) {
          if (response.relative_path) {
            watchmanRoots.set(
              response.watch,
              (existing || []).concat(response.relative_path)
            );
          } else {
            // Make the filter directories an empty array to signal that this
            // root was already seen and needs to be watched for all files or
            // directories.
            watchmanRoots.set(response.watch, []);
          }
        }
      })
    );
    return watchmanRoots;
  }

  async function queryWatchmanForDirs(rootProjectDirMappings) {
    const files = new Map();
    let isFresh = false;
    await Promise.all(
      Array.from(rootProjectDirMappings).map(
        async ([root, directoryFilters]) => {
          const expression = Array.from(defaultWatchExpression);
          const glob = [];

          if (directoryFilters.length > 0) {
            expression.push([
              'anyof',
              ...directoryFilters.map(dir => ['dirname', dir])
            ]);

            for (const directory of directoryFilters) {
              for (const extension of extensions) {
                glob.push(`${directory}/**/*.${extension}`);
              }
            }
          } else {
            for (const extension of extensions) {
              glob.push(`**/*.${extension}`);
            }
          }

          const relativeRoot = fastPath().relative(rootDir, root);
          const query = clocks.has(relativeRoot) // Use the `since` generator if we have a clock available
            ? {
                expression,
                fields,
                since: clocks.get(relativeRoot)
              } // Otherwise use the `glob` filter
            : {
                expression,
                fields,
                glob,
                glob_includedotfiles: true
              };
          const response = await cmd('query', root, query);

          if ('warning' in response) {
            console.warn('watchman warning: ', response.warning);
          }

          isFresh = isFresh || response.is_fresh_instance;
          files.set(root, response);
        }
      )
    );
    return {
      files,
      isFresh
    };
  }

  let files = data.files;
  let removedFiles = new Map();
  const changedFiles = new Map();
  let watchmanFiles;
  let isFresh = false;

  try {
    const watchmanRoots = await getWatchmanRoots(roots);
    const watchmanFileResults = await queryWatchmanForDirs(watchmanRoots); // Reset the file map if watchman was restarted and sends us a list of
    // files.

    if (watchmanFileResults.isFresh) {
      files = new Map();
      removedFiles = new Map(data.files);
      isFresh = true;
    }

    watchmanFiles = watchmanFileResults.files;
  } finally {
    client.end();
  }

  if (clientError) {
    throw clientError;
  } // TODO: remove non-null

  for (const [watchRoot, response] of watchmanFiles) {
    const fsRoot = (0, _normalizePathSep().default)(watchRoot);
    const relativeFsRoot = fastPath().relative(rootDir, fsRoot);
    clocks.set(relativeFsRoot, response.clock);

    for (const fileData of response.files) {
      const filePath =
        fsRoot + path().sep + (0, _normalizePathSep().default)(fileData.name);
      const relativeFilePath = fastPath().relative(rootDir, filePath);
      const existingFileData = data.files.get(relativeFilePath); // If watchman is fresh, the removed files map starts with all files
      // and we remove them as we verify they still exist.

      if (isFresh && existingFileData && fileData.exists) {
        removedFiles.delete(relativeFilePath);
      }

      if (!fileData.exists) {
        // No need to act on files that do not exist and were not tracked.
        if (existingFileData) {
          files.delete(relativeFilePath); // If watchman is not fresh, we will know what specific files were
          // deleted since we last ran and can track only those files.

          if (!isFresh) {
            removedFiles.set(relativeFilePath, existingFileData);
          }
        }
      } else if (!ignore(filePath)) {
        const mtime =
          typeof fileData.mtime_ms === 'number'
            ? fileData.mtime_ms
            : fileData.mtime_ms.toNumber();
        const size = fileData.size;
        let sha1hex = fileData['content.sha1hex'];

        if (typeof sha1hex !== 'string' || sha1hex.length !== 40) {
          sha1hex = null;
        }

        let nextData;

        if (
          existingFileData &&
          existingFileData[_constants().default.MTIME] === mtime
        ) {
          nextData = existingFileData;
        } else if (
          existingFileData &&
          sha1hex &&
          existingFileData[_constants().default.SHA1] === sha1hex
        ) {
          nextData = [
            existingFileData[0],
            mtime,
            existingFileData[2],
            existingFileData[3],
            existingFileData[4],
            existingFileData[5]
          ];
        } else {
          // See ../constants.ts
          nextData = ['', mtime, size, 0, '', sha1hex];
        }

        files.set(relativeFilePath, nextData);
        changedFiles.set(relativeFilePath, nextData);
      }
    }
  }

  data.files = files;
  return {
    changedFiles: isFresh ? undefined : changedFiles,
    hasteMap: data,
    removedFiles
  };
};
