/* global axios */
import ApiClient from '../ApiClient';

class AiagentInboxes extends ApiClient {
  constructor() {
    super('aiagent/topics', { accountScoped: true });
  }

  get({ topicId } = {}) {
    return axios.get(`${this.url}/${topicId}/inboxes`);
  }

  create(params = {}) {
    const { topicId, inboxId } = params;
    return axios.post(`${this.url}/${topicId}/inboxes`, {
      inbox: { inbox_id: inboxId },
    });
  }

  delete(params = {}) {
    const { topicId, inboxId } = params;
    return axios.delete(`${this.url}/${topicId}/inboxes/${inboxId}`);
  }
}

export default new AiagentInboxes();
