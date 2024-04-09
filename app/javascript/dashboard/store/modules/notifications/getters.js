import { sortComparator } from './helpers';

export const getters = {
  getNotifications($state) {
    return Object.values($state.records).sort((n1, n2) => n2.id - n1.id);
  },
  getFilteredNotifications: $state => filters => {
    const sortOrder = filters.sortOrder === 'desc' ? 'newest' : 'oldest';
    const sortedNotifications = Object.values($state.records).sort((n1, n2) =>
      sortComparator(n1, n2, sortOrder)
    );
    return sortedNotifications;
  },
  getNotificationById: $state => id => {
    return $state.records[id] || {};
  },
  getUIFlags($state) {
    return $state.uiFlags;
  },
  getNotification: $state => id => {
    const notification = $state.records[id];
    return notification || {};
  },
  getMeta: $state => {
    return $state.meta;
  },
};
