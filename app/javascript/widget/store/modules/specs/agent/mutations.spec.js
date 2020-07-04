import { mutations } from '../../agent';
import { agents } from './data';

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

  describe('#updatePresence', () => {
    it('updates agent presence', () => {
      const state = { records: agents };
      mutations.updatePresence(state, { 1: 'busy', 2: 'online' });
      expect(state.records).toEqual([
        {
          id: 1,
          name: 'John',
          avatar_url: '',
          availability_status: 'busy',
        },
        {
          id: 2,
          name: 'Xavier',
          avatar_url: '',
          availability_status: 'online',
        },
        {
          id: 3,
          name: 'Pranav',
          avatar_url: '',
        },
        {
          id: 4,
          name: 'Nithin',
          avatar_url: '',
        },
      ]);
    });
  });
});
