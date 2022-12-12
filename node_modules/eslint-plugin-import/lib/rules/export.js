'use strict';var _slicedToArray = function () {function sliceIterator(arr, i) {var _arr = [];var _n = true;var _d = false;var _e = undefined;try {for (var _i = arr[Symbol.iterator](), _s; !(_n = (_s = _i.next()).done); _n = true) {_arr.push(_s.value);if (i && _arr.length === i) break;}} catch (err) {_d = true;_e = err;} finally {try {if (!_n && _i["return"]) _i["return"]();} finally {if (_d) throw _e;}}return _arr;}return function (arr, i) {if (Array.isArray(arr)) {return arr;} else if (Symbol.iterator in Object(arr)) {return sliceIterator(arr, i);} else {throw new TypeError("Invalid attempt to destructure non-iterable instance");}};}();var _ExportMap = require('../ExportMap');var _ExportMap2 = _interopRequireDefault(_ExportMap);
var _docsUrl = require('../docsUrl');var _docsUrl2 = _interopRequireDefault(_docsUrl);
var _arrayIncludes = require('array-includes');var _arrayIncludes2 = _interopRequireDefault(_arrayIncludes);function _interopRequireDefault(obj) {return obj && obj.__esModule ? obj : { default: obj };}

/*
                                                                                                                                                                                                          Notes on TypeScript namespaces aka TSModuleDeclaration:
                                                                                                                                                                                                          
                                                                                                                                                                                                          There are two forms:
                                                                                                                                                                                                          - active namespaces: namespace Foo {} / module Foo {}
                                                                                                                                                                                                          - ambient modules; declare module "eslint-plugin-import" {}
                                                                                                                                                                                                          
                                                                                                                                                                                                          active namespaces:
                                                                                                                                                                                                          - cannot contain a default export
                                                                                                                                                                                                          - cannot contain an export all
                                                                                                                                                                                                          - cannot contain a multi name export (export { a, b })
                                                                                                                                                                                                          - can have active namespaces nested within them
                                                                                                                                                                                                          
                                                                                                                                                                                                          ambient namespaces:
                                                                                                                                                                                                          - can only be defined in .d.ts files
                                                                                                                                                                                                          - cannot be nested within active namespaces
                                                                                                                                                                                                          - have no other restrictions
                                                                                                                                                                                                          */

const rootProgram = 'root';
const tsTypePrefix = 'type:';

/**
                               * Detect function overloads like:
                               * ```ts
                               * export function foo(a: number);
                               * export function foo(a: string);
                               * export function foo(a: number|string) { return a; }
                               * ```
                               * @param {Set<Object>} nodes
                               * @returns {boolean}
                               */
function isTypescriptFunctionOverloads(nodes) {
  const types = new Set(Array.from(nodes, node => node.parent.type));
  return (
    types.has('TSDeclareFunction') && (

    types.size === 1 ||
    types.size === 2 && types.has('FunctionDeclaration')));


}

