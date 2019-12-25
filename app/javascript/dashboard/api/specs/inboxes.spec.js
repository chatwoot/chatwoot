import inboxes from '../inboxes';
import ApiClient from '../ApiClient';

describe('#AgentAPI', () => {
  it('creates correct instance', () => {
    expect(inboxes).toBeInstanceOf(ApiClient);
    expect(inboxes).toHaveProperty('get');
    expect(inboxes).toHaveProperty('show');
    expect(inboxes).toHaveProperty('create');
    expect(inboxes).toHaveProperty('update');
    expect(inboxes).toHaveProperty('delete');
  });
});
