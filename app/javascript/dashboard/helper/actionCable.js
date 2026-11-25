import AuthAPI from '../api/auth';
import BaseActionCableConnector from '../../shared/helpers/BaseActionCableConnector';
import DashboardAudioNotificationHelper from './AudioAlerts/DashboardAudioNotificationHelper';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { emitter } from 'shared/helpers/mitt';
import { useImpersonation } from 'dashboard/composables/useImpersonation';
import { pendingGroupNavigation } from 'dashboard/helper/pendingGroupNavigation';
import { useCallsStore } from 'dashboard/stores/calls';
import {
  applyOutboundAnswer,
  armOutboundRecorder,
  handleWhatsappRemoteEnd,
  isLocalWhatsappCall,
} from 'dashboard/composables/useWhatsappCallSession';
import { humanAssignee } from 'dashboard/store/modules/conversations/helpers';
import { VOICE_CALL_PROVIDERS } from 'dashboard/helper/inbox';
import { markCallDismissed, isLocalCall } from 'dashboard/helper/voice';
import { VOICE_CALL_DIRECTION } from 'dashboard/components-next/message/constants';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { getUserPermissions } from 'dashboard/helper/permissionsHelper';
import {
  CONVERSATION_PARTICIPATING_PERMISSIONS,
  CONVERSATION_UNASSIGNED_PERMISSIONS,
  MANAGE_ALL_CONVERSATION_PERMISSIONS,
} from 'dashboard/constants/permissions';

const { isImpersonating } = useImpersonation();
const UNREAD_COUNTS_REFETCH_THROTTLE_MS = 5000;
const HANDOFF_ALERT_WINDOW_MS = 2500;
const FILTERED_UNREAD_COUNTS_REFRESH_RETRY_MS = 30000;
const FILTERED_UNREAD_COUNTS_REFRESH_RETRY_JITTER_MS = 15000;
const MENTION_UNREAD_COUNTS_REFETCH_DELAY_MS =
  UNREAD_COUNTS_REFETCH_THROTTLE_MS;
// The only roles whose accessible set follows assignment. Everyone else, plain agents and administrators
// included, sees by inbox membership, so no assignment can hide a conversation and later hand it back.
const ASSIGNMENT_SCOPED_PERMISSIONS = [
  CONVERSATION_UNASSIGNED_PERMISSIONS,
  CONVERSATION_PARTICIPATING_PERMISSIONS,
];
const getFilteredUnreadCountsRefreshRetryDelay = () =>
  FILTERED_UNREAD_COUNTS_REFRESH_RETRY_MS +
  Math.random() * FILTERED_UNREAD_COUNTS_REFRESH_RETRY_JITTER_MS;

