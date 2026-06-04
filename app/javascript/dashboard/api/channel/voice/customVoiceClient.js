import {
  UserAgent,
  Registerer,
  Inviter,
  SessionState,
} from 'sip.js';
import VoiceAPI from './voiceAPIClient';

const createCallDisconnectedEvent = detail =>
  new CustomEvent('call:disconnected', { detail });
const createIncomingCallEvent = detail =>
  new CustomEvent('call:incoming', { detail });
const createAudioBlockedEvent = detail =>
  new CustomEvent('call:audio_blocked', { detail });
const createCallInviteFailedEvent = detail =>
  new CustomEvent('call:invite_failed', { detail });

const AUDIO_PERMISSION_KEY = 'cw_voice_audio_playback_allowed';

const getStoredAudioPermission = () => {
  try {
    return localStorage.getItem(AUDIO_PERMISSION_KEY) === 'true';
  } catch {
    return false;
  }
};

const storeAudioPermission = () => {
  try {
    localStorage.setItem(AUDIO_PERMISSION_KEY, 'true');
  } catch {
    // Ignore storage errors.
  }
};

class CustomVoiceClient extends EventTarget {
  constructor() {
    super();
    this.userAgent = null;
    this.registerer = null;
    this.activeSession = null;
    this.initialized = false;
    this.inboxId = null;
    this.webrtcConfig = null;
    this.token = null;
    this.authType = 'jwt';
    this.pendingInvites = new Map();
    this.remoteAudio = null;
    this.audioPlaybackRequested = false;
    this.reconnectTimer = null;
    this.reconnectAttempt = 0;
    this.isReconnecting = false;
    this.isDestroying = false;
  }

  async initializeDevice(inboxId, { force = false, reason = 'manual' } = {}) {
    if (!force && this.initialized && this.inboxId === inboxId && this.userAgent) {
      // eslint-disable-next-line no-console
      console.log('[CustomVoiceClient] reuseDevice', { inboxId });
      return this.userAgent;
    }

    this.destroyDevice();

    // eslint-disable-next-line no-console
    console.log('[CustomVoiceClient] initializeDevice', { inboxId, reason, force });
    const response = await VoiceAPI.getToken(inboxId);
    const { token, webrtc, provider, auth_type: authType, password } =
      response || {};
    if (provider !== 'custom') throw new Error('Invalid provider');
    if (!webrtc?.ws_url || !webrtc?.sip_domain) {
      throw new Error('Invalid WebRTC config');
    }

    const resolvedAuthType = authType || 'jwt';
    const credential =
      resolvedAuthType === 'password' ? password || token : token;

    if (resolvedAuthType === 'password' && !credential) {
      throw new Error('Missing WebRTC password');
    }

    if (resolvedAuthType === 'jwt' && !credential) {
      throw new Error('Invalid token');
    }

    const username = webrtc.username;
    if (!username) throw new Error('Missing WebRTC username');

    const uri = UserAgent.makeURI(`sip:${username}@${webrtc.sip_domain}`);
    if (!uri) throw new Error('Invalid SIP URI');

    const iceServers = Array.isArray(webrtc.ice_servers)
      ? webrtc.ice_servers.filter(
          entry => entry && typeof entry === 'object' && entry.urls
        )
      : [];
    const peerConnectionConfiguration = {};
    if (iceServers.length) {
      peerConnectionConfiguration.iceServers = iceServers;
    }

    this.ensureRemoteAudioElement();

    // eslint-disable-next-line no-console
    console.log('[CustomVoiceClient] createUserAgent', {
      inboxId,
      wsUrl: webrtc.ws_url,
      sipDomain: webrtc.sip_domain,
      username,
      authType: resolvedAuthType,
      hasCredential: !!credential,
      hasIceServers: !!iceServers.length,
    });
    this.userAgent = new UserAgent({
      uri,
      authorizationUsername: username,
      authorizationPassword: credential || '',
      displayName: webrtc.display_name || username,
      transportOptions: { server: webrtc.ws_url },
      sessionDescriptionHandlerFactoryOptions: {
        peerConnectionConfiguration,
        media: {
          constraints: { audio: true, video: false },
          remote: { audio: this.remoteAudio },
        },
      },
    });
    this.userAgent.delegate = {
      onInvite: invitation => {
        this.handleIncomingInvite(invitation);
      },
    };

    await this.userAgent.start();
    this.attachTransportHandlers();
    this.registerer = new Registerer(this.userAgent);
    await this.registerer.register();

    this.webrtcConfig = webrtc;
    this.token = credential;
    this.authType = resolvedAuthType;
    this.initialized = true;
    this.inboxId = inboxId;
    this.reconnectAttempt = 0;
    this.clearReconnectTimer();

    // eslint-disable-next-line no-console
    console.log('[CustomVoiceClient] registered', { inboxId, username });
    return this.userAgent;
  }

