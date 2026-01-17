import 'virtual:$histoire-theme'
import { createApp } from 'vue'
import { createPinia } from 'pinia'
import FloatingVue from 'floating-vue'
import App from './App.vue'
import { router } from './router'
import { setupPluginApi } from './plugin.js'

export async function mountMainApp() {
  const app = createApp(App)
  app.use(createPinia())
  app.use(FloatingVue, {
    overflowPadding: 4,
    arrowPadding: 8,
    themes: {
      tooltip: {
        distance: 8,
      },
      dropdown: {
        computeTransformOrigin: true,
        distance: 8,
      },
    },
  })
  app.use(router)
  app.mount('#app')

  if (import.meta.hot) {
    import.meta.hot.send('histoire:mount', {})

    /* #__PURE__ */ setupPluginApi()
  }
}
