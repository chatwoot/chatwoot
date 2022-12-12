import "core-js/modules/es.array.slice.js";
import "core-js/modules/es.object.freeze.js";

var _templateObject;

import "core-js/modules/es.array.iterator.js";
import "core-js/modules/es.object.to-string.js";
import "core-js/modules/es.set.js";
import "core-js/modules/es.string.iterator.js";
import "core-js/modules/web.dom-collections.iterator.js";
import "core-js/modules/es.array.concat.js";
import "core-js/modules/es.symbol.js";
import "core-js/modules/es.symbol.description.js";
import "core-js/modules/es.symbol.iterator.js";

function _taggedTemplateLiteral(strings, raw) { if (!raw) { raw = strings.slice(0); } return Object.freeze(Object.defineProperties(strings, { raw: { value: Object.freeze(raw) } })); }

function _typeof(obj) { "@babel/helpers - typeof"; return _typeof = "function" == typeof Symbol && "symbol" == typeof Symbol.iterator ? function (obj) { return typeof obj; } : function (obj) { return obj && "function" == typeof Symbol && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; }, _typeof(obj); }

import mapValues from 'lodash/mapValues';
import dedent from 'ts-dedent';
import { logger } from '@storybook/client-logger';
import { combineParameters } from './parameters';

var inferType = function inferType(value, name, visited) {
  var type = _typeof(value);

  switch (type) {
    case 'boolean':
    case 'string':
    case 'number':
    case 'function':
    case 'symbol':
      return {
        name: type
      };

    default:
      break;
  }

  if (value) {
    if (visited.has(value)) {
      logger.warn(dedent(_templateObject || (_templateObject = _taggedTemplateLiteral(["\n        We've detected a cycle in arg '", "'. Args should be JSON-serializable.\n\n        Consider using the mapping feature or fully custom args:\n        - Mapping: https://storybook.js.org/docs/react/writing-stories/args#mapping-to-complex-arg-values\n        - Custom args: https://storybook.js.org/docs/react/essentials/controls#fully-custom-args\n      "])), name));
      return {
        name: 'other',
        value: 'cyclic object'
      };
    }

    visited.add(value);

    if (Array.isArray(value)) {
      var childType = value.length > 0 ? inferType(value[0], name, new Set(visited)) : {
        name: 'other',
        value: 'unknown'
      };
      return {
        name: 'array',
        value: childType
      };
    }

    var fieldTypes = mapValues(value, function (field) {
      return inferType(field, name, new Set(visited));
    });
    return {
      name: 'object',
      value: fieldTypes
    };
  }

  return {
    name: 'object',
    value: {}
  };
};

export var inferArgTypes = function inferArgTypes(context) {
  var id = context.id,
      _context$argTypes = context.argTypes,
      userArgTypes = _context$argTypes === void 0 ? {} : _context$argTypes,
      _context$initialArgs = context.initialArgs,
      initialArgs = _context$initialArgs === void 0 ? {} : _context$initialArgs;
  var argTypes = mapValues(initialArgs, function (arg, key) {
    return {
      name: key,
      type: inferType(arg, "".concat(id, ".").concat(key), new Set())
    };
  });
  var userArgTypesNames = mapValues(userArgTypes, function (argType, key) {
    return {
      name: key
    };
  });
  return combineParameters(argTypes, userArgTypesNames, userArgTypes);
};
inferArgTypes.secondPass = true;