import contacts from '../contacts';
import ApiClient from '../ApiClient';

describe('#ContactsAPI', () => {
  it('creates correct instance', () => {
    expect(contacts).toBeInstanceOf(ApiClient);
    expect(contacts).toHaveProperty('get');
    expect(contacts).toHaveProperty('show');
    expect(contacts).toHaveProperty('create');
    expect(contacts).toHaveProperty('update');
    expect(contacts).toHaveProperty('delete');
    expect(contacts).toHaveProperty('getConversations');
  });
});
