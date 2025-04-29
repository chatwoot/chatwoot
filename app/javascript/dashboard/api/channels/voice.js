/* global axios */
import ApiClient from '../ApiClient';

class VoiceAPI extends ApiClient {
  constructor() {
    // Use 'voice' as the resource with accountScoped: true
    super('voice', { accountScoped: true });
  }

  // Initiate a call to a contact
  initiateCall(contactId) {
    if (!contactId) {
      throw new Error('Contact ID is required to initiate a call');
    }

    // Based on the route definition, the correct URL path is /api/v1/accounts/{accountId}/contacts/{contactId}/call
    // The endpoint is defined in the contacts namespace, not voice namespace
    return axios.post(`${this.baseUrl().replace('/voice', '')}/contacts/${contactId}/call`);
  }

  // End an active call
  endCall(callSid, conversationId) {
    if (!conversationId) {
      throw new Error('Conversation ID is required to end a call');
    }

    if (!callSid) {
      throw new Error('Call SID is required to end a call');
    }

    // Validate call SID format - Twilio call SID starts with 'CA' or 'TJ'
    if (!callSid.startsWith('CA') && !callSid.startsWith('TJ')) {
      throw new Error(
        'Invalid call SID format. Expected Twilio call SID starting with CA or TJ.'
      );
    }

    return axios.post(`${this.url}/end_call`, {
      call_sid: callSid,
      conversation_id: conversationId,
      id: conversationId,
    });
  }

  // Get call status
  getCallStatus(callSid) {
    if (!callSid) {
      throw new Error('Call SID is required to get call status');
    }

    return axios.get(`${this.url}/call_status`, {
      params: { call_sid: callSid },
    });
  }

  // Join an incoming call as an agent (join the conference)
  joinCall(callSid, conversationId) {
    if (!conversationId) {
      throw new Error('Conversation ID is required to join a call');
    }

    if (!callSid) {
      throw new Error('Call SID is required to join a call');
    }

    return axios.post(`${this.url}/join_call`, {
      call_sid: callSid,
      conversation_id: conversationId,
    });
  }

  // Reject an incoming call as an agent (don't join the conference)
  rejectCall(callSid, conversationId) {
    if (!conversationId) {
      throw new Error('Conversation ID is required to reject a call');
    }

    if (!callSid) {
      throw new Error('Call SID is required to reject a call');
    }

    return axios.post(`${this.url}/reject_call`, {
      call_sid: callSid,
      conversation_id: conversationId,
    });
  }
}

export default new VoiceAPI();
