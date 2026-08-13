// The subclasses below are test doubles standing in for the two response shapes the
// cached clients have to support
/* eslint-disable max-classes-per-file */
import axios from 'axios';
import { deleteDB } from 'idb';
import CacheEnabledApiClient from '../CacheEnabledApiClient';

global.axios = axios;
vi.mock('axios');

const ACCOUNT_ID = '7';

// Most cached resources answer with a `payload` wrapper
class WrappedClient extends CacheEnabledApiClient {
  constructor() {
    super('inboxes', { accountScoped: true });
  }

  // eslint-disable-next-line class-methods-use-this
  get cacheModelName() {
    return 'inbox';
  }
}

// Canned responses answer with a bare array, so they override both hooks. The cached read
// has to hand back the same shape as the network read or callers break on a cache hit.
class BareArrayClient extends CacheEnabledApiClient {
  constructor() {
    super('canned_responses', { accountScoped: true });
  }

  // eslint-disable-next-line class-methods-use-this
  get cacheModelName() {
    return 'canned_response';
  }

  // eslint-disable-next-line class-methods-use-this
  extractDataFromResponse(response) {
    return response.data;
  }

  // eslint-disable-next-line class-methods-use-this
  marshallData(dataToParse) {
    return { data: dataToParse };
  }
}

describe('CacheEnabledApiClient', () => {
  const inboxes = [
    { id: 1, name: 'inbox-1' },
    { id: 2, name: 'inbox-2' },
  ];
  const cannedResponses = [{ id: 1, short_code: 'hello', content: 'Hi there' }];

  let openClients = [];

  const stubEndpoints = ({ cacheKeys, payload }) => {
    axios.get.mockImplementation(url =>
      url.includes('cache_keys')
        ? Promise.resolve({ data: { cache_keys: cacheKeys } })
        : Promise.resolve({ data: payload })
    );
  };

  const listRequests = () =>
    axios.get.mock.calls.filter(([url]) => !url.includes('cache_keys'));

  const buildClient = Klass => {
    const client = new Klass();
    openClients.push(client);
    return client;
  };

  beforeEach(async () => {
    window.history.pushState({}, '', `/app/accounts/${ACCOUNT_ID}/dashboard`);
    await deleteDB(`cw-store-${ACCOUNT_ID}`);
    openClients = [];
  });

  afterEach(() => {
    openClients.forEach(client => client.dataManager.db?.close());
  });

  it('throws when a subclass does not declare a cache model', () => {
    class Incomplete extends CacheEnabledApiClient {}

    expect(() => buildClient(Incomplete).cacheModelName).toThrow();
  });

  it('does not serve one account its data to another account', async () => {
    // The bundle boots at /app and the router redirects into an account without
    // re-evaluating it, so the singleton client outlives the account in the route
    window.history.pushState({}, '', '/app');
    const client = buildClient(BareArrayClient);
    await deleteDB('cw-store-');
    await deleteDB('cw-store-9');

    // A never-written cache key is the same '0000000000' for every account
    const sharedKey = '0000000000';
    stubEndpoints({
      cacheKeys: { canned_response: sharedKey },
      payload: cannedResponses,
    });
    window.history.pushState({}, '', `/app/accounts/${ACCOUNT_ID}/dashboard`);
    await client.get(true);
    client.dataManager.db?.close();

    const otherAccountResponses = [
      { id: 99, short_code: 'other-account', content: 'Should stay private' },
    ];
    window.history.pushState({}, '', '/app/accounts/9/dashboard');
    axios.get.mockClear();
    stubEndpoints({
      cacheKeys: { canned_response: sharedKey },
      payload: otherAccountResponses,
    });
    const response = await client.get(true);

    expect(response.data).toEqual(otherAccountResponses);
    expect(listRequests()).toHaveLength(1);
  });

  it('skips the cache entirely when asked for a network read', async () => {
    stubEndpoints({
      cacheKeys: { inbox: 'key-1' },
      payload: { payload: inboxes },
    });
    const client = buildClient(WrappedClient);

    const response = await client.get(false);

    expect(response.data.payload).toEqual(inboxes);
    // No cache key lookup either, so the request count is exactly one
    expect(axios.get).toHaveBeenCalledTimes(1);
  });

  it('fetches from the network and stores locally when the cache is cold', async () => {
    stubEndpoints({
      cacheKeys: { inbox: 'key-1' },
      payload: { payload: inboxes },
    });
    const client = buildClient(WrappedClient);

    const response = await client.get(true);

    expect(response.data.payload).toEqual(inboxes);
    expect(listRequests()).toHaveLength(1);
    expect(await client.dataManager.get({ modelName: 'inbox' })).toEqual(
      inboxes
    );
    expect(await client.dataManager.getCacheKey('inbox')).toBe('key-1');
  });

  it('serves local data without a list request while the cache key is unchanged', async () => {
    stubEndpoints({
      cacheKeys: { inbox: 'key-1' },
      payload: { payload: inboxes },
    });
    const client = buildClient(WrappedClient);
    await client.get(true);

    axios.get.mockClear();
    const response = await client.get(true);

    expect(response.data.payload).toEqual(inboxes);
    expect(listRequests()).toHaveLength(0);
  });

  it('refetches and overwrites local data once the cache key moves', async () => {
    stubEndpoints({
      cacheKeys: { inbox: 'key-1' },
      payload: { payload: inboxes },
    });
    const client = buildClient(WrappedClient);
    await client.get(true);

    const renamed = [{ id: 1, name: 'inbox-1-renamed' }];
    axios.get.mockClear();
    stubEndpoints({
      cacheKeys: { inbox: 'key-2' },
      payload: { payload: renamed },
    });
    const response = await client.get(true);

    expect(response.data.payload).toEqual(renamed);
    expect(listRequests()).toHaveLength(1);
    expect(await client.dataManager.get({ modelName: 'inbox' })).toEqual(
      renamed
    );
    expect(await client.dataManager.getCacheKey('inbox')).toBe('key-2');
  });

  it('returns the same shape from the cache as from the network for a bare array resource', async () => {
    stubEndpoints({
      cacheKeys: { canned_response: 'key-1' },
      payload: cannedResponses,
    });
    const client = buildClient(BareArrayClient);

    const fromNetwork = await client.get(true);
    axios.get.mockClear();
    const fromCache = await client.get(true);

    expect(fromNetwork.data).toEqual(cannedResponses);
    expect(fromCache.data).toEqual(cannedResponses);
    expect(listRequests()).toHaveLength(0);
  });

  it('falls back to the network when IndexedDB is unavailable', async () => {
    stubEndpoints({
      cacheKeys: { inbox: 'key-1' },
      payload: { payload: inboxes },
    });
    const client = buildClient(WrappedClient);
    vi.spyOn(client.dataManager, 'initDb').mockRejectedValue(
      new Error('IndexedDB is disabled in private mode')
    );

    const response = await client.get(true);

    expect(response.data.payload).toEqual(inboxes);
  });
});
