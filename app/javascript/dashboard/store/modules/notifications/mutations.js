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
      unread_count: unReadCount,
    } = data;

    Vue.set($state.meta, 'count', count);
    Vue.set($state.meta, 'currentPage', currentPage);
    Vue.set($state.meta, 'unReadCount', unReadCount);
  },

  [types.SET_UNREAD_COUNT]: ($state, data) => {
    const { unReadCount } = data;
    Vue.set($state.meta, 'unReadCount', unReadCount);
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
    Object.values($state.records).map(item => {
      if (item.primary_actor_id === primaryActorId) {
        Vue.set($state.records[item.id], 'read_at', 'read_at');
      }
    });
  },
  [types.UPDATE_ALL_NOTIFICATIONS]: $state => {
    Object.values($state.records).map(item => {
      Vue.set($state.records[item.id], 'read_at', 'read_at');
    });
  },
};
