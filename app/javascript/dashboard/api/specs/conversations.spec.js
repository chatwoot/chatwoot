import conversations from '../conversations';
import ApiClient from '../ApiClient';

describe('#ConversationApi', () => {
  it('creates correct instance', () => {
    expect(conversations).toBeInstanceOf(ApiClient);
    expect(conversations).toHaveProperty('get');
    expect(conversations).toHaveProperty('show');
    expect(conversations).toHaveProperty('create');
    expect(conversations).toHaveProperty('update');
    expect(conversations).toHaveProperty('delete');
    expect(conversations).toHaveProperty('getLabels');
    expect(conversations).toHaveProperty('updateLabels');
  });
});
