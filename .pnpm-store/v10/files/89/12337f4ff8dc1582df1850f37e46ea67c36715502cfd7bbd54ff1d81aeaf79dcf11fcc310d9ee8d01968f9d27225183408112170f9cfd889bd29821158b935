'use strict';var _slicedToArray = function () {function sliceIterator(arr, i) {var _arr = [];var _n = true;var _d = false;var _e = undefined;try {for (var _i = arr[Symbol.iterator](), _s; !(_n = (_s = _i.next()).done); _n = true) {_arr.push(_s.value);if (i && _arr.length === i) break;}} catch (err) {_d = true;_e = err;} finally {try {if (!_n && _i["return"]) _i["return"]();} finally {if (_d) throw _e;}}return _arr;}return function (arr, i) {if (Array.isArray(arr)) {return arr;} else if (Symbol.iterator in Object(arr)) {return sliceIterator(arr, i);} else {throw new TypeError("Invalid attempt to destructure non-iterable instance");}};}();var _resolve = require('eslint-module-utils/resolve');var _resolve2 = _interopRequireDefault(_resolve);
var _semver = require('semver');var _semver2 = _interopRequireDefault(_semver);
var _arrayPrototype = require('array.prototype.flatmap');var _arrayPrototype2 = _interopRequireDefault(_arrayPrototype);

var _docsUrl = require('../docsUrl');var _docsUrl2 = _interopRequireDefault(_docsUrl);function _interopRequireDefault(obj) {return obj && obj.__esModule ? obj : { 'default': obj };}function _toArray(arr) {return Array.isArray(arr) ? arr : Array.from(arr);}

var typescriptPkg = void 0;
try {
  typescriptPkg = require('typescript/package.json'); // eslint-disable-line import/no-extraneous-dependencies
} catch (e) {/**/}

function isPunctuator(node, value) {
  return node.type === 'Punctuator' && node.value === value;
}

// Get the name of the default import of `node`, if any.
function getDefaultImportName(node) {
  var defaultSpecifier = node.specifiers.
  find(function (specifier) {return specifier.type === 'ImportDefaultSpecifier';});
  return defaultSpecifier != null ? defaultSpecifier.local.name : undefined;
}

// Checks whether `node` has a namespace import.
function hasNamespace(node) {
  var specifiers = node.specifiers.
  filter(function (specifier) {return specifier.type === 'ImportNamespaceSpecifier';});
  return specifiers.length > 0;
}

// Checks whether `node` has any non-default specifiers.
function hasSpecifiers(node) {
  var specifiers = node.specifiers.
  filter(function (specifier) {return specifier.type === 'ImportSpecifier';});
  return specifiers.length > 0;
}

// Checks whether `node` has a comment (that ends) on the previous line or on
// the same line as `node` (starts).
function hasCommentBefore(node, sourceCode) {
  return sourceCode.getCommentsBefore(node).
  some(function (comment) {return comment.loc.end.line >= node.loc.start.line - 1;});
}

// Checks whether `node` has a comment (that starts) on the same line as `node`
// (ends).
function hasCommentAfter(node, sourceCode) {
  return sourceCode.getCommentsAfter(node).
  some(function (comment) {return comment.loc.start.line === node.loc.end.line;});
}

// Checks whether `node` has any comments _inside,_ except inside the `{...}`
// part (if any).
function hasCommentInsideNonSpecifiers(node, sourceCode) {
  var tokens = sourceCode.getTokens(node);
  var openBraceIndex = tokens.findIndex(function (token) {return isPunctuator(token, '{');});
  var closeBraceIndex = tokens.findIndex(function (token) {return isPunctuator(token, '}');});
  // Slice away the first token, since we're no looking for comments _before_
  // `node` (only inside). If there's a `{...}` part, look for comments before
  // the `{`, but not before the `}` (hence the `+1`s).
  var someTokens = openBraceIndex >= 0 && closeBraceIndex >= 0 ?
  tokens.slice(1, openBraceIndex + 1).concat(tokens.slice(closeBraceIndex + 1)) :
  tokens.slice(1);
  return someTokens.some(function (token) {return sourceCode.getCommentsBefore(token).length > 0;});
}

// It's not obvious what the user wants to do with comments associated with
// duplicate imports, so skip imports with comments when autofixing.
function hasProblematicComments(node, sourceCode) {
  return (
    hasCommentBefore(node, sourceCode) ||
    hasCommentAfter(node, sourceCode) ||
    hasCommentInsideNonSpecifiers(node, sourceCode));

}

function getFix(first, rest, sourceCode, context) {
  // Sorry ESLint <= 3 users, no autofix for you. Autofixing duplicate imports
  // requires multiple `fixer.whatever()` calls in the `fix`: We both need to
  // update the first one, and remove the rest. Support for multiple
  // `fixer.whatever()` in a single `fix` was added in ESLint 4.1.
  // `sourceCode.getCommentsBefore` was added in 4.0, so that's an easy thing to
  // check for.
  if (typeof sourceCode.getCommentsBefore !== 'function') {
    return undefined;
  }

  // Adjusting the first import might make it multiline, which could break
  // `eslint-disable-next-line` comments and similar, so bail if the first
  // import has comments. Also, if the first import is `import * as ns from
  // './foo'` there's nothing we can do.
  if (hasProblematicComments(first, sourceCode) || hasNamespace(first)) {
    return undefined;
  }

  var defaultImportNames = new Set(
  (0, _arrayPrototype2['default'])([].concat(first, rest || []), function (x) {return getDefaultImportName(x) || [];}));


  // Bail if there are multiple different default import names – it's up to the
  // user to choose which one to keep.
  if (defaultImportNames.size > 1) {
    return undefined;
  }

  // Leave it to the user to handle comments. Also skip `import * as ns from
  // './foo'` imports, since they cannot be merged into another import.
  var restWithoutComments = rest.filter(function (node) {return !hasProblematicComments(node, sourceCode) && !hasNamespace(node);});

  var specifiers = restWithoutComments.
  map(function (node) {
    var tokens = sourceCode.getTokens(node);
    var openBrace = tokens.find(function (token) {return isPunctuator(token, '{');});
    var closeBrace = tokens.find(function (token) {return isPunctuator(token, '}');});

    if (openBrace == null || closeBrace == null) {
      return undefined;
    }

    return {
      importNode: node,
      identifiers: sourceCode.text.slice(openBrace.range[1], closeBrace.range[0]).split(','), // Split the text into separate identifiers (retaining any whitespace before or after)
      isEmpty: !hasSpecifiers(node) };

  }).
  filter(Boolean);

  var unnecessaryImports = restWithoutComments.filter(function (node) {return !hasSpecifiers(node) &&
    !hasNamespace(node) &&
    !specifiers.some(function (specifier) {return specifier.importNode === node;});});


  var shouldAddDefault = getDefaultImportName(first) == null && defaultImportNames.size === 1;
  var shouldAddSpecifiers = specifiers.length > 0;
  var shouldRemoveUnnecessary = unnecessaryImports.length > 0;
  var preferInline = context.options[0] && context.options[0]['prefer-inline'];

  if (!(shouldAddDefault || shouldAddSpecifiers || shouldRemoveUnnecessary)) {
    return undefined;
  }

  return function (fixer) {
    var tokens = sourceCode.getTokens(first);
    var openBrace = tokens.find(function (token) {return isPunctuator(token, '{');});
    var closeBrace = tokens.find(function (token) {return isPunctuator(token, '}');});
    var firstToken = sourceCode.getFirstToken(first);var _defaultImportNames = _slicedToArray(
    defaultImportNames, 1),defaultImportName = _defaultImportNames[0];

    var firstHasTrailingComma = closeBrace != null && isPunctuator(sourceCode.getTokenBefore(closeBrace), ',');
    var firstIsEmpty = !hasSpecifiers(first);
    var firstExistingIdentifiers = firstIsEmpty ?
    new Set() :
    new Set(sourceCode.text.slice(openBrace.range[1], closeBrace.range[0]).
    split(',').
    map(function (x) {return x.trim();}));var _specifiers$reduce =


    specifiers.reduce(
    function (_ref, specifier) {var _ref2 = _slicedToArray(_ref, 3),result = _ref2[0],needsComma = _ref2[1],existingIdentifiers = _ref2[2];
      var isTypeSpecifier = specifier.importNode.importKind === 'type';

      // a user might set prefer-inline but not have a supporting TypeScript version. Flow does not support inline types so this should fail in that case as well.
      if (preferInline && (!typescriptPkg || !_semver2['default'].satisfies(typescriptPkg.version, '>= 4.5'))) {
        throw new Error('Your version of TypeScript does not support inline type imports.');
      }

      // Add *only* the new identifiers that don't already exist, and track any new identifiers so we don't add them again in the next loop
      var _specifier$identifier = specifier.identifiers.reduce(function (_ref3, cur) {var _ref4 = _slicedToArray(_ref3, 2),text = _ref4[0],set = _ref4[1];
        var trimmed = cur.trim(); // Trim whitespace before/after to compare to our set of existing identifiers
        var curWithType = trimmed.length > 0 && preferInline && isTypeSpecifier ? 'type ' + String(cur) : cur;
        if (existingIdentifiers.has(trimmed)) {
          return [text, set];
        }
        return [text.length > 0 ? String(text) + ',' + String(curWithType) : curWithType, set.add(trimmed)];
      }, ['', existingIdentifiers]),_specifier$identifier2 = _slicedToArray(_specifier$identifier, 2),specifierText = _specifier$identifier2[0],updatedExistingIdentifiers = _specifier$identifier2[1];

      return [
      needsComma && !specifier.isEmpty && specifierText.length > 0 ? String(
      result) + ',' + String(specifierText) : '' + String(
      result) + String(specifierText),
      specifier.isEmpty ? needsComma : true,
      updatedExistingIdentifiers];

    },
    ['', !firstHasTrailingComma && !firstIsEmpty, firstExistingIdentifiers]),_specifiers$reduce2 = _slicedToArray(_specifiers$reduce, 1),specifiersText = _specifiers$reduce2[0];


    var fixes = [];

    if (shouldAddSpecifiers && preferInline && first.importKind === 'type') {
      // `import type {a} from './foo'` → `import {type a} from './foo'`
      var typeIdentifierToken = tokens.find(function (token) {return token.type === 'Identifier' && token.value === 'type';});
      fixes.push(fixer.removeRange([typeIdentifierToken.range[0], typeIdentifierToken.range[1] + 1]));

      tokens.
      filter(function (token) {return firstExistingIdentifiers.has(token.value);}).
      forEach(function (identifier) {
        fixes.push(fixer.replaceTextRange([identifier.range[0], identifier.range[1]], 'type ' + String(identifier.value)));
      });
    }

    if (shouldAddDefault && openBrace == null && shouldAddSpecifiers) {
      // `import './foo'` → `import def, {...} from './foo'`
      fixes.push(
      fixer.insertTextAfter(firstToken, ' ' + String(defaultImportName) + ', {' + String(specifiersText) + '} from'));

    } else if (shouldAddDefault && openBrace == null && !shouldAddSpecifiers) {
      // `import './foo'` → `import def from './foo'`
      fixes.push(fixer.insertTextAfter(firstToken, ' ' + String(defaultImportName) + ' from'));
    } else if (shouldAddDefault && openBrace != null && closeBrace != null) {
      // `import {...} from './foo'` → `import def, {...} from './foo'`
      fixes.push(fixer.insertTextAfter(firstToken, ' ' + String(defaultImportName) + ','));
      if (shouldAddSpecifiers) {
        // `import def, {...} from './foo'` → `import def, {..., ...} from './foo'`
        fixes.push(fixer.insertTextBefore(closeBrace, specifiersText));
      }
    } else if (!shouldAddDefault && openBrace == null && shouldAddSpecifiers) {
      if (first.specifiers.length === 0) {
        // `import './foo'` → `import {...} from './foo'`
        fixes.push(fixer.insertTextAfter(firstToken, ' {' + String(specifiersText) + '} from'));
      } else {
        // `import def from './foo'` → `import def, {...} from './foo'`
        fixes.push(fixer.insertTextAfter(first.specifiers[0], ', {' + String(specifiersText) + '}'));
      }
    } else if (!shouldAddDefault && openBrace != null && closeBrace != null) {
      // `import {...} './foo'` → `import {..., ...} from './foo'`
      fixes.push(fixer.insertTextBefore(closeBrace, specifiersText));
    }

    // Remove imports whose specifiers have been moved into the first import.
    var _iteratorNormalCompletion = true;var _didIteratorError = false;var _iteratorError = undefined;try {for (var _iterator = specifiers[Symbol.iterator](), _step; !(_iteratorNormalCompletion = (_step = _iterator.next()).done); _iteratorNormalCompletion = true) {var specifier = _step.value;
        var importNode = specifier.importNode;
        fixes.push(fixer.remove(importNode));

        var charAfterImportRange = [importNode.range[1], importNode.range[1] + 1];
        var charAfterImport = sourceCode.text.substring(charAfterImportRange[0], charAfterImportRange[1]);
        if (charAfterImport === '\n') {
          fixes.push(fixer.removeRange(charAfterImportRange));
        }
      }

      // Remove imports whose default import has been moved to the first import,
      // and side-effect-only imports that are unnecessary due to the first
      // import.
    } catch (err) {_didIteratorError = true;_iteratorError = err;} finally {try {if (!_iteratorNormalCompletion && _iterator['return']) {_iterator['return']();}} finally {if (_didIteratorError) {throw _iteratorError;}}}var _iteratorNormalCompletion2 = true;var _didIteratorError2 = false;var _iteratorError2 = undefined;try {for (var _iterator2 = unnecessaryImports[Symbol.iterator](), _step2; !(_iteratorNormalCompletion2 = (_step2 = _iterator2.next()).done); _iteratorNormalCompletion2 = true) {var node = _step2.value;
        fixes.push(fixer.remove(node));

        var charAfterImportRange = [node.range[1], node.range[1] + 1];
        var charAfterImport = sourceCode.text.substring(charAfterImportRange[0], charAfterImportRange[1]);
        if (charAfterImport === '\n') {
          fixes.push(fixer.removeRange(charAfterImportRange));
        }
      }} catch (err) {_didIteratorError2 = true;_iteratorError2 = err;} finally {try {if (!_iteratorNormalCompletion2 && _iterator2['return']) {_iterator2['return']();}} finally {if (_didIteratorError2) {throw _iteratorError2;}}}

    return fixes;
  };
}

