<script lang="ts" setup>
import { Icon } from '@iconify/vue'
import type { Variant } from '../../types'

defineProps<{
  variant: Variant
}>()
</script>

<template>
  <div class="histoire-toolbar-title htw-flex htw-items-center htw-gap-1 htw-text-gray-500 htw-flex-1 htw-truncate htw-min-w-0">
    <Icon
      :icon="variant.icon ?? 'carbon:cube'"
      class="htw-w-4 htw-h-4 htw-opacity-50"
      :class="[
        variant.iconColor ? 'bind-icon-color' : 'htw-text-gray-500',
      ]"
    />
    <span>{{ variant.title }}</span>
  </div>
</template>
