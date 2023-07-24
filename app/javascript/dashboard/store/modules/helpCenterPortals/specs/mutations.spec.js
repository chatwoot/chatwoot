import { mutations, types } from '../mutations';
import portal from './fixtures';

describe('#mutations', () => {
  let state = {};
  beforeEach(() => {
    state = { ...portal };
  });

  describe('#SET_UI_FLAG', () => {
    it('It returns default flags if empty object passed', () => {
      mutations[types.SET_UI_FLAG](state, {});
      expect(state.uiFlags).toEqual({
        allFetched: false,
        isFetching: true,
      });
    });

    it('It updates keys when passed as parameters', () => {
      mutations[types.SET_UI_FLAG](state, { isFetching: false });
      expect(state.uiFlags).toEqual({
        allFetched: false,
        isFetching: false,
      });
    });
  });

  describe('[types.ADD_PORTAL_ENTRY]', () => {
    it('does not add empty objects to state', () => {
      mutations[types.ADD_PORTAL_ENTRY](state, {});
      expect(state).toEqual(portal);
    });
    it('does adds helpcenter object to state', () => {
      mutations[types.ADD_PORTAL_ENTRY](state, { slug: 'new' });
      expect(state.portals.byId.new).toEqual({ slug: 'new' });
    });
  });

  describe('[types.ADD_PORTAL_ID]', () => {
    it('adds helpcenter slug to state', () => {
      mutations[types.ADD_PORTAL_ID](state, 12);
      expect(state.portals.allIds).toEqual([1, 2, 12]);
    });
  });

  describe('[types.UPDATE_PORTAL_ENTRY]', () => {
    it('does not updates if empty object is passed', () => {
      mutations[types.UPDATE_PORTAL_ENTRY](state, {});
      expect(state).toEqual(portal);
    });
    it('does not updates if object slug is not present ', () => {
      mutations[types.UPDATE_PORTAL_ENTRY](state, { slug: 5 });
      expect(state).toEqual(portal);
    });
    it(' updates if object with slug already present in the state', () => {
      mutations[types.UPDATE_PORTAL_ENTRY](state, {
        slug: 2,
        name: 'Updated name',
      });
      expect(state.portals.byId[2].name).toEqual('Updated name');
    });
  });

  describe('[types.REMOVE_PORTAL_ENTRY]', () => {
    it('does not remove object entry if no slug is passed', () => {
      mutations[types.REMOVE_PORTAL_ENTRY](state, undefined);
      expect(state).toEqual({ ...portal });
    });
    it('removes object entry with to conversation if outgoing', () => {
      mutations[types.REMOVE_PORTAL_ENTRY](state, 2);
      expect(state.portals.byId[2]).toEqual(undefined);
    });
  });

  describe('[types.REMOVE_PORTAL_ID]', () => {
    it('removes slug from state', () => {
      mutations[types.REMOVE_PORTAL_ID](state, 2);
      expect(state.portals.allIds).toEqual([1, 12]);
    });
  });

  describe('[types.SET_HELP_PORTAL_UI_FLAG]', () => {
    it('sets correct flag in state', () => {
      mutations[types.SET_HELP_PORTAL_UI_FLAG](state, {
        portalSlug: 'domain',
        uiFlags: { isFetching: true },
      });
      expect(state.portals.uiFlags.byId.domain).toEqual({
        isFetching: true,
        isUpdating: false,
        isDeleting: false,
      });
    });
  });

  describe('#CLEAR_PORTALS', () => {
    it('clears portals', () => {
      mutations[types.CLEAR_PORTALS](state);
      expect(state.portals.allIds).toEqual([]);
      expect(state.portals.byId).toEqual({});
      expect(state.portals.uiFlags).toEqual({
        byId: {},
      });
    });
  });

  describe('#SET_PORTALS_META', () => {
    it('add meta to state', () => {
      mutations[types.SET_PORTALS_META](state, {
        count: 10,
        currentPage: 1,
        all_articles_count: 10,
        archived_articles_count: 10,
        draft_articles_count: 10,
        mine_articles_count: 10,
      });
      expect(state.meta).toEqual({
        count: 0,
        currentPage: 1,
        allArticlesCount: 10,
        archivedArticlesCount: 10,
        draftArticlesCount: 10,
        mineArticlesCount: 10,
      });
    });
  });
});
