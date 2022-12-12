"use strict";

require("core-js/modules/es.symbol.iterator.js");

require("core-js/modules/es.array.iterator.js");

require("core-js/modules/es.string.iterator.js");

require("core-js/modules/web.dom-collections.iterator.js");

require("core-js/modules/es.array.slice.js");

require("core-js/modules/es.array.from.js");

require("core-js/modules/es.regexp.exec.js");

require("core-js/modules/es.object.freeze.js");

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.deepDiff = exports.combineArgs = exports.NO_TARGET_NAME = exports.DEEPLY_EQUAL = void 0;
exports.groupArgsByTarget = groupArgsByTarget;
exports.mapArgsToTypes = void 0;
exports.noTargetArgs = noTargetArgs;
exports.validateOptions = void 0;

require("core-js/modules/es.symbol.js");

require("core-js/modules/es.symbol.description.js");

require("core-js/modules/es.object.to-string.js");

require("core-js/modules/es.function.name.js");

require("core-js/modules/es.number.constructor.js");

require("core-js/modules/es.object.entries.js");

require("core-js/modules/es.object.assign.js");

require("core-js/modules/es.array.filter.js");

require("core-js/modules/es.object.keys.js");

require("core-js/modules/es.array.includes.js");

require("core-js/modules/es.array.find-index.js");

require("core-js/modules/es.string.includes.js");

require("core-js/modules/es.array.concat.js");

require("core-js/modules/es.array.join.js");

require("core-js/modules/es.array.map.js");

require("core-js/modules/es.array.fill.js");

require("core-js/modules/web.dom-collections.for-each.js");

var _fastDeepEqual = _interopRequireDefault(require("fast-deep-equal"));

var _clientLogger = require("@storybook/client-logger");

var _isPlainObject = _interopRequireDefault(require("lodash/isPlainObject"));

var _tsDedent = _interopRequireDefault(require("ts-dedent"));

var _templateObject, _templateObject2;

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _taggedTemplateLiteral(strings, raw) { if (!raw) { raw = strings.slice(0); } return Object.freeze(Object.defineProperties(strings, { raw: { value: Object.freeze(raw) } })); }

function _toConsumableArray(arr) { return _arrayWithoutHoles(arr) || _iterableToArray(arr) || _unsupportedIterableToArray(arr) || _nonIterableSpread(); }

