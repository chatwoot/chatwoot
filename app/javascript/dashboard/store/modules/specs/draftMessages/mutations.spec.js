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
