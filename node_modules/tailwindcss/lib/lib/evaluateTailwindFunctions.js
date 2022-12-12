"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = _default;

var _lodash = _interopRequireDefault(require("lodash"));

var _postcssFunctions = _interopRequireDefault(require("postcss-functions"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

const themeTransforms = {
  fontSize(value) {
    return Array.isArray(value) ? value[0] : value;
  },

  outline(value) {
    return Array.isArray(value) ? value[0] : value;
  }

};

function defaultTransform(value) {
  return Array.isArray(value) ? value.join(', ') : value;
}

function _default(config) {
  return (0, _postcssFunctions.default)({
    functions: {
      theme: (path, ...defaultValue) => {
        const trimmedPath = _lodash.default.trim(path, `'"`);

        return _lodash.default.thru(_lodash.default.get(config.theme, trimmedPath, defaultValue), value => {
          const [themeSection] = trimmedPath.split('.');
          return _lodash.default.get(themeTransforms, themeSection, defaultTransform)(value);
        });
      }
    }
  });
}