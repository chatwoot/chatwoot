import { readonly, ref } from 'vue';
import { Call, Device } from '@twilio/voice-sdk';
import VoiceAPI from './voiceAPIClient';

const isConnected = ref(false);
export const isTwilioCallConnected = readonly(isConnected);

const createCallDisconnectedEvent = () => new CustomEvent('call:disconnected');

class TwilioVoiceClient extends EventTarget {
  constructor() {
    super();
    this.device = null;
    this.activeConnection = null;
    isConnected.value = false;
    this.initialized = false;
    this.inboxId = null;
  }

  async initializeDevice(inboxId) {
    this.destroyDevice();

    const response = await VoiceAPI.getToken(inboxId);
    const { token, account_id } = response || {};
    if (!token) throw new Error('Invalid token');

    this.device = new Device(token, {
      allowIncomingWhileBusy: true,
      disableAudioContextSounds: true,
      appParams: { account_id },
    });

    this.device.removeAllListeners();
    this.device.on('connect', conn => {
      this.trackConnection(conn);
    });

    this.device.on('disconnect', this.onDisconnect);

    this.device.on('tokenWillExpire', async () => {
      const r = await VoiceAPI.getToken(this.inboxId);
      if (r?.token) this.device.updateToken(r.token);
    });

    this.initialized = true;
    this.inboxId = inboxId;

    return this.device;
  }

  get hasActiveConnection() {
    return !!this.activeConnection;
  }

  setMuted(shouldMute) {
    this.activeConnection?.mute(shouldMute);
  }

  sendDigits(digit) {
    if (
      !this.activeConnection ||
      this.activeConnection.status() !== Call.State.Open
    ) {
      return false;
    }

    this.activeConnection.sendDigits(digit);
    return true;
  }

  endClientCall() {
    if (this.activeConnection) {
      this.activeConnection.disconnect();
    }
    this.activeConnection = null;
    isConnected.value = false;
    if (this.device) {
      this.device.disconnectAll();
    }
  }

  destroyDevice() {
    if (this.device) {
      this.device.destroy();
    }
    this.activeConnection = null;
    isConnected.value = false;
    this.device = null;
    this.initialized = false;
    this.inboxId = null;
  }

  async joinClientCall({ to, conversationId, callSid, attemptId }) {
    if (!this.device || !this.initialized || !to) return null;
    if (this.activeConnection) return this.activeConnection;

    const params = {
      To: to,
      is_agent: 'true',
      conversation_id: conversationId,
      call_sid: callSid,
      attempt_id: attemptId,
    };

    const connection = await this.device.connect({ params });
    this.trackConnection(connection);

    return connection;
  }

  trackConnection(connection) {
    this.activeConnection = connection;
    isConnected.value = connection.status() === Call.State.Open;
    // The SDK emits reconnected before status() changes back to open.
    ['accept', 'reconnecting', 'reconnected', 'cancel', 'reject'].forEach(
      event => {
        connection.on(event, () => {
          if (this.activeConnection !== connection) return;
          isConnected.value = event === 'accept' || event === 'reconnected';
        });
      }
    );
    connection.on('disconnect', () => {
      if (this.activeConnection === connection) this.onDisconnect();
    });
  }

  onDisconnect = () => {
    this.activeConnection = null;
    isConnected.value = false;
    this.dispatchEvent(createCallDisconnectedEvent());
  };
}

export default new TwilioVoiceClient();
