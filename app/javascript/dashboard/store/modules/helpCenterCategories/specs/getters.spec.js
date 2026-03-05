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

  describe('allCategoriesSortedByPosition', () => {
    it('returns categories sorted by position in ascending order', () => {
      const stateWithPositions = {
        ...state,
        categories: {
          ...state.categories,
          byId: {
            1: { id: 1, name: 'Category 1', position: 3 },
            2: { id: 2, name: 'Category 2', position: 1 },
            3: { id: 3, name: 'Category 3', position: 2 },
          },
          allIds: [1, 2, 3],
        },
      };
      const boundGetters = {
        categoryById: getters.categoryById(stateWithPositions),
      };

      const result = getters.allCategoriesSortedByPosition(
        stateWithPositions,
        boundGetters
      );

      expect(result.map(c => c.id)).toEqual([2, 3, 1]);
      expect(result.map(c => c.position)).toEqual([1, 2, 3]);
    });

    it('places categories with null position at the end', () => {
      const stateWithNullPositions = {
        ...state,
        categories: {
          ...state.categories,
          byId: {
            1: { id: 1, name: 'Category 1', position: 1 },
            2: { id: 2, name: 'Category 2', position: null },
            3: { id: 3, name: 'Category 3', position: 2 },
          },
          allIds: [1, 2, 3],
        },
      };
      const boundGetters = {
        categoryById: getters.categoryById(stateWithNullPositions),
      };

      const result = getters.allCategoriesSortedByPosition(
        stateWithNullPositions,
        boundGetters
      );

      expect(result.map(c => c.id)).toEqual([1, 3, 2]);
    });

    it('handles categories with undefined position', () => {
      const stateWithUndefinedPositions = {
        ...state,
        categories: {
          ...state.categories,
          byId: {
            1: { id: 1, name: 'Category 1', position: 1 },
            2: { id: 2, name: 'Category 2' },
            3: { id: 3, name: 'Category 3', position: 2 },
          },
          allIds: [1, 2, 3],
        },
      };
      const boundGetters = {
        categoryById: getters.categoryById(stateWithUndefinedPositions),
      };

      const result = getters.allCategoriesSortedByPosition(
        stateWithUndefinedPositions,
        boundGetters
      );

      expect(result.map(c => c.id)).toEqual([1, 3, 2]);
    });
  });
});
