import {
  IFrameHelper,
  isMultipleConversationsEnabled,
} from 'widget/helpers/utils';
import { playNewMessageNotificationInWidget } from 'widget/helpers/WidgetAudioNotificationHelper';
import BaseActionCableConnector from '../../shared/helpers/BaseActionCableConnector';
import { emitter } from '../../shared/helpers/mitt';
import { CHATWOOT_ON_MESSAGE } from '../constants/sdkEvents';
import { ON_AGENT_MESSAGE_RECEIVED } from '../constants/widgetBusEvents';
import { shouldTriggerMessageUpdateEvent } from './IframeEventHelper';
import { MESSAGE_TYPE } from './constants';

const isMessageInActiveConversation = (getters, message) => {
  const { conversation_id: conversationId } = message;
  const activeConversationId =
    getters['conversationAttributes/getConversationParams'].id;
  if (isMultipleConversationsEnabled()) {
    return conversationId !== activeConversationId;
  }
  return activeConversationId && conversationId !== activeConversationId;
};

const WIDGET_PRESENCE_INTERVAL = 60000;

class ActionCableConnector extends BaseActionCableConnector {
  constructor(app, pubsubToken) {
    super(app, pubsubToken, '', WIDGET_PRESENCE_INTERVAL);
    this.events = {
      'message.created': this.onMessageCreated,
      'message.updated': this.onMessageUpdated,
      'conversation.typing_on': this.onTypingOn,
      'conversation.typing_off': this.onTypingOff,
      'conversation.status_changed': this.onStatusChange,
      'conversation.created': this.onConversationCreated,
      'presence.update': this.onPresenceUpdate,
      'contact.merged': this.onContactMerge,
    };
  }

  onDisconnected = () => {
    this.setLastMessageId();
  };

  onReconnect = () => {
    this.syncLatestMessages();
    // Re-fetch conversation attributes so a status change (e.g. auto-resolve)
    // that happened while disconnected is reflected, keeping the reply box state correct.
    this.app.$store.dispatch('conversationAttributes/getAttributes');
    this.refreshConversationList();
  };

  refreshConversationList = () => {
    if (!isMultipleConversationsEnabled()) return;
    this.app.$store.dispatch('conversationList/fetch');
  };

  // A message for another conversation takes over the screen only when nothing is being viewed.
  showsInActiveConversation = message => {
    const { getters, dispatch } = this.app.$store;
    const activeConversationId =
      getters['conversationAttributes/getConversationParams'].id;
    if (message.conversation_id === activeConversationId) return true;
    if (!isMultipleConversationsEnabled()) return !activeConversationId;

    // The new thread on screen is still being saved, so this is the conversation it became.
    if (!activeConversationId && getters['conversation/getIsCreating']) {
      dispatch('conversationList/attach', message.conversation_id);
      return true;
    }
    // Only replies take over the screen; the visitor's own messages from elsewhere never do.
    const isViewingConversation =
      activeConversationId &&
      (getters['appConfig/getIsWidgetOpen'] || !IFrameHelper.isIFrame());
    if (
      isViewingConversation ||
      message.message_type === MESSAGE_TYPE.INCOMING
    ) {
      dispatch('conversationList/fetch');
      return false;
    }
    dispatch('conversationList/open', message.conversation_id);
    return true;
  };

  setLastMessageId = () => {
    this.app.$store.dispatch('conversation/setLastMessageId');
  };

  syncLatestMessages = () => {
    this.app.$store.dispatch('conversation/syncLatestMessages');
  };

  onStatusChange = data => {
    if (data.status === 'resolved') {
      this.app.$store.dispatch('campaign/resetCampaign');
    }
    this.app.$store.dispatch('conversationAttributes/update', data);
    this.refreshConversationList();
  };

  onMessageCreated = data => {
    const showsInActiveConversation = this.showsInActiveConversation(data);
    if (!showsInActiveConversation && !isMultipleConversationsEnabled()) return;

    if (showsInActiveConversation) {
      this.app.$store.dispatch('conversationList/updateLastMessage', data);
      this.app.$store
        .dispatch('conversation/addOrUpdateMessage', data)
        .then(() => emitter.emit(ON_AGENT_MESSAGE_RECEIVED));
    }

    IFrameHelper.sendMessage({
      event: 'onEvent',
      eventIdentifier: CHATWOOT_ON_MESSAGE,
      data,
    });
    if (data.sender_type === 'User') {
      playNewMessageNotificationInWidget();
    }
  };

  onMessageUpdated = data => {
    if (isMessageInActiveConversation(this.app.$store.getters, data)) {
      return;
    }

    if (shouldTriggerMessageUpdateEvent(data)) {
      IFrameHelper.sendMessage({
        event: 'onEvent',
        eventIdentifier: CHATWOOT_ON_MESSAGE,
        data,
      });
    }

    this.app.$store.dispatch('conversation/addOrUpdateMessage', data);
  };

  onConversationCreated = () => {
    if (isMultipleConversationsEnabled()) {
      this.refreshConversationList();
      return;
    }
    this.app.$store.dispatch('conversationAttributes/getAttributes');
  };

  onPresenceUpdate = data => {
    this.app.$store.dispatch('agent/updatePresence', data.users);
  };

  // eslint-disable-next-line class-methods-use-this
  onContactMerge = data => {
    const { pubsub_token: pubsubToken } = data;
    ActionCableConnector.refreshConnector(pubsubToken);
  };

  isTypingInAnotherConversation = data => {
    const activeConversationId =
      this.app.$store.getters['conversationAttributes/getConversationParams']
        .id;
    return data?.conversation && data.conversation.id !== activeConversationId;
  };

  onTypingOn = data => {
    if (this.isTypingInAnotherConversation(data) || data.is_private) {
      return;
    }
    this.clearTimer();
    this.app.$store.dispatch('conversation/toggleAgentTyping', {
      status: 'on',
    });
    this.initTimer();
  };

  onTypingOff = data => {
    if (this.isTypingInAnotherConversation(data)) return;
    this.clearTimer();
    this.app.$store.dispatch('conversation/toggleAgentTyping', {
      status: 'off',
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

export default ActionCableConnector;
