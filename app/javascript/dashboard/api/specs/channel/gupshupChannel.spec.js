import gupshupChannel from '../../channel/gupshupChannel';
import ApiClient from '../../ApiClient';

describe('#gupshupChannel', () => {
  it('creates correct instance', () => {
    expect(gupshupChannel).toBeInstanceOf(ApiClient);
    expect(gupshupChannel).toHaveProperty('get');
    expect(gupshupChannel).toHaveProperty('show');
    expect(gupshupChannel).toHaveProperty('create');
    expect(gupshupChannel).toHaveProperty('update');
    expect(gupshupChannel).toHaveProperty('delete');
  });
});
