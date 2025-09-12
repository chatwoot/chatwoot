import axios from 'axios';
import { actions } from '../../agentCapacityPolicies';
import types from '../../../mutation-types';
import agentCapacityPoliciesList, { camelCaseFixtures } from './fixtures';
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
      axios.get.mockResolvedValue({ data: agentCapacityPoliciesList });
      camelcaseKeys.mockReturnValue(camelCaseFixtures);

      await actions.get({ commit });

      expect(camelcaseKeys).toHaveBeenCalledWith(agentCapacityPoliciesList);
      expect(commit.mock.calls).toEqual([
        [types.SET_AGENT_CAPACITY_POLICIES_UI_FLAG, { isFetching: true }],
        [types.SET_AGENT_CAPACITY_POLICIES, camelCaseFixtures],
        [types.SET_AGENT_CAPACITY_POLICIES_UI_FLAG, { isFetching: false }],
      ]);
    });

    it('sends correct actions if API is error', async () => {
      axios.get.mockRejectedValue({ message: 'Incorrect header' });

      await actions.get({ commit });

      expect(commit.mock.calls).toEqual([
        [types.SET_AGENT_CAPACITY_POLICIES_UI_FLAG, { isFetching: true }],
        [types.SET_AGENT_CAPACITY_POLICIES_UI_FLAG, { isFetching: false }],
      ]);
    });
  });

  describe('#show', () => {
    it('sends correct actions if API is success', async () => {
      const policyData = agentCapacityPoliciesList[0];
      const camelCasedPolicy = camelCaseFixtures[0];

      axios.get.mockResolvedValue({ data: policyData });
      camelcaseKeys.mockReturnValue(camelCasedPolicy);

      await actions.show({ commit }, 1);

      expect(camelcaseKeys).toHaveBeenCalledWith(policyData);
      expect(commit.mock.calls).toEqual([
        [types.SET_AGENT_CAPACITY_POLICIES_UI_FLAG, { isFetchingItem: true }],
        [types.SET_AGENT_CAPACITY_POLICY, camelCasedPolicy],
        [types.SET_AGENT_CAPACITY_POLICIES_UI_FLAG, { isFetchingItem: false }],
      ]);
    });

    it('sends correct actions if API is error', async () => {
      axios.get.mockRejectedValue({ message: 'Not found' });

      await actions.show({ commit }, 1);

      expect(commit.mock.calls).toEqual([
        [types.SET_AGENT_CAPACITY_POLICIES_UI_FLAG, { isFetchingItem: true }],
        [types.SET_AGENT_CAPACITY_POLICIES_UI_FLAG, { isFetchingItem: false }],
      ]);
    });
  });

  describe('#create', () => {
    it('sends correct actions if API is success', async () => {
      const newPolicy = agentCapacityPoliciesList[0];
      const camelCasedData = camelCaseFixtures[0];
      const snakeCasedPolicy = { default_capacity: 10 };

      axios.post.mockResolvedValue({ data: newPolicy });
      camelcaseKeys.mockReturnValue(camelCasedData);
      snakecaseKeys.mockReturnValue(snakeCasedPolicy);

      const result = await actions.create({ commit }, newPolicy);

      expect(snakecaseKeys).toHaveBeenCalledWith(newPolicy);
      expect(camelcaseKeys).toHaveBeenCalledWith(newPolicy);
      expect(commit.mock.calls).toEqual([
        [types.SET_AGENT_CAPACITY_POLICIES_UI_FLAG, { isCreating: true }],
        [types.ADD_AGENT_CAPACITY_POLICY, camelCasedData],
        [types.SET_AGENT_CAPACITY_POLICIES_UI_FLAG, { isCreating: false }],
      ]);
      expect(result).toEqual(newPolicy);
    });

    it('sends correct actions if API is error', async () => {
      axios.post.mockRejectedValue(new Error('Validation error'));

      await expect(actions.create({ commit }, {})).rejects.toThrow(Error);

      expect(commit.mock.calls).toEqual([
        [types.SET_AGENT_CAPACITY_POLICIES_UI_FLAG, { isCreating: true }],
        [types.SET_AGENT_CAPACITY_POLICIES_UI_FLAG, { isCreating: false }],
      ]);
    });
  });

  describe('#update', () => {
    it('sends correct actions if API is success', async () => {
      const updateParams = { id: 1, name: 'Updated Policy' };
      const responseData = {
        ...agentCapacityPoliciesList[0],
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
        [types.SET_AGENT_CAPACITY_POLICIES_UI_FLAG, { isUpdating: true }],
        [types.EDIT_AGENT_CAPACITY_POLICY, camelCasedData],
        [types.SET_AGENT_CAPACITY_POLICIES_UI_FLAG, { isUpdating: false }],
      ]);
      expect(result).toEqual(responseData);
    });

    it('sends correct actions if API is error', async () => {
      axios.patch.mockRejectedValue(new Error('Validation error'));

      await expect(
        actions.update({ commit }, { id: 1, name: 'Test' })
      ).rejects.toThrow(Error);

      expect(commit.mock.calls).toEqual([
        [types.SET_AGENT_CAPACITY_POLICIES_UI_FLAG, { isUpdating: true }],
        [types.SET_AGENT_CAPACITY_POLICIES_UI_FLAG, { isUpdating: false }],
      ]);
    });
  });

  describe('#delete', () => {
    it('sends correct actions if API is success', async () => {
      const policyId = 1;
      axios.delete.mockResolvedValue({});

      await actions.delete({ commit }, policyId);

      expect(commit.mock.calls).toEqual([
        [types.SET_AGENT_CAPACITY_POLICIES_UI_FLAG, { isDeleting: true }],
        [types.DELETE_AGENT_CAPACITY_POLICY, policyId],
        [types.SET_AGENT_CAPACITY_POLICIES_UI_FLAG, { isDeleting: false }],
      ]);
    });

    it('sends correct actions if API is error', async () => {
      axios.delete.mockRejectedValue(new Error('Not found'));

      await expect(actions.delete({ commit }, 1)).rejects.toThrow(Error);

      expect(commit.mock.calls).toEqual([
        [types.SET_AGENT_CAPACITY_POLICIES_UI_FLAG, { isDeleting: true }],
        [types.SET_AGENT_CAPACITY_POLICIES_UI_FLAG, { isDeleting: false }],
      ]);
    });
  });

  describe('#getUsers', () => {
    it('sends correct actions if API is success', async () => {
      const policyId = 1;
      const userData = [
        { id: 1, name: 'Agent 1', email: 'agent1@example.com', capacity: 15 },
        { id: 2, name: 'Agent 2', email: 'agent2@example.com', capacity: 20 },
      ];
      const camelCasedUsers = [
        { id: 1, name: 'Agent 1', email: 'agent1@example.com', capacity: 15 },
        { id: 2, name: 'Agent 2', email: 'agent2@example.com', capacity: 20 },
      ];

      axios.get.mockResolvedValue({ data: userData });
      camelcaseKeys.mockReturnValue(camelCasedUsers);

      const result = await actions.getUsers({ commit }, policyId);

      expect(camelcaseKeys).toHaveBeenCalledWith(userData);
      expect(commit.mock.calls).toEqual([
        [types.SET_AGENT_CAPACITY_POLICIES_USERS_UI_FLAG, { isFetching: true }],
        [
          types.SET_AGENT_CAPACITY_POLICIES_USERS,
          { policyId, users: camelCasedUsers },
        ],
        [
          types.SET_AGENT_CAPACITY_POLICIES_USERS_UI_FLAG,
          { isFetching: false },
        ],
      ]);
      expect(result).toEqual(userData);
    });

    it('sends correct actions if API fails', async () => {
      axios.get.mockRejectedValue(new Error('API Error'));

      await expect(actions.getUsers({ commit }, 1)).rejects.toThrow(Error);

      expect(commit.mock.calls).toEqual([
        [types.SET_AGENT_CAPACITY_POLICIES_USERS_UI_FLAG, { isFetching: true }],
        [
          types.SET_AGENT_CAPACITY_POLICIES_USERS_UI_FLAG,
          { isFetching: false },
        ],
      ]);
    });
  });
});
