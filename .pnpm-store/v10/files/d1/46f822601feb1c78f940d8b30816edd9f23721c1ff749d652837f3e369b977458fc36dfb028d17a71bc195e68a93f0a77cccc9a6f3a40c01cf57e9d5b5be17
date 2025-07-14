'use strict';Object.defineProperty(exports, "__esModule", { value: true });var _createClass = function () {function defineProperties(target, props) {for (var i = 0; i < props.length; i++) {var descriptor = props[i];descriptor.enumerable = descriptor.enumerable || false;descriptor.configurable = true;if ("value" in descriptor) descriptor.writable = true;Object.defineProperty(target, descriptor.key, descriptor);}}return function (Constructor, protoProps, staticProps) {if (protoProps) defineProperties(Constructor.prototype, protoProps);if (staticProps) defineProperties(Constructor, staticProps);return Constructor;};}();var _scc = require('@rtsao/scc');var _scc2 = _interopRequireDefault(_scc);
var _hash = require('eslint-module-utils/hash');
var _resolve = require('eslint-module-utils/resolve');var _resolve2 = _interopRequireDefault(_resolve);
var _builder = require('./exportMap/builder');var _builder2 = _interopRequireDefault(_builder);
var _childContext = require('./exportMap/childContext');var _childContext2 = _interopRequireDefault(_childContext);function _interopRequireDefault(obj) {return obj && obj.__esModule ? obj : { 'default': obj };}function _toConsumableArray(arr) {if (Array.isArray(arr)) {for (var i = 0, arr2 = Array(arr.length); i < arr.length; i++) {arr2[i] = arr[i];}return arr2;} else {return Array.from(arr);}}function _classCallCheck(instance, Constructor) {if (!(instance instanceof Constructor)) {throw new TypeError("Cannot call a class as a function");}}

var cache = new Map();var

