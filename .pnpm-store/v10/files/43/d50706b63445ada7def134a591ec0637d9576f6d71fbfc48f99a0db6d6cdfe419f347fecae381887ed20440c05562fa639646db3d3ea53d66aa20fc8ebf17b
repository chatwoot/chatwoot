'use strict';





var _builder = require('../exportMap/builder');var _builder2 = _interopRequireDefault(_builder);
var _importDeclaration = require('../importDeclaration');var _importDeclaration2 = _interopRequireDefault(_importDeclaration);
var _docsUrl = require('../docsUrl');var _docsUrl2 = _interopRequireDefault(_docsUrl);function _interopRequireDefault(obj) {return obj && obj.__esModule ? obj : { 'default': obj };}

//------------------------------------------------------------------------------
// Rule Definition
//------------------------------------------------------------------------------

module.exports = {
  meta: {
    type: 'suggestion',
    docs: {
      category: 'Helpful warnings',
      description: 'Forbid use of exported name as property of default export.',
      url: (0, _docsUrl2['default'])('no-named-as-default-member') },

    schema: [] },


  create: function () {function create(context) {
      var fileImports = new Map();
      var allPropertyLookups = new Map();

      function storePropertyLookup(objectName, propName, node) {
        var lookups = allPropertyLookups.get(objectName) || [];
        lookups.push({ node: node, propName: propName });
        allPropertyLookups.set(objectName, lookups);
      }

      return {
        ImportDefaultSpecifier: function () {function ImportDefaultSpecifier(node) {
            var declaration = (0, _importDeclaration2['default'])(context);
            var exportMap = _builder2['default'].get(declaration.source.value, context);
            if (exportMap == null) {return;}

            if (exportMap.errors.length) {
              exportMap.reportErrors(context, declaration);
              return;
            }

            fileImports.set(node.local.name, {
              exportMap: exportMap,
              sourcePath: declaration.source.value });

          }return ImportDefaultSpecifier;}(),

        MemberExpression: function () {function MemberExpression(node) {
            var objectName = node.object.name;
            var propName = node.property.name;
            storePropertyLookup(objectName, propName, node);
          }return MemberExpression;}(),

        VariableDeclarator: function () {function VariableDeclarator(node) {
            var isDestructure = node.id.type === 'ObjectPattern' &&
            node.init != null &&
            node.init.type === 'Identifier';
            if (!isDestructure) {return;}

            var objectName = node.init.name;var _iteratorNormalCompletion = true;var _didIteratorError = false;var _iteratorError = undefined;try {
              for (var _iterator = node.id.properties[Symbol.iterator](), _step; !(_iteratorNormalCompletion = (_step = _iterator.next()).done); _iteratorNormalCompletion = true) {var _ref = _step.value;var key = _ref.key;
                if (key == null) {continue;} // true for rest properties
                storePropertyLookup(objectName, key.name, key);
              }} catch (err) {_didIteratorError = true;_iteratorError = err;} finally {try {if (!_iteratorNormalCompletion && _iterator['return']) {_iterator['return']();}} finally {if (_didIteratorError) {throw _iteratorError;}}}
          }return VariableDeclarator;}(),

        'Program:exit': function () {function ProgramExit() {
            allPropertyLookups.forEach(function (lookups, objectName) {
              var fileImport = fileImports.get(objectName);
              if (fileImport == null) {return;}var _iteratorNormalCompletion2 = true;var _didIteratorError2 = false;var _iteratorError2 = undefined;try {

                for (var _iterator2 = lookups[Symbol.iterator](), _step2; !(_iteratorNormalCompletion2 = (_step2 = _iterator2.next()).done); _iteratorNormalCompletion2 = true) {var _ref2 = _step2.value;var propName = _ref2.propName,node = _ref2.node;
                  // the default import can have a "default" property
                  if (propName === 'default') {continue;}
                  if (!fileImport.exportMap.namespace.has(propName)) {continue;}

                  context.report({
                    node: node,
                    message: 'Caution: `' + String(objectName) + '` also has a named export `' + String(propName) + '`. Check if you meant to write `import {' + String(propName) + '} from \'' + String(fileImport.sourcePath) + '\'` instead.' });

                }} catch (err) {_didIteratorError2 = true;_iteratorError2 = err;} finally {try {if (!_iteratorNormalCompletion2 && _iterator2['return']) {_iterator2['return']();}} finally {if (_didIteratorError2) {throw _iteratorError2;}}}
            });
          }return ProgramExit;}() };

    }return create;}() }; /**
                           * @fileoverview Rule to warn about potentially confused use of name exports
                           * @author Desmond Brand
                           * @copyright 2016 Desmond Brand. All rights reserved.
                           * See LICENSE in root directory for full license.
                           */
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIi4uLy4uL3NyYy9ydWxlcy9uby1uYW1lZC1hcy1kZWZhdWx0LW1lbWJlci5qcyJdLCJuYW1lcyI6WyJtb2R1bGUiLCJleHBvcnRzIiwibWV0YSIsInR5cGUiLCJkb2NzIiwiY2F0ZWdvcnkiLCJkZXNjcmlwdGlvbiIsInVybCIsInNjaGVtYSIsImNyZWF0ZSIsImNvbnRleHQiLCJmaWxlSW1wb3J0cyIsIk1hcCIsImFsbFByb3BlcnR5TG9va3VwcyIsInN0b3JlUHJvcGVydHlMb29rdXAiLCJvYmplY3ROYW1lIiwicHJvcE5hbWUiLCJub2RlIiwibG9va3VwcyIsImdldCIsInB1c2giLCJzZXQiLCJJbXBvcnREZWZhdWx0U3BlY2lmaWVyIiwiZGVjbGFyYXRpb24iLCJleHBvcnRNYXAiLCJFeHBvcnRNYXBCdWlsZGVyIiwic291cmNlIiwidmFsdWUiLCJlcnJvcnMiLCJsZW5ndGgiLCJyZXBvcnRFcnJvcnMiLCJsb2NhbCIsIm5hbWUiLCJzb3VyY2VQYXRoIiwiTWVtYmVyRXhwcmVzc2lvbiIsIm9iamVjdCIsInByb3BlcnR5IiwiVmFyaWFibGVEZWNsYXJhdG9yIiwiaXNEZXN0cnVjdHVyZSIsImlkIiwiaW5pdCIsInByb3BlcnRpZXMiLCJrZXkiLCJmb3JFYWNoIiwiZmlsZUltcG9ydCIsIm5hbWVzcGFjZSIsImhhcyIsInJlcG9ydCIsIm1lc3NhZ2UiXSwibWFwcGluZ3MiOiI7Ozs7OztBQU1BLCtDO0FBQ0EseUQ7QUFDQSxxQzs7QUFFQTtBQUNBO0FBQ0E7O0FBRUFBLE9BQU9DLE9BQVAsR0FBaUI7QUFDZkMsUUFBTTtBQUNKQyxVQUFNLFlBREY7QUFFSkMsVUFBTTtBQUNKQyxnQkFBVSxrQkFETjtBQUVKQyxtQkFBYSw0REFGVDtBQUdKQyxXQUFLLDBCQUFRLDRCQUFSLENBSEQsRUFGRjs7QUFPSkMsWUFBUSxFQVBKLEVBRFM7OztBQVdmQyxRQVhlLCtCQVdSQyxPQVhRLEVBV0M7QUFDZCxVQUFNQyxjQUFjLElBQUlDLEdBQUosRUFBcEI7QUFDQSxV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SCx5QkFBeUk0QixXQUFXWCxVQUFwSixrQkFGYSxFQUFmOztBQUlELGlCQWJpRDtBQWNuRCxhQWREO0FBZUQsV0FwREksd0JBQVA7O0FBc0RELEtBM0VjLG1CQUFqQixDLENBZEEiLCJmaWxlIjoibm8tbmFtZWQtYXMtZGVmYXVsdC1tZW1iZXIuanMiLCJzb3VyY2VzQ29udGVudCI6WyIvKipcbiAqIEBmaWxlb3ZlcnZpZXcgUnVsZSB0byB3YXJuIGFib3V0IHBvdGVudGlhbGx5IGNvbmZ1c2VkIHVzZSBvZiBuYW1lIGV4cG9ydHNcbiAqIEBhdXRob3IgRGVzbW9uZCBCcmFuZFxuICogQGNvcHlyaWdodCAyMDE2IERlc21vbmQgQnJhbmQuIEFsbCByaWdodHMgcmVzZXJ2ZWQuXG4gKiBTZWUgTElDRU5TRSBpbiByb290IGRpcmVjdG9yeSBmb3IgZnVsbCBsaWNlbnNlLlxuICovXG5pbXBvcnQgRXhwb3J0TWFwQnVpbGRlciBmcm9tICcuLi9leHBvcnRNYXAvYnVpbGRlcic7XG5pbXBvcnQgaW1wb3J0RGVjbGFyYXRpb24gZnJvbSAnLi4vaW1wb3J0RGVjbGFyYXRpb24nO1xuaW1wb3J0IGRvY3NVcmwgZnJvbSAnLi4vZG9jc1VybCc7XG5cbi8vLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tXG4vLyBSdWxlIERlZmluaXRpb25cbi8vLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tXG5cbm1vZHVsZS5leHBvcnRzID0ge1xuICBtZXRhOiB7XG4gICAgdHlwZTogJ3N1Z2dlc3Rpb24nLFxuICAgIGRvY3M6IHtcbiAgICAgIGNhdGVnb3J5OiAnSGVscGZ1bCB3YXJuaW5ncycsXG4gICAgICBkZXNjcmlwdGlvbjogJ0ZvcmJpZCB1c2Ugb2YgZXhwb3J0ZWQgbmFtZSBhcyBwcm9wZXJ0eSBvZiBkZWZhdWx0IGV4cG9ydC4nLFxuICAgICAgdXJsOiBkb2NzVXJsKCduby1uYW1lZC1hcy1kZWZhdWx0LW1lbWJlcicpLFxuICAgIH0sXG4gICAgc2NoZW1hOiBbXSxcbiAgfSxcblxuICBjcmVhdGUoY29udGV4dCkge1xuICAgIGNvbnN0IGZpbGVJbXBvcnRzID0gbmV3IE1hcCgpO1xuICAgIGNvbnN0IGFsbFByb3BlcnR5TG9va3VwcyA9IG5ldyBNYXAoKTtcblxuICAgIGZ1bmN0aW9uIHN0b3JlUHJvcGVydHlMb29rdXAob2JqZWN0TmFtZSwgcHJvcE5hbWUsIG5vZGUpIHtcbiAgICAgIGNvbnN0IGxvb2t1cHMgPSBhbGxQcm9wZXJ0eUxvb2t1cHMuZ2V0KG9iamVjdE5hbWUpIHx8IFtdO1xuICAgICAgbG9va3Vwcy5wdXNoKHsgbm9kZSwgcHJvcE5hbWUgfSk7XG4gICAgICBhbGxQcm9wZXJ0eUxvb2t1cHMuc2V0KG9iamVjdE5hbWUsIGxvb2t1cHMpO1xuICAgIH1cblxuICAgIHJldHVybiB7XG4gICAgICBJbXBvcnREZWZhdWx0U3BlY2lmaWVyKG5vZGUpIHtcbiAgICAgICAgY29uc3QgZGVjbGFyYXRpb24gPSBpbXBvcnREZWNsYXJhdGlvbihjb250ZXh0KTtcbiAgICAgICAgY29uc3QgZXhwb3J0TWFwID0gRXhwb3J0TWFwQnVpbGRlci5nZXQoZGVjbGFyYXRpb24uc291cmNlLnZhbHVlLCBjb250ZXh0KTtcbiAgICAgICAgaWYgKGV4cG9ydE1hcCA9PSBudWxsKSB7IHJldHVybjsgfVxuXG4gICAgICAgIGlmIChleHBvcnRNYXAuZXJyb3JzLmxlbmd0aCkge1xuICAgICAgICAgIGV4cG9ydE1hcC5yZXBvcnRFcnJvcnMoY29udGV4dCwgZGVjbGFyYXRpb24pO1xuICAgICAgICAgIHJldHVybjtcbiAgICAgICAgfVxuXG4gICAgICAgIGZpbGVJbXBvcnRzLnNldChub2RlLmxvY2FsLm5hbWUsIHtcbiAgICAgICAgICBleHBvcnRNYXAsXG4gICAgICAgICAgc291cmNlUGF0aDogZGVjbGFyYXRpb24uc291cmNlLnZhbHVlLFxuICAgICAgICB9KTtcbiAgICAgIH0sXG5cbiAgICAgIE1lbWJlckV4cHJlc3Npb24obm9kZSkge1xuICAgICAgICBjb25zdCBvYmplY3ROYW1lID0gbm9kZS5vYmplY3QubmFtZTtcbiAgICAgICAgY29uc3QgcHJvcE5hbWUgPSBub2RlLnByb3BlcnR5Lm5hbWU7XG4gICAgICAgIHN0b3JlUHJvcGVydHlMb29rdXAob2JqZWN0TmFtZSwgcHJvcE5hbWUsIG5vZGUpO1xuICAgICAgfSxcblxuICAgICAgVmFyaWFibGVEZWNsYXJhdG9yKG5vZGUpIHtcbiAgICAgICAgY29uc3QgaXNEZXN0cnVjdHVyZSA9IG5vZGUuaWQudHlwZSA9PT0gJ09iamVjdFBhdHRlcm4nXG4gICAgICAgICAgJiYgbm9kZS5pbml0ICE9IG51bGxcbiAgICAgICAgICAmJiBub2RlLmluaXQudHlwZSA9PT0gJ0lkZW50aWZpZXInO1xuICAgICAgICBpZiAoIWlzRGVzdHJ1Y3R1cmUpIHsgcmV0dXJuOyB9XG5cbiAgICAgICAgY29uc3Qgb2JqZWN0TmFtZSA9IG5vZGUuaW5pdC5uYW1lO1xuICAgICAgICBmb3IgKGNvbnN0IHsga2V5IH0gb2Ygbm9kZS5pZC5wcm9wZXJ0aWVzKSB7XG4gICAgICAgICAgaWYgKGtleSA9PSBudWxsKSB7IGNvbnRpbnVlOyB9ICAvLyB0cnVlIGZvciByZXN0IHByb3BlcnRpZXNcbiAgICAgICAgICBzdG9yZVByb3BlcnR5TG9va3VwKG9iamVjdE5hbWUsIGtleS5uYW1lLCBrZXkpO1xuICAgICAgICB9XG4gICAgICB9LFxuXG4gICAgICAnUHJvZ3JhbTpleGl0JygpIHtcbiAgICAgICAgYWxsUHJvcGVydHlMb29rdXBzLmZvckVhY2goKGxvb2t1cHMsIG9iamVjdE5hbWUpID0+IHtcbiAgICAgICAgICBjb25zdCBmaWxlSW1wb3J0ID0gZmlsZUltcG9ydHMuZ2V0KG9iamVjdE5hbWUpO1xuICAgICAgICAgIGlmIChmaWxlSW1wb3J0ID09IG51bGwpIHsgcmV0dXJuOyB9XG5cbiAgICAgICAgICBmb3IgKGNvbnN0IHsgcHJvcE5hbWUsIG5vZGUgfSBvZiBsb29rdXBzKSB7XG4gICAgICAgICAgICAvLyB0aGUgZGVmYXVsdCBpbXBvcnQgY2FuIGhhdmUgYSBcImRlZmF1bHRcIiBwcm9wZXJ0eVxuICAgICAgICAgICAgaWYgKHByb3BOYW1lID09PSAnZGVmYXVsdCcpIHsgY29udGludWU7IH1cbiAgICAgICAgICAgIGlmICghZmlsZUltcG9ydC5leHBvcnRNYXAubmFtZXNwYWNlLmhhcyhwcm9wTmFtZSkpIHsgY29udGludWU7IH1cblxuICAgICAgICAgICAgY29udGV4dC5yZXBvcnQoe1xuICAgICAgICAgICAgICBub2RlLFxuICAgICAgICAgICAgICBtZXNzYWdlOiBgQ2F1dGlvbjogXFxgJHtvYmplY3ROYW1lfVxcYCBhbHNvIGhhcyBhIG5hbWVkIGV4cG9ydCBcXGAke3Byb3BOYW1lfVxcYC4gQ2hlY2sgaWYgeW91IG1lYW50IHRvIHdyaXRlIFxcYGltcG9ydCB7JHtwcm9wTmFtZX19IGZyb20gJyR7ZmlsZUltcG9ydC5zb3VyY2VQYXRofSdcXGAgaW5zdGVhZC5gLFxuICAgICAgICAgICAgfSk7XG4gICAgICAgICAgfVxuICAgICAgICB9KTtcbiAgICAgIH0sXG4gICAgfTtcbiAgfSxcbn07XG4iXX0=