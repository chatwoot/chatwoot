/* global axios */

import ApiClient from '../ApiClient';

class OpenAIAPI extends ApiClient {
  constructor() {
    super('integrations', { accountScoped: true });
  }

  processEvent({ type = 'rephrase', content, tone, hookId }) {
    return axios.post(`${this.url}/hooks/${hookId}/process_event`, {
      event: {
        type,
        content,
        tone,
      },
    });
  }
}

export default new OpenAIAPI();
