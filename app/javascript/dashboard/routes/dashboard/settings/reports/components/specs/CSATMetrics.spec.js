import { shallowMount } from '@vue/test-utils';
import { createStore } from 'vuex';
import CsatMetrics from '../CsatMetrics.vue';

describe('CsatMetrics.vue', () => {
  let getters;
  let store;
  let wrapper;

  beforeEach(() => {
    getters = {
      'csat/getMetrics': () => ({ totalResponseCount: 100 }),
      'csat/getRatingPercentage': () => ({
        1: 10,
        2: 20,
        3: 30,
        4: 30,
        5: 10,
      }),
      'csat/getRatingCount': () => ({
        1: 10,
        2: 20,
        3: 30,
        4: 30,
        5: 10,
      }),
      'csat/getSatisfactionScore': () => 85,
      'csat/getResponseRate': () => 90,
      'csat/getUIFlags': () => ({ isFetchingMetrics: false }),
    };

    store = createStore({
      getters,
    });

    wrapper = shallowMount(CsatMetrics, {
      global: {
        plugins: [store],
        mocks: {
          $t: msg => msg,
        },
        stubs: {
          CsatMetricCard: true,
          CsatRatingDistribution: true,
        },
      },
    });
  });

  it('computes response count correctly', () => {
    expect(wrapper.vm.responseCount).toBe('100');
  });

  it('renders metric cards with correct values', () => {
    const metricCards = wrapper.findAllComponents({ name: 'CsatMetricCard' });
    expect(metricCards).toHaveLength(3);
  });

  it('renders rating distribution component', () => {
    const distribution = wrapper.findComponent({
      name: 'CsatRatingDistribution',
    });
    expect(distribution.exists()).toBe(true);
  });
});
