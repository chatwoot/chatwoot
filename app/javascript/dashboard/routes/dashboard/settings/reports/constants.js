export const formatTime = timeInSeconds => {
  if (!timeInSeconds) {
    return '';
  }

  if (timeInSeconds < 60) {
    return `${timeInSeconds}s`;
  }

  if (timeInSeconds < 3600) {
    const minutes = Math.floor(timeInSeconds / 60);
    return `${minutes}m`;
  }

  if (timeInSeconds < 86400) {
    const hours = Math.floor(timeInSeconds / 3600);
    return `${hours}h`;
  }

  const days = Math.floor(timeInSeconds / 86400);
  return `${days}d`;
};

export const CHART_FONT_FAMILY =
  'PlusJakarta,-apple-system,system-ui,BlinkMacSystemFont,"Segoe UI",Roboto,"Helvetica Neue",Arial,sans-serif';

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

const createChartConfig = yAxisTickCallback => ({
  datasets: [DEFAULT_BAR_CHART],
  scales: {
    x: {
      ticks: {
        fontFamily: CHART_FONT_FAMILY,
      },
      grid: {
        drawOnChartArea: false,
      },
    },
    y: {
      type: 'linear',
      position: 'left',
      ticks: {
        fontFamily: CHART_FONT_FAMILY,
        beginAtZero: true,
        stepSize: 1,
        callback: yAxisTickCallback,
      },
      grid: {
        drawOnChartArea: false,
      },
    },
  },
});

export const DEFAULT_CHART = createChartConfig((value, index, ticks) => {
  if (!index || index === ticks.length - 1) {
    return value;
  }
  return '';
});

export const TIME_CHART_CONFIG = createChartConfig((value, index, values) => {
  if (!index || index === values.length - 1) {
    return formatTime(value);
  }
  return '';
});

export const METRIC_CHART = {
  conversations_count: DEFAULT_CHART,
  incoming_messages_count: DEFAULT_CHART,
  outgoing_messages_count: DEFAULT_CHART,
  avg_first_response_time: TIME_CHART_CONFIG,
  reply_time: TIME_CHART_CONFIG,
  avg_resolution_time: TIME_CHART_CONFIG,
  resolutions_count: DEFAULT_CHART,
  bot_resolutions_count: DEFAULT_CHART,
  bot_handoffs_count: DEFAULT_CHART,
};
