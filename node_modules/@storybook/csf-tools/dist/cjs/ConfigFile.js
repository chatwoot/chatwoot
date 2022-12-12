"use strict";

function _typeof(obj) { "@babel/helpers - typeof"; return _typeof = "function" == typeof Symbol && "symbol" == typeof Symbol.iterator ? function (obj) { return typeof obj; } : function (obj) { return obj && "function" == typeof Symbol && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; }, _typeof(obj); }

require("core-js/modules/es.symbol.js");

require("core-js/modules/es.symbol.description.js");

require("core-js/modules/es.symbol.iterator.js");

require("core-js/modules/es.array.iterator.js");

require("core-js/modules/es.string.iterator.js");

require("core-js/modules/web.dom-collections.iterator.js");

require("core-js/modules/es.array.from.js");

require("core-js/modules/es.regexp.exec.js");

require("core-js/modules/es.promise.js");

require("core-js/modules/es.weak-map.js");

require("core-js/modules/es.object.get-own-property-descriptor.js");

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.writeConfig = exports.readConfig = exports.loadConfig = exports.formatConfig = exports.ConfigFile = void 0;

require("regenerator-runtime/runtime.js");

require("core-js/modules/es.function.name.js");

require("core-js/modules/es.array.slice.js");

require("core-js/modules/es.array.find.js");

require("core-js/modules/es.object.to-string.js");

require("core-js/modules/web.dom-collections.for-each.js");

require("core-js/modules/es.regexp.to-string.js");

var _fsExtra = _interopRequireDefault(require("fs-extra"));

var t = _interopRequireWildcard(require("@babel/types"));

var _generator = _interopRequireDefault(require("@babel/generator"));

var _traverse = _interopRequireDefault(require("@babel/traverse"));

var _babelParse = require("./babelParse");

function _getRequireWildcardCache(nodeInterop) { if (typeof WeakMap !== "function") return null; var cacheBabelInterop = new WeakMap(); var cacheNodeInterop = new WeakMap(); return (_getRequireWildcardCache = function _getRequireWildcardCache(nodeInterop) { return nodeInterop ? cacheNodeInterop : cacheBabelInterop; })(nodeInterop); }

function _interopRequireWildcard(obj, nodeInterop) { if (!nodeInterop && obj && obj.__esModule) { return obj; } if (obj === null || _typeof(obj) !== "object" && typeof obj !== "function") { return { default: obj }; } var cache = _getRequireWildcardCache(nodeInterop); if (cache && cache.has(obj)) { return cache.get(obj); } var newObj = {}; var hasPropertyDescriptor = Object.defineProperty && Object.getOwnPropertyDescriptor; for (var key in obj) { if (key !== "default" && Object.prototype.hasOwnProperty.call(obj, key)) { var desc = hasPropertyDescriptor ? Object.getOwnPropertyDescriptor(obj, key) : null; if (desc && (desc.get || desc.set)) { Object.defineProperty(newObj, key, desc); } else { newObj[key] = obj[key]; } } } newObj.default = obj; if (cache) { cache.set(obj, newObj); } return newObj; }

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function asyncGeneratorStep(gen, resolve, reject, _next, _throw, key, arg) { try { var info = gen[key](arg); var value = info.value; } catch (error) { reject(error); return; } if (info.done) { resolve(value); } else { Promise.resolve(value).then(_next, _throw); } }

function _asyncToGenerator(fn) { return function () { var self = this, args = arguments; return new Promise(function (resolve, reject) { var gen = fn.apply(self, args); function _next(value) { asyncGeneratorStep(gen, resolve, reject, _next, _throw, "next", value); } function _throw(err) { asyncGeneratorStep(gen, resolve, reject, _next, _throw, "throw", err); } _next(undefined); }); }; }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } }

function _createClass(Constructor, protoProps, staticProps) { if (protoProps) _defineProperties(Constructor.prototype, protoProps); if (staticProps) _defineProperties(Constructor, staticProps); Object.defineProperty(Constructor, "prototype", { writable: false }); return Constructor; }

function _toArray(arr) { return _arrayWithHoles(arr) || _iterableToArray(arr) || _unsupportedIterableToArray(arr) || _nonIterableRest(); }

