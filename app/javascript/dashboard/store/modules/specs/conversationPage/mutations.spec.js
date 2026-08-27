import * as types from '../../../mutation-types';
import { mutations } from '../../conversationPage';

describe('#mutations', () => {
  describe('#SET_CURRENT_PAGE', () => {
    it('set current page correctly', () => {
      const state = { currentPage: { me: 1 }, loadedCount: { me: 25 } };
      mutations[types.default.SET_CURRENT_PAGE](state, {
        filter: 'me',
        page: 2,
        loadedCount: 20,
      });
      expect(state.currentPage).toEqual({
        me: 2,
      });
      expect(state.loadedCount).toEqual({ me: 45 });
    });

    it('replaces the loaded count for the first page', () => {
      const state = { currentPage: { me: 3 }, loadedCount: { me: 60 } };

      mutations[types.default.SET_CURRENT_PAGE](state, {
        filter: 'me',
        page: 1,
        loadedCount: 25,
      });

      expect(state.loadedCount).toEqual({ me: 25 });
    });
  });

  describe('#CLEAR_CONVERSATION_PAGE', () => {
    it('resets the state to initial state', () => {
      const state = {
        currentPage: { me: 1, unassigned: 2, all: 3 },
        hasEndReached: { me: true, unassigned: true, all: true },
        loadedCount: { me: 25, unassigned: 50, all: 75 },
      };
      mutations[types.default.CLEAR_CONVERSATION_PAGE](state);
      expect(state).toEqual({
        currentPage: { me: 0, unassigned: 0, all: 0, appliedFilters: 0 },
        hasEndReached: {
          me: false,
          unassigned: false,
          all: false,
          appliedFilters: false,
        },
        loadedCount: {
          me: 0,
          unassigned: 0,
          all: 0,
          appliedFilters: 0,
        },
      });
    });
  });

  describe('#SET_CONVERSATION_END_REACHED', () => {
    it('set conversation end reached correctly', () => {
      const state = {
        hasEndReached: { me: false, unassigned: false, all: false },
      };
      mutations[types.default.SET_CONVERSATION_END_REACHED](state, {
        filter: 'me',
      });
      expect(state.hasEndReached).toEqual({
        me: true,
        unassigned: false,
        all: false,
      });
    });

    it('only marks the all tab as ended when all reaches the end', () => {
      const state = {
        hasEndReached: { me: false, unassigned: false, all: false },
      };
      mutations[types.default.SET_CONVERSATION_END_REACHED](state, {
        filter: 'all',
      });
      expect(state.hasEndReached).toEqual({
        me: false,
        unassigned: false,
        all: true,
      });
    });
  });
});
