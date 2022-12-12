const _excluded = ["id"],
      _excluded2 = ["kind", "story", "storyId"];

function _objectWithoutPropertiesLoose(source, excluded) { if (source == null) return {}; var target = {}; var sourceKeys = Object.keys(source); var key, i; for (i = 0; i < sourceKeys.length; i++) { key = sourceKeys[i]; if (excluded.indexOf(key) >= 0) continue; target[key] = source[key]; } return target; }

import "core-js/modules/es.array.reduce.js";
import global from 'global';
import { toId, sanitize } from '@storybook/csf';
import { PRELOAD_STORIES, STORY_PREPARED, UPDATE_STORY_ARGS, RESET_STORY_ARGS, STORY_ARGS_UPDATED, STORY_CHANGED, SELECT_STORY, SET_STORIES, STORY_SPECIFIED, STORY_INDEX_INVALIDATED, CONFIG_ERROR } from '@storybook/core-events';
import deprecate from 'util-deprecate';
import { logger } from '@storybook/client-logger';
import { getEventMetadata } from '../lib/events';
import { denormalizeStoryParameters, transformStoriesRawToStoriesHash, isStory, isRoot, transformStoryIndexToStoriesHash, getComponentLookupList, getStoriesLookupList } from '../lib/stories';
const {
  DOCS_MODE,
  FEATURES,
  fetch
} = global;
const STORY_INDEX_PATH = './stories.json';
const deprecatedOptionsParameterWarnings = ['enableShortcuts', 'theme', 'showRoots'].reduce((acc, option) => {
  acc[option] = deprecate(() => {}, `parameters.options.${option} is deprecated and will be removed in Storybook 7.0.
To change this setting, use \`addons.setConfig\`. See https://github.com/storybookjs/storybook/blob/next/MIGRATION.md#deprecated-immutable-options-parameters
  `);
  return acc;
}, {});

function checkDeprecatedOptionParameters(options) {
  if (!options) {
    return;
  }

  Object.keys(options).forEach(option => {
    if (deprecatedOptionsParameterWarnings[option]) {
      deprecatedOptionsParameterWarnings[option]();
    }
  });
}

