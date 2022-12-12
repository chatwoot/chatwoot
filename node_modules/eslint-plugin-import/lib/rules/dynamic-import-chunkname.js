'use strict';var _vm = require('vm');var _vm2 = _interopRequireDefault(_vm);
var _docsUrl = require('../docsUrl');var _docsUrl2 = _interopRequireDefault(_docsUrl);function _interopRequireDefault(obj) {return obj && obj.__esModule ? obj : { default: obj };}

module.exports = {
  meta: {
    type: 'suggestion',
    docs: {
      url: (0, _docsUrl2.default)('dynamic-import-chunkname') },

    schema: [{
      type: 'object',
      properties: {
        importFunctions: {
          type: 'array',
          uniqueItems: true,
          items: {
            type: 'string' } },


        webpackChunknameFormat: {
          type: 'string' } } }] },





  create: function (context) {
    const config = context.options[0];var _ref =
    config || {},_ref$importFunctions = _ref.importFunctions;const importFunctions = _ref$importFunctions === undefined ? [] : _ref$importFunctions;var _ref2 =
    config || {},_ref2$webpackChunknam = _ref2.webpackChunknameFormat;const webpackChunknameFormat = _ref2$webpackChunknam === undefined ? '[0-9a-zA-Z-_/.]+' : _ref2$webpackChunknam;

    const paddedCommentRegex = /^ (\S[\s\S]+\S) $/;
    const commentStyleRegex = /^( \w+: (["'][^"']*["']|\d+|false|true),?)+ $/;
    const chunkSubstrFormat = ` webpackChunkName: ["']${webpackChunknameFormat}["'],? `;
    const chunkSubstrRegex = new RegExp(chunkSubstrFormat);

    function run(node, arg) {
      const sourceCode = context.getSourceCode();
      const leadingComments = sourceCode.getCommentsBefore ?
      sourceCode.getCommentsBefore(arg) // This method is available in ESLint >= 4.
      : sourceCode.getComments(arg).leading; // This method is deprecated in ESLint 7.

      if (!leadingComments || leadingComments.length === 0) {
        context.report({
          node,
          message: 'dynamic imports require a leading comment with the webpack chunkname' });

        return;
      }

      let isChunknamePresent = false;

      for (const comment of leadingComments) {
        if (comment.type !== 'Block') {
          context.report({
            node,
            message: 'dynamic imports require a /* foo */ style comment, not a // foo comment' });

          return;
        }

        if (!paddedCommentRegex.test(comment.value)) {
          context.report({
            node,
            message: `dynamic imports require a block comment padded with spaces - /* foo */` });

          return;
        }

        try {
          // just like webpack itself does
          _vm2.default.runInNewContext(`(function(){return {${comment.value}}})()`);
        }
        catch (error) {
          context.report({
            node,
            message: `dynamic imports require a "webpack" comment with valid syntax` });

          return;
        }

        if (!commentStyleRegex.test(comment.value)) {
          context.report({
            node,
            message:
            `dynamic imports require a leading comment in the form /*${chunkSubstrFormat}*/` });

          return;
        }

        if (chunkSubstrRegex.test(comment.value)) {
          isChunknamePresent = true;
        }
      }

      if (!isChunknamePresent) {
        context.report({
          node,
          message:
          `dynamic imports require a leading comment in the form /*${chunkSubstrFormat}*/` });

      }
    }

    return {
      ImportExpression(node) {
        run(node, node.source);
      },

      CallExpression(node) {
        if (node.callee.type !== 'Import' && importFunctions.indexOf(node.callee.name) < 0) {
          return;
        }

        run(node, node.arguments[0]);
      } };

  } };
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIi4uLy4uL3NyYy9ydWxlcy9keW5hbWljLWltcG9ydC1jaHVua25hbWUuanMiXSwibmFtZXMiOlsibW9kdWxlIiwiZXhwb3J0cyIsIm1ldGEiLCJ0eXBlIiwiZG9jcyIsInVybCIsInNjaGVtYSIsInByb3BlcnRpZXMiLCJpbXBvcnRGdW5jdGlvbnMiLCJ1bmlxdWVJdGVtcyIsIml0ZW1zIiwid2VicGFja0NodW5rbmFtZUZvcm1hdCIsImNyZWF0ZSIsImNvbnRleHQiLCJjb25maWciLCJvcHRpb25zIiwicGFkZGVkQ29tbWVudFJlZ2V4IiwiY29tbWVudFN0eWxlUmVnZXgiLCJjaHVua1N1YnN0ckZvcm1hdCIsImNodW5rU3Vic3RyUmVnZXgiLCJSZWdFeHAiLCJydW4iLCJub2RlIiwiYXJnIiwic291cmNlQ29kZSIsImdldFNvdXJjZUNvZGUiLCJsZWFkaW5nQ29tbWVudHMiLCJnZXRDb21tZW50c0JlZm9yZSIsImdldENvbW1lbnRzIiwibGVhZGluZyIsImxlbmd0aCIsInJlcG9ydCIsIm1lc3NhZ2UiLCJpc0NodW5rbmFtZVByZXNlbnQiLCJjb21tZW50IiwidGVzdCIsInZhbHVlIiwidm0iLCJydW5Jbk5ld0NvbnRleHQiLCJlcnJvciIsIkltcG9ydEV4cHJlc3Npb24iLCJzb3VyY2UiLCJDYWxsRXhwcmVzc2lvbiIsImNhbGxlZSIsImluZGV4T2YiLCJuYW1lIiwiYXJndW1lbnRzIl0sIm1hcHBpbmdzIjoiYUFBQSx3QjtBQUNBLHFDOztBQUVBQSxPQUFPQyxPQUFQLEdBQWlCO0FBQ2ZDLFFBQU07QUFDSkMsVUFBTSxZQURGO0FBRUpDLFVBQU07QUFDSkMsV0FBSyx1QkFBUSwwQkFBUixDQURELEVBRkY7O0FBS0pDLFlBQVEsQ0FBQztBQUNQSCxZQUFNLFFBREM7QUFFUEksa0JBQVk7QUFDVkMseUJBQWlCO0FBQ2ZMLGdCQUFNLE9BRFM7QUFFZk0sdUJBQWEsSUFGRTtBQUdmQyxpQkFBTztBQUNMUCxrQkFBTSxRQURELEVBSFEsRUFEUDs7O0FBUVZR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bEY7QUFDRDs7QUFFRHhCLFlBQUlDLElBQUosRUFBVUEsS0FBS3dCLFNBQUwsQ0FBZSxDQUFmLENBQVY7QUFDRCxPQVhJLEVBQVA7O0FBYUQsR0FsSGMsRUFBakIiLCJmaWxlIjoiZHluYW1pYy1pbXBvcnQtY2h1bmtuYW1lLmpzIiwic291cmNlc0NvbnRlbnQiOlsiaW1wb3J0IHZtIGZyb20gJ3ZtJ1xuaW1wb3J0IGRvY3NVcmwgZnJvbSAnLi4vZG9jc1VybCdcblxubW9kdWxlLmV4cG9ydHMgPSB7XG4gIG1ldGE6IHtcbiAgICB0eXBlOiAnc3VnZ2VzdGlvbicsXG4gICAgZG9jczoge1xuICAgICAgdXJsOiBkb2NzVXJsKCdkeW5hbWljLWltcG9ydC1jaHVua25hbWUnKSxcbiAgICB9LFxuICAgIHNjaGVtYTogW3tcbiAgICAgIHR5cGU6ICdvYmplY3QnLFxuICAgICAgcHJvcGVydGllczoge1xuICAgICAgICBpbXBvcnRGdW5jdGlvbnM6IHtcbiAgICAgICAgICB0eXBlOiAnYXJyYXknLFxuICAgICAgICAgIHVuaXF1ZUl0ZW1zOiB0cnVlLFxuICAgICAgICAgIGl0ZW1zOiB7XG4gICAgICAgICAgICB0eXBlOiAnc3RyaW5nJyxcbiAgICAgICAgICB9LFxuICAgICAgICB9LFxuICAgICAgICB3ZWJwYWNrQ2h1bmtuYW1lRm9ybWF0OiB7XG4gICAgICAgICAgdHlwZTogJ3N0cmluZycsXG4gICAgICAgIH0sXG4gICAgICB9LFxuICAgIH1dLFxuICB9LFxuXG4gIGNyZWF0ZTogZnVuY3Rpb24gKGNvbnRleHQpIHtcbiAgICBjb25zdCBjb25maWcgPSBjb250ZXh0Lm9wdGlvbnNbMF1cbiAgICBjb25zdCB7IGltcG9ydEZ1bmN0aW9ucyA9IFtdIH0gPSBjb25maWcgfHwge31cbiAgICBjb25zdCB7IHdlYnBhY2tDaHVua25hbWVGb3JtYXQgPSAnWzAtOWEtekEtWi1fLy5dKycgfSA9IGNvbmZpZyB8fCB7fVxuXG4gICAgY29uc3QgcGFkZGVkQ29tbWVudFJlZ2V4ID0gL14gKFxcU1tcXHNcXFNdK1xcUykgJC9cbiAgICBjb25zdCBjb21tZW50U3R5bGVSZWdleCA9IC9eKCBcXHcrOiAoW1wiJ11bXlwiJ10qW1wiJ118XFxkK3xmYWxzZXx0cnVlKSw/KSsgJC9cbiAgICBjb25zdCBjaHVua1N1YnN0ckZvcm1hdCA9IGAgd2VicGFja0NodW5rTmFtZTogW1wiJ10ke3dlYnBhY2tDaHVua25hbWVGb3JtYXR9W1wiJ10sPyBgXG4gICAgY29uc3QgY2h1bmtTdWJzdHJSZWdleCA9IG5ldyBSZWdFeHAoY2h1bmtTdWJzdHJGb3JtYXQpXG5cbiAgICBmdW5jdGlvbiBydW4obm9kZSwgYXJnKSB7XG4gICAgICBjb25zdCBzb3VyY2VDb2RlID0gY29udGV4dC5nZXRTb3VyY2VDb2RlKClcbiAgICAgIGNvbnN0IGxlYWRpbmdDb21tZW50cyA9IHNvdXJjZUNvZGUuZ2V0Q29tbWVudHNCZWZvcmVcbiAgICAgICAgPyBzb3VyY2VDb2RlLmdldENvbW1lbnRzQmVmb3JlKGFyZykgLy8gVGhpcyBtZXRob2QgaXMgYXZhaWxhYmxlIGluIEVTTGludCA+PSA0LlxuICAgICAgICA6IHNvdXJjZUNvZGUuZ2V0Q29tbWVudHMoYXJnKS5sZWFkaW5nIC8vIFRoaXMgbWV0aG9kIGlzIGRlcHJlY2F0ZWQgaW4gRVNMaW50IDcuXG5cbiAgICAgIGlmICghbGVhZGluZ0NvbW1lbnRzIHx8IGxlYWRpbmdDb21tZW50cy5sZW5ndGggPT09IDApIHtcbiAgICAgICAgY29udGV4dC5yZXBvcnQoe1xuICAgICAgICAgIG5vZGUsXG4gICAgICAgICAgbWVzc2FnZTogJ2R5bmFtaWMgaW1wb3J0cyByZXF1aXJlIGEgbGVhZGluZyBjb21tZW50IHdpdGggdGhlIHdlYnBhY2sgY2h1bmtuYW1lJyxcbiAgICAgICAgfSlcbiAgICAgICAgcmV0dXJuXG4gICAgICB9XG5cbiAgICAgIGxldCBpc0NodW5rbmFtZVByZXNlbnQgPSBmYWxzZVxuXG4gICAgICBmb3IgKGNvbnN0IGNvbW1lbnQgb2YgbGVhZGluZ0NvbW1lbnRzKSB7XG4gICAgICAgIGlmIChjb21tZW50LnR5cGUgIT09ICdCbG9jaycpIHtcbiAgICAgICAgICBjb250ZXh0LnJlcG9ydCh7XG4gICAgICAgICAgICBub2RlLFxuICAgICAgICAgICAgbWVzc2FnZTogJ2R5bmFtaWMgaW1wb3J0cyByZXF1aXJlIGEgLyogZm9vICovIHN0eWxlIGNvbW1lbnQsIG5vdCBhIC8vIGZvbyBjb21tZW50JyxcbiAgICAgICAgICB9KVxuICAgICAgICAgIHJldHVyblxuICAgICAgICB9XG5cbiAgICAgICAgaWYgKCFwYWRkZWRDb21tZW50UmVnZXgudGVzdChjb21tZW50LnZhbHVlKSkge1xuICAgICAgICAgIGNvbnRleHQucmVwb3J0KHtcbiAgICAgICAgICAgIG5vZGUsXG4gICAgICAgICAgICBtZXNzYWdlOiBgZHluYW1pYyBpbXBvcnRzIHJlcXVpcmUgYSBibG9jayBjb21tZW50IHBhZGRlZCB3aXRoIHNwYWNlcyAtIC8qIGZvbyAqL2AsXG4gICAgICAgICAgfSlcbiAgICAgICAgICByZXR1cm5cbiAgICAgICAgfVxuXG4gICAgICAgIHRyeSB7XG4gICAgICAgICAgLy8ganVzdCBsaWtlIHdlYnBhY2sgaXRzZWxmIGRvZXNcbiAgICAgICAgICB2bS5ydW5Jbk5ld0NvbnRleHQoYChmdW5jdGlvbigpe3JldHVybiB7JHtjb21tZW50LnZhbHVlfX19KSgpYClcbiAgICAgICAgfVxuICAgICAgICBjYXRjaCAoZXJyb3IpIHtcbiAgICAgICAgICBjb250ZXh0LnJlcG9ydCh7XG4gICAgICAgICAgICBub2RlLFxuICAgICAgICAgICAgbWVzc2FnZTogYGR5bmFtaWMgaW1wb3J0cyByZXF1aXJlIGEgXCJ3ZWJwYWNrXCIgY29tbWVudCB3aXRoIHZhbGlkIHN5bnRheGAsXG4gICAgICAgICAgfSlcbiAgICAgICAgICByZXR1cm5cbiAgICAgICAgfVxuXG4gICAgICAgIGlmICghY29tbWVudFN0eWxlUmVnZXgudGVzdChjb21tZW50LnZhbHVlKSkge1xuICAgICAgICAgIGNvbnRleHQucmVwb3J0KHtcbiAgICAgICAgICAgIG5vZGUsXG4gICAgICAgICAgICBtZXNzYWdlOlxuICAgICAgICAgICAgICBgZHluYW1pYyBpbXBvcnRzIHJlcXVpcmUgYSBsZWFkaW5nIGNvbW1lbnQgaW4gdGhlIGZvcm0gLyoke2NodW5rU3Vic3RyRm9ybWF0fSovYCxcbiAgICAgICAgICB9KVxuICAgICAgICAgIHJldHVyblxuICAgICAgICB9XG5cbiAgICAgICAgaWYgKGNodW5rU3Vic3RyUmVnZXgudGVzdChjb21tZW50LnZhbHVlKSkge1xuICAgICAgICAgIGlzQ2h1bmtuYW1lUHJlc2VudCA9IHRydWVcbiAgICAgICAgfVxuICAgICAgfVxuXG4gICAgICBpZiAoIWlzQ2h1bmtuYW1lUHJlc2VudCkge1xuICAgICAgICBjb250ZXh0LnJlcG9ydCh7XG4gICAgICAgICAgbm9kZSxcbiAgICAgICAgICBtZXNzYWdlOlxuICAgICAgICAgICAgYGR5bmFtaWMgaW1wb3J0cyByZXF1aXJlIGEgbGVhZGluZyBjb21tZW50IGluIHRoZSBmb3JtIC8qJHtjaHVua1N1YnN0ckZvcm1hdH0qL2AsXG4gICAgICAgIH0pXG4gICAgICB9XG4gICAgfVxuXG4gICAgcmV0dXJuIHtcbiAgICAgIEltcG9ydEV4cHJlc3Npb24obm9kZSkge1xuICAgICAgICBydW4obm9kZSwgbm9kZS5zb3VyY2UpXG4gICAgICB9LFxuXG4gICAgICBDYWxsRXhwcmVzc2lvbihub2RlKSB7XG4gICAgICAgIGlmIChub2RlLmNhbGxlZS50eXBlICE9PSAnSW1wb3J0JyAmJiBpbXBvcnRGdW5jdGlvbnMuaW5kZXhPZihub2RlLmNhbGxlZS5uYW1lKSA8IDApIHtcbiAgICAgICAgICByZXR1cm5cbiAgICAgICAgfVxuXG4gICAgICAgIHJ1bihub2RlLCBub2RlLmFyZ3VtZW50c1swXSlcbiAgICAgIH0sXG4gICAgfVxuICB9LFxufVxuIl19