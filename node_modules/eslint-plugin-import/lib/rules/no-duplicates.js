'use strict';var _slicedToArray = function () {function sliceIterator(arr, i) {var _arr = [];var _n = true;var _d = false;var _e = undefined;try {for (var _i = arr[Symbol.iterator](), _s; !(_n = (_s = _i.next()).done); _n = true) {_arr.push(_s.value);if (i && _arr.length === i) break;}} catch (err) {_d = true;_e = err;} finally {try {if (!_n && _i["return"]) _i["return"]();} finally {if (_d) throw _e;}}return _arr;}return function (arr, i) {if (Array.isArray(arr)) {return arr;} else if (Symbol.iterator in Object(arr)) {return sliceIterator(arr, i);} else {throw new TypeError("Invalid attempt to destructure non-iterable instance");}};}();var _resolve = require('eslint-module-utils/resolve');var _resolve2 = _interopRequireDefault(_resolve);
var _docsUrl = require('../docsUrl');var _docsUrl2 = _interopRequireDefault(_docsUrl);function _interopRequireDefault(obj) {return obj && obj.__esModule ? obj : { default: obj };}function _toConsumableArray(arr) {if (Array.isArray(arr)) {for (var i = 0, arr2 = Array(arr.length); i < arr.length; i++) arr2[i] = arr[i];return arr2;} else {return Array.from(arr);}}function _toArray(arr) {return Array.isArray(arr) ? arr : Array.from(arr);}

function checkImports(imported, context) {
  for (const _ref of imported.entries()) {var _ref2 = _slicedToArray(_ref, 2);const module = _ref2[0];const nodes = _ref2[1];
    if (nodes.length > 1) {
      const message = `'${module}' imported multiple times.`;var _nodes = _toArray(
      nodes);const first = _nodes[0],rest = _nodes.slice(1);
      const sourceCode = context.getSourceCode();
      const fix = getFix(first, rest, sourceCode);

      context.report({
        node: first.source,
        message,
        fix // Attach the autofix (if any) to the first import.
      });

      for (const node of rest) {
        context.report({
          node: node.source,
          message });

      }
    }
  }
}

function getFix(first, rest, sourceCode) {
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

  const defaultImportNames = new Set(
  [first].concat(_toConsumableArray(rest)).map(getDefaultImportName).filter(Boolean));


  // Bail if there are multiple different default import names – it's up to the
  // user to choose which one to keep.
  if (defaultImportNames.size > 1) {
    return undefined;
  }

  // Leave it to the user to handle comments. Also skip `import * as ns from
  // './foo'` imports, since they cannot be merged into another import.
  const restWithoutComments = rest.filter(node => !(
  hasProblematicComments(node, sourceCode) ||
  hasNamespace(node)));


  const specifiers = restWithoutComments.
  map(node => {
    const tokens = sourceCode.getTokens(node);
    const openBrace = tokens.find(token => isPunctuator(token, '{'));
    const closeBrace = tokens.find(token => isPunctuator(token, '}'));

    if (openBrace == null || closeBrace == null) {
      return undefined;
    }

    return {
      importNode: node,
      text: sourceCode.text.slice(openBrace.range[1], closeBrace.range[0]),
      hasTrailingComma: isPunctuator(sourceCode.getTokenBefore(closeBrace), ','),
      isEmpty: !hasSpecifiers(node) };

  }).
  filter(Boolean);

  const unnecessaryImports = restWithoutComments.filter(node =>
  !hasSpecifiers(node) &&
  !hasNamespace(node) &&
  !specifiers.some(specifier => specifier.importNode === node));


  const shouldAddDefault = getDefaultImportName(first) == null && defaultImportNames.size === 1;
  const shouldAddSpecifiers = specifiers.length > 0;
  const shouldRemoveUnnecessary = unnecessaryImports.length > 0;

  if (!(shouldAddDefault || shouldAddSpecifiers || shouldRemoveUnnecessary)) {
    return undefined;
  }

  return fixer => {
    const tokens = sourceCode.getTokens(first);
    const openBrace = tokens.find(token => isPunctuator(token, '{'));
    const closeBrace = tokens.find(token => isPunctuator(token, '}'));
    const firstToken = sourceCode.getFirstToken(first);var _defaultImportNames = _slicedToArray(
    defaultImportNames, 1);const defaultImportName = _defaultImportNames[0];

    const firstHasTrailingComma =
    closeBrace != null &&
    isPunctuator(sourceCode.getTokenBefore(closeBrace), ',');
    const firstIsEmpty = !hasSpecifiers(first);var _specifiers$reduce =

    specifiers.reduce(
    (_ref3, specifier) => {var _ref4 = _slicedToArray(_ref3, 2);let result = _ref4[0],needsComma = _ref4[1];
      return [
      needsComma && !specifier.isEmpty ?
      `${result},${specifier.text}` :
      `${result}${specifier.text}`,
      specifier.isEmpty ? needsComma : true];

    },
    ['', !firstHasTrailingComma && !firstIsEmpty]),_specifiers$reduce2 = _slicedToArray(_specifiers$reduce, 1);const specifiersText = _specifiers$reduce2[0];


    const fixes = [];

    if (shouldAddDefault && openBrace == null && shouldAddSpecifiers) {
      // `import './foo'` → `import def, {...} from './foo'`
      fixes.push(
      fixer.insertTextAfter(firstToken, ` ${defaultImportName}, {${specifiersText}} from`));

    } else if (shouldAddDefault && openBrace == null && !shouldAddSpecifiers) {
      // `import './foo'` → `import def from './foo'`
      fixes.push(fixer.insertTextAfter(firstToken, ` ${defaultImportName} from`));
    } else if (shouldAddDefault && openBrace != null && closeBrace != null) {
      // `import {...} from './foo'` → `import def, {...} from './foo'`
      fixes.push(fixer.insertTextAfter(firstToken, ` ${defaultImportName},`));
      if (shouldAddSpecifiers) {
        // `import def, {...} from './foo'` → `import def, {..., ...} from './foo'`
        fixes.push(fixer.insertTextBefore(closeBrace, specifiersText));
      }
    } else if (!shouldAddDefault && openBrace == null && shouldAddSpecifiers) {
      if (first.specifiers.length === 0) {
        // `import './foo'` → `import {...} from './foo'`
        fixes.push(fixer.insertTextAfter(firstToken, ` {${specifiersText}} from`));
      } else {
        // `import def from './foo'` → `import def, {...} from './foo'`
        fixes.push(fixer.insertTextAfter(first.specifiers[0], `, {${specifiersText}}`));
      }
    } else if (!shouldAddDefault && openBrace != null && closeBrace != null) {
      // `import {...} './foo'` → `import {..., ...} from './foo'`
      fixes.push(fixer.insertTextBefore(closeBrace, specifiersText));
    }

    // Remove imports whose specifiers have been moved into the first import.
    for (const specifier of specifiers) {
      fixes.push(fixer.remove(specifier.importNode));
    }

    // Remove imports whose default import has been moved to the first import,
    // and side-effect-only imports that are unnecessary due to the first
    // import.
    for (const node of unnecessaryImports) {
      fixes.push(fixer.remove(node));
    }

    return fixes;
  };
}

function isPunctuator(node, value) {
  return node.type === 'Punctuator' && node.value === value;
}

// Get the name of the default import of `node`, if any.
function getDefaultImportName(node) {
  const defaultSpecifier = node.specifiers.
  find(specifier => specifier.type === 'ImportDefaultSpecifier');
  return defaultSpecifier != null ? defaultSpecifier.local.name : undefined;
}

// Checks whether `node` has a namespace import.
function hasNamespace(node) {
  const specifiers = node.specifiers.
  filter(specifier => specifier.type === 'ImportNamespaceSpecifier');
  return specifiers.length > 0;
}

// Checks whether `node` has any non-default specifiers.
function hasSpecifiers(node) {
  const specifiers = node.specifiers.
  filter(specifier => specifier.type === 'ImportSpecifier');
  return specifiers.length > 0;
}

// It's not obvious what the user wants to do with comments associated with
// duplicate imports, so skip imports with comments when autofixing.
function hasProblematicComments(node, sourceCode) {
  return (
    hasCommentBefore(node, sourceCode) ||
    hasCommentAfter(node, sourceCode) ||
    hasCommentInsideNonSpecifiers(node, sourceCode));

}

// Checks whether `node` has a comment (that ends) on the previous line or on
// the same line as `node` (starts).
function hasCommentBefore(node, sourceCode) {
  return sourceCode.getCommentsBefore(node).
  some(comment => comment.loc.end.line >= node.loc.start.line - 1);
}

// Checks whether `node` has a comment (that starts) on the same line as `node`
// (ends).
function hasCommentAfter(node, sourceCode) {
  return sourceCode.getCommentsAfter(node).
  some(comment => comment.loc.start.line === node.loc.end.line);
}

