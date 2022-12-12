import "core-js/modules/es.array.reduce.js";
import memoize from 'memoizerific';
import deprecate from 'util-deprecate';
import dedent from 'ts-dedent';
import mapValues from 'lodash/mapValues';
import countBy from 'lodash/countBy';
import global from 'global';
import { sanitize } from '@storybook/csf';
import { combineParameters } from '../index';
import merge from './merge';
const {
  FEATURES
} = global;
const warnLegacyShowRoots = deprecate(() => {}, dedent`
    The 'showRoots' config option is deprecated and will be removed in Storybook 7.0. Use 'sidebar.showRoots' instead.
    Read more about it in the migration guide: https://github.com/storybookjs/storybook/blob/master/MIGRATION.md
  `);
const warnChangedDefaultHierarchySeparators = deprecate(() => {}, dedent`
    The default hierarchy separators changed in Storybook 6.0.
    '|' and '.' will no longer create a hierarchy, but codemods are available.
    Read more about it in the migration guide: https://github.com/storybookjs/storybook/blob/master/MIGRATION.md
  `);
export const denormalizeStoryParameters = ({
  globalParameters,
  kindParameters,
  stories
}) => {
  return mapValues(stories, storyData => Object.assign({}, storyData, {
    parameters: combineParameters(globalParameters, kindParameters[storyData.kind], storyData.parameters)
  }));
};
const STORY_KIND_PATH_SEPARATOR = /\s*\/\s*/;
export const transformStoryIndexToStoriesHash = (index, {
  provider
}) => {
  const countByTitle = countBy(Object.values(index.stories), 'title');
  const input = Object.entries(index.stories).reduce((acc, [id, {
    title,
    name,
    importPath,
    parameters
  }]) => {
    const docsOnly = name === 'Page' && countByTitle[title] === 1;
    acc[id] = {
      id,
      kind: title,
      name,
      parameters: Object.assign({
        fileName: importPath,
        options: {},
        docsOnly
      }, parameters)
    };
    return acc;
  }, {});
  return transformStoriesRawToStoriesHash(input, {
    provider,
    prepared: false
  });
};
export const transformStoriesRawToStoriesHash = (input, {
  provider,
  prepared = true
}) => {
  const values = Object.values(input).filter(Boolean);
  const usesOldHierarchySeparator = values.some(({
    kind
  }) => kind.match(/\.|\|/)); // dot or pipe

  const storiesHashOutOfOrder = values.reduce((acc, item) => {
    var _item$parameters;

    const {
      kind,
      parameters
    } = item;
    const {
      sidebar = {},
      showRoots: deprecatedShowRoots
    } = provider.getConfig();
    const {
      showRoots = deprecatedShowRoots,
      collapsedRoots = [],
      renderLabel
    } = sidebar;

    if (typeof deprecatedShowRoots !== 'undefined') {
      warnLegacyShowRoots();
    }

    const setShowRoots = typeof showRoots !== 'undefined';

    if (usesOldHierarchySeparator && !setShowRoots && FEATURES !== null && FEATURES !== void 0 && FEATURES.warnOnLegacyHierarchySeparator) {
      warnChangedDefaultHierarchySeparators();
    }

    const groups = kind.trim().split(STORY_KIND_PATH_SEPARATOR);
    const root = (!setShowRoots || showRoots) && groups.length > 1 ? [groups.shift()] : [];
    const rootAndGroups = [...root, ...groups].reduce((list, name, index) => {
      const parent = index > 0 && list[index - 1].id;
      const id = sanitize(parent ? `${parent}-${name}` : name);

      if (parent === id) {
        throw new Error(dedent`
              Invalid part '${name}', leading to id === parentId ('${id}'), inside kind '${kind}'

              Did you create a path that uses the separator char accidentally, such as 'Vue <docs/>' where '/' is a separator char? See https://github.com/storybookjs/storybook/issues/6128
            `);
      }

      if (root.length && index === 0) {
        list.push({
          type: 'root',
          id,
          name,
          depth: index,
          children: [],
          isComponent: false,
          isLeaf: false,
          isRoot: true,
          renderLabel,
          startCollapsed: collapsedRoots.includes(id)
        });
      } else {
        list.push({
          type: 'group',
          id,
          name,
          parent,
          depth: index,
          children: [],
          isComponent: false,
          isLeaf: false,
          isRoot: false,
          renderLabel,
          parameters: {
            docsOnly: parameters === null || parameters === void 0 ? void 0 : parameters.docsOnly,
            viewMode: parameters === null || parameters === void 0 ? void 0 : parameters.viewMode
          }
        });
      }

      return list;
    }, []);
    const paths = [...rootAndGroups.map(({
      id
    }) => id), item.id]; // Ok, now let's add everything to the store

    rootAndGroups.forEach((group, index) => {
      const child = paths[index + 1];
      const {
        id
      } = group;
      acc[id] = merge(acc[id] || {}, Object.assign({}, group, child && {
        children: [child]
      }));
    });
    acc[item.id] = Object.assign({
      type: (_item$parameters = item.parameters) !== null && _item$parameters !== void 0 && _item$parameters.docsOnly ? 'docs' : 'story'
    }, item, {
      depth: rootAndGroups.length,
      parent: rootAndGroups[rootAndGroups.length - 1].id,
      isLeaf: true,
      isComponent: false,
      isRoot: false,
      renderLabel,
      prepared
    });
    return acc;
  }, {});

  function addItem(acc, item) {
    if (!acc[item.id]) {
      // If we were already inserted as part of a group, that's great.
      acc[item.id] = item;
      const {
        children
      } = item;

      if (children) {
        const childNodes = children.map(id => storiesHashOutOfOrder[id]);

        if (childNodes.every(childNode => childNode.isLeaf)) {
          acc[item.id].isComponent = true;
          acc[item.id].type = 'component';
        }

        childNodes.forEach(childNode => addItem(acc, childNode));
      }
    }

    return acc;
  }

  return Object.values(storiesHashOutOfOrder).reduce(addItem, {});
};
export function isRoot(item) {
  if (item) {
    return item.isRoot;
  }

  return false;
}
export function isGroup(item) {
  if (item) {
    return !item.isRoot && !item.isLeaf;
  }

  return false;
}
export function isStory(item) {
  if (item) {
    return item.isLeaf;
  }

  return false;
}
export const getComponentLookupList = memoize(1)(hash => {
  return Object.entries(hash).reduce((acc, i) => {
    const value = i[1];

    if (value.isComponent) {
      acc.push([...i[1].children]);
    }

    return acc;
  }, []);
});
export const getStoriesLookupList = memoize(1)(hash => {
  return Object.keys(hash).filter(k => !(hash[k].children || Array.isArray(hash[k])));
});