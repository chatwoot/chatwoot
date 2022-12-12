import "core-js/modules/es.object.keys.js";
import { SET_GLOBALS, UPDATE_GLOBALS, GLOBALS_UPDATED } from '@storybook/core-events';
import { logger } from '@storybook/client-logger';
import deepEqual from 'fast-deep-equal';
import { getEventMetadata } from '../lib/events';
export var init = function init(_ref) {
  var store = _ref.store,
      fullAPI = _ref.fullAPI;
  var api = {
    getGlobals: function getGlobals() {
      return store.getState().globals;
    },
    getGlobalTypes: function getGlobalTypes() {
      return store.getState().globalTypes;
    },
    updateGlobals: function updateGlobals(newGlobals) {
      // Only emit the message to the local ref
      fullAPI.emit(UPDATE_GLOBALS, {
        globals: newGlobals,
        options: {
          target: 'storybook-preview-iframe'
        }
      });
    }
  };
  var state = {
    globals: {},
    globalTypes: {}
  };

  var updateGlobals = function updateGlobals(globals) {
    var _store$getState;

    var currentGlobals = (_store$getState = store.getState()) === null || _store$getState === void 0 ? void 0 : _store$getState.globals;

    if (!deepEqual(globals, currentGlobals)) {
      store.setState({
        globals: globals
      });
    }
  };

  var initModule = function initModule() {
    fullAPI.on(GLOBALS_UPDATED, function handleGlobalsUpdated(_ref2) {
      var globals = _ref2.globals;

      var _getEventMetadata = getEventMetadata(this, fullAPI),
          ref = _getEventMetadata.ref;

      if (!ref) {
        updateGlobals(globals);
      } else {
        logger.warn('received a GLOBALS_UPDATED from a non-local ref. This is not currently supported.');
      }
    }); // Emitted by the preview on initialization

    fullAPI.on(SET_GLOBALS, function handleSetStories(_ref3) {
      var _store$getState2;

      var globals = _ref3.globals,
          globalTypes = _ref3.globalTypes;

      var _getEventMetadata2 = getEventMetadata(this, fullAPI),
          ref = _getEventMetadata2.ref;

      var currentGlobals = (_store$getState2 = store.getState()) === null || _store$getState2 === void 0 ? void 0 : _store$getState2.globals;

      if (!ref) {
        store.setState({
          globals: globals,
          globalTypes: globalTypes
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
    api: api,
    state: state,
    init: initModule
  };
};