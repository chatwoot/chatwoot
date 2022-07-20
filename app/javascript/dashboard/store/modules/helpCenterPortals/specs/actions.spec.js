import axios from 'axios';
import { actions } from '../actions';
import { apiResponse } from './fixtures';

const commit = jest.fn();
global.axios = axios;
jest.mock('axios');

// fetchAllHelpCenters;
// createHelpCenter;
// updateHelpCenter;
// deleteHelpCenter;

describe('#actions', () => {
  describe('#fetchAllHelpCenters', () => {
    it('sends correct actions if API is success', async () => {
      axios.get.mockResolvedValue({ data: apiResponse });
      await actions.fetchAllHelpCenters({ commit });
      expect(commit.mock.calls).toEqual([
        ['setUIFlag', { isFetching: true }],
        ['addHelpCenterEntry', apiResponse[0]],
        ['addHelpCenterId', 1],
        ['setHelpCenterUIFlag', { uiFlags: {}, helpCenterId: 1 }],
        ['addHelpCenterEntry', apiResponse[1]],
        ['addHelpCenterId', 2],
        ['setHelpCenterUIFlag', { uiFlags: {}, helpCenterId: 2 }],
        ['setUIFlag', { isFetching: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.get.mockRejectedValue({ message: 'Incorrect header' });
      await expect(actions.fetchAllHelpCenters({ commit })).rejects.toThrow(
        Error
      );
      expect(commit.mock.calls).toEqual([
        ['setUIFlag', { isFetching: true }],
        ['setUIFlag', { isFetching: false }],
      ]);
    });
  });

  describe('#createHelpCenter', () => {
    it('sends correct actions if API is success', async () => {
      axios.post.mockResolvedValue({ data: apiResponse[1] });
      await actions.createHelpCenter(
        { commit },
        {
          color: 'red',
          custom_domain: 'domain_for_help',
          header_text: 'Domain Header',
        }
      );
      expect(commit.mock.calls).toEqual([
        ['setUIFlag', { isCreating: true }],
        ['addHelpCenterEntry', apiResponse[1]],
        ['addHelpCenterId', 2],
        ['setUIFlag', { isCreating: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.post.mockRejectedValue({ message: 'Incorrect header' });
      await expect(actions.createHelpCenter({ commit }, {})).rejects.toThrow(
        Error
      );
      expect(commit.mock.calls).toEqual([
        ['setUIFlag', { isCreating: true }],
        ['setUIFlag', { isCreating: false }],
      ]);
    });
  });

  describe('#updateHelpCenter', () => {
    it('sends correct actions if API is success', async () => {
      axios.patch.mockResolvedValue({ data: apiResponse[1] });
      await actions.updateHelpCenter(
        { commit },
        { helpCenter: apiResponse[1] }
      );
      expect(commit.mock.calls).toEqual([
        [
          'setHelpCenterUIFlag',
          {
            uiFlags: {
              isUpdating: true,
            },
            helpCenterId: 2,
          },
        ],
        ['updateHelpCenterEntry', apiResponse[1]],
        [
          'setHelpCenterUIFlag',
          {
            uiFlags: {
              isUpdating: false,
            },
            helpCenterId: 2,
          },
        ],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.patch.mockRejectedValue({ message: 'Incorrect header' });
      await expect(
        actions.updateHelpCenter({ commit }, { helpCenter: apiResponse[1] })
      ).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [
          'setHelpCenterUIFlag',
          {
            uiFlags: {
              isUpdating: true,
            },
            helpCenterId: 2,
          },
        ],
        [
          'setHelpCenterUIFlag',
          {
            uiFlags: {
              isUpdating: false,
            },
            helpCenterId: 2,
          },
        ],
      ]);
    });
  });

  describe('#deleteHelpCenter', () => {
    it('sends correct actions if API is success', async () => {
      axios.delete.mockResolvedValue({});
      await actions.deleteHelpCenter({ commit }, { helpCenterId: 2 });
      expect(commit.mock.calls).toEqual([
        [
          'setHelpCenterUIFlag',
          {
            uiFlags: {
              isDeleting: true,
            },
            helpCenterId: 2,
          },
        ],
        ['removeHelpCenterEntry', 2],
        ['removeHelpCenterId', 2],
        [
          'setHelpCenterUIFlag',
          {
            uiFlags: {
              isDeleting: false,
            },
            helpCenterId: 2,
          },
        ],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.delete.mockRejectedValue({ message: 'Incorrect header' });
      await expect(
        actions.deleteHelpCenter({ commit }, { helpCenterId: 2 })
      ).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [
          'setHelpCenterUIFlag',
          {
            uiFlags: {
              isDeleting: true,
            },
            helpCenterId: 2,
          },
        ],
        [
          'setHelpCenterUIFlag',
          {
            uiFlags: {
              isDeleting: false,
            },
            helpCenterId: 2,
          },
        ],
      ]);
    });
  });
});
