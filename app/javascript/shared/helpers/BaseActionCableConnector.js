import { createConsumer } from '@rails/actioncable';

const PRESENCE_INTERVAL = 5000;

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
        disconnected: this.onDisconnected,
      }
    );
    this.app = app;
    this.events = {};
    this.isAValidEvent = () => true;

    setInterval(() => {
      this.subscription.updatePresence();
      if (BaseActionCableConnector.isDisconnected && navigator.onLine) {
        this.refreshActiveConversationMessages();
        BaseActionCableConnector.isDisconnected = false;
      }
    }, PRESENCE_INTERVAL);
  }

  disconnect() {
    this.consumer.disconnect();
  }

  refreshActiveConversationMessages = () => {
    this.events['sync.active.conversation.messages']();
  };

  setActiveConversationLastMessage = () => {
    this.events['set.active.conversation.message']();
  };

  onDisconnected = () => {
    BaseActionCableConnector.isDisconnected = true;
    this.setActiveConversationLastMessage();
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
