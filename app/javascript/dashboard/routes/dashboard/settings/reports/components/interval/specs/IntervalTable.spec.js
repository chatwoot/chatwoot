import { mount } from '@vue/test-utils';
import IntervalTable from '../IntervalTable.vue';

vi.mock('vue-i18n', () => ({
  useI18n: () => ({
    t: key => key,
  }),
}));

const bucket = (isoDate, hour, value) => ({
  timestamp:
    Date.parse(`${isoDate}T${String(hour).padStart(2, '0')}:00:00Z`) / 1000,
  value,
});

describe('IntervalTable.vue', () => {
  // 2026-08-01 is a Saturday, 2026-08-02 a Sunday and 2026-08-03 a Monday.
  const intervalData = [
    bucket('2026-08-01', 9, 0),
    bucket('2026-08-02', 9, 4),
    bucket('2026-08-03', 9, 12),
    bucket('2026-08-03', 14, 0),
  ];

  const mountTable = (data = intervalData) =>
    mount(IntervalTable, { props: { intervalData: data } });

  const cellsForHour = (wrapper, hour) =>
    wrapper.findAll('tbody tr')[hour].findAll('td');

  it('always renders all 24 hour rows', () => {
    expect(mountTable().findAll('tbody tr')).toHaveLength(24);
    expect(mountTable([]).findAll('tbody tr')).toHaveLength(24);
  });

  it('renders one column per day, in ascending order', () => {
    const headers = mountTable().findAll('thead th');
    // First header is the hour column.
    expect(headers).toHaveLength(4);
    expect(headers.slice(1).map(th => th.text())).toEqual([
      expect.stringContaining('01/08'),
      expect.stringContaining('02/08'),
      expect.stringContaining('03/08'),
    ]);
  });

  it('renders the count for hours that had conversations', () => {
    const cells = cellsForHour(mountTable(), 9);
    expect(cells[1].text()).toBe('4');
    expect(cells[2].text()).toBe('12');
  });

  it('renders a dot instead of a zero for empty hours', () => {
    const wrapper = mountTable();
    // 09:00 on 01/08 is an explicit zero bucket from the API.
    expect(cellsForHour(wrapper, 9)[0].text()).toBe('·');
    // 03:00 has no bucket at all on any day.
    expect(cellsForHour(wrapper, 3).map(td => td.text())).toEqual([
      '·',
      '·',
      '·',
    ]);
  });

  it('tints cells by intensity and never paints an empty cell', () => {
    const cells = cellsForHour(mountTable(), 9);
    expect(cells[0].classes()).not.toContain('bg-n-blue-3');
    // 4 of a max of 12 lands in the second of five bands.
    expect(cells[1].classes()).toContain('bg-n-blue-5');
    // The maximum lands in the darkest band.
    expect(cells[2].classes()).toContain('bg-n-blue-8');
  });

  it('keeps every painted cell on a background token that works in both themes', () => {
    const painted = mountTable()
      .findAll('td')
      .filter(td => td.classes().some(name => name.startsWith('bg-n-blue-')));

    expect(painted.length).toBeGreaterThan(0);
    painted.forEach(td => {
      // Blue 9 and above invert between light and dark mode, so a printed
      // number on them loses contrast in one of the two themes.
      expect(td.classes()).not.toContain('bg-n-blue-9');
      expect(td.classes()).not.toContain('bg-n-blue-11');
      expect(td.classes()).toContain('text-n-slate-12');
    });
  });

  it('tints weekend columns', () => {
    const cells = cellsForHour(mountTable(), 3);
    expect(cells[0].classes()).toContain('bg-n-slate-2');
    expect(cells[1].classes()).toContain('bg-n-slate-2');
    expect(cells[2].classes()).not.toContain('bg-n-slate-2');
  });
});
