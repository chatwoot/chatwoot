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
    beforeEach(() => {
      state.meta = {};
    });

    it('add meta to state', () => {
      mutations[types.SET_ARTICLES_META](state, {
        articles_count: 3,
        current_page: 1,
      });
      expect(state.meta).toEqual({
        articles_count: 3,
        current_page: 1,
      });
    });

    it('preserves existing meta values and updates only provided keys', () => {
      state.meta = {
        all_articles_count: 56,
        archived_articles_count: 5,
        articles_count: 56,
        current_page: '1',
        draft_articles_count: 26,
        published_count: 25,
      };

      mutations[types.SET_ARTICLES_META](state, {
        articles_count: 3,
        draft_articles_count: 27,
      });

      expect(state.meta).toEqual({
        all_articles_count: 56,
        archived_articles_count: 5,
        current_page: '1',
        articles_count: 3,
        draft_articles_count: 27,
        published_count: 25,
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
    it('does not update if empty object is passed', () => {
      mutations[types.UPDATE_ARTICLE](state, {});
      expect(state).toEqual(article);
    });

    it('does not update if object id is not present in the state', () => {
      mutations[types.UPDATE_ARTICLE](state, { id: 5 });
      expect(state).toEqual(article);
    });

    it('updates if object with id is already present in the state', () => {
      const updatedArticle = {
        id: 2,
        title: 'Updated Title',
        content: 'Updated Content',
      };
      mutations[types.UPDATE_ARTICLE](state, updatedArticle);
      expect(state.articles.byId[2].title).toEqual('Updated Title');
      expect(state.articles.byId[2].content).toEqual('Updated Content');
    });

    it('preserves the original position when updating an article', () => {
      const originalPosition = state.articles.byId[2].position;
      const updatedArticle = {
        id: 2,
        title: 'Updated Title',
        content: 'Updated Content',
      };
      mutations[types.UPDATE_ARTICLE](state, updatedArticle);
      expect(state.articles.byId[2].position).toEqual(originalPosition);
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
        byId: {},
      });
    });
  });
});
