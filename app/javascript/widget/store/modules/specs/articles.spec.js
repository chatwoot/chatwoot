import { mutations, actions, getters } from '../articles';
import { getMostReadArticles } from 'widget/api/article';
import { getFromCache, setCache } from 'shared/helpers/cache';

vi.mock('widget/api/article');
vi.mock('shared/helpers/cache');

describe('Vuex Articles Module', () => {
  let state;

  beforeEach(() => {
    state = {
      records: [],
      uiFlags: {
        isError: false,
        hasFetched: false,
        isFetching: false,
      },
    };
  });

  describe('Mutations', () => {
    it('sets articles correctly', () => {
      const articles = [{ id: 1 }, { id: 2 }];
      mutations.setArticles(state, articles);
      expect(state.records).toEqual(articles);
    });

    it('sets error flag correctly', () => {
      mutations.setError(state, true);
      expect(state.uiFlags.isError).toBe(true);
    });

    it('sets fetching state correctly', () => {
      mutations.setIsFetching(state, true);
      expect(state.uiFlags.isFetching).toBe(true);
    });

    it('does not mutate records when no articles are provided', () => {
      const previousState = { ...state };
      mutations.setArticles(state, []);
      expect(state.records).toEqual(previousState.records);
    });

    it('toggles the error state correctly', () => {
      mutations.setError(state, true);
      expect(state.uiFlags.isError).toBe(true);
      mutations.setError(state, false);
      expect(state.uiFlags.isError).toBe(false);
    });

    it('toggles the fetching state correctly', () => {
      mutations.setIsFetching(state, true);
      expect(state.uiFlags.isFetching).toBe(true);
      mutations.setIsFetching(state, false);
      expect(state.uiFlags.isFetching).toBe(false);
    });
  });

  describe('Actions', () => {
    describe('#fetch', () => {
      const slug = 'test-slug';
      const locale = 'en';
      const articles = [
        { id: 1, title: 'Test' },
        { id: 2, title: 'Test 2' },
      ];
      let commit;

      beforeEach(() => {
        commit = vi.fn();
        vi.clearAllMocks();
      });

      it('returns cached data if available', async () => {
        getFromCache.mockReturnValue(articles);

        await actions.fetch({ commit }, { slug, locale });

        expect(getFromCache).toHaveBeenCalledWith(
          `chatwoot_most_read_articles_${slug}_${locale}`
        );
        expect(getMostReadArticles).not.toHaveBeenCalled();
        expect(setCache).not.toHaveBeenCalled();
        expect(commit).toHaveBeenCalledWith('setArticles', articles);
        expect(commit).toHaveBeenCalledWith('setError', false);
      });

      it('fetches and caches data if no cache available', async () => {
        getFromCache.mockReturnValue(null);
        getMostReadArticles.mockReturnValue({ data: { payload: articles } });

        await actions.fetch({ commit }, { slug, locale });

        expect(getFromCache).toHaveBeenCalledWith(
          `chatwoot_most_read_articles_${slug}_${locale}`
        );
        expect(getMostReadArticles).toHaveBeenCalledWith(slug, locale);
        expect(setCache).toHaveBeenCalledWith(
          `chatwoot_most_read_articles_${slug}_${locale}`,
          articles
        );
        expect(commit).toHaveBeenCalledWith('setArticles', articles);
        expect(commit).toHaveBeenCalledWith('setError', false);
      });

      it('handles API errors correctly', async () => {
        getFromCache.mockReturnValue(null);
        getMostReadArticles.mockRejectedValue(new Error('API Error'));

        await actions.fetch({ commit }, { slug, locale });

        expect(commit).toHaveBeenCalledWith('setError', true);
        expect(commit).toHaveBeenCalledWith('setIsFetching', false);
      });

      it('does not mutate state when fetching returns an empty payload', async () => {
        getFromCache.mockReturnValue(null);
        getMostReadArticles.mockReturnValue({ data: { payload: [] } });

        await actions.fetch({ commit }, { slug, locale });

        expect(commit).toHaveBeenCalledWith('setIsFetching', true);
        expect(commit).toHaveBeenCalledWith('setError', false);
        expect(commit).not.toHaveBeenCalledWith(
          'setArticles',
          expect.any(Array)
        );
        expect(commit).toHaveBeenCalledWith('setIsFetching', false);
      });

      it('sets loading state during fetch', async () => {
        getFromCache.mockReturnValue(null);
        getMostReadArticles.mockReturnValue({ data: { payload: articles } });

        await actions.fetch({ commit }, { slug, locale });

        expect(commit).toHaveBeenCalledWith('setIsFetching', true);
        expect(commit).toHaveBeenCalledWith('setIsFetching', false);
      });
    });

    it('sets error state when fetching fails', async () => {
      const commit = vi.fn();
      getMostReadArticles.mockRejectedValueOnce(new Error('Network error'));

      await actions.fetch(
        { commit },
        { websiteToken: 'token', slug: 'slug', locale: 'en' }
      );

      expect(commit).toHaveBeenCalledWith('setIsFetching', true);
      expect(commit).toHaveBeenCalledWith('setError', true);
      expect(commit).not.toHaveBeenCalledWith('setArticles', expect.any(Array));
      expect(commit).toHaveBeenCalledWith('setIsFetching', false);
    });
  });

  describe('Getters', () => {
    it('returns uiFlags correctly', () => {
      const result = getters.uiFlags(state);
      expect(result).toEqual(state.uiFlags);
    });

    it('returns popularArticles correctly', () => {
      const result = getters.popularArticles(state);
      expect(result).toEqual(state.records);
    });
  });
});
