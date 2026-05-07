import { createConsumer } from '@rails/actioncable';

const PRESENCE_INTERVAL = 20000;
const RECONNECT_INTERVAL = 1000;
// Delay after the page becomes visible before validating the websocket.
// Gives iOS time to restore radios/throttled timers.
const VISIBILITY_RECHECK_DELAY = 200;

class BaseActionCableConnector {
  static isDisconnected = false;

  constructor(
    app,
    pubsubToken,
    websocketHost = '',
    presenceInterval = PRESENCE_INTERVAL
  ) {
    const websocketURL = websocketHost ? `${websocketHost}/cable` : undefined;

    this.consumer = createConsumer(websocketURL);
    this.subscription = this.consumer.subscriptions.create(
      {
        channel: 'RoomChannel',
        pubsub_token: pubsubToken,
        account_id: app.$store.getters.getCurrentAccountId,
        user_id: app.$store.getters.getCurrentUserID,
      },
      {
        updatePresence() {
          this.perform('update_presence');
        },
        received: this.onReceived,
        disconnected: () => {
          BaseActionCableConnector.isDisconnected = true;
          this.onDisconnected();
          this.initReconnectTimer();
        },
      }
    );
    this.app = app;
    this.events = {};
    this.reconnectTimer = null;
    this.visibilityCheckTimer = null;
    this.isAValidEvent = () => true;
    this.triggerPresenceInterval = () => {
      setTimeout(() => {
        this.subscription.updatePresence();
        this.triggerPresenceInterval();
      }, presenceInterval);
    };
    this.triggerPresenceInterval();
    this.setupNetworkListeners();
  }

  checkConnection() {
    const isConnectionActive = this.consumer.connection.isOpen();
    const isReconnected =
      BaseActionCableConnector.isDisconnected && isConnectionActive;
    if (isReconnected) {
      this.clearReconnectTimer();
      this.onReconnect();
      BaseActionCableConnector.isDisconnected = false;
    } else {
      this.initReconnectTimer();
    }
  }

  clearReconnectTimer = () => {
    if (this.reconnectTimer) {
      clearTimeout(this.reconnectTimer);
      this.reconnectTimer = null;
    }
  };

  initReconnectTimer = () => {
    this.clearReconnectTimer();
    this.reconnectTimer = setTimeout(() => {
      this.checkConnection();
    }, RECONNECT_INTERVAL);
  };

  // eslint-disable-next-line class-methods-use-this
  onReconnect = () => {};

  // eslint-disable-next-line class-methods-use-this
  onDisconnected = () => {};

  setupNetworkListeners = () => {
    if (typeof document === 'undefined' || typeof window === 'undefined') {
      return;
    }
    this.handleVisibilityChange = () => {
      if (document.visibilityState !== 'visible') return;
      this.scheduleVisibilityRecheck();
    };
    this.handleFocus = () => this.scheduleVisibilityRecheck();
    this.handleOnline = () => this.scheduleVisibilityRecheck();
    document.addEventListener('visibilitychange', this.handleVisibilityChange);
    window.addEventListener('focus', this.handleFocus);
    window.addEventListener('online', this.handleOnline);
    window.addEventListener('pageshow', this.handleFocus);
  };

  removeNetworkListeners = () => {
    if (typeof document === 'undefined' || typeof window === 'undefined') {
      return;
    }
    if (this.handleVisibilityChange) {
      document.removeEventListener(
        'visibilitychange',
        this.handleVisibilityChange
      );
    }
    if (this.handleFocus) {
      window.removeEventListener('focus', this.handleFocus);
      window.removeEventListener('pageshow', this.handleFocus);
    }
    if (this.handleOnline) {
      window.removeEventListener('online', this.handleOnline);
    }
    if (this.visibilityCheckTimer) {
      clearTimeout(this.visibilityCheckTimer);
      this.visibilityCheckTimer = null;
    }
  };

  scheduleVisibilityRecheck = () => {
    if (this.visibilityCheckTimer) {
      clearTimeout(this.visibilityCheckTimer);
    }
    this.visibilityCheckTimer = setTimeout(() => {
      this.visibilityCheckTimer = null;
      this.refreshConnection();
    }, VISIBILITY_RECHECK_DELAY);
  };

  // Force-validate the websocket. iOS Safari (esp. PWA standalone) can
  // silently kill long-lived sockets while throttled in background; the
  // ActionCable monitor runs on a setInterval that is paused while hidden,
  // so connectionIsStale() is not re-evaluated for several seconds after
  // the app comes back. Triggering reopen() here recovers immediately.
  refreshConnection = () => {
    try {
      const connection = this.consumer && this.consumer.connection;
      if (!connection) return;

      const isOpen =
        typeof connection.isOpen === 'function' && connection.isOpen();

      if (!isOpen) {
        if (typeof connection.open === 'function') {
          connection.open();
        }
        return;
      }

      const monitor = connection.monitor;
      const isStale =
        monitor &&
        typeof monitor.connectionIsStale === 'function' &&
        monitor.connectionIsStale();

      if (isStale && typeof connection.reopen === 'function') {
        connection.reopen();
      }
    } catch (_e) {
      // Defensive: never let a recheck throw.
    }
  };

  disconnect() {
    this.removeNetworkListeners();
    this.consumer.disconnect();
  }

  onReceived = ({ event, data } = {}) => {
    if (this.isAValidEvent(data)) {
      if (this.events[event] && typeof this.events[event] === 'function') {
        this.events[event](data);
      }
    }
  };
}

export default BaseActionCableConnector;
