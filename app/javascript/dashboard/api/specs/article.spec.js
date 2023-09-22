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
  describe('API calls', context => {
    it('#getArticles', () => {
      articlesAPI.getArticles({
        pageNumber: 1,
        portalSlug: 'room-rental',
        locale: 'en-US',
        status: 'published',
        author_id: '1',
      });
      expect(axios.get).toHaveBeenCalledWith(
        '/api/v1/portals/room-rental/articles?page=1&locale=en-US&status=published&author_id=1'
      );
    });
  });
  describe('API calls', context => {
    it('#getArticle', () => {
      articlesAPI.getArticle({
        id: 1,
        portalSlug: 'room-rental',
      });
      expect(axios.get).toHaveBeenCalledWith(
        '/api/v1/portals/room-rental/articles/1'
      );
    });
  });
  describe('API calls', context => {
    it('#updateArticle', () => {
      articlesAPI.updateArticle({
        articleId: 1,
        portalSlug: 'room-rental',
        articleObj: { title: 'Update shipping address' },
      });
      expect(axios.patch).toHaveBeenCalledWith(
        '/api/v1/portals/room-rental/articles/1',
        {
          title: 'Update shipping address',
        }
      );
    });
  });
  describe('API calls', context => {
    it('#deleteArticle', () => {
      articlesAPI.deleteArticle({
        articleId: 1,
        portalSlug: 'room-rental',
      });
      expect(axios.delete).toHaveBeenCalledWith(
        '/api/v1/portals/room-rental/articles/1'
      );
    });
  });
});
