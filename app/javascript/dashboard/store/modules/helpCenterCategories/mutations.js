import types from '../../mutation-types';
import Vue from 'vue';

export const mutations = {
  [types.SET_UI_FLAG](_state, uiFlags) {
    _state.uiFlags = {
      ..._state.uiFlags,
      ...uiFlags,
    };
  },

  [types.ADD_CATEGORY]: ($state, category) => {
    if (!category.id) return;

    Vue.set($state.categories.byId, category.id, {
      ...category,
    });
  },
  [types.CLEAR_CATEGORIES]: $state => {
    Vue.set($state.categories, 'byId', {});
    Vue.set($state.categories, 'allIds', []);
    Vue.set($state.categories, 'uiFlags', {});
  },
  [types.ADD_MANY_CATEGORIES]($state, categories) {
    const allCategories = { ...$state.categories.byId };
    categories.forEach(category => {
      allCategories[category.id] = category;
    });
    Vue.set($state.categories, 'byId', allCategories);
  },
  [types.ADD_MANY_CATEGORIES_ID]($state, categoryIds) {
    $state.categories.allIds.push(...categoryIds);
  },

  [types.SET_CATEGORIES_META]: ($state, data) => {
    const { categories_count: count, current_page: currentPage } = data;
    Vue.set($state.meta, 'count', count);
    Vue.set($state.meta, 'currentPage', currentPage);
  },

  [types.ADD_CATEGORY_ID]: ($state, categoryId) => {
    $state.categories.allIds.push(categoryId);
  },
  [types.ADD_CATEGORY_FLAG]: ($state, { categoryId, uiFlags }) => {
    const flags = $state.categories.uiFlags.byId[categoryId];
    Vue.set($state.categories.uiFlags.byId, categoryId, {
      ...{
        isFetching: false,
        isUpdating: false,
        isDeleting: false,
      },
      ...flags,
      ...uiFlags,
    });
  },
  [types.UPDATE_CATEGORY]($state, category) {
    const categoryId = category.id;

    if (!$state.categories.allIds.includes(categoryId)) return;

    Vue.set($state.categories.byId, categoryId, {
      ...category,
    });
  },
  [types.REMOVE_CATEGORY]($state, categoryId) {
    const { [categoryId]: toBeRemoved, ...newById } = $state.categories.byId;
    Vue.set($state.categories, 'byId', newById);
  },
  [types.REMOVE_CATEGORY_ID]($state, categoryId) {
    $state.categories.allIds = $state.categories.allIds.filter(
      id => id !== categoryId
    );
  },
};
