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
    this.lastInboxId = null;
  }

  // ------------------- Server APIs -------------------
  static initiateCall(contactId, inboxId) {
    return ContactsAPI.initiateCall(contactId, inboxId).then(r => r.data);
  }

  leaveConference(inboxId, conversationId) {
    return axios
      .delete(`${this.baseUrl()}/inboxes/${inboxId}/conference`, {
        params: { conversation_id: conversationId },
      })
      .then(r => r.data);
  }

  joinConference({ conversationId, inboxId, callSid }) {
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
      .get(`${this.baseUrl()}/inboxes/${inboxId}/conference/token`)
      .then(r => r.data);
  }

  // ------------------- Client (Twilio) APIs -------------------
  async initializeDevice(inboxId, { store } = {}) {
    if (store) this.store = store;

    const canReuse =
      this.initialized && this.device && this.lastInboxId === inboxId;
    if (canReuse) return this.device;

    this.destroyDevice();

    const { Device } = await import('@twilio/voice-sdk');
    const response = await this.getToken(inboxId);
    const { token, account_id } = response || {};
    if (!token) throw new Error('Invalid token');

    this.device = new Device(token, {
      allowIncomingWhileBusy: true,
      disableAudioContextSounds: true,
      appParams: { account_id },
    });

    this.device.removeAllListeners();
    this.device.on('connect', conn => {
      this.activeConnection = conn;
      conn.on('disconnect', () => {
        this.activeConnection = null;
        this.store?.dispatch('calls/clearActiveCall');
      });
    });
    this.device.on('disconnect', () => {
      this.activeConnection = null;
    });
    this.device.on('tokenWillExpire', async () => {
      const r = await this.getToken(this.lastInboxId);
      if (r?.token) this.device.updateToken(r.token);
    });

    await this.device.register();
    this.initialized = true;
    this.lastInboxId = inboxId;
    return this.device;
  }

  endClientCall() {
    if (this.activeConnection?.disconnect) {
      this.activeConnection.disconnect();
    }
    this.activeConnection = null;
    this.device?.disconnectAll?.();
  }

  destroyDevice() {
    this.device?.destroy?.();
    this.activeConnection = null;
    this.device = null;
    this.initialized = false;
    this.lastInboxId = null;
  }

  async joinClientCall({ To, conversationId }) {
    if (!this.device || !this.initialized || !To) return null;
    if (this.activeConnection) return this.activeConnection;

    const params = { To: String(To), is_agent: 'true' };
    if (conversationId) params.conversation_id = String(conversationId);

    const connection = await this.device.connect({ params });
    this.activeConnection = connection;

    connection?.on?.('disconnect', () => {
      this.activeConnection = null;
    });

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
