import { getters } from '../getters';
import articles from './fixtures';
describe('#getters', () => {
  let state = {};
  beforeEach(() => {
    state = articles;
  });
  it('uiFlags', () => {
    expect(getters.uiFlags(state)(1)).toEqual({
      isFetching: false,
      isUpdating: true,
      isDeleting: false,
    });
  });

  it('articleById', () => {
    expect(getters.articleById(state)(1)).toEqual({
      id: 1,
      category_id: 1,
      title: 'Documents are required to complete KYC',
      content:
        'The submission of the following documents is mandatory to complete registration, ID proof - PAN Card, Address proof',
      description: 'Documents are required to complete KYC',
      status: 'draft',
      account_id: 1,
      views: 122,
      author: {
        id: 5,
        account_id: 1,
        email: 'tom@furrent.com',
        available_name: 'Tom',
        name: 'Tom Jose',
      },
    });
  });

  it('articleStatus', () => {
    expect(getters.articleStatus(state)(1)).toEqual('draft');
  });

  it('isFetchingArticles', () => {
    expect(getters.isFetching(state)).toEqual(true);
  });

  describe('allArticlesSortedByPosition', () => {
    it('returns articles sorted by position in ascending order', () => {
      const stateWithPositions = {
        ...state,
        articles: {
          ...state.articles,
          byId: {
            1: { id: 1, title: 'Article 1', position: 3 },
            2: { id: 2, title: 'Article 2', position: 1 },
            3: { id: 3, title: 'Article 3', position: 2 },
          },
          allIds: [1, 2, 3],
        },
      };
      const boundGetters = {
        articleById: getters.articleById(stateWithPositions),
      };

      const result = getters.allArticlesSortedByPosition(
        stateWithPositions,
        boundGetters
      );

      expect(result.map(a => a.id)).toEqual([2, 3, 1]);
      expect(result.map(a => a.position)).toEqual([1, 2, 3]);
    });

    it('places articles with null position at the end', () => {
      const stateWithNullPositions = {
        ...state,
        articles: {
          ...state.articles,
          byId: {
            1: { id: 1, title: 'Article 1', position: 1 },
            2: { id: 2, title: 'Article 2', position: null },
            3: { id: 3, title: 'Article 3', position: 2 },
          },
          allIds: [1, 2, 3],
        },
      };
      const boundGetters = {
        articleById: getters.articleById(stateWithNullPositions),
      };

      const result = getters.allArticlesSortedByPosition(
        stateWithNullPositions,
        boundGetters
      );

      expect(result.map(a => a.id)).toEqual([1, 3, 2]);
    });

    it('handles articles with undefined position', () => {
      const stateWithUndefinedPositions = {
        ...state,
        articles: {
          ...state.articles,
          byId: {
            1: { id: 1, title: 'Article 1', position: 1 },
            2: { id: 2, title: 'Article 2' },
            3: { id: 3, title: 'Article 3', position: 2 },
          },
          allIds: [1, 2, 3],
        },
      };
      const boundGetters = {
        articleById: getters.articleById(stateWithUndefinedPositions),
      };

      const result = getters.allArticlesSortedByPosition(
        stateWithUndefinedPositions,
        boundGetters
      );

      expect(result.map(a => a.id)).toEqual([1, 3, 2]);
    });
  });
});
