'use strict';var _slicedToArray = function () {function sliceIterator(arr, i) {var _arr = [];var _n = true;var _d = false;var _e = undefined;try {for (var _i = arr[Symbol.iterator](), _s; !(_n = (_s = _i.next()).done); _n = true) {_arr.push(_s.value);if (i && _arr.length === i) break;}} catch (err) {_d = true;_e = err;} finally {try {if (!_n && _i["return"]) _i["return"]();} finally {if (_d) throw _e;}}return _arr;}return function (arr, i) {if (Array.isArray(arr)) {return arr;} else if (Symbol.iterator in Object(arr)) {return sliceIterator(arr, i);} else {throw new TypeError("Invalid attempt to destructure non-iterable instance");}};}();var _docsUrl = require('../docsUrl');var _docsUrl2 = _interopRequireDefault(_docsUrl);function _interopRequireDefault(obj) {return obj && obj.__esModule ? obj : { 'default': obj };}

function getEmptyBlockRange(tokens, index) {
  var token = tokens[index];
  var nextToken = tokens[index + 1];
  var prevToken = tokens[index - 1];
  var start = token.range[0];
  var end = nextToken.range[1];

  // Remove block tokens and the previous comma
  if (prevToken.value === ',' || prevToken.value === 'type' || prevToken.value === 'typeof') {
    start = prevToken.range[0];
  }

  return [start, end];
}

