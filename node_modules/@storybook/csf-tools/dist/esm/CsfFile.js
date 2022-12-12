function _typeof(obj) { "@babel/helpers - typeof"; return _typeof = "function" == typeof Symbol && "symbol" == typeof Symbol.iterator ? function (obj) { return typeof obj; } : function (obj) { return obj && "function" == typeof Symbol && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; }, _typeof(obj); }

import "core-js/modules/es.object.get-prototype-of.js";
import "core-js/modules/es.reflect.construct.js";
import "core-js/modules/es.array.iterator.js";
import "core-js/modules/es.map.js";
import "core-js/modules/es.string.iterator.js";
import "core-js/modules/web.dom-collections.iterator.js";
import "core-js/modules/es.array.slice.js";
import "core-js/modules/es.object.freeze.js";
import "core-js/modules/es.symbol.js";
import "core-js/modules/es.symbol.description.js";
import "core-js/modules/es.symbol.iterator.js";
import "core-js/modules/es.array.from.js";
import "core-js/modules/es.promise.js";

var _templateObject, _templateObject2, _templateObject3, _templateObject4;

import "regenerator-runtime/runtime.js";

function asyncGeneratorStep(gen, resolve, reject, _next, _throw, key, arg) { try { var info = gen[key](arg); var value = info.value; } catch (error) { reject(error); return; } if (info.done) { resolve(value); } else { Promise.resolve(value).then(_next, _throw); } }

function _asyncToGenerator(fn) { return function () { var self = this, args = arguments; return new Promise(function (resolve, reject) { var gen = fn.apply(self, args); function _next(value) { asyncGeneratorStep(gen, resolve, reject, _next, _throw, "next", value); } function _throw(err) { asyncGeneratorStep(gen, resolve, reject, _next, _throw, "throw", err); } _next(undefined); }); }; }

function _slicedToArray(arr, i) { return _arrayWithHoles(arr) || _iterableToArrayLimit(arr, i) || _unsupportedIterableToArray(arr, i) || _nonIterableRest(); }

