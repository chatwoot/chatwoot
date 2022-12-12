'use strict';var _docsUrl = require('../docsUrl');var _docsUrl2 = _interopRequireDefault(_docsUrl);function _interopRequireDefault(obj) {return obj && obj.__esModule ? obj : { default: obj };}

module.exports = {
  meta: {
    type: 'suggestion',
    docs: {
      url: (0, _docsUrl2.default)('first') },

    fixable: 'code',
    schema: [
    {
      type: 'string',
      enum: ['absolute-first', 'disable-absolute-first'] }] },




  create: function (context) {
    function isPossibleDirective(node) {
      return node.type === 'ExpressionStatement' &&
      node.expression.type === 'Literal' &&
      typeof node.expression.value === 'string';
    }

    return {
      'Program': function (n) {
        const body = n.body,
        absoluteFirst = context.options[0] === 'absolute-first',
        message = 'Import in body of module; reorder to top.',
        sourceCode = context.getSourceCode(),
        originSourceCode = sourceCode.getText();
        let nonImportCount = 0,
        anyExpressions = false,
        anyRelative = false,
        lastLegalImp = null,
        errorInfos = [],
        shouldSort = true,
        lastSortNodesIndex = 0;
        body.forEach(function (node, index) {
          if (!anyExpressions && isPossibleDirective(node)) {
            return;
          }

          anyExpressions = true;

          if (node.type === 'ImportDeclaration') {
            if (absoluteFirst) {
              if (/^\./.test(node.source.value)) {
                anyRelative = true;
              } else if (anyRelative) {
                context.report({
                  node: node.source,
                  message: 'Absolute imports should come before relative imports.' });

              }
            }
            if (nonImportCount > 0) {
              for (let variable of context.getDeclaredVariables(node)) {
                if (!shouldSort) break;
                const references = variable.references;
                if (references.length) {
                  for (let reference of references) {
                    if (reference.identifier.range[0] < node.range[1]) {
                      shouldSort = false;
                      break;
                    }
                  }
                }
              }
              shouldSort && (lastSortNodesIndex = errorInfos.length);
              errorInfos.push({
                node,
                range: [body[index - 1].range[1], node.range[1]] });

            } else {
              lastLegalImp = node;
            }
          } else {
            nonImportCount++;
          }
        });
        if (!errorInfos.length) return;
        errorInfos.forEach(function (errorInfo, index) {
          const node = errorInfo.node,
          infos = {
            node,
            message };

          if (index < lastSortNodesIndex) {
            infos.fix = function (fixer) {
              return fixer.insertTextAfter(node, '');
            };
          } else if (index === lastSortNodesIndex) {
            const sortNodes = errorInfos.slice(0, lastSortNodesIndex + 1);
            infos.fix = function (fixer) {
              const removeFixers = sortNodes.map(function (_errorInfo) {
                return fixer.removeRange(_errorInfo.range);
              }),
              range = [0, removeFixers[removeFixers.length - 1].range[1]];
              let insertSourceCode = sortNodes.map(function (_errorInfo) {
                const nodeSourceCode = String.prototype.slice.apply(
                originSourceCode, _errorInfo.range);

                if (/\S/.test(nodeSourceCode[0])) {
                  return '\n' + nodeSourceCode;
                }
                return nodeSourceCode;
              }).join(''),
              insertFixer = null,
              replaceSourceCode = '';
              if (!lastLegalImp) {
                insertSourceCode =
                insertSourceCode.trim() + insertSourceCode.match(/^(\s+)/)[0];
              }
              insertFixer = lastLegalImp ?
              fixer.insertTextAfter(lastLegalImp, insertSourceCode) :
              fixer.insertTextBefore(body[0], insertSourceCode);
              const fixers = [insertFixer].concat(removeFixers);
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
      } };

  } };
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIi4uLy4uL3NyYy9ydWxlcy9maXJzdC5qcyJdLCJuYW1lcyI6WyJtb2R1bGUiLCJleHBvcnRzIiwibWV0YSIsInR5cGUiLCJkb2NzIiwidXJsIiwiZml4YWJsZSIsInNjaGVtYSIsImVudW0iLCJjcmVhdGUiLCJjb250ZXh0IiwiaXNQb3NzaWJsZURpcmVjdGl2ZSIsIm5vZGUiLCJleHByZXNzaW9uIiwidmFsdWUiLCJuIiwiYm9keSIsImFic29sdXRlRmlyc3QiLCJvcHRpb25zIiwibWVzc2FnZSIsInNvdXJjZUNvZGUiLCJnZXRTb3VyY2VDb2RlIiwib3JpZ2luU291cmNlQ29kZSIsImdldFRleHQiLCJub25JbXBvcnRDb3VudCIsImFueUV4cHJlc3Npb25zIiwiYW55UmVsYXRpdmUiLCJsYXN0TGVnYWxJbXAiLCJlcnJvckluZm9zIiwic2hvdWxkU29ydCIsImxhc3RTb3J0Tm9kZXNJbmRleCIsImZvckVhY2giLCJpbmRleCIsInRlc3QiLCJzb3VyY2UiLCJyZXBvcnQiLCJ2YXJpYWJsZSIsImdldERlY2xhcmVkVmFyaWFibGVzIiwicmVmZXJlbmNlcyIsImxlbmd0aCIsInJlZmVyZW5jZSIsImlkZW50aWZpZXIiLCJyYW5nZSIsInB1c2giLCJlcnJvckluZm8iLCJpbmZvcyIsImZpeCIsImZpeGVyIiwiaW5zZXJ0VGV4dEFmdGVyIiwic29ydE5vZGVzIiwic2xpY2UiLCJyZW1vdmVGaXhlcnMiLCJtYXAiLCJfZXJyb3JJbmZvIiwicmVtb3ZlUmFuZ2UiLCJpbnNlcnRTb3VyY2VDb2RlIiwibm9kZVNvdXJjZUNvZGUiLCJTdHJpbmciLCJwcm90b3R5cGUiLCJhcHBseSIsImpvaW4iLCJpbnNlcnRGaXhlciIsInJlcGxhY2VTb3VyY2VDb2RlIiwidHJpbSIsIm1hdGNoIiwiaW5zZXJ0VGV4dEJlZm9yZSIsImZpeGVycyIsImNvbmNhdCIsImNvbXB1dGVkRml4ZXIiLCJpIiwidGV4dCIsInJlcGxhY2VUZXh0UmFuZ2UiXSwibWFwcGluZ3MiOiJhQUFBLHFD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QVJnQixDQVFYLEVBUlcsQ0FBdkI7QUFTSUMsNEJBQWMsSUFUbEI7QUFVSUMsa0NBQW9CLEVBVnhCO0FBV0Esa0JBQUksQ0FBQ25DLFlBQUwsRUFBbUI7QUFDZjRCO0FBQ0VBLGlDQUFpQlEsSUFBakIsS0FBMEJSLGlCQUFpQlMsS0FBakIsQ0FBdUIsUUFBdkIsRUFBaUMsQ0FBakMsQ0FENUI7QUFFSDtBQUNESCw0QkFBY2xDO0FBQ0FvQixvQkFBTUMsZUFBTixDQUFzQnJCLFlBQXRCLEVBQW9DNEIsZ0JBQXBDLENBREE7QUFFQVIsb0JBQU1rQixnQkFBTixDQUF1QmpELEtBQUssQ0FBTCxDQUF2QixFQUFnQ3VDLGdCQUFoQyxDQUZkO0FBR0Esb0JBQU1XLFNBQVMsQ0FBQ0wsV0FBRCxFQUFjTSxNQUFkLENBQXFCaEIsWUFBckIsQ0FBZjtBQUNBZSxxQkFBT25DLE9BQVAsQ0FBZSxVQUFVcUMsYUFBVixFQUF5QkMsQ0FBekIsRUFBNEI7QUFDekNQLHFDQUFzQnhDLGlCQUFpQjRCLEtBQWpCO0FBQ3BCZ0IsdUJBQU9HLElBQUksQ0FBWCxJQUFnQkgsT0FBT0csSUFBSSxDQUFYLEVBQWMzQixLQUFkLENBQW9CLENBQXBCLENBQWhCLEdBQXlDLENBRHJCLEVBQ3dCMEIsY0FBYzFCLEtBQWQsQ0FBb0IsQ0FBcEIsQ0FEeEI7QUFFbEIwQiw4QkFBY0UsSUFGbEI7QUFHRCxlQUpEO0FBS0EscUJBQU92QixNQUFNd0IsZ0JBQU4sQ0FBdUI3QixLQUF2QixFQUE4Qm9CLGlCQUE5QixDQUFQO0FBQ0QsYUE5QkQ7QUErQkQ7QUFDRHBELGtCQUFReUIsTUFBUixDQUFlVSxLQUFmO0FBQ0QsU0E3Q0Q7QUE4Q0QsT0F4R0ksRUFBUDs7QUEwR0QsR0FoSWMsRUFBakIiLCJmaWxlIjoiZmlyc3QuanMiLCJzb3VyY2VzQ29udGVudCI6WyJpbXBvcnQgZG9jc1VybCBmcm9tICcuLi9kb2NzVXJsJ1xuXG5tb2R1bGUuZXhwb3J0cyA9IHtcbiAgbWV0YToge1xuICAgIHR5cGU6ICdzdWdnZXN0aW9uJyxcbiAgICBkb2NzOiB7XG4gICAgICB1cmw6IGRvY3NVcmwoJ2ZpcnN0JyksXG4gICAgfSxcbiAgICBmaXhhYmxlOiAnY29kZScsXG4gICAgc2NoZW1hOiBbXG4gICAgICB7XG4gICAgICAgIHR5cGU6ICdzdHJpbmcnLFxuICAgICAgICBlbnVtOiBbJ2Fic29sdXRlLWZpcnN0JywgJ2Rpc2FibGUtYWJzb2x1dGUtZmlyc3QnXSxcbiAgICAgIH0sXG4gICAgXSxcbiAgfSxcblxuICBjcmVhdGU6IGZ1bmN0aW9uIChjb250ZXh0KSB7XG4gICAgZnVuY3Rpb24gaXNQb3NzaWJsZURpcmVjdGl2ZSAobm9kZSkge1xuICAgICAgcmV0dXJuIG5vZGUudHlwZSA9PT0gJ0V4cHJlc3Npb25TdGF0ZW1lbnQnICYmXG4gICAgICAgIG5vZGUuZXhwcmVzc2lvbi50eXBlID09PSAnTGl0ZXJhbCcgJiZcbiAgICAgICAgdHlwZW9mIG5vZGUuZXhwcmVzc2lvbi52YWx1ZSA9PT0gJ3N0cmluZydcbiAgICB9XG5cbiAgICByZXR1cm4ge1xuICAgICAgJ1Byb2dyYW0nOiBmdW5jdGlvbiAobikge1xuICAgICAgICBjb25zdCBib2R5ID0gbi5ib2R5XG4gICAgICAgICAgICAsIGFic29sdXRlRmlyc3QgPSBjb250ZXh0Lm9wdGlvbnNbMF0gPT09ICdhYnNvbHV0ZS1maXJzdCdcbiAgICAgICAgICAgICwgbWVzc2FnZSA9ICdJbXBvcnQgaW4gYm9keSBvZiBtb2R1bGU7IHJlb3JkZXIgdG8gdG9wLidcbiAgICAgICAgICAgICwgc291cmNlQ29kZSA9IGNvbnRleHQuZ2V0U291cmNlQ29kZSgpXG4gICAgICAgICAgICAsIG9yaWdpblNvdXJjZUNvZGUgPSBzb3VyY2VDb2RlLmdldFRleHQoKVxuICAgICAgICBsZXQgbm9uSW1wb3J0Q291bnQgPSAwXG4gICAgICAgICAgLCBhbnlFeHByZXNzaW9ucyA9IGZhbHNlXG4gICAgICAgICAgLCBhbnlSZWxhdGl2ZSA9IGZhbHNlXG4gICAgICAgICAgLCBsYXN0TGVnYWxJbXAgPSBudWxsXG4gICAgICAgICAgLCBlcnJvckluZm9zID0gW11cbiAgICAgICAgICAsIHNob3VsZFNvcnQgPSB0cnVlXG4gICAgICAgICAgLCBsYXN0U29ydE5vZGVzSW5kZXggPSAwXG4gICAgICAgIGJvZHkuZm9yRWFjaChmdW5jdGlvbiAobm9kZSwgaW5kZXgpe1xuICAgICAgICAgIGlmICghYW55RXhwcmVzc2lvbnMgJiYgaXNQb3NzaWJsZURpcmVjdGl2ZShub2RlKSkge1xuICAgICAgICAgICAgcmV0dXJuXG4gICAgICAgICAgfVxuXG4gICAgICAgICAgYW55RXhwcmVzc2lvbnMgPSB0cnVlXG5cbiAgICAgICAgICBpZiAobm9kZS50eXBlID09PSAnSW1wb3J0RGVjbGFyYXRpb24nKSB7XG4gICAgICAgICAgICBpZiAoYWJzb2x1dGVGaXJzdCkge1xuICAgICAgICAgICAgICBpZiAoL15cXC4vLnRlc3Qobm9kZS5zb3VyY2UudmFsdWUpKSB7XG4gICAgICAgICAgICAgICAgYW55UmVsYXRpdmUgPSB0cnVlXG4gICAgICAgICAgICAgIH0gZWxzZSBpZiAoYW55UmVsYXRpdmUpIHtcbiAgICAgICAgICAgICAgICBjb250ZXh0LnJlcG9ydCh7XG4gICAgICAgICAgICAgICAgICBub2RlOiBub2RlLnNvdXJjZSxcbiAgICAgICAgICAgICAgICAgIG1lc3NhZ2U6ICdBYnNvbHV0ZSBpbXBvcnRzIHNob3VsZCBjb21lIGJlZm9yZSByZWxhdGl2ZSBpbXBvcnRzLicsXG4gICAgICAgICAgICAgICAgfSlcbiAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgfVxuICAgICAgICAgICAgaWYgKG5vbkltcG9ydENvdW50ID4gMCkge1xuICAgICAgICAgICAgICBmb3IgKGxldCB2YXJpYWJsZSBvZiBjb250ZXh0LmdldERlY2xhcmVkVmFyaWFibGVzKG5vZGUpKSB7XG4gICAgICAgICAgICAgICAgaWYgKCFzaG91bGRTb3J0KSBicmVha1xuICAgICAgICAgICAgICAgIGNvbnN0IHJlZmVyZW5jZXMgPSB2YXJpYWJsZS5yZWZlcmVuY2VzXG4gICAgICAgICAgICAgICAgaWYgKHJlZmVyZW5jZXMubGVuZ3RoKSB7XG4gICAgICAgICAgICAgICAgICBmb3IgKGxldCByZWZlcmVuY2Ugb2YgcmVmZXJlbmNlcykge1xuICAgICAgICAgICAgICAgICAgICBpZiAocmVmZXJlbmNlLmlkZW50aWZpZXIucmFuZ2VbMF0gPCBub2RlLnJhbmdlWzFdKSB7XG4gICAgICAgICAgICAgICAgICAgICAgc2hvdWxkU29ydCA9IGZhbHNlXG4gICAgICAgICAgICAgICAgICAgICAgYnJlYWtcbiAgICAgICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgICBzaG91bGRTb3J0ICYmIChsYXN0U29ydE5vZGVzSW5kZXggPSBlcnJvckluZm9zLmxlbmd0aClcbiAgICAgICAgICAgICAgZXJyb3JJbmZvcy5wdXNoKHtcbiAgICAgICAgICAgICAgICBub2RlLFxuICAgICAgICAgICAgICAgIHJhbmdlOiBbYm9keVtpbmRleCAtIDFdLnJhbmdlWzFdLCBub2RlLnJhbmdlWzFdXSxcbiAgICAgICAgICAgICAgfSlcbiAgICAgICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgICAgIGxhc3RMZWdhbEltcCA9IG5vZGVcbiAgICAgICAgICAgIH1cbiAgICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgICAgbm9uSW1wb3J0Q291bnQrK1xuICAgICAgICAgIH1cbiAgICAgICAgfSlcbiAgICAgICAgaWYgKCFlcnJvckluZm9zLmxlbmd0aCkgcmV0dXJuXG4gICAgICAgIGVycm9ySW5mb3MuZm9yRWFjaChmdW5jdGlvbiAoZXJyb3JJbmZvLCBpbmRleCkge1xuICAgICAgICAgIGNvbnN0IG5vZGUgPSBlcnJvckluZm8ubm9kZVxuICAgICAgICAgICAgICAsIGluZm9zID0ge1xuICAgICAgICAgICAgICAgIG5vZGUsXG4gICAgICAgICAgICAgICAgbWVzc2FnZSxcbiAgICAgICAgICAgICAgfVxuICAgICAgICAgIGlmIChpbmRleCA8IGxhc3RTb3J0Tm9kZXNJbmRleCkge1xuICAgICAgICAgICAgaW5mb3MuZml4ID0gZnVuY3Rpb24gKGZpeGVyKSB7XG4gICAgICAgICAgICAgIHJldHVybiBmaXhlci5pbnNlcnRUZXh0QWZ0ZXIobm9kZSwgJycpXG4gICAgICAgICAgICB9XG4gICAgICAgICAgfSBlbHNlIGlmIChpbmRleCA9PT0gbGFzdFNvcnROb2Rlc0luZGV4KSB7XG4gICAgICAgICAgICBjb25zdCBzb3J0Tm9kZXMgPSBlcnJvckluZm9zLnNsaWNlKDAsIGxhc3RTb3J0Tm9kZXNJbmRleCArIDEpXG4gICAgICAgICAgICBpbmZvcy5maXggPSBmdW5jdGlvbiAoZml4ZXIpIHtcbiAgICAgICAgICAgICAgY29uc3QgcmVtb3ZlRml4ZXJzID0gc29ydE5vZGVzLm1hcChmdW5jdGlvbiAoX2Vycm9ySW5mbykge1xuICAgICAgICAgICAgICAgICAgICByZXR1cm4gZml4ZXIucmVtb3ZlUmFuZ2UoX2Vycm9ySW5mby5yYW5nZSlcbiAgICAgICAgICAgICAgICAgIH0pXG4gICAgICAgICAgICAgICAgICAsIHJhbmdlID0gWzAsIHJlbW92ZUZpeGVyc1tyZW1vdmVGaXhlcnMubGVuZ3RoIC0gMV0ucmFuZ2VbMV1dXG4gICAgICAgICAgICAgIGxldCBpbnNlcnRTb3VyY2VDb2RlID0gc29ydE5vZGVzLm1hcChmdW5jdGlvbiAoX2Vycm9ySW5mbykge1xuICAgICAgICAgICAgICAgICAgICBjb25zdCBub2RlU291cmNlQ29kZSA9IFN0cmluZy5wcm90b3R5cGUuc2xpY2UuYXBwbHkoXG4gICAgICAgICAgICAgICAgICAgICAgb3JpZ2luU291cmNlQ29kZSwgX2Vycm9ySW5mby5yYW5nZVxuICAgICAgICAgICAgICAgICAgICApXG4gICAgICAgICAgICAgICAgICAgIGlmICgvXFxTLy50ZXN0KG5vZGVTb3VyY2VDb2RlWzBdKSkge1xuICAgICAgICAgICAgICAgICAgICAgIHJldHVybiAnXFxuJyArIG5vZGVTb3VyY2VDb2RlXG4gICAgICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgICAgICAgICAgcmV0dXJuIG5vZGVTb3VyY2VDb2RlXG4gICAgICAgICAgICAgICAgICB9KS5qb2luKCcnKVxuICAgICAgICAgICAgICAgICwgaW5zZXJ0Rml4ZXIgPSBudWxsXG4gICAgICAgICAgICAgICAgLCByZXBsYWNlU291cmNlQ29kZSA9ICcnXG4gICAgICAgICAgICAgIGlmICghbGFzdExlZ2FsSW1wKSB7XG4gICAgICAgICAgICAgICAgICBpbnNlcnRTb3VyY2VDb2RlID1cbiAgICAgICAgICAgICAgICAgICAgaW5zZXJ0U291cmNlQ29kZS50cmltKCkgKyBpbnNlcnRTb3VyY2VDb2RlLm1hdGNoKC9eKFxccyspLylbMF1cbiAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgICBpbnNlcnRGaXhlciA9IGxhc3RMZWdhbEltcCA/XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgZml4ZXIuaW5zZXJ0VGV4dEFmdGVyKGxhc3RMZWdhbEltcCwgaW5zZXJ0U291cmNlQ29kZSkgOlxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGZpeGVyLmluc2VydFRleHRCZWZvcmUoYm9keVswXSwgaW5zZXJ0U291cmNlQ29kZSlcbiAgICAgICAgICAgICAgY29uc3QgZml4ZXJzID0gW2luc2VydEZpeGVyXS5jb25jYXQocmVtb3ZlRml4ZXJzKVxuICAgICAgICAgICAgICBmaXhlcnMuZm9yRWFjaChmdW5jdGlvbiAoY29tcHV0ZWRGaXhlciwgaSkge1xuICAgICAgICAgICAgICAgIHJlcGxhY2VTb3VyY2VDb2RlICs9IChvcmlnaW5Tb3VyY2VDb2RlLnNsaWNlKFxuICAgICAgICAgICAgICAgICAgZml4ZXJzW2kgLSAxXSA/IGZpeGVyc1tpIC0gMV0ucmFuZ2VbMV0gOiAwLCBjb21wdXRlZEZpeGVyLnJhbmdlWzBdXG4gICAgICAgICAgICAgICAgKSArIGNvbXB1dGVkRml4ZXIudGV4dClcbiAgICAgICAgICAgICAgfSlcbiAgICAgICAgICAgICAgcmV0dXJuIGZpeGVyLnJlcGxhY2VUZXh0UmFuZ2UocmFuZ2UsIHJlcGxhY2VTb3VyY2VDb2RlKVxuICAgICAgICAgICAgfVxuICAgICAgICAgIH1cbiAgICAgICAgICBjb250ZXh0LnJlcG9ydChpbmZvcylcbiAgICAgICAgfSlcbiAgICAgIH0sXG4gICAgfVxuICB9LFxufVxuIl19