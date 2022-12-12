"use strict";

require("core-js/modules/es.array.slice.js");

require("core-js/modules/es.object.freeze.js");

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.sortStoriesV7 = exports.sortStoriesV6 = void 0;

require("core-js/modules/es.function.name.js");

require("core-js/modules/es.array.map.js");

var _stable = _interopRequireDefault(require("stable"));

var _tsDedent = _interopRequireDefault(require("ts-dedent"));

var _storySort = require("./storySort");

var _templateObject;

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _taggedTemplateLiteral(strings, raw) { if (!raw) { raw = strings.slice(0); } return Object.freeze(Object.defineProperties(strings, { raw: { value: Object.freeze(raw) } })); }

var sortStoriesCommon = function sortStoriesCommon(stories, storySortParameter, fileNameOrder) {
  if (storySortParameter) {
    var sortFn;

    if (typeof storySortParameter === 'function') {
      sortFn = storySortParameter;
    } else {
      sortFn = (0, _storySort.storySort)(storySortParameter);
    }

    _stable.default.inplace(stories, sortFn);
  } else {
    _stable.default.inplace(stories, function (s1, s2) {
      return fileNameOrder.indexOf(s1.importPath) - fileNameOrder.indexOf(s2.importPath);
    });
  }

  return stories;
};

var sortStoriesV7 = function sortStoriesV7(stories, storySortParameter, fileNameOrder) {
  try {
    return sortStoriesCommon(stories, storySortParameter, fileNameOrder);
  } catch (err) {
    throw new Error((0, _tsDedent.default)(_templateObject || (_templateObject = _taggedTemplateLiteral(["\n    Error sorting stories with sort parameter ", ":\n\n    > ", "\n    \n    Are you using a V6-style sort function in V7 mode?\n\n    More info: https://github.com/storybookjs/storybook/blob/next/MIGRATION.md#v7-style-story-sort\n  "])), storySortParameter, err.message));
  }
};

exports.sortStoriesV7 = sortStoriesV7;

var toIndexEntry = function toIndexEntry(story) {
  var id = story.id,
      title = story.title,
      name = story.name,
      parameters = story.parameters;
  return {
    id: id,
    title: title,
    name: name,
    importPath: parameters.fileName
  };
};

var sortStoriesV6 = function sortStoriesV6(stories, storySortParameter, fileNameOrder) {
  if (storySortParameter && typeof storySortParameter === 'function') {
    _stable.default.inplace(stories, storySortParameter);

    return stories.map(function (s) {
      return toIndexEntry(s[1]);
    });
  }

  var storiesV7 = stories.map(function (s) {
    return toIndexEntry(s[1]);
  });
  return sortStoriesCommon(storiesV7, storySortParameter, fileNameOrder);
};

exports.sortStoriesV6 = sortStoriesV6;