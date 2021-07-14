import { HorizontalBar } from 'vue-chartjs';

const chartOptions = {
  responsive: true,
  legend: {
    display: false,
  },
  title: {
    display: false,
  },
  tooltips: {
    enabled: false,
  },
  scales: {
    xAxes: [
      {
        gridLines: {
          offsetGridLines: false,
        },
        display: false,
        stacked: true,
      },
    ],
    yAxes: [
      {
        gridLines: {
          offsetGridLines: false,
        },
        display: false,
        stacked: true,
      },
    ],
  },
};

export default {
  extends: HorizontalBar,
  props: {
    collection: {
      type: Object,
      default: () => {},
    },
    chartOptions: {
      type: Object,
      default: () => {},
    },
  },
  mounted() {
    this.renderChart(this.collection, {
      ...chartOptions,
      ...this.chartOptions,
    });
  },
};
