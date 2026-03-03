/* global axios */
import ApiClient from './ApiClient';

class WhatsappFlowsAPI extends ApiClient {
  constructor() {
    super('whatsapp_flows', { accountScoped: true });
  }

  publish(flowId) {
    return axios.post(`${this.url}/${flowId}/publish`);
  }

  deprecate(flowId) {
    return axios.post(`${this.url}/${flowId}/deprecate`);
  }

  sync(flowId) {
    return axios.post(`${this.url}/${flowId}/sync`);
  }

  preview(flowId) {
    return axios.get(`${this.url}/${flowId}/preview`);
  }
}

export default new WhatsappFlowsAPI();
