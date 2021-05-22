import contactAPI from '../contacts';
import ApiClient from '../ApiClient';

describe('#ContactsAPI', () => {
  it('creates correct instance', () => {
    expect(contactAPI).toBeInstanceOf(ApiClient);
    expect(contactAPI).toHaveProperty('get');
    expect(contactAPI).toHaveProperty('show');
    expect(contactAPI).toHaveProperty('create');
    expect(contactAPI).toHaveProperty('update');
    expect(contactAPI).toHaveProperty('delete');
    expect(contactAPI).toHaveProperty('getConversations');
  });

  describe('API calls', () => {
    let originalAxios = null;
    let axiosMock = null;
    beforeEach(() => {
      originalAxios = window.axios;
      axiosMock = {
        post: jest.fn(() => Promise.resolve()),
        get: jest.fn(() => Promise.resolve()),
      };
      window.axios = axiosMock;
    });

    afterEach(() => {
      window.axios = originalAxios;
    });

    it('#get', () => {
      contactAPI.get(1, 'name');
      expect(axiosMock.get).toHaveBeenCalledWith(
        '/api/v1/contacts?page=1&sort=name'
      );
    });

    it('#getConversations', () => {
      contactAPI.getConversations(1);
      expect(axiosMock.get).toHaveBeenCalledWith(
        '/api/v1/contacts/1/conversations'
      );
    });

    it('#getContactableInboxes', () => {
      contactAPI.getContactableInboxes(1);
      expect(axiosMock.get).toHaveBeenCalledWith(
        '/api/v1/contacts/1/contactable_inboxes'
      );
    });
    it('#search', () => {
      contactAPI.search('leads', 1, 'date');
      expect(axiosMock.get).toHaveBeenCalledWith(
        '/api/v1/contacts/search?q=leads&page=1&sort=date'
      );
    });
  });
});
