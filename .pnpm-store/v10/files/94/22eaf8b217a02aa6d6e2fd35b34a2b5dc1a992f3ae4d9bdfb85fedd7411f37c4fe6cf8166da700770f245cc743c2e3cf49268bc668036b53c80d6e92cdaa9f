'use strict';var _path = require('path');var _path2 = _interopRequireDefault(_path);
var _minimatch = require('minimatch');var _minimatch2 = _interopRequireDefault(_minimatch);

var _staticRequire = require('../core/staticRequire');var _staticRequire2 = _interopRequireDefault(_staticRequire);
var _docsUrl = require('../docsUrl');var _docsUrl2 = _interopRequireDefault(_docsUrl);function _interopRequireDefault(obj) {return obj && obj.__esModule ? obj : { 'default': obj };}

function report(context, node) {
  context.report({
    node: node,
    message: 'Imported module should be assigned' });

}

function testIsAllow(globs, filename, source) {
  if (!Array.isArray(globs)) {
    return false; // default doesn't allow any patterns
  }

  var filePath = void 0;

  if (source[0] !== '.' && source[0] !== '/') {// a node module
    filePath = source;
  } else {
    filePath = _path2['default'].resolve(_path2['default'].dirname(filename), source); // get source absolute path
  }

  return globs.find(function (glob) {return (0, _minimatch2['default'])(filePath, glob) ||
    (0, _minimatch2['default'])(filePath, _path2['default'].join(process.cwd(), glob));}) !==
  undefined;
}

function create(context) {
  var options = context.options[0] || {};
  var filename = context.getPhysicalFilename ? context.getPhysicalFilename() : context.getFilename();
  var isAllow = function isAllow(source) {return testIsAllow(options.allow, filename, source);};

  return {
    ImportDeclaration: function () {function ImportDeclaration(node) {
        if (node.specifiers.length === 0 && !isAllow(node.source.value)) {
          report(context, node);
        }
      }return ImportDeclaration;}(),
    ExpressionStatement: function () {function ExpressionStatement(node) {
        if (
        node.expression.type === 'CallExpression' &&
        (0, _staticRequire2['default'])(node.expression) &&
        !isAllow(node.expression.arguments[0].value))
        {
          report(context, node.expression);
        }
      }return ExpressionStatement;}() };

}

