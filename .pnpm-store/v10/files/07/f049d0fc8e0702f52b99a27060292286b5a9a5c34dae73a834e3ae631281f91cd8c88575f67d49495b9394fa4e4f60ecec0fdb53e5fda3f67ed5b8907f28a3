'use strict';var _declaredScope = require('eslint-module-utils/declaredScope');var _declaredScope2 = _interopRequireDefault(_declaredScope);
var _builder = require('../exportMap/builder');var _builder2 = _interopRequireDefault(_builder);
var _exportMap = require('../exportMap');var _exportMap2 = _interopRequireDefault(_exportMap);
var _importDeclaration = require('../importDeclaration');var _importDeclaration2 = _interopRequireDefault(_importDeclaration);
var _docsUrl = require('../docsUrl');var _docsUrl2 = _interopRequireDefault(_docsUrl);function _interopRequireDefault(obj) {return obj && obj.__esModule ? obj : { 'default': obj };}

function processBodyStatement(context, namespaces, declaration) {
  if (declaration.type !== 'ImportDeclaration') {return;}

  if (declaration.specifiers.length === 0) {return;}

  var imports = _builder2['default'].get(declaration.source.value, context);
  if (imports == null) {return null;}

  if (imports.errors.length > 0) {
    imports.reportErrors(context, declaration);
    return;
  }

  declaration.specifiers.forEach(function (specifier) {
    switch (specifier.type) {
      case 'ImportNamespaceSpecifier':
        if (!imports.size) {
          context.report(
          specifier, 'No exported names found in module \'' + String(
          declaration.source.value) + '\'.');

        }
        namespaces.set(specifier.local.name, imports);
        break;
      case 'ImportDefaultSpecifier':
      case 'ImportSpecifier':{
          var meta = imports.get(
          // default to 'default' for default https://i.imgur.com/nj6qAWy.jpg
          specifier.imported ? specifier.imported.name || specifier.imported.value : 'default');

          if (!meta || !meta.namespace) {break;}
          namespaces.set(specifier.local.name, meta.namespace);
          break;
        }
      default:}

  });
}

