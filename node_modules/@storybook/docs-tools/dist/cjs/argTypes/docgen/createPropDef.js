"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.unknownFactory = exports.tsFactory = exports.javaScriptFactory = exports.getPropDefFactory = exports.flowFactory = void 0;

require("core-js/modules/es.function.name.js");

require("core-js/modules/es.object.to-string.js");

require("core-js/modules/es.symbol.js");

require("core-js/modules/es.symbol.description.js");

require("core-js/modules/es.array.map.js");

var _types = require("./types");

var _utils = require("../utils");

var _createPropDef = require("./flow/createPropDef");

var _defaultValue = require("./utils/defaultValue");

var _createPropDef2 = require("./typeScript/createPropDef");

var _convert = require("../convert");

function createType(type) {
  // A type could be null if a defaultProp has been provided without a type definition.
  return type != null ? (0, _utils.createSummaryValue)(type.name) : null;
} // A heuristic to tell if a defaultValue comes from RDT


function isReactDocgenTypescript(defaultValue) {
  var computed = defaultValue.computed,
      func = defaultValue.func;
  return typeof computed === 'undefined' && typeof func === 'undefined';
}

function isStringValued(type) {
  if (!type) {
    return false;
  }

  if (type.name === 'string') {
    return true;
  }

  if (type.name === 'enum') {
    return Array.isArray(type.value) && type.value.every(function (_ref) {
      var tv = _ref.value;
      return typeof tv === 'string' && tv[0] === '"' && tv[tv.length - 1] === '"';
    });
  }

  return false;
}

function createDefaultValue(defaultValue, type) {
  if (defaultValue != null) {
    var value = defaultValue.value;

    if (!(0, _defaultValue.isDefaultValueBlacklisted)(value)) {
      // Work around a bug in `react-docgen-typescript-loader`, which returns 'string' for a string
      // default, instead of "'string'" -- which is incorrect
      if (isReactDocgenTypescript(defaultValue) && isStringValued(type)) {
        return (0, _utils.createSummaryValue)(JSON.stringify(value));
      }

      return (0, _utils.createSummaryValue)(value);
    }
  }

  return null;
}

function createBasicPropDef(name, type, docgenInfo) {
  var description = docgenInfo.description,
      required = docgenInfo.required,
      defaultValue = docgenInfo.defaultValue;
  return {
    name: name,
    type: createType(type),
    required: required,
    description: description,
    defaultValue: createDefaultValue(defaultValue, type)
  };
}

function applyJsDocResult(propDef, jsDocParsingResult) {
  if (jsDocParsingResult.includesJsDoc) {
    var description = jsDocParsingResult.description,
        extractedTags = jsDocParsingResult.extractedTags;

    if (description != null) {
      // eslint-disable-next-line no-param-reassign
      propDef.description = jsDocParsingResult.description;
    }

    var hasParams = extractedTags.params != null;
    var hasReturns = extractedTags.returns != null && extractedTags.returns.type != null;

    if (hasParams || hasReturns) {
      // eslint-disable-next-line no-param-reassign
      propDef.jsDocTags = {
        params: hasParams && extractedTags.params.map(function (x) {
          return {
            name: x.getPrettyName(),
            description: x.description
          };
        }),
        returns: hasReturns && {
          description: extractedTags.returns.description
        }
      };
    }
  }

  return propDef;
}

var javaScriptFactory = function javaScriptFactory(propName, docgenInfo, jsDocParsingResult) {
  var propDef = createBasicPropDef(propName, docgenInfo.type, docgenInfo);
  propDef.sbType = (0, _convert.convert)(docgenInfo);
  return applyJsDocResult(propDef, jsDocParsingResult);
};

exports.javaScriptFactory = javaScriptFactory;

var tsFactory = function tsFactory(propName, docgenInfo, jsDocParsingResult) {
  var propDef = (0, _createPropDef2.createTsPropDef)(propName, docgenInfo);
  propDef.sbType = (0, _convert.convert)(docgenInfo);
  return applyJsDocResult(propDef, jsDocParsingResult);
};

exports.tsFactory = tsFactory;

var flowFactory = function flowFactory(propName, docgenInfo, jsDocParsingResult) {
  var propDef = (0, _createPropDef.createFlowPropDef)(propName, docgenInfo);
  propDef.sbType = (0, _convert.convert)(docgenInfo);
  return applyJsDocResult(propDef, jsDocParsingResult);
};

exports.flowFactory = flowFactory;

var unknownFactory = function unknownFactory(propName, docgenInfo, jsDocParsingResult) {
  var propDef = createBasicPropDef(propName, {
    name: 'unknown'
  }, docgenInfo);
  return applyJsDocResult(propDef, jsDocParsingResult);
};

exports.unknownFactory = unknownFactory;

var getPropDefFactory = function getPropDefFactory(typeSystem) {
  switch (typeSystem) {
    case _types.TypeSystem.JAVASCRIPT:
      return javaScriptFactory;

    case _types.TypeSystem.TYPESCRIPT:
      return tsFactory;

    case _types.TypeSystem.FLOW:
      return flowFactory;

    default:
      return unknownFactory;
  }
};

exports.getPropDefFactory = getPropDefFactory;