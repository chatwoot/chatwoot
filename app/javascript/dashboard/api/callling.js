import axios from 'axios';
import ApiClient from './ApiClient';

class CallingAPI extends ApiClient {
  // eslint-disable-next-line class-methods-use-this
  startCall({ to, from, accountId, conversationId, inboxId, accessToken }) {
    const url = `/api/v1/accounts/${accountId}/conversations/${conversationId}/call`;
    return axios.post(
      url,
      {
        to,
        from,
        statusCallback: `${window.location.origin}/webhooks/call/${accountId}/${inboxId}/${conversationId}`,
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
