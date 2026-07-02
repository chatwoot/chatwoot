import { flushPromises, mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { formatTime } from '@chatwoot/utils';
import ReportsAPI from 'dashboard/api/reports';
import ReportDrilldownDrawer from '../ReportDrilldownDrawer.vue';

vi.mock('dashboard/api/reports', () => ({
  default: {
    getDrilldown: vi.fn(),
  },
}));

vi.mock('vue-i18n', () => ({
  useI18n: () => ({
    t: (key, params = {}) => {
      if (key === 'REPORT.DRILLDOWN.TITLE') {
        return `${params.metric} details`;
      }
      if (key === 'REPORT.DRILLDOWN.RESULT_COUNT_MESSAGE') {
        return `${params.count} messages`;
      }
      if (key === 'REPORT.DRILLDOWN.RESULT_COUNT_CONVERSATION') {
        return `${params.count} conversations`;
      }
      return key;
    },
  }),
}));

describe('ReportDrilldownDrawer.vue', () => {
  const request = {
    metric: 'incoming_messages_count',
    metricName: 'Messages received',
    bucketLabel: '20-May',
    bucketTimestamp: 1621103400,
    from: 1621103400,
    to: 1621621800,
    type: 'account',
    groupBy: 'day',
    businessHours: false,
  };

  const payload = [
    {
      record_type: 'message',
      conversation: {
        id: 10,
        display_id: 42,
        contact_id: 11,
        contact_name: 'Jane',
        inbox_id: 12,
        inbox_name: 'Website',
        assignee_id: 13,
        assignee_name: 'Alex',
        status: 'open',
        created_at: 1621103400,
        last_activity_at: 1621103700,
        last_message: {
          id: 100,
          content: 'Latest reply',
          message_type: 'outgoing',
          created_at: 1621103600,
        },
      },
      message: {
        id: 99,
        content: 'Need help',
        message_type: 'incoming',
        created_at: 1621103500,
      },
      metric_value: null,
      occurred_at: 1621103500,
    },
  ];

  const mountDrawer = options =>
    mount(ReportDrilldownDrawer, {
      props: { open: true, ...request, ...options?.props },
      attachTo: options?.attachTo,
      global: {
        stubs: {
          Teleport: true,
          Transition: false,
          Spinner: true,
          Button: {
            props: ['label'],
            template:
              '<button @click="$emit(\'click\')">{{ label }}<slot /></button>',
          },
          ReportDrilldownCard: {
            props: ['record'],
            template:
              '<div data-testid="drilldown-card">#{{ record.conversation.display_id }}</div>',
          },
        },
        mocks: {
          $t: key => key,
        },
      },
    });

  beforeEach(() => {
    ReportsAPI.getDrilldown.mockResolvedValue({
      data: {
        meta: {
          total_count: 1,
          current_page: 1,
          record_type: 'message',
        },
        payload,
      },
    });
  });

  afterEach(() => {
    vi.clearAllMocks();
    vi.restoreAllMocks();
  });

  it('loads and renders drilldown cards for the request', async () => {
    const wrapper = mountDrawer();
    await flushPromises();

    expect(ReportsAPI.getDrilldown).toHaveBeenCalledWith(
      expect.objectContaining({
        metric: 'incoming_messages_count',
        bucketTimestamp: 1621103400,
        page: 1,
      })
    );
    expect(wrapper.text()).toContain('Messages received');
    expect(wrapper.text()).toContain('1 messages');
    expect(wrapper.find('[data-testid="drilldown-card"]').text()).toBe('#42');
  });

  it('shows the bucket aggregate value for average metrics', async () => {
    const wrapper = mountDrawer({
      props: {
        metric: 'avg_first_response_time',
        metricName: 'First response time',
        isAverageMetric: true,
        bucketValue: 2580,
      },
    });
    await flushPromises();

    expect(wrapper.text()).toContain(formatTime(2580));
  });

  it('does not show a bucket value for count metrics', async () => {
    const wrapper = mountDrawer({ props: { bucketValue: 12 } });
    await flushPromises();

    expect(wrapper.text()).not.toContain(formatTime(12));
  });

  it('emits close when the drawer close button is clicked', async () => {
    const wrapper = mountDrawer();
    await flushPromises();

    await wrapper.find('button').trigger('click');

    expect(wrapper.emitted('close')).toBeTruthy();
  });

  it('moves focus into the drawer when opened', async () => {
    const target = document.createElement('div');
    document.body.appendChild(target);
    const wrapper = mountDrawer({ attachTo: target });
    await flushPromises();
    await nextTick();

    expect(document.activeElement).toBe(
      wrapper.find('[role="dialog"]').element
    );

    wrapper.unmount();
    target.remove();
  });

  it('closes on Escape even when focus is outside the drawer', async () => {
    const target = document.createElement('div');
    document.body.appendChild(target);
    const wrapper = mountDrawer({ attachTo: target });
    await flushPromises();

    document.body.focus();
    document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape' }));

    expect(wrapper.emitted('close')).toBeTruthy();

    wrapper.unmount();
    target.remove();
  });

  it('restores focus to the previously focused element when closed', async () => {
    const opener = document.createElement('button');
    const target = document.createElement('div');
    document.body.appendChild(opener);
    document.body.appendChild(target);
    opener.focus();

    const wrapper = mountDrawer({ attachTo: target });
    await flushPromises();
    await nextTick();

    await wrapper.find('button').trigger('click');

    expect(document.activeElement).toBe(opener);

    wrapper.unmount();
    target.remove();
    opener.remove();
  });
});
