<script lang="ts" setup>
import { computed, nextTick, onMounted, ref, watch } from 'vue'
import { Icon } from '@iconify/vue'
import BaseEmpty from '../base/BaseEmpty.vue'
import { useEventsStore } from '../../stores/events'
import StoryEvent from './StoryEvent.vue'

const eventsStore = useEventsStore()

const hasEvents = computed(() => eventsStore.events.length)

onMounted(resetUnseen)
watch(() => eventsStore.unseen, resetUnseen)

async function resetUnseen() {
  if (eventsStore.unseen > 0) {
    eventsStore.unseen = 0
  }
  await nextTick()
  eventsElement.value.scrollTo({ top: eventsElement.value.scrollHeight })
}

const eventsElement = ref<HTMLDivElement>()
</script>

<template>
  <div
    ref="eventsElement"
    class="histoire-story-events"
  >
    <BaseEmpty
      v-if="!hasEvents"
    >
      <Icon
        icon="carbon:event-schedule"
        class="htw-w-8 htw-h-8 htw-opacity-50 htw-mb-6"
      />
      No event fired
    </BaseEmpty>
    <div v-else>
      <StoryEvent
        v-for="(event, key) of eventsStore.events"
        :key="key"
        :event="event"
      />
    </div>
  </div>
</template>
