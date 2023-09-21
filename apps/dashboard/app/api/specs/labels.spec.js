import labels from '../labels';
import ApiClient from '../ApiClient';

describe('#LabelsAPI', () => {
  it('creates correct instance', () => {
    expect(labels).toBeInstanceOf(ApiClient);
    expect(labels).toHaveProperty('get');
    expect(labels).toHaveProperty('show');
    expect(labels).toHaveProperty('create');
    expect(labels).toHaveProperty('update');
    expect(labels).toHaveProperty('delete');
    expect(labels.url).toBe('/api/v1/labels');
  });
});
