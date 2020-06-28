import { createConsumer } from '@rails/actioncable';

const ONE_MINUTE = 60000;
class BaseActionCableConnector {
  constructor(app, pubsubToken) {
    this.consumer = createConsumer();
    this.subscription = this.consumer.subscriptions.create(
      {
        channel: 'RoomChannel',
        pubsub_token: pubsubToken,
      },
      {
        updatePresence() {
          this.perform('update_presence');
        },
        received: this.onReceived,
      }
    );
    this.app = app;
    this.events = {};
    this.isAValidEvent = () => true;

    setInterval(() => {
      this.subscription.updatePresence();
    }, ONE_MINUTE);
  }

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
