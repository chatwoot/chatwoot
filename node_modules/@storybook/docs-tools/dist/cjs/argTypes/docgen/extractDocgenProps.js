"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.extractComponentDescription = extractComponentDescription;
exports.extractComponentSectionObject = exports.extractComponentSectionArray = exports.extractComponentProps = void 0;

require("core-js/modules/es.array.map.js");

require("core-js/modules/es.object.assign.js");

require("core-js/modules/es.function.name.js");

require("core-js/modules/es.object.keys.js");

require("core-js/modules/es.array.filter.js");

require("core-js/modules/es.object.to-string.js");

require("core-js/modules/es.symbol.js");

require("core-js/modules/es.symbol.description.js");

var _jsdocParser = require("../jsdocParser");

var _types = require("./types");

var _utils = require("./utils");

var _createPropDef = require("./createPropDef");

var getTypeSystem = function getTypeSystem(docgenInfo) {
  if (docgenInfo.type != null) {
    return _types.TypeSystem.JAVASCRIPT;
  }

  if (docgenInfo.flowType != null) {
    return _types.TypeSystem.FLOW;
  }

  if (docgenInfo.tsType != null) {
    return _types.TypeSystem.TYPESCRIPT;
  }

  return _types.TypeSystem.UNKNOWN;
};

var extractComponentSectionArray = function extractComponentSectionArray(docgenSection) {
  var typeSystem = getTypeSystem(docgenSection[0]);
  var createPropDef = (0, _createPropDef.getPropDefFactory)(typeSystem);
  return docgenSection.map(function (item) {
    var _item$type;

    var sanitizedItem = item;

    if ((_item$type = item.type) !== null && _item$type !== void 0 && _item$type.elements) {
      sanitizedItem = Object.assign({}, item, {
        type: Object.assign({}, item.type, {
          value: item.type.elements
        })
      });
    }

    return extractProp(sanitizedItem.name, sanitizedItem, typeSystem, createPropDef);
  });
};

exports.extractComponentSectionArray = extractComponentSectionArray;

var extractComponentSectionObject = function extractComponentSectionObject(docgenSection) {
  var docgenPropsKeys = Object.keys(docgenSection);
  var typeSystem = getTypeSystem(docgenSection[docgenPropsKeys[0]]);
  var createPropDef = (0, _createPropDef.getPropDefFactory)(typeSystem);
  return docgenPropsKeys.map(function (propName) {
    var docgenInfo = docgenSection[propName];
    return docgenInfo != null ? extractProp(propName, docgenInfo, typeSystem, createPropDef) : null;
  }).filter(Boolean);
};

exports.extractComponentSectionObject = extractComponentSectionObject;

var extractComponentProps = function extractComponentProps(component, section) {
  var docgenSection = (0, _utils.getDocgenSection)(component, section);

  if (!(0, _utils.isValidDocgenSection)(docgenSection)) {
    return [];
  } // vue-docgen-api has diverged from react-docgen and returns an array


  return Array.isArray(docgenSection) ? extractComponentSectionArray(docgenSection) : extractComponentSectionObject(docgenSection);
};

exports.extractComponentProps = extractComponentProps;

function extractProp(propName, docgenInfo, typeSystem, createPropDef) {
  var jsDocParsingResult = (0, _jsdocParser.parseJsDoc)(docgenInfo.description);
  var isIgnored = jsDocParsingResult.includesJsDoc && jsDocParsingResult.ignore;

  if (!isIgnored) {
    var propDef = createPropDef(propName, docgenInfo, jsDocParsingResult);
    return {
      propDef: propDef,
      jsDocTags: jsDocParsingResult.extractedTags,
      docgenInfo: docgenInfo,
      typeSystem: typeSystem
    };
  }

  return null;
}

function extractComponentDescription(component) {
  return component != null && (0, _utils.getDocgenDescription)(component);
}