import { SET_GLOBALS, UPDATE_GLOBALS, GLOBALS_UPDATED } from '@storybook/core-events';
import { logger } from '@storybook/client-logger';
import deepEqual from 'fast-deep-equal';
import { getEventMetadata } from '../lib/events';
export const init = ({
  store,
  fullAPI
}) => {
  const api = {
    getGlobals() {
      return store.getState().globals;
    },

    getGlobalTypes() {
      return store.getState().globalTypes;
    },

    updateGlobals(newGlobals) {
      // Only emit the message to the local ref
      fullAPI.emit(UPDATE_GLOBALS, {
        globals: newGlobals,
        options: {
          target: 'storybook-preview-iframe'
        }
      });
    }

  };
  const state = {
    globals: {},
    globalTypes: {}
  };

  const updateGlobals = globals => {
    var _store$getState;

    const currentGlobals = (_store$getState = store.getState()) === null || _store$getState === void 0 ? void 0 : _store$getState.globals;

    if (!deepEqual(globals, currentGlobals)) {
      store.setState({
        globals
      });
    }
  };

  const initModule = () => {
    fullAPI.on(GLOBALS_UPDATED, function handleGlobalsUpdated({
      globals
    }) {
      const {
        ref
      } = getEventMetadata(this, fullAPI);

      if (!ref) {
        updateGlobals(globals);
      } else {
        logger.warn('received a GLOBALS_UPDATED from a non-local ref. This is not currently supported.');
      }
    }); // Emitted by the preview on initialization

    fullAPI.on(SET_GLOBALS, function handleSetStories({
      globals,
      globalTypes
    }) {
      var _store$getState2;

      const {
        ref
      } = getEventMetadata(this, fullAPI);
      const currentGlobals = (_store$getState2 = store.getState()) === null || _store$getState2 === void 0 ? void 0 : _store$getState2.globals;

      if (!ref) {
        store.setState({
          globals,
          globalTypes
        });
      } else if (Object.keys(globals).length > 0) {
        logger.warn('received globals from a non-local ref. This is not currently supported.');
      }

      if (currentGlobals && Object.keys(currentGlobals).length !== 0 && !deepEqual(globals, currentGlobals)) {
        api.updateGlobals(currentGlobals);
      }
    });
  };

  return {
    api,
    state,
    init: initModule
  };
};