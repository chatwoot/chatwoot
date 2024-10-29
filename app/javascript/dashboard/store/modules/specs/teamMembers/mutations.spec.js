import { mutations, ADD_AGENTS_TO_TEAM } from '../../teamMembers';
import teamMembers from './fixtures';

describe('#mutations', () => {
  describe('#ADD_AGENTS_TO_TEAM', () => {
    it('Adds team members to records', () => {
      const state = { records: {} };
      mutations[ADD_AGENTS_TO_TEAM](state, { data: teamMembers[0], teamId: 1 });
      expect(state.records).toEqual({ 1: teamMembers[0] });
    });
  });
});