function checkImports(imported, context) {var _iteratorNormalCompletion3 = true;var _didIteratorError3 = false;var _iteratorError3 = undefined;try {
    for (var _iterator3 = imported.entries()[Symbol.iterator](), _step3; !(_iteratorNormalCompletion3 = (_step3 = _iterator3.next()).done); _iteratorNormalCompletion3 = true) {var _ref5 = _step3.value;var _ref6 = _slicedToArray(_ref5, 2);var _module = _ref6[0];var nodes = _ref6[1];
      if (nodes.length > 1) {
        var message = '\'' + String(_module) + '\' imported multiple times.';var _nodes = _toArray(
        nodes),first = _nodes[0],rest = _nodes.slice(1);
        var sourceCode = context.getSourceCode();
        var fix = getFix(first, rest, sourceCode, context);

        context.report({
          node: first.source,
          message: message,
          fix: fix // Attach the autofix (if any) to the first import.
        });var _iteratorNormalCompletion4 = true;var _didIteratorError4 = false;var _iteratorError4 = undefined;try {

          for (var _iterator4 = rest[Symbol.iterator](), _step4; !(_iteratorNormalCompletion4 = (_step4 = _iterator4.next()).done); _iteratorNormalCompletion4 = true) {var node = _step4.value;
            context.report({
              node: node.source,
              message: message });

          }} catch (err) {_didIteratorError4 = true;_iteratorError4 = err;} finally {try {if (!_iteratorNormalCompletion4 && _iterator4['return']) {_iterator4['return']();}} finally {if (_didIteratorError4) {throw _iteratorError4;}}}
      }
    }} catch (err) {_didIteratorError3 = true;_iteratorError3 = err;} finally {try {if (!_iteratorNormalCompletion3 && _iterator3['return']) {_iterator3['return']();}} finally {if (_didIteratorError3) {throw _iteratorError3;}}}
}

