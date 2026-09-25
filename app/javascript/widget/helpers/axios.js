import axios from 'axios';
import { APP_BASE_URL } from 'widget/helpers/constants';
import { isMultipleConversationsEnabled } from 'widget/helpers/utils';

export const API = axios.create({
  baseURL: APP_BASE_URL,
  withCredentials: false,
});

let activeConversationId = null;

// With multiple conversations the server no longer infers the conversation, so every request names it.
export const setActiveConversationId = id => {
  activeConversationId = id || null;
};

API.interceptors.request.use(config => {
  if (
    !activeConversationId ||
    !isMultipleConversationsEnabled() ||
    config.params?.conversation_id
  ) {
    return config;
  }
  return {
    ...config,
    params: { ...config.params, conversation_id: activeConversationId },
  };
});

export const setHeader = (value, key = 'X-Auth-Token') => {
  API.defaults.headers.common[key] = value;
};

export const removeHeader = key => {
  delete API.defaults.headers.common[key];
};
