"use strict";

function _templateObject5() {
  var data = _taggedTemplateLiteral(["\n\n\n      ", " Warning: Binary version ", " does not match the expected package version ", "\n\n        These versions may not work properly together.\n      "]);

  _templateObject5 = function _templateObject5() {
    return data;
  };

  return data;
}

function _templateObject4() {
  var data = _taggedTemplateLiteral(["\n          The supplied binary path is not executable\n          "]);

  _templateObject4 = function _templateObject4() {
    return data;
  };

  return data;
}

function _templateObject3() {
  var data = _taggedTemplateLiteral(["\n      ", " You have set the environment variable:\n\n      ", "", "\n\n      This overrides the default Cypress binary path used.\n    "]);

  _templateObject3 = function _templateObject3() {
    return data;
  };

  return data;
}

function _templateObject2() {
  var data = _taggedTemplateLiteral(["\n    It looks like this is your first time using Cypress: ", "\n    "]);

  _templateObject2 = function _templateObject2() {
    return data;
  };

  return data;
}

function _templateObject() {
  var data = _taggedTemplateLiteral(["\n      Cypress executable not found at: ", "\n    "]);

  _templateObject = function _templateObject() {
    return data;
  };

  return data;
}

function _taggedTemplateLiteral(strings, raw) { if (!raw) { raw = strings.slice(0); } return Object.freeze(Object.defineProperties(strings, { raw: { value: Object.freeze(raw) } })); }

var _ = require('lodash');

var chalk = require('chalk');

var Listr = require('listr');

var debug = require('debug')('cypress:cli');

var verbose = require('@cypress/listr-verbose-renderer');

var _require = require('common-tags'),
    stripIndent = _require.stripIndent;

var Promise = require('bluebird');

var logSymbols = require('log-symbols');

var path = require('path');

var os = require('os');

var _require2 = require('../errors'),
    throwFormErrorText = _require2.throwFormErrorText,
    errors = _require2.errors;

var util = require('../util');

var logger = require('../logger');

var xvfb = require('../exec/xvfb');

var state = require('./state');

var VERIFY_TEST_RUNNER_TIMEOUT_MS = 30000;

var checkExecutable = function checkExecutable(binaryDir) {
  var executable = state.getPathToExecutable(binaryDir);
  debug('checking if executable exists', executable);
  return util.isExecutableAsync(executable).then(function (isExecutable) {
    debug('Binary is executable? :', isExecutable);

    if (!isExecutable) {
      return throwFormErrorText(errors.binaryNotExecutable(executable))();
    }
  })["catch"]({
    code: 'ENOENT'
  }, function () {
    if (util.isCi()) {
      return throwFormErrorText(errors.notInstalledCI(executable))();
    }

    return throwFormErrorText(errors.missingApp(binaryDir))(stripIndent(_templateObject(), chalk.cyan(executable)));
  });
};

