import { shallowMount } from '@vue/test-utils';
import BarChart from '../charts/BarChart.vue';

vi.mock('vue-chartjs', () => ({
  Bar: {
    name: 'Bar',
    props: ['data', 'options'],
    template: '<canvas />',
  },
}));

describe('BarChart.vue', () => {
  it('emits the clicked chart element when clickable', () => {
    const wrapper = shallowMount(BarChart, {
      props: {
        clickable: true,
        collection: {
          labels: ['20-May'],
          datasets: [{ type: 'bar', data: [3] }],
        },
      },
    });

    const options = wrapper.findComponent({ name: 'Bar' }).props('options');
    options.onClick({}, [{ datasetIndex: 0, index: 0 }], {});

    expect(wrapper.emitted('elementClick')[0][0]).toEqual({
      datasetIndex: 0,
      dataIndex: 0,
      dataset: { type: 'bar', data: [3] },
      label: '20-May',
      value: 3,
    });
  });

  it('does not emit when chart is not clickable', () => {
    const wrapper = shallowMount(BarChart, {
      props: {
        clickable: false,
        collection: {
          labels: ['20-May'],
          datasets: [{ type: 'bar', data: [3] }],
        },
      },
    });

    const options = wrapper.findComponent({ name: 'Bar' }).props('options');
    options.onClick({}, [{ datasetIndex: 0, index: 0 }], {});

    expect(wrapper.emitted('elementClick')).toBeUndefined();
  });
});
