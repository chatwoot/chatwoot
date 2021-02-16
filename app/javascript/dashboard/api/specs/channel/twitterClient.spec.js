import TwitterClient from '../../channel/twitterClient';
import ApiClient from '../../ApiClient';

describe('#TwitterClient', () => {
  it('creates correct instance', () => {
    expect(TwitterClient).toBeInstanceOf(ApiClient);
    expect(TwitterClient).toHaveProperty('generateAuthorization');
  });
});
