import { shallowMount } from '@vue/test-utils';
import ReportMetricCard from '../ReportMetricCard.vue';

describe('ReportMetricCard.vue', () => {
  const globalConfig = {
    global: {
      stubs: {
        'fluent-icon': true, // Replace FluentIcon with a stub
      },
    },
  };

  it('renders props correctly', () => {
    const label = 'Total Responses';
    const value = '100';
    const infoText = 'Total number of responses';
    const wrapper = shallowMount(ReportMetricCard, {
      props: { label, value, infoText },
      ...globalConfig,
    });

    expect(wrapper.find('[data-test-id="reportMetricLabel"]').text()).toMatch(
      label
    );
    expect(wrapper.find('[data-test-id="reportMetricValue"]').text()).toMatch(
      value
    );
  });

  it('adds disabled class when disabled prop is true', () => {
    const wrapper = shallowMount(ReportMetricCard, {
      props: { label: '', value: '', infoText: '', disabled: true },
      ...globalConfig,
    });

    expect(wrapper.classes().join(' ')).toContain(
      'grayscale pointer-events-none opacity-30'
    );
  });

  it('does not add disabled class when disabled prop is false', () => {
    const wrapper = shallowMount(ReportMetricCard, {
      props: { label: '', value: '', infoText: '', disabled: false },
      ...globalConfig,
    });

    expect(
      wrapper.find('[data-test-id="reportMetricContainer"]').classes().join(' ')
    ).not.toContain('grayscale pointer-events-none opacity-30');
  });
});
