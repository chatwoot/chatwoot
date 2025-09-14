/* global axios */
import ApiClient from './ApiClient';

class MessageTemplatesAPI extends ApiClient {
  constructor() {
    super('message_templates', { accountScoped: true });
  }

  getFiltered(filters = {}) {
    const params = new URLSearchParams();

    if (filters.inbox_id) params.append('inbox_id', filters.inbox_id);
    if (filters.channel_type)
      params.append('channel_type', filters.channel_type);
    if (filters.language) params.append('language', filters.language);
    if (filters.status) params.append('status', filters.status);

    const queryString = params.toString();
    const url = queryString ? `${this.url}?${queryString}` : this.url;

    return axios.get(url);
  }

  getByInbox(inboxId) {
    return this.getFiltered({ inbox_id: inboxId });
  }

  getByStatus(status) {
    return this.getFiltered({ status: status });
  }

  // TODO: remove this and just use getByStatus
  getApproved() {
    return this.getFiltered({ status: 'approved' });
  }
}

export default new MessageTemplatesAPI();
