/* global axios */
import Auth from 'dashboard/api/auth';
import { useAccount } from 'dashboard/composables/useAccount';
import { getAgentManagerBaseUrl } from 'dashboard/constants/agentManager';

const BASE_URL = `${getAgentManagerBaseUrl()}/agent-manager/api/v1/agents`;

class CaptainAssistant {
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

  getAuthHeaders() {
    // Try to get Auth data from Auth module if available
    let authData = null;
    try {
      authData = Auth.getAuthData();
    } catch (e) {}
    const accountId = this.accountId || this.accountIdFromRoute;
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...(accountId ? { 'X-CHATWOOT-ACCOUNT-ID': accountId } : {}),
      ...(authData ? {
        'Access-Token': authData['access-token'],
        'Authorization': `${authData['token-type']} ${authData['access-token']}`,
      } : {}),
    };
  }

  get({ page = 1, searchKey } = {}) {
    return axios.get(`${BASE_URL}?page=${page}${searchKey ? `&searchKey=${encodeURIComponent(searchKey)}` : ''}`, {
      headers: this.getAuthHeaders(),
    });
  }

  show(id) {
    return axios.get(`${BASE_URL}/${id}`, {
      headers: this.getAuthHeaders(),
    });
  }

  create(data) {
    return axios.post(BASE_URL, data, {
      headers: this.getAuthHeaders(),
    });
  }

  update({ id, ...data }) {
    return axios.patch(`${BASE_URL}/${id}`, data, {
      headers: this.getAuthHeaders(),
    });
  }

  delete(id) {
    return axios.delete(`${BASE_URL}/${id}`, {
      headers: this.getAuthHeaders(),
    });
  }
}

export default new CaptainAssistant();
