/* global axios */

import ApiClient from './ApiClient';

class AuditLogs extends ApiClient {
  constructor() {
    super('audit_logs', { accountScoped: true });
  }

  get(filters = {}) {
    const params = Object.fromEntries(
      Object.entries(filters).filter(([, value]) =>
        Array.isArray(value)
          ? value.length > 0
          : value !== undefined && value !== null && value !== ''
      )
    );
    return axios.get(this.url, { params });
  }
}

export default new AuditLogs();
