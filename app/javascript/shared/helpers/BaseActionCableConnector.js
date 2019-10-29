import { createConsumer } from '@rails/actioncable';

class BaseActionCableConnector {
  constructor(app, pubsubToken) {
    const consumer = createConsumer();
    consumer.subscriptions.create(
      {
        channel: 'RoomChannel',
        pubsub_token: pubsubToken,
      },
      {
        received: this.onReceived,
      }
    );
    this.app = app;
    this.events = {};
  }

  onReceived = ({ event, data } = {}) => {
    if (this.events[event] && typeof this.events[event] === 'function') {
      this.events[event](data);
    }
  };
}

export default BaseActionCableConnector;