module.exports = {
  create: create,
  meta: {
    type: 'suggestion',
    docs: {
      category: 'Style guide',
      description: 'Forbid unassigned imports',
      url: (0, _docsUrl2['default'])('no-unassigned-import') },

    schema: [
    {
      type: 'object',
      properties: {
        devDependencies: { type: ['boolean', 'array'] },
        optionalDependencies: { type: ['boolean', 'array'] },
        peerDependencies: { type: ['boolean', 'array'] },
        allow: {
          type: 'array',
          items: {
            type: 'string' } } },



      additionalProperties: false }] } };
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIi4uLy4uL3NyYy9ydWxlcy9uby11bmFzc2lnbmVkLWltcG9ydC5qcyJdLCJuYW1lcyI6WyJyZXBvcnQiLCJjb250ZXh0Iiwibm9kZSIsIm1lc3NhZ2UiLCJ0ZXN0SXNBbGxvdyIsImdsb2JzIiwiZmlsZW5hbWUiLCJzb3VyY2UiLCJBcnJheSIsImlzQXJyYXkiLCJmaWxlUGF0aCIsInBhdGgiLCJyZXNvbHZlIiwiZGlybmFtZSIsImZpbmQiLCJnbG9iIiwiam9pbiIsInByb2Nlc3MiLCJjd2QiLCJ1bmRlZmluZWQiLCJjcmVhdGUiLCJvcHRpb25zIiwiZ2V0UGh5c2ljYWxGaWxlbmFtZSIsImdldEZpbGVuYW1lIiwiaXNBbGxvdyIsImFsbG93IiwiSW1wb3J0RGVjbGFyYXRpb24iLCJzcGVjaWZpZXJzIiwibGVuZ3RoIiwidmFsdWUiLCJFeHByZXNzaW9uU3RhdGVtZW50IiwiZXhwcmVzc2lvbiIsInR5cGUiLCJhcmd1bWVudHMiLCJtb2R1bGUiLCJleHBvcnRzIiwibWV0YSIsImRvY3MiLCJjYXRlZ29yeSIsImRlc2NyaXB0aW9uIiwidXJsIiwic2NoZW1hIiwicHJvcGVydGllcyIsImRldkRlcGVuZGVuY2llcyIsIm9wdGlvbmFsRGVwZW5kZW5jaWVzIiwicGVlckRlcGVuZGVuY2llcyIsIml0ZW1zIiwiYWRkaXRpb25hbFByb3BlcnRpZXMiXSwibWFwcGluZ3MiOiJhQUFBLDRCO0FBQ0Esc0M7O0FBRUEsc0Q7QUFDQSxxQzs7QUFFQSxTQUFTQSxNQUFULENBQWdCQyxPQUFoQixFQUF5QkMsSUFBekIsRUFBK0I7QUFDN0JELFVBQVFELE1BQVIsQ0FBZTtBQUNiRSxjQURhO0FBRWJDLGFBQVMsb0NBRkksRUFBZjs7QUFJRDs7QUFFRCxTQUFTQyxXQUFULENBQXFCQyxLQUFyQixFQUE0QkMsUUFBNUIsRUFBc0NDLE1BQXRDLEVBQThDO0FBQzVDLE1BQUksQ0FBQ0MsTUFBTUMsT0FBTixDQUFjSixLQUFkLENBQUwsRUFBMkI7QUFDekIsV0FBTyxLQUFQLENBRHlCLENBQ1g7QUFDZjs7QUFFRCxNQUFJSyxpQkFBSjs7QUFFQSxNQUFJSCxPQUFPLENBQVAsTUFBYyxHQUFkLElBQXFCQSxPQUFPLENBQVAsTUFBYyxHQUF2QyxFQUE0QyxDQUFFO0FBQzVDRyxlQUFXSCxNQUFYO0FBQ0QsR0FGRCxNQUVPO0FBQ0xHLGVBQVdDLGtCQUFLQyxPQUFMLENBQWFELGtCQUFLRSxPQUFMLENBQWFQLFFBQWIsQ0FBYixFQUFxQ0MsTUFBckMsQ0FBWCxDQURLLENBQ29EO0FBQzFEOztBQUVELFNBQU9GLE1BQU1TLElBQU4sQ0FBVyxVQUFDQyxJQUFELFVBQVUsNEJBQVVMLFFBQVYsRUFBb0JLLElBQXBCO0FBQ3ZCLGdDQUFVTCxRQUFWLEVBQW9CQyxrQkFBS0ssSUFBTCxDQUFVQyxRQUFRQyxHQUFSLEVBQVYsRUFBeUJILElBQXpCLENBQXBCLENBRGEsRUFBWDtBQUVESSxXQUZOO0FBR0Q7O0FBRUQsU0FBU0MsTUFBVCxDQUFnQm5CLE9BQWhCLEVBQXlCO0FBQ3ZCLE1BQU1vQixVQUFVcEIsUUFBUW9CLE9BQVIsQ0FBZ0IsQ0FBaEIsS0FBc0IsRUFBdEM7QUFDQSxNQUFNZixXQUFXTCxRQUFRcUIsbUJBQVIsR0FBOEJyQixRQUFRcUIsbUJBQVIsRUFBOUIsR0FBOERyQixRQUFRc0IsV0FBUixFQUEvRTtBQUNBLE1BQU1DLFVBQVUsU0FBVkEsT0FBVSxDQUFDakIsTUFBRCxVQUFZSCxZQUFZaUIsUUFBUUksS0FBcEIsRUFBMkJuQixRQUEzQixFQUFxQ0MsTUFBckMsQ0FBWixFQUFoQjs7QUFFQSxTQUFPO0FBQ0xtQixxQkFESywwQ0FDYXhCLElBRGIsRUFDbUI7QUFDdEIsWUFBSUEsS0FBS3lCLFVBQUwsQ0FBZ0JDLE1BQWhCLEtBQTJCLENBQTNCLElBQWdDLENBQUNKLFFBQVF0QixLQUFLSyxNQUFMLENBQVlzQixLQUFwQixDQUFyQyxFQUFpRTtBQUMvRDdCLGlCQUFPQyxPQUFQLEVBQWdCQyxJQUFoQjtBQUNEO0FBQ0YsT0FMSTtBQU1MNEIsdUJBTkssNENBTWU1QixJQU5mLEVBTXFCO0FBQ3hCO0FBQ0VBLGFBQUs2QixVQUFMLENBQWdCQyxJQUFoQixLQUF5QixnQkFBekI7QUFDRyx3Q0FBZ0I5QixLQUFLNkIsVUFBckIsQ0FESDtBQUVHLFNBQUNQLFFBQVF0QixLQUFLNkIsVUFBTCxDQUFnQkUsU0FBaEIsQ0FBMEIsQ0FBMUIsRUFBNkJKLEtBQXJDLENBSE47QUFJRTtBQUNBN0IsaUJBQU9DLE9BQVAsRUFBZ0JDLEtBQUs2QixVQUFyQjtBQUNEO0FBQ0YsT0FkSSxnQ0FBUDs7QUFnQkQ7O0FBRURHLE9BQU9DLE9BQVAsR0FBaUI7QUFDZmYsZ0JBRGU7QUFFZmdCLFFBQU07QUFDSkosVUFBTSxZQURGO0FBRUpLLFVBQU07QUFDSkMsZ0JBQVUsYUFETjtBQUVKQyxtQkFBYSwyQkFGVDtBQUdKQyxXQUFLLDBCQUFRLHNCQUFSLENBSEQsRUFGRjs7QUFPSkMsWUFBUTtBQUNOO0FBQ0VULFlBQU0sUUFEUjtBQUVFVSxrQkFBWTtBQUNWQyx5QkFBaUIsRUFBRVgsTUFBTSxDQUFDLFNBQUQsRUFBWSxPQUFaLENBQVIsRUFEUDtBQUVWWSw4QkFBc0IsRUFBRVosTUFBTSxDQUFDLFNBQUQsRUFBWSxPQUFaLENBQVIsRUFGWjtBQUdWYSwwQkFBa0IsRUFBRWIsTUFBTSxDQUFDLFNBQUQsRUFBWSxPQUFaLENBQVIsRUFIUjtBQUlWUCxlQUFPO0FBQ0xPLGdCQUFNLE9BREQ7QUFFTGMsaUJBQU87QUFDTGQsa0JBQU0sUUFERCxFQUZGLEVBSkcsRUFGZDs7OztBQWFFZSw0QkFBc0IsS0FieEIsRUFETSxDQVBKLEVBRlMsRUFBakIiLCJmaWxlIjoibm8tdW5hc3NpZ25lZC1pbXBvcnQuanMiLCJzb3VyY2VzQ29udGVudCI6WyJpbXBvcnQgcGF0aCBmcm9tICdwYXRoJztcbmltcG9ydCBtaW5pbWF0Y2ggZnJvbSAnbWluaW1hdGNoJztcblxuaW1wb3J0IGlzU3RhdGljUmVxdWlyZSBmcm9tICcuLi9jb3JlL3N0YXRpY1JlcXVpcmUnO1xuaW1wb3J0IGRvY3NVcmwgZnJvbSAnLi4vZG9jc1VybCc7XG5cbmZ1bmN0aW9uIHJlcG9ydChjb250ZXh0LCBub2RlKSB7XG4gIGNvbnRleHQucmVwb3J0KHtcbiAgICBub2RlLFxuICAgIG1lc3NhZ2U6ICdJbXBvcnRlZCBtb2R1bGUgc2hvdWxkIGJlIGFzc2lnbmVkJyxcbiAgfSk7XG59XG5cbmZ1bmN0aW9uIHRlc3RJc0FsbG93KGdsb2JzLCBmaWxlbmFtZSwgc291cmNlKSB7XG4gIGlmICghQXJyYXkuaXNBcnJheShnbG9icykpIHtcbiAgICByZXR1cm4gZmFsc2U7IC8vIGRlZmF1bHQgZG9lc24ndCBhbGxvdyBhbnkgcGF0dGVybnNcbiAgfVxuXG4gIGxldCBmaWxlUGF0aDtcblxuICBpZiAoc291cmNlWzBdICE9PSAnLicgJiYgc291cmNlWzBdICE9PSAnLycpIHsgLy8gYSBub2RlIG1vZHVsZVxuICAgIGZpbGVQYXRoID0gc291cmNlO1xuICB9IGVsc2Uge1xuICAgIGZpbGVQYXRoID0gcGF0aC5yZXNvbHZlKHBhdGguZGlybmFtZShmaWxlbmFtZSksIHNvdXJjZSk7IC8vIGdldCBzb3VyY2UgYWJzb2x1dGUgcGF0aFxuICB9XG5cbiAgcmV0dXJuIGdsb2JzLmZpbmQoKGdsb2IpID0+IG1pbmltYXRjaChmaWxlUGF0aCwgZ2xvYilcbiAgICB8fCBtaW5pbWF0Y2goZmlsZVBhdGgsIHBhdGguam9pbihwcm9jZXNzLmN3ZCgpLCBnbG9iKSksXG4gICkgIT09IHVuZGVmaW5lZDtcbn1cblxuZnVuY3Rpb24gY3JlYXRlKGNvbnRleHQpIHtcbiAgY29uc3Qgb3B0aW9ucyA9IGNvbnRleHQub3B0aW9uc1swXSB8fCB7fTtcbiAgY29uc3QgZmlsZW5hbWUgPSBjb250ZXh0LmdldFBoeXNpY2FsRmlsZW5hbWUgPyBjb250ZXh0LmdldFBoeXNpY2FsRmlsZW5hbWUoKSA6IGNvbnRleHQuZ2V0RmlsZW5hbWUoKTtcbiAgY29uc3QgaXNBbGxvdyA9IChzb3VyY2UpID0+IHRlc3RJc0FsbG93KG9wdGlvbnMuYWxsb3csIGZpbGVuYW1lLCBzb3VyY2UpO1xuXG4gIHJldHVybiB7XG4gICAgSW1wb3J0RGVjbGFyYXRpb24obm9kZSkge1xuICAgICAgaWYgKG5vZGUuc3BlY2lmaWVycy5sZW5ndGggPT09IDAgJiYgIWlzQWxsb3cobm9kZS5zb3VyY2UudmFsdWUpKSB7XG4gICAgICAgIHJlcG9ydChjb250ZXh0LCBub2RlKTtcbiAgICAgIH1cbiAgICB9LFxuICAgIEV4cHJlc3Npb25TdGF0ZW1lbnQobm9kZSkge1xuICAgICAgaWYgKFxuICAgICAgICBub2RlLmV4cHJlc3Npb24udHlwZSA9PT0gJ0NhbGxFeHByZXNzaW9uJ1xuICAgICAgICAmJiBpc1N0YXRpY1JlcXVpcmUobm9kZS5leHByZXNzaW9uKVxuICAgICAgICAmJiAhaXNBbGxvdyhub2RlLmV4cHJlc3Npb24uYXJndW1lbnRzWzBdLnZhbHVlKVxuICAgICAgKSB7XG4gICAgICAgIHJlcG9ydChjb250ZXh0LCBub2RlLmV4cHJlc3Npb24pO1xuICAgICAgfVxuICAgIH0sXG4gIH07XG59XG5cbm1vZHVsZS5leHBvcnRzID0ge1xuICBjcmVhdGUsXG4gIG1ldGE6IHtcbiAgICB0eXBlOiAnc3VnZ2VzdGlvbicsXG4gICAgZG9jczoge1xuICAgICAgY2F0ZWdvcnk6ICdTdHlsZSBndWlkZScsXG4gICAgICBkZXNjcmlwdGlvbjogJ0ZvcmJpZCB1bmFzc2lnbmVkIGltcG9ydHMnLFxuICAgICAgdXJsOiBkb2NzVXJsKCduby11bmFzc2lnbmVkLWltcG9ydCcpLFxuICAgIH0sXG4gICAgc2NoZW1hOiBbXG4gICAgICB7XG4gICAgICAgIHR5cGU6ICdvYmplY3QnLFxuICAgICAgICBwcm9wZXJ0aWVzOiB7XG4gICAgICAgICAgZGV2RGVwZW5kZW5jaWVzOiB7IHR5cGU6IFsnYm9vbGVhbicsICdhcnJheSddIH0sXG4gICAgICAgICAgb3B0aW9uYWxEZXBlbmRlbmNpZXM6IHsgdHlwZTogWydib29sZWFuJywgJ2FycmF5J10gfSxcbiAgICAgICAgICBwZWVyRGVwZW5kZW5jaWVzOiB7IHR5cGU6IFsnYm9vbGVhbicsICdhcnJheSddIH0sXG4gICAgICAgICAgYWxsb3c6IHtcbiAgICAgICAgICAgIHR5cGU6ICdhcnJheScsXG4gICAgICAgICAgICBpdGVtczoge1xuICAgICAgICAgICAgICB0eXBlOiAnc3RyaW5nJyxcbiAgICAgICAgICAgIH0sXG4gICAgICAgICAgfSxcbiAgICAgICAgfSxcbiAgICAgICAgYWRkaXRpb25hbFByb3BlcnRpZXM6IGZhbHNlLFxuICAgICAgfSxcbiAgICBdLFxuICB9LFxufTtcbiJdfQ==