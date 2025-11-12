<script lang="ts">
export default {
  name: 'HstCopyIcon',
}
</script>

<script lang="ts" setup>
import { Icon } from '@iconify/vue'
import { useClipboard } from '@vueuse/core'
import { VTooltip as vTooltip } from 'floating-vue'
import type { Awaitable } from '@histoire/shared'

const props = defineProps<{
  content: string | (() => Awaitable<string>)
}>()

const { copy, copied } = useClipboard()

async function action() {
  const content = typeof props.content === 'function' ? await props.content() : props.content
  copy(content)
}
</script>

<template>
  <Icon
    v-tooltip="{
      content: 'Copied!',
      triggers: [],
      shown: copied,
      distance: 12,
      delay: 0,
    }"
    icon="carbon:copy-file"
    class="htw-w-4 htw-h-4 htw-opacity-50 hover:htw-opacity-100 hover:htw-text-primary-500 htw-cursor-pointer"
    @click="action()"
  />
</template>
