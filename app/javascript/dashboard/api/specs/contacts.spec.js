import contactAPI, { buildContactParams } from '../contacts';
import ApiClient from '../ApiClient';
import describeWithAPIMock from './apiSpecHelper';

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

  describeWithAPIMock('API calls', context => {
    it('#get', () => {
      contactAPI.get(1, 'name', 'customer-support');
      expect(context.axiosMock.get).toHaveBeenCalledWith(
        '/api/v1/contacts?include_contact_inboxes=false&page=1&sort=name&labels[]=customer-support'
      );
    });

    it('#getConversations', () => {
      contactAPI.getConversations(1);
      expect(context.axiosMock.get).toHaveBeenCalledWith(
        '/api/v1/contacts/1/conversations'
      );
    });

    it('#getContactableInboxes', () => {
      contactAPI.getContactableInboxes(1);
      expect(context.axiosMock.get).toHaveBeenCalledWith(
        '/api/v1/contacts/1/contactable_inboxes'
      );
    });

    it('#getContactLabels', () => {
      contactAPI.getContactLabels(1);
      expect(context.axiosMock.get).toHaveBeenCalledWith(
        '/api/v1/contacts/1/labels'
      );
    });

    it('#updateContactLabels', () => {
      const labels = ['support-query'];
      contactAPI.updateContactLabels(1, labels);
      expect(context.axiosMock.post).toHaveBeenCalledWith(
        '/api/v1/contacts/1/labels',
        {
          labels,
        }
      );
    });

    it('#search', () => {
      contactAPI.search('leads', 1, 'date', 'customer-support');
      expect(context.axiosMock.get).toHaveBeenCalledWith(
        '/api/v1/contacts/search?include_contact_inboxes=false&page=1&sort=date&q=leads&labels[]=customer-support'
      );
    });

    it('#destroyCustomAttributes', () => {
      contactAPI.destroyCustomAttributes(1, ['cloudCustomer']);
      expect(context.axiosMock.post).toHaveBeenCalledWith(
        '/api/v1/contacts/1/destroy_custom_attributes',
        {
          custom_attributes: ['cloudCustomer'],
        }
      );
    });

    it('#importContacts', () => {
      const file = 'file';
      contactAPI.importContacts(file);
      expect(context.axiosMock.post).toHaveBeenCalledWith(
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
      expect(context.axiosMock.post).toHaveBeenCalledWith(
        '/api/v1/contacts/filter?include_contact_inboxes=false&page=1&sort=name',
        queryPayload
      );
    });

    it('#destroyAvatar', () => {
      contactAPI.destroyAvatar(1);
      expect(context.axiosMock.delete).toHaveBeenCalledWith(
        '/api/v1/contacts/1/avatar'
      );
    });
  });
});

describe('#buildContactParams', () => {
  it('returns correct string', () => {
    expect(buildContactParams(1, 'name', '', '')).toBe(
      'include_contact_inboxes=false&page=1&sort=name'
    );
    expect(buildContactParams(1, 'name', 'customer-support', '')).toBe(
      'include_contact_inboxes=false&page=1&sort=name&labels[]=customer-support'
    );
    expect(
      buildContactParams(1, 'name', 'customer-support', 'message-content')
    ).toBe(
      'include_contact_inboxes=false&page=1&sort=name&q=message-content&labels[]=customer-support'
    );
  });
});
