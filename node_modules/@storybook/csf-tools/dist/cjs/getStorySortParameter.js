"use strict";

function _typeof(obj) { "@babel/helpers - typeof"; return _typeof = "function" == typeof Symbol && "symbol" == typeof Symbol.iterator ? function (obj) { return typeof obj; } : function (obj) { return obj && "function" == typeof Symbol && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; }, _typeof(obj); }

require("core-js/modules/es.array.slice.js");

require("core-js/modules/es.object.freeze.js");

require("core-js/modules/es.array.iterator.js");

require("core-js/modules/es.string.iterator.js");

require("core-js/modules/es.weak-map.js");

require("core-js/modules/web.dom-collections.iterator.js");

require("core-js/modules/es.object.get-own-property-descriptor.js");

require("core-js/modules/es.symbol.js");

require("core-js/modules/es.symbol.description.js");

require("core-js/modules/es.symbol.iterator.js");

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.getStorySortParameter = void 0;

require("core-js/modules/es.object.to-string.js");

require("core-js/modules/web.dom-collections.for-each.js");

require("core-js/modules/es.function.name.js");

require("core-js/modules/es.array.map.js");

require("core-js/modules/es.array.concat.js");

var t = _interopRequireWildcard(require("@babel/types"));

var _traverse = _interopRequireDefault(require("@babel/traverse"));

var _generator = _interopRequireDefault(require("@babel/generator"));

var _tsDedent = _interopRequireDefault(require("ts-dedent"));

var _babelParse = require("./babelParse");

var _templateObject;

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _getRequireWildcardCache(nodeInterop) { if (typeof WeakMap !== "function") return null; var cacheBabelInterop = new WeakMap(); var cacheNodeInterop = new WeakMap(); return (_getRequireWildcardCache = function _getRequireWildcardCache(nodeInterop) { return nodeInterop ? cacheNodeInterop : cacheBabelInterop; })(nodeInterop); }

function _interopRequireWildcard(obj, nodeInterop) { if (!nodeInterop && obj && obj.__esModule) { return obj; } if (obj === null || _typeof(obj) !== "object" && typeof obj !== "function") { return { default: obj }; } var cache = _getRequireWildcardCache(nodeInterop); if (cache && cache.has(obj)) { return cache.get(obj); } var newObj = {}; var hasPropertyDescriptor = Object.defineProperty && Object.getOwnPropertyDescriptor; for (var key in obj) { if (key !== "default" && Object.prototype.hasOwnProperty.call(obj, key)) { var desc = hasPropertyDescriptor ? Object.getOwnPropertyDescriptor(obj, key) : null; if (desc && (desc.get || desc.set)) { Object.defineProperty(newObj, key, desc); } else { newObj[key] = obj[key]; } } } newObj.default = obj; if (cache) { cache.set(obj, newObj); } return newObj; }

function _taggedTemplateLiteral(strings, raw) { if (!raw) { raw = strings.slice(0); } return Object.freeze(Object.defineProperties(strings, { raw: { value: Object.freeze(raw) } })); }

var logger = console;

var getValue = function getValue(obj, key) {
  var value;
  obj.properties.forEach(function (p) {
    if (t.isIdentifier(p.key) && p.key.name === key) {
      value = p.value;
    }
  });
  return value;
};

var parseValue = function parseValue(expr) {
  if (t.isArrayExpression(expr)) {
    return expr.elements.map(function (o) {
      return parseValue(o);
    });
  }

  if (t.isObjectExpression(expr)) {
    return expr.properties.reduce(function (acc, p) {
      if (t.isIdentifier(p.key)) {
        acc[p.key.name] = parseValue(p.value);
      }

      return acc;
    }, {});
  }

  if (t.isLiteral(expr)) {
    // @ts-ignore
    return expr.value;
  }

  throw new Error("Unknown node type ".concat(expr));
};

var unsupported = function unsupported(unexpectedVar, isError) {
  var message = (0, _tsDedent.default)(_templateObject || (_templateObject = _taggedTemplateLiteral(["\n    Unexpected '", "'. Parameter 'options.storySort' should be defined inline e.g.:\n\n    export const parameters = {\n      options: {\n        storySort: <array | object | function>\n      }\n    }\n  "])), unexpectedVar);

  if (isError) {
    throw new Error(message);
  } else {
    logger.info(message);
  }
};

var getStorySortParameter = function getStorySortParameter(previewCode) {
  var storySort;
  var ast = (0, _babelParse.babelParse)(previewCode);
  (0, _traverse.default)(ast, {
    ExportNamedDeclaration: {
      enter: function enter(_ref) {
        var node = _ref.node;

        if (t.isVariableDeclaration(node.declaration)) {
          node.declaration.declarations.forEach(function (decl) {
            if (t.isVariableDeclarator(decl) && t.isIdentifier(decl.id)) {
              var exportName = decl.id.name;

              if (exportName === 'parameters') {
                var paramsObject = t.isTSAsExpression(decl.init) ? decl.init.expression : decl.init;

                if (t.isObjectExpression(paramsObject)) {
                  var options = getValue(paramsObject, 'options');

                  if (options) {
                    if (t.isObjectExpression(options)) {
                      storySort = getValue(options, 'storySort');
                    } else {
                      unsupported('options', true);
                    }
                  }
                } else {
                  unsupported('parameters', true);
                }
              }
            }
          });
        } else {
          node.specifiers.forEach(function (spec) {
            if (t.isIdentifier(spec.exported) && spec.exported.name === 'parameters') {
              unsupported('parameters', false);
            }
          });
        }
      }
    }
  });
  if (!storySort) return undefined;

  if (t.isArrowFunctionExpression(storySort)) {
    var _generate = (0, _generator.default)(storySort, {}),
        sortCode = _generate.code; // eslint-disable-next-line no-eval


    return eval(sortCode);
  }

  if (t.isFunctionExpression(storySort)) {
    var _generate2 = (0, _generator.default)(storySort, {}),
        _sortCode = _generate2.code;

    var functionName = storySort.id.name; // Wrap the function within an arrow function, call it, and return

    var wrapper = "(a, b) => {\n      ".concat(_sortCode, ";\n      return ").concat(functionName, "(a, b)\n    }"); // eslint-disable-next-line no-eval

    return eval(wrapper);
  }

  if (t.isLiteral(storySort) || t.isArrayExpression(storySort) || t.isObjectExpression(storySort)) {
    return parseValue(storySort);
  }

  return unsupported('storySort', true);
};

exports.getStorySortParameter = getStorySortParameter;