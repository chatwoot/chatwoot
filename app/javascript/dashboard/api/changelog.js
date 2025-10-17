import axios from 'axios';
import ApiClient from './ApiClient';

class ChangelogApi extends ApiClient {
  constructor() {
    super('changelog', { apiVersion: 'v1' });
  }

  // eslint-disable-next-line class-methods-use-this
  fetchFromHub() {
    return axios.get('https://hub.2.chatwoot.com/changelogs');
  }
}

export default new ChangelogApi();
