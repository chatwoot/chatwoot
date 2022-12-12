import { BaseChart } from './components'
import { ReactiveDataMixin, ReactivePropMixin } from './mixins'

declare module 'vue-chartjs' {
  export function generateChart(chartId: string, chartType: string): any;
  export class Bar extends BaseChart {}
  export class HorizontalBar extends BaseChart {}
  export class Doughnut extends BaseChart {}
  export class Line extends BaseChart {}
  export class Pie extends BaseChart {}
  export class PolarArea extends BaseChart {}
  export class Radar extends BaseChart {}
  export class Bubble extends BaseChart {}
  export class Scatter extends BaseChart {}
  export const mixins: {
    reactiveData: typeof ReactiveDataMixin
    reactiveProp: typeof ReactivePropMixin
  }
}