  get hasActiveConnection() {
    return !!this.activeSession;
  }

  async joinClientCall({ to, callSid, conversationId }) {
    if (!this.userAgent || !this.initialized || !to) return null;
    if (this.activeSession) return this.activeSession;

    const targetUri = this.buildTargetUri(to);
    // eslint-disable-next-line no-console
    console.log('[CustomVoiceClient] joinClientCall', {
      inboxId: this.inboxId,
      target: targetUri.toString?.() || targetUri,
    });
    const inviter = new Inviter(this.userAgent, targetUri, {
      extraHeaders: this.extraHeaders(),
    });

    this.setSessionContext(inviter, {
      callSid,
      conversationId,
      inboxId: this.inboxId,
    });
    this.activeSession = inviter;
    this.bindSession(inviter);

    inviter.invite().catch(error => {
      // eslint-disable-next-line no-console
      console.error('[CustomVoiceClient] invite failed', {
        inboxId: this.inboxId,
        callSid,
        conversationId,
        error,
      });
      if (this.activeSession === inviter) {
        this.activeSession = null;
      }
      this.dispatchEvent(
        createCallInviteFailedEvent({
          inboxId: this.inboxId,
          callSid,
          conversationId,
          error,
        })
      );
    });

    return inviter;
  }

  endClientCall() {
    // eslint-disable-next-line no-console
    console.log('[CustomVoiceClient] endClientCall', { inboxId: this.inboxId });
    if (this.activeSession) {
      const { state } = this.activeSession;
      if (state === SessionState.Established && this.activeSession.bye) {
        this.activeSession.bye();
      } else if (
        (state === SessionState.Initial || state === SessionState.Establishing) &&
        this.activeSession.cancel
      ) {
        this.activeSession.cancel();
      }
    }
    this.activeSession = null;
    if (this.registerer) {
      try {
        this.registerer.unregister();
      } catch (error) {
        // eslint-disable-next-line no-console
        console.warn('[CustomVoiceClient] unregister skipped', { error });
      }
    }
  }

  destroyDevice() {
    // eslint-disable-next-line no-console
    console.log('[CustomVoiceClient] destroyDevice', { inboxId: this.inboxId });
    this.isDestroying = true;
    this.clearReconnectTimer();
    if (this.userAgent) {
      this.userAgent.stop();
    }
    this.activeSession = null;
    this.userAgent = null;
    this.registerer = null;
    this.webrtcConfig = null;
    this.token = null;
    this.authType = 'jwt';
    this.pendingInvites.clear();
    if (this.remoteAudio) {
      this.remoteAudio.pause();
      this.remoteAudio.srcObject = null;
    }
    this.audioPlaybackRequested = false;
    this.audioPlaybackRequested = false;
    this.isReconnecting = false;
    this.reconnectAttempt = 0;
    this.initialized = false;
    this.inboxId = null;
    this.isDestroying = false;
  }

  transferCall({ referTo }) {
    if (!this.activeSession || !referTo) return false;
    if (typeof this.activeSession.refer !== 'function') return false;

    const target = this.buildReferUri(referTo);
    // eslint-disable-next-line no-console
    console.log('[CustomVoiceClient] transferCall', {
      inboxId: this.inboxId,
      referTo: target.toString?.() || target,
    });
    this.activeSession.refer(target);
    return true;
  }

