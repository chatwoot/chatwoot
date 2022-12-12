"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.registerShortcuts = void 0;

require("core-js/modules/es.object.to-string.js");

require("core-js/modules/es.promise.js");

require("regenerator-runtime/runtime.js");

var _constants = require("./constants");

function asyncGeneratorStep(gen, resolve, reject, _next, _throw, key, arg) { try { var info = gen[key](arg); var value = info.value; } catch (error) { reject(error); return; } if (info.done) { resolve(value); } else { Promise.resolve(value).then(_next, _throw); } }

function _asyncToGenerator(fn) { return function () { var self = this, args = arguments; return new Promise(function (resolve, reject) { var gen = fn.apply(self, args); function _next(value) { asyncGeneratorStep(gen, resolve, reject, _next, _throw, "next", value); } function _throw(err) { asyncGeneratorStep(gen, resolve, reject, _next, _throw, "throw", err); } _next(undefined); }); }; }

var getCurrentViewportIndex = function getCurrentViewportIndex(viewportsKeys, current) {
  return viewportsKeys.indexOf(current);
};

var getNextViewport = function getNextViewport(viewportsKeys, current) {
  var currentViewportIndex = getCurrentViewportIndex(viewportsKeys, current);
  return currentViewportIndex === viewportsKeys.length - 1 ? viewportsKeys[0] : viewportsKeys[currentViewportIndex + 1];
};

var getPreviousViewport = function getPreviousViewport(viewportsKeys, current) {
  var currentViewportIndex = getCurrentViewportIndex(viewportsKeys, current);
  return currentViewportIndex < 1 ? viewportsKeys[viewportsKeys.length - 1] : viewportsKeys[currentViewportIndex - 1];
};

var registerShortcuts = /*#__PURE__*/function () {
  var _ref = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee(api, setState, viewportsKeys) {
    return regeneratorRuntime.wrap(function _callee$(_context) {
      while (1) {
        switch (_context.prev = _context.next) {
          case 0:
            _context.next = 2;
            return api.setAddonShortcut(_constants.ADDON_ID, {
              label: 'Previous viewport',
              defaultShortcut: ['shift', 'V'],
              actionName: 'previous',
              action: function action() {
                var _api$getAddonState = api.getAddonState(_constants.ADDON_ID),
                    selected = _api$getAddonState.selected,
                    isRotated = _api$getAddonState.isRotated;

                setState({
                  selected: getPreviousViewport(viewportsKeys, selected),
                  isRotated: isRotated
                });
              }
            });

          case 2:
            _context.next = 4;
            return api.setAddonShortcut(_constants.ADDON_ID, {
              label: 'Next viewport',
              defaultShortcut: ['V'],
              actionName: 'next',
              action: function action() {
                var _api$getAddonState2 = api.getAddonState(_constants.ADDON_ID),
                    selected = _api$getAddonState2.selected,
                    isRotated = _api$getAddonState2.isRotated;

                setState({
                  selected: getNextViewport(viewportsKeys, selected),
                  isRotated: isRotated
                });
              }
            });

          case 4:
            _context.next = 6;
            return api.setAddonShortcut(_constants.ADDON_ID, {
              label: 'Reset viewport',
              defaultShortcut: ['alt', 'V'],
              actionName: 'reset',
              action: function action() {
                var _api$getAddonState3 = api.getAddonState(_constants.ADDON_ID),
                    isRotated = _api$getAddonState3.isRotated;

                setState({
                  selected: 'reset',
                  isRotated: isRotated
                });
              }
            });

          case 6:
          case "end":
            return _context.stop();
        }
      }
    }, _callee);
  }));

  return function registerShortcuts(_x, _x2, _x3) {
    return _ref.apply(this, arguments);
  };
}();

exports.registerShortcuts = registerShortcuts;