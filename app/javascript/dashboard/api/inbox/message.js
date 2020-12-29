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
    const formData = new FormData();
    if (file) formData.append('attachments[]', file, file.name);
    if (message) formData.append('content', message);
    if (contentAttributes)
      formData.append('content_attributes', JSON.stringify(contentAttributes));

    formData.append('private', isPrivate);
    formData.append('echo_id', echoId);
    return axios({
      method: 'post',
      url: `${this.url}/${conversationId}/messages`,
      data: formData,
    });
  }

  getPreviousMessages({ conversationId, before }) {
    return axios.get(`${this.url}/${conversationId}/messages`, {
      params: { before },
    });
  }
}

export default new MessageApi();