module.exports = {
  meta: {
    type: 'problem',
    docs: {
      category: 'Static analysis',
      description: 'Ensure imported namespaces contain dereferenced properties as they are dereferenced.',
      url: (0, _docsUrl2['default'])('namespace') },


    schema: [
    {
      type: 'object',
      properties: {
        allowComputed: {
          description: 'If `false`, will report computed (and thus, un-lintable) references to namespace members.',
          type: 'boolean',
          'default': false } },


      additionalProperties: false }] },




  create: function () {function namespaceRule(context) {
      // read options
      var _ref =

      context.options[0] || {},_ref$allowComputed = _ref.allowComputed,allowComputed = _ref$allowComputed === undefined ? false : _ref$allowComputed;

      var namespaces = new Map();

      function makeMessage(last, namepath) {
        return '\'' + String(last.name) + '\' not found in ' + (namepath.length > 1 ? 'deeply ' : '') + 'imported namespace \'' + String(namepath.join('.')) + '\'.';
      }

      return {
        // pick up all imports at body entry time, to properly respect hoisting
        Program: function () {function Program(_ref2) {var body = _ref2.body;
            body.forEach(function (x) {processBodyStatement(context, namespaces, x);});
          }return Program;}(),

        // same as above, but does not add names to local map
        ExportNamespaceSpecifier: function () {function ExportNamespaceSpecifier(namespace) {
            var declaration = (0, _importDeclaration2['default'])(context);

            var imports = _builder2['default'].get(declaration.source.value, context);
            if (imports == null) {return null;}

            if (imports.errors.length) {
              imports.reportErrors(context, declaration);
              return;
            }

            if (!imports.size) {
              context.report(
              namespace, 'No exported names found in module \'' + String(
              declaration.source.value) + '\'.');

            }
          }return ExportNamespaceSpecifier;}(),

        // todo: check for possible redefinition

        MemberExpression: function () {function MemberExpression(dereference) {
            if (dereference.object.type !== 'Identifier') {return;}
            if (!namespaces.has(dereference.object.name)) {return;}
            if ((0, _declaredScope2['default'])(context, dereference.object.name) !== 'module') {return;}

            if (dereference.parent.type === 'AssignmentExpression' && dereference.parent.left === dereference) {
              context.report(
              dereference.parent, 'Assignment to member of namespace \'' + String(
              dereference.object.name) + '\'.');

            }

            // go deep
            var namespace = namespaces.get(dereference.object.name);
            var namepath = [dereference.object.name];
            // while property is namespace and parent is member expression, keep validating
            while (namespace instanceof _exportMap2['default'] && dereference.type === 'MemberExpression') {
              if (dereference.computed) {
                if (!allowComputed) {
                  context.report(
                  dereference.property, 'Unable to validate computed reference to imported namespace \'' + String(
                  dereference.object.name) + '\'.');

                }
                return;
              }

              if (!namespace.has(dereference.property.name)) {
                context.report(
                dereference.property,
                makeMessage(dereference.property, namepath));

                break;
              }

              var exported = namespace.get(dereference.property.name);
              if (exported == null) {return;}

              // stash and pop
              namepath.push(dereference.property.name);
              namespace = exported.namespace;
              dereference = dereference.parent;
            }
          }return MemberExpression;}(),

        VariableDeclarator: function () {function VariableDeclarator(_ref3) {var id = _ref3.id,init = _ref3.init;
            if (init == null) {return;}
            if (init.type !== 'Identifier') {return;}
            if (!namespaces.has(init.name)) {return;}

            // check for redefinition in intermediate scopes
            if ((0, _declaredScope2['default'])(context, init.name) !== 'module') {return;}

            // DFS traverse child namespaces
            function testKey(pattern, namespace) {var path = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : [init.name];
              if (!(namespace instanceof _exportMap2['default'])) {return;}

              if (pattern.type !== 'ObjectPattern') {return;}var _iteratorNormalCompletion = true;var _didIteratorError = false;var _iteratorError = undefined;try {

                for (var _iterator = pattern.properties[Symbol.iterator](), _step; !(_iteratorNormalCompletion = (_step = _iterator.next()).done); _iteratorNormalCompletion = true) {var property = _step.value;
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
                  var dependencyExportMap = namespace.get(property.key.name);
                  // could be null when ignored or ambiguous
                  if (dependencyExportMap !== null) {
                    testKey(property.value, dependencyExportMap.namespace, path);
                  }
                  path.pop();
                }} catch (err) {_didIteratorError = true;_iteratorError = err;} finally {try {if (!_iteratorNormalCompletion && _iterator['return']) {_iterator['return']();}} finally {if (_didIteratorError) {throw _iteratorError;}}}
            }

            testKey(id, namespaces.get(init.name));
          }return VariableDeclarator;}(),

        JSXMemberExpression: function () {function JSXMemberExpression(_ref4) {var object = _ref4.object,property = _ref4.property;
            if (!namespaces.has(object.name)) {return;}
            var namespace = namespaces.get(object.name);
            if (!namespace.has(property.name)) {
              context.report({
                node: property,
                message: makeMessage(property, [object.name]) });

            }
          }return JSXMemberExpression;}() };

    }return namespaceRule;}() };
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIi4uLy4uL3NyYy9ydWxlcy9uYW1lc3BhY2UuanMiXSwibmFtZXMiOlsicHJvY2Vzc0JvZHlTdGF0ZW1lbnQiLCJjb250ZXh0IiwibmFtZXNwYWNlcyIsImRlY2xhcmF0aW9uIiwidHlwZSIsInNwZWNpZmllcnMiLCJsZW5ndGgiLCJpbXBvcnRzIiwiRXhwb3J0TWFwQnVpbGRlciIsImdldCIsInNvdXJjZSIsInZhbHVlIiwiZXJyb3JzIiwicmVwb3J0RXJyb3JzIiwiZm9yRWFjaCIsInNwZWNpZmllciIsInNpemUiLCJyZXBvcnQiLCJzZXQiLCJsb2NhbCIsIm5hbWUiLCJtZXRhIiwiaW1wb3J0ZWQiLCJuYW1lc3BhY2UiLCJtb2R1bGUiLCJleHBvcnRzIiwiZG9jcyIsImNhdGVnb3J5IiwiZGVzY3JpcHRpb24iLCJ1cmwiLCJzY2hlbWEiLCJwcm9wZXJ0aWVzIiwiYWxsb3dDb21wdXRlZCIsImFkZGl0aW9uYWxQcm9wZXJ0aWVzIiwiY3JlYXRlIiwibmFtZXNwYWNlUnVsZSIsIm9wdGlvbnMiLCJNYXAiLCJtYWtlTWVzc2FnZSIsImxhc3QiLCJuYW1lcGF0aCIsImpvaW4iLCJQcm9ncmFtIiwiYm9keSIsIngiLCJFeHBvcnROYW1lc3BhY2VTcGVjaWZpZXIiLCJNZW1iZXJFeHByZXNzaW9uIiwiZGVyZWZlcmVuY2UiLCJvYmplY3QiLCJoYXMiLCJwYXJlbnQiLCJsZWZ0IiwiRXhwb3J0TWFwIiwiY29tcHV0ZWQiLCJwcm9wZXJ0eSIsImV4cG9ydGVkIiwicHVzaCIsIlZhcmlhYmxlRGVjbGFyYXRvciIsImlkIiwiaW5pdCIsInRlc3RLZXkiLCJwYXR0ZXJuIiwicGF0aCIsImtleSIsIm5vZGUiLCJtZXNzYWdlIiwiZGVwZW5kZW5jeUV4cG9ydE1hcCIsInBvcCIsIkpTWE1lbWJlckV4cHJlc3Npb24iXSwibWFwcGluZ3MiOiJhQUFBLGtFO0FBQ0EsK0M7QUFDQSx5QztBQUNBLHlEO0FBQ0EscUM7O0FBRUEsU0FBU0Esb0JBQVQsQ0FBOEJDLE9BQTlCLEVB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QjNDLFVBQVVkLEdBQVYsQ0FBYzZDLFNBQVNTLEdBQVQsQ0FBYTNDLElBQTNCLENBQTVCO0FBQ0E7QUFDQSxzQkFBSThDLHdCQUF3QixJQUE1QixFQUFrQztBQUNoQ04sNEJBQVFOLFNBQVMzQyxLQUFqQixFQUF3QnVELG9CQUFvQjNDLFNBQTVDLEVBQXVEdUMsSUFBdkQ7QUFDRDtBQUNEQSx1QkFBS0ssR0FBTDtBQUNELGlCQXJDc0Q7QUFzQ3hEOztBQUVEUCxvQkFBUUYsRUFBUixFQUFZeEQsV0FBV08sR0FBWCxDQUFla0QsS0FBS3ZDLElBQXBCLENBQVo7QUFDRCxXQTNISTs7QUE2SExnRCwyQkE3SEssbURBNkhxQyxLQUFwQnBCLE1BQW9CLFNBQXBCQSxNQUFvQixDQUFaTSxRQUFZLFNBQVpBLFFBQVk7QUFDeEMsZ0JBQUksQ0FBQ3BELFdBQVcrQyxHQUFYLENBQWVELE9BQU81QixJQUF0QixDQUFMLEVBQWtDLENBQUUsT0FBUztBQUM3QyxnQkFBTUcsWUFBWXJCLFdBQVdPLEdBQVgsQ0FBZXVDLE9BQU81QixJQUF0QixDQUFsQjtBQUNBLGdCQUFJLENBQUNHLFVBQVUwQixHQUFWLENBQWNLLFNBQVNsQyxJQUF2QixDQUFMLEVBQW1DO0FBQ2pDbkIsc0JBQVFnQixNQUFSLENBQWU7QUFDYitDLHNCQUFNVixRQURPO0FBRWJXLHlCQUFTM0IsWUFBWWdCLFFBQVosRUFBc0IsQ0FBQ04sT0FBTzVCLElBQVIsQ0FBdEIsQ0FGSSxFQUFmOztBQUlEO0FBQ0YsV0F0SUksZ0NBQVA7O0FBd0lELEtBcEpELE9BQWlCZSxhQUFqQixJQXhCZSxFQUFqQiIsImZpbGUiOiJuYW1lc3BhY2UuanMiLCJzb3VyY2VzQ29udGVudCI6WyJpbXBvcnQgZGVjbGFyZWRTY29wZSBmcm9tICdlc2xpbnQtbW9kdWxlLXV0aWxzL2RlY2xhcmVkU2NvcGUnO1xuaW1wb3J0IEV4cG9ydE1hcEJ1aWxkZXIgZnJvbSAnLi4vZXhwb3J0TWFwL2J1aWxkZXInO1xuaW1wb3J0IEV4cG9ydE1hcCBmcm9tICcuLi9leHBvcnRNYXAnO1xuaW1wb3J0IGltcG9ydERlY2xhcmF0aW9uIGZyb20gJy4uL2ltcG9ydERlY2xhcmF0aW9uJztcbmltcG9ydCBkb2NzVXJsIGZyb20gJy4uL2RvY3NVcmwnO1xuXG5mdW5jdGlvbiBwcm9jZXNzQm9keVN0YXRlbWVudChjb250ZXh0LCBuYW1lc3BhY2VzLCBkZWNsYXJhdGlvbikge1xuICBpZiAoZGVjbGFyYXRpb24udHlwZSAhPT0gJ0ltcG9ydERlY2xhcmF0aW9uJykgeyByZXR1cm47IH1cblxuICBpZiAoZGVjbGFyYXRpb24uc3BlY2lmaWVycy5sZW5ndGggPT09IDApIHsgcmV0dXJuOyB9XG5cbiAgY29uc3QgaW1wb3J0cyA9IEV4cG9ydE1hcEJ1aWxkZXIuZ2V0KGRlY2xhcmF0aW9uLnNvdXJjZS52YWx1ZSwgY29udGV4dCk7XG4gIGlmIChpbXBvcnRzID09IG51bGwpIHsgcmV0dXJuIG51bGw7IH1cblxuICBpZiAoaW1wb3J0cy5lcnJvcnMubGVuZ3RoID4gMCkge1xuICAgIGltcG9ydHMucmVwb3J0RXJyb3JzKGNvbnRleHQsIGRlY2xhcmF0aW9uKTtcbiAgICByZXR1cm47XG4gIH1cblxuICBkZWNsYXJhdGlvbi5zcGVjaWZpZXJzLmZvckVhY2goKHNwZWNpZmllcikgPT4ge1xuICAgIHN3aXRjaCAoc3BlY2lmaWVyLnR5cGUpIHtcbiAgICAgIGNhc2UgJ0ltcG9ydE5hbWVzcGFjZVNwZWNpZmllcic6XG4gICAgICAgIGlmICghaW1wb3J0cy5zaXplKSB7XG4gICAgICAgICAgY29udGV4dC5yZXBvcnQoXG4gICAgICAgICAgICBzcGVjaWZpZXIsXG4gICAgICAgICAgICBgTm8gZXhwb3J0ZWQgbmFtZXMgZm91bmQgaW4gbW9kdWxlICcke2RlY2xhcmF0aW9uLnNvdXJjZS52YWx1ZX0nLmAsXG4gICAgICAgICAgKTtcbiAgICAgICAgfVxuICAgICAgICBuYW1lc3BhY2VzLnNldChzcGVjaWZpZXIubG9jYWwubmFtZSwgaW1wb3J0cyk7XG4gICAgICAgIGJyZWFrO1xuICAgICAgY2FzZSAnSW1wb3J0RGVmYXVsdFNwZWNpZmllcic6XG4gICAgICBjYXNlICdJbXBvcnRTcGVjaWZpZXInOiB7XG4gICAgICAgIGNvbnN0IG1ldGEgPSBpbXBvcnRzLmdldChcbiAgICAgICAgLy8gZGVmYXVsdCB0byAnZGVmYXVsdCcgZm9yIGRlZmF1bHQgaHR0cHM6Ly9pLmltZ3VyLmNvbS9uajZxQVd5LmpwZ1xuICAgICAgICAgIHNwZWNpZmllci5pbXBvcnRlZCA/IHNwZWNpZmllci5pbXBvcnRlZC5uYW1lIHx8IHNwZWNpZmllci5pbXBvcnRlZC52YWx1ZSA6ICdkZWZhdWx0JyxcbiAgICAgICAgKTtcbiAgICAgICAgaWYgKCFtZXRhIHx8ICFtZXRhLm5hbWVzcGFjZSkgeyBicmVhazsgfVxuICAgICAgICBuYW1lc3BhY2VzLnNldChzcGVjaWZpZXIubG9jYWwubmFtZSwgbWV0YS5uYW1lc3BhY2UpO1xuICAgICAgICBicmVhaztcbiAgICAgIH1cbiAgICAgIGRlZmF1bHQ6XG4gICAgfVxuICB9KTtcbn1cblxubW9kdWxlLmV4cG9ydHMgPSB7XG4gIG1ldGE6IHtcbiAgICB0eXBlOiAncHJvYmxlbScsXG4gICAgZG9jczoge1xuICAgICAgY2F0ZWdvcnk6ICdTdGF0aWMgYW5hbHlzaXMnLFxuICAgICAgZGVzY3JpcHRpb246ICdFbnN1cmUgaW1wb3J0ZWQgbmFtZXNwYWNlcyBjb250YWluIGRlcmVmZXJlbmNlZCBwcm9wZXJ0aWVzIGFzIHRoZXkgYXJlIGRlcmVmZXJlbmNlZC4nLFxuICAgICAgdXJsOiBkb2NzVXJsKCduYW1lc3BhY2UnKSxcbiAgICB9LFxuXG4gICAgc2NoZW1hOiBbXG4gICAgICB7XG4gICAgICAgIHR5cGU6ICdvYmplY3QnLFxuICAgICAgICBwcm9wZXJ0aWVzOiB7XG4gICAgICAgICAgYWxsb3dDb21wdXRlZDoge1xuICAgICAgICAgICAgZGVzY3JpcHRpb246ICdJZiBgZmFsc2VgLCB3aWxsIHJlcG9ydCBjb21wdXRlZCAoYW5kIHRodXMsIHVuLWxpbnRhYmxlKSByZWZlcmVuY2VzIHRvIG5hbWVzcGFjZSBtZW1iZXJzLicsXG4gICAgICAgICAgICB0eXBlOiAnYm9vbGVhbicsXG4gICAgICAgICAgICBkZWZhdWx0OiBmYWxzZSxcbiAgICAgICAgICB9LFxuICAgICAgICB9LFxuICAgICAgICBhZGRpdGlvbmFsUHJvcGVydGllczogZmFsc2UsXG4gICAgICB9LFxuICAgIF0sXG4gIH0sXG5cbiAgY3JlYXRlOiBmdW5jdGlvbiBuYW1lc3BhY2VSdWxlKGNvbnRleHQpIHtcbiAgICAvLyByZWFkIG9wdGlvbnNcbiAgICBjb25zdCB7XG4gICAgICBhbGxvd0NvbXB1dGVkID0gZmFsc2UsXG4gICAgfSA9IGNvbnRleHQub3B0aW9uc1swXSB8fCB7fTtcblxuICAgIGNvbnN0IG5hbWVzcGFjZXMgPSBuZXcgTWFwKCk7XG5cbiAgICBmdW5jdGlvbiBtYWtlTWVzc2FnZShsYXN0LCBuYW1lcGF0aCkge1xuICAgICAgcmV0dXJuIGAnJHtsYXN0Lm5hbWV9JyBub3QgZm91bmQgaW4gJHtuYW1lcGF0aC5sZW5ndGggPiAxID8gJ2RlZXBseSAnIDogJyd9aW1wb3J0ZWQgbmFtZXNwYWNlICcke25hbWVwYXRoLmpvaW4oJy4nKX0nLmA7XG4gICAgfVxuXG4gICAgcmV0dXJuIHtcbiAgICAgIC8vIHBpY2sgdXAgYWxsIGltcG9ydHMgYXQgYm9keSBlbnRyeSB0aW1lLCB0byBwcm9wZXJseSByZXNwZWN0IGhvaXN0aW5nXG4gICAgICBQcm9ncmFtKHsgYm9keSB9KSB7XG4gICAgICAgIGJvZHkuZm9yRWFjaCgoeCkgPT4geyBwcm9jZXNzQm9keVN0YXRlbWVudChjb250ZXh0LCBuYW1lc3BhY2VzLCB4KTsgfSk7XG4gICAgICB9LFxuXG4gICAgICAvLyBzYW1lIGFzIGFib3ZlLCBidXQgZG9lcyBub3QgYWRkIG5hbWVzIHRvIGxvY2FsIG1hcFxuICAgICAgRXhwb3J0TmFtZXNwYWNlU3BlY2lmaWVyKG5hbWVzcGFjZSkge1xuICAgICAgICBjb25zdCBkZWNsYXJhdGlvbiA9IGltcG9ydERlY2xhcmF0aW9uKGNvbnRleHQpO1xuXG4gICAgICAgIGNvbnN0IGltcG9ydHMgPSBFeHBvcnRNYXBCdWlsZGVyLmdldChkZWNsYXJhdGlvbi5zb3VyY2UudmFsdWUsIGNvbnRleHQpO1xuICAgICAgICBpZiAoaW1wb3J0cyA9PSBudWxsKSB7IHJldHVybiBudWxsOyB9XG5cbiAgICAgICAgaWYgKGltcG9ydHMuZXJyb3JzLmxlbmd0aCkge1xuICAgICAgICAgIGltcG9ydHMucmVwb3J0RXJyb3JzKGNvbnRleHQsIGRlY2xhcmF0aW9uKTtcbiAgICAgICAgICByZXR1cm47XG4gICAgICAgIH1cblxuICAgICAgICBpZiAoIWltcG9ydHMuc2l6ZSkge1xuICAgICAgICAgIGNvbnRleHQucmVwb3J0KFxuICAgICAgICAgICAgbmFtZXNwYWNlLFxuICAgICAgICAgICAgYE5vIGV4cG9ydGVkIG5hbWVzIGZvdW5kIGluIG1vZHVsZSAnJHtkZWNsYXJhdGlvbi5zb3VyY2UudmFsdWV9Jy5gLFxuICAgICAgICAgICk7XG4gICAgICAgIH1cbiAgICAgIH0sXG5cbiAgICAgIC8vIHRvZG86IGNoZWNrIGZvciBwb3NzaWJsZSByZWRlZmluaXRpb25cblxuICAgICAgTWVtYmVyRXhwcmVzc2lvbihkZXJlZmVyZW5jZSkge1xuICAgICAgICBpZiAoZGVyZWZlcmVuY2Uub2JqZWN0LnR5cGUgIT09ICdJZGVudGlmaWVyJykgeyByZXR1cm47IH1cbiAgICAgICAgaWYgKCFuYW1lc3BhY2VzLmhhcyhkZXJlZmVyZW5jZS5vYmplY3QubmFtZSkpIHsgcmV0dXJuOyB9XG4gICAgICAgIGlmIChkZWNsYXJlZFNjb3BlKGNvbnRleHQsIGRlcmVmZXJlbmNlLm9iamVjdC5uYW1lKSAhPT0gJ21vZHVsZScpIHsgcmV0dXJuOyB9XG5cbiAgICAgICAgaWYgKGRlcmVmZXJlbmNlLnBhcmVudC50eXBlID09PSAnQXNzaWdubWVudEV4cHJlc3Npb24nICYmIGRlcmVmZXJlbmNlLnBhcmVudC5sZWZ0ID09PSBkZXJlZmVyZW5jZSkge1xuICAgICAgICAgIGNvbnRleHQucmVwb3J0KFxuICAgICAgICAgICAgZGVyZWZlcmVuY2UucGFyZW50LFxuICAgICAgICAgICAgYEFzc2lnbm1lbnQgdG8gbWVtYmVyIG9mIG5hbWVzcGFjZSAnJHtkZXJlZmVyZW5jZS5vYmplY3QubmFtZX0nLmAsXG4gICAgICAgICAgKTtcbiAgICAgICAgfVxuXG4gICAgICAgIC8vIGdvIGRlZXBcbiAgICAgICAgbGV0IG5hbWVzcGFjZSA9IG5hbWVzcGFjZXMuZ2V0KGRlcmVmZXJlbmNlLm9iamVjdC5uYW1lKTtcbiAgICAgICAgY29uc3QgbmFtZXBhdGggPSBbZGVyZWZlcmVuY2Uub2JqZWN0Lm5hbWVdO1xuICAgICAgICAvLyB3aGlsZSBwcm9wZXJ0eSBpcyBuYW1lc3BhY2UgYW5kIHBhcmVudCBpcyBtZW1iZXIgZXhwcmVzc2lvbiwga2VlcCB2YWxpZGF0aW5nXG4gICAgICAgIHdoaWxlIChuYW1lc3BhY2UgaW5zdGFuY2VvZiBFeHBvcnRNYXAgJiYgZGVyZWZlcmVuY2UudHlwZSA9PT0gJ01lbWJlckV4cHJlc3Npb24nKSB7XG4gICAgICAgICAgaWYgKGRlcmVmZXJlbmNlLmNvbXB1dGVkKSB7XG4gICAgICAgICAgICBpZiAoIWFsbG93Q29tcHV0ZWQpIHtcbiAgICAgICAgICAgICAgY29udGV4dC5yZXBvcnQoXG4gICAgICAgICAgICAgICAgZGVyZWZlcmVuY2UucHJvcGVydHksXG4gICAgICAgICAgICAgICAgYFVuYWJsZSB0byB2YWxpZGF0ZSBjb21wdXRlZCByZWZlcmVuY2UgdG8gaW1wb3J0ZWQgbmFtZXNwYWNlICcke2RlcmVmZXJlbmNlLm9iamVjdC5uYW1lfScuYCxcbiAgICAgICAgICAgICAgKTtcbiAgICAgICAgICAgIH1cbiAgICAgICAgICAgIHJldHVybjtcbiAgICAgICAgICB9XG5cbiAgICAgICAgICBpZiAoIW5hbWVzcGFjZS5oYXMoZGVyZWZlcmVuY2UucHJvcGVydHkubmFtZSkpIHtcbiAgICAgICAgICAgIGNvbnRleHQucmVwb3J0KFxuICAgICAgICAgICAgICBkZXJlZmVyZW5jZS5wcm9wZXJ0eSxcbiAgICAgICAgICAgICAgbWFrZU1lc3NhZ2UoZGVyZWZlcmVuY2UucHJvcGVydHksIG5hbWVwYXRoKSxcbiAgICAgICAgICAgICk7XG4gICAgICAgICAgICBicmVhaztcbiAgICAgICAgICB9XG5cbiAgICAgICAgICBjb25zdCBleHBvcnRlZCA9IG5hbWVzcGFjZS5nZXQoZGVyZWZlcmVuY2UucHJvcGVydHkubmFtZSk7XG4gICAgICAgICAgaWYgKGV4cG9ydGVkID09IG51bGwpIHsgcmV0dXJuOyB9XG5cbiAgICAgICAgICAvLyBzdGFzaCBhbmQgcG9wXG4gICAgICAgICAgbmFtZXBhdGgucHVzaChkZXJlZmVyZW5jZS5wcm9wZXJ0eS5uYW1lKTtcbiAgICAgICAgICBuYW1lc3BhY2UgPSBleHBvcnRlZC5uYW1lc3BhY2U7XG4gICAgICAgICAgZGVyZWZlcmVuY2UgPSBkZXJlZmVyZW5jZS5wYXJlbnQ7XG4gICAgICAgIH1cbiAgICAgIH0sXG5cbiAgICAgIFZhcmlhYmxlRGVjbGFyYXRvcih7IGlkLCBpbml0IH0pIHtcbiAgICAgICAgaWYgKGluaXQgPT0gbnVsbCkgeyByZXR1cm47IH1cbiAgICAgICAgaWYgKGluaXQudHlwZSAhPT0gJ0lkZW50aWZpZXInKSB7IHJldHVybjsgfVxuICAgICAgICBpZiAoIW5hbWVzcGFjZXMuaGFzKGluaXQubmFtZSkpIHsgcmV0dXJuOyB9XG5cbiAgICAgICAgLy8gY2hlY2sgZm9yIHJlZGVmaW5pdGlvbiBpbiBpbnRlcm1lZGlhdGUgc2NvcGVzXG4gICAgICAgIGlmIChkZWNsYXJlZFNjb3BlKGNvbnRleHQsIGluaXQubmFtZSkgIT09ICdtb2R1bGUnKSB7IHJldHVybjsgfVxuXG4gICAgICAgIC8vIERGUyB0cmF2ZXJzZSBjaGlsZCBuYW1lc3BhY2VzXG4gICAgICAgIGZ1bmN0aW9uIHRlc3RLZXkocGF0dGVybiwgbmFtZXNwYWNlLCBwYXRoID0gW2luaXQubmFtZV0pIHtcbiAgICAgICAgICBpZiAoIShuYW1lc3BhY2UgaW5zdGFuY2VvZiBFeHBvcnRNYXApKSB7IHJldHVybjsgfVxuXG4gICAgICAgICAgaWYgKHBhdHRlcm4udHlwZSAhPT0gJ09iamVjdFBhdHRlcm4nKSB7IHJldHVybjsgfVxuXG4gICAgICAgICAgZm9yIChjb25zdCBwcm9wZXJ0eSBvZiBwYXR0ZXJuLnByb3BlcnRpZXMpIHtcbiAgICAgICAgICAgIGlmIChcbiAgICAgICAgICAgICAgcHJvcGVydHkudHlwZSA9PT0gJ0V4cGVyaW1lbnRhbFJlc3RQcm9wZXJ0eSdcbiAgICAgICAgICAgICAgfHwgcHJvcGVydHkudHlwZSA9PT0gJ1Jlc3RFbGVtZW50J1xuICAgICAgICAgICAgICB8fCAhcHJvcGVydHkua2V5XG4gICAgICAgICAgICApIHtcbiAgICAgICAgICAgICAgY29udGludWU7XG4gICAgICAgICAgICB9XG5cbiAgICAgICAgICAgIGlmIChwcm9wZXJ0eS5rZXkudHlwZSAhPT0gJ0lkZW50aWZpZXInKSB7XG4gICAgICAgICAgICAgIGNvbnRleHQucmVwb3J0KHtcbiAgICAgICAgICAgICAgICBub2RlOiBwcm9wZXJ0eSxcbiAgICAgICAgICAgICAgICBtZXNzYWdlOiAnT25seSBkZXN0cnVjdHVyZSB0b3AtbGV2ZWwgbmFtZXMuJyxcbiAgICAgICAgICAgICAgfSk7XG4gICAgICAgICAgICAgIGNvbnRpbnVlO1xuICAgICAgICAgICAgfVxuXG4gICAgICAgICAgICBpZiAoIW5hbWVzcGFjZS5oYXMocHJvcGVydHkua2V5Lm5hbWUpKSB7XG4gICAgICAgICAgICAgIGNvbnRleHQucmVwb3J0KHtcbiAgICAgICAgICAgICAgICBub2RlOiBwcm9wZXJ0eSxcbiAgICAgICAgICAgICAgICBtZXNzYWdlOiBtYWtlTWVzc2FnZShwcm9wZXJ0eS5rZXksIHBhdGgpLFxuICAgICAgICAgICAgICB9KTtcbiAgICAgICAgICAgICAgY29udGludWU7XG4gICAgICAgICAgICB9XG5cbiAgICAgICAgICAgIHBhdGgucHVzaChwcm9wZXJ0eS5rZXkubmFtZSk7XG4gICAgICAgICAgICBjb25zdCBkZXBlbmRlbmN5RXhwb3J0TWFwID0gbmFtZXNwYWNlLmdldChwcm9wZXJ0eS5rZXkubmFtZSk7XG4gICAgICAgICAgICAvLyBjb3VsZCBiZSBudWxsIHdoZW4gaWdub3JlZCBvciBhbWJpZ3VvdXNcbiAgICAgICAgICAgIGlmIChkZXBlbmRlbmN5RXhwb3J0TWFwICE9PSBudWxsKSB7XG4gICAgICAgICAgICAgIHRlc3RLZXkocHJvcGVydHkudmFsdWUsIGRlcGVuZGVuY3lFeHBvcnRNYXAubmFtZXNwYWNlLCBwYXRoKTtcbiAgICAgICAgICAgIH1cbiAgICAgICAgICAgIHBhdGgucG9wKCk7XG4gICAgICAgICAgfVxuICAgICAgICB9XG5cbiAgICAgICAgdGVzdEtleShpZCwgbmFtZXNwYWNlcy5nZXQoaW5pdC5uYW1lKSk7XG4gICAgICB9LFxuXG4gICAgICBKU1hNZW1iZXJFeHByZXNzaW9uKHsgb2JqZWN0LCBwcm9wZXJ0eSB9KSB7XG4gICAgICAgIGlmICghbmFtZXNwYWNlcy5oYXMob2JqZWN0Lm5hbWUpKSB7IHJldHVybjsgfVxuICAgICAgICBjb25zdCBuYW1lc3BhY2UgPSBuYW1lc3BhY2VzLmdldChvYmplY3QubmFtZSk7XG4gICAgICAgIGlmICghbmFtZXNwYWNlLmhhcyhwcm9wZXJ0eS5uYW1lKSkge1xuICAgICAgICAgIGNvbnRleHQucmVwb3J0KHtcbiAgICAgICAgICAgIG5vZGU6IHByb3BlcnR5LFxuICAgICAgICAgICAgbWVzc2FnZTogbWFrZU1lc3NhZ2UocHJvcGVydHksIFtvYmplY3QubmFtZV0pLFxuICAgICAgICAgIH0pO1xuICAgICAgICB9XG4gICAgICB9LFxuICAgIH07XG4gIH0sXG59O1xuIl19