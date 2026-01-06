import axios from 'axios';
import ApiClient from './ApiClient';
import { CHANGELOG_API_URL } from 'shared/constants/links';

class ChangelogApi extends ApiClient {
  constructor() {
    super('changelog', { apiVersion: 'v1' });
  }

  // eslint-disable-next-line class-methods-use-this
  fetchFromHub() {
    return axios.get(CHANGELOG_API_URL);
  }
}

export default new ChangelogApi();
