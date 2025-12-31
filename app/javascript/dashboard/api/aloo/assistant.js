/* global axios */
import ApiClient from '../ApiClient';

class AlooAssistant extends ApiClient {
  constructor() {
    super('aloo/assistants', { accountScoped: true });
  }

  get({ page = 1, searchKey } = {}) {
    return axios.get(this.url, {
      params: {
        page,
        search: searchKey,
      },
    });
  }

  // Override create to wrap data under 'assistant' key as expected by Rails
  create(data) {
    return axios.post(this.url, { assistant: data });
  }

  // Override update to wrap data under 'assistant' key as expected by Rails
  update(id, data) {
    return axios.patch(`${this.url}/${id}`, { assistant: data });
  }

  getStats(assistantId) {
    return axios.get(`${this.url}/${assistantId}/stats`);
  }

  assignInbox(assistantId, inboxId) {
    return axios.post(`${this.url}/${assistantId}/assign_inbox`, {
      inbox_id: inboxId,
    });
  }

  unassignInbox(assistantId, inboxId) {
    return axios.delete(`${this.url}/${assistantId}/unassign_inbox`, {
      data: { inbox_id: inboxId },
    });
  }
}

export default new AlooAssistant();
