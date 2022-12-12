'use strict';




var _docsUrl = require('../docsUrl');var _docsUrl2 = _interopRequireDefault(_docsUrl);function _interopRequireDefault(obj) {return obj && obj.__esModule ? obj : { default: obj };}

//------------------------------------------------------------------------------
// Rule Definition
//------------------------------------------------------------------------------

module.exports = {
  meta: {
    type: 'suggestion',
    docs: {
      url: (0, _docsUrl2.default)('no-amd') },

    schema: [] },


  create: function (context) {
    return {
      'CallExpression': function (node) {
        if (context.getScope().type !== 'module') return;

        if (node.callee.type !== 'Identifier') return;
        if (node.callee.name !== 'require' &&
        node.callee.name !== 'define') return;

        // todo: capture define((require, module, exports) => {}) form?
        if (node.arguments.length !== 2) return;

        const modules = node.arguments[0];
        if (modules.type !== 'ArrayExpression') return;

        // todo: check second arg type? (identifier or callback)

        context.report(node, `Expected imports instead of AMD ${node.callee.name}().`);
      } };


  } }; /**
        * @fileoverview Rule to prefer imports to AMD
        * @author Jamund Ferguson
        */
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIi4uLy4uL3NyYy9ydWxlcy9uby1hbWQuanMiXSwibmFtZXMiOlsibW9kdWxlIiwiZXhwb3J0cyIsIm1ldGEiLCJ0eXBlIiwiZG9jcyIsInVybCIsInNjaGVtYSIsImNyZWF0ZSIsImNvbnRleHQiLCJub2RlIiwiZ2V0U2NvcGUiLCJjYWxsZWUiLCJuYW1lIiwiYXJndW1lbnRzIiwibGVuZ3RoIiwibW9kdWxlcyIsInJlcG9ydCJdLCJtYXBwaW5ncyI6Ijs7Ozs7QUFLQSxxQzs7QUFFQTtBQUNBO0FBQ0E7O0FBRUFBLE9BQU9DLE9BQVAsR0FBaUI7QUFDZkMsUUFBTTtBQUNKQyxVQUFNLFlBREY7QUFFSkMsVUFBTTtBQUNKQyxXQUFLLHVCQUFRLFFBQVIsQ0FERCxFQUZGOztBQUtKQyxZQUFRLEVBTEosRUFEUzs7O0FBU2ZDLFVBQVEsVUFBVUMsT0FBVixFQUFtQjtBQUN6QixXQUFPO0FBQ0wsd0JBQWtCLFVBQVVDLElBQVYsRUFBZ0I7QUFDaEMsWUFBSUQsUUFBUUUsUUFBUixHQUFtQlAsSUFBbkIsS0FBNEIsUUFBaEMsRUFBMEM7O0FBRTFDLFlBQUlNLEtBQUtFLE1BQUwsQ0FBWVIsSUFBWixLQUFxQixZQUF6QixFQUF1QztBQUN2QyxZQUFJTSxLQUFLRSxNQUFMLENBQVlDLElBQVosS0FBcUIsU0FBckI7QUFDQUgsYUFBS0UsTUFBTCxDQUFZQyxJQUFaLEtBQXFCLFFBRHpCLEVBQ21DOztBQUVuQztBQUNBLFlBQUlILEtBQUtJLFNBQUwsQ0FBZUMsTUFBZixLQUEwQixDQUE5QixFQUFpQzs7QUFFakMsY0FBTUMsVUFBVU4sS0FBS0ksU0FBTCxDQUFlLENBQWYsQ0FBaEI7QUFDQSxZQUFJRSxRQUFRWixJQUFSLEtBQWlCLGlCQUFyQixFQUF3Qzs7QUFFeEM7O0FBRUFLLGdCQUFRUSxNQUFSLENBQWVQLElBQWYsRUFBc0IsbUNBQWtDQSxLQUFLRSxNQUFMLENBQVlDLElBQUssS0FBekU7QUFDRCxPQWpCSSxFQUFQOzs7QUFvQkQsR0E5QmMsRUFBakIsQyxDQVhBIiwiZmlsZSI6Im5vLWFtZC5qcyIsInNvdXJjZXNDb250ZW50IjpbIi8qKlxuICogQGZpbGVvdmVydmlldyBSdWxlIHRvIHByZWZlciBpbXBvcnRzIHRvIEFNRFxuICogQGF1dGhvciBKYW11bmQgRmVyZ3Vzb25cbiAqL1xuXG5pbXBvcnQgZG9jc1VybCBmcm9tICcuLi9kb2NzVXJsJ1xuXG4vLy0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLVxuLy8gUnVsZSBEZWZpbml0aW9uXG4vLy0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLVxuXG5tb2R1bGUuZXhwb3J0cyA9IHtcbiAgbWV0YToge1xuICAgIHR5cGU6ICdzdWdnZXN0aW9uJyxcbiAgICBkb2NzOiB7XG4gICAgICB1cmw6IGRvY3NVcmwoJ25vLWFtZCcpLFxuICAgIH0sXG4gICAgc2NoZW1hOiBbXSxcbiAgfSxcblxuICBjcmVhdGU6IGZ1bmN0aW9uIChjb250ZXh0KSB7XG4gICAgcmV0dXJuIHtcbiAgICAgICdDYWxsRXhwcmVzc2lvbic6IGZ1bmN0aW9uIChub2RlKSB7XG4gICAgICAgIGlmIChjb250ZXh0LmdldFNjb3BlKCkudHlwZSAhPT0gJ21vZHVsZScpIHJldHVyblxuXG4gICAgICAgIGlmIChub2RlLmNhbGxlZS50eXBlICE9PSAnSWRlbnRpZmllcicpIHJldHVyblxuICAgICAgICBpZiAobm9kZS5jYWxsZWUubmFtZSAhPT0gJ3JlcXVpcmUnICYmXG4gICAgICAgICAgICBub2RlLmNhbGxlZS5uYW1lICE9PSAnZGVmaW5lJykgcmV0dXJuXG5cbiAgICAgICAgLy8gdG9kbzogY2FwdHVyZSBkZWZpbmUoKHJlcXVpcmUsIG1vZHVsZSwgZXhwb3J0cykgPT4ge30pIGZvcm0/XG4gICAgICAgIGlmIChub2RlLmFyZ3VtZW50cy5sZW5ndGggIT09IDIpIHJldHVyblxuXG4gICAgICAgIGNvbnN0IG1vZHVsZXMgPSBub2RlLmFyZ3VtZW50c1swXVxuICAgICAgICBpZiAobW9kdWxlcy50eXBlICE9PSAnQXJyYXlFeHByZXNzaW9uJykgcmV0dXJuXG5cbiAgICAgICAgLy8gdG9kbzogY2hlY2sgc2Vjb25kIGFyZyB0eXBlPyAoaWRlbnRpZmllciBvciBjYWxsYmFjaylcblxuICAgICAgICBjb250ZXh0LnJlcG9ydChub2RlLCBgRXhwZWN0ZWQgaW1wb3J0cyBpbnN0ZWFkIG9mIEFNRCAke25vZGUuY2FsbGVlLm5hbWV9KCkuYClcbiAgICAgIH0sXG4gICAgfVxuXG4gIH0sXG59XG4iXX0=