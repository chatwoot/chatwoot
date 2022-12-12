const _excluded = ["full", "panel", "nav", "shortcuts", "addonPanel", "tabs", "addons", "panelRight", "stories", "selectedKind", "selectedStory", "path"],
      _excluded2 = ["store", "navigate", "state", "provider", "fullAPI"];
import "core-js/modules/es.array.reduce.js";

function _objectWithoutPropertiesLoose(source, excluded) { if (source == null) return {}; var target = {}; var sourceKeys = Object.keys(source); var key, i; for (i = 0; i < sourceKeys.length; i++) { key = sourceKeys[i]; if (excluded.indexOf(key) >= 0) continue; target[key] = source[key]; } return target; }

import { once } from '@storybook/client-logger';
import { NAVIGATE_URL, STORY_ARGS_UPDATED, SET_CURRENT_STORY, GLOBALS_UPDATED, UPDATE_QUERY_PARAMS } from '@storybook/core-events';
import { queryFromLocation, buildArgsParam } from '@storybook/router';
import { toId, sanitize } from '@storybook/csf';
import deepEqual from 'fast-deep-equal';
import global from 'global';
import dedent from 'ts-dedent';
import { isStory } from '../lib/stories';
const {
  window: globalWindow
} = global;

const parseBoolean = value => {
  if (value === 'true' || value === '1') return true;
  if (value === 'false' || value === '0') return false;
  return undefined;
}; // Initialize the state based on the URL.
// NOTE:
//   Although we don't change the URL when you change the state, we do support setting initial state
//   via the following URL parameters:
//     - full: 0/1 -- show fullscreen
//     - panel: bottom/right/0 -- set addons panel position (or hide)
//     - nav: 0/1 -- show or hide the story list
//
//   We also support legacy URLs from storybook <5


let prevParams;

const initialUrlSupport = ({
  state: {
    location,
    path,
    viewMode,
    storyId: storyIdFromUrl
  },
  singleStory
}) => {
  const _queryFromLocation = queryFromLocation(location),
        {
    full,
    panel,
    nav,
    shortcuts,
    addonPanel,
    tabs,
    addons,
    // deprecated
    panelRight,
    // deprecated
    stories,
    // deprecated
    selectedKind,
    // deprecated
    selectedStory // the rest gets passed to the iframe

  } = _queryFromLocation,
        otherParams = _objectWithoutPropertiesLoose(_queryFromLocation, _excluded);

  const layout = {
    isFullscreen: parseBoolean(full),
    showNav: !singleStory && parseBoolean(nav),
    showPanel: parseBoolean(panel),
    panelPosition: ['right', 'bottom'].includes(panel) ? panel : undefined,
    showTabs: parseBoolean(tabs)
  };
  const ui = {
    enableShortcuts: parseBoolean(shortcuts)
  };
  const selectedPanel = addonPanel || undefined; // @deprecated Superceded by `panel=false`, to be removed in 7.0

  if (addons === '0') {
    once.warn(dedent`
      The 'addons' query param is deprecated and will be removed in Storybook 7.0. Use 'panel=false' instead.

      More info: https://github.com/storybookjs/storybook/blob/next/MIGRATION.md#deprecated-layout-url-params
    `);
    layout.showPanel = false;
  } // @deprecated Superceded by `panel=right`, to be removed in 7.0


  if (panelRight === '1') {
    once.warn(dedent`
      The 'panelRight' query param is deprecated and will be removed in Storybook 7.0. Use 'panel=right' instead.

      More info: https://github.com/storybookjs/storybook/blob/next/MIGRATION.md#deprecated-layout-url-params
    `);
    layout.panelPosition = 'right';
  } // @deprecated Superceded by `nav=false`, to be removed in 7.0


  if (stories === '0') {
    once.warn(dedent`
      The 'stories' query param is deprecated and will be removed in Storybook 7.0. Use 'nav=false' instead.

      More info: https://github.com/storybookjs/storybook/blob/next/MIGRATION.md#deprecated-layout-url-params
    `);
    layout.showNav = false;
  } // @deprecated To be removed in 7.0
  // If the user hasn't set the storyId on the URL, we support legacy URLs (selectedKind/selectedStory)
  // NOTE: this "storyId" can just be a prefix of a storyId, really it is a storyIdSpecifier.


  let storyId = storyIdFromUrl;

  if (!storyId && selectedKind) {
    once.warn(dedent`
      The 'selectedKind' and 'selectedStory' query params are deprecated and will be removed in Storybook 7.0. Use 'path' instead.

      More info: https://github.com/storybookjs/storybook/blob/next/MIGRATION.md#deprecated-layout-url-params
    `);
    storyId = selectedStory ? toId(selectedKind, selectedStory) : sanitize(selectedKind);
  } // Avoid returning a new object each time if no params actually changed.


  const customQueryParams = deepEqual(prevParams, otherParams) ? prevParams : otherParams;
  prevParams = customQueryParams;
  return {
    viewMode,
    layout,
    ui,
    selectedPanel,
    location,
    path,
    customQueryParams,
    storyId
  };
};

