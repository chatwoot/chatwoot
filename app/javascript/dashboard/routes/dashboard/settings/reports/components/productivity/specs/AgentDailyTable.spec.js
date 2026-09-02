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

  it('scrolls on both axes inside a keyboard-reachable region', () => {
    const region = mountTable().find('[role="region"]');

    expect(region.classes()).toContain('overflow-auto');
    expect(region.classes()).toContain('max-h-[30rem]');
    expect(region.attributes('tabindex')).toBe('0');
  });

  it('pins the header row so it survives a vertical scroll', () => {
    const headers = mountTable().findAll('thead th');

    headers.forEach(header => {
      expect(header.classes()).toContain('sticky');
      expect(header.classes()).toContain('top-0');
    });
  });

  it('pins the agent column and the total column to opposite edges', () => {
    const wrapper = mountTable();
    const row = wrapper.findAll('tbody tr')[0];
    const nameCell = row.find('th');
    const cells = row.findAll('td');
    const totalCell = cells[cells.length - 1];

    expect(nameCell.classes()).toEqual(
      expect.arrayContaining(['sticky', 'start-0'])
    );
    expect(totalCell.classes()).toEqual(
      expect.arrayContaining(['sticky', 'end-0'])
    );
  });

  it('stacks the pinned corners above the pinned edges', () => {
    const headers = mountTable().findAll('thead th');
    const corner = headers[0];
    const dayHeader = headers[1];
    const totalHeader = headers[headers.length - 1];
    const nameCell = mountTable().findAll('tbody tr')[0].find('th');

    // Both-axis corners must outrank the single-axis edges they overlap.
    expect(corner.classes()).toContain('z-30');
    expect(totalHeader.classes()).toContain('z-30');
    expect(dayHeader.classes()).toContain('z-20');
    expect(nameCell.classes()).toContain('z-10');
  });

  it('keeps the whole sticky ladder below the app chrome band', () => {
    // The mobile sidebar drawer is fixed at z-40 and a tie resolves by tree order,
    // where main follows aside — so a z-40 cell here would paint over the drawer.
    const sticky = mountTable()
      .findAll('.sticky')
      .flatMap(cell => cell.classes())
      .filter(name => name.startsWith('z-'));

    expect(sticky.length).toBeGreaterThan(0);
    sticky.forEach(name => {
      expect(Number(name.replace('z-', ''))).toBeLessThan(40);
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
