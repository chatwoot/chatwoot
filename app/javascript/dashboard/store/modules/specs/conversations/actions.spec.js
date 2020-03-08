import axios from 'axios';
import actions from '../../conversations/actions';
import * as types from '../../../mutation-types';

const commit = jest.fn();
global.axios = axios;
jest.mock('axios');

describe('#actions', () => {
  describe('#getConversation', () => {
    it('sends correct actions if API is success', async () => {
      axios.get.mockResolvedValue({ data: { id: 1, meta: {} } });
      await actions.getConversation({ commit }, 1);
      expect(commit.mock.calls).toEqual([
        [types.default.ADD_CONVERSATION, { id: 1, meta: {} }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.get.mockRejectedValue({ message: 'Incorrect header' });
      await actions.getConversation({ commit });
      expect(commit.mock.calls).toEqual([]);
    });
  });
});
