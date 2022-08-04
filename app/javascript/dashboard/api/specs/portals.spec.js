import portalsAPI from '../helpCenter/portals';
import ApiClient from '../ApiClient';
import describeWithAPIMock from './apiSpecHelper';

describe('#TeamsAPI', () => {
  it('creates correct instance', () => {
    expect(portalsAPI).toBeInstanceOf(ApiClient);
    expect(portalsAPI).toHaveProperty('get');
    expect(portalsAPI).toHaveProperty('show');
    expect(portalsAPI).toHaveProperty('create');
    expect(portalsAPI).toHaveProperty('update');
    expect(portalsAPI).toHaveProperty('delete');
    expect(portalsAPI).toHaveProperty('getArticles');
  });
  describeWithAPIMock('API calls', context => {
    it('#getArticles', () => {
      portalsAPI.getArticles({
        pageNumber: 1,
        portalSlug: 'room-rental',
        locale: 'en-US',
        status: 'published',
        author_id: '1',
      });
      expect(context.axiosMock.get).toHaveBeenCalledWith(
        '/api/v1/portals/room-rental/articles?page=1&locale=en-US&status=published&author_id=1'
      );
    });
  });
});
