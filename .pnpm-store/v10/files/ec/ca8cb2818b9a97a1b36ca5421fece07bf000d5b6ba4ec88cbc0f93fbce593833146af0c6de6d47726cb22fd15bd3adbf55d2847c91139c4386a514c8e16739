'use strict';Object.defineProperty(exports, "__esModule", { value: true });var _createClass = function () {function defineProperties(target, props) {for (var i = 0; i < props.length; i++) {var descriptor = props[i];descriptor.enumerable = descriptor.enumerable || false;descriptor.configurable = true;if ("value" in descriptor) descriptor.writable = true;Object.defineProperty(target, descriptor.key, descriptor);}}return function (Constructor, protoProps, staticProps) {if (protoProps) defineProperties(Constructor.prototype, protoProps);if (staticProps) defineProperties(Constructor, staticProps);return Constructor;};}();var _fs = require('fs');var _fs2 = _interopRequireDefault(_fs);

var _doctrine = require('doctrine');var _doctrine2 = _interopRequireDefault(_doctrine);

var _debug = require('debug');var _debug2 = _interopRequireDefault(_debug);

var _parse2 = require('eslint-module-utils/parse');var _parse3 = _interopRequireDefault(_parse2);
var _visit = require('eslint-module-utils/visit');var _visit2 = _interopRequireDefault(_visit);
var _resolve = require('eslint-module-utils/resolve');var _resolve2 = _interopRequireDefault(_resolve);
var _ignore = require('eslint-module-utils/ignore');var _ignore2 = _interopRequireDefault(_ignore);

var _hash = require('eslint-module-utils/hash');
var _unambiguous = require('eslint-module-utils/unambiguous');var unambiguous = _interopRequireWildcard(_unambiguous);

var _ = require('.');var _2 = _interopRequireDefault(_);
var _childContext = require('./childContext');var _childContext2 = _interopRequireDefault(_childContext);
var _typescript = require('./typescript');
var _remotePath = require('./remotePath');
var _visitor = require('./visitor');var _visitor2 = _interopRequireDefault(_visitor);function _interopRequireWildcard(obj) {if (obj && obj.__esModule) {return obj;} else {var newObj = {};if (obj != null) {for (var key in obj) {if (Object.prototype.hasOwnProperty.call(obj, key)) newObj[key] = obj[key];}}newObj['default'] = obj;return newObj;}}function _interopRequireDefault(obj) {return obj && obj.__esModule ? obj : { 'default': obj };}function _classCallCheck(instance, Constructor) {if (!(instance instanceof Constructor)) {throw new TypeError("Cannot call a class as a function");}}

var log = (0, _debug2['default'])('eslint-plugin-import:ExportMap');

var exportCache = new Map();

/**
                              * The creation of this closure is isolated from other scopes
                              * to avoid over-retention of unrelated variables, which has
                              * caused memory leaks. See #1266.
                              */
function thunkFor(p, context) {
  // eslint-disable-next-line no-use-before-define
  return function () {return ExportMapBuilder['for']((0, _childContext2['default'])(p, context));};
}var

