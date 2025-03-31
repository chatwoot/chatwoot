'use strict';var _slicedToArray = function () {function sliceIterator(arr, i) {var _arr = [];var _n = true;var _d = false;var _e = undefined;try {for (var _i = arr[Symbol.iterator](), _s; !(_n = (_s = _i.next()).done); _n = true) {_arr.push(_s.value);if (i && _arr.length === i) break;}} catch (err) {_d = true;_e = err;} finally {try {if (!_n && _i["return"]) _i["return"]();} finally {if (_d) throw _e;}}return _arr;}return function (arr, i) {if (Array.isArray(arr)) {return arr;} else if (Symbol.iterator in Object(arr)) {return sliceIterator(arr, i);} else {throw new TypeError("Invalid attempt to destructure non-iterable instance");}};}();var _path = require('path');var path = _interopRequireWildcard(_path);
var _builder = require('../exportMap/builder');var _builder2 = _interopRequireDefault(_builder);
var _docsUrl = require('../docsUrl');var _docsUrl2 = _interopRequireDefault(_docsUrl);function _interopRequireDefault(obj) {return obj && obj.__esModule ? obj : { 'default': obj };}function _interopRequireWildcard(obj) {if (obj && obj.__esModule) {return obj;} else {var newObj = {};if (obj != null) {for (var key in obj) {if (Object.prototype.hasOwnProperty.call(obj, key)) newObj[key] = obj[key];}}newObj['default'] = obj;return newObj;}}

