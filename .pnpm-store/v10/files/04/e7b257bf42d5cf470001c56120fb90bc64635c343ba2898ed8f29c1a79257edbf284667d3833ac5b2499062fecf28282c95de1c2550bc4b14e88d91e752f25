<script lang="ts">
export default {
  name: 'HstCopyIcon',
}
</script>

<script lang="ts" setup>
import { Icon } from '@iconify/vue'
import { useClipboard } from '@vueuse/core'
import { VTooltip as vTooltip } from 'floating-vue'

const props = defineProps<{
  content: string
}>()

const { copy, copied } = useClipboard()

const action = () => copy(props.content)
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
    class="histoire-base-copy-icon htw-w-4 htw-h-4 htw-opacity-50 hover:htw-opacity-100 hover:htw-text-primary-500 htw-cursor-pointer"
    @click="action()"
  />
</template>
