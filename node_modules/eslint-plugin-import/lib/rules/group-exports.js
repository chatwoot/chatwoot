'use strict';var _docsUrl = require('../docsUrl');var _docsUrl2 = _interopRequireDefault(_docsUrl);
var _object = require('object.values');var _object2 = _interopRequireDefault(_object);
var _arrayPrototype = require('array.prototype.flat');var _arrayPrototype2 = _interopRequireDefault(_arrayPrototype);function _interopRequireDefault(obj) {return obj && obj.__esModule ? obj : { default: obj };}

const meta = {
  type: 'suggestion',
  docs: {
    url: (0, _docsUrl2.default)('group-exports') }


  /* eslint-disable max-len */ };
const errors = {
  ExportNamedDeclaration: 'Multiple named export declarations; consolidate all named exports into a single export declaration',
  AssignmentExpression: 'Multiple CommonJS exports; consolidate all exports into a single assignment to `module.exports`'

  /* eslint-enable max-len */

  /**
                               * Returns an array with names of the properties in the accessor chain for MemberExpression nodes
                               *
                               * Example:
                               *
                               * `module.exports = {}` => ['module', 'exports']
                               * `module.exports.property = true` => ['module', 'exports', 'property']
                               *
                               * @param     {Node}    node    AST Node (MemberExpression)
                               * @return    {Array}           Array with the property names in the chain
                               * @private
                               */ };
function accessorChain(node) {
  const chain = [];

  do {
    chain.unshift(node.property.name);

    if (node.object.type === 'Identifier') {
      chain.unshift(node.object.name);
      break;
    }

    node = node.object;
  } while (node.type === 'MemberExpression');

  return chain;
}

function create(context) {
  const nodes = {
    modules: {
      set: new Set(),
      sources: {} },

    types: {
      set: new Set(),
      sources: {} },

    commonjs: {
      set: new Set() } };



  return {
    ExportNamedDeclaration(node) {
      let target = node.exportKind === 'type' ? nodes.types : nodes.modules;
      if (!node.source) {
        target.set.add(node);
      } else if (Array.isArray(target.sources[node.source.value])) {
        target.sources[node.source.value].push(node);
      } else {
        target.sources[node.source.value] = [node];
      }
    },

    AssignmentExpression(node) {
      if (node.left.type !== 'MemberExpression') {
        return;
      }

      const chain = accessorChain(node.left);

      // Assignments to module.exports
      // Deeper assignments are ignored since they just modify what's already being exported
      // (ie. module.exports.exported.prop = true is ignored)
      if (chain[0] === 'module' && chain[1] === 'exports' && chain.length <= 3) {
        nodes.commonjs.set.add(node);
        return;
      }

      // Assignments to exports (exports.* = *)
      if (chain[0] === 'exports' && chain.length === 2) {
        nodes.commonjs.set.add(node);
        return;
      }
    },

    'Program:exit': function onExit() {
      // Report multiple `export` declarations (ES2015 modules)
      if (nodes.modules.set.size > 1) {
        nodes.modules.set.forEach(node => {
          context.report({
            node,
            message: errors[node.type] });

        });
      }

      // Report multiple `aggregated exports` from the same module (ES2015 modules)
      (0, _arrayPrototype2.default)((0, _object2.default)(nodes.modules.sources).
      filter(nodesWithSource => Array.isArray(nodesWithSource) && nodesWithSource.length > 1)).
      forEach(node => {
        context.report({
          node,
          message: errors[node.type] });

      });

      // Report multiple `export type` declarations (FLOW ES2015 modules)
      if (nodes.types.set.size > 1) {
        nodes.types.set.forEach(node => {
          context.report({
            node,
            message: errors[node.type] });

        });
      }

      // Report multiple `aggregated type exports` from the same module (FLOW ES2015 modules)
      (0, _arrayPrototype2.default)((0, _object2.default)(nodes.types.sources).
      filter(nodesWithSource => Array.isArray(nodesWithSource) && nodesWithSource.length > 1)).
      forEach(node => {
        context.report({
          node,
          message: errors[node.type] });

      });

      // Report multiple `module.exports` assignments (CommonJS)
      if (nodes.commonjs.set.size > 1) {
        nodes.commonjs.set.forEach(node => {
          context.report({
            node,
            message: errors[node.type] });

        });
      }
    } };

}

