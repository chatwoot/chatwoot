"use strict";

var _ = require('lodash');

var la = require('lazy-ass');

var is = require('check-more-types');

var cp = require('child_process');

var os = require('os');

var yauzl = require('yauzl');

var debug = require('debug')('cypress:cli:unzip');

var extract = require('extract-zip');

var Promise = require('bluebird');

var readline = require('readline');

var _require = require('../errors'),
    throwFormErrorText = _require.throwFormErrorText,
    errors = _require.errors;

var fs = require('../fs');

var util = require('../util');

var unzipTools = {
  extract: extract
}; // expose this function for simple testing

var unzip = function unzip(_ref) {
  var zipFilePath = _ref.zipFilePath,
      installDir = _ref.installDir,
      progress = _ref.progress;
  debug('unzipping from %s', zipFilePath);
  debug('into', installDir);

  if (!zipFilePath) {
    throw new Error('Missing zip filename');
  }

  var startTime = Date.now();
  var yauzlDoneTime = 0;
  return fs.ensureDirAsync(installDir).then(function () {
    return new Promise(function (resolve, reject) {
      return yauzl.open(zipFilePath, function (err, zipFile) {
        yauzlDoneTime = Date.now();

        if (err) {
          debug('error using yauzl %s', err.message);
          return reject(err);
        }

        var total = zipFile.entryCount;
        debug('zipFile entries count', total);
        var started = new Date();
        var percent = 0;
        var count = 0;

        var notify = function notify(percent) {
          var elapsed = +new Date() - +started;
          var eta = util.calculateEta(percent, elapsed);
          progress.onProgress(percent, util.secsRemaining(eta));
        };

        var tick = function tick() {
          count += 1;
          percent = count / total * 100;
          var displayPercent = percent.toFixed(0);
          return notify(displayPercent);
        };

        var unzipWithNode = function unzipWithNode() {
          debug('unzipping with node.js (slow)');

          var endFn = function endFn(err) {
            if (err) {
              debug('error %s', err.message);
              return reject(err);
            }

            debug('node unzip finished');
            return resolve();
          };

          var opts = {
            dir: installDir,
            onEntry: tick
          };
          debug('calling Node extract tool %s %o', zipFilePath, opts);
          return unzipTools.extract(zipFilePath, opts, endFn);
        };

        var unzipFallback = _.once(unzipWithNode);

        var unzipWithUnzipTool = function unzipWithUnzipTool() {
          debug('unzipping via `unzip`');
          var inflatingRe = /inflating:/;
          var sp = cp.spawn('unzip', ['-o', zipFilePath, '-d', installDir]);
          sp.on('error', function (err) {
            debug('unzip tool error: %s', err.message);
            unzipFallback();
          });
          sp.on('close', function (code) {
            debug('unzip tool close with code %d', code);

            if (code === 0) {
              percent = 100;
              notify(percent);
              return resolve();
            }

            debug('`unzip` failed %o', {
              code: code
            });
            return unzipFallback();
          });
          sp.stdout.on('data', function (data) {
            if (inflatingRe.test(data)) {
              return tick();
            }
          });
          sp.stderr.on('data', function (data) {
            debug('`unzip` stderr %s', data);
          });
        }; // we attempt to first unzip with the native osx
        // ditto because its less likely to have problems
        // with corruption, symlinks, or icons causing failures
        // and can handle resource forks
        // http://automatica.com.au/2011/02/unzip-mac-os-x-zip-in-terminal/


        var unzipWithOsx = function unzipWithOsx() {
          debug('unzipping via `ditto`');
          var copyingFileRe = /^copying file/;
          var sp = cp.spawn('ditto', ['-xkV', zipFilePath, installDir]); // f-it just unzip with node

          sp.on('error', function (err) {
            debug(err.message);
            unzipFallback();
          });
          sp.on('close', function (code) {
            if (code === 0) {
              // make sure we get to 100% on the progress bar
              // because reading in lines is not really accurate
              percent = 100;
              notify(percent);
              return resolve();
            }

            debug('`ditto` failed %o', {
              code: code
            });
            return unzipFallback();
          });
          return readline.createInterface({
            input: sp.stderr
          }).on('line', function (line) {
            if (copyingFileRe.test(line)) {
              return tick();
            }
          });
        };

        switch (os.platform()) {
          case 'darwin':
            return unzipWithOsx();

          case 'linux':
            return unzipWithUnzipTool();

          case 'win32':
            return unzipWithNode();

          default:
            return;
        }
      });
    }).tap(function () {
      debug('unzip completed %o', {
        yauzlMs: yauzlDoneTime - startTime,
        unzipMs: Date.now() - yauzlDoneTime
      });
    });
  });
};

var start = function start(_ref2) {
  var zipFilePath = _ref2.zipFilePath,
      installDir = _ref2.installDir,
      progress = _ref2.progress;
  la(is.unemptyString(installDir), 'missing installDir');

  if (!progress) {
    progress = {
      onProgress: function onProgress() {
        return {};
      }
    };
  }

  return fs.pathExists(installDir).then(function (exists) {
    if (exists) {
      debug('removing existing unzipped binary', installDir);
      return fs.removeAsync(installDir);
    }
  }).then(function () {
    return unzip({
      zipFilePath: zipFilePath,
      installDir: installDir,
      progress: progress
    });
  })["catch"](throwFormErrorText(errors.failedUnzip));
};

module.exports = {
  start: start,
  utils: {
    unzip: unzip,
    unzipTools: unzipTools
  }
};