import { flushPromises, mount } from '@vue/test-utils';
import { ref } from 'vue';
import SummaryReportsAPI from 'dashboard/api/summaryReports';
import SummaryReports from '../SummaryReports.vue';

const agents = [
  { id: 3, name: 'Carol' },
  { id: 1, name: 'alice' },
  { id: 4, name: 'Dave' },
  { id: 2, name: 'Bob' },
];

// Bob replies fastest and takes the fewest; Dave has no activity at all. The
// durations arrive as strings on purpose: they are floats over the wire today,
// and sorting must not depend on that.
const metrics = [
  { id: 1, conversationsCount: 9, avgFirstResponseTime: '600.0' },
  { id: 2, conversationsCount: 10, avgFirstResponseTime: '120.0' },
  { id: 3, conversationsCount: 2, avgFirstResponseTime: '3600.0' },
  { id: 4 },
];

vi.mock('dashboard/composables/store', () => ({
  useStore: () => ({ dispatch: vi.fn(), getters: {} }),
  useMapGetter: key => {
    if (key[0] === 'agents/getAgents') return ref(agents);
    if (key[0] === 'summaryReports/getAgentSummaryReports') return ref(metrics);
    return ref({});
  },
}));

vi.mock('dashboard/api/summaryReports', () => ({
  default: { getHandledConversations: vi.fn().mockResolvedValue({ data: {} }) },
}));

vi.mock('vue-i18n', () => ({
  useI18n: () => ({ t: key => key }),
}));

const mountReports = () =>
  mount(SummaryReports, {
    props: {
      type: 'agent',
      getterKey: 'agents/getAgents',
      actionKey: 'summaryReports/fetchAgentSummaryReports',
      fetchItemsKey: 'agents/get',
      summaryKey: 'summaryReports/getAgentSummaryReports',
    },
    global: {
      stubs: {
        OverviewReportFilters: true,
        SummaryDistribution: true,
        SummaryReportLink: {
          props: ['row'],
          template: '<span>{{ row.original.name }}</span>',
        },
        Spinner: true,
      },
      mocks: { $t: key => key },
    },
  });

// Resolved, handled and assigned come first, the durations after them.
const ASSIGNED = 3;
const FIRST_RESPONSE = 4;

const columnOf = (wrapper, index) =>
  wrapper.findAll('tbody tr').map(row => row.findAll('td')[index].text());

const sortBy = (wrapper, headerIndex) =>
  wrapper.findAll('th')[headerIndex].find('button').trigger('click');

describe('SummaryReports.vue', () => {
  it('sorts a count column by its number, not by the formatted string', async () => {
    const wrapper = mountReports();
    await sortBy(wrapper, ASSIGNED);

    // 10 above 9 is the whole point: as strings they sort the other way round.
    expect(columnOf(wrapper, ASSIGNED)).toEqual(['10', '9', '2', '--']);
  });

  it('sorts a duration column by its seconds, even when they arrive as strings', async () => {
    const wrapper = mountReports();
    await sortBy(wrapper, FIRST_RESPONSE);

    expect(columnOf(wrapper, 0)).toEqual(['Carol', 'alice', 'Bob', 'Dave']);
  });

  it('sorts names case-insensitively, whatever the size of the roster', async () => {
    // TanStack 8.20.5 infers the comparator from `flatRows.slice(10)`, which is
    // empty here and falls back to a case-sensitive compare that would put every
    // capitalised name above `alice`.
    const wrapper = mountReports();
    await sortBy(wrapper, 0);

    expect(columnOf(wrapper, 0)).toEqual(['alice', 'Bob', 'Carol', 'Dave']);
  });

  it('exposes each sortable header as a button, so it works without a pointer', async () => {
    const wrapper = mountReports();
    const header = wrapper.findAll('th')[1];

    expect(header.find('button').exists()).toBe(true);
    expect(header.attributes('aria-sort')).toBe('none');

    await header.find('button').trigger('click');
    expect(wrapper.findAll('th')[1].attributes('aria-sort')).toBe('descending');
  });

  it('keeps rows with no measurement at the bottom in both directions', async () => {
    const wrapper = mountReports();

    await sortBy(wrapper, FIRST_RESPONSE);
    expect(columnOf(wrapper, 0).at(-1)).toBe('Dave');

    await sortBy(wrapper, FIRST_RESPONSE);
    expect(columnOf(wrapper, 0)).toEqual(['Bob', 'alice', 'Carol', 'Dave']);
  });

  it('names the conversations column after the assignment and explains it', () => {
    const header = mountReports().findAll('th')[ASSIGNED];

    expect(header.text()).toContain('SUMMARY_REPORTS.ASSIGNED');
    expect(header.find('[title]').attributes('title')).toBe(
      'REPORT.METRIC_HINTS.ASSIGNED_AGENT'
    );
  });

  it('never lets a superseded period overwrite the handled total', async () => {
    // Each request settles only when the spec says so, and rejects the way axios
    // does once its signal is aborted.
    const pending = [];
    SummaryReportsAPI.getHandledConversations.mockImplementation(
      ({ signal }) =>
        new Promise((resolve, reject) => {
          signal?.addEventListener('abort', () =>
            reject(
              Object.assign(new Error('canceled'), { name: 'CanceledError' })
            )
          );
          pending.push(resolve);
        })
    );
    const wrapper = mountReports();
    const filters = wrapper.findComponent({ name: 'OverviewReportFilters' });

    filters.vm.$emit('filterChange', { from: 1, to: 2, businessHours: false });
    filters.vm.$emit('filterChange', { from: 3, to: 4, businessHours: false });
    pending.at(-1)({ data: { count: 7 } });
    pending.at(-2)({ data: { count: 99 } });
    await flushPromises();

    const distribution = wrapper.findComponent({ name: 'SummaryDistribution' });
    expect(distribution.props('handledTotal')).toBe(7);
  });
});