  sendDtmf(digits) {
    if (!this.activeSession || !digits) return false;

    const value = digits.toString();
    // eslint-disable-next-line no-console
    console.log('[CustomVoiceClient] sendDtmf', {
      inboxId: this.inboxId,
      digits: value,
    });

    if (typeof this.activeSession.dtmf === 'function') {
      this.activeSession.dtmf(value);
      return true;
    }

    if (typeof this.activeSession.info === 'function') {
      this.activeSession.info({
        contentType: 'application/dtmf-relay',
        body: `Signal=${value}\r\nDuration=160`,
      });
      return true;
    }

    return false;
  }

  bindSession(session) {
    session.stateChange.addListener(state => {
      // eslint-disable-next-line no-console
      console.log('[CustomVoiceClient] sessionState', {
        inboxId: this.inboxId,
        state,
      });
      session.__cwLastState = state;
      if (state === SessionState.Established) {
        session.__cwWasEstablished = true;
      }
      if (state === SessionState.Terminated) {
        this.activeSession = null;
        this.handleSessionTerminated(session);
        this.dispatchEvent(
          createCallDisconnectedEvent({
            inboxId: session.__cwInboxId,
            callSid: session.__cwCallSid,
            conversationId: session.__cwConversationId,
            status: session.__cwWasEstablished ? 'completed' : 'failed',
          })
        );
      }
      if (state === SessionState.Established) {
        const handler = session.sessionDescriptionHandler;
        const peerConnection = handler?.peerConnection;
        this.handleSessionEstablished(session);
        if (peerConnection && this.remoteAudio) {
          peerConnection.getReceivers().forEach(receiver => {
            const track =
              receiver.track?.readyState === 'live' ? receiver.track : null;
            if (track && track.kind === 'audio') {
              this.remoteAudio.srcObject = new MediaStream([track]);
              this.requestRemoteAudioPlayback('remote-track-established').catch(
                () => {}
              );
              // eslint-disable-next-line no-console
              console.log('[CustomVoiceClient] remoteStream attached', {
                inboxId: this.inboxId,
                hasStream: true,
                tracks: [{ kind: track.kind, id: track.id }],
                source: 'receiver',
              });
            }
          });
        }
        this.requestRemoteAudioPlayback('established').catch(() => {});
      }
    });
    this.attachRemoteStream(session);
  }

  async handleSessionEstablished(session) {
    if (session.__cwInProgressReported) return;
    const callSid = session.__cwCallSid;
    const conversationId = session.__cwConversationId;
    const inboxId = session.__cwInboxId || this.inboxId;
    if (!callSid || !conversationId || !inboxId) return;

    session.__cwInProgressReported = true;
    try {
      await VoiceAPI.updateCallStatus({
        conversationId,
        inboxId,
        callSid,
        callStatus: 'in-progress',
        reason: 'sip_session_established',
        timestamp: Math.floor(Date.now() / 1000),
      });
    } catch (error) {
      // eslint-disable-next-line no-console
      console.error('[CustomVoiceClient] updateCallStatus failed', {
        inboxId,
        callSid,
        conversationId,
        callStatus: 'in-progress',
        error,
      });
    }
  }

  async handleSessionTerminated(session) {
    if (session.__cwStatusReported) return;
    const callSid = session.__cwCallSid;
    const conversationId = session.__cwConversationId;
    const inboxId = session.__cwInboxId || this.inboxId;
    if (!callSid || !conversationId || !inboxId) return;

    const callStatus = session.__cwWasEstablished ? 'completed' : 'failed';
    session.__cwStatusReported = true;
    try {
      await VoiceAPI.updateCallStatus({
        conversationId,
        inboxId,
        callSid,
        callStatus,
        reason: 'sip_session_terminated',
        timestamp: Math.floor(Date.now() / 1000),
      });
    } catch (error) {
      // eslint-disable-next-line no-console
      console.error('[CustomVoiceClient] updateCallStatus failed', {
        inboxId,
        callSid,
        conversationId,
        callStatus,
        error,
      });
    }
  }

