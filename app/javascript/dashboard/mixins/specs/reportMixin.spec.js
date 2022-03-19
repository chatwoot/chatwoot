import { shallowMount, createLocalVue } from '@vue/test-utils';
import reportMixin from '../reportMixin';
import reportFixtures from './reportMixinFixtures';
import Vuex from 'vuex';
const localVue = createLocalVue();
localVue.use(Vuex);

describe('reportMixin', () => {
  let getters;
  let store;
  beforeEach(() => {
    getters = {
      getAccountSummary: () => reportFixtures.summary,
    };
    store = new Vuex.Store({ getters });
  });

  it('display the metric', () => {
    const Component = {
      render() {},
      title: 'TestComponent',
      mixins: [reportMixin],
    };
    const wrapper = shallowMount(Component, { store, localVue });
    expect(wrapper.vm.displayMetric('conversations_count')).toEqual(5);
    expect(wrapper.vm.displayMetric('avg_first_response_time')).toEqual(
      '3 Min'
    );
  });

  it('calculate the trend', () => {
    const Component = {
      render() {},
      title: 'TestComponent',
      mixins: [reportMixin],
    };
    const wrapper = shallowMount(Component, { store, localVue });
    expect(wrapper.vm.calculateTrend('conversations_count')).toEqual(25);
    expect(wrapper.vm.calculateTrend('resolutions_count')).toEqual(0);
  });
});
