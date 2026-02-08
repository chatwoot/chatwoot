import webChannelClient from '../../channel/webChannel';
import ApiClient from '../../ApiClient';

describe('#webChannelClient', () => {
  it('creates correct instance', () => {
    expect(webChannelClient).toBeInstanceOf(ApiClient);
    expect(webChannelClient).toHaveProperty('get');
    expect(webChannelClient).toHaveProperty('show');
    expect(webChannelClient).toHaveProperty('create');
    expect(webChannelClient).toHaveProperty('update');
    expect(webChannelClient).toHaveProperty('delete');
  });
});
