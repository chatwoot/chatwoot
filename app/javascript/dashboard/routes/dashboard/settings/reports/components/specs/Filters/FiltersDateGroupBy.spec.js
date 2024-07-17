import { shallowMount } from '@vue/test-utils';
import ReportsFiltersDateGroupBy from '../../Filters/DateGroupBy.vue';
import { GROUP_BY_OPTIONS } from '../../../constants';

const mountParams = {
  mocks: {
    $t: msg => msg,
  },
  stubs: ['multiselect'],
};

describe('ReportsFiltersDateGroupBy.vue', () => {
  it('emits "on-grouping-change" event when changeFilterSelection is called', () => {
    const wrapper = shallowMount(ReportsFiltersDateGroupBy, mountParams);

    const selectedFilter = GROUP_BY_OPTIONS.DAY;
    wrapper.vm.changeFilterSelection(selectedFilter);

    expect(wrapper.emitted('on-grouping-change')).toBeTruthy();
    expect(wrapper.emitted('on-grouping-change')[0]).toEqual([selectedFilter]);
  });

  it('updates currentSelectedFilter when selectedOption is changed', async () => {
    const wrapper = shallowMount(ReportsFiltersDateGroupBy, mountParams);

    const newSelectedOption = GROUP_BY_OPTIONS.MONTH;
    await wrapper.setProps({ selectedOption: newSelectedOption });

    expect(wrapper.vm.currentSelectedFilter).toEqual({
      ...newSelectedOption,
      groupBy: newSelectedOption.translationKey,
    });
  });

  it('initializes translatedOptions correctly', () => {
    const wrapper = shallowMount(ReportsFiltersDateGroupBy, mountParams);

    const expectedOptions = wrapper.vm.validGroupOptions.map(option => ({
      ...option,
      groupBy: option.translationKey,
    }));

    expect(wrapper.vm.translatedOptions).toEqual(expectedOptions);
  });
});
