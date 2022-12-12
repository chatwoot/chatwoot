'use strict';




var _resolve = require('eslint-module-utils/resolve');var _resolve2 = _interopRequireDefault(_resolve);
var _staticRequire = require('../core/staticRequire');var _staticRequire2 = _interopRequireDefault(_staticRequire);
var _docsUrl = require('../docsUrl');var _docsUrl2 = _interopRequireDefault(_docsUrl);function _interopRequireDefault(obj) {return obj && obj.__esModule ? obj : { default: obj };}

function isImportingSelf(context, node, requireName) {
  const filePath = context.getFilename();

  // If the input is from stdin, this test can't fail
  if (filePath !== '<text>' && filePath === (0, _resolve2.default)(requireName, context)) {
    context.report({
      node,
      message: 'Module imports itself.' });

  }
} /**
   * @fileOverview Forbids a module from importing itself
   * @author Gio d'Amelio
   */module.exports = { meta: {
    type: 'problem',
    docs: {
      description: 'Forbid a module from importing itself',
      recommended: true,
      url: (0, _docsUrl2.default)('no-self-import') },


    schema: [] },

  create: function (context) {
    return {
      ImportDeclaration(node) {
        isImportingSelf(context, node, node.source.value);
      },
      CallExpression(node) {
        if ((0, _staticRequire2.default)(node)) {
          isImportingSelf(context, node, node.arguments[0].value);
        }
      } };

  } };
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIi4uLy4uL3NyYy9ydWxlcy9uby1zZWxmLWltcG9ydC5qcyJdLCJuYW1lcyI6WyJpc0ltcG9ydGluZ1NlbGYiLCJjb250ZXh0Iiwibm9kZSIsInJlcXVpcmVOYW1lIiwiZmlsZVBhdGgiLCJnZXRGaWxlbmFtZSIsInJlcG9ydCIsIm1lc3NhZ2UiLCJtb2R1bGUiLCJleHBvcnRzIiwibWV0YSIsInR5cGUiLCJkb2NzIiwiZGVzY3JpcHRpb24iLCJyZWNvbW1lbmRlZCIsInVybCIsInNjaGVtYSIsImNyZWF0ZSIsIkltcG9ydERlY2xhcmF0aW9uIiwic291cmNlIiwidmFsdWUiLCJDYWxsRXhwcmVzc2lvbiIsImFyZ3VtZW50cyJdLCJtYXBwaW5ncyI6Ijs7Ozs7QUFLQSxzRDtBQUNBLHNEO0FBQ0EscUM7O0FBRUEsU0FBU0EsZUFBVCxDQUF5QkMsT0FBekIsRUFBa0NDLElBQWxDLEVBQXdDQyxXQUF4QyxFQUFxRDtBQUNuRCxRQUFNQyxXQUFXSCxRQUFRSSxXQUFSLEVBQWpCOztBQUVBO0FBQ0EsTUFBSUQsYUFBYSxRQUFiLElBQXlCQSxhQUFhLHVCQUFRRCxXQUFSLEVBQXFCRixPQUFyQixDQUExQyxFQUF5RTtBQUN2RUEsWUFBUUssTUFBUixDQUFlO0FBQ1hKLFVBRFc7QUFFWEssZUFBUyx3QkFGRSxFQUFmOztBQUlEO0FBQ0YsQyxDQW5CRDs7O0tBcUJBQyxPQUFPQyxPQUFQLEdBQWlCLEVBQ2ZDLE1BQU07QUFDSkMsVUFBTSxTQURGO0FBRUpDLFVBQU07QUFDSkMsbUJBQWEsdUNBRFQ7QUFFSkMsbUJBQWEsSUFGVDtBQUdKQyxXQUFLLHVCQUFRLGdCQUFSLENBSEQsRUFGRjs7O0FBUUpDLFlBQVEsRUFSSixFQURTOztBQVdmQyxVQUFRLFVBQVVoQixPQUFWLEVBQW1CO0FBQ3pCLFdBQU87QUFDTGlCLHdCQUFrQmhCLElBQWxCLEVBQXdCO0FBQ3RCRix3QkFBZ0JDLE9BQWhCLEVBQXlCQyxJQUF6QixFQUErQkEsS0FBS2lCLE1BQUwsQ0FBWUMsS0FBM0M7QUFDRCxPQUhJO0FBSUxDLHFCQUFlbkIsSUFBZixFQUFxQjtBQUNuQixZQUFJLDZCQUFnQkEsSUFBaEIsQ0FBSixFQUEyQjtBQUN6QkYsMEJBQWdCQyxPQUFoQixFQUF5QkMsSUFBekIsRUFBK0JBLEtBQUtvQixTQUFMLENBQWUsQ0FBZixFQUFrQkYsS0FBakQ7QUFDRDtBQUNGLE9BUkksRUFBUDs7QUFVRCxHQXRCYyxFQUFqQiIsImZpbGUiOiJuby1zZWxmLWltcG9ydC5qcyIsInNvdXJjZXNDb250ZW50IjpbIi8qKlxuICogQGZpbGVPdmVydmlldyBGb3JiaWRzIGEgbW9kdWxlIGZyb20gaW1wb3J0aW5nIGl0c2VsZlxuICogQGF1dGhvciBHaW8gZCdBbWVsaW9cbiAqL1xuXG5pbXBvcnQgcmVzb2x2ZSBmcm9tICdlc2xpbnQtbW9kdWxlLXV0aWxzL3Jlc29sdmUnXG5pbXBvcnQgaXNTdGF0aWNSZXF1aXJlIGZyb20gJy4uL2NvcmUvc3RhdGljUmVxdWlyZSdcbmltcG9ydCBkb2NzVXJsIGZyb20gJy4uL2RvY3NVcmwnXG5cbmZ1bmN0aW9uIGlzSW1wb3J0aW5nU2VsZihjb250ZXh0LCBub2RlLCByZXF1aXJlTmFtZSkge1xuICBjb25zdCBmaWxlUGF0aCA9IGNvbnRleHQuZ2V0RmlsZW5hbWUoKVxuXG4gIC8vIElmIHRoZSBpbnB1dCBpcyBmcm9tIHN0ZGluLCB0aGlzIHRlc3QgY2FuJ3QgZmFpbFxuICBpZiAoZmlsZVBhdGggIT09ICc8dGV4dD4nICYmIGZpbGVQYXRoID09PSByZXNvbHZlKHJlcXVpcmVOYW1lLCBjb250ZXh0KSkge1xuICAgIGNvbnRleHQucmVwb3J0KHtcbiAgICAgICAgbm9kZSxcbiAgICAgICAgbWVzc2FnZTogJ01vZHVsZSBpbXBvcnRzIGl0c2VsZi4nLFxuICAgIH0pXG4gIH1cbn1cblxubW9kdWxlLmV4cG9ydHMgPSB7XG4gIG1ldGE6IHtcbiAgICB0eXBlOiAncHJvYmxlbScsXG4gICAgZG9jczoge1xuICAgICAgZGVzY3JpcHRpb246ICdGb3JiaWQgYSBtb2R1bGUgZnJvbSBpbXBvcnRpbmcgaXRzZWxmJyxcbiAgICAgIHJlY29tbWVuZGVkOiB0cnVlLFxuICAgICAgdXJsOiBkb2NzVXJsKCduby1zZWxmLWltcG9ydCcpLFxuICAgIH0sXG5cbiAgICBzY2hlbWE6IFtdLFxuICB9LFxuICBjcmVhdGU6IGZ1bmN0aW9uIChjb250ZXh0KSB7XG4gICAgcmV0dXJuIHtcbiAgICAgIEltcG9ydERlY2xhcmF0aW9uKG5vZGUpIHtcbiAgICAgICAgaXNJbXBvcnRpbmdTZWxmKGNvbnRleHQsIG5vZGUsIG5vZGUuc291cmNlLnZhbHVlKVxuICAgICAgfSxcbiAgICAgIENhbGxFeHByZXNzaW9uKG5vZGUpIHtcbiAgICAgICAgaWYgKGlzU3RhdGljUmVxdWlyZShub2RlKSkge1xuICAgICAgICAgIGlzSW1wb3J0aW5nU2VsZihjb250ZXh0LCBub2RlLCBub2RlLmFyZ3VtZW50c1swXS52YWx1ZSlcbiAgICAgICAgfVxuICAgICAgfSxcbiAgICB9XG4gIH0sXG59XG4iXX0=