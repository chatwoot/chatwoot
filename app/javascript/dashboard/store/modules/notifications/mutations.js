import Vue from 'vue';
import types from '../../mutation-types';

export const mutations = {
  [types.SET_NOTIFICATIONS_UI_FLAG]($state, data) {
    $state.uiFlags = {
      ...$state.uiFlags,
      ...data,
    };
  },
  [types.CLEAR_NOTIFICATIONS]: $state => {
    Vue.set($state, 'records', {});
  },
  [types.SET_NOTIFICATIONS_META]: ($state, data) => {
    const {
      count,
      current_page: currentPage,
      unread_count: unreadCount,
    } = data;

    Vue.set($state.meta, 'count', count);
    Vue.set($state.meta, 'currentPage', currentPage);
    Vue.set($state.meta, 'unreadCount', unreadCount);
  },
  [types.SET_NOTIFICATIONS_UNREAD_COUNT]: ($state, count) => {
    Vue.set($state.meta, 'unreadCount', count < 0 ? 0 : count);
  },
  [types.SET_NOTIFICATIONS]: ($state, data) => {
    data.forEach(notification => {
      Vue.set($state.records, notification.id, {
        ...($state.records[notification.id] || {}),
        ...notification,
      });
    });
  },
  [types.UPDATE_NOTIFICATION]: ($state, primaryActorId) => {
    Object.values($state.records).forEach(item => {
      if (item.primary_actor_id === primaryActorId) {
        Vue.set($state.records[item.id], 'read_at', true);
      }
    });
  },
  [types.UPDATE_ALL_NOTIFICATIONS]: $state => {
    Object.values($state.records).forEach(item => {
      Vue.set($state.records[item.id], 'read_at', true);
    });
  },
};
