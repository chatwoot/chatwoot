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
    expect(fbChannel).toHaveProperty('markSeen');
    expect(fbChannel).toHaveProperty('toggleTyping');
  });
});
