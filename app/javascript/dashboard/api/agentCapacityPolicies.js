/* global axios */
import ApiClient from './ApiClient';

export class AgentCapacityPoliciesAPI extends ApiClient {
  constructor() {
    super('agent_capacity_policies', { accountScoped: true });
  }

  // GET /api/v1/accounts/:accountId/agent_capacity_policies
  get(params = {}) {
    return axios.get(this.url, { params });
  }

  // GET /api/v1/accounts/:accountId/agent_capacity_policies/:id
  show(id) {
    return axios.get(`${this.url}/${id}`);
  }

  // POST /api/v1/accounts/:accountId/agent_capacity_policies
  create(data) {
    return axios.post(this.url, { agent_capacity_policy: data });
  }

  // PUT /api/v1/accounts/:accountId/agent_capacity_policies/:id
  update(id, data) {
    return axios.put(`${this.url}/${id}`, { agent_capacity_policy: data });
  }

  // DELETE /api/v1/accounts/:accountId/agent_capacity_policies/:id
  delete(id) {
    return axios.delete(`${this.url}/${id}`);
  }

  // POST /api/v1/accounts/:accountId/agent_capacity_policies/:id/users
  assignUser(id, userId) {
    return axios.post(`${this.url}/${id}/users`, {
      user_id: userId,
    });
  }

  // DELETE /api/v1/accounts/:accountId/agent_capacity_policies/:id/users/:userId
  removeUser(id, userId) {
    return axios.delete(`${this.url}/${id}/users/${userId}`);
  }

  // POST /api/v1/accounts/:accountId/agent_capacity_policies/:id/inbox_limits/:inboxId
  setInboxLimit(id, inboxId, conversationLimit) {
    return axios.post(`${this.url}/${id}/inbox_limits/${inboxId}`, {
      conversation_limit: conversationLimit,
    });
  }

  // DELETE /api/v1/accounts/:accountId/agent_capacity_policies/:id/inbox_limits/:inboxId
  removeInboxLimit(id, inboxId) {
    return axios.delete(`${this.url}/${id}/inbox_limits/${inboxId}`);
  }

  // GET /api/v1/accounts/:accountId/agents/:agentId/capacity
  getAgentCapacity(accountId, agentId, inboxId = null) {
    const url = `/api/v1/accounts/${accountId}/agents/${agentId}/capacity`;
    const params = inboxId ? { inbox_id: inboxId } : {};
    return axios.get(url, { params });
  }
}

export default new AgentCapacityPoliciesAPI();
