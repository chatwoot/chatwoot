<script lang="ts" setup>
import { computed, ref, watch } from 'vue'
import { Icon } from '@iconify/vue'
import { useStoryStore } from '../../stores/story'
import type { Story, Tree } from '../../types'
import StoryList from '../tree/StoryList.vue'
import MobileOverlay from './MobileOverlay.vue'

defineProps<{
  tree: Tree
  stories: Story[]
}>()

const storyStore = useStoryStore()

const story = computed(() => storyStore.currentStory)

const folders = computed(() => {
  return story.value.file.path.slice(0, -1)
})

const isMenuOpened = ref(false)

function openMenu() {
  isMenuOpened.value = true
}

function closeMenu() {
  isMenuOpened.value = false
}

watch(story, () => {
  isMenuOpened.value = false
})
</script>

<template>
  <div class="histoire-breadcrumb">
    <a
      class="htw-px-6 htw-h-12 hover:htw-text-primary-500 dark:hover:htw-text-primary-400 htw-cursor-pointer htw-flex htw-gap-2 htw-flex-wrap htw-w-full htw-items-center"
      @click="openMenu"
    >
      <template v-if="story">
        <template
          v-for="(file, key) of folders"
          :key="key"
        >
          <span>
            {{ file }}
          </span>
          <span class="htw-opacity-40">
            /
          </span>
        </template>
        <span class="htw-flex htw-items-center htw-gap-2">
          <Icon
            :icon="story.icon ?? 'carbon:cube'"
            class="htw-w-5 htw-h-5 htw-flex-none"
            :class="{
              'htw-text-primary-500': !story.iconColor,
              'bind-icon-color': story.iconColor,
            }"
          />
          {{ story.title }}
          <span class="htw-opacity-40 htw-text-sm">
            {{ story.variants.length }}
          </span>
        </span>
      </template>
      <template v-else>
        Select a story...
      </template>

      <Icon
        icon="carbon:chevron-sort"
        class="htw-w-5 htw-h-5 htw-shrink-0 htw-ml-auto"
      />
    </a>
  </div>

  <MobileOverlay
    title="Select a story"
    :opened="isMenuOpened"
    @close="closeMenu"
  >
    <StoryList
      :tree="tree"
      :stories="stories"
      class="htw-flex-1 htw-overflow-y-scroll"
    />
  </MobileOverlay>
</template>

<style scoped>
.bind-icon-color {
  color: v-bind('story?.iconColor');
}
</style>
