"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports["default"] = void 0;

var _AsYouTypeFormatterPatternParser = _interopRequireDefault(require("./AsYouTypeFormatter.PatternParser.js"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { "default": obj }; }

function _createForOfIteratorHelperLoose(o, allowArrayLike) { var it = typeof Symbol !== "undefined" && o[Symbol.iterator] || o["@@iterator"]; if (it) return (it = it.call(o)).next.bind(it); if (Array.isArray(o) || (it = _unsupportedIterableToArray(o)) || allowArrayLike && o && typeof o.length === "number") { if (it) o = it; var i = 0; return function () { if (i >= o.length) return { done: true }; return { done: false, value: o[i++] }; }; } throw new TypeError("Invalid attempt to iterate non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen); }

function _arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } }

function _createClass(Constructor, protoProps, staticProps) { if (protoProps) _defineProperties(Constructor.prototype, protoProps); if (staticProps) _defineProperties(Constructor, staticProps); Object.defineProperty(Constructor, "prototype", { writable: false }); return Constructor; }

var PatternMatcher = /*#__PURE__*/function () {
  function PatternMatcher(pattern) {
    _classCallCheck(this, PatternMatcher);

    this.matchTree = new _AsYouTypeFormatterPatternParser["default"]().parse(pattern);
  }

  _createClass(PatternMatcher, [{
    key: "match",
    value: function match(string) {
      var _ref = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : {},
          allowOverflow = _ref.allowOverflow;

      if (!string) {
        throw new Error('String is required');
      }

      var result = _match(string.split(''), this.matchTree, true);

      if (result && result.match) {
        delete result.matchedChars;
      }

      if (result && result.overflow) {
        if (!allowOverflow) {
          return;
        }
      }

      return result;
    }
  }]);

  return PatternMatcher;
}();
/**
 * Matches `characters` against a pattern compiled into a `tree`.
 * @param  {string[]} characters
 * @param  {Tree} tree — A pattern compiled into a `tree`. See the `*.d.ts` file for the description of the `tree` structure.
 * @param  {boolean} last — Whether it's the last (rightmost) subtree on its level of the match tree.
 * @return {object} See the `*.d.ts` file for the description of the result object.
 */


exports["default"] = PatternMatcher;

function _match(characters, tree, last) {
  // If `tree` is a string, then `tree` is a single character.
  // That's because when a pattern is parsed, multi-character-string parts
  // of a pattern are compiled into arrays of single characters.
  // I still wrote this piece of code for a "general" hypothetical case
  // when `tree` could be a string of several characters, even though
  // such case is not possible with the current implementation.
  if (typeof tree === 'string') {
    var characterString = characters.join('');

    if (tree.indexOf(characterString) === 0) {
      // `tree` is always a single character.
      // If `tree.indexOf(characterString) === 0`
      // then `characters.length === tree.length`.

      /* istanbul ignore else */
      if (characters.length === tree.length) {
        return {
          match: true,
          matchedChars: characters
        };
      } // `tree` is always a single character.
      // If `tree.indexOf(characterString) === 0`
      // then `characters.length === tree.length`.

      /* istanbul ignore next */


      return {
        partialMatch: true // matchedChars: characters

      };
    }

    if (characterString.indexOf(tree) === 0) {
      if (last) {
        // The `else` path is not possible because `tree` is always a single character.
        // The `else` case for `characters.length > tree.length` would be
        // `characters.length <= tree.length` which means `characters.length <= 1`.
        // `characters` array can't be empty, so that means `characters === [tree]`,
        // which would also mean `tree.indexOf(characterString) === 0` and that'd mean
        // that the `if (tree.indexOf(characterString) === 0)` condition before this
        // `if` condition would be entered, and returned from there, not reaching this code.

        /* istanbul ignore else */
        if (characters.length > tree.length) {
          return {
            overflow: true
          };
        }
      }

      return {
        match: true,
        matchedChars: characters.slice(0, tree.length)
      };
    }

    return;
  }

  if (Array.isArray(tree)) {
    var restCharacters = characters.slice();
    var i = 0;

    while (i < tree.length) {
      var subtree = tree[i];

      var result = _match(restCharacters, subtree, last && i === tree.length - 1);

      if (!result) {
        return;
      } else if (result.overflow) {
        return result;
      } else if (result.match) {
        // Continue with the next subtree with the rest of the characters.
        restCharacters = restCharacters.slice(result.matchedChars.length);

        if (restCharacters.length === 0) {
          if (i === tree.length - 1) {
            return {
              match: true,
              matchedChars: characters
            };
          } else {
            return {
              partialMatch: true // matchedChars: characters

            };
          }
        }
      } else {
        /* istanbul ignore else */
        if (result.partialMatch) {
          return {
            partialMatch: true // matchedChars: characters

          };
        } else {
          throw new Error("Unsupported match result:\n".concat(JSON.stringify(result, null, 2)));
        }
      }

      i++;
    } // If `last` then overflow has already been checked
    // by the last element of the `tree` array.

    /* istanbul ignore if */


    if (last) {
      return {
        overflow: true
      };
    }

    return {
      match: true,
      matchedChars: characters.slice(0, characters.length - restCharacters.length)
    };
  }

  switch (tree.op) {
    case '|':
      var partialMatch;

      for (var _iterator = _createForOfIteratorHelperLoose(tree.args), _step; !(_step = _iterator()).done;) {
        var branch = _step.value;

        var _result = _match(characters, branch, last);

        if (_result) {
          if (_result.overflow) {
            return _result;
          } else if (_result.match) {
            return {
              match: true,
              matchedChars: _result.matchedChars
            };
          } else {
            /* istanbul ignore else */
            if (_result.partialMatch) {
              partialMatch = true;
            } else {
              throw new Error("Unsupported match result:\n".concat(JSON.stringify(_result, null, 2)));
            }
          }
        }
      }

      if (partialMatch) {
        return {
          partialMatch: true // matchedChars: ...

        };
      } // Not even a partial match.


      return;

    case '[]':
      for (var _iterator2 = _createForOfIteratorHelperLoose(tree.args), _step2; !(_step2 = _iterator2()).done;) {
        var _char = _step2.value;

        if (characters[0] === _char) {
          if (characters.length === 1) {
            return {
              match: true,
              matchedChars: characters
            };
          }

          if (last) {
            return {
              overflow: true
            };
          }

          return {
            match: true,
            matchedChars: [_char]
          };
        }
      } // No character matches.


      return;

    /* istanbul ignore next */

    default:
      throw new Error("Unsupported instruction tree: ".concat(tree));
  }
}
//# sourceMappingURL=AsYouTypeFormatter.PatternMatcher.js.map