module.exports = {
  meta: {
    type: 'problem',
    docs: {
      category: 'Style guide',
      description: 'Forbid repeated import of the same module in multiple places.',
      url: (0, _docsUrl2['default'])('no-duplicates') },

    fixable: 'code',
    schema: [
    {
      type: 'object',
      properties: {
        considerQueryString: {
          type: 'boolean' },

        'prefer-inline': {
          type: 'boolean' } },


      additionalProperties: false }] },




  create: function () {function create(context) {
      // Prepare the resolver from options.
      var considerQueryStringOption = context.options[0] &&
      context.options[0].considerQueryString;
      var defaultResolver = function () {function defaultResolver(sourcePath) {return (0, _resolve2['default'])(sourcePath, context) || sourcePath;}return defaultResolver;}();
      var resolver = considerQueryStringOption ? function (sourcePath) {
        var parts = sourcePath.match(/^([^?]*)\?(.*)$/);
        if (!parts) {
          return defaultResolver(sourcePath);
        }
        return String(defaultResolver(parts[1])) + '?' + String(parts[2]);
      } : defaultResolver;

      var moduleMaps = new Map();

      function getImportMap(n) {
        if (!moduleMaps.has(n.parent)) {
          moduleMaps.set(n.parent, {
            imported: new Map(),
            nsImported: new Map(),
            defaultTypesImported: new Map(),
            namedTypesImported: new Map() });

        }
        var map = moduleMaps.get(n.parent);
        var preferInline = context.options[0] && context.options[0]['prefer-inline'];
        if (!preferInline && n.importKind === 'type') {
          return n.specifiers.length > 0 && n.specifiers[0].type === 'ImportDefaultSpecifier' ? map.defaultTypesImported : map.namedTypesImported;
        }
        if (!preferInline && n.specifiers.some(function (spec) {return spec.importKind === 'type';})) {
          return map.namedTypesImported;
        }

        return hasNamespace(n) ? map.nsImported : map.imported;
      }

      return {
        ImportDeclaration: function () {function ImportDeclaration(n) {
            // resolved path will cover aliased duplicates
            var resolvedPath = resolver(n.source.value);
            var importMap = getImportMap(n);

            if (importMap.has(resolvedPath)) {
              importMap.get(resolvedPath).push(n);
            } else {
              importMap.set(resolvedPath, [n]);
            }
          }return ImportDeclaration;}(),

        'Program:exit': function () {function ProgramExit() {var _iteratorNormalCompletion5 = true;var _didIteratorError5 = false;var _iteratorError5 = undefined;try {
              for (var _iterator5 = moduleMaps.values()[Symbol.iterator](), _step5; !(_iteratorNormalCompletion5 = (_step5 = _iterator5.next()).done); _iteratorNormalCompletion5 = true) {var map = _step5.value;
                checkImports(map.imported, context);
                checkImports(map.nsImported, context);
                checkImports(map.defaultTypesImported, context);
                checkImports(map.namedTypesImported, context);
              }} catch (err) {_didIteratorError5 = true;_iteratorError5 = err;} finally {try {if (!_iteratorNormalCompletion5 && _iterator5['return']) {_iterator5['return']();}} finally {if (_didIteratorError5) {throw _iteratorError5;}}}
          }return ProgramExit;}() };

    }return create;}() };
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIi4uLy4uL3NyYy9ydWxlcy9uby1kdXBsaWNhdGVzLmpzIl0sIm5hbWVzIjpbInR5cGVzY3JpcHRQa2ciLCJyZXF1aXJlIiwiZSIsImlzUHVuY3R1YXRvciIsIm5vZGUiLCJ2YWx1ZSIsInR5cGUiLCJnZXREZWZhdWx0SW1wb3J0TmFtZSIsImRlZmF1bHRTcGVjaWZpZXIiLCJzcGVjaWZpZXJzIiwiZmluZCIsInNwZWNpZmllciIsImxvY2FsIiwibmFtZSIsInVuZGVmaW5lZCIsImhhc05hbWVzcGFjZSIsImZpbHRlciIsImxlbmd0aCIsImhhc1NwZWNpZmllcnMiLCJoYXNDb21tZW50QmVmb3JlIiwic291cmNlQ29kZSIsImdldENvbW1lbnRzQmVmb3JlIiwic29tZSIsImNvbW1lbnQiLCJsb2MiLCJlbmQiLCJsaW5lIiwic3RhcnQiLCJoYXNDb21tZW50QWZ0ZXIiLCJnZXRDb21tZW50c0FmdGVyIiwiaGFzQ29tbWVudEluc2lkZU5vblNwZWNpZmllcnMiLCJ0b2tlbnMiLCJnZXRUb2tlbnMiLCJvcGVuQnJhY2VJbmRleCIsImZpbmRJbmRleCIsInRva2VuIiwiY2xvc2VCcmFjZUluZGV4Iiwic29tZVRva2VucyIsInNsaWNlIiwiY29uY2F0IiwiaGFzUHJvYmxlbWF0aWNDb21tZW50cyIsImdldEZpeCIsImZpcnN0IiwicmVzdCIsImNvbnRleHQiLCJkZWZhdWx0SW1wb3J0TmFtZXMiLCJTZXQiLCJ4Iiwic2l6ZSIsInJlc3RXaXRob3V0Q29tbWVudHMiLCJtYXAiLCJvcGVuQnJhY2UiLCJjbG9zZUJyYWNlIiwiaW1wb3J0Tm9kZSIsImlkZW50aWZpZXJzIiwidGV4dCIsInJhbmdlIiwic3BsaXQiLCJpc0VtcHR5IiwiQm9vbGVhbiIsInVubmVjZXNzYXJ5SW1wb3J0cyIsInNob3VsZEFkZERlZmF1bHQiLCJzaG91bGRBZGRTcGVjaWZpZXJzIiwic2hvdWxkUmVtb3ZlVW5uZWNlc3NhcnkiLCJwcmVmZXJJbmxpbmUiLCJvcHRpb25zIiwiZml4ZXIiLCJmaXJzdFRva2VuIiwiZ2V0Rmlyc3RUb2tlbiIsImRlZmF1bHRJbXBvcnROYW1lIiwiZmlyc3RIYXNUcmFpbGluZ0NvbW1hIiwiZ2V0VG9rZW5CZWZvcmUiLCJmaXJzdElzRW1wdHkiLCJmaXJzdEV4aXN0aW5nSWRlbnRpZmllcnMiLCJ0cmltIiwicmVkdWNlIiwicmVzdWx0IiwibmVlZHNDb21tYSIsImV4aXN0aW5nSWRlbnRpZmllcnMiLCJpc1R5cGVTcGVjaWZpZXIiLCJpbXBvcnRLaW5kIiwic2VtdmVyIiwic2F0aXNmaWVzIiwidmVyc2lvbiIsIkVycm9yIiwiY3VyIiwic2V0IiwidHJpbW1lZCIsImN1cldpdGhUeXBlIiwiaGFzIiwiYWRkIiwic3BlY2lmaWVyVGV4dCIsInVwZGF0ZWRFeGlzdGluZ0lkZW50aWZpZXJzIiwic3BlY2lmaWVyc1RleHQiLCJmaXhlcyIsInR5cGVJZGVudGlmaWVyVG9rZW4iLCJwdXNoIiwicmVtb3ZlUmFuZ2UiLCJmb3JFYWNoIiwiaWRlbnRpZmllciIsInJlcGxhY2VUZXh0UmFuZ2UiLCJpbnNlcnRUZXh0QWZ0ZXIiLCJpbnNlcnRUZXh0QmVmb3JlIiwicmVtb3ZlIiwiY2hhckFmdGVySW1wb3J0UmFuZ2UiLCJjaGFyQWZ0ZXJJbXBvcnQiLCJzdWJzdHJpbmciLCJjaGVja0ltcG9ydHMiLCJpbXBvcnRlZCIsImVudHJpZXMiLCJtb2R1bGUiLCJub2RlcyIsIm1lc3NhZ2UiLCJnZXRTb3VyY2VDb2RlIiwiZml4IiwicmVwb3J0Iiwic291cmNlIiwiZXhwb3J0cyIsIm1ldGEiLCJkb2NzIiwiY2F0ZWdvcnkiLCJkZXNjcmlwdGlvbiIsInVybCIsImZpeGFibGUiLCJzY2hlbWEiLCJwcm9wZXJ0aWVzIiwiY29uc2lkZXJRdWVyeVN0cmluZyIsImFkZGl0aW9uYWxQcm9wZXJ0aWVzIiwiY3JlYXRlIiwiY29uc2lkZXJRdWVyeVN0cmluZ09wdGlvbiIsImRlZmF1bHRSZXNvbHZlciIsInNvdXJjZVBhdGgiLCJyZXNvbHZlciIsInBhcnRzIiwibWF0Y2giLCJtb2R1bGVNYXBzIiwiTWFwIiwiZ2V0SW1wb3J0TWFwIiwibiIsInBhcmVudCIsIm5zSW1wb3J0ZWQiLCJkZWZhdWx0VHlwZXNJbXBvcnRlZCIsIm5hbWVkVHlwZXNJbXBvcnRlZCIsImdldCIsInNwZWMiLCJJbXBvcnREZWNsYXJhdGlvbiIsInJlc29sdmVkUGF0aCIsImltcG9ydE1hcCIsInZhbHVlcyJdLCJtYXBwaW5ncyI6InFvQkFBQSxzRDtBQUNBLGdDO0FBQ0EseUQ7O0FBRUEscUM7O0FBRUEsSUFBSUEsc0JBQUo7QUFDQSxJQUFJO0FBQ0ZBLGtCQUFnQkMsUUFBUSx5QkFBUixDQUFoQixDQURFLENBQ2tEO0FBQ3JELENBRkQsQ0FFRSxPQUFPQyxDQUFQLEVBQVUsQ0FBRSxJQUFNOztBQUVwQixTQUFTQyxZQUFULENBQXNCQyxJQUF0QixFQUE0QkMsS0FBNUIsRUFBbUM7QUFDakMsU0FBT0QsS0FBS0UsSUFBTCxLQUFjLFlBQWQsSUFBOEJGLEtBQUtDLEtBQUwsS0FBZUEsS0FBcEQ7QUFDRDs7QUFFRDtBQUNBLFNBQVNFLG9CQUFULENBQThCSCxJQUE5QixFQUFvQztBQUNsQyxNQUFNSSxtQkFBbUJKLEtBQUtLLFVBQUw7QUFDdEJDLE1BRHNCLENBQ2pCLFVBQUNDLFNBQUQsVUFBZUEsVUFBVUwsSUFBVixLQUFtQix3QkFBbEMsRUFEaUIsQ0FBekI7QUFFQSxTQUFPRSxvQkFBb0IsSUFBcEIsR0FBMkJBLGlCQUFpQkksS0FBakIsQ0FBdUJDLElBQWxELEdBQXlEQyxTQUFoRTtBQUNEOztBQUVEO0FBQ0EsU0FBU0MsWUFBVCxDQUFzQlgsSUFBdEIsRUFBNEI7QUFDMUIsTUFBTUssYUFBYUwsS0FBS0ssVUFBTDtBQUNoQk8sUUFEZ0IsQ0FDVCxVQUFDTCxTQUFELFVBQWVBLFVBQVVMLElBQVYsS0FBbUIsMEJBQWxDLEVBRFMsQ0FBbkI7QUFFQSxTQUFPRyxXQUFXUSxNQUFYLEdBQW9CLENBQTNCO0FBQ0Q7O0FBRUQ7QUFDQSxTQUFTQyxhQUFULENBQXVCZCxJQUF2QixFQUE2QjtBQUMzQixNQUFNSyxhQUFhTCxLQUFLSyxVQUFMO0FBQ2hCTyxRQURnQixDQUNULFVBQUNMLFNBQUQsVUFBZUEsVUFBVUwsSUFBVixLQUFtQixpQkFBbEMsRUFEUyxDQUFuQjtBQUVBLFNBQU9HLFdBQVdRLE1BQVgsR0FBb0IsQ0FBM0I7QUFDRDs7QUFFRDtBQUNBO0FBQ0EsU0FBU0UsZ0JBQVQsQ0FBMEJmLElBQTFCLEVBQWdDZ0IsVUFBaEMsRUFBNEM7QUFDMUMsU0FBT0EsV0FBV0MsaUJBQVgsQ0FBNkJqQixJQUE3QjtBQUNKa0IsTUFESSxDQUNDLFVBQUNDLE9BQUQsVUFBYUEsUUFBUUMsR0FBUixDQUFZQyxHQUFaLENBQWdCQyxJQUFoQixJQUF3QnRCLEtBQUtvQixHQUFMLENBQVNHLEtBQVQsQ0FBZUQsSUFBZixHQUFzQixDQUEzRCxFQURELENBQVA7QUFFRDs7QUFFRDtBQUNBO0FBQ0EsU0FBU0UsZUFBVCxDQUF5QnhCLElBQXpCLEVBQStCZ0IsVUFBL0IsRUFBMkM7QUFDekMsU0FBT0EsV0FBV1MsZ0JBQVgsQ0FBNEJ6QixJQUE1QjtBQUNKa0IsTUFESSxDQUNDLFVBQUNDLE9BQUQsVUFBYUEsUUFBUUMsR0FBUixDQUFZRyxLQUFaLENBQWtCRCxJQUFsQixLQUEyQnRCLEtBQUtvQixHQUFMLENBQVNDLEdBQVQsQ0FBYUMsSUFBckQsRUFERCxDQUFQO0FBRUQ7O0FBRUQ7QUFDQTtBQUNBLFNBQVNJLDZCQUFULENBQXVDMUIsSUFBdkMsRUFBNkNnQixVQUE3QyxFQUF5RDtBQUN2RCxNQUFNVyxTQUFTWCxXQUFXWSxTQUFYLENBQXFCNUIsSUFBckIsQ0FBZjtBQUNBLE1BQU02QixpQkFBaUJGLE9BQU9HLFNBQVAsQ0FBaUIsVUFBQ0MsS0FBRCxVQUFXaEMsYUFBYWdDLEtBQWIsRUFBb0IsR0FBcEIsQ0FBWCxFQUFqQixDQUF2QjtBQUNBLE1BQU1DLGtCQUFrQkwsT0FBT0csU0FBUCxDQUFpQixVQUFDQyxLQUFELFVBQVdoQyxhQUFhZ0MsS0FBYixFQUFvQixHQUFwQixDQUFYLEVBQWpCLENBQXhCO0FBQ0E7QUFDQTtBQUNBO0FBQ0EsTUFBTUUsYUFBYUosa0JBQWtCLENBQWxCLElBQXVCRyxtQkFBbUIsQ0FBMUM7QUFDZkwsU0FBT08sS0FBUCxDQUFhLENBQWIsRUFBZ0JMLGlCQUFpQixDQUFqQyxFQUFvQ00sTUFBcEMsQ0FBMkNSLE9BQU9PLEtBQVAsQ0FBYUYsa0JBQWtCLENBQS9CLENBQTNDLENBRGU7QUFFZkwsU0FBT08sS0FBUCxDQUFhLENBQWIsQ0FGSjtBQUdBLFNBQU9ELFdBQVdmLElBQVgsQ0FBZ0IsVUFBQ2EsS0FBRCxVQUFXZixXQUFXQyxpQkFBWCxDQUE2QmMsS0FBN0IsRUFBb0NsQixNQUFwQyxHQUE2QyxDQUF4RCxFQUFoQixDQUFQO0FBQ0Q7O0FBRUQ7QUFDQTtBQUNBLFNBQVN1QixzQkFBVCxDQUFnQ3BDLElBQWhDLEVBQXNDZ0IsVUFBdEMsRUFBa0Q7QUFDaEQ7QUFDRUQscUJBQWlCZixJQUFqQixFQUF1QmdCLFVBQXZCO0FBQ0dRLG9CQUFnQnhCLElBQWhCLEVBQXNCZ0IsVUFBdEIsQ0FESDtBQUVHVSxrQ0FBOEIxQixJQUE5QixFQUFvQ2dCLFVBQXBDLENBSEw7O0FBS0Q7O0FBRUQsU0FBU3FCLE1BQVQsQ0FBZ0JDLEtBQWhCLEVBQXVCQyxJQUF2QixFQUE2QnZCLFVBQTdCLEVBQXlDd0IsT0FBekMsRUFBa0Q7QUFDaEQ7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0EsTUFBSSxPQUFPeEIsV0FBV0MsaUJBQWxCLEtBQXdDLFVBQTVDLEVBQXdEO0FBQ3RELFdBQU9QLFNBQVA7QUFDRDs7QUFFRDtBQUNBO0FBQ0E7QUFDQTtBQUNBLE1BQUkwQix1QkFBdUJFLEtBQXZCLEVBQThCdEIsVUFBOUIsS0FBNkNMLGFBQWEyQixLQUFiLENBQWpELEVBQXNFO0FBQ3BFLFdBQU81QixTQUFQO0FBQ0Q7O0FBRUQsTUFBTStCLHFCQUFxQixJQUFJQyxHQUFKO0FBQ3pCLG1DQUFRLEdBQUdQLE1BQUgsQ0FBVUcsS0FBVixFQUFpQkMsUUFBUSxFQUF6QixDQUFSLEVBQXNDLFVBQUNJLENBQUQsVUFBT3hDLHFCQUFxQndDLENBQXJCLEtBQTJCLEVBQWxDLEVBQXRDLENBRHlCLENBQTNCOzs7QUFJQTtBQUNBO0FBQ0EsTUFBSUYsbUJBQW1CRyxJQUFuQixHQUEwQixDQUE5QixFQUFpQztBQUMvQixXQUFPbEMsU0FBUDtBQUNEOztBQUVEO0FBQ0E7QUFDQSxNQUFNbUMsc0JBQXNCTixLQUFLM0IsTUFBTCxDQUFZLFVBQUNaLElBQUQsVUFBVSxDQUFDb0MsdUJBQXVCcEMsSUFBdkIsRUFBNkJnQixVQUE3QixDQUFELElBQTZDLENBQUNMLGFBQWFYLElBQWIsQ0FBeEQsRUFBWixDQUE1Qjs7QUFFQSxNQUFNSyxhQUFhd0M7QUFDaEJDLEtBRGdCLENBQ1osVUFBQzlDLElBQUQsRUFBVTtBQUNiLFFBQU0yQixTQUFTWCxXQUFXWSxTQUFYLENBQXFCNUIsSUFBckIsQ0FBZjtBQUNBLFFBQU0rQyxZQUFZcEIsT0FBT3JCLElBQVAsQ0FBWSxVQUFDeUIsS0FBRCxVQUFXaEMsYUFBYWdDLEtBQWIsRUFBb0IsR0FBcEIsQ0FBWCxFQUFaLENBQWxCO0FBQ0EsUUFBTWlCLGFBQWFyQixPQUFPckIsSUFBUCxDQUFZLFVBQUN5QixLQUFELFVBQVdoQyxhQUFhZ0MsS0FBYixFQUFvQixHQUFwQixDQUFYLEVBQVosQ0FBbkI7O0FBRUEsUUFBSWdCLGFBQWEsSUFBYixJQUFxQkMsY0FBYyxJQUF2QyxFQUE2QztBQUMzQyxhQUFPdEMsU0FBUDtBQUNEOztBQUVELFdBQU87QUFDTHVDLGtCQUFZakQsSUFEUDtBQUVMa0QsbUJBQWFsQyxXQUFXbUMsSUFBWCxDQUFnQmpCLEtBQWhCLENBQXNCYSxVQUFVSyxLQUFWLENBQWdCLENBQWhCLENBQXRCLEVBQTBDSixXQUFXSSxLQUFYLENBQWlCLENBQWpCLENBQTFDLEVBQStEQyxLQUEvRCxDQUFxRSxHQUFyRSxDQUZSLEVBRW1GO0FBQ3hGQyxlQUFTLENBQUN4QyxjQUFjZCxJQUFkLENBSEwsRUFBUDs7QUFLRCxHQWZnQjtBQWdCaEJZLFFBaEJnQixDQWdCVDJDLE9BaEJTLENBQW5COztBQWtCQSxNQUFNQyxxQkFBcUJYLG9CQUFvQmpDLE1BQXBCLENBQTJCLFVBQUNaLElBQUQsVUFBVSxDQUFDYyxjQUFjZCxJQUFkLENBQUQ7QUFDM0QsS0FBQ1csYUFBYVgsSUFBYixDQUQwRDtBQUUzRCxLQUFDSyxXQUFXYSxJQUFYLENBQWdCLFVBQUNYLFNBQUQsVUFBZUEsVUFBVTBDLFVBQVYsS0FBeUJqRCxJQUF4QyxFQUFoQixDQUZnRCxFQUEzQixDQUEzQjs7O0FBS0EsTUFBTXlELG1CQUFtQnRELHFCQUFxQm1DLEtBQXJCLEtBQStCLElBQS9CLElBQXVDRyxtQkFBbUJHLElBQW5CLEtBQTRCLENBQTVGO0FBQ0EsTUFBTWMsc0JBQXNCckQsV0FBV1EsTUFBWCxHQUFvQixDQUFoRDtBQUNBLE1BQU04QywwQkFBMEJILG1CQUFtQjNDLE1BQW5CLEdBQTRCLENBQTVEO0FBQ0EsTUFBTStDLGVBQWVwQixRQUFRcUIsT0FBUixDQUFnQixDQUFoQixLQUFzQnJCLFFBQVFxQixPQUFSLENBQWdCLENBQWhCLEVBQW1CLGVBQW5CLENBQTNDOztBQUVBLE1BQUksRUFBRUosb0JBQW9CQyxtQkFBcEIsSUFBMkNDLHVCQUE3QyxDQUFKLEVBQTJFO0FBQ3pFLFdBQU9qRCxTQUFQO0FBQ0Q7O0FBRUQsU0FBTyxVQUFDb0QsS0FBRCxFQUFXO0FBQ2hCLFFBQU1uQyxTQUFTWCxXQUFXWSxTQUFYLENBQXFCVSxLQUFyQixDQUFmO0FBQ0EsUUFBTVMsWUFBWXBCLE9BQU9yQixJQUFQLENBQVksVUFBQ3lCLEtBQUQsVUFBV2hDLGFBQWFnQyxLQUFiLEVBQW9CLEdBQXBCLENBQVgsRUFBWixDQUFsQjtBQUNBLFFBQU1pQixhQUFhckIsT0FBT3JCLElBQVAsQ0FBWSxVQUFDeUIsS0FBRCxVQUFXaEMsYUFBYWdDLEtBQWIsRUFBb0IsR0FBcEIsQ0FBWCxFQUFaLENBQW5CO0FBQ0EsUUFBTWdDLGFBQWEvQyxXQUFXZ0QsYUFBWCxDQUF5QjFCLEtBQXpCLENBQW5CLENBSmdCO0FBS1lHLHNCQUxaLEtBS1R3QixpQkFMUzs7QUFPaEIsUUFBTUMsd0JBQXdCbEIsY0FBYyxJQUFkLElBQXNCakQsYUFBYWlCLFdBQVdtRCxjQUFYLENBQTBCbkIsVUFBMUIsQ0FBYixFQUFvRCxHQUFwRCxDQUFwRDtBQUNBLFFBQU1vQixlQUFlLENBQUN0RCxjQUFjd0IsS0FBZCxDQUF0QjtBQUNBLFFBQU0rQiwyQkFBMkJEO0FBQzdCLFFBQUkxQixHQUFKLEVBRDZCO0FBRTdCLFFBQUlBLEdBQUosQ0FBUTFCLFdBQVdtQyxJQUFYLENBQWdCakIsS0FBaEIsQ0FBc0JhLFVBQVVLLEtBQVYsQ0FBZ0IsQ0FBaEIsQ0FBdEIsRUFBMENKLFdBQVdJLEtBQVgsQ0FBaUIsQ0FBakIsQ0FBMUM7QUFDUEMsU0FETyxDQUNELEdBREM7QUFFUFAsT0FGTyxDQUVILFVBQUNILENBQUQsVUFBT0EsRUFBRTJCLElBQUYsRUFBUCxFQUZHLENBQVIsQ0FGSixDQVRnQjs7O0FBZ0JTakUsZUFBV2tFLE1BQVg7QUFDdkIsb0JBQTRDaEUsU0FBNUMsRUFBMEQscUNBQXhEaUUsTUFBd0QsWUFBaERDLFVBQWdELFlBQXBDQyxtQkFBb0M7QUFDeEQsVUFBTUMsa0JBQWtCcEUsVUFBVTBDLFVBQVYsQ0FBcUIyQixVQUFyQixLQUFvQyxNQUE1RDs7QUFFQTtBQUNBLFVBQUloQixpQkFBaUIsQ0FBQ2hFLGFBQUQsSUFBa0IsQ0FBQ2lGLG9CQUFPQyxTQUFQLENBQWlCbEYsY0FBY21GLE9BQS9CLEVBQXdDLFFBQXhDLENBQXBDLENBQUosRUFBNEY7QUFDMUYsY0FBTSxJQUFJQyxLQUFKLENBQVUsa0VBQVYsQ0FBTjtBQUNEOztBQUVEO0FBUndELGtDQVNKekUsVUFBVTJDLFdBQVYsQ0FBc0JxQixNQUF0QixDQUE2QixpQkFBY1UsR0FBZCxFQUFzQixzQ0FBcEI5QixJQUFvQixZQUFkK0IsR0FBYztBQUNyRyxZQUFNQyxVQUFVRixJQUFJWCxJQUFKLEVBQWhCLENBRHFHLENBQ3pFO0FBQzVCLFlBQU1jLGNBQWNELFFBQVF0RSxNQUFSLEdBQWlCLENBQWpCLElBQXNCK0MsWUFBdEIsSUFBc0NlLGVBQXRDLG9CQUFnRU0sR0FBaEUsSUFBd0VBLEdBQTVGO0FBQ0EsWUFBSVAsb0JBQW9CVyxHQUFwQixDQUF3QkYsT0FBeEIsQ0FBSixFQUFzQztBQUNwQyxpQkFBTyxDQUFDaEMsSUFBRCxFQUFPK0IsR0FBUCxDQUFQO0FBQ0Q7QUFDRCxlQUFPLENBQUMvQixLQUFLdEMsTUFBTCxHQUFjLENBQWQsVUFBcUJzQyxJQUFyQixpQkFBNkJpQyxXQUE3QixJQUE2Q0EsV0FBOUMsRUFBMkRGLElBQUlJLEdBQUosQ0FBUUgsT0FBUixDQUEzRCxDQUFQO0FBQ0QsT0FQbUQsRUFPakQsQ0FBQyxFQUFELEVBQUtULG1CQUFMLENBUGlELENBVEksbUVBU2pEYSxhQVRpRCw2QkFTbENDLDBCQVRrQzs7QUFrQnhELGFBQU87QUFDTGYsb0JBQWMsQ0FBQ2xFLFVBQVUrQyxPQUF6QixJQUFvQ2lDLGNBQWMxRSxNQUFkLEdBQXVCLENBQTNEO0FBQ08yRCxZQURQLGlCQUNpQmUsYUFEakI7QUFFT2YsWUFGUCxXQUVnQmUsYUFGaEIsQ0FESztBQUlMaEYsZ0JBQVUrQyxPQUFWLEdBQW9CbUIsVUFBcEIsR0FBaUMsSUFKNUI7QUFLTGUsZ0NBTEssQ0FBUDs7QUFPRCxLQTFCc0I7QUEyQnZCLEtBQUMsRUFBRCxFQUFLLENBQUN0QixxQkFBRCxJQUEwQixDQUFDRSxZQUFoQyxFQUE4Q0Msd0JBQTlDLENBM0J1QixDQWhCVCw2REFnQlRvQixjQWhCUzs7O0FBOENoQixRQUFNQyxRQUFRLEVBQWQ7O0FBRUEsUUFBSWhDLHVCQUF1QkUsWUFBdkIsSUFBdUN0QixNQUFNc0MsVUFBTixLQUFxQixNQUFoRSxFQUF3RTtBQUN0RTtBQUNBLFVBQU1lLHNCQUFzQmhFLE9BQU9yQixJQUFQLENBQVksVUFBQ3lCLEtBQUQsVUFBV0EsTUFBTTdCLElBQU4sS0FBZSxZQUFmLElBQStCNkIsTUFBTTlCLEtBQU4sS0FBZ0IsTUFBMUQsRUFBWixDQUE1QjtBQUNBeUYsWUFBTUUsSUFBTixDQUFXOUIsTUFBTStCLFdBQU4sQ0FBa0IsQ0FBQ0Ysb0JBQW9CdkMsS0FBcEIsQ0FBMEIsQ0FBMUIsQ0FBRCxFQUErQnVDLG9CQUFvQnZDLEtBQXBCLENBQTBCLENBQTFCLElBQStCLENBQTlELENBQWxCLENBQVg7O0FBRUF6QjtBQUNHZixZQURILENBQ1UsVUFBQ21CLEtBQUQsVUFBV3NDLHlCQUF5QmdCLEdBQXpCLENBQTZCdEQsTUFBTTlCLEtBQW5DLENBQVgsRUFEVjtBQUVHNkYsYUFGSCxDQUVXLFVBQUNDLFVBQUQsRUFBZ0I7QUFDdkJMLGNBQU1FLElBQU4sQ0FBVzlCLE1BQU1rQyxnQkFBTixDQUF1QixDQUFDRCxXQUFXM0MsS0FBWCxDQUFpQixDQUFqQixDQUFELEVBQXNCMkMsV0FBVzNDLEtBQVgsQ0FBaUIsQ0FBakIsQ0FBdEIsQ0FBdkIsbUJBQTJFMkMsV0FBVzlGLEtBQXRGLEVBQVg7QUFDRCxPQUpIO0FBS0Q7O0FBRUQsUUFBSXdELG9CQUFvQlYsYUFBYSxJQUFqQyxJQUF5Q1csbUJBQTdDLEVBQWtFO0FBQ2hFO0FBQ0FnQyxZQUFNRSxJQUFOO0FBQ0U5QixZQUFNbUMsZUFBTixDQUFzQmxDLFVBQXRCLGVBQXNDRSxpQkFBdEMsbUJBQTZEd0IsY0FBN0QsYUFERjs7QUFHRCxLQUxELE1BS08sSUFBSWhDLG9CQUFvQlYsYUFBYSxJQUFqQyxJQUF5QyxDQUFDVyxtQkFBOUMsRUFBbUU7QUFDeEU7QUFDQWdDLFlBQU1FLElBQU4sQ0FBVzlCLE1BQU1tQyxlQUFOLENBQXNCbEMsVUFBdEIsZUFBc0NFLGlCQUF0QyxZQUFYO0FBQ0QsS0FITSxNQUdBLElBQUlSLG9CQUFvQlYsYUFBYSxJQUFqQyxJQUF5Q0MsY0FBYyxJQUEzRCxFQUFpRTtBQUN0RTtBQUNBMEMsWUFBTUUsSUFBTixDQUFXOUIsTUFBTW1DLGVBQU4sQ0FBc0JsQyxVQUF0QixlQUFzQ0UsaUJBQXRDLFFBQVg7QUFDQSxVQUFJUCxtQkFBSixFQUF5QjtBQUN2QjtBQUNBZ0MsY0FBTUUsSUFBTixDQUFXOUIsTUFBTW9DLGdCQUFOLENBQXVCbEQsVUFBdkIsRUFBbUN5QyxjQUFuQyxDQUFYO0FBQ0Q7QUFDRixLQVBNLE1BT0EsSUFBSSxDQUFDaEMsZ0JBQUQsSUFBcUJWLGFBQWEsSUFBbEMsSUFBMENXLG1CQUE5QyxFQUFtRTtBQUN4RSxVQUFJcEIsTUFBTWpDLFVBQU4sQ0FBaUJRLE1BQWpCLEtBQTRCLENBQWhDLEVBQW1DO0FBQ2pDO0FBQ0E2RSxjQUFNRSxJQUFOLENBQVc5QixNQUFNbUMsZUFBTixDQUFzQmxDLFVBQXRCLGdCQUF1QzBCLGNBQXZDLGFBQVg7QUFDRCxPQUhELE1BR087QUFDTDtBQUNBQyxjQUFNRSxJQUFOLENBQVc5QixNQUFNbUMsZUFBTixDQUFzQjNELE1BQU1qQyxVQUFOLENBQWlCLENBQWpCLENBQXRCLGlCQUFpRG9GLGNBQWpELFFBQVg7QUFDRDtBQUNGLEtBUk0sTUFRQSxJQUFJLENBQUNoQyxnQkFBRCxJQUFxQlYsYUFBYSxJQUFsQyxJQUEwQ0MsY0FBYyxJQUE1RCxFQUFrRTtBQUN2RTtBQUNBMEMsWUFBTUUsSUFBTixDQUFXOUIsTUFBTW9DLGdCQUFOLENBQXVCbEQsVUFBdkIsRUFBbUN5QyxjQUFuQyxDQUFYO0FBQ0Q7O0FBRUQ7QUF4RmdCLDJHQXlGaEIscUJBQXdCcEYsVUFBeEIsOEhBQW9DLEtBQXpCRSxTQUF5QjtBQUNsQyxZQUFNMEMsYUFBYTFDLFVBQVUwQyxVQUE3QjtBQUNBeUMsY0FBTUUsSUFBTixDQUFXOUIsTUFBTXFDLE1BQU4sQ0FBYWxELFVBQWIsQ0FBWDs7QUFFQSxZQUFNbUQsdUJBQXVCLENBQUNuRCxXQUFXRyxLQUFYLENBQWlCLENBQWpCLENBQUQsRUFBc0JILFdBQVdHLEtBQVgsQ0FBaUIsQ0FBakIsSUFBc0IsQ0FBNUMsQ0FBN0I7QUFDQSxZQUFNaUQsa0JBQWtCckYsV0FBV21DLElBQVgsQ0FBZ0JtRCxTQUFoQixDQUEwQkYscUJBQXFCLENBQXJCLENBQTFCLEVBQW1EQSxxQkFBcUIsQ0FBckIsQ0FBbkQsQ0FBeEI7QUFDQSxZQUFJQyxvQkFBb0IsSUFBeEIsRUFBOEI7QUFDNUJYLGdCQUFNRSxJQUFOLENBQVc5QixNQUFNK0IsV0FBTixDQUFrQk8sb0JBQWxCLENBQVg7QUFDRDtBQUNGOztBQUVEO0FBQ0E7QUFDQTtBQXRHZ0IscVVBdUdoQixzQkFBbUI1QyxrQkFBbkIsbUlBQXVDLEtBQTVCeEQsSUFBNEI7QUFDckMwRixjQUFNRSxJQUFOLENBQVc5QixNQUFNcUMsTUFBTixDQUFhbkcsSUFBYixDQUFYOztBQUVBLFlBQU1vRyx1QkFBdUIsQ0FBQ3BHLEtBQUtvRCxLQUFMLENBQVcsQ0FBWCxDQUFELEVBQWdCcEQsS0FBS29ELEtBQUwsQ0FBVyxDQUFYLElBQWdCLENBQWhDLENBQTdCO0FBQ0EsWUFBTWlELGtCQUFrQnJGLFdBQVdtQyxJQUFYLENBQWdCbUQsU0FBaEIsQ0FBMEJGLHFCQUFxQixDQUFyQixDQUExQixFQUFtREEscUJBQXFCLENBQXJCLENBQW5ELENBQXhCO0FBQ0EsWUFBSUMsb0JBQW9CLElBQXhCLEVBQThCO0FBQzVCWCxnQkFBTUUsSUFBTixDQUFXOUIsTUFBTStCLFdBQU4sQ0FBa0JPLG9CQUFsQixDQUFYO0FBQ0Q7QUFDRixPQS9HZTs7QUFpSGhCLFdBQU9WLEtBQVA7QUFDRCxHQWxIRDtBQW1IRDs7QUFFRCxTQUFTYSxZQUFULENBQXNCQyxRQUF0QixFQUFnQ2hFLE9BQWhDLEVBQXlDO0FBQ3ZDLDBCQUE4QmdFLFNBQVNDLE9BQVQsRUFBOUIsbUlBQWtELG1FQUF0Q0MsT0FBc0MsZ0JBQTlCQyxLQUE4QjtBQUNoRCxVQUFJQSxNQUFNOUYsTUFBTixHQUFlLENBQW5CLEVBQXNCO0FBQ3BCLFlBQU0rRix3QkFBY0YsT0FBZCxpQ0FBTixDQURvQjtBQUVLQyxhQUZMLEVBRWJyRSxLQUZhLGFBRUhDLElBRkc7QUFHcEIsWUFBTXZCLGFBQWF3QixRQUFRcUUsYUFBUixFQUFuQjtBQUNBLFlBQU1DLE1BQU16RSxPQUFPQyxLQUFQLEVBQWNDLElBQWQsRUFBb0J2QixVQUFwQixFQUFnQ3dCLE9BQWhDLENBQVo7O0FBRUFBLGdCQUFRdUUsTUFBUixDQUFlO0FBQ2IvRyxnQkFBTXNDLE1BQU0wRSxNQURDO0FBRWJKLDBCQUZhO0FBR2JFLGtCQUhhLENBR1I7QUFIUSxTQUFmLEVBTm9COztBQVlwQixnQ0FBbUJ2RSxJQUFuQixtSUFBeUIsS0FBZHZDLElBQWM7QUFDdkJ3QyxvQkFBUXVFLE1BQVIsQ0FBZTtBQUNiL0csb0JBQU1BLEtBQUtnSCxNQURFO0FBRWJKLDhCQUZhLEVBQWY7O0FBSUQsV0FqQm1CO0FBa0JyQjtBQUNGLEtBckJzQztBQXNCeEM7O0FBRURGLE9BQU9PLE9BQVAsR0FBaUI7QUFDZkMsUUFBTTtBQUNKaEgsVUFBTSxTQURGO0FBRUppSCxVQUFNO0FBQ0pDLGdCQUFVLGFBRE47QUFFSkMsbUJBQWEsK0RBRlQ7QUFHSkMsV0FBSywwQkFBUSxlQUFSLENBSEQsRUFGRjs7QUFPSkMsYUFBUyxNQVBMO0FBUUpDLFlBQVE7QUFDTjtBQUNFdEgsWUFBTSxRQURSO0FBRUV1SCxrQkFBWTtBQUNWQyw2QkFBcUI7QUFDbkJ4SCxnQkFBTSxTQURhLEVBRFg7O0FBSVYseUJBQWlCO0FBQ2ZBLGdCQUFNLFNBRFMsRUFKUCxFQUZkOzs7QUFVRXlILDRCQUFzQixLQVZ4QixFQURNLENBUkosRUFEUzs7Ozs7QUF5QmZDLFFBekJlLCtCQXlCUnBGLE9BekJRLEVBeUJDO0FBQ2Q7QUFDQSxVQUFNcUYsNEJBQTRCckYsUUFBUXFCLE9BQVIsQ0FBZ0IsQ0FBaEI7QUFDN0JyQixjQUFRcUIsT0FBUixDQUFnQixDQUFoQixFQUFtQjZELG1CQUR4QjtBQUVBLFVBQU1JLCtCQUFrQixTQUFsQkEsZUFBa0IsQ0FBQ0MsVUFBRCxVQUFnQiwwQkFBUUEsVUFBUixFQUFvQnZGLE9BQXBCLEtBQWdDdUYsVUFBaEQsRUFBbEIsMEJBQU47QUFDQSxVQUFNQyxXQUFXSCw0QkFBNEIsVUFBQ0UsVUFBRCxFQUFnQjtBQUMzRCxZQUFNRSxRQUFRRixXQUFXRyxLQUFYLENBQWlCLGlCQUFqQixDQUFkO0FBQ0EsWUFBSSxDQUFDRCxLQUFMLEVBQVk7QUFDVixpQkFBT0gsZ0JBQWdCQyxVQUFoQixDQUFQO0FBQ0Q7QUFDRCxzQkFBVUQsZ0JBQWdCRyxNQUFNLENBQU4sQ0FBaEIsQ0FBVixpQkFBdUNBLE1BQU0sQ0FBTixDQUF2QztBQUNELE9BTmdCLEdBTWJILGVBTko7O0FBUUEsVUFBTUssYUFBYSxJQUFJQyxHQUFKLEVBQW5COztBQUVBLGVBQVNDLFlBQVQsQ0FBc0JDLENBQXRCLEVBQXlCO0FBQ3ZCLFlBQUksQ0FBQ0gsV0FBVzlDLEdBQVgsQ0FBZWlELEVBQUVDLE1BQWpCLENBQUwsRUFBK0I7QUFDN0JKLHFCQUFXakQsR0FBWCxDQUFlb0QsRUFBRUMsTUFBakIsRUFBeUI7QUFDdkIvQixzQkFBVSxJQUFJNEIsR0FBSixFQURhO0FBRXZCSSx3QkFBWSxJQUFJSixHQUFKLEVBRlc7QUFHdkJLLGtDQUFzQixJQUFJTCxHQUFKLEVBSEM7QUFJdkJNLGdDQUFvQixJQUFJTixHQUFKLEVBSkcsRUFBekI7O0FBTUQ7QUFDRCxZQUFNdEYsTUFBTXFGLFdBQVdRLEdBQVgsQ0FBZUwsRUFBRUMsTUFBakIsQ0FBWjtBQUNBLFlBQU0zRSxlQUFlcEIsUUFBUXFCLE9BQVIsQ0FBZ0IsQ0FBaEIsS0FBc0JyQixRQUFRcUIsT0FBUixDQUFnQixDQUFoQixFQUFtQixlQUFuQixDQUEzQztBQUNBLFlBQUksQ0FBQ0QsWUFBRCxJQUFpQjBFLEVBQUUxRCxVQUFGLEtBQWlCLE1BQXRDLEVBQThDO0FBQzVDLGlCQUFPMEQsRUFBRWpJLFVBQUYsQ0FBYVEsTUFBYixHQUFzQixDQUF0QixJQUEyQnlILEVBQUVqSSxVQUFGLENBQWEsQ0FBYixFQUFnQkgsSUFBaEIsS0FBeUIsd0JBQXBELEdBQStFNEMsSUFBSTJGLG9CQUFuRixHQUEwRzNGLElBQUk0RixrQkFBckg7QUFDRDtBQUNELFlBQUksQ0FBQzlFLFlBQUQsSUFBaUIwRSxFQUFFakksVUFBRixDQUFhYSxJQUFiLENBQWtCLFVBQUMwSCxJQUFELFVBQVVBLEtBQUtoRSxVQUFMLEtBQW9CLE1BQTlCLEVBQWxCLENBQXJCLEVBQThFO0FBQzVFLGlCQUFPOUIsSUFBSTRGLGtCQUFYO0FBQ0Q7O0FBRUQsZUFBTy9ILGFBQWEySCxDQUFiLElBQWtCeEYsSUFBSTBGLFVBQXRCLEdBQW1DMUYsSUFBSTBELFFBQTlDO0FBQ0Q7O0FBRUQsYUFBTztBQUNMcUMseUJBREssMENBQ2FQLENBRGIsRUFDZ0I7QUFDbkI7QUFDQSxnQkFBTVEsZUFBZWQsU0FBU00sRUFBRXRCLE1BQUYsQ0FBUy9HLEtBQWxCLENBQXJCO0FBQ0EsZ0JBQU04SSxZQUFZVixhQUFhQyxDQUFiLENBQWxCOztBQUVBLGdCQUFJUyxVQUFVMUQsR0FBVixDQUFjeUQsWUFBZCxDQUFKLEVBQWlDO0FBQy9CQyx3QkFBVUosR0FBVixDQUFjRyxZQUFkLEVBQTRCbEQsSUFBNUIsQ0FBaUMwQyxDQUFqQztBQUNELGFBRkQsTUFFTztBQUNMUyx3QkFBVTdELEdBQVYsQ0FBYzRELFlBQWQsRUFBNEIsQ0FBQ1IsQ0FBRCxDQUE1QjtBQUNEO0FBQ0YsV0FYSTs7QUFhTCxzQkFiSyxzQ0FhWTtBQUNmLG9DQUFrQkgsV0FBV2EsTUFBWCxFQUFsQixtSUFBdUMsS0FBNUJsRyxHQUE0QjtBQUNyQ3lELDZCQUFhekQsSUFBSTBELFFBQWpCLEVBQTJCaEUsT0FBM0I7QUFDQStELDZCQUFhekQsSUFBSTBGLFVBQWpCLEVBQTZCaEcsT0FBN0I7QUFDQStELDZCQUFhekQsSUFBSTJGLG9CQUFqQixFQUF1Q2pHLE9BQXZDO0FBQ0ErRCw2QkFBYXpELElBQUk0RixrQkFBakIsRUFBcUNsRyxPQUFyQztBQUNELGVBTmM7QUFPaEIsV0FwQkksd0JBQVA7O0FBc0JELEtBbkZjLG1CQUFqQiIsImZpbGUiOiJuby1kdXBsaWNhdGVzLmpzIiwic291cmNlc0NvbnRlbnQiOlsiaW1wb3J0IHJlc29sdmUgZnJvbSAnZXNsaW50LW1vZHVsZS11dGlscy9yZXNvbHZlJztcbmltcG9ydCBzZW12ZXIgZnJvbSAnc2VtdmVyJztcbmltcG9ydCBmbGF0TWFwIGZyb20gJ2FycmF5LnByb3RvdHlwZS5mbGF0bWFwJztcblxuaW1wb3J0IGRvY3NVcmwgZnJvbSAnLi4vZG9jc1VybCc7XG5cbmxldCB0eXBlc2NyaXB0UGtnO1xudHJ5IHtcbiAgdHlwZXNjcmlwdFBrZyA9IHJlcXVpcmUoJ3R5cGVzY3JpcHQvcGFja2FnZS5qc29uJyk7IC8vIGVzbGludC1kaXNhYmxlLWxpbmUgaW1wb3J0L25vLWV4dHJhbmVvdXMtZGVwZW5kZW5jaWVzXG59IGNhdGNoIChlKSB7IC8qKi8gfVxuXG5mdW5jdGlvbiBpc1B1bmN0dWF0b3Iobm9kZSwgdmFsdWUpIHtcbiAgcmV0dXJuIG5vZGUudHlwZSA9PT0gJ1B1bmN0dWF0b3InICYmIG5vZGUudmFsdWUgPT09IHZhbHVlO1xufVxuXG4vLyBHZXQgdGhlIG5hbWUgb2YgdGhlIGRlZmF1bHQgaW1wb3J0IG9mIGBub2RlYCwgaWYgYW55LlxuZnVuY3Rpb24gZ2V0RGVmYXVsdEltcG9ydE5hbWUobm9kZSkge1xuICBjb25zdCBkZWZhdWx0U3BlY2lmaWVyID0gbm9kZS5zcGVjaWZpZXJzXG4gICAgLmZpbmQoKHNwZWNpZmllcikgPT4gc3BlY2lmaWVyLnR5cGUgPT09ICdJbXBvcnREZWZhdWx0U3BlY2lmaWVyJyk7XG4gIHJldHVybiBkZWZhdWx0U3BlY2lmaWVyICE9IG51bGwgPyBkZWZhdWx0U3BlY2lmaWVyLmxvY2FsLm5hbWUgOiB1bmRlZmluZWQ7XG59XG5cbi8vIENoZWNrcyB3aGV0aGVyIGBub2RlYCBoYXMgYSBuYW1lc3BhY2UgaW1wb3J0LlxuZnVuY3Rpb24gaGFzTmFtZXNwYWNlKG5vZGUpIHtcbiAgY29uc3Qgc3BlY2lmaWVycyA9IG5vZGUuc3BlY2lmaWVyc1xuICAgIC5maWx0ZXIoKHNwZWNpZmllcikgPT4gc3BlY2lmaWVyLnR5cGUgPT09ICdJbXBvcnROYW1lc3BhY2VTcGVjaWZpZXInKTtcbiAgcmV0dXJuIHNwZWNpZmllcnMubGVuZ3RoID4gMDtcbn1cblxuLy8gQ2hlY2tzIHdoZXRoZXIgYG5vZGVgIGhhcyBhbnkgbm9uLWRlZmF1bHQgc3BlY2lmaWVycy5cbmZ1bmN0aW9uIGhhc1NwZWNpZmllcnMobm9kZSkge1xuICBjb25zdCBzcGVjaWZpZXJzID0gbm9kZS5zcGVjaWZpZXJzXG4gICAgLmZpbHRlcigoc3BlY2lmaWVyKSA9PiBzcGVjaWZpZXIudHlwZSA9PT0gJ0ltcG9ydFNwZWNpZmllcicpO1xuICByZXR1cm4gc3BlY2lmaWVycy5sZW5ndGggPiAwO1xufVxuXG4vLyBDaGVja3Mgd2hldGhlciBgbm9kZWAgaGFzIGEgY29tbWVudCAodGhhdCBlbmRzKSBvbiB0aGUgcHJldmlvdXMgbGluZSBvciBvblxuLy8gdGhlIHNhbWUgbGluZSBhcyBgbm9kZWAgKHN0YXJ0cykuXG5mdW5jdGlvbiBoYXNDb21tZW50QmVmb3JlKG5vZGUsIHNvdXJjZUNvZGUpIHtcbiAgcmV0dXJuIHNvdXJjZUNvZGUuZ2V0Q29tbWVudHNCZWZvcmUobm9kZSlcbiAgICAuc29tZSgoY29tbWVudCkgPT4gY29tbWVudC5sb2MuZW5kLmxpbmUgPj0gbm9kZS5sb2Muc3RhcnQubGluZSAtIDEpO1xufVxuXG4vLyBDaGVja3Mgd2hldGhlciBgbm9kZWAgaGFzIGEgY29tbWVudCAodGhhdCBzdGFydHMpIG9uIHRoZSBzYW1lIGxpbmUgYXMgYG5vZGVgXG4vLyAoZW5kcykuXG5mdW5jdGlvbiBoYXNDb21tZW50QWZ0ZXIobm9kZSwgc291cmNlQ29kZSkge1xuICByZXR1cm4gc291cmNlQ29kZS5nZXRDb21tZW50c0FmdGVyKG5vZGUpXG4gICAgLnNvbWUoKGNvbW1lbnQpID0+IGNvbW1lbnQubG9jLnN0YXJ0LmxpbmUgPT09IG5vZGUubG9jLmVuZC5saW5lKTtcbn1cblxuLy8gQ2hlY2tzIHdoZXRoZXIgYG5vZGVgIGhhcyBhbnkgY29tbWVudHMgX2luc2lkZSxfIGV4Y2VwdCBpbnNpZGUgdGhlIGB7Li4ufWBcbi8vIHBhcnQgKGlmIGFueSkuXG5mdW5jdGlvbiBoYXNDb21tZW50SW5zaWRlTm9uU3BlY2lmaWVycyhub2RlLCBzb3VyY2VDb2RlKSB7XG4gIGNvbnN0IHRva2VucyA9IHNvdXJjZUNvZGUuZ2V0VG9rZW5zKG5vZGUpO1xuICBjb25zdCBvcGVuQnJhY2VJbmRleCA9IHRva2Vucy5maW5kSW5kZXgoKHRva2VuKSA9PiBpc1B1bmN0dWF0b3IodG9rZW4sICd7JykpO1xuICBjb25zdCBjbG9zZUJyYWNlSW5kZXggPSB0b2tlbnMuZmluZEluZGV4KCh0b2tlbikgPT4gaXNQdW5jdHVhdG9yKHRva2VuLCAnfScpKTtcbiAgLy8gU2xpY2UgYXdheSB0aGUgZmlyc3QgdG9rZW4sIHNpbmNlIHdlJ3JlIG5vIGxvb2tpbmcgZm9yIGNvbW1lbnRzIF9iZWZvcmVfXG4gIC8vIGBub2RlYCAob25seSBpbnNpZGUpLiBJZiB0aGVyZSdzIGEgYHsuLi59YCBwYXJ0LCBsb29rIGZvciBjb21tZW50cyBiZWZvcmVcbiAgLy8gdGhlIGB7YCwgYnV0IG5vdCBiZWZvcmUgdGhlIGB9YCAoaGVuY2UgdGhlIGArMWBzKS5cbiAgY29uc3Qgc29tZVRva2VucyA9IG9wZW5CcmFjZUluZGV4ID49IDAgJiYgY2xvc2VCcmFjZUluZGV4ID49IDBcbiAgICA/IHRva2Vucy5zbGljZSgxLCBvcGVuQnJhY2VJbmRleCArIDEpLmNvbmNhdCh0b2tlbnMuc2xpY2UoY2xvc2VCcmFjZUluZGV4ICsgMSkpXG4gICAgOiB0b2tlbnMuc2xpY2UoMSk7XG4gIHJldHVybiBzb21lVG9rZW5zLnNvbWUoKHRva2VuKSA9PiBzb3VyY2VDb2RlLmdldENvbW1lbnRzQmVmb3JlKHRva2VuKS5sZW5ndGggPiAwKTtcbn1cblxuLy8gSXQncyBub3Qgb2J2aW91cyB3aGF0IHRoZSB1c2VyIHdhbnRzIHRvIGRvIHdpdGggY29tbWVudHMgYXNzb2NpYXRlZCB3aXRoXG4vLyBkdXBsaWNhdGUgaW1wb3J0cywgc28gc2tpcCBpbXBvcnRzIHdpdGggY29tbWVudHMgd2hlbiBhdXRvZml4aW5nLlxuZnVuY3Rpb24gaGFzUHJvYmxlbWF0aWNDb21tZW50cyhub2RlLCBzb3VyY2VDb2RlKSB7XG4gIHJldHVybiAoXG4gICAgaGFzQ29tbWVudEJlZm9yZShub2RlLCBzb3VyY2VDb2RlKVxuICAgIHx8IGhhc0NvbW1lbnRBZnRlcihub2RlLCBzb3VyY2VDb2RlKVxuICAgIHx8IGhhc0NvbW1lbnRJbnNpZGVOb25TcGVjaWZpZXJzKG5vZGUsIHNvdXJjZUNvZGUpXG4gICk7XG59XG5cbmZ1bmN0aW9uIGdldEZpeChmaXJzdCwgcmVzdCwgc291cmNlQ29kZSwgY29udGV4dCkge1xuICAvLyBTb3JyeSBFU0xpbnQgPD0gMyB1c2Vycywgbm8gYXV0b2ZpeCBmb3IgeW91LiBBdXRvZml4aW5nIGR1cGxpY2F0ZSBpbXBvcnRzXG4gIC8vIHJlcXVpcmVzIG11bHRpcGxlIGBmaXhlci53aGF0ZXZlcigpYCBjYWxscyBpbiB0aGUgYGZpeGA6IFdlIGJvdGggbmVlZCB0b1xuICAvLyB1cGRhdGUgdGhlIGZpcnN0IG9uZSwgYW5kIHJlbW92ZSB0aGUgcmVzdC4gU3VwcG9ydCBmb3IgbXVsdGlwbGVcbiAgLy8gYGZpeGVyLndoYXRldmVyKClgIGluIGEgc2luZ2xlIGBmaXhgIHdhcyBhZGRlZCBpbiBFU0xpbnQgNC4xLlxuICAvLyBgc291cmNlQ29kZS5nZXRDb21tZW50c0JlZm9yZWAgd2FzIGFkZGVkIGluIDQuMCwgc28gdGhhdCdzIGFuIGVhc3kgdGhpbmcgdG9cbiAgLy8gY2hlY2sgZm9yLlxuICBpZiAodHlwZW9mIHNvdXJjZUNvZGUuZ2V0Q29tbWVudHNCZWZvcmUgIT09ICdmdW5jdGlvbicpIHtcbiAgICByZXR1cm4gdW5kZWZpbmVkO1xuICB9XG5cbiAgLy8gQWRqdXN0aW5nIHRoZSBmaXJzdCBpbXBvcnQgbWlnaHQgbWFrZSBpdCBtdWx0aWxpbmUsIHdoaWNoIGNvdWxkIGJyZWFrXG4gIC8vIGBlc2xpbnQtZGlzYWJsZS1uZXh0LWxpbmVgIGNvbW1lbnRzIGFuZCBzaW1pbGFyLCBzbyBiYWlsIGlmIHRoZSBmaXJzdFxuICAvLyBpbXBvcnQgaGFzIGNvbW1lbnRzLiBBbHNvLCBpZiB0aGUgZmlyc3QgaW1wb3J0IGlzIGBpbXBvcnQgKiBhcyBucyBmcm9tXG4gIC8vICcuL2ZvbydgIHRoZXJlJ3Mgbm90aGluZyB3ZSBjYW4gZG8uXG4gIGlmIChoYXNQcm9ibGVtYXRpY0NvbW1lbnRzKGZpcnN0LCBzb3VyY2VDb2RlKSB8fCBoYXNOYW1lc3BhY2UoZmlyc3QpKSB7XG4gICAgcmV0dXJuIHVuZGVmaW5lZDtcbiAgfVxuXG4gIGNvbnN0IGRlZmF1bHRJbXBvcnROYW1lcyA9IG5ldyBTZXQoXG4gICAgZmxhdE1hcChbXS5jb25jYXQoZmlyc3QsIHJlc3QgfHwgW10pLCAoeCkgPT4gZ2V0RGVmYXVsdEltcG9ydE5hbWUoeCkgfHwgW10pLFxuICApO1xuXG4gIC8vIEJhaWwgaWYgdGhlcmUgYXJlIG11bHRpcGxlIGRpZmZlcmVudCBkZWZhdWx0IGltcG9ydCBuYW1lcyDigJMgaXQncyB1cCB0byB0aGVcbiAgLy8gdXNlciB0byBjaG9vc2Ugd2hpY2ggb25lIHRvIGtlZXAuXG4gIGlmIChkZWZhdWx0SW1wb3J0TmFtZXMuc2l6ZSA+IDEpIHtcbiAgICByZXR1cm4gdW5kZWZpbmVkO1xuICB9XG5cbiAgLy8gTGVhdmUgaXQgdG8gdGhlIHVzZXIgdG8gaGFuZGxlIGNvbW1lbnRzLiBBbHNvIHNraXAgYGltcG9ydCAqIGFzIG5zIGZyb21cbiAgLy8gJy4vZm9vJ2AgaW1wb3J0cywgc2luY2UgdGhleSBjYW5ub3QgYmUgbWVyZ2VkIGludG8gYW5vdGhlciBpbXBvcnQuXG4gIGNvbnN0IHJlc3RXaXRob3V0Q29tbWVudHMgPSByZXN0LmZpbHRlcigobm9kZSkgPT4gIWhhc1Byb2JsZW1hdGljQ29tbWVudHMobm9kZSwgc291cmNlQ29kZSkgJiYgIWhhc05hbWVzcGFjZShub2RlKSk7XG5cbiAgY29uc3Qgc3BlY2lmaWVycyA9IHJlc3RXaXRob3V0Q29tbWVudHNcbiAgICAubWFwKChub2RlKSA9PiB7XG4gICAgICBjb25zdCB0b2tlbnMgPSBzb3VyY2VDb2RlLmdldFRva2Vucyhub2RlKTtcbiAgICAgIGNvbnN0IG9wZW5CcmFjZSA9IHRva2Vucy5maW5kKCh0b2tlbikgPT4gaXNQdW5jdHVhdG9yKHRva2VuLCAneycpKTtcbiAgICAgIGNvbnN0IGNsb3NlQnJhY2UgPSB0b2tlbnMuZmluZCgodG9rZW4pID0+IGlzUHVuY3R1YXRvcih0b2tlbiwgJ30nKSk7XG5cbiAgICAgIGlmIChvcGVuQnJhY2UgPT0gbnVsbCB8fCBjbG9zZUJyYWNlID09IG51bGwpIHtcbiAgICAgICAgcmV0dXJuIHVuZGVmaW5lZDtcbiAgICAgIH1cblxuICAgICAgcmV0dXJuIHtcbiAgICAgICAgaW1wb3J0Tm9kZTogbm9kZSxcbiAgICAgICAgaWRlbnRpZmllcnM6IHNvdXJjZUNvZGUudGV4dC5zbGljZShvcGVuQnJhY2UucmFuZ2VbMV0sIGNsb3NlQnJhY2UucmFuZ2VbMF0pLnNwbGl0KCcsJyksIC8vIFNwbGl0IHRoZSB0ZXh0IGludG8gc2VwYXJhdGUgaWRlbnRpZmllcnMgKHJldGFpbmluZyBhbnkgd2hpdGVzcGFjZSBiZWZvcmUgb3IgYWZ0ZXIpXG4gICAgICAgIGlzRW1wdHk6ICFoYXNTcGVjaWZpZXJzKG5vZGUpLFxuICAgICAgfTtcbiAgICB9KVxuICAgIC5maWx0ZXIoQm9vbGVhbik7XG5cbiAgY29uc3QgdW5uZWNlc3NhcnlJbXBvcnRzID0gcmVzdFdpdGhvdXRDb21tZW50cy5maWx0ZXIoKG5vZGUpID0+ICFoYXNTcGVjaWZpZXJzKG5vZGUpXG4gICAgJiYgIWhhc05hbWVzcGFjZShub2RlKVxuICAgICYmICFzcGVjaWZpZXJzLnNvbWUoKHNwZWNpZmllcikgPT4gc3BlY2lmaWVyLmltcG9ydE5vZGUgPT09IG5vZGUpLFxuICApO1xuXG4gIGNvbnN0IHNob3VsZEFkZERlZmF1bHQgPSBnZXREZWZhdWx0SW1wb3J0TmFtZShmaXJzdCkgPT0gbnVsbCAmJiBkZWZhdWx0SW1wb3J0TmFtZXMuc2l6ZSA9PT0gMTtcbiAgY29uc3Qgc2hvdWxkQWRkU3BlY2lmaWVycyA9IHNwZWNpZmllcnMubGVuZ3RoID4gMDtcbiAgY29uc3Qgc2hvdWxkUmVtb3ZlVW5uZWNlc3NhcnkgPSB1bm5lY2Vzc2FyeUltcG9ydHMubGVuZ3RoID4gMDtcbiAgY29uc3QgcHJlZmVySW5saW5lID0gY29udGV4dC5vcHRpb25zWzBdICYmIGNvbnRleHQub3B0aW9uc1swXVsncHJlZmVyLWlubGluZSddO1xuXG4gIGlmICghKHNob3VsZEFkZERlZmF1bHQgfHwgc2hvdWxkQWRkU3BlY2lmaWVycyB8fCBzaG91bGRSZW1vdmVVbm5lY2Vzc2FyeSkpIHtcbiAgICByZXR1cm4gdW5kZWZpbmVkO1xuICB9XG5cbiAgcmV0dXJuIChmaXhlcikgPT4ge1xuICAgIGNvbnN0IHRva2VucyA9IHNvdXJjZUNvZGUuZ2V0VG9rZW5zKGZpcnN0KTtcbiAgICBjb25zdCBvcGVuQnJhY2UgPSB0b2tlbnMuZmluZCgodG9rZW4pID0+IGlzUHVuY3R1YXRvcih0b2tlbiwgJ3snKSk7XG4gICAgY29uc3QgY2xvc2VCcmFjZSA9IHRva2Vucy5maW5kKCh0b2tlbikgPT4gaXNQdW5jdHVhdG9yKHRva2VuLCAnfScpKTtcbiAgICBjb25zdCBmaXJzdFRva2VuID0gc291cmNlQ29kZS5nZXRGaXJzdFRva2VuKGZpcnN0KTtcbiAgICBjb25zdCBbZGVmYXVsdEltcG9ydE5hbWVdID0gZGVmYXVsdEltcG9ydE5hbWVzO1xuXG4gICAgY29uc3QgZmlyc3RIYXNUcmFpbGluZ0NvbW1hID0gY2xvc2VCcmFjZSAhPSBudWxsICYmIGlzUHVuY3R1YXRvcihzb3VyY2VDb2RlLmdldFRva2VuQmVmb3JlKGNsb3NlQnJhY2UpLCAnLCcpO1xuICAgIGNvbnN0IGZpcnN0SXNFbXB0eSA9ICFoYXNTcGVjaWZpZXJzKGZpcnN0KTtcbiAgICBjb25zdCBmaXJzdEV4aXN0aW5nSWRlbnRpZmllcnMgPSBmaXJzdElzRW1wdHlcbiAgICAgID8gbmV3IFNldCgpXG4gICAgICA6IG5ldyBTZXQoc291cmNlQ29kZS50ZXh0LnNsaWNlKG9wZW5CcmFjZS5yYW5nZVsxXSwgY2xvc2VCcmFjZS5yYW5nZVswXSlcbiAgICAgICAgLnNwbGl0KCcsJylcbiAgICAgICAgLm1hcCgoeCkgPT4geC50cmltKCkpLFxuICAgICAgKTtcblxuICAgIGNvbnN0IFtzcGVjaWZpZXJzVGV4dF0gPSBzcGVjaWZpZXJzLnJlZHVjZShcbiAgICAgIChbcmVzdWx0LCBuZWVkc0NvbW1hLCBleGlzdGluZ0lkZW50aWZpZXJzXSwgc3BlY2lmaWVyKSA9PiB7XG4gICAgICAgIGNvbnN0IGlzVHlwZVNwZWNpZmllciA9IHNwZWNpZmllci5pbXBvcnROb2RlLmltcG9ydEtpbmQgPT09ICd0eXBlJztcblxuICAgICAgICAvLyBhIHVzZXIgbWlnaHQgc2V0IHByZWZlci1pbmxpbmUgYnV0IG5vdCBoYXZlIGEgc3VwcG9ydGluZyBUeXBlU2NyaXB0IHZlcnNpb24uIEZsb3cgZG9lcyBub3Qgc3VwcG9ydCBpbmxpbmUgdHlwZXMgc28gdGhpcyBzaG91bGQgZmFpbCBpbiB0aGF0IGNhc2UgYXMgd2VsbC5cbiAgICAgICAgaWYgKHByZWZlcklubGluZSAmJiAoIXR5cGVzY3JpcHRQa2cgfHwgIXNlbXZlci5zYXRpc2ZpZXModHlwZXNjcmlwdFBrZy52ZXJzaW9uLCAnPj0gNC41JykpKSB7XG4gICAgICAgICAgdGhyb3cgbmV3IEVycm9yKCdZb3VyIHZlcnNpb24gb2YgVHlwZVNjcmlwdCBkb2VzIG5vdCBzdXBwb3J0IGlubGluZSB0eXBlIGltcG9ydHMuJyk7XG4gICAgICAgIH1cblxuICAgICAgICAvLyBBZGQgKm9ubHkqIHRoZSBuZXcgaWRlbnRpZmllcnMgdGhhdCBkb24ndCBhbHJlYWR5IGV4aXN0LCBhbmQgdHJhY2sgYW55IG5ldyBpZGVudGlmaWVycyBzbyB3ZSBkb24ndCBhZGQgdGhlbSBhZ2FpbiBpbiB0aGUgbmV4dCBsb29wXG4gICAgICAgIGNvbnN0IFtzcGVjaWZpZXJUZXh0LCB1cGRhdGVkRXhpc3RpbmdJZGVudGlmaWVyc10gPSBzcGVjaWZpZXIuaWRlbnRpZmllcnMucmVkdWNlKChbdGV4dCwgc2V0XSwgY3VyKSA9PiB7XG4gICAgICAgICAgY29uc3QgdHJpbW1lZCA9IGN1ci50cmltKCk7IC8vIFRyaW0gd2hpdGVzcGFjZSBiZWZvcmUvYWZ0ZXIgdG8gY29tcGFyZSB0byBvdXIgc2V0IG9mIGV4aXN0aW5nIGlkZW50aWZpZXJzXG4gICAgICAgICAgY29uc3QgY3VyV2l0aFR5cGUgPSB0cmltbWVkLmxlbmd0aCA+IDAgJiYgcHJlZmVySW5saW5lICYmIGlzVHlwZVNwZWNpZmllciA/IGB0eXBlICR7Y3VyfWAgOiBjdXI7XG4gICAgICAgICAgaWYgKGV4aXN0aW5nSWRlbnRpZmllcnMuaGFzKHRyaW1tZWQpKSB7XG4gICAgICAgICAgICByZXR1cm4gW3RleHQsIHNldF07XG4gICAgICAgICAgfVxuICAgICAgICAgIHJldHVybiBbdGV4dC5sZW5ndGggPiAwID8gYCR7dGV4dH0sJHtjdXJXaXRoVHlwZX1gIDogY3VyV2l0aFR5cGUsIHNldC5hZGQodHJpbW1lZCldO1xuICAgICAgICB9LCBbJycsIGV4aXN0aW5nSWRlbnRpZmllcnNdKTtcblxuICAgICAgICByZXR1cm4gW1xuICAgICAgICAgIG5lZWRzQ29tbWEgJiYgIXNwZWNpZmllci5pc0VtcHR5ICYmIHNwZWNpZmllclRleHQubGVuZ3RoID4gMFxuICAgICAgICAgICAgPyBgJHtyZXN1bHR9LCR7c3BlY2lmaWVyVGV4dH1gXG4gICAgICAgICAgICA6IGAke3Jlc3VsdH0ke3NwZWNpZmllclRleHR9YCxcbiAgICAgICAgICBzcGVjaWZpZXIuaXNFbXB0eSA/IG5lZWRzQ29tbWEgOiB0cnVlLFxuICAgICAgICAgIHVwZGF0ZWRFeGlzdGluZ0lkZW50aWZpZXJzLFxuICAgICAgICBdO1xuICAgICAgfSxcbiAgICAgIFsnJywgIWZpcnN0SGFzVHJhaWxpbmdDb21tYSAmJiAhZmlyc3RJc0VtcHR5LCBmaXJzdEV4aXN0aW5nSWRlbnRpZmllcnNdLFxuICAgICk7XG5cbiAgICBjb25zdCBmaXhlcyA9IFtdO1xuXG4gICAgaWYgKHNob3VsZEFkZFNwZWNpZmllcnMgJiYgcHJlZmVySW5saW5lICYmIGZpcnN0LmltcG9ydEtpbmQgPT09ICd0eXBlJykge1xuICAgICAgLy8gYGltcG9ydCB0eXBlIHthfSBmcm9tICcuL2ZvbydgIOKGkiBgaW1wb3J0IHt0eXBlIGF9IGZyb20gJy4vZm9vJ2BcbiAgICAgIGNvbnN0IHR5cGVJZGVudGlmaWVyVG9rZW4gPSB0b2tlbnMuZmluZCgodG9rZW4pID0+IHRva2VuLnR5cGUgPT09ICdJZGVudGlmaWVyJyAmJiB0b2tlbi52YWx1ZSA9PT0gJ3R5cGUnKTtcbiAgICAgIGZpeGVzLnB1c2goZml4ZXIucmVtb3ZlUmFuZ2UoW3R5cGVJZGVudGlmaWVyVG9rZW4ucmFuZ2VbMF0sIHR5cGVJZGVudGlmaWVyVG9rZW4ucmFuZ2VbMV0gKyAxXSkpO1xuXG4gICAgICB0b2tlbnNcbiAgICAgICAgLmZpbHRlcigodG9rZW4pID0+IGZpcnN0RXhpc3RpbmdJZGVudGlmaWVycy5oYXModG9rZW4udmFsdWUpKVxuICAgICAgICAuZm9yRWFjaCgoaWRlbnRpZmllcikgPT4ge1xuICAgICAgICAgIGZpeGVzLnB1c2goZml4ZXIucmVwbGFjZVRleHRSYW5nZShbaWRlbnRpZmllci5yYW5nZVswXSwgaWRlbnRpZmllci5yYW5nZVsxXV0sIGB0eXBlICR7aWRlbnRpZmllci52YWx1ZX1gKSk7XG4gICAgICAgIH0pO1xuICAgIH1cblxuICAgIGlmIChzaG91bGRBZGREZWZhdWx0ICYmIG9wZW5CcmFjZSA9PSBudWxsICYmIHNob3VsZEFkZFNwZWNpZmllcnMpIHtcbiAgICAgIC8vIGBpbXBvcnQgJy4vZm9vJ2Ag4oaSIGBpbXBvcnQgZGVmLCB7Li4ufSBmcm9tICcuL2ZvbydgXG4gICAgICBmaXhlcy5wdXNoKFxuICAgICAgICBmaXhlci5pbnNlcnRUZXh0QWZ0ZXIoZmlyc3RUb2tlbiwgYCAke2RlZmF1bHRJbXBvcnROYW1lfSwgeyR7c3BlY2lmaWVyc1RleHR9fSBmcm9tYCksXG4gICAgICApO1xuICAgIH0gZWxzZSBpZiAoc2hvdWxkQWRkRGVmYXVsdCAmJiBvcGVuQnJhY2UgPT0gbnVsbCAmJiAhc2hvdWxkQWRkU3BlY2lmaWVycykge1xuICAgICAgLy8gYGltcG9ydCAnLi9mb28nYCDihpIgYGltcG9ydCBkZWYgZnJvbSAnLi9mb28nYFxuICAgICAgZml4ZXMucHVzaChmaXhlci5pbnNlcnRUZXh0QWZ0ZXIoZmlyc3RUb2tlbiwgYCAke2RlZmF1bHRJbXBvcnROYW1lfSBmcm9tYCkpO1xuICAgIH0gZWxzZSBpZiAoc2hvdWxkQWRkRGVmYXVsdCAmJiBvcGVuQnJhY2UgIT0gbnVsbCAmJiBjbG9zZUJyYWNlICE9IG51bGwpIHtcbiAgICAgIC8vIGBpbXBvcnQgey4uLn0gZnJvbSAnLi9mb28nYCDihpIgYGltcG9ydCBkZWYsIHsuLi59IGZyb20gJy4vZm9vJ2BcbiAgICAgIGZpeGVzLnB1c2goZml4ZXIuaW5zZXJ0VGV4dEFmdGVyKGZpcnN0VG9rZW4sIGAgJHtkZWZhdWx0SW1wb3J0TmFtZX0sYCkpO1xuICAgICAgaWYgKHNob3VsZEFkZFNwZWNpZmllcnMpIHtcbiAgICAgICAgLy8gYGltcG9ydCBkZWYsIHsuLi59IGZyb20gJy4vZm9vJ2Ag4oaSIGBpbXBvcnQgZGVmLCB7Li4uLCAuLi59IGZyb20gJy4vZm9vJ2BcbiAgICAgICAgZml4ZXMucHVzaChmaXhlci5pbnNlcnRUZXh0QmVmb3JlKGNsb3NlQnJhY2UsIHNwZWNpZmllcnNUZXh0KSk7XG4gICAgICB9XG4gICAgfSBlbHNlIGlmICghc2hvdWxkQWRkRGVmYXVsdCAmJiBvcGVuQnJhY2UgPT0gbnVsbCAmJiBzaG91bGRBZGRTcGVjaWZpZXJzKSB7XG4gICAgICBpZiAoZmlyc3Quc3BlY2lmaWVycy5sZW5ndGggPT09IDApIHtcbiAgICAgICAgLy8gYGltcG9ydCAnLi9mb28nYCDihpIgYGltcG9ydCB7Li4ufSBmcm9tICcuL2ZvbydgXG4gICAgICAgIGZpeGVzLnB1c2goZml4ZXIuaW5zZXJ0VGV4dEFmdGVyKGZpcnN0VG9rZW4sIGAgeyR7c3BlY2lmaWVyc1RleHR9fSBmcm9tYCkpO1xuICAgICAgfSBlbHNlIHtcbiAgICAgICAgLy8gYGltcG9ydCBkZWYgZnJvbSAnLi9mb28nYCDihpIgYGltcG9ydCBkZWYsIHsuLi59IGZyb20gJy4vZm9vJ2BcbiAgICAgICAgZml4ZXMucHVzaChmaXhlci5pbnNlcnRUZXh0QWZ0ZXIoZmlyc3Quc3BlY2lmaWVyc1swXSwgYCwgeyR7c3BlY2lmaWVyc1RleHR9fWApKTtcbiAgICAgIH1cbiAgICB9IGVsc2UgaWYgKCFzaG91bGRBZGREZWZhdWx0ICYmIG9wZW5CcmFjZSAhPSBudWxsICYmIGNsb3NlQnJhY2UgIT0gbnVsbCkge1xuICAgICAgLy8gYGltcG9ydCB7Li4ufSAnLi9mb28nYCDihpIgYGltcG9ydCB7Li4uLCAuLi59IGZyb20gJy4vZm9vJ2BcbiAgICAgIGZpeGVzLnB1c2goZml4ZXIuaW5zZXJ0VGV4dEJlZm9yZShjbG9zZUJyYWNlLCBzcGVjaWZpZXJzVGV4dCkpO1xuICAgIH1cblxuICAgIC8vIFJlbW92ZSBpbXBvcnRzIHdob3NlIHNwZWNpZmllcnMgaGF2ZSBiZWVuIG1vdmVkIGludG8gdGhlIGZpcnN0IGltcG9ydC5cbiAgICBmb3IgKGNvbnN0IHNwZWNpZmllciBvZiBzcGVjaWZpZXJzKSB7XG4gICAgICBjb25zdCBpbXBvcnROb2RlID0gc3BlY2lmaWVyLmltcG9ydE5vZGU7XG4gICAgICBmaXhlcy5wdXNoKGZpeGVyLnJlbW92ZShpbXBvcnROb2RlKSk7XG5cbiAgICAgIGNvbnN0IGNoYXJBZnRlckltcG9ydFJhbmdlID0gW2ltcG9ydE5vZGUucmFuZ2VbMV0sIGltcG9ydE5vZGUucmFuZ2VbMV0gKyAxXTtcbiAgICAgIGNvbnN0IGNoYXJBZnRlckltcG9ydCA9IHNvdXJjZUNvZGUudGV4dC5zdWJzdHJpbmcoY2hhckFmdGVySW1wb3J0UmFuZ2VbMF0sIGNoYXJBZnRlckltcG9ydFJhbmdlWzFdKTtcbiAgICAgIGlmIChjaGFyQWZ0ZXJJbXBvcnQgPT09ICdcXG4nKSB7XG4gICAgICAgIGZpeGVzLnB1c2goZml4ZXIucmVtb3ZlUmFuZ2UoY2hhckFmdGVySW1wb3J0UmFuZ2UpKTtcbiAgICAgIH1cbiAgICB9XG5cbiAgICAvLyBSZW1vdmUgaW1wb3J0cyB3aG9zZSBkZWZhdWx0IGltcG9ydCBoYXMgYmVlbiBtb3ZlZCB0byB0aGUgZmlyc3QgaW1wb3J0LFxuICAgIC8vIGFuZCBzaWRlLWVmZmVjdC1vbmx5IGltcG9ydHMgdGhhdCBhcmUgdW5uZWNlc3NhcnkgZHVlIHRvIHRoZSBmaXJzdFxuICAgIC8vIGltcG9ydC5cbiAgICBmb3IgKGNvbnN0IG5vZGUgb2YgdW5uZWNlc3NhcnlJbXBvcnRzKSB7XG4gICAgICBmaXhlcy5wdXNoKGZpeGVyLnJlbW92ZShub2RlKSk7XG5cbiAgICAgIGNvbnN0IGNoYXJBZnRlckltcG9ydFJhbmdlID0gW25vZGUucmFuZ2VbMV0sIG5vZGUucmFuZ2VbMV0gKyAxXTtcbiAgICAgIGNvbnN0IGNoYXJBZnRlckltcG9ydCA9IHNvdXJjZUNvZGUudGV4dC5zdWJzdHJpbmcoY2hhckFmdGVySW1wb3J0UmFuZ2VbMF0sIGNoYXJBZnRlckltcG9ydFJhbmdlWzFdKTtcbiAgICAgIGlmIChjaGFyQWZ0ZXJJbXBvcnQgPT09ICdcXG4nKSB7XG4gICAgICAgIGZpeGVzLnB1c2goZml4ZXIucmVtb3ZlUmFuZ2UoY2hhckFmdGVySW1wb3J0UmFuZ2UpKTtcbiAgICAgIH1cbiAgICB9XG5cbiAgICByZXR1cm4gZml4ZXM7XG4gIH07XG59XG5cbmZ1bmN0aW9uIGNoZWNrSW1wb3J0cyhpbXBvcnRlZCwgY29udGV4dCkge1xuICBmb3IgKGNvbnN0IFttb2R1bGUsIG5vZGVzXSBvZiBpbXBvcnRlZC5lbnRyaWVzKCkpIHtcbiAgICBpZiAobm9kZXMubGVuZ3RoID4gMSkge1xuICAgICAgY29uc3QgbWVzc2FnZSA9IGAnJHttb2R1bGV9JyBpbXBvcnRlZCBtdWx0aXBsZSB0aW1lcy5gO1xuICAgICAgY29uc3QgW2ZpcnN0LCAuLi5yZXN0XSA9IG5vZGVzO1xuICAgICAgY29uc3Qgc291cmNlQ29kZSA9IGNvbnRleHQuZ2V0U291cmNlQ29kZSgpO1xuICAgICAgY29uc3QgZml4ID0gZ2V0Rml4KGZpcnN0LCByZXN0LCBzb3VyY2VDb2RlLCBjb250ZXh0KTtcblxuICAgICAgY29udGV4dC5yZXBvcnQoe1xuICAgICAgICBub2RlOiBmaXJzdC5zb3VyY2UsXG4gICAgICAgIG1lc3NhZ2UsXG4gICAgICAgIGZpeCwgLy8gQXR0YWNoIHRoZSBhdXRvZml4IChpZiBhbnkpIHRvIHRoZSBmaXJzdCBpbXBvcnQuXG4gICAgICB9KTtcblxuICAgICAgZm9yIChjb25zdCBub2RlIG9mIHJlc3QpIHtcbiAgICAgICAgY29udGV4dC5yZXBvcnQoe1xuICAgICAgICAgIG5vZGU6IG5vZGUuc291cmNlLFxuICAgICAgICAgIG1lc3NhZ2UsXG4gICAgICAgIH0pO1xuICAgICAgfVxuICAgIH1cbiAgfVxufVxuXG5tb2R1bGUuZXhwb3J0cyA9IHtcbiAgbWV0YToge1xuICAgIHR5cGU6ICdwcm9ibGVtJyxcbiAgICBkb2NzOiB7XG4gICAgICBjYXRlZ29yeTogJ1N0eWxlIGd1aWRlJyxcbiAgICAgIGRlc2NyaXB0aW9uOiAnRm9yYmlkIHJlcGVhdGVkIGltcG9ydCBvZiB0aGUgc2FtZSBtb2R1bGUgaW4gbXVsdGlwbGUgcGxhY2VzLicsXG4gICAgICB1cmw6IGRvY3NVcmwoJ25vLWR1cGxpY2F0ZXMnKSxcbiAgICB9LFxuICAgIGZpeGFibGU6ICdjb2RlJyxcbiAgICBzY2hlbWE6IFtcbiAgICAgIHtcbiAgICAgICAgdHlwZTogJ29iamVjdCcsXG4gICAgICAgIHByb3BlcnRpZXM6IHtcbiAgICAgICAgICBjb25zaWRlclF1ZXJ5U3RyaW5nOiB7XG4gICAgICAgICAgICB0eXBlOiAnYm9vbGVhbicsXG4gICAgICAgICAgfSxcbiAgICAgICAgICAncHJlZmVyLWlubGluZSc6IHtcbiAgICAgICAgICAgIHR5cGU6ICdib29sZWFuJyxcbiAgICAgICAgICB9LFxuICAgICAgICB9LFxuICAgICAgICBhZGRpdGlvbmFsUHJvcGVydGllczogZmFsc2UsXG4gICAgICB9LFxuICAgIF0sXG4gIH0sXG5cbiAgY3JlYXRlKGNvbnRleHQpIHtcbiAgICAvLyBQcmVwYXJlIHRoZSByZXNvbHZlciBmcm9tIG9wdGlvbnMuXG4gICAgY29uc3QgY29uc2lkZXJRdWVyeVN0cmluZ09wdGlvbiA9IGNvbnRleHQub3B0aW9uc1swXVxuICAgICAgJiYgY29udGV4dC5vcHRpb25zWzBdLmNvbnNpZGVyUXVlcnlTdHJpbmc7XG4gICAgY29uc3QgZGVmYXVsdFJlc29sdmVyID0gKHNvdXJjZVBhdGgpID0+IHJlc29sdmUoc291cmNlUGF0aCwgY29udGV4dCkgfHwgc291cmNlUGF0aDtcbiAgICBjb25zdCByZXNvbHZlciA9IGNvbnNpZGVyUXVlcnlTdHJpbmdPcHRpb24gPyAoc291cmNlUGF0aCkgPT4ge1xuICAgICAgY29uc3QgcGFydHMgPSBzb3VyY2VQYXRoLm1hdGNoKC9eKFteP10qKVxcPyguKikkLyk7XG4gICAgICBpZiAoIXBhcnRzKSB7XG4gICAgICAgIHJldHVybiBkZWZhdWx0UmVzb2x2ZXIoc291cmNlUGF0aCk7XG4gICAgICB9XG4gICAgICByZXR1cm4gYCR7ZGVmYXVsdFJlc29sdmVyKHBhcnRzWzFdKX0/JHtwYXJ0c1syXX1gO1xuICAgIH0gOiBkZWZhdWx0UmVzb2x2ZXI7XG5cbiAgICBjb25zdCBtb2R1bGVNYXBzID0gbmV3IE1hcCgpO1xuXG4gICAgZnVuY3Rpb24gZ2V0SW1wb3J0TWFwKG4pIHtcbiAgICAgIGlmICghbW9kdWxlTWFwcy5oYXMobi5wYXJlbnQpKSB7XG4gICAgICAgIG1vZHVsZU1hcHMuc2V0KG4ucGFyZW50LCB7XG4gICAgICAgICAgaW1wb3J0ZWQ6IG5ldyBNYXAoKSxcbiAgICAgICAgICBuc0ltcG9ydGVkOiBuZXcgTWFwKCksXG4gICAgICAgICAgZGVmYXVsdFR5cGVzSW1wb3J0ZWQ6IG5ldyBNYXAoKSxcbiAgICAgICAgICBuYW1lZFR5cGVzSW1wb3J0ZWQ6IG5ldyBNYXAoKSxcbiAgICAgICAgfSk7XG4gICAgICB9XG4gICAgICBjb25zdCBtYXAgPSBtb2R1bGVNYXBzLmdldChuLnBhcmVudCk7XG4gICAgICBjb25zdCBwcmVmZXJJbmxpbmUgPSBjb250ZXh0Lm9wdGlvbnNbMF0gJiYgY29udGV4dC5vcHRpb25zWzBdWydwcmVmZXItaW5saW5lJ107XG4gICAgICBpZiAoIXByZWZlcklubGluZSAmJiBuLmltcG9ydEtpbmQgPT09ICd0eXBlJykge1xuICAgICAgICByZXR1cm4gbi5zcGVjaWZpZXJzLmxlbmd0aCA+IDAgJiYgbi5zcGVjaWZpZXJzWzBdLnR5cGUgPT09ICdJbXBvcnREZWZhdWx0U3BlY2lmaWVyJyA/IG1hcC5kZWZhdWx0VHlwZXNJbXBvcnRlZCA6IG1hcC5uYW1lZFR5cGVzSW1wb3J0ZWQ7XG4gICAgICB9XG4gICAgICBpZiAoIXByZWZlcklubGluZSAmJiBuLnNwZWNpZmllcnMuc29tZSgoc3BlYykgPT4gc3BlYy5pbXBvcnRLaW5kID09PSAndHlwZScpKSB7XG4gICAgICAgIHJldHVybiBtYXAubmFtZWRUeXBlc0ltcG9ydGVkO1xuICAgICAgfVxuXG4gICAgICByZXR1cm4gaGFzTmFtZXNwYWNlKG4pID8gbWFwLm5zSW1wb3J0ZWQgOiBtYXAuaW1wb3J0ZWQ7XG4gICAgfVxuXG4gICAgcmV0dXJuIHtcbiAgICAgIEltcG9ydERlY2xhcmF0aW9uKG4pIHtcbiAgICAgICAgLy8gcmVzb2x2ZWQgcGF0aCB3aWxsIGNvdmVyIGFsaWFzZWQgZHVwbGljYXRlc1xuICAgICAgICBjb25zdCByZXNvbHZlZFBhdGggPSByZXNvbHZlcihuLnNvdXJjZS52YWx1ZSk7XG4gICAgICAgIGNvbnN0IGltcG9ydE1hcCA9IGdldEltcG9ydE1hcChuKTtcblxuICAgICAgICBpZiAoaW1wb3J0TWFwLmhhcyhyZXNvbHZlZFBhdGgpKSB7XG4gICAgICAgICAgaW1wb3J0TWFwLmdldChyZXNvbHZlZFBhdGgpLnB1c2gobik7XG4gICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgaW1wb3J0TWFwLnNldChyZXNvbHZlZFBhdGgsIFtuXSk7XG4gICAgICAgIH1cbiAgICAgIH0sXG5cbiAgICAgICdQcm9ncmFtOmV4aXQnKCkge1xuICAgICAgICBmb3IgKGNvbnN0IG1hcCBvZiBtb2R1bGVNYXBzLnZhbHVlcygpKSB7XG4gICAgICAgICAgY2hlY2tJbXBvcnRzKG1hcC5pbXBvcnRlZCwgY29udGV4dCk7XG4gICAgICAgICAgY2hlY2tJbXBvcnRzKG1hcC5uc0ltcG9ydGVkLCBjb250ZXh0KTtcbiAgICAgICAgICBjaGVja0ltcG9ydHMobWFwLmRlZmF1bHRUeXBlc0ltcG9ydGVkLCBjb250ZXh0KTtcbiAgICAgICAgICBjaGVja0ltcG9ydHMobWFwLm5hbWVkVHlwZXNJbXBvcnRlZCwgY29udGV4dCk7XG4gICAgICAgIH1cbiAgICAgIH0sXG4gICAgfTtcbiAgfSxcbn07XG4iXX0=