<script lang="ts" setup>
import { computed } from 'vue'
import { Icon } from '@iconify/vue'
import { useStoryStore } from '../../stores/story'
import { isMobile } from '../../util/responsive'
import BaseSplitPane from '../base/BaseSplitPane.vue'
import StoryVariantListItem from './StoryVariantListItem.vue'
import StoryVariantSingleView from './StoryVariantSingleView.vue'

defineEmits({
  openVariantMenu: () => true,
})

const storyStore = useStoryStore()

const hasSingleVariant = computed(() => (storyStore.currentStory?.variants.length === 1))

const variant = computed(() => storyStore.currentVariant)
</script>

<template>
  <div
    v-if="hasSingleVariant && variant"
    class="histoire-story-variant-single htw-p-2 htw-h-full __histoire-pane-shadow-from-right"
  >
    <StoryVariantSingleView
      :variant="variant"
      :story="storyStore.currentStory"
    />
  </div>
  <template v-else>
    <div
      v-if="isMobile"
      class="htw-divide-y htw-divide-gray-100 dark:htw-divide-gray-800 htw-h-full htw-flex htw-flex-col"
    >
      <a
        class="htw-px-6 htw-h-12 hover:htw-text-primary-500 dark:hover:htw-text-primary-400 htw-cursor-pointer htw-flex htw-gap-2 htw-flex-wrap htw-w-full htw-items-center htw-flex-none"
        @click="$emit('openVariantMenu')"
      >
        <template v-if="variant">
          <Icon
            :icon="variant.icon ?? 'carbon:cube'"
            class="htw-w-5 htw-h-5 htw-flex-none"
            :class="{
              'htw-text-gray-500': !variant.iconColor,
              'bind-icon-color': variant.iconColor,
            }"
          />
          {{ variant.title }}
        </template>
        <template v-else>
          Select a variant...
        </template>

        <Icon
          icon="carbon:chevron-sort"
          class="htw-w-5 htw-h-5 htw-shrink-0 htw-ml-auto"
        />
      </a>
      <div
        v-if="storyStore.currentVariant"
        class="htw-p-2 htw-h-full"
      >
        <StoryVariantSingleView
          :variant="storyStore.currentVariant"
          :story="storyStore.currentStory"
        />
      </div>
    </div>
    <BaseSplitPane
      v-else
      save-id="story-single-main-split"
      :min="5"
      :max="40"
      :default-split="17"
    >
      <template #first>
        <div class="htw-h-full htw-overflow-y-auto">
          <StoryVariantListItem
            v-for="(v, index) of storyStore.currentStory.variants"
            :key="index"
            :variant="v"
          />
        </div>
      </template>
      <template #last>
        <div
          v-if="storyStore.currentVariant"
          class="htw-p-2 htw-h-full __histoire-pane-shadow-from-right"
        >
          <StoryVariantSingleView
            :variant="storyStore.currentVariant"
            :story="storyStore.currentStory"
          />
        </div>
      </template>
    </BaseSplitPane>
  </template>
</template>

<style scoped>
.bind-icon-color {
  color: v-bind('variant?.iconColor');
}
</style>
