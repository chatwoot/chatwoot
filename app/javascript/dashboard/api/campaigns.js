/* global axios */
import ApiClient from './ApiClient';

class CampaignsAPI extends ApiClient {
  constructor() {
    super('campaigns', { accountScoped: true });
  }

  getRecipients(campaignId, { status, page, q } = {}) {
    return axios.get(`${this.url}/${campaignId}/recipients`, {
      params: { status, page, q },
    });
  }

  getStats(campaignId) {
    return axios.get(`${this.url}/${campaignId}/stats`);
  }

  previewAudience({ inboxId, audience } = {}) {
    return axios.post(`${this.url}/preview_audience`, {
      inbox_id: inboxId,
      audience,
    });
  }

  exportRecipients(campaignId, { status, q, exportFormat } = {}) {
    return axios.get(`${this.url}/${campaignId}/export_recipients`, {
      params: {
        status,
        q,
        export_format: exportFormat,
      },
      responseType: exportFormat === 'xlsx' ? 'blob' : 'text',
    });
  }
}

export default new CampaignsAPI();
