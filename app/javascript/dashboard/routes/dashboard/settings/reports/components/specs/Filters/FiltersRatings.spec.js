import { shallowMount, createLocalVue } from '@vue/test-utils';
import ReportFiltersRatings from '../../Filters/Ratings.vue';
import { CSAT_RATINGS } from 'shared/constants/messages';

const mountParams = {
  mocks: {
    $t: msg => msg,
  },
  stubs: ['multiselect'],
};

const localVue = createLocalVue();

describe('ReportFiltersRatings.vue', () => {
  it('emits "rating-filter-selection" event when handleInput is called', () => {
    const wrapper = shallowMount(ReportFiltersRatings, {
      localVue,
      ...mountParams,
    });

    const selectedRating = { value: 1, label: 'Rating 1' };
    wrapper.setData({ selectedOption: selectedRating });

    wrapper.vm.handleInput(selectedRating);

    expect(wrapper.emitted('rating-filter-selection')).toBeTruthy();
    expect(wrapper.emitted('rating-filter-selection')[0]).toEqual([
      selectedRating,
    ]);
  });

  it('initializes options correctly', () => {
    const wrapper = shallowMount(ReportFiltersRatings, {
      localVue,
      ...mountParams,
    });

    const expectedOptions = CSAT_RATINGS.map(option => ({
      ...option,
      label: option.translationKey,
    }));

    expect(wrapper.vm.options).toEqual(expectedOptions);
  });
});
