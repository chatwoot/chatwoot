'use strict';

Object.defineProperty(exports, '__esModule', {
  value: true
});
exports.run = run;

function _os() {
  const data = require('os');

  _os = function () {
    return data;
  };

  return data;
}

function path() {
  const data = _interopRequireWildcard(require('path'));

  path = function () {
    return data;
  };

  return data;
}

function _chalk() {
  const data = _interopRequireDefault(require('chalk'));

  _chalk = function () {
    return data;
  };

  return data;
}

function _yargs() {
  const data = _interopRequireDefault(require('yargs'));

  _yargs = function () {
    return data;
  };

  return data;
}

function _console() {
  const data = require('@jest/console');

  _console = function () {
    return data;
  };

  return data;
}

function _jestConfig() {
  const data = require('jest-config');

  _jestConfig = function () {
    return data;
  };

  return data;
}

function _jestUtil() {
  const data = require('jest-util');

  _jestUtil = function () {
    return data;
  };

  return data;
}

function _jestValidate() {
  const data = require('jest-validate');

  _jestValidate = function () {
    return data;
  };

  return data;
}

function _version() {
  const data = require('../version');

  _version = function () {
    return data;
  };

  return data;
}

var args = _interopRequireWildcard(require('./args'));

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
async function run(cliArgv, cliInfo) {
  let argv;

  if (cliArgv) {
    argv = cliArgv;
  } else {
    argv = _yargs()
      .default.usage(args.usage)
      .help(false)
      .version(false)
      .options(args.options).argv;
    (0, _jestValidate().validateCLIOptions)(argv, {
      ...args.options,
      deprecationEntries: _jestConfig().deprecationEntries
    });
  }

  if (argv.help) {
    _yargs().default.showHelp();

    process.on('exit', () => (process.exitCode = 1));
    return;
  }

  if (argv.version) {
    console.log(`v${_version().VERSION}\n`);
    return;
  }

  if (!argv._.length) {
    console.log('Please provide a path to a script. (See --help for details)');
    process.on('exit', () => (process.exitCode = 1));
    return;
  }

  const root = (0, _jestUtil().tryRealpath)(process.cwd());
  const filePath = path().resolve(root, argv._[0]);

  if (argv.debug) {
    const info = cliInfo ? ', ' + cliInfo.join(', ') : '';
    console.log(`Using Jest Runtime v${_version().VERSION}${info}`);
  }

  const options = await (0, _jestConfig().readConfig)(argv, root);
  const globalConfig = options.globalConfig; // Always disable automocking in scripts.

  const config = {...options.projectConfig, automock: false};

  const Runtime = require('..');

  try {
    var _runtime$unstable_sho2;

    const hasteMap = await Runtime.createContext(config, {
      maxWorkers: Math.max((0, _os().cpus)().length - 1, 1),
      watchman: globalConfig.watchman
    });

    const Environment = require(config.testEnvironment);

    const environment = new Environment(config);
    (0, _jestUtil().setGlobal)(
      environment.global,
      'console',
      new (_console().CustomConsole)(process.stdout, process.stderr)
    );
    (0, _jestUtil().setGlobal)(environment.global, 'jestProjectConfig', config);
    (0, _jestUtil().setGlobal)(
      environment.global,
      'jestGlobalConfig',
      globalConfig
    );
    const runtime = new Runtime(
      config,
      environment,
      hasteMap.resolver,
      undefined,
      undefined,
      filePath
    );

    for (const path of config.setupFiles) {
      var _runtime$unstable_sho;

      // TODO: remove ? in Jest 26
      const esm =
        (_runtime$unstable_sho = runtime.unstable_shouldLoadAsEsm) === null ||
        _runtime$unstable_sho === void 0
          ? void 0
          : _runtime$unstable_sho.call(runtime, path);

      if (esm) {
        await runtime.unstable_importModule(path);
      } else {
        runtime.requireModule(path);
      }
    } // TODO: remove ? in Jest 26

    const esm =
      (_runtime$unstable_sho2 = runtime.unstable_shouldLoadAsEsm) === null ||
      _runtime$unstable_sho2 === void 0
        ? void 0
        : _runtime$unstable_sho2.call(runtime, filePath);

    if (esm) {
      await runtime.unstable_importModule(filePath);
    } else {
      runtime.requireModule(filePath);
    }
  } catch (e) {
    console.error(_chalk().default.red(e.stack || e));
    process.on('exit', () => (process.exitCode = 1));
  }
}
