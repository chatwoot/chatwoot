/* global axios */

import ApiClient from './ApiClient';

class WhatsAppInteractivePresets extends ApiClient {
  constructor() {
    super('whatsapp_interactive_presets', { accountScoped: true });
  }

  get({ search = '' } = {}) {
    const query = search.trim();
    const url = query
      ? `${this.url}?search=${encodeURIComponent(query)}`
      : this.url;
    return axios.get(url);
  }
}

export default new WhatsAppInteractivePresets();
