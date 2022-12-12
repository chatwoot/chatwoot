"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.getDocgenDescription = getDocgenDescription;
exports.getDocgenSection = getDocgenSection;
exports.hasDocgen = hasDocgen;
exports.isValidDocgenSection = isValidDocgenSection;

require("core-js/modules/es.object.keys.js");

require("core-js/modules/es.symbol.js");

require("core-js/modules/es.symbol.description.js");

var _string = require("./string");

/* eslint-disable no-underscore-dangle */
function hasDocgen(component) {
  return !!component.__docgenInfo;
}

function isValidDocgenSection(docgenSection) {
  return docgenSection != null && Object.keys(docgenSection).length > 0;
}

function getDocgenSection(component, section) {
  return hasDocgen(component) ? component.__docgenInfo[section] : null;
}

function getDocgenDescription(component) {
  return hasDocgen(component) && (0, _string.str)(component.__docgenInfo.description);
}