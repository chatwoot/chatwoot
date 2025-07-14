'use strict';var _docsUrl = require('../docsUrl');var _docsUrl2 = _interopRequireDefault(_docsUrl);function _interopRequireDefault(obj) {return obj && obj.__esModule ? obj : { 'default': obj };}

function getImportValue(node) {
  return node.type === 'ImportDeclaration' ?
  node.source.value :
  node.moduleReference.expression.value;
}

module.exports = {
  meta: {
    type: 'suggestion',
    docs: {
      category: 'Style guide',
      description: 'Ensure all imports appear before other statements.',
      url: (0, _docsUrl2['default'])('first') },

    fixable: 'code',
    schema: [
    {
      type: 'string',
      'enum': ['absolute-first', 'disable-absolute-first'] }] },




  create: function () {function create(context) {
      function isPossibleDirective(node) {
        return node.type === 'ExpressionStatement' &&
        node.expression.type === 'Literal' &&
        typeof node.expression.value === 'string';
      }

      return {
        Program: function () {function Program(n) {
            var body = n.body;
            if (!body) {
              return;
            }
            var absoluteFirst = context.options[0] === 'absolute-first';
            var message = 'Import in body of module; reorder to top.';
            var sourceCode = context.getSourceCode();
            var originSourceCode = sourceCode.getText();
            var nonImportCount = 0;
            var anyExpressions = false;
            var anyRelative = false;
            var lastLegalImp = null;
            var errorInfos = [];
            var shouldSort = true;
            var lastSortNodesIndex = 0;
            body.forEach(function (node, index) {
              if (!anyExpressions && isPossibleDirective(node)) {
                return;
              }

              anyExpressions = true;

              if (node.type === 'ImportDeclaration' || node.type === 'TSImportEqualsDeclaration') {
                if (absoluteFirst) {
                  if (/^\./.test(getImportValue(node))) {
                    anyRelative = true;
                  } else if (anyRelative) {
                    context.report({
                      node: node.type === 'ImportDeclaration' ? node.source : node.moduleReference,
                      message: 'Absolute imports should come before relative imports.' });

                  }
                }
                if (nonImportCount > 0) {var _iteratorNormalCompletion = true;var _didIteratorError = false;var _iteratorError = undefined;try {
                    for (var _iterator = context.getDeclaredVariables(node)[Symbol.iterator](), _step; !(_iteratorNormalCompletion = (_step = _iterator.next()).done); _iteratorNormalCompletion = true) {var variable = _step.value;
                      if (!shouldSort) {break;}
                      var references = variable.references;
                      if (references.length) {var _iteratorNormalCompletion2 = true;var _didIteratorError2 = false;var _iteratorError2 = undefined;try {
                          for (var _iterator2 = references[Symbol.iterator](), _step2; !(_iteratorNormalCompletion2 = (_step2 = _iterator2.next()).done); _iteratorNormalCompletion2 = true) {var reference = _step2.value;
                            if (reference.identifier.range[0] < node.range[1]) {
                              shouldSort = false;
                              break;
                            }
                          }} catch (err) {_didIteratorError2 = true;_iteratorError2 = err;} finally {try {if (!_iteratorNormalCompletion2 && _iterator2['return']) {_iterator2['return']();}} finally {if (_didIteratorError2) {throw _iteratorError2;}}}
                      }
                    }} catch (err) {_didIteratorError = true;_iteratorError = err;} finally {try {if (!_iteratorNormalCompletion && _iterator['return']) {_iterator['return']();}} finally {if (_didIteratorError) {throw _iteratorError;}}}
                  shouldSort && (lastSortNodesIndex = errorInfos.length);
                  errorInfos.push({
                    node: node,
                    range: [body[index - 1].range[1], node.range[1]] });

                } else {
                  lastLegalImp = node;
                }
              } else {
                nonImportCount++;
              }
            });
            if (!errorInfos.length) {return;}
            errorInfos.forEach(function (errorInfo, index) {
              var node = errorInfo.node;
              var infos = {
                node: node,
                message: message };

              if (index < lastSortNodesIndex) {
                infos.fix = function (fixer) {
                  return fixer.insertTextAfter(node, '');
                };
              } else if (index === lastSortNodesIndex) {
                var sortNodes = errorInfos.slice(0, lastSortNodesIndex + 1);
                infos.fix = function (fixer) {
                  var removeFixers = sortNodes.map(function (_errorInfo) {
                    return fixer.removeRange(_errorInfo.range);
                  });
                  var range = [0, removeFixers[removeFixers.length - 1].range[1]];
                  var insertSourceCode = sortNodes.map(function (_errorInfo) {
                    var nodeSourceCode = String.prototype.slice.apply(
                    originSourceCode, _errorInfo.range);

                    if (/\S/.test(nodeSourceCode[0])) {
                      return '\n' + String(nodeSourceCode);
                    }
                    return nodeSourceCode;
                  }).join('');
                  var insertFixer = null;
                  var replaceSourceCode = '';
                  if (!lastLegalImp) {
                    insertSourceCode = insertSourceCode.trim() + insertSourceCode.match(/^(\s+)/)[0];
                  }
                  insertFixer = lastLegalImp ?
                  fixer.insertTextAfter(lastLegalImp, insertSourceCode) :
                  fixer.insertTextBefore(body[0], insertSourceCode);

                  var fixers = [insertFixer].concat(removeFixers);
                  fixers.forEach(function (computedFixer, i) {
                    replaceSourceCode += originSourceCode.slice(
                    fixers[i - 1] ? fixers[i - 1].range[1] : 0, computedFixer.range[0]) +
                    computedFixer.text;
                  });

                  return fixer.replaceTextRange(range, replaceSourceCode);
                };
              }
              context.report(infos);
            });
          }return Program;}() };

    }return create;}() };
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIi4uLy4uL3NyYy9ydWxlcy9maXJzdC5qcyJdLCJuYW1lcyI6WyJnZXRJbXBvcnRWYWx1ZSIsIm5vZGUiLCJ0eXBlIiwic291cmNlIiwidmFsdWUiLCJtb2R1bGVSZWZlcmVuY2UiLCJleHByZXNzaW9uIiwibW9kdWxlIiwiZXhwb3J0cyIsIm1ldGEiLCJkb2NzIiwiY2F0ZWdvcnkiLCJkZXNjcmlwdGlvbiIsInVybCIsImZpeGFibGUiLCJzY2hlbWEiLCJjcmVhdGUiLCJjb250ZXh0IiwiaXNQb3NzaWJsZURpcmVjdGl2ZSIsIlByb2dyYW0iLCJuIiwiYm9keSIsImFic29sdXRlRmlyc3QiLCJvcHRpb25zIiwibWVzc2FnZSIsInNvdXJjZUNvZGUiLCJnZXRTb3VyY2VDb2RlIiwib3JpZ2luU291cmNlQ29kZSIsImdldFRleHQiLCJub25JbXBvcnRDb3VudCIsImFueUV4cHJlc3Npb25zIiwiYW55UmVsYXRpdmUiLCJsYXN0TGVnYWxJbXAiLCJlcnJvckluZm9zIiwic2hvdWxkU29ydCIsImxhc3RTb3J0Tm9kZXNJbmRleCIsImZvckVhY2giLCJpbmRleCIsInRlc3QiLCJyZXBvcnQiLCJnZXREZWNsYXJlZFZhcmlhYmxlcyIsInZhcmlhYmxlIiwicmVmZXJlbmNlcyIsImxlbmd0aCIsInJlZmVyZW5jZSIsImlkZW50aWZpZXIiLCJyYW5nZSIsInB1c2giLCJlcnJvckluZm8iLCJpbmZvcyIsImZpeCIsImZpeGVyIiwiaW5zZXJ0VGV4dEFmdGVyIiwic29ydE5vZGVzIiwic2xpY2UiLCJyZW1vdmVGaXhlcnMiLCJtYXAiLCJfZXJyb3JJbmZvIiwicmVtb3ZlUmFuZ2UiLCJpbnNlcnRTb3VyY2VDb2RlIiwibm9kZVNvdXJjZUNvZGUiLCJTdHJpbmciLCJwcm90b3R5cGUiLCJhcHBseSIsImpvaW4iLCJpbnNlcnRGaXhlciIsInJlcGxhY2VTb3VyY2VDb2RlIiwidHJpbSIsIm1hdGNoIiwiaW5zZXJ0VGV4dEJlZm9yZSIsImZpeGVycyIsImNvbmNhdCIsImNv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QjtBQUNuQ1AseUNBQXFCdkMsaUJBQWlCMkIsS0FBakI7QUFDbkJnQiwyQkFBT0csSUFBSSxDQUFYLElBQWdCSCxPQUFPRyxJQUFJLENBQVgsRUFBYzNCLEtBQWQsQ0FBb0IsQ0FBcEIsQ0FBaEIsR0FBeUMsQ0FEdEIsRUFDeUIwQixjQUFjMUIsS0FBZCxDQUFvQixDQUFwQixDQUR6QjtBQUVqQjBCLGtDQUFjRSxJQUZsQjtBQUdELG1CQUpEOztBQU1BLHlCQUFPdkIsTUFBTXdCLGdCQUFOLENBQXVCN0IsS0FBdkIsRUFBOEJvQixpQkFBOUIsQ0FBUDtBQUNELGlCQS9CRDtBQWdDRDtBQUNEakQsc0JBQVFzQixNQUFSLENBQWVVLEtBQWY7QUFDRCxhQTlDRDtBQStDRCxXQTVHSSxvQkFBUDs7QUE4R0QsS0F0SWMsbUJBQWpCIiwiZmlsZSI6ImZpcnN0LmpzIiwic291cmNlc0NvbnRlbnQiOlsiaW1wb3J0IGRvY3NVcmwgZnJvbSAnLi4vZG9jc1VybCc7XG5cbmZ1bmN0aW9uIGdldEltcG9ydFZhbHVlKG5vZGUpIHtcbiAgcmV0dXJuIG5vZGUudHlwZSA9PT0gJ0ltcG9ydERlY2xhcmF0aW9uJ1xuICAgID8gbm9kZS5zb3VyY2UudmFsdWVcbiAgICA6IG5vZGUubW9kdWxlUmVmZXJlbmNlLmV4cHJlc3Npb24udmFsdWU7XG59XG5cbm1vZHVsZS5leHBvcnRzID0ge1xuICBtZXRhOiB7XG4gICAgdHlwZTogJ3N1Z2dlc3Rpb24nLFxuICAgIGRvY3M6IHtcbiAgICAgIGNhdGVnb3J5OiAnU3R5bGUgZ3VpZGUnLFxuICAgICAgZGVzY3JpcHRpb246ICdFbnN1cmUgYWxsIGltcG9ydHMgYXBwZWFyIGJlZm9yZSBvdGhlciBzdGF0ZW1lbnRzLicsXG4gICAgICB1cmw6IGRvY3NVcmwoJ2ZpcnN0JyksXG4gICAgfSxcbiAgICBmaXhhYmxlOiAnY29kZScsXG4gICAgc2NoZW1hOiBbXG4gICAgICB7XG4gICAgICAgIHR5cGU6ICdzdHJpbmcnLFxuICAgICAgICBlbnVtOiBbJ2Fic29sdXRlLWZpcnN0JywgJ2Rpc2FibGUtYWJzb2x1dGUtZmlyc3QnXSxcbiAgICAgIH0sXG4gICAgXSxcbiAgfSxcblxuICBjcmVhdGUoY29udGV4dCkge1xuICAgIGZ1bmN0aW9uIGlzUG9zc2libGVEaXJlY3RpdmUobm9kZSkge1xuICAgICAgcmV0dXJuIG5vZGUudHlwZSA9PT0gJ0V4cHJlc3Npb25TdGF0ZW1lbnQnXG4gICAgICAgICYmIG5vZGUuZXhwcmVzc2lvbi50eXBlID09PSAnTGl0ZXJhbCdcbiAgICAgICAgJiYgdHlwZW9mIG5vZGUuZXhwcmVzc2lvbi52YWx1ZSA9PT0gJ3N0cmluZyc7XG4gICAgfVxuXG4gICAgcmV0dXJuIHtcbiAgICAgIFByb2dyYW0obikge1xuICAgICAgICBjb25zdCBib2R5ID0gbi5ib2R5O1xuICAgICAgICBpZiAoIWJvZHkpIHtcbiAgICAgICAgICByZXR1cm47XG4gICAgICAgIH1cbiAgICAgICAgY29uc3QgYWJzb2x1dGVGaXJzdCA9IGNvbnRleHQub3B0aW9uc1swXSA9PT0gJ2Fic29sdXRlLWZpcnN0JztcbiAgICAgICAgY29uc3QgbWVzc2FnZSA9ICdJbXBvcnQgaW4gYm9keSBvZiBtb2R1bGU7IHJlb3JkZXIgdG8gdG9wLic7XG4gICAgICAgIGNvbnN0IHNvdXJjZUNvZGUgPSBjb250ZXh0LmdldFNvdXJjZUNvZGUoKTtcbiAgICAgICAgY29uc3Qgb3JpZ2luU291cmNlQ29kZSA9IHNvdXJjZUNvZGUuZ2V0VGV4dCgpO1xuICAgICAgICBsZXQgbm9uSW1wb3J0Q291bnQgPSAwO1xuICAgICAgICBsZXQgYW55RXhwcmVzc2lvbnMgPSBmYWxzZTtcbiAgICAgICAgbGV0IGFueVJlbGF0aXZlID0gZmFsc2U7XG4gICAgICAgIGxldCBsYXN0TGVnYWxJbXAgPSBudWxsO1xuICAgICAgICBjb25zdCBlcnJvckluZm9zID0gW107XG4gICAgICAgIGxldCBzaG91bGRTb3J0ID0gdHJ1ZTtcbiAgICAgICAgbGV0IGxhc3RTb3J0Tm9kZXNJbmRleCA9IDA7XG4gICAgICAgIGJvZHkuZm9yRWFjaChmdW5jdGlvbiAobm9kZSwgaW5kZXgpIHtcbiAgICAgICAgICBpZiAoIWFueUV4cHJlc3Npb25zICYmIGlzUG9zc2libGVEaXJlY3RpdmUobm9kZSkpIHtcbiAgICAgICAgICAgIHJldHVybjtcbiAgICAgICAgICB9XG5cbiAgICAgICAgICBhbnlFeHByZXNzaW9ucyA9IHRydWU7XG5cbiAgICAgICAgICBpZiAobm9kZS50eXBlID09PSAnSW1wb3J0RGVjbGFyYXRpb24nIHx8IG5vZGUudHlwZSA9PT0gJ1RTSW1wb3J0RXF1YWxzRGVjbGFyYXRpb24nKSB7XG4gICAgICAgICAgICBpZiAoYWJzb2x1dGVGaXJzdCkge1xuICAgICAgICAgICAgICBpZiAoKC9eXFwuLykudGVzdChnZXRJbXBvcnRWYWx1ZShub2RlKSkpIHtcbiAgICAgICAgICAgICAgICBhbnlSZWxhdGl2ZSA9IHRydWU7XG4gICAgICAgICAgICAgIH0gZWxzZSBpZiAoYW55UmVsYXRpdmUpIHtcbiAgICAgICAgICAgICAgICBjb250ZXh0LnJlcG9ydCh7XG4gICAgICAgICAgICAgICAgICBub2RlOiBub2RlLnR5cGUgPT09ICdJbXBvcnREZWNsYXJhdGlvbicgPyBub2RlLnNvdXJjZSA6IG5vZGUubW9kdWxlUmVmZXJlbmNlLFxuICAgICAgICAgICAgICAgICAgbWVzc2FnZTogJ0Fic29sdXRlIGltcG9ydHMgc2hvdWxkIGNvbWUgYmVmb3JlIHJlbGF0aXZlIGltcG9ydHMuJyxcbiAgICAgICAgICAgICAgICB9KTtcbiAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgfVxuICAgICAgICAgICAgaWYgKG5vbkltcG9ydENvdW50ID4gMCkge1xuICAgICAgICAgICAgICBmb3IgKGNvbnN0IHZhcmlhYmxlIG9mIGNvbnRleHQuZ2V0RGVjbGFyZWRWYXJpYWJsZXMobm9kZSkpIHtcbiAgICAgICAgICAgICAgICBpZiAoIXNob3VsZFNvcnQpIHsgYnJlYWs7IH1cbiAgICAgICAgICAgICAgICBjb25zdCByZWZlcmVuY2VzID0gdmFyaWFibGUucmVmZXJlbmNlcztcbiAgICAgICAgICAgICAgICBpZiAocmVmZXJlbmNlcy5sZW5ndGgpIHtcbiAgICAgICAgICAgICAgICAgIGZvciAoY29uc3QgcmVmZXJlbmNlIG9mIHJlZmVyZW5jZXMpIHtcbiAgICAgICAgICAgICAgICAgICAgaWYgKHJlZmVyZW5jZS5pZGVudGlmaWVyLnJhbmdlWzBdIDwgbm9kZS5yYW5nZVsxXSkge1xuICAgICAgICAgICAgICAgICAgICAgIHNob3VsZFNvcnQgPSBmYWxzZTtcbiAgICAgICAgICAgICAgICAgICAgICBicmVhaztcbiAgICAgICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgICBzaG91bGRTb3J0ICYmIChsYXN0U29ydE5vZGVzSW5kZXggPSBlcnJvckluZm9zLmxlbmd0aCk7XG4gICAgICAgICAgICAgIGVycm9ySW5mb3MucHVzaCh7XG4gICAgICAgICAgICAgICAgbm9kZSxcbiAgICAgICAgICAgICAgICByYW5nZTogW2JvZHlbaW5kZXggLSAxXS5yYW5nZVsxXSwgbm9kZS5yYW5nZVsxXV0sXG4gICAgICAgICAgICAgIH0pO1xuICAgICAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICAgICAgbGFzdExlZ2FsSW1wID0gbm9kZTtcbiAgICAgICAgICAgIH1cbiAgICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgICAgbm9uSW1wb3J0Q291bnQrKztcbiAgICAgICAgICB9XG4gICAgICAgIH0pO1xuICAgICAgICBpZiAoIWVycm9ySW5mb3MubGVuZ3RoKSB7IHJldHVybjsgfVxuICAgICAgICBlcnJvckluZm9zLmZvckVhY2goZnVuY3Rpb24gKGVycm9ySW5mbywgaW5kZXgpIHtcbiAgICAgICAgICBjb25zdCBub2RlID0gZXJyb3JJbmZvLm5vZGU7XG4gICAgICAgICAgY29uc3QgaW5mb3MgPSB7XG4gICAgICAgICAgICBub2RlLFxuICAgICAgICAgICAgbWVzc2FnZSxcbiAgICAgICAgICB9O1xuICAgICAgICAgIGlmIChpbmRleCA8IGxhc3RTb3J0Tm9kZXNJbmRleCkge1xuICAgICAgICAgICAgaW5mb3MuZml4ID0gZnVuY3Rpb24gKGZpeGVyKSB7XG4gICAgICAgICAgICAgIHJldHVybiBmaXhlci5pbnNlcnRUZXh0QWZ0ZXIobm9kZSwgJycpO1xuICAgICAgICAgICAgfTtcbiAgICAgICAgICB9IGVsc2UgaWYgKGluZGV4ID09PSBsYXN0U29ydE5vZGVzSW5kZXgpIHtcbiAgICAgICAgICAgIGNvbnN0IHNvcnROb2RlcyA9IGVycm9ySW5mb3Muc2xpY2UoMCwgbGFzdFNvcnROb2Rlc0luZGV4ICsgMSk7XG4gICAgICAgICAgICBpbmZvcy5maXggPSBmdW5jdGlvbiAoZml4ZXIpIHtcbiAgICAgICAgICAgICAgY29uc3QgcmVtb3ZlRml4ZXJzID0gc29ydE5vZGVzLm1hcChmdW5jdGlvbiAoX2Vycm9ySW5mbykge1xuICAgICAgICAgICAgICAgIHJldHVybiBmaXhlci5yZW1vdmVSYW5nZShfZXJyb3JJbmZvLnJhbmdlKTtcbiAgICAgICAgICAgICAgfSk7XG4gICAgICAgICAgICAgIGNvbnN0IHJhbmdlID0gWzAsIHJlbW92ZUZpeGVyc1tyZW1vdmVGaXhlcnMubGVuZ3RoIC0gMV0ucmFuZ2VbMV1dO1xuICAgICAgICAgICAgICBsZXQgaW5zZXJ0U291cmNlQ29kZSA9IHNvcnROb2Rlcy5tYXAoZnVuY3Rpb24gKF9lcnJvckluZm8pIHtcbiAgICAgICAgICAgICAgICBjb25zdCBub2RlU291cmNlQ29kZSA9IFN0cmluZy5wcm90b3R5cGUuc2xpY2UuYXBwbHkoXG4gICAgICAgICAgICAgICAgICBvcmlnaW5Tb3VyY2VDb2RlLCBfZXJyb3JJbmZvLnJhbmdlLFxuICAgICAgICAgICAgICAgICk7XG4gICAgICAgICAgICAgICAgaWYgKCgvXFxTLykudGVzdChub2RlU291cmNlQ29kZVswXSkpIHtcbiAgICAgICAgICAgICAgICAgIHJldHVybiBgXFxuJHtub2RlU291cmNlQ29kZX1gO1xuICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgICAgICByZXR1cm4gbm9kZVNvdXJjZUNvZGU7XG4gICAgICAgICAgICAgIH0pLmpvaW4oJycpO1xuICAgICAgICAgICAgICBsZXQgaW5zZXJ0Rml4ZXIgPSBudWxsO1xuICAgICAgICAgICAgICBsZXQgcmVwbGFjZVNvdXJjZUNvZGUgPSAnJztcbiAgICAgICAgICAgICAgaWYgKCFsYXN0TGVnYWxJbXApIHtcbiAgICAgICAgICAgICAgICBpbnNlcnRTb3VyY2VDb2RlID0gaW5zZXJ0U291cmNlQ29kZS50cmltKCkgKyBpbnNlcnRTb3VyY2VDb2RlLm1hdGNoKC9eKFxccyspLylbMF07XG4gICAgICAgICAgICAgIH1cbiAgICAgICAgICAgICAgaW5zZXJ0Rml4ZXIgPSBsYXN0TGVnYWxJbXBcbiAgICAgICAgICAgICAgICA/IGZpeGVyLmluc2VydFRleHRBZnRlcihsYXN0TGVnYWxJbXAsIGluc2VydFNvdXJjZUNvZGUpXG4gICAgICAgICAgICAgICAgOiBmaXhlci5pbnNlcnRUZXh0QmVmb3JlKGJvZHlbMF0sIGluc2VydFNvdXJjZUNvZGUpO1xuXG4gICAgICAgICAgICAgIGNvbnN0IGZpeGVycyA9IFtpbnNlcnRGaXhlcl0uY29uY2F0KHJlbW92ZUZpeGVycyk7XG4gICAgICAgICAgICAgIGZpeGVycy5mb3JFYWNoKChjb21wdXRlZEZpeGVyLCBpKSA9PiB7XG4gICAgICAgICAgICAgICAgcmVwbGFjZVNvdXJjZUNvZGUgKz0gb3JpZ2luU291cmNlQ29kZS5zbGljZShcbiAgICAgICAgICAgICAgICAgIGZpeGVyc1tpIC0gMV0gPyBmaXhlcnNbaSAtIDFdLnJhbmdlWzFdIDogMCwgY29tcHV0ZWRGaXhlci5yYW5nZVswXSxcbiAgICAgICAgICAgICAgICApICsgY29tcHV0ZWRGaXhlci50ZXh0O1xuICAgICAgICAgICAgICB9KTtcblxuICAgICAgICAgICAgICByZXR1cm4gZml4ZXIucmVwbGFjZVRleHRSYW5nZShyYW5nZSwgcmVwbGFjZVNvdXJjZUNvZGUpO1xuICAgICAgICAgICAgfTtcbiAgICAgICAgICB9XG4gICAgICAgICAgY29udGV4dC5yZXBvcnQoaW5mb3MpO1xuICAgICAgICB9KTtcbiAgICAgIH0sXG4gICAgfTtcbiAgfSxcbn07XG4iXX0=