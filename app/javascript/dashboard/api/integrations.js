/* global axios */

import ApiClient from './ApiClient';

class IntegrationsAPI extends ApiClient {
  constructor() {
    super('integrations/apps', { accountScoped: true });
  }

  connectSlack(code) {
    return axios.post(`${this.baseUrl()}/integrations/slack`, { code });
  }

  updateSlack({ referenceId }) {
    return axios.patch(`${this.baseUrl()}/integrations/slack`, {
      reference_id: referenceId,
    });
  }

  listAllSlackChannels() {
    return axios.get(`${this.baseUrl()}/integrations/slack/list_all_channels`);
  }

  delete(integrationId) {
    return axios.delete(`${this.baseUrl()}/integrations/${integrationId}`);
  }

  createHook(hookData) {
    return axios.post(`${this.baseUrl()}/integrations/hooks`, hookData);
  }

  deleteHook(hookId) {
    return axios.delete(`${this.baseUrl()}/integrations/hooks/${hookId}`);
  }

  connectShopify({ shopDomain }) {
    return axios.post(`${this.baseUrl()}/integrations/shopify/auth`, {
      shop_domain: shopDomain,
    });
  }

  getMoengage() {
    return axios.get(`${this.baseUrl()}/integrations/moengage`);
  }

  createMoengage(settings) {
    return axios.post(`${this.baseUrl()}/integrations/moengage`, {
      hook: { settings },
    });
  }

  updateMoengage(settings) {
    return axios.patch(`${this.baseUrl()}/integrations/moengage`, {
      hook: { settings },
    });
  }

  deleteMoengage() {
    return axios.delete(`${this.baseUrl()}/integrations/moengage`);
  }

  regenerateMoengageToken() {
    return axios.post(
      `${this.baseUrl()}/integrations/moengage/regenerate_token`
    );
  }

  getMoengageWebhookEventLogs({
    page = 1,
    perPage = 25,
    status,
    eventName,
  } = {}) {
    const params = new URLSearchParams();
    params.append('page', page);
    params.append('per_page', perPage);
    if (status) params.append('status', status);
    if (eventName) params.append('event_name', eventName);

    return axios.get(
      `${this.baseUrl()}/integrations/moengage/webhook_event_logs?${params.toString()}`
    );
  }
}

export default new IntegrationsAPI();