export const init = ({
  fullAPI,
  store,
  navigate,
  provider,
  storyId: initialStoryId,
  viewMode: initialViewMode
}) => {
  const api = {
    storyId: toId,
    getData: (storyId, refId) => {
      const result = api.resolveStory(storyId, refId);
      return isRoot(result) ? undefined : result;
    },
    isPrepared: (storyId, refId) => {
      const data = api.getData(storyId, refId);

      if (data.isLeaf) {
        return data.prepared;
      } // Groups are always prepared :shrug:


      return true;
    },
    resolveStory: (storyId, refId) => {
      const {
        refs,
        storiesHash
      } = store.getState();

      if (refId) {
        return refs[refId].stories ? refs[refId].stories[storyId] : undefined;
      }

      return storiesHash ? storiesHash[storyId] : undefined;
    },
    getCurrentStoryData: () => {
      const {
        storyId,
        refId
      } = store.getState();
      return api.getData(storyId, refId);
    },
    getParameters: (storyIdOrCombo, parameterName) => {
      const {
        storyId,
        refId
      } = typeof storyIdOrCombo === 'string' ? {
        storyId: storyIdOrCombo,
        refId: undefined
      } : storyIdOrCombo;
      const data = api.getData(storyId, refId);

      if (isStory(data)) {
        const {
          parameters
        } = data;

        if (parameters) {
          return parameterName ? parameters[parameterName] : parameters;
        }

        return {};
      }

      return null;
    },
    getCurrentParameter: parameterName => {
      const {
        storyId,
        refId
      } = store.getState();
      const parameters = api.getParameters({
        storyId,
        refId
      }, parameterName); // FIXME Returning falsey parameters breaks a bunch of toolbars code,
      // so this strange logic needs to be here until various client code is updated.

      return parameters || undefined;
    },
    jumpToComponent: direction => {
      const {
        storiesHash,
        storyId,
        refs,
        refId
      } = store.getState();
      const story = api.getData(storyId, refId); // cannot navigate when there's no current selection

      if (!story) {
        return;
      }

      const hash = refId ? refs[refId].stories || {} : storiesHash;
      const result = api.findSiblingStoryId(storyId, hash, direction, true);

      if (result) {
        api.selectStory(result, undefined, {
          ref: refId
        });
      }
    },
    jumpToStory: direction => {
      const {
        storiesHash,
        storyId,
        refs,
        refId
      } = store.getState();
      const story = api.getData(storyId, refId);

      if (DOCS_MODE) {
        api.jumpToComponent(direction);
        return;
      } // cannot navigate when there's no current selection


      if (!story) {
        return;
      }

      const hash = story.refId ? refs[story.refId].stories : storiesHash;
      const result = api.findSiblingStoryId(storyId, hash, direction, false);

      if (result) {
        api.selectStory(result, undefined, {
          ref: refId
        });
      }
    },
    setStories: async (input, error) => {
      // Now create storiesHash by reordering the above by group
      const hash = transformStoriesRawToStoriesHash(input, {
        provider
      });
      await store.setState({
        storiesHash: hash,
        storiesConfigured: true,
        storiesFailed: error
      });
    },
    selectFirstStory: () => {
      const {
        storiesHash
      } = store.getState();
      const firstStory = Object.keys(storiesHash).find(k => !(storiesHash[k].children || Array.isArray(storiesHash[k])));

      if (firstStory) {
        api.selectStory(firstStory);
        return;
      }

      navigate('/');
    },
    selectStory: (kindOrId = undefined, story = undefined, options = {}) => {
      const {
        ref,
        viewMode: viewModeFromArgs
      } = options;
      const {
        viewMode: viewModeFromState = 'story',
        storyId,
        storiesHash,
        refs
      } = store.getState();
      const hash = ref ? refs[ref].stories : storiesHash;
      const kindSlug = storyId === null || storyId === void 0 ? void 0 : storyId.split('--', 2)[0];

      if (!story) {
        const s = kindOrId ? hash[kindOrId] || hash[sanitize(kindOrId)] : hash[kindSlug]; // eslint-disable-next-line no-nested-ternary

        const id = s ? s.children ? s.children[0] : s.id : kindOrId;
        let viewMode = s && !isRoot(s) && (viewModeFromArgs || s.parameters.viewMode) ? s.parameters.viewMode : viewModeFromState; // Some viewModes are not story-specific, and we should reset viewMode
        //  to 'story' if one of those is active when navigating to another story

        if (['settings', 'about', 'release'].includes(viewMode)) {
          viewMode = 'story';
        }

        const p = s && s.refId ? `/${viewMode}/${s.refId}_${id}` : `/${viewMode}/${id}`;
        navigate(p);
      } else if (!kindOrId) {
        // This is a slugified version of the kind, but that's OK, our toId function is idempotent
        const id = toId(kindSlug, story);
        api.selectStory(id, undefined, options);
      } else {
        const id = ref ? `${ref}_${toId(kindOrId, story)}` : toId(kindOrId, story);

        if (hash[id]) {
          api.selectStory(id, undefined, options);
        } else {
          // Support legacy API with component permalinks, where kind is `x/y` but permalink is 'z'
          const k = hash[sanitize(kindOrId)];

          if (k && k.children) {
            const foundId = k.children.find(childId => hash[childId].name === story);

            if (foundId) {
              api.selectStory(foundId, undefined, options);
            }
          }
        }
      }
    },

    findLeafStoryId(storiesHash, storyId) {
      if (storiesHash[storyId].isLeaf) {
        return storyId;
      }

      const childStoryId = storiesHash[storyId].children[0];
      return api.findLeafStoryId(storiesHash, childStoryId);
    },

    findSiblingStoryId(storyId, hash, direction, toSiblingGroup) {
      if (toSiblingGroup) {
        const lookupList = getComponentLookupList(hash);
        const index = lookupList.findIndex(i => i.includes(storyId)); // cannot navigate beyond fist or last

        if (index === lookupList.length - 1 && direction > 0) {
          return;
        }

        if (index === 0 && direction < 0) {
          return;
        }

        if (lookupList[index + direction]) {
          // eslint-disable-next-line consistent-return
          return lookupList[index + direction][0];
        }

        return;
      }

      const lookupList = getStoriesLookupList(hash);
      const index = lookupList.indexOf(storyId); // cannot navigate beyond fist or last

      if (index === lookupList.length - 1 && direction > 0) {
        return;
      }

      if (index === 0 && direction < 0) {
        return;
      } // eslint-disable-next-line consistent-return


      return lookupList[index + direction];
    },

    updateStoryArgs: (story, updatedArgs) => {
      const {
        id: storyId,
        refId
      } = story;
      fullAPI.emit(UPDATE_STORY_ARGS, {
        storyId,
        updatedArgs,
        options: {
          target: refId ? `storybook-ref-${refId}` : 'storybook-preview-iframe'
        }
      });
    },
    resetStoryArgs: (story, argNames) => {
      const {
        id: storyId,
        refId
      } = story;
      fullAPI.emit(RESET_STORY_ARGS, {
        storyId,
        argNames,
        options: {
          target: refId ? `storybook-ref-${refId}` : 'storybook-preview-iframe'
        }
      });
    },
    fetchStoryList: async () => {
      try {
        const result = await fetch(STORY_INDEX_PATH);
        if (result.status !== 200) throw new Error(await result.text());
        const storyIndex = await result.json(); // We can only do this if the stories.json is a proper storyIndex

        if (storyIndex.v !== 3) {
          logger.warn(`Skipping story index with version v${storyIndex.v}, awaiting SET_STORIES.`);
          return;
        }

        await fullAPI.setStoryList(storyIndex);
      } catch (err) {
        store.setState({
          storiesConfigured: true,
          storiesFailed: err
        });
      }
    },
    setStoryList: async storyIndex => {
      const hash = transformStoryIndexToStoriesHash(storyIndex, {
        provider
      });
      await store.setState({
        storiesHash: hash,
        storiesConfigured: true,
        storiesFailed: null
      });
    },
    updateStory: async (storyId, update, ref) => {
      if (!ref) {
        const {
          storiesHash
        } = store.getState();
        storiesHash[storyId] = Object.assign({}, storiesHash[storyId], update);
        await store.setState({
          storiesHash
        });
      } else {
        const {
          id: refId,
          stories
        } = ref;
        stories[storyId] = Object.assign({}, stories[storyId], update);
        await fullAPI.updateRef(refId, {
          stories
        });
      }
    }
  };

  const initModule = async () => {
    // On initial load, the local iframe will select the first story (or other "selection specifier")
    // and emit STORY_SPECIFIED with the id. We need to ensure we respond to this change.
    fullAPI.on(STORY_SPECIFIED, function handler({
      storyId,
      viewMode
    }) {
      const {
        sourceType
      } = getEventMetadata(this, fullAPI);
      if (fullAPI.isSettingsScreenActive()) return;

      if (sourceType === 'local') {
        // Special case -- if we are already at the story being specified (i.e. the user started at a given story),
        // we don't need to change URL. See https://github.com/storybookjs/storybook/issues/11677
        const state = store.getState();

        if (state.storyId !== storyId || state.viewMode !== viewMode) {
          navigate(`/${viewMode}/${storyId}`);
        }
      }
    });
    fullAPI.on(STORY_CHANGED, function handler() {
      const {
        sourceType
      } = getEventMetadata(this, fullAPI);

      if (sourceType === 'local') {
        const options = fullAPI.getCurrentParameter('options');

        if (options) {
          checkDeprecatedOptionParameters(options);
          fullAPI.setOptions(options);
        }
      }
    });
    fullAPI.on(STORY_PREPARED, function handler(_ref) {
      let {
        id
      } = _ref,
          update = _objectWithoutPropertiesLoose(_ref, _excluded);

      const {
        ref,
        sourceType
      } = getEventMetadata(this, fullAPI);
      fullAPI.updateStory(id, Object.assign({}, update, {
        prepared: true
      }), ref);

      if (!ref) {
        if (!store.getState().hasCalledSetOptions) {
          const {
            options
          } = update.parameters;
          checkDeprecatedOptionParameters(options);
          fullAPI.setOptions(options);
          store.setState({
            hasCalledSetOptions: true
          });
        }
      } else {
        fullAPI.updateRef(ref.id, {
          ready: true
        });
      }

      if (sourceType === 'local') {
        const {
          storyId,
          storiesHash
        } = store.getState(); // create a list of related stories to be preloaded

        const toBePreloaded = Array.from(new Set([api.findSiblingStoryId(storyId, storiesHash, 1, true), api.findSiblingStoryId(storyId, storiesHash, -1, true)])).filter(Boolean);
        fullAPI.emit(PRELOAD_STORIES, toBePreloaded);
      }
    });
    fullAPI.on(SET_STORIES, function handler(data) {
      const {
        ref
      } = getEventMetadata(this, fullAPI);
      const stories = data.v ? denormalizeStoryParameters(data) : data.stories;

      if (!ref) {
        if (!data.v) {
          throw new Error('Unexpected legacy SET_STORIES event from local source');
        }

        fullAPI.setStories(stories);
        const options = fullAPI.getCurrentParameter('options');
        checkDeprecatedOptionParameters(options);
        fullAPI.setOptions(options);
      } else {
        fullAPI.setRef(ref.id, Object.assign({}, ref, data, {
          stories
        }), true);
      }
    });
    fullAPI.on(SELECT_STORY, function handler(_ref2) {
      let {
        kind,
        story,
        storyId
      } = _ref2,
          rest = _objectWithoutPropertiesLoose(_ref2, _excluded2);

      const {
        ref
      } = getEventMetadata(this, fullAPI);

      if (!ref) {
        fullAPI.selectStory(storyId || kind, story, rest);
      } else {
        fullAPI.selectStory(storyId || kind, story, Object.assign({}, rest, {
          ref: ref.id
        }));
      }
    });
    fullAPI.on(STORY_ARGS_UPDATED, function handleStoryArgsUpdated({
      storyId,
      args
    }) {
      const {
        ref
      } = getEventMetadata(this, fullAPI);
      fullAPI.updateStory(storyId, {
        args
      }, ref);
    });
    fullAPI.on(CONFIG_ERROR, function handleConfigError(err) {
      store.setState({
        storiesConfigured: true,
        storiesFailed: err
      });
    });

    if (FEATURES !== null && FEATURES !== void 0 && FEATURES.storyStoreV7) {
      var _provider$serverChann;

      (_provider$serverChann = provider.serverChannel) === null || _provider$serverChann === void 0 ? void 0 : _provider$serverChann.on(STORY_INDEX_INVALIDATED, () => fullAPI.fetchStoryList());
      await fullAPI.fetchStoryList();
    }
  };

  return {
    api,
    state: {
      storiesHash: {},
      storyId: initialStoryId,
      viewMode: initialViewMode,
      storiesConfigured: false,
      hasCalledSetOptions: false
    },
    init: initModule
  };
};