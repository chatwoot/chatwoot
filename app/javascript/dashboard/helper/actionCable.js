import AuthAPI from '../api/auth';
import BaseActionCableConnector from '../../shared/helpers/BaseActionCableConnector';
import DashboardAudioNotificationHelper from './AudioAlerts/DashboardAudioNotificationHelper';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { emitter } from 'shared/helpers/mitt';
import { useImpersonation } from 'dashboard/composables/useImpersonation';
import { useCallsStore } from 'dashboard/stores/calls';
import {
  applyOutboundAnswer,
  armOutboundRecorder,
  handleWhatsappRemoteEnd,
  isLocalWhatsappCall,
} from 'dashboard/composables/useWhatsappCallSession';
import { VOICE_CALL_PROVIDERS } from 'dashboard/helper/inbox';
import { VOICE_CALL_DIRECTION } from 'dashboard/components-next/message/constants';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';

const { isImpersonating } = useImpersonation();
const UNREAD_COUNTS_REFETCH_THROTTLE_MS = 5000;

class ActionCableConnector extends BaseActionCableConnector {
  constructor(app, pubsubToken) {
    const { websocketURL = '' } = window.chatwootConfig || {};
    super(app, pubsubToken, websocketURL);
    this.CancelTyping = [];
    this.lastUnreadCountsFetchAt = null;
    this.unreadCountsFetchTimer = null;
    this.events = {
      'message.created': this.onMessageCreated,
      'message.updated': this.onMessageUpdated,
      'conversation.created': this.onConversationCreated,
      'conversation.status_changed': this.onStatusChange,
      'user:logout': this.onLogout,
      'page:reload': this.onReload,
      'assignee.changed': this.onAssigneeChanged,
      'conversation.typing_on': this.onTypingOn,
      'conversation.typing_off': this.onTypingOff,
      'conversation.contact_changed': this.onConversationContactChange,
      'presence.update': this.onPresenceUpdate,
      'contact.deleted': this.onContactDelete,
      'contact.updated': this.onContactUpdate,
      'conversation.mentioned': this.onConversationMentioned,
      'notification.created': this.onNotificationCreated,
      'notification.deleted': this.onNotificationDeleted,
      'notification.updated': this.onNotificationUpdated,
      'conversation.read': this.onConversationRead,
      'conversation.updated': this.onConversationUpdated,
      'conversation.unread_count_changed':
        this.onConversationUnreadCountChanged,
      'account.cache_invalidated': this.onCacheInvalidate,
      'account.enrichment_completed': this.onEnrichmentCompleted,
      'copilot.message.created': this.onCopilotMessageCreated,
      'voice_call.incoming': this.onVoiceCallIncoming,
      'voice_call.outbound_connected': this.onVoiceCallOutboundConnected,
      'voice_call.outbound_accepted': this.onVoiceCallOutboundAccepted,
      'voice_call.ended': this.onVoiceCallEnded,
    };
  }

  // eslint-disable-next-line class-methods-use-this
  onReconnect = () => {
    emitter.emit(BUS_EVENTS.WEBSOCKET_RECONNECT);
  };

  // eslint-disable-next-line class-methods-use-this
  onDisconnected = () => {
    emitter.emit(BUS_EVENTS.WEBSOCKET_DISCONNECT);
  };

  isAValidEvent = data => {
    return this.app.$store.getters.getCurrentAccountId === data.account_id;
  };

  onMessageUpdated = data => {
    this.app.$store.dispatch('updateMessage', data);
  };

  onPresenceUpdate = data => {
    if (isImpersonating.value) return;
    this.app.$store.dispatch('contacts/updatePresence', data.contacts);
    this.app.$store.dispatch('agents/updatePresence', data.users);
    this.app.$store.dispatch('setCurrentUserAvailability', data.users);
  };

  onConversationContactChange = payload => {
    const { meta = {}, id: conversationId } = payload;
    const { sender } = meta || {};
    if (conversationId) {
      this.app.$store.dispatch('updateConversationContact', {
        conversationId,
        ...sender,
      });
    }
  };

  onAssigneeChanged = payload => {
    const { id } = payload;
    if (id) {
      this.app.$store.dispatch('updateConversation', payload);
    }
    this.fetchConversationStats();
  };

