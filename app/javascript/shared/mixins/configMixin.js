export default {
  computed: {
    hostURL() {
      return window.chatwootConfig.hostURL;
    },
    twilioCallbackURL() {
      return `${this.hostURL}/twilio/callback`;
    },
    vapidPublicKey() {
      return window.chatwootConfig.vapidPublicKey;
    },
    enabledLanguages() {
      return window.chatwootConfig.enabledLanguages;
    },
  },
};
