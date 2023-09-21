import { mutations } from '../mutations';
import types from '../../../mutation-types';
import { categoriesState, categoriesPayload } from './fixtures';
describe('#mutations', () => {
  let state = {};
  beforeEach(() => {
    state = categoriesState;
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
    it('Does not invalid category with empty data passed', () => {
      mutations[types.ADD_CATEGORY_ID](state, {});
      expect(state).toEqual(categoriesState);
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
});
