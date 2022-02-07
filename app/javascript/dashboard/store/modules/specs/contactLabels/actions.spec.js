import axios from 'axios';
import { actions } from '../../contactLabels';
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
        [types.default.SET_CONTACT_LABELS_UI_FLAG, { isFetching: true }],

        [
          types.default.SET_CONTACT_LABELS,
          { id: 1, data: ['customer-success', 'on-hold'] },
        ],
        [types.default.SET_CONTACT_LABELS_UI_FLAG, { isFetching: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.get.mockRejectedValue({ message: 'Incorrect header' });
      await actions.get({ commit });
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CONTACT_LABELS_UI_FLAG, { isFetching: true }],
        [types.default.SET_CONTACT_LABELS_UI_FLAG, { isFetching: false }],
      ]);
    });
  });

  describe('#update', () => {
    it('updates correct actions if API is success', async () => {
      axios.post.mockResolvedValue({
        data: { payload: { contactId: '1', labels: ['on-hold'] } },
      });
      await actions.update({ commit }, { contactId: '1', labels: ['on-hold'] });

      expect(commit.mock.calls).toEqual([
        [types.default.SET_CONTACT_LABELS_UI_FLAG, { isUpdating: true }],
        [
          types.default.SET_CONTACT_LABELS,
          {
            id: '1',
            data: { contactId: '1', labels: ['on-hold'] },
          },
        ],
        [
          types.default.SET_CONTACT_LABELS_UI_FLAG,
          { isUpdating: false, isError: false },
        ],
      ]);
    });

    it('sends correct actions if API is error', async () => {
      axios.post.mockRejectedValue({ message: 'Incorrect header' });
      await expect(
        actions.update({ commit }, { contactId: '1', labels: ['on-hold'] })
      ).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CONTACT_LABELS_UI_FLAG, { isUpdating: true }],
        [
          types.default.SET_CONTACT_LABELS_UI_FLAG,
          { isUpdating: false, isError: true },
        ],
      ]);
    });
  });
});
