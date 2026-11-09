/* global axios */

import ApiClient from './ApiClient';

class AuditLogs extends ApiClient {
  constructor() {
    super('audit_logs', { accountScoped: true });
  }

  get(filters = {}) {
    return axios.get(this.url, { params: filters });
  }
}

export default new AuditLogs();
