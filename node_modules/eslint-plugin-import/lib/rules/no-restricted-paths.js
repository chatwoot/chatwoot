'use strict';var _slicedToArray = function () {function sliceIterator(arr, i) {var _arr = [];var _n = true;var _d = false;var _e = undefined;try {for (var _i = arr[Symbol.iterator](), _s; !(_n = (_s = _i.next()).done); _n = true) {_arr.push(_s.value);if (i && _arr.length === i) break;}} catch (err) {_d = true;_e = err;} finally {try {if (!_n && _i["return"]) _i["return"]();} finally {if (_d) throw _e;}}return _arr;}return function (arr, i) {if (Array.isArray(arr)) {return arr;} else if (Symbol.iterator in Object(arr)) {return sliceIterator(arr, i);} else {throw new TypeError("Invalid attempt to destructure non-iterable instance");}};}();var _containsPath = require('contains-path');var _containsPath2 = _interopRequireDefault(_containsPath);
var _path = require('path');var _path2 = _interopRequireDefault(_path);

var _resolve = require('eslint-module-utils/resolve');var _resolve2 = _interopRequireDefault(_resolve);
var _staticRequire = require('../core/staticRequire');var _staticRequire2 = _interopRequireDefault(_staticRequire);
var _docsUrl = require('../docsUrl');var _docsUrl2 = _interopRequireDefault(_docsUrl);
var _importType = require('../core/importType');var _importType2 = _interopRequireDefault(_importType);function _interopRequireDefault(obj) {return obj && obj.__esModule ? obj : { default: obj };}

