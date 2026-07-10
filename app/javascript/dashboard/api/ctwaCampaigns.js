/* global axios */

import ApiClient from './ApiClient';

// Opções de campanha CTWA (anúncios de clique-para-WhatsApp que geraram
// conversas na conta). Endpoint único, fora do gate CRM — consumido tanto pelo
// filtro de Campanha do Kanban quanto pelo picker do filtro de Conversas.
// GET /api/v1/accounts/:account_id/ctwa_campaigns →
//   { payload: [{ source_id, source, headline, count, last_touch_at }] } (count desc)
class CtwaCampaignsAPI extends ApiClient {
  constructor() {
    super('ctwa_campaigns', { accountScoped: true });
  }

  get(params = {}) {
    return axios.get(this.url, { params });
  }
}

export default new CtwaCampaignsAPI();
