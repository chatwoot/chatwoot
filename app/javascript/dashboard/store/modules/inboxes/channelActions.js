import * as types from '../../mutation-types';
import InboxesAPI from '../../../api/inboxes';
import EvolutionChannel from '../../../api/channel/evolutionChannel';
import AnalyticsHelper from '../../../helper/AnalyticsHelper';
import { ACCOUNT_EVENTS } from '../../../helper/AnalyticsHelper/events';
import { isEvolutionAPIError } from '../../../helper/evolutionErrorHandler';

export const buildInboxData = inboxParams => {
  const formData = new FormData();
  const { channel = {}, ...inboxProperties } = inboxParams;
  Object.keys(inboxProperties).forEach(key => {
    formData.append(key, inboxProperties[key]);
  });
  const { selectedFeatureFlags, ...channelParams } = channel;
  // selectedFeatureFlags needs to be empty when creating a website channel
  if (selectedFeatureFlags) {
    if (selectedFeatureFlags.length) {
      selectedFeatureFlags.forEach(featureFlag => {
        formData.append(`channel[selected_feature_flags][]`, featureFlag);
      });
    } else {
      formData.append('channel[selected_feature_flags][]', '');
    }
  }
  Object.keys(channelParams).forEach(key => {
    formData.append(`channel[${key}]`, channel[key]);
  });
  return formData;
};

const sendAnalyticsEvent = channelType => {
  AnalyticsHelper.track(ACCOUNT_EVENTS.ADDED_AN_INBOX, {
    channelType,
  });
};

export const channelActions = {
  createVoiceChannel: async ({ commit }, params) => {
    try {
      commit(types.default.SET_INBOXES_UI_FLAG, { isCreating: true });
      const response = await InboxesAPI.create({
        name: params.name,
        channel: { ...params.voice, type: 'voice' },
      });
      commit(types.default.ADD_INBOXES, response.data);
      commit(types.default.SET_INBOXES_UI_FLAG, { isCreating: false });
      sendAnalyticsEvent('voice');
      return response.data;
    } catch (error) {
      commit(types.default.SET_INBOXES_UI_FLAG, { isCreating: false });
      throw error;
    }
  },
  createEvolutionChannel: async ({ commit }, params) => {
    try {
      commit(types.default.SET_INBOXES_UI_FLAG, { isCreating: true });
      const response = await EvolutionChannel.create(params);
      commit(types.default.ADD_INBOXES, response.data);
      commit(types.default.SET_INBOXES_UI_FLAG, { isCreating: false });
      sendAnalyticsEvent('evolution');
      return response.data;
    } catch (error) {
      commit(types.default.SET_INBOXES_UI_FLAG, { isCreating: false });

      // Enhanced error handling for Evolution API
      if (isEvolutionAPIError(error)) {
        // Store the formatted error for the component to access
        const enhancedError = new Error(error.message);
        enhancedError.isEvolutionError = true;
        enhancedError.originalError = error;
        enhancedError.canRetry =
          error.response?.status >= 500 || !error.response;
        throw enhancedError;
      }

      throw error;
    }
  },
};
