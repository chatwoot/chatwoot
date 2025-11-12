'use strict';var _docsUrl = require('../docsUrl');var _docsUrl2 = _interopRequireDefault(_docsUrl);function _interopRequireDefault(obj) {return obj && obj.__esModule ? obj : { 'default': obj };}

function isComma(token) {
  return token.type === 'Punctuator' && token.value === ',';
}

function removeSpecifiers(fixes, fixer, sourceCode, specifiers) {var _iteratorNormalCompletion = true;var _didIteratorError = false;var _iteratorError = undefined;try {
    for (var _iterator = specifiers[Symbol.iterator](), _step; !(_iteratorNormalCompletion = (_step = _iterator.next()).done); _iteratorNormalCompletion = true) {var specifier = _step.value;
      // remove the trailing comma
      var token = sourceCode.getTokenAfter(specifier);
      if (token && isComma(token)) {
        fixes.push(fixer.remove(token));
      }
      fixes.push(fixer.remove(specifier));
    }} catch (err) {_didIteratorError = true;_iteratorError = err;} finally {try {if (!_iteratorNormalCompletion && _iterator['return']) {_iterator['return']();}} finally {if (_didIteratorError) {throw _iteratorError;}}}
}

function getImportText(
node,
sourceCode,
specifiers,
kind)
{
  var sourceString = sourceCode.getText(node.source);
  if (specifiers.length === 0) {
    return '';
  }

  var names = specifiers.map(function (s) {
    if (s.imported.name === s.local.name) {
      return s.imported.name;
    }
    return String(s.imported.name) + ' as ' + String(s.local.name);
  });
  // insert a fresh top-level import
  return 'import ' + String(kind) + ' {' + String(names.join(', ')) + '} from ' + String(sourceString) + ';';
}

