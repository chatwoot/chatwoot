import axios from 'axios';
import actions from '../actions';
import * as types from '../../../mutation-types';

const commit = jest.fn();
global.axios = axios;
jest.mock('axios');

describe('#actions', () => {
  describe('#getConversationStats', () => {
    it('sends correct actions if API is success', async () => {
      axios.get.mockResolvedValue({ data: { meta: { mine_count: 1 } } });
      await actions.getConversationStats(
        { commit },
        { inboxId: 1, assigneeTpe: 'me', status: 'open' }
      );
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CONV_TAB_META, { mine_count: 1 }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.get.mockRejectedValue({ message: 'Incorrect header' });
      await actions.getConversationStats(
        { commit },
        { inboxId: 1, assigneeTpe: 'me', status: 'open' }
      );
      expect(commit.mock.calls).toEqual([]);
    });
  });
});
