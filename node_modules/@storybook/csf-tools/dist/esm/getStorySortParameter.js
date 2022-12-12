import "core-js/modules/es.array.slice.js";
import "core-js/modules/es.object.freeze.js";

var _templateObject;

function _taggedTemplateLiteral(strings, raw) { if (!raw) { raw = strings.slice(0); } return Object.freeze(Object.defineProperties(strings, { raw: { value: Object.freeze(raw) } })); }

import "core-js/modules/es.object.to-string.js";
import "core-js/modules/web.dom-collections.for-each.js";
import "core-js/modules/es.function.name.js";
import "core-js/modules/es.array.map.js";
import "core-js/modules/es.array.concat.js";
import * as t from '@babel/types';
import traverse from '@babel/traverse';
import generate from '@babel/generator';
import dedent from 'ts-dedent';
import { babelParse } from './babelParse';
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
  var message = dedent(_templateObject || (_templateObject = _taggedTemplateLiteral(["\n    Unexpected '", "'. Parameter 'options.storySort' should be defined inline e.g.:\n\n    export const parameters = {\n      options: {\n        storySort: <array | object | function>\n      }\n    }\n  "])), unexpectedVar);

  if (isError) {
    throw new Error(message);
  } else {
    logger.info(message);
  }
};

export var getStorySortParameter = function getStorySortParameter(previewCode) {
  var storySort;
  var ast = babelParse(previewCode);
  traverse(ast, {
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
    var _generate = generate(storySort, {}),
        sortCode = _generate.code; // eslint-disable-next-line no-eval


    return eval(sortCode);
  }

  if (t.isFunctionExpression(storySort)) {
    var _generate2 = generate(storySort, {}),
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