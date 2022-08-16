import { mutations } from '../mutations';
import article from './fixtures';
import types from '../../../mutation-types';

describe('#mutations', () => {
  let state = {};
  beforeEach(() => {
    state = article;
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

  describe('#ADD_ARTICLE', () => {
    it('add valid article to state', () => {
      mutations[types.ADD_ARTICLE](state, {
        id: 3,
        category_id: 1,
        title:
          'How do I change my registered email address and/or phone number?',
      });
      expect(state.articles.byId[3]).toEqual({
        id: 3,
        category_id: 1,
        title:
          'How do I change my registered email address and/or phone number?',
      });
    });
    it('does not add article with empty data passed', () => {
      mutations[types.ADD_ARTICLE](state, {});
      expect(state).toEqual(article);
    });
  });

  describe('#ARTICLES_META', () => {
    it('add meta to state', () => {
      mutations[types.SET_ARTICLES_META](state, {
        articles_count: 3,
        current_page: 1,
      });
      expect(state.meta).toEqual({
        count: 3,
        currentPage: 1,
      });
    });
  });

  describe('#ADD_ARTICLE_ID', () => {
    it('add valid article id to state', () => {
      mutations[types.ADD_ARTICLE_ID](state, 3);
      expect(state.articles.allIds).toEqual([1, 2, 3]);
    });
    it('Does not invalid article with empty data passed', () => {
      mutations[types.ADD_ARTICLE_ID](state, {});
      expect(state).toEqual(article);
    });
  });

  describe('#UPDATE_ARTICLE', () => {
    it('does not updates if empty object is passed', () => {
      mutations[types.UPDATE_ARTICLE](state, {});
      expect(state).toEqual(article);
    });
    it('does not updates if object id is not present ', () => {
      mutations[types.UPDATE_ARTICLE](state, { id: 5 });
      expect(state).toEqual(article);
    });
    it(' updates if object with id already present in the state', () => {
      mutations[types.UPDATE_ARTICLE](state, {
        id: 2,
        title: 'How do I change my registered email address',
      });
      expect(state.articles.byId[2].title).toEqual(
        'How do I change my registered email address'
      );
    });
  });

  describe('#REMOVE_ARTICLE', () => {
    it('does not remove object entry if no id is passed', () => {
      mutations[types.REMOVE_ARTICLE](state, undefined);
      expect(state).toEqual({ ...article });
    });
    it('removes article if valid article id passed', () => {
      mutations[types.REMOVE_ARTICLE](state, 2);
      expect(state.articles.byId[2]).toEqual(undefined);
    });
  });

  describe('#CLEAR_ARTICLES', () => {
    it('clears articles', () => {
      mutations[types.CLEAR_ARTICLES](state);
      expect(state.articles.allIds).toEqual([]);
      expect(state.articles.byId).toEqual({});
      expect(state.articles.uiFlags).toEqual({
        byId: {
          '1': { isFetching: false, isUpdating: true, isDeleting: false },
        },
      });
    });
  });
});
