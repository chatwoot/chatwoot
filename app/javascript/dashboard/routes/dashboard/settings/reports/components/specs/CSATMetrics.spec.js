import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import CsatMetrics from '../CsatMetrics.vue';

const localVue = createLocalVue();
localVue.use(Vuex);

const mountParams = {
  mocks: {
    $t: msg => msg,
  },
  stubs: ['csat-metric-card', 'woot-horizontal-bar'],
};

describe('CsatMetrics.vue', () => {
  let getters;
  let store;
  let wrapper;
  const filters = { rating: 3 };

  beforeEach(() => {
    getters = {
      'csat/getMetrics': () => ({ totalResponseCount: 100 }),
      'csat/getRatingPercentage': () => ({ 1: 10, 2: 20, 3: 30, 4: 30, 5: 10 }),
      'csat/getSatisfactionScore': () => 85,
      'csat/getResponseRate': () => 90,
    };

    store = new Vuex.Store({
      getters,
    });

    wrapper = shallowMount(CsatMetrics, {
      store,
      localVue,
      propsData: { filters },
      ...mountParams,
    });
  });

  it('computes response count correctly', () => {
    expect(wrapper.vm.responseCount).toBe('100');
    expect(wrapper.html()).toMatchSnapshot();
  });

  it('formats values to percent correctly', () => {
    expect(wrapper.vm.formatToPercent(85)).toBe('85%');
    expect(wrapper.vm.formatToPercent(null)).toBe('--');
  });

  it('maps rating value to emoji correctly', () => {
    const rating = wrapper.vm.csatRatings[0]; // assuming this is { value: 1, emoji: '😡' }
    expect(wrapper.vm.ratingToEmoji(rating.value)).toBe(rating.emoji);
  });

  it('hides report card if rating filter is enabled', () => {
    expect(wrapper.find({ ref: 'csatHorizontalBarChart' }).exists()).toBe(
      false
    );
  });

  it('shows report card if rating filter is not enabled', async () => {
    await wrapper.setProps({ filters: {} });
    expect(wrapper.find({ ref: 'csatHorizontalBarChart' }).exists()).toBe(true);
  });
});
