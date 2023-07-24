import bulkActions from '../bulkActions';
import ApiClient from '../ApiClient';

describe('#BulkActionsAPI', () => {
  it('creates correct instance', () => {
    expect(bulkActions).toBeInstanceOf(ApiClient);
    expect(bulkActions).toHaveProperty('create');
  });
});
