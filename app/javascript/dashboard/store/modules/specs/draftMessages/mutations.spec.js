import types from '../../../mutation-types';
import { mutations } from '../../draftMessages';

describe('#mutations', () => {
  describe('#SET_DRAFT_MESSAGES', () => {
    it('sets the draft messages', () => {
      const state = {
        records: {},
      };
      mutations[types.SET_DRAFT_MESSAGES](state, {
        key: 'draft-32-REPLY',
        message: 'Hey how ',
      });
      expect(state.records).toEqual({
        'draft-32-REPLY': 'Hey how ',
      });
    });
  });

  describe('#REMOVE_DRAFT_MESSAGES', () => {
    it('removes the draft messages', () => {
      const state = {
        records: {
          'draft-32-REPLY': 'Hey how ',
        },
      };
      mutations[types.REMOVE_DRAFT_MESSAGES](state, {
        key: 'draft-32-REPLY',
      });
      expect(state.records).toEqual({});
    });
  });

  describe('#SET_IN_REPLY_TO', () => {
    it('sets the inReplyTo value', () => {
      const state = {
        inReplyTo: {},
      };
      mutations[types.SET_IN_REPLY_TO](state, {
        conversationId: 1234,
        inReplyToMessage: 9876,
      });
      expect(state.inReplyTo).toEqual({
        1234: 9876,
      });
    });
  });

  describe('#REMOVE_IN_REPLY_TO', () => {
    it('removes the inReplyTo value', () => {
      const state = {
        inReplyTo: {
          1234: 9876,
        },
      };
      mutations[types.REMOVE_IN_REPLY_TO](state, {
        conversationId: 1234,
      });
      expect(state.inReplyTo).toEqual({});
    });
  });

  describe('#SET_REPLY_EDITOR_MODE', () => {
    it('sets the reply editor mode', () => {
      const state = {
        replyEditorMode: 'reply',
      };
      mutations[types.SET_REPLY_EDITOR_MODE](state, {
        mode: 'note',
      });
      expect(state.replyEditorMode).toEqual('note');
    });
  });
});
