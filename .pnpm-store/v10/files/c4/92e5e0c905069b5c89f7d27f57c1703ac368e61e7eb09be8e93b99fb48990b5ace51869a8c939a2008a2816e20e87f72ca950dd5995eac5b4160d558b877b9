<script lang="ts" setup>
import { useResizeObserver } from '@vueuse/core'
import { computed, onMounted, ref, watch } from 'vue'
import { useStoryStore } from '../../stores/story'
import { isMobile } from '../../util/responsive'
import ToolbarBackground from '../toolbar/ToolbarBackground.vue'
import ToolbarTextDirection from '../toolbar/ToolbarTextDirection.vue'
import DevOnlyToolbarOpenInEditor from '../toolbar/DevOnlyToolbarOpenInEditor.vue'
import StoryVariantGridItem from './StoryVariantGridItem.vue'

const storyStore = useStoryStore()

const gridTemplateWidth = computed(() => {
  if (storyStore.currentStory.layout.type !== 'grid') {
    return
  }

  const layoutWidth = storyStore.currentStory.layout.width

  if (!layoutWidth) {
    return '200px'
  }

  if (typeof layoutWidth === 'number') {
    return `${layoutWidth}px`
  }

  return layoutWidth
})

const margin = 16
const gap = 16

const itemWidth = ref(16)
const maxItemHeight = ref(0)
const maxCount = ref(10)
const countPerRow = ref(0)
const visibleRows = ref(0)

const el = ref<HTMLDivElement>(null)

useResizeObserver(el, () => {
  updateMaxCount()
  updateSize()
})

function updateMaxCount() {
  if (!maxItemHeight.value) return

  const width = el.value!.clientWidth - margin * 2
  const height = el.value!.clientHeight
  const scrollTop = el.value!.scrollTop

  // width = (countPerRow - 1) * gap + countPerRow * itemWidth.value

  // W = (C - 1) * G + C * I
  // W = C * G - G + C * I
  // W + G = C * G + C * I
  // W + G = C * (G + I)
  // (W + G) / (G + I) = C

  countPerRow.value = Math.floor((width + gap) / (itemWidth.value + gap))
  visibleRows.value = Math.ceil((height + scrollTop + gap) / (maxItemHeight.value + gap))
  const newMaxCount = countPerRow.value * visibleRows.value
  if (maxCount.value < newMaxCount) {
    maxCount.value = newMaxCount
  }

  if (storyStore.currentVariant) {
    const index = storyStore.currentStory.variants.indexOf(storyStore.currentVariant)
    if (index + 1 > maxCount.value) {
      maxCount.value = index + 1
    }
  }
}

function onItemResize(w: number, h: number) {
  itemWidth.value = w
  if (maxItemHeight.value < h) {
    maxItemHeight.value = h
    updateMaxCount()
  }
}

watch(() => storyStore.currentVariant, () => {
  maxItemHeight.value = 0 // Reset max height
  updateMaxCount()
})

// Grid size

const gridEl = ref<HTMLDivElement>(null)
const gridColumnWidth = ref(1)
const viewWidth = ref(1)

function updateSize() {
  if (!el.value) return
  viewWidth.value = el.value.clientWidth

  if (!gridEl.value) return

  if (gridTemplateWidth.value.endsWith('%')) {
    gridColumnWidth.value = viewWidth.value * Number.parseInt(gridTemplateWidth.value) / 100 - gap
  }
  else {
    gridColumnWidth.value = Number.parseInt(gridTemplateWidth.value)
  }
}

onMounted(() => {
  updateSize()
})

useResizeObserver(gridEl, () => {
  updateSize()
})

const columnCount = computed(() => Math.min(storyStore.currentStory.variants.length, Math.floor((viewWidth.value + gap) / (gridColumnWidth.value + gap))))
</script>

<template>
  <div class="histoire-story-variant-grid htw-flex htw-flex-col htw-items-stretch htw-h-full __histoire-pane-shadow-from-right">
    <!-- Toolbar -->
    <div
      v-if="!isMobile"
      class="htw-flex-none htw-flex htw-items-center htw-justify-end htw-h-8 htw-mx-2 htw-mt-1"
    >
      <ToolbarBackground />
      <ToolbarTextDirection />

      <DevOnlyToolbarOpenInEditor
        v-if="__HISTOIRE_DEV__"
        :file="storyStore.currentStory.file?.filePath"
        tooltip="Edit story in editor"
      />
    </div>

    <div
      ref="el"
      class="htw-overflow-y-auto htw-flex htw-flex-1"
      @scroll="updateMaxCount()"
    >
      <div class="htw-flex htw-w-0 htw-flex-1 htw-mx-4">
        <div
          class="htw-m-auto"
          :style="{
            minHeight: `${(storyStore.currentStory.variants.length / countPerRow) * (maxItemHeight + gap) - gap}px`,
          }"
        >
          <div
            ref="gridEl"
            class="htw-grid htw-gap-4 htw-my-4"
            :style="{
              gridTemplateColumns: `repeat(${columnCount}, ${gridColumnWidth}px)`,
            }"
          >
            <StoryVariantGridItem
              v-for="(variant, index) of storyStore.currentStory.variants.slice(0, maxCount)"
              :key="index"
              :variant="variant"
              :story="storyStore.currentStory"
              @resize="onItemResize"
            />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
