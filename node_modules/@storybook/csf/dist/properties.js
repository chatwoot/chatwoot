"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.PropertyTypes = void 0;

/**
 * Property field types
 * examples are provided for the different types:
 *
 */
var PropertyTypes;
exports.PropertyTypes = PropertyTypes;

(function (PropertyTypes) {
  PropertyTypes["TEXT"] = "text";
  PropertyTypes["NUMBER"] = "number";
  PropertyTypes["BOOLEAN"] = "boolean";
  PropertyTypes["OPTIONS"] = "options";
  PropertyTypes["DATE"] = "date";
  PropertyTypes["COLOR"] = "color";
  PropertyTypes["BUTTON"] = "button";
  PropertyTypes["OBJECT"] = "object";
  PropertyTypes["ARRAY"] = "array";
  PropertyTypes["FILES"] = "files";
})(PropertyTypes || (exports.PropertyTypes = PropertyTypes = {}));