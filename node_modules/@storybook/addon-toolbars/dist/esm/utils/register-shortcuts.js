import "regenerator-runtime/runtime.js";
import "core-js/modules/es.array.iterator.js";
import "core-js/modules/es.object.to-string.js";
import "core-js/modules/web.dom-collections.iterator.js";
import "core-js/modules/es.promise.js";

function asyncGeneratorStep(gen, resolve, reject, _next, _throw, key, arg) { try { var info = gen[key](arg); var value = info.value; } catch (error) { reject(error); return; } if (info.done) { resolve(value); } else { Promise.resolve(value).then(_next, _throw); } }

function _asyncToGenerator(fn) { return function () { var self = this, args = arguments; return new Promise(function (resolve, reject) { var gen = fn.apply(self, args); function _next(value) { asyncGeneratorStep(gen, resolve, reject, _next, _throw, "next", value); } function _throw(err) { asyncGeneratorStep(gen, resolve, reject, _next, _throw, "throw", err); } _next(undefined); }); }; }

import { ADDON_ID } from '../constants';
export var registerShortcuts = /*#__PURE__*/function () {
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
            return api.setAddonShortcut(ADDON_ID, {
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
            return api.setAddonShortcut(ADDON_ID, {
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
            return api.setAddonShortcut(ADDON_ID, {
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