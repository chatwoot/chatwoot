'use strict';




var _unambiguous = require('eslint-module-utils/unambiguous');
var _docsUrl = require('../docsUrl');var _docsUrl2 = _interopRequireDefault(_docsUrl);function _interopRequireDefault(obj) {return obj && obj.__esModule ? obj : { 'default': obj };} /**
                                                                                                                                                                                       * @fileOverview Report modules that could parse incorrectly as scripts.
                                                                                                                                                                                       * @author Ben Mosher
                                                                                                                                                                                       */module.exports = { meta: {
    type: 'suggestion',
    docs: {
      category: 'Module systems',
      description: 'Forbid potentially ambiguous parse goal (`script` vs. `module`).',
      url: (0, _docsUrl2['default'])('unambiguous') },

    schema: [] },


  create: function () {function create(context) {
      // ignore non-modules
      if (context.parserOptions.sourceType !== 'module') {
        return {};
      }

      return {
        Program: function () {function Program(ast) {
            if (!(0, _unambiguous.isModule)(ast)) {
              context.report({
                node: ast,
                message: 'This module could be parsed as a valid script.' });

            }
          }return Program;}() };


    }return create;}() };
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIi4uLy4uL3NyYy9ydWxlcy91bmFtYmlndW91cy5qcyJdLCJuYW1lcyI6WyJtb2R1bGUiLCJleHBvcnRzIiwibWV0YSIsInR5cGUiLCJkb2NzIiwiY2F0ZWdvcnkiLCJkZXNjcmlwdGlvbiIsInVybCIsInNjaGVtYSIsImNyZWF0ZSIsImNvbnRleHQiLCJwYXJzZXJPcHRpb25zIiwic291cmNlVHlwZSIsIlByb2dyYW0iLCJhc3QiLCJyZXBvcnQiLCJub2RlIiwibWVzc2FnZSJdLCJtYXBwaW5ncyI6Ijs7Ozs7QUFLQTtBQUNBLHFDLGlKQU5BOzs7eUxBUUFBLE9BQU9DLE9BQVAsR0FBaUIsRUFDZkMsTUFBTTtBQUNKQyxVQUFNLFlBREY7QUFFSkMsVUFBTTtBQUNKQyxnQkFBVSxnQkFETjtBQUVKQyxtQkFBYSxrRUFGVDtBQUdKQyxXQUFLLDBCQUFRLGFBQVIsQ0FIRCxFQUZGOztBQU9KQyxZQUFRLEVBUEosRUFEUzs7O0FBV2ZDLFFBWGUsK0JBV1JDLE9BWFEsRUFXQztBQUNkO0FBQ0EsVUFBSUEsUUFBUUMsYUFBUixDQUFzQkMsVUFBdEIsS0FBcUMsUUFBekMsRUFBbUQ7QUFDakQsZUFBTyxFQUFQO0FBQ0Q7O0FBRUQsYUFBTztBQUNMQyxlQURLLGdDQUNHQyxHQURILEVBQ1E7QUFDWCxnQkFBSSxDQUFDLDJCQUFTQSxHQUFULENBQUwsRUFBb0I7QUFDbEJKLHNCQUFRSyxNQUFSLENBQWU7QUFDYkMsc0JBQU1GLEdBRE87QUFFYkcseUJBQVMsZ0RBRkksRUFBZjs7QUFJRDtBQUNGLFdBUkksb0JBQVA7OztBQVdELEtBNUJjLG1CQUFqQiIsImZpbGUiOiJ1bmFtYmlndW91cy5qcyIsInNvdXJjZXNDb250ZW50IjpbIi8qKlxuICogQGZpbGVPdmVydmlldyBSZXBvcnQgbW9kdWxlcyB0aGF0IGNvdWxkIHBhcnNlIGluY29ycmVjdGx5IGFzIHNjcmlwdHMuXG4gKiBAYXV0aG9yIEJlbiBNb3NoZXJcbiAqL1xuXG5pbXBvcnQgeyBpc01vZHVsZSB9IGZyb20gJ2VzbGludC1tb2R1bGUtdXRpbHMvdW5hbWJpZ3VvdXMnO1xuaW1wb3J0IGRvY3NVcmwgZnJvbSAnLi4vZG9jc1VybCc7XG5cbm1vZHVsZS5leHBvcnRzID0ge1xuICBtZXRhOiB7XG4gICAgdHlwZTogJ3N1Z2dlc3Rpb24nLFxuICAgIGRvY3M6IHtcbiAgICAgIGNhdGVnb3J5OiAnTW9kdWxlIHN5c3RlbXMnLFxuICAgICAgZGVzY3JpcHRpb246ICdGb3JiaWQgcG90ZW50aWFsbHkgYW1iaWd1b3VzIHBhcnNlIGdvYWwgKGBzY3JpcHRgIHZzLiBgbW9kdWxlYCkuJyxcbiAgICAgIHVybDogZG9jc1VybCgndW5hbWJpZ3VvdXMnKSxcbiAgICB9LFxuICAgIHNjaGVtYTogW10sXG4gIH0sXG5cbiAgY3JlYXRlKGNvbnRleHQpIHtcbiAgICAvLyBpZ25vcmUgbm9uLW1vZHVsZXNcbiAgICBpZiAoY29udGV4dC5wYXJzZXJPcHRpb25zLnNvdXJjZVR5cGUgIT09ICdtb2R1bGUnKSB7XG4gICAgICByZXR1cm4ge307XG4gICAgfVxuXG4gICAgcmV0dXJuIHtcbiAgICAgIFByb2dyYW0oYXN0KSB7XG4gICAgICAgIGlmICghaXNNb2R1bGUoYXN0KSkge1xuICAgICAgICAgIGNvbnRleHQucmVwb3J0KHtcbiAgICAgICAgICAgIG5vZGU6IGFzdCxcbiAgICAgICAgICAgIG1lc3NhZ2U6ICdUaGlzIG1vZHVsZSBjb3VsZCBiZSBwYXJzZWQgYXMgYSB2YWxpZCBzY3JpcHQuJyxcbiAgICAgICAgICB9KTtcbiAgICAgICAgfVxuICAgICAgfSxcbiAgICB9O1xuXG4gIH0sXG59O1xuIl19