import companyAPI from '../companies';
import ApiClient from '../ApiClient';

describe('#CompanyAPI', () => {
  it('creates correct instance', () => {
    expect(companyAPI).toBeInstanceOf(ApiClient);
    expect(companyAPI).toHaveProperty('get');
    expect(companyAPI).toHaveProperty('show');
    expect(companyAPI).toHaveProperty('update');
    expect(companyAPI).toHaveProperty('delete');
    expect(companyAPI).toHaveProperty('search');
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

    it('#get includes pagination and sorting params', () => {
      companyAPI.get({});
      expect(axiosMock.get).toHaveBeenCalledWith(
        '/api/v1/companies?page=1&sort=name'
      );
    });

    it('#search encodes query params', () => {
      companyAPI.search('acme & co', 2, 'domain');
      expect(axiosMock.get).toHaveBeenCalledWith(
        '/api/v1/companies/search?q=acme+%26+co&page=2&sort=domain'
      );
    });

    it('#search keeps empty query param for backend validation', () => {
      companyAPI.search('', 1, 'name');
      expect(axiosMock.get).toHaveBeenCalledWith(
        '/api/v1/companies/search?q=&page=1&sort=name'
      );
    });

    it('#destroyAvatar deletes the company avatar endpoint', () => {
      companyAPI.destroyAvatar(1);
      expect(axiosMock.delete).toHaveBeenCalledWith(
        '/api/v1/companies/1/avatar'
      );
    });

    it('#listContacts fetches company contacts', () => {
      companyAPI.listContacts(1, 2);
      expect(axiosMock.get).toHaveBeenCalledWith(
        '/api/v1/companies/1/contacts?page=2'
      );
    });

    it('#searchContacts encodes contact search params', () => {
      companyAPI.searchContacts(1, 'jane & co', 3);
      expect(axiosMock.get).toHaveBeenCalledWith(
        '/api/v1/companies/1/contacts/search?q=jane+%26+co&page=3'
      );
    });

    it('#createContact links a contact to the company', () => {
      companyAPI.createContact(1, { contact_id: 2 });
      expect(axiosMock.post).toHaveBeenCalledWith(
        '/api/v1/companies/1/contacts',
        { contact_id: 2 }
      );
    });

    it('#removeContact unlinks a contact from the company', () => {
      companyAPI.removeContact(1, 2);
      expect(axiosMock.delete).toHaveBeenCalledWith(
        '/api/v1/companies/1/contacts/2'
      );
    });

    it('#destroyCustomAttributes removes company custom attributes', () => {
      companyAPI.destroyCustomAttributes(1, ['plan']);
      expect(axiosMock.post).toHaveBeenCalledWith(
        '/api/v1/companies/1/destroy_custom_attributes',
        { custom_attributes: ['plan'] }
      );
    });
  });
});
