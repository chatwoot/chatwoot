import { mutations, types } from '../../inboxAssignableMembers';
import inboxAssignableMembers from './fixtures';

describe('#mutations', () => {
  describe('#SET_INBOX_ASSIGNABLE_MEMBERS', () => {
    it('Adds inbox members to records', () => {
      const state = { records: {} };
      mutations[types.SET_INBOX_ASSIGNABLE_MEMBERS](state, {
        members: [...inboxAssignableMembers],
        inboxId: 1,
      });

      expect(state.records).toEqual({ 1: inboxAssignableMembers });
    });
  });
});
