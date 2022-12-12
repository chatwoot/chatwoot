import "core-js/modules/es.array.reduce.js";
import React, { Component, Fragment, useCallback, useContext, useEffect, useMemo, useRef } from 'react';
import mergeWith from 'lodash/mergeWith';
import { STORY_CHANGED, SHARED_STATE_CHANGED, SHARED_STATE_SET, SET_STORIES } from '@storybook/core-events';
import { createContext } from './context';
import Store from './store';
import getInitialState from './initial-state';
import { isGroup, isRoot, isStory } from './lib/stories';
import * as provider from './modules/provider';
import * as addons from './modules/addons';
import * as channel from './modules/channel';
import * as notifications from './modules/notifications';
import * as settings from './modules/settings';
import * as releaseNotes from './modules/release-notes';
import * as stories from './modules/stories';
import * as refs from './modules/refs';
import * as layout from './modules/layout';
import * as shortcuts from './modules/shortcuts';
import * as url from './modules/url';
import * as version from './modules/versions';
import * as globals from './modules/globals';
const {
  ActiveTabs
} = layout;
export { default as merge } from './lib/merge';
export { ActiveTabs };
const ManagerContext = createContext({
  api: undefined,
  state: getInitialState({})
});
// This is duplicated from @storybook/client-api for the reasons mentioned in lib-addons/types.js
export const combineParameters = (...parameterSets) => mergeWith({}, ...parameterSets, (objValue, srcValue) => {
  // Treat arrays as scalars:
  if (Array.isArray(srcValue)) return srcValue;
  return undefined;
});

class ManagerProvider extends Component {
  constructor(props) {
    super(props);
    this.api = {};
    this.modules = void 0;

    this.initModules = () => {
      // Now every module has had a chance to set its API, call init on each module which gives it
      // a chance to do things that call other modules' APIs.
      this.modules.forEach(({
        init
      }) => {
        if (init) {
          init();
        }
      });
    };

    const {
      location,
      path,
      refId,
      viewMode = props.docsMode ? 'docs' : 'story',
      singleStory,
      storyId,
      docsMode,
      navigate
    } = props;
    const store = new Store({
      getState: () => this.state,
      setState: (stateChange, callback) => this.setState(stateChange, callback)
    });
    const routeData = {
      location,
      path,
      viewMode,
      singleStory,
      storyId,
      refId
    }; // Initialize the state to be the initial (persisted) state of the store.
    // This gives the modules the chance to read the persisted state, apply their defaults
    // and override if necessary

    const docsModeState = {
      layout: {
        showToolbar: false,
        showPanel: false
      },
      ui: {
        docsMode: true
      }
    };
    this.state = store.getInitialState(getInitialState(Object.assign({}, routeData, docsMode ? docsModeState : null)));
    const apiData = {
      navigate,
      store,
      provider: props.provider
    };
    this.modules = [provider, channel, addons, layout, notifications, settings, releaseNotes, shortcuts, stories, refs, globals, url, version].map(m => m.init(Object.assign({}, routeData, apiData, {
      state: this.state,
      fullAPI: this.api
    }))); // Create our initial state by combining the initial state of all modules, then overlaying any saved state

    const state = getInitialState(this.state, ...this.modules.map(m => m.state)); // Get our API by combining the APIs exported by each module

    const api = Object.assign(this.api, {
      navigate
    }, ...this.modules.map(m => m.api));
    this.state = state;
    this.api = api;
  }

  static getDerivedStateFromProps(props, state) {
    if (state.path !== props.path) {
      return Object.assign({}, state, {
        location: props.location,
        path: props.path,
        refId: props.refId,
        // if its a docsOnly page, even the 'story' view mode is considered 'docs'
        viewMode: (props.docsMode && props.viewMode) === 'story' ? 'docs' : props.viewMode,
        storyId: props.storyId
      });
    }

    return null;
  }

  shouldComponentUpdate(nextProps, nextState) {
    const prevState = this.state;
    const prevProps = this.props;

    if (prevState !== nextState) {
      return true;
    }

    if (prevProps.path !== nextProps.path) {
      return true;
    }

    return false;
  }

  render() {
    const {
      children
    } = this.props;
    const value = {
      state: this.state,
      api: this.api
    };
    return /*#__PURE__*/React.createElement(EffectOnMount, {
      effect: this.initModules
    }, /*#__PURE__*/React.createElement(ManagerContext.Provider, {
      value: value
    }, /*#__PURE__*/React.createElement(ManagerConsumer, null, children)));
  }

}

ManagerProvider.displayName = "ManagerProvider";
ManagerProvider.displayName = 'Manager';

// EffectOnMount exists to work around a bug in Reach Router where calling
// navigate inside of componentDidMount (as could happen when we call init on any
// of our modules) does not cause Reach Router's LocationProvider to update with
// the correct path. Calling navigate inside on an effect does not have the
// same problem. See https://github.com/reach/router/issues/404
const EffectOnMount = ({
  children,
  effect
}) => {
  React.useEffect(effect, []);
  return children;
};

const defaultFilter = c => c;

