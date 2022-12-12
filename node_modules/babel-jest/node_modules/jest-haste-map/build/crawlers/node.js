'use strict';

function path() {
  const data = _interopRequireWildcard(require('path'));

  path = function () {
    return data;
  };

  return data;
}

function _child_process() {
  const data = require('child_process');

  _child_process = function () {
    return data;
  };

  return data;
}

function fs() {
  const data = _interopRequireWildcard(require('graceful-fs'));

  fs = function () {
    return data;
  };

  return data;
}

function _which() {
  const data = _interopRequireDefault(require('which'));

  _which = function () {
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
async function hasNativeFindSupport(forceNodeFilesystemAPI) {
  if (forceNodeFilesystemAPI || process.platform === 'win32') {
    return false;
  }

  try {
    await (0, _which().default)('find');
    return true;
  } catch (_unused) {
    return false;
  }
}

function find(roots, extensions, ignore, callback) {
  const result = [];
  let activeCalls = 0;

  function search(directory) {
    activeCalls++;
    fs().readdir(
      directory,
      {
        withFileTypes: true
      },
      (err, entries) => {
        activeCalls--;

        if (err) {
          callback(result);
          return;
        } // node < v10.10 does not support the withFileTypes option, and
        // entry will be a string.

        entries.forEach(entry => {
          const file = path().join(
            directory,
            typeof entry === 'string' ? entry : entry.name
          );

          if (ignore(file)) {
            return;
          }

          if (typeof entry !== 'string') {
            if (entry.isSymbolicLink()) {
              return;
            }

            if (entry.isDirectory()) {
              search(file);
              return;
            }
          }

          activeCalls++;
          fs().lstat(file, (err, stat) => {
            activeCalls--; // This logic is unnecessary for node > v10.10, but leaving it in
            // since we need it for backwards-compatibility still.

            if (!err && stat && !stat.isSymbolicLink()) {
              if (stat.isDirectory()) {
                search(file);
              } else {
                const ext = path().extname(file).substr(1);

                if (extensions.indexOf(ext) !== -1) {
                  result.push([file, stat.mtime.getTime(), stat.size]);
                }
              }
            }

            if (activeCalls === 0) {
              callback(result);
            }
          });
        });

        if (activeCalls === 0) {
          callback(result);
        }
      }
    );
  }

  if (roots.length > 0) {
    roots.forEach(search);
  } else {
    callback(result);
  }
}

function findNative(roots, extensions, ignore, callback) {
  const args = Array.from(roots);
  args.push('-type', 'f');

  if (extensions.length) {
    args.push('(');
  }

  extensions.forEach((ext, index) => {
    if (index) {
      args.push('-o');
    }

    args.push('-iname');
    args.push('*.' + ext);
  });

  if (extensions.length) {
    args.push(')');
  }

  const child = (0, _child_process().spawn)('find', args);
  let stdout = '';

  if (child.stdout === null) {
    throw new Error(
      'stdout is null - this should never happen. Please open up an issue at https://github.com/facebook/jest'
    );
  }

  child.stdout.setEncoding('utf-8');
  child.stdout.on('data', data => (stdout += data));
  child.stdout.on('close', () => {
    const lines = stdout
      .trim()
      .split('\n')
      .filter(x => !ignore(x));
    const result = [];
    let count = lines.length;

    if (!count) {
      callback([]);
    } else {
      lines.forEach(path => {
        fs().stat(path, (err, stat) => {
          if (!err && stat) {
            result.push([path, stat.mtime.getTime(), stat.size]);
          }

          if (--count === 0) {
            callback(result);
          }
        });
      });
    }
  });
}

module.exports = async function nodeCrawl(options) {
  const {
    data,
    extensions,
    forceNodeFilesystemAPI,
    ignore,
    rootDir,
    roots
  } = options;
  const useNativeFind = await hasNativeFindSupport(forceNodeFilesystemAPI);
  return new Promise(resolve => {
    const callback = list => {
      const files = new Map();
      const removedFiles = new Map(data.files);
      list.forEach(fileData => {
        const [filePath, mtime, size] = fileData;
        const relativeFilePath = fastPath().relative(rootDir, filePath);
        const existingFile = data.files.get(relativeFilePath);

        if (
          existingFile &&
          existingFile[_constants().default.MTIME] === mtime
        ) {
          files.set(relativeFilePath, existingFile);
        } else {
          // See ../constants.js; SHA-1 will always be null and fulfilled later.
          files.set(relativeFilePath, ['', mtime, size, 0, '', null]);
        }

        removedFiles.delete(relativeFilePath);
      });
      data.files = files;
      resolve({
        hasteMap: data,
        removedFiles
      });
    };

    if (useNativeFind) {
      findNative(roots, extensions, ignore, callback);
    } else {
      find(roots, extensions, ignore, callback);
    }
  });
};
