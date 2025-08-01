/* global axios */
import { getAgentManagerBaseUrl } from 'dashboard/constants/agentManager';

class CaptainDocument {
  constructor() {
    this.accountId = null;
  }

  get accountIdFromRoute() {
    const isInsideAccountScopedURLs =
      window.location.pathname.includes('/app/accounts');

    if (isInsideAccountScopedURLs) {
      return window.location.pathname.split('/')[3];
    }

    return null;
  }

  setAccountId(id) {
    this.accountId = id;
  }

  get({ page = 1, searchKey } = {}) {
    const baseUrl = getAgentManagerBaseUrl();
    return axios.get(`${baseUrl}/agent-manager/api/v1/datasources`, {
      params: {
        page,
        searchKey,
      },
      headers: {
        'X-CHATWOOT-ACCOUNT-ID': this.accountId || this.accountIdFromRoute,
      },
    });
  }

  create(data) {
    const isFileUpload = data instanceof FormData;
    const baseUrl = getAgentManagerBaseUrl();
    
    return axios.post(`${baseUrl}/agent-manager/api/v1/datasources`, data, {
      headers: {
        ...(isFileUpload ? {} : { 'Content-Type': 'application/json' }),
        'X-CHATWOOT-ACCOUNT-ID': this.accountId || this.accountIdFromRoute,
      },
    });
  }

  delete(id) {
    const baseUrl = getAgentManagerBaseUrl();
    return axios.delete(`${baseUrl}/agent-manager/api/v1/datasources/${id}`, {
      headers: {
        'X-CHATWOOT-ACCOUNT-ID': this.accountId || this.accountIdFromRoute,
      },
    });
  }
}

export default new CaptainDocument();
