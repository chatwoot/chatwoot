import { shallowMount } from '@vue/test-utils';
import MonitorChartFilters from '../MonitorChartFilters.vue';

vi.mock('vue-i18n', async importOriginal => ({
  ...(await importOriginal()),
  useI18n: () => ({ t: (key, params) => `${key}:${params?.count ?? ''}` }),
}));

const mountFilters = (props = {}) =>
  shallowMount(MonitorChartFilters, {
    props: { modelValue: { range: 7, interval: 'day' }, ...props },
  });

describe('MonitorChartFilters', () => {
  it('offers the preset ranges and emits the selected days as a number', () => {
    const wrapper = mountFilters();
    const [range] = wrapper.findAllComponents({ name: 'SelectMenu' });

    expect(range.props('options').map(option => option.value)).toEqual([
      '7',
      '15',
      '30',
    ]);
    range.vm.$emit('update:modelValue', '15');

    expect(wrapper.emitted('update:modelValue')).toEqual([
      [{ range: 15, interval: 'day' }],
    ]);
  });

  it('keeps the range when the grouping changes', () => {
    const wrapper = mountFilters();
    const [, interval] = wrapper.findAllComponents({ name: 'SelectMenu' });

    interval.vm.$emit('update:modelValue', 'hour');

    expect(wrapper.emitted('update:modelValue')).toEqual([
      [{ range: 7, interval: 'hour' }],
    ]);
  });

  it('labels the ranges relative to the pause for a paused monitor', () => {
    const wrapper = mountFilters({ pausedAt: 1790000000 });
    const [range] = wrapper.findAllComponents({ name: 'SelectMenu' });

    expect(range.props('label')).toBe('MONITORS.LAST_DAYS_BEFORE_PAUSE:7');
    expect(range.props('options')[2].label).toBe(
      'MONITORS.LAST_DAYS_BEFORE_PAUSE:30'
    );
  });
});
