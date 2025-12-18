import ApiClient from '../ApiClient';
import tiktokClient from '../channel/tiktokClient';

describe('#TiktokClient', () => {
  it('creates correct instance', () => {
    expect(tiktokClient).toBeInstanceOf(ApiClient);
    expect(tiktokClient).toHaveProperty('generateAuthorization');
  });

  describe('#generateAuthorization', () => {
    const originalAxios = window.axios;
    const originalPathname = window.location.pathname;
    const axiosMock = {
      post: vi.fn(() => Promise.resolve()),
    };

    beforeEach(() => {
      window.axios = axiosMock;
      window.history.pushState({}, '', '/app/accounts/1/settings');
    });

    afterEach(() => {
      window.axios = originalAxios;
      window.history.pushState({}, '', originalPathname);
    });

    it('posts to the authorization endpoint', () => {
      tiktokClient.generateAuthorization({ state: 'test-state' });
      expect(axiosMock.post).toHaveBeenCalledWith(
        '/api/v1/accounts/1/tiktok/authorization',
        { state: 'test-state' }
      );
    });
  });
});
