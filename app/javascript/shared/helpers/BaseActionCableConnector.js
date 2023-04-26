import { createConsumer } from '@rails/actioncable';
import { BUS_EVENTS } from 'shared/constants/busEvents';

const PRESENCE_INTERVAL = 20000;

class BaseActionCableConnector {
  static isDisconnected = false;

  constructor(app, pubsubToken, websocketHost = '') {
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
          // TODO: Remove this after completing the conversation list refetching
          window.bus.$emit(BUS_EVENTS.WEBSOCKET_DISCONNECT);
        },
      }
    );
    this.app = app;
    this.events = {};
    this.isAValidEvent = () => true;
    this.triggerPresenceInterval = () => {
      setTimeout(() => {
        this.subscription.updatePresence();
        this.checkConnection();
        this.triggerPresenceInterval();
      }, PRESENCE_INTERVAL);
    };
    this.triggerPresenceInterval();
  }

  checkConnection() {
    const isConnectionActive = this.consumer.connection.isOpen();
    const isReconnected =
      BaseActionCableConnector.isDisconnected && isConnectionActive;
    console.log('isReconnected', isReconnected);

    if (isReconnected) {
      this.onReconnect();
      BaseActionCableConnector.isDisconnected = false;
    }
  }

  onReconnect = () => {};

  onDisconnected = () => {};

  disconnect() {
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
