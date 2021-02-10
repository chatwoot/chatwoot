import teams from '../teams';
import ApiClient from '../ApiClient';

describe('#TeamsAPI', () => {
  it('creates correct instance', () => {
    expect(teams).toBeInstanceOf(ApiClient);
    expect(teams).toHaveProperty('get');
    expect(teams).toHaveProperty('show');
    expect(teams).toHaveProperty('create');
    expect(teams).toHaveProperty('update');
    expect(teams).toHaveProperty('delete');
    expect(teams).toHaveProperty('getAgents');
    expect(teams).toHaveProperty('addAgents');
  });
});
