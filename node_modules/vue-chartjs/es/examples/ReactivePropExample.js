import { Bar } from '../BaseCharts';
import { reactiveProp } from '../mixins';
export default {
  extends: Bar,
  mixins: [reactiveProp],
  data: function data() {
    return {
      options: {
        responsive: true,
        maintainAspectRatio: false
      }
    };
  },
  mounted: function mounted() {
    this.renderChart(this.chartData, this.options);
  }
};