module.exports = {
  meta: {
    type: 'suggestion',
    docs: {
      category: 'Helpful warnings',
      description: 'Forbid empty named import blocks.',
      url: (0, _docsUrl2['default'])('no-empty-named-blocks') },

    fixable: 'code',
    schema: [],
    hasSuggestions: true },


  create: function () {function create(context) {
      var importsWithoutNameds = [];

      return {
        ImportDeclaration: function () {function ImportDeclaration(node) {
            if (!node.specifiers.some(function (x) {return x.type === 'ImportSpecifier';})) {
              importsWithoutNameds.push(node);
            }
          }return ImportDeclaration;}(),

        'Program:exit': function () {function ProgramExit(program) {
            var importsTokens = importsWithoutNameds.map(function (node) {return [node, program.tokens.filter(function (x) {return x.range[0] >= node.range[0] && x.range[1] <= node.range[1];})];});

            importsTokens.forEach(function (_ref) {var _ref2 = _slicedToArray(_ref, 2),node = _ref2[0],tokens = _ref2[1];
              tokens.forEach(function (token) {
                var idx = program.tokens.indexOf(token);
                var nextToken = program.tokens[idx + 1];

                if (nextToken && token.value === '{' && nextToken.value === '}') {
                  var hasOtherIdentifiers = tokens.some(function (token) {return token.type === 'Identifier' &&
                    token.value !== 'from' &&
                    token.value !== 'type' &&
                    token.value !== 'typeof';});


                  // If it has no other identifiers it's the only thing in the import, so we can either remove the import
                  // completely or transform it in a side-effects only import
                  if (!hasOtherIdentifiers) {
                    context.report({
                      node: node,
                      message: 'Unexpected empty named import block',
                      suggest: [
                      {
                        desc: 'Remove unused import',
                        fix: function () {function fix(fixer) {
                            // Remove the whole import
                            return fixer.remove(node);
                          }return fix;}() },

                      {
                        desc: 'Remove empty import block',
                        fix: function () {function fix(fixer) {
                            // Remove the empty block and the 'from' token, leaving the import only for its side
                            // effects, e.g. `import 'mod'`
                            var sourceCode = context.getSourceCode();
                            var fromToken = program.tokens.find(function (t) {return t.value === 'from';});
                            var importToken = program.tokens.find(function (t) {return t.value === 'import';});
                            var hasSpaceAfterFrom = sourceCode.isSpaceBetween(fromToken, sourceCode.getTokenAfter(fromToken));
                            var hasSpaceAfterImport = sourceCode.isSpaceBetween(importToken, sourceCode.getTokenAfter(fromToken));var _getEmptyBlockRange =

                            getEmptyBlockRange(program.tokens, idx),_getEmptyBlockRange2 = _slicedToArray(_getEmptyBlockRange, 1),start = _getEmptyBlockRange2[0];var _fromToken$range = _slicedToArray(
                            fromToken.range, 2),end = _fromToken$range[1];
                            var range = [start, hasSpaceAfterFrom ? end + 1 : end];

                            return fixer.replaceTextRange(range, hasSpaceAfterImport ? '' : ' ');
                          }return fix;}() }] });



                  } else {
                    context.report({
                      node: node,
                      message: 'Unexpected empty named import block',
                      fix: function () {function fix(fixer) {
                          return fixer.removeRange(getEmptyBlockRange(program.tokens, idx));
                        }return fix;}() });

                  }
                }
              });
            });
          }return ProgramExit;}() };

    }return create;}() };
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIi4uLy4uL3NyYy9ydWxlcy9uby1lbXB0eS1uYW1lZC1ibG9ja3MuanMiXSwibmFtZXMiOlsiZ2V0RW1wdHlCbG9ja1JhbmdlIiwidG9rZW5zIiwiaW5kZXgiLCJ0b2tlbiIsIm5leHRUb2tlbiIsInByZXZUb2tlbiIsInN0YXJ0IiwicmFuZ2UiLCJlbmQiLCJ2YWx1ZSIsIm1vZHVsZSIsImV4cG9ydHMiLCJtZXRhIiwidHlwZSIsImRvY3MiLCJjYXRlZ29yeSIsImRlc2NyaXB0aW9uIiwidXJsIiwiZml4YWJsZSIsInNjaGVtYSIsImhhc1N1Z2dlc3Rpb25zIiwiY3JlYXRlIiwiY29udGV4dCIsImltcG9ydHNXaXRob3V0TmFtZWRzIiwiSW1wb3J0RGVjbGFyYXRpb24iLCJub2RlIiwic3BlY2lmaWVycyIsInNvbWUiLCJ4IiwicHVzaCIsInByb2dyYW0iLCJpbXBvcnRzVG9rZW5zIiwibWFwIiwiZmlsdGVyIiwiZm9yRWFjaCIsImlkeCIsImluZGV4T2YiLCJoYXNPdGhlcklkZW50aWZpZXJzIiwicmVwb3J0IiwibWVzc2FnZSIsInN1Z2dlc3QiLCJkZXNjIiwiZml4IiwiZml4ZXIiLCJyZW1vdmUiLCJzb3VyY2VDb2RlIiwiZ2V0U291cmNlQ29kZSIsImZyb21Ub2tlbiIsImZpbmQiLCJ0IiwiaW1wb3J0VG9rZW4iLCJoYXNTcGFjZUFmdGVyRnJvbSIsImlzU3BhY2VCZXR3ZWVuIiwiZ2V0VG9rZW5BZnRlciIsImhhc1NwYWNlQWZ0ZXJJbXBvcnQiLCJyZXBsYWNlVGV4dFJhbmdlIiwicmVtb3ZlUmFuZ2UiXSwibWFwcGluZ3MiOiJxb0JBQUEscUM7O0FBRUEsU0FBU0Esa0JBQVQsQ0FBNEJDLE1BQTVCLEVBQW9DQyxLQUFwQyxFQUEyQztBQUN6QyxNQUFNQyxRQUFRRixPQUFPQyxLQUFQLENBQWQ7QUFDQSxNQUFNRSxZQUFZSCxPQUFPQyxRQUFRLENBQWYsQ0FBbEI7QUFDQSxNQUFNRyxZQUFZSixPQUFPQyxRQUFRLENBQWYsQ0FBbEI7QUFDQSxNQUFJ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YUF6REQ7QUEwREQsV0FwRUksd0JBQVA7O0FBc0VELEtBdEZjLG1CQUFqQiIsImZpbGUiOiJuby1lbXB0eS1uYW1lZC1ibG9ja3MuanMiLCJzb3VyY2VzQ29udGVudCI6WyJpbXBvcnQgZG9jc1VybCBmcm9tICcuLi9kb2NzVXJsJztcblxuZnVuY3Rpb24gZ2V0RW1wdHlCbG9ja1JhbmdlKHRva2VucywgaW5kZXgpIHtcbiAgY29uc3QgdG9rZW4gPSB0b2tlbnNbaW5kZXhdO1xuICBjb25zdCBuZXh0VG9rZW4gPSB0b2tlbnNbaW5kZXggKyAxXTtcbiAgY29uc3QgcHJldlRva2VuID0gdG9rZW5zW2luZGV4IC0gMV07XG4gIGxldCBzdGFydCA9IHRva2VuLnJhbmdlWzBdO1xuICBjb25zdCBlbmQgPSBuZXh0VG9rZW4ucmFuZ2VbMV07XG5cbiAgLy8gUmVtb3ZlIGJsb2NrIHRva2VucyBhbmQgdGhlIHByZXZpb3VzIGNvbW1hXG4gIGlmIChwcmV2VG9rZW4udmFsdWUgPT09ICcsJyB8fCBwcmV2VG9rZW4udmFsdWUgPT09ICd0eXBlJyB8fCBwcmV2VG9rZW4udmFsdWUgPT09ICd0eXBlb2YnKSB7XG4gICAgc3RhcnQgPSBwcmV2VG9rZW4ucmFuZ2VbMF07XG4gIH1cblxuICByZXR1cm4gW3N0YXJ0LCBlbmRdO1xufVxuXG5tb2R1bGUuZXhwb3J0cyA9IHtcbiAgbWV0YToge1xuICAgIHR5cGU6ICdzdWdnZXN0aW9uJyxcbiAgICBkb2NzOiB7XG4gICAgICBjYXRlZ29yeTogJ0hlbHBmdWwgd2FybmluZ3MnLFxuICAgICAgZGVzY3JpcHRpb246ICdGb3JiaWQgZW1wdHkgbmFtZWQgaW1wb3J0IGJsb2Nrcy4nLFxuICAgICAgdXJsOiBkb2NzVXJsKCduby1lbXB0eS1uYW1lZC1ibG9ja3MnKSxcbiAgICB9LFxuICAgIGZpeGFibGU6ICdjb2RlJyxcbiAgICBzY2hlbWE6IFtdLFxuICAgIGhhc1N1Z2dlc3Rpb25zOiB0cnVlLFxuICB9LFxuXG4gIGNyZWF0ZShjb250ZXh0KSB7XG4gICAgY29uc3QgaW1wb3J0c1dpdGhvdXROYW1lZHMgPSBbXTtcblxuICAgIHJldHVybiB7XG4gICAgICBJbXBvcnREZWNsYXJhdGlvbihub2RlKSB7XG4gICAgICAgIGlmICghbm9kZS5zcGVjaWZpZXJzLnNvbWUoKHgpID0+IHgudHlwZSA9PT0gJ0ltcG9ydFNwZWNpZmllcicpKSB7XG4gICAgICAgICAgaW1wb3J0c1dpdGhvdXROYW1lZHMucHVzaChub2RlKTtcbiAgICAgICAgfVxuICAgICAgfSxcblxuICAgICAgJ1Byb2dyYW06ZXhpdCcocHJvZ3JhbSkge1xuICAgICAgICBjb25zdCBpbXBvcnRzVG9rZW5zID0gaW1wb3J0c1dpdGhvdXROYW1lZHMubWFwKChub2RlKSA9PiBbbm9kZSwgcHJvZ3JhbS50b2tlbnMuZmlsdGVyKCh4KSA9PiB4LnJhbmdlWzBdID49IG5vZGUucmFuZ2VbMF0gJiYgeC5yYW5nZVsxXSA8PSBub2RlLnJhbmdlWzFdKV0pO1xuXG4gICAgICAgIGltcG9ydHNUb2tlbnMuZm9yRWFjaCgoW25vZGUsIHRva2Vuc10pID0+IHtcbiAgICAgICAgICB0b2tlbnMuZm9yRWFjaCgodG9rZW4pID0+IHtcbiAgICAgICAgICAgIGNvbnN0IGlkeCA9IHByb2dyYW0udG9rZW5zLmluZGV4T2YodG9rZW4pO1xuICAgICAgICAgICAgY29uc3QgbmV4dFRva2VuID0gcHJvZ3JhbS50b2tlbnNbaWR4ICsgMV07XG5cbiAgICAgICAgICAgIGlmIChuZXh0VG9rZW4gJiYgdG9rZW4udmFsdWUgPT09ICd7JyAmJiBuZXh0VG9rZW4udmFsdWUgPT09ICd9Jykge1xuICAgICAgICAgICAgICBjb25zdCBoYXNPdGhlcklkZW50aWZpZXJzID0gdG9rZW5zLnNvbWUoKHRva2VuKSA9PiB0b2tlbi50eXBlID09PSAnSWRlbnRpZmllcidcbiAgICAgICAgICAgICAgICAgICYmIHRva2VuLnZhbHVlICE9PSAnZnJvbSdcbiAgICAgICAgICAgICAgICAgICYmIHRva2VuLnZhbHVlICE9PSAndHlwZSdcbiAgICAgICAgICAgICAgICAgICYmIHRva2VuLnZhbHVlICE9PSAndHlwZW9mJyxcbiAgICAgICAgICAgICAgKTtcblxuICAgICAgICAgICAgICAvLyBJZiBpdCBoYXMgbm8gb3RoZXIgaWRlbnRpZmllcnMgaXQncyB0aGUgb25seSB0aGluZyBpbiB0aGUgaW1wb3J0LCBzbyB3ZSBjYW4gZWl0aGVyIHJlbW92ZSB0aGUgaW1wb3J0XG4gICAgICAgICAgICAgIC8vIGNvbXBsZXRlbHkgb3IgdHJhbnNmb3JtIGl0IGluIGEgc2lkZS1lZmZlY3RzIG9ubHkgaW1wb3J0XG4gICAgICAgICAgICAgIGlmICghaGFzT3RoZXJJZGVudGlmaWVycykge1xuICAgICAgICAgICAgICAgIGNvbnRleHQucmVwb3J0KHtcbiAgICAgICAgICAgICAgICAgIG5vZGUsXG4gICAgICAgICAgICAgICAgICBtZXNzYWdlOiAnVW5leHBlY3RlZCBlbXB0eSBuYW1lZCBpbXBvcnQgYmxvY2snLFxuICAgICAgICAgICAgICAgICAgc3VnZ2VzdDogW1xuICAgICAgICAgICAgICAgICAgICB7XG4gICAgICAgICAgICAgICAgICAgICAgZGVzYzogJ1JlbW92ZSB1bnVzZWQgaW1wb3J0JyxcbiAgICAgICAgICAgICAgICAgICAgICBmaXgoZml4ZXIpIHtcbiAgICAgICAgICAgICAgICAgICAgICAgIC8vIFJlbW92ZSB0aGUgd2hvbGUgaW1wb3J0XG4gICAgICAgICAgICAgICAgICAgICAgICByZXR1cm4gZml4ZXIucmVtb3ZlKG5vZGUpO1xuICAgICAgICAgICAgICAgICAgICAgIH0sXG4gICAgICAgICAgICAgICAgICAgIH0sXG4gICAgICAgICAgICAgICAgICAgIHtcbiAgICAgICAgICAgICAgICAgICAgICBkZXNjOiAnUmVtb3ZlIGVtcHR5IGltcG9ydCBibG9jaycsXG4gICAgICAgICAgICAgICAgICAgICAgZml4KGZpeGVyKSB7XG4gICAgICAgICAgICAgICAgICAgICAgICAvLyBSZW1vdmUgdGhlIGVtcHR5IGJsb2NrIGFuZCB0aGUgJ2Zyb20nIHRva2VuLCBsZWF2aW5nIHRoZSBpbXBvcnQgb25seSBmb3IgaXRzIHNpZGVcbiAgICAgICAgICAgICAgICAgICAgICAgIC8vIGVmZmVjdHMsIGUuZy4gYGltcG9ydCAnbW9kJ2BcbiAgICAgICAgICAgICAgICAgICAgICAgIGNvbnN0IHNvdXJjZUNvZGUgPSBjb250ZXh0LmdldFNvdXJjZUNvZGUoKTtcbiAgICAgICAgICAgICAgICAgICAgICAgIGNvbnN0IGZyb21Ub2tlbiA9IHByb2dyYW0udG9rZW5zLmZpbmQoKHQpID0+IHQudmFsdWUgPT09ICdmcm9tJyk7XG4gICAgICAgICAgICAgICAgICAgICAgICBjb25zdCBpbXBvcnRUb2tlbiA9IHByb2dyYW0udG9rZW5zLmZpbmQoKHQpID0+IHQudmFsdWUgPT09ICdpbXBvcnQnKTtcbiAgICAgICAgICAgICAgICAgICAgICAgIGNvbnN0IGhhc1NwYWNlQWZ0ZXJGcm9tID0gc291cmNlQ29kZS5pc1NwYWNlQmV0d2Vlbihmcm9tVG9rZW4sIHNvdXJjZUNvZGUuZ2V0VG9rZW5BZnRlcihmcm9tVG9rZW4pKTtcbiAgICAgICAgICAgICAgICAgICAgICAgIGNvbnN0IGhhc1NwYWNlQWZ0ZXJJbXBvcnQgPSBzb3VyY2VDb2RlLmlzU3BhY2VCZXR3ZWVuKGltcG9ydFRva2VuLCBzb3VyY2VDb2RlLmdldFRva2VuQWZ0ZXIoZnJvbVRva2VuKSk7XG5cbiAgICAgICAgICAgICAgICAgICAgICAgIGNvbnN0IFtzdGFydF0gPSBnZXRFbXB0eUJsb2NrUmFuZ2UocHJvZ3JhbS50b2tlbnMsIGlkeCk7XG4gICAgICAgICAgICAgICAgICAgICAgICBjb25zdCBbLCBlbmRdID0gZnJvbVRva2VuLnJhbmdlO1xuICAgICAgICAgICAgICAgICAgICAgICAgY29uc3QgcmFuZ2UgPSBbc3RhcnQsIGhhc1NwYWNlQWZ0ZXJGcm9tID8gZW5kICsgMSA6IGVuZF07XG5cbiAgICAgICAgICAgICAgICAgICAgICAgIHJldHVybiBmaXhlci5yZXBsYWNlVGV4dFJhbmdlKHJhbmdlLCBoYXNTcGFjZUFmdGVySW1wb3J0ID8gJycgOiAnICcpO1xuICAgICAgICAgICAgICAgICAgICAgIH0sXG4gICAgICAgICAgICAgICAgICAgIH0sXG4gICAgICAgICAgICAgICAgICBdLFxuICAgICAgICAgICAgICAgIH0pO1xuICAgICAgICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgICAgICAgIGNvbnRleHQucmVwb3J0KHtcbiAgICAgICAgICAgICAgICAgIG5vZGUsXG4gICAgICAgICAgICAgICAgICBtZXNzYWdlOiAnVW5leHBlY3RlZCBlbXB0eSBuYW1lZCBpbXBvcnQgYmxvY2snLFxuICAgICAgICAgICAgICAgICAgZml4KGZpeGVyKSB7XG4gICAgICAgICAgICAgICAgICAgIHJldHVybiBmaXhlci5yZW1vdmVSYW5nZShnZXRFbXB0eUJsb2NrUmFuZ2UocHJvZ3JhbS50b2tlbnMsIGlkeCkpO1xuICAgICAgICAgICAgICAgICAgfSxcbiAgICAgICAgICAgICAgICB9KTtcbiAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgfVxuICAgICAgICAgIH0pO1xuICAgICAgICB9KTtcbiAgICAgIH0sXG4gICAgfTtcbiAgfSxcbn07XG4iXX0=