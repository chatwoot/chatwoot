import { defineStore } from 'pinia'
import { computed, ref } from 'vue'
import { router } from '../router'
import type { Story, Variant } from '../types'

export const useStoryStore = defineStore('story', () => {
  const stories = ref<Story[]>([])
  function setStories(value: Story[]) {
    stories.value = value
  }

  const currentStory = computed(() => stories.value.find(s => s.id === router.currentRoute.value.params.storyId))

  const currentVariant = computed(() => currentStory.value?.variants.find(v => v.id === router.currentRoute.value.query.variantId))

  const maps = computed(() => {
    const storyMap = new Map<string, Story>()
    const variantMap = new Map<string, Variant>()
    for (const story of stories.value) {
      storyMap.set(story.id, story)
      for (const variant of story.variants) {
        variantMap.set(`${story.id}:${variant.id}`, variant)
      }
    }
    return {
      stories: storyMap,
      variants: variantMap,
    }
  })

  function getStoryById(id: string) {
    return maps.value.stories.get(id)
  }

  function getVariantById(idWithStoryId: string) {
    return maps.value.variants.get(idWithStoryId)
  }

  return {
    stories,
    setStories,
    currentStory,
    currentVariant,
    getStoryById,
    getVariantById,
  }
})
