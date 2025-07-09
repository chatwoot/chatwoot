'use strict';




var _docsUrl = require('../docsUrl');var _docsUrl2 = _interopRequireDefault(_docsUrl);function _interopRequireDefault(obj) {return obj && obj.__esModule ? obj : { 'default': obj };}

var EXPORT_MESSAGE = 'Expected "export" or "export default"'; /**
                                                               * @fileoverview Rule to prefer ES6 to CJS
                                                               * @author Jamund Ferguson
                                                               */var IMPORT_MESSAGE = 'Expected "import" instead of "require()"';function normalizeLegacyOptions(options) {
  if (options.indexOf('allow-primitive-modules') >= 0) {
    return { allowPrimitiveModules: true };
  }
  return options[0] || {};
}

function allowPrimitive(node, options) {
  if (!options.allowPrimitiveModules) {return false;}
  if (node.parent.type !== 'AssignmentExpression') {return false;}
  return node.parent.right.type !== 'ObjectExpression';
}

function allowRequire(node, options) {
  return options.allowRequire;
}

function allowConditionalRequire(node, options) {
  return options.allowConditionalRequire !== false;
}

function validateScope(scope) {
  return scope.variableScope.type === 'module';
}

// https://github.com/estree/estree/blob/HEAD/es5.md
function isConditional(node) {
  if (
  node.type === 'IfStatement' ||
  node.type === 'TryStatement' ||
  node.type === 'LogicalExpression' ||
  node.type === 'ConditionalExpression')
  {
    return true;
  }
  if (node.parent) {return isConditional(node.parent);}
  return false;
}

function isLiteralString(node) {
  return node.type === 'Literal' && typeof node.value === 'string' ||
  node.type === 'TemplateLiteral' && node.expressions.length === 0;
}

//------------------------------------------------------------------------------
// Rule Definition
//------------------------------------------------------------------------------

var schemaString = { 'enum': ['allow-primitive-modules'] };
var schemaObject = {
  type: 'object',
  properties: {
    allowPrimitiveModules: { type: 'boolean' },
    allowRequire: { type: 'boolean' },
    allowConditionalRequire: { type: 'boolean' } },

  additionalProperties: false };


