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
    if (this.getSecondsSinceDisconnect() >= 3 * 3600) window.location.reload();
  };

  fetchConversationsOnReconnect = async () => {
    try {
      await this.store.dispatch('updateChatListFilters', {
        page: null,
        updatedWithin: this.getSecondsSinceDisconnect(),
      });
      await this.store.dispatch('fetchAllConversations');
    } finally {
      window.bus.$emit(BUS_EVENTS.WEBSOCKET_RECONNECT_COMPLETED);
    }
  };

  fetchFilteredOrSavedConversations = async payload => {
    try {
      await this.store.dispatch('fetchFilteredConversations', {
        queryData: payload,
        page: 1,
      });
    } finally {
      window.bus.$emit(BUS_EVENTS.WEBSOCKET_RECONNECT_COMPLETED);
    }
  };

  fetchConversations = async () => {
    const {
      getAppliedConversationFiltersQuery,
      'customViews/getActiveConversationFolder': activeFolder,
    } = this.store.getters;
    const hasActiveFilters = getAppliedConversationFiltersQuery.length !== 0;
    const hasActiveFolder = activeFolder !== null;

    const query = hasActiveFilters
      ? getAppliedConversationFiltersQuery
      : activeFolder?.query;
    await (hasActiveFilters || hasActiveFolder
      ? this.fetchFilteredOrSavedConversations(query)
      : this.fetchConversationsOnReconnect());
  };

  fetchInboxNotificationsOnReconnect = async () => {
    try {
      await this.store.dispatch('notifications/index', {
        ...this.filters,
        page: 1,
      });
    } finally {
      window.bus.$emit(BUS_EVENTS.WEBSOCKET_RECONNECT_COMPLETED);
    }
  };

  fetchNotificationsOnReconnect = async () => {
    try {
      await this.store.dispatch('notifications/get', { page: 1 });
    } finally {
      window.bus.$emit(BUS_EVENTS.WEBSOCKET_RECONNECT_COMPLETED);
    }
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
    } else if (isAInboxViewRoute(currentRoute, true)) {
      await this.fetchInboxNotificationsOnReconnect();
    } else if (isNotificationRoute(currentRoute)) {
      await this.fetchNotificationsOnReconnect();
    }
  };

  onDisconnect = () => {
    this.disconnectTime = new Date();
  };

  onReconnect = () => {
    this.handleRouteSpecificFetch();
    this.revalidateCaches();
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
