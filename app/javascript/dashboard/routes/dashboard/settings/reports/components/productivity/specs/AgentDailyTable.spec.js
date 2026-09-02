import { mount } from '@vue/test-utils';
import AgentDailyTable from '../AgentDailyTable.vue';

vi.mock('vue-i18n', () => ({
  useI18n: () => ({
    t: key => key,
  }),
}));

describe('AgentDailyTable.vue', () => {
  const agents = [
    { id: 1, name: 'Alice', total: 5 },
    { id: 2, name: 'Bob', total: 4 },
  ];
  const days = ['2026-08-01', '2026-08-02', '2026-08-03'];
  const matrix = [
    [0, 2, 3],
    [4, 0, 0],
  ];

  const mountTable = (props = {}) =>
    mount(AgentDailyTable, {
      props: { agents, days, matrix, ...props },
    });

  it('renders one row per agent and one column per day plus total', () => {
    const wrapper = mountTable();

    expect(wrapper.findAll('tbody tr')).toHaveLength(2);
    expect(wrapper.findAll('thead th')).toHaveLength(days.length + 2);
    expect(wrapper.findAll('tbody tr')[0].findAll('td')).toHaveLength(
      days.length + 1
    );
  });

  it('renders a dot for zero cells', () => {
    const cells = mountTable().findAll('tbody tr')[0].findAll('td');

    expect(cells[0].text()).toBe('·');
    expect(cells[1].text()).toBe('2');
  });

  it('shows the row total without an intensity background', () => {
    const totalCell = mountTable().findAll('tbody tr')[0].findAll('td').at(-1);

    expect(totalCell.text()).toBe('5');
    expect(
      totalCell.classes().some(name => name.startsWith('bg-n-blue-'))
    ).toBe(false);
  });

  it('tints weekend headers and empty weekend cells', () => {
    const wrapper = mountTable();
    const dayHeaders = wrapper.findAll('thead th').slice(1, -1);
    const firstRowCells = wrapper.findAll('tbody tr')[0].findAll('td');

    expect(dayHeaders[0].classes()).toContain('bg-n-slate-2');
    expect(dayHeaders[1].classes()).toContain('bg-n-slate-2');
    expect(dayHeaders[2].classes()).not.toContain('bg-n-slate-2');
    expect(firstRowCells[0].classes()).toContain('bg-n-slate-2');
  });

  it('uses only intensity tokens that keep contrast in both themes', () => {
    const painted = mountTable()
      .findAll('td')
      .filter(td => td.classes().some(name => name.startsWith('bg-n-blue-')));

    expect(painted.length).toBeGreaterThan(0);
    painted.forEach(td => {
      expect(td.classes()).not.toContain('bg-n-blue-9');
      expect(td.classes()).not.toContain('bg-n-blue-11');
      expect(td.classes()).toContain('text-n-slate-12');
    });
  });

  it('renders an empty state when there are no agents', () => {
    const wrapper = mountTable({ agents: [], matrix: [] });

    expect(wrapper.findAll('tbody tr')).toHaveLength(1);
    expect(wrapper.find('tbody').text()).toContain(
      'OVERVIEW_REPORTS.AGENT_DAILY.NO_AGENTS'
    );
  });
});
