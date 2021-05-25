import { mutations } from '../../campaign';
import { campaigns } from './data';

describe('#mutations', () => {
  describe('#setCampaigns', () => {
    it('set campaign records', () => {
      const state = { records: [] };
      mutations.setCampaigns(state, campaigns);
      expect(state.records).toEqual(campaigns);
    });
  });

  describe('#setError', () => {
    it('set error flag', () => {
      const state = { records: [], uiFlags: {} };
      mutations.setError(state, true);
      expect(state.uiFlags.isError).toEqual(true);
    });
  });

  describe('#setHasFetched', () => {
    it('set fetched flag', () => {
      const state = { records: [], uiFlags: {} };
      mutations.setHasFetched(state, true);
      expect(state.uiFlags.hasFetched).toEqual(true);
    });
  });
});
