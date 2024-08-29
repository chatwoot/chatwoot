export const getEventNamei18n = event => {
  const eventName = event.toUpperCase();
  return `INTEGRATION_SETTINGS.WEBHOOK.FORM.SUBSCRIPTIONS.EVENTS.${eventName}`;
};
