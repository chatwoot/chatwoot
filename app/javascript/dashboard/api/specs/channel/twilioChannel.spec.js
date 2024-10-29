import twilioChannel from '../../channel/twilioChannel';
import ApiClient from '../../ApiClient';

describe('#twilioChannel', () => {
  it('creates correct instance', () => {
    expect(twilioChannel).toBeInstanceOf(ApiClient);
    expect(twilioChannel).toHaveProperty('get');
    expect(twilioChannel).toHaveProperty('show');
    expect(twilioChannel).toHaveProperty('create');
    expect(twilioChannel).toHaveProperty('update');
    expect(twilioChannel).toHaveProperty('delete');
  });
});