module.exports = {
  meta: {
    type: 'suggestion',
    docs: {
      category: 'Style guide',
      description: 'Enforce or ban the use of inline type-only markers for named imports.',
      url: (0, _docsUrl2['default'])('consistent-type-specifier-style') },

    fixable: 'code',
    schema: [
    {
      type: 'string',
      'enum': ['prefer-inline', 'prefer-top-level'],
      'default': 'prefer-inline' }] },




  create: function () {function create(context) {
      var sourceCode = context.getSourceCode();

      if (context.options[0] === 'prefer-inline') {
        return {
          ImportDeclaration: function () {function ImportDeclaration(node) {
              if (node.importKind === 'value' || node.importKind == null) {
                // top-level value / unknown is valid
                return;
              }

              if (
              // no specifiers (import type {} from '') have no specifiers to mark as inline
              node.specifiers.length === 0 ||
              node.specifiers.length === 1
              // default imports are both "inline" and "top-level"
              && (
              node.specifiers[0].type === 'ImportDefaultSpecifier'
              // namespace imports are both "inline" and "top-level"
              || node.specifiers[0].type === 'ImportNamespaceSpecifier'))

              {
                return;
              }

              context.report({
                node: node,
                message: 'Prefer using inline {{kind}} specifiers instead of a top-level {{kind}}-only import.',
                data: {
                  kind: node.importKind },

                fix: function () {function fix(fixer) {
                    var kindToken = sourceCode.getFirstToken(node, { skip: 1 });

                    return [].concat(
                    kindToken ? fixer.remove(kindToken) : [],
                    node.specifiers.map(function (specifier) {return fixer.insertTextBefore(specifier, String(node.importKind) + ' ');}));

                  }return fix;}() });

            }return ImportDeclaration;}() };

      }

      // prefer-top-level
      return {
        ImportDeclaration: function () {function ImportDeclaration(node) {
            if (
            // already top-level is valid
            node.importKind === 'type' ||
            node.importKind === 'typeof'
            // no specifiers (import {} from '') cannot have inline - so is valid
            || node.specifiers.length === 0 ||
            node.specifiers.length === 1
            // default imports are both "inline" and "top-level"
            && (
            node.specifiers[0].type === 'ImportDefaultSpecifier'
            // namespace imports are both "inline" and "top-level"
            || node.specifiers[0].type === 'ImportNamespaceSpecifier'))

            {
              return;
            }

            var typeSpecifiers = [];
            var typeofSpecifiers = [];
            var valueSpecifiers = [];
            var defaultSpecifier = null;var _iteratorNormalCompletion2 = true;var _didIteratorError2 = false;var _iteratorError2 = undefined;try {
              for (var _iterator2 = node.specifiers[Symbol.iterator](), _step2; !(_iteratorNormalCompletion2 = (_step2 = _iterator2.next()).done); _iteratorNormalCompletion2 = true) {var specifier = _step2.value;
                if (specifier.type === 'ImportDefaultSpecifier') {
                  defaultSpecifier = specifier;
                  continue;
                }

                if (specifier.importKind === 'type') {
                  typeSpecifiers.push(specifier);
                } else if (specifier.importKind === 'typeof') {
                  typeofSpecifiers.push(specifier);
                } else if (specifier.importKind === 'value' || specifier.importKind == null) {
                  valueSpecifiers.push(specifier);
                }
              }} catch (err) {_didIteratorError2 = true;_iteratorError2 = err;} finally {try {if (!_iteratorNormalCompletion2 && _iterator2['return']) {_iterator2['return']();}} finally {if (_didIteratorError2) {throw _iteratorError2;}}}

            var typeImport = getImportText(node, sourceCode, typeSpecifiers, 'type');
            var typeofImport = getImportText(node, sourceCode, typeofSpecifiers, 'typeof');
            var newImports = (String(typeImport) + '\n' + String(typeofImport)).trim();

            if (typeSpecifiers.length + typeofSpecifiers.length === node.specifiers.length) {
              // all specifiers have inline specifiers - so we replace the entire import
              var kind = [].concat(
              typeSpecifiers.length > 0 ? 'type' : [],
              typeofSpecifiers.length > 0 ? 'typeof' : []);


              context.report({
                node: node,
                message: 'Prefer using a top-level {{kind}}-only import instead of inline {{kind}} specifiers.',
                data: {
                  kind: kind.join('/') },

                fix: function () {function fix(fixer) {
                    return fixer.replaceText(node, newImports);
                  }return fix;}() });

            } else {
              // remove specific specifiers and insert new imports for them
              var _iteratorNormalCompletion3 = true;var _didIteratorError3 = false;var _iteratorError3 = undefined;try {for (var _iterator3 = typeSpecifiers.concat(typeofSpecifiers)[Symbol.iterator](), _step3; !(_iteratorNormalCompletion3 = (_step3 = _iterator3.next()).done); _iteratorNormalCompletion3 = true) {var _specifier = _step3.value;
                  context.report({
                    node: _specifier,
                    message: 'Prefer using a top-level {{kind}}-only import instead of inline {{kind}} specifiers.',
                    data: {
                      kind: _specifier.importKind },

                    fix: function () {function fix(fixer) {
                        var fixes = [];

                        // if there are no value specifiers, then the other report fixer will be called, not this one

                        if (valueSpecifiers.length > 0) {
                          // import { Value, type Type } from 'mod';

                          // we can just remove the type specifiers
                          removeSpecifiers(fixes, fixer, sourceCode, typeSpecifiers);
                          removeSpecifiers(fixes, fixer, sourceCode, typeofSpecifiers);

                          // make the import nicely formatted by also removing the trailing comma after the last value import
                          // eg
                          // import { Value, type Type } from 'mod';
                          // to
                          // import { Value  } from 'mod';
                          // not
                          // import { Value,  } from 'mod';
                          var maybeComma = sourceCode.getTokenAfter(valueSpecifiers[valueSpecifiers.length - 1]);
                          if (isComma(maybeComma)) {
                            fixes.push(fixer.remove(maybeComma));
                          }
                        } else if (defaultSpecifier) {
                          // import Default, { type Type } from 'mod';

                          // remove the entire curly block so we don't leave an empty one behind
                          // NOTE - the default specifier *must* be the first specifier always!
                          //        so a comma exists that we also have to clean up or else it's bad syntax
                          var comma = sourceCode.getTokenAfter(defaultSpecifier, isComma);
                          var closingBrace = sourceCode.getTokenAfter(
                          node.specifiers[node.specifiers.length - 1],
                          function (token) {return token.type === 'Punctuator' && token.value === '}';});

                          fixes.push(fixer.removeRange([
                          comma.range[0],
                          closingBrace.range[1]]));

                        }

                        return fixes.concat(
                        // insert the new imports after the old declaration
                        fixer.insertTextAfter(node, '\n' + String(newImports)));

                      }return fix;}() });

                }} catch (err) {_didIteratorError3 = true;_iteratorError3 = err;} finally {try {if (!_iteratorNormalCompletion3 && _iterator3['return']) {_iterator3['return']();}} finally {if (_didIteratorError3) {throw _iteratorError3;}}}
            }
          }return ImportDeclaration;}() };

    }return create;}() };
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIi4uLy4uL3NyYy9ydWxlcy9jb25zaXN0ZW50LXR5cGUtc3BlY2lmaWVyLXN0eWxlLmpzIl0sIm5hbWVzIjpbImlzQ29tbWEiLCJ0b2tlbiIsInR5cGUiLCJ2YWx1ZSIsInJlbW92ZVNwZWNpZmllcnMiLCJmaXhlcyIsImZpeGVyIiwic291cmNlQ29kZSIsInNwZWNpZmllcnMiLCJzcGVjaWZpZXIiLCJnZXRUb2tlbkFmdGVyIiwicHVzaCIsInJlbW92ZSIsImdldEltcG9ydFRleHQiLCJub2RlIiwia2luZCIsInNvdXJjZVN0cmluZyIsImdldFRleHQiLCJzb3VyY2UiLCJsZW5ndGgiLCJuYW1lcyIsIm1hcCIsInMiLCJpbXBvcnRlZCIsIm5hbWUiLCJsb2NhbCIsImpvaW4iLCJtb2R1bGUiLCJleHBvcnRzIiwibWV0YSIsImRvY3MiLCJjYXRlZ29yeSIsImRlc2NyaXB0aW9uIiwidXJsIiwiZml4YWJsZSIsInNjaGVtYSIsImNyZWF0ZSIsImNvbnRleHQiLCJnZXRTb3VyY2VDb2RlIiwib3B0aW9ucyIsIkltcG9ydERlY2xhcmF0aW9uIiwiaW1wb3J0S2luZCIsInJlcG9ydCIsIm1lc3NhZ2UiLCJkYXRhIiwiZml4Iiwia2luZFRva2VuIiwiZ2V0Rmlyc3RUb2tlbiIsInNraXAiLCJjb25jYXQiLCJpbnNlcnRUZXh0QmVmb3JlIiwidHlwZVNwZWNpZmllcnMiLCJ0eXBlb2ZTcGVjaWZpZXJzIiwidmFsdWVTcGVjaWZpZXJzIiwiZGVmYXVsdFNwZWNpZmllciIsInR5cGVJbXBvcnQiLCJ0eXBlb2ZJbXBvcnQiLCJuZXdJbXBvcnRzIiwidHJpbSIsInJlcGxhY2VUZXh0IiwibWF5YmVDb21tYSIsImNvbW1hIiwiY2xvc2luZ0JyYWNlIiwicmVtb3ZlUmFuZ2UiLCJyYW5nZSIsImluc2VydFRleHRBZnRlciJdLCJtYXBwaW5ncyI6ImFBQUEscUM7O0FBRUEsU0FBU0EsT0FBVCxDQUFpQkMsS0FBakIsRUFBd0I7QUFDdEIsU0FBT0EsTUFBTUMsSUFBTixLQUFl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LENBQXpDLENBRG1CO0FBRW5CLG9DQUFDbEIsS0FBRCxVQUFXQSxNQUFNQyxJQUFOLEtBQWUsWUFBZixJQUErQkQsTUFBTUUsS0FBTixLQUFnQixHQUExRCxFQUZtQixDQUFyQjs7QUFJQUUsZ0NBQU1NLElBQU4sQ0FBV0wsTUFBTXlELFdBQU4sQ0FBa0I7QUFDM0JGLGdDQUFNRyxLQUFOLENBQVksQ0FBWixDQUQyQjtBQUUzQkYsdUNBQWFFLEtBQWIsQ0FBbUIsQ0FBbkIsQ0FGMkIsQ0FBbEIsQ0FBWDs7QUFJRDs7QUFFRCwrQkFBTzNELE1BQU00QyxNQUFOO0FBQ0w7QUFDQTNDLDhCQUFNMkQsZUFBTixDQUFzQm5ELElBQXRCLGdCQUFpQzJDLFVBQWpDLEVBRkssQ0FBUDs7QUFJRCx1QkFsRFksZ0JBQWY7O0FBb0RELGlCQXZESTtBQXdETjtBQUNGLFdBcEhJLDhCQUFQOztBQXNIRCxLQXJMYyxtQkFBakIiLCJmaWxlIjoiY29uc2lzdGVudC10eXBlLXNwZWNpZmllci1zdHlsZS5qcyIsInNvdXJjZXNDb250ZW50IjpbImltcG9ydCBkb2NzVXJsIGZyb20gJy4uL2RvY3NVcmwnO1xuXG5mdW5jdGlvbiBpc0NvbW1hKHRva2VuKSB7XG4gIHJldHVybiB0b2tlbi50eXBlID09PSAnUHVuY3R1YXRvcicgJiYgdG9rZW4udmFsdWUgPT09ICcsJztcbn1cblxuZnVuY3Rpb24gcmVtb3ZlU3BlY2lmaWVycyhmaXhlcywgZml4ZXIsIHNvdXJjZUNvZGUsIHNwZWNpZmllcnMpIHtcbiAgZm9yIChjb25zdCBzcGVjaWZpZXIgb2Ygc3BlY2lmaWVycykge1xuICAgIC8vIHJlbW92ZSB0aGUgdHJhaWxpbmcgY29tbWFcbiAgICBjb25zdCB0b2tlbiA9IHNvdXJjZUNvZGUuZ2V0VG9rZW5BZnRlcihzcGVjaWZpZXIpO1xuICAgIGlmICh0b2tlbiAmJiBpc0NvbW1hKHRva2VuKSkge1xuICAgICAgZml4ZXMucHVzaChmaXhlci5yZW1vdmUodG9rZW4pKTtcbiAgICB9XG4gICAgZml4ZXMucHVzaChmaXhlci5yZW1vdmUoc3BlY2lmaWVyKSk7XG4gIH1cbn1cblxuZnVuY3Rpb24gZ2V0SW1wb3J0VGV4dChcbiAgbm9kZSxcbiAgc291cmNlQ29kZSxcbiAgc3BlY2lmaWVycyxcbiAga2luZCxcbikge1xuICBjb25zdCBzb3VyY2VTdHJpbmcgPSBzb3VyY2VDb2RlLmdldFRleHQobm9kZS5zb3VyY2UpO1xuICBpZiAoc3BlY2lmaWVycy5sZW5ndGggPT09IDApIHtcbiAgICByZXR1cm4gJyc7XG4gIH1cblxuICBjb25zdCBuYW1lcyA9IHNwZWNpZmllcnMubWFwKChzKSA9PiB7XG4gICAgaWYgKHMuaW1wb3J0ZWQubmFtZSA9PT0gcy5sb2NhbC5uYW1lKSB7XG4gICAgICByZXR1cm4gcy5pbXBvcnRlZC5uYW1lO1xuICAgIH1cbiAgICByZXR1cm4gYCR7cy5pbXBvcnRlZC5uYW1lfSBhcyAke3MubG9jYWwubmFtZX1gO1xuICB9KTtcbiAgLy8gaW5zZXJ0IGEgZnJlc2ggdG9wLWxldmVsIGltcG9ydFxuICByZXR1cm4gYGltcG9ydCAke2tpbmR9IHske25hbWVzLmpvaW4oJywgJyl9fSBmcm9tICR7c291cmNlU3RyaW5nfTtgO1xufVxuXG5tb2R1bGUuZXhwb3J0cyA9IHtcbiAgbWV0YToge1xuICAgIHR5cGU6ICdzdWdnZXN0aW9uJyxcbiAgICBkb2NzOiB7XG4gICAgICBjYXRlZ29yeTogJ1N0eWxlIGd1aWRlJyxcbiAgICAgIGRlc2NyaXB0aW9uOiAnRW5mb3JjZSBvciBiYW4gdGhlIHVzZSBvZiBpbmxpbmUgdHlwZS1vbmx5IG1hcmtlcnMgZm9yIG5hbWVkIGltcG9ydHMuJyxcbiAgICAgIHVybDogZG9jc1VybCgnY29uc2lzdGVudC10eXBlLXNwZWNpZmllci1zdHlsZScpLFxuICAgIH0sXG4gICAgZml4YWJsZTogJ2NvZGUnLFxuICAgIHNjaGVtYTogW1xuICAgICAge1xuICAgICAgICB0eXBlOiAnc3RyaW5nJyxcbiAgICAgICAgZW51bTogWydwcmVmZXItaW5saW5lJywgJ3ByZWZlci10b3AtbGV2ZWwnXSxcbiAgICAgICAgZGVmYXVsdDogJ3ByZWZlci1pbmxpbmUnLFxuICAgICAgfSxcbiAgICBdLFxuICB9LFxuXG4gIGNyZWF0ZShjb250ZXh0KSB7XG4gICAgY29uc3Qgc291cmNlQ29kZSA9IGNvbnRleHQuZ2V0U291cmNlQ29kZSgpO1xuXG4gICAgaWYgKGNvbnRleHQub3B0aW9uc1swXSA9PT0gJ3ByZWZlci1pbmxpbmUnKSB7XG4gICAgICByZXR1cm4ge1xuICAgICAgICBJbXBvcnREZWNsYXJhdGlvbihub2RlKSB7XG4gICAgICAgICAgaWYgKG5vZGUuaW1wb3J0S2luZCA9PT0gJ3ZhbHVlJyB8fCBub2RlLmltcG9ydEtpbmQgPT0gbnVsbCkge1xuICAgICAgICAgICAgLy8gdG9wLWxldmVsIHZhbHVlIC8gdW5rbm93biBpcyB2YWxpZFxuICAgICAgICAgICAgcmV0dXJuO1xuICAgICAgICAgIH1cblxuICAgICAgICAgIGlmIChcbiAgICAgICAgICAgIC8vIG5vIHNwZWNpZmllcnMgKGltcG9ydCB0eXBlIHt9IGZyb20gJycpIGhhdmUgbm8gc3BlY2lmaWVycyB0byBtYXJrIGFzIGlubGluZVxuICAgICAgICAgICAgbm9kZS5zcGVjaWZpZXJzLmxlbmd0aCA9PT0gMFxuICAgICAgICAgICAgfHwgbm9kZS5zcGVjaWZpZXJzLmxlbmd0aCA9PT0gMVxuICAgICAgICAgICAgLy8gZGVmYXVsdCBpbXBvcnRzIGFyZSBib3RoIFwiaW5saW5lXCIgYW5kIFwidG9wLWxldmVsXCJcbiAgICAgICAgICAgICYmIChcbiAgICAgICAgICAgICAgbm9kZS5zcGVjaWZpZXJzWzBdLnR5cGUgPT09ICdJbXBvcnREZWZhdWx0U3BlY2lmaWVyJ1xuICAgICAgICAgICAgICAvLyBuYW1lc3BhY2UgaW1wb3J0cyBhcmUgYm90aCBcImlubGluZVwiIGFuZCBcInRvcC1sZXZlbFwiXG4gICAgICAgICAgICAgIHx8IG5vZGUuc3BlY2lmaWVyc1swXS50eXBlID09PSAnSW1wb3J0TmFtZXNwYWNlU3BlY2lmaWVyJ1xuICAgICAgICAgICAgKVxuICAgICAgICAgICkge1xuICAgICAgICAgICAgcmV0dXJuO1xuICAgICAgICAgIH1cblxuICAgICAgICAgIGNvbnRleHQucmVwb3J0KHtcbiAgICAgICAgICAgIG5vZGUsXG4gICAgICAgICAgICBtZXNzYWdlOiAnUHJlZmVyIHVzaW5nIGlubGluZSB7e2tpbmR9fSBzcGVjaWZpZXJzIGluc3RlYWQgb2YgYSB0b3AtbGV2ZWwge3traW5kfX0tb25seSBpbXBvcnQuJyxcbiAgICAgICAgICAgIGRhdGE6IHtcbiAgICAgICAgICAgICAga2luZDogbm9kZS5pbXBvcnRLaW5kLFxuICAgICAgICAgICAgfSxcbiAgICAgICAgICAgIGZpeChmaXhlcikge1xuICAgICAgICAgICAgICBjb25zdCBraW5kVG9rZW4gPSBzb3VyY2VDb2RlLmdldEZpcnN0VG9rZW4obm9kZSwgeyBza2lwOiAxIH0pO1xuXG4gICAgICAgICAgICAgIHJldHVybiBbXS5jb25jYXQoXG4gICAgICAgICAgICAgICAga2luZFRva2VuID8gZml4ZXIucmVtb3ZlKGtpbmRUb2tlbikgOiBbXSxcbiAgICAgICAgICAgICAgICBub2RlLnNwZWNpZmllcnMubWFwKChzcGVjaWZpZXIpID0+IGZpeGVyLmluc2VydFRleHRCZWZvcmUoc3BlY2lmaWVyLCBgJHtub2RlLmltcG9ydEtpbmR9IGApKSxcbiAgICAgICAgICAgICAgKTtcbiAgICAgICAgICAgIH0sXG4gICAgICAgICAgfSk7XG4gICAgICAgIH0sXG4gICAgICB9O1xuICAgIH1cblxuICAgIC8vIHByZWZlci10b3AtbGV2ZWxcbiAgICByZXR1cm4ge1xuICAgICAgSW1wb3J0RGVjbGFyYXRpb24obm9kZSkge1xuICAgICAgICBpZiAoXG4gICAgICAgICAgLy8gYWxyZWFkeSB0b3AtbGV2ZWwgaXMgdmFsaWRcbiAgICAgICAgICBub2RlLmltcG9ydEtpbmQgPT09ICd0eXBlJ1xuICAgICAgICAgIHx8IG5vZGUuaW1wb3J0S2luZCA9PT0gJ3R5cGVvZidcbiAgICAgICAgICAvLyBubyBzcGVjaWZpZXJzIChpbXBvcnQge30gZnJvbSAnJykgY2Fubm90IGhhdmUgaW5saW5lIC0gc28gaXMgdmFsaWRcbiAgICAgICAgICB8fCBub2RlLnNwZWNpZmllcnMubGVuZ3RoID09PSAwXG4gICAgICAgICAgfHwgbm9kZS5zcGVjaWZpZXJzLmxlbmd0aCA9PT0gMVxuICAgICAgICAgIC8vIGRlZmF1bHQgaW1wb3J0cyBhcmUgYm90aCBcImlubGluZVwiIGFuZCBcInRvcC1sZXZlbFwiXG4gICAgICAgICAgJiYgKFxuICAgICAgICAgICAgbm9kZS5zcGVjaWZpZXJzWzBdLnR5cGUgPT09ICdJbXBvcnREZWZhdWx0U3BlY2lmaWVyJ1xuICAgICAgICAgICAgLy8gbmFtZXNwYWNlIGltcG9ydHMgYXJlIGJvdGggXCJpbmxpbmVcIiBhbmQgXCJ0b3AtbGV2ZWxcIlxuICAgICAgICAgICAgfHwgbm9kZS5zcGVjaWZpZXJzWzBdLnR5cGUgPT09ICdJbXBvcnROYW1lc3BhY2VTcGVjaWZpZXInXG4gICAgICAgICAgKVxuICAgICAgICApIHtcbiAgICAgICAgICByZXR1cm47XG4gICAgICAgIH1cblxuICAgICAgICBjb25zdCB0eXBlU3BlY2lmaWVycyA9IFtdO1xuICAgICAgICBjb25zdCB0eXBlb2ZTcGVjaWZpZXJzID0gW107XG4gICAgICAgIGNvbnN0IHZhbHVlU3BlY2lmaWVycyA9IFtdO1xuICAgICAgICBsZXQgZGVmYXVsdFNwZWNpZmllciA9IG51bGw7XG4gICAgICAgIGZvciAoY29uc3Qgc3BlY2lmaWVyIG9mIG5vZGUuc3BlY2lmaWVycykge1xuICAgICAgICAgIGlmIChzcGVjaWZpZXIudHlwZSA9PT0gJ0ltcG9ydERlZmF1bHRTcGVjaWZpZXInKSB7XG4gICAgICAgICAgICBkZWZhdWx0U3BlY2lmaWVyID0gc3BlY2lmaWVyO1xuICAgICAgICAgICAgY29udGludWU7XG4gICAgICAgICAgfVxuXG4gICAgICAgICAgaWYgKHNwZWNpZmllci5pbXBvcnRLaW5kID09PSAndHlwZScpIHtcbiAgICAgICAgICAgIHR5cGVTcGVjaWZpZXJzLnB1c2goc3BlY2lmaWVyKTtcbiAgICAgICAgICB9IGVsc2UgaWYgKHNwZWNpZmllci5pbXBvcnRLaW5kID09PSAndHlwZW9mJykge1xuICAgICAgICAgICAgdHlwZW9mU3BlY2lmaWVycy5wdXNoKHNwZWNpZmllcik7XG4gICAgICAgICAgfSBlbHNlIGlmIChzcGVjaWZpZXIuaW1wb3J0S2luZCA9PT0gJ3ZhbHVlJyB8fCBzcGVjaWZpZXIuaW1wb3J0S2luZCA9PSBudWxsKSB7XG4gICAgICAgICAgICB2YWx1ZVNwZWNpZmllcnMucHVzaChzcGVjaWZpZXIpO1xuICAgICAgICAgIH1cbiAgICAgICAgfVxuXG4gICAgICAgIGNvbnN0IHR5cGVJbXBvcnQgPSBnZXRJbXBvcnRUZXh0KG5vZGUsIHNvdXJjZUNvZGUsIHR5cGVTcGVjaWZpZXJzLCAndHlwZScpO1xuICAgICAgICBjb25zdCB0eXBlb2ZJbXBvcnQgPSBnZXRJbXBvcnRUZXh0KG5vZGUsIHNvdXJjZUNvZGUsIHR5cGVvZlNwZWNpZmllcnMsICd0eXBlb2YnKTtcbiAgICAgICAgY29uc3QgbmV3SW1wb3J0cyA9IGAke3R5cGVJbXBvcnR9XFxuJHt0eXBlb2ZJbXBvcnR9YC50cmltKCk7XG5cbiAgICAgICAgaWYgKHR5cGVTcGVjaWZpZXJzLmxlbmd0aCArIHR5cGVvZlNwZWNpZmllcnMubGVuZ3RoID09PSBub2RlLnNwZWNpZmllcnMubGVuZ3RoKSB7XG4gICAgICAgICAgLy8gYWxsIHNwZWNpZmllcnMgaGF2ZSBpbmxpbmUgc3BlY2lmaWVycyAtIHNvIHdlIHJlcGxhY2UgdGhlIGVudGlyZSBpbXBvcnRcbiAgICAgICAgICBjb25zdCBraW5kID0gW10uY29uY2F0KFxuICAgICAgICAgICAgdHlwZVNwZWNpZmllcnMubGVuZ3RoID4gMCA/ICd0eXBlJyA6IFtdLFxuICAgICAgICAgICAgdHlwZW9mU3BlY2lmaWVycy5sZW5ndGggPiAwID8gJ3R5cGVvZicgOiBbXSxcbiAgICAgICAgICApO1xuXG4gICAgICAgICAgY29udGV4dC5yZXBvcnQoe1xuICAgICAgICAgICAgbm9kZSxcbiAgICAgICAgICAgIG1lc3NhZ2U6ICdQcmVmZXIgdXNpbmcgYSB0b3AtbGV2ZWwge3traW5kfX0tb25seSBpbXBvcnQgaW5zdGVhZCBvZiBpbmxpbmUge3traW5kfX0gc3BlY2lmaWVycy4nLFxuICAgICAgICAgICAgZGF0YToge1xuICAgICAgICAgICAgICBraW5kOiBraW5kLmpvaW4oJy8nKSxcbiAgICAgICAgICAgIH0sXG4gICAgICAgICAgICBmaXgoZml4ZXIpIHtcbiAgICAgICAgICAgICAgcmV0dXJuIGZpeGVyLnJlcGxhY2VUZXh0KG5vZGUsIG5ld0ltcG9ydHMpO1xuICAgICAgICAgICAgfSxcbiAgICAgICAgICB9KTtcbiAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICAvLyByZW1vdmUgc3BlY2lmaWMgc3BlY2lmaWVycyBhbmQgaW5zZXJ0IG5ldyBpbXBvcnRzIGZvciB0aGVtXG4gICAgICAgICAgZm9yIChjb25zdCBzcGVjaWZpZXIgb2YgdHlwZVNwZWNpZmllcnMuY29uY2F0KHR5cGVvZlNwZWNpZmllcnMpKSB7XG4gICAgICAgICAgICBjb250ZXh0LnJlcG9ydCh7XG4gICAgICAgICAgICAgIG5vZGU6IHNwZWNpZmllcixcbiAgICAgICAgICAgICAgbWVzc2FnZTogJ1ByZWZlciB1c2luZyBhIHRvcC1sZXZlbCB7e2tpbmR9fS1vbmx5IGltcG9ydCBpbnN0ZWFkIG9mIGlubGluZSB7e2tpbmR9fSBzcGVjaWZpZXJzLicsXG4gICAgICAgICAgICAgIGRhdGE6IHtcbiAgICAgICAgICAgICAgICBraW5kOiBzcGVjaWZpZXIuaW1wb3J0S2luZCxcbiAgICAgICAgICAgICAgfSxcbiAgICAgICAgICAgICAgZml4KGZpeGVyKSB7XG4gICAgICAgICAgICAgICAgY29uc3QgZml4ZXMgPSBbXTtcblxuICAgICAgICAgICAgICAgIC8vIGlmIHRoZXJlIGFyZSBubyB2YWx1ZSBzcGVjaWZpZXJzLCB0aGVuIHRoZSBvdGhlciByZXBvcnQgZml4ZXIgd2lsbCBiZSBjYWxsZWQsIG5vdCB0aGlzIG9uZVxuXG4gICAgICAgICAgICAgICAgaWYgKHZhbHVlU3BlY2lmaWVycy5sZW5ndGggPiAwKSB7XG4gICAgICAgICAgICAgICAgICAvLyBpbXBvcnQgeyBWYWx1ZSwgdHlwZSBUeXBlIH0gZnJvbSAnbW9kJztcblxuICAgICAgICAgICAgICAgICAgLy8gd2UgY2FuIGp1c3QgcmVtb3ZlIHRoZSB0eXBlIHNwZWNpZmllcnNcbiAgICAgICAgICAgICAgICAgIHJlbW92ZVNwZWNpZmllcnMoZml4ZXMsIGZpeGVyLCBzb3VyY2VDb2RlLCB0eXBlU3BlY2lmaWVycyk7XG4gICAgICAgICAgICAgICAgICByZW1vdmVTcGVjaWZpZXJzKGZpeGVzLCBmaXhlciwgc291cmNlQ29kZSwgdHlwZW9mU3BlY2lmaWVycyk7XG5cbiAgICAgICAgICAgICAgICAgIC8vIG1ha2UgdGhlIGltcG9ydCBuaWNlbHkgZm9ybWF0dGVkIGJ5IGFsc28gcmVtb3ZpbmcgdGhlIHRyYWlsaW5nIGNvbW1hIGFmdGVyIHRoZSBsYXN0IHZhbHVlIGltcG9ydFxuICAgICAgICAgICAgICAgICAgLy8gZWdcbiAgICAgICAgICAgICAgICAgIC8vIGltcG9ydCB7IFZhbHVlLCB0eXBlIFR5cGUgfSBmcm9tICdtb2QnO1xuICAgICAgICAgICAgICAgICAgLy8gdG9cbiAgICAgICAgICAgICAgICAgIC8vIGltcG9ydCB7IFZhbHVlICB9IGZyb20gJ21vZCc7XG4gICAgICAgICAgICAgICAgICAvLyBub3RcbiAgICAgICAgICAgICAgICAgIC8vIGltcG9ydCB7IFZhbHVlLCAgfSBmcm9tICdtb2QnO1xuICAgICAgICAgICAgICAgICAgY29uc3QgbWF5YmVDb21tYSA9IHNvdXJjZUNvZGUuZ2V0VG9rZW5BZnRlcih2YWx1ZVNwZWNpZmllcnNbdmFsdWVTcGVjaWZpZXJzLmxlbmd0aCAtIDFdKTtcbiAgICAgICAgICAgICAgICAgIGlmIChpc0NvbW1hKG1heWJlQ29tbWEpKSB7XG4gICAgICAgICAgICAgICAgICAgIGZpeGVzLnB1c2goZml4ZXIucmVtb3ZlKG1heWJlQ29tbWEpKTtcbiAgICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgICAgICB9IGVsc2UgaWYgKGRlZmF1bHRTcGVjaWZpZXIpIHtcbiAgICAgICAgICAgICAgICAgIC8vIGltcG9ydCBEZWZhdWx0LCB7IHR5cGUgVHlwZSB9IGZyb20gJ21vZCc7XG5cbiAgICAgICAgICAgICAgICAgIC8vIHJlbW92ZSB0aGUgZW50aXJlIGN1cmx5IGJsb2NrIHNvIHdlIGRvbid0IGxlYXZlIGFuIGVtcHR5IG9uZSBiZWhpbmRcbiAgICAgICAgICAgICAgICAgIC8vIE5PVEUgLSB0aGUgZGVmYXVsdCBzcGVjaWZpZXIgKm11c3QqIGJlIHRoZSBmaXJzdCBzcGVjaWZpZXIgYWx3YXlzIVxuICAgICAgICAgICAgICAgICAgLy8gICAgICAgIHNvIGEgY29tbWEgZXhpc3RzIHRoYXQgd2UgYWxzbyBoYXZlIHRvIGNsZWFuIHVwIG9yIGVsc2UgaXQncyBiYWQgc3ludGF4XG4gICAgICAgICAgICAgICAgICBjb25zdCBjb21tYSA9IHNvdXJjZUNvZGUuZ2V0VG9rZW5BZnRlcihkZWZhdWx0U3BlY2lmaWVyLCBpc0NvbW1hKTtcbiAgICAgICAgICAgICAgICAgIGNvbnN0IGNsb3NpbmdCcmFjZSA9IHNvdXJjZUNvZGUuZ2V0VG9rZW5BZnRlcihcbiAgICAgICAgICAgICAgICAgICAgbm9kZS5zcGVjaWZpZXJzW25vZGUuc3BlY2lmaWVycy5sZW5ndGggLSAxXSxcbiAgICAgICAgICAgICAgICAgICAgKHRva2VuKSA9PiB0b2tlbi50eXBlID09PSAnUHVuY3R1YXRvcicgJiYgdG9rZW4udmFsdWUgPT09ICd9JyxcbiAgICAgICAgICAgICAgICAgICk7XG4gICAgICAgICAgICAgICAgICBmaXhlcy5wdXNoKGZpeGVyLnJlbW92ZVJhbmdlKFtcbiAgICAgICAgICAgICAgICAgICAgY29tbWEucmFuZ2VbMF0sXG4gICAgICAgICAgICAgICAgICAgIGNsb3NpbmdCcmFjZS5yYW5nZVsxXSxcbiAgICAgICAgICAgICAgICAgIF0pKTtcbiAgICAgICAgICAgICAgICB9XG5cbiAgICAgICAgICAgICAgICByZXR1cm4gZml4ZXMuY29uY2F0KFxuICAgICAgICAgICAgICAgICAgLy8gaW5zZXJ0IHRoZSBuZXcgaW1wb3J0cyBhZnRlciB0aGUgb2xkIGRlY2xhcmF0aW9uXG4gICAgICAgICAgICAgICAgICBmaXhlci5pbnNlcnRUZXh0QWZ0ZXIobm9kZSwgYFxcbiR7bmV3SW1wb3J0c31gKSxcbiAgICAgICAgICAgICAgICApO1xuICAgICAgICAgICAgICB9LFxuICAgICAgICAgICAgfSk7XG4gICAgICAgICAgfVxuICAgICAgICB9XG4gICAgICB9LFxuICAgIH07XG4gIH0sXG59O1xuIl19