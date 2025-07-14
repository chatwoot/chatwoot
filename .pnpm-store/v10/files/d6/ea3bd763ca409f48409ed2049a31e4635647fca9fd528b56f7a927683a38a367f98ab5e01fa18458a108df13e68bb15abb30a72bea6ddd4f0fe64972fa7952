<script lang="ts" setup>
import { computed, markRaw, nextTick, onMounted, ref, shallowRef, watch, watchEffect } from 'vue'
import { Icon } from '@iconify/vue'
import type { Highlighter } from 'shiki-es'
import { getHighlighter } from 'shiki-es'
import { HstCopyIcon } from '@histoire/controls'
import { unindent } from '@histoire/shared'
import { clientSupportPlugins } from 'virtual:$histoire-support-plugins-client'
import type { Story, Variant } from '../../types'
import { isDark } from '../../util/dark'
import BaseEmpty from '../base/BaseEmpty.vue'

const props = defineProps<{
  story: Story
  variant: Variant
}>()

const generateSourceCodeFn = ref(null)

watchEffect(async () => {
  const clientPlugin = clientSupportPlugins[props.story.file?.supportPluginId]
  if (clientPlugin) {
    const pluginModule = await clientPlugin()
    generateSourceCodeFn.value = markRaw(pluginModule.generateSourceCode)
  }
})

const highlighter = shallowRef<Highlighter>()

const dynamicSourceCode = ref('')
const error = ref<string>(null)

watch(() => [props.variant, generateSourceCodeFn.value], async () => {
  if (!generateSourceCodeFn.value) return
  error.value = null
  dynamicSourceCode.value = ''
  try {
    if (props.variant.source) {
      dynamicSourceCode.value = props.variant.source
    }
    else if (props.variant.slots?.().source) {
      const source = props.variant.slots?.().source()[0].children
      if (source) {
        dynamicSourceCode.value = await unindent(source)
      }
    }
    else {
      dynamicSourceCode.value = await generateSourceCodeFn.value(props.variant)
    }
  }
  catch (e) {
    console.error(e)
    error.value = e.message
  }

  // Auto-switch
  if (!dynamicSourceCode.value) {
    displayedSource.value = 'static'
  }
}, {
  deep: true,
  immediate: true,
})

// Static file source

const staticSourceCode = ref('')
watch(() => [props.story, props.story?.file?.source], async () => {
  staticSourceCode.value = ''
  const sourceLoader = props.story.file?.source
  if (sourceLoader) {
    staticSourceCode.value = (await sourceLoader()).default
  }
}, {
  immediate: true,
})

const displayedSource = ref<'dynamic' | 'static'>('dynamic')

const displayedSourceCode = computed(() => {
  if (displayedSource.value === 'dynamic') {
    return dynamicSourceCode.value
  }
  return staticSourceCode.value
})

// HTML render

onMounted(async () => {
  highlighter.value = await getHighlighter({
    langs: [
      'html',
      'jsx',
    ],
    themes: [
      'github-light',
      'github-dark',
    ],
  })
})

const sourceHtml = computed(() => displayedSourceCode.value
  ? highlighter.value?.codeToHtml(displayedSourceCode.value, {
    lang: 'html',
    theme: isDark.value ? 'github-dark' : 'github-light',
  })
  : '')

// Scrolling

let lastScroll = 0

// Reset
watch(() => props.variant, () => {
  lastScroll = 0
})

const scroller = ref<HTMLElement>()

function onScroll(event) {
  if (sourceHtml.value) {
    lastScroll = event.target.scrollTop
  }
}

watch(sourceHtml, async () => {
  await nextTick()
  if (scroller.value) {
    scroller.value.scrollTop = lastScroll
  }
})
</script>

