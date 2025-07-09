'use strict';var _builder = require('../exportMap/builder');var _builder2 = _interopRequireDefault(_builder);
var _importDeclaration = require('../importDeclaration');var _importDeclaration2 = _interopRequireDefault(_importDeclaration);
var _docsUrl = require('../docsUrl');var _docsUrl2 = _interopRequireDefault(_docsUrl);function _interopRequireDefault(obj) {return obj && obj.__esModule ? obj : { 'default': obj };}

module.exports = {
  meta: {
    type: 'problem',
    docs: {
      category: 'Helpful warnings',
      description: 'Forbid use of exported name as identifier of default export.',
      url: (0, _docsUrl2['default'])('no-named-as-default') },

    schema: [] },


  create: function () {function create(context) {
      function checkDefault(nameKey, defaultSpecifier) {
        // #566: default is a valid specifier
        if (defaultSpecifier[nameKey].name === 'default') {return;}

        var declaration = (0, _importDeclaration2['default'])(context);

        var imports = _builder2['default'].get(declaration.source.value, context);
        if (imports == null) {return;}

        if (imports.errors.length) {
          imports.reportErrors(context, declaration);
          return;
        }

        if (imports.has('default') && imports.has(defaultSpecifier[nameKey].name)) {

          context.report(
          defaultSpecifier, 'Using exported name \'' + String(
          defaultSpecifier[nameKey].name) + '\' as identifier for default export.');


        }
      }
      return {
        ImportDefaultSpecifier: checkDefault.bind(null, 'local'),
        ExportDefaultSpecifier: checkDefault.bind(null, 'exported') };

    }return create;}() };
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIi4uLy4uL3NyYy9ydWxlcy9uby1uYW1lZC1hcy1kZWZhdWx0LmpzIl0sIm5hbWVzIjpbIm1vZHVsZSIsImV4cG9ydHMiLCJtZXRhIiwidHlwZSIsImRvY3MiLCJjYXRlZ29yeSIsImRlc2NyaXB0aW9uIiwidXJsIiwic2NoZW1hIiwiY3JlYXRlIiwiY29udGV4dCIsImNoZWNrRGVmYXVsdCIsIm5hbWVLZXkiLCJkZWZhdWx0U3BlY2lmaWVyIiwibmFtZSIsImRlY2xhcmF0aW9uIiwiaW1wb3J0cyIsIkV4cG9ydE1hcEJ1aWxkZXIiLCJnZXQiLCJzb3VyY2UiLCJ2YWx1ZSIsImVycm9ycyIsImxlbmd0aCIsInJlcG9ydEVycm9ycyIsImhhcyIsInJlcG9ydCIsIkltcG9ydERlZmF1bHRTcGVjaWZpZXIiLCJiaW5kIiwiRXhwb3J0RGVmYXVsdFNwZWNpZmllciJdLCJtYXBwaW5ncyI6ImFBQUEsK0M7QUFDQSx5RDtBQUNBLHFDOztBQUVBQSxPQUFPQyxPQUFQLEdBQWlCO0FBQ2ZDLFFBQU07QUFDSkMsVUFBTSxTQURGO0FBRUpDLFVBQU07QUFDSkMsZ0JBQVUsa0JBRE47QUFFSkMsbUJBQWEsOERBRlQ7QUFHSkMsV0FBSywwQkFBUSxxQkFBUixDQUhELEVBRkY7O0FBT0pDLFlBQVEsRUFQSixFQURTOzs7QUFXZkMsUUFYZSwrQkFXUkMsT0FYUSxFQVdDO0FBQ2QsZUFBU0MsWUFBVCxDQUFzQkMsT0FBdEIsRUFBK0JDLGdCQUEvQixFQUFpRDtBQUMvQztBQUNBLFlBQUlBLGlCQUFpQkQsT0FBakIsRUFBMEJFLElBQTFCLEtBQW1DLFNBQXZDLEVBQWtELENBQUUsT0FBUzs7QUFFN0QsWUFBTUMsY0FBYyxvQ0FBa0JMLE9BQWxCLENBQXBCOztBQUVBLFlBQU1NLFVBQVVDLHFCQUFpQkMsR0FBakIsQ0FBcUJILFlBQVlJLE1BQVosQ0FBbUJDLEtBQXhDLEVBQStDVixPQUEvQyxDQUFoQjtBQUNBLFlBQUlNLFdBQVcsSUFBZixFQUFxQixDQUFFLE9BQVM7O0FBRWhDLFlBQUlBLFFBQVFLLE1BQVIsQ0FBZUMsTUFBbkIsRUFBMkI7QUFDekJOLGtCQUFRTyxZQUFSLENBQXFCYixPQUFyQixFQUE4QkssV0FBOUI7QUFDQTtBQUNEOztBQUVELFlBQUlDLFFBQVFRLEdBQVIsQ0FBWSxTQUFaLEtBQTBCUixRQUFRUSxHQUFSLENBQVlYLGlCQUFpQkQsT0FBakIsRUFBMEJFLElBQXRDLENBQTlCLEVBQTJFOztBQUV6RUosa0JBQVFlLE1BQVI7QUFDRVosMEJBREY7QUFFMEJBLDJCQUFpQkQsT0FBakIsRUFBMEJFLElBRnBEOzs7QUFLRDtBQUNGO0FBQ0QsYUFBTztBQUNMWSxnQ0FBd0JmLGFBQWFnQixJQUFiLENBQWtCLElBQWxCLEVBQXdCLE9BQXhCLENBRG5CO0FBRUxDLGdDQUF3QmpCLGFBQWFnQixJQUFiLENBQWtCLElBQWxCLEVBQXdCLFVBQXhCLENBRm5CLEVBQVA7O0FBSUQsS0F2Q2MsbUJBQWpCIiwiZmlsZSI6Im5vLW5hbWVkLWFzLWRlZmF1bHQuanMiLCJzb3VyY2VzQ29udGVudCI6WyJpbXBvcnQgRXhwb3J0TWFwQnVpbGRlciBmcm9tICcuLi9leHBvcnRNYXAvYnVpbGRlcic7XG5pbXBvcnQgaW1wb3J0RGVjbGFyYXRpb24gZnJvbSAnLi4vaW1wb3J0RGVjbGFyYXRpb24nO1xuaW1wb3J0IGRvY3NVcmwgZnJvbSAnLi4vZG9jc1VybCc7XG5cbm1vZHVsZS5leHBvcnRzID0ge1xuICBtZXRhOiB7XG4gICAgdHlwZTogJ3Byb2JsZW0nLFxuICAgIGRvY3M6IHtcbiAgICAgIGNhdGVnb3J5OiAnSGVscGZ1bCB3YXJuaW5ncycsXG4gICAgICBkZXNjcmlwdGlvbjogJ0ZvcmJpZCB1c2Ugb2YgZXhwb3J0ZWQgbmFtZSBhcyBpZGVudGlmaWVyIG9mIGRlZmF1bHQgZXhwb3J0LicsXG4gICAgICB1cmw6IGRvY3NVcmwoJ25vLW5hbWVkLWFzLWRlZmF1bHQnKSxcbiAgICB9LFxuICAgIHNjaGVtYTogW10sXG4gIH0sXG5cbiAgY3JlYXRlKGNvbnRleHQpIHtcbiAgICBmdW5jdGlvbiBjaGVja0RlZmF1bHQobmFtZUtleSwgZGVmYXVsdFNwZWNpZmllcikge1xuICAgICAgLy8gIzU2NjogZGVmYXVsdCBpcyBhIHZhbGlkIHNwZWNpZmllclxuICAgICAgaWYgKGRlZmF1bHRTcGVjaWZpZXJbbmFtZUtleV0ubmFtZSA9PT0gJ2RlZmF1bHQnKSB7IHJldHVybjsgfVxuXG4gICAgICBjb25zdCBkZWNsYXJhdGlvbiA9IGltcG9ydERlY2xhcmF0aW9uKGNvbnRleHQpO1xuXG4gICAgICBjb25zdCBpbXBvcnRzID0gRXhwb3J0TWFwQnVpbGRlci5nZXQoZGVjbGFyYXRpb24uc291cmNlLnZhbHVlLCBjb250ZXh0KTtcbiAgICAgIGlmIChpbXBvcnRzID09IG51bGwpIHsgcmV0dXJuOyB9XG5cbiAgICAgIGlmIChpbXBvcnRzLmVycm9ycy5sZW5ndGgpIHtcbiAgICAgICAgaW1wb3J0cy5yZXBvcnRFcnJvcnMoY29udGV4dCwgZGVjbGFyYXRpb24pO1xuICAgICAgICByZXR1cm47XG4gICAgICB9XG5cbiAgICAgIGlmIChpbXBvcnRzLmhhcygnZGVmYXVsdCcpICYmIGltcG9ydHMuaGFzKGRlZmF1bHRTcGVjaWZpZXJbbmFtZUtleV0ubmFtZSkpIHtcblxuICAgICAgICBjb250ZXh0LnJlcG9ydChcbiAgICAgICAgICBkZWZhdWx0U3BlY2lmaWVyLFxuICAgICAgICAgIGBVc2luZyBleHBvcnRlZCBuYW1lICcke2RlZmF1bHRTcGVjaWZpZXJbbmFtZUtleV0ubmFtZX0nIGFzIGlkZW50aWZpZXIgZm9yIGRlZmF1bHQgZXhwb3J0LmAsXG4gICAgICAgICk7XG5cbiAgICAgIH1cbiAgICB9XG4gICAgcmV0dXJuIHtcbiAgICAgIEltcG9ydERlZmF1bHRTcGVjaWZpZXI6IGNoZWNrRGVmYXVsdC5iaW5kKG51bGwsICdsb2NhbCcpLFxuICAgICAgRXhwb3J0RGVmYXVsdFNwZWNpZmllcjogY2hlY2tEZWZhdWx0LmJpbmQobnVsbCwgJ2V4cG9ydGVkJyksXG4gICAgfTtcbiAgfSxcbn07XG4iXX0=