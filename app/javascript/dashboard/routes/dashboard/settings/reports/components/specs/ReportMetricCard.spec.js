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

    expect(wrapper.find('.heading span').text()).toMatch(label);
    expect(wrapper.find('.metric').text()).toMatch(value);
    expect(wrapper.find('.report-metric--icon').classes()).toContain(
      'has-tooltip'
    );
  });

  it('adds disabled class when disabled prop is true', () => {
    const wrapper = shallowMount(ReportMetricCard, {
      propsData: { label: '', value: '', infoText: '', disabled: true },
      localVue,
      stubs: ['fluent-icon'],
    });

    expect(wrapper.find('.report--metric-card').classes()).toContain(
      'disabled'
    );
  });

  it('does not add disabled class when disabled prop is false', () => {
    const wrapper = shallowMount(ReportMetricCard, {
      propsData: { label: '', value: '', infoText: '', disabled: false },
      localVue,
      stubs: ['fluent-icon'],
    });

    expect(wrapper.find('.report--metric-card').classes()).not.toContain(
      'disabled'
    );
  });
});
