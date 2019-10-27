import { createConsumer } from '@rails/actioncable';

import AuthAPI from '../api/auth';

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
      'conversation.created': this.onConversationCreated,
      'status_change:conversation': this.onStatusChange,
      'user:logout': this.onLogout,
      'page:reload': this.onReload,
      'assignee.changed': this.onAssigneeChanged,
    };
  }

  onAssigneeChanged = payload => {
    const { meta = {}, id } = payload;
    const { assignee } = meta || {};
    if (id) {
      this.app.$store.dispatch('updateAssignee', { id, assignee });
    }
  };

  onConversationCreated = data => {
    this.app.$store.dispatch('addConversation', data);
  };

  onLogout = () => AuthAPI.logout();

  onMessageCreated = data => {
    this.app.$store.dispatch('addMessage', data);
  };

  onReceived = ({ event, data } = {}) => {
    if (this.events[event]) {
      this.events[event](data);
    }
  };

  onReload = () => window.location.reload();

  onStatusChange = data => {
    this.app.$store.dispatch('addConversation', data);
  };
}

export default {
  init() {
    if (AuthAPI.isLoggedIn()) {
      const actionCable = new ActionCableConnector(
        window.WOOT,
        AuthAPI.getPubSubToken()
      );
      return actionCable;
    }
    return null;
  },
};
