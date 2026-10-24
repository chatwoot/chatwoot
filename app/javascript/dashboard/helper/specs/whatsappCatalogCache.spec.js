import inboxes from '../../api/inboxes';
import {
  CATALOG_CACHE_TTL,
  clearCatalogCache,
  loadCatalog,
  loadProductsPage,
  peekCatalog,
  peekProductsPage,
  prefetchCatalog,
} from '../whatsappCatalogCache';

vi.mock('../../api/inboxes', () => ({
  default: { getWhatsappCatalog: vi.fn(), getWhatsappCatalogProducts: vi.fn() },
}));

const okData = { status: 'ok', catalog_id: '1', collections: [], products: [] };

const page = {
  status: 'ok',
  products: [{ retailer_id: 'a' }],
  next_cursor: 'c',
};

describe('whatsappCatalogCache', () => {
  beforeEach(() => {
    vi.useFakeTimers();
    clearCatalogCache();
    inboxes.getWhatsappCatalog.mockReset();
    inboxes.getWhatsappCatalog.mockResolvedValue({ data: okData });
    inboxes.getWhatsappCatalogProducts.mockReset();
    inboxes.getWhatsappCatalogProducts.mockResolvedValue({ data: page });
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('shares one request between simultaneous calls', async () => {
    const [a, b] = await Promise.all([loadCatalog(1), loadCatalog(1)]);
    expect(a).toEqual(okData);
    expect(b).toEqual(okData);
    expect(inboxes.getWhatsappCatalog).toHaveBeenCalledTimes(1);
  });

  it('serves from memory until it expires', async () => {
    await loadCatalog(1);
    await loadCatalog(1);
    expect(inboxes.getWhatsappCatalog).toHaveBeenCalledTimes(1);
    vi.advanceTimersByTime(CATALOG_CACHE_TTL + 1);
    await loadCatalog(1);
    expect(inboxes.getWhatsappCatalog).toHaveBeenCalledTimes(2);
  });

  it('caches per inbox', async () => {
    await loadCatalog(1);
    await loadCatalog(2);
    expect(inboxes.getWhatsappCatalog).toHaveBeenCalledTimes(2);
  });

  it('force skips the cache and asks for refresh', async () => {
    await loadCatalog(1);
    await loadCatalog(1, { force: true });
    expect(inboxes.getWhatsappCatalog).toHaveBeenLastCalledWith(1, {
      refresh: true,
    });
  });

  it('does not cache non-ok statuses', async () => {
    inboxes.getWhatsappCatalog.mockResolvedValue({
      data: { status: 'error' },
    });
    await loadCatalog(1);
    await loadCatalog(1);
    expect(inboxes.getWhatsappCatalog).toHaveBeenCalledTimes(2);
  });

  it('does not cache request failures and propagates them', async () => {
    inboxes.getWhatsappCatalog.mockRejectedValueOnce(new Error('boom'));
    await expect(loadCatalog(1)).rejects.toThrow('boom');
    await expect(loadCatalog(1)).resolves.toEqual(okData);
    expect(inboxes.getWhatsappCatalog).toHaveBeenCalledTimes(2);
  });

  it('prefetch swallows errors', async () => {
    inboxes.getWhatsappCatalog.mockRejectedValueOnce(new Error('boom'));
    await expect(prefetchCatalog(1)).resolves.toBeUndefined();
  });

  it('prefetch swallows products errors too', async () => {
    inboxes.getWhatsappCatalogProducts.mockRejectedValueOnce(new Error('boom'));
    await expect(prefetchCatalog(1)).resolves.toBeUndefined();
  });

  describe('loadProductsPage', () => {
    it('caches the first page per inbox and collection', async () => {
      await expect(loadProductsPage(1)).resolves.toEqual(page);
      await loadProductsPage(1);
      expect(inboxes.getWhatsappCatalogProducts).toHaveBeenCalledTimes(1);
      await loadProductsPage(1, { collectionId: 'c1' });
      await loadProductsPage(2);
      expect(inboxes.getWhatsappCatalogProducts).toHaveBeenCalledTimes(3);
    });

    it('does not cache pages with after or q', async () => {
      await loadProductsPage(1, { after: 'c' });
      await loadProductsPage(1, { after: 'c' });
      await loadProductsPage(1, { q: 'taza' });
      await loadProductsPage(1, { q: 'taza' });
      expect(inboxes.getWhatsappCatalogProducts).toHaveBeenCalledTimes(4);
    });

    it('shares one request between simultaneous first-page calls', async () => {
      await Promise.all([loadProductsPage(1), loadProductsPage(1)]);
      expect(inboxes.getWhatsappCatalogProducts).toHaveBeenCalledTimes(1);
    });

    it('expires after the TTL', async () => {
      await loadProductsPage(1);
      vi.advanceTimersByTime(CATALOG_CACHE_TTL + 1);
      await loadProductsPage(1);
      expect(inboxes.getWhatsappCatalogProducts).toHaveBeenCalledTimes(2);
    });

    it('force refreshes, and errors are not cached', async () => {
      await loadProductsPage(1);
      await loadProductsPage(1, { force: true });
      expect(inboxes.getWhatsappCatalogProducts).toHaveBeenLastCalledWith(1, {
        after: undefined,
        q: undefined,
        collectionId: undefined,
        refresh: true,
      });
      clearCatalogCache();
      inboxes.getWhatsappCatalogProducts.mockRejectedValueOnce(new Error('x'));
      await expect(loadProductsPage(1)).rejects.toThrow('x');
      await expect(loadProductsPage(1)).resolves.toEqual(page);
    });
  });

  describe('peek', () => {
    it('returns null before loading and fresh data after', async () => {
      expect(peekCatalog(1)).toBeNull();
      expect(peekProductsPage(1)).toBeNull();
      await loadCatalog(1);
      await loadProductsPage(1);
      await loadProductsPage(1, { collectionId: 'c1' });
      expect(peekCatalog(1)).toEqual({ data: okData, isStale: false });
      expect(peekProductsPage(1)).toEqual({ data: page, isStale: false });
      expect(peekProductsPage(1, { collectionId: 'c1' })).toEqual({
        data: page,
        isStale: false,
      });
      expect(peekProductsPage(1, { collectionId: 'c2' })).toBeNull();
      expect(peekCatalog(2)).toBeNull();
    });

    it('keeps returning the data, flagged stale, after the TTL', async () => {
      await loadCatalog(1);
      await loadProductsPage(1);
      vi.advanceTimersByTime(CATALOG_CACHE_TTL + 1);
      expect(peekCatalog(1)).toEqual({ data: okData, isStale: true });
      expect(peekProductsPage(1)).toEqual({ data: page, isStale: true });
    });

    it('never calls the API', async () => {
      peekCatalog(1);
      peekProductsPage(1);
      await loadCatalog(1);
      await loadProductsPage(1);
      inboxes.getWhatsappCatalog.mockClear();
      inboxes.getWhatsappCatalogProducts.mockClear();
      vi.advanceTimersByTime(CATALOG_CACHE_TTL + 1);
      peekCatalog(1);
      peekProductsPage(1);
      expect(inboxes.getWhatsappCatalog).not.toHaveBeenCalled();
      expect(inboxes.getWhatsappCatalogProducts).not.toHaveBeenCalled();
    });
  });
});
