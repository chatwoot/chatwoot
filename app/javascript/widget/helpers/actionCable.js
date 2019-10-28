import { createConsumer } from '@rails/actioncable';

class ActionCableConnector {
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
    this.events = {
      'message.created': this.onMessageCreated,
    };
  }

  onMessageCreated = data => {
    this.app.$store.dispatch('conversation/addMessage', data);
  };

  onReceived = ({ event, data } = {}) => {
    if (this.events[event]) {
      this.events[event](data);
    }
  };
}

export default ActionCableConnector;
