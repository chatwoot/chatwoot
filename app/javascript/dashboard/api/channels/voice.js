/* global axios */
import ApiClient from '../ApiClient';

class VoiceAPI extends ApiClient {
  constructor() {
    // Use empty string for resource to avoid duplicate 'accounts' in URL
    super('', { accountScoped: true });
  }

  // Initiate a call to a contact
  initiateCall(contactId) {
    // Get the account ID from the current URL
    const accountId = this.accountIdFromRoute;
    // Make sure we have the right endpoint path
    return axios.post(
      `/api/v1/accounts/${accountId}/contacts/${contactId}/call`
    );
  }
}

export default new VoiceAPI();