"use strict";

function _templateObject7() {
  var data = _taggedTemplateLiteral(["\n          ", " Warning: Forcing a binary version different than the default.\n\n            The CLI expected to install version: ", "\n\n            Instead we will install version: ", "\n\n            These versions may not work properly together.\n        "]);

  _templateObject7 = function _templateObject7() {
    return data;
  };

  return data;
}

function _templateObject6() {
  var data = _taggedTemplateLiteral(["\n      Cypress ", " is installed in ", "\n      "]);

  _templateObject6 = function _templateObject6() {
    return data;
  };

  return data;
}

function _templateObject5() {
  var data = _taggedTemplateLiteral(["\n    Failed to access ", ":\n\n    ", "\n    "]);

  _templateObject5 = function _templateObject5() {
    return data;
  };

  return data;
}

function _templateObject4() {
  var data = _taggedTemplateLiteral(["\n        ", " Overriding Cypress cache directory to: ", "\n\n              Previous installs of Cypress may not be found.\n      "]);

  _templateObject4 = function _templateObject4() {
    return data;
  };

  return data;
}

function _templateObject3() {
  var data = _taggedTemplateLiteral(["\n        ", " Skipping binary installation: Environment variable CYPRESS_INSTALL_BINARY = 0."]);

  _templateObject3 = function _templateObject3() {
    return data;
  };

  return data;
}

function _templateObject2() {
  var data = _taggedTemplateLiteral(["\n      ", " Warning: It looks like you've installed Cypress globally.\n\n        This will work, but it's not recommended.\n\n        The recommended way to install Cypress is as a devDependency per project.\n\n        You should probably run these commands:\n\n        - ", "\n        - ", "\n    "], ["\n      ", " Warning: It looks like you\\'ve installed Cypress globally.\n\n        This will work, but it'\\s not recommended.\n\n        The recommended way to install Cypress is as a devDependency per project.\n\n        You should probably run these commands:\n\n        - ", "\n        - ", "\n    "]);

  _templateObject2 = function _templateObject2() {
    return data;
  };

  return data;
}

function _templateObject() {
  var data = _taggedTemplateLiteral(["\n      Skipping installation:\n\n        Pass the ", " option if you'd like to reinstall anyway.\n    "]);

  _templateObject = function _templateObject() {
    return data;
  };

  return data;
}

function _taggedTemplateLiteral(strings, raw) { if (!raw) { raw = strings.slice(0); } return Object.freeze(Object.defineProperties(strings, { raw: { value: Object.freeze(raw) } })); }

var _ = require('lodash');

var os = require('os');

var path = require('path');

var chalk = require('chalk');

var debug = require('debug')('cypress:cli');

var Listr = require('listr');

var verbose = require('@cypress/listr-verbose-renderer');

var Promise = require('bluebird');

var logSymbols = require('log-symbols');

var _require = require('common-tags'),
    stripIndent = _require.stripIndent;

var fs = require('../fs');

var download = require('./download');

var util = require('../util');

var state = require('./state');

var unzip = require('./unzip');

var logger = require('../logger');

var _require2 = require('../errors'),
    throwFormErrorText = _require2.throwFormErrorText,
    errors = _require2.errors;

var alreadyInstalledMsg = function alreadyInstalledMsg() {
  if (!util.isPostInstall()) {
    logger.log(stripIndent(_templateObject(), chalk.yellow('--force')));
  }
};

var displayCompletionMsg = function displayCompletionMsg() {
  // check here to see if we are globally installed
  if (util.isInstalledGlobally()) {
    // if we are display a warning
    logger.log();
    logger.warn(stripIndent(_templateObject2(), logSymbols.warning, chalk.cyan('npm uninstall -g cypress'), chalk.cyan('npm install --save-dev cypress')));
    return;
  }

  logger.log();
  logger.log('You can now open Cypress by running:', chalk.cyan(path.join('node_modules', '.bin', 'cypress'), 'open'));
  logger.log();
  logger.log(chalk.grey('https://on.cypress.io/installing-cypress'));
  logger.log();
};

