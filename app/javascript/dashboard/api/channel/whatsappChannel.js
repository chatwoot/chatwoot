/* global axios */
import ApiClient from '../ApiClient';

class WhatsappChannel extends ApiClient {
  constructor() {
    super('whatsapp', { accountScoped: true });
  }

  createEmbeddedSignup(params) {
    return axios.post(`${this.baseUrl()}/whatsapp/authorization`, params);
  }

  requestEmbeddedSignupAccess(useCase) {
    return axios.post(`${this.baseUrl()}/whatsapp/access_request`, {
      use_case: useCase,
    });
  }

  postEmbeddedSignupAuthorization({ inboxId, ...params }) {
    return axios.post(`${this.baseUrl()}/whatsapp/authorization`, {
      ...params,
      inbox_id: inboxId,
    });
  }

  // The provider catalog the session setup form renders itself from: which providers
  // this account may pick, what each one asks for and what it can do once connected.
  getSessionProviders() {
    return axios.get(`${this.baseUrl()}/whatsapp/session_providers`);
  }

  previewManualSetup(params) {
    return axios.post(`${this.baseUrl()}/whatsapp/manual/preview`, params);
  }

  connectManualSetup(params) {
    return axios.post(`${this.baseUrl()}/whatsapp/manual/connect`, params);
  }

  getManualWebhookStatus(inboxId) {
    return axios.get(
      `${this.baseUrl()}/whatsapp/manual/${inboxId}/webhook_status`
    );
  }

  setupManualWebhook(inboxId) {
    return axios.post(
      `${this.baseUrl()}/whatsapp/manual/${inboxId}/setup_webhook`
    );
  }

  rotateZapiWebhookUrl(inboxId) {
    return axios.post(
      `${this.baseUrl()}/whatsapp/zapi/${inboxId}/rotate_webhook_url`
    );
  }
}

export default new WhatsappChannel();
