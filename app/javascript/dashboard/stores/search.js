import { defineStore } from 'pinia';
import SearchAPI from 'dashboard/api/search';

export const SEARCH_ENTITIES = [
  'contacts',
  'conversations',
  'messages',
  'articles',
];
export const PER_PAGE = 15;
export const PREVIEW_PER_PAGE = 5;

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
        backend: null,
      },
    ])
  );

export const useSearchStore = defineStore('search', {
  state: () => ({
    counts: {},
    countBackend: null,
    isFetchingCounts: false,
    hasCountError: false,
    results: emptyResults(),
    previews: emptyResults(),
  }),

  getters: {
    // The message count is wrong once the indexed search fell back to SQL
    isMessageCountStale:
      state =>
      (preview = false) => {
        const { backend } = (preview ? state.previews : state.results).messages;
        return Boolean(
          state.countBackend && backend && state.countBackend !== backend
        );
      },
    countFor() {
      return (type, preview = false) =>
        type === 'messages' && this.isMessageCountStale(preview)
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

    async fetchResults(
      type,
      { page = 1, ...params },
      { signal, preview = false } = {}
    ) {
      const results = preview ? this.previews[type] : this.results[type];
      const perPage = preview ? PREVIEW_PER_PAGE : PER_PAGE;
      results.isFetching = true;
      results.hasError = false;
      try {
        const { data } = await SearchAPI[type](
          { ...params, page, perPage },
          { signal }
        );
        const records = data.payload[type];
        results.records =
          page === 1 ? records : appendUniqueRecords(results.records, records);
        results.page = page;
        // hasMore uses the raw page size: the records above may shrink on
        // dedupe, so stored counts cannot signal whether more pages exist
        results.hasMore = records.length === perPage;
        if (type === 'messages') results.backend = data.meta.message_backend;
      } catch (error) {
        if (!signal?.aborted) results.hasError = true;
      } finally {
        if (!signal?.aborted) results.isFetching = false;
      }
    },
  },
});
