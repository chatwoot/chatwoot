'use strict';var _path = require('path');var _path2 = _interopRequireDefault(_path);

var _resolve = require('eslint-module-utils/resolve');var _resolve2 = _interopRequireDefault(_resolve);
var _moduleVisitor = require('eslint-module-utils/moduleVisitor');var _moduleVisitor2 = _interopRequireDefault(_moduleVisitor);
var _isGlob = require('is-glob');var _isGlob2 = _interopRequireDefault(_isGlob);
var _minimatch = require('minimatch');
var _docsUrl = require('../docsUrl');var _docsUrl2 = _interopRequireDefault(_docsUrl);
var _importType = require('../core/importType');var _importType2 = _interopRequireDefault(_importType);function _interopRequireDefault(obj) {return obj && obj.__esModule ? obj : { 'default': obj };}

var containsPath = function containsPath(filepath, target) {
  var relative = _path2['default'].relative(target, filepath);
  return relative === '' || !relative.startsWith('..');
};

function isMatchingTargetPath(filename, targetPath) {
  if ((0, _isGlob2['default'])(targetPath)) {
    var mm = new _minimatch.Minimatch(targetPath);
    return mm.match(filename);
  }

  return containsPath(filename, targetPath);
}

module.exports = {
  meta: {
    type: 'problem',
    docs: {
      category: 'Static analysis',
      description: 'Enforce which files can be imported in a given folder.',
      url: (0, _docsUrl2['default'])('no-restricted-paths') },


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
              target: {
                anyOf: [
                { type: 'string' },
                {
                  type: 'array',
                  items: { type: 'string' },
                  uniqueItems: true,
                  minLength: 1 }] },



              from: {
                anyOf: [
                { type: 'string' },
                {
                  type: 'array',
                  items: { type: 'string' },
                  uniqueItems: true,
                  minLength: 1 }] },



              except: {
                type: 'array',
                items: {
                  type: 'string' },

                uniqueItems: true },

              message: { type: 'string' } },

            additionalProperties: false } },


        basePath: { type: 'string' } },

      additionalProperties: false }] },




  create: function () {function noRestrictedPaths(context) {
      var options = context.options[0] || {};
      var restrictedPaths = options.zones || [];
      var basePath = options.basePath || process.cwd();
      var currentFilename = context.getPhysicalFilename ? context.getPhysicalFilename() : context.getFilename();
      var matchingZones = restrictedPaths.filter(
      function (zone) {return [].concat(zone.target).
        map(function (target) {return _path2['default'].resolve(basePath, target);}).
        some(function (targetPath) {return isMatchingTargetPath(currentFilename, targetPath);});});


      function isValidExceptionPath(absoluteFromPath, absoluteExceptionPath) {
        var relativeExceptionPath = _path2['default'].relative(absoluteFromPath, absoluteExceptionPath);

        return (0, _importType2['default'])(relativeExceptionPath, context) !== 'parent';
      }

      function areBothGlobPatternAndAbsolutePath(areGlobPatterns) {
        return areGlobPatterns.some(function (isGlob) {return isGlob;}) && areGlobPatterns.some(function (isGlob) {return !isGlob;});
      }

      function reportInvalidExceptionPath(node) {
        context.report({
          node: node,
          message: 'Restricted path exceptions must be descendants of the configured `from` path for that zone.' });

      }

      function reportInvalidExceptionMixedGlobAndNonGlob(node) {
        context.report({
          node: node,
          message: 'Restricted path `from` must contain either only glob patterns or none' });

      }

      function reportInvalidExceptionGlob(node) {
        context.report({
          node: node,
          message: 'Restricted path exceptions must be glob patterns when `from` contains glob patterns' });

      }

      function computeMixedGlobAndAbsolutePathValidator() {
        return {
          isPathRestricted: function () {function isPathRestricted() {return true;}return isPathRestricted;}(),
          hasValidExceptions: false,
          reportInvalidException: reportInvalidExceptionMixedGlobAndNonGlob };

      }

      function computeGlobPatternPathValidator(absoluteFrom, zoneExcept) {
        var isPathException = void 0;

        var mm = new _minimatch.Minimatch(absoluteFrom);
        var isPathRestricted = function () {function isPathRestricted(absoluteImportPath) {return mm.match(absoluteImportPath);}return isPathRestricted;}();
        var hasValidExceptions = zoneExcept.every(_isGlob2['default']);

        if (hasValidExceptions) {
          var exceptionsMm = zoneExcept.map(function (except) {return new _minimatch.Minimatch(except);});
          isPathException = function () {function isPathException(absoluteImportPath) {return exceptionsMm.some(function (mm) {return mm.match(absoluteImportPath);});}return isPathException;}();
        }

        var reportInvalidException = reportInvalidExceptionGlob;

        return {
          isPathRestricted: isPathRestricted,
          hasValidExceptions: hasValidExceptions,
          isPathException: isPathException,
          reportInvalidException: reportInvalidException };

      }

      function computeAbsolutePathValidator(absoluteFrom, zoneExcept) {
        var isPathException = void 0;

        var isPathRestricted = function () {function isPathRestricted(absoluteImportPath) {return containsPath(absoluteImportPath, absoluteFrom);}return isPathRestricted;}();

        var absoluteExceptionPaths = zoneExcept.
        map(function (exceptionPath) {return _path2['default'].resolve(absoluteFrom, exceptionPath);});
        var hasValidExceptions = absoluteExceptionPaths.
        every(function (absoluteExceptionPath) {return isValidExceptionPath(absoluteFrom, absoluteExceptionPath);});

        if (hasValidExceptions) {
          isPathException = function () {function isPathException(absoluteImportPath) {return absoluteExceptionPaths.some(
              function (absoluteExceptionPath) {return containsPath(absoluteImportPath, absoluteExceptionPath);});}return isPathException;}();

        }

        var reportInvalidException = reportInvalidExceptionPath;

        return {
          isPathRestricted: isPathRestricted,
          hasValidExceptions: hasValidExceptions,
          isPathException: isPathException,
          reportInvalidException: reportInvalidException };

      }

      function reportInvalidExceptions(validators, node) {
        validators.forEach(function (validator) {return validator.reportInvalidException(node);});
      }

      function reportImportsInRestrictedZone(validators, node, importPath, customMessage) {
        validators.forEach(function () {
          context.report({
            node: node,
            message: 'Unexpected path "{{importPath}}" imported in restricted zone.' + (customMessage ? ' ' + String(customMessage) : ''),
            data: { importPath: importPath } });

        });
      }

      var makePathValidators = function () {function makePathValidators(zoneFrom) {var zoneExcept = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : [];
          var allZoneFrom = [].concat(zoneFrom);
          var areGlobPatterns = allZoneFrom.map(_isGlob2['default']);

          if (areBothGlobPatternAndAbsolutePath(areGlobPatterns)) {
            return [computeMixedGlobAndAbsolutePathValidator()];
          }

          var isGlobPattern = areGlobPatterns.every(function (isGlob) {return isGlob;});

          return allZoneFrom.map(function (singleZoneFrom) {
            var absoluteFrom = _path2['default'].resolve(basePath, singleZoneFrom);

            if (isGlobPattern) {
              return computeGlobPatternPathValidator(absoluteFrom, zoneExcept);
            }
            return computeAbsolutePathValidator(absoluteFrom, zoneExcept);
          });
        }return makePathValidators;}();

      var validators = [];

      function checkForRestrictedImportPath(importPath, node) {
        var absoluteImportPath = (0, _resolve2['default'])(importPath, context);

        if (!absoluteImportPath) {
          return;
        }

        matchingZones.forEach(function (zone, index) {
          if (!validators[index]) {
            validators[index] = makePathValidators(zone.from, zone.except);
          }

          var applicableValidatorsForImportPath = validators[index].filter(function (validator) {return validator.isPathRestricted(absoluteImportPath);});

          var validatorsWithInvalidExceptions = applicableValidatorsForImportPath.filter(function (validator) {return !validator.hasValidExceptions;});
          reportInvalidExceptions(validatorsWithInvalidExceptions, node);

          var applicableValidatorsForImportPathExcludingExceptions = applicableValidatorsForImportPath.
          filter(function (validator) {return validator.hasValidExceptions && !validator.isPathException(absoluteImportPath);});
          reportImportsInRestrictedZone(applicableValidatorsForImportPathExcludingExceptions, node, importPath, zone.message);
        });
      }

      return (0, _moduleVisitor2['default'])(function (source) {
        checkForRestrictedImportPath(source.value, source);
      }, { commonjs: true });
    }return noRestrictedPaths;}() };
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIi4uLy4uL3NyYy9ydWxlcy9uby1yZXN0cmljdGVkLXBhdGhzLmpzIl0sIm5hbWVzIjpbImNvbnRhaW5zUGF0aCIsImZpbGVwYXRoIiwidGFyZ2V0IiwicmVsYXRpdmUiLCJwYXRoIiwic3RhcnRzV2l0aCIsImlzTWF0Y2hpbmdUYXJnZXRQYXRoIiwiZmlsZW5hbWUiLCJ0YXJnZXRQYXRoIiwibW0iLCJNaW5pbWF0Y2giLCJtYXRjaCIsIm1vZHVsZSIsImV4cG9ydHMiLCJtZXRhIiwidHlwZSIsImRvY3MiLCJjYXRlZ29yeSIsImRlc2NyaXB0aW9uIiwidXJsIiwic2NoZW1hIiwicHJvcGVydGllcyIsInpvbmVzIiwibWluSXRlbXMiLCJpdGVtcyIsImFueU9mIiwidW5pcXVlSXRlbXMiLCJtaW5MZW5ndGgiLCJmcm9tIiwiZXhjZXB0IiwibWVzc2FnZSIsImFkZGl0aW9uYWxQcm9wZXJ0aWVzIiwiYmFzZVBhdGgiLCJjcmVhdGUiLCJub1Jlc3RyaWN0ZWRQYXRocyIsImNvbnRleHQiLCJvcHRpb25zIiwicmVzdHJpY3RlZFBhdGhzIiwicHJvY2VzcyIsImN3ZCIsImN1cnJlbnRGaWxlbmFtZSIsImdldFBoeXNpY2FsRmlsZW5hbWUiLCJnZXRGaWxlbmFtZSIsIm1hdGNoaW5nWm9uZXMiLCJmaWx0ZXIiLCJ6b25lIiwiY29uY2F0IiwibWFwIiwicmVzb2x2ZSIsInNvbWUiLCJpc1ZhbGlkRXhjZXB0aW9uUGF0aCIsImFic29sdXRlRnJvbVBhdGgiLCJhYnNvbHV0ZUV4Y2VwdGlvblBhdGgiLCJyZWxhdGl2ZUV4Y2VwdGlvblBhdGgiLCJhcmVCb3RoR2xvYlBhdHRlcm5BbmRBYnNvbHV0ZVBhdGgiLCJhcmVHbG9iUGF0dGVybnMiLCJpc0dsb2IiLCJyZXBvcnRJbnZhbGlkRXhjZXB0aW9uUGF0aCIsIm5vZGUiLCJyZXBvcnQiLCJyZXBvcnRJbnZhbGlkRXhjZXB0aW9uTWl4ZWRHbG9iQW5kTm9uR2xvYiIsInJlcG9ydEludmFsaWRFeGNlcHRpb25HbG9iIiwiY29tcHV0ZU1peGVkR2xvYkFuZEFic29sdXRlUGF0aFZhbGlkYXRvciIsImlzUGF0aFJlc3RyaWN0ZWQiLCJoYXNWYWxpZEV4Y2VwdGlvbnMiLCJyZXBvcnRJbnZhbGlkRXhjZXB0aW9uIiwiY29tcHV0ZUdsb2JQYXR0ZXJuUGF0aFZhbGlkYXRvciIsImFic29sdXRlRnJvbSIsInpvbmVFeGNlcHQiLCJpc1BhdGhFeGNlcHRpb24iLCJhYnNvbHV0ZUltcG9ydFBhdGgiLCJldmVyeSIsImV4Y2VwdGlvbnNNbSIsImNvbXB1dGVBYnNvbHV0ZVBhdGhWYWxpZGF0b3IiLCJhYnNvbHV0ZUV4Y2VwdGlvblBhdGhzIiwiZXhjZXB0aW9uUGF0aCIsInJlcG9ydEludmFsaWRFeGNlcHRpb25zIiwidmFsaWRhdG9ycyIsImZvckVhY2giLCJ2YWxpZGF0b3IiLCJyZXBvcnRJbXBvcnRzSW5SZXN0cmljdGVkWm9uZSIsImltcG9ydFBhdGgiLCJjdXN0b21NZXNzYWdlIiwiZGF0YSIsIm1ha2VQYXRoVmFsaWRhdG9ycyIsInpvbmVGcm9tIiwiYWxsWm9uZUZyb20iLCJpc0dsb2JQYXR0ZXJuIiwic2luZ2xlWm9uZUZyb20iLCJjaGVja0ZvclJlc3RyaWN0ZWRJbXBvcnRQYXRoIiwiaW5kZXgiLCJhcHBsaWNhYmxlVmFsaWRhdG9yc0ZvckltcG9ydFBhdGgiLCJ2YWxpZGF0b3JzV2l0aEludmFsaWRFeGNlcHRpb25zIiwiYXBwbGljYWJsZVZhbGlkYXRvcnNGb3JJbXBvcnRQYXRoRXhjbHVkaW5nRXhjZXB0aW9ucyIsInNvdXJjZSIsInZhbHVlIiwiY29tbW9uanMiXSwibWFwcGluZ3MiOiJhQUFBLDRCOztBQUVBLHNEO0FBQ0Esa0U7QUFDQSxpQztBQUNBO0FBQ0EscUM7QUFDQSxnRDs7QUFFQSxJQUFNQSxlQUFlLFNBQWZBLFlBQWUsQ0FBQ0MsUUFBRCxFQUFXQyxNQUFYLEVBQXNCO0FBQ3pDLE1BQU1DLFdBQVdDLGtCQUFLRCxRQUFMLENBQWNELE1BQWQsRUFBc0JELFFBQXRCLENBQWpCO0FBQ0EsU0FBT0UsYUFB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QUEzRztBQUNELFNBYkQ7QUFjRDs7QUFFRCxhQUFPLGdDQUFjLFVBQUNnRSxNQUFELEVBQVk7QUFDL0JMLHFDQUE2QkssT0FBT0MsS0FBcEMsRUFBMkNELE1BQTNDO0FBQ0QsT0FGTSxFQUVKLEVBQUVFLFVBQVUsSUFBWixFQUZJLENBQVA7QUFHRCxLQWhLRCxPQUFpQjlELGlCQUFqQixJQTVEZSxFQUFqQiIsImZpbGUiOiJuby1yZXN0cmljdGVkLXBhdGhzLmpzIiwic291cmNlc0NvbnRlbnQiOlsiaW1wb3J0IHBhdGggZnJvbSAncGF0aCc7XG5cbmltcG9ydCByZXNvbHZlIGZyb20gJ2VzbGludC1tb2R1bGUtdXRpbHMvcmVzb2x2ZSc7XG5pbXBvcnQgbW9kdWxlVmlzaXRvciBmcm9tICdlc2xpbnQtbW9kdWxlLXV0aWxzL21vZHVsZVZpc2l0b3InO1xuaW1wb3J0IGlzR2xvYiBmcm9tICdpcy1nbG9iJztcbmltcG9ydCB7IE1pbmltYXRjaCB9IGZyb20gJ21pbmltYXRjaCc7XG5pbXBvcnQgZG9jc1VybCBmcm9tICcuLi9kb2NzVXJsJztcbmltcG9ydCBpbXBvcnRUeXBlIGZyb20gJy4uL2NvcmUvaW1wb3J0VHlwZSc7XG5cbmNvbnN0IGNvbnRhaW5zUGF0aCA9IChmaWxlcGF0aCwgdGFyZ2V0KSA9PiB7XG4gIGNvbnN0IHJlbGF0aXZlID0gcGF0aC5yZWxhdGl2ZSh0YXJnZXQsIGZpbGVwYXRoKTtcbiAgcmV0dXJuIHJlbGF0aXZlID09PSAnJyB8fCAhcmVsYXRpdmUuc3RhcnRzV2l0aCgnLi4nKTtcbn07XG5cbmZ1bmN0aW9uIGlzTWF0Y2hpbmdUYXJnZXRQYXRoKGZpbGVuYW1lLCB0YXJnZXRQYXRoKSB7XG4gIGlmIChpc0dsb2IodGFyZ2V0UGF0aCkpIHtcbiAgICBjb25zdCBtbSA9IG5ldyBNaW5pbWF0Y2godGFyZ2V0UGF0aCk7XG4gICAgcmV0dXJuIG1tLm1hdGNoKGZpbGVuYW1lKTtcbiAgfVxuXG4gIHJldHVybiBjb250YWluc1BhdGgoZmlsZW5hbWUsIHRhcmdldFBhdGgpO1xufVxuXG5tb2R1bGUuZXhwb3J0cyA9IHtcbiAgbWV0YToge1xuICAgIHR5cGU6ICdwcm9ibGVtJyxcbiAgICBkb2NzOiB7XG4gICAgICBjYXRlZ29yeTogJ1N0YXRpYyBhbmFseXNpcycsXG4gICAgICBkZXNjcmlwdGlvbjogJ0VuZm9yY2Ugd2hpY2ggZmlsZXMgY2FuIGJlIGltcG9ydGVkIGluIGEgZ2l2ZW4gZm9sZGVyLicsXG4gICAgICB1cmw6IGRvY3NVcmwoJ25vLXJlc3RyaWN0ZWQtcGF0aHMnKSxcbiAgICB9LFxuXG4gICAgc2NoZW1hOiBbXG4gICAgICB7XG4gICAgICAgIHR5cGU6ICdvYmplY3QnLFxuICAgICAgICBwcm9wZXJ0aWVzOiB7XG4gICAgICAgICAgem9uZXM6IHtcbiAgICAgICAgICAgIHR5cGU6ICdhcnJheScsXG4gICAgICAgICAgICBtaW5JdGVtczogMSxcbiAgICAgICAgICAgIGl0ZW1zOiB7XG4gICAgICAgICAgICAgIHR5cGU6ICdvYmplY3QnLFxuICAgICAgICAgICAgICBwcm9wZXJ0aWVzOiB7XG4gICAgICAgICAgICAgICAgdGFyZ2V0OiB7XG4gICAgICAgICAgICAgICAgICBhbnlPZjogW1xuICAgICAgICAgICAgICAgICAgICB7IHR5cGU6ICdzdHJpbmcnIH0sXG4gICAgICAgICAgICAgICAgICAgIHtcbiAgICAgICAgICAgICAgICAgICAgICB0eXBlOiAnYXJyYXknLFxuICAgICAgICAgICAgICAgICAgICAgIGl0ZW1zOiB7IHR5cGU6ICdzdHJpbmcnIH0sXG4gICAgICAgICAgICAgICAgICAgICAgdW5pcXVlSXRlbXM6IHRydWUsXG4gICAgICAgICAgICAgICAgICAgICAgbWluTGVuZ3RoOiAxLFxuICAgICAgICAgICAgICAgICAgICB9LFxuICAgICAgICAgICAgICAgICAgXSxcbiAgICAgICAgICAgICAgICB9LFxuICAgICAgICAgICAgICAgIGZyb206IHtcbiAgICAgICAgICAgICAgICAgIGFueU9mOiBbXG4gICAgICAgICAgICAgICAgICAgIHsgdHlwZTogJ3N0cmluZycgfSxcbiAgICAgICAgICAgICAgICAgICAge1xuICAgICAgICAgICAgICAgICAgICAgIHR5cGU6ICdhcnJheScsXG4gICAgICAgICAgICAgICAgICAgICAgaXRlbXM6IHsgdHlwZTogJ3N0cmluZycgfSxcbiAgICAgICAgICAgICAgICAgICAgICB1bmlxdWVJdGVtczogdHJ1ZSxcbiAgICAgICAgICAgICAgICAgICAgICBtaW5MZW5ndGg6IDEsXG4gICAgICAgICAgICAgICAgICAgIH0sXG4gICAgICAgICAgICAgICAgICBdLFxuICAgICAgICAgICAgICAgIH0sXG4gICAgICAgICAgICAgICAgZXhjZXB0OiB7XG4gICAgICAgICAgICAgICAgICB0eXBlOiAnYXJyYXknLFxuICAgICAgICAgICAgICAgICAgaXRlbXM6IHtcbiAgICAgICAgICAgICAgICAgICAgdHlwZTogJ3N0cmluZycsXG4gICAgICAgICAgICAgICAgICB9LFxuICAgICAgICAgICAgICAgICAgdW5pcXVlSXRlbXM6IHRydWUsXG4gICAgICAgICAgICAgICAgfSxcbiAgICAgICAgICAgICAgICBtZXNzYWdlOiB7IHR5cGU6ICdzdHJpbmcnIH0sXG4gICAgICAgICAgICAgIH0sXG4gICAgICAgICAgICAgIGFkZGl0aW9uYWxQcm9wZXJ0aWVzOiBmYWxzZSxcbiAgICAgICAgICAgIH0sXG4gICAgICAgICAgfSxcbiAgICAgICAgICBiYXNlUGF0aDogeyB0eXBlOiAnc3RyaW5nJyB9LFxuICAgICAgICB9LFxuICAgICAgICBhZGRpdGlvbmFsUHJvcGVydGllczogZmFsc2UsXG4gICAgICB9LFxuICAgIF0sXG4gIH0sXG5cbiAgY3JlYXRlOiBmdW5jdGlvbiBub1Jlc3RyaWN0ZWRQYXRocyhjb250ZXh0KSB7XG4gICAgY29uc3Qgb3B0aW9ucyA9IGNvbnRleHQub3B0aW9uc1swXSB8fCB7fTtcbiAgICBjb25zdCByZXN0cmljdGVkUGF0aHMgPSBvcHRpb25zLnpvbmVzIHx8IFtdO1xuICAgIGNvbnN0IGJhc2VQYXRoID0gb3B0aW9ucy5iYXNlUGF0aCB8fCBwcm9jZXNzLmN3ZCgpO1xuICAgIGNvbnN0IGN1cnJlbnRGaWxlbmFtZSA9IGNvbnRleHQuZ2V0UGh5c2ljYWxGaWxlbmFtZSA/IGNvbnRleHQuZ2V0UGh5c2ljYWxGaWxlbmFtZSgpIDogY29udGV4dC5nZXRGaWxlbmFtZSgpO1xuICAgIGNvbnN0IG1hdGNoaW5nWm9uZXMgPSByZXN0cmljdGVkUGF0aHMuZmlsdGVyKFxuICAgICAgKHpvbmUpID0+IFtdLmNvbmNhdCh6b25lLnRhcmdldClcbiAgICAgICAgLm1hcCgodGFyZ2V0KSA9PiBwYXRoLnJlc29sdmUoYmFzZVBhdGgsIHRhcmdldCkpXG4gICAgICAgIC5zb21lKCh0YXJnZXRQYXRoKSA9PiBpc01hdGNoaW5nVGFyZ2V0UGF0aChjdXJyZW50RmlsZW5hbWUsIHRhcmdldFBhdGgpKSxcbiAgICApO1xuXG4gICAgZnVuY3Rpb24gaXNWYWxpZEV4Y2VwdGlvblBhdGgoYWJzb2x1dGVGcm9tUGF0aCwgYWJzb2x1dGVFeGNlcHRpb25QYXRoKSB7XG4gICAgICBjb25zdCByZWxhdGl2ZUV4Y2VwdGlvblBhdGggPSBwYXRoLnJlbGF0aXZlKGFic29sdXRlRnJvbVBhdGgsIGFic29sdXRlRXhjZXB0aW9uUGF0aCk7XG5cbiAgICAgIHJldHVybiBpbXBvcnRUeXBlKHJlbGF0aXZlRXhjZXB0aW9uUGF0aCwgY29udGV4dCkgIT09ICdwYXJlbnQnO1xuICAgIH1cblxuICAgIGZ1bmN0aW9uIGFyZUJvdGhHbG9iUGF0dGVybkFuZEFic29sdXRlUGF0aChhcmVHbG9iUGF0dGVybnMpIHtcbiAgICAgIHJldHVybiBhcmVHbG9iUGF0dGVybnMuc29tZSgoaXNHbG9iKSA9PiBpc0dsb2IpICYmIGFyZUdsb2JQYXR0ZXJucy5zb21lKChpc0dsb2IpID0+ICFpc0dsb2IpO1xuICAgIH1cblxuICAgIGZ1bmN0aW9uIHJlcG9ydEludmFsaWRFeGNlcHRpb25QYXRoKG5vZGUpIHtcbiAgICAgIGNvbnRleHQucmVwb3J0KHtcbiAgICAgICAgbm9kZSxcbiAgICAgICAgbWVzc2FnZTogJ1Jlc3RyaWN0ZWQgcGF0aCBleGNlcHRpb25zIG11c3QgYmUgZGVzY2VuZGFudHMgb2YgdGhlIGNvbmZpZ3VyZWQgYGZyb21gIHBhdGggZm9yIHRoYXQgem9uZS4nLFxuICAgICAgfSk7XG4gICAgfVxuXG4gICAgZnVuY3Rpb24gcmVwb3J0SW52YWxpZEV4Y2VwdGlvbk1peGVkR2xvYkFuZE5vbkdsb2Iobm9kZSkge1xuICAgICAgY29udGV4dC5yZXBvcnQoe1xuICAgICAgICBub2RlLFxuICAgICAgICBtZXNzYWdlOiAnUmVzdHJpY3RlZCBwYXRoIGBmcm9tYCBtdXN0IGNvbnRhaW4gZWl0aGVyIG9ubHkgZ2xvYiBwYXR0ZXJucyBvciBub25lJyxcbiAgICAgIH0pO1xuICAgIH1cblxuICAgIGZ1bmN0aW9uIHJlcG9ydEludmFsaWRFeGNlcHRpb25HbG9iKG5vZGUpIHtcbiAgICAgIGNvbnRleHQucmVwb3J0KHtcbiAgICAgICAgbm9kZSxcbiAgICAgICAgbWVzc2FnZTogJ1Jlc3RyaWN0ZWQgcGF0aCBleGNlcHRpb25zIG11c3QgYmUgZ2xvYiBwYXR0ZXJucyB3aGVuIGBmcm9tYCBjb250YWlucyBnbG9iIHBhdHRlcm5zJyxcbiAgICAgIH0pO1xuICAgIH1cblxuICAgIGZ1bmN0aW9uIGNvbXB1dGVNaXhlZEdsb2JBbmRBYnNvbHV0ZVBhdGhWYWxpZGF0b3IoKSB7XG4gICAgICByZXR1cm4ge1xuICAgICAgICBpc1BhdGhSZXN0cmljdGVkOiAoKSA9PiB0cnVlLFxuICAgICAgICBoYXNWYWxpZEV4Y2VwdGlvbnM6IGZhbHNlLFxuICAgICAgICByZXBvcnRJbnZhbGlkRXhjZXB0aW9uOiByZXBvcnRJbnZhbGlkRXhjZXB0aW9uTWl4ZWRHbG9iQW5kTm9uR2xvYixcbiAgICAgIH07XG4gICAgfVxuXG4gICAgZnVuY3Rpb24gY29tcHV0ZUdsb2JQYXR0ZXJuUGF0aFZhbGlkYXRvcihhYnNvbHV0ZUZyb20sIHpvbmVFeGNlcHQpIHtcbiAgICAgIGxldCBpc1BhdGhFeGNlcHRpb247XG5cbiAgICAgIGNvbnN0IG1tID0gbmV3IE1pbmltYXRjaChhYnNvbHV0ZUZyb20pO1xuICAgICAgY29uc3QgaXNQYXRoUmVzdHJpY3RlZCA9IChhYnNvbHV0ZUltcG9ydFBhdGgpID0+IG1tLm1hdGNoKGFic29sdXRlSW1wb3J0UGF0aCk7XG4gICAgICBjb25zdCBoYXNWYWxpZEV4Y2VwdGlvbnMgPSB6b25lRXhjZXB0LmV2ZXJ5KGlzR2xvYik7XG5cbiAgICAgIGlmIChoYXNWYWxpZEV4Y2VwdGlvbnMpIHtcbiAgICAgICAgY29uc3QgZXhjZXB0aW9uc01tID0gem9uZUV4Y2VwdC5tYXAoKGV4Y2VwdCkgPT4gbmV3IE1pbmltYXRjaChleGNlcHQpKTtcbiAgICAgICAgaXNQYXRoRXhjZXB0aW9uID0gKGFic29sdXRlSW1wb3J0UGF0aCkgPT4gZXhjZXB0aW9uc01tLnNvbWUoKG1tKSA9PiBtbS5tYXRjaChhYnNvbHV0ZUltcG9ydFBhdGgpKTtcbiAgICAgIH1cblxuICAgICAgY29uc3QgcmVwb3J0SW52YWxpZEV4Y2VwdGlvbiA9IHJlcG9ydEludmFsaWRFeGNlcHRpb25HbG9iO1xuXG4gICAgICByZXR1cm4ge1xuICAgICAgICBpc1BhdGhSZXN0cmljdGVkLFxuICAgICAgICBoYXNWYWxpZEV4Y2VwdGlvbnMsXG4gICAgICAgIGlzUGF0aEV4Y2VwdGlvbixcbiAgICAgICAgcmVwb3J0SW52YWxpZEV4Y2VwdGlvbixcbiAgICAgIH07XG4gICAgfVxuXG4gICAgZnVuY3Rpb24gY29tcHV0ZUFic29sdXRlUGF0aFZhbGlkYXRvcihhYnNvbHV0ZUZyb20sIHpvbmVFeGNlcHQpIHtcbiAgICAgIGxldCBpc1BhdGhFeGNlcHRpb247XG5cbiAgICAgIGNvbnN0IGlzUGF0aFJlc3RyaWN0ZWQgPSAoYWJzb2x1dGVJbXBvcnRQYXRoKSA9PiBjb250YWluc1BhdGgoYWJzb2x1dGVJbXBvcnRQYXRoLCBhYnNvbHV0ZUZyb20pO1xuXG4gICAgICBjb25zdCBhYnNvbHV0ZUV4Y2VwdGlvblBhdGhzID0gem9uZUV4Y2VwdFxuICAgICAgICAubWFwKChleGNlcHRpb25QYXRoKSA9PiBwYXRoLnJlc29sdmUoYWJzb2x1dGVGcm9tLCBleGNlcHRpb25QYXRoKSk7XG4gICAgICBjb25zdCBoYXNWYWxpZEV4Y2VwdGlvbnMgPSBhYnNvbHV0ZUV4Y2VwdGlvblBhdGhzXG4gICAgICAgIC5ldmVyeSgoYWJzb2x1dGVFeGNlcHRpb25QYXRoKSA9PiBpc1ZhbGlkRXhjZXB0aW9uUGF0aChhYnNvbHV0ZUZyb20sIGFic29sdXRlRXhjZXB0aW9uUGF0aCkpO1xuXG4gICAgICBpZiAoaGFzVmFsaWRFeGNlcHRpb25zKSB7XG4gICAgICAgIGlzUGF0aEV4Y2VwdGlvbiA9IChhYnNvbHV0ZUltcG9ydFBhdGgpID0+IGFic29sdXRlRXhjZXB0aW9uUGF0aHMuc29tZShcbiAgICAgICAgICAoYWJzb2x1dGVFeGNlcHRpb25QYXRoKSA9PiBjb250YWluc1BhdGgoYWJzb2x1dGVJbXBvcnRQYXRoLCBhYnNvbHV0ZUV4Y2VwdGlvblBhdGgpLFxuICAgICAgICApO1xuICAgICAgfVxuXG4gICAgICBjb25zdCByZXBvcnRJbnZhbGlkRXhjZXB0aW9uID0gcmVwb3J0SW52YWxpZEV4Y2VwdGlvblBhdGg7XG5cbiAgICAgIHJldHVybiB7XG4gICAgICAgIGlzUGF0aFJlc3RyaWN0ZWQsXG4gICAgICAgIGhhc1ZhbGlkRXhjZXB0aW9ucyxcbiAgICAgICAgaXNQYXRoRXhjZXB0aW9uLFxuICAgICAgICByZXBvcnRJbnZhbGlkRXhjZXB0aW9uLFxuICAgICAgfTtcbiAgICB9XG5cbiAgICBmdW5jdGlvbiByZXBvcnRJbnZhbGlkRXhjZXB0aW9ucyh2YWxpZGF0b3JzLCBub2RlKSB7XG4gICAgICB2YWxpZGF0b3JzLmZvckVhY2goKHZhbGlkYXRvcikgPT4gdmFsaWRhdG9yLnJlcG9ydEludmFsaWRFeGNlcHRpb24obm9kZSkpO1xuICAgIH1cblxuICAgIGZ1bmN0aW9uIHJlcG9ydEltcG9ydHNJblJlc3RyaWN0ZWRab25lKHZhbGlkYXRvcnMsIG5vZGUsIGltcG9ydFBhdGgsIGN1c3RvbU1lc3NhZ2UpIHtcbiAgICAgIHZhbGlkYXRvcnMuZm9yRWFjaCgoKSA9PiB7XG4gICAgICAgIGNvbnRleHQucmVwb3J0KHtcbiAgICAgICAgICBub2RlLFxuICAgICAgICAgIG1lc3NhZ2U6IGBVbmV4cGVjdGVkIHBhdGggXCJ7e2ltcG9ydFBhdGh9fVwiIGltcG9ydGVkIGluIHJlc3RyaWN0ZWQgem9uZS4ke2N1c3RvbU1lc3NhZ2UgPyBgICR7Y3VzdG9tTWVzc2FnZX1gIDogJyd9YCxcbiAgICAgICAgICBkYXRhOiB7IGltcG9ydFBhdGggfSxcbiAgICAgICAgfSk7XG4gICAgICB9KTtcbiAgICB9XG5cbiAgICBjb25zdCBtYWtlUGF0aFZhbGlkYXRvcnMgPSAoem9uZUZyb20sIHpvbmVFeGNlcHQgPSBbXSkgPT4ge1xuICAgICAgY29uc3QgYWxsWm9uZUZyb20gPSBbXS5jb25jYXQoem9uZUZyb20pO1xuICAgICAgY29uc3QgYXJlR2xvYlBhdHRlcm5zID0gYWxsWm9uZUZyb20ubWFwKGlzR2xvYik7XG5cbiAgICAgIGlmIChhcmVCb3RoR2xvYlBhdHRlcm5BbmRBYnNvbHV0ZVBhdGgoYXJlR2xvYlBhdHRlcm5zKSkge1xuICAgICAgICByZXR1cm4gW2NvbXB1dGVNaXhlZEdsb2JBbmRBYnNvbHV0ZVBhdGhWYWxpZGF0b3IoKV07XG4gICAgICB9XG5cbiAgICAgIGNvbnN0IGlzR2xvYlBhdHRlcm4gPSBhcmVHbG9iUGF0dGVybnMuZXZlcnkoKGlzR2xvYikgPT4gaXNHbG9iKTtcblxuICAgICAgcmV0dXJuIGFsbFpvbmVGcm9tLm1hcCgoc2luZ2xlWm9uZUZyb20pID0+IHtcbiAgICAgICAgY29uc3QgYWJzb2x1dGVGcm9tID0gcGF0aC5yZXNvbHZlKGJhc2VQYXRoLCBzaW5nbGVab25lRnJvbSk7XG5cbiAgICAgICAgaWYgKGlzR2xvYlBhdHRlcm4pIHtcbiAgICAgICAgICByZXR1cm4gY29tcHV0ZUdsb2JQYXR0ZXJuUGF0aFZhbGlkYXRvcihhYnNvbHV0ZUZyb20sIHpvbmVFeGNlcHQpO1xuICAgICAgICB9XG4gICAgICAgIHJldHVybiBjb21wdXRlQWJzb2x1dGVQYXRoVmFsaWRhdG9yKGFic29sdXRlRnJvbSwgem9uZUV4Y2VwdCk7XG4gICAgICB9KTtcbiAgICB9O1xuXG4gICAgY29uc3QgdmFsaWRhdG9ycyA9IFtdO1xuXG4gICAgZnVuY3Rpb24gY2hlY2tGb3JSZXN0cmljdGVkSW1wb3J0UGF0aChpbXBvcnRQYXRoLCBub2RlKSB7XG4gICAgICBjb25zdCBhYnNvbHV0ZUltcG9ydFBhdGggPSByZXNvbHZlKGltcG9ydFBhdGgsIGNvbnRleHQpO1xuXG4gICAgICBpZiAoIWFic29sdXRlSW1wb3J0UGF0aCkge1xuICAgICAgICByZXR1cm47XG4gICAgICB9XG5cbiAgICAgIG1hdGNoaW5nWm9uZXMuZm9yRWFjaCgoem9uZSwgaW5kZXgpID0+IHtcbiAgICAgICAgaWYgKCF2YWxpZGF0b3JzW2luZGV4XSkge1xuICAgICAgICAgIHZhbGlkYXRvcnNbaW5kZXhdID0gbWFrZVBhdGhWYWxpZGF0b3JzKHpvbmUuZnJvbSwgem9uZS5leGNlcHQpO1xuICAgICAgICB9XG5cbiAgICAgICAgY29uc3QgYXBwbGljYWJsZVZhbGlkYXRvcnNGb3JJbXBvcnRQYXRoID0gdmFsaWRhdG9yc1tpbmRleF0uZmlsdGVyKCh2YWxpZGF0b3IpID0+IHZhbGlkYXRvci5pc1BhdGhSZXN0cmljdGVkKGFic29sdXRlSW1wb3J0UGF0aCkpO1xuXG4gICAgICAgIGNvbnN0IHZhbGlkYXRvcnNXaXRoSW52YWxpZEV4Y2VwdGlvbnMgPSBhcHBsaWNhYmxlVmFsaWRhdG9yc0ZvckltcG9ydFBhdGguZmlsdGVyKCh2YWxpZGF0b3IpID0+ICF2YWxpZGF0b3IuaGFzVmFsaWRFeGNlcHRpb25zKTtcbiAgICAgICAgcmVwb3J0SW52YWxpZEV4Y2VwdGlvbnModmFsaWRhdG9yc1dpdGhJbnZhbGlkRXhjZXB0aW9ucywgbm9kZSk7XG5cbiAgICAgICAgY29uc3QgYXBwbGljYWJsZVZhbGlkYXRvcnNGb3JJbXBvcnRQYXRoRXhjbHVkaW5nRXhjZXB0aW9ucyA9IGFwcGxpY2FibGVWYWxpZGF0b3JzRm9ySW1wb3J0UGF0aFxuICAgICAgICAgIC5maWx0ZXIoKHZhbGlkYXRvcikgPT4gdmFsaWRhdG9yLmhhc1ZhbGlkRXhjZXB0aW9ucyAmJiAhdmFsaWRhdG9yLmlzUGF0aEV4Y2VwdGlvbihhYnNvbHV0ZUltcG9ydFBhdGgpKTtcbiAgICAgICAgcmVwb3J0SW1wb3J0c0luUmVzdHJpY3RlZFpvbmUoYXBwbGljYWJsZVZhbGlkYXRvcnNGb3JJbXBvcnRQYXRoRXhjbHVkaW5nRXhjZXB0aW9ucywgbm9kZSwgaW1wb3J0UGF0aCwgem9uZS5tZXNzYWdlKTtcbiAgICAgIH0pO1xuICAgIH1cblxuICAgIHJldHVybiBtb2R1bGVWaXNpdG9yKChzb3VyY2UpID0+IHtcbiAgICAgIGNoZWNrRm9yUmVzdHJpY3RlZEltcG9ydFBhdGgoc291cmNlLnZhbHVlLCBzb3VyY2UpO1xuICAgIH0sIHsgY29tbW9uanM6IHRydWUgfSk7XG4gIH0sXG59O1xuIl19