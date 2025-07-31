/* global axios */
import ApiClient from './ApiClient';

export class LeavesAPI extends ApiClient {
  constructor() {
    super('leaves', { accountScoped: true });
  }

  // GET /api/v1/accounts/:accountId/leaves
  get(params = {}) {
    return axios.get(this.url, { params });
  }

  // GET /api/v1/accounts/:accountId/leaves/:id
  show(id) {
    return axios.get(`${this.url}/${id}`);
  }

  // POST /api/v1/accounts/:accountId/leaves
  create(data) {
    return axios.post(this.url, { leave: data.leave, user_id: data.user_id });
  }

  // PUT /api/v1/accounts/:accountId/leaves/:id
  update(id, data) {
    return axios.put(`${this.url}/${id}`, { leave: data });
  }

  // DELETE /api/v1/accounts/:accountId/leaves/:id
  delete(id) {
    return axios.delete(`${this.url}/${id}`);
  }

  // POST /api/v1/accounts/:accountId/leaves/:id/approve
  approve(id, data = {}) {
    return axios.post(`${this.url}/${id}/approve`, data);
  }

  // POST /api/v1/accounts/:accountId/leaves/:id/reject
  reject(id, data = {}) {
    return axios.post(`${this.url}/${id}/reject`, data);
  }

  // GET /api/v1/accounts/:accountId/leaves/my_leaves
  getMyLeaves(params = {}) {
    return axios.get(`${this.url}/my_leaves`, { params });
  }

  // GET /api/v1/accounts/:accountId/leaves/pending_approvals
  getPendingApprovals(params = {}) {
    return axios.get(`${this.url}/pending_approvals`, { params });
  }
}

export default new LeavesAPI();
