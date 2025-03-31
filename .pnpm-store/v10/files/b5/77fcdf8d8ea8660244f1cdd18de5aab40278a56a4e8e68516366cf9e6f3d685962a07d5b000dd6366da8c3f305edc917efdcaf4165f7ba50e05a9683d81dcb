'use strict';




var _minimatch = require('minimatch');var _minimatch2 = _interopRequireDefault(_minimatch);
var _docsUrl = require('../docsUrl');var _docsUrl2 = _interopRequireDefault(_docsUrl);function _interopRequireDefault(obj) {return obj && obj.__esModule ? obj : { 'default': obj };}

/**
                                                                                                                                                                                       * @param {MemberExpression} memberExpression
                                                                                                                                                                                       * @returns {string} the name of the member in the object expression, e.g. the `x` in `namespace.x`
                                                                                                                                                                                       */ /**
                                                                                                                                                                                           * @fileoverview Rule to disallow namespace import
                                                                                                                                                                                           * @author Radek Benkel
                                                                                                                                                                                           */function getMemberPropertyName(memberExpression) {return memberExpression.property.type === 'Identifier' ? memberExpression.property.name :
  memberExpression.property.value;
}

/**
   * @param {ScopeManager} scopeManager
   * @param {ASTNode} node
   * @return {Set<string>}
   */
function getVariableNamesInScope(scopeManager, node) {
  var currentNode = node;
  var scope = scopeManager.acquire(currentNode);
  while (scope == null) {
    currentNode = currentNode.parent;
    scope = scopeManager.acquire(currentNode, true);
  }
  return new Set(scope.variables.concat(scope.upper.variables).map(function (variable) {return variable.name;}));
}

/**
   *
   * @param {*} names
   * @param {*} nameConflicts
   * @param {*} namespaceName
   */
function generateLocalNames(names, nameConflicts, namespaceName) {
  var localNames = {};
  names.forEach(function (name) {
    var localName = void 0;
    if (!nameConflicts[name].has(name)) {
      localName = name;
    } else if (!nameConflicts[name].has(String(namespaceName) + '_' + String(name))) {
      localName = String(namespaceName) + '_' + String(name);
    } else {
      for (var i = 1; i < Infinity; i++) {
        if (!nameConflicts[name].has(String(namespaceName) + '_' + String(name) + '_' + String(i))) {
          localName = String(namespaceName) + '_' + String(name) + '_' + String(i);
          break;
        }
      }
    }
    localNames[name] = localName;
  });
  return localNames;
}

/**
   * @param {Identifier[]} namespaceIdentifiers
   * @returns {boolean} `true` if the namespace variable is more than just a glorified constant
   */
function usesNamespaceAsObject(namespaceIdentifiers) {
  return !namespaceIdentifiers.every(function (identifier) {
    var parent = identifier.parent;

    // `namespace.x` or `namespace['x']`
    return (
      parent &&
      parent.type === 'MemberExpression' && (
      parent.property.type === 'Identifier' || parent.property.type === 'Literal'));

  });
}

