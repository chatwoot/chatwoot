/* global axios */
import ApiClient from '../ApiClient';
import ContactsAPI from '../contacts';

class VoiceAPI extends ApiClient {
  constructor() {
    super('voice', { accountScoped: true });
    this.device = null;
    this.activeConnection = null;
    this.initialized = false;
    this.store = null;
  }

  // ------------------- Server APIs -------------------
  initiateCall(contactId, inboxId) {
    return ContactsAPI.initiateCall(contactId, inboxId).then(r => r.data);
  }

  leaveConference(inboxId, conversationId) {
    if (!inboxId) throw new Error('Inbox ID is required to leave a conference');
    if (!conversationId)
      throw new Error('Conversation ID is required to leave a conference');
    return axios
      .delete(`${this.baseUrl()}/inboxes/${inboxId}/conference`, { params: { conversation_id: conversationId } })
      .then(r => r.data);
  }

  joinConference(params) {
    const conversationId = params.conversation_id || params.conversationId;
    const inboxId = params.inbox_id || params.inboxId;
    const callSid = params.call_sid || params.callSid;
    if (!inboxId) throw new Error('Inbox ID is required to join a call');
    if (!conversationId)
      throw new Error('Conversation ID is required to join a call');
    return axios
      .post(`${this.baseUrl()}/inboxes/${inboxId}/conference`, {
        conversation_id: conversationId,
        call_sid: callSid,
      })
      .then(r => r.data);
  }

  // Reject is handled client-side by not joining and clearing state

  getToken(inboxId) {
    if (!inboxId) return Promise.reject(new Error('Inbox ID is required'));
    return axios
      .get(`${this.baseUrl()}/inboxes/${inboxId}/conference_token`)
      .then(r => r.data);
  }

  // ------------------- Client (Twilio) APIs -------------------
  async initializeDevice(inboxId, { store } = {}) {
    if (this.initialized && this.device && this.device.state !== 'error')
      return this.device;
    if (!inboxId) throw new Error('Inbox ID is required to initialize');
    if (store) this.store = store;

    const { Device } = await import('@twilio/voice-sdk');
    const response = await this.getToken(inboxId);
    const { token, voice_enabled, account_id } = response || {};
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
        if (this.store) {
          this.store.dispatch('calls/clearActiveCall');
        }
      });
    });
    this.device.on('disconnect', () => {
      this.activeConnection = null;
    });
    this.device.on('tokenWillExpire', async () => {
      try {
        const r = await this.getToken(inboxId);
        if (r?.token) this.device.updateToken(r.token);
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
        this.device.disconnectAll();
      }
    } catch (error) {
      this.activeConnection = null;
      try {
        if (this.device) {
          this.device.disconnectAll();
        }
      } catch (fallbackError) {
        // ignore
      }
    }
  }

  destroyDevice() {
    try {
      if (this.device) {
        this.device.destroy?.();
      }
    } catch (_) {
      // ignore
    } finally {
      this.activeConnection = null;
      this.device = null;
      this.initialized = false;
    }
  }

  joinClientCall({ To, conversationId }) {
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

    const params = { To: String(To), is_agent: 'true' };
    if (conversationId) params.conversation_id = String(conversationId);
    const connection = this.device.connect({ params });
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
