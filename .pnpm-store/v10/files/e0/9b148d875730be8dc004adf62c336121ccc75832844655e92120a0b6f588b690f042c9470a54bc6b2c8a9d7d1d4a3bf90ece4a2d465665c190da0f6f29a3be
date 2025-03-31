'use strict';var _slicedToArray = function () {function sliceIterator(arr, i) {var _arr = [];var _n = true;var _d = false;var _e = undefined;try {for (var _i = arr[Symbol.iterator](), _s; !(_n = (_s = _i.next()).done); _n = true) {_arr.push(_s.value);if (i && _arr.length === i) break;}} catch (err) {_d = true;_e = err;} finally {try {if (!_n && _i["return"]) _i["return"]();} finally {if (_d) throw _e;}}return _arr;}return function (arr, i) {if (Array.isArray(arr)) {return arr;} else if (Symbol.iterator in Object(arr)) {return sliceIterator(arr, i);} else {throw new TypeError("Invalid attempt to destructure non-iterable instance");}};}(); /**
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       * @fileOverview Ensures that no imported module imports the linted module.
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       * @author Ben Mosher
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       */

var _resolve = require('eslint-module-utils/resolve');var _resolve2 = _interopRequireDefault(_resolve);
var _builder = require('../exportMap/builder');var _builder2 = _interopRequireDefault(_builder);
var _scc = require('../scc');var _scc2 = _interopRequireDefault(_scc);
var _importType = require('../core/importType');
var _moduleVisitor = require('eslint-module-utils/moduleVisitor');var _moduleVisitor2 = _interopRequireDefault(_moduleVisitor);
var _docsUrl = require('../docsUrl');var _docsUrl2 = _interopRequireDefault(_docsUrl);function _interopRequireDefault(obj) {return obj && obj.__esModule ? obj : { 'default': obj };}function _toConsumableArray(arr) {if (Array.isArray(arr)) {for (var i = 0, arr2 = Array(arr.length); i < arr.length; i++) {arr2[i] = arr[i];}return arr2;} else {return Array.from(arr);}}

var traversed = new Set();

function routeString(route) {
  return route.map(function (s) {return String(s.value) + ':' + String(s.loc.start.line);}).join('=>');
}

