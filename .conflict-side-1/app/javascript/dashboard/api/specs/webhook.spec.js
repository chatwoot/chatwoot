import webhooksAPI from '../webhooks';
import ApiClient from '../ApiClient';

describe('#webhooksAPI', () => {
  it('creates correct instance', () => {
    expect(webhooksAPI).toBeInstanceOf(ApiClient);
    expect(webhooksAPI).toHaveProperty('get');
    expect(webhooksAPI).toHaveProperty('show');
    expect(webhooksAPI).toHaveProperty('create');
    expect(webhooksAPI).toHaveProperty('update');
    expect(webhooksAPI).toHaveProperty('delete');
  });
});
