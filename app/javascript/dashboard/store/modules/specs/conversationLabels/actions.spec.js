import axios from 'axios';
import { actions } from '../../conversationLabels';
import * as types from '../../../mutation-types';

const commit = jest.fn();
global.axios = axios;
jest.mock('axios');

describe('#actions', () => {
  describe('#get', () => {
    it('sends correct actions if API is success', async () => {
      axios.get.mockResolvedValue({
        data: { payload: ['customer-success', 'on-hold'] },
      });
      await actions.get({ commit }, 1);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CONVERSATION_LABELS_UI_FLAG, { isFetching: true }],

        [
          types.default.SET_CONVERSATION_LABELS,
          { id: 1, data: ['customer-success', 'on-hold'] },
        ],
        [types.default.SET_CONVERSATION_LABELS_UI_FLAG, { isFetching: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.get.mockRejectedValue({ message: 'Incorrect header' });
      await actions.get({ commit });
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CONVERSATION_LABELS_UI_FLAG, { isFetching: true }],
        [types.default.SET_CONVERSATION_LABELS_UI_FLAG, { isFetching: false }],
      ]);
    });
  });
});
