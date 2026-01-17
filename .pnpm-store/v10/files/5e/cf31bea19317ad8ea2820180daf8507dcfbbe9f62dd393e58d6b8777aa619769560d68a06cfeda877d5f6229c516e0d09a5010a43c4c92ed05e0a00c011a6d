<script lang="ts" setup>
import { Icon } from '@iconify/vue'
import { usePreviewSettingsStore } from '../../stores/preview-settings'

const settings = usePreviewSettingsStore().currentSettings
</script>

<template>
  <a
    v-tooltip="`Switch to text direction ${settings.textDirection === 'ltr' ? 'Right to Left' : 'Left to Right'}`"
    class="histoire-toolbar-text-direction htw-flex htw-items-center htw-gap-1 htw-h-full htw-px-2 hover:htw-text-primary-500 htw-opacity-50 hover:htw-opacity-100 dark:hover:htw-text-primary-400 htw-text-gray-900 dark:htw-text-gray-100"
    @click="settings.textDirection = settings.textDirection === 'ltr' ? 'rtl' : 'ltr'"
  >
    <Icon
      :icon="settings.textDirection === 'ltr' ? 'fluent:text-paragraph-direction-right-16-regular' : 'fluent:text-paragraph-direction-left-16-regular'"
      class="htw-w-4 htw-h-4"
    />
  </a>
</template>
