/* global axios */

import ApiClient from '../ApiClient';

class DyteAPI extends ApiClient {
  constructor() {
    super('integrations', { accountScoped: true });
  }

  processEvent(type = 'rephrase', content) {
    return axios.post(`${this.url}/hooks/1/process_event`, {
      type,
      content,
    });
  }
}

export default new DyteAPI();