  onConversationCreated = data => {
    this.app.$store.dispatch('addConversation', data);
    this.fetchConversationStats();
  };

  onConversationRead = data => {
    this.app.$store.dispatch('updateConversation', data);
  };

  // eslint-disable-next-line class-methods-use-this
  onLogout = () => AuthAPI.logout();

  onMessageCreated = data => {
    const {
      conversation: { last_activity_at: lastActivityAt },
      conversation_id: conversationId,
    } = data;
    DashboardAudioNotificationHelper.onNewMessage(data);
    this.app.$store.dispatch('addMessage', data);
    this.app.$store.dispatch('updateConversationLastActivity', {
      lastActivityAt,
      conversationId,
    });
  };

  // eslint-disable-next-line class-methods-use-this
  onReload = () => window.location.reload();

  onStatusChange = data => {
    this.app.$store.dispatch('updateConversation', data);
    this.fetchConversationStats();
  };

  onConversationUpdated = data => {
    this.app.$store.dispatch('updateConversation', data);
    this.fetchConversationStats();
  };

  onConversationUnreadCountChanged = () => {
    this.throttledFetchConversationUnreadCounts();
  };

  throttledFetchConversationUnreadCounts = () => {
    const now = Date.now();
    const elapsedTime = now - this.lastUnreadCountsFetchAt;

    if (
      this.lastUnreadCountsFetchAt === null ||
      elapsedTime >= UNREAD_COUNTS_REFETCH_THROTTLE_MS
    ) {
      this.clearUnreadCountsFetchTimer();
      this.fetchConversationUnreadCounts();
      return;
    }

    if (this.unreadCountsFetchTimer) return;

    this.unreadCountsFetchTimer = setTimeout(() => {
      this.unreadCountsFetchTimer = null;
      this.fetchConversationUnreadCounts();
    }, UNREAD_COUNTS_REFETCH_THROTTLE_MS - elapsedTime);
  };

  clearUnreadCountsFetchTimer = () => {
    if (!this.unreadCountsFetchTimer) return;

    clearTimeout(this.unreadCountsFetchTimer);
    this.unreadCountsFetchTimer = null;
  };

  fetchConversationUnreadCounts = () => {
    if (!this.isConversationUnreadCountsEnabled()) return;

    this.lastUnreadCountsFetchAt = Date.now();
    this.app.$store.dispatch('conversationUnreadCounts/get');
  };

  isConversationUnreadCountsEnabled = () => {
    const accountId = this.app.$store.getters.getCurrentAccountId;
    const isFeatureEnabled =
      this.app.$store.getters['accounts/isFeatureEnabledonAccount'];

    return isFeatureEnabled?.(
      accountId,
      FEATURE_FLAGS.CONVERSATION_UNREAD_COUNTS
    );
  };

  onTypingOn = ({ conversation, user }) => {
    const conversationId = conversation.id;

    this.clearTimer(conversationId);
    this.app.$store.dispatch('conversationTypingStatus/create', {
      conversationId,
      user,
    });
    this.initTimer({ conversation, user });
  };

  onTypingOff = ({ conversation, user }) => {
    const conversationId = conversation.id;

    this.clearTimer(conversationId);
    this.app.$store.dispatch('conversationTypingStatus/destroy', {
      conversationId,
      user,
    });
  };

  onConversationMentioned = data => {
    this.app.$store.dispatch('addMentions', data);
  };

  clearTimer = conversationId => {
    const timerEvent = this.CancelTyping[conversationId];

    if (timerEvent) {
      clearTimeout(timerEvent);
      this.CancelTyping[conversationId] = null;
    }
  };

  initTimer = ({ conversation, user }) => {
    const conversationId = conversation.id;
    // Turn off typing automatically after 30 seconds
    this.CancelTyping[conversationId] = setTimeout(() => {
      this.onTypingOff({ conversation, user });
    }, 30000);
  };

  // eslint-disable-next-line class-methods-use-this
  fetchConversationStats = () => {
    emitter.emit('fetch_conversation_stats');
  };

  onContactDelete = data => {
    this.app.$store.dispatch(
      'contacts/deleteContactThroughConversations',
      data.id
    );
    this.fetchConversationStats();
  };