function _nonIterableRest() { throw new TypeError("Invalid attempt to destructure non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen); }

function _arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

function _iterableToArray(iter) { if (typeof Symbol !== "undefined" && iter[Symbol.iterator] != null || iter["@@iterator"] != null) return Array.from(iter); }

function _arrayWithHoles(arr) { if (Array.isArray(arr)) return arr; }

var logger = console;

var propKey = function propKey(p) {
  if (t.isIdentifier(p.key)) return p.key.name;
  if (t.isStringLiteral(p.key)) return p.key.value;
  return null;
};

var _getPath = function _getPath(path, node) {
  if (path.length === 0) {
    return node;
  }

  if (t.isObjectExpression(node)) {
    var _path = _toArray(path),
        first = _path[0],
        rest = _path.slice(1);

    var field = node.properties.find(function (p) {
      return propKey(p) === first;
    });

    if (field) {
      return _getPath(rest, field.value);
    }
  }

  return undefined;
};

var _findVarInitialization = function _findVarInitialization(identifier, program) {
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

var _makeObjectExpression = function _makeObjectExpression(path, value) {
  if (path.length === 0) return value;

  var _path2 = _toArray(path),
      first = _path2[0],
      rest = _path2.slice(1);

  var innerExpression = _makeObjectExpression(rest, value);

  return t.objectExpression([t.objectProperty(t.identifier(first), innerExpression)]);
};

var _updateExportNode = function _updateExportNode(path, expr, existing) {
  var _path3 = _toArray(path),
      first = _path3[0],
      rest = _path3.slice(1);

  var existingField = existing.properties.find(function (p) {
    return propKey(p) === first;
  });

  if (!existingField) {
    existing.properties.push(t.objectProperty(t.identifier(first), _makeObjectExpression(rest, expr)));
  } else if (t.isObjectExpression(existingField.value) && rest.length > 0) {
    _updateExportNode(rest, expr, existingField.value);
  } else {
    existingField.value = _makeObjectExpression(rest, expr);
  }
};

var ConfigFile = /*#__PURE__*/function () {
  function ConfigFile(ast, code, fileName) {
    _classCallCheck(this, ConfigFile);

    this._ast = void 0;
    this._code = void 0;
    this._exports = {};
    this._exportsObject = void 0;
    this._quotes = void 0;
    this.fileName = void 0;
    this._ast = ast;
    this._code = code;
    this.fileName = fileName;
  }

  _createClass(ConfigFile, [{
    key: "parse",
    value: function parse() {
      // eslint-disable-next-line @typescript-eslint/no-this-alias
      var self = this;
      (0, _traverse.default)(this._ast, {
        ExportNamedDeclaration: {
          enter: function enter(_ref) {
            var node = _ref.node,
                parent = _ref.parent;

            if (t.isVariableDeclaration(node.declaration)) {
              // export const X = ...;
              node.declaration.declarations.forEach(function (decl) {
                if (t.isVariableDeclarator(decl) && t.isIdentifier(decl.id)) {
                  var exportName = decl.id.name;
                  var exportVal = decl.init;

                  if (t.isIdentifier(exportVal)) {
                    exportVal = _findVarInitialization(exportVal.name, parent);
                  }

                  self._exports[exportName] = exportVal;
                }
              });
            } else {
              logger.warn("Unexpected ".concat(JSON.stringify(node)));
            }
          }
        },
        ExpressionStatement: {
          enter: function enter(_ref2) {
            var node = _ref2.node,
                parent = _ref2.parent;

            if (t.isAssignmentExpression(node.expression) && node.expression.operator === '=') {
              var _node$expression = node.expression,
                  left = _node$expression.left,
                  right = _node$expression.right;

              if (t.isMemberExpression(left) && t.isIdentifier(left.object) && left.object.name === 'module' && t.isIdentifier(left.property) && left.property.name === 'exports') {
                var exportObject = right;

                if (t.isIdentifier(right)) {
                  exportObject = _findVarInitialization(right.name, parent);
                }

                if (t.isObjectExpression(exportObject)) {
                  self._exportsObject = exportObject;
                  exportObject.properties.forEach(function (p) {
                    var exportName = propKey(p);

                    if (exportName) {
                      var exportVal = p.value;

                      if (t.isIdentifier(exportVal)) {
                        exportVal = _findVarInitialization(exportVal.name, parent);
                      }

                      self._exports[exportName] = exportVal;
                    }
                  });
                } else {
                  logger.warn("Unexpected ".concat(JSON.stringify(node)));
                }
              }
            }
          }
        }
      });
      return self;
    }
  }, {
    key: "getFieldNode",
    value: function getFieldNode(path) {
      var _path4 = _toArray(path),
          root = _path4[0],
          rest = _path4.slice(1);

      var exported = this._exports[root];
      if (!exported) return undefined;
      return _getPath(rest, exported);
    }
  }, {
    key: "getFieldValue",
    value: function getFieldValue(path) {
      var node = this.getFieldNode(path);

      if (node) {
        var _generate = (0, _generator.default)(node, {}),
            code = _generate.code; // eslint-disable-next-line no-eval


        var value = eval("(() => (".concat(code, "))()"));
        return value;
      }

      return undefined;
    }
  }, {
    key: "setFieldNode",
    value: function setFieldNode(path, expr) {
      var _path5 = _toArray(path),
          first = _path5[0],
          rest = _path5.slice(1);

      var exportNode = this._exports[first];

      if (this._exportsObject) {
        _updateExportNode(path, expr, this._exportsObject);

        this._exports[path[0]] = expr;
      } else if (exportNode && t.isObjectExpression(exportNode) && rest.length > 0) {
        _updateExportNode(rest, expr, exportNode);
      } else {
        // create a new named export and add it to the top level
        var exportObj = _makeObjectExpression(rest, expr);

        var newExport = t.exportNamedDeclaration(t.variableDeclaration('const', [t.variableDeclarator(t.identifier(first), exportObj)]));
        this._exports[first] = exportObj;

        this._ast.program.body.push(newExport);
      }
    }
  }, {
    key: "_inferQuotes",
    value: function _inferQuotes() {
      var _this = this;

      if (!this._quotes) {
        // first 500 tokens for efficiency
        var occurrences = (this._ast.tokens || []).slice(0, 500).reduce(function (acc, token) {
          if (token.type.label === 'string') {
            acc[_this._code[token.start]] += 1;
          }

          return acc;
        }, {
          "'": 0,
          '"': 0
        });
        this._quotes = occurrences["'"] > occurrences['"'] ? 'single' : 'double';
      }

      return this._quotes;
    }
  }, {
    key: "setFieldValue",
    value: function setFieldValue(path, value) {
      var quotes = this._inferQuotes();

      var valueNode; // we do this rather than t.valueToNode because apparently
      // babel only preserves quotes if they are parsed from the original code.

      if (quotes === 'single') {
        var _generate2 = (0, _generator.default)(t.valueToNode(value), {
          jsescOption: {
            quotes: quotes
          }
        }),
            code = _generate2.code;

        var program = (0, _babelParse.babelParse)("const __x = ".concat(code));
        (0, _traverse.default)(program, {
          VariableDeclaration: {
            enter: function enter(_ref3) {
              var node = _ref3.node;

              if (node.declarations.length === 1 && t.isVariableDeclarator(node.declarations[0]) && t.isIdentifier(node.declarations[0].id) && node.declarations[0].id.name === '__x') {
                valueNode = node.declarations[0].init;
              }
            }
          }
        });
      } else {
        // double quotes is the default so we can skip all that
        valueNode = t.valueToNode(value);
      }

      if (!valueNode) {
        throw new Error("Unexpected value ".concat(JSON.stringify(value)));
      }

      this.setFieldNode(path, valueNode);
    }
  }]);

  return ConfigFile;
}();

exports.ConfigFile = ConfigFile;

var loadConfig = function loadConfig(code, fileName) {
  var ast = (0, _babelParse.babelParse)(code);
  return new ConfigFile(ast, code, fileName);
};

exports.loadConfig = loadConfig;

var formatConfig = function formatConfig(config) {
  var _generate3 = (0, _generator.default)(config._ast, {}),
      code = _generate3.code;

  return code;
};

exports.formatConfig = formatConfig;

var readConfig = /*#__PURE__*/function () {
  var _ref4 = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee(fileName) {
    var code;
    return regeneratorRuntime.wrap(function _callee$(_context) {
      while (1) {
        switch (_context.prev = _context.next) {
          case 0:
            _context.next = 2;
            return _fsExtra.default.readFile(fileName, 'utf-8');

          case 2:
            code = _context.sent.toString();
            return _context.abrupt("return", loadConfig(code, fileName).parse());

          case 4:
          case "end":
            return _context.stop();
        }
      }
    }, _callee);
  }));

  return function readConfig(_x) {
    return _ref4.apply(this, arguments);
  };
}();

exports.readConfig = readConfig;

var writeConfig = /*#__PURE__*/function () {
  var _ref5 = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee2(config, fileName) {
    var fname;
    return regeneratorRuntime.wrap(function _callee2$(_context2) {
      while (1) {
        switch (_context2.prev = _context2.next) {
          case 0:
            fname = fileName || config.fileName;

            if (fname) {
              _context2.next = 3;
              break;
            }

            throw new Error('Please specify a fileName for writeConfig');

          case 3:
            _context2.t0 = _fsExtra.default;
            _context2.t1 = fname;
            _context2.next = 7;
            return formatConfig(config);

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

  return function writeConfig(_x2, _x3) {
    return _ref5.apply(this, arguments);
  };
}();

exports.writeConfig = writeConfig;