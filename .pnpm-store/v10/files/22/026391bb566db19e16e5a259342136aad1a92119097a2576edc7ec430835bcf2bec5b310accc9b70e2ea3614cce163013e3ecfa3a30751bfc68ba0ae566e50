<script lang="ts" setup>
import { computed } from 'vue'
import { customLogos, histoireConfig } from '../util/config'
import HistoireLogo from '../assets/histoire.svg'
import { useStoryStore } from '../stores/story'
import HomeCounter from './app/HomeCounter.vue'

const logoUrl = computed(() => histoireConfig.theme?.logo?.square ? customLogos.square : HistoireLogo)
const storyStore = useStoryStore()

const stats = computed(() => {
  let storyCount = 0
  let variantCount = 0
  let docsCount = 0;

  (storyStore.stories || []).forEach((story) => {
    if (story.docsOnly) {
      docsCount++
    }
    else {
      storyCount++
      if (story.variants) {
        variantCount += story.variants.length
      }
    }
  })

  return {
    storyCount,
    variantCount,
    docsCount,
  }
})
</script>

<template>
  <div class="histoire-home-view htw-flex md:htw-flex-col htw-gap-12 htw-items-center htw-justify-center htw-h-full">
    <img
      :src="logoUrl"
      alt="Logo"
      class="htw-w-64 htw-h-64 htw-opacity-25 htw-mb-8 htw-hidden md:htw-block"
    >
    <div class="htw-flex !md:htw-flex-col htw-flex-wrap htw-justify-evenly htw-gap-2 htw-px-4 htw-py-2 htw-bg-gray-100 dark:htw-bg-gray-750 htw-rounded htw-border htw-border-gray-500/30">
      <HomeCounter
        title="Stories"
        icon="carbon:cube"
        :count="stats.storyCount"
      />
      <HomeCounter
        title="Variants"
        icon="carbon:cube-view"
        :count="stats.variantCount"
      />
      <HomeCounter
        title="Documents"
        icon="carbon:document-blank"
        :count="stats.docsCount"
      />
    </div>
  </div>
</template>
