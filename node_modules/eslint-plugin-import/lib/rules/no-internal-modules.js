'use strict';var _slicedToArray = function () {function sliceIterator(arr, i) {var _arr = [];var _n = true;var _d = false;var _e = undefined;try {for (var _i = arr[Symbol.iterator](), _s; !(_n = (_s = _i.next()).done); _n = true) {_arr.push(_s.value);if (i && _arr.length === i) break;}} catch (err) {_d = true;_e = err;} finally {try {if (!_n && _i["return"]) _i["return"]();} finally {if (_d) throw _e;}}return _arr;}return function (arr, i) {if (Array.isArray(arr)) {return arr;} else if (Symbol.iterator in Object(arr)) {return sliceIterator(arr, i);} else {throw new TypeError("Invalid attempt to destructure non-iterable instance");}};}();var _minimatch = require('minimatch');var _minimatch2 = _interopRequireDefault(_minimatch);

var _resolve = require('eslint-module-utils/resolve');var _resolve2 = _interopRequireDefault(_resolve);
var _importType = require('../core/importType');var _importType2 = _interopRequireDefault(_importType);
var _staticRequire = require('../core/staticRequire');var _staticRequire2 = _interopRequireDefault(_staticRequire);
var _docsUrl = require('../docsUrl');var _docsUrl2 = _interopRequireDefault(_docsUrl);function _interopRequireDefault(obj) {return obj && obj.__esModule ? obj : { default: obj };}

