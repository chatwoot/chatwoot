import { mount } from '@vue/test-utils';
import { createI18n } from 'vue-i18n';
import SummaryDistribution from '../SummaryDistribution.vue';

const push = vi.fn();

vi.mock('vue-router', () => ({
  useRouter: () => ({ push }),
}));

const buildI18n = () =>
  createI18n({
    legacy: false,
    locale: 'en',
    messages: {
      en: {
        REPORT: {
          DISTRIBUTION: {
            TITLE: {
              AGENT: 'Distribution by agent',
              INBOX: 'Distribution by inbox',
            },
            METRIC: {
              RESOLUTIONS: 'Resolved',
              HANDLED: 'Handled',
              ASSIGNED: 'Assigned',
              OPENED: 'Opened',
            },
            OTHERS: 'Others ({count})',
            EMPTY_METRIC: 'Not enough data to compare on this metric.',
            HANDLED_SHARE: 'Shares can add up to more than 100%.',
          },
          METRIC_HINTS: {
            RESOLVED_AGENT: 'Credited to the assignee.',
            RESOLVED: 'Resolutions in the period.',
            HANDLED_AGENT: 'The agent sent a public message.',
            HANDLED: 'An agent sent a public message.',
            ASSIGNED_AGENT: 'Assigned to the agent today.',
            ASSIGNED_TEAM: 'Assigned to the team today.',
            OPENED: 'Opened in the period.',
          },
        },
      },
    },
  });

const buildRows = (count, value) =>
  Array.from({ length: count }, (_, index) => ({
    id: index + 1,
    name: `Agent ${index + 1}`,
    resolvedConversationsCount: value ?? count - index,
    conversationsCount: 1,
  }));

const mountComponent = (props = {}) =>
  mount(SummaryDistribution, {
    props: { type: 'agent', rows: buildRows(3), ...props },
    global: {
      plugins: [buildI18n()],
      stubs: { TabBar: true },
    },
  });

// Name, count and share; the second cell is the bar track and carries no text.
const rowsOf = wrapper =>
  wrapper.findAll('li').map(row => {
    const [name, , count, share] = [...row.element.firstElementChild.children];
    return [name, count, share].map(cell => cell.textContent.trim()).join(' ');
  });

const barWidthsOf = wrapper =>
  wrapper
    .findAll('li span[style]')
    .map(bar => Number.parseFloat(bar.attributes('style').match(/[\d.]+/)[0]));

