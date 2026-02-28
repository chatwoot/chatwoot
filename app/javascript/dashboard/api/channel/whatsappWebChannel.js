/* global axios */
import ApiClient from '../ApiClient';

class WhatsappWebChannel extends ApiClient {
  constructor() {
    super('inboxes', { accountScoped: true });
  }

  basePath(inboxId) {
    return `${this.url}/${inboxId}/whatsapp_web`;
  }

  showConfig(inboxId) {
    return axios.get(this.basePath(inboxId));
  }

  updateConfig(inboxId, payload) {
    return axios.patch(this.basePath(inboxId), payload);
  }

  setup(inboxId, payload) {
    return axios.post(`${this.basePath(inboxId)}/setup`, payload);
  }

  testConnection(inboxId) {
    return axios.post(`${this.basePath(inboxId)}/test_connection`);
  }

  listDevices(inboxId) {
    return axios.get(`${this.basePath(inboxId)}/devices`);
  }

  status(inboxId, payload = {}) {
    return axios.get(`${this.basePath(inboxId)}/status`, { params: payload });
  }

  loginQr(inboxId, payload = {}) {
    return axios.post(`${this.basePath(inboxId)}/login_qr`, payload);
  }

  loginCode(inboxId, payload = {}) {
    return axios.post(`${this.basePath(inboxId)}/login_code`, payload);
  }

  reconnect(inboxId, payload = {}) {
    return axios.post(`${this.basePath(inboxId)}/reconnect`, payload);
  }

  logout(inboxId, payload = {}) {
    return axios.post(`${this.basePath(inboxId)}/logout`, payload);
  }

  removeDevice(inboxId, payload = {}) {
    return axios.post(`${this.basePath(inboxId)}/remove_device`, payload);
  }

  sync(inboxId, payload = {}) {
    return axios.post(`${this.basePath(inboxId)}/sync`, payload);
  }

  syncStatus(inboxId, payload = {}) {
    return axios.get(`${this.basePath(inboxId)}/sync_status`, {
      params: payload,
    });
  }
}

export default new WhatsappWebChannel();
