import types from '../../../mutation-types';
import { mutations } from '../../draftMessages';
import { data } from './fixtures';

describe('#mutations', () => {
  describe('#SET_DRAFT_MESSAGES', () => {
    it('sets the draft messages', () => {
      const state = {
        draftMessages: {},
      };
      mutations[types.SET_DRAFT_MESSAGES](state, { draftMessages: data });
      expect(state.records).toEqual(data);
    });
  });
});
