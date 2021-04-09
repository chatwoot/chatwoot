import { mutations, types } from '../../inboxMembers';
import inboxMembers from './fixtures';

describe('#mutations', () => {
  describe('#SET_INBOX_MEMBERS', () => {
    it('Adds inbox members to records', () => {
      const state = { records: {} };
      mutations[types.SET_INBOX_MEMBERS](state, {
        members: [...inboxMembers],
        inboxId: 1,
      });

      expect(state.records).toEqual({ 1: inboxMembers });
    });
  });
});
