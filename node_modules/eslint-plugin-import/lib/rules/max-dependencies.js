'use strict';var _slicedToArray = function () {function sliceIterator(arr, i) {var _arr = [];var _n = true;var _d = false;var _e = undefined;try {for (var _i = arr[Symbol.iterator](), _s; !(_n = (_s = _i.next()).done); _n = true) {_arr.push(_s.value);if (i && _arr.length === i) break;}} catch (err) {_d = true;_e = err;} finally {try {if (!_n && _i["return"]) _i["return"]();} finally {if (_d) throw _e;}}return _arr;}return function (arr, i) {if (Array.isArray(arr)) {return arr;} else if (Symbol.iterator in Object(arr)) {return sliceIterator(arr, i);} else {throw new TypeError("Invalid attempt to destructure non-iterable instance");}};}();var _staticRequire = require('../core/staticRequire');var _staticRequire2 = _interopRequireDefault(_staticRequire);
var _docsUrl = require('../docsUrl');var _docsUrl2 = _interopRequireDefault(_docsUrl);function _interopRequireDefault(obj) {return obj && obj.__esModule ? obj : { default: obj };}

const DEFAULT_MAX = 10;

const countDependencies = (dependencies, lastNode, context) => {var _ref =
  context.options[0] || { max: DEFAULT_MAX };const max = _ref.max;

  if (dependencies.size > max) {
    context.report(
    lastNode,
    `Maximum number of dependencies (${max}) exceeded.`);

  }
};

