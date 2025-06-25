export default {
  computed: {
    hostURL() {
      return window.chatwootConfig.hostURL;
    },
    vapidPublicKey() {
      return window.chatwootConfig.vapidPublicKey;
    },
    enabledLanguages() {
      return window.chatwootConfig.enabledLanguages;
    },
    isEnterprise() {
      return window.chatwootConfig.isEnterprise === 'true';
    },
  },
};
