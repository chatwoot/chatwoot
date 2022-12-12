'use strict';var _docsUrl = require('../docsUrl');var _docsUrl2 = _interopRequireDefault(_docsUrl);function _interopRequireDefault(obj) {return obj && obj.__esModule ? obj : { default: obj };}

module.exports = {
  meta: {
    type: 'suggestion',
    docs: { url: (0, _docsUrl2.default)('no-named-export') },
    schema: [] },


  create(context) {
    // ignore non-modules
    if (context.parserOptions.sourceType !== 'module') {
      return {};
    }

    const message = 'Named exports are not allowed.';

    return {
      ExportAllDeclaration(node) {
        context.report({ node, message });
      },

      ExportNamedDeclaration(node) {
        if (node.specifiers.length === 0) {
          return context.report({ node, message });
        }

        const someNamed = node.specifiers.some(specifier => specifier.exported.name !== 'default');
        if (someNamed) {
          context.report({ node, message });
        }
      } };

  } };
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIi4uLy4uL3NyYy9ydWxlcy9uby1uYW1lZC1leHBvcnQuanMiXSwibmFtZXMiOlsibW9kdWxlIiwiZXhwb3J0cyIsIm1ldGEiLCJ0eXBlIiwiZG9jcyIsInVybCIsInNjaGVtYSIsImNyZWF0ZSIsImNvbnRleHQiLCJwYXJzZXJPcHRpb25zIiwic291cmNlVHlwZSIsIm1lc3NhZ2UiLCJFeHBvcnRBbGxEZWNsYXJhdGlvbiIsIm5vZGUiLCJyZXBvcnQiLCJFeHBvcnROYW1lZERlY2xhcmF0aW9uIiwic3BlY2lmaWVycyIsImxlbmd0aCIsInNvbWVOYW1lZCIsInNvbWUiLCJzcGVjaWZpZXIiLCJleHBvcnRlZCIsIm5hbWUiXSwibWFwcGluZ3MiOiJhQUFBLHFDOztBQUVBQSxPQUFPQyxPQUFQLEdBQWlCO0FBQ2ZDLFFBQU07QUFDSkMsVUFBTSxZQURGO0FBRUpDLFVBQU0sRUFBRUMsS0FBSyx1QkFBUSxpQkFBUixDQUFQLEVBRkY7QUFHSkMsWUFBUSxFQUhKLEVBRFM7OztBQU9mQyxTQUFPQyxPQUFQLEVBQWdCO0FBQ2Q7QUFDQSxRQUFJQSxRQUFRQyxhQUFSLENBQXNCQyxVQUF0QixLQUFxQyxRQUF6QyxFQUFtRDtBQUNqRCxhQUFPLEVBQVA7QUFDRDs7QUFFRCxVQUFNQyxVQUFVLGdDQUFoQjs7QUFFQSxXQUFPO0FBQ0xDLDJCQUFxQkMsSUFBckIsRUFBMkI7QUFDekJMLGdCQUFRTSxNQUFSLENBQWUsRUFBQ0QsSUFBRCxFQUFPRixPQUFQLEVBQWY7QUFDRCxPQUhJOztBQUtMSSw2QkFBdUJGLElBQXZCLEVBQTZCO0FBQzNCLFlBQUlBLEtBQUtHLFVBQUwsQ0FBZ0JDLE1BQWhCLEtBQTJCLENBQS9CLEVBQWtDO0FBQ2hDLGlCQUFPVCxRQUFRTSxNQUFSLENBQWUsRUFBQ0QsSUFBRCxFQUFPRixPQUFQLEVBQWYsQ0FBUDtBQUNEOztBQUVELGNBQU1PLFlBQVlMLEtBQUtHLFVBQUwsQ0FBZ0JHLElBQWhCLENBQXFCQyxhQUFhQSxVQUFVQyxRQUFWLENBQW1CQyxJQUFuQixLQUE0QixTQUE5RCxDQUFsQjtBQUNBLFlBQUlKLFNBQUosRUFBZTtBQUNiVixrQkFBUU0sTUFBUixDQUFlLEVBQUNELElBQUQsRUFBT0YsT0FBUCxFQUFmO0FBQ0Q7QUFDRixPQWRJLEVBQVA7O0FBZ0JELEdBL0JjLEVBQWpCIiwiZmlsZSI6Im5vLW5hbWVkLWV4cG9ydC5qcyIsInNvdXJjZXNDb250ZW50IjpbImltcG9ydCBkb2NzVXJsIGZyb20gJy4uL2RvY3NVcmwnXG5cbm1vZHVsZS5leHBvcnRzID0ge1xuICBtZXRhOiB7XG4gICAgdHlwZTogJ3N1Z2dlc3Rpb24nLFxuICAgIGRvY3M6IHsgdXJsOiBkb2NzVXJsKCduby1uYW1lZC1leHBvcnQnKSB9LFxuICAgIHNjaGVtYTogW10sXG4gIH0sXG5cbiAgY3JlYXRlKGNvbnRleHQpIHtcbiAgICAvLyBpZ25vcmUgbm9uLW1vZHVsZXNcbiAgICBpZiAoY29udGV4dC5wYXJzZXJPcHRpb25zLnNvdXJjZVR5cGUgIT09ICdtb2R1bGUnKSB7XG4gICAgICByZXR1cm4ge31cbiAgICB9XG5cbiAgICBjb25zdCBtZXNzYWdlID0gJ05hbWVkIGV4cG9ydHMgYXJlIG5vdCBhbGxvd2VkLidcblxuICAgIHJldHVybiB7XG4gICAgICBFeHBvcnRBbGxEZWNsYXJhdGlvbihub2RlKSB7XG4gICAgICAgIGNvbnRleHQucmVwb3J0KHtub2RlLCBtZXNzYWdlfSlcbiAgICAgIH0sXG5cbiAgICAgIEV4cG9ydE5hbWVkRGVjbGFyYXRpb24obm9kZSkge1xuICAgICAgICBpZiAobm9kZS5zcGVjaWZpZXJzLmxlbmd0aCA9PT0gMCkge1xuICAgICAgICAgIHJldHVybiBjb250ZXh0LnJlcG9ydCh7bm9kZSwgbWVzc2FnZX0pXG4gICAgICAgIH1cblxuICAgICAgICBjb25zdCBzb21lTmFtZWQgPSBub2RlLnNwZWNpZmllcnMuc29tZShzcGVjaWZpZXIgPT4gc3BlY2lmaWVyLmV4cG9ydGVkLm5hbWUgIT09ICdkZWZhdWx0JylcbiAgICAgICAgaWYgKHNvbWVOYW1lZCkge1xuICAgICAgICAgIGNvbnRleHQucmVwb3J0KHtub2RlLCBtZXNzYWdlfSlcbiAgICAgICAgfVxuICAgICAgfSxcbiAgICB9XG4gIH0sXG59XG4iXX0=