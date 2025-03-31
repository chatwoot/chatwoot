'use strict';var _slicedToArray = function () {function sliceIterator(arr, i) {var _arr = [];var _n = true;var _d = false;var _e = undefined;try {for (var _i = arr[Symbol.iterator](), _s; !(_n = (_s = _i.next()).done); _n = true) {_arr.push(_s.value);if (i && _arr.length === i) break;}} catch (err) {_d = true;_e = err;} finally {try {if (!_n && _i["return"]) _i["return"]();} finally {if (_d) throw _e;}}return _arr;}return function (arr, i) {if (Array.isArray(arr)) {return arr;} else if (Symbol.iterator in Object(arr)) {return sliceIterator(arr, i);} else {throw new TypeError("Invalid attempt to destructure non-iterable instance");}};}();var _builder = require('../exportMap/builder');var _builder2 = _interopRequireDefault(_builder);
var _patternCapture = require('../exportMap/patternCapture');var _patternCapture2 = _interopRequireDefault(_patternCapture);
var _docsUrl = require('../docsUrl');var _docsUrl2 = _interopRequireDefault(_docsUrl);
var _arrayIncludes = require('array-includes');var _arrayIncludes2 = _interopRequireDefault(_arrayIncludes);
var _arrayPrototype = require('array.prototype.flatmap');var _arrayPrototype2 = _interopRequireDefault(_arrayPrototype);function _interopRequireDefault(obj) {return obj && obj.__esModule ? obj : { 'default': obj };}

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

var rootProgram = 'root';
var tsTypePrefix = 'type:';

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
  var nodesArr = Array.from(nodes);

  var idents = (0, _arrayPrototype2['default'])(
  nodesArr,
  function (node) {return node.declaration && (
    node.declaration.type === 'TSDeclareFunction' // eslint 6+
    || node.declaration.type === 'TSEmptyBodyFunctionDeclaration' // eslint 4-5
    ) ?
    node.declaration.id.name :
    [];});

  if (new Set(idents).size !== idents.length) {
    return true;
  }

  var types = new Set(nodesArr.map(function (node) {return node.parent.type;}));
  if (!types.has('TSDeclareFunction')) {
    return false;
  }
  if (types.size === 1) {
    return true;
  }
  if (types.size === 2 && types.has('FunctionDeclaration')) {
    return true;
  }
  return false;
}

/**
   * Detect merging Namespaces with Classes, Functions, or Enums like:
   * ```ts
   * export class Foo { }
   * export namespace Foo { }
   * ```
   * @param {Set<Object>} nodes
   * @returns {boolean}
   */
function isTypescriptNamespaceMerging(nodes) {
  var types = new Set(Array.from(nodes, function (node) {return node.parent.type;}));
  var noNamespaceNodes = Array.from(nodes).filter(function (node) {return node.parent.type !== 'TSModuleDeclaration';});

  return types.has('TSModuleDeclaration') && (

  types.size === 1
  // Merging with functions
  || types.size === 2 && (types.has('FunctionDeclaration') || types.has('TSDeclareFunction')) ||
  types.size === 3 && types.has('FunctionDeclaration') && types.has('TSDeclareFunction')
  // Merging with classes or enums
  || types.size === 2 && (types.has('ClassDeclaration') || types.has('TSEnumDeclaration')) && noNamespaceNodes.length === 1);

}

/**
   * Detect if a typescript namespace node should be reported as multiple export:
   * ```ts
   * export class Foo { }
   * export function Foo();
   * export namespace Foo { }
   * ```
   * @param {Object} node
   * @param {Set<Object>} nodes
   * @returns {boolean}
   */
function shouldSkipTypescriptNamespace(node, nodes) {
  var types = new Set(Array.from(nodes, function (node) {return node.parent.type;}));

  return !isTypescriptNamespaceMerging(nodes) &&
  node.parent.type === 'TSModuleDeclaration' && (

  types.has('TSEnumDeclaration') ||
  types.has('ClassDeclaration') ||
  types.has('FunctionDeclaration') ||
  types.has('TSDeclareFunction'));

}