ExportMapBuilder = function () {function ExportMapBuilder() {_classCallCheck(this, ExportMapBuilder);}_createClass(ExportMapBuilder, null, [{ key: 'get', value: function () {function get(
      source, context) {
        var path = (0, _resolve2['default'])(source, context);
        if (path == null) {return null;}

        return ExportMapBuilder['for']((0, _childContext2['default'])(path, context));
      }return get;}() }, { key: 'for', value: function () {function _for(

      context) {var
        path = context.path;

        var cacheKey = context.cacheKey || (0, _hash.hashObject)(context).digest('hex');
        var exportMap = exportCache.get(cacheKey);

        // return cached ignore
        if (exportMap === null) {return null;}

        var stats = _fs2['default'].statSync(path);
        if (exportMap != null) {
          // date equality check
          if (exportMap.mtime - stats.mtime === 0) {
            return exportMap;
          }
          // future: check content equality?
        }

        // check valid extensions first
        if (!(0, _ignore.hasValidExtension)(path, context)) {
          exportCache.set(cacheKey, null);
          return null;
        }

        // check for and cache ignore
        if ((0, _ignore2['default'])(path, context)) {
          log('ignored path due to ignore settings:', path);
          exportCache.set(cacheKey, null);
          return null;
        }

        var content = _fs2['default'].readFileSync(path, { encoding: 'utf8' });

        // check for and cache unambiguous modules
        if (!unambiguous.test(content)) {
          log('ignored path due to unambiguous regex:', path);
          exportCache.set(cacheKey, null);
          return null;
        }

        log('cache miss', cacheKey, 'for path', path);
        exportMap = ExportMapBuilder.parse(path, content, context);

        // ambiguous modules return null
        if (exportMap == null) {
          log('ignored path due to ambiguous parse:', path);
          exportCache.set(cacheKey, null);
          return null;
        }

        exportMap.mtime = stats.mtime;

        exportCache.set(cacheKey, exportMap);
        return exportMap;
      }return _for;}() }, { key: 'parse', value: function () {function parse(

      path, content, context) {
        var exportMap = new _2['default'](path);
        var isEsModuleInteropTrue = (0, _typescript.isEsModuleInterop)(context);

        var ast = void 0;
        var visitorKeys = void 0;
        try {
          var result = (0, _parse3['default'])(path, content, context);
          ast = result.ast;
          visitorKeys = result.visitorKeys;
        } catch (err) {
          exportMap.errors.push(err);
          return exportMap; // can't continue
        }

        exportMap.visitorKeys = visitorKeys;

        var hasDynamicImports = false;

        var remotePathResolver = new _remotePath.RemotePath(path, context);

        function processDynamicImport(source) {
          hasDynamicImports = true;
          if (source.type !== 'Literal') {
            return null;
          }
          var p = remotePathResolver.resolve(source.value);
          if (p == null) {
            return null;
          }
          var importedSpecifiers = new Set();
          importedSpecifiers.add('ImportNamespaceSpecifier');
          var getter = thunkFor(p, context);
          exportMap.imports.set(p, {
            getter: getter,
            declarations: new Set([{
              source: {
                // capturing actual node reference holds full AST in memory!
                value: source.value,
                loc: source.loc },

              importedSpecifiers: importedSpecifiers,
              dynamic: true }]) });


        }

        (0, _visit2['default'])(ast, visitorKeys, {
          ImportExpression: function () {function ImportExpression(node) {
              processDynamicImport(node.source);
            }return ImportExpression;}(),
          CallExpression: function () {function CallExpression(node) {
              if (node.callee.type === 'Import') {
                processDynamicImport(node.arguments[0]);
              }
            }return CallExpression;}() });


        var unambiguouslyESM = unambiguous.isModule(ast);
        if (!unambiguouslyESM && !hasDynamicImports) {return null;}

        // attempt to collect module doc
        if (ast.comments) {
          ast.comments.some(function (c) {
            if (c.type !== 'Block') {return false;}
            try {
              var doc = _doctrine2['default'].parse(c.value, { unwrap: true });
              if (doc.tags.some(function (t) {return t.title === 'module';})) {
                exportMap.doc = doc;
                return true;
              }
            } catch (err) {/* ignore */}
            return false;
          });
        }

        var visitorBuilder = new _visitor2['default'](
        path,
        context,
        exportMap,
        ExportMapBuilder,
        content,
        ast,
        isEsModuleInteropTrue,
        thunkFor);

        ast.body.forEach(function (astNode) {
          var visitor = visitorBuilder.build(astNode);

          if (visitor[astNode.type]) {
            visitor[astNode.type].call(visitorBuilder);
          }
        });

        if (
        isEsModuleInteropTrue // esModuleInterop is on in tsconfig
        && exportMap.namespace.size > 0 // anything is exported
        && !exportMap.namespace.has('default') // and default isn't added already
        ) {
            exportMap.namespace.set('default', {}); // add default export
          }

        if (unambiguouslyESM) {
          exportMap.parseGoal = 'Module';
        }
        return exportMap;
      }return parse;}() }]);return ExportMapBuilder;}();exports['default'] = ExportMapBuilder;
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIi4uLy4uL3NyYy9leHBvcnRNYXAvYnVpbGRlci5qcyJdLCJuYW1lcyI6WyJ1bmFtYmlndW91cyIsImxvZyIsImV4cG9ydENhY2hlIiwiTWFwIiwidGh1bmtGb3IiLCJwIiwiY29udGV4dCIsIkV4cG9ydE1hcEJ1aWxkZXIiLCJzb3VyY2UiLCJwYXRoIiwiY2FjaGVLZXkiLCJkaWdlc3QiLCJleHBvcnRNYXAiLCJnZXQiLCJzdGF0cyIsImZzIiwic3RhdFN5bmMiLCJtdGltZSIsInNldCIsImNvbnRlbnQiLCJyZWFkRmlsZVN5bmMiLCJlbmNvZGluZyIsInRlc3QiLCJwYXJzZSIsIkV4cG9ydE1hcCIsImlzRXNNb2R1bGVJbnRlcm9wVHJ1ZSIsImFzdCIsInZpc2l0b3JLZXlzIiwicmVzdWx0IiwiZXJyIiwiZXJyb3JzIiwicHVzaCIsImhhc0R5bmFtaWNJbXBvcnRzIiwicmVtb3RlUGF0aFJlc29sdmVyIiwiUmVtb3RlUGF0aCIsInByb2Nlc3NEeW5hbWljSW1wb3J0IiwidHlwZSIsInJlc29sdmUiLCJ2YWx1ZSIsImltcG9ydGVkU3BlY2lmaWVycyIsIlNldCIsImFkZCIsImdldHRlciIsImltcG9ydHMiLCJkZWNsYXJhdGlvbnMiLCJsb2MiLCJkeW5hbWljIiwiSW1wb3J0RXhwcmVzc2lvbiIsIm5vZGUiLCJDYWxsRXhwcmVzc2lvbiIsImNhbGxlZSIsImFyZ3VtZW50cyIsInVuYW1iaWd1b3VzbHlFU00iLCJpc01vZHVsZSIsImNvbW1lbnRzIiwic29tZSIsImMiLCJkb2MiLCJkb2N0cmluZSIsInVud3JhcCIsInRhZ3MiLCJ0IiwidGl0bGUiLCJ2aXNpdG9yQnVpbGRlciIsIkltcG9ydEV4cG9ydFZpc2l0b3JCdWlsZGVyIiwiYm9keSIsImZvckVhY2giLCJhc3ROb2RlIiwidmlzaXRvciIsImJ1aWxkIiwiY2FsbCIsIm5hbWVzcGFjZSIsInNpemUiLCJoYXMiLCJwYXJzZUdvYWwiXSwibWFwcGluZ3MiOiJnbkJBQUEsd0I7O0FBRUEsb0M7O0FBRUEs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dUJBQU8sSUFBUDtBQUNEO0FBQ0YsYUFORCxDQU1FLE9BQU81QixHQUFQLEVBQVksQ0FBRSxZQUFjO0FBQzlCLG1CQUFPLEtBQVA7QUFDRCxXQVZEO0FBV0Q7O0FBRUQsWUFBTWtDLGlCQUFpQixJQUFJQyxvQkFBSjtBQUNyQnZELFlBRHFCO0FBRXJCSCxlQUZxQjtBQUdyQk0saUJBSHFCO0FBSXJCTCx3QkFKcUI7QUFLckJZLGVBTHFCO0FBTXJCTyxXQU5xQjtBQU9yQkQsNkJBUHFCO0FBUXJCckIsZ0JBUnFCLENBQXZCOztBQVVBc0IsWUFBSXVDLElBQUosQ0FBU0MsT0FBVCxDQUFpQixVQUFVQyxPQUFWLEVBQW1CO0FBQ2xDLGNBQU1DLFVBQVVMLGVBQWVNLEtBQWYsQ0FBcUJGLE9BQXJCLENBQWhCOztBQUVBLGNBQUlDLFFBQVFELFFBQVEvQixJQUFoQixDQUFKLEVBQTJCO0FBQ3pCZ0Msb0JBQVFELFFBQVEvQixJQUFoQixFQUFzQmtDLElBQXRCLENBQTJCUCxjQUEzQjtBQUNEO0FBQ0YsU0FORDs7QUFRQTtBQUNFdEMsOEJBQXNCO0FBQXRCLFdBQ0diLFVBQVUyRCxTQUFWLENBQW9CQyxJQUFwQixHQUEyQixDQUQ5QixDQUNnQztBQURoQyxXQUVHLENBQUM1RCxVQUFVMkQsU0FBVixDQUFvQkUsR0FBcEIsQ0FBd0IsU0FBeEIsQ0FITixDQUd5QztBQUh6QyxVQUlFO0FBQ0E3RCxzQkFBVTJELFNBQVYsQ0FBb0JyRCxHQUFwQixDQUF3QixTQUF4QixFQUFtQyxFQUFuQyxFQURBLENBQ3dDO0FBQ3pDOztBQUVELFlBQUlrQyxnQkFBSixFQUFzQjtBQUNwQnhDLG9CQUFVOEQsU0FBVixHQUFzQixRQUF0QjtBQUNEO0FBQ0QsZUFBTzlELFNBQVA7QUFDRCxPLHNFQTFLa0JMLGdCIiwiZmlsZSI6ImJ1aWxkZXIuanMiLCJzb3VyY2VzQ29udGVudCI6WyJpbXBvcnQgZnMgZnJvbSAnZnMnO1xuXG5pbXBvcnQgZG9jdHJpbmUgZnJvbSAnZG9jdHJpbmUnO1xuXG5pbXBvcnQgZGVidWcgZnJvbSAnZGVidWcnO1xuXG5pbXBvcnQgcGFyc2UgZnJvbSAnZXNsaW50LW1vZHVsZS11dGlscy9wYXJzZSc7XG5pbXBvcnQgdmlzaXQgZnJvbSAnZXNsaW50LW1vZHVsZS11dGlscy92aXNpdCc7XG5pbXBvcnQgcmVzb2x2ZSBmcm9tICdlc2xpbnQtbW9kdWxlLXV0aWxzL3Jlc29sdmUnO1xuaW1wb3J0IGlzSWdub3JlZCwgeyBoYXNWYWxpZEV4dGVuc2lvbiB9IGZyb20gJ2VzbGludC1tb2R1bGUtdXRpbHMvaWdub3JlJztcblxuaW1wb3J0IHsgaGFzaE9iamVjdCB9IGZyb20gJ2VzbGludC1tb2R1bGUtdXRpbHMvaGFzaCc7XG5pbXBvcnQgKiBhcyB1bmFtYmlndW91cyBmcm9tICdlc2xpbnQtbW9kdWxlLXV0aWxzL3VuYW1iaWd1b3VzJztcblxuaW1wb3J0IEV4cG9ydE1hcCBmcm9tICcuJztcbmltcG9ydCBjaGlsZENvbnRleHQgZnJvbSAnLi9jaGlsZENvbnRleHQnO1xuaW1wb3J0IHsgaXNFc01vZHVsZUludGVyb3AgfSBmcm9tICcuL3R5cGVzY3JpcHQnO1xuaW1wb3J0IHsgUmVtb3RlUGF0aCB9IGZyb20gJy4vcmVtb3RlUGF0aCc7XG5pbXBvcnQgSW1wb3J0RXhwb3J0VmlzaXRvckJ1aWxkZXIgZnJvbSAnLi92aXNpdG9yJztcblxuY29uc3QgbG9nID0gZGVidWcoJ2VzbGludC1wbHVnaW4taW1wb3J0OkV4cG9ydE1hcCcpO1xuXG5jb25zdCBleHBvcnRDYWNoZSA9IG5ldyBNYXAoKTtcblxuLyoqXG4gKiBUaGUgY3JlYXRpb24gb2YgdGhpcyBjbG9zdXJlIGlzIGlzb2xhdGVkIGZyb20gb3RoZXIgc2NvcGVzXG4gKiB0byBhdm9pZCBvdmVyLXJldGVudGlvbiBvZiB1bnJlbGF0ZWQgdmFyaWFibGVzLCB3aGljaCBoYXNcbiAqIGNhdXNlZCBtZW1vcnkgbGVha3MuIFNlZSAjMTI2Ni5cbiAqL1xuZnVuY3Rpb24gdGh1bmtGb3IocCwgY29udGV4dCkge1xuICAvLyBlc2xpbnQtZGlzYWJsZS1uZXh0LWxpbmUgbm8tdXNlLWJlZm9yZS1kZWZpbmVcbiAgcmV0dXJuICgpID0+IEV4cG9ydE1hcEJ1aWxkZXIuZm9yKGNoaWxkQ29udGV4dChwLCBjb250ZXh0KSk7XG59XG5cbmV4cG9ydCBkZWZhdWx0IGNsYXNzIEV4cG9ydE1hcEJ1aWxkZXIge1xuICBzdGF0aWMgZ2V0KHNvdXJjZSwgY29udGV4dCkge1xuICAgIGNvbnN0IHBhdGggPSByZXNvbHZlKHNvdXJjZSwgY29udGV4dCk7XG4gICAgaWYgKHBhdGggPT0gbnVsbCkgeyByZXR1cm4gbnVsbDsgfVxuXG4gICAgcmV0dXJuIEV4cG9ydE1hcEJ1aWxkZXIuZm9yKGNoaWxkQ29udGV4dChwYXRoLCBjb250ZXh0KSk7XG4gIH1cblxuICBzdGF0aWMgZm9yKGNvbnRleHQpIHtcbiAgICBjb25zdCB7IHBhdGggfSA9IGNvbnRleHQ7XG5cbiAgICBjb25zdCBjYWNoZUtleSA9IGNvbnRleHQuY2FjaGVLZXkgfHwgaGFzaE9iamVjdChjb250ZXh0KS5kaWdlc3QoJ2hleCcpO1xuICAgIGxldCBleHBvcnRNYXAgPSBleHBvcnRDYWNoZS5nZXQoY2FjaGVLZXkpO1xuXG4gICAgLy8gcmV0dXJuIGNhY2hlZCBpZ25vcmVcbiAgICBpZiAoZXhwb3J0TWFwID09PSBudWxsKSB7IHJldHVybiBudWxsOyB9XG5cbiAgICBjb25zdCBzdGF0cyA9IGZzLnN0YXRTeW5jKHBhdGgpO1xuICAgIGlmIChleHBvcnRNYXAgIT0gbnVsbCkge1xuICAgICAgLy8gZGF0ZSBlcXVhbGl0eSBjaGVja1xuICAgICAgaWYgKGV4cG9ydE1hcC5tdGltZSAtIHN0YXRzLm10aW1lID09PSAwKSB7XG4gICAgICAgIHJldHVybiBleHBvcnRNYXA7XG4gICAgICB9XG4gICAgICAvLyBmdXR1cmU6IGNoZWNrIGNvbnRlbnQgZXF1YWxpdHk/XG4gICAgfVxuXG4gICAgLy8gY2hlY2sgdmFsaWQgZXh0ZW5zaW9ucyBmaXJzdFxuICAgIGlmICghaGFzVmFsaWRFeHRlbnNpb24ocGF0aCwgY29udGV4dCkpIHtcbiAgICAgIGV4cG9ydENhY2hlLnNldChjYWNoZUtleSwgbnVsbCk7XG4gICAgICByZXR1cm4gbnVsbDtcbiAgICB9XG5cbiAgICAvLyBjaGVjayBmb3IgYW5kIGNhY2hlIGlnbm9yZVxuICAgIGlmIChpc0lnbm9yZWQocGF0aCwgY29udGV4dCkpIHtcbiAgICAgIGxvZygnaWdub3JlZCBwYXRoIGR1ZSB0byBpZ25vcmUgc2V0dGluZ3M6JywgcGF0aCk7XG4gICAgICBleHBvcnRDYWNoZS5zZXQoY2FjaGVLZXksIG51bGwpO1xuICAgICAgcmV0dXJuIG51bGw7XG4gICAgfVxuXG4gICAgY29uc3QgY29udGVudCA9IGZzLnJlYWRGaWxlU3luYyhwYXRoLCB7IGVuY29kaW5nOiAndXRmOCcgfSk7XG5cbiAgICAvLyBjaGVjayBmb3IgYW5kIGNhY2hlIHVuYW1iaWd1b3VzIG1vZHVsZXNcbiAgICBpZiAoIXVuYW1iaWd1b3VzLnRlc3QoY29udGVudCkpIHtcbiAgICAgIGxvZygnaWdub3JlZCBwYXRoIGR1ZSB0byB1bmFtYmlndW91cyByZWdleDonLCBwYXRoKTtcbiAgICAgIGV4cG9ydENhY2hlLnNldChjYWNoZUtleSwgbnVsbCk7XG4gICAgICByZXR1cm4gbnVsbDtcbiAgICB9XG5cbiAgICBsb2coJ2NhY2hlIG1pc3MnLCBjYWNoZUtleSwgJ2ZvciBwYXRoJywgcGF0aCk7XG4gICAgZXhwb3J0TWFwID0gRXhwb3J0TWFwQnVpbGRlci5wYXJzZShwYXRoLCBjb250ZW50LCBjb250ZXh0KTtcblxuICAgIC8vIGFtYmlndW91cyBtb2R1bGVzIHJldHVybiBudWxsXG4gICAgaWYgKGV4cG9ydE1hcCA9PSBudWxsKSB7XG4gICAgICBsb2coJ2lnbm9yZWQgcGF0aCBkdWUgdG8gYW1iaWd1b3VzIHBhcnNlOicsIHBhdGgpO1xuICAgICAgZXhwb3J0Q2FjaGUuc2V0KGNhY2hlS2V5LCBudWxsKTtcbiAgICAgIHJldHVybiBudWxsO1xuICAgIH1cblxuICAgIGV4cG9ydE1hcC5tdGltZSA9IHN0YXRzLm10aW1lO1xuXG4gICAgZXhwb3J0Q2FjaGUuc2V0KGNhY2hlS2V5LCBleHBvcnRNYXApO1xuICAgIHJldHVybiBleHBvcnRNYXA7XG4gIH1cblxuICBzdGF0aWMgcGFyc2UocGF0aCwgY29udGVudCwgY29udGV4dCkge1xuICAgIGNvbnN0IGV4cG9ydE1hcCA9IG5ldyBFeHBvcnRNYXAocGF0aCk7XG4gICAgY29uc3QgaXNFc01vZHVsZUludGVyb3BUcnVlID0gaXNFc01vZHVsZUludGVyb3AoY29udGV4dCk7XG5cbiAgICBsZXQgYXN0O1xuICAgIGxldCB2aXNpdG9yS2V5cztcbiAgICB0cnkge1xuICAgICAgY29uc3QgcmVzdWx0ID0gcGFyc2UocGF0aCwgY29udGVudCwgY29udGV4dCk7XG4gICAgICBhc3QgPSByZXN1bHQuYXN0O1xuICAgICAgdmlzaXRvcktleXMgPSByZXN1bHQudmlzaXRvcktleXM7XG4gICAgfSBjYXRjaCAoZXJyKSB7XG4gICAgICBleHBvcnRNYXAuZXJyb3JzLnB1c2goZXJyKTtcbiAgICAgIHJldHVybiBleHBvcnRNYXA7IC8vIGNhbid0IGNvbnRpbnVlXG4gICAgfVxuXG4gICAgZXhwb3J0TWFwLnZpc2l0b3JLZXlzID0gdmlzaXRvcktleXM7XG5cbiAgICBsZXQgaGFzRHluYW1pY0ltcG9ydHMgPSBmYWxzZTtcblxuICAgIGNvbnN0IHJlbW90ZVBhdGhSZXNvbHZlciA9IG5ldyBSZW1vdGVQYXRoKHBhdGgsIGNvbnRleHQpO1xuXG4gICAgZnVuY3Rpb24gcHJvY2Vzc0R5bmFtaWNJbXBvcnQoc291cmNlKSB7XG4gICAgICBoYXNEeW5hbWljSW1wb3J0cyA9IHRydWU7XG4gICAgICBpZiAoc291cmNlLnR5cGUgIT09ICdMaXRlcmFsJykge1xuICAgICAgICByZXR1cm4gbnVsbDtcbiAgICAgIH1cbiAgICAgIGNvbnN0IHAgPSByZW1vdGVQYXRoUmVzb2x2ZXIucmVzb2x2ZShzb3VyY2UudmFsdWUpO1xuICAgICAgaWYgKHAgPT0gbnVsbCkge1xuICAgICAgICByZXR1cm4gbnVsbDtcbiAgICAgIH1cbiAgICAgIGNvbnN0IGltcG9ydGVkU3BlY2lmaWVycyA9IG5ldyBTZXQoKTtcbiAgICAgIGltcG9ydGVkU3BlY2lmaWVycy5hZGQoJ0ltcG9ydE5hbWVzcGFjZVNwZWNpZmllcicpO1xuICAgICAgY29uc3QgZ2V0dGVyID0gdGh1bmtGb3IocCwgY29udGV4dCk7XG4gICAgICBleHBvcnRNYXAuaW1wb3J0cy5zZXQocCwge1xuICAgICAgICBnZXR0ZXIsXG4gICAgICAgIGRlY2xhcmF0aW9uczogbmV3IFNldChbe1xuICAgICAgICAgIHNvdXJjZToge1xuICAgICAgICAgIC8vIGNhcHR1cmluZyBhY3R1YWwgbm9kZSByZWZlcmVuY2UgaG9sZHMgZnVsbCBBU1QgaW4gbWVtb3J5IVxuICAgICAgICAgICAgdmFsdWU6IHNvdXJjZS52YWx1ZSxcbiAgICAgICAgICAgIGxvYzogc291cmNlLmxvYyxcbiAgICAgICAgICB9LFxuICAgICAgICAgIGltcG9ydGVkU3BlY2lmaWVycyxcbiAgICAgICAgICBkeW5hbWljOiB0cnVlLFxuICAgICAgICB9XSksXG4gICAgICB9KTtcbiAgICB9XG5cbiAgICB2aXNpdChhc3QsIHZpc2l0b3JLZXlzLCB7XG4gICAgICBJbXBvcnRFeHByZXNzaW9uKG5vZGUpIHtcbiAgICAgICAgcHJvY2Vzc0R5bmFtaWNJbXBvcnQobm9kZS5zb3VyY2UpO1xuICAgICAgfSxcbiAgICAgIENhbGxFeHByZXNzaW9uKG5vZGUpIHtcbiAgICAgICAgaWYgKG5vZGUuY2FsbGVlLnR5cGUgPT09ICdJbXBvcnQnKSB7XG4gICAgICAgICAgcHJvY2Vzc0R5bmFtaWNJbXBvcnQobm9kZS5hcmd1bWVudHNbMF0pO1xuICAgICAgICB9XG4gICAgICB9LFxuICAgIH0pO1xuXG4gICAgY29uc3QgdW5hbWJpZ3VvdXNseUVTTSA9IHVuYW1iaWd1b3VzLmlzTW9kdWxlKGFzdCk7XG4gICAgaWYgKCF1bmFtYmlndW91c2x5RVNNICYmICFoYXNEeW5hbWljSW1wb3J0cykgeyByZXR1cm4gbnVsbDsgfVxuXG4gICAgLy8gYXR0ZW1wdCB0byBjb2xsZWN0IG1vZHVsZSBkb2NcbiAgICBpZiAoYXN0LmNvbW1lbnRzKSB7XG4gICAgICBhc3QuY29tbWVudHMuc29tZSgoYykgPT4ge1xuICAgICAgICBpZiAoYy50eXBlICE9PSAnQmxvY2snKSB7IHJldHVybiBmYWxzZTsgfVxuICAgICAgICB0cnkge1xuICAgICAgICAgIGNvbnN0IGRvYyA9IGRvY3RyaW5lLnBhcnNlKGMudmFsdWUsIHsgdW53cmFwOiB0cnVlIH0pO1xuICAgICAgICAgIGlmIChkb2MudGFncy5zb21lKCh0KSA9PiB0LnRpdGxlID09PSAnbW9kdWxlJykpIHtcbiAgICAgICAgICAgIGV4cG9ydE1hcC5kb2MgPSBkb2M7XG4gICAgICAgICAgICByZXR1cm4gdHJ1ZTtcbiAgICAgICAgICB9XG4gICAgICAgIH0gY2F0Y2ggKGVycikgeyAvKiBpZ25vcmUgKi8gfVxuICAgICAgICByZXR1cm4gZmFsc2U7XG4gICAgICB9KTtcbiAgICB9XG5cbiAgICBjb25zdCB2aXNpdG9yQnVpbGRlciA9IG5ldyBJbXBvcnRFeHBvcnRWaXNpdG9yQnVpbGRlcihcbiAgICAgIHBhdGgsXG4gICAgICBjb250ZXh0LFxuICAgICAgZXhwb3J0TWFwLFxuICAgICAgRXhwb3J0TWFwQnVpbGRlcixcbiAgICAgIGNvbnRlbnQsXG4gICAgICBhc3QsXG4gICAgICBpc0VzTW9kdWxlSW50ZXJvcFRydWUsXG4gICAgICB0aHVua0ZvcixcbiAgICApO1xuICAgIGFzdC5ib2R5LmZvckVhY2goZnVuY3Rpb24gKGFzdE5vZGUpIHtcbiAgICAgIGNvbnN0IHZpc2l0b3IgPSB2aXNpdG9yQnVpbGRlci5idWlsZChhc3ROb2RlKTtcblxuICAgICAgaWYgKHZpc2l0b3JbYXN0Tm9kZS50eXBlXSkge1xuICAgICAgICB2aXNpdG9yW2FzdE5vZGUudHlwZV0uY2FsbCh2aXNpdG9yQnVpbGRlcik7XG4gICAgICB9XG4gICAgfSk7XG5cbiAgICBpZiAoXG4gICAgICBpc0VzTW9kdWxlSW50ZXJvcFRydWUgLy8gZXNNb2R1bGVJbnRlcm9wIGlzIG9uIGluIHRzY29uZmlnXG4gICAgICAmJiBleHBvcnRNYXAubmFtZXNwYWNlLnNpemUgPiAwIC8vIGFueXRoaW5nIGlzIGV4cG9ydGVkXG4gICAgICAmJiAhZXhwb3J0TWFwLm5hbWVzcGFjZS5oYXMoJ2RlZmF1bHQnKSAvLyBhbmQgZGVmYXVsdCBpc24ndCBhZGRlZCBhbHJlYWR5XG4gICAgKSB7XG4gICAgICBleHBvcnRNYXAubmFtZXNwYWNlLnNldCgnZGVmYXVsdCcsIHt9KTsgLy8gYWRkIGRlZmF1bHQgZXhwb3J0XG4gICAgfVxuXG4gICAgaWYgKHVuYW1iaWd1b3VzbHlFU00pIHtcbiAgICAgIGV4cG9ydE1hcC5wYXJzZUdvYWwgPSAnTW9kdWxlJztcbiAgICB9XG4gICAgcmV0dXJuIGV4cG9ydE1hcDtcbiAgfVxufVxuIl19