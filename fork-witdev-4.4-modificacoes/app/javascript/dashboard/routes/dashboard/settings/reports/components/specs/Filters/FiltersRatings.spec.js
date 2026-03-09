import { shallowMount } from '@vue/test-utils';
import ReportFiltersRatings from '../../Filters/Ratings.vue';
import { CSAT_RATINGS } from 'shared/constants/messages';

const mountParams = {
  global: {
    mocks: {
      $t: msg => msg,
    },
    stubs: ['multiselect'],
  },
};

describe('ReportFiltersRatings.vue', () => {
  it('emits "rating-filter-selection" event when handleInput is called', async () => {
    const wrapper = shallowMount(ReportFiltersRatings, {
      ...mountParams,
    });

    const selectedRating = { value: 1, label: 'Rating 1' };
    await wrapper.setData({ selectedOption: selectedRating });

    await wrapper.vm.handleInput(selectedRating);

    expect(wrapper.emitted('ratingFilterSelection')).toBeTruthy();
    expect(wrapper.emitted('ratingFilterSelection')[0]).toEqual([
      selectedRating,
    ]);
  });

  it('initializes options correctly', () => {
    const wrapper = shallowMount(ReportFiltersRatings, {
      ...mountParams,
    });

    const expectedOptions = CSAT_RATINGS.map(option => ({
      ...option,
      label: option.translationKey,
    }));

    expect(wrapper.vm.options).toEqual(expectedOptions);
  });
});