export const init = _ref => {
  let {
    store,
    navigate,
    state,
    provider,
    fullAPI
  } = _ref,
      rest = _objectWithoutPropertiesLoose(_ref, _excluded2);

  const navigateTo = (path, queryParams = {}, options = {}) => {
    const params = Object.entries(queryParams).filter(([, v]) => v).sort(([a], [b]) => a < b ? -1 : 1).map(([k, v]) => `${k}=${v}`);
    const to = [path, ...params].join('&');
    return navigate(to, options);
  };

  const api = {
    getQueryParam(key) {
      const {
        customQueryParams
      } = store.getState();
      return customQueryParams ? customQueryParams[key] : undefined;
    },

    getUrlState() {
      const {
        path,
        customQueryParams,
        storyId,
        url,
        viewMode
      } = store.getState();
      return {
        path,
        queryParams: customQueryParams,
        storyId,
        url,
        viewMode
      };
    },

    setQueryParams(input) {
      const {
        customQueryParams
      } = store.getState();
      const queryParams = {};
      const update = Object.assign({}, customQueryParams, Object.entries(input).reduce((acc, [key, value]) => {
        if (value !== null) {
          acc[key] = value;
        }

        return acc;
      }, queryParams));

      if (!deepEqual(customQueryParams, update)) {
        store.setState({
          customQueryParams: update
        });
        fullAPI.emit(UPDATE_QUERY_PARAMS, update);
      }
    },

    navigateUrl(url, options) {
      navigate(url, Object.assign({}, options, {
        plain: true
      }));
    }

  };

  const initModule = () => {
    // Sets `args` parameter in URL, omitting any args that have their initial value or cannot be unserialized safely.
    const updateArgsParam = () => {
      const {
        path,
        queryParams,
        viewMode
      } = fullAPI.getUrlState();
      if (viewMode !== 'story') return;
      const currentStory = fullAPI.getCurrentStoryData();
      if (!isStory(currentStory)) return;
      const {
        args,
        initialArgs
      } = currentStory;
      const argsString = buildArgsParam(initialArgs, args);
      navigateTo(path, Object.assign({}, queryParams, {
        args: argsString
      }), {
        replace: true
      });
      api.setQueryParams({
        args: argsString
      });
    };

    fullAPI.on(SET_CURRENT_STORY, () => updateArgsParam());
    let handleOrId;
    fullAPI.on(STORY_ARGS_UPDATED, () => {
      if ('requestIdleCallback' in globalWindow) {
        if (handleOrId) globalWindow.cancelIdleCallback(handleOrId);
        handleOrId = globalWindow.requestIdleCallback(updateArgsParam, {
          timeout: 1000
        });
      } else {
        if (handleOrId) clearTimeout(handleOrId);
        setTimeout(updateArgsParam, 100);
      }
    });
    fullAPI.on(GLOBALS_UPDATED, ({
      globals,
      initialGlobals
    }) => {
      const {
        path,
        queryParams
      } = fullAPI.getUrlState();
      const globalsString = buildArgsParam(initialGlobals, globals);
      navigateTo(path, Object.assign({}, queryParams, {
        globals: globalsString
      }), {
        replace: true
      });
      api.setQueryParams({
        globals: globalsString
      });
    });
    fullAPI.on(NAVIGATE_URL, (url, options) => {
      fullAPI.navigateUrl(url, options);
    });

    if (fullAPI.showReleaseNotesOnLaunch()) {
      navigate('/settings/release-notes');
    }
  };

  return {
    api,
    state: initialUrlSupport(Object.assign({
      store,
      navigate,
      state,
      provider,
      fullAPI
    }, rest)),
    init: initModule
  };
};