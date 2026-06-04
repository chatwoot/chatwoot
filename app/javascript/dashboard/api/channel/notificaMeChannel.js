/* global axios */
import ApiClient from '../ApiClient';

class NotificaMeChannel extends ApiClient {
  constructor() {
    super('channels/notifica_me_channel', { accountScoped: true });
  }

  get(token) {
    const headers = { ...axios.headers };
    return axios.get(`${this.url}?token=${token}`, headers);
  }
}

export default new NotificaMeChannel();
