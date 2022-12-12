'use strict';




var _docsUrl = require('../docsUrl');var _docsUrl2 = _interopRequireDefault(_docsUrl);function _interopRequireDefault(obj) {return obj && obj.__esModule ? obj : { default: obj };}function _toConsumableArray(arr) {if (Array.isArray(arr)) {for (var i = 0, arr2 = Array(arr.length); i < arr.length; i++) arr2[i] = arr[i];return arr2;} else {return Array.from(arr);}} /**
                                                                                                                                                                                                                                                                                                                                                                             * @fileoverview Rule to disallow namespace import
                                                                                                                                                                                                                                                                                                                                                                             * @author Radek Benkel
                                                                                                                                                                                                                                                                                                                                                                             */ //------------------------------------------------------------------------------
// Rule Definition
//------------------------------------------------------------------------------

module.exports = {
  meta: {
    type: 'suggestion',
    docs: {
      url: (0, _docsUrl2.default)('no-namespace') },

    fixable: 'code',
    schema: [] },


  create: function (context) {
    return {
      'ImportNamespaceSpecifier': function (node) {
        const scopeVariables = context.getScope().variables;
        const namespaceVariable = scopeVariables.find(variable =>
        variable.defs[0].node === node);

        const namespaceReferences = namespaceVariable.references;
        const namespaceIdentifiers = namespaceReferences.map(reference => reference.identifier);
        const canFix = namespaceIdentifiers.length > 0 && !usesNamespaceAsObject(namespaceIdentifiers);

        context.report({
          node,
          message: `Unexpected namespace import.`,
          fix: canFix && (fixer => {
            const scopeManager = context.getSourceCode().scopeManager;
            const fixes = [];

            // Pass 1: Collect variable names that are already in scope for each reference we want
            // to transform, so that we can be sure that we choose non-conflicting import names
            const importNameConflicts = {};
            namespaceIdentifiers.forEach(identifier => {
              const parent = identifier.parent;
              if (parent && parent.type === 'MemberExpression') {
                const importName = getMemberPropertyName(parent);
                const localConflicts = getVariableNamesInScope(scopeManager, parent);
                if (!importNameConflicts[importName]) {
                  importNameConflicts[importName] = localConflicts;
                } else {
                  localConflicts.forEach(c => importNameConflicts[importName].add(c));
                }
              }
            });

            // Choose new names for each import
            const importNames = Object.keys(importNameConflicts);
            const importLocalNames = generateLocalNames(
            importNames,
            importNameConflicts,
            namespaceVariable.name);


            // Replace the ImportNamespaceSpecifier with a list of ImportSpecifiers
            const namedImportSpecifiers = importNames.map(importName =>
            importName === importLocalNames[importName] ?
            importName :
            `${importName} as ${importLocalNames[importName]}`);

            fixes.push(fixer.replaceText(node, `{ ${namedImportSpecifiers.join(', ')} }`));

            // Pass 2: Replace references to the namespace with references to the named imports
            namespaceIdentifiers.forEach(identifier => {
              const parent = identifier.parent;
              if (parent && parent.type === 'MemberExpression') {
                const importName = getMemberPropertyName(parent);
                fixes.push(fixer.replaceText(parent, importLocalNames[importName]));
              }
            });

            return fixes;
          }) });

      } };

  }


  /**
     * @param {Identifier[]} namespaceIdentifiers
     * @returns {boolean} `true` if the namespace variable is more than just a glorified constant
     */ };
function usesNamespaceAsObject(namespaceIdentifiers) {
  return !namespaceIdentifiers.every(identifier => {
    const parent = identifier.parent;

    // `namespace.x` or `namespace['x']`
    return (
      parent && parent.type === 'MemberExpression' && (
      parent.property.type === 'Identifier' || parent.property.type === 'Literal'));

  });
}

/**
   * @param {MemberExpression} memberExpression
   * @returns {string} the name of the member in the object expression, e.g. the `x` in `namespace.x`
   */
