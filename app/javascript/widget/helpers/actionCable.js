import BaseActionCableConnector from '../../shared/helpers/BaseActionCableConnector';

class ActionCableConnector extends BaseActionCableConnector {
  constructor(app, pubsubToken) {
    super(app, pubsubToken);
    this.events = {
      'message.created': this.onMessageCreated,
    };
    console.log('joined', app, pubsubToken);
  }

  onMessageCreated = data => {
    this.app.$store.dispatch('conversation/addMessage', data);
  };
}

export default ActionCableConnector;