var runSmokeTest = function runSmokeTest(binaryDir, options) {
  var executable = state.getPathToExecutable(binaryDir);

  var onSmokeTestError = function onSmokeTestError(smokeTestCommand, linuxWithDisplayEnv) {
    return function (err) {
      debug('Smoke test failed:', err);
      var errMessage = err.stderr || err.message;
      debug('error message:', errMessage);

      if (err.timedOut) {
        debug('error timedOut is true');
        return throwFormErrorText(errors.smokeTestFailure(smokeTestCommand, true))(errMessage);
      }

      if (linuxWithDisplayEnv && util.isBrokenGtkDisplay(errMessage)) {
        util.logBrokenGtkDisplayWarning();
        return throwFormErrorText(errors.invalidSmokeTestDisplayError)(errMessage);
      }

      return throwFormErrorText(errors.missingDependency)(errMessage);
    };
  };

  var needsXvfb = xvfb.isNeeded();
  debug('needs Xvfb?', needsXvfb);
  /**
   * Spawn Cypress running smoke test to check if all operating system
   * dependencies are good.
   */

  var spawn = function spawn(linuxWithDisplayEnv) {
    var random = _.random(0, 1000);

    var args = ['--smoke-test', "--ping=".concat(random)];

    if (needsSandbox()) {
      // electron requires --no-sandbox to run as root
      debug('disabling Electron sandbox');
      args.unshift('--no-sandbox');
    }

    if (options.dev) {
      executable = 'node';
      args.unshift(path.resolve(__dirname, '..', '..', '..', 'scripts', 'start.js'));
    }

    var smokeTestCommand = "".concat(executable, " ").concat(args.join(' '));
    debug('running smoke test');
    debug('using Cypress executable %s', executable);
    debug('smoke test command:', smokeTestCommand);
    debug('smoke test timeout %d ms', options.smokeTestTimeout);

    var env = _.extend({}, process.env, {
      ELECTRON_ENABLE_LOGGING: true
    });

    var stdioOptions = _.extend({}, {
      env: env,
      timeout: options.smokeTestTimeout
    });

    return Promise.resolve(util.exec(executable, args, stdioOptions))["catch"](onSmokeTestError(smokeTestCommand, linuxWithDisplayEnv)).then(function (result) {
      // TODO: when execa > 1.1 is released
      // change this to `result.all` for both stderr and stdout
      // use lodash to be robust during tests against null result or missing stdout
      var smokeTestStdout = _.get(result, 'stdout', '');

      debug('smoke test stdout "%s"', smokeTestStdout);

      if (!util.stdoutLineMatches(String(random), smokeTestStdout)) {
        debug('Smoke test failed because could not find %d in:', random, result);

        var smokeTestStderr = _.get(result, 'stderr', '');

        var errorText = smokeTestStderr || smokeTestStdout;
        return throwFormErrorText(errors.smokeTestFailure(smokeTestCommand, false))(errorText);
      }
    });
  };

  var spawnInXvfb = function spawnInXvfb(linuxWithDisplayEnv) {
    return xvfb.start().then(function () {
      return spawn(linuxWithDisplayEnv);
    })["finally"](xvfb.stop);
  };

  var userFriendlySpawn = function userFriendlySpawn(linuxWithDisplayEnv) {
    debug('spawning, should retry on display problem?', Boolean(linuxWithDisplayEnv));
    return spawn(linuxWithDisplayEnv)["catch"]({
      code: 'INVALID_SMOKE_TEST_DISPLAY_ERROR'
    }, function () {
      return spawnInXvfb(linuxWithDisplayEnv);
    });
  };

  if (needsXvfb) {
    return spawnInXvfb();
  } // if we are on linux and there's already a DISPLAY
  // set, then we may need to rerun cypress after
  // spawning our own Xvfb server


  var linuxWithDisplayEnv = util.isPossibleLinuxWithIncorrectDisplay();
  return userFriendlySpawn(linuxWithDisplayEnv);
};

function testBinary(version, binaryDir, options) {
  debug('running binary verification check', version); // if running from 'cypress verify', don't print this message

  if (!options.force) {
    logger.log(stripIndent(_templateObject2(), chalk.cyan(version)));
  }

  logger.log(); // if we are running in CI then use
  // the verbose renderer else use
  // the default

  var renderer = util.isCi() ? verbose : 'default';
  if (logger.logLevel() === 'silent') renderer = 'silent';
  var rendererOptions = {
    renderer: renderer
  };
  var tasks = new Listr([{
    title: util.titleize('Verifying Cypress can run', chalk.gray(binaryDir)),
    task: function task(ctx, _task) {
      debug('clearing out the verified version');
      return state.clearBinaryStateAsync(binaryDir).then(function () {
        return Promise.all([runSmokeTest(binaryDir, options), Promise.resolve().delay(1500) // good user experience
        ]);
      }).then(function () {
        debug('write verified: true');
        return state.writeBinaryVerifiedAsync(true, binaryDir);
      }).then(function () {
        util.setTaskTitle(_task, util.titleize(chalk.green('Verified Cypress!'), chalk.gray(binaryDir)), rendererOptions.renderer);
      });
    }
  }], rendererOptions);
  return tasks.run();
}

var maybeVerify = function maybeVerify(installedVersion, binaryDir, options) {
  return state.getBinaryVerifiedAsync(binaryDir).then(function (isVerified) {
    debug('is Verified ?', isVerified);
    var shouldVerify = !isVerified; // force verify if options.force

    if (options.force) {
      debug('force verify');
      shouldVerify = true;
    }

    if (shouldVerify) {
      return testBinary(installedVersion, binaryDir, options).then(function () {
        if (options.welcomeMessage) {
          logger.log();
          logger.log('Opening Cypress...');
        }
      });
    }
  });
};

