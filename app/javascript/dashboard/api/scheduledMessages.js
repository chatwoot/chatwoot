/* global axios */
import ApiClient from './ApiClient';

class ScheduledMessagesApi extends ApiClient {
  constructor() {
    super('scheduled_messages', { accountScoped: true });
  }

  getAll(params = {}) {
    return axios.get(this.url, { params });
  }

  getByConversation(conversationId) {
    return axios.get(this.url, {
      params: { conversation_id: conversationId },
    });
  }

  get(id) {
    return axios.get(`${this.url}/${id}`);
  }

  create(scheduledMessageData) {
    return axios.post(this.url, {
      scheduled_message: scheduledMessageData,
    });
  }

  update(id, scheduledMessageData) {
    return axios.patch(`${this.url}/${id}`, {
      scheduled_message: scheduledMessageData,
    });
  }

  delete(id) {
    return axios.delete(`${this.url}/${id}`);
  }

  sendNow(id) {
    return axios.post(`${this.url}/${id}/send_now`);
  }
}

export default new ScheduledMessagesApi();
