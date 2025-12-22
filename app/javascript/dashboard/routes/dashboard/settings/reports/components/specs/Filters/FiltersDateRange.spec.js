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
  it('emits "onRangeChange" event when updateRange is called', () => {
    const wrapper = shallowMount(ReportFiltersDateRange, mountParams);

    const selectedRange = DATE_RANGE_OPTIONS.LAST_7_DAYS;
    wrapper.vm.updateRange(selectedRange);

    expect(wrapper.emitted('onRangeChange')).toBeTruthy();
    expect(wrapper.emitted('onRangeChange')[0]).toEqual([selectedRange]);
  });

  it('initializes options correctly', () => {
    const wrapper = shallowMount(ReportFiltersDateRange, mountParams);

    const expectedIds = Object.values(DATE_RANGE_OPTIONS).map(
      option => option.id
    );
    const receivedIds = wrapper.vm.options.map(option => option.id);

    expect(receivedIds).toEqual(expectedIds);
  });

  it('initializes selectedOption correctly', () => {
    const wrapper = shallowMount(ReportFiltersDateRange, mountParams);
    const expectedId = Object.values(DATE_RANGE_OPTIONS)[0].id;
    expect(wrapper.vm.selectedOption.id).toBe(expectedId);
  });
});