module.exports = {
  meta: {
    type: 'suggestion',
    docs: {
      url: (0, _docsUrl2.default)('no-internal-modules') },


    schema: [
    {
      type: 'object',
      properties: {
        allow: {
          type: 'array',
          items: {
            type: 'string' } } },



      additionalProperties: false }] },




  create: function noReachingInside(context) {
    const options = context.options[0] || {};
    const allowRegexps = (options.allow || []).map(p => _minimatch2.default.makeRe(p));

    // test if reaching to this destination is allowed
    function reachingAllowed(importPath) {
      return allowRegexps.some(re => re.test(importPath));
    }

    // minimatch patterns are expected to use / path separators, like import
    // statements, so normalize paths to use the same
    function normalizeSep(somePath) {
      return somePath.split('\\').join('/');
    }

    // find a directory that is being reached into, but which shouldn't be
    function isReachViolation(importPath) {
      const steps = normalizeSep(importPath).
      split('/').
      reduce((acc, step) => {
        if (!step || step === '.') {
          return acc;
        } else if (step === '..') {
          return acc.slice(0, -1);
        } else {
          return acc.concat(step);
        }
      }, []);

      const nonScopeSteps = steps.filter(step => step.indexOf('@') !== 0);
      if (nonScopeSteps.length <= 1) return false;

      // before trying to resolve, see if the raw import (with relative
      // segments resolved) matches an allowed pattern
      const justSteps = steps.join('/');
      if (reachingAllowed(justSteps) || reachingAllowed(`/${justSteps}`)) return false;

      // if the import statement doesn't match directly, try to match the
      // resolved path if the import is resolvable
      const resolved = (0, _resolve2.default)(importPath, context);
      if (!resolved || reachingAllowed(normalizeSep(resolved))) return false;

      // this import was not allowed by the allowed paths, and reaches
      // so it is a violation
      return true;
    }

    function checkImportForReaching(importPath, node) {
      const potentialViolationTypes = ['parent', 'index', 'sibling', 'external', 'internal'];
      if (potentialViolationTypes.indexOf((0, _importType2.default)(importPath, context)) !== -1 &&
      isReachViolation(importPath))
      {
        context.report({
          node,
          message: `Reaching to "${importPath}" is not allowed.` });

      }
    }

    return {
      ImportDeclaration(node) {
        checkImportForReaching(node.source.value, node.source);
      },
      ExportAllDeclaration(node) {
        checkImportForReaching(node.source.value, node.source);
      },
      ExportNamedDeclaration(node) {
        if (node.source) {
          checkImportForReaching(node.source.value, node.source);
        }
      },
      CallExpression(node) {
        if ((0, _staticRequire2.default)(node)) {var _node$arguments = _slicedToArray(
          node.arguments, 1);const firstArgument = _node$arguments[0];
          checkImportForReaching(firstArgument.value, firstArgument);
        }
      } };

  } };
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIi4uLy4uL3NyYy9ydWxlcy9uby1pbnRlcm5hbC1tb2R1bGVzLmpzIl0sIm5hbWVzIjpbIm1vZHVsZSIsImV4cG9ydHMiLCJtZXRhIiwidHlwZSIsImRvY3MiLCJ1cmwiLCJzY2hlbWEiLCJwcm9wZXJ0aWVzIiwiYWxsb3ciLCJpdGVtcyIsImFkZGl0aW9uYWxQcm9wZXJ0aWVzIiwiY3JlYXRlIiwibm9SZWFjaGluZ0luc2lkZSIsImNvbnRleHQiLCJvcHRpb25zIiwiYWxsb3dSZWdleHBzIiwibWFwIiwicCIsIm1pbmltYXRjaCIsIm1ha2VSZSIsInJlYWNoaW5nQWxsb3dlZCIsImltcG9ydFBhdGgiLCJzb21lIiwicmUiLCJ0ZXN0Iiwibm9ybWFsaXplU2VwIiwic29tZVBhdGgiLCJzcGxpdCIsImpvaW4iLCJpc1JlYWNoVmlvbGF0aW9uIiwic3RlcHMiLCJyZWR1Y2UiLCJhY2MiLCJzdGVwIiwic2xpY2UiLCJjb25jYXQiLCJub25TY29wZVN0ZXBzIiwiZmlsdGVyIiwiaW5kZXhPZiIsImxlbmd0aCIsImp1c3RTdGVwcyIsInJlc29sdmVkIiwiY2hlY2tJbXBvcnRGb3JSZWFjaGluZyIsIm5vZGUiLCJwb3RlbnRpYWxWaW9sYXRpb25UeXBlcyIsInJlcG9ydCIsIm1lc3NhZ2UiLCJJbXBvcnREZWNsYXJhdGlvbiIsInNvdXJjZSIsInZhbHVlIiwiRXhwb3J0QWxsRGVjbGFyYXRpb24iLCJFeHBvcnROYW1lZERlY2xhcmF0aW9uIiwiQ2FsbEV4cHJlc3Npb24iLCJhcmd1bWVudHMiLCJmaXJzdEFyZ3VtZW50Il0sIm1hcHBpbmdzIjoicW9CQUFBLHNDOztBQUVBLHNEO0FBQ0EsZ0Q7QUFDQSxzRDtBQUNBLHFDOztBQUVBQSxPQUFPQyxPQUFQLEdBQWlCO0FBQ2ZDLFFBQU07QUFDSkMsVUFBTSxZQURGO0FBRUpDLFVBQU07QUFDSkMsV0FBSyx1QkFBUSxxQkFBUixDQURELEVBRkY7OztBQU1KQyxZQUFRO0FBQ047QUFDRUgsWUFBTSxRQURSO0FBRUVJLGtC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QkFBcUJQLElBQXJCLEVBQTJCO0FBQ3pCRCwrQkFBdUJDLEtBQUtLLE1BQUwsQ0FBWUMsS0FBbkMsRUFBMENOLEtBQUtLLE1BQS9DO0FBQ0QsT0FOSTtBQU9MRyw2QkFBdUJSLElBQXZCLEVBQTZCO0FBQzNCLFlBQUlBLEtBQUtLLE1BQVQsRUFBaUI7QUFDZk4saUNBQXVCQyxLQUFLSyxNQUFMLENBQVlDLEtBQW5DLEVBQTBDTixLQUFLSyxNQUEvQztBQUNEO0FBQ0YsT0FYSTtBQVlMSSxxQkFBZVQsSUFBZixFQUFxQjtBQUNuQixZQUFJLDZCQUFnQkEsSUFBaEIsQ0FBSixFQUEyQjtBQUNDQSxlQUFLVSxTQUROLFdBQ2pCQyxhQURpQjtBQUV6QlosaUNBQXVCWSxjQUFjTCxLQUFyQyxFQUE0Q0ssYUFBNUM7QUFDRDtBQUNGLE9BakJJLEVBQVA7O0FBbUJELEdBckdjLEVBQWpCIiwiZmlsZSI6Im5vLWludGVybmFsLW1vZHVsZXMuanMiLCJzb3VyY2VzQ29udGVudCI6WyJpbXBvcnQgbWluaW1hdGNoIGZyb20gJ21pbmltYXRjaCdcblxuaW1wb3J0IHJlc29sdmUgZnJvbSAnZXNsaW50LW1vZHVsZS11dGlscy9yZXNvbHZlJ1xuaW1wb3J0IGltcG9ydFR5cGUgZnJvbSAnLi4vY29yZS9pbXBvcnRUeXBlJ1xuaW1wb3J0IGlzU3RhdGljUmVxdWlyZSBmcm9tICcuLi9jb3JlL3N0YXRpY1JlcXVpcmUnXG5pbXBvcnQgZG9jc1VybCBmcm9tICcuLi9kb2NzVXJsJ1xuXG5tb2R1bGUuZXhwb3J0cyA9IHtcbiAgbWV0YToge1xuICAgIHR5cGU6ICdzdWdnZXN0aW9uJyxcbiAgICBkb2NzOiB7XG4gICAgICB1cmw6IGRvY3NVcmwoJ25vLWludGVybmFsLW1vZHVsZXMnKSxcbiAgICB9LFxuXG4gICAgc2NoZW1hOiBbXG4gICAgICB7XG4gICAgICAgIHR5cGU6ICdvYmplY3QnLFxuICAgICAgICBwcm9wZXJ0aWVzOiB7XG4gICAgICAgICAgYWxsb3c6IHtcbiAgICAgICAgICAgIHR5cGU6ICdhcnJheScsXG4gICAgICAgICAgICBpdGVtczoge1xuICAgICAgICAgICAgICB0eXBlOiAnc3RyaW5nJyxcbiAgICAgICAgICAgIH0sXG4gICAgICAgICAgfSxcbiAgICAgICAgfSxcbiAgICAgICAgYWRkaXRpb25hbFByb3BlcnRpZXM6IGZhbHNlLFxuICAgICAgfSxcbiAgICBdLFxuICB9LFxuXG4gIGNyZWF0ZTogZnVuY3Rpb24gbm9SZWFjaGluZ0luc2lkZShjb250ZXh0KSB7XG4gICAgY29uc3Qgb3B0aW9ucyA9IGNvbnRleHQub3B0aW9uc1swXSB8fCB7fVxuICAgIGNvbnN0IGFsbG93UmVnZXhwcyA9IChvcHRpb25zLmFsbG93IHx8IFtdKS5tYXAocCA9PiBtaW5pbWF0Y2gubWFrZVJlKHApKVxuXG4gICAgLy8gdGVzdCBpZiByZWFjaGluZyB0byB0aGlzIGRlc3RpbmF0aW9uIGlzIGFsbG93ZWRcbiAgICBmdW5jdGlvbiByZWFjaGluZ0FsbG93ZWQoaW1wb3J0UGF0aCkge1xuICAgICAgcmV0dXJuIGFsbG93UmVnZXhwcy5zb21lKHJlID0+IHJlLnRlc3QoaW1wb3J0UGF0aCkpXG4gICAgfVxuXG4gICAgLy8gbWluaW1hdGNoIHBhdHRlcm5zIGFyZSBleHBlY3RlZCB0byB1c2UgLyBwYXRoIHNlcGFyYXRvcnMsIGxpa2UgaW1wb3J0XG4gICAgLy8gc3RhdGVtZW50cywgc28gbm9ybWFsaXplIHBhdGhzIHRvIHVzZSB0aGUgc2FtZVxuICAgIGZ1bmN0aW9uIG5vcm1hbGl6ZVNlcChzb21lUGF0aCkge1xuICAgICAgcmV0dXJuIHNvbWVQYXRoLnNwbGl0KCdcXFxcJykuam9pbignLycpXG4gICAgfVxuXG4gICAgLy8gZmluZCBhIGRpcmVjdG9yeSB0aGF0IGlzIGJlaW5nIHJlYWNoZWQgaW50bywgYnV0IHdoaWNoIHNob3VsZG4ndCBiZVxuICAgIGZ1bmN0aW9uIGlzUmVhY2hWaW9sYXRpb24oaW1wb3J0UGF0aCkge1xuICAgICAgY29uc3Qgc3RlcHMgPSBub3JtYWxpemVTZXAoaW1wb3J0UGF0aClcbiAgICAgICAgLnNwbGl0KCcvJylcbiAgICAgICAgLnJlZHVjZSgoYWNjLCBzdGVwKSA9PiB7XG4gICAgICAgICAgaWYgKCFzdGVwIHx8IHN0ZXAgPT09ICcuJykge1xuICAgICAgICAgICAgcmV0dXJuIGFjY1xuICAgICAgICAgIH0gZWxzZSBpZiAoc3RlcCA9PT0gJy4uJykge1xuICAgICAgICAgICAgcmV0dXJuIGFjYy5zbGljZSgwLCAtMSlcbiAgICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgICAgcmV0dXJuIGFjYy5jb25jYXQoc3RlcClcbiAgICAgICAgICB9XG4gICAgICAgIH0sIFtdKVxuXG4gICAgICBjb25zdCBub25TY29wZVN0ZXBzID0gc3RlcHMuZmlsdGVyKHN0ZXAgPT4gc3RlcC5pbmRleE9mKCdAJykgIT09IDApXG4gICAgICBpZiAobm9uU2NvcGVTdGVwcy5sZW5ndGggPD0gMSkgcmV0dXJuIGZhbHNlXG5cbiAgICAgIC8vIGJlZm9yZSB0cnlpbmcgdG8gcmVzb2x2ZSwgc2VlIGlmIHRoZSByYXcgaW1wb3J0ICh3aXRoIHJlbGF0aXZlXG4gICAgICAvLyBzZWdtZW50cyByZXNvbHZlZCkgbWF0Y2hlcyBhbiBhbGxvd2VkIHBhdHRlcm5cbiAgICAgIGNvbnN0IGp1c3RTdGVwcyA9IHN0ZXBzLmpvaW4oJy8nKVxuICAgICAgaWYgKHJlYWNoaW5nQWxsb3dlZChqdXN0U3RlcHMpIHx8IHJlYWNoaW5nQWxsb3dlZChgLyR7anVzdFN0ZXBzfWApKSByZXR1cm4gZmFsc2VcblxuICAgICAgLy8gaWYgdGhlIGltcG9ydCBzdGF0ZW1lbnQgZG9lc24ndCBtYXRjaCBkaXJlY3RseSwgdHJ5IHRvIG1hdGNoIHRoZVxuICAgICAgLy8gcmVzb2x2ZWQgcGF0aCBpZiB0aGUgaW1wb3J0IGlzIHJlc29sdmFibGVcbiAgICAgIGNvbnN0IHJlc29sdmVkID0gcmVzb2x2ZShpbXBvcnRQYXRoLCBjb250ZXh0KVxuICAgICAgaWYgKCFyZXNvbHZlZCB8fCByZWFjaGluZ0FsbG93ZWQobm9ybWFsaXplU2VwKHJlc29sdmVkKSkpIHJldHVybiBmYWxzZVxuXG4gICAgICAvLyB0aGlzIGltcG9ydCB3YXMgbm90IGFsbG93ZWQgYnkgdGhlIGFsbG93ZWQgcGF0aHMsIGFuZCByZWFjaGVzXG4gICAgICAvLyBzbyBpdCBpcyBhIHZpb2xhdGlvblxuICAgICAgcmV0dXJuIHRydWVcbiAgICB9XG5cbiAgICBmdW5jdGlvbiBjaGVja0ltcG9ydEZvclJlYWNoaW5nKGltcG9ydFBhdGgsIG5vZGUpIHtcbiAgICAgIGNvbnN0IHBvdGVudGlhbFZpb2xhdGlvblR5cGVzID0gWydwYXJlbnQnLCAnaW5kZXgnLCAnc2libGluZycsICdleHRlcm5hbCcsICdpbnRlcm5hbCddXG4gICAgICBpZiAocG90ZW50aWFsVmlvbGF0aW9uVHlwZXMuaW5kZXhPZihpbXBvcnRUeXBlKGltcG9ydFBhdGgsIGNvbnRleHQpKSAhPT0gLTEgJiZcbiAgICAgICAgaXNSZWFjaFZpb2xhdGlvbihpbXBvcnRQYXRoKVxuICAgICAgKSB7XG4gICAgICAgIGNvbnRleHQucmVwb3J0KHtcbiAgICAgICAgICBub2RlLFxuICAgICAgICAgIG1lc3NhZ2U6IGBSZWFjaGluZyB0byBcIiR7aW1wb3J0UGF0aH1cIiBpcyBub3QgYWxsb3dlZC5gLFxuICAgICAgICB9KVxuICAgICAgfVxuICAgIH1cblxuICAgIHJldHVybiB7XG4gICAgICBJbXBvcnREZWNsYXJhdGlvbihub2RlKSB7XG4gICAgICAgIGNoZWNrSW1wb3J0Rm9yUmVhY2hpbmcobm9kZS5zb3VyY2UudmFsdWUsIG5vZGUuc291cmNlKVxuICAgICAgfSxcbiAgICAgIEV4cG9ydEFsbERlY2xhcmF0aW9uKG5vZGUpIHtcbiAgICAgICAgY2hlY2tJbXBvcnRGb3JSZWFjaGluZyhub2RlLnNvdXJjZS52YWx1ZSwgbm9kZS5zb3VyY2UpXG4gICAgICB9LFxuICAgICAgRXhwb3J0TmFtZWREZWNsYXJhdGlvbihub2RlKSB7XG4gICAgICAgIGlmIChub2RlLnNvdXJjZSkge1xuICAgICAgICAgIGNoZWNrSW1wb3J0Rm9yUmVhY2hpbmcobm9kZS5zb3VyY2UudmFsdWUsIG5vZGUuc291cmNlKVxuICAgICAgICB9XG4gICAgICB9LFxuICAgICAgQ2FsbEV4cHJlc3Npb24obm9kZSkge1xuICAgICAgICBpZiAoaXNTdGF0aWNSZXF1aXJlKG5vZGUpKSB7XG4gICAgICAgICAgY29uc3QgWyBmaXJzdEFyZ3VtZW50IF0gPSBub2RlLmFyZ3VtZW50c1xuICAgICAgICAgIGNoZWNrSW1wb3J0Rm9yUmVhY2hpbmcoZmlyc3RBcmd1bWVudC52YWx1ZSwgZmlyc3RBcmd1bWVudClcbiAgICAgICAgfVxuICAgICAgfSxcbiAgICB9XG4gIH0sXG59XG4iXX0=