function _nonIterableSpread() { throw new TypeError("Invalid attempt to spread non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _iterableToArray(iter) { if (typeof Symbol !== "undefined" && iter[Symbol.iterator] != null || iter["@@iterator"] != null) return Array.from(iter); }

function _arrayWithoutHoles(arr) { if (Array.isArray(arr)) return _arrayLikeToArray(arr); }

function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }

function _slicedToArray(arr, i) { return _arrayWithHoles(arr) || _iterableToArrayLimit(arr, i) || _unsupportedIterableToArray(arr, i) || _nonIterableRest(); }

function _nonIterableRest() { throw new TypeError("Invalid attempt to destructure non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen); }

function _arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

function _iterableToArrayLimit(arr, i) { var _i = arr == null ? null : typeof Symbol !== "undefined" && arr[Symbol.iterator] || arr["@@iterator"]; if (_i == null) return; var _arr = []; var _n = true; var _d = false; var _s, _e; try { for (_i = _i.call(arr); !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"] != null) _i["return"](); } finally { if (_d) throw _e; } } return _arr; }

function _arrayWithHoles(arr) { if (Array.isArray(arr)) return arr; }

function _typeof(obj) { "@babel/helpers - typeof"; return _typeof = "function" == typeof Symbol && "symbol" == typeof Symbol.iterator ? function (obj) { return typeof obj; } : function (obj) { return obj && "function" == typeof Symbol && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; }, _typeof(obj); }

var INCOMPATIBLE = Symbol('incompatible');

var map = function map(arg, argType) {
  var type = argType.type;
  if (arg === undefined || arg === null || !type) return arg;

  if (argType.mapping) {
    return arg;
  }

  switch (type.name) {
    case 'string':
      return String(arg);

    case 'enum':
      return arg;

    case 'number':
      return Number(arg);

    case 'boolean':
      return arg === 'true';

    case 'array':
      if (!type.value || !Array.isArray(arg)) return INCOMPATIBLE;
      return arg.reduce(function (acc, item, index) {
        var mapped = map(item, {
          type: type.value
        });
        if (mapped !== INCOMPATIBLE) acc[index] = mapped;
        return acc;
      }, new Array(arg.length));

    case 'object':
      if (typeof arg === 'string' || typeof arg === 'number') return arg;
      if (!type.value || _typeof(arg) !== 'object') return INCOMPATIBLE;
      return Object.entries(arg).reduce(function (acc, _ref) {
        var _ref2 = _slicedToArray(_ref, 2),
            key = _ref2[0],
            val = _ref2[1];

        var mapped = map(val, {
          type: type.value[key]
        });
        return mapped === INCOMPATIBLE ? acc : Object.assign(acc, _defineProperty({}, key, mapped));
      }, {});

    default:
      return INCOMPATIBLE;
  }
};

var mapArgsToTypes = function mapArgsToTypes(args, argTypes) {
  return Object.entries(args).reduce(function (acc, _ref3) {
    var _ref4 = _slicedToArray(_ref3, 2),
        key = _ref4[0],
        value = _ref4[1];

    if (!argTypes[key]) return acc;
    var mapped = map(value, argTypes[key]);
    return mapped === INCOMPATIBLE ? acc : Object.assign(acc, _defineProperty({}, key, mapped));
  }, {});
};

exports.mapArgsToTypes = mapArgsToTypes;

var combineArgs = function combineArgs(value, update) {
  if (Array.isArray(value) && Array.isArray(update)) {
    return update.reduce(function (acc, upd, index) {
      acc[index] = combineArgs(value[index], update[index]);
      return acc;
    }, _toConsumableArray(value)).filter(function (v) {
      return v !== undefined;
    });
  }

  if (!(0, _isPlainObject.default)(value) || !(0, _isPlainObject.default)(update)) return update;
  return Object.keys(Object.assign({}, value, update)).reduce(function (acc, key) {
    if (key in update) {
      var combined = combineArgs(value[key], update[key]);
      if (combined !== undefined) acc[key] = combined;
    } else {
      acc[key] = value[key];
    }

    return acc;
  }, {});
};

exports.combineArgs = combineArgs;

var validateOptions = function validateOptions(args, argTypes) {
  return Object.entries(argTypes).reduce(function (acc, _ref5) {
    var _ref6 = _slicedToArray(_ref5, 2),
        key = _ref6[0],
        options = _ref6[1].options;

    // Don't set args that are not defined in `args` (they can be undefined in there)
    // see https://github.com/storybookjs/storybook/issues/15630 and
    //   https://github.com/storybookjs/storybook/issues/17063
    function allowArg() {
      if (key in args) {
        acc[key] = args[key];
      }

      return acc;
    }

    if (!options) return allowArg();

    if (!Array.isArray(options)) {
      _clientLogger.once.error((0, _tsDedent.default)(_templateObject || (_templateObject = _taggedTemplateLiteral(["\n        Invalid argType: '", ".options' should be an array.\n\n        More info: https://storybook.js.org/docs/react/api/argtypes\n      "])), key));

      return allowArg();
    }

    if (options.some(function (opt) {
      return opt && ['object', 'function'].includes(_typeof(opt));
    })) {
      _clientLogger.once.error((0, _tsDedent.default)(_templateObject2 || (_templateObject2 = _taggedTemplateLiteral(["\n        Invalid argType: '", ".options' should only contain primitives. Use a 'mapping' for complex values.\n\n        More info: https://storybook.js.org/docs/react/writing-stories/args#mapping-to-complex-arg-values\n      "])), key));

      return allowArg();
    }

    var isArray = Array.isArray(args[key]);
    var invalidIndex = isArray && args[key].findIndex(function (val) {
      return !options.includes(val);
    });
    var isValidArray = isArray && invalidIndex === -1;

    if (args[key] === undefined || options.includes(args[key]) || isValidArray) {
      return allowArg();
    }

    var field = isArray ? "".concat(key, "[").concat(invalidIndex, "]") : key;
    var supportedOptions = options.map(function (opt) {
      return typeof opt === 'string' ? "'".concat(opt, "'") : String(opt);
    }).join(', ');

    _clientLogger.once.warn("Received illegal value for '".concat(field, "'. Supported options: ").concat(supportedOptions));

    return acc;
  }, {});
}; // TODO -- copied from router, needs to be in a shared location


exports.validateOptions = validateOptions;
var DEEPLY_EQUAL = Symbol('Deeply equal');
exports.DEEPLY_EQUAL = DEEPLY_EQUAL;

var deepDiff = function deepDiff(value, update) {
  if (_typeof(value) !== _typeof(update)) return update;
  if ((0, _fastDeepEqual.default)(value, update)) return DEEPLY_EQUAL;

  if (Array.isArray(value) && Array.isArray(update)) {
    var res = update.reduce(function (acc, upd, index) {
      var diff = deepDiff(value[index], upd);
      if (diff !== DEEPLY_EQUAL) acc[index] = diff;
      return acc;
    }, new Array(update.length));
    if (update.length >= value.length) return res;
    return res.concat(new Array(value.length - update.length).fill(undefined));
  }

  if ((0, _isPlainObject.default)(value) && (0, _isPlainObject.default)(update)) {
    return Object.keys(Object.assign({}, value, update)).reduce(function (acc, key) {
      var diff = deepDiff(value === null || value === void 0 ? void 0 : value[key], update === null || update === void 0 ? void 0 : update[key]);
      return diff === DEEPLY_EQUAL ? acc : Object.assign(acc, _defineProperty({}, key, diff));
    }, {});
  }

  return update;
};

exports.deepDiff = deepDiff;
var NO_TARGET_NAME = '';
exports.NO_TARGET_NAME = NO_TARGET_NAME;

function groupArgsByTarget(_ref7) {
  var args = _ref7.args,
      argTypes = _ref7.argTypes;
  var groupedArgs = {};
  Object.entries(args).forEach(function (_ref8) {
    var _ref9 = _slicedToArray(_ref8, 2),
        name = _ref9[0],
        value = _ref9[1];

    var _ref10 = argTypes[name] || {},
        _ref10$target = _ref10.target,
        target = _ref10$target === void 0 ? NO_TARGET_NAME : _ref10$target;

    groupedArgs[target] = groupedArgs[target] || {};
    groupedArgs[target][name] = value;
  });
  return groupedArgs;
}

function noTargetArgs(context) {
  return groupArgsByTarget(context)[NO_TARGET_NAME];
}