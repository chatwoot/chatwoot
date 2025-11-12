"use strict";

var _searchNumbers = _interopRequireDefault(require("./searchNumbers.js"));

var _metadataMin = _interopRequireDefault(require("../../metadata.min.json"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { "default": obj }; }

function _createForOfIteratorHelperLoose(o, allowArrayLike) { var it = typeof Symbol !== "undefined" && o[Symbol.iterator] || o["@@iterator"]; if (it) return (it = it.call(o)).next.bind(it); if (Array.isArray(o) || (it = _unsupportedIterableToArray(o)) || allowArrayLike && o && typeof o.length === "number") { if (it) o = it; var i = 0; return function () { if (i >= o.length) return { done: true }; return { done: false, value: o[i++] }; }; } throw new TypeError("Invalid attempt to iterate non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen); }

function _arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

describe('searchNumbers', function () {
  it('should iterate', function () {
    var expectedNumbers = [{
      country: 'RU',
      phone: '8005553535',
      // number   : '+7 (800) 555-35-35',
      startsAt: 14,
      endsAt: 32
    }, {
      country: 'US',
      phone: '2133734253',
      // number   : '(213) 373-4253',
      startsAt: 41,
      endsAt: 55
    }];

    for (var _iterator = _createForOfIteratorHelperLoose((0, _searchNumbers["default"])('The number is +7 (800) 555-35-35 and not (213) 373-4253 as written in the document.', 'US', _metadataMin["default"])), _step; !(_step = _iterator()).done;) {
      var number = _step.value;
      number.should.deep.equal(expectedNumbers.shift());
    }

    expectedNumbers.length.should.equal(0);
  });
});
//# sourceMappingURL=searchNumbers.test.js.map