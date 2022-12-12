import "regenerator-runtime/runtime.js";
import "core-js/modules/es.object.to-string.js";
import "core-js/modules/es.promise.js";

function asyncGeneratorStep(gen, resolve, reject, _next, _throw, key, arg) { try { var info = gen[key](arg); var value = info.value; } catch (error) { reject(error); return; } if (info.done) { resolve(value); } else { Promise.resolve(value).then(_next, _throw); } }

function _asyncToGenerator(fn) { return function () { var self = this, args = arguments; return new Promise(function (resolve, reject) { var gen = fn.apply(self, args); function _next(value) { asyncGeneratorStep(gen, resolve, reject, _next, _throw, "next", value); } function _throw(err) { asyncGeneratorStep(gen, resolve, reject, _next, _throw, "throw", err); } _next(undefined); }); }; }

export var parameters = {
  docs: {
    getContainer: function () {
      var _getContainer = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee() {
        return regeneratorRuntime.wrap(function _callee$(_context) {
          while (1) {
            switch (_context.prev = _context.next) {
              case 0:
                _context.next = 2;
                return import('./blocks');

              case 2:
                return _context.abrupt("return", _context.sent.DocsContainer);

              case 3:
              case "end":
                return _context.stop();
            }
          }
        }, _callee);
      }));

      function getContainer() {
        return _getContainer.apply(this, arguments);
      }

      return getContainer;
    }(),
    getPage: function () {
      var _getPage = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee2() {
        return regeneratorRuntime.wrap(function _callee2$(_context2) {
          while (1) {
            switch (_context2.prev = _context2.next) {
              case 0:
                _context2.next = 2;
                return import('./blocks');

              case 2:
                return _context2.abrupt("return", _context2.sent.DocsPage);

              case 3:
              case "end":
                return _context2.stop();
            }
          }
        }, _callee2);
      }));

      function getPage() {
        return _getPage.apply(this, arguments);
      }

      return getPage;
    }()
  }
};