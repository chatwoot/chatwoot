'use strict';var _path = require('path');var _path2 = _interopRequireDefault(_path);

var _resolve = require('eslint-module-utils/resolve');var _resolve2 = _interopRequireDefault(_resolve);
var _importType = require('../core/importType');
var _moduleVisitor = require('eslint-module-utils/moduleVisitor');var _moduleVisitor2 = _interopRequireDefault(_moduleVisitor);
var _docsUrl = require('../docsUrl');var _docsUrl2 = _interopRequireDefault(_docsUrl);function _interopRequireDefault(obj) {return obj && obj.__esModule ? obj : { 'default': obj };}

var enumValues = { 'enum': ['always', 'ignorePackages', 'never'] };
var patternProperties = {
  type: 'object',
  patternProperties: { '.*': enumValues } };

var properties = {
  type: 'object',
  properties: {
    pattern: patternProperties,
    ignorePackages: { type: 'boolean' } } };



function buildProperties(context) {

  var result = {
    defaultConfig: 'never',
    pattern: {},
    ignorePackages: false };


  context.options.forEach(function (obj) {

    // If this is a string, set defaultConfig to its value
    if (typeof obj === 'string') {
      result.defaultConfig = obj;
      return;
    }

    // If this is not the new structure, transfer all props to result.pattern
    if (obj.pattern === undefined && obj.ignorePackages === undefined) {
      Object.assign(result.pattern, obj);
      return;
    }

    // If pattern is provided, transfer all props
    if (obj.pattern !== undefined) {
      Object.assign(result.pattern, obj.pattern);
    }

    // If ignorePackages is provided, transfer it to result
    if (obj.ignorePackages !== undefined) {
      result.ignorePackages = obj.ignorePackages;
    }
  });

  if (result.defaultConfig === 'ignorePackages') {
    result.defaultConfig = 'always';
    result.ignorePackages = true;
  }

  return result;
}

