import { applyInboxPageFilters, sortComparator } from './helpers';

export const getters = {
  getNotifications($state) {
    return Object.values($state.records).sort((n1, n2) => n2.id - n1.id);
  },
  getFilteredNotifications: $state => filters => {
    const sortOrder = filters.sortOrder === 'desc' ? 'newest' : 'oldest';
    const filteredNotifications = Object.values($state.records).filter(
      notification => applyInboxPageFilters(notification, filters)
    );
    const sortedNotifications = filteredNotifications.sort((a, b) =>
      sortComparator(a, b, sortOrder)
    );
    return sortedNotifications;
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
