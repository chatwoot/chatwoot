'use strict';




var _docsUrl = require('../docsUrl');var _docsUrl2 = _interopRequireDefault(_docsUrl);function _interopRequireDefault(obj) {return obj && obj.__esModule ? obj : { 'default': obj };}

//------------------------------------------------------------------------------
// Rule Definition
//------------------------------------------------------------------------------

module.exports = {
  meta: {
    type: 'suggestion',
    docs: {
      category: 'Module systems',
      description: 'Forbid AMD `require` and `define` calls.',
      url: (0, _docsUrl2['default'])('no-amd') },

    schema: [] },


  create: function () {function create(context) {
      return {
        CallExpression: function () {function CallExpression(node) {
            if (context.getScope().type !== 'module') {return;}

            if (node.callee.type !== 'Identifier') {return;}
            if (node.callee.name !== 'require' && node.callee.name !== 'define') {return;}

            // todo: capture define((require, module, exports) => {}) form?
            if (node.arguments.length !== 2) {return;}

            var modules = node.arguments[0];
            if (modules.type !== 'ArrayExpression') {return;}

            // todo: check second arg type? (identifier or callback)

            context.report(node, 'Expected imports instead of AMD ' + String(node.callee.name) + '().');
          }return CallExpression;}() };


    }return create;}() }; /**
                           * @fileoverview Rule to prefer imports to AMD
                           * @author Jamund Ferguson
                           */
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIi4uLy4uL3NyYy9ydWxlcy9uby1hbWQuanMiXSwibmFtZXMiOlsibW9kdWxlIiwiZXhwb3J0cyIsIm1ldGEiLCJ0eXBlIiwiZG9jcyIsImNhdGVnb3J5IiwiZGVzY3JpcHRpb24iLCJ1cmwiLCJzY2hlbWEiLCJjcmVhdGUiLCJjb250ZXh0IiwiQ2FsbEV4cHJlc3Npb24iLCJub2RlIiwiZ2V0U2NvcGUiLCJjYWxsZWUiLCJuYW1lIiwiYXJndW1lbnRzIiwibGVuZ3RoIiwibW9kdWxlcyIsInJlcG9ydCJdLCJtYXBwaW5ncyI6Ijs7Ozs7QUFLQSxxQzs7QUFFQTtBQUNBO0FBQ0E7O0FBRUFBLE9BQU9DLE9BQVAsR0FBaUI7QUFDZkMsUUFBTTtBQUNKQyxVQUFNLFlBREY7QUFFSkMsVUFBTTtBQUNKQyxnQkFBVSxnQkFETjtBQUVKQyxtQkFBYSwwQ0FGVDtBQUdKQyxXQUFLLDBCQUFRLFFBQVIsQ0FIRCxFQUZGOztBQU9KQyxZQUFRLEVBUEosRUFEUzs7O0FBV2ZDLFFBWGUsK0JBV1JDLE9BWFEsRUFXQztBQUNkLGFBQU87QUFDTEMsc0JBREssdUNBQ1VDLElBRFYsRUFDZ0I7QUFDbkIsZ0JBQUlGLFFBQVFHLFFBQVIsR0FBbUJWLElBQW5CLEtBQTRCLFFBQWhDLEVBQTBDLENBQUUsT0FBUzs7QUFFckQsZ0JBQUlTLEtBQUtFLE1BQUwsQ0FBWVgsSUFBWixLQUFxQixZQUF6QixFQUF1QyxDQUFFLE9BQVM7QUFDbEQsZ0JBQUlTLEtBQUtFLE1BQUwsQ0FBWUMsSUFBWixLQUFxQixTQUFyQixJQUFrQ0gsS0FBS0UsTUFBTCxDQUFZQyxJQUFaLEtBQXFCLFFBQTNELEVBQXFFLENBQUUsT0FBUzs7QUFFaEY7QUFDQSxnQkFBSUgsS0FBS0ksU0FBTCxDQUFlQyxNQUFmLEtBQTBCLENBQTlCLEVBQWlDLENBQUUsT0FBUzs7QUFFNUMsZ0JBQU1DLFVBQVVOLEtBQUtJLFNBQUwsQ0FBZSxDQUFmLENBQWhCO0FBQ0EsZ0JBQUlFLFFBQVFmLElBQVIsS0FBaUIsaUJBQXJCLEVBQXdDLENBQUUsT0FBUzs7QUFFbkQ7O0FBRUFPLG9CQUFRUyxNQUFSLENBQWVQLElBQWYsOENBQXdEQSxLQUFLRSxNQUFMLENBQVlDLElBQXBFO0FBQ0QsV0FoQkksMkJBQVA7OztBQW1CRCxLQS9CYyxtQkFBakIsQyxDQVhBIiwiZmlsZSI6Im5vLWFtZC5qcyIsInNvdXJjZXNDb250ZW50IjpbIi8qKlxuICogQGZpbGVvdmVydmlldyBSdWxlIHRvIHByZWZlciBpbXBvcnRzIHRvIEFNRFxuICogQGF1dGhvciBKYW11bmQgRmVyZ3Vzb25cbiAqL1xuXG5pbXBvcnQgZG9jc1VybCBmcm9tICcuLi9kb2NzVXJsJztcblxuLy8tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS1cbi8vIFJ1bGUgRGVmaW5pdGlvblxuLy8tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS1cblxubW9kdWxlLmV4cG9ydHMgPSB7XG4gIG1ldGE6IHtcbiAgICB0eXBlOiAnc3VnZ2VzdGlvbicsXG4gICAgZG9jczoge1xuICAgICAgY2F0ZWdvcnk6ICdNb2R1bGUgc3lzdGVtcycsXG4gICAgICBkZXNjcmlwdGlvbjogJ0ZvcmJpZCBBTUQgYHJlcXVpcmVgIGFuZCBgZGVmaW5lYCBjYWxscy4nLFxuICAgICAgdXJsOiBkb2NzVXJsKCduby1hbWQnKSxcbiAgICB9LFxuICAgIHNjaGVtYTogW10sXG4gIH0sXG5cbiAgY3JlYXRlKGNvbnRleHQpIHtcbiAgICByZXR1cm4ge1xuICAgICAgQ2FsbEV4cHJlc3Npb24obm9kZSkge1xuICAgICAgICBpZiAoY29udGV4dC5nZXRTY29wZSgpLnR5cGUgIT09ICdtb2R1bGUnKSB7IHJldHVybjsgfVxuXG4gICAgICAgIGlmIChub2RlLmNhbGxlZS50eXBlICE9PSAnSWRlbnRpZmllcicpIHsgcmV0dXJuOyB9XG4gICAgICAgIGlmIChub2RlLmNhbGxlZS5uYW1lICE9PSAncmVxdWlyZScgJiYgbm9kZS5jYWxsZWUubmFtZSAhPT0gJ2RlZmluZScpIHsgcmV0dXJuOyB9XG5cbiAgICAgICAgLy8gdG9kbzogY2FwdHVyZSBkZWZpbmUoKHJlcXVpcmUsIG1vZHVsZSwgZXhwb3J0cykgPT4ge30pIGZvcm0/XG4gICAgICAgIGlmIChub2RlLmFyZ3VtZW50cy5sZW5ndGggIT09IDIpIHsgcmV0dXJuOyB9XG5cbiAgICAgICAgY29uc3QgbW9kdWxlcyA9IG5vZGUuYXJndW1lbnRzWzBdO1xuICAgICAgICBpZiAobW9kdWxlcy50eXBlICE9PSAnQXJyYXlFeHByZXNzaW9uJykgeyByZXR1cm47IH1cblxuICAgICAgICAvLyB0b2RvOiBjaGVjayBzZWNvbmQgYXJnIHR5cGU/IChpZGVudGlmaWVyIG9yIGNhbGxiYWNrKVxuXG4gICAgICAgIGNvbnRleHQucmVwb3J0KG5vZGUsIGBFeHBlY3RlZCBpbXBvcnRzIGluc3RlYWQgb2YgQU1EICR7bm9kZS5jYWxsZWUubmFtZX0oKS5gKTtcbiAgICAgIH0sXG4gICAgfTtcblxuICB9LFxufTtcbiJdfQ==