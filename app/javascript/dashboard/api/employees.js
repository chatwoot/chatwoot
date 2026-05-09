/* global axios */

import ApiClient from './ApiClient';

class Employees extends ApiClient {
  constructor() {
    super('employees', { accountScoped: true });
  }

  list(params = {}) {
    return axios.get(this.url, { params });
  }

  changePassword(id, data) {
    return axios.patch(`${this.url}/${id}/change_password`, { employee: data });
  }

  activate(id) {
    return axios.patch(`${this.url}/${id}/activate`);
  }

  deactivate(id, data) {
    return axios.patch(`${this.url}/${id}/deactivate`, { employee: data });
  }

  archive(id, data) {
    return axios.patch(`${this.url}/${id}/archive`, { employee: data });
  }

  forceLogout(id) {
    return axios.post(`${this.url}/${id}/force_logout`);
  }

  sessions(id) {
    return axios.get(`${this.url}/${id}/sessions`);
  }

  loginHistory(id) {
    return axios.get(`${this.url}/${id}/login_history`);
  }

  activity(id) {
    return axios.get(`${this.url}/${id}/activity`);
  }

  deleteSession(id, clientId) {
    return axios.delete(`${this.url}/${id}/sessions/${clientId}`);
  }

  bulkUpdate(data) {
    return axios.patch(`${this.url}/bulk_update`, data);
  }
}

export default new Employees();
