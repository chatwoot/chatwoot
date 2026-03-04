import groupContactsAPI from '../groupContacts';
import ApiClient from '../ApiClient';

describe('#GroupContactsAPI', () => {
  it('creates correct instance', () => {
    expect(groupContactsAPI).toBeInstanceOf(ApiClient);
    expect(groupContactsAPI).toHaveProperty('getGroupContacts');
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
    });

    it('#getGroupContacts with default page', () => {
      groupContactsAPI.getGroupContacts(123);
      expect(axiosMock.get).toHaveBeenCalledWith(
        '/api/v1/conversations/123/group_contacts?page=1'
      );
    });

    it('#getGroupContacts with specified page', () => {
      groupContactsAPI.getGroupContacts(123, { page: 2 });
      expect(axiosMock.get).toHaveBeenCalledWith(
        '/api/v1/conversations/123/group_contacts?page=2'
      );
    });
  });
});
