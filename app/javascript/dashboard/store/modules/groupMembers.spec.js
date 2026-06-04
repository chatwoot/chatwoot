import axios from 'axios';
import { actions, getters, mutations, state } from './groupMembers';
import * as types from '../mutation-types';

const commit = vi.fn();
const dispatch = vi.fn();
global.axios = axios;
vi.mock('axios');
vi.mock('../../api/groupMembers', () => ({
  default: {
    getGroupMembers: vi.fn(),
    syncGroup: vi.fn(),
    addMembers: vi.fn(),
    removeMembers: vi.fn(),
    updateMemberRole: vi.fn(),
  },
}));

import GroupMembersAPI from '../../api/groupMembers';

const sampleMembers = [
  { id: 1, role: 'admin', is_active: true, contact: { id: 10, name: 'Alice' } },
  { id: 2, role: 'member', is_active: true, contact: { id: 11, name: 'Bob' } },
];

describe('groupMembers store', () => {
  beforeEach(() => {
    commit.mockClear();
    dispatch.mockClear();
  });

  describe('getters', () => {
    it('getGroupMembers returns members for a contactId', () => {
      const localState = { records: { 42: sampleMembers } };
      expect(getters.getGroupMembers(localState)(42)).toEqual(sampleMembers);
    });

    it('getGroupMembers returns empty array for unknown contactId', () => {
      const localState = { records: {} };
      expect(getters.getGroupMembers(localState)(99)).toEqual([]);
    });

    it('getUIFlags returns uiFlags', () => {
      const localState = {
        uiFlags: { isFetching: true, isSyncing: false, isUpdating: false },
      };
      expect(getters.getUIFlags(localState)).toEqual(localState.uiFlags);
    });
  });

  describe('mutations', () => {
    it('SET_GROUP_MEMBERS_UI_FLAG merges flags', () => {
      const localState = { ...state };
      mutations[types.default.SET_GROUP_MEMBERS_UI_FLAG](localState, {
        isFetching: true,
      });
      expect(localState.uiFlags.isFetching).toBe(true);
    });

    it('SET_GROUP_MEMBERS stores members keyed by contactId', () => {
      const localState = { records: {} };
      mutations[types.default.SET_GROUP_MEMBERS](localState, {
        contactId: 42,
        members: sampleMembers,
      });
      expect(localState.records[42]).toEqual(sampleMembers);
    });
  });

  describe('actions', () => {
    describe('setGroupMembers', () => {
      it('commits SET_GROUP_MEMBERS directly', () => {
        actions.setGroupMembers(
          { commit },
          { contactId: 42, members: sampleMembers }
        );
        expect(commit).toHaveBeenCalledWith(types.default.SET_GROUP_MEMBERS, {
          contactId: 42,
          members: sampleMembers,
        });
      });
    });

    describe('fetch', () => {
      it('commits SET_GROUP_MEMBERS on success', async () => {
        const meta = { total_count: 2, page: 1, per_page: 15 };
        GroupMembersAPI.getGroupMembers.mockResolvedValue({
          data: { payload: sampleMembers, meta },
        });
        await actions.fetch({ commit }, { contactId: 42 });
        expect(commit.mock.calls).toEqual([
          [types.default.SET_GROUP_MEMBERS_UI_FLAG, { isFetching: true }],
          [
            types.default.SET_GROUP_MEMBERS,
            { contactId: 42, members: sampleMembers },
          ],
          [types.default.SET_GROUP_MEMBERS_META, { contactId: 42, meta }],
          [types.default.SET_GROUP_MEMBERS_UI_FLAG, { isFetching: false }],
        ]);
      });

      it('throws on API error', async () => {
        GroupMembersAPI.getGroupMembers.mockRejectedValue(new Error('fail'));
        await expect(
          actions.fetch({ commit }, { contactId: 42 })
        ).rejects.toThrow(Error);
      });
    });

    describe('sync', () => {
      it('calls syncGroup without re-fetching (fire-and-forget)', async () => {
        GroupMembersAPI.syncGroup.mockResolvedValue({});
        await actions.sync({ commit }, { contactId: 42 });
        expect(GroupMembersAPI.syncGroup).toHaveBeenCalledWith(42);
        expect(dispatch).not.toHaveBeenCalled();
      });
    });

    describe('addMembers', () => {
      it('calls addMembers and re-fetches on success', async () => {
        GroupMembersAPI.addMembers.mockResolvedValue({});
        dispatch.mockResolvedValue();
        await actions.addMembers(
          { commit, dispatch },
          { contactId: 42, participants: ['+5511999'] }
        );
        expect(dispatch).toHaveBeenCalledWith('fetch', { contactId: 42 });
      });
    });

    describe('removeMembers', () => {
      it('calls removeMembers and re-fetches on success', async () => {
        GroupMembersAPI.removeMembers.mockResolvedValue({});
        dispatch.mockResolvedValue();
        await actions.removeMembers(
          { commit, dispatch },
          { contactId: 42, memberId: 1 }
        );
        expect(dispatch).toHaveBeenCalledWith('fetch', { contactId: 42 });
      });
    });

    describe('updateMemberRole', () => {
      it('calls updateMemberRole and re-fetches on success', async () => {
        GroupMembersAPI.updateMemberRole.mockResolvedValue({});
        dispatch.mockResolvedValue();
        await actions.updateMemberRole(
          { commit, dispatch },
          { contactId: 42, memberId: 1, role: 'admin' }
        );
        expect(dispatch).toHaveBeenCalledWith('fetch', { contactId: 42 });
      });
    });
  });
});
