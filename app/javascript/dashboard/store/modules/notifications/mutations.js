import types from '../../mutation-types';

export const mutations = {
  [types.SET_NOTIFICATIONS_UI_FLAG]($state, data) {
    $state.uiFlags = {
      ...$state.uiFlags,
      ...data,
    };
  },
  [types.CLEAR_NOTIFICATIONS]: $state => {
    $state.records = {};
    $state.uiFlags.isAllNotificationsLoaded = false;
  },
  [types.SET_NOTIFICATIONS_META]: ($state, data) => {
    const {
      count,
      current_page: currentPage,
      unread_count: unreadCount,
    } = data;

    $state.meta = { ...$state.meta, count, currentPage, unreadCount };
  },
  [types.SET_NOTIFICATIONS_UNREAD_COUNT]: ($state, count) => {
    $state.meta.unreadCount = count < 0 ? 0 : count;
  },
  [types.SET_NOTIFICATIONS]: ($state, data) => {
    data.forEach(notification => {
      // Find existing notification with same primary_actor_id (primary_actor_id is unique)
      const existingNotification = Object.values($state.records).find(
        record => record.primary_actor_id === notification.primary_actor_id
      );
      // This is to handle the case where the same notification is received multiple times
      // On reconnect, if there is existing notification with same primary_actor_id,
      // it will be deleted and the new one will be added. So it will solve with duplicate notification
      if (existingNotification) {
        delete $state.records[existingNotification.id];
      }

      $state.records[notification.id] = {
        ...($state.records[notification.id] || {}),
        ...notification,
      };
    });
  },
  [types.READ_NOTIFICATION]: ($state, { id, read_at }) => {
    $state.records[id].read_at = read_at;
  },
  [types.UPDATE_ALL_NOTIFICATIONS]: $state => {
    Object.values($state.records).forEach(item => {
      $state.records[item.id].read_at = true;
    });
  },

  [types.ADD_NOTIFICATION]($state, data) {
    const { notification, unread_count: unreadCount, count } = data;

    $state.records[notification.id] = {
      ...($state.records[notification.id] || {}),
      ...notification,
    };
    $state.meta.unreadCount = unreadCount;
    $state.meta.count = count;
  },
  [types.UPDATE_NOTIFICATION]($state, data) {
    const { notification, unread_count: unreadCount, count } = data;
    $state.records[notification.id] = {
      ...($state.records[notification.id] || {}),
      ...notification,
    };
    $state.meta.unreadCount = unreadCount;
    $state.meta.count = count;
  },
  [types.DELETE_NOTIFICATION]($state, data) {
    const { notification, unread_count: unreadCount, count } = data;
    delete $state.records[notification.id];
    $state.meta.unreadCount = unreadCount;
    $state.meta.count = count;
  },
  [types.SET_ALL_NOTIFICATIONS_LOADED]: $state => {
    $state.uiFlags.isAllNotificationsLoaded = true;
  },

  [types.DELETE_READ_NOTIFICATIONS]: $state => {
    Object.values($state.records).forEach(item => {
      if (item.read_at) {
        delete $state.records[item.id];
      }
    });
  },
  [types.DELETE_ALL_NOTIFICATIONS]: $state => {
    $state.records = {};
  },

  [types.SNOOZE_NOTIFICATION]: ($state, { id, snoozed_until }) => {
    $state.records[id].snoozed_until = snoozed_until;
  },

  [types.SET_NOTIFICATION_FILTERS]: ($state, filters) => {
    $state.notificationFilters = filters;
  },
  [types.UPDATE_NOTIFICATION_FILTERS]: ($state, filters) => {
    $state.notificationFilters = {
      ...$state.notificationFilters,
      ...filters,
    };
  },
};
