"use strict";

var _ = require(".");

function _slicedToArray(arr, i) { return _arrayWithHoles(arr) || _iterableToArrayLimit(arr, i) || _unsupportedIterableToArray(arr, i) || _nonIterableRest(); }

function _nonIterableRest() { throw new TypeError("Invalid attempt to destructure non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(n); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen); }

function _arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

function _iterableToArrayLimit(arr, i) { if (typeof Symbol === "undefined" || !(Symbol.iterator in Object(arr))) return; var _arr = []; var _n = true; var _d = false; var _e = undefined; try { for (var _i = arr[Symbol.iterator](), _s; !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"] != null) _i["return"](); } finally { if (_d) throw _e; } } return _arr; }

function _arrayWithHoles(arr) { if (Array.isArray(arr)) return arr; }

describe('toId', function () {
  var testCases = [// name, kind, story, output
  ['handles simple cases', 'kind', 'story', 'kind--story'], ['handles kind without story', 'kind', undefined, 'kind'], ['handles basic substitution', 'a b$c?d😀e', '1-2:3', 'a-b-c-d😀e--1-2-3'], ['handles runs of non-url chars', 'a?&*b', 'story', 'a-b--story'], ['removes non-url chars from start and end', '?ab-', 'story', 'ab--story'], ['downcases', 'KIND', 'STORY', 'kind--story'], ['non-latin', 'Кнопки', 'нормальный', 'кнопки--нормальный'], ['korean', 'kind', '바보 (babo)', 'kind--바보-babo'], ['all punctuation', 'kind', 'unicorns,’–—―′¿`"<>()!.!!!{}[]%^&$*#&', 'kind--unicorns']];
  testCases.forEach(function (_ref) {
    var _ref2 = _slicedToArray(_ref, 4),
        name = _ref2[0],
        kind = _ref2[1],
        story = _ref2[2],
        output = _ref2[3];

    it(name, function () {
      expect((0, _.toId)(kind, story)).toBe(output);
    });
  });
  it('does not allow kind with *no* url chars', function () {
    expect(function () {
      return (0, _.toId)('?', 'asdf');
    }).toThrow("Invalid kind '?', must include alphanumeric characters");
  });
  it('does not allow empty kind', function () {
    expect(function () {
      return (0, _.toId)('', 'asdf');
    }).toThrow("Invalid kind '', must include alphanumeric characters");
  });
  it('does not allow story with *no* url chars', function () {
    expect(function () {
      return (0, _.toId)('kind', '?');
    }).toThrow("Invalid name '?', must include alphanumeric characters");
  });
  it('allows empty story', function () {
    expect(function () {
      return (0, _.toId)('kind', '');
    }).not.toThrow();
  });
});
describe('storyNameFromExport', function () {
  it('should format CSF exports with sensible defaults', function () {
    var testCases = {
      name: 'Name',
      someName: 'Some Name',
      someNAME: 'Some NAME',
      some_custom_NAME: 'Some Custom NAME',
      someName1234: 'Some Name 1234',
      someName1_2_3_4: 'Some Name 1 2 3 4'
    };
    Object.entries(testCases).forEach(function (_ref3) {
      var _ref4 = _slicedToArray(_ref3, 2),
          key = _ref4[0],
          val = _ref4[1];

      return expect((0, _.storyNameFromExport)(key)).toBe(val);
    });
  });
});
describe('isExportStory', function () {
  it('should exclude __esModule', function () {
    expect((0, _.isExportStory)('__esModule', {})).toBeFalsy();
  });
  it('should include all stories when there are no filters', function () {
    expect((0, _.isExportStory)('a', {})).toBeTruthy();
  });
  it('should filter stories by arrays', function () {
    expect((0, _.isExportStory)('a', {
      includeStories: ['a']
    })).toBeTruthy();
    expect((0, _.isExportStory)('a', {
      includeStories: []
    })).toBeFalsy();
    expect((0, _.isExportStory)('a', {
      includeStories: ['b']
    })).toBeFalsy();
    expect((0, _.isExportStory)('a', {
      excludeStories: ['a']
    })).toBeFalsy();
    expect((0, _.isExportStory)('a', {
      excludeStories: []
    })).toBeTruthy();
    expect((0, _.isExportStory)('a', {
      excludeStories: ['b']
    })).toBeTruthy();
    expect((0, _.isExportStory)('a', {
      includeStories: ['a'],
      excludeStories: ['a']
    })).toBeFalsy();
    expect((0, _.isExportStory)('a', {
      includeStories: [],
      excludeStories: []
    })).toBeFalsy();
    expect((0, _.isExportStory)('a', {
      includeStories: ['a'],
      excludeStories: ['b']
    })).toBeTruthy();
  });
  it('should filter stories by regex', function () {
    expect((0, _.isExportStory)('a', {
      includeStories: /a/
    })).toBeTruthy();
    expect((0, _.isExportStory)('a', {
      includeStories: /.*/
    })).toBeTruthy();
    expect((0, _.isExportStory)('a', {
      includeStories: /b/
    })).toBeFalsy();
    expect((0, _.isExportStory)('a', {
      excludeStories: /a/
    })).toBeFalsy();
    expect((0, _.isExportStory)('a', {
      excludeStories: /.*/
    })).toBeFalsy();
    expect((0, _.isExportStory)('a', {
      excludeStories: /b/
    })).toBeTruthy();
    expect((0, _.isExportStory)('a', {
      includeStories: /a/,
      excludeStories: ['a']
    })).toBeFalsy();
    expect((0, _.isExportStory)('a', {
      includeStories: /.*/,
      excludeStories: /.*/
    })).toBeFalsy();
    expect((0, _.isExportStory)('a', {
      includeStories: /a/,
      excludeStories: /b/
    })).toBeTruthy();
  });
});