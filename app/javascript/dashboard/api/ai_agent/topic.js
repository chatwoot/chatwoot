/* global axios */
import ApiClient from '../ApiClient';

class AiAgentTopic extends ApiClient {
  constructor() {
    super('captain/assistants', { accountScoped: true });
  }

  get({ page = 1, searchKey } = {}) {
    return axios.get(this.url, {
      params: {
        page,
        searchKey,
      },
    });
  }

  create(topicObj) {
    return axios.post(this.url, {
      assistant: topicObj,
    });
  }

  update({ id, ...topicObj }) {
    return axios.patch(`${this.url}/${id}`, {
      assistant: topicObj,
    });
  }

  delete(id) {
    return axios.delete(`${this.url}/${id}`);
  }

  show(id) {
    return axios.get(`${this.url}/${id}`);
  }

  playground({ topicId, messageContent, messageHistory }) {
    return axios.post(`${this.url}/${topicId}/playground`, {
      message_content: messageContent,
      message_history: messageHistory,
    });
  }
}

export default new AiAgentTopic();
