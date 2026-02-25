import AgentBotsAPI from '../agentBots';
import ApiClient from '../ApiClient';

describe('#AgentBotsAPI', () => {
  it('creates correct instance', () => {
    expect(AgentBotsAPI).toBeInstanceOf(ApiClient);
    expect(AgentBotsAPI).toHaveProperty('get');
    expect(AgentBotsAPI).toHaveProperty('show');
    expect(AgentBotsAPI).toHaveProperty('create');
    expect(AgentBotsAPI).toHaveProperty('update');
    expect(AgentBotsAPI).toHaveProperty('delete');
    expect(AgentBotsAPI).toHaveProperty('resetAccessToken');
  });
});