StronglyConnectedComponentsBuilder = function () {function StronglyConnectedComponentsBuilder() {_classCallCheck(this, StronglyConnectedComponentsBuilder);}_createClass(StronglyConnectedComponentsBuilder, null, [{ key: 'clearCache', value: function () {function clearCache()
      {
        cache = new Map();
      }return clearCache;}() }, { key: 'get', value: function () {function get(

      source, context) {
        var path = (0, _resolve2['default'])(source, context);
        if (path == null) {return null;}
        return StronglyConnectedComponentsBuilder['for']((0, _childContext2['default'])(path, context));
      }return get;}() }, { key: 'for', value: function () {function _for(

      context) {
        var cacheKey = context.cacheKey || (0, _hash.hashObject)(context).digest('hex');
        if (cache.has(cacheKey)) {
          return cache.get(cacheKey);
        }
        var scc = StronglyConnectedComponentsBuilder.calculate(context);
        cache.set(cacheKey, scc);
        return scc;
      }return _for;}() }, { key: 'calculate', value: function () {function calculate(

      context) {
        var exportMap = _builder2['default']['for'](context);
        var adjacencyList = this.exportMapToAdjacencyList(exportMap);
        var calculatedScc = (0, _scc2['default'])(adjacencyList);
        return StronglyConnectedComponentsBuilder.calculatedSccToPlainObject(calculatedScc);
      }return calculate;}()

    /** @returns {Map<string, Set<string>>} for each dep, what are its direct deps */ }, { key: 'exportMapToAdjacencyList', value: function () {function exportMapToAdjacencyList(
      initialExportMap) {
        var adjacencyList = new Map();
        // BFS
        function visitNode(exportMap) {
          if (!exportMap) {
            return;
          }
          exportMap.imports.forEach(function (v, importedPath) {
            var from = exportMap.path;
            var to = importedPath;

            // Ignore type-only imports, because we care only about SCCs of value imports
            var toTraverse = [].concat(_toConsumableArray(v.declarations)).filter(function (_ref) {var isOnlyImportingTypes = _ref.isOnlyImportingTypes;return !isOnlyImportingTypes;});
            if (toTraverse.length === 0) {return;}

            if (!adjacencyList.has(from)) {
              adjacencyList.set(from, new Set());
            }

            if (adjacencyList.get(from).has(to)) {
              return; // prevent endless loop
            }
            adjacencyList.get(from).add(to);
            visitNode(v.getter());
          });
        }
        visitNode(initialExportMap);
        // Fill gaps
        adjacencyList.forEach(function (values) {
          values.forEach(function (value) {
            if (!adjacencyList.has(value)) {
              adjacencyList.set(value, new Set());
            }
          });
        });
        return adjacencyList;
      }return exportMapToAdjacencyList;}()

    /** @returns {Record<string, number>} for each key, its SCC's index */ }, { key: 'calculatedSccToPlainObject', value: function () {function calculatedSccToPlainObject(
      sccs) {
        var obj = {};
        sccs.forEach(function (scc, index) {
          scc.forEach(function (node) {
            obj[node] = index;
          });
        });
        return obj;
      }return calculatedSccToPlainObject;}() }]);return StronglyConnectedComponentsBuilder;}();exports['default'] = StronglyConnectedComponentsBuilder;
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIi4uL3NyYy9zY2MuanMiXSwibmFtZXMiOlsiY2FjaGUiLCJNYXAiLCJTdHJvbmdseUNvbm5lY3RlZENvbXBvbmVudHNCdWlsZGVyIiwic291cmNlIiwiY29udGV4dCIsInBhdGgiLCJjYWNoZUtleSIsImRpZ2VzdCIsImhhcyIsImdldCIsInNjYyIsImNhbGN1bGF0ZSIsInNldCIsImV4cG9ydE1hcCIsIkV4cG9ydE1hcEJ1aWxkZXIiLCJhZGphY2VuY3lMaXN0IiwiZXhwb3J0TWFwVG9BZGphY2VuY3lMaXN0IiwiY2FsY3VsYXRlZFNjYyIsImNhbGN1bGF0ZWRTY2NUb1BsYWluT2JqZWN0IiwiaW5pdGlhbEV4cG9ydE1hcCIsInZpc2l0Tm9kZSIsImltcG9ydHMiLCJmb3JFYWNoIiwidiIsImltcG9ydGVkUGF0aCIsImZyb20iLCJ0byIsInRvVHJhdmVyc2UiLCJkZWNsYXJhdGlvbnMiLCJmaWx0ZXIiLCJpc09ubHlJbXBvcnRpbmdUeXBlcyIsImxlbmd0aCIsIlNldCIsImFkZCIsImdldHRlciIsInZhbHVlcyIsInZhbHVlIiwic2NjcyIsIm9iaiIsImluZGV4Iiwibm9kZSJdLCJtYXBwaW5ncyI6ImduQkFBQSxpQztBQUNBO0FBQ0Esc0Q7QUFDQSw4QztBQUNBLHdEOztBQUVBLElBQUlBLFFBQVEsSUFBSUMsR0FBSixFQUFaLEM7O0FBRXFCQyxrQztBQUNDO0FBQ2xCRixnQkFBUSxJQUFJQyxHQUFKLEVBQVI7QUFDRCxPOztBQUVVRSxZLEVBQVFDLE8sRUFBUztBQUMxQixZQUFNQyxPQUFPLDBCQUFRRixNQUFSLEVBQWdCQyxPQUFoQixDQUFiO0FBQ0EsWUFBSUMsUUFBUSxJQUFaLEVBQWtCLENBQUUsT0FBTyxJQUFQLENBQWM7QUFDbEMsZUFBT0gsMENBQXVDLCtCQUFhRyxJQUFiLEVBQW1CRCxPQUFuQixDQUF2QyxDQUFQO0FBQ0QsTzs7QUFFVUEsYSxFQUFTO0FBQ2xCLFlBQU1FLFdBQVdGLFFBQVFFLFFBQVIsSUFBb0Isc0JBQVdGLE9BQVgsRUFBb0JHLE1BQXBCLENBQTJCLEtBQTNCLENBQXJDO0FBQ0EsWUFBSVAsTUFBTVEsR0FBTixDQUFVRixRQUFWLENBQUosRUFBeUI7QUFDdkIsaUJBQU9OLE1BQU1TLEdBQU4sQ0FBVUgsUUFBVixDQUFQO0FBQ0Q7QUFDRCxZQUFNSSxNQUFNUixtQ0FBbUNTLFNBQW5DLENBQTZDUCxPQUE3QyxDQUFaO0FBQ0FKLGNBQU1ZLEdBQU4sQ0FBVU4sUUFBVixFQUFvQkksR0FBcEI7QUFDQSxlQUFPQSxHQUFQO0FBQ0QsTzs7QUFFZ0JOLGEsRUFBUztBQUN4QixZQUFNUyxZQUFZQyw0QkFBcUJWLE9BQXJCLENBQWxCO0FBQ0EsWUFBTVcsZ0JBQWdCLEtBQUtDLHdCQUFMLENBQThCSCxTQUE5QixDQUF0QjtBQUNBLFlBQU1JLGdCQUFnQixzQkFBYUYsYUFBYixDQUF0QjtBQUNBLGVBQU9iLG1DQUFtQ2dCLDBCQUFuQyxDQUE4REQsYUFBOUQsQ0FBUDtBQUNELE87O0FBRUQscUY7QUFDZ0NFLHNCLEVBQWtCO0FBQ2hELFlBQU1KLGdCQUFnQixJQUFJZCxHQUFKLEVBQXRCO0FBQ0E7QUFDQSxpQkFBU21CLFNBQVQsQ0FBbUJQLFNBQW5CLEVBQThCO0FBQzVCLGNBQUksQ0FBQ0EsU0FBTCxFQUFnQjtBQUNkO0FBQ0Q7QUFDREEsb0JBQVVRLE9BQVYsQ0FBa0JDLE9BQWxCLENBQTBCLFVBQUNDLENBQUQsRUFBSUMsWUFBSixFQUFxQjtBQUM3QyxnQkFBTUMsT0FBT1osVUFBVVIsSUFBdkI7QUFDQSxnQkFBTXFCLEtBQUtGLFlBQVg7O0FBRUE7QUFDQSxnQkFBTUcsYUFBYSw2QkFBSUosRUFBRUssWUFBTixHQUFvQkMsTUFBcEIsQ0FBMkIscUJBQUdDLG9CQUFILFFBQUdBLG9CQUFILFFBQThCLENBQUNBLG9CQUEvQixFQUEzQixDQUFuQjtBQUNBLGdCQUFJSCxXQUFXSSxNQUFYLEtBQXNCLENBQTFCLEVBQTZCLENBQUUsT0FBUzs7QUFFeEMsZ0JBQUksQ0FBQ2hCLGNBQWNQLEdBQWQsQ0FBa0JpQixJQUFsQixDQUFMLEVBQThCO0FBQzVCViw0QkFBY0gsR0FBZCxDQUFrQmEsSUFBbEIsRUFBd0IsSUFBSU8sR0FBSixFQUF4QjtBQUNEOztBQUVELGdCQUFJakIsY0FBY04sR0FBZCxDQUFrQmdCLElBQWxCLEVBQXdCakIsR0FBeEIsQ0FBNEJrQixFQUE1QixDQUFKLEVBQXFDO0FBQ25DLHFCQURtQyxDQUMzQjtBQUNUO0FBQ0RYLDBCQUFjTixHQUFkLENBQWtCZ0IsSUFBbEIsRUFBd0JRLEdBQXhCLENBQTRCUCxFQUE1QjtBQUNBTixzQkFBVUcsRUFBRVcsTUFBRixFQUFWO0FBQ0QsV0FqQkQ7QUFrQkQ7QUFDRGQsa0JBQVVELGdCQUFWO0FBQ0E7QUFDQUosc0JBQWNPLE9BQWQsQ0FBc0IsVUFBQ2EsTUFBRCxFQUFZO0FBQ2hDQSxpQkFBT2IsT0FBUCxDQUFlLFVBQUNjLEtBQUQsRUFBVztBQUN4QixnQkFBSSxDQUFDckIsY0FBY1AsR0FBZCxDQUFrQjRCLEtBQWxCLENBQUwsRUFBK0I7QUFDN0JyQiw0QkFBY0gsR0FBZCxDQUFrQndCLEtBQWxCLEVBQXlCLElBQUlKLEdBQUosRUFBekI7QUFDRDtBQUNGLFdBSkQ7QUFLRCxTQU5EO0FBT0EsZUFBT2pCLGFBQVA7QUFDRCxPOztBQUVELDBFO0FBQ2tDc0IsVSxFQUFNO0FBQ3RDLFlBQU1DLE1BQU0sRUFBWjtBQUNBRCxhQUFLZixPQUFMLENBQWEsVUFBQ1osR0FBRCxFQUFNNkIsS0FBTixFQUFnQjtBQUMzQjdCLGNBQUlZLE9BQUosQ0FBWSxVQUFDa0IsSUFBRCxFQUFVO0FBQ3BCRixnQkFBSUUsSUFBSixJQUFZRCxLQUFaO0FBQ0QsV0FGRDtBQUdELFNBSkQ7QUFLQSxlQUFPRCxHQUFQO0FBQ0QsTyw2R0E1RWtCcEMsa0MiLCJmaWxlIjoic2NjLmpzIiwic291cmNlc0NvbnRlbnQiOlsiaW1wb3J0IGNhbGN1bGF0ZVNjYyBmcm9tICdAcnRzYW8vc2NjJztcbmltcG9ydCB7IGhhc2hPYmplY3QgfSBmcm9tICdlc2xpbnQtbW9kdWxlLXV0aWxzL2hhc2gnO1xuaW1wb3J0IHJlc29sdmUgZnJvbSAnZXNsaW50LW1vZHVsZS11dGlscy9yZXNvbHZlJztcbmltcG9ydCBFeHBvcnRNYXBCdWlsZGVyIGZyb20gJy4vZXhwb3J0TWFwL2J1aWxkZXInO1xuaW1wb3J0IGNoaWxkQ29udGV4dCBmcm9tICcuL2V4cG9ydE1hcC9jaGlsZENvbnRleHQnO1xuXG5sZXQgY2FjaGUgPSBuZXcgTWFwKCk7XG5cbmV4cG9ydCBkZWZhdWx0IGNsYXNzIFN0cm9uZ2x5Q29ubmVjdGVkQ29tcG9uZW50c0J1aWxkZXIge1xuICBzdGF0aWMgY2xlYXJDYWNoZSgpIHtcbiAgICBjYWNoZSA9IG5ldyBNYXAoKTtcbiAgfVxuXG4gIHN0YXRpYyBnZXQoc291cmNlLCBjb250ZXh0KSB7XG4gICAgY29uc3QgcGF0aCA9IHJlc29sdmUoc291cmNlLCBjb250ZXh0KTtcbiAgICBpZiAocGF0aCA9PSBudWxsKSB7IHJldHVybiBudWxsOyB9XG4gICAgcmV0dXJuIFN0cm9uZ2x5Q29ubmVjdGVkQ29tcG9uZW50c0J1aWxkZXIuZm9yKGNoaWxkQ29udGV4dChwYXRoLCBjb250ZXh0KSk7XG4gIH1cblxuICBzdGF0aWMgZm9yKGNvbnRleHQpIHtcbiAgICBjb25zdCBjYWNoZUtleSA9IGNvbnRleHQuY2FjaGVLZXkgfHwgaGFzaE9iamVjdChjb250ZXh0KS5kaWdlc3QoJ2hleCcpO1xuICAgIGlmIChjYWNoZS5oYXMoY2FjaGVLZXkpKSB7XG4gICAgICByZXR1cm4gY2FjaGUuZ2V0KGNhY2hlS2V5KTtcbiAgICB9XG4gICAgY29uc3Qgc2NjID0gU3Ryb25nbHlDb25uZWN0ZWRDb21wb25lbnRzQnVpbGRlci5jYWxjdWxhdGUoY29udGV4dCk7XG4gICAgY2FjaGUuc2V0KGNhY2hlS2V5LCBzY2MpO1xuICAgIHJldHVybiBzY2M7XG4gIH1cblxuICBzdGF0aWMgY2FsY3VsYXRlKGNvbnRleHQpIHtcbiAgICBjb25zdCBleHBvcnRNYXAgPSBFeHBvcnRNYXBCdWlsZGVyLmZvcihjb250ZXh0KTtcbiAgICBjb25zdCBhZGphY2VuY3lMaXN0ID0gdGhpcy5leHBvcnRNYXBUb0FkamFjZW5jeUxpc3QoZXhwb3J0TWFwKTtcbiAgICBjb25zdCBjYWxjdWxhdGVkU2NjID0gY2FsY3VsYXRlU2NjKGFkamFjZW5jeUxpc3QpO1xuICAgIHJldHVybiBTdHJvbmdseUNvbm5lY3RlZENvbXBvbmVudHNCdWlsZGVyLmNhbGN1bGF0ZWRTY2NUb1BsYWluT2JqZWN0KGNhbGN1bGF0ZWRTY2MpO1xuICB9XG5cbiAgLyoqIEByZXR1cm5zIHtNYXA8c3RyaW5nLCBTZXQ8c3RyaW5nPj59IGZvciBlYWNoIGRlcCwgd2hhdCBhcmUgaXRzIGRpcmVjdCBkZXBzICovXG4gIHN0YXRpYyBleHBvcnRNYXBUb0FkamFjZW5jeUxpc3QoaW5pdGlhbEV4cG9ydE1hcCkge1xuICAgIGNvbnN0IGFkamFjZW5jeUxpc3QgPSBuZXcgTWFwKCk7XG4gICAgLy8gQkZTXG4gICAgZnVuY3Rpb24gdmlzaXROb2RlKGV4cG9ydE1hcCkge1xuICAgICAgaWYgKCFleHBvcnRNYXApIHtcbiAgICAgICAgcmV0dXJuO1xuICAgICAgfVxuICAgICAgZXhwb3J0TWFwLmltcG9ydHMuZm9yRWFjaCgodiwgaW1wb3J0ZWRQYXRoKSA9PiB7XG4gICAgICAgIGNvbnN0IGZyb20gPSBleHBvcnRNYXAucGF0aDtcbiAgICAgICAgY29uc3QgdG8gPSBpbXBvcnRlZFBhdGg7XG5cbiAgICAgICAgLy8gSWdub3JlIHR5cGUtb25seSBpbXBvcnRzLCBiZWNhdXNlIHdlIGNhcmUgb25seSBhYm91dCBTQ0NzIG9mIHZhbHVlIGltcG9ydHNcbiAgICAgICAgY29uc3QgdG9UcmF2ZXJzZSA9IFsuLi52LmRlY2xhcmF0aW9uc10uZmlsdGVyKCh7IGlzT25seUltcG9ydGluZ1R5cGVzIH0pID0+ICFpc09ubHlJbXBvcnRpbmdUeXBlcyk7XG4gICAgICAgIGlmICh0b1RyYXZlcnNlLmxlbmd0aCA9PT0gMCkgeyByZXR1cm47IH1cblxuICAgICAgICBpZiAoIWFkamFjZW5jeUxpc3QuaGFzKGZyb20pKSB7XG4gICAgICAgICAgYWRqYWNlbmN5TGlzdC5zZXQoZnJvbSwgbmV3IFNldCgpKTtcbiAgICAgICAgfVxuXG4gICAgICAgIGlmIChhZGphY2VuY3lMaXN0LmdldChmcm9tKS5oYXModG8pKSB7XG4gICAgICAgICAgcmV0dXJuOyAvLyBwcmV2ZW50IGVuZGxlc3MgbG9vcFxuICAgICAgICB9XG4gICAgICAgIGFkamFjZW5jeUxpc3QuZ2V0KGZyb20pLmFkZCh0byk7XG4gICAgICAgIHZpc2l0Tm9kZSh2LmdldHRlcigpKTtcbiAgICAgIH0pO1xuICAgIH1cbiAgICB2aXNpdE5vZGUoaW5pdGlhbEV4cG9ydE1hcCk7XG4gICAgLy8gRmlsbCBnYXBzXG4gICAgYWRqYWNlbmN5TGlzdC5mb3JFYWNoKCh2YWx1ZXMpID0+IHtcbiAgICAgIHZhbHVlcy5mb3JFYWNoKCh2YWx1ZSkgPT4ge1xuICAgICAgICBpZiAoIWFkamFjZW5jeUxpc3QuaGFzKHZhbHVlKSkge1xuICAgICAgICAgIGFkamFjZW5jeUxpc3Quc2V0KHZhbHVlLCBuZXcgU2V0KCkpO1xuICAgICAgICB9XG4gICAgICB9KTtcbiAgICB9KTtcbiAgICByZXR1cm4gYWRqYWNlbmN5TGlzdDtcbiAgfVxuXG4gIC8qKiBAcmV0dXJucyB7UmVjb3JkPHN0cmluZywgbnVtYmVyPn0gZm9yIGVhY2gga2V5LCBpdHMgU0NDJ3MgaW5kZXggKi9cbiAgc3RhdGljIGNhbGN1bGF0ZWRTY2NUb1BsYWluT2JqZWN0KHNjY3MpIHtcbiAgICBjb25zdCBvYmogPSB7fTtcbiAgICBzY2NzLmZvckVhY2goKHNjYywgaW5kZXgpID0+IHtcbiAgICAgIHNjYy5mb3JFYWNoKChub2RlKSA9PiB7XG4gICAgICAgIG9ialtub2RlXSA9IGluZGV4O1xuICAgICAgfSk7XG4gICAgfSk7XG4gICAgcmV0dXJuIG9iajtcbiAgfVxufVxuIl19