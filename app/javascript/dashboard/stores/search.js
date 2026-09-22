import { defineStore } from 'pinia';
import SearchAPI from 'dashboard/api/search';

export const SEARCH_ENTITIES = [
  'contacts',
  'conversations',
  'messages',
  'articles',
];
const PER_PAGE = 15;

// Paginated search responses can overlap across pages (new records shift
// offsets between fetches), so drop records that are already in the list.
const appendUniqueRecords = (existingRecords, newRecords) => {
  const existingIds = new Set(existingRecords.map(record => record.id));
  return [
    ...existingRecords,
    ...newRecords.filter(record => !existingIds.has(record.id)),
  ];
};

const emptyResults = () =>
  Object.fromEntries(
    SEARCH_ENTITIES.map(type => [
      type,
      {
        records: [],
        page: 0,
        hasMore: false,
        isFetching: false,
        hasError: false,
      },
    ])
  );

export const useSearchStore = defineStore('search', {
  state: () => ({
    counts: {},
    countBackend: null,
    messageBackend: null,
    isFetchingCounts: false,
    hasCountError: false,
    results: emptyResults(),
  }),

  getters: {
    // The message count is wrong once the indexed search fell back to SQL
    isMessageCountStale: state =>
      Boolean(
        state.countBackend &&
          state.messageBackend &&
          state.countBackend !== state.messageBackend
      ),
    countFor() {
      return type =>
        type === 'messages' && this.isMessageCountStale
          ? null
          : (this.counts[type] ?? null);
    },
  },

  actions: {
    // An aborted request leaves the flags to the request that replaced it.
    async fetchCounts(params, { signal } = {}) {
      this.isFetchingCounts = true;
      this.hasCountError = false;
      try {
        const { data } = await SearchAPI.counts(params, { signal });
        this.counts = data.payload.counts;
        this.countBackend = data.meta.message_backend;
      } catch (error) {
        if (!signal?.aborted) this.hasCountError = true;
      } finally {
        if (!signal?.aborted) this.isFetchingCounts = false;
      }
    },

    async fetchResults(type, { page = 1, ...params }, { signal } = {}) {
      const results = this.results[type];
      results.isFetching = true;
      results.hasError = false;
      try {
        const { data } = await SearchAPI[type]({ ...params, page }, { signal });
        const records = data.payload[type];
        results.records =
          page === 1 ? records : appendUniqueRecords(results.records, records);
        results.page = page;
        // hasMore uses the raw page size: the records above may shrink on
        // dedupe, so stored counts cannot signal whether more pages exist
        results.hasMore = records.length === PER_PAGE;
        if (type === 'messages')
          this.messageBackend = data.meta.message_backend;
      } catch (error) {
        if (!signal?.aborted) results.hasError = true;
      } finally {
        if (!signal?.aborted) results.isFetching = false;
      }
    },
  },
});
