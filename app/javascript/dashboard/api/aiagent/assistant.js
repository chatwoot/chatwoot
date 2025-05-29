/* global axios */
import ApiClient from '../ApiClient';

class AiagentAssistant extends ApiClient {
  constructor() {
    super('aiagent/assistants', { accountScoped: true });
  }

  get({ page = 1, searchKey } = {}) {
    return axios.get(this.url, {
      params: {
        page,
        searchKey,
      },
    });
  }

  playground({ assistantId, messageContent, messageHistory }) {
    return axios.post(`${this.url}/${assistantId}/playground`, {
      message_content: messageContent,
      message_history: messageHistory,
    });
  }
}

export default new AiagentAssistant();
