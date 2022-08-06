export const getters = {
  uiFlags: state => helpCenterId => {
    const uiFlags = state.categories.uiFlags.byId[helpCenterId];
    if (uiFlags) return uiFlags;
    return { isFetching: false, isUpdating: false, isDeleting: false };
  },
  isFetching: state => state.uiFlags.isFetching,
  categoryById: (...getterArguments) => categoryId => {
    const [state] = getterArguments;
    const category = state.categories.byId[categoryId];
    if (!category) return undefined;
    return category;
  },
  allCategories: (...getterArguments) => {
    const [state, _getters] = getterArguments;
    const categories = state.categories.allIds.map(id => {
      return _getters.categoryById(id);
    });
    return categories;
  },
  getMeta: state => {
    return state.meta;
  },
};
