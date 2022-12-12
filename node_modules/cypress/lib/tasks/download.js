"use strict";

function _templateObject5() {
  var data = _taggedTemplateLiteral(["\n          Failed downloading the Cypress binary.\n          Response code: ", "\n          Response message: ", "\n        "]);

  _templateObject5 = function _templateObject5() {
    return data;
  };

  return data;
}

function _templateObject4() {
  var data = _taggedTemplateLiteral(["\n          Corrupted download\n\n          Expected downloaded file to have size: ", "\n          Computed size: ", "\n        "]);

  _templateObject4 = function _templateObject4() {
    return data;
  };

  return data;
}

function _templateObject3() {
  var data = _taggedTemplateLiteral(["\n        Corrupted download\n\n        Expected downloaded file to have checksum: ", "\n        Computed checksum: ", "\n      "]);

  _templateObject3 = function _templateObject3() {
    return data;
  };

  return data;
}

function _templateObject2() {
  var data = _taggedTemplateLiteral(["\n          Corrupted download\n\n          Expected downloaded file to have checksum: ", "\n          Computed checksum: ", "\n\n          Expected downloaded file to have size: ", "\n          Computed size: ", "\n        "]);

  _templateObject2 = function _templateObject2() {
    return data;
  };

  return data;
}

function _templateObject() {
  var data = _taggedTemplateLiteral(["\n    URL: ", "\n    ", "\n  "]);

  _templateObject = function _templateObject() {
    return data;
  };

  return data;
}

function _taggedTemplateLiteral(strings, raw) { if (!raw) { raw = strings.slice(0); } return Object.freeze(Object.defineProperties(strings, { raw: { value: Object.freeze(raw) } })); }

var arch = require('arch');

var la = require('lazy-ass');

var is = require('check-more-types');

var os = require('os');

var url = require('url');

var path = require('path');

var debug = require('debug')('cypress:cli');

var request = require('@cypress/request');

var Promise = require('bluebird');

var requestProgress = require('request-progress');

var _require = require('common-tags'),
    stripIndent = _require.stripIndent;

var _require2 = require('../errors'),
    throwFormErrorText = _require2.throwFormErrorText,
    errors = _require2.errors;

var fs = require('../fs');

var util = require('../util');

var defaultBaseUrl = 'https://download.cypress.io/';

var getProxyUrl = function getProxyUrl() {
  return process.env.HTTPS_PROXY || process.env.https_proxy || process.env.npm_config_https_proxy || process.env.HTTP_PROXY || process.env.http_proxy || process.env.npm_config_proxy || null;
};

var getRealOsArch = function getRealOsArch() {
  // os.arch() returns the arch for which this node was compiled
  // we want the operating system's arch instead: x64 or x86
  var osArch = arch();

  if (osArch === 'x86') {
    // match process.platform output
    return 'ia32';
  }

  return osArch;
};

var getBaseUrl = function getBaseUrl() {
  if (util.getEnv('CYPRESS_DOWNLOAD_MIRROR')) {
    var baseUrl = util.getEnv('CYPRESS_DOWNLOAD_MIRROR');

    if (!baseUrl.endsWith('/')) {
      baseUrl += '/';
    }

    return baseUrl;
  }

  return defaultBaseUrl;
};

var prepend = function prepend(urlPath) {
  var endpoint = url.resolve(getBaseUrl(), urlPath);
  var platform = os.platform();
  var arch = getRealOsArch();
  return "".concat(endpoint, "?platform=").concat(platform, "&arch=").concat(arch);
};

var getUrl = function getUrl(version) {
  if (is.url(version)) {
    debug('version is already an url', version);
    return version;
  }

  return version ? prepend("desktop/".concat(version)) : prepend('desktop');
};

var statusMessage = function statusMessage(err) {
  return err.statusCode ? [err.statusCode, err.statusMessage].join(' - ') : err.toString();
};

var prettyDownloadErr = function prettyDownloadErr(err, version) {
  var msg = stripIndent(_templateObject(), getUrl(version), statusMessage(err));
  debug(msg);
  return throwFormErrorText(errors.failedDownload)(msg);
};
/**
 * Checks checksum and file size for the given file. Allows both
 * values or just one of them to be checked.
 */


