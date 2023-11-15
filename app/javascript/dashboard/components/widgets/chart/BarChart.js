import { Bar } from 'vue-chartjs';

const fontFamily =
  'PlusJakarta,-apple-system,system-ui,BlinkMacSystemFont,"Segoe UI",Roboto,"Helvetica Neue",Arial,sans-serif';

const defaultChartOptions = {
  responsive: true,
  maintainAspectRatio: false,
  legend: {
    display: false,
    labels: {
      fontFamily,
    },
  },
  animation: {
    duration: 0,
  },
  datasets: {
    bar: {
      barPercentage: 1.0,
    },
  },
  scales: {
    xAxes: [
      {
        ticks: {
          fontFamily,
        },
        gridLines: {
          drawOnChartArea: false,
        },
      },
    ],
    yAxes: [
      {
        ticks: {
          fontFamily,
          beginAtZero: true,
        },
        gridLines: {
          drawOnChartArea: false,
        },
      },
    ],
  },
};

export default {
  extends: Bar,
  props: {
    collection: {
      type: Object,
      default: () => ({}),
    },
    chartOptions: {
      type: Object,
      default: () => ({}),
    },
  },
  mounted() {
    this.renderChart(this.collection, {
      ...defaultChartOptions,
      ...this.chartOptions,
    });
  },
};
