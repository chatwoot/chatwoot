"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.normalizeComponentAnnotations = normalizeComponentAnnotations;

require("core-js/modules/es.object.assign.js");

var _csf = require("@storybook/csf");

var _normalizeInputTypes = require("./normalizeInputTypes");

function normalizeComponentAnnotations(defaultExport) {
  var title = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : defaultExport.title;
  var importPath = arguments.length > 2 ? arguments[2] : undefined;
  var id = defaultExport.id,
      argTypes = defaultExport.argTypes;
  return Object.assign({
    id: (0, _csf.sanitize)(id || title)
  }, defaultExport, {
    title: title
  }, argTypes && {
    argTypes: (0, _normalizeInputTypes.normalizeInputTypes)(argTypes)
  }, {
    parameters: Object.assign({
      fileName: importPath
    }, defaultExport.parameters)
  });
}