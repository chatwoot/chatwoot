"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.init = void 0;

require("core-js/modules/es.object.keys.js");

var _coreEvents = require("@storybook/core-events");

var _clientLogger = require("@storybook/client-logger");

var _fastDeepEqual = _interopRequireDefault(require("fast-deep-equal"));

var _events = require("../lib/events");

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var init = function init(_ref) {
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
      fullAPI.emit(_coreEvents.UPDATE_GLOBALS, {
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

    if (!(0, _fastDeepEqual.default)(globals, currentGlobals)) {
      store.setState({
        globals: globals
      });
    }
  };

  var initModule = function initModule() {
    fullAPI.on(_coreEvents.GLOBALS_UPDATED, function handleGlobalsUpdated(_ref2) {
      var globals = _ref2.globals;

      var _getEventMetadata = (0, _events.getEventMetadata)(this, fullAPI),
          ref = _getEventMetadata.ref;

      if (!ref) {
        updateGlobals(globals);
      } else {
        _clientLogger.logger.warn('received a GLOBALS_UPDATED from a non-local ref. This is not currently supported.');
      }
    }); // Emitted by the preview on initialization

    fullAPI.on(_coreEvents.SET_GLOBALS, function handleSetStories(_ref3) {
      var _store$getState2;

      var globals = _ref3.globals,
          globalTypes = _ref3.globalTypes;

      var _getEventMetadata2 = (0, _events.getEventMetadata)(this, fullAPI),
          ref = _getEventMetadata2.ref;

      var currentGlobals = (_store$getState2 = store.getState()) === null || _store$getState2 === void 0 ? void 0 : _store$getState2.globals;

      if (!ref) {
        store.setState({
          globals: globals,
          globalTypes: globalTypes
        });
      } else if (Object.keys(globals).length > 0) {
        _clientLogger.logger.warn('received globals from a non-local ref. This is not currently supported.');
      }

      if (currentGlobals && Object.keys(currentGlobals).length !== 0 && !(0, _fastDeepEqual.default)(globals, currentGlobals)) {
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

exports.init = init;