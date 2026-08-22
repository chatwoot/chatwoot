/* global axios */
import ApiClient from './ApiClient';

class CampaignsAPI extends ApiClient {
  constructor() {
    super('campaigns', { accountScoped: true });
  }

  previewAudience({ inboxId, audience } = {}) {
    return axios.post(`${this.url}/preview_audience`, {
      inbox_id: inboxId,
      audience,
    });
  }

  exportRecipients(campaignId, { status, exportFormat } = {}) {
    return axios.get(`${this.url}/${campaignId}/export_recipients`, {
      params: {
        status,
        export_format: exportFormat,
      },
      responseType: exportFormat === 'xlsx' ? 'blob' : 'text',
    });
  }

  analyticsMetrics(id) {
    return axios.get(`${this.url}/${id}/analytics/metrics`);
  }

  analyticsContacts(id, { status, page } = {}) {
    return axios.get(`${this.url}/${id}/analytics/contacts`, {
      params: { status, page },
    });
  }
}

export default new CampaignsAPI();
