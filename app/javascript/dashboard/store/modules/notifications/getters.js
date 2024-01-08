const NOTIFICATION_TYPES = {
  conversation_creation: 1,
  conversation_assignment: 2,
  assigned_conversation_new_message: 3,
  conversation_mention: 4,
  participating_conversation_new_message: 5,
};

function getSubscribedNotificationTypes(pushFlags, emailFlags) {
  return Object.keys(NOTIFICATION_TYPES).filter(notificationType => {
    const emailFlag = `email_${notificationType}`;
    const pushFlag = `push_${notificationType}`;
    return pushFlags.includes(pushFlag) || emailFlags.includes(emailFlag);
  });
}

export const getters = {
  getNotifications($state, __, rootState) {
    const notificationSettings =
      rootState.userNotificationSettings.record || {};
    const pushFlags = notificationSettings.selected_push_flags || {};
    const emailFlags = notificationSettings.selected_email_flags || {};

    const subscribedNotificationTypes = getSubscribedNotificationTypes(
      pushFlags,
      emailFlags
    );

    return Object.values($state.records)
      .filter(notification =>
        subscribedNotificationTypes.includes(notification.notification_type)
      )
      .sort((n1, n2) => n2.id - n1.id);
  },

  getUIFlags($state) {
    return $state.uiFlags;
  },

  getNotification: $state => id => {
    return $state.records[id] || {};
  },

  getMeta: $state => {
    return $state.meta;
  },
};
