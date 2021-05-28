import * as types from '../../../mutation-types';
import { mutations } from '../../contactConversations';

describe('#mutations', () => {
  describe('#SET_CONTACT_CONVERSATIONS_UI_FLAG', () => {
    it('set ui flags', () => {
      const state = { uiFlags: { isFetching: true } };
      mutations[types.default.SET_CONTACT_CONVERSATIONS_UI_FLAG](state, {
        isFetching: false,
      });
      expect(state.uiFlags).toEqual({
        isFetching: false,
      });
    });
  });

  describe('#SET_CONTACT_CONVERSATIONS', () => {
    it('set contact conversation records', () => {
      const state = { records: {} };
      mutations[types.default.SET_CONTACT_CONVERSATIONS](state, {
        id: 1,
        data: [{ id: 1, contact_id: 1, message: 'hello' }],
      });
      expect(state.records).toEqual({
        1: [{ id: 1, contact_id: 1, message: 'hello' }],
      });
    });
  });

  describe('#ADD_CONTACT_CONVERSATION', () => {
    it('Adds new contact conversation to records', () => {
      const state = { records: {} };
      mutations[types.default.ADD_CONTACT_CONVERSATION](state, {
        id: 1,
        data: { id: 1, contact_id: 1, message: 'hello' },
      });
      expect(state.records).toEqual({
        1: [{ id: 1, contact_id: 1, message: 'hello' }],
      });
    });
  });
});
