import { mutations } from '../../agent';
import agents from './data';

describe('#mutations', () => {
  describe('#setAgents', () => {
    it('set agent records', () => {
      const state = { records: [] };
      mutations.setAgents(state, agents);
      expect(state.records).toEqual(agents);
    });
  });

  describe('#setError', () => {
    it('set error flag', () => {
      const state = { records: [], uiFlags: {} };
      mutations.setError(state, true);
      expect(state.uiFlags.isError).toEqual(true);
    });
  });

  describe('#setError', () => {
    it('set fetched flag', () => {
      const state = { records: [], uiFlags: {} };
      mutations.setHasFetched(state, true);
      expect(state.uiFlags.hasFetched).toEqual(true);
    });
  });
});
