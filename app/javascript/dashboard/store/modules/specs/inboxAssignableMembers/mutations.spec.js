import { mutations, types } from '../../inboxAssignableAgents';
import agentsData from './fixtures';

describe('#mutations', () => {
  describe('#SET_INBOX_ASSIGNABLE_AGENTS', () => {
    it('Adds inbox members to records', () => {
      const state = { records: {} };
      mutations[types.SET_INBOX_ASSIGNABLE_AGENTS](state, {
        members: [...agentsData],
        uniqueRecordId: 'i-1-c-1',
      });

      expect(state.records).toEqual({ 'i-1-c-1': agentsData });
    });
  });
});
