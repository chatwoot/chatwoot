<script lang="ts" setup>
import { computed } from 'vue'
import { RouterLink } from 'vue-router'

const props = defineProps<{
  to?: any
  href?: string
  color?: string
}>()

const comp = computed(() => {
  if (props.to) {
    return RouterLink
  }
  if (props.href) {
    return 'a'
  }
  return 'button'
})
</script>

<template>
  <component
    :is="comp"
    class="histoire-base-button htw-rounded htw-cursor-pointer"
    :class="{
      'htw-bg-primary-200 dark:htw-bg-primary-800 hover:htw-bg-primary-300 dark:hover:htw-bg-primary-700': color === 'primary' || !color,
      'htw-bg-grey-100 dark:htw-bg-grey-900 hover:htw-bg-grey-200 dark:hover:htw-bg-grey-800': color === 'grey',
    }"
  >
    <slot />
  </component>
</template>
