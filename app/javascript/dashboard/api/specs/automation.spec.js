import automations from '../automation';
import ApiClient from '../ApiClient';

describe('#AutomationsAPI', () => {
  it('creates correct instance', () => {
    expect(automations).toBeInstanceOf(ApiClient);
    expect(automations).toHaveProperty('get');
    expect(automations).toHaveProperty('show');
    expect(automations).toHaveProperty('create');
    expect(automations).toHaveProperty('update');
    expect(automations).toHaveProperty('delete');
    expect(automations).toHaveProperty('clone');
    expect(automations.url).toBe('/api/v1/automation_rules');
  });
});
