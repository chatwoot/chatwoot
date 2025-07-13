import {
  ANALYTICS_IDENTITY,
  CHATWOOT_RESET,
  CHATWOOT_SET_USER,
} from '../constants/appEvents';
import AnalyticsHelper from './AnalyticsHelper';
import { emitter } from 'shared/helpers/mitt';

export const initializeAnalyticsEvents = () => {
  AnalyticsHelper.init();
  emitter.on(ANALYTICS_IDENTITY, ({ user }) => {
    AnalyticsHelper.identify(user);
  });
};

export const initializeAudioAlerts = () => {
  // Audio alerts now handled per component
};

export const initializeChatwootEvents = () => {
  emitter.on(CHATWOOT_RESET, () => {
    if (window.$chatwoot) {
      window.$chatwoot.reset();
    }
  });
  emitter.on(CHATWOOT_SET_USER, ({ user }) => {
    if (window.$chatwoot) {
      window.$chatwoot.setUser(user.email, {
        avatar_url: user.avatar_url,
        email: user.email,
        identifier_hash: user.hmac_identifier,
        name: user.name,
      });
      window.$chatwoot.setCustomAttributes({
        signedUpAt: user.created_at,
        cloudCustomer: 'true',
        account_id: user.account_id,
      });
    }

    initializeAudioAlerts();
  });
};
