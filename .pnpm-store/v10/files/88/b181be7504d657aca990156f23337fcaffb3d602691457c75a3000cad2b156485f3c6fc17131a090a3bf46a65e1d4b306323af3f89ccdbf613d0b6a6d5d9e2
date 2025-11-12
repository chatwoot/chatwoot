<script lang="ts">
export default {
  name: 'HstJson',
  inheritAttrs: false,
}
</script>

<script lang="ts" setup>
import { onMounted, ref, watch, watchEffect } from 'vue'
import { Icon } from '@iconify/vue'
import { VTooltip as vTooltip } from 'floating-vue'
import { Compartment } from '@codemirror/state'
import type {
  ViewUpdate,
} from '@codemirror/view'
import {
  EditorView,
  highlightActiveLine,
  highlightActiveLineGutter,
  highlightSpecialChars,
  keymap,
} from '@codemirror/view'
import { defaultKeymap } from '@codemirror/commands'
import { json } from '@codemirror/lang-json'
import {
  bracketMatching,
  defaultHighlightStyle,
  foldGutter,
  foldKeymap,
  indentOnInput,
  syntaxHighlighting,
} from '@codemirror/language'
import { lintKeymap } from '@codemirror/lint'
import { oneDarkHighlightStyle, oneDarkTheme } from '@codemirror/theme-one-dark'
import HstWrapper from '../HstWrapper.vue'
import { isDark } from '../../utils'

const props = defineProps<{
  title?: string
  modelValue: unknown
}>()

const emit = defineEmits({
  'update:modelValue': (newValue: unknown) => true,
})

let editorView: EditorView
const internalValue = ref('')
const invalidValue = ref(false)
const editorElement = ref<HTMLInputElement>()

const themes = {
  light: [EditorView.baseTheme({}), syntaxHighlighting(defaultHighlightStyle)],
  dark: [oneDarkTheme, syntaxHighlighting(oneDarkHighlightStyle)],
}

const themeConfig = new Compartment()

const extensions = [
  highlightActiveLineGutter(),
  highlightActiveLine(),
  highlightSpecialChars(),
  json(),
  bracketMatching(),
  indentOnInput(),
  foldGutter(),
  keymap.of([
    ...defaultKeymap,
    ...foldKeymap,
    ...lintKeymap,
  ]),
  EditorView.updateListener.of((viewUpdate: ViewUpdate) => {
    internalValue.value = viewUpdate.view.state.doc.toString()
  }),
  themeConfig.of(themes.light),
]

onMounted(() => {
  editorView = new EditorView({
    doc: JSON.stringify(props.modelValue, null, 2),
    extensions,
    parent: editorElement.value,
  })

  watchEffect(() => {
    editorView.dispatch({
      effects: [
        themeConfig.reconfigure(themes[isDark.value ? 'dark' : 'light']),
      ],
    })
  })
})

watch(() => props.modelValue, () => {
  let sameDocument

  try {
    sameDocument = (JSON.stringify(JSON.parse(internalValue.value)) === JSON.stringify(props.modelValue))
  }
  catch (e) {
    sameDocument = false
  }

  if (!sameDocument) {
    editorView.dispatch({ changes: [{ from: 0, to: editorView.state.doc.length, insert: JSON.stringify(props.modelValue, null, 2) }] })
  }
}, { deep: true })

watch(() => internalValue.value, () => {
  invalidValue.value = false
  try {
    emit('update:modelValue', JSON.parse(internalValue.value))
  }
  catch (e) {
    invalidValue.value = true
  }
})
</script>

<template>
  <HstWrapper
    :title="title"
    class="histoire-json htw-cursor-text"
    :class="$attrs.class"
    :style="$attrs.style"
  >
    <div
      ref="editorElement"
      class="__histoire-json-code htw-w-full htw-border htw-border-solid htw-border-black/25 dark:htw-border-white/25 focus-within:htw-border-primary-500 dark:focus-within:htw-border-primary-500 htw-rounded-sm htw-box-border htw-overflow-auto htw-resize-y htw-min-h-32 htw-h-48 htw-relative"
      v-bind="{ ...$attrs, class: null, style: null }"
    />

    <template #actions>
      <Icon
        v-if="invalidValue"
        v-tooltip="'JSON error'"
        icon="carbon:warning-alt"
        class="htw-text-orange-500"
      />

      <slot name="actions" />
    </template>
  </HstWrapper>
</template>

<style scoped>
.__histoire-json-code :deep(.cm-editor) {
  height: 100%;
  min-width: 280px;
}
</style>