module.exports = {
  meta: {
    type: 'problem',
    docs: {
      category: 'Static analysis',
      description: 'Ensure named imports correspond to a named export in the remote file.',
      url: (0, _docsUrl2['default'])('named') },

    schema: [
    {
      type: 'object',
      properties: {
        commonjs: {
          type: 'boolean' } },


      additionalProperties: false }] },




  create: function () {function create(context) {
      var options = context.options[0] || {};

      function checkSpecifiers(key, type, node) {
        // ignore local exports and type imports/exports
        if (
        node.source == null ||
        node.importKind === 'type' ||
        node.importKind === 'typeof' ||
        node.exportKind === 'type')
        {
          return;
        }

        if (!node.specifiers.some(function (im) {return im.type === type;})) {
          return; // no named imports/exports
        }

        var imports = _builder2['default'].get(node.source.value, context);
        if (imports == null || imports.parseGoal === 'ambiguous') {
          return;
        }

        if (imports.errors.length) {
          imports.reportErrors(context, node);
          return;
        }

        node.specifiers.forEach(function (im) {
          if (
          im.type !== type
          // ignore type imports
          || im.importKind === 'type' || im.importKind === 'typeof')
          {
            return;
          }

          var name = im[key].name || im[key].value;

          var deepLookup = imports.hasDeep(name);

          if (!deepLookup.found) {
            if (deepLookup.path.length > 1) {
              var deepPath = deepLookup.path.
              map(function (i) {return path.relative(path.dirname(context.getPhysicalFilename ? context.getPhysicalFilename() : context.getFilename()), i.path);}).
              join(' -> ');

              context.report(im[key], String(name) + ' not found via ' + String(deepPath));
            } else {
              context.report(im[key], String(name) + ' not found in \'' + String(node.source.value) + '\'');
            }
          }
        });
      }

      function checkRequire(node) {
        if (
        !options.commonjs ||
        node.type !== 'VariableDeclarator'
        // return if it's not an object destructure or it's an empty object destructure
        || !node.id || node.id.type !== 'ObjectPattern' || node.id.properties.length === 0
        // return if there is no call expression on the right side
        || !node.init || node.init.type !== 'CallExpression')
        {
          return;
        }

        var call = node.init;var _call$arguments = _slicedToArray(
        call.arguments, 1),source = _call$arguments[0];
        var variableImports = node.id.properties;
        var variableExports = _builder2['default'].get(source.value, context);

        if (
        // return if it's not a commonjs require statement
        call.callee.type !== 'Identifier' || call.callee.name !== 'require' || call.arguments.length !== 1
        // return if it's not a string source
        || source.type !== 'Literal' ||
        variableExports == null ||
        variableExports.parseGoal === 'ambiguous')
        {
          return;
        }

        if (variableExports.errors.length) {
          variableExports.reportErrors(context, node);
          return;
        }

        variableImports.forEach(function (im) {
          if (im.type !== 'Property' || !im.key || im.key.type !== 'Identifier') {
            return;
          }

          var deepLookup = variableExports.hasDeep(im.key.name);

          if (!deepLookup.found) {
            if (deepLookup.path.length > 1) {
              var deepPath = deepLookup.path.
              map(function (i) {return path.relative(path.dirname(context.getFilename()), i.path);}).
              join(' -> ');

              context.report(im.key, String(im.key.name) + ' not found via ' + String(deepPath));
            } else {
              context.report(im.key, String(im.key.name) + ' not found in \'' + String(source.value) + '\'');
            }
          }
        });
      }

      return {
        ImportDeclaration: checkSpecifiers.bind(null, 'imported', 'ImportSpecifier'),

        ExportNamedDeclaration: checkSpecifiers.bind(null, 'local', 'ExportSpecifier'),

        VariableDeclarator: checkRequire };

    }return create;}() };
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIi4uLy4uL3NyYy9ydWxlcy9uYW1lZC5qcyJdLCJuYW1lcyI6WyJwYXRoIiwibW9kdWxlIiwiZXhwb3J0cyIsIm1ldGEiLCJ0eXBlIiwiZG9jcyIsImNhdGVnb3J5IiwiZGVzY3JpcHRpb24iLCJ1cmwiLCJzY2hlbWEiLCJwcm9wZXJ0aWVzIiwiY29tbW9uanMiLCJhZGRpdGlvbmFsUHJvcGVydGllcyIsImNyZWF0ZSIsImNvbnRleHQiLCJvcHRpb25zIiwiY2hlY2tTcGVjaWZpZXJzIiwia2V5Iiwibm9kZSIsInNvdXJjZSIsImltcG9ydEtpbmQiLCJleHBvcnRLaW5kIiwic3BlY2lmaWVycyIsInNvbWUiLCJpbSIsImltcG9ydHMiLCJFeHBvcnRNYXBCdWlsZGVyIiwiZ2V0IiwidmFsdWUiLCJwYXJzZUdvYWwiLCJlcnJvcnMiLCJsZW5ndGgiLCJyZXBvcnRFcnJvcnMiLCJmb3JFYWNoIiwibmFtZSIsImRlZXBMb29rdXAiLCJoYXNEZWVwIiwiZm91bmQiLCJkZWVwUGF0aCIsIm1hcCIsImkiLCJyZWxhdGl2ZSIsImRpcm5hbWUiLCJnZXRQaHlzaWNhbEZpbGVuYW1lIiwiZ2V0RmlsZW5hbWUiLCJqb2luIiwicmVwb3J0IiwiY2hlY2tSZXF1aXJlIiwiaWQiLCJpbml0IiwiY2FsbCIsImFyZ3VtZW50cyIsInZhcmlhYmxlSW1wb3J0cyIsInZhcmlhYmxlRXhwb3J0cyIsImNhbGxlZSIsIkltcG9ydERlY2xhcmF0aW9uIiwiYmluZCIsIkV4cG9ydE5hbWVkRGVjbGFyYXRpb24iLCJWYXJpYWJsZURlY2xhcmF0b3IiXSwibWFwcGluZ3MiOiJxb0JBQUEsNEIsSUFBWUEsSTtBQUNaLCtDO0FBQ0EscUM7O0FBRUFDLE9BQU9DLE9BQVAsR0FBaUI7QUFDZkMsUUFBTTtBQUNKQyxVQUFNLFNBREY7QUFFSkMsVUFBTTtBQUNKQyxnQkFBVSxpQkFETjtBQUVKQyxtQkFBYSx1RUFGVDtBQUdKQyxXQUFLLDBCQUFRLE9BQVIsQ0FIRCxFQUZGOztBQU9KQyxZQUFRO0FB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LEVBQXVCO0FBQ3JCLGdCQUFJRixXQUFXbkMsSUFBWCxDQUFnQitCLE1BQWhCLEdBQXlCLENBQTdCLEVBQWdDO0FBQzlCLGtCQUFNTyxXQUFXSCxXQUFXbkMsSUFBWDtBQUNkdUMsaUJBRGMsQ0FDVixVQUFDQyxDQUFELFVBQU94QyxLQUFLeUMsUUFBTCxDQUFjekMsS0FBSzBDLE9BQUwsQ0FBYTVCLFFBQVE4QixXQUFSLEVBQWIsQ0FBZCxFQUFtREosRUFBRXhDLElBQXJELENBQVAsRUFEVTtBQUVkNkMsa0JBRmMsQ0FFVCxNQUZTLENBQWpCOztBQUlBL0Isc0JBQVFnQyxNQUFSLENBQWV0QixHQUFHUCxHQUFsQixTQUEwQk8sR0FBR1AsR0FBSCxDQUFPaUIsSUFBakMsK0JBQXVESSxRQUF2RDtBQUNELGFBTkQsTUFNTztBQUNMeEIsc0JBQVFnQyxNQUFSLENBQWV0QixHQUFHUCxHQUFsQixTQUEwQk8sR0FBR1AsR0FBSCxDQUFPaUIsSUFBakMsZ0NBQXVEZixPQUFPUyxLQUE5RDtBQUNEO0FBQ0Y7QUFDRixTQWxCRDtBQW1CRDs7QUFFRCxhQUFPO0FBQ0wyQiwyQkFBbUJ2QyxnQkFBZ0J3QyxJQUFoQixDQUFxQixJQUFyQixFQUEyQixVQUEzQixFQUF1QyxpQkFBdkMsQ0FEZDs7QUFHTEMsZ0NBQXdCekMsZ0JBQWdCd0MsSUFBaEIsQ0FBcUIsSUFBckIsRUFBMkIsT0FBM0IsRUFBb0MsaUJBQXBDLENBSG5COztBQUtMRSw0QkFBb0JYLFlBTGYsRUFBUDs7QUFPRCxLQXpJYyxtQkFBakIiLCJmaWxlIjoibmFtZWQuanMiLCJzb3VyY2VzQ29udGVudCI6WyJpbXBvcnQgKiBhcyBwYXRoIGZyb20gJ3BhdGgnO1xuaW1wb3J0IEV4cG9ydE1hcEJ1aWxkZXIgZnJvbSAnLi4vZXhwb3J0TWFwL2J1aWxkZXInO1xuaW1wb3J0IGRvY3NVcmwgZnJvbSAnLi4vZG9jc1VybCc7XG5cbm1vZHVsZS5leHBvcnRzID0ge1xuICBtZXRhOiB7XG4gICAgdHlwZTogJ3Byb2JsZW0nLFxuICAgIGRvY3M6IHtcbiAgICAgIGNhdGVnb3J5OiAnU3RhdGljIGFuYWx5c2lzJyxcbiAgICAgIGRlc2NyaXB0aW9uOiAnRW5zdXJlIG5hbWVkIGltcG9ydHMgY29ycmVzcG9uZCB0byBhIG5hbWVkIGV4cG9ydCBpbiB0aGUgcmVtb3RlIGZpbGUuJyxcbiAgICAgIHVybDogZG9jc1VybCgnbmFtZWQnKSxcbiAgICB9LFxuICAgIHNjaGVtYTogW1xuICAgICAge1xuICAgICAgICB0eXBlOiAnb2JqZWN0JyxcbiAgICAgICAgcHJvcGVydGllczoge1xuICAgICAgICAgIGNvbW1vbmpzOiB7XG4gICAgICAgICAgICB0eXBlOiAnYm9vbGVhbicsXG4gICAgICAgICAgfSxcbiAgICAgICAgfSxcbiAgICAgICAgYWRkaXRpb25hbFByb3BlcnRpZXM6IGZhbHNlLFxuICAgICAgfSxcbiAgICBdLFxuICB9LFxuXG4gIGNyZWF0ZShjb250ZXh0KSB7XG4gICAgY29uc3Qgb3B0aW9ucyA9IGNvbnRleHQub3B0aW9uc1swXSB8fCB7fTtcblxuICAgIGZ1bmN0aW9uIGNoZWNrU3BlY2lmaWVycyhrZXksIHR5cGUsIG5vZGUpIHtcbiAgICAgIC8vIGlnbm9yZSBsb2NhbCBleHBvcnRzIGFuZCB0eXBlIGltcG9ydHMvZXhwb3J0c1xuICAgICAgaWYgKFxuICAgICAgICBub2RlLnNvdXJjZSA9PSBudWxsXG4gICAgICAgIHx8IG5vZGUuaW1wb3J0S2luZCA9PT0gJ3R5cGUnXG4gICAgICAgIHx8IG5vZGUuaW1wb3J0S2luZCA9PT0gJ3R5cGVvZidcbiAgICAgICAgfHwgbm9kZS5leHBvcnRLaW5kID09PSAndHlwZSdcbiAgICAgICkge1xuICAgICAgICByZXR1cm47XG4gICAgICB9XG5cbiAgICAgIGlmICghbm9kZS5zcGVjaWZpZXJzLnNvbWUoKGltKSA9PiBpbS50eXBlID09PSB0eXBlKSkge1xuICAgICAgICByZXR1cm47IC8vIG5vIG5hbWVkIGltcG9ydHMvZXhwb3J0c1xuICAgICAgfVxuXG4gICAgICBjb25zdCBpbXBvcnRzID0gRXhwb3J0TWFwQnVpbGRlci5nZXQobm9kZS5zb3VyY2UudmFsdWUsIGNvbnRleHQpO1xuICAgICAgaWYgKGltcG9ydHMgPT0gbnVsbCB8fCBpbXBvcnRzLnBhcnNlR29hbCA9PT0gJ2FtYmlndW91cycpIHtcbiAgICAgICAgcmV0dXJuO1xuICAgICAgfVxuXG4gICAgICBpZiAoaW1wb3J0cy5lcnJvcnMubGVuZ3RoKSB7XG4gICAgICAgIGltcG9ydHMucmVwb3J0RXJyb3JzKGNvbnRleHQsIG5vZGUpO1xuICAgICAgICByZXR1cm47XG4gICAgICB9XG5cbiAgICAgIG5vZGUuc3BlY2lmaWVycy5mb3JFYWNoKGZ1bmN0aW9uIChpbSkge1xuICAgICAgICBpZiAoXG4gICAgICAgICAgaW0udHlwZSAhPT0gdHlwZVxuICAgICAgICAgIC8vIGlnbm9yZSB0eXBlIGltcG9ydHNcbiAgICAgICAgICB8fCBpbS5pbXBvcnRLaW5kID09PSAndHlwZScgfHwgaW0uaW1wb3J0S2luZCA9PT0gJ3R5cGVvZidcbiAgICAgICAgKSB7XG4gICAgICAgICAgcmV0dXJuO1xuICAgICAgICB9XG5cbiAgICAgICAgY29uc3QgbmFtZSA9IGltW2tleV0ubmFtZSB8fCBpbVtrZXldLnZhbHVlO1xuXG4gICAgICAgIGNvbnN0IGRlZXBMb29rdXAgPSBpbXBvcnRzLmhhc0RlZXAobmFtZSk7XG5cbiAgICAgICAgaWYgKCFkZWVwTG9va3VwLmZvdW5kKSB7XG4gICAgICAgICAgaWYgKGRlZXBMb29rdXAucGF0aC5sZW5ndGggPiAxKSB7XG4gICAgICAgICAgICBjb25zdCBkZWVwUGF0aCA9IGRlZXBMb29rdXAucGF0aFxuICAgICAgICAgICAgICAubWFwKChpKSA9PiBwYXRoLnJlbGF0aXZlKHBhdGguZGlybmFtZShjb250ZXh0LmdldFBoeXNpY2FsRmlsZW5hbWUgPyBjb250ZXh0LmdldFBoeXNpY2FsRmlsZW5hbWUoKSA6IGNvbnRleHQuZ2V0RmlsZW5hbWUoKSksIGkucGF0aCkpXG4gICAgICAgICAgICAgIC5qb2luKCcgLT4gJyk7XG5cbiAgICAgICAgICAgIGNvbnRleHQucmVwb3J0KGltW2tleV0sIGAke25hbWV9IG5vdCBmb3VuZCB2aWEgJHtkZWVwUGF0aH1gKTtcbiAgICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgICAgY29udGV4dC5yZXBvcnQoaW1ba2V5XSwgYCR7bmFtZX0gbm90IGZvdW5kIGluICcke25vZGUuc291cmNlLnZhbHVlfSdgKTtcbiAgICAgICAgICB9XG4gICAgICAgIH1cbiAgICAgIH0pO1xuICAgIH1cblxuICAgIGZ1bmN0aW9uIGNoZWNrUmVxdWlyZShub2RlKSB7XG4gICAgICBpZiAoXG4gICAgICAgICFvcHRpb25zLmNvbW1vbmpzXG4gICAgICAgIHx8IG5vZGUudHlwZSAhPT0gJ1ZhcmlhYmxlRGVjbGFyYXRvcidcbiAgICAgICAgLy8gcmV0dXJuIGlmIGl0J3Mgbm90IGFuIG9iamVjdCBkZXN0cnVjdHVyZSBvciBpdCdzIGFuIGVtcHR5IG9iamVjdCBkZXN0cnVjdHVyZVxuICAgICAgICB8fCAhbm9kZS5pZCB8fCBub2RlLmlkLnR5cGUgIT09ICdPYmplY3RQYXR0ZXJuJyB8fCBub2RlLmlkLnByb3BlcnRpZXMubGVuZ3RoID09PSAwXG4gICAgICAgIC8vIHJldHVybiBpZiB0aGVyZSBpcyBubyBjYWxsIGV4cHJlc3Npb24gb24gdGhlIHJpZ2h0IHNpZGVcbiAgICAgICAgfHwgIW5vZGUuaW5pdCB8fCBub2RlLmluaXQudHlwZSAhPT0gJ0NhbGxFeHByZXNzaW9uJ1xuICAgICAgKSB7XG4gICAgICAgIHJldHVybjtcbiAgICAgIH1cblxuICAgICAgY29uc3QgY2FsbCA9IG5vZGUuaW5pdDtcbiAgICAgIGNvbnN0IFtzb3VyY2VdID0gY2FsbC5hcmd1bWVudHM7XG4gICAgICBjb25zdCB2YXJpYWJsZUltcG9ydHMgPSBub2RlLmlkLnByb3BlcnRpZXM7XG4gICAgICBjb25zdCB2YXJpYWJsZUV4cG9ydHMgPSBFeHBvcnRNYXBCdWlsZGVyLmdldChzb3VyY2UudmFsdWUsIGNvbnRleHQpO1xuXG4gICAgICBpZiAoXG4gICAgICAgIC8vIHJldHVybiBpZiBpdCdzIG5vdCBhIGNvbW1vbmpzIHJlcXVpcmUgc3RhdGVtZW50XG4gICAgICAgIGNhbGwuY2FsbGVlLnR5cGUgIT09ICdJZGVudGlmaWVyJyB8fCBjYWxsLmNhbGxlZS5uYW1lICE9PSAncmVxdWlyZScgfHwgY2FsbC5hcmd1bWVudHMubGVuZ3RoICE9PSAxXG4gICAgICAgIC8vIHJldHVybiBpZiBpdCdzIG5vdCBhIHN0cmluZyBzb3VyY2VcbiAgICAgICAgfHwgc291cmNlLnR5cGUgIT09ICdMaXRlcmFsJ1xuICAgICAgICB8fCB2YXJpYWJsZUV4cG9ydHMgPT0gbnVsbFxuICAgICAgICB8fCB2YXJpYWJsZUV4cG9ydHMucGFyc2VHb2FsID09PSAnYW1iaWd1b3VzJ1xuICAgICAgKSB7XG4gICAgICAgIHJldHVybjtcbiAgICAgIH1cblxuICAgICAgaWYgKHZhcmlhYmxlRXhwb3J0cy5lcnJvcnMubGVuZ3RoKSB7XG4gICAgICAgIHZhcmlhYmxlRXhwb3J0cy5yZXBvcnRFcnJvcnMoY29udGV4dCwgbm9kZSk7XG4gICAgICAgIHJldHVybjtcbiAgICAgIH1cblxuICAgICAgdmFyaWFibGVJbXBvcnRzLmZvckVhY2goZnVuY3Rpb24gKGltKSB7XG4gICAgICAgIGlmIChpbS50eXBlICE9PSAnUHJvcGVydHknIHx8ICFpbS5rZXkgfHwgaW0ua2V5LnR5cGUgIT09ICdJZGVudGlmaWVyJykge1xuICAgICAgICAgIHJldHVybjtcbiAgICAgICAgfVxuXG4gICAgICAgIGNvbnN0IGRlZXBMb29rdXAgPSB2YXJpYWJsZUV4cG9ydHMuaGFzRGVlcChpbS5rZXkubmFtZSk7XG5cbiAgICAgICAgaWYgKCFkZWVwTG9va3VwLmZvdW5kKSB7XG4gICAgICAgICAgaWYgKGRlZXBMb29rdXAucGF0aC5sZW5ndGggPiAxKSB7XG4gICAgICAgICAgICBjb25zdCBkZWVwUGF0aCA9IGRlZXBMb29rdXAucGF0aFxuICAgICAgICAgICAgICAubWFwKChpKSA9PiBwYXRoLnJlbGF0aXZlKHBhdGguZGlybmFtZShjb250ZXh0LmdldEZpbGVuYW1lKCkpLCBpLnBhdGgpKVxuICAgICAgICAgICAgICAuam9pbignIC0+ICcpO1xuXG4gICAgICAgICAgICBjb250ZXh0LnJlcG9ydChpbS5rZXksIGAke2ltLmtleS5uYW1lfSBub3QgZm91bmQgdmlhICR7ZGVlcFBhdGh9YCk7XG4gICAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICAgIGNvbnRleHQucmVwb3J0KGltLmtleSwgYCR7aW0ua2V5Lm5hbWV9IG5vdCBmb3VuZCBpbiAnJHtzb3VyY2UudmFsdWV9J2ApO1xuICAgICAgICAgIH1cbiAgICAgICAgfVxuICAgICAgfSk7XG4gICAgfVxuXG4gICAgcmV0dXJuIHtcbiAgICAgIEltcG9ydERlY2xhcmF0aW9uOiBjaGVja1NwZWNpZmllcnMuYmluZChudWxsLCAnaW1wb3J0ZWQnLCAnSW1wb3J0U3BlY2lmaWVyJyksXG5cbiAgICAgIEV4cG9ydE5hbWVkRGVjbGFyYXRpb246IGNoZWNrU3BlY2lmaWVycy5iaW5kKG51bGwsICdsb2NhbCcsICdFeHBvcnRTcGVjaWZpZXInKSxcblxuICAgICAgVmFyaWFibGVEZWNsYXJhdG9yOiBjaGVja1JlcXVpcmUsXG4gICAgfTtcbiAgfSxcbn07XG4iXX0=