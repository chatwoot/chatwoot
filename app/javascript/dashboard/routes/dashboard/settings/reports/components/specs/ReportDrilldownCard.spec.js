import { mount } from '@vue/test-utils';
import ReportDrilldownCard from '../ReportDrilldownCard.vue';

vi.mock('vue-router', () => ({
  useRoute: () => ({
    params: {
      accountId: 1,
    },
  }),
}));

vi.mock('vue-i18n', () => ({
  useI18n: () => ({
    t: (key, params = {}) => {
      if (key === 'REPORT.DRILLDOWN.MESSAGE_CREATED_AT') {
        return `Message created at ${params.time}`;
      }
      if (key === 'REPORT.DRILLDOWN.EVENT_OCCURRED_AT') {
        return `Event occurred at ${params.time}`;
      }
      if (key === 'REPORT.DRILLDOWN.INCOMING_MESSAGE') {
        return 'Incoming message';
      }
      if (key === 'REPORT.DRILLDOWN.OUTGOING_MESSAGE') {
        return 'Outgoing message';
      }
      return key;
    },
  }),
}));

vi.mock('shared/helpers/timeHelper', () => ({
  dynamicTime: timestamp => {
    const timestamps = {
      1621103500: '2 minutes ago',
      1621103400: '4 days ago',
      1621103700: '4 days ago',
    };
    return timestamps[timestamp] || 'less than a minute ago';
  },
  shortTimestamp: time => {
    const timestamps = {
      '2 minutes ago': '2m',
      '4 days ago': '4d',
    };
    return timestamps[time] || 'now';
  },
  dateFormat: timestamp => `date-${timestamp}`,
}));

describe('ReportDrilldownCard.vue', () => {
  const record = {
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
  };

  const mountCard = (props = {}) =>
    mount(ReportDrilldownCard, {
      props: {
        record,
        ...props,
      },
      global: {
        mocks: {
          $t: key => key,
        },
      },
    });

  beforeEach(() => {
    vi.spyOn(window, 'open').mockImplementation(() => {});
  });

  afterEach(() => {
    vi.clearAllMocks();
    vi.restoreAllMocks();
  });

  it('opens the card conversation link in a new tab', async () => {
    const wrapper = mountCard();

    expect(wrapper.text()).toContain('#42');
    expect(wrapper.text()).toContain('Need help');
    expect(wrapper.find('.i-lucide-arrow-down-left').exists()).toBe(true);
    expect(wrapper.find('[aria-label="Incoming message"]').exists()).toBe(true);

    await wrapper.find('[role="link"]').trigger('click');

    expect(window.open).toHaveBeenCalledWith(
      '/app/accounts/1/conversations/42?messageId=99',
      '_blank',
      'noopener,noreferrer'
    );
  });

  it('renders only message created timestamp for message rows', () => {
    const wrapper = mountCard();
    const messageCreatedLabel = wrapper
      .findAll('[aria-label]')
      .map(timestamp => timestamp.attributes('aria-label'))
      .find(label => label.includes('Message created at'));

    expect(wrapper.text()).toContain('2m');
    expect(wrapper.text()).not.toContain('4d • 4d');
    expect(messageCreatedLabel).toContain('Message created at');
  });

  it('renders separate contact, inbox, and agent links', async () => {
    const wrapper = mountCard();
    const links = wrapper.findAll('a');

    expect(links.map(link => link.attributes('href'))).toEqual([
      '/app/accounts/1/contacts/11',
      '/app/accounts/1/inbox/12',
      '/app/accounts/1/reports/agents/13',
    ]);
    expect(links.every(link => link.attributes('target') === '_blank')).toBe(
      true
    );
    expect(
      links.every(link => link.classes().includes('text-n-slate-10'))
    ).toBe(true);
    expect(
      links.every(link => !link.classes().includes('text-n-blue-11'))
    ).toBe(true);
    expect(wrapper.find('.i-lucide-contact').exists()).toBe(true);
    expect(wrapper.find('.i-lucide-inbox').exists()).toBe(true);
    expect(wrapper.find('.i-lucide-user-round').exists()).toBe(true);

    await links[0].trigger('click');

    expect(window.open).not.toHaveBeenCalled();
  });

  it('renders the last message for conversation rows', () => {
    const wrapper = mountCard({
      record: {
        ...record,
        record_type: 'conversation',
        message: null,
        occurred_at: 1621103500,
      },
    });

    expect(wrapper.text()).toContain('Latest reply');
    expect(wrapper.text()).toContain('4d • 4d');
  });

  it('renders event time alongside TimeAgo for event-backed conversation rows', () => {
    const wrapper = mountCard({
      record: {
        ...record,
        record_type: 'conversation',
        message: null,
        event_name: 'conversation_bot_handoff',
        occurred_at: 1621103500,
      },
    });
    const eventOccurredLabel = wrapper
      .findAll('[aria-label]')
      .map(timestamp => timestamp.attributes('aria-label'))
      .find(label => label.includes('Event occurred at'));

    expect(wrapper.text()).toContain('Latest reply');
    expect(wrapper.text()).toContain('4d • 4d');
    expect(wrapper.text()).toContain('2m');
    expect(eventOccurredLabel).toContain('Event occurred at');
  });
});