module.exports = {
  meta,
  create };
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIi4uLy4uL3NyYy9ydWxlcy9ncm91cC1leHBvcnRzLmpzIl0sIm5hbWVzIjpbIm1ldGEiLCJ0eXBlIiwiZG9jcyIsInVybCIsImVycm9ycyIsIkV4cG9ydE5hbWVkRGVjbGFyYXRpb24iLCJBc3NpZ25tZW50RXhwcmVzc2lvbiIsImFjY2Vzc29yQ2hhaW4iLCJub2RlIiwiY2hhaW4iLCJ1bnNoaWZ0IiwicHJvcGVydHkiLCJuYW1lIiwib2JqZWN0IiwiY3JlYXRlIiwiY29udGV4dCIsIm5vZGVzIiwibW9kdWxlcyIsInNldCIsIlNldCIsInNvdXJjZXMiLCJ0eXBlcyIsImNvbW1vbmpzIiwidGFyZ2V0IiwiZXhwb3J0S2luZCIsInNvdXJjZSIsImFkZCIsIkFycmF5IiwiaXNBcnJheSIsInZhbHVlIiwicHVzaCIsImxlZnQiLCJsZW5ndGgiLCJvbkV4aXQiLCJzaXplIiwiZm9yRWFjaCIsInJlcG9ydCIsIm1lc3NhZ2UiLCJmaWx0ZXIiLCJub2Rlc1dpdGhTb3VyY2UiLCJtb2R1bGUiLCJleHBvcnRzIl0sIm1hcHBpbmdzIjoiYUFBQSxxQztBQUNBLHVDO0FBQ0Esc0Q7O0FBRUEsTUFBTUEsT0FBTztBQUNYQyxRQUFNLFlBREs7QUFFWEMsUUFBTTtBQUNKQyxTQUFLLHVCQUFRLGVBQVIsQ0FERDs7O0FBSVIsOEJBTmEsRUFBYjtBQU9BLE1BQU1DLFNBQVM7QUFDYkMsMEJBQXdCLG9HQURYO0FBRWJDLHdCQUFzQjs7QUFFeEI7O0FBRUE7Ozs7Ozs7Ozs7O2lDQU5lLEVBQWY7QUFrQkEsU0FBU0MsYUFBVCxDQUF1QkMsSUFBdkIsRUFBNkI7QUFDM0IsUUFBTUMsUUFBUSxFQUFkOztBQUVBLEtBQUc7QUFDREEsVUFBTUMsT0FBTixDQUFjRixLQUFLRyxRQUFMLENBQWNDLElBQTVCOztBQUVBLFFBQUlKLEtBQUtLLE1BQUwsQ0FBWVosSUFBWixLQUFxQixZQUF6QixFQUF1QztBQUNyQ1EsWUFBTUMsT0FBTixDQUFjRixLQUFLSyxNQUFMLENBQVlELElBQTFCO0FB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QixJQUFoQixHQUF1QixDQUEzQixFQUE4QjtBQUM1QmxCLGNBQU1LLEtBQU4sQ0FBWUgsR0FBWixDQUFnQmlCLE9BQWhCLENBQXdCM0IsUUFBUTtBQUM5Qk8sa0JBQVFxQixNQUFSLENBQWU7QUFDYjVCLGdCQURhO0FBRWI2QixxQkFBU2pDLE9BQU9JLEtBQUtQLElBQVosQ0FGSSxFQUFmOztBQUlELFNBTEQ7QUFNRDs7QUFFRDtBQUNBLG9DQUFLLHNCQUFPZSxNQUFNSyxLQUFOLENBQVlELE9BQW5CO0FBQ0ZrQixZQURFLENBQ0tDLG1CQUFtQlosTUFBTUMsT0FBTixDQUFjVyxlQUFkLEtBQWtDQSxnQkFBZ0JQLE1BQWhCLEdBQXlCLENBRG5GLENBQUw7QUFFR0csYUFGSCxDQUVZM0IsSUFBRCxJQUFVO0FBQ2pCTyxnQkFBUXFCLE1BQVIsQ0FBZTtBQUNiNUIsY0FEYTtBQUViNkIsbUJBQVNqQyxPQUFPSSxLQUFLUCxJQUFaLENBRkksRUFBZjs7QUFJRCxPQVBIOztBQVNBO0FBQ0EsVUFBSWUsTUFBTU0sUUFBTixDQUFlSixHQUFmLENBQW1CZ0IsSUFBbkIsR0FBMEIsQ0FBOUIsRUFBaUM7QUFDL0JsQixjQUFNTSxRQUFOLENBQWVKLEdBQWYsQ0FBbUJpQixPQUFuQixDQUEyQjNCLFFBQVE7QUFDakNPLGtCQUFRcUIsTUFBUixDQUFlO0FBQ2I1QixnQkFEYTtBQUViNkIscUJBQVNqQyxPQUFPSSxLQUFLUCxJQUFaLENBRkksRUFBZjs7QUFJRCxTQUxEO0FBTUQ7QUFDRixLQXBGSSxFQUFQOztBQXNGRDs7QUFFRHVDLE9BQU9DLE9BQVAsR0FBaUI7QUFDZnpDLE1BRGU7QUFFZmMsUUFGZSxFQUFqQiIsImZpbGUiOiJncm91cC1leHBvcnRzLmpzIiwic291cmNlc0NvbnRlbnQiOlsiaW1wb3J0IGRvY3NVcmwgZnJvbSAnLi4vZG9jc1VybCdcbmltcG9ydCB2YWx1ZXMgZnJvbSAnb2JqZWN0LnZhbHVlcydcbmltcG9ydCBmbGF0IGZyb20gJ2FycmF5LnByb3RvdHlwZS5mbGF0J1xuXG5jb25zdCBtZXRhID0ge1xuICB0eXBlOiAnc3VnZ2VzdGlvbicsXG4gIGRvY3M6IHtcbiAgICB1cmw6IGRvY3NVcmwoJ2dyb3VwLWV4cG9ydHMnKSxcbiAgfSxcbn1cbi8qIGVzbGludC1kaXNhYmxlIG1heC1sZW4gKi9cbmNvbnN0IGVycm9ycyA9IHtcbiAgRXhwb3J0TmFtZWREZWNsYXJhdGlvbjogJ011bHRpcGxlIG5hbWVkIGV4cG9ydCBkZWNsYXJhdGlvbnM7IGNvbnNvbGlkYXRlIGFsbCBuYW1lZCBleHBvcnRzIGludG8gYSBzaW5nbGUgZXhwb3J0IGRlY2xhcmF0aW9uJyxcbiAgQXNzaWdubWVudEV4cHJlc3Npb246ICdNdWx0aXBsZSBDb21tb25KUyBleHBvcnRzOyBjb25zb2xpZGF0ZSBhbGwgZXhwb3J0cyBpbnRvIGEgc2luZ2xlIGFzc2lnbm1lbnQgdG8gYG1vZHVsZS5leHBvcnRzYCcsXG59XG4vKiBlc2xpbnQtZW5hYmxlIG1heC1sZW4gKi9cblxuLyoqXG4gKiBSZXR1cm5zIGFuIGFycmF5IHdpdGggbmFtZXMgb2YgdGhlIHByb3BlcnRpZXMgaW4gdGhlIGFjY2Vzc29yIGNoYWluIGZvciBNZW1iZXJFeHByZXNzaW9uIG5vZGVzXG4gKlxuICogRXhhbXBsZTpcbiAqXG4gKiBgbW9kdWxlLmV4cG9ydHMgPSB7fWAgPT4gWydtb2R1bGUnLCAnZXhwb3J0cyddXG4gKiBgbW9kdWxlLmV4cG9ydHMucHJvcGVydHkgPSB0cnVlYCA9PiBbJ21vZHVsZScsICdleHBvcnRzJywgJ3Byb3BlcnR5J11cbiAqXG4gKiBAcGFyYW0gICAgIHtOb2RlfSAgICBub2RlICAgIEFTVCBOb2RlIChNZW1iZXJFeHByZXNzaW9uKVxuICogQHJldHVybiAgICB7QXJyYXl9ICAgICAgICAgICBBcnJheSB3aXRoIHRoZSBwcm9wZXJ0eSBuYW1lcyBpbiB0aGUgY2hhaW5cbiAqIEBwcml2YXRlXG4gKi9cbmZ1bmN0aW9uIGFjY2Vzc29yQ2hhaW4obm9kZSkge1xuICBjb25zdCBjaGFpbiA9IFtdXG5cbiAgZG8ge1xuICAgIGNoYWluLnVuc2hpZnQobm9kZS5wcm9wZXJ0eS5uYW1lKVxuXG4gICAgaWYgKG5vZGUub2JqZWN0LnR5cGUgPT09ICdJZGVudGlmaWVyJykge1xuICAgICAgY2hhaW4udW5zaGlmdChub2RlLm9iamVjdC5uYW1lKVxuICAgICAgYnJlYWtcbiAgICB9XG5cbiAgICBub2RlID0gbm9kZS5vYmplY3RcbiAgfSB3aGlsZSAobm9kZS50eXBlID09PSAnTWVtYmVyRXhwcmVzc2lvbicpXG5cbiAgcmV0dXJuIGNoYWluXG59XG5cbmZ1bmN0aW9uIGNyZWF0ZShjb250ZXh0KSB7XG4gIGNvbnN0IG5vZGVzID0ge1xuICAgIG1vZHVsZXM6IHtcbiAgICAgIHNldDogbmV3IFNldCgpLFxuICAgICAgc291cmNlczoge30sXG4gICAgfSxcbiAgICB0eXBlczoge1xuICAgICAgc2V0OiBuZXcgU2V0KCksXG4gICAgICBzb3VyY2VzOiB7fSxcbiAgICB9LFxuICAgIGNvbW1vbmpzOiB7XG4gICAgICBzZXQ6IG5ldyBTZXQoKSxcbiAgICB9LFxuICB9XG5cbiAgcmV0dXJuIHtcbiAgICBFeHBvcnROYW1lZERlY2xhcmF0aW9uKG5vZGUpIHtcbiAgICAgIGxldCB0YXJnZXQgPSBub2RlLmV4cG9ydEtpbmQgPT09ICd0eXBlJyA/IG5vZGVzLnR5cGVzIDogbm9kZXMubW9kdWxlc1xuICAgICAgaWYgKCFub2RlLnNvdXJjZSkge1xuICAgICAgICB0YXJnZXQuc2V0LmFkZChub2RlKVxuICAgICAgfSBlbHNlIGlmIChBcnJheS5pc0FycmF5KHRhcmdldC5zb3VyY2VzW25vZGUuc291cmNlLnZhbHVlXSkpIHtcbiAgICAgICAgdGFyZ2V0LnNvdXJjZXNbbm9kZS5zb3VyY2UudmFsdWVdLnB1c2gobm9kZSlcbiAgICAgIH0gZWxzZSB7XG4gICAgICAgIHRhcmdldC5zb3VyY2VzW25vZGUuc291cmNlLnZhbHVlXSA9IFtub2RlXVxuICAgICAgfVxuICAgIH0sXG5cbiAgICBBc3NpZ25tZW50RXhwcmVzc2lvbihub2RlKSB7XG4gICAgICBpZiAobm9kZS5sZWZ0LnR5cGUgIT09ICdNZW1iZXJFeHByZXNzaW9uJykge1xuICAgICAgICByZXR1cm5cbiAgICAgIH1cblxuICAgICAgY29uc3QgY2hhaW4gPSBhY2Nlc3NvckNoYWluKG5vZGUubGVmdClcblxuICAgICAgLy8gQXNzaWdubWVudHMgdG8gbW9kdWxlLmV4cG9ydHNcbiAgICAgIC8vIERlZXBlciBhc3NpZ25tZW50cyBhcmUgaWdub3JlZCBzaW5jZSB0aGV5IGp1c3QgbW9kaWZ5IHdoYXQncyBhbHJlYWR5IGJlaW5nIGV4cG9ydGVkXG4gICAgICAvLyAoaWUuIG1vZHVsZS5leHBvcnRzLmV4cG9ydGVkLnByb3AgPSB0cnVlIGlzIGlnbm9yZWQpXG4gICAgICBpZiAoY2hhaW5bMF0gPT09ICdtb2R1bGUnICYmIGNoYWluWzFdID09PSAnZXhwb3J0cycgJiYgY2hhaW4ubGVuZ3RoIDw9IDMpIHtcbiAgICAgICAgbm9kZXMuY29tbW9uanMuc2V0LmFkZChub2RlKVxuICAgICAgICByZXR1cm5cbiAgICAgIH1cblxuICAgICAgLy8gQXNzaWdubWVudHMgdG8gZXhwb3J0cyAoZXhwb3J0cy4qID0gKilcbiAgICAgIGlmIChjaGFpblswXSA9PT0gJ2V4cG9ydHMnICYmIGNoYWluLmxlbmd0aCA9PT0gMikge1xuICAgICAgICBub2Rlcy5jb21tb25qcy5zZXQuYWRkKG5vZGUpXG4gICAgICAgIHJldHVyblxuICAgICAgfVxuICAgIH0sXG5cbiAgICAnUHJvZ3JhbTpleGl0JzogZnVuY3Rpb24gb25FeGl0KCkge1xuICAgICAgLy8gUmVwb3J0IG11bHRpcGxlIGBleHBvcnRgIGRlY2xhcmF0aW9ucyAoRVMyMDE1IG1vZHVsZXMpXG4gICAgICBpZiAobm9kZXMubW9kdWxlcy5zZXQuc2l6ZSA+IDEpIHtcbiAgICAgICAgbm9kZXMubW9kdWxlcy5zZXQuZm9yRWFjaChub2RlID0+IHtcbiAgICAgICAgICBjb250ZXh0LnJlcG9ydCh7XG4gICAgICAgICAgICBub2RlLFxuICAgICAgICAgICAgbWVzc2FnZTogZXJyb3JzW25vZGUudHlwZV0sXG4gICAgICAgICAgfSlcbiAgICAgICAgfSlcbiAgICAgIH1cblxuICAgICAgLy8gUmVwb3J0IG11bHRpcGxlIGBhZ2dyZWdhdGVkIGV4cG9ydHNgIGZyb20gdGhlIHNhbWUgbW9kdWxlIChFUzIwMTUgbW9kdWxlcylcbiAgICAgIGZsYXQodmFsdWVzKG5vZGVzLm1vZHVsZXMuc291cmNlcylcbiAgICAgICAgLmZpbHRlcihub2Rlc1dpdGhTb3VyY2UgPT4gQXJyYXkuaXNBcnJheShub2Rlc1dpdGhTb3VyY2UpICYmIG5vZGVzV2l0aFNvdXJjZS5sZW5ndGggPiAxKSlcbiAgICAgICAgLmZvckVhY2goKG5vZGUpID0+IHtcbiAgICAgICAgICBjb250ZXh0LnJlcG9ydCh7XG4gICAgICAgICAgICBub2RlLFxuICAgICAgICAgICAgbWVzc2FnZTogZXJyb3JzW25vZGUudHlwZV0sXG4gICAgICAgICAgfSlcbiAgICAgICAgfSlcblxuICAgICAgLy8gUmVwb3J0IG11bHRpcGxlIGBleHBvcnQgdHlwZWAgZGVjbGFyYXRpb25zIChGTE9XIEVTMjAxNSBtb2R1bGVzKVxuICAgICAgaWYgKG5vZGVzLnR5cGVzLnNldC5zaXplID4gMSkge1xuICAgICAgICBub2Rlcy50eXBlcy5zZXQuZm9yRWFjaChub2RlID0+IHtcbiAgICAgICAgICBjb250ZXh0LnJlcG9ydCh7XG4gICAgICAgICAgICBub2RlLFxuICAgICAgICAgICAgbWVzc2FnZTogZXJyb3JzW25vZGUudHlwZV0sXG4gICAgICAgICAgfSlcbiAgICAgICAgfSlcbiAgICAgIH1cblxuICAgICAgLy8gUmVwb3J0IG11bHRpcGxlIGBhZ2dyZWdhdGVkIHR5cGUgZXhwb3J0c2AgZnJvbSB0aGUgc2FtZSBtb2R1bGUgKEZMT1cgRVMyMDE1IG1vZHVsZXMpXG4gICAgICBmbGF0KHZhbHVlcyhub2Rlcy50eXBlcy5zb3VyY2VzKVxuICAgICAgICAuZmlsdGVyKG5vZGVzV2l0aFNvdXJjZSA9PiBBcnJheS5pc0FycmF5KG5vZGVzV2l0aFNvdXJjZSkgJiYgbm9kZXNXaXRoU291cmNlLmxlbmd0aCA+IDEpKVxuICAgICAgICAuZm9yRWFjaCgobm9kZSkgPT4ge1xuICAgICAgICAgIGNvbnRleHQucmVwb3J0KHtcbiAgICAgICAgICAgIG5vZGUsXG4gICAgICAgICAgICBtZXNzYWdlOiBlcnJvcnNbbm9kZS50eXBlXSxcbiAgICAgICAgICB9KVxuICAgICAgICB9KVxuXG4gICAgICAvLyBSZXBvcnQgbXVsdGlwbGUgYG1vZHVsZS5leHBvcnRzYCBhc3NpZ25tZW50cyAoQ29tbW9uSlMpXG4gICAgICBpZiAobm9kZXMuY29tbW9uanMuc2V0LnNpemUgPiAxKSB7XG4gICAgICAgIG5vZGVzLmNvbW1vbmpzLnNldC5mb3JFYWNoKG5vZGUgPT4ge1xuICAgICAgICAgIGNvbnRleHQucmVwb3J0KHtcbiAgICAgICAgICAgIG5vZGUsXG4gICAgICAgICAgICBtZXNzYWdlOiBlcnJvcnNbbm9kZS50eXBlXSxcbiAgICAgICAgICB9KVxuICAgICAgICB9KVxuICAgICAgfVxuICAgIH0sXG4gIH1cbn1cblxubW9kdWxlLmV4cG9ydHMgPSB7XG4gIG1ldGEsXG4gIGNyZWF0ZSxcbn1cbiJdfQ==