  attachRemoteStream(session) {
    const handler = session.sessionDescriptionHandler;
    if (!handler || !this.remoteAudio) return;
    const peerConnection = handler.peerConnection;
    if (!peerConnection) return;

    peerConnection.addEventListener('iceconnectionstatechange', () => {
      // eslint-disable-next-line no-console
      console.log('[CustomVoiceClient] iceConnectionState', {
        inboxId: this.inboxId,
        state: peerConnection.iceConnectionState,
      });
    });

    peerConnection.addEventListener('connectionstatechange', () => {
      // eslint-disable-next-line no-console
      console.log('[CustomVoiceClient] connectionState', {
        inboxId: this.inboxId,
        state: peerConnection.connectionState,
      });
    });

    peerConnection.addEventListener('signalingstatechange', () => {
      // eslint-disable-next-line no-console
      console.log('[CustomVoiceClient] signalingState', {
        inboxId: this.inboxId,
        state: peerConnection.signalingState,
      });
    });

    const handleStream = event => {
      const stream =
        event.streams?.[0] || (event.track ? new MediaStream([event.track]) : null);
      if (!stream) return;
      if (event.track && event.track.kind !== 'audio') return;
      this.remoteAudio.srcObject = stream;
      this.requestRemoteAudioPlayback('remote-track').catch(() => {});
      // eslint-disable-next-line no-console
      console.log('[CustomVoiceClient] remoteStream attached', {
        inboxId: this.inboxId,
        hasStream: true,
        tracks: stream.getTracks().map(t => ({ kind: t.kind, id: t.id })),
        source: 'track',
      });
    };

    peerConnection.addEventListener('track', handleStream);
  }

  ensureRemoteAudioElement() {
    if (this.remoteAudio && document.body.contains(this.remoteAudio)) {
      return this.remoteAudio;
    }

    const existing = document.getElementById('cw-voice-remote-audio');
    if (existing) {
      existing.muted = false;
      existing.volume = 1.0;
      this.remoteAudio = existing;
      return existing;
    }

    const audio = document.createElement('audio');
    audio.id = 'cw-voice-remote-audio';
    audio.autoplay = true;
    audio.playsInline = true;
    audio.muted = false;
    audio.volume = 1.0;
    audio.setAttribute('aria-hidden', 'true');
    audio.className = 'hidden';
    document.body.appendChild(audio);
    this.remoteAudio = audio;
    return audio;
  }

  async requestRemoteAudioPlayback(reason) {
    const audio = this.ensureRemoteAudioElement();
    if (!audio) return false;

    if (this.audioPlaybackRequested) {
      return true;
    }

    try {
      await audio.play();
      storeAudioPermission();
      this.audioPlaybackRequested = true;
      // eslint-disable-next-line no-console
      console.log('[CustomVoiceClient] remoteAudio play', {
        inboxId: this.inboxId,
        reason,
      });
      return true;
    } catch (error) {
      if (!getStoredAudioPermission()) {
        this.dispatchEvent(createAudioBlockedEvent({ inboxId: this.inboxId, reason }));
      }
      // eslint-disable-next-line no-console
      console.warn('[CustomVoiceClient] remoteAudio play blocked', {
        inboxId: this.inboxId,
        reason,
        error,
      });
      return false;
    }
  }

  attachTransportHandlers() {
    const transport = this.userAgent?.transport;
    if (!transport) return;

    transport.onConnect = () => {
      // eslint-disable-next-line no-console
      console.log('[CustomVoiceClient] transport connected', { inboxId: this.inboxId });
      this.clearReconnectTimer();
      if (this.registerer) {
        this.registerer.register();
      }
    };

    transport.onDisconnect = error => {
      // eslint-disable-next-line no-console
      console.warn('[CustomVoiceClient] transport disconnected', {
        inboxId: this.inboxId,
        error,
      });
      this.scheduleReconnect('transport');
    };
  }

