import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import CsatMetrics from '../CsatMetrics.vue';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('CsatMetrics.vue', () => {
  let getters;
  let store;

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
  });

  it('computes response count correctly', () => {
    const wrapper = shallowMount(CsatMetrics, {
      store,
      localVue,
      mocks: {
        $t: msg => msg,
      },
      stubs: ['csat-metric-card', 'woot-horizontal-bar'],
    });

    expect(wrapper.vm.responseCount).toBe('100');
    expect(wrapper.html()).toMatchSnapshot();
  });

  it('formats values to percent correctly', () => {
    const wrapper = shallowMount(CsatMetrics, {
      store,
      localVue,
      mocks: {
        $t: msg => msg,
      },
      stubs: ['csat-metric-card', 'woot-horizontal-bar'],
    });

    expect(wrapper.vm.formatToPercent(85)).toBe('85%');
    expect(wrapper.vm.formatToPercent(null)).toBe('--');
  });

  it('maps rating value to emoji correctly', () => {
    const wrapper = shallowMount(CsatMetrics, {
      store,
      localVue,
      mocks: {
        $t: msg => msg,
      },
      stubs: ['csat-metric-card', 'woot-horizontal-bar'],
    });

    const rating = wrapper.vm.csatRatings[0]; // assuming this is { value: 1, emoji: '😡' }
    expect(wrapper.vm.ratingToEmoji(rating.value)).toBe(rating.emoji);
  });
});
