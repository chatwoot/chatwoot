'use strict';var _path = require('path');var _path2 = _interopRequireDefault(_path);
var _moduleVisitor = require('eslint-module-utils/moduleVisitor');var _moduleVisitor2 = _interopRequireDefault(_moduleVisitor);
var _importType = require('../core/importType');
var _docsUrl = require('../docsUrl');var _docsUrl2 = _interopRequireDefault(_docsUrl);function _interopRequireDefault(obj) {return obj && obj.__esModule ? obj : { 'default': obj };}

module.exports = {
  meta: {
    type: 'suggestion',
    docs: {
      category: 'Static analysis',
      description: 'Forbid import of modules using absolute paths.',
      url: (0, _docsUrl2['default'])('no-absolute-path') },

    fixable: 'code',
    schema: [(0, _moduleVisitor.makeOptionsSchema)()] },


  create: function () {function create(context) {
      function reportIfAbsolute(source) {
        if ((0, _importType.isAbsolute)(source.value)) {
          context.report({
            node: source,
            message: 'Do not import modules using an absolute path',
            fix: function () {function fix(fixer) {
                var resolvedContext = context.getPhysicalFilename ? context.getPhysicalFilename() : context.getFilename();
                // node.js and web imports work with posix style paths ("/")
                var relativePath = _path2['default'].posix.relative(_path2['default'].dirname(resolvedContext), source.value);
                if (!relativePath.startsWith('.')) {
                  relativePath = './' + String(relativePath);
                }
                return fixer.replaceText(source, JSON.stringify(relativePath));
              }return fix;}() });

        }
      }

      var options = Object.assign({ esmodule: true, commonjs: true }, context.options[0]);
      return (0, _moduleVisitor2['default'])(reportIfAbsolute, options);
    }return create;}() };
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIi4uLy4uL3NyYy9ydWxlcy9uby1hYnNvbHV0ZS1wYXRoLmpzIl0sIm5hbWVzIjpbIm1vZHVsZSIsImV4cG9ydHMiLCJtZXRhIiwidHlwZSIsImRvY3MiLCJjYXRlZ29yeSIsImRlc2NyaXB0aW9uIiwidXJsIiwiZml4YWJsZSIsInNjaGVtYSIsImNyZWF0ZSIsImNvbnRleHQiLCJyZXBvcnRJZkFic29sdXRlIiwic291cmNlIiwidmFsdWUiLCJyZXBvcnQiLCJub2RlIiwibWVzc2FnZSIsImZpeCIsImZpeGVyIiwicmVzb2x2ZWRDb250ZXh0IiwiZ2V0UGh5c2ljYWxGaWxlbmFtZSIsImdldEZpbGVuYW1lIiwicmVsYXRpdmVQYXRoIiwicGF0aCIsInBvc2l4IiwicmVsYXRpdmUiLCJkaXJuYW1lIiwic3RhcnRzV2l0aCIsInJlcGxhY2VUZXh0IiwiSlNPTiIsInN0cmluZ2lmeSIsIm9wdGlvbnMiLCJlc21vZHVsZSIsImNvbW1vbmpzIl0sIm1hcHBpbmdzIjoiYUFBQSw0QjtBQUNBLGtFO0FBQ0E7QUFDQSxxQzs7QUFFQUEsT0FBT0MsT0FBUCxHQUFpQjtBQUNmQyxRQUFNO0FBQ0pDLFVBQU0sWUFERjtBQUVKQyxVQUFNO0FBQ0pDLGdCQUFVLGlCQUROO0FBRUpDLG1CQUFhLGdEQUZUO0FBR0pDLFdBQUssMEJBQVEsa0JBQVIsQ0FIRCxFQUZGOztBQU9KQyxhQUFTLE1BUEw7QUFRSkMsWUFBUSxDQUFDLHVDQUFELENBUkosRUFEUzs7O0FBWWZDLFFBWmUsK0JBWVJDLE9BWlEsRUFZQztBQUNkLGVBQVNDLGdCQUFULENBQTBCQyxNQUExQixFQUFrQztBQUNoQyxZQUFJLDRCQUFXQSxPQUFPQyxLQUFsQixDQUFKLEVBQThCO0FBQzVCSCxrQkFBUUksTUFBUixDQUFlO0FBQ2JDLGtCQUFNSCxNQURPO0FBRWJJLHFCQUFTLDhDQUZJO0FBR2JDLGVBSGEsNEJBR1RDLEtBSFMsRUFHRjtBQUNULG9CQUFNQyxrQkFBa0JULFFBQVFVLG1CQUFSLEdBQThCVixRQUFRVSxtQkFBUixFQUE5QixHQUE4RFYsUUFBUVcsV0FBUixFQUF0RjtBQUNBO0FBQ0Esb0JBQUlDLGVBQWVDLGtCQUFLQyxLQUFMLENBQVdDLFFBQVgsQ0FBb0JGLGtCQUFLRyxPQUFMLENBQWFQLGVBQWIsQ0FBcEIsRUFBbURQLE9BQU9DLEtBQTFELENBQW5CO0FBQ0Esb0JBQUksQ0FBQ1MsYUFBYUssVUFBYixDQUF3QixHQUF4QixDQUFMLEVBQW1DO0FBQ2pDTCwrQ0FBb0JBLFlBQXBCO0FBQ0Q7QUFDRCx1QkFBT0osTUFBTVUsV0FBTixDQUFrQmhCLE1BQWxCLEVBQTBCaUIsS0FBS0MsU0FBTCxDQUFlUixZQUFmLENBQTFCLENBQVA7QUFDRCxlQVhZLGdCQUFmOztBQWFEO0FBQ0Y7O0FBRUQsVUFBTVMsMEJBQVlDLFVBQVUsSUFBdEIsRUFBNEJDLFVBQVUsSUFBdEMsSUFBK0N2QixRQUFRcUIsT0FBUixDQUFnQixDQUFoQixDQUEvQyxDQUFOO0FBQ0EsYUFBTyxnQ0FBY3BCLGdCQUFkLEVBQWdDb0IsT0FBaEMsQ0FBUDtBQUNELEtBakNjLG1CQUFqQiIsImZpbGUiOiJuby1hYnNvbHV0ZS1wYXRoLmpzIiwic291cmNlc0NvbnRlbnQiOlsiaW1wb3J0IHBhdGggZnJvbSAncGF0aCc7XG5pbXBvcnQgbW9kdWxlVmlzaXRvciwgeyBtYWtlT3B0aW9uc1NjaGVtYSB9IGZyb20gJ2VzbGludC1tb2R1bGUtdXRpbHMvbW9kdWxlVmlzaXRvcic7XG5pbXBvcnQgeyBpc0Fic29sdXRlIH0gZnJvbSAnLi4vY29yZS9pbXBvcnRUeXBlJztcbmltcG9ydCBkb2NzVXJsIGZyb20gJy4uL2RvY3NVcmwnO1xuXG5tb2R1bGUuZXhwb3J0cyA9IHtcbiAgbWV0YToge1xuICAgIHR5cGU6ICdzdWdnZXN0aW9uJyxcbiAgICBkb2NzOiB7XG4gICAgICBjYXRlZ29yeTogJ1N0YXRpYyBhbmFseXNpcycsXG4gICAgICBkZXNjcmlwdGlvbjogJ0ZvcmJpZCBpbXBvcnQgb2YgbW9kdWxlcyB1c2luZyBhYnNvbHV0ZSBwYXRocy4nLFxuICAgICAgdXJsOiBkb2NzVXJsKCduby1hYnNvbHV0ZS1wYXRoJyksXG4gICAgfSxcbiAgICBmaXhhYmxlOiAnY29kZScsXG4gICAgc2NoZW1hOiBbbWFrZU9wdGlvbnNTY2hlbWEoKV0sXG4gIH0sXG5cbiAgY3JlYXRlKGNvbnRleHQpIHtcbiAgICBmdW5jdGlvbiByZXBvcnRJZkFic29sdXRlKHNvdXJjZSkge1xuICAgICAgaWYgKGlzQWJzb2x1dGUoc291cmNlLnZhbHVlKSkge1xuICAgICAgICBjb250ZXh0LnJlcG9ydCh7XG4gICAgICAgICAgbm9kZTogc291cmNlLFxuICAgICAgICAgIG1lc3NhZ2U6ICdEbyBub3QgaW1wb3J0IG1vZHVsZXMgdXNpbmcgYW4gYWJzb2x1dGUgcGF0aCcsXG4gICAgICAgICAgZml4KGZpeGVyKSB7XG4gICAgICAgICAgICBjb25zdCByZXNvbHZlZENvbnRleHQgPSBjb250ZXh0LmdldFBoeXNpY2FsRmlsZW5hbWUgPyBjb250ZXh0LmdldFBoeXNpY2FsRmlsZW5hbWUoKSA6IGNvbnRleHQuZ2V0RmlsZW5hbWUoKTtcbiAgICAgICAgICAgIC8vIG5vZGUuanMgYW5kIHdlYiBpbXBvcnRzIHdvcmsgd2l0aCBwb3NpeCBzdHlsZSBwYXRocyAoXCIvXCIpXG4gICAgICAgICAgICBsZXQgcmVsYXRpdmVQYXRoID0gcGF0aC5wb3NpeC5yZWxhdGl2ZShwYXRoLmRpcm5hbWUocmVzb2x2ZWRDb250ZXh0KSwgc291cmNlLnZhbHVlKTtcbiAgICAgICAgICAgIGlmICghcmVsYXRpdmVQYXRoLnN0YXJ0c1dpdGgoJy4nKSkge1xuICAgICAgICAgICAgICByZWxhdGl2ZVBhdGggPSBgLi8ke3JlbGF0aXZlUGF0aH1gO1xuICAgICAgICAgICAgfVxuICAgICAgICAgICAgcmV0dXJuIGZpeGVyLnJlcGxhY2VUZXh0KHNvdXJjZSwgSlNPTi5zdHJpbmdpZnkocmVsYXRpdmVQYXRoKSk7XG4gICAgICAgICAgfSxcbiAgICAgICAgfSk7XG4gICAgICB9XG4gICAgfVxuXG4gICAgY29uc3Qgb3B0aW9ucyA9IHsgZXNtb2R1bGU6IHRydWUsIGNvbW1vbmpzOiB0cnVlLCAuLi5jb250ZXh0Lm9wdGlvbnNbMF0gfTtcbiAgICByZXR1cm4gbW9kdWxlVmlzaXRvcihyZXBvcnRJZkFic29sdXRlLCBvcHRpb25zKTtcbiAgfSxcbn07XG4iXX0=