import evolutionChannelClient from '../../channel/evolutionChannel';
import ApiClient from '../../ApiClient';

describe('#evolutionChannelClient', () => {
  it('creates correct instance', () => {
    expect(evolutionChannelClient).toBeInstanceOf(ApiClient);
    expect(evolutionChannelClient).toHaveProperty('get');
    expect(evolutionChannelClient).toHaveProperty('show');
    expect(evolutionChannelClient).toHaveProperty('create');
    expect(evolutionChannelClient).toHaveProperty('update');
    expect(evolutionChannelClient).toHaveProperty('delete');
  });

  it('is configured with correct endpoint and account scoped', () => {
    expect(evolutionChannelClient.url).toContain('channels/evolution_channel');
    expect(evolutionChannelClient.options.accountScoped).toBe(true);
  });
});
