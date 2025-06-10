import { createContext, useContext, useEffect, useRef } from 'react';
import { registerVueWebComponents } from '../vue-components/registerWebComponents';
import store from '../../../dashboard/store';
import constants from '../../../dashboard/constants/globals';
import axios from 'axios';
import createAxios from '../../../ui/axios';
import commonHelpers from '../../../dashboard/helper/commons';
import vueActionCable from '../../../dashboard/helper/actionCable';

const ChatwootContext = createContext();

export const ChatwootProvider = ({
  baseURL,
  userId,
  userToken,
  websocketURL,
  pubsubToken,
  children
}) => {
  const isInitialized = useRef(false);
  const originalGlobals = useRef({});

  // Validate required props
  if (!baseURL) {
    throw new Error('ChatwootProvider: baseURL is required');
  }
  if (!userToken) {
    throw new Error('ChatwootProvider: userToken is required');
  }

  // Configuration object passed to all child components
  const config = {
    baseURL: baseURL.replace(/\/$/, ''), // Remove trailing slash
    userId,
    userToken,
    websocketURL: websocketURL || `${baseURL.replace('http', 'ws')}/cable`,
    pubsubToken: pubsubToken || userToken, // Fallback to userToken if pubsubToken not provided
  };

  useEffect(() => {
    if (isInitialized.current) return;

    initializeChatwootGlobals();
    isInitialized.current = true;

    // Cleanup on unmount
    return () => {
      cleanupChatwootGlobals();
    };
  }, [config.baseURL, config.userToken, config.websocketURL, config.pubsubToken]);

  function initializeChatwootGlobals() {
    // Store original globals for cleanup
    storeOriginalGlobals();

    // Register Web Components
    registerVueWebComponents();

    // Set up global variables that Vue components expect
    window.__WOOT_API_HOST__ = config.baseURL;
    window.__WOOT_ACCESS_TOKEN__ = config.userToken;
    window.__WEBSOCKET_URL__ = config.websocketURL;
    window.__PUBSUB_TOKEN__ = config.pubsubToken;
    window.__WOOT_USER_ID__ = config.userId ? Number(config.userId) : undefined;
    window.__WOOT_ISOLATED_SHELL__ = true;

    // Initialize common helpers
    commonHelpers();

    // Set up global objects
    window.__CHATWOOT_STORE__ = store;
    window.WootConstants = constants;
    window.axios = createAxios(axios);

    // Initialize user in store and ActionCable
    store.dispatch('setUser').then(() => {
      vueActionCable.init(store, config.pubsubToken);
    });
  }

  function storeOriginalGlobals() {
    originalGlobals.current = {
      __WOOT_API_HOST__: window.__WOOT_API_HOST__,
      __WOOT_ACCESS_TOKEN__: window.__WOOT_ACCESS_TOKEN__,
      __WEBSOCKET_URL__: window.__WEBSOCKET_URL__,
      __PUBSUB_TOKEN__: window.__PUBSUB_TOKEN__,
      __WOOT_USER_ID__: window.__WOOT_USER_ID__,
      __WOOT_ISOLATED_SHELL__: window.__WOOT_ISOLATED_SHELL__,
      __CHATWOOT_STORE__: window.__CHATWOOT_STORE__,
      WootConstants: window.WootConstants,
      axios: window.axios
    };
  }

  function cleanupChatwootGlobals() {
    // Restore original globals
    Object.entries(originalGlobals.current).forEach(([key, value]) => {
      if (value !== undefined) {
        window[key] = value;
      } else {
        delete window[key];
      }
    });

    // Disconnect ActionCable
    if (vueActionCable.connection) {
      vueActionCable.connection.disconnect();
    }
  }

  return (
    <ChatwootContext.Provider value={config}>
      {children}
    </ChatwootContext.Provider>
  );
};

export const useChatwoot = () => {
  const context = useContext(ChatwootContext);
  if (!context) {
    throw new Error('useChatwoot must be used within ChatwootProvider');
  }
  return context;
};

// For backwards compatibility and explicit configuration access
export const useChawootConfig = useChatwoot;
