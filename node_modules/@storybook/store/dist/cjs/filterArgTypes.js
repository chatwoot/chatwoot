"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.filterArgTypes = void 0;

require("core-js/modules/es.array.includes.js");

require("core-js/modules/es.string.includes.js");

require("core-js/modules/es.regexp.exec.js");

require("core-js/modules/es.string.match.js");

require("core-js/modules/es.function.name.js");

var _pickBy = _interopRequireDefault(require("lodash/pickBy"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var matches = function matches(name, descriptor) {
  return Array.isArray(descriptor) ? descriptor.includes(name) : name.match(descriptor);
};

var filterArgTypes = function filterArgTypes(argTypes, include, exclude) {
  if (!include && !exclude) {
    return argTypes;
  }

  return argTypes && (0, _pickBy.default)(argTypes, function (argType, key) {
    var name = argType.name || key;
    return (!include || matches(name, include)) && (!exclude || !matches(name, exclude));
  });
};

exports.filterArgTypes = filterArgTypes;