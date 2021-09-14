import posthog from 'posthog-js';

export const CHATWOOT_SET_USER = 'CHATWOOT_SET_USER';
export const CHATWOOT_RESET = 'CHATWOOT_RESET';

export const ANALYTICS_IDENTITY = 'ANALYTICS_IDENTITY';
export const ANALYTICS_RESET = 'ANALYTICS_RESET';

export const initializeAnalyticsEvents = () => {
  window.bus.$on(ANALYTICS_IDENTITY, ({ user }) => {
    if (window.analyticsConfig) {
      posthog.identify(user.id, { name: user.name, email: user.email });
    }
  });

  window.bus.$on(ANALYTICS_RESET, () => {
    if (window.analyticsConfig) {
      posthog.reset();
    }
  });
};

export const initializeChatwootEvents = () => {
  window.bus.$on(CHATWOOT_RESET, () => {
    if (window.$chatwoot) {
      window.$chatwoot.reset();
    }
  });
  window.bus.$on(CHATWOOT_SET_USER, ({ user }) => {
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
      });
    }
  });
};
