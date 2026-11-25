import { emitter } from 'shared/helpers/mitt';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { differenceInSeconds } from 'date-fns';
import {
  isAConversationRoute,
  isAInboxViewRoute,
  validateLoggedInRoutes,
} from 'dashboard/helper/routeHelpers';
import ReconnectService from 'dashboard/helper/ReconnectService';

vi.mock('shared/helpers/mitt', () => ({
  emitter: {
    on: vi.fn(),
    off: vi.fn(),
    emit: vi.fn(),
  },
}));

vi.mock('date-fns', () => ({
  differenceInSeconds: vi.fn(),
}));

vi.mock('dashboard/helper/routeHelpers', () => ({
  isAConversationRoute: vi.fn(),
  isAInboxViewRoute: vi.fn(),
  validateLoggedInRoutes: vi.fn(),
}));

const storeMock = {
  dispatch: vi.fn(),
  getters: {
    getAppliedConversationFiltersQuery: [],
    'customViews/getActiveConversationFolder': { query: {} },
    'notifications/getNotificationFilters': {},
    getChatListFilters: { assigneeType: 'unassigned', status: 'open' },
  },
};

const routerMock = {
  currentRoute: {
    value: {
      name: '',
      params: { conversation_id: null },
    },
  },
};

describe('ReconnectService', () => {
  let reconnectService;

  beforeEach(() => {
    window.addEventListener = vi.fn();
    window.removeEventListener = vi.fn();
    Object.defineProperty(window, 'location', {
      configurable: true,
      value: { reload: vi.fn() },
    });
    reconnectService = new ReconnectService(storeMock, routerMock);
  });

  afterEach(() => {
    vi.clearAllMocks();
  });

  describe('constructor', () => {
    it('should initialize with store, router, and setup event listeners', () => {
      expect(reconnectService.store).toBe(storeMock);
      expect(reconnectService.router).toBe(routerMock);
      expect(window.addEventListener).toHaveBeenCalledWith(
        'online',
        reconnectService.handleOnlineEvent
      );
      expect(emitter.on).toHaveBeenCalledWith(
        BUS_EVENTS.WEBSOCKET_RECONNECT,
        reconnectService.onReconnect
      );
      expect(emitter.on).toHaveBeenCalledWith(
        BUS_EVENTS.WEBSOCKET_DISCONNECT,
        reconnectService.onDisconnect
      );
    });

    it('enforces route access when the server says the features changed', () => {
      expect(emitter.on).toHaveBeenCalledWith(
        BUS_EVENTS.FEATURE_ACCESS_CHANGED,
        reconnectService.enforceRouteAccess
      );
    });
  });

  describe('disconnect', () => {
    it('should remove event listeners', () => {
      reconnectService.disconnect();
      expect(window.removeEventListener).toHaveBeenCalledWith(
        'online',
        reconnectService.handleOnlineEvent
      );
      expect(emitter.off).toHaveBeenCalledWith(
        BUS_EVENTS.WEBSOCKET_RECONNECT,
        reconnectService.onReconnect
      );
      expect(emitter.off).toHaveBeenCalledWith(
        BUS_EVENTS.WEBSOCKET_DISCONNECT,
        reconnectService.onDisconnect
      );
    });
  });

  describe('getSecondsSinceDisconnect', () => {
    it('should return 0 if disconnectTime is null', () => {
      reconnectService.disconnectTime = null;
      expect(reconnectService.getSecondsSinceDisconnect()).toBe(0);
    });

    it('should return the number of seconds + threshold since disconnect', () => {
      reconnectService.disconnectTime = new Date();
      differenceInSeconds.mockReturnValue(100);
      expect(reconnectService.getSecondsSinceDisconnect()).toBe(100);
    });
  });

  describe('handleOnlineEvent', () => {
    it('should reload the page if disconnected for more than 3 hours', () => {
      reconnectService.getSecondsSinceDisconnect = vi
        .fn()
        .mockReturnValue(10801);
      reconnectService.handleOnlineEvent();
      expect(window.location.reload).toHaveBeenCalled();
    });

    it('should not reload the page if disconnected for less than 3 hours', () => {
      reconnectService.getSecondsSinceDisconnect = vi
        .fn()
        .mockReturnValue(10799);
      reconnectService.handleOnlineEvent();
      expect(window.location.reload).not.toHaveBeenCalled();
    });
  });

  describe('fetchConversations', () => {
    it('should dispatch updateChatListFilters and fetchAllConversations', async () => {
      await reconnectService.fetchConversations();
      expect(storeMock.dispatch).toHaveBeenCalledWith('updateChatListFilters', {
        page: 1,
        updatedWithin: null,
      });
      expect(storeMock.dispatch).toHaveBeenCalledWith('fetchAllConversations', {
        replaceExisting: true,
      });
    });
  });

  describe('fetchFilteredOrSavedConversations', () => {
    it('should dispatch fetchFilteredConversations', async () => {
      const payload = { test: 'data' };
      await reconnectService.fetchFilteredOrSavedConversations(payload);
      expect(storeMock.dispatch).toHaveBeenCalledWith(
        'fetchFilteredConversations',
        {
          queryData: payload,
          page: 1,
          replaceExisting: true,
        }
      );
    });
  });

  describe('fetchConversationsOnReconnect', () => {
    it('should fetch filtered or saved conversations if query exists', async () => {
      storeMock.getters.getAppliedConversationFiltersQuery = {
        payload: [
          {
            attribute_key: 'status',
            filter_operator: 'equal_to',
            values: ['open'],
          },
        ],
      };
      const spy = vi.spyOn(
        reconnectService,
        'fetchFilteredOrSavedConversations'
      );

      await reconnectService.fetchConversationsOnReconnect();

      expect(spy).toHaveBeenCalledWith(
        storeMock.getters.getAppliedConversationFiltersQuery
      );
    });

    it('should fetch all conversations if no query exists', async () => {
      storeMock.getters.getAppliedConversationFiltersQuery = [];
      storeMock.getters['customViews/getActiveConversationFolder'] = {
        query: null,
      };

      const spy = vi.spyOn(reconnectService, 'fetchConversations');

      await reconnectService.fetchConversationsOnReconnect();

      expect(spy).toHaveBeenCalled();
    });

    it('should fetch filtered or saved conversations if active folder query exists and no applied query', async () => {
      storeMock.getters.getAppliedConversationFiltersQuery = [];
      storeMock.getters['customViews/getActiveConversationFolder'] = {
        query: { test: 'activeFolderQuery' },
      };

      const spy = vi.spyOn(
        reconnectService,
        'fetchFilteredOrSavedConversations'
      );

      await reconnectService.fetchConversationsOnReconnect();

      expect(spy).toHaveBeenCalledWith({ test: 'activeFolderQuery' });
    });
  });

  describe('refreshActiveConversationOnReconnect', () => {
    it('should refresh the conversation and its messages if conversationId exists', async () => {
      routerMock.currentRoute.value.params.conversation_id = 1;
      await reconnectService.refreshActiveConversationOnReconnect();
      expect(storeMock.dispatch).toHaveBeenCalledWith('getConversation', 1);
      expect(storeMock.dispatch).toHaveBeenCalledWith(
        'syncActiveConversationMessages',
        { conversationId: 1 }
      );
    });

    it('should not dispatch syncActiveConversationMessages if conversationId does not exist', async () => {
      routerMock.currentRoute.value.params.conversation_id = null;
      await reconnectService.refreshActiveConversationOnReconnect();
      expect(storeMock.dispatch).not.toHaveBeenCalledWith(
        'getConversation',
        expect.anything()
      );
      expect(storeMock.dispatch).not.toHaveBeenCalledWith(
        'syncActiveConversationMessages',
        expect.anything()
      );
    });
  });

  describe('fetchNotificationsOnReconnect', () => {
    it('should dispatch notifications/index', async () => {
      const filter = { test: 'filter' };
      await reconnectService.fetchNotificationsOnReconnect(filter);
      expect(storeMock.dispatch).toHaveBeenCalledWith('notifications/index', {
        ...filter,
        page: 1,
      });
    });
  });

  describe('revalidateCaches', () => {
    it('should dispatch revalidate actions for labels, inboxes, and teams', async () => {
      storeMock.dispatch.mockResolvedValueOnce({
        label: 'labelKey',
        inbox: 'inboxKey',
        team: 'teamKey',
      });
      await reconnectService.revalidateCaches();
      expect(storeMock.dispatch).toHaveBeenCalledWith('accounts/getCacheKeys');
      expect(storeMock.dispatch).toHaveBeenCalledWith('labels/revalidate', {
        newKey: 'labelKey',
      });
      expect(storeMock.dispatch).toHaveBeenCalledWith('inboxes/revalidate', {
        newKey: 'inboxKey',
      });
      expect(storeMock.dispatch).toHaveBeenCalledWith('teams/revalidate', {
        newKey: 'teamKey',
      });
    });
  });

  describe('handleRouteSpecificFetch', () => {
    it('should fetch conversations and messages if current route is a conversation route', async () => {
      isAConversationRoute.mockReturnValue(true);
      const spyConversations = vi.spyOn(
        reconnectService,
        'fetchConversationsOnReconnect'
      );
      const spyActiveConversation = vi.spyOn(
        reconnectService,
        'refreshActiveConversationOnReconnect'
      );
      await reconnectService.handleRouteSpecificFetch();
      expect(spyConversations).toHaveBeenCalled();
      expect(spyActiveConversation).toHaveBeenCalled();
    });

    it('should fetch notifications if current route is an inbox view route', async () => {
      isAInboxViewRoute.mockReturnValue(true);
      const spy = vi.spyOn(reconnectService, 'fetchNotificationsOnReconnect');
      await reconnectService.handleRouteSpecificFetch();
      expect(spy).toHaveBeenCalled();
    });
  });

  describe('setConversationLastMessageId', () => {
    it('should dispatch setConversationLastMessageId if conversationId exists', async () => {
      routerMock.currentRoute.value.params.conversation_id = 1;
      await reconnectService.setConversationLastMessageId();
      expect(storeMock.dispatch).toHaveBeenCalledWith(
        'setConversationLastMessageId',
        { conversationId: 1 }
      );
    });

    it('should not dispatch setConversationLastMessageId if conversationId does not exist', async () => {
      routerMock.currentRoute.value.params.conversation_id = null;
      await reconnectService.setConversationLastMessageId();
      expect(storeMock.dispatch).not.toHaveBeenCalledWith(
        'setConversationLastMessageId',
        expect.anything()
      );
    });
  });

  describe('onDisconnect', () => {
    it('should set disconnectTime and call setConversationLastMessageId', () => {
      reconnectService.setConversationLastMessageId = vi.fn();
      reconnectService.onDisconnect();
      expect(reconnectService.disconnectTime).toBeInstanceOf(Date);
      expect(reconnectService.setConversationLastMessageId).toHaveBeenCalled();
    });
  });

  describe('enforceRouteAccess', () => {
    const accessRoute = {
      name: 'internal_chat_home',
      params: { accountId: 1 },
      meta: {},
    };

    let previousRoute;

    beforeEach(() => {
      previousRoute = routerMock.currentRoute.value;
      routerMock.currentRoute.value = accessRoute;
      routerMock.replace = vi.fn();
      storeMock.getters.getCurrentUser = {
        accounts: [{ id: 1, feature_access: ['internal_chat.access'] }],
      };
    });

    afterEach(() => {
      routerMock.currentRoute.value = previousRoute;
      delete routerMock.replace;
      delete storeMock.getters.getCurrentUser;
      storeMock.dispatch.mockReset();
    });

    it('reads the user again and leaves a route it no longer reaches', async () => {
      validateLoggedInRoutes.mockReturnValue('accounts/1/dashboard');

      await reconnectService.enforceRouteAccess();

      expect(storeMock.dispatch).toHaveBeenCalledWith('setUser');
      expect(validateLoggedInRoutes).toHaveBeenCalledWith(
        accessRoute,
        storeMock.getters.getCurrentUser
      );
      expect(routerMock.replace).toHaveBeenCalledWith(
        '/app/accounts/1/dashboard'
      );
    });

    it('stays on a route the member still reaches', async () => {
      validateLoggedInRoutes.mockReturnValue(null);

      await reconnectService.enforceRouteAccess();

      expect(routerMock.replace).not.toHaveBeenCalled();
    });

    it('drops the data of a feature the member lost, after leaving its route', async () => {
      const calls = [];
      validateLoggedInRoutes.mockReturnValue('accounts/1/dashboard');
      routerMock.replace = vi.fn(() => calls.push('replace'));
      storeMock.dispatch.mockImplementation(action => calls.push(action));
      storeMock.getters.getCurrentUser = {
        accounts: [{ id: 1, feature_access: [] }],
      };

      await reconnectService.enforceRouteAccess();

      expect(calls).toEqual([
        'setUser',
        'replace',
        'internalChat/reset',
        'internalChatTypingStatus/reset',
        'notifications/removeOfTypes',
      ]);
      expect(storeMock.dispatch).toHaveBeenCalledWith(
        'notifications/removeOfTypes',
        ['internal_chat_mention', 'internal_chat_new_message']
      );
    });

    it('keeps the data of a feature the member still has', async () => {
      validateLoggedInRoutes.mockReturnValue(null);
      storeMock.getters.getCurrentUser = {
        accounts: [{ id: 1, feature_access: ['internal_chat.access'] }],
      };

      await reconnectService.enforceRouteAccess();

      expect(storeMock.dispatch).not.toHaveBeenCalledWith('internalChat/reset');
    });

    it('runs on every reconnect', async () => {
      reconnectService.enforceRouteAccess = vi.fn();
      reconnectService.handleRouteSpecificFetch = vi.fn();
      reconnectService.revalidateCaches = vi.fn();

      await reconnectService.onReconnect();

      expect(reconnectService.enforceRouteAccess).toHaveBeenCalled();
    });
  });

  describe('onReconnect', () => {
    it('should handle route-specific fetch, revalidate caches, and emit WEBSOCKET_RECONNECT_COMPLETED event', async () => {
      reconnectService.handleRouteSpecificFetch = vi.fn();
      reconnectService.revalidateCaches = vi.fn();
      await reconnectService.onReconnect();
      expect(reconnectService.handleRouteSpecificFetch).toHaveBeenCalled();
      expect(reconnectService.revalidateCaches).toHaveBeenCalled();
      expect(emitter.emit).toHaveBeenCalledWith(
        BUS_EVENTS.WEBSOCKET_RECONNECT_COMPLETED
      );
    });
  });
});
