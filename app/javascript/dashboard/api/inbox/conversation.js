/* global axios */
import ApiClient from '../ApiClient';

class ConversationApi extends ApiClient {
  constructor() {
    super('conversations', { accountScoped: true });
  }

  get({
    inboxId,
    status,
    assigneeType,
    page,
    labels,
    teamId,
    conversationType,
  }) {
    return axios.get(this.url, {
      params: {
        inbox_id: inboxId,
        team_id: teamId,
        status,
        assignee_type: assigneeType,
        page,
        labels,
        conversation_type: conversationType,
      },
    });
  }

  filter(payload) {
    return axios.post(`${this.url}/filter`, payload.queryData, {
      params: {
        page: payload.page,
      },
    });
  }

  search({ q }) {
    return axios.get(`${this.url}/search`, {
      params: {
        q,
        page: 1,
      },
    });
  }

  toggleStatus({ conversationId, status, snoozedUntil = null }) {
    return axios.post(`${this.url}/${conversationId}/toggle_status`, {
      status,
      snoozed_until: snoozedUntil,
    });
  }

  assignAgent({ conversationId, agentId }) {
    return axios.post(
      `${this.url}/${conversationId}/assignments?assignee_id=${agentId}`,
      {}
    );
  }

  assignTeam({ conversationId, teamId }) {
    const params = { team_id: teamId };
    return axios.post(`${this.url}/${conversationId}/assignments`, params);
  }

  markMessageRead({ id }) {
    return axios.post(`${this.url}/${id}/update_last_seen`);
  }

  toggleTyping({ conversationId, status, isPrivate }) {
    return axios.post(`${this.url}/${conversationId}/toggle_typing_status`, {
      typing_status: status,
      is_private: isPrivate,
    });
  }

  mute(conversationId) {
    return axios.post(`${this.url}/${conversationId}/mute`);
  }

  unmute(conversationId) {
    return axios.post(`${this.url}/${conversationId}/unmute`);
  }

  meta({ inboxId, status, assigneeType, labels, teamId, conversationType }) {
    return axios.get(`${this.url}/meta`, {
      params: {
        inbox_id: inboxId,
        status,
        assignee_type: assigneeType,
        labels,
        team_id: teamId,
        conversation_type: conversationType,
      },
    });
  }

  sendEmailTranscript({ conversationId, email }) {
    return axios.post(`${this.url}/${conversationId}/transcript`, { email });
  }

  updateCustomAttributes({ conversationId, customAttributes }) {
    return axios.post(`${this.url}/${conversationId}/custom_attributes`, {
      custom_attributes: customAttributes,
    });
  }
}

export default new ConversationApi();
