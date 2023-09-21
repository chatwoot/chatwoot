import filterMixin from '../filterMixin';
import { shallowMount } from '@vue/test-utils';
import MockComponent from './MockComponent.vue';

describe('Test mixin function', () => {
  const wrapper = shallowMount(MockComponent, {
    mixins: [filterMixin],
  });

  it('should return proper value from bool', () => {
    expect(wrapper.vm.setFilterAttributes).toBeTruthy();
  });

  it('should return proper value from bool', () => {
    expect(wrapper.vm.initializeExistingFilterToModal).toBeTruthy();
  });
});
