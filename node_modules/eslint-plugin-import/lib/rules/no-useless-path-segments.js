'use strict';




var _ignore = require('eslint-module-utils/ignore');
var _moduleVisitor = require('eslint-module-utils/moduleVisitor');var _moduleVisitor2 = _interopRequireDefault(_moduleVisitor);
var _resolve = require('eslint-module-utils/resolve');var _resolve2 = _interopRequireDefault(_resolve);
var _path = require('path');var _path2 = _interopRequireDefault(_path);
var _docsUrl = require('../docsUrl');var _docsUrl2 = _interopRequireDefault(_docsUrl);function _interopRequireDefault(obj) {return obj && obj.__esModule ? obj : { default: obj };}

/**
                                                                                                                                                                                     * convert a potentially relative path from node utils into a true
                                                                                                                                                                                     * relative path.
                                                                                                                                                                                     *
                                                                                                                                                                                     * ../ -> ..
                                                                                                                                                                                     * ./ -> .
                                                                                                                                                                                     * .foo/bar -> ./.foo/bar
                                                                                                                                                                                     * ..foo/bar -> ./..foo/bar
                                                                                                                                                                                     * foo/bar -> ./foo/bar
                                                                                                                                                                                     *
                                                                                                                                                                                     * @param relativePath {string} relative posix path potentially missing leading './'
                                                                                                                                                                                     * @returns {string} relative posix path that always starts with a ./
                                                                                                                                                                                     **/
function toRelativePath(relativePath) {
  const stripped = relativePath.replace(/\/$/g, ''); // Remove trailing /

  return (/^((\.\.)|(\.))($|\/)/.test(stripped) ? stripped : `./${stripped}`);
} /**
   * @fileOverview Ensures that there are no useless path segments
   * @author Thomas Grainger
   */function normalize(fn) {return toRelativePath(_path2.default.posix.normalize(fn));
}

function countRelativeParents(pathSegments) {
  return pathSegments.reduce((sum, pathSegment) => pathSegment === '..' ? sum + 1 : sum, 0);
}

