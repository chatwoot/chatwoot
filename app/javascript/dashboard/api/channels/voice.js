/* global axios */
import ApiClient from '../ApiClient';

class VoiceAPI extends ApiClient {
  constructor() {
    super('voice', { accountScoped: true });
    this.device = null;
    this.activeConnection = null;
    this.initialized = false;
  }

  // ------------------- Server APIs -------------------
  initiateCall(contactId, inboxId) {
    if (!contactId)
      throw new Error('Contact ID is required to initiate a call');
    const payload = {};
    if (inboxId) payload.inbox_id = inboxId;
    // The endpoint is defined in the contacts namespace, not voice namespace
    return axios.post(
      `${this.baseUrl().replace('/voice', '')}/contacts/${contactId}/call`,
      payload
    );
  }

  endCall(callSid, conversationId) {
    if (!conversationId)
      throw new Error('Conversation ID is required to end a call');
    if (!callSid) throw new Error('Call SID is required to end a call');
    return axios.post(`${this.url}/end_call`, {
      call_sid: callSid,
      conversation_id: conversationId,
      id: conversationId,
    });
  }

  joinCall(params) {
    const conversationId = params.conversation_id || params.conversationId;
    const callSid = params.call_sid || params.callSid;
    const payload = { call_sid: callSid, conversation_id: conversationId };
    if (!conversationId)
      throw new Error('Conversation ID is required to join a call');
    if (!callSid) throw new Error('Call SID is required to join a call');
    if (params.account_id) payload.account_id = params.account_id;
    return axios.post(`${this.url}/join_call`, payload);
  }

  rejectCall(callSid, conversationId) {
    if (!conversationId)
      throw new Error('Conversation ID is required to reject a call');
    if (!callSid) throw new Error('Call SID is required to reject a call');
    return axios.post(`${this.url}/reject_call`, {
      call_sid: callSid,
      conversation_id: conversationId,
    });
  }

  getToken(inboxId) {
    if (!inboxId) return Promise.reject(new Error('Inbox ID is required'));
    return axios.post(`${this.url}/token`, { inbox_id: inboxId });
  }

  // ------------------- Client (Twilio) APIs -------------------
  async initializeDevice(inboxId) {
    if (this.initialized && this.device && this.device.state !== 'error')
      return this.device;
    if (!inboxId) throw new Error('Inbox ID is required to initialize');

    const { Device } = await import('@twilio/voice-sdk');
    const response = await this.getToken(inboxId);
    const { token, voice_enabled, account_id } = response.data || {};
    if (!voice_enabled) throw new Error('Voice not enabled for this inbox');
    if (!token) throw new Error('Invalid token');

    this.device = new Device(token, {
      allowIncomingWhileBusy: true,
      disableAudioContextSounds: true,
      appParams: { account_id },
    });

    // Basic listeners
    this.device.removeAllListeners();
    this.device.on('registered', () => {});
    this.device.on('unregistered', () => {});
    this.device.on('error', () => {});
    this.device.on('connect', conn => {
      this.activeConnection = conn;
      // Listen for connection disconnect
      conn.on('disconnect', () => {
        this.activeConnection = null;
        // Dispatch event to update UI when call disconnects
        if (window.app && window.app.$store) {
          window.app.$store.dispatch('calls/clearActiveCall');
        }
      });
    });
    this.device.on('disconnect', () => {
      this.activeConnection = null;
    });
    this.device.on('tokenWillExpire', async () => {
      try {
        const r = await this.getToken(inboxId);
        if (r.data?.token) this.device.updateToken(r.data.token);
      } catch (error) {
        // Token refresh failed
      }
    });

    await this.device.register();
    this.initialized = true;
    return this.device;
  }

  endClientCall() {
    try {
      // Disconnect active connection first
      if (this.activeConnection) {
        this.activeConnection.disconnect();
        this.activeConnection = null;
      }

      // Disconnect all connections on the device
      if (this.device) {
        if (this.device.state === 'busy') {
          this.device.disconnectAll();
        }
        // Also try to disconnect any ongoing connections
        const connections = this.device.calls || [];
        connections.forEach(call => {
          try {
            call.disconnect();
          } catch (e) {
            // Ignore individual call disconnect errors
          }
        });
      }
    } catch (error) {
      this.activeConnection = null;
      // Force device disconnect as fallback
      try {
        if (this.device) {
          this.device.disconnectAll();
        }
      } catch (fallbackError) {
        // Final fallback failed
      }
    }
  }

  joinClientCall({ To }) {
    if (!this.device || !this.initialized) throw new Error('Twilio not ready');
    if (!To) throw new Error('Missing To');

    // Guard: if there is already an active/connecting call, return it instead of creating a new one
    if (this.activeConnection) {
      return this.activeConnection;
    }
    if (this.device.state === 'busy') {
      const existing = (this.device.calls || [])[0];
      if (existing) {
        this.activeConnection = existing;
        return existing;
      }
    }

    const connection = this.device.connect({
      params: { To: String(To), is_agent: 'true' },
    });
    this.activeConnection = connection;
    return connection;
  }

  getDeviceStatus() {
    if (!this.device) return 'not_initialized';
    const s = this.device.state;
    switch (s) {
      case 'registered':
        return 'ready';
      case 'unregistered':
        return 'disconnected';
      case 'destroyed':
        return 'terminated';
      case 'busy':
        return 'busy';
      case 'error':
        return 'error';
      default:
        return s;
    }
  }
}

export default new VoiceAPI();
