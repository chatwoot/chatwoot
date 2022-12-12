import "regenerator-runtime/runtime.js";

function asyncGeneratorStep(gen, resolve, reject, _next, _throw, key, arg) { try { var info = gen[key](arg); var value = info.value; } catch (error) { reject(error); return; } if (info.done) { resolve(value); } else { Promise.resolve(value).then(_next, _throw); } }

function _asyncToGenerator(fn) { return function () { var self = this, args = arguments; return new Promise(function (resolve, reject) { var gen = fn.apply(self, args); function _next(value) { asyncGeneratorStep(gen, resolve, reject, _next, _throw, "next", value); } function _throw(err) { asyncGeneratorStep(gen, resolve, reject, _next, _throw, "throw", err); } _next(undefined); }); }; }

import "core-js/modules/es.regexp.exec.js";
import "core-js/modules/es.string.match.js";
import "core-js/modules/es.object.assign.js";
import "core-js/modules/es.object.to-string.js";
import "core-js/modules/es.promise.js";
export var init = function init(_ref) {
  var store = _ref.store,
      navigate = _ref.navigate,
      fullAPI = _ref.fullAPI;

  var isSettingsScreenActive = function isSettingsScreenActive() {
    var _fullAPI$getUrlState = fullAPI.getUrlState(),
        path = _fullAPI$getUrlState.path;

    return !!(path || '').match(/^\/settings/);
  };

  var api = {
    closeSettings: function closeSettings() {
      var _store$getState = store.getState(),
          lastTrackedStoryId = _store$getState.settings.lastTrackedStoryId;

      if (lastTrackedStoryId) {
        fullAPI.selectStory(lastTrackedStoryId);
      } else {
        fullAPI.selectFirstStory();
      }
    },
    changeSettingsTab: function changeSettingsTab(tab) {
      navigate("/settings/".concat(tab));
    },
    isSettingsScreenActive: isSettingsScreenActive,
    navigateToSettingsPage: function () {
      var _navigateToSettingsPage = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee(path) {
        var _store$getState2, settings, storyId;

        return regeneratorRuntime.wrap(function _callee$(_context) {
          while (1) {
            switch (_context.prev = _context.next) {
              case 0:
                if (isSettingsScreenActive()) {
                  _context.next = 4;
                  break;
                }

                _store$getState2 = store.getState(), settings = _store$getState2.settings, storyId = _store$getState2.storyId;
                _context.next = 4;
                return store.setState({
                  settings: Object.assign({}, settings, {
                    lastTrackedStoryId: storyId
                  })
                });

              case 4:
                navigate(path);

              case 5:
              case "end":
                return _context.stop();
            }
          }
        }, _callee);
      }));

      function navigateToSettingsPage(_x) {
        return _navigateToSettingsPage.apply(this, arguments);
      }

      return navigateToSettingsPage;
    }()
  };

  var initModule = /*#__PURE__*/function () {
    var _ref2 = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee2() {
      return regeneratorRuntime.wrap(function _callee2$(_context2) {
        while (1) {
          switch (_context2.prev = _context2.next) {
            case 0:
              _context2.next = 2;
              return store.setState({
                settings: {
                  lastTrackedStoryId: null
                }
              });

            case 2:
            case "end":
              return _context2.stop();
          }
        }
      }, _callee2);
    }));

    return function initModule() {
      return _ref2.apply(this, arguments);
    };
  }();

  return {
    init: initModule,
    api: api
  };
};