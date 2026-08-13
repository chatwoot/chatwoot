import { shallowMount } from '@vue/test-utils';
import BarChart from '../charts/BarChart.vue';

vi.mock('@chatwoot/viz', () => ({
  BarChart: {
    name: 'VizBarChart',
    props: ['data', 'ariaLabel', 'onItemClick'],
    template: '<button @click="onItemClick?.({ pointIndex: 0 })" />',
  },
}));

describe('BarChart.vue', () => {
  const data = {
    categories: ['20-May'],
    series: [{ id: 'conversations', data: [3] }],
  };

  it('emits the clicked chart item when clickable', () => {
    const wrapper = shallowMount(BarChart, {
      props: {
        clickable: true,
        data,
        ariaLabel: 'Conversations by day',
      },
    });

    const chart = wrapper.findComponent({ name: 'VizBarChart' });
    chart.props('onItemClick')({ pointIndex: 0 });

    expect(chart.props('data')).toEqual(data);
    expect(chart.props('ariaLabel')).toBe('Conversations by day');
    expect(wrapper.emitted('itemClick')[0][0]).toEqual({ pointIndex: 0 });
  });

  it('does not attach an item handler when chart is not clickable', () => {
    const wrapper = shallowMount(BarChart, {
      props: {
        clickable: false,
        data,
        ariaLabel: 'Conversations by day',
      },
    });

    expect(
      wrapper.findComponent({ name: 'VizBarChart' }).props('onItemClick')
    ).toBeUndefined();
  });
});
