import { BUS_EVENTS } from 'shared/constants/busEvents';
import { differenceInSeconds } from 'date-fns';
import {
  isAConversationRoute,
  isAInboxViewRoute,
  isNotificationRoute,
} from 'dashboard/helper/routeHelpers';

class ReconnectService {
  constructor(store, router) {
    this.store = store;
    this.router = router;
    this.disconnectTime = null;

    this.setupEventListeners();
  }

  disconnect = () => this.removeEventListeners();

  getSecondsSinceDisconnect = () =>
    this.disconnectTime
      ? Math.max(differenceInSeconds(new Date(), this.disconnectTime), 0)
      : 0;

  handleOnlineEvent = () => {
    if (this.getSecondsSinceDisconnect() >= 10800) window.location.reload(); // Force reload if the user is disconnected for more than 3 hours
  };

  fetchConversationsOnReconnect = async () => {
    await this.store.dispatch('updateChatListFilters', {
      page: null,
      updatedWithin: this.getSecondsSinceDisconnect(),
    });
    await this.store.dispatch('fetchAllConversations');
  };

  fetchFilteredOrSavedConversations = async payload => {
    await this.store.dispatch('fetchFilteredConversations', {
      queryData: payload,
      page: 1,
    });
  };

  fetchConversations = async () => {
    const {
      getAppliedConversationFiltersQuery,
      'customViews/getActiveConversationFolder': activeFolder,
    } = this.store.getters;
    const query = getAppliedConversationFiltersQuery.length
      ? getAppliedConversationFiltersQuery
      : activeFolder?.query;
    if (query) {
      await this.fetchFilteredOrSavedConversations(query);
    } else {
      await this.fetchConversationsOnReconnect();
    }
  };

  fetchConversationMessagesOnReconnect = async () => {
    const { conversation_id: conversationId } = this.router.currentRoute.params;
    if (conversationId) {
      await this.store.dispatch('syncActiveConversationMessages', {
        conversationId: Number(conversationId),
      });
    }
  };

  fetchInboxNotificationsOnReconnect = async () => {
    await this.store.dispatch('notifications/index', {
      ...this.filters,
      page: 1,
    });
  };

  fetchNotificationsOnReconnect = async () => {
    await this.store.dispatch('notifications/get', { page: 1 });
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
    const currentRoute = this.router.currentRoute.name;
    if (isAConversationRoute(currentRoute, true)) {
      await this.fetchConversations();
      await this.fetchConversationMessagesOnReconnect();
    } else if (isAInboxViewRoute(currentRoute, true)) {
      await this.fetchInboxNotificationsOnReconnect();
    } else if (isNotificationRoute(currentRoute)) {
      await this.fetchNotificationsOnReconnect();
    }
  };

  setConversationLastMessageId = async () => {
    const { conversation_id: conversationId } = this.router.currentRoute.params;
    if (conversationId) {
      await this.store.dispatch('setConversationLastMessageId', {
        conversationId: Number(conversationId),
      });
    }
  };

  onDisconnect = () => {
    this.disconnectTime = new Date();
    this.setConversationLastMessageId();
  };

  onReconnect = () => {
    this.handleRouteSpecificFetch();
    this.revalidateCaches();
    window.bus.$emit(BUS_EVENTS.WEBSOCKET_RECONNECT_COMPLETED);
  };

  setupEventListeners = () => {
    window.addEventListener('online', this.handleOnlineEvent);
    window.bus.$on(BUS_EVENTS.WEBSOCKET_RECONNECT, this.onReconnect);
    window.bus.$on(BUS_EVENTS.WEBSOCKET_DISCONNECT, this.onDisconnect);
  };

  removeEventListeners = () => {
    window.removeEventListener('online', this.handleOnlineEvent);
    window.bus.$off(BUS_EVENTS.WEBSOCKET_RECONNECT, this.onReconnect);
    window.bus.$off(BUS_EVENTS.WEBSOCKET_DISCONNECT, this.onDisconnect);
  };
}

export default ReconnectService;
