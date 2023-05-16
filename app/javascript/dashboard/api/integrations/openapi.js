/* global axios */

import ApiClient from '../ApiClient';

class OpenAIAPI extends ApiClient {
  constructor() {
    super('integrations', { accountScoped: true });
  }

  processEvent({ type = 'rephrase', content, tone, conversationId, hookId }) {
    let data = {
      tone,
      content,
    };

    if (type === 'reply_suggestion' || type === 'summarize') {
      data = {
        conversation_display_id: conversationId,
      };
    }

    return axios.post(`${this.url}/hooks/${hookId}/process_event`, {
      event: {
        name: type,
        data,
      },
    });
  }
}

export default new OpenAIAPI();
