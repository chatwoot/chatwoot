import Vue from 'vue'
import VueFormulate from '../src/Formulate'
import FormulateSpecimens from './FormulateSpecimens.vue'
import { en, de } from '@braid/vue-formulate-i18n'

Vue.config.productionTip = false

Vue.use(VueFormulate, {
  plugins: [en, de],
  locale: 'en'
})

new Vue({
  render: h => h(FormulateSpecimens)
}).$mount('#app')
