import BaseActionCableConnector from '../../shared/helpers/BaseActionCableConnector';

class ActionCableConnector extends BaseActionCableConnector {
  constructor(app, pubsubToken) {
    super(app, pubsubToken);
    this.events = {
      'message.created': this.onMessageCreated,
      'message.updated': this.onMessageUpdated,
      'conversation.typing_on': this.onTypingOn,
      'conversation.typing_off': this.onTypingOff,
    };
  }

  onMessageCreated = data => {
    this.app.$store.dispatch('conversation/addMessage', data);
  };

  onMessageUpdated = data => {
    this.app.$store.dispatch('conversation/updateMessage', data);
  };

  onTypingOn = () => {
    this.app.$store.dispatch('conversation/toggleAgentTyping', {
      status: 'on',
    });
    // Turn off typing automatically after 30 seconds
    setTimeout(() => {
      this.app.$store.dispatch('conversation/toggleAgentTyping', {
        status: 'off',
      });
    }, 30000);
  };

  onTypingOff = () => {
    this.app.$store.dispatch('conversation/toggleAgentTyping', {
      status: 'off',
    });
  };
}

export const refreshActionCableConnector = pubsubToken => {
  if (!pubsubToken) {
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
