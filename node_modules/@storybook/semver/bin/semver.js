#!/usr/bin/env node
// Standalone semver comparison program.
// Exits successfully and prints matching version(s) if
// any supplied version is valid and passes all tests.
"use strict";

require("core-js/modules/es.symbol");

require("core-js/modules/es.symbol.description");

require("core-js/modules/es.symbol.iterator");

require("core-js/modules/es.array.filter");

require("core-js/modules/es.array.for-each");

require("core-js/modules/es.array.index-of");

require("core-js/modules/es.array.iterator");

require("core-js/modules/es.array.map");

require("core-js/modules/es.array.slice");

require("core-js/modules/es.array.sort");

require("core-js/modules/es.object.to-string");

require("core-js/modules/es.string.iterator");

require("core-js/modules/web.dom-collections.for-each");

require("core-js/modules/web.dom-collections.iterator");

function _typeof(obj) { "@babel/helpers - typeof"; if (typeof Symbol === "function" && typeof Symbol.iterator === "symbol") { _typeof = function _typeof(obj) { return typeof obj; }; } else { _typeof = function _typeof(obj) { return obj && typeof Symbol === "function" && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; }; } return _typeof(obj); }

var argv = process.argv.slice(2);
var versions = [];
var range = [];
var inc = null;

var findUp = require('find-up');

var version = require(findUp.sync('package.json')).version;

var loose = false;
var includePrerelease = false;
var coerce = false;
var rtl = false;
var identifier;

var semver = require('../');

var reverse = false;
var options = {};

var main = function main() {
  if (!argv.length) return help();

  while (argv.length) {
    var a = argv.shift();
    var indexOfEqualSign = a.indexOf('=');

    if (indexOfEqualSign !== -1) {
      a = a.slice(0, indexOfEqualSign);
      argv.unshift(a.slice(indexOfEqualSign + 1));
    }

    switch (a) {
      case '-rv':
      case '-rev':
      case '--rev':
      case '--reverse':
        reverse = true;
        break;

      case '-l':
      case '--loose':
        loose = true;
        break;

      case '-p':
      case '--include-prerelease':
        includePrerelease = true;
        break;

      case '-v':
      case '--version':
        versions.push(argv.shift());
        break;

      case '-i':
      case '--inc':
      case '--increment':
        switch (argv[0]) {
          case 'major':
          case 'minor':
          case 'patch':
          case 'prerelease':
          case 'premajor':
          case 'preminor':
          case 'prepatch':
            inc = argv.shift();
            break;

          default:
            inc = 'patch';
            break;
        }

        break;

      case '--preid':
        identifier = argv.shift();
        break;

      case '-r':
      case '--range':
        range.push(argv.shift());
        break;

      case '-c':
      case '--coerce':
        coerce = true;
        break;

      case '--rtl':
        rtl = true;
        break;

      case '--ltr':
        rtl = false;
        break;

      case '-h':
      case '--help':
      case '-?':
        return help();

      default:
        versions.push(a);
        break;
    }
  }

  var options = {
    loose: loose,
    includePrerelease: includePrerelease,
    rtl: rtl
  };
  versions = versions.map(function (v) {
    return coerce ? (semver.coerce(v, options) || {
      version: v
    }).version : v;
  }).filter(function (v) {
    return semver.valid(v);
  });
  if (!versions.length) return fail();

  if (inc && (versions.length !== 1 || range.length)) {
    return failInc();
  }

  var _loop = function _loop(i, l) {
    versions = versions.filter(function (v) {
      return semver.satisfies(v, range[i], options);
    });
    if (!versions.length) return {
      v: fail()
    };
  };

  for (var i = 0, l = range.length; i < l; i++) {
    var _ret = _loop(i, l);

    if (_typeof(_ret) === "object") return _ret.v;
  }

  return success(versions);
};

var failInc = function failInc() {
  console.error('--inc can only be used on a single version with no range');
  fail();
};

var fail = function fail() {
  return process.exit(1);
};

var success = function success() {
  var compare = reverse ? 'rcompare' : 'compare';
  versions.sort(function (a, b) {
    return semver[compare](a, b, options);
  }).map(function (v) {
    return semver.clean(v, options);
  }).map(function (v) {
    return inc ? semver.inc(v, inc, options, identifier) : v;
  }).forEach(function (v, i, _) {
    console.log(v);
  });
};

var help = function help() {
  return console.log("SemVer ".concat(version, "\n\nA JavaScript implementation of the https://semver.org/ specification\nCopyright Isaac Z. Schlueter\n\nUsage: semver [options] <version> [<version> [...]]\nPrints valid versions sorted by SemVer precedence\n\nOptions:\n-r --range <range>\n        Print versions that match the specified range.\n\n-i --increment [<level>]\n        Increment a version by the specified level.  Level can\n        be one of: major, minor, patch, premajor, preminor,\n        prepatch, or prerelease.  Default level is 'patch'.\n        Only one version may be specified.\n\n--preid <identifier>\n        Identifier to be used to prefix premajor, preminor,\n        prepatch or prerelease version increments.\n\n-l --loose\n        Interpret versions and ranges loosely\n\n-p --include-prerelease\n        Always include prerelease versions in range matching\n\n-c --coerce\n        Coerce a string into SemVer if possible\n        (does not imply --loose)\n\n--rtl\n        Coerce version strings right to left\n\n--ltr\n        Coerce version strings left to right (default)\n\nProgram exits successfully if any valid version satisfies\nall supplied ranges, and prints all satisfying versions.\n\nIf no satisfying versions are found, then exits failure.\n\nVersions are printed in ascending order, so supplying\nmultiple versions to the utility will just sort them."));
};

main();