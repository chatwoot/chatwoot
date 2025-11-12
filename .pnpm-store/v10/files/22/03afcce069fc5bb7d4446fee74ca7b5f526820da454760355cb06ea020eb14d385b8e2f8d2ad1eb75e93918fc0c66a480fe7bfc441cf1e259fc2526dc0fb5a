<script lang="ts" setup>
import { computed, ref, toRaw, watch } from 'vue'
import { useEventListener } from '@vueuse/core'
import { applyState } from '@histoire/shared'
import { EVENT_SEND, PREVIEW_SETTINGS_SYNC, SANDBOX_READY, STATE_SYNC } from '../../util/const'
import type { Story, Variant } from '../../types'
import { getSandboxUrl } from '../../util/sandbox'
import { usePreviewSettingsStore } from '../../stores/preview-settings'
import type { HstEvent } from '../../stores/events'
import { useEventsStore } from '../../stores/events'
import { toRawDeep } from '../../util/state'
import StoryResponsivePreview from './StoryResponsivePreview.vue'

const props = defineProps<{
  story: Story
  variant: Variant
}>()

const settings = usePreviewSettingsStore().currentSettings

// Iframe

const iframe = ref<HTMLIFrameElement>()

function syncState() {
  if (iframe.value && props.variant.previewReady) {
    iframe.value.contentWindow.postMessage({
      type: STATE_SYNC,
      state: toRawDeep(props.variant.state, true),
    })
  }
}

let synced = false

watch(() => props.variant.state, () => {
  if (synced) {
    synced = false
    return
  }
  syncState()
}, {
  deep: true,
  immediate: true,
})

Object.assign(props.variant, {
  previewReady: false,
})

useEventListener(window, 'message', (event) => {
  switch (event.data.type) {
    case STATE_SYNC:
      updateVariantState(event.data.state)
      break
    case EVENT_SEND:
      logEvent(event.data.event)
      break
    case SANDBOX_READY:
      setPreviewReady()
      break
  }
})

function updateVariantState(state: any) {
  synced = true
  applyState(props.variant.state, state)
}

function logEvent(event: HstEvent) {
  const eventsStore = useEventsStore()
  eventsStore.addEvent(event)
}

function setPreviewReady() {
  Object.assign(props.variant, {
    previewReady: true,
  })
}

const sandboxUrl = computed(() => {
  return getSandboxUrl(props.story, props.variant)
})

const isIframeLoaded = ref(false)

watch(sandboxUrl, () => {
  isIframeLoaded.value = false
  Object.assign(props.variant, {
    previewReady: false,
  })
})

// Settings

function syncSettings() {
  if (iframe.value) {
    iframe.value.contentWindow.postMessage({
      type: PREVIEW_SETTINGS_SYNC,
      settings: toRaw(settings),
    })
  }
}

watch(() => settings, () => {
  syncSettings()
}, {
  deep: true,
  immediate: true,
})

// Iframe load

function onIframeLoad() {
  isIframeLoaded.value = true
  syncState()
  syncSettings()
}
</script>

<template>
  <StoryResponsivePreview
    v-slot="{ isResponsiveEnabled, finalWidth, finalHeight, resizing }"
    class="histoire-story-variant-single-preview-remote"
    :variant="variant"
  >
    <iframe
      ref="iframe"
      :src="sandboxUrl"
      class="htw-w-full htw-h-full htw-relative"
      :class="{
        'htw-invisible': !isIframeLoaded,
        'htw-pointer-events-none': resizing,
      }"
      :style="isResponsiveEnabled ? {
        width: finalWidth ? `${finalWidth}px` : null,
        height: finalHeight ? `${finalHeight}px` : null,
      } : undefined"
      data-test-id="preview-iframe"
      @load="onIframeLoad()"
    />
  </StoryResponsivePreview>
</template>
