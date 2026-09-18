import { createStore } from 'vuex';
import conversationModule from 'dashboard/store/modules/conversations';
import Connector from '../actionCable';
import alerts from '../AudioAlerts/DashboardAudioNotificationHelper';
import AudioNotificationStore from '../AudioAlerts/AudioNotificationStore';
import WindowVisibilityHelper from '../AudioAlerts/WindowVisibilityHelper';
import { showBadgeOnFavicon } from '../AudioAlerts/faviconHelper';

vi.mock('@rails/actioncable', () => ({
  createConsumer: () => ({
    subscriptions: { create: vi.fn() },
    disconnect: vi.fn(),
  }),
}));
vi.mock('dashboard/store', () => ({ default: {} }));
vi.mock('dashboard/composables/useImpersonation', () => ({
  useImpersonation: () => ({ isImpersonating: { value: false } }),
}));
vi.mock('../AudioAlerts/faviconHelper', () => ({
  showBadgeOnFavicon: vi.fn(),
  initFaviconSwitcher: vi.fn(),
}));

const HANDOFF_ALERT_WINDOW_MS = 2500;

describe('handoff event → conversation store → audible alert', () => {
  let store;
  let connector;
  let handoff;
  let assignment;
  let play;

  beforeEach(() => {
    vi.useFakeTimers();
    store = createStore({
      ...conversationModule,
      state: {
        ...conversationModule.state,
        allConversations: [],
        conversationFilters: {},
      },
      getters: {
        ...conversationModule.getters,
        getCurrentAccountId: state => state.currentAccountId,
        getCurrentUserID: () => 7,
      },
      modules: {
        conversationLabels: {
          namespaced: true,
          actions: { setConversationLabel: vi.fn() },
        },
      },
    });
    store.state.currentAccountId = 1;
    connector = Connector.init(store, 'test-token');
    vi.spyOn(connector, 'fetchConversationStats').mockImplementation(() => {});
    alerts.store = new AudioNotificationStore(store);
    alerts.currentUser = {
      id: 7,
      accounts: [{ id: 1, permissions: ['administrator'] }],
    };
    alerts.notificationConfig = {
      audioAlertType: ['mine'],
      playAlertOnlyWhenHidden: true,
      alertIfUnreadConversationExist: false,
    };
    play = vi.fn().mockResolvedValue();
    alerts.audioConfig.audio = { play };
    vi.spyOn(WindowVisibilityHelper, 'isWindowVisible').mockReturnValue(false);
    handoff = {
      id: 12,
      account_id: 1,
      status: 'open',
      updated_at: 100,
      meta: { assignee_type: null, assignee: null },
    };
    assignment = {
      ...handoff,
      updated_at: 101,
      meta: { assignee_type: 'User', assignee: { id: 7 } },
      assignment: {
        automatic: true,
        assignee_id: 7,
        assignee_type: 'User',
        updated_at: 101,
      },
    };
  });

  afterEach(() => {
    connector.disconnect();
    vi.clearAllTimers();
    vi.restoreAllMocks();
    vi.clearAllMocks();
    vi.useRealTimers();
  });

  it.each(['note first', 'handoff first'])(
    'stores the Captain note but alerts only for the handoff with %s',
    order => {
      store.state.allConversations.push({ ...assignment, messages: [] });
      const note = {
        id: 51,
        account_id: 1,
        conversation_id: handoff.id,
        conversation: { assignee_id: 7, last_activity_at: 101 },
        message_type: 1,
        private: true,
        sender: { id: 99, type: 'captain_assistant' },
      };
      const events = [
        { event: 'message.created', data: note },
        { event: 'conversation.bot_handoff', data: handoff },
      ];
      if (order === 'handoff first') events.reverse();
      events.forEach(event => connector.onReceived(event));

      expect(store.getters.getConversationById(handoff.id).messages).toEqual([
        note,
      ]);
      expect(play).not.toHaveBeenCalled();
      vi.advanceTimersByTime(HANDOFF_ALERT_WINDOW_MS);
      expect(play).toHaveBeenCalledOnce();
      expect(showBadgeOnFavicon).toHaveBeenCalledOnce();
    }
  );

  it.each(['handoff first', 'assignment first'])(
    'alerts once for automatic assignment with %s',
    order => {
      if (order === 'assignment first')
        connector.onReceived({ event: 'assignee.changed', data: assignment });
      connector.onReceived({
        event: 'conversation.bot_handoff',
        data: handoff,
      });
      if (order === 'handoff first')
        connector.onReceived({ event: 'assignee.changed', data: assignment });
      expect(play).not.toHaveBeenCalled();
      vi.advanceTimersByTime(HANDOFF_ALERT_WINDOW_MS);
      expect(play).toHaveBeenCalledOnce();
      expect(showBadgeOnFavicon).toHaveBeenCalledOnce();
    }
  );

  it.each([false, undefined])(
    'suppresses an assignment with automatic=%s even when an unrelated event changes performer',
    automatic => {
      assignment.assignment.automatic = automatic;
      connector.onReceived({ event: 'assignee.changed', data: assignment });
      connector.onReceived({
        event: 'conversation.bot_handoff',
        data: handoff,
      });
      connector.onReceived({
        event: 'conversation.updated',
        data: {
          ...handoff,
          meta: assignment.meta,
          updated_at: 102,
          performer: null,
        },
      });
      vi.advanceTimersByTime(HANDOFF_ALERT_WINDOW_MS);
      expect(play).not.toHaveBeenCalled();
    }
  );

  it('retains automatic provenance across unrelated human-performed updates', () => {
    connector.onReceived({ event: 'assignee.changed', data: assignment });
    connector.onReceived({
      event: 'conversation.updated',
      data: {
        ...handoff,
        meta: assignment.meta,
        updated_at: 102,
        performer: { type: 'user' },
      },
    });
    connector.onReceived({ event: 'conversation.bot_handoff', data: handoff });
    vi.advanceTimersByTime(HANDOFF_ALERT_WINDOW_MS);
    expect(play).toHaveBeenCalledOnce();
  });

  it.each(['conversation.status_changed', 'conversation.updated'])(
    'preserves an unassigned handoff after a newer open %s snapshot',
    event => {
      alerts.notificationConfig.audioAlertType = ['all'];
      connector.onReceived({
        event: 'conversation.bot_handoff',
        data: handoff,
      });
      // An out-of-office message advances updated_at before the queued
      // broadcast refreshes its snapshot, without changing status or assignment.
      connector.onReceived({
        event,
        data: { ...handoff, updated_at: 102 },
      });
      vi.advanceTimersByTime(HANDOFF_ALERT_WINDOW_MS);
      expect(play).toHaveBeenCalledOnce();
    }
  );

  it('ignores assignment provenance from before the handoff when the owner is unchanged', () => {
    handoff.meta = assignment.meta;
    connector.onReceived({ event: 'conversation.bot_handoff', data: handoff });
    connector.onReceived({
      event: 'conversation.updated',
      data: {
        ...handoff,
        updated_at: 102,
        assignment: {
          ...assignment.assignment,
          automatic: false,
          updated_at: 99,
        },
      },
    });
    vi.advanceTimersByTime(HANDOFF_ALERT_WINDOW_MS);
    expect(play).toHaveBeenCalledOnce();
  });

  it('still cancels when a refreshed status exposes a changed owner without assignment provenance', () => {
    alerts.notificationConfig.audioAlertType = ['all'];
    connector.onReceived({ event: 'conversation.bot_handoff', data: handoff });
    connector.onReceived({
      event: 'conversation.status_changed',
      data: { ...handoff, updated_at: 102, meta: assignment.meta },
    });
    vi.advanceTimersByTime(HANDOFF_ALERT_WINDOW_MS);
    expect(play).not.toHaveBeenCalled();
  });

  it('accepts a synchronous assignment already reflected in the handoff snapshot', () => {
    handoff.meta = assignment.meta;
    connector.onReceived({ event: 'conversation.bot_handoff', data: handoff });
    connector.onReceived({
      event: 'assignee.changed',
      data: {
        ...assignment,
        updated_at: 102,
        assignment: {
          ...assignment.assignment,
          automatic: false,
          updated_at: handoff.updated_at,
        },
      },
    });
    vi.advanceTimersByTime(HANDOFF_ALERT_WINDOW_MS);
    expect(play).toHaveBeenCalledOnce();
  });

  it('cancels when resolved and ignores an older open event delivered afterward', () => {
    alerts.notificationConfig.audioAlertType = ['all'];
    connector.onReceived({ event: 'conversation.bot_handoff', data: handoff });
    connector.onReceived({
      event: 'conversation.status_changed',
      data: { ...handoff, status: 'resolved', updated_at: 102 },
    });
    connector.onReceived({ event: 'assignee.changed', data: assignment });
    vi.advanceTimersByTime(HANDOFF_ALERT_WINDOW_MS);
    expect(play).not.toHaveBeenCalled();
  });

  it('does not resurrect an expired handoff when assignment arrives late', () => {
    connector.onReceived({ event: 'conversation.bot_handoff', data: handoff });
    vi.advanceTimersByTime(HANDOFF_ALERT_WINDOW_MS);
    connector.onReceived({ event: 'assignee.changed', data: assignment });
    vi.advanceTimersByTime(5000);
    expect(play).not.toHaveBeenCalled();
    expect(connector.pendingHandoffAlerts.size).toBe(0);
  });

  it('includes an assignment after two seconds and alerts at exactly 2.5 seconds', () => {
    connector.onReceived({ event: 'conversation.bot_handoff', data: handoff });
    vi.advanceTimersByTime(2200);
    connector.onReceived({ event: 'assignee.changed', data: assignment });
    vi.advanceTimersByTime(299);
    expect(play).not.toHaveBeenCalled();
    vi.advanceTimersByTime(1);
    expect(play).toHaveBeenCalledOnce();
    expect(connector.pendingHandoffAlerts.size).toBe(0);
  });

  it('coalesces duplicate handoffs without extending the deadline', () => {
    alerts.notificationConfig.audioAlertType = ['all'];
    connector.onReceived({ event: 'conversation.bot_handoff', data: handoff });
    vi.advanceTimersByTime(HANDOFF_ALERT_WINDOW_MS - 500);
    connector.onReceived({ event: 'conversation.bot_handoff', data: handoff });
    vi.advanceTimersByTime(500);
    expect(play).toHaveBeenCalledOnce();
    vi.advanceTimersByTime(HANDOFF_ALERT_WINDOW_MS);
    expect(play).toHaveBeenCalledOnce();
  });

  it.each([
    ['all', 1],
    ['none', 0],
    ['mine', 0],
  ])(
    'uses the handoff snapshot with %s preferences when local state is missing',
    (filter, count) => {
      alerts.notificationConfig.audioAlertType = [filter];
      connector.onReceived({
        event: 'conversation.bot_handoff',
        data: handoff,
      });
      vi.advanceTimersByTime(HANDOFF_ALERT_WINDOW_MS);
      expect(play).toHaveBeenCalledTimes(count);
    }
  );

  it('rechecks the selected account when the timer fires', () => {
    alerts.notificationConfig.audioAlertType = ['all'];
    connector.onReceived({ event: 'conversation.bot_handoff', data: handoff });
    store.state.currentAccountId = 2;
    vi.advanceTimersByTime(HANDOFF_ALERT_WINDOW_MS);
    expect(play).not.toHaveBeenCalled();
  });

  it('discards timers on disconnect', () => {
    alerts.notificationConfig.audioAlertType = ['all'];
    connector.onReceived({ event: 'conversation.bot_handoff', data: handoff });
    connector.disconnect();
    expect(connector.pendingHandoffAlerts.size).toBe(0);
    vi.advanceTimersByTime(HANDOFF_ALERT_WINDOW_MS);
    expect(play).not.toHaveBeenCalled();
  });

  it('cancels when a human overrides automatic assignment during the window', () => {
    alerts.notificationConfig.audioAlertType = ['all'];
    connector.onReceived({ event: 'conversation.bot_handoff', data: handoff });
    connector.onReceived({ event: 'assignee.changed', data: assignment });
    connector.onReceived({
      event: 'assignee.changed',
      data: {
        ...assignment,
        updated_at: 102,
        assignment: {
          ...assignment.assignment,
          automatic: false,
          updated_at: 102,
        },
      },
    });
    vi.advanceTimersByTime(HANDOFF_ALERT_WINDOW_MS);
    expect(play).not.toHaveBeenCalled();
  });

  it.each([
    ['old assignment', { updated_at: 99 }],
    ['different assignee', { assignee_id: 8 }],
    ['different assignee type', { assignee_type: 'AgentBot' }],
  ])('does not reuse automatic provenance for %s', (_, metadata) => {
    assignment.assignment = { ...assignment.assignment, ...metadata };
    connector.onReceived({ event: 'assignee.changed', data: assignment });
    connector.onReceived({ event: 'conversation.bot_handoff', data: handoff });
    vi.advanceTimersByTime(HANDOFF_ALERT_WINDOW_MS);
    expect(play).not.toHaveBeenCalled();
  });

  it.each(['user', 'agent_bot'])(
    'does not confuse a %s handoff performer with assignment provenance',
    type => {
      alerts.notificationConfig.audioAlertType = ['all'];
      connector.onReceived({
        event: 'conversation.bot_handoff',
        data: { ...handoff, performer: { type } },
      });
      vi.advanceTimersByTime(HANDOFF_ALERT_WINDOW_MS);
      expect(play).toHaveBeenCalledOnce();
    }
  );

  it.each(['hidden-only', 'selected conversation', 'no permission'])(
    'rechecks %s at the deadline',
    reason => {
      connector.onReceived({
        event: 'conversation.bot_handoff',
        data: handoff,
      });
      connector.onReceived({ event: 'assignee.changed', data: assignment });
      if (reason === 'no permission') {
        alerts.currentUser.accounts[0].permissions = [];
      } else {
        WindowVisibilityHelper.isWindowVisible.mockReturnValue(true);
        if (reason === 'selected conversation') {
          alerts.notificationConfig.playAlertOnlyWhenHidden = false;
          store.state.selectedChatId = 12;
        }
      }
      vi.advanceTimersByTime(HANDOFF_ALERT_WINDOW_MS);
      expect(play).not.toHaveBeenCalled();
    }
  );
});
