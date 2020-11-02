import BaseActionCableConnector from '../../shared/helpers/BaseActionCableConnector';

class ActionCableConnector extends BaseActionCableConnector {
  constructor(app, pubsubToken) {
    super(app, pubsubToken);
    this.events = {
      'message.created': this.onMessageCreated,
      'message.updated': this.onMessageUpdated,
      'conversation.typing_on': this.onTypingOn,
      'conversation.typing_off': this.onTypingOff,
      'conversation.resolved': this.onStatusChange,
      'conversation.opened': this.onStatusChange,
      'presence.update': this.onPresenceUpdate,
    };
  }

  onStatusChange = data => {
    this.app.$store.dispatch('conversationAttributes/update', data);
  };

  onMessageCreated = data => {
    this.app.$store.dispatch('conversation/addMessage', data).then(() => {
      window.bus.$emit('on-agent-message-recieved');
    });
  };

  onMessageUpdated = data => {
    this.app.$store.dispatch('conversation/updateMessage', data);
  };

  onPresenceUpdate = data => {
    this.app.$store.dispatch('agent/updatePresence', data.users);
  };

  onTypingOn = ({ conversation = {} }) => {
    this.clearTimer();
    this.app.$store.dispatch('conversation/toggleAgentTyping', {
      status: 'on',
      conversationId: conversation.id,
    });
    this.initTimer({ conversation });
  };

  onTypingOff = ({ conversation = {} }) => {
    this.clearTimer();
    this.app.$store.dispatch('conversation/toggleAgentTyping', {
      status: 'off',
      conversationId: conversation.id,
    });
  };

  clearTimer = () => {
    if (this.CancelTyping) {
      clearTimeout(this.CancelTyping);
      this.CancelTyping = null;
    }
  };

  initTimer = ({ conversation }) => {
    // Turn off typing automatically after 30 seconds
    this.CancelTyping = setTimeout(() => {
      this.onTypingOff({ conversation });
    }, 30000);
  };
}

export const refreshActionCableConnector = pubsubToken => {
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

export default ActionCableConnector;
