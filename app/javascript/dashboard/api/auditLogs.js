/* global axios */

import ApiClient from './ApiClient';

class AuditLogs extends ApiClient {
  constructor() {
    super('audit_logs', { accountScoped: true });
  }

  get({ searchKey }) {
    const url = searchKey ? `${this.url}?search=${searchKey}` : this.url;
    return axios.get(url);
  }
}

export default new AuditLogs();
