/* global axios */
import ApiClient from '../ApiClient';

class CaptainInboxes extends ApiClient {
  constructor() {
    super('captain/assistants', { accountScoped: true });
  }

  get({ assistantId } = {}) {
    return axios.get(`${this.url}/${assistantId}/inboxes`);
  }

  create(params = {}) {
    const { assistantId, inboxId } = params;
    return axios.post(`${this.url}/${assistantId}/inboxes`, {
      inbox: { inbox_id: inboxId },
    });
  }

  delete(params = {}) {
    const { assistantId, inboxId } = params;
    return axios.delete(`${this.url}/${assistantId}/inboxes/${inboxId}`);
  }
}

export default new CaptainInboxes();
