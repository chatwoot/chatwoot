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
      getBotSummary: () => reportFixtures.botSummary,
      getAccountReports: () => reportFixtures.report,
    };
    store = new Vuex.Store({ getters });
  });

  it('display the metric for account', async () => {
    const Component = {
      render() {},
      title: 'TestComponent',
      mixins: [reportMixin],
    };
    const wrapper = shallowMount(Component, { store, localVue });
    await wrapper.setProps({
      accountSummaryKey: 'getAccountSummary',
    });
    expect(wrapper.vm.displayMetric('conversations_count')).toEqual('5,000');
    expect(wrapper.vm.displayMetric('avg_first_response_time')).toEqual(
      '3 Min 18 Sec'
    );
  });

  it('display the metric for bot', async () => {
    const Component = {
      render() {},
      title: 'TestComponent',
      mixins: [reportMixin],
    };
    const wrapper = shallowMount(Component, { store, localVue });
    await wrapper.setProps({
      accountSummaryKey: 'getBotSummary',
    });
    expect(wrapper.vm.displayMetric('bot_resolutions_count')).toEqual('10');
    expect(wrapper.vm.displayMetric('bot_handoffs_count')).toEqual('20');
  });

  it('display the metric', () => {
    const Component = {
      render() {},
      title: 'TestComponent',
      mixins: [reportMixin],
    };
    const wrapper = shallowMount(Component, { store, localVue });
    expect(wrapper.vm.displayMetric('conversations_count')).toEqual('5,000');
    expect(wrapper.vm.displayMetric('avg_first_response_time')).toEqual(
      '3 Min 18 Sec'
    );
  });

  it('calculate the trend', () => {
    const Component = {
      render() {},
      title: 'TestComponent',
      mixins: [reportMixin],
    };
    const wrapper = shallowMount(Component, { store, localVue });
    expect(wrapper.vm.calculateTrend('conversations_count')).toEqual(124900);
    expect(wrapper.vm.calculateTrend('resolutions_count')).toEqual(0);
  });

  it('display info text', () => {
    const Component = {
      render() {},
      title: 'TestComponent',
      mixins: [reportMixin],
      data() {
        return {
          currentSelection: 0,
        };
      },
      computed: {
        metrics() {
          return [
            {
              DESC: '( Avg )',
              INFO_TEXT: 'Total number of conversations used for computation:',
              KEY: 'avg_first_response_time',
              NAME: 'First Response Time',
            },
          ];
        },
      },
    };
    const wrapper = shallowMount(Component, { store, localVue });
    expect(wrapper.vm.displayInfoText('avg_first_response_time')).toEqual(
      'Total number of conversations used for computation: 4'
    );
  });

  it('do not display info text', () => {
    const Component = {
      render() {},
      title: 'TestComponent',
      mixins: [reportMixin],
      data() {
        return {
          currentSelection: 0,
        };
      },
      computed: {
        metrics() {
          return [
            {
              DESC: '( Total )',
              INFO_TEXT: '',
              KEY: 'conversation_count',
              NAME: 'Conversations',
            },
            {
              DESC: '( Avg )',
              INFO_TEXT: 'Total number of conversations used for computation:',
              KEY: 'avg_first_response_time',
              NAME: 'First Response Time',
            },
          ];
        },
      },
    };
    const wrapper = shallowMount(Component, { store, localVue });
    expect(wrapper.vm.displayInfoText('conversation_count')).toEqual('');
    expect(wrapper.vm.displayInfoText('incoming_messages_count')).toEqual('');
  });
});
