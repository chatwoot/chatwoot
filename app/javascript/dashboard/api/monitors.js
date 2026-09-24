/* global axios */
import ApiClient from './ApiClient';

class MonitorsAPI extends ApiClient {
  constructor() {
    super('monitors', { accountScoped: true });
  }

  get(params, signal) {
    return axios.get(this.url, { params, signal });
  }

  timeseries(id, params, signal) {
    return axios.get(`${this.url}/${id}/timeseries`, { params, signal });
  }

  conversations({ monitorId, signal, ...params }) {
    return axios.get(`${this.url}/${monitorId}/conversations`, {
      params,
      signal,
    });
  }

  retry(id, signal) {
    return axios.post(`${this.url}/${id}/retry_evaluations`, undefined, {
      signal,
    });
  }

  resume(id, params) {
    return axios.post(`${this.url}/${id}/resume`, params);
  }

  preview(condition) {
    return axios.post(`${this.url}/preview`, { condition });
  }

  previewStatus(token) {
    return axios.get(`${this.url}/preview/${token}`);
  }
}

export default new MonitorsAPI();
