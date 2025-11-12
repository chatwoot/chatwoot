import { defineStore } from 'pinia'
import { reactive, ref, watch } from 'vue'
import { useStoryStore } from './story.js'

export interface HstEvent {
  name: string
  argument: unknown
}

export const useEventsStore = defineStore('events', () => {
  const storyStore = useStoryStore()

  const events = reactive<Array<HstEvent>>([])
  const unseen = ref(0)

  function addEvent(event: HstEvent) {
    events.push(event)
    unseen.value++
  }

  function reset() {
    events.length = 0
    unseen.value = 0
  }

  watch(() => storyStore.currentVariant?.id, () => {
    reset()
  })

  return {
    addEvent,
    reset,
    events,
    unseen,
  }
})