module.exports = {
  meta: {
    type: 'suggestion',
    docs: {
      category: 'Style guide',
      description: 'Forbid namespace (a.k.a. "wildcard" `*`) imports.',
      url: (0, _docsUrl2['default'])('no-namespace') },

    fixable: 'code',
    schema: [{
      type: 'object',
      properties: {
        ignore: {
          type: 'array',
          items: {
            type: 'string' },

          uniqueItems: true } } }] },





  create: function () {function create(context) {
      var firstOption = context.options[0] || {};
      var ignoreGlobs = firstOption.ignore;

      return {
        ImportNamespaceSpecifier: function () {function ImportNamespaceSpecifier(node) {
            if (ignoreGlobs && ignoreGlobs.find(function (glob) {return (0, _minimatch2['default'])(node.parent.source.value, glob, { matchBase: true });})) {
              return;
            }

            var scopeVariables = context.getScope().variables;
            var namespaceVariable = scopeVariables.find(function (variable) {return variable.defs[0].node === node;});
            var namespaceReferences = namespaceVariable.references;
            var namespaceIdentifiers = namespaceReferences.map(function (reference) {return reference.identifier;});
            var canFix = namespaceIdentifiers.length > 0 && !usesNamespaceAsObject(namespaceIdentifiers);

            context.report({
              node: node,
              message: 'Unexpected namespace import.',
              fix: canFix && function (fixer) {
                var scopeManager = context.getSourceCode().scopeManager;
                var fixes = [];

                // Pass 1: Collect variable names that are already in scope for each reference we want
                // to transform, so that we can be sure that we choose non-conflicting import names
                var importNameConflicts = {};
                namespaceIdentifiers.forEach(function (identifier) {
                  var parent = identifier.parent;
                  if (parent && parent.type === 'MemberExpression') {
                    var importName = getMemberPropertyName(parent);
                    var localConflicts = getVariableNamesInScope(scopeManager, parent);
                    if (!importNameConflicts[importName]) {
                      importNameConflicts[importName] = localConflicts;
                    } else {
                      localConflicts.forEach(function (c) {return importNameConflicts[importName].add(c);});
                    }
                  }
                });

                // Choose new names for each import
                var importNames = Object.keys(importNameConflicts);
                var importLocalNames = generateLocalNames(
                importNames,
                importNameConflicts,
                namespaceVariable.name);


                // Replace the ImportNamespaceSpecifier with a list of ImportSpecifiers
                var namedImportSpecifiers = importNames.map(function (importName) {return importName === importLocalNames[importName] ?
                  importName : String(
                  importName) + ' as ' + String(importLocalNames[importName]);});

                fixes.push(fixer.replaceText(node, '{ ' + String(namedImportSpecifiers.join(', ')) + ' }'));

                // Pass 2: Replace references to the namespace with references to the named imports
                namespaceIdentifiers.forEach(function (identifier) {
                  var parent = identifier.parent;
                  if (parent && parent.type === 'MemberExpression') {
                    var importName = getMemberPropertyName(parent);
                    fixes.push(fixer.replaceText(parent, importLocalNames[importName]));
                  }
                });

                return fixes;
              } });

          }return ImportNamespaceSpecifier;}() };

    }return create;}() };
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIi4uLy4uL3NyYy9ydWxlcy9uby1uYW1lc3BhY2UuanMiXSwibmFtZXMiOlsiZ2V0TWVtYmVyUHJvcGVydHlOYW1lIiwibWVtYmVyRXhwcmVzc2lvbiIsInByb3BlcnR5IiwidHlwZSIsIm5hbWUiLCJ2YWx1ZSIsImdldFZhcmlhYmxlTmFtZXNJblNjb3BlIiwic2NvcGVNYW5hZ2VyIiwibm9kZSIsImN1cnJlbnROb2RlIiwic2NvcGUiLCJhY3F1aXJlIiwicGFyZW50IiwiU2V0IiwidmFyaWFibGVzIiwiY29uY2F0IiwidXBwZXIiLCJtYXAiLCJ2YXJpYWJsZSIsImdlbmVyYXRlTG9jYWxOYW1lcyIsIm5hbWVzIiwibmFtZUNvbmZsaWN0cyIsIm5hbWVzcGFjZU5hbWUiLCJsb2NhbE5hbWVzIiwiZm9yRWFjaCIsImxvY2FsTmFtZSIsImhhcyIsImkiLCJJbmZpbml0eSIsInVzZXNOYW1lc3BhY2VBc09iamVjdCIsIm5hbWVzcGFjZUlkZW50aWZpZXJzIiwiZXZlcnkiLCJpZGVudGlmaWVyIiwibW9kdWxlIiwiZXhwb3J0cyIsIm1ldGEiLCJkb2NzIiwiY2F0ZWdvcnkiLCJkZXNjcmlwdGlvbiIsInVybCIsImZpeGFibGUiLCJzY2hlbWEiLCJwcm9wZXJ0aWVzIiwiaWdub3JlIiwiaXRlbXMiLCJ1bmlxdWVJdGVtcyIsImNyZWF0ZSIsImNvbnRleHQiLCJmaXJzdE9wdGlvbiIsIm9wdGlvbnMiLCJpZ25vcmVHbG9icyIsIkltcG9ydE5hbWVzcGFjZVNwZWNpZmllciIsImZpbmQiLCJnbG9iIiwic291cmNlIiwibWF0Y2hCYXNlIiwic2NvcGVWYXJpYWJsZXMiLCJnZXRTY29wZSIsIm5hbWVzcGFjZVZhcmlhYmxlIiwiZGVmcyIsIm5hbWVzcGFjZVJlZmVyZW5jZXMiLCJyZWZlcmVuY2VzIiwicmVmZXJlbmNlIiwiY2FuRml4IiwibGVuZ3RoIiwicmVwb3J0IiwibWVzc2FnZSIsImZpeCIsImZpeGVyIiwiZ2V0U291cmNlQ29kZSIsImZpeGVzIiwiaW1wb3J0TmFtZUNvbmZsaWN0cyIsImltcG9ydE5hbWUiLCJsb2NhbENvbmZsaWN0cyIsImMiLCJhZGQiLCJpbXBvcnROYW1lcyIsIk9iamVjdCIsImtleXMiLCJpbXBvcnRMb2NhbE5hbWVzIiwibmFtZWRJbXBvcnRTcGVjaWZpZXJzIiwicHVzaCIsInJlcGxhY2VUZXh0Iiwiam9pbiJdLCJtYXBwaW5ncyI6Ijs7Ozs7QUFLQSxzQztBQUNBLHFDOztBQUVBOzs7MExBUkE7Ozs2TEFZQSxTQUFTQSxxQkFBVCxDQUErQkMsZ0JBQS9CLEVBQWlELENBQy9DLE9BQU9BLGlCQUFpQkMsUUFBakIsQ0FBMEJDLElBQTFCLEtBQW1DLFlBQW5DLEdBQ0hGLGlCQUFpQkMsUUFBakIsQ0FBMEJFLElBRHZCO0FBRUhILG1CQUFpQkMsUUFBakIsQ0FBMEJHLEtBRjlCO0FBR0Q7O0FBRUQ7Ozs7O0FBS0EsU0FBU0MsdUJBQVQsQ0FBaUNDLFlBQWpDLEVBQStDQyxJQUEvQyxFQUFxRDtBQUNuRCxNQUFJQyxjQUFjRCxJQUFsQjtBQUNBLE1BQUlFLFFBQVFILGFBQWFJLE9BQWIsQ0FBcUJGLFdBQXJCLENBQVo7QUFDQSxTQUFPQyxTQUFTLElBQWhCLEVBQXNCO0FBQ3BCRCxrQkFBY0EsWUFBWUcsTUFBMUI7QUFDQUYsWUFBUUgsYUFBYUksT0FBYixDQUFxQkYsV0FBckIsRUFBa0MsSUFBbEMsQ0FBUjtBQUNEO0FBQ0QsU0FBTyxJQUFJSSxHQUFKLENBQVFILE1BQU1JLFNBQU4sQ0FBZ0JDLE1BQWhCLENBQXVCTCxNQUFNTSxLQUFOLENBQVlGLFNBQW5DLEVBQThDRyxHQUE5QyxDQUFrRCxVQUFDQyxRQUFELFVBQWNBLFNBQVNkLElBQXZCLEVBQWxELENBQVIsQ0FBUDtBQUNEOztBQUVEOzs7Ozs7QUFNQSxTQUFTZSxrQkFBVCxDQUE0QkMsS0FBNUIsRUFBbUNDLGFBQW5DLEVBQWtEQyxhQUFsRCxFQUFpRTtBQUMvRCxNQUFNQyxhQUFhLEVBQW5CO0FBQ0FILFFBQU1JLE9BQU4sQ0FBYyxVQUFDcEIsSUFBRCxFQUFVO0FBQ3RCLFFBQUlxQixrQkFBSjtBQUNBLFFBQUksQ0FBQ0osY0FBY2pCLElBQWQsRUFBb0JzQixHQUFwQixDQUF3QnRCLElBQXhCLENBQUwsRUFBb0M7QUFDbENxQixrQkFBWXJCLElBQVo7QUFDRCxLQUZELE1BRU8sSUFBSSxDQUFDaUIsY0FBY2pCLElBQWQsRUFBb0JzQixHQUFwQixRQUEyQkosYUFBM0IsaUJBQTRDbEIsSUFBNUMsRUFBTCxFQUEwRDtBQUMvRHFCLHlCQUFlSCxhQUFmLGlCQUFnQ2xCLElBQWhDO0FBQ0QsS0FGTSxNQUVBO0FBQ0wsV0FBSyxJQUFJdUIsSUFBSSxDQUFiLEVBQWdCQSxJQUFJQyxRQUFwQixFQUE4QkQsR0FBOUIsRUFBbUM7QUFDakMsWUFBSSxDQUFDTixjQUFjakIsSUFBZCxFQUFvQnNCLEdBQXBCLFFBQTJCSixhQUEzQixpQkFBNENsQixJQUE1QyxpQkFBb0R1QixDQUFwRCxFQUFMLEVBQStEO0FBQzdERiw2QkFBZUgsYUFBZixpQkFBZ0NsQixJQUFoQyxpQkFBd0N1QixDQUF4QztBQUNBO0FBQ0Q7QUFDRjtBQUNGO0FBQ0RKLGVBQVduQixJQUFYLElBQW1CcUIsU0FBbkI7QUFDRCxHQWZEO0FBZ0JBLFNBQU9GLFVBQVA7QUFDRDs7QUFFRDs7OztBQUlBLFNBQVNNLHFCQUFULENBQStCQyxvQkFBL0IsRUFBcUQ7QUFDbkQsU0FBTyxDQUFDQSxxQkFBcUJDLEtBQXJCLENBQTJCLFVBQUNDLFVBQUQsRUFBZ0I7QUFDakQsUUFBTXBCLFNBQVNvQixXQUFXcEIsTUFBMUI7O0FBRUE7QUFDQTtBQUNFQTtBQUNHQSxhQUFPVCxJQUFQLEtBQWdCLGtCQURuQjtBQUVJUyxhQUFPVixRQUFQLENBQWdCQyxJQUFoQixLQUF5QixZQUF6QixJQUF5Q1MsT0FBT1YsUUFBUCxDQUFnQkMsSUFBaEIsS0FBeUIsU0FGdEUsQ0FERjs7QUFLRCxHQVRPLENBQVI7QUFVRDs7QUFFRDhCLE9BQU9DLE9BQVAsR0FBaUI7QUFDZkMsUUFBTTtBQUNKaEMsVUFBTSxZQURGO0FBRUppQyxVQUFNO0FBQ0pDLGdCQUFVLGFBRE47QUFFSkMsbUJBQWEsbURBRlQ7QUFHSkMsV0FBSywwQkFBUSxjQUFSLENBSEQsRUFGRjs7QUFPSkMsYUFBUyxNQVBMO0FBUUpDLFlBQVEsQ0FBQztBQUNQdEMsWUFBTSxRQURDO0FBRVB1QyxrQkFBWTtBQUNWQyxnQkFBUTtBQUNOeEMsZ0JBQU0sT0FEQTtBQUVOeUMsaUJBQU87QUFDTHpDLGtCQUFNLFFBREQsRUFGRDs7QUFLTjBDLHVCQUFhLElBTFAsRUFERSxFQUZMLEVBQUQsQ0FSSixFQURTOzs7Ozs7QUF1QmZDLFFBdkJlLCtCQXVCUkMsT0F2QlEsRUF1QkM7QUFDZCxVQUFNQyxjQUFjRCxRQUFRRSxPQUFSLENBQWdCLENBQWhCLEtBQXNCLEVBQTFDO0FBQ0EsVUFBTUMsY0FBY0YsWUFBWUwsTUFBaEM7O0FBRUEsYUFBTztBQUNMUSxnQ0FESyxpREFDb0IzQyxJQURwQixFQUMwQjtBQUM3QixnQkFBSTBDLGVBQWVBLFlBQVlFLElBQVosQ0FBaUIsVUFBQ0MsSUFBRCxVQUFVLDRCQUFVN0MsS0FBS0ksTUFBTCxDQUFZMEMsTUFBWixDQUFtQmpELEtBQTdCLEVBQW9DZ0QsSUFBcEMsRUFBMEMsRUFBRUUsV0FBVyxJQUFiLEVBQTFDLENBQVYsRUFBakIsQ0FBbkIsRUFBK0c7QUFDN0c7QUFDRDs7QUFFRCxnQkFBTUMsaUJBQWlCVCxRQUFRVSxRQUFSLEdBQW1CM0MsU0FBMUM7QUFDQSxnQkFBTTRDLG9CQUFvQkYsZUFBZUosSUFBZixDQUFvQixVQUFDbEMsUUFBRCxVQUFjQSxTQUFTeUMsSUFBVCxDQUFjLENBQWQsRUFBaUJuRCxJQUFqQixLQUEwQkEsSUFBeEMsRUFBcEIsQ0FBMUI7QUFDQSxnQkFBTW9ELHNCQUFzQkYsa0JBQWtCRyxVQUE5QztBQUNBLGdCQUFNL0IsdUJBQXVCOEIsb0JBQW9CM0MsR0FBcEIsQ0FBd0IsVUFBQzZDLFNBQUQsVUFBZUEsVUFBVTlCLFVBQXpCLEVBQXhCLENBQTdCO0FBQ0EsZ0JBQU0rQixTQUFTakMscUJBQXFCa0MsTUFBckIsR0FBOEIsQ0FBOUIsSUFBbUMsQ0FBQ25DLHNCQUFzQkMsb0JBQXRCLENBQW5EOztBQUVBaUIsb0JBQVFrQixNQUFSLENBQWU7QUFDYnpELHdCQURhO0FBRWIwRCxxREFGYTtBQUdiQyxtQkFBS0osVUFBVyxVQUFDSyxLQUFELEVBQVc7QUFDekIsb0JBQU03RCxlQUFld0MsUUFBUXNCLGFBQVIsR0FBd0I5RCxZQUE3QztBQUNBLG9CQUFNK0QsUUFBUSxFQUFkOztBQUVBO0FBQ0E7QUFDQSxvQkFBTUMsc0JBQXNCLEVBQTVCO0FBQ0F6QyxxQ0FBcUJOLE9BQXJCLENBQTZCLFVBQUNRLFVBQUQsRUFBZ0I7QUFDM0Msc0JBQU1wQixTQUFTb0IsV0FBV3BCLE1BQTFCO0FBQ0Esc0JBQUlBLFVBQVVBLE9BQU9ULElBQVAsS0FBZ0Isa0JBQTlCLEVBQWtEO0FBQ2hELHdCQUFNcUUsYUFBYXhFLHNCQUFzQlksTUFBdEIsQ0FBbkI7QUFDQSx3QkFBTTZELGlCQUFpQm5FLHdCQUF3QkMsWUFBeEIsRUFBc0NLLE1BQXRDLENBQXZCO0FBQ0Esd0JBQUksQ0FBQzJELG9CQUFvQkMsVUFBcEIsQ0FBTCxFQUFzQztBQUNwQ0QsMENBQW9CQyxVQUFwQixJQUFrQ0MsY0FBbEM7QUFDRCxxQkFGRCxNQUVPO0FBQ0xBLHFDQUFlakQsT0FBZixDQUF1QixVQUFDa0QsQ0FBRCxVQUFPSCxvQkFBb0JDLFVBQXBCLEVBQWdDRyxHQUFoQyxDQUFvQ0QsQ0FBcEMsQ0FBUCxFQUF2QjtBQUNEO0FBQ0Y7QUFDRixpQkFYRDs7QUFhQTtBQUNBLG9CQUFNRSxjQUFjQyxPQUFPQyxJQUFQLENBQVlQLG1CQUFaLENBQXBCO0FBQ0Esb0JBQU1RLG1CQUFtQjVEO0FBQ3ZCeUQsMkJBRHVCO0FBRXZCTCxtQ0FGdUI7QUFHdkJiLGtDQUFrQnRELElBSEssQ0FBekI7OztBQU1BO0FBQ0Esb0JBQU00RSx3QkFBd0JKLFlBQVkzRCxHQUFaLENBQWdCLFVBQUN1RCxVQUFELFVBQWdCQSxlQUFlTyxpQkFBaUJQLFVBQWpCLENBQWY7QUFDMURBLDRCQUQwRDtBQUV2REEsNEJBRnVELG9CQUV0Q08saUJBQWlCUCxVQUFqQixDQUZzQyxDQUFoQixFQUFoQixDQUE5Qjs7QUFJQUYsc0JBQU1XLElBQU4sQ0FBV2IsTUFBTWMsV0FBTixDQUFrQjFFLElBQWxCLGdCQUE2QndFLHNCQUFzQkcsSUFBdEIsQ0FBMkIsSUFBM0IsQ0FBN0IsU0FBWDs7QUFFQTtBQUNBckQscUNBQXFCTixPQUFyQixDQUE2QixVQUFDUSxVQUFELEVBQWdCO0FBQzNDLHNCQUFNcEIsU0FBU29CLFdBQVdwQixNQUExQjtBQUNBLHNCQUFJQSxVQUFVQSxPQUFPVCxJQUFQLEtBQWdCLGtCQUE5QixFQUFrRDtBQUNoRCx3QkFBTXFFLGFBQWF4RSxzQkFBc0JZLE1BQXRCLENBQW5CO0FBQ0EwRCwwQkFBTVcsSUFBTixDQUFXYixNQUFNYyxXQUFOLENBQWtCdEUsTUFBbEIsRUFBMEJtRSxpQkFBaUJQLFVBQWpCLENBQTFCLENBQVg7QUFDRDtBQUNGLGlCQU5EOztBQVFBLHVCQUFPRixLQUFQO0FBQ0QsZUFoRFksRUFBZjs7QUFrREQsV0E5REkscUNBQVA7O0FBZ0VELEtBM0ZjLG1CQUFqQiIsImZpbGUiOiJuby1uYW1lc3BhY2UuanMiLCJzb3VyY2VzQ29udGVudCI6WyIvKipcbiAqIEBmaWxlb3ZlcnZpZXcgUnVsZSB0byBkaXNhbGxvdyBuYW1lc3BhY2UgaW1wb3J0XG4gKiBAYXV0aG9yIFJhZGVrIEJlbmtlbFxuICovXG5cbmltcG9ydCBtaW5pbWF0Y2ggZnJvbSAnbWluaW1hdGNoJztcbmltcG9ydCBkb2NzVXJsIGZyb20gJy4uL2RvY3NVcmwnO1xuXG4vKipcbiAqIEBwYXJhbSB7TWVtYmVyRXhwcmVzc2lvbn0gbWVtYmVyRXhwcmVzc2lvblxuICogQHJldHVybnMge3N0cmluZ30gdGhlIG5hbWUgb2YgdGhlIG1lbWJlciBpbiB0aGUgb2JqZWN0IGV4cHJlc3Npb24sIGUuZy4gdGhlIGB4YCBpbiBgbmFtZXNwYWNlLnhgXG4gKi9cbmZ1bmN0aW9uIGdldE1lbWJlclByb3BlcnR5TmFtZShtZW1iZXJFeHByZXNzaW9uKSB7XG4gIHJldHVybiBtZW1iZXJFeHByZXNzaW9uLnByb3BlcnR5LnR5cGUgPT09ICdJZGVudGlmaWVyJ1xuICAgID8gbWVtYmVyRXhwcmVzc2lvbi5wcm9wZXJ0eS5uYW1lXG4gICAgOiBtZW1iZXJFeHByZXNzaW9uLnByb3BlcnR5LnZhbHVlO1xufVxuXG4vKipcbiAqIEBwYXJhbSB7U2NvcGVNYW5hZ2VyfSBzY29wZU1hbmFnZXJcbiAqIEBwYXJhbSB7QVNUTm9kZX0gbm9kZVxuICogQHJldHVybiB7U2V0PHN0cmluZz59XG4gKi9cbmZ1bmN0aW9uIGdldFZhcmlhYmxlTmFtZXNJblNjb3BlKHNjb3BlTWFuYWdlciwgbm9kZSkge1xuICBsZXQgY3VycmVudE5vZGUgPSBub2RlO1xuICBsZXQgc2NvcGUgPSBzY29wZU1hbmFnZXIuYWNxdWlyZShjdXJyZW50Tm9kZSk7XG4gIHdoaWxlIChzY29wZSA9PSBudWxsKSB7XG4gICAgY3VycmVudE5vZGUgPSBjdXJyZW50Tm9kZS5wYXJlbnQ7XG4gICAgc2NvcGUgPSBzY29wZU1hbmFnZXIuYWNxdWlyZShjdXJyZW50Tm9kZSwgdHJ1ZSk7XG4gIH1cbiAgcmV0dXJuIG5ldyBTZXQoc2NvcGUudmFyaWFibGVzLmNvbmNhdChzY29wZS51cHBlci52YXJpYWJsZXMpLm1hcCgodmFyaWFibGUpID0+IHZhcmlhYmxlLm5hbWUpKTtcbn1cblxuLyoqXG4gKlxuICogQHBhcmFtIHsqfSBuYW1lc1xuICogQHBhcmFtIHsqfSBuYW1lQ29uZmxpY3RzXG4gKiBAcGFyYW0geyp9IG5hbWVzcGFjZU5hbWVcbiAqL1xuZnVuY3Rpb24gZ2VuZXJhdGVMb2NhbE5hbWVzKG5hbWVzLCBuYW1lQ29uZmxpY3RzLCBuYW1lc3BhY2VOYW1lKSB7XG4gIGNvbnN0IGxvY2FsTmFtZXMgPSB7fTtcbiAgbmFtZXMuZm9yRWFjaCgobmFtZSkgPT4ge1xuICAgIGxldCBsb2NhbE5hbWU7XG4gICAgaWYgKCFuYW1lQ29uZmxpY3RzW25hbWVdLmhhcyhuYW1lKSkge1xuICAgICAgbG9jYWxOYW1lID0gbmFtZTtcbiAgICB9IGVsc2UgaWYgKCFuYW1lQ29uZmxpY3RzW25hbWVdLmhhcyhgJHtuYW1lc3BhY2VOYW1lfV8ke25hbWV9YCkpIHtcbiAgICAgIGxvY2FsTmFtZSA9IGAke25hbWVzcGFjZU5hbWV9XyR7bmFtZX1gO1xuICAgIH0gZWxzZSB7XG4gICAgICBmb3IgKGxldCBpID0gMTsgaSA8IEluZmluaXR5OyBpKyspIHtcbiAgICAgICAgaWYgKCFuYW1lQ29uZmxpY3RzW25hbWVdLmhhcyhgJHtuYW1lc3BhY2VOYW1lfV8ke25hbWV9XyR7aX1gKSkge1xuICAgICAgICAgIGxvY2FsTmFtZSA9IGAke25hbWVzcGFjZU5hbWV9XyR7bmFtZX1fJHtpfWA7XG4gICAgICAgICAgYnJlYWs7XG4gICAgICAgIH1cbiAgICAgIH1cbiAgICB9XG4gICAgbG9jYWxOYW1lc1tuYW1lXSA9IGxvY2FsTmFtZTtcbiAgfSk7XG4gIHJldHVybiBsb2NhbE5hbWVzO1xufVxuXG4vKipcbiAqIEBwYXJhbSB7SWRlbnRpZmllcltdfSBuYW1lc3BhY2VJZGVudGlmaWVyc1xuICogQHJldHVybnMge2Jvb2xlYW59IGB0cnVlYCBpZiB0aGUgbmFtZXNwYWNlIHZhcmlhYmxlIGlzIG1vcmUgdGhhbiBqdXN0IGEgZ2xvcmlmaWVkIGNvbnN0YW50XG4gKi9cbmZ1bmN0aW9uIHVzZXNOYW1lc3BhY2VBc09iamVjdChuYW1lc3BhY2VJZGVudGlmaWVycykge1xuICByZXR1cm4gIW5hbWVzcGFjZUlkZW50aWZpZXJzLmV2ZXJ5KChpZGVudGlmaWVyKSA9PiB7XG4gICAgY29uc3QgcGFyZW50ID0gaWRlbnRpZmllci5wYXJlbnQ7XG5cbiAgICAvLyBgbmFtZXNwYWNlLnhgIG9yIGBuYW1lc3BhY2VbJ3gnXWBcbiAgICByZXR1cm4gKFxuICAgICAgcGFyZW50XG4gICAgICAmJiBwYXJlbnQudHlwZSA9PT0gJ01lbWJlckV4cHJlc3Npb24nXG4gICAgICAmJiAocGFyZW50LnByb3BlcnR5LnR5cGUgPT09ICdJZGVudGlmaWVyJyB8fCBwYXJlbnQucHJvcGVydHkudHlwZSA9PT0gJ0xpdGVyYWwnKVxuICAgICk7XG4gIH0pO1xufVxuXG5tb2R1bGUuZXhwb3J0cyA9IHtcbiAgbWV0YToge1xuICAgIHR5cGU6ICdzdWdnZXN0aW9uJyxcbiAgICBkb2NzOiB7XG4gICAgICBjYXRlZ29yeTogJ1N0eWxlIGd1aWRlJyxcbiAgICAgIGRlc2NyaXB0aW9uOiAnRm9yYmlkIG5hbWVzcGFjZSAoYS5rLmEuIFwid2lsZGNhcmRcIiBgKmApIGltcG9ydHMuJyxcbiAgICAgIHVybDogZG9jc1VybCgnbm8tbmFtZXNwYWNlJyksXG4gICAgfSxcbiAgICBmaXhhYmxlOiAnY29kZScsXG4gICAgc2NoZW1hOiBbe1xuICAgICAgdHlwZTogJ29iamVjdCcsXG4gICAgICBwcm9wZXJ0aWVzOiB7XG4gICAgICAgIGlnbm9yZToge1xuICAgICAgICAgIHR5cGU6ICdhcnJheScsXG4gICAgICAgICAgaXRlbXM6IHtcbiAgICAgICAgICAgIHR5cGU6ICdzdHJpbmcnLFxuICAgICAgICAgIH0sXG4gICAgICAgICAgdW5pcXVlSXRlbXM6IHRydWUsXG4gICAgICAgIH0sXG4gICAgICB9LFxuICAgIH1dLFxuICB9LFxuXG4gIGNyZWF0ZShjb250ZXh0KSB7XG4gICAgY29uc3QgZmlyc3RPcHRpb24gPSBjb250ZXh0Lm9wdGlvbnNbMF0gfHwge307XG4gICAgY29uc3QgaWdub3JlR2xvYnMgPSBmaXJzdE9wdGlvbi5pZ25vcmU7XG5cbiAgICByZXR1cm4ge1xuICAgICAgSW1wb3J0TmFtZXNwYWNlU3BlY2lmaWVyKG5vZGUpIHtcbiAgICAgICAgaWYgKGlnbm9yZUdsb2JzICYmIGlnbm9yZUdsb2JzLmZpbmQoKGdsb2IpID0+IG1pbmltYXRjaChub2RlLnBhcmVudC5zb3VyY2UudmFsdWUsIGdsb2IsIHsgbWF0Y2hCYXNlOiB0cnVlIH0pKSkge1xuICAgICAgICAgIHJldHVybjtcbiAgICAgICAgfVxuXG4gICAgICAgIGNvbnN0IHNjb3BlVmFyaWFibGVzID0gY29udGV4dC5nZXRTY29wZSgpLnZhcmlhYmxlcztcbiAgICAgICAgY29uc3QgbmFtZXNwYWNlVmFyaWFibGUgPSBzY29wZVZhcmlhYmxlcy5maW5kKCh2YXJpYWJsZSkgPT4gdmFyaWFibGUuZGVmc1swXS5ub2RlID09PSBub2RlKTtcbiAgICAgICAgY29uc3QgbmFtZXNwYWNlUmVmZXJlbmNlcyA9IG5hbWVzcGFjZVZhcmlhYmxlLnJlZmVyZW5jZXM7XG4gICAgICAgIGNvbnN0IG5hbWVzcGFjZUlkZW50aWZpZXJzID0gbmFtZXNwYWNlUmVmZXJlbmNlcy5tYXAoKHJlZmVyZW5jZSkgPT4gcmVmZXJlbmNlLmlkZW50aWZpZXIpO1xuICAgICAgICBjb25zdCBjYW5GaXggPSBuYW1lc3BhY2VJZGVudGlmaWVycy5sZW5ndGggPiAwICYmICF1c2VzTmFtZXNwYWNlQXNPYmplY3QobmFtZXNwYWNlSWRlbnRpZmllcnMpO1xuXG4gICAgICAgIGNvbnRleHQucmVwb3J0KHtcbiAgICAgICAgICBub2RlLFxuICAgICAgICAgIG1lc3NhZ2U6IGBVbmV4cGVjdGVkIG5hbWVzcGFjZSBpbXBvcnQuYCxcbiAgICAgICAgICBmaXg6IGNhbkZpeCAmJiAoKGZpeGVyKSA9PiB7XG4gICAgICAgICAgICBjb25zdCBzY29wZU1hbmFnZXIgPSBjb250ZXh0LmdldFNvdXJjZUNvZGUoKS5zY29wZU1hbmFnZXI7XG4gICAgICAgICAgICBjb25zdCBmaXhlcyA9IFtdO1xuXG4gICAgICAgICAgICAvLyBQYXNzIDE6IENvbGxlY3QgdmFyaWFibGUgbmFtZXMgdGhhdCBhcmUgYWxyZWFkeSBpbiBzY29wZSBmb3IgZWFjaCByZWZlcmVuY2Ugd2Ugd2FudFxuICAgICAgICAgICAgLy8gdG8gdHJhbnNmb3JtLCBzbyB0aGF0IHdlIGNhbiBiZSBzdXJlIHRoYXQgd2UgY2hvb3NlIG5vbi1jb25mbGljdGluZyBpbXBvcnQgbmFtZXNcbiAgICAgICAgICAgIGNvbnN0IGltcG9ydE5hbWVDb25mbGljdHMgPSB7fTtcbiAgICAgICAgICAgIG5hbWVzcGFjZUlkZW50aWZpZXJzLmZvckVhY2goKGlkZW50aWZpZXIpID0+IHtcbiAgICAgICAgICAgICAgY29uc3QgcGFyZW50ID0gaWRlbnRpZmllci5wYXJlbnQ7XG4gICAgICAgICAgICAgIGlmIChwYXJlbnQgJiYgcGFyZW50LnR5cGUgPT09ICdNZW1iZXJFeHByZXNzaW9uJykge1xuICAgICAgICAgICAgICAgIGNvbnN0IGltcG9ydE5hbWUgPSBnZXRNZW1iZXJQcm9wZXJ0eU5hbWUocGFyZW50KTtcbiAgICAgICAgICAgICAgICBjb25zdCBsb2NhbENvbmZsaWN0cyA9IGdldFZhcmlhYmxlTmFtZXNJblNjb3BlKHNjb3BlTWFuYWdlciwgcGFyZW50KTtcbiAgICAgICAgICAgICAgICBpZiAoIWltcG9ydE5hbWVDb25mbGljdHNbaW1wb3J0TmFtZV0pIHtcbiAgICAgICAgICAgICAgICAgIGltcG9ydE5hbWVDb25mbGljdHNbaW1wb3J0TmFtZV0gPSBsb2NhbENvbmZsaWN0cztcbiAgICAgICAgICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgICAgICAgICAgbG9jYWxDb25mbGljdHMuZm9yRWFjaCgoYykgPT4gaW1wb3J0TmFtZUNvbmZsaWN0c1tpbXBvcnROYW1lXS5hZGQoYykpO1xuICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgfSk7XG5cbiAgICAgICAgICAgIC8vIENob29zZSBuZXcgbmFtZXMgZm9yIGVhY2ggaW1wb3J0XG4gICAgICAgICAgICBjb25zdCBpbXBvcnROYW1lcyA9IE9iamVjdC5rZXlzKGltcG9ydE5hbWVDb25mbGljdHMpO1xuICAgICAgICAgICAgY29uc3QgaW1wb3J0TG9jYWxOYW1lcyA9IGdlbmVyYXRlTG9jYWxOYW1lcyhcbiAgICAgICAgICAgICAgaW1wb3J0TmFtZXMsXG4gICAgICAgICAgICAgIGltcG9ydE5hbWVDb25mbGljdHMsXG4gICAgICAgICAgICAgIG5hbWVzcGFjZVZhcmlhYmxlLm5hbWUsXG4gICAgICAgICAgICApO1xuXG4gICAgICAgICAgICAvLyBSZXBsYWNlIHRoZSBJbXBvcnROYW1lc3BhY2VTcGVjaWZpZXIgd2l0aCBhIGxpc3Qgb2YgSW1wb3J0U3BlY2lmaWVyc1xuICAgICAgICAgICAgY29uc3QgbmFtZWRJbXBvcnRTcGVjaWZpZXJzID0gaW1wb3J0TmFtZXMubWFwKChpbXBvcnROYW1lKSA9PiBpbXBvcnROYW1lID09PSBpbXBvcnRMb2NhbE5hbWVzW2ltcG9ydE5hbWVdXG4gICAgICAgICAgICAgID8gaW1wb3J0TmFtZVxuICAgICAgICAgICAgICA6IGAke2ltcG9ydE5hbWV9IGFzICR7aW1wb3J0TG9jYWxOYW1lc1tpbXBvcnROYW1lXX1gLFxuICAgICAgICAgICAgKTtcbiAgICAgICAgICAgIGZpeGVzLnB1c2goZml4ZXIucmVwbGFjZVRleHQobm9kZSwgYHsgJHtuYW1lZEltcG9ydFNwZWNpZmllcnMuam9pbignLCAnKX0gfWApKTtcblxuICAgICAgICAgICAgLy8gUGFzcyAyOiBSZXBsYWNlIHJlZmVyZW5jZXMgdG8gdGhlIG5hbWVzcGFjZSB3aXRoIHJlZmVyZW5jZXMgdG8gdGhlIG5hbWVkIGltcG9ydHNcbiAgICAgICAgICAgIG5hbWVzcGFjZUlkZW50aWZpZXJzLmZvckVhY2goKGlkZW50aWZpZXIpID0+IHtcbiAgICAgICAgICAgICAgY29uc3QgcGFyZW50ID0gaWRlbnRpZmllci5wYXJlbnQ7XG4gICAgICAgICAgICAgIGlmIChwYXJlbnQgJiYgcGFyZW50LnR5cGUgPT09ICdNZW1iZXJFeHByZXNzaW9uJykge1xuICAgICAgICAgICAgICAgIGNvbnN0IGltcG9ydE5hbWUgPSBnZXRNZW1iZXJQcm9wZXJ0eU5hbWUocGFyZW50KTtcbiAgICAgICAgICAgICAgICBmaXhlcy5wdXNoKGZpeGVyLnJlcGxhY2VUZXh0KHBhcmVudCwgaW1wb3J0TG9jYWxOYW1lc1tpbXBvcnROYW1lXSkpO1xuICAgICAgICAgICAgICB9XG4gICAgICAgICAgICB9KTtcblxuICAgICAgICAgICAgcmV0dXJuIGZpeGVzO1xuICAgICAgICAgIH0pLFxuICAgICAgICB9KTtcbiAgICAgIH0sXG4gICAgfTtcbiAgfSxcbn07XG4iXX0=