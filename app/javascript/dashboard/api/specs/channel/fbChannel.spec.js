import fbChannel from '../../channel/fbChannel';
import ApiClient from '../../ApiClient';

describe('#FBChannel', () => {
  it('creates correct instance', () => {
    expect(fbChannel).toBeInstanceOf(ApiClient);
    expect(fbChannel).toHaveProperty('get');
    expect(fbChannel).toHaveProperty('show');
    expect(fbChannel).toHaveProperty('create');
    expect(fbChannel).toHaveProperty('update');
    expect(fbChannel).toHaveProperty('delete');
  });
  describe('API calls', context => {
    it('#create', () => {
      fbChannel.create({ omniauthToken: 'ASFM131CSF@#@$', appId: 'chatwoot' });
      expect(axios.post).toHaveBeenCalledWith(
        '/api/v1/callbacks/register_facebook_page',
        {
          omniauthToken: 'ASFM131CSF@#@$',
          appId: 'chatwoot',
        }
      );
    });
    it('#reauthorize', () => {
      fbChannel.reauthorizeFacebookPage({
        omniauthToken: 'ASFM131CSF@#@$',
        inboxId: 1,
      });
      expect(axios.post).toHaveBeenCalledWith(
        '/api/v1/callbacks/reauthorize_page',
        {
          omniauth_token: 'ASFM131CSF@#@$',
          inbox_id: 1,
        }
      );
    });
  });
});
