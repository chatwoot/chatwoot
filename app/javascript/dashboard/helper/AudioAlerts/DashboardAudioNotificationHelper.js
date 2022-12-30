import { MESSAGE_TYPE } from 'shared/constants/messages';
import { showBadgeOnFavicon } from './faviconHelper';
import { initFaviconSwitcher } from './faviconHelper';
import {
  getAlertAudio,
  initOnEvents,
} from 'shared/helpers/AudioNotificationHelper';

class DashboardAudioNotificationHelper {
  constructor() {
    this.recurringNotificationTimer = null;
    this.audioAlertType = 'none';
    this.playAlertOnlyWhenHidden = true;
    this.currentUserId = null;
    this.audioAlertTone = 'ding';
  }

  setInstanceValues = ({
    currentUserId,
    alwaysPlayAudioAlert,
    audioAlertType,
    audioAlertTone,
  }) => {
    this.audioAlertType = audioAlertType;
    this.playAlertOnlyWhenHidden = !alwaysPlayAudioAlert;
    this.currentUserId = currentUserId;
    this.audioAlertTone = audioAlertTone;
    initOnEvents.forEach(e => {
      document.addEventListener(e, this.onAudioListenEvent, false);
    });
    initFaviconSwitcher();
  };

  onAudioListenEvent = async () => {
    try {
      await getAlertAudio('', {
        type: 'dashboard',
        alertTone: this.audioAlertTone,
      });
      initOnEvents.forEach(event => {
        document.removeEventListener(event, this.onAudioListenEvent, false);
      });
    } catch (error) {
      // Ignore audio fetch errors
    }
  };

  isConversationAssignedToCurrentUser = message => {
    const conversationAssigneeId = message?.conversation?.assignee_id;
    return conversationAssigneeId === this.currentUserId;
  };

  isMessageFromCurrentConversation = message => {
    return (
      window.WOOT.$store.getters.getSelectedChat?.id === message.conversation_id
    );
  };

  isMessageFromCurrentUser = message => {
    return message?.sender_id === this.currentUserId;
  };

  shouldNotifyOnMessage = message => {
    if (this.audioAlertType === 'mine') {
      return this.isConversationAssignedToCurrentUser(message);
    }
    return this.audioAlertType === 'all';
  };

  onNewMessage = message => {
    // If the message is sent by the current user or the
    // correct notification is not enabled, then dismiss the alert
    if (
      this.isMessageFromCurrentUser(message) ||
      !this.shouldNotifyOnMessage(message)
    ) {
      return;
    }

    // If the message type is not incoming or private, then dismiss the alert
    const { message_type: messageType, private: isPrivate } = message;
    if (messageType !== MESSAGE_TYPE.INCOMING && !isPrivate) {
      return;
    }

    // If the user looking at the conversation, then dismiss the alert
    if (this.isMessageFromCurrentConversation(message) && !document.hidden) {
      return;
    }
    // If the user has disabled alerts when active on the dashboard, the dismiss the alert
    if (this.playAlertOnlyWhenHidden && !document.hidden) {
      return;
    }

    window.playAudioAlert();
    showBadgeOnFavicon();
  };
}

export default new DashboardAudioNotificationHelper();
