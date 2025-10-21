import articlesAPI from '../helpCenter/articles';
import ApiClient from 'dashboard/api/helpCenter/portals';

describe('#PortalAPI', () => {
  it('creates correct instance', () => {
    expect(articlesAPI).toBeInstanceOf(ApiClient);
    expect(articlesAPI).toHaveProperty('get');
    expect(articlesAPI).toHaveProperty('show');
    expect(articlesAPI).toHaveProperty('create');
    expect(articlesAPI).toHaveProperty('update');
    expect(articlesAPI).toHaveProperty('delete');
    expect(articlesAPI).toHaveProperty('getArticles');
  });
  describe('API calls', () => {
    const originalAxios = window.axios;
    const axiosMock = {
      post: vi.fn(() => Promise.resolve()),
      get: vi.fn(() => Promise.resolve()),
      patch: vi.fn(() => Promise.resolve()),
      delete: vi.fn(() => Promise.resolve()),
    };

    beforeEach(() => {
      window.axios = axiosMock;
    });

    afterEach(() => {
      window.axios = originalAxios;
    });

    it('#getArticles', () => {
      articlesAPI.getArticles({
        pageNumber: 1,
        portalSlug: 'room-rental',
        locale: 'en-US',
        status: 'published',
        authorId: '1',
      });
      expect(axiosMock.get).toHaveBeenCalledWith(
        '/api/v1/portals/room-rental/articles?page=1&locale=en-US&status=published&author_id=1'
      );
    });
  });
  describe('API calls', () => {
    const originalAxios = window.axios;
    const axiosMock = {
      post: vi.fn(() => Promise.resolve()),
      get: vi.fn(() => Promise.resolve()),
      patch: vi.fn(() => Promise.resolve()),
      delete: vi.fn(() => Promise.resolve()),
    };

    beforeEach(() => {
      window.axios = axiosMock;
    });

    afterEach(() => {
      window.axios = originalAxios;
    });

    it('#getArticle', () => {
      articlesAPI.getArticle({
        id: 1,
        portalSlug: 'room-rental',
      });
      expect(axiosMock.get).toHaveBeenCalledWith(
        '/api/v1/portals/room-rental/articles/1'
      );
    });
  });
  describe('API calls', () => {
    const originalAxios = window.axios;
    const axiosMock = {
      post: vi.fn(() => Promise.resolve()),
      get: vi.fn(() => Promise.resolve()),
      patch: vi.fn(() => Promise.resolve()),
      delete: vi.fn(() => Promise.resolve()),
    };

    beforeEach(() => {
      window.axios = axiosMock;
    });

    afterEach(() => {
      window.axios = originalAxios;
    });

    it('#searchArticles', () => {
      articlesAPI.searchArticles({
        query: 'test',
        portalSlug: 'room-rental',
      });
      expect(axiosMock.get).toHaveBeenCalledWith(
        '/api/v1/portals/room-rental/articles?query=test'
      );
    });
  });
  describe('API calls', () => {
    const originalAxios = window.axios;
    const axiosMock = {
      post: vi.fn(() => Promise.resolve()),
      get: vi.fn(() => Promise.resolve()),
      patch: vi.fn(() => Promise.resolve()),
      delete: vi.fn(() => Promise.resolve()),
    };

    beforeEach(() => {
      window.axios = axiosMock;
    });

    afterEach(() => {
      window.axios = originalAxios;
    });

    it('#updateArticle', () => {
      articlesAPI.updateArticle({
        articleId: 1,
        portalSlug: 'room-rental',
        articleObj: { title: 'Update shipping address' },
      });
      expect(axiosMock.patch).toHaveBeenCalledWith(
        '/api/v1/portals/room-rental/articles/1',
        {
          title: 'Update shipping address',
        }
      );
    });
  });
  describe('API calls', () => {
    const originalAxios = window.axios;
    const axiosMock = {
      post: vi.fn(() => Promise.resolve()),
      get: vi.fn(() => Promise.resolve()),
      patch: vi.fn(() => Promise.resolve()),
      delete: vi.fn(() => Promise.resolve()),
    };

    beforeEach(() => {
      window.axios = axiosMock;
    });

    afterEach(() => {
      window.axios = originalAxios;
    });

    it('#deleteArticle', () => {
      articlesAPI.deleteArticle({
        articleId: 1,
        portalSlug: 'room-rental',
      });
      expect(axiosMock.delete).toHaveBeenCalledWith(
        '/api/v1/portals/room-rental/articles/1'
      );
    });
  });
});
