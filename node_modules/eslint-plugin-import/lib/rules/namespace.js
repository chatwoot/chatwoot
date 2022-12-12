'use strict';var _declaredScope = require('eslint-module-utils/declaredScope');var _declaredScope2 = _interopRequireDefault(_declaredScope);
var _ExportMap = require('../ExportMap');var _ExportMap2 = _interopRequireDefault(_ExportMap);
var _importDeclaration = require('../importDeclaration');var _importDeclaration2 = _interopRequireDefault(_importDeclaration);
var _docsUrl = require('../docsUrl');var _docsUrl2 = _interopRequireDefault(_docsUrl);function _interopRequireDefault(obj) {return obj && obj.__esModule ? obj : { default: obj };}

module.exports = {
  meta: {
    type: 'problem',
    docs: {
      url: (0, _docsUrl2.default)('namespace') },


    schema: [
    {
      type: 'object',
      properties: {
        allowComputed: {
          description: 'If `false`, will report computed (and thus, un-lintable) references to namespace members.',
          type: 'boolean',
          default: false } },


      additionalProperties: false }] },




  create: function namespaceRule(context) {

    // read options
    var _ref =

    context.options[0] || {},_ref$allowComputed = _ref.allowComputed;const allowComputed = _ref$allowComputed === undefined ? false : _ref$allowComputed;

    const namespaces = new Map();

    function makeMessage(last, namepath) {
      return `'${last.name}' not found in ${namepath.length > 1 ? 'deeply ' : ''}imported namespace '${namepath.join('.')}'.`;
    }

    return {
      // pick up all imports at body entry time, to properly respect hoisting
      Program(_ref2) {let body = _ref2.body;
        function processBodyStatement(declaration) {
          if (declaration.type !== 'ImportDeclaration') return;

          if (declaration.specifiers.length === 0) return;

          const imports = _ExportMap2.default.get(declaration.source.value, context);
          if (imports == null) return null;

          if (imports.errors.length) {
            imports.reportErrors(context, declaration);
            return;
          }

          for (const specifier of declaration.specifiers) {
            switch (specifier.type) {
              case 'ImportNamespaceSpecifier':
                if (!imports.size) {
                  context.report(
                  specifier,
                  `No exported names found in module '${declaration.source.value}'.`);

                }
                namespaces.set(specifier.local.name, imports);
                break;
              case 'ImportDefaultSpecifier':
              case 'ImportSpecifier':{
                  const meta = imports.get(
                  // default to 'default' for default http://i.imgur.com/nj6qAWy.jpg
                  specifier.imported ? specifier.imported.name : 'default');

                  if (!meta || !meta.namespace) {break;}
                  namespaces.set(specifier.local.name, meta.namespace);
                  break;
                }}

          }
        }
        body.forEach(processBodyStatement);
      },

      // same as above, but does not add names to local map
      ExportNamespaceSpecifier(namespace) {
        var declaration = (0, _importDeclaration2.default)(context);

        var imports = _ExportMap2.default.get(declaration.source.value, context);
        if (imports == null) return null;

        if (imports.errors.length) {
          imports.reportErrors(context, declaration);
          return;
        }

        if (!imports.size) {
          context.report(
          namespace,
          `No exported names found in module '${declaration.source.value}'.`);

        }
      },

      // todo: check for possible redefinition

      MemberExpression(dereference) {
        if (dereference.object.type !== 'Identifier') return;
        if (!namespaces.has(dereference.object.name)) return;
        if ((0, _declaredScope2.default)(context, dereference.object.name) !== 'module') return;

        if (dereference.parent.type === 'AssignmentExpression' && dereference.parent.left === dereference) {
          context.report(
          dereference.parent,
          `Assignment to member of namespace '${dereference.object.name}'.`);

        }

        // go deep
        var namespace = namespaces.get(dereference.object.name);
        var namepath = [dereference.object.name];
        // while property is namespace and parent is member expression, keep validating
        while (namespace instanceof _ExportMap2.default && dereference.type === 'MemberExpression') {

          if (dereference.computed) {
            if (!allowComputed) {
              context.report(
              dereference.property,
              `Unable to validate computed reference to imported namespace '${dereference.object.name}'.`);

            }
            return;
          }

          if (!namespace.has(dereference.property.name)) {
            context.report(
            dereference.property,
            makeMessage(dereference.property, namepath));

            break;
          }

          const exported = namespace.get(dereference.property.name);
          if (exported == null) return;

          // stash and pop
          namepath.push(dereference.property.name);
          namespace = exported.namespace;
          dereference = dereference.parent;
        }

      },

      VariableDeclarator(_ref3) {let id = _ref3.id,init = _ref3.init;
        if (init == null) return;
        if (init.type !== 'Identifier') return;
        if (!namespaces.has(init.name)) return;

        // check for redefinition in intermediate scopes
        if ((0, _declaredScope2.default)(context, init.name) !== 'module') return;

        // DFS traverse child namespaces
        function testKey(pattern, namespace) {let path = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : [init.name];
          if (!(namespace instanceof _ExportMap2.default)) return;

          if (pattern.type !== 'ObjectPattern') return;

          for (const property of pattern.properties) {
            if (
            property.type === 'ExperimentalRestProperty' ||
            property.type === 'RestElement' ||
            !property.key)
            {
              continue;
            }

            if (property.key.type !== 'Identifier') {
              context.report({
                node: property,
                message: 'Only destructure top-level names.' });

              continue;
            }

            if (!namespace.has(property.key.name)) {
              context.report({
                node: property,
                message: makeMessage(property.key, path) });

              continue;
            }

            path.push(property.key.name);
            const dependencyExportMap = namespace.get(property.key.name);
            // could be null when ignored or ambiguous
            if (dependencyExportMap !== null) {
              testKey(property.value, dependencyExportMap.namespace, path);
            }
            path.pop();
          }
        }

        testKey(id, namespaces.get(init.name));
      },

      JSXMemberExpression(_ref4) {let object = _ref4.object,property = _ref4.property;
        if (!namespaces.has(object.name)) return;
        var namespace = namespaces.get(object.name);
        if (!namespace.has(property.name)) {
          context.report({
            node: property,
            message: makeMessage(property, [object.name]) });

        }
      } };

  } };
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIi4uLy4uL3NyYy9ydWxlcy9uYW1lc3BhY2UuanMiXSwibmFtZXMiOlsibW9kdWxlIiwiZXhwb3J0cyIsIm1ldGEiLCJ0eXBlIiwiZG9jcyIsInVybCIsInNjaGVtYSIsInByb3BlcnRpZXMiLCJhbGxvd0NvbXB1dGVkIiwiZGVzY3JpcHRpb24iLCJkZWZhdWx0IiwiYWRkaXRpb25hbFByb3BlcnRpZXMiLCJjcmVhdGUiLCJuYW1lc3BhY2VSdWxlIiwiY29udGV4dCIsIm9wdGlvbnMiLCJuYW1lc3BhY2VzIiwiTWFwIiwibWFrZU1lc3NhZ2UiLCJsYXN0IiwibmFtZXBhdGgiLCJuYW1lIiwibGVuZ3RoIiwiam9pbiIsIlByb2dyYW0iLCJib2R5IiwicHJvY2Vzc0JvZHlTdGF0ZW1lbnQiLCJkZWNsYXJhdGlvbiIsInNwZWNpZmllcnMiLCJpbXBvcnRzIiwiRXhwb3J0cyIsImdldCIsInNvdXJjZSIsInZhbHVlIiwiZXJyb3JzIiwicmVwb3J0RXJyb3JzIiwic3BlY2lmaWVyIiwic2l6ZSIsInJlcG9ydCIsInNldCIsImxvY2FsIiwiaW1wb3J0ZWQiLCJuYW1lc3BhY2UiLCJmb3JFYWNoIiwiRXhwb3J0TmFtZXNwYWNlU3BlY2lmaWVyIiwiTWVtYmVyRXhwcmVzc2lvbiIsImRlcmVmZXJlbmNlIiwib2JqZWN0IiwiaGFzIiwicGFyZW50IiwibGVmdCIsImNvbXB1dGVkIiwicHJvcGVydHkiLCJleHBvcnRlZCIsInB1c2giLCJWYXJpYWJsZURlY2xhcmF0b3IiLCJpZCIsImluaXQiLCJ0ZXN0S2V5IiwicGF0dGVybiIsInBhdGgiLCJrZXkiLCJub2RlIiwibWVzc2FnZSIsImRlcGVuZGVuY3lFeHBvcnRNYXAiLCJwb3AiLCJKU1hNZW1iZXJFeHByZXNzaW9uIl0sIm1hcHBpbmdzIjoiYUFBQSxrRTtBQUNBLHlDO0FBQ0EseUQ7QUFDQSxxQzs7QUFFQUEsT0FBT0MsT0FBUCxHQUFpQjtBQUNmQyxRQUFNO0FBQ0pDLFVBQU0sU0FERjtBQUVKQyxVQUFNO0FBQ0pD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LElBQXRCLENBQUwsRUFBa0M7QUFDbEMsWUFBSXFCLFlBQVkxQixXQUFXZSxHQUFYLENBQWVnQixPQUFPMUIsSUFBdEIsQ0FBaEI7QUFDQSxZQUFJLENBQUNxQixVQUFVTSxHQUFWLENBQWNJLFNBQVMvQixJQUF2QixDQUFMLEVBQW1DO0FBQ2pDUCxrQkFBUXdCLE1BQVIsQ0FBZTtBQUNid0Isa0JBQU1WLFFBRE87QUFFYlcscUJBQVM3QyxZQUFZa0MsUUFBWixFQUFzQixDQUFDTCxPQUFPMUIsSUFBUixDQUF0QixDQUZJLEVBQWY7O0FBSUQ7QUFDSCxPQTdLSSxFQUFQOztBQStLRCxHQWxOYyxFQUFqQiIsImZpbGUiOiJuYW1lc3BhY2UuanMiLCJzb3VyY2VzQ29udGVudCI6WyJpbXBvcnQgZGVjbGFyZWRTY29wZSBmcm9tICdlc2xpbnQtbW9kdWxlLXV0aWxzL2RlY2xhcmVkU2NvcGUnXG5pbXBvcnQgRXhwb3J0cyBmcm9tICcuLi9FeHBvcnRNYXAnXG5pbXBvcnQgaW1wb3J0RGVjbGFyYXRpb24gZnJvbSAnLi4vaW1wb3J0RGVjbGFyYXRpb24nXG5pbXBvcnQgZG9jc1VybCBmcm9tICcuLi9kb2NzVXJsJ1xuXG5tb2R1bGUuZXhwb3J0cyA9IHtcbiAgbWV0YToge1xuICAgIHR5cGU6ICdwcm9ibGVtJyxcbiAgICBkb2NzOiB7XG4gICAgICB1cmw6IGRvY3NVcmwoJ25hbWVzcGFjZScpLFxuICAgIH0sXG5cbiAgICBzY2hlbWE6IFtcbiAgICAgIHtcbiAgICAgICAgdHlwZTogJ29iamVjdCcsXG4gICAgICAgIHByb3BlcnRpZXM6IHtcbiAgICAgICAgICBhbGxvd0NvbXB1dGVkOiB7XG4gICAgICAgICAgICBkZXNjcmlwdGlvbjogJ0lmIGBmYWxzZWAsIHdpbGwgcmVwb3J0IGNvbXB1dGVkIChhbmQgdGh1cywgdW4tbGludGFibGUpIHJlZmVyZW5jZXMgdG8gbmFtZXNwYWNlIG1lbWJlcnMuJyxcbiAgICAgICAgICAgIHR5cGU6ICdib29sZWFuJyxcbiAgICAgICAgICAgIGRlZmF1bHQ6IGZhbHNlLFxuICAgICAgICAgIH0sXG4gICAgICAgIH0sXG4gICAgICAgIGFkZGl0aW9uYWxQcm9wZXJ0aWVzOiBmYWxzZSxcbiAgICAgIH0sXG4gICAgXSxcbiAgfSxcblxuICBjcmVhdGU6IGZ1bmN0aW9uIG5hbWVzcGFjZVJ1bGUoY29udGV4dCkge1xuXG4gICAgLy8gcmVhZCBvcHRpb25zXG4gICAgY29uc3Qge1xuICAgICAgYWxsb3dDb21wdXRlZCA9IGZhbHNlLFxuICAgIH0gPSBjb250ZXh0Lm9wdGlvbnNbMF0gfHwge31cblxuICAgIGNvbnN0IG5hbWVzcGFjZXMgPSBuZXcgTWFwKClcblxuICAgIGZ1bmN0aW9uIG1ha2VNZXNzYWdlKGxhc3QsIG5hbWVwYXRoKSB7XG4gICAgICByZXR1cm4gYCcke2xhc3QubmFtZX0nIG5vdCBmb3VuZCBpbiAke25hbWVwYXRoLmxlbmd0aCA+IDEgPyAnZGVlcGx5ICcgOiAnJ31pbXBvcnRlZCBuYW1lc3BhY2UgJyR7bmFtZXBhdGguam9pbignLicpfScuYFxuICAgIH1cblxuICAgIHJldHVybiB7XG4gICAgICAvLyBwaWNrIHVwIGFsbCBpbXBvcnRzIGF0IGJvZHkgZW50cnkgdGltZSwgdG8gcHJvcGVybHkgcmVzcGVjdCBob2lzdGluZ1xuICAgICAgUHJvZ3JhbSh7IGJvZHkgfSkge1xuICAgICAgICBmdW5jdGlvbiBwcm9jZXNzQm9keVN0YXRlbWVudChkZWNsYXJhdGlvbikge1xuICAgICAgICAgIGlmIChkZWNsYXJhdGlvbi50eXBlICE9PSAnSW1wb3J0RGVjbGFyYXRpb24nKSByZXR1cm5cblxuICAgICAgICAgIGlmIChkZWNsYXJhdGlvbi5zcGVjaWZpZXJzLmxlbmd0aCA9PT0gMCkgcmV0dXJuXG5cbiAgICAgICAgICBjb25zdCBpbXBvcnRzID0gRXhwb3J0cy5nZXQoZGVjbGFyYXRpb24uc291cmNlLnZhbHVlLCBjb250ZXh0KVxuICAgICAgICAgIGlmIChpbXBvcnRzID09IG51bGwpIHJldHVybiBudWxsXG5cbiAgICAgICAgICBpZiAoaW1wb3J0cy5lcnJvcnMubGVuZ3RoKSB7XG4gICAgICAgICAgICBpbXBvcnRzLnJlcG9ydEVycm9ycyhjb250ZXh0LCBkZWNsYXJhdGlvbilcbiAgICAgICAgICAgIHJldHVyblxuICAgICAgICAgIH1cblxuICAgICAgICAgIGZvciAoY29uc3Qgc3BlY2lmaWVyIG9mIGRlY2xhcmF0aW9uLnNwZWNpZmllcnMpIHtcbiAgICAgICAgICAgIHN3aXRjaCAoc3BlY2lmaWVyLnR5cGUpIHtcbiAgICAgICAgICAgICAgY2FzZSAnSW1wb3J0TmFtZXNwYWNlU3BlY2lmaWVyJzpcbiAgICAgICAgICAgICAgICBpZiAoIWltcG9ydHMuc2l6ZSkge1xuICAgICAgICAgICAgICAgICAgY29udGV4dC5yZXBvcnQoXG4gICAgICAgICAgICAgICAgICAgIHNwZWNpZmllcixcbiAgICAgICAgICAgICAgICAgICAgYE5vIGV4cG9ydGVkIG5hbWVzIGZvdW5kIGluIG1vZHVsZSAnJHtkZWNsYXJhdGlvbi5zb3VyY2UudmFsdWV9Jy5gXG4gICAgICAgICAgICAgICAgICApXG4gICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgICAgIG5hbWVzcGFjZXMuc2V0KHNwZWNpZmllci5sb2NhbC5uYW1lLCBpbXBvcnRzKVxuICAgICAgICAgICAgICAgIGJyZWFrXG4gICAgICAgICAgICAgIGNhc2UgJ0ltcG9ydERlZmF1bHRTcGVjaWZpZXInOlxuICAgICAgICAgICAgICBjYXNlICdJbXBvcnRTcGVjaWZpZXInOiB7XG4gICAgICAgICAgICAgICAgY29uc3QgbWV0YSA9IGltcG9ydHMuZ2V0KFxuICAgICAgICAgICAgICAgICAgLy8gZGVmYXVsdCB0byAnZGVmYXVsdCcgZm9yIGRlZmF1bHQgaHR0cDovL2kuaW1ndXIuY29tL25qNnFBV3kuanBnXG4gICAgICAgICAgICAgICAgICBzcGVjaWZpZXIuaW1wb3J0ZWQgPyBzcGVjaWZpZXIuaW1wb3J0ZWQubmFtZSA6ICdkZWZhdWx0J1xuICAgICAgICAgICAgICAgIClcbiAgICAgICAgICAgICAgICBpZiAoIW1ldGEgfHwgIW1ldGEubmFtZXNwYWNlKSB7IGJyZWFrIH1cbiAgICAgICAgICAgICAgICBuYW1lc3BhY2VzLnNldChzcGVjaWZpZXIubG9jYWwubmFtZSwgbWV0YS5uYW1lc3BhY2UpXG4gICAgICAgICAgICAgICAgYnJlYWtcbiAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgfVxuICAgICAgICAgIH1cbiAgICAgICAgfVxuICAgICAgICBib2R5LmZvckVhY2gocHJvY2Vzc0JvZHlTdGF0ZW1lbnQpXG4gICAgICB9LFxuXG4gICAgICAvLyBzYW1lIGFzIGFib3ZlLCBidXQgZG9lcyBub3QgYWRkIG5hbWVzIHRvIGxvY2FsIG1hcFxuICAgICAgRXhwb3J0TmFtZXNwYWNlU3BlY2lmaWVyKG5hbWVzcGFjZSkge1xuICAgICAgICB2YXIgZGVjbGFyYXRpb24gPSBpbXBvcnREZWNsYXJhdGlvbihjb250ZXh0KVxuXG4gICAgICAgIHZhciBpbXBvcnRzID0gRXhwb3J0cy5nZXQoZGVjbGFyYXRpb24uc291cmNlLnZhbHVlLCBjb250ZXh0KVxuICAgICAgICBpZiAoaW1wb3J0cyA9PSBudWxsKSByZXR1cm4gbnVsbFxuXG4gICAgICAgIGlmIChpbXBvcnRzLmVycm9ycy5sZW5ndGgpIHtcbiAgICAgICAgICBpbXBvcnRzLnJlcG9ydEVycm9ycyhjb250ZXh0LCBkZWNsYXJhdGlvbilcbiAgICAgICAgICByZXR1cm5cbiAgICAgICAgfVxuXG4gICAgICAgIGlmICghaW1wb3J0cy5zaXplKSB7XG4gICAgICAgICAgY29udGV4dC5yZXBvcnQoXG4gICAgICAgICAgICBuYW1lc3BhY2UsXG4gICAgICAgICAgICBgTm8gZXhwb3J0ZWQgbmFtZXMgZm91bmQgaW4gbW9kdWxlICcke2RlY2xhcmF0aW9uLnNvdXJjZS52YWx1ZX0nLmBcbiAgICAgICAgICApXG4gICAgICAgIH1cbiAgICAgIH0sXG5cbiAgICAgIC8vIHRvZG86IGNoZWNrIGZvciBwb3NzaWJsZSByZWRlZmluaXRpb25cblxuICAgICAgTWVtYmVyRXhwcmVzc2lvbihkZXJlZmVyZW5jZSkge1xuICAgICAgICBpZiAoZGVyZWZlcmVuY2Uub2JqZWN0LnR5cGUgIT09ICdJZGVudGlmaWVyJykgcmV0dXJuXG4gICAgICAgIGlmICghbmFtZXNwYWNlcy5oYXMoZGVyZWZlcmVuY2Uub2JqZWN0Lm5hbWUpKSByZXR1cm5cbiAgICAgICAgaWYgKGRlY2xhcmVkU2NvcGUoY29udGV4dCwgZGVyZWZlcmVuY2Uub2JqZWN0Lm5hbWUpICE9PSAnbW9kdWxlJykgcmV0dXJuXG5cbiAgICAgICAgaWYgKGRlcmVmZXJlbmNlLnBhcmVudC50eXBlID09PSAnQXNzaWdubWVudEV4cHJlc3Npb24nICYmIGRlcmVmZXJlbmNlLnBhcmVudC5sZWZ0ID09PSBkZXJlZmVyZW5jZSkge1xuICAgICAgICAgICAgY29udGV4dC5yZXBvcnQoXG4gICAgICAgICAgICAgIGRlcmVmZXJlbmNlLnBhcmVudCxcbiAgICAgICAgICAgICAgYEFzc2lnbm1lbnQgdG8gbWVtYmVyIG9mIG5hbWVzcGFjZSAnJHtkZXJlZmVyZW5jZS5vYmplY3QubmFtZX0nLmBcbiAgICAgICAgICAgIClcbiAgICAgICAgfVxuXG4gICAgICAgIC8vIGdvIGRlZXBcbiAgICAgICAgdmFyIG5hbWVzcGFjZSA9IG5hbWVzcGFjZXMuZ2V0KGRlcmVmZXJlbmNlLm9iamVjdC5uYW1lKVxuICAgICAgICB2YXIgbmFtZXBhdGggPSBbZGVyZWZlcmVuY2Uub2JqZWN0Lm5hbWVdXG4gICAgICAgIC8vIHdoaWxlIHByb3BlcnR5IGlzIG5hbWVzcGFjZSBhbmQgcGFyZW50IGlzIG1lbWJlciBleHByZXNzaW9uLCBrZWVwIHZhbGlkYXRpbmdcbiAgICAgICAgd2hpbGUgKG5hbWVzcGFjZSBpbnN0YW5jZW9mIEV4cG9ydHMgJiYgZGVyZWZlcmVuY2UudHlwZSA9PT0gJ01lbWJlckV4cHJlc3Npb24nKSB7XG5cbiAgICAgICAgICBpZiAoZGVyZWZlcmVuY2UuY29tcHV0ZWQpIHtcbiAgICAgICAgICAgIGlmICghYWxsb3dDb21wdXRlZCkge1xuICAgICAgICAgICAgICBjb250ZXh0LnJlcG9ydChcbiAgICAgICAgICAgICAgICBkZXJlZmVyZW5jZS5wcm9wZXJ0eSxcbiAgICAgICAgICAgICAgICBgVW5hYmxlIHRvIHZhbGlkYXRlIGNvbXB1dGVkIHJlZmVyZW5jZSB0byBpbXBvcnRlZCBuYW1lc3BhY2UgJyR7ZGVyZWZlcmVuY2Uub2JqZWN0Lm5hbWV9Jy5gXG4gICAgICAgICAgICAgIClcbiAgICAgICAgICAgIH1cbiAgICAgICAgICAgIHJldHVyblxuICAgICAgICAgIH1cblxuICAgICAgICAgIGlmICghbmFtZXNwYWNlLmhhcyhkZXJlZmVyZW5jZS5wcm9wZXJ0eS5uYW1lKSkge1xuICAgICAgICAgICAgY29udGV4dC5yZXBvcnQoXG4gICAgICAgICAgICAgIGRlcmVmZXJlbmNlLnByb3BlcnR5LFxuICAgICAgICAgICAgICBtYWtlTWVzc2FnZShkZXJlZmVyZW5jZS5wcm9wZXJ0eSwgbmFtZXBhdGgpXG4gICAgICAgICAgICApXG4gICAgICAgICAgICBicmVha1xuICAgICAgICAgIH1cblxuICAgICAgICAgIGNvbnN0IGV4cG9ydGVkID0gbmFtZXNwYWNlLmdldChkZXJlZmVyZW5jZS5wcm9wZXJ0eS5uYW1lKVxuICAgICAgICAgIGlmIChleHBvcnRlZCA9PSBudWxsKSByZXR1cm5cblxuICAgICAgICAgIC8vIHN0YXNoIGFuZCBwb3BcbiAgICAgICAgICBuYW1lcGF0aC5wdXNoKGRlcmVmZXJlbmNlLnByb3BlcnR5Lm5hbWUpXG4gICAgICAgICAgbmFtZXNwYWNlID0gZXhwb3J0ZWQubmFtZXNwYWNlXG4gICAgICAgICAgZGVyZWZlcmVuY2UgPSBkZXJlZmVyZW5jZS5wYXJlbnRcbiAgICAgICAgfVxuXG4gICAgICB9LFxuXG4gICAgICBWYXJpYWJsZURlY2xhcmF0b3IoeyBpZCwgaW5pdCB9KSB7XG4gICAgICAgIGlmIChpbml0ID09IG51bGwpIHJldHVyblxuICAgICAgICBpZiAoaW5pdC50eXBlICE9PSAnSWRlbnRpZmllcicpIHJldHVyblxuICAgICAgICBpZiAoIW5hbWVzcGFjZXMuaGFzKGluaXQubmFtZSkpIHJldHVyblxuXG4gICAgICAgIC8vIGNoZWNrIGZvciByZWRlZmluaXRpb24gaW4gaW50ZXJtZWRpYXRlIHNjb3Blc1xuICAgICAgICBpZiAoZGVjbGFyZWRTY29wZShjb250ZXh0LCBpbml0Lm5hbWUpICE9PSAnbW9kdWxlJykgcmV0dXJuXG5cbiAgICAgICAgLy8gREZTIHRyYXZlcnNlIGNoaWxkIG5hbWVzcGFjZXNcbiAgICAgICAgZnVuY3Rpb24gdGVzdEtleShwYXR0ZXJuLCBuYW1lc3BhY2UsIHBhdGggPSBbaW5pdC5uYW1lXSkge1xuICAgICAgICAgIGlmICghKG5hbWVzcGFjZSBpbnN0YW5jZW9mIEV4cG9ydHMpKSByZXR1cm5cblxuICAgICAgICAgIGlmIChwYXR0ZXJuLnR5cGUgIT09ICdPYmplY3RQYXR0ZXJuJykgcmV0dXJuXG5cbiAgICAgICAgICBmb3IgKGNvbnN0IHByb3BlcnR5IG9mIHBhdHRlcm4ucHJvcGVydGllcykge1xuICAgICAgICAgICAgaWYgKFxuICAgICAgICAgICAgICBwcm9wZXJ0eS50eXBlID09PSAnRXhwZXJpbWVudGFsUmVzdFByb3BlcnR5J1xuICAgICAgICAgICAgICB8fCBwcm9wZXJ0eS50eXBlID09PSAnUmVzdEVsZW1lbnQnXG4gICAgICAgICAgICAgIHx8ICFwcm9wZXJ0eS5rZXlcbiAgICAgICAgICAgICkge1xuICAgICAgICAgICAgICBjb250aW51ZVxuICAgICAgICAgICAgfVxuXG4gICAgICAgICAgICBpZiAocHJvcGVydHkua2V5LnR5cGUgIT09ICdJZGVudGlmaWVyJykge1xuICAgICAgICAgICAgICBjb250ZXh0LnJlcG9ydCh7XG4gICAgICAgICAgICAgICAgbm9kZTogcHJvcGVydHksXG4gICAgICAgICAgICAgICAgbWVzc2FnZTogJ09ubHkgZGVzdHJ1Y3R1cmUgdG9wLWxldmVsIG5hbWVzLicsXG4gICAgICAgICAgICAgIH0pXG4gICAgICAgICAgICAgIGNvbnRpbnVlXG4gICAgICAgICAgICB9XG5cbiAgICAgICAgICAgIGlmICghbmFtZXNwYWNlLmhhcyhwcm9wZXJ0eS5rZXkubmFtZSkpIHtcbiAgICAgICAgICAgICAgY29udGV4dC5yZXBvcnQoe1xuICAgICAgICAgICAgICAgIG5vZGU6IHByb3BlcnR5LFxuICAgICAgICAgICAgICAgIG1lc3NhZ2U6IG1ha2VNZXNzYWdlKHByb3BlcnR5LmtleSwgcGF0aCksXG4gICAgICAgICAgICAgIH0pXG4gICAgICAgICAgICAgIGNvbnRpbnVlXG4gICAgICAgICAgICB9XG5cbiAgICAgICAgICAgIHBhdGgucHVzaChwcm9wZXJ0eS5rZXkubmFtZSlcbiAgICAgICAgICAgIGNvbnN0IGRlcGVuZGVuY3lFeHBvcnRNYXAgPSBuYW1lc3BhY2UuZ2V0KHByb3BlcnR5LmtleS5uYW1lKVxuICAgICAgICAgICAgLy8gY291bGQgYmUgbnVsbCB3aGVuIGlnbm9yZWQgb3IgYW1iaWd1b3VzXG4gICAgICAgICAgICBpZiAoZGVwZW5kZW5jeUV4cG9ydE1hcCAhPT0gbnVsbCkge1xuICAgICAgICAgICAgICB0ZXN0S2V5KHByb3BlcnR5LnZhbHVlLCBkZXBlbmRlbmN5RXhwb3J0TWFwLm5hbWVzcGFjZSwgcGF0aClcbiAgICAgICAgICAgIH1cbiAgICAgICAgICAgIHBhdGgucG9wKClcbiAgICAgICAgICB9XG4gICAgICAgIH1cblxuICAgICAgICB0ZXN0S2V5KGlkLCBuYW1lc3BhY2VzLmdldChpbml0Lm5hbWUpKVxuICAgICAgfSxcblxuICAgICAgSlNYTWVtYmVyRXhwcmVzc2lvbih7b2JqZWN0LCBwcm9wZXJ0eX0pIHtcbiAgICAgICAgIGlmICghbmFtZXNwYWNlcy5oYXMob2JqZWN0Lm5hbWUpKSByZXR1cm5cbiAgICAgICAgIHZhciBuYW1lc3BhY2UgPSBuYW1lc3BhY2VzLmdldChvYmplY3QubmFtZSlcbiAgICAgICAgIGlmICghbmFtZXNwYWNlLmhhcyhwcm9wZXJ0eS5uYW1lKSkge1xuICAgICAgICAgICBjb250ZXh0LnJlcG9ydCh7XG4gICAgICAgICAgICAgbm9kZTogcHJvcGVydHksXG4gICAgICAgICAgICAgbWVzc2FnZTogbWFrZU1lc3NhZ2UocHJvcGVydHksIFtvYmplY3QubmFtZV0pLFxuICAgICAgICAgICB9KVxuICAgICAgICAgfVxuICAgICAgfSxcbiAgICB9XG4gIH0sXG59XG4iXX0=