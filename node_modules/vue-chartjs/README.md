<div align="center">
  <img width="256" heigth="256" src="/assets/vue-chartjs.png" alt="vue-chartjs logo">
</div>

[![npm version](https://badge.fury.io/js/vue-chartjs.svg)](https://badge.fury.io/js/vue-chartjs)
[![codecov](https://codecov.io/gh/apertureless/vue-chartjs/branch/master/graph/badge.svg)](https://codecov.io/gh/apertureless/vue-chartjs)
[![Build Status](https://travis-ci.org/apertureless/vue-chartjs.svg?branch=master)](https://travis-ci.org/apertureless/vue-chartjs)
[![Package Quality](http://npm.packagequality.com/shield/vue-chartjs.svg)](http://packagequality.com/#?package=vue-chartjs)
[![npm](https://img.shields.io/npm/dm/vue-chartjs.svg)](https://www.npmjs.com/package/vue-chartjs)
[![Gitter chat](https://img.shields.io/gitter/room/TechnologyAdvice/Stardust.svg)](https://gitter.im/vue-chartjs/Lobby)
[![license](https://img.shields.io/github/license/mashape/apistatus.svg)](https://github.com/apertureless/vue-chartjs/blob/master/LICENSE.txt)
[![CDNJS version](https://img.shields.io/cdnjs/v/vue-chartjs.svg)](https://cdnjs.com/libraries/vue-chartjs)
[![Known Vulnerabilities](https://snyk.io/test/github/apertureless/vue-chartjs/badge.svg)](https://snyk.io/test/github/apertureless/vue-chartjs)
[![Maintainability](https://api.codeclimate.com/v1/badges/8c0256b16ba7a50a9f93/maintainability)](https://codeclimate.com/github/apertureless/vue-chartjs/maintainability)
[![Donate](assets/donate.svg)](https://www.paypal.me/apertureless/50eur)
[![ko-fi](https://www.ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/C0C1WP7C)

# vue-chartjs

**vue-chartjs** is a wrapper for [Chart.js](https://github.com/chartjs/Chart.js) in vue. You can easily create reuseable chart components.

## Demo & Docs

- 📺 [Demo](http://demo.vue-chartjs.org/)
- 📖 [Docs](http://vue-chartjs.org/)

### Compatibility

- v1 later `@legacy`
  - Vue.js 1.x
- v2 later
  - Vue.js 2.x

After the final release of vue.js 2, you also get the v2 by default if you install vue-chartjs over npm.
No need for the @next tag anymore. If you want the v1 you need to define the version or use the legacy tag.
If you're looking for v1 check this [branch](https://github.com/apertureless/vue-chartjs/tree/release/1.x)

## Install

- **yarn** install: `yarn add vue-chartjs chart.js`
- **npm** install: `npm install vue-chartjs chart.js --save`

Or if you want to use it directly in the browser add

```html
<script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/2.7.1/Chart.min.js"></script>
<script src="https://unpkg.com/vue-chartjs/dist/vue-chartjs.min.js"></script>
```
to your scripts. See [Codepen](https://codepen.io/apertureless/pen/zEvvWM)


### Browser
You can use `vue-chartjs` directly in the browser without any build setup. Like in this [codepen](https://codepen.io/apertureless/pen/zEvvWM). For this case, please use the `vue-chartjs.min.js` which is the minified version. You also need to add the Chart.js CDN script.

You can then simply register your component:

```js
Vue.component('line-chart', {
  extends: VueChartJs.Line,
  mounted () {
    this.renderChart({
      labels: ['January', 'February', 'March', 'April', 'May', 'June', 'July'],
      datasets: [
        {
          label: 'Data One',
          backgroundColor: '#f87979',
          data: [40, 39, 10, 40, 39, 80, 40]
        }
      ]
    }, {responsive: true, maintainAspectRatio: false})
  }
})
```

## How to use

You need to import the component and then either use `extends` or `mixins` and add it.

You can import the whole package or each module individual.

```javascript
import VueCharts from 'vue-chartjs'
import { Bar, Line } from 'vue-chartjs'
```

Just create your own component.

```javascript
// CommitChart.js
import { Bar } from 'vue-chartjs'

export default {
  extends: Bar,
  mounted () {
    // Overwriting base render method with actual data.
    this.renderChart({
      labels: ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'],
      datasets: [
        {
          label: 'GitHub Commits',
          backgroundColor: '#f87979',
          data: [40, 20, 12, 39, 10, 40, 39, 80, 40, 20, 12, 11]
        }
      ]
    })
  }
}
```

or in TypeScript

```ts
// CommitChart.ts
import { Bar, mixins } from 'vue-chartjs';
import { Component } from 'vue-property-decorator';

@Component({
    extends: Bar, // this is important to add the functionality to your component
    mixins: [mixins.reactiveProp]
})
export default class CommitChart extends Vue<Bar> {
  mounted () {
    // Overwriting base render method with actual data.
    this.renderChart({
      labels: ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'],
      datasets: [
        {
          label: 'GitHub Commits',
          backgroundColor: '#f87979',
          data: [40, 20, 12, 39, 10, 40, 39, 80, 40, 20, 12, 11]
        }
      ]
    })
  }
}
```

Then simply import and use your own extended component and use it like a normal vue component

```javascript
import CommitChart from 'path/to/component/CommitChart'
```

## Another Example with options

You can overwrite the default chart options. Just pass the options object as a second parameter to the render method

```javascript
// MonthlyIncome.vue
import { Line } from 'vue-chartjs'

export default {
  extends: Line,
  props: ['data', 'options'],
  mounted () {
    this.renderChart(this.data, this.options)
  }
}
```

Use it in your vue app

```javascript
import MonthlyIncome from 'path/to/component/MonthlyIncome'

<template>
  <monthly-income :data={....} />
</template>

<script>
export default {
  components: { MonthlyIncome },
  ....
}
</script>
```

## Reactivity

Chart.js does not update or re-render the chart if new data is passed.
However, you can simply implement this on your own or use one of the two mixins which are included.

- `reactiveProp`
- `reactiveData`

Both are included in the `mixins` module.

The mixins automatically create `chartData` as a prop or data. And add a watcher. If data has changed, the chart will update.
However, keep in mind the limitations of vue and javascript for mutations on arrays and objects.
**It is important that you pass your options in a local variable named `options`!**
The reason is that if the mixin re-renders the chart it calls `this.renderChart(this.chartData, this.options)` so don't pass in the options object directly or it will be ignored.

More info [here](https://vue-chartjs.org/guide/#updating-charts)

```javascript
// MonthlyIncome.js
import { Line, mixins } from 'vue-chartjs'

export default {
  extends: Line,
  mixins: [mixins.reactiveProp],
  props: ['chartData', 'options'],
  mounted () {
    this.renderChart(this.chartData, this.options)
  }
}

```

### Mixins module
The `mixins` module is included in the `VueCharts` module and as a separate module.
Some ways to import them:

```javascript
// Load complete module with all charts
import VueCharts from 'vue-chartjs'

export default {
  extends: VueCharts.Line,
  mixins: [VueCharts.mixins.reactiveProp],
  props: ['chartData', 'options'],
  mounted () {
    this.renderChart(this.chartData, this.options)
  }
}
```

```javascript
// Load separate modules
import { Line, mixins } from 'vue-chartjs'

export default {
  extends: Line,
  mixins: [mixins.reactiveProp],
  props: ['chartData', 'options'],
  mounted () {
    this.renderChart(this.chartData, this.options)
  }
}
```

```javascript
// Load separate modules with destructure assign
import { Line, mixins } from 'vue-chartjs'
const { reactiveProp } = mixins

export default {
  extends: Line,
  mixins: [reactiveProp],
  props: ['chartData', 'options'],
  mounted () {
    this.renderChart(this.chartData, this.options)
  }
}
```

## Single File Components

You can create your components in Vues single file components. However it is important that you **do not** have the `<template></template>` included. Because Vue can't merge templates. And the template is included in the mixin. If you leave the template tag in your component, it will overwrite the one which comes from the base chart and you will have a blank screen.

## Available Charts

### Bar Chart

![Bar](assets/bar.png)

### Line Chart

![Line](assets/line.png)

### Doughnut

![Doughnut](assets/doughnut.png)

### Pie

![Pie](assets/pie.png)

### Radar

![Pie](assets/radar.png)

### Polar Area

![Pie](assets/polar.png)

### Bubble

![Bubble](assets/bubble.png)

### Scatter

![Scatter](assets/scatter.png)

## Build Setup

``` bash
# install dependencies
npm install

# serve with hot reload at localhost:8080
npm run dev

# build for production with minification
npm run build

# run unit tests
npm run unit

# run e2e tests
npm run e2e

# run all tests
npm test
```

For a detailed explanation of how things work, check out the [guide](http://vuejs-templates.github.io/webpack/) and [docs for vue-loader](http://vuejs.github.io/vue-loader).

## Contributing

1. Fork it ( https://github.com/apertureless/vue-chartjs/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## License

This software is distributed under [MIT license](LICENSE.txt).

<a href="https://www.buymeacoffee.com/xcqjaytbl" target="_blank"><img src="https://www.buymeacoffee.com/assets/img/custom_images/purple_img.png" alt="Buy Me A Coffee" style="height: auto !important;width: auto !important;" ></a>
