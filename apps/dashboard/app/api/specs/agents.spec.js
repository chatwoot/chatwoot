import agents from '../agents';
import ApiClient from '../ApiClient';

describe('#AgentAPI', () => {
  it('creates correct instance', () => {
    expect(agents).toBeInstanceOf(ApiClient);
    expect(agents).toHaveProperty('get');
    expect(agents).toHaveProperty('show');
    expect(agents).toHaveProperty('create');
    expect(agents).toHaveProperty('update');
    expect(agents).toHaveProperty('delete');
  });
});
