import AuthAPI from '../api/auth';
import VoiceAPI from 'dashboard/api/channels/voice';
import BaseActionCableConnector from '../../shared/helpers/BaseActionCableConnector';
import DashboardAudioNotificationHelper from './AudioAlerts/DashboardAudioNotificationHelper';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { emitter } from 'shared/helpers/mitt';
import { useImpersonation } from 'dashboard/composables/useImpersonation';

const { isImpersonating } = useImpersonation();

class ActionCableConnector extends BaseActionCableConnector {
  constructor(app, pubsubToken) {
    const { websocketURL = '' } = window.chatwootConfig || {};
    super(app, pubsubToken, websocketURL);
    this.CancelTyping = [];
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
      'account.cache_invalidated': this.onCacheInvalidate,
      'copilot.message.created': this.onCopilotMessageCreated,
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

    // Sync call status when voice_call message gets updated
    try {
      const isVoiceCallMessage =
        data?.content_type === 12 || data?.content_type === 'voice_call';
      const status = data?.content_attributes?.data?.status;
      const callSid = data?.content_attributes?.data?.call_sid;
      const conversationId = data?.conversation_id;
      const inboxId = data?.inbox_id;

      if (isVoiceCallMessage && callSid && status) {
        this.app.$store.dispatch('calls/handleCallStatusChanged', {
          callSid,
          status,
        });
        // Reflect it on conversation list item state
        try {
          this.app.$store.commit('UPDATE_CONVERSATION_CALL_STATUS', {
            conversationId,
            callStatus: status,
          });
        } catch (_) {
          // ignore commit errors
        }

        // Backfill incoming call payload only when ringing and no active/incoming
        const hasIncoming = this.app.$store.getters['calls/hasIncomingCall'];
        const hasActive = this.app.$store.getters['calls/hasActiveCall'];
        if (status === 'ringing' && !hasIncoming && !hasActive) {
          const conv = this.app.$store.getters[
            'conversations/getConversationById'
          ]?.(conversationId);
          const inboxFromStore = this.app.$store.getters['inboxes/getInbox']?.(
            conv?.inbox_id || inboxId
          );
          const payload = ActionCableConnector.buildIncomingCallPayload(
            {
              ...data,
              display_id: conversationId,
              inbox_id: conv?.inbox_id || inboxId,
              account_id: conv?.account_id || data?.account_id,
              meta: {
                inbox: conv?.meta?.inbox || {
                  name: inboxFromStore?.name,
                  avatar_url: inboxFromStore?.avatar_url,
                  phone_number: inboxFromStore?.phone_number,
                },
                sender: conv?.meta?.sender,
              },
            },
            inboxFromStore
          );
          this.app.$store.dispatch('calls/setIncomingCall', payload);
        }
      }
    } catch (_) {
      // ignore voice call sync errors
    }
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
  onLogout = () => {
    try {
      VoiceAPI.endClientCall();
      VoiceAPI.destroyDevice();
    } catch (_) {}
    AuthAPI.logout();
  };

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

    // Voice call messages bootstrap call state across clients
    try {
      const isVoiceCallMessage =
        data?.content_type === 12 || data?.content_type === 'voice_call';
      if (isVoiceCallMessage) {
        const status = data?.content_attributes?.data?.status;
        const callSid = data?.content_attributes?.data?.call_sid;
        if (callSid) {
          // Compose payload using conversation details from store
          const conv = this.app.$store.getters[
            'conversations/getConversationById'
          ]?.(conversationId);
          const inboxFromStore = this.app.$store.getters['inboxes/getInbox']?.(
            conv?.inbox_id || data?.inbox_id
          );
          const payload = ActionCableConnector.buildIncomingCallPayload(
            {
              ...data,
              display_id: conversationId,
              inbox_id: conv?.inbox_id || data?.inbox_id,
              account_id: conv?.account_id || data?.account_id,
              meta: {
                inbox: conv?.meta?.inbox || {
                  name: inboxFromStore?.name,
                  avatar_url: inboxFromStore?.avatar_url,
                  phone_number: inboxFromStore?.phone_number,
                },
                sender: conv?.meta?.sender,
              },
            },
            inboxFromStore
          );

          this.app.$store.dispatch('calls/setIncomingCall', payload);

          if (status) {
            this.app.$store.dispatch('calls/handleCallStatusChanged', {
              callSid,
              status,
            });
          }
        }
      }
    } catch (_) {
      // non-fatal; ignore voice bootstrap errors
    }
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

  // ----------------- Helpers (DRY) -----------------
  // Identify voice channel events across payload variants
  static isVoiceChannel(data) {
    return (
      data?.meta?.inbox?.channel_type === 'Channel::Voice' ||
      data?.channel === 'Channel::Voice'
    );
  }

  // Normalize an incoming call payload for Vuex calls module
  static buildIncomingCallPayload(data, inboxFromStore) {
    return {
      callSid: data.content_attributes?.data?.call_sid,
      conversationId: data.display_id || data.id,
      inboxId: data.inbox_id,
      inboxName: data.meta?.inbox?.name || inboxFromStore?.name,
      inboxAvatarUrl: data.meta?.inbox?.avatar_url || inboxFromStore?.avatar_url,
      inboxPhoneNumber:
        data.meta?.inbox?.phone_number || inboxFromStore?.phone_number,
      contactName: data.meta?.sender?.name || 'Unknown Caller',
      contactId: data.meta?.sender?.id,
      accountId: data.account_id,
      isOutbound: data.content_attributes?.data?.call_direction === 'outbound',
      callDirection: data.content_attributes?.data?.call_direction,
      phoneNumber: data.meta?.sender?.phone_number,
      avatarUrl: data.meta?.sender?.avatar_url,
    };
  }

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

  onCacheInvalidate = data => {
    const keys = data.cache_keys;
    this.app.$store.dispatch('labels/revalidate', { newKey: keys.label });
    this.app.$store.dispatch('inboxes/revalidate', { newKey: keys.inbox });
    this.app.$store.dispatch('teams/revalidate', { newKey: keys.team });
  };
}

export default {
  init(store, pubsubToken) {
    return new ActionCableConnector({ $store: store }, pubsubToken);
  },
};
