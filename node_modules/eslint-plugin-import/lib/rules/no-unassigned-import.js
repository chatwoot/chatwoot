'use strict';var _path = require('path');var _path2 = _interopRequireDefault(_path);
var _minimatch = require('minimatch');var _minimatch2 = _interopRequireDefault(_minimatch);

var _staticRequire = require('../core/staticRequire');var _staticRequire2 = _interopRequireDefault(_staticRequire);
var _docsUrl = require('../docsUrl');var _docsUrl2 = _interopRequireDefault(_docsUrl);function _interopRequireDefault(obj) {return obj && obj.__esModule ? obj : { default: obj };}

function report(context, node) {
  context.report({
    node,
    message: 'Imported module should be assigned' });

}

function testIsAllow(globs, filename, source) {
  if (!Array.isArray(globs)) {
    return false; // default doesn't allow any patterns
  }

  let filePath;

  if (source[0] !== '.' && source[0] !== '/') {// a node module
    filePath = source;
  } else {
    filePath = _path2.default.resolve(_path2.default.dirname(filename), source); // get source absolute path
  }

  return globs.find(glob =>
  (0, _minimatch2.default)(filePath, glob) ||
  (0, _minimatch2.default)(filePath, _path2.default.join(process.cwd(), glob))) !==
  undefined;
}

function create(context) {
  const options = context.options[0] || {};
  const filename = context.getFilename();
  const isAllow = source => testIsAllow(options.allow, filename, source);

  return {
    ImportDeclaration(node) {
      if (node.specifiers.length === 0 && !isAllow(node.source.value)) {
        report(context, node);
      }
    },
    ExpressionStatement(node) {
      if (node.expression.type === 'CallExpression' &&
      (0, _staticRequire2.default)(node.expression) &&
      !isAllow(node.expression.arguments[0].value)) {
        report(context, node.expression);
      }
    } };

}

