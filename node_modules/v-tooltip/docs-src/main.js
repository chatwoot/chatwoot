import Vue from 'vue'
import VueRouter from 'vue-router'
import VTooltip, { createTooltip, destroyTooltip } from '../'
import App from './App.vue'
import PageHome from './PageHome.vue'
import PageInstall from './PageInstall.vue'

Vue.use(VTooltip, {
  disposeTimeout: 5000,
  popover: {
    defaultPopperOptions: {
      modifiers: {
        preventOverflow: {
          padding: 12,
        },
      },
    },
  },
})

VTooltip.options.defaultDelay = {
  show: 300,
  hide: 0,
}

Vue.use(VueRouter)

const router = new VueRouter({
  routes: [
    { path: '/', name: 'home', component: PageHome },
    { path: '/install', name: 'install', component: PageInstall },
    { path: '/table', name: 'table', component: () => import('./PageTable.vue') },
    { path: '/popover-hover', name: 'popover-hover', component: () => import('./PopoverHover.vue') },
    { path: '*', redirect: '/' },
  ],
})

/* eslint-disable no-new */
new Vue({
  el: '#app',
  router,
  render: h => h(App),
})

// Create tooltips without the directive
window.manualTooltip = () => {
  const el = document.querySelector('button')
  const tooltip = createTooltip(el, {
    content: 'This is a manual tooltip',
    placement: 'bottom',
    trigger: 'manual',
  })
  tooltip.show()
  setTimeout(() => {
    destroyTooltip(el)
  }, 2000)
}
