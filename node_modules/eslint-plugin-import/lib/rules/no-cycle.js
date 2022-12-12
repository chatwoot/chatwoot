'use strict';var _slicedToArray = function () {function sliceIterator(arr, i) {var _arr = [];var _n = true;var _d = false;var _e = undefined;try {for (var _i = arr[Symbol.iterator](), _s; !(_n = (_s = _i.next()).done); _n = true) {_arr.push(_s.value);if (i && _arr.length === i) break;}} catch (err) {_d = true;_e = err;} finally {try {if (!_n && _i["return"]) _i["return"]();} finally {if (_d) throw _e;}}return _arr;}return function (arr, i) {if (Array.isArray(arr)) {return arr;} else if (Symbol.iterator in Object(arr)) {return sliceIterator(arr, i);} else {throw new TypeError("Invalid attempt to destructure non-iterable instance");}};}(); /**
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       * @fileOverview Ensures that no imported module imports the linted module.
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       * @author Ben Mosher
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       */

var _ExportMap = require('../ExportMap');var _ExportMap2 = _interopRequireDefault(_ExportMap);
var _importType = require('../core/importType');
var _moduleVisitor = require('eslint-module-utils/moduleVisitor');var _moduleVisitor2 = _interopRequireDefault(_moduleVisitor);
var _docsUrl = require('../docsUrl');var _docsUrl2 = _interopRequireDefault(_docsUrl);function _interopRequireDefault(obj) {return obj && obj.__esModule ? obj : { default: obj };}

// todo: cache cycles / deep relationships for faster repeat evaluation
module.exports = {
  meta: {
    type: 'suggestion',
    docs: { url: (0, _docsUrl2.default)('no-cycle') },
    schema: [(0, _moduleVisitor.makeOptionsSchema)({
      maxDepth: {
        oneOf: [
        {
          description: 'maximum dependency depth to traverse',
          type: 'integer',
          minimum: 1 },

        {
          enum: ['∞'],
          type: 'string' }] },



      ignoreExternal: {
        description: 'ignore external modules',
        type: 'boolean',
        default: false } })] },




  create: function (context) {
    const myPath = context.getFilename();
    if (myPath === '<text>') return {}; // can't cycle-check a non-file

    const options = context.options[0] || {};
    const maxDepth = typeof options.maxDepth === 'number' ? options.maxDepth : Infinity;
    const ignoreModule = name => options.ignoreExternal ? (0, _importType.isExternalModule)(name) : false;

    function checkSourceValue(sourceNode, importer) {
      if (ignoreModule(sourceNode.value)) {
        return; // ignore external modules
      }

      const imported = _ExportMap2.default.get(sourceNode.value, context);

      if (importer.importKind === 'type') {
        return; // no Flow import resolution
      }

      if (imported == null) {
        return; // no-unresolved territory
      }

      if (imported.path === myPath) {
        return; // no-self-import territory
      }

      const untraversed = [{ mget: () => imported, route: [] }];
      const traversed = new Set();
      function detectCycle(_ref) {let mget = _ref.mget,route = _ref.route;
        const m = mget();
        if (m == null) return;
        if (traversed.has(m.path)) return;
        traversed.add(m.path);

        for (let _ref2 of m.imports) {var _ref3 = _slicedToArray(_ref2, 2);let path = _ref3[0];var _ref3$ = _ref3[1];let getter = _ref3$.getter;let source = _ref3$.source;
          if (path === myPath) return true;
          if (traversed.has(path)) continue;
          if (ignoreModule(source.value)) continue;
          if (route.length + 1 < maxDepth) {
            untraversed.push({
              mget: getter,
              route: route.concat(source) });

          }
        }
      }

      while (untraversed.length > 0) {
        const next = untraversed.shift(); // bfs!
        if (detectCycle(next)) {
          const message = next.route.length > 0 ?
          `Dependency cycle via ${routeString(next.route)}` :
          'Dependency cycle detected.';
          context.report(importer, message);
          return;
        }
      }
    }

    return (0, _moduleVisitor2.default)(checkSourceValue, context.options[0]);
  } };


