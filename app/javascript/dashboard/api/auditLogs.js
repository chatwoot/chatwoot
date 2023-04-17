/* global axios */

import ApiClient from './ApiClient';

class AuditLogs extends ApiClient {
  constructor() {
    super('audit_logs', { accountScoped: true });
  }

  get({ page }) {
    const url = page ? `${this.url}?page=${page}` : this.url;
    return axios.get(url);
  }
}

export default new AuditLogs();
