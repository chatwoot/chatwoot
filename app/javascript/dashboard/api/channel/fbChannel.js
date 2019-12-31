/* global axios */
import ApiClient from '../ApiClient';

class FBChannel extends ApiClient {
  constructor() {
    super('facebook_indicators');
  }

  markSeen({ inboxId, contactId }) {
    return axios.post(`${this.url}/mark_seen`, {
      inbox_id: inboxId,
      contact_id: contactId,
    });
  }

  toggleTyping({ status, inboxId, contactId }) {
    return axios.post(`${this.url}/typing_${status}`, {
      inbox_id: inboxId,
      contact_id: contactId,
    });
  }

  create(params) {
    return axios.post(
      `${this.apiVersion}/callbacks/register_facebook_page`,
      params
    );
  }
}

export default new FBChannel();
