import BaseActionCableConnector from '../../shared/helpers/BaseActionCableConnector';
import { playNewMessageNotificationInWidget } from 'shared/helpers/AudioNotificationHelper';

class ActionCableConnector extends BaseActionCableConnector {
  constructor(app, pubsubToken) {
    super(app, pubsubToken);
    this.events = {
      'message.created': this.onMessageCreated,
      'message.updated': this.onMessageUpdated,
      'conversation.created': this.onConversationCreated,
      'conversation.typing_on': this.onTypingOn,
      'conversation.typing_off': this.onTypingOff,
      'conversation.status_changed': this.onStatusChange,
      'presence.update': this.onPresenceUpdate,
      'contact.merged': this.onContactMerge,
    };
  }

  static refreshConnector = pubsubToken => {
    if (!pubsubToken || window.chatwootPubsubToken === pubsubToken) {
      return;
    }
    window.chatwootPubsubToken = pubsubToken;
    window.actionCable.disconnect();
    window.actionCable = new ActionCableConnector(
      window.WOOT_WIDGET,
      window.chatwootPubsubToken
    );
  };

  onStatusChange = data => {
    const { status, id: conversationId } = data;
    this.app.$store.dispatch('conversation/setConversationStatusIn', {
      status,
      conversationId,
    });
  };

  onConversationCreated = data => {
    this.app.$store.dispatch('conversation/addConversation', data);
  };

  onMessageCreated = data => {
    this.app.$store.dispatch('message/addOrUpdate', data).then(() => {
      window.bus.$emit('on-agent-message-received');
    });
    if (data.sender_type === 'User') {
      playNewMessageNotificationInWidget();
    }
  };

  onMessageUpdated = data => {
    this.app.$store.dispatch('message/addOrUpdate', data).then(() => {
      window.bus.$emit('on-agent-message-received');
    });
  };

  onPresenceUpdate = data => {
    this.app.$store.dispatch('agent/updatePresence', data.users);
  };

  onContactMerge = data => {
    const { pubsub_token: pubsubToken } = data;
    ActionCableConnector.refreshConnector(pubsubToken);
  };

  onTypingOn = data => {
    if (data.is_private) {
      return;
    }
    this.clearTimer();
    const {
      conversation: { id: conversationId },
    } = data;
    this.app.$store.dispatch('conversation/toggleAgentTypingIn', {
      status: 'on',
      conversationId,
    });
    this.initTimer();
  };

  onTypingOff = data => {
    this.clearTimer();
    const {
      conversation: { id: conversationId },
    } = data;
    this.app.$store.dispatch('conversation/toggleAgentTypingIn', {
      status: 'off',
      conversationId,
    });
  };

  clearTimer = () => {
    if (this.CancelTyping) {
      clearTimeout(this.CancelTyping);
      this.CancelTyping = null;
    }
  };

  initTimer = () => {
    // Turn off typing automatically after 30 seconds
    this.CancelTyping = setTimeout(() => {
      this.onTypingOff();
    }, 30000);
  };
}

export const refreshActionCableConnector =
  ActionCableConnector.refreshConnector;

export default ActionCableConnector;
