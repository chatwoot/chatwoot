import { formatTime } from '@chatwoot/utils';

export const GROUP_BY_FILTER = {
  1: { id: 1, period: 'day' },
  2: { id: 2, period: 'week' },
  3: { id: 3, period: 'month' },
  4: { id: 4, period: 'year' },
};

export const GROUP_BY_OPTIONS = {
  DAY: {
    id: 'DAY',
    period: 'day',
    translationKey: 'REPORT.GROUPING_OPTIONS.DAY',
  },
  WEEK: {
    id: 'WEEK',
    period: 'week',
    translationKey: 'REPORT.GROUPING_OPTIONS.WEEK',
  },
  MONTH: {
    id: 'MONTH',
    period: 'month',
    translationKey: 'REPORT.GROUPING_OPTIONS.MONTH',
  },
  YEAR: {
    id: 'YEAR',
    period: 'year',
    translationKey: 'REPORT.GROUPING_OPTIONS.YEAR',
  },
};

export const DATE_RANGE_OPTIONS = {
  LAST_7_DAYS: {
    id: 'LAST_7_DAYS',
    translationKey: 'REPORT.DATE_RANGE_OPTIONS.LAST_7_DAYS',
    offset: 6,
    groupByOptions: [GROUP_BY_OPTIONS.DAY],
  },
  LAST_30_DAYS: {
    id: 'LAST_30_DAYS',
    translationKey: 'REPORT.DATE_RANGE_OPTIONS.LAST_30_DAYS',
    offset: 29,
    groupByOptions: [GROUP_BY_OPTIONS.DAY, GROUP_BY_OPTIONS.WEEK],
  },
  LAST_3_MONTHS: {
    id: 'LAST_3_MONTHS',
    translationKey: 'REPORT.DATE_RANGE_OPTIONS.LAST_3_MONTHS',
    offset: 89,
    groupByOptions: [
      GROUP_BY_OPTIONS.DAY,
      GROUP_BY_OPTIONS.WEEK,
      GROUP_BY_OPTIONS.MONTH,
    ],
  },
  LAST_6_MONTHS: {
    id: 'LAST_6_MONTHS',
    translationKey: 'REPORT.DATE_RANGE_OPTIONS.LAST_6_MONTHS',
    offset: 179,
    groupByOptions: [
      GROUP_BY_OPTIONS.DAY,
      GROUP_BY_OPTIONS.WEEK,
      GROUP_BY_OPTIONS.MONTH,
    ],
  },
  LAST_YEAR: {
    id: 'LAST_YEAR',
    translationKey: 'REPORT.DATE_RANGE_OPTIONS.LAST_YEAR',
    offset: 364,
    groupByOptions: [
      GROUP_BY_OPTIONS.DAY,
      GROUP_BY_OPTIONS.WEEK,
      GROUP_BY_OPTIONS.MONTH,
    ],
  },
  CUSTOM_DATE_RANGE: {
    id: 'CUSTOM_DATE_RANGE',
    translationKey: 'REPORT.DATE_RANGE_OPTIONS.CUSTOM_DATE_RANGE',
    offset: null,
    groupByOptions: [
      GROUP_BY_OPTIONS.DAY,
      GROUP_BY_OPTIONS.WEEK,
      GROUP_BY_OPTIONS.MONTH,
      GROUP_BY_OPTIONS.YEAR,
    ],
  },
};

export const CHART_FONT_FAMILY =
  '-apple-system,system-ui,BlinkMacSystemFont,"Segoe UI",Roboto,"Helvetica Neue",Arial,sans-serif';

export const DEFAULT_LINE_CHART = {
  type: 'line',
  fill: false,
  borderColor: '#779BBB',
  pointBackgroundColor: '#779BBB',
};

export const DEFAULT_BAR_CHART = {
  type: 'bar',
  backgroundColor: 'rgb(31, 147, 255)',
};

export const DEFAULT_CHART = {
  datasets: [DEFAULT_BAR_CHART],
  scales: {
    xAxes: [
      {
        ticks: {
          fontFamily: CHART_FONT_FAMILY,
        },
        gridLines: {
          drawOnChartArea: false,
        },
      },
    ],
    yAxes: [
      {
        id: 'y-left',
        type: 'linear',
        position: 'left',
        ticks: {
          fontFamily: CHART_FONT_FAMILY,
          beginAtZero: true,
          stepSize: 1,
        },
        gridLines: {
          drawOnChartArea: false,
        },
      },
    ],
  },
};

export const METRIC_CHART = {
  conversations_count: DEFAULT_CHART,
  incoming_messages_count: DEFAULT_CHART,
  outgoing_messages_count: DEFAULT_CHART,
  avg_first_response_time: {
    datasets: [DEFAULT_BAR_CHART],
    scales: {
      xAxes: [
        {
          ticks: {
            fontFamily: CHART_FONT_FAMILY,
          },
          gridLines: {
            drawOnChartArea: false,
          },
        },
      ],
      yAxes: [
        {
          id: 'y-left',
          type: 'linear',
          position: 'left',
          ticks: {
            fontFamily: CHART_FONT_FAMILY,
            callback(value) {
              return formatTime(value);
            },
          },
          gridLines: {
            drawOnChartArea: false,
          },
        },
      ],
    },
  },
  avg_resolution_time: {
    datasets: [DEFAULT_BAR_CHART],
    scales: {
      xAxes: [
        {
          ticks: {
            fontFamily: CHART_FONT_FAMILY,
          },
          gridLines: {
            drawOnChartArea: false,
          },
        },
      ],
      yAxes: [
        {
          id: 'y-left',
          type: 'linear',
          position: 'left',
          ticks: {
            fontFamily: CHART_FONT_FAMILY,
            callback(value) {
              return formatTime(value);
            },
          },
          gridLines: {
            drawOnChartArea: false,
          },
        },
      ],
    },
  },
  resolutions_count: DEFAULT_CHART,
};

export const OVERVIEW_METRICS = {
  open: 'OPEN',
  unattended: 'UNATTENDED',
  unassigned: 'UNASSIGNED',
  online: 'ONLINE',
  busy: 'BUSY',
  offline: 'OFFLINE',
};
