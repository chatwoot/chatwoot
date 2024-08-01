/* global axios */
// import ApiClient from './ApiClient';
import CacheEnabledApiClient from './CacheEnabledApiClient';

export class TicketsAPI extends CacheEnabledApiClient {
  constructor() {
    super('tickets', { accountScoped: true });
  }

  // eslint-disable-next-line class-methods-use-this
  get cacheModelName() {
    return 'tickets';
  }

  create(params) {
    return axios.post(`${this.url}`, params);
  }

  getConversationTickets(conversationId) {
    return axios.get(`${this.url}/conversations/${conversationId}`);
  }
}

export default new TicketsAPI();
