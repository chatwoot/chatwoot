'use strict';var _vm = require('vm');var _vm2 = _interopRequireDefault(_vm);
var _docsUrl = require('../docsUrl');var _docsUrl2 = _interopRequireDefault(_docsUrl);function _interopRequireDefault(obj) {return obj && obj.__esModule ? obj : { 'default': obj };}

module.exports = {
  meta: {
    type: 'suggestion',
    docs: {
      category: 'Style guide',
      description: 'Enforce a leading comment with the webpackChunkName for dynamic imports.',
      url: (0, _docsUrl2['default'])('dynamic-import-chunkname') },

    schema: [{
      type: 'object',
      properties: {
        importFunctions: {
          type: 'array',
          uniqueItems: true,
          items: {
            type: 'string' } },


        allowEmpty: {
          type: 'boolean' },

        webpackChunknameFormat: {
          type: 'string' } } }],



    hasSuggestions: true },


  create: function () {function create(context) {
      var config = context.options[0];var _ref =
      config || {},_ref$importFunctions = _ref.importFunctions,importFunctions = _ref$importFunctions === undefined ? [] : _ref$importFunctions,_ref$allowEmpty = _ref.allowEmpty,allowEmpty = _ref$allowEmpty === undefined ? false : _ref$allowEmpty;var _ref2 =
      config || {},_ref2$webpackChunknam = _ref2.webpackChunknameFormat,webpackChunknameFormat = _ref2$webpackChunknam === undefined ? '([0-9a-zA-Z-_/.]|\\[(request|index)\\])+' : _ref2$webpackChunknam;

      var paddedCommentRegex = /^ (\S[\s\S]+\S) $/;
      var commentStyleRegex = /^( ((webpackChunkName: .+)|((webpackPrefetch|webpackPreload): (true|false|-?[0-9]+))|(webpackIgnore: (true|false))|((webpackInclude|webpackExclude): \/.*\/)|(webpackMode: ["'](lazy|lazy-once|eager|weak)["'])|(webpackExports: (['"]\w+['"]|\[(['"]\w+['"], *)+(['"]\w+['"]*)\]))),?)+ $/;
      var chunkSubstrFormat = 'webpackChunkName: ["\']' + String(webpackChunknameFormat) + '["\'],? ';
      var chunkSubstrRegex = new RegExp(chunkSubstrFormat);
      var eagerModeFormat = 'webpackMode: ["\']eager["\'],? ';
      var eagerModeRegex = new RegExp(eagerModeFormat);

      function run(node, arg) {
        var sourceCode = context.getSourceCode();
        var leadingComments = sourceCode.getCommentsBefore ?
        sourceCode.getCommentsBefore(arg) // This method is available in ESLint >= 4.
        : sourceCode.getComments(arg).leading; // This method is deprecated in ESLint 7.

        if ((!leadingComments || leadingComments.length === 0) && !allowEmpty) {
          context.report({
            node: node,
            message: 'dynamic imports require a leading comment with the webpack chunkname' });

          return;
        }

        var isChunknamePresent = false;
        var isEagerModePresent = false;var _iteratorNormalCompletion = true;var _didIteratorError = false;var _iteratorError = undefined;try {

          for (var _iterator = leadingComments[Symbol.iterator](), _step; !(_iteratorNormalCompletion = (_step = _iterator.next()).done); _iteratorNormalCompletion = true) {var comment = _step.value;
            if (comment.type !== 'Block') {
              context.report({
                node: node,
                message: 'dynamic imports require a /* foo */ style comment, not a // foo comment' });

              return;
            }

            if (!paddedCommentRegex.test(comment.value)) {
              context.report({
                node: node,
                message: 'dynamic imports require a block comment padded with spaces - /* foo */' });

              return;
            }

            try {
              // just like webpack itself does
              _vm2['default'].runInNewContext('(function() {return {' + String(comment.value) + '}})()');
            } catch (error) {
              context.report({
                node: node,
                message: 'dynamic imports require a "webpack" comment with valid syntax' });

              return;
            }

            if (!commentStyleRegex.test(comment.value)) {
              context.report({
                node: node,
                message: 'dynamic imports require a "webpack" comment with valid syntax' });


              return;
            }

            if (eagerModeRegex.test(comment.value)) {
              isEagerModePresent = true;
            }

            if (chunkSubstrRegex.test(comment.value)) {
              isChunknamePresent = true;
            }
          }} catch (err) {_didIteratorError = true;_iteratorError = err;} finally {try {if (!_iteratorNormalCompletion && _iterator['return']) {_iterator['return']();}} finally {if (_didIteratorError) {throw _iteratorError;}}}

        if (isChunknamePresent && isEagerModePresent) {
          context.report({
            node: node,
            message: 'dynamic imports using eager mode do not need a webpackChunkName',
            suggest: [
            {
              desc: 'Remove webpackChunkName',
              fix: function () {function fix(fixer) {var _iteratorNormalCompletion2 = true;var _didIteratorError2 = false;var _iteratorError2 = undefined;try {
                    for (var _iterator2 = leadingComments[Symbol.iterator](), _step2; !(_iteratorNormalCompletion2 = (_step2 = _iterator2.next()).done); _iteratorNormalCompletion2 = true) {var _comment = _step2.value;
                      if (chunkSubstrRegex.test(_comment.value)) {
                        var replacement = _comment.value.replace(chunkSubstrRegex, '').trim().replace(/,$/, '');
                        if (replacement === '') {
                          return fixer.remove(_comment);
                        } else {
                          return fixer.replaceText(_comment, '/* ' + String(replacement) + ' */');
                        }
                      }
                    }} catch (err) {_didIteratorError2 = true;_iteratorError2 = err;} finally {try {if (!_iteratorNormalCompletion2 && _iterator2['return']) {_iterator2['return']();}} finally {if (_didIteratorError2) {throw _iteratorError2;}}}
                }return fix;}() },

            {
              desc: 'Remove webpackMode',
              fix: function () {function fix(fixer) {var _iteratorNormalCompletion3 = true;var _didIteratorError3 = false;var _iteratorError3 = undefined;try {
                    for (var _iterator3 = leadingComments[Symbol.iterator](), _step3; !(_iteratorNormalCompletion3 = (_step3 = _iterator3.next()).done); _iteratorNormalCompletion3 = true) {var _comment2 = _step3.value;
                      if (eagerModeRegex.test(_comment2.value)) {
                        var replacement = _comment2.value.replace(eagerModeRegex, '').trim().replace(/,$/, '');
                        if (replacement === '') {
                          return fixer.remove(_comment2);
                        } else {
                          return fixer.replaceText(_comment2, '/* ' + String(replacement) + ' */');
                        }
                      }
                    }} catch (err) {_didIteratorError3 = true;_iteratorError3 = err;} finally {try {if (!_iteratorNormalCompletion3 && _iterator3['return']) {_iterator3['return']();}} finally {if (_didIteratorError3) {throw _iteratorError3;}}}
                }return fix;}() }] });



        }

        if (!isChunknamePresent && !allowEmpty && !isEagerModePresent) {
          context.report({
            node: node,
            message: 'dynamic imports require a leading comment in the form /*' +
            chunkSubstrFormat + '*/' });

        }
      }

      return {
        ImportExpression: function () {function ImportExpression(node) {
            run(node, node.source);
          }return ImportExpression;}(),

        CallExpression: function () {function CallExpression(node) {
            if (node.callee.type !== 'Import' && importFunctions.indexOf(node.callee.name) < 0) {
              return;
            }

            run(node, node.arguments[0]);
          }return CallExpression;}() };

    }return create;}() };
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIi4uLy4uL3NyYy9ydWxlcy9keW5hbWljLWltcG9ydC1jaHVua25hbWUuanMiXSwibmFtZXMiOlsibW9kdWxlIiwiZXhwb3J0cyIsIm1ldGEiLCJ0eXBlIiwiZG9jcyIsImNhdGVnb3J5IiwiZGVzY3JpcHRpb24iLCJ1cmwiLCJzY2hlbWEiLCJwcm9wZXJ0aWVzIiwiaW1wb3J0RnVuY3Rpb25zIiwidW5pcXVlSXRlbXMiLCJpdGVtcyIsImFsbG93RW1wdHkiLCJ3ZWJwYWNrQ2h1bmtuYW1lRm9ybWF0IiwiaGFzU3VnZ2VzdGlvbnMiLCJjcmVhdGUiLCJjb250ZXh0IiwiY29uZmlnIiwib3B0aW9ucyIsInBhZGRlZENvbW1lbnRSZWdleCIsImNvbW1lbnRTdHlsZVJlZ2V4IiwiY2h1bmtTdWJzdHJGb3JtYXQiLCJjaHVua1N1YnN0clJlZ2V4IiwiUmVnRXhwIiwiZWFnZXJNb2RlRm9ybWF0IiwiZWFnZXJNb2RlUmVnZXgiLCJydW4iLCJub2RlIiwiYXJnIiwic291cmNlQ29kZSIsImdldFNvdXJjZUNvZGUiLCJsZWFkaW5nQ29tbWVudHMiLCJnZXRDb21tZW50c0JlZm9yZSIsImdldENvbW1lbnRzIiwibGVhZGluZyIsImxlbmd0aCIsInJlcG9ydCIsIm1lc3NhZ2UiLCJpc0NodW5rbmFtZVByZXNlbnQiLCJpc0VhZ2VyTW9kZVByZXNlbnQiLCJjb21tZW50IiwidGVzdCIsInZhbHVlIiwidm0iLCJydW5Jbk5ld0NvbnRleHQiLCJlcnJvciIsInN1Z2dlc3QiLCJkZXNjIiwiZml4IiwiZml4ZXIiLCJyZXBsYWNlbWVudCIsInJlcGxhY2UiLCJ0cmltIiwicmVtb3ZlIiwicmVwbGFjZVRleHQiLCJJbXBvcnRFeHByZXNzaW9uIiwic291cmNlIiwiQ2FsbEV4cHJlc3Npb24iLCJjYWxsZWUiLCJpbmRleE9mIiwibmFtZSIsImFyZ3VtZW50cyJdLCJtYXBwaW5ncyI6ImFBQUEsd0I7QUFDQSxxQzs7QUFFQUEsT0FBT0MsT0FBUCxHQUFpQjtBQUNmQyxRQUFNO0FB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Y0FBdEIsRUFBc0MsRUFBdEMsRUFBMEMyQixJQUExQyxHQUFpREQsT0FBakQsQ0FBeUQsSUFBekQsRUFBK0QsRUFBL0QsQ0FBcEI7QUFDQSw0QkFBSUQsZ0JBQWdCLEVBQXBCLEVBQXdCO0FBQ3RCLGlDQUFPRCxNQUFNSSxNQUFOLENBQWFiLFNBQWIsQ0FBUDtBQUNELHlCQUZELE1BRU87QUFDTCxpQ0FBT1MsTUFBTUssV0FBTixDQUFrQmQsU0FBbEIsaUJBQWlDVSxXQUFqQyxVQUFQO0FBQ0Q7QUFDRjtBQUNGLHFCQVZRO0FBV1YsaUJBYkgsZ0JBaEJPLENBSEksRUFBZjs7OztBQW9DRDs7QUFFRCxZQUFJLENBQUNaLGtCQUFELElBQXVCLENBQUMxQixVQUF4QixJQUFzQyxDQUFDMkIsa0JBQTNDLEVBQStEO0FBQzdEdkIsa0JBQVFvQixNQUFSLENBQWU7QUFDYlQsc0JBRGE7QUFFYlU7QUFDNkRoQiw2QkFEN0QsT0FGYSxFQUFmOztBQUtEO0FBQ0Y7O0FBRUQsYUFBTztBQUNMa0Msd0JBREsseUNBQ1k1QixJQURaLEVBQ2tCO0FBQ3JCRCxnQkFBSUMsSUFBSixFQUFVQSxLQUFLNkIsTUFBZjtBQUNELFdBSEk7O0FBS0xDLHNCQUxLLHVDQUtVOUIsSUFMVixFQUtnQjtBQUNuQixnQkFBSUEsS0FBSytCLE1BQUwsQ0FBWXhELElBQVosS0FBcUIsUUFBckIsSUFBaUNPLGdCQUFnQmtELE9BQWhCLENBQXdCaEMsS0FBSytCLE1BQUwsQ0FBWUUsSUFBcEMsSUFBNEMsQ0FBakYsRUFBb0Y7QUFDbEY7QUFDRDs7QUFFRGxDLGdCQUFJQyxJQUFKLEVBQVVBLEtBQUtrQyxTQUFMLENBQWUsQ0FBZixDQUFWO0FBQ0QsV0FYSSwyQkFBUDs7QUFhRCxLQXJLYyxtQkFBakIiLCJmaWxlIjoiZHluYW1pYy1pbXBvcnQtY2h1bmtuYW1lLmpzIiwic291cmNlc0NvbnRlbnQiOlsiaW1wb3J0IHZtIGZyb20gJ3ZtJztcbmltcG9ydCBkb2NzVXJsIGZyb20gJy4uL2RvY3NVcmwnO1xuXG5tb2R1bGUuZXhwb3J0cyA9IHtcbiAgbWV0YToge1xuICAgIHR5cGU6ICdzdWdnZXN0aW9uJyxcbiAgICBkb2NzOiB7XG4gICAgICBjYXRlZ29yeTogJ1N0eWxlIGd1aWRlJyxcbiAgICAgIGRlc2NyaXB0aW9uOiAnRW5mb3JjZSBhIGxlYWRpbmcgY29tbWVudCB3aXRoIHRoZSB3ZWJwYWNrQ2h1bmtOYW1lIGZvciBkeW5hbWljIGltcG9ydHMuJyxcbiAgICAgIHVybDogZG9jc1VybCgnZHluYW1pYy1pbXBvcnQtY2h1bmtuYW1lJyksXG4gICAgfSxcbiAgICBzY2hlbWE6IFt7XG4gICAgICB0eXBlOiAnb2JqZWN0JyxcbiAgICAgIHByb3BlcnRpZXM6IHtcbiAgICAgICAgaW1wb3J0RnVuY3Rpb25zOiB7XG4gICAgICAgICAgdHlwZTogJ2FycmF5JyxcbiAgICAgICAgICB1bmlxdWVJdGVtczogdHJ1ZSxcbiAgICAgICAgICBpdGVtczoge1xuICAgICAgICAgICAgdHlwZTogJ3N0cmluZycsXG4gICAgICAgICAgfSxcbiAgICAgICAgfSxcbiAgICAgICAgYWxsb3dFbXB0eToge1xuICAgICAgICAgIHR5cGU6ICdib29sZWFuJyxcbiAgICAgICAgfSxcbiAgICAgICAgd2VicGFja0NodW5rbmFtZUZvcm1hdDoge1xuICAgICAgICAgIHR5cGU6ICdzdHJpbmcnLFxuICAgICAgICB9LFxuICAgICAgfSxcbiAgICB9XSxcbiAgICBoYXNTdWdnZXN0aW9uczogdHJ1ZSxcbiAgfSxcblxuICBjcmVhdGUoY29udGV4dCkge1xuICAgIGNvbnN0IGNvbmZpZyA9IGNvbnRleHQub3B0aW9uc1swXTtcbiAgICBjb25zdCB7IGltcG9ydEZ1bmN0aW9ucyA9IFtdLCBhbGxvd0VtcHR5ID0gZmFsc2UgfSA9IGNvbmZpZyB8fCB7fTtcbiAgICBjb25zdCB7IHdlYnBhY2tDaHVua25hbWVGb3JtYXQgPSAnKFswLTlhLXpBLVotXy8uXXxcXFxcWyhyZXF1ZXN0fGluZGV4KVxcXFxdKSsnIH0gPSBjb25maWcgfHwge307XG5cbiAgICBjb25zdCBwYWRkZWRDb21tZW50UmVnZXggPSAvXiAoXFxTW1xcc1xcU10rXFxTKSAkLztcbiAgICBjb25zdCBjb21tZW50U3R5bGVSZWdleCA9IC9eKCAoKHdlYnBhY2tDaHVua05hbWU6IC4rKXwoKHdlYnBhY2tQcmVmZXRjaHx3ZWJwYWNrUHJlbG9hZCk6ICh0cnVlfGZhbHNlfC0/WzAtOV0rKSl8KHdlYnBhY2tJZ25vcmU6ICh0cnVlfGZhbHNlKSl8KCh3ZWJwYWNrSW5jbHVkZXx3ZWJwYWNrRXhjbHVkZSk6IFxcLy4qXFwvKXwod2VicGFja01vZGU6IFtcIiddKGxhenl8bGF6eS1vbmNlfGVhZ2VyfHdlYWspW1wiJ10pfCh3ZWJwYWNrRXhwb3J0czogKFsnXCJdXFx3K1snXCJdfFxcWyhbJ1wiXVxcdytbJ1wiXSwgKikrKFsnXCJdXFx3K1snXCJdKilcXF0pKSksPykrICQvO1xuICAgIGNvbnN0IGNodW5rU3Vic3RyRm9ybWF0ID0gYHdlYnBhY2tDaHVua05hbWU6IFtcIiddJHt3ZWJwYWNrQ2h1bmtuYW1lRm9ybWF0fVtcIiddLD8gYDtcbiAgICBjb25zdCBjaHVua1N1YnN0clJlZ2V4ID0gbmV3IFJlZ0V4cChjaHVua1N1YnN0ckZvcm1hdCk7XG4gICAgY29uc3QgZWFnZXJNb2RlRm9ybWF0ID0gYHdlYnBhY2tNb2RlOiBbXCInXWVhZ2VyW1wiJ10sPyBgO1xuICAgIGNvbnN0IGVhZ2VyTW9kZVJlZ2V4ID0gbmV3IFJlZ0V4cChlYWdlck1vZGVGb3JtYXQpO1xuXG4gICAgZnVuY3Rpb24gcnVuKG5vZGUsIGFyZykge1xuICAgICAgY29uc3Qgc291cmNlQ29kZSA9IGNvbnRleHQuZ2V0U291cmNlQ29kZSgpO1xuICAgICAgY29uc3QgbGVhZGluZ0NvbW1lbnRzID0gc291cmNlQ29kZS5nZXRDb21tZW50c0JlZm9yZVxuICAgICAgICA/IHNvdXJjZUNvZGUuZ2V0Q29tbWVudHNCZWZvcmUoYXJnKSAvLyBUaGlzIG1ldGhvZCBpcyBhdmFpbGFibGUgaW4gRVNMaW50ID49IDQuXG4gICAgICAgIDogc291cmNlQ29kZS5nZXRDb21tZW50cyhhcmcpLmxlYWRpbmc7IC8vIFRoaXMgbWV0aG9kIGlzIGRlcHJlY2F0ZWQgaW4gRVNMaW50IDcuXG5cbiAgICAgIGlmICgoIWxlYWRpbmdDb21tZW50cyB8fCBsZWFkaW5nQ29tbWVudHMubGVuZ3RoID09PSAwKSAmJiAhYWxsb3dFbXB0eSkge1xuICAgICAgICBjb250ZXh0LnJlcG9ydCh7XG4gICAgICAgICAgbm9kZSxcbiAgICAgICAgICBtZXNzYWdlOiAnZHluYW1pYyBpbXBvcnRzIHJlcXVpcmUgYSBsZWFkaW5nIGNvbW1lbnQgd2l0aCB0aGUgd2VicGFjayBjaHVua25hbWUnLFxuICAgICAgICB9KTtcbiAgICAgICAgcmV0dXJuO1xuICAgICAgfVxuXG4gICAgICBsZXQgaXNDaHVua25hbWVQcmVzZW50ID0gZmFsc2U7XG4gICAgICBsZXQgaXNFYWdlck1vZGVQcmVzZW50ID0gZmFsc2U7XG5cbiAgICAgIGZvciAoY29uc3QgY29tbWVudCBvZiBsZWFkaW5nQ29tbWVudHMpIHtcbiAgICAgICAgaWYgKGNvbW1lbnQudHlwZSAhPT0gJ0Jsb2NrJykge1xuICAgICAgICAgIGNvbnRleHQucmVwb3J0KHtcbiAgICAgICAgICAgIG5vZGUsXG4gICAgICAgICAgICBtZXNzYWdlOiAnZHluYW1pYyBpbXBvcnRzIHJlcXVpcmUgYSAvKiBmb28gKi8gc3R5bGUgY29tbWVudCwgbm90IGEgLy8gZm9vIGNvbW1lbnQnLFxuICAgICAgICAgIH0pO1xuICAgICAgICAgIHJldHVybjtcbiAgICAgICAgfVxuXG4gICAgICAgIGlmICghcGFkZGVkQ29tbWVudFJlZ2V4LnRlc3QoY29tbWVudC52YWx1ZSkpIHtcbiAgICAgICAgICBjb250ZXh0LnJlcG9ydCh7XG4gICAgICAgICAgICBub2RlLFxuICAgICAgICAgICAgbWVzc2FnZTogYGR5bmFtaWMgaW1wb3J0cyByZXF1aXJlIGEgYmxvY2sgY29tbWVudCBwYWRkZWQgd2l0aCBzcGFjZXMgLSAvKiBmb28gKi9gLFxuICAgICAgICAgIH0pO1xuICAgICAgICAgIHJldHVybjtcbiAgICAgICAgfVxuXG4gICAgICAgIHRyeSB7XG4gICAgICAgICAgLy8ganVzdCBsaWtlIHdlYnBhY2sgaXRzZWxmIGRvZXNcbiAgICAgICAgICB2bS5ydW5Jbk5ld0NvbnRleHQoYChmdW5jdGlvbigpIHtyZXR1cm4geyR7Y29tbWVudC52YWx1ZX19fSkoKWApO1xuICAgICAgICB9IGNhdGNoIChlcnJvcikge1xuICAgICAgICAgIGNvbnRleHQucmVwb3J0KHtcbiAgICAgICAgICAgIG5vZGUsXG4gICAgICAgICAgICBtZXNzYWdlOiBgZHluYW1pYyBpbXBvcnRzIHJlcXVpcmUgYSBcIndlYnBhY2tcIiBjb21tZW50IHdpdGggdmFsaWQgc3ludGF4YCxcbiAgICAgICAgICB9KTtcbiAgICAgICAgICByZXR1cm47XG4gICAgICAgIH1cblxuICAgICAgICBpZiAoIWNvbW1lbnRTdHlsZVJlZ2V4LnRlc3QoY29tbWVudC52YWx1ZSkpIHtcbiAgICAgICAgICBjb250ZXh0LnJlcG9ydCh7XG4gICAgICAgICAgICBub2RlLFxuICAgICAgICAgICAgbWVzc2FnZTpcbiAgICAgICAgICAgICAgYGR5bmFtaWMgaW1wb3J0cyByZXF1aXJlIGEgXCJ3ZWJwYWNrXCIgY29tbWVudCB3aXRoIHZhbGlkIHN5bnRheGAsXG4gICAgICAgICAgfSk7XG4gICAgICAgICAgcmV0dXJuO1xuICAgICAgICB9XG5cbiAgICAgICAgaWYgKGVhZ2VyTW9kZVJlZ2V4LnRlc3QoY29tbWVudC52YWx1ZSkpIHtcbiAgICAgICAgICBpc0VhZ2VyTW9kZVByZXNlbnQgPSB0cnVlO1xuICAgICAgICB9XG5cbiAgICAgICAgaWYgKGNodW5rU3Vic3RyUmVnZXgudGVzdChjb21tZW50LnZhbHVlKSkge1xuICAgICAgICAgIGlzQ2h1bmtuYW1lUHJlc2VudCA9IHRydWU7XG4gICAgICAgIH1cbiAgICAgIH1cblxuICAgICAgaWYgKGlzQ2h1bmtuYW1lUHJlc2VudCAmJiBpc0VhZ2VyTW9kZVByZXNlbnQpIHtcbiAgICAgICAgY29udGV4dC5yZXBvcnQoe1xuICAgICAgICAgIG5vZGUsXG4gICAgICAgICAgbWVzc2FnZTogJ2R5bmFtaWMgaW1wb3J0cyB1c2luZyBlYWdlciBtb2RlIGRvIG5vdCBuZWVkIGEgd2VicGFja0NodW5rTmFtZScsXG4gICAgICAgICAgc3VnZ2VzdDogW1xuICAgICAgICAgICAge1xuICAgICAgICAgICAgICBkZXNjOiAnUmVtb3ZlIHdlYnBhY2tDaHVua05hbWUnLFxuICAgICAgICAgICAgICBmaXgoZml4ZXIpIHtcbiAgICAgICAgICAgICAgICBmb3IgKGNvbnN0IGNvbW1lbnQgb2YgbGVhZGluZ0NvbW1lbnRzKSB7XG4gICAgICAgICAgICAgICAgICBpZiAoY2h1bmtTdWJzdHJSZWdleC50ZXN0KGNvbW1lbnQudmFsdWUpKSB7XG4gICAgICAgICAgICAgICAgICAgIGNvbnN0IHJlcGxhY2VtZW50ID0gY29tbWVudC52YWx1ZS5yZXBsYWNlKGNodW5rU3Vic3RyUmVnZXgsICcnKS50cmltKCkucmVwbGFjZSgvLCQvLCAnJyk7XG4gICAgICAgICAgICAgICAgICAgIGlmIChyZXBsYWNlbWVudCA9PT0gJycpIHtcbiAgICAgICAgICAgICAgICAgICAgICByZXR1cm4gZml4ZXIucmVtb3ZlKGNvbW1lbnQpO1xuICAgICAgICAgICAgICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgICAgICAgICAgICAgIHJldHVybiBmaXhlci5yZXBsYWNlVGV4dChjb21tZW50LCBgLyogJHtyZXBsYWNlbWVudH0gKi9gKTtcbiAgICAgICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgICAgfSxcbiAgICAgICAgICAgIH0sXG4gICAgICAgICAgICB7XG4gICAgICAgICAgICAgIGRlc2M6ICdSZW1vdmUgd2VicGFja01vZGUnLFxuICAgICAgICAgICAgICBmaXgoZml4ZXIpIHtcbiAgICAgICAgICAgICAgICBmb3IgKGNvbnN0IGNvbW1lbnQgb2YgbGVhZGluZ0NvbW1lbnRzKSB7XG4gICAgICAgICAgICAgICAgICBpZiAoZWFnZXJNb2RlUmVnZXgudGVzdChjb21tZW50LnZhbHVlKSkge1xuICAgICAgICAgICAgICAgICAgICBjb25zdCByZXBsYWNlbWVudCA9IGNvbW1lbnQudmFsdWUucmVwbGFjZShlYWdlck1vZGVSZWdleCwgJycpLnRyaW0oKS5yZXBsYWNlKC8sJC8sICcnKTtcbiAgICAgICAgICAgICAgICAgICAgaWYgKHJlcGxhY2VtZW50ID09PSAnJykge1xuICAgICAgICAgICAgICAgICAgICAgIHJldHVybiBmaXhlci5yZW1vdmUoY29tbWVudCk7XG4gICAgICAgICAgICAgICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgICAgICAgICAgICAgcmV0dXJuIGZpeGVyLnJlcGxhY2VUZXh0KGNvbW1lbnQsIGAvKiAke3JlcGxhY2VtZW50fSAqL2ApO1xuICAgICAgICAgICAgICAgICAgICB9XG4gICAgICAgICAgICAgICAgICB9XG4gICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgICB9LFxuICAgICAgICAgICAgfSxcbiAgICAgICAgICBdLFxuICAgICAgICB9KTtcbiAgICAgIH1cblxuICAgICAgaWYgKCFpc0NodW5rbmFtZVByZXNlbnQgJiYgIWFsbG93RW1wdHkgJiYgIWlzRWFnZXJNb2RlUHJlc2VudCkge1xuICAgICAgICBjb250ZXh0LnJlcG9ydCh7XG4gICAgICAgICAgbm9kZSxcbiAgICAgICAgICBtZXNzYWdlOlxuICAgICAgICAgICAgYGR5bmFtaWMgaW1wb3J0cyByZXF1aXJlIGEgbGVhZGluZyBjb21tZW50IGluIHRoZSBmb3JtIC8qJHtjaHVua1N1YnN0ckZvcm1hdH0qL2AsXG4gICAgICAgIH0pO1xuICAgICAgfVxuICAgIH1cblxuICAgIHJldHVybiB7XG4gICAgICBJbXBvcnRFeHByZXNzaW9uKG5vZGUpIHtcbiAgICAgICAgcnVuKG5vZGUsIG5vZGUuc291cmNlKTtcbiAgICAgIH0sXG5cbiAgICAgIENhbGxFeHByZXNzaW9uKG5vZGUpIHtcbiAgICAgICAgaWYgKG5vZGUuY2FsbGVlLnR5cGUgIT09ICdJbXBvcnQnICYmIGltcG9ydEZ1bmN0aW9ucy5pbmRleE9mKG5vZGUuY2FsbGVlLm5hbWUpIDwgMCkge1xuICAgICAgICAgIHJldHVybjtcbiAgICAgICAgfVxuXG4gICAgICAgIHJ1bihub2RlLCBub2RlLmFyZ3VtZW50c1swXSk7XG4gICAgICB9LFxuICAgIH07XG4gIH0sXG59O1xuIl19