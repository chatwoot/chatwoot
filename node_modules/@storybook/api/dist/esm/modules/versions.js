import "regenerator-runtime/runtime.js";

function asyncGeneratorStep(gen, resolve, reject, _next, _throw, key, arg) { try { var info = gen[key](arg); var value = info.value; } catch (error) { reject(error); return; } if (info.done) { resolve(value); } else { Promise.resolve(value).then(_next, _throw); } }

function _asyncToGenerator(fn) { return function () { var self = this, args = arguments; return new Promise(function (resolve, reject) { var gen = fn.apply(self, args); function _next(value) { asyncGeneratorStep(gen, resolve, reject, _next, _throw, "next", value); } function _throw(err) { asyncGeneratorStep(gen, resolve, reject, _next, _throw, "throw", err); } _next(undefined); }); }; }

import "core-js/modules/es.object.assign.js";
import "core-js/modules/es.array.concat.js";
import "core-js/modules/es.array.includes.js";
import "core-js/modules/es.string.includes.js";
import "core-js/modules/es.object.to-string.js";
import "core-js/modules/es.promise.js";
import global from 'global';
import semver from '@storybook/semver';
import memoize from 'memoizerific';
import { version as currentVersion } from '../version';
var VERSIONCHECK = global.VERSIONCHECK;
var getVersionCheckData = memoize(1)(function () {
  try {
    return Object.assign({}, JSON.parse(VERSIONCHECK).data || {});
  } catch (e) {
    return {};
  }
});
export var init = function init(_ref) {
  var store = _ref.store,
      mode = _ref.mode,
      fullAPI = _ref.fullAPI;

  var _store$getState = store.getState(),
      dismissedVersionNotification = _store$getState.dismissedVersionNotification;

  var state = {
    versions: Object.assign({
      current: {
        version: currentVersion
      }
    }, getVersionCheckData()),
    dismissedVersionNotification: dismissedVersionNotification
  };
  var api = {
    getCurrentVersion: function getCurrentVersion() {
      var _store$getState2 = store.getState(),
          current = _store$getState2.versions.current;

      return current;
    },
    getLatestVersion: function getLatestVersion() {
      var _store$getState3 = store.getState(),
          _store$getState3$vers = _store$getState3.versions,
          latest = _store$getState3$vers.latest,
          next = _store$getState3$vers.next,
          current = _store$getState3$vers.current;

      if (current && semver.prerelease(current.version) && next) {
        return latest && semver.gt(latest.version, next.version) ? latest : next;
      }

      return latest;
    },
    versionUpdateAvailable: function versionUpdateAvailable() {
      var latest = api.getLatestVersion();
      var current = api.getCurrentVersion();

      if (latest) {
        if (!latest.version) {
          return true;
        }

        if (!current.version) {
          return true;
        }

        var onPrerelease = !!semver.prerelease(current.version);
        var actualCurrent = onPrerelease ? "".concat(semver.major(current.version), ".").concat(semver.minor(current.version), ".").concat(semver.patch(current.version)) : current.version;
        var diff = semver.diff(actualCurrent, latest.version);
        return semver.gt(latest.version, actualCurrent) && diff !== 'patch' && !diff.includes('pre');
      }

      return false;
    }
  }; // Grab versions from the server/local storage right away

  var initModule = /*#__PURE__*/function () {
    var _ref2 = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee() {
      var _store$getState4, _store$getState4$vers, versions, _getVersionCheckData, latest, next, latestVersion, diff;

      return regeneratorRuntime.wrap(function _callee$(_context) {
        while (1) {
          switch (_context.prev = _context.next) {
            case 0:
              _store$getState4 = store.getState(), _store$getState4$vers = _store$getState4.versions, versions = _store$getState4$vers === void 0 ? {} : _store$getState4$vers;
              _getVersionCheckData = getVersionCheckData(), latest = _getVersionCheckData.latest, next = _getVersionCheckData.next;
              _context.next = 4;
              return store.setState({
                versions: Object.assign({}, versions, {
                  latest: latest,
                  next: next
                })
              });

            case 4:
              if (api.versionUpdateAvailable()) {
                latestVersion = api.getLatestVersion().version;
                diff = semver.diff(versions.current.version, versions.latest.version);

                if (latestVersion !== dismissedVersionNotification && diff !== 'patch' && !semver.prerelease(latestVersion) && mode !== 'production') {
                  fullAPI.addNotification({
                    id: 'update',
                    link: '/settings/about',
                    content: {
                      headline: "Storybook ".concat(latestVersion, " is available!"),
                      subHeadline: "Your current version is: ".concat(versions.current.version)
                    },
                    icon: {
                      name: 'book'
                    },
                    onClear: function onClear() {
                      store.setState({
                        dismissedVersionNotification: latestVersion
                      }, {
                        persistence: 'permanent'
                      });
                    }
                  });
                }
              }

            case 5:
            case "end":
              return _context.stop();
          }
        }
      }, _callee);
    }));

    return function initModule() {
      return _ref2.apply(this, arguments);
    };
  }();

  return {
    init: initModule,
    state: state,
    api: api
  };
};