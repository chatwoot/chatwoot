<script lang="ts" setup>
import { ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { Icon } from '@iconify/vue'
import { useStoryStore } from '../../stores/story'

import BaseSplitPane from '../base/BaseSplitPane.vue'
import BaseEmpty from '../base/BaseEmpty.vue'
import { isMobile } from '../../util/responsive'
import StorySidePanel from '../panel/StorySidePanel.vue'
import StoryDocs from '../panel/StoryDocs.vue'
import StoryViewer from './StoryViewer.vue'

const storyStore = useStoryStore()

const router = useRouter()
const route = useRoute()

// Restore variant selection

watch(() => storyStore.currentVariant, (value) => {
  if (value) {
    storyStore.currentStory.lastSelectedVariant = value
  }
}, {
  immediate: true,
})

watch(() => [storyStore.currentStory, storyStore.currentVariant], () => {
  if (!storyStore.currentVariant) {
    if (storyStore.currentStory?.lastSelectedVariant) {
      setVariant(storyStore.currentStory.lastSelectedVariant.id)
      return
    }

    if (storyStore.currentStory?.variants.length === 1) {
      setVariant(storyStore.currentStory.variants[0].id)
    }
  }
}, {
  immediate: true,
})

function setVariant(variantId: string) {
  router.replace({
    ...route,
    query: {
      ...route.query,
      variantId,
    },
  })
}

// Docs auto-scroll to top

const docsOnlyScroller = ref<HTMLElement>(null)

function scrollDocsToTop() {
  docsOnlyScroller.value?.scrollTo(0, 0)
}
</script>

<template>
  <BaseEmpty
    v-if="!storyStore.currentStory"
    class="histoire-story-view histoire-no-story"
  >
    <Icon
      icon="carbon:software-resource-resource"
      class="htw-w-16 htw-h-16 htw-opacity-50"
    />
  </BaseEmpty>

  <div
    v-else
    class="histoire-story-view histoire-with-story htw-h-full"
  >
    <div
      v-if="storyStore.currentStory.docsOnly"
      ref="docsOnlyScroller"
      class="htw-h-full htw-overflow-auto"
    >
      <StoryDocs
        :story="storyStore.currentStory"
        standalone
        class="md:htw-p-12 htw-w-full md:htw-max-w-[600px] lg:htw-max-w-[800px] xl:htw-max-w-[900px]"
        @scroll-top="scrollDocsToTop()"
      />
    </div>
    <template v-else-if="isMobile">
      <StoryViewer />
    </template>
    <BaseSplitPane
      v-else
      save-id="story-main"
      :min="30"
      :max="95"
      :default-split="75"
      class="htw-h-full"
    >
      <template #first>
        <StoryViewer />
      </template>

      <template #last>
        <StorySidePanel />
      </template>
    </BaseSplitPane>
  </div>
</template>
