/* eslint no-console: 0 */
/* global axios */
import ApiClient from '../ApiClient';

class MessageApi extends ApiClient {
  constructor() {
    super('conversations', { accountScoped: true });
  }

  create({ conversationId, message, private: isPrivate }) {
    return axios.post(`${this.url}/${conversationId}/messages`, {
      content: message,
      private: isPrivate,
    });
  }

  getPreviousMessages({ conversationId, before }) {
    return axios.get(`${this.url}/${conversationId}/messages`, {
      params: { before },
    });
  }

  sendAttachment([conversationId, { file, isPrivate = false }]) {
    const formData = new FormData();
    formData.append('attachments[]', file, file.name);
    formData.append('private', isPrivate);
    return axios({
      method: 'post',
      url: `${this.url}/${conversationId}/messages`,
      data: formData,
    });
  }
}

export default new MessageApi();
