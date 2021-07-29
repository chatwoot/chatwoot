/* eslint no-console: 0 */
/* global axios */
import ApiClient from '../ApiClient';

class MessageApi extends ApiClient {
  constructor() {
    super('conversations', { accountScoped: true });
  }

  create({
    conversationId,
    message,
    private: isPrivate,
    contentAttributes,
    echo_id: echoId,
    file,
  }) {
    let payload;
    if (file) {
      payload = new FormData();
      payload.append('attachments[]', file, file.name);
      if (message) {
        payload.append('content', message);
      }
      payload.append('private', isPrivate);
      payload.append('echo_id', echoId);
    } else {
      payload = {
        content: message,
        private: isPrivate,
        echo_id: echoId,
        content_attributes: contentAttributes,
      };
    }

    return axios({
      method: 'post',
      url: `${this.url}/${conversationId}/messages`,
      data: payload,
    });
  }

  delete(conversationID, messageId) {
    return axios.delete(`${this.url}/${conversationID}/messages/${messageId}`);
  }

  getPreviousMessages({ conversationId, before }) {
    return axios.get(`${this.url}/${conversationId}/messages`, {
      params: { before },
    });
  }
}

export default new MessageApi();