var start = function start() {
  var options = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : {};
  debug('verifying Cypress app');
  var packageVersion = util.pkgVersion();
  var binaryDir = state.getBinaryDir(packageVersion);

  _.defaults(options, {
    dev: false,
    force: false,
    welcomeMessage: true,
    smokeTestTimeout: VERIFY_TEST_RUNNER_TIMEOUT_MS
  });

  if (options.dev) {
    return runSmokeTest('', options);
  }

  var parseBinaryEnvVar = function parseBinaryEnvVar() {
    var envBinaryPath = util.getEnv('CYPRESS_RUN_BINARY');
    debug('CYPRESS_RUN_BINARY exists, =', envBinaryPath);
    logger.log(stripIndent(_templateObject3(), chalk.yellow('Note:'), chalk.white('CYPRESS_RUN_BINARY='), chalk.cyan(envBinaryPath)));
    logger.log();
    return util.isExecutableAsync(envBinaryPath).then(function (isExecutable) {
      debug('CYPRESS_RUN_BINARY is executable? :', isExecutable);

      if (!isExecutable) {
        return throwFormErrorText(errors.CYPRESS_RUN_BINARY.notValid(envBinaryPath))(stripIndent(_templateObject4()));
      }
    }).then(function () {
      return state.parseRealPlatformBinaryFolderAsync(envBinaryPath);
    }).then(function (envBinaryDir) {
      if (!envBinaryDir) {
        return throwFormErrorText(errors.CYPRESS_RUN_BINARY.notValid(envBinaryPath))();
      }

      debug('CYPRESS_RUN_BINARY has binaryDir:', envBinaryDir);
      binaryDir = envBinaryDir;
    })["catch"]({
      code: 'ENOENT'
    }, function (err) {
      return throwFormErrorText(errors.CYPRESS_RUN_BINARY.notValid(envBinaryPath))(err.message);
    });
  };

  return Promise["try"](function () {
    debug('checking environment variables');

    if (util.getEnv('CYPRESS_RUN_BINARY')) {
      return parseBinaryEnvVar();
    }
  }).then(function () {
    return checkExecutable(binaryDir);
  }).tap(function () {
    return debug('binaryDir is ', binaryDir);
  }).then(function () {
    return state.getBinaryPkgVersionAsync(binaryDir);
  }).then(function (binaryVersion) {
    if (!binaryVersion) {
      debug('no Cypress binary found for cli version ', packageVersion);
      return throwFormErrorText(errors.missingApp(binaryDir))("\n      Cannot read binary version from: ".concat(chalk.cyan(state.getBinaryPkgPath(binaryDir)), "\n    "));
    }

    debug("Found binary version ".concat(chalk.green(binaryVersion), " installed in: ").concat(chalk.cyan(binaryDir)));

    if (binaryVersion !== packageVersion) {
      // warn if we installed with CYPRESS_INSTALL_BINARY or changed version
      // in the package.json
      logger.log("Found binary version ".concat(chalk.green(binaryVersion), " installed in: ").concat(chalk.cyan(binaryDir)));
      logger.log();
      logger.warn(stripIndent(_templateObject5(), logSymbols.warning, chalk.green(binaryVersion), chalk.green(packageVersion)));
      logger.log();
    }

    return maybeVerify(binaryVersion, binaryDir, options);
  })["catch"](function (err) {
    if (err.known) {
      throw err;
    }

    return throwFormErrorText(errors.unexpected)(err.stack);
  });
};

var isLinuxLike = function isLinuxLike() {
  return os.platform() !== 'win32';
};
/**
 * Returns true if running on a system where Electron needs "--no-sandbox" flag.
 * @see https://crbug.com/638180
 *
 * On Debian we had problems running in sandbox even for non-root users.
 * @see https://github.com/cypress-io/cypress/issues/5434
 * Seems there is a lot of discussion around this issue among Electron users
 * @see https://github.com/electron/electron/issues/17972
*/


var needsSandbox = function needsSandbox() {
  return isLinuxLike();
};

module.exports = {
  start: start,
  VERIFY_TEST_RUNNER_TIMEOUT_MS: VERIFY_TEST_RUNNER_TIMEOUT_MS,
  needsSandbox: needsSandbox
};