  clearReconnectTimer() {
    if (this.reconnectTimer) {
      clearTimeout(this.reconnectTimer);
      this.reconnectTimer = null;
    }
  }

  scheduleReconnect(reason) {
    if (!this.inboxId || this.reconnectTimer || this.isDestroying) return;

    const retrySteps = [15000, 30000, 45000, 60000];
    const pauseDelay = 120000;
    let delay = pauseDelay;

    if (this.reconnectAttempt < retrySteps.length) {
      delay = retrySteps[this.reconnectAttempt];
      this.reconnectAttempt += 1;
    } else {
      this.reconnectAttempt = 0;
    }

    // eslint-disable-next-line no-console
    console.log('[CustomVoiceClient] scheduleReconnect', {
      inboxId: this.inboxId,
      delayMs: delay,
      reason,
    });
    this.reconnectTimer = setTimeout(() => {
      this.reconnectTimer = null;
      this.reconnect(reason);
    }, delay);
  }

  async reconnect(reason) {
    if (!this.inboxId || this.isReconnecting) return;
    this.isReconnecting = true;

    try {
      // eslint-disable-next-line no-console
      console.log('[CustomVoiceClient] reconnect start', {
        inboxId: this.inboxId,
        reason,
      });
      await this.initializeDevice(this.inboxId, {
        force: true,
        reason: `reconnect:${reason}`,
      });
      // eslint-disable-next-line no-console
      console.log('[CustomVoiceClient] reconnect success', {
        inboxId: this.inboxId,
      });
    } catch (error) {
      // eslint-disable-next-line no-console
      console.warn('[CustomVoiceClient] reconnect failed', {
        inboxId: this.inboxId,
        error,
      });
      this.scheduleReconnect('retry');
    } finally {
      this.isReconnecting = false;
    }
  }

  async handleIncomingInvite(invitation) {
    const request = invitation?.request;
    const callSid = request?.callId;
    const fromNumber =
      request?.from?.uri?.user ||
      request?.from?.displayName ||
      request?.from?.uri?.toString?.() ||
      request?.from?.toString?.() ||
      callSid;

    if (!callSid || !this.inboxId) {
      // eslint-disable-next-line no-console
      console.error('[CustomVoiceClient] incomingInvite invalid', {
        inboxId: this.inboxId,
        callSid,
        fromNumber,
      });
      try {
        invitation?.reject();
      } catch (error) {
        // eslint-disable-next-line no-console
        console.error('[CustomVoiceClient] incomingInvite reject error', {
          callSid,
          error,
        });
      }
      return;
    }

    if (this.pendingInvites.has(callSid)) return;

    this.pendingInvites.set(callSid, { invitation });
    invitation.stateChange.addListener(state => {
      if (state === SessionState.Terminated) {
        this.handlePendingInviteTerminated(callSid);
      }
    });

    // eslint-disable-next-line no-console
    console.log('[CustomVoiceClient] incomingInvite', {
      inboxId: this.inboxId,
      callSid,
      fromNumber,
    });

    try {
      const response = await VoiceAPI.notifyIncomingCall({
        inboxId: this.inboxId,
        callSid,
        fromNumber,
      });
      const conversationId = response?.conversation_id;
      const resolvedCallSid = response?.call_sid || callSid;

      if (resolvedCallSid !== callSid) {
        this.pendingInvites.delete(callSid);
        this.pendingInvites.set(resolvedCallSid, { invitation, conversationId });
      } else {
        this.pendingInvites.set(callSid, { invitation, conversationId });
      }
      this.setSessionContext(invitation, {
        callSid: resolvedCallSid,
        conversationId,
        inboxId: this.inboxId,
      });

      if (conversationId) {
        this.dispatchEvent(
          createIncomingCallEvent({
            callSid: resolvedCallSid,
            conversationId,
            inboxId: this.inboxId,
          })
        );
      }
    } catch (error) {
      // eslint-disable-next-line no-console
      console.error('[CustomVoiceClient] incomingInvite error', {
        inboxId: this.inboxId,
        callSid,
        error,
      });
      try {
        invitation?.reject();
      } catch (rejectError) {
        // eslint-disable-next-line no-console
        console.error('[CustomVoiceClient] incomingInvite reject error', {
          callSid,
          error: rejectError,
        });
      }
      this.pendingInvites.delete(callSid);
    }
  }