function routeString(route) {
  return route.map(s => `${s.value}:${s.loc.start.line}`).join('=>');
}
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIi4uLy4uL3NyYy9ydWxlcy9uby1jeWNsZS5qcyJdLCJuYW1lcyI6WyJtb2R1bGUiLCJleHBvcnRzIiwibWV0YSIsInR5cGUiLCJkb2NzIiwidXJsIiwic2NoZW1hIiwibWF4RGVwdGgiLCJvbmVPZiIsImRlc2NyaXB0aW9uIiwibWluaW11bSIsImVudW0iLCJpZ25vcmVFeHRlcm5hbCIsImRlZmF1bHQiLCJjcmVhdGUiLCJjb250ZXh0IiwibXlQYXRoIiwiZ2V0RmlsZW5hbWUiLCJvcHRpb25zIiwiSW5maW5pdHkiLCJpZ25vcmVNb2R1bGUiLCJuYW1lIiwiY2hlY2tTb3VyY2VWYWx1ZSIsInNvdXJjZU5vZGUiLCJpbXBvcnRlciIsInZhbHVlIiwiaW1wb3J0ZWQiLCJFeHBvcnRzIiwiZ2V0IiwiaW1wb3J0S2luZCIsInBhdGgiLCJ1bnRyYXZlcnNlZCIsIm1nZXQiLCJyb3V0ZSIsInRyYXZlcnNlZCIsIlNldCIsImRldGVjdEN5Y2xlIiwibSIsImhhcyIsImFkZCIsImltcG9ydHMiLCJnZXR0ZXIiLCJzb3VyY2UiLCJsZW5ndGgiLCJwdXNoIiwiY29uY2F0IiwibmV4dCIsInNoaWZ0IiwibWVzc2FnZSIsInJvdXRlU3RyaW5nIiwicmVwb3J0IiwibWFwIiwicyIsImxvYyIsInN0YXJ0IiwibGluZSIsImpvaW4iXSwibWFwcGluZ3MiOiJzb0JBQUE7Ozs7O0FBS0EseUM7QUFDQTtBQUNBLGtFO0FBQ0EscUM7O0FBRUE7QUFDQUEsT0FBT0MsT0FBUCxHQUFpQjtBQUNmQyxRQUFNO0FBQ0pDLFVBQU0sWUFERjtBQUVKQyxVQUFNLEVBQUVDLEtBQUssdUJBQVEsVUFBUixDQUFQLEVBRkY7QUFHSkMsWUFBUSxDQUFDLHNDQUFrQjtBQUN6QkMsZ0JBQVU7QUFDUkMsZUFBTztBQUNMO0FBQ0VDLHVCQUFhLHNDQURmO0FBRUVOLGdCQUFNLFNBRlI7QUFHRU8sbUJBQVMsQ0FIWCxFQURLOztBQU1MO0FBQ0VDLGdCQUFNLENBQUMsR0FBRCxDQURSO0FBRUVSLGdCQUFN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QkFBYzFCLGdCQUFkLEVBQWdDUCxRQUFRRyxPQUFSLENBQWdCLENBQWhCLENBQWhDLENBQVA7QUFDRCxHQXZGYyxFQUFqQjs7O0FBMEZBLFNBQVMrQixXQUFULENBQXFCaEIsS0FBckIsRUFBNEI7QUFDMUIsU0FBT0EsTUFBTWtCLEdBQU4sQ0FBVUMsS0FBTSxHQUFFQSxFQUFFM0IsS0FBTSxJQUFHMkIsRUFBRUMsR0FBRixDQUFNQyxLQUFOLENBQVlDLElBQUssRUFBOUMsRUFBaURDLElBQWpELENBQXNELElBQXRELENBQVA7QUFDRCIsImZpbGUiOiJuby1jeWNsZS5qcyIsInNvdXJjZXNDb250ZW50IjpbIi8qKlxuICogQGZpbGVPdmVydmlldyBFbnN1cmVzIHRoYXQgbm8gaW1wb3J0ZWQgbW9kdWxlIGltcG9ydHMgdGhlIGxpbnRlZCBtb2R1bGUuXG4gKiBAYXV0aG9yIEJlbiBNb3NoZXJcbiAqL1xuXG5pbXBvcnQgRXhwb3J0cyBmcm9tICcuLi9FeHBvcnRNYXAnXG5pbXBvcnQgeyBpc0V4dGVybmFsTW9kdWxlIH0gZnJvbSAnLi4vY29yZS9pbXBvcnRUeXBlJ1xuaW1wb3J0IG1vZHVsZVZpc2l0b3IsIHsgbWFrZU9wdGlvbnNTY2hlbWEgfSBmcm9tICdlc2xpbnQtbW9kdWxlLXV0aWxzL21vZHVsZVZpc2l0b3InXG5pbXBvcnQgZG9jc1VybCBmcm9tICcuLi9kb2NzVXJsJ1xuXG4vLyB0b2RvOiBjYWNoZSBjeWNsZXMgLyBkZWVwIHJlbGF0aW9uc2hpcHMgZm9yIGZhc3RlciByZXBlYXQgZXZhbHVhdGlvblxubW9kdWxlLmV4cG9ydHMgPSB7XG4gIG1ldGE6IHtcbiAgICB0eXBlOiAnc3VnZ2VzdGlvbicsXG4gICAgZG9jczogeyB1cmw6IGRvY3NVcmwoJ25vLWN5Y2xlJykgfSxcbiAgICBzY2hlbWE6IFttYWtlT3B0aW9uc1NjaGVtYSh7XG4gICAgICBtYXhEZXB0aDoge1xuICAgICAgICBvbmVPZjogW1xuICAgICAgICAgIHtcbiAgICAgICAgICAgIGRlc2NyaXB0aW9uOiAnbWF4aW11bSBkZXBlbmRlbmN5IGRlcHRoIHRvIHRyYXZlcnNlJyxcbiAgICAgICAgICAgIHR5cGU6ICdpbnRlZ2VyJyxcbiAgICAgICAgICAgIG1pbmltdW06IDEsXG4gICAgICAgICAgfSxcbiAgICAgICAgICB7XG4gICAgICAgICAgICBlbnVtOiBbJ+KIniddLFxuICAgICAgICAgICAgdHlwZTogJ3N0cmluZycsXG4gICAgICAgICAgfSxcbiAgICAgICAgXSxcbiAgICAgIH0sXG4gICAgICBpZ25vcmVFeHRlcm5hbDoge1xuICAgICAgICBkZXNjcmlwdGlvbjogJ2lnbm9yZSBleHRlcm5hbCBtb2R1bGVzJyxcbiAgICAgICAgdHlwZTogJ2Jvb2xlYW4nLFxuICAgICAgICBkZWZhdWx0OiBmYWxzZSxcbiAgICAgIH0sXG4gICAgfSldLFxuICB9LFxuXG4gIGNyZWF0ZTogZnVuY3Rpb24gKGNvbnRleHQpIHtcbiAgICBjb25zdCBteVBhdGggPSBjb250ZXh0LmdldEZpbGVuYW1lKClcbiAgICBpZiAobXlQYXRoID09PSAnPHRleHQ+JykgcmV0dXJuIHt9IC8vIGNhbid0IGN5Y2xlLWNoZWNrIGEgbm9uLWZpbGVcblxuICAgIGNvbnN0IG9wdGlvbnMgPSBjb250ZXh0Lm9wdGlvbnNbMF0gfHwge31cbiAgICBjb25zdCBtYXhEZXB0aCA9IHR5cGVvZiBvcHRpb25zLm1heERlcHRoID09PSAnbnVtYmVyJyA/IG9wdGlvbnMubWF4RGVwdGggOiBJbmZpbml0eVxuICAgIGNvbnN0IGlnbm9yZU1vZHVsZSA9IChuYW1lKSA9PiBvcHRpb25zLmlnbm9yZUV4dGVybmFsID8gaXNFeHRlcm5hbE1vZHVsZShuYW1lKSA6IGZhbHNlXG5cbiAgICBmdW5jdGlvbiBjaGVja1NvdXJjZVZhbHVlKHNvdXJjZU5vZGUsIGltcG9ydGVyKSB7XG4gICAgICBpZiAoaWdub3JlTW9kdWxlKHNvdXJjZU5vZGUudmFsdWUpKSB7XG4gICAgICAgIHJldHVybiAvLyBpZ25vcmUgZXh0ZXJuYWwgbW9kdWxlc1xuICAgICAgfVxuXG4gICAgICBjb25zdCBpbXBvcnRlZCA9IEV4cG9ydHMuZ2V0KHNvdXJjZU5vZGUudmFsdWUsIGNvbnRleHQpXG5cbiAgICAgIGlmIChpbXBvcnRlci5pbXBvcnRLaW5kID09PSAndHlwZScpIHtcbiAgICAgICAgcmV0dXJuIC8vIG5vIEZsb3cgaW1wb3J0IHJlc29sdXRpb25cbiAgICAgIH1cblxuICAgICAgaWYgKGltcG9ydGVkID09IG51bGwpIHtcbiAgICAgICAgcmV0dXJuICAvLyBuby11bnJlc29sdmVkIHRlcnJpdG9yeVxuICAgICAgfVxuXG4gICAgICBpZiAoaW1wb3J0ZWQucGF0aCA9PT0gbXlQYXRoKSB7XG4gICAgICAgIHJldHVybiAgLy8gbm8tc2VsZi1pbXBvcnQgdGVycml0b3J5XG4gICAgICB9XG5cbiAgICAgIGNvbnN0IHVudHJhdmVyc2VkID0gW3ttZ2V0OiAoKSA9PiBpbXBvcnRlZCwgcm91dGU6W119XVxuICAgICAgY29uc3QgdHJhdmVyc2VkID0gbmV3IFNldCgpXG4gICAgICBmdW5jdGlvbiBkZXRlY3RDeWNsZSh7bWdldCwgcm91dGV9KSB7XG4gICAgICAgIGNvbnN0IG0gPSBtZ2V0KClcbiAgICAgICAgaWYgKG0gPT0gbnVsbCkgcmV0dXJuXG4gICAgICAgIGlmICh0cmF2ZXJzZWQuaGFzKG0ucGF0aCkpIHJldHVyblxuICAgICAgICB0cmF2ZXJzZWQuYWRkKG0ucGF0aClcblxuICAgICAgICBmb3IgKGxldCBbcGF0aCwgeyBnZXR0ZXIsIHNvdXJjZSB9XSBvZiBtLmltcG9ydHMpIHtcbiAgICAgICAgICBpZiAocGF0aCA9PT0gbXlQYXRoKSByZXR1cm4gdHJ1ZVxuICAgICAgICAgIGlmICh0cmF2ZXJzZWQuaGFzKHBhdGgpKSBjb250aW51ZVxuICAgICAgICAgIGlmIChpZ25vcmVNb2R1bGUoc291cmNlLnZhbHVlKSkgY29udGludWVcbiAgICAgICAgICBpZiAocm91dGUubGVuZ3RoICsgMSA8IG1heERlcHRoKSB7XG4gICAgICAgICAgICB1bnRyYXZlcnNlZC5wdXNoKHtcbiAgICAgICAgICAgICAgbWdldDogZ2V0dGVyLFxuICAgICAgICAgICAgICByb3V0ZTogcm91dGUuY29uY2F0KHNvdXJjZSksXG4gICAgICAgICAgICB9KVxuICAgICAgICAgIH1cbiAgICAgICAgfVxuICAgICAgfVxuXG4gICAgICB3aGlsZSAodW50cmF2ZXJzZWQubGVuZ3RoID4gMCkge1xuICAgICAgICBjb25zdCBuZXh0ID0gdW50cmF2ZXJzZWQuc2hpZnQoKSAvLyBiZnMhXG4gICAgICAgIGlmIChkZXRlY3RDeWNsZShuZXh0KSkge1xuICAgICAgICAgIGNvbnN0IG1lc3NhZ2UgPSAobmV4dC5yb3V0ZS5sZW5ndGggPiAwXG4gICAgICAgICAgICA/IGBEZXBlbmRlbmN5IGN5Y2xlIHZpYSAke3JvdXRlU3RyaW5nKG5leHQucm91dGUpfWBcbiAgICAgICAgICAgIDogJ0RlcGVuZGVuY3kgY3ljbGUgZGV0ZWN0ZWQuJylcbiAgICAgICAgICBjb250ZXh0LnJlcG9ydChpbXBvcnRlciwgbWVzc2FnZSlcbiAgICAgICAgICByZXR1cm5cbiAgICAgICAgfVxuICAgICAgfVxuICAgIH1cblxuICAgIHJldHVybiBtb2R1bGVWaXNpdG9yKGNoZWNrU291cmNlVmFsdWUsIGNvbnRleHQub3B0aW9uc1swXSlcbiAgfSxcbn1cblxuZnVuY3Rpb24gcm91dGVTdHJpbmcocm91dGUpIHtcbiAgcmV0dXJuIHJvdXRlLm1hcChzID0+IGAke3MudmFsdWV9OiR7cy5sb2Muc3RhcnQubGluZX1gKS5qb2luKCc9PicpXG59XG4iXX0=