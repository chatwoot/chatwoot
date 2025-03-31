<script lang="ts" setup>
import { computed, ref, watch } from 'vue'
import { useStoryStore } from '../../stores/story'
import MobileOverlay from '../app/MobileOverlay.vue'
import StoryVariantListItem from './StoryVariantListItem.vue'
import StoryVariantGrid from './StoryVariantGrid.vue'
import StoryVariantSingle from './StoryVariantSingle.vue'

const storyStore = useStoryStore()

const variant = computed(() => storyStore.currentVariant)

const isMenuOpened = ref(false)

function closeMenu() {
  isMenuOpened.value = false
}

watch(variant, () => {
  isMenuOpened.value = false
})
</script>

<template>
  <div class="histoire-story-viewer htw-bg-gray-50 htw-h-full dark:htw-bg-gray-750">
    <StoryVariantGrid
      v-if="storyStore.currentStory.layout.type === 'grid'"
    />
    <StoryVariantSingle
      v-else-if="storyStore.currentStory.layout.type === 'single'"
      @open-variant-menu="isMenuOpened = true"
    />
  </div>

  <MobileOverlay
    title="Select a variant"
    :opened="isMenuOpened"
    @close="closeMenu"
  >
    <StoryVariantListItem
      v-for="(v, index) of storyStore.currentStory.variants"
      :key="index"
      :variant="v"
    />
  </MobileOverlay>
</template>

<style scoped>
.bind-icon-color {
  color: v-bind('variant?.iconColor');
}
</style>
