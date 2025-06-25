import axios from 'axios';
import { actions } from '../../sla';
import * as types from '../../../mutation-types';
import SLAList from './fixtures';

const commit = vi.fn();
global.axios = axios;
vi.mock('axios');

describe('#actions', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('#get', () => {
    it('sends correct actions if API is success', async () => {
      axios.get.mockResolvedValue({
        data: { payload: SLAList },
      });
      await actions.get({ commit });
      expect(commit.mock.calls).toEqual([
        [types.default.SET_SLA_UI_FLAG, { isFetching: true }],
        [types.default.SET_SLA, SLAList],
        [types.default.SET_SLA_UI_FLAG, { isFetching: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.get.mockRejectedValue({ message: 'Incorrect header' });
      await actions.get({ commit });
      expect(commit.mock.calls).toEqual([
        [types.default.SET_SLA_UI_FLAG, { isFetching: true }],
        [types.default.SET_SLA_UI_FLAG, { isFetching: false }],
      ]);
    });
  });

  describe('#create', () => {
    it('sends correct actions if API is success', async () => {
      axios.post.mockResolvedValue({
        data: { payload: SLAList[0] },
      });
      await actions.create({ commit }, SLAList[0]);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_SLA_UI_FLAG, { isCreating: true }],
        [types.default.ADD_SLA, SLAList[0]],
        [types.default.SET_SLA_UI_FLAG, { isCreating: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.post.mockRejectedValue({ message: 'Incorrect header' });
      await expect(actions.create({ commit })).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_SLA_UI_FLAG, { isCreating: true }],
        [types.default.SET_SLA_UI_FLAG, { isCreating: false }],
      ]);
    });
  });

  describe('#delete', () => {
    it('sends correct actions if API is success', async () => {
      axios.delete.mockResolvedValue({});
      await actions.delete({ commit }, 1);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_SLA_UI_FLAG, { isDeleting: true }],
        [types.default.DELETE_SLA, 1],
        [types.default.SET_SLA_UI_FLAG, { isDeleting: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.delete.mockRejectedValue({ message: 'Incorrect header' });
      await expect(actions.delete({ commit })).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_SLA_UI_FLAG, { isDeleting: true }],
        [types.default.SET_SLA_UI_FLAG, { isDeleting: false }],
      ]);
    });
  });
});
