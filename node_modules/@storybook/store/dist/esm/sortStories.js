import "core-js/modules/es.array.slice.js";
import "core-js/modules/es.object.freeze.js";

var _templateObject;

import "core-js/modules/es.function.name.js";
import "core-js/modules/es.array.map.js";

function _taggedTemplateLiteral(strings, raw) { if (!raw) { raw = strings.slice(0); } return Object.freeze(Object.defineProperties(strings, { raw: { value: Object.freeze(raw) } })); }

import stable from 'stable';
import dedent from 'ts-dedent';
import { storySort } from './storySort';

var sortStoriesCommon = function sortStoriesCommon(stories, storySortParameter, fileNameOrder) {
  if (storySortParameter) {
    var sortFn;

    if (typeof storySortParameter === 'function') {
      sortFn = storySortParameter;
    } else {
      sortFn = storySort(storySortParameter);
    }

    stable.inplace(stories, sortFn);
  } else {
    stable.inplace(stories, function (s1, s2) {
      return fileNameOrder.indexOf(s1.importPath) - fileNameOrder.indexOf(s2.importPath);
    });
  }

  return stories;
};

export var sortStoriesV7 = function sortStoriesV7(stories, storySortParameter, fileNameOrder) {
  try {
    return sortStoriesCommon(stories, storySortParameter, fileNameOrder);
  } catch (err) {
    throw new Error(dedent(_templateObject || (_templateObject = _taggedTemplateLiteral(["\n    Error sorting stories with sort parameter ", ":\n\n    > ", "\n    \n    Are you using a V6-style sort function in V7 mode?\n\n    More info: https://github.com/storybookjs/storybook/blob/next/MIGRATION.md#v7-style-story-sort\n  "])), storySortParameter, err.message));
  }
};

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

export var sortStoriesV6 = function sortStoriesV6(stories, storySortParameter, fileNameOrder) {
  if (storySortParameter && typeof storySortParameter === 'function') {
    stable.inplace(stories, storySortParameter);
    return stories.map(function (s) {
      return toIndexEntry(s[1]);
    });
  }

  var storiesV7 = stories.map(function (s) {
    return toIndexEntry(s[1]);
  });
  return sortStoriesCommon(storiesV7, storySortParameter, fileNameOrder);
};