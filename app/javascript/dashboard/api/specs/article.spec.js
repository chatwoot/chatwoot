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
        '/api/v1/portals/room-rental/articles?page=1&locale=en-US&status=published&author_id=1',
        { signal: undefined }
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
        status: 'published',
      });
      expect(axiosMock.get).toHaveBeenCalledWith(
        '/api/v1/portals/room-rental/articles?status=published&query=test'
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

    it('#bulkUpdateCategory', () => {
      articlesAPI.bulkUpdateCategory({
        portalSlug: 'room-rental',
        articleIds: [1, 2, 3],
        categoryId: 7,
      });
      expect(axiosMock.patch).toHaveBeenCalledWith(
        '/api/v1/portals/room-rental/articles/bulk_actions/update_category',
        { ids: [1, 2, 3], category_id: 7 }
      );
    });

    it('#bulkUpdateStatus targets every article matching the list filters', () => {
      articlesAPI.bulkUpdateStatus({
        portalSlug: 'room-rental',
        filters: {
          locale: 'en',
          status: 0,
          authorId: '5',
          categorySlug: 'billing',
          query: 'refund',
        },
        status: 'published',
      });
      expect(axiosMock.patch).toHaveBeenCalledWith(
        '/api/v1/portals/room-rental/articles/bulk_actions/update_status',
        {
          select_all: true,
          filters: {
            locale: 'en',
            status: 0,
            author_id: '5',
            category_slug: 'billing',
            query: 'refund',
          },
          status: 'published',
        }
      );
    });
  });
});
