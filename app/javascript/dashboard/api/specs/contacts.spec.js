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
