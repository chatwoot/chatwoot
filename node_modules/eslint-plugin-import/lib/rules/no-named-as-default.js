'use strict';var _ExportMap = require('../ExportMap');var _ExportMap2 = _interopRequireDefault(_ExportMap);
var _importDeclaration = require('../importDeclaration');var _importDeclaration2 = _interopRequireDefault(_importDeclaration);
var _docsUrl = require('../docsUrl');var _docsUrl2 = _interopRequireDefault(_docsUrl);function _interopRequireDefault(obj) {return obj && obj.__esModule ? obj : { default: obj };}

module.exports = {
  meta: {
    type: 'problem',
    docs: {
      url: (0, _docsUrl2.default)('no-named-as-default') },

    schema: [] },


  create: function (context) {
    function checkDefault(nameKey, defaultSpecifier) {
      // #566: default is a valid specifier
      if (defaultSpecifier[nameKey].name === 'default') return;

      var declaration = (0, _importDeclaration2.default)(context);

      var imports = _ExportMap2.default.get(declaration.source.value, context);
      if (imports == null) return;

      if (imports.errors.length) {
        imports.reportErrors(context, declaration);
        return;
      }

      if (imports.has('default') &&
      imports.has(defaultSpecifier[nameKey].name)) {

        context.report(defaultSpecifier,
        'Using exported name \'' + defaultSpecifier[nameKey].name +
        '\' as identifier for default export.');

      }
    }
    return {
      'ImportDefaultSpecifier': checkDefault.bind(null, 'local'),
      'ExportDefaultSpecifier': checkDefault.bind(null, 'exported') };

  } };
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIi4uLy4uL3NyYy9ydWxlcy9uby1uYW1lZC1hcy1kZWZhdWx0LmpzIl0sIm5hbWVzIjpbIm1vZHVsZSIsImV4cG9ydHMiLCJtZXRhIiwidHlwZSIsImRvY3MiLCJ1cmwiLCJzY2hlbWEiLCJjcmVhdGUiLCJjb250ZXh0IiwiY2hlY2tEZWZhdWx0IiwibmFtZUtleSIsImRlZmF1bHRTcGVjaWZpZXIiLCJuYW1lIiwiZGVjbGFyYXRpb24iLCJpbXBvcnRzIiwiRXhwb3J0cyIsImdldCIsInNvdXJjZSIsInZhbHVlIiwiZXJyb3JzIiwibGVuZ3RoIiwicmVwb3J0RXJyb3JzIiwiaGFzIiwicmVwb3J0IiwiYmluZCJdLCJtYXBwaW5ncyI6ImFBQUEseUM7QUFDQSx5RDtBQUNBLHFDOztBQUVBQSxPQUFPQyxPQUFQLEdBQWlCO0FBQ2ZDLFFBQU07QUFDSkMsVUFBTSxTQURGO0FBRUpDLFVBQU07QUFDSkMsV0FBSyx1QkFBUSxxQkFBUixDQURELEVBRkY7O0FBS0pDLFlBQVEsRUFMSixFQURTOzs7QUFTZkMsVUFBUSxVQUFVQyxPQUFWLEVBQW1CO0FBQ3pCLGFBQVNDLFlBQVQsQ0FBc0JDLE9BQXRCLEVBQStCQyxnQkFBL0IsRUFBaUQ7QUFDL0M7QUFDQSxVQUFJQSxpQkFBaUJELE9BQWpCLEVBQTBCRSxJQUExQixLQUFtQyxTQUF2QyxFQUFrRDs7QUFFbEQsVUFBSUMsY0FBYyxpQ0FBa0JMLE9BQWxCLENBQWxCOztBQUVBLFVBQUlNLFVBQVVDLG9CQUFRQyxHQUFSLENBQVlILFlBQVlJLE1BQVosQ0FBbUJDLEtBQS9CLEVBQXNDVixPQUF0QyxDQUFkO0FBQ0EsVUFBSU0sV0FBVyxJQUFmLEVBQXFCOztBQUVyQixVQUFJQSxRQUFRSyxNQUFSLENBQWVDLE1BQW5CLEVBQTJCO0FBQ3pCTixnQkFBUU8sWUFBUixDQUFxQmIsT0FBckIsRUFBOEJLLFdBQTlCO0FBQ0E7QUFDRDs7QUFFRCxVQUFJQyxRQUFRUSxHQUFSLENBQVksU0FBWjtBQUNBUixjQUFRUSxHQUFSLENBQVlYLGlCQUFpQkQsT0FBakIsRUFBMEJFLElBQXRDLENBREosRUFDaUQ7O0FBRS9DSixnQkFBUWUsTUFBUixDQUFlWixnQkFBZjtBQUNFLG1DQUEyQkEsaUJBQWlCRCxPQUFqQixFQUEwQkUsSUFBckQ7QUFDQSw4Q0FGRjs7QUFJRDtBQUNGO0FBQ0QsV0FBTztBQUNMLGdDQUEwQkgsYUFBYWUsSUFBYixDQUFrQixJQUFsQixFQUF3QixPQUF4QixDQURyQjtBQUVMLGdDQUEwQmYsYUFBYWUsSUFBYixDQUFrQixJQUFsQixFQUF3QixVQUF4QixDQUZyQixFQUFQOztBQUlELEdBckNjLEVBQWpCIiwiZmlsZSI6Im5vLW5hbWVkLWFzLWRlZmF1bHQuanMiLCJzb3VyY2VzQ29udGVudCI6WyJpbXBvcnQgRXhwb3J0cyBmcm9tICcuLi9FeHBvcnRNYXAnXG5pbXBvcnQgaW1wb3J0RGVjbGFyYXRpb24gZnJvbSAnLi4vaW1wb3J0RGVjbGFyYXRpb24nXG5pbXBvcnQgZG9jc1VybCBmcm9tICcuLi9kb2NzVXJsJ1xuXG5tb2R1bGUuZXhwb3J0cyA9IHtcbiAgbWV0YToge1xuICAgIHR5cGU6ICdwcm9ibGVtJyxcbiAgICBkb2NzOiB7XG4gICAgICB1cmw6IGRvY3NVcmwoJ25vLW5hbWVkLWFzLWRlZmF1bHQnKSxcbiAgICB9LFxuICAgIHNjaGVtYTogW10sXG4gIH0sXG5cbiAgY3JlYXRlOiBmdW5jdGlvbiAoY29udGV4dCkge1xuICAgIGZ1bmN0aW9uIGNoZWNrRGVmYXVsdChuYW1lS2V5LCBkZWZhdWx0U3BlY2lmaWVyKSB7XG4gICAgICAvLyAjNTY2OiBkZWZhdWx0IGlzIGEgdmFsaWQgc3BlY2lmaWVyXG4gICAgICBpZiAoZGVmYXVsdFNwZWNpZmllcltuYW1lS2V5XS5uYW1lID09PSAnZGVmYXVsdCcpIHJldHVyblxuXG4gICAgICB2YXIgZGVjbGFyYXRpb24gPSBpbXBvcnREZWNsYXJhdGlvbihjb250ZXh0KVxuXG4gICAgICB2YXIgaW1wb3J0cyA9IEV4cG9ydHMuZ2V0KGRlY2xhcmF0aW9uLnNvdXJjZS52YWx1ZSwgY29udGV4dClcbiAgICAgIGlmIChpbXBvcnRzID09IG51bGwpIHJldHVyblxuXG4gICAgICBpZiAoaW1wb3J0cy5lcnJvcnMubGVuZ3RoKSB7XG4gICAgICAgIGltcG9ydHMucmVwb3J0RXJyb3JzKGNvbnRleHQsIGRlY2xhcmF0aW9uKVxuICAgICAgICByZXR1cm5cbiAgICAgIH1cblxuICAgICAgaWYgKGltcG9ydHMuaGFzKCdkZWZhdWx0JykgJiZcbiAgICAgICAgICBpbXBvcnRzLmhhcyhkZWZhdWx0U3BlY2lmaWVyW25hbWVLZXldLm5hbWUpKSB7XG5cbiAgICAgICAgY29udGV4dC5yZXBvcnQoZGVmYXVsdFNwZWNpZmllcixcbiAgICAgICAgICAnVXNpbmcgZXhwb3J0ZWQgbmFtZSBcXCcnICsgZGVmYXVsdFNwZWNpZmllcltuYW1lS2V5XS5uYW1lICtcbiAgICAgICAgICAnXFwnIGFzIGlkZW50aWZpZXIgZm9yIGRlZmF1bHQgZXhwb3J0LicpXG5cbiAgICAgIH1cbiAgICB9XG4gICAgcmV0dXJuIHtcbiAgICAgICdJbXBvcnREZWZhdWx0U3BlY2lmaWVyJzogY2hlY2tEZWZhdWx0LmJpbmQobnVsbCwgJ2xvY2FsJyksXG4gICAgICAnRXhwb3J0RGVmYXVsdFNwZWNpZmllcic6IGNoZWNrRGVmYXVsdC5iaW5kKG51bGwsICdleHBvcnRlZCcpLFxuICAgIH1cbiAgfSxcbn1cbiJdfQ==