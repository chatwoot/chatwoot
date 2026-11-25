/* global axios */
import ApiClient from './ApiClient';

class InternalChatMessagesAPI extends ApiClient {
  constructor() {
    super('internal_chat/channels', { accountScoped: true });
  }

  getMessages(channelId, params = {}) {
    return axios.get(`${this.url}/${channelId}/messages`, { params });
  }

  createMessage(channelId, data, files = []) {
    if (files.length === 0) {
      return axios.post(`${this.url}/${channelId}/messages`, data);
    }
    const formData = new FormData();
    if (data.content) formData.append('content', data.content);
    if (data.parent_id) formData.append('parent_id', data.parent_id);
    if (data.echo_id) formData.append('echo_id', data.echo_id);
    if (data.also_send_in_channel)
      formData.append('also_send_in_channel', data.also_send_in_channel);
    files.forEach(file => {
      formData.append('attachments[][file]', file);
    });
    return axios.post(`${this.url}/${channelId}/messages`, formData);
  }

  updateMessage(channelId, messageId, data) {
    return axios.patch(`${this.url}/${channelId}/messages/${messageId}`, data);
  }

  deleteMessage(channelId, messageId) {
    return axios.delete(`${this.url}/${channelId}/messages/${messageId}`);
  }

  getThread(channelId, messageId) {
    return axios.get(`${this.url}/${channelId}/messages/${messageId}/thread`);
  }

  pinMessage(channelId, messageId) {
    return axios.post(`${this.url}/${channelId}/messages/${messageId}/pin`);
  }

  unpinMessage(channelId, messageId) {
    return axios.delete(`${this.url}/${channelId}/messages/${messageId}/unpin`);
  }

  addReaction(messageId, emoji) {
    const baseUrl = this.url.replace('/channels', '');
    return axios.post(`${baseUrl}/messages/${messageId}/reactions`, {
      emoji,
    });
  }

  removeReaction(messageId, reactionId) {
    const baseUrl = this.url.replace('/channels', '');
    return axios.delete(
      `${baseUrl}/messages/${messageId}/reactions/${reactionId}`
    );
  }
}

export default new InternalChatMessagesAPI();
