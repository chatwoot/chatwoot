/* eslint no-console: 0 */
/* global axios */
import ApiClient from '../ApiClient';

class DraftMessageApi extends ApiClient {
  constructor() {
    super('conversations', { accountScoped: true });
  }

  getDraft(conversationId) {
    return axios.get(`${this.url}/${conversationId}/draft_messages`);
  }

  updateDraft({ conversationId, message }) {
    return axios.put(`${this.url}/${conversationId}/draft_messages`, {
      message,
    });
  }

  deleteDraft(conversationId) {
    return axios.delete(`${this.url}/${conversationId}/draft_messages`);
  }
}

export default new DraftMessageApi();
