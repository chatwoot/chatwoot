export const initialState = () => ({
  records: {},
  archivedRecords: {},
  categories: [],
  activeChannelId: null,
  uiFlags: {
    isFetching: false,
    isCreating: false,
    isFetchingArchived: false,
  },
});