  async acceptIncomingCall({ callSid }) {
    const entry = this.pendingInvites.get(callSid);
    if (!entry) return false;

    this.pendingInvites.delete(callSid);
    this.activeSession = entry.invitation;
    this.setSessionContext(entry.invitation, {
      callSid,
      conversationId: entry.conversationId,
      inboxId: this.inboxId,
    });
    entry.invitation.__cwAccepted = true;
    this.bindSession(entry.invitation);

    try {
      await entry.invitation.accept({
        extraHeaders: this.extraHeaders(),
      });
      return true;
    } catch (error) {
      // eslint-disable-next-line no-console
      console.error('[CustomVoiceClient] acceptIncomingCall error', {
        callSid,
        error,
      });
      this.activeSession = null;
      return false;
    }
  }

  async handlePendingInviteTerminated(callSid) {
    const entry = this.pendingInvites.get(callSid);
    if (!entry) return;
    const invitation = entry.invitation;
    this.pendingInvites.delete(callSid);
    if (invitation?.__cwAccepted) return;
    if (invitation?.__cwStatusReported) return;

    const conversationId =
      invitation?.__cwConversationId || entry.conversationId;
    const inboxId = invitation?.__cwInboxId || this.inboxId;
    const resolvedCallSid = invitation?.__cwCallSid || callSid;
    if (!conversationId || !inboxId || !resolvedCallSid) return;

    invitation.__cwStatusReported = true;
    try {
      await VoiceAPI.updateCallStatus({
        conversationId,
        inboxId,
        callSid: resolvedCallSid,
        callStatus: 'no-answer',
        reason: 'incoming_invite_terminated',
        timestamp: Math.floor(Date.now() / 1000),
      });
    } catch (error) {
      // eslint-disable-next-line no-console
      console.error('[CustomVoiceClient] updateCallStatus failed', {
        inboxId,
        callSid: resolvedCallSid,
        conversationId,
        callStatus: 'no-answer',
        error,
      });
    }

    this.dispatchEvent(
      createCallDisconnectedEvent({
        inboxId,
        callSid: resolvedCallSid,
        conversationId,
        status: 'no-answer',
      })
    );
  }

  setSessionContext(session, { callSid, conversationId, inboxId }) {
    session.__cwCallSid = callSid;
    session.__cwConversationId = conversationId;
    session.__cwInboxId = inboxId;
    session.__cwWasEstablished = false;
  }

  rejectIncomingCall({ callSid }) {
    const entry = this.pendingInvites.get(callSid);
    if (!entry) return false;

    try {
      entry.invitation.reject();
    } catch (error) {
      // eslint-disable-next-line no-console
      console.error('[CustomVoiceClient] rejectIncomingCall error', {
        callSid,
        error,
      });
    }
    this.pendingInvites.delete(callSid);
    return true;
  }

  buildTargetUri(target) {
    const value = target.toString().startsWith('sip:')
      ? target.toString()
      : `sip:${target}@${this.webrtcConfig.sip_domain}`;
    const uri = UserAgent.makeURI(value);
    if (!uri) throw new Error('Invalid target');
    return uri;
  }

  buildReferUri(referTo) {
    const value = referTo.toString().startsWith('sip:')
      ? referTo.toString()
      : `sip:${referTo}@${this.webrtcConfig.sip_domain}`;
    const uri = UserAgent.makeURI(value);
    if (!uri) throw new Error('Invalid refer target');
    return uri;
  }

  extraHeaders() {
    if (this.authType !== 'jwt' || !this.token) return [];
    return [`Authorization: Bearer ${this.token}`];
  }
}

export default new CustomVoiceClient();