module.exports = {
  meta: {
    type: 'problem',
    docs: {
      category: 'Helpful warnings',
      description: 'Forbid any invalid exports, i.e. re-export of the same name.',
      url: (0, _docsUrl2['default'])('export') },

    schema: [] },


  create: function () {function create(context) {
      var namespace = new Map([[rootProgram, new Map()]]);

      function addNamed(name, node, parent, isType) {
        if (!namespace.has(parent)) {
          namespace.set(parent, new Map());
        }
        var named = namespace.get(parent);

        var key = isType ? '' + tsTypePrefix + String(name) : name;
        var nodes = named.get(key);

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
        ExportDefaultDeclaration: function () {function ExportDefaultDeclaration(node) {
            addNamed('default', node, getParent(node));
          }return ExportDefaultDeclaration;}(),

        ExportSpecifier: function () {function ExportSpecifier(node) {
            addNamed(
            node.exported.name || node.exported.value,
            node.exported,
            getParent(node.parent));

          }return ExportSpecifier;}(),

        ExportNamedDeclaration: function () {function ExportNamedDeclaration(node) {
            if (node.declaration == null) {return;}

            var parent = getParent(node);
            // support for old TypeScript versions
            var isTypeVariableDecl = node.declaration.kind === 'type';

            if (node.declaration.id != null) {
              if ((0, _arrayIncludes2['default'])([
              'TSTypeAliasDeclaration',
              'TSInterfaceDeclaration'],
              node.declaration.type)) {
                addNamed(node.declaration.id.name, node.declaration.id, parent, true);
              } else {
                addNamed(node.declaration.id.name, node.declaration.id, parent, isTypeVariableDecl);
              }
            }

            if (node.declaration.declarations != null) {var _iteratorNormalCompletion = true;var _didIteratorError = false;var _iteratorError = undefined;try {
                for (var _iterator = node.declaration.declarations[Symbol.iterator](), _step; !(_iteratorNormalCompletion = (_step = _iterator.next()).done); _iteratorNormalCompletion = true) {var declaration = _step.value;
                  (0, _patternCapture2['default'])(declaration.id, function (v) {addNamed(v.name, v, parent, isTypeVariableDecl);});
                }} catch (err) {_didIteratorError = true;_iteratorError = err;} finally {try {if (!_iteratorNormalCompletion && _iterator['return']) {_iterator['return']();}} finally {if (_didIteratorError) {throw _iteratorError;}}}
            }
          }return ExportNamedDeclaration;}(),

        ExportAllDeclaration: function () {function ExportAllDeclaration(node) {
            if (node.source == null) {return;} // not sure if this is ever true

            // `export * as X from 'path'` does not conflict
            if (node.exported && node.exported.name) {return;}

            var remoteExports = _builder2['default'].get(node.source.value, context);
            if (remoteExports == null) {return;}

            if (remoteExports.errors.length) {
              remoteExports.reportErrors(context, node);
              return;
            }

            var parent = getParent(node);

            var any = false;
            remoteExports.forEach(function (v, name) {
              if (name !== 'default') {
                any = true; // poor man's filter
                addNamed(name, node, parent);
              }
            });

            if (!any) {
              context.report(
              node.source, 'No named exports found in module \'' + String(
              node.source.value) + '\'.');

            }
          }return ExportAllDeclaration;}(),

        'Program:exit': function () {function ProgramExit() {var _iteratorNormalCompletion2 = true;var _didIteratorError2 = false;var _iteratorError2 = undefined;try {
              for (var _iterator2 = namespace[Symbol.iterator](), _step2; !(_iteratorNormalCompletion2 = (_step2 = _iterator2.next()).done); _iteratorNormalCompletion2 = true) {var _ref = _step2.value;var _ref2 = _slicedToArray(_ref, 2);var named = _ref2[1];var _iteratorNormalCompletion3 = true;var _didIteratorError3 = false;var _iteratorError3 = undefined;try {
                  for (var _iterator3 = named[Symbol.iterator](), _step3; !(_iteratorNormalCompletion3 = (_step3 = _iterator3.next()).done); _iteratorNormalCompletion3 = true) {var _ref3 = _step3.value;var _ref4 = _slicedToArray(_ref3, 2);var name = _ref4[0];var nodes = _ref4[1];
                    if (nodes.size <= 1) {continue;}

                    if (isTypescriptFunctionOverloads(nodes) || isTypescriptNamespaceMerging(nodes)) {continue;}var _iteratorNormalCompletion4 = true;var _didIteratorError4 = false;var _iteratorError4 = undefined;try {

                      for (var _iterator4 = nodes[Symbol.iterator](), _step4; !(_iteratorNormalCompletion4 = (_step4 = _iterator4.next()).done); _iteratorNormalCompletion4 = true) {var node = _step4.value;
                        if (shouldSkipTypescriptNamespace(node, nodes)) {continue;}

                        if (name === 'default') {
                          context.report(node, 'Multiple default exports.');
                        } else {
                          context.report(
                          node, 'Multiple exports of name \'' + String(
                          name.replace(tsTypePrefix, '')) + '\'.');

                        }
                      }} catch (err) {_didIteratorError4 = true;_iteratorError4 = err;} finally {try {if (!_iteratorNormalCompletion4 && _iterator4['return']) {_iterator4['return']();}} finally {if (_didIteratorError4) {throw _iteratorError4;}}}
                  }} catch (err) {_didIteratorError3 = true;_iteratorError3 = err;} finally {try {if (!_iteratorNormalCompletion3 && _iterator3['return']) {_iterator3['return']();}} finally {if (_didIteratorError3) {throw _iteratorError3;}}}
              }} catch (err) {_didIteratorError2 = true;_iteratorError2 = err;} finally {try {if (!_iteratorNormalCompletion2 && _iterator2['return']) {_iterator2['return']();}} finally {if (_didIteratorError2) {throw _iteratorError2;}}}
          }return ProgramExit;}() };

    }return create;}() };
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIi4uLy4uL3NyYy9ydWxlcy9leHBvcnQuanMiXSwibmFtZXMiOlsicm9vdFByb2dyYW0iLCJ0c1R5cGVQcmVmaXgiLCJpc1R5cGVzY3JpcHRGdW5jdGlvbk92ZXJsb2FkcyIsIm5vZGVzIiwibm9kZXNBcnIiLCJBcnJheSIsImZyb20iLCJpZGVudHMiLCJub2RlIiwiZGVjbGFyYXRpb24iLCJ0eXBlIiwiaWQiLCJuYW1lIiwiU2V0Iiwic2l6ZSIsImxlbmd0aCIsInR5cGVzIiwibWFwIiwicGFyZW50IiwiaGFzIiwiaXNUeXBlc2NyaXB0TmFtZXNwYWNlTWVyZ2luZyIsIm5vTmFtZXNwYWNlTm9kZXMiLCJmaWx0ZXIiLCJzaG91bGRTa2lwVHlwZXNjcmlwdE5hbWVzcGFjZSIsIm1vZHVsZSIsImV4cG9ydHMiLCJtZXRhIiwiZG9jcyIsImNhdGVnb3J5IiwiZGVzY3JpcHRpb24iLCJ1cmwiLCJzY2hlbWEiLCJjcmVhdGUiLCJjb250ZXh0IiwibmFtZXNwYWNlIiwiTWFwIiwiYWRkTmFtZWQiLCJpc1R5cGUiLCJzZXQiLCJuYW1lZCIsImdldCIsImtleSIsImFkZCIsImdldFBhcmVudCIsIkV4cG9ydERlZmF1bHREZWNsYXJhdGlvbiIsIkV4cG9ydFNwZWNpZmllciIsImV4cG9ydGVkIiwidmFsdWUiLCJFeHBvcnROYW1lZERlY2xhcmF0aW9uIiwiaXNUeXBlVmFyaWFibGVEZWNsIiwia2luZCIsImRlY2xhcmF0aW9ucyIsInYiLCJFeHBvcnRBbGxEZWNsYXJhdGlvbiIsInNvdXJjZSIsInJlbW90ZUV4cG9ydHMiLCJFeHBvcnRNYXBCdWlsZGVyIiwiZXJyb3JzIiwicmVwb3J0RXJyb3JzIiwiYW55IiwiZm9yRWFjaCIsInJlcG9ydCIsInJlcGxhY2UiXSwibWFwcGluZ3MiOiJxb0JBQUEsK0M7QUFDQSw2RDtBQUNBLHFDO0FBQ0EsK0M7QUFDQSx5RDs7QUFFQTs7Ozs7Ozs7Ozs7Ozs7Ozs7OztBQW1CQSxJQUFNQSxjQUFjLE1BQXBCO0FBQ0EsSUFBTUMsZUFB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LHNCQUFNLElBQU4sQ0FEc0IsQ0FDVjtBQUNadkIseUJBQVN4QixJQUFULEVBQWVKLElBQWYsRUFBcUJVLE1BQXJCO0FBQ0Q7QUFDRixhQUxEOztBQU9BLGdCQUFJLENBQUN5QyxHQUFMLEVBQVU7QUFDUjFCLHNCQUFRNEIsTUFBUjtBQUNFckQsbUJBQUs4QyxNQURQO0FBRXVDOUMsbUJBQUs4QyxNQUFMLENBQVlQLEtBRm5EOztBQUlEO0FBQ0YsV0FwRUk7O0FBc0VMLHNCQXRFSyxzQ0FzRVk7QUFDZixvQ0FBd0JiLFNBQXhCLG1JQUFtQyxpRUFBckJLLEtBQXFCO0FBQ2pDLHdDQUE0QkEsS0FBNUIsbUlBQW1DLG1FQUF2QjNCLElBQXVCLGdCQUFqQlQsS0FBaUI7QUFDakMsd0JBQUlBLE1BQU1XLElBQU4sSUFBYyxDQUFsQixFQUFxQixDQUFFLFNBQVc7O0FBRWxDLHdCQUFJWiw4QkFBOEJDLEtBQTlCLEtBQXdDaUIsNkJBQTZCakIsS0FBN0IsQ0FBNUMsRUFBaUYsQ0FBRSxTQUFXLENBSDdEOztBQUtqQyw0Q0FBbUJBLEtBQW5CLG1JQUEwQixLQUFmSyxJQUFlO0FBQ3hCLDRCQUFJZSw4QkFBOEJmLElBQTlCLEVBQW9DTCxLQUFwQyxDQUFKLEVBQWdELENBQUUsU0FBVzs7QUFFN0QsNEJBQUlTLFNBQVMsU0FBYixFQUF3QjtBQUN0QnFCLGtDQUFRNEIsTUFBUixDQUFlckQsSUFBZixFQUFxQiwyQkFBckI7QUFDRCx5QkFGRCxNQUVPO0FBQ0x5QixrQ0FBUTRCLE1BQVI7QUFDRXJELDhCQURGO0FBRStCSSwrQkFBS2tELE9BQUwsQ0FBYTdELFlBQWIsRUFBMkIsRUFBM0IsQ0FGL0I7O0FBSUQ7QUFDRix1QkFoQmdDO0FBaUJsQyxtQkFsQmdDO0FBbUJsQyxlQXBCYztBQXFCaEIsV0EzRkksd0JBQVA7O0FBNkZELEtBdEljLG1CQUFqQiIsImZpbGUiOiJleHBvcnQuanMiLCJzb3VyY2VzQ29udGVudCI6WyJpbXBvcnQgRXhwb3J0TWFwQnVpbGRlciBmcm9tICcuLi9leHBvcnRNYXAvYnVpbGRlcic7XG5pbXBvcnQgcmVjdXJzaXZlUGF0dGVybkNhcHR1cmUgZnJvbSAnLi4vZXhwb3J0TWFwL3BhdHRlcm5DYXB0dXJlJztcbmltcG9ydCBkb2NzVXJsIGZyb20gJy4uL2RvY3NVcmwnO1xuaW1wb3J0IGluY2x1ZGVzIGZyb20gJ2FycmF5LWluY2x1ZGVzJztcbmltcG9ydCBmbGF0TWFwIGZyb20gJ2FycmF5LnByb3RvdHlwZS5mbGF0bWFwJztcblxuLypcbk5vdGVzIG9uIFR5cGVTY3JpcHQgbmFtZXNwYWNlcyBha2EgVFNNb2R1bGVEZWNsYXJhdGlvbjpcblxuVGhlcmUgYXJlIHR3byBmb3Jtczpcbi0gYWN0aXZlIG5hbWVzcGFjZXM6IG5hbWVzcGFjZSBGb28ge30gLyBtb2R1bGUgRm9vIHt9XG4tIGFtYmllbnQgbW9kdWxlczsgZGVjbGFyZSBtb2R1bGUgXCJlc2xpbnQtcGx1Z2luLWltcG9ydFwiIHt9XG5cbmFjdGl2ZSBuYW1lc3BhY2VzOlxuLSBjYW5ub3QgY29udGFpbiBhIGRlZmF1bHQgZXhwb3J0XG4tIGNhbm5vdCBjb250YWluIGFuIGV4cG9ydCBhbGxcbi0gY2Fubm90IGNvbnRhaW4gYSBtdWx0aSBuYW1lIGV4cG9ydCAoZXhwb3J0IHsgYSwgYiB9KVxuLSBjYW4gaGF2ZSBhY3RpdmUgbmFtZXNwYWNlcyBuZXN0ZWQgd2l0aGluIHRoZW1cblxuYW1iaWVudCBuYW1lc3BhY2VzOlxuLSBjYW4gb25seSBiZSBkZWZpbmVkIGluIC5kLnRzIGZpbGVzXG4tIGNhbm5vdCBiZSBuZXN0ZWQgd2l0aGluIGFjdGl2ZSBuYW1lc3BhY2VzXG4tIGhhdmUgbm8gb3RoZXIgcmVzdHJpY3Rpb25zXG4qL1xuXG5jb25zdCByb290UHJvZ3JhbSA9ICdyb290JztcbmNvbnN0IHRzVHlwZVByZWZpeCA9ICd0eXBlOic7XG5cbi8qKlxuICogRGV0ZWN0IGZ1bmN0aW9uIG92ZXJsb2FkcyBsaWtlOlxuICogYGBgdHNcbiAqIGV4cG9ydCBmdW5jdGlvbiBmb28oYTogbnVtYmVyKTtcbiAqIGV4cG9ydCBmdW5jdGlvbiBmb28oYTogc3RyaW5nKTtcbiAqIGV4cG9ydCBmdW5jdGlvbiBmb28oYTogbnVtYmVyfHN0cmluZykgeyByZXR1cm4gYTsgfVxuICogYGBgXG4gKiBAcGFyYW0ge1NldDxPYmplY3Q+fSBub2Rlc1xuICogQHJldHVybnMge2Jvb2xlYW59XG4gKi9cbmZ1bmN0aW9uIGlzVHlwZXNjcmlwdEZ1bmN0aW9uT3ZlcmxvYWRzKG5vZGVzKSB7XG4gIGNvbnN0IG5vZGVzQXJyID0gQXJyYXkuZnJvbShub2Rlcyk7XG5cbiAgY29uc3QgaWRlbnRzID0gZmxhdE1hcChcbiAgICBub2Rlc0FycixcbiAgICAobm9kZSkgPT4gbm9kZS5kZWNsYXJhdGlvbiAmJiAoXG4gICAgICBub2RlLmRlY2xhcmF0aW9uLnR5cGUgPT09ICdUU0RlY2xhcmVGdW5jdGlvbicgLy8gZXNsaW50IDYrXG4gICAgICB8fCBub2RlLmRlY2xhcmF0aW9uLnR5cGUgPT09ICdUU0VtcHR5Qm9keUZ1bmN0aW9uRGVjbGFyYXRpb24nIC8vIGVzbGludCA0LTVcbiAgICApXG4gICAgICA/IG5vZGUuZGVjbGFyYXRpb24uaWQubmFtZVxuICAgICAgOiBbXSxcbiAgKTtcbiAgaWYgKG5ldyBTZXQoaWRlbnRzKS5zaXplICE9PSBpZGVudHMubGVuZ3RoKSB7XG4gICAgcmV0dXJuIHRydWU7XG4gIH1cblxuICBjb25zdCB0eXBlcyA9IG5ldyBTZXQobm9kZXNBcnIubWFwKChub2RlKSA9PiBub2RlLnBhcmVudC50eXBlKSk7XG4gIGlmICghdHlwZXMuaGFzKCdUU0RlY2xhcmVGdW5jdGlvbicpKSB7XG4gICAgcmV0dXJuIGZhbHNlO1xuICB9XG4gIGlmICh0eXBlcy5zaXplID09PSAxKSB7XG4gICAgcmV0dXJuIHRydWU7XG4gIH1cbiAgaWYgKHR5cGVzLnNpemUgPT09IDIgJiYgdHlwZXMuaGFzKCdGdW5jdGlvbkRlY2xhcmF0aW9uJykpIHtcbiAgICByZXR1cm4gdHJ1ZTtcbiAgfVxuICByZXR1cm4gZmFsc2U7XG59XG5cbi8qKlxuICogRGV0ZWN0IG1lcmdpbmcgTmFtZXNwYWNlcyB3aXRoIENsYXNzZXMsIEZ1bmN0aW9ucywgb3IgRW51bXMgbGlrZTpcbiAqIGBgYHRzXG4gKiBleHBvcnQgY2xhc3MgRm9vIHsgfVxuICogZXhwb3J0IG5hbWVzcGFjZSBGb28geyB9XG4gKiBgYGBcbiAqIEBwYXJhbSB7U2V0PE9iamVjdD59IG5vZGVzXG4gKiBAcmV0dXJucyB7Ym9vbGVhbn1cbiAqL1xuZnVuY3Rpb24gaXNUeXBlc2NyaXB0TmFtZXNwYWNlTWVyZ2luZyhub2Rlcykge1xuICBjb25zdCB0eXBlcyA9IG5ldyBTZXQoQXJyYXkuZnJvbShub2RlcywgKG5vZGUpID0+IG5vZGUucGFyZW50LnR5cGUpKTtcbiAgY29uc3Qgbm9OYW1lc3BhY2VOb2RlcyA9IEFycmF5LmZyb20obm9kZXMpLmZpbHRlcigobm9kZSkgPT4gbm9kZS5wYXJlbnQudHlwZSAhPT0gJ1RTTW9kdWxlRGVjbGFyYXRpb24nKTtcblxuICByZXR1cm4gdHlwZXMuaGFzKCdUU01vZHVsZURlY2xhcmF0aW9uJylcbiAgICAmJiAoXG4gICAgICB0eXBlcy5zaXplID09PSAxXG4gICAgICAvLyBNZXJnaW5nIHdpdGggZnVuY3Rpb25zXG4gICAgICB8fCB0eXBlcy5zaXplID09PSAyICYmICh0eXBlcy5oYXMoJ0Z1bmN0aW9uRGVjbGFyYXRpb24nKSB8fCB0eXBlcy5oYXMoJ1RTRGVjbGFyZUZ1bmN0aW9uJykpXG4gICAgICB8fCB0eXBlcy5zaXplID09PSAzICYmIHR5cGVzLmhhcygnRnVuY3Rpb25EZWNsYXJhdGlvbicpICYmIHR5cGVzLmhhcygnVFNEZWNsYXJlRnVuY3Rpb24nKVxuICAgICAgLy8gTWVyZ2luZyB3aXRoIGNsYXNzZXMgb3IgZW51bXNcbiAgICAgIHx8IHR5cGVzLnNpemUgPT09IDIgJiYgKHR5cGVzLmhhcygnQ2xhc3NEZWNsYXJhdGlvbicpIHx8IHR5cGVzLmhhcygnVFNFbnVtRGVjbGFyYXRpb24nKSkgJiYgbm9OYW1lc3BhY2VOb2Rlcy5sZW5ndGggPT09IDFcbiAgICApO1xufVxuXG4vKipcbiAqIERldGVjdCBpZiBhIHR5cGVzY3JpcHQgbmFtZXNwYWNlIG5vZGUgc2hvdWxkIGJlIHJlcG9ydGVkIGFzIG11bHRpcGxlIGV4cG9ydDpcbiAqIGBgYHRzXG4gKiBleHBvcnQgY2xhc3MgRm9vIHsgfVxuICogZXhwb3J0IGZ1bmN0aW9uIEZvbygpO1xuICogZXhwb3J0IG5hbWVzcGFjZSBGb28geyB9XG4gKiBgYGBcbiAqIEBwYXJhbSB7T2JqZWN0fSBub2RlXG4gKiBAcGFyYW0ge1NldDxPYmplY3Q+fSBub2Rlc1xuICogQHJldHVybnMge2Jvb2xlYW59XG4gKi9cbmZ1bmN0aW9uIHNob3VsZFNraXBUeXBlc2NyaXB0TmFtZXNwYWNlKG5vZGUsIG5vZGVzKSB7XG4gIGNvbnN0IHR5cGVzID0gbmV3IFNldChBcnJheS5mcm9tKG5vZGVzLCAobm9kZSkgPT4gbm9kZS5wYXJlbnQudHlwZSkpO1xuXG4gIHJldHVybiAhaXNUeXBlc2NyaXB0TmFtZXNwYWNlTWVyZ2luZyhub2RlcylcbiAgICAmJiBub2RlLnBhcmVudC50eXBlID09PSAnVFNNb2R1bGVEZWNsYXJhdGlvbidcbiAgICAmJiAoXG4gICAgICB0eXBlcy5oYXMoJ1RTRW51bURlY2xhcmF0aW9uJylcbiAgICAgIHx8IHR5cGVzLmhhcygnQ2xhc3NEZWNsYXJhdGlvbicpXG4gICAgICB8fCB0eXBlcy5oYXMoJ0Z1bmN0aW9uRGVjbGFyYXRpb24nKVxuICAgICAgfHwgdHlwZXMuaGFzKCdUU0RlY2xhcmVGdW5jdGlvbicpXG4gICAgKTtcbn1cblxubW9kdWxlLmV4cG9ydHMgPSB7XG4gIG1ldGE6IHtcbiAgICB0eXBlOiAncHJvYmxlbScsXG4gICAgZG9jczoge1xuICAgICAgY2F0ZWdvcnk6ICdIZWxwZnVsIHdhcm5pbmdzJyxcbiAgICAgIGRlc2NyaXB0aW9uOiAnRm9yYmlkIGFueSBpbnZhbGlkIGV4cG9ydHMsIGkuZS4gcmUtZXhwb3J0IG9mIHRoZSBzYW1lIG5hbWUuJyxcbiAgICAgIHVybDogZG9jc1VybCgnZXhwb3J0JyksXG4gICAgfSxcbiAgICBzY2hlbWE6IFtdLFxuICB9LFxuXG4gIGNyZWF0ZShjb250ZXh0KSB7XG4gICAgY29uc3QgbmFtZXNwYWNlID0gbmV3IE1hcChbW3Jvb3RQcm9ncmFtLCBuZXcgTWFwKCldXSk7XG5cbiAgICBmdW5jdGlvbiBhZGROYW1lZChuYW1lLCBub2RlLCBwYXJlbnQsIGlzVHlwZSkge1xuICAgICAgaWYgKCFuYW1lc3BhY2UuaGFzKHBhcmVudCkpIHtcbiAgICAgICAgbmFtZXNwYWNlLnNldChwYXJlbnQsIG5ldyBNYXAoKSk7XG4gICAgICB9XG4gICAgICBjb25zdCBuYW1lZCA9IG5hbWVzcGFjZS5nZXQocGFyZW50KTtcblxuICAgICAgY29uc3Qga2V5ID0gaXNUeXBlID8gYCR7dHNUeXBlUHJlZml4fSR7bmFtZX1gIDogbmFtZTtcbiAgICAgIGxldCBub2RlcyA9IG5hbWVkLmdldChrZXkpO1xuXG4gICAgICBpZiAobm9kZXMgPT0gbnVsbCkge1xuICAgICAgICBub2RlcyA9IG5ldyBTZXQoKTtcbiAgICAgICAgbmFtZWQuc2V0KGtleSwgbm9kZXMpO1xuICAgICAgfVxuXG4gICAgICBub2Rlcy5hZGQobm9kZSk7XG4gICAgfVxuXG4gICAgZnVuY3Rpb24gZ2V0UGFyZW50KG5vZGUpIHtcbiAgICAgIGlmIChub2RlLnBhcmVudCAmJiBub2RlLnBhcmVudC50eXBlID09PSAnVFNNb2R1bGVCbG9jaycpIHtcbiAgICAgICAgcmV0dXJuIG5vZGUucGFyZW50LnBhcmVudDtcbiAgICAgIH1cblxuICAgICAgLy8ganVzdCBpbiBjYXNlIHNvbWVob3cgYSBub24tdHMgbmFtZXNwYWNlIGV4cG9ydCBkZWNsYXJhdGlvbiBpc24ndCBkaXJlY3RseVxuICAgICAgLy8gcGFyZW50ZWQgdG8gdGhlIHJvb3QgUHJvZ3JhbSBub2RlXG4gICAgICByZXR1cm4gcm9vdFByb2dyYW07XG4gICAgfVxuXG4gICAgcmV0dXJuIHtcbiAgICAgIEV4cG9ydERlZmF1bHREZWNsYXJhdGlvbihub2RlKSB7XG4gICAgICAgIGFkZE5hbWVkKCdkZWZhdWx0Jywgbm9kZSwgZ2V0UGFyZW50KG5vZGUpKTtcbiAgICAgIH0sXG5cbiAgICAgIEV4cG9ydFNwZWNpZmllcihub2RlKSB7XG4gICAgICAgIGFkZE5hbWVkKFxuICAgICAgICAgIG5vZGUuZXhwb3J0ZWQubmFtZSB8fCBub2RlLmV4cG9ydGVkLnZhbHVlLFxuICAgICAgICAgIG5vZGUuZXhwb3J0ZWQsXG4gICAgICAgICAgZ2V0UGFyZW50KG5vZGUucGFyZW50KSxcbiAgICAgICAgKTtcbiAgICAgIH0sXG5cbiAgICAgIEV4cG9ydE5hbWVkRGVjbGFyYXRpb24obm9kZSkge1xuICAgICAgICBpZiAobm9kZS5kZWNsYXJhdGlvbiA9PSBudWxsKSB7IHJldHVybjsgfVxuXG4gICAgICAgIGNvbnN0IHBhcmVudCA9IGdldFBhcmVudChub2RlKTtcbiAgICAgICAgLy8gc3VwcG9ydCBmb3Igb2xkIFR5cGVTY3JpcHQgdmVyc2lvbnNcbiAgICAgICAgY29uc3QgaXNUeXBlVmFyaWFibGVEZWNsID0gbm9kZS5kZWNsYXJhdGlvbi5raW5kID09PSAndHlwZSc7XG5cbiAgICAgICAgaWYgKG5vZGUuZGVjbGFyYXRpb24uaWQgIT0gbnVsbCkge1xuICAgICAgICAgIGlmIChpbmNsdWRlcyhbXG4gICAgICAgICAgICAnVFNUeXBlQWxpYXNEZWNsYXJhdGlvbicsXG4gICAgICAgICAgICAnVFNJbnRlcmZhY2VEZWNsYXJhdGlvbicsXG4gICAgICAgICAgXSwgbm9kZS5kZWNsYXJhdGlvbi50eXBlKSkge1xuICAgICAgICAgICAgYWRkTmFtZWQobm9kZS5kZWNsYXJhdGlvbi5pZC5uYW1lLCBub2RlLmRlY2xhcmF0aW9uLmlkLCBwYXJlbnQsIHRydWUpO1xuICAgICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgICBhZGROYW1lZChub2RlLmRlY2xhcmF0aW9uLmlkLm5hbWUsIG5vZGUuZGVjbGFyYXRpb24uaWQsIHBhcmVudCwgaXNUeXBlVmFyaWFibGVEZWNsKTtcbiAgICAgICAgICB9XG4gICAgICAgIH1cblxuICAgICAgICBpZiAobm9kZS5kZWNsYXJhdGlvbi5kZWNsYXJhdGlvbnMgIT0gbnVsbCkge1xuICAgICAgICAgIGZvciAoY29uc3QgZGVjbGFyYXRpb24gb2Ygbm9kZS5kZWNsYXJhdGlvbi5kZWNsYXJhdGlvbnMpIHtcbiAgICAgICAgICAgIHJlY3Vyc2l2ZVBhdHRlcm5DYXB0dXJlKGRlY2xhcmF0aW9uLmlkLCAodikgPT4geyBhZGROYW1lZCh2Lm5hbWUsIHYsIHBhcmVudCwgaXNUeXBlVmFyaWFibGVEZWNsKTsgfSk7XG4gICAgICAgICAgfVxuICAgICAgICB9XG4gICAgICB9LFxuXG4gICAgICBFeHBvcnRBbGxEZWNsYXJhdGlvbihub2RlKSB7XG4gICAgICAgIGlmIChub2RlLnNvdXJjZSA9PSBudWxsKSB7IHJldHVybjsgfSAvLyBub3Qgc3VyZSBpZiB0aGlzIGlzIGV2ZXIgdHJ1ZVxuXG4gICAgICAgIC8vIGBleHBvcnQgKiBhcyBYIGZyb20gJ3BhdGgnYCBkb2VzIG5vdCBjb25mbGljdFxuICAgICAgICBpZiAobm9kZS5leHBvcnRlZCAmJiBub2RlLmV4cG9ydGVkLm5hbWUpIHsgcmV0dXJuOyB9XG5cbiAgICAgICAgY29uc3QgcmVtb3RlRXhwb3J0cyA9IEV4cG9ydE1hcEJ1aWxkZXIuZ2V0KG5vZGUuc291cmNlLnZhbHVlLCBjb250ZXh0KTtcbiAgICAgICAgaWYgKHJlbW90ZUV4cG9ydHMgPT0gbnVsbCkgeyByZXR1cm47IH1cblxuICAgICAgICBpZiAocmVtb3RlRXhwb3J0cy5lcnJvcnMubGVuZ3RoKSB7XG4gICAgICAgICAgcmVtb3RlRXhwb3J0cy5yZXBvcnRFcnJvcnMoY29udGV4dCwgbm9kZSk7XG4gICAgICAgICAgcmV0dXJuO1xuICAgICAgICB9XG5cbiAgICAgICAgY29uc3QgcGFyZW50ID0gZ2V0UGFyZW50KG5vZGUpO1xuXG4gICAgICAgIGxldCBhbnkgPSBmYWxzZTtcbiAgICAgICAgcmVtb3RlRXhwb3J0cy5mb3JFYWNoKCh2LCBuYW1lKSA9PiB7XG4gICAgICAgICAgaWYgKG5hbWUgIT09ICdkZWZhdWx0Jykge1xuICAgICAgICAgICAgYW55ID0gdHJ1ZTsgLy8gcG9vciBtYW4ncyBmaWx0ZXJcbiAgICAgICAgICAgIGFkZE5hbWVkKG5hbWUsIG5vZGUsIHBhcmVudCk7XG4gICAgICAgICAgfVxuICAgICAgICB9KTtcblxuICAgICAgICBpZiAoIWFueSkge1xuICAgICAgICAgIGNvbnRleHQucmVwb3J0KFxuICAgICAgICAgICAgbm9kZS5zb3VyY2UsXG4gICAgICAgICAgICBgTm8gbmFtZWQgZXhwb3J0cyBmb3VuZCBpbiBtb2R1bGUgJyR7bm9kZS5zb3VyY2UudmFsdWV9Jy5gLFxuICAgICAgICAgICk7XG4gICAgICAgIH1cbiAgICAgIH0sXG5cbiAgICAgICdQcm9ncmFtOmV4aXQnKCkge1xuICAgICAgICBmb3IgKGNvbnN0IFssIG5hbWVkXSBvZiBuYW1lc3BhY2UpIHtcbiAgICAgICAgICBmb3IgKGNvbnN0IFtuYW1lLCBub2Rlc10gb2YgbmFtZWQpIHtcbiAgICAgICAgICAgIGlmIChub2Rlcy5zaXplIDw9IDEpIHsgY29udGludWU7IH1cblxuICAgICAgICAgICAgaWYgKGlzVHlwZXNjcmlwdEZ1bmN0aW9uT3ZlcmxvYWRzKG5vZGVzKSB8fCBpc1R5cGVzY3JpcHROYW1lc3BhY2VNZXJnaW5nKG5vZGVzKSkgeyBjb250aW51ZTsgfVxuXG4gICAgICAgICAgICBmb3IgKGNvbnN0IG5vZGUgb2Ygbm9kZXMpIHtcbiAgICAgICAgICAgICAgaWYgKHNob3VsZFNraXBUeXBlc2NyaXB0TmFtZXNwYWNlKG5vZGUsIG5vZGVzKSkgeyBjb250aW51ZTsgfVxuXG4gICAgICAgICAgICAgIGlmIChuYW1lID09PSAnZGVmYXVsdCcpIHtcbiAgICAgICAgICAgICAgICBjb250ZXh0LnJlcG9ydChub2RlLCAnTXVsdGlwbGUgZGVmYXVsdCBleHBvcnRzLicpO1xuICAgICAgICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgICAgICAgIGNvbnRleHQucmVwb3J0KFxuICAgICAgICAgICAgICAgICAgbm9kZSxcbiAgICAgICAgICAgICAgICAgIGBNdWx0aXBsZSBleHBvcnRzIG9mIG5hbWUgJyR7bmFtZS5yZXBsYWNlKHRzVHlwZVByZWZpeCwgJycpfScuYCxcbiAgICAgICAgICAgICAgICApO1xuICAgICAgICAgICAgICB9XG4gICAgICAgICAgICB9XG4gICAgICAgICAgfVxuICAgICAgICB9XG4gICAgICB9LFxuICAgIH07XG4gIH0sXG59O1xuIl19