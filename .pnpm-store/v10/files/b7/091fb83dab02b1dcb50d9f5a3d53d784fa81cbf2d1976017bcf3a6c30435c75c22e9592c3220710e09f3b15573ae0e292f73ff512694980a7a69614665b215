<script setup lang="ts">
import { Icon } from '@iconify/vue'
import { computed } from 'vue'
import { isDark, toggleDark } from '../../util/dark'
import { onKeyboardShortcut } from '../../util/keyboard'
import { makeTooltip } from '../../util/tooltip'
import { histoireConfig } from '../../util/config'
import AppLogo from './AppLogo.vue'

defineEmits({
  search: () => true,
})

const themeIcon = computed(() => {
  return isDark.value ? 'carbon:moon' : 'carbon:sun'
})

onKeyboardShortcut(['ctrl+shift+d', 'meta+shift+d'], (event) => {
  event.preventDefault()
  toggleDark()
})
</script>

<template>
  <div
    class="histoire-app-header htw-px-4 htw-h-16 htw-flex htw-items-center htw-gap-2"
  >
    <div class="htw-py-3 sm:htw-py-4 htw-flex-1 htw-h-full htw-flex htw-items-center htw-pr-2">
      <a
        :href="histoireConfig.theme?.logoHref"
        target="_blank"
        class="htw-w-full htw-h-full htw-flex htw-items-center"
      >
        <AppLogo
          class="htw-max-w-full htw-max-h-full"
        />
      </a>
    </div>
    <div class="htw-ml-auto htw-flex-none htw-flex">
      <a
        v-tooltip="makeTooltip('Search', ({ isMac }) => isMac ? 'meta+k' : 'ctrl+k')"
        class="htw-p-2 sm:htw-p-1 hover:htw-text-primary-500 dark:hover:htw-text-primary-400 htw-cursor-pointer htw-text-gray-900 dark:htw-text-gray-100"
        data-test-id="search-btn"
        @click="$emit('search')"
      >
        <Icon
          icon="carbon:search"
          class="htw-w-6 htw-h-6 sm:htw-w-4 sm:htw-h-4"
        />
      </a>

      <a
        v-if="!histoireConfig.theme.hideColorSchemeSwitch"
        v-tooltip="makeTooltip('Toggle dark mode', ({ isMac }) => isMac ? 'meta+shift+d' : 'ctrl+shift+d')"
        class="htw-p-2 sm:htw-p-1 hover:htw-text-primary-500 dark:hover:htw-text-primary-400 htw-cursor-pointer htw-text-gray-900 dark:htw-text-gray-100"
        @click="toggleDark()"
      >
        <Icon
          :icon="themeIcon"
          class="htw-w-6 htw-h-6 sm:htw-w-4 sm:htw-h-4"
        />
      </a>
    </div>
  </div>
</template>
