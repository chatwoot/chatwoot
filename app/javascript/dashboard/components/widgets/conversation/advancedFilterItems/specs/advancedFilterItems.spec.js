import defaultFilters from '../index';
import { filterAttributeGroups } from '../index';

describe('#filterItems', () => {
  it('Matches the correct filterItems', () => {
    expect(defaultFilters).toMatchObject(defaultFilters);
    expect(filterAttributeGroups).toMatchObject(filterAttributeGroups);
  });
});
