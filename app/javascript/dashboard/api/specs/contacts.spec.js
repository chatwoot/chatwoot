import contactAPI from '../contacts';
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
      contactAPI.get(1, 'name');
      expect(context.axiosMock.get).toHaveBeenCalledWith(
        '/api/v1/contacts?page=1&sort=name'
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
      contactAPI.search('leads', 1, 'date');
      expect(context.axiosMock.get).toHaveBeenCalledWith(
        '/api/v1/contacts/search?q=leads&page=1&sort=date'
      );
    });
  });
});
