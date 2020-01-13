import agents from '../contacts';
import ApiClient from '../ApiClient';

describe('#ContactsAPI', () => {
  it('creates correct instance', () => {
    expect(agents).toBeInstanceOf(ApiClient);
    expect(agents).toHaveProperty('get');
    expect(agents).toHaveProperty('show');
    expect(agents).toHaveProperty('create');
    expect(agents).toHaveProperty('update');
    expect(agents).toHaveProperty('delete');
    expect(agents).toHaveProperty('getConversations');
  });
});
