import { Bar } from 'vue-chartjs';

const fontFamily =
  '-apple-system,system-ui,BlinkMacSystemFont,"Segoe UI",Roboto,"Helvetica Neue",Arial,sans-serif';

const chartOptions = {
  responsive: true,
  maintainAspectRatio: false,
  legend: {
    labels: {
      fontFamily,
    },
  },
  scales: {
    xAxes: [
      {
        barPercentage: 1.26,
        ticks: {
          fontFamily,
        },
        gridLines: {
          display: false,
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
          display: false,
        },
      },
    ],
  },
};

export default {
  extends: Bar,
  props: ['collection'],
  mounted() {
    this.renderChart(this.collection, chartOptions);
  },
};
