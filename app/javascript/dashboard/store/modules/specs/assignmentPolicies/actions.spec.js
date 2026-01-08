import axios from 'axios';
import { actions } from '../../assignmentPolicies';
import types from '../../../mutation-types';
import assignmentPoliciesList, { camelCaseFixtures } from './fixtures';
import camelcaseKeys from 'camelcase-keys';
import snakecaseKeys from 'snakecase-keys';

const commit = vi.fn();

global.axios = axios;
vi.mock('axios');
vi.mock('camelcase-keys');
vi.mock('snakecase-keys');
vi.mock('../../../utils/api');

describe('#actions', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('#get', () => {
    it('sends correct actions if API is success', async () => {
      axios.get.mockResolvedValue({ data: assignmentPoliciesList });
      camelcaseKeys.mockReturnValue(camelCaseFixtures);

      await actions.get({ commit });

      expect(camelcaseKeys).toHaveBeenCalledWith(assignmentPoliciesList);
      expect(commit.mock.calls).toEqual([
        [types.SET_ASSIGNMENT_POLICIES_UI_FLAG, { isFetching: true }],
        [types.SET_ASSIGNMENT_POLICIES, camelCaseFixtures],
        [types.SET_ASSIGNMENT_POLICIES_UI_FLAG, { isFetching: false }],
      ]);
    });

    it('sends correct actions if API is error', async () => {
      axios.get.mockRejectedValue({ message: 'Incorrect header' });

      await actions.get({ commit });

      expect(commit.mock.calls).toEqual([
        [types.SET_ASSIGNMENT_POLICIES_UI_FLAG, { isFetching: true }],
        [types.SET_ASSIGNMENT_POLICIES_UI_FLAG, { isFetching: false }],
      ]);
    });
  });

  describe('#show', () => {
    it('sends correct actions if API is success', async () => {
      const policyData = assignmentPoliciesList[0];
      const camelCasedPolicy = camelCaseFixtures[0];

      axios.get.mockResolvedValue({ data: policyData });
      camelcaseKeys.mockReturnValue(camelCasedPolicy);

      await actions.show({ commit }, 1);

      expect(camelcaseKeys).toHaveBeenCalledWith(policyData);
      expect(commit.mock.calls).toEqual([
        [types.SET_ASSIGNMENT_POLICIES_UI_FLAG, { isFetchingItem: true }],
        [types.SET_ASSIGNMENT_POLICY, camelCasedPolicy],
        [types.SET_ASSIGNMENT_POLICIES_UI_FLAG, { isFetchingItem: false }],
      ]);
    });

    it('sends correct actions if API is error', async () => {
      axios.get.mockRejectedValue({ message: 'Not found' });

      await actions.show({ commit }, 1);

      expect(commit.mock.calls).toEqual([
        [types.SET_ASSIGNMENT_POLICIES_UI_FLAG, { isFetchingItem: true }],
        [types.SET_ASSIGNMENT_POLICIES_UI_FLAG, { isFetchingItem: false }],
      ]);
    });
  });

  describe('#create', () => {
    it('sends correct actions if API is success', async () => {
      const newPolicy = assignmentPoliciesList[0];
      const camelCasedData = camelCaseFixtures[0];
      const snakeCasedPolicy = { assignment_order: 'round_robin' };

      axios.post.mockResolvedValue({ data: newPolicy });
      camelcaseKeys.mockReturnValue(camelCasedData);
      snakecaseKeys.mockReturnValue(snakeCasedPolicy);

      const result = await actions.create({ commit }, newPolicy);

      expect(snakecaseKeys).toHaveBeenCalledWith(newPolicy);
      expect(camelcaseKeys).toHaveBeenCalledWith(newPolicy);
      expect(commit.mock.calls).toEqual([
        [types.SET_ASSIGNMENT_POLICIES_UI_FLAG, { isCreating: true }],
        [types.ADD_ASSIGNMENT_POLICY, camelCasedData],
        [types.SET_ASSIGNMENT_POLICIES_UI_FLAG, { isCreating: false }],
      ]);
      expect(result).toEqual(newPolicy);
    });

    it('sends correct actions if API is error', async () => {
      axios.post.mockRejectedValue(new Error('Validation error'));

      await expect(actions.create({ commit }, {})).rejects.toThrow(Error);

      expect(commit.mock.calls).toEqual([
        [types.SET_ASSIGNMENT_POLICIES_UI_FLAG, { isCreating: true }],
        [types.SET_ASSIGNMENT_POLICIES_UI_FLAG, { isCreating: false }],
      ]);
    });
  });

  describe('#update', () => {
    it('sends correct actions if API is success', async () => {
      const updateParams = { id: 1, name: 'Updated Policy' };
      const responseData = {
        ...assignmentPoliciesList[0],
        name: 'Updated Policy',
      };
      const camelCasedData = {
        ...camelCaseFixtures[0],
        name: 'Updated Policy',
      };
      const snakeCasedParams = { name: 'Updated Policy' };

      axios.patch.mockResolvedValue({ data: responseData });
      camelcaseKeys.mockReturnValue(camelCasedData);
      snakecaseKeys.mockReturnValue(snakeCasedParams);

      const result = await actions.update({ commit }, updateParams);

      expect(snakecaseKeys).toHaveBeenCalledWith({ name: 'Updated Policy' });
      expect(camelcaseKeys).toHaveBeenCalledWith(responseData);
      expect(commit.mock.calls).toEqual([
        [types.SET_ASSIGNMENT_POLICIES_UI_FLAG, { isUpdating: true }],
        [types.EDIT_ASSIGNMENT_POLICY, camelCasedData],
        [types.SET_ASSIGNMENT_POLICIES_UI_FLAG, { isUpdating: false }],
      ]);
      expect(result).toEqual(responseData);
    });

    it('sends correct actions if API is error', async () => {
      axios.patch.mockRejectedValue(new Error('Validation error'));

      await expect(
        actions.update({ commit }, { id: 1, name: 'Test' })
      ).rejects.toThrow(Error);

      expect(commit.mock.calls).toEqual([
        [types.SET_ASSIGNMENT_POLICIES_UI_FLAG, { isUpdating: true }],
        [types.SET_ASSIGNMENT_POLICIES_UI_FLAG, { isUpdating: false }],
      ]);
    });
  });

  describe('#delete', () => {
    it('sends correct actions if API is success', async () => {
      const policyId = 1;
      axios.delete.mockResolvedValue({});

      await actions.delete({ commit }, policyId);

      expect(commit.mock.calls).toEqual([
        [types.SET_ASSIGNMENT_POLICIES_UI_FLAG, { isDeleting: true }],
        [types.DELETE_ASSIGNMENT_POLICY, policyId],
        [types.SET_ASSIGNMENT_POLICIES_UI_FLAG, { isDeleting: false }],
      ]);
    });

    it('sends correct actions if API is error', async () => {
      axios.delete.mockRejectedValue(new Error('Not found'));

      await expect(actions.delete({ commit }, 1)).rejects.toThrow(Error);

      expect(commit.mock.calls).toEqual([
        [types.SET_ASSIGNMENT_POLICIES_UI_FLAG, { isDeleting: true }],
        [types.SET_ASSIGNMENT_POLICIES_UI_FLAG, { isDeleting: false }],
      ]);
    });
  });

  describe('#getInboxes', () => {
    it('sends correct actions if API is success', async () => {
      const policyId = 1;
      const inboxData = {
        inboxes: [
          { id: 1, name: 'Support' },
          { id: 2, name: 'Sales' },
        ],
      };
      const camelCasedInboxes = [
        { id: 1, name: 'Support' },
        { id: 2, name: 'Sales' },
      ];

      axios.get.mockResolvedValue({ data: inboxData });
      camelcaseKeys.mockReturnValue(camelCasedInboxes);

      await actions.getInboxes({ commit }, policyId);

      expect(camelcaseKeys).toHaveBeenCalledWith(inboxData.inboxes);
      expect(commit.mock.calls).toEqual([
        [types.SET_ASSIGNMENT_POLICIES_INBOXES_UI_FLAG, { isFetching: true }],
        [
          types.SET_ASSIGNMENT_POLICIES_INBOXES,
          { policyId, inboxes: camelCasedInboxes },
        ],
        [types.SET_ASSIGNMENT_POLICIES_INBOXES_UI_FLAG, { isFetching: false }],
      ]);
    });

    it('sends correct actions if API fails', async () => {
      axios.get.mockRejectedValue(new Error('API Error'));

      await expect(actions.getInboxes({ commit }, 1)).rejects.toThrow(Error);

      expect(commit.mock.calls).toEqual([
        [types.SET_ASSIGNMENT_POLICIES_INBOXES_UI_FLAG, { isFetching: true }],
        [types.SET_ASSIGNMENT_POLICIES_INBOXES_UI_FLAG, { isFetching: false }],
      ]);
    });
  });

  describe('#setInboxPolicy', () => {
    it('sends correct actions if API is success', async () => {
      const responseData = { success: true, policy_id: 2 };
      const camelCasedData = { success: true, policyId: 2 };

      axios.post.mockResolvedValue({ data: responseData });
      camelcaseKeys.mockReturnValue(camelCasedData);

      const result = await actions.setInboxPolicy(
        { commit },
        { inboxId: 1, policyId: 2 }
      );

      expect(camelcaseKeys).toHaveBeenCalledWith(responseData);
      expect(commit.mock.calls).toEqual([
        [types.ADD_ASSIGNMENT_POLICIES_INBOXES, camelCasedData],
      ]);
      expect(result).toEqual(responseData);
    });

    it('throws error if API fails', async () => {
      axios.post.mockRejectedValue(new Error('API Error'));

      await expect(
        actions.setInboxPolicy({ commit }, { inboxId: 1, policyId: 2 })
      ).rejects.toThrow(Error);
    });
  });

  describe('#getInboxPolicy', () => {
    it('returns camelCased response data if API is success', async () => {
      const responseData = { policy_id: 1, name: 'Round Robin' };
      const camelCasedData = { policyId: 1, name: 'Round Robin' };

      axios.get.mockResolvedValue({ data: responseData });
      camelcaseKeys.mockReturnValue(camelCasedData);

      const result = await actions.getInboxPolicy({}, { inboxId: 1 });

      expect(camelcaseKeys).toHaveBeenCalledWith(responseData);
      expect(result).toEqual(camelCasedData);
    });

    it('throws error if API fails', async () => {
      axios.get.mockRejectedValue(new Error('Not found'));

      await expect(
        actions.getInboxPolicy({}, { inboxId: 999 })
      ).rejects.toThrow(Error);
    });
  });

  describe('#updateInboxPolicy', () => {
    it('commits EDIT_ASSIGNMENT_POLICY mutation', async () => {
      const policy = { id: 1, name: 'Updated Policy' };

      await actions.updateInboxPolicy({ commit }, { policy });

      expect(commit.mock.calls).toEqual([
        [types.EDIT_ASSIGNMENT_POLICY, policy],
      ]);
    });

    it('throws error if commit fails', async () => {
      commit.mockImplementation(() => {
        throw new Error('Commit failed');
      });

      await expect(
        actions.updateInboxPolicy({ commit }, { policy: {} })
      ).rejects.toThrow(Error);
    });
  });

  describe('#removeInboxPolicy', () => {
    it('sends correct actions if API is success', async () => {
      const policyId = 1;
      const inboxId = 2;

      axios.delete.mockResolvedValue({});

      await actions.removeInboxPolicy({ commit }, { policyId, inboxId });

      expect(commit.mock.calls).toEqual([
        [types.SET_ASSIGNMENT_POLICIES_INBOXES_UI_FLAG, { isDeleting: true }],
        [types.DELETE_ASSIGNMENT_POLICIES_INBOXES, { policyId, inboxId }],
        [types.SET_ASSIGNMENT_POLICIES_INBOXES_UI_FLAG, { isDeleting: false }],
      ]);
    });

    it('sends correct actions if API fails', async () => {
      axios.delete.mockRejectedValue(new Error('Not found'));

      await expect(
        actions.removeInboxPolicy({ commit }, { policyId: 1, inboxId: 999 })
      ).rejects.toThrow(Error);

      expect(commit.mock.calls).toEqual([
        [types.SET_ASSIGNMENT_POLICIES_INBOXES_UI_FLAG, { isDeleting: true }],
        [types.SET_ASSIGNMENT_POLICIES_INBOXES_UI_FLAG, { isDeleting: false }],
      ]);
    });
  });
});
