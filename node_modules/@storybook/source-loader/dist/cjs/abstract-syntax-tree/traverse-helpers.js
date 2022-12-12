"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.findAddsMap = findAddsMap;
exports.findExportsMap = findExportsMap;
exports.popParametersObjectFromDefaultExport = popParametersObjectFromDefaultExport;
exports.splitExports = splitExports;
exports.splitSTORYOF = splitSTORYOF;

require("core-js/modules/es.function.name.js");

require("core-js/modules/es.array.includes.js");

require("core-js/modules/es.array.find.js");

require("core-js/modules/es.object.to-string.js");

require("core-js/modules/es.array.map.js");

require("core-js/modules/es.object.assign.js");

var _csf = require("@storybook/csf");

var _estraverse = _interopRequireDefault(require("estraverse"));

var _parseHelpers = require("./parse-helpers");

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function splitSTORYOF(ast, source) {
  var lastIndex = 0;
  var parts = [source];

  _estraverse.default.traverse(ast, {
    fallback: 'iteration',
    enter: function enter(node) {
      (0, _parseHelpers.patchNode)(node);

      if (node.type === 'CallExpression') {
        lastIndex = (0, _parseHelpers.handleSTORYOF)(node, parts, source, lastIndex);
      }
    }
  });

  return parts;
}

function isFunctionVariable(declarations, includeExclude) {
  return declarations && declarations.length === 1 && declarations[0].type === 'VariableDeclarator' && declarations[0].id && declarations[0].id.name && declarations[0].init && ['CallExpression', 'ArrowFunctionExpression', 'FunctionExpression'].includes(declarations[0].init.type) && (0, _csf.isExportStory)(declarations[0].id.name, includeExclude);
}

function isFunctionDeclaration(declaration, includeExclude) {
  return declaration.type === 'FunctionDeclaration' && declaration.id && declaration.id.name && (0, _csf.isExportStory)(declaration.id.name, includeExclude);
}

function getDescriptor(metaDeclaration, propertyName) {
  var property = metaDeclaration && metaDeclaration.declaration && metaDeclaration.declaration.properties.find(function (p) {
    return p.key && p.key.name === propertyName;
  });

  if (!property) {
    return undefined;
  }

  var type = property.value.type;

  switch (type) {
    case 'ArrayExpression':
      return property.value.elements.map(function (t) {
        if (!['StringLiteral', 'Literal'].includes(t.type)) {
          throw new Error("Unexpected descriptor element: ".concat(t.type));
        }

        return t.value;
      });

    case 'Literal':
    case 'RegExpLiteral':
      return property.value.value;

    default:
      throw new Error("Unexpected descriptor: ".concat(type));
  }
}

function findIncludeExclude(ast) {
  var program = ast && ast.program || ast;
  var metaDeclaration = program && program.body && program.body.find(function (d) {
    return d.type === 'ExportDefaultDeclaration' && d.declaration.type === 'ObjectExpression' && (d.declaration.properties || []).length;
  });
  var includeStories = getDescriptor(metaDeclaration, 'includeStories');
  var excludeStories = getDescriptor(metaDeclaration, 'excludeStories');
  return {
    includeStories: includeStories,
    excludeStories: excludeStories
  };
}

function splitExports(ast, source) {
  var parts = [];
  var lastIndex = 0;
  var includeExclude = findIncludeExclude(ast);

  _estraverse.default.traverse(ast, {
    fallback: 'iteration',
    enter: function enter(node) {
      (0, _parseHelpers.patchNode)(node);
      var isNamedExport = node.type === 'ExportNamedDeclaration' && node.declaration;
      var isFunctionVariableExport = isNamedExport && isFunctionVariable(node.declaration.declarations, includeExclude);
      var isFunctionDeclarationExport = isNamedExport && isFunctionDeclaration(node.declaration, includeExclude);

      if (isFunctionDeclarationExport || isFunctionVariableExport) {
        var functionNode = isFunctionVariableExport ? node.declaration.declarations[0].init : node.declaration;
        parts.push({
          source: source.substring(lastIndex, functionNode.start - 1)
        });
        parts.push({
          source: source.substring(functionNode.start, functionNode.end),
          declaration: {
            isVariableDeclaration: isFunctionVariableExport,
            ident: isFunctionVariableExport ? node.declaration.declarations[0].id.name : functionNode.id.name
          }
        });
        lastIndex = functionNode.end;
      }
    }
  });

  if (source.length > lastIndex + 1) parts.push({
    source: source.substring(lastIndex + 1)
  });
  if (parts.length === 1) return [source];
  return parts;
}

