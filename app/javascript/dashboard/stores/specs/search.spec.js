import { setActivePinia, createPinia } from 'pinia';
import SearchAPI from 'dashboard/api/search';
import { useSearchStore } from '../search';

vi.mock('dashboard/api/search', () => ({
  default: {
    counts: vi.fn(),
    contacts: vi.fn(),
    conversations: vi.fn(),
    messages: vi.fn(),
    articles: vi.fn(),
  },
}));

const page = (count, offset = 0) =>
  Array.from({ length: count }, (_, i) => ({ id: offset + i + 1 }));

describe('search store', () => {
  beforeEach(() => {
    setActivePinia(createPinia());
    vi.clearAllMocks();
  });

  it('starts with empty results for every entity', () => {
    const store = useSearchStore();
    expect(Object.keys(store.results)).toEqual([
      'contacts',
      'conversations',
      'messages',
      'articles',
    ]);
    expect(store.results.messages).toEqual({
      records: [],
      page: 0,
      hasMore: false,
      isFetching: false,
      hasError: false,
    });
  });

  describe('fetchCounts', () => {
    it('stores the counts from the API', async () => {
      SearchAPI.counts.mockResolvedValue({
        data: {
          payload: { counts: { contacts: 2, messages: 37 } },
          meta: { message_backend: 'gin' },
        },
      });
      const store = useSearchStore();

      const request = store.fetchCounts({ q: 'hi', types: ['contacts'] });
      expect(store.isFetchingCounts).toBe(true);
      await request;

      expect(SearchAPI.counts).toHaveBeenCalledWith(
        { q: 'hi', types: ['contacts'] },
        { signal: undefined }
      );
      expect(store.counts).toEqual({ contacts: 2, messages: 37 });
      expect(store.countBackend).toBe('gin');
      expect(store.isFetchingCounts).toBe(false);
      expect(store.countFor('messages')).toBe(37);
      expect(store.countFor('articles')).toBeNull();
    });

    it('flags an error and keeps the previous counts when the request fails', async () => {
      SearchAPI.counts.mockRejectedValue(new Error('boom'));
      const store = useSearchStore();

      await store.fetchCounts({ q: 'hi', types: ['contacts'] });

      expect(store.counts).toEqual({});
      expect(store.hasCountError).toBe(true);
      expect(store.isFetchingCounts).toBe(false);
    });

    it('hides the message count when counts and results used different backends', async () => {
      SearchAPI.counts.mockResolvedValue({
        data: {
          payload: { counts: { messages: 37 } },
          meta: { message_backend: 'opensearch' },
        },
      });
      SearchAPI.messages.mockResolvedValue({
        data: {
          payload: { messages: page(2) },
          meta: { message_backend: 'gin' },
        },
      });
      const store = useSearchStore();

      await store.fetchCounts({ q: 'hi', types: ['messages'] });
      await store.fetchResults('messages', { q: 'hi' });

      expect(store.isMessageCountStale).toBe(true);
      expect(store.countFor('messages')).toBeNull();
    });

    it('leaves the flags to the request that replaced an aborted one', async () => {
      const controller = new AbortController();
      SearchAPI.counts.mockImplementation(
        (params, { signal }) =>
          new Promise((resolve, reject) => {
            signal.addEventListener('abort', () =>
              reject(new Error('canceled'))
            );
          })
      );
      const store = useSearchStore();

      const request = store.fetchCounts(
        { q: 'hi' },
        { signal: controller.signal }
      );
      controller.abort();
      await request;

      expect(store.isFetchingCounts).toBe(true);
      expect(store.hasCountError).toBe(false);
    });
  });

  describe('fetchResults', () => {
    it('stores the first page and flags more pages when it is full', async () => {
      SearchAPI.messages.mockResolvedValue({
        data: {
          payload: { messages: page(15) },
          meta: { message_backend: 'gin' },
        },
      });
      const store = useSearchStore();

      const request = store.fetchResults('messages', { q: 'hi', from: 3 });
      expect(store.results.messages.isFetching).toBe(true);
      await request;

      expect(SearchAPI.messages).toHaveBeenCalledWith(
        { q: 'hi', from: 3, page: 1, perPage: 15 },
        { signal: undefined }
      );
      expect(store.results.messages).toEqual({
        records: page(15),
        page: 1,
        hasMore: true,
        isFetching: false,
        hasError: false,
      });
      expect(store.messageBackend).toBe('gin');
    });

    it('appends later pages without duplicating overlapping records', async () => {
      SearchAPI.contacts
        .mockResolvedValueOnce({ data: { payload: { contacts: page(15) } } })
        .mockResolvedValueOnce({
          data: { payload: { contacts: page(3, 14) } },
        });
      const store = useSearchStore();

      await store.fetchResults('contacts', { q: 'hi' });
      await store.fetchResults('contacts', { q: 'hi', page: 2 });

      expect(store.results.contacts.records).toEqual(page(17));
      expect(store.results.contacts.page).toBe(2);
      expect(store.results.contacts.hasMore).toBe(false);
    });

    it('flags an error and leaves the loaded page untouched when the request fails', async () => {
      SearchAPI.articles
        .mockResolvedValueOnce({ data: { payload: { articles: page(15) } } })
        .mockRejectedValueOnce(new Error('boom'));
      const store = useSearchStore();

      await store.fetchResults('articles', { q: 'hi' });
      await store.fetchResults('articles', { q: 'hi', page: 2 });

      expect(store.results.articles).toEqual({
        records: page(15),
        page: 1,
        hasMore: true,
        isFetching: false,
        hasError: true,
      });
    });

    it('stores a preview separately from the pages', async () => {
      SearchAPI.contacts.mockResolvedValue({
        data: { payload: { contacts: page(5) } },
      });
      const store = useSearchStore();

      await store.fetchResults('contacts', { q: 'hi' }, { preview: true });

      expect(SearchAPI.contacts).toHaveBeenCalledWith(
        { q: 'hi', page: 1, perPage: 5 },
        { signal: undefined }
      );
      expect(store.previews.contacts).toEqual({
        records: page(5),
        page: 1,
        hasMore: true,
        isFetching: false,
        hasError: false,
      });
      expect(store.results.contacts.page).toBe(0);
    });

    it('does not touch the results of other entities', async () => {
      SearchAPI.conversations.mockResolvedValue({
        data: { payload: { conversations: page(2) } },
      });
      const store = useSearchStore();

      await store.fetchResults('conversations', { q: 'hi' });

      expect(store.results.conversations.records).toEqual(page(2));
      expect(store.results.messages.page).toBe(0);
    });
  });

  it('$reset clears counts and every entity', async () => {
    SearchAPI.counts.mockResolvedValue({
      data: { payload: { counts: { contacts: 2 } }, meta: {} },
    });
    SearchAPI.contacts.mockResolvedValue({
      data: { payload: { contacts: page(2) } },
    });
    const store = useSearchStore();
    await store.fetchCounts({ q: 'hi', types: ['contacts'] });
    await store.fetchResults('contacts', { q: 'hi' });

    store.$reset();

    expect(store.counts).toEqual({});
    expect(store.results.contacts).toEqual({
      records: [],
      page: 0,
      hasMore: false,
      isFetching: false,
      hasError: false,
    });
  });
});
