import { parseQuery } from 'vue-router'
import { computed, createApp, h, onMounted, ref, watch } from 'vue'
import { createPinia } from 'pinia'
import { applyState } from '@histoire/shared'
import { files } from 'virtual:$histoire-stories'
import GenericMountStory from './components/story/GenericMountStory.vue'
import GenericRenderStory from './components/story/GenericRenderStory.vue'
import type { StoryFile } from './types'
import { mapFile } from './util/mapping'
import { PREVIEW_SETTINGS_SYNC, SANDBOX_READY, STATE_SYNC } from './util/const.js'
import { applyPreviewSettings } from './util/preview-settings.js'
import { isDark } from './util/dark.js'
import { histoireConfig } from './util/config.js'
import { toRawDeep } from './util/state.js'
import { setupPluginApi } from './plugin.js'

const query = parseQuery(window.location.search)
const file = ref<StoryFile>(mapFile(files.find(f => f.id === query.storyId)))

const app = createApp({
  name: 'SandboxApp',

  setup() {
    const story = computed(() => file.value.story)
    const variant = computed(() => story.value?.variants.find(v => v.id === query.variantId))

    let synced = false
    let mounted = false

    window.addEventListener('message', (event) => {
      // console.log('[sandbox] received message', event.data)
      if (event.data?.type === STATE_SYNC) {
        if (!mounted) return
        synced = true
        applyState(variant.value.state, event.data.state)
      }
      else if (event.data?.type === PREVIEW_SETTINGS_SYNC) {
        applyPreviewSettings(event.data.settings)
      }
    })

    watch(() => variant.value.state, (value) => {
      if (synced && mounted) {
        synced = false
        return
      }
      window.parent?.postMessage({
        type: STATE_SYNC,
        state: toRawDeep(value, true),
      })
    }, {
      deep: true,
    })

    onMounted(() => {
      mounted = true
    })

    return {
      story,
      variant,
    }
  },

  render() {
    return [
      h('div', { class: 'htw-sandbox-hidden' }, [
        h(GenericMountStory, {
          key: file.value.story.id,
          story: file.value.story,
        }),
      ]),
      this.story && this.variant
        ? h(GenericRenderStory, {
          story: this.story,
          variant: this.variant,
          onReady: () => {
            window.parent?.postMessage({
              type: SANDBOX_READY,
            })
          },
        })
        : null,
    ]
  },
})
app.use(createPinia())
app.mount('#app')

watch(isDark, (value) => {
  if (value) {
    document.documentElement.classList.add(histoireConfig.sandboxDarkClass) // @TODO remove
    document.documentElement.classList.add(histoireConfig.theme.darkClass)
  }
  else {
    document.documentElement.classList.remove(histoireConfig.sandboxDarkClass) // @TODO remove
    document.documentElement.classList.remove(histoireConfig.theme.darkClass)
  }
}, {
  immediate: true,
})

if (import.meta.hot) {
  /* #__PURE__ */ setupPluginApi()
}
