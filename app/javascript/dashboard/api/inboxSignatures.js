/* global axios */

const API_BASE = '/api/v1/profile/inbox_signatures';

export default {
  getAll(accountId) {
    return axios.get(API_BASE, {
      params: { account_id: accountId },
    });
  },

  get(inboxId) {
    return axios.get(`${API_BASE}/${inboxId}`);
  },

  upsert(inboxId, params) {
    return axios.put(`${API_BASE}/${inboxId}`, {
      inbox_signature: params,
    });
  },

  delete(inboxId) {
    return axios.delete(`${API_BASE}/${inboxId}`);
  },
};