  onContactUpdate = data => {
    this.app.$store.dispatch('contacts/updateContact', data);
  };

  onNotificationCreated = data => {
    this.app.$store.dispatch('notifications/addNotification', data);
  };

  onNotificationDeleted = data => {
    this.app.$store.dispatch('notifications/deleteNotification', data);
  };

  onNotificationUpdated = data => {
    this.app.$store.dispatch('notifications/updateNotification', data);
  };

  onCopilotMessageCreated = data => {
    this.app.$store.dispatch('copilotMessages/upsert', data);
  };

  onEnrichmentCompleted = () => {
    this.app.$store.dispatch('accounts/get', { silent: true });
  };

  onCacheInvalidate = data => {
    const keys = data.cache_keys;
    this.app.$store.dispatch('labels/revalidate', { newKey: keys.label });
    this.app.$store.dispatch('inboxes/revalidate', { newKey: keys.inbox });
    this.app.$store.dispatch('teams/revalidate', { newKey: keys.team });
  };

  onVoiceCallIncoming = data => {
    if (data?.provider !== VOICE_CALL_PROVIDERS.WHATSAPP) return;
    // Defense in depth: the server already filters to online agent streams,
    // but if anything ever broadcasts to a broader stream (e.g. account-wide),
    // an agent who's set availability=offline/busy shouldn't ring.
    const availability = this.app.$store.getters.getCurrentUserAvailability;
    if (availability !== 'online') return;

    useCallsStore().addCall({
      callSid: data.call_id,
      callId: data.id,
      conversationId: data.conversation_id,
      inboxId: data.inbox_id,
      callDirection: VOICE_CALL_DIRECTION.INBOUND,
      provider: VOICE_CALL_PROVIDERS.WHATSAPP,
      sdpOffer: data.sdp_offer,
      iceServers: data.ice_servers,
      caller: data.caller,
    });
  };

  // `connect` is the WebRTC tunnel-ready signal (fires ~20s before pickup
  // for outbound). Apply the SDP answer so the handshake completes during
  // ringing, but stay non-active until `outbound_accepted` arrives.
  // eslint-disable-next-line class-methods-use-this
  onVoiceCallOutboundConnected = async data => {
    if (data?.provider !== VOICE_CALL_PROVIDERS.WHATSAPP || !data.sdp_answer)
      return;
    // Account-wide broadcast that can arrive before /initiate sets this tab's
    // call id. applyOutboundAnswer filters foreign calls and buffers the answer
    // until the id is known, so we must not drop it here on a null activeCallId.
    try {
      await applyOutboundAnswer(data.id, data.sdp_answer);
    } catch (_) {
      /* noop */
    }
  };

  // Real pickup signal — Meta sends status=ACCEPTED on the call when the
  // contact answers. Flip active (timer starts) and arm the recorder.
  // eslint-disable-next-line class-methods-use-this
  onVoiceCallOutboundAccepted = data => {
    if (data?.provider !== VOICE_CALL_PROVIDERS.WHATSAPP) return;
    const store = useCallsStore();
    if (!store.calls.some(c => c.callSid === data.call_id)) return;
    store.setCallActive(data.call_id);
    armOutboundRecorder();
  };

  // eslint-disable-next-line class-methods-use-this
  onVoiceCallEnded = async data => {
    if (data?.provider !== VOICE_CALL_PROVIDERS.WHATSAPP) return;
    // The store entry should always be removed for this account-wide broadcast,
    // but the WebRTC/recorder teardown must only run for the call this tab owns
    // — otherwise an unrelated agent's call ending would stop this tab's
    // recorder and upload its chunks against the wrong call id.
    if (isLocalWhatsappCall(data.id)) {
      // Await upload before removeCall — the store's sync teardown would otherwise
      // wipe the recorder chunks before they reach the server.
      try {
        await handleWhatsappRemoteEnd(data.id);
      } catch (_) {
        /* noop */
      }
    }
    useCallsStore().removeCall(data.call_id);
  };
}

export default {
  init(store, pubsubToken) {
    return new ActionCableConnector({ $store: store }, pubsubToken);
  },
};
