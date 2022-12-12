import Vue from 'vue'
import 'chart.js'

/** vue-chartjs component common definition */
export declare class BaseChart extends Vue {
  addPlugin (plugin?: object): void
  renderChart (chartData: Chart.ChartData, options?: Chart.ChartOptions): void
}
