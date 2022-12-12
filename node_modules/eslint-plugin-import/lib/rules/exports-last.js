'use strict';var _docsUrl = require('../docsUrl');var _docsUrl2 = _interopRequireDefault(_docsUrl);function _interopRequireDefault(obj) {return obj && obj.__esModule ? obj : { default: obj };}

function isNonExportStatement(_ref) {let type = _ref.type;
  return type !== 'ExportDefaultDeclaration' &&
  type !== 'ExportNamedDeclaration' &&
  type !== 'ExportAllDeclaration';
}

module.exports = {
  meta: {
    type: 'suggestion',
    docs: {
      url: (0, _docsUrl2.default)('exports-last') },

    schema: [] },


  create: function (context) {
    return {
      Program: function (_ref2) {let body = _ref2.body;
        const lastNonExportStatementIndex = body.reduce(function findLastIndex(acc, item, index) {
          if (isNonExportStatement(item)) {
            return index;
          }
          return acc;
        }, -1);

        if (lastNonExportStatementIndex !== -1) {
          body.slice(0, lastNonExportStatementIndex).forEach(function checkNonExport(node) {
            if (!isNonExportStatement(node)) {
              context.report({
                node,
                message: 'Export statements should appear at the end of the file' });

            }
          });
        }
      } };

  } };
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIi4uLy4uL3NyYy9ydWxlcy9leHBvcnRzLWxhc3QuanMiXSwibmFtZXMiOlsiaXNOb25FeHBvcnRTdGF0ZW1lbnQiLCJ0eXBlIiwibW9kdWxlIiwiZXhwb3J0cyIsIm1ldGEiLCJkb2NzIiwidXJsIiwic2NoZW1hIiwiY3JlYXRlIiwiY29udGV4dCIsIlByb2dyYW0iLCJib2R5IiwibGFzdE5vbkV4cG9ydFN0YXRlbWVudEluZGV4IiwicmVkdWNlIiwiZmluZExhc3RJbmRleCIsImFjYyIsIml0ZW0iLCJpbmRleCIsInNsaWNlIiwiZm9yRWFjaCIsImNoZWNrTm9uRXhwb3J0Iiwibm9kZSIsInJlcG9ydCIsIm1lc3NhZ2UiXSwibWFwcGluZ3MiOiJhQUFBLHFDOztBQUVBLFNBQVNBLG9CQUFULE9BQXdDLEtBQVJDLElBQVEsUUFBUkEsSUFBUTtBQUN0QyxTQUFPQSxTQUFTLDBCQUFUO0FBQ0xBLFdBQVMsd0JBREo7QUFFTEEsV0FBUyxzQkFGWDtBQUdEOztBQUVEQyxPQUFPQyxPQUFQLEdBQWlCO0FBQ2ZDLFFBQU07QUFDSkgsVUFBTSxZQURGO0FBRUpJLFVBQU07QUFDSkMsV0FBSyx1QkFBUSxjQUFSLENBREQsRUFGRjs7QUFLSkMsWUFBUSxFQUxKLEVBRFM7OztBQVNmQyxVQUFRLFVBQVVDLE9BQVYsRUFBbUI7QUFDekIsV0FBTztBQUNMQyxlQUFTLGlCQUFvQixLQUFSQyxJQUFRLFNBQVJBLElBQVE7QUFDM0IsY0FBTUMsOEJBQThCRCxLQUFLRSxNQUFMLENBQVksU0FBU0MsYUFBVCxDQUF1QkMsR0FBdkIsRUFBNEJDLElBQTVCLEVBQWtDQyxLQUFsQyxFQUF5QztBQUN2RixjQUFJakIscUJBQXFCZ0IsSUFBckIsQ0FBSixFQUFnQztBQUM5QixtQkFBT0MsS0FBUDtBQUNEO0FBQ0QsaUJBQU9GLEdBQVA7QUFDRCxTQUxtQyxFQUtqQyxDQUFDLENBTGdDLENBQXBDOztBQU9BLFlBQUlILGdDQUFnQyxDQUFDLENBQXJDLEVBQXdDO0FBQ3RDRCxlQUFLTyxLQUFMLENBQVcsQ0FBWCxFQUFjTiwyQkFBZCxFQUEyQ08sT0FBM0MsQ0FBbUQsU0FBU0MsY0FBVCxDQUF3QkMsSUFBeEIsRUFBOEI7QUFDL0UsZ0JBQUksQ0FBQ3JCLHFCQUFxQnFCLElBQXJCLENBQUwsRUFBaUM7QUFDL0JaLHNCQUFRYSxNQUFSLENBQWU7QUFDYkQsb0JBRGE7QUFFYkUseUJBQVMsd0RBRkksRUFBZjs7QUFJRDtBQUNGLFdBUEQ7QUFRRDtBQUNGLE9BbkJJLEVBQVA7O0FBcUJELEdBL0JjLEVBQWpCIiwiZmlsZSI6ImV4cG9ydHMtbGFzdC5qcyIsInNvdXJjZXNDb250ZW50IjpbImltcG9ydCBkb2NzVXJsIGZyb20gJy4uL2RvY3NVcmwnXG5cbmZ1bmN0aW9uIGlzTm9uRXhwb3J0U3RhdGVtZW50KHsgdHlwZSB9KSB7XG4gIHJldHVybiB0eXBlICE9PSAnRXhwb3J0RGVmYXVsdERlY2xhcmF0aW9uJyAmJlxuICAgIHR5cGUgIT09ICdFeHBvcnROYW1lZERlY2xhcmF0aW9uJyAmJlxuICAgIHR5cGUgIT09ICdFeHBvcnRBbGxEZWNsYXJhdGlvbidcbn1cblxubW9kdWxlLmV4cG9ydHMgPSB7XG4gIG1ldGE6IHtcbiAgICB0eXBlOiAnc3VnZ2VzdGlvbicsXG4gICAgZG9jczoge1xuICAgICAgdXJsOiBkb2NzVXJsKCdleHBvcnRzLWxhc3QnKSxcbiAgICB9LFxuICAgIHNjaGVtYTogW10sXG4gIH0sXG5cbiAgY3JlYXRlOiBmdW5jdGlvbiAoY29udGV4dCkge1xuICAgIHJldHVybiB7XG4gICAgICBQcm9ncmFtOiBmdW5jdGlvbiAoeyBib2R5IH0pIHtcbiAgICAgICAgY29uc3QgbGFzdE5vbkV4cG9ydFN0YXRlbWVudEluZGV4ID0gYm9keS5yZWR1Y2UoZnVuY3Rpb24gZmluZExhc3RJbmRleChhY2MsIGl0ZW0sIGluZGV4KSB7XG4gICAgICAgICAgaWYgKGlzTm9uRXhwb3J0U3RhdGVtZW50KGl0ZW0pKSB7XG4gICAgICAgICAgICByZXR1cm4gaW5kZXhcbiAgICAgICAgICB9XG4gICAgICAgICAgcmV0dXJuIGFjY1xuICAgICAgICB9LCAtMSlcblxuICAgICAgICBpZiAobGFzdE5vbkV4cG9ydFN0YXRlbWVudEluZGV4ICE9PSAtMSkge1xuICAgICAgICAgIGJvZHkuc2xpY2UoMCwgbGFzdE5vbkV4cG9ydFN0YXRlbWVudEluZGV4KS5mb3JFYWNoKGZ1bmN0aW9uIGNoZWNrTm9uRXhwb3J0KG5vZGUpIHtcbiAgICAgICAgICAgIGlmICghaXNOb25FeHBvcnRTdGF0ZW1lbnQobm9kZSkpIHtcbiAgICAgICAgICAgICAgY29udGV4dC5yZXBvcnQoe1xuICAgICAgICAgICAgICAgIG5vZGUsXG4gICAgICAgICAgICAgICAgbWVzc2FnZTogJ0V4cG9ydCBzdGF0ZW1lbnRzIHNob3VsZCBhcHBlYXIgYXQgdGhlIGVuZCBvZiB0aGUgZmlsZScsXG4gICAgICAgICAgICAgIH0pXG4gICAgICAgICAgICB9XG4gICAgICAgICAgfSlcbiAgICAgICAgfVxuICAgICAgfSxcbiAgICB9XG4gIH0sXG59XG4iXX0=