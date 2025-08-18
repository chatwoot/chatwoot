import types from '../../../mutation-types';
import { mutations } from '../../customViews';
import { customViewList, updateCustomViewList } from './fixtures';

describe('#mutations', () => {
  describe('#SET_CUSTOM_VIEW', () => {
    it('[Conversation] set custom view records', () => {
      const state = {
        records: [],
        conversation: { records: [] },
        contact: { records: [] },
      };
      mutations[types.SET_CUSTOM_VIEW](state, {
        data: customViewList,
        filterType: 'conversation',
      });
      expect(state.conversation.records).toEqual(customViewList);
      expect(state.contact.records).toEqual([]);
    });

    it('[Contact] set custom view records', () => {
      const state = {
        records: [],
        conversation: { records: [] },
        contact: { records: [] },
      };
      mutations[types.SET_CUSTOM_VIEW](state, {
        data: customViewList,
        filterType: 'contact',
      });
      expect(state.contact.records).toEqual(customViewList);
      expect(state.conversation.records).toEqual([]);
    });
  });

  describe('#ADD_CUSTOM_VIEW', () => {
    it('[Conversation] push newly created custom views to the store', () => {
      const state = {
        conversation: { records: [customViewList] },
        contact: { records: [] },
      };
      mutations[types.ADD_CUSTOM_VIEW](state, {
        data: customViewList[0],
        filterType: 'conversation',
      });
      expect(state.conversation.records).toEqual([
        customViewList,
        customViewList[0],
      ]);
      expect(state.contact.records).toEqual([]);
    });

    it('[Contact] push newly created custom views to the store', () => {
      const state = {
        conversation: { records: [] },
        contact: { records: [customViewList] },
      };
      mutations[types.ADD_CUSTOM_VIEW](state, {
        data: customViewList[0],
        filterType: 'contact',
      });
      expect(state.contact.records).toEqual([
        customViewList,
        customViewList[0],
      ]);
      expect(state.conversation.records).toEqual([]);
    });
  });

  describe('#DELETE_CUSTOM_VIEW', () => {
    it('[Conversation] delete custom view record', () => {
      const state = {
        conversation: { records: [customViewList[0]] },
        contact: { records: [] },
      };
      mutations[types.DELETE_CUSTOM_VIEW](state, {
        data: customViewList[0],
        filterType: 'conversation',
      });
      expect(state.conversation.records).toEqual([customViewList[0]]);
      expect(state.contact.records).toEqual([]);
    });

    it('[Contact] delete custom view record', () => {
      const state = {
        contact: { records: [customViewList[0]] },
        conversation: { records: [] },
      };
      mutations[types.DELETE_CUSTOM_VIEW](state, {
        data: customViewList[0],
        filterType: 'contact',
      });
      expect(state.contact.records).toEqual([customViewList[0]]);
      expect(state.conversation.records).toEqual([]);
    });
  });

  describe('#UPDATE_CUSTOM_VIEW', () => {
    it('[Conversation] update custom view record', () => {
      const state = {
        conversation: { records: [updateCustomViewList[0]] },
        contact: { records: [] },
      };
      mutations[types.UPDATE_CUSTOM_VIEW](state, {
        data: updateCustomViewList[0],
        filterType: 'conversation',
      });
      expect(state.conversation.records).toEqual(updateCustomViewList);
      expect(state.contact.records).toEqual([]);
    });

    it('[Contact] update custom view record', () => {
      const state = {
        contact: { records: [updateCustomViewList[0]] },
        conversation: { records: [] },
      };
      mutations[types.UPDATE_CUSTOM_VIEW](state, {
        data: updateCustomViewList[0],
        filterType: 'contact',
      });
      expect(state.contact.records).toEqual(updateCustomViewList);
      expect(state.conversation.records).toEqual([]);
    });
  });

  describe('#SET_ACTIVE_CONVERSATION_FOLDER', () => {
    it('set active conversation folder', () => {
      const state = { activeConversationFolder: customViewList[0] };
      mutations[types.SET_ACTIVE_CONVERSATION_FOLDER](state, customViewList[0]);
      expect(state.activeConversationFolder).toEqual(customViewList[0]);
    });
  });
});
