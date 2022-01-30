import { mount } from '@vue/test-utils';
import filterMixin from '../filterMixin';
import { filterGroups } from './filterFixtures';
describe('filterMixin', () => {
  test('set filterGroups using component filterGroups property', () => {
    const Component = {
      render() {},
      mixins: [filterMixin],
    };
    mount(Component);
    expect(filterGroups).toBe(filterGroups);
  });
});