describe('SummaryDistribution.vue', () => {
  beforeEach(() => push.mockClear());

  it('ranks rows by the active metric and shows each share of the total', () => {
    const wrapper = mountComponent({
      rows: [
        { id: 1, name: 'Alice', resolvedConversationsCount: 20 },
        { id: 2, name: 'Bob', resolvedConversationsCount: 60 },
        { id: 3, name: 'Carol', resolvedConversationsCount: 20 },
      ],
    });

    expect(rowsOf(wrapper)).toEqual([
      'Bob 60 60%',
      'Alice 20 20%',
      'Carol 20 20%',
    ]);
  });

  it('leaves out rows the period has nothing for', () => {
    const wrapper = mountComponent({
      rows: [
        { id: 1, name: 'Alice', resolvedConversationsCount: 5 },
        { id: 2, name: 'Bob', resolvedConversationsCount: 0 },
        { id: 3, name: 'Carol', resolvedConversationsCount: undefined },
        { id: 4, name: 'Dave', resolvedConversationsCount: 5 },
      ],
    });

    expect(rowsOf(wrapper)).toEqual(['Alice 5 50%', 'Dave 5 50%']);
  });

  it('aggregates everything past the tenth row into a single tail row', () => {
    const wrapper = mountComponent({ rows: buildRows(13) });
    const rows = rowsOf(wrapper);

    // 13 down to 4 stay named, 3 + 2 + 1 land in the tail.
    expect(rows).toHaveLength(11);
    expect(rows.at(-1)).toBe('Others (3) 6 6.6%');
  });

  it('keeps the tail bar inside the track when it outgrows the biggest row', () => {
    // Twelve rows of ten: the two-row tail is worth twice the biggest one.
    const widths = barWidthsOf(mountComponent({ rows: buildRows(12, 10) }));

    expect(widths.at(-1)).toBe(100);
    expect(Math.max(...widths.slice(0, -1))).toBe(50);
  });

  it('renders nothing until there are two rows to compare', () => {
    const wrapper = mountComponent({
      rows: [{ id: 1, name: 'Alice', resolvedConversationsCount: 9 }],
    });

    expect(wrapper.find('h3').exists()).toBe(false);
  });

  it('keeps the card up for a metric with no activity, so the tabs survive', () => {
    // Two agents resolved conversations, neither replied to one.
    const wrapper = mountComponent({
      rows: [
        {
          id: 1,
          name: 'Alice',
          resolvedConversationsCount: 5,
          handledConversationsCount: 0,
        },
        {
          id: 2,
          name: 'Bob',
          resolvedConversationsCount: 3,
          handledConversationsCount: 0,
        },
      ],
    });
    // Switch to the empty metric the way the tab bar does.
    wrapper
      .findComponent({ name: 'TabBar' })
      .vm.$emit('tabChanged', { index: 1 });

    return wrapper.vm.$nextTick().then(() => {
      expect(wrapper.find('h3').exists()).toBe(true);
      expect(wrapper.text()).toContain('Not enough data to compare');
      expect(wrapper.findAll('li')).toHaveLength(0);
    });
  });

  it('opens the report of the row that was clicked', async () => {
    const wrapper = mountComponent();
    await wrapper.findAll('li button')[0].trigger('click');

    expect(push).toHaveBeenCalledWith({
      name: 'agent_reports_show',
      params: { id: 1 },
    });
  });

  it('does not link the aggregated tail anywhere', () => {
    const wrapper = mountComponent({ rows: buildRows(13) });

    expect(wrapper.findAll('li button')).toHaveLength(10);
  });

  it('explains the active metric for the dimension being read', async () => {
    const wrapper = mountComponent();
    expect(wrapper.text()).toContain('Credited to the assignee.');

    const tabBar = wrapper.findComponent({ name: 'TabBar' });
    tabBar.vm.$emit('tabChanged', { index: 2 });
    await wrapper.vm.$nextTick();
    expect(wrapper.text()).toContain('Assigned to the agent today.');

    const inbox = mountComponent({ type: 'inbox' });
    inbox
      .findComponent({ name: 'TabBar' })
      .vm.$emit('tabChanged', { index: 2 });
    await inbox.vm.$nextTick();
    expect(inbox.text()).toContain('Opened in the period.');
  });

  it('shares handled conversations out of the distinct total, not the sum of the rows', async () => {
    // Alice and Bob both replied to 2 of the 8 handled conversations.
    const wrapper = mountComponent({
      handledTotal: 8,
      rows: [
        { id: 1, name: 'Alice', handledConversationsCount: 6 },
        { id: 2, name: 'Bob', handledConversationsCount: 4 },
      ],
    });
    wrapper
      .findComponent({ name: 'TabBar' })
      .vm.$emit('tabChanged', { index: 1 });
    await wrapper.vm.$nextTick();

    expect(wrapper.text()).toContain('Shares can add up to more than 100%.');
    expect(rowsOf(wrapper)).toEqual(['Alice 6 75%', 'Bob 4 50%']);
  });

  it('keeps sharing out of the sum where rows cannot overlap', async () => {
    const wrapper = mountComponent({
      type: 'inbox',
      handledTotal: 8,
      rows: [
        { id: 1, name: 'Sales', handledConversationsCount: 6 },
        { id: 2, name: 'Support', handledConversationsCount: 4 },
      ],
    });
    wrapper
      .findComponent({ name: 'TabBar' })
      .vm.$emit('tabChanged', { index: 1 });
    await wrapper.vm.$nextTick();

    expect(rowsOf(wrapper)).toEqual(['Sales 6 60%', 'Support 4 40%']);
  });
});
