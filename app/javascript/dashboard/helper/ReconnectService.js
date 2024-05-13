import { BUS_EVENTS } from 'shared/constants/busEvents';
import { differenceInSeconds } from 'date-fns';
import {
  isAConversationRoute,
  isAInboxViewRoute,
  isNotificationRoute,
} from 'dashboard/helper/routeHelpers';

export default class ReconnectService {
  static instance;

  constructor(store, bus, route, filters) {
    this.store = store;
    this.bus = bus;
    this.route = route;
    this.filters = filters || {};
    this.disconnectTime = null;
  }

  static getInstance(store, bus, route, filters) {
    if (!ReconnectService.instance) {
      ReconnectService.instance = new ReconnectService(
        store,
        bus,
        route,
        filters
      );
    }
    return ReconnectService.instance;
  }

  setDisconnectTime() {
    this.disconnectTime = new Date();
  }

  resetDisconnectTime() {
    this.disconnectTime = null;
  }

  isChatListLoading() {
    return this.store.getters.getChatListLoadingStatus;
  }

  getSecondsSinceDisconnect() {
    return this.disconnectTime
      ? Math.max(differenceInSeconds(new Date(), this.disconnectTime), 0)
      : 0;
  }

  handleOnlineEvent() {
    // if the disconnect time is greater than 3 hours, reload the page
    // if the disconnect time is less than 3 hours, fetch the conversations/notifications
    const seconds = this.getSecondsSinceDisconnect();
    const threshold = 3 * 3600; // 3 hours
    if (seconds >= threshold) {
      // 10800 seconds equals 3 hours
      window.location.reload();
      this.resetDisconnectTime();
    }
  }

  async fetchConversationsOnReconnect() {
    if (this.isChatListLoading()) {
      return;
    }
    try {
      const filters = {
        ...this.filters,
        page: null,
        updatedWithin: this.getSecondsSinceDisconnect(),
      };
      await this.store.dispatch('fetchAllConversations', filters);
    } catch (error) {
      // error
    } finally {
      this.bus.$emit(BUS_EVENTS.WEBSOCKET_RECONNECT_COMPLETED);
    }
  }

  async fetchInboxNotificationsOnReconnect() {
    try {
      const filter = {
        ...this.filters,
        page: 1,
      };
      this.store.dispatch('notifications/index', filter);
    } catch (error) {
      // error
    } finally {
      this.bus.$emit(BUS_EVENTS.WEBSOCKET_RECONNECT_COMPLETED);
    }
  }

  async fetchNotificationsOnReconnect() {
    try {
      this.store.dispatch('notifications/get', { page: 1 });
    } catch (error) {
      // error
    } finally {
      this.bus.$emit(BUS_EVENTS.WEBSOCKET_RECONNECT_COMPLETED);
    }
  }

  async fetchOnReconnect() {
    // if the disconnect time is greater than 3 hours, reload the page
    // if the disconnect time is less than 3 hours, fetch the conversations/notifications
    if (isAConversationRoute(this.route.name, true)) {
      await this.fetchConversationsOnReconnect();
    } else if (isAInboxViewRoute(this.route.name, true)) {
      await this.fetchInboxNotificationsOnReconnect();
    } else if (isNotificationRoute(this.route.name)) {
      await this.fetchNotificationsOnReconnect();
    }
  }

  setupEventListeners() {
    // Added the online event listener, to handle the case where the user
    // goes online for three hours and then back online, to force reload the page
    window.addEventListener('online', () => this.handleOnlineEvent());
    this.bus.$on(BUS_EVENTS.WEBSOCKET_RECONNECT, () => this.fetchOnReconnect());
    this.bus.$on(BUS_EVENTS.WEBSOCKET_DISCONNECT, () =>
      this.setDisconnectTime()
    );
  }

  removeEventListeners() {
    window.removeEventListener('online', () => this.handleOnlineEvent());
    this.bus.$off(BUS_EVENTS.WEBSOCKET_RECONNECT, () =>
      this.fetchOnReconnect()
    );
    this.bus.$off(BUS_EVENTS.WEBSOCKET_DISCONNECT, () =>
      this.resetDisconnectTime()
    );
  }
}
