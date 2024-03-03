import { createLocalVue, shallowMount } from '@vue/test-utils';
import ReportMetricCard from '../ReportMetricCard.vue';

import VTooltip from 'v-tooltip';

const localVue = createLocalVue();
localVue.use(VTooltip);

describe('ReportMetricCard.vue', () => {
  it('renders props correctly', () => {
    const label = 'Total Responses';
    const value = '100';
    const infoText = 'Total number of responses';
    const wrapper = shallowMount(ReportMetricCard, {
      propsData: { label, value, infoText },
      localVue,
      stubs: ['fluent-icon'],
    });

    expect(wrapper.find({ ref: 'reportMetricLabel' }).text()).toMatch(label);
    expect(wrapper.find({ ref: 'reportMetricValue' }).text()).toMatch(value);
    expect(wrapper.find({ ref: 'reportMetricInfo' }).classes()).toContain(
      'has-tooltip'
    );
  });

  it('adds disabled class when disabled prop is true', () => {
    const wrapper = shallowMount(ReportMetricCard, {
      propsData: { label: '', value: '', infoText: '', disabled: true },
      localVue,
      stubs: ['fluent-icon'],
    });

    expect(wrapper.classes().join(' ')).toContain(
      'grayscale pointer-events-none opacity-30'
    );
  });

  it('does not add disabled class when disabled prop is false', () => {
    const wrapper = shallowMount(ReportMetricCard, {
      propsData: { label: '', value: '', infoText: '', disabled: false },
      localVue,
      stubs: ['fluent-icon'],
    });

    expect(
      wrapper.find({ ref: 'reportMetricContainer' }).classes().join(' ')
    ).not.toContain('grayscale pointer-events-none opacity-30');
  });
});
