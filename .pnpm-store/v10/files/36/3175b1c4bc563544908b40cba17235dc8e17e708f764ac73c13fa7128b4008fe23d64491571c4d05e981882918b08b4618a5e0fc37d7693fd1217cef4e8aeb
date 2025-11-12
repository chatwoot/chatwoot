"use strict";

var _matchesEntirely = _interopRequireDefault(require("./matchesEntirely.js"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { "default": obj }; }

describe('matchesEntirely', function () {
  it('should work in edge cases', function () {
    // No text.
    (0, _matchesEntirely["default"])(undefined, '').should.equal(true); // "OR" in regexp.

    (0, _matchesEntirely["default"])('911231231', '4\d{8}|[1-9]\d{7}').should.equal(false);
  });
});
//# sourceMappingURL=matchesEntirely.test.js.map