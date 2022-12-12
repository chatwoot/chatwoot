'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function filterWarnings(exclude, result) {
  result.compilation.warnings = result.compilation.warnings.filter( // eslint-disable-line no-param-reassign
  function (warning) {
    return !exclude.some(function (regexp) {
      return regexp.test(warning.message || warning);
    });
  });
}

var FilterWarningsPlugin = function () {
  function FilterWarningsPlugin(_ref) {
    var exclude = _ref.exclude;

    _classCallCheck(this, FilterWarningsPlugin);

    if (exclude instanceof RegExp) {
      exclude = [exclude]; // eslint-disable-line no-param-reassign
    }
    if (!Array.isArray(exclude)) {
      throw new Error('Exclude an only be a regexp or an array of regexp');
    }
    this.exclude = exclude;
  }

  _createClass(FilterWarningsPlugin, [{
    key: 'apply',
    value: function apply(compiler) {
      var _this = this;

      if (typeof compiler.hooks !== 'undefined') {
        compiler.hooks.done.tap('filter-warnings-plugin', function (result) {
          filterWarnings(_this.exclude, result);
        });
      } else {
        compiler.plugin('done', function (result) {
          filterWarnings(_this.exclude, result);
        });
      }
    }
  }]);

  return FilterWarningsPlugin;
}();

exports.default = FilterWarningsPlugin;