'use strict';




var _resolve = require('eslint-module-utils/resolve');var _resolve2 = _interopRequireDefault(_resolve);
var _moduleVisitor = require('eslint-module-utils/moduleVisitor');var _moduleVisitor2 = _interopRequireDefault(_moduleVisitor);
var _docsUrl = require('../docsUrl');var _docsUrl2 = _interopRequireDefault(_docsUrl);function _interopRequireDefault(obj) {return obj && obj.__esModule ? obj : { 'default': obj };}

function isImportingSelf(context, node, requireName) {
  var filePath = context.getPhysicalFilename ? context.getPhysicalFilename() : context.getFilename();

  // If the input is from stdin, this test can't fail
  if (filePath !== '<text>' && filePath === (0, _resolve2['default'])(requireName, context)) {
    context.report({
      node: node,
      message: 'Module imports itself.' });

  }
} /**
   * @fileOverview Forbids a module from importing itself
   * @author Gio d'Amelio
   */module.exports = { meta: {
    type: 'problem',
    docs: {
      category: 'Static analysis',
      description: 'Forbid a module from importing itself.',
      recommended: true,
      url: (0, _docsUrl2['default'])('no-self-import') },


    schema: [] },

  create: function () {function create(context) {
      return (0, _moduleVisitor2['default'])(function (source, node) {
        isImportingSelf(context, node, source.value);
      }, { commonjs: true });
    }return create;}() };
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIi4uLy4uL3NyYy9ydWxlcy9uby1zZWxmLWltcG9ydC5qcyJdLCJuYW1lcyI6WyJpc0ltcG9ydGluZ1NlbGYiLCJjb250ZXh0Iiwibm9kZSIsInJlcXVpcmVOYW1lIiwiZmlsZVBhdGgiLCJnZXRQaHlzaWNhbEZpbGVuYW1lIiwiZ2V0RmlsZW5hbWUiLCJyZXBvcnQiLCJtZXNzYWdlIiwibW9kdWxlIiwiZXhwb3J0cyIsIm1ldGEiLCJ0eXBlIiwiZG9jcyIsImNhdGVnb3J5IiwiZGVzY3JpcHRpb24iLCJyZWNvbW1lbmRlZCIsInVybCIsInNjaGVtYSIsImNyZWF0ZSIsInNvdXJjZSIsInZhbHVlIiwiY29tbW9uanMiXSwibWFwcGluZ3MiOiI7Ozs7O0FBS0Esc0Q7QUFDQSxrRTtBQUNBLHFDOztBQUVBLFNBQVNBLGVBQVQsQ0FBeUJDLE9BQXpCLEVBQWtDQyxJQUFsQyxFQUF3Q0MsV0FBeEMsRUFBcUQ7QUFDbkQsTUFBTUMsV0FBV0gsUUFBUUksbUJBQVIsR0FBOEJKLFFBQVFJLG1CQUFSLEVBQTlCLEdBQThESixRQUFRSyxXQUFSLEVBQS9FOztBQUVBO0FBQ0EsTUFBSUYsYUFBYSxRQUFiLElBQXlCQSxhQUFhLDBCQUFRRCxXQUFSLEVBQXFCRixPQUFyQixDQUExQyxFQUF5RTtBQUN2RUEsWUFBUU0sTUFBUixDQUFlO0FBQ2JMLGdCQURhO0FBRWJNLGVBQVMsd0JBRkksRUFBZjs7QUFJRDtBQUNGLEMsQ0FuQkQ7OztLQXFCQUMsT0FBT0MsT0FBUCxHQUFpQixFQUNmQyxNQUFNO0FBQ0pDLFVBQU0sU0FERjtBQUVKQyxVQUFNO0FBQ0pDLGdCQUFVLGlCQUROO0FBRUpDLG1CQUFhLHdDQUZUO0FBR0pDLG1CQUFhLElBSFQ7QUFJSkMsV0FBSywwQkFBUSxnQkFBUixDQUpELEVBRkY7OztBQVNKQyxZQUFRLEVBVEosRUFEUzs7QUFZZkMsUUFaZSwrQkFZUmxCLE9BWlEsRUFZQztBQUNkLGFBQU8sZ0NBQWMsVUFBQ21CLE1BQUQsRUFBU2xCLElBQVQsRUFBa0I7QUFDckNGLHdCQUFnQkMsT0FBaEIsRUFBeUJDLElBQXpCLEVBQStCa0IsT0FBT0MsS0FBdEM7QUFDRCxPQUZNLEVBRUosRUFBRUMsVUFBVSxJQUFaLEVBRkksQ0FBUDtBQUdELEtBaEJjLG1CQUFqQiIsImZpbGUiOiJuby1zZWxmLWltcG9ydC5qcyIsInNvdXJjZXNDb250ZW50IjpbIi8qKlxuICogQGZpbGVPdmVydmlldyBGb3JiaWRzIGEgbW9kdWxlIGZyb20gaW1wb3J0aW5nIGl0c2VsZlxuICogQGF1dGhvciBHaW8gZCdBbWVsaW9cbiAqL1xuXG5pbXBvcnQgcmVzb2x2ZSBmcm9tICdlc2xpbnQtbW9kdWxlLXV0aWxzL3Jlc29sdmUnO1xuaW1wb3J0IG1vZHVsZVZpc2l0b3IgZnJvbSAnZXNsaW50LW1vZHVsZS11dGlscy9tb2R1bGVWaXNpdG9yJztcbmltcG9ydCBkb2NzVXJsIGZyb20gJy4uL2RvY3NVcmwnO1xuXG5mdW5jdGlvbiBpc0ltcG9ydGluZ1NlbGYoY29udGV4dCwgbm9kZSwgcmVxdWlyZU5hbWUpIHtcbiAgY29uc3QgZmlsZVBhdGggPSBjb250ZXh0LmdldFBoeXNpY2FsRmlsZW5hbWUgPyBjb250ZXh0LmdldFBoeXNpY2FsRmlsZW5hbWUoKSA6IGNvbnRleHQuZ2V0RmlsZW5hbWUoKTtcblxuICAvLyBJZiB0aGUgaW5wdXQgaXMgZnJvbSBzdGRpbiwgdGhpcyB0ZXN0IGNhbid0IGZhaWxcbiAgaWYgKGZpbGVQYXRoICE9PSAnPHRleHQ+JyAmJiBmaWxlUGF0aCA9PT0gcmVzb2x2ZShyZXF1aXJlTmFtZSwgY29udGV4dCkpIHtcbiAgICBjb250ZXh0LnJlcG9ydCh7XG4gICAgICBub2RlLFxuICAgICAgbWVzc2FnZTogJ01vZHVsZSBpbXBvcnRzIGl0c2VsZi4nLFxuICAgIH0pO1xuICB9XG59XG5cbm1vZHVsZS5leHBvcnRzID0ge1xuICBtZXRhOiB7XG4gICAgdHlwZTogJ3Byb2JsZW0nLFxuICAgIGRvY3M6IHtcbiAgICAgIGNhdGVnb3J5OiAnU3RhdGljIGFuYWx5c2lzJyxcbiAgICAgIGRlc2NyaXB0aW9uOiAnRm9yYmlkIGEgbW9kdWxlIGZyb20gaW1wb3J0aW5nIGl0c2VsZi4nLFxuICAgICAgcmVjb21tZW5kZWQ6IHRydWUsXG4gICAgICB1cmw6IGRvY3NVcmwoJ25vLXNlbGYtaW1wb3J0JyksXG4gICAgfSxcblxuICAgIHNjaGVtYTogW10sXG4gIH0sXG4gIGNyZWF0ZShjb250ZXh0KSB7XG4gICAgcmV0dXJuIG1vZHVsZVZpc2l0b3IoKHNvdXJjZSwgbm9kZSkgPT4ge1xuICAgICAgaXNJbXBvcnRpbmdTZWxmKGNvbnRleHQsIG5vZGUsIHNvdXJjZS52YWx1ZSk7XG4gICAgfSwgeyBjb21tb25qczogdHJ1ZSB9KTtcbiAgfSxcbn07XG4iXX0=