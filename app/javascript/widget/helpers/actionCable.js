import BaseActionCableConnector from '../../shared/helpers/BaseActionCableConnector';

class ActionCableConnector extends BaseActionCableConnector {
  constructor(app, pubsubToken) {
    super(app, pubsubToken);
    this.events = {
      'message.created': this.onMessageCreated,
      'message.updated': this.onMessageUpdated,
    };
  }

  onMessageCreated = data => {
    this.app.$store.dispatch('conversation/addMessage', data);
  };

  onMessageUpdated = data => {
    this.app.$store.dispatch('conversation/updateMessage', data);
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
