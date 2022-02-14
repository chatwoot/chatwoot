/* eslint-disable class-methods-use-this */
import { createConsumer } from '@rails/actioncable';

const PRESENCE_INTERVAL = 20000;

class BaseActionCableConnector {
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
        disconnected: this.onDisconnected,
        connected: this.onConnected,
      }
    );
    this.app = app;
    this.events = {};
    this.isAValidEvent = () => true;

    setInterval(() => {
      this.subscription.updatePresence();
    }, PRESENCE_INTERVAL);
  }

  // Called when the subscription is ready for use on the server.
  onConnected() {
    // eslint-disable-next-line no-console
    console.log('Action cable connected');
  }

  disconnect() {
    this.consumer.disconnect();
  }

  // Called when the WebSocket connection is closed.
  onDisconnected() {
    // eslint-disable-next-line no-console
    console.log('Action cable disconnected');
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
