import { defineStore } from 'pinia';

export const createResourceStore = (
  storeName,
  { api, customGetters = {}, customActions = {} }
) => {
  return defineStore(storeName, {
    state: () => ({
      records: [],
      uiFlags: {
        isFetching: false,
        isCreating: false,
        isUpdating: false,
        isDeleting: false,
      },
      error: null,
    }),

    getters: {
      getRecords: state => state.records,
      getUIFlags: state => state.uiFlags,
      getError: state => state.error,
      ...customGetters,
    },

    actions: {
      async index(params = {}) {
        this.uiFlags.isFetching = true;
        this.error = null;

        try {
          const {
            data: { payload = [] },
          } = await api.index(params);
          this.records = [...payload];
        } catch (error) {
          this.error = error;
          throw error;
        } finally {
          this.uiFlags.isFetching = false;
        }
      },

      async create(payload) {
        this.uiFlags.isCreating = true;
        this.error = null;

        try {
          const { data } = await api.post(payload);
          this.records.push(data.payload);
          return data.payload;
        } catch (error) {
          this.error = error;
          throw error;
        } finally {
          this.uiFlags.isCreating = false;
        }
      },

      async update(id, payload) {
        this.uiFlags.isUpdating = true;
        this.error = null;

        try {
          const { data } = await api.put(id, payload);
          const index = this.records.findIndex(record => record.id === id);
          if (index !== -1) {
            this.records[index] = data.payload;
          }
          return data.payload;
        } catch (error) {
          this.error = error;
          throw error;
        } finally {
          this.uiFlags.isUpdating = false;
        }
      },

      async delete(id) {
        this.uiFlags.isDeleting = true;
        this.error = null;

        try {
          await api.delete(id);
          this.records = this.records.filter(record => record.id !== id);
        } catch (error) {
          this.error = error;
          throw error;
        } finally {
          this.uiFlags.isDeleting = false;
        }
      },

      reset() {
        this.records = [];
        this.error = null;
        Object.keys(this.uiFlags).forEach(key => {
          this.uiFlags[key] = false;
        });
      },

      ...customActions,
    },
  });
};
