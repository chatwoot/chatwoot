import { getters } from '../getters';
import { categoriesState } from './fixtures';
describe('#getters', () => {
  let state = {};
  beforeEach(() => {
    state = categoriesState;
  });
  it('uiFlags', () => {
    expect(getters.uiFlags(state)(1)).toEqual({
      isFetching: false,
      isUpdating: true,
      isDeleting: false,
    });
  });

  it('categoryById', () => {
    expect(getters.categoryById(state)(1)).toEqual(
      categoriesState.categories.byId[1]
    );
  });

  it('categoriesByLocaleCode', () => {
    expect(getters.categoriesByLocaleCode(state, getters)('en_US')).toEqual([]);
  });

  it('isFetchingCategories', () => {
    expect(getters.isFetching(state)).toEqual(true);
  });
});
