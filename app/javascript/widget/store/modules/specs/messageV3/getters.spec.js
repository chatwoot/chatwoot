import { getters } from '../../messageV3/getters';

describe('getters', () => {
  describe('uIFlags', () => {
    it('returns the uiFlags from state', () => {
      const state = {
        uiFlags: {
          isError: false,
          hasFetched: true,
          isFetching: false,
        },
      };

      const result = getters.uIFlags(state);

      expect(result).toEqual(state.uiFlags);
    });
  });

  describe('messageById', () => {
    it('returns the correct message for a given messageId', () => {
      const state = {
        messages: {
          byId: {
            '1': { id: '1', content: 'Message 1' },
            '2': { id: '2', content: 'Message 2' },
          },
        },
      };

      const result1 = getters.messageById(state)('1');
      const result2 = getters.messageById(state)('2');

      expect(result1).toEqual(state.messages.byId['1']);
      expect(result2).toEqual(state.messages.byId['2']);
    });

    it('returns undefined if messageId does not exist', () => {
      const state = {
        messages: {
          byId: {},
        },
      };

      const result = getters.messageById(state)('nonexistent');

      expect(result).toBeUndefined();
    });
  });
});
