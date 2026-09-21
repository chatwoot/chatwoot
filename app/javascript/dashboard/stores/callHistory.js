import camelcaseKeys from 'camelcase-keys';
import CallsAPI from 'dashboard/api/calls';
import { throwErrorMessage } from 'dashboard/store/utils/api';
import { defineStore } from 'pinia';

export const useCallHistoryStore = defineStore('callHistory', {
  state: () => ({
    records: [],
    meta: { count: 0, currentPage: 1, totalPages: 0 },
    uiFlags: { isFetching: false },
    fetchRequestToken: 0,
  }),

  actions: {
    async fetchCalls(params = {}) {
      this.uiFlags.isFetching = true;
      this.fetchRequestToken += 1;
      const requestToken = this.fetchRequestToken;
      try {
        const { data } = await CallsAPI.get(params);
        // A newer fetch (filter/page change) superseded this one; drop the result.
        if (this.fetchRequestToken !== requestToken) return this.records;
        this.records = camelcaseKeys(data.payload, { deep: true });
        this.meta = camelcaseKeys(data.meta);
        return this.records;
      } catch (error) {
        // Don't surface errors from a fetch that a newer request already replaced.
        if (this.fetchRequestToken !== requestToken) return this.records;
        // Drop the previous results so stale rows aren't shown under the new view.
        this.records = [];
        this.meta = { count: 0, currentPage: 1, totalPages: 0 };
        return throwErrorMessage(error);
      } finally {
        if (this.fetchRequestToken === requestToken) {
          this.uiFlags.isFetching = false;
        }
      }
    },
  },
});
