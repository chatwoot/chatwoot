'use strict';

var _docsUrl = require('../docsUrl');var _docsUrl2 = _interopRequireDefault(_docsUrl);function _interopRequireDefault(obj) {return obj && obj.__esModule ? obj : { default: obj };}

module.exports = {
  meta: {
    type: 'suggestion',
    docs: {
      url: (0, _docsUrl2.default)('prefer-default-export') },

    schema: [] },


  create: function (context) {
    let specifierExportCount = 0;
    let hasDefaultExport = false;
    let hasStarExport = false;
    let hasTypeExport = false;
    let namedExportNode = null;

    function captureDeclaration(identifierOrPattern) {
      if (identifierOrPattern.type === 'ObjectPattern') {
        // recursively capture
        identifierOrPattern.properties.
        forEach(function (property) {
          captureDeclaration(property.value);
        });
      } else if (identifierOrPattern.type === 'ArrayPattern') {
        identifierOrPattern.elements.
        forEach(captureDeclaration);
      } else {
        // assume it's a single standard identifier
        specifierExportCount++;
      }
    }

    return {
      'ExportDefaultSpecifier': function () {
        hasDefaultExport = true;
      },

      'ExportSpecifier': function (node) {
        if (node.exported.name === 'default') {
          hasDefaultExport = true;
        } else {
          specifierExportCount++;
          namedExportNode = node;
        }
      },

      'ExportNamedDeclaration': function (node) {
        // if there are specifiers, node.declaration should be null
        if (!node.declaration) return;const

        type = node.declaration.type;

        if (
        type === 'TSTypeAliasDeclaration' ||
        type === 'TypeAlias' ||
        type === 'TSInterfaceDeclaration' ||
        type === 'InterfaceDeclaration')
        {
          specifierExportCount++;
          hasTypeExport = true;
          return;
        }

        if (node.declaration.declarations) {
          node.declaration.declarations.forEach(function (declaration) {
            captureDeclaration(declaration.id);
          });
        } else
        {
          // captures 'export function foo() {}' syntax
          specifierExportCount++;
        }

        namedExportNode = node;
      },

      'ExportDefaultDeclaration': function () {
        hasDefaultExport = true;
      },

      'ExportAllDeclaration': function () {
        hasStarExport = true;
      },

      'Program:exit': function () {
        if (specifierExportCount === 1 && !hasDefaultExport && !hasStarExport && !hasTypeExport) {
          context.report(namedExportNode, 'Prefer default export.');
        }
      } };

  } };
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIi4uLy4uL3NyYy9ydWxlcy9wcmVmZXItZGVmYXVsdC1leHBvcnQuanMiXSwibmFtZXMiOlsibW9kdWxlIiwiZXhwb3J0cyIsIm1ldGEiLCJ0eXBlIiwiZG9jcyIsInVybCIsInNjaGVtYSIsImNyZWF0ZSIsImNvbnRleHQiLCJzcGVjaWZpZXJFeHBvcnRDb3VudCIsImhhc0RlZmF1bHRFeHBvcnQiLCJoYXNTdGFyRXhwb3J0IiwiaGFzVHlwZUV4cG9ydCIsIm5hbWVkRXhwb3J0Tm9kZSIsImNhcHR1cmVEZWNsYXJhdGlvbiIsImlkZW50aWZpZXJPclBhdHRlcm4iLCJwcm9wZXJ0aWVzIiwiZm9yRWFjaCIsInByb3BlcnR5IiwidmFsdWUiLCJlbGVtZW50cyIsIm5vZGUiLCJleHBvcnRlZCIsIm5hbWUiLCJkZWNsYXJhdGlvbiIsImRlY2xhcmF0aW9ucyIsImlkIiwicmVwb3J0Il0sIm1hcHBpbmdzIjoiQUFBQTs7QUFFQSxxQzs7QUFFQUEsT0FBT0MsT0FBUCxHQUFpQjtBQUNmQyxRQUFNO0FBQ0pDLFVBQU0sWUFERjtBQUVKQyxVQUFNO0FBQ0pDLFdBQUssdUJBQVEsdUJBQVIsQ0FERCxFQUZGOztBQUtKQyxZQUFRLEVBTEosRUFEUzs7O0FBU2ZDLFVBQVEsVUFBU0MsT0FBVCxFQUFrQjtBQUN4QixRQUFJQyx1QkFBdUIsQ0FBM0I7QUFDQSxRQUFJQyxtQkFBbUIsS0FBdkI7QUFDQSxRQUFJQyxnQkFBZ0IsS0FBcEI7QUFDQSxRQUFJQyxnQkFBZ0IsS0FBcEI7QUFDQSxRQUFJQyxrQkFBa0IsSUFBdEI7O0FBRUEsYUFBU0Msa0JBQVQsQ0FBNEJDLG1CQUE1QixFQUFpRDtBQUMvQyxVQUFJQSxvQkFBb0JaLElBQXBCLEtBQTZCLGVBQWpDLEVBQWtEO0FBQ2hEO0FBQ0FZLDRCQUFvQkMsVUFBcEI7QUFDR0MsZUFESCxDQUNXLFVBQVNDLFFBQVQsRUFBbUI7QUFDMUJKLDZCQUFtQkksU0FBU0MsS0FBNUI7QUFDRCxTQUhIO0FBSUQsT0FORCxNQU1PLElBQUlKLG9CQUFvQlosSUFBcEIsS0FBNkIsY0FBakMsRUFBaUQ7QUFDdERZLDRCQUFvQkssUUFBcEI7QUFDR0gsZUFESCxDQUNXSCxrQkFEWDtBQUVELE9BSE0sTUFHQztBQUNSO0FBQ0VMO0FBQ0Q7QUFDRjs7QUFFRCxXQUFPO0FBQ0wsZ0NBQTBCLFlBQVc7QUFDbkNDLDJCQUFtQixJQUFuQjtBQUNELE9BSEk7O0FBS0wseUJBQW1CLFVBQVNXLElBQVQsRUFBZTtBQUNoQyxZQUFJQSxLQUFLQyxRQUFMLENBQWNDLElBQWQsS0FBdUIsU0FBM0IsRUFBc0M7QUFDcENiLDZCQUFtQixJQUFuQjtBQUNELFNBRkQsTUFFTztBQUNMRDtBQUNBSSw0QkFBa0JRLElBQWxCO0FBQ0Q7QUFDRixPQVpJOztBQWNMLGdDQUEwQixVQUFTQSxJQUFULEVBQWU7QUFDdkM7QUFDQSxZQUFJLENBQUNBLEtBQUtHLFdBQVYsRUFBdUIsT0FGZ0I7O0FBSS9CckIsWUFKK0IsR0FJdEJrQixLQUFLRyxXQUppQixDQUkvQnJCLElBSitCOztBQU12QztBQUNFQSxpQkFBUyx3QkFBVDtBQUNBQSxpQkFBUyxXQURUO0FBRUFBLGlCQUFTLHdCQUZUO0FBR0FBLGlCQUFTLHNCQUpYO0FBS0U7QUFDQU07QUFDQUcsMEJBQWdCLElBQWhCO0FBQ0E7QUFDRDs7QUFFRCxZQUFJUyxLQUFLRyxXQUFMLENBQWlCQyxZQUFyQixFQUFtQztBQUNqQ0osZUFBS0csV0FBTCxDQUFpQkMsWUFBakIsQ0FBOEJSLE9BQTlCLENBQXNDLFVBQVNPLFdBQVQsRUFBc0I7QUFDMURWLCtCQUFtQlUsWUFBWUUsRUFBL0I7QUFDRCxXQUZEO0FBR0QsU0FKRDtBQUtLO0FBQ0g7QUFDQWpCO0FBQ0Q7O0FBRURJLDBCQUFrQlEsSUFBbEI7QUFDRCxPQTFDSTs7QUE0Q0wsa0NBQTRCLFlBQVc7QUFDckNYLDJCQUFtQixJQUFuQjtBQUNELE9BOUNJOztBQWdETCw4QkFBd0IsWUFBVztBQUNqQ0Msd0JBQWdCLElBQWhCO0FBQ0QsT0FsREk7O0FBb0RMLHNCQUFnQixZQUFXO0FBQ3pCLFlBQUlGLHlCQUF5QixDQUF6QixJQUE4QixDQUFDQyxnQkFBL0IsSUFBbUQsQ0FBQ0MsYUFBcEQsSUFBcUUsQ0FBQ0MsYUFBMUUsRUFBeUY7QUFDdkZKLGtCQUFRbUIsTUFBUixDQUFlZCxlQUFmLEVBQWdDLHdCQUFoQztBQUNEO0FBQ0YsT0F4REksRUFBUDs7QUEwREQsR0ExRmMsRUFBakIiLCJmaWxlIjoicHJlZmVyLWRlZmF1bHQtZXhwb3J0LmpzIiwic291cmNlc0NvbnRlbnQiOlsiJ3VzZSBzdHJpY3QnXG5cbmltcG9ydCBkb2NzVXJsIGZyb20gJy4uL2RvY3NVcmwnXG5cbm1vZHVsZS5leHBvcnRzID0ge1xuICBtZXRhOiB7XG4gICAgdHlwZTogJ3N1Z2dlc3Rpb24nLFxuICAgIGRvY3M6IHtcbiAgICAgIHVybDogZG9jc1VybCgncHJlZmVyLWRlZmF1bHQtZXhwb3J0JyksXG4gICAgfSxcbiAgICBzY2hlbWE6IFtdLFxuICB9LFxuXG4gIGNyZWF0ZTogZnVuY3Rpb24oY29udGV4dCkge1xuICAgIGxldCBzcGVjaWZpZXJFeHBvcnRDb3VudCA9IDBcbiAgICBsZXQgaGFzRGVmYXVsdEV4cG9ydCA9IGZhbHNlXG4gICAgbGV0IGhhc1N0YXJFeHBvcnQgPSBmYWxzZVxuICAgIGxldCBoYXNUeXBlRXhwb3J0ID0gZmFsc2VcbiAgICBsZXQgbmFtZWRFeHBvcnROb2RlID0gbnVsbFxuXG4gICAgZnVuY3Rpb24gY2FwdHVyZURlY2xhcmF0aW9uKGlkZW50aWZpZXJPclBhdHRlcm4pIHtcbiAgICAgIGlmIChpZGVudGlmaWVyT3JQYXR0ZXJuLnR5cGUgPT09ICdPYmplY3RQYXR0ZXJuJykge1xuICAgICAgICAvLyByZWN1cnNpdmVseSBjYXB0dXJlXG4gICAgICAgIGlkZW50aWZpZXJPclBhdHRlcm4ucHJvcGVydGllc1xuICAgICAgICAgIC5mb3JFYWNoKGZ1bmN0aW9uKHByb3BlcnR5KSB7XG4gICAgICAgICAgICBjYXB0dXJlRGVjbGFyYXRpb24ocHJvcGVydHkudmFsdWUpXG4gICAgICAgICAgfSlcbiAgICAgIH0gZWxzZSBpZiAoaWRlbnRpZmllck9yUGF0dGVybi50eXBlID09PSAnQXJyYXlQYXR0ZXJuJykge1xuICAgICAgICBpZGVudGlmaWVyT3JQYXR0ZXJuLmVsZW1lbnRzXG4gICAgICAgICAgLmZvckVhY2goY2FwdHVyZURlY2xhcmF0aW9uKVxuICAgICAgfSBlbHNlICB7XG4gICAgICAvLyBhc3N1bWUgaXQncyBhIHNpbmdsZSBzdGFuZGFyZCBpZGVudGlmaWVyXG4gICAgICAgIHNwZWNpZmllckV4cG9ydENvdW50KytcbiAgICAgIH1cbiAgICB9XG5cbiAgICByZXR1cm4ge1xuICAgICAgJ0V4cG9ydERlZmF1bHRTcGVjaWZpZXInOiBmdW5jdGlvbigpIHtcbiAgICAgICAgaGFzRGVmYXVsdEV4cG9ydCA9IHRydWVcbiAgICAgIH0sXG5cbiAgICAgICdFeHBvcnRTcGVjaWZpZXInOiBmdW5jdGlvbihub2RlKSB7XG4gICAgICAgIGlmIChub2RlLmV4cG9ydGVkLm5hbWUgPT09ICdkZWZhdWx0Jykge1xuICAgICAgICAgIGhhc0RlZmF1bHRFeHBvcnQgPSB0cnVlXG4gICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgc3BlY2lmaWVyRXhwb3J0Q291bnQrK1xuICAgICAgICAgIG5hbWVkRXhwb3J0Tm9kZSA9IG5vZGVcbiAgICAgICAgfVxuICAgICAgfSxcblxuICAgICAgJ0V4cG9ydE5hbWVkRGVjbGFyYXRpb24nOiBmdW5jdGlvbihub2RlKSB7XG4gICAgICAgIC8vIGlmIHRoZXJlIGFyZSBzcGVjaWZpZXJzLCBub2RlLmRlY2xhcmF0aW9uIHNob3VsZCBiZSBudWxsXG4gICAgICAgIGlmICghbm9kZS5kZWNsYXJhdGlvbikgcmV0dXJuXG5cbiAgICAgICAgY29uc3QgeyB0eXBlIH0gPSBub2RlLmRlY2xhcmF0aW9uXG5cbiAgICAgICAgaWYgKFxuICAgICAgICAgIHR5cGUgPT09ICdUU1R5cGVBbGlhc0RlY2xhcmF0aW9uJyB8fFxuICAgICAgICAgIHR5cGUgPT09ICdUeXBlQWxpYXMnIHx8XG4gICAgICAgICAgdHlwZSA9PT0gJ1RTSW50ZXJmYWNlRGVjbGFyYXRpb24nIHx8XG4gICAgICAgICAgdHlwZSA9PT0gJ0ludGVyZmFjZURlY2xhcmF0aW9uJ1xuICAgICAgICApIHtcbiAgICAgICAgICBzcGVjaWZpZXJFeHBvcnRDb3VudCsrXG4gICAgICAgICAgaGFzVHlwZUV4cG9ydCA9IHRydWVcbiAgICAgICAgICByZXR1cm5cbiAgICAgICAgfVxuXG4gICAgICAgIGlmIChub2RlLmRlY2xhcmF0aW9uLmRlY2xhcmF0aW9ucykge1xuICAgICAgICAgIG5vZGUuZGVjbGFyYXRpb24uZGVjbGFyYXRpb25zLmZvckVhY2goZnVuY3Rpb24oZGVjbGFyYXRpb24pIHtcbiAgICAgICAgICAgIGNhcHR1cmVEZWNsYXJhdGlvbihkZWNsYXJhdGlvbi5pZClcbiAgICAgICAgICB9KVxuICAgICAgICB9XG4gICAgICAgIGVsc2Uge1xuICAgICAgICAgIC8vIGNhcHR1cmVzICdleHBvcnQgZnVuY3Rpb24gZm9vKCkge30nIHN5bnRheFxuICAgICAgICAgIHNwZWNpZmllckV4cG9ydENvdW50KytcbiAgICAgICAgfVxuXG4gICAgICAgIG5hbWVkRXhwb3J0Tm9kZSA9IG5vZGVcbiAgICAgIH0sXG5cbiAgICAgICdFeHBvcnREZWZhdWx0RGVjbGFyYXRpb24nOiBmdW5jdGlvbigpIHtcbiAgICAgICAgaGFzRGVmYXVsdEV4cG9ydCA9IHRydWVcbiAgICAgIH0sXG5cbiAgICAgICdFeHBvcnRBbGxEZWNsYXJhdGlvbic6IGZ1bmN0aW9uKCkge1xuICAgICAgICBoYXNTdGFyRXhwb3J0ID0gdHJ1ZVxuICAgICAgfSxcblxuICAgICAgJ1Byb2dyYW06ZXhpdCc6IGZ1bmN0aW9uKCkge1xuICAgICAgICBpZiAoc3BlY2lmaWVyRXhwb3J0Q291bnQgPT09IDEgJiYgIWhhc0RlZmF1bHRFeHBvcnQgJiYgIWhhc1N0YXJFeHBvcnQgJiYgIWhhc1R5cGVFeHBvcnQpIHtcbiAgICAgICAgICBjb250ZXh0LnJlcG9ydChuYW1lZEV4cG9ydE5vZGUsICdQcmVmZXIgZGVmYXVsdCBleHBvcnQuJylcbiAgICAgICAgfVxuICAgICAgfSxcbiAgICB9XG4gIH0sXG59XG4iXX0=