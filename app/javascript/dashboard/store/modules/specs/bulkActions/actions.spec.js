import axios from 'axios';
import { actions } from '../../bulkActions';
import * as types from '../../../mutation-types';
import payload from './fixtures';
const commit = jest.fn();
global.axios = axios;
jest.mock('axios');

describe('#actions', () => {
  describe('#create', () => {
    it('sends correct actions if API is success', async () => {
      axios.post.mockResolvedValue({ data: payload });
      await actions.process({ commit }, payload);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_BULK_ACTIONS_FLAG, { isUpdating: true }],
        [types.default.SET_BULK_ACTIONS_FLAG, { isUpdating: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.post.mockRejectedValue({ message: 'Incorrect header' });
      await expect(actions.process({ commit })).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_BULK_ACTIONS_FLAG, { isUpdating: true }],
        [types.default.SET_BULK_ACTIONS_FLAG, { isUpdating: false }],
      ]);
    });
  });
});