var verifyDownloadedFile = function verifyDownloadedFile(filename, expectedSize, expectedChecksum) {
  if (expectedSize && expectedChecksum) {
    debug('verifying checksum and file size');
    return Promise.join(util.getFileChecksum(filename), util.getFileSize(filename), function (checksum, filesize) {
      if (checksum === expectedChecksum && filesize === expectedSize) {
        debug('downloaded file has the expected checksum and size ✅');
        return;
      }

      debug('raising error: checksum or file size mismatch');
      var text = stripIndent(_templateObject2(), expectedChecksum, checksum, expectedSize, filesize);
      debug(text);
      throw new Error(text);
    });
  }

  if (expectedChecksum) {
    debug('only checking expected file checksum %d', expectedChecksum);
    return util.getFileChecksum(filename).then(function (checksum) {
      if (checksum === expectedChecksum) {
        debug('downloaded file has the expected checksum ✅');
        return;
      }

      debug('raising error: file checksum mismatch');
      var text = stripIndent(_templateObject3(), expectedChecksum, checksum);
      throw new Error(text);
    });
  }

  if (expectedSize) {
    // maybe we don't have a checksum, but at least CDN returns content length
    // which we can check against the file size
    debug('only checking expected file size %d', expectedSize);
    return util.getFileSize(filename).then(function (filesize) {
      if (filesize === expectedSize) {
        debug('downloaded file has the expected size ✅');
        return;
      }

      debug('raising error: file size mismatch');
      var text = stripIndent(_templateObject4(), expectedSize, filesize);
      throw new Error(text);
    });
  }

  debug('downloaded file lacks checksum or size to verify');
  return Promise.resolve();
}; // downloads from given url
// return an object with
// {filename: ..., downloaded: true}


var downloadFromUrl = function downloadFromUrl(_ref) {
  var url = _ref.url,
      downloadDestination = _ref.downloadDestination,
      progress = _ref.progress;
  return new Promise(function (resolve, reject) {
    var proxy = getProxyUrl();
    debug('Downloading package', {
      url: url,
      proxy: proxy,
      downloadDestination: downloadDestination
    });
    var redirectVersion;
    var req = request({
      url: url,
      proxy: proxy,
      followRedirect: function followRedirect(response) {
        var version = response.headers['x-version'];
        debug('redirect version:', version);

        if (version) {
          // set the version in options if we have one.
          // this insulates us from potential redirect
          // problems where version would be set to undefined.
          redirectVersion = version;
        } // yes redirect


        return true;
      }
    }); // closure

    var started = null;
    var expectedSize;
    var expectedChecksum;
    requestProgress(req, {
      throttle: progress.throttle
    }).on('response', function (response) {
      // we have computed checksum and filesize during test runner binary build
      // and have set it on the S3 object as user meta data, available via
      // these custom headers "x-amz-meta-..."
      // see https://github.com/cypress-io/cypress/pull/4092
      expectedSize = response.headers['x-amz-meta-size'] || response.headers['content-length'];
      expectedChecksum = response.headers['x-amz-meta-checksum'];

      if (expectedChecksum) {
        debug('expected checksum %s', expectedChecksum);
      }

      if (expectedSize) {
        // convert from string (all Amazon custom headers are strings)
        expectedSize = Number(expectedSize);
        debug('expected file size %d', expectedSize);
      } // start counting now once we've gotten
      // response headers


      started = new Date(); // if our status code does not start with 200

      if (!/^2/.test(response.statusCode)) {
        debug('response code %d', response.statusCode);
        var err = new Error(stripIndent(_templateObject5(), response.statusCode, response.statusMessage));
        reject(err);
      }
    }).on('error', reject).on('progress', function (state) {
      // total time we've elapsed
      // starting on our first progress notification
      var elapsed = new Date() - started; // request-progress sends a value between 0 and 1

      var percentage = util.convertPercentToPercentage(state.percent);
      var eta = util.calculateEta(percentage, elapsed); // send up our percent and seconds remaining

      progress.onProgress(percentage, util.secsRemaining(eta));
    }) // save this download here
    .pipe(fs.createWriteStream(downloadDestination)).on('finish', function () {
      debug('downloading finished');
      verifyDownloadedFile(downloadDestination, expectedSize, expectedChecksum).then(function () {
        return resolve(redirectVersion);
      }, reject);
    });
  });
};
/**
 * Download Cypress.zip from external url to local file.
 * @param [string] version Could be "3.3.0" or full URL
 * @param [string] downloadDestination Local filename to save as
 */


var start = function start(opts) {
  var version = opts.version,
      downloadDestination = opts.downloadDestination,
      progress = opts.progress;

  if (!downloadDestination) {
    la(is.unemptyString(downloadDestination), 'missing download dir', opts);
  }

  if (!progress) {
    progress = {
      onProgress: function onProgress() {
        return {};
      }
    };
  }

  var url = getUrl(version);
  progress.throttle = 100;
  debug('needed Cypress version: %s', version);
  debug('source url %s', url);
  debug("downloading cypress.zip to \"".concat(downloadDestination, "\"")); // ensure download dir exists

  return fs.ensureDirAsync(path.dirname(downloadDestination)).then(function () {
    return downloadFromUrl({
      url: url,
      downloadDestination: downloadDestination,
      progress: progress
    });
  })["catch"](function (err) {
    return prettyDownloadErr(err, version);
  });
};

module.exports = {
  start: start,
  getUrl: getUrl,
  getProxyUrl: getProxyUrl
};