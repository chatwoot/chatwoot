/* eslint no-console: 0 */
/* global axios */
import ApiClient from '../ApiClient';
import { SMART_ACTION_EVENTS } from 'shared/constants/smartActionEvents';

class SmartActionApi extends ApiClient {
  constructor() {
    super('conversations', { accountScoped: true });
  }

  getSmartActions(conversationId) {
    return axios.get(`${this.url}/${conversationId}/smart_actions`);
  }

  askCopilot(conversationId) {
    return axios.get(`${this.url}/${conversationId}/smart_actions/event_data`, {
      params: {
        event: SMART_ACTION_EVENTS.ASK_COPILOT,
      },
    });
  }

  cancelBooking(link) {
    axios.get(link)
    .then(response => {
      console.log(response.data);
    })
    .catch(error => {
      console.error('Error:', error);
    });

    return true;
  }
}

export default new SmartActionApi();