<template>
  <div
    class="histoire-story-source-code htw-bg-gray-50 dark:htw-bg-gray-750 htw-h-full htw-overflow-hidden htw-flex htw-flex-col"
  >
    <!-- Toolbar -->
    <div
      v-if="!error"
      class="htw-h-10 htw-flex-none htw-border-b htw-border-solid htw-border-gray-500/5 htw-px-4 htw-flex htw-items-center htw-gap-2"
    >
      <div class="htw-text-gray-900 dark:htw-text-gray-100">
        Source
      </div>
      <div class="htw-flex-1" />

      <!-- Display source modes -->
      <div class="htw-flex htw-flex-none htw-gap-px htw-h-full htw-py-2">
        <button
          v-tooltip="!dynamicSourceCode ? 'Dynamic source code is not available' : displayedSource !== 'dynamic' ? 'Switch to dynamic source' : null"
          class="htw-flex htw-items-center htw-gap-1 htw-h-full htw-px-1 htw-bg-gray-500/10 htw-rounded-l htw-transition-all htw-ease-[cubic-bezier(0,1,.6,1)] htw-duration-300 htw-overflow-hidden"
          :class="[
            displayedSource !== 'dynamic' ? 'htw-max-w-6 htw-opacity-70' : 'htw-max-w-[82px] htw-text-primary-600 dark:htw-text-primary-400',
            dynamicSourceCode ? 'htw-cursor-pointer hover:htw-bg-gray-500/30 active:htw-bg-gray-600/50' : 'htw-opacity-50',
          ]"
          @click="dynamicSourceCode && (displayedSource = 'dynamic')"
        >
          <Icon
            icon="carbon:flash"
            class="htw-w-4 htw-h-4 htw-flex-none"
          />
          <span
            class="transition-opacity duration-300"
            :class="{
              'opacity-0': displayedSource !== 'dynamic',
            }"
          >
            Dynamic
          </span>
        </button>
        <button
          v-tooltip="!staticSourceCode ? 'Static source code is not available' : displayedSource !== 'static' ? 'Switch to static source' : null"
          class="htw-flex htw-items-center htw-gap-1 htw-h-full htw-px-1 htw-bg-gray-500/10 htw-rounded-r htw-transition-all htw-ease-[cubic-bezier(0,1,.6,1)] htw-duration-300 htw-overflow-hidden"
          :class="[
            displayedSource !== 'static' ? 'htw-max-w-6 htw-opacity-70' : 'htw-max-w-[63px] htw-text-primary-600 dark:htw-text-primary-400',
            staticSourceCode ? 'htw-cursor-pointer hover:htw-bg-gray-500/30 active:htw-bg-gray-600/50' : 'htw-opacity-50',
          ]"
          @click="staticSourceCode && (displayedSource = 'static')"
        >
          <Icon
            icon="carbon:document"
            class="htw-w-4 htw-h-4 htw-flex-none"
          />
          <span
            class="transition-opacity duration-300"
            :class="{
              'opacity-0': displayedSource !== 'static',
            }"
          >
            Static
          </span>
        </button>
      </div>

      <HstCopyIcon
        :content="displayedSourceCode"
        class="htw-flex-none"
      />
    </div>

    <div
      v-if="error"
      class="htw-text-red-500 htw-h-full htw-p-2 htw-overflow-auto htw-font-mono htw-text-sm"
    >
      Error: {{ error }}
    </div>

    <BaseEmpty v-else-if="!displayedSourceCode">
      <Icon
        icon="carbon:code-hide"
        class="htw-w-8 htw-h-8 htw-opacity-50 htw-mb-6"
      />
      <span>Not available</span>
    </BaseEmpty>

    <textarea
      v-else-if="!sourceHtml"
      ref="scroller"
      class="__histoire-code-placeholder htw-w-full htw-h-full htw-p-4 htw-outline-none htw-bg-transparent htw-resize-none htw-m-0"
      :value="displayedSourceCode"
      readonly
      data-test-id="story-source-code"
      @scroll="onScroll"
    />
    <!-- eslint-disable vue/no-v-html -->
    <div
      v-else
      ref="scroller"
      class="htw-w-full htw-h-full htw-overflow-auto"
      data-test-id="story-source-code"
      @scroll="onScroll"
    >
      <div
        class="__histoire-code htw-p-4 htw-w-fit"
        v-html="sourceHtml"
      />
    </div>
    <!-- eslint-enable vue/no-v-html -->
  </div>
</template>

<style scoped>
.__histoire-code-placeholder {
  color: inherit;
  font-size: inherit;
}
</style>
