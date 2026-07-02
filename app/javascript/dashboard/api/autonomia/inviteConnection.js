/* global axios */
import ApiClient from '../ApiClient';

class AutonomiaInviteConnectionAPI extends ApiClient {
  constructor() {
    super('autonomia/invite_connection', { accountScoped: true });
  }

  show() {
    return axios.get(this.url);
  }

  connection(inboxId) {
    return axios.get(`${this.url}/${inboxId}/connection`);
  }

  reconnect(inboxId) {
    return axios.post(`${this.url}/${inboxId}/reconnect`);
  }
}

export default new AutonomiaInviteConnectionAPI();