function findAddsMap(ast, storiesOfIdentifiers) {
  var addsMap = {};

  _estraverse.default.traverse(ast, {
    fallback: 'iteration',
    enter: function enter(node, parent) {
      (0, _parseHelpers.patchNode)(node);

      if (node.type === 'MemberExpression') {
        var _handleADD = (0, _parseHelpers.handleADD)(node, parent, storiesOfIdentifiers),
            toAdd = _handleADD.toAdd,
            idToFramework = _handleADD.idToFramework;

        Object.assign(addsMap, toAdd);
      }
    }
  });

  return addsMap;
}

function findExportsMap(ast) {
  var addsMap = {};

  _estraverse.default.traverse(ast, {
    fallback: 'iteration',
    enter: function enter(node, parent) {
      (0, _parseHelpers.patchNode)(node);
      var isNamedExport = node.type === 'ExportNamedDeclaration' && node.declaration;
      var isFunctionVariableExport = isNamedExport && node.declaration.declarations && node.declaration.declarations.length === 1 && node.declaration.declarations[0].type === 'VariableDeclarator' && node.declaration.declarations[0].id && node.declaration.declarations[0].id.name && node.declaration.declarations[0].init && ['CallExpression', 'ArrowFunctionExpression', 'FunctionExpression'].includes(node.declaration.declarations[0].init.type);
      var isFunctionDeclarationExport = isNamedExport && node.declaration.type === 'FunctionDeclaration' && node.declaration.id && node.declaration.id.name;

      if (isFunctionDeclarationExport || isFunctionVariableExport) {
        var exportDeclaration = isFunctionVariableExport ? node.declaration.declarations[0] : node.declaration;
        var toAdd = (0, _parseHelpers.handleExportedName)(exportDeclaration.id.name, exportDeclaration.init || exportDeclaration, parent);
        Object.assign(addsMap, toAdd);
      }
    }
  });

  return addsMap;
}

function popParametersObjectFromDefaultExport(source, ast) {
  var splicedSource = source;
  var parametersSliceOfCode = '';
  var indexWhereToAppend = -1;
  var foundParametersProperty = false;

  _estraverse.default.traverse(ast, {
    fallback: 'iteration',
    enter: function enter(node) {
      var _node$declaration, _node$declaration2, _node$declaration3;

      (0, _parseHelpers.patchNode)(node);
      var isDefaultExport = node.type === 'ExportDefaultDeclaration';
      var isObjectExpression = ((_node$declaration = node.declaration) === null || _node$declaration === void 0 ? void 0 : _node$declaration.type) === 'ObjectExpression';
      var isTsAsExpression = ((_node$declaration2 = node.declaration) === null || _node$declaration2 === void 0 ? void 0 : _node$declaration2.type) === 'TSAsExpression';
      var targetNode = isObjectExpression ? node.declaration : (_node$declaration3 = node.declaration) === null || _node$declaration3 === void 0 ? void 0 : _node$declaration3.expression;

      if (isDefaultExport && (isObjectExpression || isTsAsExpression) && (targetNode.properties || []).length) {
        var parametersProperty = targetNode.properties.find(function (p) {
          return p.key.name === 'parameters' && p.value.type === 'ObjectExpression';
        });
        foundParametersProperty = !!parametersProperty;

        if (foundParametersProperty) {
          (0, _parseHelpers.patchNode)(parametersProperty.value);
        } else {
          (0, _parseHelpers.patchNode)(targetNode);
        }

        splicedSource = parametersProperty ? source.substring(0, parametersProperty.value.start) + source.substring(parametersProperty.value.end + 1) : splicedSource;
        parametersSliceOfCode = parametersProperty ? source.substring(parametersProperty.value.start, parametersProperty.value.end) : '{}';
        indexWhereToAppend = parametersProperty ? parametersProperty.value.start : targetNode.start + 1;
      }
    }
  });

  return {
    splicedSource: splicedSource,
    parametersSliceOfCode: parametersSliceOfCode,
    indexWhereToAppend: indexWhereToAppend,
    foundParametersProperty: foundParametersProperty
  };
}