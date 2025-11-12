import { ref } from 'vue'

export const isDark = ref(false)

if (!window.__hst_controls_dark) {
  window.__hst_controls_dark = []
}

// There could be multiple instances of the controls lib (in the controls book https://controls.histoire.dev)
window.__hst_controls_dark.push(isDark)

window.__hst_controls_dark_ready?.()
