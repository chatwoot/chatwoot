import { emitter } from 'shared/helpers/mitt';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { differenceInSeconds } from 'date-fns';
import {
  isAConversationRoute,
  isAInboxViewRoute,
  isNotificationRoute,
} from 'dashboard/helper/routeHelpers';

const MAX_DISCONNECT_SECONDS = 10800;

// The disconnect delay threshold is added to account for delays in identifying
// disconnections (for example, the websocket disconnection takes up to 3 seconds)
// while fetching the latest updated conversations or messages.
const DISCONNECT_DELAY_THRESHOLD = 15;

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
  };

  removeEventListeners = () => {
    window.removeEventListener('online', this.handleOnlineEvent);
    emitter.off(BUS_EVENTS.WEBSOCKET_RECONNECT, this.onReconnect);
    emitter.off(BUS_EVENTS.WEBSOCKET_DISCONNECT, this.onDisconnect);
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
      page: null,
      updatedWithin:
        this.getSecondsSinceDisconnect() + DISCONNECT_DELAY_THRESHOLD,
    });
    await this.store.dispatch('fetchAllConversations');
    // Reset the updatedWithin in the store chat list filter after fetching conversations when the user is reconnected
    await this.store.dispatch('updateChatListFilters', {
      updatedWithin: null,
    });
  };

  fetchFilteredOrSavedConversations = async queryData => {
    await this.store.dispatch('fetchFilteredConversations', {
      queryData,
      page: 1,
    });
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

  fetchConversationMessagesOnReconnect = async () => {
    const { conversation_id: conversationId } =
      this.router.currentRoute.value.params;
    if (conversationId) {
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
      await this.fetchConversationMessagesOnReconnect();
    } else if (isAInboxViewRoute(currentRoute, true)) {
      await this.fetchNotificationsOnReconnect(
        this.store.getters['notifications/getNotificationFilters']
      );
    } else if (isNotificationRoute(currentRoute)) {
      await this.fetchNotificationsOnReconnect();
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

  onDisconnect = () => {
    this.disconnectTime = new Date();
    this.setConversationLastMessageId();
  };

  onReconnect = async () => {
    await this.handleRouteSpecificFetch();
    await this.revalidateCaches();
    emitter.emit(BUS_EVENTS.WEBSOCKET_RECONNECT_COMPLETED);
  };
}

export default ReconnectService;
