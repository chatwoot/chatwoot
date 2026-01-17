<script lang="ts" setup>
import { Icon } from '@iconify/vue'
import { computed } from 'vue'
import type { Story, Variant } from '../../types'
import { getSandboxUrl } from '../../util/sandbox'

const props = defineProps<{
  variant: Variant
  story: Story
}>()

const sandboxUrl = computed(() => {
  return getSandboxUrl(props.story, props.variant)
})
</script>

<template>
  <a
    v-tooltip="'Open variant in new tab'"
    :href="sandboxUrl"
    target="_blank"
    class="histoire-toolbar-new-tab htw-flex htw-items-center htw-gap-1 htw-h-full htw-px-2 hover:htw-text-primary-500 htw-opacity-50 hover:htw-opacity-100 dark:hover:htw-text-primary-400 htw-text-gray-900 dark:htw-text-gray-100"
  >
    <Icon
      icon="carbon:launch"
      class="htw-w-4 htw-h-4"
    />
  </a>
</template>