function getMemberPropertyName(memberExpression) {
  return memberExpression.property.type === 'Identifier' ?
  memberExpression.property.name :
  memberExpression.property.value;
}

/**
   * @param {ScopeManager} scopeManager
   * @param {ASTNode} node
   * @return {Set<string>}
   */
function getVariableNamesInScope(scopeManager, node) {
  let currentNode = node;
  let scope = scopeManager.acquire(currentNode);
  while (scope == null) {
    currentNode = currentNode.parent;
    scope = scopeManager.acquire(currentNode, true);
  }
  return new Set([].concat(_toConsumableArray(
  scope.variables.map(variable => variable.name)), _toConsumableArray(
  scope.upper.variables.map(variable => variable.name))));

}

/**
   *
   * @param {*} names
   * @param {*} nameConflicts
   * @param {*} namespaceName
   */
function generateLocalNames(names, nameConflicts, namespaceName) {
  const localNames = {};
  names.forEach(name => {
    let localName;
    if (!nameConflicts[name].has(name)) {
      localName = name;
    } else if (!nameConflicts[name].has(`${namespaceName}_${name}`)) {
      localName = `${namespaceName}_${name}`;
    } else {
      for (let i = 1; i < Infinity; i++) {
        if (!nameConflicts[name].has(`${namespaceName}_${name}_${i}`)) {
          localName = `${namespaceName}_${name}_${i}`;
          break;
        }
      }
    }
    localNames[name] = localName;
  });
  return localNames;
}
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIi4uLy4uL3NyYy9ydWxlcy9uby1uYW1lc3BhY2UuanMiXSwibmFtZXMiOlsibW9kdWxlIiwiZXhwb3J0cyIsIm1ldGEiLCJ0eXBlIiwiZG9jcyIsInVybCIsImZpeGFibGUiLCJzY2hlbWEiLCJjcmVhdGUiLCJjb250ZXh0Iiwibm9kZSIsInNjb3BlVmFyaWFibGVzIiwiZ2V0U2NvcGUiLCJ2YXJpYWJsZXMiLCJuYW1lc3BhY2VWYXJpYWJsZSIsImZpbmQiLCJ2YXJpYWJsZSIsImRlZnMiLCJuYW1lc3BhY2VSZWZlcmVuY2VzIiwicmVmZXJlbmNlcyIsIm5hbWVzcGFjZUlkZW50aWZpZXJzIiwibWFwIiwicmVmZXJlbmNlIiwiaWRlbnRpZmllciIsImNhbkZpeCIsImxlbmd0aCIsInVzZXNOYW1lc3BhY2VBc09iamVjdCIsInJlcG9ydCIsIm1lc3NhZ2UiLCJmaXgiLCJmaXhlciIsInNjb3BlTWFuYWdlciIsImdldFNvdXJjZUNvZGUiLCJmaXhlcyIsImltcG9ydE5hbWVDb25mbGljdHMiLCJmb3JFYWNoIiwicGFyZW50IiwiaW1wb3J0TmFtZSIsImdldE1lbWJlclByb3BlcnR5TmFtZSIsImxvY2FsQ29uZmxpY3RzIiwiZ2V0VmFyaWFibGVOYW1lc0luU2NvcGUiLCJjIiwiYWRkIiwiaW1wb3J0TmFtZXMiLCJPYmplY3QiLCJrZXlzIiwiaW1wb3J0TG9jYWxOYW1lcyIsImdlbmVyYXRlTG9jYWxOYW1lcyIsIm5hbWUiLCJuYW1lZEltcG9ydFNwZWNpZmllcnMiLCJwdXNoIiwicmVwbGFjZVRleHQiLCJqb2luIiwiZXZlcnkiLCJwcm9wZXJ0eSIsIm1lbWJlckV4cHJlc3Npb24iLCJ2YWx1ZSIsImN1cnJlbnROb2RlIiwic2NvcGUiLCJhY3F1aXJlIiwiU2V0IiwidXBwZXIiLCJuYW1lcyIsIm5hbWVDb25mbGljdHMiLCJuYW1lc3BhY2VOYW1lIiwibG9jYWxOYW1lcyIsImxvY2FsTmFtZSIsImhhcyIsImkiLCJJbmZpbml0eSJdLCJtYXBwaW5ncyI6Ijs7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QVosQ0FBc0JRLEdBQXRCLENBQTBCTCxZQUFZQSxTQUFTZ0MsSUFBL0MsQ0FGRSxHQUFQOztBQUlEOztBQUVEOzs7Ozs7QUFNQSxTQUFTRCxrQkFBVCxDQUE0QmUsS0FBNUIsRUFBbUNDLGFBQW5DLEVBQWtEQyxhQUFsRCxFQUFpRTtBQUMvRCxRQUFNQyxhQUFhLEVBQW5CO0FBQ0FILFFBQU0zQixPQUFOLENBQWVhLElBQUQsSUFBVTtBQUN0QixRQUFJa0IsU0FBSjtBQUNBLFFBQUksQ0FBQ0gsY0FBY2YsSUFBZCxFQUFvQm1CLEdBQXBCLENBQXdCbkIsSUFBeEIsQ0FBTCxFQUFvQztBQUNsQ2tCLGtCQUFZbEIsSUFBWjtBQUNELEtBRkQsTUFFTyxJQUFJLENBQUNlLGNBQWNmLElBQWQsRUFBb0JtQixHQUFwQixDQUF5QixHQUFFSCxhQUFjLElBQUdoQixJQUFLLEVBQWpELENBQUwsRUFBMEQ7QUFDL0RrQixrQkFBYSxHQUFFRixhQUFjLElBQUdoQixJQUFLLEVBQXJDO0FBQ0QsS0FGTSxNQUVBO0FBQ0wsV0FBSyxJQUFJb0IsSUFBSSxDQUFiLEVBQWdCQSxJQUFJQyxRQUFwQixFQUE4QkQsR0FBOUIsRUFBbUM7QUFDakMsWUFBSSxDQUFDTCxjQUFjZixJQUFkLEVBQW9CbUIsR0FBcEIsQ0FBeUIsR0FBRUgsYUFBYyxJQUFHaEIsSUFBSyxJQUFHb0IsQ0FBRSxFQUF0RCxDQUFMLEVBQStEO0FBQzdERixzQkFBYSxHQUFFRixhQUFjLElBQUdoQixJQUFLLElBQUdvQixDQUFFLEVBQTFDO0FBQ0E7QUFDRDtBQUNGO0FBQ0Y7QUFDREgsZUFBV2pCLElBQVgsSUFBbUJrQixTQUFuQjtBQUNELEdBZkQ7QUFnQkEsU0FBT0QsVUFBUDtBQUNEIiwiZmlsZSI6Im5vLW5hbWVzcGFjZS5qcyIsInNvdXJjZXNDb250ZW50IjpbIi8qKlxuICogQGZpbGVvdmVydmlldyBSdWxlIHRvIGRpc2FsbG93IG5hbWVzcGFjZSBpbXBvcnRcbiAqIEBhdXRob3IgUmFkZWsgQmVua2VsXG4gKi9cblxuaW1wb3J0IGRvY3NVcmwgZnJvbSAnLi4vZG9jc1VybCdcblxuLy8tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS1cbi8vIFJ1bGUgRGVmaW5pdGlvblxuLy8tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS1cblxuXG5tb2R1bGUuZXhwb3J0cyA9IHtcbiAgbWV0YToge1xuICAgIHR5cGU6ICdzdWdnZXN0aW9uJyxcbiAgICBkb2NzOiB7XG4gICAgICB1cmw6IGRvY3NVcmwoJ25vLW5hbWVzcGFjZScpLFxuICAgIH0sXG4gICAgZml4YWJsZTogJ2NvZGUnLFxuICAgIHNjaGVtYTogW10sXG4gIH0sXG5cbiAgY3JlYXRlOiBmdW5jdGlvbiAoY29udGV4dCkge1xuICAgIHJldHVybiB7XG4gICAgICAnSW1wb3J0TmFtZXNwYWNlU3BlY2lmaWVyJzogZnVuY3Rpb24gKG5vZGUpIHtcbiAgICAgICAgY29uc3Qgc2NvcGVWYXJpYWJsZXMgPSBjb250ZXh0LmdldFNjb3BlKCkudmFyaWFibGVzXG4gICAgICAgIGNvbnN0IG5hbWVzcGFjZVZhcmlhYmxlID0gc2NvcGVWYXJpYWJsZXMuZmluZCgodmFyaWFibGUpID0+XG4gICAgICAgICAgdmFyaWFibGUuZGVmc1swXS5ub2RlID09PSBub2RlXG4gICAgICAgIClcbiAgICAgICAgY29uc3QgbmFtZXNwYWNlUmVmZXJlbmNlcyA9IG5hbWVzcGFjZVZhcmlhYmxlLnJlZmVyZW5jZXNcbiAgICAgICAgY29uc3QgbmFtZXNwYWNlSWRlbnRpZmllcnMgPSBuYW1lc3BhY2VSZWZlcmVuY2VzLm1hcChyZWZlcmVuY2UgPT4gcmVmZXJlbmNlLmlkZW50aWZpZXIpXG4gICAgICAgIGNvbnN0IGNhbkZpeCA9IG5hbWVzcGFjZUlkZW50aWZpZXJzLmxlbmd0aCA+IDAgJiYgIXVzZXNOYW1lc3BhY2VBc09iamVjdChuYW1lc3BhY2VJZGVudGlmaWVycylcblxuICAgICAgICBjb250ZXh0LnJlcG9ydCh7XG4gICAgICAgICAgbm9kZSxcbiAgICAgICAgICBtZXNzYWdlOiBgVW5leHBlY3RlZCBuYW1lc3BhY2UgaW1wb3J0LmAsXG4gICAgICAgICAgZml4OiBjYW5GaXggJiYgKGZpeGVyID0+IHtcbiAgICAgICAgICAgIGNvbnN0IHNjb3BlTWFuYWdlciA9IGNvbnRleHQuZ2V0U291cmNlQ29kZSgpLnNjb3BlTWFuYWdlclxuICAgICAgICAgICAgY29uc3QgZml4ZXMgPSBbXVxuXG4gICAgICAgICAgICAvLyBQYXNzIDE6IENvbGxlY3QgdmFyaWFibGUgbmFtZXMgdGhhdCBhcmUgYWxyZWFkeSBpbiBzY29wZSBmb3IgZWFjaCByZWZlcmVuY2Ugd2Ugd2FudFxuICAgICAgICAgICAgLy8gdG8gdHJhbnNmb3JtLCBzbyB0aGF0IHdlIGNhbiBiZSBzdXJlIHRoYXQgd2UgY2hvb3NlIG5vbi1jb25mbGljdGluZyBpbXBvcnQgbmFtZXNcbiAgICAgICAgICAgIGNvbnN0IGltcG9ydE5hbWVDb25mbGljdHMgPSB7fVxuICAgICAgICAgICAgbmFtZXNwYWNlSWRlbnRpZmllcnMuZm9yRWFjaCgoaWRlbnRpZmllcikgPT4ge1xuICAgICAgICAgICAgICBjb25zdCBwYXJlbnQgPSBpZGVudGlmaWVyLnBhcmVudFxuICAgICAgICAgICAgICBpZiAocGFyZW50ICYmIHBhcmVudC50eXBlID09PSAnTWVtYmVyRXhwcmVzc2lvbicpIHtcbiAgICAgICAgICAgICAgICBjb25zdCBpbXBvcnROYW1lID0gZ2V0TWVtYmVyUHJvcGVydHlOYW1lKHBhcmVudClcbiAgICAgICAgICAgICAgICBjb25zdCBsb2NhbENvbmZsaWN0cyA9IGdldFZhcmlhYmxlTmFtZXNJblNjb3BlKHNjb3BlTWFuYWdlciwgcGFyZW50KVxuICAgICAgICAgICAgICAgIGlmICghaW1wb3J0TmFtZUNvbmZsaWN0c1tpbXBvcnROYW1lXSkge1xuICAgICAgICAgICAgICAgICAgaW1wb3J0TmFtZUNvbmZsaWN0c1tpbXBvcnROYW1lXSA9IGxvY2FsQ29uZmxpY3RzXG4gICAgICAgICAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICAgICAgICAgIGxvY2FsQ29uZmxpY3RzLmZvckVhY2goKGMpID0+IGltcG9ydE5hbWVDb25mbGljdHNbaW1wb3J0TmFtZV0uYWRkKGMpKVxuICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgfSlcblxuICAgICAgICAgICAgLy8gQ2hvb3NlIG5ldyBuYW1lcyBmb3IgZWFjaCBpbXBvcnRcbiAgICAgICAgICAgIGNvbnN0IGltcG9ydE5hbWVzID0gT2JqZWN0LmtleXMoaW1wb3J0TmFtZUNvbmZsaWN0cylcbiAgICAgICAgICAgIGNvbnN0IGltcG9ydExvY2FsTmFtZXMgPSBnZW5lcmF0ZUxvY2FsTmFtZXMoXG4gICAgICAgICAgICAgIGltcG9ydE5hbWVzLFxuICAgICAgICAgICAgICBpbXBvcnROYW1lQ29uZmxpY3RzLFxuICAgICAgICAgICAgICBuYW1lc3BhY2VWYXJpYWJsZS5uYW1lXG4gICAgICAgICAgICApXG5cbiAgICAgICAgICAgIC8vIFJlcGxhY2UgdGhlIEltcG9ydE5hbWVzcGFjZVNwZWNpZmllciB3aXRoIGEgbGlzdCBvZiBJbXBvcnRTcGVjaWZpZXJzXG4gICAgICAgICAgICBjb25zdCBuYW1lZEltcG9ydFNwZWNpZmllcnMgPSBpbXBvcnROYW1lcy5tYXAoKGltcG9ydE5hbWUpID0+XG4gICAgICAgICAgICAgIGltcG9ydE5hbWUgPT09IGltcG9ydExvY2FsTmFtZXNbaW1wb3J0TmFtZV1cbiAgICAgICAgICAgICAgICA/IGltcG9ydE5hbWVcbiAgICAgICAgICAgICAgICA6IGAke2ltcG9ydE5hbWV9IGFzICR7aW1wb3J0TG9jYWxOYW1lc1tpbXBvcnROYW1lXX1gXG4gICAgICAgICAgICApXG4gICAgICAgICAgICBmaXhlcy5wdXNoKGZpeGVyLnJlcGxhY2VUZXh0KG5vZGUsIGB7ICR7bmFtZWRJbXBvcnRTcGVjaWZpZXJzLmpvaW4oJywgJyl9IH1gKSlcblxuICAgICAgICAgICAgLy8gUGFzcyAyOiBSZXBsYWNlIHJlZmVyZW5jZXMgdG8gdGhlIG5hbWVzcGFjZSB3aXRoIHJlZmVyZW5jZXMgdG8gdGhlIG5hbWVkIGltcG9ydHNcbiAgICAgICAgICAgIG5hbWVzcGFjZUlkZW50aWZpZXJzLmZvckVhY2goKGlkZW50aWZpZXIpID0+IHtcbiAgICAgICAgICAgICAgY29uc3QgcGFyZW50ID0gaWRlbnRpZmllci5wYXJlbnRcbiAgICAgICAgICAgICAgaWYgKHBhcmVudCAmJiBwYXJlbnQudHlwZSA9PT0gJ01lbWJlckV4cHJlc3Npb24nKSB7XG4gICAgICAgICAgICAgICAgY29uc3QgaW1wb3J0TmFtZSA9IGdldE1lbWJlclByb3BlcnR5TmFtZShwYXJlbnQpXG4gICAgICAgICAgICAgICAgZml4ZXMucHVzaChmaXhlci5yZXBsYWNlVGV4dChwYXJlbnQsIGltcG9ydExvY2FsTmFtZXNbaW1wb3J0TmFtZV0pKVxuICAgICAgICAgICAgICB9XG4gICAgICAgICAgICB9KVxuXG4gICAgICAgICAgICByZXR1cm4gZml4ZXNcbiAgICAgICAgICB9KSxcbiAgICAgICAgfSlcbiAgICAgIH0sXG4gICAgfVxuICB9LFxufVxuXG4vKipcbiAqIEBwYXJhbSB7SWRlbnRpZmllcltdfSBuYW1lc3BhY2VJZGVudGlmaWVyc1xuICogQHJldHVybnMge2Jvb2xlYW59IGB0cnVlYCBpZiB0aGUgbmFtZXNwYWNlIHZhcmlhYmxlIGlzIG1vcmUgdGhhbiBqdXN0IGEgZ2xvcmlmaWVkIGNvbnN0YW50XG4gKi9cbmZ1bmN0aW9uIHVzZXNOYW1lc3BhY2VBc09iamVjdChuYW1lc3BhY2VJZGVudGlmaWVycykge1xuICByZXR1cm4gIW5hbWVzcGFjZUlkZW50aWZpZXJzLmV2ZXJ5KChpZGVudGlmaWVyKSA9PiB7XG4gICAgY29uc3QgcGFyZW50ID0gaWRlbnRpZmllci5wYXJlbnRcblxuICAgIC8vIGBuYW1lc3BhY2UueGAgb3IgYG5hbWVzcGFjZVsneCddYFxuICAgIHJldHVybiAoXG4gICAgICBwYXJlbnQgJiYgcGFyZW50LnR5cGUgPT09ICdNZW1iZXJFeHByZXNzaW9uJyAmJlxuICAgICAgKHBhcmVudC5wcm9wZXJ0eS50eXBlID09PSAnSWRlbnRpZmllcicgfHwgcGFyZW50LnByb3BlcnR5LnR5cGUgPT09ICdMaXRlcmFsJylcbiAgICApXG4gIH0pXG59XG5cbi8qKlxuICogQHBhcmFtIHtNZW1iZXJFeHByZXNzaW9ufSBtZW1iZXJFeHByZXNzaW9uXG4gKiBAcmV0dXJucyB7c3RyaW5nfSB0aGUgbmFtZSBvZiB0aGUgbWVtYmVyIGluIHRoZSBvYmplY3QgZXhwcmVzc2lvbiwgZS5nLiB0aGUgYHhgIGluIGBuYW1lc3BhY2UueGBcbiAqL1xuZnVuY3Rpb24gZ2V0TWVtYmVyUHJvcGVydHlOYW1lKG1lbWJlckV4cHJlc3Npb24pIHtcbiAgcmV0dXJuIG1lbWJlckV4cHJlc3Npb24ucHJvcGVydHkudHlwZSA9PT0gJ0lkZW50aWZpZXInXG4gICAgPyBtZW1iZXJFeHByZXNzaW9uLnByb3BlcnR5Lm5hbWVcbiAgICA6IG1lbWJlckV4cHJlc3Npb24ucHJvcGVydHkudmFsdWVcbn1cblxuLyoqXG4gKiBAcGFyYW0ge1Njb3BlTWFuYWdlcn0gc2NvcGVNYW5hZ2VyXG4gKiBAcGFyYW0ge0FTVE5vZGV9IG5vZGVcbiAqIEByZXR1cm4ge1NldDxzdHJpbmc+fVxuICovXG5mdW5jdGlvbiBnZXRWYXJpYWJsZU5hbWVzSW5TY29wZShzY29wZU1hbmFnZXIsIG5vZGUpIHtcbiAgbGV0IGN1cnJlbnROb2RlID0gbm9kZVxuICBsZXQgc2NvcGUgPSBzY29wZU1hbmFnZXIuYWNxdWlyZShjdXJyZW50Tm9kZSlcbiAgd2hpbGUgKHNjb3BlID09IG51bGwpIHtcbiAgICBjdXJyZW50Tm9kZSA9IGN1cnJlbnROb2RlLnBhcmVudFxuICAgIHNjb3BlID0gc2NvcGVNYW5hZ2VyLmFjcXVpcmUoY3VycmVudE5vZGUsIHRydWUpXG4gIH1cbiAgcmV0dXJuIG5ldyBTZXQoW1xuICAgIC4uLnNjb3BlLnZhcmlhYmxlcy5tYXAodmFyaWFibGUgPT4gdmFyaWFibGUubmFtZSksXG4gICAgLi4uc2NvcGUudXBwZXIudmFyaWFibGVzLm1hcCh2YXJpYWJsZSA9PiB2YXJpYWJsZS5uYW1lKSxcbiAgXSlcbn1cblxuLyoqXG4gKlxuICogQHBhcmFtIHsqfSBuYW1lc1xuICogQHBhcmFtIHsqfSBuYW1lQ29uZmxpY3RzXG4gKiBAcGFyYW0geyp9IG5hbWVzcGFjZU5hbWVcbiAqL1xuZnVuY3Rpb24gZ2VuZXJhdGVMb2NhbE5hbWVzKG5hbWVzLCBuYW1lQ29uZmxpY3RzLCBuYW1lc3BhY2VOYW1lKSB7XG4gIGNvbnN0IGxvY2FsTmFtZXMgPSB7fVxuICBuYW1lcy5mb3JFYWNoKChuYW1lKSA9PiB7XG4gICAgbGV0IGxvY2FsTmFtZVxuICAgIGlmICghbmFtZUNvbmZsaWN0c1tuYW1lXS5oYXMobmFtZSkpIHtcbiAgICAgIGxvY2FsTmFtZSA9IG5hbWVcbiAgICB9IGVsc2UgaWYgKCFuYW1lQ29uZmxpY3RzW25hbWVdLmhhcyhgJHtuYW1lc3BhY2VOYW1lfV8ke25hbWV9YCkpIHtcbiAgICAgIGxvY2FsTmFtZSA9IGAke25hbWVzcGFjZU5hbWV9XyR7bmFtZX1gXG4gICAgfSBlbHNlIHtcbiAgICAgIGZvciAobGV0IGkgPSAxOyBpIDwgSW5maW5pdHk7IGkrKykge1xuICAgICAgICBpZiAoIW5hbWVDb25mbGljdHNbbmFtZV0uaGFzKGAke25hbWVzcGFjZU5hbWV9XyR7bmFtZX1fJHtpfWApKSB7XG4gICAgICAgICAgbG9jYWxOYW1lID0gYCR7bmFtZXNwYWNlTmFtZX1fJHtuYW1lfV8ke2l9YFxuICAgICAgICAgIGJyZWFrXG4gICAgICAgIH1cbiAgICAgIH1cbiAgICB9XG4gICAgbG9jYWxOYW1lc1tuYW1lXSA9IGxvY2FsTmFtZVxuICB9KVxuICByZXR1cm4gbG9jYWxOYW1lc1xufVxuIl19