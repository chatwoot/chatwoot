import * as types from '../../../mutation-types';
import { mutations } from '../../scheduledMessages';

describe('#scheduledMessages mutations', () => {
  describe('SET_SCHEDULED_MESSAGES', () => {
    it('sets records for a conversation', () => {
      const state = { records: {} };

      mutations[types.default.SET_SCHEDULED_MESSAGES](state, {
        conversationId: '4',
        data: [{ id: 10 }],
      });

      expect(state.records).toEqual({ 4: [{ id: 10 }] });
    });
  });

  describe('ADD_SCHEDULED_MESSAGE', () => {
    it('adds new record or updates existing one', () => {
      const state = { records: { 2: [{ id: 1, status: 'draft' }] } };

      mutations[types.default.ADD_SCHEDULED_MESSAGE](state, {
        conversationId: 2,
        data: { id: 1, status: 'pending' },
      });

      expect(state.records[2]).toEqual([{ id: 1, status: 'pending' }]);
    });
  });

  describe('DELETE_SCHEDULED_MESSAGE', () => {
    it('removes record by id', () => {
      const state = { records: { 3: [{ id: 1 }, { id: 2 }] } };

      mutations[types.default.DELETE_SCHEDULED_MESSAGE](state, {
        conversationId: 3,
        scheduledMessageId: 1,
      });

      expect(state.records[3]).toEqual([{ id: 2 }]);
    });
  });
});
