/* global axios */

import ApiClient from './ApiClient';

class AgentCapacityPolicies extends ApiClient {
  constructor() {
    super('agent_capacity_policies', { accountScoped: true });
  }

  getUsers(policyId) {
    return axios.get(`${this.url}/${policyId}/users`);
  }

  addUser(policyId, userData) {
    return axios.post(`${this.url}/${policyId}/users`, {
      user_id: userData.id,
      capacity: userData.capacity,
    });
  }

  removeUser(policyId, userId) {
    return axios.delete(`${this.url}/${policyId}/users/${userId}`);
  }

  createInboxLimit(policyId, limitData) {
    return axios.post(`${this.url}/${policyId}/inbox_limits`, {
      inbox_id: limitData.inboxId,
      conversation_limit: limitData.conversationLimit,
    });
  }

  updateInboxLimit(policyId, limitId, limitData) {
    return axios.put(`${this.url}/${policyId}/inbox_limits/${limitId}`, {
      conversation_limit: limitData.conversationLimit,
    });
  }

  deleteInboxLimit(policyId, limitId) {
    return axios.delete(`${this.url}/${policyId}/inbox_limits/${limitId}`);
  }
}

export default new AgentCapacityPolicies();
