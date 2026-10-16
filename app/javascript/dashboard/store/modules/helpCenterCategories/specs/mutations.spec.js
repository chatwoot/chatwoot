import { mutations } from '../mutations';
import types from '../../../mutation-types';
import { categoriesState, categoriesPayload } from './fixtures';
describe('#mutations', () => {
  let state = {};
  beforeEach(() => {
    state = JSON.parse(JSON.stringify(categoriesState));
  });

  describe('#SET_UI_FLAG', () => {
    it('It returns default flags if empty object passed', () => {
      mutations[types.SET_UI_FLAG](state, {});
      expect(state.uiFlags).toEqual({
        allFetched: false,
        isFetching: true,
      });
    });
    it('Update flags when flag passed as parameters', () => {
      mutations[types.SET_UI_FLAG](state, { isFetching: true });
      expect(state.uiFlags).toEqual({
        allFetched: false,
        isFetching: true,
      });
    });
  });

  describe('#ADD_CATEGORY', () => {
    it('add valid category to state', () => {
      mutations[types.ADD_CATEGORY](state, categoriesPayload.payload[0]);
      expect(state.categories.byId[1]).toEqual(categoriesPayload.payload[0]);
    });
    it('does not add category with empty data passed', () => {
      mutations[types.ADD_CATEGORY](state, {});
      expect(state).toEqual(categoriesState);
    });
  });

  describe('#CATEGORIES_META', () => {
    it('add meta to state', () => {
      mutations[types.SET_CATEGORIES_META](state, {
        categories_count: 3,
        current_page: 1,
      });
      expect(state.meta).toEqual({
        count: 3,
        currentPage: 1,
      });
    });
  });

  describe('#ADD_CATEGORY_ID', () => {
    it('add valid category id to state', () => {
      mutations[types.ADD_CATEGORY_ID](state, 3);
      expect(state.categories.allIds).toEqual([1, 2, 3]);
    });
    it('pushes the given id to allIds', () => {
      mutations[types.ADD_CATEGORY_ID](state, {});
      expect(state.categories.allIds).toEqual([1, 2, {}]);
    });
  });

  describe('#UPDATE_CATEGORY', () => {
    it('does not updates if empty object is passed', () => {
      mutations[types.UPDATE_CATEGORY](state, {});
      expect(state).toEqual(categoriesState);
    });
    it('does not updates if object id is not present ', () => {
      mutations[types.UPDATE_CATEGORY](state, { id: 5 });
      expect(state).toEqual(categoriesState);
    });
    it(' updates if object with id already present in the state', () => {
      mutations[types.UPDATE_CATEGORY](state, {
        id: 2,
        title: 'This category is for product updates',
      });
      expect(state.categories.byId[2].title).toEqual(
        'This category is for product updates'
      );
    });
  });

  describe('#REMOVE_CATEGORY', () => {
    it('does not remove object entry if no id is passed', () => {
      mutations[types.REMOVE_CATEGORY](state, undefined);
      expect(state).toEqual({ ...categoriesState });
    });
    it('removes category if valid category id passed', () => {
      mutations[types.REMOVE_CATEGORY](state, 2);
      expect(state.categories.byId[2]).toEqual(undefined);
    });
  });

  // describe('#CLEAR_CATEGORIES', () => {
  //   it('clears categories', () => {
  //     mutations[types.CLEAR_CATEGORIES](state);
  //     expect(state.categories.allIds).toEqual([]);
  //     expect(state.categories.byId).toEqual({});
  //     expect(state.categories.uiFlags).toEqual({});
  //   });
  // });

  describe('#SET_CATEGORY_POSITIONS', () => {
    it('updates positions for categories in the store', () => {
      const positionsHash = { 1: 1, 2: 2 };
      mutations[types.SET_CATEGORY_POSITIONS](state, positionsHash);

      expect(state.categories.byId[1].position).toEqual(1);
      expect(state.categories.byId[2].position).toEqual(2);
    });

    it('does not update categories that are not in the store', () => {
      const positionsHash = { 999: 5 };
      mutations[types.SET_CATEGORY_POSITIONS](state, positionsHash);

      expect(state.categories.byId[999]).toBeUndefined();
    });

    it('preserves other category properties when updating position', () => {
      const originalName = state.categories.byId[1].name;
      const positionsHash = { 1: 3 };
      mutations[types.SET_CATEGORY_POSITIONS](state, positionsHash);

      expect(state.categories.byId[1].position).toEqual(3);
      expect(state.categories.byId[1].name).toEqual(originalName);
    });

    it('re-sorts allIds by position after update', () => {
      state.categories.byId[1].position = 1;
      state.categories.byId[2].position = 2;
      state.categories.allIds = [1, 2];

      mutations[types.SET_CATEGORY_POSITIONS](state, { 1: 3, 2: 1 });

      expect(state.categories.allIds).toEqual([2, 1]);
    });
  });
});