module.exports = {
  meta: {
    type: 'suggestion',
    docs: {
      url: (0, _docsUrl2.default)('no-useless-path-segments') },


    fixable: 'code',

    schema: [
    {
      type: 'object',
      properties: {
        commonjs: { type: 'boolean' },
        noUselessIndex: { type: 'boolean' } },

      additionalProperties: false }] },




  create(context) {
    const currentDir = _path2.default.dirname(context.getFilename());
    const options = context.options[0];

    function checkSourceValue(source) {const
      importPath = source.value;

      function reportWithProposedPath(proposedPath) {
        context.report({
          node: source,
          // Note: Using messageIds is not possible due to the support for ESLint 2 and 3
          message: `Useless path segments for "${importPath}", should be "${proposedPath}"`,
          fix: fixer => proposedPath && fixer.replaceText(source, JSON.stringify(proposedPath)) });

      }

      // Only relative imports are relevant for this rule --> Skip checking
      if (!importPath.startsWith('.')) {
        return;
      }

      // Report rule violation if path is not the shortest possible
      const resolvedPath = (0, _resolve2.default)(importPath, context);
      const normedPath = normalize(importPath);
      const resolvedNormedPath = (0, _resolve2.default)(normedPath, context);
      if (normedPath !== importPath && resolvedPath === resolvedNormedPath) {
        return reportWithProposedPath(normedPath);
      }

      const fileExtensions = (0, _ignore.getFileExtensions)(context.settings);
      const regexUnnecessaryIndex = new RegExp(
      `.*\\/index(\\${Array.from(fileExtensions).join('|\\')})?$`);


      // Check if path contains unnecessary index (including a configured extension)
      if (options && options.noUselessIndex && regexUnnecessaryIndex.test(importPath)) {
        const parentDirectory = _path2.default.dirname(importPath);

        // Try to find ambiguous imports
        if (parentDirectory !== '.' && parentDirectory !== '..') {
          for (let fileExtension of fileExtensions) {
            if ((0, _resolve2.default)(`${parentDirectory}${fileExtension}`, context)) {
              return reportWithProposedPath(`${parentDirectory}/`);
            }
          }
        }

        return reportWithProposedPath(parentDirectory);
      }

      // Path is shortest possible + starts from the current directory --> Return directly
      if (importPath.startsWith('./')) {
        return;
      }

      // Path is not existing --> Return directly (following code requires path to be defined)
      if (resolvedPath === undefined) {
        return;
      }

      const expected = _path2.default.relative(currentDir, resolvedPath); // Expected import path
      const expectedSplit = expected.split(_path2.default.sep); // Split by / or \ (depending on OS)
      const importPathSplit = importPath.replace(/^\.\//, '').split('/');
      const countImportPathRelativeParents = countRelativeParents(importPathSplit);
      const countExpectedRelativeParents = countRelativeParents(expectedSplit);
      const diff = countImportPathRelativeParents - countExpectedRelativeParents;

      // Same number of relative parents --> Paths are the same --> Return directly
      if (diff <= 0) {
        return;
      }

      // Report and propose minimal number of required relative parents
      return reportWithProposedPath(
      toRelativePath(
      importPathSplit.
      slice(0, countExpectedRelativeParents).
      concat(importPathSplit.slice(countImportPathRelativeParents + diff)).
      join('/')));


    }

    return (0, _moduleVisitor2.default)(checkSourceValue, options);
  } };
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIi4uLy4uL3NyYy9ydWxlcy9uby11c2VsZXNzLXBhdGgtc2VnbWVudHMuanMiXSwibmFtZXMiOlsidG9SZWxhdGl2ZVBhdGgiLCJyZWxhdGl2ZVBhdGgiLCJzdHJpcHBlZCIsInJlcGxhY2UiLCJ0ZXN0Iiwibm9ybWFsaXplIiwiZm4iLCJwYXRoIiwicG9zaXgiLCJjb3VudFJlbGF0aXZlUGFyZW50cyIsInBhdGhTZWdtZW50cyIsInJlZHVjZSIsInN1bSIsInBhdGhTZWdtZW50IiwibW9kdWxlIiwiZXhwb3J0cyIsIm1ldGEiLCJ0eXBlIiwiZG9jcyIsInVybCIsImZpeGFibGUiLCJzY2hlbWEiLCJwcm9wZXJ0aWVzIiwiY29tbW9uanMiLCJub1VzZWxlc3NJbmRleCIsImFkZGl0aW9uYWxQcm9wZXJ0aWVzIiwiY3JlYXRlIiwiY29udGV4dCIsImN1cnJlbnREaXIiLCJkaXJuYW1lIiwiZ2V0RmlsZW5hbWUiLCJvcHRpb25zIiwiY2hlY2tTb3VyY2VWYWx1ZSIsInNvdXJjZSIsImltcG9ydFBhdGgiLCJ2YWx1ZSIsInJlcG9ydFdpdGhQcm9wb3NlZFBhdGgiLCJwcm9wb3NlZFBhdGgiLCJyZXBvcnQiLCJub2RlIiwibWVzc2FnZSIsImZpeCIsImZpeGVyIiwicmVwbGFjZVRleHQiLCJKU09OIiwic3RyaW5naWZ5Iiwic3RhcnRzV2l0aCIsInJlc29sdmVkUGF0aCIsIm5vcm1lZFBhdGgiLCJyZXNvbHZlZE5vcm1lZFBhdGgiLCJmaWxlRXh0ZW5zaW9ucyIsInNldHRpbmdzIiwicmVnZXhVbm5lY2Vzc2FyeUluZGV4IiwiUmVnRXhwIiwiQXJyYXkiLCJmcm9tIiwiam9pbiIsInBhcmVudERpcmVjdG9yeSIsImZpbGVFeHRlbnNpb24iLCJ1bmRlZmluZWQiLCJleHBlY3RlZCIsInJlbGF0aXZlIiwiZXhwZWN0ZWRTcGxpdCIsInNwbGl0Iiwic2VwIiwiaW1wb3J0UGF0aFNwbGl0IiwiY291bnRJbXBvcnRQYXRoUmVsYXRpdmVQYXJlbnRzIiwiY291bnRFeHBl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O0FBRUdHLFlBRkgsQ0FFVUwsZ0JBQWdCSSxLQUFoQixDQUFzQkgsaUNBQWlDRSxJQUF2RCxDQUZWO0FBR0daLFVBSEgsQ0FHUSxHQUhSLENBREYsQ0FESyxDQUFQOzs7QUFRRDs7QUFFRCxXQUFPLDZCQUFjeEIsZ0JBQWQsRUFBZ0NELE9BQWhDLENBQVA7QUFDRCxHQXpHYyxFQUFqQiIsImZpbGUiOiJuby11c2VsZXNzLXBhdGgtc2VnbWVudHMuanMiLCJzb3VyY2VzQ29udGVudCI6WyIvKipcbiAqIEBmaWxlT3ZlcnZpZXcgRW5zdXJlcyB0aGF0IHRoZXJlIGFyZSBubyB1c2VsZXNzIHBhdGggc2VnbWVudHNcbiAqIEBhdXRob3IgVGhvbWFzIEdyYWluZ2VyXG4gKi9cblxuaW1wb3J0IHsgZ2V0RmlsZUV4dGVuc2lvbnMgfSBmcm9tICdlc2xpbnQtbW9kdWxlLXV0aWxzL2lnbm9yZSdcbmltcG9ydCBtb2R1bGVWaXNpdG9yIGZyb20gJ2VzbGludC1tb2R1bGUtdXRpbHMvbW9kdWxlVmlzaXRvcidcbmltcG9ydCByZXNvbHZlIGZyb20gJ2VzbGludC1tb2R1bGUtdXRpbHMvcmVzb2x2ZSdcbmltcG9ydCBwYXRoIGZyb20gJ3BhdGgnXG5pbXBvcnQgZG9jc1VybCBmcm9tICcuLi9kb2NzVXJsJ1xuXG4vKipcbiAqIGNvbnZlcnQgYSBwb3RlbnRpYWxseSByZWxhdGl2ZSBwYXRoIGZyb20gbm9kZSB1dGlscyBpbnRvIGEgdHJ1ZVxuICogcmVsYXRpdmUgcGF0aC5cbiAqXG4gKiAuLi8gLT4gLi5cbiAqIC4vIC0+IC5cbiAqIC5mb28vYmFyIC0+IC4vLmZvby9iYXJcbiAqIC4uZm9vL2JhciAtPiAuLy4uZm9vL2JhclxuICogZm9vL2JhciAtPiAuL2Zvby9iYXJcbiAqXG4gKiBAcGFyYW0gcmVsYXRpdmVQYXRoIHtzdHJpbmd9IHJlbGF0aXZlIHBvc2l4IHBhdGggcG90ZW50aWFsbHkgbWlzc2luZyBsZWFkaW5nICcuLydcbiAqIEByZXR1cm5zIHtzdHJpbmd9IHJlbGF0aXZlIHBvc2l4IHBhdGggdGhhdCBhbHdheXMgc3RhcnRzIHdpdGggYSAuL1xuICoqL1xuZnVuY3Rpb24gdG9SZWxhdGl2ZVBhdGgocmVsYXRpdmVQYXRoKSB7XG4gIGNvbnN0IHN0cmlwcGVkID0gcmVsYXRpdmVQYXRoLnJlcGxhY2UoL1xcLyQvZywgJycpIC8vIFJlbW92ZSB0cmFpbGluZyAvXG5cbiAgcmV0dXJuIC9eKChcXC5cXC4pfChcXC4pKSgkfFxcLykvLnRlc3Qoc3RyaXBwZWQpID8gc3RyaXBwZWQgOiBgLi8ke3N0cmlwcGVkfWBcbn1cblxuZnVuY3Rpb24gbm9ybWFsaXplKGZuKSB7XG4gIHJldHVybiB0b1JlbGF0aXZlUGF0aChwYXRoLnBvc2l4Lm5vcm1hbGl6ZShmbikpXG59XG5cbmZ1bmN0aW9uIGNvdW50UmVsYXRpdmVQYXJlbnRzKHBhdGhTZWdtZW50cykge1xuICByZXR1cm4gcGF0aFNlZ21lbnRzLnJlZHVjZSgoc3VtLCBwYXRoU2VnbWVudCkgPT4gcGF0aFNlZ21lbnQgPT09ICcuLicgPyBzdW0gKyAxIDogc3VtLCAwKVxufVxuXG5tb2R1bGUuZXhwb3J0cyA9IHtcbiAgbWV0YToge1xuICAgIHR5cGU6ICdzdWdnZXN0aW9uJyxcbiAgICBkb2NzOiB7XG4gICAgICB1cmw6IGRvY3NVcmwoJ25vLXVzZWxlc3MtcGF0aC1zZWdtZW50cycpLFxuICAgIH0sXG5cbiAgICBmaXhhYmxlOiAnY29kZScsXG5cbiAgICBzY2hlbWE6IFtcbiAgICAgIHtcbiAgICAgICAgdHlwZTogJ29iamVjdCcsXG4gICAgICAgIHByb3BlcnRpZXM6IHtcbiAgICAgICAgICBjb21tb25qczogeyB0eXBlOiAnYm9vbGVhbicgfSxcbiAgICAgICAgICBub1VzZWxlc3NJbmRleDogeyB0eXBlOiAnYm9vbGVhbicgfSxcbiAgICAgICAgfSxcbiAgICAgICAgYWRkaXRpb25hbFByb3BlcnRpZXM6IGZhbHNlLFxuICAgICAgfSxcbiAgICBdLFxuICB9LFxuXG4gIGNyZWF0ZShjb250ZXh0KSB7XG4gICAgY29uc3QgY3VycmVudERpciA9IHBhdGguZGlybmFtZShjb250ZXh0LmdldEZpbGVuYW1lKCkpXG4gICAgY29uc3Qgb3B0aW9ucyA9IGNvbnRleHQub3B0aW9uc1swXVxuXG4gICAgZnVuY3Rpb24gY2hlY2tTb3VyY2VWYWx1ZShzb3VyY2UpIHtcbiAgICAgIGNvbnN0IHsgdmFsdWU6IGltcG9ydFBhdGggfSA9IHNvdXJjZVxuXG4gICAgICBmdW5jdGlvbiByZXBvcnRXaXRoUHJvcG9zZWRQYXRoKHByb3Bvc2VkUGF0aCkge1xuICAgICAgICBjb250ZXh0LnJlcG9ydCh7XG4gICAgICAgICAgbm9kZTogc291cmNlLFxuICAgICAgICAgIC8vIE5vdGU6IFVzaW5nIG1lc3NhZ2VJZHMgaXMgbm90IHBvc3NpYmxlIGR1ZSB0byB0aGUgc3VwcG9ydCBmb3IgRVNMaW50IDIgYW5kIDNcbiAgICAgICAgICBtZXNzYWdlOiBgVXNlbGVzcyBwYXRoIHNlZ21lbnRzIGZvciBcIiR7aW1wb3J0UGF0aH1cIiwgc2hvdWxkIGJlIFwiJHtwcm9wb3NlZFBhdGh9XCJgLFxuICAgICAgICAgIGZpeDogZml4ZXIgPT4gcHJvcG9zZWRQYXRoICYmIGZpeGVyLnJlcGxhY2VUZXh0KHNvdXJjZSwgSlNPTi5zdHJpbmdpZnkocHJvcG9zZWRQYXRoKSksXG4gICAgICAgIH0pXG4gICAgICB9XG5cbiAgICAgIC8vIE9ubHkgcmVsYXRpdmUgaW1wb3J0cyBhcmUgcmVsZXZhbnQgZm9yIHRoaXMgcnVsZSAtLT4gU2tpcCBjaGVja2luZ1xuICAgICAgaWYgKCFpbXBvcnRQYXRoLnN0YXJ0c1dpdGgoJy4nKSkge1xuICAgICAgICByZXR1cm5cbiAgICAgIH1cblxuICAgICAgLy8gUmVwb3J0IHJ1bGUgdmlvbGF0aW9uIGlmIHBhdGggaXMgbm90IHRoZSBzaG9ydGVzdCBwb3NzaWJsZVxuICAgICAgY29uc3QgcmVzb2x2ZWRQYXRoID0gcmVzb2x2ZShpbXBvcnRQYXRoLCBjb250ZXh0KVxuICAgICAgY29uc3Qgbm9ybWVkUGF0aCA9IG5vcm1hbGl6ZShpbXBvcnRQYXRoKVxuICAgICAgY29uc3QgcmVzb2x2ZWROb3JtZWRQYXRoID0gcmVzb2x2ZShub3JtZWRQYXRoLCBjb250ZXh0KVxuICAgICAgaWYgKG5vcm1lZFBhdGggIT09IGltcG9ydFBhdGggJiYgcmVzb2x2ZWRQYXRoID09PSByZXNvbHZlZE5vcm1lZFBhdGgpIHtcbiAgICAgICAgcmV0dXJuIHJlcG9ydFdpdGhQcm9wb3NlZFBhdGgobm9ybWVkUGF0aClcbiAgICAgIH1cblxuICAgICAgY29uc3QgZmlsZUV4dGVuc2lvbnMgPSBnZXRGaWxlRXh0ZW5zaW9ucyhjb250ZXh0LnNldHRpbmdzKVxuICAgICAgY29uc3QgcmVnZXhVbm5lY2Vzc2FyeUluZGV4ID0gbmV3IFJlZ0V4cChcbiAgICAgICAgYC4qXFxcXC9pbmRleChcXFxcJHtBcnJheS5mcm9tKGZpbGVFeHRlbnNpb25zKS5qb2luKCd8XFxcXCcpfSk/JGBcbiAgICAgIClcblxuICAgICAgLy8gQ2hlY2sgaWYgcGF0aCBjb250YWlucyB1bm5lY2Vzc2FyeSBpbmRleCAoaW5jbHVkaW5nIGEgY29uZmlndXJlZCBleHRlbnNpb24pXG4gICAgICBpZiAob3B0aW9ucyAmJiBvcHRpb25zLm5vVXNlbGVzc0luZGV4ICYmIHJlZ2V4VW5uZWNlc3NhcnlJbmRleC50ZXN0KGltcG9ydFBhdGgpKSB7XG4gICAgICAgIGNvbnN0IHBhcmVudERpcmVjdG9yeSA9IHBhdGguZGlybmFtZShpbXBvcnRQYXRoKVxuXG4gICAgICAgIC8vIFRyeSB0byBmaW5kIGFtYmlndW91cyBpbXBvcnRzXG4gICAgICAgIGlmIChwYXJlbnREaXJlY3RvcnkgIT09ICcuJyAmJiBwYXJlbnREaXJlY3RvcnkgIT09ICcuLicpIHtcbiAgICAgICAgICBmb3IgKGxldCBmaWxlRXh0ZW5zaW9uIG9mIGZpbGVFeHRlbnNpb25zKSB7XG4gICAgICAgICAgICBpZiAocmVzb2x2ZShgJHtwYXJlbnREaXJlY3Rvcnl9JHtmaWxlRXh0ZW5zaW9ufWAsIGNvbnRleHQpKSB7XG4gICAgICAgICAgICAgIHJldHVybiByZXBvcnRXaXRoUHJvcG9zZWRQYXRoKGAke3BhcmVudERpcmVjdG9yeX0vYClcbiAgICAgICAgICAgIH1cbiAgICAgICAgICB9XG4gICAgICAgIH1cblxuICAgICAgICByZXR1cm4gcmVwb3J0V2l0aFByb3Bvc2VkUGF0aChwYXJlbnREaXJlY3RvcnkpXG4gICAgICB9XG5cbiAgICAgIC8vIFBhdGggaXMgc2hvcnRlc3QgcG9zc2libGUgKyBzdGFydHMgZnJvbSB0aGUgY3VycmVudCBkaXJlY3RvcnkgLS0+IFJldHVybiBkaXJlY3RseVxuICAgICAgaWYgKGltcG9ydFBhdGguc3RhcnRzV2l0aCgnLi8nKSkge1xuICAgICAgICByZXR1cm5cbiAgICAgIH1cblxuICAgICAgLy8gUGF0aCBpcyBub3QgZXhpc3RpbmcgLS0+IFJldHVybiBkaXJlY3RseSAoZm9sbG93aW5nIGNvZGUgcmVxdWlyZXMgcGF0aCB0byBiZSBkZWZpbmVkKVxuICAgICAgaWYgKHJlc29sdmVkUGF0aCA9PT0gdW5kZWZpbmVkKSB7XG4gICAgICAgIHJldHVyblxuICAgICAgfVxuXG4gICAgICBjb25zdCBleHBlY3RlZCA9IHBhdGgucmVsYXRpdmUoY3VycmVudERpciwgcmVzb2x2ZWRQYXRoKSAvLyBFeHBlY3RlZCBpbXBvcnQgcGF0aFxuICAgICAgY29uc3QgZXhwZWN0ZWRTcGxpdCA9IGV4cGVjdGVkLnNwbGl0KHBhdGguc2VwKSAvLyBTcGxpdCBieSAvIG9yIFxcIChkZXBlbmRpbmcgb24gT1MpXG4gICAgICBjb25zdCBpbXBvcnRQYXRoU3BsaXQgPSBpbXBvcnRQYXRoLnJlcGxhY2UoL15cXC5cXC8vLCAnJykuc3BsaXQoJy8nKVxuICAgICAgY29uc3QgY291bnRJbXBvcnRQYXRoUmVsYXRpdmVQYXJlbnRzID0gY291bnRSZWxhdGl2ZVBhcmVudHMoaW1wb3J0UGF0aFNwbGl0KVxuICAgICAgY29uc3QgY291bnRFeHBlY3RlZFJlbGF0aXZlUGFyZW50cyA9IGNvdW50UmVsYXRpdmVQYXJlbnRzKGV4cGVjdGVkU3BsaXQpXG4gICAgICBjb25zdCBkaWZmID0gY291bnRJbXBvcnRQYXRoUmVsYXRpdmVQYXJlbnRzIC0gY291bnRFeHBlY3RlZFJlbGF0aXZlUGFyZW50c1xuXG4gICAgICAvLyBTYW1lIG51bWJlciBvZiByZWxhdGl2ZSBwYXJlbnRzIC0tPiBQYXRocyBhcmUgdGhlIHNhbWUgLS0+IFJldHVybiBkaXJlY3RseVxuICAgICAgaWYgKGRpZmYgPD0gMCkge1xuICAgICAgICByZXR1cm5cbiAgICAgIH1cblxuICAgICAgLy8gUmVwb3J0IGFuZCBwcm9wb3NlIG1pbmltYWwgbnVtYmVyIG9mIHJlcXVpcmVkIHJlbGF0aXZlIHBhcmVudHNcbiAgICAgIHJldHVybiByZXBvcnRXaXRoUHJvcG9zZWRQYXRoKFxuICAgICAgICB0b1JlbGF0aXZlUGF0aChcbiAgICAgICAgICBpbXBvcnRQYXRoU3BsaXRcbiAgICAgICAgICAgIC5zbGljZSgwLCBjb3VudEV4cGVjdGVkUmVsYXRpdmVQYXJlbnRzKVxuICAgICAgICAgICAgLmNvbmNhdChpbXBvcnRQYXRoU3BsaXQuc2xpY2UoY291bnRJbXBvcnRQYXRoUmVsYXRpdmVQYXJlbnRzICsgZGlmZikpXG4gICAgICAgICAgICAuam9pbignLycpXG4gICAgICAgIClcbiAgICAgIClcbiAgICB9XG5cbiAgICByZXR1cm4gbW9kdWxlVmlzaXRvcihjaGVja1NvdXJjZVZhbHVlLCBvcHRpb25zKVxuICB9LFxufVxuIl19