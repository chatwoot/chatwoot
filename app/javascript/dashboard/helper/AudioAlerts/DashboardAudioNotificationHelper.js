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
    this.playAudioAlertUntilAllConversationsAreRead = false;
    this.currentUserId = null;
    this.audioAlertTone = 'ding';
    this.timer = null;
  }

  setInstanceValues = ({
    currentUserId,
    alwaysPlayAudioAlert,
    playAudioUntilAllConversationsAreRead,
    audioAlertType,
    audioAlertTone,
  }) => {
    this.audioAlertType = audioAlertType;
    this.playAlertOnlyWhenHidden = !alwaysPlayAudioAlert;
    this.playAudioAlertUntilAllConversationsAreRead = playAudioUntilAllConversationsAreRead;
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

  clearSetTimeout = () => {
    if (this.timer) {
      clearTimeout(this.timer);
    }
  };

  playAudioEvery30Seconds = () => {
    if (
      this.playAudioAlertUntilAllConversationsAreRead &&
      this.audioAlertType !== 'none'
    ) {
      const TIME = 30000;
      const {
        enable_audio_alerts: enableAudioAlerts = false,
        play_audio_until_all_conversations_are_read: playAudioUntilAllConversationsAreRead,
      } = window.WOOT.$store.getters.getUISettings;

      if (
        enableAudioAlerts !== 'none' &&
        playAudioUntilAllConversationsAreRead
      ) {
        const mineConversation = window.WOOT.$store.getters.getMineChats({
          assigneeType: 'me',
          status: 'open',
        });
        const hasUnreadConversation = mineConversation.some(conv => {
          return conv.unread_count > 0;
        });

        if (hasUnreadConversation) {
          this.timer = setTimeout(() => {
            window.playAudioAlert();
            showBadgeOnFavicon();
            this.playAudioEvery30Seconds();
          }, TIME);
        } else {
          this.clearSetTimeout();
        }
      }
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

    if (this.playAudioAlertUntilAllConversationsAreRead) {
      this.clearSetTimeout();
      this.playAudioEvery30Seconds();
    }

    window.playAudioAlert();
    showBadgeOnFavicon();
  };
}

export default new DashboardAudioNotificationHelper();
