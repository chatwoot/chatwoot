import { mount } from '@vue/test-utils';
import AgentRankingTable from '../AgentRankingTable.vue';

vi.mock('vue-i18n', () => ({
  useI18n: () => ({
    t: key => key,
  }),
}));

describe('AgentRankingTable.vue', () => {
  const rows = [
    {
      id: 1,
      name: 'Alice',
      conversationsCount: 12,
      resolvedCount: 10,
    },
    { id: 2, name: 'Bob', conversationsCount: 8, resolvedCount: 5 },
    { id: 3, name: 'Zoe', conversationsCount: 0, resolvedCount: 0 },
  ];

  const mountTable = (tableRows = rows) =>
    mount(AgentRankingTable, { props: { rows: tableRows } });

  it('renders rows in the given order with one-based ranks', () => {
    const renderedRows = mountTable().findAll('tbody tr');

    expect(renderedRows.map(row => row.find('th').text())).toEqual([
      '1',
      '2',
      '3',
    ]);
    expect(renderedRows.map(row => row.findAll('td')[0].text())).toEqual([
      'Alice',
      'Bob',
      'Zoe',
    ]);
  });

  it('sizes bars relative to the largest resolved count', () => {
    const bars = mountTable().findAll('[data-testid="agent-ranking-bar"]');

    expect(bars[0].attributes('style')).toContain('width: 100%');
    expect(bars[1].attributes('style')).toContain('width: 50%');
  });

  it('renders a zero row with a zero-percent bar', () => {
    const zeroBar = mountTable().findAll(
      '[data-testid="agent-ranking-bar"]'
    )[2];

    expect(zeroBar.attributes('style')).toContain('width: 0%');
  });

  it('renders an empty state when there are no rows', () => {
    const wrapper = mountTable([]);

    expect(wrapper.findAll('tbody tr')).toHaveLength(1);
    expect(wrapper.find('tbody').text()).toContain(
      'OVERVIEW_REPORTS.AGENT_RANKING.NO_AGENTS'
    );
  });
});
