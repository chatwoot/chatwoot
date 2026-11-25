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

    // The roster is the group's and is shared, but `is_inbox_admin`, `own_member_id` and
    // the phone number answer "who are we in this group", which is per inbox. Keyed by
    // contact alone, the panel for one number showed the other one's answer.
    it('getGroupMembersMeta answers per inbox', () => {
      const localState = {
        meta: {
          '42:7': { is_inbox_admin: true },
          '42:9': { is_inbox_admin: false },
        },
      };
      expect(getters.getGroupMembersMeta(localState)(42, 7)).toEqual({
        is_inbox_admin: true,
      });
      expect(getters.getGroupMembersMeta(localState)(42, 9)).toEqual({
        is_inbox_admin: false,
      });
      expect(getters.getGroupMembersMeta(localState)(42, 11)).toEqual({});
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

    it('SET_GROUP_MEMBERS_META keeps one inbox from overwriting another', () => {
      const localState = { meta: {} };
      mutations[types.default.SET_GROUP_MEMBERS_META](localState, {
        contactId: 42,
        inboxId: 7,
        meta: { is_inbox_admin: true },
      });
      mutations[types.default.SET_GROUP_MEMBERS_META](localState, {
        contactId: 42,
        inboxId: 9,
        meta: { is_inbox_admin: false },
      });

      expect(localState.meta['42:7']).toEqual({ is_inbox_admin: true });
      expect(localState.meta['42:9']).toEqual({ is_inbox_admin: false });
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
        await actions.fetch({ commit }, { contactId: 42, inboxId: 7 });
        expect(GroupMembersAPI.getGroupMembers).toHaveBeenCalledWith(42, 7, 1);
        expect(commit.mock.calls).toEqual([
          [types.default.SET_GROUP_MEMBERS_UI_FLAG, { isFetching: true }],
          [
            types.default.SET_GROUP_MEMBERS,
            { contactId: 42, members: sampleMembers },
          ],
          [
            types.default.SET_GROUP_MEMBERS_META,
            { contactId: 42, inboxId: 7, meta },
          ],
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
        await actions.sync({ commit }, { contactId: 42, inboxId: 7 });
        expect(GroupMembersAPI.syncGroup).toHaveBeenCalledWith(42, 7);
        expect(dispatch).not.toHaveBeenCalled();
      });
    });

    describe('addMembers', () => {
      it('calls addMembers and re-fetches on success', async () => {
        GroupMembersAPI.addMembers.mockResolvedValue({});
        dispatch.mockResolvedValue();
        await actions.addMembers(
          { commit, dispatch },
          { contactId: 42, participants: ['+5511999'], inboxId: 7 }
        );
        expect(GroupMembersAPI.addMembers).toHaveBeenCalledWith(
          42,
          ['+5511999'],
          7
        );
        expect(dispatch).toHaveBeenCalledWith('fetch', {
          contactId: 42,
          inboxId: 7,
        });
      });
    });

    describe('removeMembers', () => {
      it('calls removeMembers and re-fetches on success', async () => {
        GroupMembersAPI.removeMembers.mockResolvedValue({});
        dispatch.mockResolvedValue();
        await actions.removeMembers(
          { commit, dispatch },
          { contactId: 42, memberId: 1, inboxId: 7 }
        );
        expect(GroupMembersAPI.removeMembers).toHaveBeenCalledWith(42, 1, 7);
        expect(dispatch).toHaveBeenCalledWith('fetch', {
          contactId: 42,
          inboxId: 7,
        });
      });
    });

    describe('updateMemberRole', () => {
      it('calls updateMemberRole and re-fetches on success', async () => {
        GroupMembersAPI.updateMemberRole.mockResolvedValue({});
        dispatch.mockResolvedValue();
        await actions.updateMemberRole(
          { commit, dispatch },
          { contactId: 42, memberId: 1, role: 'admin', inboxId: 7 }
        );
        expect(GroupMembersAPI.updateMemberRole).toHaveBeenCalledWith(
          42,
          1,
          'admin',
          7
        );
        expect(dispatch).toHaveBeenCalledWith('fetch', {
          contactId: 42,
          inboxId: 7,
        });
      });
    });
  });
});
