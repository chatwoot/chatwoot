import { Bar } from '../BaseCharts';
import { reactiveData } from '../mixins';
export default {
  extends: Bar,
  mixins: [reactiveData],
  data: function data() {
    return {
      chartData: '',
      options: {
        responsive: true,
        maintainAspectRatio: false
      }
    };
  },
  created: function created() {
    this.fillData();
  },
  mounted: function mounted() {
    var _this = this;

    this.renderChart(this.chartData, this.options);
    setInterval(function () {
      _this.fillData();
    }, 5000);
  },
  methods: {
    fillData: function fillData() {
      this.chartData = {
        labels: ['January' + this.getRandomInt(), 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'],
        datasets: [{
          label: 'Data One',
          backgroundColor: '#f87979',
          data: [this.getRandomInt(), this.getRandomInt(), this.getRandomInt(), this.getRandomInt(), this.getRandomInt(), this.getRandomInt(), this.getRandomInt(), this.getRandomInt(), this.getRandomInt(), this.getRandomInt(), this.getRandomInt(), this.getRandomInt()]
        }]
      };
    },
    getRandomInt: function getRandomInt() {
      return Math.floor(Math.random() * (50 - 5 + 1)) + 5;
    }
  }
};