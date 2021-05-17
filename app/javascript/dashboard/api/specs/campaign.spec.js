import campaigns from '../campaigns';
import ApiClient from '../ApiClient';

describe('#CampaignAPI', () => {
  it('creates correct instance', () => {
    expect(campaigns).toBeInstanceOf(ApiClient);
    expect(campaigns).toHaveProperty('get');
    expect(campaigns).toHaveProperty('show');
    expect(campaigns).toHaveProperty('create');
    expect(campaigns).toHaveProperty('update');
    expect(campaigns).toHaveProperty('delete');
  });
});
