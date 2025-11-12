"use strict";

var _semverCompare = _interopRequireDefault(require("./semver-compare.js"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { "default": obj }; }

describe('semver-compare', function () {
  it('should compare versions', function () {
    var versions = ['1.2.3', '4.11.6', '4.2.0', '1.5.19', '1.5.6', '1.5.4', '1.5.5-alpha.beta', '1.5.5-alpha', '1.5.5', '1.5.5-rc.1', '1.5.5-beta.0', '4.1.3', '2.3.1', '10.5.5', '11.3.0'];
    versions.sort(_semverCompare["default"]).should.deep.equal(['1.2.3', '1.5.4', '1.5.5-alpha', '1.5.5-alpha.beta', '1.5.5-beta.0', '1.5.5-rc.1', '1.5.5', '1.5.6', '1.5.19', '2.3.1', '4.1.3', '4.2.0', '4.11.6', '10.5.5', '11.3.0']);
  });
});
//# sourceMappingURL=semver-compare.test.js.map