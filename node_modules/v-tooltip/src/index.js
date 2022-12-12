import vtooltip, { defaultOptions, state } from './directives/v-tooltip'
import vclosepopover from './directives/v-close-popover'
import Popover from './components/Popover.vue'
import merge from 'lodash/merge'
import 'vue-resize/dist/vue-resize.css'

export { createTooltip, destroyTooltip } from './directives/v-tooltip'

export function install (Vue, options = {}) {
  if (install.installed) return
  install.installed = true

  const finalOptions = {}
  merge(finalOptions, defaultOptions, options)

  plugin.options = finalOptions
  vtooltip.options = finalOptions

  Vue.directive('tooltip', vtooltip)
  Vue.directive('close-popover', vclosepopover)
  Vue.component('VPopover', Popover)
}

export const VTooltip = vtooltip
export const VClosePopover = vclosepopover
export const VPopover = Popover

const plugin = {
  install,

  get enabled () {
    return state.enabled
  },

  set enabled (value) {
    state.enabled = value
  },
}

// Auto-install
let GlobalVue = null
if (typeof window !== 'undefined') {
  GlobalVue = window.Vue
} else if (typeof global !== 'undefined') {
  GlobalVue = global.Vue
}
if (GlobalVue) {
  GlobalVue.use(plugin)
}

export default plugin
