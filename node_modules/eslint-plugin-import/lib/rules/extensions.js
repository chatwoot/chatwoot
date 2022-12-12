'use strict';var _path = require('path');var _path2 = _interopRequireDefault(_path);

var _resolve = require('eslint-module-utils/resolve');var _resolve2 = _interopRequireDefault(_resolve);
var _importType = require('../core/importType');
var _docsUrl = require('../docsUrl');var _docsUrl2 = _interopRequireDefault(_docsUrl);function _interopRequireDefault(obj) {return obj && obj.__esModule ? obj : { default: obj };}

const enumValues = { enum: ['always', 'ignorePackages', 'never'] };
const patternProperties = {
  type: 'object',
  patternProperties: { '.*': enumValues } };

const properties = {
  type: 'object',
  properties: {
    'pattern': patternProperties,
    'ignorePackages': { type: 'boolean' } } };



function buildProperties(context) {

  const result = {
    defaultConfig: 'never',
    pattern: {},
    ignorePackages: false };


  context.options.forEach(obj => {

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
      url: (0, _docsUrl2.default)('extensions') },


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





  create: function (context) {

    const props = buildProperties(context);

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
      const extension = _path2.default.extname(file);
      const fileWithoutExtension = file.slice(0, -extension.length);
      const resolvedFileWithoutExtension = (0, _resolve2.default)(fileWithoutExtension, context);

      return resolvedFileWithoutExtension === (0, _resolve2.default)(file, context);
    }

    function isExternalRootModule(file) {
      const slashCount = file.split('/').length - 1;

      if ((0, _importType.isScopedModule)(file) && slashCount <= 1) return true;
      if ((0, _importType.isExternalModule)(file, context, (0, _resolve2.default)(file, context)) && !slashCount) return true;
      return false;
    }

    function checkFileExtension(node) {const
      source = node.source;

      // bail if the declaration doesn't have a source, e.g. "export { foo };"
      if (!source) return;

      const importPathWithQueryString = source.value;

      // don't enforce anything on builtins
      if ((0, _importType.isBuiltIn)(importPathWithQueryString, context.settings)) return;

      const importPath = importPathWithQueryString.replace(/\?(.*)$/, '');

      // don't enforce in root external packages as they may have names with `.js`.
      // Like `import Decimal from decimal.js`)
      if (isExternalRootModule(importPath)) return;

      const resolvedPath = (0, _resolve2.default)(importPath, context);

      // get extension from resolved path, if possible.
      // for unresolved, use source value.
      const extension = _path2.default.extname(resolvedPath || importPath).substring(1);

      // determine if this is a module
      const isPackage = (0, _importType.isExternalModule)(importPath, context.settings) ||
      (0, _importType.isScoped)(importPath);

      if (!extension || !importPath.endsWith(`.${extension}`)) {
        const extensionRequired = isUseOfExtensionRequired(extension, isPackage);
        const extensionForbidden = isUseOfExtensionForbidden(extension);
        if (extensionRequired && !extensionForbidden) {
          context.report({
            node: source,
            message:
            `Missing file extension ${extension ? `"${extension}" ` : ''}for "${importPathWithQueryString}"` });

        }
      } else if (extension) {
        if (isUseOfExtensionForbidden(extension) && isResolvableWithoutExtension(importPath)) {
          context.report({
            node: source,
            message: `Unexpected use of file extension "${extension}" for "${importPathWithQueryString}"` });

        }
      }
    }

    return {
      ImportDeclaration: checkFileExtension,
      ExportNamedDeclaration: checkFileExtension };

  } };
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIi4uLy4uL3NyYy9ydWxlcy9leHRlbnNpb25zLmpzIl0sIm5hbWVzIjpbImVudW1WYWx1ZXMiLCJlbnVtIiwicGF0dGVyblByb3BlcnRpZXMiLCJ0eXBlIiwicHJvcGVydGllcyIsImJ1aWxkUHJvcGVydGllcyIsImNvbnRleHQiLCJyZXN1bHQiLCJkZWZhdWx0Q29uZmlnIiwicGF0dGVybiIsImlnbm9yZVBhY2thZ2VzIiwib3B0aW9ucyIsImZvckVhY2giLCJvYmoiLCJ1bmRlZmluZWQiLCJPYmplY3QiLCJhc3NpZ24iLCJtb2R1bGUiLCJleHBvcnRzIiwibWV0YSIsImRvY3MiLCJ1cmwiLCJzY2hlbWEiLCJhbnlPZiIsIml0ZW1zIiwiYWRkaXRpb25hbEl0ZW1zIiwiY3JlYXRlIiwicHJvcHMiLCJnZXRNb2RpZmllciIsImV4dGVuc2lvbiIsImlzVXNlT2ZFeHRlbnNpb25SZXF1aXJlZCIsImlzUGFja2FnZSIsImlzVXNlT2ZFeHRlbnNpb25Gb3JiaWRkZW4iLCJpc1Jlc29sdmFibGVXaXRob3V0RXh0ZW5zaW9uIiwiZmlsZSIsInBhdGgiLCJleHRuYW1lIiwiZmlsZVdpdGhvdXRFeHRlbnNpb24iLCJzbGljZSIsImxlbmd0aCIsInJlc29sdmVkRmlsZVdpdGhvdXRFeHRlbnNpb24iLCJpc0V4dGVybmFsUm9vdE1vZHVsZSIsInNsYXNoQ291bnQiLCJzcGxpdCIsImNoZWNrRmlsZUV4dGVuc2lvbiIsIm5vZGUiLCJzb3VyY2UiLCJpbXBvcnRQYXRoV2l0aFF1ZXJ5U3RyaW5nIiwidmFsdWUiLCJzZXR0aW5ncyIsImltcG9ydFBhdGgiLCJyZXBsYWNlIiwicmVzb2x2ZWRQYXRoIiwic3Vic3RyaW5nIiwiZW5kc1dpdGgiLCJleHRlbnNpb25SZXF1aXJlZCIsImV4dGVuc2lvbkZvcmJpZGRlbiIsInJlcG9ydCIsIm1lc3NhZ2UiLCJJbXBvcnREZWNsYXJhdGlvbiIsIkV4cG9ydE5hbWVkRGVjbGFyYXRpb24iXSwibWFwcGluZ3MiOiJhQUFBLDRCOztBQUVB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d0JoQixrQkFGbkIsRUFBUDs7QUFJRCxHQS9IYyxFQUFqQiIsImZpbGUiOiJleHRlbnNpb25zLmpzIiwic291cmNlc0NvbnRlbnQiOlsiaW1wb3J0IHBhdGggZnJvbSAncGF0aCdcblxuaW1wb3J0IHJlc29sdmUgZnJvbSAnZXNsaW50LW1vZHVsZS11dGlscy9yZXNvbHZlJ1xuaW1wb3J0IHsgaXNCdWlsdEluLCBpc0V4dGVybmFsTW9kdWxlLCBpc1Njb3BlZCwgaXNTY29wZWRNb2R1bGUgfSBmcm9tICcuLi9jb3JlL2ltcG9ydFR5cGUnXG5pbXBvcnQgZG9jc1VybCBmcm9tICcuLi9kb2NzVXJsJ1xuXG5jb25zdCBlbnVtVmFsdWVzID0geyBlbnVtOiBbICdhbHdheXMnLCAnaWdub3JlUGFja2FnZXMnLCAnbmV2ZXInIF0gfVxuY29uc3QgcGF0dGVyblByb3BlcnRpZXMgPSB7XG4gIHR5cGU6ICdvYmplY3QnLFxuICBwYXR0ZXJuUHJvcGVydGllczogeyAnLionOiBlbnVtVmFsdWVzIH0sXG59XG5jb25zdCBwcm9wZXJ0aWVzID0ge1xuICB0eXBlOiAnb2JqZWN0JyxcbiAgcHJvcGVydGllczoge1xuICAgICdwYXR0ZXJuJzogcGF0dGVyblByb3BlcnRpZXMsXG4gICAgJ2lnbm9yZVBhY2thZ2VzJzogeyB0eXBlOiAnYm9vbGVhbicgfSxcbiAgfSxcbn1cblxuZnVuY3Rpb24gYnVpbGRQcm9wZXJ0aWVzKGNvbnRleHQpIHtcblxuICAgIGNvbnN0IHJlc3VsdCA9IHtcbiAgICAgIGRlZmF1bHRDb25maWc6ICduZXZlcicsXG4gICAgICBwYXR0ZXJuOiB7fSxcbiAgICAgIGlnbm9yZVBhY2thZ2VzOiBmYWxzZSxcbiAgICB9XG5cbiAgICBjb250ZXh0Lm9wdGlvbnMuZm9yRWFjaChvYmogPT4ge1xuXG4gICAgICAvLyBJZiB0aGlzIGlzIGEgc3RyaW5nLCBzZXQgZGVmYXVsdENvbmZpZyB0byBpdHMgdmFsdWVcbiAgICAgIGlmICh0eXBlb2Ygb2JqID09PSAnc3RyaW5nJykge1xuICAgICAgICByZXN1bHQuZGVmYXVsdENvbmZpZyA9IG9ialxuICAgICAgICByZXR1cm5cbiAgICAgIH1cblxuICAgICAgLy8gSWYgdGhpcyBpcyBub3QgdGhlIG5ldyBzdHJ1Y3R1cmUsIHRyYW5zZmVyIGFsbCBwcm9wcyB0byByZXN1bHQucGF0dGVyblxuICAgICAgaWYgKG9iai5wYXR0ZXJuID09PSB1bmRlZmluZWQgJiYgb2JqLmlnbm9yZVBhY2thZ2VzID09PSB1bmRlZmluZWQpIHtcbiAgICAgICAgT2JqZWN0LmFzc2lnbihyZXN1bHQucGF0dGVybiwgb2JqKVxuICAgICAgICByZXR1cm5cbiAgICAgIH1cblxuICAgICAgLy8gSWYgcGF0dGVybiBpcyBwcm92aWRlZCwgdHJhbnNmZXIgYWxsIHByb3BzXG4gICAgICBpZiAob2JqLnBhdHRlcm4gIT09IHVuZGVmaW5lZCkge1xuICAgICAgICBPYmplY3QuYXNzaWduKHJlc3VsdC5wYXR0ZXJuLCBvYmoucGF0dGVybilcbiAgICAgIH1cblxuICAgICAgLy8gSWYgaWdub3JlUGFja2FnZXMgaXMgcHJvdmlkZWQsIHRyYW5zZmVyIGl0IHRvIHJlc3VsdFxuICAgICAgaWYgKG9iai5pZ25vcmVQYWNrYWdlcyAhPT0gdW5kZWZpbmVkKSB7XG4gICAgICAgIHJlc3VsdC5pZ25vcmVQYWNrYWdlcyA9IG9iai5pZ25vcmVQYWNrYWdlc1xuICAgICAgfVxuICAgIH0pXG5cbiAgICBpZiAocmVzdWx0LmRlZmF1bHRDb25maWcgPT09ICdpZ25vcmVQYWNrYWdlcycpIHtcbiAgICAgIHJlc3VsdC5kZWZhdWx0Q29uZmlnID0gJ2Fsd2F5cydcbiAgICAgIHJlc3VsdC5pZ25vcmVQYWNrYWdlcyA9IHRydWVcbiAgICB9XG5cbiAgICByZXR1cm4gcmVzdWx0XG59XG5cbm1vZHVsZS5leHBvcnRzID0ge1xuICBtZXRhOiB7XG4gICAgdHlwZTogJ3N1Z2dlc3Rpb24nLFxuICAgIGRvY3M6IHtcbiAgICAgIHVybDogZG9jc1VybCgnZXh0ZW5zaW9ucycpLFxuICAgIH0sXG5cbiAgICBzY2hlbWE6IHtcbiAgICAgIGFueU9mOiBbXG4gICAgICAgIHtcbiAgICAgICAgICB0eXBlOiAnYXJyYXknLFxuICAgICAgICAgIGl0ZW1zOiBbZW51bVZhbHVlc10sXG4gICAgICAgICAgYWRkaXRpb25hbEl0ZW1zOiBmYWxzZSxcbiAgICAgICAgfSxcbiAgICAgICAge1xuICAgICAgICAgIHR5cGU6ICdhcnJheScsXG4gICAgICAgICAgaXRlbXM6IFtcbiAgICAgICAgICAgIGVudW1WYWx1ZXMsXG4gICAgICAgICAgICBwcm9wZXJ0aWVzLFxuICAgICAgICAgIF0sXG4gICAgICAgICAgYWRkaXRpb25hbEl0ZW1zOiBmYWxzZSxcbiAgICAgICAgfSxcbiAgICAgICAge1xuICAgICAgICAgIHR5cGU6ICdhcnJheScsXG4gICAgICAgICAgaXRlbXM6IFtwcm9wZXJ0aWVzXSxcbiAgICAgICAgICBhZGRpdGlvbmFsSXRlbXM6IGZhbHNlLFxuICAgICAgICB9LFxuICAgICAgICB7XG4gICAgICAgICAgdHlwZTogJ2FycmF5JyxcbiAgICAgICAgICBpdGVtczogW3BhdHRlcm5Qcm9wZXJ0aWVzXSxcbiAgICAgICAgICBhZGRpdGlvbmFsSXRlbXM6IGZhbHNlLFxuICAgICAgICB9LFxuICAgICAgICB7XG4gICAgICAgICAgdHlwZTogJ2FycmF5JyxcbiAgICAgICAgICBpdGVtczogW1xuICAgICAgICAgICAgZW51bVZhbHVlcyxcbiAgICAgICAgICAgIHBhdHRlcm5Qcm9wZXJ0aWVzLFxuICAgICAgICAgIF0sXG4gICAgICAgICAgYWRkaXRpb25hbEl0ZW1zOiBmYWxzZSxcbiAgICAgICAgfSxcbiAgICAgIF0sXG4gICAgfSxcbiAgfSxcblxuICBjcmVhdGU6IGZ1bmN0aW9uIChjb250ZXh0KSB7XG5cbiAgICBjb25zdCBwcm9wcyA9IGJ1aWxkUHJvcGVydGllcyhjb250ZXh0KVxuXG4gICAgZnVuY3Rpb24gZ2V0TW9kaWZpZXIoZXh0ZW5zaW9uKSB7XG4gICAgICByZXR1cm4gcHJvcHMucGF0dGVybltleHRlbnNpb25dIHx8IHByb3BzLmRlZmF1bHRDb25maWdcbiAgICB9XG5cbiAgICBmdW5jdGlvbiBpc1VzZU9mRXh0ZW5zaW9uUmVxdWlyZWQoZXh0ZW5zaW9uLCBpc1BhY2thZ2UpIHtcbiAgICAgIHJldHVybiBnZXRNb2RpZmllcihleHRlbnNpb24pID09PSAnYWx3YXlzJyAmJiAoIXByb3BzLmlnbm9yZVBhY2thZ2VzIHx8ICFpc1BhY2thZ2UpXG4gICAgfVxuXG4gICAgZnVuY3Rpb24gaXNVc2VPZkV4dGVuc2lvbkZvcmJpZGRlbihleHRlbnNpb24pIHtcbiAgICAgIHJldHVybiBnZXRNb2RpZmllcihleHRlbnNpb24pID09PSAnbmV2ZXInXG4gICAgfVxuXG4gICAgZnVuY3Rpb24gaXNSZXNvbHZhYmxlV2l0aG91dEV4dGVuc2lvbihmaWxlKSB7XG4gICAgICBjb25zdCBleHRlbnNpb24gPSBwYXRoLmV4dG5hbWUoZmlsZSlcbiAgICAgIGNvbnN0IGZpbGVXaXRob3V0RXh0ZW5zaW9uID0gZmlsZS5zbGljZSgwLCAtZXh0ZW5zaW9uLmxlbmd0aClcbiAgICAgIGNvbnN0IHJlc29sdmVkRmlsZVdpdGhvdXRFeHRlbnNpb24gPSByZXNvbHZlKGZpbGVXaXRob3V0RXh0ZW5zaW9uLCBjb250ZXh0KVxuXG4gICAgICByZXR1cm4gcmVzb2x2ZWRGaWxlV2l0aG91dEV4dGVuc2lvbiA9PT0gcmVzb2x2ZShmaWxlLCBjb250ZXh0KVxuICAgIH1cblxuICAgIGZ1bmN0aW9uIGlzRXh0ZXJuYWxSb290TW9kdWxlKGZpbGUpIHtcbiAgICAgIGNvbnN0IHNsYXNoQ291bnQgPSBmaWxlLnNwbGl0KCcvJykubGVuZ3RoIC0gMVxuXG4gICAgICBpZiAoaXNTY29wZWRNb2R1bGUoZmlsZSkgJiYgc2xhc2hDb3VudCA8PSAxKSByZXR1cm4gdHJ1ZVxuICAgICAgaWYgKGlzRXh0ZXJuYWxNb2R1bGUoZmlsZSwgY29udGV4dCwgcmVzb2x2ZShmaWxlLCBjb250ZXh0KSkgJiYgIXNsYXNoQ291bnQpIHJldHVybiB0cnVlXG4gICAgICByZXR1cm4gZmFsc2VcbiAgICB9XG5cbiAgICBmdW5jdGlvbiBjaGVja0ZpbGVFeHRlbnNpb24obm9kZSkge1xuICAgICAgY29uc3QgeyBzb3VyY2UgfSA9IG5vZGVcblxuICAgICAgLy8gYmFpbCBpZiB0aGUgZGVjbGFyYXRpb24gZG9lc24ndCBoYXZlIGEgc291cmNlLCBlLmcuIFwiZXhwb3J0IHsgZm9vIH07XCJcbiAgICAgIGlmICghc291cmNlKSByZXR1cm5cblxuICAgICAgY29uc3QgaW1wb3J0UGF0aFdpdGhRdWVyeVN0cmluZyA9IHNvdXJjZS52YWx1ZVxuXG4gICAgICAvLyBkb24ndCBlbmZvcmNlIGFueXRoaW5nIG9uIGJ1aWx0aW5zXG4gICAgICBpZiAoaXNCdWlsdEluKGltcG9ydFBhdGhXaXRoUXVlcnlTdHJpbmcsIGNvbnRleHQuc2V0dGluZ3MpKSByZXR1cm5cblxuICAgICAgY29uc3QgaW1wb3J0UGF0aCA9IGltcG9ydFBhdGhXaXRoUXVlcnlTdHJpbmcucmVwbGFjZSgvXFw/KC4qKSQvLCAnJylcblxuICAgICAgLy8gZG9uJ3QgZW5mb3JjZSBpbiByb290IGV4dGVybmFsIHBhY2thZ2VzIGFzIHRoZXkgbWF5IGhhdmUgbmFtZXMgd2l0aCBgLmpzYC5cbiAgICAgIC8vIExpa2UgYGltcG9ydCBEZWNpbWFsIGZyb20gZGVjaW1hbC5qc2ApXG4gICAgICBpZiAoaXNFeHRlcm5hbFJvb3RNb2R1bGUoaW1wb3J0UGF0aCkpIHJldHVyblxuXG4gICAgICBjb25zdCByZXNvbHZlZFBhdGggPSByZXNvbHZlKGltcG9ydFBhdGgsIGNvbnRleHQpXG5cbiAgICAgIC8vIGdldCBleHRlbnNpb24gZnJvbSByZXNvbHZlZCBwYXRoLCBpZiBwb3NzaWJsZS5cbiAgICAgIC8vIGZvciB1bnJlc29sdmVkLCB1c2Ugc291cmNlIHZhbHVlLlxuICAgICAgY29uc3QgZXh0ZW5zaW9uID0gcGF0aC5leHRuYW1lKHJlc29sdmVkUGF0aCB8fCBpbXBvcnRQYXRoKS5zdWJzdHJpbmcoMSlcblxuICAgICAgLy8gZGV0ZXJtaW5lIGlmIHRoaXMgaXMgYSBtb2R1bGVcbiAgICAgIGNvbnN0IGlzUGFja2FnZSA9IGlzRXh0ZXJuYWxNb2R1bGUoaW1wb3J0UGF0aCwgY29udGV4dC5zZXR0aW5ncylcbiAgICAgICAgfHwgaXNTY29wZWQoaW1wb3J0UGF0aClcblxuICAgICAgaWYgKCFleHRlbnNpb24gfHwgIWltcG9ydFBhdGguZW5kc1dpdGgoYC4ke2V4dGVuc2lvbn1gKSkge1xuICAgICAgICBjb25zdCBleHRlbnNpb25SZXF1aXJlZCA9IGlzVXNlT2ZFeHRlbnNpb25SZXF1aXJlZChleHRlbnNpb24sIGlzUGFja2FnZSlcbiAgICAgICAgY29uc3QgZXh0ZW5zaW9uRm9yYmlkZGVuID0gaXNVc2VPZkV4dGVuc2lvbkZvcmJpZGRlbihleHRlbnNpb24pXG4gICAgICAgIGlmIChleHRlbnNpb25SZXF1aXJlZCAmJiAhZXh0ZW5zaW9uRm9yYmlkZGVuKSB7XG4gICAgICAgICAgY29udGV4dC5yZXBvcnQoe1xuICAgICAgICAgICAgbm9kZTogc291cmNlLFxuICAgICAgICAgICAgbWVzc2FnZTpcbiAgICAgICAgICAgICAgYE1pc3NpbmcgZmlsZSBleHRlbnNpb24gJHtleHRlbnNpb24gPyBgXCIke2V4dGVuc2lvbn1cIiBgIDogJyd9Zm9yIFwiJHtpbXBvcnRQYXRoV2l0aFF1ZXJ5U3RyaW5nfVwiYCxcbiAgICAgICAgICB9KVxuICAgICAgICB9XG4gICAgICB9IGVsc2UgaWYgKGV4dGVuc2lvbikge1xuICAgICAgICBpZiAoaXNVc2VPZkV4dGVuc2lvbkZvcmJpZGRlbihleHRlbnNpb24pICYmIGlzUmVzb2x2YWJsZVdpdGhvdXRFeHRlbnNpb24oaW1wb3J0UGF0aCkpIHtcbiAgICAgICAgICBjb250ZXh0LnJlcG9ydCh7XG4gICAgICAgICAgICBub2RlOiBzb3VyY2UsXG4gICAgICAgICAgICBtZXNzYWdlOiBgVW5leHBlY3RlZCB1c2Ugb2YgZmlsZSBleHRlbnNpb24gXCIke2V4dGVuc2lvbn1cIiBmb3IgXCIke2ltcG9ydFBhdGhXaXRoUXVlcnlTdHJpbmd9XCJgLFxuICAgICAgICAgIH0pXG4gICAgICAgIH1cbiAgICAgIH1cbiAgICB9XG5cbiAgICByZXR1cm4ge1xuICAgICAgSW1wb3J0RGVjbGFyYXRpb246IGNoZWNrRmlsZUV4dGVuc2lvbixcbiAgICAgIEV4cG9ydE5hbWVkRGVjbGFyYXRpb246IGNoZWNrRmlsZUV4dGVuc2lvbixcbiAgICB9XG4gIH0sXG59XG4iXX0=