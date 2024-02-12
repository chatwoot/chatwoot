export const filterByStatus = (snoozedUntil, filterStatus) =>
  filterStatus === 'snoozed' ? !!snoozedUntil : !snoozedUntil;

export const filterByType = (readAt, filterType) =>
  filterType === 'read' ? !!readAt : !readAt;

export const filterByTypeAndStatus = (
  readAt,
  snoozedUntil,
  filterType,
  filterStatus
) => {
  const shouldFilterByStatus = filterByStatus(snoozedUntil, filterStatus);
  const shouldFilterByType = filterByType(readAt, filterType);
  return shouldFilterByStatus && shouldFilterByType;
};

export const applyInboxPageFilters = (notification, filters) => {
  const { status, type } = filters;
  const { read_at: readAt, snoozed_until: snoozedUntil } = notification;

  if (status && type)
    return filterByTypeAndStatus(readAt, snoozedUntil, type, status);
  if (status && !type) return filterByStatus(snoozedUntil, status);
  if (!status && type) return filterByType(readAt, type);
  return true;
};

const INBOX_SORT_OPTIONS = {
  newest: 'desc',
  oldest: 'asc',
};

const sortConfig = {
  newest: (a, b) => b.created_at - a.created_at,
  oldest: (a, b) => a.created_at - b.created_at,
};

export const sortComparator = (a, b, sortOrder) => {
  const sortDirection = INBOX_SORT_OPTIONS[sortOrder];
  if (sortOrder === 'newest' || sortOrder === 'oldest') {
    return sortConfig[sortOrder](a, b, sortDirection);
  }
  return 0;
};
