import "core-js/modules/es.regexp.exec.js";
import "core-js/modules/es.function.name.js";
import mapValues from 'lodash/mapValues';
import { logger } from '@storybook/client-logger';
import { filterArgTypes } from './filterArgTypes';
import { combineParameters } from './parameters';

var inferControl = function inferControl(argType, name, matchers) {
  var type = argType.type,
      options = argType.options;

  if (!type && !options) {
    return undefined;
  } // args that end with background or color e.g. iconColor


  if (matchers.color && matchers.color.test(name)) {
    var controlType = argType.type.name;

    if (controlType === 'string') {
      return {
        control: {
          type: 'color'
        }
      };
    }

    logger.warn("Addon controls: Control of type color only supports string, received \"".concat(controlType, "\" instead"));
  } // args that end with date e.g. purchaseDate


  if (matchers.date && matchers.date.test(name)) {
    return {
      control: {
        type: 'date'
      }
    };
  }

  switch (type.name) {
    case 'array':
      return {
        control: {
          type: 'object'
        }
      };

    case 'boolean':
      return {
        control: {
          type: 'boolean'
        }
      };

    case 'string':
      return {
        control: {
          type: 'text'
        }
      };

    case 'number':
      return {
        control: {
          type: 'number'
        }
      };

    case 'enum':
      {
        var _ref = type,
            value = _ref.value;
        return {
          control: {
            type: (value === null || value === void 0 ? void 0 : value.length) <= 5 ? 'radio' : 'select'
          },
          options: value
        };
      }

    case 'function':
    case 'symbol':
      return null;

    default:
      return {
        control: {
          type: options ? 'select' : 'object'
        }
      };
  }
};

export var inferControls = function inferControls(context) {
  var argTypes = context.argTypes,
      _context$parameters = context.parameters,
      __isArgsStory = _context$parameters.__isArgsStory,
      _context$parameters$c = _context$parameters.controls;
  _context$parameters$c = _context$parameters$c === void 0 ? {} : _context$parameters$c;
  var _context$parameters$c2 = _context$parameters$c.include,
      include = _context$parameters$c2 === void 0 ? null : _context$parameters$c2,
      _context$parameters$c3 = _context$parameters$c.exclude,
      exclude = _context$parameters$c3 === void 0 ? null : _context$parameters$c3,
      _context$parameters$c4 = _context$parameters$c.matchers,
      matchers = _context$parameters$c4 === void 0 ? {} : _context$parameters$c4;
  if (!__isArgsStory) return argTypes;
  var filteredArgTypes = filterArgTypes(argTypes, include, exclude);
  var withControls = mapValues(filteredArgTypes, function (argType, name) {
    return (argType === null || argType === void 0 ? void 0 : argType.type) && inferControl(argType, name, matchers);
  });
  return combineParameters(withControls, filteredArgTypes);
};
inferControls.secondPass = true;
export var argTypesEnhancers = [inferControls];