function ManagerConsumer({
  // @ts-ignore
  filter = defaultFilter,
  children
}) {
  const c = useContext(ManagerContext);
  const renderer = useRef(children);
  const filterer = useRef(filter);

  if (typeof renderer.current !== 'function') {
    return /*#__PURE__*/React.createElement(Fragment, null, renderer.current);
  }

  const data = filterer.current(c);
  const l = useMemo(() => {
    return [...Object.entries(data).reduce((acc, keyval) => acc.concat(keyval), [])];
  }, [c.state]);
  return useMemo(() => {
    const Child = renderer.current;
    return /*#__PURE__*/React.createElement(Child, data);
  }, l);
}

export function useStorybookState() {
  const {
    state
  } = useContext(ManagerContext);
  return state;
}
export function useStorybookApi() {
  const {
    api
  } = useContext(ManagerContext);
  return api;
}
export { ManagerConsumer as Consumer, ManagerProvider as Provider, isGroup, isRoot, isStory };

function orDefault(fromStore, defaultState) {
  if (typeof fromStore === 'undefined') {
    return defaultState;
  }

  return fromStore;
}

export const useChannel = (eventMap, deps = []) => {
  const api = useStorybookApi();
  useEffect(() => {
    Object.entries(eventMap).forEach(([type, listener]) => api.on(type, listener));
    return () => {
      Object.entries(eventMap).forEach(([type, listener]) => api.off(type, listener));
    };
  }, deps);
  return api.emit;
};
export function useStoryPrepared(storyId) {
  const api = useStorybookApi();
  return api.isPrepared(storyId);
}
export function useParameter(parameterKey, defaultValue) {
  const api = useStorybookApi();
  const result = api.getCurrentParameter(parameterKey);
  return orDefault(result, defaultValue);
}
// cache for taking care of HMR
const addonStateCache = {}; // shared state

export function useSharedState(stateId, defaultState) {
  const api = useStorybookApi();
  const existingState = api.getAddonState(stateId);
  const state = orDefault(existingState, addonStateCache[stateId] ? addonStateCache[stateId] : defaultState);

  const setState = (s, options) => {
    // set only after the stories are loaded
    if (addonStateCache[stateId]) {
      addonStateCache[stateId] = s;
    }

    api.setAddonState(stateId, s, options);
  };

  const allListeners = useMemo(() => {
    const stateChangeHandlers = {
      [`${SHARED_STATE_CHANGED}-client-${stateId}`]: s => setState(s),
      [`${SHARED_STATE_SET}-client-${stateId}`]: s => setState(s)
    };
    const stateInitializationHandlers = {
      [SET_STORIES]: () => {
        const currentState = api.getAddonState(stateId);

        if (currentState) {
          addonStateCache[stateId] = currentState;
          api.emit(`${SHARED_STATE_SET}-manager-${stateId}`, currentState);
        } else if (addonStateCache[stateId]) {
          // this happens when HMR
          setState(addonStateCache[stateId]);
          api.emit(`${SHARED_STATE_SET}-manager-${stateId}`, addonStateCache[stateId]);
        } else if (defaultState !== undefined) {
          // if not HMR, yet the defaults are from the manager
          setState(defaultState); // initialize addonStateCache after first load, so its available for subsequent HMR

          addonStateCache[stateId] = defaultState;
          api.emit(`${SHARED_STATE_SET}-manager-${stateId}`, defaultState);
        }
      },
      [STORY_CHANGED]: () => {
        const currentState = api.getAddonState(stateId);

        if (currentState !== undefined) {
          api.emit(`${SHARED_STATE_SET}-manager-${stateId}`, currentState);
        }
      }
    };
    return Object.assign({}, stateChangeHandlers, stateInitializationHandlers);
  }, [stateId]);
  const emit = useChannel(allListeners);
  return [state, (newStateOrMerger, options) => {
    setState(newStateOrMerger, options);
    emit(`${SHARED_STATE_CHANGED}-manager-${stateId}`, newStateOrMerger);
  }];
}
export function useAddonState(addonId, defaultState) {
  return useSharedState(addonId, defaultState);
}
export function useArgs() {
  const {
    getCurrentStoryData,
    updateStoryArgs,
    resetStoryArgs
  } = useStorybookApi();
  const data = getCurrentStoryData();
  const args = isStory(data) ? data.args : {};
  const updateArgs = useCallback(newArgs => updateStoryArgs(data, newArgs), [data, updateStoryArgs]);
  const resetArgs = useCallback(argNames => resetStoryArgs(data, argNames), [data, resetStoryArgs]);
  return [args, updateArgs, resetArgs];
}
export function useGlobals() {
  const api = useStorybookApi();
  return [api.getGlobals(), api.updateGlobals];
}
export function useGlobalTypes() {
  return useStorybookApi().getGlobalTypes();
}

function useCurrentStory() {
  const {
    getCurrentStoryData
  } = useStorybookApi();
  return getCurrentStoryData();
}

export function useArgTypes() {
  var _useCurrentStory;

  return ((_useCurrentStory = useCurrentStory()) === null || _useCurrentStory === void 0 ? void 0 : _useCurrentStory.argTypes) || {};
}