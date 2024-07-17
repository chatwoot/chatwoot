import { MESSAGE_TYPE } from 'shared/constants/messages';
import { showBadgeOnFavicon } from './faviconHelper';
import { initFaviconSwitcher } from './faviconHelper';
import {
  getAlertAudio,
  initOnEvents,
} from 'shared/helpers/AudioNotificationHelper';

const NOTIFICATION_TIME = 30000;

class DashboardAudioNotificationHelper {
  constructor() {
    this.recurringNotificationTimer = null;
    this.audioAlertType = 'none';
    this.playAlertOnlyWhenHidden = true;
    this.alertIfUnreadConversationExist = false;
    this.currentUserId = null;
    this.audioAlertTone = 'ding';
  }

  setInstanceValues = ({
    currentUserId,
    alwaysPlayAudioAlert,
    alertIfUnreadConversationExist,
    audioAlertType,
    audioAlertTone,
  }) => {
    this.audioAlertType = audioAlertType;
    this.playAlertOnlyWhenHidden = !alwaysPlayAudioAlert;
    this.alertIfUnreadConversationExist = alertIfUnreadConversationExist;
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
      this.playAudioEvery30Seconds();
    } catch (error) {
      // Ignore audio fetch errors
    }
  };

  executeRecurringNotification = () => {
    if (!window.WOOT || !window.WOOT.$store) {
      this.clearSetTimeout();
      return;
    }
    const mineConversation = window.WOOT.$store.getters.getMineChats({
      assigneeType: 'me',
      status: 'open',
    });
    const hasUnreadConversation = mineConversation.some(conv => {
      return conv.unread_count > 0;
    });

    const shouldPlayAlert = !this.playAlertOnlyWhenHidden || document.hidden;

    if (hasUnreadConversation && shouldPlayAlert) {
      window.playAudioAlert();
      showBadgeOnFavicon();
    }
    this.clearSetTimeout();
  };

  clearSetTimeout = () => {
    if (this.recurringNotificationTimer) {
      clearTimeout(this.recurringNotificationTimer);
    }
    this.recurringNotificationTimer = setTimeout(
      this.executeRecurringNotification,
      NOTIFICATION_TIME
    );
  };

  playAudioEvery30Seconds = () => {
    //  Audio alert is disabled dismiss the timer
    if (this.audioAlertType === 'none') {
      return;
    }
    // If assigned conversation flag is disabled dismiss the timer
    if (!this.alertIfUnreadConversationExist) {
      return;
    }

    this.clearSetTimeout();
  };

  isConversationAssignedToCurrentUser = message => {
    const conversationAssigneeId = message?.conversation?.assignee_id;
    return conversationAssigneeId === this.currentUserId;
  };

  // eslint-disable-next-line class-methods-use-this
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
    this.playAudioEvery30Seconds();
  };
}

export default new DashboardAudioNotificationHelper();
