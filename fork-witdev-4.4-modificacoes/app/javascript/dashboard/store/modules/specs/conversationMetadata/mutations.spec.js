import * as types from '../../../mutation-types';
import { mutations } from '../../conversationMetadata';

describe('#mutations', () => {
  describe('#SET_INBOXES', () => {
    it('set inbox records', () => {
      const state = { records: {} };
      mutations[types.default.SET_CONVERSATION_METADATA](state, {
        id: 1,
        data: { browser: { name: 'Chrome' } },
      });
      expect(state.records).toEqual({
        1: { browser: { name: 'Chrome' } },
      });
    });
  });
});
