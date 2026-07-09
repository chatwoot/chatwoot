/* global axios */
import ApiClient from './ApiClient';

// Read-only ledger of CTWA conversions sent to Meta, consumed by the CRM Lista
// column, the card drawer badge and the dashboard sync-health block.
// GET crm/meta_conversions?card_ids[]=… → { payload: [{ card_id, status, event_type, ... }] }
// GET crm/meta_conversions/summary        → { payload: { by_status, by_event_type, ... } }
class MetaConversionsAPI extends ApiClient {
  constructor() {
    super('crm/meta_conversions', { accountScoped: true });
  }

  getForCards(cardIds = []) {
    return axios.get(this.url, { params: { card_ids: cardIds } });
  }

  getSummary(params = {}) {
    return axios.get(`${this.url}/summary`, { params });
  }
}

export default new MetaConversionsAPI();