module.exports = {
  meta: {
    type: 'suggestion',
    docs: {
      category: 'Module systems',
      description: 'Forbid CommonJS `require` calls and `module.exports` or `exports.*`.',
      url: (0, _docsUrl2['default'])('no-commonjs') },


    schema: {
      anyOf: [
      {
        type: 'array',
        items: [schemaString],
        additionalItems: false },

      {
        type: 'array',
        items: [schemaObject],
        additionalItems: false }] } },





  create: function () {function create(context) {
      var options = normalizeLegacyOptions(context.options);

      return {

        MemberExpression: function () {function MemberExpression(node) {

            // module.exports
            if (node.object.name === 'module' && node.property.name === 'exports') {
              if (allowPrimitive(node, options)) {return;}
              context.report({ node: node, message: EXPORT_MESSAGE });
            }

            // exports.
            if (node.object.name === 'exports') {
              var isInScope = context.getScope().
              variables.
              some(function (variable) {return variable.name === 'exports';});
              if (!isInScope) {
                context.report({ node: node, message: EXPORT_MESSAGE });
              }
            }

          }return MemberExpression;}(),
        CallExpression: function () {function CallExpression(call) {
            if (!validateScope(context.getScope())) {return;}

            if (call.callee.type !== 'Identifier') {return;}
            if (call.callee.name !== 'require') {return;}

            if (call.arguments.length !== 1) {return;}
            if (!isLiteralString(call.arguments[0])) {return;}

            if (allowRequire(call, options)) {return;}

            if (allowConditionalRequire(call, options) && isConditional(call.parent)) {return;}

            // keeping it simple: all 1-string-arg `require` calls are reported
            context.report({
              node: call.callee,
              message: IMPORT_MESSAGE });

          }return CallExpression;}() };


    }return create;}() };
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIi4uLy4uL3NyYy9ydWxlcy9uby1jb21tb25qcy5qcyJdLCJuYW1lcyI6WyJFWFBPUlRfTUVTU0FHRSIsIklNUE9SVF9NRVNTQUdFIiwibm9ybWFsaXplTGVnYWN5T3B0aW9ucyIsIm9wdGlvbnMiLCJpbmRleE9mIiwiYWxsb3dQcmltaXRpdmVNb2R1bGVzIiwiYWxsb3dQcmltaXRpdmUiLCJub2RlIiwicGFyZW50IiwidHlwZSIsInJpZ2h0IiwiYWxsb3dSZXF1aXJlIiwiYWxsb3dDb25kaXRpb25hbFJlcXVpcmUiLCJ2YWxpZGF0ZVNjb3BlIiwic2NvcGUiLCJ2YXJpYWJsZVNjb3BlIiwiaXNDb25kaXRpb25hbCIsImlzTGl0ZXJhbFN0cmluZyIsInZhbHVlIiwiZXhwcmVzc2lvbnMiLCJsZW5ndGgiLCJzY2hlbWFTdHJpbmciLCJzY2hlbWFPYmplY3QiLCJwcm9wZXJ0aWVzIiwiYWRkaXRpb25hbFByb3BlcnRpZXMiLCJtb2R1bGUiLCJleHBvcnRzIiwibWV0YSIsImRvY3MiLCJjYXRlZ29yeSIsImRlc2NyaXB0aW9uIiwidXJsIiwic2NoZW1hIiwiYW55T2YiLCJpdGVtcyIsImFkZGl0aW9uYWxJdGVtcyIsImNyZWF0ZSIsImNvbnRleHQiLCJNZW1iZXJFeHByZXNzaW9uIiwib2JqZWN0IiwibmFtZSIsInByb3BlcnR5IiwicmVwb3J0IiwibWVzc2FnZSIsImlzSW5TY29wZSIsImdldFNjb3BlIiwidmFyaWFibGVzIiwic29tZSIsInZhcmlhYmxlIiwiQ2FsbEV4cHJlc3Npb24iLCJjYWxsIiwiY2FsbGVlIiwiYXJndW1lbnRzIl0sIm1hcHBpbmdzIjoiOzs7OztBQUtBLHFDOztBQUVBLElBQU1BLGlCQUFpQix1Q0FBdkIsQyxDQVBBOzs7aUVBUUEsSUFBTUMsaUJBQWlCLDBDQUF2QixDQUVBLFNBQVNDLHNCQUFULENBQWdDQyxPQUFoQyxFQUF5QztBQUN2QyxNQUFJQSxRQUFRQyxPQUFSLENBQWdCLHlCQUFoQixLQUE4QyxDQUFsRCxFQUFxRDtBQUNu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QUEwQ2EsY0FBY2tDLEtBQUsxQyxNQUFuQixDQUE5QyxFQUEwRSxDQUFFLE9BQVM7O0FBRXJGO0FBQ0E2QixvQkFBUUssTUFBUixDQUFlO0FBQ2JuQyxvQkFBTTJDLEtBQUtDLE1BREU7QUFFYlIsdUJBQVMxQyxjQUZJLEVBQWY7O0FBSUQsV0F2Q0ksMkJBQVA7OztBQTBDRCxLQXRFYyxtQkFBakIiLCJmaWxlIjoibm8tY29tbW9uanMuanMiLCJzb3VyY2VzQ29udGVudCI6WyIvKipcbiAqIEBmaWxlb3ZlcnZpZXcgUnVsZSB0byBwcmVmZXIgRVM2IHRvIENKU1xuICogQGF1dGhvciBKYW11bmQgRmVyZ3Vzb25cbiAqL1xuXG5pbXBvcnQgZG9jc1VybCBmcm9tICcuLi9kb2NzVXJsJztcblxuY29uc3QgRVhQT1JUX01FU1NBR0UgPSAnRXhwZWN0ZWQgXCJleHBvcnRcIiBvciBcImV4cG9ydCBkZWZhdWx0XCInO1xuY29uc3QgSU1QT1JUX01FU1NBR0UgPSAnRXhwZWN0ZWQgXCJpbXBvcnRcIiBpbnN0ZWFkIG9mIFwicmVxdWlyZSgpXCInO1xuXG5mdW5jdGlvbiBub3JtYWxpemVMZWdhY3lPcHRpb25zKG9wdGlvbnMpIHtcbiAgaWYgKG9wdGlvbnMuaW5kZXhPZignYWxsb3ctcHJpbWl0aXZlLW1vZHVsZXMnKSA+PSAwKSB7XG4gICAgcmV0dXJuIHsgYWxsb3dQcmltaXRpdmVNb2R1bGVzOiB0cnVlIH07XG4gIH1cbiAgcmV0dXJuIG9wdGlvbnNbMF0gfHwge307XG59XG5cbmZ1bmN0aW9uIGFsbG93UHJpbWl0aXZlKG5vZGUsIG9wdGlvbnMpIHtcbiAgaWYgKCFvcHRpb25zLmFsbG93UHJpbWl0aXZlTW9kdWxlcykgeyByZXR1cm4gZmFsc2U7IH1cbiAgaWYgKG5vZGUucGFyZW50LnR5cGUgIT09ICdBc3NpZ25tZW50RXhwcmVzc2lvbicpIHsgcmV0dXJuIGZhbHNlOyB9XG4gIHJldHVybiBub2RlLnBhcmVudC5yaWdodC50eXBlICE9PSAnT2JqZWN0RXhwcmVzc2lvbic7XG59XG5cbmZ1bmN0aW9uIGFsbG93UmVxdWlyZShub2RlLCBvcHRpb25zKSB7XG4gIHJldHVybiBvcHRpb25zLmFsbG93UmVxdWlyZTtcbn1cblxuZnVuY3Rpb24gYWxsb3dDb25kaXRpb25hbFJlcXVpcmUobm9kZSwgb3B0aW9ucykge1xuICByZXR1cm4gb3B0aW9ucy5hbGxvd0NvbmRpdGlvbmFsUmVxdWlyZSAhPT0gZmFsc2U7XG59XG5cbmZ1bmN0aW9uIHZhbGlkYXRlU2NvcGUoc2NvcGUpIHtcbiAgcmV0dXJuIHNjb3BlLnZhcmlhYmxlU2NvcGUudHlwZSA9PT0gJ21vZHVsZSc7XG59XG5cbi8vIGh0dHBzOi8vZ2l0aHViLmNvbS9lc3RyZWUvZXN0cmVlL2Jsb2IvSEVBRC9lczUubWRcbmZ1bmN0aW9uIGlzQ29uZGl0aW9uYWwobm9kZSkge1xuICBpZiAoXG4gICAgbm9kZS50eXBlID09PSAnSWZTdGF0ZW1lbnQnXG4gICAgfHwgbm9kZS50eXBlID09PSAnVHJ5U3RhdGVtZW50J1xuICAgIHx8IG5vZGUudHlwZSA9PT0gJ0xvZ2ljYWxFeHByZXNzaW9uJ1xuICAgIHx8IG5vZGUudHlwZSA9PT0gJ0NvbmRpdGlvbmFsRXhwcmVzc2lvbidcbiAgKSB7XG4gICAgcmV0dXJuIHRydWU7XG4gIH1cbiAgaWYgKG5vZGUucGFyZW50KSB7IHJldHVybiBpc0NvbmRpdGlvbmFsKG5vZGUucGFyZW50KTsgfVxuICByZXR1cm4gZmFsc2U7XG59XG5cbmZ1bmN0aW9uIGlzTGl0ZXJhbFN0cmluZyhub2RlKSB7XG4gIHJldHVybiBub2RlLnR5cGUgPT09ICdMaXRlcmFsJyAmJiB0eXBlb2Ygbm9kZS52YWx1ZSA9PT0gJ3N0cmluZydcbiAgICB8fCBub2RlLnR5cGUgPT09ICdUZW1wbGF0ZUxpdGVyYWwnICYmIG5vZGUuZXhwcmVzc2lvbnMubGVuZ3RoID09PSAwO1xufVxuXG4vLy0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLVxuLy8gUnVsZSBEZWZpbml0aW9uXG4vLy0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLVxuXG5jb25zdCBzY2hlbWFTdHJpbmcgPSB7IGVudW06IFsnYWxsb3ctcHJpbWl0aXZlLW1vZHVsZXMnXSB9O1xuY29uc3Qgc2NoZW1hT2JqZWN0ID0ge1xuICB0eXBlOiAnb2JqZWN0JyxcbiAgcHJvcGVydGllczoge1xuICAgIGFsbG93UHJpbWl0aXZlTW9kdWxlczogeyB0eXBlOiAnYm9vbGVhbicgfSxcbiAgICBhbGxvd1JlcXVpcmU6IHsgdHlwZTogJ2Jvb2xlYW4nIH0sXG4gICAgYWxsb3dDb25kaXRpb25hbFJlcXVpcmU6IHsgdHlwZTogJ2Jvb2xlYW4nIH0sXG4gIH0sXG4gIGFkZGl0aW9uYWxQcm9wZXJ0aWVzOiBmYWxzZSxcbn07XG5cbm1vZHVsZS5leHBvcnRzID0ge1xuICBtZXRhOiB7XG4gICAgdHlwZTogJ3N1Z2dlc3Rpb24nLFxuICAgIGRvY3M6IHtcbiAgICAgIGNhdGVnb3J5OiAnTW9kdWxlIHN5c3RlbXMnLFxuICAgICAgZGVzY3JpcHRpb246ICdGb3JiaWQgQ29tbW9uSlMgYHJlcXVpcmVgIGNhbGxzIGFuZCBgbW9kdWxlLmV4cG9ydHNgIG9yIGBleHBvcnRzLipgLicsXG4gICAgICB1cmw6IGRvY3NVcmwoJ25vLWNvbW1vbmpzJyksXG4gICAgfSxcblxuICAgIHNjaGVtYToge1xuICAgICAgYW55T2Y6IFtcbiAgICAgICAge1xuICAgICAgICAgIHR5cGU6ICdhcnJheScsXG4gICAgICAgICAgaXRlbXM6IFtzY2hlbWFTdHJpbmddLFxuICAgICAgICAgIGFkZGl0aW9uYWxJdGVtczogZmFsc2UsXG4gICAgICAgIH0sXG4gICAgICAgIHtcbiAgICAgICAgICB0eXBlOiAnYXJyYXknLFxuICAgICAgICAgIGl0ZW1zOiBbc2NoZW1hT2JqZWN0XSxcbiAgICAgICAgICBhZGRpdGlvbmFsSXRlbXM6IGZhbHNlLFxuICAgICAgICB9LFxuICAgICAgXSxcbiAgICB9LFxuICB9LFxuXG4gIGNyZWF0ZShjb250ZXh0KSB7XG4gICAgY29uc3Qgb3B0aW9ucyA9IG5vcm1hbGl6ZUxlZ2FjeU9wdGlvbnMoY29udGV4dC5vcHRpb25zKTtcblxuICAgIHJldHVybiB7XG5cbiAgICAgIE1lbWJlckV4cHJlc3Npb24obm9kZSkge1xuXG4gICAgICAgIC8vIG1vZHVsZS5leHBvcnRzXG4gICAgICAgIGlmIChub2RlLm9iamVjdC5uYW1lID09PSAnbW9kdWxlJyAmJiBub2RlLnByb3BlcnR5Lm5hbWUgPT09ICdleHBvcnRzJykge1xuICAgICAgICAgIGlmIChhbGxvd1ByaW1pdGl2ZShub2RlLCBvcHRpb25zKSkgeyByZXR1cm47IH1cbiAgICAgICAgICBjb250ZXh0LnJlcG9ydCh7IG5vZGUsIG1lc3NhZ2U6IEVYUE9SVF9NRVNTQUdFIH0pO1xuICAgICAgICB9XG5cbiAgICAgICAgLy8gZXhwb3J0cy5cbiAgICAgICAgaWYgKG5vZGUub2JqZWN0Lm5hbWUgPT09ICdleHBvcnRzJykge1xuICAgICAgICAgIGNvbnN0IGlzSW5TY29wZSA9IGNvbnRleHQuZ2V0U2NvcGUoKVxuICAgICAgICAgICAgLnZhcmlhYmxlc1xuICAgICAgICAgICAgLnNvbWUoKHZhcmlhYmxlKSA9PiB2YXJpYWJsZS5uYW1lID09PSAnZXhwb3J0cycpO1xuICAgICAgICAgIGlmICghaXNJblNjb3BlKSB7XG4gICAgICAgICAgICBjb250ZXh0LnJlcG9ydCh7IG5vZGUsIG1lc3NhZ2U6IEVYUE9SVF9NRVNTQUdFIH0pO1xuICAgICAgICAgIH1cbiAgICAgICAgfVxuXG4gICAgICB9LFxuICAgICAgQ2FsbEV4cHJlc3Npb24oY2FsbCkge1xuICAgICAgICBpZiAoIXZhbGlkYXRlU2NvcGUoY29udGV4dC5nZXRTY29wZSgpKSkgeyByZXR1cm47IH1cblxuICAgICAgICBpZiAoY2FsbC5jYWxsZWUudHlwZSAhPT0gJ0lkZW50aWZpZXInKSB7IHJldHVybjsgfVxuICAgICAgICBpZiAoY2FsbC5jYWxsZWUubmFtZSAhPT0gJ3JlcXVpcmUnKSB7IHJldHVybjsgfVxuXG4gICAgICAgIGlmIChjYWxsLmFyZ3VtZW50cy5sZW5ndGggIT09IDEpIHsgcmV0dXJuOyB9XG4gICAgICAgIGlmICghaXNMaXRlcmFsU3RyaW5nKGNhbGwuYXJndW1lbnRzWzBdKSkgeyByZXR1cm47IH1cblxuICAgICAgICBpZiAoYWxsb3dSZXF1aXJlKGNhbGwsIG9wdGlvbnMpKSB7IHJldHVybjsgfVxuXG4gICAgICAgIGlmIChhbGxvd0NvbmRpdGlvbmFsUmVxdWlyZShjYWxsLCBvcHRpb25zKSAmJiBpc0NvbmRpdGlvbmFsKGNhbGwucGFyZW50KSkgeyByZXR1cm47IH1cblxuICAgICAgICAvLyBrZWVwaW5nIGl0IHNpbXBsZTogYWxsIDEtc3RyaW5nLWFyZyBgcmVxdWlyZWAgY2FsbHMgYXJlIHJlcG9ydGVkXG4gICAgICAgIGNvbnRleHQucmVwb3J0KHtcbiAgICAgICAgICBub2RlOiBjYWxsLmNhbGxlZSxcbiAgICAgICAgICBtZXNzYWdlOiBJTVBPUlRfTUVTU0FHRSxcbiAgICAgICAgfSk7XG4gICAgICB9LFxuICAgIH07XG5cbiAgfSxcbn07XG4iXX0=