import axios from 'axios';
import ApiClient from './ApiClient';

class CallingAPI extends ApiClient {
  // eslint-disable-next-line class-methods-use-this
  startCall({ to, from, accountId, contactId, accessToken }) {
    const url = `/api/v1/accounts/${accountId}/call`;
    return axios.post(
      url,
      {
        to,
        from,
        contactId,
        baseUrl: window.location.origin,
      },
      {
        headers: {
          'Content-Type': 'application/json',
          api_access_token: accessToken,
        },
      }
    );
  }
}

export default new CallingAPI();
