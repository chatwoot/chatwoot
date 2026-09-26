import { mount } from '@vue/test-utils';
import { createI18n } from 'vue-i18n';
import report from 'dashboard/i18n/locale/en/report.json';
import MonitorUsageWarning from '../MonitorUsageWarning.vue';

describe('MonitorUsageWarning', () => {
  const global = {
    plugins: [
      createI18n({ legacy: false, locale: 'en', messages: { en: report } }),
    ],
  };
  const exhausted = {
    limit: 100000,
    used: 100000,
    limit_reached: true,
    limit_reached_at: Date.parse('2026-09-22T12:00:00Z') / 1000,
    resets_at: Date.parse('2026-10-01T00:00:00Z') / 1000,
  };

  it('shows the account limit, hit timestamp, and UTC reset when exhausted', () => {
    const wrapper = mount(MonitorUsageWarning, {
      props: { usage: exhausted },
      global,
    });

    expect(wrapper.get('[role="status"]').text()).toContain(
      '100,000 monitor calls'
    );
    expect(wrapper.text()).toContain('Existing results remain available.');
    expect(wrapper.text()).toContain('Limit reached on');
    expect(wrapper.text()).toContain('UTC');
    wrapper.unmount();
  });

  it('removes the warning when the next monthly allowance becomes available', async () => {
    const wrapper = mount(MonitorUsageWarning, {
      props: { usage: exhausted },
      global,
    });
    await wrapper.setProps({
      usage: {
        ...exhausted,
        used: 0,
        limit_reached: false,
        limit_reached_at: null,
      },
    });

    expect(wrapper.find('[role="status"]').exists()).toBe(false);
    wrapper.unmount();
  });
});
