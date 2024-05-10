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
        event: SMART_ACTION_EVENTS.ASK_COPILOT
      }
    });
  }
}

export default new SmartActionApi();
