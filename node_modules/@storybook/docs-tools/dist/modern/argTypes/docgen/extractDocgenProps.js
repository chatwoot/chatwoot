import { parseJsDoc } from '../jsdocParser';
import { TypeSystem } from './types';
import { getDocgenSection, isValidDocgenSection, getDocgenDescription } from './utils';
import { getPropDefFactory } from './createPropDef';

const getTypeSystem = docgenInfo => {
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

export const extractComponentSectionArray = docgenSection => {
  const typeSystem = getTypeSystem(docgenSection[0]);
  const createPropDef = getPropDefFactory(typeSystem);
  return docgenSection.map(item => {
    var _item$type;

    let sanitizedItem = item;

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
export const extractComponentSectionObject = docgenSection => {
  const docgenPropsKeys = Object.keys(docgenSection);
  const typeSystem = getTypeSystem(docgenSection[docgenPropsKeys[0]]);
  const createPropDef = getPropDefFactory(typeSystem);
  return docgenPropsKeys.map(propName => {
    const docgenInfo = docgenSection[propName];
    return docgenInfo != null ? extractProp(propName, docgenInfo, typeSystem, createPropDef) : null;
  }).filter(Boolean);
};
export const extractComponentProps = (component, section) => {
  const docgenSection = getDocgenSection(component, section);

  if (!isValidDocgenSection(docgenSection)) {
    return [];
  } // vue-docgen-api has diverged from react-docgen and returns an array


  return Array.isArray(docgenSection) ? extractComponentSectionArray(docgenSection) : extractComponentSectionObject(docgenSection);
};

function extractProp(propName, docgenInfo, typeSystem, createPropDef) {
  const jsDocParsingResult = parseJsDoc(docgenInfo.description);
  const isIgnored = jsDocParsingResult.includesJsDoc && jsDocParsingResult.ignore;

  if (!isIgnored) {
    const propDef = createPropDef(propName, docgenInfo, jsDocParsingResult);
    return {
      propDef,
      jsDocTags: jsDocParsingResult.extractedTags,
      docgenInfo,
      typeSystem
    };
  }

  return null;
}

export function extractComponentDescription(component) {
  return component != null && getDocgenDescription(component);
}