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

  summarizeEvent({ name = 'summarize', conversationId, hookId }) {
    return axios.post(`${this.url}/hooks/${hookId}/process_event`, {
      event: {
        name,
        data: {
          conversation_display_id: conversationId,
        },
      },
    });
  }

  replySuggestion({ name = 'reply_suggestion', conversationId, hookId }) {
    return axios.post(`${this.url}/hooks/${hookId}/process_event`, {
      event: {
        name,
        data: {
          conversation_display_id: conversationId,
        },
      },
    });
  }
}

export default new OpenAIAPI();
