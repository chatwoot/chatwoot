import { getters } from '../../draftMessages';
import { data } from './fixtures';

describe('#getters', () => {
  it('return the payload if key is present', () => {
    const state = {
      records: data,
    };
    expect(getters.get(state)('draft-32-REPLY')).toEqual('Hey how ');
  });

  it('return empty string if key is not present', () => {
    const state = {
      records: data,
    };
    expect(getters.get(state)('draft-22-REPLY')).toEqual('');
  });

  it('return replyEditorMode', () => {
    const state = {
      replyEditorMode: 'reply',
    };
    expect(getters.getReplyEditorMode(state)).toEqual('reply');
  });

  describe('#getInReplyTo', () => {
    it('returns the inReplyTo value if key is present', () => {
      const state = {
        inReplyTo: {
          1234: 9876,
        },
      };
      expect(getters.getInReplyTo(state)(1234)).toEqual(9876);
    });

    it('returns undefined if key is not present', () => {
      const state = {
        inReplyTo: {
          1234: 9876,
        },
      };
      expect(getters.getInReplyTo(state)('message-22')).toBeUndefined();
    });
  });
});
