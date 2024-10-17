import { MESSAGE_TYPE } from 'shared/constants/messages';
import { showBadgeOnFavicon } from './faviconHelper';
import { initFaviconSwitcher } from './faviconHelper';
import {
  getAlertAudio,
  initOnEvents,
} from 'shared/helpers/AudioNotificationHelper';
import {
  ROLES,
  CONVERSATION_PERMISSIONS,
} from 'dashboard/constants/permissions.js';
import { getUserPermissions } from 'dashboard/helper/permissionsHelper.js';

const NOTIFICATION_TIME = 30000;

class DashboardAudioNotificationHelper {
  constructor() {
    this.recurringNotificationTimer = null;
    this.audioAlertType = 'none';
    this.playAlertOnlyWhenHidden = true;
    this.alertIfUnreadConversationExist = false;
    this.currentUser = null;
    this.currentUserId = null;
    this.audioAlertTone = 'ding';

    this.onAudioListenEvent = async () => {
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
  }

  setInstanceValues = ({
    currentUser,
    alwaysPlayAudioAlert,
    alertIfUnreadConversationExist,
    audioAlertType,
    audioAlertTone,
  }) => {
    this.audioAlertType = audioAlertType;
    this.playAlertOnlyWhenHidden = !alwaysPlayAudioAlert;
    this.alertIfUnreadConversationExist = alertIfUnreadConversationExist;
    this.currentUser = currentUser;
    this.currentUserId = currentUser.id;
    this.audioAlertTone = audioAlertTone;
    initOnEvents.forEach(e => {
      document.addEventListener(e, this.onAudioListenEvent, {
        once: true,
      });
    });
    initFaviconSwitcher();
  };

  executeRecurringNotification = () => {
    if (!window.WOOT_STORE) {
      this.clearSetTimeout();
      return;
    }

    const mineConversation = window.WOOT_STORE.getters.getMineChats({
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
      window.WOOT_STORE.getters.getSelectedChat?.id === message.conversation_id
    );
  };

  isMessageFromCurrentUser = message => {
    return message?.sender_id === this.currentUserId;
  };

  isUserHasConversationPermission = () => {
    const currentAccountId = window.WOOT_STORE.getters.getCurrentAccountId;
    // Get the user permissions for the current account
    const userPermissions = getUserPermissions(
      this.currentUser,
      currentAccountId
    );
    // Check if the user has the required permissions
    const hasRequiredPermission = [...ROLES, ...CONVERSATION_PERMISSIONS].some(
      permission => userPermissions.includes(permission)
    );
    return hasRequiredPermission;
  };

  shouldNotifyOnMessage = message => {
    if (this.audioAlertType === 'mine') {
      return this.isConversationAssignedToCurrentUser(message);
    }
    return this.audioAlertType === 'all';
  };

  onNewMessage = message => {
    // If the user does not have the permission to view the conversation, then dismiss the alert
    if (!this.isUserHasConversationPermission()) {
      return;
    }

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

const notifHelper = new DashboardAudioNotificationHelper();
window.notifHelper = notifHelper;
export default notifHelper;