function _nonIterableRest() { throw new TypeError("Invalid attempt to destructure non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen); }

function _arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

function _iterableToArrayLimit(arr, i) { var _i = arr == null ? null : typeof Symbol !== "undefined" && arr[Symbol.iterator] || arr["@@iterator"]; if (_i == null) return; var _arr = []; var _n = true; var _d = false; var _s, _e; try { for (_i = _i.call(arr); !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"] != null) _i["return"](); } finally { if (_d) throw _e; } } return _arr; }

function _arrayWithHoles(arr) { if (Array.isArray(arr)) return arr; }

function _taggedTemplateLiteral(strings, raw) { if (!raw) { raw = strings.slice(0); } return Object.freeze(Object.defineProperties(strings, { raw: { value: Object.freeze(raw) } })); }

function _defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } }

function _createClass(Constructor, protoProps, staticProps) { if (protoProps) _defineProperties(Constructor.prototype, protoProps); if (staticProps) _defineProperties(Constructor, staticProps); Object.defineProperty(Constructor, "prototype", { writable: false }); return Constructor; }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function"); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, writable: true, configurable: true } }); Object.defineProperty(subClass, "prototype", { writable: false }); if (superClass) _setPrototypeOf(subClass, superClass); }

function _createSuper(Derived) { var hasNativeReflectConstruct = _isNativeReflectConstruct(); return function _createSuperInternal() { var Super = _getPrototypeOf(Derived), result; if (hasNativeReflectConstruct) { var NewTarget = _getPrototypeOf(this).constructor; result = Reflect.construct(Super, arguments, NewTarget); } else { result = Super.apply(this, arguments); } return _possibleConstructorReturn(this, result); }; }

function _possibleConstructorReturn(self, call) { if (call && (_typeof(call) === "object" || typeof call === "function")) { return call; } else if (call !== void 0) { throw new TypeError("Derived constructors may only return object or undefined"); } return _assertThisInitialized(self); }

function _assertThisInitialized(self) { if (self === void 0) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return self; }

function _wrapNativeSuper(Class) { var _cache = typeof Map === "function" ? new Map() : undefined; _wrapNativeSuper = function _wrapNativeSuper(Class) { if (Class === null || !_isNativeFunction(Class)) return Class; if (typeof Class !== "function") { throw new TypeError("Super expression must either be null or a function"); } if (typeof _cache !== "undefined") { if (_cache.has(Class)) return _cache.get(Class); _cache.set(Class, Wrapper); } function Wrapper() { return _construct(Class, arguments, _getPrototypeOf(this).constructor); } Wrapper.prototype = Object.create(Class.prototype, { constructor: { value: Wrapper, enumerable: false, writable: true, configurable: true } }); return _setPrototypeOf(Wrapper, Class); }; return _wrapNativeSuper(Class); }

function _construct(Parent, args, Class) { if (_isNativeReflectConstruct()) { _construct = Reflect.construct; } else { _construct = function _construct(Parent, args, Class) { var a = [null]; a.push.apply(a, args); var Constructor = Function.bind.apply(Parent, a); var instance = new Constructor(); if (Class) _setPrototypeOf(instance, Class.prototype); return instance; }; } return _construct.apply(null, arguments); }

function _isNativeReflectConstruct() { if (typeof Reflect === "undefined" || !Reflect.construct) return false; if (Reflect.construct.sham) return false; if (typeof Proxy === "function") return true; try { Boolean.prototype.valueOf.call(Reflect.construct(Boolean, [], function () {})); return true; } catch (e) { return false; } }

function _isNativeFunction(fn) { return Function.toString.call(fn).indexOf("[native code]") !== -1; }

function _setPrototypeOf(o, p) { _setPrototypeOf = Object.setPrototypeOf || function _setPrototypeOf(o, p) { o.__proto__ = p; return o; }; return _setPrototypeOf(o, p); }

function _getPrototypeOf(o) { _getPrototypeOf = Object.setPrototypeOf ? Object.getPrototypeOf : function _getPrototypeOf(o) { return o.__proto__ || Object.getPrototypeOf(o); }; return _getPrototypeOf(o); }

import "core-js/modules/es.array.map.js";
import "core-js/modules/es.regexp.constructor.js";
import "core-js/modules/es.regexp.exec.js";
import "core-js/modules/es.regexp.to-string.js";
import "core-js/modules/es.regexp.flags.js";
import "core-js/modules/es.array.find.js";
import "core-js/modules/es.object.to-string.js";
import "core-js/modules/es.function.name.js";
import "core-js/modules/es.string.trim.js";
import "core-js/modules/es.array.concat.js";
import "core-js/modules/web.dom-collections.for-each.js";
import "core-js/modules/es.array.includes.js";
import "core-js/modules/es.array.filter.js";
import "core-js/modules/es.object.entries.js";
import "core-js/modules/es.object.assign.js";
import "core-js/modules/es.object.keys.js";
import "core-js/modules/es.string.includes.js";
import "core-js/modules/es.object.values.js";

/* eslint-disable no-underscore-dangle */
import fs from 'fs-extra';
import dedent from 'ts-dedent';
import * as t from '@babel/types';
import generate from '@babel/generator';
import traverse from '@babel/traverse';
import { toId, isExportStory, storyNameFromExport } from '@storybook/csf';
import { babelParse } from './babelParse';
var logger = console;

function parseIncludeExclude(prop) {
  if (t.isArrayExpression(prop)) {
    return prop.elements.map(function (e) {
      if (t.isStringLiteral(e)) return e.value;
      throw new Error("Expected string literal: ".concat(e));
    });
  }

  if (t.isStringLiteral(prop)) return new RegExp(prop.value);
  if (t.isRegExpLiteral(prop)) return new RegExp(prop.pattern, prop.flags);
  throw new Error("Unknown include/exclude: ".concat(prop));
}

var findVarInitialization = function findVarInitialization(identifier, program) {
  var init = null;
  var declarations = null;
  program.body.find(function (node) {
    if (t.isVariableDeclaration(node)) {
      declarations = node.declarations;
    } else if (t.isExportNamedDeclaration(node) && t.isVariableDeclaration(node.declaration)) {
      declarations = node.declaration.declarations;
    }

    return declarations && declarations.find(function (decl) {
      if (t.isVariableDeclarator(decl) && t.isIdentifier(decl.id) && decl.id.name === identifier) {
        init = decl.init;
        return true; // stop looking
      }

      return false;
    });
  });
  return init;
};

var formatLocation = function formatLocation(node, fileName) {
  var _node$loc$start = node.loc.start,
      line = _node$loc$start.line,
      column = _node$loc$start.column;
  return "".concat(fileName || '', " (line ").concat(line, ", col ").concat(column, ")").trim();
};

var isArgsStory = function isArgsStory(init, parent, csf) {
  var storyFn = init; // export const Foo = Bar.bind({})

  if (t.isCallExpression(init)) {
    var callee = init.callee,
        bindArguments = init.arguments;

    if (t.isProgram(parent) && t.isMemberExpression(callee) && t.isIdentifier(callee.object) && t.isIdentifier(callee.property) && callee.property.name === 'bind' && (bindArguments.length === 0 || bindArguments.length === 1 && t.isObjectExpression(bindArguments[0]) && bindArguments[0].properties.length === 0)) {
      var boundIdentifier = callee.object.name;
      var template = findVarInitialization(boundIdentifier, parent);

      if (template) {
        // eslint-disable-next-line no-param-reassign
        csf._templates[boundIdentifier] = template;
        storyFn = template;
      }
    }
  }

  if (t.isArrowFunctionExpression(storyFn)) {
    return storyFn.params.length > 0;
  }

  if (t.isFunctionDeclaration(storyFn)) {
    return storyFn.params.length > 0;
  }

  return false;
};

var parseExportsOrder = function parseExportsOrder(init) {
  if (t.isArrayExpression(init)) {
    return init.elements.map(function (item) {
      if (t.isStringLiteral(item)) {
        return item.value;
      }

      throw new Error("Expected string literal named export: ".concat(item));
    });
  }

  throw new Error("Expected array of string literals: ".concat(init));
};

var sortExports = function sortExports(exportByName, order) {
  return order.reduce(function (acc, name) {
    var namedExport = exportByName[name];
    if (namedExport) acc[name] = namedExport;
    return acc;
  }, {});
};

export var NoMetaError = /*#__PURE__*/function (_Error) {
  _inherits(NoMetaError, _Error);

  var _super = _createSuper(NoMetaError);

  function NoMetaError(ast, fileName) {
    var _this;

    _classCallCheck(this, NoMetaError);

    _this = _super.call(this, dedent(_templateObject || (_templateObject = _taggedTemplateLiteral(["\n      CSF: missing default export ", "\n\n      More info: https://storybook.js.org/docs/react/writing-stories/introduction#default-export\n    "])), formatLocation(ast, fileName)));
    _this.name = _this.constructor.name;
    return _this;
  }

  return _createClass(NoMetaError);
}( /*#__PURE__*/_wrapNativeSuper(Error));
export var CsfFile = /*#__PURE__*/function () {
  function CsfFile(ast, _ref) {
    var fileName = _ref.fileName,
        makeTitle = _ref.makeTitle;

    _classCallCheck(this, CsfFile);

    this._ast = void 0;
    this._fileName = void 0;
    this._makeTitle = void 0;
    this._meta = void 0;
    this._stories = {};
    this._metaAnnotations = {};
    this._storyExports = {};
    this._storyAnnotations = {};
    this._templates = {};
    this._namedExportsOrder = void 0;
    this._ast = ast;
    this._fileName = fileName;
    this._makeTitle = makeTitle;
  }

  _createClass(CsfFile, [{
    key: "_parseTitle",
    value: function _parseTitle(value) {
      var node = t.isIdentifier(value) ? findVarInitialization(value.name, this._ast.program) : value;
      if (t.isStringLiteral(node)) return node.value;
      throw new Error(dedent(_templateObject2 || (_templateObject2 = _taggedTemplateLiteral(["\n      CSF: unexpected dynamic title ", "\n\n      More info: https://github.com/storybookjs/storybook/blob/next/MIGRATION.md#string-literal-titles\n    "])), formatLocation(node, this._fileName)));
    }
  }, {
    key: "_parseMeta",
    value: function _parseMeta(declaration, program) {
      var _this2 = this;

      var meta = {};
      declaration.properties.forEach(function (p) {
        if (t.isIdentifier(p.key)) {
          _this2._metaAnnotations[p.key.name] = p.value;

          if (p.key.name === 'title') {
            meta.title = _this2._parseTitle(p.value);
          } else if (['includeStories', 'excludeStories'].includes(p.key.name)) {
            // @ts-ignore
            meta[p.key.name] = parseIncludeExclude(p.value);
          } else if (p.key.name === 'component') {
            var _generate = generate(p.value, {}),
                code = _generate.code;

            meta.component = code;
          } else if (p.key.name === 'id') {
            if (t.isStringLiteral(p.value)) {
              meta.id = p.value.value;
            } else {
              throw new Error("Unexpected component id: ".concat(p.value));
            }
          }
        }
      });
      this._meta = meta;
    }
  }, {
    key: "parse",
    value: function parse() {
      // eslint-disable-next-line @typescript-eslint/no-this-alias
      var self = this;
      traverse(this._ast, {
        ExportDefaultDeclaration: {
          enter: function enter(_ref2) {
            var node = _ref2.node,
                parent = _ref2.parent;
            var metaNode;
            var decl = t.isIdentifier(node.declaration) && t.isProgram(parent) ? findVarInitialization(node.declaration.name, parent) : node.declaration;

            if (t.isObjectExpression(decl)) {
              // export default { ... };
              metaNode = decl;
            } else if ( // export default { ... } as Meta<...>
            t.isTSAsExpression(decl) && t.isObjectExpression(decl.expression)) {
              metaNode = decl.expression;
            }

            if (!self._meta && metaNode && t.isProgram(parent)) {
              self._parseMeta(metaNode, parent);
            }
          }
        },
        ExportNamedDeclaration: {
          enter: function enter(_ref3) {
            var node = _ref3.node,
                parent = _ref3.parent;
            var declarations;

            if (t.isVariableDeclaration(node.declaration)) {
              declarations = node.declaration.declarations.filter(function (d) {
                return t.isVariableDeclarator(d);
              });
            } else if (t.isFunctionDeclaration(node.declaration)) {
              declarations = [node.declaration];
            }

            if (declarations) {
              // export const X = ...;
              declarations.forEach(function (decl) {
                if (t.isIdentifier(decl.id)) {
                  var exportName = decl.id.name;

                  if (exportName === '__namedExportsOrder' && t.isVariableDeclarator(decl)) {
                    self._namedExportsOrder = parseExportsOrder(decl.init);
                    return;
                  }

                  self._storyExports[exportName] = decl;
                  var name = storyNameFromExport(exportName);

                  if (self._storyAnnotations[exportName]) {
                    logger.warn("Unexpected annotations for \"".concat(exportName, "\" before story declaration"));
                  } else {
                    self._storyAnnotations[exportName] = {};
                  }

                  var parameters;

                  if (t.isVariableDeclarator(decl) && t.isObjectExpression(decl.init)) {
                    var __isArgsStory = true; // assume default render is an args story
                    // CSF3 object export

                    decl.init.properties.forEach(function (p) {
                      if (t.isIdentifier(p.key)) {
                        if (p.key.name === 'render') {
                          __isArgsStory = isArgsStory(p.value, parent, self);
                        } else if (p.key.name === 'name' && t.isStringLiteral(p.value)) {
                          name = p.value.value;
                        } else if (p.key.name === 'storyName' && t.isStringLiteral(p.value)) {
                          logger.warn("Unexpected usage of \"storyName\" in \"".concat(exportName, "\". Please use \"name\" instead."));
                        }

                        self._storyAnnotations[exportName][p.key.name] = p.value;
                      }
                    });
                    parameters = {
                      __isArgsStory: __isArgsStory
                    };
                  } else {
                    var fn = t.isVariableDeclarator(decl) ? decl.init : decl;
                    parameters = {
                      // __id: toId(self._meta.title, name),
                      // FIXME: Template.bind({});
                      __isArgsStory: isArgsStory(fn, parent, self)
                    };
                  }

                  self._stories[exportName] = {
                    id: 'FIXME',
                    name: name,
                    parameters: parameters
                  };
                }
              });
            } else if (node.specifiers.length > 0) {
              // export { X as Y }
              node.specifiers.forEach(function (specifier) {
                if (t.isExportSpecifier(specifier) && t.isIdentifier(specifier.exported)) {
                  var exportName = specifier.exported.name;
                  self._storyAnnotations[exportName] = {};
                  self._stories[exportName] = {
                    id: 'FIXME',
                    name: exportName,
                    parameters: {}
                  };
                }
              });
            }
          }
        },
        ExpressionStatement: {
          enter: function enter(_ref4) {
            var node = _ref4.node,
                parent = _ref4.parent;
            var expression = node.expression; // B.storyName = 'some string';

            if (t.isProgram(parent) && t.isAssignmentExpression(expression) && t.isMemberExpression(expression.left) && t.isIdentifier(expression.left.object) && t.isIdentifier(expression.left.property)) {
              var exportName = expression.left.object.name;
              var annotationKey = expression.left.property.name;
              var annotationValue = expression.right; // v1-style annotation
              // A.story = { parameters: ..., decorators: ... }

              if (self._storyAnnotations[exportName]) {
                if (annotationKey === 'story' && t.isObjectExpression(annotationValue)) {
                  annotationValue.properties.forEach(function (prop) {
                    if (t.isIdentifier(prop.key)) {
                      self._storyAnnotations[exportName][prop.key.name] = prop.value;
                    }
                  });
                } else {
                  self._storyAnnotations[exportName][annotationKey] = annotationValue;
                }
              }

              if (annotationKey === 'storyName' && t.isStringLiteral(annotationValue)) {
                var storyName = annotationValue.value;
                var story = self._stories[exportName];
                if (!story) return;
                story.name = storyName;
              }
            }
          }
        },
        CallExpression: {
          enter: function enter(_ref5) {
            var node = _ref5.node;
            var callee = node.callee;

            if (t.isIdentifier(callee) && callee.name === 'storiesOf') {
              throw new Error(dedent(_templateObject3 || (_templateObject3 = _taggedTemplateLiteral(["\n              CSF: unexpected storiesOf call ", "\n\n              More info: https://github.com/storybookjs/storybook/blob/next/MIGRATION.md#story-store-v7\n            "])), formatLocation(node, self._fileName)));
            }
          }
        }
      });

      if (!self._meta) {
        throw new NoMetaError(self._ast, self._fileName);
      }

      if (!self._meta.title && !self._meta.component) {
        throw new Error(dedent(_templateObject4 || (_templateObject4 = _taggedTemplateLiteral(["\n        CSF: missing title/component ", "\n\n        More info: https://storybook.js.org/docs/react/writing-stories/introduction#default-export\n      "])), formatLocation(self._ast, self._fileName)));
      } // default export can come at any point in the file, so we do this post processing last


      var entries = Object.entries(self._stories);
      self._meta.title = this._makeTitle(self._meta.title);
      self._stories = entries.reduce(function (acc, _ref6) {
        var _ref7 = _slicedToArray(_ref6, 2),
            key = _ref7[0],
            story = _ref7[1];

        if (isExportStory(key, self._meta)) {
          var id = toId(self._meta.id || self._meta.title, storyNameFromExport(key));
          var parameters = Object.assign({}, story.parameters, {
            __id: id
          });

          if (entries.length === 1 && key === '__page') {
            parameters.docsOnly = true;
          }

          acc[key] = Object.assign({}, story, {
            id: id,
            parameters: parameters
          });
        }

        return acc;
      }, {});
      Object.keys(self._storyExports).forEach(function (key) {
        if (!isExportStory(key, self._meta)) {
          delete self._storyExports[key];
          delete self._storyAnnotations[key];
        }
      });

      if (self._namedExportsOrder) {
        var unsortedExports = Object.keys(self._storyExports);
        self._storyExports = sortExports(self._storyExports, self._namedExportsOrder);
        self._stories = sortExports(self._stories, self._namedExportsOrder);
        var sortedExports = Object.keys(self._storyExports);

        if (unsortedExports.length !== sortedExports.length) {
          throw new Error("Missing exports after sort: ".concat(unsortedExports.filter(function (key) {
            return !sortedExports.includes(key);
          })));
        }
      }

      return self;
    }
  }, {
    key: "meta",
    get: function get() {
      return this._meta;
    }
  }, {
    key: "stories",
    get: function get() {
      return Object.values(this._stories);
    }
  }]);

  return CsfFile;
}();
export var loadCsf = function loadCsf(code, options) {
  var ast = babelParse(code);
  return new CsfFile(ast, options);
};
export var formatCsf = function formatCsf(csf) {
  var _generate2 = generate(csf._ast, {}),
      code = _generate2.code;

  return code;
};
export var readCsf = /*#__PURE__*/function () {
  var _ref8 = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee(fileName, options) {
    var code;
    return regeneratorRuntime.wrap(function _callee$(_context) {
      while (1) {
        switch (_context.prev = _context.next) {
          case 0:
            _context.next = 2;
            return fs.readFile(fileName, 'utf-8');

          case 2:
            code = _context.sent.toString();
            return _context.abrupt("return", loadCsf(code, Object.assign({}, options, {
              fileName: fileName
            })));

          case 4:
          case "end":
            return _context.stop();
        }
      }
    }, _callee);
  }));

  return function readCsf(_x, _x2) {
    return _ref8.apply(this, arguments);
  };
}();
export var writeCsf = /*#__PURE__*/function () {
  var _ref9 = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee2(csf, fileName) {
    var fname;
    return regeneratorRuntime.wrap(function _callee2$(_context2) {
      while (1) {
        switch (_context2.prev = _context2.next) {
          case 0:
            fname = fileName || csf._fileName;

            if (fname) {
              _context2.next = 3;
              break;
            }

            throw new Error('Please specify a fileName for writeCsf');

          case 3:
            _context2.t0 = fs;
            _context2.t1 = fileName;
            _context2.next = 7;
            return formatCsf(csf);

          case 7:
            _context2.t2 = _context2.sent;
            _context2.next = 10;
            return _context2.t0.writeFile.call(_context2.t0, _context2.t1, _context2.t2);

          case 10:
          case "end":
            return _context2.stop();
        }
      }
    }, _callee2);
  }));

  return function writeCsf(_x3, _x4) {
    return _ref9.apply(this, arguments);
  };
}();