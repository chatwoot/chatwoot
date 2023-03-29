import { createConsumer } from '@rails/actioncable';

const PRESENCE_INTERVAL = 20000;

class BaseActionCableConnector {
  constructor(app, pubsubToken, websocketHost = '') {
    const websocketURL = websocketHost ? `${websocketHost}/cable` : undefined;
    this.consumer = createConsumer(websocketURL);
    let isDisconnected = false;
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
        disconnected() {
          isDisconnected = true;
          console.log('Disconnected from ActionCable', isDisconnected);
        },
      }
    );
    this.app = app;
    this.events = {};
    this.isAValidEvent = () => true;

    setInterval(() => {
      this.subscription.updatePresence();
      if (isDisconnected && navigator.onLine) {
        console.log(
          'Are you ready to refresh the conversation?',
          isDisconnected
        );
        this.refreshConversations();
        isDisconnected = false;
      }
    }, PRESENCE_INTERVAL);
  }

  disconnect() {
    this.consumer.disconnect();
  }

  refreshConversations = () => {
    this.events['refresh.conversations']();
  };

  onReceived = ({ event, data } = {}) => {
    if (this.isAValidEvent(data)) {
      if (this.events[event] && typeof this.events[event] === 'function') {
        this.events[event](data);
      }
    }
  };
}

export default BaseActionCableConnector;
