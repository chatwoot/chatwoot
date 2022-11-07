import categoriesAPI from '../../helpCenter/categories';
import ApiClient from '../../ApiClient';

describe('#BulkActionsAPI', () => {
  it('creates correct instance', () => {
    expect(categoriesAPI).toBeInstanceOf(ApiClient);
    expect(categoriesAPI).toHaveProperty('get');
    expect(categoriesAPI).toHaveProperty('create');
    expect(categoriesAPI).toHaveProperty('update');
    expect(categoriesAPI).toHaveProperty('delete');
  });
});
