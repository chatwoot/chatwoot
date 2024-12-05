import { MESSAGE_TYPE } from 'shared/constants/messages';
import { showBadgeOnFavicon } from './faviconHelper';
import { initFaviconSwitcher } from './faviconHelper';

import { EVENT_TYPES } from 'dashboard/routes/dashboard/settings/profile/constants.js';
import GlobalStore from 'dashboard/store';
import AudioNotificationStore from './AudioNotificationStore';

const NOTIFICATION_TIME = 30000;
const ALERT_PATH_PREFIX = '/audio/dashboard/';
const DEFAULT_TONE = 'ding';
const DEFAULT_ALERT_TYPE = ['none'];

const isConversationUnassigned = message => !message?.conversation?.assignee_id;

export class DashboardAudioNotificationHelper {
  constructor(store) {
    if (!store) {
      throw new Error('store is required');
    }
    this.store = new AudioNotificationStore(store);

    this.notificationConfig = {
      audioAlertType: DEFAULT_ALERT_TYPE,
      playAlertOnlyWhenHidden: true,
      alertIfUnreadConversationExist: false,
    };

    this.recurringNotificationTimer = null;

    this.audioConfig = {
      audio: null,
      toneType: DEFAULT_TONE,
    };

    this.currentUser = null;

    this.playAudioEvery30Seconds();
  }

  intializeAudio = () => {
    const resourceUrl = `${ALERT_PATH_PREFIX}${this.audioConfig.toneType}.mp3`;
    this.audioConfig.audio = new Audio(resourceUrl);
    return this.audioConfig.audio.load();
  };

  playAudioAlert = async () => {
    try {
      await this.audioConfig.audio.play();
    } catch (error) {
      // eslint-disable-next-line
      console.log(error.name);
    }
  };

  setInstanceValues = ({
    currentUser,
    alwaysPlayAudioAlert,
    alertIfUnreadConversationExist,
    audioAlertType = DEFAULT_ALERT_TYPE,
    audioAlertTone = DEFAULT_TONE,
  }) => {
    this.notificationConfig = {
      ...this.notificationConfig,
      audioAlertType: audioAlertType.split('+').filter(Boolean),
      playAlertOnlyWhenHidden: !alwaysPlayAudioAlert,
      alertIfUnreadConversationExist: alertIfUnreadConversationExist,
    };

    this.currentUser = currentUser;

    this.audioConfig = {
      ...this.audioConfig,
      toneType: audioAlertTone,
    };
    this.intializeAudio();
    initFaviconSwitcher();
  };

  shouldPlayAlert = () => {
    return !this.notificationConfig.playAlertOnlyWhenHidden || document.hidden;
  };

  executeRecurringNotification = () => {
    if (this.store.hasUnreadConversation() && this.shouldPlayAlert()) {
      this.playAudioAlert();
      showBadgeOnFavicon();
    }
    this.resetRecurringTimer();
  };

  resetRecurringTimer = () => {
    if (this.recurringNotificationTimer) {
      clearTimeout(this.recurringNotificationTimer);
    }
    this.recurringNotificationTimer = setTimeout(
      this.executeRecurringNotification,
      NOTIFICATION_TIME
    );
  };

  playAudioEvery30Seconds = () => {
    const { audioAlertType, alertIfUnreadConversationExist } =
      this.notificationConfig;

    //  Audio alert is disabled dismiss the timer
    if (audioAlertType.includes('none')) return;

    // If unread conversation flag is disabled, dismiss the timer
    if (!alertIfUnreadConversationExist) return;

    this.resetRecurringTimer();
  };

  isConversationAssignedToCurrentUser = message => {
    const conversationAssigneeId = message?.conversation?.assignee_id;
    return conversationAssigneeId === this.currentUser.id;
  };

  isMessageFromCurrentUser = message => {
    return message?.sender_id === this.currentUser.id;
  };

  shouldNotifyOnMessage = message => {
    const { audioAlertType } = this.notificationConfig;
    if (audioAlertType.includes('none')) return false;
    if (audioAlertType.includes('all')) return true;

    const assignedToMe = this.isConversationAssignedToCurrentUser(message);
    const isUnassigned = isConversationUnassigned(message);

    const shouldPlayAudio = [];

    if (audioAlertType.includes(EVENT_TYPES.ASSIGNED)) {
      shouldPlayAudio.push(assignedToMe);
    }
    if (audioAlertType.includes(EVENT_TYPES.UNASSIGNED)) {
      shouldPlayAudio.push(isUnassigned);
    }
    if (audioAlertType.includes(EVENT_TYPES.NOTME)) {
      shouldPlayAudio.push(!isUnassigned && !assignedToMe);
    }

    return shouldPlayAudio.some(Boolean);
  };

  onNewMessage = message => {
    // If the user does not have the permission to view the conversation, then dismiss the alert
    // FIX ME: There shouldn't be a new message if the user has no access to the conversation.
    if (!this.store.hasConversationPermission(this.currentUser)) {
      return;
    }

    // If the message is sent by the current user then dismiss the alert
    if (this.isMessageFromCurrentUser(message)) {
      return;
    }

    if (!this.shouldNotifyOnMessage(message)) {
      return;
    }

    // If the message type is not incoming or private, then dismiss the alert
    const { message_type: messageType, private: isPrivate } = message;
    if (messageType !== MESSAGE_TYPE.INCOMING && !isPrivate) {
      return;
    }

    if (!document.hidden) {
      // If the user looking at the conversation, then dismiss the alert
      if (this.store.isMessageFromCurrentConversation(message)) {
        return;
      }

      // If the user has disabled alerts when active on the dashboard, the dismiss the alert
      if (this.playAlertOnlyWhenHidden) {
        return;
      }
    }

    this.playAudioAlert();
    showBadgeOnFavicon();
    this.playAudioEvery30Seconds();
  };
}

export default new DashboardAudioNotificationHelper(GlobalStore);
