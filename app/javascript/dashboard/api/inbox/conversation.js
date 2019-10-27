/* global axios */
import ApiClient from '../ApiClient';

class ConversationApi extends ApiClient {
  constructor() {
    super('conversations');
  }

  get({ inboxId, convStatus, assigneeStatus }) {
    return axios.get(this.url, {
      params: {
        inbox_id: inboxId,
        conversation_status_id: convStatus,
        assignee_type_id: assigneeStatus,
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
}

export default new ConversationApi();
