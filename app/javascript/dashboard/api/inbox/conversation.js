/* global axios */
import ApiClient from '../ApiClient';

class ConversationApi extends ApiClient {
  constructor() {
    super('conversations', { accountScoped: true });
  }

  get({ inboxId, status, assigneeType, page }) {
    return axios.get(this.url, {
      params: {
        inbox_id: inboxId,
        status,
        assignee_type: assigneeType,
        page,
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

  markMessageRead({ id, lastSeen }) {
    return axios.post(`${this.url}/${id}/update_last_seen`, {
      agent_last_seen_at: lastSeen,
    });
  }

  toggleTyping({ conversationId, status }) {
    return axios.post(`${this.url}/${conversationId}/toggle_typing_status`, {
      typing_status: status,
    });
  }
}

export default new ConversationApi();
