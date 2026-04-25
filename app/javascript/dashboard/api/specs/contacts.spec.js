import contactAPI, { buildContactParams } from '../contacts';
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
    expect(contactAPI).toHaveProperty('filter');
    expect(contactAPI).toHaveProperty('destroyAvatar');
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

    it('#get', () => {
      contactAPI.get(1, 'name', 'customer-support');
      expect(axiosMock.get).toHaveBeenCalledWith(
        '/api/v1/contacts?include_contact_inboxes=false&page=1&sort=name&labels[]=customer-support'
      );
    });

    it('#get with pageSize', () => {
      contactAPI.get(1, 'name', 'customer-support', 50);
      expect(axiosMock.get).toHaveBeenCalledWith(
        '/api/v1/contacts?include_contact_inboxes=false&page=1&sort=name&labels[]=customer-support&page_size=50'
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

    it('#getContactLabels', () => {
      contactAPI.getContactLabels(1);
      expect(axiosMock.get).toHaveBeenCalledWith('/api/v1/contacts/1/labels');
    });

    it('#updateContactLabels', () => {
      const labels = ['support-query'];
      contactAPI.updateContactLabels(1, labels);
      expect(axiosMock.post).toHaveBeenCalledWith('/api/v1/contacts/1/labels', {
        labels,
      });
    });

    it('#search', () => {
      contactAPI.search('leads', 1, 'date', 'customer-support');
      expect(axiosMock.get).toHaveBeenCalledWith(
        '/api/v1/contacts/search?include_contact_inboxes=false&page=1&sort=date&q=leads&labels[]=customer-support',
        { signal: undefined }
      );
    });

    it('#search with signal', () => {
      const controller = new AbortController();
      contactAPI.search('leads', 1, 'date', 'customer-support', {
        signal: controller.signal,
      });
      expect(axiosMock.get).toHaveBeenCalledWith(
        '/api/v1/contacts/search?include_contact_inboxes=false&page=1&sort=date&q=leads&labels[]=customer-support',
        { signal: controller.signal }
      );
    });

    it('#search with pageSize', () => {
      contactAPI.search('leads', 1, 'date', 'customer-support', {}, 100);
      expect(axiosMock.get).toHaveBeenCalledWith(
        '/api/v1/contacts/search?include_contact_inboxes=false&page=1&sort=date&q=leads&labels[]=customer-support&page_size=100',
        { signal: undefined }
      );
    });

    it('#destroyCustomAttributes', () => {
      contactAPI.destroyCustomAttributes(1, ['cloudCustomer']);
      expect(axiosMock.post).toHaveBeenCalledWith(
        '/api/v1/contacts/1/destroy_custom_attributes',
        {
          custom_attributes: ['cloudCustomer'],
        }
      );
    });

    it('#importContacts', () => {
      const file = 'file';
      contactAPI.importContacts(file);
      expect(axiosMock.post).toHaveBeenCalledWith(
        '/api/v1/contacts/import',
        expect.any(FormData),
        {
          headers: { 'Content-Type': 'multipart/form-data' },
        }
      );
    });

    it('#filter', () => {
      const queryPayload = {
        payload: [
          {
            attribute_key: 'email',
            filter_operator: 'contains',
            values: ['fayaz'],
            query_operator: null,
          },
        ],
      };
      contactAPI.filter(1, 'name', queryPayload);
      expect(axiosMock.post).toHaveBeenCalledWith(
        '/api/v1/contacts/filter?include_contact_inboxes=false&page=1&sort=name',
        queryPayload
      );
    });

    it('#filter with pageSize', () => {
      const queryPayload = { payload: [] };
      contactAPI.filter(1, 'name', queryPayload, 250);
      expect(axiosMock.post).toHaveBeenCalledWith(
        '/api/v1/contacts/filter?include_contact_inboxes=false&page=1&sort=name&page_size=250',
        queryPayload
      );
    });

    it('#destroyAvatar', () => {
      contactAPI.destroyAvatar(1);
      expect(axiosMock.delete).toHaveBeenCalledWith(
        '/api/v1/contacts/1/avatar'
      );
    });
  });
});

describe('#buildContactParams', () => {
  it('returns correct string without optional params', () => {
    expect(buildContactParams(1, 'name', '', '')).toBe(
      'include_contact_inboxes=false&page=1&sort=name'
    );
  });

  it('includes label when provided', () => {
    expect(buildContactParams(1, 'name', 'customer-support', '')).toBe(
      'include_contact_inboxes=false&page=1&sort=name&labels[]=customer-support'
    );
  });

  it('includes search query and label when both provided', () => {
    expect(
      buildContactParams(1, 'name', 'customer-support', 'message-content')
    ).toBe(
      'include_contact_inboxes=false&page=1&sort=name&q=message-content&labels[]=customer-support'
    );
  });

  it('appends page_size when provided', () => {
    expect(buildContactParams(1, 'name', '', '', 50)).toBe(
      'include_contact_inboxes=false&page=1&sort=name&page_size=50'
    );
  });

  it('omits page_size when not provided', () => {
    expect(buildContactParams(1, 'name', '', '')).not.toContain('page_size');
  });

  it('includes all params together', () => {
    expect(buildContactParams(2, '-created_at', 'vip', 'john', 100)).toBe(
      'include_contact_inboxes=false&page=2&sort=-created_at&q=john&labels[]=vip&page_size=100'
    );
  });
});
