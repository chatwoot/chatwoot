import { describe, it, expect, vi, beforeEach } from 'vitest';
import InboxesAPI from '../inboxes';

describe('InboxesAPI cache key binding', () => {
  const dataManager = {
    initDb: vi.fn().mockResolvedValue(true),
    replace: vi.fn().mockResolvedValue(true),
    setCacheKeys: vi.fn().mockResolvedValue(true),
    db: true,
  };

  beforeEach(() => {
    vi.clearAllMocks();
    vi.spyOn(InboxesAPI, 'dataManager', 'get').mockReturnValue(dataManager);
  });

  // A rolling deploy can answer /cache_keys from the new build and this request from the
  // old one. Filing the old payload under the new key leaves it valid for good, which is
  // how an inbox keeps reporting capabilities it never received.
  it('files the rows under the key the response carried, not the one asked for', async () => {
    vi.spyOn(InboxesAPI, 'getFromNetwork').mockResolvedValue({
      data: { payload: [], cache_key: 'from-the-body' },
    });

    await InboxesAPI.refetchAndCommit('from-cache-keys');

    expect(dataManager.setCacheKeys).toHaveBeenCalledWith({
      inbox: 'from-the-body',
    });
  });

  // The empty case of the guard above, and the one that reopened the hole: borrowing the
  // key from /cache_keys is precisely what must not happen, because during a rolling
  // deploy that key belongs to the build that did not serve this body.
  it('caches nothing when the response carries no key of its own', async () => {
    vi.spyOn(InboxesAPI, 'getFromNetwork').mockResolvedValue({
      data: { payload: [{ id: 1 }] },
    });

    const response = await InboxesAPI.refetchAndCommit('from-cache-keys');

    expect(dataManager.setCacheKeys).not.toHaveBeenCalled();
    expect(dataManager.replace).not.toHaveBeenCalled();
    expect(response.data.payload).toEqual([{ id: 1 }]);
  });
});
