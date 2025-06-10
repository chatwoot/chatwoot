import types from '../../../mutation-types';
import { mutations } from '../../conversationSearch';

describe('#mutations', () => {
  describe('#SEARCH_CONVERSATIONS_SET', () => {
    it('set records correctly', () => {
      const state = { records: [] };
      mutations[types.SEARCH_CONVERSATIONS_SET](state, [{ id: 1 }]);
      expect(state.records).toEqual([{ id: 1 }]);
    });
  });

  describe('#SEARCH_CONVERSATIONS_SET_UI_FLAG', () => {
    it('set uiFlags correctly', () => {
      const state = { uiFlags: { isFetching: true } };
      mutations[types.SEARCH_CONVERSATIONS_SET_UI_FLAG](state, {
        isFetching: false,
      });
      expect(state.uiFlags).toEqual({ isFetching: false });
    });
  });

  describe('#CONTACT_SEARCH_SET', () => {
    it('should append new contact records to existing ones', () => {
      const state = { contactRecords: [{ id: 1 }] };
      mutations[types.CONTACT_SEARCH_SET](state, [{ id: 2 }]);
      expect(state.contactRecords).toEqual([{ id: 1 }, { id: 2 }]);
    });
  });

  describe('#CONVERSATION_SEARCH_SET', () => {
    it('should append new conversation records to existing ones', () => {
      const state = { conversationRecords: [{ id: 1 }] };
      mutations[types.CONVERSATION_SEARCH_SET](state, [{ id: 2 }]);
      expect(state.conversationRecords).toEqual([{ id: 1 }, { id: 2 }]);
    });
  });

  describe('#MESSAGE_SEARCH_SET', () => {
    it('should append new message records to existing ones', () => {
      const state = { messageRecords: [{ id: 1 }] };
      mutations[types.MESSAGE_SEARCH_SET](state, [{ id: 2 }]);
      expect(state.messageRecords).toEqual([{ id: 1 }, { id: 2 }]);
    });
  });

  describe('#FULL_SEARCH_SET_UI_FLAG', () => {
    it('set full search UI flags correctly', () => {
      const state = {
        uiFlags: {
          isFetching: true,
          isSearchCompleted: false,
        },
      };
      mutations[types.FULL_SEARCH_SET_UI_FLAG](state, {
        isFetching: false,
        isSearchCompleted: true,
      });
      expect(state.uiFlags).toEqual({
        isFetching: false,
        isSearchCompleted: true,
      });
    });
  });

  describe('#CONTACT_SEARCH_SET_UI_FLAG', () => {
    it('set contact search UI flags correctly', () => {
      const state = {
        uiFlags: {
          contact: { isFetching: true },
        },
      };
      mutations[types.CONTACT_SEARCH_SET_UI_FLAG](state, { isFetching: false });
      expect(state.uiFlags.contact).toEqual({ isFetching: false });
    });
  });

  describe('#CONVERSATION_SEARCH_SET_UI_FLAG', () => {
    it('set conversation search UI flags correctly', () => {
      const state = {
        uiFlags: {
          conversation: { isFetching: true },
        },
      };
      mutations[types.CONVERSATION_SEARCH_SET_UI_FLAG](state, {
        isFetching: false,
      });
      expect(state.uiFlags.conversation).toEqual({ isFetching: false });
    });
  });

  describe('#MESSAGE_SEARCH_SET_UI_FLAG', () => {
    it('set message search UI flags correctly', () => {
      const state = {
        uiFlags: {
          message: { isFetching: true },
        },
      };
      mutations[types.MESSAGE_SEARCH_SET_UI_FLAG](state, { isFetching: false });
      expect(state.uiFlags.message).toEqual({ isFetching: false });
    });
  });

  describe('#CLEAR_SEARCH_RESULTS', () => {
    it('should clear all search records', () => {
      const state = {
        contactRecords: [{ id: 1 }],
        conversationRecords: [{ id: 1 }],
        messageRecords: [{ id: 1 }],
      };
      mutations[types.CLEAR_SEARCH_RESULTS](state);
      expect(state.contactRecords).toEqual([]);
      expect(state.conversationRecords).toEqual([]);
      expect(state.messageRecords).toEqual([]);
    });
  });
});
