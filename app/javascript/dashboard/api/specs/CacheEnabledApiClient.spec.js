import axios from 'axios';
import CacheEnabledApiClient from '../CacheEnabledApiClient';

global.axios = axios;
vi.mock('axios');

class TestCacheClient extends CacheEnabledApiClient {
  constructor(cacheModelName) {
    super('test');
    this.modelName = cacheModelName;
    this.dataManager = {
      initDb: vi.fn().mockResolvedValue(),
      get: vi.fn().mockResolvedValue([]),
    };
    this.validateCacheKey = vi.fn().mockResolvedValue(true);
    this.refetchAndCommit = vi
      .fn()
      .mockResolvedValue({ data: { payload: [] } });
  }

  // eslint-disable-next-line class-methods-use-this
  get accountIdFromRoute() {
    return 'cache-dedupe-test';
  }

  get cacheModelName() {
    return this.modelName;
  }
}

describe('CacheEnabledApiClient', () => {
  it('shares simultaneous cache-key requests for the same account', async () => {
    axios.get.mockResolvedValue({
      data: { cache_keys: { labels: 1, teams: 2 } },
    });
    const labelsClient = new TestCacheClient('labels');
    const teamsClient = new TestCacheClient('teams');

    await Promise.all([
      labelsClient.getFromCache(),
      teamsClient.getFromCache(),
    ]);

    expect(axios.get).toHaveBeenCalledTimes(1);
    expect(axios.get).toHaveBeenCalledWith(
      '/api/v1/accounts/cache-dedupe-test/cache_keys'
    );
    expect(labelsClient.validateCacheKey).toHaveBeenCalledWith(1);
    expect(teamsClient.validateCacheKey).toHaveBeenCalledWith(2);
  });
});
