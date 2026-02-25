import twitterClient from '../../channel/twitterClient';
import ApiClient from '../../ApiClient';

describe('#TwitterClient', () => {
  it('creates correct instance', () => {
    expect(twitterClient).toBeInstanceOf(ApiClient);
    expect(twitterClient).toHaveProperty('get');
    expect(twitterClient).toHaveProperty('show');
    expect(twitterClient).toHaveProperty('create');
    expect(twitterClient).toHaveProperty('update');
    expect(twitterClient).toHaveProperty('delete');
    expect(twitterClient).toHaveProperty('generateAuthorization');
  });
});
