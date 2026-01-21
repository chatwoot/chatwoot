import { createContext, useContext, useEffect, useRef, useState } from 'react';
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
  accountId,
  userToken,
  websocketURL,
  pubsubToken,
  conversationId,
  disableUpload,
  disableEditor,
  children,
}) => {
  const isInitialized = useRef(false);
  const [initializationComplete, setInitializationComplete] = useState(false);

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
    userToken,
    accountId: Number(accountId),
    conversationId: Number(conversationId),
    disableEditor: disableEditor || false,
    disableUpload: disableUpload || false,
    websocketURL: websocketURL,
    pubsubToken: pubsubToken,
  };

  function initializeChatwootGlobals() {
    // Register Web Components
    registerVueWebComponents();

    // Set up global variables that Vue components expect
    /* eslint-disable no-underscore-dangle */
    window.__WOOT_API_HOST__ = config.baseURL;
    window.__WOOT_ACCOUNT_ID__ = config.accountId;
    window.__WOOT_ACCESS_TOKEN__ = config.userToken;
    window.__WEBSOCKET_URL__ = config.websocketURL;
    window.__PUBSUB_TOKEN__ = config.pubsubToken;
    window.__WOOT_CONVERSATION_ID__ = config.conversationId;
    window.__EDITOR_DISABLE_UPLOAD__ = config.disableUpload;
    window.__DISABLE_EDITOR__ = config.disableEditor;
    window.__WOOT_ISOLATED_SHELL__ = true;
    /* eslint-enable no-underscore-dangle */

    // Initialize common helpers
    commonHelpers();

    // Set up global objects
    // eslint-disable-next-line no-underscore-dangle
    window.WootConstants = constants;
    window.axios = createAxios(axios);

    // Initialize user in store and ActionCable
    store.dispatch('setUser').then(() => {
      vueActionCable.init(store, config.pubsubToken);
      setInitializationComplete(true);
    });
  }

  useEffect(() => {
    if (isInitialized.current) return;

    initializeChatwootGlobals();
    isInitialized.current = true;
  }, [
    config.baseURL,
    config.userToken,
    config.websocketURL,
    config.pubsubToken,
  ]);

  if (!initializationComplete) {
    return null;
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
