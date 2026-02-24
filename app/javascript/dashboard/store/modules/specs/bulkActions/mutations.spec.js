import types from '../../../mutation-types';
import { mutations } from '../../bulkActions';

describe('#mutations', () => {
  describe('#toggleUiFlag', () => {
    it('set update flags', () => {
      const state = { uiFlags: { isUpdating: false } };
      mutations[types.SET_BULK_ACTIONS_FLAG](state, { isUpdating: true });
      expect(state.uiFlags.isUpdating).toEqual(true);
    });
  });
  describe('#setSelectedConversationIds', () => {
    it('set selected conversation ids', () => {
      const state = { selectedConversationIds: [] };
      mutations[types.SET_SELECTED_CONVERSATION_IDS](state, [1, 2, 3]);
      expect(state.selectedConversationIds).toEqual([1, 2, 3]);
    });
  });
  describe('#removeSelectedConversationIds', () => {
    it('remove selected conversation ids', () => {
      const state = { selectedConversationIds: [1, 2, 3] };
      mutations[types.REMOVE_SELECTED_CONVERSATION_IDS](state, 1);
      expect(state.selectedConversationIds).toEqual([2, 3]);
    });
  });
  describe('#clearSelectedConversationIds', () => {
    it('clear selected conversation ids', () => {
      const state = { selectedConversationIds: [1, 2, 3] };
      mutations[types.CLEAR_SELECTED_CONVERSATION_IDS](state);
      expect(state.selectedConversationIds).toEqual([]);
    });
  });
});
