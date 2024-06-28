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
