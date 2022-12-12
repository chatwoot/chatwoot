import stable from 'stable';
import dedent from 'ts-dedent';
import { storySort } from './storySort';

const sortStoriesCommon = (stories, storySortParameter, fileNameOrder) => {
  if (storySortParameter) {
    let sortFn;

    if (typeof storySortParameter === 'function') {
      sortFn = storySortParameter;
    } else {
      sortFn = storySort(storySortParameter);
    }

    stable.inplace(stories, sortFn);
  } else {
    stable.inplace(stories, (s1, s2) => fileNameOrder.indexOf(s1.importPath) - fileNameOrder.indexOf(s2.importPath));
  }

  return stories;
};

export const sortStoriesV7 = (stories, storySortParameter, fileNameOrder) => {
  try {
    return sortStoriesCommon(stories, storySortParameter, fileNameOrder);
  } catch (err) {
    throw new Error(dedent`
    Error sorting stories with sort parameter ${storySortParameter}:

    > ${err.message}
    
    Are you using a V6-style sort function in V7 mode?

    More info: https://github.com/storybookjs/storybook/blob/next/MIGRATION.md#v7-style-story-sort
  `);
  }
};

const toIndexEntry = story => {
  const {
    id,
    title,
    name,
    parameters
  } = story;
  return {
    id,
    title,
    name,
    importPath: parameters.fileName
  };
};

export const sortStoriesV6 = (stories, storySortParameter, fileNameOrder) => {
  if (storySortParameter && typeof storySortParameter === 'function') {
    stable.inplace(stories, storySortParameter);
    return stories.map(s => toIndexEntry(s[1]));
  }

  const storiesV7 = stories.map(s => toIndexEntry(s[1]));
  return sortStoriesCommon(storiesV7, storySortParameter, fileNameOrder);
};