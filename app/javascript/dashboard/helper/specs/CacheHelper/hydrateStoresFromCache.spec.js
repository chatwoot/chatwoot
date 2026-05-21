import hydrateStoresFromCache from '../../CacheHelper/hydrateStoresFromCache';
import { DataManager } from '../../CacheHelper/DataManager';

describe('hydrateStoresFromCache', () => {
  const accountId = 'hydrate-test-account';
  const originalAxios = window.axios;
  let axiosMock;
  let dm;
  let storeMock;

  beforeEach(async () => {
    axiosMock = {
      get: vi.fn(),
    };
    window.axios = axiosMock;

    storeMock = {
      commit: vi.fn(),
      dispatch: vi.fn(),
    };

    dm = new DataManager(accountId);
    await dm.initDb();
  });

  afterEach(async () => {
    const tx = dm.db.transaction(
      [...dm.modelsToSync, 'cache-keys'],
      'readwrite'
    );
    [...dm.modelsToSync, 'cache-keys'].forEach(name => {
      tx.objectStore(name).clear();
    });
    await tx.done;
    window.axios = originalAxios;
  });

  it('does nothing when IDB is empty (first ever load)', async () => {
    axiosMock.get.mockResolvedValueOnce({
      data: { cache_keys: { inbox: 'k1', label: 'k2', team: 'k3' } },
    });

    await hydrateStoresFromCache(storeMock, accountId);

    expect(storeMock.commit).not.toHaveBeenCalled();
    expect(storeMock.dispatch).not.toHaveBeenCalled();
  });

  it('seeds Vuex from IDB then revalidates only stale models', async () => {
    await dm.push({
      modelName: 'inbox',
      data: [{ id: 1, name: 'Support' }],
    });
    await dm.push({
      modelName: 'label',
      data: [{ id: 9, title: 'Bug' }],
    });
    await dm.setCacheKeys({ inbox: 'inbox-old', label: 'label-current' });

    axiosMock.get.mockResolvedValueOnce({
      data: {
        cache_keys: {
          inbox: 'inbox-new', // changed → revalidate
          label: 'label-current', // matches → no dispatch
        },
      },
    });

    await hydrateStoresFromCache(storeMock, accountId);

    expect(storeMock.commit).toHaveBeenCalledWith('inboxes/SET_INBOXES', [
      { id: 1, name: 'Support' },
    ]);
    expect(storeMock.commit).toHaveBeenCalledWith('labels/SET_LABELS', [
      { id: 9, title: 'Bug' },
    ]);
    expect(storeMock.dispatch).toHaveBeenCalledWith('inboxes/revalidate', {
      newKey: 'inbox-new',
    });
    expect(storeMock.dispatch).not.toHaveBeenCalledWith(
      'labels/revalidate',
      expect.anything()
    );
  });

  it('commits CLEAR_TEAMS before SET_TEAMS to drop phantom rows', async () => {
    await dm.push({
      modelName: 'team',
      data: [{ id: 1, name: 'Sales' }],
    });

    axiosMock.get.mockResolvedValueOnce({ data: { cache_keys: {} } });

    await hydrateStoresFromCache(storeMock, accountId);

    const teamCommits = storeMock.commit.mock.calls.filter(call =>
      call[0].startsWith('teams/')
    );
    expect(teamCommits[0][0]).toBe('teams/CLEAR_TEAMS');
    expect(teamCommits[1][0]).toBe('teams/SET_TEAMS');
  });

  it('captures local keys BEFORE comparing to server keys (sequencing guard)', async () => {
    await dm.push({
      modelName: 'canned_response',
      data: [{ id: 1, short_code: 'hi', content: 'Hello' }],
    });
    await dm.setCacheKeys({ canned_response: 'canned-old' });

    let serverKeyResolved = false;
    axiosMock.get.mockImplementationOnce(async () => {
      // If the implementation persisted the server key before snapshotting the
      // local one, by the time this resolves the IDB would already say
      // 'canned-new' and the revalidate dispatch would be skipped. Asserting
      // the dispatch fires proves the original local key was captured first.
      serverKeyResolved = true;
      return { data: { cache_keys: { canned_response: 'canned-new' } } };
    });

    await hydrateStoresFromCache(storeMock, accountId);

    expect(serverKeyResolved).toBe(true);
    expect(storeMock.dispatch).toHaveBeenCalledWith(
      'revalidateCannedResponses',
      { newKey: 'canned-new' }
    );
  });

  it('still paints cached data when the cache_keys network call fails', async () => {
    await dm.push({
      modelName: 'inbox',
      data: [{ id: 7, name: 'Email' }],
    });
    axiosMock.get.mockRejectedValueOnce(new Error('offline'));

    await hydrateStoresFromCache(storeMock, accountId);

    expect(storeMock.commit).toHaveBeenCalledWith('inboxes/SET_INBOXES', [
      { id: 7, name: 'Email' },
    ]);
    expect(storeMock.dispatch).not.toHaveBeenCalled();
  });
});
