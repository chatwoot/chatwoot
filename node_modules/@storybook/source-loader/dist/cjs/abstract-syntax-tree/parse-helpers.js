"use strict";

require("core-js/modules/es.symbol.js");

require("core-js/modules/es.symbol.description.js");

require("core-js/modules/es.symbol.iterator.js");

require("core-js/modules/es.array.iterator.js");

require("core-js/modules/es.string.iterator.js");

require("core-js/modules/web.dom-collections.iterator.js");

require("core-js/modules/es.array.from.js");

require("core-js/modules/es.regexp.exec.js");

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.asImport = asImport;
exports.handleADD = handleADD;
exports.handleExportedName = handleExportedName;
exports.handleSTORYOF = handleSTORYOF;
exports.patchNode = patchNode;

require("core-js/modules/es.array.slice.js");

require("core-js/modules/es.array.find.js");

require("core-js/modules/es.object.to-string.js");

require("core-js/modules/es.function.name.js");

var _csf = require("@storybook/csf");

function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }

function _slicedToArray(arr, i) { return _arrayWithHoles(arr) || _iterableToArrayLimit(arr, i) || _unsupportedIterableToArray(arr, i) || _nonIterableRest(); }

function _nonIterableRest() { throw new TypeError("Invalid attempt to destructure non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen); }

function _arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

function _iterableToArrayLimit(arr, i) { var _i = arr == null ? null : typeof Symbol !== "undefined" && arr[Symbol.iterator] || arr["@@iterator"]; if (_i == null) return; var _arr = []; var _n = true; var _d = false; var _s, _e; try { for (_i = _i.call(arr); !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"] != null) _i["return"](); } finally { if (_d) throw _e; } } return _arr; }

function _arrayWithHoles(arr) { if (Array.isArray(arr)) return arr; }

var STORIES_OF = 'storiesOf';

function pushParts(source, parts, from, to) {
  var start = source.slice(from, to);
  parts.push(start);
  var end = source.slice(to);
  parts.push(end);
}

function patchNode(node) {
  if (node.range && node.range.length === 2 && node.start === undefined && node.end === undefined) {
    var _node$range = _slicedToArray(node.range, 2),
        start = _node$range[0],
        end = _node$range[1]; // eslint-disable-next-line no-param-reassign


    node.start = start; // eslint-disable-next-line no-param-reassign

    node.end = end;
  }

  if (!node.range && node.start !== undefined && node.end !== undefined) {
    // eslint-disable-next-line no-param-reassign
    node.range = [node.start, node.end];
  }

  return node;
}

function findTemplate(templateName, program) {
  var template = null;
  program.body.find(function (node) {
    var _node$declaration;

    var declarations = null;

    if (node.type === 'VariableDeclaration') {
      declarations = node.declarations;
    } else if (node.type === 'ExportNamedDeclaration' && ((_node$declaration = node.declaration) === null || _node$declaration === void 0 ? void 0 : _node$declaration.type) === 'VariableDeclaration') {
      declarations = node.declaration.declarations;
    }

    return declarations && declarations.find(function (decl) {
      if (decl.type === 'VariableDeclarator' && decl.id.type === 'Identifier' && decl.id.name === templateName) {
        template = decl.init;
        return true; // stop looking
      }

      return false;
    });
  });
  return template;
}

function expandBindExpression(node, parent) {
  if (node.type === 'CallExpression') {
    var callee = node.callee,
        bindArguments = node.arguments;

    if (parent.type === 'Program' && callee.type === 'MemberExpression' && callee.object.type === 'Identifier' && callee.property.type === 'Identifier' && callee.property.name === 'bind' && (bindArguments.length === 0 || bindArguments.length === 1 && bindArguments[0].type === 'ObjectExpression' && bindArguments[0].properties.length === 0)) {
      var boundIdentifier = callee.object.name;
      var template = findTemplate(boundIdentifier, parent);

      if (template) {
        return template;
      }
    }
  }

  return node;
}

function handleExportedName(storyName, originalNode, parent) {
  var node = expandBindExpression(originalNode, parent);
  var startLoc = {
    col: node.loc.start.column,
    line: node.loc.start.line
  };
  var endLoc = {
    col: node.loc.end.column,
    line: node.loc.end.line
  };
  return _defineProperty({}, storyName, {
    startLoc: startLoc,
    endLoc: endLoc,
    startBody: startLoc,
    endBody: endLoc
  });
}

function handleADD(node, parent, storiesOfIdentifiers) {
  if (!node.property || !node.property.name || node.property.name !== 'add') {
    return {};
  }

  var addArgs = parent.arguments;

  if (!addArgs || addArgs.length < 2) {
    return {};
  }

  var tmp = node.object;

  while (tmp.callee && tmp.callee.object) {
    tmp = tmp.callee.object;
  }

  var framework = tmp.callee && tmp.callee.name && storiesOfIdentifiers[tmp.callee.name];
  var storyName = addArgs[0];
  var body = addArgs[1];
  var lastArg = addArgs[addArgs.length - 1];

  if (storyName.type !== 'Literal' && storyName.type !== 'StringLiteral') {
    // if story name is not literal, it's much harder to extract it
    return {};
  }

  if (storyName.value) {
    var key = (0, _csf.sanitize)(storyName.value);
    var idToFramework;

    if (key && framework) {
      idToFramework = _defineProperty({}, key, framework);
    }

    return {
      toAdd: _defineProperty({}, key, {
        // Debug: code: source.slice(storyName.start, lastArg.end),
        startLoc: {
          col: storyName.loc.start.column,
          line: storyName.loc.start.line
        },
        endLoc: {
          col: lastArg.loc.end.column,
          line: lastArg.loc.end.line
        },
        startBody: {
          col: body.loc.start.column,
          line: body.loc.start.line
        },
        endBody: {
          col: body.loc.end.column,
          line: body.loc.end.line
        }
      }),
      idToFramework: idToFramework
    };
  }

  return {};
}

function handleSTORYOF(node, parts, source, lastIndex) {
  if (!node.callee || !node.callee.name || node.callee.name !== STORIES_OF) {
    return lastIndex;
  }

  parts.pop();
  pushParts(source, parts, lastIndex, node.end);
  return node.end;
}

function asImport(node) {
  return node.source.value;
}