module.exports = {
  create,
  meta: {
    type: 'suggestion',
    docs: {
      url: (0, _docsUrl2.default)('no-unassigned-import') },

    schema: [
    {
      'type': 'object',
      'properties': {
        'devDependencies': { 'type': ['boolean', 'array'] },
        'optionalDependencies': { 'type': ['boolean', 'array'] },
        'peerDependencies': { 'type': ['boolean', 'array'] },
        'allow': {
          'type': 'array',
          'items': {
            'type': 'string' } } },



      'additionalProperties': false }] } };
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIi4uLy4uL3NyYy9ydWxlcy9uby11bmFzc2lnbmVkLWltcG9ydC5qcyJdLCJuYW1lcyI6WyJyZXBvcnQiLCJjb250ZXh0Iiwibm9kZSIsIm1lc3NhZ2UiLCJ0ZXN0SXNBbGxvdyIsImdsb2JzIiwiZmlsZW5hbWUiLCJzb3VyY2UiLCJBcnJheSIsImlzQXJyYXkiLCJmaWxlUGF0aCIsInBhdGgiLCJyZXNvbHZlIiwiZGlybmFtZSIsImZpbmQiLCJnbG9iIiwiam9pbiIsInByb2Nlc3MiLCJjd2QiLCJ1bmRlZmluZWQiLCJjcmVhdGUiLCJvcHRpb25zIiwiZ2V0RmlsZW5hbWUiLCJpc0FsbG93IiwiYWxsb3ciLCJJbXBvcnREZWNsYXJhdGlvbiIsInNwZWNpZmllcnMiLCJsZW5ndGgiLCJ2YWx1ZSIsIkV4cHJlc3Npb25TdGF0ZW1lbnQiLCJleHByZXNzaW9uIiwidHlwZSIsImFyZ3VtZW50cyIsIm1vZHVsZSIsImV4cG9ydHMiLCJtZXRhIiwiZG9jcyIsInVybCIsInNjaGVtYSJdLCJtYXBwaW5ncyI6ImFBQUEsNEI7QUFDQSxzQzs7QUFFQSxzRDtBQUNBLHFDOztBQUVBLFNBQVNBLE1BQVQsQ0FBZ0JDLE9BQWhCLEVBQXlCQyxJQUF6QixFQUErQjtBQUM3QkQsVUFBUUQsTUFBUixDQUFlO0FBQ2JFLFFBRGE7QUFFYkMsYUFBUyxvQ0FGSSxFQUFmOztBQUlEOztBQUVELFNBQVNDLFdBQVQsQ0FBcUJDLEtBQXJCLEVBQTRCQyxRQUE1QixFQUFzQ0MsTUFBdEMsRUFBOEM7QUFDNUMsTUFBSSxDQUFDQyxNQUFNQyxPQUFOLENBQWNKLEtBQWQsQ0FBTCxFQUEyQjtBQUN6QixXQUFPLEtBQVAsQ0FEeUIsQ0FDWjtBQUNkOztBQUVELE1BQUlLLFFBQUo7O0FBRUEsTUFBSUgsT0FBTyxDQUFQLE1BQWMsR0FBZCxJQUFxQkEsT0FBTyxDQUFQLE1BQWMsR0FBdkMsRUFBNEMsQ0FBRTtBQUM1Q0csZUFBV0gsTUFBWDtBQUNELEdBRkQsTUFFTztBQUNMRyxlQUFXQyxlQUFLQyxPQUFMLENBQWFELGVBQUtFLE9BQUwsQ0FBYVAsUUFBYixDQUFiLEVBQXFDQyxNQUFyQyxDQUFYLENBREssQ0FDbUQ7QUFDekQ7O0FBRUQsU0FBT0YsTUFBTVMsSUFBTixDQUFXQztBQUNoQiwyQkFBVUwsUUFBVixFQUFvQkssSUFBcEI7QUFDQSwyQkFBVUwsUUFBVixFQUFvQkMsZUFBS0ssSUFBTCxDQUFVQyxRQUFRQyxHQUFSLEVBQVYsRUFBeUJILElBQXpCLENBQXBCLENBRks7QUFHQUksV0FIUDtBQUlEOztBQUVELFNBQVNDLE1BQVQsQ0FBZ0JuQixPQUFoQixFQUF5QjtBQUN2QixRQUFNb0IsVUFBVXBCLFFBQVFvQixPQUFSLENBQWdCLENBQWhCLEtBQXNCLEVBQXRDO0FBQ0EsUUFBTWYsV0FBV0wsUUFBUXFCLFdBQVIsRUFBakI7QUFDQSxRQUFNQyxVQUFVaEIsVUFBVUgsWUFBWWlCLFFBQVFHLEtBQXBCLEVBQTJCbEIsUUFBM0IsRUFBcUNDLE1BQXJDLENBQTFCOztBQUVBLFNBQU87QUFDTGtCLHNCQUFrQnZCLElBQWxCLEVBQXdCO0FBQ3RCLFVBQUlBLEtBQUt3QixVQUFMLENBQWdCQyxNQUFoQixLQUEyQixDQUEzQixJQUFnQyxDQUFDSixRQUFRckIsS0FBS0ssTUFBTCxDQUFZcUIsS0FBcEIsQ0FBckMsRUFBaUU7QUFDL0Q1QixlQUFPQyxPQUFQLEVBQWdCQyxJQUFoQjtBQUNEO0FBQ0YsS0FMSTtBQU1MMkIsd0JBQW9CM0IsSUFBcEIsRUFBMEI7QUFDeEIsVUFBSUEsS0FBSzRCLFVBQUwsQ0FBZ0JDLElBQWhCLEtBQXlCLGdCQUF6QjtBQUNGLG1DQUFnQjdCLEtBQUs0QixVQUFyQixDQURFO0FBRUYsT0FBQ1AsUUFBUXJCLEtBQUs0QixVQUFMLENBQWdCRSxTQUFoQixDQUEwQixDQUExQixFQUE2QkosS0FBckMsQ0FGSCxFQUVnRDtBQUM5QzVCLGVBQU9DLE9BQVAsRUFBZ0JDLEtBQUs0QixVQUFyQjtBQUNEO0FBQ0YsS0FaSSxFQUFQOztBQWNEOztBQUVERyxPQUFPQyxPQUFQLEdBQWlCO0FBQ2ZkLFFBRGU7QUFFZmUsUUFBTTtBQUNKSixVQUFNLFlBREY7QUFFSkssVUFBTTtBQUNKQyxXQUFLLHVCQUFRLHNCQUFSLENBREQsRUFGRjs7QUFLSkMsWUFBUTtBQUNOO0FBQ0UsY0FBUSxRQURWO0FBRUUsb0JBQWM7QUFDWiwyQkFBbUIsRUFBRSxRQUFRLENBQUMsU0FBRCxFQUFZLE9BQVosQ0FBVixFQURQO0FBRVosZ0NBQXdCLEVBQUUsUUFBUSxDQUFDLFNBQUQsRUFBWSxPQUFaLENBQVYsRUFGWjtBQUdaLDRCQUFvQixFQUFFLFFBQVEsQ0FBQyxTQUFELEVBQVksT0FBWixDQUFWLEVBSFI7QUFJWixpQkFBUztBQUNQLGtCQUFRLE9BREQ7QUFFUCxtQkFBUztBQUNQLG9CQUFRLFFBREQsRUFGRixFQUpHLEVBRmhCOzs7O0FBYUUsOEJBQXdCLEtBYjFCLEVBRE0sQ0FMSixFQUZTLEVBQWpCIiwiZmlsZSI6Im5vLXVuYXNzaWduZWQtaW1wb3J0LmpzIiwic291cmNlc0NvbnRlbnQiOlsiaW1wb3J0IHBhdGggZnJvbSAncGF0aCdcbmltcG9ydCBtaW5pbWF0Y2ggZnJvbSAnbWluaW1hdGNoJ1xuXG5pbXBvcnQgaXNTdGF0aWNSZXF1aXJlIGZyb20gJy4uL2NvcmUvc3RhdGljUmVxdWlyZSdcbmltcG9ydCBkb2NzVXJsIGZyb20gJy4uL2RvY3NVcmwnXG5cbmZ1bmN0aW9uIHJlcG9ydChjb250ZXh0LCBub2RlKSB7XG4gIGNvbnRleHQucmVwb3J0KHtcbiAgICBub2RlLFxuICAgIG1lc3NhZ2U6ICdJbXBvcnRlZCBtb2R1bGUgc2hvdWxkIGJlIGFzc2lnbmVkJyxcbiAgfSlcbn1cblxuZnVuY3Rpb24gdGVzdElzQWxsb3coZ2xvYnMsIGZpbGVuYW1lLCBzb3VyY2UpIHtcbiAgaWYgKCFBcnJheS5pc0FycmF5KGdsb2JzKSkge1xuICAgIHJldHVybiBmYWxzZSAvLyBkZWZhdWx0IGRvZXNuJ3QgYWxsb3cgYW55IHBhdHRlcm5zXG4gIH1cblxuICBsZXQgZmlsZVBhdGhcblxuICBpZiAoc291cmNlWzBdICE9PSAnLicgJiYgc291cmNlWzBdICE9PSAnLycpIHsgLy8gYSBub2RlIG1vZHVsZVxuICAgIGZpbGVQYXRoID0gc291cmNlXG4gIH0gZWxzZSB7XG4gICAgZmlsZVBhdGggPSBwYXRoLnJlc29sdmUocGF0aC5kaXJuYW1lKGZpbGVuYW1lKSwgc291cmNlKSAvLyBnZXQgc291cmNlIGFic29sdXRlIHBhdGhcbiAgfVxuXG4gIHJldHVybiBnbG9icy5maW5kKGdsb2IgPT4gKFxuICAgIG1pbmltYXRjaChmaWxlUGF0aCwgZ2xvYikgfHxcbiAgICBtaW5pbWF0Y2goZmlsZVBhdGgsIHBhdGguam9pbihwcm9jZXNzLmN3ZCgpLCBnbG9iKSlcbiAgKSkgIT09IHVuZGVmaW5lZFxufVxuXG5mdW5jdGlvbiBjcmVhdGUoY29udGV4dCkge1xuICBjb25zdCBvcHRpb25zID0gY29udGV4dC5vcHRpb25zWzBdIHx8IHt9XG4gIGNvbnN0IGZpbGVuYW1lID0gY29udGV4dC5nZXRGaWxlbmFtZSgpXG4gIGNvbnN0IGlzQWxsb3cgPSBzb3VyY2UgPT4gdGVzdElzQWxsb3cob3B0aW9ucy5hbGxvdywgZmlsZW5hbWUsIHNvdXJjZSlcblxuICByZXR1cm4ge1xuICAgIEltcG9ydERlY2xhcmF0aW9uKG5vZGUpIHtcbiAgICAgIGlmIChub2RlLnNwZWNpZmllcnMubGVuZ3RoID09PSAwICYmICFpc0FsbG93KG5vZGUuc291cmNlLnZhbHVlKSkge1xuICAgICAgICByZXBvcnQoY29udGV4dCwgbm9kZSlcbiAgICAgIH1cbiAgICB9LFxuICAgIEV4cHJlc3Npb25TdGF0ZW1lbnQobm9kZSkge1xuICAgICAgaWYgKG5vZGUuZXhwcmVzc2lvbi50eXBlID09PSAnQ2FsbEV4cHJlc3Npb24nICYmXG4gICAgICAgIGlzU3RhdGljUmVxdWlyZShub2RlLmV4cHJlc3Npb24pICYmXG4gICAgICAgICFpc0FsbG93KG5vZGUuZXhwcmVzc2lvbi5hcmd1bWVudHNbMF0udmFsdWUpKSB7XG4gICAgICAgIHJlcG9ydChjb250ZXh0LCBub2RlLmV4cHJlc3Npb24pXG4gICAgICB9XG4gICAgfSxcbiAgfVxufVxuXG5tb2R1bGUuZXhwb3J0cyA9IHtcbiAgY3JlYXRlLFxuICBtZXRhOiB7XG4gICAgdHlwZTogJ3N1Z2dlc3Rpb24nLFxuICAgIGRvY3M6IHtcbiAgICAgIHVybDogZG9jc1VybCgnbm8tdW5hc3NpZ25lZC1pbXBvcnQnKSxcbiAgICB9LFxuICAgIHNjaGVtYTogW1xuICAgICAge1xuICAgICAgICAndHlwZSc6ICdvYmplY3QnLFxuICAgICAgICAncHJvcGVydGllcyc6IHtcbiAgICAgICAgICAnZGV2RGVwZW5kZW5jaWVzJzogeyAndHlwZSc6IFsnYm9vbGVhbicsICdhcnJheSddIH0sXG4gICAgICAgICAgJ29wdGlvbmFsRGVwZW5kZW5jaWVzJzogeyAndHlwZSc6IFsnYm9vbGVhbicsICdhcnJheSddIH0sXG4gICAgICAgICAgJ3BlZXJEZXBlbmRlbmNpZXMnOiB7ICd0eXBlJzogWydib29sZWFuJywgJ2FycmF5J10gfSxcbiAgICAgICAgICAnYWxsb3cnOiB7XG4gICAgICAgICAgICAndHlwZSc6ICdhcnJheScsXG4gICAgICAgICAgICAnaXRlbXMnOiB7XG4gICAgICAgICAgICAgICd0eXBlJzogJ3N0cmluZycsXG4gICAgICAgICAgICB9LFxuICAgICAgICAgIH0sXG4gICAgICAgIH0sXG4gICAgICAgICdhZGRpdGlvbmFsUHJvcGVydGllcyc6IGZhbHNlLFxuICAgICAgfSxcbiAgICBdLFxuICB9LFxufVxuIl19