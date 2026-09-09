import ChannelGroupsAPI from 'dashboard/api/channelGroups';
import { actions, getters, mutations } from '../../channelGroups';

vi.mock('dashboard/api/channelGroups');

const groups = [{ id: 1, name: 'Northstar', inbox_ids: [3, 4] }];

describe('#getters', () => {
  it('returns the groups of the account they were fetched for', () => {
    const state = { records: groups, accountId: 1 };

    expect(getters.getGroups(state, {}, {}, { getCurrentAccountId: 1 })).toEqual(
      groups
    );
  });

  it('returns nothing after switching to another account', () => {
    const state = { records: groups, accountId: 1 };

    expect(
      getters.getGroups(state, {}, {}, { getCurrentAccountId: 2 })
    ).toEqual([]);
  });
});

describe('#mutations', () => {
  it('stores the groups with the account they belong to', () => {
    const state = { records: [], accountId: null };

    mutations.setGroups(state, { records: groups, accountId: 1 });

    expect(state).toEqual({ records: groups, accountId: 1 });
  });
});

describe('#actions', () => {
  const commit = vi.fn();

  beforeEach(() => {
    commit.mockClear();
  });

  it('stores the fetched groups', async () => {
    ChannelGroupsAPI.get.mockResolvedValue({ data: groups });

    await actions.get({ commit, rootGetters: { getCurrentAccountId: 1 } });

    expect(commit).toHaveBeenCalledWith('setGroups', {
      records: groups,
      accountId: 1,
    });
  });

  it('discards a response that arrives after an account switch', async () => {
    const rootGetters = { getCurrentAccountId: 1 };
    ChannelGroupsAPI.get.mockImplementation(() => {
      rootGetters.getCurrentAccountId = 2;
      return Promise.resolve({ data: groups });
    });

    await actions.get({ commit, rootGetters });

    expect(commit).not.toHaveBeenCalled();
  });

  it('refreshes the list after a group changes', async () => {
    const dispatch = vi.fn();
    ChannelGroupsAPI.create.mockResolvedValue({});

    await actions.create({ dispatch }, { name: 'Harbor', inbox_ids: [] });

    expect(ChannelGroupsAPI.create).toHaveBeenCalledWith({
      channel_group: { name: 'Harbor', inbox_ids: [] },
    });
    expect(dispatch).toHaveBeenCalledWith('get');
  });
});