class ActionCableConnector extends BaseActionCableConnector {
  constructor(app, pubsubToken) {
    const { websocketURL = '' } = window.chatwootConfig || {};
    super(app, pubsubToken, websocketURL);
    this.CancelTyping = [];
    this.pendingHandoffAlerts = new Map();
    this.lastUnreadCountsFetchAt = null;
    this.unreadCountsFetchTimer = null;
    this.mentionUnreadCountsFetchTimer = null;
    this.mentionUnreadCountsRetryTimer = null;
    this.filteredUnreadCountsRetryTimer = null;
    this.events = {
      'monitor.updated': this.onMonitorUpdated,
      'message.created': this.onMessageCreated,
      'message.updated': this.onMessageUpdated,
      'conversation.created': this.onConversationCreated,
      'conversation.bot_handoff': this.onConversationBotHandoff,
      'conversation.status_changed': this.onStatusChange,
      'user:logout': this.onLogout,
      'page:reload': this.onReload,
      'assignee.changed': this.onAssigneeChanged,
      'conversation.typing_on': this.onTypingOn,
      'conversation.typing_off': this.onTypingOff,
      'conversation.recording': this.onRecording,
      'conversation.contact_changed': this.onConversationContactChange,
      'presence.update': this.onPresenceUpdate,
      'contact.deleted': this.onContactDelete,
      'contact.updated': this.onContactUpdate,
      'contact.group_synced': this.onContactGroupSynced,
      'conversation.mentioned': this.onConversationMentioned,
      'conversation.pinned': this.onConversationPinned,
      'conversation.unpinned': this.onConversationUnpinned,
      'notification.created': this.onNotificationCreated,
      'notification.deleted': this.onNotificationDeleted,
      'notification.updated': this.onNotificationUpdated,
      'conversation.read': this.onConversationRead,
      'conversation.updated': this.onConversationUpdated,
      'conversation.unread_count_changed':
        this.onConversationUnreadCountChanged,
      'account.cache_invalidated': this.onCacheInvalidate,
      'inbox.provider_connection_updated':
        this.onInboxProviderConnectionUpdated,
      'account.enrichment_completed': this.onEnrichmentCompleted,
      'account.billing_updated': this.onBillingUpdated,
      'feature_access.changed': this.onFeatureAccessChanged,
      'copilot.message.created': this.onCopilotMessageCreated,
      'scheduled_message.created': this.onScheduledMessageCreated,
      'scheduled_message.updated': this.onScheduledMessageUpdated,
      'scheduled_message.deleted': this.onScheduledMessageDeleted,
      'recurring_scheduled_message.created':
        this.onRecurringScheduledMessageCreated,
      'recurring_scheduled_message.updated':
        this.onRecurringScheduledMessageUpdated,
      'recurring_scheduled_message.deleted':
        this.onRecurringScheduledMessageDeleted,
      'internal_chat.channel.updated': this.onInternalChatChannelUpdated,
      'internal_chat.message.created': this.onInternalChatMessageCreated,
      'internal_chat.message.updated': this.onInternalChatMessageUpdated,
      'internal_chat.message.deleted': this.onInternalChatMessageDeleted,
      'internal_chat.typing_on': this.onInternalChatTypingOn,
      'internal_chat.typing_off': this.onInternalChatTypingOff,
      'internal_chat.reaction.created': this.onInternalChatReactionCreated,
      'internal_chat.reaction.deleted': this.onInternalChatReactionDeleted,
      'internal_chat.poll.voted': this.onInternalChatPollVoted,
      // The store upserts by ID, so an updated approval card replaces the old one.
      'copilot.message.updated': this.onCopilotMessageCreated,
      'captain.playground.response': this.onCaptainPlaygroundResponse,
      'voice_call.incoming': this.onVoiceCallIncoming,
      'voice_call.accepted': this.onVoiceCallAccepted,
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
  onMonitorUpdated = data => {
    emitter.emit(BUS_EVENTS.MONITOR_UPDATED, data);
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
    this.app.$store.dispatch(
      'setCurrentUserWorkPreferences',
      data.work_preferences
    );
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
    if (this.assignmentMayHaveGrantedAccess(payload)) {
      this.app.$store.dispatch('conversationPins/fetch');
    }
    this.fetchConversationStats();
  };

  // A custom role can scope what an agent sees down to the conversations assigned to them or left
  // unassigned, so an assignment can hand back a conversation that was invisible when the pins were last
  // read. The server then leads the list with a pin the client no longer knows about, and the client
  // re-sorts it away as unpinned until the next reconnect. Being added as a participant grants access the
  // same way but emits no event, so that path still waits for one.
  assignmentMayHaveGrantedAccess = payload => {
    const user = this.app.$store.getters.getCurrentUser;
    const accountId = this.app.$store.getters.getCurrentAccountId;
    const permissions = getUserPermissions(user, accountId);

    // This event reaches every member of the inbox, and auto assignment fires it constantly, so it is only
    // worth a request for the roles that can lose a conversation to an assignment in the first place.
    // Manage-all is checked first because holding it says nothing on its own: the role editor adds both
    // scoped permissions alongside it, and the backend reads it with precedence over them, so such a role
    // sees by inbox membership like a plain agent does.
    if (permissions.includes(MANAGE_ALL_CONVERSATION_PERMISSIONS)) return false;
    if (!permissions.some(held => ASSIGNMENT_SCOPED_PERMISSIONS.includes(held)))
      return false;

    // The human, because the id being compared is an agent's: a bot's id comes from its own table
    // and can be the same integer.
    if (humanAssignee(payload)?.id === user?.id) return true;

    // Whoever holds it, bot included: an unassigned-only role is scoped on the server by
    // `conversations.unassigned`, which a bot-held conversation is not part of. Being handed to a
    // bot takes access away rather than granting it, the same as being handed to another agent.
    return (
      !payload.meta?.assignee &&
      permissions.includes(CONVERSATION_UNASSIGNED_PERMISSIONS)
    );
  };

  onConversationCreated = data => {
    this.app.$store.dispatch('addConversation', data);
    this.fetchConversationStats();

    const pendingJid = pendingGroupNavigation.consume();
    if (pendingJid && data.meta?.sender?.identifier === pendingJid) {
      emitter.emit(BUS_EVENTS.NAVIGATE_TO_GROUP, { conversationId: data.id });
    } else if (pendingJid) {
      pendingGroupNavigation.set(pendingJid);
    }
  };

  onConversationBotHandoff = data => {
    // Trust the handoff event, not its request's performer: a bot handoff can
    // run inside an agent-authenticated API request.
    const key = `${data.account_id}:${data.id}`;
    if (this.pendingHandoffAlerts.has(key)) return;

    // One fixed window lets the normal store absorb assignment/status updates,
    // even assignments delivered before the handoff. Duplicates do not extend it.
    // Late assignments intentionally do not resurrect alerts after this window.
    this.pendingHandoffAlerts.set(
      key,
      setTimeout(() => {
        this.pendingHandoffAlerts.delete(key);
        if (!this.isAValidEvent(data)) return;
        this.alertOnSettledHandoff(data);
      }, HANDOFF_ALERT_WINDOW_MS)
    );
  };

  alertOnSettledHandoff = handoff => {
    const stored = this.app.$store.getters.getConversationById(handoff.id);
    // Fall back to the handoff snapshot when local state is missing or older.
    const conversation =
      stored?.updated_at >= handoff.updated_at ? stored : handoff;
    if (conversation.status !== 'open') return;

    const { assignment, meta } = conversation;
    const hasAssignmentChange =
      assignment?.updated_at > handoff.updated_at ||
      meta?.assignee?.id !== handoff.meta?.assignee?.id ||
      meta?.assignee_type !== handoff.meta?.assignee_type;

    if (hasAssignmentChange) {
      // Unrelated updates (e.g. out-of-office messages) must not cancel alerts.
      // A changed owner needs a matching automatic assignment since the handoff,
      // even if a refreshed status payload exposes it before the assignment event.
      if (
        !assignment?.automatic ||
        assignment.updated_at < handoff.updated_at ||
        assignment.assignee_id !== meta?.assignee?.id ||
        assignment.assignee_type !== meta?.assignee_type
      ) {
        return;
      }
    }
    DashboardAudioNotificationHelper.onConversationBotHandoff(conversation);
  };

  disconnect() {
    this.pendingHandoffAlerts.forEach(clearTimeout);
    this.pendingHandoffAlerts.clear();
    super.disconnect();
  }

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
    // History somebody asked for is shown as it lands, but it is not new mail and
    // must not sound or flash for the rest of the inbox.
    if (!data.content_attributes?.history_archive) {
      DashboardAudioNotificationHelper.onNewMessage(data);
    }
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

  onScheduledMessageCreated = data => {
    this.app.$store.dispatch('handleScheduledMessageCreated', data);
  };

  onConversationUnreadCountChanged = () => {
    this.refreshConversationUnreadCountsWithFilteredRetry();
  };

  refreshConversationUnreadCountsWithFilteredRetry = () => {
    this.throttledFetchConversationUnreadCounts();
    this.scheduleFilteredUnreadCountsRetry();
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

  scheduleMentionUnreadCountsFetch = () => {
    if (!this.isFilteredUnreadCountsEnabled()) return;

    // Mention invalidation runs through the async dispatcher, and stale snapshots
    // can be served until the filtered-count backend refresh window opens.
    this.scheduleUnreadCountsFetchAfter(
      'mentionUnreadCountsFetchTimer',
      MENTION_UNREAD_COUNTS_REFETCH_DELAY_MS
    );
    this.scheduleUnreadCountsFetchAfter(
      'mentionUnreadCountsRetryTimer',
      getFilteredUnreadCountsRefreshRetryDelay(),
      { reset: true }
    );
  };

  scheduleFilteredUnreadCountsRetry = () => {
    if (!this.isFilteredUnreadCountsEnabled()) return;

    // Filtered snapshots can intentionally stay stale until the backend
    // refresh window opens.
    this.scheduleUnreadCountsFetchAfter(
      'filteredUnreadCountsRetryTimer',
      getFilteredUnreadCountsRefreshRetryDelay(),
      { reset: true }
    );
  };

  scheduleUnreadCountsFetchAfter = (
    timerName,
    delay,
    { reset = false } = {}
  ) => {
    if (this[timerName]) {
      if (!reset) return;

      clearTimeout(this[timerName]);
    }

    this[timerName] = setTimeout(() => {
      this[timerName] = null;
      this.throttledFetchConversationUnreadCounts();
    }, delay);
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

  isFilteredUnreadCountsEnabled = () => {
    const accountId = this.app.$store.getters.getCurrentAccountId;
    const isFeatureEnabled =
      this.app.$store.getters['accounts/isFeatureEnabledonAccount'];

    return (
      isFeatureEnabled?.(accountId, FEATURE_FLAGS.CONVERSATION_UNREAD_COUNTS) &&
      isFeatureEnabled?.(accountId, FEATURE_FLAGS.UNREAD_COUNT_FOR_FILTERS)
    );
  };

  onScheduledMessageUpdated = data => {
    this.app.$store.dispatch('handleScheduledMessageUpdated', data);
  };

  onScheduledMessageDeleted = data => {
    this.app.$store.dispatch('handleScheduledMessageDeleted', data);
  };

  onRecurringScheduledMessageCreated = data => {
    this.app.$store.dispatch('handleRecurringScheduledMessageCreated', data);
  };

  onRecurringScheduledMessageUpdated = data => {
    this.app.$store.dispatch('handleRecurringScheduledMessageUpdated', data);
  };

  onRecurringScheduledMessageDeleted = data => {
    this.app.$store.dispatch('handleRecurringScheduledMessageDeleted', data);
  };

  onTypingOn = ({ conversation, user }) => {
    const timerKey = `${conversation.id}:${user.type}:${user.id}`;

    this.clearTimer(timerKey);
    this.app.$store.dispatch('conversationTypingStatus/create', {
      conversationId: conversation.id,
      user: { ...user, recording: false },
    });
    this.initTimer({ conversation, user, timerKey });
  };

  onRecording = ({ conversation, user }) => {
    const timerKey = `${conversation.id}:${user.type}:${user.id}`;

    this.clearTimer(timerKey);
    this.app.$store.dispatch('conversationTypingStatus/create', {
      conversationId: conversation.id,
      user: { ...user, recording: true },
    });
    this.initTimer({ conversation, user, timerKey });
  };

  onTypingOff = ({ conversation, user }) => {
    const timerKey = `${conversation.id}:${user.type}:${user.id}`;

    this.clearTimer(timerKey);
    this.app.$store.dispatch('conversationTypingStatus/destroy', {
      conversationId: conversation.id,
      user,
    });
  };

  onConversationMentioned = data => {
    this.app.$store.dispatch('addMentions', data);
    this.scheduleMentionUnreadCountsFetch();
  };

  onConversationPinned = data => {
    this.app.$store.dispatch('conversationPins/add', data);
  };

  onConversationUnpinned = data => {
    this.app.$store.dispatch('conversationPins/remove', data);
  };

  clearTimer = timerKey => {
    const timerEvent = this.CancelTyping[timerKey];

    if (timerEvent) {
      clearTimeout(timerEvent);
      this.CancelTyping[timerKey] = null;
    }
  };

  initTimer = ({ conversation, user, timerKey }) => {
    // Turn off typing automatically after 30 seconds
    this.CancelTyping[timerKey] = setTimeout(() => {
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

  onContactGroupSynced = data => {
    this.app.$store.dispatch('groupMembers/setGroupMembers', {
      contactId: data.id,
      members: data.group_members,
      inboxPhoneNumber: data.inbox_phone_number,
      ownMemberId: data.own_member_id,
      isInboxAdmin: data.is_inbox_admin,
      inboxId: data.inbox_id,
    });
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

  // eslint-disable-next-line class-methods-use-this
  onCaptainPlaygroundResponse = data => {
    emitter.emit(BUS_EVENTS.CAPTAIN_PLAYGROUND_RESPONSE, data);
  };

  onEnrichmentCompleted = () => {
    this.app.$store.dispatch('accounts/get', { silent: true });
  };

  onBillingUpdated = data => {
    this.app.$store.dispatch('accounts/get', {
      accountId: data.account_id,
      silent: true,
    });
  };

  // The features this member may use changed (an access profile was edited or assigned):
  // ReconnectService reads the user again and leaves what is no longer reachable.
  // eslint-disable-next-line class-methods-use-this
  onFeatureAccessChanged = () => {
    emitter.emit(BUS_EVENTS.FEATURE_ACCESS_CHANGED);
  };

  onCacheInvalidate = data => {
    const keys = data.cache_keys;
    this.app.$store.dispatch('labels/revalidate', { newKey: keys.label });
    this.app.$store.dispatch('inboxes/revalidate', { newKey: keys.inbox });
    this.app.$store.dispatch('teams/revalidate', { newKey: keys.team });
    // Same reason as the unread counts below: which pins are visible follows the accessible set, so a
    // regained role or custom role would otherwise leave a pinned conversation rendering as unpinned until
    // the next reconnect. Inbox membership does not emit this event, so that path still waits for one.
    this.app.$store.dispatch('conversationPins/fetch');
    this.app.$store.dispatch('revalidateCannedResponses', {
      newKey: keys.canned_response,
    });

    if (this.isFilteredUnreadCountsEnabled()) {
      // Inbox/team/label visibility changes can change the accessible set used
      // by filtered unread counts even when no conversation row changes.
      this.refreshConversationUnreadCountsWithFilteredRetry();
    }
  };

  onInboxProviderConnectionUpdated = data => {
    this.app.$store.dispatch('inboxes/updateProviderConnection', {
      id: data.inbox_id,
      providerConnection: data.provider_connection,
    });
  };

  onInternalChatMessageCreated = data => {
    this.app.$store.dispatch('internalChat/messages/addMessageFromCable', {
      channelId: data.internal_chat_channel_id,
      message: data,
    });
    const channel = this.app.$store.getters['internalChat/getChannelById'](
      data.internal_chat_channel_id
    );
    if (channel) {
      const currentUserId = this.app.$store.getters.getCurrentUser?.id;
      const isOwnMessage = data.sender?.id === currentUserId;
      const activeChannelId =
        this.app.$store.getters['internalChat/getActiveChannelId'];
      const isActiveChannel = activeChannelId === data.internal_chat_channel_id;
      const mentionedIds = data.content_attributes?.mentioned_user_ids || [];
      const isMentioned = mentionedIds.includes(currentUserId);
      this.app.$store.dispatch('internalChat/updateChannel', {
        id: data.internal_chat_channel_id,
        unread_count:
          isActiveChannel || isOwnMessage
            ? channel.unread_count || 0
            : (channel.unread_count || 0) + 1,
        has_unread_mention:
          isActiveChannel || isOwnMessage
            ? false
            : channel.has_unread_mention || isMentioned,
        last_activity_at: data.created_at,
      });
    }
  };

  onInternalChatMessageUpdated = data => {
    this.app.$store.dispatch('internalChat/messages/updateMessageFromCable', {
      channelId: data.internal_chat_channel_id,
      message: data,
    });
  };

  onInternalChatMessageDeleted = data => {
    this.app.$store.dispatch('internalChat/messages/deleteMessageFromCable', {
      channelId: data.internal_chat_channel_id,
      messageId: data.id,
    });
  };

  onInternalChatTypingOn = ({ channel, user }) => {
    this.app.$store.dispatch('internalChatTypingStatus/create', {
      channelId: channel.id,
      user,
    });
  };

  onInternalChatTypingOff = ({ channel, user }) => {
    this.app.$store.dispatch('internalChatTypingStatus/destroy', {
      channelId: channel.id,
      user,
    });
  };

  onInternalChatReactionCreated = data => {
    this.app.$store.dispatch('internalChat/messages/addReactionFromCable', {
      channelId: data.internal_chat_channel_id,
      messageId: data.message_id,
      reaction: data,
    });
  };

  onInternalChatReactionDeleted = data => {
    this.app.$store.dispatch('internalChat/messages/removeReactionFromCable', {
      channelId: data.internal_chat_channel_id,
      messageId: data.message_id,
      reactionId: data.id,
    });
  };

  onInternalChatChannelUpdated = data => {
    const currentUserId = this.app.$store.getters.getCurrentUser?.id;
    const memberIds = data.member_user_ids;

    if (memberIds && currentUserId && data.channel_type === 'private_channel') {
      if (!memberIds.includes(currentUserId)) {
        // Current user was removed from channel
        this.app.$store.commit('internalChat/DELETE_CHANNEL', data.id);
        return;
      }
      // Current user was added: if channel not in store, refetch channels
      const existing = this.app.$store.getters['internalChat/getChannelById'](
        data.id
      );
      if (!existing) {
        this.app.$store.dispatch('internalChat/get');
        return;
      }
    }

    this.app.$store.dispatch('internalChat/updateChannel', data);
  };

  onInternalChatPollVoted = data => {
    this.app.$store.dispatch('internalChat/polls/updatePollFromCable', {
      channelId: data.internal_chat_channel_id,
      poll: data,
    });
  };

  onVoiceCallIncoming = data => {
    if (data?.provider !== VOICE_CALL_PROVIDERS.WHATSAPP) return;
    // Defense in depth: the server already filters to online agent streams that
    // take calls, but if anything ever broadcasts to a broader stream (e.g.
    // account-wide), an agent who is not online or has turned calls off
    // shouldn't ring.
    if (!this.app.$store.getters.getCurrentUserReceivesCalls) return;

    useCallsStore().addCall({
      callSid: data.call_id,
      callId: data.id,
      conversationId: data.conversation_id,
      inboxId: data.inbox_id,
      callDirection: VOICE_CALL_DIRECTION.INBOUND,
      provider: VOICE_CALL_PROVIDERS.WHATSAPP,
      sdpOffer: data.sdp_offer,
      iceServers: data.ice_servers,
      recordingEnabled: data.recording_enabled !== false,
      caller: data.caller,
    });
  };

  // Inbound call accepted (in this tab or a sibling tab/window on the same
  // account, on either provider). Broadcast is account-wide, so drop the
  // ringing card everywhere except the tab that actually owns the now-active
  // call — removing an active call here would tear down its live WebRTC
  // session. Check isLocalWhatsappCall/isLocalCall (both set synchronously
  // before their respective accept/join API calls) rather than the store's
  // isActive flag, which this tab may not have set yet.
  // Mark dismissed regardless of locality: the ringing message.created for
  // this call is queued through ActionCableBroadcastJob and can still be
  // delivered after this (synchronous) broadcast, which would otherwise
  // re-add the call as ringing once it finally arrives.
  // eslint-disable-next-line class-methods-use-this
  onVoiceCallAccepted = data => {
    if (!data?.provider) return;
    markCallDismissed(data.call_id);
    const isLocal =
      data.provider === VOICE_CALL_PROVIDERS.WHATSAPP
        ? isLocalWhatsappCall(data.id)
        : isLocalCall(data.call_id);
    if (isLocal) return;
    useCallsStore().removeCall(data.call_id);
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
    if (!Object.values(VOICE_CALL_PROVIDERS).includes(data?.provider)) return;
    // A still-queued ringing message.created (see onVoiceCallAccepted) must not
    // resurrect a call that has already ended.
    markCallDismissed(data.call_id);
    // The store entry should always be removed for this account-wide broadcast,
    // but the WebRTC/recorder teardown must only run for the call this tab owns
    // — otherwise an unrelated agent's call ending would stop this tab's
    // recorder and upload its chunks against the wrong call id. For Twilio,
    // removeCall's own isActive check already scopes teardown to the owning
    // tab (via TwilioVoiceClient.endClientCall in teardownByProvider), so no
    // extra guard is needed here — only WhatsApp's recorder upload must be
    // awaited before the store entry (and its in-memory chunks) is wiped.
    if (
      data.provider === VOICE_CALL_PROVIDERS.WHATSAPP &&
      isLocalWhatsappCall(data.id)
    ) {
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