module.exports = {
  meta: {
    type: 'problem',
    docs: {
      url: (0, _docsUrl2.default)('no-restricted-paths') },


    schema: [
    {
      type: 'object',
      properties: {
        zones: {
          type: 'array',
          minItems: 1,
          items: {
            type: 'object',
            properties: {
              target: { type: 'string' },
              from: { type: 'string' },
              except: {
                type: 'array',
                items: {
                  type: 'string' },

                uniqueItems: true },

              message: { type: 'string' } },

            additionalProperties: false } },


        basePath: { type: 'string' } },

      additionalProperties: false }] },




  create: function noRestrictedPaths(context) {
    const options = context.options[0] || {};
    const restrictedPaths = options.zones || [];
    const basePath = options.basePath || process.cwd();
    const currentFilename = context.getFilename();
    const matchingZones = restrictedPaths.filter(zone => {
      const targetPath = _path2.default.resolve(basePath, zone.target);

      return (0, _containsPath2.default)(currentFilename, targetPath);
    });

    function isValidExceptionPath(absoluteFromPath, absoluteExceptionPath) {
      const relativeExceptionPath = _path2.default.relative(absoluteFromPath, absoluteExceptionPath);

      return (0, _importType2.default)(relativeExceptionPath, context) !== 'parent';
    }

    function reportInvalidExceptionPath(node) {
      context.report({
        node,
        message: 'Restricted path exceptions must be descendants of the configured `from` path for that zone.' });

    }

    function checkForRestrictedImportPath(importPath, node) {
      const absoluteImportPath = (0, _resolve2.default)(importPath, context);

      if (!absoluteImportPath) {
        return;
      }

      matchingZones.forEach(zone => {
        const exceptionPaths = zone.except || [];
        const absoluteFrom = _path2.default.resolve(basePath, zone.from);

        if (!(0, _containsPath2.default)(absoluteImportPath, absoluteFrom)) {
          return;
        }

        const absoluteExceptionPaths = exceptionPaths.map(exceptionPath =>
        _path2.default.resolve(absoluteFrom, exceptionPath));

        const hasValidExceptionPaths = absoluteExceptionPaths.
        every(absoluteExceptionPath => isValidExceptionPath(absoluteFrom, absoluteExceptionPath));

        if (!hasValidExceptionPaths) {
          reportInvalidExceptionPath(node);
          return;
        }

        const pathIsExcepted = absoluteExceptionPaths.
        some(absoluteExceptionPath => (0, _containsPath2.default)(absoluteImportPath, absoluteExceptionPath));

        if (pathIsExcepted) {
          return;
        }

        context.report({
          node,
          message: `Unexpected path "{{importPath}}" imported in restricted zone.${zone.message ? ` ${zone.message}` : ''}`,
          data: { importPath } });

      });
    }

    return {
      ImportDeclaration(node) {
        checkForRestrictedImportPath(node.source.value, node.source);
      },
      CallExpression(node) {
        if ((0, _staticRequire2.default)(node)) {var _node$arguments = _slicedToArray(
          node.arguments, 1);const firstArgument = _node$arguments[0];

          checkForRestrictedImportPath(firstArgument.value, firstArgument);
        }
      } };

  } };
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIi4uLy4uL3NyYy9ydWxlcy9uby1yZXN0cmljdGVkLXBhdGhzLmpzIl0sIm5hbWVzIjpbIm1vZHVsZSIsImV4cG9ydHMiLCJtZXRhIiwidHlwZSIsImRvY3MiLCJ1cmwiLCJzY2hlbWEiLCJwcm9wZXJ0aWVzIiwiem9uZXMiLCJtaW5JdGVtcyIsIml0ZW1zIiwidGFyZ2V0IiwiZnJvbSIsImV4Y2VwdCIsInVuaXF1ZUl0ZW1zIiwibWVzc2FnZSIsImFkZGl0aW9uYWxQcm9wZXJ0aWVzIiwiYmFzZVBhdGgiLCJjcmVhdGUiLCJub1Jlc3RyaWN0ZWRQYXRocyIsImNvbnRleHQiLCJvcHRpb25zIiwicmVzdHJpY3RlZFBhdGhzIiwicHJvY2VzcyIsImN3ZCIsImN1cnJlbnRGaWxlbmFtZSIsImdldEZpbGVuYW1lIiwibWF0Y2hpbmdab25lcyIsImZpbHRlciIsInpvbmUiLCJ0YXJnZXRQYXRoIiwicGF0aCIsInJlc29sdmUiLCJpc1ZhbGlkRXhjZXB0aW9uUGF0aCIsImFic29sdXRlRnJvbVBhdGgiLCJhYnNvbHV0ZUV4Y2VwdGlvblBhdGgiLCJyZWxhdGl2ZUV4Y2VwdGlvblBhdGgiLCJyZWxhdGl2ZSIsInJlcG9ydEludmFsaWRFeGNlcHRpb25QYXRoIiwibm9kZSIsInJlcG9ydCIsImNoZWNrRm9yUmVzdHJpY3RlZEltcG9ydFBhdGgiLCJpbXBvcnRQYXRoIiwiYWJzb2x1dGVJbXBvcnRQYXRoIiwiZm9yRWFjaCIsImV4Y2VwdGlvblBhdGhzIiwiYWJzb2x1dGVGcm9tIiwiYWJzb2x1dGVFeGNlcHRpb25QYXRocyIsIm1hcCIsImV4Y2VwdGlvblBhdGgiLCJoYXNWYWxpZEV4Y2VwdGlvblBhdGhzIiwiZXZlcnkiLCJwYXRoSXNFeGNlcHRlZCIsInNvbWUiLCJkYXRhIiwiSW1wb3J0RGVjbGFyYXRpb24iLCJzb3VyY2UiLCJ2YWx1ZSIsIkNhbGxFeHByZXNzaW9uIiwiYXJndW1lbnRzIiwiZmlyc3RBcmd1bWVudCJdLCJtYXBwaW5ncyI6InFvQkFBQSw2QztB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WUFBSSxDQUFDZSxzQkFBTCxFQUE2QjtBQUMzQloscUNBQTJCQyxJQUEzQjtBQUNBO0FBQ0Q7O0FBRUQsY0FBTWEsaUJBQWlCTDtBQUNwQk0sWUFEb0IsQ0FDZGxCLHFCQUFELElBQTJCLDRCQUFhUSxrQkFBYixFQUFpQ1IscUJBQWpDLENBRFosQ0FBdkI7O0FBR0EsWUFBSWlCLGNBQUosRUFBb0I7QUFDbEI7QUFDRDs7QUFFRGhDLGdCQUFRb0IsTUFBUixDQUFlO0FBQ2JELGNBRGE7QUFFYnhCLG1CQUFVLGdFQUErRGMsS0FBS2QsT0FBTCxHQUFnQixJQUFHYyxLQUFLZCxPQUFRLEVBQWhDLEdBQW9DLEVBQUcsRUFGbkc7QUFHYnVDLGdCQUFNLEVBQUVaLFVBQUYsRUFITyxFQUFmOztBQUtELE9BL0JEO0FBZ0NIOztBQUVELFdBQU87QUFDTGEsd0JBQWtCaEIsSUFBbEIsRUFBd0I7QUFDdEJFLHFDQUE2QkYsS0FBS2lCLE1BQUwsQ0FBWUMsS0FBekMsRUFBZ0RsQixLQUFLaUIsTUFBckQ7QUFDRCxPQUhJO0FBSUxFLHFCQUFlbkIsSUFBZixFQUFxQjtBQUNuQixZQUFJLDZCQUFnQkEsSUFBaEIsQ0FBSixFQUEyQjtBQUNDQSxlQUFLb0IsU0FETixXQUNqQkMsYUFEaUI7O0FBR3pCbkIsdUNBQTZCbUIsY0FBY0gsS0FBM0MsRUFBa0RHLGFBQWxEO0FBQ0Q7QUFDRixPQVZJLEVBQVA7O0FBWUQsR0FuSGMsRUFBakIiLCJmaWxlIjoibm8tcmVzdHJpY3RlZC1wYXRocy5qcyIsInNvdXJjZXNDb250ZW50IjpbImltcG9ydCBjb250YWluc1BhdGggZnJvbSAnY29udGFpbnMtcGF0aCdcbmltcG9ydCBwYXRoIGZyb20gJ3BhdGgnXG5cbmltcG9ydCByZXNvbHZlIGZyb20gJ2VzbGludC1tb2R1bGUtdXRpbHMvcmVzb2x2ZSdcbmltcG9ydCBpc1N0YXRpY1JlcXVpcmUgZnJvbSAnLi4vY29yZS9zdGF0aWNSZXF1aXJlJ1xuaW1wb3J0IGRvY3NVcmwgZnJvbSAnLi4vZG9jc1VybCdcbmltcG9ydCBpbXBvcnRUeXBlIGZyb20gJy4uL2NvcmUvaW1wb3J0VHlwZSdcblxubW9kdWxlLmV4cG9ydHMgPSB7XG4gIG1ldGE6IHtcbiAgICB0eXBlOiAncHJvYmxlbScsXG4gICAgZG9jczoge1xuICAgICAgdXJsOiBkb2NzVXJsKCduby1yZXN0cmljdGVkLXBhdGhzJyksXG4gICAgfSxcblxuICAgIHNjaGVtYTogW1xuICAgICAge1xuICAgICAgICB0eXBlOiAnb2JqZWN0JyxcbiAgICAgICAgcHJvcGVydGllczoge1xuICAgICAgICAgIHpvbmVzOiB7XG4gICAgICAgICAgICB0eXBlOiAnYXJyYXknLFxuICAgICAgICAgICAgbWluSXRlbXM6IDEsXG4gICAgICAgICAgICBpdGVtczoge1xuICAgICAgICAgICAgICB0eXBlOiAnb2JqZWN0JyxcbiAgICAgICAgICAgICAgcHJvcGVydGllczoge1xuICAgICAgICAgICAgICAgIHRhcmdldDogeyB0eXBlOiAnc3RyaW5nJyB9LFxuICAgICAgICAgICAgICAgIGZyb206IHsgdHlwZTogJ3N0cmluZycgfSxcbiAgICAgICAgICAgICAgICBleGNlcHQ6IHtcbiAgICAgICAgICAgICAgICAgIHR5cGU6ICdhcnJheScsXG4gICAgICAgICAgICAgICAgICBpdGVtczoge1xuICAgICAgICAgICAgICAgICAgICB0eXBlOiAnc3RyaW5nJyxcbiAgICAgICAgICAgICAgICAgIH0sXG4gICAgICAgICAgICAgICAgICB1bmlxdWVJdGVtczogdHJ1ZSxcbiAgICAgICAgICAgICAgICB9LFxuICAgICAgICAgICAgICAgIG1lc3NhZ2U6IHsgdHlwZTogJ3N0cmluZycgfSxcbiAgICAgICAgICAgICAgfSxcbiAgICAgICAgICAgICAgYWRkaXRpb25hbFByb3BlcnRpZXM6IGZhbHNlLFxuICAgICAgICAgICAgfSxcbiAgICAgICAgICB9LFxuICAgICAgICAgIGJhc2VQYXRoOiB7IHR5cGU6ICdzdHJpbmcnIH0sXG4gICAgICAgIH0sXG4gICAgICAgIGFkZGl0aW9uYWxQcm9wZXJ0aWVzOiBmYWxzZSxcbiAgICAgIH0sXG4gICAgXSxcbiAgfSxcblxuICBjcmVhdGU6IGZ1bmN0aW9uIG5vUmVzdHJpY3RlZFBhdGhzKGNvbnRleHQpIHtcbiAgICBjb25zdCBvcHRpb25zID0gY29udGV4dC5vcHRpb25zWzBdIHx8IHt9XG4gICAgY29uc3QgcmVzdHJpY3RlZFBhdGhzID0gb3B0aW9ucy56b25lcyB8fCBbXVxuICAgIGNvbnN0IGJhc2VQYXRoID0gb3B0aW9ucy5iYXNlUGF0aCB8fCBwcm9jZXNzLmN3ZCgpXG4gICAgY29uc3QgY3VycmVudEZpbGVuYW1lID0gY29udGV4dC5nZXRGaWxlbmFtZSgpXG4gICAgY29uc3QgbWF0Y2hpbmdab25lcyA9IHJlc3RyaWN0ZWRQYXRocy5maWx0ZXIoKHpvbmUpID0+IHtcbiAgICAgIGNvbnN0IHRhcmdldFBhdGggPSBwYXRoLnJlc29sdmUoYmFzZVBhdGgsIHpvbmUudGFyZ2V0KVxuXG4gICAgICByZXR1cm4gY29udGFpbnNQYXRoKGN1cnJlbnRGaWxlbmFtZSwgdGFyZ2V0UGF0aClcbiAgICB9KVxuXG4gICAgZnVuY3Rpb24gaXNWYWxpZEV4Y2VwdGlvblBhdGgoYWJzb2x1dGVGcm9tUGF0aCwgYWJzb2x1dGVFeGNlcHRpb25QYXRoKSB7XG4gICAgICBjb25zdCByZWxhdGl2ZUV4Y2VwdGlvblBhdGggPSBwYXRoLnJlbGF0aXZlKGFic29sdXRlRnJvbVBhdGgsIGFic29sdXRlRXhjZXB0aW9uUGF0aClcblxuICAgICAgcmV0dXJuIGltcG9ydFR5cGUocmVsYXRpdmVFeGNlcHRpb25QYXRoLCBjb250ZXh0KSAhPT0gJ3BhcmVudCdcbiAgICB9XG5cbiAgICBmdW5jdGlvbiByZXBvcnRJbnZhbGlkRXhjZXB0aW9uUGF0aChub2RlKSB7XG4gICAgICBjb250ZXh0LnJlcG9ydCh7XG4gICAgICAgIG5vZGUsXG4gICAgICAgIG1lc3NhZ2U6ICdSZXN0cmljdGVkIHBhdGggZXhjZXB0aW9ucyBtdXN0IGJlIGRlc2NlbmRhbnRzIG9mIHRoZSBjb25maWd1cmVkIGBmcm9tYCBwYXRoIGZvciB0aGF0IHpvbmUuJyxcbiAgICAgIH0pXG4gICAgfVxuXG4gICAgZnVuY3Rpb24gY2hlY2tGb3JSZXN0cmljdGVkSW1wb3J0UGF0aChpbXBvcnRQYXRoLCBub2RlKSB7XG4gICAgICAgIGNvbnN0IGFic29sdXRlSW1wb3J0UGF0aCA9IHJlc29sdmUoaW1wb3J0UGF0aCwgY29udGV4dClcblxuICAgICAgICBpZiAoIWFic29sdXRlSW1wb3J0UGF0aCkge1xuICAgICAgICAgIHJldHVyblxuICAgICAgICB9XG5cbiAgICAgICAgbWF0Y2hpbmdab25lcy5mb3JFYWNoKCh6b25lKSA9PiB7XG4gICAgICAgICAgY29uc3QgZXhjZXB0aW9uUGF0aHMgPSB6b25lLmV4Y2VwdCB8fCBbXVxuICAgICAgICAgIGNvbnN0IGFic29sdXRlRnJvbSA9IHBhdGgucmVzb2x2ZShiYXNlUGF0aCwgem9uZS5mcm9tKVxuXG4gICAgICAgICAgaWYgKCFjb250YWluc1BhdGgoYWJzb2x1dGVJbXBvcnRQYXRoLCBhYnNvbHV0ZUZyb20pKSB7XG4gICAgICAgICAgICByZXR1cm5cbiAgICAgICAgICB9XG5cbiAgICAgICAgICBjb25zdCBhYnNvbHV0ZUV4Y2VwdGlvblBhdGhzID0gZXhjZXB0aW9uUGF0aHMubWFwKChleGNlcHRpb25QYXRoKSA9PlxuICAgICAgICAgICAgcGF0aC5yZXNvbHZlKGFic29sdXRlRnJvbSwgZXhjZXB0aW9uUGF0aClcbiAgICAgICAgICApXG4gICAgICAgICAgY29uc3QgaGFzVmFsaWRFeGNlcHRpb25QYXRocyA9IGFic29sdXRlRXhjZXB0aW9uUGF0aHNcbiAgICAgICAgICAgIC5ldmVyeSgoYWJzb2x1dGVFeGNlcHRpb25QYXRoKSA9PiBpc1ZhbGlkRXhjZXB0aW9uUGF0aChhYnNvbHV0ZUZyb20sIGFic29sdXRlRXhjZXB0aW9uUGF0aCkpXG5cbiAgICAgICAgICBpZiAoIWhhc1ZhbGlkRXhjZXB0aW9uUGF0aHMpIHtcbiAgICAgICAgICAgIHJlcG9ydEludmFsaWRFeGNlcHRpb25QYXRoKG5vZGUpXG4gICAgICAgICAgICByZXR1cm5cbiAgICAgICAgICB9XG5cbiAgICAgICAgICBjb25zdCBwYXRoSXNFeGNlcHRlZCA9IGFic29sdXRlRXhjZXB0aW9uUGF0aHNcbiAgICAgICAgICAgIC5zb21lKChhYnNvbHV0ZUV4Y2VwdGlvblBhdGgpID0+IGNvbnRhaW5zUGF0aChhYnNvbHV0ZUltcG9ydFBhdGgsIGFic29sdXRlRXhjZXB0aW9uUGF0aCkpXG5cbiAgICAgICAgICBpZiAocGF0aElzRXhjZXB0ZWQpIHtcbiAgICAgICAgICAgIHJldHVyblxuICAgICAgICAgIH1cblxuICAgICAgICAgIGNvbnRleHQucmVwb3J0KHtcbiAgICAgICAgICAgIG5vZGUsXG4gICAgICAgICAgICBtZXNzYWdlOiBgVW5leHBlY3RlZCBwYXRoIFwie3tpbXBvcnRQYXRofX1cIiBpbXBvcnRlZCBpbiByZXN0cmljdGVkIHpvbmUuJHt6b25lLm1lc3NhZ2UgPyBgICR7em9uZS5tZXNzYWdlfWAgOiAnJ31gLFxuICAgICAgICAgICAgZGF0YTogeyBpbXBvcnRQYXRoIH0sXG4gICAgICAgICAgfSlcbiAgICAgICAgfSlcbiAgICB9XG5cbiAgICByZXR1cm4ge1xuICAgICAgSW1wb3J0RGVjbGFyYXRpb24obm9kZSkge1xuICAgICAgICBjaGVja0ZvclJlc3RyaWN0ZWRJbXBvcnRQYXRoKG5vZGUuc291cmNlLnZhbHVlLCBub2RlLnNvdXJjZSlcbiAgICAgIH0sXG4gICAgICBDYWxsRXhwcmVzc2lvbihub2RlKSB7XG4gICAgICAgIGlmIChpc1N0YXRpY1JlcXVpcmUobm9kZSkpIHtcbiAgICAgICAgICBjb25zdCBbIGZpcnN0QXJndW1lbnQgXSA9IG5vZGUuYXJndW1lbnRzXG5cbiAgICAgICAgICBjaGVja0ZvclJlc3RyaWN0ZWRJbXBvcnRQYXRoKGZpcnN0QXJndW1lbnQudmFsdWUsIGZpcnN0QXJndW1lbnQpXG4gICAgICAgIH1cbiAgICAgIH0sXG4gICAgfVxuICB9LFxufVxuIl19