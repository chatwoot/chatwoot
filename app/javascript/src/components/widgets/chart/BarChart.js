import { Bar } from 'vue-chartjs';

const fontFamily = '-apple-system,system-ui,BlinkMacSystemFont,"Segoe UI",Roboto,"Helvetica Neue",Arial,sans-serif';

export default Bar.extend({
  props: ['collection'],
  mounted() {
    this.renderChart(this.collection, {
      // responsive: true,
      maintainAspectRatio: false,
      legend: {
        labels: {
          fontFamily,
        },
      },
      scales: {
        xAxes: [
          {
            barPercentage: 1.9,
            ticks: {
              fontFamily,
            },
          },
        ],
        yAxes: [
          {
            ticks: {
              fontFamily,
            },
          },
        ],
      },
    });
  },
});
