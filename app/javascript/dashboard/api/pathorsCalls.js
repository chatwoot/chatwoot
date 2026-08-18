/* global axios */
import ApiClient from './ApiClient';

class PathorsCallsAPI extends ApiClient {
  constructor() {
    super('pathors/calls', { accountScoped: true });
  }

  // The relay hands back a LiveKit token for the room the Pathors voice agent
  // is already in. `accountId` is optional — ApiClient derives it from the
  // route, but callers that already hold it can pass it explicitly.
  join(callId, accountId) {
    const url = accountId
      ? `/api/v1/accounts/${accountId}/pathors/calls/${callId}/join`
      : `${this.url}/${callId}/join`;

    return axios.post(url).then(r => r.data);
  }
}

export default new PathorsCallsAPI();
