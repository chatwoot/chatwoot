import Vue from 'vue';
import 'chart.js';

export declare class ReactiveDataMixin extends Vue {
  chartData: Chart.ChartData;
}

export declare class ReactivePropMixin extends Vue {
  readonly chartData: Chart.ChartData;
}
