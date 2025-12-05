/* global axios */
import ApiClient from './ApiClient';

class WhatsappWebGatewayApi extends ApiClient {
  constructor() {
    super('whatsapp_web/gateway', { accountScoped: true });
  }

  login(inboxId) {
    return axios.get(`${this.url}/${inboxId}/login`);
  }

  loginWithCode(inboxId, phone) {
    return axios.get(`${this.url}/${inboxId}/login_with_code`, {
      params: { phone },
    });
  }

  getDevices(inboxId) {
    return axios.get(`${this.url}/${inboxId}/devices`);
  }

  getStatus(inboxId) {
    return axios.get(`${this.url}/${inboxId}/status`);
  }

  logout(inboxId) {
    return axios.get(`${this.url}/${inboxId}/logout`);
  }

  reconnect(inboxId) {
    return axios.get(`${this.url}/${inboxId}/reconnect`);
  }

  syncHistory(inboxId) {
    return axios.post(`${this.url}/${inboxId}/sync_history`);
  }

  // Test endpoints for gateway configuration validation
  testConnection(gatewayConfig) {
    return axios.post(`${this.url}/test_connection`, {
      gateway_base_url: gatewayConfig.gatewayBaseUrl,
      basic_auth_user: gatewayConfig.basicAuthUser,
      basic_auth_password: gatewayConfig.basicAuthPassword,
      phone_number: gatewayConfig.phoneNumber,
    });
  }

  testDevices(gatewayConfig) {
    return axios.post(`${this.url}/test_devices`, {
      gateway_base_url: gatewayConfig.gatewayBaseUrl,
      basic_auth_user: gatewayConfig.basicAuthUser,
      basic_auth_password: gatewayConfig.basicAuthPassword,
      phone_number: gatewayConfig.phoneNumber,
    });
  }
}

export default new WhatsappWebGatewayApi();
