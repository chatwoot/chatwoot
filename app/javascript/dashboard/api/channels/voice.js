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

  // End an active call
  endCall(callSid, conversationId) {
    if (!conversationId) {
      console.error('VoiceAPI: Cannot end call - conversation ID is required');
      return Promise.reject(
        new Error('Conversation ID is required to end a call')
      );
    }

    if (!callSid) {
      console.error('VoiceAPI: Cannot end call - call SID is required');
      return Promise.reject(new Error('Call SID is required to end a call'));
    }

    // Validate call SID format - Twilio call SID starts with 'CA' followed by alphanumeric characters
    if (!callSid.startsWith('CA') && !callSid.startsWith('TJ')) {
      console.error('VoiceAPI: Invalid call SID format:', callSid);
      return Promise.reject(
        new Error(
          'Invalid call SID format. Expected Twilio call SID starting with CA or TJ.'
        )
      );
    }

    // Get the account ID from the current URL
    const accountId = this.accountIdFromRoute;
    console.log(
      `VoiceAPI: Ending call with SID ${callSid} for conversation ${conversationId} in account ${accountId}`
    );

    // Make the actual API call with conversation ID as a parameter
    // Using the route structure that matches the Rails routes.rb definition
    return axios
      .post(`/api/v1/accounts/${accountId}/voice/end_call`, {
        call_sid: callSid,
        conversation_id: conversationId,
        id: conversationId, // Also include as 'id' as the controller may check for it
      })
      .then(response => {
        console.log('VoiceAPI: End call API succeeded:', response);
        return response;
      })
      .catch(error => {
        console.error('VoiceAPI: End call API failed:', error);
        throw error;
      });
  }

  // Get call status
  getCallStatus(callSid) {
    // Get the account ID from the current URL
    const accountId = this.accountIdFromRoute;
    return axios.get(`/api/v1/accounts/${accountId}/voice/call_status`, {
      params: { call_sid: callSid },
    });
  }
}

export default new VoiceAPI();
