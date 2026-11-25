import { describe, it, beforeEach, afterEach, expect, vi } from 'vitest';
import ActionCableConnector from '../actionCable';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import DashboardAudioNotificationHelper from '../AudioAlerts/DashboardAudioNotificationHelper';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { emitter } from 'shared/helpers/mitt';

vi.mock('shared/helpers/mitt', () => ({
  emitter: {
    emit: vi.fn(),
  },
}));

vi.mock('dashboard/composables/useImpersonation', () => ({
  useImpersonation: () => ({
    isImpersonating: { value: false },
  }),
}));

global.chatwootConfig = {
  websocketURL: 'wss://test.chatwoot.com',
};

const mockRetryJitter = value =>
  vi.spyOn(Math, 'random').mockReturnValue(value);

describe('ActionCableConnector - Copilot Tests', () => {
  let store;
  let actionCable;
  let mockDispatch;

  beforeEach(() => {
    vi.clearAllMocks();
    mockDispatch = vi.fn();
    store = {
      $store: {
        dispatch: mockDispatch,
        getters: {
          getCurrentAccountId: 1,
          'accounts/isFeatureEnabledonAccount': vi.fn(() => true),
        },
      },
    };

    actionCable = ActionCableConnector.init(store.$store, 'test-token');
  });

  afterEach(() => {
    vi.restoreAllMocks();
    vi.clearAllTimers();
    vi.useRealTimers();
  });

  describe('message.created event handler', () => {
    const message = contentAttributes => ({
      id: 1,
      conversation_id: 7,
      conversation: { last_activity_at: 1 },
      content_attributes: contentAttributes,
    });

    it('alerts for a new message', () => {
      const alert = vi
        .spyOn(DashboardAudioNotificationHelper, 'onNewMessage')
        .mockImplementation(() => {});
      actionCable.onMessageCreated(message({}));
      expect(alert).toHaveBeenCalled();
      expect(mockDispatch).toHaveBeenCalledWith(
        'addMessage',
        expect.anything()
      );
    });

    it('shows archived history without alerting about it', () => {
      const alert = vi
        .spyOn(DashboardAudioNotificationHelper, 'onNewMessage')
        .mockImplementation(() => {});
      actionCable.onMessageCreated(
        message({ imported: true, history_archive: true })
      );
      expect(alert).not.toHaveBeenCalled();
      expect(mockDispatch).toHaveBeenCalledWith(
        'addMessage',
        expect.anything()
      );
    });
  });

  describe('contact.group_synced event handler', () => {
    it('should register the contact.group_synced event handler', () => {
      expect(Object.keys(actionCable.events)).toContain('contact.group_synced');
      expect(actionCable.events['contact.group_synced']).toBe(
        actionCable.onContactGroupSynced
      );
    });

    it('should dispatch groupMembers/setGroupMembers with contact id and members from payload', () => {
      const groupSyncedData = {
        id: 42,
        name: 'Test Group',
        account_id: 1,
        group_members: [
          {
            id: 1,
            role: 'admin',
            is_active: true,
            contact: {
              id: 10,
              name: 'Alice',
              phone_number: '+1234567890',
              thumbnail: null,
            },
          },
          {
            id: 2,
            role: 'member',
            is_active: true,
            contact: {
              id: 11,
              name: 'Bob',
              phone_number: '+0987654321',
              thumbnail: null,
            },
          },
        ],
      };

      actionCable.onReceived({
        event: 'contact.group_synced',
        data: groupSyncedData,
      });

      expect(mockDispatch).toHaveBeenCalledWith(
        'groupMembers/setGroupMembers',
        {
          contactId: 42,
          members: groupSyncedData.group_members,
        }
      );
    });
  });

  describe('copilot event handlers', () => {
    it('should register the copilot.message.created event handler', () => {
      expect(Object.keys(actionCable.events)).toContain(
        'copilot.message.created'
      );
      expect(actionCable.events['copilot.message.created']).toBe(
        actionCable.onCopilotMessageCreated
      );
    });

    it('should handle the copilot.message.created event through the ActionCable system', () => {
      const copilotData = {
        id: 2,
        content: 'This is a copilot message from ActionCable',
        conversation_id: 456,
        created_at: '2025-05-27T15:58:04-06:00',
        account_id: 1,
      };
      actionCable.onReceived({
        event: 'copilot.message.created',
        data: copilotData,
      });
      expect(mockDispatch).toHaveBeenCalledWith(
        'copilotMessages/upsert',
        copilotData
      );
    });
  });

  describe('inbox.provider_connection_updated event handler', () => {
    it('should register the inbox.provider_connection_updated event handler', () => {
      expect(Object.keys(actionCable.events)).toContain(
        'inbox.provider_connection_updated'
      );
      expect(actionCable.events['inbox.provider_connection_updated']).toBe(
        actionCable.onInboxProviderConnectionUpdated
      );
    });

    it('should dispatch inboxes/updateProviderConnection with the inbox id and connection', () => {
      actionCable.onReceived({
        event: 'inbox.provider_connection_updated',
        data: {
          inbox_id: 7,
          provider_connection: { connection: 'open' },
          account_id: 1,
        },
      });

      expect(mockDispatch).toHaveBeenCalledWith(
        'inboxes/updateProviderConnection',
        { id: 7, providerConnection: { connection: 'open' } }
      );
    });
  });

  describe('Captain Playground event handlers', () => {
    it('registers the captain.playground.response event handler', () => {
      expect(actionCable.events['captain.playground.response']).toBe(
        actionCable.onCaptainPlaygroundResponse
      );
    });

    it('emits the Playground response on the dashboard event bus', () => {
      const playgroundData = {
        account_id: 1,
        request_id: 'playground-request-1',
        response: 'Hello from Captain',
      };

      actionCable.onReceived({
        event: 'captain.playground.response',
        data: playgroundData,
      });

      expect(emitter.emit).toHaveBeenCalledWith(
        BUS_EVENTS.CAPTAIN_PLAYGROUND_RESPONSE,
        playgroundData
      );
    });
  });

  describe('feature_access.changed', () => {
    it('asks the dashboard to read the member features again', () => {
      actionCable.onReceived({
        event: 'feature_access.changed',
        data: { account_id: 1 },
      });

      expect(emitter.emit).toHaveBeenCalledWith(
        BUS_EVENTS.FEATURE_ACCESS_CHANGED
      );
    });
  });

  describe('monitor.updated', () => {
    it('forwards updates for the active account', () => {
      const data = { account_id: 1, monitor_id: 2, data_revision: 3 };

      actionCable.onReceived({ event: 'monitor.updated', data });

      expect(emitter.emit).toHaveBeenCalledWith(
        BUS_EVENTS.MONITOR_UPDATED,
        data
      );
    });

    it('ignores updates from another account', () => {
      actionCable.onReceived({
        event: 'monitor.updated',
        data: { account_id: 2, monitor_id: 2 },
      });

      expect(emitter.emit).not.toHaveBeenCalledWith(
        BUS_EVENTS.MONITOR_UPDATED,
        expect.anything()
      );
    });
  });

  describe('presence.update', () => {
    it('updates the work preferences of the current user', () => {
      const workPreferences = {
        accepts_conversations: true,
        accepts_calls: false,
      };

      actionCable.onReceived({
        event: 'presence.update',
        data: {
          account_id: 1,
          users: { 1: 'online' },
          contacts: {},
          work_preferences: workPreferences,
        },
      });

      expect(mockDispatch).toHaveBeenCalledWith(
        'setCurrentUserWorkPreferences',
        workPreferences
      );
    });
  });

  describe('conversation unread count event handlers', () => {
    it('should register the conversation.unread_count_changed event handler', () => {
      expect(Object.keys(actionCable.events)).toContain(
        'conversation.unread_count_changed'
      );
      expect(actionCable.events['conversation.unread_count_changed']).toBe(
        actionCable.onConversationUnreadCountChanged
      );
    });

    it('should refetch unread counts when unread count changes', () => {
      vi.useFakeTimers();
      vi.setSystemTime(new Date('2026-01-01T00:00:00Z'));
      mockRetryJitter(0.5);

      actionCable.onReceived({
        event: 'conversation.unread_count_changed',
        data: { account_id: 1 },
      });

      expect(mockDispatch).toHaveBeenCalledWith('conversationUnreadCounts/get');

      vi.advanceTimersByTime(37499);
      expect(mockDispatch).toHaveBeenCalledTimes(1);

      vi.advanceTimersByTime(1);
      expect(mockDispatch).toHaveBeenCalledTimes(2);
      expect(mockDispatch).toHaveBeenLastCalledWith(
        'conversationUnreadCounts/get'
      );
    });

    it('does not retry unread count changes when filtered counts are disabled', () => {
      vi.useFakeTimers();
      vi.setSystemTime(new Date('2026-01-01T00:00:00Z'));
      store.$store.getters[
        'accounts/isFeatureEnabledonAccount'
      ].mockImplementation(
        (_, featureFlag) =>
          featureFlag === FEATURE_FLAGS.CONVERSATION_UNREAD_COUNTS
      );

      actionCable.onReceived({
        event: 'conversation.unread_count_changed',
        data: { account_id: 1 },
      });

      expect(mockDispatch).toHaveBeenCalledTimes(1);

      vi.advanceTimersByTime(45000);
      expect(mockDispatch).toHaveBeenCalledTimes(1);
    });

    it('delays unread count refetch when a conversation is mentioned', () => {
      vi.useFakeTimers();
      vi.setSystemTime(new Date('2026-01-01T00:00:00Z'));

      const conversation = { id: 1, account_id: 1 };

      actionCable.onReceived({
        event: 'conversation.mentioned',
        data: conversation,
      });

      expect(mockDispatch).toHaveBeenCalledWith('addMentions', conversation);
      expect(mockDispatch).not.toHaveBeenCalledWith(
        'conversationUnreadCounts/get'
      );

      vi.advanceTimersByTime(4999);
      expect(mockDispatch).not.toHaveBeenCalledWith(
        'conversationUnreadCounts/get'
      );

      vi.advanceTimersByTime(1);
      expect(mockDispatch).toHaveBeenCalledWith('conversationUnreadCounts/get');
    });

    it('does not schedule mention unread count fetches when filtered counts are disabled', () => {
      vi.useFakeTimers();
      store.$store.getters[
        'accounts/isFeatureEnabledonAccount'
      ].mockImplementation(
        (_, featureFlag) =>
          featureFlag === FEATURE_FLAGS.CONVERSATION_UNREAD_COUNTS
      );

      const conversation = { id: 1, account_id: 1 };

      actionCable.onReceived({
        event: 'conversation.mentioned',
        data: conversation,
      });

      expect(mockDispatch).toHaveBeenCalledWith('addMentions', conversation);

      vi.advanceTimersByTime(45000);
      expect(mockDispatch).not.toHaveBeenCalledWith(
        'conversationUnreadCounts/get'
      );
    });

    it('retries mentioned unread counts after the backend refresh window', () => {
      vi.useFakeTimers();
      vi.setSystemTime(new Date('2026-01-01T00:00:00Z'));
      mockRetryJitter(0.5);

      actionCable.onReceived({
        event: 'conversation.mentioned',
        data: { id: 1, account_id: 1 },
      });

      const unreadCountFetches = () =>
        mockDispatch.mock.calls.filter(
          ([action]) => action === 'conversationUnreadCounts/get'
        );

      vi.advanceTimersByTime(5000);
      expect(unreadCountFetches()).toHaveLength(1);

      vi.advanceTimersByTime(32499);
      expect(unreadCountFetches()).toHaveLength(1);

      vi.advanceTimersByTime(1);
      expect(unreadCountFetches()).toHaveLength(2);
    });

    it('reschedules mentioned unread count retries for later invalidations', () => {
      vi.useFakeTimers();
      vi.setSystemTime(new Date('2026-01-01T00:00:00Z'));
      mockRetryJitter(0);

      const unreadCountFetches = () =>
        mockDispatch.mock.calls.filter(
          ([action]) => action === 'conversationUnreadCounts/get'
        );

      actionCable.onReceived({
        event: 'conversation.mentioned',
        data: { id: 1, account_id: 1 },
      });

      vi.advanceTimersByTime(5000);
      expect(unreadCountFetches()).toHaveLength(1);

      vi.advanceTimersByTime(10000);
      actionCable.onReceived({
        event: 'conversation.mentioned',
        data: { id: 1, account_id: 1 },
      });

      vi.advanceTimersByTime(5000);
      expect(unreadCountFetches()).toHaveLength(2);

      vi.advanceTimersByTime(10000);
      expect(unreadCountFetches()).toHaveLength(2);

      vi.advanceTimersByTime(15000);
      expect(unreadCountFetches()).toHaveLength(3);
    });

    it('refetches filtered unread counts after account cache invalidation', () => {
      vi.useFakeTimers();
      vi.setSystemTime(new Date('2026-01-01T00:00:00Z'));
      mockRetryJitter(0.5);

      const cacheKeys = {
        label: 'label-key',
        inbox: 'inbox-key',
        team: 'team-key',
      };
      const unreadCountFetches = () =>
        mockDispatch.mock.calls.filter(
          ([action]) => action === 'conversationUnreadCounts/get'
        );

      actionCable.onReceived({
        event: 'account.cache_invalidated',
        data: { account_id: 1, cache_keys: cacheKeys },
      });

      expect(mockDispatch).toHaveBeenCalledWith('labels/revalidate', {
        newKey: cacheKeys.label,
      });
      expect(mockDispatch).toHaveBeenCalledWith('inboxes/revalidate', {
        newKey: cacheKeys.inbox,
      });
      expect(mockDispatch).toHaveBeenCalledWith('teams/revalidate', {
        newKey: cacheKeys.team,
      });
      expect(unreadCountFetches()).toHaveLength(1);

      vi.advanceTimersByTime(37499);
      expect(unreadCountFetches()).toHaveLength(1);

      vi.advanceTimersByTime(1);
      expect(unreadCountFetches()).toHaveLength(2);
    });

    it('does not refetch unread counts after cache invalidation when filtered counts are disabled', () => {
      vi.useFakeTimers();
      store.$store.getters[
        'accounts/isFeatureEnabledonAccount'
      ].mockImplementation(
        (_, featureFlag) =>
          featureFlag === FEATURE_FLAGS.CONVERSATION_UNREAD_COUNTS
      );

      actionCable.onReceived({
        event: 'account.cache_invalidated',
        data: {
          account_id: 1,
          cache_keys: {
            label: 'label-key',
            inbox: 'inbox-key',
            team: 'team-key',
          },
        },
      });

      expect(mockDispatch).not.toHaveBeenCalledWith(
        'conversationUnreadCounts/get'
      );

      vi.advanceTimersByTime(45000);
      expect(mockDispatch).not.toHaveBeenCalledWith(
        'conversationUnreadCounts/get'
      );
    });

    it('does not refetch unread counts when unread count feature is disabled', () => {
      store.$store.getters[
        'accounts/isFeatureEnabledonAccount'
      ].mockReturnValue(false);

      actionCable.onReceived({
        event: 'conversation.unread_count_changed',
        data: { account_id: 1 },
      });

      expect(mockDispatch).not.toHaveBeenCalledWith(
        'conversationUnreadCounts/get'
      );
    });

    it('should throttle unread count refetches for repeated events', () => {
      vi.useFakeTimers();
      vi.setSystemTime(new Date('2026-01-01T00:00:00Z'));

      actionCable.onReceived({
        event: 'conversation.unread_count_changed',
        data: { account_id: 1 },
      });
      actionCable.onReceived({
        event: 'conversation.unread_count_changed',
        data: { account_id: 1 },
      });
      actionCable.onReceived({
        event: 'conversation.unread_count_changed',
        data: { account_id: 1 },
      });

      expect(mockDispatch).toHaveBeenCalledTimes(1);

      vi.advanceTimersByTime(4999);
      expect(mockDispatch).toHaveBeenCalledTimes(1);

      vi.advanceTimersByTime(1);
      expect(mockDispatch).toHaveBeenCalledTimes(2);
      expect(mockDispatch).toHaveBeenLastCalledWith(
        'conversationUnreadCounts/get'
      );
    });

    it('clears pending unread count refetch before immediate refetch', () => {
      vi.useFakeTimers();
      vi.setSystemTime(new Date('2026-01-01T00:00:00Z'));

      actionCable.onReceived({
        event: 'conversation.unread_count_changed',
        data: { account_id: 1 },
      });

      vi.advanceTimersByTime(1000);
      actionCable.onReceived({
        event: 'conversation.unread_count_changed',
        data: { account_id: 1 },
      });

      vi.setSystemTime(new Date('2026-01-01T00:00:06Z'));
      actionCable.onReceived({
        event: 'conversation.unread_count_changed',
        data: { account_id: 1 },
      });

      expect(mockDispatch).toHaveBeenCalledTimes(2);

      vi.advanceTimersByTime(4000);
      expect(mockDispatch).toHaveBeenCalledTimes(2);
    });
  });

  describe('conversation pin event handlers', () => {
    it('dispatches conversationPins/add on conversation.pinned', () => {
      actionCable.onReceived({
        event: 'conversation.pinned',
        data: { account_id: 1, conversation_id: 7, pinned_at: 100 },
      });

      expect(mockDispatch).toHaveBeenCalledWith('conversationPins/add', {
        account_id: 1,
        conversation_id: 7,
        pinned_at: 100,
      });
    });

    it('dispatches conversationPins/remove on conversation.unpinned', () => {
      actionCable.onReceived({
        event: 'conversation.unpinned',
        data: { account_id: 1, conversation_id: 7, pinned_at: 100 },
      });

      expect(mockDispatch).toHaveBeenCalledWith('conversationPins/remove', {
        account_id: 1,
        conversation_id: 7,
        pinned_at: 100,
      });
    });

    it('ignores events from another account', () => {
      actionCable.onReceived({
        event: 'conversation.pinned',
        data: { account_id: 2, conversation_id: 7, pinned_at: 100 },
      });

      expect(mockDispatch).not.toHaveBeenCalled();
    });

    it('refetches the pins when the account cache is invalidated', () => {
      actionCable.onReceived({
        event: 'account.cache_invalidated',
        data: { account_id: 1, cache_keys: {} },
      });

      expect(mockDispatch).toHaveBeenCalledWith('conversationPins/fetch');
    });
  });

  describe('pin refresh on assignment', () => {
    const assigneeChanged = (assignee, assigneeType = 'User') => ({
      event: 'assignee.changed',
      data: {
        account_id: 1,
        id: 7,
        meta: { assignee, assignee_type: assigneeType },
      },
    });

    const userWith = permissions => ({
      id: 11,
      accounts: [{ id: 1, permissions }],
    });

    beforeEach(() => {
      store.$store.getters.getCurrentUser = userWith([
        'conversation_participating_manage',
      ]);
    });

    it('refetches the pins when the conversation is assigned to the current user', () => {
      actionCable.onReceived(assigneeChanged({ id: 11 }));

      expect(mockDispatch).toHaveBeenCalledWith('conversationPins/fetch');
    });

    it('does not refetch when the conversation is assigned to someone else', () => {
      actionCable.onReceived(assigneeChanged({ id: 12 }));

      expect(mockDispatch).not.toHaveBeenCalledWith('conversationPins/fetch');
    });

    it('does not refetch when an agent bot shares the current user id', () => {
      actionCable.onReceived(assigneeChanged({ id: 11 }, 'AgentBot'));

      expect(mockDispatch).not.toHaveBeenCalledWith('conversationPins/fetch');
    });

    it('does not refetch for a plain agent, whose access never followed the assignee', () => {
      store.$store.getters.getCurrentUser = { id: 11, accounts: [{ id: 1 }] };

      actionCable.onReceived(assigneeChanged({ id: 11 }));

      expect(mockDispatch).not.toHaveBeenCalledWith('conversationPins/fetch');
    });

    it('does not refetch for a role that sees every conversation in its inboxes', () => {
      store.$store.getters.getCurrentUser = userWith(['conversation_manage']);

      actionCable.onReceived(assigneeChanged({ id: 11 }));

      expect(mockDispatch).not.toHaveBeenCalledWith('conversationPins/fetch');
    });

    // The role editor adds both scoped permissions whenever manage-all is picked, so this is what a
    // manage-all role looks like in practice, and the backend reads manage-all with precedence.
    it('does not refetch for a manage-all role carrying the scoped permissions too', () => {
      store.$store.getters.getCurrentUser = userWith([
        'conversation_manage',
        'conversation_unassigned_manage',
        'conversation_participating_manage',
      ]);

      actionCable.onReceived(assigneeChanged({ id: 11 }));
      actionCable.onReceived(assigneeChanged(null, null));

      expect(mockDispatch).not.toHaveBeenCalledWith('conversationPins/fetch');
    });

    // `conversations.unassigned` excludes a conversation a bot holds, so a bot taking over takes it
    // away from an unassigned-only role instead of handing it over.
    it('does not refetch when a bot takes over, which grants no access', () => {
      store.$store.getters.getCurrentUser = userWith([
        'conversation_unassigned_manage',
      ]);

      actionCable.onReceived(assigneeChanged({ id: 99 }, 'AgentBot'));

      expect(mockDispatch).not.toHaveBeenCalledWith('conversationPins/fetch');
    });

    it('refetches when the conversation is unassigned and the role sees unassigned ones', () => {
      store.$store.getters.getCurrentUser = userWith([
        'conversation_unassigned_manage',
      ]);

      actionCable.onReceived(assigneeChanged(null, null));

      expect(mockDispatch).toHaveBeenCalledWith('conversationPins/fetch');
    });

    it('does not refetch when the conversation is unassigned and the role only sees its own', () => {
      actionCable.onReceived(assigneeChanged(null, null));

      expect(mockDispatch).not.toHaveBeenCalledWith('conversationPins/fetch');
    });
  });
});