var downloadAndUnzip = function downloadAndUnzip(_ref) {
  var version = _ref.version,
      installDir = _ref.installDir,
      downloadDir = _ref.downloadDir;
  var progress = {
    throttle: 100,
    onProgress: null
  };
  var downloadDestination = path.join(downloadDir, 'cypress.zip');
  var rendererOptions = getRendererOptions(); // let the user know what version of cypress we're downloading!

  logger.log("Installing Cypress ".concat(chalk.gray("(version: ".concat(version, ")"))));
  logger.log();
  var tasks = new Listr([{
    title: util.titleize('Downloading Cypress'),
    task: function task(ctx, _task) {
      // as our download progresses indicate the status
      progress.onProgress = progessify(_task, 'Downloading Cypress');
      return download.start({
        version: version,
        downloadDestination: downloadDestination,
        progress: progress
      }).then(function (redirectVersion) {
        if (redirectVersion) version = redirectVersion;
        debug("finished downloading file: ".concat(downloadDestination));
      }).then(function () {
        // save the download destination for unzipping
        util.setTaskTitle(_task, util.titleize(chalk.green('Downloaded Cypress')), rendererOptions.renderer);
      });
    }
  }, unzipTask({
    progress: progress,
    zipFilePath: downloadDestination,
    installDir: installDir,
    rendererOptions: rendererOptions
  }), {
    title: util.titleize('Finishing Installation'),
    task: function task(ctx, _task2) {
      var cleanup = function cleanup() {
        debug('removing zip file %s', downloadDestination);
        return fs.removeAsync(downloadDestination);
      };

      return cleanup().then(function () {
        debug('finished installation in', installDir);
        util.setTaskTitle(_task2, util.titleize(chalk.green('Finished Installation'), chalk.gray(installDir)), rendererOptions.renderer);
      });
    }
  }], rendererOptions); // start the tasks!

  return Promise.resolve(tasks.run());
};

