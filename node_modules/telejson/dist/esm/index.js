function ownKeys(object, enumerableOnly) { var keys = Object.keys(object); if (Object.getOwnPropertySymbols) { var symbols = Object.getOwnPropertySymbols(object); if (enumerableOnly) symbols = symbols.filter(function (sym) { return Object.getOwnPropertyDescriptor(object, sym).enumerable; }); keys.push.apply(keys, symbols); } return keys; }

function _objectSpread(target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i] != null ? arguments[i] : {}; if (i % 2) { ownKeys(Object(source), true).forEach(function (key) { _defineProperty(target, key, source[key]); }); } else if (Object.getOwnPropertyDescriptors) { Object.defineProperties(target, Object.getOwnPropertyDescriptors(source)); } else { ownKeys(Object(source)).forEach(function (key) { Object.defineProperty(target, key, Object.getOwnPropertyDescriptor(source, key)); }); } } return target; }

function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }

function _slicedToArray(arr, i) { return _arrayWithHoles(arr) || _iterableToArrayLimit(arr, i) || _unsupportedIterableToArray(arr, i) || _nonIterableRest(); }

function _nonIterableRest() { throw new TypeError("Invalid attempt to destructure non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen); }

function _arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

function _iterableToArrayLimit(arr, i) { if (typeof Symbol === "undefined" || !(Symbol.iterator in Object(arr))) return; var _arr = []; var _n = true; var _d = false; var _e = undefined; try { for (var _i = arr[Symbol.iterator](), _s; !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"] != null) _i["return"](); } finally { if (_d) throw _e; } } return _arr; }

function _arrayWithHoles(arr) { if (Array.isArray(arr)) return arr; }

import isRegExp from 'is-regex';
import isFunction from 'is-function';
import isSymbol from 'is-symbol';
import isObjectAny from 'isobject';
import get from 'lodash/get';
import memoize from 'memoizerific';
import { extractEventHiddenProperties } from './dom-event';
var isRunningInBrowser = typeof window !== 'undefined' && typeof window.document !== 'undefined'; // eslint-disable-next-line @typescript-eslint/ban-types, no-use-before-define

var isObject = isObjectAny;

var removeCodeComments = function removeCodeComments(code) {
  var inQuoteChar = null;
  var inBlockComment = false;
  var inLineComment = false;
  var inRegexLiteral = false;
  var newCode = '';

  if (code.indexOf('//') >= 0 || code.indexOf('/*') >= 0) {
    for (var i = 0; i < code.length; i += 1) {
      if (!inQuoteChar && !inBlockComment && !inLineComment && !inRegexLiteral) {
        if (code[i] === '"' || code[i] === "'" || code[i] === '`') {
          inQuoteChar = code[i];
        } else if (code[i] === '/' && code[i + 1] === '*') {
          inBlockComment = true;
        } else if (code[i] === '/' && code[i + 1] === '/') {
          inLineComment = true;
        } else if (code[i] === '/' && code[i + 1] !== '/') {
          inRegexLiteral = true;
        }
      } else {
        if (inQuoteChar && (code[i] === inQuoteChar && code[i - 1] !== '\\' || code[i] === '\n' && inQuoteChar !== '`')) {
          inQuoteChar = null;
        }

        if (inRegexLiteral && (code[i] === '/' && code[i - 1] !== '\\' || code[i] === '\n')) {
          inRegexLiteral = false;
        }

        if (inBlockComment && code[i - 1] === '/' && code[i - 2] === '*') {
          inBlockComment = false;
        }

        if (inLineComment && code[i] === '\n') {
          inLineComment = false;
        }
      }

      if (!inBlockComment && !inLineComment) {
        newCode += code[i];
      }
    }
  } else {
    newCode = code;
  }

  return newCode;
};

var cleanCode = memoize(10000)(function (code) {
  return removeCodeComments(code).replace(/\n\s*/g, '') // remove indents & newlines
  .trim();
});

var convertShorthandMethods = function convertShorthandMethods(key, stringified) {
  var fnHead = stringified.slice(0, stringified.indexOf('{'));
  var fnBody = stringified.slice(stringified.indexOf('{'));

  if (fnHead.includes('=>')) {
    // This is an arrow function
    return stringified;
  }

  if (fnHead.includes('function')) {
    // This is an anonymous function
    return stringified;
  }

  var modifiedHead = fnHead;
  modifiedHead = modifiedHead.replace(key, 'function');
  return modifiedHead + fnBody;
};

var dateFormat = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{3})?Z$/;
// eslint-disable-next-line no-useless-escape
export var isJSON = function isJSON(input) {
  return input.match(/^[\[\{\"\}].*[\]\}\"]$/);
};

function convertUnconventionalData(data) {
  if (!isObject(data)) {
    return data;
  }

  var result = data;
  var wasMutated = false; // `Event` has a weird structure, for details see `extractEventHiddenProperties` doc
  // Plus we need to check if running in a browser to ensure `Event` exist and
  // is really the dom Event class.

  if (isRunningInBrowser && data instanceof Event) {
    result = extractEventHiddenProperties(result);
    wasMutated = true;
  }

  result = Object.keys(result).reduce(function (acc, key) {
    try {
      var _result$key;

      // Try accessing a property to test if we are allowed to do so
      // eslint-disable-next-line no-unused-expressions
      (_result$key = result[key]) === null || _result$key === void 0 ? void 0 : _result$key.toJSON;
      acc[key] = result[key];
    } catch (err) {
      wasMutated = true;
    }

    return acc;
  }, {});
  return wasMutated ? result : data;
}

export var replacer = function replacer(options) {
  var objects;
  var map;
  var stack;
  var keys;
  return function replace(key, value) {
    try {
      //  very first iteration
      if (key === '') {
        keys = [];
        objects = new Map([[value, '[]']]);
        map = new Map();
        stack = [];
        return value;
      } // From the JSON.stringify's doc:
      // "The object in which the key was found is provided as the replacer's this parameter." thus one can control the depth


      var origin = map.get(this) || this;

      while (stack.length && origin !== stack[0]) {
        stack.shift();
        keys.pop();
      }

      if (typeof value === 'boolean') {
        return value;
      }

      if (value === undefined) {
        if (!options.allowUndefined) {
          return undefined;
        }

        return '_undefined_';
      }

      if (value === null) {
        return null;
      }

      if (typeof value === 'number') {
        if (value === -Infinity) {
          return '_-Infinity_';
        }

        if (value === Infinity) {
          return '_Infinity_';
        }

        if (Number.isNaN(value)) {
          return '_NaN_';
        }

        return value;
      }

      if (typeof value === 'bigint') {
        return "_bigint_".concat(value.toString());
      }

      if (typeof value === 'string') {
        if (dateFormat.test(value)) {
          if (!options.allowDate) {
            return undefined;
          }

          return "_date_".concat(value);
        }

        return value;
      }

      if (isRegExp(value)) {
        if (!options.allowRegExp) {
          return undefined;
        }

        return "_regexp_".concat(value.flags, "|").concat(value.source);
      }

      if (isFunction(value)) {
        if (!options.allowFunction) {
          return undefined;
        }

        var name = value.name;
        var stringified = value.toString();

        if (!stringified.match(/(\[native code\]|WEBPACK_IMPORTED_MODULE|__webpack_exports__|__webpack_require__)/)) {
          return "_function_".concat(name, "|").concat(cleanCode(convertShorthandMethods(key, stringified)));
        }

        return "_function_".concat(name, "|").concat(function () {}.toString());
      }

      if (isSymbol(value)) {
        if (!options.allowSymbol) {
          return undefined;
        }

        var globalRegistryKey = Symbol.keyFor(value);

        if (globalRegistryKey !== undefined) {
          return "_gsymbol_".concat(globalRegistryKey);
        }

        return "_symbol_".concat(value.toString().slice(7, -1));
      }

      if (stack.length >= options.maxDepth) {
        if (Array.isArray(value)) {
          return "[Array(".concat(value.length, ")]");
        }

        return '[Object]';
      }

      if (value === this) {
        return "_duplicate_".concat(JSON.stringify(keys));
      } // when it's a class and we don't want to support classes, skip


      if (value.constructor && value.constructor.name && value.constructor.name !== 'Object' && !Array.isArray(value) && !options.allowClass) {
        return undefined;
      }

      var found = objects.get(value);

      if (!found) {
        var converted = Array.isArray(value) ? value : convertUnconventionalData(value);

        if (value.constructor && value.constructor.name && value.constructor.name !== 'Object' && !Array.isArray(value) && options.allowClass) {
          try {
            Object.assign(converted, {
              '_constructor-name_': value.constructor.name
            });
          } catch (e) {// immutable objects can't be written to and throw
            // we could make a deep copy but if the user values the correct instance name,
            // the user should make the deep copy themselves.
          }
        }

        keys.push(key);
        stack.unshift(converted);
        objects.set(value, JSON.stringify(keys));

        if (value !== converted) {
          map.set(value, converted);
        }

        return converted;
      } //  actually, here's the only place where the keys keeping is useful


      return "_duplicate_".concat(found);
    } catch (e) {
      return undefined;
    }
  };
};
export var reviver = function reviver(options) {
  var refs = [];
  var root;
  return function revive(key, value) {
    // last iteration = root
    if (key === '') {
      root = value; // restore cyclic refs

      refs.forEach(function (_ref) {
        var target = _ref.target,
            container = _ref.container,
            replacement = _ref.replacement;
        var replacementArr = isJSON(replacement) ? JSON.parse(replacement) : replacement.split('.');

        if (replacementArr.length === 0) {
          // eslint-disable-next-line no-param-reassign
          container[target] = root;
        } else {
          // eslint-disable-next-line no-param-reassign
          container[target] = get(root, replacementArr);
        }
      });
    }

    if (key === '_constructor-name_') {
      return value;
    } // deal with instance names


    if (isObject(value) && value['_constructor-name_'] && options.allowFunction) {
      var name = value['_constructor-name_'];

      if (name !== 'Object') {
        // eslint-disable-next-line no-new-func
        var Fn = new Function("return function ".concat(name.replace(/[\W_]+/g, ''), "(){}"))();
        Object.setPrototypeOf(value, new Fn());
      } // eslint-disable-next-line no-param-reassign


      delete value['_constructor-name_'];
      return value;
    }

    if (typeof value === 'string' && value.startsWith('_function_') && options.allowFunction) {
      var _ref2 = value.match(/_function_([^|]*)\|(.*)/) || [],
          _ref3 = _slicedToArray(_ref2, 3),
          _name = _ref3[1],
          source = _ref3[2]; // eslint-disable-next-line no-useless-escape


      var sourceSanitized = source.replace(/[(\(\))|\\| |\]|`]*$/, '');

      if (!options.lazyEval) {
        // eslint-disable-next-line no-eval
        return eval("(".concat(sourceSanitized, ")"));
      } // lazy eval of the function


      var result = function result() {
        // eslint-disable-next-line no-eval
        var f = eval("(".concat(sourceSanitized, ")"));
        return f.apply(void 0, arguments);
      };

      Object.defineProperty(result, 'toString', {
        value: function value() {
          return sourceSanitized;
        }
      });
      Object.defineProperty(result, 'name', {
        value: _name
      });
      return result;
    }

    if (typeof value === 'string' && value.startsWith('_regexp_') && options.allowRegExp) {
      // this split isn't working correctly
      var _ref4 = value.match(/_regexp_([^|]*)\|(.*)/) || [],
          _ref5 = _slicedToArray(_ref4, 3),
          flags = _ref5[1],
          _source = _ref5[2];

      return new RegExp(_source, flags);
    }

    if (typeof value === 'string' && value.startsWith('_date_') && options.allowDate) {
      return new Date(value.replace('_date_', ''));
    }

    if (typeof value === 'string' && value.startsWith('_duplicate_')) {
      refs.push({
        target: key,
        container: this,
        replacement: value.replace(/^_duplicate_/, '')
      });
      return null;
    }

    if (typeof value === 'string' && value.startsWith('_symbol_') && options.allowSymbol) {
      return Symbol(value.replace('_symbol_', ''));
    }

    if (typeof value === 'string' && value.startsWith('_gsymbol_') && options.allowSymbol) {
      return Symbol["for"](value.replace('_gsymbol_', ''));
    }

    if (typeof value === 'string' && value === '_-Infinity_') {
      return -Infinity;
    }

    if (typeof value === 'string' && value === '_Infinity_') {
      return Infinity;
    }

    if (typeof value === 'string' && value === '_NaN_') {
      return NaN;
    }

    if (typeof value === 'string' && value.startsWith('_bigint_') && typeof BigInt === 'function') {
      return BigInt(value.replace('_bigint_', ''));
    }

    return value;
  };
};
var defaultOptions = {
  maxDepth: 10,
  space: undefined,
  allowFunction: true,
  allowRegExp: true,
  allowDate: true,
  allowClass: true,
  allowUndefined: true,
  allowSymbol: true,
  lazyEval: true
};
export var stringify = function stringify(data) {
  var options = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : {};

  var mergedOptions = _objectSpread(_objectSpread({}, defaultOptions), options);

  return JSON.stringify(convertUnconventionalData(data), replacer(mergedOptions), options.space);
};

var mutator = function mutator() {
  var mutated = new Map();
  return function mutateUndefined(value) {
    // JSON.parse will not output keys with value of undefined
    // we map over a deeply nester object, if we find any value with `_undefined_`, we mutate it to be undefined
    if (isObject(value)) {
      Object.entries(value).forEach(function (_ref6) {
        var _ref7 = _slicedToArray(_ref6, 2),
            k = _ref7[0],
            v = _ref7[1];

        if (v === '_undefined_') {
          // eslint-disable-next-line no-param-reassign
          value[k] = undefined;
        } else if (!mutated.get(v)) {
          mutated.set(v, true);
          mutateUndefined(v);
        }
      });
    }

    if (Array.isArray(value)) {
      value.forEach(function (v, index) {
        if (v === '_undefined_') {
          mutated.set(v, true); // eslint-disable-next-line no-param-reassign

          value[index] = undefined;
        } else if (!mutated.get(v)) {
          mutated.set(v, true);
          mutateUndefined(v);
        }
      });
    }
  };
};

export var parse = function parse(data) {
  var options = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : {};

  var mergedOptions = _objectSpread(_objectSpread({}, defaultOptions), options);

  var result = JSON.parse(data, reviver(mergedOptions));
  mutator()(result);
  return result;
};