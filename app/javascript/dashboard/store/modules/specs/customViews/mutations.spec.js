import types from '../../../mutation-types';
import { mutations } from '../../customViews';
import { customViewList, updateCustomViewList } from './fixtures';

describe('#mutations', () => {
  describe('#SET_CUSTOM_VIEW', () => {
    it('set custom view records', () => {
      const state = { records: [] };
      mutations[types.SET_CUSTOM_VIEW](state, customViewList);
      expect(state.records).toEqual(customViewList);
    });
  });

  describe('#ADD_CUSTOM_VIEW', () => {
    it('push newly created custom views to the store', () => {
      const state = { records: [customViewList] };
      mutations[types.ADD_CUSTOM_VIEW](state, customViewList[0]);
      expect(state.records).toEqual([customViewList, customViewList[0]]);
    });
  });

  describe('#DELETE_CUSTOM_VIEW', () => {
    it('delete custom view record', () => {
      const state = { records: [customViewList[0]] };
      mutations[types.DELETE_CUSTOM_VIEW](state, customViewList[0]);
      expect(state.records).toEqual([customViewList[0]]);
    });
  });

  describe('#UPDATE_CUSTOM_VIEW', () => {
    it('update custom view record', () => {
      const state = { records: [updateCustomViewList[0]] };
      mutations[types.UPDATE_CUSTOM_VIEW](state, updateCustomViewList[0]);
      expect(state.records).toEqual(updateCustomViewList);
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
