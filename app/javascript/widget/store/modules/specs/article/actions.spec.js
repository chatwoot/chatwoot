import { mutations, actions, getters } from '../../articles'; // update this import path to your actual module location
import { getMostReadArticles } from 'widget/api/article';

vi.mock('widget/api/article');

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
    it('fetches articles correctly', async () => {
      const commit = vi.fn();
      const articles = [{ id: 1 }, { id: 2 }];
      getMostReadArticles.mockResolvedValueOnce({
        data: { payload: articles },
      });

      await actions.fetch({ commit }, { slug: 'slug', locale: 'en' });

      expect(commit).toHaveBeenCalledWith('setIsFetching', true);
      expect(commit).toHaveBeenCalledWith('setError', false);
      expect(commit).toHaveBeenCalledWith('setArticles', articles);
      expect(commit).toHaveBeenCalledWith('setIsFetching', false);
    });

    it('handles fetch error correctly', async () => {
      const commit = vi.fn();
      getMostReadArticles.mockRejectedValueOnce(new Error('Error message'));

      await actions.fetch(
        { commit },
        { websiteToken: 'token', slug: 'slug', locale: 'en' }
      );

      expect(commit).toHaveBeenCalledWith('setIsFetching', true);
      expect(commit).toHaveBeenCalledWith('setError', true);
      expect(commit).toHaveBeenCalledWith('setIsFetching', false);
    });

    it('does not mutate state when fetching returns an empty payload', async () => {
      const commit = vi.fn();
      getMostReadArticles.mockResolvedValueOnce({ data: { payload: [] } });

      await actions.fetch({ commit }, { slug: 'slug', locale: 'en' });

      expect(commit).toHaveBeenCalledWith('setIsFetching', true);
      expect(commit).toHaveBeenCalledWith('setError', false);
      expect(commit).not.toHaveBeenCalledWith('setArticles', expect.any(Array));
      expect(commit).toHaveBeenCalledWith('setIsFetching', false);
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
