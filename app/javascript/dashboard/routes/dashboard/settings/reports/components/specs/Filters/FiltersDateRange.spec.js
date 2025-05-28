import { shallowMount } from '@vue/test-utils';
import ReportFiltersDateRange from '../../Filters/DateRange.vue';
import { DATE_RANGE_OPTIONS } from '../../../constants';

const mountParams = {
  global: {
    mocks: {
      $t: msg => msg,
    },
    stubs: ['multiselect'],
  },
};

describe('ReportFiltersDateRange.vue', () => {
  it('emits "on-range-change" event when updateRange is called', () => {
    const wrapper = shallowMount(ReportFiltersDateRange, mountParams);

    const selectedRange = DATE_RANGE_OPTIONS.LAST_7_DAYS;
    wrapper.vm.updateRange(selectedRange);

    expect(wrapper.emitted('on-range-change')).toBeTruthy();
    expect(wrapper.emitted('on-range-change')[0]).toEqual([selectedRange]);
  });

  it('initializes options correctly', () => {
    const wrapper = shallowMount(ReportFiltersDateRange, mountParams);

    const expectedOptions = Object.values(DATE_RANGE_OPTIONS).map(option => ({
      ...option,
      name: option.translationKey,
    }));

    expect(wrapper.vm.options).toEqual(expectedOptions);
  });

  it('initializes selectedOption correctly', () => {
    const wrapper = shallowMount(ReportFiltersDateRange, mountParams);
    const expectedSelectedOption = Object.values(DATE_RANGE_OPTIONS)[0];
    expect(wrapper.vm.selectedOption).toEqual({
      ...expectedSelectedOption,
      name: expectedSelectedOption.translationKey,
    });
  });
});
