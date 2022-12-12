import "core-js/modules/es.array.map.js";
import "core-js/modules/es.object.assign.js";
import "core-js/modules/es.function.name.js";
import "core-js/modules/es.object.keys.js";
import "core-js/modules/es.array.filter.js";
import "core-js/modules/es.object.to-string.js";
import "core-js/modules/es.symbol.js";
import "core-js/modules/es.symbol.description.js";
import { parseJsDoc } from '../jsdocParser';
import { TypeSystem } from './types';
import { getDocgenSection, isValidDocgenSection, getDocgenDescription } from './utils';
import { getPropDefFactory } from './createPropDef';

var getTypeSystem = function getTypeSystem(docgenInfo) {
  if (docgenInfo.type != null) {
    return TypeSystem.JAVASCRIPT;
  }

  if (docgenInfo.flowType != null) {
    return TypeSystem.FLOW;
  }

  if (docgenInfo.tsType != null) {
    return TypeSystem.TYPESCRIPT;
  }

  return TypeSystem.UNKNOWN;
};

export var extractComponentSectionArray = function extractComponentSectionArray(docgenSection) {
  var typeSystem = getTypeSystem(docgenSection[0]);
  var createPropDef = getPropDefFactory(typeSystem);
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
export var extractComponentSectionObject = function extractComponentSectionObject(docgenSection) {
  var docgenPropsKeys = Object.keys(docgenSection);
  var typeSystem = getTypeSystem(docgenSection[docgenPropsKeys[0]]);
  var createPropDef = getPropDefFactory(typeSystem);
  return docgenPropsKeys.map(function (propName) {
    var docgenInfo = docgenSection[propName];
    return docgenInfo != null ? extractProp(propName, docgenInfo, typeSystem, createPropDef) : null;
  }).filter(Boolean);
};
export var extractComponentProps = function extractComponentProps(component, section) {
  var docgenSection = getDocgenSection(component, section);

  if (!isValidDocgenSection(docgenSection)) {
    return [];
  } // vue-docgen-api has diverged from react-docgen and returns an array


  return Array.isArray(docgenSection) ? extractComponentSectionArray(docgenSection) : extractComponentSectionObject(docgenSection);
};

function extractProp(propName, docgenInfo, typeSystem, createPropDef) {
  var jsDocParsingResult = parseJsDoc(docgenInfo.description);
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

export function extractComponentDescription(component) {
  return component != null && getDocgenDescription(component);
}