import { emitter } from 'shared/helpers/mitt';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { differenceInSeconds } from 'date-fns';
import {
  isAConversationRoute,
  isAInboxViewRoute,
  validateLoggedInRoutes,
} from 'dashboard/helper/routeHelpers';
import { frontendURL } from 'dashboard/helper/URLHelper';
import { hasFeatureAccess } from 'dashboard/helper/permissionsHelper';
import { FEATURE_ACCESS_RESETS } from 'dashboard/constants/featureAccess';

const MAX_DISCONNECT_SECONDS = 10800;

class ReconnectService {
  constructor(store, router) {
    this.store = store;
    this.router = router;
    this.disconnectTime = null;

    this.setupEventListeners();
  }

  disconnect = () => this.removeEventListeners();

  setupEventListeners = () => {
    window.addEventListener('online', this.handleOnlineEvent);
    emitter.on(BUS_EVENTS.WEBSOCKET_RECONNECT, this.onReconnect);
    emitter.on(BUS_EVENTS.WEBSOCKET_DISCONNECT, this.onDisconnect);
    emitter.on(BUS_EVENTS.FEATURE_ACCESS_CHANGED, this.enforceRouteAccess);
  };

  removeEventListeners = () => {
    window.removeEventListener('online', this.handleOnlineEvent);
    emitter.off(BUS_EVENTS.WEBSOCKET_RECONNECT, this.onReconnect);
    emitter.off(BUS_EVENTS.WEBSOCKET_DISCONNECT, this.onDisconnect);
    emitter.off(BUS_EVENTS.FEATURE_ACCESS_CHANGED, this.enforceRouteAccess);
  };

  getSecondsSinceDisconnect = () =>
    this.disconnectTime
      ? Math.max(differenceInSeconds(new Date(), this.disconnectTime), 0)
      : 0;

  // Force reload if the user is disconnected for more than 3 hours
  handleOnlineEvent = () => {
    if (this.getSecondsSinceDisconnect() >= MAX_DISCONNECT_SECONDS) {
      window.location.reload();
    }
  };

  fetchConversations = async () => {
    await this.store.dispatch('updateChatListFilters', {
      page: 1,
      updatedWithin: null,
    });
    // Page 1 REPLACES the list rather than merging into it. The merge only ever adds or replaces,
    // so a conversation that left this tab while the socket was down would otherwise keep its
    // stale copy on screen; replacing is what takes it off.
    await this.store.dispatch('fetchAllConversations', {
      replaceExisting: true,
    });
  };

  // The store action applies the agent's sort itself, so page 1 here is page 1 of what they are
  // looking at, and `replaceExisting` swaps the list for it instead of merging a stale one.
  fetchFilteredOrSavedConversations = async queryData => {
    try {
      await this.store.dispatch('fetchFilteredConversations', {
        queryData,
        page: 1,
        replaceExisting: true,
      });
    } catch (error) {
      // Ignore error, reconnect flow should continue
    }
  };

  fetchConversationsOnReconnect = async () => {
    const {
      getAppliedConversationFiltersQuery,
      'customViews/getActiveConversationFolder': activeFolder,
    } = this.store.getters;
    const query = getAppliedConversationFiltersQuery?.payload?.length
      ? getAppliedConversationFiltersQuery
      : activeFolder?.query;
    if (query) {
      await this.fetchFilteredOrSavedConversations(query);
    } else {
      await this.fetchConversations();
    }
  };

  refreshActiveConversationOnReconnect = async () => {
    const { conversation_id: conversationId } =
      this.router.currentRoute.value.params;
    if (conversationId) {
      await this.store.dispatch('getConversation', Number(conversationId));
      await this.store.dispatch('syncActiveConversationMessages', {
        conversationId: Number(conversationId),
      });
    }
  };

  fetchNotificationsOnReconnect = async filter => {
    await this.store.dispatch('notifications/index', { ...filter, page: 1 });
  };

  revalidateCaches = async () => {
    const { label, inbox, team } = await this.store.dispatch(
      'accounts/getCacheKeys'
    );
    await Promise.all([
      this.store.dispatch('labels/revalidate', { newKey: label }),
      this.store.dispatch('inboxes/revalidate', { newKey: inbox }),
      this.store.dispatch('teams/revalidate', { newKey: team }),
    ]);
  };

  handleRouteSpecificFetch = async () => {
    const currentRoute = this.router.currentRoute.value.name;
    if (isAConversationRoute(currentRoute, true)) {
      await this.fetchConversationsOnReconnect();
      await this.refreshActiveConversationOnReconnect();
    } else if (isAInboxViewRoute(currentRoute, true)) {
      await this.fetchNotificationsOnReconnect(
        this.store.getters['notifications/getNotificationFilters']
      );
    }
  };

  setConversationLastMessageId = async () => {
    const { conversation_id: conversationId } =
      this.router.currentRoute.value.params;
    if (conversationId) {
      await this.store.dispatch('setConversationLastMessageId', {
        conversationId: Number(conversationId),
      });
    }
  };

  // What the member may reach can change while the socket was down (access to a gated feature,
  // for one), so the user is read again and a route it no longer reaches is left the way the
  // router guard would leave it. Also run when the server says the member's features changed.
  enforceRouteAccess = async () => {
    await this.store.dispatch('setUser');
    const route = this.router.currentRoute.value;
    if (!route.params?.accountId) return;

    const user = this.store.getters.getCurrentUser;
    const redirect = validateLoggedInRoutes(route, user);
    if (redirect) await this.router.replace(frontendURL(redirect));

    // Only once the screen is gone, so it cannot fetch the data back.
    Object.entries(FEATURE_ACCESS_RESETS).forEach(([capability, resets]) => {
      if (hasFeatureAccess(user, route.params.accountId, capability)) return;

      resets.forEach(([action, payload]) =>
        this.store.dispatch(action, payload)
      );
    });
  };

  onDisconnect = () => {
    this.disconnectTime = new Date();
    this.setConversationLastMessageId();
  };

  onReconnect = async () => {
    // A billing change while the cable was down loses its account.billing_updated
    // broadcast, and the focus listener never fires if the tab stayed focused.
    await this.store.dispatch('accounts/get', { silent: true });
    await this.enforceRouteAccess();
    await this.handleRouteSpecificFetch();
    await this.revalidateCaches();
    // Pin events that fired while the socket was down are lost, so the map is rebuilt from the server.
    await this.store.dispatch('conversationPins/fetch');
    emitter.emit(BUS_EVENTS.WEBSOCKET_RECONNECT_COMPLETED);
  };
}

export default ReconnectService;
