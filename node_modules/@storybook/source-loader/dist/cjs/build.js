"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.transform = transform;

require("regenerator-runtime/runtime.js");

require("core-js/modules/es.object.to-string.js");

require("core-js/modules/es.promise.js");

require("core-js/modules/es.array.concat.js");

var _readAsObject = require("./dependencies-lookup/readAsObject");

function asyncGeneratorStep(gen, resolve, reject, _next, _throw, key, arg) { try { var info = gen[key](arg); var value = info.value; } catch (error) { reject(error); return; } if (info.done) { resolve(value); } else { Promise.resolve(value).then(_next, _throw); } }

function _asyncToGenerator(fn) { return function () { var self = this, args = arguments; return new Promise(function (resolve, reject) { var gen = fn.apply(self, args); function _next(value) { asyncGeneratorStep(gen, resolve, reject, _next, _throw, "next", value); } function _throw(err) { asyncGeneratorStep(gen, resolve, reject, _next, _throw, "throw", err); } _next(undefined); }); }; }

function transform(_x) {
  return _transform.apply(this, arguments);
}

function _transform() {
  _transform = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee(inputSource) {
    var sourceObject, source, sourceJson, addsMap, preamble;
    return regeneratorRuntime.wrap(function _callee$(_context) {
      while (1) {
        switch (_context.prev = _context.next) {
          case 0:
            _context.next = 2;
            return (0, _readAsObject.readStory)(this, inputSource);

          case 2:
            sourceObject = _context.sent;

            if (!(!sourceObject.source || sourceObject.source.length === 0)) {
              _context.next = 5;
              break;
            }

            return _context.abrupt("return", inputSource);

          case 5:
            source = sourceObject.source, sourceJson = sourceObject.sourceJson, addsMap = sourceObject.addsMap;
            preamble = "\n    /* eslint-disable */\n    // @ts-nocheck\n    // @ts-ignore\n    var __STORY__ = ".concat(sourceJson, ";\n    // @ts-ignore\n    var __LOCATIONS_MAP__ = ").concat(JSON.stringify(addsMap), ";\n    ");
            return _context.abrupt("return", "".concat(preamble, "\n").concat(source));

          case 8:
          case "end":
            return _context.stop();
        }
      }
    }, _callee, this);
  }));
  return _transform.apply(this, arguments);
}