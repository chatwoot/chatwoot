import { shallowMount } from '@vue/test-utils';
import { useAlert } from 'dashboard/composables';
import ReportContainer from '../ReportContainer.vue';

vi.mock('dashboard/composables', () => ({
  useAlert: vi.fn(),
}));

vi.mock('dashboard/composables/useReportMetrics', () => ({
  useReportMetrics: () => ({
    calculateTrend: () => 0,
    isAverageMetricType: key =>
      ['avg_first_response_time', 'avg_resolution_time', 'reply_time'].includes(
        key
      ),
  }),
}));

describe('ReportContainer.vue', () => {
  const mountComponent = ({
    dataPoint = { value: 2, timestamp: 1621103400 },
    data,
    reportKey = 'conversations_count',
    role = 'administrator',
  } = {}) =>
    shallowMount(ReportContainer, {
      props: {
        from: 1621103400,
        to: 1621621800,
        groupBy: { period: 'day' },
        reportType: 'inbox',
        selectedItemId: 1,
        businessHours: true,
        reportKeys: {
          CONVERSATIONS: reportKey,
        },
      },
      global: {
        mocks: {
          $t: key => key,
          $store: {
            getters: {
              getAccountReports: {
                isFetching: {
                  [reportKey]: false,
                },
                data: {
                  [reportKey]: data || [dataPoint],
                },
              },
              getCurrentRole: role,
            },
          },
        },
        stubs: {
          ChartStats: true,
          ReportDrilldownDrawer: {
            name: 'ReportDrilldownDrawer',
            props: [
              'open',
              'metric',
              'metricName',
              'bucketLabel',
              'bucketTimestamp',
              'bucketValue',
              'isAverageMetric',
              'from',
              'to',
              'type',
              'id',
              'groupBy',
              'businessHours',
              'canPrev',
              'canNext',
            ],
            emits: ['navigate', 'close'],
            template: '<div />',
          },
          BarChart: {
            name: 'BarChart',
            props: ['collection', 'chartOptions', 'clickable'],
            emits: ['elementClick'],
            template:
              '<button data-test-id="bar-chart" @click="$emit(\'elementClick\', { dataIndex: 0, label: \'20-May\', value: 2 })" />',
          },
        },
      },
    });

  afterEach(() => {
    vi.clearAllMocks();
  });

  it('opens a drilldown request with report context when a non-zero bar is clicked', async () => {
    const wrapper = mountComponent();

    await wrapper.find('[data-test-id="bar-chart"]').trigger('click');

    const drawer = wrapper.findComponent({ name: 'ReportDrilldownDrawer' });
    expect(drawer.props('open')).toBe(true);
    expect(drawer.props()).toMatchObject({
      metric: 'conversations_count',
      metricName: 'REPORT.METRICS.CONVERSATIONS.NAME',
      bucketLabel: '15-May',
      bucketTimestamp: 1621103400,
      from: 1621103400,
      to: 1621621800,
      type: 'inbox',
      id: 1,
      groupBy: 'day',
      businessHours: true,
    });
  });

  it('shows an alert and does not open drilldown for non-admin users', async () => {
    const wrapper = mountComponent({ role: 'agent' });

    await wrapper.find('[data-test-id="bar-chart"]').trigger('click');

    expect(useAlert).toHaveBeenCalledWith('REPORT.DRILLDOWN.ADMIN_ONLY');
    expect(
      wrapper.findComponent({ name: 'ReportDrilldownDrawer' }).props('open')
    ).toBe(false);
  });

  it('does not open drilldown for zero-value count bars', async () => {
    const wrapper = mountComponent({
      dataPoint: { value: 0, timestamp: 1621103400 },
    });

    await wrapper.find('[data-test-id="bar-chart"]').trigger('click');

    expect(
      wrapper.findComponent({ name: 'ReportDrilldownDrawer' }).props('open')
    ).toBe(false);
  });

  it('opens average metric drilldown when the bucket has contributing records', async () => {
    const wrapper = mountComponent({
      reportKey: 'avg_first_response_time',
      dataPoint: { value: 90, count: 2, timestamp: 1621103400 },
    });

    await wrapper.find('[data-test-id="bar-chart"]').trigger('click');

    const drawer = wrapper.findComponent({ name: 'ReportDrilldownDrawer' });
    expect(drawer.props('open')).toBe(true);
    expect(drawer.props()).toMatchObject({
      metric: 'avg_first_response_time',
      bucketTimestamp: 1621103400,
    });
  });

  it('navigates to adjacent drillable buckets within the report range', async () => {
    const wrapper = mountComponent({
      data: [
        { value: 2, timestamp: 1621103400 },
        { value: 0, timestamp: 1621189800 },
        { value: 5, timestamp: 1621276200 },
      ],
    });

    await wrapper.find('[data-test-id="bar-chart"]').trigger('click');

    const drawer = wrapper.findComponent({ name: 'ReportDrilldownDrawer' });
    // Opened on the first bucket: no previous, but a later drillable bucket exists.
    expect(drawer.props('bucketTimestamp')).toBe(1621103400);
    expect(drawer.props('canPrev')).toBe(false);
    expect(drawer.props('canNext')).toBe(true);

    // Skips the zero-value middle bucket and lands on the last drillable one.
    drawer.vm.$emit('navigate', 1);
    await wrapper.vm.$nextTick();

    expect(drawer.props('bucketTimestamp')).toBe(1621276200);
    expect(drawer.props('canPrev')).toBe(true);
    expect(drawer.props('canNext')).toBe(false);
  });
});
