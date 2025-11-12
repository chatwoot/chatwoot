<script lang="ts" setup>
import { computed } from 'vue'
import type { HstEvent } from '../../stores/events'

const props = defineProps<{
  event: HstEvent
}>()

const formattedArgument = computed(() => {
  switch (typeof props.event.argument) {
    case 'string':
      return `"${props.event.argument}"`
    case 'object':
      return `{ ${Object.keys(props.event.argument).map(key => `${key}: ${props.event.argument[key]}`).join(', ')} }`
    default:
      return props.event.argument
  }
})
</script>

<template>
  <VDropdown
    class="histoire-story-event htw-group"
    placement="right"
    data-test-id="event-item"
  >
    <template #default="{ shown }">
      <div
        class="group-hover:htw-bg-primary-100 dark:group-hover:htw-bg-primary-700 htw-cursor-pointer htw-py-2 htw-px-4 htw-flex htw-items-baseline htw-gap-1 htw-leading-normal"
        :class="[
          shown ? 'htw-bg-primary-50 dark:htw-bg-primary-600' : 'group-odd:htw-bg-gray-100/50 dark:group-odd:htw-bg-gray-750/40',
        ]"
      >
        <span
          :class="{
            'htw-text-primary-500': shown,
          }"
        >
          {{ event.name }}
        </span>
        <span
          v-if="event.argument"
          class="htw-text-xs htw-opacity-50 htw-truncate"
        >{{ formattedArgument }}</span>
      </div>
    </template>

    <template #popper>
      <div class="htw-overflow-auto htw-max-w-[400px] htw-max-h-[400px]">
        <pre class="htw-p-4">{{ event.argument }}</pre>
      </div>
    </template>
  </VDropdown>
</template>
