/* global axios */
import ApiClient from './ApiClient';

export class AssignmentPoliciesAPI extends ApiClient {
  constructor() {
    super('assignment_policies', { accountScoped: true });
  }

  // GET /api/v1/accounts/:accountId/assignment_policies
  get() {
    return axios.get(this.url);
  }

  // GET /api/v1/accounts/:accountId/assignment_policies/:id
  show(id) {
    return axios.get(`${this.url}/${id}`);
  }

  // POST /api/v1/accounts/:accountId/assignment_policies
  create(data) {
    return axios.post(this.url, { assignment_policy: data });
  }

  // PUT /api/v1/accounts/:accountId/assignment_policies/:id
  update(id, data) {
    return axios.put(`${this.url}/${id}`, { assignment_policy: data });
  }

  // DELETE /api/v1/accounts/:accountId/assignment_policies/:id
  delete(id) {
    return axios.delete(`${this.url}/${id}`);
  }
}

export default new AssignmentPoliciesAPI();
