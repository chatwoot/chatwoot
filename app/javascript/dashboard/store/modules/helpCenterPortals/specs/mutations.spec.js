import { mutations } from '../mutations';
import portal from './fixtures';

describe('#mutations', () => {
  let state = {};
  beforeEach(() => {
    state = { ...portal };
  });

  describe('#setUIFlag', () => {
    it('It returns default flags if empty object passed', () => {
      mutations.setUIFlag(state, {});
      expect(state.uiFlags).toEqual({
        allFetched: false,
        isFetching: true,
      });
    });
    it('It updates keys when passed as parameters', () => {
      mutations.setUIFlag(state, { isFetching: false });
      expect(state.uiFlags).toEqual({
        allFetched: false,
        isFetching: false,
      });
    });
  });

  describe('#addHelpCenterEntry', () => {
    it('does not add empty objects to state', () => {
      mutations.addHelpCenterEntry(state, {});
      expect(state).toEqual(portal);
    });
    it('does adds helpcenter object to state', () => {
      mutations.addHelpCenterEntry(state, { id: 3 });
      expect(state.helpCenters.byId[3]).toEqual({ id: 3 });
    });
  });

  describe('#addHelpCenterId', () => {
    it('adds helpcenter id to state', () => {
      mutations.addHelpCenterId(state, 12);
      expect(state.helpCenters.allIds).toEqual([1, 2, 12]);
    });
  });

  describe('#updateHelpCenterEntry', () => {
    it('does not updates if empty object is passed', () => {
      mutations.updateHelpCenterEntry(state, {});
      expect(state).toEqual(portal);
    });
    it('does not updates if object id is not present ', () => {
      mutations.updateHelpCenterEntry(state, { id: 5 });
      expect(state).toEqual(portal);
    });
    it(' updates if object with id already present in the state', () => {
      mutations.updateHelpCenterEntry(state, { id: 2, name: 'Updated name' });
      expect(state.helpCenters.byId[2].name).toEqual('Updated name');
    });
  });

  describe('#removeHelpCenterEntry', () => {
    it('does not remove object entry if no id is passed', () => {
      mutations.removeHelpCenterEntry(state, undefined);
      expect(state).toEqual({ ...portal });
    });
    it('removes object entry with to conversation if outgoing', () => {
      mutations.removeHelpCenterEntry(state, 2);
      expect(state.helpCenters.byId[2]).toEqual(undefined);
    });
  });

  describe('#removeHelpCenterId', () => {
    it('removes id from state', () => {
      mutations.removeHelpCenterId(state, 2);
      expect(state.helpCenters.allIds).toEqual([1, 12]);
    });
  });

  describe('#setHelpCenterUIFlag', () => {
    it('sets correct flag in state', () => {
      mutations.setHelpCenterUIFlag(state, {
        helpCenterId: 1,
        uiFlags: { isFetching: true },
      });
      expect(state.helpCenters.uiFlags.byId[1]).toEqual({
        isFetching: true,
        isUpdating: true,
        isDeleting: false,
      });
    });
  });
});
