'use strict';var _docsUrl = require('../docsUrl');var _docsUrl2 = _interopRequireDefault(_docsUrl);function _interopRequireDefault(obj) {return obj && obj.__esModule ? obj : { default: obj };}

module.exports = {
  meta: {
    type: 'suggestion',
    docs: {
      url: (0, _docsUrl2.default)('no-mutable-exports') },

    schema: [] },


  create: function (context) {
    function checkDeclaration(node) {const
      kind = node.kind;
      if (kind === 'var' || kind === 'let') {
        context.report(node, `Exporting mutable '${kind}' binding, use 'const' instead.`);
      }
    }

    function checkDeclarationsInScope(_ref, name) {let variables = _ref.variables;
      for (let variable of variables) {
        if (variable.name === name) {
          for (let def of variable.defs) {
            if (def.type === 'Variable' && def.parent) {
              checkDeclaration(def.parent);
            }
          }
        }
      }
    }

    function handleExportDefault(node) {
      const scope = context.getScope();

      if (node.declaration.name) {
        checkDeclarationsInScope(scope, node.declaration.name);
      }
    }

    function handleExportNamed(node) {
      const scope = context.getScope();

      if (node.declaration) {
        checkDeclaration(node.declaration);
      } else if (!node.source) {
        for (let specifier of node.specifiers) {
          checkDeclarationsInScope(scope, specifier.local.name);
        }
      }
    }

    return {
      'ExportDefaultDeclaration': handleExportDefault,
      'ExportNamedDeclaration': handleExportNamed };

  } };
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIi4uLy4uL3NyYy9ydWxlcy9uby1tdXRhYmxlLWV4cG9ydHMuanMiXSwibmFtZXMiOlsibW9kdWxlIiwiZXhwb3J0cyIsIm1ldGEiLCJ0eXBlIiwiZG9jcyIsInVybCIsInNjaGVtYSIsImNyZWF0ZSIsImNvbnRleHQiLCJjaGVja0RlY2xhcmF0aW9uIiwibm9kZSIsImtpbmQiLCJyZXBvcnQiLCJjaGVja0RlY2xhcmF0aW9uc0luU2NvcGUiLCJuYW1lIiwidmFyaWFibGVzIiwidmFyaWFibGUiLCJkZWYiLCJkZWZzIiwicGFyZW50IiwiaGFuZGxlRXhwb3J0RGVmYXVsdCIsInNjb3BlIiwiZ2V0U2NvcGUiLCJkZWNsYXJhdGlvbiIsImhhbmRsZUV4cG9ydE5hbWVkIiwic291cmNlIiwic3BlY2lmaWVyIiwic3BlY2lmaWVycyIsImxvY2FsIl0sIm1hcHBpbmdzIjoiYUFBQSxxQzs7QUFFQUEsT0FBT0MsT0FBUCxHQUFpQjtBQUNmQyxRQUFNO0FBQ0pDLFVBQU0sWUFERjtBQUVKQyxVQUFNO0FBQ0pDLFdBQUssdUJBQVEsb0JBQVIsQ0FERCxFQUZGOztBQUtKQyxZQUFRLEVBTEosRUFEUzs7O0FBU2ZDLFVBQVEsVUFBVUMsT0FBVixFQUFtQjtBQUN6QixhQUFTQyxnQkFBVCxDQUEwQkMsSUFBMUIsRUFBZ0M7QUFDdkJDLFVBRHVCLEdBQ2ZELElBRGUsQ0FDdkJDLElBRHVCO0FBRTlCLFVBQUlBLFNBQVMsS0FBVCxJQUFrQkEsU0FBUyxLQUEvQixFQUFzQztBQUNwQ0gsZ0JBQVFJLE1BQVIsQ0FBZUYsSUFBZixFQUFzQixzQkFBcUJDLElBQUssaUNBQWhEO0FBQ0Q7QUFDRjs7QUFFRCxhQUFTRSx3QkFBVCxPQUErQ0MsSUFBL0MsRUFBcUQsS0FBbEJDLFNBQWtCLFFBQWxCQSxTQUFrQjtBQUNuRCxXQUFLLElBQUlDLFFBQVQsSUFBcUJELFNBQXJCLEVBQWdDO0FBQzlCLFlBQUlDLFNBQVNGLElBQVQsS0FBa0JBLElBQXRCLEVBQTRCO0FBQzFCLGVBQUssSUFBSUcsR0FBVCxJQUFnQkQsU0FBU0UsSUFBekIsRUFBK0I7QUFDN0IsZ0JBQUlELElBQUlkLElBQUosS0FBYSxVQUFiLElBQTJCYyxJQUFJRSxNQUFuQyxFQUEyQztBQUN6Q1YsK0JBQWlCUSxJQUFJRSxNQUFyQjtBQUNEO0FBQ0Y7QUFDRjtBQUNGO0FBQ0Y7O0FBRUQsYUFBU0MsbUJBQVQsQ0FBNkJWLElBQTdCLEVBQW1DO0FBQ2pDLFlBQU1XLFFBQVFiLFFBQVFjLFFBQVIsRUFBZDs7QUFFQSxVQUFJWixLQUFLYSxXQUFMLENBQWlCVCxJQUFyQixFQUEyQjtBQUN6QkQsaUNBQXlCUSxLQUF6QixFQUFnQ1gsS0FBS2EsV0FBTCxDQUFpQlQsSUFBakQ7QUFDRDtBQUNGOztBQUVELGFBQVNVLGlCQUFULENBQTJCZCxJQUEzQixFQUFpQztBQUMvQixZQUFNVyxRQUFRYixRQUFRYyxRQUFSLEVBQWQ7O0FBRUEsVUFBSVosS0FBS2EsV0FBVCxFQUF1QjtBQUNyQmQseUJBQWlCQyxLQUFLYSxXQUF0QjtBQUNELE9BRkQsTUFFTyxJQUFJLENBQUNiLEtBQUtlLE1BQVYsRUFBa0I7QUFDdkIsYUFBSyxJQUFJQyxTQUFULElBQXNCaEIsS0FBS2lCLFVBQTNCLEVBQXVDO0FBQ3JDZCxtQ0FBeUJRLEtBQXpCLEVBQWdDSyxVQUFVRSxLQUFWLENBQWdCZCxJQUFoRDtBQUNEO0FBQ0Y7QUFDRjs7QUFFRCxXQUFPO0FBQ0wsa0NBQTRCTSxtQkFEdkI7QUFFTCxnQ0FBMEJJLGlCQUZyQixFQUFQOztBQUlELEdBckRjLEVBQWpCIiwiZmlsZSI6Im5vLW11dGFibGUtZXhwb3J0cy5qcyIsInNvdXJjZXNDb250ZW50IjpbImltcG9ydCBkb2NzVXJsIGZyb20gJy4uL2RvY3NVcmwnXG5cbm1vZHVsZS5leHBvcnRzID0ge1xuICBtZXRhOiB7XG4gICAgdHlwZTogJ3N1Z2dlc3Rpb24nLFxuICAgIGRvY3M6IHtcbiAgICAgIHVybDogZG9jc1VybCgnbm8tbXV0YWJsZS1leHBvcnRzJyksXG4gICAgfSxcbiAgICBzY2hlbWE6IFtdLFxuICB9LFxuXG4gIGNyZWF0ZTogZnVuY3Rpb24gKGNvbnRleHQpIHtcbiAgICBmdW5jdGlvbiBjaGVja0RlY2xhcmF0aW9uKG5vZGUpIHtcbiAgICAgIGNvbnN0IHtraW5kfSA9IG5vZGVcbiAgICAgIGlmIChraW5kID09PSAndmFyJyB8fCBraW5kID09PSAnbGV0Jykge1xuICAgICAgICBjb250ZXh0LnJlcG9ydChub2RlLCBgRXhwb3J0aW5nIG11dGFibGUgJyR7a2luZH0nIGJpbmRpbmcsIHVzZSAnY29uc3QnIGluc3RlYWQuYClcbiAgICAgIH1cbiAgICB9XG5cbiAgICBmdW5jdGlvbiBjaGVja0RlY2xhcmF0aW9uc0luU2NvcGUoe3ZhcmlhYmxlc30sIG5hbWUpIHtcbiAgICAgIGZvciAobGV0IHZhcmlhYmxlIG9mIHZhcmlhYmxlcykge1xuICAgICAgICBpZiAodmFyaWFibGUubmFtZSA9PT0gbmFtZSkge1xuICAgICAgICAgIGZvciAobGV0IGRlZiBvZiB2YXJpYWJsZS5kZWZzKSB7XG4gICAgICAgICAgICBpZiAoZGVmLnR5cGUgPT09ICdWYXJpYWJsZScgJiYgZGVmLnBhcmVudCkge1xuICAgICAgICAgICAgICBjaGVja0RlY2xhcmF0aW9uKGRlZi5wYXJlbnQpXG4gICAgICAgICAgICB9XG4gICAgICAgICAgfVxuICAgICAgICB9XG4gICAgICB9XG4gICAgfVxuXG4gICAgZnVuY3Rpb24gaGFuZGxlRXhwb3J0RGVmYXVsdChub2RlKSB7XG4gICAgICBjb25zdCBzY29wZSA9IGNvbnRleHQuZ2V0U2NvcGUoKVxuXG4gICAgICBpZiAobm9kZS5kZWNsYXJhdGlvbi5uYW1lKSB7XG4gICAgICAgIGNoZWNrRGVjbGFyYXRpb25zSW5TY29wZShzY29wZSwgbm9kZS5kZWNsYXJhdGlvbi5uYW1lKVxuICAgICAgfVxuICAgIH1cblxuICAgIGZ1bmN0aW9uIGhhbmRsZUV4cG9ydE5hbWVkKG5vZGUpIHtcbiAgICAgIGNvbnN0IHNjb3BlID0gY29udGV4dC5nZXRTY29wZSgpXG5cbiAgICAgIGlmIChub2RlLmRlY2xhcmF0aW9uKSAge1xuICAgICAgICBjaGVja0RlY2xhcmF0aW9uKG5vZGUuZGVjbGFyYXRpb24pXG4gICAgICB9IGVsc2UgaWYgKCFub2RlLnNvdXJjZSkge1xuICAgICAgICBmb3IgKGxldCBzcGVjaWZpZXIgb2Ygbm9kZS5zcGVjaWZpZXJzKSB7XG4gICAgICAgICAgY2hlY2tEZWNsYXJhdGlvbnNJblNjb3BlKHNjb3BlLCBzcGVjaWZpZXIubG9jYWwubmFtZSlcbiAgICAgICAgfVxuICAgICAgfVxuICAgIH1cblxuICAgIHJldHVybiB7XG4gICAgICAnRXhwb3J0RGVmYXVsdERlY2xhcmF0aW9uJzogaGFuZGxlRXhwb3J0RGVmYXVsdCxcbiAgICAgICdFeHBvcnROYW1lZERlY2xhcmF0aW9uJzogaGFuZGxlRXhwb3J0TmFtZWQsXG4gICAgfVxuICB9LFxufVxuIl19