module.exports = {
  meta: {
    type: 'suggestion',
    docs: {
      category: 'Style guide',
      description: 'Ensure consistent use of file extension within the import path.',
      url: (0, _docsUrl2['default'])('extensions') },


    schema: {
      anyOf: [
      {
        type: 'array',
        items: [enumValues],
        additionalItems: false },

      {
        type: 'array',
        items: [
        enumValues,
        properties],

        additionalItems: false },

      {
        type: 'array',
        items: [properties],
        additionalItems: false },

      {
        type: 'array',
        items: [patternProperties],
        additionalItems: false },

      {
        type: 'array',
        items: [
        enumValues,
        patternProperties],

        additionalItems: false }] } },





  create: function () {function create(context) {

      var props = buildProperties(context);

      function getModifier(extension) {
        return props.pattern[extension] || props.defaultConfig;
      }

      function isUseOfExtensionRequired(extension, isPackage) {
        return getModifier(extension) === 'always' && (!props.ignorePackages || !isPackage);
      }

      function isUseOfExtensionForbidden(extension) {
        return getModifier(extension) === 'never';
      }

      function isResolvableWithoutExtension(file) {
        var extension = _path2['default'].extname(file);
        var fileWithoutExtension = file.slice(0, -extension.length);
        var resolvedFileWithoutExtension = (0, _resolve2['default'])(fileWithoutExtension, context);

        return resolvedFileWithoutExtension === (0, _resolve2['default'])(file, context);
      }

      function isExternalRootModule(file) {
        if (file === '.' || file === '..') {return false;}
        var slashCount = file.split('/').length - 1;

        if (slashCount === 0) {return true;}
        if ((0, _importType.isScoped)(file) && slashCount <= 1) {return true;}
        return false;
      }

      function checkFileExtension(source, node) {
        // bail if the declaration doesn't have a source, e.g. "export { foo };", or if it's only partially typed like in an editor
        if (!source || !source.value) {return;}

        var importPathWithQueryString = source.value;

        // don't enforce anything on builtins
        if ((0, _importType.isBuiltIn)(importPathWithQueryString, context.settings)) {return;}

        var importPath = importPathWithQueryString.replace(/\?(.*)$/, '');

        // don't enforce in root external packages as they may have names with `.js`.
        // Like `import Decimal from decimal.js`)
        if (isExternalRootModule(importPath)) {return;}

        var resolvedPath = (0, _resolve2['default'])(importPath, context);

        // get extension from resolved path, if possible.
        // for unresolved, use source value.
        var extension = _path2['default'].extname(resolvedPath || importPath).substring(1);

        // determine if this is a module
        var isPackage = (0, _importType.isExternalModule)(
        importPath,
        (0, _resolve2['default'])(importPath, context),
        context) ||
        (0, _importType.isScoped)(importPath);

        if (!extension || !importPath.endsWith('.' + String(extension))) {
          // ignore type-only imports and exports
          if (node.importKind === 'type' || node.exportKind === 'type') {return;}
          var extensionRequired = isUseOfExtensionRequired(extension, isPackage);
          var extensionForbidden = isUseOfExtensionForbidden(extension);
          if (extensionRequired && !extensionForbidden) {
            context.report({
              node: source,
              message: 'Missing file extension ' + (
              extension ? '"' + String(extension) + '" ' : '') + 'for "' + String(importPathWithQueryString) + '"' });

          }
        } else if (extension) {
          if (isUseOfExtensionForbidden(extension) && isResolvableWithoutExtension(importPath)) {
            context.report({
              node: source,
              message: 'Unexpected use of file extension "' + String(extension) + '" for "' + String(importPathWithQueryString) + '"' });

          }
        }
      }

      return (0, _moduleVisitor2['default'])(checkFileExtension, { commonjs: true });
    }return create;}() };
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIi4uLy4uL3NyYy9ydWxlcy9leHRlbnNpb25zLmpzIl0sIm5hbWVzIjpbImVudW1WYWx1ZXMiLCJwYXR0ZXJuUHJvcGVydGllcyIsInR5cGUiLCJwcm9wZXJ0aWVzIiwicGF0dGVybiIsImlnbm9yZVBhY2thZ2VzIiwiYnVpbGRQcm9wZXJ0aWVzIiwiY29udGV4dCIsInJlc3VsdCIsImRlZmF1bHRDb25maWciLCJvcHRpb25zIiwiZm9yRWFjaCIsIm9iaiIsInVuZGVmaW5lZCIsIk9iamVjdCIsImFzc2lnbiIsIm1vZHVsZSIsImV4cG9ydHMiLCJtZXRhIiwiZG9jcyIsImNhdGVnb3J5IiwiZGVzY3JpcHRpb24iLCJ1cmwiLCJzY2hlbWEiLCJhbnlPZiIsIml0ZW1zIiwiYWRkaXRpb25hbEl0ZW1zIiwiY3JlYXRlIiwicHJvcHMiLCJnZXRNb2RpZmllciIsImV4dGVuc2lvbiIsImlzVXNlT2ZFeHRlbnNpb25SZXF1aXJlZCIsImlzUGFja2FnZSIsImlzVXNlT2ZFeHRlbnNpb25Gb3JiaWRkZW4iLCJpc1Jlc29sdmFibGVXaXRob3V0RXh0ZW5zaW9uIiwiZmlsZSIsInBhdGgiLCJleHRuYW1lIiwiZmlsZVdpdGhvdXRFeHRlbnNpb24iLCJzbGljZSIsImxlbmd0aCIsInJlc29sdmVkRmlsZVdpdGhvdXRFeHRlbnNpb24iLCJpc0V4dGVybmFsUm9vdE1vZHVsZSIsInNsYXNoQ291bnQiLCJzcGxpdCIsImNoZWNrRmlsZUV4dGVuc2lvbiIsInNvdXJjZSIsIm5vZGUiLCJ2YWx1ZSIsImltcG9ydFBhdGhXaXRoUXVlcnlTdHJpbmciLCJzZXR0aW5ncyIsImltcG9ydFBhdGgiLCJyZXBsYWNlIiwicmVzb2x2ZWRQYXRoIiwic3Vic3RyaW5nIiwiZW5kc1dpdGgiLCJpbXBvcnRLaW5kIiwiZXhwb3J0S2luZCIsImV4dGVuc2lvblJlcXVpcmVkIiwiZXh0ZW5zaW9uRm9yYmlkZGVuIiwicmVwb3J0IiwibWVzc2FnZSIsImNvbW1vbmpzIl0sIm1hcHBpbmdzIjoiYUFB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LGNBQUlHLDBCQUEwQkgsU0FBMUIsS0FBd0NJLDZCQUE2QmlCLFVBQTdCLENBQTVDLEVBQXNGO0FBQ3BGNUMsb0JBQVFxRCxNQUFSLENBQWU7QUFDYmIsb0JBQU1ELE1BRE87QUFFYmUscUVBQThDL0IsU0FBOUMsdUJBQWlFbUIseUJBQWpFLE9BRmEsRUFBZjs7QUFJRDtBQUNGO0FBQ0Y7O0FBRUQsYUFBTyxnQ0FBY0osa0JBQWQsRUFBa0MsRUFBRWlCLFVBQVUsSUFBWixFQUFsQyxDQUFQO0FBQ0QsS0FsSWMsbUJBQWpCIiwiZmlsZSI6ImV4dGVuc2lvbnMuanMiLCJzb3VyY2VzQ29udGVudCI6WyJpbXBvcnQgcGF0aCBmcm9tICdwYXRoJztcblxuaW1wb3J0IHJlc29sdmUgZnJvbSAnZXNsaW50LW1vZHVsZS11dGlscy9yZXNvbHZlJztcbmltcG9ydCB7IGlzQnVpbHRJbiwgaXNFeHRlcm5hbE1vZHVsZSwgaXNTY29wZWQgfSBmcm9tICcuLi9jb3JlL2ltcG9ydFR5cGUnO1xuaW1wb3J0IG1vZHVsZVZpc2l0b3IgZnJvbSAnZXNsaW50LW1vZHVsZS11dGlscy9tb2R1bGVWaXNpdG9yJztcbmltcG9ydCBkb2NzVXJsIGZyb20gJy4uL2RvY3NVcmwnO1xuXG5jb25zdCBlbnVtVmFsdWVzID0geyBlbnVtOiBbJ2Fsd2F5cycsICdpZ25vcmVQYWNrYWdlcycsICduZXZlciddIH07XG5jb25zdCBwYXR0ZXJuUHJvcGVydGllcyA9IHtcbiAgdHlwZTogJ29iamVjdCcsXG4gIHBhdHRlcm5Qcm9wZXJ0aWVzOiB7ICcuKic6IGVudW1WYWx1ZXMgfSxcbn07XG5jb25zdCBwcm9wZXJ0aWVzID0ge1xuICB0eXBlOiAnb2JqZWN0JyxcbiAgcHJvcGVydGllczoge1xuICAgIHBhdHRlcm46IHBhdHRlcm5Qcm9wZXJ0aWVzLFxuICAgIGlnbm9yZVBhY2thZ2VzOiB7IHR5cGU6ICdib29sZWFuJyB9LFxuICB9LFxufTtcblxuZnVuY3Rpb24gYnVpbGRQcm9wZXJ0aWVzKGNvbnRleHQpIHtcblxuICBjb25zdCByZXN1bHQgPSB7XG4gICAgZGVmYXVsdENvbmZpZzogJ25ldmVyJyxcbiAgICBwYXR0ZXJuOiB7fSxcbiAgICBpZ25vcmVQYWNrYWdlczogZmFsc2UsXG4gIH07XG5cbiAgY29udGV4dC5vcHRpb25zLmZvckVhY2goKG9iaikgPT4ge1xuXG4gICAgLy8gSWYgdGhpcyBpcyBhIHN0cmluZywgc2V0IGRlZmF1bHRDb25maWcgdG8gaXRzIHZhbHVlXG4gICAgaWYgKHR5cGVvZiBvYmogPT09ICdzdHJpbmcnKSB7XG4gICAgICByZXN1bHQuZGVmYXVsdENvbmZpZyA9IG9iajtcbiAgICAgIHJldHVybjtcbiAgICB9XG5cbiAgICAvLyBJZiB0aGlzIGlzIG5vdCB0aGUgbmV3IHN0cnVjdHVyZSwgdHJhbnNmZXIgYWxsIHByb3BzIHRvIHJlc3VsdC5wYXR0ZXJuXG4gICAgaWYgKG9iai5wYXR0ZXJuID09PSB1bmRlZmluZWQgJiYgb2JqLmlnbm9yZVBhY2thZ2VzID09PSB1bmRlZmluZWQpIHtcbiAgICAgIE9iamVjdC5hc3NpZ24ocmVzdWx0LnBhdHRlcm4sIG9iaik7XG4gICAgICByZXR1cm47XG4gICAgfVxuXG4gICAgLy8gSWYgcGF0dGVybiBpcyBwcm92aWRlZCwgdHJhbnNmZXIgYWxsIHByb3BzXG4gICAgaWYgKG9iai5wYXR0ZXJuICE9PSB1bmRlZmluZWQpIHtcbiAgICAgIE9iamVjdC5hc3NpZ24ocmVzdWx0LnBhdHRlcm4sIG9iai5wYXR0ZXJuKTtcbiAgICB9XG5cbiAgICAvLyBJZiBpZ25vcmVQYWNrYWdlcyBpcyBwcm92aWRlZCwgdHJhbnNmZXIgaXQgdG8gcmVzdWx0XG4gICAgaWYgKG9iai5pZ25vcmVQYWNrYWdlcyAhPT0gdW5kZWZpbmVkKSB7XG4gICAgICByZXN1bHQuaWdub3JlUGFja2FnZXMgPSBvYmouaWdub3JlUGFja2FnZXM7XG4gICAgfVxuICB9KTtcblxuICBpZiAocmVzdWx0LmRlZmF1bHRDb25maWcgPT09ICdpZ25vcmVQYWNrYWdlcycpIHtcbiAgICByZXN1bHQuZGVmYXVsdENvbmZpZyA9ICdhbHdheXMnO1xuICAgIHJlc3VsdC5pZ25vcmVQYWNrYWdlcyA9IHRydWU7XG4gIH1cblxuICByZXR1cm4gcmVzdWx0O1xufVxuXG5tb2R1bGUuZXhwb3J0cyA9IHtcbiAgbWV0YToge1xuICAgIHR5cGU6ICdzdWdnZXN0aW9uJyxcbiAgICBkb2NzOiB7XG4gICAgICBjYXRlZ29yeTogJ1N0eWxlIGd1aWRlJyxcbiAgICAgIGRlc2NyaXB0aW9uOiAnRW5zdXJlIGNvbnNpc3RlbnQgdXNlIG9mIGZpbGUgZXh0ZW5zaW9uIHdpdGhpbiB0aGUgaW1wb3J0IHBhdGguJyxcbiAgICAgIHVybDogZG9jc1VybCgnZXh0ZW5zaW9ucycpLFxuICAgIH0sXG5cbiAgICBzY2hlbWE6IHtcbiAgICAgIGFueU9mOiBbXG4gICAgICAgIHtcbiAgICAgICAgICB0eXBlOiAnYXJyYXknLFxuICAgICAgICAgIGl0ZW1zOiBbZW51bVZhbHVlc10sXG4gICAgICAgICAgYWRkaXRpb25hbEl0ZW1zOiBmYWxzZSxcbiAgICAgICAgfSxcbiAgICAgICAge1xuICAgICAgICAgIHR5cGU6ICdhcnJheScsXG4gICAgICAgICAgaXRlbXM6IFtcbiAgICAgICAgICAgIGVudW1WYWx1ZXMsXG4gICAgICAgICAgICBwcm9wZXJ0aWVzLFxuICAgICAgICAgIF0sXG4gICAgICAgICAgYWRkaXRpb25hbEl0ZW1zOiBmYWxzZSxcbiAgICAgICAgfSxcbiAgICAgICAge1xuICAgICAgICAgIHR5cGU6ICdhcnJheScsXG4gICAgICAgICAgaXRlbXM6IFtwcm9wZXJ0aWVzXSxcbiAgICAgICAgICBhZGRpdGlvbmFsSXRlbXM6IGZhbHNlLFxuICAgICAgICB9LFxuICAgICAgICB7XG4gICAgICAgICAgdHlwZTogJ2FycmF5JyxcbiAgICAgICAgICBpdGVtczogW3BhdHRlcm5Qcm9wZXJ0aWVzXSxcbiAgICAgICAgICBhZGRpdGlvbmFsSXRlbXM6IGZhbHNlLFxuICAgICAgICB9LFxuICAgICAgICB7XG4gICAgICAgICAgdHlwZTogJ2FycmF5JyxcbiAgICAgICAgICBpdGVtczogW1xuICAgICAgICAgICAgZW51bVZhbHVlcyxcbiAgICAgICAgICAgIHBhdHRlcm5Qcm9wZXJ0aWVzLFxuICAgICAgICAgIF0sXG4gICAgICAgICAgYWRkaXRpb25hbEl0ZW1zOiBmYWxzZSxcbiAgICAgICAgfSxcbiAgICAgIF0sXG4gICAgfSxcbiAgfSxcblxuICBjcmVhdGUoY29udGV4dCkge1xuXG4gICAgY29uc3QgcHJvcHMgPSBidWlsZFByb3BlcnRpZXMoY29udGV4dCk7XG5cbiAgICBmdW5jdGlvbiBnZXRNb2RpZmllcihleHRlbnNpb24pIHtcbiAgICAgIHJldHVybiBwcm9wcy5wYXR0ZXJuW2V4dGVuc2lvbl0gfHwgcHJvcHMuZGVmYXVsdENvbmZpZztcbiAgICB9XG5cbiAgICBmdW5jdGlvbiBpc1VzZU9mRXh0ZW5zaW9uUmVxdWlyZWQoZXh0ZW5zaW9uLCBpc1BhY2thZ2UpIHtcbiAgICAgIHJldHVybiBnZXRNb2RpZmllcihleHRlbnNpb24pID09PSAnYWx3YXlzJyAmJiAoIXByb3BzLmlnbm9yZVBhY2thZ2VzIHx8ICFpc1BhY2thZ2UpO1xuICAgIH1cblxuICAgIGZ1bmN0aW9uIGlzVXNlT2ZFeHRlbnNpb25Gb3JiaWRkZW4oZXh0ZW5zaW9uKSB7XG4gICAgICByZXR1cm4gZ2V0TW9kaWZpZXIoZXh0ZW5zaW9uKSA9PT0gJ25ldmVyJztcbiAgICB9XG5cbiAgICBmdW5jdGlvbiBpc1Jlc29sdmFibGVXaXRob3V0RXh0ZW5zaW9uKGZpbGUpIHtcbiAgICAgIGNvbnN0IGV4dGVuc2lvbiA9IHBhdGguZXh0bmFtZShmaWxlKTtcbiAgICAgIGNvbnN0IGZpbGVXaXRob3V0RXh0ZW5zaW9uID0gZmlsZS5zbGljZSgwLCAtZXh0ZW5zaW9uLmxlbmd0aCk7XG4gICAgICBjb25zdCByZXNvbHZlZEZpbGVXaXRob3V0RXh0ZW5zaW9uID0gcmVzb2x2ZShmaWxlV2l0aG91dEV4dGVuc2lvbiwgY29udGV4dCk7XG5cbiAgICAgIHJldHVybiByZXNvbHZlZEZpbGVXaXRob3V0RXh0ZW5zaW9uID09PSByZXNvbHZlKGZpbGUsIGNvbnRleHQpO1xuICAgIH1cblxuICAgIGZ1bmN0aW9uIGlzRXh0ZXJuYWxSb290TW9kdWxlKGZpbGUpIHtcbiAgICAgIGlmIChmaWxlID09PSAnLicgfHwgZmlsZSA9PT0gJy4uJykgeyByZXR1cm4gZmFsc2U7IH1cbiAgICAgIGNvbnN0IHNsYXNoQ291bnQgPSBmaWxlLnNwbGl0KCcvJykubGVuZ3RoIC0gMTtcblxuICAgICAgaWYgKHNsYXNoQ291bnQgPT09IDApICB7IHJldHVybiB0cnVlOyB9XG4gICAgICBpZiAoaXNTY29wZWQoZmlsZSkgJiYgc2xhc2hDb3VudCA8PSAxKSB7IHJldHVybiB0cnVlOyB9XG4gICAgICByZXR1cm4gZmFsc2U7XG4gICAgfVxuXG4gICAgZnVuY3Rpb24gY2hlY2tGaWxlRXh0ZW5zaW9uKHNvdXJjZSwgbm9kZSkge1xuICAgICAgLy8gYmFpbCBpZiB0aGUgZGVjbGFyYXRpb24gZG9lc24ndCBoYXZlIGEgc291cmNlLCBlLmcuIFwiZXhwb3J0IHsgZm9vIH07XCIsIG9yIGlmIGl0J3Mgb25seSBwYXJ0aWFsbHkgdHlwZWQgbGlrZSBpbiBhbiBlZGl0b3JcbiAgICAgIGlmICghc291cmNlIHx8ICFzb3VyY2UudmFsdWUpIHsgcmV0dXJuOyB9XG5cbiAgICAgIGNvbnN0IGltcG9ydFBhdGhXaXRoUXVlcnlTdHJpbmcgPSBzb3VyY2UudmFsdWU7XG5cbiAgICAgIC8vIGRvbid0IGVuZm9yY2UgYW55dGhpbmcgb24gYnVpbHRpbnNcbiAgICAgIGlmIChpc0J1aWx0SW4oaW1wb3J0UGF0aFdpdGhRdWVyeVN0cmluZywgY29udGV4dC5zZXR0aW5ncykpIHsgcmV0dXJuOyB9XG5cbiAgICAgIGNvbnN0IGltcG9ydFBhdGggPSBpbXBvcnRQYXRoV2l0aFF1ZXJ5U3RyaW5nLnJlcGxhY2UoL1xcPyguKikkLywgJycpO1xuXG4gICAgICAvLyBkb24ndCBlbmZvcmNlIGluIHJvb3QgZXh0ZXJuYWwgcGFja2FnZXMgYXMgdGhleSBtYXkgaGF2ZSBuYW1lcyB3aXRoIGAuanNgLlxuICAgICAgLy8gTGlrZSBgaW1wb3J0IERlY2ltYWwgZnJvbSBkZWNpbWFsLmpzYClcbiAgICAgIGlmIChpc0V4dGVybmFsUm9vdE1vZHVsZShpbXBvcnRQYXRoKSkgeyByZXR1cm47IH1cblxuICAgICAgY29uc3QgcmVzb2x2ZWRQYXRoID0gcmVzb2x2ZShpbXBvcnRQYXRoLCBjb250ZXh0KTtcblxuICAgICAgLy8gZ2V0IGV4dGVuc2lvbiBmcm9tIHJlc29sdmVkIHBhdGgsIGlmIHBvc3NpYmxlLlxuICAgICAgLy8gZm9yIHVucmVzb2x2ZWQsIHVzZSBzb3VyY2UgdmFsdWUuXG4gICAgICBjb25zdCBleHRlbnNpb24gPSBwYXRoLmV4dG5hbWUocmVzb2x2ZWRQYXRoIHx8IGltcG9ydFBhdGgpLnN1YnN0cmluZygxKTtcblxuICAgICAgLy8gZGV0ZXJtaW5lIGlmIHRoaXMgaXMgYSBtb2R1bGVcbiAgICAgIGNvbnN0IGlzUGFja2FnZSA9IGlzRXh0ZXJuYWxNb2R1bGUoXG4gICAgICAgIGltcG9ydFBhdGgsXG4gICAgICAgIHJlc29sdmUoaW1wb3J0UGF0aCwgY29udGV4dCksXG4gICAgICAgIGNvbnRleHQsXG4gICAgICApIHx8IGlzU2NvcGVkKGltcG9ydFBhdGgpO1xuXG4gICAgICBpZiAoIWV4dGVuc2lvbiB8fCAhaW1wb3J0UGF0aC5lbmRzV2l0aChgLiR7ZXh0ZW5zaW9ufWApKSB7XG4gICAgICAgIC8vIGlnbm9yZSB0eXBlLW9ubHkgaW1wb3J0cyBhbmQgZXhwb3J0c1xuICAgICAgICBpZiAobm9kZS5pbXBvcnRLaW5kID09PSAndHlwZScgfHwgbm9kZS5leHBvcnRLaW5kID09PSAndHlwZScpIHsgcmV0dXJuOyB9XG4gICAgICAgIGNvbnN0IGV4dGVuc2lvblJlcXVpcmVkID0gaXNVc2VPZkV4dGVuc2lvblJlcXVpcmVkKGV4dGVuc2lvbiwgaXNQYWNrYWdlKTtcbiAgICAgICAgY29uc3QgZXh0ZW5zaW9uRm9yYmlkZGVuID0gaXNVc2VPZkV4dGVuc2lvbkZvcmJpZGRlbihleHRlbnNpb24pO1xuICAgICAgICBpZiAoZXh0ZW5zaW9uUmVxdWlyZWQgJiYgIWV4dGVuc2lvbkZvcmJpZGRlbikge1xuICAgICAgICAgIGNvbnRleHQucmVwb3J0KHtcbiAgICAgICAgICAgIG5vZGU6IHNvdXJjZSxcbiAgICAgICAgICAgIG1lc3NhZ2U6XG4gICAgICAgICAgICAgIGBNaXNzaW5nIGZpbGUgZXh0ZW5zaW9uICR7ZXh0ZW5zaW9uID8gYFwiJHtleHRlbnNpb259XCIgYCA6ICcnfWZvciBcIiR7aW1wb3J0UGF0aFdpdGhRdWVyeVN0cmluZ31cImAsXG4gICAgICAgICAgfSk7XG4gICAgICAgIH1cbiAgICAgIH0gZWxzZSBpZiAoZXh0ZW5zaW9uKSB7XG4gICAgICAgIGlmIChpc1VzZU9mRXh0ZW5zaW9uRm9yYmlkZGVuKGV4dGVuc2lvbikgJiYgaXNSZXNvbHZhYmxlV2l0aG91dEV4dGVuc2lvbihpbXBvcnRQYXRoKSkge1xuICAgICAgICAgIGNvbnRleHQucmVwb3J0KHtcbiAgICAgICAgICAgIG5vZGU6IHNvdXJjZSxcbiAgICAgICAgICAgIG1lc3NhZ2U6IGBVbmV4cGVjdGVkIHVzZSBvZiBmaWxlIGV4dGVuc2lvbiBcIiR7ZXh0ZW5zaW9ufVwiIGZvciBcIiR7aW1wb3J0UGF0aFdpdGhRdWVyeVN0cmluZ31cImAsXG4gICAgICAgICAgfSk7XG4gICAgICAgIH1cbiAgICAgIH1cbiAgICB9XG5cbiAgICByZXR1cm4gbW9kdWxlVmlzaXRvcihjaGVja0ZpbGVFeHRlbnNpb24sIHsgY29tbW9uanM6IHRydWUgfSk7XG4gIH0sXG59O1xuIl19