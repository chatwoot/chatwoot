import types from '../../mutation-types';

export const mutations = {
  [types.SET_UI_FLAG](_state, uiFlags) {
    _state.uiFlags = {
      ..._state.uiFlags,
      ...uiFlags,
    };
  },

  [types.ADD_CATEGORY]: ($state, category) => {
    if (!category.id) return;

    $state.categories.byId[category.id] = { ...category };
  },
  [types.CLEAR_CATEGORIES]: $state => {
    $state.categories.byId = {};
    $state.categories.allIds = [];
    $state.categories.uiFlags.byId = {};
  },
  [types.ADD_MANY_CATEGORIES]($state, categories) {
    const allCategories = { ...$state.categories.byId };
    categories.forEach(category => {
      allCategories[category.id] = category;
    });
    $state.categories.byId = allCategories;
  },
  [types.ADD_MANY_CATEGORIES_ID]($state, categoryIds) {
    $state.categories.allIds.push(...categoryIds);
  },

  [types.SET_CATEGORIES_META]: ($state, data) => {
    const { categories_count: count, current_page: currentPage } = data;
    $state.meta = { ...$state.meta, count, currentPage };
  },

  [types.ADD_CATEGORY_ID]: ($state, categoryId) => {
    $state.categories.allIds.push(categoryId);
  },
  [types.ADD_CATEGORY_FLAG]: ($state, { categoryId, uiFlags }) => {
    const flags = $state.categories.uiFlags.byId[categoryId];
    $state.categories.uiFlags.byId[categoryId] = {
      ...{
        isFetching: false,
        isUpdating: false,
        isDeleting: false,
      },
      ...flags,
      ...uiFlags,
    };
  },
  [types.SET_CATEGORY_POSITIONS]: ($state, positionsHash) => {
    const { byId, allIds } = $state.categories;
    // Update position on each category record
    Object.entries(positionsHash).forEach(([id, position]) => {
      if (byId[id]) byId[id] = { ...byId[id], position };
    });
    // Re-sort allIds so every consumer sees the new order
    allIds.sort(
      (a, b) =>
        (byId[a]?.position ?? Infinity) - (byId[b]?.position ?? Infinity)
    );
  },
  [types.UPDATE_CATEGORY]($state, category) {
    const categoryId = category.id;

    if (!$state.categories.allIds.includes(categoryId)) return;

    $state.categories.byId[categoryId] = { ...category };
  },
  [types.REMOVE_CATEGORY]($state, categoryId) {
    const { [categoryId]: toBeRemoved, ...newById } = $state.categories.byId;
    $state.categories.byId = newById;
  },
  [types.REMOVE_CATEGORY_ID]($state, categoryId) {
    $state.categories.allIds = $state.categories.allIds.filter(
      id => id !== categoryId
    );
  },
};
