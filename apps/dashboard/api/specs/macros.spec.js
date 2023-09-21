import macros from '../macros';
import ApiClient from '../ApiClient';

describe('#macrosAPI', () => {
  it('creates correct instance', () => {
    expect(macros).toBeInstanceOf(ApiClient);
    expect(macros).toHaveProperty('get');
    expect(macros).toHaveProperty('create');
    expect(macros).toHaveProperty('update');
    expect(macros).toHaveProperty('delete');
    expect(macros).toHaveProperty('show');
    expect(macros.url).toBe('/api/v1/macros');
  });
});