var start = function start() {
  var options = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : {};

  // handle deprecated / removed
  if (util.getEnv('CYPRESS_BINARY_VERSION')) {
    return throwFormErrorText(errors.removed.CYPRESS_BINARY_VERSION)();
  }

  if (util.getEnv('CYPRESS_SKIP_BINARY_INSTALL')) {
    return throwFormErrorText(errors.removed.CYPRESS_SKIP_BINARY_INSTALL)();
  }

  debug('installing with options %j', options);

  _.defaults(options, {
    force: false
  });

  var pkgVersion = util.pkgVersion();
  var needVersion = pkgVersion;
  debug('version in package.json is', needVersion); // let this environment variable reset the binary version we need

  if (util.getEnv('CYPRESS_INSTALL_BINARY')) {
    // because passed file paths are often double quoted
    // and might have extra whitespace around, be robust and trim the string
    var trimAndRemoveDoubleQuotes = true;
    var envVarVersion = util.getEnv('CYPRESS_INSTALL_BINARY', trimAndRemoveDoubleQuotes);
    debug('using environment variable CYPRESS_INSTALL_BINARY "%s"', envVarVersion);

    if (envVarVersion === '0') {
      debug('environment variable CYPRESS_INSTALL_BINARY = 0, skipping install');
      logger.log(stripIndent(_templateObject3(), chalk.yellow('Note:')));
      logger.log();
      return Promise.resolve();
    } // if this doesn't match the expected version
    // then print warning to the user


    if (envVarVersion !== needVersion) {
      // reset the version to the env var version
      needVersion = envVarVersion;
    }
  }

  if (util.getEnv('CYPRESS_CACHE_FOLDER')) {
    var envCache = util.getEnv('CYPRESS_CACHE_FOLDER');
    logger.log(stripIndent(_templateObject4(), chalk.yellow('Note:'), chalk.cyan(envCache)));
    logger.log();
  }

  var installDir = state.getVersionDir(pkgVersion);
  var cacheDir = state.getCacheDir();
  var binaryDir = state.getBinaryDir(pkgVersion);
  return fs.ensureDirAsync(cacheDir)["catch"]({
    code: 'EACCES'
  }, function (err) {
    return throwFormErrorText(errors.invalidCacheDirectory)(stripIndent(_templateObject5(), chalk.cyan(cacheDir), err.message));
  }).then(function () {
    return state.getBinaryPkgVersionAsync(binaryDir);
  }).then(function (binaryVersion) {
    if (!binaryVersion) {
      debug('no binary installed under cli version');
      return true;
    }

    debug('installed version is', binaryVersion, 'version needed is', needVersion);
    logger.log();
    logger.log(stripIndent(_templateObject6(), chalk.green(binaryVersion), chalk.cyan(installDir)));
    logger.log();

    if (options.force) {
      debug('performing force install over existing binary');
      return true;
    }

    if (binaryVersion === needVersion || !util.isSemver(needVersion)) {
      // our version matches, tell the user this is a noop
      alreadyInstalledMsg();
      return false;
    }

    return true;
  }).then(function (shouldInstall) {
    // noop if we've been told not to download
    if (!shouldInstall) {
      debug('Not downloading or installing binary');
      return;
    }

    if (needVersion !== pkgVersion) {
      logger.log(chalk.yellow(stripIndent(_templateObject7(), logSymbols.warning, chalk.green(pkgVersion), chalk.green(needVersion))));
      logger.log();
    } // see if version supplied is a path to a binary


    return fs.pathExistsAsync(needVersion).then(function (exists) {
      if (exists) {
        return path.extname(needVersion) === '.zip' ? needVersion : false;
      }

      var possibleFile = util.formAbsolutePath(needVersion);
      debug('checking local file', possibleFile, 'cwd', process.cwd());
      return fs.pathExistsAsync(possibleFile).then(function (exists) {
        // if this exists return the path to it
        // else false
        if (exists && path.extname(possibleFile) === '.zip') {
          return possibleFile;
        }

        return false;
      });
    }).then(function (pathToLocalFile) {
      if (pathToLocalFile) {
        var absolutePath = path.resolve(needVersion);
        debug('found local file at', absolutePath);
        debug('skipping download');
        var rendererOptions = getRendererOptions();
        return new Listr([unzipTask({
          progress: {
            throttle: 100,
            onProgress: null
          },
          zipFilePath: absolutePath,
          installDir: installDir,
          rendererOptions: rendererOptions
        })], rendererOptions).run();
      }

      if (options.force) {
        debug('Cypress already installed at', installDir);
        debug('but the installation was forced');
      }

      debug('preparing to download and unzip version ', needVersion, 'to path', installDir);
      var downloadDir = os.tmpdir();
      return downloadAndUnzip({
        version: needVersion,
        installDir: installDir,
        downloadDir: downloadDir
      });
    }) // delay 1 sec for UX, unless we are testing
    .then(function () {
      return Promise.delay(1000);
    }).then(displayCompletionMsg);
  });
};

module.exports = {
  start: start
};

var unzipTask = function unzipTask(_ref2) {
  var zipFilePath = _ref2.zipFilePath,
      installDir = _ref2.installDir,
      progress = _ref2.progress,
      rendererOptions = _ref2.rendererOptions;
  return {
    title: util.titleize('Unzipping Cypress'),
    task: function task(ctx, _task3) {
      // as our unzip progresses indicate the status
      progress.onProgress = progessify(_task3, 'Unzipping Cypress');
      return unzip.start({
        zipFilePath: zipFilePath,
        installDir: installDir,
        progress: progress
      }).then(function () {
        util.setTaskTitle(_task3, util.titleize(chalk.green('Unzipped Cypress')), rendererOptions.renderer);
      });
    }
  };
};

var progessify = function progessify(task, title) {
  // return higher order function
  return function (percentComplete, remaining) {
    percentComplete = chalk.white(" ".concat(percentComplete, "%")); // pluralize seconds remaining

    remaining = chalk.gray("".concat(remaining, "s"));
    util.setTaskTitle(task, util.titleize(title, percentComplete, remaining), getRendererOptions().renderer);
  };
}; // if we are running in CI then use
// the verbose renderer else use
// the default


var getRendererOptions = function getRendererOptions() {
  var renderer = util.isCi() ? verbose : 'default';

  if (logger.logLevel() === 'silent') {
    renderer = 'silent';
  }

  return {
    renderer: renderer
  };
};