module.exports = {
  meta: {
    type: 'suggestion',
    docs: {
      category: 'Static analysis',
      description: 'Forbid a module from importing a module with a dependency path back to itself.',
      url: (0, _docsUrl2['default'])('no-cycle') },

    schema: [(0, _moduleVisitor.makeOptionsSchema)({
      maxDepth: {
        anyOf: [
        {
          description: 'maximum dependency depth to traverse',
          type: 'integer',
          minimum: 1 },

        {
          'enum': ['∞'],
          type: 'string' }] },



      ignoreExternal: {
        description: 'ignore external modules',
        type: 'boolean',
        'default': false },

      allowUnsafeDynamicCyclicDependency: {
        description: 'Allow cyclic dependency if there is at least one dynamic import in the chain',
        type: 'boolean',
        'default': false },

      disableScc: {
        description: 'When true, don\'t calculate a strongly-connected-components graph. SCC is used to reduce the time-complexity of cycle detection, but adds overhead.',
        type: 'boolean',
        'default': false } })] },




  create: function () {function create(context) {
      var myPath = context.getPhysicalFilename ? context.getPhysicalFilename() : context.getFilename();
      if (myPath === '<text>') {return {};} // can't cycle-check a non-file

      var options = context.options[0] || {};
      var maxDepth = typeof options.maxDepth === 'number' ? options.maxDepth : Infinity;
      var ignoreModule = function () {function ignoreModule(name) {return options.ignoreExternal && (0, _importType.isExternalModule)(
          name,
          (0, _resolve2['default'])(name, context),
          context);}return ignoreModule;}();


      var scc = options.disableScc ? {} : _scc2['default'].get(myPath, context);

      function checkSourceValue(sourceNode, importer) {
        if (ignoreModule(sourceNode.value)) {
          return; // ignore external modules
        }
        if (
        options.allowUnsafeDynamicCyclicDependency && (
        // Ignore `import()`
        importer.type === 'ImportExpression'
        // `require()` calls are always checked (if possible)
        || importer.type === 'CallExpression' && importer.callee.name !== 'require'))

        {
          return; // cycle via dynamic import allowed by config
        }

        if (
        importer.type === 'ImportDeclaration' && (
        // import type { Foo } (TS and Flow)
        importer.importKind === 'type'
        // import { type Foo } (Flow)
        || importer.specifiers.every(function (_ref) {var importKind = _ref.importKind;return importKind === 'type';})))

        {
          return; // ignore type imports
        }

        var imported = _builder2['default'].get(sourceNode.value, context);

        if (imported == null) {
          return; // no-unresolved territory
        }

        if (imported.path === myPath) {
          return; // no-self-import territory
        }

        /* If we're in the same Strongly Connected Component,
           * Then there exists a path from each node in the SCC to every other node in the SCC,
           * Then there exists at least one path from them to us and from us to them,
           * Then we have a cycle between us.
           */
        var hasDependencyCycle = options.disableScc || scc[myPath] === scc[imported.path];
        if (!hasDependencyCycle) {
          return;
        }

        var untraversed = [{ mget: function () {function mget() {return imported;}return mget;}(), route: [] }];
        function detectCycle(_ref2) {var mget = _ref2.mget,route = _ref2.route;
          var m = mget();
          if (m == null) {return;}
          if (traversed.has(m.path)) {return;}
          traversed.add(m.path);var _iteratorNormalCompletion = true;var _didIteratorError = false;var _iteratorError = undefined;try {

            for (var _iterator = m.imports[Symbol.iterator](), _step; !(_iteratorNormalCompletion = (_step = _iterator.next()).done); _iteratorNormalCompletion = true) {var _ref3 = _step.value;var _ref4 = _slicedToArray(_ref3, 2);var path = _ref4[0];var _ref4$ = _ref4[1];var getter = _ref4$.getter;var declarations = _ref4$.declarations;
              // If we're in different SCCs, we can't have a circular dependency
              if (!options.disableScc && scc[myPath] !== scc[path]) {continue;}

              if (traversed.has(path)) {continue;}
              var toTraverse = [].concat(_toConsumableArray(declarations)).filter(function (_ref5) {var source = _ref5.source,isOnlyImportingTypes = _ref5.isOnlyImportingTypes;return !ignoreModule(source.value)
                // Ignore only type imports
                && !isOnlyImportingTypes;});


              /*
                                             If cyclic dependency is allowed via dynamic import, skip checking if any module is imported dynamically
                                             */
              if (options.allowUnsafeDynamicCyclicDependency && toTraverse.some(function (d) {return d.dynamic;})) {return;}

              /*
                                                                                                                             Only report as a cycle if there are any import declarations that are considered by
                                                                                                                             the rule. For example:
                                                                                                                              a.ts:
                                                                                                                             import { foo } from './b' // should not be reported as a cycle
                                                                                                                              b.ts:
                                                                                                                             import type { Bar } from './a'
                                                                                                                             */


              if (path === myPath && toTraverse.length > 0) {return true;}
              if (route.length + 1 < maxDepth) {var _iteratorNormalCompletion2 = true;var _didIteratorError2 = false;var _iteratorError2 = undefined;try {
                  for (var _iterator2 = toTraverse[Symbol.iterator](), _step2; !(_iteratorNormalCompletion2 = (_step2 = _iterator2.next()).done); _iteratorNormalCompletion2 = true) {var _ref6 = _step2.value;var source = _ref6.source;
                    untraversed.push({ mget: getter, route: route.concat(source) });
                  }} catch (err) {_didIteratorError2 = true;_iteratorError2 = err;} finally {try {if (!_iteratorNormalCompletion2 && _iterator2['return']) {_iterator2['return']();}} finally {if (_didIteratorError2) {throw _iteratorError2;}}}
              }
            }} catch (err) {_didIteratorError = true;_iteratorError = err;} finally {try {if (!_iteratorNormalCompletion && _iterator['return']) {_iterator['return']();}} finally {if (_didIteratorError) {throw _iteratorError;}}}
        }

        while (untraversed.length > 0) {
          var next = untraversed.shift(); // bfs!
          if (detectCycle(next)) {
            var message = next.route.length > 0 ? 'Dependency cycle via ' + String(
            routeString(next.route)) :
            'Dependency cycle detected.';
            context.report(importer, message);
            return;
          }
        }
      }

      return Object.assign((0, _moduleVisitor2['default'])(checkSourceValue, context.options[0]), {
        'Program:exit': function () {function ProgramExit() {
            traversed.clear();
          }return ProgramExit;}() });

    }return create;}() };
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIi4uLy4uL3NyYy9ydWxlcy9uby1jeWNsZS5qcyJdLCJuYW1lcyI6WyJ0cmF2ZXJzZWQiLCJTZXQiLCJyb3V0ZVN0cmluZyIsInJvdXRlIiwibWFwIiwicyIsInZhbHVlIiwibG9jIiwic3RhcnQiLCJsaW5lIiwiam9pbiIsIm1vZHVsZSIsImV4cG9ydHMiLCJtZXRhIiwidHlwZSIsImRvY3MiLCJjYXRlZ29yeSIsImRlc2NyaXB0aW9uIiwidXJsIiwic2NoZW1hIiwibWF4RGVwdGgiLCJhbnlPZiIsIm1pbmltdW0iLCJpZ25vcmVFeHRlcm5hbCIsImFsbG93VW5zYWZlRHluYW1pY0N5Y2xpY0RlcGVuZGVuY3kiLCJkaXNhYmxlU2NjIiwiY3JlYXRlIiwiY29udGV4dCIsIm15UGF0aCIsImdldFBoeXNpY2FsRmlsZW5hbWUiLCJnZXRGaWxlbmFtZSIsIm9wdGlvbnMiLCJJbmZpbml0eSIsImlnbm9yZU1vZHVsZSIsIm5hbWUiLCJzY2MiLCJTdHJvbmdseUNvbm5lY3RlZENvbXBvbmVudHNCdWlsZGVyIiwiZ2V0IiwiY2hlY2tTb3VyY2VWYWx1ZSIsInNvdXJjZU5vZGUiLCJpbXBvcnRlciIsImNhbGxlZSIsImltcG9ydEtpbmQiLCJzcGVjaWZpZXJzIiwiZXZlcnkiLCJpbXBvcnRlZCIsIkV4cG9ydE1hcEJ1aWxkZXIiLCJwYXRoIiwiaGFzRGVwZW5kZW5jeUN5Y2xlIiwidW50cmF2ZXJzZWQiLCJtZ2V0IiwiZGV0ZWN0Q3ljbGUiLCJtIiwiaGFzIiwiYWRkIiwiaW1wb3J0cyIsImdldHRlciIsImRlY2xhcmF0aW9ucyIsInRvVHJhdmVyc2UiLCJmaWx0ZXIiLCJzb3VyY2UiLCJpc09ubHlJbXBvcnRpbmdUeXBlcyIsInNvbWUiLCJkIiwiZHluYW1pYyIsImxlbmd0aCIsInB1c2giLCJjb25jYXQiLCJuZXh0Iiwic2hpZnQiLCJtZXNzYWdlIiwicmVwb3J0IiwiT2JqZWN0IiwiYXNzaWduIiwiY2xlYXIiXSwibWFwcGluZ3MiOiJzb0JBQUE7Ozs7O0FBS0Es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L0IsUUFBZixFQUF5QjhCLE9BQXpCO0FBQ0E7QUFDRDtBQUNGO0FBQ0Y7O0FBRUQsYUFBT0UsT0FBT0MsTUFBUCxDQUFjLGdDQUFjbkMsZ0JBQWQsRUFBZ0NYLFFBQVFJLE9BQVIsQ0FBZ0IsQ0FBaEIsQ0FBaEMsQ0FBZCxFQUFtRTtBQUN4RSxzQkFEd0Usc0NBQ3ZEO0FBQ2YvQixzQkFBVTBFLEtBQVY7QUFDRCxXQUh1RSx3QkFBbkUsQ0FBUDs7QUFLRCxLQTlKYyxtQkFBakIiLCJmaWxlIjoibm8tY3ljbGUuanMiLCJzb3VyY2VzQ29udGVudCI6WyIvKipcbiAqIEBmaWxlT3ZlcnZpZXcgRW5zdXJlcyB0aGF0IG5vIGltcG9ydGVkIG1vZHVsZSBpbXBvcnRzIHRoZSBsaW50ZWQgbW9kdWxlLlxuICogQGF1dGhvciBCZW4gTW9zaGVyXG4gKi9cblxuaW1wb3J0IHJlc29sdmUgZnJvbSAnZXNsaW50LW1vZHVsZS11dGlscy9yZXNvbHZlJztcbmltcG9ydCBFeHBvcnRNYXBCdWlsZGVyIGZyb20gJy4uL2V4cG9ydE1hcC9idWlsZGVyJztcbmltcG9ydCBTdHJvbmdseUNvbm5lY3RlZENvbXBvbmVudHNCdWlsZGVyIGZyb20gJy4uL3NjYyc7XG5pbXBvcnQgeyBpc0V4dGVybmFsTW9kdWxlIH0gZnJvbSAnLi4vY29yZS9pbXBvcnRUeXBlJztcbmltcG9ydCBtb2R1bGVWaXNpdG9yLCB7IG1ha2VPcHRpb25zU2NoZW1hIH0gZnJvbSAnZXNsaW50LW1vZHVsZS11dGlscy9tb2R1bGVWaXNpdG9yJztcbmltcG9ydCBkb2NzVXJsIGZyb20gJy4uL2RvY3NVcmwnO1xuXG5jb25zdCB0cmF2ZXJzZWQgPSBuZXcgU2V0KCk7XG5cbmZ1bmN0aW9uIHJvdXRlU3RyaW5nKHJvdXRlKSB7XG4gIHJldHVybiByb3V0ZS5tYXAoKHMpID0+IGAke3MudmFsdWV9OiR7cy5sb2Muc3RhcnQubGluZX1gKS5qb2luKCc9PicpO1xufVxuXG5tb2R1bGUuZXhwb3J0cyA9IHtcbiAgbWV0YToge1xuICAgIHR5cGU6ICdzdWdnZXN0aW9uJyxcbiAgICBkb2NzOiB7XG4gICAgICBjYXRlZ29yeTogJ1N0YXRpYyBhbmFseXNpcycsXG4gICAgICBkZXNjcmlwdGlvbjogJ0ZvcmJpZCBhIG1vZHVsZSBmcm9tIGltcG9ydGluZyBhIG1vZHVsZSB3aXRoIGEgZGVwZW5kZW5jeSBwYXRoIGJhY2sgdG8gaXRzZWxmLicsXG4gICAgICB1cmw6IGRvY3NVcmwoJ25vLWN5Y2xlJyksXG4gICAgfSxcbiAgICBzY2hlbWE6IFttYWtlT3B0aW9uc1NjaGVtYSh7XG4gICAgICBtYXhEZXB0aDoge1xuICAgICAgICBhbnlPZjogW1xuICAgICAgICAgIHtcbiAgICAgICAgICAgIGRlc2NyaXB0aW9uOiAnbWF4aW11bSBkZXBlbmRlbmN5IGRlcHRoIHRvIHRyYXZlcnNlJyxcbiAgICAgICAgICAgIHR5cGU6ICdpbnRlZ2VyJyxcbiAgICAgICAgICAgIG1pbmltdW06IDEsXG4gICAgICAgICAgfSxcbiAgICAgICAgICB7XG4gICAgICAgICAgICBlbnVtOiBbJ+KIniddLFxuICAgICAgICAgICAgdHlwZTogJ3N0cmluZycsXG4gICAgICAgICAgfSxcbiAgICAgICAgXSxcbiAgICAgIH0sXG4gICAgICBpZ25vcmVFeHRlcm5hbDoge1xuICAgICAgICBkZXNjcmlwdGlvbjogJ2lnbm9yZSBleHRlcm5hbCBtb2R1bGVzJyxcbiAgICAgICAgdHlwZTogJ2Jvb2xlYW4nLFxuICAgICAgICBkZWZhdWx0OiBmYWxzZSxcbiAgICAgIH0sXG4gICAgICBhbGxvd1Vuc2FmZUR5bmFtaWNDeWNsaWNEZXBlbmRlbmN5OiB7XG4gICAgICAgIGRlc2NyaXB0aW9uOiAnQWxsb3cgY3ljbGljIGRlcGVuZGVuY3kgaWYgdGhlcmUgaXMgYXQgbGVhc3Qgb25lIGR5bmFtaWMgaW1wb3J0IGluIHRoZSBjaGFpbicsXG4gICAgICAgIHR5cGU6ICdib29sZWFuJyxcbiAgICAgICAgZGVmYXVsdDogZmFsc2UsXG4gICAgICB9LFxuICAgICAgZGlzYWJsZVNjYzoge1xuICAgICAgICBkZXNjcmlwdGlvbjogJ1doZW4gdHJ1ZSwgZG9uXFwndCBjYWxjdWxhdGUgYSBzdHJvbmdseS1jb25uZWN0ZWQtY29tcG9uZW50cyBncmFwaC4gU0NDIGlzIHVzZWQgdG8gcmVkdWNlIHRoZSB0aW1lLWNvbXBsZXhpdHkgb2YgY3ljbGUgZGV0ZWN0aW9uLCBidXQgYWRkcyBvdmVyaGVhZC4nLFxuICAgICAgICB0eXBlOiAnYm9vbGVhbicsXG4gICAgICAgIGRlZmF1bHQ6IGZhbHNlLFxuICAgICAgfSxcbiAgICB9KV0sXG4gIH0sXG5cbiAgY3JlYXRlKGNvbnRleHQpIHtcbiAgICBjb25zdCBteVBhdGggPSBjb250ZXh0LmdldFBoeXNpY2FsRmlsZW5hbWUgPyBjb250ZXh0LmdldFBoeXNpY2FsRmlsZW5hbWUoKSA6IGNvbnRleHQuZ2V0RmlsZW5hbWUoKTtcbiAgICBpZiAobXlQYXRoID09PSAnPHRleHQ+JykgeyByZXR1cm4ge307IH0gLy8gY2FuJ3QgY3ljbGUtY2hlY2sgYSBub24tZmlsZVxuXG4gICAgY29uc3Qgb3B0aW9ucyA9IGNvbnRleHQub3B0aW9uc1swXSB8fCB7fTtcbiAgICBjb25zdCBtYXhEZXB0aCA9IHR5cGVvZiBvcHRpb25zLm1heERlcHRoID09PSAnbnVtYmVyJyA/IG9wdGlvbnMubWF4RGVwdGggOiBJbmZpbml0eTtcbiAgICBjb25zdCBpZ25vcmVNb2R1bGUgPSAobmFtZSkgPT4gb3B0aW9ucy5pZ25vcmVFeHRlcm5hbCAmJiBpc0V4dGVybmFsTW9kdWxlKFxuICAgICAgbmFtZSxcbiAgICAgIHJlc29sdmUobmFtZSwgY29udGV4dCksXG4gICAgICBjb250ZXh0LFxuICAgICk7XG5cbiAgICBjb25zdCBzY2MgPSBvcHRpb25zLmRpc2FibGVTY2MgPyB7fSA6IFN0cm9uZ2x5Q29ubmVjdGVkQ29tcG9uZW50c0J1aWxkZXIuZ2V0KG15UGF0aCwgY29udGV4dCk7XG5cbiAgICBmdW5jdGlvbiBjaGVja1NvdXJjZVZhbHVlKHNvdXJjZU5vZGUsIGltcG9ydGVyKSB7XG4gICAgICBpZiAoaWdub3JlTW9kdWxlKHNvdXJjZU5vZGUudmFsdWUpKSB7XG4gICAgICAgIHJldHVybjsgLy8gaWdub3JlIGV4dGVybmFsIG1vZHVsZXNcbiAgICAgIH1cbiAgICAgIGlmIChcbiAgICAgICAgb3B0aW9ucy5hbGxvd1Vuc2FmZUR5bmFtaWNDeWNsaWNEZXBlbmRlbmN5ICYmIChcbiAgICAgICAgICAvLyBJZ25vcmUgYGltcG9ydCgpYFxuICAgICAgICAgIGltcG9ydGVyLnR5cGUgPT09ICdJbXBvcnRFeHByZXNzaW9uJ1xuICAgICAgICAgIC8vIGByZXF1aXJlKClgIGNhbGxzIGFyZSBhbHdheXMgY2hlY2tlZCAoaWYgcG9zc2libGUpXG4gICAgICAgICAgfHwgaW1wb3J0ZXIudHlwZSA9PT0gJ0NhbGxFeHByZXNzaW9uJyAmJiBpbXBvcnRlci5jYWxsZWUubmFtZSAhPT0gJ3JlcXVpcmUnXG4gICAgICAgIClcbiAgICAgICkge1xuICAgICAgICByZXR1cm47IC8vIGN5Y2xlIHZpYSBkeW5hbWljIGltcG9ydCBhbGxvd2VkIGJ5IGNvbmZpZ1xuICAgICAgfVxuXG4gICAgICBpZiAoXG4gICAgICAgIGltcG9ydGVyLnR5cGUgPT09ICdJbXBvcnREZWNsYXJhdGlvbicgJiYgKFxuICAgICAgICAgIC8vIGltcG9ydCB0eXBlIHsgRm9vIH0gKFRTIGFuZCBGbG93KVxuICAgICAgICAgIGltcG9ydGVyLmltcG9ydEtpbmQgPT09ICd0eXBlJ1xuICAgICAgICAgIC8vIGltcG9ydCB7IHR5cGUgRm9vIH0gKEZsb3cpXG4gICAgICAgICAgfHwgaW1wb3J0ZXIuc3BlY2lmaWVycy5ldmVyeSgoeyBpbXBvcnRLaW5kIH0pID0+IGltcG9ydEtpbmQgPT09ICd0eXBlJylcbiAgICAgICAgKVxuICAgICAgKSB7XG4gICAgICAgIHJldHVybjsgLy8gaWdub3JlIHR5cGUgaW1wb3J0c1xuICAgICAgfVxuXG4gICAgICBjb25zdCBpbXBvcnRlZCA9IEV4cG9ydE1hcEJ1aWxkZXIuZ2V0KHNvdXJjZU5vZGUudmFsdWUsIGNvbnRleHQpO1xuXG4gICAgICBpZiAoaW1wb3J0ZWQgPT0gbnVsbCkge1xuICAgICAgICByZXR1cm47ICAvLyBuby11bnJlc29sdmVkIHRlcnJpdG9yeVxuICAgICAgfVxuXG4gICAgICBpZiAoaW1wb3J0ZWQucGF0aCA9PT0gbXlQYXRoKSB7XG4gICAgICAgIHJldHVybjsgIC8vIG5vLXNlbGYtaW1wb3J0IHRlcnJpdG9yeVxuICAgICAgfVxuXG4gICAgICAvKiBJZiB3ZSdyZSBpbiB0aGUgc2FtZSBTdHJvbmdseSBDb25uZWN0ZWQgQ29tcG9uZW50LFxuICAgICAgICogVGhlbiB0aGVyZSBleGlzdHMgYSBwYXRoIGZyb20gZWFjaCBub2RlIGluIHRoZSBTQ0MgdG8gZXZlcnkgb3RoZXIgbm9kZSBpbiB0aGUgU0NDLFxuICAgICAgICogVGhlbiB0aGVyZSBleGlzdHMgYXQgbGVhc3Qgb25lIHBhdGggZnJvbSB0aGVtIHRvIHVzIGFuZCBmcm9tIHVzIHRvIHRoZW0sXG4gICAgICAgKiBUaGVuIHdlIGhhdmUgYSBjeWNsZSBiZXR3ZWVuIHVzLlxuICAgICAgICovXG4gICAgICBjb25zdCBoYXNEZXBlbmRlbmN5Q3ljbGUgPSBvcHRpb25zLmRpc2FibGVTY2MgfHwgc2NjW215UGF0aF0gPT09IHNjY1tpbXBvcnRlZC5wYXRoXTtcbiAgICAgIGlmICghaGFzRGVwZW5kZW5jeUN5Y2xlKSB7XG4gICAgICAgIHJldHVybjtcbiAgICAgIH1cblxuICAgICAgY29uc3QgdW50cmF2ZXJzZWQgPSBbeyBtZ2V0OiAoKSA9PiBpbXBvcnRlZCwgcm91dGU6IFtdIH1dO1xuICAgICAgZnVuY3Rpb24gZGV0ZWN0Q3ljbGUoeyBtZ2V0LCByb3V0ZSB9KSB7XG4gICAgICAgIGNvbnN0IG0gPSBtZ2V0KCk7XG4gICAgICAgIGlmIChtID09IG51bGwpIHsgcmV0dXJuOyB9XG4gICAgICAgIGlmICh0cmF2ZXJzZWQuaGFzKG0ucGF0aCkpIHsgcmV0dXJuOyB9XG4gICAgICAgIHRyYXZlcnNlZC5hZGQobS5wYXRoKTtcblxuICAgICAgICBmb3IgKGNvbnN0IFtwYXRoLCB7IGdldHRlciwgZGVjbGFyYXRpb25zIH1dIG9mIG0uaW1wb3J0cykge1xuICAgICAgICAgIC8vIElmIHdlJ3JlIGluIGRpZmZlcmVudCBTQ0NzLCB3ZSBjYW4ndCBoYXZlIGEgY2lyY3VsYXIgZGVwZW5kZW5jeVxuICAgICAgICAgIGlmICghb3B0aW9ucy5kaXNhYmxlU2NjICYmIHNjY1tteVBhdGhdICE9PSBzY2NbcGF0aF0pIHsgY29udGludWU7IH1cblxuICAgICAgICAgIGlmICh0cmF2ZXJzZWQuaGFzKHBhdGgpKSB7IGNvbnRpbnVlOyB9XG4gICAgICAgICAgY29uc3QgdG9UcmF2ZXJzZSA9IFsuLi5kZWNsYXJhdGlvbnNdLmZpbHRlcigoeyBzb3VyY2UsIGlzT25seUltcG9ydGluZ1R5cGVzIH0pID0+ICFpZ25vcmVNb2R1bGUoc291cmNlLnZhbHVlKVxuICAgICAgICAgICAgLy8gSWdub3JlIG9ubHkgdHlwZSBpbXBvcnRzXG4gICAgICAgICAgICAmJiAhaXNPbmx5SW1wb3J0aW5nVHlwZXMsXG4gICAgICAgICAgKTtcblxuICAgICAgICAgIC8qXG4gICAgICAgICAgSWYgY3ljbGljIGRlcGVuZGVuY3kgaXMgYWxsb3dlZCB2aWEgZHluYW1pYyBpbXBvcnQsIHNraXAgY2hlY2tpbmcgaWYgYW55IG1vZHVsZSBpcyBpbXBvcnRlZCBkeW5hbWljYWxseVxuICAgICAgICAgICovXG4gICAgICAgICAgaWYgKG9wdGlvbnMuYWxsb3dVbnNhZmVEeW5hbWljQ3ljbGljRGVwZW5kZW5jeSAmJiB0b1RyYXZlcnNlLnNvbWUoKGQpID0+IGQuZHluYW1pYykpIHsgcmV0dXJuOyB9XG5cbiAgICAgICAgICAvKlxuICAgICAgICAgIE9ubHkgcmVwb3J0IGFzIGEgY3ljbGUgaWYgdGhlcmUgYXJlIGFueSBpbXBvcnQgZGVjbGFyYXRpb25zIHRoYXQgYXJlIGNvbnNpZGVyZWQgYnlcbiAgICAgICAgICB0aGUgcnVsZS4gRm9yIGV4YW1wbGU6XG5cbiAgICAgICAgICBhLnRzOlxuICAgICAgICAgIGltcG9ydCB7IGZvbyB9IGZyb20gJy4vYicgLy8gc2hvdWxkIG5vdCBiZSByZXBvcnRlZCBhcyBhIGN5Y2xlXG5cbiAgICAgICAgICBiLnRzOlxuICAgICAgICAgIGltcG9ydCB0eXBlIHsgQmFyIH0gZnJvbSAnLi9hJ1xuICAgICAgICAgICovXG4gICAgICAgICAgaWYgKHBhdGggPT09IG15UGF0aCAmJiB0b1RyYXZlcnNlLmxlbmd0aCA+IDApIHsgcmV0dXJuIHRydWU7IH1cbiAgICAgICAgICBpZiAocm91dGUubGVuZ3RoICsgMSA8IG1heERlcHRoKSB7XG4gICAgICAgICAgICBmb3IgKGNvbnN0IHsgc291cmNlIH0gb2YgdG9UcmF2ZXJzZSkge1xuICAgICAgICAgICAgICB1bnRyYXZlcnNlZC5wdXNoKHsgbWdldDogZ2V0dGVyLCByb3V0ZTogcm91dGUuY29uY2F0KHNvdXJjZSkgfSk7XG4gICAgICAgICAgICB9XG4gICAgICAgICAgfVxuICAgICAgICB9XG4gICAgICB9XG5cbiAgICAgIHdoaWxlICh1bnRyYXZlcnNlZC5sZW5ndGggPiAwKSB7XG4gICAgICAgIGNvbnN0IG5leHQgPSB1bnRyYXZlcnNlZC5zaGlmdCgpOyAvLyBiZnMhXG4gICAgICAgIGlmIChkZXRlY3RDeWNsZShuZXh0KSkge1xuICAgICAgICAgIGNvbnN0IG1lc3NhZ2UgPSBuZXh0LnJvdXRlLmxlbmd0aCA+IDBcbiAgICAgICAgICAgID8gYERlcGVuZGVuY3kgY3ljbGUgdmlhICR7cm91dGVTdHJpbmcobmV4dC5yb3V0ZSl9YFxuICAgICAgICAgICAgOiAnRGVwZW5kZW5jeSBjeWNsZSBkZXRlY3RlZC4nO1xuICAgICAgICAgIGNvbnRleHQucmVwb3J0KGltcG9ydGVyLCBtZXNzYWdlKTtcbiAgICAgICAgICByZXR1cm47XG4gICAgICAgIH1cbiAgICAgIH1cbiAgICB9XG5cbiAgICByZXR1cm4gT2JqZWN0LmFzc2lnbihtb2R1bGVWaXNpdG9yKGNoZWNrU291cmNlVmFsdWUsIGNvbnRleHQub3B0aW9uc1swXSksIHtcbiAgICAgICdQcm9ncmFtOmV4aXQnKCkge1xuICAgICAgICB0cmF2ZXJzZWQuY2xlYXIoKTtcbiAgICAgIH0sXG4gICAgfSk7XG4gIH0sXG59O1xuIl19