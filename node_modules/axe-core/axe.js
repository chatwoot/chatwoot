/*! axe v4.2.0
 * Copyright (c) 2021 Deque Systems, Inc.
 *
 * Your use of this Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 *
 * This entire copyright notice must appear in every copy of this file you
 * distribute or in any file that contains substantial portions of this source
 * code.
 */
(function axeFunction(window) {
  var global = window;
  var document = window.document;
  'use strict';
  function _typeof(obj) {
    '@babel/helpers - typeof';
    if (typeof Symbol === 'function' && typeof Symbol.iterator === 'symbol') {
      _typeof = function _typeof(obj) {
        return typeof obj;
      };
    } else {
      _typeof = function _typeof(obj) {
        return obj && typeof Symbol === 'function' && obj.constructor === Symbol && obj !== Symbol.prototype ? 'symbol' : typeof obj;
      };
    }
    return _typeof(obj);
  }
  var axe = axe || {};
  axe.version = '4.2.0';
  if (typeof define === 'function' && define.amd) {
    define('axe-core', [], function() {
      return axe;
    });
  }
  if ((typeof module === 'undefined' ? 'undefined' : _typeof(module)) === 'object' && module.exports && typeof axeFunction.toString === 'function') {
    axe.source = '(' + axeFunction.toString() + ')(typeof window === "object" ? window : this);';
    module.exports = axe;
  }
  if (typeof window.getComputedStyle === 'function') {
    window.axe = axe;
  }
  var commons;
  function SupportError(error) {
    this.name = 'SupportError';
    this.cause = error.cause;
    this.message = '`'.concat(error.cause, '` - feature unsupported in your environment.');
    if (error.ruleId) {
      this.ruleId = error.ruleId;
      this.message += ' Skipping '.concat(this.ruleId, ' rule.');
    }
    this.stack = new Error().stack;
  }
  SupportError.prototype = Object.create(Error.prototype);
  SupportError.prototype.constructor = SupportError;
  'use strict';
  function _objectWithoutProperties(source, excluded) {
    if (source == null) {
      return {};
    }
    var target = _objectWithoutPropertiesLoose(source, excluded);
    var key, i;
    if (Object.getOwnPropertySymbols) {
      var sourceSymbolKeys = Object.getOwnPropertySymbols(source);
      for (i = 0; i < sourceSymbolKeys.length; i++) {
        key = sourceSymbolKeys[i];
        if (excluded.indexOf(key) >= 0) {
          continue;
        }
        if (!Object.prototype.propertyIsEnumerable.call(source, key)) {
          continue;
        }
        target[key] = source[key];
      }
    }
    return target;
  }
  function _objectWithoutPropertiesLoose(source, excluded) {
    if (source == null) {
      return {};
    }
    var target = {};
    var sourceKeys = Object.keys(source);
    var key, i;
    for (i = 0; i < sourceKeys.length; i++) {
      key = sourceKeys[i];
      if (excluded.indexOf(key) >= 0) {
        continue;
      }
      target[key] = source[key];
    }
    return target;
  }
  function _defineProperty(obj, key, value) {
    if (key in obj) {
      Object.defineProperty(obj, key, {
        value: value,
        enumerable: true,
        configurable: true,
        writable: true
      });
    } else {
      obj[key] = value;
    }
    return obj;
  }
  function _inherits(subClass, superClass) {
    if (typeof superClass !== 'function' && superClass !== null) {
      throw new TypeError('Super expression must either be null or a function');
    }
    subClass.prototype = Object.create(superClass && superClass.prototype, {
      constructor: {
        value: subClass,
        writable: true,
        configurable: true
      }
    });
    if (superClass) {
      _setPrototypeOf(subClass, superClass);
    }
  }
  function _setPrototypeOf(o, p) {
    _setPrototypeOf = Object.setPrototypeOf || function _setPrototypeOf(o, p) {
      o.__proto__ = p;
      return o;
    };
    return _setPrototypeOf(o, p);
  }
  function _createSuper(Derived) {
    var hasNativeReflectConstruct = _isNativeReflectConstruct();
    return function _createSuperInternal() {
      var Super = _getPrototypeOf(Derived), result;
      if (hasNativeReflectConstruct) {
        var NewTarget = _getPrototypeOf(this).constructor;
        result = Reflect.construct(Super, arguments, NewTarget);
      } else {
        result = Super.apply(this, arguments);
      }
      return _possibleConstructorReturn(this, result);
    };
  }
  function _possibleConstructorReturn(self, call) {
    if (call && (_typeof(call) === 'object' || typeof call === 'function')) {
      return call;
    }
    return _assertThisInitialized(self);
  }
  function _assertThisInitialized(self) {
    if (self === void 0) {
      throw new ReferenceError('this hasn\'t been initialised - super() hasn\'t been called');
    }
    return self;
  }
  function _isNativeReflectConstruct() {
    if (typeof Reflect === 'undefined' || !Reflect.construct) {
      return false;
    }
    if (Reflect.construct.sham) {
      return false;
    }
    if (typeof Proxy === 'function') {
      return true;
    }
    try {
      Date.prototype.toString.call(Reflect.construct(Date, [], function() {}));
      return true;
    } catch (e) {
      return false;
    }
  }
  function _getPrototypeOf(o) {
    _getPrototypeOf = Object.setPrototypeOf ? Object.getPrototypeOf : function _getPrototypeOf(o) {
      return o.__proto__ || Object.getPrototypeOf(o);
    };
    return _getPrototypeOf(o);
  }
  function _toConsumableArray(arr) {
    return _arrayWithoutHoles(arr) || _iterableToArray(arr) || _unsupportedIterableToArray(arr) || _nonIterableSpread();
  }
  function _nonIterableSpread() {
    throw new TypeError('Invalid attempt to spread non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method.');
  }
  function _iterableToArray(iter) {
    if (typeof Symbol !== 'undefined' && Symbol.iterator in Object(iter)) {
      return Array.from(iter);
    }
  }
  function _arrayWithoutHoles(arr) {
    if (Array.isArray(arr)) {
      return _arrayLikeToArray(arr);
    }
  }
  function _slicedToArray(arr, i) {
    return _arrayWithHoles(arr) || _iterableToArrayLimit(arr, i) || _unsupportedIterableToArray(arr, i) || _nonIterableRest();
  }
  function _nonIterableRest() {
    throw new TypeError('Invalid attempt to destructure non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method.');
  }
  function _iterableToArrayLimit(arr, i) {
    if (typeof Symbol === 'undefined' || !(Symbol.iterator in Object(arr))) {
      return;
    }
    var _arr = [];
    var _n = true;
    var _d = false;
    var _e = undefined;
    try {
      for (var _i = arr[Symbol.iterator](), _s; !(_n = (_s = _i.next()).done); _n = true) {
        _arr.push(_s.value);
        if (i && _arr.length === i) {
          break;
        }
      }
    } catch (err) {
      _d = true;
      _e = err;
    } finally {
      try {
        if (!_n && _i['return'] != null) {
          _i['return']();
        }
      } finally {
        if (_d) {
          throw _e;
        }
      }
    }
    return _arr;
  }
  function _arrayWithHoles(arr) {
    if (Array.isArray(arr)) {
      return arr;
    }
  }
  function _extends() {
    _extends = Object.assign || function(target) {
      for (var i = 1; i < arguments.length; i++) {
        var source = arguments[i];
        for (var key in source) {
          if (Object.prototype.hasOwnProperty.call(source, key)) {
            target[key] = source[key];
          }
        }
      }
      return target;
    };
    return _extends.apply(this, arguments);
  }
  function _classCallCheck(instance, Constructor) {
    if (!(instance instanceof Constructor)) {
      throw new TypeError('Cannot call a class as a function');
    }
  }
  function _defineProperties(target, props) {
    for (var i = 0; i < props.length; i++) {
      var descriptor = props[i];
      descriptor.enumerable = descriptor.enumerable || false;
      descriptor.configurable = true;
      if ('value' in descriptor) {
        descriptor.writable = true;
      }
      Object.defineProperty(target, descriptor.key, descriptor);
    }
  }
  function _createClass(Constructor, protoProps, staticProps) {
    if (protoProps) {
      _defineProperties(Constructor.prototype, protoProps);
    }
    if (staticProps) {
      _defineProperties(Constructor, staticProps);
    }
    return Constructor;
  }
  function _createForOfIteratorHelper(o, allowArrayLike) {
    var it;
    if (typeof Symbol === 'undefined' || o[Symbol.iterator] == null) {
      if (Array.isArray(o) || (it = _unsupportedIterableToArray(o)) || allowArrayLike && o && typeof o.length === 'number') {
        if (it) {
          o = it;
        }
        var i = 0;
        var F = function F() {};
        return {
          s: F,
          n: function n() {
            if (i >= o.length) {
              return {
                done: true
              };
            }
            return {
              done: false,
              value: o[i++]
            };
          },
          e: function e(_e2) {
            throw _e2;
          },
          f: F
        };
      }
      throw new TypeError('Invalid attempt to iterate non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method.');
    }
    var normalCompletion = true, didErr = false, err;
    return {
      s: function s() {
        it = o[Symbol.iterator]();
      },
      n: function n() {
        var step = it.next();
        normalCompletion = step.done;
        return step;
      },
      e: function e(_e3) {
        didErr = true;
        err = _e3;
      },
      f: function f() {
        try {
          if (!normalCompletion && it['return'] != null) {
            it['return']();
          }
        } finally {
          if (didErr) {
            throw err;
          }
        }
      }
    };
  }
  function _unsupportedIterableToArray(o, minLen) {
    if (!o) {
      return;
    }
    if (typeof o === 'string') {
      return _arrayLikeToArray(o, minLen);
    }
    var n = Object.prototype.toString.call(o).slice(8, -1);
    if (n === 'Object' && o.constructor) {
      n = o.constructor.name;
    }
    if (n === 'Map' || n === 'Set') {
      return Array.from(o);
    }
    if (n === 'Arguments' || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) {
      return _arrayLikeToArray(o, minLen);
    }
  }
  function _arrayLikeToArray(arr, len) {
    if (len == null || len > arr.length) {
      len = arr.length;
    }
    for (var i = 0, arr2 = new Array(len); i < len; i++) {
      arr2[i] = arr[i];
    }
    return arr2;
  }
  function _typeof(obj) {
    '@babel/helpers - typeof';
    if (typeof Symbol === 'function' && typeof Symbol.iterator === 'symbol') {
      _typeof = function _typeof(obj) {
        return typeof obj;
      };
    } else {
      _typeof = function _typeof(obj) {
        return obj && typeof Symbol === 'function' && obj.constructor === Symbol && obj !== Symbol.prototype ? 'symbol' : typeof obj;
      };
    }
    return _typeof(obj);
  }
  (function() {
    var __create = Object.create;
    var __defProp = Object.defineProperty;
    var __getProtoOf = Object.getPrototypeOf;
    var __hasOwnProp = Object.prototype.hasOwnProperty;
    var __getOwnPropNames = Object.getOwnPropertyNames;
    var __getOwnPropDesc = Object.getOwnPropertyDescriptor;
    var __markAsModule = function __markAsModule(target) {
      return __defProp(target, '__esModule', {
        value: true
      });
    };
    var __commonJS = function __commonJS(callback, module) {
      return function() {
        if (!module) {
          module = {
            exports: {}
          };
          callback(module.exports, module);
        }
        return module.exports;
      };
    };
    var __export = function __export(target, all) {
      __markAsModule(target);
      for (var name in all) {
        __defProp(target, name, {
          get: all[name],
          enumerable: true
        });
      }
    };
    var __exportStar = function __exportStar(target, module) {
      __markAsModule(target);
      if (_typeof(module) === 'object' || typeof module === 'function') {
        var _iterator = _createForOfIteratorHelper(__getOwnPropNames(module)), _step;
        try {
          var _loop = function _loop() {
            var key = _step.value;
            if (!__hasOwnProp.call(target, key) && key !== 'default') {
              __defProp(target, key, {
                get: function get() {
                  return module[key];
                },
                enumerable: __getOwnPropDesc(module, key).enumerable
              });
            }
          };
          for (_iterator.s(); !(_step = _iterator.n()).done; ) {
            _loop();
          }
        } catch (err) {
          _iterator.e(err);
        } finally {
          _iterator.f();
        }
      }
      return target;
    };
    var __toModule = function __toModule(module) {
      if (module && module.__esModule) {
        return module;
      }
      return __exportStar(__defProp(__create(__getProtoOf(module)), 'default', {
        value: module,
        enumerable: true
      }), module);
    };
    var require_utils = __commonJS(function(exports) {
      'use strict';
      Object.defineProperty(exports, '__esModule', {
        value: true
      });
      function isIdentStart(c) {
        return c >= 'a' && c <= 'z' || c >= 'A' && c <= 'Z' || c === '-' || c === '_';
      }
      exports.isIdentStart = isIdentStart;
      function isIdent(c) {
        return c >= 'a' && c <= 'z' || c >= 'A' && c <= 'Z' || c >= '0' && c <= '9' || c === '-' || c === '_';
      }
      exports.isIdent = isIdent;
      function isHex(c) {
        return c >= 'a' && c <= 'f' || c >= 'A' && c <= 'F' || c >= '0' && c <= '9';
      }
      exports.isHex = isHex;
      function escapeIdentifier(s) {
        var len = s.length;
        var result = '';
        var i = 0;
        while (i < len) {
          var chr = s.charAt(i);
          if (exports.identSpecialChars[chr]) {
            result += '\\' + chr;
          } else {
            if (!(chr === '_' || chr === '-' || chr >= 'A' && chr <= 'Z' || chr >= 'a' && chr <= 'z' || i !== 0 && chr >= '0' && chr <= '9')) {
              var charCode = chr.charCodeAt(0);
              if ((charCode & 63488) === 55296) {
                var extraCharCode = s.charCodeAt(i++);
                if ((charCode & 64512) !== 55296 || (extraCharCode & 64512) !== 56320) {
                  throw Error('UCS-2(decode): illegal sequence');
                }
                charCode = ((charCode & 1023) << 10) + (extraCharCode & 1023) + 65536;
              }
              result += '\\' + charCode.toString(16) + ' ';
            } else {
              result += chr;
            }
          }
          i++;
        }
        return result;
      }
      exports.escapeIdentifier = escapeIdentifier;
      function escapeStr(s) {
        var len = s.length;
        var result = '';
        var i = 0;
        var replacement;
        while (i < len) {
          var chr = s.charAt(i);
          if (chr === '"') {
            chr = '\\"';
          } else if (chr === '\\') {
            chr = '\\\\';
          } else if ((replacement = exports.strReplacementsRev[chr]) !== void 0) {
            chr = replacement;
          }
          result += chr;
          i++;
        }
        return '"' + result + '"';
      }
      exports.escapeStr = escapeStr;
      exports.identSpecialChars = {
        '!': true,
        '"': true,
        '#': true,
        $: true,
        '%': true,
        '&': true,
        '\'': true,
        '(': true,
        ')': true,
        '*': true,
        '+': true,
        ',': true,
        '.': true,
        '/': true,
        ';': true,
        '<': true,
        '=': true,
        '>': true,
        '?': true,
        '@': true,
        '[': true,
        '\\': true,
        ']': true,
        '^': true,
        '`': true,
        '{': true,
        '|': true,
        '}': true,
        '~': true
      };
      exports.strReplacementsRev = {
        '\n': '\\n',
        '\r': '\\r',
        '\t': '\\t',
        '\f': '\\f',
        '\v': '\\v'
      };
      exports.singleQuoteEscapeChars = {
        n: '\n',
        r: '\r',
        t: '\t',
        f: '\f',
        '\\': '\\',
        '\'': '\''
      };
      exports.doubleQuotesEscapeChars = {
        n: '\n',
        r: '\r',
        t: '\t',
        f: '\f',
        '\\': '\\',
        '"': '"'
      };
    });
    var require_parser_context = __commonJS(function(exports) {
      'use strict';
      Object.defineProperty(exports, '__esModule', {
        value: true
      });
      var utils_1 = require_utils();
      function parseCssSelector(str, pos, pseudos, attrEqualityMods, ruleNestingOperators, substitutesEnabled) {
        var l = str.length;
        var chr = '';
        function getStr(quote, escapeTable) {
          var result = '';
          pos++;
          chr = str.charAt(pos);
          while (pos < l) {
            if (chr === quote) {
              pos++;
              return result;
            } else if (chr === '\\') {
              pos++;
              chr = str.charAt(pos);
              var esc = void 0;
              if (chr === quote) {
                result += quote;
              } else if ((esc = escapeTable[chr]) !== void 0) {
                result += esc;
              } else if (utils_1.isHex(chr)) {
                var hex = chr;
                pos++;
                chr = str.charAt(pos);
                while (utils_1.isHex(chr)) {
                  hex += chr;
                  pos++;
                  chr = str.charAt(pos);
                }
                if (chr === ' ') {
                  pos++;
                  chr = str.charAt(pos);
                }
                result += String.fromCharCode(parseInt(hex, 16));
                continue;
              } else {
                result += chr;
              }
            } else {
              result += chr;
            }
            pos++;
            chr = str.charAt(pos);
          }
          return result;
        }
        function getIdent() {
          var result = '';
          chr = str.charAt(pos);
          while (pos < l) {
            if (utils_1.isIdent(chr)) {
              result += chr;
            } else if (chr === '\\') {
              pos++;
              if (pos >= l) {
                throw Error('Expected symbol but end of file reached.');
              }
              chr = str.charAt(pos);
              if (utils_1.identSpecialChars[chr]) {
                result += chr;
              } else if (utils_1.isHex(chr)) {
                var hex = chr;
                pos++;
                chr = str.charAt(pos);
                while (utils_1.isHex(chr)) {
                  hex += chr;
                  pos++;
                  chr = str.charAt(pos);
                }
                if (chr === ' ') {
                  pos++;
                  chr = str.charAt(pos);
                }
                result += String.fromCharCode(parseInt(hex, 16));
                continue;
              } else {
                result += chr;
              }
            } else {
              return result;
            }
            pos++;
            chr = str.charAt(pos);
          }
          return result;
        }
        function skipWhitespace() {
          chr = str.charAt(pos);
          var result = false;
          while (chr === ' ' || chr === '\t' || chr === '\n' || chr === '\r' || chr === '\f') {
            result = true;
            pos++;
            chr = str.charAt(pos);
          }
          return result;
        }
        function parse2() {
          var res = parseSelector();
          if (pos < l) {
            throw Error('Rule expected but "' + str.charAt(pos) + '" found.');
          }
          return res;
        }
        function parseSelector() {
          var selector = parseSingleSelector();
          if (!selector) {
            return null;
          }
          var res = selector;
          chr = str.charAt(pos);
          while (chr === ',') {
            pos++;
            skipWhitespace();
            if (res.type !== 'selectors') {
              res = {
                type: 'selectors',
                selectors: [ selector ]
              };
            }
            selector = parseSingleSelector();
            if (!selector) {
              throw Error('Rule expected after ",".');
            }
            res.selectors.push(selector);
          }
          return res;
        }
        function parseSingleSelector() {
          skipWhitespace();
          var selector = {
            type: 'ruleSet'
          };
          var rule3 = parseRule();
          if (!rule3) {
            return null;
          }
          var currentRule = selector;
          while (rule3) {
            rule3.type = 'rule';
            currentRule.rule = rule3;
            currentRule = rule3;
            skipWhitespace();
            chr = str.charAt(pos);
            if (pos >= l || chr === ',' || chr === ')') {
              break;
            }
            if (ruleNestingOperators[chr]) {
              var op = chr;
              pos++;
              skipWhitespace();
              rule3 = parseRule();
              if (!rule3) {
                throw Error('Rule expected after "' + op + '".');
              }
              rule3.nestingOperator = op;
            } else {
              rule3 = parseRule();
              if (rule3) {
                rule3.nestingOperator = null;
              }
            }
          }
          return selector;
        }
        function parseRule() {
          var rule3 = null;
          while (pos < l) {
            chr = str.charAt(pos);
            if (chr === '*') {
              pos++;
              (rule3 = rule3 || {}).tagName = '*';
            } else if (utils_1.isIdentStart(chr) || chr === '\\') {
              (rule3 = rule3 || {}).tagName = getIdent();
            } else if (chr === '.') {
              pos++;
              rule3 = rule3 || {};
              (rule3.classNames = rule3.classNames || []).push(getIdent());
            } else if (chr === '#') {
              pos++;
              (rule3 = rule3 || {}).id = getIdent();
            } else if (chr === '[') {
              pos++;
              skipWhitespace();
              var attr = {
                name: getIdent()
              };
              skipWhitespace();
              if (chr === ']') {
                pos++;
              } else {
                var operator = '';
                if (attrEqualityMods[chr]) {
                  operator = chr;
                  pos++;
                  chr = str.charAt(pos);
                }
                if (pos >= l) {
                  throw Error('Expected "=" but end of file reached.');
                }
                if (chr !== '=') {
                  throw Error('Expected "=" but "' + chr + '" found.');
                }
                attr.operator = operator + '=';
                pos++;
                skipWhitespace();
                var attrValue = '';
                attr.valueType = 'string';
                if (chr === '"') {
                  attrValue = getStr('"', utils_1.doubleQuotesEscapeChars);
                } else if (chr === '\'') {
                  attrValue = getStr('\'', utils_1.singleQuoteEscapeChars);
                } else if (substitutesEnabled && chr === '$') {
                  pos++;
                  attrValue = getIdent();
                  attr.valueType = 'substitute';
                } else {
                  while (pos < l) {
                    if (chr === ']') {
                      break;
                    }
                    attrValue += chr;
                    pos++;
                    chr = str.charAt(pos);
                  }
                  attrValue = attrValue.trim();
                }
                skipWhitespace();
                if (pos >= l) {
                  throw Error('Expected "]" but end of file reached.');
                }
                if (chr !== ']') {
                  throw Error('Expected "]" but "' + chr + '" found.');
                }
                pos++;
                attr.value = attrValue;
              }
              rule3 = rule3 || {};
              (rule3.attrs = rule3.attrs || []).push(attr);
            } else if (chr === ':') {
              pos++;
              var pseudoName = getIdent();
              var pseudo = {
                name: pseudoName
              };
              if (chr === '(') {
                pos++;
                var value = '';
                skipWhitespace();
                if (pseudos[pseudoName] === 'selector') {
                  pseudo.valueType = 'selector';
                  value = parseSelector();
                } else {
                  pseudo.valueType = pseudos[pseudoName] || 'string';
                  if (chr === '"') {
                    value = getStr('"', utils_1.doubleQuotesEscapeChars);
                  } else if (chr === '\'') {
                    value = getStr('\'', utils_1.singleQuoteEscapeChars);
                  } else if (substitutesEnabled && chr === '$') {
                    pos++;
                    value = getIdent();
                    pseudo.valueType = 'substitute';
                  } else {
                    while (pos < l) {
                      if (chr === ')') {
                        break;
                      }
                      value += chr;
                      pos++;
                      chr = str.charAt(pos);
                    }
                    value = value.trim();
                  }
                  skipWhitespace();
                }
                if (pos >= l) {
                  throw Error('Expected ")" but end of file reached.');
                }
                if (chr !== ')') {
                  throw Error('Expected ")" but "' + chr + '" found.');
                }
                pos++;
                pseudo.value = value;
              }
              rule3 = rule3 || {};
              (rule3.pseudos = rule3.pseudos || []).push(pseudo);
            } else {
              break;
            }
          }
          return rule3;
        }
        return parse2();
      }
      exports.parseCssSelector = parseCssSelector;
    });
    var require_render = __commonJS(function(exports) {
      'use strict';
      Object.defineProperty(exports, '__esModule', {
        value: true
      });
      var utils_1 = require_utils();
      function renderEntity(entity) {
        var res = '';
        switch (entity.type) {
         case 'ruleSet':
          var currentEntity = entity.rule;
          var parts = [];
          while (currentEntity) {
            if (currentEntity.nestingOperator) {
              parts.push(currentEntity.nestingOperator);
            }
            parts.push(renderEntity(currentEntity));
            currentEntity = currentEntity.rule;
          }
          res = parts.join(' ');
          break;

         case 'selectors':
          res = entity.selectors.map(renderEntity).join(', ');
          break;

         case 'rule':
          if (entity.tagName) {
            if (entity.tagName === '*') {
              res = '*';
            } else {
              res = utils_1.escapeIdentifier(entity.tagName);
            }
          }
          if (entity.id) {
            res += '#' + utils_1.escapeIdentifier(entity.id);
          }
          if (entity.classNames) {
            res += entity.classNames.map(function(cn) {
              return '.' + utils_1.escapeIdentifier(cn);
            }).join('');
          }
          if (entity.attrs) {
            res += entity.attrs.map(function(attr) {
              if ('operator' in attr) {
                if (attr.valueType === 'substitute') {
                  return '[' + utils_1.escapeIdentifier(attr.name) + attr.operator + '$' + attr.value + ']';
                } else {
                  return '[' + utils_1.escapeIdentifier(attr.name) + attr.operator + utils_1.escapeStr(attr.value) + ']';
                }
              } else {
                return '[' + utils_1.escapeIdentifier(attr.name) + ']';
              }
            }).join('');
          }
          if (entity.pseudos) {
            res += entity.pseudos.map(function(pseudo) {
              if (pseudo.valueType) {
                if (pseudo.valueType === 'selector') {
                  return ':' + utils_1.escapeIdentifier(pseudo.name) + '(' + renderEntity(pseudo.value) + ')';
                } else if (pseudo.valueType === 'substitute') {
                  return ':' + utils_1.escapeIdentifier(pseudo.name) + '($' + pseudo.value + ')';
                } else if (pseudo.valueType === 'numeric') {
                  return ':' + utils_1.escapeIdentifier(pseudo.name) + '(' + pseudo.value + ')';
                } else {
                  return ':' + utils_1.escapeIdentifier(pseudo.name) + '(' + utils_1.escapeIdentifier(pseudo.value) + ')';
                }
              } else {
                return ':' + utils_1.escapeIdentifier(pseudo.name);
              }
            }).join('');
          }
          break;

         default:
          throw Error('Unknown entity type: "' + entity.type + '".');
        }
        return res;
      }
      exports.renderEntity = renderEntity;
    });
    var require_lib = __commonJS(function(exports) {
      'use strict';
      Object.defineProperty(exports, '__esModule', {
        value: true
      });
      var parser_context_1 = require_parser_context();
      var render_1 = require_render();
      var CssSelectorParser3 = function() {
        function CssSelectorParser4() {
          this.pseudos = {};
          this.attrEqualityMods = {};
          this.ruleNestingOperators = {};
          this.substitutesEnabled = false;
        }
        CssSelectorParser4.prototype.registerSelectorPseudos = function() {
          var pseudos = [];
          for (var _i = 0; _i < arguments.length; _i++) {
            pseudos[_i] = arguments[_i];
          }
          for (var _a = 0, pseudos_1 = pseudos; _a < pseudos_1.length; _a++) {
            var pseudo = pseudos_1[_a];
            this.pseudos[pseudo] = 'selector';
          }
          return this;
        };
        CssSelectorParser4.prototype.unregisterSelectorPseudos = function() {
          var pseudos = [];
          for (var _i = 0; _i < arguments.length; _i++) {
            pseudos[_i] = arguments[_i];
          }
          for (var _a = 0, pseudos_2 = pseudos; _a < pseudos_2.length; _a++) {
            var pseudo = pseudos_2[_a];
            delete this.pseudos[pseudo];
          }
          return this;
        };
        CssSelectorParser4.prototype.registerNumericPseudos = function() {
          var pseudos = [];
          for (var _i = 0; _i < arguments.length; _i++) {
            pseudos[_i] = arguments[_i];
          }
          for (var _a = 0, pseudos_3 = pseudos; _a < pseudos_3.length; _a++) {
            var pseudo = pseudos_3[_a];
            this.pseudos[pseudo] = 'numeric';
          }
          return this;
        };
        CssSelectorParser4.prototype.unregisterNumericPseudos = function() {
          var pseudos = [];
          for (var _i = 0; _i < arguments.length; _i++) {
            pseudos[_i] = arguments[_i];
          }
          for (var _a = 0, pseudos_4 = pseudos; _a < pseudos_4.length; _a++) {
            var pseudo = pseudos_4[_a];
            delete this.pseudos[pseudo];
          }
          return this;
        };
        CssSelectorParser4.prototype.registerNestingOperators = function() {
          var operators = [];
          for (var _i = 0; _i < arguments.length; _i++) {
            operators[_i] = arguments[_i];
          }
          for (var _a = 0, operators_1 = operators; _a < operators_1.length; _a++) {
            var operator = operators_1[_a];
            this.ruleNestingOperators[operator] = true;
          }
          return this;
        };
        CssSelectorParser4.prototype.unregisterNestingOperators = function() {
          var operators = [];
          for (var _i = 0; _i < arguments.length; _i++) {
            operators[_i] = arguments[_i];
          }
          for (var _a = 0, operators_2 = operators; _a < operators_2.length; _a++) {
            var operator = operators_2[_a];
            delete this.ruleNestingOperators[operator];
          }
          return this;
        };
        CssSelectorParser4.prototype.registerAttrEqualityMods = function() {
          var mods = [];
          for (var _i = 0; _i < arguments.length; _i++) {
            mods[_i] = arguments[_i];
          }
          for (var _a = 0, mods_1 = mods; _a < mods_1.length; _a++) {
            var mod = mods_1[_a];
            this.attrEqualityMods[mod] = true;
          }
          return this;
        };
        CssSelectorParser4.prototype.unregisterAttrEqualityMods = function() {
          var mods = [];
          for (var _i = 0; _i < arguments.length; _i++) {
            mods[_i] = arguments[_i];
          }
          for (var _a = 0, mods_2 = mods; _a < mods_2.length; _a++) {
            var mod = mods_2[_a];
            delete this.attrEqualityMods[mod];
          }
          return this;
        };
        CssSelectorParser4.prototype.enableSubstitutes = function() {
          this.substitutesEnabled = true;
          return this;
        };
        CssSelectorParser4.prototype.disableSubstitutes = function() {
          this.substitutesEnabled = false;
          return this;
        };
        CssSelectorParser4.prototype.parse = function(str) {
          return parser_context_1.parseCssSelector(str, 0, this.pseudos, this.attrEqualityMods, this.ruleNestingOperators, this.substitutesEnabled);
        };
        CssSelectorParser4.prototype.render = function(path) {
          return render_1.renderEntity(path).trim();
        };
        return CssSelectorParser4;
      }();
      exports.CssSelectorParser = CssSelectorParser3;
    });
    var require_noop = __commonJS(function(exports, module) {
      'use strict';
      module.exports = function() {};
    });
    var require_is_value = __commonJS(function(exports, module) {
      'use strict';
      var _undefined = require_noop()();
      module.exports = function(val) {
        return val !== _undefined && val !== null;
      };
    });
    var require_normalize_options = __commonJS(function(exports, module) {
      'use strict';
      var isValue = require_is_value();
      var forEach = Array.prototype.forEach;
      var create = Object.create;
      var process2 = function process2(src, obj) {
        var key;
        for (key in src) {
          obj[key] = src[key];
        }
      };
      module.exports = function(opts1) {
        var result = create(null);
        forEach.call(arguments, function(options) {
          if (!isValue(options)) {
            return;
          }
          process2(Object(options), result);
        });
        return result;
      };
    });
    var require_is_implemented = __commonJS(function(exports, module) {
      'use strict';
      module.exports = function() {
        var sign = Math.sign;
        if (typeof sign !== 'function') {
          return false;
        }
        return sign(10) === 1 && sign(-20) === -1;
      };
    });
    var require_shim = __commonJS(function(exports, module) {
      'use strict';
      module.exports = function(value) {
        value = Number(value);
        if (isNaN(value) || value === 0) {
          return value;
        }
        return value > 0 ? 1 : -1;
      };
    });
    var require_sign = __commonJS(function(exports, module) {
      'use strict';
      module.exports = require_is_implemented()() ? Math.sign : require_shim();
    });
    var require_to_integer = __commonJS(function(exports, module) {
      'use strict';
      var sign = require_sign();
      var abs = Math.abs;
      var floor = Math.floor;
      module.exports = function(value) {
        if (isNaN(value)) {
          return 0;
        }
        value = Number(value);
        if (value === 0 || !isFinite(value)) {
          return value;
        }
        return sign(value) * floor(abs(value));
      };
    });
    var require_to_pos_integer = __commonJS(function(exports, module) {
      'use strict';
      var toInteger = require_to_integer();
      var max = Math.max;
      module.exports = function(value) {
        return max(0, toInteger(value));
      };
    });
    var require_resolve_length = __commonJS(function(exports, module) {
      'use strict';
      var toPosInt = require_to_pos_integer();
      module.exports = function(optsLength, fnLength, isAsync) {
        var length;
        if (isNaN(optsLength)) {
          length = fnLength;
          if (!(length >= 0)) {
            return 1;
          }
          if (isAsync && length) {
            return length - 1;
          }
          return length;
        }
        if (optsLength === false) {
          return false;
        }
        return toPosInt(optsLength);
      };
    });
    var require_valid_callable = __commonJS(function(exports, module) {
      'use strict';
      module.exports = function(fn) {
        if (typeof fn !== 'function') {
          throw new TypeError(fn + ' is not a function');
        }
        return fn;
      };
    });
    var require_valid_value = __commonJS(function(exports, module) {
      'use strict';
      var isValue = require_is_value();
      module.exports = function(value) {
        if (!isValue(value)) {
          throw new TypeError('Cannot use null or undefined');
        }
        return value;
      };
    });
    var require_iterate = __commonJS(function(exports, module) {
      'use strict';
      var callable = require_valid_callable();
      var value = require_valid_value();
      var bind = Function.prototype.bind;
      var call = Function.prototype.call;
      var keys = Object.keys;
      var objPropertyIsEnumerable = Object.prototype.propertyIsEnumerable;
      module.exports = function(method, defVal) {
        return function(obj, cb) {
          var list, thisArg = arguments[2], compareFn = arguments[3];
          obj = Object(value(obj));
          callable(cb);
          list = keys(obj);
          if (compareFn) {
            list.sort(typeof compareFn === 'function' ? bind.call(compareFn, obj) : void 0);
          }
          if (typeof method !== 'function') {
            method = list[method];
          }
          return call.call(method, list, function(key, index) {
            if (!objPropertyIsEnumerable.call(obj, key)) {
              return defVal;
            }
            return call.call(cb, thisArg, obj[key], key, obj, index);
          });
        };
      };
    });
    var require_for_each = __commonJS(function(exports, module) {
      'use strict';
      module.exports = require_iterate()('forEach');
    });
    var require_registered_extensions = __commonJS(function() {
      'use strict';
    });
    var require_is_implemented2 = __commonJS(function(exports, module) {
      'use strict';
      module.exports = function() {
        var assign = Object.assign, obj;
        if (typeof assign !== 'function') {
          return false;
        }
        obj = {
          foo: 'raz'
        };
        assign(obj, {
          bar: 'dwa'
        }, {
          trzy: 'trzy'
        });
        return obj.foo + obj.bar + obj.trzy === 'razdwatrzy';
      };
    });
    var require_is_implemented3 = __commonJS(function(exports, module) {
      'use strict';
      module.exports = function() {
        try {
          Object.keys('primitive');
          return true;
        } catch (e) {
          return false;
        }
      };
    });
    var require_shim2 = __commonJS(function(exports, module) {
      'use strict';
      var isValue = require_is_value();
      var keys = Object.keys;
      module.exports = function(object) {
        return keys(isValue(object) ? Object(object) : object);
      };
    });
    var require_keys = __commonJS(function(exports, module) {
      'use strict';
      module.exports = require_is_implemented3()() ? Object.keys : require_shim2();
    });
    var require_shim3 = __commonJS(function(exports, module) {
      'use strict';
      var keys = require_keys();
      var value = require_valid_value();
      var max = Math.max;
      module.exports = function(dest, src) {
        var error, i, length = max(arguments.length, 2), assign;
        dest = Object(value(dest));
        assign = function assign(key) {
          try {
            dest[key] = src[key];
          } catch (e) {
            if (!error) {
              error = e;
            }
          }
        };
        for (i = 1; i < length; ++i) {
          src = arguments[i];
          keys(src).forEach(assign);
        }
        if (error !== void 0) {
          throw error;
        }
        return dest;
      };
    });
    var require_assign = __commonJS(function(exports, module) {
      'use strict';
      module.exports = require_is_implemented2()() ? Object.assign : require_shim3();
    });
    var require_is_object = __commonJS(function(exports, module) {
      'use strict';
      var isValue = require_is_value();
      var map = {
        function: true,
        object: true
      };
      module.exports = function(value) {
        return isValue(value) && map[_typeof(value)] || false;
      };
    });
    var require_custom = __commonJS(function(exports, module) {
      'use strict';
      var assign = require_assign();
      var isObject = require_is_object();
      var isValue = require_is_value();
      var captureStackTrace = Error.captureStackTrace;
      module.exports = function(message) {
        var err2 = new Error(message), code = arguments[1], ext = arguments[2];
        if (!isValue(ext)) {
          if (isObject(code)) {
            ext = code;
            code = null;
          }
        }
        if (isValue(ext)) {
          assign(err2, ext);
        }
        if (isValue(code)) {
          err2.code = code;
        }
        if (captureStackTrace) {
          captureStackTrace(err2, module.exports);
        }
        return err2;
      };
    });
    var require_mixin = __commonJS(function(exports, module) {
      'use strict';
      var value = require_valid_value();
      var defineProperty = Object.defineProperty;
      var getOwnPropertyDescriptor = Object.getOwnPropertyDescriptor;
      var getOwnPropertyNames = Object.getOwnPropertyNames;
      var getOwnPropertySymbols = Object.getOwnPropertySymbols;
      module.exports = function(target, source) {
        var error, sourceObject = Object(value(source));
        target = Object(value(target));
        getOwnPropertyNames(sourceObject).forEach(function(name) {
          try {
            defineProperty(target, name, getOwnPropertyDescriptor(source, name));
          } catch (e) {
            error = e;
          }
        });
        if (typeof getOwnPropertySymbols === 'function') {
          getOwnPropertySymbols(sourceObject).forEach(function(symbol) {
            try {
              defineProperty(target, symbol, getOwnPropertyDescriptor(source, symbol));
            } catch (e) {
              error = e;
            }
          });
        }
        if (error !== void 0) {
          throw error;
        }
        return target;
      };
    });
    var require_define_length = __commonJS(function(exports, module) {
      'use strict';
      var toPosInt = require_to_pos_integer();
      var test = function test(arg1, arg2) {
        return arg2;
      };
      var desc;
      var defineProperty;
      var generate;
      var mixin;
      try {
        Object.defineProperty(test, 'length', {
          configurable: true,
          writable: false,
          enumerable: false,
          value: 1
        });
      } catch (ignore) {}
      if (test.length === 1) {
        desc = {
          configurable: true,
          writable: false,
          enumerable: false
        };
        defineProperty = Object.defineProperty;
        module.exports = function(fn, length) {
          length = toPosInt(length);
          if (fn.length === length) {
            return fn;
          }
          desc.value = length;
          return defineProperty(fn, 'length', desc);
        };
      } else {
        mixin = require_mixin();
        generate = function() {
          var cache20 = [];
          return function(length) {
            var args, i = 0;
            if (cache20[length]) {
              return cache20[length];
            }
            args = [];
            while (length--) {
              args.push('a' + (++i).toString(36));
            }
            return new Function('fn', 'return function (' + args.join(', ') + ') { return fn.apply(this, arguments); };');
          };
        }();
        module.exports = function(src, length) {
          var target;
          length = toPosInt(length);
          if (src.length === length) {
            return src;
          }
          target = generate(length)(src);
          try {
            mixin(target, src);
          } catch (ignore) {}
          return target;
        };
      }
    });
    var require_is = __commonJS(function(exports, module) {
      'use strict';
      var _undefined = void 0;
      module.exports = function(value) {
        return value !== _undefined && value !== null;
      };
    });
    var require_is2 = __commonJS(function(exports, module) {
      'use strict';
      var isValue = require_is();
      var possibleTypes = {
        object: true,
        function: true,
        undefined: true
      };
      module.exports = function(value) {
        if (!isValue(value)) {
          return false;
        }
        return hasOwnProperty.call(possibleTypes, _typeof(value));
      };
    });
    var require_is3 = __commonJS(function(exports, module) {
      'use strict';
      var isObject = require_is2();
      module.exports = function(value) {
        if (!isObject(value)) {
          return false;
        }
        try {
          if (!value.constructor) {
            return false;
          }
          return value.constructor.prototype === value;
        } catch (error) {
          return false;
        }
      };
    });
    var require_is4 = __commonJS(function(exports, module) {
      'use strict';
      var isPrototype = require_is3();
      module.exports = function(value) {
        if (typeof value !== 'function') {
          return false;
        }
        if (!hasOwnProperty.call(value, 'length')) {
          return false;
        }
        try {
          if (typeof value.length !== 'number') {
            return false;
          }
          if (typeof value.call !== 'function') {
            return false;
          }
          if (typeof value.apply !== 'function') {
            return false;
          }
        } catch (error) {
          return false;
        }
        return !isPrototype(value);
      };
    });
    var require_is5 = __commonJS(function(exports, module) {
      'use strict';
      var isFunction = require_is4();
      var classRe = /^\s*class[\s{/}]/;
      var functionToString = Function.prototype.toString;
      module.exports = function(value) {
        if (!isFunction(value)) {
          return false;
        }
        if (classRe.test(functionToString.call(value))) {
          return false;
        }
        return true;
      };
    });
    var require_is_implemented4 = __commonJS(function(exports, module) {
      'use strict';
      var str = 'razdwatrzy';
      module.exports = function() {
        if (typeof str.contains !== 'function') {
          return false;
        }
        return str.contains('dwa') === true && str.contains('foo') === false;
      };
    });
    var require_shim4 = __commonJS(function(exports, module) {
      'use strict';
      var indexOf = String.prototype.indexOf;
      module.exports = function(searchString) {
        return indexOf.call(this, searchString, arguments[1]) > -1;
      };
    });
    var require_contains = __commonJS(function(exports, module) {
      'use strict';
      module.exports = require_is_implemented4()() ? String.prototype.contains : require_shim4();
    });
    var require_d = __commonJS(function(exports, module) {
      'use strict';
      var isValue = require_is();
      var isPlainFunction = require_is5();
      var assign = require_assign();
      var normalizeOpts = require_normalize_options();
      var contains6 = require_contains();
      var d = module.exports = function(dscr, value) {
        var c, e, w, options, desc;
        if (arguments.length < 2 || typeof dscr !== 'string') {
          options = value;
          value = dscr;
          dscr = null;
        } else {
          options = arguments[2];
        }
        if (isValue(dscr)) {
          c = contains6.call(dscr, 'c');
          e = contains6.call(dscr, 'e');
          w = contains6.call(dscr, 'w');
        } else {
          c = w = true;
          e = false;
        }
        desc = {
          value: value,
          configurable: c,
          enumerable: e,
          writable: w
        };
        return !options ? desc : assign(normalizeOpts(options), desc);
      };
      d.gs = function(dscr, get, set) {
        var c, e, options, desc;
        if (typeof dscr !== 'string') {
          options = set;
          set = get;
          get = dscr;
          dscr = null;
        } else {
          options = arguments[3];
        }
        if (!isValue(get)) {
          get = void 0;
        } else if (!isPlainFunction(get)) {
          options = get;
          get = set = void 0;
        } else if (!isValue(set)) {
          set = void 0;
        } else if (!isPlainFunction(set)) {
          options = set;
          set = void 0;
        }
        if (isValue(dscr)) {
          c = contains6.call(dscr, 'c');
          e = contains6.call(dscr, 'e');
        } else {
          c = true;
          e = false;
        }
        desc = {
          get: get,
          set: set,
          configurable: c,
          enumerable: e
        };
        return !options ? desc : assign(normalizeOpts(options), desc);
      };
    });
    var require_event_emitter = __commonJS(function(exports, module) {
      'use strict';
      var d = require_d();
      var callable = require_valid_callable();
      var apply = Function.prototype.apply;
      var call = Function.prototype.call;
      var create = Object.create;
      var defineProperty = Object.defineProperty;
      var defineProperties = Object.defineProperties;
      var hasOwnProperty2 = Object.prototype.hasOwnProperty;
      var descriptor = {
        configurable: true,
        enumerable: false,
        writable: true
      };
      var on;
      var once;
      var off;
      var emit;
      var methods;
      var descriptors;
      var base;
      on = function on(type, listener) {
        var data2;
        callable(listener);
        if (!hasOwnProperty2.call(this, '__ee__')) {
          data2 = descriptor.value = create(null);
          defineProperty(this, '__ee__', descriptor);
          descriptor.value = null;
        } else {
          data2 = this.__ee__;
        }
        if (!data2[type]) {
          data2[type] = listener;
        } else if (_typeof(data2[type]) === 'object') {
          data2[type].push(listener);
        } else {
          data2[type] = [ data2[type], listener ];
        }
        return this;
      };
      once = function once(type, listener) {
        var _once, self2;
        callable(listener);
        self2 = this;
        on.call(this, type, _once = function once2() {
          off.call(self2, type, _once);
          apply.call(listener, this, arguments);
        });
        _once.__eeOnceListener__ = listener;
        return this;
      };
      off = function off(type, listener) {
        var data2, listeners, candidate, i;
        callable(listener);
        if (!hasOwnProperty2.call(this, '__ee__')) {
          return this;
        }
        data2 = this.__ee__;
        if (!data2[type]) {
          return this;
        }
        listeners = data2[type];
        if (_typeof(listeners) === 'object') {
          for (i = 0; candidate = listeners[i]; ++i) {
            if (candidate === listener || candidate.__eeOnceListener__ === listener) {
              if (listeners.length === 2) {
                data2[type] = listeners[i ? 0 : 1];
              } else {
                listeners.splice(i, 1);
              }
            }
          }
        } else {
          if (listeners === listener || listeners.__eeOnceListener__ === listener) {
            delete data2[type];
          }
        }
        return this;
      };
      emit = function emit(type) {
        var i, l, listener, listeners, args;
        if (!hasOwnProperty2.call(this, '__ee__')) {
          return;
        }
        listeners = this.__ee__[type];
        if (!listeners) {
          return;
        }
        if (_typeof(listeners) === 'object') {
          l = arguments.length;
          args = new Array(l - 1);
          for (i = 1; i < l; ++i) {
            args[i - 1] = arguments[i];
          }
          listeners = listeners.slice();
          for (i = 0; listener = listeners[i]; ++i) {
            apply.call(listener, this, args);
          }
        } else {
          switch (arguments.length) {
           case 1:
            call.call(listeners, this);
            break;

           case 2:
            call.call(listeners, this, arguments[1]);
            break;

           case 3:
            call.call(listeners, this, arguments[1], arguments[2]);
            break;

           default:
            l = arguments.length;
            args = new Array(l - 1);
            for (i = 1; i < l; ++i) {
              args[i - 1] = arguments[i];
            }
            apply.call(listeners, this, args);
          }
        }
      };
      methods = {
        on: on,
        once: once,
        off: off,
        emit: emit
      };
      descriptors = {
        on: d(on),
        once: d(once),
        off: d(off),
        emit: d(emit)
      };
      base = defineProperties({}, descriptors);
      module.exports = exports = function exports(o) {
        return o == null ? create(base) : defineProperties(Object(o), descriptors);
      };
      exports.methods = methods;
    });
    var require_is_implemented5 = __commonJS(function(exports, module) {
      'use strict';
      module.exports = function() {
        var from = Array.from, arr, result;
        if (typeof from !== 'function') {
          return false;
        }
        arr = [ 'raz', 'dwa' ];
        result = from(arr);
        return Boolean(result && result !== arr && result[1] === 'dwa');
      };
    });
    var require_is_implemented6 = __commonJS(function(exports, module) {
      'use strict';
      module.exports = function() {
        if ((typeof globalThis === 'undefined' ? 'undefined' : _typeof(globalThis)) !== 'object') {
          return false;
        }
        if (!globalThis) {
          return false;
        }
        return globalThis.Array === Array;
      };
    });
    var require_implementation = __commonJS(function(exports, module) {
      var naiveFallback = function naiveFallback() {
        if ((typeof self === 'undefined' ? 'undefined' : _typeof(self)) === 'object' && self) {
          return self;
        }
        if ((typeof window === 'undefined' ? 'undefined' : _typeof(window)) === 'object' && window) {
          return window;
        }
        throw new Error('Unable to resolve global `this`');
      };
      module.exports = function() {
        if (this) {
          return this;
        }
        try {
          Object.defineProperty(Object.prototype, '__global__', {
            get: function get() {
              return this;
            },
            configurable: true
          });
        } catch (error) {
          return naiveFallback();
        }
        try {
          if (!__global__) {
            return naiveFallback();
          }
          return __global__;
        } finally {
          delete Object.prototype.__global__;
        }
      }();
    });
    var require_global_this = __commonJS(function(exports, module) {
      'use strict';
      module.exports = require_is_implemented6()() ? globalThis : require_implementation();
    });
    var require_is_implemented7 = __commonJS(function(exports, module) {
      'use strict';
      var global2 = require_global_this();
      var validTypes = {
        object: true,
        symbol: true
      };
      module.exports = function() {
        var _Symbol = global2.Symbol;
        var symbol;
        if (typeof _Symbol !== 'function') {
          return false;
        }
        symbol = _Symbol('test symbol');
        try {
          String(symbol);
        } catch (e) {
          return false;
        }
        if (!validTypes[_typeof(_Symbol.iterator)]) {
          return false;
        }
        if (!validTypes[_typeof(_Symbol.toPrimitive)]) {
          return false;
        }
        if (!validTypes[_typeof(_Symbol.toStringTag)]) {
          return false;
        }
        return true;
      };
    });
    var require_is_symbol = __commonJS(function(exports, module) {
      'use strict';
      module.exports = function(value) {
        if (!value) {
          return false;
        }
        if (_typeof(value) === 'symbol') {
          return true;
        }
        if (!value.constructor) {
          return false;
        }
        if (value.constructor.name !== 'Symbol') {
          return false;
        }
        return value[value.constructor.toStringTag] === 'Symbol';
      };
    });
    var require_validate_symbol = __commonJS(function(exports, module) {
      'use strict';
      var isSymbol = require_is_symbol();
      module.exports = function(value) {
        if (!isSymbol(value)) {
          throw new TypeError(value + ' is not a symbol');
        }
        return value;
      };
    });
    var require_generate_name = __commonJS(function(exports, module) {
      'use strict';
      var d = require_d();
      var create = Object.create;
      var defineProperty = Object.defineProperty;
      var objPrototype = Object.prototype;
      var created = create(null);
      module.exports = function(desc) {
        var postfix = 0, name, ie11BugWorkaround;
        while (created[desc + (postfix || '')]) {
          ++postfix;
        }
        desc += postfix || '';
        created[desc] = true;
        name = '@@' + desc;
        defineProperty(objPrototype, name, d.gs(null, function(value) {
          if (ie11BugWorkaround) {
            return;
          }
          ie11BugWorkaround = true;
          defineProperty(this, name, d(value));
          ie11BugWorkaround = false;
        }));
        return name;
      };
    });
    var require_standard_symbols = __commonJS(function(exports, module) {
      'use strict';
      var d = require_d();
      var NativeSymbol = require_global_this().Symbol;
      module.exports = function(SymbolPolyfill) {
        return Object.defineProperties(SymbolPolyfill, {
          hasInstance: d('', NativeSymbol && NativeSymbol.hasInstance || SymbolPolyfill('hasInstance')),
          isConcatSpreadable: d('', NativeSymbol && NativeSymbol.isConcatSpreadable || SymbolPolyfill('isConcatSpreadable')),
          iterator: d('', NativeSymbol && NativeSymbol.iterator || SymbolPolyfill('iterator')),
          match: d('', NativeSymbol && NativeSymbol.match || SymbolPolyfill('match')),
          replace: d('', NativeSymbol && NativeSymbol.replace || SymbolPolyfill('replace')),
          search: d('', NativeSymbol && NativeSymbol.search || SymbolPolyfill('search')),
          species: d('', NativeSymbol && NativeSymbol.species || SymbolPolyfill('species')),
          split: d('', NativeSymbol && NativeSymbol.split || SymbolPolyfill('split')),
          toPrimitive: d('', NativeSymbol && NativeSymbol.toPrimitive || SymbolPolyfill('toPrimitive')),
          toStringTag: d('', NativeSymbol && NativeSymbol.toStringTag || SymbolPolyfill('toStringTag')),
          unscopables: d('', NativeSymbol && NativeSymbol.unscopables || SymbolPolyfill('unscopables'))
        });
      };
    });
    var require_symbol_registry = __commonJS(function(exports, module) {
      'use strict';
      var d = require_d();
      var validateSymbol = require_validate_symbol();
      var registry = Object.create(null);
      module.exports = function(SymbolPolyfill) {
        return Object.defineProperties(SymbolPolyfill, {
          for: d(function(key) {
            if (registry[key]) {
              return registry[key];
            }
            return registry[key] = SymbolPolyfill(String(key));
          }),
          keyFor: d(function(symbol) {
            var key;
            validateSymbol(symbol);
            for (key in registry) {
              if (registry[key] === symbol) {
                return key;
              }
            }
            return void 0;
          })
        });
      };
    });
    var require_polyfill = __commonJS(function(exports, module) {
      'use strict';
      var d = require_d();
      var validateSymbol = require_validate_symbol();
      var NativeSymbol = require_global_this().Symbol;
      var generateName = require_generate_name();
      var setupStandardSymbols = require_standard_symbols();
      var setupSymbolRegistry = require_symbol_registry();
      var create = Object.create;
      var defineProperties = Object.defineProperties;
      var defineProperty = Object.defineProperty;
      var SymbolPolyfill;
      var HiddenSymbol;
      var isNativeSafe;
      if (typeof NativeSymbol === 'function') {
        try {
          String(NativeSymbol());
          isNativeSafe = true;
        } catch (ignore) {}
      } else {
        NativeSymbol = null;
      }
      HiddenSymbol = function _Symbol2(description) {
        if (this instanceof HiddenSymbol) {
          throw new TypeError('Symbol is not a constructor');
        }
        return SymbolPolyfill(description);
      };
      module.exports = SymbolPolyfill = function _Symbol3(description) {
        var symbol;
        if (this instanceof _Symbol3) {
          throw new TypeError('Symbol is not a constructor');
        }
        if (isNativeSafe) {
          return NativeSymbol(description);
        }
        symbol = create(HiddenSymbol.prototype);
        description = description === void 0 ? '' : String(description);
        return defineProperties(symbol, {
          __description__: d('', description),
          __name__: d('', generateName(description))
        });
      };
      setupStandardSymbols(SymbolPolyfill);
      setupSymbolRegistry(SymbolPolyfill);
      defineProperties(HiddenSymbol.prototype, {
        constructor: d(SymbolPolyfill),
        toString: d('', function() {
          return this.__name__;
        })
      });
      defineProperties(SymbolPolyfill.prototype, {
        toString: d(function() {
          return 'Symbol (' + validateSymbol(this).__description__ + ')';
        }),
        valueOf: d(function() {
          return validateSymbol(this);
        })
      });
      defineProperty(SymbolPolyfill.prototype, SymbolPolyfill.toPrimitive, d('', function() {
        var symbol = validateSymbol(this);
        if (_typeof(symbol) === 'symbol') {
          return symbol;
        }
        return symbol.toString();
      }));
      defineProperty(SymbolPolyfill.prototype, SymbolPolyfill.toStringTag, d('c', 'Symbol'));
      defineProperty(HiddenSymbol.prototype, SymbolPolyfill.toStringTag, d('c', SymbolPolyfill.prototype[SymbolPolyfill.toStringTag]));
      defineProperty(HiddenSymbol.prototype, SymbolPolyfill.toPrimitive, d('c', SymbolPolyfill.prototype[SymbolPolyfill.toPrimitive]));
    });
    var require_es6_symbol = __commonJS(function(exports, module) {
      'use strict';
      module.exports = require_is_implemented7()() ? require_global_this().Symbol : require_polyfill();
    });
    var require_is_arguments = __commonJS(function(exports, module) {
      'use strict';
      var objToString = Object.prototype.toString;
      var id = objToString.call(function() {
        return arguments;
      }());
      module.exports = function(value) {
        return objToString.call(value) === id;
      };
    });
    var require_is_function = __commonJS(function(exports, module) {
      'use strict';
      var objToString = Object.prototype.toString;
      var isFunctionStringTag = RegExp.prototype.test.bind(/^[object [A-Za-z0-9]*Function]$/);
      module.exports = function(value) {
        return typeof value === 'function' && isFunctionStringTag(objToString.call(value));
      };
    });
    var require_is_string = __commonJS(function(exports, module) {
      'use strict';
      var objToString = Object.prototype.toString;
      var id = objToString.call('');
      module.exports = function(value) {
        return typeof value === 'string' || value && _typeof(value) === 'object' && (value instanceof String || objToString.call(value) === id) || false;
      };
    });
    var require_shim5 = __commonJS(function(exports, module) {
      'use strict';
      var iteratorSymbol = require_es6_symbol().iterator;
      var isArguments = require_is_arguments();
      var isFunction = require_is_function();
      var toPosInt = require_to_pos_integer();
      var callable = require_valid_callable();
      var validValue = require_valid_value();
      var isValue = require_is_value();
      var isString = require_is_string();
      var isArray = Array.isArray;
      var call = Function.prototype.call;
      var desc = {
        configurable: true,
        enumerable: true,
        writable: true,
        value: null
      };
      var defineProperty = Object.defineProperty;
      module.exports = function(arrayLike) {
        var mapFn = arguments[1], thisArg = arguments[2], Context2, i, j, arr, length, code, iterator, result, getIterator, value;
        arrayLike = Object(validValue(arrayLike));
        if (isValue(mapFn)) {
          callable(mapFn);
        }
        if (!this || this === Array || !isFunction(this)) {
          if (!mapFn) {
            if (isArguments(arrayLike)) {
              length = arrayLike.length;
              if (length !== 1) {
                return Array.apply(null, arrayLike);
              }
              arr = new Array(1);
              arr[0] = arrayLike[0];
              return arr;
            }
            if (isArray(arrayLike)) {
              arr = new Array(length = arrayLike.length);
              for (i = 0; i < length; ++i) {
                arr[i] = arrayLike[i];
              }
              return arr;
            }
          }
          arr = [];
        } else {
          Context2 = this;
        }
        if (!isArray(arrayLike)) {
          if ((getIterator = arrayLike[iteratorSymbol]) !== void 0) {
            iterator = callable(getIterator).call(arrayLike);
            if (Context2) {
              arr = new Context2();
            }
            result = iterator.next();
            i = 0;
            while (!result.done) {
              value = mapFn ? call.call(mapFn, thisArg, result.value, i) : result.value;
              if (Context2) {
                desc.value = value;
                defineProperty(arr, i, desc);
              } else {
                arr[i] = value;
              }
              result = iterator.next();
              ++i;
            }
            length = i;
          } else if (isString(arrayLike)) {
            length = arrayLike.length;
            if (Context2) {
              arr = new Context2();
            }
            for (i = 0, j = 0; i < length; ++i) {
              value = arrayLike[i];
              if (i + 1 < length) {
                code = value.charCodeAt(0);
                if (code >= 55296 && code <= 56319) {
                  value += arrayLike[++i];
                }
              }
              value = mapFn ? call.call(mapFn, thisArg, value, j) : value;
              if (Context2) {
                desc.value = value;
                defineProperty(arr, j, desc);
              } else {
                arr[j] = value;
              }
              ++j;
            }
            length = j;
          }
        }
        if (length === void 0) {
          length = toPosInt(arrayLike.length);
          if (Context2) {
            arr = new Context2(length);
          }
          for (i = 0; i < length; ++i) {
            value = mapFn ? call.call(mapFn, thisArg, arrayLike[i], i) : arrayLike[i];
            if (Context2) {
              desc.value = value;
              defineProperty(arr, i, desc);
            } else {
              arr[i] = value;
            }
          }
        }
        if (Context2) {
          desc.value = null;
          arr.length = length;
        }
        return arr;
      };
    });
    var require_from = __commonJS(function(exports, module) {
      'use strict';
      module.exports = require_is_implemented5()() ? Array.from : require_shim5();
    });
    var require_to_array = __commonJS(function(exports, module) {
      'use strict';
      var from = require_from();
      var isArray = Array.isArray;
      module.exports = function(arrayLike) {
        return isArray(arrayLike) ? arrayLike : from(arrayLike);
      };
    });
    var require_resolve_resolve = __commonJS(function(exports, module) {
      'use strict';
      var toArray2 = require_to_array();
      var isValue = require_is_value();
      var callable = require_valid_callable();
      var slice = Array.prototype.slice;
      var resolveArgs;
      resolveArgs = function resolveArgs(args) {
        return this.map(function(resolve, i) {
          return resolve ? resolve(args[i]) : args[i];
        }).concat(slice.call(args, this.length));
      };
      module.exports = function(resolvers) {
        resolvers = toArray2(resolvers);
        resolvers.forEach(function(resolve) {
          if (isValue(resolve)) {
            callable(resolve);
          }
        });
        return resolveArgs.bind(resolvers);
      };
    });
    var require_resolve_normalize = __commonJS(function(exports, module) {
      'use strict';
      var callable = require_valid_callable();
      module.exports = function(userNormalizer) {
        var normalizer;
        if (typeof userNormalizer === 'function') {
          return {
            set: userNormalizer,
            get: userNormalizer
          };
        }
        normalizer = {
          get: callable(userNormalizer.get)
        };
        if (userNormalizer.set !== void 0) {
          normalizer.set = callable(userNormalizer.set);
          if (userNormalizer['delete']) {
            normalizer['delete'] = callable(userNormalizer['delete']);
          }
          if (userNormalizer.clear) {
            normalizer.clear = callable(userNormalizer.clear);
          }
          return normalizer;
        }
        normalizer.set = normalizer.get;
        return normalizer;
      };
    });
    var require_configure_map = __commonJS(function(exports, module) {
      'use strict';
      var customError = require_custom();
      var defineLength = require_define_length();
      var d = require_d();
      var ee = require_event_emitter().methods;
      var resolveResolve = require_resolve_resolve();
      var resolveNormalize = require_resolve_normalize();
      var apply = Function.prototype.apply;
      var call = Function.prototype.call;
      var create = Object.create;
      var defineProperties = Object.defineProperties;
      var _on = ee.on;
      var emit = ee.emit;
      module.exports = function(original, length, options) {
        var cache20 = create(null), conf, memLength, _get, set, del, _clear, extDel, extGet, extHas, normalizer, getListeners, setListeners, deleteListeners, memoized, resolve;
        if (length !== false) {
          memLength = length;
        } else if (isNaN(original.length)) {
          memLength = 1;
        } else {
          memLength = original.length;
        }
        if (options.normalizer) {
          normalizer = resolveNormalize(options.normalizer);
          _get = normalizer.get;
          set = normalizer.set;
          del = normalizer['delete'];
          _clear = normalizer.clear;
        }
        if (options.resolvers != null) {
          resolve = resolveResolve(options.resolvers);
        }
        if (_get) {
          memoized = defineLength(function(arg) {
            var id, result, args = arguments;
            if (resolve) {
              args = resolve(args);
            }
            id = _get(args);
            if (id !== null) {
              if (hasOwnProperty.call(cache20, id)) {
                if (getListeners) {
                  conf.emit('get', id, args, this);
                }
                return cache20[id];
              }
            }
            if (args.length === 1) {
              result = call.call(original, this, args[0]);
            } else {
              result = apply.call(original, this, args);
            }
            if (id === null) {
              id = _get(args);
              if (id !== null) {
                throw customError('Circular invocation', 'CIRCULAR_INVOCATION');
              }
              id = set(args);
            } else if (hasOwnProperty.call(cache20, id)) {
              throw customError('Circular invocation', 'CIRCULAR_INVOCATION');
            }
            cache20[id] = result;
            if (setListeners) {
              conf.emit('set', id, null, result);
            }
            return result;
          }, memLength);
        } else if (length === 0) {
          memoized = function memoized() {
            var result;
            if (hasOwnProperty.call(cache20, 'data')) {
              if (getListeners) {
                conf.emit('get', 'data', arguments, this);
              }
              return cache20.data;
            }
            if (arguments.length) {
              result = apply.call(original, this, arguments);
            } else {
              result = call.call(original, this);
            }
            if (hasOwnProperty.call(cache20, 'data')) {
              throw customError('Circular invocation', 'CIRCULAR_INVOCATION');
            }
            cache20.data = result;
            if (setListeners) {
              conf.emit('set', 'data', null, result);
            }
            return result;
          };
        } else {
          memoized = function memoized(arg) {
            var result, args = arguments, id;
            if (resolve) {
              args = resolve(arguments);
            }
            id = String(args[0]);
            if (hasOwnProperty.call(cache20, id)) {
              if (getListeners) {
                conf.emit('get', id, args, this);
              }
              return cache20[id];
            }
            if (args.length === 1) {
              result = call.call(original, this, args[0]);
            } else {
              result = apply.call(original, this, args);
            }
            if (hasOwnProperty.call(cache20, id)) {
              throw customError('Circular invocation', 'CIRCULAR_INVOCATION');
            }
            cache20[id] = result;
            if (setListeners) {
              conf.emit('set', id, null, result);
            }
            return result;
          };
        }
        conf = {
          original: original,
          memoized: memoized,
          profileName: options.profileName,
          get: function get(args) {
            if (resolve) {
              args = resolve(args);
            }
            if (_get) {
              return _get(args);
            }
            return String(args[0]);
          },
          has: function has(id) {
            return hasOwnProperty.call(cache20, id);
          },
          delete: function _delete(id) {
            var result;
            if (!hasOwnProperty.call(cache20, id)) {
              return;
            }
            if (del) {
              del(id);
            }
            result = cache20[id];
            delete cache20[id];
            if (deleteListeners) {
              conf.emit('delete', id, result);
            }
          },
          clear: function clear() {
            var oldCache = cache20;
            if (_clear) {
              _clear();
            }
            cache20 = create(null);
            conf.emit('clear', oldCache);
          },
          on: function on(type, listener) {
            if (type === 'get') {
              getListeners = true;
            } else if (type === 'set') {
              setListeners = true;
            } else if (type === 'delete') {
              deleteListeners = true;
            }
            return _on.call(this, type, listener);
          },
          emit: emit,
          updateEnv: function updateEnv() {
            original = conf.original;
          }
        };
        if (_get) {
          extDel = defineLength(function(arg) {
            var id, args = arguments;
            if (resolve) {
              args = resolve(args);
            }
            id = _get(args);
            if (id === null) {
              return;
            }
            conf['delete'](id);
          }, memLength);
        } else if (length === 0) {
          extDel = function extDel() {
            return conf['delete']('data');
          };
        } else {
          extDel = function extDel(arg) {
            if (resolve) {
              arg = resolve(arguments)[0];
            }
            return conf['delete'](arg);
          };
        }
        extGet = defineLength(function() {
          var id, args = arguments;
          if (length === 0) {
            return cache20.data;
          }
          if (resolve) {
            args = resolve(args);
          }
          if (_get) {
            id = _get(args);
          } else {
            id = String(args[0]);
          }
          return cache20[id];
        });
        extHas = defineLength(function() {
          var id, args = arguments;
          if (length === 0) {
            return conf.has('data');
          }
          if (resolve) {
            args = resolve(args);
          }
          if (_get) {
            id = _get(args);
          } else {
            id = String(args[0]);
          }
          if (id === null) {
            return false;
          }
          return conf.has(id);
        });
        defineProperties(memoized, {
          __memoized__: d(true),
          delete: d(extDel),
          clear: d(conf.clear),
          _get: d(extGet),
          _has: d(extHas)
        });
        return conf;
      };
    });
    var require_plain = __commonJS(function(exports, module) {
      'use strict';
      var callable = require_valid_callable();
      var forEach = require_for_each();
      var extensions = require_registered_extensions();
      var configure5 = require_configure_map();
      var resolveLength = require_resolve_length();
      module.exports = function self2(fn) {
        var options, length, conf;
        callable(fn);
        options = Object(arguments[1]);
        if (options.async && options.promise) {
          throw new Error('Options \'async\' and \'promise\' cannot be used together');
        }
        if (hasOwnProperty.call(fn, '__memoized__') && !options.force) {
          return fn;
        }
        length = resolveLength(options.length, fn.length, options.async && extensions.async);
        conf = configure5(fn, length, options);
        forEach(extensions, function(extFn, name) {
          if (options[name]) {
            extFn(options[name], conf, options);
          }
        });
        if (self2.__profiler__) {
          self2.__profiler__(conf);
        }
        conf.updateEnv();
        return conf.memoized;
      };
    });
    var require_primitive = __commonJS(function(exports, module) {
      'use strict';
      module.exports = function(args) {
        var id, i, length = args.length;
        if (!length) {
          return '\x02';
        }
        id = String(args[i = 0]);
        while (--length) {
          id += '\x01' + args[++i];
        }
        return id;
      };
    });
    var require_get_primitive_fixed = __commonJS(function(exports, module) {
      'use strict';
      module.exports = function(length) {
        if (!length) {
          return function() {
            return '';
          };
        }
        return function(args) {
          var id = String(args[0]), i = 0, currentLength = length;
          while (--currentLength) {
            id += '\x01' + args[++i];
          }
          return id;
        };
      };
    });
    var require_is_implemented8 = __commonJS(function(exports, module) {
      'use strict';
      module.exports = function() {
        var numberIsNaN = Number.isNaN;
        if (typeof numberIsNaN !== 'function') {
          return false;
        }
        return !numberIsNaN({}) && numberIsNaN(NaN) && !numberIsNaN(34);
      };
    });
    var require_shim6 = __commonJS(function(exports, module) {
      'use strict';
      module.exports = function(value) {
        return value !== value;
      };
    });
    var require_is_nan = __commonJS(function(exports, module) {
      'use strict';
      module.exports = require_is_implemented8()() ? Number.isNaN : require_shim6();
    });
    var require_e_index_of = __commonJS(function(exports, module) {
      'use strict';
      var numberIsNaN = require_is_nan();
      var toPosInt = require_to_pos_integer();
      var value = require_valid_value();
      var indexOf = Array.prototype.indexOf;
      var objHasOwnProperty = Object.prototype.hasOwnProperty;
      var abs = Math.abs;
      var floor = Math.floor;
      module.exports = function(searchElement) {
        var i, length, fromIndex, val;
        if (!numberIsNaN(searchElement)) {
          return indexOf.apply(this, arguments);
        }
        length = toPosInt(value(this).length);
        fromIndex = arguments[1];
        if (isNaN(fromIndex)) {
          fromIndex = 0;
        } else if (fromIndex >= 0) {
          fromIndex = floor(fromIndex);
        } else {
          fromIndex = toPosInt(this.length) - floor(abs(fromIndex));
        }
        for (i = fromIndex; i < length; ++i) {
          if (objHasOwnProperty.call(this, i)) {
            val = this[i];
            if (numberIsNaN(val)) {
              return i;
            }
          }
        }
        return -1;
      };
    });
    var require_get = __commonJS(function(exports, module) {
      'use strict';
      var indexOf = require_e_index_of();
      var create = Object.create;
      module.exports = function() {
        var lastId = 0, map = [], cache20 = create(null);
        return {
          get: function get(args) {
            var index = 0, set = map, i, length = args.length;
            if (length === 0) {
              return set[length] || null;
            }
            if (set = set[length]) {
              while (index < length - 1) {
                i = indexOf.call(set[0], args[index]);
                if (i === -1) {
                  return null;
                }
                set = set[1][i];
                ++index;
              }
              i = indexOf.call(set[0], args[index]);
              if (i === -1) {
                return null;
              }
              return set[1][i] || null;
            }
            return null;
          },
          set: function set(args) {
            var index = 0, set = map, i, length = args.length;
            if (length === 0) {
              set[length] = ++lastId;
            } else {
              if (!set[length]) {
                set[length] = [ [], [] ];
              }
              set = set[length];
              while (index < length - 1) {
                i = indexOf.call(set[0], args[index]);
                if (i === -1) {
                  i = set[0].push(args[index]) - 1;
                  set[1].push([ [], [] ]);
                }
                set = set[1][i];
                ++index;
              }
              i = indexOf.call(set[0], args[index]);
              if (i === -1) {
                i = set[0].push(args[index]) - 1;
              }
              set[1][i] = ++lastId;
            }
            cache20[lastId] = args;
            return lastId;
          },
          delete: function _delete(id) {
            var index = 0, set = map, i, args = cache20[id], length = args.length, path = [];
            if (length === 0) {
              delete set[length];
            } else if (set = set[length]) {
              while (index < length - 1) {
                i = indexOf.call(set[0], args[index]);
                if (i === -1) {
                  return;
                }
                path.push(set, i);
                set = set[1][i];
                ++index;
              }
              i = indexOf.call(set[0], args[index]);
              if (i === -1) {
                return;
              }
              id = set[1][i];
              set[0].splice(i, 1);
              set[1].splice(i, 1);
              while (!set[0].length && path.length) {
                i = path.pop();
                set = path.pop();
                set[0].splice(i, 1);
                set[1].splice(i, 1);
              }
            }
            delete cache20[id];
          },
          clear: function clear() {
            map = [];
            cache20 = create(null);
          }
        };
      };
    });
    var require_get_1 = __commonJS(function(exports, module) {
      'use strict';
      var indexOf = require_e_index_of();
      module.exports = function() {
        var lastId = 0, argsMap = [], cache20 = [];
        return {
          get: function get(args) {
            var index = indexOf.call(argsMap, args[0]);
            return index === -1 ? null : cache20[index];
          },
          set: function set(args) {
            argsMap.push(args[0]);
            cache20.push(++lastId);
            return lastId;
          },
          delete: function _delete(id) {
            var index = indexOf.call(cache20, id);
            if (index !== -1) {
              argsMap.splice(index, 1);
              cache20.splice(index, 1);
            }
          },
          clear: function clear() {
            argsMap = [];
            cache20 = [];
          }
        };
      };
    });
    var require_get_fixed = __commonJS(function(exports, module) {
      'use strict';
      var indexOf = require_e_index_of();
      var create = Object.create;
      module.exports = function(length) {
        var lastId = 0, map = [ [], [] ], cache20 = create(null);
        return {
          get: function get(args) {
            var index = 0, set = map, i;
            while (index < length - 1) {
              i = indexOf.call(set[0], args[index]);
              if (i === -1) {
                return null;
              }
              set = set[1][i];
              ++index;
            }
            i = indexOf.call(set[0], args[index]);
            if (i === -1) {
              return null;
            }
            return set[1][i] || null;
          },
          set: function set(args) {
            var index = 0, set = map, i;
            while (index < length - 1) {
              i = indexOf.call(set[0], args[index]);
              if (i === -1) {
                i = set[0].push(args[index]) - 1;
                set[1].push([ [], [] ]);
              }
              set = set[1][i];
              ++index;
            }
            i = indexOf.call(set[0], args[index]);
            if (i === -1) {
              i = set[0].push(args[index]) - 1;
            }
            set[1][i] = ++lastId;
            cache20[lastId] = args;
            return lastId;
          },
          delete: function _delete(id) {
            var index = 0, set = map, i, path = [], args = cache20[id];
            while (index < length - 1) {
              i = indexOf.call(set[0], args[index]);
              if (i === -1) {
                return;
              }
              path.push(set, i);
              set = set[1][i];
              ++index;
            }
            i = indexOf.call(set[0], args[index]);
            if (i === -1) {
              return;
            }
            id = set[1][i];
            set[0].splice(i, 1);
            set[1].splice(i, 1);
            while (!set[0].length && path.length) {
              i = path.pop();
              set = path.pop();
              set[0].splice(i, 1);
              set[1].splice(i, 1);
            }
            delete cache20[id];
          },
          clear: function clear() {
            map = [ [], [] ];
            cache20 = create(null);
          }
        };
      };
    });
    var require_map = __commonJS(function(exports, module) {
      'use strict';
      var callable = require_valid_callable();
      var forEach = require_for_each();
      var call = Function.prototype.call;
      module.exports = function(obj, cb) {
        var result = {}, thisArg = arguments[2];
        callable(cb);
        forEach(obj, function(value, key, targetObj, index) {
          result[key] = call.call(cb, thisArg, value, key, targetObj, index);
        });
        return result;
      };
    });
    var require_next_tick = __commonJS(function(exports, module) {
      'use strict';
      var callable;
      var byObserver;
      callable = function callable(fn) {
        if (typeof fn !== 'function') {
          throw new TypeError(fn + ' is not a function');
        }
        return fn;
      };
      byObserver = function byObserver(Observer) {
        var node = document.createTextNode(''), queue4, currentQueue, i = 0;
        new Observer(function() {
          var callback;
          if (!queue4) {
            if (!currentQueue) {
              return;
            }
            queue4 = currentQueue;
          } else if (currentQueue) {
            queue4 = currentQueue.concat(queue4);
          }
          currentQueue = queue4;
          queue4 = null;
          if (typeof currentQueue === 'function') {
            callback = currentQueue;
            currentQueue = null;
            callback();
            return;
          }
          node.data = i = ++i % 2;
          while (currentQueue) {
            callback = currentQueue.shift();
            if (!currentQueue.length) {
              currentQueue = null;
            }
            callback();
          }
        }).observe(node, {
          characterData: true
        });
        return function(fn) {
          callable(fn);
          if (queue4) {
            if (typeof queue4 === 'function') {
              queue4 = [ queue4, fn ];
            } else {
              queue4.push(fn);
            }
            return;
          }
          queue4 = fn;
          node.data = i = ++i % 2;
        };
      };
      module.exports = function() {
        if ((typeof process === 'undefined' ? 'undefined' : _typeof(process)) === 'object' && process && typeof process.nextTick === 'function') {
          return process.nextTick;
        }
        if ((typeof document === 'undefined' ? 'undefined' : _typeof(document)) === 'object' && document) {
          if (typeof MutationObserver === 'function') {
            return byObserver(MutationObserver);
          }
          if (typeof WebKitMutationObserver === 'function') {
            return byObserver(WebKitMutationObserver);
          }
        }
        if (typeof setImmediate === 'function') {
          return function(cb) {
            setImmediate(callable(cb));
          };
        }
        if (typeof setTimeout === 'function' || (typeof setTimeout === 'undefined' ? 'undefined' : _typeof(setTimeout)) === 'object') {
          return function(cb) {
            setTimeout(callable(cb), 0);
          };
        }
        return null;
      }();
    });
    var require_async = __commonJS(function() {
      'use strict';
      var aFrom = require_from();
      var objectMap = require_map();
      var mixin = require_mixin();
      var defineLength = require_define_length();
      var nextTick = require_next_tick();
      var slice = Array.prototype.slice;
      var apply = Function.prototype.apply;
      var create = Object.create;
      require_registered_extensions().async = function(tbi, conf) {
        var waiting = create(null), cache20 = create(null), base = conf.memoized, original = conf.original, currentCallback, currentContext, currentArgs;
        conf.memoized = defineLength(function(arg) {
          var args = arguments, last = args[args.length - 1];
          if (typeof last === 'function') {
            currentCallback = last;
            args = slice.call(args, 0, -1);
          }
          return base.apply(currentContext = this, currentArgs = args);
        }, base);
        try {
          mixin(conf.memoized, base);
        } catch (ignore) {}
        conf.on('get', function(id) {
          var cb, context3, args;
          if (!currentCallback) {
            return;
          }
          if (waiting[id]) {
            if (typeof waiting[id] === 'function') {
              waiting[id] = [ waiting[id], currentCallback ];
            } else {
              waiting[id].push(currentCallback);
            }
            currentCallback = null;
            return;
          }
          cb = currentCallback;
          context3 = currentContext;
          args = currentArgs;
          currentCallback = currentContext = currentArgs = null;
          nextTick(function() {
            var data2;
            if (hasOwnProperty.call(cache20, id)) {
              data2 = cache20[id];
              conf.emit('getasync', id, args, context3);
              apply.call(cb, data2.context, data2.args);
            } else {
              currentCallback = cb;
              currentContext = context3;
              currentArgs = args;
              base.apply(context3, args);
            }
          });
        });
        conf.original = function() {
          var args, cb, origCb, result;
          if (!currentCallback) {
            return apply.call(original, this, arguments);
          }
          args = aFrom(arguments);
          cb = function self2(err2) {
            var cb2, args2, id = self2.id;
            if (id == null) {
              nextTick(apply.bind(self2, this, arguments));
              return void 0;
            }
            delete self2.id;
            cb2 = waiting[id];
            delete waiting[id];
            if (!cb2) {
              return void 0;
            }
            args2 = aFrom(arguments);
            if (conf.has(id)) {
              if (err2) {
                conf['delete'](id);
              } else {
                cache20[id] = {
                  context: this,
                  args: args2
                };
                conf.emit('setasync', id, typeof cb2 === 'function' ? 1 : cb2.length);
              }
            }
            if (typeof cb2 === 'function') {
              result = apply.call(cb2, this, args2);
            } else {
              cb2.forEach(function(cb3) {
                result = apply.call(cb3, this, args2);
              }, this);
            }
            return result;
          };
          origCb = currentCallback;
          currentCallback = currentContext = currentArgs = null;
          args.push(cb);
          result = apply.call(original, this, args);
          cb.cb = origCb;
          currentCallback = cb;
          return result;
        };
        conf.on('set', function(id) {
          if (!currentCallback) {
            conf['delete'](id);
            return;
          }
          if (waiting[id]) {
            if (typeof waiting[id] === 'function') {
              waiting[id] = [ waiting[id], currentCallback.cb ];
            } else {
              waiting[id].push(currentCallback.cb);
            }
          } else {
            waiting[id] = currentCallback.cb;
          }
          delete currentCallback.cb;
          currentCallback.id = id;
          currentCallback = null;
        });
        conf.on('delete', function(id) {
          var result;
          if (hasOwnProperty.call(waiting, id)) {
            return;
          }
          if (!cache20[id]) {
            return;
          }
          result = cache20[id];
          delete cache20[id];
          conf.emit('deleteasync', id, slice.call(result.args, 1));
        });
        conf.on('clear', function() {
          var oldCache = cache20;
          cache20 = create(null);
          conf.emit('clearasync', objectMap(oldCache, function(data2) {
            return slice.call(data2.args, 1);
          }));
        });
      };
    });
    var require_primitive_set = __commonJS(function(exports, module) {
      'use strict';
      var forEach = Array.prototype.forEach;
      var create = Object.create;
      module.exports = function(arg) {
        var set = create(null);
        forEach.call(arguments, function(name) {
          set[name] = true;
        });
        return set;
      };
    });
    var require_is_callable = __commonJS(function(exports, module) {
      'use strict';
      module.exports = function(obj) {
        return typeof obj === 'function';
      };
    });
    var require_validate_stringifiable = __commonJS(function(exports, module) {
      'use strict';
      var isCallable = require_is_callable();
      module.exports = function(stringifiable) {
        try {
          if (stringifiable && isCallable(stringifiable.toString)) {
            return stringifiable.toString();
          }
          return String(stringifiable);
        } catch (e) {
          throw new TypeError('Passed argument cannot be stringifed');
        }
      };
    });
    var require_validate_stringifiable_value = __commonJS(function(exports, module) {
      'use strict';
      var ensureValue = require_valid_value();
      var stringifiable = require_validate_stringifiable();
      module.exports = function(value) {
        return stringifiable(ensureValue(value));
      };
    });
    var require_safe_to_string = __commonJS(function(exports, module) {
      'use strict';
      var isCallable = require_is_callable();
      module.exports = function(value) {
        try {
          if (value && isCallable(value.toString)) {
            return value.toString();
          }
          return String(value);
        } catch (e) {
          return '<Non-coercible to string value>';
        }
      };
    });
    var require_to_short_string_representation = __commonJS(function(exports, module) {
      'use strict';
      var safeToString = require_safe_to_string();
      var reNewLine = /[\n\r\u2028\u2029]/g;
      module.exports = function(value) {
        var string = safeToString(value);
        if (string.length > 100) {
          string = string.slice(0, 99) + '\u2026';
        }
        string = string.replace(reNewLine, function(_char) {
          return JSON.stringify(_char).slice(1, -1);
        });
        return string;
      };
    });
    var require_is_promise = __commonJS(function(exports, module) {
      module.exports = isPromise;
      module.exports['default'] = isPromise;
      function isPromise(obj) {
        return !!obj && (_typeof(obj) === 'object' || typeof obj === 'function') && typeof obj.then === 'function';
      }
    });
    var require_promise = __commonJS(function() {
      'use strict';
      var objectMap = require_map();
      var primitiveSet = require_primitive_set();
      var ensureString = require_validate_stringifiable_value();
      var toShortString = require_to_short_string_representation();
      var isPromise = require_is_promise();
      var nextTick = require_next_tick();
      var create = Object.create;
      var supportedModes = primitiveSet('then', 'then:finally', 'done', 'done:finally');
      require_registered_extensions().promise = function(mode, conf) {
        var waiting = create(null), cache20 = create(null), promises = create(null);
        if (mode === true) {
          mode = null;
        } else {
          mode = ensureString(mode);
          if (!supportedModes[mode]) {
            throw new TypeError('\'' + toShortString(mode) + '\' is not valid promise mode');
          }
        }
        conf.on('set', function(id, ignore, promise) {
          var isFailed = false;
          if (!isPromise(promise)) {
            cache20[id] = promise;
            conf.emit('setasync', id, 1);
            return;
          }
          waiting[id] = 1;
          promises[id] = promise;
          var onSuccess = function onSuccess(result) {
            var count = waiting[id];
            if (isFailed) {
              throw new Error('Memoizee error: Detected unordered then|done & finally resolution, which in turn makes proper detection of success/failure impossible (when in \'done:finally\' mode)\nConsider to rely on \'then\' or \'done\' mode instead.');
            }
            if (!count) {
              return;
            }
            delete waiting[id];
            cache20[id] = result;
            conf.emit('setasync', id, count);
          };
          var onFailure = function onFailure() {
            isFailed = true;
            if (!waiting[id]) {
              return;
            }
            delete waiting[id];
            delete promises[id];
            conf['delete'](id);
          };
          var resolvedMode = mode;
          if (!resolvedMode) {
            resolvedMode = 'then';
          }
          if (resolvedMode === 'then') {
            var nextTickFailure = function nextTickFailure() {
              nextTick(onFailure);
            };
            promise = promise.then(function(result) {
              nextTick(onSuccess.bind(this, result));
            }, nextTickFailure);
            if (typeof promise['finally'] === 'function') {
              promise['finally'](nextTickFailure);
            }
          } else if (resolvedMode === 'done') {
            if (typeof promise.done !== 'function') {
              throw new Error('Memoizee error: Retrieved promise does not implement \'done\' in \'done\' mode');
            }
            promise.done(onSuccess, onFailure);
          } else if (resolvedMode === 'done:finally') {
            if (typeof promise.done !== 'function') {
              throw new Error('Memoizee error: Retrieved promise does not implement \'done\' in \'done:finally\' mode');
            }
            if (typeof promise['finally'] !== 'function') {
              throw new Error('Memoizee error: Retrieved promise does not implement \'finally\' in \'done:finally\' mode');
            }
            promise.done(onSuccess);
            promise['finally'](onFailure);
          }
        });
        conf.on('get', function(id, args, context3) {
          var promise;
          if (waiting[id]) {
            ++waiting[id];
            return;
          }
          promise = promises[id];
          var emit = function emit() {
            conf.emit('getasync', id, args, context3);
          };
          if (isPromise(promise)) {
            if (typeof promise.done === 'function') {
              promise.done(emit);
            } else {
              promise.then(function() {
                nextTick(emit);
              });
            }
          } else {
            emit();
          }
        });
        conf.on('delete', function(id) {
          delete promises[id];
          if (waiting[id]) {
            delete waiting[id];
            return;
          }
          if (!hasOwnProperty.call(cache20, id)) {
            return;
          }
          var result = cache20[id];
          delete cache20[id];
          conf.emit('deleteasync', id, [ result ]);
        });
        conf.on('clear', function() {
          var oldCache = cache20;
          cache20 = create(null);
          waiting = create(null);
          promises = create(null);
          conf.emit('clearasync', objectMap(oldCache, function(data2) {
            return [ data2 ];
          }));
        });
      };
    });
    var require_dispose = __commonJS(function() {
      'use strict';
      var callable = require_valid_callable();
      var forEach = require_for_each();
      var extensions = require_registered_extensions();
      var apply = Function.prototype.apply;
      extensions.dispose = function(dispose, conf, options) {
        var del;
        callable(dispose);
        if (options.async && extensions.async || options.promise && extensions.promise) {
          conf.on('deleteasync', del = function del(id, resultArray) {
            apply.call(dispose, null, resultArray);
          });
          conf.on('clearasync', function(cache20) {
            forEach(cache20, function(result, id) {
              del(id, result);
            });
          });
          return;
        }
        conf.on('delete', del = function del(id, result) {
          dispose(result);
        });
        conf.on('clear', function(cache20) {
          forEach(cache20, function(result, id) {
            del(id, result);
          });
        });
      };
    });
    var require_max_timeout = __commonJS(function(exports, module) {
      'use strict';
      module.exports = 2147483647;
    });
    var require_valid_timeout = __commonJS(function(exports, module) {
      'use strict';
      var toPosInt = require_to_pos_integer();
      var maxTimeout = require_max_timeout();
      module.exports = function(value) {
        value = toPosInt(value);
        if (value > maxTimeout) {
          throw new TypeError(value + ' exceeds maximum possible timeout');
        }
        return value;
      };
    });
    var require_max_age = __commonJS(function() {
      'use strict';
      var aFrom = require_from();
      var forEach = require_for_each();
      var nextTick = require_next_tick();
      var isPromise = require_is_promise();
      var timeout = require_valid_timeout();
      var extensions = require_registered_extensions();
      var noop4 = Function.prototype;
      var max = Math.max;
      var min = Math.min;
      var create = Object.create;
      extensions.maxAge = function(maxAge, conf, options) {
        var timeouts, postfix, preFetchAge, preFetchTimeouts;
        maxAge = timeout(maxAge);
        if (!maxAge) {
          return;
        }
        timeouts = create(null);
        postfix = options.async && extensions.async || options.promise && extensions.promise ? 'async' : '';
        conf.on('set' + postfix, function(id) {
          timeouts[id] = setTimeout(function() {
            conf['delete'](id);
          }, maxAge);
          if (typeof timeouts[id].unref === 'function') {
            timeouts[id].unref();
          }
          if (!preFetchTimeouts) {
            return;
          }
          if (preFetchTimeouts[id]) {
            if (preFetchTimeouts[id] !== 'nextTick') {
              clearTimeout(preFetchTimeouts[id]);
            }
          }
          preFetchTimeouts[id] = setTimeout(function() {
            delete preFetchTimeouts[id];
          }, preFetchAge);
          if (typeof preFetchTimeouts[id].unref === 'function') {
            preFetchTimeouts[id].unref();
          }
        });
        conf.on('delete' + postfix, function(id) {
          clearTimeout(timeouts[id]);
          delete timeouts[id];
          if (!preFetchTimeouts) {
            return;
          }
          if (preFetchTimeouts[id] !== 'nextTick') {
            clearTimeout(preFetchTimeouts[id]);
          }
          delete preFetchTimeouts[id];
        });
        if (options.preFetch) {
          if (options.preFetch === true || isNaN(options.preFetch)) {
            preFetchAge = .333;
          } else {
            preFetchAge = max(min(Number(options.preFetch), 1), 0);
          }
          if (preFetchAge) {
            preFetchTimeouts = {};
            preFetchAge = (1 - preFetchAge) * maxAge;
            conf.on('get' + postfix, function(id, args, context3) {
              if (!preFetchTimeouts[id]) {
                preFetchTimeouts[id] = 'nextTick';
                nextTick(function() {
                  var result;
                  if (preFetchTimeouts[id] !== 'nextTick') {
                    return;
                  }
                  delete preFetchTimeouts[id];
                  conf['delete'](id);
                  if (options.async) {
                    args = aFrom(args);
                    args.push(noop4);
                  }
                  result = conf.memoized.apply(context3, args);
                  if (options.promise) {
                    if (isPromise(result)) {
                      if (typeof result.done === 'function') {
                        result.done(noop4, noop4);
                      } else {
                        result.then(noop4, noop4);
                      }
                    }
                  }
                });
              }
            });
          }
        }
        conf.on('clear' + postfix, function() {
          forEach(timeouts, function(id) {
            clearTimeout(id);
          });
          timeouts = {};
          if (preFetchTimeouts) {
            forEach(preFetchTimeouts, function(id) {
              if (id !== 'nextTick') {
                clearTimeout(id);
              }
            });
            preFetchTimeouts = {};
          }
        });
      };
    });
    var require_lru_queue = __commonJS(function(exports, module) {
      'use strict';
      var toPosInt = require_to_pos_integer();
      var create = Object.create;
      var hasOwnProperty2 = Object.prototype.hasOwnProperty;
      module.exports = function(limit) {
        var size = 0, base = 1, queue4 = create(null), map = create(null), index = 0, del;
        limit = toPosInt(limit);
        return {
          hit: function hit(id) {
            var oldIndex = map[id], nuIndex = ++index;
            queue4[nuIndex] = id;
            map[id] = nuIndex;
            if (!oldIndex) {
              ++size;
              if (size <= limit) {
                return;
              }
              id = queue4[base];
              del(id);
              return id;
            }
            delete queue4[oldIndex];
            if (base !== oldIndex) {
              return;
            }
            while (!hasOwnProperty2.call(queue4, ++base)) {
              continue;
            }
          },
          delete: del = function del(id) {
            var oldIndex = map[id];
            if (!oldIndex) {
              return;
            }
            delete queue4[oldIndex];
            delete map[id];
            --size;
            if (base !== oldIndex) {
              return;
            }
            if (!size) {
              index = 0;
              base = 1;
              return;
            }
            while (!hasOwnProperty2.call(queue4, ++base)) {
              continue;
            }
          },
          clear: function clear() {
            size = 0;
            base = 1;
            queue4 = create(null);
            map = create(null);
            index = 0;
          }
        };
      };
    });
    var require_max = __commonJS(function() {
      'use strict';
      var toPosInteger = require_to_pos_integer();
      var lruQueue = require_lru_queue();
      var extensions = require_registered_extensions();
      extensions.max = function(max, conf, options) {
        var postfix, queue4, hit;
        max = toPosInteger(max);
        if (!max) {
          return;
        }
        queue4 = lruQueue(max);
        postfix = options.async && extensions.async || options.promise && extensions.promise ? 'async' : '';
        conf.on('set' + postfix, hit = function hit(id) {
          id = queue4.hit(id);
          if (id === void 0) {
            return;
          }
          conf['delete'](id);
        });
        conf.on('get' + postfix, hit);
        conf.on('delete' + postfix, queue4['delete']);
        conf.on('clear' + postfix, queue4.clear);
      };
    });
    var require_ref_counter = __commonJS(function() {
      'use strict';
      var d = require_d();
      var extensions = require_registered_extensions();
      var create = Object.create;
      var defineProperties = Object.defineProperties;
      extensions.refCounter = function(ignore, conf, options) {
        var cache20, postfix;
        cache20 = create(null);
        postfix = options.async && extensions.async || options.promise && extensions.promise ? 'async' : '';
        conf.on('set' + postfix, function(id, length) {
          cache20[id] = length || 1;
        });
        conf.on('get' + postfix, function(id) {
          ++cache20[id];
        });
        conf.on('delete' + postfix, function(id) {
          delete cache20[id];
        });
        conf.on('clear' + postfix, function() {
          cache20 = {};
        });
        defineProperties(conf.memoized, {
          deleteRef: d(function() {
            var id = conf.get(arguments);
            if (id === null) {
              return null;
            }
            if (!cache20[id]) {
              return null;
            }
            if (!--cache20[id]) {
              conf['delete'](id);
              return true;
            }
            return false;
          }),
          getRefCount: d(function() {
            var id = conf.get(arguments);
            if (id === null) {
              return 0;
            }
            if (!cache20[id]) {
              return 0;
            }
            return cache20[id];
          })
        });
      };
    });
    var require_memoizee = __commonJS(function(exports, module) {
      'use strict';
      var normalizeOpts = require_normalize_options();
      var resolveLength = require_resolve_length();
      var plain = require_plain();
      module.exports = function(fn) {
        var options = normalizeOpts(arguments[1]), length;
        if (!options.normalizer) {
          length = options.length = resolveLength(options.length, fn.length, options.async);
          if (length !== 0) {
            if (options.primitive) {
              if (length === false) {
                options.normalizer = require_primitive();
              } else if (length > 1) {
                options.normalizer = require_get_primitive_fixed()(length);
              }
            } else if (length === false) {
              options.normalizer = require_get()();
            } else if (length === 1) {
              options.normalizer = require_get_1()();
            } else {
              options.normalizer = require_get_fixed()(length);
            }
          }
        }
        if (options.async) {
          require_async();
        }
        if (options.promise) {
          require_promise();
        }
        if (options.dispose) {
          require_dispose();
        }
        if (options.maxAge) {
          require_max_age();
        }
        if (options.max) {
          require_max();
        }
        if (options.refCounter) {
          require_ref_counter();
        }
        return plain(fn, options);
      };
    });
    var require_emoji_regex = __commonJS(function(exports, module) {
      'use strict';
      module.exports = function() {
        return /\uD83C\uDFF4\uDB40\uDC67\uDB40\uDC62(?:\uDB40\uDC65\uDB40\uDC6E\uDB40\uDC67|\uDB40\uDC73\uDB40\uDC63\uDB40\uDC74|\uDB40\uDC77\uDB40\uDC6C\uDB40\uDC73)\uDB40\uDC7F|\uD83D\uDC68(?:\uD83C\uDFFC\u200D(?:\uD83E\uDD1D\u200D\uD83D\uDC68\uD83C\uDFFB|\uD83C[\uDF3E\uDF73\uDF93\uDFA4\uDFA8\uDFEB\uDFED]|\uD83D[\uDCBB\uDCBC\uDD27\uDD2C\uDE80\uDE92]|\uD83E[\uDDAF-\uDDB3\uDDBC\uDDBD])|\uD83C\uDFFF\u200D(?:\uD83E\uDD1D\u200D\uD83D\uDC68(?:\uD83C[\uDFFB-\uDFFE])|\uD83C[\uDF3E\uDF73\uDF93\uDFA4\uDFA8\uDFEB\uDFED]|\uD83D[\uDCBB\uDCBC\uDD27\uDD2C\uDE80\uDE92]|\uD83E[\uDDAF-\uDDB3\uDDBC\uDDBD])|\uD83C\uDFFE\u200D(?:\uD83E\uDD1D\u200D\uD83D\uDC68(?:\uD83C[\uDFFB-\uDFFD])|\uD83C[\uDF3E\uDF73\uDF93\uDFA4\uDFA8\uDFEB\uDFED]|\uD83D[\uDCBB\uDCBC\uDD27\uDD2C\uDE80\uDE92]|\uD83E[\uDDAF-\uDDB3\uDDBC\uDDBD])|\uD83C\uDFFD\u200D(?:\uD83E\uDD1D\u200D\uD83D\uDC68(?:\uD83C[\uDFFB\uDFFC])|\uD83C[\uDF3E\uDF73\uDF93\uDFA4\uDFA8\uDFEB\uDFED]|\uD83D[\uDCBB\uDCBC\uDD27\uDD2C\uDE80\uDE92]|\uD83E[\uDDAF-\uDDB3\uDDBC\uDDBD])|\u200D(?:\u2764\uFE0F\u200D(?:\uD83D\uDC8B\u200D)?\uD83D\uDC68|(?:\uD83D[\uDC68\uDC69])\u200D(?:\uD83D\uDC66\u200D\uD83D\uDC66|\uD83D\uDC67\u200D(?:\uD83D[\uDC66\uDC67]))|\uD83D\uDC66\u200D\uD83D\uDC66|\uD83D\uDC67\u200D(?:\uD83D[\uDC66\uDC67])|(?:\uD83D[\uDC68\uDC69])\u200D(?:\uD83D[\uDC66\uDC67])|[\u2695\u2696\u2708]\uFE0F|\uD83D[\uDC66\uDC67]|\uD83C[\uDF3E\uDF73\uDF93\uDFA4\uDFA8\uDFEB\uDFED]|\uD83D[\uDCBB\uDCBC\uDD27\uDD2C\uDE80\uDE92]|\uD83E[\uDDAF-\uDDB3\uDDBC\uDDBD])|(?:\uD83C\uDFFB\u200D[\u2695\u2696\u2708]|\uD83C\uDFFF\u200D[\u2695\u2696\u2708]|\uD83C\uDFFE\u200D[\u2695\u2696\u2708]|\uD83C\uDFFD\u200D[\u2695\u2696\u2708]|\uD83C\uDFFC\u200D[\u2695\u2696\u2708])\uFE0F|\uD83C\uDFFB\u200D(?:\uD83C[\uDF3E\uDF73\uDF93\uDFA4\uDFA8\uDFEB\uDFED]|\uD83D[\uDCBB\uDCBC\uDD27\uDD2C\uDE80\uDE92]|\uD83E[\uDDAF-\uDDB3\uDDBC\uDDBD])|\uD83C[\uDFFB-\uDFFF])|(?:\uD83E\uDDD1\uD83C\uDFFB\u200D\uD83E\uDD1D\u200D\uD83E\uDDD1|\uD83D\uDC69\uD83C\uDFFC\u200D\uD83E\uDD1D\u200D\uD83D\uDC69)\uD83C\uDFFB|\uD83E\uDDD1(?:\uD83C\uDFFF\u200D\uD83E\uDD1D\u200D\uD83E\uDDD1(?:\uD83C[\uDFFB-\uDFFF])|\u200D\uD83E\uDD1D\u200D\uD83E\uDDD1)|(?:\uD83E\uDDD1\uD83C\uDFFE\u200D\uD83E\uDD1D\u200D\uD83E\uDDD1|\uD83D\uDC69\uD83C\uDFFF\u200D\uD83E\uDD1D\u200D(?:\uD83D[\uDC68\uDC69]))(?:\uD83C[\uDFFB-\uDFFE])|(?:\uD83E\uDDD1\uD83C\uDFFC\u200D\uD83E\uDD1D\u200D\uD83E\uDDD1|\uD83D\uDC69\uD83C\uDFFD\u200D\uD83E\uDD1D\u200D\uD83D\uDC69)(?:\uD83C[\uDFFB\uDFFC])|\uD83D\uDC69(?:\uD83C\uDFFE\u200D(?:\uD83E\uDD1D\u200D\uD83D\uDC68(?:\uD83C[\uDFFB-\uDFFD\uDFFF])|\uD83C[\uDF3E\uDF73\uDF93\uDFA4\uDFA8\uDFEB\uDFED]|\uD83D[\uDCBB\uDCBC\uDD27\uDD2C\uDE80\uDE92]|\uD83E[\uDDAF-\uDDB3\uDDBC\uDDBD])|\uD83C\uDFFC\u200D(?:\uD83E\uDD1D\u200D\uD83D\uDC68(?:\uD83C[\uDFFB\uDFFD-\uDFFF])|\uD83C[\uDF3E\uDF73\uDF93\uDFA4\uDFA8\uDFEB\uDFED]|\uD83D[\uDCBB\uDCBC\uDD27\uDD2C\uDE80\uDE92]|\uD83E[\uDDAF-\uDDB3\uDDBC\uDDBD])|\uD83C\uDFFB\u200D(?:\uD83E\uDD1D\u200D\uD83D\uDC68(?:\uD83C[\uDFFC-\uDFFF])|\uD83C[\uDF3E\uDF73\uDF93\uDFA4\uDFA8\uDFEB\uDFED]|\uD83D[\uDCBB\uDCBC\uDD27\uDD2C\uDE80\uDE92]|\uD83E[\uDDAF-\uDDB3\uDDBC\uDDBD])|\uD83C\uDFFD\u200D(?:\uD83E\uDD1D\u200D\uD83D\uDC68(?:\uD83C[\uDFFB\uDFFC\uDFFE\uDFFF])|\uD83C[\uDF3E\uDF73\uDF93\uDFA4\uDFA8\uDFEB\uDFED]|\uD83D[\uDCBB\uDCBC\uDD27\uDD2C\uDE80\uDE92]|\uD83E[\uDDAF-\uDDB3\uDDBC\uDDBD])|\u200D(?:\u2764\uFE0F\u200D(?:\uD83D\uDC8B\u200D(?:\uD83D[\uDC68\uDC69])|\uD83D[\uDC68\uDC69])|\uD83C[\uDF3E\uDF73\uDF93\uDFA4\uDFA8\uDFEB\uDFED]|\uD83D[\uDCBB\uDCBC\uDD27\uDD2C\uDE80\uDE92]|\uD83E[\uDDAF-\uDDB3\uDDBC\uDDBD])|\uD83C\uDFFF\u200D(?:\uD83C[\uDF3E\uDF73\uDF93\uDFA4\uDFA8\uDFEB\uDFED]|\uD83D[\uDCBB\uDCBC\uDD27\uDD2C\uDE80\uDE92]|\uD83E[\uDDAF-\uDDB3\uDDBC\uDDBD]))|\uD83D\uDC69\u200D\uD83D\uDC69\u200D(?:\uD83D\uDC66\u200D\uD83D\uDC66|\uD83D\uDC67\u200D(?:\uD83D[\uDC66\uDC67]))|(?:\uD83E\uDDD1\uD83C\uDFFD\u200D\uD83E\uDD1D\u200D\uD83E\uDDD1|\uD83D\uDC69\uD83C\uDFFE\u200D\uD83E\uDD1D\u200D\uD83D\uDC69)(?:\uD83C[\uDFFB-\uDFFD])|\uD83D\uDC69\u200D\uD83D\uDC66\u200D\uD83D\uDC66|\uD83D\uDC69\u200D\uD83D\uDC69\u200D(?:\uD83D[\uDC66\uDC67])|(?:\uD83D\uDC41\uFE0F\u200D\uD83D\uDDE8|\uD83D\uDC69(?:\uD83C\uDFFF\u200D[\u2695\u2696\u2708]|\uD83C\uDFFE\u200D[\u2695\u2696\u2708]|\uD83C\uDFFC\u200D[\u2695\u2696\u2708]|\uD83C\uDFFB\u200D[\u2695\u2696\u2708]|\uD83C\uDFFD\u200D[\u2695\u2696\u2708]|\u200D[\u2695\u2696\u2708])|(?:(?:\u26F9|\uD83C[\uDFCB\uDFCC]|\uD83D\uDD75)\uFE0F|\uD83D\uDC6F|\uD83E[\uDD3C\uDDDE\uDDDF])\u200D[\u2640\u2642]|(?:\u26F9|\uD83C[\uDFCB\uDFCC]|\uD83D\uDD75)(?:\uD83C[\uDFFB-\uDFFF])\u200D[\u2640\u2642]|(?:\uD83C[\uDFC3\uDFC4\uDFCA]|\uD83D[\uDC6E\uDC71\uDC73\uDC77\uDC81\uDC82\uDC86\uDC87\uDE45-\uDE47\uDE4B\uDE4D\uDE4E\uDEA3\uDEB4-\uDEB6]|\uD83E[\uDD26\uDD37-\uDD39\uDD3D\uDD3E\uDDB8\uDDB9\uDDCD-\uDDCF\uDDD6-\uDDDD])(?:(?:\uD83C[\uDFFB-\uDFFF])\u200D[\u2640\u2642]|\u200D[\u2640\u2642])|\uD83C\uDFF4\u200D\u2620)\uFE0F|\uD83D\uDC69\u200D\uD83D\uDC67\u200D(?:\uD83D[\uDC66\uDC67])|\uD83C\uDFF3\uFE0F\u200D\uD83C\uDF08|\uD83D\uDC15\u200D\uD83E\uDDBA|\uD83D\uDC69\u200D\uD83D\uDC66|\uD83D\uDC69\u200D\uD83D\uDC67|\uD83C\uDDFD\uD83C\uDDF0|\uD83C\uDDF4\uD83C\uDDF2|\uD83C\uDDF6\uD83C\uDDE6|[#\*0-9]\uFE0F\u20E3|\uD83C\uDDE7(?:\uD83C[\uDDE6\uDDE7\uDDE9-\uDDEF\uDDF1-\uDDF4\uDDF6-\uDDF9\uDDFB\uDDFC\uDDFE\uDDFF])|\uD83C\uDDF9(?:\uD83C[\uDDE6\uDDE8\uDDE9\uDDEB-\uDDED\uDDEF-\uDDF4\uDDF7\uDDF9\uDDFB\uDDFC\uDDFF])|\uD83C\uDDEA(?:\uD83C[\uDDE6\uDDE8\uDDEA\uDDEC\uDDED\uDDF7-\uDDFA])|\uD83E\uDDD1(?:\uD83C[\uDFFB-\uDFFF])|\uD83C\uDDF7(?:\uD83C[\uDDEA\uDDF4\uDDF8\uDDFA\uDDFC])|\uD83D\uDC69(?:\uD83C[\uDFFB-\uDFFF])|\uD83C\uDDF2(?:\uD83C[\uDDE6\uDDE8-\uDDED\uDDF0-\uDDFF])|\uD83C\uDDE6(?:\uD83C[\uDDE8-\uDDEC\uDDEE\uDDF1\uDDF2\uDDF4\uDDF6-\uDDFA\uDDFC\uDDFD\uDDFF])|\uD83C\uDDF0(?:\uD83C[\uDDEA\uDDEC-\uDDEE\uDDF2\uDDF3\uDDF5\uDDF7\uDDFC\uDDFE\uDDFF])|\uD83C\uDDED(?:\uD83C[\uDDF0\uDDF2\uDDF3\uDDF7\uDDF9\uDDFA])|\uD83C\uDDE9(?:\uD83C[\uDDEA\uDDEC\uDDEF\uDDF0\uDDF2\uDDF4\uDDFF])|\uD83C\uDDFE(?:\uD83C[\uDDEA\uDDF9])|\uD83C\uDDEC(?:\uD83C[\uDDE6\uDDE7\uDDE9-\uDDEE\uDDF1-\uDDF3\uDDF5-\uDDFA\uDDFC\uDDFE])|\uD83C\uDDF8(?:\uD83C[\uDDE6-\uDDEA\uDDEC-\uDDF4\uDDF7-\uDDF9\uDDFB\uDDFD-\uDDFF])|\uD83C\uDDEB(?:\uD83C[\uDDEE-\uDDF0\uDDF2\uDDF4\uDDF7])|\uD83C\uDDF5(?:\uD83C[\uDDE6\uDDEA-\uDDED\uDDF0-\uDDF3\uDDF7-\uDDF9\uDDFC\uDDFE])|\uD83C\uDDFB(?:\uD83C[\uDDE6\uDDE8\uDDEA\uDDEC\uDDEE\uDDF3\uDDFA])|\uD83C\uDDF3(?:\uD83C[\uDDE6\uDDE8\uDDEA-\uDDEC\uDDEE\uDDF1\uDDF4\uDDF5\uDDF7\uDDFA\uDDFF])|\uD83C\uDDE8(?:\uD83C[\uDDE6\uDDE8\uDDE9\uDDEB-\uDDEE\uDDF0-\uDDF5\uDDF7\uDDFA-\uDDFF])|\uD83C\uDDF1(?:\uD83C[\uDDE6-\uDDE8\uDDEE\uDDF0\uDDF7-\uDDFB\uDDFE])|\uD83C\uDDFF(?:\uD83C[\uDDE6\uDDF2\uDDFC])|\uD83C\uDDFC(?:\uD83C[\uDDEB\uDDF8])|\uD83C\uDDFA(?:\uD83C[\uDDE6\uDDEC\uDDF2\uDDF3\uDDF8\uDDFE\uDDFF])|\uD83C\uDDEE(?:\uD83C[\uDDE8-\uDDEA\uDDF1-\uDDF4\uDDF6-\uDDF9])|\uD83C\uDDEF(?:\uD83C[\uDDEA\uDDF2\uDDF4\uDDF5])|(?:\uD83C[\uDFC3\uDFC4\uDFCA]|\uD83D[\uDC6E\uDC71\uDC73\uDC77\uDC81\uDC82\uDC86\uDC87\uDE45-\uDE47\uDE4B\uDE4D\uDE4E\uDEA3\uDEB4-\uDEB6]|\uD83E[\uDD26\uDD37-\uDD39\uDD3D\uDD3E\uDDB8\uDDB9\uDDCD-\uDDCF\uDDD6-\uDDDD])(?:\uD83C[\uDFFB-\uDFFF])|(?:\u26F9|\uD83C[\uDFCB\uDFCC]|\uD83D\uDD75)(?:\uD83C[\uDFFB-\uDFFF])|(?:[\u261D\u270A-\u270D]|\uD83C[\uDF85\uDFC2\uDFC7]|\uD83D[\uDC42\uDC43\uDC46-\uDC50\uDC66\uDC67\uDC6B-\uDC6D\uDC70\uDC72\uDC74-\uDC76\uDC78\uDC7C\uDC83\uDC85\uDCAA\uDD74\uDD7A\uDD90\uDD95\uDD96\uDE4C\uDE4F\uDEC0\uDECC]|\uD83E[\uDD0F\uDD18-\uDD1C\uDD1E\uDD1F\uDD30-\uDD36\uDDB5\uDDB6\uDDBB\uDDD2-\uDDD5])(?:\uD83C[\uDFFB-\uDFFF])|(?:[\u231A\u231B\u23E9-\u23EC\u23F0\u23F3\u25FD\u25FE\u2614\u2615\u2648-\u2653\u267F\u2693\u26A1\u26AA\u26AB\u26BD\u26BE\u26C4\u26C5\u26CE\u26D4\u26EA\u26F2\u26F3\u26F5\u26FA\u26FD\u2705\u270A\u270B\u2728\u274C\u274E\u2753-\u2755\u2757\u2795-\u2797\u27B0\u27BF\u2B1B\u2B1C\u2B50\u2B55]|\uD83C[\uDC04\uDCCF\uDD8E\uDD91-\uDD9A\uDDE6-\uDDFF\uDE01\uDE1A\uDE2F\uDE32-\uDE36\uDE38-\uDE3A\uDE50\uDE51\uDF00-\uDF20\uDF2D-\uDF35\uDF37-\uDF7C\uDF7E-\uDF93\uDFA0-\uDFCA\uDFCF-\uDFD3\uDFE0-\uDFF0\uDFF4\uDFF8-\uDFFF]|\uD83D[\uDC00-\uDC3E\uDC40\uDC42-\uDCFC\uDCFF-\uDD3D\uDD4B-\uDD4E\uDD50-\uDD67\uDD7A\uDD95\uDD96\uDDA4\uDDFB-\uDE4F\uDE80-\uDEC5\uDECC\uDED0-\uDED2\uDED5\uDEEB\uDEEC\uDEF4-\uDEFA\uDFE0-\uDFEB]|\uD83E[\uDD0D-\uDD3A\uDD3C-\uDD45\uDD47-\uDD71\uDD73-\uDD76\uDD7A-\uDDA2\uDDA5-\uDDAA\uDDAE-\uDDCA\uDDCD-\uDDFF\uDE70-\uDE73\uDE78-\uDE7A\uDE80-\uDE82\uDE90-\uDE95])|(?:[#\*0-9\xA9\xAE\u203C\u2049\u2122\u2139\u2194-\u2199\u21A9\u21AA\u231A\u231B\u2328\u23CF\u23E9-\u23F3\u23F8-\u23FA\u24C2\u25AA\u25AB\u25B6\u25C0\u25FB-\u25FE\u2600-\u2604\u260E\u2611\u2614\u2615\u2618\u261D\u2620\u2622\u2623\u2626\u262A\u262E\u262F\u2638-\u263A\u2640\u2642\u2648-\u2653\u265F\u2660\u2663\u2665\u2666\u2668\u267B\u267E\u267F\u2692-\u2697\u2699\u269B\u269C\u26A0\u26A1\u26AA\u26AB\u26B0\u26B1\u26BD\u26BE\u26C4\u26C5\u26C8\u26CE\u26CF\u26D1\u26D3\u26D4\u26E9\u26EA\u26F0-\u26F5\u26F7-\u26FA\u26FD\u2702\u2705\u2708-\u270D\u270F\u2712\u2714\u2716\u271D\u2721\u2728\u2733\u2734\u2744\u2747\u274C\u274E\u2753-\u2755\u2757\u2763\u2764\u2795-\u2797\u27A1\u27B0\u27BF\u2934\u2935\u2B05-\u2B07\u2B1B\u2B1C\u2B50\u2B55\u3030\u303D\u3297\u3299]|\uD83C[\uDC04\uDCCF\uDD70\uDD71\uDD7E\uDD7F\uDD8E\uDD91-\uDD9A\uDDE6-\uDDFF\uDE01\uDE02\uDE1A\uDE2F\uDE32-\uDE3A\uDE50\uDE51\uDF00-\uDF21\uDF24-\uDF93\uDF96\uDF97\uDF99-\uDF9B\uDF9E-\uDFF0\uDFF3-\uDFF5\uDFF7-\uDFFF]|\uD83D[\uDC00-\uDCFD\uDCFF-\uDD3D\uDD49-\uDD4E\uDD50-\uDD67\uDD6F\uDD70\uDD73-\uDD7A\uDD87\uDD8A-\uDD8D\uDD90\uDD95\uDD96\uDDA4\uDDA5\uDDA8\uDDB1\uDDB2\uDDBC\uDDC2-\uDDC4\uDDD1-\uDDD3\uDDDC-\uDDDE\uDDE1\uDDE3\uDDE8\uDDEF\uDDF3\uDDFA-\uDE4F\uDE80-\uDEC5\uDECB-\uDED2\uDED5\uDEE0-\uDEE5\uDEE9\uDEEB\uDEEC\uDEF0\uDEF3-\uDEFA\uDFE0-\uDFEB]|\uD83E[\uDD0D-\uDD3A\uDD3C-\uDD45\uDD47-\uDD71\uDD73-\uDD76\uDD7A-\uDDA2\uDDA5-\uDDAA\uDDAE-\uDDCA\uDDCD-\uDDFF\uDE70-\uDE73\uDE78-\uDE7A\uDE80-\uDE82\uDE90-\uDE95])\uFE0F|(?:[\u261D\u26F9\u270A-\u270D]|\uD83C[\uDF85\uDFC2-\uDFC4\uDFC7\uDFCA-\uDFCC]|\uD83D[\uDC42\uDC43\uDC46-\uDC50\uDC66-\uDC78\uDC7C\uDC81-\uDC83\uDC85-\uDC87\uDC8F\uDC91\uDCAA\uDD74\uDD75\uDD7A\uDD90\uDD95\uDD96\uDE45-\uDE47\uDE4B-\uDE4F\uDEA3\uDEB4-\uDEB6\uDEC0\uDECC]|\uD83E[\uDD0F\uDD18-\uDD1F\uDD26\uDD30-\uDD39\uDD3C-\uDD3E\uDDB5\uDDB6\uDDB8\uDDB9\uDDBB\uDDCD-\uDDCF\uDDD1-\uDDDD])/g;
      };
    });
    var require_doT = __commonJS(function(exports, module) {
      (function() {
        'use strict';
        var doT3 = {
          name: 'doT',
          version: '1.1.1',
          templateSettings: {
            evaluate: /\{\{([\s\S]+?(\}?)+)\}\}/g,
            interpolate: /\{\{=([\s\S]+?)\}\}/g,
            encode: /\{\{!([\s\S]+?)\}\}/g,
            use: /\{\{#([\s\S]+?)\}\}/g,
            useParams: /(^|[^\w$])def(?:\.|\[[\'\"])([\w$\.]+)(?:[\'\"]\])?\s*\:\s*([\w$\.]+|\"[^\"]+\"|\'[^\']+\'|\{[^\}]+\})/g,
            define: /\{\{##\s*([\w\.$]+)\s*(\:|=)([\s\S]+?)#\}\}/g,
            defineParams: /^\s*([\w$]+):([\s\S]+)/,
            conditional: /\{\{\?(\?)?\s*([\s\S]*?)\s*\}\}/g,
            iterate: /\{\{~\s*(?:\}\}|([\s\S]+?)\s*\:\s*([\w$]+)\s*(?:\:\s*([\w$]+))?\s*\}\})/g,
            varname: 'it',
            strip: true,
            append: true,
            selfcontained: false,
            doNotSkipEncoded: false
          },
          template: void 0,
          compile: void 0,
          log: true
        };
        (function() {
          if ((typeof globalThis === 'undefined' ? 'undefined' : _typeof(globalThis)) === 'object') {
            return;
          }
          try {
            Object.defineProperty(Object.prototype, '__magic__', {
              get: function get() {
                return this;
              },
              configurable: true
            });
            __magic__.globalThis = __magic__;
            delete Object.prototype.__magic__;
          } catch (e) {
            window.globalThis = function() {
              if (typeof self !== 'undefined') {
                return self;
              }
              if (typeof window !== 'undefined') {
                return window;
              }
              if (typeof global !== 'undefined') {
                return global;
              }
              if (typeof this !== 'undefined') {
                return this;
              }
              throw new Error('Unable to locate global `this`');
            }();
          }
        })();
        doT3.encodeHTMLSource = function(doNotSkipEncoded) {
          var encodeHTMLRules = {
            '&': '&#38;',
            '<': '&#60;',
            '>': '&#62;',
            '"': '&#34;',
            '\'': '&#39;',
            '/': '&#47;'
          }, matchHTML = doNotSkipEncoded ? /[&<>"'\/]/g : /&(?!#?\w+;)|<|>|"|'|\//g;
          return function(code) {
            return code ? code.toString().replace(matchHTML, function(m) {
              return encodeHTMLRules[m] || m;
            }) : '';
          };
        };
        if (typeof module !== 'undefined' && module.exports) {
          module.exports = doT3;
        } else if (typeof define === 'function' && define.amd) {
          define(function() {
            return doT3;
          });
        } else {
          globalThis.doT = doT3;
        }
        var startend = {
          append: {
            start: '\'+(',
            end: ')+\'',
            startencode: '\'+encodeHTML('
          },
          split: {
            start: '\';out+=(',
            end: ');out+=\'',
            startencode: '\';out+=encodeHTML('
          }
        }, skip = /$^/;
        function resolveDefs(c, block, def) {
          return (typeof block === 'string' ? block : block.toString()).replace(c.define || skip, function(m, code, assign, value) {
            if (code.indexOf('def.') === 0) {
              code = code.substring(4);
            }
            if (!(code in def)) {
              if (assign === ':') {
                if (c.defineParams) {
                  value.replace(c.defineParams, function(m2, param, v) {
                    def[code] = {
                      arg: param,
                      text: v
                    };
                  });
                }
                if (!(code in def)) {
                  def[code] = value;
                }
              } else {
                new Function('def', 'def[\'' + code + '\']=' + value)(def);
              }
            }
            return '';
          }).replace(c.use || skip, function(m, code) {
            if (c.useParams) {
              code = code.replace(c.useParams, function(m2, s, d, param) {
                if (def[d] && def[d].arg && param) {
                  var rw = (d + ':' + param).replace(/'|\\/g, '_');
                  def.__exp = def.__exp || {};
                  def.__exp[rw] = def[d].text.replace(new RegExp('(^|[^\\w$])' + def[d].arg + '([^\\w$])', 'g'), '$1' + param + '$2');
                  return s + 'def.__exp[\'' + rw + '\']';
                }
              });
            }
            var v = new Function('def', 'return ' + code)(def);
            return v ? resolveDefs(c, v, def) : v;
          });
        }
        function unescape(code) {
          return code.replace(/\\('|\\)/g, '$1').replace(/[\r\t\n]/g, ' ');
        }
        doT3.template = function(tmpl, c, def) {
          c = c || doT3.templateSettings;
          var cse = c.append ? startend.append : startend.split, needhtmlencode, sid = 0, indv, str = c.use || c.define ? resolveDefs(c, tmpl, def || {}) : tmpl;
          str = ('var out=\'' + (c.strip ? str.replace(/(^|\r|\n)\t* +| +\t*(\r|\n|$)/g, ' ').replace(/\r|\n|\t|\/\*[\s\S]*?\*\//g, '') : str).replace(/'|\\/g, '\\$&').replace(c.interpolate || skip, function(m, code) {
            return cse.start + unescape(code) + cse.end;
          }).replace(c.encode || skip, function(m, code) {
            needhtmlencode = true;
            return cse.startencode + unescape(code) + cse.end;
          }).replace(c.conditional || skip, function(m, elsecase, code) {
            return elsecase ? code ? '\';}else if(' + unescape(code) + '){out+=\'' : '\';}else{out+=\'' : code ? '\';if(' + unescape(code) + '){out+=\'' : '\';}out+=\'';
          }).replace(c.iterate || skip, function(m, iterate, vname, iname) {
            if (!iterate) {
              return '\';} } out+=\'';
            }
            sid += 1;
            indv = iname || 'i' + sid;
            iterate = unescape(iterate);
            return '\';var arr' + sid + '=' + iterate + ';if(arr' + sid + '){var ' + vname + ',' + indv + '=-1,l' + sid + '=arr' + sid + '.length-1;while(' + indv + '<l' + sid + '){' + vname + '=arr' + sid + '[' + indv + '+=1];out+=\'';
          }).replace(c.evaluate || skip, function(m, code) {
            return '\';' + unescape(code) + 'out+=\'';
          }) + '\';return out;').replace(/\n/g, '\\n').replace(/\t/g, '\\t').replace(/\r/g, '\\r').replace(/(\s|;|\}|^|\{)out\+='';/g, '$1').replace(/\+''/g, '');
          if (needhtmlencode) {
            if (!c.selfcontained && globalThis && !globalThis._encodeHTML) {
              globalThis._encodeHTML = doT3.encodeHTMLSource(c.doNotSkipEncoded);
            }
            str = 'var encodeHTML = typeof _encodeHTML !== \'undefined\' ? _encodeHTML : (' + doT3.encodeHTMLSource.toString() + '(' + (c.doNotSkipEncoded || '') + '));' + str;
          }
          try {
            return new Function(c.varname, str);
          } catch (e) {
            if (typeof console !== 'undefined') {
              console.log('Could not create a template function: ' + str);
            }
            throw e;
          }
        };
        doT3.compile = function(tmpl, def) {
          return doT3.template(tmpl, null, def);
        };
      })();
    });
    var require_es6_promise = __commonJS(function(exports, module) {
      (function(global2, factory) {
        _typeof(exports) === 'object' && typeof module !== 'undefined' ? module.exports = factory() : typeof define === 'function' && define.amd ? define(factory) : global2.ES6Promise = factory();
      })(exports, function() {
        'use strict';
        function objectOrFunction(x) {
          var type = _typeof(x);
          return x !== null && (type === 'object' || type === 'function');
        }
        function isFunction(x) {
          return typeof x === 'function';
        }
        var _isArray = void 0;
        if (Array.isArray) {
          _isArray = Array.isArray;
        } else {
          _isArray = function _isArray(x) {
            return Object.prototype.toString.call(x) === '[object Array]';
          };
        }
        var isArray = _isArray;
        var len = 0;
        var vertxNext = void 0;
        var customSchedulerFn = void 0;
        var asap = function asap2(callback, arg) {
          queue4[len] = callback;
          queue4[len + 1] = arg;
          len += 2;
          if (len === 2) {
            if (customSchedulerFn) {
              customSchedulerFn(flush);
            } else {
              scheduleFlush();
            }
          }
        };
        function setScheduler(scheduleFn) {
          customSchedulerFn = scheduleFn;
        }
        function setAsap(asapFn) {
          asap = asapFn;
        }
        var browserWindow = typeof window !== 'undefined' ? window : void 0;
        var browserGlobal = browserWindow || {};
        var BrowserMutationObserver = browserGlobal.MutationObserver || browserGlobal.WebKitMutationObserver;
        var isNode2 = typeof self === 'undefined' && typeof process !== 'undefined' && {}.toString.call(process) === '[object process]';
        var isWorker = typeof Uint8ClampedArray !== 'undefined' && typeof importScripts !== 'undefined' && typeof MessageChannel !== 'undefined';
        function useNextTick() {
          return function() {
            return process.nextTick(flush);
          };
        }
        function useVertxTimer() {
          if (typeof vertxNext !== 'undefined') {
            return function() {
              vertxNext(flush);
            };
          }
          return useSetTimeout();
        }
        function useMutationObserver() {
          var iterations = 0;
          var observer = new BrowserMutationObserver(flush);
          var node = document.createTextNode('');
          observer.observe(node, {
            characterData: true
          });
          return function() {
            node.data = iterations = ++iterations % 2;
          };
        }
        function useMessageChannel() {
          var channel = new MessageChannel();
          channel.port1.onmessage = flush;
          return function() {
            return channel.port2.postMessage(0);
          };
        }
        function useSetTimeout() {
          var globalSetTimeout = setTimeout;
          return function() {
            return globalSetTimeout(flush, 1);
          };
        }
        var queue4 = new Array(1e3);
        function flush() {
          for (var i = 0; i < len; i += 2) {
            var callback = queue4[i];
            var arg = queue4[i + 1];
            callback(arg);
            queue4[i] = void 0;
            queue4[i + 1] = void 0;
          }
          len = 0;
        }
        function attemptVertx() {
          try {
            var vertx = Function('return this')().require('vertx');
            vertxNext = vertx.runOnLoop || vertx.runOnContext;
            return useVertxTimer();
          } catch (e) {
            return useSetTimeout();
          }
        }
        var scheduleFlush = void 0;
        if (isNode2) {
          scheduleFlush = useNextTick();
        } else if (BrowserMutationObserver) {
          scheduleFlush = useMutationObserver();
        } else if (isWorker) {
          scheduleFlush = useMessageChannel();
        } else if (browserWindow === void 0 && true) {
          scheduleFlush = attemptVertx();
        } else {
          scheduleFlush = useSetTimeout();
        }
        function then(onFulfillment, onRejection) {
          var parent = this;
          var child = new this.constructor(noop4);
          if (child[PROMISE_ID] === void 0) {
            makePromise(child);
          }
          var _state = parent._state;
          if (_state) {
            var callback = arguments[_state - 1];
            asap(function() {
              return invokeCallback(_state, child, callback, parent._result);
            });
          } else {
            subscribe2(parent, child, onFulfillment, onRejection);
          }
          return child;
        }
        function resolve$1(object) {
          var Constructor = this;
          if (object && _typeof(object) === 'object' && object.constructor === Constructor) {
            return object;
          }
          var promise = new Constructor(noop4);
          resolve(promise, object);
          return promise;
        }
        var PROMISE_ID = Math.random().toString(36).substring(2);
        function noop4() {}
        var PENDING = void 0;
        var FULFILLED = 1;
        var REJECTED = 2;
        function selfFulfillment() {
          return new TypeError('You cannot resolve a promise with itself');
        }
        function cannotReturnOwn() {
          return new TypeError('A promises callback cannot return that same promise.');
        }
        function tryThen(then$$1, value, fulfillmentHandler, rejectionHandler) {
          try {
            then$$1.call(value, fulfillmentHandler, rejectionHandler);
          } catch (e) {
            return e;
          }
        }
        function handleForeignThenable(promise, thenable, then$$1) {
          asap(function(promise2) {
            var sealed = false;
            var error = tryThen(then$$1, thenable, function(value) {
              if (sealed) {
                return;
              }
              sealed = true;
              if (thenable !== value) {
                resolve(promise2, value);
              } else {
                fulfill(promise2, value);
              }
            }, function(reason) {
              if (sealed) {
                return;
              }
              sealed = true;
              reject(promise2, reason);
            }, 'Settle: ' + (promise2._label || ' unknown promise'));
            if (!sealed && error) {
              sealed = true;
              reject(promise2, error);
            }
          }, promise);
        }
        function handleOwnThenable(promise, thenable) {
          if (thenable._state === FULFILLED) {
            fulfill(promise, thenable._result);
          } else if (thenable._state === REJECTED) {
            reject(promise, thenable._result);
          } else {
            subscribe2(thenable, void 0, function(value) {
              return resolve(promise, value);
            }, function(reason) {
              return reject(promise, reason);
            });
          }
        }
        function handleMaybeThenable(promise, maybeThenable, then$$1) {
          if (maybeThenable.constructor === promise.constructor && then$$1 === then && maybeThenable.constructor.resolve === resolve$1) {
            handleOwnThenable(promise, maybeThenable);
          } else {
            if (then$$1 === void 0) {
              fulfill(promise, maybeThenable);
            } else if (isFunction(then$$1)) {
              handleForeignThenable(promise, maybeThenable, then$$1);
            } else {
              fulfill(promise, maybeThenable);
            }
          }
        }
        function resolve(promise, value) {
          if (promise === value) {
            reject(promise, selfFulfillment());
          } else if (objectOrFunction(value)) {
            var then$$1 = void 0;
            try {
              then$$1 = value.then;
            } catch (error) {
              reject(promise, error);
              return;
            }
            handleMaybeThenable(promise, value, then$$1);
          } else {
            fulfill(promise, value);
          }
        }
        function publishRejection(promise) {
          if (promise._onerror) {
            promise._onerror(promise._result);
          }
          publish(promise);
        }
        function fulfill(promise, value) {
          if (promise._state !== PENDING) {
            return;
          }
          promise._result = value;
          promise._state = FULFILLED;
          if (promise._subscribers.length !== 0) {
            asap(publish, promise);
          }
        }
        function reject(promise, reason) {
          if (promise._state !== PENDING) {
            return;
          }
          promise._state = REJECTED;
          promise._result = reason;
          asap(publishRejection, promise);
        }
        function subscribe2(parent, child, onFulfillment, onRejection) {
          var _subscribers = parent._subscribers;
          var length = _subscribers.length;
          parent._onerror = null;
          _subscribers[length] = child;
          _subscribers[length + FULFILLED] = onFulfillment;
          _subscribers[length + REJECTED] = onRejection;
          if (length === 0 && parent._state) {
            asap(publish, parent);
          }
        }
        function publish(promise) {
          var subscribers = promise._subscribers;
          var settled = promise._state;
          if (subscribers.length === 0) {
            return;
          }
          var child = void 0, callback = void 0, detail = promise._result;
          for (var i = 0; i < subscribers.length; i += 3) {
            child = subscribers[i];
            callback = subscribers[i + settled];
            if (child) {
              invokeCallback(settled, child, callback, detail);
            } else {
              callback(detail);
            }
          }
          promise._subscribers.length = 0;
        }
        function invokeCallback(settled, promise, callback, detail) {
          var hasCallback = isFunction(callback), value = void 0, error = void 0, succeeded = true;
          if (hasCallback) {
            try {
              value = callback(detail);
            } catch (e) {
              succeeded = false;
              error = e;
            }
            if (promise === value) {
              reject(promise, cannotReturnOwn());
              return;
            }
          } else {
            value = detail;
          }
          if (promise._state !== PENDING) {} else if (hasCallback && succeeded) {
            resolve(promise, value);
          } else if (succeeded === false) {
            reject(promise, error);
          } else if (settled === FULFILLED) {
            fulfill(promise, value);
          } else if (settled === REJECTED) {
            reject(promise, value);
          }
        }
        function initializePromise(promise, resolver) {
          try {
            resolver(function resolvePromise(value) {
              resolve(promise, value);
            }, function rejectPromise(reason) {
              reject(promise, reason);
            });
          } catch (e) {
            reject(promise, e);
          }
        }
        var id = 0;
        function nextId() {
          return id++;
        }
        function makePromise(promise) {
          promise[PROMISE_ID] = id++;
          promise._state = void 0;
          promise._result = void 0;
          promise._subscribers = [];
        }
        function validationError() {
          return new Error('Array Methods must be provided an Array');
        }
        var Enumerator = function() {
          function Enumerator2(Constructor, input) {
            this._instanceConstructor = Constructor;
            this.promise = new Constructor(noop4);
            if (!this.promise[PROMISE_ID]) {
              makePromise(this.promise);
            }
            if (isArray(input)) {
              this.length = input.length;
              this._remaining = input.length;
              this._result = new Array(this.length);
              if (this.length === 0) {
                fulfill(this.promise, this._result);
              } else {
                this.length = this.length || 0;
                this._enumerate(input);
                if (this._remaining === 0) {
                  fulfill(this.promise, this._result);
                }
              }
            } else {
              reject(this.promise, validationError());
            }
          }
          Enumerator2.prototype._enumerate = function _enumerate(input) {
            for (var i = 0; this._state === PENDING && i < input.length; i++) {
              this._eachEntry(input[i], i);
            }
          };
          Enumerator2.prototype._eachEntry = function _eachEntry(entry, i) {
            var c = this._instanceConstructor;
            var resolve$$1 = c.resolve;
            if (resolve$$1 === resolve$1) {
              var _then = void 0;
              var error = void 0;
              var didError = false;
              try {
                _then = entry.then;
              } catch (e) {
                didError = true;
                error = e;
              }
              if (_then === then && entry._state !== PENDING) {
                this._settledAt(entry._state, i, entry._result);
              } else if (typeof _then !== 'function') {
                this._remaining--;
                this._result[i] = entry;
              } else if (c === Promise$1) {
                var promise = new c(noop4);
                if (didError) {
                  reject(promise, error);
                } else {
                  handleMaybeThenable(promise, entry, _then);
                }
                this._willSettleAt(promise, i);
              } else {
                this._willSettleAt(new c(function(resolve$$12) {
                  return resolve$$12(entry);
                }), i);
              }
            } else {
              this._willSettleAt(resolve$$1(entry), i);
            }
          };
          Enumerator2.prototype._settledAt = function _settledAt(state, i, value) {
            var promise = this.promise;
            if (promise._state === PENDING) {
              this._remaining--;
              if (state === REJECTED) {
                reject(promise, value);
              } else {
                this._result[i] = value;
              }
            }
            if (this._remaining === 0) {
              fulfill(promise, this._result);
            }
          };
          Enumerator2.prototype._willSettleAt = function _willSettleAt(promise, i) {
            var enumerator = this;
            subscribe2(promise, void 0, function(value) {
              return enumerator._settledAt(FULFILLED, i, value);
            }, function(reason) {
              return enumerator._settledAt(REJECTED, i, reason);
            });
          };
          return Enumerator2;
        }();
        function all(entries) {
          return new Enumerator(this, entries).promise;
        }
        function race(entries) {
          var Constructor = this;
          if (!isArray(entries)) {
            return new Constructor(function(_, reject2) {
              return reject2(new TypeError('You must pass an array to race.'));
            });
          } else {
            return new Constructor(function(resolve2, reject2) {
              var length = entries.length;
              for (var i = 0; i < length; i++) {
                Constructor.resolve(entries[i]).then(resolve2, reject2);
              }
            });
          }
        }
        function reject$1(reason) {
          var Constructor = this;
          var promise = new Constructor(noop4);
          reject(promise, reason);
          return promise;
        }
        function needsResolver() {
          throw new TypeError('You must pass a resolver function as the first argument to the promise constructor');
        }
        function needsNew() {
          throw new TypeError('Failed to construct \'Promise\': Please use the \'new\' operator, this object constructor cannot be called as a function.');
        }
        var Promise$1 = function() {
          function Promise2(resolver) {
            this[PROMISE_ID] = nextId();
            this._result = this._state = void 0;
            this._subscribers = [];
            if (noop4 !== resolver) {
              typeof resolver !== 'function' && needsResolver();
              this instanceof Promise2 ? initializePromise(this, resolver) : needsNew();
            }
          }
          Promise2.prototype['catch'] = function _catch(onRejection) {
            return this.then(null, onRejection);
          };
          Promise2.prototype['finally'] = function _finally(callback) {
            var promise = this;
            var constructor = promise.constructor;
            if (isFunction(callback)) {
              return promise.then(function(value) {
                return constructor.resolve(callback()).then(function() {
                  return value;
                });
              }, function(reason) {
                return constructor.resolve(callback()).then(function() {
                  throw reason;
                });
              });
            }
            return promise.then(callback, callback);
          };
          return Promise2;
        }();
        Promise$1.prototype.then = then;
        Promise$1.all = all;
        Promise$1.race = race;
        Promise$1.resolve = resolve$1;
        Promise$1.reject = reject$1;
        Promise$1._setScheduler = setScheduler;
        Promise$1._setAsap = setAsap;
        Promise$1._asap = asap;
        function polyfill() {
          var local = void 0;
          if (typeof global !== 'undefined') {
            local = global;
          } else if (typeof self !== 'undefined') {
            local = self;
          } else {
            try {
              local = Function('return this')();
            } catch (e) {
              throw new Error('polyfill failed because global object is unavailable in this environment');
            }
          }
          var P = local.Promise;
          if (P) {
            var promiseToString = null;
            try {
              promiseToString = Object.prototype.toString.call(P.resolve());
            } catch (e) {}
            if (promiseToString === '[object Promise]' && !P.cast) {
              return;
            }
          }
          local.Promise = Promise$1;
        }
        Promise$1.polyfill = polyfill;
        Promise$1.Promise = Promise$1;
        return Promise$1;
      });
    });
    var require_typedarray = __commonJS(function(exports) {
      var undefined2 = void 0;
      var MAX_ARRAY_LENGTH = 1e5;
      var ECMAScript = function() {
        var opts = Object.prototype.toString, ophop = Object.prototype.hasOwnProperty;
        return {
          Class: function Class(v) {
            return opts.call(v).replace(/^\[object *|\]$/g, '');
          },
          HasProperty: function HasProperty(o, p) {
            return p in o;
          },
          HasOwnProperty: function HasOwnProperty(o, p) {
            return ophop.call(o, p);
          },
          IsCallable: function IsCallable(o) {
            return typeof o === 'function';
          },
          ToInt32: function ToInt32(v) {
            return v >> 0;
          },
          ToUint32: function ToUint32(v) {
            return v >>> 0;
          }
        };
      }();
      var LN2 = Math.LN2;
      var abs = Math.abs;
      var floor = Math.floor;
      var log10 = Math.log;
      var min = Math.min;
      var pow = Math.pow;
      var round = Math.round;
      function configureProperties(obj) {
        if (getOwnPropNames && defineProp) {
          var props = getOwnPropNames(obj), i;
          for (i = 0; i < props.length; i += 1) {
            defineProp(obj, props[i], {
              value: obj[props[i]],
              writable: false,
              enumerable: false,
              configurable: false
            });
          }
        }
      }
      var defineProp;
      if (Object.defineProperty && function() {
        try {
          Object.defineProperty({}, 'x', {});
          return true;
        } catch (e) {
          return false;
        }
      }()) {
        defineProp = Object.defineProperty;
      } else {
        defineProp = function defineProp(o, p, desc) {
          if (!o === Object(o)) {
            throw new TypeError('Object.defineProperty called on non-object');
          }
          if (ECMAScript.HasProperty(desc, 'get') && Object.prototype.__defineGetter__) {
            Object.prototype.__defineGetter__.call(o, p, desc.get);
          }
          if (ECMAScript.HasProperty(desc, 'set') && Object.prototype.__defineSetter__) {
            Object.prototype.__defineSetter__.call(o, p, desc.set);
          }
          if (ECMAScript.HasProperty(desc, 'value')) {
            o[p] = desc.value;
          }
          return o;
        };
      }
      var getOwnPropNames = Object.getOwnPropertyNames || function(o) {
        if (o !== Object(o)) {
          throw new TypeError('Object.getOwnPropertyNames called on non-object');
        }
        var props = [], p;
        for (p in o) {
          if (ECMAScript.HasOwnProperty(o, p)) {
            props.push(p);
          }
        }
        return props;
      };
      function makeArrayAccessors(obj) {
        if (!defineProp) {
          return;
        }
        if (obj.length > MAX_ARRAY_LENGTH) {
          throw new RangeError('Array too large for polyfill');
        }
        function makeArrayAccessor(index) {
          defineProp(obj, index, {
            get: function get() {
              return obj._getter(index);
            },
            set: function set(v) {
              obj._setter(index, v);
            },
            enumerable: true,
            configurable: false
          });
        }
        var i;
        for (i = 0; i < obj.length; i += 1) {
          makeArrayAccessor(i);
        }
      }
      function as_signed(value, bits) {
        var s = 32 - bits;
        return value << s >> s;
      }
      function as_unsigned(value, bits) {
        var s = 32 - bits;
        return value << s >>> s;
      }
      function packI8(n) {
        return [ n & 255 ];
      }
      function unpackI8(bytes) {
        return as_signed(bytes[0], 8);
      }
      function packU8(n) {
        return [ n & 255 ];
      }
      function unpackU8(bytes) {
        return as_unsigned(bytes[0], 8);
      }
      function packU8Clamped(n) {
        n = round(Number(n));
        return [ n < 0 ? 0 : n > 255 ? 255 : n & 255 ];
      }
      function packI16(n) {
        return [ n >> 8 & 255, n & 255 ];
      }
      function unpackI16(bytes) {
        return as_signed(bytes[0] << 8 | bytes[1], 16);
      }
      function packU16(n) {
        return [ n >> 8 & 255, n & 255 ];
      }
      function unpackU16(bytes) {
        return as_unsigned(bytes[0] << 8 | bytes[1], 16);
      }
      function packI32(n) {
        return [ n >> 24 & 255, n >> 16 & 255, n >> 8 & 255, n & 255 ];
      }
      function unpackI32(bytes) {
        return as_signed(bytes[0] << 24 | bytes[1] << 16 | bytes[2] << 8 | bytes[3], 32);
      }
      function packU32(n) {
        return [ n >> 24 & 255, n >> 16 & 255, n >> 8 & 255, n & 255 ];
      }
      function unpackU32(bytes) {
        return as_unsigned(bytes[0] << 24 | bytes[1] << 16 | bytes[2] << 8 | bytes[3], 32);
      }
      function packIEEE754(v, ebits, fbits) {
        var bias = (1 << ebits - 1) - 1, s, e, f, ln, i, bits, str, bytes;
        function roundToEven(n) {
          var w = floor(n), f2 = n - w;
          if (f2 < .5) {
            return w;
          }
          if (f2 > .5) {
            return w + 1;
          }
          return w % 2 ? w + 1 : w;
        }
        if (v !== v) {
          e = (1 << ebits) - 1;
          f = pow(2, fbits - 1);
          s = 0;
        } else if (v === Infinity || v === -Infinity) {
          e = (1 << ebits) - 1;
          f = 0;
          s = v < 0 ? 1 : 0;
        } else if (v === 0) {
          e = 0;
          f = 0;
          s = 1 / v === -Infinity ? 1 : 0;
        } else {
          s = v < 0;
          v = abs(v);
          if (v >= pow(2, 1 - bias)) {
            e = min(floor(log10(v) / LN2), 1023);
            f = roundToEven(v / pow(2, e) * pow(2, fbits));
            if (f / pow(2, fbits) >= 2) {
              e = e + 1;
              f = 1;
            }
            if (e > bias) {
              e = (1 << ebits) - 1;
              f = 0;
            } else {
              e = e + bias;
              f = f - pow(2, fbits);
            }
          } else {
            e = 0;
            f = roundToEven(v / pow(2, 1 - bias - fbits));
          }
        }
        bits = [];
        for (i = fbits; i; i -= 1) {
          bits.push(f % 2 ? 1 : 0);
          f = floor(f / 2);
        }
        for (i = ebits; i; i -= 1) {
          bits.push(e % 2 ? 1 : 0);
          e = floor(e / 2);
        }
        bits.push(s ? 1 : 0);
        bits.reverse();
        str = bits.join('');
        bytes = [];
        while (str.length) {
          bytes.push(parseInt(str.substring(0, 8), 2));
          str = str.substring(8);
        }
        return bytes;
      }
      function unpackIEEE754(bytes, ebits, fbits) {
        var bits = [], i, j, b, str, bias, s, e, f;
        for (i = bytes.length; i; i -= 1) {
          b = bytes[i - 1];
          for (j = 8; j; j -= 1) {
            bits.push(b % 2 ? 1 : 0);
            b = b >> 1;
          }
        }
        bits.reverse();
        str = bits.join('');
        bias = (1 << ebits - 1) - 1;
        s = parseInt(str.substring(0, 1), 2) ? -1 : 1;
        e = parseInt(str.substring(1, 1 + ebits), 2);
        f = parseInt(str.substring(1 + ebits), 2);
        if (e === (1 << ebits) - 1) {
          return f !== 0 ? NaN : s * Infinity;
        } else if (e > 0) {
          return s * pow(2, e - bias) * (1 + f / pow(2, fbits));
        } else if (f !== 0) {
          return s * pow(2, -(bias - 1)) * (f / pow(2, fbits));
        } else {
          return s < 0 ? -0 : 0;
        }
      }
      function unpackF64(b) {
        return unpackIEEE754(b, 11, 52);
      }
      function packF64(v) {
        return packIEEE754(v, 11, 52);
      }
      function unpackF32(b) {
        return unpackIEEE754(b, 8, 23);
      }
      function packF32(v) {
        return packIEEE754(v, 8, 23);
      }
      (function() {
        var ArrayBuffer = function ArrayBuffer2(length) {
          length = ECMAScript.ToInt32(length);
          if (length < 0) {
            throw new RangeError('ArrayBuffer size is not a small enough positive integer');
          }
          this.byteLength = length;
          this._bytes = [];
          this._bytes.length = length;
          var i;
          for (i = 0; i < this.byteLength; i += 1) {
            this._bytes[i] = 0;
          }
          configureProperties(this);
        };
        exports.ArrayBuffer = exports.ArrayBuffer || ArrayBuffer;
        var ArrayBufferView = function ArrayBufferView2() {};
        function makeConstructor(bytesPerElement, pack, unpack) {
          var _ctor;
          _ctor = function ctor(buffer, byteOffset, length) {
            var array, sequence, i, s;
            if (!arguments.length || typeof arguments[0] === 'number') {
              this.length = ECMAScript.ToInt32(arguments[0]);
              if (length < 0) {
                throw new RangeError('ArrayBufferView size is not a small enough positive integer');
              }
              this.byteLength = this.length * this.BYTES_PER_ELEMENT;
              this.buffer = new ArrayBuffer(this.byteLength);
              this.byteOffset = 0;
            } else if (_typeof(arguments[0]) === 'object' && arguments[0].constructor === _ctor) {
              array = arguments[0];
              this.length = array.length;
              this.byteLength = this.length * this.BYTES_PER_ELEMENT;
              this.buffer = new ArrayBuffer(this.byteLength);
              this.byteOffset = 0;
              for (i = 0; i < this.length; i += 1) {
                this._setter(i, array._getter(i));
              }
            } else if (_typeof(arguments[0]) === 'object' && !(arguments[0] instanceof ArrayBuffer || ECMAScript.Class(arguments[0]) === 'ArrayBuffer')) {
              sequence = arguments[0];
              this.length = ECMAScript.ToUint32(sequence.length);
              this.byteLength = this.length * this.BYTES_PER_ELEMENT;
              this.buffer = new ArrayBuffer(this.byteLength);
              this.byteOffset = 0;
              for (i = 0; i < this.length; i += 1) {
                s = sequence[i];
                this._setter(i, Number(s));
              }
            } else if (_typeof(arguments[0]) === 'object' && (arguments[0] instanceof ArrayBuffer || ECMAScript.Class(arguments[0]) === 'ArrayBuffer')) {
              this.buffer = buffer;
              this.byteOffset = ECMAScript.ToUint32(byteOffset);
              if (this.byteOffset > this.buffer.byteLength) {
                throw new RangeError('byteOffset out of range');
              }
              if (this.byteOffset % this.BYTES_PER_ELEMENT) {
                throw new RangeError('ArrayBuffer length minus the byteOffset is not a multiple of the element size.');
              }
              if (arguments.length < 3) {
                this.byteLength = this.buffer.byteLength - this.byteOffset;
                if (this.byteLength % this.BYTES_PER_ELEMENT) {
                  throw new RangeError('length of buffer minus byteOffset not a multiple of the element size');
                }
                this.length = this.byteLength / this.BYTES_PER_ELEMENT;
              } else {
                this.length = ECMAScript.ToUint32(length);
                this.byteLength = this.length * this.BYTES_PER_ELEMENT;
              }
              if (this.byteOffset + this.byteLength > this.buffer.byteLength) {
                throw new RangeError('byteOffset and length reference an area beyond the end of the buffer');
              }
            } else {
              throw new TypeError('Unexpected argument type(s)');
            }
            this.constructor = _ctor;
            configureProperties(this);
            makeArrayAccessors(this);
          };
          _ctor.prototype = new ArrayBufferView();
          _ctor.prototype.BYTES_PER_ELEMENT = bytesPerElement;
          _ctor.prototype._pack = pack;
          _ctor.prototype._unpack = unpack;
          _ctor.BYTES_PER_ELEMENT = bytesPerElement;
          _ctor.prototype._getter = function(index) {
            if (arguments.length < 1) {
              throw new SyntaxError('Not enough arguments');
            }
            index = ECMAScript.ToUint32(index);
            if (index >= this.length) {
              return undefined2;
            }
            var bytes = [], i, o;
            for (i = 0, o = this.byteOffset + index * this.BYTES_PER_ELEMENT; i < this.BYTES_PER_ELEMENT; i += 1, 
            o += 1) {
              bytes.push(this.buffer._bytes[o]);
            }
            return this._unpack(bytes);
          };
          _ctor.prototype.get = _ctor.prototype._getter;
          _ctor.prototype._setter = function(index, value) {
            if (arguments.length < 2) {
              throw new SyntaxError('Not enough arguments');
            }
            index = ECMAScript.ToUint32(index);
            if (index >= this.length) {
              return undefined2;
            }
            var bytes = this._pack(value), i, o;
            for (i = 0, o = this.byteOffset + index * this.BYTES_PER_ELEMENT; i < this.BYTES_PER_ELEMENT; i += 1, 
            o += 1) {
              this.buffer._bytes[o] = bytes[i];
            }
          };
          _ctor.prototype.set = function(index, value) {
            if (arguments.length < 1) {
              throw new SyntaxError('Not enough arguments');
            }
            var array, sequence, offset, len, i, s, d, byteOffset, byteLength, tmp;
            if (_typeof(arguments[0]) === 'object' && arguments[0].constructor === this.constructor) {
              array = arguments[0];
              offset = ECMAScript.ToUint32(arguments[1]);
              if (offset + array.length > this.length) {
                throw new RangeError('Offset plus length of array is out of range');
              }
              byteOffset = this.byteOffset + offset * this.BYTES_PER_ELEMENT;
              byteLength = array.length * this.BYTES_PER_ELEMENT;
              if (array.buffer === this.buffer) {
                tmp = [];
                for (i = 0, s = array.byteOffset; i < byteLength; i += 1, s += 1) {
                  tmp[i] = array.buffer._bytes[s];
                }
                for (i = 0, d = byteOffset; i < byteLength; i += 1, d += 1) {
                  this.buffer._bytes[d] = tmp[i];
                }
              } else {
                for (i = 0, s = array.byteOffset, d = byteOffset; i < byteLength; i += 1, s += 1, 
                d += 1) {
                  this.buffer._bytes[d] = array.buffer._bytes[s];
                }
              }
            } else if (_typeof(arguments[0]) === 'object' && typeof arguments[0].length !== 'undefined') {
              sequence = arguments[0];
              len = ECMAScript.ToUint32(sequence.length);
              offset = ECMAScript.ToUint32(arguments[1]);
              if (offset + len > this.length) {
                throw new RangeError('Offset plus length of array is out of range');
              }
              for (i = 0; i < len; i += 1) {
                s = sequence[i];
                this._setter(offset + i, Number(s));
              }
            } else {
              throw new TypeError('Unexpected argument type(s)');
            }
          };
          _ctor.prototype.subarray = function(start, end) {
            function clamp(v, min2, max) {
              return v < min2 ? min2 : v > max ? max : v;
            }
            start = ECMAScript.ToInt32(start);
            end = ECMAScript.ToInt32(end);
            if (arguments.length < 1) {
              start = 0;
            }
            if (arguments.length < 2) {
              end = this.length;
            }
            if (start < 0) {
              start = this.length + start;
            }
            if (end < 0) {
              end = this.length + end;
            }
            start = clamp(start, 0, this.length);
            end = clamp(end, 0, this.length);
            var len = end - start;
            if (len < 0) {
              len = 0;
            }
            return new this.constructor(this.buffer, this.byteOffset + start * this.BYTES_PER_ELEMENT, len);
          };
          return _ctor;
        }
        var Int8Array = makeConstructor(1, packI8, unpackI8);
        var Uint8Array2 = makeConstructor(1, packU8, unpackU8);
        var Uint8ClampedArray2 = makeConstructor(1, packU8Clamped, unpackU8);
        var Int16Array = makeConstructor(2, packI16, unpackI16);
        var Uint16Array = makeConstructor(2, packU16, unpackU16);
        var Int32Array = makeConstructor(4, packI32, unpackI32);
        var Uint32Array3 = makeConstructor(4, packU32, unpackU32);
        var Float32Array = makeConstructor(4, packF32, unpackF32);
        var Float64Array = makeConstructor(8, packF64, unpackF64);
        exports.Int8Array = exports.Int8Array || Int8Array;
        exports.Uint8Array = exports.Uint8Array || Uint8Array2;
        exports.Uint8ClampedArray = exports.Uint8ClampedArray || Uint8ClampedArray2;
        exports.Int16Array = exports.Int16Array || Int16Array;
        exports.Uint16Array = exports.Uint16Array || Uint16Array;
        exports.Int32Array = exports.Int32Array || Int32Array;
        exports.Uint32Array = exports.Uint32Array || Uint32Array3;
        exports.Float32Array = exports.Float32Array || Float32Array;
        exports.Float64Array = exports.Float64Array || Float64Array;
      })();
      (function() {
        function r(array, index) {
          return ECMAScript.IsCallable(array.get) ? array.get(index) : array[index];
        }
        var IS_BIG_ENDIAN = function() {
          var u16array = new exports.Uint16Array([ 4660 ]), u8array = new exports.Uint8Array(u16array.buffer);
          return r(u8array, 0) === 18;
        }();
        var DataView = function DataView2(buffer, byteOffset, byteLength) {
          if (arguments.length === 0) {
            buffer = new exports.ArrayBuffer(0);
          } else if (!(buffer instanceof exports.ArrayBuffer || ECMAScript.Class(buffer) === 'ArrayBuffer')) {
            throw new TypeError('TypeError');
          }
          this.buffer = buffer || new exports.ArrayBuffer(0);
          this.byteOffset = ECMAScript.ToUint32(byteOffset);
          if (this.byteOffset > this.buffer.byteLength) {
            throw new RangeError('byteOffset out of range');
          }
          if (arguments.length < 3) {
            this.byteLength = this.buffer.byteLength - this.byteOffset;
          } else {
            this.byteLength = ECMAScript.ToUint32(byteLength);
          }
          if (this.byteOffset + this.byteLength > this.buffer.byteLength) {
            throw new RangeError('byteOffset and length reference an area beyond the end of the buffer');
          }
          configureProperties(this);
        };
        function makeGetter(arrayType) {
          return function(byteOffset, littleEndian) {
            byteOffset = ECMAScript.ToUint32(byteOffset);
            if (byteOffset + arrayType.BYTES_PER_ELEMENT > this.byteLength) {
              throw new RangeError('Array index out of range');
            }
            byteOffset += this.byteOffset;
            var uint8Array = new exports.Uint8Array(this.buffer, byteOffset, arrayType.BYTES_PER_ELEMENT), bytes = [], i;
            for (i = 0; i < arrayType.BYTES_PER_ELEMENT; i += 1) {
              bytes.push(r(uint8Array, i));
            }
            if (Boolean(littleEndian) === Boolean(IS_BIG_ENDIAN)) {
              bytes.reverse();
            }
            return r(new arrayType(new exports.Uint8Array(bytes).buffer), 0);
          };
        }
        DataView.prototype.getUint8 = makeGetter(exports.Uint8Array);
        DataView.prototype.getInt8 = makeGetter(exports.Int8Array);
        DataView.prototype.getUint16 = makeGetter(exports.Uint16Array);
        DataView.prototype.getInt16 = makeGetter(exports.Int16Array);
        DataView.prototype.getUint32 = makeGetter(exports.Uint32Array);
        DataView.prototype.getInt32 = makeGetter(exports.Int32Array);
        DataView.prototype.getFloat32 = makeGetter(exports.Float32Array);
        DataView.prototype.getFloat64 = makeGetter(exports.Float64Array);
        function makeSetter(arrayType) {
          return function(byteOffset, value, littleEndian) {
            byteOffset = ECMAScript.ToUint32(byteOffset);
            if (byteOffset + arrayType.BYTES_PER_ELEMENT > this.byteLength) {
              throw new RangeError('Array index out of range');
            }
            var typeArray = new arrayType([ value ]), byteArray = new exports.Uint8Array(typeArray.buffer), bytes = [], i, byteView;
            for (i = 0; i < arrayType.BYTES_PER_ELEMENT; i += 1) {
              bytes.push(r(byteArray, i));
            }
            if (Boolean(littleEndian) === Boolean(IS_BIG_ENDIAN)) {
              bytes.reverse();
            }
            byteView = new exports.Uint8Array(this.buffer, byteOffset, arrayType.BYTES_PER_ELEMENT);
            byteView.set(bytes);
          };
        }
        DataView.prototype.setUint8 = makeSetter(exports.Uint8Array);
        DataView.prototype.setInt8 = makeSetter(exports.Int8Array);
        DataView.prototype.setUint16 = makeSetter(exports.Uint16Array);
        DataView.prototype.setInt16 = makeSetter(exports.Int16Array);
        DataView.prototype.setUint32 = makeSetter(exports.Uint32Array);
        DataView.prototype.setInt32 = makeSetter(exports.Int32Array);
        DataView.prototype.setFloat32 = makeSetter(exports.Float32Array);
        DataView.prototype.setFloat64 = makeSetter(exports.Float64Array);
        exports.DataView = exports.DataView || DataView;
      })();
    });
    var require_weakmap_polyfill = __commonJS(function(exports) {
      (function(self2) {
        'use strict';
        if (self2.WeakMap) {
          return;
        }
        var hasOwnProperty2 = Object.prototype.hasOwnProperty;
        var defineProperty = function defineProperty(object, name, value) {
          if (Object.defineProperty) {
            Object.defineProperty(object, name, {
              configurable: true,
              writable: true,
              value: value
            });
          } else {
            object[name] = value;
          }
        };
        self2.WeakMap = function() {
          function WeakMap2() {
            if (this === void 0) {
              throw new TypeError('Constructor WeakMap requires \'new\'');
            }
            defineProperty(this, '_id', genId('_WeakMap'));
            if (arguments.length > 0) {
              throw new TypeError('WeakMap iterable is not supported');
            }
          }
          defineProperty(WeakMap2.prototype, 'delete', function(key) {
            checkInstance(this, 'delete');
            if (!isObject(key)) {
              return false;
            }
            var entry = key[this._id];
            if (entry && entry[0] === key) {
              delete key[this._id];
              return true;
            }
            return false;
          });
          defineProperty(WeakMap2.prototype, 'get', function(key) {
            checkInstance(this, 'get');
            if (!isObject(key)) {
              return void 0;
            }
            var entry = key[this._id];
            if (entry && entry[0] === key) {
              return entry[1];
            }
            return void 0;
          });
          defineProperty(WeakMap2.prototype, 'has', function(key) {
            checkInstance(this, 'has');
            if (!isObject(key)) {
              return false;
            }
            var entry = key[this._id];
            if (entry && entry[0] === key) {
              return true;
            }
            return false;
          });
          defineProperty(WeakMap2.prototype, 'set', function(key, value) {
            checkInstance(this, 'set');
            if (!isObject(key)) {
              throw new TypeError('Invalid value used as weak map key');
            }
            var entry = key[this._id];
            if (entry && entry[0] === key) {
              entry[1] = value;
              return this;
            }
            defineProperty(key, this._id, [ key, value ]);
            return this;
          });
          function checkInstance(x, methodName) {
            if (!isObject(x) || !hasOwnProperty2.call(x, '_id')) {
              throw new TypeError(methodName + ' method called on incompatible receiver ' + _typeof(x));
            }
          }
          function genId(prefix) {
            return prefix + '_' + rand() + '.' + rand();
          }
          function rand() {
            return Math.random().toString().substring(2);
          }
          defineProperty(WeakMap2, '_polyfill', true);
          return WeakMap2;
        }();
        function isObject(x) {
          return Object(x) === x;
        }
      })(typeof self !== 'undefined' ? self : typeof window !== 'undefined' ? window : typeof global !== 'undefined' ? global : exports);
    });
    var definitions = [ {
      name: 'NA',
      value: 'inapplicable',
      priority: 0,
      group: 'inapplicable'
    }, {
      name: 'PASS',
      value: 'passed',
      priority: 1,
      group: 'passes'
    }, {
      name: 'CANTTELL',
      value: 'cantTell',
      priority: 2,
      group: 'incomplete'
    }, {
      name: 'FAIL',
      value: 'failed',
      priority: 3,
      group: 'violations'
    } ];
    var constants = {
      helpUrlBase: 'https://dequeuniversity.com/rules/',
      results: [],
      resultGroups: [],
      resultGroupMap: {},
      impact: Object.freeze([ 'minor', 'moderate', 'serious', 'critical' ]),
      preload: Object.freeze({
        assets: [ 'cssom', 'media' ],
        timeout: 1e4
      }),
      allOrigins: '<unsafe_all_origins>',
      sameOrigin: '<same_origin>'
    };
    definitions.forEach(function(definition) {
      var name = definition.name;
      var value = definition.value;
      var priority = definition.priority;
      var group = definition.group;
      constants[name] = value;
      constants[name + '_PRIO'] = priority;
      constants[name + '_GROUP'] = group;
      constants.results[priority] = value;
      constants.resultGroups[priority] = group;
      constants.resultGroupMap[value] = group;
    });
    Object.freeze(constants.results);
    Object.freeze(constants.resultGroups);
    Object.freeze(constants.resultGroupMap);
    Object.freeze(constants);
    var constants_default = constants;
    function log() {
      if ((typeof console === 'undefined' ? 'undefined' : _typeof(console)) === 'object' && console.log) {
        Function.prototype.apply.call(console.log, console, arguments);
      }
    }
    var log_default = log;
    var whitespaceRegex = /[\t\r\n\f]/g;
    var AbstractVirtualNode = function() {
      function AbstractVirtualNode() {
        _classCallCheck(this, AbstractVirtualNode);
        this.parent = void 0;
      }
      _createClass(AbstractVirtualNode, [ {
        key: 'attr',
        value: function attr() {
          throw new Error('VirtualNode class must have an "attr" function');
        }
      }, {
        key: 'hasAttr',
        value: function hasAttr() {
          throw new Error('VirtualNode class must have a "hasAttr" function');
        }
      }, {
        key: 'hasClass',
        value: function hasClass(className) {
          var classAttr = this.attr('class');
          if (!classAttr) {
            return false;
          }
          var selector = ' ' + className + ' ';
          return (' ' + classAttr + ' ').replace(whitespaceRegex, ' ').indexOf(selector) >= 0;
        }
      }, {
        key: 'props',
        get: function get() {
          throw new Error('VirtualNode class must have a "props" object consisting of "nodeType" and "nodeName" properties');
        }
      }, {
        key: 'attrNames',
        get: function get() {
          throw new Error('VirtualNode class must have an "attrNames" property');
        }
      } ]);
      return AbstractVirtualNode;
    }();
    var abstract_virtual_node_default = AbstractVirtualNode;
    var utils_exports = {};
    __export(utils_exports, {
      DqElement: function DqElement() {
        return dq_element_default;
      },
      aggregate: function aggregate() {
        return aggregate_default;
      },
      aggregateChecks: function aggregateChecks() {
        return aggregate_checks_default;
      },
      aggregateNodeResults: function aggregateNodeResults() {
        return aggregate_node_results_default;
      },
      aggregateResult: function aggregateResult() {
        return aggregate_result_default;
      },
      areStylesSet: function areStylesSet() {
        return are_styles_set_default;
      },
      assert: function assert() {
        return assert_default;
      },
      checkHelper: function checkHelper() {
        return check_helper_default;
      },
      clone: function clone() {
        return clone_default;
      },
      closest: function closest() {
        return closest_default;
      },
      collectResultsFromFrames: function collectResultsFromFrames() {
        return collect_results_from_frames_default;
      },
      contains: function contains() {
        return contains_default;
      },
      convertSelector: function convertSelector() {
        return _convertSelector;
      },
      cssParser: function cssParser() {
        return css_parser_default;
      },
      deepMerge: function deepMerge() {
        return deep_merge_default;
      },
      escapeSelector: function escapeSelector() {
        return escape_selector_default;
      },
      extendMetaData: function extendMetaData() {
        return extend_meta_data_default;
      },
      filterHtmlAttrs: function filterHtmlAttrs() {
        return filter_html_attrs_default;
      },
      finalizeRuleResult: function finalizeRuleResult() {
        return finalize_result_default;
      },
      findBy: function findBy() {
        return find_by_default;
      },
      getAllChecks: function getAllChecks() {
        return get_all_checks_default;
      },
      getAncestry: function getAncestry() {
        return _getAncestry;
      },
      getBaseLang: function getBaseLang() {
        return get_base_lang_default;
      },
      getCheckMessage: function getCheckMessage() {
        return get_check_message_default;
      },
      getCheckOption: function getCheckOption() {
        return get_check_option_default;
      },
      getFlattenedTree: function getFlattenedTree() {
        return get_flattened_tree_default;
      },
      getFriendlyUriEnd: function getFriendlyUriEnd() {
        return get_friendly_uri_end_default;
      },
      getNodeAttributes: function getNodeAttributes() {
        return get_node_attributes_default;
      },
      getNodeFromTree: function getNodeFromTree() {
        return get_node_from_tree_default;
      },
      getPreloadConfig: function getPreloadConfig() {
        return _getPreloadConfig;
      },
      getRootNode: function getRootNode() {
        return get_root_node_default;
      },
      getRule: function getRule() {
        return get_rule_default;
      },
      getScroll: function getScroll() {
        return get_scroll_default;
      },
      getScrollState: function getScrollState() {
        return get_scroll_state_default;
      },
      getSelector: function getSelector() {
        return _getSelector;
      },
      getSelectorData: function getSelectorData() {
        return _getSelectorData;
      },
      getShadowSelector: function getShadowSelector() {
        return get_shadow_selector_default;
      },
      getStyleSheetFactory: function getStyleSheetFactory() {
        return get_stylesheet_factory_default;
      },
      getXpath: function getXpath() {
        return get_xpath_default;
      },
      injectStyle: function injectStyle() {
        return inject_style_default;
      },
      isHidden: function isHidden() {
        return is_hidden_default;
      },
      isHtmlElement: function isHtmlElement() {
        return is_html_element_default;
      },
      isNodeInContext: function isNodeInContext() {
        return is_node_in_context_default;
      },
      isShadowRoot: function isShadowRoot() {
        return is_shadow_root_default;
      },
      isValidLang: function isValidLang() {
        return valid_langs_default;
      },
      isXHTML: function isXHTML() {
        return is_xhtml_default;
      },
      matches: function matches() {
        return matches_default;
      },
      matchesExpression: function matchesExpression() {
        return _matchesExpression;
      },
      matchesSelector: function matchesSelector() {
        return element_matches_default;
      },
      memoize: function memoize() {
        return memoize_default;
      },
      mergeResults: function mergeResults() {
        return merge_results_default;
      },
      nodeSorter: function nodeSorter() {
        return node_sorter_default;
      },
      parseCrossOriginStylesheet: function parseCrossOriginStylesheet() {
        return parse_crossorigin_stylesheet_default;
      },
      parseSameOriginStylesheet: function parseSameOriginStylesheet() {
        return parse_sameorigin_stylesheet_default;
      },
      parseStylesheet: function parseStylesheet() {
        return parse_stylesheet_default;
      },
      performanceTimer: function performanceTimer() {
        return performance_timer_default;
      },
      pollyfillElementsFromPoint: function pollyfillElementsFromPoint() {
        return _pollyfillElementsFromPoint;
      },
      preload: function preload() {
        return preload_default;
      },
      preloadCssom: function preloadCssom() {
        return preload_cssom_default;
      },
      preloadMedia: function preloadMedia() {
        return preload_media_default;
      },
      processMessage: function processMessage() {
        return process_message_default;
      },
      publishMetaData: function publishMetaData() {
        return publish_metadata_default;
      },
      querySelectorAll: function querySelectorAll() {
        return query_selector_all_default;
      },
      querySelectorAllFilter: function querySelectorAllFilter() {
        return query_selector_all_filter_default;
      },
      queue: function queue() {
        return queue_default;
      },
      respondable: function respondable() {
        return _respondable;
      },
      ruleShouldRun: function ruleShouldRun() {
        return rule_should_run_default;
      },
      select: function select() {
        return select_default;
      },
      sendCommandToFrame: function sendCommandToFrame() {
        return send_command_to_frame_default;
      },
      setScrollState: function setScrollState() {
        return set_scroll_state_default;
      },
      shouldPreload: function shouldPreload() {
        return _shouldPreload;
      },
      toArray: function toArray() {
        return to_array_default;
      },
      tokenList: function tokenList() {
        return token_list_default;
      },
      uniqueArray: function uniqueArray() {
        return unique_array_default;
      },
      uuid: function uuid() {
        return uuid_default;
      },
      validInputTypes: function validInputTypes() {
        return valid_input_type_default;
      },
      validLangs: function validLangs() {
        return _validLangs;
      }
    });
    var errorTypes = Object.freeze([ 'EvalError', 'RangeError', 'ReferenceError', 'SyntaxError', 'TypeError', 'URIError' ]);
    function stringifyMessage(_ref) {
      var topic = _ref.topic, channelId = _ref.channelId, message = _ref.message, messageId = _ref.messageId, keepalive = _ref.keepalive;
      var data2 = {
        channelId: channelId,
        topic: topic,
        messageId: messageId,
        keepalive: !!keepalive,
        source: getSource()
      };
      if (message instanceof Error) {
        data2.error = {
          name: message.name,
          message: message.message,
          stack: message.stack
        };
      } else {
        data2.payload = message;
      }
      return JSON.stringify(data2);
    }
    function parseMessage(dataString) {
      var data2;
      try {
        data2 = JSON.parse(dataString);
      } catch (e) {
        return;
      }
      if (!isRespondableMessage(data2)) {
        return;
      }
      var _data = data2, topic = _data.topic, channelId = _data.channelId, messageId = _data.messageId, keepalive = _data.keepalive;
      var message = _typeof(data2.error) === 'object' ? buildErrorObject(data2.error) : data2.payload;
      return {
        topic: topic,
        message: message,
        messageId: messageId,
        channelId: channelId,
        keepalive: !!keepalive
      };
    }
    function isRespondableMessage(postedMessage) {
      return _typeof(postedMessage) === 'object' && typeof postedMessage.channelId === 'string' && postedMessage.source === getSource();
    }
    function buildErrorObject(error) {
      var msg = error.message || 'Unknown error occurred';
      var errorName = errorTypes.includes(error.name) ? error.name : 'Error';
      var ErrConstructor = window[errorName] || Error;
      if (error.stack) {
        msg += '\n' + error.stack.replace(error.message, '');
      }
      return new ErrConstructor(msg);
    }
    function getSource() {
      var application = 'axeAPI';
      var version = '';
      if (typeof axe !== 'undefined' && axe._audit && axe._audit.application) {
        application = axe._audit.application;
      }
      if (typeof axe !== 'undefined') {
        version = axe.version;
      }
      return application + '.' + version;
    }
    function assert(bool, message) {
      if (!bool) {
        throw new Error(message);
      }
    }
    var assert_default = assert;
    function assertIsParentWindow(win) {
      assetNotGlobalWindow(win);
      assert_default(window.parent === win, 'Source of the response must be the parent window.');
    }
    function assertIsFrameWindow(win) {
      assetNotGlobalWindow(win);
      assert_default(win.parent === window, 'Respondable target must be a frame in the current window');
    }
    function assetNotGlobalWindow(win) {
      assert_default(window !== win, 'Messages can not be sent to the same window.');
    }
    var channels = {};
    function storeReplyHandler(channelId, replyHandler) {
      var sendToParent = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : true;
      assert_default(!channels[channelId], 'A replyHandler already exists for this message channel.');
      channels[channelId] = {
        replyHandler: replyHandler,
        sendToParent: sendToParent
      };
    }
    function getReplyHandler(topic) {
      return channels[topic];
    }
    function deleteReplyHandler(channelId) {
      delete channels[channelId];
    }
    var uuid;
    var _rng;
    var _crypto = window.crypto || window.msCrypto;
    if (!_rng && _crypto && _crypto.getRandomValues) {
      var _rnds8 = new Uint8Array(16);
      _rng = function whatwgRNG() {
        _crypto.getRandomValues(_rnds8);
        return _rnds8;
      };
    }
    try {
      if (!_rng) {
        var nodeCrypto = require('crypto');
        _rng = function _rng() {
          return nodeCrypto.randomBytes(16);
        };
      }
    } catch (e) {}
    if (!_rng) {
      var _rnds = new Array(16);
      _rng = function _rng() {
        for (var i = 0, r; i < 16; i++) {
          if ((i & 3) === 0) {
            r = Math.random() * 4294967296;
          }
          _rnds[i] = r >>> ((i & 3) << 3) & 255;
        }
        return _rnds;
      };
    }
    var BufferClass = typeof window.Buffer == 'function' ? window.Buffer : Array;
    var _byteToHex = [];
    var _hexToByte = {};
    for (var i = 0; i < 256; i++) {
      _byteToHex[i] = (i + 256).toString(16).substr(1);
      _hexToByte[_byteToHex[i]] = i;
    }
    function parse(s, buf, offset) {
      var i = buf && offset || 0, ii = 0;
      buf = buf || [];
      s.toLowerCase().replace(/[0-9a-f]{2}/g, function(oct) {
        if (ii < 16) {
          buf[i + ii++] = _hexToByte[oct];
        }
      });
      while (ii < 16) {
        buf[i + ii++] = 0;
      }
      return buf;
    }
    function unparse(buf, offset) {
      var i = offset || 0, bth = _byteToHex;
      return bth[buf[i++]] + bth[buf[i++]] + bth[buf[i++]] + bth[buf[i++]] + '-' + bth[buf[i++]] + bth[buf[i++]] + '-' + bth[buf[i++]] + bth[buf[i++]] + '-' + bth[buf[i++]] + bth[buf[i++]] + '-' + bth[buf[i++]] + bth[buf[i++]] + bth[buf[i++]] + bth[buf[i++]] + bth[buf[i++]] + bth[buf[i++]];
    }
    var _seedBytes = _rng();
    var _nodeId = [ _seedBytes[0] | 1, _seedBytes[1], _seedBytes[2], _seedBytes[3], _seedBytes[4], _seedBytes[5] ];
    var _clockseq = (_seedBytes[6] << 8 | _seedBytes[7]) & 16383;
    var _lastMSecs = 0;
    var _lastNSecs = 0;
    function v1(options, buf, offset) {
      var i = buf && offset || 0;
      var b = buf || [];
      options = options || {};
      var clockseq = options.clockseq != null ? options.clockseq : _clockseq;
      var msecs = options.msecs != null ? options.msecs : new Date().getTime();
      var nsecs = options.nsecs != null ? options.nsecs : _lastNSecs + 1;
      var dt = msecs - _lastMSecs + (nsecs - _lastNSecs) / 1e4;
      if (dt < 0 && options.clockseq == null) {
        clockseq = clockseq + 1 & 16383;
      }
      if ((dt < 0 || msecs > _lastMSecs) && options.nsecs == null) {
        nsecs = 0;
      }
      if (nsecs >= 1e4) {
        throw new Error('uuid.v1(): Can\'t create more than 10M uuids/sec');
      }
      _lastMSecs = msecs;
      _lastNSecs = nsecs;
      _clockseq = clockseq;
      msecs += 122192928e5;
      var tl = ((msecs & 268435455) * 1e4 + nsecs) % 4294967296;
      b[i++] = tl >>> 24 & 255;
      b[i++] = tl >>> 16 & 255;
      b[i++] = tl >>> 8 & 255;
      b[i++] = tl & 255;
      var tmh = msecs / 4294967296 * 1e4 & 268435455;
      b[i++] = tmh >>> 8 & 255;
      b[i++] = tmh & 255;
      b[i++] = tmh >>> 24 & 15 | 16;
      b[i++] = tmh >>> 16 & 255;
      b[i++] = clockseq >>> 8 | 128;
      b[i++] = clockseq & 255;
      var node = options.node || _nodeId;
      for (var n = 0; n < 6; n++) {
        b[i + n] = node[n];
      }
      return buf ? buf : unparse(b);
    }
    function v4(options, buf, offset) {
      var i = buf && offset || 0;
      if (typeof options == 'string') {
        buf = options == 'binary' ? new BufferClass(16) : null;
        options = null;
      }
      options = options || {};
      var rnds = options.random || (options.rng || _rng)();
      rnds[6] = rnds[6] & 15 | 64;
      rnds[8] = rnds[8] & 63 | 128;
      if (buf) {
        for (var ii = 0; ii < 16; ii++) {
          buf[i + ii] = rnds[ii];
        }
      }
      return buf || unparse(rnds);
    }
    uuid = v4;
    uuid.v1 = v1;
    uuid.v4 = v4;
    uuid.parse = parse;
    uuid.unparse = unparse;
    uuid.BufferClass = BufferClass;
    axe._uuid = v1();
    var uuid_default = v4;
    var messageIds = [];
    function createMessageId() {
      var uuid5 = ''.concat(v4(), ':').concat(v4());
      if (messageIds.includes(uuid5)) {
        return createMessageId();
      }
      messageIds.push(uuid5);
      return uuid5;
    }
    function isNewMessage(uuid5) {
      if (messageIds.includes(uuid5)) {
        return false;
      }
      messageIds.push(uuid5);
      return true;
    }
    function postMessage(win, data2, sendToParent, replyHandler) {
      if (typeof replyHandler === 'function') {
        storeReplyHandler(data2.channelId, replyHandler, sendToParent);
      }
      sendToParent ? assertIsParentWindow(win) : assertIsFrameWindow(win);
      if (data2.message instanceof Error && !sendToParent) {
        axe.log(data2.message);
        return false;
      }
      var dataString = stringifyMessage(_extends({
        messageId: createMessageId()
      }, data2));
      var allowedOrigins = axe._audit.allowedOrigins;
      if (!allowedOrigins || !allowedOrigins.length) {
        return false;
      }
      allowedOrigins.forEach(function(origin) {
        try {
          win.postMessage(dataString, origin);
        } catch (err2) {
          if (err2 instanceof win.DOMException) {
            throw new Error('allowedOrigins value "'.concat(origin, '" is not a valid origin'));
          }
          throw err2;
        }
      });
      return true;
    }
    function processError(win, error, channelId) {
      if (!win.parent !== window) {
        return axe.log(error);
      }
      try {
        postMessage(win, {
          topic: null,
          channelId: channelId,
          message: error,
          messageId: createMessageId(),
          keepalive: true
        }, true);
      } catch (err2) {
        return axe.log(err2);
      }
    }
    function createResponder(win, channelId) {
      var sendToParent = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : true;
      return function respond(message, keepalive, replyHandler) {
        var data2 = {
          channelId: channelId,
          message: message,
          keepalive: keepalive
        };
        postMessage(win, data2, sendToParent, replyHandler);
      };
    }
    function originIsAllowed(origin) {
      var allowedOrigins = axe._audit.allowedOrigins;
      return allowedOrigins && allowedOrigins.includes('*') || allowedOrigins.includes(origin);
    }
    function messageHandler(_ref2, topicHandler) {
      var origin = _ref2.origin, dataString = _ref2.data, win = _ref2.source;
      var data2 = parseMessage(dataString) || {};
      var channelId = data2.channelId, message = data2.message, messageId = data2.messageId;
      if (!originIsAllowed(origin) || !isNewMessage(messageId)) {
        return;
      }
      if (message instanceof Error && win.parent !== window) {
        axe.log(message);
        return false;
      }
      try {
        if (data2.topic) {
          var responder = createResponder(win, channelId);
          assertIsParentWindow(win);
          topicHandler(data2, responder);
        } else {
          callReplyHandler(win, data2);
        }
      } catch (error) {
        processError(win, error, channelId);
      }
    }
    function callReplyHandler(win, data2) {
      var channelId = data2.channelId, message = data2.message, keepalive = data2.keepalive;
      var _ref3 = getReplyHandler(channelId) || {}, replyHandler = _ref3.replyHandler, sendToParent = _ref3.sendToParent;
      if (!replyHandler) {
        return;
      }
      sendToParent ? assertIsParentWindow(win) : assertIsFrameWindow(win);
      var responder = createResponder(win, channelId, sendToParent);
      if (!keepalive && channelId) {
        deleteReplyHandler(channelId);
      }
      try {
        replyHandler(message, keepalive, responder);
      } catch (error) {
        axe.log(error);
        responder(error, keepalive);
      }
    }
    var frameMessenger = {
      open: function open(topicHandler) {
        if (typeof window.addEventListener !== 'function') {
          return;
        }
        var handler = function handler(messageEvent) {
          messageHandler(messageEvent, topicHandler);
        };
        window.addEventListener('message', handler, false);
        return function() {
          window.removeEventListener('message', handler, false);
        };
      },
      post: function post(win, data2, replyHandler) {
        if (typeof window.addEventListener !== 'function') {
          return false;
        }
        return postMessage(win, data2, false, replyHandler);
      }
    };
    function setDefaultFrameMessenger(respondable5) {
      respondable5.updateMessenger(frameMessenger);
    }
    function aggregate(map, values, initial) {
      values = values.slice();
      if (initial) {
        values.push(initial);
      }
      var sorting = values.map(function(val) {
        return map.indexOf(val);
      }).sort();
      return map[sorting.pop()];
    }
    var aggregate_default = aggregate;
    var CANTTELL_PRIO = constants_default.CANTTELL_PRIO, FAIL_PRIO = constants_default.FAIL_PRIO;
    var checkMap = [];
    checkMap[constants_default.PASS_PRIO] = true;
    checkMap[constants_default.CANTTELL_PRIO] = null;
    checkMap[constants_default.FAIL_PRIO] = false;
    var checkTypes = [ 'any', 'all', 'none' ];
    function anyAllNone(obj, functor) {
      return checkTypes.reduce(function(out, type) {
        out[type] = (obj[type] || []).map(function(val) {
          return functor(val, type);
        });
        return out;
      }, {});
    }
    function aggregateChecks(nodeResOriginal) {
      var nodeResult = Object.assign({}, nodeResOriginal);
      anyAllNone(nodeResult, function(check4, type) {
        var i = typeof check4.result === 'undefined' ? -1 : checkMap.indexOf(check4.result);
        check4.priority = i !== -1 ? i : constants_default.CANTTELL_PRIO;
        if (type === 'none') {
          if (check4.priority === constants_default.PASS_PRIO) {
            check4.priority = constants_default.FAIL_PRIO;
          } else if (check4.priority === constants_default.FAIL_PRIO) {
            check4.priority = constants_default.PASS_PRIO;
          }
        }
      });
      var priorities = {
        all: nodeResult.all.reduce(function(a, b) {
          return Math.max(a, b.priority);
        }, 0),
        none: nodeResult.none.reduce(function(a, b) {
          return Math.max(a, b.priority);
        }, 0),
        any: nodeResult.any.reduce(function(a, b) {
          return Math.min(a, b.priority);
        }, 4) % 4
      };
      nodeResult.priority = Math.max(priorities.all, priorities.none, priorities.any);
      var impacts = [];
      checkTypes.forEach(function(type) {
        nodeResult[type] = nodeResult[type].filter(function(check4) {
          return check4.priority === nodeResult.priority && check4.priority === priorities[type];
        });
        nodeResult[type].forEach(function(check4) {
          return impacts.push(check4.impact);
        });
      });
      if ([ CANTTELL_PRIO, FAIL_PRIO ].includes(nodeResult.priority)) {
        nodeResult.impact = aggregate_default(constants_default.impact, impacts);
      } else {
        nodeResult.impact = null;
      }
      anyAllNone(nodeResult, function(c) {
        delete c.result;
        delete c.priority;
      });
      nodeResult.result = constants_default.results[nodeResult.priority];
      delete nodeResult.priority;
      return nodeResult;
    }
    var aggregate_checks_default = aggregateChecks;
    function finalizeRuleResult(ruleResult) {
      var rule3 = axe._audit.rules.find(function(rule4) {
        return rule4.id === ruleResult.id;
      });
      if (rule3 && rule3.impact) {
        ruleResult.nodes.forEach(function(node) {
          [ 'any', 'all', 'none' ].forEach(function(checkType) {
            (node[checkType] || []).forEach(function(checkResult) {
              checkResult.impact = rule3.impact;
            });
          });
        });
      }
      Object.assign(ruleResult, aggregate_node_results_default(ruleResult.nodes));
      delete ruleResult.nodes;
      return ruleResult;
    }
    var finalize_result_default = finalizeRuleResult;
    function aggregateNodeResults(nodeResults) {
      var ruleResult = {};
      nodeResults = nodeResults.map(function(nodeResult) {
        if (nodeResult.any && nodeResult.all && nodeResult.none) {
          return aggregate_checks_default(nodeResult);
        } else if (Array.isArray(nodeResult.node)) {
          return finalize_result_default(nodeResult);
        } else {
          throw new TypeError('Invalid Result type');
        }
      });
      if (nodeResults && nodeResults.length) {
        var resultList = nodeResults.map(function(node) {
          return node.result;
        });
        ruleResult.result = aggregate_default(constants_default.results, resultList, ruleResult.result);
      } else {
        ruleResult.result = 'inapplicable';
      }
      constants_default.resultGroups.forEach(function(group) {
        return ruleResult[group] = [];
      });
      nodeResults.forEach(function(nodeResult) {
        var groupName = constants_default.resultGroupMap[nodeResult.result];
        ruleResult[groupName].push(nodeResult);
      });
      var impactGroup = constants_default.FAIL_GROUP;
      if (ruleResult[impactGroup].length === 0) {
        impactGroup = constants_default.CANTTELL_GROUP;
      }
      if (ruleResult[impactGroup].length > 0) {
        var impactList = ruleResult[impactGroup].map(function(failure) {
          return failure.impact;
        });
        ruleResult.impact = aggregate_default(constants_default.impact, impactList) || null;
      } else {
        ruleResult.impact = null;
      }
      return ruleResult;
    }
    var aggregate_node_results_default = aggregateNodeResults;
    function copyToGroup(resultObject, subResult, group) {
      var resultCopy = Object.assign({}, subResult);
      resultCopy.nodes = (resultCopy[group] || []).concat();
      constants_default.resultGroups.forEach(function(group2) {
        delete resultCopy[group2];
      });
      resultObject[group].push(resultCopy);
    }
    function aggregateResult(results) {
      var resultObject = {};
      constants_default.resultGroups.forEach(function(groupName) {
        return resultObject[groupName] = [];
      });
      results.forEach(function(subResult) {
        if (subResult.error) {
          copyToGroup(resultObject, subResult, constants_default.CANTTELL_GROUP);
        } else if (subResult.result === constants_default.NA) {
          copyToGroup(resultObject, subResult, constants_default.NA_GROUP);
        } else {
          constants_default.resultGroups.forEach(function(group) {
            if (Array.isArray(subResult[group]) && subResult[group].length > 0) {
              copyToGroup(resultObject, subResult, group);
            }
          });
        }
      });
      return resultObject;
    }
    var aggregate_result_default = aggregateResult;
    function areStylesSet(el, styles, stopAt) {
      var styl = window.getComputedStyle(el, null);
      if (!styl) {
        return false;
      }
      for (var i = 0; i < styles.length; ++i) {
        var att = styles[i];
        if (styl.getPropertyValue(att.property) === att.value) {
          return true;
        }
      }
      if (!el.parentNode || el.nodeName.toUpperCase() === stopAt.toUpperCase()) {
        return false;
      }
      return areStylesSet(el.parentNode, styles, stopAt);
    }
    var are_styles_set_default = areStylesSet;
    function toArray(thing) {
      return Array.prototype.slice.call(thing);
    }
    var to_array_default = toArray;
    function escapeSelector(value) {
      var string = String(value);
      var length = string.length;
      var index = -1;
      var codeUnit;
      var result = '';
      var firstCodeUnit = string.charCodeAt(0);
      while (++index < length) {
        codeUnit = string.charCodeAt(index);
        if (codeUnit == 0) {
          result += '\ufffd';
          continue;
        }
        if (codeUnit >= 1 && codeUnit <= 31 || codeUnit == 127 || index == 0 && codeUnit >= 48 && codeUnit <= 57 || index == 1 && codeUnit >= 48 && codeUnit <= 57 && firstCodeUnit == 45) {
          result += '\\' + codeUnit.toString(16) + ' ';
          continue;
        }
        if (index == 0 && length == 1 && codeUnit == 45) {
          result += '\\' + string.charAt(index);
          continue;
        }
        if (codeUnit >= 128 || codeUnit == 45 || codeUnit == 95 || codeUnit >= 48 && codeUnit <= 57 || codeUnit >= 65 && codeUnit <= 90 || codeUnit >= 97 && codeUnit <= 122) {
          result += string.charAt(index);
          continue;
        }
        result += '\\' + string.charAt(index);
      }
      return result;
    }
    var escape_selector_default = escapeSelector;
    function isMostlyNumbers() {
      var str = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : '';
      return str.length !== 0 && (str.match(/[0-9]/g) || '').length >= str.length / 2;
    }
    function splitString(str, splitIndex) {
      return [ str.substring(0, splitIndex), str.substring(splitIndex) ];
    }
    function trimRight(str) {
      return str.replace(/\s+$/, '');
    }
    function uriParser(url) {
      var original = url;
      var protocol = '', domain = '', port = '', path = '', query = '', hash = '';
      if (url.includes('#')) {
        var _splitString = splitString(url, url.indexOf('#'));
        var _splitString2 = _slicedToArray(_splitString, 2);
        url = _splitString2[0];
        hash = _splitString2[1];
      }
      if (url.includes('?')) {
        var _splitString3 = splitString(url, url.indexOf('?'));
        var _splitString4 = _slicedToArray(_splitString3, 2);
        url = _splitString4[0];
        query = _splitString4[1];
      }
      if (url.includes('://')) {
        var _url$split = url.split('://');
        var _url$split2 = _slicedToArray(_url$split, 2);
        protocol = _url$split2[0];
        url = _url$split2[1];
        var _splitString5 = splitString(url, url.indexOf('/'));
        var _splitString6 = _slicedToArray(_splitString5, 2);
        domain = _splitString6[0];
        url = _splitString6[1];
      } else if (url.substr(0, 2) === '//') {
        url = url.substr(2);
        var _splitString7 = splitString(url, url.indexOf('/'));
        var _splitString8 = _slicedToArray(_splitString7, 2);
        domain = _splitString8[0];
        url = _splitString8[1];
      }
      if (domain.substr(0, 4) === 'www.') {
        domain = domain.substr(4);
      }
      if (domain && domain.includes(':')) {
        var _splitString9 = splitString(domain, domain.indexOf(':'));
        var _splitString10 = _slicedToArray(_splitString9, 2);
        domain = _splitString10[0];
        port = _splitString10[1];
      }
      path = url;
      return {
        original: original,
        protocol: protocol,
        domain: domain,
        port: port,
        path: path,
        query: query,
        hash: hash
      };
    }
    function getFriendlyUriEnd() {
      var uri = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : '';
      var options = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : {};
      if (uri.length <= 1 || uri.substr(0, 5) === 'data:' || uri.substr(0, 11) === 'javascript:' || uri.includes('?')) {
        return;
      }
      var currentDomain = options.currentDomain, _options$maxLength = options.maxLength, maxLength = _options$maxLength === void 0 ? 25 : _options$maxLength;
      var _uriParser = uriParser(uri), path = _uriParser.path, domain = _uriParser.domain, hash = _uriParser.hash;
      var pathEnd = path.substr(path.substr(0, path.length - 2).lastIndexOf('/') + 1);
      if (hash) {
        if (pathEnd && (pathEnd + hash).length <= maxLength) {
          return trimRight(pathEnd + hash);
        } else if (pathEnd.length < 2 && hash.length > 2 && hash.length <= maxLength) {
          return trimRight(hash);
        } else {
          return;
        }
      } else if (domain && domain.length < maxLength && path.length <= 1) {
        return trimRight(domain + path);
      }
      if (path === '/' + pathEnd && domain && currentDomain && domain !== currentDomain && (domain + path).length <= maxLength) {
        return trimRight(domain + path);
      }
      var lastDotIndex = pathEnd.lastIndexOf('.');
      if ((lastDotIndex === -1 || lastDotIndex > 1) && (lastDotIndex !== -1 || pathEnd.length > 2) && pathEnd.length <= maxLength && !pathEnd.match(/index(\.[a-zA-Z]{2-4})?/) && !isMostlyNumbers(pathEnd)) {
        return trimRight(pathEnd);
      }
    }
    var get_friendly_uri_end_default = getFriendlyUriEnd;
    function getNodeAttributes(node) {
      if (node.attributes instanceof window.NamedNodeMap) {
        return node.attributes;
      }
      return node.cloneNode(false).attributes;
    }
    var get_node_attributes_default = getNodeAttributes;
    var matchesSelector = function() {
      var method;
      function getMethod(node) {
        var index, candidate, candidates = [ 'matches', 'matchesSelector', 'mozMatchesSelector', 'webkitMatchesSelector', 'msMatchesSelector' ], length = candidates.length;
        for (index = 0; index < length; index++) {
          candidate = candidates[index];
          if (node[candidate]) {
            return candidate;
          }
        }
      }
      return function(node, selector) {
        if (!method || !node[method]) {
          method = getMethod(node);
        }
        if (node[method]) {
          return node[method](selector);
        }
        return false;
      };
    }();
    var element_matches_default = matchesSelector;
    function isXHTML(doc) {
      if (!doc.createElement) {
        return false;
      }
      return doc.createElement('A').localName === 'A';
    }
    var is_xhtml_default = isXHTML;
    function getShadowSelector(generateSelector2, elm) {
      var options = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : {};
      if (!elm) {
        return '';
      }
      var doc = elm.getRootNode && elm.getRootNode() || document;
      if (doc.nodeType !== 11) {
        return generateSelector2(elm, options, doc);
      }
      var stack = [];
      while (doc.nodeType === 11) {
        if (!doc.host) {
          return '';
        }
        stack.unshift({
          elm: elm,
          doc: doc
        });
        elm = doc.host;
        doc = elm.getRootNode();
      }
      stack.unshift({
        elm: elm,
        doc: doc
      });
      return stack.map(function(_ref4) {
        var elm2 = _ref4.elm, doc2 = _ref4.doc;
        return generateSelector2(elm2, options, doc2);
      });
    }
    var get_shadow_selector_default = getShadowSelector;
    var xhtml;
    var ignoredAttributes = [ 'class', 'style', 'id', 'selected', 'checked', 'disabled', 'tabindex', 'aria-checked', 'aria-selected', 'aria-invalid', 'aria-activedescendant', 'aria-busy', 'aria-disabled', 'aria-expanded', 'aria-grabbed', 'aria-pressed', 'aria-valuenow' ];
    var MAXATTRIBUTELENGTH = 31;
    function getAttributeNameValue(node, at) {
      var name = at.name;
      var atnv;
      if (name.indexOf('href') !== -1 || name.indexOf('src') !== -1) {
        var friendly = get_friendly_uri_end_default(node.getAttribute(name));
        if (friendly) {
          var value = encodeURI(friendly);
          if (value) {
            atnv = escape_selector_default(at.name) + '$="' + escape_selector_default(value) + '"';
          } else {
            return;
          }
        } else {
          atnv = escape_selector_default(at.name) + '="' + escape_selector_default(node.getAttribute(name)) + '"';
        }
      } else {
        atnv = escape_selector_default(name) + '="' + escape_selector_default(at.value) + '"';
      }
      return atnv;
    }
    function countSort(a, b) {
      return a.count < b.count ? -1 : a.count === b.count ? 0 : 1;
    }
    function filterAttributes(at) {
      return !ignoredAttributes.includes(at.name) && at.name.indexOf(':') === -1 && (!at.value || at.value.length < MAXATTRIBUTELENGTH);
    }
    function _getSelectorData(domTree) {
      var data2 = {
        classes: {},
        tags: {},
        attributes: {}
      };
      domTree = Array.isArray(domTree) ? domTree : [ domTree ];
      var currentLevel = domTree.slice();
      var stack = [];
      var _loop2 = function _loop2() {
        var current = currentLevel.pop();
        var node = current.actualNode;
        if (!!node.querySelectorAll) {
          var tag = node.nodeName;
          if (data2.tags[tag]) {
            data2.tags[tag]++;
          } else {
            data2.tags[tag] = 1;
          }
          if (node.classList) {
            Array.from(node.classList).forEach(function(cl) {
              var ind = escape_selector_default(cl);
              if (data2.classes[ind]) {
                data2.classes[ind]++;
              } else {
                data2.classes[ind] = 1;
              }
            });
          }
          if (node.hasAttributes()) {
            Array.from(get_node_attributes_default(node)).filter(filterAttributes).forEach(function(at) {
              var atnv = getAttributeNameValue(node, at);
              if (atnv) {
                if (data2.attributes[atnv]) {
                  data2.attributes[atnv]++;
                } else {
                  data2.attributes[atnv] = 1;
                }
              }
            });
          }
        }
        if (current.children.length) {
          stack.push(currentLevel);
          currentLevel = current.children.slice();
        }
        while (!currentLevel.length && stack.length) {
          currentLevel = stack.pop();
        }
      };
      while (currentLevel.length) {
        _loop2();
      }
      return data2;
    }
    function uncommonClasses(node, selectorData) {
      var retVal = [];
      var classData = selectorData.classes;
      var tagData = selectorData.tags;
      if (node.classList) {
        Array.from(node.classList).forEach(function(cl) {
          var ind = escape_selector_default(cl);
          if (classData[ind] < tagData[node.nodeName]) {
            retVal.push({
              name: ind,
              count: classData[ind],
              species: 'class'
            });
          }
        });
      }
      return retVal.sort(countSort);
    }
    function getNthChildString(elm, selector) {
      var siblings = elm.parentNode && Array.from(elm.parentNode.children || '') || [];
      var hasMatchingSiblings = siblings.find(function(sibling) {
        return sibling !== elm && element_matches_default(sibling, selector);
      });
      if (hasMatchingSiblings) {
        var nthChild = 1 + siblings.indexOf(elm);
        return ':nth-child(' + nthChild + ')';
      } else {
        return '';
      }
    }
    function getElmId(elm) {
      if (!elm.getAttribute('id')) {
        return;
      }
      var doc = elm.getRootNode && elm.getRootNode() || document;
      var id = '#' + escape_selector_default(elm.getAttribute('id') || '');
      if (!id.match(/player_uid_/) && doc.querySelectorAll(id).length === 1) {
        return id;
      }
    }
    function getBaseSelector(elm) {
      if (typeof xhtml === 'undefined') {
        xhtml = is_xhtml_default(document);
      }
      return escape_selector_default(xhtml ? elm.localName : elm.nodeName.toLowerCase());
    }
    function uncommonAttributes(node, selectorData) {
      var retVal = [];
      var attData = selectorData.attributes;
      var tagData = selectorData.tags;
      if (node.hasAttributes()) {
        Array.from(get_node_attributes_default(node)).filter(filterAttributes).forEach(function(at) {
          var atnv = getAttributeNameValue(node, at);
          if (atnv && attData[atnv] < tagData[node.nodeName]) {
            retVal.push({
              name: atnv,
              count: attData[atnv],
              species: 'attribute'
            });
          }
        });
      }
      return retVal.sort(countSort);
    }
    function getThreeLeastCommonFeatures(elm, selectorData) {
      var selector = '';
      var features;
      var clss = uncommonClasses(elm, selectorData);
      var atts = uncommonAttributes(elm, selectorData);
      if (clss.length && clss[0].count === 1) {
        features = [ clss[0] ];
      } else if (atts.length && atts[0].count === 1) {
        features = [ atts[0] ];
        selector = getBaseSelector(elm);
      } else {
        features = clss.concat(atts);
        features.sort(countSort);
        features = features.slice(0, 3);
        if (!features.some(function(feat) {
          return feat.species === 'class';
        })) {
          selector = getBaseSelector(elm);
        } else {
          features.sort(function(a, b) {
            return a.species !== b.species && a.species === 'class' ? -1 : a.species === b.species ? 0 : 1;
          });
        }
      }
      return selector += features.reduce(function(val, feat) {
        switch (feat.species) {
         case 'class':
          return val + '.' + feat.name;

         case 'attribute':
          return val + '[' + feat.name + ']';
        }
        return val;
      }, '');
    }
    function generateSelector(elm, options, doc) {
      if (!axe._selectorData) {
        throw new Error('Expect axe._selectorData to be set up');
      }
      var _options$toRoot = options.toRoot, toRoot = _options$toRoot === void 0 ? false : _options$toRoot;
      var selector;
      var similar;
      do {
        var features = getElmId(elm);
        if (!features) {
          features = getThreeLeastCommonFeatures(elm, axe._selectorData);
          features += getNthChildString(elm, features);
        }
        if (selector) {
          selector = features + ' > ' + selector;
        } else {
          selector = features;
        }
        if (!similar) {
          similar = Array.from(doc.querySelectorAll(selector));
        } else {
          similar = similar.filter(function(item) {
            return element_matches_default(item, selector);
          });
        }
        elm = elm.parentElement;
      } while ((similar.length > 1 || toRoot) && elm && elm.nodeType !== 11);
      if (similar.length === 1) {
        return selector;
      } else if (selector.indexOf(' > ') !== -1) {
        return ':root' + selector.substring(selector.indexOf(' > '));
      }
      return ':root';
    }
    function _getSelector(elm, options) {
      return get_shadow_selector_default(generateSelector, elm, options);
    }
    function generateAncestry(node) {
      var nodeName2 = node.nodeName.toLowerCase();
      var parent = node.parentElement;
      if (!parent) {
        return nodeName2;
      }
      var nthChild = '';
      if (nodeName2 !== 'head' && nodeName2 !== 'body' && parent.children.length > 1) {
        var index = Array.prototype.indexOf.call(parent.children, node) + 1;
        nthChild = ':nth-child('.concat(index, ')');
      }
      return generateAncestry(parent) + ' > ' + nodeName2 + nthChild;
    }
    function _getAncestry(elm, options) {
      return get_shadow_selector_default(generateAncestry, elm, options);
    }
    function getXPathArray(node, path) {
      var sibling, count;
      if (!node) {
        return [];
      }
      if (!path && node.nodeType === 9) {
        path = [ {
          str: 'html'
        } ];
        return path;
      }
      path = path || [];
      if (node.parentNode && node.parentNode !== node) {
        path = getXPathArray(node.parentNode, path);
      }
      if (node.previousSibling) {
        count = 1;
        sibling = node.previousSibling;
        do {
          if (sibling.nodeType === 1 && sibling.nodeName === node.nodeName) {
            count++;
          }
          sibling = sibling.previousSibling;
        } while (sibling);
        if (count === 1) {
          count = null;
        }
      } else if (node.nextSibling) {
        sibling = node.nextSibling;
        do {
          if (sibling.nodeType === 1 && sibling.nodeName === node.nodeName) {
            count = 1;
            sibling = null;
          } else {
            count = null;
            sibling = sibling.previousSibling;
          }
        } while (sibling);
      }
      if (node.nodeType === 1) {
        var element = {};
        element.str = node.nodeName.toLowerCase();
        var id = node.getAttribute && escape_selector_default(node.getAttribute('id'));
        if (id && node.ownerDocument.querySelectorAll('#' + id).length === 1) {
          element.id = node.getAttribute('id');
        }
        if (count > 1) {
          element.count = count;
        }
        path.push(element);
      }
      return path;
    }
    function xpathToString(xpathArray) {
      return xpathArray.reduce(function(str, elm) {
        if (elm.id) {
          return '/'.concat(elm.str, '[@id=\'').concat(elm.id, '\']');
        } else {
          return str + '/'.concat(elm.str) + (elm.count > 0 ? '['.concat(elm.count, ']') : '');
        }
      }, '');
    }
    function getXpath(node) {
      var xpathArray = getXPathArray(node);
      return xpathToString(xpathArray);
    }
    var get_xpath_default = getXpath;
    function truncate(str, maxLength) {
      maxLength = maxLength || 300;
      if (str.length > maxLength) {
        var index = str.indexOf('>');
        str = str.substring(0, index + 1);
      }
      return str;
    }
    function getSource2(element) {
      var source = element.outerHTML;
      if (!source && typeof XMLSerializer === 'function') {
        source = new XMLSerializer().serializeToString(element);
      }
      return truncate(source || '');
    }
    function DqElement(element, options, spec) {
      this._fromFrame = !!spec;
      this.spec = spec || {};
      if (options && options.absolutePaths) {
        this._options = {
          toRoot: true
        };
      }
      if (axe._audit.noHtml) {
        this.source = null;
      } else if (this.spec.source !== void 0) {
        this.source = this.spec.source;
      } else {
        this.source = getSource2(element);
      }
      this._element = element;
    }
    DqElement.prototype = {
      get selector() {
        return this.spec.selector || [ _getSelector(this.element, this._options) ];
      },
      get ancestry() {
        return this.spec.ancestry || [ _getAncestry(this.element) ];
      },
      get xpath() {
        return this.spec.xpath || [ get_xpath_default(this.element) ];
      },
      get element() {
        return this._element;
      },
      get fromFrame() {
        return this._fromFrame;
      },
      toJSON: function toJSON() {
        return {
          selector: this.selector,
          source: this.source,
          xpath: this.xpath,
          ancestry: this.ancestry
        };
      }
    };
    DqElement.fromFrame = function fromFrame(node, options, frame) {
      var spec = _extends({}, node, {
        selector: [].concat(_toConsumableArray(frame.selector), _toConsumableArray(node.selector)),
        ancestry: [].concat(_toConsumableArray(frame.ancestry), _toConsumableArray(node.ancestry)),
        xpath: [].concat(_toConsumableArray(frame.xpath), _toConsumableArray(node.xpath))
      });
      return new DqElement(frame.element, options, spec);
    };
    var dq_element_default = DqElement;
    function checkHelper(checkResult, options, resolve, reject) {
      return {
        isAsync: false,
        async: function async() {
          this.isAsync = true;
          return function(result) {
            if (result instanceof Error === false) {
              checkResult.result = result;
              resolve(checkResult);
            } else {
              reject(result);
            }
          };
        },
        data: function data(data2) {
          checkResult.data = data2;
        },
        relatedNodes: function relatedNodes(nodes) {
          nodes = nodes instanceof window.Node ? [ nodes ] : to_array_default(nodes);
          checkResult.relatedNodes = nodes.map(function(element) {
            return new dq_element_default(element, options);
          });
        }
      };
    }
    var check_helper_default = checkHelper;
    function clone(obj) {
      var index, length, out = obj;
      if (obj !== null && _typeof(obj) === 'object') {
        if (Array.isArray(obj)) {
          out = [];
          for (index = 0, length = obj.length; index < length; index++) {
            out[index] = clone(obj[index]);
          }
        } else {
          out = {};
          for (index in obj) {
            out[index] = clone(obj[index]);
          }
        }
      }
      return out;
    }
    var clone_default = clone;
    var css_selector_parser = __toModule(require_lib());
    var parser = new css_selector_parser.CssSelectorParser();
    parser.registerSelectorPseudos('not');
    parser.registerSelectorPseudos('is');
    parser.registerNestingOperators('>');
    parser.registerAttrEqualityMods('^', '$', '*', '~');
    var css_parser_default = parser;
    function matchesTag(vNode, exp) {
      return vNode.props.nodeType === 1 && (exp.tag === '*' || vNode.props.nodeName === exp.tag);
    }
    function matchesClasses(vNode, exp) {
      return !exp.classes || exp.classes.every(function(cl) {
        return vNode.hasClass(cl.value);
      });
    }
    function matchesAttributes(vNode, exp) {
      return !exp.attributes || exp.attributes.every(function(att) {
        var nodeAtt = vNode.attr(att.key);
        return nodeAtt !== null && (!att.value || att.test(nodeAtt));
      });
    }
    function matchesId(vNode, exp) {
      return !exp.id || vNode.props.id === exp.id;
    }
    function matchesPseudos(target, exp) {
      if (!exp.pseudos || exp.pseudos.every(function(pseudo) {
        if (pseudo.name === 'not') {
          return !pseudo.expressions.some(function(expression) {
            return _matchesExpression(target, expression);
          });
        } else if (pseudo.name === 'is') {
          return pseudo.expressions.some(function(expression) {
            return _matchesExpression(target, expression);
          });
        }
        throw new Error('the pseudo selector ' + pseudo.name + ' has not yet been implemented');
      })) {
        return true;
      }
      return false;
    }
    function matchExpression(vNode, expression) {
      return matchesTag(vNode, expression) && matchesClasses(vNode, expression) && matchesAttributes(vNode, expression) && matchesId(vNode, expression) && matchesPseudos(vNode, expression);
    }
    var escapeRegExp = function() {
      var from = /(?=[\-\[\]{}()*+?.\\\^$|,#\s])/g;
      var to = '\\';
      return function(string) {
        return string.replace(from, to);
      };
    }();
    var reUnescape = /\\/g;
    function convertAttributes(atts) {
      if (!atts) {
        return;
      }
      return atts.map(function(att) {
        var attributeKey = att.name.replace(reUnescape, '');
        var attributeValue = (att.value || '').replace(reUnescape, '');
        var test, regexp;
        switch (att.operator) {
         case '^=':
          regexp = new RegExp('^' + escapeRegExp(attributeValue));
          break;

         case '$=':
          regexp = new RegExp(escapeRegExp(attributeValue) + '$');
          break;

         case '~=':
          regexp = new RegExp('(^|\\s)' + escapeRegExp(attributeValue) + '(\\s|$)');
          break;

         case '|=':
          regexp = new RegExp('^' + escapeRegExp(attributeValue) + '(-|$)');
          break;

         case '=':
          test = function test(value) {
            return attributeValue === value;
          };
          break;

         case '*=':
          test = function test(value) {
            return value && value.includes(attributeValue);
          };
          break;

         case '!=':
          test = function test(value) {
            return attributeValue !== value;
          };
          break;

         default:
          test = function test(value) {
            return !!value;
          };
        }
        if (attributeValue === '' && /^[*$^]=$/.test(att.operator)) {
          test = function test() {
            return false;
          };
        }
        if (!test) {
          test = function test(value) {
            return value && regexp.test(value);
          };
        }
        return {
          key: attributeKey,
          value: attributeValue,
          test: test
        };
      });
    }
    function convertClasses(classes) {
      if (!classes) {
        return;
      }
      return classes.map(function(className) {
        className = className.replace(reUnescape, '');
        return {
          value: className,
          regexp: new RegExp('(^|\\s)' + escapeRegExp(className) + '(\\s|$)')
        };
      });
    }
    function convertPseudos(pseudos) {
      if (!pseudos) {
        return;
      }
      return pseudos.map(function(p) {
        var expressions;
        if ([ 'is', 'not' ].includes(p.name)) {
          expressions = p.value;
          expressions = expressions.selectors ? expressions.selectors : [ expressions ];
          expressions = convertExpressions(expressions);
        }
        return {
          name: p.name,
          expressions: expressions,
          value: p.value
        };
      });
    }
    function convertExpressions(expressions) {
      return expressions.map(function(exp) {
        var newExp = [];
        var rule3 = exp.rule;
        while (rule3) {
          newExp.push({
            tag: rule3.tagName ? rule3.tagName.toLowerCase() : '*',
            combinator: rule3.nestingOperator ? rule3.nestingOperator : ' ',
            id: rule3.id,
            attributes: convertAttributes(rule3.attrs),
            classes: convertClasses(rule3.classNames),
            pseudos: convertPseudos(rule3.pseudos)
          });
          rule3 = rule3.rule;
        }
        return newExp;
      });
    }
    function _convertSelector(selector) {
      var expressions = css_parser_default.parse(selector);
      expressions = expressions.selectors ? expressions.selectors : [ expressions ];
      return convertExpressions(expressions);
    }
    function _matchesExpression(vNode, expressions, matchAnyParent) {
      var exps = [].concat(expressions);
      var expression = exps.pop();
      var matches14 = matchExpression(vNode, expression);
      while (!matches14 && matchAnyParent && vNode.parent) {
        vNode = vNode.parent;
        matches14 = matchExpression(vNode, expression);
      }
      if (exps.length) {
        if ([ ' ', '>' ].includes(expression.combinator) === false) {
          throw new Error('axe.utils.matchesExpression does not support the combinator: ' + expression.combinator);
        }
        matches14 = matches14 && _matchesExpression(vNode.parent, exps, expression.combinator === ' ');
      }
      return matches14;
    }
    function matches(vNode, selector) {
      var expressions = _convertSelector(selector);
      return expressions.some(function(expression) {
        return _matchesExpression(vNode, expression);
      });
    }
    var matches_default = matches;
    function closest(vNode, selector) {
      while (vNode) {
        if (matches_default(vNode, selector)) {
          return vNode;
        }
        if (typeof vNode.parent === 'undefined') {
          throw new TypeError('Cannot resolve parent for non-DOM nodes');
        }
        vNode = vNode.parent;
      }
      return null;
    }
    var closest_default = closest;
    function noop() {}
    function funcGuard(f) {
      if (typeof f !== 'function') {
        throw new TypeError('Queue methods require functions as arguments');
      }
    }
    function queue() {
      var tasks = [];
      var started = 0;
      var remaining = 0;
      var completeQueue = noop;
      var complete = false;
      var err2;
      var defaultFail = function defaultFail(e) {
        err2 = e;
        setTimeout(function() {
          if (err2 !== void 0 && err2 !== null) {
            log_default('Uncaught error (of queue)', err2);
          }
        }, 1);
      };
      var failed = defaultFail;
      function createResolve(i) {
        return function(r) {
          tasks[i] = r;
          remaining -= 1;
          if (!remaining && completeQueue !== noop) {
            complete = true;
            completeQueue(tasks);
          }
        };
      }
      function abort(msg) {
        completeQueue = noop;
        failed(msg);
        return tasks;
      }
      function pop() {
        var length = tasks.length;
        for (;started < length; started++) {
          var task = tasks[started];
          try {
            task.call(null, createResolve(started), abort);
          } catch (e) {
            abort(e);
          }
        }
      }
      var q = {
        defer: function defer(fn) {
          if (_typeof(fn) === 'object' && fn.then && fn['catch']) {
            var defer = fn;
            fn = function fn(resolve, reject) {
              defer.then(resolve)['catch'](reject);
            };
          }
          funcGuard(fn);
          if (err2 !== void 0) {
            return;
          } else if (complete) {
            throw new Error('Queue already completed');
          }
          tasks.push(fn);
          ++remaining;
          pop();
          return q;
        },
        then: function then(fn) {
          funcGuard(fn);
          if (completeQueue !== noop) {
            throw new Error('queue `then` already set');
          }
          if (!err2) {
            completeQueue = fn;
            if (!remaining) {
              complete = true;
              completeQueue(tasks);
            }
          }
          return q;
        },
        catch: function _catch(fn) {
          funcGuard(fn);
          if (failed !== defaultFail) {
            throw new Error('queue `catch` already set');
          }
          if (!err2) {
            failed = fn;
          } else {
            fn(err2);
            err2 = null;
          }
          return q;
        },
        abort: abort
      };
      return q;
    }
    var queue_default = queue;
    var closeHandler;
    var postMessage2;
    var topicHandlers = {};
    function _respondable(win, topic, message, keepalive, replyHandler) {
      var data2 = {
        topic: topic,
        message: message,
        channelId: ''.concat(v4(), ':').concat(v4()),
        keepalive: keepalive
      };
      return postMessage2(win, data2, replyHandler);
    }
    function messageListener(data2, responder) {
      var topic = data2.topic, message = data2.message, keepalive = data2.keepalive;
      var topicHandler = topicHandlers[topic];
      if (!topicHandler) {
        return;
      }
      try {
        topicHandler(message, keepalive, responder);
      } catch (error) {
        axe.log(error);
        responder(error, keepalive);
      }
    }
    _respondable.updateMessenger = function updateMessenger(_ref5) {
      var open = _ref5.open, post = _ref5.post;
      assert_default(typeof open === 'function', 'open callback must be a function');
      assert_default(typeof post === 'function', 'post callback must be a function');
      if (closeHandler) {
        closeHandler();
      }
      var close = open(messageListener);
      if (close) {
        assert_default(typeof close === 'function', 'open callback must return a cleanup function');
        closeHandler = close;
      } else {
        closeHandler = null;
      }
      postMessage2 = post;
    };
    _respondable.subscribe = function subscribe(topic, topicHandler) {
      assert_default(typeof topicHandler === 'function', 'Subscriber callback must be a function');
      assert_default(!topicHandlers[topic], 'Topic '.concat(topic, ' is already registered to.'));
      topicHandlers[topic] = topicHandler;
    };
    _respondable.isInFrame = function isInFrame() {
      var win = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : window;
      return !!win.frameElement;
    };
    setDefaultFrameMessenger(_respondable);
    function err(message, node) {
      var selector;
      if (axe._tree) {
        selector = _getSelector(node);
      }
      return new Error(message + ': ' + (selector || node));
    }
    function sendCommandToFrame(node, parameters, resolve, reject) {
      var win = node.contentWindow;
      if (!win) {
        log_default('Frame does not have a content window', node);
        resolve(null);
        return;
      }
      var timeout = setTimeout(function() {
        timeout = setTimeout(function() {
          if (!parameters.debug) {
            resolve(null);
          } else {
            reject(err('No response from frame', node));
          }
        }, 0);
      }, 500);
      _respondable(win, 'axe.ping', null, void 0, function() {
        clearTimeout(timeout);
        var frameWaitTime = parameters.options && parameters.options.frameWaitTime || 6e4;
        timeout = setTimeout(function collectResultFramesTimeout() {
          reject(err('Axe in frame timed out', node));
        }, frameWaitTime);
        _respondable(win, 'axe.start', parameters, void 0, function(data2) {
          clearTimeout(timeout);
          if (data2 instanceof Error === false) {
            resolve(data2);
          } else {
            reject(data2);
          }
        });
      });
    }
    var send_command_to_frame_default = sendCommandToFrame;
    function getAllChecks(object) {
      var result = [];
      return result.concat(object.any || []).concat(object.all || []).concat(object.none || []);
    }
    var get_all_checks_default = getAllChecks;
    function nodeSorter(nodeA, nodeB) {
      nodeA = nodeA.actualNode || nodeA;
      nodeB = nodeB.actualNode || nodeB;
      if (nodeA === nodeB) {
        return 0;
      }
      if (nodeA.compareDocumentPosition(nodeB) & 4) {
        return -1;
      } else {
        return 1;
      }
    }
    var node_sorter_default = nodeSorter;
    function findBy(array, key, value) {
      if (Array.isArray(array)) {
        return array.find(function(obj) {
          return _typeof(obj) === 'object' && obj[key] === value;
        });
      }
    }
    var find_by_default = findBy;
    function pushFrame(resultSet, dqFrame, options) {
      resultSet.forEach(function(res) {
        res.node = dq_element_default.fromFrame(res.node, options, dqFrame);
        var checks = get_all_checks_default(res);
        checks.forEach(function(check4) {
          check4.relatedNodes = check4.relatedNodes.map(function(node) {
            return dq_element_default.fromFrame(node, options, dqFrame);
          });
        });
      });
    }
    function spliceNodes(target, to) {
      var firstFromFrame = to[0].node;
      for (var _i2 = 0; _i2 < target.length; _i2++) {
        var node = target[_i2].node;
        var sorterResult = node_sorter_default({
          actualNode: node.element
        }, {
          actualNode: firstFromFrame.element
        });
        if (sorterResult > 0 || sorterResult === 0 && firstFromFrame.selector.length < node.selector.length) {
          target.splice.apply(target, [ _i2, 0 ].concat(to));
          return;
        }
      }
      target.push.apply(target, to);
    }
    function normalizeResult(result) {
      if (!result || !result.results) {
        return null;
      }
      if (!Array.isArray(result.results)) {
        return [ result.results ];
      }
      if (!result.results.length) {
        return null;
      }
      return result.results;
    }
    function mergeResults(frameResults, options) {
      var mergedResult = [];
      frameResults.forEach(function(frameResult) {
        var results = normalizeResult(frameResult);
        if (!results || !results.length) {
          return;
        }
        var dqFrame;
        if (frameResult.frameElement) {
          var spec = {
            selector: [ frameResult.frame ]
          };
          dqFrame = new dq_element_default(frameResult.frameElement, options, spec);
        }
        results.forEach(function(ruleResult) {
          if (ruleResult.nodes && dqFrame) {
            pushFrame(ruleResult.nodes, dqFrame, options);
          }
          var res = find_by_default(mergedResult, 'id', ruleResult.id);
          if (!res) {
            mergedResult.push(ruleResult);
          } else {
            if (ruleResult.nodes.length) {
              spliceNodes(res.nodes, ruleResult.nodes);
            }
          }
        });
      });
      if (frameResults.length > 1 && window && window.Node) {
        mergedResult.forEach(function(result) {
          if (result.nodes) {
            result.nodes.sort(function(a, b) {
              var aNode = a.node.element;
              var bNode = b.node.element;
              if (aNode !== bNode && (a.node._fromFrame || b.node._fromFrame)) {
                return node_sorter_default(aNode, bNode);
              }
              return 0;
            });
          }
        });
      }
      return mergedResult;
    }
    var merge_results_default = mergeResults;
    function collectResultsFromFrames(parentContent, options, command, parameter, resolve, reject) {
      var q = queue_default();
      var frames = parentContent.frames;
      frames.forEach(function(frame) {
        var tabindex = parseInt(frame.node.getAttribute('tabindex'), 10);
        var focusable = isNaN(tabindex) || tabindex >= 0;
        var rect = frame.node.getBoundingClientRect();
        var width = parseInt(frame.node.getAttribute('width'), 10);
        var height = parseInt(frame.node.getAttribute('height'), 10);
        width = isNaN(width) ? rect.width : width;
        height = isNaN(height) ? rect.height : height;
        var params = {
          options: options,
          command: command,
          parameter: parameter,
          context: {
            initiator: false,
            focusable: parentContent.focusable === false ? false : focusable,
            boundingClientRect: {
              width: width,
              height: height
            },
            page: parentContent.page,
            include: frame.include || [],
            exclude: frame.exclude || []
          }
        };
        q.defer(function(res, rej) {
          var node = frame.node;
          send_command_to_frame_default(node, params, function(data2) {
            if (data2) {
              return res({
                results: data2,
                frameElement: node,
                frame: _getSelector(node)
              });
            }
            res(null);
          }, rej);
        });
      });
      q.then(function(data2) {
        resolve(merge_results_default(data2, options));
      })['catch'](reject);
    }
    var collect_results_from_frames_default = collectResultsFromFrames;
    function contains(vNode, otherVNode) {
      function containsShadowChild(vNode2, otherVNode2) {
        if (vNode2.shadowId === otherVNode2.shadowId) {
          return true;
        }
        return !!vNode2.children.find(function(child) {
          return containsShadowChild(child, otherVNode2);
        });
      }
      if (vNode.shadowId || otherVNode.shadowId) {
        return containsShadowChild(vNode, otherVNode);
      }
      if (vNode.actualNode) {
        if (typeof vNode.actualNode.contains === 'function') {
          return vNode.actualNode.contains(otherVNode.actualNode);
        }
        return !!(vNode.actualNode.compareDocumentPosition(otherVNode.actualNode) & 16);
      } else {
        do {
          if (otherVNode === vNode) {
            return true;
          }
        } while (otherVNode = otherVNode && otherVNode.parent);
      }
      return false;
    }
    var contains_default = contains;
    function deepMerge() {
      var target = {};
      for (var _len = arguments.length, sources = new Array(_len), _key = 0; _key < _len; _key++) {
        sources[_key] = arguments[_key];
      }
      sources.forEach(function(source) {
        if (!source || _typeof(source) !== 'object' || Array.isArray(source)) {
          return;
        }
        for (var _i3 = 0, _Object$keys = Object.keys(source); _i3 < _Object$keys.length; _i3++) {
          var key = _Object$keys[_i3];
          if (!target.hasOwnProperty(key) || _typeof(source[key]) !== 'object' || Array.isArray(target[key])) {
            target[key] = source[key];
          } else {
            target[key] = deepMerge(target[key], source[key]);
          }
        }
      });
      return target;
    }
    var deep_merge_default = deepMerge;
    function extendMetaData(to, from) {
      Object.assign(to, from);
      Object.keys(from).filter(function(prop) {
        return typeof from[prop] === 'function';
      }).forEach(function(prop) {
        to[prop] = null;
        try {
          to[prop] = from[prop](to);
        } catch (e) {}
      });
    }
    var extend_meta_data_default = extendMetaData;
    var possibleShadowRoots = [ 'article', 'aside', 'blockquote', 'body', 'div', 'footer', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'header', 'main', 'nav', 'p', 'section', 'span' ];
    function isShadowRoot(node) {
      if (node.shadowRoot) {
        var nodeName2 = node.nodeName.toLowerCase();
        if (possibleShadowRoots.includes(nodeName2) || /^[a-z][a-z0-9_.-]*-[a-z0-9_.-]*$/.test(nodeName2)) {
          return true;
        }
      }
      return false;
    }
    var is_shadow_root_default = isShadowRoot;
    var dom_exports = {};
    __export(dom_exports, {
      findElmsInContext: function findElmsInContext() {
        return find_elms_in_context_default;
      },
      findUp: function findUp() {
        return find_up_default;
      },
      findUpVirtual: function findUpVirtual() {
        return find_up_virtual_default;
      },
      getComposedParent: function getComposedParent() {
        return get_composed_parent_default;
      },
      getElementByReference: function getElementByReference() {
        return get_element_by_reference_default;
      },
      getElementCoordinates: function getElementCoordinates() {
        return get_element_coordinates_default;
      },
      getElementStack: function getElementStack() {
        return get_element_stack_default;
      },
      getRootNode: function getRootNode() {
        return get_root_node_default2;
      },
      getScrollOffset: function getScrollOffset() {
        return get_scroll_offset_default;
      },
      getTabbableElements: function getTabbableElements() {
        return get_tabbable_elements_default;
      },
      getTextElementStack: function getTextElementStack() {
        return get_text_element_stack_default;
      },
      getViewportSize: function getViewportSize() {
        return get_viewport_size_default;
      },
      hasContent: function hasContent() {
        return has_content_default;
      },
      hasContentVirtual: function hasContentVirtual() {
        return has_content_virtual_default;
      },
      idrefs: function idrefs() {
        return idrefs_default;
      },
      insertedIntoFocusOrder: function insertedIntoFocusOrder() {
        return inserted_into_focus_order_default;
      },
      isFocusable: function isFocusable() {
        return is_focusable_default;
      },
      isHTML5: function isHTML5() {
        return is_html5_default;
      },
      isHiddenWithCSS: function isHiddenWithCSS() {
        return is_hidden_with_css_default;
      },
      isInTextBlock: function isInTextBlock() {
        return is_in_text_block_default;
      },
      isModalOpen: function isModalOpen() {
        return is_modal_open_default;
      },
      isNativelyFocusable: function isNativelyFocusable() {
        return is_natively_focusable_default;
      },
      isNode: function isNode() {
        return is_node_default;
      },
      isOffscreen: function isOffscreen() {
        return is_offscreen_default;
      },
      isOpaque: function isOpaque() {
        return is_opaque_default;
      },
      isSkipLink: function isSkipLink() {
        return is_skip_link_default;
      },
      isVisible: function isVisible() {
        return is_visible_default;
      },
      isVisualContent: function isVisualContent() {
        return is_visual_content_default;
      },
      reduceToElementsBelowFloating: function reduceToElementsBelowFloating() {
        return reduce_to_elements_below_floating_default;
      },
      shadowElementsFromPoint: function shadowElementsFromPoint() {
        return shadow_elements_from_point_default;
      },
      urlPropsFromAttribute: function urlPropsFromAttribute() {
        return url_props_from_attribute_default;
      },
      visuallyContains: function visuallyContains() {
        return visually_contains_default;
      },
      visuallyOverlaps: function visuallyOverlaps() {
        return visually_overlaps_default;
      }
    });
    function getRootNode(node) {
      var doc = node.getRootNode && node.getRootNode() || document;
      if (doc === node) {
        doc = document;
      }
      return doc;
    }
    var get_root_node_default = getRootNode;
    var get_root_node_default2 = get_root_node_default;
    function findElmsInContext(_ref6) {
      var context3 = _ref6.context, value = _ref6.value, attr = _ref6.attr, _ref6$elm = _ref6.elm, elm = _ref6$elm === void 0 ? '' : _ref6$elm;
      var root;
      var escapedValue = escape_selector_default(value);
      if (context3.nodeType === 9 || context3.nodeType === 11) {
        root = context3;
      } else {
        root = get_root_node_default2(context3);
      }
      return Array.from(root.querySelectorAll(elm + '[' + attr + '=' + escapedValue + ']'));
    }
    var find_elms_in_context_default = findElmsInContext;
    function findUpVirtual(element, target) {
      var parent;
      parent = element.actualNode;
      if (!element.shadowId && typeof element.actualNode.closest === 'function') {
        var match = element.actualNode.closest(target);
        if (match) {
          return match;
        }
        return null;
      }
      do {
        parent = parent.assignedSlot ? parent.assignedSlot : parent.parentNode;
        if (parent && parent.nodeType === 11) {
          parent = parent.host;
        }
      } while (parent && !element_matches_default(parent, target) && parent !== document.documentElement);
      if (!parent) {
        return null;
      }
      if (!element_matches_default(parent, target)) {
        return null;
      }
      return parent;
    }
    var find_up_virtual_default = findUpVirtual;
    function findUp(element, target) {
      return find_up_virtual_default(get_node_from_tree_default(element), target);
    }
    var find_up_default = findUp;
    function getComposedParent(element) {
      if (element.assignedSlot) {
        return getComposedParent(element.assignedSlot);
      } else if (element.parentNode) {
        var parentNode = element.parentNode;
        if (parentNode.nodeType === 1) {
          return parentNode;
        } else if (parentNode.host) {
          return parentNode.host;
        }
      }
      return null;
    }
    var get_composed_parent_default = getComposedParent;
    function getElementByReference(node, attr) {
      var fragment = node.getAttribute(attr);
      if (!fragment) {
        return null;
      }
      if (fragment.charAt(0) === '#') {
        fragment = decodeURIComponent(fragment.substring(1));
      } else if (fragment.substr(0, 2) === '/#') {
        fragment = decodeURIComponent(fragment.substring(2));
      }
      var candidate = document.getElementById(fragment);
      if (candidate) {
        return candidate;
      }
      candidate = document.getElementsByName(fragment);
      if (candidate.length) {
        return candidate[0];
      }
      return null;
    }
    var get_element_by_reference_default = getElementByReference;
    function getScrollOffset(element) {
      if (!element.nodeType && element.document) {
        element = element.document;
      }
      if (element.nodeType === 9) {
        var docElement = element.documentElement, body = element.body;
        return {
          left: docElement && docElement.scrollLeft || body && body.scrollLeft || 0,
          top: docElement && docElement.scrollTop || body && body.scrollTop || 0
        };
      }
      return {
        left: element.scrollLeft,
        top: element.scrollTop
      };
    }
    var get_scroll_offset_default = getScrollOffset;
    function getElementCoordinates(element) {
      var scrollOffset = get_scroll_offset_default(document), xOffset = scrollOffset.left, yOffset = scrollOffset.top, coords = element.getBoundingClientRect();
      return {
        top: coords.top + yOffset,
        right: coords.right + xOffset,
        bottom: coords.bottom + yOffset,
        left: coords.left + xOffset,
        width: coords.right - coords.left,
        height: coords.bottom - coords.top
      };
    }
    var get_element_coordinates_default = getElementCoordinates;
    function getViewportSize(win) {
      var doc = win.document;
      var docElement = doc.documentElement;
      if (win.innerWidth) {
        return {
          width: win.innerWidth,
          height: win.innerHeight
        };
      }
      if (docElement) {
        return {
          width: docElement.clientWidth,
          height: docElement.clientHeight
        };
      }
      var body = doc.body;
      return {
        width: body.clientWidth,
        height: body.clientHeight
      };
    }
    var get_viewport_size_default = getViewportSize;
    function noParentScrolled(element, offset) {
      element = get_composed_parent_default(element);
      while (element && element.nodeName.toLowerCase() !== 'html') {
        if (element.scrollTop) {
          offset += element.scrollTop;
          if (offset >= 0) {
            return false;
          }
        }
        element = get_composed_parent_default(element);
      }
      return true;
    }
    function isOffscreen(element) {
      var leftBoundary;
      var docElement = document.documentElement;
      var styl = window.getComputedStyle(element);
      var dir = window.getComputedStyle(document.body || docElement).getPropertyValue('direction');
      var coords = get_element_coordinates_default(element);
      if (coords.bottom < 0 && (noParentScrolled(element, coords.bottom) || styl.position === 'absolute')) {
        return true;
      }
      if (coords.left === 0 && coords.right === 0) {
        return false;
      }
      if (dir === 'ltr') {
        if (coords.right <= 0) {
          return true;
        }
      } else {
        leftBoundary = Math.max(docElement.scrollWidth, get_viewport_size_default(window).width);
        if (coords.left >= leftBoundary) {
          return true;
        }
      }
      return false;
    }
    var is_offscreen_default = isOffscreen;
    var clipRegex = /rect\s*\(([0-9]+)px,?\s*([0-9]+)px,?\s*([0-9]+)px,?\s*([0-9]+)px\s*\)/;
    var clipPathRegex = /(\w+)\((\d+)/;
    function isClipped(style) {
      var matchesClip = style.getPropertyValue('clip').match(clipRegex);
      var matchesClipPath = style.getPropertyValue('clip-path').match(clipPathRegex);
      if (matchesClip && matchesClip.length === 5) {
        return matchesClip[3] - matchesClip[1] <= 0 && matchesClip[2] - matchesClip[4] <= 0;
      }
      if (matchesClipPath) {
        var type = matchesClipPath[1];
        var value = parseInt(matchesClipPath[2], 10);
        switch (type) {
         case 'inset':
          return value >= 50;

         case 'circle':
          return value === 0;

         default:
        }
      }
      return false;
    }
    function isAreaVisible(el, screenReader, recursed) {
      var mapEl = find_up_default(el, 'map');
      if (!mapEl) {
        return false;
      }
      var mapElName = mapEl.getAttribute('name');
      if (!mapElName) {
        return false;
      }
      var mapElRootNode = get_root_node_default2(el);
      if (!mapElRootNode || mapElRootNode.nodeType !== 9) {
        return false;
      }
      var refs = query_selector_all_default(axe._tree, 'img[usemap="#'.concat(escape_selector_default(mapElName), '"]'));
      if (!refs || !refs.length) {
        return false;
      }
      return refs.some(function(_ref7) {
        var actualNode = _ref7.actualNode;
        return isVisible(actualNode, screenReader, recursed);
      });
    }
    function isVisible(el, screenReader, recursed) {
      if (!el) {
        throw new TypeError('Cannot determine if element is visible for non-DOM nodes');
      }
      var vNode = get_node_from_tree_default(el);
      var cacheName = '_isVisible' + (screenReader ? 'ScreenReader' : '');
      if (el.nodeType === 9) {
        return true;
      }
      if (el.nodeType === 11) {
        el = el.host;
      }
      if (vNode && typeof vNode[cacheName] !== 'undefined') {
        return vNode[cacheName];
      }
      var style = window.getComputedStyle(el, null);
      if (style === null) {
        return false;
      }
      var nodeName2 = el.nodeName.toUpperCase();
      if (nodeName2 === 'AREA') {
        return isAreaVisible(el, screenReader, recursed);
      }
      if (style.getPropertyValue('display') === 'none' || [ 'STYLE', 'SCRIPT', 'NOSCRIPT', 'TEMPLATE' ].includes(nodeName2)) {
        return false;
      }
      if (screenReader && el.getAttribute('aria-hidden') === 'true') {
        return false;
      }
      if (!screenReader && (isClipped(style) || style.getPropertyValue('opacity') === '0' || get_scroll_default(el) && parseInt(style.getPropertyValue('height')) === 0)) {
        return false;
      }
      if (!recursed && (style.getPropertyValue('visibility') === 'hidden' || !screenReader && is_offscreen_default(el))) {
        return false;
      }
      var parent = el.assignedSlot ? el.assignedSlot : el.parentNode;
      var visible4 = false;
      if (parent) {
        visible4 = isVisible(parent, screenReader, true);
      }
      if (vNode) {
        vNode[cacheName] = visible4;
      }
      return visible4;
    }
    var is_visible_default = isVisible;
    var gridSize = 200;
    function isStackingContext(vNode, parentVNode) {
      var position = vNode.getComputedStylePropertyValue('position');
      var zIndex = vNode.getComputedStylePropertyValue('z-index');
      if (position === 'fixed' || position === 'sticky') {
        return true;
      }
      if (zIndex !== 'auto' && position !== 'static') {
        return true;
      }
      if (vNode.getComputedStylePropertyValue('opacity') !== '1') {
        return true;
      }
      var transform = vNode.getComputedStylePropertyValue('-webkit-transform') || vNode.getComputedStylePropertyValue('-ms-transform') || vNode.getComputedStylePropertyValue('transform') || 'none';
      if (transform !== 'none') {
        return true;
      }
      var mixBlendMode = vNode.getComputedStylePropertyValue('mix-blend-mode');
      if (mixBlendMode && mixBlendMode !== 'normal') {
        return true;
      }
      var filter = vNode.getComputedStylePropertyValue('filter');
      if (filter && filter !== 'none') {
        return true;
      }
      var perspective = vNode.getComputedStylePropertyValue('perspective');
      if (perspective && perspective !== 'none') {
        return true;
      }
      var clipPath = vNode.getComputedStylePropertyValue('clip-path');
      if (clipPath && clipPath !== 'none') {
        return true;
      }
      var mask = vNode.getComputedStylePropertyValue('-webkit-mask') || vNode.getComputedStylePropertyValue('mask') || 'none';
      if (mask !== 'none') {
        return true;
      }
      var maskImage = vNode.getComputedStylePropertyValue('-webkit-mask-image') || vNode.getComputedStylePropertyValue('mask-image') || 'none';
      if (maskImage !== 'none') {
        return true;
      }
      var maskBorder = vNode.getComputedStylePropertyValue('-webkit-mask-border') || vNode.getComputedStylePropertyValue('mask-border') || 'none';
      if (maskBorder !== 'none') {
        return true;
      }
      if (vNode.getComputedStylePropertyValue('isolation') === 'isolate') {
        return true;
      }
      var willChange = vNode.getComputedStylePropertyValue('will-change');
      if (willChange === 'transform' || willChange === 'opacity') {
        return true;
      }
      if (vNode.getComputedStylePropertyValue('-webkit-overflow-scrolling') === 'touch') {
        return true;
      }
      var contain = vNode.getComputedStylePropertyValue('contain');
      if ([ 'layout', 'paint', 'strict', 'content' ].includes(contain)) {
        return true;
      }
      if (zIndex !== 'auto' && parentVNode) {
        var parentDsiplay = parentVNode.getComputedStylePropertyValue('display');
        if ([ 'flex', 'inline-flex', 'inline flex', 'grid', 'inline-grid', 'inline grid' ].includes(parentDsiplay)) {
          return true;
        }
      }
      return false;
    }
    function isFloated(vNode) {
      if (!vNode) {
        return false;
      }
      if (vNode._isFloated !== void 0) {
        return vNode._isFloated;
      }
      var floatStyle = vNode.getComputedStylePropertyValue('float');
      if (floatStyle !== 'none') {
        vNode._isFloated = true;
        return true;
      }
      var floated = isFloated(vNode.parent);
      vNode._isFloated = floated;
      return floated;
    }
    function getPositionOrder(vNode) {
      if (vNode.getComputedStylePropertyValue('position') === 'static') {
        if (vNode.getComputedStylePropertyValue('display').indexOf('inline') !== -1) {
          return 2;
        }
        if (isFloated(vNode)) {
          return 1;
        }
        return 0;
      }
      return 3;
    }
    function visuallySort(a, b) {
      for (var _i4 = 0; _i4 < a._stackingOrder.length; _i4++) {
        if (typeof b._stackingOrder[_i4] === 'undefined') {
          return -1;
        }
        if (b._stackingOrder[_i4] > a._stackingOrder[_i4]) {
          return 1;
        }
        if (b._stackingOrder[_i4] < a._stackingOrder[_i4]) {
          return -1;
        }
      }
      var aNode = a.actualNode;
      var bNode = b.actualNode;
      if (aNode.getRootNode && aNode.getRootNode() !== bNode.getRootNode()) {
        var boundaries = [];
        while (aNode) {
          boundaries.push({
            root: aNode.getRootNode(),
            node: aNode
          });
          aNode = aNode.getRootNode().host;
        }
        while (bNode && !boundaries.find(function(boundary) {
          return boundary.root === bNode.getRootNode();
        })) {
          bNode = bNode.getRootNode().host;
        }
        aNode = boundaries.find(function(boundary) {
          return boundary.root === bNode.getRootNode();
        }).node;
        if (aNode === bNode) {
          return a.actualNode.getRootNode() !== aNode.getRootNode() ? -1 : 1;
        }
      }
      var _window$Node = window.Node, DOCUMENT_POSITION_FOLLOWING = _window$Node.DOCUMENT_POSITION_FOLLOWING, DOCUMENT_POSITION_CONTAINS = _window$Node.DOCUMENT_POSITION_CONTAINS, DOCUMENT_POSITION_CONTAINED_BY = _window$Node.DOCUMENT_POSITION_CONTAINED_BY;
      var docPosition = aNode.compareDocumentPosition(bNode);
      var DOMOrder = docPosition & DOCUMENT_POSITION_FOLLOWING ? 1 : -1;
      var isDescendant = docPosition & DOCUMENT_POSITION_CONTAINS || docPosition & DOCUMENT_POSITION_CONTAINED_BY;
      var aPosition = getPositionOrder(a);
      var bPosition = getPositionOrder(b);
      if (aPosition === bPosition || isDescendant) {
        return DOMOrder;
      }
      return bPosition - aPosition;
    }
    function getStackingOrder(vNode, parentVNode) {
      var stackingOrder = parentVNode._stackingOrder.slice();
      var zIndex = vNode.getComputedStylePropertyValue('z-index');
      if (zIndex !== 'auto') {
        stackingOrder[stackingOrder.length - 1] = parseInt(zIndex);
      }
      if (isStackingContext(vNode, parentVNode)) {
        stackingOrder.push(0);
      }
      return stackingOrder;
    }
    function findScrollRegionParent(vNode, parentVNode) {
      var scrollRegionParent = null;
      var checkedNodes = [ vNode ];
      while (parentVNode) {
        if (parentVNode._scrollRegionParent) {
          scrollRegionParent = parentVNode._scrollRegionParent;
          break;
        }
        if (get_scroll_default(parentVNode.actualNode)) {
          scrollRegionParent = parentVNode;
          break;
        }
        checkedNodes.push(parentVNode);
        parentVNode = get_node_from_tree_default(parentVNode.actualNode.parentElement || parentVNode.actualNode.parentNode);
      }
      checkedNodes.forEach(function(vNode2) {
        return vNode2._scrollRegionParent = scrollRegionParent;
      });
      return scrollRegionParent;
    }
    function addNodeToGrid(grid, vNode) {
      vNode._grid = grid;
      vNode.clientRects.forEach(function(rect) {
        var x = rect.left;
        var y = rect.top;
        var startRow = y / gridSize | 0;
        var startCol = x / gridSize | 0;
        var endRow = (y + rect.height) / gridSize | 0;
        var endCol = (x + rect.width) / gridSize | 0;
        for (var row = startRow; row <= endRow; row++) {
          grid.cells[row] = grid.cells[row] || [];
          for (var col = startCol; col <= endCol; col++) {
            grid.cells[row][col] = grid.cells[row][col] || [];
            if (!grid.cells[row][col].includes(vNode)) {
              grid.cells[row][col].push(vNode);
            }
          }
        }
      });
    }
    function createGrid() {
      var root = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : document.body;
      var rootGrid = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : {
        container: null,
        cells: []
      };
      var parentVNode = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : null;
      if (!parentVNode) {
        var vNode = get_node_from_tree_default(document.documentElement);
        if (!vNode) {
          vNode = new virtual_node_default(document.documentElement);
        }
        vNode._stackingOrder = [ 0 ];
        addNodeToGrid(rootGrid, vNode);
        if (get_scroll_default(vNode.actualNode)) {
          var subGrid = {
            container: vNode,
            cells: []
          };
          vNode._subGrid = subGrid;
        }
      }
      var treeWalker = document.createTreeWalker(root, window.NodeFilter.SHOW_ELEMENT, null, false);
      var node = parentVNode ? treeWalker.nextNode() : treeWalker.currentNode;
      while (node) {
        var _vNode = get_node_from_tree_default(node);
        if (node.parentElement) {
          parentVNode = get_node_from_tree_default(node.parentElement);
        } else if (node.parentNode && get_node_from_tree_default(node.parentNode)) {
          parentVNode = get_node_from_tree_default(node.parentNode);
        }
        if (!_vNode) {
          _vNode = new axe.VirtualNode(node, parentVNode);
        }
        _vNode._stackingOrder = getStackingOrder(_vNode, parentVNode);
        var scrollRegionParent = findScrollRegionParent(_vNode, parentVNode);
        var grid = scrollRegionParent ? scrollRegionParent._subGrid : rootGrid;
        if (get_scroll_default(_vNode.actualNode)) {
          var _subGrid = {
            container: _vNode,
            cells: []
          };
          _vNode._subGrid = _subGrid;
        }
        var rect = _vNode.boundingClientRect;
        if (rect.width !== 0 && rect.height !== 0 && is_visible_default(node)) {
          addNodeToGrid(grid, _vNode);
        }
        if (is_shadow_root_default(node)) {
          createGrid(node.shadowRoot, grid, _vNode);
        }
        node = treeWalker.nextNode();
      }
    }
    function getRectStack(grid, rect) {
      var recursed = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : false;
      var x = rect.left + rect.width / 2;
      var y = rect.top + rect.height / 2;
      var row = y / gridSize | 0;
      var col = x / gridSize | 0;
      var stack = grid.cells[row][col].filter(function(gridCellNode) {
        return gridCellNode.clientRects.find(function(clientRect) {
          var rectX = clientRect.left;
          var rectY = clientRect.top;
          return x <= rectX + clientRect.width && x >= rectX && y <= rectY + clientRect.height && y >= rectY;
        });
      });
      var gridContainer = grid.container;
      if (gridContainer) {
        stack = getRectStack(gridContainer._grid, gridContainer.boundingClientRect, true).concat(stack);
      }
      if (!recursed) {
        stack = stack.sort(visuallySort).map(function(vNode) {
          return vNode.actualNode;
        }).concat(document.documentElement).filter(function(node, index, array) {
          return array.indexOf(node) === index;
        });
      }
      return stack;
    }
    var _cache = {};
    var cache = {
      set: function set(key, value) {
        _cache[key] = value;
      },
      get: function get(key) {
        return _cache[key];
      },
      clear: function clear() {
        _cache = {};
      }
    };
    var cache_default = cache;
    function getElementStack(node) {
      if (!cache_default.get('gridCreated')) {
        createGrid();
        cache_default.set('gridCreated', true);
      }
      var vNode = get_node_from_tree_default(node);
      var grid = vNode._grid;
      if (!grid) {
        return [];
      }
      return getRectStack(grid, vNode.boundingClientRect);
    }
    var get_element_stack_default = getElementStack;
    function getTabbableElements(virtualNode) {
      var nodeAndDescendents = query_selector_all_default(virtualNode, '*');
      var tabbableElements = nodeAndDescendents.filter(function(vNode) {
        var isFocusable2 = vNode.isFocusable;
        var tabIndex = vNode.actualNode.getAttribute('tabindex');
        tabIndex = tabIndex && !isNaN(parseInt(tabIndex, 10)) ? parseInt(tabIndex) : null;
        return tabIndex ? isFocusable2 && tabIndex >= 0 : isFocusable2;
      });
      return tabbableElements;
    }
    var get_tabbable_elements_default = getTabbableElements;
    function sanitize(str) {
      if (!str) {
        return '';
      }
      return str.replace(/\r\n/g, '\n').replace(/\u00A0/g, ' ').replace(/[\s]{2,}/g, ' ').trim();
    }
    var sanitize_default = sanitize;
    function getTextElementStack(node) {
      if (!cache_default.get('gridCreated')) {
        createGrid();
        cache_default.set('gridCreated', true);
      }
      var vNode = get_node_from_tree_default(node);
      var grid = vNode._grid;
      if (!grid) {
        return [];
      }
      var nodeRect = vNode.boundingClientRect;
      var clientRects = [];
      Array.from(node.childNodes).forEach(function(elm) {
        if (elm.nodeType === 3 && sanitize_default(elm.textContent) !== '') {
          var range = document.createRange();
          range.selectNodeContents(elm);
          var rects = range.getClientRects();
          var outsideRectBounds = Array.from(rects).some(function(rect) {
            var horizontalMidpoint = rect.left + rect.width / 2;
            var verticalMidpoint = rect.top + rect.height / 2;
            return horizontalMidpoint < nodeRect.left || horizontalMidpoint > nodeRect.right || verticalMidpoint < nodeRect.top || verticalMidpoint > nodeRect.bottom;
          });
          if (outsideRectBounds) {
            return;
          }
          for (var _i5 = 0; _i5 < rects.length; _i5++) {
            var rect = rects[_i5];
            if (rect.width >= 1 && rect.height >= 1) {
              clientRects.push(rect);
            }
          }
        }
      });
      if (!clientRects.length) {
        return [ get_element_stack_default(node) ];
      }
      return clientRects.map(function(rect) {
        return getRectStack(grid, rect);
      });
    }
    var get_text_element_stack_default = getTextElementStack;
    var visualRoles = [ 'checkbox', 'img', 'radio', 'range', 'slider', 'spinbutton', 'textbox' ];
    function isVisualContent(element) {
      var role = element.getAttribute('role');
      if (role) {
        return visualRoles.indexOf(role) !== -1;
      }
      switch (element.nodeName.toUpperCase()) {
       case 'IMG':
       case 'IFRAME':
       case 'OBJECT':
       case 'VIDEO':
       case 'AUDIO':
       case 'CANVAS':
       case 'SVG':
       case 'MATH':
       case 'BUTTON':
       case 'SELECT':
       case 'TEXTAREA':
       case 'KEYGEN':
       case 'PROGRESS':
       case 'METER':
        return true;

       case 'INPUT':
        return element.type !== 'hidden';

       default:
        return false;
      }
    }
    var is_visual_content_default = isVisualContent;
    function idrefs(node, attr) {
      node = node.actualNode || node;
      try {
        var doc = get_root_node_default2(node);
        var result = [];
        var attrValue = node.getAttribute(attr);
        if (attrValue) {
          attrValue = token_list_default(attrValue);
          for (var index = 0; index < attrValue.length; index++) {
            result.push(doc.getElementById(attrValue[index]));
          }
        }
        return result;
      } catch (e) {
        throw new TypeError('Cannot resolve id references for non-DOM nodes');
      }
    }
    var idrefs_default = idrefs;
    function visibleVirtual(element, screenReader, noRecursing) {
      var vNode = element instanceof abstract_virtual_node_default ? element : get_node_from_tree_default(element);
      var visible4 = !element.actualNode || element.actualNode && is_visible_default(element.actualNode, screenReader);
      var result = vNode.children.map(function(child) {
        var _child$props = child.props, nodeType = _child$props.nodeType, nodeValue = _child$props.nodeValue;
        if (nodeType === 3) {
          if (nodeValue && visible4) {
            return nodeValue;
          }
        } else if (!noRecursing) {
          return visibleVirtual(child, screenReader);
        }
      }).join('');
      return sanitize_default(result);
    }
    var visible_virtual_default = visibleVirtual;
    function labelVirtual(virtualNode) {
      var ref, candidate;
      if (virtualNode.attr('aria-labelledby')) {
        ref = idrefs_default(virtualNode.actualNode, 'aria-labelledby');
        candidate = ref.map(function(thing) {
          var vNode = get_node_from_tree_default(thing);
          return vNode ? visible_virtual_default(vNode, true) : '';
        }).join(' ').trim();
        if (candidate) {
          return candidate;
        }
      }
      candidate = virtualNode.attr('aria-label');
      if (candidate) {
        candidate = sanitize_default(candidate);
        if (candidate) {
          return candidate;
        }
      }
      return null;
    }
    var label_virtual_default = labelVirtual;
    var hiddenTextElms = [ 'HEAD', 'TITLE', 'TEMPLATE', 'SCRIPT', 'STYLE', 'IFRAME', 'OBJECT', 'VIDEO', 'AUDIO', 'NOSCRIPT' ];
    function hasChildTextNodes(elm) {
      if (!hiddenTextElms.includes(elm.actualNode.nodeName.toUpperCase())) {
        return elm.children.some(function(_ref8) {
          var actualNode = _ref8.actualNode;
          return actualNode.nodeType === 3 && actualNode.nodeValue.trim();
        });
      }
    }
    function hasContentVirtual(elm, noRecursion, ignoreAria) {
      return hasChildTextNodes(elm) || is_visual_content_default(elm.actualNode) || !ignoreAria && !!label_virtual_default(elm) || !noRecursion && elm.children.some(function(child) {
        return child.actualNode.nodeType === 1 && hasContentVirtual(child);
      });
    }
    var has_content_virtual_default = hasContentVirtual;
    function hasContent(elm, noRecursion, ignoreAria) {
      elm = get_node_from_tree_default(elm);
      return has_content_virtual_default(elm, noRecursion, ignoreAria);
    }
    var has_content_default = hasContent;
    function isHiddenWithCSS(el, descendentVisibilityValue) {
      var vNode = get_node_from_tree_default(el);
      if (!vNode) {
        return _isHiddenWithCSS(el, descendentVisibilityValue);
      }
      if (vNode._isHiddenWithCSS === void 0) {
        vNode._isHiddenWithCSS = _isHiddenWithCSS(el, descendentVisibilityValue);
      }
      return vNode._isHiddenWithCSS;
    }
    function _isHiddenWithCSS(el, descendentVisibilityValue) {
      if (el.nodeType === 9) {
        return false;
      }
      if (el.nodeType === 11) {
        el = el.host;
      }
      if ([ 'STYLE', 'SCRIPT' ].includes(el.nodeName.toUpperCase())) {
        return false;
      }
      var style = window.getComputedStyle(el, null);
      if (!style) {
        throw new Error('Style does not exist for the given element.');
      }
      var displayValue = style.getPropertyValue('display');
      if (displayValue === 'none') {
        return true;
      }
      var HIDDEN_VISIBILITY_VALUES = [ 'hidden', 'collapse' ];
      var visibilityValue = style.getPropertyValue('visibility');
      if (HIDDEN_VISIBILITY_VALUES.includes(visibilityValue) && !descendentVisibilityValue) {
        return true;
      }
      if (HIDDEN_VISIBILITY_VALUES.includes(visibilityValue) && descendentVisibilityValue && HIDDEN_VISIBILITY_VALUES.includes(descendentVisibilityValue)) {
        return true;
      }
      var parent = get_composed_parent_default(el);
      if (parent && !HIDDEN_VISIBILITY_VALUES.includes(visibilityValue)) {
        return isHiddenWithCSS(parent, visibilityValue);
      }
      return false;
    }
    var is_hidden_with_css_default = isHiddenWithCSS;
    function focusDisabled(el) {
      var vNode = el instanceof abstract_virtual_node_default ? el : get_node_from_tree_default(el);
      if (vNode.hasAttr('disabled')) {
        return true;
      }
      if (vNode.props.nodeName !== 'area') {
        if (!vNode.actualNode) {
          return false;
        }
        return is_hidden_with_css_default(vNode.actualNode);
      }
      return false;
    }
    var focus_disabled_default = focusDisabled;
    function isNativelyFocusable(el) {
      var vNode = el instanceof abstract_virtual_node_default ? el : get_node_from_tree_default(el);
      if (!vNode || focus_disabled_default(vNode)) {
        return false;
      }
      switch (vNode.props.nodeName) {
       case 'a':
       case 'area':
        if (vNode.hasAttr('href')) {
          return true;
        }
        break;

       case 'input':
        return vNode.props.type !== 'hidden';

       case 'textarea':
       case 'select':
       case 'summary':
       case 'button':
        return true;

       case 'details':
        return !query_selector_all_default(vNode, 'summary').length;
      }
      return false;
    }
    var is_natively_focusable_default = isNativelyFocusable;
    function isFocusable(el) {
      var vNode = el instanceof abstract_virtual_node_default ? el : get_node_from_tree_default(el);
      if (vNode.props.nodeType !== 1) {
        return false;
      }
      if (focus_disabled_default(vNode)) {
        return false;
      } else if (is_natively_focusable_default(vNode)) {
        return true;
      }
      var tabindex = vNode.attr('tabindex');
      if (tabindex && !isNaN(parseInt(tabindex, 10))) {
        return true;
      }
      return false;
    }
    var is_focusable_default = isFocusable;
    function insertedIntoFocusOrder(el) {
      var tabIndex = parseInt(el.getAttribute('tabindex'), 10);
      return tabIndex > -1 && is_focusable_default(el) && !is_natively_focusable_default(el);
    }
    var inserted_into_focus_order_default = insertedIntoFocusOrder;
    function isHTML5(doc) {
      var node = doc.doctype;
      if (node === null) {
        return false;
      }
      return node.name === 'html' && !node.publicId && !node.systemId;
    }
    var is_html5_default = isHTML5;
    function walkDomNode(node, functor) {
      if (functor(node.actualNode) !== false) {
        node.children.forEach(function(child) {
          return walkDomNode(child, functor);
        });
      }
    }
    var blockLike = [ 'block', 'list-item', 'table', 'flex', 'grid', 'inline-block' ];
    function isBlock(elm) {
      var display = window.getComputedStyle(elm).getPropertyValue('display');
      return blockLike.includes(display) || display.substr(0, 6) === 'table-';
    }
    function getBlockParent(node) {
      var parentBlock = get_composed_parent_default(node);
      while (parentBlock && !isBlock(parentBlock)) {
        parentBlock = get_composed_parent_default(parentBlock);
      }
      return get_node_from_tree_default(parentBlock);
    }
    function isInTextBlock(node) {
      if (isBlock(node)) {
        return false;
      }
      var virtualParent = getBlockParent(node);
      var parentText = '';
      var linkText = '';
      var inBrBlock = 0;
      walkDomNode(virtualParent, function(currNode) {
        if (inBrBlock === 2) {
          return false;
        }
        if (currNode.nodeType === 3) {
          parentText += currNode.nodeValue;
        }
        if (currNode.nodeType !== 1) {
          return;
        }
        var nodeName2 = (currNode.nodeName || '').toUpperCase();
        if ([ 'BR', 'HR' ].includes(nodeName2)) {
          if (inBrBlock === 0) {
            parentText = '';
            linkText = '';
          } else {
            inBrBlock = 2;
          }
        } else if (currNode.style.display === 'none' || currNode.style.overflow === 'hidden' || ![ '', null, 'none' ].includes(currNode.style['float']) || ![ '', null, 'relative' ].includes(currNode.style.position)) {
          return false;
        } else if (nodeName2 === 'A' && currNode.href || (currNode.getAttribute('role') || '').toLowerCase() === 'link') {
          if (currNode === node) {
            inBrBlock = 1;
          }
          linkText += currNode.textContent;
          return false;
        }
      });
      parentText = sanitize_default(parentText);
      linkText = sanitize_default(linkText);
      return parentText.length > linkText.length;
    }
    var is_in_text_block_default = isInTextBlock;
    function isModalOpen(options) {
      options = options || {};
      var modalPercent = options.modalPercent || .75;
      if (cache_default.get('isModalOpen')) {
        return cache_default.get('isModalOpen');
      }
      var definiteModals = query_selector_all_filter_default(axe._tree[0], 'dialog, [role=dialog], [aria-modal=true]', function(vNode) {
        return is_visible_default(vNode.actualNode);
      });
      if (definiteModals.length) {
        cache_default.set('isModalOpen', true);
        return true;
      }
      var viewport = get_viewport_size_default(window);
      var percentWidth = viewport.width * modalPercent;
      var percentHeight = viewport.height * modalPercent;
      var x = (viewport.width - percentWidth) / 2;
      var y = (viewport.height - percentHeight) / 2;
      var points = [ {
        x: x,
        y: y
      }, {
        x: viewport.width - x,
        y: y
      }, {
        x: viewport.width / 2,
        y: viewport.height / 2
      }, {
        x: x,
        y: viewport.height - y
      }, {
        x: viewport.width - x,
        y: viewport.height - y
      } ];
      var stacks = points.map(function(point) {
        return Array.from(document.elementsFromPoint(point.x, point.y));
      });
      var _loop3 = function _loop3(_i6) {
        var modalElement = stacks[_i6].find(function(elm) {
          var style = window.getComputedStyle(elm);
          return parseInt(style.width, 10) >= percentWidth && parseInt(style.height, 10) >= percentHeight && style.getPropertyValue('pointer-events') !== 'none' && (style.position === 'absolute' || style.position === 'fixed');
        });
        if (modalElement && stacks.every(function(stack) {
          return stack.includes(modalElement);
        })) {
          cache_default.set('isModalOpen', true);
          return {
            v: true
          };
        }
      };
      for (var _i6 = 0; _i6 < stacks.length; _i6++) {
        var _ret = _loop3(_i6);
        if (_typeof(_ret) === 'object') {
          return _ret.v;
        }
      }
      cache_default.set('isModalOpen', void 0);
      return void 0;
    }
    var is_modal_open_default = isModalOpen;
    function isNode(element) {
      return element instanceof window.Node;
    }
    var is_node_default = isNode;
    var data = {};
    var incompleteData = {
      set: function set(key, reason) {
        if (typeof key !== 'string') {
          throw new Error('Incomplete data: key must be a string');
        }
        if (reason) {
          data[key] = reason;
        }
        return data[key];
      },
      get: function get(key) {
        return data[key];
      },
      clear: function clear() {
        data = {};
      }
    };
    var incomplete_data_default = incompleteData;
    function elementHasImage(elm, style) {
      var graphicNodes = [ 'IMG', 'CANVAS', 'OBJECT', 'IFRAME', 'VIDEO', 'SVG' ];
      var nodeName2 = elm.nodeName.toUpperCase();
      if (graphicNodes.includes(nodeName2)) {
        incomplete_data_default.set('bgColor', 'imgNode');
        return true;
      }
      style = style || window.getComputedStyle(elm);
      var bgImageStyle = style.getPropertyValue('background-image');
      var hasBgImage = bgImageStyle !== 'none';
      if (hasBgImage) {
        var hasGradient = /gradient/.test(bgImageStyle);
        incomplete_data_default.set('bgColor', hasGradient ? 'bgGradient' : 'bgImage');
      }
      return hasBgImage;
    }
    var element_has_image_default = elementHasImage;
    var ariaAttrs = {
      'aria-activedescendant': {
        type: 'idref',
        allowEmpty: true
      },
      'aria-atomic': {
        type: 'boolean',
        global: true
      },
      'aria-autocomplete': {
        type: 'nmtoken',
        values: [ 'inline', 'list', 'both', 'none' ]
      },
      'aria-busy': {
        type: 'boolean',
        global: true
      },
      'aria-checked': {
        type: 'nmtoken',
        values: [ 'false', 'mixed', 'true', 'undefined' ]
      },
      'aria-colcount': {
        type: 'int',
        minValue: -1
      },
      'aria-colindex': {
        type: 'int',
        minValue: 1
      },
      'aria-colspan': {
        type: 'int',
        minValue: 1
      },
      'aria-controls': {
        type: 'idrefs',
        allowEmpty: true,
        global: true
      },
      'aria-current': {
        type: 'nmtoken',
        allowEmpty: true,
        values: [ 'page', 'step', 'location', 'date', 'time', 'true', 'false' ],
        global: true
      },
      'aria-describedby': {
        type: 'idrefs',
        allowEmpty: true,
        global: true
      },
      'aria-details': {
        type: 'idref',
        allowEmpty: true,
        global: true
      },
      'aria-disabled': {
        type: 'boolean',
        global: true
      },
      'aria-dropeffect': {
        type: 'nmtokens',
        values: [ 'copy', 'execute', 'link', 'move', 'none', 'popup' ],
        global: true
      },
      'aria-errormessage': {
        type: 'idref',
        allowEmpty: true,
        global: true
      },
      'aria-expanded': {
        type: 'nmtoken',
        values: [ 'true', 'false', 'undefined' ]
      },
      'aria-flowto': {
        type: 'idrefs',
        allowEmpty: true,
        global: true
      },
      'aria-grabbed': {
        type: 'nmtoken',
        values: [ 'true', 'false', 'undefined' ],
        global: true
      },
      'aria-haspopup': {
        type: 'nmtoken',
        allowEmpty: true,
        values: [ 'true', 'false', 'menu', 'listbox', 'tree', 'grid', 'dialog' ],
        global: true
      },
      'aria-hidden': {
        type: 'nmtoken',
        values: [ 'true', 'false', 'undefined' ],
        global: true
      },
      'aria-invalid': {
        type: 'nmtoken',
        allowEmpty: true,
        values: [ 'grammar', 'false', 'spelling', 'true' ],
        global: true
      },
      'aria-keyshortcuts': {
        type: 'string',
        allowEmpty: true,
        global: true
      },
      'aria-label': {
        type: 'string',
        allowEmpty: true,
        global: true
      },
      'aria-labelledby': {
        type: 'idrefs',
        allowEmpty: true,
        global: true
      },
      'aria-level': {
        type: 'int',
        minValue: 1
      },
      'aria-live': {
        type: 'nmtoken',
        values: [ 'assertive', 'off', 'polite' ],
        global: true
      },
      'aria-modal': {
        type: 'boolean'
      },
      'aria-multiline': {
        type: 'boolean'
      },
      'aria-multiselectable': {
        type: 'boolean'
      },
      'aria-orientation': {
        type: 'nmtoken',
        values: [ 'horizontal', 'undefined', 'vertical' ]
      },
      'aria-owns': {
        type: 'idrefs',
        allowEmpty: true,
        global: true
      },
      'aria-placeholder': {
        type: 'string',
        allowEmpty: true
      },
      'aria-posinset': {
        type: 'int',
        minValue: 1
      },
      'aria-pressed': {
        type: 'nmtoken',
        values: [ 'false', 'mixed', 'true', 'undefined' ]
      },
      'aria-readonly': {
        type: 'boolean'
      },
      'aria-relevant': {
        type: 'nmtokens',
        values: [ 'additions', 'all', 'removals', 'text' ],
        global: true
      },
      'aria-required': {
        type: 'boolean'
      },
      'aria-roledescription': {
        type: 'string',
        allowEmpty: true,
        global: true
      },
      'aria-rowcount': {
        type: 'int',
        minValue: -1
      },
      'aria-rowindex': {
        type: 'int',
        minValue: 1
      },
      'aria-rowspan': {
        type: 'int',
        minValue: 0
      },
      'aria-selected': {
        type: 'nmtoken',
        values: [ 'false', 'true', 'undefined' ]
      },
      'aria-setsize': {
        type: 'int',
        minValue: -1
      },
      'aria-sort': {
        type: 'nmtoken',
        values: [ 'ascending', 'descending', 'none', 'other' ]
      },
      'aria-valuemax': {
        type: 'decimal'
      },
      'aria-valuemin': {
        type: 'decimal'
      },
      'aria-valuenow': {
        type: 'decimal'
      },
      'aria-valuetext': {
        type: 'string'
      }
    };
    var aria_attrs_default = ariaAttrs;
    var ariaRoles = {
      alert: {
        type: 'widget',
        allowedAttrs: [ 'aria-expanded' ],
        superclassRole: [ 'section' ]
      },
      alertdialog: {
        type: 'widget',
        allowedAttrs: [ 'aria-expanded', 'aria-modal' ],
        superclassRole: [ 'alert', 'dialog' ],
        accessibleNameRequired: true
      },
      application: {
        type: 'landmark',
        allowedAttrs: [ 'aria-activedescendant', 'aria-expanded' ],
        superclassRole: [ 'structure' ],
        accessibleNameRequired: true
      },
      article: {
        type: 'structure',
        allowedAttrs: [ 'aria-posinset', 'aria-setsize', 'aria-expanded' ],
        superclassRole: [ 'document' ]
      },
      banner: {
        type: 'landmark',
        allowedAttrs: [ 'aria-expanded' ],
        superclassRole: [ 'landmark' ]
      },
      blockquote: {
        type: 'structure',
        superclassRole: [ 'section' ]
      },
      button: {
        type: 'widget',
        allowedAttrs: [ 'aria-expanded', 'aria-pressed' ],
        superclassRole: [ 'command' ],
        accessibleNameRequired: true,
        nameFromContent: true,
        childrenPresentational: true
      },
      caption: {
        type: 'structure',
        requiredContext: [ 'figure', 'table', 'grid', 'treegrid' ],
        superclassRole: [ 'section' ],
        prohibitedAttrs: [ 'aria-label', 'aria-labelledby' ]
      },
      cell: {
        type: 'structure',
        requiredContext: [ 'row' ],
        allowedAttrs: [ 'aria-colindex', 'aria-colspan', 'aria-rowindex', 'aria-rowspan', 'aria-expanded' ],
        superclassRole: [ 'section' ],
        nameFromContent: true
      },
      checkbox: {
        type: 'widget',
        allowedAttrs: [ 'aria-checked', 'aria-readonly', 'aria-required' ],
        superclassRole: [ 'input' ],
        accessibleNameRequired: true,
        nameFromContent: true,
        childrenPresentational: true
      },
      code: {
        type: 'structure',
        superclassRole: [ 'section' ],
        prohibitedAttrs: [ 'aria-label', 'aria-labelledby' ]
      },
      columnheader: {
        type: 'structure',
        requiredContext: [ 'row' ],
        allowedAttrs: [ 'aria-sort', 'aria-colindex', 'aria-colspan', 'aria-expanded', 'aria-readonly', 'aria-required', 'aria-rowindex', 'aria-rowspan', 'aria-selected' ],
        superclassRole: [ 'cell', 'gridcell', 'sectionhead' ],
        accessibleNameRequired: false,
        nameFromContent: true
      },
      combobox: {
        type: 'composite',
        requiredOwned: [ 'listbox', 'tree', 'grid', 'dialog', 'textbox' ],
        requiredAttrs: [ 'aria-expanded' ],
        allowedAttrs: [ 'aria-controls', 'aria-autocomplete', 'aria-readonly', 'aria-required', 'aria-activedescendant', 'aria-orientation' ],
        superclassRole: [ 'select' ],
        accessibleNameRequired: true
      },
      command: {
        type: 'abstract',
        superclassRole: [ 'widget' ]
      },
      complementary: {
        type: 'landmark',
        allowedAttrs: [ 'aria-expanded' ],
        superclassRole: [ 'landmark' ]
      },
      composite: {
        type: 'abstract',
        superclassRole: [ 'widget' ]
      },
      contentinfo: {
        type: 'landmark',
        allowedAttrs: [ 'aria-expanded' ],
        superclassRole: [ 'landmark' ]
      },
      definition: {
        type: 'structure',
        allowedAttrs: [ 'aria-expanded' ],
        superclassRole: [ 'section' ]
      },
      deletion: {
        type: 'structure',
        superclassRole: [ 'section' ],
        prohibitedAttrs: [ 'aria-label', 'aria-labelledby' ]
      },
      dialog: {
        type: 'widget',
        allowedAttrs: [ 'aria-expanded', 'aria-modal' ],
        superclassRole: [ 'window' ],
        accessibleNameRequired: true
      },
      directory: {
        type: 'structure',
        allowedAttrs: [ 'aria-expanded' ],
        superclassRole: [ 'list' ],
        nameFromContent: true
      },
      document: {
        type: 'structure',
        allowedAttrs: [ 'aria-expanded' ],
        superclassRole: [ 'structure' ]
      },
      emphasis: {
        type: 'structure',
        superclassRole: [ 'section' ],
        prohibitedAttrs: [ 'aria-label', 'aria-labelledby' ]
      },
      feed: {
        type: 'structure',
        requiredOwned: [ 'article' ],
        allowedAttrs: [ 'aria-expanded' ],
        superclassRole: [ 'list' ]
      },
      figure: {
        type: 'structure',
        allowedAttrs: [ 'aria-expanded' ],
        superclassRole: [ 'section' ],
        nameFromContent: true
      },
      form: {
        type: 'landmark',
        allowedAttrs: [ 'aria-expanded' ],
        superclassRole: [ 'landmark' ]
      },
      grid: {
        type: 'composite',
        requiredOwned: [ 'rowgroup', 'row' ],
        allowedAttrs: [ 'aria-level', 'aria-multiselectable', 'aria-readonly', 'aria-activedescendant', 'aria-colcount', 'aria-expanded', 'aria-rowcount' ],
        superclassRole: [ 'composite', 'table' ],
        accessibleNameRequired: false
      },
      gridcell: {
        type: 'widget',
        requiredContext: [ 'row' ],
        allowedAttrs: [ 'aria-readonly', 'aria-required', 'aria-selected', 'aria-colindex', 'aria-colspan', 'aria-expanded', 'aria-rowindex', 'aria-rowspan' ],
        superclassRole: [ 'cell', 'widget' ],
        nameFromContent: true
      },
      group: {
        type: 'structure',
        allowedAttrs: [ 'aria-activedescendant', 'aria-expanded' ],
        superclassRole: [ 'section' ]
      },
      heading: {
        type: 'structure',
        requiredAttrs: [ 'aria-level' ],
        allowedAttrs: [ 'aria-expanded' ],
        superclassRole: [ 'sectionhead' ],
        accessibleNameRequired: false,
        nameFromContent: true
      },
      img: {
        type: 'structure',
        allowedAttrs: [ 'aria-expanded' ],
        superclassRole: [ 'section' ],
        accessibleNameRequired: true,
        childrenPresentational: true
      },
      input: {
        type: 'abstract',
        superclassRole: [ 'widget' ]
      },
      insertion: {
        type: 'structure',
        superclassRole: [ 'section' ],
        prohibitedAttrs: [ 'aria-label', 'aria-labelledby' ]
      },
      landmark: {
        type: 'abstract',
        superclassRole: [ 'section' ]
      },
      link: {
        type: 'widget',
        allowedAttrs: [ 'aria-expanded' ],
        superclassRole: [ 'command' ],
        accessibleNameRequired: true,
        nameFromContent: true
      },
      list: {
        type: 'structure',
        requiredOwned: [ 'group', 'listitem' ],
        allowedAttrs: [ 'aria-expanded' ],
        superclassRole: [ 'section' ]
      },
      listbox: {
        type: 'composite',
        requiredOwned: [ 'option' ],
        allowedAttrs: [ 'aria-multiselectable', 'aria-readonly', 'aria-required', 'aria-activedescendant', 'aria-expanded', 'aria-orientation' ],
        superclassRole: [ 'select' ],
        accessibleNameRequired: true
      },
      listitem: {
        type: 'structure',
        requiredContext: [ 'list' ],
        allowedAttrs: [ 'aria-level', 'aria-posinset', 'aria-setsize', 'aria-expanded' ],
        superclassRole: [ 'section' ],
        nameFromContent: true
      },
      log: {
        type: 'widget',
        allowedAttrs: [ 'aria-expanded' ],
        superclassRole: [ 'section' ]
      },
      main: {
        type: 'landmark',
        allowedAttrs: [ 'aria-expanded' ],
        superclassRole: [ 'landmark' ]
      },
      marquee: {
        type: 'widget',
        allowedAttrs: [ 'aria-expanded' ],
        superclassRole: [ 'section' ]
      },
      math: {
        type: 'structure',
        allowedAttrs: [ 'aria-expanded' ],
        superclassRole: [ 'section' ],
        childrenPresentational: true
      },
      menu: {
        type: 'composite',
        requiredOwned: [ 'group', 'menuitemradio', 'menuitem', 'menuitemcheckbox' ],
        allowedAttrs: [ 'aria-activedescendant', 'aria-expanded', 'aria-orientation' ],
        superclassRole: [ 'select' ]
      },
      menubar: {
        type: 'composite',
        requiredOwned: [ 'group', 'menuitemradio', 'menuitem', 'menuitemcheckbox' ],
        allowedAttrs: [ 'aria-activedescendant', 'aria-expanded', 'aria-orientation' ],
        superclassRole: [ 'menu' ]
      },
      menuitem: {
        type: 'widget',
        requiredContext: [ 'menu', 'menubar', 'group' ],
        allowedAttrs: [ 'aria-posinset', 'aria-setsize', 'aria-expanded' ],
        superclassRole: [ 'command' ],
        accessibleNameRequired: true,
        nameFromContent: true
      },
      menuitemcheckbox: {
        type: 'widget',
        requiredContext: [ 'menu', 'menubar', 'group' ],
        allowedAttrs: [ 'aria-checked', 'aria-posinset', 'aria-readonly', 'aria-setsize' ],
        superclassRole: [ 'checkbox', 'menuitem' ],
        accessibleNameRequired: true,
        nameFromContent: true,
        childrenPresentational: true
      },
      menuitemradio: {
        type: 'widget',
        requiredContext: [ 'menu', 'menubar', 'group' ],
        allowedAttrs: [ 'aria-checked', 'aria-posinset', 'aria-readonly', 'aria-setsize' ],
        superclassRole: [ 'menuitemcheckbox', 'radio' ],
        accessibleNameRequired: true,
        nameFromContent: true,
        childrenPresentational: true
      },
      meter: {
        type: 'structure',
        allowedAttrs: [ 'aria-valuetext' ],
        requiredAttrs: [ 'aria-valuemax', 'aria-valuemin', 'aria-valuenow' ],
        superclassRole: [ 'range' ],
        accessibleNameRequired: true,
        childrenPresentational: true
      },
      navigation: {
        type: 'landmark',
        allowedAttrs: [ 'aria-expanded' ],
        superclassRole: [ 'landmark' ]
      },
      none: {
        type: 'structure',
        superclassRole: [ 'structure' ],
        prohibitedAttrs: [ 'aria-label', 'aria-labelledby' ]
      },
      note: {
        type: 'structure',
        allowedAttrs: [ 'aria-expanded' ],
        superclassRole: [ 'section' ]
      },
      option: {
        type: 'widget',
        requiredContext: [ 'listbox' ],
        allowedAttrs: [ 'aria-selected', 'aria-checked', 'aria-posinset', 'aria-setsize' ],
        superclassRole: [ 'input' ],
        accessibleNameRequired: true,
        nameFromContent: true,
        childrenPresentational: true
      },
      paragraph: {
        type: 'structure',
        superclassRole: [ 'section' ],
        prohibitedAttrs: [ 'aria-label', 'aria-labelledby' ]
      },
      presentation: {
        type: 'structure',
        superclassRole: [ 'structure' ],
        prohibitedAttrs: [ 'aria-label', 'aria-labelledby' ]
      },
      progressbar: {
        type: 'widget',
        allowedAttrs: [ 'aria-expanded', 'aria-valuemax', 'aria-valuemin', 'aria-valuenow', 'aria-valuetext' ],
        superclassRole: [ 'range' ],
        accessibleNameRequired: true,
        childrenPresentational: true
      },
      radio: {
        type: 'widget',
        allowedAttrs: [ 'aria-checked', 'aria-posinset', 'aria-setsize', 'aria-required' ],
        superclassRole: [ 'input' ],
        accessibleNameRequired: true,
        nameFromContent: true,
        childrenPresentational: true
      },
      radiogroup: {
        type: 'composite',
        requiredOwned: [ 'radio' ],
        allowedAttrs: [ 'aria-readonly', 'aria-required', 'aria-activedescendant', 'aria-expanded', 'aria-orientation' ],
        superclassRole: [ 'select' ],
        accessibleNameRequired: false
      },
      range: {
        type: 'abstract',
        superclassRole: [ 'widget' ]
      },
      region: {
        type: 'landmark',
        allowedAttrs: [ 'aria-expanded' ],
        superclassRole: [ 'landmark' ],
        accessibleNameRequired: false
      },
      roletype: {
        type: 'abstract',
        superclassRole: []
      },
      row: {
        type: 'structure',
        requiredContext: [ 'grid', 'rowgroup', 'table', 'treegrid' ],
        requiredOwned: [ 'cell', 'columnheader', 'gridcell', 'rowheader' ],
        allowedAttrs: [ 'aria-colindex', 'aria-level', 'aria-rowindex', 'aria-selected', 'aria-activedescendant', 'aria-expanded' ],
        superclassRole: [ 'group', 'widget' ],
        nameFromContent: true
      },
      rowgroup: {
        type: 'structure',
        requiredContext: [ 'grid', 'table', 'treegrid' ],
        requiredOwned: [ 'row' ],
        superclassRole: [ 'structure' ],
        nameFromContent: true
      },
      rowheader: {
        type: 'structure',
        requiredContext: [ 'row' ],
        allowedAttrs: [ 'aria-sort', 'aria-colindex', 'aria-colspan', 'aria-expanded', 'aria-readonly', 'aria-required', 'aria-rowindex', 'aria-rowspan', 'aria-selected' ],
        superclassRole: [ 'cell', 'gridcell', 'sectionhead' ],
        accessibleNameRequired: false,
        nameFromContent: true
      },
      scrollbar: {
        type: 'widget',
        requiredAttrs: [ 'aria-valuenow' ],
        allowedAttrs: [ 'aria-controls', 'aria-orientation', 'aria-valuemax', 'aria-valuemin', 'aria-valuetext' ],
        superclassRole: [ 'range' ],
        childrenPresentational: true
      },
      search: {
        type: 'landmark',
        allowedAttrs: [ 'aria-expanded' ],
        superclassRole: [ 'landmark' ]
      },
      searchbox: {
        type: 'widget',
        allowedAttrs: [ 'aria-activedescendant', 'aria-autocomplete', 'aria-multiline', 'aria-placeholder', 'aria-readonly', 'aria-required' ],
        superclassRole: [ 'textbox' ],
        accessibleNameRequired: true
      },
      section: {
        type: 'abstract',
        superclassRole: [ 'structure' ],
        nameFromContent: true
      },
      sectionhead: {
        type: 'abstract',
        superclassRole: [ 'structure' ],
        nameFromContent: true
      },
      select: {
        type: 'abstract',
        superclassRole: [ 'composite', 'group' ]
      },
      separator: {
        type: 'structure',
        allowedAttrs: [ 'aria-valuemax', 'aria-valuemin', 'aria-valuenow', 'aria-orientation', 'aria-valuetext' ],
        superclassRole: [ 'structure', 'widget' ],
        childrenPresentational: true
      },
      slider: {
        type: 'widget',
        requiredAttrs: [ 'aria-valuenow' ],
        allowedAttrs: [ 'aria-valuemax', 'aria-valuemin', 'aria-orientation', 'aria-readonly', 'aria-valuetext' ],
        superclassRole: [ 'input', 'range' ],
        accessibleNameRequired: true,
        childrenPresentational: true
      },
      spinbutton: {
        type: 'widget',
        requiredAttrs: [ 'aria-valuenow' ],
        allowedAttrs: [ 'aria-valuemax', 'aria-valuemin', 'aria-readonly', 'aria-required', 'aria-activedescendant', 'aria-valuetext' ],
        superclassRole: [ 'composite', 'input', 'range' ],
        accessibleNameRequired: true
      },
      status: {
        type: 'widget',
        allowedAttrs: [ 'aria-expanded' ],
        superclassRole: [ 'section' ]
      },
      strong: {
        type: 'structure',
        superclassRole: [ 'section' ],
        prohibitedAttrs: [ 'aria-label', 'aria-labelledby' ]
      },
      structure: {
        type: 'abstract',
        superclassRole: [ 'roletype' ]
      },
      subscript: {
        type: 'structure',
        superclassRole: [ 'section' ],
        prohibitedAttrs: [ 'aria-label', 'aria-labelledby' ]
      },
      superscript: {
        type: 'structure',
        superclassRole: [ 'section' ],
        prohibitedAttrs: [ 'aria-label', 'aria-labelledby' ]
      },
      switch: {
        type: 'widget',
        requiredAttrs: [ 'aria-checked' ],
        allowedAttrs: [ 'aria-readonly' ],
        superclassRole: [ 'checkbox' ],
        accessibleNameRequired: true,
        nameFromContent: true,
        childrenPresentational: true
      },
      tab: {
        type: 'widget',
        requiredContext: [ 'tablist' ],
        allowedAttrs: [ 'aria-posinset', 'aria-selected', 'aria-setsize', 'aria-expanded' ],
        superclassRole: [ 'sectionhead', 'widget' ],
        nameFromContent: true,
        childrenPresentational: true
      },
      table: {
        type: 'structure',
        requiredOwned: [ 'rowgroup', 'row' ],
        allowedAttrs: [ 'aria-colcount', 'aria-rowcount', 'aria-expanded' ],
        superclassRole: [ 'section' ],
        accessibleNameRequired: false,
        nameFromContent: true
      },
      tablist: {
        type: 'composite',
        requiredOwned: [ 'tab' ],
        allowedAttrs: [ 'aria-level', 'aria-multiselectable', 'aria-orientation', 'aria-activedescendant', 'aria-expanded' ],
        superclassRole: [ 'composite' ]
      },
      tabpanel: {
        type: 'widget',
        allowedAttrs: [ 'aria-expanded' ],
        superclassRole: [ 'section' ],
        accessibleNameRequired: false
      },
      term: {
        type: 'structure',
        allowedAttrs: [ 'aria-expanded' ],
        superclassRole: [ 'section' ],
        nameFromContent: true
      },
      text: {
        type: 'structure',
        superclassRole: [ 'section' ],
        nameFromContent: true
      },
      textbox: {
        type: 'widget',
        allowedAttrs: [ 'aria-activedescendant', 'aria-autocomplete', 'aria-multiline', 'aria-placeholder', 'aria-readonly', 'aria-required' ],
        superclassRole: [ 'input' ],
        accessibleNameRequired: true
      },
      time: {
        type: 'structure',
        superclassRole: [ 'section' ]
      },
      timer: {
        type: 'widget',
        allowedAttrs: [ 'aria-expanded' ],
        superclassRole: [ 'status' ]
      },
      toolbar: {
        type: 'structure',
        allowedAttrs: [ 'aria-orientation', 'aria-activedescendant', 'aria-expanded' ],
        superclassRole: [ 'group' ],
        accessibleNameRequired: true
      },
      tooltip: {
        type: 'structure',
        allowedAttrs: [ 'aria-expanded' ],
        superclassRole: [ 'section' ],
        nameFromContent: true
      },
      tree: {
        type: 'composite',
        requiredOwned: [ 'group', 'treeitem' ],
        allowedAttrs: [ 'aria-multiselectable', 'aria-required', 'aria-activedescendant', 'aria-expanded', 'aria-orientation' ],
        superclassRole: [ 'select' ],
        accessibleNameRequired: false
      },
      treegrid: {
        type: 'composite',
        requiredOwned: [ 'rowgroup', 'row' ],
        allowedAttrs: [ 'aria-activedescendant', 'aria-colcount', 'aria-expanded', 'aria-level', 'aria-multiselectable', 'aria-orientation', 'aria-readonly', 'aria-required', 'aria-rowcount' ],
        superclassRole: [ 'grid', 'tree' ],
        accessibleNameRequired: false
      },
      treeitem: {
        type: 'widget',
        requiredContext: [ 'group', 'tree' ],
        allowedAttrs: [ 'aria-checked', 'aria-expanded', 'aria-level', 'aria-posinset', 'aria-selected', 'aria-setsize' ],
        superclassRole: [ 'listitem', 'option' ],
        accessibleNameRequired: true,
        nameFromContent: true
      },
      widget: {
        type: 'abstract',
        superclassRole: [ 'roletype' ]
      },
      window: {
        type: 'abstract',
        superclassRole: [ 'roletype' ]
      }
    };
    var aria_roles_default = ariaRoles;
    var dpubRoles = {
      'doc-abstract': {
        type: 'section',
        allowedAttrs: [ 'aria-expanded' ],
        superclassRole: [ 'section' ]
      },
      'doc-acknowledgments': {
        type: 'landmark',
        allowedAttrs: [ 'aria-expanded' ],
        superclassRole: [ 'landmark' ]
      },
      'doc-afterword': {
        type: 'landmark',
        allowedAttrs: [ 'aria-expanded' ],
        superclassRole: [ 'landmark' ]
      },
      'doc-appendix': {
        type: 'landmark',
        allowedAttrs: [ 'aria-expanded' ],
        superclassRole: [ 'landmark' ]
      },
      'doc-backlink': {
        type: 'link',
        allowedAttrs: [ 'aria-expanded' ],
        nameFromContent: true,
        superclassRole: [ 'link' ]
      },
      'doc-biblioentry': {
        type: 'listitem',
        requiredContext: [ 'doc-bibliography' ],
        allowedAttrs: [ 'aria-expanded', 'aria-level', 'aria-posinset', 'aria-setsize' ],
        superclassRole: [ 'listitem' ]
      },
      'doc-bibliography': {
        type: 'landmark',
        requiredOwned: [ 'doc-biblioentry' ],
        allowedAttrs: [ 'aria-expanded' ],
        superclassRole: [ 'landmark' ]
      },
      'doc-biblioref': {
        type: 'link',
        allowedAttrs: [ 'aria-expanded' ],
        nameFromContent: true,
        superclassRole: [ 'link' ]
      },
      'doc-chapter': {
        type: 'landmark',
        allowedAttrs: [ 'aria-expanded' ],
        superclassRole: [ 'landmark' ]
      },
      'doc-colophon': {
        type: 'section',
        allowedAttrs: [ 'aria-expanded' ],
        superclassRole: [ 'section' ]
      },
      'doc-conclusion': {
        type: 'landmark',
        allowedAttrs: [ 'aria-expanded' ],
        superclassRole: [ 'landmark' ]
      },
      'doc-cover': {
        type: 'img',
        allowedAttrs: [ 'aria-expanded' ],
        superclassRole: [ 'img' ]
      },
      'doc-credit': {
        type: 'section',
        allowedAttrs: [ 'aria-expanded' ],
        superclassRole: [ 'section' ]
      },
      'doc-credits': {
        type: 'landmark',
        allowedAttrs: [ 'aria-expanded' ],
        superclassRole: [ 'landmark' ]
      },
      'doc-dedication': {
        type: 'section',
        allowedAttrs: [ 'aria-expanded' ],
        superclassRole: [ 'section' ]
      },
      'doc-endnote': {
        type: 'listitem',
        requiredContext: [ 'doc-endnotes' ],
        allowedAttrs: [ 'aria-expanded', 'aria-level', 'aria-posinset', 'aria-setsize' ],
        superclassRole: [ 'listitem' ]
      },
      'doc-endnotes': {
        type: 'landmark',
        requiredOwned: [ 'doc-endnote' ],
        allowedAttrs: [ 'aria-expanded' ],
        superclassRole: [ 'landmark' ]
      },
      'doc-epigraph': {
        type: 'section',
        allowedAttrs: [ 'aria-expanded' ],
        superclassRole: [ 'section' ]
      },
      'doc-epilogue': {
        type: 'landmark',
        allowedAttrs: [ 'aria-expanded' ],
        superclassRole: [ 'landmark' ]
      },
      'doc-errata': {
        type: 'landmark',
        allowedAttrs: [ 'aria-expanded' ],
        superclassRole: [ 'landmark' ]
      },
      'doc-example': {
        type: 'section',
        allowedAttrs: [ 'aria-expanded' ],
        superclassRole: [ 'section' ]
      },
      'doc-footnote': {
        type: 'section',
        allowedAttrs: [ 'aria-expanded' ],
        superclassRole: [ 'section' ]
      },
      'doc-foreword': {
        type: 'landmark',
        allowedAttrs: [ 'aria-expanded' ],
        superclassRole: [ 'landmark' ]
      },
      'doc-glossary': {
        type: 'landmark',
        requiredOwned: [ 'definition', 'term' ],
        allowedAttrs: [ 'aria-expanded' ],
        superclassRole: [ 'landmark' ]
      },
      'doc-glossref': {
        type: 'link',
        allowedAttrs: [ 'aria-expanded' ],
        nameFromContent: true,
        superclassRole: [ 'link' ]
      },
      'doc-index': {
        type: 'navigation',
        allowedAttrs: [ 'aria-expanded' ],
        superclassRole: [ 'navigation' ]
      },
      'doc-introduction': {
        type: 'landmark',
        allowedAttrs: [ 'aria-expanded' ],
        superclassRole: [ 'landmark' ]
      },
      'doc-noteref': {
        type: 'link',
        allowedAttrs: [ 'aria-expanded' ],
        nameFromContent: true,
        superclassRole: [ 'link' ]
      },
      'doc-notice': {
        type: 'note',
        allowedAttrs: [ 'aria-expanded' ],
        superclassRole: [ 'note' ]
      },
      'doc-pagebreak': {
        type: 'separator',
        allowedAttrs: [ 'aria-expanded', 'aria-orientation' ],
        superclassRole: [ 'separator' ],
        childrenPresentational: true
      },
      'doc-pagelist': {
        type: 'navigation',
        allowedAttrs: [ 'aria-expanded' ],
        superclassRole: [ 'navigation' ]
      },
      'doc-part': {
        type: 'landmark',
        allowedAttrs: [ 'aria-expanded' ],
        superclassRole: [ 'landmark' ]
      },
      'doc-preface': {
        type: 'landmark',
        allowedAttrs: [ 'aria-expanded' ],
        superclassRole: [ 'landmark' ]
      },
      'doc-prologue': {
        type: 'landmark',
        allowedAttrs: [ 'aria-expanded' ],
        superclassRole: [ 'landmark' ]
      },
      'doc-pullquote': {
        type: 'none',
        superclassRole: [ 'none' ]
      },
      'doc-qna': {
        type: 'section',
        allowedAttrs: [ 'aria-expanded' ],
        superclassRole: [ 'section' ]
      },
      'doc-subtitle': {
        type: 'sectionhead',
        allowedAttrs: [ 'aria-expanded' ],
        superclassRole: [ 'sectionhead' ]
      },
      'doc-tip': {
        type: 'note',
        allowedAttrs: [ 'aria-expanded' ],
        superclassRole: [ 'note' ]
      },
      'doc-toc': {
        type: 'navigation',
        allowedAttrs: [ 'aria-expanded' ],
        superclassRole: [ 'navigation' ]
      }
    };
    var dpub_roles_default = dpubRoles;
    var graphicsRoles = {
      'graphics-document': {
        type: 'structure',
        superclassRole: [ 'document' ],
        accessibleNameRequired: true
      },
      'graphics-object': {
        type: 'structure',
        superclassRole: [ 'group' ],
        nameFromContent: true
      },
      'graphics-symbol': {
        type: 'structure',
        superclassRole: [ 'img' ],
        accessibleNameRequired: true,
        childrenPresentational: true
      }
    };
    var graphics_roles_default = graphicsRoles;
    var htmlElms = {
      a: {
        variant: {
          href: {
            matches: '[href]',
            contentTypes: [ 'interactive', 'phrasing', 'flow' ],
            allowedRoles: [ 'button', 'checkbox', 'menuitem', 'menuitemcheckbox', 'menuitemradio', 'option', 'radio', 'switch', 'tab', 'treeitem', 'doc-backlink', 'doc-biblioref', 'doc-glossref', 'doc-noteref' ],
            namingMethods: [ 'subtreeText' ]
          },
          default: {
            contentTypes: [ 'phrasing', 'flow' ],
            allowedRoles: true
          }
        }
      },
      abbr: {
        contentTypes: [ 'phrasing', 'flow' ],
        allowedRoles: true
      },
      addres: {
        contentTypes: [ 'flow' ],
        allowedRoles: true
      },
      area: {
        contentTypes: [ 'phrasing', 'flow' ],
        allowedRoles: false,
        namingMethods: [ 'altText' ]
      },
      article: {
        contentTypes: [ 'sectioning', 'flow' ],
        allowedRoles: [ 'feed', 'presentation', 'none', 'document', 'application', 'main', 'region' ],
        shadowRoot: true
      },
      aside: {
        contentTypes: [ 'sectioning', 'flow' ],
        allowedRoles: [ 'feed', 'note', 'presentation', 'none', 'region', 'search', 'doc-dedication', 'doc-example', 'doc-footnote', 'doc-pullquote', 'doc-tip' ]
      },
      audio: {
        variant: {
          controls: {
            matches: '[controls]',
            contentTypes: [ 'interactive', 'embedded', 'phrasing', 'flow' ]
          },
          default: {
            contentTypes: [ 'embedded', 'phrasing', 'flow' ]
          }
        },
        allowedRoles: [ 'application' ]
      },
      b: {
        contentTypes: [ 'phrasing', 'flow' ],
        allowedRoles: false
      },
      base: {
        allowedRoles: false,
        noAriaAttrs: true
      },
      bdi: {
        contentTypes: [ 'phrasing', 'flow' ],
        allowedRoles: true
      },
      bdo: {
        contentTypes: [ 'phrasing', 'flow' ],
        allowedRoles: true
      },
      blockquote: {
        contentTypes: [ 'flow' ],
        allowedRoles: true,
        shadowRoot: true
      },
      body: {
        allowedRoles: false,
        shadowRoot: true
      },
      br: {
        contentTypes: [ 'phrasing', 'flow' ],
        allowedRoles: [ 'presentation', 'none' ],
        namingMethods: [ 'titleText', 'singleSpace' ]
      },
      button: {
        contentTypes: [ 'interactive', 'phrasing', 'flow' ],
        allowedRoles: [ 'checkbox', 'link', 'menuitem', 'menuitemcheckbox', 'menuitemradio', 'option', 'radio', 'switch', 'tab' ],
        namingMethods: [ 'subtreeText' ]
      },
      canvas: {
        allowedRoles: true,
        contentTypes: [ 'embedded', 'phrasing', 'flow' ]
      },
      caption: {
        allowedRoles: false
      },
      cite: {
        contentTypes: [ 'phrasing', 'flow' ],
        allowedRoles: true
      },
      code: {
        contentTypes: [ 'phrasing', 'flow' ],
        allowedRoles: true
      },
      col: {
        allowedRoles: false,
        noAriaAttrs: true
      },
      colgroup: {
        allowedRoles: false,
        noAriaAttrs: true
      },
      data: {
        contentTypes: [ 'phrasing', 'flow' ],
        allowedRoles: true
      },
      datalist: {
        contentTypes: [ 'phrasing', 'flow' ],
        allowedRoles: false,
        implicitAttrs: {
          'aria-multiselectable': 'false'
        }
      },
      dd: {
        allowedRoles: false
      },
      del: {
        contentTypes: [ 'phrasing', 'flow' ],
        allowedRoles: true
      },
      dfn: {
        contentTypes: [ 'phrasing', 'flow' ],
        allowedRoles: true
      },
      details: {
        contentTypes: [ 'interactive', 'flow' ],
        allowedRoles: false
      },
      dialog: {
        contentTypes: [ 'flow' ],
        allowedRoles: [ 'alertdialog' ]
      },
      div: {
        contentTypes: [ 'flow' ],
        allowedRoles: true,
        shadowRoot: true
      },
      dl: {
        contentTypes: [ 'flow' ],
        allowedRoles: [ 'group', 'list', 'presentation', 'none' ]
      },
      dt: {
        allowedRoles: [ 'listitem' ]
      },
      em: {
        contentTypes: [ 'phrasing', 'flow' ],
        allowedRoles: true
      },
      embed: {
        contentTypes: [ 'interactive', 'embedded', 'phrasing', 'flow' ],
        allowedRoles: [ 'application', 'document', 'img', 'presentation', 'none' ]
      },
      fieldset: {
        contentTypes: [ 'flow' ],
        allowedRoles: [ 'none', 'presentation', 'radiogroup' ],
        namingMethods: [ 'fieldsetLegendText' ]
      },
      figcaption: {
        allowedRoles: [ 'group', 'none', 'presentation' ]
      },
      figure: {
        contentTypes: [ 'flow' ],
        allowedRoles: true,
        namingMethods: [ 'figureText', 'titleText' ]
      },
      footer: {
        contentTypes: [ 'flow' ],
        allowedRoles: [ 'group', 'none', 'presentation', 'doc-footnote' ],
        shadowRoot: true
      },
      form: {
        contentTypes: [ 'flow' ],
        allowedRoles: [ 'search', 'none', 'presentation' ]
      },
      h1: {
        contentTypes: [ 'heading', 'flow' ],
        allowedRoles: [ 'none', 'presentation', 'tab', 'doc-subtitle' ],
        shadowRoot: true,
        implicitAttrs: {
          'aria-level': '1'
        }
      },
      h2: {
        contentTypes: [ 'heading', 'flow' ],
        allowedRoles: [ 'none', 'presentation', 'tab', 'doc-subtitle' ],
        shadowRoot: true,
        implicitAttrs: {
          'aria-level': '2'
        }
      },
      h3: {
        contentTypes: [ 'heading', 'flow' ],
        allowedRoles: [ 'none', 'presentation', 'tab', 'doc-subtitle' ],
        shadowRoot: true,
        implicitAttrs: {
          'aria-level': '3'
        }
      },
      h4: {
        contentTypes: [ 'heading', 'flow' ],
        allowedRoles: [ 'none', 'presentation', 'tab', 'doc-subtitle' ],
        shadowRoot: true,
        implicitAttrs: {
          'aria-level': '4'
        }
      },
      h5: {
        contentTypes: [ 'heading', 'flow' ],
        allowedRoles: [ 'none', 'presentation', 'tab', 'doc-subtitle' ],
        shadowRoot: true,
        implicitAttrs: {
          'aria-level': '5'
        }
      },
      h6: {
        contentTypes: [ 'heading', 'flow' ],
        allowedRoles: [ 'none', 'presentation', 'tab', 'doc-subtitle' ],
        shadowRoot: true,
        implicitAttrs: {
          'aria-level': '6'
        }
      },
      head: {
        allowedRoles: false,
        noAriaAttrs: true
      },
      header: {
        contentTypes: [ 'flow' ],
        allowedRoles: [ 'group', 'none', 'presentation', 'doc-footnote' ],
        shadowRoot: true
      },
      hgroup: {
        contentTypes: [ 'heading', 'flow' ],
        allowedRoles: true
      },
      hr: {
        contentTypes: [ 'flow' ],
        allowedRoles: [ 'none', 'presentation', 'doc-pagebreak' ],
        namingMethods: [ 'titleText', 'singleSpace' ]
      },
      html: {
        allowedRoles: false,
        noAriaAttrs: true
      },
      i: {
        contentTypes: [ 'phrasing', 'flow' ],
        allowedRoles: true
      },
      iframe: {
        contentTypes: [ 'interactive', 'embedded', 'phrasing', 'flow' ],
        allowedRoles: [ 'application', 'document', 'img', 'none', 'presentation' ]
      },
      img: {
        variant: {
          nonEmptyAlt: {
            matches: {
              attributes: {
                alt: '/.+/'
              }
            },
            allowedRoles: [ 'button', 'checkbox', 'link', 'menuitem', 'menuitemcheckbox', 'menuitemradio', 'option', 'progressbar', 'scrollbar', 'separator', 'slider', 'switch', 'tab', 'treeitem', 'doc-cover' ]
          },
          usemap: {
            matches: '[usemap]',
            contentTypes: [ 'interactive', 'embedded', 'phrasing', 'flow' ]
          },
          default: {
            allowedRoles: [ 'presentation', 'none' ],
            contentTypes: [ 'embedded', 'phrasing', 'flow' ]
          }
        },
        namingMethods: [ 'altText' ]
      },
      input: {
        variant: {
          button: {
            matches: {
              properties: {
                type: 'button'
              }
            },
            allowedRoles: [ 'link', 'menuitem', 'menuitemcheckbox', 'menuitemradio', 'option', 'radio', 'switch', 'tab' ]
          },
          buttonType: {
            matches: {
              properties: {
                type: [ 'button', 'submit', 'reset' ]
              }
            },
            namingMethods: [ 'valueText', 'titleText', 'buttonDefaultText' ]
          },
          checkboxPressed: {
            matches: {
              properties: {
                type: 'checkbox'
              },
              attributes: {
                'aria-pressed': '/.*/'
              }
            },
            allowedRoles: [ 'button', 'menuitemcheckbox', 'option', 'switch' ],
            implicitAttrs: {
              'aria-checked': 'false'
            }
          },
          checkbox: {
            matches: {
              properties: {
                type: 'checkbox'
              },
              attributes: {
                'aria-pressed': null
              }
            },
            allowedRoles: [ 'menuitemcheckbox', 'option', 'switch' ],
            implicitAttrs: {
              'aria-checked': 'false'
            }
          },
          noRoles: {
            matches: {
              properties: {
                type: [ 'color', 'date', 'datetime-local', 'file', 'month', 'number', 'password', 'range', 'reset', 'submit', 'time', 'week' ]
              }
            },
            allowedRoles: false
          },
          hidden: {
            matches: {
              properties: {
                type: 'hidden'
              }
            },
            contentTypes: [ 'flow' ],
            allowedRoles: false,
            noAriaAttrs: true
          },
          image: {
            matches: {
              properties: {
                type: 'image'
              }
            },
            allowedRoles: [ 'link', 'menuitem', 'menuitemcheckbox', 'menuitemradio', 'radio', 'switch' ],
            namingMethods: [ 'altText', 'valueText', 'labelText', 'titleText', 'buttonDefaultText' ]
          },
          radio: {
            matches: {
              properties: {
                type: 'radio'
              }
            },
            allowedRoles: [ 'menuitemradio' ],
            implicitAttrs: {
              'aria-checked': 'false'
            }
          },
          textWithList: {
            matches: {
              properties: {
                type: 'text'
              },
              attributes: {
                list: '/.*/'
              }
            },
            allowedRoles: false
          },
          default: {
            contentTypes: [ 'interactive', 'flow' ],
            allowedRoles: [ 'combobox', 'searchbox', 'spinbutton' ],
            implicitAttrs: {
              'aria-valuenow': ''
            },
            namingMethods: [ 'labelText', 'placeholderText' ]
          }
        }
      },
      ins: {
        contentTypes: [ 'phrasing', 'flow' ],
        allowedRoles: true
      },
      kbd: {
        contentTypes: [ 'phrasing', 'flow' ],
        allowedRoles: true
      },
      label: {
        contentTypes: [ 'interactive', 'phrasing', 'flow' ],
        allowedRoles: false
      },
      legend: {
        allowedRoles: false
      },
      li: {
        allowedRoles: [ 'menuitem', 'menuitemcheckbox', 'menuitemradio', 'option', 'none', 'presentation', 'radio', 'separator', 'tab', 'treeitem', 'doc-biblioentry', 'doc-endnote' ],
        implicitAttrs: {
          'aria-setsize': '1',
          'aria-posinset': '1'
        }
      },
      link: {
        contentTypes: [ 'phrasing', 'flow' ],
        allowedRoles: false,
        noAriaAttrs: true
      },
      main: {
        contentTypes: [ 'flow' ],
        allowedRoles: false,
        shadowRoot: true
      },
      map: {
        contentTypes: [ 'phrasing', 'flow' ],
        allowedRoles: false,
        noAriaAttrs: true
      },
      math: {
        contentTypes: [ 'embedded', 'phrasing', 'flow' ],
        allowedRoles: false
      },
      mark: {
        contentTypes: [ 'phrasing', 'flow' ],
        allowedRoles: true
      },
      menu: {
        contentTypes: [ 'flow' ],
        allowedRoles: [ 'directory', 'group', 'listbox', 'menu', 'menubar', 'none', 'presentation', 'radiogroup', 'tablist', 'toolbar', 'tree' ]
      },
      meta: {
        variant: {
          itemprop: {
            matches: '[itemprop]',
            contentTypes: [ 'phrasing', 'flow' ]
          }
        },
        allowedRoles: false,
        noAriaAttrs: true
      },
      meter: {
        contentTypes: [ 'phrasing', 'flow' ],
        allowedRoles: false
      },
      nav: {
        contentTypes: [ 'sectioning', 'flow' ],
        allowedRoles: [ 'doc-index', 'doc-pagelist', 'doc-toc' ],
        shadowRoot: true
      },
      noscript: {
        contentTypes: [ 'phrasing', 'flow' ],
        allowedRoles: false,
        noAriaAttrs: true
      },
      object: {
        variant: {
          usemap: {
            matches: '[usemap]',
            contentTypes: [ 'interactive', 'embedded', 'phrasing', 'flow' ]
          },
          default: {
            contentTypes: [ 'embedded', 'phrasing', 'flow' ]
          }
        },
        allowedRoles: [ 'application', 'document', 'img' ]
      },
      ol: {
        contentTypes: [ 'flow' ],
        allowedRoles: [ 'directory', 'group', 'listbox', 'menu', 'menubar', 'none', 'presentation', 'radiogroup', 'tablist', 'toolbar', 'tree' ]
      },
      optgroup: {
        allowedRoles: false
      },
      option: {
        allowedRoles: false,
        implicitAttrs: {
          'aria-selected': 'false'
        }
      },
      output: {
        contentTypes: [ 'phrasing', 'flow' ],
        allowedRoles: true,
        namingMethods: [ 'subtreeText' ]
      },
      p: {
        contentTypes: [ 'flow' ],
        allowedRoles: true,
        shadowRoot: true
      },
      param: {
        allowedRoles: false,
        noAriaAttrs: true
      },
      picture: {
        contentTypes: [ 'embedded', 'phrasing', 'flow' ],
        allowedRoles: false,
        noAriaAttrs: true
      },
      pre: {
        contentTypes: [ 'flow' ],
        allowedRoles: true
      },
      progress: {
        contentTypes: [ 'phrasing', 'flow' ],
        allowedRoles: true,
        implicitAttrs: {
          'aria-valuemax': '100',
          'aria-valuemin': '0',
          'aria-valuenow': '0'
        }
      },
      q: {
        contentTypes: [ 'phrasing', 'flow' ],
        allowedRoles: true
      },
      rp: {
        allowedRoles: true
      },
      rt: {
        allowedRoles: true
      },
      ruby: {
        contentTypes: [ 'phrasing', 'flow' ],
        allowedRoles: true
      },
      s: {
        contentTypes: [ 'phrasing', 'flow' ],
        allowedRoles: true
      },
      samp: {
        contentTypes: [ 'phrasing', 'flow' ],
        allowedRoles: true
      },
      script: {
        contentTypes: [ 'phrasing', 'flow' ],
        allowedRoles: false,
        noAriaAttrs: true
      },
      section: {
        contentTypes: [ 'sectioning', 'flow' ],
        allowedRoles: [ 'alert', 'alertdialog', 'application', 'banner', 'complementary', 'contentinfo', 'dialog', 'document', 'feed', 'log', 'main', 'marquee', 'navigation', 'none', 'note', 'presentation', 'search', 'status', 'tabpanel', 'doc-abstract', 'doc-acknowledgments', 'doc-afterword', 'doc-appendix', 'doc-bibliography', 'doc-chapter', 'doc-colophon', 'doc-conclusion', 'doc-credit', 'doc-credits', 'doc-dedication', 'doc-endnotes', 'doc-epigraph', 'doc-epilogue', 'doc-errata', 'doc-example', 'doc-foreword', 'doc-glossary', 'doc-index', 'doc-introduction', 'doc-notice', 'doc-pagelist', 'doc-part', 'doc-preface', 'doc-prologue', 'doc-pullquote', 'doc-qna', 'doc-toc' ],
        shadowRoot: true
      },
      select: {
        variant: {
          combobox: {
            matches: {
              attributes: {
                multiple: null,
                size: [ null, '1' ]
              }
            },
            allowedRoles: [ 'menu' ]
          },
          default: {
            allowedRoles: false
          }
        },
        contentTypes: [ 'interactive', 'phrasing', 'flow' ],
        implicitAttrs: {
          'aria-valuenow': ''
        },
        namingMethods: [ 'labelText' ]
      },
      slot: {
        contentTypes: [ 'phrasing', 'flow' ],
        allowedRoles: false,
        noAriaAttrs: true
      },
      small: {
        contentTypes: [ 'phrasing', 'flow' ],
        allowedRoles: true
      },
      source: {
        allowedRoles: false,
        noAriaAttrs: true
      },
      span: {
        contentTypes: [ 'phrasing', 'flow' ],
        allowedRoles: true,
        shadowRoot: true
      },
      strong: {
        contentTypes: [ 'phrasing', 'flow' ],
        allowedRoles: true
      },
      style: {
        allowedRoles: false,
        noAriaAttrs: true
      },
      svg: {
        contentTypes: [ 'embedded', 'phrasing', 'flow' ],
        allowedRoles: [ 'application', 'document', 'img' ],
        namingMethods: [ 'svgTitleText' ]
      },
      sub: {
        contentTypes: [ 'phrasing', 'flow' ],
        allowedRoles: true
      },
      summary: {
        allowedRoles: false,
        namingMethods: [ 'subtreeText' ]
      },
      sup: {
        contentTypes: [ 'phrasing', 'flow' ],
        allowedRoles: true
      },
      table: {
        contentTypes: [ 'flow' ],
        allowedRoles: true,
        namingMethods: [ 'tableCaptionText', 'tableSummaryText' ]
      },
      tbody: {
        allowedRoles: true
      },
      template: {
        contentTypes: [ 'phrasing', 'flow' ],
        allowedRoles: false,
        noAriaAttrs: true
      },
      textarea: {
        contentTypes: [ 'interactive', 'phrasing', 'flow' ],
        allowedRoles: false,
        implicitAttrs: {
          'aria-valuenow': '',
          'aria-multiline': 'true'
        },
        namingMethods: [ 'labelText', 'placeholderText' ]
      },
      tfoot: {
        allowedRoles: true
      },
      thead: {
        allowedRoles: true
      },
      time: {
        contentTypes: [ 'phrasing', 'flow' ],
        allowedRoles: true
      },
      title: {
        allowedRoles: false,
        noAriaAttrs: true
      },
      td: {
        allowedRoles: true
      },
      th: {
        allowedRoles: true
      },
      tr: {
        allowedRoles: true
      },
      track: {
        allowedRoles: false,
        noAriaAttrs: true
      },
      u: {
        contentTypes: [ 'phrasing', 'flow' ],
        allowedRoles: true
      },
      ul: {
        contentTypes: [ 'flow' ],
        allowedRoles: [ 'directory', 'group', 'listbox', 'menu', 'menubar', 'none', 'presentation', 'radiogroup', 'tablist', 'toolbar', 'tree' ]
      },
      var: {
        contentTypes: [ 'phrasing', 'flow' ],
        allowedRoles: true
      },
      video: {
        variant: {
          controls: {
            matches: '[controls]',
            contentTypes: [ 'interactive', 'embedded', 'phrasing', 'flow' ]
          },
          default: {
            contentTypes: [ 'embedded', 'phrasing', 'flow' ]
          }
        },
        allowedRoles: [ 'application' ]
      },
      wbr: {
        contentTypes: [ 'phrasing', 'flow' ],
        allowedRoles: true
      }
    };
    var html_elms_default = htmlElms;
    var cssColors = {
      aliceblue: [ 240, 248, 255 ],
      antiquewhite: [ 250, 235, 215 ],
      aqua: [ 0, 255, 255 ],
      aquamarine: [ 127, 255, 212 ],
      azure: [ 240, 255, 255 ],
      beige: [ 245, 245, 220 ],
      bisque: [ 255, 228, 196 ],
      black: [ 0, 0, 0 ],
      blanchedalmond: [ 255, 235, 205 ],
      blue: [ 0, 0, 255 ],
      blueviolet: [ 138, 43, 226 ],
      brown: [ 165, 42, 42 ],
      burlywood: [ 222, 184, 135 ],
      cadetblue: [ 95, 158, 160 ],
      chartreuse: [ 127, 255, 0 ],
      chocolate: [ 210, 105, 30 ],
      coral: [ 255, 127, 80 ],
      cornflowerblue: [ 100, 149, 237 ],
      cornsilk: [ 255, 248, 220 ],
      crimson: [ 220, 20, 60 ],
      cyan: [ 0, 255, 255 ],
      darkblue: [ 0, 0, 139 ],
      darkcyan: [ 0, 139, 139 ],
      darkgoldenrod: [ 184, 134, 11 ],
      darkgray: [ 169, 169, 169 ],
      darkgreen: [ 0, 100, 0 ],
      darkgrey: [ 169, 169, 169 ],
      darkkhaki: [ 189, 183, 107 ],
      darkmagenta: [ 139, 0, 139 ],
      darkolivegreen: [ 85, 107, 47 ],
      darkorange: [ 255, 140, 0 ],
      darkorchid: [ 153, 50, 204 ],
      darkred: [ 139, 0, 0 ],
      darksalmon: [ 233, 150, 122 ],
      darkseagreen: [ 143, 188, 143 ],
      darkslateblue: [ 72, 61, 139 ],
      darkslategray: [ 47, 79, 79 ],
      darkslategrey: [ 47, 79, 79 ],
      darkturquoise: [ 0, 206, 209 ],
      darkviolet: [ 148, 0, 211 ],
      deeppink: [ 255, 20, 147 ],
      deepskyblue: [ 0, 191, 255 ],
      dimgray: [ 105, 105, 105 ],
      dimgrey: [ 105, 105, 105 ],
      dodgerblue: [ 30, 144, 255 ],
      firebrick: [ 178, 34, 34 ],
      floralwhite: [ 255, 250, 240 ],
      forestgreen: [ 34, 139, 34 ],
      fuchsia: [ 255, 0, 255 ],
      gainsboro: [ 220, 220, 220 ],
      ghostwhite: [ 248, 248, 255 ],
      gold: [ 255, 215, 0 ],
      goldenrod: [ 218, 165, 32 ],
      gray: [ 128, 128, 128 ],
      green: [ 0, 128, 0 ],
      greenyellow: [ 173, 255, 47 ],
      grey: [ 128, 128, 128 ],
      honeydew: [ 240, 255, 240 ],
      hotpink: [ 255, 105, 180 ],
      indianred: [ 205, 92, 92 ],
      indigo: [ 75, 0, 130 ],
      ivory: [ 255, 255, 240 ],
      khaki: [ 240, 230, 140 ],
      lavender: [ 230, 230, 250 ],
      lavenderblush: [ 255, 240, 245 ],
      lawngreen: [ 124, 252, 0 ],
      lemonchiffon: [ 255, 250, 205 ],
      lightblue: [ 173, 216, 230 ],
      lightcoral: [ 240, 128, 128 ],
      lightcyan: [ 224, 255, 255 ],
      lightgoldenrodyellow: [ 250, 250, 210 ],
      lightgray: [ 211, 211, 211 ],
      lightgreen: [ 144, 238, 144 ],
      lightgrey: [ 211, 211, 211 ],
      lightpink: [ 255, 182, 193 ],
      lightsalmon: [ 255, 160, 122 ],
      lightseagreen: [ 32, 178, 170 ],
      lightskyblue: [ 135, 206, 250 ],
      lightslategray: [ 119, 136, 153 ],
      lightslategrey: [ 119, 136, 153 ],
      lightsteelblue: [ 176, 196, 222 ],
      lightyellow: [ 255, 255, 224 ],
      lime: [ 0, 255, 0 ],
      limegreen: [ 50, 205, 50 ],
      linen: [ 250, 240, 230 ],
      magenta: [ 255, 0, 255 ],
      maroon: [ 128, 0, 0 ],
      mediumaquamarine: [ 102, 205, 170 ],
      mediumblue: [ 0, 0, 205 ],
      mediumorchid: [ 186, 85, 211 ],
      mediumpurple: [ 147, 112, 219 ],
      mediumseagreen: [ 60, 179, 113 ],
      mediumslateblue: [ 123, 104, 238 ],
      mediumspringgreen: [ 0, 250, 154 ],
      mediumturquoise: [ 72, 209, 204 ],
      mediumvioletred: [ 199, 21, 133 ],
      midnightblue: [ 25, 25, 112 ],
      mintcream: [ 245, 255, 250 ],
      mistyrose: [ 255, 228, 225 ],
      moccasin: [ 255, 228, 181 ],
      navajowhite: [ 255, 222, 173 ],
      navy: [ 0, 0, 128 ],
      oldlace: [ 253, 245, 230 ],
      olive: [ 128, 128, 0 ],
      olivedrab: [ 107, 142, 35 ],
      orange: [ 255, 165, 0 ],
      orangered: [ 255, 69, 0 ],
      orchid: [ 218, 112, 214 ],
      palegoldenrod: [ 238, 232, 170 ],
      palegreen: [ 152, 251, 152 ],
      paleturquoise: [ 175, 238, 238 ],
      palevioletred: [ 219, 112, 147 ],
      papayawhip: [ 255, 239, 213 ],
      peachpuff: [ 255, 218, 185 ],
      peru: [ 205, 133, 63 ],
      pink: [ 255, 192, 203 ],
      plum: [ 221, 160, 221 ],
      powderblue: [ 176, 224, 230 ],
      purple: [ 128, 0, 128 ],
      rebeccapurple: [ 102, 51, 153 ],
      red: [ 255, 0, 0 ],
      rosybrown: [ 188, 143, 143 ],
      royalblue: [ 65, 105, 225 ],
      saddlebrown: [ 139, 69, 19 ],
      salmon: [ 250, 128, 114 ],
      sandybrown: [ 244, 164, 96 ],
      seagreen: [ 46, 139, 87 ],
      seashell: [ 255, 245, 238 ],
      sienna: [ 160, 82, 45 ],
      silver: [ 192, 192, 192 ],
      skyblue: [ 135, 206, 235 ],
      slateblue: [ 106, 90, 205 ],
      slategray: [ 112, 128, 144 ],
      slategrey: [ 112, 128, 144 ],
      snow: [ 255, 250, 250 ],
      springgreen: [ 0, 255, 127 ],
      steelblue: [ 70, 130, 180 ],
      tan: [ 210, 180, 140 ],
      teal: [ 0, 128, 128 ],
      thistle: [ 216, 191, 216 ],
      tomato: [ 255, 99, 71 ],
      turquoise: [ 64, 224, 208 ],
      violet: [ 238, 130, 238 ],
      wheat: [ 245, 222, 179 ],
      white: [ 255, 255, 255 ],
      whitesmoke: [ 245, 245, 245 ],
      yellow: [ 255, 255, 0 ],
      yellowgreen: [ 154, 205, 50 ]
    };
    var css_colors_default = cssColors;
    var originals = {
      ariaAttrs: aria_attrs_default,
      ariaRoles: _extends({}, aria_roles_default, dpub_roles_default, graphics_roles_default),
      htmlElms: html_elms_default,
      cssColors: css_colors_default
    };
    var standards = _extends({}, originals);
    function configureStandards(config) {
      Object.keys(standards).forEach(function(propName) {
        if (config[propName]) {
          standards[propName] = deep_merge_default(standards[propName], config[propName]);
        }
      });
    }
    function resetStandards() {
      Object.keys(standards).forEach(function(propName) {
        standards[propName] = originals[propName];
      });
    }
    var standards_default = standards;
    function convertColorVal(colorFunc, value, index) {
      if (/%$/.test(value)) {
        if (index === 3) {
          return parseFloat(value) / 100;
        }
        return parseFloat(value) * 255 / 100;
      }
      if (colorFunc[index] === 'h') {
        if (/turn$/.test(value)) {
          return parseFloat(value) * 360;
        }
        if (/rad$/.test(value)) {
          return parseFloat(value) * 57.3;
        }
      }
      return parseFloat(value);
    }
    function hslToRgb(_ref9) {
      var _ref10 = _slicedToArray(_ref9, 4), hue = _ref10[0], saturation = _ref10[1], lightness = _ref10[2], alpha = _ref10[3];
      saturation /= 255;
      lightness /= 255;
      var high = (1 - Math.abs(2 * lightness - 1)) * saturation;
      var low = high * (1 - Math.abs(hue / 60 % 2 - 1));
      var base = lightness - high / 2;
      var colors;
      if (hue < 60) {
        colors = [ high, low, 0 ];
      } else if (hue < 120) {
        colors = [ low, high, 0 ];
      } else if (hue < 180) {
        colors = [ 0, high, low ];
      } else if (hue < 240) {
        colors = [ 0, low, high ];
      } else if (hue < 300) {
        colors = [ low, 0, high ];
      } else {
        colors = [ high, 0, low ];
      }
      return colors.map(function(color10) {
        return Math.round((color10 + base) * 255);
      }).concat(alpha);
    }
    function Color(red, green, blue, alpha) {
      this.red = red;
      this.green = green;
      this.blue = blue;
      this.alpha = alpha;
      this.toHexString = function toHexString() {
        var redString = Math.round(this.red).toString(16);
        var greenString = Math.round(this.green).toString(16);
        var blueString = Math.round(this.blue).toString(16);
        return '#' + (this.red > 15.5 ? redString : '0' + redString) + (this.green > 15.5 ? greenString : '0' + greenString) + (this.blue > 15.5 ? blueString : '0' + blueString);
      };
      var hexRegex = /^#[0-9a-f]{3,8}$/i;
      var colorFnRegex = /^((?:rgb|hsl)a?)\s*\(([^\)]*)\)/i;
      this.parseString = function parseString(colorString) {
        if (standards_default.cssColors[colorString] || colorString === 'transparent') {
          var _ref11 = standards_default.cssColors[colorString] || [ 0, 0, 0 ], _ref12 = _slicedToArray(_ref11, 3), red2 = _ref12[0], green2 = _ref12[1], blue2 = _ref12[2];
          this.red = red2;
          this.green = green2;
          this.blue = blue2;
          this.alpha = colorString === 'transparent' ? 0 : 1;
          return;
        }
        if (colorString.match(colorFnRegex)) {
          this.parseColorFnString(colorString);
          return;
        }
        if (colorString.match(hexRegex)) {
          this.parseHexString(colorString);
          return;
        }
        throw new Error('Unable to parse color "'.concat(colorString, '"'));
      };
      this.parseRgbString = function parseRgbString(colorString) {
        if (colorString === 'transparent') {
          this.red = 0;
          this.green = 0;
          this.blue = 0;
          this.alpha = 0;
          return;
        }
        this.parseColorFnString(colorString);
      };
      this.parseHexString = function parseHexString(colorString) {
        if (!colorString.match(hexRegex) || [ 6, 8 ].includes(colorString.length)) {
          return;
        }
        colorString = colorString.replace('#', '');
        if (colorString.length < 6) {
          var _colorString = colorString, _colorString2 = _slicedToArray(_colorString, 4), r = _colorString2[0], g = _colorString2[1], b = _colorString2[2], a = _colorString2[3];
          colorString = r + r + g + g + b + b;
          if (a) {
            colorString += a + a;
          }
        }
        var aRgbHex = colorString.match(/.{1,2}/g);
        this.red = parseInt(aRgbHex[0], 16);
        this.green = parseInt(aRgbHex[1], 16);
        this.blue = parseInt(aRgbHex[2], 16);
        if (aRgbHex[3]) {
          this.alpha = parseInt(aRgbHex[3], 16) / 255;
        } else {
          this.alpha = 1;
        }
      };
      this.parseColorFnString = function parseColorFnString(colorString) {
        var _ref13 = colorString.match(colorFnRegex) || [], _ref14 = _slicedToArray(_ref13, 3), colorFunc = _ref14[1], colorValStr = _ref14[2];
        if (!colorFunc || !colorValStr) {
          return;
        }
        var colorVals = colorValStr.split(/\s*[,\/\s]\s*/).map(function(str) {
          return str.replace(',', '').trim();
        }).filter(function(str) {
          return str !== '';
        });
        var colorNums = colorVals.map(function(val, index) {
          return convertColorVal(colorFunc, val, index);
        });
        if (colorFunc.substr(0, 3) === 'hsl') {
          colorNums = hslToRgb(colorNums);
        }
        this.red = colorNums[0];
        this.green = colorNums[1];
        this.blue = colorNums[2];
        this.alpha = typeof colorNums[3] === 'number' ? colorNums[3] : 1;
      };
      this.getRelativeLuminance = function getRelativeLuminance() {
        var rSRGB = this.red / 255;
        var gSRGB = this.green / 255;
        var bSRGB = this.blue / 255;
        var r = rSRGB <= .03928 ? rSRGB / 12.92 : Math.pow((rSRGB + .055) / 1.055, 2.4);
        var g = gSRGB <= .03928 ? gSRGB / 12.92 : Math.pow((gSRGB + .055) / 1.055, 2.4);
        var b = bSRGB <= .03928 ? bSRGB / 12.92 : Math.pow((bSRGB + .055) / 1.055, 2.4);
        return .2126 * r + .7152 * g + .0722 * b;
      };
    }
    var color_default = Color;
    function getOwnBackgroundColor(elmStyle) {
      var bgColor = new color_default();
      bgColor.parseString(elmStyle.getPropertyValue('background-color'));
      if (bgColor.alpha !== 0) {
        var opacity = elmStyle.getPropertyValue('opacity');
        bgColor.alpha = bgColor.alpha * opacity;
      }
      return bgColor;
    }
    var get_own_background_color_default = getOwnBackgroundColor;
    function isOpaque(node) {
      var style = window.getComputedStyle(node);
      return element_has_image_default(node, style) || get_own_background_color_default(style).alpha === 1;
    }
    var is_opaque_default = isOpaque;
    var isInternalLinkRegex = /^\/?#[^/!]/;
    function isSkipLink(element) {
      if (!isInternalLinkRegex.test(element.getAttribute('href'))) {
        return false;
      }
      var firstPageLink;
      if (typeof cache_default.get('firstPageLink') !== 'undefined') {
        firstPageLink = cache_default.get('firstPageLink');
      } else {
        firstPageLink = query_selector_all_default(axe._tree, 'a:not([href^="#"]):not([href^="/#"]):not([href^="javascript"])')[0];
        cache_default.set('firstPageLink', firstPageLink || null);
      }
      if (!firstPageLink) {
        return true;
      }
      return element.compareDocumentPosition(firstPageLink.actualNode) === element.DOCUMENT_POSITION_FOLLOWING;
    }
    var is_skip_link_default = isSkipLink;
    function reduceToElementsBelowFloating(elements, targetNode) {
      var floatingPositions = [ 'fixed', 'sticky' ];
      var finalElements = [];
      var targetFound = false;
      for (var index = 0; index < elements.length; ++index) {
        var currentNode = elements[index];
        if (currentNode === targetNode) {
          targetFound = true;
        }
        var style = window.getComputedStyle(currentNode);
        if (!targetFound && floatingPositions.indexOf(style.position) !== -1) {
          finalElements = [];
          continue;
        }
        finalElements.push(currentNode);
      }
      return finalElements;
    }
    var reduce_to_elements_below_floating_default = reduceToElementsBelowFloating;
    function getScrollAncestor(node) {
      var vNode = get_node_from_tree_default(node);
      var ancestor = vNode.parent;
      while (ancestor) {
        if (get_scroll_default(ancestor.actualNode)) {
          return ancestor.actualNode;
        }
        ancestor = ancestor.parent;
      }
    }
    function contains2(node, parent) {
      var rectBound = node.getBoundingClientRect();
      var margin = .01;
      var rect = {
        top: rectBound.top + margin,
        bottom: rectBound.bottom - margin,
        left: rectBound.left + margin,
        right: rectBound.right - margin
      };
      var parentRect = parent.getBoundingClientRect();
      var parentTop = parentRect.top;
      var parentLeft = parentRect.left;
      var parentScrollArea = {
        top: parentTop - parent.scrollTop,
        bottom: parentTop - parent.scrollTop + parent.scrollHeight,
        left: parentLeft - parent.scrollLeft,
        right: parentLeft - parent.scrollLeft + parent.scrollWidth
      };
      var style = window.getComputedStyle(parent);
      if (style.getPropertyValue('display') === 'inline') {
        return true;
      }
      if (rect.left < parentScrollArea.left && rect.left < parentRect.left || rect.top < parentScrollArea.top && rect.top < parentRect.top || rect.right > parentScrollArea.right && rect.right > parentRect.right || rect.bottom > parentScrollArea.bottom && rect.bottom > parentRect.bottom) {
        return false;
      }
      if (rect.right > parentRect.right || rect.bottom > parentRect.bottom) {
        return style.overflow === 'scroll' || style.overflow === 'auto' || style.overflow === 'hidden' || parent instanceof window.HTMLBodyElement || parent instanceof window.HTMLHtmlElement;
      }
      return true;
    }
    function visuallyContains(node, parent) {
      var parentScrollAncestor = getScrollAncestor(parent);
      do {
        var nextScrollAncestor = getScrollAncestor(node);
        if (nextScrollAncestor === parentScrollAncestor || nextScrollAncestor === parent) {
          return contains2(node, parent);
        }
        node = nextScrollAncestor;
      } while (node);
      return false;
    }
    var visually_contains_default = visuallyContains;
    function shadowElementsFromPoint(nodeX, nodeY) {
      var root = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : document;
      var i = arguments.length > 3 && arguments[3] !== undefined ? arguments[3] : 0;
      if (i > 999) {
        throw new Error('Infinite loop detected');
      }
      return Array.from(root.elementsFromPoint(nodeX, nodeY) || []).filter(function(nodes) {
        return get_root_node_default2(nodes) === root;
      }).reduce(function(stack, elm) {
        if (is_shadow_root_default(elm)) {
          var shadowStack = shadowElementsFromPoint(nodeX, nodeY, elm.shadowRoot, i + 1);
          stack = stack.concat(shadowStack);
          if (stack.length && visually_contains_default(stack[0], elm)) {
            stack.push(elm);
          }
        } else {
          stack.push(elm);
        }
        return stack;
      }, []);
    }
    var shadow_elements_from_point_default = shadowElementsFromPoint;
    function urlPropsFromAttribute(node, attribute) {
      if (!node.hasAttribute(attribute)) {
        return void 0;
      }
      var nodeName2 = node.nodeName.toUpperCase();
      var parser2 = node;
      if (![ 'A', 'AREA' ].includes(nodeName2) || node.ownerSVGElement) {
        parser2 = document.createElement('a');
        parser2.href = node.getAttribute(attribute);
      }
      var protocol = [ 'https:', 'ftps:' ].includes(parser2.protocol) ? parser2.protocol.replace(/s:$/, ':') : parser2.protocol;
      var parserPathname = /^\//.test(parser2.pathname) ? parser2.pathname : '/'.concat(parser2.pathname);
      var _getPathnameOrFilenam = getPathnameOrFilename(parserPathname), pathname = _getPathnameOrFilenam.pathname, filename = _getPathnameOrFilenam.filename;
      return {
        protocol: protocol,
        hostname: parser2.hostname,
        port: getPort(parser2.port),
        pathname: /\/$/.test(pathname) ? pathname : ''.concat(pathname, '/'),
        search: getSearchPairs(parser2.search),
        hash: getHashRoute(parser2.hash),
        filename: filename
      };
    }
    function getPort(port) {
      var excludePorts = [ '443', '80' ];
      return !excludePorts.includes(port) ? port : '';
    }
    function getPathnameOrFilename(pathname) {
      var filename = pathname.split('/').pop();
      if (!filename || filename.indexOf('.') === -1) {
        return {
          pathname: pathname,
          filename: ''
        };
      }
      return {
        pathname: pathname.replace(filename, ''),
        filename: /index./.test(filename) ? '' : filename
      };
    }
    function getSearchPairs(searchStr) {
      var query = {};
      if (!searchStr || !searchStr.length) {
        return query;
      }
      var pairs = searchStr.substring(1).split('&');
      if (!pairs || !pairs.length) {
        return query;
      }
      for (var index = 0; index < pairs.length; index++) {
        var pair = pairs[index];
        var _pair$split = pair.split('='), _pair$split2 = _slicedToArray(_pair$split, 2), key = _pair$split2[0], _pair$split2$ = _pair$split2[1], value = _pair$split2$ === void 0 ? '' : _pair$split2$;
        query[decodeURIComponent(key)] = decodeURIComponent(value);
      }
      return query;
    }
    function getHashRoute(hash) {
      if (!hash) {
        return '';
      }
      var hashRegex = /#!?\/?/g;
      var hasMatch = hash.match(hashRegex);
      if (!hasMatch) {
        return '';
      }
      var _hasMatch = _slicedToArray(hasMatch, 1), matchedStr = _hasMatch[0];
      if (matchedStr === '#') {
        return '';
      }
      return hash;
    }
    var url_props_from_attribute_default = urlPropsFromAttribute;
    function visuallyOverlaps(rect, parent) {
      var parentRect = parent.getBoundingClientRect();
      var parentTop = parentRect.top;
      var parentLeft = parentRect.left;
      var parentScrollArea = {
        top: parentTop - parent.scrollTop,
        bottom: parentTop - parent.scrollTop + parent.scrollHeight,
        left: parentLeft - parent.scrollLeft,
        right: parentLeft - parent.scrollLeft + parent.scrollWidth
      };
      if (rect.left > parentScrollArea.right && rect.left > parentRect.right || rect.top > parentScrollArea.bottom && rect.top > parentRect.bottom || rect.right < parentScrollArea.left && rect.right < parentRect.left || rect.bottom < parentScrollArea.top && rect.bottom < parentRect.top) {
        return false;
      }
      var style = window.getComputedStyle(parent);
      if (rect.left > parentRect.right || rect.top > parentRect.bottom) {
        return style.overflow === 'scroll' || style.overflow === 'auto' || parent instanceof window.HTMLBodyElement || parent instanceof window.HTMLHtmlElement;
      }
      return true;
    }
    var visually_overlaps_default = visuallyOverlaps;
    var isXHTMLGlobal;
    var VirtualNode = function(_abstract_virtual_nod) {
      _inherits(VirtualNode, _abstract_virtual_nod);
      var _super = _createSuper(VirtualNode);
      function VirtualNode(node, parent, shadowId) {
        var _this;
        _classCallCheck(this, VirtualNode);
        _this = _super.call(this);
        _this.shadowId = shadowId;
        _this.children = [];
        _this.actualNode = node;
        _this.parent = parent;
        _this._isHidden = null;
        _this._cache = {};
        if (typeof isXHTMLGlobal === 'undefined') {
          isXHTMLGlobal = is_xhtml_default(node.ownerDocument);
        }
        _this._isXHTML = isXHTMLGlobal;
        if (node.nodeName.toLowerCase() === 'input') {
          var type = node.getAttribute('type');
          type = _this._isXHTML ? type : (type || '').toLowerCase();
          if (!valid_input_type_default().includes(type)) {
            type = 'text';
          }
          _this._type = type;
        }
        if (cache_default.get('nodeMap')) {
          cache_default.get('nodeMap').set(node, _assertThisInitialized(_this));
        }
        return _this;
      }
      _createClass(VirtualNode, [ {
        key: 'attr',
        value: function attr(attrName) {
          if (typeof this.actualNode.getAttribute !== 'function') {
            return null;
          }
          return this.actualNode.getAttribute(attrName);
        }
      }, {
        key: 'hasAttr',
        value: function hasAttr(attrName) {
          if (typeof this.actualNode.hasAttribute !== 'function') {
            return false;
          }
          return this.actualNode.hasAttribute(attrName);
        }
      }, {
        key: 'getComputedStylePropertyValue',
        value: function getComputedStylePropertyValue(property) {
          var key = 'computedStyle_' + property;
          if (!this._cache.hasOwnProperty(key)) {
            if (!this._cache.hasOwnProperty('computedStyle')) {
              this._cache.computedStyle = window.getComputedStyle(this.actualNode);
            }
            this._cache[key] = this._cache.computedStyle.getPropertyValue(property);
          }
          return this._cache[key];
        }
      }, {
        key: 'props',
        get: function get() {
          var _this$actualNode = this.actualNode, nodeType = _this$actualNode.nodeType, nodeName2 = _this$actualNode.nodeName, id = _this$actualNode.id, multiple = _this$actualNode.multiple, nodeValue = _this$actualNode.nodeValue, value = _this$actualNode.value;
          return {
            nodeType: nodeType,
            nodeName: this._isXHTML ? nodeName2 : nodeName2.toLowerCase(),
            id: id,
            type: this._type,
            multiple: multiple,
            nodeValue: nodeValue,
            value: value
          };
        }
      }, {
        key: 'attrNames',
        get: function get() {
          if (!this._cache.hasOwnProperty('attrNames')) {
            var attrs;
            if (this.actualNode.attributes instanceof window.NamedNodeMap) {
              attrs = this.actualNode.attributes;
            } else {
              attrs = this.actualNode.cloneNode(false).attributes;
            }
            this._cache.attrNames = Array.from(attrs).map(function(attr) {
              return attr.name;
            });
          }
          return this._cache.attrNames;
        }
      }, {
        key: 'isFocusable',
        get: function get() {
          if (!this._cache.hasOwnProperty('isFocusable')) {
            this._cache.isFocusable = is_focusable_default(this.actualNode);
          }
          return this._cache.isFocusable;
        }
      }, {
        key: 'tabbableElements',
        get: function get() {
          if (!this._cache.hasOwnProperty('tabbableElements')) {
            this._cache.tabbableElements = get_tabbable_elements_default(this);
          }
          return this._cache.tabbableElements;
        }
      }, {
        key: 'clientRects',
        get: function get() {
          if (!this._cache.hasOwnProperty('clientRects')) {
            this._cache.clientRects = Array.from(this.actualNode.getClientRects()).filter(function(rect) {
              return rect.width > 0;
            });
          }
          return this._cache.clientRects;
        }
      }, {
        key: 'boundingClientRect',
        get: function get() {
          if (!this._cache.hasOwnProperty('boundingClientRect')) {
            this._cache.boundingClientRect = this.actualNode.getBoundingClientRect();
          }
          return this._cache.boundingClientRect;
        }
      } ]);
      return VirtualNode;
    }(abstract_virtual_node_default);
    var virtual_node_default = VirtualNode;
    function getSlotChildren(node) {
      var retVal = [];
      node = node.firstChild;
      while (node) {
        retVal.push(node);
        node = node.nextSibling;
      }
      return retVal;
    }
    function flattenTree(node, shadowId, parent) {
      var retVal, realArray, nodeName2;
      function reduceShadowDOM(res, child, parent2) {
        var replacements = flattenTree(child, shadowId, parent2);
        if (replacements) {
          res = res.concat(replacements);
        }
        return res;
      }
      if (node.documentElement) {
        node = node.documentElement;
      }
      nodeName2 = node.nodeName.toLowerCase();
      if (is_shadow_root_default(node)) {
        retVal = new virtual_node_default(node, parent, shadowId);
        shadowId = 'a' + Math.random().toString().substring(2);
        realArray = Array.from(node.shadowRoot.childNodes);
        retVal.children = realArray.reduce(function(res, child) {
          return reduceShadowDOM(res, child, retVal);
        }, []);
        return [ retVal ];
      } else {
        if (nodeName2 === 'content' && typeof node.getDistributedNodes === 'function') {
          realArray = Array.from(node.getDistributedNodes());
          return realArray.reduce(function(res, child) {
            return reduceShadowDOM(res, child, parent);
          }, []);
        } else if (nodeName2 === 'slot' && typeof node.assignedNodes === 'function') {
          realArray = Array.from(node.assignedNodes());
          if (!realArray.length) {
            realArray = getSlotChildren(node);
          }
          var styl = window.getComputedStyle(node);
          if (false) {
            retVal = new virtual_node_default(node, parent, shadowId);
            retVal.children = realArray.reduce(function(res, child) {
              return reduceShadowDOM(res, child, retVal);
            }, []);
            return [ retVal ];
          } else {
            return realArray.reduce(function(res, child) {
              return reduceShadowDOM(res, child, parent);
            }, []);
          }
        } else {
          if (node.nodeType === 1) {
            retVal = new virtual_node_default(node, parent, shadowId);
            realArray = Array.from(node.childNodes);
            retVal.children = realArray.reduce(function(res, child) {
              return reduceShadowDOM(res, child, retVal);
            }, []);
            return [ retVal ];
          } else if (node.nodeType === 3) {
            return [ new virtual_node_default(node, parent) ];
          }
          return void 0;
        }
      }
    }
    function getFlattenedTree() {
      var node = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : document.documentElement;
      var shadowId = arguments.length > 1 ? arguments[1] : undefined;
      cache_default.set('nodeMap', new WeakMap());
      return flattenTree(node, shadowId, null);
    }
    var get_flattened_tree_default = getFlattenedTree;
    function getBaseLang(lang) {
      if (!lang) {
        return '';
      }
      return lang.trim().split('-')[0].toLowerCase();
    }
    var get_base_lang_default = getBaseLang;
    function failureSummary(nodeData) {
      var failingChecks = {};
      failingChecks.none = nodeData.none.concat(nodeData.all);
      failingChecks.any = nodeData.any;
      return Object.keys(failingChecks).map(function(key) {
        if (!failingChecks[key].length) {
          return;
        }
        var sum = axe._audit.data.failureSummaries[key];
        if (sum && typeof sum.failureMessage === 'function') {
          return sum.failureMessage(failingChecks[key].map(function(check4) {
            return check4.message || '';
          }));
        }
      }).filter(function(i) {
        return i !== void 0;
      }).join('\n\n');
    }
    var failure_summary_default = failureSummary;
    function getEnvironmentData() {
      var win = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : window;
      var _win$screen = win.screen, screen = _win$screen === void 0 ? {} : _win$screen, _win$navigator = win.navigator, navigator = _win$navigator === void 0 ? {} : _win$navigator, _win$location = win.location, location = _win$location === void 0 ? {} : _win$location, innerHeight = win.innerHeight, innerWidth = win.innerWidth;
      var orientation = screen.msOrientation || screen.orientation || screen.mozOrientation || {};
      return {
        testEngine: {
          name: 'axe-core',
          version: axe.version
        },
        testRunner: {
          name: axe._audit.brand
        },
        testEnvironment: {
          userAgent: navigator.userAgent,
          windowWidth: innerWidth,
          windowHeight: innerHeight,
          orientationAngle: orientation.angle,
          orientationType: orientation.type
        },
        timestamp: new Date().toISOString(),
        url: location.href
      };
    }
    var get_environment_data_default = getEnvironmentData;
    function incompleteFallbackMessage() {
      return typeof axe._audit.data.incompleteFallbackMessage === 'function' ? axe._audit.data.incompleteFallbackMessage() : axe._audit.data.incompleteFallbackMessage;
    }
    var incomplete_fallback_msg_default = incompleteFallbackMessage;
    function normalizeRelatedNodes(node, options) {
      [ 'any', 'all', 'none' ].forEach(function(type) {
        if (!Array.isArray(node[type])) {
          return;
        }
        node[type].filter(function(checkRes) {
          return Array.isArray(checkRes.relatedNodes);
        }).forEach(function(checkRes) {
          checkRes.relatedNodes = checkRes.relatedNodes.map(function(relatedNode) {
            var res = {
              html: relatedNode.source
            };
            if (options.elementRef && !relatedNode.fromFrame) {
              res.element = relatedNode.element;
            }
            if (options.selectors !== false || relatedNode.fromFrame) {
              res.target = relatedNode.selector;
            }
            if (options.ancestry) {
              res.ancestry = relatedNode.ancestry;
            }
            if (options.xpath) {
              res.xpath = relatedNode.xpath;
            }
            return res;
          });
        });
      });
    }
    var resultKeys = constants_default.resultGroups;
    function processAggregate(results, options) {
      var resultObject = axe.utils.aggregateResult(results);
      resultKeys.forEach(function(key) {
        if (options.resultTypes && !options.resultTypes.includes(key)) {
          (resultObject[key] || []).forEach(function(ruleResult) {
            if (Array.isArray(ruleResult.nodes) && ruleResult.nodes.length > 0) {
              ruleResult.nodes = [ ruleResult.nodes[0] ];
            }
          });
        }
        resultObject[key] = (resultObject[key] || []).map(function(ruleResult) {
          ruleResult = Object.assign({}, ruleResult);
          if (Array.isArray(ruleResult.nodes) && ruleResult.nodes.length > 0) {
            ruleResult.nodes = ruleResult.nodes.map(function(subResult) {
              if (_typeof(subResult.node) === 'object') {
                subResult.html = subResult.node.source;
                if (options.elementRef && !subResult.node.fromFrame) {
                  subResult.element = subResult.node.element;
                }
                if (options.selectors !== false || subResult.node.fromFrame) {
                  subResult.target = subResult.node.selector;
                }
                if (options.ancestry) {
                  subResult.ancestry = subResult.node.ancestry;
                }
                if (options.xpath) {
                  subResult.xpath = subResult.node.xpath;
                }
              }
              delete subResult.result;
              delete subResult.node;
              normalizeRelatedNodes(subResult, options);
              return subResult;
            });
          }
          resultKeys.forEach(function(key2) {
            return delete ruleResult[key2];
          });
          delete ruleResult.pageLevel;
          delete ruleResult.result;
          return ruleResult;
        });
      });
      return resultObject;
    }
    var process_aggregate_default = processAggregate;
    axe._thisWillBeDeletedDoNotUse = axe._thisWillBeDeletedDoNotUse || {};
    axe._thisWillBeDeletedDoNotUse.helpers = {
      failureSummary: failure_summary_default,
      getEnvironmentData: get_environment_data_default,
      incompleteFallbackMessage: incomplete_fallback_msg_default,
      processAggregate: process_aggregate_default
    };
    var dataRegex = /\$\{\s?data\s?\}/g;
    function substitute(str, data2) {
      if (typeof data2 === 'string') {
        return str.replace(dataRegex, data2);
      }
      for (var prop in data2) {
        if (data2.hasOwnProperty(prop)) {
          var regex = new RegExp('\\${\\s?data\\.' + prop + '\\s?}', 'g');
          var replace = typeof data2[prop] === 'undefined' ? '' : String(data2[prop]);
          str = str.replace(regex, replace);
        }
      }
      return str;
    }
    function processMessage(message, data2) {
      if (!message) {
        return;
      }
      if (Array.isArray(data2)) {
        data2.values = data2.join(', ');
        if (typeof message.singular === 'string' && typeof message.plural === 'string') {
          var str2 = data2.length === 1 ? message.singular : message.plural;
          return substitute(str2, data2);
        }
        return substitute(message, data2);
      }
      if (typeof message === 'string') {
        return substitute(message, data2);
      }
      if (typeof data2 === 'string') {
        var _str = message[data2];
        return substitute(_str, data2);
      }
      var str = message['default'] || incomplete_fallback_msg_default();
      if (data2 && data2.messageKey && message[data2.messageKey]) {
        str = message[data2.messageKey];
      }
      return processMessage(str, data2);
    }
    var process_message_default = processMessage;
    function getCheckMessage(checkId, type, data2) {
      var check4 = axe._audit.data.checks[checkId];
      if (!check4) {
        throw new Error('Cannot get message for unknown check: '.concat(checkId, '.'));
      }
      if (!check4.messages[type]) {
        throw new Error('Check "'.concat(checkId, '"" does not have a "').concat(type, '" message.'));
      }
      return process_message_default(check4.messages[type], data2);
    }
    var get_check_message_default = getCheckMessage;
    function getCheckOption(check4, ruleID, options) {
      var ruleCheckOption = ((options.rules && options.rules[ruleID] || {}).checks || {})[check4.id];
      var checkOption = (options.checks || {})[check4.id];
      var enabled = check4.enabled;
      var opts = check4.options;
      if (checkOption) {
        if (checkOption.hasOwnProperty('enabled')) {
          enabled = checkOption.enabled;
        }
        if (checkOption.hasOwnProperty('options')) {
          opts = checkOption.options;
        }
      }
      if (ruleCheckOption) {
        if (ruleCheckOption.hasOwnProperty('enabled')) {
          enabled = ruleCheckOption.enabled;
        }
        if (ruleCheckOption.hasOwnProperty('options')) {
          opts = ruleCheckOption.options;
        }
      }
      return {
        enabled: enabled,
        options: opts,
        absolutePaths: options.absolutePaths
      };
    }
    var get_check_option_default = getCheckOption;
    function getNodeFromTree(vNode, node) {
      var el = node || vNode;
      return cache_default.get('nodeMap') ? cache_default.get('nodeMap').get(el) : null;
    }
    var get_node_from_tree_default = getNodeFromTree;
    function getRule(ruleId) {
      var rule3 = axe._audit.rules.find(function(rule4) {
        return rule4.id === ruleId;
      });
      if (!rule3) {
        throw new Error('Cannot find rule by id: '.concat(ruleId));
      }
      return rule3;
    }
    var get_rule_default = getRule;
    function getScroll(elm) {
      var buffer = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : 0;
      var overflowX = elm.scrollWidth > elm.clientWidth + buffer;
      var overflowY = elm.scrollHeight > elm.clientHeight + buffer;
      if (!(overflowX || overflowY)) {
        return;
      }
      var style = window.getComputedStyle(elm);
      var overflowXStyle = style.getPropertyValue('overflow-x');
      var overflowYStyle = style.getPropertyValue('overflow-y');
      var scrollableX = overflowXStyle !== 'visible' && overflowXStyle !== 'hidden';
      var scrollableY = overflowYStyle !== 'visible' && overflowYStyle !== 'hidden';
      if (overflowX && scrollableX || overflowY && scrollableY) {
        return {
          elm: elm,
          top: elm.scrollTop,
          left: elm.scrollLeft
        };
      }
    }
    var get_scroll_default = getScroll;
    function getElmScrollRecursive(root) {
      return Array.from(root.children || root.childNodes || []).reduce(function(scrolls, elm) {
        var scroll = get_scroll_default(elm);
        if (scroll) {
          scrolls.push(scroll);
        }
        return scrolls.concat(getElmScrollRecursive(elm));
      }, []);
    }
    function getScrollState() {
      var win = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : window;
      var root = win.document.documentElement;
      var windowScroll = [ win.pageXOffset !== void 0 ? {
        elm: win,
        top: win.pageYOffset,
        left: win.pageXOffset
      } : {
        elm: root,
        top: root.scrollTop,
        left: root.scrollLeft
      } ];
      return windowScroll.concat(getElmScrollRecursive(document.body));
    }
    var get_scroll_state_default = getScrollState;
    function getStyleSheetFactory(dynamicDoc) {
      if (!dynamicDoc) {
        throw new Error('axe.utils.getStyleSheetFactory should be invoked with an argument');
      }
      return function(options) {
        var data2 = options.data, _options$isCrossOrigi = options.isCrossOrigin, isCrossOrigin = _options$isCrossOrigi === void 0 ? false : _options$isCrossOrigi, shadowId = options.shadowId, root = options.root, priority = options.priority, _options$isLink = options.isLink, isLink = _options$isLink === void 0 ? false : _options$isLink;
        var style = dynamicDoc.createElement('style');
        if (isLink) {
          var text32 = dynamicDoc.createTextNode('@import "'.concat(data2.href, '"'));
          style.appendChild(text32);
        } else {
          style.appendChild(dynamicDoc.createTextNode(data2));
        }
        dynamicDoc.head.appendChild(style);
        return {
          sheet: style.sheet,
          isCrossOrigin: isCrossOrigin,
          shadowId: shadowId,
          root: root,
          priority: priority
        };
      };
    }
    var get_stylesheet_factory_default = getStyleSheetFactory;
    var styleSheet;
    function injectStyle(style) {
      if (styleSheet && styleSheet.parentNode) {
        if (styleSheet.styleSheet === void 0) {
          styleSheet.appendChild(document.createTextNode(style));
        } else {
          styleSheet.styleSheet.cssText += style;
        }
        return styleSheet;
      }
      if (!style) {
        return;
      }
      var head = document.head || document.getElementsByTagName('head')[0];
      styleSheet = document.createElement('style');
      styleSheet.type = 'text/css';
      if (styleSheet.styleSheet === void 0) {
        styleSheet.appendChild(document.createTextNode(style));
      } else {
        styleSheet.styleSheet.cssText = style;
      }
      head.appendChild(styleSheet);
      return styleSheet;
    }
    var inject_style_default = injectStyle;
    function isHidden(el, recursed) {
      var node = get_node_from_tree_default(el);
      if (el.nodeType === 9) {
        return false;
      }
      if (el.nodeType === 11) {
        el = el.host;
      }
      if (node && node._isHidden !== null) {
        return node._isHidden;
      }
      var style = window.getComputedStyle(el, null);
      if (!style || !el.parentNode || style.getPropertyValue('display') === 'none' || !recursed && style.getPropertyValue('visibility') === 'hidden' || el.getAttribute('aria-hidden') === 'true') {
        return true;
      }
      var parent = el.assignedSlot ? el.assignedSlot : el.parentNode;
      var hidden = isHidden(parent, true);
      if (node) {
        node._isHidden = hidden;
      }
      return hidden;
    }
    var is_hidden_default = isHidden;
    var htmlTags = [ 'a', 'abbr', 'address', 'area', 'article', 'aside', 'audio', 'b', 'base', 'bdi', 'bdo', 'blockquote', 'body', 'br', 'button', 'canvas', 'caption', 'cite', 'code', 'col', 'colgroup', 'data', 'datalist', 'dd', 'del', 'details', 'dfn', 'dialog', 'div', 'dl', 'dt', 'em', 'embed', 'fieldset', 'figcaption', 'figure', 'footer', 'form', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'head', 'header', 'hgroup', 'hr', 'html', 'i', 'iframe', 'img', 'input', 'ins', 'kbd', 'keygen', 'label', 'legend', 'li', 'link', 'main', 'map', 'mark', 'math', 'menu', 'menuitem', 'meta', 'meter', 'nav', 'noscript', 'object', 'ol', 'optgroup', 'option', 'output', 'p', 'param', 'picture', 'pre', 'progress', 'q', 'rb', 'rp', 'rt', 'rtc', 'ruby', 's', 'samp', 'script', 'section', 'select', 'slot', 'small', 'source', 'span', 'strong', 'style', 'sub', 'summary', 'sup', 'svg', 'table', 'tbody', 'td', 'template', 'textarea', 'tfoot', 'th', 'thead', 'time', 'title', 'tr', 'track', 'u', 'ul', 'var', 'video', 'wbr' ];
    function isHtmlElement(node) {
      if (node.namespaceURI === 'http://www.w3.org/2000/svg') {
        return false;
      }
      return htmlTags.includes(node.nodeName.toLowerCase());
    }
    var is_html_element_default = isHtmlElement;
    function getDeepest(collection) {
      return collection.sort(function(a, b) {
        if (contains_default(a, b)) {
          return 1;
        }
        return -1;
      })[0];
    }
    function isNodeInContext(node, context3) {
      var include = context3.include && getDeepest(context3.include.filter(function(candidate) {
        return contains_default(candidate, node);
      }));
      var exclude = context3.exclude && getDeepest(context3.exclude.filter(function(candidate) {
        return contains_default(candidate, node);
      }));
      if (!exclude && include || exclude && contains_default(exclude, include)) {
        return true;
      }
      return false;
    }
    var is_node_in_context_default = isNodeInContext;
    var memoizee = __toModule(require_memoizee());
    axe._memoizedFns = [];
    function memoizeImplementation(fn) {
      var memoized = memoizee['default'](fn);
      axe._memoizedFns.push(memoized);
      return memoized;
    }
    var memoize_default = memoizeImplementation;
    function parseSameOriginStylesheet(sheet, options, priority, importedUrls) {
      var isCrossOrigin = arguments.length > 4 && arguments[4] !== undefined ? arguments[4] : false;
      var rules = Array.from(sheet.cssRules);
      if (!rules) {
        return Promise.resolve();
      }
      var cssImportRules = rules.filter(function(r) {
        return r.type === 3;
      });
      if (!cssImportRules.length) {
        return Promise.resolve({
          isCrossOrigin: isCrossOrigin,
          priority: priority,
          root: options.rootNode,
          shadowId: options.shadowId,
          sheet: sheet
        });
      }
      var cssImportUrlsNotAlreadyImported = cssImportRules.filter(function(rule3) {
        return rule3.href;
      }).map(function(rule3) {
        return rule3.href;
      }).filter(function(url) {
        return !importedUrls.includes(url);
      });
      var promises = cssImportUrlsNotAlreadyImported.map(function(importUrl, cssRuleIndex) {
        var newPriority = [].concat(_toConsumableArray(priority), [ cssRuleIndex ]);
        var isCrossOriginRequest = /^https?:\/\/|^\/\//i.test(importUrl);
        return parse_crossorigin_stylesheet_default(importUrl, options, newPriority, importedUrls, isCrossOriginRequest);
      });
      var nonImportCSSRules = rules.filter(function(r) {
        return r.type !== 3;
      });
      if (!nonImportCSSRules.length) {
        return Promise.all(promises);
      }
      promises.push(Promise.resolve(options.convertDataToStylesheet({
        data: nonImportCSSRules.map(function(rule3) {
          return rule3.cssText;
        }).join(),
        isCrossOrigin: isCrossOrigin,
        priority: priority,
        root: options.rootNode,
        shadowId: options.shadowId
      })));
      return Promise.all(promises);
    }
    var parse_sameorigin_stylesheet_default = parseSameOriginStylesheet;
    function parseStylesheet(sheet, options, priority, importedUrls) {
      var isCrossOrigin = arguments.length > 4 && arguments[4] !== undefined ? arguments[4] : false;
      var isSameOrigin = isSameOriginStylesheet(sheet);
      if (isSameOrigin) {
        return parse_sameorigin_stylesheet_default(sheet, options, priority, importedUrls, isCrossOrigin);
      }
      return parse_crossorigin_stylesheet_default(sheet.href, options, priority, importedUrls, true);
    }
    function isSameOriginStylesheet(sheet) {
      try {
        var rules = sheet.cssRules;
        if (!rules && sheet.href) {
          return false;
        }
        return true;
      } catch (e) {
        return false;
      }
    }
    var parse_stylesheet_default = parseStylesheet;
    function parseCrossOriginStylesheet(url, options, priority, importedUrls, isCrossOrigin) {
      importedUrls.push(url);
      return new Promise(function(resolve, reject) {
        var request = new XMLHttpRequest();
        request.open('GET', url);
        request.timeout = constants_default.preload.timeout;
        request.addEventListener('error', reject);
        request.addEventListener('timeout', reject);
        request.addEventListener('loadend', function(event) {
          if (event.loaded && request.responseText) {
            return resolve(request.responseText);
          }
          reject(request.responseText);
        });
        request.send();
      }).then(function(data2) {
        var result = options.convertDataToStylesheet({
          data: data2,
          isCrossOrigin: isCrossOrigin,
          priority: priority,
          root: options.rootNode,
          shadowId: options.shadowId
        });
        return parse_stylesheet_default(result.sheet, options, priority, importedUrls, result.isCrossOrigin);
      });
    }
    var parse_crossorigin_stylesheet_default = parseCrossOriginStylesheet;
    var performanceTimer = function() {
      function now() {
        if (window.performance && window.performance) {
          return window.performance.now();
        }
      }
      var originalTime = null;
      var lastRecordedTime = now();
      return {
        start: function start() {
          this.mark('mark_axe_start');
        },
        end: function end() {
          this.mark('mark_axe_end');
          this.measure('axe', 'mark_axe_start', 'mark_axe_end');
          this.logMeasures('axe');
        },
        auditStart: function auditStart() {
          this.mark('mark_audit_start');
        },
        auditEnd: function auditEnd() {
          this.mark('mark_audit_end');
          this.measure('audit_start_to_end', 'mark_audit_start', 'mark_audit_end');
          this.logMeasures();
        },
        mark: function mark(markName) {
          if (window.performance && window.performance.mark !== void 0) {
            window.performance.mark(markName);
          }
        },
        measure: function measure(measureName, startMark, endMark) {
          if (window.performance && window.performance.measure !== void 0) {
            window.performance.measure(measureName, startMark, endMark);
          }
        },
        logMeasures: function logMeasures(measureName) {
          function logMeasure(req2) {
            log_default('Measure ' + req2.name + ' took ' + req2.duration + 'ms');
          }
          if (window.performance && window.performance.getEntriesByType !== void 0) {
            var axeStart = window.performance.getEntriesByName('mark_axe_start')[0];
            var measures = window.performance.getEntriesByType('measure').filter(function(measure) {
              return measure.startTime >= axeStart.startTime;
            });
            for (var i = 0; i < measures.length; ++i) {
              var req = measures[i];
              if (req.name === measureName) {
                logMeasure(req);
                return;
              }
              logMeasure(req);
            }
          }
        },
        timeElapsed: function timeElapsed() {
          return now() - lastRecordedTime;
        },
        reset: function reset() {
          if (!originalTime) {
            originalTime = now();
          }
          lastRecordedTime = now();
        }
      };
    }();
    var performance_timer_default = performanceTimer;
    if (typeof Object.assign !== 'function') {
      (function() {
        Object.assign = function(target) {
          if (target === void 0 || target === null) {
            throw new TypeError('Cannot convert undefined or null to object');
          }
          var output = Object(target);
          for (var index = 1; index < arguments.length; index++) {
            var source = arguments[index];
            if (source !== void 0 && source !== null) {
              for (var nextKey in source) {
                if (source.hasOwnProperty(nextKey)) {
                  output[nextKey] = source[nextKey];
                }
              }
            }
          }
          return output;
        };
      })();
    }
    if (!Array.prototype.find) {
      Object.defineProperty(Array.prototype, 'find', {
        value: function value(predicate) {
          if (this === null) {
            throw new TypeError('Array.prototype.find called on null or undefined');
          }
          if (typeof predicate !== 'function') {
            throw new TypeError('predicate must be a function');
          }
          var list = Object(this);
          var length = list.length >>> 0;
          var thisArg = arguments[1];
          var value;
          for (var i = 0; i < length; i++) {
            value = list[i];
            if (predicate.call(thisArg, value, i, list)) {
              return value;
            }
          }
          return void 0;
        }
      });
    }
    function _pollyfillElementsFromPoint() {
      if (document.elementsFromPoint) {
        return document.elementsFromPoint;
      }
      if (document.msElementsFromPoint) {
        return document.msElementsFromPoint;
      }
      var usePointer = function() {
        var element = document.createElement('x');
        element.style.cssText = 'pointer-events:auto';
        return element.style.pointerEvents === 'auto';
      }();
      var cssProp = usePointer ? 'pointer-events' : 'visibility';
      var cssDisableVal = usePointer ? 'none' : 'hidden';
      var style = document.createElement('style');
      style.innerHTML = usePointer ? '* { pointer-events: all }' : '* { visibility: visible }';
      return function(x, y) {
        var current, i, d;
        var elements = [];
        var previousPointerEvents = [];
        document.head.appendChild(style);
        while ((current = document.elementFromPoint(x, y)) && elements.indexOf(current) === -1) {
          elements.push(current);
          previousPointerEvents.push({
            value: current.style.getPropertyValue(cssProp),
            priority: current.style.getPropertyPriority(cssProp)
          });
          current.style.setProperty(cssProp, cssDisableVal, 'important');
        }
        if (elements.indexOf(document.documentElement) < elements.length - 1) {
          elements.splice(elements.indexOf(document.documentElement), 1);
          elements.push(document.documentElement);
        }
        for (i = previousPointerEvents.length; !!(d = previousPointerEvents[--i]); ) {
          elements[i].style.setProperty(cssProp, d.value ? d.value : '', d.priority);
        }
        document.head.removeChild(style);
        return elements;
      };
    }
    if (typeof window.addEventListener === 'function') {
      document.elementsFromPoint = _pollyfillElementsFromPoint();
    }
    if (!Array.prototype.includes) {
      Object.defineProperty(Array.prototype, 'includes', {
        value: function value(searchElement) {
          var O = Object(this);
          var len = parseInt(O.length, 10) || 0;
          if (len === 0) {
            return false;
          }
          var n = parseInt(arguments[1], 10) || 0;
          var k;
          if (n >= 0) {
            k = n;
          } else {
            k = len + n;
            if (k < 0) {
              k = 0;
            }
          }
          var currentElement;
          while (k < len) {
            currentElement = O[k];
            if (searchElement === currentElement || searchElement !== searchElement && currentElement !== currentElement) {
              return true;
            }
            k++;
          }
          return false;
        }
      });
    }
    if (!Array.prototype.some) {
      Object.defineProperty(Array.prototype, 'some', {
        value: function value(fun) {
          if (this == null) {
            throw new TypeError('Array.prototype.some called on null or undefined');
          }
          if (typeof fun !== 'function') {
            throw new TypeError();
          }
          var t = Object(this);
          var len = t.length >>> 0;
          var thisArg = arguments.length >= 2 ? arguments[1] : void 0;
          for (var i = 0; i < len; i++) {
            if (i in t && fun.call(thisArg, t[i], i, t)) {
              return true;
            }
          }
          return false;
        }
      });
    }
    if (!Array.from) {
      Object.defineProperty(Array, 'from', {
        value: function() {
          var toStr = Object.prototype.toString;
          var isCallable = function isCallable(fn) {
            return typeof fn === 'function' || toStr.call(fn) === '[object Function]';
          };
          var toInteger = function toInteger(value) {
            var number = Number(value);
            if (isNaN(number)) {
              return 0;
            }
            if (number === 0 || !isFinite(number)) {
              return number;
            }
            return (number > 0 ? 1 : -1) * Math.floor(Math.abs(number));
          };
          var maxSafeInteger = Math.pow(2, 53) - 1;
          var toLength = function toLength(value) {
            var len = toInteger(value);
            return Math.min(Math.max(len, 0), maxSafeInteger);
          };
          return function from(arrayLike) {
            var C = this;
            var items = Object(arrayLike);
            if (arrayLike == null) {
              throw new TypeError('Array.from requires an array-like object - not null or undefined');
            }
            var mapFn = arguments.length > 1 ? arguments[1] : void 0;
            var T;
            if (typeof mapFn !== 'undefined') {
              if (!isCallable(mapFn)) {
                throw new TypeError('Array.from: when provided, the second argument must be a function');
              }
              if (arguments.length > 2) {
                T = arguments[2];
              }
            }
            var len = toLength(items.length);
            var A = isCallable(C) ? Object(new C(len)) : new Array(len);
            var k = 0;
            var kValue;
            while (k < len) {
              kValue = items[k];
              if (mapFn) {
                A[k] = typeof T === 'undefined' ? mapFn(kValue, k) : mapFn.call(T, kValue, k);
              } else {
                A[k] = kValue;
              }
              k += 1;
            }
            A.length = len;
            return A;
          };
        }()
      });
    }
    if (!String.prototype.includes) {
      String.prototype.includes = function(search, start) {
        if (typeof start !== 'number') {
          start = 0;
        }
        if (start + search.length > this.length) {
          return false;
        } else {
          return this.indexOf(search, start) !== -1;
        }
      };
    }
    function uniqueArray(arr1, arr2) {
      return arr1.concat(arr2).filter(function(elem, pos, arr) {
        return arr.indexOf(elem) === pos;
      });
    }
    var unique_array_default = uniqueArray;
    function createLocalVariables(vNodes, anyLevel, thisLevel, parentShadowId) {
      var retVal = {
        vNodes: vNodes.slice(),
        anyLevel: anyLevel,
        thisLevel: thisLevel,
        parentShadowId: parentShadowId
      };
      retVal.vNodes.reverse();
      return retVal;
    }
    function matchExpressions(domTree, expressions, filter) {
      var stack = [];
      var vNodes = Array.isArray(domTree) ? domTree : [ domTree ];
      var currentLevel = createLocalVariables(vNodes, expressions, [], domTree[0].shadowId);
      var result = [];
      while (currentLevel.vNodes.length) {
        var vNode = currentLevel.vNodes.pop();
        var childOnly = [];
        var childAny = [];
        var combined = currentLevel.anyLevel.slice().concat(currentLevel.thisLevel);
        var added = false;
        for (var _i7 = 0; _i7 < combined.length; _i7++) {
          var exp = combined[_i7];
          if ((!exp[0].id || vNode.shadowId === currentLevel.parentShadowId) && _matchesExpression(vNode, exp[0])) {
            if (exp.length === 1) {
              if (!added && (!filter || filter(vNode))) {
                result.push(vNode);
                added = true;
              }
            } else {
              var rest = exp.slice(1);
              if ([ ' ', '>' ].includes(rest[0].combinator) === false) {
                throw new Error('axe.utils.querySelectorAll does not support the combinator: ' + exp[1].combinator);
              }
              if (rest[0].combinator === '>') {
                childOnly.push(rest);
              } else {
                childAny.push(rest);
              }
            }
          }
          if ((!exp[0].id || vNode.shadowId === currentLevel.parentShadowId) && currentLevel.anyLevel.includes(exp)) {
            childAny.push(exp);
          }
        }
        if (vNode.children && vNode.children.length) {
          stack.push(currentLevel);
          currentLevel = createLocalVariables(vNode.children, childAny, childOnly, vNode.shadowId);
        }
        while (!currentLevel.vNodes.length && stack.length) {
          currentLevel = stack.pop();
        }
      }
      return result;
    }
    function querySelectorAllFilter(domTree, selector, filter) {
      domTree = Array.isArray(domTree) ? domTree : [ domTree ];
      var expressions = _convertSelector(selector);
      return matchExpressions(domTree, expressions, filter);
    }
    var query_selector_all_filter_default = querySelectorAllFilter;
    function preloadCssom(_ref15) {
      var _ref15$treeRoot = _ref15.treeRoot, treeRoot = _ref15$treeRoot === void 0 ? axe._tree[0] : _ref15$treeRoot;
      var rootNodes = getAllRootNodesInTree(treeRoot);
      if (!rootNodes.length) {
        return Promise.resolve();
      }
      var dynamicDoc = document.implementation.createHTMLDocument('Dynamic document for loading cssom');
      var convertDataToStylesheet = get_stylesheet_factory_default(dynamicDoc);
      return getCssomForAllRootNodes(rootNodes, convertDataToStylesheet).then(function(assets) {
        return flattenAssets(assets);
      });
    }
    var preload_cssom_default = preloadCssom;
    function getAllRootNodesInTree(tree) {
      var ids = [];
      var rootNodes = query_selector_all_filter_default(tree, '*', function(node) {
        if (ids.includes(node.shadowId)) {
          return false;
        }
        ids.push(node.shadowId);
        return true;
      }).map(function(node) {
        return {
          shadowId: node.shadowId,
          rootNode: get_root_node_default(node.actualNode)
        };
      });
      return unique_array_default(rootNodes, []);
    }
    function getCssomForAllRootNodes(rootNodes, convertDataToStylesheet) {
      var promises = [];
      rootNodes.forEach(function(_ref16, index) {
        var rootNode = _ref16.rootNode, shadowId = _ref16.shadowId;
        var sheets = getStylesheetsOfRootNode(rootNode, shadowId, convertDataToStylesheet);
        if (!sheets) {
          return Promise.all(promises);
        }
        var rootIndex = index + 1;
        var parseOptions = {
          rootNode: rootNode,
          shadowId: shadowId,
          convertDataToStylesheet: convertDataToStylesheet,
          rootIndex: rootIndex
        };
        var importedUrls = [];
        var p = Promise.all(sheets.map(function(sheet, sheetIndex) {
          var priority = [ rootIndex, sheetIndex ];
          return parse_stylesheet_default(sheet, parseOptions, priority, importedUrls);
        }));
        promises.push(p);
      });
      return Promise.all(promises);
    }
    function flattenAssets(assets) {
      return assets.reduce(function(acc, val) {
        return Array.isArray(val) ? acc.concat(flattenAssets(val)) : acc.concat(val);
      }, []);
    }
    function getStylesheetsOfRootNode(rootNode, shadowId, convertDataToStylesheet) {
      var sheets;
      if (rootNode.nodeType === 11 && shadowId) {
        sheets = getStylesheetsFromDocumentFragment(rootNode, convertDataToStylesheet);
      } else {
        sheets = getStylesheetsFromDocument(rootNode);
      }
      return filterStylesheetsWithSameHref(sheets);
    }
    function getStylesheetsFromDocumentFragment(rootNode, convertDataToStylesheet) {
      return Array.from(rootNode.children).filter(filerStyleAndLinkAttributesInDocumentFragment).reduce(function(out, node) {
        var nodeName2 = node.nodeName.toUpperCase();
        var data2 = nodeName2 === 'STYLE' ? node.textContent : node;
        var isLink = nodeName2 === 'LINK';
        var stylesheet = convertDataToStylesheet({
          data: data2,
          isLink: isLink,
          root: rootNode
        });
        out.push(stylesheet.sheet);
        return out;
      }, []);
    }
    function getStylesheetsFromDocument(rootNode) {
      return Array.from(rootNode.styleSheets).filter(function(sheet) {
        return filterMediaIsPrint(sheet.media.mediaText);
      });
    }
    function filerStyleAndLinkAttributesInDocumentFragment(node) {
      var nodeName2 = node.nodeName.toUpperCase();
      var linkHref = node.getAttribute('href');
      var linkRel = node.getAttribute('rel');
      var isLink = nodeName2 === 'LINK' && linkHref && linkRel && node.rel.toUpperCase().includes('STYLESHEET');
      var isStyle = nodeName2 === 'STYLE';
      return isStyle || isLink && filterMediaIsPrint(node.media);
    }
    function filterMediaIsPrint(media) {
      if (!media) {
        return true;
      }
      return !media.toUpperCase().includes('PRINT');
    }
    function filterStylesheetsWithSameHref(sheets) {
      var hrefs = [];
      return sheets.filter(function(sheet) {
        if (!sheet.href) {
          return true;
        }
        if (hrefs.includes(sheet.href)) {
          return false;
        }
        hrefs.push(sheet.href);
        return true;
      });
    }
    function preloadMedia(_ref17) {
      var _ref17$treeRoot = _ref17.treeRoot, treeRoot = _ref17$treeRoot === void 0 ? axe._tree[0] : _ref17$treeRoot;
      var mediaVirtualNodes = query_selector_all_filter_default(treeRoot, 'video, audio', function(_ref18) {
        var actualNode = _ref18.actualNode;
        if (actualNode.hasAttribute('src')) {
          return !!actualNode.getAttribute('src');
        }
        var sourceWithSrc = Array.from(actualNode.getElementsByTagName('source')).filter(function(source) {
          return !!source.getAttribute('src');
        });
        if (sourceWithSrc.length <= 0) {
          return false;
        }
        return true;
      });
      return Promise.all(mediaVirtualNodes.map(function(_ref19) {
        var actualNode = _ref19.actualNode;
        return isMediaElementReady(actualNode);
      }));
    }
    var preload_media_default = preloadMedia;
    function isMediaElementReady(elm) {
      return new Promise(function(resolve) {
        if (elm.readyState > 0) {
          resolve(elm);
        }
        function onMediaReady() {
          elm.removeEventListener('loadedmetadata', onMediaReady);
          resolve(elm);
        }
        elm.addEventListener('loadedmetadata', onMediaReady);
      });
    }
    function isValidPreloadObject(preload3) {
      return _typeof(preload3) === 'object' && Array.isArray(preload3.assets);
    }
    function _shouldPreload(options) {
      if (!options || options.preload === void 0 || options.preload === null) {
        return true;
      }
      if (typeof options.preload === 'boolean') {
        return options.preload;
      }
      return isValidPreloadObject(options.preload);
    }
    function _getPreloadConfig(options) {
      var _constants_default$pr = constants_default.preload, assets = _constants_default$pr.assets, timeout = _constants_default$pr.timeout;
      var config = {
        assets: assets,
        timeout: timeout
      };
      if (!options.preload) {
        return config;
      }
      if (typeof options.preload === 'boolean') {
        return config;
      }
      var areRequestedAssetsValid = options.preload.assets.every(function(a) {
        return assets.includes(a.toLowerCase());
      });
      if (!areRequestedAssetsValid) {
        throw new Error('Requested assets, not supported. Supported assets are: '.concat(assets.join(', '), '.'));
      }
      config.assets = unique_array_default(options.preload.assets.map(function(a) {
        return a.toLowerCase();
      }), []);
      if (options.preload.timeout && typeof options.preload.timeout === 'number' && !isNaN(options.preload.timeout)) {
        config.timeout = options.preload.timeout;
      }
      return config;
    }
    function preload(options) {
      var preloadFunctionsMap = {
        cssom: preload_cssom_default,
        media: preload_media_default
      };
      if (!_shouldPreload(options)) {
        return Promise.resolve();
      }
      return new Promise(function(resolve, reject) {
        var _getPreloadConfig2 = _getPreloadConfig(options), assets = _getPreloadConfig2.assets, timeout = _getPreloadConfig2.timeout;
        var preloadTimeout = setTimeout(function() {
          return reject(new Error('Preload assets timed out.'));
        }, timeout);
        Promise.all(assets.map(function(asset) {
          return preloadFunctionsMap[asset](options).then(function(results) {
            return _defineProperty({}, asset, results);
          });
        })).then(function(results) {
          var preloadAssets = results.reduce(function(out, result) {
            return _extends({}, out, result);
          }, {});
          clearTimeout(preloadTimeout);
          resolve(preloadAssets);
        })['catch'](function(err2) {
          clearTimeout(preloadTimeout);
          reject(err2);
        });
      });
    }
    var preload_default = preload;
    function getIncompleteReason(checkData, messages) {
      function getDefaultMsg(messages2) {
        if (messages2.incomplete && messages2.incomplete['default']) {
          return messages2.incomplete['default'];
        } else {
          return incomplete_fallback_msg_default();
        }
      }
      if (checkData && checkData.missingData) {
        try {
          var msg = messages.incomplete[checkData.missingData[0].reason];
          if (!msg) {
            throw new Error();
          }
          return msg;
        } catch (e) {
          if (typeof checkData.missingData === 'string') {
            return messages.incomplete[checkData.missingData];
          } else {
            return getDefaultMsg(messages);
          }
        }
      } else if (checkData && checkData.messageKey) {
        return messages.incomplete[checkData.messageKey];
      } else {
        return getDefaultMsg(messages);
      }
    }
    function extender(checksData, shouldBeTrue) {
      return function(check4) {
        var sourceData = checksData[check4.id] || {};
        var messages = sourceData.messages || {};
        var data2 = Object.assign({}, sourceData);
        delete data2.messages;
        if (check4.result === void 0) {
          if (_typeof(messages.incomplete) === 'object' && !Array.isArray(check4.data)) {
            data2.message = getIncompleteReason(check4.data, messages);
          }
          if (!data2.message) {
            data2.message = messages.incomplete;
          }
        } else {
          data2.message = check4.result === shouldBeTrue ? messages.pass : messages.fail;
        }
        if (typeof data2.message !== 'function') {
          data2.message = process_message_default(data2.message, check4.data);
        }
        extend_meta_data_default(check4, data2);
      };
    }
    function publishMetaData(ruleResult) {
      var checksData = axe._audit.data.checks || {};
      var rulesData = axe._audit.data.rules || {};
      var rule3 = find_by_default(axe._audit.rules, 'id', ruleResult.id) || {};
      ruleResult.tags = clone_default(rule3.tags || []);
      var shouldBeTrue = extender(checksData, true);
      var shouldBeFalse = extender(checksData, false);
      ruleResult.nodes.forEach(function(detail) {
        detail.any.forEach(shouldBeTrue);
        detail.all.forEach(shouldBeTrue);
        detail.none.forEach(shouldBeFalse);
      });
      extend_meta_data_default(ruleResult, clone_default(rulesData[ruleResult.id] || {}));
    }
    var publish_metadata_default = publishMetaData;
    function querySelectorAll(domTree, selector) {
      return query_selector_all_filter_default(domTree, selector);
    }
    var query_selector_all_default = querySelectorAll;
    function matchTags(rule3, runOnly) {
      var include, exclude, matching;
      var defaultExclude = axe._audit && axe._audit.tagExclude ? axe._audit.tagExclude : [];
      if (runOnly.hasOwnProperty('include') || runOnly.hasOwnProperty('exclude')) {
        include = runOnly.include || [];
        include = Array.isArray(include) ? include : [ include ];
        exclude = runOnly.exclude || [];
        exclude = Array.isArray(exclude) ? exclude : [ exclude ];
        exclude = exclude.concat(defaultExclude.filter(function(tag) {
          return include.indexOf(tag) === -1;
        }));
      } else {
        include = Array.isArray(runOnly) ? runOnly : [ runOnly ];
        exclude = defaultExclude.filter(function(tag) {
          return include.indexOf(tag) === -1;
        });
      }
      matching = include.some(function(tag) {
        return rule3.tags.indexOf(tag) !== -1;
      });
      if (matching || include.length === 0 && rule3.enabled !== false) {
        return exclude.every(function(tag) {
          return rule3.tags.indexOf(tag) === -1;
        });
      } else {
        return false;
      }
    }
    function ruleShouldRun(rule3, context3, options) {
      var runOnly = options.runOnly || {};
      var ruleOptions = (options.rules || {})[rule3.id];
      if (rule3.pageLevel && !context3.page) {
        return false;
      } else if (runOnly.type === 'rule') {
        return runOnly.values.indexOf(rule3.id) !== -1;
      } else if (ruleOptions && typeof ruleOptions.enabled === 'boolean') {
        return ruleOptions.enabled;
      } else if (runOnly.type === 'tag' && runOnly.values) {
        return matchTags(rule3, runOnly.values);
      } else {
        return matchTags(rule3, []);
      }
    }
    var rule_should_run_default = ruleShouldRun;
    function attributeMatches(node, attrName, filterAttrs) {
      if (typeof filterAttrs[attrName] === 'undefined') {
        return false;
      }
      if (filterAttrs[attrName] === true) {
        return true;
      }
      return element_matches_default(node, filterAttrs[attrName]);
    }
    function filterHtmlAttrs(element, filterAttrs) {
      if (!filterAttrs) {
        return element;
      }
      var node = element.cloneNode(false);
      var outerHTML = node.outerHTML;
      var attributes4 = get_node_attributes_default(node);
      if (cache_default.get(outerHTML)) {
        node = cache_default.get(outerHTML);
      } else if (attributes4) {
        node = document.createElement(node.nodeName);
        Array.from(attributes4).forEach(function(attr) {
          if (!attributeMatches(element, attr.name, filterAttrs)) {
            node.setAttribute(attr.name, attr.value);
          }
        });
        cache_default.set(outerHTML, node);
      }
      Array.from(element.childNodes).forEach(function(child) {
        node.appendChild(filterHtmlAttrs(child, filterAttrs));
      });
      return node;
    }
    var filter_html_attrs_default = filterHtmlAttrs;
    function pushNode(result, nodes) {
      var temp;
      if (result.length === 0) {
        return nodes;
      }
      if (result.length < nodes.length) {
        temp = result;
        result = nodes;
        nodes = temp;
      }
      for (var _i8 = 0, l = nodes.length; _i8 < l; _i8++) {
        if (!result.includes(nodes[_i8])) {
          result.push(nodes[_i8]);
        }
      }
      return result;
    }
    function reduceIncludes(includes) {
      return includes.reduce(function(res, el) {
        if (!res.length || !contains_default(res[res.length - 1], el)) {
          res.push(el);
        }
        return res;
      }, []);
    }
    function select(selector, context3) {
      var result = [];
      var candidate;
      if (axe._selectCache) {
        for (var j = 0, l = axe._selectCache.length; j < l; j++) {
          var item = axe._selectCache[j];
          if (item.selector === selector) {
            return item.result;
          }
        }
      }
      var curried = function(context4) {
        return function(node) {
          return is_node_in_context_default(node, context4);
        };
      }(context3);
      var reducedIncludes = reduceIncludes(context3.include);
      for (var _i9 = 0; _i9 < reducedIncludes.length; _i9++) {
        candidate = reducedIncludes[_i9];
        result = pushNode(result, query_selector_all_filter_default(candidate, selector, curried));
      }
      if (axe._selectCache) {
        axe._selectCache.push({
          selector: selector,
          result: result
        });
      }
      return result;
    }
    var select_default = select;
    function setScroll(elm, top, left) {
      if (elm === window) {
        return elm.scroll(left, top);
      } else {
        elm.scrollTop = top;
        elm.scrollLeft = left;
      }
    }
    function setScrollState(scrollState) {
      scrollState.forEach(function(_ref21) {
        var elm = _ref21.elm, top = _ref21.top, left = _ref21.left;
        return setScroll(elm, top, left);
      });
    }
    var set_scroll_state_default = setScrollState;
    function tokenList(str) {
      return (str || '').trim().replace(/\s{2,}/g, ' ').split(' ');
    }
    var token_list_default = tokenList;
    function validInputTypes() {
      return [ 'hidden', 'text', 'search', 'tel', 'url', 'email', 'password', 'date', 'month', 'week', 'time', 'datetime-local', 'number', 'range', 'color', 'checkbox', 'radio', 'file', 'submit', 'image', 'reset', 'button' ];
    }
    var valid_input_type_default = validInputTypes;
    var langs = [ , [ , [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, , 1 ], [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ , 1, 1, , 1, 1, 1, , 1, 1, , 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ , 1, 1, , 1, 1, 1, 1, 1, 1, 1, , 1, , 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1 ], [ 1, 1, 1, 1, 1, 1, , , , , , 1, 1, 1, 1, , , 1, 1, 1, , 1, , 1, , 1, 1 ], [ 1, 1, 1, , 1, 1, , 1, 1, 1, , 1, , , 1, 1, 1, , , 1, 1, 1, , , , , 1 ], [ , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ , 1, 1, , , , , 1, 1, 1, , 1, 1, 1, 1, 1, 1, , 1, 1, 1 ], [ , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , , 1, 1, 1 ], [ , 1, , , , , , 1, , 1, , , , , 1, , 1, , , , 1, 1, , 1, , , 1 ], [ 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ , 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ 1, 1, 1, 1, , 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , , , 1, 1, 1, 1, , , 1, , 1 ], [ , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ , 1, , 1, 1, , , 1, , , , , 1, 1, 1, , 1, , 1, , 1, , , , , , 1 ], [ 1, , 1, 1, 1, 1, , , 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ , 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1 ], [ 1, , 1, , 1, , , , , 1, , 1, 1, 1, 1, 1, , , , 1, 1, 1, 1 ], [ , 1, 1, 1, 1, 1, , 1, 1, 1, , 1, , 1, 1, 1, , , 1, 1, 1, 1, 1, 1, 1, 1 ], [ , , 1, , , 1, , 1, , , , 1, 1, 1, , , , , , , , , , , 1 ], [ 1, 1, 1, 1, 1, 1, , 1, 1, 1, , 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, , , 1, 1, 1 ], [ 1, 1, 1, 1, 1, , , 1, , , 1, , , 1, 1, 1, , , , , 1, , , , , , 1 ] ], [ , [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, , 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1 ], [ , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1 ], [ 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ 1, 1, 1, 1, 1, 1, 1, 1, , , 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1 ], [ , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ , 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1 ], [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ 1, 1, 1, , , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1 ], [ , 1, 1, , 1, , , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ , 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1 ], [ , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1 ], [ , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1 ], [ , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, , 1 ], [ , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1 ], [ , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ] ], [ , [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1 ], [ , 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, , 1, 1, , 1, 1, 1, 1, 1, 1, 1, , 1 ], [ , 1, , 1, 1, 1, , 1, 1, , 1, , 1, 1, 1, 1, 1, 1, 1, 1 ], [ , 1, , 1, 1, 1, 1, 1, 1, 1, 1, , , 1, 1, 1, , , 1, 1, , , , , , 1, 1 ], [ 1, 1, 1, , , , , 1, , , , 1, 1, , 1, , , , , , 1, , , , , 1 ], [ , 1, , , 1, , , 1, , , , , , 1 ], [ , 1, , 1, , , , 1, , , , 1 ], [ 1, , 1, 1, 1, , 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, , , 1, 1, 1, 1 ], [ , 1, 1, 1, 1, 1, , , 1, , , 1, , 1, 1, , 1, , 1, , , , , 1, , 1 ], [ , 1, , , , 1, , , 1, 1, , 1, , 1, 1, 1, 1, , 1, 1, , , 1, , , 1 ], [ , 1, 1, , , , , , 1, , , , 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, , 1, 1, 1 ], [ , 1, , 1, 1, 1, , , 1, 1, 1, 1, 1, 1, , 1, , , , , 1, 1, , 1, , 1 ], [ , 1, , 1, , 1, , 1, , 1, , 1, 1, 1, 1, 1, , , 1, 1, 1 ], [ , 1, 1, 1, , , , 1, 1, 1, , 1, 1, , , 1, 1, , 1, 1, 1, 1, , 1, 1 ], [ 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, , , 1, 1, 1, 1, 1, 1, 1 ], [ , 1, 1, 1, , 1, 1, 1, , 1, , , , , 1, 1, 1, , , 1, , 1, , , 1, 1 ], [ , , , , 1, , , , , , , , , , , , , , , , , 1 ], [ 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1 ], [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1 ], [ , 1, , 1, 1, 1, , 1, 1, , , , 1, 1, 1, 1, 1, , , 1, 1, 1, , , , , 1 ], [ 1, 1, 1, 1, , , , 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ 1, , , , , , , 1, , , , , , , 1 ], [ , 1, 1, , 1, 1, , 1, , , , , , , , , , , , , 1 ], , [ 1, 1, 1, , , , , , , , , , , , , 1 ], [ , , , , , , , , 1, , , 1, , , 1, 1, , , , , 1 ] ], [ , [ 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1 ], [ , 1, 1, , 1, 1, 1, 1, , 1, 1, , 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, , 1 ], [ , , , 1, , , , , , , , , , , , , , , 1 ], [ , 1, , , 1, 1, , 1, , 1, 1, , , , 1, 1, , , 1, 1, , , , 1 ], [ 1, , , 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, , 1, 1, 1, 1, , , 1, , , , 1 ], , [ , 1, 1, 1, 1, 1, , 1, 1, 1, , 1, 1, , 1, 1, , , 1, 1, 1, 1, , 1, 1, , 1 ], [ , 1, , , 1, , , 1, , 1, , , 1, 1, 1, 1, , , 1, 1, , 1, 1, 1, 1 ], [ , 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1 ], [ , 1, 1, 1, 1, 1, 1, , , 1, 1, 1, 1, 1, 1, 1, , , 1, , , 1, , 1 ], [ , 1, , , , , , , , , , 1, 1, , , , , , 1, 1, , , , , 1 ], [ , , , , , , , 1, , , , 1, , 1, 1 ], [ , 1, 1, 1, 1, 1, 1, 1, , , , 1, 1, 1, 1, 1, , , 1, 1, , 1, 1, 1, 1, 1 ], [ , 1, , , 1, 1, , 1, , 1, 1, 1, , , 1, 1, , , 1, , 1, 1, 1, 1, , 1 ], [ , 1, 1, 1, , 1, 1, , 1, 1, , 1, 1, , 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1 ], [ , , , , , , , , , , , , , , , , 1 ], , [ , 1, 1, 1, 1, 1, , 1, 1, 1, , , 1, , 1, 1, , 1, 1, 1, 1, 1, , 1, , 1 ], [ , , 1, , , 1, , , 1, 1, , , 1, , 1, 1, , 1 ], [ , 1, 1, , 1, , , , 1, 1, , 1, , 1, 1, 1, 1, , 1, 1, 1, 1, , , , 1 ], [ , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1 ], [ 1, 1 ], [ , 1, , , , , , , , , , 1, 1, , , , , , 1, 1, , 1, , 1, , 1, 1 ], , [ , 1, 1, , 1, , , 1, , 1, , , , 1, 1, 1, , , , , , 1, , , , 1 ], [ 1, 1, , , 1, 1, , 1, , , , , 1, , 1 ] ], [ , [ , 1 ], [ , , , 1, , , , 1, , , , 1, , , , 1, , , 1, , , 1 ], [ , , , , , , , , , , , , , , , , , , 1, 1, , , , , , 1 ], , [ 1, , , , , 1 ], [ , 1, , , , 1, , , , 1 ], [ , 1, , , , , , , , , , , 1, , , 1, , , , , , , , , 1, 1 ], [ , , , , , , , , , , , , , , , , , , , , , 1 ], [ , , , , , , , , , , , , , , , , 1, , , , 1, , 1 ], [ , 1 ], [ , 1, , 1, , 1, , 1, , 1, , 1, 1, 1, , 1, 1, , 1, , , , , , , 1 ], [ 1, , , , , 1, , , 1, 1, , 1, , 1, , 1, 1, , , , , 1, , , 1 ], [ , 1, 1, , , 1, , 1, , 1, , 1, , 1, 1, 1, 1, , , 1, , 1, , 1, 1, 1 ], [ 1, 1, 1, 1, 1, , 1, , 1, , , , 1, 1, 1, 1, , 1, 1, , , 1, 1, 1, 1 ], [ 1, , , , , , , , , , , , , , , , , , , , 1 ], [ , , , , , , , , , 1 ], , [ , 1, , , , , , 1, 1, 1, , 1, , , , 1, , , 1, 1, 1, , , 1 ], [ 1, , , , , 1, , 1, 1, 1, , 1, 1, 1, 1, 1, , 1, , 1, , 1, , , 1, 1 ], [ 1, , 1, 1, , , , , 1, , , , , , 1, 1, , , 1, 1, 1, 1, , , 1, , 1 ], [ 1, , , , , , , , , , , , , , , , , 1 ], [ , , , , , 1, , , 1, , , , , , 1 ], [ , , , , , , , , , , , , , , , 1 ], [ , , , , , , , , , , , , , , , , , , , , 1 ], [ , 1, , , , , , , , , , , , , , 1 ], [ , 1, , , , 1 ] ], [ , [ 1, 1, 1, , 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, , 1, , 1, 1, , , 1, 1, 1 ], [ , , , , , , , , , , , , 1 ], [ , , , , , , , , , , , , , , , , , , , 1 ], , [ , , , , , , , , , , , , , , , , , , 1 ], [ 1, , , , , , , , , 1, , , , 1 ], [ , , , , , , , , , , , , , , , , , , 1 ], , [ 1, 1, , , , 1, 1, , , , , , 1, , , , 1, , 1, , 1, 1, , 1 ], [ 1 ], [ , , , , , , , , , , , 1, , , , , , , , , , , 1 ], [ , 1, , , , , , , 1, 1, , , 1, , 1, , , , 1, , , , , , , 1 ], [ , , , , , , , , , , , , , , , , 1, , , , , 1 ], [ , , 1, , , , , 1, , 1 ], [ 1, , , , 1, , , , , 1, , , , 1, 1, , , , 1, 1, , , , , 1 ], [ , , , , , 1 ], [ , , , , , , , , , , , , , , , , , , , 1 ], [ 1, , , 1, 1, , , , , , , 1, , 1, , 1, 1, 1, 1, 1, 1 ], [ , , , , , 1, , , , , , , 1, , , , , , , 1 ], , [ , , 1, 1, 1, 1, 1, , 1, 1, 1, , , 1, 1, , , 1, 1, , 1, 1, 1, , , 1 ], [ , , , , , , , , , , , , , , , , , , 1 ], [ , 1, , , , 1 ], , [ 1 ] ], [ , [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1 ], [ , , , 1, 1, 1, 1, , , , , , 1, , 1, , , , 1, , 1 ], [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, , , 1 ], [ , 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, , , , 1, , 1, , , 1, 1, 1, 1, 1 ], [ , , , , , , , , , , , 1, , , , , , , , , 1, , , , 1 ], [ , 1, 1, , 1, 1, , 1, , , , 1, 1, , 1, 1, , , 1, , 1, 1, , 1 ], [ , 1, , 1, , 1, , , 1, , , 1, 1, , 1, 1, , , 1, 1, 1 ], [ , 1, 1, 1, 1, 1, , 1, 1, , , , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1 ], [ , , , , , , , , , 1, , 1, , 1, 1, , , , 1, , , 1 ], [ , 1, , , 1, 1, , , , , , , , , 1, 1, 1, , , , , 1 ], [ 1, , , 1, 1, , , , 1, 1, 1, 1, 1, , , 1, , , 1, , , 1, , 1, , 1 ], [ , 1, 1, , 1, 1, , 1, 1, , , , 1, 1, 1, , , 1, 1, , , 1, 1, 1, 1, 1, 1 ], [ 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, , 1, 1, , 1, , , 1 ], [ , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1 ], [ , 1, , , , 1, , , , , , , , , 1 ], [ , 1, , , , , , , , 1, , , , , 1, , , , 1, , , 1 ], [ , 1, 1, 1, 1, , , 1, 1, 1, 1, 1, , 1, , 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ , , , , , 1, , 1, , , , , 1, 1, 1, 1, 1, , , 1, , , , 1 ], [ , 1, , , , , , , , 1, , , , , , , , , , , , 1 ], [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1 ], [ 1, 1, , 1, , 1, 1, , , , 1, , 1, 1, 1, 1, 1, , 1, 1, , , , , , 1 ], [ , 1, 1, 1, 1, 1, 1, 1, , 1, 1, , , 1, 1, , , , 1, , 1, 1, , 1, 1 ], [ , , , , , , , , , , , , , , , , , , , , , , , , 1 ], [ , 1, 1, , 1, 1, 1, 1, , 1, , , 1, 1, 1, 1, , , 1, , , , , , , 1 ], [ , 1, , , , , , , , 1, , , , , 1 ] ], [ , [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , , 1, 1, 1, 1, 1 ], [ , 1, 1, , , , , , , , , , , , 1, 1, , , , , , 1 ], [ , 1, , , , , , , 1 ], [ , , , , , , , , , , , , , , 1, , , , , 1, , , , , , 1 ], [ 1, 1, , , 1, , , 1, 1, 1, , , , 1 ], , [ , , , , , , , , , , , , , 1, , , , , , , , , , 1 ], [ , , , , , , , , , 1, , , , , , , , , 1, , , , , , , 1 ], [ 1, 1, 1, , 1, , 1, 1, 1, 1, 1, 1, 1, 1, , 1, , , 1, , 1, , , 1, 1 ], [ , , , , , , , , , 1 ], [ , 1, , , , 1, , , , , , 1, , , 1, , , , , 1 ], [ , 1, 1, , 1, 1, , , , , , , , , , , , , , , 1, 1 ], [ , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ , 1, , , 1, 1, , 1, 1, 1, 1, , , , 1, 1, , , , 1, , 1 ], [ 1, 1, 1, 1, 1, 1, , , 1, 1, 1, 1, 1, 1, , 1, 1, , 1, 1, 1, , 1, 1, , 1, 1 ], [ , , , , , , , , , , , , , , , 1, , , , 1 ], , [ 1, 1, , 1, , 1, , , , , , 1, , 1, , 1, 1, , 1, , 1, 1, , 1, 1, , 1 ], [ , , 1, , , , , , 1, , , , 1, , 1, , , , , 1 ], [ 1, , , , , , , , , 1, , , , , , 1, , , , 1, , 1, , , 1 ], [ 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ , , , 1, , 1, , , , , , 1, , , 1, , , , , , , , 1 ], [ , 1, , 1, , , , , , , , , , , , 1 ], , [ 1, 1, , , , , , , , , , , , , , , , , , , , , , 1, 1 ], [ 1 ] ], [ , [ 1, , , , , , , , , 1, , , , , 1, , 1, , 1 ], [ , 1, 1, , 1, 1, , 1, 1, 1, , , 1, 1, 1, , , , 1, , , 1, , , , 1 ], [ , 1, , , , , , , 1, , , , 1, , , , , , 1 ], [ 1, 1, 1, 1, 1, 1, , , , 1, , , , , , , , , 1, 1, 1, 1 ], [ 1 ], [ , 1, 1, , , 1, 1, , , , , 1, , 1, , , , , , , , 1, , , , 1 ], [ 1, , 1, , , 1, , 1, , , , , 1, 1, 1, 1, , , , 1, , , , 1 ], [ , , 1, , , , , , , 1, , , , , , , 1, , , , , , , 1 ], [ 1, , , , , , , , , , , , , , 1, , , , 1 ], [ , , , 1, , 1, , , , , 1, , , , 1, 1, , , , 1 ], [ 1, , , , , 1, , , , 1, , 1, 1, , , 1, 1, , 1, 1, 1, , 1, 1, 1, , 1 ], [ , 1, 1, , , , , 1, , 1, , 1, 1, 1, , 1, 1, , , 1, , 1, 1, 1 ], [ , 1, , , , 1, , , , 1, , , 1, , 1, 1, , , 1, 1, , , , , , 1 ], [ 1, , 1, 1, , 1, , 1, 1, , 1, , 1, 1, 1, 1, 1, , , 1, 1, , , , , , 1 ], [ 1, , , , , , , , , , , , , , , , , , 1, , , 1, , 1 ], [ , , , , , , , , , 1, , , , , , 1 ], [ , , , , , , , , , , , , , , , , , , , , , 1, , 1 ], [ , 1, , , , 1, , , 1, 1, , 1, , , 1, 1, , , 1, , , 1, , , 1, 1 ], [ 1, 1, , 1, 1, 1, , 1, 1, 1, , 1, , 1, 1, 1, , , 1, , 1, 1 ], [ 1, , 1, 1, 1, 1, , , , 1, , 1, 1, 1, , 1, , , 1, 1, 1, , 1, 1, 1, 1, 1 ], [ 1, , , , , , , , , , , , , 1 ], [ , , 1, , , , , , , , , , , , , , , , , , , , 1 ], [ 1, , , , , , , , , , , 1, , 1, , 1, , , , 1 ], [ , , , 1, , , , , , , , , 1 ], [ , 1, , , , , , , , , , , , , , 1, , , , , , , , , 1 ], [ , , , , , , , , 1, 1, , , , , , , , , 1, , , , , , , , 1 ] ], [ , [ 1, 1, 1, 1, 1, 1, 1, , 1, , 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, , , 1, 1, 1 ], [ , , , , , 1, , , , 1, 1, 1, , , 1, 1, , , 1, , 1, 1, , 1 ], [ , , , , , , , , , , , , , , , , , , , 1, 1 ], [ , 1, , , , , , 1, , , , , , , , , , , , , 1 ], [ , , 1, , , 1, , 1, 1, 1, , 1, 1, , 1, , , , 1, , 1, 1 ], , [ , , 1, , , 1, , , , , , 1, , , , 1 ], [ , , , , , , , , , 1, , , , , , , , , , 1 ], [ 1, 1, 1, 1, 1, 1, , 1, 1, 1, , , 1, 1, , 1, , 1, , , 1, 1, 1, , , 1 ], [ , , , , , 1, , , , , , , , , , , , , 1 ], [ , 1, , , , , , , , , , , , 1, , 1, 1, , 1, , , 1 ], [ , , , , , 1, , , , , , , , , , , , , , 1 ], [ , 1, 1, 1, 1, , , , , 1, , , 1, , 1, , , , 1, 1, , , , 1, 1 ], [ , 1, , , 1, , , 1, , 1, 1, , 1, , , , , , , 1 ], [ , , 1, , 1, , , 1, , , , , , , , , , , 1, 1, , , , 1 ], [ , 1, , , , , , , , , , , , , , , , , 1, , , , , , 1 ], [ , , , , , , , , , , , , , , , , , , 1 ], [ , 1, 1, , , , , , , , , , , , , , , , 1, , 1, 1 ], [ , , , , , , , , , , , , 1 ], , [ , 1, 1, 1, 1, , , , 1, 1, , 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, , 1, , 1 ], [ 1, , , , 1, , , , , , , , , , 1 ], [ 1, , , , , , , , , 1 ], , [ , 1, , , , 1, , , , , , , , , , , , , , , , , , , , 1 ] ], [ , [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, , 1, 1, 1, 1, , , , 1, 1, 1, 1 ], [ , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ , 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1 ], [ , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, , 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1 ], [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1 ], [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , , 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1 ], [ , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1 ], [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ , 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ] ], [ , [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, , 1, , 1, 1, 1, 1 ], [ 1, 1, 1, 1, , 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ , , , 1, 1, 1, 1, , 1, , , , 1, 1, , , 1, 1, , 1 ], [ , 1, 1, , 1, , , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ , 1, , , , , , , , , , , , , 1 ], [ 1, 1, 1, , , , , 1, 1, 1, , 1, 1, 1, 1, , , 1, 1, , 1, 1, , , , , 1 ], [ , 1, , , , , , , 1, 1, , , 1, 1, 1, , 1, , , 1, 1, 1 ], [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , , 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1 ], [ , 1, , , , 1, , , , 1, , , 1, , , , 1, , , , , , , 1, 1 ], [ , 1, 1, 1, 1, 1, , , 1, 1, 1, , 1, 1, 1, 1, , , 1, 1, 1, 1, , , , 1 ], [ , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, , 1, , , 1 ], [ , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , , 1, 1, 1, 1, 1, 1 ], [ 1, 1, 1, , 1, , , 1, 1, 1, 1, , 1, 1, 1, 1, , , , 1, , 1, , 1, , , 1 ], [ 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ , 1, , , , 1, , , , , , , , , 1, 1, , , , , , , , , 1 ], , [ , 1, , 1, , 1, , 1, , 1, , 1, 1, 1, 1, 1, , , 1, , 1, , 1, , , , 1 ], [ , 1, , , 1, 1, , 1, 1, 1, , , 1, 1, 1, 1, 1, , 1, 1, 1, , 1, , , 1 ], [ 1, , , 1, , , , 1, 1, 1, , , , , 1, 1, , , , 1, , 1 ], [ 1, 1, , 1, 1, 1, 1, , , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1 ], [ 1, 1, , , , , , , , 1, , 1, , , , , , , , 1, , 1 ], [ , 1, , , , 1, , 1, 1, , , , 1, 1, , 1, , , , 1, 1, 1, , 1 ], , [ , 1, , , , , , 1, , , , , , , 1 ], [ , , , , , , , , 1, , , , 1, , 1, , , , , , , , , , , , 1 ] ], [ , [ , 1, 1, , 1, 1, 1, 1, , 1, 1, 1, , 1, 1, , 1, 1, , 1, 1, 1, 1, 1, 1, , 1 ], [ , 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1 ], [ , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1 ], [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1 ], [ , 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, , 1 ], [ , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1 ], [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ , 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ , 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ , 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1 ], [ , 1, 1, , 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ , 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ] ], [ , [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , , 1, 1, 1, 1 ], [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , , 1, , 1 ], [ 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ , 1, , , 1, , , , , , , , 1, , , , , , 1, , , 1 ], [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ , 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, , 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1 ], [ , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ , 1, 1, , 1, , , , 1, 1, 1, , 1, 1, 1, 1, , , 1, 1, 1, 1, , , 1, 1, 1 ], [ , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1 ], [ 1, 1, , 1, , 1, , 1, , 1, 1, 1, 1, 1, 1, 1, , 1, 1, , , 1, 1, 1, 1, 1, 1 ], [ , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, , 1, 1 ], [ , 1, 1, , , , , 1, 1, 1, , , 1, , 1, 1, , , , 1, , 1, , , 1, 1 ], [ , , , , , , , 1, , , , 1, 1, 1, 1, 1, , 1, , , , , , , , 1 ], [ 1, 1, 1, 1, , 1, 1, 1, , 1, , 1, 1, 1, 1, , 1, , 1, , 1, 1, , , 1, , 1 ], [ , 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ , , , , 1, 1, , 1, , 1, 1, 1, , 1, , 1, 1, , 1, 1, , 1, , 1, 1, 1, 1 ], [ , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ 1, , , , , , , , 1, , , , , 1, , 1 ], [ , 1, 1, 1, , 1, , 1, , 1, , , , 1, , 1, , , 1, , , , , , 1, 1 ], [ , 1, , , 1, 1, , 1, , 1, , 1, 1, 1, 1, 1, , 1, 1, , , 1, , , 1 ], [ 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ , 1, 1, , 1, , , , , 1, , 1, , 1, , , , , , 1, , 1, , , , 1, 1 ] ], [ , [ , 1, , 1, , , , , , , , , , , , , , , 1, , , , 1 ], [ , , , , , , , , , 1, , 1, 1, 1, , 1, , , 1, , 1, 1 ], [ 1, 1, , , , , , , 1, , , , , , , 1, , , , , , 1 ], [ , 1, , , , , , , , , , 1, , , , , , , , , 1, 1 ], , [ , , , , , , , , , , , , , , , 1, , , , 1, , 1 ], [ , , 1, 1, , 1, , 1, , , , , , , , 1, , , , , , 1 ], [ , , , , , , , , , , , , , , , , , , , , 1, 1 ], [ , 1, , , , , , , , , , , , , 1 ], [ 1, , 1, 1, , , , 1, , , , , , , , , 1, , , 1, , , 1, 1 ], [ , 1, 1, , 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, , , 1, 1, , 1, 1, , 1 ], [ , 1, , , 1, 1, , , , , , 1, , 1, , 1, , , 1, , 1, 1 ], [ 1, 1, 1, 1, , 1, , 1, , 1, , 1, 1, , 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1 ], [ , 1, 1, , , 1, , 1, , 1, 1, 1, , , 1, 1, 1, , 1, 1, 1, 1, , 1, 1 ], [ , , , , 1, , , 1, , , , , , , 1, , , , 1, 1 ], [ , 1, , , , , , , , , , 1, , 1, , 1, , , , , 1, , , , , 1 ], , [ 1, 1, , 1, , 1, , 1, 1, , , , , , 1, 1, , , 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ 1, 1, , 1, , , , , , 1, , , , , , 1, 1, , , , 1, 1, , , 1 ], [ , 1, 1, , 1, 1, , , , 1, , 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, , 1, 1, 1, 1 ], [ , 1, 1, , , 1, , , , 1, , , , 1, 1 ], [ , , , , 1 ], [ , , , , , , , , , 1, , , 1 ], , [ , , 1, , 1, , , , , , , , , 1, , , , , , , , , , , , 1 ], [ , , , , , , , , , , , , , 1 ] ], [ , [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ , , 1, 1, , 1, 1, 1, 1, 1, , , 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, , , 1, 1 ], [ , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, , 1, , , , , 1 ], [ , 1, , 1, , , , , , 1, , , , , 1, 1, , , , , 1, 1 ], [ , 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, , 1, , , 1, , 1, 1, 1 ], [ , 1, , , , 1, , , , , , , 1 ], [ , 1, , , 1, , , 1, , 1, , 1, 1, , 1, , , , , 1, , 1, , , , 1, 1 ], [ , 1, , , 1, , , 1, 1, 1, , 1, 1, 1, 1, 1, , 1, 1, , 1, 1, 1, 1 ], [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ , , , , , , , , , , , , , , , , , , , , 1 ], [ , 1, 1, 1, , , , 1, 1, , , , , , 1, 1, 1, , 1, 1, 1, 1 ], [ 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1 ], [ , 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, , 1, 1, 1, 1 ], [ , 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ , , , 1, 1, 1, 1, 1, 1, 1, , 1, , 1, 1, 1, 1, 1, , 1, 1, , 1, 1, 1, 1, 1 ], [ , 1, , , , 1, , , , 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ , 1, , , , 1, , , , , , , , 1, , , , , , , , , , 1 ], [ , 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1 ], [ 1, 1, , 1, 1, 1, , 1, 1, 1, , , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, , 1 ], [ 1, 1, , , , , , , 1, 1, , , , , 1, 1, 1, 1, 1, , 1, 1, 1, 1, , 1 ], [ , 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, , 1, , 1, 1, 1, 1, , 1, 1, , 1, 1, 1, 1 ], , [ , 1, 1, , , , , 1, , 1, , , , 1, 1, 1, , , 1, , , , , 1 ], [ , , , , , , , , , , , , , 1 ], [ , , , , , 1, , , , , , , , 1, 1, , , , , 1, , 1, , , 1, 1 ], [ , , , , , , , , , , , , , , 1 ] ], [ , [ , 1 ], , , , , , , , , , , , , , , , , , , , [ 1, 1, 1, 1, 1, , 1, 1, 1, 1, , 1, 1, 1, 1, , 1, 1, 1, 1, , , 1, 1, 1, 1, 1 ], [ , 1, , 1, , 1, , , 1, 1, 1, , 1, 1, 1, 1, 1, , , 1, , , , 1, , 1, 1 ], [ , 1, , 1, , 1, , , 1, , , , , 1, , , , , , 1, 1 ], [ , 1, , 1, , , , , 1, , , , 1, , 1, 1, 1, 1, 1, 1, 1, 1, , 1 ], [ , 1, , , , , , , , , , , , , , , 1 ] ], [ , [ , 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ , , 1, , , , , , , , , 1, 1, , , , 1 ], [ , , , , , , 1 ], [ , , 1 ], [ , 1, 1, , , 1, , 1, , 1, 1, , 1, 1, 1, , , , 1, 1, 1, , , , , 1 ], , [ , 1, , , , 1, , , , , , 1, , , 1, , , , 1, 1, , 1 ], [ , , , , , , , 1, , , , , , , , , 1 ], [ , 1, , , , 1, 1, , , , , , 1, 1, 1, , , , 1, , 1, 1 ], [ , , , , , , , 1, , 1, , , , , , , , , , 1 ], [ , 1, 1, , , , , , 1, 1, , , , 1, , , , , , , 1, , , 1 ], , [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ 1, 1, , , 1, , , 1, , , , , 1, , 1, , 1, , 1, , , , , 1 ], [ 1, 1, 1, 1, 1, 1, 1, 1, , , , , 1, 1, , 1, 1, , 1, , , 1, , 1 ], [ , , , , , , , , , , , , , , 1, , , , , , 1 ], , [ , , , , , , , , , 1, , , , , , 1, , , , , 1 ], [ , , 1, , , , , , , 1, , , 1, 1 ], [ , , , 1, , , , , 1, , , , , 1, , , , , , 1, , , , 1 ], [ 1, , 1, 1, , 1, 1, 1, 1, 1, , 1, , , , 1, 1, 1, , , 1, 1, , , , 1, 1 ], , [ 1, 1, , , , , , , , , , 1, , 1, , 1, , , 1 ], [ , , , , 1, , , , , , , , , , , , , , , , , , , 1 ], [ , , , , , , , , , , , , , , 1, , , , , 1, , 1 ], [ , , , , , , , , 1 ] ], [ , [ 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ 1, 1, 1, , , 1, 1, 1, 1, 1, , 1, 1, , 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1 ], [ 1, 1, 1, 1, , 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, , 1 ], [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1 ], [ , , 1, , , 1, , , , , , , , 1, , , , , , 1, , , , 1 ], [ 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, , 1, 1, 1, 1 ], [ 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ , 1, 1, , 1, 1, , 1, , , , 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, , 1 ], [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, , 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1 ], [ 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ 1, , 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1 ], [ 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1 ], [ , , 1, 1, 1, 1, , 1, , 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1 ], [ 1, 1, , , , , , , 1, , 1, 1, , 1, 1, 1, , 1, 1, 1, 1, 1 ], [ 1, 1, 1, 1, , 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1 ], [ 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1 ], [ 1, 1, 1, 1, , 1, , 1, , 1, 1, 1, 1, 1, , , , 1, 1, 1, 1, , 1, 1, 1, 1, 1 ], [ 1, 1, 1, 1, , 1, , , , , , 1, , 1, , , , , 1, 1, , , , , 1 ], [ 1, , 1, 1, , , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ , , 1, 1, , 1, , 1, , , , 1, 1, 1, 1, 1, , , 1, 1, , 1, , 1 ], [ , 1, 1, 1, 1, , , , , 1, , 1, 1, 1, 1, 1, , , 1, 1, , , , 1, 1, 1 ], [ , 1, 1, 1, 1, 1, , 1, , , , , 1, , 1, , 1, , , 1, , , 1, 1, , 1 ] ], [ , [ 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1 ], [ , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ , 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, , 1, 1, 1, 1 ], [ , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, , 1, 1 ], [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ , , , , , , , , , 1, , , , , 1, 1, , , 1, , 1 ], [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , , , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ 1, , , 1, 1, 1, 1, , 1, 1, , 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1 ], [ , 1, , , , , , 1, , 1, 1, , 1, 1, 1, 1, 1, , , 1, , 1, , 1 ], [ 1, 1, 1, , 1, 1, 1, 1, , , , 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1 ], [ 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1 ], [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, , 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1 ], [ , 1, , 1, , 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1 ], [ , , 1, , , , , , , , , , 1, 1, 1, 1, 1, 1, 1, , 1, 1, , 1 ], [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1 ], [ , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1 ], [ , 1, , , 1, 1, , , , , , 1, 1, 1, 1, 1, , , , 1, 1, 1, , 1, 1, 1 ], [ 1, 1, 1, 1, 1, 1, 1, 1, 1, , , , 1, 1, 1, 1, 1, 1, 1, , 1, 1, , 1, 1, 1 ], [ , 1, 1, 1, , 1, , 1, 1, 1, 1, , , 1, 1, 1, , 1, 1, 1, 1, 1, , , 1, 1 ], [ 1, 1, , , , 1, , , 1, 1, 1, , 1, , 1, , 1, , 1, 1, 1, 1, 1, , 1, , 1 ], [ , 1, , , , , , , 1, , 1, , 1, 1, 1, 1, , , , , , , , , 1 ] ], [ , [ , , , , , , , , , , , , , 1, 1, , , , 1 ], [ , 1, , , , , , , , 1, , , 1, , , , , , 1, , , 1, , , , 1 ], , [ , 1, , , , 1, , 1, , 1, 1, , 1, 1, , , , , , , , 1 ], [ , , , , , , , , , , , , , , , , , , , 1 ], [ , , , , , , , , , 1 ], [ 1, 1, 1, , , 1, , , , , , , , , 1, 1, , , , , , , , , , 1 ], [ , 1, , , , , , , , , , , , , 1 ], [ , , , , , , , , , , , , , , , , , , , 1, , , 1 ], [ , , , , , , , , , 1 ], [ 1, 1, , , , , , 1, 1, 1, , 1, 1, , , , 1, 1, , 1, , 1, 1, 1, , 1 ], [ , 1, 1, 1, , 1, 1, , , 1, , 1, 1, 1, 1, , , , , , , 1, , 1 ], [ , 1, 1, 1, 1, , , 1, , 1, , , , 1, 1, 1, 1, , 1, 1, , 1 ], [ , 1, , , 1, 1, , 1, , , , 1, , 1, 1, , 1, , 1, , , 1, , , 1, , 1 ], [ , , , , , , , , , , , 1 ], [ , , , , , , , , , 1, , , , , , , , , , , , , 1 ], , [ 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, , 1, 1, 1, 1, 1, 1, 1 ], [ , 1, , , , , , , 1, 1, , 1, , , , , 1, , , 1, , 1 ], [ , 1, , , , 1, , , 1, , , , , , , , 1, , 1, , , 1 ], [ , , , , , , , , , , , , , 1, 1, , , , 1, , , 1 ], [ , , , , , 1, , , 1, , , , 1 ], [ , 1 ], , [ , 1 ], [ 1, , , , , , , , , , , , , , 1, , , , , 1 ] ], [ , [ , 1, , , , 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, , 1, 1, , 1, 1, , , 1 ], [ , , 1, , , , , , , , , 1 ], , , [ 1, , , 1, 1, , , , , , , , 1, 1, , 1, 1, , 1 ], , [ , , , , , , , , , , , , , , , , , , 1, , 1 ], , [ 1, , , 1, 1, , 1, 1, , , , , 1, , 1, , , , , 1, 1, , 1 ], , [ , 1, , , , , , , , 1, 1, 1, 1, 1, , 1, 1, , , , 1, 1 ], [ , , , , , , , , , , , , , , , , 1, , , 1 ], [ , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , , 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1 ], [ , , , , , , , , , , , 1, , 1, , , 1 ], [ 1, , , , , , , , , , , , , , , , , , 1, , 1 ], , , [ , 1, , , , , , , , , , , , , , 1, , , , 1, 1 ], [ , , , , , , , , , 1, , , 1, , , , , , , , , , 1 ], [ , , , , , , , , , , , , , , , 1 ], [ , , , , , , , , , , , , , 1, 1, , , , , , 1 ], , [ , 1 ] ], [ , [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ , 1, 1, , , 1, 1, , 1, 1, 1, 1, 1, 1, , , 1, 1, 1, 1, 1, , 1, 1 ], [ , 1, , , , , , , , 1 ], [ , , , , 1, , , 1, , , 1, 1, , , , , , , , , , 1, , , , 1 ], [ , 1, , 1, 1, , , 1, 1, 1, , , , 1, 1, 1, 1, , 1, 1, 1, 1, , 1 ], [ , , , , , , , 1 ], [ , 1, 1, , , , , 1, , 1, , , , , , 1, , , , , , 1, , 1, , 1 ], [ , 1, , , , , , 1, , , , 1, , , , , , , , , , 1 ], [ , , 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , , , 1, , 1, 1, 1, 1, , 1 ], [ , 1, , , , , , , , 1 ], [ , 1, 1, , 1, , , , , , , , 1, , , , , , 1, , , 1, , 1, , 1 ], [ , 1, , 1, , 1, , 1, 1, 1, , 1, 1, 1, , 1, , , 1, 1, , 1, 1, 1, 1, 1 ], [ , 1, 1, 1, 1, 1, , , 1, 1, , , , 1, 1, 1, , , , 1, 1, , , 1, 1 ], [ , , 1, 1, 1, 1, , 1, , 1, , 1, , 1, 1, 1, 1, , , , , 1, , 1, , 1 ], [ 1, 1, 1, 1, 1, 1, 1, 1, , 1, , 1, , 1, 1, 1, , , 1, 1, , , , 1, , 1 ], [ , , , 1 ], , [ , 1, 1, , 1, , , 1, 1, 1, , 1, 1, 1, 1, 1, 1, , 1, 1, , 1, 1, 1, 1, 1, 1 ], [ , 1, , , , , , 1, , 1, , 1, , , , , , , 1, 1, , 1, 1 ], [ , , , , , , 1, , 1, 1, , 1, , 1, , , , , , , , , , 1 ], [ , 1, 1, , 1, , , , 1, , , , 1, 1, 1, , , , 1, , 1, 1, 1, , 1, 1 ], , [ , 1, 1, , , , , , , , , , , , , 1, , , 1, , , , , 1 ], [ , 1, , , , , , , , , , , , , , , , , , , , , , 1 ], [ , 1, 1, , , , , , , 1, , , , 1, , , , , 1, , , , , , , 1 ] ], [ , [ , 1, 1, 1, 1, 1, , 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1 ], [ , 1, 1, 1, 1, 1, , 1, , 1, 1, , , 1, 1, 1, 1, , 1, , , , , 1, 1, 1 ], [ , , 1, 1, , 1, , 1, 1, , , , 1, 1, 1, 1, , , 1, , 1, 1, 1, 1, , 1 ], [ , 1, , 1, , , , , , , , 1, , 1, , 1, , , , , , , , , , 1 ], [ , , 1, , 1, , , 1, , , , , 1, 1, , , 1, , 1, 1, 1, 1 ], [ , 1 ], [ , 1, 1, , 1, , 1, 1, , 1, , , 1, 1, 1, , , , 1, , , 1, , 1 ], [ 1, 1, , 1, 1, 1, , , , , , , , , , , , , 1, , 1, 1, 1 ], [ , 1, 1, , , , , , , 1, , , 1, , 1, , 1, , 1, 1, , , 1, , , 1 ], [ , , 1, , , , , , , , , , , , , , , , , , 1 ], [ , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ , 1, 1, 1, 1, 1, , 1, , 1, , , , , 1, 1, 1, , , 1, , 1, , , , 1 ], [ , 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ , 1, 1, , 1, , , 1, 1, 1, , 1, , 1, 1, 1, , , 1, 1, 1, 1, , , , 1, 1 ], [ , , , 1, 1, , , 1, , 1, , 1, , 1, 1, 1, 1, , 1, , , , , 1 ], [ , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ , 1, , , , , , , , , , , , , , , , , , , 1 ], [ , 1, 1, , 1, 1, , 1, , 1, , , , 1, 1, , , 1, 1, , 1, 1, , 1 ], [ , 1, 1, 1, 1, 1, , , 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, , , 1 ], [ , 1, 1, 1, 1, 1, , 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1 ], [ , 1, 1, , 1, , , 1, , , 1, , 1, 1, 1, 1, 1, , 1, , 1, 1 ], [ , , , , , 1, , , , 1, , , , , 1, 1, , , , 1 ], [ , 1, , 1, 1, 1, , 1, , , 1, 1, 1, , , 1, , , 1, , 1, , , 1 ], [ , , 1, , , , , , , , , 1, , 1, , , , , 1, , 1 ], [ , 1, 1, , , , , , , , 1, 1, 1, , , , , , , , 1, , , , , 1 ], [ , , , , , , , , 1, , , , , 1, , , 1 ] ], [ , [ , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ , 1, 1, , 1, 1, , , 1, 1, 1, 1, 1, 1, 1, 1, , , , , , , , , 1, 1 ], [ , , , , , , , , 1, , , , 1, , 1, , 1 ], [ , 1, , , 1, 1, , 1, , , , 1, , , , , , , , 1 ], [ , 1, , 1, , 1, , , , 1, 1, , 1, , 1, , , , 1, 1, 1, 1, 1, , , 1 ], , [ , 1, , , , , , , , 1, , , 1, 1, , , 1, , 1, 1, , 1, , 1 ], [ , 1, , , 1, , , , , , , , 1, , , , , , , 1 ], [ 1, 1, , , , , 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1 ], , [ , 1, , , , , , 1, , 1, , 1, 1, 1, 1, 1, , , 1, , 1, 1, , , , 1 ], [ , 1, 1, , , 1, , 1, , 1, , , 1, 1, 1, 1, , , 1, , , 1, , , , 1 ], [ , 1, 1, 1, 1, 1, , 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , , , 1, , 1 ], [ , 1, , , 1, 1, , 1, 1, , , 1, 1, , 1, 1, , 1, , 1, , 1 ], [ 1, , 1, , , , , 1, , 1, , 1, 1, 1, 1, , , , , 1, 1, , , , 1, 1 ], [ , 1, 1, , , , , 1, 1, , , 1, , 1, 1, 1, 1, , , , , , , , , , 1 ], , [ , 1, 1, , , 1, , , , 1, , 1, 1, 1, 1, 1, , , , 1, , , , 1, , 1 ], [ , , , 1, 1, , , 1, , , , , 1, , 1, 1, 1, , 1, 1, , , , , , 1 ], [ , 1, , , , , , , , , , , 1, , , , 1, , , , , , , 1, , 1 ], [ , 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, , 1, 1, 1, , 1, 1, , 1, 1, 1, 1 ], [ , 1, , , , , , , , , , , , , , , , , , , 1 ], [ , 1, , , , , , 1, , , , , 1, , 1, , , 1, 1, , 1, 1, , 1 ], [ , 1, , , , , , 1, , , , , 1, 1, , , , , , , , 1, , , , 1 ], [ , , , , , , , , , , , , , , , , , , 1, , , 1, , , , , 1 ], [ , , , , , , , 1, , , , 1 ] ], [ , [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ , 1, , 1, , 1, , , , , , , 1, , , , , , , , 1, , , 1 ], [ , 1, , , , , , , 1 ], [ , , , , , , , , , , 1 ], [ , 1, , , , , , 1, 1, , , , , , 1 ], , [ , 1, 1, , , , , , 1, , , , , 1, 1, , , , 1 ], [ 1, , 1, , 1, , , , , 1, , , , , 1, , , , , , , , , 1, 1 ], [ , 1, 1, , , , , , , , , 1, 1, 1, 1, , , , 1, , , , , 1, , , 1 ], , [ , 1, 1, , 1, , , 1, 1, , , 1, , , 1, 1, 1, , 1, , 1, 1, 1, , , , 1 ], [ , , , , , 1, , , , , 1, , , 1, 1, , , 1, , 1, , , , 1 ], [ , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ , 1, , , 1, 1, , 1, , , , 1, , , , , , , , 1 ], [ , , , 1, , , , , 1, , , , , 1, , 1, , 1, 1, 1 ], [ , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], [ , , , , , 1 ], [ , 1, , , , , , 1, , , , , , , 1, 1, 1, , , 1 ], [ , 1, , , , , , , , , , 1, 1, 1, , , , , 1, , , 1 ], [ , , , , , 1, , 1, , , , , 1, 1, 1, , 1, 1, , 1, 1, 1, , , 1, 1 ], [ 1, 1, , , , , , , 1, , , , , 1, 1, , , , , , , , , , , 1 ], , [ , 1 ], [ , , , , , , , , , , , , , , , , , , , , , , , , 1 ], [ , , 1, , , , , 1, , , 1, , , , 1, , 1 ], [ , 1, , , , , , , , , 1 ] ] ];
    function isValidLang(lang) {
      var array = langs;
      while (lang.length < 3) {
        lang += '`';
      }
      for (var _i10 = 0; _i10 <= lang.length - 1; _i10++) {
        var index = lang.charCodeAt(_i10) - 96;
        array = array[index];
        if (!array) {
          return false;
        }
      }
      return true;
    }
    function _validLangs(langArray) {
      langArray = Array.isArray(langArray) ? langArray : langs;
      var codes = [];
      langArray.forEach(function(lang, index) {
        var _char2 = String.fromCharCode(index + 96).replace('`', '');
        if (Array.isArray(lang)) {
          codes = codes.concat(_validLangs(lang).map(function(newLang) {
            return _char2 + newLang;
          }));
        } else {
          codes.push(_char2);
        }
      });
      return codes;
    }
    var valid_langs_default = isValidLang;
    axe._thisWillBeDeletedDoNotUse = axe._thisWillBeDeletedDoNotUse || {};
    axe._thisWillBeDeletedDoNotUse.utils = {
      setDefaultFrameMessenger: setDefaultFrameMessenger
    };
    var SerialVirtualNode = function(_abstract_virtual_nod2) {
      _inherits(SerialVirtualNode, _abstract_virtual_nod2);
      var _super2 = _createSuper(SerialVirtualNode);
      function SerialVirtualNode(serialNode) {
        var _this2;
        _classCallCheck(this, SerialVirtualNode);
        _this2 = _super2.call(this);
        _this2._props = normaliseProps(serialNode);
        _this2._attrs = normaliseAttrs(serialNode);
        return _this2;
      }
      _createClass(SerialVirtualNode, [ {
        key: 'attr',
        value: function attr(attrName) {
          return this._attrs[attrName] || null;
        }
      }, {
        key: 'hasAttr',
        value: function hasAttr(attrName) {
          return this._attrs[attrName] !== void 0;
        }
      }, {
        key: 'props',
        get: function get() {
          return this._props;
        }
      }, {
        key: 'attrNames',
        get: function get() {
          return Object.keys(this._attrs);
        }
      } ]);
      return SerialVirtualNode;
    }(abstract_virtual_node_default);
    function normaliseProps(serialNode) {
      var nodeName2 = serialNode.nodeName;
      var _serialNode$nodeType = serialNode.nodeType, nodeType = _serialNode$nodeType === void 0 ? 1 : _serialNode$nodeType;
      assert_default(typeof nodeType === 'number', 'nodeType has to be a number, got \''.concat(nodeType, '\''));
      assert_default(typeof nodeName2 === 'string', 'nodeName has to be a string, got \''.concat(nodeName2, '\''));
      nodeName2 = nodeName2.toLowerCase();
      var type = null;
      if (nodeName2 === 'input') {
        type = (serialNode.type || serialNode.attributes && serialNode.attributes.type || '').toLowerCase();
        if (!valid_input_type_default().includes(type)) {
          type = 'text';
        }
      }
      var props = _extends({}, serialNode, {
        nodeType: nodeType,
        nodeName: nodeName2
      });
      if (type) {
        props.type = type;
      }
      delete props.attributes;
      return Object.freeze(props);
    }
    function normaliseAttrs(_ref22) {
      var _ref22$attributes = _ref22.attributes, attributes4 = _ref22$attributes === void 0 ? {} : _ref22$attributes;
      var attrMap = {
        htmlFor: 'for',
        className: 'class'
      };
      return Object.keys(attributes4).reduce(function(attrs, attrName) {
        var value = attributes4[attrName];
        assert_default(_typeof(value) !== 'object' || value === null, 'expects attributes not to be an object, \''.concat(attrName, '\' was'));
        if (value !== void 0) {
          var mappedName = attrMap[attrName] || attrName;
          attrs[mappedName] = value !== null ? String(value) : null;
        }
        return attrs;
      }, {});
    }
    var serial_virtual_node_default = SerialVirtualNode;
    var aria_exports = {};
    __export(aria_exports, {
      allowedAttr: function allowedAttr() {
        return allowed_attr_default;
      },
      arialabelText: function arialabelText() {
        return arialabel_text_default;
      },
      arialabelledbyText: function arialabelledbyText() {
        return arialabelledby_text_default;
      },
      getAccessibleRefs: function getAccessibleRefs() {
        return get_accessible_refs_default;
      },
      getElementUnallowedRoles: function getElementUnallowedRoles() {
        return get_element_unallowed_roles_default;
      },
      getExplicitRole: function getExplicitRole() {
        return get_explicit_role_default;
      },
      getOwnedVirtual: function getOwnedVirtual() {
        return get_owned_virtual_default;
      },
      getRole: function getRole() {
        return get_role_default;
      },
      getRoleType: function getRoleType() {
        return get_role_type_default;
      },
      getRolesByType: function getRolesByType() {
        return get_roles_by_type_default;
      },
      getRolesWithNameFromContents: function getRolesWithNameFromContents() {
        return get_roles_with_name_from_contents_default;
      },
      implicitNodes: function implicitNodes() {
        return implicit_nodes_default;
      },
      implicitRole: function implicitRole() {
        return implicit_role_default;
      },
      isAccessibleRef: function isAccessibleRef() {
        return is_accessible_ref_default;
      },
      isAriaRoleAllowedOnElement: function isAriaRoleAllowedOnElement() {
        return is_aria_role_allowed_on_element_default;
      },
      isUnsupportedRole: function isUnsupportedRole() {
        return is_unsupported_role_default;
      },
      isValidRole: function isValidRole() {
        return is_valid_role_default;
      },
      label: function label() {
        return label_default2;
      },
      labelVirtual: function labelVirtual() {
        return label_virtual_default;
      },
      lookupTable: function lookupTable() {
        return lookup_table_default;
      },
      namedFromContents: function namedFromContents() {
        return named_from_contents_default;
      },
      requiredAttr: function requiredAttr() {
        return required_attr_default;
      },
      requiredContext: function requiredContext() {
        return required_context_default;
      },
      requiredOwned: function requiredOwned() {
        return required_owned_default;
      },
      validateAttr: function validateAttr() {
        return validate_attr_default;
      },
      validateAttrValue: function validateAttrValue() {
        return validate_attr_value_default;
      }
    });
    function getGlobalAriaAttrs() {
      if (cache_default.get('globalAriaAttrs')) {
        return cache_default.get('globalAriaAttrs');
      }
      var globalAttrs = Object.keys(standards_default.ariaAttrs).filter(function(attrName) {
        return standards_default.ariaAttrs[attrName].global;
      });
      cache_default.set('globalAriaAttrs', globalAttrs);
      return globalAttrs;
    }
    var get_global_aria_attrs_default = getGlobalAriaAttrs;
    function allowedAttr(role) {
      var roleDef = standards_default.ariaRoles[role];
      var attrs = _toConsumableArray(get_global_aria_attrs_default());
      if (!roleDef) {
        return attrs;
      }
      if (roleDef.allowedAttrs) {
        attrs.push.apply(attrs, _toConsumableArray(roleDef.allowedAttrs));
      }
      if (roleDef.requiredAttrs) {
        attrs.push.apply(attrs, _toConsumableArray(roleDef.requiredAttrs));
      }
      return attrs;
    }
    var allowed_attr_default = allowedAttr;
    function arialabelText(vNode) {
      if (!(vNode instanceof abstract_virtual_node_default)) {
        if (vNode.nodeType !== 1) {
          return '';
        }
        vNode = get_node_from_tree_default(vNode);
      }
      return vNode.attr('aria-label') || '';
    }
    var arialabel_text_default = arialabelText;
    function isUnsupportedRole(role) {
      var roleDefinition = standards_default.ariaRoles[role];
      return roleDefinition ? !!roleDefinition.unsupported : false;
    }
    var is_unsupported_role_default = isUnsupportedRole;
    function isValidRole(role) {
      var _ref23 = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : {}, allowAbstract = _ref23.allowAbstract, _ref23$flagUnsupporte = _ref23.flagUnsupported, flagUnsupported = _ref23$flagUnsupporte === void 0 ? false : _ref23$flagUnsupporte;
      var roleDefinition = standards_default.ariaRoles[role];
      var isRoleUnsupported = is_unsupported_role_default(role);
      if (!roleDefinition || flagUnsupported && isRoleUnsupported) {
        return false;
      }
      return allowAbstract ? true : roleDefinition.type !== 'abstract';
    }
    var is_valid_role_default = isValidRole;
    function getExplicitRole(vNode) {
      var _ref24 = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : {}, fallback = _ref24.fallback, abstracts = _ref24.abstracts, dpub = _ref24.dpub;
      vNode = vNode instanceof abstract_virtual_node_default ? vNode : get_node_from_tree_default(vNode);
      if (vNode.props.nodeType !== 1) {
        return null;
      }
      var roleAttr = (vNode.attr('role') || '').trim().toLowerCase();
      var roleList = fallback ? token_list_default(roleAttr) : [ roleAttr ];
      var firstValidRole = roleList.find(function(role) {
        if (!dpub && role.substr(0, 4) === 'doc-') {
          return false;
        }
        return is_valid_role_default(role, {
          allowAbstract: abstracts
        });
      });
      return firstValidRole || null;
    }
    var get_explicit_role_default = getExplicitRole;
    function getElementsByContentType(type) {
      return Object.keys(standards_default.htmlElms).filter(function(nodeName2) {
        var elm = standards_default.htmlElms[nodeName2];
        if (elm.contentTypes) {
          return elm.contentTypes.includes(type);
        }
        if (!elm.variant) {
          return false;
        }
        if (elm.variant['default'] && elm.variant['default'].contentTypes) {
          return elm.variant['default'].contentTypes.includes(type);
        }
        return false;
      });
    }
    var get_elements_by_content_type_default = getElementsByContentType;
    function toGrid(node) {
      var table5 = [];
      var rows = node.rows;
      for (var i = 0, rowLength = rows.length; i < rowLength; i++) {
        var cells = rows[i].cells;
        table5[i] = table5[i] || [];
        var columnIndex = 0;
        for (var j = 0, cellLength = cells.length; j < cellLength; j++) {
          for (var colSpan = 0; colSpan < cells[j].colSpan; colSpan++) {
            var rowspanAttr = cells[j].getAttribute('rowspan');
            var rowspanValue = parseInt(rowspanAttr) === 0 || cells[j].rowspan === 0 ? rows.length : cells[j].rowSpan;
            for (var rowSpan = 0; rowSpan < rowspanValue; rowSpan++) {
              table5[i + rowSpan] = table5[i + rowSpan] || [];
              while (table5[i + rowSpan][columnIndex]) {
                columnIndex++;
              }
              table5[i + rowSpan][columnIndex] = cells[j];
            }
            columnIndex++;
          }
        }
      }
      return table5;
    }
    var to_grid_default = memoize_default(toGrid);
    function getCellPosition(cell, tableGrid) {
      var rowIndex, index;
      if (!tableGrid) {
        tableGrid = to_grid_default(find_up_default(cell, 'table'));
      }
      for (rowIndex = 0; rowIndex < tableGrid.length; rowIndex++) {
        if (tableGrid[rowIndex]) {
          index = tableGrid[rowIndex].indexOf(cell);
          if (index !== -1) {
            return {
              x: index,
              y: rowIndex
            };
          }
        }
      }
    }
    var get_cell_position_default = memoize_default(getCellPosition);
    function getScope(cell) {
      var scope = cell.getAttribute('scope');
      var role = cell.getAttribute('role');
      if (cell instanceof window.Element === false || [ 'TD', 'TH' ].indexOf(cell.nodeName.toUpperCase()) === -1) {
        throw new TypeError('Expected TD or TH element');
      }
      if (role === 'columnheader') {
        return 'col';
      } else if (role === 'rowheader') {
        return 'row';
      } else if (scope === 'col' || scope === 'row') {
        return scope;
      } else if (cell.nodeName.toUpperCase() !== 'TH') {
        return false;
      }
      var tableGrid = to_grid_default(find_up_default(cell, 'table'));
      var pos = get_cell_position_default(cell, tableGrid);
      var headerRow = tableGrid[pos.y].reduce(function(headerRow2, cell2) {
        return headerRow2 && cell2.nodeName.toUpperCase() === 'TH';
      }, true);
      if (headerRow) {
        return 'col';
      }
      var headerCol = tableGrid.map(function(col) {
        return col[pos.x];
      }).reduce(function(headerCol2, cell2) {
        return headerCol2 && cell2 && cell2.nodeName.toUpperCase() === 'TH';
      }, true);
      if (headerCol) {
        return 'row';
      }
      return 'auto';
    }
    var get_scope_default = getScope;
    function isColumnHeader(element) {
      return [ 'col', 'auto' ].indexOf(get_scope_default(element)) !== -1;
    }
    var is_column_header_default = isColumnHeader;
    function isRowHeader(cell) {
      return [ 'row', 'auto' ].includes(get_scope_default(cell));
    }
    var is_row_header_default = isRowHeader;
    var sectioningElementSelector = get_elements_by_content_type_default('sectioning').map(function(nodeName2) {
      return ''.concat(nodeName2, ':not([role])');
    }).join(', ') + ' , main:not([role]), [role=article], [role=complementary], [role=main], [role=navigation], [role=region]';
    function hasAccessibleName(vNode) {
      var ariaLabelledby = sanitize_default(arialabelledby_text_default(vNode));
      var ariaLabel = sanitize_default(arialabel_text_default(vNode));
      return !!(ariaLabelledby || ariaLabel);
    }
    var implicitHtmlRoles = {
      a: function a(vNode) {
        return vNode.hasAttr('href') ? 'link' : null;
      },
      area: function area(vNode) {
        return vNode.hasAttr('href') ? 'link' : null;
      },
      article: 'article',
      aside: 'complementary',
      body: 'document',
      button: 'button',
      datalist: 'listbox',
      dd: 'definition',
      dfn: 'term',
      details: 'group',
      dialog: 'dialog',
      dt: 'term',
      fieldset: 'group',
      figure: 'figure',
      footer: function footer(vNode) {
        var sectioningElement = closest_default(vNode, sectioningElementSelector);
        return !sectioningElement ? 'contentinfo' : null;
      },
      form: function form(vNode) {
        return hasAccessibleName(vNode) ? 'form' : null;
      },
      h1: 'heading',
      h2: 'heading',
      h3: 'heading',
      h4: 'heading',
      h5: 'heading',
      h6: 'heading',
      header: function header(vNode) {
        var sectioningElement = closest_default(vNode, sectioningElementSelector);
        return !sectioningElement ? 'banner' : null;
      },
      hr: 'separator',
      img: function img(vNode) {
        var emptyAlt = vNode.hasAttr('alt') && !vNode.attr('alt');
        var hasGlobalAria = get_global_aria_attrs_default().find(function(attr) {
          return vNode.hasAttr(attr);
        });
        return emptyAlt && !hasGlobalAria && !is_focusable_default(vNode) ? 'presentation' : 'img';
      },
      input: function input(vNode) {
        var suggestionsSourceElement;
        if (vNode.hasAttr('list')) {
          var listElement = idrefs_default(vNode.actualNode, 'list').filter(function(node) {
            return !!node;
          })[0];
          suggestionsSourceElement = listElement && listElement.nodeName.toLowerCase() === 'datalist';
        }
        switch (vNode.props.type) {
         case 'button':
         case 'image':
         case 'reset':
         case 'submit':
          return 'button';

         case 'checkbox':
          return 'checkbox';

         case 'email':
         case 'tel':
         case 'text':
         case 'url':
         case '':
          return !suggestionsSourceElement ? 'textbox' : 'combobox';

         case 'number':
          return 'spinbutton';

         case 'radio':
          return 'radio';

         case 'range':
          return 'slider';

         case 'search':
          return !suggestionsSourceElement ? 'searchbox' : 'combobox';
        }
      },
      li: 'listitem',
      main: 'main',
      math: 'math',
      menu: 'list',
      nav: 'navigation',
      ol: 'list',
      optgroup: 'group',
      option: 'option',
      output: 'status',
      progress: 'progressbar',
      section: function section(vNode) {
        return hasAccessibleName(vNode) ? 'region' : null;
      },
      select: function select(vNode) {
        return vNode.hasAttr('multiple') || parseInt(vNode.attr('size')) > 1 ? 'listbox' : 'combobox';
      },
      summary: 'button',
      table: 'table',
      tbody: 'rowgroup',
      td: function td(vNode) {
        var table5 = closest_default(vNode, 'table');
        var role = get_explicit_role_default(table5);
        return [ 'grid', 'treegrid' ].includes(role) ? 'gridcell' : 'cell';
      },
      textarea: 'textbox',
      tfoot: 'rowgroup',
      th: function th(vNode) {
        if (is_column_header_default(vNode.actualNode)) {
          return 'columnheader';
        }
        if (is_row_header_default(vNode.actualNode)) {
          return 'rowheader';
        }
      },
      thead: 'rowgroup',
      tr: 'row',
      ul: 'list'
    };
    var implicit_html_roles_default = implicitHtmlRoles;
    function implicitRole(node) {
      var vNode = node instanceof abstract_virtual_node_default ? node : get_node_from_tree_default(node);
      node = vNode.actualNode;
      if (!vNode) {
        throw new ReferenceError('Cannot get implicit role of a node outside the current scope.');
      }
      if (node && node.namespaceURI === 'http://www.w3.org/2000/svg') {
        return null;
      }
      var nodeName2 = vNode.props.nodeName;
      var role = implicit_html_roles_default[nodeName2];
      if (!role) {
        return null;
      }
      if (typeof role === 'function') {
        return role(vNode);
      }
      return role;
    }
    var implicit_role_default = implicitRole;
    var inheritsPresentationChain = {
      td: [ 'tr' ],
      th: [ 'tr' ],
      tr: [ 'thead', 'tbody', 'tfoot', 'table' ],
      thead: [ 'table' ],
      tbody: [ 'table' ],
      tfoot: [ 'table' ],
      li: [ 'ol', 'ul' ],
      dt: [ 'dl', 'div' ],
      dd: [ 'dl', 'div' ],
      div: [ 'dl' ]
    };
    function getInheritedRole(vNode, explicitRoleOptions) {
      var parentNodeNames = inheritsPresentationChain[vNode.props.nodeName];
      if (!parentNodeNames) {
        return null;
      }
      if (!vNode.parent) {
        throw new ReferenceError('Cannot determine role presentational inheritance of a required parent outside the current scope.');
      }
      if (!parentNodeNames.includes(vNode.parent.props.nodeName)) {
        return null;
      }
      var parentRole = get_explicit_role_default(vNode.parent, explicitRoleOptions);
      if ([ 'none', 'presentation' ].includes(parentRole) && !hasConflictResolution(vNode.parent)) {
        return parentRole;
      }
      if (parentRole) {
        return null;
      }
      return getInheritedRole(vNode.parent, explicitRoleOptions);
    }
    function resolveImplicitRole(vNode, explicitRoleOptions) {
      var implicitRole3 = implicit_role_default(vNode);
      if (!implicitRole3) {
        return null;
      }
      var presentationalRole = getInheritedRole(vNode, explicitRoleOptions);
      if (presentationalRole) {
        return presentationalRole;
      }
      return implicitRole3;
    }
    function hasConflictResolution(vNode) {
      var hasGlobalAria = get_global_aria_attrs_default().some(function(attr) {
        return vNode.hasAttr(attr);
      });
      return hasGlobalAria || is_focusable_default(vNode);
    }
    function resolveRole(node) {
      var _ref25 = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : {};
      var noImplicit = _ref25.noImplicit, explicitRoleOptions = _objectWithoutProperties(_ref25, [ 'noImplicit' ]);
      var vNode = node instanceof abstract_virtual_node_default ? node : get_node_from_tree_default(node);
      if (vNode.props.nodeType !== 1) {
        return null;
      }
      var explicitRole2 = get_explicit_role_default(vNode, explicitRoleOptions);
      if (!explicitRole2) {
        return noImplicit ? null : resolveImplicitRole(vNode, explicitRoleOptions);
      }
      if (![ 'presentation', 'none' ].includes(explicitRole2)) {
        return explicitRole2;
      }
      if (hasConflictResolution(vNode)) {
        return noImplicit ? null : resolveImplicitRole(vNode, explicitRoleOptions);
      }
      return explicitRole2;
    }
    function getRole(node) {
      var _ref26 = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : {};
      var noPresentational = _ref26.noPresentational, options = _objectWithoutProperties(_ref26, [ 'noPresentational' ]);
      var role = resolveRole(node, options);
      if (noPresentational && [ 'presentation', 'none' ].includes(role)) {
        return null;
      }
      return role;
    }
    var get_role_default = getRole;
    function fromPrimative(someString, matcher) {
      var matcherType = _typeof(matcher);
      if (Array.isArray(matcher) && typeof someString !== 'undefined') {
        return matcher.includes(someString);
      }
      if (matcherType === 'function') {
        return !!matcher(someString);
      }
      if (someString !== null && someString !== void 0) {
        if (matcher instanceof RegExp) {
          return matcher.test(someString);
        }
        if (/^\/.*\/$/.test(matcher)) {
          var pattern = matcher.substring(1, matcher.length - 1);
          return new RegExp(pattern).test(someString);
        }
      }
      return matcher === someString;
    }
    var from_primative_default = fromPrimative;
    function fromFunction(getValue, matcher) {
      var matcherType = _typeof(matcher);
      if (matcherType !== 'object' || Array.isArray(matcher) || matcher instanceof RegExp) {
        throw new Error('Expect matcher to be an object');
      }
      return Object.keys(matcher).every(function(propName) {
        return from_primative_default(getValue(propName), matcher[propName]);
      });
    }
    var from_function_default = fromFunction;
    function attributes(vNode, matcher) {
      if (!(vNode instanceof abstract_virtual_node_default)) {
        vNode = get_node_from_tree_default(vNode);
      }
      return from_function_default(function(attrName) {
        return vNode.attr(attrName);
      }, matcher);
    }
    var attributes_default = attributes;
    function condition(arg, condition4) {
      return !!condition4(arg);
    }
    var condition_default = condition;
    function explicitRole(vNode, matcher) {
      return from_primative_default(get_explicit_role_default(vNode), matcher);
    }
    var explicit_role_default = explicitRole;
    function implicitRole2(vNode, matcher) {
      return from_primative_default(implicit_role_default(vNode), matcher);
    }
    var implicit_role_default2 = implicitRole2;
    function nodeName(vNode, matcher) {
      if (!(vNode instanceof abstract_virtual_node_default)) {
        vNode = get_node_from_tree_default(vNode);
      }
      return from_primative_default(vNode.props.nodeName, matcher);
    }
    var node_name_default = nodeName;
    function properties(vNode, matcher) {
      if (!(vNode instanceof abstract_virtual_node_default)) {
        vNode = get_node_from_tree_default(vNode);
      }
      return from_function_default(function(propName) {
        return vNode.props[propName];
      }, matcher);
    }
    var properties_default = properties;
    function semanticRole(vNode, matcher) {
      return from_primative_default(get_role_default(vNode), matcher);
    }
    var semantic_role_default = semanticRole;
    var matchers = {
      attributes: attributes_default,
      condition: condition_default,
      explicitRole: explicit_role_default,
      implicitRole: implicit_role_default2,
      nodeName: node_name_default,
      properties: properties_default,
      semanticRole: semantic_role_default
    };
    function fromDefinition(vNode, definition) {
      if (!(vNode instanceof abstract_virtual_node_default)) {
        vNode = get_node_from_tree_default(vNode);
      }
      if (Array.isArray(definition)) {
        return definition.some(function(definitionItem) {
          return fromDefinition(vNode, definitionItem);
        });
      }
      if (typeof definition === 'string') {
        return matches_default(vNode, definition);
      }
      return Object.keys(definition).every(function(matcherName) {
        if (!matchers[matcherName]) {
          throw new Error('Unknown matcher type "'.concat(matcherName, '"'));
        }
        var matchMethod = matchers[matcherName];
        var matcher = definition[matcherName];
        return matchMethod(vNode, matcher);
      });
    }
    var from_definition_default = fromDefinition;
    function matches5(vNode, definition) {
      return from_definition_default(vNode, definition);
    }
    var matches_default2 = matches5;
    matches_default2.attributes = attributes_default;
    matches_default2.condition = condition_default;
    matches_default2.explicitRole = explicit_role_default;
    matches_default2.fromDefinition = from_definition_default;
    matches_default2.fromFunction = from_function_default;
    matches_default2.fromPrimative = from_primative_default;
    matches_default2.implicitRole = implicit_role_default2;
    matches_default2.nodeName = node_name_default;
    matches_default2.properties = properties_default;
    matches_default2.semanticRole = semantic_role_default;
    var matches_default3 = matches_default2;
    function getElementSpec(vNode) {
      var standard = standards_default.htmlElms[vNode.props.nodeName];
      if (!standard) {
        return {};
      }
      if (!standard.variant) {
        return standard;
      }
      var variant = standard.variant, spec = _objectWithoutProperties(standard, [ 'variant' ]);
      for (var variantName in variant) {
        if (!variant.hasOwnProperty(variantName) || variantName === 'default') {
          continue;
        }
        var _variant$variantName = variant[variantName], matches14 = _variant$variantName.matches, props = _objectWithoutProperties(_variant$variantName, [ 'matches' ]);
        if (matches_default3(vNode, matches14)) {
          for (var propName in props) {
            if (props.hasOwnProperty(propName)) {
              spec[propName] = props[propName];
            }
          }
        }
      }
      for (var _propName in variant['default']) {
        if (variant['default'].hasOwnProperty(_propName) && typeof spec[_propName] === 'undefined') {
          spec[_propName] = variant['default'][_propName];
        }
      }
      return spec;
    }
    var get_element_spec_default = getElementSpec;
    var alwaysTitleElements = [ 'iframe' ];
    function titleText(node) {
      var vNode = node instanceof abstract_virtual_node_default ? node : get_node_from_tree_default(node);
      if (vNode.props.nodeType !== 1 || !node.hasAttr('title')) {
        return '';
      }
      if (!matches_default2(vNode, alwaysTitleElements) && [ 'none', 'presentation' ].includes(get_role_default(vNode))) {
        return '';
      }
      return vNode.attr('title');
    }
    var title_text_default = titleText;
    function namedFromContents(vNode) {
      var _ref27 = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : {}, strict = _ref27.strict;
      vNode = vNode instanceof abstract_virtual_node_default ? vNode : get_node_from_tree_default(vNode);
      if (vNode.props.nodeType !== 1) {
        return false;
      }
      var role = get_role_default(vNode);
      var roleDef = standards_default.ariaRoles[role];
      if (roleDef && roleDef.nameFromContent) {
        return true;
      }
      if (strict) {
        return false;
      }
      return !roleDef || [ 'presentation', 'none' ].includes(role);
    }
    var named_from_contents_default = namedFromContents;
    function getOwnedVirtual(virtualNode) {
      var actualNode = virtualNode.actualNode, children = virtualNode.children;
      if (!children) {
        throw new Error('getOwnedVirtual requires a virtual node');
      }
      if (virtualNode.hasAttr('aria-owns')) {
        var owns = idrefs_default(actualNode, 'aria-owns').filter(function(element) {
          return !!element;
        }).map(function(element) {
          return axe.utils.getNodeFromTree(element);
        });
        return [].concat(_toConsumableArray(children), _toConsumableArray(owns));
      }
      return _toConsumableArray(children);
    }
    var get_owned_virtual_default = getOwnedVirtual;
    function subtreeText(virtualNode) {
      var context3 = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : {};
      var alreadyProcessed2 = accessible_text_virtual_default.alreadyProcessed;
      context3.startNode = context3.startNode || virtualNode;
      var _context = context3, strict = _context.strict, inControlContext = _context.inControlContext, inLabelledByContext = _context.inLabelledByContext;
      if (alreadyProcessed2(virtualNode, context3) || virtualNode.props.nodeType !== 1) {
        return '';
      }
      if (!named_from_contents_default(virtualNode, {
        strict: strict
      }) && !context3.subtreeDescendant) {
        return '';
      }
      if (!strict) {
        var subtreeDescendant = !inControlContext && !inLabelledByContext;
        context3 = _extends({
          subtreeDescendant: subtreeDescendant
        }, context3);
      }
      return get_owned_virtual_default(virtualNode).reduce(function(contentText, child) {
        return appendAccessibleText(contentText, child, context3);
      }, '');
    }
    var phrasingElements = get_elements_by_content_type_default('phrasing').concat([ '#text' ]);
    function appendAccessibleText(contentText, virtualNode, context3) {
      var nodeName2 = virtualNode.props.nodeName;
      var contentTextAdd = accessible_text_virtual_default(virtualNode, context3);
      if (!contentTextAdd) {
        return contentText;
      }
      if (!phrasingElements.includes(nodeName2)) {
        if (contentTextAdd[0] !== ' ') {
          contentTextAdd += ' ';
        }
        if (contentText && contentText[contentText.length - 1] !== ' ') {
          contentTextAdd = ' ' + contentTextAdd;
        }
      }
      return contentText + contentTextAdd;
    }
    var subtree_text_default = subtreeText;
    function labelText(virtualNode) {
      var context3 = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : {};
      var alreadyProcessed2 = accessible_text_virtual_default.alreadyProcessed;
      if (context3.inControlContext || context3.inLabelledByContext || alreadyProcessed2(virtualNode, context3)) {
        return '';
      }
      if (!context3.startNode) {
        context3.startNode = virtualNode;
      }
      var labelContext = _extends({
        inControlContext: true
      }, context3);
      var explicitLabels = getExplicitLabels(virtualNode);
      var implicitLabel = closest_default(virtualNode, 'label');
      var labels;
      if (implicitLabel) {
        labels = [].concat(_toConsumableArray(explicitLabels), [ implicitLabel.actualNode ]);
        labels.sort(node_sorter_default);
      } else {
        labels = explicitLabels;
      }
      return labels.map(function(label5) {
        return accessible_text_default(label5, labelContext);
      }).filter(function(text32) {
        return text32 !== '';
      }).join(' ');
    }
    function getExplicitLabels(virtualNode) {
      if (!virtualNode.attr('id')) {
        return [];
      }
      if (!virtualNode.actualNode) {
        throw new TypeError('Cannot resolve explicit label reference for non-DOM nodes');
      }
      return find_elms_in_context_default({
        elm: 'label',
        attr: 'for',
        value: virtualNode.attr('id'),
        context: virtualNode.actualNode
      });
    }
    var label_text_default = labelText;
    var defaultButtonValues = {
      submit: 'Submit',
      image: 'Submit',
      reset: 'Reset',
      button: ''
    };
    var nativeTextMethods = {
      valueText: function valueText(_ref28) {
        var actualNode = _ref28.actualNode;
        return actualNode.value || '';
      },
      buttonDefaultText: function buttonDefaultText(_ref29) {
        var actualNode = _ref29.actualNode;
        return defaultButtonValues[actualNode.type] || '';
      },
      tableCaptionText: descendantText.bind(null, 'caption'),
      figureText: descendantText.bind(null, 'figcaption'),
      svgTitleText: descendantText.bind(null, 'title'),
      fieldsetLegendText: descendantText.bind(null, 'legend'),
      altText: attrText.bind(null, 'alt'),
      tableSummaryText: attrText.bind(null, 'summary'),
      titleText: title_text_default,
      subtreeText: subtree_text_default,
      labelText: label_text_default,
      singleSpace: function singleSpace() {
        return ' ';
      },
      placeholderText: attrText.bind(null, 'placeholder')
    };
    function attrText(attr, vNode) {
      return vNode.attr(attr) || '';
    }
    function descendantText(nodeName2, _ref30, context3) {
      var actualNode = _ref30.actualNode;
      nodeName2 = nodeName2.toLowerCase();
      var nodeNames = [ nodeName2, actualNode.nodeName.toLowerCase() ].join(',');
      var candidate = actualNode.querySelector(nodeNames);
      if (!candidate || candidate.nodeName.toLowerCase() !== nodeName2) {
        return '';
      }
      return accessible_text_default(candidate, context3);
    }
    var native_text_methods_default = nativeTextMethods;
    function nativeTextAlternative(virtualNode) {
      var context3 = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : {};
      var actualNode = virtualNode.actualNode;
      if (virtualNode.props.nodeType !== 1 || [ 'presentation', 'none' ].includes(get_role_default(virtualNode))) {
        return '';
      }
      var textMethods = findTextMethods(virtualNode);
      var accName = textMethods.reduce(function(accName2, step) {
        return accName2 || step(virtualNode, context3);
      }, '');
      if (context3.debug) {
        axe.log(accName || '{empty-value}', actualNode, context3);
      }
      return accName;
    }
    function findTextMethods(virtualNode) {
      var elmSpec = get_element_spec_default(virtualNode);
      var methods = elmSpec.namingMethods || [];
      return methods.map(function(methodName) {
        return native_text_methods_default[methodName];
      });
    }
    var native_text_alternative_default = nativeTextAlternative;
    var unsupported = {
      accessibleNameFromFieldValue: [ 'combobox', 'listbox', 'progressbar' ]
    };
    var unsupported_default = unsupported;
    var nonTextInputTypes = [ 'button', 'checkbox', 'color', 'file', 'hidden', 'image', 'password', 'radio', 'reset', 'submit' ];
    function isNativeTextbox(node) {
      node = node instanceof abstract_virtual_node_default ? node : get_node_from_tree_default(node);
      var nodeName2 = node.props.nodeName;
      return nodeName2 === 'textarea' || nodeName2 === 'input' && !nonTextInputTypes.includes((node.attr('type') || '').toLowerCase());
    }
    var is_native_textbox_default = isNativeTextbox;
    function isNativeSelect(node) {
      node = node instanceof abstract_virtual_node_default ? node : get_node_from_tree_default(node);
      var nodeName2 = node.props.nodeName;
      return nodeName2 === 'select';
    }
    var is_native_select_default = isNativeSelect;
    function isAriaTextbox(node) {
      var role = get_explicit_role_default(node);
      return role === 'textbox';
    }
    var is_aria_textbox_default = isAriaTextbox;
    function isAriaListbox(node) {
      var role = get_explicit_role_default(node);
      return role === 'listbox';
    }
    var is_aria_listbox_default = isAriaListbox;
    function isAriaCombobox(node) {
      var role = get_explicit_role_default(node);
      return role === 'combobox';
    }
    var is_aria_combobox_default = isAriaCombobox;
    var rangeRoles = [ 'progressbar', 'scrollbar', 'slider', 'spinbutton' ];
    function isAriaRange(node) {
      var role = get_explicit_role_default(node);
      return rangeRoles.includes(role);
    }
    var is_aria_range_default = isAriaRange;
    var controlValueRoles = [ 'textbox', 'progressbar', 'scrollbar', 'slider', 'spinbutton', 'combobox', 'listbox' ];
    var _formControlValueMethods = {
      nativeTextboxValue: nativeTextboxValue,
      nativeSelectValue: nativeSelectValue,
      ariaTextboxValue: ariaTextboxValue,
      ariaListboxValue: ariaListboxValue,
      ariaComboboxValue: ariaComboboxValue,
      ariaRangeValue: ariaRangeValue
    };
    function formControlValue(virtualNode) {
      var context3 = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : {};
      var actualNode = virtualNode.actualNode;
      var unsupportedRoles = unsupported_default.accessibleNameFromFieldValue || [];
      var role = get_role_default(virtualNode);
      if (context3.startNode === virtualNode || !controlValueRoles.includes(role) || unsupportedRoles.includes(role)) {
        return '';
      }
      var valueMethods = Object.keys(_formControlValueMethods).map(function(name) {
        return _formControlValueMethods[name];
      });
      var valueString = valueMethods.reduce(function(accName, step) {
        return accName || step(virtualNode, context3);
      }, '');
      if (context3.debug) {
        log_default(valueString || '{empty-value}', actualNode, context3);
      }
      return valueString;
    }
    function nativeTextboxValue(node) {
      var vNode = node instanceof abstract_virtual_node_default ? node : get_node_from_tree_default(node);
      if (is_native_textbox_default(vNode)) {
        return vNode.props.value || '';
      }
      return '';
    }
    function nativeSelectValue(node) {
      var vNode = node instanceof abstract_virtual_node_default ? node : get_node_from_tree_default(node);
      if (!is_native_select_default(vNode)) {
        return '';
      }
      var options = query_selector_all_default(vNode, 'option');
      var selectedOptions = options.filter(function(option) {
        return option.hasAttr('selected');
      });
      if (!selectedOptions.length) {
        selectedOptions.push(options[0]);
      }
      return selectedOptions.map(function(option) {
        return visible_virtual_default(option);
      }).join(' ') || '';
    }
    function ariaTextboxValue(node) {
      var vNode = node instanceof abstract_virtual_node_default ? node : get_node_from_tree_default(node);
      var actualNode = vNode.actualNode;
      if (!is_aria_textbox_default(vNode)) {
        return '';
      }
      if (!actualNode || actualNode && !is_hidden_with_css_default(actualNode)) {
        return visible_virtual_default(vNode, true);
      } else {
        return actualNode.textContent;
      }
    }
    function ariaListboxValue(node, context3) {
      var vNode = node instanceof abstract_virtual_node_default ? node : get_node_from_tree_default(node);
      if (!is_aria_listbox_default(vNode)) {
        return '';
      }
      var selected = get_owned_virtual_default(vNode).filter(function(owned) {
        return get_role_default(owned) === 'option' && owned.attr('aria-selected') === 'true';
      });
      if (selected.length === 0) {
        return '';
      }
      return accessible_text_virtual_default(selected[0], context3);
    }
    function ariaComboboxValue(node, context3) {
      var vNode = node instanceof abstract_virtual_node_default ? node : get_node_from_tree_default(node);
      if (!is_aria_combobox_default(vNode)) {
        return '';
      }
      var listbox = get_owned_virtual_default(vNode).filter(function(elm) {
        return get_role_default(elm) === 'listbox';
      })[0];
      return listbox ? ariaListboxValue(listbox, context3) : '';
    }
    function ariaRangeValue(node) {
      var vNode = node instanceof abstract_virtual_node_default ? node : get_node_from_tree_default(node);
      if (!is_aria_range_default(vNode) || !vNode.hasAttr('aria-valuenow')) {
        return '';
      }
      var valueNow = +vNode.attr('aria-valuenow');
      return !isNaN(valueNow) ? String(valueNow) : '0';
    }
    var form_control_value_default = formControlValue;
    function accessibleTextVirtual(virtualNode) {
      var context3 = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : {};
      var actualNode = virtualNode.actualNode;
      context3 = prepareContext(virtualNode, context3);
      if (shouldIgnoreHidden(virtualNode, context3)) {
        return '';
      }
      var computationSteps = [ arialabelledby_text_default, arialabel_text_default, native_text_alternative_default, form_control_value_default, subtree_text_default, textNodeValue, title_text_default ];
      var accName = computationSteps.reduce(function(accName2, step) {
        if (context3.startNode === virtualNode) {
          accName2 = sanitize_default(accName2);
        }
        if (accName2 !== '') {
          return accName2;
        }
        return step(virtualNode, context3);
      }, '');
      if (context3.debug) {
        axe.log(accName || '{empty-value}', actualNode, context3);
      }
      return accName;
    }
    function textNodeValue(virtualNode) {
      if (virtualNode.props.nodeType !== 3) {
        return '';
      }
      return virtualNode.props.nodeValue;
    }
    function shouldIgnoreHidden(_ref31, context3) {
      var actualNode = _ref31.actualNode;
      if (!actualNode) {
        return false;
      }
      if (actualNode.nodeType !== 1 || context3.includeHidden) {
        return false;
      }
      return !is_visible_default(actualNode, true);
    }
    function prepareContext(virtualNode, context3) {
      var actualNode = virtualNode.actualNode;
      if (!context3.startNode) {
        context3 = _extends({
          startNode: virtualNode
        }, context3);
      }
      if (!actualNode) {
        return context3;
      }
      if (actualNode.nodeType === 1 && context3.inLabelledByContext && context3.includeHidden === void 0) {
        context3 = _extends({
          includeHidden: !is_visible_default(actualNode, true)
        }, context3);
      }
      return context3;
    }
    accessibleTextVirtual.alreadyProcessed = function alreadyProcessed(virtualnode, context3) {
      context3.processed = context3.processed || [];
      if (context3.processed.includes(virtualnode)) {
        return true;
      }
      context3.processed.push(virtualnode);
      return false;
    };
    var accessible_text_virtual_default = accessibleTextVirtual;
    function accessibleText(element, context3) {
      var virtualNode = get_node_from_tree_default(element);
      return accessible_text_virtual_default(virtualNode, context3);
    }
    var accessible_text_default = accessibleText;
    function arialabelledbyText(vNode) {
      var context3 = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : {};
      if (!(vNode instanceof abstract_virtual_node_default)) {
        if (vNode.nodeType !== 1) {
          return '';
        }
        vNode = get_node_from_tree_default(vNode);
      }
      if (vNode.props.nodeType !== 1 || context3.inLabelledByContext || context3.inControlContext || !vNode.attr('aria-labelledby')) {
        return '';
      }
      var refs = idrefs_default(vNode, 'aria-labelledby').filter(function(elm) {
        return elm;
      });
      return refs.reduce(function(accessibleName, elm) {
        var accessibleNameAdd = accessible_text_default(elm, _extends({
          inLabelledByContext: true,
          startNode: context3.startNode || vNode
        }, context3));
        if (!accessibleName) {
          return accessibleNameAdd;
        } else {
          return ''.concat(accessibleName, ' ').concat(accessibleNameAdd);
        }
      }, '');
    }
    var arialabelledby_text_default = arialabelledbyText;
    var text_exports = {};
    __export(text_exports, {
      accessibleText: function accessibleText() {
        return accessible_text_default;
      },
      accessibleTextVirtual: function accessibleTextVirtual() {
        return accessible_text_virtual_default;
      },
      autocomplete: function autocomplete() {
        return _autocomplete;
      },
      formControlValue: function formControlValue() {
        return form_control_value_default;
      },
      formControlValueMethods: function formControlValueMethods() {
        return _formControlValueMethods;
      },
      hasUnicode: function hasUnicode() {
        return has_unicode_default;
      },
      isHumanInterpretable: function isHumanInterpretable() {
        return is_human_interpretable_default;
      },
      isIconLigature: function isIconLigature() {
        return is_icon_ligature_default;
      },
      isValidAutocomplete: function isValidAutocomplete() {
        return is_valid_autocomplete_default;
      },
      label: function label() {
        return label_default;
      },
      labelText: function labelText() {
        return label_text_default;
      },
      labelVirtual: function labelVirtual() {
        return label_virtual_default2;
      },
      nativeElementType: function nativeElementType() {
        return native_element_type_default;
      },
      nativeTextAlternative: function nativeTextAlternative() {
        return native_text_alternative_default;
      },
      nativeTextMethods: function nativeTextMethods() {
        return native_text_methods_default;
      },
      removeUnicode: function removeUnicode() {
        return remove_unicode_default;
      },
      sanitize: function sanitize() {
        return sanitize_default;
      },
      subtreeText: function subtreeText() {
        return subtree_text_default;
      },
      titleText: function titleText() {
        return title_text_default;
      },
      unsupported: function unsupported() {
        return unsupported_default;
      },
      visible: function visible() {
        return visible_default;
      },
      visibleTextNodes: function visibleTextNodes() {
        return visible_text_nodes_default;
      },
      visibleVirtual: function visibleVirtual() {
        return visible_virtual_default;
      }
    });
    function getUnicodeNonBmpRegExp() {
      return /[\u1D00-\u1D7F\u1D80-\u1DBF\u1DC0-\u1DFF\u20A0-\u20CF\u20D0-\u20FF\u2100-\u214F\u2150-\u218F\u2190-\u21FF\u2200-\u22FF\u2300-\u23FF\u2400-\u243F\u2440-\u245F\u2460-\u24FF\u2500-\u257F\u2580-\u259F\u25A0-\u25FF\u2600-\u26FF\u2700-\u27BF\uE000-\uF8FF]/g;
    }
    function getPunctuationRegExp() {
      return /[\u2000-\u206F\u2E00-\u2E7F\\'!"#$%&\xa3\xa2\xa5\xa7\u20ac()*+,\-.\/:;<=>?@\[\]^_`{|}~\xb1]/g;
    }
    function getSupplementaryPrivateUseRegExp() {
      return /[\uDB80-\uDBBF][\uDC00-\uDFFF]/g;
    }
    var emoji_regex = __toModule(require_emoji_regex());
    function hasUnicode(str, options) {
      var emoji = options.emoji, nonBmp = options.nonBmp, punctuations = options.punctuations;
      if (emoji) {
        return emoji_regex['default']().test(str);
      }
      if (nonBmp) {
        return getUnicodeNonBmpRegExp().test(str) || getSupplementaryPrivateUseRegExp().test(str);
      }
      if (punctuations) {
        return getPunctuationRegExp().test(str);
      }
      return false;
    }
    var has_unicode_default = hasUnicode;
    var emoji_regex2 = __toModule(require_emoji_regex());
    function removeUnicode(str, options) {
      var emoji = options.emoji, nonBmp = options.nonBmp, punctuations = options.punctuations;
      if (emoji) {
        str = str.replace(emoji_regex2['default'](), '');
      }
      if (nonBmp) {
        str = str.replace(getUnicodeNonBmpRegExp(), '');
        str = str.replace(getSupplementaryPrivateUseRegExp(), '');
      }
      if (punctuations) {
        str = str.replace(getPunctuationRegExp(), '');
      }
      return str;
    }
    var remove_unicode_default = removeUnicode;
    function isHumanInterpretable(str) {
      if (!str.length) {
        return 0;
      }
      var alphaNumericIconMap = [ 'x', 'i' ];
      if (alphaNumericIconMap.includes(str)) {
        return 0;
      }
      var noUnicodeStr = remove_unicode_default(str, {
        emoji: true,
        nonBmp: true,
        punctuations: true
      });
      if (!sanitize_default(noUnicodeStr)) {
        return 0;
      }
      return 1;
    }
    var is_human_interpretable_default = isHumanInterpretable;
    function isIconLigature(textVNode) {
      var differenceThreshold = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : .15;
      var occuranceThreshold = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : 3;
      var nodeValue = textVNode.actualNode.nodeValue.trim();
      if (!sanitize_default(nodeValue) || has_unicode_default(nodeValue, {
        emoji: true,
        nonBmp: true
      })) {
        return false;
      }
      if (!cache_default.get('canvasContext')) {
        cache_default.set('canvasContext', document.createElement('canvas').getContext('2d'));
      }
      var canvasContext = cache_default.get('canvasContext');
      var canvas = canvasContext.canvas;
      if (!cache_default.get('fonts')) {
        cache_default.set('fonts', {});
      }
      var fonts = cache_default.get('fonts');
      var style = window.getComputedStyle(textVNode.parent.actualNode);
      var fontFamily = style.getPropertyValue('font-family');
      if (!fonts[fontFamily]) {
        fonts[fontFamily] = {
          occurances: 0,
          numLigatures: 0
        };
      }
      var font = fonts[fontFamily];
      if (font.occurances >= occuranceThreshold) {
        if (font.numLigatures / font.occurances === 1) {
          return true;
        } else if (font.numLigatures === 0) {
          return false;
        }
      }
      font.occurances++;
      var fontSize = 30;
      var fontStyle = ''.concat(fontSize, 'px ').concat(fontFamily);
      canvasContext.font = fontStyle;
      var firstChar = nodeValue.charAt(0);
      var width = canvasContext.measureText(firstChar).width;
      if (width < 30) {
        var diff = 30 / width;
        width *= diff;
        fontSize *= diff;
        fontStyle = ''.concat(fontSize, 'px ').concat(fontFamily);
      }
      canvas.width = width;
      canvas.height = fontSize;
      canvasContext.font = fontStyle;
      canvasContext.textAlign = 'left';
      canvasContext.textBaseline = 'top';
      canvasContext.fillText(firstChar, 0, 0);
      var compareData = new Uint32Array(canvasContext.getImageData(0, 0, width, fontSize).data.buffer);
      if (!compareData.some(function(pixel) {
        return pixel;
      })) {
        font.numLigatures++;
        return true;
      }
      canvasContext.clearRect(0, 0, width, fontSize);
      canvasContext.fillText(nodeValue, 0, 0);
      var compareWith = new Uint32Array(canvasContext.getImageData(0, 0, width, fontSize).data.buffer);
      var differences = compareData.reduce(function(diff, pixel, i) {
        if (pixel === 0 && compareWith[i] === 0) {
          return diff;
        }
        if (pixel !== 0 && compareWith[i] !== 0) {
          return diff;
        }
        return ++diff;
      }, 0);
      var expectedWidth = nodeValue.split('').reduce(function(width2, _char3) {
        return width2 + canvasContext.measureText(_char3).width;
      }, 0);
      var actualWidth = canvasContext.measureText(nodeValue).width;
      var pixelDifference = differences / compareData.length;
      var sizeDifference = 1 - actualWidth / expectedWidth;
      if (pixelDifference >= differenceThreshold && sizeDifference >= differenceThreshold) {
        font.numLigatures++;
        return true;
      }
      return false;
    }
    var is_icon_ligature_default = isIconLigature;
    var _autocomplete = {
      stateTerms: [ 'on', 'off' ],
      standaloneTerms: [ 'name', 'honorific-prefix', 'given-name', 'additional-name', 'family-name', 'honorific-suffix', 'nickname', 'username', 'new-password', 'current-password', 'organization-title', 'organization', 'street-address', 'address-line1', 'address-line2', 'address-line3', 'address-level4', 'address-level3', 'address-level2', 'address-level1', 'country', 'country-name', 'postal-code', 'cc-name', 'cc-given-name', 'cc-additional-name', 'cc-family-name', 'cc-number', 'cc-exp', 'cc-exp-month', 'cc-exp-year', 'cc-csc', 'cc-type', 'transaction-currency', 'transaction-amount', 'language', 'bday', 'bday-day', 'bday-month', 'bday-year', 'sex', 'url', 'photo', 'one-time-code' ],
      qualifiers: [ 'home', 'work', 'mobile', 'fax', 'pager' ],
      qualifiedTerms: [ 'tel', 'tel-country-code', 'tel-national', 'tel-area-code', 'tel-local', 'tel-local-prefix', 'tel-local-suffix', 'tel-extension', 'email', 'impp' ],
      locations: [ 'billing', 'shipping' ]
    };
    function isValidAutocomplete(autocompleteValue) {
      var _ref32 = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : {}, _ref32$looseTyped = _ref32.looseTyped, looseTyped = _ref32$looseTyped === void 0 ? false : _ref32$looseTyped, _ref32$stateTerms = _ref32.stateTerms, stateTerms = _ref32$stateTerms === void 0 ? [] : _ref32$stateTerms, _ref32$locations = _ref32.locations, locations = _ref32$locations === void 0 ? [] : _ref32$locations, _ref32$qualifiers = _ref32.qualifiers, qualifiers = _ref32$qualifiers === void 0 ? [] : _ref32$qualifiers, _ref32$standaloneTerm = _ref32.standaloneTerms, standaloneTerms = _ref32$standaloneTerm === void 0 ? [] : _ref32$standaloneTerm, _ref32$qualifiedTerms = _ref32.qualifiedTerms, qualifiedTerms = _ref32$qualifiedTerms === void 0 ? [] : _ref32$qualifiedTerms;
      autocompleteValue = autocompleteValue.toLowerCase().trim();
      stateTerms = stateTerms.concat(_autocomplete.stateTerms);
      if (stateTerms.includes(autocompleteValue) || autocompleteValue === '') {
        return true;
      }
      qualifiers = qualifiers.concat(_autocomplete.qualifiers);
      locations = locations.concat(_autocomplete.locations);
      standaloneTerms = standaloneTerms.concat(_autocomplete.standaloneTerms);
      qualifiedTerms = qualifiedTerms.concat(_autocomplete.qualifiedTerms);
      var autocompleteTerms = autocompleteValue.split(/\s+/g);
      if (!looseTyped) {
        if (autocompleteTerms[0].length > 8 && autocompleteTerms[0].substr(0, 8) === 'section-') {
          autocompleteTerms.shift();
        }
        if (locations.includes(autocompleteTerms[0])) {
          autocompleteTerms.shift();
        }
        if (qualifiers.includes(autocompleteTerms[0])) {
          autocompleteTerms.shift();
          standaloneTerms = [];
        }
        if (autocompleteTerms.length !== 1) {
          return false;
        }
      }
      var purposeTerm = autocompleteTerms[autocompleteTerms.length - 1];
      return standaloneTerms.includes(purposeTerm) || qualifiedTerms.includes(purposeTerm);
    }
    var is_valid_autocomplete_default = isValidAutocomplete;
    function visible(element, screenReader, noRecursing) {
      element = get_node_from_tree_default(element);
      return visible_virtual_default(element, screenReader, noRecursing);
    }
    var visible_default = visible;
    function labelVirtual2(virtualNode) {
      var ref, candidate, doc;
      candidate = label_virtual_default(virtualNode);
      if (candidate) {
        return candidate;
      }
      if (virtualNode.attr('id')) {
        if (!virtualNode.actualNode) {
          throw new TypeError('Cannot resolve explicit label reference for non-DOM nodes');
        }
        var id = escape_selector_default(virtualNode.attr('id'));
        doc = get_root_node_default2(virtualNode.actualNode);
        ref = doc.querySelector('label[for="' + id + '"]');
        candidate = ref && visible_default(ref, true);
        if (candidate) {
          return candidate;
        }
      }
      ref = closest_default(virtualNode, 'label');
      candidate = ref && visible_virtual_default(ref, true);
      if (candidate) {
        return candidate;
      }
      return null;
    }
    var label_virtual_default2 = labelVirtual2;
    function label(node) {
      node = get_node_from_tree_default(node);
      return label_virtual_default2(node);
    }
    var label_default = label;
    var nativeElementType = [ {
      matches: [ {
        nodeName: 'textarea'
      }, {
        nodeName: 'input',
        properties: {
          type: [ 'text', 'password', 'search', 'tel', 'email', 'url' ]
        }
      } ],
      namingMethods: 'labelText'
    }, {
      matches: {
        nodeName: 'input',
        properties: {
          type: [ 'button', 'submit', 'reset' ]
        }
      },
      namingMethods: [ 'valueText', 'titleText', 'buttonDefaultText' ]
    }, {
      matches: {
        nodeName: 'input',
        properties: {
          type: 'image'
        }
      },
      namingMethods: [ 'altText', 'valueText', 'labelText', 'titleText', 'buttonDefaultText' ]
    }, {
      matches: 'button',
      namingMethods: 'subtreeText'
    }, {
      matches: 'fieldset',
      namingMethods: 'fieldsetLegendText'
    }, {
      matches: 'OUTPUT',
      namingMethods: 'subtreeText'
    }, {
      matches: [ {
        nodeName: 'select'
      }, {
        nodeName: 'input',
        properties: {
          type: /^(?!text|password|search|tel|email|url|button|submit|reset)/
        }
      } ],
      namingMethods: 'labelText'
    }, {
      matches: 'summary',
      namingMethods: 'subtreeText'
    }, {
      matches: 'figure',
      namingMethods: [ 'figureText', 'titleText' ]
    }, {
      matches: 'img',
      namingMethods: 'altText'
    }, {
      matches: 'table',
      namingMethods: [ 'tableCaptionText', 'tableSummaryText' ]
    }, {
      matches: [ 'hr', 'br' ],
      namingMethods: [ 'titleText', 'singleSpace' ]
    } ];
    var native_element_type_default = nativeElementType;
    function visibleTextNodes(vNode) {
      var parentVisible = is_visible_default(vNode.actualNode);
      var nodes = [];
      vNode.children.forEach(function(child) {
        if (child.actualNode.nodeType === 3) {
          if (parentVisible) {
            nodes.push(child);
          }
        } else {
          nodes = nodes.concat(visibleTextNodes(child));
        }
      });
      return nodes;
    }
    var visible_text_nodes_default = visibleTextNodes;
    var idRefsRegex = /^idrefs?$/;
    function cacheIdRefs(node, idRefs, refAttrs) {
      if (node.hasAttribute) {
        if (node.nodeName.toUpperCase() === 'LABEL' && node.hasAttribute('for')) {
          var id = node.getAttribute('for');
          idRefs[id] = idRefs[id] || [];
          idRefs[id].push(node);
        }
        for (var _i11 = 0; _i11 < refAttrs.length; ++_i11) {
          var attr = refAttrs[_i11];
          var attrValue = sanitize_default(node.getAttribute(attr) || '');
          if (!attrValue) {
            continue;
          }
          var tokens = token_list_default(attrValue);
          for (var k = 0; k < tokens.length; ++k) {
            idRefs[tokens[k]] = idRefs[tokens[k]] || [];
            idRefs[tokens[k]].push(node);
          }
        }
      }
      for (var _i12 = 0; _i12 < node.children.length; _i12++) {
        cacheIdRefs(node.children[_i12], idRefs, refAttrs);
      }
    }
    function getAccessibleRefs(node) {
      node = node.actualNode || node;
      var root = get_root_node_default2(node);
      root = root.documentElement || root;
      var idRefsByRoot = cache_default.get('idRefsByRoot');
      if (!idRefsByRoot) {
        idRefsByRoot = new WeakMap();
        cache_default.set('idRefsByRoot', idRefsByRoot);
      }
      var idRefs = idRefsByRoot.get(root);
      if (!idRefs) {
        idRefs = {};
        idRefsByRoot.set(root, idRefs);
        var refAttrs = Object.keys(standards_default.ariaAttrs).filter(function(attr) {
          var type = standards_default.ariaAttrs[attr].type;
          return idRefsRegex.test(type);
        });
        cacheIdRefs(root, idRefs, refAttrs);
      }
      return idRefs[node.id] || [];
    }
    var get_accessible_refs_default = getAccessibleRefs;
    function getRoleType(role) {
      var roleDef = standards_default.ariaRoles[role];
      if (!roleDef) {
        return null;
      }
      return roleDef.type;
    }
    var get_role_type_default = getRoleType;
    function isAriaRoleAllowedOnElement(node, role) {
      var vNode = node instanceof abstract_virtual_node_default ? node : get_node_from_tree_default(node);
      var implicitRole3 = implicit_role_default(vNode);
      if (role === implicitRole3) {
        return true;
      }
      var spec = get_element_spec_default(vNode);
      if (Array.isArray(spec.allowedRoles)) {
        return spec.allowedRoles.includes(role);
      }
      return !!spec.allowedRoles;
    }
    var is_aria_role_allowed_on_element_default = isAriaRoleAllowedOnElement;
    var dpubRoles2 = [ 'doc-backlink', 'doc-biblioentry', 'doc-biblioref', 'doc-cover', 'doc-endnote', 'doc-glossref', 'doc-noteref' ];
    function getRoleSegments(node) {
      var roles = [];
      if (!node) {
        return roles;
      }
      if (node.hasAttribute('role')) {
        var nodeRoles = token_list_default(node.getAttribute('role').toLowerCase());
        roles = roles.concat(nodeRoles);
      }
      if (node.hasAttributeNS('http://www.idpf.org/2007/ops', 'type')) {
        var epubRoles = token_list_default(node.getAttributeNS('http://www.idpf.org/2007/ops', 'type').toLowerCase()).map(function(role) {
          return 'doc-'.concat(role);
        });
        roles = roles.concat(epubRoles);
      }
      roles = roles.filter(function(role) {
        return is_valid_role_default(role);
      });
      return roles;
    }
    function getElementUnallowedRoles(node) {
      var allowImplicit = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : true;
      var tagName = node.nodeName.toUpperCase();
      if (!is_html_element_default(node)) {
        return [];
      }
      var roleSegments = getRoleSegments(node);
      var implicitRole3 = implicit_role_default(node);
      var unallowedRoles = roleSegments.filter(function(role) {
        if (allowImplicit && role === implicitRole3) {
          return false;
        }
        if (allowImplicit && dpubRoles2.includes(role)) {
          var roleType = get_role_type_default(role);
          if (implicitRole3 !== roleType) {
            return true;
          }
        }
        if (!allowImplicit && !(role === 'row' && tagName === 'TR' && element_matches_default(node, 'table[role="grid"] > tr'))) {
          return true;
        }
        return !is_aria_role_allowed_on_element_default(node, role);
      });
      return unallowedRoles;
    }
    var get_element_unallowed_roles_default = getElementUnallowedRoles;
    function getAriaRolesByType(type) {
      return Object.keys(standards_default.ariaRoles).filter(function(roleName) {
        return standards_default.ariaRoles[roleName].type === type;
      });
    }
    var get_aria_roles_by_type_default = getAriaRolesByType;
    function getRolesByType(roleType) {
      return get_aria_roles_by_type_default(roleType);
    }
    var get_roles_by_type_default = getRolesByType;
    function getAriaRolesSupportingNameFromContent() {
      if (cache_default.get('ariaRolesNameFromContent')) {
        return cache_default.get('ariaRolesNameFromContent');
      }
      var contentRoles = Object.keys(standards_default.ariaRoles).filter(function(roleName) {
        return standards_default.ariaRoles[roleName].nameFromContent;
      });
      cache_default.set('ariaRolesNameFromContent', contentRoles);
      return contentRoles;
    }
    var get_aria_roles_supporting_name_from_content_default = getAriaRolesSupportingNameFromContent;
    function getRolesWithNameFromContents() {
      return get_aria_roles_supporting_name_from_content_default();
    }
    var get_roles_with_name_from_contents_default = getRolesWithNameFromContents;
    var isNull = function isNull(value) {
      return value === null;
    };
    var isNotNull = function isNotNull(value) {
      return value !== null;
    };
    var lookupTable = {};
    lookupTable.attributes = {
      'aria-activedescendant': {
        type: 'idref',
        allowEmpty: true,
        unsupported: false
      },
      'aria-atomic': {
        type: 'boolean',
        values: [ 'true', 'false' ],
        unsupported: false
      },
      'aria-autocomplete': {
        type: 'nmtoken',
        values: [ 'inline', 'list', 'both', 'none' ],
        unsupported: false
      },
      'aria-busy': {
        type: 'boolean',
        values: [ 'true', 'false' ],
        unsupported: false
      },
      'aria-checked': {
        type: 'nmtoken',
        values: [ 'true', 'false', 'mixed', 'undefined' ],
        unsupported: false
      },
      'aria-colcount': {
        type: 'int',
        unsupported: false
      },
      'aria-colindex': {
        type: 'int',
        unsupported: false
      },
      'aria-colspan': {
        type: 'int',
        unsupported: false
      },
      'aria-controls': {
        type: 'idrefs',
        allowEmpty: true,
        unsupported: false
      },
      'aria-current': {
        type: 'nmtoken',
        allowEmpty: true,
        values: [ 'page', 'step', 'location', 'date', 'time', 'true', 'false' ],
        unsupported: false
      },
      'aria-describedby': {
        type: 'idrefs',
        allowEmpty: true,
        unsupported: false
      },
      'aria-describedat': {
        unsupported: true,
        unstandardized: true
      },
      'aria-details': {
        type: 'idref',
        allowEmpty: true,
        unsupported: false
      },
      'aria-disabled': {
        type: 'boolean',
        values: [ 'true', 'false' ],
        unsupported: false
      },
      'aria-dropeffect': {
        type: 'nmtokens',
        values: [ 'copy', 'move', 'reference', 'execute', 'popup', 'none' ],
        unsupported: false
      },
      'aria-errormessage': {
        type: 'idref',
        allowEmpty: true,
        unsupported: false
      },
      'aria-expanded': {
        type: 'nmtoken',
        values: [ 'true', 'false', 'undefined' ],
        unsupported: false
      },
      'aria-flowto': {
        type: 'idrefs',
        allowEmpty: true,
        unsupported: false
      },
      'aria-grabbed': {
        type: 'nmtoken',
        values: [ 'true', 'false', 'undefined' ],
        unsupported: false
      },
      'aria-haspopup': {
        type: 'nmtoken',
        allowEmpty: true,
        values: [ 'true', 'false', 'menu', 'listbox', 'tree', 'grid', 'dialog' ],
        unsupported: false
      },
      'aria-hidden': {
        type: 'boolean',
        values: [ 'true', 'false' ],
        unsupported: false
      },
      'aria-invalid': {
        type: 'nmtoken',
        allowEmpty: true,
        values: [ 'true', 'false', 'spelling', 'grammar' ],
        unsupported: false
      },
      'aria-keyshortcuts': {
        type: 'string',
        allowEmpty: true,
        unsupported: false
      },
      'aria-label': {
        type: 'string',
        allowEmpty: true,
        unsupported: false
      },
      'aria-labelledby': {
        type: 'idrefs',
        allowEmpty: true,
        unsupported: false
      },
      'aria-level': {
        type: 'int',
        unsupported: false
      },
      'aria-live': {
        type: 'nmtoken',
        values: [ 'off', 'polite', 'assertive' ],
        unsupported: false
      },
      'aria-modal': {
        type: 'boolean',
        values: [ 'true', 'false' ],
        unsupported: false
      },
      'aria-multiline': {
        type: 'boolean',
        values: [ 'true', 'false' ],
        unsupported: false
      },
      'aria-multiselectable': {
        type: 'boolean',
        values: [ 'true', 'false' ],
        unsupported: false
      },
      'aria-orientation': {
        type: 'nmtoken',
        values: [ 'horizontal', 'vertical' ],
        unsupported: false
      },
      'aria-owns': {
        type: 'idrefs',
        allowEmpty: true,
        unsupported: false
      },
      'aria-placeholder': {
        type: 'string',
        allowEmpty: true,
        unsupported: false
      },
      'aria-posinset': {
        type: 'int',
        unsupported: false
      },
      'aria-pressed': {
        type: 'nmtoken',
        values: [ 'true', 'false', 'mixed', 'undefined' ],
        unsupported: false
      },
      'aria-readonly': {
        type: 'boolean',
        values: [ 'true', 'false' ],
        unsupported: false
      },
      'aria-relevant': {
        type: 'nmtokens',
        values: [ 'additions', 'removals', 'text', 'all' ],
        unsupported: false
      },
      'aria-required': {
        type: 'boolean',
        values: [ 'true', 'false' ],
        unsupported: false
      },
      'aria-roledescription': {
        type: 'string',
        allowEmpty: true,
        unsupported: false
      },
      'aria-rowcount': {
        type: 'int',
        unsupported: false
      },
      'aria-rowindex': {
        type: 'int',
        unsupported: false
      },
      'aria-rowspan': {
        type: 'int',
        unsupported: false
      },
      'aria-selected': {
        type: 'nmtoken',
        values: [ 'true', 'false', 'undefined' ],
        unsupported: false
      },
      'aria-setsize': {
        type: 'int',
        unsupported: false
      },
      'aria-sort': {
        type: 'nmtoken',
        values: [ 'ascending', 'descending', 'other', 'none' ],
        unsupported: false
      },
      'aria-valuemax': {
        type: 'decimal',
        unsupported: false
      },
      'aria-valuemin': {
        type: 'decimal',
        unsupported: false
      },
      'aria-valuenow': {
        type: 'decimal',
        unsupported: false
      },
      'aria-valuetext': {
        type: 'string',
        unsupported: false
      }
    };
    lookupTable.globalAttributes = [ 'aria-atomic', 'aria-busy', 'aria-controls', 'aria-current', 'aria-describedby', 'aria-details', 'aria-disabled', 'aria-dropeffect', 'aria-flowto', 'aria-grabbed', 'aria-haspopup', 'aria-hidden', 'aria-invalid', 'aria-keyshortcuts', 'aria-label', 'aria-labelledby', 'aria-live', 'aria-owns', 'aria-relevant', 'aria-roledescription' ];
    lookupTable.role = {
      alert: {
        type: 'widget',
        attributes: {
          allowed: [ 'aria-expanded', 'aria-errormessage' ]
        },
        owned: null,
        nameFrom: [ 'author' ],
        context: null,
        unsupported: false,
        allowedElements: [ 'section' ]
      },
      alertdialog: {
        type: 'widget',
        attributes: {
          allowed: [ 'aria-expanded', 'aria-modal', 'aria-errormessage' ]
        },
        owned: null,
        nameFrom: [ 'author' ],
        context: null,
        unsupported: false,
        allowedElements: [ 'dialog', 'section' ]
      },
      application: {
        type: 'landmark',
        attributes: {
          allowed: [ 'aria-expanded', 'aria-errormessage', 'aria-activedescendant' ]
        },
        owned: null,
        nameFrom: [ 'author' ],
        context: null,
        unsupported: false,
        allowedElements: [ 'article', 'audio', 'embed', 'iframe', 'object', 'section', 'svg', 'video' ]
      },
      article: {
        type: 'structure',
        attributes: {
          allowed: [ 'aria-expanded', 'aria-posinset', 'aria-setsize', 'aria-errormessage' ]
        },
        owned: null,
        nameFrom: [ 'author' ],
        context: null,
        implicit: [ 'article' ],
        unsupported: false
      },
      banner: {
        type: 'landmark',
        attributes: {
          allowed: [ 'aria-expanded', 'aria-errormessage' ]
        },
        owned: null,
        nameFrom: [ 'author' ],
        context: null,
        implicit: [ 'header' ],
        unsupported: false,
        allowedElements: [ 'section' ]
      },
      button: {
        type: 'widget',
        attributes: {
          allowed: [ 'aria-expanded', 'aria-pressed', 'aria-errormessage' ]
        },
        owned: null,
        nameFrom: [ 'author', 'contents' ],
        context: null,
        implicit: [ 'button', 'input[type="button"]', 'input[type="image"]', 'input[type="reset"]', 'input[type="submit"]', 'summary' ],
        unsupported: false,
        allowedElements: [ {
          nodeName: 'a',
          attributes: {
            href: isNotNull
          }
        } ]
      },
      cell: {
        type: 'structure',
        attributes: {
          allowed: [ 'aria-colindex', 'aria-colspan', 'aria-rowindex', 'aria-rowspan', 'aria-errormessage' ]
        },
        owned: null,
        nameFrom: [ 'author', 'contents' ],
        context: [ 'row' ],
        implicit: [ 'td', 'th' ],
        unsupported: false
      },
      checkbox: {
        type: 'widget',
        attributes: {
          allowed: [ 'aria-checked', 'aria-required', 'aria-readonly', 'aria-errormessage' ]
        },
        owned: null,
        nameFrom: [ 'author', 'contents' ],
        context: null,
        implicit: [ 'input[type="checkbox"]' ],
        unsupported: false,
        allowedElements: [ 'button' ]
      },
      columnheader: {
        type: 'structure',
        attributes: {
          allowed: [ 'aria-colindex', 'aria-colspan', 'aria-expanded', 'aria-rowindex', 'aria-rowspan', 'aria-required', 'aria-readonly', 'aria-selected', 'aria-sort', 'aria-errormessage' ]
        },
        owned: null,
        nameFrom: [ 'author', 'contents' ],
        context: [ 'row' ],
        implicit: [ 'th' ],
        unsupported: false
      },
      combobox: {
        type: 'composite',
        attributes: {
          allowed: [ 'aria-autocomplete', 'aria-required', 'aria-activedescendant', 'aria-orientation', 'aria-errormessage' ],
          required: [ 'aria-expanded' ]
        },
        owned: {
          all: [ 'listbox', 'tree', 'grid', 'dialog', 'textbox' ]
        },
        nameFrom: [ 'author' ],
        context: null,
        unsupported: false,
        allowedElements: [ {
          nodeName: 'input',
          properties: {
            type: [ 'text', 'search', 'tel', 'url', 'email' ]
          }
        } ]
      },
      command: {
        nameFrom: [ 'author' ],
        type: 'abstract',
        unsupported: false
      },
      complementary: {
        type: 'landmark',
        attributes: {
          allowed: [ 'aria-expanded', 'aria-errormessage' ]
        },
        owned: null,
        nameFrom: [ 'author' ],
        context: null,
        implicit: [ 'aside' ],
        unsupported: false,
        allowedElements: [ 'section' ]
      },
      composite: {
        nameFrom: [ 'author' ],
        type: 'abstract',
        unsupported: false
      },
      contentinfo: {
        type: 'landmark',
        attributes: {
          allowed: [ 'aria-expanded', 'aria-errormessage' ]
        },
        owned: null,
        nameFrom: [ 'author' ],
        context: null,
        implicit: [ 'footer' ],
        unsupported: false,
        allowedElements: [ 'section' ]
      },
      definition: {
        type: 'structure',
        attributes: {
          allowed: [ 'aria-expanded', 'aria-errormessage' ]
        },
        owned: null,
        nameFrom: [ 'author' ],
        context: null,
        implicit: [ 'dd', 'dfn' ],
        unsupported: false
      },
      dialog: {
        type: 'widget',
        attributes: {
          allowed: [ 'aria-expanded', 'aria-modal', 'aria-errormessage' ]
        },
        owned: null,
        nameFrom: [ 'author' ],
        context: null,
        implicit: [ 'dialog' ],
        unsupported: false,
        allowedElements: [ 'section' ]
      },
      directory: {
        type: 'structure',
        attributes: {
          allowed: [ 'aria-expanded', 'aria-errormessage' ]
        },
        owned: null,
        nameFrom: [ 'author', 'contents' ],
        context: null,
        unsupported: false,
        allowedElements: [ 'ol', 'ul' ]
      },
      document: {
        type: 'structure',
        attributes: {
          allowed: [ 'aria-expanded', 'aria-errormessage' ]
        },
        owned: null,
        nameFrom: [ 'author' ],
        context: null,
        implicit: [ 'body' ],
        unsupported: false,
        allowedElements: [ 'article', 'embed', 'iframe', 'object', 'section', 'svg' ]
      },
      'doc-abstract': {
        type: 'section',
        attributes: {
          allowed: [ 'aria-expanded', 'aria-errormessage' ]
        },
        owned: null,
        nameFrom: [ 'author' ],
        context: null,
        unsupported: false,
        allowedElements: [ 'section' ]
      },
      'doc-acknowledgments': {
        type: 'landmark',
        attributes: {
          allowed: [ 'aria-expanded', 'aria-errormessage' ]
        },
        owned: null,
        nameFrom: [ 'author' ],
        context: null,
        unsupported: false,
        allowedElements: [ 'section' ]
      },
      'doc-afterword': {
        type: 'landmark',
        attributes: {
          allowed: [ 'aria-expanded', 'aria-errormessage' ]
        },
        owned: null,
        nameFrom: [ 'author' ],
        context: null,
        unsupported: false,
        allowedElements: [ 'section' ]
      },
      'doc-appendix': {
        type: 'landmark',
        attributes: {
          allowed: [ 'aria-expanded', 'aria-errormessage' ]
        },
        owned: null,
        nameFrom: [ 'author' ],
        context: null,
        unsupported: false,
        allowedElements: [ 'section' ]
      },
      'doc-backlink': {
        type: 'link',
        attributes: {
          allowed: [ 'aria-expanded', 'aria-errormessage' ]
        },
        owned: null,
        nameFrom: [ 'author', 'contents' ],
        context: null,
        unsupported: false,
        allowedElements: [ {
          nodeName: 'a',
          attributes: {
            href: isNotNull
          }
        } ]
      },
      'doc-biblioentry': {
        type: 'listitem',
        attributes: {
          allowed: [ 'aria-expanded', 'aria-level', 'aria-posinset', 'aria-setsize', 'aria-errormessage' ]
        },
        owned: null,
        nameFrom: [ 'author' ],
        context: [ 'doc-bibliography' ],
        unsupported: false,
        allowedElements: [ 'li' ]
      },
      'doc-bibliography': {
        type: 'landmark',
        attributes: {
          allowed: [ 'aria-expanded', 'aria-errormessage' ]
        },
        owned: {
          one: [ 'doc-biblioentry' ]
        },
        nameFrom: [ 'author' ],
        context: null,
        unsupported: false,
        allowedElements: [ 'section' ]
      },
      'doc-biblioref': {
        type: 'link',
        attributes: {
          allowed: [ 'aria-expanded', 'aria-errormessage' ]
        },
        owned: null,
        nameFrom: [ 'author', 'contents' ],
        context: null,
        unsupported: false,
        allowedElements: [ {
          nodeName: 'a',
          attributes: {
            href: isNotNull
          }
        } ]
      },
      'doc-chapter': {
        type: 'landmark',
        attributes: {
          allowed: [ 'aria-expanded', 'aria-errormessage' ]
        },
        owned: null,
        namefrom: [ 'author' ],
        context: null,
        unsupported: false,
        allowedElements: [ 'section' ]
      },
      'doc-colophon': {
        type: 'section',
        attributes: {
          allowed: [ 'aria-expanded', 'aria-errormessage' ]
        },
        owned: null,
        namefrom: [ 'author' ],
        context: null,
        unsupported: false,
        allowedElements: [ 'section' ]
      },
      'doc-conclusion': {
        type: 'landmark',
        attributes: {
          allowed: [ 'aria-expanded', 'aria-errormessage' ]
        },
        owned: null,
        namefrom: [ 'author' ],
        context: null,
        unsupported: false,
        allowedElements: [ 'section' ]
      },
      'doc-cover': {
        type: 'img',
        attributes: {
          allowed: [ 'aria-expanded', 'aria-errormessage' ]
        },
        owned: null,
        namefrom: [ 'author' ],
        context: null,
        unsupported: false
      },
      'doc-credit': {
        type: 'section',
        attributes: {
          allowed: [ 'aria-expanded', 'aria-errormessage' ]
        },
        owned: null,
        namefrom: [ 'author' ],
        context: null,
        unsupported: false,
        allowedElements: [ 'section' ]
      },
      'doc-credits': {
        type: 'landmark',
        attributes: {
          allowed: [ 'aria-expanded', 'aria-errormessage' ]
        },
        owned: null,
        namefrom: [ 'author' ],
        context: null,
        unsupported: false,
        allowedElements: [ 'section' ]
      },
      'doc-dedication': {
        type: 'section',
        attributes: {
          allowed: [ 'aria-expanded', 'aria-errormessage' ]
        },
        owned: null,
        namefrom: [ 'author' ],
        context: null,
        unsupported: false,
        allowedElements: [ 'section' ]
      },
      'doc-endnote': {
        type: 'listitem',
        attributes: {
          allowed: [ 'aria-expanded', 'aria-level', 'aria-posinset', 'aria-setsize', 'aria-errormessage' ]
        },
        owned: null,
        namefrom: [ 'author' ],
        context: [ 'doc-endnotes' ],
        unsupported: false,
        allowedElements: [ 'li' ]
      },
      'doc-endnotes': {
        type: 'landmark',
        attributes: {
          allowed: [ 'aria-expanded', 'aria-errormessage' ]
        },
        owned: {
          one: [ 'doc-endnote' ]
        },
        namefrom: [ 'author' ],
        context: null,
        unsupported: false,
        allowedElements: [ 'section' ]
      },
      'doc-epigraph': {
        type: 'section',
        attributes: {
          allowed: [ 'aria-expanded', 'aria-errormessage' ]
        },
        owned: null,
        namefrom: [ 'author' ],
        context: null,
        unsupported: false
      },
      'doc-epilogue': {
        type: 'landmark',
        attributes: {
          allowed: [ 'aria-expanded', 'aria-errormessage' ]
        },
        owned: null,
        namefrom: [ 'author' ],
        context: null,
        unsupported: false,
        allowedElements: [ 'section' ]
      },
      'doc-errata': {
        type: 'landmark',
        attributes: {
          allowed: [ 'aria-expanded', 'aria-errormessage' ]
        },
        owned: null,
        namefrom: [ 'author' ],
        context: null,
        unsupported: false,
        allowedElements: [ 'section' ]
      },
      'doc-example': {
        type: 'section',
        attributes: {
          allowed: [ 'aria-expanded', 'aria-errormessage' ]
        },
        owned: null,
        namefrom: [ 'author' ],
        context: null,
        unsupported: false,
        allowedElements: [ 'aside', 'section' ]
      },
      'doc-footnote': {
        type: 'section',
        attributes: {
          allowed: [ 'aria-expanded', 'aria-errormessage' ]
        },
        owned: null,
        namefrom: [ 'author' ],
        context: null,
        unsupported: false,
        allowedElements: [ 'aside', 'footer', 'header' ]
      },
      'doc-foreword': {
        type: 'landmark',
        attributes: {
          allowed: [ 'aria-expanded', 'aria-errormessage' ]
        },
        owned: null,
        namefrom: [ 'author' ],
        context: null,
        unsupported: false,
        allowedElements: [ 'section' ]
      },
      'doc-glossary': {
        type: 'landmark',
        attributes: {
          allowed: [ 'aria-expanded', 'aria-errormessage' ]
        },
        owned: [ 'term', 'definition' ],
        namefrom: [ 'author' ],
        context: null,
        unsupported: false,
        allowedElements: [ 'dl' ]
      },
      'doc-glossref': {
        type: 'link',
        attributes: {
          allowed: [ 'aria-expanded', 'aria-errormessage' ]
        },
        owned: null,
        namefrom: [ 'author', 'contents' ],
        context: null,
        unsupported: false,
        allowedElements: [ {
          nodeName: 'a',
          attributes: {
            href: isNotNull
          }
        } ]
      },
      'doc-index': {
        type: 'navigation',
        attributes: {
          allowed: [ 'aria-expanded', 'aria-errormessage' ]
        },
        owned: null,
        namefrom: [ 'author' ],
        context: null,
        unsupported: false,
        allowedElements: [ 'nav', 'section' ]
      },
      'doc-introduction': {
        type: 'landmark',
        attributes: {
          allowed: [ 'aria-expanded', 'aria-errormessage' ]
        },
        owned: null,
        namefrom: [ 'author' ],
        context: null,
        unsupported: false,
        allowedElements: [ 'section' ]
      },
      'doc-noteref': {
        type: 'link',
        attributes: {
          allowed: [ 'aria-expanded' ]
        },
        owned: null,
        namefrom: [ 'author', 'contents' ],
        context: null,
        unsupported: false,
        allowedElements: [ {
          nodeName: 'a',
          attributes: {
            href: isNotNull
          }
        } ]
      },
      'doc-notice': {
        type: 'note',
        attributes: {
          allowed: [ 'aria-expanded' ]
        },
        owned: null,
        namefrom: [ 'author' ],
        context: null,
        unsupported: false,
        allowedElements: [ 'section' ]
      },
      'doc-pagebreak': {
        type: 'separator',
        attributes: {
          allowed: [ 'aria-expanded' ]
        },
        owned: null,
        namefrom: [ 'author' ],
        context: null,
        unsupported: false,
        allowedElements: [ 'hr' ]
      },
      'doc-pagelist': {
        type: 'navigation',
        attributes: {
          allowed: [ 'aria-expanded' ]
        },
        owned: null,
        namefrom: [ 'author' ],
        context: null,
        unsupported: false,
        allowedElements: [ 'nav', 'section' ]
      },
      'doc-part': {
        type: 'landmark',
        attributes: {
          allowed: [ 'aria-expanded' ]
        },
        owned: null,
        namefrom: [ 'author' ],
        context: null,
        unsupported: false,
        allowedElements: [ 'section' ]
      },
      'doc-preface': {
        type: 'landmark',
        attributes: {
          allowed: [ 'aria-expanded' ]
        },
        owned: null,
        namefrom: [ 'author' ],
        context: null,
        unsupported: false,
        allowedElements: [ 'section' ]
      },
      'doc-prologue': {
        type: 'landmark',
        attributes: {
          allowed: [ 'aria-expanded', 'aria-errormessage' ]
        },
        owned: null,
        namefrom: [ 'author' ],
        context: null,
        unsupported: false,
        allowedElements: [ 'section' ]
      },
      'doc-pullquote': {
        type: 'none',
        attributes: {
          allowed: [ 'aria-expanded' ]
        },
        owned: null,
        namefrom: [ 'author' ],
        context: null,
        unsupported: false,
        allowedElements: [ 'aside', 'section' ]
      },
      'doc-qna': {
        type: 'section',
        attributes: {
          allowed: [ 'aria-expanded' ]
        },
        owned: null,
        namefrom: [ 'author' ],
        context: null,
        unsupported: false,
        allowedElements: [ 'section' ]
      },
      'doc-subtitle': {
        type: 'sectionhead',
        attributes: {
          allowed: [ 'aria-expanded' ]
        },
        owned: null,
        namefrom: [ 'author' ],
        context: null,
        unsupported: false,
        allowedElements: {
          nodeName: [ 'h1', 'h2', 'h3', 'h4', 'h5', 'h6' ]
        }
      },
      'doc-tip': {
        type: 'note',
        attributes: {
          allowed: [ 'aria-expanded' ]
        },
        owned: null,
        namefrom: [ 'author' ],
        context: null,
        unsupported: false,
        allowedElements: [ 'aside' ]
      },
      'doc-toc': {
        type: 'navigation',
        attributes: {
          allowed: [ 'aria-expanded', 'aria-errormessage' ]
        },
        owned: null,
        namefrom: [ 'author' ],
        context: null,
        unsupported: false,
        allowedElements: [ 'nav', 'section' ]
      },
      feed: {
        type: 'structure',
        attributes: {
          allowed: [ 'aria-expanded', 'aria-errormessage' ]
        },
        owned: {
          one: [ 'article' ]
        },
        nameFrom: [ 'author' ],
        context: null,
        unsupported: false,
        allowedElements: [ 'article', 'aside', 'section' ]
      },
      figure: {
        type: 'structure',
        attributes: {
          allowed: [ 'aria-expanded', 'aria-errormessage' ]
        },
        owned: null,
        nameFrom: [ 'author', 'contents' ],
        context: null,
        implicit: [ 'figure' ],
        unsupported: false
      },
      form: {
        type: 'landmark',
        attributes: {
          allowed: [ 'aria-expanded', 'aria-errormessage' ]
        },
        owned: null,
        nameFrom: [ 'author' ],
        context: null,
        implicit: [ 'form' ],
        unsupported: false
      },
      grid: {
        type: 'composite',
        attributes: {
          allowed: [ 'aria-activedescendant', 'aria-expanded', 'aria-colcount', 'aria-level', 'aria-multiselectable', 'aria-readonly', 'aria-rowcount', 'aria-errormessage' ]
        },
        owned: {
          one: [ 'rowgroup', 'row' ]
        },
        nameFrom: [ 'author' ],
        context: null,
        implicit: [ 'table' ],
        unsupported: false
      },
      gridcell: {
        type: 'widget',
        attributes: {
          allowed: [ 'aria-colindex', 'aria-colspan', 'aria-expanded', 'aria-rowindex', 'aria-rowspan', 'aria-selected', 'aria-readonly', 'aria-required', 'aria-errormessage' ]
        },
        owned: null,
        nameFrom: [ 'author', 'contents' ],
        context: [ 'row' ],
        implicit: [ 'td', 'th' ],
        unsupported: false
      },
      group: {
        type: 'structure',
        attributes: {
          allowed: [ 'aria-activedescendant', 'aria-expanded', 'aria-errormessage' ]
        },
        owned: null,
        nameFrom: [ 'author' ],
        context: null,
        implicit: [ 'details', 'optgroup' ],
        unsupported: false,
        allowedElements: [ 'dl', 'figcaption', 'fieldset', 'figure', 'footer', 'header', 'ol', 'ul' ]
      },
      heading: {
        type: 'structure',
        attributes: {
          required: [ 'aria-level' ],
          allowed: [ 'aria-expanded', 'aria-errormessage' ]
        },
        owned: null,
        nameFrom: [ 'author', 'contents' ],
        context: null,
        implicit: [ 'h1', 'h2', 'h3', 'h4', 'h5', 'h6' ],
        unsupported: false
      },
      img: {
        type: 'structure',
        attributes: {
          allowed: [ 'aria-expanded', 'aria-errormessage' ]
        },
        owned: null,
        nameFrom: [ 'author' ],
        context: null,
        implicit: [ 'img' ],
        unsupported: false,
        allowedElements: [ 'embed', 'iframe', 'object', 'svg' ]
      },
      input: {
        nameFrom: [ 'author' ],
        type: 'abstract',
        unsupported: false
      },
      landmark: {
        nameFrom: [ 'author' ],
        type: 'abstract',
        unsupported: false
      },
      link: {
        type: 'widget',
        attributes: {
          allowed: [ 'aria-expanded', 'aria-errormessage' ]
        },
        owned: null,
        nameFrom: [ 'author', 'contents' ],
        context: null,
        implicit: [ 'a[href]', 'area[href]' ],
        unsupported: false,
        allowedElements: [ 'button', {
          nodeName: 'input',
          properties: {
            type: [ 'image', 'button' ]
          }
        } ]
      },
      list: {
        type: 'structure',
        attributes: {
          allowed: [ 'aria-expanded', 'aria-errormessage' ]
        },
        owned: {
          all: [ 'listitem' ]
        },
        nameFrom: [ 'author' ],
        context: null,
        implicit: [ 'ol', 'ul', 'dl' ],
        unsupported: false
      },
      listbox: {
        type: 'composite',
        attributes: {
          allowed: [ 'aria-activedescendant', 'aria-multiselectable', 'aria-readonly', 'aria-required', 'aria-expanded', 'aria-orientation', 'aria-errormessage' ]
        },
        owned: {
          all: [ 'option' ]
        },
        nameFrom: [ 'author' ],
        context: null,
        implicit: [ 'select' ],
        unsupported: false,
        allowedElements: [ 'ol', 'ul' ]
      },
      listitem: {
        type: 'structure',
        attributes: {
          allowed: [ 'aria-level', 'aria-posinset', 'aria-setsize', 'aria-expanded', 'aria-errormessage' ]
        },
        owned: null,
        nameFrom: [ 'author', 'contents' ],
        context: [ 'list' ],
        implicit: [ 'li', 'dt' ],
        unsupported: false
      },
      log: {
        type: 'widget',
        attributes: {
          allowed: [ 'aria-expanded', 'aria-errormessage' ]
        },
        owned: null,
        nameFrom: [ 'author' ],
        context: null,
        unsupported: false,
        allowedElements: [ 'section' ]
      },
      main: {
        type: 'landmark',
        attributes: {
          allowed: [ 'aria-expanded', 'aria-errormessage' ]
        },
        owned: null,
        nameFrom: [ 'author' ],
        context: null,
        implicit: [ 'main' ],
        unsupported: false,
        allowedElements: [ 'article', 'section' ]
      },
      marquee: {
        type: 'widget',
        attributes: {
          allowed: [ 'aria-expanded', 'aria-errormessage' ]
        },
        owned: null,
        nameFrom: [ 'author' ],
        context: null,
        unsupported: false,
        allowedElements: [ 'section' ]
      },
      math: {
        type: 'structure',
        attributes: {
          allowed: [ 'aria-expanded', 'aria-errormessage' ]
        },
        owned: null,
        nameFrom: [ 'author' ],
        context: null,
        implicit: [ 'math' ],
        unsupported: false
      },
      menu: {
        type: 'composite',
        attributes: {
          allowed: [ 'aria-activedescendant', 'aria-expanded', 'aria-orientation', 'aria-errormessage' ]
        },
        owned: {
          one: [ 'menuitem', 'menuitemradio', 'menuitemcheckbox' ]
        },
        nameFrom: [ 'author' ],
        context: null,
        implicit: [ 'menu[type="context"]' ],
        unsupported: false,
        allowedElements: [ 'ol', 'ul' ]
      },
      menubar: {
        type: 'composite',
        attributes: {
          allowed: [ 'aria-activedescendant', 'aria-expanded', 'aria-orientation', 'aria-errormessage' ]
        },
        owned: {
          one: [ 'menuitem', 'menuitemradio', 'menuitemcheckbox' ]
        },
        nameFrom: [ 'author' ],
        context: null,
        unsupported: false,
        allowedElements: [ 'ol', 'ul' ]
      },
      menuitem: {
        type: 'widget',
        attributes: {
          allowed: [ 'aria-posinset', 'aria-setsize', 'aria-expanded', 'aria-errormessage' ]
        },
        owned: null,
        nameFrom: [ 'author', 'contents' ],
        context: [ 'menu', 'menubar' ],
        implicit: [ 'menuitem[type="command"]' ],
        unsupported: false,
        allowedElements: [ 'button', 'li', {
          nodeName: 'iput',
          properties: {
            type: [ 'image', 'button' ]
          }
        }, {
          nodeName: 'a',
          attributes: {
            href: isNotNull
          }
        } ]
      },
      menuitemcheckbox: {
        type: 'widget',
        attributes: {
          allowed: [ 'aria-checked', 'aria-posinset', 'aria-setsize', 'aria-errormessage' ]
        },
        owned: null,
        nameFrom: [ 'author', 'contents' ],
        context: [ 'menu', 'menubar' ],
        implicit: [ 'menuitem[type="checkbox"]' ],
        unsupported: false,
        allowedElements: [ {
          nodeName: [ 'button', 'li' ]
        }, {
          nodeName: 'input',
          properties: {
            type: [ 'checkbox', 'image', 'button' ]
          }
        }, {
          nodeName: 'a',
          attributes: {
            href: isNotNull
          }
        } ]
      },
      menuitemradio: {
        type: 'widget',
        attributes: {
          allowed: [ 'aria-checked', 'aria-selected', 'aria-posinset', 'aria-setsize', 'aria-errormessage' ]
        },
        owned: null,
        nameFrom: [ 'author', 'contents' ],
        context: [ 'menu', 'menubar' ],
        implicit: [ 'menuitem[type="radio"]' ],
        unsupported: false,
        allowedElements: [ {
          nodeName: [ 'button', 'li' ]
        }, {
          nodeName: 'input',
          properties: {
            type: [ 'image', 'button', 'radio' ]
          }
        }, {
          nodeName: 'a',
          attributes: {
            href: isNotNull
          }
        } ]
      },
      navigation: {
        type: 'landmark',
        attributes: {
          allowed: [ 'aria-expanded', 'aria-errormessage' ]
        },
        owned: null,
        nameFrom: [ 'author' ],
        context: null,
        implicit: [ 'nav' ],
        unsupported: false,
        allowedElements: [ 'section' ]
      },
      none: {
        type: 'structure',
        attributes: null,
        owned: null,
        nameFrom: [ 'author' ],
        context: null,
        unsupported: false,
        allowedElements: [ {
          nodeName: [ 'article', 'aside', 'dl', 'embed', 'figcaption', 'fieldset', 'figure', 'footer', 'form', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'header', 'hr', 'iframe', 'li', 'ol', 'section', 'ul' ]
        }, {
          nodeName: 'img',
          attributes: {
            alt: isNotNull
          }
        } ]
      },
      note: {
        type: 'structure',
        attributes: {
          allowed: [ 'aria-expanded', 'aria-errormessage' ]
        },
        owned: null,
        nameFrom: [ 'author' ],
        context: null,
        unsupported: false,
        allowedElements: [ 'aside' ]
      },
      option: {
        type: 'widget',
        attributes: {
          allowed: [ 'aria-selected', 'aria-posinset', 'aria-setsize', 'aria-checked', 'aria-errormessage' ]
        },
        owned: null,
        nameFrom: [ 'author', 'contents' ],
        context: [ 'listbox' ],
        implicit: [ 'option' ],
        unsupported: false,
        allowedElements: [ {
          nodeName: [ 'button', 'li' ]
        }, {
          nodeName: 'input',
          properties: {
            type: [ 'checkbox', 'button' ]
          }
        }, {
          nodeName: 'a',
          attributes: {
            href: isNotNull
          }
        } ]
      },
      presentation: {
        type: 'structure',
        attributes: null,
        owned: null,
        nameFrom: [ 'author' ],
        context: null,
        unsupported: false,
        allowedElements: [ {
          nodeName: [ 'article', 'aside', 'dl', 'embed', 'figcaption', 'fieldset', 'figure', 'footer', 'form', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'header', 'hr', 'iframe', 'li', 'ol', 'section', 'ul' ]
        }, {
          nodeName: 'img',
          attributes: {
            alt: isNotNull
          }
        } ]
      },
      progressbar: {
        type: 'widget',
        attributes: {
          allowed: [ 'aria-valuetext', 'aria-valuenow', 'aria-valuemax', 'aria-valuemin', 'aria-expanded', 'aria-errormessage' ]
        },
        owned: null,
        nameFrom: [ 'author' ],
        context: null,
        implicit: [ 'progress' ],
        unsupported: false
      },
      radio: {
        type: 'widget',
        attributes: {
          allowed: [ 'aria-selected', 'aria-posinset', 'aria-setsize', 'aria-required', 'aria-errormessage', 'aria-checked' ]
        },
        owned: null,
        nameFrom: [ 'author', 'contents' ],
        context: null,
        implicit: [ 'input[type="radio"]' ],
        unsupported: false,
        allowedElements: [ {
          nodeName: [ 'button', 'li' ]
        }, {
          nodeName: 'input',
          properties: {
            type: [ 'image', 'button' ]
          }
        } ]
      },
      radiogroup: {
        type: 'composite',
        attributes: {
          allowed: [ 'aria-activedescendant', 'aria-required', 'aria-expanded', 'aria-readonly', 'aria-errormessage', 'aria-orientation' ]
        },
        owned: {
          all: [ 'radio' ]
        },
        nameFrom: [ 'author' ],
        context: null,
        unsupported: false,
        allowedElements: {
          nodeName: [ 'ol', 'ul', 'fieldset' ]
        }
      },
      range: {
        nameFrom: [ 'author' ],
        type: 'abstract',
        unsupported: false
      },
      region: {
        type: 'landmark',
        attributes: {
          allowed: [ 'aria-expanded', 'aria-errormessage' ]
        },
        owned: null,
        nameFrom: [ 'author' ],
        context: null,
        implicit: [ 'section[aria-label]', 'section[aria-labelledby]', 'section[title]' ],
        unsupported: false,
        allowedElements: {
          nodeName: [ 'article', 'aside' ]
        }
      },
      roletype: {
        type: 'abstract',
        unsupported: false
      },
      row: {
        type: 'structure',
        attributes: {
          allowed: [ 'aria-activedescendant', 'aria-colindex', 'aria-expanded', 'aria-level', 'aria-selected', 'aria-rowindex', 'aria-errormessage' ]
        },
        owned: {
          one: [ 'cell', 'columnheader', 'rowheader', 'gridcell' ]
        },
        nameFrom: [ 'author', 'contents' ],
        context: [ 'rowgroup', 'grid', 'treegrid', 'table' ],
        implicit: [ 'tr' ],
        unsupported: false
      },
      rowgroup: {
        type: 'structure',
        attributes: {
          allowed: [ 'aria-activedescendant', 'aria-expanded', 'aria-errormessage' ]
        },
        owned: {
          all: [ 'row' ]
        },
        nameFrom: [ 'author', 'contents' ],
        context: [ 'grid', 'table', 'treegrid' ],
        implicit: [ 'tbody', 'thead', 'tfoot' ],
        unsupported: false
      },
      rowheader: {
        type: 'structure',
        attributes: {
          allowed: [ 'aria-colindex', 'aria-colspan', 'aria-expanded', 'aria-rowindex', 'aria-rowspan', 'aria-required', 'aria-readonly', 'aria-selected', 'aria-sort', 'aria-errormessage' ]
        },
        owned: null,
        nameFrom: [ 'author', 'contents' ],
        context: [ 'row' ],
        implicit: [ 'th' ],
        unsupported: false
      },
      scrollbar: {
        type: 'widget',
        attributes: {
          required: [ 'aria-controls', 'aria-valuenow' ],
          allowed: [ 'aria-valuetext', 'aria-orientation', 'aria-errormessage', 'aria-valuemax', 'aria-valuemin' ]
        },
        owned: null,
        nameFrom: [ 'author' ],
        context: null,
        unsupported: false
      },
      search: {
        type: 'landmark',
        attributes: {
          allowed: [ 'aria-expanded', 'aria-errormessage' ]
        },
        owned: null,
        nameFrom: [ 'author' ],
        context: null,
        unsupported: false,
        allowedElements: {
          nodeName: [ 'aside', 'form', 'section' ]
        }
      },
      searchbox: {
        type: 'widget',
        attributes: {
          allowed: [ 'aria-activedescendant', 'aria-autocomplete', 'aria-multiline', 'aria-readonly', 'aria-required', 'aria-placeholder', 'aria-errormessage' ]
        },
        owned: null,
        nameFrom: [ 'author' ],
        context: null,
        implicit: [ 'input[type="search"]' ],
        unsupported: false,
        allowedElements: {
          nodeName: 'input',
          properties: {
            type: 'text'
          }
        }
      },
      section: {
        nameFrom: [ 'author', 'contents' ],
        type: 'abstract',
        unsupported: false
      },
      sectionhead: {
        nameFrom: [ 'author', 'contents' ],
        type: 'abstract',
        unsupported: false
      },
      select: {
        nameFrom: [ 'author' ],
        type: 'abstract',
        unsupported: false
      },
      separator: {
        type: 'structure',
        attributes: {
          allowed: [ 'aria-expanded', 'aria-orientation', 'aria-valuenow', 'aria-valuemax', 'aria-valuemin', 'aria-valuetext', 'aria-errormessage' ]
        },
        owned: null,
        nameFrom: [ 'author' ],
        context: null,
        implicit: [ 'hr' ],
        unsupported: false,
        allowedElements: [ 'li' ]
      },
      slider: {
        type: 'widget',
        attributes: {
          allowed: [ 'aria-valuetext', 'aria-orientation', 'aria-readonly', 'aria-errormessage', 'aria-valuemax', 'aria-valuemin' ],
          required: [ 'aria-valuenow' ]
        },
        owned: null,
        nameFrom: [ 'author' ],
        context: null,
        implicit: [ 'input[type="range"]' ],
        unsupported: false
      },
      spinbutton: {
        type: 'widget',
        attributes: {
          allowed: [ 'aria-valuetext', 'aria-required', 'aria-readonly', 'aria-errormessage', 'aria-valuemax', 'aria-valuemin' ],
          required: [ 'aria-valuenow' ]
        },
        owned: null,
        nameFrom: [ 'author' ],
        context: null,
        implicit: [ 'input[type="number"]' ],
        unsupported: false,
        allowedElements: {
          nodeName: 'input',
          properties: {
            type: [ 'text', 'tel' ]
          }
        }
      },
      status: {
        type: 'widget',
        attributes: {
          allowed: [ 'aria-expanded', 'aria-errormessage' ]
        },
        owned: null,
        nameFrom: [ 'author' ],
        context: null,
        implicit: [ 'output' ],
        unsupported: false,
        allowedElements: [ 'section' ]
      },
      structure: {
        type: 'abstract',
        unsupported: false
      },
      switch: {
        type: 'widget',
        attributes: {
          allowed: [ 'aria-errormessage' ],
          required: [ 'aria-checked' ]
        },
        owned: null,
        nameFrom: [ 'author', 'contents' ],
        context: null,
        unsupported: false,
        allowedElements: [ 'button', {
          nodeName: 'input',
          properties: {
            type: [ 'checkbox', 'image', 'button' ]
          }
        }, {
          nodeName: 'a',
          attributes: {
            href: isNotNull
          }
        } ]
      },
      tab: {
        type: 'widget',
        attributes: {
          allowed: [ 'aria-selected', 'aria-expanded', 'aria-setsize', 'aria-posinset', 'aria-errormessage' ]
        },
        owned: null,
        nameFrom: [ 'author', 'contents' ],
        context: [ 'tablist' ],
        unsupported: false,
        allowedElements: [ {
          nodeName: [ 'button', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'li' ]
        }, {
          nodeName: 'input',
          properties: {
            type: 'button'
          }
        }, {
          nodeName: 'a',
          attributes: {
            href: isNotNull
          }
        } ]
      },
      table: {
        type: 'structure',
        attributes: {
          allowed: [ 'aria-colcount', 'aria-rowcount', 'aria-errormessage' ]
        },
        owned: {
          one: [ 'rowgroup', 'row' ]
        },
        nameFrom: [ 'author', 'contents' ],
        context: null,
        implicit: [ 'table' ],
        unsupported: false
      },
      tablist: {
        type: 'composite',
        attributes: {
          allowed: [ 'aria-activedescendant', 'aria-expanded', 'aria-level', 'aria-multiselectable', 'aria-orientation', 'aria-errormessage' ]
        },
        owned: {
          all: [ 'tab' ]
        },
        nameFrom: [ 'author' ],
        context: null,
        unsupported: false,
        allowedElements: [ 'ol', 'ul' ]
      },
      tabpanel: {
        type: 'widget',
        attributes: {
          allowed: [ 'aria-expanded', 'aria-errormessage' ]
        },
        owned: null,
        nameFrom: [ 'author' ],
        context: null,
        unsupported: false,
        allowedElements: [ 'section' ]
      },
      term: {
        type: 'structure',
        attributes: {
          allowed: [ 'aria-expanded', 'aria-errormessage' ]
        },
        owned: null,
        nameFrom: [ 'author', 'contents' ],
        context: null,
        implicit: [ 'dt' ],
        unsupported: false
      },
      textbox: {
        type: 'widget',
        attributes: {
          allowed: [ 'aria-activedescendant', 'aria-autocomplete', 'aria-multiline', 'aria-readonly', 'aria-required', 'aria-placeholder', 'aria-errormessage' ]
        },
        owned: null,
        nameFrom: [ 'author' ],
        context: null,
        implicit: [ 'input[type="text"]', 'input[type="email"]', 'input[type="password"]', 'input[type="tel"]', 'input[type="url"]', 'input:not([type])', 'textarea' ],
        unsupported: false
      },
      timer: {
        type: 'widget',
        attributes: {
          allowed: [ 'aria-expanded', 'aria-errormessage' ]
        },
        owned: null,
        nameFrom: [ 'author' ],
        context: null,
        unsupported: false
      },
      toolbar: {
        type: 'structure',
        attributes: {
          allowed: [ 'aria-activedescendant', 'aria-expanded', 'aria-orientation', 'aria-errormessage' ]
        },
        owned: null,
        nameFrom: [ 'author' ],
        context: null,
        implicit: [ 'menu[type="toolbar"]' ],
        unsupported: false,
        allowedElements: [ 'ol', 'ul' ]
      },
      tooltip: {
        type: 'structure',
        attributes: {
          allowed: [ 'aria-expanded', 'aria-errormessage' ]
        },
        owned: null,
        nameFrom: [ 'author', 'contents' ],
        context: null,
        unsupported: false
      },
      tree: {
        type: 'composite',
        attributes: {
          allowed: [ 'aria-activedescendant', 'aria-multiselectable', 'aria-required', 'aria-expanded', 'aria-orientation', 'aria-errormessage' ]
        },
        owned: {
          all: [ 'treeitem' ]
        },
        nameFrom: [ 'author' ],
        context: null,
        unsupported: false,
        allowedElements: [ 'ol', 'ul' ]
      },
      treegrid: {
        type: 'composite',
        attributes: {
          allowed: [ 'aria-activedescendant', 'aria-colcount', 'aria-expanded', 'aria-level', 'aria-multiselectable', 'aria-readonly', 'aria-required', 'aria-rowcount', 'aria-orientation', 'aria-errormessage' ]
        },
        owned: {
          one: [ 'rowgroup', 'row' ]
        },
        nameFrom: [ 'author' ],
        context: null,
        unsupported: false
      },
      treeitem: {
        type: 'widget',
        attributes: {
          allowed: [ 'aria-checked', 'aria-selected', 'aria-expanded', 'aria-level', 'aria-posinset', 'aria-setsize', 'aria-errormessage' ]
        },
        owned: null,
        nameFrom: [ 'author', 'contents' ],
        context: [ 'group', 'tree' ],
        unsupported: false,
        allowedElements: [ 'li', {
          nodeName: 'a',
          attributes: {
            href: isNotNull
          }
        } ]
      },
      widget: {
        type: 'abstract',
        unsupported: false
      },
      window: {
        nameFrom: [ 'author' ],
        type: 'abstract',
        unsupported: false
      }
    };
    lookupTable.implicitHtmlRole = implicit_html_roles_default;
    lookupTable.elementsAllowedNoRole = [ {
      nodeName: [ 'base', 'body', 'caption', 'col', 'colgroup', 'datalist', 'dd', 'details', 'dt', 'head', 'html', 'keygen', 'label', 'legend', 'main', 'map', 'math', 'meta', 'meter', 'noscript', 'optgroup', 'param', 'picture', 'progress', 'script', 'source', 'style', 'template', 'textarea', 'title', 'track' ]
    }, {
      nodeName: 'area',
      attributes: {
        href: isNotNull
      }
    }, {
      nodeName: 'input',
      properties: {
        type: [ 'color', 'data', 'datatime', 'file', 'hidden', 'month', 'number', 'password', 'range', 'reset', 'submit', 'time', 'week' ]
      }
    }, {
      nodeName: 'link',
      attributes: {
        href: isNotNull
      }
    }, {
      nodeName: 'menu',
      attributes: {
        type: 'context'
      }
    }, {
      nodeName: 'menuitem',
      attributes: {
        type: [ 'command', 'checkbox', 'radio' ]
      }
    }, {
      nodeName: 'select',
      condition: function condition(vNode) {
        if (!(vNode instanceof axe.AbstractVirtualNode)) {
          vNode = axe.utils.getNodeFromTree(vNode);
        }
        return Number(vNode.attr('size')) > 1;
      },
      properties: {
        multiple: true
      }
    }, {
      nodeName: [ 'clippath', 'cursor', 'defs', 'desc', 'feblend', 'fecolormatrix', 'fecomponenttransfer', 'fecomposite', 'feconvolvematrix', 'fediffuselighting', 'fedisplacementmap', 'fedistantlight', 'fedropshadow', 'feflood', 'fefunca', 'fefuncb', 'fefuncg', 'fefuncr', 'fegaussianblur', 'feimage', 'femerge', 'femergenode', 'femorphology', 'feoffset', 'fepointlight', 'fespecularlighting', 'fespotlight', 'fetile', 'feturbulence', 'filter', 'hatch', 'hatchpath', 'lineargradient', 'marker', 'mask', 'meshgradient', 'meshpatch', 'meshrow', 'metadata', 'mpath', 'pattern', 'radialgradient', 'solidcolor', 'stop', 'switch', 'view' ]
    } ];
    lookupTable.elementsAllowedAnyRole = [ {
      nodeName: 'a',
      attributes: {
        href: isNull
      }
    }, {
      nodeName: 'img',
      attributes: {
        alt: isNull
      }
    }, {
      nodeName: [ 'abbr', 'address', 'canvas', 'div', 'p', 'pre', 'blockquote', 'ins', 'del', 'output', 'span', 'table', 'tbody', 'thead', 'tfoot', 'td', 'em', 'strong', 'small', 's', 'cite', 'q', 'dfn', 'abbr', 'time', 'code', 'var', 'samp', 'kbd', 'sub', 'sup', 'i', 'b', 'u', 'mark', 'ruby', 'rt', 'rp', 'bdi', 'bdo', 'br', 'wbr', 'th', 'tr' ]
    } ];
    lookupTable.evaluateRoleForElement = {
      A: function A(_ref33) {
        var node = _ref33.node, out = _ref33.out;
        if (node.namespaceURI === 'http://www.w3.org/2000/svg') {
          return true;
        }
        if (node.href.length) {
          return out;
        }
        return true;
      },
      AREA: function AREA(_ref34) {
        var node = _ref34.node;
        return !node.href;
      },
      BUTTON: function BUTTON(_ref35) {
        var node = _ref35.node, role = _ref35.role, out = _ref35.out;
        if (node.getAttribute('type') === 'menu') {
          return role === 'menuitem';
        }
        return out;
      },
      IMG: function IMG(_ref36) {
        var node = _ref36.node, role = _ref36.role, out = _ref36.out;
        switch (node.alt) {
         case null:
          return out;

         case '':
          return role === 'presentation' || role === 'none';

         default:
          return role !== 'presentation' && role !== 'none';
        }
      },
      INPUT: function INPUT(_ref37) {
        var node = _ref37.node, role = _ref37.role, out = _ref37.out;
        switch (node.type) {
         case 'button':
         case 'image':
          return out;

         case 'checkbox':
          if (role === 'button' && node.hasAttribute('aria-pressed')) {
            return true;
          }
          return out;

         case 'radio':
          return role === 'menuitemradio';

         case 'text':
          return role === 'combobox' || role === 'searchbox' || role === 'spinbutton';

         case 'tel':
          return role === 'combobox' || role === 'spinbutton';

         case 'url':
         case 'search':
         case 'email':
          return role === 'combobox';

         default:
          return false;
        }
      },
      LI: function LI(_ref38) {
        var node = _ref38.node, out = _ref38.out;
        var hasImplicitListitemRole = axe.utils.matchesSelector(node, 'ol li, ul li');
        if (hasImplicitListitemRole) {
          return out;
        }
        return true;
      },
      MENU: function MENU(_ref39) {
        var node = _ref39.node;
        if (node.getAttribute('type') === 'context') {
          return false;
        }
        return true;
      },
      OPTION: function OPTION(_ref40) {
        var node = _ref40.node;
        var withinOptionList = axe.utils.matchesSelector(node, 'select > option, datalist > option, optgroup > option');
        return !withinOptionList;
      },
      SELECT: function SELECT(_ref41) {
        var node = _ref41.node, role = _ref41.role;
        return !node.multiple && node.size <= 1 && role === 'menu';
      },
      SVG: function SVG(_ref42) {
        var node = _ref42.node, out = _ref42.out;
        if (node.parentNode && node.parentNode.namespaceURI === 'http://www.w3.org/2000/svg') {
          return true;
        }
        return out;
      }
    };
    lookupTable.rolesOfType = {
      widget: [ 'button', 'checkbox', 'dialog', 'gridcell', 'link', 'log', 'marquee', 'menuitem', 'menuitemcheckbox', 'menuitemradio', 'option', 'progressbar', 'radio', 'scrollbar', 'searchbox', 'slider', 'spinbutton', 'status', 'switch', 'tab', 'tabpanel', 'textbox', 'timer', 'tooltip', 'tree', 'treeitem' ]
    };
    var lookup_table_default = lookupTable;
    function implicitNodes(role) {
      var implicit = null;
      var roles = lookup_table_default.role[role];
      if (roles && roles.implicit) {
        implicit = clone_default(roles.implicit);
      }
      return implicit;
    }
    var implicit_nodes_default = implicitNodes;
    function isAccessibleRef(node) {
      return !!get_accessible_refs_default(node).length;
    }
    var is_accessible_ref_default = isAccessibleRef;
    function label3(node) {
      node = get_node_from_tree_default(node);
      return label_virtual_default(node);
    }
    var label_default2 = label3;
    function requiredAttr(role) {
      var roleDef = standards_default.ariaRoles[role];
      if (!roleDef || !Array.isArray(roleDef.requiredAttrs)) {
        return [];
      }
      return _toConsumableArray(roleDef.requiredAttrs);
    }
    var required_attr_default = requiredAttr;
    function requiredContext(role) {
      var roleDef = standards_default.ariaRoles[role];
      if (!roleDef || !Array.isArray(roleDef.requiredContext)) {
        return null;
      }
      return _toConsumableArray(roleDef.requiredContext);
    }
    var required_context_default = requiredContext;
    function requiredOwned(role) {
      var roleDef = standards_default.ariaRoles[role];
      if (!roleDef || !Array.isArray(roleDef.requiredOwned)) {
        return null;
      }
      return _toConsumableArray(roleDef.requiredOwned);
    }
    var required_owned_default = requiredOwned;
    function validateAttrValue(node, attr) {
      var matches14;
      var list;
      var value = node.getAttribute(attr);
      var attrInfo = standards_default.ariaAttrs[attr];
      var doc = get_root_node_default2(node);
      if (!attrInfo) {
        return true;
      }
      if (attrInfo.allowEmpty && (!value || value.trim() === '')) {
        return true;
      }
      switch (attrInfo.type) {
       case 'boolean':
        return [ 'true', 'false' ].includes(value.toLowerCase());

       case 'nmtoken':
        return typeof value === 'string' && attrInfo.values.includes(value.toLowerCase());

       case 'nmtokens':
        list = token_list_default(value);
        return list.reduce(function(result, token) {
          return result && attrInfo.values.includes(token);
        }, list.length !== 0);

       case 'idref':
        return !!(value && doc.getElementById(value));

       case 'idrefs':
        list = token_list_default(value);
        return list.some(function(token) {
          return doc.getElementById(token);
        });

       case 'string':
        return value.trim() !== '';

       case 'decimal':
        matches14 = value.match(/^[-+]?([0-9]*)\.?([0-9]*)$/);
        return !!(matches14 && (matches14[1] || matches14[2]));

       case 'int':
        var minValue = typeof attrInfo.minValue !== 'undefined' ? attrInfo.minValue : -Infinity;
        return /^[-+]?[0-9]+$/.test(value) && parseInt(value) >= minValue;
      }
    }
    var validate_attr_value_default = validateAttrValue;
    function validateAttr(att) {
      var attrDefinition = standards_default.ariaAttrs[att];
      return !!attrDefinition;
    }
    var validate_attr_default = validateAttr;
    function abstractroleEvaluate(node, options, virtualNode) {
      var abstractRoles = token_list_default(virtualNode.attr('role')).filter(function(role) {
        return get_role_type_default(role) === 'abstract';
      });
      if (abstractRoles.length > 0) {
        this.data(abstractRoles);
        return true;
      }
      return false;
    }
    var abstractrole_evaluate_default = abstractroleEvaluate;
    function ariaAllowedAttrEvaluate(node, options, virtualNode) {
      var invalid = [];
      var role = get_role_default(virtualNode);
      var attrs = virtualNode.attrNames;
      var allowed = allowed_attr_default(role);
      if (Array.isArray(options[role])) {
        allowed = unique_array_default(options[role].concat(allowed));
      }
      if (role && allowed) {
        for (var _i13 = 0; _i13 < attrs.length; _i13++) {
          var attrName = attrs[_i13];
          if (validate_attr_default(attrName) && !allowed.includes(attrName)) {
            invalid.push(attrName + '="' + virtualNode.attr(attrName) + '"');
          }
        }
      }
      if (invalid.length) {
        this.data(invalid);
        return false;
      }
      return true;
    }
    var aria_allowed_attr_evaluate_default = ariaAllowedAttrEvaluate;
    function ariaAllowedRoledEvaluate(node) {
      var options = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : {};
      var _options$allowImplici = options.allowImplicit, allowImplicit = _options$allowImplici === void 0 ? true : _options$allowImplici, _options$ignoredTags = options.ignoredTags, ignoredTags = _options$ignoredTags === void 0 ? [] : _options$ignoredTags;
      var tagName = node.nodeName.toUpperCase();
      if (ignoredTags.map(function(t) {
        return t.toUpperCase();
      }).includes(tagName)) {
        return true;
      }
      var unallowedRoles = get_element_unallowed_roles_default(node, allowImplicit);
      if (unallowedRoles.length) {
        this.data(unallowedRoles);
        if (!is_visible_default(node, true)) {
          return void 0;
        }
        return false;
      }
      return true;
    }
    var aria_allowed_role_evaluate_default = ariaAllowedRoledEvaluate;
    function ariaErrormessageEvaluate(node, options) {
      options = Array.isArray(options) ? options : [];
      var attr = node.getAttribute('aria-errormessage');
      var hasAttr = node.hasAttribute('aria-errormessage');
      var invaid = node.getAttribute('aria-invalid');
      var hasInvallid = node.hasAttribute('aria-invalid');
      if (!hasInvallid || invaid === 'false') {
        return true;
      }
      var doc = get_root_node_default2(node);
      function validateAttrValue2(attr2) {
        if (attr2.trim() === '') {
          return standards_default.ariaAttrs['aria-errormessage'].allowEmpty;
        }
        var idref = attr2 && doc.getElementById(attr2);
        if (idref) {
          return idref.getAttribute('role') === 'alert' || idref.getAttribute('aria-live') === 'assertive' || idref.getAttribute('aria-live') === 'polite' || token_list_default(node.getAttribute('aria-describedby')).indexOf(attr2) > -1;
        }
        return;
      }
      if (options.indexOf(attr) === -1 && hasAttr) {
        this.data(token_list_default(attr));
        return validateAttrValue2(attr);
      }
      return true;
    }
    var aria_errormessage_evaluate_default = ariaErrormessageEvaluate;
    function ariaHiddenBodyEvaluate(node, options, virtualNode) {
      return virtualNode.attr('aria-hidden') !== 'true';
    }
    var aria_hidden_body_evaluate_default = ariaHiddenBodyEvaluate;
    function ariaProhibitedAttrEvaluate(node, options, virtualNode) {
      var prohibited = [];
      var role = get_role_default(virtualNode);
      var attrs = virtualNode.attrNames;
      var prohibitedAttrs = role ? standards_default.ariaRoles[role].prohibitedAttrs : [ 'aria-label', 'aria-labelledby' ];
      if (!prohibitedAttrs) {
        return false;
      }
      for (var _i14 = 0; _i14 < attrs.length; _i14++) {
        var attrName = attrs[_i14];
        var attrValue = sanitize_default(virtualNode.attr(attrName));
        if (prohibitedAttrs.includes(attrName) && attrValue !== '') {
          prohibited.push(attrName);
        }
      }
      if (prohibited.length) {
        this.data(prohibited);
        if (!role && sanitize_default(subtree_text_default(virtualNode)) !== '') {
          return void 0;
        }
        return true;
      }
      return false;
    }
    var aria_prohibited_attr_evaluate_default = ariaProhibitedAttrEvaluate;
    var standards_exports = {};
    __export(standards_exports, {
      getAriaRolesByType: function getAriaRolesByType() {
        return get_aria_roles_by_type_default;
      },
      getAriaRolesSupportingNameFromContent: function getAriaRolesSupportingNameFromContent() {
        return get_aria_roles_supporting_name_from_content_default;
      },
      getElementSpec: function getElementSpec() {
        return get_element_spec_default;
      },
      getElementsByContentType: function getElementsByContentType() {
        return get_elements_by_content_type_default;
      },
      getGlobalAriaAttrs: function getGlobalAriaAttrs() {
        return get_global_aria_attrs_default;
      },
      implicitHtmlRoles: function implicitHtmlRoles() {
        return implicit_html_roles_default;
      }
    });
    function ariaRequiredAttrEvaluate(node) {
      var options = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : {};
      var virtualNode = arguments.length > 2 ? arguments[2] : undefined;
      var missing = [];
      var attrs = virtualNode.attrNames;
      if (attrs.length) {
        var role = get_explicit_role_default(virtualNode);
        var required = required_attr_default(role);
        var elmSpec = get_element_spec_default(virtualNode);
        if (Array.isArray(options[role])) {
          required = unique_array_default(options[role], required);
        }
        if (role && required) {
          for (var _i15 = 0, l = required.length; _i15 < l; _i15++) {
            var attr = required[_i15];
            if (!virtualNode.attr(attr) && !(elmSpec.implicitAttrs && typeof elmSpec.implicitAttrs[attr] !== 'undefined')) {
              missing.push(attr);
            }
          }
        }
      }
      if (missing.length) {
        this.data(missing);
        return false;
      }
      return true;
    }
    var aria_required_attr_evaluate_default = ariaRequiredAttrEvaluate;
    function getOwnedRoles(virtualNode, required) {
      var ownedRoles = [];
      var ownedElements = get_owned_virtual_default(virtualNode);
      var _loop4 = function _loop4(_i16) {
        var ownedElement = ownedElements[_i16];
        var role = get_role_default(ownedElement, {
          noPresentational: true
        });
        if (!role || [ 'group', 'rowgroup' ].includes(role) && required.some(function(requiredRole) {
          return requiredRole === role;
        })) {
          ownedElements.push.apply(ownedElements, _toConsumableArray(ownedElement.children));
        } else if (role) {
          ownedRoles.push(role);
        }
      };
      for (var _i16 = 0; _i16 < ownedElements.length; _i16++) {
        _loop4(_i16);
      }
      return ownedRoles;
    }
    function missingRequiredChildren(virtualNode, role, required, ownedRoles) {
      var isCombobox = role === 'combobox';
      if (isCombobox) {
        var textTypeInputs = [ 'text', 'search', 'email', 'url', 'tel' ];
        if (virtualNode.props.nodeName === 'input' && textTypeInputs.includes(virtualNode.props.type) || ownedRoles.includes('searchbox')) {
          required = required.filter(function(requiredRole) {
            return requiredRole !== 'textbox';
          });
        }
        var expandedChildRoles = [ 'listbox', 'tree', 'grid', 'dialog' ];
        var expandedValue = virtualNode.attr('aria-expanded');
        var expanded = expandedValue && expandedValue.toLowerCase() !== 'false';
        var popupRole = (virtualNode.attr('aria-haspopup') || 'listbox').toLowerCase();
        required = required.filter(function(requiredRole) {
          return !expandedChildRoles.includes(requiredRole) || expanded && requiredRole === popupRole;
        });
      }
      for (var _i17 = 0; _i17 < ownedRoles.length; _i17++) {
        var ownedRole = ownedRoles[_i17];
        if (required.includes(ownedRole)) {
          required = required.filter(function(requiredRole) {
            return requiredRole !== ownedRole;
          });
          if (!isCombobox) {
            return null;
          }
        }
      }
      if (required.length) {
        return required;
      }
      return null;
    }
    function ariaRequiredChildrenEvaluate(node, options, virtualNode) {
      var reviewEmpty = options && Array.isArray(options.reviewEmpty) ? options.reviewEmpty : [];
      var role = get_explicit_role_default(virtualNode, {
        dpub: true
      });
      var required = required_owned_default(role);
      if (required === null) {
        return true;
      }
      var ownedRoles = getOwnedRoles(virtualNode, required);
      var missing = missingRequiredChildren(virtualNode, role, required, ownedRoles);
      if (!missing) {
        return true;
      }
      this.data(missing);
      if (reviewEmpty.includes(role) && !has_content_virtual_default(virtualNode, false, true) && !ownedRoles.length && (!virtualNode.hasAttr('aria-owns') || !idrefs_default(node, 'aria-owns').length)) {
        return void 0;
      }
      return false;
    }
    var aria_required_children_evaluate_default = ariaRequiredChildrenEvaluate;
    function getMissingContext(virtualNode, reqContext, includeElement) {
      var explicitRole2 = get_explicit_role_default(virtualNode);
      if (!reqContext) {
        reqContext = required_context_default(explicitRole2);
      }
      if (!reqContext) {
        return null;
      }
      var vNode = includeElement ? virtualNode : virtualNode.parent;
      while (vNode) {
        var parentRole = get_role_default(vNode);
        if (reqContext.includes('group') && parentRole === 'group') {
          vNode = vNode.parent;
          continue;
        }
        if (reqContext.includes(parentRole)) {
          return null;
        } else if (parentRole && ![ 'presentation', 'none' ].includes(parentRole)) {
          return reqContext;
        }
        vNode = vNode.parent;
      }
      return reqContext;
    }
    function getAriaOwners(element) {
      var owners = [], o = null;
      while (element) {
        if (element.getAttribute('id')) {
          var id = escape_selector_default(element.getAttribute('id'));
          var doc = get_root_node_default2(element);
          o = doc.querySelector('[aria-owns~='.concat(id, ']'));
          if (o) {
            owners.push(o);
          }
        }
        element = element.parentElement;
      }
      return owners.length ? owners : null;
    }
    function ariaRequiredParentEvaluate(node, options, virtualNode) {
      var missingParents = getMissingContext(virtualNode);
      if (!missingParents) {
        return true;
      }
      var owners = getAriaOwners(node);
      if (owners) {
        for (var i = 0, l = owners.length; i < l; i++) {
          missingParents = getMissingContext(get_node_from_tree_default(owners[i]), missingParents, true);
          if (!missingParents) {
            return true;
          }
        }
      }
      this.data(missingParents);
      return false;
    }
    var aria_required_parent_evaluate_default = ariaRequiredParentEvaluate;
    function ariaRoledescriptionEvaluate(node) {
      var options = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : {};
      var role = get_role_default(node);
      var supportedRoles = options.supportedRoles || [];
      if (supportedRoles.includes(role)) {
        return true;
      }
      if (role && role !== 'presentation' && role !== 'none') {
        return void 0;
      }
      return false;
    }
    var aria_roledescription_evaluate_default = ariaRoledescriptionEvaluate;
    function ariaUnsupportedAttrEvaluate(node, options, virtualNode) {
      var unsupportedAttrs = virtualNode.attrNames.filter(function(name) {
        var attribute = standards_default.ariaAttrs[name];
        if (!validate_attr_default(name)) {
          return false;
        }
        var unsupported4 = attribute.unsupported;
        if (_typeof(unsupported4) !== 'object') {
          return !!unsupported4;
        }
        return !matches_default3(node, unsupported4.exceptions);
      });
      if (unsupportedAttrs.length) {
        this.data(unsupportedAttrs);
        return true;
      }
      return false;
    }
    var aria_unsupported_attr_evaluate_default = ariaUnsupportedAttrEvaluate;
    function ariaValidAttrEvaluate(node, options) {
      options = Array.isArray(options.value) ? options.value : [];
      var invalid = [], aria43 = /^aria-/;
      var attr, attrs = get_node_attributes_default(node);
      for (var i = 0, l = attrs.length; i < l; i++) {
        attr = attrs[i].name;
        if (options.indexOf(attr) === -1 && aria43.test(attr) && !validate_attr_default(attr)) {
          invalid.push(attr);
        }
      }
      if (invalid.length) {
        this.data(invalid);
        return false;
      }
      return true;
    }
    var aria_valid_attr_evaluate_default = ariaValidAttrEvaluate;
    function ariaValidAttrValueEvaluate(node, options) {
      options = Array.isArray(options.value) ? options.value : [];
      var needsReview = '';
      var messageKey = '';
      var invalid = [];
      var aria43 = /^aria-/;
      var attrs = get_node_attributes_default(node);
      var skipAttrs = [ 'aria-errormessage' ];
      var preChecks = {
        'aria-controls': function ariaControls() {
          return node.getAttribute('aria-expanded') !== 'false' && node.getAttribute('aria-selected') !== 'false';
        },
        'aria-current': function ariaCurrent() {
          if (!validate_attr_value_default(node, 'aria-current')) {
            needsReview = 'aria-current="'.concat(node.getAttribute('aria-current'), '"');
            messageKey = 'ariaCurrent';
          }
          return;
        },
        'aria-owns': function ariaOwns() {
          return node.getAttribute('aria-expanded') !== 'false';
        },
        'aria-describedby': function ariaDescribedby() {
          if (!validate_attr_value_default(node, 'aria-describedby')) {
            needsReview = 'aria-describedby="'.concat(node.getAttribute('aria-describedby'), '"');
            messageKey = 'noId';
          }
          return;
        },
        'aria-labelledby': function ariaLabelledby() {
          if (!validate_attr_value_default(node, 'aria-labelledby')) {
            needsReview = 'aria-labelledby="'.concat(node.getAttribute('aria-labelledby'), '"');
            messageKey = 'noId';
          }
        }
      };
      for (var _i18 = 0, l = attrs.length; _i18 < l; _i18++) {
        var attr = attrs[_i18];
        var attrName = attr.name;
        if (!skipAttrs.includes(attrName) && options.indexOf(attrName) === -1 && aria43.test(attrName) && (preChecks[attrName] ? preChecks[attrName]() : true) && !validate_attr_value_default(node, attrName)) {
          invalid.push(''.concat(attrName, '="').concat(attr.nodeValue, '"'));
        }
      }
      if (needsReview) {
        this.data({
          messageKey: messageKey,
          needsReview: needsReview
        });
        return void 0;
      }
      if (invalid.length) {
        this.data(invalid);
        return false;
      }
      return true;
    }
    var aria_valid_attr_value_evaluate_default = ariaValidAttrValueEvaluate;
    function fallbackroleEvaluate(node, options, virtualNode) {
      return token_list_default(virtualNode.attr('role')).length > 1;
    }
    var fallbackrole_evaluate_default = fallbackroleEvaluate;
    function hasGlobalAriaAttributeEvaluate(node, options, virtualNode) {
      var globalAttrs = get_global_aria_attrs_default().filter(function(attr) {
        return virtualNode.hasAttr(attr);
      });
      this.data(globalAttrs);
      return globalAttrs.length > 0;
    }
    var has_global_aria_attribute_evaluate_default = hasGlobalAriaAttributeEvaluate;
    function hasWidgetRoleEvaluate(node) {
      var role = node.getAttribute('role');
      if (role === null) {
        return false;
      }
      var roleType = get_role_type_default(role);
      return roleType === 'widget' || roleType === 'composite';
    }
    var has_widget_role_evaluate_default = hasWidgetRoleEvaluate;
    function invalidroleEvaluate(node, options, virtualNode) {
      var allRoles = token_list_default(virtualNode.attr('role'));
      var allInvalid = allRoles.every(function(role) {
        return !is_valid_role_default(role, {
          allowAbstract: true
        });
      });
      if (allInvalid) {
        this.data(allRoles);
        return true;
      }
      return false;
    }
    var invalidrole_evaluate_default = invalidroleEvaluate;
    function isElementFocusableEvaluate(node, options, virtualNode) {
      return is_focusable_default(virtualNode);
    }
    var is_element_focusable_evaluate_default = isElementFocusableEvaluate;
    function noImplicitExplicitLabelEvaluate(node, options, virtualNode) {
      var role = get_role_default(virtualNode, {
        noImplicit: true
      });
      this.data(role);
      var label5;
      var accText;
      try {
        label5 = sanitize_default(label_text_default(virtualNode)).toLowerCase();
        accText = sanitize_default(accessible_text_virtual_default(virtualNode)).toLowerCase();
      } catch (e) {
        return void 0;
      }
      if (!accText && !label5) {
        return false;
      }
      if (!accText && label5) {
        return void 0;
      }
      if (!accText.includes(label5)) {
        return void 0;
      }
      return false;
    }
    var no_implicit_explicit_label_evaluate_default = noImplicitExplicitLabelEvaluate;
    function unsupportedroleEvaluate(node, options, virtualNode) {
      return is_unsupported_role_default(get_role_default(virtualNode));
    }
    var unsupportedrole_evaluate_default = unsupportedroleEvaluate;
    var VALID_TAG_NAMES_FOR_SCROLLABLE_REGIONS = {
      ARTICLE: true,
      ASIDE: true,
      NAV: true,
      SECTION: true
    };
    var VALID_ROLES_FOR_SCROLLABLE_REGIONS = {
      application: true,
      banner: false,
      complementary: true,
      contentinfo: true,
      form: true,
      main: true,
      navigation: true,
      region: true,
      search: false
    };
    function validScrollableTagName(node) {
      var nodeName2 = node.nodeName.toUpperCase();
      return VALID_TAG_NAMES_FOR_SCROLLABLE_REGIONS[nodeName2] || false;
    }
    function validScrollableRole(node, options) {
      var role = get_explicit_role_default(node);
      if (!role) {
        return false;
      }
      return VALID_ROLES_FOR_SCROLLABLE_REGIONS[role] || options.roles.includes(role) || false;
    }
    function validScrollableSemanticsEvaluate(node, options) {
      return validScrollableRole(node, options) || validScrollableTagName(node);
    }
    var valid_scrollable_semantics_evaluate_default = validScrollableSemanticsEvaluate;
    var table_exports = {};
    __export(table_exports, {
      getAllCells: function getAllCells() {
        return get_all_cells_default;
      },
      getCellPosition: function getCellPosition() {
        return get_cell_position_default;
      },
      getHeaders: function getHeaders() {
        return get_headers_default;
      },
      getScope: function getScope() {
        return get_scope_default;
      },
      isColumnHeader: function isColumnHeader() {
        return is_column_header_default;
      },
      isDataCell: function isDataCell() {
        return is_data_cell_default;
      },
      isDataTable: function isDataTable() {
        return is_data_table_default;
      },
      isHeader: function isHeader() {
        return is_header_default;
      },
      isRowHeader: function isRowHeader() {
        return is_row_header_default;
      },
      toArray: function toArray() {
        return to_grid_default;
      },
      toGrid: function toGrid() {
        return to_grid_default;
      },
      traverse: function traverse() {
        return traverse_default;
      }
    });
    function getAllCells(tableElm) {
      var rowIndex, cellIndex, rowLength, cellLength;
      var cells = [];
      for (rowIndex = 0, rowLength = tableElm.rows.length; rowIndex < rowLength; rowIndex++) {
        for (cellIndex = 0, cellLength = tableElm.rows[rowIndex].cells.length; cellIndex < cellLength; cellIndex++) {
          cells.push(tableElm.rows[rowIndex].cells[cellIndex]);
        }
      }
      return cells;
    }
    var get_all_cells_default = getAllCells;
    function traverseForHeaders(headerType, position, tableGrid) {
      var property = headerType === 'row' ? '_rowHeaders' : '_colHeaders';
      var predicate = headerType === 'row' ? is_row_header_default : is_column_header_default;
      var startCell = tableGrid[position.y][position.x];
      var colspan = startCell.colSpan - 1;
      var rowspanAttr = startCell.getAttribute('rowspan');
      var rowspanValue = parseInt(rowspanAttr) === 0 || startCell.rowspan === 0 ? tableGrid.length : startCell.rowSpan;
      var rowspan = rowspanValue - 1;
      var rowStart = position.y + rowspan;
      var colStart = position.x + colspan;
      var rowEnd = headerType === 'row' ? position.y : 0;
      var colEnd = headerType === 'row' ? 0 : position.x;
      var headers;
      var cells = [];
      for (var row = rowStart; row >= rowEnd && !headers; row--) {
        for (var col = colStart; col >= colEnd; col--) {
          var cell = tableGrid[row] ? tableGrid[row][col] : void 0;
          if (!cell) {
            continue;
          }
          var vNode = axe.utils.getNodeFromTree(cell);
          if (vNode[property]) {
            headers = vNode[property];
            break;
          }
          cells.push(cell);
        }
      }
      headers = (headers || []).concat(cells.filter(predicate));
      cells.forEach(function(tableCell) {
        var vNode = axe.utils.getNodeFromTree(tableCell);
        vNode[property] = headers;
      });
      return headers;
    }
    function getHeaders(cell, tableGrid) {
      if (cell.getAttribute('headers')) {
        var headers = idrefs_default(cell, 'headers');
        if (headers.filter(function(header) {
          return header;
        }).length) {
          return headers;
        }
      }
      if (!tableGrid) {
        tableGrid = to_grid_default(find_up_default(cell, 'table'));
      }
      var position = get_cell_position_default(cell, tableGrid);
      var rowHeaders = traverseForHeaders('row', position, tableGrid);
      var colHeaders = traverseForHeaders('col', position, tableGrid);
      return [].concat(rowHeaders, colHeaders).reverse();
    }
    var get_headers_default = getHeaders;
    function isDataCell(cell) {
      if (!cell.children.length && !cell.textContent.trim()) {
        return false;
      }
      var role = cell.getAttribute('role');
      if (is_valid_role_default(role)) {
        return [ 'cell', 'gridcell' ].includes(role);
      } else {
        return cell.nodeName.toUpperCase() === 'TD';
      }
    }
    var is_data_cell_default = isDataCell;
    function isDataTable(node) {
      var role = (node.getAttribute('role') || '').toLowerCase();
      if ((role === 'presentation' || role === 'none') && !is_focusable_default(node)) {
        return false;
      }
      if (node.getAttribute('contenteditable') === 'true' || find_up_default(node, '[contenteditable="true"]')) {
        return true;
      }
      if (role === 'grid' || role === 'treegrid' || role === 'table') {
        return true;
      }
      if (get_role_type_default(role) === 'landmark') {
        return true;
      }
      if (node.getAttribute('datatable') === '0') {
        return false;
      }
      if (node.getAttribute('summary')) {
        return true;
      }
      if (node.tHead || node.tFoot || node.caption) {
        return true;
      }
      for (var childIndex = 0, childLength = node.children.length; childIndex < childLength; childIndex++) {
        if (node.children[childIndex].nodeName.toUpperCase() === 'COLGROUP') {
          return true;
        }
      }
      var cells = 0;
      var rowLength = node.rows.length;
      var row, cell;
      var hasBorder = false;
      for (var rowIndex = 0; rowIndex < rowLength; rowIndex++) {
        row = node.rows[rowIndex];
        for (var cellIndex = 0, cellLength = row.cells.length; cellIndex < cellLength; cellIndex++) {
          cell = row.cells[cellIndex];
          if (cell.nodeName.toUpperCase() === 'TH') {
            return true;
          }
          if (!hasBorder && (cell.offsetWidth !== cell.clientWidth || cell.offsetHeight !== cell.clientHeight)) {
            hasBorder = true;
          }
          if (cell.getAttribute('scope') || cell.getAttribute('headers') || cell.getAttribute('abbr')) {
            return true;
          }
          if ([ 'columnheader', 'rowheader' ].includes((cell.getAttribute('role') || '').toLowerCase())) {
            return true;
          }
          if (cell.children.length === 1 && cell.children[0].nodeName.toUpperCase() === 'ABBR') {
            return true;
          }
          cells++;
        }
      }
      if (node.getElementsByTagName('table').length) {
        return false;
      }
      if (rowLength < 2) {
        return false;
      }
      var sampleRow = node.rows[Math.ceil(rowLength / 2)];
      if (sampleRow.cells.length === 1 && sampleRow.cells[0].colSpan === 1) {
        return false;
      }
      if (sampleRow.cells.length >= 5) {
        return true;
      }
      if (hasBorder) {
        return true;
      }
      var bgColor, bgImage;
      for (rowIndex = 0; rowIndex < rowLength; rowIndex++) {
        row = node.rows[rowIndex];
        if (bgColor && bgColor !== window.getComputedStyle(row).getPropertyValue('background-color')) {
          return true;
        } else {
          bgColor = window.getComputedStyle(row).getPropertyValue('background-color');
        }
        if (bgImage && bgImage !== window.getComputedStyle(row).getPropertyValue('background-image')) {
          return true;
        } else {
          bgImage = window.getComputedStyle(row).getPropertyValue('background-image');
        }
      }
      if (rowLength >= 20) {
        return true;
      }
      if (get_element_coordinates_default(node).width > get_viewport_size_default(window).width * .95) {
        return false;
      }
      if (cells < 10) {
        return false;
      }
      if (node.querySelector('object, embed, iframe, applet')) {
        return false;
      }
      return true;
    }
    var is_data_table_default = isDataTable;
    function isHeader(cell) {
      if (is_column_header_default(cell) || is_row_header_default(cell)) {
        return true;
      }
      if (cell.getAttribute('id')) {
        var id = escape_selector_default(cell.getAttribute('id'));
        return !!document.querySelector('[headers~="'.concat(id, '"]'));
      }
      return false;
    }
    var is_header_default = isHeader;
    function traverseTable(dir, position, tableGrid, callback) {
      var result;
      var cell = tableGrid[position.y] ? tableGrid[position.y][position.x] : void 0;
      if (!cell) {
        return [];
      }
      if (typeof callback === 'function') {
        result = callback(cell, position, tableGrid);
        if (result === true) {
          return [ cell ];
        }
      }
      result = traverseTable(dir, {
        x: position.x + dir.x,
        y: position.y + dir.y
      }, tableGrid, callback);
      result.unshift(cell);
      return result;
    }
    function traverse(dir, startPos, tableGrid, callback) {
      if (Array.isArray(startPos)) {
        callback = tableGrid;
        tableGrid = startPos;
        startPos = {
          x: 0,
          y: 0
        };
      }
      if (typeof dir === 'string') {
        switch (dir) {
         case 'left':
          dir = {
            x: -1,
            y: 0
          };
          break;

         case 'up':
          dir = {
            x: 0,
            y: -1
          };
          break;

         case 'right':
          dir = {
            x: 1,
            y: 0
          };
          break;

         case 'down':
          dir = {
            x: 0,
            y: 1
          };
          break;
        }
      }
      return traverseTable(dir, {
        x: startPos.x + dir.x,
        y: startPos.y + dir.y
      }, tableGrid, callback);
    }
    var traverse_default = traverse;
    function captionFakedEvaluate(node) {
      var table5 = to_grid_default(node);
      var firstRow = table5[0];
      if (table5.length <= 1 || firstRow.length <= 1 || node.rows.length <= 1) {
        return true;
      }
      return firstRow.reduce(function(out, curr, i) {
        return out || curr !== firstRow[i + 1] && firstRow[i + 1] !== void 0;
      }, false);
    }
    var caption_faked_evaluate_default = captionFakedEvaluate;
    function html5ScopeEvaluate(node) {
      if (!is_html5_default(document)) {
        return true;
      }
      return node.nodeName.toUpperCase() === 'TH';
    }
    var html5_scope_evaluate_default = html5ScopeEvaluate;
    function sameCaptionSummaryEvaluate(node) {
      return !!(node.summary && node.caption) && node.summary.toLowerCase() === accessible_text_default(node.caption).toLowerCase();
    }
    var same_caption_summary_evaluate_default = sameCaptionSummaryEvaluate;
    function scopeValueEvaluate(node, options) {
      var value = node.getAttribute('scope').toLowerCase();
      return options.values.indexOf(value) !== -1;
    }
    var scope_value_evaluate_default = scopeValueEvaluate;
    function tdHasHeaderEvaluate(node) {
      var badCells = [];
      var cells = get_all_cells_default(node);
      var tableGrid = to_grid_default(node);
      cells.forEach(function(cell) {
        if (has_content_default(cell) && is_data_cell_default(cell) && !label_default2(cell)) {
          var hasHeaders = get_headers_default(cell, tableGrid).some(function(header) {
            return header !== null && !!has_content_default(header);
          });
          if (!hasHeaders) {
            badCells.push(cell);
          }
        }
      });
      if (badCells.length) {
        this.relatedNodes(badCells);
        return false;
      }
      return true;
    }
    var td_has_header_evaluate_default = tdHasHeaderEvaluate;
    function tdHeadersAttrEvaluate(node) {
      var cells = [];
      var reviewCells = [];
      var badCells = [];
      for (var rowIndex = 0; rowIndex < node.rows.length; rowIndex++) {
        var row = node.rows[rowIndex];
        for (var cellIndex = 0; cellIndex < row.cells.length; cellIndex++) {
          cells.push(row.cells[cellIndex]);
        }
      }
      var ids = cells.reduce(function(ids2, cell) {
        if (cell.getAttribute('id')) {
          ids2.push(cell.getAttribute('id'));
        }
        return ids2;
      }, []);
      cells.forEach(function(cell) {
        var isSelf = false;
        var notOfTable = false;
        if (!cell.hasAttribute('headers')) {
          return;
        }
        var headersAttr = cell.getAttribute('headers').trim();
        if (!headersAttr) {
          return reviewCells.push(cell);
        }
        var headers = token_list_default(headersAttr);
        if (headers.length !== 0) {
          if (cell.getAttribute('id')) {
            isSelf = headers.indexOf(cell.getAttribute('id').trim()) !== -1;
          }
          notOfTable = headers.some(function(header) {
            return !ids.includes(header);
          });
          if (isSelf || notOfTable) {
            badCells.push(cell);
          }
        }
      });
      if (badCells.length > 0) {
        this.relatedNodes(badCells);
        return false;
      }
      if (reviewCells.length) {
        this.relatedNodes(reviewCells);
        return void 0;
      }
      return true;
    }
    var td_headers_attr_evaluate_default = tdHeadersAttrEvaluate;
    function thHasDataCellsEvaluate(node) {
      var cells = get_all_cells_default(node);
      var checkResult = this;
      var reffedHeaders = [];
      cells.forEach(function(cell) {
        var headers2 = cell.getAttribute('headers');
        if (headers2) {
          reffedHeaders = reffedHeaders.concat(headers2.split(/\s+/));
        }
        var ariaLabel = cell.getAttribute('aria-labelledby');
        if (ariaLabel) {
          reffedHeaders = reffedHeaders.concat(ariaLabel.split(/\s+/));
        }
      });
      var headers = cells.filter(function(cell) {
        if (sanitize_default(cell.textContent) === '') {
          return false;
        }
        return cell.nodeName.toUpperCase() === 'TH' || [ 'rowheader', 'columnheader' ].indexOf(cell.getAttribute('role')) !== -1;
      });
      var tableGrid = to_grid_default(node);
      var out = true;
      headers.forEach(function(header) {
        if (header.getAttribute('id') && reffedHeaders.includes(header.getAttribute('id'))) {
          return;
        }
        var pos = get_cell_position_default(header, tableGrid);
        var hasCell = false;
        if (is_column_header_default(header)) {
          hasCell = traverse_default('down', pos, tableGrid).find(function(cell) {
            return !is_column_header_default(cell) && get_headers_default(cell, tableGrid).includes(header);
          });
        }
        if (!hasCell && is_row_header_default(header)) {
          hasCell = traverse_default('right', pos, tableGrid).find(function(cell) {
            return !is_row_header_default(cell) && get_headers_default(cell, tableGrid).includes(header);
          });
        }
        if (!hasCell) {
          checkResult.relatedNodes(header);
        }
        out = out && hasCell;
      });
      return out ? true : void 0;
    }
    var th_has_data_cells_evaluate_default = thHasDataCellsEvaluate;
    function hiddenContentEvaluate(node, options, virtualNode) {
      var whitelist = [ 'SCRIPT', 'HEAD', 'TITLE', 'NOSCRIPT', 'STYLE', 'TEMPLATE' ];
      if (!whitelist.includes(node.nodeName.toUpperCase()) && has_content_virtual_default(virtualNode)) {
        var styles = window.getComputedStyle(node);
        if (styles.getPropertyValue('display') === 'none') {
          return void 0;
        } else if (styles.getPropertyValue('visibility') === 'hidden') {
          var parent = get_composed_parent_default(node);
          var parentStyle = parent && window.getComputedStyle(parent);
          if (!parentStyle || parentStyle.getPropertyValue('visibility') !== 'hidden') {
            return void 0;
          }
        }
      }
      return true;
    }
    var hidden_content_evaluate_default = hiddenContentEvaluate;
    var color_exports = {};
    __export(color_exports, {
      Color: function Color() {
        return color_default;
      },
      centerPointOfRect: function centerPointOfRect() {
        return center_point_of_rect_default;
      },
      elementHasImage: function elementHasImage() {
        return element_has_image_default;
      },
      elementIsDistinct: function elementIsDistinct() {
        return element_is_distinct_default;
      },
      filteredRectStack: function filteredRectStack() {
        return filtered_rect_stack_default;
      },
      flattenColors: function flattenColors() {
        return flatten_colors_default;
      },
      getBackgroundColor: function getBackgroundColor() {
        return get_background_color_default;
      },
      getBackgroundStack: function getBackgroundStack() {
        return get_background_stack_default;
      },
      getContrast: function getContrast() {
        return get_contrast_default;
      },
      getForegroundColor: function getForegroundColor() {
        return get_foreground_color_default;
      },
      getOwnBackgroundColor: function getOwnBackgroundColor() {
        return get_own_background_color_default;
      },
      getRectStack: function getRectStack() {
        return get_rect_stack_default;
      },
      getTextShadowColors: function getTextShadowColors() {
        return get_text_shadow_colors_default;
      },
      hasValidContrastRatio: function hasValidContrastRatio() {
        return has_valid_contrast_ratio_default;
      },
      incompleteData: function incompleteData() {
        return incomplete_data_default;
      }
    });
    function centerPointOfRect(rect) {
      if (rect.left > window.innerWidth) {
        return void 0;
      }
      if (rect.top > window.innerHeight) {
        return void 0;
      }
      var x = Math.min(Math.ceil(rect.left + rect.width / 2), window.innerWidth - 1);
      var y = Math.min(Math.ceil(rect.top + rect.height / 2), window.innerHeight - 1);
      return {
        x: x,
        y: y
      };
    }
    var center_point_of_rect_default = centerPointOfRect;
    function _getFonts(style) {
      return style.getPropertyValue('font-family').split(/[,;]/g).map(function(font) {
        return font.trim().toLowerCase();
      });
    }
    function elementIsDistinct(node, ancestorNode) {
      var nodeStyle = window.getComputedStyle(node);
      if (nodeStyle.getPropertyValue('background-image') !== 'none') {
        return true;
      }
      var hasBorder = [ 'border-bottom', 'border-top', 'outline' ].reduce(function(result, edge) {
        var borderClr = new color_default();
        borderClr.parseString(nodeStyle.getPropertyValue(edge + '-color'));
        return result || nodeStyle.getPropertyValue(edge + '-style') !== 'none' && parseFloat(nodeStyle.getPropertyValue(edge + '-width')) > 0 && borderClr.alpha !== 0;
      }, false);
      if (hasBorder) {
        return true;
      }
      var parentStyle = window.getComputedStyle(ancestorNode);
      if (_getFonts(nodeStyle)[0] !== _getFonts(parentStyle)[0]) {
        return true;
      }
      var hasStyle = [ 'text-decoration-line', 'text-decoration-style', 'font-weight', 'font-style', 'font-size' ].reduce(function(result, cssProp) {
        return result || nodeStyle.getPropertyValue(cssProp) !== parentStyle.getPropertyValue(cssProp);
      }, false);
      var tDec = nodeStyle.getPropertyValue('text-decoration');
      if (tDec.split(' ').length < 3) {
        hasStyle = hasStyle || tDec !== parentStyle.getPropertyValue('text-decoration');
      }
      return hasStyle;
    }
    var element_is_distinct_default = elementIsDistinct;
    function getRectStack2(elm) {
      var boundingStack = get_element_stack_default(elm);
      var filteredArr = get_text_element_stack_default(elm);
      if (!filteredArr || filteredArr.length <= 1) {
        return [ boundingStack ];
      }
      if (filteredArr.some(function(stack) {
        return stack === void 0;
      })) {
        return null;
      }
      filteredArr.splice(0, 0, boundingStack);
      return filteredArr;
    }
    var get_rect_stack_default = getRectStack2;
    function filteredRectStack(elm) {
      var rectStack = get_rect_stack_default(elm);
      if (rectStack && rectStack.length === 1) {
        return rectStack[0];
      }
      if (rectStack && rectStack.length > 1) {
        var boundingStack = rectStack.shift();
        var isSame;
        rectStack.forEach(function(rectList, index) {
          if (index === 0) {
            return;
          }
          var rectA = rectStack[index - 1], rectB = rectStack[index];
          isSame = rectA.every(function(element, elementIndex) {
            return element === rectB[elementIndex];
          }) || boundingStack.includes(elm);
        });
        if (!isSame) {
          incomplete_data_default.set('bgColor', 'elmPartiallyObscuring');
          return null;
        }
        return rectStack[0];
      }
      incomplete_data_default.set('bgColor', 'outsideViewport');
      return null;
    }
    var filtered_rect_stack_default = filteredRectStack;
    function flattenColors(fgColor, bgColor) {
      var alpha = fgColor.alpha;
      var r = (1 - alpha) * bgColor.red + alpha * fgColor.red;
      var g = (1 - alpha) * bgColor.green + alpha * fgColor.green;
      var b = (1 - alpha) * bgColor.blue + alpha * fgColor.blue;
      var a = fgColor.alpha + bgColor.alpha * (1 - fgColor.alpha);
      return new color_default(r, g, b, a);
    }
    var flatten_colors_default = flattenColors;
    function contentOverlapping(targetElement, bgNode) {
      var targetRect = targetElement.getClientRects()[0];
      var obscuringElements = shadow_elements_from_point_default(targetRect.left, targetRect.top);
      if (obscuringElements) {
        for (var i = 0; i < obscuringElements.length; i++) {
          if (obscuringElements[i] !== targetElement && obscuringElements[i] === bgNode) {
            return true;
          }
        }
      }
      return false;
    }
    function calculateObscuringElement(elmIndex, elmStack, originalElm) {
      if (elmIndex > 0) {
        for (var i = elmIndex - 1; i >= 0; i--) {
          var bgElm = elmStack[i];
          if (contentOverlapping(originalElm, bgElm)) {
            return true;
          } else {
            elmStack.splice(i, 1);
          }
        }
      }
      return false;
    }
    function sortPageBackground(elmStack) {
      var bodyIndex = elmStack.indexOf(document.body);
      var bgNodes = elmStack;
      var sortBodyElement = bodyIndex > 1 || bodyIndex === -1;
      if (sortBodyElement && !element_has_image_default(document.documentElement) && get_own_background_color_default(window.getComputedStyle(document.documentElement)).alpha === 0) {
        if (bodyIndex > 1) {
          bgNodes.splice(bodyIndex, 1);
        }
        bgNodes.splice(elmStack.indexOf(document.documentElement), 1);
        bgNodes.push(document.body);
      }
      return bgNodes;
    }
    function getBackgroundStack(elm) {
      var elmStack = filtered_rect_stack_default(elm);
      if (elmStack === null) {
        return null;
      }
      elmStack = reduce_to_elements_below_floating_default(elmStack, elm);
      elmStack = sortPageBackground(elmStack);
      var elmIndex = elmStack.indexOf(elm);
      if (calculateObscuringElement(elmIndex, elmStack, elm)) {
        incomplete_data_default.set('bgColor', 'bgOverlap');
        return null;
      }
      return elmIndex !== -1 ? elmStack : null;
    }
    var get_background_stack_default = getBackgroundStack;
    function getTextShadowColors(node) {
      var _ref43 = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : {}, minRatio = _ref43.minRatio, maxRatio = _ref43.maxRatio;
      var style = window.getComputedStyle(node);
      var textShadow = style.getPropertyValue('text-shadow');
      if (textShadow === 'none') {
        return [];
      }
      var fontSizeStr = style.getPropertyValue('font-size');
      var fontSize = parseInt(fontSizeStr);
      assert_default(isNaN(fontSize) === false, 'Unable to determine font-size value '.concat(fontSizeStr));
      var shadowColors = [];
      var shadows = parseTextShadows(textShadow);
      shadows.forEach(function(_ref44) {
        var colorStr = _ref44.colorStr, pixels = _ref44.pixels;
        colorStr = colorStr || style.getPropertyValue('color');
        var _pixels = _slicedToArray(pixels, 3), offsetY = _pixels[0], offsetX = _pixels[1], _pixels$ = _pixels[2], blurRadius = _pixels$ === void 0 ? 0 : _pixels$;
        if ((!minRatio || blurRadius >= fontSize * minRatio) && (!maxRatio || blurRadius < fontSize * maxRatio)) {
          var color10 = textShadowColor({
            colorStr: colorStr,
            offsetY: offsetY,
            offsetX: offsetX,
            blurRadius: blurRadius,
            fontSize: fontSize
          });
          shadowColors.push(color10);
        }
      });
      return shadowColors;
    }
    function parseTextShadows(textShadow) {
      var current = {
        pixels: []
      };
      var str = textShadow.trim();
      var shadows = [ current ];
      if (!str) {
        return [];
      }
      while (str) {
        var colorMatch = str.match(/^rgba?\([0-9,.\s]+\)/i) || str.match(/^[a-z]+/i) || str.match(/^#[0-9a-f]+/i);
        var pixelMatch = str.match(/^([0-9.-]+)px/i) || str.match(/^(0)/);
        if (colorMatch) {
          assert_default(!current.colorStr, 'Multiple colors identified in text-shadow: '.concat(textShadow));
          str = str.replace(colorMatch[0], '').trim();
          current.colorStr = colorMatch[0];
        } else if (pixelMatch) {
          assert_default(current.pixels.length < 3, 'Too many pixel units in text-shadow: '.concat(textShadow));
          str = str.replace(pixelMatch[0], '').trim();
          var pixelUnit = parseFloat((pixelMatch[1][0] === '.' ? '0' : '') + pixelMatch[1]);
          current.pixels.push(pixelUnit);
        } else if (str[0] === ',') {
          assert_default(current.pixels.length >= 2, 'Missing pixel value in text-shadow: '.concat(textShadow));
          current = {
            pixels: []
          };
          shadows.push(current);
          str = str.substr(1).trim();
        } else {
          throw new Error('Unable to process text-shadows: '.concat(textShadow));
        }
      }
      return shadows;
    }
    function textShadowColor(_ref45) {
      var colorStr = _ref45.colorStr, offsetX = _ref45.offsetX, offsetY = _ref45.offsetY, blurRadius = _ref45.blurRadius, fontSize = _ref45.fontSize;
      if (offsetX > blurRadius || offsetY > blurRadius) {
        return new color_default(0, 0, 0, 0);
      }
      var shadowColor = new color_default();
      shadowColor.parseString(colorStr);
      shadowColor.alpha *= blurRadiusToAlpha(blurRadius, fontSize);
      return shadowColor;
    }
    function blurRadiusToAlpha(blurRadius, fontSize) {
      var relativeBlur = blurRadius / fontSize;
      return .185 / (relativeBlur + .4);
    }
    var get_text_shadow_colors_default = getTextShadowColors;
    function elmPartiallyObscured(elm, bgElm, bgColor) {
      var obscured = elm !== bgElm && !visually_contains_default(elm, bgElm) && bgColor.alpha !== 0;
      if (obscured) {
        incomplete_data_default.set('bgColor', 'elmPartiallyObscured');
      }
      return obscured;
    }
    function getBackgroundColor(elm) {
      var bgElms = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : [];
      var shadowOutlineEmMax = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : .1;
      var bgColors = get_text_shadow_colors_default(elm, {
        minRatio: shadowOutlineEmMax
      });
      var elmStack = get_background_stack_default(elm);
      (elmStack || []).some(function(bgElm) {
        var bgElmStyle = window.getComputedStyle(bgElm);
        var bgColor = get_own_background_color_default(bgElmStyle);
        if (elmPartiallyObscured(elm, bgElm, bgColor) || element_has_image_default(bgElm, bgElmStyle)) {
          bgColors = null;
          bgElms.push(bgElm);
          return true;
        }
        if (bgColor.alpha !== 0) {
          bgElms.push(bgElm);
          bgColors.push(bgColor);
          return bgColor.alpha === 1;
        } else {
          return false;
        }
      });
      if (bgColors === null || elmStack === null) {
        return null;
      }
      bgColors.push(new color_default(255, 255, 255, 1));
      var colors = bgColors.reduce(flatten_colors_default);
      return colors;
    }
    var get_background_color_default = getBackgroundColor;
    function getContrast(bgColor, fgColor) {
      if (!fgColor || !bgColor) {
        return null;
      }
      if (fgColor.alpha < 1) {
        fgColor = flatten_colors_default(fgColor, bgColor);
      }
      var bL = bgColor.getRelativeLuminance();
      var fL = fgColor.getRelativeLuminance();
      return (Math.max(fL, bL) + .05) / (Math.min(fL, bL) + .05);
    }
    var get_contrast_default = getContrast;
    function getOpacity(node) {
      if (!node) {
        return 1;
      }
      var vNode = get_node_from_tree_default(node);
      if (vNode && vNode._opacity !== void 0 && vNode._opacity !== null) {
        return vNode._opacity;
      }
      var nodeStyle = window.getComputedStyle(node);
      var opacity = nodeStyle.getPropertyValue('opacity');
      var finalOpacity = opacity * getOpacity(node.parentElement);
      if (vNode) {
        vNode._opacity = finalOpacity;
      }
      return finalOpacity;
    }
    function getForegroundColor(node, _, bgColor) {
      var nodeStyle = window.getComputedStyle(node);
      var fgColor = new color_default();
      fgColor.parseString(nodeStyle.getPropertyValue('color'));
      var opacity = getOpacity(node);
      fgColor.alpha = fgColor.alpha * opacity;
      if (fgColor.alpha === 1) {
        return fgColor;
      }
      if (!bgColor) {
        bgColor = get_background_color_default(node, []);
      }
      if (bgColor === null) {
        var reason = incomplete_data_default.get('bgColor');
        incomplete_data_default.set('fgColor', reason);
        return null;
      }
      return flatten_colors_default(fgColor, bgColor);
    }
    var get_foreground_color_default = getForegroundColor;
    function hasValidContrastRatio(bg, fg, fontSize, isBold) {
      var contrast = get_contrast_default(bg, fg);
      var isSmallFont = isBold && Math.ceil(fontSize * 72) / 96 < 14 || !isBold && Math.ceil(fontSize * 72) / 96 < 18;
      var expectedContrastRatio = isSmallFont ? 4.5 : 3;
      return {
        isValid: contrast > expectedContrastRatio,
        contrastRatio: contrast,
        expectedContrastRatio: expectedContrastRatio
      };
    }
    var has_valid_contrast_ratio_default = hasValidContrastRatio;
    var hasPsuedoElement = memoize_default(function hasPsuedoElement2(node, pseudo) {
      var style = window.getComputedStyle(node, pseudo);
      var backgroundColor = get_own_background_color_default(style);
      return style.getPropertyValue('content') !== 'none' && style.getPropertyValue('position') === 'absolute' && parseInt(style.getPropertyValue('width')) !== 0 && parseInt(style.getPropertyValue('height')) !== 0 && (backgroundColor.alpha !== 0 || style.getPropertyValue('background-image') !== 'none');
    });
    function colorContrastEvaluate(node, options, virtualNode) {
      if (!is_visible_default(node, false)) {
        return true;
      }
      var ignoreUnicode = options.ignoreUnicode, ignoreLength = options.ignoreLength, boldValue = options.boldValue, boldTextPt = options.boldTextPt, largeTextPt = options.largeTextPt, contrastRatio = options.contrastRatio, shadowOutlineEmMax = options.shadowOutlineEmMax;
      var visibleText = visible_virtual_default(virtualNode, false, true);
      var textContainsOnlyUnicode = has_unicode_default(visibleText, {
        nonBmp: true
      }) && sanitize_default(remove_unicode_default(visibleText, {
        nonBmp: true
      })) === '';
      if (textContainsOnlyUnicode && ignoreUnicode) {
        this.data({
          messageKey: 'nonBmp'
        });
        return void 0;
      }
      var bgNodes = [];
      var bgColor = get_background_color_default(node, bgNodes, shadowOutlineEmMax);
      var fgColor = get_foreground_color_default(node, false, bgColor);
      var shadowColors = get_text_shadow_colors_default(node, {
        maxRatio: shadowOutlineEmMax
      });
      var nodeStyle = window.getComputedStyle(node);
      var fontSize = parseFloat(nodeStyle.getPropertyValue('font-size'));
      var fontWeight = nodeStyle.getPropertyValue('font-weight');
      var bold = parseFloat(fontWeight) >= boldValue || fontWeight === 'bold';
      var contrast = null;
      if (shadowColors.length === 0) {
        contrast = get_contrast_default(bgColor, fgColor);
      } else if (fgColor && bgColor) {
        var shadowColor = [].concat(_toConsumableArray(shadowColors), [ bgColor ]).reduce(flatten_colors_default);
        var bgContrast = get_contrast_default(bgColor, shadowColor);
        var fgContrast = get_contrast_default(shadowColor, fgColor);
        contrast = Math.max(bgContrast, fgContrast);
      }
      var ptSize = Math.ceil(fontSize * 72) / 96;
      var isSmallFont = bold && ptSize < boldTextPt || !bold && ptSize < largeTextPt;
      var _ref46 = isSmallFont ? contrastRatio.normal : contrastRatio.large, expected = _ref46.expected, minThreshold = _ref46.minThreshold, maxThreshold = _ref46.maxThreshold;
      var isValid = contrast > expected;
      var parentNode = node.parentElement;
      while (parentNode) {
        if (hasPsuedoElement(parentNode, ':before') || hasPsuedoElement(parentNode, ':after')) {
          this.data({
            messageKey: 'pseudoContent'
          });
          this.relatedNodes(parentNode);
          return void 0;
        }
        parentNode = parentNode.parentElement;
      }
      if (typeof minThreshold === 'number' && contrast < minThreshold || typeof maxThreshold === 'number' && contrast > maxThreshold) {
        return true;
      }
      var truncatedResult = Math.floor(contrast * 100) / 100;
      var missing;
      if (bgColor === null) {
        missing = incomplete_data_default.get('bgColor');
      }
      var equalRatio = truncatedResult === 1;
      var shortTextContent = visibleText.length === 1;
      if (equalRatio) {
        missing = incomplete_data_default.set('bgColor', 'equalRatio');
      } else if (shortTextContent && !ignoreLength) {
        missing = 'shortTextContent';
      }
      var data2 = {
        fgColor: fgColor ? fgColor.toHexString() : void 0,
        bgColor: bgColor ? bgColor.toHexString() : void 0,
        contrastRatio: truncatedResult,
        fontSize: ''.concat((fontSize * 72 / 96).toFixed(1), 'pt (').concat(fontSize, 'px)'),
        fontWeight: bold ? 'bold' : 'normal',
        messageKey: missing,
        expectedContrastRatio: expected + ':1'
      };
      this.data(data2);
      if (fgColor === null || bgColor === null || equalRatio || shortTextContent && !ignoreLength && !isValid) {
        missing = null;
        incomplete_data_default.clear();
        this.relatedNodes(bgNodes);
        return void 0;
      }
      if (!isValid) {
        this.relatedNodes(bgNodes);
      }
      return isValid;
    }
    var color_contrast_evaluate_default = colorContrastEvaluate;
    function getContrast2(color1, color22) {
      var c1lum = color1.getRelativeLuminance();
      var c2lum = color22.getRelativeLuminance();
      return (Math.max(c1lum, c2lum) + .05) / (Math.min(c1lum, c2lum) + .05);
    }
    var blockLike2 = [ 'block', 'list-item', 'table', 'flex', 'grid', 'inline-block' ];
    function isBlock2(elm) {
      var display = window.getComputedStyle(elm).getPropertyValue('display');
      return blockLike2.indexOf(display) !== -1 || display.substr(0, 6) === 'table-';
    }
    function linkInTextBlockEvaluate(node) {
      if (isBlock2(node)) {
        return false;
      }
      var parentBlock = get_composed_parent_default(node);
      while (parentBlock.nodeType === 1 && !isBlock2(parentBlock)) {
        parentBlock = get_composed_parent_default(parentBlock);
      }
      this.relatedNodes([ parentBlock ]);
      if (element_is_distinct_default(node, parentBlock)) {
        return true;
      } else {
        var nodeColor, parentColor;
        nodeColor = get_foreground_color_default(node);
        parentColor = get_foreground_color_default(parentBlock);
        if (!nodeColor || !parentColor) {
          return void 0;
        }
        var contrast = getContrast2(nodeColor, parentColor);
        if (contrast === 1) {
          return true;
        } else if (contrast >= 3) {
          incomplete_data_default.set('fgColor', 'bgContrast');
          this.data({
            messageKey: incomplete_data_default.get('fgColor')
          });
          incomplete_data_default.clear();
          return void 0;
        }
        nodeColor = get_background_color_default(node);
        parentColor = get_background_color_default(parentBlock);
        if (!nodeColor || !parentColor || getContrast2(nodeColor, parentColor) >= 3) {
          var reason;
          if (!nodeColor || !parentColor) {
            reason = incomplete_data_default.get('bgColor');
          } else {
            reason = 'bgContrast';
          }
          incomplete_data_default.set('fgColor', reason);
          this.data({
            messageKey: incomplete_data_default.get('fgColor')
          });
          incomplete_data_default.clear();
          return void 0;
        }
      }
      return false;
    }
    var link_in_text_block_evaluate_default = linkInTextBlockEvaluate;
    function autocompleteAppropriateEvaluate(node, options, virtualNode) {
      if (virtualNode.props.nodeName !== 'input') {
        return true;
      }
      var number = [ 'text', 'search', 'number', 'tel' ];
      var url = [ 'text', 'search', 'url' ];
      var allowedTypesMap = {
        bday: [ 'text', 'search', 'date' ],
        email: [ 'text', 'search', 'email' ],
        'street-address': [ 'text' ],
        tel: [ 'text', 'search', 'tel' ],
        'tel-country-code': [ 'text', 'search', 'tel' ],
        'tel-national': [ 'text', 'search', 'tel' ],
        'tel-area-code': [ 'text', 'search', 'tel' ],
        'tel-local': [ 'text', 'search', 'tel' ],
        'tel-local-prefix': [ 'text', 'search', 'tel' ],
        'tel-local-suffix': [ 'text', 'search', 'tel' ],
        'tel-extension': [ 'text', 'search', 'tel' ],
        'cc-number': number,
        'cc-exp': [ 'text', 'search', 'month', 'tel' ],
        'cc-exp-month': number,
        'cc-exp-year': number,
        'cc-csc': number,
        'transaction-amount': number,
        'bday-day': number,
        'bday-month': number,
        'bday-year': number,
        'new-password': [ 'text', 'search', 'password' ],
        'current-password': [ 'text', 'search', 'password' ],
        url: url,
        photo: url,
        impp: url
      };
      if (_typeof(options) === 'object') {
        Object.keys(options).forEach(function(key) {
          if (!allowedTypesMap[key]) {
            allowedTypesMap[key] = [];
          }
          allowedTypesMap[key] = allowedTypesMap[key].concat(options[key]);
        });
      }
      var autocompleteAttr = virtualNode.attr('autocomplete');
      var autocompleteTerms = autocompleteAttr.split(/\s+/g).map(function(term) {
        return term.toLowerCase();
      });
      var purposeTerm = autocompleteTerms[autocompleteTerms.length - 1];
      if (_autocomplete.stateTerms.includes(purposeTerm)) {
        return true;
      }
      var allowedTypes = allowedTypesMap[purposeTerm];
      var type = virtualNode.hasAttr('type') ? sanitize_default(virtualNode.attr('type')).toLowerCase() : 'text';
      type = valid_input_type_default().includes(type) ? type : 'text';
      if (typeof allowedTypes === 'undefined') {
        return type === 'text';
      }
      return allowedTypes.includes(type);
    }
    var autocomplete_appropriate_evaluate_default = autocompleteAppropriateEvaluate;
    function autocompleteValidEvaluate(node, options, virtualNode) {
      var autocomplete2 = virtualNode.attr('autocomplete') || '';
      return is_valid_autocomplete_default(autocomplete2, options);
    }
    var autocomplete_valid_evaluate_default = autocompleteValidEvaluate;
    function attrNonSpaceContentEvaluate(node) {
      var options = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : {};
      var vNode = arguments.length > 2 ? arguments[2] : undefined;
      if (!options.attribute || typeof options.attribute !== 'string') {
        throw new TypeError('attr-non-space-content requires options.attribute to be a string');
      }
      if (!vNode.hasAttr(options.attribute)) {
        this.data({
          messageKey: 'noAttr'
        });
        return false;
      }
      var attribute = vNode.attr(options.attribute);
      var attributeIsEmpty = !sanitize_default(attribute);
      if (attributeIsEmpty) {
        this.data({
          messageKey: 'emptyAttr'
        });
        return false;
      }
      return true;
    }
    var attr_non_space_content_evaluate_default = attrNonSpaceContentEvaluate;
    function pageHasElmAfter(results) {
      var elmUsedAnywhere = results.some(function(frameResult) {
        return frameResult.result === true;
      });
      if (elmUsedAnywhere) {
        results.forEach(function(result) {
          result.result = true;
        });
      }
      return results;
    }
    var has_descendant_after_default = pageHasElmAfter;
    function hasDescendant(node, options, virtualNode) {
      if (!options || !options.selector || typeof options.selector !== 'string') {
        throw new TypeError('has-descendant requires options.selector to be a string');
      }
      var matchingElms = query_selector_all_filter_default(virtualNode, options.selector, function(vNode) {
        return is_visible_default(vNode.actualNode, true);
      });
      this.relatedNodes(matchingElms.map(function(vNode) {
        return vNode.actualNode;
      }));
      return matchingElms.length > 0;
    }
    var has_descendant_evaluate_default = hasDescendant;
    function hasTextContentEvaluate(node, options, virtualNode) {
      try {
        return sanitize_default(subtree_text_default(virtualNode)) !== '';
      } catch (e) {
        return void 0;
      }
    }
    var has_text_content_evaluate_default = hasTextContentEvaluate;
    function matchesDefinitionEvaluate(_, options, virtualNode) {
      return matches_default3(virtualNode, options.matcher);
    }
    var matches_definition_evaluate_default = matchesDefinitionEvaluate;
    function pageNoDuplicateAfter(results) {
      return results.filter(function(checkResult) {
        return checkResult.data !== 'ignored';
      });
    }
    var page_no_duplicate_after_default = pageNoDuplicateAfter;
    function pageNoDuplicateEvaluate(node, options, virtualNode) {
      if (!options || !options.selector || typeof options.selector !== 'string') {
        throw new TypeError('page-no-duplicate requires options.selector to be a string');
      }
      var key = 'page-no-duplicate;' + options.selector;
      if (cache_default.get(key)) {
        this.data('ignored');
        return;
      }
      cache_default.set(key, true);
      var elms = query_selector_all_filter_default(axe._tree[0], options.selector, function(elm) {
        return is_visible_default(elm.actualNode);
      });
      if (typeof options.nativeScopeFilter === 'string') {
        elms = elms.filter(function(elm) {
          return elm.actualNode.hasAttribute('role') || !find_up_virtual_default(elm, options.nativeScopeFilter);
        });
      }
      this.relatedNodes(elms.filter(function(elm) {
        return elm !== virtualNode;
      }).map(function(elm) {
        return elm.actualNode;
      }));
      return elms.length <= 1;
    }
    var page_no_duplicate_evaluate_default = pageNoDuplicateEvaluate;
    var joinStr = ' > ';
    function getFramePath(ancestry, nodePath) {
      ancestry = ancestry.slice(0, ancestry.length - 1);
      if (nodePath) {
        ancestry = ancestry.concat(nodePath);
      }
      return ancestry.join(joinStr);
    }
    function headingOrderAfter(results) {
      if (results.length < 2) {
        return results;
      }
      var pageResult = results.find(function(result) {
        return !result.node._fromFrame;
      });
      var headingOrder = pageResult.data.headingOrder.map(function(heading) {
        return _extends({}, heading, {
          ancestry: getFramePath(pageResult.node.ancestry, heading.ancestry)
        });
      });
      var nestedResults = results.filter(function(result) {
        return result.data && result.data.headingOrder && result.node._fromFrame;
      });
      nestedResults.forEach(function(result) {
        result.data.headingOrder = result.data.headingOrder.map(function(heading) {
          return _extends({}, heading, {
            ancestry: getFramePath(result.node.ancestry, heading.ancestry)
          });
        });
      });
      function getFrameIndex(result) {
        var path = getFramePath(result.node.ancestry);
        var heading = headingOrder.find(function(heading2) {
          return heading2.ancestry === path;
        });
        return headingOrder.indexOf(heading);
      }
      function replaceFrameWithResults(index, result) {
        var _headingOrder;
        (_headingOrder = headingOrder).splice.apply(_headingOrder, [ index, 1 ].concat(_toConsumableArray(result.data.headingOrder)));
      }
      var replaced = false;
      while (nestedResults.length) {
        for (var _i19 = 0; _i19 < nestedResults.length; ) {
          var nestedResult = nestedResults[_i19];
          var index = getFrameIndex(nestedResult);
          if (index !== -1) {
            replaceFrameWithResults(index, nestedResult);
            replaced = true;
            nestedResults.splice(_i19, 1);
          } else {
            _i19++;
          }
        }
        if (!replaced) {
          throw new Error('Unable to find parent iframe of heading-order results');
        }
      }
      results.forEach(function(result) {
        var path = result.node.ancestry.join(joinStr);
        var heading = headingOrder.find(function(heading2) {
          return heading2.ancestry === path;
        });
        var index = headingOrder.indexOf(heading);
        headingOrder.splice(index, 1, {
          level: headingOrder[index].level,
          result: result
        });
      });
      headingOrder = headingOrder.filter(function(heading) {
        return heading.level > 0;
      });
      var _loop5 = function _loop5(_i20) {
        var result = results[_i20];
        var heading = headingOrder.find(function(heading2) {
          return heading2.result === result;
        });
        var index = headingOrder.indexOf(heading);
        var currLevel = headingOrder[index].level;
        var prevLevel = headingOrder[index - 1].level;
        if (currLevel - prevLevel > 1) {
          result.result = false;
        }
      };
      for (var _i20 = 1; _i20 < results.length; _i20++) {
        _loop5(_i20);
      }
      return results;
    }
    var heading_order_after_default = headingOrderAfter;
    function getLevel(vNode) {
      var role = vNode.attr('role');
      if (role && role.includes('heading')) {
        var ariaHeadingLevel = vNode.attr('aria-level');
        var level = parseInt(ariaHeadingLevel, 10);
        if (isNaN(level) || level < 1 || level > 6) {
          return 2;
        }
        return level;
      }
      var headingLevel = vNode.props.nodeName.match(/h(\d)/);
      if (headingLevel) {
        return parseInt(headingLevel[1], 10);
      }
      return -1;
    }
    function headingOrderEvaluate() {
      var headingOrder = cache_default.get('headingOrder');
      if (headingOrder) {
        return true;
      }
      var selector = 'h1, h2, h3, h4, h5, h6, [role=heading], iframe, frame';
      var vNodes = query_selector_all_filter_default(axe._tree[0], selector, function(vNode) {
        return is_visible_default(vNode.actualNode, true);
      });
      headingOrder = vNodes.map(function(vNode) {
        return {
          ancestry: [ _getAncestry(vNode.actualNode) ],
          level: getLevel(vNode)
        };
      });
      this.data({
        headingOrder: headingOrder
      });
      cache_default.set('headingOrder', vNodes);
      return true;
    }
    var heading_order_evaluate_default = headingOrderEvaluate;
    function isIdenticalObject(a, b) {
      if (!a || !b) {
        return false;
      }
      var aProps = Object.getOwnPropertyNames(a);
      var bProps = Object.getOwnPropertyNames(b);
      if (aProps.length !== bProps.length) {
        return false;
      }
      var result = aProps.every(function(propName) {
        var aValue = a[propName];
        var bValue = b[propName];
        if (_typeof(aValue) !== _typeof(bValue)) {
          return false;
        }
        if (typeof aValue === 'object' || typeof bValue === 'object') {
          return isIdenticalObject(aValue, bValue);
        }
        return aValue === bValue;
      });
      return result;
    }
    function identicalLinksSamePurposeAfter(results) {
      if (results.length < 2) {
        return results;
      }
      var incompleteResults = results.filter(function(_ref47) {
        var result = _ref47.result;
        return result !== void 0;
      });
      var uniqueResults = [];
      var nameMap = {};
      var _loop6 = function _loop6(index) {
        var _currentResult$relate;
        var currentResult = incompleteResults[index];
        var _currentResult$data = currentResult.data, name = _currentResult$data.name, urlProps = _currentResult$data.urlProps;
        if (nameMap[name]) {
          return 'continue';
        }
        var sameNameResults = incompleteResults.filter(function(_ref48, resultNum) {
          var data2 = _ref48.data;
          return data2.name === name && resultNum !== index;
        });
        var isSameUrl = sameNameResults.every(function(_ref49) {
          var data2 = _ref49.data;
          return isIdenticalObject(data2.urlProps, urlProps);
        });
        if (sameNameResults.length && !isSameUrl) {
          currentResult.result = void 0;
        }
        currentResult.relatedNodes = [];
        (_currentResult$relate = currentResult.relatedNodes).push.apply(_currentResult$relate, _toConsumableArray(sameNameResults.map(function(node) {
          return node.relatedNodes[0];
        })));
        nameMap[name] = sameNameResults;
        uniqueResults.push(currentResult);
      };
      for (var index = 0; index < incompleteResults.length; index++) {
        var _ret2 = _loop6(index);
        if (_ret2 === 'continue') {
          continue;
        }
      }
      return uniqueResults;
    }
    var identical_links_same_purpose_after_default = identicalLinksSamePurposeAfter;
    var commons_exports = {};
    __export(commons_exports, {
      aria: function aria() {
        return aria_exports;
      },
      color: function color() {
        return color_exports;
      },
      dom: function dom() {
        return dom_exports;
      },
      forms: function forms() {
        return forms_exports;
      },
      matches: function matches() {
        return matches_default3;
      },
      standards: function standards() {
        return standards_exports;
      },
      table: function table() {
        return table_exports;
      },
      text: function text() {
        return text_exports;
      },
      utils: function utils() {
        return utils_exports;
      }
    });
    var forms_exports = {};
    __export(forms_exports, {
      isAriaCombobox: function isAriaCombobox() {
        return is_aria_combobox_default;
      },
      isAriaListbox: function isAriaListbox() {
        return is_aria_listbox_default;
      },
      isAriaRange: function isAriaRange() {
        return is_aria_range_default;
      },
      isAriaTextbox: function isAriaTextbox() {
        return is_aria_textbox_default;
      },
      isDisabled: function isDisabled() {
        return is_disabled_default;
      },
      isNativeSelect: function isNativeSelect() {
        return is_native_select_default;
      },
      isNativeTextbox: function isNativeTextbox() {
        return is_native_textbox_default;
      }
    });
    var disabledNodeNames = [ 'fieldset', 'button', 'select', 'input', 'textarea' ];
    function isDisabled(virtualNode) {
      var disabledState = virtualNode._isDisabled;
      if (typeof disabledState === 'boolean') {
        return disabledState;
      }
      var nodeName2 = virtualNode.props.nodeName;
      var ariaDisabled = virtualNode.attr('aria-disabled');
      if (disabledNodeNames.includes(nodeName2) && virtualNode.hasAttr('disabled')) {
        disabledState = true;
      } else if (ariaDisabled) {
        disabledState = ariaDisabled.toLowerCase() === 'true';
      } else if (virtualNode.parent) {
        disabledState = isDisabled(virtualNode.parent);
      } else {
        disabledState = false;
      }
      virtualNode._isDisabled = disabledState;
      return disabledState;
    }
    var is_disabled_default = isDisabled;
    var commons = {
      aria: aria_exports,
      color: color_exports,
      dom: dom_exports,
      forms: forms_exports,
      matches: matches_default3,
      standards: standards_exports,
      table: table_exports,
      text: text_exports,
      utils: utils_exports
    };
    function identicalLinksSamePurposeEvaluate(node, options, virtualNode) {
      var accText = text_exports.accessibleTextVirtual(virtualNode);
      var name = text_exports.sanitize(text_exports.removeUnicode(accText, {
        emoji: true,
        nonBmp: true,
        punctuations: true
      })).toLowerCase();
      if (!name) {
        return void 0;
      }
      var afterData = {
        name: name,
        urlProps: dom_exports.urlPropsFromAttribute(node, 'href')
      };
      this.data(afterData);
      this.relatedNodes([ node ]);
      return true;
    }
    var identical_links_same_purpose_evaluate_default = identicalLinksSamePurposeEvaluate;
    function internalLinkPresentEvaluate(node, options, virtualNode) {
      var links = query_selector_all_default(virtualNode, 'a[href]');
      return links.some(function(vLink) {
        return /^#[^/!]/.test(vLink.actualNode.getAttribute('href'));
      });
    }
    var internal_link_present_evaluate_default = internalLinkPresentEvaluate;
    function metaRefreshEvaluate(node, options, virtualNode) {
      var content = virtualNode.attr('content') || '', parsedParams = content.split(/[;,]/);
      return content === '' || parsedParams[0] === '0';
    }
    var meta_refresh_evaluate_default = metaRefreshEvaluate;
    function normalizeFontWeight(weight) {
      switch (weight) {
       case 'lighter':
        return 100;

       case 'normal':
        return 400;

       case 'bold':
        return 700;

       case 'bolder':
        return 900;
      }
      weight = parseInt(weight);
      return !isNaN(weight) ? weight : 400;
    }
    function getTextContainer(elm) {
      var nextNode = elm;
      var outerText = elm.textContent.trim();
      var innerText = outerText;
      while (innerText === outerText && nextNode !== void 0) {
        var _i21 = -1;
        elm = nextNode;
        if (elm.children.length === 0) {
          return elm;
        }
        do {
          _i21++;
          innerText = elm.children[_i21].textContent.trim();
        } while (innerText === '' && _i21 + 1 < elm.children.length);
        nextNode = elm.children[_i21];
      }
      return elm;
    }
    function getStyleValues(node) {
      var style = window.getComputedStyle(getTextContainer(node));
      return {
        fontWeight: normalizeFontWeight(style.getPropertyValue('font-weight')),
        fontSize: parseInt(style.getPropertyValue('font-size')),
        isItalic: style.getPropertyValue('font-style') === 'italic'
      };
    }
    function isHeaderStyle(styleA, styleB, margins) {
      return margins.reduce(function(out, margin) {
        return out || (!margin.size || styleA.fontSize / margin.size > styleB.fontSize) && (!margin.weight || styleA.fontWeight - margin.weight > styleB.fontWeight) && (!margin.italic || styleA.isItalic && !styleB.isItalic);
      }, false);
    }
    function pAsHeadingEvaluate(node, options, virtualNode) {
      var siblings = Array.from(node.parentNode.children);
      var currentIndex = siblings.indexOf(node);
      options = options || {};
      var margins = options.margins || [];
      var nextSibling = siblings.slice(currentIndex + 1).find(function(elm) {
        return elm.nodeName.toUpperCase() === 'P';
      });
      var prevSibling = siblings.slice(0, currentIndex).reverse().find(function(elm) {
        return elm.nodeName.toUpperCase() === 'P';
      });
      var currStyle = getStyleValues(node);
      var nextStyle = nextSibling ? getStyleValues(nextSibling) : null;
      var prevStyle = prevSibling ? getStyleValues(prevSibling) : null;
      if (!nextStyle || !isHeaderStyle(currStyle, nextStyle, margins)) {
        return true;
      }
      var blockquote = find_up_virtual_default(virtualNode, 'blockquote');
      if (blockquote && blockquote.nodeName.toUpperCase() === 'BLOCKQUOTE') {
        return void 0;
      }
      if (prevStyle && !isHeaderStyle(currStyle, prevStyle, margins)) {
        return void 0;
      }
      return false;
    }
    var p_as_heading_evaluate_default = pAsHeadingEvaluate;
    var landmarkRoles = get_aria_roles_by_type_default('landmark');
    var implicitAriaLiveRoles = [ 'alert', 'log', 'status' ];
    function isRegion(virtualNode, options) {
      var node = virtualNode.actualNode;
      var role = get_role_default(virtualNode);
      var ariaLive = (node.getAttribute('aria-live') || '').toLowerCase().trim();
      if ([ 'assertive', 'polite' ].includes(ariaLive) || implicitAriaLiveRoles.includes(role)) {
        return true;
      }
      if (landmarkRoles.includes(role)) {
        return true;
      }
      if (options.regionMatcher && matches_default3(virtualNode, options.regionMatcher)) {
        return true;
      }
      return false;
    }
    function findRegionlessElms(virtualNode, options) {
      var node = virtualNode.actualNode;
      if (isRegion(virtualNode, options) || is_skip_link_default(virtualNode.actualNode) && get_element_by_reference_default(virtualNode.actualNode, 'href') || !is_visible_default(node, true)) {
        var vNode = virtualNode;
        while (vNode) {
          vNode._hasRegionDescendant = true;
          vNode = vNode.parent;
        }
        return [];
      } else if (node !== document.body && has_content_default(node, true)) {
        return [ virtualNode ];
      } else {
        return virtualNode.children.filter(function(_ref50) {
          var actualNode = _ref50.actualNode;
          return actualNode.nodeType === 1;
        }).map(function(vNode) {
          return findRegionlessElms(vNode, options);
        }).reduce(function(a, b) {
          return a.concat(b);
        }, []);
      }
    }
    function regionEvaluate(node, options, virtualNode) {
      var regionlessNodes = cache_default.get('regionlessNodes');
      if (regionlessNodes) {
        return !regionlessNodes.includes(virtualNode);
      }
      var tree = axe._tree;
      regionlessNodes = findRegionlessElms(tree[0], options).map(function(vNode) {
        while (vNode.parent && !vNode.parent._hasRegionDescendant && vNode.parent.actualNode !== document.body) {
          vNode = vNode.parent;
        }
        return vNode;
      }).filter(function(vNode, index, array) {
        return array.indexOf(vNode) === index;
      });
      cache_default.set('regionlessNodes', regionlessNodes);
      return !regionlessNodes.includes(virtualNode);
    }
    var region_evaluate_default = regionEvaluate;
    function skipLinkEvaluate(node) {
      var target = get_element_by_reference_default(node, 'href');
      if (target) {
        return is_visible_default(target, true) || void 0;
      }
      return false;
    }
    var skip_link_evaluate_default = skipLinkEvaluate;
    function uniqueFrameTitleAfter(results) {
      var titles = {};
      results.forEach(function(r) {
        titles[r.data] = titles[r.data] !== void 0 ? ++titles[r.data] : 0;
      });
      results.forEach(function(r) {
        r.result = !!titles[r.data];
      });
      return results;
    }
    var unique_frame_title_after_default = uniqueFrameTitleAfter;
    function uniqueFrameTitleEvaluate(node, options, vNode) {
      var title = sanitize_default(vNode.attr('title')).toLowerCase();
      this.data(title);
      return true;
    }
    var unique_frame_title_evaluate_default = uniqueFrameTitleEvaluate;
    function ariaLabelEvaluate(node, options, virtualNode) {
      return !!sanitize_default(arialabel_text_default(virtualNode));
    }
    var aria_label_evaluate_default = ariaLabelEvaluate;
    function ariaLabelledbyEvaluate(node, options, virtualNode) {
      try {
        return !!sanitize_default(arialabelledby_text_default(virtualNode));
      } catch (e) {
        return void 0;
      }
    }
    var aria_labelledby_evaluate_default = ariaLabelledbyEvaluate;
    function avoidInlineSpacingEvaluate(node, options) {
      var overriddenProperties = options.cssProperties.filter(function(property) {
        if (node.style.getPropertyPriority(property) === 'important') {
          return property;
        }
      });
      if (overriddenProperties.length > 0) {
        this.data(overriddenProperties);
        return false;
      }
      return true;
    }
    var avoid_inline_spacing_evaluate_default = avoidInlineSpacingEvaluate;
    function docHasTitleEvaluate() {
      var title = document.title;
      return !!sanitize_default(title);
    }
    var doc_has_title_evaluate_default = docHasTitleEvaluate;
    function existsEvaluate() {
      return void 0;
    }
    var exists_evaluate_default = existsEvaluate;
    function hasAltEvaluate(node, options, virtualNode) {
      var nodeName2 = virtualNode.props.nodeName;
      if (![ 'img', 'input', 'area' ].includes(nodeName2)) {
        return false;
      }
      return virtualNode.hasAttr('alt');
    }
    var has_alt_evaluate_default = hasAltEvaluate;
    function isOnScreenEvaluate(node) {
      return is_visible_default(node, false) && !is_offscreen_default(node);
    }
    var is_on_screen_evaluate_default = isOnScreenEvaluate;
    function nonEmptyIfPresentEvaluate(node, options, virtualNode) {
      var nodeName2 = virtualNode.props.nodeName;
      var type = (virtualNode.attr('type') || '').toLowerCase();
      var label5 = virtualNode.attr('value');
      if (label5) {
        this.data({
          messageKey: 'has-label'
        });
      }
      if (nodeName2 === 'input' && [ 'submit', 'reset' ].includes(type)) {
        return label5 === null;
      }
      return false;
    }
    var non_empty_if_present_evaluate_default = nonEmptyIfPresentEvaluate;
    function presentationalRoleEvaluate(node, options, virtualNode) {
      var role = get_role_default(virtualNode);
      var explicitRole2 = get_explicit_role_default(virtualNode);
      if ([ 'presentation', 'none' ].includes(role)) {
        this.data({
          role: role
        });
        return true;
      }
      if (![ 'presentation', 'none' ].includes(explicitRole2)) {
        return false;
      }
      var hasGlobalAria = get_global_aria_attrs_default().some(function(attr) {
        return virtualNode.hasAttr(attr);
      });
      var focusable = is_focusable_default(virtualNode);
      var messageKey;
      if (hasGlobalAria && !focusable) {
        messageKey = 'globalAria';
      } else if (!hasGlobalAria && focusable) {
        messageKey = 'focusable';
      } else {
        messageKey = 'both';
      }
      this.data({
        messageKey: messageKey,
        role: role
      });
      return false;
    }
    var presentational_role_evaluate_default = presentationalRoleEvaluate;
    function svgNonEmptyTitleEvaluate(node, options, virtualNode) {
      if (!virtualNode.children) {
        return void 0;
      }
      var titleNode = virtualNode.children.find(function(_ref51) {
        var props = _ref51.props;
        return props.nodeName === 'title';
      });
      if (!titleNode) {
        this.data({
          messageKey: 'noTitle'
        });
        return false;
      }
      try {
        if (visible_virtual_default(titleNode) === '') {
          this.data({
            messageKey: 'emptyTitle'
          });
          return false;
        }
      } catch (e) {
        return void 0;
      }
      return true;
    }
    var svg_non_empty_title_evaluate_default = svgNonEmptyTitleEvaluate;
    function cssOrientationLockEvaluate(node, options, virtualNode, context3) {
      var _ref52 = context3 || {}, _ref52$cssom = _ref52.cssom, cssom = _ref52$cssom === void 0 ? void 0 : _ref52$cssom;
      var _ref53 = options || {}, _ref53$degreeThreshol = _ref53.degreeThreshold, degreeThreshold = _ref53$degreeThreshol === void 0 ? 0 : _ref53$degreeThreshol;
      if (!cssom || !cssom.length) {
        return void 0;
      }
      var isLocked = false;
      var relatedElements = [];
      var rulesGroupByDocumentFragment = groupCssomByDocument(cssom);
      var _loop7 = function _loop7() {
        var key = _Object$keys2[_i22];
        var _rulesGroupByDocument = rulesGroupByDocumentFragment[key], root = _rulesGroupByDocument.root, rules = _rulesGroupByDocument.rules;
        var orientationRules = rules.filter(isMediaRuleWithOrientation);
        if (!orientationRules.length) {
          return 'continue';
        }
        orientationRules.forEach(function(_ref54) {
          var cssRules = _ref54.cssRules;
          Array.from(cssRules).forEach(function(cssRule) {
            var locked = getIsOrientationLocked(cssRule);
            if (locked && cssRule.selectorText.toUpperCase() !== 'HTML') {
              var elms = Array.from(root.querySelectorAll(cssRule.selectorText)) || [];
              relatedElements = relatedElements.concat(elms);
            }
            isLocked = isLocked || locked;
          });
        });
      };
      for (var _i22 = 0, _Object$keys2 = Object.keys(rulesGroupByDocumentFragment); _i22 < _Object$keys2.length; _i22++) {
        var _ret3 = _loop7();
        if (_ret3 === 'continue') {
          continue;
        }
      }
      if (!isLocked) {
        return true;
      }
      if (relatedElements.length) {
        this.relatedNodes(relatedElements);
      }
      return false;
      function groupCssomByDocument(cssObjectModel) {
        return cssObjectModel.reduce(function(out, _ref55) {
          var sheet = _ref55.sheet, root = _ref55.root, shadowId = _ref55.shadowId;
          var key = shadowId ? shadowId : 'topDocument';
          if (!out[key]) {
            out[key] = {
              root: root,
              rules: []
            };
          }
          if (!sheet || !sheet.cssRules) {
            return out;
          }
          var rules = Array.from(sheet.cssRules);
          out[key].rules = out[key].rules.concat(rules);
          return out;
        }, {});
      }
      function isMediaRuleWithOrientation(_ref56) {
        var type = _ref56.type, cssText = _ref56.cssText;
        if (type !== 4) {
          return false;
        }
        return /orientation:\s*landscape/i.test(cssText) || /orientation:\s*portrait/i.test(cssText);
      }
      function getIsOrientationLocked(_ref57) {
        var selectorText = _ref57.selectorText, style = _ref57.style;
        if (!selectorText || style.length <= 0) {
          return false;
        }
        var transformStyle = style.transform || style.webkitTransform || style.msTransform || false;
        if (!transformStyle) {
          return false;
        }
        var matches14 = transformStyle.match(/(rotate|rotateZ|rotate3d|matrix|matrix3d)\(([^)]+)\)(?!.*(rotate|rotateZ|rotate3d|matrix|matrix3d))/);
        if (!matches14) {
          return false;
        }
        var _matches = _slicedToArray(matches14, 3), transformFn = _matches[1], transformFnValue = _matches[2];
        var degrees = getRotationInDegrees(transformFn, transformFnValue);
        if (!degrees) {
          return false;
        }
        degrees = Math.abs(degrees);
        if (Math.abs(degrees - 180) % 180 <= degreeThreshold) {
          return false;
        }
        return Math.abs(degrees - 90) % 90 <= degreeThreshold;
      }
      function getRotationInDegrees(transformFunction, transformFnValue) {
        switch (transformFunction) {
         case 'rotate':
         case 'rotateZ':
          return getAngleInDegrees(transformFnValue);

         case 'rotate3d':
          var _transformFnValue$spl = transformFnValue.split(',').map(function(value) {
            return value.trim();
          }), _transformFnValue$spl2 = _slicedToArray(_transformFnValue$spl, 4), z = _transformFnValue$spl2[2], angleWithUnit = _transformFnValue$spl2[3];
          if (parseInt(z) === 0) {
            return;
          }
          return getAngleInDegrees(angleWithUnit);

         case 'matrix':
         case 'matrix3d':
          return getAngleInDegreesFromMatrixTransform(transformFnValue);

         default:
          return;
        }
      }
      function getAngleInDegrees(angleWithUnit) {
        var _ref58 = angleWithUnit.match(/(deg|grad|rad|turn)/) || [], _ref59 = _slicedToArray(_ref58, 1), unit = _ref59[0];
        if (!unit) {
          return;
        }
        var angle = parseFloat(angleWithUnit.replace(unit, ''));
        switch (unit) {
         case 'rad':
          return convertRadToDeg(angle);

         case 'grad':
          return convertGradToDeg(angle);

         case 'turn':
          return convertTurnToDeg(angle);

         case 'deg':
         default:
          return parseInt(angle);
        }
      }
      function getAngleInDegreesFromMatrixTransform(transformFnValue) {
        var values = transformFnValue.split(',');
        if (values.length <= 6) {
          var _values = _slicedToArray(values, 2), a = _values[0], b2 = _values[1];
          var radians = Math.atan2(parseFloat(b2), parseFloat(a));
          return convertRadToDeg(radians);
        }
        var sinB = parseFloat(values[8]);
        var b = Math.asin(sinB);
        var cosB = Math.cos(b);
        var rotateZRadians = Math.acos(parseFloat(values[0]) / cosB);
        return convertRadToDeg(rotateZRadians);
      }
      function convertRadToDeg(radians) {
        return Math.round(radians * (180 / Math.PI));
      }
      function convertGradToDeg(grad) {
        grad = grad % 400;
        if (grad < 0) {
          grad += 400;
        }
        return Math.round(grad / 400 * 360);
      }
      function convertTurnToDeg(turn) {
        return Math.round(360 / (1 / turn));
      }
    }
    var css_orientation_lock_evaluate_default = cssOrientationLockEvaluate;
    function metaViewportScaleEvaluate(node, options, virtualNode) {
      var _ref60 = options || {}, _ref60$scaleMinimum = _ref60.scaleMinimum, scaleMinimum = _ref60$scaleMinimum === void 0 ? 2 : _ref60$scaleMinimum, _ref60$lowerBound = _ref60.lowerBound, lowerBound = _ref60$lowerBound === void 0 ? false : _ref60$lowerBound;
      var content = virtualNode.attr('content') || '';
      if (!content) {
        return true;
      }
      var result = content.split(/[;,]/).reduce(function(out, item) {
        var contentValue = item.trim();
        if (!contentValue) {
          return out;
        }
        var _contentValue$split = contentValue.split('='), _contentValue$split2 = _slicedToArray(_contentValue$split, 2), key = _contentValue$split2[0], value = _contentValue$split2[1];
        if (!key || !value) {
          return out;
        }
        var curatedKey = key.toLowerCase().trim();
        var curatedValue = value.toLowerCase().trim();
        if (curatedKey === 'maximum-scale' && curatedValue === 'yes') {
          curatedValue = 1;
        }
        if (curatedKey === 'maximum-scale' && parseFloat(curatedValue) < 0) {
          return out;
        }
        out[curatedKey] = curatedValue;
        return out;
      }, {});
      if (lowerBound && result['maximum-scale'] && parseFloat(result['maximum-scale']) < lowerBound) {
        return true;
      }
      if (!lowerBound && result['user-scalable'] === 'no') {
        this.data('user-scalable=no');
        return false;
      }
      if (result['maximum-scale'] && parseFloat(result['maximum-scale']) < scaleMinimum) {
        this.data('maximum-scale');
        return false;
      }
      return true;
    }
    var meta_viewport_scale_evaluate_default = metaViewportScaleEvaluate;
    function duplicateIdAfter(results) {
      var uniqueIds = [];
      return results.filter(function(r) {
        if (uniqueIds.indexOf(r.data) === -1) {
          uniqueIds.push(r.data);
          return true;
        }
        return false;
      });
    }
    var duplicate_id_after_default = duplicateIdAfter;
    function duplicateIdEvaluate(node) {
      var id = node.getAttribute('id').trim();
      if (!id) {
        return true;
      }
      var root = get_root_node_default2(node);
      var matchingNodes = Array.from(root.querySelectorAll('[id="'.concat(escape_selector_default(id), '"]'))).filter(function(foundNode) {
        return foundNode !== node;
      });
      if (matchingNodes.length) {
        this.relatedNodes(matchingNodes);
      }
      this.data(id);
      return matchingNodes.length === 0;
    }
    var duplicate_id_evaluate_default = duplicateIdEvaluate;
    function accesskeysAfter(results) {
      var seen = {};
      return results.filter(function(r) {
        if (!r.data) {
          return false;
        }
        var key = r.data.toUpperCase();
        if (!seen[key]) {
          seen[key] = r;
          r.relatedNodes = [];
          return true;
        }
        seen[key].relatedNodes.push(r.relatedNodes[0]);
        return false;
      }).map(function(r) {
        r.result = !!r.relatedNodes.length;
        return r;
      });
    }
    var accesskeys_after_default = accesskeysAfter;
    function accesskeysEvaluate(node) {
      if (is_visible_default(node, false)) {
        this.data(node.getAttribute('accesskey'));
        this.relatedNodes([ node ]);
      }
      return true;
    }
    var accesskeys_evaluate_default = accesskeysEvaluate;
    function focusableContentEvaluate(node, options, virtualNode) {
      var tabbableElements = virtualNode.tabbableElements;
      if (!tabbableElements) {
        return false;
      }
      var tabbableContentElements = tabbableElements.filter(function(el) {
        return el !== virtualNode;
      });
      return tabbableContentElements.length > 0;
    }
    var focusable_content_evaluate_default = focusableContentEvaluate;
    function focusableDisabledEvaluate(node, options, virtualNode) {
      var elementsThatCanBeDisabled = [ 'BUTTON', 'FIELDSET', 'INPUT', 'SELECT', 'TEXTAREA' ];
      var tabbableElements = virtualNode.tabbableElements;
      if (!tabbableElements || !tabbableElements.length) {
        return true;
      }
      var relatedNodes = tabbableElements.reduce(function(out, _ref61) {
        var el = _ref61.actualNode;
        var nodeName2 = el.nodeName.toUpperCase();
        if (elementsThatCanBeDisabled.includes(nodeName2)) {
          out.push(el);
        }
        return out;
      }, []);
      this.relatedNodes(relatedNodes);
      if (relatedNodes.length && is_modal_open_default()) {
        return true;
      }
      return relatedNodes.length === 0;
    }
    var focusable_disabled_evaluate_default = focusableDisabledEvaluate;
    function focusableElementEvaluate(node, options, virtualNode) {
      if (virtualNode.hasAttr('contenteditable') && isContenteditable(virtualNode)) {
        return true;
      }
      var isFocusable2 = virtualNode.isFocusable;
      var tabIndex = parseInt(virtualNode.attr('tabindex'), 10);
      tabIndex = !isNaN(tabIndex) ? tabIndex : null;
      return tabIndex ? isFocusable2 && tabIndex >= 0 : isFocusable2;
      function isContenteditable(vNode) {
        var contenteditable = vNode.attr('contenteditable');
        if (contenteditable === 'true' || contenteditable === '') {
          return true;
        }
        if (contenteditable === 'false') {
          return false;
        }
        var ancestor = closest_default(virtualNode.parent, '[contenteditable]');
        if (!ancestor) {
          return false;
        }
        return isContenteditable(ancestor);
      }
    }
    var focusable_element_evaluate_default = focusableElementEvaluate;
    function focusableModalOpenEvaluate(node, options, virtualNode) {
      var tabbableElements = virtualNode.tabbableElements.map(function(_ref62) {
        var actualNode = _ref62.actualNode;
        return actualNode;
      });
      if (!tabbableElements || !tabbableElements.length) {
        return true;
      }
      if (is_modal_open_default()) {
        this.relatedNodes(tabbableElements);
        return void 0;
      }
      return true;
    }
    var focusable_modal_open_evaluate_default = focusableModalOpenEvaluate;
    function focusableNoNameEvaluate(node, options, virtualNode) {
      var tabIndex = virtualNode.attr('tabindex');
      var inFocusOrder = is_focusable_default(virtualNode) && tabIndex > -1;
      if (!inFocusOrder) {
        return false;
      }
      try {
        return !accessible_text_virtual_default(virtualNode);
      } catch (e) {
        return void 0;
      }
    }
    var focusable_no_name_evaluate_default = focusableNoNameEvaluate;
    function focusableNotTabbableEvaluate(node, options, virtualNode) {
      var elementsThatCanBeDisabled = [ 'BUTTON', 'FIELDSET', 'INPUT', 'SELECT', 'TEXTAREA' ];
      var tabbableElements = virtualNode.tabbableElements;
      if (!tabbableElements || !tabbableElements.length) {
        return true;
      }
      var relatedNodes = tabbableElements.reduce(function(out, _ref63) {
        var el = _ref63.actualNode;
        var nodeName2 = el.nodeName.toUpperCase();
        if (!elementsThatCanBeDisabled.includes(nodeName2)) {
          out.push(el);
        }
        return out;
      }, []);
      this.relatedNodes(relatedNodes);
      if (relatedNodes.length > 0 && is_modal_open_default()) {
        return true;
      }
      return relatedNodes.length === 0;
    }
    var focusable_not_tabbable_evaluate_default = focusableNotTabbableEvaluate;
    function landmarkIsTopLevelEvaluate(node) {
      var landmarks = get_aria_roles_by_type_default('landmark');
      var parent = get_composed_parent_default(node);
      var nodeRole = get_role_default(node);
      this.data({
        role: nodeRole
      });
      while (parent) {
        var role = parent.getAttribute('role');
        if (!role && parent.nodeName.toUpperCase() !== 'FORM') {
          role = implicit_role_default(parent);
        }
        if (role && landmarks.includes(role) && !(role === 'main' && nodeRole === 'complementary')) {
          return false;
        }
        parent = get_composed_parent_default(parent);
      }
      return true;
    }
    var landmark_is_top_level_evaluate_default = landmarkIsTopLevelEvaluate;
    function focusableDescendants(vNode) {
      if (is_focusable_default(vNode)) {
        return true;
      }
      if (!vNode.children) {
        if (vNode.props.nodeType === 1) {
          throw new Error('Cannot determine children');
        }
        return false;
      }
      return vNode.children.some(function(child) {
        return focusableDescendants(child);
      });
    }
    function noFocusbleContentEvaluate(node, options, virtualNode) {
      if (!virtualNode.children) {
        return void 0;
      }
      try {
        return !virtualNode.children.some(function(child) {
          return focusableDescendants(child);
        });
      } catch (e) {
        return void 0;
      }
    }
    var no_focusable_content_evaluate_default = noFocusbleContentEvaluate;
    function tabindexEvaluate(node, options, virtualNode) {
      var tabIndex = parseInt(virtualNode.attr('tabindex'), 10);
      return isNaN(tabIndex) ? true : tabIndex <= 0;
    }
    var tabindex_evaluate_default = tabindexEvaluate;
    function altSpaceValueEvaluate(node, options, virtualNode) {
      var alt = virtualNode.attr('alt');
      var isOnlySpace = /^\s+$/;
      return typeof alt === 'string' && isOnlySpace.test(alt);
    }
    var alt_space_value_evaluate_default = altSpaceValueEvaluate;
    function duplicateImgLabelEvaluate(node, options, virtualNode) {
      if ([ 'none', 'presentation' ].includes(get_role_default(virtualNode))) {
        return false;
      }
      var parentVNode = closest_default(virtualNode, options.parentSelector);
      if (!parentVNode) {
        return false;
      }
      var visibleText = visible_virtual_default(parentVNode, true).toLowerCase();
      if (visibleText === '') {
        return false;
      }
      return visibleText === accessible_text_virtual_default(virtualNode).toLowerCase();
    }
    var duplicate_img_label_evaluate_default = duplicateImgLabelEvaluate;
    function explicitEvaluate(node, options, virtualNode) {
      if (virtualNode.attr('id')) {
        if (!virtualNode.actualNode) {
          return void 0;
        }
        var root = get_root_node_default2(virtualNode.actualNode);
        var id = escape_selector_default(virtualNode.attr('id'));
        var labels = Array.from(root.querySelectorAll('label[for="'.concat(id, '"]')));
        if (labels.length) {
          try {
            return labels.some(function(label5) {
              if (!is_visible_default(label5)) {
                return true;
              } else {
                return !!accessible_text_default(label5);
              }
            });
          } catch (e) {
            return void 0;
          }
        }
      }
      return false;
    }
    var explicit_evaluate_default = explicitEvaluate;
    function helpSameAsLabelEvaluate(node, options, virtualNode) {
      var labelText2 = label_virtual_default2(virtualNode), check4 = node.getAttribute('title');
      if (!labelText2) {
        return false;
      }
      if (!check4) {
        check4 = '';
        if (node.getAttribute('aria-describedby')) {
          var ref = idrefs_default(node, 'aria-describedby');
          check4 = ref.map(function(thing) {
            return thing ? accessible_text_default(thing) : '';
          }).join('');
        }
      }
      return sanitize_default(check4) === sanitize_default(labelText2);
    }
    var help_same_as_label_evaluate_default = helpSameAsLabelEvaluate;
    function hiddenExplicitLabelEvaluate(node, options, virtualNode) {
      if (virtualNode.hasAttr('id')) {
        if (!virtualNode.actualNode) {
          return void 0;
        }
        var root = get_root_node_default2(node);
        var id = escape_selector_default(node.getAttribute('id'));
        var label5 = root.querySelector('label[for="'.concat(id, '"]'));
        if (label5 && !is_visible_default(label5, true)) {
          var name;
          try {
            name = accessible_text_virtual_default(virtualNode).trim();
          } catch (e) {
            return void 0;
          }
          var isNameEmpty = name === '';
          return isNameEmpty;
        }
      }
      return false;
    }
    var hidden_explicit_label_evaluate_default = hiddenExplicitLabelEvaluate;
    function implicitEvaluate(node, options, virtualNode) {
      try {
        var label5 = closest_default(virtualNode, 'label');
        if (label5) {
          return !!accessible_text_virtual_default(label5, {
            inControlContext: true
          });
        }
        return false;
      } catch (e) {
        return void 0;
      }
    }
    var implicit_evaluate_default = implicitEvaluate;
    function isStringContained(compare, compareWith) {
      var curatedCompareWith = curateString(compareWith);
      var curatedCompare = curateString(compare);
      if (!curatedCompareWith || !curatedCompare) {
        return false;
      }
      return curatedCompareWith.includes(curatedCompare);
    }
    function curateString(str) {
      var noUnicodeStr = remove_unicode_default(str, {
        emoji: true,
        nonBmp: true,
        punctuations: true
      });
      return sanitize_default(noUnicodeStr);
    }
    function labelContentNameMismatchEvaluate(node, options, virtualNode) {
      var _ref64 = options || {}, pixelThreshold = _ref64.pixelThreshold, occuranceThreshold = _ref64.occuranceThreshold;
      var accText = accessible_text_default(node).toLowerCase();
      if (is_human_interpretable_default(accText) < 1) {
        return void 0;
      }
      var textVNodes = visible_text_nodes_default(virtualNode);
      var nonLigatureText = textVNodes.filter(function(textVNode) {
        return !is_icon_ligature_default(textVNode, pixelThreshold, occuranceThreshold);
      }).map(function(textVNode) {
        return textVNode.actualNode.nodeValue;
      }).join('');
      var visibleText = sanitize_default(nonLigatureText).toLowerCase();
      if (!visibleText) {
        return true;
      }
      if (is_human_interpretable_default(visibleText) < 1) {
        if (isStringContained(visibleText, accText)) {
          return true;
        }
        return void 0;
      }
      return isStringContained(visibleText, accText);
    }
    var label_content_name_mismatch_evaluate_default = labelContentNameMismatchEvaluate;
    function multipleLabelEvaluate(node) {
      var id = escape_selector_default(node.getAttribute('id'));
      var parent = node.parentNode;
      var root = get_root_node_default2(node);
      root = root.documentElement || root;
      var labels = Array.from(root.querySelectorAll('label[for="'.concat(id, '"]')));
      if (labels.length) {
        labels = labels.filter(function(label5) {
          return is_visible_default(label5);
        });
      }
      while (parent) {
        if (parent.nodeName.toUpperCase() === 'LABEL' && labels.indexOf(parent) === -1) {
          labels.push(parent);
        }
        parent = parent.parentNode;
      }
      this.relatedNodes(labels);
      if (labels.length > 1) {
        var ATVisibleLabels = labels.filter(function(label5) {
          return is_visible_default(label5, true);
        });
        if (ATVisibleLabels.length > 1) {
          return void 0;
        }
        var labelledby = idrefs_default(node, 'aria-labelledby');
        return !labelledby.includes(ATVisibleLabels[0]) ? void 0 : false;
      }
      return false;
    }
    var multiple_label_evaluate_default = multipleLabelEvaluate;
    function titleOnlyEvaluate(node, options, virtualNode) {
      var labelText2 = label_virtual_default2(virtualNode);
      var title = title_text_default(virtualNode);
      var ariaDescribedBy = virtualNode.attr('aria-describedby');
      return !labelText2 && !!(title || ariaDescribedBy);
    }
    var title_only_evaluate_default = titleOnlyEvaluate;
    function landmarkIsUniqueAfter(results) {
      var uniqueLandmarks = [];
      return results.filter(function(currentResult) {
        var findMatch = function findMatch(someResult) {
          return currentResult.data.role === someResult.data.role && currentResult.data.accessibleText === someResult.data.accessibleText;
        };
        var matchedResult = uniqueLandmarks.find(findMatch);
        if (matchedResult) {
          matchedResult.result = false;
          matchedResult.relatedNodes.push(currentResult.relatedNodes[0]);
          return false;
        }
        uniqueLandmarks.push(currentResult);
        currentResult.relatedNodes = [];
        return true;
      });
    }
    var landmark_is_unique_after_default = landmarkIsUniqueAfter;
    function landmarkIsUniqueEvaluate(node, options, virtualNode) {
      var role = get_role_default(node);
      var accessibleText2 = accessible_text_virtual_default(virtualNode);
      accessibleText2 = accessibleText2 ? accessibleText2.toLowerCase() : null;
      this.data({
        role: role,
        accessibleText: accessibleText2
      });
      this.relatedNodes([ node ]);
      return true;
    }
    var landmark_is_unique_evaluate_default = landmarkIsUniqueEvaluate;
    function hasValue(value) {
      return (value || '').trim() !== '';
    }
    function hasLangEvaluate(node, options, virtualNode) {
      var xhtml2 = typeof document !== 'undefined' ? is_xhtml_default(document) : false;
      if (options.attributes.includes('xml:lang') && options.attributes.includes('lang') && hasValue(virtualNode.attr('xml:lang')) && !hasValue(virtualNode.attr('lang')) && !xhtml2) {
        this.data({
          messageKey: 'noXHTML'
        });
        return false;
      }
      var hasLang = options.attributes.some(function(name) {
        return hasValue(virtualNode.attr(name));
      });
      if (!hasLang) {
        this.data({
          messageKey: 'noLang'
        });
        return false;
      }
      return true;
    }
    var has_lang_evaluate_default = hasLangEvaluate;
    function validLangEvaluate(node, options, virtualNode) {
      var invalid = [];
      options.attributes.forEach(function(langAttr) {
        var langVal = virtualNode.attr(langAttr);
        if (typeof langVal !== 'string') {
          return;
        }
        var baselangVal = get_base_lang_default(langVal);
        var invalidLang = options.value ? !options.value.map(get_base_lang_default).includes(baselangVal) : !valid_langs_default(baselangVal);
        if (baselangVal !== '' && invalidLang || langVal !== '' && !sanitize_default(langVal)) {
          invalid.push(langAttr + '="' + virtualNode.attr(langAttr) + '"');
        }
      });
      if (invalid.length) {
        this.data(invalid);
        return true;
      }
      return false;
    }
    var valid_lang_evaluate_default = validLangEvaluate;
    function xmlLangMismatchEvaluate(node, options, vNode) {
      var primaryLangValue = get_base_lang_default(vNode.attr('lang'));
      var primaryXmlLangValue = get_base_lang_default(vNode.attr('xml:lang'));
      return primaryLangValue === primaryXmlLangValue;
    }
    var xml_lang_mismatch_evaluate_default = xmlLangMismatchEvaluate;
    function dlitemEvaluate(node) {
      var parent = get_composed_parent_default(node);
      var parentTagName = parent.nodeName.toUpperCase();
      var parentRole = get_explicit_role_default(parent);
      if (parentTagName === 'DIV' && [ 'presentation', 'none', null ].includes(parentRole)) {
        parent = get_composed_parent_default(parent);
        parentTagName = parent.nodeName.toUpperCase();
        parentRole = get_explicit_role_default(parent);
      }
      if (parentTagName !== 'DL') {
        return false;
      }
      if (!parentRole || [ 'presentation', 'none', 'list' ].includes(parentRole)) {
        return true;
      }
      return false;
    }
    var dlitem_evaluate_default = dlitemEvaluate;
    function listitemEvaluate(node) {
      var parent = get_composed_parent_default(node);
      if (!parent) {
        return void 0;
      }
      var parentTagName = parent.nodeName.toUpperCase();
      var parentRole = (parent.getAttribute('role') || '').toLowerCase();
      if ([ 'presentation', 'none', 'list' ].includes(parentRole)) {
        return true;
      }
      if (parentRole && is_valid_role_default(parentRole)) {
        this.data({
          messageKey: 'roleNotValid'
        });
        return false;
      }
      return [ 'UL', 'OL' ].includes(parentTagName);
    }
    var listitem_evaluate_default = listitemEvaluate;
    function onlyDlitemsEvaluate(node, options, virtualNode) {
      var ALLOWED_ROLES = [ 'definition', 'term', 'list' ];
      var base = {
        badNodes: [],
        hasNonEmptyTextNode: false
      };
      var content = virtualNode.children.reduce(function(content2, child) {
        var actualNode = child.actualNode;
        if (actualNode.nodeName.toUpperCase() === 'DIV' && get_role_default(actualNode) === null) {
          return content2.concat(child.children);
        }
        return content2.concat(child);
      }, []);
      var result = content.reduce(function(out, childNode) {
        var actualNode = childNode.actualNode;
        var tagName = actualNode.nodeName.toUpperCase();
        if (actualNode.nodeType === 1 && is_visible_default(actualNode, true, false)) {
          var explicitRole2 = get_explicit_role_default(actualNode);
          if (tagName !== 'DT' && tagName !== 'DD' || explicitRole2) {
            if (!ALLOWED_ROLES.includes(explicitRole2)) {
              out.badNodes.push(actualNode);
            }
          }
        } else if (actualNode.nodeType === 3 && actualNode.nodeValue.trim() !== '') {
          out.hasNonEmptyTextNode = true;
        }
        return out;
      }, base);
      if (result.badNodes.length) {
        this.relatedNodes(result.badNodes);
      }
      return !!result.badNodes.length || result.hasNonEmptyTextNode;
    }
    var only_dlitems_evaluate_default = onlyDlitemsEvaluate;
    function onlyListitemsEvaluate(node, options, virtualNode) {
      var hasNonEmptyTextNode = false;
      var atLeastOneListitem = false;
      var isEmpty = true;
      var badNodes = [];
      var badRoleNodes = [];
      var badRoles = [];
      virtualNode.children.forEach(function(vNode) {
        var actualNode = vNode.actualNode;
        if (actualNode.nodeType === 3 && actualNode.nodeValue.trim() !== '') {
          hasNonEmptyTextNode = true;
          return;
        }
        if (actualNode.nodeType !== 1 || !is_visible_default(actualNode, true, false)) {
          return;
        }
        isEmpty = false;
        var isLi = actualNode.nodeName.toUpperCase() === 'LI';
        var role = get_role_default(vNode);
        var isListItemRole = role === 'listitem';
        if (!isLi && !isListItemRole) {
          badNodes.push(actualNode);
        }
        if (isLi && !isListItemRole) {
          badRoleNodes.push(actualNode);
          if (!badRoles.includes(role)) {
            badRoles.push(role);
          }
        }
        if (isListItemRole) {
          atLeastOneListitem = true;
        }
      });
      if (hasNonEmptyTextNode || badNodes.length) {
        this.relatedNodes(badNodes);
        return true;
      }
      if (isEmpty || atLeastOneListitem) {
        return false;
      }
      this.relatedNodes(badRoleNodes);
      this.data({
        messageKey: 'roleNotValid',
        roles: badRoles.join(', ')
      });
      return true;
    }
    var only_listitems_evaluate_default = onlyListitemsEvaluate;
    function structuredDlitemsEvaluate(node, options, virtualNode) {
      var children = virtualNode.children;
      if (!children || !children.length) {
        return false;
      }
      var hasDt = false, hasDd = false, nodeName2;
      for (var i = 0; i < children.length; i++) {
        nodeName2 = children[i].props.nodeName.toUpperCase();
        if (nodeName2 === 'DT') {
          hasDt = true;
        }
        if (hasDt && nodeName2 === 'DD') {
          return false;
        }
        if (nodeName2 === 'DD') {
          hasDd = true;
        }
      }
      return hasDt || hasDd;
    }
    var structured_dlitems_evaluate_default = structuredDlitemsEvaluate;
    function captionEvaluate(node, options, virtualNode) {
      var tracks = query_selector_all_default(virtualNode, 'track');
      var hasCaptions = tracks.some(function(vNode) {
        return (vNode.attr('kind') || '').toLowerCase() === 'captions';
      });
      return hasCaptions ? false : void 0;
    }
    var caption_evaluate_default = captionEvaluate;
    function frameTestedEvaluate(node, options) {
      var resolve = this.async();
      var _Object$assign = Object.assign({
        isViolation: false,
        timeout: 500
      }, options), isViolation = _Object$assign.isViolation, timeout = _Object$assign.timeout;
      var timer = setTimeout(function() {
        timer = setTimeout(function() {
          timer = null;
          resolve(isViolation ? false : void 0);
        }, 0);
      }, timeout);
      _respondable(node.contentWindow, 'axe.ping', null, void 0, function() {
        if (timer !== null) {
          clearTimeout(timer);
          resolve(true);
        }
      });
    }
    var frame_tested_evaluate_default = frameTestedEvaluate;
    function noAutoplayAudioEvaluate(node, options) {
      if (!node.duration) {
        console.warn('axe.utils.preloadMedia did not load metadata');
        return void 0;
      }
      var _options$allowedDurat = options.allowedDuration, allowedDuration = _options$allowedDurat === void 0 ? 3 : _options$allowedDurat;
      var playableDuration = getPlayableDuration(node);
      if (playableDuration <= allowedDuration && !node.hasAttribute('loop')) {
        return true;
      }
      if (!node.hasAttribute('controls')) {
        return false;
      }
      return true;
      function getPlayableDuration(elm) {
        if (!elm.currentSrc) {
          return 0;
        }
        var playbackRange = getPlaybackRange(elm.currentSrc);
        if (!playbackRange) {
          return Math.abs(elm.duration - (elm.currentTime || 0));
        }
        if (playbackRange.length === 1) {
          return Math.abs(elm.duration - playbackRange[0]);
        }
        return Math.abs(playbackRange[1] - playbackRange[0]);
      }
      function getPlaybackRange(src) {
        var match = src.match(/#t=(.*)/);
        if (!match) {
          return;
        }
        var _match = _slicedToArray(match, 2), value = _match[1];
        var ranges = value.split(',');
        return ranges.map(function(range) {
          if (/:/.test(range)) {
            return convertHourMinSecToSeconds(range);
          }
          return parseFloat(range);
        });
      }
      function convertHourMinSecToSeconds(hhMmSs) {
        var parts = hhMmSs.split(':');
        var secs = 0;
        var mins = 1;
        while (parts.length > 0) {
          secs += mins * parseInt(parts.pop(), 10);
          mins *= 60;
        }
        return parseFloat(secs);
      }
    }
    var no_autoplay_audio_evaluate_default = noAutoplayAudioEvaluate;
    function ariaAllowedAttrMatches(node, virtualNode) {
      var aria43 = /^aria-/;
      var attrs = virtualNode.attrNames;
      if (attrs.length) {
        for (var _i23 = 0, l = attrs.length; _i23 < l; _i23++) {
          if (aria43.test(attrs[_i23])) {
            return true;
          }
        }
      }
      return false;
    }
    var aria_allowed_attr_matches_default = ariaAllowedAttrMatches;
    function ariaAllowedRoleMatches(node) {
      return get_explicit_role_default(node, {
        dpub: true,
        fallback: true
      }) !== null;
    }
    var aria_allowed_role_matches_default = ariaAllowedRoleMatches;
    function ariaHasAttrMatches(node) {
      var aria43 = /^aria-/;
      if (node.hasAttributes()) {
        var attrs = get_node_attributes_default(node);
        for (var i = 0, l = attrs.length; i < l; i++) {
          if (aria43.test(attrs[i].name)) {
            return true;
          }
        }
      }
      return false;
    }
    var aria_has_attr_matches_default = ariaHasAttrMatches;
    function shouldMatchElement(el) {
      if (!el) {
        return true;
      }
      if (el.getAttribute('aria-hidden') === 'true') {
        return false;
      }
      return shouldMatchElement(get_composed_parent_default(el));
    }
    function ariaHiddenFocusMatches(node) {
      return shouldMatchElement(get_composed_parent_default(node));
    }
    var aria_hidden_focus_matches_default = ariaHiddenFocusMatches;
    function ariaRequiredChildrenMatches(node, virtualNode) {
      var role = get_explicit_role_default(virtualNode, {
        dpub: true
      });
      return !!required_owned_default(role);
    }
    var aria_required_children_matches_default = ariaRequiredChildrenMatches;
    function ariaRequiredParentMatches(node, virtualNode) {
      var role = get_explicit_role_default(virtualNode);
      return !!required_context_default(role);
    }
    var aria_required_parent_matches_default = ariaRequiredParentMatches;
    function autocompleteMatches(node, virtualNode) {
      var autocomplete2 = virtualNode.attr('autocomplete');
      if (!autocomplete2 || sanitize_default(autocomplete2) === '') {
        return false;
      }
      var nodeName2 = virtualNode.props.nodeName;
      if ([ 'textarea', 'input', 'select' ].includes(nodeName2) === false) {
        return false;
      }
      var excludedInputTypes = [ 'submit', 'reset', 'button', 'hidden' ];
      if (nodeName2 === 'input' && excludedInputTypes.includes(virtualNode.props.type)) {
        return false;
      }
      var ariaDisabled = virtualNode.attr('aria-disabled') || 'false';
      if (virtualNode.hasAttr('disabled') || ariaDisabled.toLowerCase() === 'true') {
        return false;
      }
      var role = virtualNode.attr('role');
      var tabIndex = virtualNode.attr('tabindex');
      if (tabIndex === '-1' && role) {
        var roleDef = standards_default.ariaRoles[role];
        if (roleDef === void 0 || roleDef.type !== 'widget') {
          return false;
        }
      }
      if (tabIndex === '-1' && virtualNode.actualNode && !is_visible_default(virtualNode.actualNode, false) && !is_visible_default(virtualNode.actualNode, true)) {
        return false;
      }
      return true;
    }
    var autocomplete_matches_default = autocompleteMatches;
    function isInitiatorMatches(node, virtualNode, context3) {
      return context3.initiator;
    }
    var is_initiator_matches_default = isInitiatorMatches;
    function bypassMatches(node, virtualNode, context3) {
      if (is_initiator_matches_default(node, virtualNode, context3)) {
        return !!node.querySelector('a[href]');
      }
      return true;
    }
    var bypass_matches_default = bypassMatches;
    function colorContrastMatches(node, virtualNode) {
      var _virtualNode$props = virtualNode.props, nodeName2 = _virtualNode$props.nodeName, inputType = _virtualNode$props.type;
      if (nodeName2 === 'option') {
        return false;
      }
      if (nodeName2 === 'select' && !node.options.length) {
        return false;
      }
      var nonTextInput = [ 'hidden', 'range', 'color', 'checkbox', 'radio', 'image' ];
      if (nodeName2 === 'input' && nonTextInput.includes(inputType)) {
        return false;
      }
      if (is_disabled_default(virtualNode)) {
        return false;
      }
      var formElements = [ 'input', 'select', 'textarea' ];
      if (formElements.includes(nodeName2)) {
        var style = window.getComputedStyle(node);
        var textIndent = parseInt(style.getPropertyValue('text-indent'), 10);
        if (textIndent) {
          var rect = node.getBoundingClientRect();
          rect = {
            top: rect.top,
            bottom: rect.bottom,
            left: rect.left + textIndent,
            right: rect.right + textIndent
          };
          if (!visually_overlaps_default(rect, node)) {
            return false;
          }
        }
        return true;
      }
      var nodeParentLabel = find_up_virtual_default(virtualNode, 'label');
      if (nodeName2 === 'label' || nodeParentLabel) {
        var labelNode = nodeParentLabel || node;
        var labelVirtual3 = nodeParentLabel ? get_node_from_tree_default(nodeParentLabel) : virtualNode;
        if (labelNode.htmlFor) {
          var doc = get_root_node_default2(labelNode);
          var explicitControl = doc.getElementById(labelNode.htmlFor);
          var explicitControlVirtual = explicitControl && get_node_from_tree_default(explicitControl);
          if (explicitControlVirtual && is_disabled_default(explicitControlVirtual)) {
            return false;
          }
        }
        var query = 'input:not([type="hidden"],[type="image"],[type="button"],[type="submit"],[type="reset"]), select, textarea';
        var implicitControl = query_selector_all_default(labelVirtual3, query)[0];
        if (implicitControl && is_disabled_default(implicitControl)) {
          return false;
        }
      }
      var ariaLabelledbyControls = [];
      var ancestorNode = virtualNode;
      while (ancestorNode) {
        if (ancestorNode.props.id) {
          var virtualControls = get_accessible_refs_default(ancestorNode).filter(function(control) {
            return token_list_default(control.getAttribute('aria-labelledby') || '').includes(ancestorNode.props.id);
          }).map(function(control) {
            return get_node_from_tree_default(control);
          });
          ariaLabelledbyControls.push.apply(ariaLabelledbyControls, _toConsumableArray(virtualControls));
        }
        ancestorNode = ancestorNode.parent;
      }
      if (ariaLabelledbyControls.length > 0 && ariaLabelledbyControls.every(is_disabled_default)) {
        return false;
      }
      var visibleText = visible_virtual_default(virtualNode, false, true);
      var removeUnicodeOptions = {
        emoji: true,
        nonBmp: false,
        punctuations: true
      };
      if (!visibleText || !remove_unicode_default(visibleText, removeUnicodeOptions)) {
        return false;
      }
      var range = document.createRange();
      var childNodes = virtualNode.children;
      for (var index = 0; index < childNodes.length; index++) {
        var child = childNodes[index];
        if (child.actualNode.nodeType === 3 && sanitize_default(child.actualNode.nodeValue) !== '') {
          range.selectNodeContents(child.actualNode);
        }
      }
      var rects = range.getClientRects();
      for (var _index = 0; _index < rects.length; _index++) {
        if (visually_overlaps_default(rects[_index], node)) {
          return true;
        }
      }
      return false;
    }
    var color_contrast_matches_default = colorContrastMatches;
    function dataTableLargeMatches(node) {
      if (is_data_table_default(node)) {
        var tableArray = to_grid_default(node);
        return tableArray.length >= 3 && tableArray[0].length >= 3 && tableArray[1].length >= 3 && tableArray[2].length >= 3;
      }
      return false;
    }
    var data_table_large_matches_default = dataTableLargeMatches;
    function dataTableMatches(node) {
      return is_data_table_default(node);
    }
    var data_table_matches_default = dataTableMatches;
    function duplicateIdActiveMatches(node) {
      var id = node.getAttribute('id').trim();
      var idSelector = '*[id="'.concat(escape_selector_default(id), '"]');
      var idMatchingElms = Array.from(get_root_node_default2(node).querySelectorAll(idSelector));
      return !is_accessible_ref_default(node) && idMatchingElms.some(is_focusable_default);
    }
    var duplicate_id_active_matches_default = duplicateIdActiveMatches;
    function duplicateIdAriaMatches(node) {
      return is_accessible_ref_default(node);
    }
    var duplicate_id_aria_matches_default = duplicateIdAriaMatches;
    function duplicateIdMiscMatches(node) {
      var id = node.getAttribute('id').trim();
      var idSelector = '*[id="'.concat(escape_selector_default(id), '"]');
      var idMatchingElms = Array.from(get_root_node_default2(node).querySelectorAll(idSelector));
      return !is_accessible_ref_default(node) && idMatchingElms.every(function(elm) {
        return !is_focusable_default(elm);
      });
    }
    var duplicate_id_misc_matches_default = duplicateIdMiscMatches;
    function frameFocusableContentMatches(node, virtualNode, context3) {
      return !context3.initiator && !context3.focusable && context3.boundingClientRect.width * context3.boundingClientRect.height > 1;
    }
    var frame_focusable_content_matches_default = frameFocusableContentMatches;
    function frameTitleHasTextMatches(node) {
      var title = node.getAttribute('title');
      return !!sanitize_default(title);
    }
    var frame_title_has_text_matches_default = frameTitleHasTextMatches;
    function headingMatches(node) {
      var explicitRoles;
      if (node.hasAttribute('role')) {
        explicitRoles = node.getAttribute('role').split(/\s+/i).filter(axe.commons.aria.isValidRole);
      }
      if (explicitRoles && explicitRoles.length > 0) {
        return explicitRoles.includes('heading');
      } else {
        return axe.commons.aria.implicitRole(node) === 'heading';
      }
    }
    var heading_matches_default = headingMatches;
    function svgNamespaceMatches(node, virtualNode) {
      try {
        var nodeName2 = virtualNode.props.nodeName;
        if (nodeName2 === 'svg') {
          return true;
        }
        return !!closest_default(virtualNode, 'svg');
      } catch (e) {
        return false;
      }
    }
    var svg_namespace_matches_default = svgNamespaceMatches;
    function htmlNamespaceMatches(node, virtualNode) {
      return !svg_namespace_matches_default(node, virtualNode);
    }
    var html_namespace_matches_default = htmlNamespaceMatches;
    function identicalLinksSamePurposeMatches(node, virtualNode) {
      var hasAccName = !!accessible_text_virtual_default(virtualNode);
      if (!hasAccName) {
        return false;
      }
      var role = get_role_default(node);
      if (role && role !== 'link') {
        return false;
      }
      return true;
    }
    var identical_links_same_purpose_matches_default = identicalLinksSamePurposeMatches;
    function insertedIntoFocusOrderMatches(node) {
      return inserted_into_focus_order_default(node);
    }
    var inserted_into_focus_order_matches_default = insertedIntoFocusOrderMatches;
    function labelContentNameMismatchMatches(node, virtualNode) {
      var role = get_role_default(node);
      if (!role) {
        return false;
      }
      var widgetRoles = get_aria_roles_by_type_default('widget');
      var isWidgetType = widgetRoles.includes(role);
      if (!isWidgetType) {
        return false;
      }
      var rolesWithNameFromContents = get_aria_roles_supporting_name_from_content_default();
      if (!rolesWithNameFromContents.includes(role)) {
        return false;
      }
      if (!sanitize_default(arialabel_text_default(virtualNode)) && !sanitize_default(arialabelledby_text_default(node))) {
        return false;
      }
      if (!sanitize_default(visible_virtual_default(virtualNode))) {
        return false;
      }
      return true;
    }
    var label_content_name_mismatch_matches_default = labelContentNameMismatchMatches;
    function labelMatches(node, virtualNode) {
      if (virtualNode.props.nodeName !== 'input' || virtualNode.hasAttr('type') === false) {
        return true;
      }
      var type = virtualNode.attr('type').toLowerCase();
      return [ 'hidden', 'image', 'button', 'submit', 'reset' ].includes(type) === false;
    }
    var label_matches_default = labelMatches;
    function landmarkHasBodyContextMatches(node, virtualNode) {
      var nativeScopeFilter = 'article, aside, main, nav, section';
      return node.hasAttribute('role') || !find_up_virtual_default(virtualNode, nativeScopeFilter);
    }
    var landmark_has_body_context_matches_default = landmarkHasBodyContextMatches;
    function landmarkUniqueMatches(node, virtualNode) {
      var excludedParentsForHeaderFooterLandmarks = [ 'article', 'aside', 'main', 'nav', 'section' ].join(',');
      function isHeaderFooterLandmark(headerFooterElement) {
        return !find_up_virtual_default(headerFooterElement, excludedParentsForHeaderFooterLandmarks);
      }
      function isLandmarkVirtual(virtualNode2) {
        var actualNode = virtualNode2.actualNode;
        var landmarkRoles2 = get_aria_roles_by_type_default('landmark');
        var role = get_role_default(actualNode);
        if (!role) {
          return false;
        }
        var nodeName2 = actualNode.nodeName.toUpperCase();
        if (nodeName2 === 'HEADER' || nodeName2 === 'FOOTER') {
          return isHeaderFooterLandmark(virtualNode2);
        }
        if (nodeName2 === 'SECTION' || nodeName2 === 'FORM') {
          var accessibleText2 = accessible_text_virtual_default(virtualNode2);
          return !!accessibleText2;
        }
        return landmarkRoles2.indexOf(role) >= 0 || role === 'region';
      }
      return isLandmarkVirtual(virtualNode) && is_visible_default(node, true);
    }
    var landmark_unique_matches_default = landmarkUniqueMatches;
    function dataTableMatches2(node) {
      return !is_data_table_default(node) && !is_focusable_default(node);
    }
    var layout_table_matches_default = dataTableMatches2;
    function linkInTextBlockMatches(node) {
      var text32 = sanitize_default(node.textContent);
      var role = node.getAttribute('role');
      if (role && role !== 'link') {
        return false;
      }
      if (!text32) {
        return false;
      }
      if (!is_visible_default(node, false)) {
        return false;
      }
      return is_in_text_block_default(node);
    }
    var link_in_text_block_matches_default = linkInTextBlockMatches;
    function nestedInteractiveMatches(node, virtualNode) {
      var role = get_role_default(virtualNode);
      if (!role) {
        return false;
      }
      return !!standards_default.ariaRoles[role].childrenPresentational;
    }
    var nested_interactive_matches_default = nestedInteractiveMatches;
    function noAutoplayAudioMatches(node) {
      if (!node.currentSrc) {
        return false;
      }
      if (node.hasAttribute('paused') || node.hasAttribute('muted')) {
        return false;
      }
      return true;
    }
    var no_autoplay_audio_matches_default = noAutoplayAudioMatches;
    function noEmptyRoleMatches(node, virtualNode) {
      if (!virtualNode.hasAttr('role')) {
        return false;
      }
      if (!virtualNode.attr('role').trim()) {
        return false;
      }
      return true;
    }
    var no_empty_role_matches_default = noEmptyRoleMatches;
    function noExplicitNameRequired(node, virtualNode) {
      var role = get_explicit_role_default(virtualNode);
      if (!role || [ 'none', 'presentation' ].includes(role)) {
        return true;
      }
      var _ref65 = aria_roles_default[role] || {}, accessibleNameRequired = _ref65.accessibleNameRequired;
      if (accessibleNameRequired || is_focusable_default(virtualNode)) {
        return true;
      }
      return false;
    }
    var no_explicit_name_required_matches_default = noExplicitNameRequired;
    function noNamingMethodMatches(node, virtualNode) {
      var _get_element_spec_def = get_element_spec_default(virtualNode), namingMethods = _get_element_spec_def.namingMethods;
      if (namingMethods && namingMethods.length !== 0) {
        return false;
      }
      if (get_explicit_role_default(virtualNode) === 'combobox' && query_selector_all_default(virtualNode, 'input:not([type="hidden"])').length) {
        return false;
      }
      return true;
    }
    var no_naming_method_matches_default = noNamingMethodMatches;
    function noRoleMatches(node) {
      return !node.getAttribute('role');
    }
    var no_role_matches_default = noRoleMatches;
    function notHtmlMatches(node, virtualNode) {
      return virtualNode.props.nodeName !== 'html';
    }
    var not_html_matches_default = notHtmlMatches;
    function pAsHeadingMatches(node) {
      var children = Array.from(node.parentNode.childNodes);
      var nodeText = node.textContent.trim();
      var isSentence = /[.!?:;](?![.!?:;])/g;
      if (nodeText.length === 0 || (nodeText.match(isSentence) || []).length >= 2) {
        return false;
      }
      var siblingsAfter = children.slice(children.indexOf(node) + 1).filter(function(elm) {
        return elm.nodeName.toUpperCase() === 'P' && elm.textContent.trim() !== '';
      });
      return siblingsAfter.length !== 0;
    }
    var p_as_heading_matches_default = pAsHeadingMatches;
    function scrollableRegionFocusableMatches(node, virtualNode) {
      if (!!get_scroll_default(node, 13) === false) {
        return false;
      }
      var role = get_explicit_role_default(virtualNode);
      if (standards_default.ariaRoles.combobox.requiredOwned.includes(role)) {
        if (closest_default(virtualNode, '[role~="combobox"]')) {
          return false;
        }
        var id = virtualNode.attr('id');
        if (id) {
          var doc = get_root_node_default(node);
          var owned = Array.from(doc.querySelectorAll('[aria-owns~="'.concat(id, '"], [aria-controls~="').concat(id, '"]')));
          var comboboxOwned = owned.some(function(el) {
            var roles = token_list_default(el.getAttribute('role'));
            return roles.includes('combobox');
          });
          if (comboboxOwned) {
            return false;
          }
        }
      }
      var nodeAndDescendents = query_selector_all_default(virtualNode, '*');
      var hasVisibleChildren = nodeAndDescendents.some(function(elm) {
        return has_content_virtual_default(elm, true, true);
      });
      if (!hasVisibleChildren) {
        return false;
      }
      return true;
    }
    var scrollable_region_focusable_matches_default = scrollableRegionFocusableMatches;
    function skipLinkMatches(node) {
      return is_skip_link_default(node) && is_offscreen_default(node);
    }
    var skip_link_matches_default = skipLinkMatches;
    function windowIsTopMatches(node) {
      return node.ownerDocument.defaultView.self === node.ownerDocument.defaultView.top;
    }
    var window_is_top_matches_default = windowIsTopMatches;
    function xmlLangMismatchMatches(node) {
      var primaryLangValue = get_base_lang_default(node.getAttribute('lang'));
      var primaryXmlLangValue = get_base_lang_default(node.getAttribute('xml:lang'));
      return valid_langs_default(primaryLangValue) && valid_langs_default(primaryXmlLangValue);
    }
    var xml_lang_mismatch_matches_default = xmlLangMismatchMatches;
    var metadataFunctionMap = {
      'abstractrole-evaluate': abstractrole_evaluate_default,
      'aria-allowed-attr-evaluate': aria_allowed_attr_evaluate_default,
      'aria-allowed-role-evaluate': aria_allowed_role_evaluate_default,
      'aria-errormessage-evaluate': aria_errormessage_evaluate_default,
      'aria-hidden-body-evaluate': aria_hidden_body_evaluate_default,
      'aria-prohibited-attr-evaluate': aria_prohibited_attr_evaluate_default,
      'aria-required-attr-evaluate': aria_required_attr_evaluate_default,
      'aria-required-children-evaluate': aria_required_children_evaluate_default,
      'aria-required-parent-evaluate': aria_required_parent_evaluate_default,
      'aria-roledescription-evaluate': aria_roledescription_evaluate_default,
      'aria-unsupported-attr-evaluate': aria_unsupported_attr_evaluate_default,
      'aria-valid-attr-evaluate': aria_valid_attr_evaluate_default,
      'aria-valid-attr-value-evaluate': aria_valid_attr_value_evaluate_default,
      'fallbackrole-evaluate': fallbackrole_evaluate_default,
      'has-global-aria-attribute-evaluate': has_global_aria_attribute_evaluate_default,
      'has-widget-role-evaluate': has_widget_role_evaluate_default,
      'invalidrole-evaluate': invalidrole_evaluate_default,
      'is-element-focusable-evaluate': is_element_focusable_evaluate_default,
      'no-implicit-explicit-label-evaluate': no_implicit_explicit_label_evaluate_default,
      'unsupportedrole-evaluate': unsupportedrole_evaluate_default,
      'valid-scrollable-semantics-evaluate': valid_scrollable_semantics_evaluate_default,
      'caption-faked-evaluate': caption_faked_evaluate_default,
      'html5-scope-evaluate': html5_scope_evaluate_default,
      'same-caption-summary-evaluate': same_caption_summary_evaluate_default,
      'scope-value-evaluate': scope_value_evaluate_default,
      'td-has-header-evaluate': td_has_header_evaluate_default,
      'td-headers-attr-evaluate': td_headers_attr_evaluate_default,
      'th-has-data-cells-evaluate': th_has_data_cells_evaluate_default,
      'hidden-content-evaluate': hidden_content_evaluate_default,
      'color-contrast-evaluate': color_contrast_evaluate_default,
      'link-in-text-block-evaluate': link_in_text_block_evaluate_default,
      'autocomplete-appropriate-evaluate': autocomplete_appropriate_evaluate_default,
      'autocomplete-valid-evaluate': autocomplete_valid_evaluate_default,
      'attr-non-space-content-evaluate': attr_non_space_content_evaluate_default,
      'has-descendant-after': has_descendant_after_default,
      'has-descendant-evaluate': has_descendant_evaluate_default,
      'has-text-content-evaluate': has_text_content_evaluate_default,
      'matches-definition-evaluate': matches_definition_evaluate_default,
      'page-no-duplicate-after': page_no_duplicate_after_default,
      'page-no-duplicate-evaluate': page_no_duplicate_evaluate_default,
      'heading-order-after': heading_order_after_default,
      'heading-order-evaluate': heading_order_evaluate_default,
      'identical-links-same-purpose-after': identical_links_same_purpose_after_default,
      'identical-links-same-purpose-evaluate': identical_links_same_purpose_evaluate_default,
      'internal-link-present-evaluate': internal_link_present_evaluate_default,
      'meta-refresh-evaluate': meta_refresh_evaluate_default,
      'p-as-heading-evaluate': p_as_heading_evaluate_default,
      'region-evaluate': region_evaluate_default,
      'skip-link-evaluate': skip_link_evaluate_default,
      'unique-frame-title-after': unique_frame_title_after_default,
      'unique-frame-title-evaluate': unique_frame_title_evaluate_default,
      'aria-label-evaluate': aria_label_evaluate_default,
      'aria-labelledby-evaluate': aria_labelledby_evaluate_default,
      'avoid-inline-spacing-evaluate': avoid_inline_spacing_evaluate_default,
      'doc-has-title-evaluate': doc_has_title_evaluate_default,
      'exists-evaluate': exists_evaluate_default,
      'has-alt-evaluate': has_alt_evaluate_default,
      'is-on-screen-evaluate': is_on_screen_evaluate_default,
      'non-empty-if-present-evaluate': non_empty_if_present_evaluate_default,
      'presentational-role-evaluate': presentational_role_evaluate_default,
      'svg-non-empty-title-evaluate': svg_non_empty_title_evaluate_default,
      'css-orientation-lock-evaluate': css_orientation_lock_evaluate_default,
      'meta-viewport-scale-evaluate': meta_viewport_scale_evaluate_default,
      'duplicate-id-after': duplicate_id_after_default,
      'duplicate-id-evaluate': duplicate_id_evaluate_default,
      'accesskeys-after': accesskeys_after_default,
      'accesskeys-evaluate': accesskeys_evaluate_default,
      'focusable-content-evaluate': focusable_content_evaluate_default,
      'focusable-disabled-evaluate': focusable_disabled_evaluate_default,
      'focusable-element-evaluate': focusable_element_evaluate_default,
      'focusable-modal-open-evaluate': focusable_modal_open_evaluate_default,
      'focusable-no-name-evaluate': focusable_no_name_evaluate_default,
      'focusable-not-tabbable-evaluate': focusable_not_tabbable_evaluate_default,
      'landmark-is-top-level-evaluate': landmark_is_top_level_evaluate_default,
      'no-focusable-content-evaluate': no_focusable_content_evaluate_default,
      'tabindex-evaluate': tabindex_evaluate_default,
      'alt-space-value-evaluate': alt_space_value_evaluate_default,
      'duplicate-img-label-evaluate': duplicate_img_label_evaluate_default,
      'explicit-evaluate': explicit_evaluate_default,
      'help-same-as-label-evaluate': help_same_as_label_evaluate_default,
      'hidden-explicit-label-evaluate': hidden_explicit_label_evaluate_default,
      'implicit-evaluate': implicit_evaluate_default,
      'label-content-name-mismatch-evaluate': label_content_name_mismatch_evaluate_default,
      'multiple-label-evaluate': multiple_label_evaluate_default,
      'title-only-evaluate': title_only_evaluate_default,
      'landmark-is-unique-after': landmark_is_unique_after_default,
      'landmark-is-unique-evaluate': landmark_is_unique_evaluate_default,
      'has-lang-evaluate': has_lang_evaluate_default,
      'valid-lang-evaluate': valid_lang_evaluate_default,
      'xml-lang-mismatch-evaluate': xml_lang_mismatch_evaluate_default,
      'dlitem-evaluate': dlitem_evaluate_default,
      'listitem-evaluate': listitem_evaluate_default,
      'only-dlitems-evaluate': only_dlitems_evaluate_default,
      'only-listitems-evaluate': only_listitems_evaluate_default,
      'structured-dlitems-evaluate': structured_dlitems_evaluate_default,
      'caption-evaluate': caption_evaluate_default,
      'frame-tested-evaluate': frame_tested_evaluate_default,
      'no-autoplay-audio-evaluate': no_autoplay_audio_evaluate_default,
      'aria-allowed-attr-matches': aria_allowed_attr_matches_default,
      'aria-allowed-role-matches': aria_allowed_role_matches_default,
      'aria-form-field-name-matches': no_naming_method_matches_default,
      'aria-has-attr-matches': aria_has_attr_matches_default,
      'aria-hidden-focus-matches': aria_hidden_focus_matches_default,
      'aria-required-children-matches': aria_required_children_matches_default,
      'aria-required-parent-matches': aria_required_parent_matches_default,
      'autocomplete-matches': autocomplete_matches_default,
      'bypass-matches': bypass_matches_default,
      'color-contrast-matches': color_contrast_matches_default,
      'data-table-large-matches': data_table_large_matches_default,
      'data-table-matches': data_table_matches_default,
      'duplicate-id-active-matches': duplicate_id_active_matches_default,
      'duplicate-id-aria-matches': duplicate_id_aria_matches_default,
      'duplicate-id-misc-matches': duplicate_id_misc_matches_default,
      'frame-focusable-content-matches': frame_focusable_content_matches_default,
      'frame-title-has-text-matches': frame_title_has_text_matches_default,
      'heading-matches': heading_matches_default,
      'html-namespace-matches': html_namespace_matches_default,
      'identical-links-same-purpose-matches': identical_links_same_purpose_matches_default,
      'inserted-into-focus-order-matches': inserted_into_focus_order_matches_default,
      'is-initiator-matches': is_initiator_matches_default,
      'label-content-name-mismatch-matches': label_content_name_mismatch_matches_default,
      'label-matches': label_matches_default,
      'landmark-has-body-context-matches': landmark_has_body_context_matches_default,
      'landmark-unique-matches': landmark_unique_matches_default,
      'layout-table-matches': layout_table_matches_default,
      'link-in-text-block-matches': link_in_text_block_matches_default,
      'nested-interactive-matches': nested_interactive_matches_default,
      'no-autoplay-audio-matches': no_autoplay_audio_matches_default,
      'no-empty-role-matches': no_empty_role_matches_default,
      'no-explicit-name-required-matches': no_explicit_name_required_matches_default,
      'no-naming-method-matches': no_naming_method_matches_default,
      'no-role-matches': no_role_matches_default,
      'not-html-matches': not_html_matches_default,
      'p-as-heading-matches': p_as_heading_matches_default,
      'scrollable-region-focusable-matches': scrollable_region_focusable_matches_default,
      'skip-link-matches': skip_link_matches_default,
      'svg-namespace-matches': svg_namespace_matches_default,
      'window-is-top-matches': window_is_top_matches_default,
      'xml-lang-mismatch-matches': xml_lang_mismatch_matches_default
    };
    var metadata_function_map_default = metadataFunctionMap;
    function CheckResult(check4) {
      this.id = check4.id;
      this.data = null;
      this.relatedNodes = [];
      this.result = null;
    }
    var check_result_default = CheckResult;
    function createExecutionContext(spec) {
      if (typeof spec === 'string') {
        if (metadata_function_map_default[spec]) {
          return metadata_function_map_default[spec];
        }
        if (/^\s*function[\s\w]*\(/.test(spec)) {
          return new Function('return ' + spec + ';')();
        }
        throw new ReferenceError('Function ID does not exist in the metadata-function-map: '.concat(spec));
      }
      return spec;
    }
    function normalizeOptions() {
      var options = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : {};
      if (Array.isArray(options) || _typeof(options) !== 'object') {
        options = {
          value: options
        };
      }
      return options;
    }
    function Check(spec) {
      if (spec) {
        this.id = spec.id;
        this.configure(spec);
      }
    }
    Check.prototype.enabled = true;
    Check.prototype.run = function run(node, options, context3, resolve, reject) {
      options = options || {};
      var enabled = options.hasOwnProperty('enabled') ? options.enabled : this.enabled;
      var checkOptions = this.getOptions(options.options);
      if (enabled) {
        var checkResult = new check_result_default(this);
        var helper = check_helper_default(checkResult, options, resolve, reject);
        var result;
        try {
          result = this.evaluate.call(helper, node.actualNode, checkOptions, node, context3);
        } catch (e) {
          if (node && node.actualNode) {
            e.errorNode = new dq_element_default(node.actualNode).toJSON();
          }
          reject(e);
          return;
        }
        if (!helper.isAsync) {
          checkResult.result = result;
          resolve(checkResult);
        }
      } else {
        resolve(null);
      }
    };
    Check.prototype.runSync = function runSync(node, options, context3) {
      options = options || {};
      var _options = options, _options$enabled = _options.enabled, enabled = _options$enabled === void 0 ? this.enabled : _options$enabled;
      if (!enabled) {
        return null;
      }
      var checkOptions = this.getOptions(options.options);
      var checkResult = new check_result_default(this);
      var helper = check_helper_default(checkResult, options);
      helper.async = function async() {
        throw new Error('Cannot run async check while in a synchronous run');
      };
      var result;
      try {
        result = this.evaluate.call(helper, node.actualNode, checkOptions, node, context3);
      } catch (e) {
        if (node && node.actualNode) {
          e.errorNode = new dq_element_default(node.actualNode).toJSON();
        }
        throw e;
      }
      checkResult.result = result;
      return checkResult;
    };
    Check.prototype.configure = function configure(spec) {
      var _this3 = this;
      if (!spec.evaluate || metadata_function_map_default[spec.evaluate]) {
        this._internalCheck = true;
      }
      if (spec.hasOwnProperty('enabled')) {
        this.enabled = spec.enabled;
      }
      if (spec.hasOwnProperty('options')) {
        if (this._internalCheck) {
          this.options = normalizeOptions(spec.options);
        } else {
          this.options = spec.options;
        }
      }
      [ 'evaluate', 'after' ].filter(function(prop) {
        return spec.hasOwnProperty(prop);
      }).forEach(function(prop) {
        return _this3[prop] = createExecutionContext(spec[prop]);
      });
    };
    Check.prototype.getOptions = function getOptions(options) {
      if (this._internalCheck) {
        return deep_merge_default(this.options, normalizeOptions(options || {}));
      } else {
        return options || this.options;
      }
    };
    var check_default = Check;
    function RuleResult(rule3) {
      this.id = rule3.id;
      this.result = constants_default.NA;
      this.pageLevel = rule3.pageLevel;
      this.impact = null;
      this.nodes = [];
    }
    var rule_result_default = RuleResult;
    function Rule(spec, parentAudit) {
      this._audit = parentAudit;
      this.id = spec.id;
      this.selector = spec.selector || '*';
      if (spec.impact) {
        assert_default(constants_default.impact.includes(spec.impact), 'Impact '.concat(spec.impact, ' is not a valid impact'));
        this.impact = spec.impact;
      }
      this.excludeHidden = typeof spec.excludeHidden === 'boolean' ? spec.excludeHidden : true;
      this.enabled = typeof spec.enabled === 'boolean' ? spec.enabled : true;
      this.pageLevel = typeof spec.pageLevel === 'boolean' ? spec.pageLevel : false;
      this.reviewOnFail = typeof spec.reviewOnFail === 'boolean' ? spec.reviewOnFail : false;
      this.any = spec.any || [];
      this.all = spec.all || [];
      this.none = spec.none || [];
      this.tags = spec.tags || [];
      this.preload = spec.preload ? true : false;
      if (spec.matches) {
        this.matches = createExecutionContext(spec.matches);
      }
    }
    Rule.prototype.matches = function matches13() {
      return true;
    };
    Rule.prototype.gather = function gather(context3) {
      var options = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : {};
      var markStart = 'mark_gather_start_' + this.id;
      var markEnd = 'mark_gather_end_' + this.id;
      var markHiddenStart = 'mark_isHidden_start_' + this.id;
      var markHiddenEnd = 'mark_isHidden_end_' + this.id;
      if (options.performanceTimer) {
        performance_timer_default.mark(markStart);
      }
      var elements = select_default(this.selector, context3);
      if (this.excludeHidden) {
        if (options.performanceTimer) {
          performance_timer_default.mark(markHiddenStart);
        }
        elements = elements.filter(function(element) {
          return !is_hidden_default(element.actualNode);
        });
        if (options.performanceTimer) {
          performance_timer_default.mark(markHiddenEnd);
          performance_timer_default.measure('rule_' + this.id + '#gather_axe.utils.isHidden', markHiddenStart, markHiddenEnd);
        }
      }
      if (options.performanceTimer) {
        performance_timer_default.mark(markEnd);
        performance_timer_default.measure('rule_' + this.id + '#gather', markStart, markEnd);
      }
      return elements;
    };
    Rule.prototype.runChecks = function runChecks(type, node, options, context3, resolve, reject) {
      var self2 = this;
      var checkQueue = queue_default();
      this[type].forEach(function(c) {
        var check4 = self2._audit.checks[c.id || c];
        var option = get_check_option_default(check4, self2.id, options);
        checkQueue.defer(function(res, rej) {
          check4.run(node, option, context3, res, rej);
        });
      });
      checkQueue.then(function(results) {
        results = results.filter(function(check4) {
          return check4;
        });
        resolve({
          type: type,
          results: results
        });
      })['catch'](reject);
    };
    Rule.prototype.runChecksSync = function runChecksSync(type, node, options, context3) {
      var self2 = this;
      var results = [];
      this[type].forEach(function(c) {
        var check4 = self2._audit.checks[c.id || c];
        var option = get_check_option_default(check4, self2.id, options);
        results.push(check4.runSync(node, option, context3));
      });
      results = results.filter(function(check4) {
        return check4;
      });
      return {
        type: type,
        results: results
      };
    };
    Rule.prototype.run = function run2(context3) {
      var _this4 = this;
      var options = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : {};
      var resolve = arguments.length > 2 ? arguments[2] : undefined;
      var reject = arguments.length > 3 ? arguments[3] : undefined;
      if (options.performanceTimer) {
        this._trackPerformance();
      }
      var q = queue_default();
      var ruleResult = new rule_result_default(this);
      var nodes;
      try {
        nodes = this.gatherAndMatchNodes(context3, options);
      } catch (error) {
        reject(new SupportError({
          cause: error,
          ruleId: this.id
        }));
        return;
      }
      if (options.performanceTimer) {
        this._logGatherPerformance(nodes);
      }
      nodes.forEach(function(node) {
        q.defer(function(resolveNode, rejectNode) {
          var checkQueue = queue_default();
          [ 'any', 'all', 'none' ].forEach(function(type) {
            checkQueue.defer(function(res, rej) {
              _this4.runChecks(type, node, options, context3, res, rej);
            });
          });
          checkQueue.then(function(results) {
            var result = getResult(results);
            if (result) {
              result.node = new dq_element_default(node.actualNode, options);
              ruleResult.nodes.push(result);
              if (_this4.reviewOnFail) {
                [ 'any', 'all' ].forEach(function(type) {
                  result[type].forEach(function(checkResult) {
                    if (checkResult.result === false) {
                      checkResult.result = void 0;
                    }
                  });
                });
                result.none.forEach(function(checkResult) {
                  if (checkResult.result === true) {
                    checkResult.result = void 0;
                  }
                });
              }
            }
            resolveNode();
          })['catch'](function(err2) {
            return rejectNode(err2);
          });
        });
      });
      q.defer(function(resolve2) {
        return setTimeout(resolve2, 0);
      });
      if (options.performanceTimer) {
        this._logRulePerformance();
      }
      q.then(function() {
        return resolve(ruleResult);
      })['catch'](function(error) {
        return reject(error);
      });
    };
    Rule.prototype.runSync = function runSync2(context3) {
      var _this5 = this;
      var options = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : {};
      if (options.performanceTimer) {
        this._trackPerformance();
      }
      var ruleResult = new rule_result_default(this);
      var nodes;
      try {
        nodes = this.gatherAndMatchNodes(context3, options);
      } catch (error) {
        throw new SupportError({
          cause: error,
          ruleId: this.id
        });
      }
      if (options.performanceTimer) {
        this._logGatherPerformance(nodes);
      }
      nodes.forEach(function(node) {
        var results = [];
        [ 'any', 'all', 'none' ].forEach(function(type) {
          results.push(_this5.runChecksSync(type, node, options, context3));
        });
        var result = getResult(results);
        if (result) {
          result.node = node.actualNode ? new dq_element_default(node.actualNode, options) : null;
          ruleResult.nodes.push(result);
          if (_this5.reviewOnFail) {
            [ 'any', 'all' ].forEach(function(type) {
              result[type].forEach(function(checkResult) {
                if (checkResult.result === false) {
                  checkResult.result = void 0;
                }
              });
            });
            result.none.forEach(function(checkResult) {
              if (checkResult.result === true) {
                checkResult.result = void 0;
              }
            });
          }
        }
      });
      if (options.performanceTimer) {
        this._logRulePerformance();
      }
      return ruleResult;
    };
    Rule.prototype._trackPerformance = function _trackPerformance() {
      this._markStart = 'mark_rule_start_' + this.id;
      this._markEnd = 'mark_rule_end_' + this.id;
      this._markChecksStart = 'mark_runchecks_start_' + this.id;
      this._markChecksEnd = 'mark_runchecks_end_' + this.id;
    };
    Rule.prototype._logGatherPerformance = function _logGatherPerformance(nodes) {
      log_default('gather (', nodes.length, '):', performance_timer_default.timeElapsed() + 'ms');
      performance_timer_default.mark(this._markChecksStart);
    };
    Rule.prototype._logRulePerformance = function _logRulePerformance() {
      performance_timer_default.mark(this._markChecksEnd);
      performance_timer_default.mark(this._markEnd);
      performance_timer_default.measure('runchecks_' + this.id, this._markChecksStart, this._markChecksEnd);
      performance_timer_default.measure('rule_' + this.id, this._markStart, this._markEnd);
    };
    function getResult(results) {
      if (results.length) {
        var hasResults = false;
        var result = {};
        results.forEach(function(r) {
          var res = r.results.filter(function(result2) {
            return result2;
          });
          result[r.type] = res;
          if (res.length) {
            hasResults = true;
          }
        });
        if (hasResults) {
          return result;
        }
        return null;
      }
    }
    Rule.prototype.gatherAndMatchNodes = function gatherAndMatchNodes(context3, options) {
      var _this6 = this;
      var markMatchesStart = 'mark_matches_start_' + this.id;
      var markMatchesEnd = 'mark_matches_end_' + this.id;
      var nodes = this.gather(context3, options);
      if (options.performanceTimer) {
        performance_timer_default.mark(markMatchesStart);
      }
      nodes = nodes.filter(function(node) {
        return _this6.matches(node.actualNode, node, context3);
      });
      if (options.performanceTimer) {
        performance_timer_default.mark(markMatchesEnd);
        performance_timer_default.measure('rule_' + this.id + '#matches', markMatchesStart, markMatchesEnd);
      }
      return nodes;
    };
    function findAfterChecks(rule3) {
      return get_all_checks_default(rule3).map(function(c) {
        var check4 = rule3._audit.checks[c.id || c];
        return check4 && typeof check4.after === 'function' ? check4 : null;
      }).filter(Boolean);
    }
    function findCheckResults(nodes, checkID) {
      var checkResults = [];
      nodes.forEach(function(nodeResult) {
        var checks = get_all_checks_default(nodeResult);
        checks.forEach(function(checkResult) {
          if (checkResult.id === checkID) {
            checkResult.node = nodeResult.node;
            checkResults.push(checkResult);
          }
        });
      });
      return checkResults;
    }
    function filterChecks(checks) {
      return checks.filter(function(check4) {
        return check4.filtered !== true;
      });
    }
    function sanitizeNodes(result) {
      var checkTypes2 = [ 'any', 'all', 'none' ];
      var nodes = result.nodes.filter(function(detail) {
        var length = 0;
        checkTypes2.forEach(function(type) {
          detail[type] = filterChecks(detail[type]);
          length += detail[type].length;
        });
        return length > 0;
      });
      if (result.pageLevel && nodes.length) {
        nodes = [ nodes.reduce(function(a, b) {
          if (a) {
            checkTypes2.forEach(function(type) {
              a[type].push.apply(a[type], b[type]);
            });
            return a;
          }
        }) ];
      }
      return nodes;
    }
    Rule.prototype.after = function after(result, options) {
      var afterChecks = findAfterChecks(this);
      var ruleID = this.id;
      afterChecks.forEach(function(check4) {
        var beforeResults = findCheckResults(result.nodes, check4.id);
        var option = get_check_option_default(check4, ruleID, options);
        var afterResults = check4.after(beforeResults, option);
        beforeResults.forEach(function(item) {
          delete item.node;
          if (afterResults.indexOf(item) === -1) {
            item.filtered = true;
          }
        });
      });
      result.nodes = sanitizeNodes(result);
      return result;
    };
    Rule.prototype.configure = function configure2(spec) {
      if (spec.hasOwnProperty('selector')) {
        this.selector = spec.selector;
      }
      if (spec.hasOwnProperty('excludeHidden')) {
        this.excludeHidden = typeof spec.excludeHidden === 'boolean' ? spec.excludeHidden : true;
      }
      if (spec.hasOwnProperty('enabled')) {
        this.enabled = typeof spec.enabled === 'boolean' ? spec.enabled : true;
      }
      if (spec.hasOwnProperty('pageLevel')) {
        this.pageLevel = typeof spec.pageLevel === 'boolean' ? spec.pageLevel : false;
      }
      if (spec.hasOwnProperty('reviewOnFail')) {
        this.reviewOnFail = typeof spec.reviewOnFail === 'boolean' ? spec.reviewOnFail : false;
      }
      if (spec.hasOwnProperty('any')) {
        this.any = spec.any;
      }
      if (spec.hasOwnProperty('all')) {
        this.all = spec.all;
      }
      if (spec.hasOwnProperty('none')) {
        this.none = spec.none;
      }
      if (spec.hasOwnProperty('tags')) {
        this.tags = spec.tags;
      }
      if (spec.hasOwnProperty('matches')) {
        this.matches = createExecutionContext(spec.matches);
      }
      if (spec.impact) {
        assert_default(constants_default.impact.includes(spec.impact), 'Impact '.concat(spec.impact, ' is not a valid impact'));
        this.impact = spec.impact;
      }
    };
    var rule_default = Rule;
    var dot = __toModule(require_doT());
    var dotRegex = /\{\{.+?\}\}/g;
    function getDefaultOrigin() {
      if (window.origin) {
        return window.origin;
      }
      if (window.location && window.location.origin) {
        return window.location.origin;
      }
    }
    function getDefaultConfiguration(audit3) {
      var config;
      if (audit3) {
        config = clone_default(audit3);
        config.commons = audit3.commons;
      } else {
        config = {};
      }
      config.reporter = config.reporter || null;
      config.noHtml = config.noHtml || false;
      if (!config.allowedOrigins) {
        var defaultOrigin = getDefaultOrigin();
        config.allowedOrigins = defaultOrigin ? [ defaultOrigin ] : [];
      }
      config.rules = config.rules || [];
      config.checks = config.checks || [];
      config.data = _extends({
        checks: {},
        rules: {}
      }, config.data);
      return config;
    }
    function unpackToObject(collection, audit3, method) {
      var i, l;
      for (i = 0, l = collection.length; i < l; i++) {
        audit3[method](collection[i]);
      }
    }
    var mergeCheckLocale = function mergeCheckLocale(a, b) {
      var pass = b.pass, fail = b.fail;
      if (typeof pass === 'string' && dotRegex.test(pass)) {
        pass = dot['default'].compile(pass);
      }
      if (typeof fail === 'string' && dotRegex.test(fail)) {
        fail = dot['default'].compile(fail);
      }
      return _extends({}, a, {
        messages: {
          pass: pass || a.messages.pass,
          fail: fail || a.messages.fail,
          incomplete: _typeof(a.messages.incomplete) === 'object' ? _extends({}, a.messages.incomplete, b.incomplete) : b.incomplete
        }
      });
    };
    var mergeRuleLocale = function mergeRuleLocale(a, b) {
      var help = b.help, description = b.description;
      if (typeof help === 'string' && dotRegex.test(help)) {
        help = dot['default'].compile(help);
      }
      if (typeof description === 'string' && dotRegex.test(description)) {
        description = dot['default'].compile(description);
      }
      return _extends({}, a, {
        help: help || a.help,
        description: description || a.description
      });
    };
    var mergeFailureMessage = function mergeFailureMessage(a, b) {
      var failureMessage = b.failureMessage;
      if (typeof failureMessage === 'string' && dotRegex.test(failureMessage)) {
        failureMessage = dot['default'].compile(failureMessage);
      }
      return _extends({}, a, {
        failureMessage: failureMessage || a.failureMessage
      });
    };
    var mergeFallbackMessage = function mergeFallbackMessage(a, b) {
      if (typeof b === 'string' && dotRegex.test(b)) {
        b = dot['default'].compile(b);
      }
      return b || a;
    };
    var Audit = function() {
      function Audit(audit3) {
        _classCallCheck(this, Audit);
        this.lang = 'en';
        this.defaultConfig = audit3;
        this.standards = standards_default;
        this._init();
        this._defaultLocale = null;
      }
      _createClass(Audit, [ {
        key: '_setDefaultLocale',
        value: function _setDefaultLocale() {
          if (this._defaultLocale) {
            return;
          }
          var locale = {
            checks: {},
            rules: {},
            failureSummaries: {},
            incompleteFallbackMessage: '',
            lang: this.lang
          };
          var checkIDs = Object.keys(this.data.checks);
          for (var _i24 = 0; _i24 < checkIDs.length; _i24++) {
            var id = checkIDs[_i24];
            var check4 = this.data.checks[id];
            var _check4$messages = check4.messages, pass = _check4$messages.pass, fail = _check4$messages.fail, incomplete = _check4$messages.incomplete;
            locale.checks[id] = {
              pass: pass,
              fail: fail,
              incomplete: incomplete
            };
          }
          var ruleIDs = Object.keys(this.data.rules);
          for (var _i25 = 0; _i25 < ruleIDs.length; _i25++) {
            var _id = ruleIDs[_i25];
            var rule3 = this.data.rules[_id];
            var description = rule3.description, help = rule3.help;
            locale.rules[_id] = {
              description: description,
              help: help
            };
          }
          var failureSummaries = Object.keys(this.data.failureSummaries);
          for (var _i26 = 0; _i26 < failureSummaries.length; _i26++) {
            var type = failureSummaries[_i26];
            var failureSummary2 = this.data.failureSummaries[type];
            var failureMessage = failureSummary2.failureMessage;
            locale.failureSummaries[type] = {
              failureMessage: failureMessage
            };
          }
          locale.incompleteFallbackMessage = this.data.incompleteFallbackMessage;
          this._defaultLocale = locale;
        }
      }, {
        key: '_resetLocale',
        value: function _resetLocale() {
          var defaultLocale = this._defaultLocale;
          if (!defaultLocale) {
            return;
          }
          this.applyLocale(defaultLocale);
        }
      }, {
        key: '_applyCheckLocale',
        value: function _applyCheckLocale(checks) {
          var keys = Object.keys(checks);
          for (var _i27 = 0; _i27 < keys.length; _i27++) {
            var id = keys[_i27];
            if (!this.data.checks[id]) {
              throw new Error('Locale provided for unknown check: "'.concat(id, '"'));
            }
            this.data.checks[id] = mergeCheckLocale(this.data.checks[id], checks[id]);
          }
        }
      }, {
        key: '_applyRuleLocale',
        value: function _applyRuleLocale(rules) {
          var keys = Object.keys(rules);
          for (var _i28 = 0; _i28 < keys.length; _i28++) {
            var id = keys[_i28];
            if (!this.data.rules[id]) {
              throw new Error('Locale provided for unknown rule: "'.concat(id, '"'));
            }
            this.data.rules[id] = mergeRuleLocale(this.data.rules[id], rules[id]);
          }
        }
      }, {
        key: '_applyFailureSummaries',
        value: function _applyFailureSummaries(messages) {
          var keys = Object.keys(messages);
          for (var _i29 = 0; _i29 < keys.length; _i29++) {
            var key = keys[_i29];
            if (!this.data.failureSummaries[key]) {
              throw new Error('Locale provided for unknown failureMessage: "'.concat(key, '"'));
            }
            this.data.failureSummaries[key] = mergeFailureMessage(this.data.failureSummaries[key], messages[key]);
          }
        }
      }, {
        key: 'applyLocale',
        value: function applyLocale(locale) {
          this._setDefaultLocale();
          if (locale.checks) {
            this._applyCheckLocale(locale.checks);
          }
          if (locale.rules) {
            this._applyRuleLocale(locale.rules);
          }
          if (locale.failureSummaries) {
            this._applyFailureSummaries(locale.failureSummaries, 'failureSummaries');
          }
          if (locale.incompleteFallbackMessage) {
            this.data.incompleteFallbackMessage = mergeFallbackMessage(this.data.incompleteFallbackMessage, locale.incompleteFallbackMessage);
          }
          if (locale.lang) {
            this.lang = locale.lang;
          }
        }
      }, {
        key: 'setAllowedOrigins',
        value: function setAllowedOrigins(allowedOrigins) {
          var defaultOrigin = getDefaultOrigin();
          this.allowedOrigins = [];
          var _iterator2 = _createForOfIteratorHelper(allowedOrigins), _step2;
          try {
            for (_iterator2.s(); !(_step2 = _iterator2.n()).done; ) {
              var origin = _step2.value;
              if (origin === constants_default.allOrigins) {
                this.allowedOrigins = [ '*' ];
                return;
              } else if (origin !== constants_default.sameOrigin) {
                this.allowedOrigins.push(origin);
              } else if (defaultOrigin) {
                this.allowedOrigins.push(defaultOrigin);
              }
            }
          } catch (err) {
            _iterator2.e(err);
          } finally {
            _iterator2.f();
          }
        }
      }, {
        key: '_init',
        value: function _init() {
          var audit3 = getDefaultConfiguration(this.defaultConfig);
          this.lang = audit3.lang || 'en';
          this.reporter = audit3.reporter;
          this.commands = {};
          this.rules = [];
          this.checks = {};
          this.brand = 'axe';
          this.application = 'axeAPI';
          this.tagExclude = [ 'experimental' ];
          this.noHtml = audit3.noHtml;
          this.allowedOrigins = audit3.allowedOrigins;
          unpackToObject(audit3.rules, this, 'addRule');
          unpackToObject(audit3.checks, this, 'addCheck');
          this.data = {};
          this.data.checks = audit3.data && audit3.data.checks || {};
          this.data.rules = audit3.data && audit3.data.rules || {};
          this.data.failureSummaries = audit3.data && audit3.data.failureSummaries || {};
          this.data.incompleteFallbackMessage = audit3.data && audit3.data.incompleteFallbackMessage || '';
          this._constructHelpUrls();
        }
      }, {
        key: 'registerCommand',
        value: function registerCommand(command) {
          this.commands[command.id] = command.callback;
        }
      }, {
        key: 'addRule',
        value: function addRule(spec) {
          if (spec.metadata) {
            this.data.rules[spec.id] = spec.metadata;
          }
          var rule3 = this.getRule(spec.id);
          if (rule3) {
            rule3.configure(spec);
          } else {
            this.rules.push(new rule_default(spec, this));
          }
        }
      }, {
        key: 'addCheck',
        value: function addCheck(spec) {
          var metadata = spec.metadata;
          if (_typeof(metadata) === 'object') {
            this.data.checks[spec.id] = metadata;
            if (_typeof(metadata.messages) === 'object') {
              Object.keys(metadata.messages).filter(function(prop) {
                return metadata.messages.hasOwnProperty(prop) && typeof metadata.messages[prop] === 'string';
              }).forEach(function(prop) {
                if (metadata.messages[prop].indexOf('function') === 0) {
                  metadata.messages[prop] = new Function('return ' + metadata.messages[prop] + ';')();
                }
              });
            }
          }
          if (this.checks[spec.id]) {
            this.checks[spec.id].configure(spec);
          } else {
            this.checks[spec.id] = new check_default(spec);
          }
        }
      }, {
        key: 'run',
        value: function run(context3, options, resolve, reject) {
          this.normalizeOptions(options);
          axe._selectCache = [];
          var allRulesToRun = getRulesToRun(this.rules, context3, options);
          var runNowRules = allRulesToRun.now;
          var runLaterRules = allRulesToRun.later;
          var nowRulesQueue = queue_default();
          runNowRules.forEach(function(rule3) {
            nowRulesQueue.defer(getDefferedRule(rule3, context3, options));
          });
          var preloaderQueue = queue_default();
          if (runLaterRules.length) {
            preloaderQueue.defer(function(resolve2) {
              preload_default(options).then(function(assets) {
                return resolve2(assets);
              })['catch'](function(err2) {
                console.warn('Couldn\'t load preload assets: ', err2);
                resolve2(void 0);
              });
            });
          }
          var queueForNowRulesAndPreloader = queue_default();
          queueForNowRulesAndPreloader.defer(nowRulesQueue);
          queueForNowRulesAndPreloader.defer(preloaderQueue);
          queueForNowRulesAndPreloader.then(function(nowRulesAndPreloaderResults) {
            var assetsFromQueue = nowRulesAndPreloaderResults.pop();
            if (assetsFromQueue && assetsFromQueue.length) {
              var assets = assetsFromQueue[0];
              if (assets) {
                context3 = _extends({}, context3, assets);
              }
            }
            var nowRulesResults = nowRulesAndPreloaderResults[0];
            if (!runLaterRules.length) {
              axe._selectCache = void 0;
              resolve(nowRulesResults.filter(function(result) {
                return !!result;
              }));
              return;
            }
            var laterRulesQueue = queue_default();
            runLaterRules.forEach(function(rule3) {
              var deferredRule = getDefferedRule(rule3, context3, options);
              laterRulesQueue.defer(deferredRule);
            });
            laterRulesQueue.then(function(laterRuleResults) {
              axe._selectCache = void 0;
              resolve(nowRulesResults.concat(laterRuleResults).filter(function(result) {
                return !!result;
              }));
            })['catch'](reject);
          })['catch'](reject);
        }
      }, {
        key: 'after',
        value: function after(results, options) {
          var rules = this.rules;
          return results.map(function(ruleResult) {
            var rule3 = find_by_default(rules, 'id', ruleResult.id);
            if (!rule3) {
              throw new Error('Result for unknown rule. You may be running mismatch axe-core versions');
            }
            return rule3.after(ruleResult, options);
          });
        }
      }, {
        key: 'getRule',
        value: function getRule(ruleId) {
          return this.rules.find(function(rule3) {
            return rule3.id === ruleId;
          });
        }
      }, {
        key: 'normalizeOptions',
        value: function normalizeOptions(options) {
          var audit3 = this;
          var tags = [];
          var ruleIds = [];
          audit3.rules.forEach(function(rule3) {
            ruleIds.push(rule3.id);
            rule3.tags.forEach(function(tag) {
              if (!tags.includes(tag)) {
                tags.push(tag);
              }
            });
          });
          if (_typeof(options.runOnly) === 'object') {
            if (Array.isArray(options.runOnly)) {
              var hasTag = options.runOnly.find(function(value) {
                return tags.includes(value);
              });
              var hasRule = options.runOnly.find(function(value) {
                return ruleIds.includes(value);
              });
              if (hasTag && hasRule) {
                throw new Error('runOnly cannot be both rules and tags');
              }
              if (hasRule) {
                options.runOnly = {
                  type: 'rule',
                  values: options.runOnly
                };
              } else {
                options.runOnly = {
                  type: 'tag',
                  values: options.runOnly
                };
              }
            }
            var only = options.runOnly;
            if (only.value && !only.values) {
              only.values = only.value;
              delete only.value;
            }
            if (!Array.isArray(only.values) || only.values.length === 0) {
              throw new Error('runOnly.values must be a non-empty array');
            }
            if ([ 'rule', 'rules' ].includes(only.type)) {
              only.type = 'rule';
              only.values.forEach(function(ruleId) {
                if (!ruleIds.includes(ruleId)) {
                  throw new Error('unknown rule `' + ruleId + '` in options.runOnly');
                }
              });
            } else if ([ 'tag', 'tags', void 0 ].includes(only.type)) {
              only.type = 'tag';
              var unmatchedTags = only.values.filter(function(tag) {
                return !tags.includes(tag);
              });
              if (unmatchedTags.length !== 0) {
                log_default('Could not find tags `' + unmatchedTags.join('`, `') + '`');
              }
            } else {
              throw new Error('Unknown runOnly type \''.concat(only.type, '\''));
            }
          }
          if (_typeof(options.rules) === 'object') {
            Object.keys(options.rules).forEach(function(ruleId) {
              if (!ruleIds.includes(ruleId)) {
                throw new Error('unknown rule `' + ruleId + '` in options.rules');
              }
            });
          }
          return options;
        }
      }, {
        key: 'setBranding',
        value: function setBranding(branding) {
          var previous = {
            brand: this.brand,
            application: this.application
          };
          if (branding && branding.hasOwnProperty('brand') && branding.brand && typeof branding.brand === 'string') {
            this.brand = branding.brand;
          }
          if (branding && branding.hasOwnProperty('application') && branding.application && typeof branding.application === 'string') {
            this.application = branding.application;
          }
          this._constructHelpUrls(previous);
        }
      }, {
        key: '_constructHelpUrls',
        value: function _constructHelpUrls() {
          var _this7 = this;
          var previous = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : null;
          var version = (axe.version.match(/^[1-9][0-9]*\.[0-9]+/) || [ 'x.y' ])[0];
          this.rules.forEach(function(rule3) {
            if (!_this7.data.rules[rule3.id]) {
              _this7.data.rules[rule3.id] = {};
            }
            var metaData = _this7.data.rules[rule3.id];
            if (typeof metaData.helpUrl !== 'string' || previous && metaData.helpUrl === getHelpUrl(previous, rule3.id, version)) {
              metaData.helpUrl = getHelpUrl(_this7, rule3.id, version);
            }
          });
        }
      }, {
        key: 'resetRulesAndChecks',
        value: function resetRulesAndChecks() {
          this._init();
          this._resetLocale();
        }
      } ]);
      return Audit;
    }();
    function getRulesToRun(rules, context3, options) {
      var base = {
        now: [],
        later: []
      };
      var splitRules = rules.reduce(function(out, rule3) {
        if (!rule_should_run_default(rule3, context3, options)) {
          return out;
        }
        if (rule3.preload) {
          out.later.push(rule3);
          return out;
        }
        out.now.push(rule3);
        return out;
      }, base);
      return splitRules;
    }
    function getDefferedRule(rule3, context3, options) {
      if (options.performanceTimer) {
        performance_timer_default.mark('mark_rule_start_' + rule3.id);
      }
      return function(resolve, reject) {
        rule3.run(context3, options, function(ruleResult) {
          resolve(ruleResult);
        }, function(err2) {
          if (!options.debug) {
            var errResult = Object.assign(new rule_result_default(rule3), {
              result: constants_default.CANTTELL,
              description: 'An error occured while running this rule',
              message: err2.message,
              stack: err2.stack,
              error: err2,
              errorNode: err2.errorNode
            });
            resolve(errResult);
          } else {
            reject(err2);
          }
        });
      };
    }
    function getHelpUrl(_ref66, ruleId, version) {
      var brand = _ref66.brand, application = _ref66.application, lang = _ref66.lang;
      return constants_default.helpUrlBase + brand + '/' + (version || axe.version.substring(0, axe.version.lastIndexOf('.'))) + '/' + ruleId + '?application=' + encodeURIComponent(application) + (lang && lang !== 'en' ? '&lang=' + encodeURIComponent(lang) : '');
    }
    var audit_default = Audit;
    function pushUniqueFrame(collection, frame) {
      if (is_hidden_default(frame)) {
        return;
      }
      var fr = find_by_default(collection, 'node', frame);
      if (!fr) {
        collection.push({
          node: frame,
          include: [],
          exclude: []
        });
      }
    }
    function pushUniqueFrameSelector(context3, type, selectorArray) {
      context3.frames = context3.frames || [];
      var result, frame;
      var frames = document.querySelectorAll(selectorArray.shift());
      frameloop: for (var i = 0, l = frames.length; i < l; i++) {
        frame = frames[i];
        for (var j = 0, l2 = context3.frames.length; j < l2; j++) {
          if (context3.frames[j].node === frame) {
            context3.frames[j][type].push(selectorArray);
            break frameloop;
          }
        }
        result = {
          node: frame,
          include: [],
          exclude: []
        };
        if (selectorArray) {
          result[type].push(selectorArray);
        }
        context3.frames.push(result);
      }
    }
    function normalizeContext(context3) {
      if (context3 && _typeof(context3) === 'object' || context3 instanceof window.NodeList) {
        if (context3 instanceof window.Node) {
          return {
            include: [ context3 ],
            exclude: []
          };
        }
        if (context3.hasOwnProperty('include') || context3.hasOwnProperty('exclude')) {
          return {
            include: context3.include && +context3.include.length ? context3.include : [ document ],
            exclude: context3.exclude || []
          };
        }
        if (context3.length === +context3.length) {
          return {
            include: context3,
            exclude: []
          };
        }
      }
      if (typeof context3 === 'string') {
        return {
          include: [ context3 ],
          exclude: []
        };
      }
      return {
        include: [ document ],
        exclude: []
      };
    }
    function parseSelectorArray(context3, type) {
      var item, result = [], nodeList;
      for (var i = 0, l = context3[type].length; i < l; i++) {
        item = context3[type][i];
        if (typeof item === 'string') {
          nodeList = Array.from(document.querySelectorAll(item));
          result = result.concat(nodeList.map(function(node) {
            return get_node_from_tree_default(node);
          }));
          break;
        } else if (item && item.length && !(item instanceof window.Node)) {
          if (item.length > 1) {
            pushUniqueFrameSelector(context3, type, item);
          } else {
            nodeList = Array.from(document.querySelectorAll(item[0]));
            result = result.concat(nodeList.map(function(node) {
              return get_node_from_tree_default(node);
            }));
          }
        } else if (item instanceof window.Node) {
          if (item.documentElement instanceof window.Node) {
            result.push(context3.flatTree[0]);
          } else {
            result.push(get_node_from_tree_default(item));
          }
        }
      }
      return result.filter(function(r) {
        return r;
      });
    }
    function validateContext(context3) {
      if (context3.include.length === 0) {
        if (context3.frames.length === 0) {
          var env = _respondable.isInFrame() ? 'frame' : 'page';
          return new Error('No elements found for include in ' + env + ' Context');
        }
        context3.frames.forEach(function(frame, i) {
          if (frame.include.length === 0) {
            return new Error('No elements found for include in Context of frame ' + i);
          }
        });
      }
    }
    function getRootNode2(_ref67) {
      var include = _ref67.include, exclude = _ref67.exclude;
      var selectors = Array.from(include).concat(Array.from(exclude));
      for (var i = 0; i < selectors.length; ++i) {
        var item = selectors[i];
        if (item instanceof window.Element) {
          return item.ownerDocument.documentElement;
        }
        if (item instanceof window.Document) {
          return item.documentElement;
        }
      }
      return document.documentElement;
    }
    function Context(spec) {
      var _this8 = this;
      this.frames = [];
      this.initiator = spec && typeof spec.initiator === 'boolean' ? spec.initiator : true;
      this.focusable = spec && typeof spec.focusable === 'boolean' ? spec.focusable : true;
      this.boundingClientRect = spec && _typeof(spec.boundingClientRect) === 'object' ? spec.boundingClientRect : {};
      this.page = false;
      spec = normalizeContext(spec);
      this.flatTree = get_flattened_tree_default(getRootNode2(spec));
      this.exclude = spec.exclude;
      this.include = spec.include;
      this.include = parseSelectorArray(this, 'include');
      this.exclude = parseSelectorArray(this, 'exclude');
      select_default('frame, iframe', this).forEach(function(frame) {
        if (is_node_in_context_default(frame, _this8)) {
          pushUniqueFrame(_this8.frames, frame.actualNode);
        }
      });
      if (this.include.length === 1 && this.include[0].actualNode === document.documentElement) {
        this.page = true;
      }
      var err2 = validateContext(this);
      if (err2 instanceof Error) {
        throw err2;
      }
      if (!Array.isArray(this.include)) {
        this.include = Array.from(this.include);
      }
      this.include.sort(node_sorter_default);
    }
    var context_default = Context;
    var imports_exports = {};
    __export(imports_exports, {
      CssSelectorParser: function CssSelectorParser() {
        return css_selector_parser2.CssSelectorParser;
      },
      doT: function doT() {
        return dot2['default'];
      },
      emojiRegexText: function emojiRegexText() {
        return emoji_regex3['default'];
      },
      memoize: function memoize() {
        return memoizee2['default'];
      }
    });
    var css_selector_parser2 = __toModule(require_lib());
    var dot2 = __toModule(require_doT());
    var emoji_regex3 = __toModule(require_emoji_regex());
    var memoizee2 = __toModule(require_memoizee());
    var es6_promise = __toModule(require_es6_promise());
    var typedarray = __toModule(require_typedarray());
    var weakmap_polyfill = __toModule(require_weakmap_polyfill());
    if (!('Promise' in window)) {
      es6_promise['default'].polyfill();
    }
    if (!('Uint32Array' in window)) {
      window.Uint32Array = typedarray.Uint32Array;
    }
    if (window.Uint32Array) {
      if (!('some' in window.Uint32Array.prototype)) {
        Object.defineProperty(window.Uint32Array.prototype, 'some', {
          value: Array.prototype.some
        });
      }
      if (!('reduce' in window.Uint32Array.prototype)) {
        Object.defineProperty(window.Uint32Array.prototype, 'reduce', {
          value: Array.prototype.reduce
        });
      }
    }
    function cleanup(resolve, reject) {
      resolve = resolve || function res() {};
      reject = reject || axe.log;
      if (!axe._audit) {
        throw new Error('No audit configured');
      }
      var q = axe.utils.queue();
      var cleanupErrors = [];
      Object.keys(axe.plugins).forEach(function(key) {
        q.defer(function(res) {
          var rej = function rej2(err2) {
            cleanupErrors.push(err2);
            res();
          };
          try {
            axe.plugins[key].cleanup(res, rej);
          } catch (err2) {
            rej(err2);
          }
        });
      });
      var flattenedTree = axe.utils.getFlattenedTree(document.body);
      axe.utils.querySelectorAll(flattenedTree, 'iframe, frame').forEach(function(node) {
        q.defer(function(res, rej) {
          return axe.utils.sendCommandToFrame(node.actualNode, {
            command: 'cleanup-plugin'
          }, res, rej);
        });
      });
      q.then(function(results) {
        if (cleanupErrors.length === 0) {
          resolve(results);
        } else {
          reject(cleanupErrors);
        }
      })['catch'](reject);
    }
    var cleanup_default = cleanup;
    var reporters = {};
    var defaultReporter;
    function hasReporter(reporterName) {
      return reporters.hasOwnProperty(reporterName);
    }
    function getReporter(reporter4) {
      if (typeof reporter4 === 'string' && reporters[reporter4]) {
        return reporters[reporter4];
      }
      if (typeof reporter4 === 'function') {
        return reporter4;
      }
      return defaultReporter;
    }
    function addReporter(name, cb, isDefault) {
      reporters[name] = cb;
      if (isDefault) {
        defaultReporter = cb;
      }
    }
    function configure3(spec) {
      var audit3;
      audit3 = axe._audit;
      if (!audit3) {
        throw new Error('No audit configured');
      }
      if (spec.axeVersion || spec.ver) {
        var specVersion = spec.axeVersion || spec.ver;
        if (!/^\d+\.\d+\.\d+(-canary)?/.test(specVersion)) {
          throw new Error('Invalid configured version '.concat(specVersion));
        }
        var _specVersion$split = specVersion.split('-'), _specVersion$split2 = _slicedToArray(_specVersion$split, 2), version = _specVersion$split2[0], canary = _specVersion$split2[1];
        var _version$split$map = version.split('.').map(Number), _version$split$map2 = _slicedToArray(_version$split$map, 3), major = _version$split$map2[0], minor = _version$split$map2[1], patch = _version$split$map2[2];
        var _axe$version$split = axe.version.split('-'), _axe$version$split2 = _slicedToArray(_axe$version$split, 2), axeVersion = _axe$version$split2[0], axeCanary = _axe$version$split2[1];
        var _axeVersion$split$map = axeVersion.split('.').map(Number), _axeVersion$split$map2 = _slicedToArray(_axeVersion$split$map, 3), axeMajor = _axeVersion$split$map2[0], axeMinor = _axeVersion$split$map2[1], axePatch = _axeVersion$split$map2[2];
        if (major !== axeMajor || axeMinor < minor || axeMinor === minor && axePatch < patch || major === axeMajor && minor === axeMinor && patch === axePatch && canary && canary !== axeCanary) {
          throw new Error('Configured version '.concat(specVersion, ' is not compatible with current axe version ').concat(axe.version));
        }
      }
      if (spec.reporter && (typeof spec.reporter === 'function' || hasReporter(spec.reporter))) {
        audit3.reporter = spec.reporter;
      }
      if (spec.checks) {
        if (!Array.isArray(spec.checks)) {
          throw new TypeError('Checks property must be an array');
        }
        spec.checks.forEach(function(check4) {
          if (!check4.id) {
            throw new TypeError('Configured check '.concat(JSON.stringify(check4), ' is invalid. Checks must be an object with at least an id property'));
          }
          audit3.addCheck(check4);
        });
      }
      var modifiedRules = [];
      if (spec.rules) {
        if (!Array.isArray(spec.rules)) {
          throw new TypeError('Rules property must be an array');
        }
        spec.rules.forEach(function(rule3) {
          if (!rule3.id) {
            throw new TypeError('Configured rule '.concat(JSON.stringify(rule3), ' is invalid. Rules must be an object with at least an id property'));
          }
          modifiedRules.push(rule3.id);
          audit3.addRule(rule3);
        });
      }
      if (spec.disableOtherRules) {
        audit3.rules.forEach(function(rule3) {
          if (modifiedRules.includes(rule3.id) === false) {
            rule3.enabled = false;
          }
        });
      }
      if (typeof spec.branding !== 'undefined') {
        audit3.setBranding(spec.branding);
      } else {
        audit3._constructHelpUrls();
      }
      if (spec.tagExclude) {
        audit3.tagExclude = spec.tagExclude;
      }
      if (spec.locale) {
        audit3.applyLocale(spec.locale);
      }
      if (spec.standards) {
        configureStandards(spec.standards);
      }
      if (spec.noHtml) {
        audit3.noHtml = true;
      }
      if (spec.allowedOrigins) {
        if (!Array.isArray(spec.allowedOrigins)) {
          throw new TypeError('Allowed origins property must be an array');
        }
        if (spec.allowedOrigins.includes('*')) {
          throw new Error('"*" is not allowed. Use "'.concat(constants_default.allOrigins, '" instead'));
        }
        audit3.setAllowedOrigins(spec.allowedOrigins);
      }
    }
    var configure_default = configure3;
    function frameMessenger2(frameHandler) {
      _respondable.updateMessenger(frameHandler);
    }
    function getRules(tags) {
      tags = tags || [];
      var matchingRules = !tags.length ? axe._audit.rules : axe._audit.rules.filter(function(item) {
        return !!tags.filter(function(tag) {
          return item.tags.indexOf(tag) !== -1;
        }).length;
      });
      var ruleData = axe._audit.data.rules || {};
      return matchingRules.map(function(matchingRule) {
        var rd = ruleData[matchingRule.id] || {};
        return {
          ruleId: matchingRule.id,
          description: rd.description,
          help: rd.help,
          helpUrl: rd.helpUrl,
          tags: matchingRule.tags
        };
      });
    }
    var get_rules_default = getRules;
    function teardown() {
      if (cache_default.get('globalDocumentSet')) {
        document = null;
      }
      if (cache_default.get('globalWindowSet')) {
        window = null;
      }
      axe._memoizedFns.forEach(function(fn) {
        return fn.clear();
      });
      cache_default.clear();
      axe._tree = void 0;
      axe._selectorData = void 0;
      axe._selectCache = void 0;
    }
    var teardown_default = teardown;
    function runRules(context3, options, resolve, reject) {
      try {
        context3 = new context_default(context3);
        axe._tree = context3.flatTree;
        axe._selectorData = _getSelectorData(context3.flatTree);
      } catch (e) {
        teardown_default();
        return reject(e);
      }
      var q = queue_default();
      var audit3 = axe._audit;
      if (options.performanceTimer) {
        performance_timer_default.auditStart();
      }
      if (context3.frames.length && options.iframes !== false) {
        q.defer(function(res, rej) {
          collect_results_from_frames_default(context3, options, 'rules', null, res, rej);
        });
      }
      q.defer(function(res, rej) {
        audit3.run(context3, options, res, rej);
      });
      q.then(function(data2) {
        try {
          if (options.performanceTimer) {
            performance_timer_default.auditEnd();
          }
          var results = merge_results_default(data2.map(function(results2) {
            return {
              results: results2
            };
          }));
          if (context3.initiator) {
            results = audit3.after(results, options);
            results.forEach(publish_metadata_default);
            results = results.map(finalize_result_default);
          }
          try {
            resolve(results, teardown_default);
          } catch (e) {
            teardown_default();
            log_default(e);
          }
        } catch (e) {
          teardown_default();
          reject(e);
        }
      })['catch'](function(e) {
        teardown_default();
        reject(e);
      });
    }
    var run_rules_default = runRules;
    function runCommand(data2, keepalive, callback) {
      var resolve = callback;
      var reject = function reject2(err2) {
        if (err2 instanceof Error === false) {
          err2 = new Error(err2);
        }
        callback(err2);
      };
      var context3 = data2 && data2.context || {};
      if (context3.hasOwnProperty('include') && !context3.include.length) {
        context3.include = [ document ];
      }
      var options = data2 && data2.options || {};
      switch (data2.command) {
       case 'rules':
        return run_rules_default(context3, options, function(results, cleanup5) {
          resolve(results);
          cleanup5();
        }, reject);

       case 'cleanup-plugin':
        return cleanup_default(resolve, reject);

       default:
        if (axe._audit && axe._audit.commands && axe._audit.commands[data2.command]) {
          return axe._audit.commands[data2.command](data2, callback);
        }
      }
    }
    if (window.top !== window) {
      _respondable.subscribe('axe.start', runCommand);
      _respondable.subscribe('axe.ping', function(data2, keepalive, respond) {
        respond({
          axe: true
        });
      });
    }
    function load(audit3) {
      axe._audit = new audit_default(audit3);
    }
    var load_default = load;
    function Plugin(spec) {
      this._run = spec.run;
      this._collect = spec.collect;
      this._registry = {};
      spec.commands.forEach(function(command) {
        axe._audit.registerCommand(command);
      });
    }
    Plugin.prototype.run = function run3() {
      return this._run.apply(this, arguments);
    };
    Plugin.prototype.collect = function collect() {
      return this._collect.apply(this, arguments);
    };
    Plugin.prototype.cleanup = function cleanup3(done) {
      var q = axe.utils.queue();
      var that = this;
      Object.keys(this._registry).forEach(function(key) {
        q.defer(function(_done) {
          that._registry[key].cleanup(_done);
        });
      });
      q.then(done);
    };
    Plugin.prototype.add = function add(impl) {
      this._registry[impl.id] = impl;
    };
    function registerPlugin(plugin) {
      axe.plugins[plugin.id] = new Plugin(plugin);
    }
    var plugins_default = registerPlugin;
    function reset() {
      var audit3 = axe._audit;
      if (!audit3) {
        throw new Error('No audit configured');
      }
      audit3.resetRulesAndChecks();
      resetStandards();
    }
    var reset_default = reset;
    function runVirtualRule(ruleId, vNode) {
      var options = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : {};
      options.reporter = options.reporter || axe._audit.reporter || 'v1';
      axe._selectorData = {};
      if (!(vNode instanceof abstract_virtual_node_default)) {
        vNode = new serial_virtual_node_default(vNode);
      }
      var rule3 = get_rule_default(ruleId);
      if (!rule3) {
        throw new Error('unknown rule `' + ruleId + '`');
      }
      rule3 = Object.create(rule3, {
        excludeHidden: {
          value: false
        }
      });
      var context3 = {
        initiator: true,
        include: [ vNode ]
      };
      var rawResults = rule3.runSync(context3, options);
      publish_metadata_default(rawResults);
      finalize_result_default(rawResults);
      var results = aggregate_result_default([ rawResults ]);
      results.violations.forEach(function(result) {
        return result.nodes.forEach(function(nodeResult) {
          nodeResult.failureSummary = failure_summary_default(nodeResult);
        });
      });
      return _extends({}, get_environment_data_default(), results, {
        toolOptions: options
      });
    }
    var run_virtual_rule_default = runVirtualRule;
    function isContext(potential) {
      switch (true) {
       case typeof potential === 'string':
       case Array.isArray(potential):
       case window.Node && potential instanceof window.Node:
       case window.NodeList && potential instanceof window.NodeList:
        return true;

       case _typeof(potential) !== 'object':
        return false;

       case potential.include !== void 0:
       case potential.exclude !== void 0:
       case typeof potential.length === 'number':
        return true;

       default:
        return false;
      }
    }
    var noop2 = function noop3() {};
    function normalizeRunParams(context3, options, callback) {
      var typeErr = new TypeError('axe.run arguments are invalid');
      if (!isContext(context3)) {
        if (callback !== void 0) {
          throw typeErr;
        }
        callback = options;
        options = context3;
        context3 = document;
      }
      if (_typeof(options) !== 'object') {
        if (callback !== void 0) {
          throw typeErr;
        }
        callback = options;
        options = {};
      }
      if (typeof callback !== 'function' && callback !== void 0) {
        throw typeErr;
      }
      return {
        context: context3,
        options: options,
        callback: callback || noop2
      };
    }
    function run4(context3, options, callback) {
      if (!axe._audit) {
        throw new Error('No audit configured');
      }
      var hasWindow = window && 'Node' in window && 'NodeList' in window;
      var hasDoc = !!document;
      if (!hasWindow || !hasDoc) {
        if (!context3 || !context3.ownerDocument) {
          throw new Error('Required "window" or "document" globals not defined and cannot be deduced from the context. Either set the globals before running or pass in a valid Element.');
        }
        if (!hasDoc) {
          cache_default.set('globalDocumentSet', true);
          document = context3.ownerDocument;
        }
        if (!hasWindow) {
          cache_default.set('globalWindowSet', true);
          window = document.defaultView;
        }
      }
      var args = normalizeRunParams(context3, options, callback);
      context3 = args.context;
      options = args.options;
      callback = args.callback;
      options.reporter = options.reporter || axe._audit.reporter || 'v1';
      if (options.performanceTimer) {
        axe.utils.performanceTimer.start();
      }
      var p;
      var reject = noop2;
      var resolve = noop2;
      if (typeof Promise === 'function' && callback === noop2) {
        p = new Promise(function(_resolve, _reject) {
          reject = _reject;
          resolve = _resolve;
        });
      }
      if (axe._running) {
        var err2 = 'Axe is already running. Use `await axe.run()` to wait for the previous run to finish before starting a new run.';
        callback(err2);
        reject(err2);
        return p;
      }
      axe._running = true;
      axe._runRules(context3, options, function(rawResults, cleanup5) {
        var respond = function respond(results) {
          axe._running = false;
          cleanup5();
          try {
            callback(null, results);
          } catch (e) {
            axe.log(e);
          }
          resolve(results);
        };
        if (options.performanceTimer) {
          axe.utils.performanceTimer.end();
        }
        try {
          var reporter4 = getReporter(options.reporter);
          var results = reporter4(rawResults, options, respond);
          if (results !== void 0) {
            respond(results);
          }
        } catch (err2) {
          axe._running = false;
          cleanup5();
          callback(err2);
          reject(err2);
        }
      }, function(err2) {
        axe._running = false;
        callback(err2);
        reject(err2);
      });
      return p;
    }
    var run_default = run4;
    function setup(node) {
      if (axe._tree) {
        throw new Error('Axe is already setup. Call `axe.teardown()` before calling `axe.setup` again.');
      }
      axe._tree = get_flattened_tree_default(node);
      axe._selectorData = _getSelectorData(axe._tree);
      return axe._tree[0];
    }
    var setup_default = setup;
    var naReporter = function naReporter(results, options, callback) {
      console.warn('"na" reporter will be deprecated in axe v4.0. Use the "v2" reporter instead.');
      if (typeof options === 'function') {
        callback = options;
        options = {};
      }
      var out = process_aggregate_default(results, options);
      callback(_extends({}, get_environment_data_default(), {
        toolOptions: options,
        violations: out.violations,
        passes: out.passes,
        incomplete: out.incomplete,
        inapplicable: out.inapplicable
      }));
    };
    var na_default = naReporter;
    var noPassesReporter = function noPassesReporter(results, options, callback) {
      if (typeof options === 'function') {
        callback = options;
        options = {};
      }
      options.resultTypes = [ 'violations' ];
      var out = process_aggregate_default(results, options);
      callback(_extends({}, get_environment_data_default(), {
        toolOptions: options,
        violations: out.violations
      }));
    };
    var no_passes_default = noPassesReporter;
    var rawReporter = function rawReporter(results, options, callback) {
      if (typeof options === 'function') {
        callback = options;
        options = {};
      }
      if (!results || !Array.isArray(results)) {
        return callback(results);
      }
      var transformedResults = results.map(function(result) {
        var transformedResult = _extends({}, result);
        var types = [ 'passes', 'violations', 'incomplete', 'inapplicable' ];
        for (var _i30 = 0, _types = types; _i30 < _types.length; _i30++) {
          var type = _types[_i30];
          if (transformedResult[type] && Array.isArray(transformedResult[type])) {
            transformedResult[type] = transformedResult[type].map(function(typeResult) {
              return _extends({}, typeResult, {
                node: typeResult.node.toJSON()
              });
            });
          }
        }
        return transformedResult;
      });
      callback(transformedResults);
    };
    var raw_default = rawReporter;
    var rawEnvReporter = function rawEnvReporter(results, options, callback) {
      if (typeof options === 'function') {
        callback = options;
        options = {};
      }
      function rawCallback(raw3) {
        var env = get_environment_data_default();
        callback({
          raw: raw3,
          env: env
        });
      }
      raw_default(results, options, rawCallback);
    };
    var raw_env_default = rawEnvReporter;
    var v1Reporter = function v1Reporter(results, options, callback) {
      if (typeof options === 'function') {
        callback = options;
        options = {};
      }
      var out = process_aggregate_default(results, options);
      var addFailureSummaries = function addFailureSummaries(result) {
        result.nodes.forEach(function(nodeResult) {
          nodeResult.failureSummary = failure_summary_default(nodeResult);
        });
      };
      out.incomplete.forEach(addFailureSummaries);
      out.violations.forEach(addFailureSummaries);
      callback(_extends({}, get_environment_data_default(), {
        toolOptions: options,
        violations: out.violations,
        passes: out.passes,
        incomplete: out.incomplete,
        inapplicable: out.inapplicable
      }));
    };
    var v1_default = v1Reporter;
    var v2Reporter = function v2Reporter(results, options, callback) {
      if (typeof options === 'function') {
        callback = options;
        options = {};
      }
      var out = process_aggregate_default(results, options);
      callback(_extends({}, get_environment_data_default(), {
        toolOptions: options,
        violations: out.violations,
        passes: out.passes,
        incomplete: out.incomplete,
        inapplicable: out.inapplicable
      }));
    };
    var v2_default = v2Reporter;
    axe.constants = constants_default;
    axe.log = log_default;
    axe.AbstractVirtualNode = abstract_virtual_node_default;
    axe.SerialVirtualNode = serial_virtual_node_default;
    axe.VirtualNode = virtual_node_default;
    axe._cache = cache_default;
    axe._thisWillBeDeletedDoNotUse = axe._thisWillBeDeletedDoNotUse || {};
    axe._thisWillBeDeletedDoNotUse.base = {
      Audit: audit_default,
      CheckResult: check_result_default,
      Check: check_default,
      Context: context_default,
      RuleResult: rule_result_default,
      Rule: rule_default,
      metadataFunctionMap: metadata_function_map_default
    };
    axe.imports = imports_exports;
    axe.cleanup = cleanup_default;
    axe.configure = configure_default;
    axe.frameMessenger = frameMessenger2;
    axe.getRules = get_rules_default;
    axe._load = load_default;
    axe.plugins = {};
    axe.registerPlugin = plugins_default;
    axe.hasReporter = hasReporter;
    axe.getReporter = getReporter;
    axe.addReporter = addReporter;
    axe.reset = reset_default;
    axe._runRules = run_rules_default;
    axe.runVirtualRule = run_virtual_rule_default;
    axe.run = run_default;
    axe.setup = setup_default;
    axe.teardown = teardown_default;
    axe.commons = commons_exports;
    axe.utils = utils_exports;
    axe.addReporter('na', na_default);
    axe.addReporter('no-passes', no_passes_default);
    axe.addReporter('rawEnv', raw_env_default);
    axe.addReporter('raw', raw_default);
    axe.addReporter('v1', v1_default);
    axe.addReporter('v2', v2_default, true);
  })();
  'use strict';
  axe._load({
    lang: 'en',
    data: {
      rules: {
        accesskeys: {
          description: 'Ensures every accesskey attribute value is unique',
          help: 'accesskey attribute value should be unique'
        },
        'area-alt': {
          description: 'Ensures <area> elements of image maps have alternate text',
          help: 'Active <area> elements must have alternate text'
        },
        'aria-allowed-attr': {
          description: 'Ensures ARIA attributes are allowed for an element\'s role',
          help: 'Elements must only use allowed ARIA attributes'
        },
        'aria-allowed-role': {
          description: 'Ensures role attribute has an appropriate value for the element',
          help: 'ARIA role should be appropriate for the element'
        },
        'aria-command-name': {
          description: 'Ensures every ARIA button, link and menuitem has an accessible name',
          help: 'ARIA commands must have an accessible name'
        },
        'aria-dialog-name': {
          description: 'Ensures every ARIA dialog and alertdialog node has an accessible name',
          help: 'ARIA dialog and alertdialog nodes should have an accessible name'
        },
        'aria-hidden-body': {
          description: 'Ensures aria-hidden=\'true\' is not present on the document body.',
          help: 'aria-hidden=\'true\' must not be present on the document body'
        },
        'aria-hidden-focus': {
          description: 'Ensures aria-hidden elements do not contain focusable elements',
          help: 'ARIA hidden element must not contain focusable elements'
        },
        'aria-input-field-name': {
          description: 'Ensures every ARIA input field has an accessible name',
          help: 'ARIA input fields must have an accessible name'
        },
        'aria-meter-name': {
          description: 'Ensures every ARIA meter node has an accessible name',
          help: 'ARIA meter nodes must have an accessible name'
        },
        'aria-progressbar-name': {
          description: 'Ensures every ARIA progressbar node has an accessible name',
          help: 'ARIA progressbar nodes must have an accessible name'
        },
        'aria-required-attr': {
          description: 'Ensures elements with ARIA roles have all required ARIA attributes',
          help: 'Required ARIA attributes must be provided'
        },
        'aria-required-children': {
          description: 'Ensures elements with an ARIA role that require child roles contain them',
          help: 'Certain ARIA roles must contain particular children'
        },
        'aria-required-parent': {
          description: 'Ensures elements with an ARIA role that require parent roles are contained by them',
          help: 'Certain ARIA roles must be contained by particular parents'
        },
        'aria-roledescription': {
          description: 'Ensure aria-roledescription is only used on elements with an implicit or explicit role',
          help: 'Use aria-roledescription on elements with a semantic role'
        },
        'aria-roles': {
          description: 'Ensures all elements with a role attribute use a valid value',
          help: 'ARIA roles used must conform to valid values'
        },
        'aria-text': {
          description: 'Ensures "role=text" is used on elements with no focusable descendants',
          help: '"role=text" should have no focusable descendants'
        },
        'aria-toggle-field-name': {
          description: 'Ensures every ARIA toggle field has an accessible name',
          help: 'ARIA toggle fields have an accessible name'
        },
        'aria-tooltip-name': {
          description: 'Ensures every ARIA tooltip node has an accessible name',
          help: 'ARIA tooltip nodes must have an accessible name'
        },
        'aria-treeitem-name': {
          description: 'Ensures every ARIA treeitem node has an accessible name',
          help: 'ARIA treeitem nodes should have an accessible name'
        },
        'aria-valid-attr-value': {
          description: 'Ensures all ARIA attributes have valid values',
          help: 'ARIA attributes must conform to valid values'
        },
        'aria-valid-attr': {
          description: 'Ensures attributes that begin with aria- are valid ARIA attributes',
          help: 'ARIA attributes must conform to valid names'
        },
        'audio-caption': {
          description: 'Ensures <audio> elements have captions',
          help: '<audio> elements must have a captions track'
        },
        'autocomplete-valid': {
          description: 'Ensure the autocomplete attribute is correct and suitable for the form field',
          help: 'autocomplete attribute must be used correctly'
        },
        'avoid-inline-spacing': {
          description: 'Ensure that text spacing set through style attributes can be adjusted with custom stylesheets',
          help: 'Inline text spacing must be adjustable with custom stylesheets'
        },
        blink: {
          description: 'Ensures <blink> elements are not used',
          help: '<blink> elements are deprecated and must not be used'
        },
        'button-name': {
          description: 'Ensures buttons have discernible text',
          help: 'Buttons must have discernible text'
        },
        bypass: {
          description: 'Ensures each page has at least one mechanism for a user to bypass navigation and jump straight to the content',
          help: 'Page must have means to bypass repeated blocks'
        },
        'color-contrast': {
          description: 'Ensures the contrast between foreground and background colors meets WCAG 2 AA contrast ratio thresholds',
          help: 'Elements must have sufficient color contrast'
        },
        'css-orientation-lock': {
          description: 'Ensures content is not locked to any specific display orientation, and the content is operable in all display orientations',
          help: 'CSS Media queries are not used to lock display orientation'
        },
        'definition-list': {
          description: 'Ensures <dl> elements are structured correctly',
          help: '<dl> elements must only directly contain properly-ordered <dt> and <dd> groups, <script>, <template> or <div> elements'
        },
        dlitem: {
          description: 'Ensures <dt> and <dd> elements are contained by a <dl>',
          help: '<dt> and <dd> elements must be contained by a <dl>'
        },
        'document-title': {
          description: 'Ensures each HTML document contains a non-empty <title> element',
          help: 'Documents must have <title> element to aid in navigation'
        },
        'duplicate-id-active': {
          description: 'Ensures every id attribute value of active elements is unique',
          help: 'IDs of active elements must be unique'
        },
        'duplicate-id-aria': {
          description: 'Ensures every id attribute value used in ARIA and in labels is unique',
          help: 'IDs used in ARIA and labels must be unique'
        },
        'duplicate-id': {
          description: 'Ensures every id attribute value is unique',
          help: 'id attribute value must be unique'
        },
        'empty-heading': {
          description: 'Ensures headings have discernible text',
          help: 'Headings should not be empty'
        },
        'empty-table-header': {
          description: 'Ensures table headers have discernible text',
          help: 'Table header text must not be empty'
        },
        'focus-order-semantics': {
          description: 'Ensures elements in the focus order have an appropriate role',
          help: 'Elements in the focus order need a role appropriate for interactive content'
        },
        'form-field-multiple-labels': {
          description: 'Ensures form field does not have multiple label elements',
          help: 'Form field must not have multiple label elements'
        },
        'frame-focusable-content': {
          description: 'Ensures <frame> and <iframe> elements with tabindex=-1 do not have focusable content',
          help: 'Frames with tabindex=-1 must not have focusable content'
        },
        'frame-tested': {
          description: 'Ensures <iframe> and <frame> elements contain the axe-core script',
          help: 'Frames should be tested with axe-core'
        },
        'frame-title-unique': {
          description: 'Ensures <iframe> and <frame> elements contain a unique title attribute',
          help: 'Frames should have a unique title attribute'
        },
        'frame-title': {
          description: 'Ensures <iframe> and <frame> elements have an accessible name',
          help: 'Frames must have an accessible name'
        },
        'heading-order': {
          description: 'Ensures the order of headings is semantically correct',
          help: 'Heading levels should only increase by one'
        },
        'hidden-content': {
          description: 'Informs users about hidden content.',
          help: 'Hidden content on the page cannot be analyzed'
        },
        'html-has-lang': {
          description: 'Ensures every HTML document has a lang attribute',
          help: '<html> element must have a lang attribute'
        },
        'html-lang-valid': {
          description: 'Ensures the lang attribute of the <html> element has a valid value',
          help: '<html> element must have a valid value for the lang attribute'
        },
        'html-xml-lang-mismatch': {
          description: 'Ensure that HTML elements with both valid lang and xml:lang attributes agree on the base language of the page',
          help: 'HTML elements with lang and xml:lang must have the same base language'
        },
        'identical-links-same-purpose': {
          description: 'Ensure that links with the same accessible name serve a similar purpose',
          help: 'Links with the same name have a similar purpose'
        },
        'image-alt': {
          description: 'Ensures <img> elements have alternate text or a role of none or presentation',
          help: 'Images must have alternate text'
        },
        'image-redundant-alt': {
          description: 'Ensure image alternative is not repeated as text',
          help: 'Alternative text of images should not be repeated as text'
        },
        'input-button-name': {
          description: 'Ensures input buttons have discernible text',
          help: 'Input buttons must have discernible text'
        },
        'input-image-alt': {
          description: 'Ensures <input type="image"> elements have alternate text',
          help: 'Image buttons must have alternate text'
        },
        'label-content-name-mismatch': {
          description: 'Ensures that elements labelled through their content must have their visible text as part of their accessible name',
          help: 'Elements must have their visible text as part of their accessible name'
        },
        'label-title-only': {
          description: 'Ensures that every form element is not solely labeled using the title or aria-describedby attributes',
          help: 'Form elements should have a visible label'
        },
        label: {
          description: 'Ensures every form element has a label',
          help: 'Form elements must have labels'
        },
        'landmark-banner-is-top-level': {
          description: 'Ensures the banner landmark is at top level',
          help: 'Banner landmark should not be contained in another landmark'
        },
        'landmark-complementary-is-top-level': {
          description: 'Ensures the complementary landmark or aside is at top level',
          help: 'Aside should not be contained in another landmark'
        },
        'landmark-contentinfo-is-top-level': {
          description: 'Ensures the contentinfo landmark is at top level',
          help: 'Contentinfo landmark should not be contained in another landmark'
        },
        'landmark-main-is-top-level': {
          description: 'Ensures the main landmark is at top level',
          help: 'Main landmark should not be contained in another landmark'
        },
        'landmark-no-duplicate-banner': {
          description: 'Ensures the document has at most one banner landmark',
          help: 'Document should not have more than one banner landmark'
        },
        'landmark-no-duplicate-contentinfo': {
          description: 'Ensures the document has at most one contentinfo landmark',
          help: 'Document should not have more than one contentinfo landmark'
        },
        'landmark-no-duplicate-main': {
          description: 'Ensures the document has at most one main landmark',
          help: 'Document should not have more than one main landmark'
        },
        'landmark-one-main': {
          description: 'Ensures the document has a main landmark',
          help: 'Document should have one main landmark'
        },
        'landmark-unique': {
          help: 'Ensures landmarks are unique',
          description: 'Landmarks should have a unique role or role/label/title (i.e. accessible name) combination'
        },
        'link-in-text-block': {
          description: 'Links can be distinguished without relying on color',
          help: 'Links must be distinguished from surrounding text in a way that does not rely on color'
        },
        'link-name': {
          description: 'Ensures links have discernible text',
          help: 'Links must have discernible text'
        },
        list: {
          description: 'Ensures that lists are structured correctly',
          help: '<ul> and <ol> must only directly contain <li>, <script> or <template> elements'
        },
        listitem: {
          description: 'Ensures <li> elements are used semantically',
          help: '<li> elements must be contained in a <ul> or <ol>'
        },
        marquee: {
          description: 'Ensures <marquee> elements are not used',
          help: '<marquee> elements are deprecated and must not be used'
        },
        'meta-refresh': {
          description: 'Ensures <meta http-equiv="refresh"> is not used',
          help: 'Timed refresh must not exist'
        },
        'meta-viewport-large': {
          description: 'Ensures <meta name="viewport"> can scale a significant amount',
          help: 'Users should be able to zoom and scale the text up to 500%'
        },
        'meta-viewport': {
          description: 'Ensures <meta name="viewport"> does not disable text scaling and zooming',
          help: 'Zooming and scaling should not be disabled'
        },
        'nested-interactive': {
          description: 'Nested interactive controls are not announced by screen readers',
          help: 'Ensure interactive controls are not nested'
        },
        'no-autoplay-audio': {
          description: 'Ensures <video> or <audio> elements do not autoplay audio for more than 3 seconds without a control mechanism to stop or mute the audio',
          help: '<video> or <audio> elements do not autoplay audio'
        },
        'object-alt': {
          description: 'Ensures <object> elements have alternate text',
          help: '<object> elements must have alternate text'
        },
        'p-as-heading': {
          description: 'Ensure p elements are not used to style headings',
          help: 'Bold, italic text and font-size are not used to style p elements as a heading'
        },
        'page-has-heading-one': {
          description: 'Ensure that the page, or at least one of its frames contains a level-one heading',
          help: 'Page should contain a level-one heading'
        },
        'presentation-role-conflict': {
          description: 'Flags elements whose role is none or presentation and which cause the role conflict resolution to trigger.',
          help: 'Elements of role none or presentation should be flagged'
        },
        region: {
          description: 'Ensures all page content is contained by landmarks',
          help: 'All page content should be contained by landmarks'
        },
        'role-img-alt': {
          description: 'Ensures [role=\'img\'] elements have alternate text',
          help: '[role=\'img\'] elements have an alternative text'
        },
        'scope-attr-valid': {
          description: 'Ensures the scope attribute is used correctly on tables',
          help: 'scope attribute should be used correctly'
        },
        'scrollable-region-focusable': {
          description: 'Elements that have scrollable content must be accessible by keyboard',
          help: 'Ensure that scrollable region has keyboard access'
        },
        'select-name': {
          description: 'Ensures select element has an accessible name',
          help: 'Select element must have an accessible name'
        },
        'server-side-image-map': {
          description: 'Ensures that server-side image maps are not used',
          help: 'Server-side image maps must not be used'
        },
        'skip-link': {
          description: 'Ensure all skip links have a focusable target',
          help: 'The skip-link target should exist and be focusable'
        },
        'svg-img-alt': {
          description: 'Ensures svg elements with an img, graphics-document or graphics-symbol role have an accessible text',
          help: 'svg elements with an img role have an alternative text'
        },
        tabindex: {
          description: 'Ensures tabindex attribute values are not greater than 0',
          help: 'Elements should not have tabindex greater than zero'
        },
        'table-duplicate-name': {
          description: 'Ensure that tables do not have the same summary and caption',
          help: 'The <caption> element should not contain the same text as the summary attribute'
        },
        'table-fake-caption': {
          description: 'Ensure that tables with a caption use the <caption> element.',
          help: 'Data or header cells must not be used to give caption to a data table.'
        },
        'td-has-header': {
          description: 'Ensure that each non-empty data cell in a large table has one or more table headers',
          help: 'All non-empty td element in table larger than 3 by 3 must have an associated table header'
        },
        'td-headers-attr': {
          description: 'Ensure that each cell in a table using the headers refers to another cell in that table',
          help: 'All cells in a table element that use the headers attribute must only refer to other cells of that same table'
        },
        'th-has-data-cells': {
          description: 'Ensure that each table header in a data table refers to data cells',
          help: 'All th elements and elements with role=columnheader/rowheader must have data cells they describe'
        },
        'valid-lang': {
          description: 'Ensures lang attributes have valid values',
          help: 'lang attribute must have a valid value'
        },
        'video-caption': {
          description: 'Ensures <video> elements have captions',
          help: '<video> elements must have captions'
        }
      },
      checks: {
        abstractrole: {
          impact: 'serious',
          messages: {
            pass: 'Abstract roles are not used',
            fail: {
              singular: 'Abstract role cannot be directly used: ${data.values}',
              plural: 'Abstract roles cannot be directly used: ${data.values}'
            }
          }
        },
        'aria-allowed-attr': {
          impact: 'critical',
          messages: {
            pass: 'ARIA attributes are used correctly for the defined role',
            fail: {
              singular: 'ARIA attribute is not allowed: ${data.values}',
              plural: 'ARIA attributes are not allowed: ${data.values}'
            }
          }
        },
        'aria-allowed-role': {
          impact: 'minor',
          messages: {
            pass: 'ARIA role is allowed for given element',
            fail: {
              singular: 'ARIA role ${data.values} is not allowed for given element',
              plural: 'ARIA roles ${data.values} are not allowed for given element'
            },
            incomplete: {
              singular: 'ARIA role ${data.values} must be removed when the element is made visible, as it is not allowed for the element',
              plural: 'ARIA roles ${data.values} must be removed when the element is made visible, as they are not allowed for the element'
            }
          }
        },
        'aria-errormessage': {
          impact: 'critical',
          messages: {
            pass: 'aria-errormessage exists and references elements visible to screen readers that use a supported aria-errormessage technique',
            fail: {
              singular: 'aria-errormessage value `${data.values}` must use a technique to announce the message (e.g., aria-live, aria-describedby, role=alert, etc.)',
              plural: 'aria-errormessage values `${data.values}` must use a technique to announce the message (e.g., aria-live, aria-describedby, role=alert, etc.)'
            },
            incomplete: {
              singular: 'ensure aria-errormessage value `${data.values}` references an existing element',
              plural: 'ensure aria-errormessage values `${data.values}` reference existing elements'
            }
          }
        },
        'aria-hidden-body': {
          impact: 'critical',
          messages: {
            pass: 'No aria-hidden attribute is present on document body',
            fail: 'aria-hidden=true should not be present on the document body'
          }
        },
        'aria-prohibited-attr': {
          impact: 'critical',
          messages: {
            pass: 'ARIA attribute is allowed',
            fail: 'ARIA attribute cannot be used: ${data.values}',
            incomplete: 'ARIA attribute is not well supported on the element and the text content will be used instead: ${data.values}'
          }
        },
        'aria-required-attr': {
          impact: 'critical',
          messages: {
            pass: 'All required ARIA attributes are present',
            fail: {
              singular: 'Required ARIA attribute not present: ${data.values}',
              plural: 'Required ARIA attributes not present: ${data.values}'
            }
          }
        },
        'aria-required-children': {
          impact: 'critical',
          messages: {
            pass: 'Required ARIA children are present',
            fail: {
              singular: 'Required ARIA child role not present: ${data.values}',
              plural: 'Required ARIA children role not present: ${data.values}'
            },
            incomplete: {
              singular: 'Expecting ARIA child role to be added: ${data.values}',
              plural: 'Expecting ARIA children role to be added: ${data.values}'
            }
          }
        },
        'aria-required-parent': {
          impact: 'critical',
          messages: {
            pass: 'Required ARIA parent role present',
            fail: {
              singular: 'Required ARIA parent role not present: ${data.values}',
              plural: 'Required ARIA parents role not present: ${data.values}'
            }
          }
        },
        'aria-roledescription': {
          impact: 'serious',
          messages: {
            pass: 'aria-roledescription used on a supported semantic role',
            incomplete: 'Check that the aria-roledescription is announced by supported screen readers',
            fail: 'Give the element a role that supports aria-roledescription'
          }
        },
        'aria-unsupported-attr': {
          impact: 'critical',
          messages: {
            pass: 'ARIA attribute is supported',
            fail: 'ARIA attribute is not widely supported in screen readers and assistive technologies: ${data.values}'
          }
        },
        'aria-valid-attr-value': {
          impact: 'critical',
          messages: {
            pass: 'ARIA attribute values are valid',
            fail: {
              singular: 'Invalid ARIA attribute value: ${data.values}',
              plural: 'Invalid ARIA attribute values: ${data.values}'
            },
            incomplete: {
              noId: 'ARIA attribute element ID does not exist on the page: ${data.needsReview}',
              ariaCurrent: 'ARIA attribute value is invalid and will be treated as "aria-current=true": ${data.needsReview}'
            }
          }
        },
        'aria-valid-attr': {
          impact: 'critical',
          messages: {
            pass: 'ARIA attribute name is valid',
            fail: {
              singular: 'Invalid ARIA attribute name: ${data.values}',
              plural: 'Invalid ARIA attribute names: ${data.values}'
            }
          }
        },
        fallbackrole: {
          impact: 'serious',
          messages: {
            pass: 'Only one role value used',
            fail: 'Use only one role value, since fallback roles are not supported in older browsers'
          }
        },
        'has-global-aria-attribute': {
          impact: 'minor',
          messages: {
            pass: {
              singular: 'Element has global ARIA attribute: ${data.values}',
              plural: 'Element has global ARIA attributes: ${data.values}'
            },
            fail: 'Element does not have global ARIA attribute'
          }
        },
        'has-widget-role': {
          impact: 'minor',
          messages: {
            pass: 'Element has a widget role.',
            fail: 'Element does not have a widget role.'
          }
        },
        invalidrole: {
          impact: 'critical',
          messages: {
            pass: 'ARIA role is valid',
            fail: {
              singular: 'Role must be one of the valid ARIA roles: ${data.values}',
              plural: 'Roles must be one of the valid ARIA roles: ${data.values}'
            }
          }
        },
        'is-element-focusable': {
          impact: 'minor',
          messages: {
            pass: 'Element is focusable.',
            fail: 'Element is not focusable.'
          }
        },
        'no-implicit-explicit-label': {
          impact: 'moderate',
          messages: {
            pass: 'There is no mismatch between a <label> and accessible name',
            incomplete: 'Check that the <label> does not need be part of the ARIA ${data} field\'s name'
          }
        },
        unsupportedrole: {
          impact: 'critical',
          messages: {
            pass: 'ARIA role is supported',
            fail: 'The role used is not widely supported in screen readers and assistive technologies: ${data.values}'
          }
        },
        'valid-scrollable-semantics': {
          impact: 'minor',
          messages: {
            pass: 'Element has valid semantics for an element in the focus order.',
            fail: 'Element has invalid semantics for an element in the focus order.'
          }
        },
        'color-contrast': {
          impact: 'serious',
          messages: {
            pass: 'Element has sufficient color contrast of ${data.contrastRatio}',
            fail: 'Element has insufficient color contrast of ${data.contrastRatio} (foreground color: ${data.fgColor}, background color: ${data.bgColor}, font size: ${data.fontSize}, font weight: ${data.fontWeight}). Expected contrast ratio of ${data.expectedContrastRatio}',
            incomplete: {
              default: 'Unable to determine contrast ratio',
              bgImage: 'Element\'s background color could not be determined due to a background image',
              bgGradient: 'Element\'s background color could not be determined due to a background gradient',
              imgNode: 'Element\'s background color could not be determined because element contains an image node',
              bgOverlap: 'Element\'s background color could not be determined because it is overlapped by another element',
              fgAlpha: 'Element\'s foreground color could not be determined because of alpha transparency',
              elmPartiallyObscured: 'Element\'s background color could not be determined because it\'s partially obscured by another element',
              elmPartiallyObscuring: 'Element\'s background color could not be determined because it partially overlaps other elements',
              outsideViewport: 'Element\'s background color could not be determined because it\'s outside the viewport',
              equalRatio: 'Element has a 1:1 contrast ratio with the background',
              shortTextContent: 'Element content is too short to determine if it is actual text content',
              nonBmp: 'Element content contains only non-text characters',
              pseudoContent: 'Element\'s background color could not be determined due to a pseudo element'
            }
          }
        },
        'link-in-text-block': {
          impact: 'serious',
          messages: {
            pass: 'Links can be distinguished from surrounding text in some way other than by color',
            fail: 'Links need to be distinguished from surrounding text in some way other than by color',
            incomplete: {
              default: 'Unable to determine contrast ratio',
              bgContrast: 'Element\'s contrast ratio could not be determined. Check for a distinct hover/focus style',
              bgImage: 'Element\'s contrast ratio could not be determined due to a background image',
              bgGradient: 'Element\'s contrast ratio could not be determined due to a background gradient',
              imgNode: 'Element\'s contrast ratio could not be determined because element contains an image node',
              bgOverlap: 'Element\'s contrast ratio could not be determined because of element overlap'
            }
          }
        },
        'autocomplete-appropriate': {
          impact: 'serious',
          messages: {
            pass: 'the autocomplete value is on an appropriate element',
            fail: 'the autocomplete value is inappropriate for this type of input'
          }
        },
        'autocomplete-valid': {
          impact: 'serious',
          messages: {
            pass: 'the autocomplete attribute is correctly formatted',
            fail: 'the autocomplete attribute is incorrectly formatted'
          }
        },
        accesskeys: {
          impact: 'serious',
          messages: {
            pass: 'Accesskey attribute value is unique',
            fail: 'Document has multiple elements with the same accesskey'
          }
        },
        'focusable-content': {
          impact: 'moderate',
          messages: {
            pass: 'Element contains focusable elements',
            fail: 'Element should have focusable content'
          }
        },
        'focusable-disabled': {
          impact: 'serious',
          messages: {
            pass: 'No focusable elements contained within element',
            fail: 'Focusable content should be disabled or be removed from the DOM'
          }
        },
        'focusable-element': {
          impact: 'moderate',
          messages: {
            pass: 'Element is focusable',
            fail: 'Element should be focusable'
          }
        },
        'focusable-modal-open': {
          impact: 'serious',
          messages: {
            pass: 'No focusable elements while a modal is open',
            incomplete: 'Check that focusable elements are not tabbable in the current state'
          }
        },
        'focusable-no-name': {
          impact: 'serious',
          messages: {
            pass: 'Element is not in tab order or has accessible text',
            fail: 'Element is in tab order and does not have accessible text',
            incomplete: 'Unable to determine if element has an accessible name'
          }
        },
        'focusable-not-tabbable': {
          impact: 'serious',
          messages: {
            pass: 'No focusable elements contained within element',
            fail: 'Focusable content should have tabindex=\'-1\' or be removed from the DOM'
          }
        },
        'frame-focusable-content': {
          impact: 'serious',
          messages: {
            pass: 'Element does not have focusable descendants',
            fail: 'Element has focusable descendants',
            incomplete: 'Could not determine if element has descendants'
          }
        },
        'landmark-is-top-level': {
          impact: 'moderate',
          messages: {
            pass: 'The ${data.role} landmark is at the top level.',
            fail: 'The ${data.role} landmark is contained in another landmark.'
          }
        },
        'no-focusable-content': {
          impact: 'serious',
          messages: {
            pass: 'Element does not have focusable descendants',
            fail: 'Element has focusable descendants',
            incomplete: 'Could not determine if element has descendants'
          }
        },
        'page-has-heading-one': {
          impact: 'moderate',
          messages: {
            pass: 'Page has at least one level-one heading',
            fail: 'Page must have a level-one heading'
          }
        },
        'page-has-main': {
          impact: 'moderate',
          messages: {
            pass: 'Document has at least one main landmark',
            fail: 'Document does not have a main landmark'
          }
        },
        'page-no-duplicate-banner': {
          impact: 'moderate',
          messages: {
            pass: 'Document does not have more than one banner landmark',
            fail: 'Document has more than one banner landmark'
          }
        },
        'page-no-duplicate-contentinfo': {
          impact: 'moderate',
          messages: {
            pass: 'Document does not have more than one contentinfo landmark',
            fail: 'Document has more than one contentinfo landmark'
          }
        },
        'page-no-duplicate-main': {
          impact: 'moderate',
          messages: {
            pass: 'Document does not have more than one main landmark',
            fail: 'Document has more than one main landmark'
          }
        },
        tabindex: {
          impact: 'serious',
          messages: {
            pass: 'Element does not have a tabindex greater than 0',
            fail: 'Element has a tabindex greater than 0'
          }
        },
        'alt-space-value': {
          impact: 'critical',
          messages: {
            pass: 'Element has a valid alt attribute value',
            fail: 'Element has an alt attribute containing only a space character, which is not ignored by all screen readers'
          }
        },
        'duplicate-img-label': {
          impact: 'minor',
          messages: {
            pass: 'Element does not duplicate existing text in <img> alt text',
            fail: 'Element contains <img> element with alt text that duplicates existing text'
          }
        },
        'explicit-label': {
          impact: 'critical',
          messages: {
            pass: 'Form element has an explicit <label>',
            fail: 'Form element does not have an explicit <label>',
            incomplete: 'Unable to determine if form element has an explicit <label>'
          }
        },
        'help-same-as-label': {
          impact: 'minor',
          messages: {
            pass: 'Help text (title or aria-describedby) does not duplicate label text',
            fail: 'Help text (title or aria-describedby) text is the same as the label text'
          }
        },
        'hidden-explicit-label': {
          impact: 'critical',
          messages: {
            pass: 'Form element has a visible explicit <label>',
            fail: 'Form element has explicit <label> that is hidden',
            incomplete: 'Unable to determine if form element has explicit <label> that is hidden'
          }
        },
        'implicit-label': {
          impact: 'critical',
          messages: {
            pass: 'Form element has an implicit (wrapped) <label>',
            fail: 'Form element does not have an implicit (wrapped) <label>',
            incomplete: 'Unable to determine if form element has an implicit (wrapped} <label>'
          }
        },
        'label-content-name-mismatch': {
          impact: 'serious',
          messages: {
            pass: 'Element contains visible text as part of it\'s accessible name',
            fail: 'Text inside the element is not included in the accessible name'
          }
        },
        'multiple-label': {
          impact: 'moderate',
          messages: {
            pass: 'Form field does not have multiple label elements',
            incomplete: 'Multiple label elements is not widely supported in assistive technologies. Ensure the first label contains all necessary information.'
          }
        },
        'title-only': {
          impact: 'serious',
          messages: {
            pass: 'Form element does not solely use title attribute for its label',
            fail: 'Only title used to generate label for form element'
          }
        },
        'landmark-is-unique': {
          impact: 'moderate',
          messages: {
            pass: 'Landmarks must have a unique role or role/label/title (i.e. accessible name) combination',
            fail: 'The landmark must have a unique aria-label, aria-labelledby, or title to make landmarks distinguishable'
          }
        },
        'has-lang': {
          impact: 'serious',
          messages: {
            pass: 'The <html> element has a lang attribute',
            fail: {
              noXHTML: 'The xml:lang attribute is not valid on HTML pages, use the lang attribute.',
              noLang: 'The <html> element does not have a lang attribute'
            }
          }
        },
        'valid-lang': {
          impact: 'serious',
          messages: {
            pass: 'Value of lang attribute is included in the list of valid languages',
            fail: 'Value of lang attribute not included in the list of valid languages'
          }
        },
        'xml-lang-mismatch': {
          impact: 'moderate',
          messages: {
            pass: 'Lang and xml:lang attributes have the same base language',
            fail: 'Lang and xml:lang attributes do not have the same base language'
          }
        },
        dlitem: {
          impact: 'serious',
          messages: {
            pass: 'Description list item has a <dl> parent element',
            fail: 'Description list item does not have a <dl> parent element'
          }
        },
        listitem: {
          impact: 'serious',
          messages: {
            pass: 'List item has a <ul>, <ol> or role="list" parent element',
            fail: {
              default: 'List item does not have a <ul>, <ol> parent element',
              roleNotValid: 'List item does not have a <ul>, <ol> parent element without a role, or a role="list"'
            }
          }
        },
        'only-dlitems': {
          impact: 'serious',
          messages: {
            pass: 'List element only has direct children that are allowed inside <dt> or <dd> elements',
            fail: 'List element has direct children that are not allowed inside <dt> or <dd> elements'
          }
        },
        'only-listitems': {
          impact: 'serious',
          messages: {
            pass: 'List element only has direct children that are allowed inside <li> elements',
            fail: {
              default: 'List element has direct children that are not allowed inside <li> elements',
              roleNotValid: 'List element has direct children with a role that is not allowed: ${data.roles}'
            }
          }
        },
        'structured-dlitems': {
          impact: 'serious',
          messages: {
            pass: 'When not empty, element has both <dt> and <dd> elements',
            fail: 'When not empty, element does not have at least one <dt> element followed by at least one <dd> element'
          }
        },
        caption: {
          impact: 'critical',
          messages: {
            pass: 'The multimedia element has a captions track',
            incomplete: 'Check that captions is available for the element'
          }
        },
        'frame-tested': {
          impact: 'critical',
          messages: {
            pass: 'The iframe was tested with axe-core',
            fail: 'The iframe could not be tested with axe-core',
            incomplete: 'The iframe still has to be tested with axe-core'
          }
        },
        'no-autoplay-audio': {
          impact: 'moderate',
          messages: {
            pass: '<video> or <audio> does not output audio for more than allowed duration or has controls mechanism',
            fail: '<video> or <audio> outputs audio for more than allowed duration and does not have a controls mechanism',
            incomplete: 'Check that the <video> or <audio> does not output audio for more than allowed duration or provides a controls mechanism'
          }
        },
        'css-orientation-lock': {
          impact: 'serious',
          messages: {
            pass: 'Display is operable, and orientation lock does not exist',
            fail: 'CSS Orientation lock is applied, and makes display inoperable',
            incomplete: 'CSS Orientation lock cannot be determined'
          }
        },
        'meta-viewport-large': {
          impact: 'minor',
          messages: {
            pass: '<meta> tag does not prevent significant zooming on mobile devices',
            fail: '<meta> tag limits zooming on mobile devices'
          }
        },
        'meta-viewport': {
          impact: 'critical',
          messages: {
            pass: '<meta> tag does not disable zooming on mobile devices',
            fail: '${data} on <meta> tag disables zooming on mobile devices'
          }
        },
        'header-present': {
          impact: 'serious',
          messages: {
            pass: 'Page has a heading',
            fail: 'Page does not have a heading'
          }
        },
        'heading-order': {
          impact: 'moderate',
          messages: {
            pass: 'Heading order valid',
            fail: 'Heading order invalid'
          }
        },
        'identical-links-same-purpose': {
          impact: 'minor',
          messages: {
            pass: 'There are no other links with the same name, that go to a different URL',
            incomplete: 'Check that links have the same purpose, or are intentionally ambiguous.'
          }
        },
        'internal-link-present': {
          impact: 'serious',
          messages: {
            pass: 'Valid skip link found',
            fail: 'No valid skip link found'
          }
        },
        landmark: {
          impact: 'serious',
          messages: {
            pass: 'Page has a landmark region',
            fail: 'Page does not have a landmark region'
          }
        },
        'meta-refresh': {
          impact: 'critical',
          messages: {
            pass: '<meta> tag does not immediately refresh the page',
            fail: '<meta> tag forces timed refresh of page'
          }
        },
        'p-as-heading': {
          impact: 'serious',
          messages: {
            pass: '<p> elements are not styled as headings',
            fail: 'Heading elements should be used instead of styled p elements'
          }
        },
        region: {
          impact: 'moderate',
          messages: {
            pass: 'All page content is contained by landmarks',
            fail: 'Some page content is not contained by landmarks'
          }
        },
        'skip-link': {
          impact: 'moderate',
          messages: {
            pass: 'Skip link target exists',
            incomplete: 'Skip link target should become visible on activation',
            fail: 'No skip link target'
          }
        },
        'unique-frame-title': {
          impact: 'serious',
          messages: {
            pass: 'Element\'s title attribute is unique',
            fail: 'Element\'s title attribute is not unique'
          }
        },
        'duplicate-id-active': {
          impact: 'serious',
          messages: {
            pass: 'Document has no active elements that share the same id attribute',
            fail: 'Document has active elements with the same id attribute: ${data}'
          }
        },
        'duplicate-id-aria': {
          impact: 'critical',
          messages: {
            pass: 'Document has no elements referenced with ARIA or labels that share the same id attribute',
            fail: 'Document has multiple elements referenced with ARIA with the same id attribute: ${data}'
          }
        },
        'duplicate-id': {
          impact: 'minor',
          messages: {
            pass: 'Document has no static elements that share the same id attribute',
            fail: 'Document has multiple static elements with the same id attribute: ${data}'
          }
        },
        'aria-label': {
          impact: 'serious',
          messages: {
            pass: 'aria-label attribute exists and is not empty',
            fail: 'aria-label attribute does not exist or is empty'
          }
        },
        'aria-labelledby': {
          impact: 'serious',
          messages: {
            pass: 'aria-labelledby attribute exists and references elements that are visible to screen readers',
            fail: 'aria-labelledby attribute does not exist, references elements that do not exist or references elements that are empty',
            incomplete: 'ensure aria-labelledby references an existing element'
          }
        },
        'avoid-inline-spacing': {
          impact: 'serious',
          messages: {
            pass: 'No inline styles with \'!important\' that affect text spacing has been specified',
            fail: {
              singular: 'Remove \'!important\' from inline style ${data.values}, as overriding this is not supported by most browsers',
              plural: 'Remove \'!important\' from inline styles ${data.values}, as overriding this is not supported by most browsers'
            }
          }
        },
        'button-has-visible-text': {
          impact: 'critical',
          messages: {
            pass: 'Element has inner text that is visible to screen readers',
            fail: 'Element does not have inner text that is visible to screen readers',
            incomplete: 'Unable to determine if element has children'
          }
        },
        'doc-has-title': {
          impact: 'serious',
          messages: {
            pass: 'Document has a non-empty <title> element',
            fail: 'Document does not have a non-empty <title> element'
          }
        },
        exists: {
          impact: 'minor',
          messages: {
            pass: 'Element does not exist',
            incomplete: 'Element exists'
          }
        },
        'has-alt': {
          impact: 'critical',
          messages: {
            pass: 'Element has an alt attribute',
            fail: 'Element does not have an alt attribute'
          }
        },
        'has-visible-text': {
          impact: 'minor',
          messages: {
            pass: 'Element has text that is visible to screen readers',
            fail: 'Element does not have text that is visible to screen readers',
            incomplete: 'Unable to determine if element has children'
          }
        },
        'is-on-screen': {
          impact: 'serious',
          messages: {
            pass: 'Element is not visible',
            fail: 'Element is visible'
          }
        },
        'non-empty-alt': {
          impact: 'critical',
          messages: {
            pass: 'Element has a non-empty alt attribute',
            fail: {
              noAttr: 'Element has no alt attribute',
              emptyAttr: 'Element has an empty alt attribute'
            }
          }
        },
        'non-empty-if-present': {
          impact: 'critical',
          messages: {
            pass: {
              default: 'Element does not have a value attribute',
              'has-label': 'Element has a non-empty value attribute'
            },
            fail: 'Element has a value attribute and the value attribute is empty'
          }
        },
        'non-empty-placeholder': {
          impact: 'serious',
          messages: {
            pass: 'Element has a placeholder attribute',
            fail: {
              noAttr: 'Element has no placeholder attribute',
              emptyAttr: 'Element has an empty placeholder attribute'
            }
          }
        },
        'non-empty-title': {
          impact: 'serious',
          messages: {
            pass: 'Element has a title attribute',
            fail: {
              noAttr: 'Element has no title attribute',
              emptyAttr: 'Element has an empty title attribute'
            }
          }
        },
        'non-empty-value': {
          impact: 'critical',
          messages: {
            pass: 'Element has a non-empty value attribute',
            fail: {
              noAttr: 'Element has no value attribute',
              emptyAttr: 'Element has an empty value attribute'
            }
          }
        },
        'presentational-role': {
          impact: 'minor',
          messages: {
            pass: 'Element\'s default semantics were overriden with role="${data.role}"',
            fail: {
              default: 'Element\'s default semantics were not overridden with role="none" or role="presentation"',
              globalAria: 'Element\'s role is not presentational because it has a global ARIA attribute',
              focusable: 'Element\'s role is not presentational because it is focusable',
              both: 'Element\'s role is not presentational because it has a global ARIA attribute and is focusable'
            }
          }
        },
        'role-none': {
          impact: 'minor',
          messages: {
            pass: 'Element\'s default semantics were overriden with role="none"',
            fail: 'Element\'s default semantics were not overridden with role="none"'
          }
        },
        'role-presentation': {
          impact: 'minor',
          messages: {
            pass: 'Element\'s default semantics were overriden with role="presentation"',
            fail: 'Element\'s default semantics were not overridden with role="presentation"'
          }
        },
        'svg-non-empty-title': {
          impact: 'serious',
          messages: {
            pass: 'Element has a child that is a title',
            fail: {
              noTitle: 'Element has no child that is a title',
              emptyTitle: 'Element child title is empty'
            },
            incomplete: 'Unable to determine element has a child that is a title'
          }
        },
        'caption-faked': {
          impact: 'serious',
          messages: {
            pass: 'The first row of a table is not used as a caption',
            fail: 'The first child of the table should be a caption instead of a table cell'
          }
        },
        'html5-scope': {
          impact: 'moderate',
          messages: {
            pass: 'Scope attribute is only used on table header elements (<th>)',
            fail: 'In HTML 5, scope attributes may only be used on table header elements (<th>)'
          }
        },
        'same-caption-summary': {
          impact: 'minor',
          messages: {
            pass: 'Content of summary attribute and <caption> are not duplicated',
            fail: 'Content of summary attribute and <caption> element are identical'
          }
        },
        'scope-value': {
          impact: 'critical',
          messages: {
            pass: 'Scope attribute is used correctly',
            fail: 'The value of the scope attribute may only be \'row\' or \'col\''
          }
        },
        'td-has-header': {
          impact: 'critical',
          messages: {
            pass: 'All non-empty data cells have table headers',
            fail: 'Some non-empty data cells do not have table headers'
          }
        },
        'td-headers-attr': {
          impact: 'serious',
          messages: {
            pass: 'The headers attribute is exclusively used to refer to other cells in the table',
            incomplete: 'The headers attribute is empty',
            fail: 'The headers attribute is not exclusively used to refer to other cells in the table'
          }
        },
        'th-has-data-cells': {
          impact: 'serious',
          messages: {
            pass: 'All table header cells refer to data cells',
            fail: 'Not all table header cells refer to data cells',
            incomplete: 'Table data cells are missing or empty'
          }
        },
        'hidden-content': {
          impact: 'minor',
          messages: {
            pass: 'All content on the page has been analyzed.',
            fail: 'There were problems analyzing the content on this page.',
            incomplete: 'There is hidden content on the page that was not analyzed. You will need to trigger the display of this content in order to analyze it.'
          }
        }
      },
      failureSummaries: {
        any: {
          failureMessage: function anonymous(it) {
            var out = 'Fix any of the following:';
            var arr1 = it;
            if (arr1) {
              var value, i1 = -1, l1 = arr1.length - 1;
              while (i1 < l1) {
                value = arr1[i1 += 1];
                out += '\n  ' + value.split('\n').join('\n  ');
              }
            }
            return out;
          }
        },
        none: {
          failureMessage: function anonymous(it) {
            var out = 'Fix all of the following:';
            var arr1 = it;
            if (arr1) {
              var value, i1 = -1, l1 = arr1.length - 1;
              while (i1 < l1) {
                value = arr1[i1 += 1];
                out += '\n  ' + value.split('\n').join('\n  ');
              }
            }
            return out;
          }
        }
      },
      incompleteFallbackMessage: {}
    },
    rules: [ {
      id: 'accesskeys',
      selector: '[accesskey]',
      excludeHidden: false,
      tags: [ 'cat.keyboard', 'best-practice' ],
      all: [],
      any: [],
      none: [ 'accesskeys' ]
    }, {
      id: 'area-alt',
      selector: 'map area[href]',
      excludeHidden: false,
      tags: [ 'cat.text-alternatives', 'wcag2a', 'wcag111', 'wcag244', 'wcag412', 'section508', 'section508.22.a', 'ACT' ],
      all: [],
      any: [ {
        options: {
          attribute: 'alt'
        },
        id: 'non-empty-alt'
      }, 'aria-label', 'aria-labelledby', {
        options: {
          attribute: 'title'
        },
        id: 'non-empty-title'
      } ],
      none: []
    }, {
      id: 'aria-allowed-attr',
      matches: 'aria-allowed-attr-matches',
      tags: [ 'cat.aria', 'wcag2a', 'wcag412' ],
      all: [],
      any: [ 'aria-allowed-attr' ],
      none: [ 'aria-unsupported-attr', 'aria-prohibited-attr' ]
    }, {
      id: 'aria-allowed-role',
      excludeHidden: false,
      selector: '[role]',
      matches: 'aria-allowed-role-matches',
      tags: [ 'cat.aria', 'best-practice' ],
      all: [],
      any: [ {
        options: {
          allowImplicit: true,
          ignoredTags: []
        },
        id: 'aria-allowed-role'
      } ],
      none: []
    }, {
      id: 'aria-command-name',
      selector: '[role="link"], [role="button"], [role="menuitem"]',
      matches: 'no-naming-method-matches',
      tags: [ 'cat.aria', 'wcag2a', 'wcag412' ],
      all: [],
      any: [ 'has-visible-text', 'aria-label', 'aria-labelledby', {
        options: {
          attribute: 'title'
        },
        id: 'non-empty-title'
      } ],
      none: []
    }, {
      id: 'aria-dialog-name',
      selector: '[role="dialog"], [role="alertdialog"]',
      matches: 'no-naming-method-matches',
      tags: [ 'cat.aria', 'best-practice' ],
      all: [],
      any: [ 'aria-label', 'aria-labelledby', {
        options: {
          attribute: 'title'
        },
        id: 'non-empty-title'
      } ],
      none: []
    }, {
      id: 'aria-hidden-body',
      selector: 'body',
      excludeHidden: false,
      matches: 'is-initiator-matches',
      tags: [ 'cat.aria', 'wcag2a', 'wcag412' ],
      all: [],
      any: [ 'aria-hidden-body' ],
      none: []
    }, {
      id: 'aria-hidden-focus',
      selector: '[aria-hidden="true"]',
      matches: 'aria-hidden-focus-matches',
      excludeHidden: false,
      tags: [ 'cat.name-role-value', 'wcag2a', 'wcag412', 'wcag131' ],
      all: [ 'focusable-modal-open', 'focusable-disabled', 'focusable-not-tabbable' ],
      any: [],
      none: []
    }, {
      id: 'aria-input-field-name',
      selector: '[role="combobox"], [role="listbox"], [role="searchbox"], [role="slider"], [role="spinbutton"], [role="textbox"]',
      matches: 'no-naming-method-matches',
      tags: [ 'cat.aria', 'wcag2a', 'wcag412', 'ACT' ],
      all: [],
      any: [ 'aria-label', 'aria-labelledby', {
        options: {
          attribute: 'title'
        },
        id: 'non-empty-title'
      } ],
      none: [ 'no-implicit-explicit-label' ]
    }, {
      id: 'aria-meter-name',
      selector: '[role="meter"]',
      matches: 'no-naming-method-matches',
      tags: [ 'cat.aria', 'wcag2a', 'wcag111' ],
      all: [],
      any: [ 'aria-label', 'aria-labelledby', {
        options: {
          attribute: 'title'
        },
        id: 'non-empty-title'
      } ],
      none: []
    }, {
      id: 'aria-progressbar-name',
      selector: '[role="progressbar"]',
      matches: 'no-naming-method-matches',
      tags: [ 'cat.aria', 'wcag2a', 'wcag111' ],
      all: [],
      any: [ 'aria-label', 'aria-labelledby', {
        options: {
          attribute: 'title'
        },
        id: 'non-empty-title'
      } ],
      none: []
    }, {
      id: 'aria-required-attr',
      selector: '[role]',
      tags: [ 'cat.aria', 'wcag2a', 'wcag412' ],
      all: [],
      any: [ 'aria-required-attr' ],
      none: []
    }, {
      id: 'aria-required-children',
      selector: '[role]',
      matches: 'aria-required-children-matches',
      tags: [ 'cat.aria', 'wcag2a', 'wcag131' ],
      all: [],
      any: [ {
        options: {
          reviewEmpty: [ 'doc-bibliography', 'doc-endnotes', 'grid', 'list', 'listbox', 'table', 'tablist', 'tree', 'treegrid', 'rowgroup' ]
        },
        id: 'aria-required-children'
      } ],
      none: []
    }, {
      id: 'aria-required-parent',
      selector: '[role]',
      matches: 'aria-required-parent-matches',
      tags: [ 'cat.aria', 'wcag2a', 'wcag131' ],
      all: [],
      any: [ 'aria-required-parent' ],
      none: []
    }, {
      id: 'aria-roledescription',
      selector: '[aria-roledescription]',
      tags: [ 'cat.aria', 'wcag2a', 'wcag412' ],
      all: [],
      any: [ {
        options: {
          supportedRoles: [ 'button', 'img', 'checkbox', 'radio', 'combobox', 'menuitemcheckbox', 'menuitemradio' ]
        },
        id: 'aria-roledescription'
      } ],
      none: []
    }, {
      id: 'aria-roles',
      selector: '[role]',
      matches: 'no-empty-role-matches',
      tags: [ 'cat.aria', 'wcag2a', 'wcag412' ],
      all: [],
      any: [],
      none: [ 'fallbackrole', 'invalidrole', 'abstractrole', 'unsupportedrole' ]
    }, {
      id: 'aria-text',
      selector: '[role=text]',
      tags: [ 'cat.aria', 'best-practice' ],
      all: [],
      any: [ 'no-focusable-content' ],
      none: []
    }, {
      id: 'aria-toggle-field-name',
      selector: '[role="checkbox"], [role="menuitemcheckbox"], [role="menuitemradio"], [role="radio"], [role="switch"], [role="option"]',
      matches: 'no-naming-method-matches',
      tags: [ 'cat.aria', 'wcag2a', 'wcag412', 'ACT' ],
      all: [],
      any: [ 'has-visible-text', 'aria-label', 'aria-labelledby', {
        options: {
          attribute: 'title'
        },
        id: 'non-empty-title'
      } ],
      none: [ 'no-implicit-explicit-label' ]
    }, {
      id: 'aria-tooltip-name',
      selector: '[role="tooltip"]',
      matches: 'no-naming-method-matches',
      tags: [ 'cat.aria', 'wcag2a', 'wcag412' ],
      all: [],
      any: [ 'has-visible-text', 'aria-label', 'aria-labelledby', {
        options: {
          attribute: 'title'
        },
        id: 'non-empty-title'
      } ],
      none: []
    }, {
      id: 'aria-treeitem-name',
      selector: '[role="treeitem"]',
      matches: 'no-naming-method-matches',
      tags: [ 'cat.aria', 'best-practice' ],
      all: [],
      any: [ 'has-visible-text', 'aria-label', 'aria-labelledby', {
        options: {
          attribute: 'title'
        },
        id: 'non-empty-title'
      } ],
      none: []
    }, {
      id: 'aria-valid-attr-value',
      matches: 'aria-has-attr-matches',
      tags: [ 'cat.aria', 'wcag2a', 'wcag412' ],
      all: [ {
        options: [],
        id: 'aria-valid-attr-value'
      }, 'aria-errormessage' ],
      any: [],
      none: []
    }, {
      id: 'aria-valid-attr',
      matches: 'aria-has-attr-matches',
      tags: [ 'cat.aria', 'wcag2a', 'wcag412' ],
      all: [],
      any: [ {
        options: [],
        id: 'aria-valid-attr'
      } ],
      none: []
    }, {
      id: 'audio-caption',
      selector: 'audio',
      enabled: false,
      excludeHidden: false,
      tags: [ 'cat.time-and-media', 'wcag2a', 'wcag121', 'section508', 'section508.22.a' ],
      all: [],
      any: [],
      none: [ 'caption' ]
    }, {
      id: 'autocomplete-valid',
      matches: 'autocomplete-matches',
      tags: [ 'cat.forms', 'wcag21aa', 'wcag135' ],
      all: [ 'autocomplete-valid', 'autocomplete-appropriate' ],
      any: [],
      none: []
    }, {
      id: 'avoid-inline-spacing',
      selector: '[style]',
      tags: [ 'cat.structure', 'wcag21aa', 'wcag1412' ],
      all: [ {
        options: {
          cssProperties: [ 'line-height', 'letter-spacing', 'word-spacing' ]
        },
        id: 'avoid-inline-spacing'
      } ],
      any: [],
      none: []
    }, {
      id: 'blink',
      selector: 'blink',
      excludeHidden: false,
      tags: [ 'cat.time-and-media', 'wcag2a', 'wcag222', 'section508', 'section508.22.j' ],
      all: [],
      any: [],
      none: [ 'is-on-screen' ]
    }, {
      id: 'button-name',
      selector: 'button',
      matches: 'no-explicit-name-required-matches',
      tags: [ 'cat.name-role-value', 'wcag2a', 'wcag412', 'section508', 'section508.22.a', 'ACT' ],
      all: [],
      any: [ 'button-has-visible-text', 'aria-label', 'aria-labelledby', {
        options: {
          attribute: 'title'
        },
        id: 'non-empty-title'
      }, 'presentational-role' ],
      none: []
    }, {
      id: 'bypass',
      selector: 'html',
      pageLevel: true,
      matches: 'bypass-matches',
      reviewOnFail: true,
      tags: [ 'cat.keyboard', 'wcag2a', 'wcag241', 'section508', 'section508.22.o' ],
      all: [],
      any: [ 'internal-link-present', {
        options: {
          selector: ':is(h1, h2, h3, h4, h5, h6):not([role]), [role=heading]'
        },
        id: 'header-present'
      }, {
        options: {
          selector: 'main, [role=main]'
        },
        id: 'landmark'
      } ],
      none: []
    }, {
      id: 'color-contrast',
      matches: 'color-contrast-matches',
      excludeHidden: false,
      tags: [ 'cat.color', 'wcag2aa', 'wcag143' ],
      all: [],
      any: [ {
        options: {
          ignoreUnicode: true,
          ignoreLength: false,
          boldValue: 700,
          boldTextPt: 14,
          largeTextPt: 18,
          contrastRatio: {
            normal: {
              expected: 4.5
            },
            large: {
              expected: 3
            }
          },
          shadowOutlineEmMax: .1
        },
        id: 'color-contrast'
      } ],
      none: []
    }, {
      id: 'css-orientation-lock',
      selector: 'html',
      tags: [ 'cat.structure', 'wcag134', 'wcag21aa', 'experimental' ],
      all: [ {
        options: {
          degreeThreshold: 2
        },
        id: 'css-orientation-lock'
      } ],
      any: [],
      none: [],
      preload: true
    }, {
      id: 'definition-list',
      selector: 'dl',
      matches: 'no-role-matches',
      tags: [ 'cat.structure', 'wcag2a', 'wcag131' ],
      all: [],
      any: [],
      none: [ 'structured-dlitems', 'only-dlitems' ]
    }, {
      id: 'dlitem',
      selector: 'dd, dt',
      matches: 'no-role-matches',
      tags: [ 'cat.structure', 'wcag2a', 'wcag131' ],
      all: [],
      any: [ 'dlitem' ],
      none: []
    }, {
      id: 'document-title',
      selector: 'html',
      matches: 'is-initiator-matches',
      tags: [ 'cat.text-alternatives', 'wcag2a', 'wcag242', 'ACT' ],
      all: [],
      any: [ 'doc-has-title' ],
      none: []
    }, {
      id: 'duplicate-id-active',
      selector: '[id]',
      matches: 'duplicate-id-active-matches',
      excludeHidden: false,
      tags: [ 'cat.parsing', 'wcag2a', 'wcag411' ],
      all: [],
      any: [ 'duplicate-id-active' ],
      none: []
    }, {
      id: 'duplicate-id-aria',
      selector: '[id]',
      matches: 'duplicate-id-aria-matches',
      excludeHidden: false,
      tags: [ 'cat.parsing', 'wcag2a', 'wcag411' ],
      all: [],
      any: [ 'duplicate-id-aria' ],
      none: []
    }, {
      id: 'duplicate-id',
      selector: '[id]',
      matches: 'duplicate-id-misc-matches',
      excludeHidden: false,
      tags: [ 'cat.parsing', 'wcag2a', 'wcag411' ],
      all: [],
      any: [ 'duplicate-id' ],
      none: []
    }, {
      id: 'empty-heading',
      selector: 'h1, h2, h3, h4, h5, h6, [role="heading"]',
      matches: 'heading-matches',
      tags: [ 'cat.name-role-value', 'best-practice' ],
      impact: 'minor',
      all: [],
      any: [ 'has-visible-text', 'aria-label', 'aria-labelledby', {
        options: {
          attribute: 'title'
        },
        id: 'non-empty-title'
      } ],
      none: []
    }, {
      id: 'empty-table-header',
      selector: 'th, [role="rowheader"], [role="columnheader"]',
      tags: [ 'wcag131', 'cat.aria' ],
      reviewOnFail: true,
      all: [],
      any: [ 'has-visible-text' ],
      none: []
    }, {
      id: 'focus-order-semantics',
      selector: 'div, h1, h2, h3, h4, h5, h6, [role=heading], p, span',
      matches: 'inserted-into-focus-order-matches',
      tags: [ 'cat.keyboard', 'best-practice', 'experimental' ],
      all: [],
      any: [ {
        options: [],
        id: 'has-widget-role'
      }, {
        options: {
          roles: [ 'tooltip' ]
        },
        id: 'valid-scrollable-semantics'
      } ],
      none: []
    }, {
      id: 'form-field-multiple-labels',
      selector: 'input, select, textarea',
      matches: 'label-matches',
      tags: [ 'cat.forms', 'wcag2a', 'wcag332' ],
      all: [],
      any: [],
      none: [ 'multiple-label' ]
    }, {
      id: 'frame-focusable-content',
      selector: 'html',
      matches: 'frame-focusable-content-matches',
      tags: [ 'cat.keyboard', 'wcag2a', 'wcag211' ],
      all: [],
      any: [ 'frame-focusable-content' ],
      none: []
    }, {
      id: 'frame-tested',
      selector: 'frame, iframe',
      tags: [ 'cat.structure', 'review-item', 'best-practice' ],
      all: [ {
        options: {
          isViolation: false
        },
        id: 'frame-tested'
      } ],
      any: [],
      none: []
    }, {
      id: 'frame-title-unique',
      selector: 'frame[title], iframe[title]',
      matches: 'frame-title-has-text-matches',
      tags: [ 'cat.text-alternatives', 'best-practice' ],
      all: [],
      any: [],
      none: [ 'unique-frame-title' ]
    }, {
      id: 'frame-title',
      selector: 'frame, iframe',
      tags: [ 'cat.text-alternatives', 'wcag2a', 'wcag241', 'wcag412', 'section508', 'section508.22.i' ],
      all: [],
      any: [ {
        options: {
          attribute: 'title'
        },
        id: 'non-empty-title'
      }, 'aria-label', 'aria-labelledby', 'presentational-role' ],
      none: []
    }, {
      id: 'heading-order',
      selector: 'h1, h2, h3, h4, h5, h6, [role=heading]',
      matches: 'heading-matches',
      tags: [ 'cat.semantics', 'best-practice' ],
      all: [],
      any: [ 'heading-order' ],
      none: []
    }, {
      id: 'hidden-content',
      selector: '*',
      excludeHidden: false,
      tags: [ 'cat.structure', 'experimental', 'review-item', 'best-practice' ],
      all: [],
      any: [ 'hidden-content' ],
      none: []
    }, {
      id: 'html-has-lang',
      selector: 'html',
      matches: 'is-initiator-matches',
      tags: [ 'cat.language', 'wcag2a', 'wcag311', 'ACT' ],
      all: [],
      any: [ {
        options: {
          attributes: [ 'lang', 'xml:lang' ]
        },
        id: 'has-lang'
      } ],
      none: []
    }, {
      id: 'html-lang-valid',
      selector: 'html[lang], html[xml\\:lang]',
      tags: [ 'cat.language', 'wcag2a', 'wcag311', 'ACT' ],
      all: [],
      any: [],
      none: [ {
        options: {
          attributes: [ 'lang', 'xml:lang' ]
        },
        id: 'valid-lang'
      } ]
    }, {
      id: 'html-xml-lang-mismatch',
      selector: 'html[lang][xml\\:lang]',
      matches: 'xml-lang-mismatch-matches',
      tags: [ 'cat.language', 'wcag2a', 'wcag311', 'ACT' ],
      all: [ 'xml-lang-mismatch' ],
      any: [],
      none: []
    }, {
      id: 'identical-links-same-purpose',
      selector: 'a[href], area[href], [role="link"]',
      excludeHidden: false,
      matches: 'identical-links-same-purpose-matches',
      tags: [ 'cat.semantics', 'wcag2aaa', 'wcag249', 'best-practice' ],
      all: [ 'identical-links-same-purpose' ],
      any: [],
      none: []
    }, {
      id: 'image-alt',
      selector: 'img',
      matches: 'no-explicit-name-required-matches',
      tags: [ 'cat.text-alternatives', 'wcag2a', 'wcag111', 'section508', 'section508.22.a', 'ACT' ],
      all: [],
      any: [ 'has-alt', 'aria-label', 'aria-labelledby', {
        options: {
          attribute: 'title'
        },
        id: 'non-empty-title'
      }, 'presentational-role' ],
      none: [ 'alt-space-value' ]
    }, {
      id: 'image-redundant-alt',
      selector: 'img',
      tags: [ 'cat.text-alternatives', 'best-practice' ],
      all: [],
      any: [],
      none: [ {
        options: {
          parentSelector: 'button, [role=button], a[href], p, li, td, th'
        },
        id: 'duplicate-img-label'
      } ]
    }, {
      id: 'input-button-name',
      selector: 'input[type="button"], input[type="submit"], input[type="reset"]',
      matches: 'no-explicit-name-required-matches',
      tags: [ 'cat.name-role-value', 'wcag2a', 'wcag412', 'section508', 'section508.22.a' ],
      all: [],
      any: [ 'non-empty-if-present', {
        options: {
          attribute: 'value'
        },
        id: 'non-empty-value'
      }, 'aria-label', 'aria-labelledby', {
        options: {
          attribute: 'title'
        },
        id: 'non-empty-title'
      }, 'presentational-role' ],
      none: []
    }, {
      id: 'input-image-alt',
      selector: 'input[type="image"]',
      matches: 'no-explicit-name-required-matches',
      tags: [ 'cat.text-alternatives', 'wcag2a', 'wcag111', 'section508', 'section508.22.a', 'ACT' ],
      all: [],
      any: [ {
        options: {
          attribute: 'alt'
        },
        id: 'non-empty-alt'
      }, 'aria-label', 'aria-labelledby', {
        options: {
          attribute: 'title'
        },
        id: 'non-empty-title'
      } ],
      none: []
    }, {
      id: 'label-content-name-mismatch',
      matches: 'label-content-name-mismatch-matches',
      tags: [ 'cat.semantics', 'wcag21a', 'wcag253', 'experimental' ],
      all: [],
      any: [ {
        options: {
          pixelThreshold: .1,
          occuranceThreshold: 3
        },
        id: 'label-content-name-mismatch'
      } ],
      none: []
    }, {
      id: 'label-title-only',
      selector: 'input, select, textarea',
      matches: 'label-matches',
      tags: [ 'cat.forms', 'best-practice' ],
      all: [],
      any: [],
      none: [ 'title-only' ]
    }, {
      id: 'label',
      selector: 'input, textarea',
      matches: 'label-matches',
      tags: [ 'cat.forms', 'wcag2a', 'wcag412', 'wcag131', 'section508', 'section508.22.n', 'ACT' ],
      all: [],
      any: [ 'implicit-label', 'explicit-label', 'aria-label', 'aria-labelledby', {
        options: {
          attribute: 'title'
        },
        id: 'non-empty-title'
      }, {
        options: {
          attribute: 'placeholder'
        },
        id: 'non-empty-placeholder'
      }, 'presentational-role' ],
      none: [ 'help-same-as-label', 'hidden-explicit-label' ]
    }, {
      id: 'landmark-banner-is-top-level',
      selector: 'header:not([role]), [role=banner]',
      matches: 'landmark-has-body-context-matches',
      tags: [ 'cat.semantics', 'best-practice' ],
      all: [],
      any: [ 'landmark-is-top-level' ],
      none: []
    }, {
      id: 'landmark-complementary-is-top-level',
      selector: 'aside:not([role]), [role=complementary]',
      tags: [ 'cat.semantics', 'best-practice' ],
      all: [],
      any: [ 'landmark-is-top-level' ],
      none: []
    }, {
      id: 'landmark-contentinfo-is-top-level',
      selector: 'footer:not([role]), [role=contentinfo]',
      matches: 'landmark-has-body-context-matches',
      tags: [ 'cat.semantics', 'best-practice' ],
      all: [],
      any: [ 'landmark-is-top-level' ],
      none: []
    }, {
      id: 'landmark-main-is-top-level',
      selector: 'main:not([role]), [role=main]',
      tags: [ 'cat.semantics', 'best-practice' ],
      all: [],
      any: [ 'landmark-is-top-level' ],
      none: []
    }, {
      id: 'landmark-no-duplicate-banner',
      selector: 'header:not([role]), [role=banner]',
      tags: [ 'cat.semantics', 'best-practice' ],
      all: [],
      any: [ {
        options: {
          selector: 'header:not([role]), [role=banner]',
          nativeScopeFilter: 'article, aside, main, nav, section'
        },
        id: 'page-no-duplicate-banner'
      } ],
      none: []
    }, {
      id: 'landmark-no-duplicate-contentinfo',
      selector: 'footer:not([role]), [role=contentinfo]',
      tags: [ 'cat.semantics', 'best-practice' ],
      all: [],
      any: [ {
        options: {
          selector: 'footer:not([role]), [role=contentinfo]',
          nativeScopeFilter: 'article, aside, main, nav, section'
        },
        id: 'page-no-duplicate-contentinfo'
      } ],
      none: []
    }, {
      id: 'landmark-no-duplicate-main',
      selector: 'main:not([role]), [role=main]',
      tags: [ 'cat.semantics', 'best-practice' ],
      all: [],
      any: [ {
        options: {
          selector: 'main:not([role]), [role=\'main\']'
        },
        id: 'page-no-duplicate-main'
      } ],
      none: []
    }, {
      id: 'landmark-one-main',
      selector: 'html',
      tags: [ 'cat.semantics', 'best-practice' ],
      all: [ {
        options: {
          selector: 'main:not([role]), [role=\'main\']'
        },
        id: 'page-has-main'
      } ],
      any: [],
      none: []
    }, {
      id: 'landmark-unique',
      selector: '[role=banner], [role=complementary], [role=contentinfo], [role=main], [role=navigation], [role=region], [role=search], [role=form], form, footer, header, aside, main, nav, section',
      tags: [ 'cat.semantics', 'best-practice' ],
      matches: 'landmark-unique-matches',
      all: [],
      any: [ 'landmark-is-unique' ],
      none: []
    }, {
      id: 'link-in-text-block',
      selector: 'a[href], [role=link]',
      matches: 'link-in-text-block-matches',
      excludeHidden: false,
      tags: [ 'cat.color', 'experimental', 'wcag2a', 'wcag141' ],
      all: [ 'link-in-text-block' ],
      any: [],
      none: []
    }, {
      id: 'link-name',
      selector: 'a[href]',
      tags: [ 'cat.name-role-value', 'wcag2a', 'wcag412', 'wcag244', 'section508', 'section508.22.a', 'ACT' ],
      all: [],
      any: [ 'has-visible-text', 'aria-label', 'aria-labelledby', {
        options: {
          attribute: 'title'
        },
        id: 'non-empty-title'
      } ],
      none: [ 'focusable-no-name' ]
    }, {
      id: 'list',
      selector: 'ul, ol',
      matches: 'no-role-matches',
      tags: [ 'cat.structure', 'wcag2a', 'wcag131' ],
      all: [],
      any: [],
      none: [ 'only-listitems' ]
    }, {
      id: 'listitem',
      selector: 'li',
      matches: 'no-role-matches',
      tags: [ 'cat.structure', 'wcag2a', 'wcag131' ],
      all: [],
      any: [ 'listitem' ],
      none: []
    }, {
      id: 'marquee',
      selector: 'marquee',
      excludeHidden: false,
      tags: [ 'cat.parsing', 'wcag2a', 'wcag222' ],
      all: [],
      any: [],
      none: [ 'is-on-screen' ]
    }, {
      id: 'meta-refresh',
      selector: 'meta[http-equiv="refresh"]',
      excludeHidden: false,
      tags: [ 'cat.time-and-media', 'wcag2a', 'wcag2aaa', 'wcag221', 'wcag224', 'wcag325' ],
      all: [],
      any: [ 'meta-refresh' ],
      none: []
    }, {
      id: 'meta-viewport-large',
      selector: 'meta[name="viewport"]',
      excludeHidden: false,
      tags: [ 'cat.sensory-and-visual-cues', 'best-practice' ],
      all: [],
      any: [ {
        options: {
          scaleMinimum: 5,
          lowerBound: 2
        },
        id: 'meta-viewport-large'
      } ],
      none: []
    }, {
      id: 'meta-viewport',
      selector: 'meta[name="viewport"]',
      excludeHidden: false,
      tags: [ 'cat.sensory-and-visual-cues', 'best-practice', 'ACT' ],
      all: [],
      any: [ {
        options: {
          scaleMinimum: 2
        },
        id: 'meta-viewport'
      } ],
      none: []
    }, {
      id: 'nested-interactive',
      matches: 'nested-interactive-matches',
      tags: [ 'cat.keyboard', 'wcag2a', 'wcag412' ],
      all: [],
      any: [ 'no-focusable-content' ],
      none: []
    }, {
      id: 'no-autoplay-audio',
      excludeHidden: false,
      selector: 'audio[autoplay], video[autoplay]',
      matches: 'no-autoplay-audio-matches',
      tags: [ 'cat.time-and-media', 'wcag2a', 'wcag142', 'experimental' ],
      preload: true,
      all: [ {
        options: {
          allowedDuration: 3
        },
        id: 'no-autoplay-audio'
      } ],
      any: [],
      none: []
    }, {
      id: 'object-alt',
      selector: 'object',
      matches: 'no-explicit-name-required-matches',
      tags: [ 'cat.text-alternatives', 'wcag2a', 'wcag111', 'section508', 'section508.22.a' ],
      all: [],
      any: [ 'aria-label', 'aria-labelledby', {
        options: {
          attribute: 'title'
        },
        id: 'non-empty-title'
      }, 'presentational-role' ],
      none: []
    }, {
      id: 'p-as-heading',
      selector: 'p',
      matches: 'p-as-heading-matches',
      tags: [ 'cat.semantics', 'wcag2a', 'wcag131', 'experimental' ],
      all: [ {
        options: {
          margins: [ {
            weight: 150,
            italic: true
          }, {
            weight: 150,
            size: 1.15
          }, {
            italic: true,
            size: 1.15
          }, {
            size: 1.4
          } ]
        },
        id: 'p-as-heading'
      } ],
      any: [],
      none: []
    }, {
      id: 'page-has-heading-one',
      selector: 'html',
      tags: [ 'cat.semantics', 'best-practice' ],
      all: [ {
        options: {
          selector: 'h1:not([role], [aria-level]), :is(h1, h2, h3, h4, h5, h6):not([role])[aria-level=1], [role=heading][aria-level=1]'
        },
        id: 'page-has-heading-one'
      } ],
      any: [],
      none: []
    }, {
      id: 'presentation-role-conflict',
      selector: '[role="none"], [role="presentation"]',
      tags: [ 'cat.aria', 'best-practice' ],
      all: [],
      any: [],
      none: [ 'is-element-focusable', 'has-global-aria-attribute' ]
    }, {
      id: 'region',
      selector: 'body *',
      tags: [ 'cat.keyboard', 'best-practice' ],
      all: [],
      any: [ {
        options: {
          regionMatcher: 'dialog, [role=dialog], [role=alertdialog], svg, iframe'
        },
        id: 'region'
      } ],
      none: []
    }, {
      id: 'role-img-alt',
      selector: '[role=\'img\']:not(img, area, input, object)',
      matches: 'html-namespace-matches',
      tags: [ 'cat.text-alternatives', 'wcag2a', 'wcag111', 'section508', 'section508.22.a', 'ACT' ],
      all: [],
      any: [ 'aria-label', 'aria-labelledby', {
        options: {
          attribute: 'title'
        },
        id: 'non-empty-title'
      } ],
      none: []
    }, {
      id: 'scope-attr-valid',
      selector: 'td[scope], th[scope]',
      tags: [ 'cat.tables', 'best-practice' ],
      all: [ 'html5-scope', {
        options: {
          values: [ 'row', 'col', 'rowgroup', 'colgroup' ]
        },
        id: 'scope-value'
      } ],
      any: [],
      none: []
    }, {
      id: 'scrollable-region-focusable',
      matches: 'scrollable-region-focusable-matches',
      tags: [ 'cat.keyboard', 'wcag2a', 'wcag211' ],
      all: [],
      any: [ 'focusable-content', 'focusable-element' ],
      none: []
    }, {
      id: 'select-name',
      selector: 'select',
      tags: [ 'cat.forms', 'wcag2a', 'wcag412', 'wcag131', 'section508', 'section508.22.n', 'ACT' ],
      all: [],
      any: [ 'implicit-label', 'explicit-label', 'aria-label', 'aria-labelledby', {
        options: {
          attribute: 'title'
        },
        id: 'non-empty-title'
      }, 'presentational-role' ],
      none: [ 'help-same-as-label', 'hidden-explicit-label' ]
    }, {
      id: 'server-side-image-map',
      selector: 'img[ismap]',
      tags: [ 'cat.text-alternatives', 'wcag2a', 'wcag211', 'section508', 'section508.22.f' ],
      all: [],
      any: [],
      none: [ 'exists' ]
    }, {
      id: 'skip-link',
      selector: 'a[href^="#"], a[href^="/#"]',
      matches: 'skip-link-matches',
      tags: [ 'cat.keyboard', 'best-practice' ],
      all: [],
      any: [ 'skip-link' ],
      none: []
    }, {
      id: 'svg-img-alt',
      selector: '[role="img"], [role="graphics-symbol"], svg[role="graphics-document"]',
      matches: 'svg-namespace-matches',
      tags: [ 'cat.text-alternatives', 'wcag2a', 'wcag111', 'section508', 'section508.22.a', 'ACT' ],
      all: [],
      any: [ 'svg-non-empty-title', 'aria-label', 'aria-labelledby', {
        options: {
          attribute: 'title'
        },
        id: 'non-empty-title'
      } ],
      none: []
    }, {
      id: 'tabindex',
      selector: '[tabindex]',
      tags: [ 'cat.keyboard', 'best-practice' ],
      all: [],
      any: [ 'tabindex' ],
      none: []
    }, {
      id: 'table-duplicate-name',
      selector: 'table',
      tags: [ 'cat.tables', 'best-practice' ],
      all: [],
      any: [],
      none: [ 'same-caption-summary' ]
    }, {
      id: 'table-fake-caption',
      selector: 'table',
      matches: 'data-table-matches',
      tags: [ 'cat.tables', 'experimental', 'wcag2a', 'wcag131', 'section508', 'section508.22.g' ],
      all: [ 'caption-faked' ],
      any: [],
      none: []
    }, {
      id: 'td-has-header',
      selector: 'table',
      matches: 'data-table-large-matches',
      tags: [ 'cat.tables', 'experimental', 'wcag2a', 'wcag131', 'section508', 'section508.22.g' ],
      all: [ 'td-has-header' ],
      any: [],
      none: []
    }, {
      id: 'td-headers-attr',
      selector: 'table',
      tags: [ 'cat.tables', 'wcag2a', 'wcag131', 'section508', 'section508.22.g' ],
      all: [ 'td-headers-attr' ],
      any: [],
      none: []
    }, {
      id: 'th-has-data-cells',
      selector: 'table',
      matches: 'data-table-matches',
      tags: [ 'cat.tables', 'wcag2a', 'wcag131', 'section508', 'section508.22.g' ],
      all: [ 'th-has-data-cells' ],
      any: [],
      none: []
    }, {
      id: 'valid-lang',
      selector: '[lang], [xml\\:lang]',
      matches: 'not-html-matches',
      tags: [ 'cat.language', 'wcag2aa', 'wcag312' ],
      all: [],
      any: [],
      none: [ {
        options: {
          attributes: [ 'lang', 'xml:lang' ]
        },
        id: 'valid-lang'
      } ]
    }, {
      id: 'video-caption',
      selector: 'video',
      excludeHidden: false,
      tags: [ 'cat.text-alternatives', 'wcag2a', 'wcag122', 'section508', 'section508.22.a' ],
      all: [],
      any: [],
      none: [ 'caption' ]
    } ],
    checks: [ {
      id: 'abstractrole',
      evaluate: 'abstractrole-evaluate'
    }, {
      id: 'aria-allowed-attr',
      evaluate: 'aria-allowed-attr-evaluate'
    }, {
      id: 'aria-allowed-role',
      evaluate: 'aria-allowed-role-evaluate',
      options: {
        allowImplicit: true,
        ignoredTags: []
      }
    }, {
      id: 'aria-errormessage',
      evaluate: 'aria-errormessage-evaluate'
    }, {
      id: 'aria-hidden-body',
      evaluate: 'aria-hidden-body-evaluate'
    }, {
      id: 'aria-prohibited-attr',
      evaluate: 'aria-prohibited-attr-evaluate'
    }, {
      id: 'aria-required-attr',
      evaluate: 'aria-required-attr-evaluate'
    }, {
      id: 'aria-required-children',
      evaluate: 'aria-required-children-evaluate',
      options: {
        reviewEmpty: [ 'doc-bibliography', 'doc-endnotes', 'grid', 'list', 'listbox', 'table', 'tablist', 'tree', 'treegrid', 'rowgroup' ]
      }
    }, {
      id: 'aria-required-parent',
      evaluate: 'aria-required-parent-evaluate'
    }, {
      id: 'aria-roledescription',
      evaluate: 'aria-roledescription-evaluate',
      options: {
        supportedRoles: [ 'button', 'img', 'checkbox', 'radio', 'combobox', 'menuitemcheckbox', 'menuitemradio' ]
      }
    }, {
      id: 'aria-unsupported-attr',
      evaluate: 'aria-unsupported-attr-evaluate'
    }, {
      id: 'aria-valid-attr-value',
      evaluate: 'aria-valid-attr-value-evaluate',
      options: []
    }, {
      id: 'aria-valid-attr',
      evaluate: 'aria-valid-attr-evaluate',
      options: []
    }, {
      id: 'fallbackrole',
      evaluate: 'fallbackrole-evaluate'
    }, {
      id: 'has-global-aria-attribute',
      evaluate: 'has-global-aria-attribute-evaluate'
    }, {
      id: 'has-widget-role',
      evaluate: 'has-widget-role-evaluate',
      options: []
    }, {
      id: 'invalidrole',
      evaluate: 'invalidrole-evaluate'
    }, {
      id: 'is-element-focusable',
      evaluate: 'is-element-focusable-evaluate'
    }, {
      id: 'no-implicit-explicit-label',
      evaluate: 'no-implicit-explicit-label-evaluate'
    }, {
      id: 'unsupportedrole',
      evaluate: 'unsupportedrole-evaluate'
    }, {
      id: 'valid-scrollable-semantics',
      evaluate: 'valid-scrollable-semantics-evaluate',
      options: {
        roles: [ 'tooltip' ]
      }
    }, {
      id: 'color-contrast',
      evaluate: 'color-contrast-evaluate',
      options: {
        ignoreUnicode: true,
        ignoreLength: false,
        boldValue: 700,
        boldTextPt: 14,
        largeTextPt: 18,
        contrastRatio: {
          normal: {
            expected: 4.5
          },
          large: {
            expected: 3
          }
        },
        shadowOutlineEmMax: .1
      }
    }, {
      id: 'link-in-text-block',
      evaluate: 'link-in-text-block-evaluate'
    }, {
      id: 'autocomplete-appropriate',
      evaluate: 'autocomplete-appropriate-evaluate'
    }, {
      id: 'autocomplete-valid',
      evaluate: 'autocomplete-valid-evaluate'
    }, {
      id: 'accesskeys',
      evaluate: 'accesskeys-evaluate',
      after: 'accesskeys-after'
    }, {
      id: 'focusable-content',
      evaluate: 'focusable-content-evaluate'
    }, {
      id: 'focusable-disabled',
      evaluate: 'focusable-disabled-evaluate'
    }, {
      id: 'focusable-element',
      evaluate: 'focusable-element-evaluate'
    }, {
      id: 'focusable-modal-open',
      evaluate: 'focusable-modal-open-evaluate'
    }, {
      id: 'focusable-no-name',
      evaluate: 'focusable-no-name-evaluate'
    }, {
      id: 'focusable-not-tabbable',
      evaluate: 'focusable-not-tabbable-evaluate'
    }, {
      id: 'frame-focusable-content',
      evaluate: 'no-focusable-content-evaluate'
    }, {
      id: 'landmark-is-top-level',
      evaluate: 'landmark-is-top-level-evaluate'
    }, {
      id: 'no-focusable-content',
      evaluate: 'no-focusable-content-evaluate'
    }, {
      id: 'page-has-heading-one',
      evaluate: 'has-descendant-evaluate',
      after: 'has-descendant-after',
      options: {
        selector: 'h1:not([role], [aria-level]), :is(h1, h2, h3, h4, h5, h6):not([role])[aria-level=1], [role=heading][aria-level=1]'
      }
    }, {
      id: 'page-has-main',
      evaluate: 'has-descendant-evaluate',
      after: 'has-descendant-after',
      options: {
        selector: 'main:not([role]), [role=\'main\']'
      }
    }, {
      id: 'page-no-duplicate-banner',
      evaluate: 'page-no-duplicate-evaluate',
      after: 'page-no-duplicate-after',
      options: {
        selector: 'header:not([role]), [role=banner]',
        nativeScopeFilter: 'article, aside, main, nav, section'
      }
    }, {
      id: 'page-no-duplicate-contentinfo',
      evaluate: 'page-no-duplicate-evaluate',
      after: 'page-no-duplicate-after',
      options: {
        selector: 'footer:not([role]), [role=contentinfo]',
        nativeScopeFilter: 'article, aside, main, nav, section'
      }
    }, {
      id: 'page-no-duplicate-main',
      evaluate: 'page-no-duplicate-evaluate',
      after: 'page-no-duplicate-after',
      options: {
        selector: 'main:not([role]), [role=\'main\']'
      }
    }, {
      id: 'tabindex',
      evaluate: 'tabindex-evaluate'
    }, {
      id: 'alt-space-value',
      evaluate: 'alt-space-value-evaluate'
    }, {
      id: 'duplicate-img-label',
      evaluate: 'duplicate-img-label-evaluate',
      options: {
        parentSelector: 'button, [role=button], a[href], p, li, td, th'
      }
    }, {
      id: 'explicit-label',
      evaluate: 'explicit-evaluate'
    }, {
      id: 'help-same-as-label',
      evaluate: 'help-same-as-label-evaluate',
      enabled: false
    }, {
      id: 'hidden-explicit-label',
      evaluate: 'hidden-explicit-label-evaluate'
    }, {
      id: 'implicit-label',
      evaluate: 'implicit-evaluate'
    }, {
      id: 'label-content-name-mismatch',
      evaluate: 'label-content-name-mismatch-evaluate',
      options: {
        pixelThreshold: .1,
        occuranceThreshold: 3
      }
    }, {
      id: 'multiple-label',
      evaluate: 'multiple-label-evaluate'
    }, {
      id: 'title-only',
      evaluate: 'title-only-evaluate'
    }, {
      id: 'landmark-is-unique',
      evaluate: 'landmark-is-unique-evaluate',
      after: 'landmark-is-unique-after'
    }, {
      id: 'has-lang',
      evaluate: 'has-lang-evaluate',
      options: {
        attributes: [ 'lang', 'xml:lang' ]
      }
    }, {
      id: 'valid-lang',
      evaluate: 'valid-lang-evaluate',
      options: {
        attributes: [ 'lang', 'xml:lang' ]
      }
    }, {
      id: 'xml-lang-mismatch',
      evaluate: 'xml-lang-mismatch-evaluate'
    }, {
      id: 'dlitem',
      evaluate: 'dlitem-evaluate'
    }, {
      id: 'listitem',
      evaluate: 'listitem-evaluate'
    }, {
      id: 'only-dlitems',
      evaluate: 'only-dlitems-evaluate'
    }, {
      id: 'only-listitems',
      evaluate: 'only-listitems-evaluate'
    }, {
      id: 'structured-dlitems',
      evaluate: 'structured-dlitems-evaluate'
    }, {
      id: 'caption',
      evaluate: 'caption-evaluate'
    }, {
      id: 'frame-tested',
      evaluate: 'frame-tested-evaluate',
      options: {
        isViolation: false
      }
    }, {
      id: 'no-autoplay-audio',
      evaluate: 'no-autoplay-audio-evaluate',
      options: {
        allowedDuration: 3
      }
    }, {
      id: 'css-orientation-lock',
      evaluate: 'css-orientation-lock-evaluate',
      options: {
        degreeThreshold: 2
      }
    }, {
      id: 'meta-viewport-large',
      evaluate: 'meta-viewport-scale-evaluate',
      options: {
        scaleMinimum: 5,
        lowerBound: 2
      }
    }, {
      id: 'meta-viewport',
      evaluate: 'meta-viewport-scale-evaluate',
      options: {
        scaleMinimum: 2
      }
    }, {
      id: 'header-present',
      evaluate: 'has-descendant-evaluate',
      after: 'has-descendant-after',
      options: {
        selector: ':is(h1, h2, h3, h4, h5, h6):not([role]), [role=heading]'
      }
    }, {
      id: 'heading-order',
      evaluate: 'heading-order-evaluate',
      after: 'heading-order-after'
    }, {
      id: 'identical-links-same-purpose',
      evaluate: 'identical-links-same-purpose-evaluate',
      after: 'identical-links-same-purpose-after'
    }, {
      id: 'internal-link-present',
      evaluate: 'internal-link-present-evaluate'
    }, {
      id: 'landmark',
      evaluate: 'has-descendant-evaluate',
      options: {
        selector: 'main, [role=main]'
      }
    }, {
      id: 'meta-refresh',
      evaluate: 'meta-refresh-evaluate'
    }, {
      id: 'p-as-heading',
      evaluate: 'p-as-heading-evaluate',
      options: {
        margins: [ {
          weight: 150,
          italic: true
        }, {
          weight: 150,
          size: 1.15
        }, {
          italic: true,
          size: 1.15
        }, {
          size: 1.4
        } ]
      }
    }, {
      id: 'region',
      evaluate: 'region-evaluate',
      options: {
        regionMatcher: 'dialog, [role=dialog], [role=alertdialog], svg, iframe'
      }
    }, {
      id: 'skip-link',
      evaluate: 'skip-link-evaluate'
    }, {
      id: 'unique-frame-title',
      evaluate: 'unique-frame-title-evaluate',
      after: 'unique-frame-title-after'
    }, {
      id: 'duplicate-id-active',
      evaluate: 'duplicate-id-evaluate',
      after: 'duplicate-id-after'
    }, {
      id: 'duplicate-id-aria',
      evaluate: 'duplicate-id-evaluate',
      after: 'duplicate-id-after'
    }, {
      id: 'duplicate-id',
      evaluate: 'duplicate-id-evaluate',
      after: 'duplicate-id-after'
    }, {
      id: 'aria-label',
      evaluate: 'aria-label-evaluate'
    }, {
      id: 'aria-labelledby',
      evaluate: 'aria-labelledby-evaluate'
    }, {
      id: 'avoid-inline-spacing',
      evaluate: 'avoid-inline-spacing-evaluate',
      options: {
        cssProperties: [ 'line-height', 'letter-spacing', 'word-spacing' ]
      }
    }, {
      id: 'button-has-visible-text',
      evaluate: 'has-text-content-evaluate'
    }, {
      id: 'doc-has-title',
      evaluate: 'doc-has-title-evaluate'
    }, {
      id: 'exists',
      evaluate: 'exists-evaluate'
    }, {
      id: 'has-alt',
      evaluate: 'has-alt-evaluate'
    }, {
      id: 'has-visible-text',
      evaluate: 'has-text-content-evaluate'
    }, {
      id: 'is-on-screen',
      evaluate: 'is-on-screen-evaluate'
    }, {
      id: 'non-empty-alt',
      evaluate: 'attr-non-space-content-evaluate',
      options: {
        attribute: 'alt'
      }
    }, {
      id: 'non-empty-if-present',
      evaluate: 'non-empty-if-present-evaluate'
    }, {
      id: 'non-empty-placeholder',
      evaluate: 'attr-non-space-content-evaluate',
      options: {
        attribute: 'placeholder'
      }
    }, {
      id: 'non-empty-title',
      evaluate: 'attr-non-space-content-evaluate',
      options: {
        attribute: 'title'
      }
    }, {
      id: 'non-empty-value',
      evaluate: 'attr-non-space-content-evaluate',
      options: {
        attribute: 'value'
      }
    }, {
      id: 'presentational-role',
      evaluate: 'presentational-role-evaluate'
    }, {
      id: 'role-none',
      evaluate: 'matches-definition-evaluate',
      deprecated: true,
      options: {
        matcher: {
          attributes: {
            role: 'none'
          }
        }
      }
    }, {
      id: 'role-presentation',
      evaluate: 'matches-definition-evaluate',
      deprecated: true,
      options: {
        matcher: {
          attributes: {
            role: 'presentation'
          }
        }
      }
    }, {
      id: 'svg-non-empty-title',
      evaluate: 'svg-non-empty-title-evaluate'
    }, {
      id: 'caption-faked',
      evaluate: 'caption-faked-evaluate'
    }, {
      id: 'html5-scope',
      evaluate: 'html5-scope-evaluate'
    }, {
      id: 'same-caption-summary',
      evaluate: 'same-caption-summary-evaluate'
    }, {
      id: 'scope-value',
      evaluate: 'scope-value-evaluate',
      options: {
        values: [ 'row', 'col', 'rowgroup', 'colgroup' ]
      }
    }, {
      id: 'td-has-header',
      evaluate: 'td-has-header-evaluate'
    }, {
      id: 'td-headers-attr',
      evaluate: 'td-headers-attr-evaluate'
    }, {
      id: 'th-has-data-cells',
      evaluate: 'th-has-data-cells-evaluate'
    }, {
      id: 'hidden-content',
      evaluate: 'hidden-content-evaluate'
    } ]
  });
})(typeof window === 'object' ? window : this);