/* global axios */

import ApiClient from '../ApiClient';

class OpenAIAPI extends ApiClient {
  constructor() {
    super('integrations', { accountScoped: true });
  }

  processEvent({ name = 'rephrase', content, tone, hookId }) {
    return axios.post(`${this.url}/hooks/${hookId}/process_event`, {
      event: {
        name: name,
        data: {
          tone,
          content,
        },
      },
    });
  }
}

export default new OpenAIAPI();
