<script lang="ts">
export default {
  name: 'HstWrapper',
}
</script>

<script lang="ts" setup>
import { withDefaults } from 'vue'
import { VTooltip as vTooltip } from 'floating-vue'

withDefaults(defineProps<{
  title?: string
  tag?: string
}>(), {
  title: undefined,
  tag: 'label',
})
</script>

<template>
  <component
    :is="tag"
    class="histoire-wrapper htw-p-2 hover:htw-bg-primary-100 dark:hover:htw-bg-primary-800 htw-flex htw-gap-2 htw-flex-wrap"
  >
    <span
      v-tooltip="{
        content: title,
        placement: 'left',
        distance: 12,
      }"
      class="htw-w-28 htw-whitespace-nowrap htw-text-ellipsis htw-overflow-hidden htw-shrink-0"
    >
      {{ title }}
    </span>
    <span class="htw-grow htw-max-w-full htw-flex htw-items-center htw-gap-1">
      <span class="htw-block htw-grow htw-max-w-full">
        <slot />
      </span>
      <slot name="actions" />
    </span>
  </component>
</template>
