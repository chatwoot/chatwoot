import searchAPI from '../search';
import ApiClient from '../ApiClient';

describe('#SearchAPI', () => {
  it('creates correct instance', () => {
    expect(searchAPI).toBeInstanceOf(ApiClient);
    expect(searchAPI).toHaveProperty('get');
    expect(searchAPI).toHaveProperty('contacts');
    expect(searchAPI).toHaveProperty('conversations');
    expect(searchAPI).toHaveProperty('messages');
    expect(searchAPI).toHaveProperty('articles');
  });

  describe('API calls', () => {
    const originalAxios = window.axios;
    const axiosMock = {
      get: vi.fn(() => Promise.resolve()),
    };

    beforeEach(() => {
      window.axios = axiosMock;
    });

    afterEach(() => {
      window.axios = originalAxios;
      vi.clearAllMocks();
    });

    it('#get', () => {
      searchAPI.get({ q: 'test query' });
      expect(axiosMock.get).toHaveBeenCalledWith('/api/v1/search', {
        params: { q: 'test query' },
      });
    });

    it('#contacts', () => {
      searchAPI.contacts({ q: 'test', page: 1 });
      expect(axiosMock.get).toHaveBeenCalledWith('/api/v1/search/contacts', {
        params: { q: 'test', page: 1, since: undefined, until: undefined },
      });
    });

    it('#contacts with date filters', () => {
      searchAPI.contacts({
        q: 'test',
        page: 2,
        since: 1700000000,
        until: 1732000000,
      });
      expect(axiosMock.get).toHaveBeenCalledWith('/api/v1/search/contacts', {
        params: { q: 'test', page: 2, since: 1700000000, until: 1732000000 },
      });
    });

    it('#conversations', () => {
      searchAPI.conversations({ q: 'test', page: 1 });
      expect(axiosMock.get).toHaveBeenCalledWith(
        '/api/v1/search/conversations',
        {
          params: { q: 'test', page: 1, since: undefined, until: undefined },
        }
      );
    });

    it('#conversations with date filters', () => {
      searchAPI.conversations({
        q: 'test',
        page: 1,
        since: 1700000000,
        until: 1732000000,
      });
      expect(axiosMock.get).toHaveBeenCalledWith(
        '/api/v1/search/conversations',
        {
          params: { q: 'test', page: 1, since: 1700000000, until: 1732000000 },
        }
      );
    });

    it('#messages', () => {
      searchAPI.messages({ q: 'test', page: 1 });
      expect(axiosMock.get).toHaveBeenCalledWith('/api/v1/search/messages', {
        params: {
          q: 'test',
          page: 1,
          since: undefined,
          until: undefined,
          from: undefined,
          inbox_id: undefined,
        },
      });
    });

    it('#messages with all filters', () => {
      searchAPI.messages({
        q: 'test',
        page: 1,
        since: 1700000000,
        until: 1732000000,
        from: 'contact:42',
        inboxId: 10,
      });
      expect(axiosMock.get).toHaveBeenCalledWith('/api/v1/search/messages', {
        params: {
          q: 'test',
          page: 1,
          since: 1700000000,
          until: 1732000000,
          from: 'contact:42',
          inbox_id: 10,
        },
      });
    });

    it('#articles', () => {
      searchAPI.articles({ q: 'test', page: 1 });
      expect(axiosMock.get).toHaveBeenCalledWith('/api/v1/search/articles', {
        params: { q: 'test', page: 1, since: undefined, until: undefined },
      });
    });

    it('#articles with date filters', () => {
      searchAPI.articles({
        q: 'test',
        page: 2,
        since: 1700000000,
        until: 1732000000,
      });
      expect(axiosMock.get).toHaveBeenCalledWith('/api/v1/search/articles', {
        params: { q: 'test', page: 2, since: 1700000000, until: 1732000000 },
      });
    });
  });
});
