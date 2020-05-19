import { createWrapper } from '@vue/test-utils';
import agentMixin from '../agentMixin';
import Vue from 'vue';

const translations = {
  'AGENT_AVAILABILITY.IS_AVAILABLE': 'is available',
  'AGENT_AVAILABILITY.ARE_AVAILABLE': 'are available',
  'AGENT_AVAILABILITY.OTHERS_ARE_AVAILABLE': 'others are available',
  'AGENT_AVAILABILITY.AND': 'and',
};

const TestComponent = {
  render() {},
  title: 'TestComponent',
  mixins: [agentMixin],
  methods: {
    $t(key) {
      return translations[key];
    },
  },
};

describe('agentMixin', () => {
  test('returns correct text', () => {
    const Constructor = Vue.extend(TestComponent);
    const vm = new Constructor().$mount();
    const wrapper = createWrapper(vm);

    expect(wrapper.vm.getAvailableAgentsText([{ name: 'Pranav' }])).toEqual(
      'Pranav is available'
    );

    expect(
      wrapper.vm.getAvailableAgentsText([
        { name: 'Pranav' },
        { name: 'Nithin' },
      ])
    ).toEqual('Pranav and Nithin are available');

    expect(
      wrapper.vm.getAvailableAgentsText([
        { name: 'Pranav' },
        { name: 'Nithin' },
        { name: 'Subin' },
        { name: 'Sojan' },
      ])
    ).toEqual('Pranav and 3 others are available');
  });
});