module.exports = {
  meta: {
    type: 'suggestion',
    docs: {
      url: (0, _docsUrl2.default)('max-dependencies') },


    schema: [
    {
      'type': 'object',
      'properties': {
        'max': { 'type': 'number' } },

      'additionalProperties': false }] },




  create: context => {
    const dependencies = new Set(); // keep track of dependencies
    let lastNode; // keep track of the last node to report on

    return {
      ImportDeclaration(node) {
        dependencies.add(node.source.value);
        lastNode = node.source;
      },

      CallExpression(node) {
        if ((0, _staticRequire2.default)(node)) {var _node$arguments = _slicedToArray(
          node.arguments, 1);const requirePath = _node$arguments[0];
          dependencies.add(requirePath.value);
          lastNode = node;
        }
      },

      'Program:exit': function () {
        countDependencies(dependencies, lastNode, context);
      } };

  } };
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIi4uLy4uL3NyYy9ydWxlcy9tYXgtZGVwZW5kZW5jaWVzLmpzIl0sIm5hbWVzIjpbIkRFRkFVTFRfTUFYIiwiY291bnREZXBlbmRlbmNpZXMiLCJkZXBlbmRlbmNpZXMiLCJsYXN0Tm9kZSIsImNvbnRleHQiLCJvcHRpb25zIiwibWF4Iiwic2l6ZSIsInJlcG9ydCIsIm1vZHVsZSIsImV4cG9ydHMiLCJtZXRhIiwidHlwZSIsImRvY3MiLCJ1cmwiLCJzY2hlbWEiLCJjcmVhdGUiLCJTZXQiLCJJbXBvcnREZWNsYXJhdGlvbiIsIm5vZGUiLCJhZGQiLCJzb3VyY2UiLCJ2YWx1ZSIsIkNhbGxFeHByZXNzaW9uIiwiYXJndW1lbnRzIiwicmVxdWlyZVBhdGgiXSwibWFwcGluZ3MiOiJxb0JBQUEsc0Q7QUFDQSxxQzs7QUFFQSxNQUFNQSxjQUFjLEVBQXBCOztBQUVBLE1BQU1DLG9CQUFvQixDQUFDQyxZQUFELEVBQWVDLFFBQWYsRUFBeUJDLE9BQXpCLEtBQXFDO0FBQy9DQSxVQUFRQyxPQUFSLENBQWdCLENBQWhCLEtBQXNCLEVBQUVDLEtBQUtOLFdBQVAsRUFEeUIsT0FDdERNLEdBRHNELFFBQ3REQSxHQURzRDs7QUFHN0QsTUFBSUosYUFBYUssSUFBYixHQUFvQkQsR0FBeEIsRUFBNkI7QUFDM0JGLFlBQVFJLE1BQVI7QUFDRUwsWUFERjtBQUVHLHVDQUFrQ0csR0FBSSxhQUZ6Qzs7QUFJRDtBQUNGLENBVEQ7O0FBV0FHLE9BQU9DLE9BQVAsR0FBaUI7QUFDZkMsUUFBTTtBQUNKQyxVQUFNLFlBREY7QUFFSkMsVUFBTTtBQUNKQyxXQUFLLHVCQUFRLGtCQUFSLENBREQsRUFGRjs7O0FBTUpDLFlBQVE7QUFDTjtBQUNFLGNBQVEsUUFEVjtBQUVFLG9CQUFjO0FBQ1osZUFBTyxFQUFFLFFBQVEsUUFBVixFQURLLEVBRmhCOztBQUtFLDhCQUF3QixLQUwxQixFQURNLENBTkosRUFEUzs7Ozs7QUFrQmZDLFVBQVFaLFdBQVc7QUFDakIsVUFBTUYsZUFBZSxJQUFJZSxHQUFKLEVBQXJCLENBRGlCLENBQ2M7QUFDL0IsUUFBSWQsUUFBSixDQUZpQixDQUVKOztBQUViLFdBQU87QUFDTGUsd0JBQWtCQyxJQUFsQixFQUF3QjtBQUN0QmpCLHFCQUFha0IsR0FBYixDQUFpQkQsS0FBS0UsTUFBTCxDQUFZQyxLQUE3QjtBQUNBbkIsbUJBQVdnQixLQUFLRSxNQUFoQjtBQUNELE9BSkk7O0FBTUxFLHFCQUFlSixJQUFmLEVBQXFCO0FBQ25CLFlBQUksNkJBQWdCQSxJQUFoQixDQUFKLEVBQTJCO0FBQ0RBLGVBQUtLLFNBREosV0FDakJDLFdBRGlCO0FBRXpCdkIsdUJBQWFrQixHQUFiLENBQWlCSyxZQUFZSCxLQUE3QjtBQUNBbkIscUJBQVdnQixJQUFYO0FBQ0Q7QUFDRixPQVpJOztBQWNMLHNCQUFnQixZQUFZO0FBQzFCbEIsMEJBQWtCQyxZQUFsQixFQUFnQ0MsUUFBaEMsRUFBMENDLE9BQTFDO0FBQ0QsT0FoQkksRUFBUDs7QUFrQkQsR0F4Q2MsRUFBakIiLCJmaWxlIjoibWF4LWRlcGVuZGVuY2llcy5qcyIsInNvdXJjZXNDb250ZW50IjpbImltcG9ydCBpc1N0YXRpY1JlcXVpcmUgZnJvbSAnLi4vY29yZS9zdGF0aWNSZXF1aXJlJ1xuaW1wb3J0IGRvY3NVcmwgZnJvbSAnLi4vZG9jc1VybCdcblxuY29uc3QgREVGQVVMVF9NQVggPSAxMFxuXG5jb25zdCBjb3VudERlcGVuZGVuY2llcyA9IChkZXBlbmRlbmNpZXMsIGxhc3ROb2RlLCBjb250ZXh0KSA9PiB7XG4gIGNvbnN0IHttYXh9ID0gY29udGV4dC5vcHRpb25zWzBdIHx8IHsgbWF4OiBERUZBVUxUX01BWCB9XG5cbiAgaWYgKGRlcGVuZGVuY2llcy5zaXplID4gbWF4KSB7XG4gICAgY29udGV4dC5yZXBvcnQoXG4gICAgICBsYXN0Tm9kZSxcbiAgICAgIGBNYXhpbXVtIG51bWJlciBvZiBkZXBlbmRlbmNpZXMgKCR7bWF4fSkgZXhjZWVkZWQuYFxuICAgIClcbiAgfVxufVxuXG5tb2R1bGUuZXhwb3J0cyA9IHtcbiAgbWV0YToge1xuICAgIHR5cGU6ICdzdWdnZXN0aW9uJyxcbiAgICBkb2NzOiB7XG4gICAgICB1cmw6IGRvY3NVcmwoJ21heC1kZXBlbmRlbmNpZXMnKSxcbiAgICB9LFxuXG4gICAgc2NoZW1hOiBbXG4gICAgICB7XG4gICAgICAgICd0eXBlJzogJ29iamVjdCcsXG4gICAgICAgICdwcm9wZXJ0aWVzJzoge1xuICAgICAgICAgICdtYXgnOiB7ICd0eXBlJzogJ251bWJlcicgfSxcbiAgICAgICAgfSxcbiAgICAgICAgJ2FkZGl0aW9uYWxQcm9wZXJ0aWVzJzogZmFsc2UsXG4gICAgICB9LFxuICAgIF0sXG4gIH0sXG5cbiAgY3JlYXRlOiBjb250ZXh0ID0+IHtcbiAgICBjb25zdCBkZXBlbmRlbmNpZXMgPSBuZXcgU2V0KCkgLy8ga2VlcCB0cmFjayBvZiBkZXBlbmRlbmNpZXNcbiAgICBsZXQgbGFzdE5vZGUgLy8ga2VlcCB0cmFjayBvZiB0aGUgbGFzdCBub2RlIHRvIHJlcG9ydCBvblxuXG4gICAgcmV0dXJuIHtcbiAgICAgIEltcG9ydERlY2xhcmF0aW9uKG5vZGUpIHtcbiAgICAgICAgZGVwZW5kZW5jaWVzLmFkZChub2RlLnNvdXJjZS52YWx1ZSlcbiAgICAgICAgbGFzdE5vZGUgPSBub2RlLnNvdXJjZVxuICAgICAgfSxcblxuICAgICAgQ2FsbEV4cHJlc3Npb24obm9kZSkge1xuICAgICAgICBpZiAoaXNTdGF0aWNSZXF1aXJlKG5vZGUpKSB7XG4gICAgICAgICAgY29uc3QgWyByZXF1aXJlUGF0aCBdID0gbm9kZS5hcmd1bWVudHNcbiAgICAgICAgICBkZXBlbmRlbmNpZXMuYWRkKHJlcXVpcmVQYXRoLnZhbHVlKVxuICAgICAgICAgIGxhc3ROb2RlID0gbm9kZVxuICAgICAgICB9XG4gICAgICB9LFxuXG4gICAgICAnUHJvZ3JhbTpleGl0JzogZnVuY3Rpb24gKCkge1xuICAgICAgICBjb3VudERlcGVuZGVuY2llcyhkZXBlbmRlbmNpZXMsIGxhc3ROb2RlLCBjb250ZXh0KVxuICAgICAgfSxcbiAgICB9XG4gIH0sXG59XG4iXX0=