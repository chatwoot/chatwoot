"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.convert = void 0;

var _typescript = require("./typescript");

var _flow = require("./flow");

var _proptypes = require("./proptypes");

var convert = function convert(docgenInfo) {
  var type = docgenInfo.type,
      tsType = docgenInfo.tsType,
      flowType = docgenInfo.flowType;
  if (type != null) return (0, _proptypes.convert)(type);
  if (tsType != null) return (0, _typescript.convert)(tsType);
  if (flowType != null) return (0, _flow.convert)(flowType);
  return null;
};

exports.convert = convert;