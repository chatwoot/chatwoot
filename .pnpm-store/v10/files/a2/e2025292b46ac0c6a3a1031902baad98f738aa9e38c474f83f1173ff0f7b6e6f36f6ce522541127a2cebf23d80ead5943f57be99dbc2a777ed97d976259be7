'use strict';var _docsUrl = require('../docsUrl');var _docsUrl2 = _interopRequireDefault(_docsUrl);function _interopRequireDefault(obj) {return obj && obj.__esModule ? obj : { 'default': obj };}

module.exports = {
  meta: {
    type: 'suggestion',
    docs: {
      category: 'Style guide',
      description: 'Forbid named exports.',
      url: (0, _docsUrl2['default'])('no-named-export') },

    schema: [] },


  create: function () {function create(context) {
      // ignore non-modules
      if (context.parserOptions.sourceType !== 'module') {
        return {};
      }

      var message = 'Named exports are not allowed.';

      return {
        ExportAllDeclaration: function () {function ExportAllDeclaration(node) {
            context.report({ node: node, message: message });
          }return ExportAllDeclaration;}(),

        ExportNamedDeclaration: function () {function ExportNamedDeclaration(node) {
            if (node.specifiers.length === 0) {
              return context.report({ node: node, message: message });
            }

            var someNamed = node.specifiers.some(function (specifier) {return (specifier.exported.name || specifier.exported.value) !== 'default';});
            if (someNamed) {
              context.report({ node: node, message: message });
            }
          }return ExportNamedDeclaration;}() };

    }return create;}() };
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIi4uLy4uL3NyYy9ydWxlcy9uby1uYW1lZC1leHBvcnQuanMiXSwibmFtZXMiOlsibW9kdWxlIiwiZXhwb3J0cyIsIm1ldGEiLCJ0eXBlIiwiZG9jcyIsImNhdGVnb3J5IiwiZGVzY3JpcHRpb24iLCJ1cmwiLCJzY2hlbWEiLCJjcmVhdGUiLCJjb250ZXh0IiwicGFyc2VyT3B0aW9ucyIsInNvdXJjZVR5cGUiLCJtZXNzYWdlIiwiRXhwb3J0QWxsRGVjbGFyYXRpb24iLCJub2RlIiwicmVwb3J0IiwiRXhwb3J0TmFtZWREZWNsYXJhdGlvbiIsInNwZWNpZmllcnMiLCJsZW5ndGgiLCJzb21lTmFtZWQiLCJzb21lIiwic3BlY2lmaWVyIiwiZXhwb3J0ZWQiLCJuYW1lIiwidmFsdWUiXSwibWFwcGluZ3MiOiJhQUFBLHFDOztBQUVBQSxPQUFPQyxPQUFQLEdBQWlCO0FBQ2ZDLFFBQU07QUFDSkMsVUFBTSxZQURGO0FBRUpDLFVBQU07QUFDSkMsZ0JBQVUsYUFETjtBQUVKQyxtQkFBYSx1QkFGVDtBQUdKQyxXQUFLLDBCQUFRLGlCQUFSLENBSEQsRUFGRjs7QUFPSkMsWUFBUSxFQVBKLEVBRFM7OztBQVdmQyxRQVhlLCtCQVdSQyxPQVhRLEVBV0M7QUFDZDtBQUNBLFVBQUlBLFFBQVFDLGFBQVIsQ0FBc0JDLFVBQXRCLEtBQXFDLFFBQXpDLEVBQW1EO0FBQ2pELGVBQU8sRUFBUDtBQUNEOztBQUVELFVBQU1DLFVBQVUsZ0NBQWhCOztBQUVBLGFBQU87QUFDTEMsNEJBREssNkNBQ2dCQyxJQURoQixFQUNzQjtBQUN6Qkwsb0JBQVFNLE1BQVIsQ0FBZSxFQUFFRCxVQUFGLEVBQVFGLGdCQUFSLEVBQWY7QUFDRCxXQUhJOztBQUtMSSw4QkFMSywrQ0FLa0JGLElBTGxCLEVBS3dCO0FBQzNCLGdCQUFJQSxLQUFLRyxVQUFMLENBQWdCQyxNQUFoQixLQUEyQixDQUEvQixFQUFrQztBQUNoQyxxQkFBT1QsUUFBUU0sTUFBUixDQUFlLEVBQUVELFVBQUYsRUFBUUYsZ0JBQVIsRUFBZixDQUFQO0FBQ0Q7O0FBRUQsZ0JBQU1PLFlBQVlMLEtBQUtHLFVBQUwsQ0FBZ0JHLElBQWhCLENBQXFCLFVBQUNDLFNBQUQsVUFBZSxDQUFDQSxVQUFVQyxRQUFWLENBQW1CQyxJQUFuQixJQUEyQkYsVUFBVUMsUUFBVixDQUFtQkUsS0FBL0MsTUFBMEQsU0FBekUsRUFBckIsQ0FBbEI7QUFDQSxnQkFBSUwsU0FBSixFQUFlO0FBQ2JWLHNCQUFRTSxNQUFSLENBQWUsRUFBRUQsVUFBRixFQUFRRixnQkFBUixFQUFmO0FBQ0Q7QUFDRixXQWRJLG1DQUFQOztBQWdCRCxLQW5DYyxtQkFBakIiLCJmaWxlIjoibm8tbmFtZWQtZXhwb3J0LmpzIiwic291cmNlc0NvbnRlbnQiOlsiaW1wb3J0IGRvY3NVcmwgZnJvbSAnLi4vZG9jc1VybCc7XG5cbm1vZHVsZS5leHBvcnRzID0ge1xuICBtZXRhOiB7XG4gICAgdHlwZTogJ3N1Z2dlc3Rpb24nLFxuICAgIGRvY3M6IHtcbiAgICAgIGNhdGVnb3J5OiAnU3R5bGUgZ3VpZGUnLFxuICAgICAgZGVzY3JpcHRpb246ICdGb3JiaWQgbmFtZWQgZXhwb3J0cy4nLFxuICAgICAgdXJsOiBkb2NzVXJsKCduby1uYW1lZC1leHBvcnQnKSxcbiAgICB9LFxuICAgIHNjaGVtYTogW10sXG4gIH0sXG5cbiAgY3JlYXRlKGNvbnRleHQpIHtcbiAgICAvLyBpZ25vcmUgbm9uLW1vZHVsZXNcbiAgICBpZiAoY29udGV4dC5wYXJzZXJPcHRpb25zLnNvdXJjZVR5cGUgIT09ICdtb2R1bGUnKSB7XG4gICAgICByZXR1cm4ge307XG4gICAgfVxuXG4gICAgY29uc3QgbWVzc2FnZSA9ICdOYW1lZCBleHBvcnRzIGFyZSBub3QgYWxsb3dlZC4nO1xuXG4gICAgcmV0dXJuIHtcbiAgICAgIEV4cG9ydEFsbERlY2xhcmF0aW9uKG5vZGUpIHtcbiAgICAgICAgY29udGV4dC5yZXBvcnQoeyBub2RlLCBtZXNzYWdlIH0pO1xuICAgICAgfSxcblxuICAgICAgRXhwb3J0TmFtZWREZWNsYXJhdGlvbihub2RlKSB7XG4gICAgICAgIGlmIChub2RlLnNwZWNpZmllcnMubGVuZ3RoID09PSAwKSB7XG4gICAgICAgICAgcmV0dXJuIGNvbnRleHQucmVwb3J0KHsgbm9kZSwgbWVzc2FnZSB9KTtcbiAgICAgICAgfVxuXG4gICAgICAgIGNvbnN0IHNvbWVOYW1lZCA9IG5vZGUuc3BlY2lmaWVycy5zb21lKChzcGVjaWZpZXIpID0+IChzcGVjaWZpZXIuZXhwb3J0ZWQubmFtZSB8fCBzcGVjaWZpZXIuZXhwb3J0ZWQudmFsdWUpICE9PSAnZGVmYXVsdCcpO1xuICAgICAgICBpZiAoc29tZU5hbWVkKSB7XG4gICAgICAgICAgY29udGV4dC5yZXBvcnQoeyBub2RlLCBtZXNzYWdlIH0pO1xuICAgICAgICB9XG4gICAgICB9LFxuICAgIH07XG4gIH0sXG59O1xuIl19