// Checks whether `node` has any comments _inside,_ except inside the `{...}`
// part (if any).
function hasCommentInsideNonSpecifiers(node, sourceCode) {
  const tokens = sourceCode.getTokens(node);
  const openBraceIndex = tokens.findIndex(token => isPunctuator(token, '{'));
  const closeBraceIndex = tokens.findIndex(token => isPunctuator(token, '}'));
  // Slice away the first token, since we're no looking for comments _before_
  // `node` (only inside). If there's a `{...}` part, look for comments before
  // the `{`, but not before the `}` (hence the `+1`s).
  const someTokens = openBraceIndex >= 0 && closeBraceIndex >= 0 ?
  tokens.slice(1, openBraceIndex + 1).concat(tokens.slice(closeBraceIndex + 1)) :
  tokens.slice(1);
  return someTokens.some(token => sourceCode.getCommentsBefore(token).length > 0);
}

module.exports = {
  meta: {
    type: 'problem',
    docs: {
      url: (0, _docsUrl2.default)('no-duplicates') },

    fixable: 'code',
    schema: [
    {
      type: 'object',
      properties: {
        considerQueryString: {
          type: 'boolean' } },


      additionalProperties: false }] },




  create: function (context) {
    // Prepare the resolver from options.
    const considerQueryStringOption = context.options[0] &&
    context.options[0]['considerQueryString'];
    const defaultResolver = sourcePath => (0, _resolve2.default)(sourcePath, context) || sourcePath;
    const resolver = considerQueryStringOption ? sourcePath => {
      const parts = sourcePath.match(/^([^?]*)\?(.*)$/);
      if (!parts) {
        return defaultResolver(sourcePath);
      }
      return defaultResolver(parts[1]) + '?' + parts[2];
    } : defaultResolver;

    const imported = new Map();
    const nsImported = new Map();
    const typesImported = new Map();
    return {
      'ImportDeclaration': function (n) {
        // resolved path will cover aliased duplicates
        const resolvedPath = resolver(n.source.value);
        const importMap = n.importKind === 'type' ? typesImported :
        hasNamespace(n) ? nsImported : imported;

        if (importMap.has(resolvedPath)) {
          importMap.get(resolvedPath).push(n);
        } else {
          importMap.set(resolvedPath, [n]);
        }
      },

      'Program:exit': function () {
        checkImports(imported, context);
        checkImports(nsImported, context);
        checkImports(typesImported, context);
      } };

  } };
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIi4uLy4uL3NyYy9ydWxlcy9uby1kdXBsaWNhdGVzLmpzIl0sIm5hbWVzIjpbImNoZWNrSW1wb3J0cyIsImltcG9ydGVkIiwiY29udGV4dCIsImVudHJpZXMiLCJtb2R1bGUiLCJub2RlcyIsImxlbmd0aCIsIm1lc3NhZ2UiLCJmaXJzdCIsInJlc3QiLCJzb3VyY2VDb2RlIiwiZ2V0U291cmNlQ29kZSIsImZpeCIsImdldEZpeCIsInJlcG9ydCIsIm5vZGUiLCJzb3VyY2UiLCJnZXRDb21tZW50c0JlZm9yZSIsInVuZGVmaW5lZCIsImhhc1Byb2JsZW1hdGljQ29tbWVudHMiLCJoYXNOYW1lc3BhY2UiLCJkZWZhdWx0SW1wb3J0TmFtZXMiLCJTZXQiLCJtYXAiLCJnZXREZWZhdWx0SW1wb3J0TmFtZSIsImZpbHRlciIsIkJvb2xlYW4iLCJzaXplIiwicmVzdFdpdGhvdXRDb21tZW50cyIsInNwZWNpZmllcnMiLCJ0b2tlbnMiLCJnZXRUb2tlbnMiLCJvcGVuQnJhY2UiLCJmaW5kIiwidG9rZW4iLCJpc1B1bmN0dWF0b3IiLCJjbG9zZUJyYWNlIiwiaW1wb3J0Tm9kZSIsInRleHQiLCJzbGljZSIsInJhbmdlIiwiaGFzVHJhaWxpbmdDb21tYSIsImdldFRva2VuQmVmb3JlIiwiaXNFbXB0eSIsImhhc1NwZWNpZmllcnMiLCJ1bm5lY2Vzc2FyeUltcG9ydHMiLCJzb21lIiwic3BlY2lmaWVyIiwic2hvdWxkQWRkRGVmYXVsdCIsInNob3VsZEFkZFNwZWNpZmllcnMiLCJzaG91bGRSZW1vdmVVbm5lY2Vzc2FyeSIsImZpeGVyIiwiZmlyc3RUb2tlbiIsImdldEZpcnN0VG9rZW4iLCJkZWZhdWx0SW1wb3J0TmFtZSIsImZpcnN0SGFzVHJhaWxpbmdDb21tYSIsImZpcnN0SXNFbXB0eSIsInJlZHVjZSIsInJlc3VsdCIsIm5lZWRzQ29tbWEiLCJzcGVjaWZpZXJzVGV4dCIsImZpeGVzIiwicHVzaCIsImluc2VydFRleHRBZnRlciIsImluc2VydFRleHRCZWZvcmUiLCJyZW1vdmUiLCJ2YWx1ZSIsInR5cGUiLCJkZWZhdWx0U3BlY2lmaWVyIiwibG9jYWwiLCJuYW1lIiwiaGFzQ29tbWVudEJlZm9yZSIsImhhc0NvbW1lbnRBZnRlciIsImhhc0NvbW1lbnRJbnNpZGVOb25TcGVjaWZpZXJzIiwiY29tbWVudCIsImxvYyIsImVuZCIsImxpbmUiLCJzdGFydCIsImdldENvbW1lbnRzQWZ0ZXIiLCJvcGVuQnJhY2VJbmRleCIsImZpbmRJbmRleCIsImNsb3NlQnJhY2VJbmRleCIsInNvbWVUb2tlbnMiLCJjb25jYXQiLCJleHBvcnRzIiwibWV0YSIsImRvY3MiLCJ1cmwiLCJmaXhhYmxlIiwic2NoZW1hIiwicHJvcGVydGllcyIsImNvbnNpZGVyUXVlcnlTdHJpbmciLCJhZGRpdGlvbmFsUHJvcGVydGllcyIsImNyZWF0ZSIsImNvbnNpZGVyUXVlcnlTdHJpbmdPcHRpb24iLCJvcHRpb25zIiwiZGVmYXVsdFJlc29sdmVyIiwic291cmNlUGF0aCIsInJlc29sdmVyIiwicGFydHMiLCJtYXRjaCIsIk1hcCIsIm5zSW1wb3J0ZWQiLCJ0eXBlc0ltcG9ydGVkIiwibiIsInJlc29sdmVkUGF0aCIsImltcG9ydE1hcCIsImltcG9ydEtpbmQiLCJoYXMiLCJnZXQiLCJzZXQiXSwibWFwcGluZ3MiOiJxb0JBQUEsc0Q7QUFDQSxxQzs7QUFFQSxTQUFTQSxZQUFULENBQXNCQyxRQUF0QixFQUFnQ0MsT0FBaEMsRUFBeUM7QUFDdkMscUJBQThCRCxTQUFTRSxPQUFULEVBQTlCLEVBQWtELDJDQUF0Q0MsTUFBc0Msa0JBQTlCQyxLQUE4QjtBQUNoRCxRQUFJQSxNQUFNQyxNQUFOLEdBQWUsQ0FBbkIsRUFBc0I7QUFDcEIsWUFBTUMsVUFBVyxJQUFHSCxNQUFPLDRCQUEzQixDQURvQjtBQUVLQyxXQUZMLFFBRWJHLEtBRmEsYUFFSEMsSUFGRztBQUdwQixZQUFNQyxhQUFhUixRQUFRUyxhQUFSLEVBQW5CO0FBQ0EsWUFBTUMsTUFBTUMsT0FBT0wsS0FBUCxFQUFjQyxJQUFkLEVBQW9CQyxVQUFwQixDQUFaOztBQUVBUixjQUFRWSxNQUFSLENBQWU7QUFDYkMsY0FBTVAsTUFBTVEsTUFEQztBQUViVCxlQUZhO0FBR2JLLFdBSGEsQ0FHUjtBQUhRLE9BQWY7O0FBTUEsV0FBSyxNQUFNRyxJQUFYLElBQW1CTixJQUFuQixFQUF5QjtBQUN2QlAsZ0JBQVFZLE1BQVIsQ0FBZTtBQUNiQyxnQkFBTUEsS0FBS0MsTUFERTtBQUViVCxpQkFGYSxFQUFmOztBQUlEO0FBQ0Y7QUFDRjtBQUNGOztBQUVELFNBQVNNLE1BQVQsQ0FBZ0JMLEtBQWhCLEVBQXVCQyxJQUF2QixFQUE2QkMsVUFBN0IsRUFBeUM7QUFDdkM7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0EsTUFBSSxPQUFPQSxXQUFXTyxpQkFBbEIsS0FBd0MsVUFBNUMsRUFBd0Q7QUFDdEQsV0FBT0MsU0FBUDtBQUNEOztBQUVEO0FBQ0E7QUFDQTtBQUNBO0FBQ0EsTUFBSUMsdUJBQXVCWCxLQUF2QixFQUE4QkUsVUFBOUIsS0FBNkNVLGFBQWFaLEtBQWIsQ0FBakQsRUFBc0U7QUFDcEUsV0FBT1UsU0FBUDtBQUNEOztBQUVELFFBQU1HLHFCQUFxQixJQUFJQyxHQUFKO0FBQ3pCLEdBQUNkLEtBQUQsNEJBQVdDLElBQVgsR0FBaUJjLEdBQWpCLENBQXFCQyxvQkFBckIsRUFBMkNDLE1BQTNDLENBQWtEQyxPQUFsRCxDQUR5QixDQUEzQjs7O0FBSUE7QUFDQTtBQUNBLE1BQUlMLG1CQUFtQk0sSUFBbkIsR0FBMEIsQ0FBOUIsRUFBaUM7QUFDL0IsV0FBT1QsU0FBUDtBQUNEOztBQUVEO0FBQ0E7QUFDQSxRQUFNVSxzQkFBc0JuQixLQUFLZ0IsTUFBTCxDQUFZVixRQUFRO0FBQzlDSSx5QkFBdUJKLElBQXZCLEVBQTZCTCxVQUE3QjtBQUNBVSxlQUFhTCxJQUFiLENBRjhDLENBQXBCLENBQTVCOzs7QUFLQSxRQUFNYyxhQUFhRDtBQUNoQkwsS0FEZ0IsQ0FDWlIsUUFBUTtBQUNYLFVBQU1lLFNBQVNwQixXQUFXcUIsU0FBWCxDQUFxQmhCLElBQXJCLENBQWY7QUFDQSxVQUFNaUIsWUFBWUYsT0FBT0csSUFBUCxDQUFZQyxTQUFTQyxhQUFhRCxLQUFiLEVBQW9CLEdBQXBCLENBQXJCLENBQWxCO0FBQ0EsVUFBTUUsYUFBYU4sT0FBT0csSUFBUCxDQUFZQyxTQUFTQyxhQUFhRCxLQUFiLEVBQW9CLEdBQXBCLENBQXJCLENBQW5COztBQUVBLFFBQUlGLGFBQWEsSUFBYixJQUFxQkksY0FBYyxJQUF2QyxFQUE2QztBQUMzQyxhQUFPbEIsU0FBUDtBQUNEOztBQUVELFdBQU87QUFDTG1CLGtCQUFZdEIsSUFEUDtBQUVMdUIsWUFBTTVCLFdBQVc0QixJQUFYLENBQWdCQyxLQUFoQixDQUFzQlAsVUFBVVEsS0FBVixDQUFnQixDQUFoQixDQUF0QixFQUEwQ0osV0FBV0ksS0FBWCxDQUFpQixDQUFqQixDQUExQyxDQUZEO0FBR0xDLHdCQUFrQk4sYUFBYXpCLFdBQVdnQyxjQUFYLENBQTBCTixVQUExQixDQUFiLEVBQW9ELEdBQXBELENBSGI7QUFJTE8sZUFBUyxDQUFDQyxjQUFjN0IsSUFBZCxDQUpMLEVBQVA7O0FBTUQsR0FoQmdCO0FBaUJoQlUsUUFqQmdCLENBaUJUQyxPQWpCUyxDQUFuQjs7QUFtQkEsUUFBTW1CLHFCQUFxQmpCLG9CQUFvQkgsTUFBcEIsQ0FBMkJWO0FBQ3BELEdBQUM2QixjQUFjN0IsSUFBZCxDQUFEO0FBQ0EsR0FBQ0ssYUFBYUwsSUFBYixDQUREO0FBRUEsR0FBQ2MsV0FBV2lCLElBQVgsQ0FBZ0JDLGFBQWFBLFVBQVVWLFVBQVYsS0FBeUJ0QixJQUF0RCxDQUh3QixDQUEzQjs7O0FBTUEsUUFBTWlDLG1CQUFtQnhCLHFCQUFxQmhCLEtBQXJCLEtBQStCLElBQS9CLElBQXVDYSxtQkFBbUJNLElBQW5CLEtBQTRCLENBQTVGO0FBQ0EsUUFBTXNCLHNCQUFzQnBCLFdBQVd2QixNQUFYLEdBQW9CLENBQWhEO0FBQ0EsUUFBTTRDLDBCQUEwQkwsbUJBQW1CdkMsTUFBbkIsR0FBNEIsQ0FBNUQ7O0FBRUEsTUFBSSxFQUFFMEMsb0JBQW9CQyxtQkFBcEIsSUFBMkNDLHVCQUE3QyxDQUFKLEVBQTJFO0FBQ3pFLFdBQU9oQyxTQUFQO0FBQ0Q7O0FBRUQsU0FBT2lDLFNBQVM7QUFDZCxVQUFNckIsU0FBU3BCLFdBQVdxQixTQUFYLENBQXFCdkIsS0FBckIsQ0FBZjtBQUNBLFVBQU13QixZQUFZRixPQUFPRyxJQUFQLENBQVlDLFNBQVNDLGFBQWFELEtBQWIsRUFBb0IsR0FBcEIsQ0FBckIsQ0FBbEI7QUFDQSxVQUFNRSxhQUFhTixPQUFPRyxJQUFQLENBQVlDLFNBQVNDLGFBQWFELEtBQWIsRUFBb0IsR0FBcEIsQ0FBckIsQ0FBbkI7QUFDQSxVQUFNa0IsYUFBYTFDLFdBQVcyQyxhQUFYLENBQXlCN0MsS0FBekIsQ0FBbkIsQ0FKYztBQUtjYSxzQkFMZCxXQUtQaUMsaUJBTE87O0FBT2QsVUFBTUM7QUFDSm5CLGtCQUFjLElBQWQ7QUFDQUQsaUJBQWF6QixXQUFXZ0MsY0FBWCxDQUEwQk4sVUFBMUIsQ0FBYixFQUFvRCxHQUFwRCxDQUZGO0FBR0EsVUFBTW9CLGVBQWUsQ0FBQ1osY0FBY3BDLEtBQWQsQ0FBdEIsQ0FWYzs7QUFZV3FCLGVBQVc0QixNQUFYO0FBQ3ZCLFlBQXVCVixTQUF2QixLQUFxQywwQ0FBbkNXLE1BQW1DLFlBQTNCQyxVQUEyQjtBQUNuQyxhQUFPO0FBQ0xBLG9CQUFjLENBQUNaLFVBQVVKLE9BQXpCO0FBQ0ssU0FBRWUsTUFBTyxJQUFHWCxVQUFVVCxJQUFLLEVBRGhDO0FBRUssU0FBRW9CLE1BQU8sR0FBRVgsVUFBVVQsSUFBSyxFQUgxQjtBQUlMUyxnQkFBVUosT0FBVixHQUFvQmdCLFVBQXBCLEdBQWlDLElBSjVCLENBQVA7O0FBTUQsS0FSc0I7QUFTdkIsS0FBQyxFQUFELEVBQUssQ0FBQ0oscUJBQUQsSUFBMEIsQ0FBQ0MsWUFBaEMsQ0FUdUIsQ0FaWCxtRUFZUEksY0FaTzs7O0FBd0JkLFVBQU1DLFFBQVEsRUFBZDs7QUFFQSxRQUFJYixvQkFBb0JoQixhQUFhLElBQWpDLElBQXlDaUIsbUJBQTdDLEVBQWtFO0FBQ2hFO0FBQ0FZLFlBQU1DLElBQU47QUFDRVgsWUFBTVksZUFBTixDQUFzQlgsVUFBdEIsRUFBbUMsSUFBR0UsaUJBQWtCLE1BQUtNLGNBQWUsUUFBNUUsQ0FERjs7QUFHRCxLQUxELE1BS08sSUFBSVosb0JBQW9CaEIsYUFBYSxJQUFqQyxJQUF5QyxDQUFDaUIsbUJBQTlDLEVBQW1FO0FBQ3hFO0FBQ0FZLFlBQU1DLElBQU4sQ0FBV1gsTUFBTVksZUFBTixDQUFzQlgsVUFBdEIsRUFBbUMsSUFBR0UsaUJBQWtCLE9BQXhELENBQVg7QUFDRCxLQUhNLE1BR0EsSUFBSU4sb0JBQW9CaEIsYUFBYSxJQUFqQyxJQUF5Q0ksY0FBYyxJQUEzRCxFQUFpRTtBQUN0RTtBQUNBeUIsWUFBTUMsSUFBTixDQUFXWCxNQUFNWSxlQUFOLENBQXNCWCxVQUF0QixFQUFtQyxJQUFHRSxpQkFBa0IsR0FBeEQsQ0FBWDtBQUNBLFVBQUlMLG1CQUFKLEVBQXlCO0FBQ3ZCO0FBQ0FZLGNBQU1DLElBQU4sQ0FBV1gsTUFBTWEsZ0JBQU4sQ0FBdUI1QixVQUF2QixFQUFtQ3dCLGNBQW5DLENBQVg7QUFDRDtBQUNGLEtBUE0sTUFPQSxJQUFJLENBQUNaLGdCQUFELElBQXFCaEIsYUFBYSxJQUFsQyxJQUEwQ2lCLG1CQUE5QyxFQUFtRTtBQUN4RSxVQUFJekMsTUFBTXFCLFVBQU4sQ0FBaUJ2QixNQUFqQixLQUE0QixDQUFoQyxFQUFtQztBQUNqQztBQUNBdUQsY0FBTUMsSUFBTixDQUFXWCxNQUFNWSxlQUFOLENBQXNCWCxVQUF0QixFQUFtQyxLQUFJUSxjQUFlLFFBQXRELENBQVg7QUFDRCxPQUhELE1BR087QUFDTDtBQUNBQyxjQUFNQyxJQUFOLENBQVdYLE1BQU1ZLGVBQU4sQ0FBc0J2RCxNQUFNcUIsVUFBTixDQUFpQixDQUFqQixDQUF0QixFQUE0QyxNQUFLK0IsY0FBZSxHQUFoRSxDQUFYO0FBQ0Q7QUFDRixLQVJNLE1BUUEsSUFBSSxDQUFDWixnQkFBRCxJQUFxQmhCLGFBQWEsSUFBbEMsSUFBMENJLGNBQWMsSUFBNUQsRUFBa0U7QUFDdkU7QUFDQXlCLFlBQU1DLElBQU4sQ0FBV1gsTUFBTWEsZ0JBQU4sQ0FBdUI1QixVQUF2QixFQUFtQ3dCLGNBQW5DLENBQVg7QUFDRDs7QUFFRDtBQUNBLFNBQUssTUFBTWIsU0FBWCxJQUF3QmxCLFVBQXhCLEVBQW9DO0FBQ2xDZ0MsWUFBTUMsSUFBTixDQUFXWCxNQUFNYyxNQUFOLENBQWFsQixVQUFVVixVQUF2QixDQUFYO0FBQ0Q7O0FBRUQ7QUFDQTtBQUNBO0FBQ0EsU0FBSyxNQUFNdEIsSUFBWCxJQUFtQjhCLGtCQUFuQixFQUF1QztBQUNyQ2dCLFlBQU1DLElBQU4sQ0FBV1gsTUFBTWMsTUFBTixDQUFhbEQsSUFBYixDQUFYO0FBQ0Q7O0FBRUQsV0FBTzhDLEtBQVA7QUFDRCxHQW5FRDtBQW9FRDs7QUFFRCxTQUFTMUIsWUFBVCxDQUFzQnBCLElBQXRCLEVBQTRCbUQsS0FBNUIsRUFBbUM7QUFDakMsU0FBT25ELEtBQUtvRCxJQUFMLEtBQWMsWUFBZCxJQUE4QnBELEtBQUttRCxLQUFMLEtBQWVBLEtBQXBEO0FBQ0Q7O0FBRUQ7QUFDQSxTQUFTMUMsb0JBQVQsQ0FBOEJULElBQTlCLEVBQW9DO0FBQ2xDLFFBQU1xRCxtQkFBbUJyRCxLQUFLYyxVQUFMO0FBQ3RCSSxNQURzQixDQUNqQmMsYUFBYUEsVUFBVW9CLElBQVYsS0FBbUIsd0JBRGYsQ0FBekI7QUFFQSxTQUFPQyxvQkFBb0IsSUFBcEIsR0FBMkJBLGlCQUFpQkMsS0FBakIsQ0FBdUJDLElBQWxELEdBQXlEcEQsU0FBaEU7QUFDRDs7QUFFRDtBQUNBLFNBQVNFLFlBQVQsQ0FBc0JMLElBQXRCLEVBQTRCO0FBQzFCLFFBQU1jLGFBQWFkLEtBQUtjLFVBQUw7QUFDaEJKLFFBRGdCLENBQ1RzQixhQUFhQSxVQUFVb0IsSUFBVixLQUFtQiwwQkFEdkIsQ0FBbkI7QUFFQSxTQUFPdEMsV0FBV3ZCLE1BQVgsR0FBb0IsQ0FBM0I7QUFDRDs7QUFFRDtBQUNBLFNBQVNzQyxhQUFULENBQXVCN0IsSUFBdkIsRUFBNkI7QUFDM0IsUUFBTWMsYUFBYWQsS0FBS2MsVUFBTDtBQUNoQkosUUFEZ0IsQ0FDVHNCLGFBQWFBLFVBQVVvQixJQUFWLEtBQW1CLGlCQUR2QixDQUFuQjtBQUVBLFNBQU90QyxXQUFXdkIsTUFBWCxHQUFvQixDQUEzQjtBQUNEOztBQUVEO0FBQ0E7QUFDQSxTQUFTYSxzQkFBVCxDQUFnQ0osSUFBaEMsRUFBc0NMLFVBQXRDLEVBQWtEO0FBQ2hEO0FBQ0U2RCxxQkFBaUJ4RCxJQUFqQixFQUF1QkwsVUFBdkI7QUFDQThELG9CQUFnQnpELElBQWhCLEVBQXNCTCxVQUF0QixDQURBO0FBRUErRCxrQ0FBOEIxRCxJQUE5QixFQUFvQ0wsVUFBcEMsQ0FIRjs7QUFLRDs7QUFFRDtBQUNBO0FBQ0EsU0FBUzZELGdCQUFULENBQTBCeEQsSUFBMUIsRUFBZ0NMLFVBQWhDLEVBQTRDO0FBQzFDLFNBQU9BLFdBQVdPLGlCQUFYLENBQTZCRixJQUE3QjtBQUNKK0IsTUFESSxDQUNDNEIsV0FBV0EsUUFBUUMsR0FBUixDQUFZQyxHQUFaLENBQWdCQyxJQUFoQixJQUF3QjlELEtBQUs0RCxHQUFMLENBQVNHLEtBQVQsQ0FBZUQsSUFBZixHQUFzQixDQUQxRCxDQUFQO0FBRUQ7O0FBRUQ7QUFDQTtBQUNBLFNBQVNMLGVBQVQsQ0FBeUJ6RCxJQUF6QixFQUErQkwsVUFBL0IsRUFBMkM7QUFDekMsU0FBT0EsV0FBV3FFLGdCQUFYLENBQTRCaEUsSUFBNUI7QUFDSitCLE1BREksQ0FDQzRCLFdBQVdBLFFBQVFDLEdBQVIsQ0FBWUcsS0FBWixDQUFrQkQsSUFBbEIsS0FBMkI5RCxLQUFLNEQsR0FBTCxDQUFTQyxHQUFULENBQWFDLElBRHBELENBQVA7QUFFRDs7QUFFRDtBQUNBO0FBQ0EsU0FBU0osNkJBQVQsQ0FBdUMxRCxJQUF2QyxFQUE2Q0wsVUFBN0MsRUFBeUQ7QUFDdkQsUUFBTW9CLFNBQVNwQixXQUFXcUIsU0FBWCxDQUFxQmhCLElBQXJCLENBQWY7QUFDQSxRQUFNaUUsaUJBQWlCbEQsT0FBT21ELFNBQVAsQ0FBaUIvQyxTQUFTQyxhQUFhRCxLQUFiLEVBQW9CLEdBQXBCLENBQTFCLENBQXZCO0FBQ0EsUUFBTWdELGtCQUFrQnBELE9BQU9tRCxTQUFQLENBQWlCL0MsU0FBU0MsYUFBYUQsS0FBYixFQUFvQixHQUFwQixDQUExQixDQUF4QjtBQUNBO0FBQ0E7QUFDQTtBQUNBLFFBQU1pRCxhQUFhSCxrQkFBa0IsQ0FBbEIsSUFBdUJFLG1CQUFtQixDQUExQztBQUNmcEQsU0FBT1MsS0FBUCxDQUFhLENBQWIsRUFBZ0J5QyxpQkFBaUIsQ0FBakMsRUFBb0NJLE1BQXBDLENBQTJDdEQsT0FBT1MsS0FBUCxDQUFhMkMsa0JBQWtCLENBQS9CLENBQTNDLENBRGU7QUFFZnBELFNBQU9TLEtBQVAsQ0FBYSxDQUFiLENBRko7QUFHQSxTQUFPNEMsV0FBV3JDLElBQVgsQ0FBZ0JaLFNBQVN4QixXQUFXTyxpQkFBWCxDQUE2QmlCLEtBQTdCLEVBQW9DNUIsTUFBcEMsR0FBNkMsQ0FBdEUsQ0FBUDtBQUNEOztBQUVERixPQUFPaUYsT0FBUCxHQUFpQjtBQUNmQyxRQUFNO0FBQ0puQixVQUFNLFNBREY7QUFFSm9CLFVBQU07QUFDSkMsV0FBSyx1QkFBUSxlQUFSLENBREQsRUFGRjs7QUFLSkMsYUFBUyxNQUxMO0FBTUpDLFlBQVE7QUFDTjtBQUNFdkIsWUFBTSxRQURSO0FBRUV3QixrQkFBWTtBQUNWQyw2QkFBcUI7QUFDbkJ6QixnQkFBTSxTQURhLEVBRFgsRUFGZDs7O0FBT0UwQiw0QkFBc0IsS0FQeEIsRUFETSxDQU5KLEVBRFM7Ozs7O0FBb0JmQyxVQUFRLFVBQVU1RixPQUFWLEVBQW1CO0FBQ3pCO0FBQ0EsVUFBTTZGLDRCQUE0QjdGLFFBQVE4RixPQUFSLENBQWdCLENBQWhCO0FBQ2hDOUYsWUFBUThGLE9BQVIsQ0FBZ0IsQ0FBaEIsRUFBbUIscUJBQW5CLENBREY7QUFFQSxVQUFNQyxrQkFBa0JDLGNBQWMsdUJBQVFBLFVBQVIsRUFBb0JoRyxPQUFwQixLQUFnQ2dHLFVBQXRFO0FBQ0EsVUFBTUMsV0FBV0osNEJBQTZCRyxjQUFjO0FBQzFELFlBQU1FLFFBQVFGLFdBQVdHLEtBQVgsQ0FBaUIsaUJBQWpCLENBQWQ7QUFDQSxVQUFJLENBQUNELEtBQUwsRUFBWTtBQUNWLGVBQU9ILGdCQUFnQkMsVUFBaEIsQ0FBUDtBQUNEO0FBQ0QsYUFBT0QsZ0JBQWdCRyxNQUFNLENBQU4sQ0FBaEIsSUFBNEIsR0FBNUIsR0FBa0NBLE1BQU0sQ0FBTixDQUF6QztBQUNELEtBTmdCLEdBTVpILGVBTkw7O0FBUUEsVUFBTWhHLFdBQVcsSUFBSXFHLEdBQUosRUFBakI7QUFDQSxVQUFNQyxhQUFhLElBQUlELEdBQUosRUFBbkI7QUFDQSxVQUFNRSxnQkFBZ0IsSUFBSUYsR0FBSixFQUF0QjtBQUNBLFdBQU87QUFDTCwyQkFBcUIsVUFBVUcsQ0FBVixFQUFhO0FBQ2hDO0FBQ0EsY0FBTUMsZUFBZVAsU0FBU00sRUFBRXpGLE1BQUYsQ0FBU2tELEtBQWxCLENBQXJCO0FBQ0EsY0FBTXlDLFlBQVlGLEVBQUVHLFVBQUYsS0FBaUIsTUFBakIsR0FBMEJKLGFBQTFCO0FBQ2ZwRixxQkFBYXFGLENBQWIsSUFBa0JGLFVBQWxCLEdBQStCdEcsUUFEbEM7O0FBR0EsWUFBSTBHLFVBQVVFLEdBQVYsQ0FBY0gsWUFBZCxDQUFKLEVBQWlDO0FBQy9CQyxvQkFBVUcsR0FBVixDQUFjSixZQUFkLEVBQTRCNUMsSUFBNUIsQ0FBaUMyQyxDQUFqQztBQUNELFNBRkQsTUFFTztBQUNMRSxvQkFBVUksR0FBVixDQUFjTCxZQUFkLEVBQTRCLENBQUNELENBQUQsQ0FBNUI7QUFDRDtBQUNGLE9BWkk7O0FBY0wsc0JBQWdCLFlBQVk7QUFDMUJ6RyxxQkFBYUMsUUFBYixFQUF1QkMsT0FBdkI7QUFDQUYscUJBQWF1RyxVQUFiLEVBQXlCckcsT0FBekI7QUFDQUYscUJBQWF3RyxhQUFiLEVBQTRCdEcsT0FBNUI7QUFDRCxPQWxCSSxFQUFQOztBQW9CRCxHQXhEYyxFQUFqQiIsImZpbGUiOiJuby1kdXBsaWNhdGVzLmpzIiwic291cmNlc0NvbnRlbnQiOlsiaW1wb3J0IHJlc29sdmUgZnJvbSAnZXNsaW50LW1vZHVsZS11dGlscy9yZXNvbHZlJ1xuaW1wb3J0IGRvY3NVcmwgZnJvbSAnLi4vZG9jc1VybCdcblxuZnVuY3Rpb24gY2hlY2tJbXBvcnRzKGltcG9ydGVkLCBjb250ZXh0KSB7XG4gIGZvciAoY29uc3QgW21vZHVsZSwgbm9kZXNdIG9mIGltcG9ydGVkLmVudHJpZXMoKSkge1xuICAgIGlmIChub2Rlcy5sZW5ndGggPiAxKSB7XG4gICAgICBjb25zdCBtZXNzYWdlID0gYCcke21vZHVsZX0nIGltcG9ydGVkIG11bHRpcGxlIHRpbWVzLmBcbiAgICAgIGNvbnN0IFtmaXJzdCwgLi4ucmVzdF0gPSBub2Rlc1xuICAgICAgY29uc3Qgc291cmNlQ29kZSA9IGNvbnRleHQuZ2V0U291cmNlQ29kZSgpXG4gICAgICBjb25zdCBmaXggPSBnZXRGaXgoZmlyc3QsIHJlc3QsIHNvdXJjZUNvZGUpXG5cbiAgICAgIGNvbnRleHQucmVwb3J0KHtcbiAgICAgICAgbm9kZTogZmlyc3Quc291cmNlLFxuICAgICAgICBtZXNzYWdlLFxuICAgICAgICBmaXgsIC8vIEF0dGFjaCB0aGUgYXV0b2ZpeCAoaWYgYW55KSB0byB0aGUgZmlyc3QgaW1wb3J0LlxuICAgICAgfSlcblxuICAgICAgZm9yIChjb25zdCBub2RlIG9mIHJlc3QpIHtcbiAgICAgICAgY29udGV4dC5yZXBvcnQoe1xuICAgICAgICAgIG5vZGU6IG5vZGUuc291cmNlLFxuICAgICAgICAgIG1lc3NhZ2UsXG4gICAgICAgIH0pXG4gICAgICB9XG4gICAgfVxuICB9XG59XG5cbmZ1bmN0aW9uIGdldEZpeChmaXJzdCwgcmVzdCwgc291cmNlQ29kZSkge1xuICAvLyBTb3JyeSBFU0xpbnQgPD0gMyB1c2Vycywgbm8gYXV0b2ZpeCBmb3IgeW91LiBBdXRvZml4aW5nIGR1cGxpY2F0ZSBpbXBvcnRzXG4gIC8vIHJlcXVpcmVzIG11bHRpcGxlIGBmaXhlci53aGF0ZXZlcigpYCBjYWxscyBpbiB0aGUgYGZpeGA6IFdlIGJvdGggbmVlZCB0b1xuICAvLyB1cGRhdGUgdGhlIGZpcnN0IG9uZSwgYW5kIHJlbW92ZSB0aGUgcmVzdC4gU3VwcG9ydCBmb3IgbXVsdGlwbGVcbiAgLy8gYGZpeGVyLndoYXRldmVyKClgIGluIGEgc2luZ2xlIGBmaXhgIHdhcyBhZGRlZCBpbiBFU0xpbnQgNC4xLlxuICAvLyBgc291cmNlQ29kZS5nZXRDb21tZW50c0JlZm9yZWAgd2FzIGFkZGVkIGluIDQuMCwgc28gdGhhdCdzIGFuIGVhc3kgdGhpbmcgdG9cbiAgLy8gY2hlY2sgZm9yLlxuICBpZiAodHlwZW9mIHNvdXJjZUNvZGUuZ2V0Q29tbWVudHNCZWZvcmUgIT09ICdmdW5jdGlvbicpIHtcbiAgICByZXR1cm4gdW5kZWZpbmVkXG4gIH1cblxuICAvLyBBZGp1c3RpbmcgdGhlIGZpcnN0IGltcG9ydCBtaWdodCBtYWtlIGl0IG11bHRpbGluZSwgd2hpY2ggY291bGQgYnJlYWtcbiAgLy8gYGVzbGludC1kaXNhYmxlLW5leHQtbGluZWAgY29tbWVudHMgYW5kIHNpbWlsYXIsIHNvIGJhaWwgaWYgdGhlIGZpcnN0XG4gIC8vIGltcG9ydCBoYXMgY29tbWVudHMuIEFsc28sIGlmIHRoZSBmaXJzdCBpbXBvcnQgaXMgYGltcG9ydCAqIGFzIG5zIGZyb21cbiAgLy8gJy4vZm9vJ2AgdGhlcmUncyBub3RoaW5nIHdlIGNhbiBkby5cbiAgaWYgKGhhc1Byb2JsZW1hdGljQ29tbWVudHMoZmlyc3QsIHNvdXJjZUNvZGUpIHx8IGhhc05hbWVzcGFjZShmaXJzdCkpIHtcbiAgICByZXR1cm4gdW5kZWZpbmVkXG4gIH1cblxuICBjb25zdCBkZWZhdWx0SW1wb3J0TmFtZXMgPSBuZXcgU2V0KFxuICAgIFtmaXJzdCwgLi4ucmVzdF0ubWFwKGdldERlZmF1bHRJbXBvcnROYW1lKS5maWx0ZXIoQm9vbGVhbilcbiAgKVxuXG4gIC8vIEJhaWwgaWYgdGhlcmUgYXJlIG11bHRpcGxlIGRpZmZlcmVudCBkZWZhdWx0IGltcG9ydCBuYW1lcyDigJMgaXQncyB1cCB0byB0aGVcbiAgLy8gdXNlciB0byBjaG9vc2Ugd2hpY2ggb25lIHRvIGtlZXAuXG4gIGlmIChkZWZhdWx0SW1wb3J0TmFtZXMuc2l6ZSA+IDEpIHtcbiAgICByZXR1cm4gdW5kZWZpbmVkXG4gIH1cblxuICAvLyBMZWF2ZSBpdCB0byB0aGUgdXNlciB0byBoYW5kbGUgY29tbWVudHMuIEFsc28gc2tpcCBgaW1wb3J0ICogYXMgbnMgZnJvbVxuICAvLyAnLi9mb28nYCBpbXBvcnRzLCBzaW5jZSB0aGV5IGNhbm5vdCBiZSBtZXJnZWQgaW50byBhbm90aGVyIGltcG9ydC5cbiAgY29uc3QgcmVzdFdpdGhvdXRDb21tZW50cyA9IHJlc3QuZmlsdGVyKG5vZGUgPT4gIShcbiAgICBoYXNQcm9ibGVtYXRpY0NvbW1lbnRzKG5vZGUsIHNvdXJjZUNvZGUpIHx8XG4gICAgaGFzTmFtZXNwYWNlKG5vZGUpXG4gICkpXG5cbiAgY29uc3Qgc3BlY2lmaWVycyA9IHJlc3RXaXRob3V0Q29tbWVudHNcbiAgICAubWFwKG5vZGUgPT4ge1xuICAgICAgY29uc3QgdG9rZW5zID0gc291cmNlQ29kZS5nZXRUb2tlbnMobm9kZSlcbiAgICAgIGNvbnN0IG9wZW5CcmFjZSA9IHRva2Vucy5maW5kKHRva2VuID0+IGlzUHVuY3R1YXRvcih0b2tlbiwgJ3snKSlcbiAgICAgIGNvbnN0IGNsb3NlQnJhY2UgPSB0b2tlbnMuZmluZCh0b2tlbiA9PiBpc1B1bmN0dWF0b3IodG9rZW4sICd9JykpXG5cbiAgICAgIGlmIChvcGVuQnJhY2UgPT0gbnVsbCB8fCBjbG9zZUJyYWNlID09IG51bGwpIHtcbiAgICAgICAgcmV0dXJuIHVuZGVmaW5lZFxuICAgICAgfVxuXG4gICAgICByZXR1cm4ge1xuICAgICAgICBpbXBvcnROb2RlOiBub2RlLFxuICAgICAgICB0ZXh0OiBzb3VyY2VDb2RlLnRleHQuc2xpY2Uob3BlbkJyYWNlLnJhbmdlWzFdLCBjbG9zZUJyYWNlLnJhbmdlWzBdKSxcbiAgICAgICAgaGFzVHJhaWxpbmdDb21tYTogaXNQdW5jdHVhdG9yKHNvdXJjZUNvZGUuZ2V0VG9rZW5CZWZvcmUoY2xvc2VCcmFjZSksICcsJyksXG4gICAgICAgIGlzRW1wdHk6ICFoYXNTcGVjaWZpZXJzKG5vZGUpLFxuICAgICAgfVxuICAgIH0pXG4gICAgLmZpbHRlcihCb29sZWFuKVxuXG4gIGNvbnN0IHVubmVjZXNzYXJ5SW1wb3J0cyA9IHJlc3RXaXRob3V0Q29tbWVudHMuZmlsdGVyKG5vZGUgPT5cbiAgICAhaGFzU3BlY2lmaWVycyhub2RlKSAmJlxuICAgICFoYXNOYW1lc3BhY2Uobm9kZSkgJiZcbiAgICAhc3BlY2lmaWVycy5zb21lKHNwZWNpZmllciA9PiBzcGVjaWZpZXIuaW1wb3J0Tm9kZSA9PT0gbm9kZSlcbiAgKVxuXG4gIGNvbnN0IHNob3VsZEFkZERlZmF1bHQgPSBnZXREZWZhdWx0SW1wb3J0TmFtZShmaXJzdCkgPT0gbnVsbCAmJiBkZWZhdWx0SW1wb3J0TmFtZXMuc2l6ZSA9PT0gMVxuICBjb25zdCBzaG91bGRBZGRTcGVjaWZpZXJzID0gc3BlY2lmaWVycy5sZW5ndGggPiAwXG4gIGNvbnN0IHNob3VsZFJlbW92ZVVubmVjZXNzYXJ5ID0gdW5uZWNlc3NhcnlJbXBvcnRzLmxlbmd0aCA+IDBcblxuICBpZiAoIShzaG91bGRBZGREZWZhdWx0IHx8IHNob3VsZEFkZFNwZWNpZmllcnMgfHwgc2hvdWxkUmVtb3ZlVW5uZWNlc3NhcnkpKSB7XG4gICAgcmV0dXJuIHVuZGVmaW5lZFxuICB9XG5cbiAgcmV0dXJuIGZpeGVyID0+IHtcbiAgICBjb25zdCB0b2tlbnMgPSBzb3VyY2VDb2RlLmdldFRva2VucyhmaXJzdClcbiAgICBjb25zdCBvcGVuQnJhY2UgPSB0b2tlbnMuZmluZCh0b2tlbiA9PiBpc1B1bmN0dWF0b3IodG9rZW4sICd7JykpXG4gICAgY29uc3QgY2xvc2VCcmFjZSA9IHRva2Vucy5maW5kKHRva2VuID0+IGlzUHVuY3R1YXRvcih0b2tlbiwgJ30nKSlcbiAgICBjb25zdCBmaXJzdFRva2VuID0gc291cmNlQ29kZS5nZXRGaXJzdFRva2VuKGZpcnN0KVxuICAgIGNvbnN0IFtkZWZhdWx0SW1wb3J0TmFtZV0gPSBkZWZhdWx0SW1wb3J0TmFtZXNcblxuICAgIGNvbnN0IGZpcnN0SGFzVHJhaWxpbmdDb21tYSA9XG4gICAgICBjbG9zZUJyYWNlICE9IG51bGwgJiZcbiAgICAgIGlzUHVuY3R1YXRvcihzb3VyY2VDb2RlLmdldFRva2VuQmVmb3JlKGNsb3NlQnJhY2UpLCAnLCcpXG4gICAgY29uc3QgZmlyc3RJc0VtcHR5ID0gIWhhc1NwZWNpZmllcnMoZmlyc3QpXG5cbiAgICBjb25zdCBbc3BlY2lmaWVyc1RleHRdID0gc3BlY2lmaWVycy5yZWR1Y2UoXG4gICAgICAoW3Jlc3VsdCwgbmVlZHNDb21tYV0sIHNwZWNpZmllcikgPT4ge1xuICAgICAgICByZXR1cm4gW1xuICAgICAgICAgIG5lZWRzQ29tbWEgJiYgIXNwZWNpZmllci5pc0VtcHR5XG4gICAgICAgICAgICA/IGAke3Jlc3VsdH0sJHtzcGVjaWZpZXIudGV4dH1gXG4gICAgICAgICAgICA6IGAke3Jlc3VsdH0ke3NwZWNpZmllci50ZXh0fWAsXG4gICAgICAgICAgc3BlY2lmaWVyLmlzRW1wdHkgPyBuZWVkc0NvbW1hIDogdHJ1ZSxcbiAgICAgICAgXVxuICAgICAgfSxcbiAgICAgIFsnJywgIWZpcnN0SGFzVHJhaWxpbmdDb21tYSAmJiAhZmlyc3RJc0VtcHR5XVxuICAgIClcblxuICAgIGNvbnN0IGZpeGVzID0gW11cblxuICAgIGlmIChzaG91bGRBZGREZWZhdWx0ICYmIG9wZW5CcmFjZSA9PSBudWxsICYmIHNob3VsZEFkZFNwZWNpZmllcnMpIHtcbiAgICAgIC8vIGBpbXBvcnQgJy4vZm9vJ2Ag4oaSIGBpbXBvcnQgZGVmLCB7Li4ufSBmcm9tICcuL2ZvbydgXG4gICAgICBmaXhlcy5wdXNoKFxuICAgICAgICBmaXhlci5pbnNlcnRUZXh0QWZ0ZXIoZmlyc3RUb2tlbiwgYCAke2RlZmF1bHRJbXBvcnROYW1lfSwgeyR7c3BlY2lmaWVyc1RleHR9fSBmcm9tYClcbiAgICAgIClcbiAgICB9IGVsc2UgaWYgKHNob3VsZEFkZERlZmF1bHQgJiYgb3BlbkJyYWNlID09IG51bGwgJiYgIXNob3VsZEFkZFNwZWNpZmllcnMpIHtcbiAgICAgIC8vIGBpbXBvcnQgJy4vZm9vJ2Ag4oaSIGBpbXBvcnQgZGVmIGZyb20gJy4vZm9vJ2BcbiAgICAgIGZpeGVzLnB1c2goZml4ZXIuaW5zZXJ0VGV4dEFmdGVyKGZpcnN0VG9rZW4sIGAgJHtkZWZhdWx0SW1wb3J0TmFtZX0gZnJvbWApKVxuICAgIH0gZWxzZSBpZiAoc2hvdWxkQWRkRGVmYXVsdCAmJiBvcGVuQnJhY2UgIT0gbnVsbCAmJiBjbG9zZUJyYWNlICE9IG51bGwpIHtcbiAgICAgIC8vIGBpbXBvcnQgey4uLn0gZnJvbSAnLi9mb28nYCDihpIgYGltcG9ydCBkZWYsIHsuLi59IGZyb20gJy4vZm9vJ2BcbiAgICAgIGZpeGVzLnB1c2goZml4ZXIuaW5zZXJ0VGV4dEFmdGVyKGZpcnN0VG9rZW4sIGAgJHtkZWZhdWx0SW1wb3J0TmFtZX0sYCkpXG4gICAgICBpZiAoc2hvdWxkQWRkU3BlY2lmaWVycykge1xuICAgICAgICAvLyBgaW1wb3J0IGRlZiwgey4uLn0gZnJvbSAnLi9mb28nYCDihpIgYGltcG9ydCBkZWYsIHsuLi4sIC4uLn0gZnJvbSAnLi9mb28nYFxuICAgICAgICBmaXhlcy5wdXNoKGZpeGVyLmluc2VydFRleHRCZWZvcmUoY2xvc2VCcmFjZSwgc3BlY2lmaWVyc1RleHQpKVxuICAgICAgfVxuICAgIH0gZWxzZSBpZiAoIXNob3VsZEFkZERlZmF1bHQgJiYgb3BlbkJyYWNlID09IG51bGwgJiYgc2hvdWxkQWRkU3BlY2lmaWVycykge1xuICAgICAgaWYgKGZpcnN0LnNwZWNpZmllcnMubGVuZ3RoID09PSAwKSB7XG4gICAgICAgIC8vIGBpbXBvcnQgJy4vZm9vJ2Ag4oaSIGBpbXBvcnQgey4uLn0gZnJvbSAnLi9mb28nYFxuICAgICAgICBmaXhlcy5wdXNoKGZpeGVyLmluc2VydFRleHRBZnRlcihmaXJzdFRva2VuLCBgIHske3NwZWNpZmllcnNUZXh0fX0gZnJvbWApKVxuICAgICAgfSBlbHNlIHtcbiAgICAgICAgLy8gYGltcG9ydCBkZWYgZnJvbSAnLi9mb28nYCDihpIgYGltcG9ydCBkZWYsIHsuLi59IGZyb20gJy4vZm9vJ2BcbiAgICAgICAgZml4ZXMucHVzaChmaXhlci5pbnNlcnRUZXh0QWZ0ZXIoZmlyc3Quc3BlY2lmaWVyc1swXSwgYCwgeyR7c3BlY2lmaWVyc1RleHR9fWApKVxuICAgICAgfVxuICAgIH0gZWxzZSBpZiAoIXNob3VsZEFkZERlZmF1bHQgJiYgb3BlbkJyYWNlICE9IG51bGwgJiYgY2xvc2VCcmFjZSAhPSBudWxsKSB7XG4gICAgICAvLyBgaW1wb3J0IHsuLi59ICcuL2ZvbydgIOKGkiBgaW1wb3J0IHsuLi4sIC4uLn0gZnJvbSAnLi9mb28nYFxuICAgICAgZml4ZXMucHVzaChmaXhlci5pbnNlcnRUZXh0QmVmb3JlKGNsb3NlQnJhY2UsIHNwZWNpZmllcnNUZXh0KSlcbiAgICB9XG5cbiAgICAvLyBSZW1vdmUgaW1wb3J0cyB3aG9zZSBzcGVjaWZpZXJzIGhhdmUgYmVlbiBtb3ZlZCBpbnRvIHRoZSBmaXJzdCBpbXBvcnQuXG4gICAgZm9yIChjb25zdCBzcGVjaWZpZXIgb2Ygc3BlY2lmaWVycykge1xuICAgICAgZml4ZXMucHVzaChmaXhlci5yZW1vdmUoc3BlY2lmaWVyLmltcG9ydE5vZGUpKVxuICAgIH1cblxuICAgIC8vIFJlbW92ZSBpbXBvcnRzIHdob3NlIGRlZmF1bHQgaW1wb3J0IGhhcyBiZWVuIG1vdmVkIHRvIHRoZSBmaXJzdCBpbXBvcnQsXG4gICAgLy8gYW5kIHNpZGUtZWZmZWN0LW9ubHkgaW1wb3J0cyB0aGF0IGFyZSB1bm5lY2Vzc2FyeSBkdWUgdG8gdGhlIGZpcnN0XG4gICAgLy8gaW1wb3J0LlxuICAgIGZvciAoY29uc3Qgbm9kZSBvZiB1bm5lY2Vzc2FyeUltcG9ydHMpIHtcbiAgICAgIGZpeGVzLnB1c2goZml4ZXIucmVtb3ZlKG5vZGUpKVxuICAgIH1cblxuICAgIHJldHVybiBmaXhlc1xuICB9XG59XG5cbmZ1bmN0aW9uIGlzUHVuY3R1YXRvcihub2RlLCB2YWx1ZSkge1xuICByZXR1cm4gbm9kZS50eXBlID09PSAnUHVuY3R1YXRvcicgJiYgbm9kZS52YWx1ZSA9PT0gdmFsdWVcbn1cblxuLy8gR2V0IHRoZSBuYW1lIG9mIHRoZSBkZWZhdWx0IGltcG9ydCBvZiBgbm9kZWAsIGlmIGFueS5cbmZ1bmN0aW9uIGdldERlZmF1bHRJbXBvcnROYW1lKG5vZGUpIHtcbiAgY29uc3QgZGVmYXVsdFNwZWNpZmllciA9IG5vZGUuc3BlY2lmaWVyc1xuICAgIC5maW5kKHNwZWNpZmllciA9PiBzcGVjaWZpZXIudHlwZSA9PT0gJ0ltcG9ydERlZmF1bHRTcGVjaWZpZXInKVxuICByZXR1cm4gZGVmYXVsdFNwZWNpZmllciAhPSBudWxsID8gZGVmYXVsdFNwZWNpZmllci5sb2NhbC5uYW1lIDogdW5kZWZpbmVkXG59XG5cbi8vIENoZWNrcyB3aGV0aGVyIGBub2RlYCBoYXMgYSBuYW1lc3BhY2UgaW1wb3J0LlxuZnVuY3Rpb24gaGFzTmFtZXNwYWNlKG5vZGUpIHtcbiAgY29uc3Qgc3BlY2lmaWVycyA9IG5vZGUuc3BlY2lmaWVyc1xuICAgIC5maWx0ZXIoc3BlY2lmaWVyID0+IHNwZWNpZmllci50eXBlID09PSAnSW1wb3J0TmFtZXNwYWNlU3BlY2lmaWVyJylcbiAgcmV0dXJuIHNwZWNpZmllcnMubGVuZ3RoID4gMFxufVxuXG4vLyBDaGVja3Mgd2hldGhlciBgbm9kZWAgaGFzIGFueSBub24tZGVmYXVsdCBzcGVjaWZpZXJzLlxuZnVuY3Rpb24gaGFzU3BlY2lmaWVycyhub2RlKSB7XG4gIGNvbnN0IHNwZWNpZmllcnMgPSBub2RlLnNwZWNpZmllcnNcbiAgICAuZmlsdGVyKHNwZWNpZmllciA9PiBzcGVjaWZpZXIudHlwZSA9PT0gJ0ltcG9ydFNwZWNpZmllcicpXG4gIHJldHVybiBzcGVjaWZpZXJzLmxlbmd0aCA+IDBcbn1cblxuLy8gSXQncyBub3Qgb2J2aW91cyB3aGF0IHRoZSB1c2VyIHdhbnRzIHRvIGRvIHdpdGggY29tbWVudHMgYXNzb2NpYXRlZCB3aXRoXG4vLyBkdXBsaWNhdGUgaW1wb3J0cywgc28gc2tpcCBpbXBvcnRzIHdpdGggY29tbWVudHMgd2hlbiBhdXRvZml4aW5nLlxuZnVuY3Rpb24gaGFzUHJvYmxlbWF0aWNDb21tZW50cyhub2RlLCBzb3VyY2VDb2RlKSB7XG4gIHJldHVybiAoXG4gICAgaGFzQ29tbWVudEJlZm9yZShub2RlLCBzb3VyY2VDb2RlKSB8fFxuICAgIGhhc0NvbW1lbnRBZnRlcihub2RlLCBzb3VyY2VDb2RlKSB8fFxuICAgIGhhc0NvbW1lbnRJbnNpZGVOb25TcGVjaWZpZXJzKG5vZGUsIHNvdXJjZUNvZGUpXG4gIClcbn1cblxuLy8gQ2hlY2tzIHdoZXRoZXIgYG5vZGVgIGhhcyBhIGNvbW1lbnQgKHRoYXQgZW5kcykgb24gdGhlIHByZXZpb3VzIGxpbmUgb3Igb25cbi8vIHRoZSBzYW1lIGxpbmUgYXMgYG5vZGVgIChzdGFydHMpLlxuZnVuY3Rpb24gaGFzQ29tbWVudEJlZm9yZShub2RlLCBzb3VyY2VDb2RlKSB7XG4gIHJldHVybiBzb3VyY2VDb2RlLmdldENvbW1lbnRzQmVmb3JlKG5vZGUpXG4gICAgLnNvbWUoY29tbWVudCA9PiBjb21tZW50LmxvYy5lbmQubGluZSA+PSBub2RlLmxvYy5zdGFydC5saW5lIC0gMSlcbn1cblxuLy8gQ2hlY2tzIHdoZXRoZXIgYG5vZGVgIGhhcyBhIGNvbW1lbnQgKHRoYXQgc3RhcnRzKSBvbiB0aGUgc2FtZSBsaW5lIGFzIGBub2RlYFxuLy8gKGVuZHMpLlxuZnVuY3Rpb24gaGFzQ29tbWVudEFmdGVyKG5vZGUsIHNvdXJjZUNvZGUpIHtcbiAgcmV0dXJuIHNvdXJjZUNvZGUuZ2V0Q29tbWVudHNBZnRlcihub2RlKVxuICAgIC5zb21lKGNvbW1lbnQgPT4gY29tbWVudC5sb2Muc3RhcnQubGluZSA9PT0gbm9kZS5sb2MuZW5kLmxpbmUpXG59XG5cbi8vIENoZWNrcyB3aGV0aGVyIGBub2RlYCBoYXMgYW55IGNvbW1lbnRzIF9pbnNpZGUsXyBleGNlcHQgaW5zaWRlIHRoZSBgey4uLn1gXG4vLyBwYXJ0IChpZiBhbnkpLlxuZnVuY3Rpb24gaGFzQ29tbWVudEluc2lkZU5vblNwZWNpZmllcnMobm9kZSwgc291cmNlQ29kZSkge1xuICBjb25zdCB0b2tlbnMgPSBzb3VyY2VDb2RlLmdldFRva2Vucyhub2RlKVxuICBjb25zdCBvcGVuQnJhY2VJbmRleCA9IHRva2Vucy5maW5kSW5kZXgodG9rZW4gPT4gaXNQdW5jdHVhdG9yKHRva2VuLCAneycpKVxuICBjb25zdCBjbG9zZUJyYWNlSW5kZXggPSB0b2tlbnMuZmluZEluZGV4KHRva2VuID0+IGlzUHVuY3R1YXRvcih0b2tlbiwgJ30nKSlcbiAgLy8gU2xpY2UgYXdheSB0aGUgZmlyc3QgdG9rZW4sIHNpbmNlIHdlJ3JlIG5vIGxvb2tpbmcgZm9yIGNvbW1lbnRzIF9iZWZvcmVfXG4gIC8vIGBub2RlYCAob25seSBpbnNpZGUpLiBJZiB0aGVyZSdzIGEgYHsuLi59YCBwYXJ0LCBsb29rIGZvciBjb21tZW50cyBiZWZvcmVcbiAgLy8gdGhlIGB7YCwgYnV0IG5vdCBiZWZvcmUgdGhlIGB9YCAoaGVuY2UgdGhlIGArMWBzKS5cbiAgY29uc3Qgc29tZVRva2VucyA9IG9wZW5CcmFjZUluZGV4ID49IDAgJiYgY2xvc2VCcmFjZUluZGV4ID49IDBcbiAgICA/IHRva2Vucy5zbGljZSgxLCBvcGVuQnJhY2VJbmRleCArIDEpLmNvbmNhdCh0b2tlbnMuc2xpY2UoY2xvc2VCcmFjZUluZGV4ICsgMSkpXG4gICAgOiB0b2tlbnMuc2xpY2UoMSlcbiAgcmV0dXJuIHNvbWVUb2tlbnMuc29tZSh0b2tlbiA9PiBzb3VyY2VDb2RlLmdldENvbW1lbnRzQmVmb3JlKHRva2VuKS5sZW5ndGggPiAwKVxufVxuXG5tb2R1bGUuZXhwb3J0cyA9IHtcbiAgbWV0YToge1xuICAgIHR5cGU6ICdwcm9ibGVtJyxcbiAgICBkb2NzOiB7XG4gICAgICB1cmw6IGRvY3NVcmwoJ25vLWR1cGxpY2F0ZXMnKSxcbiAgICB9LFxuICAgIGZpeGFibGU6ICdjb2RlJyxcbiAgICBzY2hlbWE6IFtcbiAgICAgIHtcbiAgICAgICAgdHlwZTogJ29iamVjdCcsXG4gICAgICAgIHByb3BlcnRpZXM6IHtcbiAgICAgICAgICBjb25zaWRlclF1ZXJ5U3RyaW5nOiB7XG4gICAgICAgICAgICB0eXBlOiAnYm9vbGVhbicsXG4gICAgICAgICAgfSxcbiAgICAgICAgfSxcbiAgICAgICAgYWRkaXRpb25hbFByb3BlcnRpZXM6IGZhbHNlLFxuICAgICAgfSxcbiAgICBdLFxuICB9LFxuXG4gIGNyZWF0ZTogZnVuY3Rpb24gKGNvbnRleHQpIHtcbiAgICAvLyBQcmVwYXJlIHRoZSByZXNvbHZlciBmcm9tIG9wdGlvbnMuXG4gICAgY29uc3QgY29uc2lkZXJRdWVyeVN0cmluZ09wdGlvbiA9IGNvbnRleHQub3B0aW9uc1swXSAmJlxuICAgICAgY29udGV4dC5vcHRpb25zWzBdWydjb25zaWRlclF1ZXJ5U3RyaW5nJ11cbiAgICBjb25zdCBkZWZhdWx0UmVzb2x2ZXIgPSBzb3VyY2VQYXRoID0+IHJlc29sdmUoc291cmNlUGF0aCwgY29udGV4dCkgfHwgc291cmNlUGF0aFxuICAgIGNvbnN0IHJlc29sdmVyID0gY29uc2lkZXJRdWVyeVN0cmluZ09wdGlvbiA/IChzb3VyY2VQYXRoID0+IHtcbiAgICAgIGNvbnN0IHBhcnRzID0gc291cmNlUGF0aC5tYXRjaCgvXihbXj9dKilcXD8oLiopJC8pXG4gICAgICBpZiAoIXBhcnRzKSB7XG4gICAgICAgIHJldHVybiBkZWZhdWx0UmVzb2x2ZXIoc291cmNlUGF0aClcbiAgICAgIH1cbiAgICAgIHJldHVybiBkZWZhdWx0UmVzb2x2ZXIocGFydHNbMV0pICsgJz8nICsgcGFydHNbMl1cbiAgICB9KSA6IGRlZmF1bHRSZXNvbHZlclxuXG4gICAgY29uc3QgaW1wb3J0ZWQgPSBuZXcgTWFwKClcbiAgICBjb25zdCBuc0ltcG9ydGVkID0gbmV3IE1hcCgpXG4gICAgY29uc3QgdHlwZXNJbXBvcnRlZCA9IG5ldyBNYXAoKVxuICAgIHJldHVybiB7XG4gICAgICAnSW1wb3J0RGVjbGFyYXRpb24nOiBmdW5jdGlvbiAobikge1xuICAgICAgICAvLyByZXNvbHZlZCBwYXRoIHdpbGwgY292ZXIgYWxpYXNlZCBkdXBsaWNhdGVzXG4gICAgICAgIGNvbnN0IHJlc29sdmVkUGF0aCA9IHJlc29sdmVyKG4uc291cmNlLnZhbHVlKVxuICAgICAgICBjb25zdCBpbXBvcnRNYXAgPSBuLmltcG9ydEtpbmQgPT09ICd0eXBlJyA/IHR5cGVzSW1wb3J0ZWQgOlxuICAgICAgICAgIChoYXNOYW1lc3BhY2UobikgPyBuc0ltcG9ydGVkIDogaW1wb3J0ZWQpXG5cbiAgICAgICAgaWYgKGltcG9ydE1hcC5oYXMocmVzb2x2ZWRQYXRoKSkge1xuICAgICAgICAgIGltcG9ydE1hcC5nZXQocmVzb2x2ZWRQYXRoKS5wdXNoKG4pXG4gICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgaW1wb3J0TWFwLnNldChyZXNvbHZlZFBhdGgsIFtuXSlcbiAgICAgICAgfVxuICAgICAgfSxcblxuICAgICAgJ1Byb2dyYW06ZXhpdCc6IGZ1bmN0aW9uICgpIHtcbiAgICAgICAgY2hlY2tJbXBvcnRzKGltcG9ydGVkLCBjb250ZXh0KVxuICAgICAgICBjaGVja0ltcG9ydHMobnNJbXBvcnRlZCwgY29udGV4dClcbiAgICAgICAgY2hlY2tJbXBvcnRzKHR5cGVzSW1wb3J0ZWQsIGNvbnRleHQpXG4gICAgICB9LFxuICAgIH1cbiAgfSxcbn1cbiJdfQ==