import { mutations, types } from '../../inboxAssignableAgents';
import agentsData from './fixtures';

describe('#mutations', () => {
  describe('#SET_INBOX_ASSIGNABLE_AGENTS', () => {
    it('Adds inbox members to records', () => {
      const state = { records: {} };
      mutations[types.SET_INBOX_ASSIGNABLE_AGENTS](state, {
        members: [...agentsData],
        inboxId: 1,
      });

      expect(state.records).toEqual({ 1: agentsData });
    });
  });
});
