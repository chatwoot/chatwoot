'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _cssUnitConverter = require('css-unit-converter');

var _cssUnitConverter2 = _interopRequireDefault(_cssUnitConverter);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function convertNodes(left, right, precision) {
  switch (left.type) {
    case 'LengthValue':
    case 'AngleValue':
    case 'TimeValue':
    case 'FrequencyValue':
    case 'ResolutionValue':
      return convertAbsoluteLength(left, right, precision);
    default:
      return { left: left, right: right };
  }
}

function convertAbsoluteLength(left, right, precision) {
  if (right.type === left.type) {
    right = {
      type: left.type,
      value: (0, _cssUnitConverter2.default)(right.value, right.unit, left.unit, precision),
      unit: left.unit
    };
  }
  return { left: left, right: right };
}

exports.default = convertNodes;
module.exports = exports['default'];