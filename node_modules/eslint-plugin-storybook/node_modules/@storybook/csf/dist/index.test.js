"use strict";

var _ = require(".");

function _slicedToArray(arr, i) { return _arrayWithHoles(arr) || _iterableToArrayLimit(arr, i) || _nonIterableRest(); }

function _nonIterableRest() { throw new TypeError("Invalid attempt to destructure non-iterable instance"); }

function _iterableToArrayLimit(arr, i) { if (!(Symbol.iterator in Object(arr) || Object.prototype.toString.call(arr) === "[object Arguments]")) { return; } var _arr = []; var _n = true; var _d = false; var _e = undefined; try { for (var _i = arr[Symbol.iterator](), _s; !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"] != null) _i["return"](); } finally { if (_d) throw _e; } } return _arr; }

function _arrayWithHoles(arr) { if (Array.isArray(arr)) return arr; }

describe('toId', function () {
  [// name, kind, story, output
  ['handles simple cases', 'kind', 'story', 'kind--story'], ['handles basic substitution', 'a b$c?d😀e', '1-2:3', 'a-b-c-d😀e--1-2-3'], ['handles runs of non-url chars', 'a?&*b', 'story', 'a-b--story'], ['removes non-url chars from start and end', '?ab-', 'story', 'ab--story'], ['downcases', 'KIND', 'STORY', 'kind--story'], ['non-latin', 'Кнопки', 'нормальный', 'кнопки--нормальный'], ['korean', 'kind', '바보 (babo)', 'kind--바보-babo'], ['all punctuation', 'kind', 'unicorns,’–—―′¿`"<>()!.!!!{}[]%^&$*#&', 'kind--unicorns']].forEach(function (_ref) {
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
  it('does not allow empty story', function () {
    expect(function () {
      return (0, _.toId)('kind', '');
    }).toThrow("Invalid name '', must include alphanumeric characters");
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