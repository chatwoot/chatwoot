export default {
  methods: {
    getEventLabel(event) {
      const eventName = event.toUpperCase();
      return this.$t(
        `INTEGRATION_SETTINGS.WEBHOOK.FORM.SUBSCRIPTIONS.EVENTS.${eventName}`
      );
    },
  },
};
