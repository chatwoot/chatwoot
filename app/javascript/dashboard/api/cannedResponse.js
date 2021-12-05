/* global axios */

import ApiClient from './ApiClient';

class CannedResponse extends ApiClient {
  constructor() {
    super('canned_responses', { accountScoped: true });
  }

  get({ searchKey, chatId }) {
    const queryParams = [];
    if (searchKey) {
      queryParams.push(`search=${searchKey}`);
    }
    if (chatId) {
      queryParams.push(`conversation_id=${chatId}`);
    }
    const url = `${this.url}?${queryParams.join('&')}`;
    return axios.get(url);
  }
}

export default new CannedResponse();
