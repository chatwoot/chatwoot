'use strict';var _declaredScope = require('eslint-module-utils/declaredScope');var _declaredScope2 = _interopRequireDefault(_declaredScope);
var _ExportMap = require('../ExportMap');var _ExportMap2 = _interopRequireDefault(_ExportMap);
var _docsUrl = require('../docsUrl');var _docsUrl2 = _interopRequireDefault(_docsUrl);function _interopRequireDefault(obj) {return obj && obj.__esModule ? obj : { default: obj };}

function message(deprecation) {
  return 'Deprecated' + (deprecation.description ? ': ' + deprecation.description : '.');
}

function getDeprecation(metadata) {
  if (!metadata || !metadata.doc) return;

  let deprecation;
  if (metadata.doc.tags.some(t => t.title === 'deprecated' && (deprecation = t))) {
    return deprecation;
  }
}

module.exports = {
  meta: {
    type: 'suggestion',
    docs: {
      url: (0, _docsUrl2.default)('no-deprecated') },

    schema: [] },


  create: function (context) {
    const deprecated = new Map(),
    namespaces = new Map();

    function checkSpecifiers(node) {
      if (node.type !== 'ImportDeclaration') return;
      if (node.source == null) return; // local export, ignore

      const imports = _ExportMap2.default.get(node.source.value, context);
      if (imports == null) return;

      let moduleDeprecation;
      if (imports.doc &&
      imports.doc.tags.some(t => t.title === 'deprecated' && (moduleDeprecation = t))) {
        context.report({ node, message: message(moduleDeprecation) });
      }

      if (imports.errors.length) {
        imports.reportErrors(context, node);
        return;
      }

      node.specifiers.forEach(function (im) {
        let imported, local;
        switch (im.type) {


          case 'ImportNamespaceSpecifier':{
              if (!imports.size) return;
              namespaces.set(im.local.name, imports);
              return;
            }

          case 'ImportDefaultSpecifier':
            imported = 'default';
            local = im.local.name;
            break;

          case 'ImportSpecifier':
            imported = im.imported.name;
            local = im.local.name;
            break;

          default:return; // can't handle this one
        }

        // unknown thing can't be deprecated
        const exported = imports.get(imported);
        if (exported == null) return;

        // capture import of deep namespace
        if (exported.namespace) namespaces.set(local, exported.namespace);

        const deprecation = getDeprecation(imports.get(imported));
        if (!deprecation) return;

        context.report({ node: im, message: message(deprecation) });

        deprecated.set(local, deprecation);

      });
    }

    return {
      'Program': (_ref) => {let body = _ref.body;return body.forEach(checkSpecifiers);},

      'Identifier': function (node) {
        if (node.parent.type === 'MemberExpression' && node.parent.property === node) {
          return; // handled by MemberExpression
        }

        // ignore specifier identifiers
        if (node.parent.type.slice(0, 6) === 'Import') return;

        if (!deprecated.has(node.name)) return;

        if ((0, _declaredScope2.default)(context, node.name) !== 'module') return;
        context.report({
          node,
          message: message(deprecated.get(node.name)) });

      },

      'MemberExpression': function (dereference) {
        if (dereference.object.type !== 'Identifier') return;
        if (!namespaces.has(dereference.object.name)) return;

        if ((0, _declaredScope2.default)(context, dereference.object.name) !== 'module') return;

        // go deep
        var namespace = namespaces.get(dereference.object.name);
        var namepath = [dereference.object.name];
        // while property is namespace and parent is member expression, keep validating
        while (namespace instanceof _ExportMap2.default &&
        dereference.type === 'MemberExpression') {

          // ignore computed parts for now
          if (dereference.computed) return;

          const metadata = namespace.get(dereference.property.name);

          if (!metadata) break;
          const deprecation = getDeprecation(metadata);

          if (deprecation) {
            context.report({ node: dereference.property, message: message(deprecation) });
          }

          // stash and pop
          namepath.push(dereference.property.name);
          namespace = metadata.namespace;
          dereference = dereference.parent;
        }
      } };

  } };
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIi4uLy4uL3NyYy9ydWxlcy9uby1kZXByZWNhdGVkLmpzIl0sIm5hbWVzIjpbIm1lc3NhZ2UiLCJkZXByZWNhdGlvbiIsImRlc2NyaXB0aW9uIiwiZ2V0RGVwcmVjYXRpb24iLCJtZXRhZGF0YSIsImRvYyIsInRhZ3MiLCJzb21lIiwidCIsInRpdGxlIiwibW9kdWxlIiwiZXhwb3J0cyIsIm1ldGEiLCJ0eXBlIiwiZG9jcyIsInVybCIsInNjaGVtYSIsImNyZWF0ZSIsImNvbnRleHQiLCJkZXByZWNhdGVkIiwiTWFwIiwibmFtZXNwYWNlcyIsImNoZWNrU3BlY2lmaWVycyIsIm5vZGUiLCJzb3VyY2UiLCJpbXBvcnRzIiwiRXhwb3J0cyIsImdldCIsInZhbHVlIiwibW9kdWxlRGVwcmVjYXRpb24iLCJyZXBvcnQiLCJlcnJvcnMiLCJsZW5ndGgiLCJyZXBvcnRFcnJvcnMiLCJzcGVjaWZpZXJzIiwiZm9yRWFjaCIsImltIiwiaW1wb3J0ZWQiLCJsb2NhbCIsInNpemUiLCJzZXQiLCJuYW1lIiwiZXhwb3J0ZWQiLCJuYW1lc3BhY2UiLCJib2R5IiwicGFyZW50IiwicHJvcGVydHkiLCJzbGljZSIsImhhcyIsImRlcmVmZXJlbmNlIiwib2JqZWN0IiwibmFtZXBhdGgiLCJjb21wdXRlZCIsInB1c2giXSwibWFwcGluZ3MiOiJhQUFBLGtFO0FBQ0EseUM7QUFDQSxxQzs7QUFFQSxTQUFTQSxPQUFULENBQWlCQyxXQUFqQixFQUE4QjtBQUM1QixTQUFPLGdCQUFnQkEsWUFBWUMsV0FBWixHQUEwQixPQUFPRCxZQUFZQyxXQUE3QyxHQUEyRCxHQUEzRSxDQUFQO0FBQ0Q7O0FBRUQsU0FBU0MsY0FBVCxDQUF3QkMsUUFBeEIsRUFBa0M7QUFDaEMsTUFBSSxDQUFDQSxRQUFELElBQWEsQ0FBQ0EsU0FBU0MsR0FBM0IsRUFBZ0M7O0FBRWhDLE1BQUlKLFdBQUo7QUFDQSxNQUFJRyxTQUFTQyxHQUFULENBQWFDLElBQWIsQ0FBa0JDLElBQWxCLENBQXVCQyxLQUFLQSxF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QyxZQUFZRyxRQUFoQixFQUEwQjs7QUFFMUIsZ0JBQU1oRCxXQUFXdUMsVUFBVWhCLEdBQVYsQ0FBY3NCLFlBQVlILFFBQVosQ0FBcUJMLElBQW5DLENBQWpCOztBQUVBLGNBQUksQ0FBQ3JDLFFBQUwsRUFBZTtBQUNmLGdCQUFNSCxjQUFjRSxlQUFlQyxRQUFmLENBQXBCOztBQUVBLGNBQUlILFdBQUosRUFBaUI7QUFDZmlCLG9CQUFRWSxNQUFSLENBQWUsRUFBRVAsTUFBTTBCLFlBQVlILFFBQXBCLEVBQThCOUMsU0FBU0EsUUFBUUMsV0FBUixDQUF2QyxFQUFmO0FBQ0Q7O0FBRUQ7QUFDQWtELG1CQUFTRSxJQUFULENBQWNKLFlBQVlILFFBQVosQ0FBcUJMLElBQW5DO0FBQ0FFLHNCQUFZdkMsU0FBU3VDLFNBQXJCO0FBQ0FNLHdCQUFjQSxZQUFZSixNQUExQjtBQUNEO0FBQ0YsT0FsREksRUFBUDs7QUFvREQsR0E1SGMsRUFBakIiLCJmaWxlIjoibm8tZGVwcmVjYXRlZC5qcyIsInNvdXJjZXNDb250ZW50IjpbImltcG9ydCBkZWNsYXJlZFNjb3BlIGZyb20gJ2VzbGludC1tb2R1bGUtdXRpbHMvZGVjbGFyZWRTY29wZSdcbmltcG9ydCBFeHBvcnRzIGZyb20gJy4uL0V4cG9ydE1hcCdcbmltcG9ydCBkb2NzVXJsIGZyb20gJy4uL2RvY3NVcmwnXG5cbmZ1bmN0aW9uIG1lc3NhZ2UoZGVwcmVjYXRpb24pIHtcbiAgcmV0dXJuICdEZXByZWNhdGVkJyArIChkZXByZWNhdGlvbi5kZXNjcmlwdGlvbiA/ICc6ICcgKyBkZXByZWNhdGlvbi5kZXNjcmlwdGlvbiA6ICcuJylcbn1cblxuZnVuY3Rpb24gZ2V0RGVwcmVjYXRpb24obWV0YWRhdGEpIHtcbiAgaWYgKCFtZXRhZGF0YSB8fCAhbWV0YWRhdGEuZG9jKSByZXR1cm5cblxuICBsZXQgZGVwcmVjYXRpb25cbiAgaWYgKG1ldGFkYXRhLmRvYy50YWdzLnNvbWUodCA9PiB0LnRpdGxlID09PSAnZGVwcmVjYXRlZCcgJiYgKGRlcHJlY2F0aW9uID0gdCkpKSB7XG4gICAgcmV0dXJuIGRlcHJlY2F0aW9uXG4gIH1cbn1cblxubW9kdWxlLmV4cG9ydHMgPSB7XG4gIG1ldGE6IHtcbiAgICB0eXBlOiAnc3VnZ2VzdGlvbicsXG4gICAgZG9jczoge1xuICAgICAgdXJsOiBkb2NzVXJsKCduby1kZXByZWNhdGVkJyksXG4gICAgfSxcbiAgICBzY2hlbWE6IFtdLFxuICB9LFxuXG4gIGNyZWF0ZTogZnVuY3Rpb24gKGNvbnRleHQpIHtcbiAgICBjb25zdCBkZXByZWNhdGVkID0gbmV3IE1hcCgpXG4gICAgICAgICwgbmFtZXNwYWNlcyA9IG5ldyBNYXAoKVxuXG4gICAgZnVuY3Rpb24gY2hlY2tTcGVjaWZpZXJzKG5vZGUpIHtcbiAgICAgIGlmIChub2RlLnR5cGUgIT09ICdJbXBvcnREZWNsYXJhdGlvbicpIHJldHVyblxuICAgICAgaWYgKG5vZGUuc291cmNlID09IG51bGwpIHJldHVybiAvLyBsb2NhbCBleHBvcnQsIGlnbm9yZVxuXG4gICAgICBjb25zdCBpbXBvcnRzID0gRXhwb3J0cy5nZXQobm9kZS5zb3VyY2UudmFsdWUsIGNvbnRleHQpXG4gICAgICBpZiAoaW1wb3J0cyA9PSBudWxsKSByZXR1cm5cblxuICAgICAgbGV0IG1vZHVsZURlcHJlY2F0aW9uXG4gICAgICBpZiAoaW1wb3J0cy5kb2MgJiZcbiAgICAgICAgICBpbXBvcnRzLmRvYy50YWdzLnNvbWUodCA9PiB0LnRpdGxlID09PSAnZGVwcmVjYXRlZCcgJiYgKG1vZHVsZURlcHJlY2F0aW9uID0gdCkpKSB7XG4gICAgICAgIGNvbnRleHQucmVwb3J0KHsgbm9kZSwgbWVzc2FnZTogbWVzc2FnZShtb2R1bGVEZXByZWNhdGlvbikgfSlcbiAgICAgIH1cblxuICAgICAgaWYgKGltcG9ydHMuZXJyb3JzLmxlbmd0aCkge1xuICAgICAgICBpbXBvcnRzLnJlcG9ydEVycm9ycyhjb250ZXh0LCBub2RlKVxuICAgICAgICByZXR1cm5cbiAgICAgIH1cblxuICAgICAgbm9kZS5zcGVjaWZpZXJzLmZvckVhY2goZnVuY3Rpb24gKGltKSB7XG4gICAgICAgIGxldCBpbXBvcnRlZCwgbG9jYWxcbiAgICAgICAgc3dpdGNoIChpbS50eXBlKSB7XG5cblxuICAgICAgICAgIGNhc2UgJ0ltcG9ydE5hbWVzcGFjZVNwZWNpZmllcic6e1xuICAgICAgICAgICAgaWYgKCFpbXBvcnRzLnNpemUpIHJldHVyblxuICAgICAgICAgICAgbmFtZXNwYWNlcy5zZXQoaW0ubG9jYWwubmFtZSwgaW1wb3J0cylcbiAgICAgICAgICAgIHJldHVyblxuICAgICAgICAgIH1cblxuICAgICAgICAgIGNhc2UgJ0ltcG9ydERlZmF1bHRTcGVjaWZpZXInOlxuICAgICAgICAgICAgaW1wb3J0ZWQgPSAnZGVmYXVsdCdcbiAgICAgICAgICAgIGxvY2FsID0gaW0ubG9jYWwubmFtZVxuICAgICAgICAgICAgYnJlYWtcblxuICAgICAgICAgIGNhc2UgJ0ltcG9ydFNwZWNpZmllcic6XG4gICAgICAgICAgICBpbXBvcnRlZCA9IGltLmltcG9ydGVkLm5hbWVcbiAgICAgICAgICAgIGxvY2FsID0gaW0ubG9jYWwubmFtZVxuICAgICAgICAgICAgYnJlYWtcblxuICAgICAgICAgIGRlZmF1bHQ6IHJldHVybiAvLyBjYW4ndCBoYW5kbGUgdGhpcyBvbmVcbiAgICAgICAgfVxuXG4gICAgICAgIC8vIHVua25vd24gdGhpbmcgY2FuJ3QgYmUgZGVwcmVjYXRlZFxuICAgICAgICBjb25zdCBleHBvcnRlZCA9IGltcG9ydHMuZ2V0KGltcG9ydGVkKVxuICAgICAgICBpZiAoZXhwb3J0ZWQgPT0gbnVsbCkgcmV0dXJuXG5cbiAgICAgICAgLy8gY2FwdHVyZSBpbXBvcnQgb2YgZGVlcCBuYW1lc3BhY2VcbiAgICAgICAgaWYgKGV4cG9ydGVkLm5hbWVzcGFjZSkgbmFtZXNwYWNlcy5zZXQobG9jYWwsIGV4cG9ydGVkLm5hbWVzcGFjZSlcblxuICAgICAgICBjb25zdCBkZXByZWNhdGlvbiA9IGdldERlcHJlY2F0aW9uKGltcG9ydHMuZ2V0KGltcG9ydGVkKSlcbiAgICAgICAgaWYgKCFkZXByZWNhdGlvbikgcmV0dXJuXG5cbiAgICAgICAgY29udGV4dC5yZXBvcnQoeyBub2RlOiBpbSwgbWVzc2FnZTogbWVzc2FnZShkZXByZWNhdGlvbikgfSlcblxuICAgICAgICBkZXByZWNhdGVkLnNldChsb2NhbCwgZGVwcmVjYXRpb24pXG5cbiAgICAgIH0pXG4gICAgfVxuXG4gICAgcmV0dXJuIHtcbiAgICAgICdQcm9ncmFtJzogKHsgYm9keSB9KSA9PiBib2R5LmZvckVhY2goY2hlY2tTcGVjaWZpZXJzKSxcblxuICAgICAgJ0lkZW50aWZpZXInOiBmdW5jdGlvbiAobm9kZSkge1xuICAgICAgICBpZiAobm9kZS5wYXJlbnQudHlwZSA9PT0gJ01lbWJlckV4cHJlc3Npb24nICYmIG5vZGUucGFyZW50LnByb3BlcnR5ID09PSBub2RlKSB7XG4gICAgICAgICAgcmV0dXJuIC8vIGhhbmRsZWQgYnkgTWVtYmVyRXhwcmVzc2lvblxuICAgICAgICB9XG5cbiAgICAgICAgLy8gaWdub3JlIHNwZWNpZmllciBpZGVudGlmaWVyc1xuICAgICAgICBpZiAobm9kZS5wYXJlbnQudHlwZS5zbGljZSgwLCA2KSA9PT0gJ0ltcG9ydCcpIHJldHVyblxuXG4gICAgICAgIGlmICghZGVwcmVjYXRlZC5oYXMobm9kZS5uYW1lKSkgcmV0dXJuXG5cbiAgICAgICAgaWYgKGRlY2xhcmVkU2NvcGUoY29udGV4dCwgbm9kZS5uYW1lKSAhPT0gJ21vZHVsZScpIHJldHVyblxuICAgICAgICBjb250ZXh0LnJlcG9ydCh7XG4gICAgICAgICAgbm9kZSxcbiAgICAgICAgICBtZXNzYWdlOiBtZXNzYWdlKGRlcHJlY2F0ZWQuZ2V0KG5vZGUubmFtZSkpLFxuICAgICAgICB9KVxuICAgICAgfSxcblxuICAgICAgJ01lbWJlckV4cHJlc3Npb24nOiBmdW5jdGlvbiAoZGVyZWZlcmVuY2UpIHtcbiAgICAgICAgaWYgKGRlcmVmZXJlbmNlLm9iamVjdC50eXBlICE9PSAnSWRlbnRpZmllcicpIHJldHVyblxuICAgICAgICBpZiAoIW5hbWVzcGFjZXMuaGFzKGRlcmVmZXJlbmNlLm9iamVjdC5uYW1lKSkgcmV0dXJuXG5cbiAgICAgICAgaWYgKGRlY2xhcmVkU2NvcGUoY29udGV4dCwgZGVyZWZlcmVuY2Uub2JqZWN0Lm5hbWUpICE9PSAnbW9kdWxlJykgcmV0dXJuXG5cbiAgICAgICAgLy8gZ28gZGVlcFxuICAgICAgICB2YXIgbmFtZXNwYWNlID0gbmFtZXNwYWNlcy5nZXQoZGVyZWZlcmVuY2Uub2JqZWN0Lm5hbWUpXG4gICAgICAgIHZhciBuYW1lcGF0aCA9IFtkZXJlZmVyZW5jZS5vYmplY3QubmFtZV1cbiAgICAgICAgLy8gd2hpbGUgcHJvcGVydHkgaXMgbmFtZXNwYWNlIGFuZCBwYXJlbnQgaXMgbWVtYmVyIGV4cHJlc3Npb24sIGtlZXAgdmFsaWRhdGluZ1xuICAgICAgICB3aGlsZSAobmFtZXNwYWNlIGluc3RhbmNlb2YgRXhwb3J0cyAmJlxuICAgICAgICAgICAgICAgZGVyZWZlcmVuY2UudHlwZSA9PT0gJ01lbWJlckV4cHJlc3Npb24nKSB7XG5cbiAgICAgICAgICAvLyBpZ25vcmUgY29tcHV0ZWQgcGFydHMgZm9yIG5vd1xuICAgICAgICAgIGlmIChkZXJlZmVyZW5jZS5jb21wdXRlZCkgcmV0dXJuXG5cbiAgICAgICAgICBjb25zdCBtZXRhZGF0YSA9IG5hbWVzcGFjZS5nZXQoZGVyZWZlcmVuY2UucHJvcGVydHkubmFtZSlcblxuICAgICAgICAgIGlmICghbWV0YWRhdGEpIGJyZWFrXG4gICAgICAgICAgY29uc3QgZGVwcmVjYXRpb24gPSBnZXREZXByZWNhdGlvbihtZXRhZGF0YSlcblxuICAgICAgICAgIGlmIChkZXByZWNhdGlvbikge1xuICAgICAgICAgICAgY29udGV4dC5yZXBvcnQoeyBub2RlOiBkZXJlZmVyZW5jZS5wcm9wZXJ0eSwgbWVzc2FnZTogbWVzc2FnZShkZXByZWNhdGlvbikgfSlcbiAgICAgICAgICB9XG5cbiAgICAgICAgICAvLyBzdGFzaCBhbmQgcG9wXG4gICAgICAgICAgbmFtZXBhdGgucHVzaChkZXJlZmVyZW5jZS5wcm9wZXJ0eS5uYW1lKVxuICAgICAgICAgIG5hbWVzcGFjZSA9IG1ldGFkYXRhLm5hbWVzcGFjZVxuICAgICAgICAgIGRlcmVmZXJlbmNlID0gZGVyZWZlcmVuY2UucGFyZW50XG4gICAgICAgIH1cbiAgICAgIH0sXG4gICAgfVxuICB9LFxufVxuIl19