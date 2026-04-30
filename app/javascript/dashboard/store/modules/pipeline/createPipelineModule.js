import PipelineStatusesAPI from 'dashboard/api/pipeline_statuses';

/**
 * Factory that creates a namespaced Vuex pipeline module for any entity type.
 *
 * @param {object} options
 * @param {string} options.entityType - 'contact' | 'conversation'
 * @param {function} [options.fetchAllColumns] - (params) => Promise — returns columns with paginated items embedded
 * @param {function} [options.fetchColumnItems] - (columnId) => Promise — fetches items for a single column (used on column create)
 * @param {function} [options.fetchColumnPage] - (params) => Promise — fetches a page of items for a single column
 * @param {function} options.moveItem - (itemId, targetColumnId) => Promise
 */
export const createPipelineModule = ({
  entityType,
  fetchAllColumns,
  fetchColumnItems,
  fetchColumnPage,
  moveItem,
}) => {
  const state = {
    columns: [],
    filterParams: {},
    uiFlags: {
      isFetchingColumns: false,
      isCreating: false,
      isUpdating: false,
      isDeleting: false,
    },
    columnLoadingIds: [],
    columnPagination: {},
  };

  const getters = {
    getColumns: $state => $state.columns,
    getUiFlags: $state => $state.uiFlags,
    isColumnLoading: $state => columnId =>
      $state.columnLoadingIds.includes(columnId),
    getColumnPagination: $state => columnId =>
      $state.columnPagination[columnId] || {},
  };

  const mutations = {
    SET_COLUMNS($state, columns) {
      $state.columns = columns;
    },
    ADD_COLUMN($state, column) {
      $state.columns.push(column);
    },
    UPDATE_COLUMN($state, updated) {
      const index = $state.columns.findIndex(c => c.id === updated.id);
      if (index !== -1)
        $state.columns[index] = { ...$state.columns[index], ...updated };
    },
    DELETE_COLUMN($state, columnId) {
      $state.columns = $state.columns.filter(c => c.id !== columnId);
    },
    REORDER_COLUMNS($state, orderedIds) {
      const map = Object.fromEntries($state.columns.map(c => [c.id, c]));
      $state.columns = orderedIds.map(id => map[id]).filter(Boolean);
    },
    SET_COLUMN_ITEMS($state, { columnId, items }) {
      const col = $state.columns.find(c => c.id === columnId);
      if (col) col.items = items;
    },
    APPEND_COLUMN_ITEMS($state, { columnId, items }) {
      const col = $state.columns.find(c => c.id === columnId);
      if (col) col.items = [...col.items, ...items];
    },
    ADD_COLUMN_LOADING($state, columnId) {
      if (!$state.columnLoadingIds.includes(columnId))
        $state.columnLoadingIds.push(columnId);
    },
    REMOVE_COLUMN_LOADING($state, columnId) {
      $state.columnLoadingIds = $state.columnLoadingIds.filter(
        id => id !== columnId
      );
    },
    MOVE_ITEM($state, { itemId, fromColumnId, toColumnId }) {
      const fromCol = $state.columns.find(c => c.id === fromColumnId);
      const toCol = $state.columns.find(c => c.id === toColumnId);
      if (!fromCol || !toCol) return;

      const item = fromCol.items.find(i => i.id === itemId);
      if (!item) return;

      fromCol.items = fromCol.items.filter(i => i.id !== itemId);
      toCol.items = [...toCol.items, item];
    },
    ROLLBACK_MOVE($state, { item, fromColumnId, toColumnId }) {
      const toCol = $state.columns.find(c => c.id === toColumnId);
      const fromCol = $state.columns.find(c => c.id === fromColumnId);
      if (toCol) toCol.items = toCol.items.filter(i => i.id !== item.id);
      if (fromCol) fromCol.items = [...fromCol.items, item];
    },
    SET_UI_FLAG($state, flags) {
      $state.uiFlags = { ...$state.uiFlags, ...flags };
    },
    SET_FILTER_PARAMS($state, params) {
      $state.filterParams = params;
    },
    SET_COLUMN_PAGINATION($state, { columnId, pagination }) {
      $state.columnPagination = {
        ...$state.columnPagination,
        [columnId]: {
          ...($state.columnPagination[columnId] || {}),
          ...pagination,
        },
      };
    },
  };

  const actions = {
    fetchColumns: async ({ commit }, params = {}) => {
      commit('SET_UI_FLAG', { isFetchingColumns: true });
      commit('SET_FILTER_PARAMS', params);
      commit('SET_COLUMNS', []);
      try {
        if (fetchAllColumns) {
          const response = await fetchAllColumns(params);
          const columns = response.data.columns;
          commit(
            'SET_COLUMNS',
            columns.map(c => ({
              id: c.id,
              name: c.name,
              position: c.position,
              items: c.items || [],
              itemsLoaded: true,
            }))
          );
          columns.forEach(c => {
            commit('SET_COLUMN_PAGINATION', {
              columnId: c.id,
              pagination: {
                page: 1,
                hasMore: c.has_more,
                totalCount: c.total_count,
                isLoadingMore: false,
              },
            });
          });
        } else {
          const response = await PipelineStatusesAPI.getByType(entityType);
          const columns = response.data.pipeline_statuses;
          commit(
            'SET_COLUMNS',
            columns.map(s => ({
              id: s.id,
              name: s.name,
              position: s.position,
              items: [],
              itemsLoaded: false,
            }))
          );
        }
      } finally {
        commit('SET_UI_FLAG', { isFetchingColumns: false });
      }
    },

    fetchColumnItems: async ({ commit }, columnId) => {
      commit('ADD_COLUMN_LOADING', columnId);
      try {
        const response = await fetchColumnItems(columnId);
        const items = response.data.payload || response.data;
        commit('SET_COLUMN_ITEMS', { columnId, items });
        commit('SET_COLUMN_PAGINATION', {
          columnId,
          pagination: {
            page: 1,
            hasMore: false,
            totalCount: items.length,
            isLoadingMore: false,
          },
        });
      } finally {
        commit('REMOVE_COLUMN_LOADING', columnId);
      }
    },

    fetchMoreColumnItems: async ({ commit, state: $state }, columnId) => {
      if (!fetchColumnPage) return;

      const pagination = $state.columnPagination[columnId] || {};
      if (!pagination.hasMore || pagination.isLoadingMore) return;

      const nextPage = (pagination.page || 1) + 1;
      commit('SET_COLUMN_PAGINATION', {
        columnId,
        pagination: { isLoadingMore: true },
      });

      try {
        const response = await fetchColumnPage({
          ...$state.filterParams,
          column_id: columnId,
          page: nextPage,
        });
        const { items, has_more, total_count } = response.data;
        commit('APPEND_COLUMN_ITEMS', { columnId, items });
        commit('SET_COLUMN_PAGINATION', {
          columnId,
          pagination: {
            page: nextPage,
            hasMore: has_more,
            totalCount: total_count,
            isLoadingMore: false,
          },
        });
      } catch {
        commit('SET_COLUMN_PAGINATION', {
          columnId,
          pagination: { isLoadingMore: false },
        });
      }
    },

    createColumn: async ({ commit, dispatch }, name) => {
      commit('SET_UI_FLAG', { isCreating: true });
      try {
        const response = await PipelineStatusesAPI.create({
          name,
          pipeline_type: entityType,
        });
        commit('ADD_COLUMN', {
          id: response.data.id,
          name: response.data.name,
          items: [],
          itemsLoaded: false,
        });
        dispatch('fetchColumnItems', response.data.id);
      } finally {
        commit('SET_UI_FLAG', { isCreating: false });
      }
    },

    updateColumn: async ({ commit }, { id, name }) => {
      commit('SET_UI_FLAG', { isUpdating: true });
      try {
        const response = await PipelineStatusesAPI.update(id, { name });
        commit('UPDATE_COLUMN', { id, name: response.data.name });
      } finally {
        commit('SET_UI_FLAG', { isUpdating: false });
      }
    },

    deleteColumn: async ({ commit }, columnId) => {
      commit('SET_UI_FLAG', { isDeleting: true });
      try {
        await PipelineStatusesAPI.delete(columnId);
        commit('DELETE_COLUMN', columnId);
      } finally {
        commit('SET_UI_FLAG', { isDeleting: false });
      }
    },

    reorderColumns: async ({ commit, state: $state }, orderedIds) => {
      const previousIds = $state.columns.map(c => c.id);
      commit('REORDER_COLUMNS', orderedIds);
      try {
        await PipelineStatusesAPI.reorder(orderedIds);
      } catch {
        commit('REORDER_COLUMNS', previousIds);
      }
    },

    moveItem: async (
      { commit, state: $state },
      { itemId, fromColumnId, toColumnId }
    ) => {
      if (fromColumnId === toColumnId) return;

      const fromCol = $state.columns.find(c => c.id === fromColumnId);
      const originalItem = fromCol?.items.find(i => i.id === itemId);

      commit('MOVE_ITEM', { itemId, fromColumnId, toColumnId });

      try {
        await moveItem(itemId, toColumnId);
      } catch {
        if (originalItem) {
          commit('ROLLBACK_MOVE', {
            item: originalItem,
            fromColumnId,
            toColumnId,
          });
        }
      }
    },
  };

  return { namespaced: true, state, getters, mutations, actions };
};
