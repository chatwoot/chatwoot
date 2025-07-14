<script lang="ts">
export default {
  name: 'HstButton',
}
</script>

<script setup lang="ts">
const colors = {
  default: 'htw-bg-gray-200 dark:htw-bg-gray-750 htw-text-gray-900 dark:htw-text-gray-100 hover:htw-bg-primary-200 dark:hover:htw-bg-primary-900',
  primary: 'htw-bg-primary-500 hover:htw-bg-primary-600 htw-text-white dark:htw-text-black',
  flat: 'htw-bg-transparent hover:htw-bg-gray-500/20 htw-text-gray-900 dark:htw-text-gray-100',
}

defineProps<{
  color?: keyof typeof colors
}>()
</script>

<template>
  <button
    class="histoire-button htw-cursor-pointer htw-rounded-sm"
    :class="colors[color ?? 'default']"
  >
    <slot />
  </button>
</template>
