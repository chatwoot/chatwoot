"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.inferControls = exports.argTypesEnhancers = void 0;

require("core-js/modules/es.regexp.exec.js");

require("core-js/modules/es.function.name.js");

var _mapValues = _interopRequireDefault(require("lodash/mapValues"));

var _clientLogger = require("@storybook/client-logger");

var _filterArgTypes = require("./filterArgTypes");

var _parameters = require("./parameters");

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

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

    _clientLogger.logger.warn("Addon controls: Control of type color only supports string, received \"".concat(controlType, "\" instead"));
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

var inferControls = function inferControls(context) {
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
  var filteredArgTypes = (0, _filterArgTypes.filterArgTypes)(argTypes, include, exclude);
  var withControls = (0, _mapValues.default)(filteredArgTypes, function (argType, name) {
    return (argType === null || argType === void 0 ? void 0 : argType.type) && inferControl(argType, name, matchers);
  });
  return (0, _parameters.combineParameters)(withControls, filteredArgTypes);
};

exports.inferControls = inferControls;
inferControls.secondPass = true;
var argTypesEnhancers = [inferControls];
exports.argTypesEnhancers = argTypesEnhancers;