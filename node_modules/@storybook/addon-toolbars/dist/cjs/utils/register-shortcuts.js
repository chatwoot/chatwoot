"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.registerShortcuts = void 0;

require("regenerator-runtime/runtime.js");

require("core-js/modules/es.array.iterator.js");

require("core-js/modules/es.object.to-string.js");

require("core-js/modules/web.dom-collections.iterator.js");

require("core-js/modules/es.promise.js");

var _constants = require("../constants");

function asyncGeneratorStep(gen, resolve, reject, _next, _throw, key, arg) { try { var info = gen[key](arg); var value = info.value; } catch (error) { reject(error); return; } if (info.done) { resolve(value); } else { Promise.resolve(value).then(_next, _throw); } }

function _asyncToGenerator(fn) { return function () { var self = this, args = arguments; return new Promise(function (resolve, reject) { var gen = fn.apply(self, args); function _next(value) { asyncGeneratorStep(gen, resolve, reject, _next, _throw, "next", value); } function _throw(err) { asyncGeneratorStep(gen, resolve, reject, _next, _throw, "throw", err); } _next(undefined); }); }; }

var registerShortcuts = /*#__PURE__*/function () {
  var _ref = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee(api, id, shortcuts) {
    return regeneratorRuntime.wrap(function _callee$(_context) {
      while (1) {
        switch (_context.prev = _context.next) {
          case 0:
            if (!(shortcuts && shortcuts.next)) {
              _context.next = 3;
              break;
            }

            _context.next = 3;
            return api.setAddonShortcut(_constants.ADDON_ID, {
              label: shortcuts.next.label,
              defaultShortcut: shortcuts.next.keys,
              actionName: "".concat(id, ":next"),
              action: shortcuts.next.action
            });

          case 3:
            if (!(shortcuts && shortcuts.previous)) {
              _context.next = 6;
              break;
            }

            _context.next = 6;
            return api.setAddonShortcut(_constants.ADDON_ID, {
              label: shortcuts.previous.label,
              defaultShortcut: shortcuts.previous.keys,
              actionName: "".concat(id, ":previous"),
              action: shortcuts.previous.action
            });

          case 6:
            if (!(shortcuts && shortcuts.reset)) {
              _context.next = 9;
              break;
            }

            _context.next = 9;
            return api.setAddonShortcut(_constants.ADDON_ID, {
              label: shortcuts.reset.label,
              defaultShortcut: shortcuts.reset.keys,
              actionName: "".concat(id, ":reset"),
              action: shortcuts.reset.action
            });

          case 9:
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