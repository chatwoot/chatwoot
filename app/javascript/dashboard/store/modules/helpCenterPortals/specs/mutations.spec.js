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
      mutations[types.ADD_PORTAL_ENTRY](state, { id: 3 });
      expect(state.portals.byId[3]).toEqual({ id: 3 });
    });
  });

  describe('[types.ADD_PORTAL_ID]', () => {
    it('adds helpcenter id to state', () => {
      mutations[types.ADD_PORTAL_ID](state, 12);
      expect(state.portals.allIds).toEqual([1, 2, 12]);
    });
  });

  describe('[types.UPDATE_PORTAL_ENTRY]', () => {
    it('does not updates if empty object is passed', () => {
      mutations[types.UPDATE_PORTAL_ENTRY](state, {});
      expect(state).toEqual(portal);
    });
    it('does not updates if object id is not present ', () => {
      mutations[types.UPDATE_PORTAL_ENTRY](state, { id: 5 });
      expect(state).toEqual(portal);
    });
    it(' updates if object with id already present in the state', () => {
      mutations[types.UPDATE_PORTAL_ENTRY](state, {
        id: 2,
        name: 'Updated name',
      });
      expect(state.portals.byId[2].name).toEqual('Updated name');
    });
  });

  describe('[types.REMOVE_PORTAL_ENTRY]', () => {
    it('does not remove object entry if no id is passed', () => {
      mutations[types.REMOVE_PORTAL_ENTRY](state, undefined);
      expect(state).toEqual({ ...portal });
    });
    it('removes object entry with to conversation if outgoing', () => {
      mutations[types.REMOVE_PORTAL_ENTRY](state, 2);
      expect(state.portals.byId[2]).toEqual(undefined);
    });
  });

  describe('[types.REMOVE_PORTAL_ID]', () => {
    it('removes id from state', () => {
      mutations[types.REMOVE_PORTAL_ID](state, 2);
      expect(state.portals.allIds).toEqual([1, 12]);
    });
  });

  describe('[types.SET_HELP_PORTAL_UI_FLAG]', () => {
    it('sets correct flag in state', () => {
      mutations[types.SET_HELP_PORTAL_UI_FLAG](state, {
        portalId: 1,
        uiFlags: { isFetching: true },
      });
      expect(state.portals.uiFlags.byId[1]).toEqual({
        isFetching: true,
        isUpdating: true,
        isDeleting: false,
      });
    });
  });

  describe('#CLEAR_PORTALS', () => {
    it('clears portals', () => {
      mutations[types.CLEAR_PORTALS](state);
      expect(state.portals.allIds).toEqual([]);
      expect(state.portals.byId).toEqual({});
      expect(state.portals.uiFlags).toEqual({});
    });
  });

  describe('#SET_PORTALS_META', () => {
    it('add meta to state', () => {
      mutations[types.SET_PORTALS_META](state, {
        portals_count: 10,
        current_page: 1,
      });
      expect(state.meta).toEqual({
        count: 10,
        currentPage: 1,
      });
    });
  });

  describe('#SET_SELECTED_PORTAL_ID', () => {
    it('set selected portal id', () => {
      mutations[types.SET_SELECTED_PORTAL_ID](state, 4);
      expect(state.portals.selectedPortalId).toEqual(4);
    });
  });
});