module.exports = {
  meta: {
    type: 'problem',
    docs: {
      url: (0, _docsUrl2.default)('export') },

    schema: [] },


  create: function (context) {
    const namespace = new Map([[rootProgram, new Map()]]);

    function addNamed(name, node, parent, isType) {
      if (!namespace.has(parent)) {
        namespace.set(parent, new Map());
      }
      const named = namespace.get(parent);

      const key = isType ? `${tsTypePrefix}${name}` : name;
      let nodes = named.get(key);

      if (nodes == null) {
        nodes = new Set();
        named.set(key, nodes);
      }

      nodes.add(node);
    }

    function getParent(node) {
      if (node.parent && node.parent.type === 'TSModuleBlock') {
        return node.parent.parent;
      }

      // just in case somehow a non-ts namespace export declaration isn't directly
      // parented to the root Program node
      return rootProgram;
    }

    return {
      'ExportDefaultDeclaration': node => addNamed('default', node, getParent(node)),

      'ExportSpecifier': node => addNamed(node.exported.name, node.exported, getParent(node)),

      'ExportNamedDeclaration': function (node) {
        if (node.declaration == null) return;

        const parent = getParent(node);
        // support for old TypeScript versions
        const isTypeVariableDecl = node.declaration.kind === 'type';

        if (node.declaration.id != null) {
          if ((0, _arrayIncludes2.default)([
          'TSTypeAliasDeclaration',
          'TSInterfaceDeclaration'],
          node.declaration.type)) {
            addNamed(node.declaration.id.name, node.declaration.id, parent, true);
          } else {
            addNamed(node.declaration.id.name, node.declaration.id, parent, isTypeVariableDecl);
          }
        }

        if (node.declaration.declarations != null) {
          for (let declaration of node.declaration.declarations) {
            (0, _ExportMap.recursivePatternCapture)(declaration.id, v =>
            addNamed(v.name, v, parent, isTypeVariableDecl));
          }
        }
      },

      'ExportAllDeclaration': function (node) {
        if (node.source == null) return; // not sure if this is ever true

        // `export * as X from 'path'` does not conflict
        if (node.exported && node.exported.name) return;

        const remoteExports = _ExportMap2.default.get(node.source.value, context);
        if (remoteExports == null) return;

        if (remoteExports.errors.length) {
          remoteExports.reportErrors(context, node);
          return;
        }

        const parent = getParent(node);

        let any = false;
        remoteExports.forEach((v, name) =>
        name !== 'default' && (
        any = true) && // poor man's filter
        addNamed(name, node, parent));

        if (!any) {
          context.report(
          node.source,
          `No named exports found in module '${node.source.value}'.`);

        }
      },

      'Program:exit': function () {
        for (let _ref of namespace) {var _ref2 = _slicedToArray(_ref, 2);let named = _ref2[1];
          for (let _ref3 of named) {var _ref4 = _slicedToArray(_ref3, 2);let name = _ref4[0];let nodes = _ref4[1];
            if (nodes.size <= 1) continue;

            if (isTypescriptFunctionOverloads(nodes)) continue;

            for (let node of nodes) {
              if (name === 'default') {
                context.report(node, 'Multiple default exports.');
              } else {
                context.report(
                node,
                `Multiple exports of name '${name.replace(tsTypePrefix, '')}'.`);

              }
            }
          }
        }
      } };

  } };
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIi4uLy4uL3NyYy9ydWxlcy9leHBvcnQuanMiXSwibmFtZXMiOlsicm9vdFByb2dyYW0iLCJ0c1R5cGVQcmVmaXgiLCJpc1R5cGVzY3JpcHRGdW5jdGlvbk92ZXJsb2FkcyIsIm5vZGVzIiwidHlwZXMiLCJTZXQiLCJBcnJheSIsImZyb20iLCJub2RlIiwicGFyZW50IiwidHlwZSIsImhhcyIsInNpemUiLCJtb2R1bGUiLCJleHBvcnRzIiwibWV0YSIsImRvY3MiLCJ1cmwiLCJzY2hlbWEiLCJjcmVhdGUiLCJjb250ZXh0IiwibmFtZXNwYWNlIiwiTWFwIiwiYWRkTmFtZWQiLCJuYW1lIiwiaXNUeXBlIiwic2V0IiwibmFtZWQiLCJnZXQiLCJrZXkiLCJhZGQiLCJnZXRQYXJlbnQiLCJleHBvcnRlZCIsImRlY2xhcmF0aW9uIiwiaXNUeXBlVmFyaWFibGVEZWNsIiwia2luZCIsImlkIiwiZGVjbGFyYXRpb25zIiwidiIsInNvdXJjZSIsInJlbW90ZUV4cG9ydHMiLCJFeHBvcnRNYXAiLCJ2YWx1ZSIsImVycm9ycyIsImxlbmd0aCIsInJlcG9ydEVycm9ycyIsImFueSIsImZvckVhY2giLCJyZXBvcnQiLCJyZXBsYWNlIl0sIm1hcHBpbmdzIjoicW9CQUFBLHlDO0FBQ0EscUM7QUFDQSwrQzs7QUFFQTs7Ozs7Ozs7Ozs7Ozs7Ozs7OztBQW1CQSxNQUFNQSxjQUFjLE1BQXBCO0FBQ0EsTUFBTUMsZUFBZSxPQUFyQjs7QUFFQTs7Ozs7Ozs7OztBQVVBLFNBQVNDLDZCQUFULENBQXVDQyxLQUF2QyxFQUE4QztBQUM1QyxRQUFNQyxRQUFRLElBQUlDLEdBQUosQ0FBUUMsTUFBTUMsSUFBTixDQUFXSixLQUFYLEVBQWtCSyxRQUFRQSxLQUFLQyxNQUFMLENBQVlDLElBQXRDLENBQVIsQ0FBZDtBQUNBO0FBQ0VOLFVBQU1PLEdBQU4sQ0FBVSxtQkFBVjs7QUFFRVAsVUFBTVEsSUFBTixLQUFlLENBQWY7QUFDQ1IsVUFBTVEsSUFBTixLQUFlLENBQWYsSUFBb0JSLE1B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QTBCQSxLQUExQixFQUFpQywwQ0FBdkJILElBQXVCLGdCQUFqQnJCLEtBQWlCO0FBQy9CLGdCQUFJQSxNQUFNUyxJQUFOLElBQWMsQ0FBbEIsRUFBcUI7O0FBRXJCLGdCQUFJViw4QkFBOEJDLEtBQTlCLENBQUosRUFBMEM7O0FBRTFDLGlCQUFLLElBQUlLLElBQVQsSUFBaUJMLEtBQWpCLEVBQXdCO0FBQ3RCLGtCQUFJcUIsU0FBUyxTQUFiLEVBQXdCO0FBQ3RCSix3QkFBUTRCLE1BQVIsQ0FBZXhDLElBQWYsRUFBcUIsMkJBQXJCO0FBQ0QsZUFGRCxNQUVPO0FBQ0xZLHdCQUFRNEIsTUFBUjtBQUNFeEMsb0JBREY7QUFFRyw2Q0FBNEJnQixLQUFLeUIsT0FBTCxDQUFhaEQsWUFBYixFQUEyQixFQUEzQixDQUErQixJQUY5RDs7QUFJRDtBQUNGO0FBQ0Y7QUFDRjtBQUNGLE9BaEZJLEVBQVA7O0FBa0ZELEdBekhjLEVBQWpCIiwiZmlsZSI6ImV4cG9ydC5qcyIsInNvdXJjZXNDb250ZW50IjpbImltcG9ydCBFeHBvcnRNYXAsIHsgcmVjdXJzaXZlUGF0dGVybkNhcHR1cmUgfSBmcm9tICcuLi9FeHBvcnRNYXAnXG5pbXBvcnQgZG9jc1VybCBmcm9tICcuLi9kb2NzVXJsJ1xuaW1wb3J0IGluY2x1ZGVzIGZyb20gJ2FycmF5LWluY2x1ZGVzJ1xuXG4vKlxuTm90ZXMgb24gVHlwZVNjcmlwdCBuYW1lc3BhY2VzIGFrYSBUU01vZHVsZURlY2xhcmF0aW9uOlxuXG5UaGVyZSBhcmUgdHdvIGZvcm1zOlxuLSBhY3RpdmUgbmFtZXNwYWNlczogbmFtZXNwYWNlIEZvbyB7fSAvIG1vZHVsZSBGb28ge31cbi0gYW1iaWVudCBtb2R1bGVzOyBkZWNsYXJlIG1vZHVsZSBcImVzbGludC1wbHVnaW4taW1wb3J0XCIge31cblxuYWN0aXZlIG5hbWVzcGFjZXM6XG4tIGNhbm5vdCBjb250YWluIGEgZGVmYXVsdCBleHBvcnRcbi0gY2Fubm90IGNvbnRhaW4gYW4gZXhwb3J0IGFsbFxuLSBjYW5ub3QgY29udGFpbiBhIG11bHRpIG5hbWUgZXhwb3J0IChleHBvcnQgeyBhLCBiIH0pXG4tIGNhbiBoYXZlIGFjdGl2ZSBuYW1lc3BhY2VzIG5lc3RlZCB3aXRoaW4gdGhlbVxuXG5hbWJpZW50IG5hbWVzcGFjZXM6XG4tIGNhbiBvbmx5IGJlIGRlZmluZWQgaW4gLmQudHMgZmlsZXNcbi0gY2Fubm90IGJlIG5lc3RlZCB3aXRoaW4gYWN0aXZlIG5hbWVzcGFjZXNcbi0gaGF2ZSBubyBvdGhlciByZXN0cmljdGlvbnNcbiovXG5cbmNvbnN0IHJvb3RQcm9ncmFtID0gJ3Jvb3QnXG5jb25zdCB0c1R5cGVQcmVmaXggPSAndHlwZTonXG5cbi8qKlxuICogRGV0ZWN0IGZ1bmN0aW9uIG92ZXJsb2FkcyBsaWtlOlxuICogYGBgdHNcbiAqIGV4cG9ydCBmdW5jdGlvbiBmb28oYTogbnVtYmVyKTtcbiAqIGV4cG9ydCBmdW5jdGlvbiBmb28oYTogc3RyaW5nKTtcbiAqIGV4cG9ydCBmdW5jdGlvbiBmb28oYTogbnVtYmVyfHN0cmluZykgeyByZXR1cm4gYTsgfVxuICogYGBgXG4gKiBAcGFyYW0ge1NldDxPYmplY3Q+fSBub2Rlc1xuICogQHJldHVybnMge2Jvb2xlYW59XG4gKi9cbmZ1bmN0aW9uIGlzVHlwZXNjcmlwdEZ1bmN0aW9uT3ZlcmxvYWRzKG5vZGVzKSB7XG4gIGNvbnN0IHR5cGVzID0gbmV3IFNldChBcnJheS5mcm9tKG5vZGVzLCBub2RlID0+IG5vZGUucGFyZW50LnR5cGUpKVxuICByZXR1cm4gKFxuICAgIHR5cGVzLmhhcygnVFNEZWNsYXJlRnVuY3Rpb24nKSAmJlxuICAgIChcbiAgICAgIHR5cGVzLnNpemUgPT09IDEgfHxcbiAgICAgICh0eXBlcy5zaXplID09PSAyICYmIHR5cGVzLmhhcygnRnVuY3Rpb25EZWNsYXJhdGlvbicpKVxuICAgIClcbiAgKVxufVxuXG5tb2R1bGUuZXhwb3J0cyA9IHtcbiAgbWV0YToge1xuICAgIHR5cGU6ICdwcm9ibGVtJyxcbiAgICBkb2NzOiB7XG4gICAgICB1cmw6IGRvY3NVcmwoJ2V4cG9ydCcpLFxuICAgIH0sXG4gICAgc2NoZW1hOiBbXSxcbiAgfSxcblxuICBjcmVhdGU6IGZ1bmN0aW9uIChjb250ZXh0KSB7XG4gICAgY29uc3QgbmFtZXNwYWNlID0gbmV3IE1hcChbW3Jvb3RQcm9ncmFtLCBuZXcgTWFwKCldXSlcblxuICAgIGZ1bmN0aW9uIGFkZE5hbWVkKG5hbWUsIG5vZGUsIHBhcmVudCwgaXNUeXBlKSB7XG4gICAgICBpZiAoIW5hbWVzcGFjZS5oYXMocGFyZW50KSkge1xuICAgICAgICBuYW1lc3BhY2Uuc2V0KHBhcmVudCwgbmV3IE1hcCgpKVxuICAgICAgfVxuICAgICAgY29uc3QgbmFtZWQgPSBuYW1lc3BhY2UuZ2V0KHBhcmVudClcblxuICAgICAgY29uc3Qga2V5ID0gaXNUeXBlID8gYCR7dHNUeXBlUHJlZml4fSR7bmFtZX1gIDogbmFtZVxuICAgICAgbGV0IG5vZGVzID0gbmFtZWQuZ2V0KGtleSlcblxuICAgICAgaWYgKG5vZGVzID09IG51bGwpIHtcbiAgICAgICAgbm9kZXMgPSBuZXcgU2V0KClcbiAgICAgICAgbmFtZWQuc2V0KGtleSwgbm9kZXMpXG4gICAgICB9XG5cbiAgICAgIG5vZGVzLmFkZChub2RlKVxuICAgIH1cblxuICAgIGZ1bmN0aW9uIGdldFBhcmVudChub2RlKSB7XG4gICAgICBpZiAobm9kZS5wYXJlbnQgJiYgbm9kZS5wYXJlbnQudHlwZSA9PT0gJ1RTTW9kdWxlQmxvY2snKSB7XG4gICAgICAgIHJldHVybiBub2RlLnBhcmVudC5wYXJlbnRcbiAgICAgIH1cblxuICAgICAgLy8ganVzdCBpbiBjYXNlIHNvbWVob3cgYSBub24tdHMgbmFtZXNwYWNlIGV4cG9ydCBkZWNsYXJhdGlvbiBpc24ndCBkaXJlY3RseVxuICAgICAgLy8gcGFyZW50ZWQgdG8gdGhlIHJvb3QgUHJvZ3JhbSBub2RlXG4gICAgICByZXR1cm4gcm9vdFByb2dyYW1cbiAgICB9XG5cbiAgICByZXR1cm4ge1xuICAgICAgJ0V4cG9ydERlZmF1bHREZWNsYXJhdGlvbic6IChub2RlKSA9PiBhZGROYW1lZCgnZGVmYXVsdCcsIG5vZGUsIGdldFBhcmVudChub2RlKSksXG5cbiAgICAgICdFeHBvcnRTcGVjaWZpZXInOiAobm9kZSkgPT4gYWRkTmFtZWQobm9kZS5leHBvcnRlZC5uYW1lLCBub2RlLmV4cG9ydGVkLCBnZXRQYXJlbnQobm9kZSkpLFxuXG4gICAgICAnRXhwb3J0TmFtZWREZWNsYXJhdGlvbic6IGZ1bmN0aW9uIChub2RlKSB7XG4gICAgICAgIGlmIChub2RlLmRlY2xhcmF0aW9uID09IG51bGwpIHJldHVyblxuXG4gICAgICAgIGNvbnN0IHBhcmVudCA9IGdldFBhcmVudChub2RlKVxuICAgICAgICAvLyBzdXBwb3J0IGZvciBvbGQgVHlwZVNjcmlwdCB2ZXJzaW9uc1xuICAgICAgICBjb25zdCBpc1R5cGVWYXJpYWJsZURlY2wgPSBub2RlLmRlY2xhcmF0aW9uLmtpbmQgPT09ICd0eXBlJ1xuXG4gICAgICAgIGlmIChub2RlLmRlY2xhcmF0aW9uLmlkICE9IG51bGwpIHtcbiAgICAgICAgICBpZiAoaW5jbHVkZXMoW1xuICAgICAgICAgICAgJ1RTVHlwZUFsaWFzRGVjbGFyYXRpb24nLFxuICAgICAgICAgICAgJ1RTSW50ZXJmYWNlRGVjbGFyYXRpb24nLFxuICAgICAgICAgIF0sIG5vZGUuZGVjbGFyYXRpb24udHlwZSkpIHtcbiAgICAgICAgICAgIGFkZE5hbWVkKG5vZGUuZGVjbGFyYXRpb24uaWQubmFtZSwgbm9kZS5kZWNsYXJhdGlvbi5pZCwgcGFyZW50LCB0cnVlKVxuICAgICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgICBhZGROYW1lZChub2RlLmRlY2xhcmF0aW9uLmlkLm5hbWUsIG5vZGUuZGVjbGFyYXRpb24uaWQsIHBhcmVudCwgaXNUeXBlVmFyaWFibGVEZWNsKVxuICAgICAgICAgIH1cbiAgICAgICAgfVxuXG4gICAgICAgIGlmIChub2RlLmRlY2xhcmF0aW9uLmRlY2xhcmF0aW9ucyAhPSBudWxsKSB7XG4gICAgICAgICAgZm9yIChsZXQgZGVjbGFyYXRpb24gb2Ygbm9kZS5kZWNsYXJhdGlvbi5kZWNsYXJhdGlvbnMpIHtcbiAgICAgICAgICAgIHJlY3Vyc2l2ZVBhdHRlcm5DYXB0dXJlKGRlY2xhcmF0aW9uLmlkLCB2ID0+XG4gICAgICAgICAgICAgIGFkZE5hbWVkKHYubmFtZSwgdiwgcGFyZW50LCBpc1R5cGVWYXJpYWJsZURlY2wpKVxuICAgICAgICAgIH1cbiAgICAgICAgfVxuICAgICAgfSxcblxuICAgICAgJ0V4cG9ydEFsbERlY2xhcmF0aW9uJzogZnVuY3Rpb24gKG5vZGUpIHtcbiAgICAgICAgaWYgKG5vZGUuc291cmNlID09IG51bGwpIHJldHVybiAvLyBub3Qgc3VyZSBpZiB0aGlzIGlzIGV2ZXIgdHJ1ZVxuXG4gICAgICAgIC8vIGBleHBvcnQgKiBhcyBYIGZyb20gJ3BhdGgnYCBkb2VzIG5vdCBjb25mbGljdFxuICAgICAgICBpZiAobm9kZS5leHBvcnRlZCAmJiBub2RlLmV4cG9ydGVkLm5hbWUpIHJldHVyblxuXG4gICAgICAgIGNvbnN0IHJlbW90ZUV4cG9ydHMgPSBFeHBvcnRNYXAuZ2V0KG5vZGUuc291cmNlLnZhbHVlLCBjb250ZXh0KVxuICAgICAgICBpZiAocmVtb3RlRXhwb3J0cyA9PSBudWxsKSByZXR1cm5cblxuICAgICAgICBpZiAocmVtb3RlRXhwb3J0cy5lcnJvcnMubGVuZ3RoKSB7XG4gICAgICAgICAgcmVtb3RlRXhwb3J0cy5yZXBvcnRFcnJvcnMoY29udGV4dCwgbm9kZSlcbiAgICAgICAgICByZXR1cm5cbiAgICAgICAgfVxuXG4gICAgICAgIGNvbnN0IHBhcmVudCA9IGdldFBhcmVudChub2RlKVxuXG4gICAgICAgIGxldCBhbnkgPSBmYWxzZVxuICAgICAgICByZW1vdGVFeHBvcnRzLmZvckVhY2goKHYsIG5hbWUpID0+XG4gICAgICAgICAgbmFtZSAhPT0gJ2RlZmF1bHQnICYmXG4gICAgICAgICAgKGFueSA9IHRydWUpICYmIC8vIHBvb3IgbWFuJ3MgZmlsdGVyXG4gICAgICAgICAgYWRkTmFtZWQobmFtZSwgbm9kZSwgcGFyZW50KSlcblxuICAgICAgICBpZiAoIWFueSkge1xuICAgICAgICAgIGNvbnRleHQucmVwb3J0KFxuICAgICAgICAgICAgbm9kZS5zb3VyY2UsXG4gICAgICAgICAgICBgTm8gbmFtZWQgZXhwb3J0cyBmb3VuZCBpbiBtb2R1bGUgJyR7bm9kZS5zb3VyY2UudmFsdWV9Jy5gXG4gICAgICAgICAgKVxuICAgICAgICB9XG4gICAgICB9LFxuXG4gICAgICAnUHJvZ3JhbTpleGl0JzogZnVuY3Rpb24gKCkge1xuICAgICAgICBmb3IgKGxldCBbLCBuYW1lZF0gb2YgbmFtZXNwYWNlKSB7XG4gICAgICAgICAgZm9yIChsZXQgW25hbWUsIG5vZGVzXSBvZiBuYW1lZCkge1xuICAgICAgICAgICAgaWYgKG5vZGVzLnNpemUgPD0gMSkgY29udGludWVcblxuICAgICAgICAgICAgaWYgKGlzVHlwZXNjcmlwdEZ1bmN0aW9uT3ZlcmxvYWRzKG5vZGVzKSkgY29udGludWVcblxuICAgICAgICAgICAgZm9yIChsZXQgbm9kZSBvZiBub2Rlcykge1xuICAgICAgICAgICAgICBpZiAobmFtZSA9PT0gJ2RlZmF1bHQnKSB7XG4gICAgICAgICAgICAgICAgY29udGV4dC5yZXBvcnQobm9kZSwgJ011bHRpcGxlIGRlZmF1bHQgZXhwb3J0cy4nKVxuICAgICAgICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgICAgICAgIGNvbnRleHQucmVwb3J0KFxuICAgICAgICAgICAgICAgICAgbm9kZSxcbiAgICAgICAgICAgICAgICAgIGBNdWx0aXBsZSBleHBvcnRzIG9mIG5hbWUgJyR7bmFtZS5yZXBsYWNlKHRzVHlwZVByZWZpeCwgJycpfScuYFxuICAgICAgICAgICAgICAgIClcbiAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgfVxuICAgICAgICAgIH1cbiAgICAgICAgfVxuICAgICAgfSxcbiAgICB9XG4gIH0sXG59XG4iXX0=