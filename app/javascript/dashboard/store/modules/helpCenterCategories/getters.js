export const getters = {
  uiFlagsIn: state => helpCenterId => {
    const uiFlags = state.categories.uiFlags.byId[helpCenterId];
    if (uiFlags) return uiFlags;
    return { isFetching: false, isUpdating: false, isDeleting: false };
  },
  isFetchingHelpCenterCategories: state => state.uiFlags.isFetching,
  categoryById: (...getterArguments) => categoryId => {
    const [state] = getterArguments;
    const category = state.categories.byId[categoryId];

    if (!category) return undefined;

    return category;
  },
  categoryByLocale: (...getterArguments) => locale => {
    const [state] = getterArguments;
    const category = state.categories.byId[locale];

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
};
