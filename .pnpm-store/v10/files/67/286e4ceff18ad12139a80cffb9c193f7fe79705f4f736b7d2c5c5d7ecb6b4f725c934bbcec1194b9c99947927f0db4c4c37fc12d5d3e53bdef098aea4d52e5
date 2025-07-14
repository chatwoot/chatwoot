'use strict';var _declaredScope = require('eslint-module-utils/declaredScope');var _declaredScope2 = _interopRequireDefault(_declaredScope);
var _builder = require('../exportMap/builder');var _builder2 = _interopRequireDefault(_builder);
var _exportMap = require('../exportMap');var _exportMap2 = _interopRequireDefault(_exportMap);
var _docsUrl = require('../docsUrl');var _docsUrl2 = _interopRequireDefault(_docsUrl);function _interopRequireDefault(obj) {return obj && obj.__esModule ? obj : { 'default': obj };}

function message(deprecation) {
  return 'Deprecated' + (deprecation.description ? ': ' + String(deprecation.description) : '.');
}

function getDeprecation(metadata) {
  if (!metadata || !metadata.doc) {return;}

  return metadata.doc.tags.find(function (t) {return t.title === 'deprecated';});
}

module.exports = {
  meta: {
    type: 'suggestion',
    docs: {
      category: 'Helpful warnings',
      description: 'Forbid imported names marked with `@deprecated` documentation tag.',
      url: (0, _docsUrl2['default'])('no-deprecated') },

    schema: [] },


  create: function () {function create(context) {
      var deprecated = new Map();
      var namespaces = new Map();

      function checkSpecifiers(node) {
        if (node.type !== 'ImportDeclaration') {return;}
        if (node.source == null) {return;} // local export, ignore

        var imports = _builder2['default'].get(node.source.value, context);
        if (imports == null) {return;}

        var moduleDeprecation = imports.doc && imports.doc.tags.find(function (t) {return t.title === 'deprecated';});
        if (moduleDeprecation) {
          context.report({ node: node, message: message(moduleDeprecation) });
        }

        if (imports.errors.length) {
          imports.reportErrors(context, node);
          return;
        }

        node.specifiers.forEach(function (im) {
          var imported = void 0;var local = void 0;
          switch (im.type) {

            case 'ImportNamespaceSpecifier':{
                if (!imports.size) {return;}
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
          var exported = imports.get(imported);
          if (exported == null) {return;}

          // capture import of deep namespace
          if (exported.namespace) {namespaces.set(local, exported.namespace);}

          var deprecation = getDeprecation(imports.get(imported));
          if (!deprecation) {return;}

          context.report({ node: im, message: message(deprecation) });

          deprecated.set(local, deprecation);

        });
      }

      return {
        Program: function () {function Program(_ref) {var body = _ref.body;return body.forEach(checkSpecifiers);}return Program;}(),

        Identifier: function () {function Identifier(node) {
            if (node.parent.type === 'MemberExpression' && node.parent.property === node) {
              return; // handled by MemberExpression
            }

            // ignore specifier identifiers
            if (node.parent.type.slice(0, 6) === 'Import') {return;}

            if (!deprecated.has(node.name)) {return;}

            if ((0, _declaredScope2['default'])(context, node.name) !== 'module') {return;}
            context.report({
              node: node,
              message: message(deprecated.get(node.name)) });

          }return Identifier;}(),

        MemberExpression: function () {function MemberExpression(dereference) {
            if (dereference.object.type !== 'Identifier') {return;}
            if (!namespaces.has(dereference.object.name)) {return;}

            if ((0, _declaredScope2['default'])(context, dereference.object.name) !== 'module') {return;}

            // go deep
            var namespace = namespaces.get(dereference.object.name);
            var namepath = [dereference.object.name];
            // while property is namespace and parent is member expression, keep validating
            while (namespace instanceof _exportMap2['default'] && dereference.type === 'MemberExpression') {
              // ignore computed parts for now
              if (dereference.computed) {return;}

              var metadata = namespace.get(dereference.property.name);

              if (!metadata) {break;}
              var deprecation = getDeprecation(metadata);

              if (deprecation) {
                context.report({ node: dereference.property, message: message(deprecation) });
              }

              // stash and pop
              namepath.push(dereference.property.name);
              namespace = metadata.namespace;
              dereference = dereference.parent;
            }
          }return MemberExpression;}() };

    }return create;}() };
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIi4uLy4uL3NyYy9ydWxlcy9uby1kZXByZWNhdGVkLmpzIl0sIm5hbWVzIjpbIm1lc3NhZ2UiLCJkZXByZWNhdGlvbiIsImRlc2NyaXB0aW9uIiwiZ2V0RGVwcmVjYXRpb24iLCJtZXRhZGF0YSIsImRvYyIsInRhZ3MiLCJmaW5kIiwidCIsInRpdGxlIiwibW9kdWxlIiwiZXhwb3J0cyIsIm1ldGEiLCJ0eXBlIiwiZG9jcyIsImNhdGVnb3J5IiwidXJsIiwic2NoZW1hIiwiY3JlYXRlIiwiY29udGV4dCIsImRlcHJlY2F0ZWQiLCJNYXAiLCJuYW1lc3BhY2VzIiwiY2hlY2tTcGVjaWZpZXJzIiwibm9kZSIsInNvdXJjZSIsImltcG9ydHMiLCJFeHBvcnRNYXBCdWlsZGVyIiwiZ2V0IiwidmFsdWUiLCJtb2R1bGVEZXByZWNhdGlvbiIsInJlcG9ydCIsImVycm9ycyIsImxlbmd0aCIsInJlcG9ydEVycm9ycyIsInNwZWNpZmllcnMiLCJmb3JFYWNoIiwiaW0iLCJpbXBvcnRlZCIsImxvY2FsIiwic2l6ZSIsInNldCIsIm5hbWUiLCJleHBvcnRlZCIsIm5hbWVzcGFjZSIsIlByb2dyYW0iLCJib2R5IiwiSWRlbnRpZmllciIsInBhcmVudCIsInByb3BlcnR5Iiwic2xpY2UiLCJoYXMiLCJNZW1iZXJFeHByZXNzaW9uIiwiZGVyZWZlcmVuY2UiLCJvYmplY3QiLCJuYW1lcGF0aCIsIkV4cG9ydE1hcCIsImNvbXB1dGVkIiwicHVzaCJdLCJtYXBwaW5ncyI6ImFBQUEsa0U7QUFDQSwrQztBQUNBLHlDO0FBQ0EscUM7O0FBRUEsU0FBU0EsT0FBVCxDQUFpQkMsV0FBakIsRUFBOEI7QUFDNUIseUJBQW9CQSxZQUFZQyxXQUFaLGlCQUErQkQsWUFBWUMsV0FBM0MsSUFBMkQsR0FBL0U7QUFDRDs7QUFFRCxTQUFTQyxjQUFULENBQXdCQyxRQUF4QixFQUFrQztBQUNoQyxNQUFJLENBQUNBLFFBQUQsSUFBYSxDQUFDQSxTQUFTQyxHQUEzQixFQUFnQyxDQUFFLE9BQVM7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RUFBa0UsQ0FBRSxPQUFTOztBQUU3RTtBQUNBLGdCQUFJRSxZQUFZdEIsV0FBV00sR0FBWCxDQUFleUIsWUFBWUMsTUFBWixDQUFtQlosSUFBbEMsQ0FBaEI7QUFDQSxnQkFBTWEsV0FBVyxDQUFDRixZQUFZQyxNQUFaLENBQW1CWixJQUFwQixDQUFqQjtBQUNBO0FBQ0EsbUJBQU9FLHFCQUFxQlksc0JBQXJCLElBQWtDSCxZQUFZeEMsSUFBWixLQUFxQixrQkFBOUQsRUFBa0Y7QUFDaEY7QUFDQSxrQkFBSXdDLFlBQVlJLFFBQWhCLEVBQTBCLENBQUUsT0FBUzs7QUFFckMsa0JBQU1yRCxXQUFXd0MsVUFBVWhCLEdBQVYsQ0FBY3lCLFlBQVlKLFFBQVosQ0FBcUJQLElBQW5DLENBQWpCOztBQUVBLGtCQUFJLENBQUN0QyxRQUFMLEVBQWUsQ0FBRSxNQUFRO0FBQ3pCLGtCQUFNSCxjQUFjRSxlQUFlQyxRQUFmLENBQXBCOztBQUVBLGtCQUFJSCxXQUFKLEVBQWlCO0FBQ2ZrQix3QkFBUVksTUFBUixDQUFlLEVBQUVQLE1BQU02QixZQUFZSixRQUFwQixFQUE4QmpELFNBQVNBLFFBQVFDLFdBQVIsQ0FBdkMsRUFBZjtBQUNEOztBQUVEO0FBQ0FzRCx1QkFBU0csSUFBVCxDQUFjTCxZQUFZSixRQUFaLENBQXFCUCxJQUFuQztBQUNBRSwwQkFBWXhDLFNBQVN3QyxTQUFyQjtBQUNBUyw0QkFBY0EsWUFBWUwsTUFBMUI7QUFDRDtBQUNGLFdBaERJLDZCQUFQOztBQWtERCxLQTFIYyxtQkFBakIiLCJmaWxlIjoibm8tZGVwcmVjYXRlZC5qcyIsInNvdXJjZXNDb250ZW50IjpbImltcG9ydCBkZWNsYXJlZFNjb3BlIGZyb20gJ2VzbGludC1tb2R1bGUtdXRpbHMvZGVjbGFyZWRTY29wZSc7XG5pbXBvcnQgRXhwb3J0TWFwQnVpbGRlciBmcm9tICcuLi9leHBvcnRNYXAvYnVpbGRlcic7XG5pbXBvcnQgRXhwb3J0TWFwIGZyb20gJy4uL2V4cG9ydE1hcCc7XG5pbXBvcnQgZG9jc1VybCBmcm9tICcuLi9kb2NzVXJsJztcblxuZnVuY3Rpb24gbWVzc2FnZShkZXByZWNhdGlvbikge1xuICByZXR1cm4gYERlcHJlY2F0ZWQke2RlcHJlY2F0aW9uLmRlc2NyaXB0aW9uID8gYDogJHtkZXByZWNhdGlvbi5kZXNjcmlwdGlvbn1gIDogJy4nfWA7XG59XG5cbmZ1bmN0aW9uIGdldERlcHJlY2F0aW9uKG1ldGFkYXRhKSB7XG4gIGlmICghbWV0YWRhdGEgfHwgIW1ldGFkYXRhLmRvYykgeyByZXR1cm47IH1cblxuICByZXR1cm4gbWV0YWRhdGEuZG9jLnRhZ3MuZmluZCgodCkgPT4gdC50aXRsZSA9PT0gJ2RlcHJlY2F0ZWQnKTtcbn1cblxubW9kdWxlLmV4cG9ydHMgPSB7XG4gIG1ldGE6IHtcbiAgICB0eXBlOiAnc3VnZ2VzdGlvbicsXG4gICAgZG9jczoge1xuICAgICAgY2F0ZWdvcnk6ICdIZWxwZnVsIHdhcm5pbmdzJyxcbiAgICAgIGRlc2NyaXB0aW9uOiAnRm9yYmlkIGltcG9ydGVkIG5hbWVzIG1hcmtlZCB3aXRoIGBAZGVwcmVjYXRlZGAgZG9jdW1lbnRhdGlvbiB0YWcuJyxcbiAgICAgIHVybDogZG9jc1VybCgnbm8tZGVwcmVjYXRlZCcpLFxuICAgIH0sXG4gICAgc2NoZW1hOiBbXSxcbiAgfSxcblxuICBjcmVhdGUoY29udGV4dCkge1xuICAgIGNvbnN0IGRlcHJlY2F0ZWQgPSBuZXcgTWFwKCk7XG4gICAgY29uc3QgbmFtZXNwYWNlcyA9IG5ldyBNYXAoKTtcblxuICAgIGZ1bmN0aW9uIGNoZWNrU3BlY2lmaWVycyhub2RlKSB7XG4gICAgICBpZiAobm9kZS50eXBlICE9PSAnSW1wb3J0RGVjbGFyYXRpb24nKSB7IHJldHVybjsgfVxuICAgICAgaWYgKG5vZGUuc291cmNlID09IG51bGwpIHsgcmV0dXJuOyB9IC8vIGxvY2FsIGV4cG9ydCwgaWdub3JlXG5cbiAgICAgIGNvbnN0IGltcG9ydHMgPSBFeHBvcnRNYXBCdWlsZGVyLmdldChub2RlLnNvdXJjZS52YWx1ZSwgY29udGV4dCk7XG4gICAgICBpZiAoaW1wb3J0cyA9PSBudWxsKSB7IHJldHVybjsgfVxuXG4gICAgICBjb25zdCBtb2R1bGVEZXByZWNhdGlvbiA9IGltcG9ydHMuZG9jICYmIGltcG9ydHMuZG9jLnRhZ3MuZmluZCgodCkgPT4gdC50aXRsZSA9PT0gJ2RlcHJlY2F0ZWQnKTtcbiAgICAgIGlmIChtb2R1bGVEZXByZWNhdGlvbikge1xuICAgICAgICBjb250ZXh0LnJlcG9ydCh7IG5vZGUsIG1lc3NhZ2U6IG1lc3NhZ2UobW9kdWxlRGVwcmVjYXRpb24pIH0pO1xuICAgICAgfVxuXG4gICAgICBpZiAoaW1wb3J0cy5lcnJvcnMubGVuZ3RoKSB7XG4gICAgICAgIGltcG9ydHMucmVwb3J0RXJyb3JzKGNvbnRleHQsIG5vZGUpO1xuICAgICAgICByZXR1cm47XG4gICAgICB9XG5cbiAgICAgIG5vZGUuc3BlY2lmaWVycy5mb3JFYWNoKGZ1bmN0aW9uIChpbSkge1xuICAgICAgICBsZXQgaW1wb3J0ZWQ7IGxldCBsb2NhbDtcbiAgICAgICAgc3dpdGNoIChpbS50eXBlKSB7XG5cbiAgICAgICAgICBjYXNlICdJbXBvcnROYW1lc3BhY2VTcGVjaWZpZXInOiB7XG4gICAgICAgICAgICBpZiAoIWltcG9ydHMuc2l6ZSkgeyByZXR1cm47IH1cbiAgICAgICAgICAgIG5hbWVzcGFjZXMuc2V0KGltLmxvY2FsLm5hbWUsIGltcG9ydHMpO1xuICAgICAgICAgICAgcmV0dXJuO1xuICAgICAgICAgIH1cblxuICAgICAgICAgIGNhc2UgJ0ltcG9ydERlZmF1bHRTcGVjaWZpZXInOlxuICAgICAgICAgICAgaW1wb3J0ZWQgPSAnZGVmYXVsdCc7XG4gICAgICAgICAgICBsb2NhbCA9IGltLmxvY2FsLm5hbWU7XG4gICAgICAgICAgICBicmVhaztcblxuICAgICAgICAgIGNhc2UgJ0ltcG9ydFNwZWNpZmllcic6XG4gICAgICAgICAgICBpbXBvcnRlZCA9IGltLmltcG9ydGVkLm5hbWU7XG4gICAgICAgICAgICBsb2NhbCA9IGltLmxvY2FsLm5hbWU7XG4gICAgICAgICAgICBicmVhaztcblxuICAgICAgICAgIGRlZmF1bHQ6IHJldHVybjsgLy8gY2FuJ3QgaGFuZGxlIHRoaXMgb25lXG4gICAgICAgIH1cblxuICAgICAgICAvLyB1bmtub3duIHRoaW5nIGNhbid0IGJlIGRlcHJlY2F0ZWRcbiAgICAgICAgY29uc3QgZXhwb3J0ZWQgPSBpbXBvcnRzLmdldChpbXBvcnRlZCk7XG4gICAgICAgIGlmIChleHBvcnRlZCA9PSBudWxsKSB7IHJldHVybjsgfVxuXG4gICAgICAgIC8vIGNhcHR1cmUgaW1wb3J0IG9mIGRlZXAgbmFtZXNwYWNlXG4gICAgICAgIGlmIChleHBvcnRlZC5uYW1lc3BhY2UpIHsgbmFtZXNwYWNlcy5zZXQobG9jYWwsIGV4cG9ydGVkLm5hbWVzcGFjZSk7IH1cblxuICAgICAgICBjb25zdCBkZXByZWNhdGlvbiA9IGdldERlcHJlY2F0aW9uKGltcG9ydHMuZ2V0KGltcG9ydGVkKSk7XG4gICAgICAgIGlmICghZGVwcmVjYXRpb24pIHsgcmV0dXJuOyB9XG5cbiAgICAgICAgY29udGV4dC5yZXBvcnQoeyBub2RlOiBpbSwgbWVzc2FnZTogbWVzc2FnZShkZXByZWNhdGlvbikgfSk7XG5cbiAgICAgICAgZGVwcmVjYXRlZC5zZXQobG9jYWwsIGRlcHJlY2F0aW9uKTtcblxuICAgICAgfSk7XG4gICAgfVxuXG4gICAgcmV0dXJuIHtcbiAgICAgIFByb2dyYW06ICh7IGJvZHkgfSkgPT4gYm9keS5mb3JFYWNoKGNoZWNrU3BlY2lmaWVycyksXG5cbiAgICAgIElkZW50aWZpZXIobm9kZSkge1xuICAgICAgICBpZiAobm9kZS5wYXJlbnQudHlwZSA9PT0gJ01lbWJlckV4cHJlc3Npb24nICYmIG5vZGUucGFyZW50LnByb3BlcnR5ID09PSBub2RlKSB7XG4gICAgICAgICAgcmV0dXJuOyAvLyBoYW5kbGVkIGJ5IE1lbWJlckV4cHJlc3Npb25cbiAgICAgICAgfVxuXG4gICAgICAgIC8vIGlnbm9yZSBzcGVjaWZpZXIgaWRlbnRpZmllcnNcbiAgICAgICAgaWYgKG5vZGUucGFyZW50LnR5cGUuc2xpY2UoMCwgNikgPT09ICdJbXBvcnQnKSB7IHJldHVybjsgfVxuXG4gICAgICAgIGlmICghZGVwcmVjYXRlZC5oYXMobm9kZS5uYW1lKSkgeyByZXR1cm47IH1cblxuICAgICAgICBpZiAoZGVjbGFyZWRTY29wZShjb250ZXh0LCBub2RlLm5hbWUpICE9PSAnbW9kdWxlJykgeyByZXR1cm47IH1cbiAgICAgICAgY29udGV4dC5yZXBvcnQoe1xuICAgICAgICAgIG5vZGUsXG4gICAgICAgICAgbWVzc2FnZTogbWVzc2FnZShkZXByZWNhdGVkLmdldChub2RlLm5hbWUpKSxcbiAgICAgICAgfSk7XG4gICAgICB9LFxuXG4gICAgICBNZW1iZXJFeHByZXNzaW9uKGRlcmVmZXJlbmNlKSB7XG4gICAgICAgIGlmIChkZXJlZmVyZW5jZS5vYmplY3QudHlwZSAhPT0gJ0lkZW50aWZpZXInKSB7IHJldHVybjsgfVxuICAgICAgICBpZiAoIW5hbWVzcGFjZXMuaGFzKGRlcmVmZXJlbmNlLm9iamVjdC5uYW1lKSkgeyByZXR1cm47IH1cblxuICAgICAgICBpZiAoZGVjbGFyZWRTY29wZShjb250ZXh0LCBkZXJlZmVyZW5jZS5vYmplY3QubmFtZSkgIT09ICdtb2R1bGUnKSB7IHJldHVybjsgfVxuXG4gICAgICAgIC8vIGdvIGRlZXBcbiAgICAgICAgbGV0IG5hbWVzcGFjZSA9IG5hbWVzcGFjZXMuZ2V0KGRlcmVmZXJlbmNlLm9iamVjdC5uYW1lKTtcbiAgICAgICAgY29uc3QgbmFtZXBhdGggPSBbZGVyZWZlcmVuY2Uub2JqZWN0Lm5hbWVdO1xuICAgICAgICAvLyB3aGlsZSBwcm9wZXJ0eSBpcyBuYW1lc3BhY2UgYW5kIHBhcmVudCBpcyBtZW1iZXIgZXhwcmVzc2lvbiwga2VlcCB2YWxpZGF0aW5nXG4gICAgICAgIHdoaWxlIChuYW1lc3BhY2UgaW5zdGFuY2VvZiBFeHBvcnRNYXAgJiYgZGVyZWZlcmVuY2UudHlwZSA9PT0gJ01lbWJlckV4cHJlc3Npb24nKSB7XG4gICAgICAgICAgLy8gaWdub3JlIGNvbXB1dGVkIHBhcnRzIGZvciBub3dcbiAgICAgICAgICBpZiAoZGVyZWZlcmVuY2UuY29tcHV0ZWQpIHsgcmV0dXJuOyB9XG5cbiAgICAgICAgICBjb25zdCBtZXRhZGF0YSA9IG5hbWVzcGFjZS5nZXQoZGVyZWZlcmVuY2UucHJvcGVydHkubmFtZSk7XG5cbiAgICAgICAgICBpZiAoIW1ldGFkYXRhKSB7IGJyZWFrOyB9XG4gICAgICAgICAgY29uc3QgZGVwcmVjYXRpb24gPSBnZXREZXByZWNhdGlvbihtZXRhZGF0YSk7XG5cbiAgICAgICAgICBpZiAoZGVwcmVjYXRpb24pIHtcbiAgICAgICAgICAgIGNvbnRleHQucmVwb3J0KHsgbm9kZTogZGVyZWZlcmVuY2UucHJvcGVydHksIG1lc3NhZ2U6IG1lc3NhZ2UoZGVwcmVjYXRpb24pIH0pO1xuICAgICAgICAgIH1cblxuICAgICAgICAgIC8vIHN0YXNoIGFuZCBwb3BcbiAgICAgICAgICBuYW1lcGF0aC5wdXNoKGRlcmVmZXJlbmNlLnByb3BlcnR5Lm5hbWUpO1xuICAgICAgICAgIG5hbWVzcGFjZSA9IG1ldGFkYXRhLm5hbWVzcGFjZTtcbiAgICAgICAgICBkZXJlZmVyZW5jZSA9IGRlcmVmZXJlbmNlLnBhcmVudDtcbiAgICAgICAgfVxuICAgICAgfSxcbiAgICB9O1xuICB9LFxufTtcbiJdfQ==