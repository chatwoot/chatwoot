<script lang="ts" setup>
import { Icon } from '@iconify/vue'
import { openInEditor } from '../../util/open-in-editor.js'

defineProps<{
  file: string
  tooltip: string
}>()
</script>

<template>
  <a
    v-tooltip="tooltip"
    target="_blank"
    class="histoire-toolbar-open-in-editor htw-flex htw-items-center htw-gap-1 htw-h-full htw-px-2 hover:htw-text-primary-500 htw-opacity-50 hover:htw-opacity-100 dark:hover:htw-text-primary-400 htw-text-gray-900 dark:htw-text-gray-100"
    @click="openInEditor(file)"
  >
    <Icon
      icon="carbon:script-reference"
      class="htw-w-4 htw-h-4"
    />
  </a>
</template>
