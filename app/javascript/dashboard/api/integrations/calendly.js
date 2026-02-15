/* global axios */

import ApiClient from '../ApiClient';

class CalendlyAPI extends ApiClient {
  constructor() {
    super('integrations/calendly', { accountScoped: true });
  }

  getEventTypes() {
    return axios.get(`${this.url}/event_types`);
  }

  createSchedulingLink(eventTypeUri) {
    return axios.post(`${this.url}/scheduling_link`, {
      event_type_uri: eventTypeUri,
    });
  }

  getScheduledEvents() {
    return axios.get(`${this.url}/scheduled_events`);
  }

  cancelEvent(eventUuid, reason = '') {
    return axios.post(`${this.url}/cancel_event`, {
      event_uuid: eventUuid,
      reason,
    });
  }

  getAvailableTimes(eventTypeUri, startTime, endTime) {
    return axios.get(`${this.url}/available_times`, {
      params: {
        event_type_uri: eventTypeUri,
        start_time: startTime,
        end_time: endTime,
      },
    });
  }

  updateSettings(settings) {
    return axios.patch(`${this.url}/update_settings`, settings);
  }

  resubscribeWebhook() {
    return axios.post(`${this.url}/resubscribe_webhook`);
  }
}

export default new CalendlyAPI();
