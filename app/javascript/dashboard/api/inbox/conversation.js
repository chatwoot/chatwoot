/* global axios */
import ApiClient from '../ApiClient';

class ConversationApi extends ApiClient {
  constructor() {
    super('conversations', { accountScoped: true });
  }

  get({ inboxId, status, assigneeType, page, labels }) {
    return axios.get(this.url, {
      params: {
        inbox_id: inboxId,
        status,
        assignee_type: assigneeType,
        page,
        labels,
      },
    });
  }

  toggleStatus(conversationId) {
    return axios.post(`${this.url}/${conversationId}/toggle_status`, {});
  }

  assignAgent({ conversationId, agentId }) {
    axios.post(
      `${this.url}/${conversationId}/assignments?assignee_id=${agentId}`,
      {}
    );
  }

  markMessageRead({ id }) {
    return axios.post(`${this.url}/${id}/update_last_seen`);
  }

  toggleTyping({ conversationId, status }) {
    return axios.post(`${this.url}/${conversationId}/toggle_typing_status`, {
      typing_status: status,
    });
  }

  mute(conversationId) {
    return axios.post(`${this.url}/${conversationId}/mute`);
  }

  meta({ inboxId, status, assigneeType, labels }) {
    return axios.get(`${this.url}/meta`, {
      params: {
        inbox_id: inboxId,
        status,
        assignee_type: assigneeType,
        labels,
      },
    });
  }
}

export default new ConversationApi();
