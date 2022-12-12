import { TypeSystem } from './types';
import { createSummaryValue } from '../utils';
import { createFlowPropDef } from './flow/createPropDef';
import { isDefaultValueBlacklisted } from './utils/defaultValue';
import { createTsPropDef } from './typeScript/createPropDef';
import { convert } from '../convert';

function createType(type) {
  // A type could be null if a defaultProp has been provided without a type definition.
  return type != null ? createSummaryValue(type.name) : null;
} // A heuristic to tell if a defaultValue comes from RDT


function isReactDocgenTypescript(defaultValue) {
  const {
    computed,
    func
  } = defaultValue;
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
    return Array.isArray(type.value) && type.value.every(({
      value: tv
    }) => typeof tv === 'string' && tv[0] === '"' && tv[tv.length - 1] === '"');
  }

  return false;
}

function createDefaultValue(defaultValue, type) {
  if (defaultValue != null) {
    const {
      value
    } = defaultValue;

    if (!isDefaultValueBlacklisted(value)) {
      // Work around a bug in `react-docgen-typescript-loader`, which returns 'string' for a string
      // default, instead of "'string'" -- which is incorrect
      if (isReactDocgenTypescript(defaultValue) && isStringValued(type)) {
        return createSummaryValue(JSON.stringify(value));
      }

      return createSummaryValue(value);
    }
  }

  return null;
}

function createBasicPropDef(name, type, docgenInfo) {
  const {
    description,
    required,
    defaultValue
  } = docgenInfo;
  return {
    name,
    type: createType(type),
    required,
    description,
    defaultValue: createDefaultValue(defaultValue, type)
  };
}

function applyJsDocResult(propDef, jsDocParsingResult) {
  if (jsDocParsingResult.includesJsDoc) {
    const {
      description,
      extractedTags
    } = jsDocParsingResult;

    if (description != null) {
      // eslint-disable-next-line no-param-reassign
      propDef.description = jsDocParsingResult.description;
    }

    const hasParams = extractedTags.params != null;
    const hasReturns = extractedTags.returns != null && extractedTags.returns.type != null;

    if (hasParams || hasReturns) {
      // eslint-disable-next-line no-param-reassign
      propDef.jsDocTags = {
        params: hasParams && extractedTags.params.map(x => ({
          name: x.getPrettyName(),
          description: x.description
        })),
        returns: hasReturns && {
          description: extractedTags.returns.description
        }
      };
    }
  }

  return propDef;
}

export const javaScriptFactory = (propName, docgenInfo, jsDocParsingResult) => {
  const propDef = createBasicPropDef(propName, docgenInfo.type, docgenInfo);
  propDef.sbType = convert(docgenInfo);
  return applyJsDocResult(propDef, jsDocParsingResult);
};
export const tsFactory = (propName, docgenInfo, jsDocParsingResult) => {
  const propDef = createTsPropDef(propName, docgenInfo);
  propDef.sbType = convert(docgenInfo);
  return applyJsDocResult(propDef, jsDocParsingResult);
};
export const flowFactory = (propName, docgenInfo, jsDocParsingResult) => {
  const propDef = createFlowPropDef(propName, docgenInfo);
  propDef.sbType = convert(docgenInfo);
  return applyJsDocResult(propDef, jsDocParsingResult);
};
export const unknownFactory = (propName, docgenInfo, jsDocParsingResult) => {
  const propDef = createBasicPropDef(propName, {
    name: 'unknown'
  }, docgenInfo);
  return applyJsDocResult(propDef, jsDocParsingResult);
};
export const getPropDefFactory = typeSystem => {
  switch (typeSystem) {
    case TypeSystem.JAVASCRIPT:
      return javaScriptFactory;

    case TypeSystem.TYPESCRIPT:
      return tsFactory;

    case TypeSystem.FLOW:
      return flowFactory;

    default:
      return unknownFactory;
  }
};