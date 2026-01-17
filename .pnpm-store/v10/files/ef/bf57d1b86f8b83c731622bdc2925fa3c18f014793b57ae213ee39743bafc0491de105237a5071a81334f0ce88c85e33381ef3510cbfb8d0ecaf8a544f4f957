<script lang="ts" setup>
import { Icon } from '@iconify/vue'

defineProps<{
  title: string
  opened: boolean
}>()

const emit = defineEmits<{ (e: 'close'): void }>()
</script>

<template>
  <transition name="__histoire-fade-bottom">
    <div
      v-if="opened"
      class="histoire-mobile-overlay htw-absolute htw-z-10 htw-bg-white dark:htw-bg-gray-700 htw-w-screen htw-h-screen htw-inset-0 htw-overflow-hidden htw-flex htw-flex-col"
    >
      <div class="htw-p-4 htw-h-16 htw-flex htw-border-b htw-border-gray-100 dark:htw-border-gray-800 htw-items-center htw-place-content-between">
        <span class="htw-text-gray-500">{{ title }}</span>
        <a
          class="htw-p-1 hover:htw-text-primary-500 dark:hover:htw-text-primary-400 htw-cursor-pointer"
          @click="emit('close')"
        >
          <Icon
            icon="carbon:close"
            class="htw-w-8 htw-h-8 htw-shrink-0"
          />
        </a>
      </div>
      <slot />
    </div>
  </transition>
</template>
