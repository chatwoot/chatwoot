import axios from 'axios';
import { APP_BASE_URL } from 'widget/helpers/constants';
import { isMultipleConversationsEnabled } from 'widget/helpers/utils';

export const API = axios.create({
  baseURL: APP_BASE_URL,
  withCredentials: false,
});

let activeConversationId = null;

// With multiple conversations every request names its conversation, blank for a new one, so the
// server can tell this widget apart from one loaded before the inbox enabled the feature.
export const setActiveConversationId = id => {
  activeConversationId = id || null;
};

API.interceptors.request.use(config => {
  if (!isMultipleConversationsEnabled() || config.params?.conversation_id) {
    return config;
  }
  return {
    ...config,
    params: { ...config.params, conversation_id: activeConversationId ?? '' },
  };
});

export const setHeader = (value, key = 'X-Auth-Token') => {
  API.defaults.headers.common[key] = value;
};

export const removeHeader = key => {
  delete API.defaults.headers.common[key];
};
